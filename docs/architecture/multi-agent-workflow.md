# Multi-Agent Workflow + Premium UI Stack (2026-09-22)

**Status:** Planning doc. Authority: ADR S7 (Ionic React + Capacitor),
AD-13 (Contract Packs, one-writer-per-file), AD-16c (Foundation owns
packages/platform + CI), 02 S4 (6 layers), 05 S2-3 (DS tokens +
components), docs/epics-stories.md (38 stories, wave 0-7).

## 1. Multi-Agent Roles (parallel, non-blocking)

```
CLAUDE CODE (primary coder)
  -> Codes ALL modules (38 stories across 7 waves)
  -> One module at a time (AD-13: one-writer-per-file)
  -> Each story = 1 branch + 1 PR
  -> DoD: compile + lint + unit tests + contract tests pass

CODEX (deep reviewer, this agent)
  -> Reviews EVERY commit + push (NOT just at PR merge)
  -> Deep analysis: architecture compliance (AD-1..AD-16),
     dependency matrix, event vocabulary, single-writer,
     vendor isolation, data ownership
  -> Each commit: "does this break a spine invariant?"
  -> Deepening: finds gaps Claude Code missed
     (edge cases, missing tests, undocumented assumptions)
  -> Improvement suggestions (not rewrites, additive)
  -> Contract validation: "does this match the Contract Pack?"

DYAD (design + fullstack)
  -> Design System (05 S3-5): tokens, components, themes
  -> Screen implementation (05 S4): layout, spacing, states
  -> Visual QA: screenshots, theme rendering, 30 fps
  -> Premium component selection + integration
  -> Fullstack: UI + data binding (React Query, Zustand)
  -> NOT a second coder for domain logic
     (domain logic = Claude Code; Dyad = presentation layer)
```

### Parallel Safety (how 3 agents don't collide)

| Agent | Owns (files) | Must NOT touch |
|---|---|---|
| Claude Code | `packages/*/src`, `apps/mobile/src/features/*`, server Edge Functions | `packages/ui` (Dyad), `packages/platform` (Foundation) |
| Codex | REVIEW ONLY (no code writes). Comments + suggestions + gap reports | Nothing (read-only) |
| Dyad | `packages/ui/*`, `apps/mobile/src/components/*`, theme JSON, screen layouts | `packages/domain`, `packages/data`, `packages/agent` (Claude Code) |

**The contract that enables parallelism = the Contract Packs (AD-13).**
Each module has:
- Owned files (one-writer rule)
- Public TS interfaces (the contract)
- Input/output events (AD-9)
- Allowed dependencies
- Required states (5 UX + killed)
- Acceptance criteria (DoD)

**Claude Code can start module X as soon as its Contract Pack is
ratified, even if module Y is not yet coded.** The interfaces are
the contract; the implementation comes later.

## 2. Commit / Review Cadence

```
Claude Code:
  commit 1 (feature branch): "task.create + task.update commands"
    -> Codex: reviews in 5 min (architecture, AD-7 single-writer,
       event vocabulary, no cross-module import)
    -> Codex: "PASS" or "REJECT: AD-7 violation, kernel writes
       task table directly"
    -> Claude Code fixes -> commit 2
    -> Codex: "PASS"

Sprint end (end of week):
  Claude Code: all stories merged to main
  Codex: deep review (not just commits, but the ACHIEVED STATE)
    -> "The 5 spine invariants hold. 2 gaps: missing event test
       for TaskCompleted, missing RLS policy on focus_sessions"
  Dyad: visual QA pass (screenshots, theme rendering, 30 fps)
    -> "Home screen renders correctly. Calendar component looks
       dated (old Ionic style). Replace with FullCalendar."
```

## 3. Premium UI Component Selection

**The problem:** default Ionic looks "vieux" (old, corporate, 2015-era).
The user wants PREMIUM, modern, not "vieux calendrier en anglais."

### 3.1 What to REPLACE (from default Ionic)

