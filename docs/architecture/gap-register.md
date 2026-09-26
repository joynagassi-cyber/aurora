# Gap & Risk Register (Deliverable J — reclassified per master mission S72)

Severity: CRITICAL / HIGH / MEDIUM / LOW.
Category: Architecture / Backend / Frontend / Agent / Integration / Provider /
Platform / Security / Data / Design / Testing / Documentation.
Nothing is masked. Platform limitations and unverified facts are listed as such.

## CRITICAL

(none — the coherence review found 0 Critical; no lost ADR decision)

## HIGH

| ID | Category | Gap | Detail | Action |
|---|---|---|---|---|
| G-H1 | Data | FocusSessionBilan SSoT (04/05) | **RESOLVED 2026-09-22**: shape pinned in 05 S3.6.9 + 01 S4.1; 04 S4.1 pt4 points to SSoT | None |
| G-H2 | Design | 05 canvas-value conflict (C-1) | **RESOLVED 2026-09-22**: 7 stale occurrences corrected to S2.1 values (#F8FAFC / #0A0E1A); SPEC OQ-16 residual #121212 corrected | Residual: theme-JSON regression lint at wave 0 |
| G-H3 | Architecture | 5 mustFixForV2 theme binary locks | **VERIFIED APPLIED in packs (2026-09-22)**: 02 S3.3, 02 S5.2, 02 S8, 01 S2.1, 04 O3b | Remaining: G1 / wave-0 ratification of AD-17 block (OQ-14/15/16) |

## MEDIUM

| ID | Category | Gap | Detail | Action |
|---|---|---|---|---|
| G-M1 | Design | AnimationController has no DS wrapper | **RESOLVED 2026-09-26**: 05 S3.6.13 ratifies `AnimationSlot` + `createAnimationController` (the DS wrapper for the 5ᵉ AD-10 contract `AnimationController`, 02 §5.5). The `useAuroraAnimation` hook is an **optional extension** (not normatively required by pack 05); the 4 other contracts = S3.6.6/.7/.8 + S3.6.1/.5 (SemanticTreeNode, InfographicSlot, MathBlock, DataTable/Sparkline). **Code SSoT already in place** at `packages/ui/src/renderers/AnimationController.tsx` (G-M1 verdict comment in source) | None — code aligns with docs |
| G-M2 | Frontend | killed app state not in 5-state UX matrix | **RESOLVED 2026-09-26**: `killed` added as **sub-state of `loading`** in 02 S7 (Sous-état `killed`, G-M2 block) + 05 S3.7 (row `killed` column note + `AnimationSlot` row) — pattern SSoT = docs/ui-libraries.md n°185 (Skeleton + auto-resync, « Reconnexion… » + shimmer); test DoD wave 1 = 03 S5.9 « kill-app relaunch = état intact » | None |
| G-M3 | Data | AppError SSoT split | **RESOLVED 2026-09-26**: owner = `packages/domain` (AD-15, SSoT wave 0 W0-E1-2) — pointer comment already in 01 S3.1 (line ~110) + 02 S10 header (docs only, app imports, jamais ré-déclare); **code SSoT already in place** at `packages/domain/src/envelopes.ts` (`AppError` + `AppErrorCode`, line 33-42) | None — code aligns with docs |
| G-M4 | Backend | job_queue field SSoT split | **RESOLVED 2026-09-26**: full `job_queue` + `job_logs` shape frozen in 01 S5.3 (lines 260-284) — 03 S5.5 lines 370-373 point only (01 §5.3 `idempotency_key` + `source_local_mutation_id`), no redeclaration ; **code SSoT already in place** at `packages/domain/src/jobs.ts` (`JobQueue.sourceLocalMutationId` line 47, G-M4 comment) | None — code aligns with docs |
| G-M5 | Data | ChartSpec SSoT undecided | **RESOLVED 2026-09-26**: owner = `packages/ui` ; shape **ratifié** = le `ChartSpec` déjà en `packages/ui/src/themes/types.ts` (line 164-188 : `id` + `type` bar/line/area/pie/radar/heatmap, `series[].values[] {label, value, unit}`, `animateValues`, `palette`, `labels`) — G-M5 verdict comment in source ; `focusBilan` (§3.6.9) = instanciation `bar` avec `seriesName: 'planned'`/`'actual'` ; règles fidèle §2.6 n°1 (pas d'animation compteur) ; **code SSoT already in place** | None — code aligns with docs |
| G-M6 | Documentation | SPEC presets line stale (C-2) | **RESOLVED 2026-09-22**: SPEC S05 now lists Slate / Nocturne / High Contrast | None |
| G-M7 | Architecture | No feature activation / deactivation framework in V1 | **RESOLVED by specification (2026-09-22)**: feature-registry.md (FeatureDescriptor, registry chain, deactivation effects S6, product modes S7, FeatureModule S8, AgentFeatureDeclaration S9, dependency graph S10, evolution flows S11) | NEEDS_DECISION: ratify wave 0 (Foundation + App Shell); types in packages/domain (AD-15) |

## LOW

| ID | Category | Gap | Detail | Action |
|---|---|---|---|---|
| G-L1 | Documentation | 04 frontmatter dependency direction | minSyncIntervalMs: 04 imposes, 03 defines; frontmatter says opposite | Clarify 04 frontmatter (wave 0) |
| G-L2 | Design | 49 theme x screen mockups not produced | **REJECTED 2026-09-27 (owner Joy)**: the 49 mockups are intentionally NOT produced (time/token cost, owner decision). Design work proceeds from the 05 S5.7 mechanism + the 1 example (Lagoon×Focus) + theme tokens + docs/ui-libraries.md (incl. S9 brand assets). No agent may produce mockups without explicit owner re-approval | None (closed, W0-E2-2 descoped) |
| G-L3 | Documentation | Mirror Cognitive Mode had no pack section | **RESOLVED 2026-09-22**: 01 S4.2 prescriptive design (server mirror-analysis job, typed detections + AD-11 provenance, F-07 evidence path) | Remaining: dedicated Mirror screen = additive 05 inventory item, wave 2 |
| G-L4 | Backend | ArtifactGenerated UI consumer (OQ-05) | Pack 02 declares UI consumer; AD-9 matrix lists Knowledge/Learning only | Ratify in AD-9 matrix at next spine ADR (additive) |
| G-L5 | Documentation | Eisenhower matrix absent from packs + 05 inventory | No pack section; no quadrant screen in 05 S4.3-4.5 | Prescriptive design in docs/productivity/eisenhower.md; ratify before wave-2 cut |

## Platform limitations (documented, never promised beyond)

| ID | Category | Limitation | Evidence | Consequence |
|---|---|---|---|---|
| G-P1 | Platform | App-blocking verdict = deployment-profile dependent | Consumer: NOT POSSIBLE (04 S4.1). v1.8 DPC: SUPPORTED via setPackagesSuspended (API 29+) under device-owner condition (focus spec S0/S2) | isBlockingAvailable() = detection; blocking UI only in DPC profile; consumer fallback = restriction-only |
| G-P2 | Platform | Call control is role-gated, not app-gated | CallScreeningService (API 23+) requires user-selected role; ~5 s response deadline; Play policy review; OEM variability | Level 1 (silence) = platform-dependent option; Level 2 (block) = NOT POSSIBLE as V1 promise; any UI requires Foundation decision + additive ADR |
| G-P3 | Platform | Programmatic system DND not in V1 whitelist | 04 S3.1 Capacitor whitelist has no NotificationManager / DND plugin | "Notifications suppressed" in V1 = Aurora's own notifications; system-wide DND = user action |
| G-P4 | Platform | Screen Pinning availability on target Android | 04 S8.3 O3; OQ-06 unresolved | Marked OPTIONAL / BEST-EFFORT / NEEDS_VERIFICATION; not a Phase-1 blocker |

## Unknown / needs verification

| ID | Category | Item | Owner | When |
|---|---|---|---|---|
| G-U1 | Data | Environment values (regions, buckets, provider accounts, registry) — OQ-03 | Foundation | wave 0 |
| G-U2 | Platform | startLockTask() / Screen Pinning on target Android — OQ-06 | Foundation | wave 0 |
| G-U3 | Testing | E2E-on-device framework (Playwright + Capacitor vs Appium) — OQ-08 | QA | wave 7 |
| G-U4 | Provider | Free-tier quota drift (snapshot 2026-09-21; Agnes "a suivre par compte") — OQ-12 | packages/data Model Registry | continuous; recurring CI "provider retirement" test |
| G-U5 | Backend | FOREGROUND_SERVICE necessity (background sync > 30 s) — OQ-04 | Data team | before wave 1 |
| G-U6 | Platform | DPC provisioning + suspendability on target phone (v1.8) — OQ-17 | Foundation + Productivity | wave 0 — **blocking for freezing Focus implementation** |
| G-M7 | Architecture | Feature Registry ratification (G-M7) | Foundation + App Shell | wave 0 |

## Documentation gaps (new, from this pass)

| ID | Category | Gap | Detail | Action |
|---|---|---|---|---|
| G-D1 | Documentation | Composeio integration spec was missing | **RESOLVED 2026-09-22**: docs/integrations/composio.md created | None |
| G-D2 | Documentation | E2E agent scenarios were not enumerated | **RESOLVED 2026-09-22**: docs/agent/e2e-agent-scenarios.md (20 scenarios) | None |
| G-D3 | Documentation | Error / recovery spec per workflow was absent | **RESOLVED 2026-09-22**: docs/agent/error-recovery.md (10 error classes) | None |
| G-D4 | Documentation | Data ownership matrix was implicit | **RESOLVED 2026-09-22**: docs/architecture/data-ownership-matrix.md | None |
| G-D5 | Documentation | Frontend module ownership matrix was implicit | **RESOLVED 2026-09-22**: docs/frontend/module-ownership-matrix.md | None |
| G-D6 | Documentation | Observability spec was scattered | **RESOLVED 2026-09-22**: docs/architecture/observability.md | None |
| G-D7 | Documentation | Focus data model (FocusAppRule, FocusNotificationPolicy, FocusCallPolicy) was not formalised | **RESOLVED 2026-09-22**: focus-mode/spec.md S15 | None |
| G-D8 | Documentation | Registry system was not specified | **RESOLVED 2026-09-22**: docs/architecture/registries.md (7 registries) + contract-catalog S10/S11 | None |
| G-D9 | Documentation | ADR traceability table (Spec -> Contract -> Module -> Backend -> Frontend -> Agent -> Test) was not produced | **RESOLVED 2026-09-22**: docs/architecture/adr-traceability.md | None |

## Implementation status baseline

Because the repo contains no application code, every module capability is
DESIGNED_NOT_IMPLEMENTED (wave-scheduled) or DOCUMENTED_ONLY (contracts /
specs without an implementation owner yet). The first implementation waves
are defined in SPEC.md S "Ordre de vague". This register is re-run after
wave 1 to flip statuses.
