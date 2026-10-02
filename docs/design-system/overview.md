# Design System & Multi-Theme — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1; theme system = AD-17 candidate, gating G1
for wave-1 UI). Authority: `05-design-system` (owner: Design System team; SSoT of the
DS), `02-frontend` §5/§8, spine AD-10/AD-13, coherence review (H1/M1 + mustFixForV2).

## 1. Purpose

`packages/ui` = the single source of truth for the design system (AD-13, doc §21.2
"Design System → packages/ui et tokens"): direction "Technical Calm" (05 §1),
tokens, component library with 5 canonical UX states, AD-10 renderer
implementations, the screen inventory (44 screens, 05 §4), and the multi-theme
system (05 §5, AD-17 candidate).

## 2. Token discipline (blocking rule)

- Every color/spacing/typography/radius value = a **semantic design token**
  (`aurora.color.*` light + dark, 05 §2.1). Primitives (nuances 50–900) are the
  *only* raw swatches; components never touch them — semantic tokens only
  (§2.1.2/§2.1.3, frozen "normatives pour la vague 1"). **Any hardcoded value
  outside a token = blocking finding** (AI_RULES). No ad-hoc CSS.
- Light default, **Dark is first-class** (05 §2.1: night concentration
  sessions; `bg` light = plain white `#FFFFFF`, dark = `#121212` — the two
  neutral canvas values, no tint or gradient canvas (G-H2 re-2026-10)).
- Fonts: self-hosted variable Inter (body) + JetBrains Mono (formulas/units/data) —
  embedded, offline-first, no CDN (AI_RULES).

## 3. Theme system (05 §5–§6, AD-17 candidate)

Three resolution layers (05 §5.2): **Neutral Style** (Light `bg #FFFFFF` / Dark
`bg #121212` — the G-H2 re-2026-10 tokens; two plain canvas values, no tint or
gradient) × **Expressive Theme** (10 living themes:
Aurora default, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus,
Cosmos — each a full visual universe: 4 colors + gradient + shapes + icon/
selection/focus treatment + chart palette + motion mood, §5.4) + 3 specialized
**presets** combining with any theme (§5.5: **Slate**, **Nocturne** = soft dark
for night, canvas `#121212`, desaturated accents; **High Contrast** = 7:1,
56px targets, 3px focus ring) × **Local Adaptation** (module/screen-scoped token
overrides, declared — V1 = Focus Mode only, OQ-15; no per-screen theme
switching, §5.10).

Blocking rule (§5.1): a theme **never redefines** `success`/`warning`/`danger`/
`info` — semantic states are theme-independent (neutral layer). A PR redefining a
semantic token inside a theme file = rejection (Codex review). Resolution:
`valeur = theme_accent[token] ?? style_neutre[token] ?? défaut` (§5.3).

Technical contracts (§5.8, AD-17 candidate; wave-0 deliverables per 05 §7.2):
themes as **JSON in `packages/ui/src/themes/`** (SSoT, AD-15), `resolveToken` +
`<AuroraThemeProvider>`; theme choice persisted (UI store, `persist` middleware);
**never a silent theme change on foreground return** (05 §2.1 rule); auto-switch
(system/time) explicitly exposed in /settings with preview.

**Flagged conflicts (not silently resolved):** canvas values in 05 §5.2/§5.6/§6.1
(`#F8F9FA`/`#121212`) vs frozen tokens §2.1 (superseded — see G-H2 re-2026-10) →
G-H2 resolved 2026-10 as plain white `#FFFFFF` / plain dark `#121212`; SPEC
preset names ("Nocturne, Sable, Forêt") vs 05 §5.5 (Slate/Nocturne/High Contrast)
→ G-M6. Both must be aligned at G1 ratification (OQ-14..16).

## 4. Components & states (05 §3, AD-13)

