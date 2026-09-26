# Aurora — Changelog

Release-notes source of truth (docs/release/README S2 step 2). One
section per wave; within a wave, one bullet per story (AD-13:
1 story = 1 commit = 1 rollback — the bullet is reversible by
reverting that commit).

The `v*` tag workflow (`.github/workflows/release.yml`) copies this
file's `## Upcoming (v0.1.0)` section into `RELEASE_NOTES.md` at
release time.

---

## Upcoming (v0.1.0 — Phase 1 release candidate)

### UI Polish (wave 5, ERYNIS)

- **Framer Motion polish + theme adaptation** — `PageTransition`
  (200 ms ease-out), `NodePulse` (Focus active-node emphasis),
  `Reveal` (staggered in-view entry); all GPU-only
  (transform + opacity), 150–250 ms, `prefers-reduced-motion` aware
  (static when ON). OQ-15 theme adaptation is Focus-V1-only
  (`FocusThemeAdapter`: secondary nodes attenuated to 40 %, active
  node + progress at full contrast; other screens render the plain
  expressive theme). Brand assets: logo WITHOUT background =
  in-app (headers / empty states / page center); full logo =
  external icon only (Capacitor / store / splash) — no
  logo re-invented (docs/ui-libraries S9).
- **Product modes + command palette** — 6 named product modes
  (core / study / exam / focus-heavy / professional / minimal) as
  declarations over the Feature Registry (feature-registry S7), and
  the command palette as a view over the capability registry
  (S4: one capability, 5 entry points, zero duplicated business
  logic). Disabled features disappear from the palette (S6
  deactivation effect), never just greyed out.
- **Perf budgets** — 02 §9.1 SLOs (300 Ko gz JS, 1.5 s TTI,
  30 fps on Pixel 4a) wired as a static gate; device-observed
  via Sentry perf at release (OQ-08).

### E2E + Release (wave 7, ERYNIS)

- **E2E on device (OQ-08)** — Playwright driving the Capacitor
  webview (NOT Appium; Appium = documented fallback for the
  native-only seams). The web slice (create → complete task,
  offline badge) + TTI SLO gate runs in CI (the CI runner has no
  device). The 8-scenario Focus DPC bundle (docs/focus-mode/
  spec.md S13, OQ-17) runs on the provisioned device; its
  consumer fallback path (6/8) + provisioned mock (>=7/8, s6
  factory reset tolerated) is asserted in CI as the deterministic
  gate.
- **CI/CD + release process** — `.github/workflows/release.yml`
  (tag `v*` → build + APK + release notes + changelog; deploy
  steps dry-run until OQ-03 ratifies the env values), the
  per-wave changelog above, and the gate/rollback discipline in
  docs/release/README (1 story = 1 commit = 1 rollback).

---

## Wave history (audit trail, NOT release notes)

> This section is the git-log mirror for the session; it is NOT
> the release notes source. Release notes = the `## Upcoming`
> section above.

- **wave 7** — E2E device (OQ-08) + Focus DPC E2E (OQ-17, S13)
  + CI/CD + release notes (ERYNIS)
- **wave 5** — UI polish (Framer Motion + OQ-15 themes) +
  product modes / command palette + perf pass (ERYNIS)
- **wave 4** — 23 composite workflows + AD-9 event wiring +
  error recovery + self-improvement loop + OQ-08 Playwright
  spec (HARPYS)
- **wave 3** — Agent Kernel (intent → memory), 8 tools,
  Agnes-primary router, AgentRunState + command bus, expert
  skills (4 extensions), fn-agent-run; Ascent (Slide-Ascent +
  baseline + depth), 0016_ascent RLS; 5 composition patterns,
  agent goal capabilities; 20 E2E agent scenarios (ORACLE /
  SOPHIA / HEPHAESTUS)
- **wave 2** — feature registry G-M7 + 4 boundary greps +
  spine test (HERMES / ACHILLES)
- **wave 1** — packages/ui component library, packages/data
  (PowerSync + Supabase bridge), packages/platform (Capacitor
  adapters)
- **wave 0** — monorepo scaffold + domain types + theme JSON
  SSoT + 49 mockups + Supabase schemas + RLS + PowerSync relay
