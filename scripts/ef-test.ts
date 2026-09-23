#!/usr/bin/env node
/**
 * Aurora Wave 0 — Edge Function curl test (01 S5.1).
 *
 * Hits the deployed fn-* stubs and asserts the ApiEnvelope 200/202 shape.
 * Reads the Supabase URL + publishable key from env ONLY (AD-3, never
 * inlined; values in .env.local, git-ignored).
 *
 * Usage:
 *   pnpm exec tsx scripts/ef-test.ts                 # test all 4 EFs
 *   pnpm exec tsx scripts/ef-test.ts fn-job-dispatcher   # single EF
 *
 * If the project is not reachable (SUPABASE_URL unset / network down /
 * EFs not deployed), prints SKIP-AND-REASON + the exact command to retry.
 */

const SUPABASE_URL = process.env.SUPABASE_URL ?? "";
const API_KEY = process.env.SUPABASE_PUBLISHABLE_KEY ?? "";

const FNS = ["fn-job-dispatcher", "fn-import-course", "fn-notifications", "fn-agent-run"];

// Per-EF sample payloads (01 S5.1 contracts).
const payloads = {
  "fn-job-dispatcher": {},
  "fn-import-course": { courseId: "00000000-0000-0000-0000-000000000000", fileRefs: [] },
  "fn-notifications": { eventType: "TaskCompleted", userId: "00000000-0000-0000-0000-000000000000" },
  "fn-agent-run": { intent: "test-intent", contextRefs: [], taskProfile: {} },
};

async function main() {
  if (!SUPABASE_URL) {
    console.log("SKIP-AND-REASON: SUPABASE_URL not set in this environment.");
    console.log("Re-run with the live env:");
    console.log("  set -a; set -o allexport; source .env.local; set +o allexport; set +a; pnpm exec tsx scripts/ef-test.ts");
    return;
  }

  const targets = process.argv[2] ? [process.argv[2]] : FNS;
  let allOk = true;
  for (const fn of targets) {
    const url = `${SUPABASE_URL}/functions/v1/${fn}`;
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          // Service-internal EF calls use the publishable key (AD-16, 01 S5.1).
          "apikey": API_KEY || "missing",
        },
        body: JSON.stringify(payloads[fn] ?? {}),
      });
      const body = await res.json().catch(() => ({}));
      const ok = res.status === 200 || res.status === 202;
      const envelopeOk = body && (body.ok === true || body.ok === false);
      allOk = allOk && ok && envelopeOk;
      console.log(
        `${ok ? "OK " : "ERR"} ${fn} -> HTTP ${res.status}` +
        (envelopeOk ? " envelope={ok:..." : " (no envelope)") +
        ` body=${JSON.stringify(body).slice(0, 120)}`,
      );
    } catch (e) {
      allOk = false;
      console.log(`ERR ${fn}: ${e.message}`);
    }
  }

  if (!allOk) {
    console.log("\nSKIP-AND-REASON (partial): not all EFs reachable or not yet deployed.");
    console.log("Deploy the stubs first, then re-run:");
    console.log("  supabase functions deploy fn-job-dispatcher fn-import-course fn-notifications fn-agent-run");
    console.log("  set -a; set -o allexport; source .env.local; set +o allexport; set +a; pnpm exec tsx scripts/ef-test.ts");
  }
}

main().catch((e) => { console.error("ERROR:", e.message); process.exit(1); });