| Default Ionic component | Problem | Replacement |
|---|---|---|
| `ion-calendar` | Old, corporate, English-style, not modern | **FullCalendar** (multi-view, premium, customizable) |
| `ion-list` (data tables) | Dated, not premium | **AG Grid Community** (if data tables needed) or custom Tiptap-based tables |
| `ion-datetime` | Old, not premium | **date-fns + custom** or FullCalendar date picker |
| `ion-item` (forms) | Dated | **Radix UI** (headless, premium, accessible) + custom tokens |
| `ion-modal` | OK but basic | **Radix Dialog** or **React Portal** with premium animation |
| `ion-tabs` (bottom nav) | Acceptable, keep | Keep (it's the mobile pattern) but restyle with tokens |
| Default Ionic colors | Flat, corporate | **Design tokens** (05 S2.1) + 10 themes (AD-17) |

### 3.2 The Premium Stack (what to ADD)

| Component | Use | Why |
|---|---|---|
| **FullCalendar** (v6+) | Calendar (day/week/month/agenda) + time blocking + Focus sessions | Premium, modern, multi-view, NOT the old Ionic calendar. Custom theme via CSS variables. React Native compatible (via webview). Free (MIT). |
| **Radix UI** (headless) | Forms, dialogs, tooltips, tabs, switches, sliders, command palette | Premium, accessible (WAI-ARIA), headless (no default styling = fully customizable with Aurora tokens). React. Works in Ionic (webview). |
| **AG Grid Community** (free) | Data tables (QCM results, Progress dashboards, resource library) | Premium, virtualized (1000+ rows at 60fps), sortable, filterable. Free (MIT). |
| **Framer Motion** | Animations (page transitions, node pulse, reveal-on-scroll) | Smooth, GPU-accelerated, NOT bouncy. Respects `prefers-reduced-motion` (AD-10 AnimationController, G-M1). |
| **Tiptap** (already in ADR) | Rich text editor (courses, notes, sheets, Mirror) | Already specified. Extensions: math (KaTeX), link, table, highlight, code-block. |
| **KaTeX** (already in ADR) | Math rendering | Already specified (AD-10 MathRenderer). |
| **AntV G2** (already in ADR) | Charts (Progress, Analytics, Focus bilans) | Already specified (AD-10 DataVisualizationRenderer). |
| **React Flow + Dagre** (already in ADR) | Semantic Tree + cross-domain bridges | Already specified (AD-10 SemanticTreeRenderer). Lazy, incremental, 30fps. |
| **AntV Infographic** (already in ADR) | Infographics (multi-resource, with images) | Already specified (AD-10 InfographicRenderer). |
| **Lucide icons** | All icons | Already in 05 DS (not emoji, not custom SVG). 16px in nodes, 20px in header. |
| **Inter / system font** | Typography | 05 S2.1. 13px/500 for feature labels, 20px/700 for progress %, 16px/600 for goal titles. |

### 3.3 What NOT to use (explicitly excluded)

| Library | Why excluded |
|---|---|
| **CopilotKit** | Conflicts with AD-10 frozen engines + 5-state UX + local-first. Too heavy, too opinionated. |
| **Material UI (MUI)** | Web-first, not mobile-native, conflicts with Ionic + design tokens. Not premium on mobile. |
| **Ant Design** | Enterprise, heavy, conflicts with the 10-theme system. |
| **Chakra UI** | Web-first, not mobile-native. |
| **Default Ionic components for premium screens** | "Vieux." Replace with Radix + FullCalendar + AG Grid + Framer Motion. |
| **SVG hero illustrations** | ADR S17: use real/generated images (Agnes Image 2.5 Flash), not decorative SVG. |
| **Rounded > 8px** | DS convention: 8px max border radius (05 S3). |

### 3.4 The Premium Look (how it comes together)

```
NOT: default Ionic (flat, corporate, "vieux")
YES: custom tokens (05 S2.1) + 10 themes (AD-17) +
     Radix (headless, premium interactions) +
     FullCalendar (modern, multi-view) +
     AG Grid (virtualized, premium data) +
     Framer Motion (smooth, GPU, reduced-motion aware) +
     Lucide (clean icons) +
     Inter (clean typography) +
     Dark: #0A0E1A canvas / Light: #F8FAFC canvas (G-H2 resolved)
```

The premium feel = **tokens + headless components + motion + typography.**
NOT a specific component library's default skin. The skin is Aurora's
own (10 themes, AD-17). The components are headless (Radix) so the
skin is fully controlled.

### 3.5 Mobile Premium (specific to Android / Capacitor)

| Concern | Solution |
|---|---|
| FullCalendar on mobile (webview) | FullCalendar is web-based; works in Ionic webview. Touch-optimized views (day/week, not year). `height: auto`, responsive. |
| AG Grid virtualization on mobile | `rowBuffer: 10`, `maxVisibleRows: 30`. 60fps on Pixel 4a (OQ-11). |
| Radix on mobile (touch) | Radix is headless; touch targets >= 44px (05 S2.1 spacing tokens). Custom touch handlers where needed. |
| Framer Motion battery | GPU-accelerated (transform + opacity only). No `layout` animations on mobile (CPU-heavy). `prefers-reduced-motion` = static. |
| Tiptap on mobile keyboard | `contenteditable` in webview. Keyboard avoidance: Capacitor `Keyboard` plugin. |
| Theme switching (10 themes) | `AuroraThemeProvider` (05 S5.8) + CSS variables. Instant, no re-render (GPU). |

## 4. Contracts for Parallel Coding

The documents that enable 3 agents to work simultaneously:

| Contract | File | Owner |
|---|---|---|
| Module Contract Packs (AD-13) | 01-05 packs + docs/architecture/contract-catalog.md | Foundation (wave 0) |
| TS interfaces (AD-15 SSoT) | packages/domain (all entity types, commands, events, envelopes) | Foundation (wave 0) |
| Event vocabulary (AD-9) | docs/architecture/data-event-job-catalog.md (9 events, closed) | Foundation (wave 0) |
| Dependency matrix (AD-2) | docs/architecture/dependency-matrix.md (who reads/writes what) | Foundation (wave 0) |
| Feature Registry (G-M7) | docs/frontend/feature-registry.md (activation, deactivation, modes) | Foundation + App Shell |
| DS tokens + components (05 S2-3) | 05 S2.1 tokens + 05 S3.6 DEFs + 05 S5 themes JSON | Dyad (wave 0-1) |
| Screen inventory (05 S4) | 05 S4 + docs/mobile/navigation-and-page-composition.md | Dyad (wave 0) |
| Premium component list (this doc S3) | This file (FullCalendar, Radix, AG Grid, Framer Motion) | Dyad (wave 0 ratify) |
| Agent Kernel spec | docs/agent/kernel.md (15 components, 15 sections) | Claude Code (wave 3) |
| Vercel AI SDK integration | docs/ai/vercel-ai-sdk-integration.md | Claude Code (wave 3) |
| Engineering Intelligence Layer | docs/scientific-engine/engineering-intelligence-layer.md | Claude Code (wave 2) |
| Goal Engine + Dashboard UI | docs/architecture/dynamic-goal-engine.md + goal-dashboard-ui.md | Claude Code + Dyad (wave 2-5) |

**The rule: an agent can start coding module X when:**
1. Module X's Contract Pack is ratified (AD-13)
2. Module X's TS interfaces are in packages/domain (AD-15)
3. Module X's events are in the 9-event vocabulary (AD-9)
4. Module X's DS screens are in the 05 S4 inventory
5. The premium components for module X's screens are selected

**If all 5 are true, Claude Code starts module X. Dyad starts
module X's screens in parallel. Codex reviews both.**

## 5. Codex Review Checklist (per commit)

At EVERY commit / push, Codex verifies:

| Check | What to look for | Reference |
|---|---|---|
| AD-1 | No vendor imports in domain/ui/apps | contract-catalog S1 |
| AD-2 | No cross-module table access | dependency-matrix S6 |
| AD-3 | No secrets in the diff (grep) | 04 S7.2e |
| AD-7 | Single-writer: this commit only writes its own module's tables | data-ownership-matrix |
| AD-8 | Heavy work = job (not inline) | 01 S5.2 |
| AD-9 | Only 9 events (no new event without additive ADR) | data-event-job-catalog |
| AD-12 | Agent doesn't write module tables directly | kernel S2 |
| AD-15 | Types from packages/domain (no re-declaration) | coverage-matrix |
| AD-17 | Theme tokens used (no hardcoded colors) | 05 S5 |
| 03 S5.4 | No cross-module SQL JOIN | 03 S5.4 |
| Premium UI | No "vieux" component (old IonList for data, old calendar) | This doc S3 |
| Battery | No continuous service (WorkManager, not foreground) | event-reconciliation S1.2 |
| Offline | Feature works offline (local mirror) | data/local-first.md |

## 6. What to Ratify Before Launch

| Item | Owner | When |
|---|---|---|
| Premium component list (FullCalendar, Radix, AG Grid, Framer Motion) | Dyad + Foundation | Wave 0 standup |
| pnpm layout (12 packages incl. 3 engineering) | Foundation | Wave 0 standup |
| AD-15 entity list (add GoalProject, SubGoal, FeaturePlacement, GoalProgress) | Foundation | Wave 0 (additive ADR) |
| UserContext fields for Discovery filtering (region, disciplines, professional_target, budget_constraint) | Identity team | Wave 0 |
| Agnes Image 2.5 Flash in Model Registry seed | Foundation | Wave 0 |
