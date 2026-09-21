# ADR Compliance Report (Deliverable A)

**Scope:** every decision of `Aurora_Architecture_Decisions_v1_7_final` (frozen ADR v1.7, incl.
v1.6 frozen sections and the 2026-09-21 AI multi-provider section) checked against the
downstream design docs (spine AD-1..16, SPEC, packs 01–05) and the (absent) codebase.

**Method:** per mission §1 — authority chain ADR > spine > SPEC > packs; conflicts are
flagged, not silently resolved. Statuses per mission §2.

## Summary verdict

- **All 16 spine invariants (AD-1..AD-16) are carried into the packs** — the packs reference
  them by AD number and the coherence review (2026-09-21) found **0 Critical** findings.
- **No ADR decision is lost**: every ADR section §1–§26 + v1.7 has at least one pack or spine
  reference (see [coverage-matrix.md](./coverage-matrix.md), status column).
- **Implementation status is uniformly `DESIGNED_NOT_IMPLEMENTED` / `DOCUMENTED_ONLY`**
  (design phase, pre-wave-0). No ADR decision is currently `MISSING` from the design; the gaps
  found are *documentation-precision* gaps, not missing decisions.

## Key coverage results

| ADR area | Where it is designed | Status |
|---|---|---|
| Vision / productivity suite (§1, §2) | pack 01 §4.1, 03 §4.2, 05 §4 screens | DOCUMENTED_ONLY |
| Focus & anti-distraction (§2.8) | pack 04 §4.1/§4.2 (platform validation done: no absolute blocking promised) | DOCUMENTED_ONLY; [focus spec](../focus-mode/spec.md) extends the contract (proposed, additive) |
| Learning incl. Mirror Cognitive Mode (§3) | pack 01 §4.2, 05 §4.6–4.8; **Mirror Cognitive Mode has no dedicated pack section** | MISSING design detail (gap G-DOC-04) |
| Agent orchestration (§5, §13, §16) | spine AD-12, pack 01 §5.6, [agent/kernel.md](../agent/kernel.md) | DOCUMENTED_ONLY |
| Semantic tree (§14, §25.2/25.3) | pack 01 §4.3, 03 §4.2 (Knowledge-only writer of `NodeState`), 02 §5.1, 05 §3.6 | DOCUMENTED_ONLY |
| Scientific Engine (§15) | spine AD-10 family, pack 01 §3.2 (`ScientificEngine` port), [module page](../scientific-engine/overview.md) | DOCUMENTED_ONLY |
| Artifact Hub (§16) | pack 01 §4.6/§5.4, 04 §5, AD-10 renderers | DOCUMENTED_ONLY |
| Review-sheet corpus fidelity (§17) | spine AD-11, 02/05 (Tiptap + MathRenderer), pack 01 §5.6 data-policy guard | DOCUMENTED_ONLY |
| Discovery engine (§13) | pack 01 §4.5, `ResearchProvider` port, [module page](../discovery/overview.md) | DOCUMENTED_ONLY |
| Self-improvement / Expert Skills (§14) | pack 01 §4.7 (`expert_skills` server-only), [agent/kernel.md §memory](../agent/kernel.md) | DOCUMENTED_ONLY |
| Progress (§18) | pack 01 §4.4, 03 §4.2 (Progress sole producer of evidence events), [module page](../progress/overview.md) | DOCUMENTED_ONLY |
| Parallelization / waves (§21) | spine AD-13, SPEC wave plan, 01–05 Contract Packs | DOCUMENTED_ONLY (process) |
| Phase 1 mobile-only / portability (§23) | spine (No Electron V1), 04 §8.2, [mobile/overview.md](../mobile/overview.md) | DOCUMENTED_ONLY |
| Visual stack §25 / frozen engines | spine AD-10, 02 §5, 05 §3.6 (AD-10 renderer DEFs) | DOCUMENTED_ONLY |
| v1.5 add-ons (Tiptap, Scanner/OCR, audio, TranscriptionProvider optional, Explain Engine) | 04 §3.2 (contracts), 01 §5.1 (server jobs), [contracts](./contract-catalog.md) | DOCUMENTED_ONLY |
| AI multi-provider v1.7 (§v1.7) | 01 §5.6 (split server-side, secrets placement, fallback, budgets, data policy), [ai/providers-and-routing.md](../ai/providers-and-routing.md) | DOCUMENTED_ONLY |

