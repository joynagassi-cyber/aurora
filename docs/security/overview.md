# Security — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1). Authority: spine AD-2/AD-3/AD-16,
`01-backend` §2.2/§5/§6/§7, `04-mobile` §3.2.5/§7.2, ADR §9 (provider reliability
rules), mission §26 (incl. Electron Phase-2 baseline).

## 1. Data isolation (RLS, 01 §2.2)

Supabase RLS = the enforcement mechanism of AD-2 at the data layer (ruling of the
spine Open Question, 01 §2.2): per-module schemas, every row carries `user_id`;
user A never reads/writes user B's rows (penetration test on **every** table,
blocking for policy migrations, 01 §7). `service_role` reads PowerSync views
**through RLS policies**, never `BYPASSRLS` (01 §3.4). The device cannot call
Edge Functions without identity (01 §6 auth rule).

## 2. Secrets & keys (AD-3)

- **No key or secret ever ships to the device.** Provider keys (Agnes,
  Cloudflare, Groq, Cerebras, …) live in Supabase Secrets / Cloudflare Secrets
  Store (01 §5.6). The client only sees the normalized `AIProvider` contract.
- OneSignal: `appKey` (app-specific) in `capacitor.config.ts` (owner Foundation,
  AD-16c) ≠ **server key** (push-sending) which lives in `fn-notifications`
  only; test 04 §7.2(e) verifies no server-side key in `capacitor.config.ts`.
- R2: presigned URLs only (15 min / 5 min TTLs, 01 §5.4); client uploads direct,
  never with keys (04 §7.2(b)).
- 429s are **never** bypassed by rotating keys/accounts (AD-5, ADR §9/§10).
- CI greps: vendor names/keys outside adapter files + secrets patterns in client
  bundles (SPEC wave-0 gate; sole sanctioned exception = OneSignal appKey, 04
  §7.2e).

## 3. Agent tool permissions (AD-12, ADR §5)

Permission Context per session (authorized / confirmed / forbidden); tool calls
classified read / write / destructive; **confirmation mandatory for important or
irreversible actions**; destructive operations always confirmed; replayable via
idempotent jobs (AD-8). See [agent/kernel.md §5](../agent/kernel.md).

## 4. Provider data policy (ADR v1.7 §11)

Providers declare `DataPolicy` in the Model Registry; production routes can
exclude free tiers with incompatible data terms (Mistral/OpenRouter data-use
terms; Groq no-retention-by-default + ZDR — verify at integration and version
it). User documents/courses/notes never auto-flow to an incompatible provider
(`AIRequestGuard` refuses **before** the call, 01 §6).

## 5. Electron Phase 2 baseline (planned, NOT a V1 artifact — ADR §23)

When Phase 2 adds the desktop adapter: `contextIsolation = true`,
`nodeIntegration = false`, minimal preload, strict CSP, navigation allowlist,
minimal typed IPC (mission §26). The V1 core stays portable (ADR §23.2/§23.3);
Codex review checks portability, not desktop work, in V1 (ADR §24).

## 6. Review & audit hooks

Codex review (ADR §21.6) systematically hunts: architecture/boundary violations,
RLS holes, secrets/permissions/IPC leaks, duplicates, UX state gaps, agent
orchestration/permission/idempotency problems. Risk register with mitigations:
01 §8.2 (R1–R7, incl. `USING (true)` policy = disaster; per-team registries
forbidden by AD-16 + CI test).

## 7. Tests

RLS penetration (01 §7) · key anti-leak (04 §7.2b/e) · `AIRequestGuard`
pre-refusal tests · idempotency (01 §7) · Electron baseline checks = Phase 2.

## 8. Extended surface (mission §57/§58)

- **Composio credentials** (integration layer, NOT an AI provider —
  docs/integrations/composio.md): user-level OAuth/API-key connections managed
  **server-side** (connected accounts + token refresh owned by the service,
  per-user `userID`/`connectedAccountID` scoping); the agent never holds
  external tokens directly (it requests the Tool Router, which enforces
  execution authorization per tool scope + confirmation class).
- **Local data**: SQLite mirror is per-user (keyed by `user_id` in every table,
  01 §4); no cross-user reads locally (mirror = PowerSync views already RLS-
  scoped, 03 §5.4); secrets never local (AD-3); DPC device (v1.8) = one user,
  device-level trust documented in focus spec §14.
- **External data**: provider data policies (ADR v1.7 §11) + Composio connected
  accounts stay in the integration layer (device sees normalized results only);
  R2 = private buckets + presigned (no key on device).
- **Logs**: `job_logs` (job lifecycle, redacted payloads — sensitive content
  NEVER logged in full: document/corpus excerpts stay out of logs, 01 §5.3);
  Sentry = errors/perf (breadcrumbs, no corpus content in default capture);
  PostHog = aggregate events only (**no sensitive content in analytics** —
  mission §58: event names + ids + durations, never document/course text;
  data-policy check in the telemetry review, 01 §7 observability tests).
