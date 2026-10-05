# 02-detect-F — Lens F: cross-file contract drift + Capacitor / cross-platform

Method: read-only. All claims cite `file:line`. Lens scope = contract drift between
device UI / `lib/*-client.ts` / `packages/domain` / `packages/platform`, plus
Capacitor build-runtime correctness. Companion lenses (A–E) cover the generic
Ionic surface; no overlap below except where a contract finding lands on a
screen another lens owns.

## Summary

**6 findings: 1 High, 2 Medium, 3 Low. No Critical, no 🔴-confidence finding.**

## Ranked findings

| # | severity | file:line | category | symptom | fix_hint | confidence |
|---|----------|-----------|----------|---------|----------|------------|
| 1 | High | `apps/mobile/src/pages/integrations/index.tsx:35-45` (+ `:99`) | contract-drift | The page's own header (`:24-26`, "the UI NEVER invents a toolkit/tool slug — the runtime catalog is the SSoT") is violated by its implementation: 9 hardcoded `toolkit_slug` values drive the connect UX, and `lib/integrations-client.ts:47` `discoverTools()` has **0 call sites in `src/**`** (grep = none) — so silent drift against the real Composio v3.1 catalog goes undetected; the `:99` `window.open` connect link (see #6) is the only user-visible consequence path. | Have the page fetch the connectable catalog from `integrations?.discoverTools()` (already imported at `:22` as `IntegrationAccount` type) and render from that; keep the 9-item local list only as a degraded fallback; document that fallback. | 🟢 |
| 2 | Medium | `apps/mobile/src/pages/skills/index.tsx:35-42` vs `packages/domain/src/entities-agent.ts:22` vs `apps/mobile/src/lib/skills-client.ts:52` | contract-drift | Device re-declares the skill-domain concept AD-15 assigns to `packages/domain`: `DOMAIN_LABELS` (6 labels) re-lists the `AgentSkillTemplate.domain` 6-way union (`entities-agent.ts:22`), while the device contract (`CreateSkillPayload.domain`, free `string`) and `packages/domain` `UserSkill.domain` (free `string`, line 50) disagree on which one is canonical; today the key-sets coincide 6/6, so the divergence is **latent, not active**. | Move the domain union to `packages/domain` (export it, add the i18n label map there or in a UI package) and import it in `skills-client.ts` + `skills/index.tsx`; stop re-declaring. | 🟢 |
| 3 | Medium | `apps/mobile/src/hooks/use-killed.ts:54` | cross-platform | `setKilled(true)` on every mount + `resync()` at first paint — on the *native* Android WebView path (where a real kill leaves no `visibilitychange`/session record, per the doc comment) the "Reconnexion…" skeleton + refetch fires on **every** cold start, not only after a kill. | Gate the boot-time `killed=true` on a native/cold-start signal from `@aurora/platform` (P5) instead of unconditionally; web stays as-is. | 🟢 |
| 4 | Low | `apps/mobile/package.json:30-31` | capacitor-config | `@capacitor/android` (+ `@capacitor/core`) declared in **`dependencies`**, while `packages/platform` declares its own `@capacitor/*` in `devDependencies` (its `package.json:22-24`); the mobile app has no consumer of the package (workspace root `package.json:13` only runs it via `pnpm -F`), so the bucketing is inconsistent with the platform-package convention. | Move both to `devDependencies` in `apps/mobile/package.json` (nothing at runtime builds against them); no functional impact. | 🟡 |
| 5 | Low | `apps/mobile/.env.example:5` (only doc site) | capacitor-config | Required build var `AURORA_ONESIGNAL_APP_ID` (fail-fast `capacitor.config.ts:14-20`, AD-3 — by design, do NOT remove) is documented in **exactly one** place: the 5-line `.env.example`; 0 mentions in `docs/**` or any `README` (grep across repo = only `capacitor.config.ts`, `.env.example`, `out/review/00-scoping.md`). | Add a one-paragraph pointer in `docs/` (mobile build section) explaining the fail-fast + where to get the OneSignal app key; keep the guard. | 🟢 |
| 6 | Low | `apps/mobile/src/pages/integrations/index.tsx:99` | cross-platform | `window.open(connectLink, '_blank')` for the Composio OAuth connect link — on the native Android WebView this may silently no-op or open in-app without `target="_blank"` support; `packages/platform/src` has **no** `Browser`/`Opener`/`openURL` shim (grep `Browser|Opener|window.open|openURL` = 0) and `@capacitor/browser`/`opener` are not in any manifest. The `composio.md:224` spec ("in-app WebView or deep link") is thus unmet on Android. | Open the link through a `@capacitor/browser`-backed `openExternal` adapter exposed by `@aurora/platform` (AD-1), falling back to `window.open` on web; add the plugin to the platform package. | 🟡 |

## Verified clean / NOT findings

- **AD-1 boundary holds** (confirmed by Map §3 + re-grep here): 0 `@capacitor/*`
  imports in `apps/mobile/src/**`; all native capability is behind
  `@aurora/platform` (`packages/platform/package.json:22-24` declares the
  plugins, none reach app code).
- **`use-online.ts` is correct for both web and native** (`src/hooks/use-online.ts:12-30`):
  `navigator.onLine` + `online`/`offline` events fire reliably in Capacitor
  Android WebView (they are standard Web APIs; Capacitor does not override
  them). No finding. (The Map §3 note "webview fallback" just means: this hook
  works without the native `Network` plugin being wired.)
- **Spotify / "defaultOn: true" reading — judged**: the "Google Workspace preset"
  reading (`integrations/index.tsx:31` + `composio.md:82` "Spotify est le SEUL
  toolkit… qui n'a PAS d'OAuth géré par Composio") is the **legitimate
  intentional** one — it documents *which* tools are connectable by the
  managed-OAuth flow, not a claim about the full v3.1 catalog. So #1 is
  *specifically* the "never invents a slug" SSoT clause + the skipped
  `discoverTools` seam, not a wrong vendor choice.
- **`packages/domain/src/entities-agent.ts` domain union**: 6 values
  (`science|marketing|social|research|documents|creative`, line 22) — matches
  `DOMAIN_LABELS` keys exactly today; hence #2 is ranked Medium (latent) rather
  than High.
- **`pnpm-lock.yaml`**: confirms `@capacitor/android@7.6.9` and
  `@capacitor/core@7.6.9` are only in the mobile app's dep tree; no other
  package transitively depends on `@capacitor/android`, so #4 is a bucketing
  nit, not a duplicate-resolution issue.
- **`use-killed.ts` visibility-gap branch** (`:31-46`): correct as a heuristic
  for the *in-session* background/foreground case; the issue is only the
  boot-time `setKilled(true)` at line 54 (captured in #3).

## 🔴 findings

None. No finding reached 🔴 (low-confidence) confidence; all six are backed by
direct file reads and greps (🟢 × 4, 🟡 × 2). The user does not need to answer
any disambiguating question for this lens.
