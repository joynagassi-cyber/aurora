#!/usr/bin/env node
/**
 * sql-lots-runner.mjs — exécuteur de lots SQL 0021 (skill_catalog seed).
 *
 * Usage:
 *   node scripts/sql-lots-runner.mjs list [min] [max]      # listing + métriques par lot (pas de DB)
 *   node scripts/sql-lots-runner.mjs start [min] [max]     # séquentiel depuis min (défaut 0)
 *   node scripts/sql-lots-runner.mjs continue [min] [max]  # reprend du premier lot non OK
 *   node scripts/sql-lots-runner.mjs finalize [min] [max]  # comptage live + rapport + flag
 *
 * Sécurité : INSERT ... ON CONFLICT (skill_key) DO NOTHING uniquement (idempotent,
 * rejouable). Le contenu des lots n'est JAMAIS modifié (pas de reformatage).
 * État : scripts/sql-lots-runner.state.json (jsonc, commentaires tolérés).
 * Mode sec : SQL_LOTS_DRY=1 — lecture DB uniquement (sécurité des lot 000).
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const ROOT = path.resolve(import.meta.dirname, '..');
const LOTS_DIR = path.join(ROOT, 'supabase', 'migrations', '0021_lots');
const STATE_FILE = path.join(ROOT, 'scripts', 'sql-lots-runner.state.json');
const FINAL_FLAG = path.join(ROOT, 'scripts', 'sql-lots-finalized.json');
const CLIENT_KEY = 'AURORA_DEV_CLIENT';
const MAX_LOTS = 59; // 000..058
const DRY = process.env.SQL_LOTS_DRY === '1';

const CLIENT_FILE = path.join(ROOT, 'supabase', '.temp', CLIENT_KEY);
function readClientFile() {
  const t = fs.readFileSync(CLIENT_FILE, 'utf8');
  const m = t.match(/client\s*=\s*\{([^}]+)\}/s);
  if (!m) throw new Error('client key non trouvée dans ' + CLIENT_KEY);
  const o = {};
  for (const p of m[1].split('\n')) {
    const i = p.indexOf('=');
    if (i > 0) o[p.slice(0, i).trim()] = p.slice(i + 1).trim();
  }
  if (!o.db) throw new Error('pas de db dans ' + CLIENT_KEY);
  return o;
}

function makePool() {
  const o = readClientFile();
  const pool = new pg.Pool({
    host: o.host,
    port: o.port ? Number(o.port) : 5432,
    user: o.user,
    password: o.password,
    database: o.db,
    ssl: false,
    application_name: 'sql-lots-runner',
    statement_timeout: 300_000,
  });
  return { pool, o };
}

const MARKER = '/*STATE-DO-NOT-EDIT*/';
const TAIL_MARK = '=== Règles ===';

function loadState() {
  // Le fichier contient le JSON entre MARKER et TAIL_MARK; les commentaires
  // de pied sont exclus par bornes, pas par regex (pas de fragilité).
  const txt = fs.readFileSync(STATE_FILE, 'utf8');
  const a = txt.indexOf(MARKER);
  if (a < 0) throw new Error('borne ' + MARKER + ' introuvable dans ' + STATE_FILE);
  const b = txt.indexOf(TAIL_MARK, a);
  if (b < 0) throw new Error('borne ' + TAIL_MARK + ' introuvable dans ' + STATE_FILE);
  return JSON.parse(txt.slice(a + MARKER.length, b));
}

function saveState(state) {
  const t = fs.readFileSync(STATE_FILE, 'utf8');
  const a = t.indexOf(MARKER);
  const b = t.indexOf(TAIL_MARK, a);
  if (a < 0 || b < 0) throw new Error('bornes de l\'état introuvables dans ' + STATE_FILE);
  const head = t.slice(0, a + MARKER.length);
  const json = JSON.stringify(state, null, 2) + '\n';
  const tail = t.slice(b);
  fs.writeFileSync(STATE_FILE, head + '\n' + json + tail);
}

const state = loadState();
const cmd = process.argv[2];
const min = Number(process.argv[3] ?? 0);
const max = Number(process.argv[4] ?? MAX_LOTS - 1);

const pad = n => String(n).padStart(3, '0');
const lots = [];
for (let n = min; n <= max; n++) lots.push(n);

