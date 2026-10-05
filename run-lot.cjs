// Exécute 1 lot (ou 2 parties) du seed skill_catalog via HTTP contre le
// PostgREST de Supabase avec le JWT secret (service_role) présent dans .env.local.
//
// Usage:
//   node run-lot.cjs lot_000.sql
//   node run-lot.cjs .l000a.sql .l000b.sql
//
// Sortie JSON : { ok, rowsInserted, lot }
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname);
const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('usage: node run-lot.cjs <fichier SQL> [fichier SQL 2]');
  process.exit(2);
}

// --- charger le JWT secret depuis .env.local (pas commité) ---
const envRaw = fs.readFileSync(path.join(ROOT, '.env.local'), 'utf8');
const mk = (k) => {
  const m = envRaw.match(new RegExp('^' + k + '=\\s*(.+)$', 'm'));
  if (!m) throw new Error('variable d\'env absente : ' + k);
  return m[1].trim();
};
const SUPABASE_URL = mk('SUPABASE_URL');
const SECRET = mk('SUPABASE_SECRET_KEY');

// --- POSTgREST : POST /rpc/<fn> ne sert pas ; on utilise le endpoint d'insert
// direct : POST /skill_catalog  avec Prefer: resolution=ignore-duplicates ---
async function runOne(file) {
  const sql = fs.readFileSync(file, 'utf8');
  // Extraire les tuples du lot pour construire le payload JSON.
  // Le lot est : INSERT INTO skill_catalog (...11 colonnes...) VALUES (...), (...);
  // On parse les tuples individuels (chacun commence à la ligne "('marketplace:").
  const lines = sql.split('\n');
  const headerIdx = lines.findIndex((l) => l.startsWith('INSERT INTO skill_catalog'));
  if (headerIdx < 0) throw new Error('en-tête INSERT introuvable dans ' + file);
  const columnsLine = lines[headerIdx + 1];
  const cols = columnsLine.match(/\(([^)]+)\)/)[1].split(',').map((c) => c.trim());

  const tuples = [];
  let cur = null;
  for (const line of lines.slice(headerIdx + 2)) {
    if (line.startsWith("('marketplace:")) {
      if (cur) tuples.push(cur);
      cur = line;
    } else if (cur !== null) {
      cur += '\n' + line;
    }
    if (cur && cur.endsWith('ON CONFLICT (skill_key) DO NOTHING;')) {
      tuples.push(cur);
      cur = null;
      break;
    }
  }
  if (cur) tuples.push(cur);

  // Parser chaque tuple : ('key','domain',...,$body$...$body$)
  // Séparation par virgules au niveau tuple, pas celles imbriquées dans $body$.
  // Heuristique fiable ici : les colonnes fixes sont au début ; le corps est le
  // dernier champ et se termine par $body$) — on split sur le premier $body$ après
  // les 10 colonnes fixes.
  const parsed = tuples.map((t) => {
    // Enlever le ; final
    let body = t.replace(/\n*ON CONFLICT \(skill_key\) DO NOTHING;\n?$/, '');
    // Trouver la première occurrence de "''" (description vide) puis $body$
    // Format: ('key','domain','name','','objective','[]','[]','[]','source','',$body$CORPS$body$)
    const m = body.match(
      /^'\''marketplace:[^]*'$body\$$/
    );
    // Parse plus robuste : chercher le dernier $body$
    const startDollar = body.indexOf('$body$');
    const endDollar = body.lastIndexOf('$body$');
    const fixedPart = body.slice(1, startDollar).trim(); // ( 'a','b',...,''
    const contentPart = body.slice(endDollar + 6, body.length - 1).trim(); // }CORPS$body$)
    // fixedPart = "('key','domain','name','','objective','[]'::jsonb,'[]'::jsonb,'[]'::jsonb,'source',''"
    const vals = [];
    // Découpe les chaînes simples '...' en gérant les guillemets échappés ''
    let i = 1; // après (
    const fields = [];
    while (i < fixedPart.length) {
      if (fixedPart[i] === '\'') {
        i++;
        let s = '';
        while (i < fixedPart.length) {
          if (fixedPart[i] === '\'') {
            if (fixedPart[i + 1] === '\'') { s += "'"; i += 2; continue; }
            i++; break;
          }
          s += fixedPart[i]; i++;
        }
        fields.push(s);
      } else if (fixedPart[i] === ',') {
        i++;
      } else if (/[ \t\r\n]/.test(fixedPart[i])) {
        i++;
      } else {
        // ::jsonb ou autre typecast
        let j = i;
        while (j < fixedPart.length && /[A-Za-z0-9_:'\[\];]/.test(fixedPart[j])) j++;
        fields.push(fixedPart.slice(i, j));
        i = j;
      }
    }
    const record = {};
    for (let k = 0; k < cols.length; k++) {
      record[cols[k]] = fields[k];
    }
    record.body = contentPart;
    // Cast jsonb : le value doit rester une string pour PostgREST qui parse auto
    return record;
  });

  // POST /skill_catalog avec Prefer: resolution=ignore-duplicates
  const res = await fetch(SUPABASE_URL + '/skill_catalog', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + SECRET,
      'apikey': SECRET,
      'Content-Type': 'application/json',
      Prefer: 'resolution=ignore-duplicates, return=minimal',
    },
    body: JSON.stringify(parsed),
  });
  const text = await res.text();
  return { file, status: res.status, rows: parsed.length, ok: res.ok, body: text.slice(0, 500) };
}

(async () => {
  for (const f of files) {
    const r = await runOne(f);
    console.log(JSON.stringify({ ok: r.ok, lot: r.file, status: r.status, rows: r.rows, resp: r.body }, null, 2));
    if (!r.ok) process.exitCode = 1;
  }
})();