## Conflicts found (flagged, not resolved)

| # | Conflict | More recent / normative source | Proposed correction |
|---|---|---|---|
| C-1 | Pack 05 §5.2/§5.6/§6.1 describe the neutral canvas as Light `#F8F9FA` / Dark `#121212`; the **frozen normative tokens** (§2.1.2/§2.1.3, "normatives pour la vague 1") define `bg` = `#F8FAFC` (light) and `#0A0E1A` (dark, deliberately blue-tinted to avoid OLED banding). Pack 05 §5.5 (Nocturne preset) already uses the §2.1 values. | §2.1 (frozen tokens) | Editorial alignment of §5.2/§5.6/§6.1 mock values to §2.1.2/§2.1.3 (DS team; no ADR needed — descriptive correction inside a wave-0-draft pack) |
| C-2 | SPEC §05 note lists the 3 presets as "Nocturne, Sable, Forêt"; pack 05 §5.5 (owner: Design System team, SSoT of the DS) lists **Slate, Nocturne, High Contrast**. | Pack 05 §5.5 (sooner-ratified, G1-gated) | Correct the SPEC line at OQ-14/15/16 ratification (G1), pending DS team confirmation |
| C-3 | Coherence review M3/M4: `AppError`/`AppErrorCode` shape lives in pack 02 §10 *body* while 01 §3.1 refuses to restate it → shape not pinned in `packages/domain`. | AD-15 (single SSoT) | Move shape to `packages/domain` (owner Foundation, wave 0); both packs point to `@aurora/domain` |
| C-4 | Coherence review H1: `FocusSessionBilan` contract is non-carrier across 04↔05 (no type, no ChartSpec, no named DS component). | AD-13/AD-15 | Define `FocusSessionBilan` in `packages/domain` (Productivity) + `ChartSpec` in 05 §3.6.9 + named DS component before wave-1 UI cut (review recommendation, unchanged) |
| C-5 | Mission §20 proposes a richer `FocusController` (pause/resume/restore/status) than pack 04 §4.2's minimal contract (start/end/reduceNotifications/isBlockingAvailable). | Pack 04 §4.2 (frozen in pack) | Additive contract extension (additive = normal per Consistency Conventions): record as **proposed**, ratify by Productivity + Foundation before wave 2. See [focus-mode/spec.md](../focus-mode/spec.md) §5 |

## Open items that gate compliance (from SPEC OQ list)

OQ-01 pnpm layout ratification (wave-0 blocker) · OQ-02 team column of the AD-15 mapping
(reduced: entity→module owner→local table already frozen in `03-sync` §4.2) · OQ-03 environment
values · OQ-04 `FOREGROUND_SERVICE` · OQ-05 `ArtifactGenerated` UI consumer ratification in the
AD-9 matrix · OQ-06 Screen Pinning availability · OQ-08 E2E framework (Playwright+Capacitor
driver, Appium fallback) · OQ-14..16 theme catalogue V1 scope + local adaptation scope +
Nocturne preset definition.

## Bottom line

The design layer is **coherent and complete with respect to the ADR**; the risks are
(a) documentation-precision gaps that two teams reading the packs literally could exploit
(coherence review H1/M1–M5, all with prescribed fixes), and (b) platform capabilities that must
never be promised beyond what Android actually allows (Focus Mode — see
[focus-mode/spec.md](../focus-mode/spec.md) verdicts table).