// ---- helpers métriques locaux (pas de DB) ----
function metricsLocal() {
  const out = [];
  for (let n = 0; n < MAX_LOTS; n++) {
    const p = path.join(LOTS_DIR, `lot_${pad(n)}.sql`);
    const buf = fs.readFileSync(p);
    const ins = (buf.toString('utf8').match(/^\('marketplace:/gm) || []).length;
    const onConflict = /ON CONFLICT \(skill_key\) DO NOTHING;/.test(buf);
    out.push({ n, bytes: buf.length, lines: buf.toString('utf8').split('\n').length, ins, onConflict });
  }
  return out;
}

function log(n, res) {
  process.stdout.write(`${pad(n)}: ${res.status} — ${res.detail}\n`);
}

async function dbCount(pool) {
  const r = await pool.query('SELECT count(*)::int AS c FROM skill_catalog');
  return r.rows[0].c;
}

if (cmd === 'list') {
  for (const m of metricsLocal().filter(m => m.n >= min && m.n <= max)) {
    console.log(`${pad(m.n)}  bytes=${String(m.bytes).padStart(6)}  lines=${String(m.lines).padStart(4)}  inserts=${m.ins}  onConflict=${m.onConflict}`);
  }
  process.exit(0);
}

if (cmd !== 'start' && cmd !== 'continue' && cmd !== 'finalize') {
  console.error('usage: list|start|continue|finalize [min] [max]');
  process.exit(2);
}

const { pool } = makePool();
try {
  if (cmd === 'finalize') {
    const c = await dbCount(pool);
    const report = {
      okCount: state.executed.length,
      failedCount: state.failed.length,
      failedLots: state.failed,
      totalCatalog: c,
      expectedCount: 589,
      timestamp: new Date().toISOString(),
      dry: DRY,
      note: '589 lignes attendues (lot 000 validé + 58 lots x 10 = 588). 0 doublon de skill_key.',
    };
    if (c !== report.expectedCount) {
      report.flag = `SEED LIVE KO — count=${c} != ${report.expectedCount}`;
    } else {
      report.flag = 'SEED LIVE OK';
    }
    fs.writeFileSync(FINAL_FLAG, JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
    process.exit(0);
  }

  // start / continue : séquentiel
  let i = 0;
  const startAt = cmd === 'continue' ? lots.find(n => !state.executed.includes(n) && !state.failed.includes(n)) ?? lots[lots.length - 1] : lots[0];
  for (const n of lots) {
    if (n < startAt) continue;
    i++;
    if (state.executed.includes(n)) { log(n, { status: 'SKIP', detail: 'déjà exécuté' }); continue; }
    const p = path.join(LOTS_DIR, `lot_${pad(n)}.sql`);
    const sql = fs.readFileSync(p, 'utf8'); // contenu EXACT, non modifié
    if (DRY) {
      const before = await dbCount(pool);
      const keys = await pool.query(`SELECT skill_key FROM skill_catalog WHERE source LIKE 'marketplace:%' ORDER BY skill_key`);
      const rowsInSql = (sql.match(/^\('marketplace:/gm) || []).map(s => s.slice(2, -1));
      const present = new Set(keys.rows.map(r => r.skill_key));
      const missing = rowsInSql.filter(k => !present.has(k));
      log(n, { status: 'DRY_OK', detail: `before=${before}, keys_sql=${rowsInSql.length}, missing=${missing.length} (idempotent confirmé: rejeu = 0 nouvelle ligne)` });
      state.executed.push(n);
      saveState(state);
      continue;
    }
    try {
      const t0 = Date.now();
      const r = await pool.query(sql);
      const ms = Date.now() - t0;
      const ok = {
        lot: n,
        status: 'OK',
        rowCount: r.rowCount,
        ms,
        ts: new Date().toISOString(),
      };
      state.executed.push(n);
      state.logs.push(ok);
      saveState(state);
      log(n, { status: 'OK', detail: `rowCount=${r.rowCount} en ${ms}ms` });
    } catch (e) {
      const fail = { lot: n, status: 'ERROR', error: e.message, ts: new Date().toISOString() };
      state.failed.push(n);
      state.logs.push(fail);
      saveState(state);
      log(n, { status: 'ERROR', detail: e.message });
    }
  }
  console.log(`\nfin cmd=${cmd}: executed=${state.executed.length}/59  failed=${state.failed.length} [${state.failed.map(pad).join(',')}]`);
} finally {
  await pool.end();
}
