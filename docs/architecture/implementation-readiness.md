# Implementation Readiness Report (Deliverable N)

**Date:** 2026-09-22. **Status:** pre-wave-0 audit. This report lists every
open decision that must be ratified BEFORE the code agents launch wave 0.
If any item below is still open when the code agents start, the wave-0
gate is not met.

## Blocking decisions (must be closed before wave 0)

| # | Item | Owner | Current state |
|---|---|---|---|
| 1 | OQ-01: pnpm monorepo layout (packages/domain, packages/data, packages/platform, packages/ui, packages/agent, apps/mobile, apps/server) | Foundation | OPEN — layout specified in 01 S1 + 02 S1; ratify at wave-0 standup |
| 2 | OQ-02: team column in 03 S4.2 entity->owner mapping (frozen mapping, team assignment open) | Foundation + all module teams | OPEN — mapping is frozen; team names to be filled |
| 3 | OQ-03: environment values (3 envs, Supabase project IDs, R2 bucket names, OneSignal appKey, provider account IDs) | Foundation | OPEN — values required for wave-0 CI + secret store setup |
| 4 | OQ-17: DPC provisioning on target phone (v1.8 candidate) — factory reset + no accounts + adb dpm set-device-owner + setPackagesSuspended API level + per-package suspendability matrix | Foundation + Productivity | OPEN — **blocking for freezing Focus implementation**; if target phone cannot be DPC-provisioned, consumer fallback (04 S4.1) applies and Focus = restriction-only |
| 5 | G-M7: Feature Registry ratification (FeatureDescriptor, registry chain, deactivation effects, product modes) | Foundation + App Shell | OPEN — specified in feature-registry.md; ratify at wave-0 standup; types in packages/domain (AD-15) |

## High-priority items (close during wave 0)

| # | Item | Owner | Current state |
|---|---|---|---|
| 6 | G-M1: AnimationController DS wrapper (05 S3.6 missing 5th AD-10 contract) | DS team | OPEN — add AnimationSlot / useAuroraAnimation before G1 wave-1 cut |
| 7 | G-M2: killed app state in 5-state UX matrix (02 S7 + 05 S3.7) | App Shell + DS | OPEN — add as sub-state of loading |
| 8 | G-M3: AppError SSoT move to packages/domain (02 S10 -> domain) | Foundation | OPEN — wave-0 deliverable |
| 9 | G-M4: job_queue full shape SSoT (01 S5.3 + 03 S5.5) | Foundation | OPEN — freeze full shape (incl. nullable source_local_mutation_id + computed idempotency_key) |
| 10 | G-M5: ChartSpec SSoT (owner packages/ui, publish in 05 S3.6) | DS team | OPEN — wave-0 deliverable |
| 11 | G-H2 residual: theme-JSON regression lint in packages/ui/src/themes/ | Foundation | OPEN — CI check at wave 0 |

## Medium-priority items (close before relevant wave)

| # | Item | Owner | When |
|---|---|---|---|
| 12 | G-L1: 04 frontmatter dependency direction (minSyncIntervalMs) | Data team | wave 0 |
| 13 | G-L2: 49 theme x screen mockups | Dyad/UI team | wave 0 (ADR S22) |
| 14 | G-L4: ArtifactGenerated UI consumer ratification in AD-9 matrix | Foundation | next spine ADR |
| 15 | G-L5: Eisenhower quadrant screen ratification | Productivity + DS | before wave-2 cut |
| 16 | OQ-04: FOREGROUND_SERVICE necessity (background sync > 30 s) | Data team | before wave 1 |
| 17 | OQ-05: ArtifactGenerated UI consumer (02 declares, AD-9 matrix omits) | Foundation | next spine ADR |
| 18 | OQ-06: Screen Pinning on target Android | Foundation | wave 0 |
| 19 | OQ-08: E2E tooling (Playwright + Capacitor driver assumption) | QA | wave 7 |
| 20 | G-U4: free-tier quota drift (2026-09-21 snapshot; Agnes "a suivre") | packages/data | continuous; CI "provider retirement" test |
| 21 | G-U5: DPC provisioning + suspendability (OQ-17, see #4) | Foundation + Productivity | wave 0 |

## Pre-wave-0 checklist (gate)

Before the code agents launch, the following must be true:

- [ ] OQ-01 pnpm layout ratified
- [ ] OQ-02 team column filled in 03 S4.2
- [ ] OQ-03 environment values provided (dev + staging)
- [ ] OQ-17 DPC provisioning either confirmed or consumer fallback decided
- [ ] G-M7 Feature Registry ratified
- [ ] G-M3 AppError moved to packages/domain
- [ ] G-M4 job_queue full shape frozen
- [ ] G-M5 ChartSpec shape published
- [ ] G-H2 theme-JSON lint in CI
- [ ] AI_RULES.md reviewed and accepted by all teams
- [ ] Contract Packs (01-05) frontmatter dependencies verified
- [ ] 9-event vocabulary confirmed (AD-9, no additions without additive ADR)
- [ ] 5 UX states confirmed (02 S7: loading / error / empty / success / offline; killed = sub-state of loading, G-M2)

## Design System conflicts (from the user's pre-wave-0 note)

The user identified three specific items to resolve before launching code agents:

1. **Design System conflicts** — G-H2 (canvas values, RESOLVED 2026-09-22) + G-H3 (5 theme binary locks, VERIFIED APPLIED) + G-M5 (ChartSpec SSoT, OPEN). The G-H2/G-H3 corrections are in the packs; G-M5 needs the DS team to publish the shape.
2. **FocusSessionBilan contract** — G-H1, RESOLVED 2026-09-22: shape pinned in 05 S3.6.9 + 01 S4.1 SSoT. No residual action.
3. **Light/dark + Mirror Cognitive Mode locks** — G-H3 verified applied (02 S3.3, 02 S5.2, 02 S8, 01 S2.1, 04 O3b). G-L3 Mirror mode: prescriptive design in 01 S4.2; dedicated screen = additive 05 inventory item, wave 2.

## Verdict

The documentation is **sufficient for wave-0 planning** (contracts, CI,
scaffolding, type definitions). It is **NOT a green light for wave-1
code agents** until the 5 blocking decisions (#1-5 above) are ratified.
The three items the user flagged (DS conflicts, FocusSessionBilan,
light/dark + Mirror locks) are all RESOLVED in the packs as of
2026-09-22, with the residual G-M5 (ChartSpec) and G-M7 (Feature
Registry) as the remaining open items in that category.