Full component library (05 §3.1–3.5: actions/forms/display/navigation/floating
surfaces) each with states `default/pressed/focus/disabled/loading` + the 5
canonical UX states where applicable (matrix 05 §3.7, annex A normative); the 9
data/visualization components wrapping the AD-10 engines (§3.6.1–.9:
DataTable, KeyValueList, Timeline, GanttRow, Sparkline, SemanticTreeNode,
InfographicSlot, MathBlock, FocusTimer) + the animation wrapper (G-M1: to add,
per coherence review).

## 5. AD-10 renderer implementations (DEF side; CONSO = 02 §5, ratified G1)

`@xyflow/react` + `@dagrejs/dagre` → `SemanticTreeRenderer` (lazy level-1,
memoized nodes, incremental Dagre; 30 fps rule 02 §9.2) · `@antv/infographic` →
`InfographicRenderer` (spec → validation → SVG; content separated from engine,
ADR §25.4/§25.5 fidelity rule) · `@antv/g2` → `DataVisualizationRenderer`
(data-driven: progression, stats, series, distributions, scientific results) ·
KaTeX → `MathRenderer` (invalid LaTeX → styled raw source + `onError`, never
crash) · `motion` → `AnimationController` (progressive reveal, reduced-motion
mode). Engines importable **only** inside `packages/ui` (AD-10 boundary,
CI-red elsewhere; SPEC wave-0 gate).

## 6. Screen inventory (05 §4)

44 screens across Onboarding/Home (AD-14 composition fixed), Productivity
(4.3–4.5), Learning (4.6–4.9: library & courses, sheets/QCM/flashcards, coach
mode), Focus (§4.4.2), progress dashboards, knowledge tree, discovery feed,
settings (theme selector + preview). Home invariant: answers *"What matters
now?"* — agenda, next action, main priority, critical progress, due reviews,
Focus access, Coach suggestions — never a widget dashboard (AD-14).

## 7. Accessibility (05 §6.3)

WCAG AA minimum per `theme × neutral style`; tap targets ≥ 44px (56px in High
Contrast); visible focus (ring contrast verified on both styles); reduced motion
per mood; aria-labels (CI test); dark = nuance 400 for contrast (§2.1.3).

## 8. Tests & DoD

05 §11 family (per PR of the DS pack): component state tests (5 states),
renderer non-coupling (no engine in DOM métier), perf (tree 1000 nodes),
theming: 10 themes × 5 screens mockup validation (05 §5.7: 1 example done
Lagoon×Focus, 49 remaining = wave-0 Dyad/UI deliverable, G-L2) + WCAG pass per
pair (wave 7). G1 ratification (02 R8) gates the wave-1 UI cut.

## 9. Normative inconsistencies verified (mission §56, 2026-09-22)

- **Canvas values** (G-H2 re-2026-10): the neutral canvas is re-anchored to
  **plain white `#FFFFFF` (light) / plain dark `#121212`** — no tinted or
  gradient canvas; two styles only (light white, dark `#121212`). The earlier
  frozen tokens (`#FFFFFF`/`#121212`, surfaces `#1E2026`/`#25282F`) and the
  SPEC §5 v2 draft values (`#F8F9FA`/`#121212`) are both superseded.
  `neutral.ts` + `aurora.css` + `tokens.css` re-anchored 2026-10.
- **Preset names** (G-M6/C-2, RESOLVED): SPEC now lists **Slate/Nocturne/High
  Contrast** (05 §5.5 = SSoT); OQ-14/15/16 TRANCHÉ V1 (10 themes from V1; local
  adaptation = Focus only; Nocturne = autonomous preset), ratify at G1.
- **Binary locks** (G-H3, VERIFIED): 02 §3.3/§5.2/§8 + 01 §2.1 + 04 O3b already
  carry `AuroraTheme` (10 values) + orthogonal `themeStyle` — no breaking ADR needed
  if G1 ratifies before the wave-1 UI cut.
- **Rule "thème ≠ composants parallèles"** (05 §5.1 blocking rule + 02 §8): a theme
  changes token values only; a PR redefining a semantic state inside a theme =
  rejection. Residual: theme-JSON regression check in `packages/ui/src/themes/`
  lint (wave 0, G-H2 action).
