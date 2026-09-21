# Gap & Risk Register (Deliverable J)

Severity scale per mission §34. Nothing is masked: platform limitations and unverified facts
are listed as such. Sources: coherence review (2026-09-21), this documentation pass, platform
knowledge (marked `NEEDS_VERIFICATION` where version/Play-policy dependent).

## Critical

(none — the coherence review found 0 Critical; no lost ADR decision.)

## High

| ID | Gap | Type | Detail | Prescribed action |
|---|---|---|---|---|
| G-H1 | `FocusSessionBilan` non-carrier contract (04↔05) | Architecture | No `FocusSessionBilan` type, no `ChartSpec` of the bilan, no named DS component — two teams reading 04+05 literally produce divergent specs (AD-13/AD-15 violation risk). Review H1 | Fix before wave-1 UI cut (G1 02 R8): type in `packages/domain` + `ChartSpec` in 05 §3.6.9 + component in 05 §3.6/§3.7 (review recommendation verbatim) |
| G-H2 | Pack 05 canvas-value conflict (C-1) | Documentation | §5.2/§5.6/§6.1 use `#F8F9FA`/`#121212`; frozen tokens §2.1.2/§2.1.3 use `#F8FAFC`/`#0A0E1A`. A theming implementation following §5.6 would deviate from the frozen light/dark base. | Editorial alignment of §5 v2 mock values to §2.1 (DS team, wave 0); add a regression check in the theme JSON lint (`packages/ui/src/themes/`) |
| G-H3 | 5 `mustFixForV2` theme binary locks (01/02/04) | Architecture | `02 §3.3` store `theme: 'light'|'dark'`, `02 §5.2` infographic `theme` prop, `02 §8` dark-mode rule, `04` default-theme-on-kill, `01 §4.x` `user_context` theme value — all assume a binary that the AD-17 theme system (10 values) breaks; if frozen binary first, the v2 becomes a breaking ADR. | Execute the 5 review fixes in wave 0 (store/theme prop = v2 enum SSoT `packages/domain`; migrator in `packages/domain`; fallback = light default) |

## Medium

| ID | Gap | Type | Detail | Action |
|---|---|---|---|---|
| G-M1 | `AnimationController` has no DS wrapper (review M1) | Architecture | 05 §3.6 wraps 4 of 5 AD-10 contracts; the 5th (`AnimationController`, 02 §5.5) has no named DS component exposing its exact props. | Add `AnimationSlot`/`useAuroraAnimation` in 05 §3.6 (before G1 wave-1 cut) |
| G-M2 | `killed` app state not in the 5-state UX matrix (review M2) | Architecture | Android task-kill is an implicit 6th state (04 §6.1/§7.1); 02 §7 and 05 §3.7 matrices lack it. | Add `killed` as a sub-state of `loading` (skeleton + re-sync) in 02 §7 + 05 §3.7 column |
| G-M3 | `AppError` SSoT split (review M3/C-3) | Architecture | Shape in 02 §10 body; 01 §3.1 refuses to restate → not pinned in `packages/domain`. | Move shape to `packages/domain` (wave 0, owner Foundation) |
| G-M4 | `job_queue` field SSoT split (review M4/M5) | Architecture | `source_local_mutation_id` (ULID) referenced across 01 §5.3 ↔ 03 §5.5 without a single owner of the full shape. | Freeze the full `job_queue` shape (incl. nullable `source_local_mutation_id` + computed `idempotency_key`) in 01 §5.3; 03 points only |
| G-M5 | `ChartSpec` SSoT undecided (review L4) | Architecture | G2 spec shape is "figé par le DS" in 02 §5.3 but defined nowhere. | Decide owner (`packages/ui` per review recommendation) + publish shape in 05 §3.6 (wave 0) |
| G-M6 | SPEC presets line stale (C-2) | Documentation | SPEC says "Nocturne, Sable, Forêt"; 05 §5.5 says Slate/Nocturne/High Contrast. | Ratify at G1 (OQ-14..16) and correct SPEC |

## Low

| ID | Gap | Type | Detail | Action |
|---|---|---|---|---|
| G-L1 | 04 frontmatter dependency direction (review L3) | Documentation | `minSyncIntervalMs`: 04 **imposes** the constraint, 03 **defines** the parameter; frontmatter says the opposite. | Clarify 04 frontmatter (wave 0) |
| G-L2 | 49 theme×screen mockups not produced | Documentation | 05 §5.7 defines the mechanism + 1 example; the 49 remaining pairs are a wave-0 Dyad/UI deliverable. | Track as wave-0 deliverable (owner Dyad/UI team, ADR §22) |
| G-L3 | Mirror Cognitive Mode (ADR §3) has no pack section | Documentation | ADR names it (student explains understanding; Aurora detects gaps/contradictions/errors) but no pack designs the flow, data, or agent behavior. | Add to Learning pack (wave 2 prep) — gap G-DOC-04 |
| G-L4 | `ArtifactGenerated` UI consumer (OQ-05) | Architecture | Pack 02 declares a UI consumer; the AD-9 matrix lists Knowledge/Learning only. | Ratify in the AD-9 matrix at next spine ADR (additive) |

## Platform limitations (documented, never promised beyond them)

| ID | Limitation | Evidence / basis | Consequence for docs |
|---|---|---|---|
| G-P1 | **No app-blocking by a consumer third-party app on Android.** No public API to block/restrict arbitrary apps; Digital Wellbeing App Timers are system features (no third-party API); `DevicePolicyManager` requires device owner/MDM; Accessibility-based blocking risks Google Play rejection. | Pack 04 §4.1 verdict (normative), ADR §2.8 rule | Focus Mode promises *restriction* (in-app + DND guidance + optional Screen Pinning), never *blocking*. `isBlockingAvailable()` = `false` on V1 Android; UI must not show a "block apps" CTA |
| G-P2 | **Call control is role-gated, not app-gated.** `CallScreeningService` (API 23+) requires the user to select Aurora as the call-screening app; strict framework response deadlines; Google Play review for the category; OEM/region variability. V1 docs must not state "Aurora blocks calls". | Android `CallScreeningService` (NEEDS_VERIFICATION on target API levels + Play policy, 2026) | Level 1 (silence calls) = platform-dependent option; Level 2 (block) = NOT POSSIBLE as a V1 promise; any UI requires a dedicated Foundation decision + Play-policy review (additive ADR) |
| G-P3 | **Programmatic system DND is not in the V1 whitelist.** The Capacitor whitelist (04 §3.1) contains no custom plugin for `NotificationManager`/Notification Policy access; DND remains a *user-guided* recommendation. | 04 §3.1 + §4.1 | "Notifications suppressed" in V1 = **Aurora's own notifications** (OneSignal unsubscribe + local mute); system-wide DND = user action |
| G-P4 | **Screen Pinning availability on target Android versions** = OQ-06 (unresolved). | 04 §8.3 O3, OQ-06 | Marked `OPTIONAL / BEST-EFFORT / NEEDS_VERIFICATION`; not a Phase-1 blocker |

## Unknown / needs verification

| ID | Item | Owner | When |
|---|---|---|---|
| G-U1 | Environment values (regions, bucket names, provider account IDs, registry values) — OQ-03 | Foundation | wave 0 |
| G-U2 | `startLockTask()`/Screen Pinning on target Android versions — OQ-06 | Foundation | wave 0 |
| G-U3 | E2E-on-device framework (Playwright + Capacitor driver vs Appium) — OQ-08 (assumption: Playwright) | QA | wave 7 |
| G-U4 | Free-tier quota drift (snapshot 2026-09-21; Agnes quotas "à suivre par compte") — OQ-12 | `packages/data` Model Registry (AD-16b) | continuous; recurring CI "provider retirement" test |
| G-U5 | `FOREGROUND_SERVICE` necessity (background sync > 30 s) — OQ-04 | Data team (03 §5.7) | before wave 1 |

## Implementation status baseline

Because the repo contains no application code, **every** module capability is
`DESIGNED_NOT_IMPLEMENTED` (wave-scheduled) or `DOCUMENTED_ONLY` (contracts/specs without an
implementation owner yet). The first implementation waves are defined in
`SPEC.md` § "Ordre de vague". This register is re-run after wave 1 to flip statuses.
