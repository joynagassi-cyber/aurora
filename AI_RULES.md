# AI_RULES — Aurora

Aurora is a personal productivity + learning + agentic-orchestration suite, delivered **Phase 1 mobile-only** (Android: Ionic React + Capacitor) on a **frozen composite architecture** (ADR v1.7, spine AD-1…AD-17). This file is the **living reindex guide for coding agents**: it (1) reflects the *actual* state of the working tree, (2) tells you *which library to use for what*, and (3) is the **decision-navigation hub** — every major decision has a "decided in → implemented in → gated by" pointer so any agent can locate it fast.

> **How to use this file:** read the **Reality check** + **Decision Map** first (they tell you *what's true now* and *where to go*), then the **Repo map** (the real tree), then the **library rules** + **hard constraints** before writing code. The authority docs below are read-only; this file supersedes *stale status banners* in those docs when they disagree with the working tree (see **Reality check**).

---

## 1. Reality check (read first — the tree has moved)

**⚠️ Doc-lag warning:** the authority docs (and this file's *earlier* revision) carry a wave-0 banner that reads *"design/solutioning phase — no application code ships yet, packages are stubs."* **That is now stale.** The working tree has delivered **waves 0 → 7** and is at the **v0.1.0 release-candidate** stage.

The live source of shipped state is, in order:
1. **`docs/release/changelog.md`** — the per-wave release history (wave 0…7, what each shipped).
2. **`git log`** — commit-level truth (each wave is tagged `wave{N}/{agent}: …`; last recorded full gate: **236 unit tests pass / 0 fail**, all boundary + RLS + view-join greps green).
3. **`_bmad-output/project-context.md`** + **`project-context-changelog.md`** — the engineering context log.

So: **`apps/` + `packages/` contain real, tested code; `supabase/` has 20 applied migrations + 4 Edge Functions; the mobile app has all its screens.** When a doc says "DESIGNED_NOT_IMPLEMENTED" / "DOCUMENTED_ONLY" but the changelog + a `packages/*/` implementation say otherwise, **trust the changelog + code.** Only treat a capability as designed-not-built if it's *absent from the tree AND absent from the changelog.*

**Agent session scratch:** `.claude/worktrees/` holds git worktrees + `node_modules` from past agent sessions — **gitignored, regenerable, and NOT part of the codebase. Do not navigate or edit inside it.**

---

## 2. Authority chain (read-only)

`ADR v1.7 (adr-extract.md, frozen)` → `ARCHITECTURE-SPINE.md (AD-1…AD-17)` → `SPEC.md` → Contract Packs `01–05` → `docs/*` (prescriptive) → **this file** → (live state) `docs/release/changelog.md` + `git log`.

If a *frozen* doc contradicts the working tree, that's a **doc-lag** — surface it (flag in [gap-register.md](docs/architecture/gap-register.md) or a PR note), **don't silently resolve it**, and don't "fix" a frozen doc without a documented ADR.

| Anchor doc | Path |
| --- | --- |
| Spine (AD-1…AD-17, frozen invariants + stack) | `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` |
| ADR v1.7 (frozen, §1–§26) | `…/adr-extract.md` |
| SPEC + OQ-01…OQ-17 | `…/SPEC.md` |
| Contract Packs 01–05 | `…/dimensions/01-backend … 05-design-system.md` |
| Adversarial/coherence reviews | `…/reviews/*.md` |
| Readiness audit (wave-0 gate) | `_bmad-output/implementation-readiness-report-2026-09-22.md` |
| Engineering context log | `_bmad-output/project-context.md` (+ `-changelog.md`) |

---

## 3. Repo map (the real tree)

19 packages + 2 apps + supporting infra. Dependency rule: **`domain` imports nothing**; vendor SDKs live only in adapter packages + server (AD-1); `ui` never imports `data`/`platform`; feature slices never import sibling slices (AD-2/AD-13).

### Hexagon center
- **`packages/domain`** — SSoT of *all* frozen shared types (AD-15): envelopes (`ApiEnvelope`,`AppError`,`AsyncState`,`AIResponseEnvelope`), CRDT OR-Set, 11 entity modules (40+ entities: productivity/learning/knowledge/progress/discovery/artifact/agent/goal/integrations/identity/engineering), the closed **9-event** vocabulary (AD-9), **14 ports**, the **9 AI-pipeline contracts**, and 7 registries. **Imports nothing; no vendor.** Consume it, never re-declare it.

### Foundation / infra
- **`packages/data`** — PowerSync/SQLite repos + sync engine (`sync-engine`,`crdt-orset`,`server-wins`,`upsync-queue`), `powersync-client/schema`, `supabase-connector`, `react-query-bridge`, `repositories`. **Vendor confined here (AD-1):** `@powersync/*` + `@supabase/supabase-js`. Owns the **Model Registry** (AD-16b).
- **`packages/ui`** — Design System: tokens + ~40 shadcn/Radix components + data components (`AgGridTable`,`DataTable`,`CalendarView`,`GanttRow`,`StatTile`,`KeyValueList`,`Timeline`), the **5 AD-10 renderers** (`SemanticTreeRenderer`,`InfographicRenderer`,`DataVisualizationRenderer`,`MathRenderer`,`AnimationController`), and the **themes JSON SSoT** (10 themes + 3 presets + neutral + `resolve` + `AuroraThemeProvider`). **All AD-10 engines live ONLY here** (`@xyflow/react`,`@antv/*`,`katex`,`motion`,`@fullcalendar/*`,`ag-grid` — see [library rules](#5-library-rules)).
- **`packages/platform`** — Capacitor adapters behind typed interfaces: `lifecycle`,`local-notification`,`remote-notification` (OneSignal),`network`,`dpc`/`dpc-adapter` (v1.8 DPC),`boot-receiver`,`bilan`. **The only native surface; the app never imports `@capacitor/*` directly** (CI lint boundary).
- **`packages/agent`** — the **Agent Kernel** (15 components: intent → context → planner → capability/tool/permission/confirmation → router → execution → verification → result → memory → observability → recovery) + `tools` (8 kernel tools) + **the AD-1 exception: the Vercel AI SDK layer** (`ai` v7 + `@ai-sdk/openai-compatible`) + expert skills + command bus + run-state + model/providers + goal capabilities. **Server-side; the device sees only `AgentRunState` (F-09).**

### Feature domains (vertical slices)
- **`packages/productivity`** — tasks, habits, routines, goals-projects, eisenhower, calendar, inbox, reviews, focus (session/timer/blocklist logic), events, jobs.
- **`packages/learning`** — FSRS, QCM, retrieval, semantic-tree, mirror-cognitive, study-sheets, course-import.
- **`packages/goal-engine`** — dynamic goal engine: decomposition, layout, mutations, patterns, progress.
- **`packages/progress`** — dashboard, evidence, recompute, trajectories, jobs. **Sole producer of progress (F-07).**
- **`packages/discovery`** — discovery feed, gaps, filtering, research-provider, jobs.
- **`packages/focus`** — **`controller.ts` is the SSoT of `FocusControllerPort`** (startSession/endSession/reduceNotifications/isBlockingAvailable + v1.8 DPC `precheckBlocklist`/`applyBlocklist`), timer, pomodoro, bilan, service.
- **`packages/ascent`** — Slide-Ascent: adapter, baseline, depth, path-builder, read-do-prove, source-hierarchy, kernel-integration.
- **`packages/integrations`** — Composio (`IntegrationProvider`), notification adapters, automations, research-provider.
- **`packages/scientific-engine`** — generic math/units behind `ScientificEngine` (+ `engineering-*` decomposition: `engineering-core/solvers/adapters/registry` — Problem IR, 6 registries, deterministic solvers, swappable adapters).
- **`packages/workflows`** — the **23 composite workflows** (`w1…w23`) + `event-flow`,`error-recovery`,`recovery-plan`,`self-improvement`,`validate` + E2E scenarios.

### Apps
- **`apps/mobile`** — Ionic React + Capacitor shell + **all screens** (`home`,`goals`,`tasks`,`projects`,`knowledge`,`learn`,`discovery`,`focus`,`calendar`,`inbox`,`agent`,`artifacts`,`ascent`,`progress`,`settings`,`not-found`) + `shell/Shell`,`router`,`query/` (React-Query bridge),`state/ui-state` (Zustand UI-only),`modes/` (product-modes + command-palette),`feature-registry`,`ux/` (polish + theme-adapter),`perf/` (budgets + measure),`hooks/` (use-killed, use-online), and a full test suite.
- **`apps/server`** — the server-side workspace member (server kernel/AI/jobs bundle entry). The actual deployable **Supabase Edge Functions live in `supabase/functions/`**.

### Supporting infra (root)
- **`supabase/`** — **20 migrations** (`0001…0020`; `0020` = live-applied tracking marker), **4 Edge Functions** (`fn-agent-run`,`fn-import-course`,`fn-job-dispatcher`,`fn-notifications` + `_shared/envelope`), `config.toml` (pg_cron + EF catalog), `README.md`.
- **`powersync/`** — relay schema/config (`relay.sql`,`schema.json`,`sync-config.yaml`,`service.yaml` (supabase client_auth, AD-3 JWKS auto-detect),`cli.yaml`,`roundtrip.md`).
- **`scripts/`** — the static gates: `check-boundaries.sh` (G1–G4), `check-rls.sh`, `check-view-joins.ts`, `r2-presign.ts`, `ef-test.ts`.
- **`tests/`** — `spine/` (2 équipes → 1 contrat, AD-15 type-cross-check), `e2e/` (Playwright device + node-native), `rls-penetration.sql`.
- **`e2e/`** — OQ-08 device driver + specs (Playwright over Capacitor webview).
- **`docs/`** — ~90+ prescriptive pages (start [00-overview](docs/architecture/00-overview.md) + [ui-libraries.md](docs/ui-libraries.md)).
- **`_bmad-output/`** — architecture anchors (above) + `ux-designs/` + `wds/` (product brief, trigger map, UX scenarios) + readiness report + context log.
- **`prompts/`** — the **agent roster** (named wave agents) + session prompts + Dyad beta/QA prompts (see [Agent roster](#8-agent-roster-how-the-work-is-run)).
- **`.github/`** — `workflows/ci.yml` + `workflows/release.yml` + `BRANCH-PROTECTION.md`.
- **`set-secrets.ps1`** — pushes the config/env contract to GitHub Actions secrets ([Config & secrets](#7-config--secrets-deploy-contract)).

---

## 4. Tech stack (what's actually installed)

- **Frontend:** Ionic React + TypeScript, mobile-first; UI built from **shadcn/ui + Radix + Tailwind** driven by Aurora **design tokens** (CSS variables), never library defaults.
- **Mobile shell:** Capacitor (Android = Phase 1; `packages/platform` adapters only). **Electron = Phase 2 only.**
- **Monorepo:** pnpm 10 + TypeScript (strict, `noUncheckedIndexedAccess`); root `tsconfig.json` = project references; `packageManager: pnpm@10.28.0`, Node ≥ 22.
- **Local-first data:** **PowerSync + SQLite** on device; UI reads local first; offline is a first-class state (AD-7).
- **Backend:** **Supabase** — PostgreSQL (SoT, live project ref `opagfyspdbhxthlxvlrk`) + Auth + Edge Functions + pg_cron (job dispatcher) + **pgvector** (768-dim, semantic retrieval).
- **Files:** **Cloudflare R2** (private buckets + presigned URLs; key convention frozen in [r2.md §1](docs/cloudflare/r2.md), *not* 01 §5.4).
- **AI:** server-side, multi-provider behind the `AIProvider` port — **Agnes (always primary)** → Cloudflare AI Gateway → Workers AI → optional Groq/Cerebras/OpenRouter → CF Worker last-resort. Orchestration via the **Vercel AI SDK (`ai`)**. **No key/secret ships to the device (AD-3).**
- **Observation:** **Sentry** (errors + perf SLOs) + **PostHog** (analytics, EU host).
- **Testing:** **Vitest** (unit, no DOM) + **Playwright** (device E2E; Appium = fallback) + a **node-native gate** (`node --experimental-strip-types --test …`).
- **CI/CD:** **GitHub Actions** (`main` always buildable; boundary-lint + vendor/secret/RLS/view-join gates; tag `v*` → release.yml → APK + release notes).

---

## 5. Library rules (what to use for what)

> Authoritative component map: **[docs/ui-libraries.md](docs/ui-libraries.md)** (install commands + "never write a component a library already provides"). Verified against `packages/ui/package.json` + `apps/mobile/package.json`. Every value routes through **Aurora design tokens** — no `#000`/`#fff`, no ad-hoc CSS.

### UI shell & components
- **shadcn/ui + Radix + Tailwind** for all base controls (button, card, dialog, drawer, input, textarea, select, checkbox/radio/switch, slider, tabs, accordion, tooltip, popover, command, toast, alert, badge, avatar, progress, skeleton, sidebar, breadcrumb, pagination, scroll-area, separator, label, form, …). **`packages/ui/src/components/ui/` already ships these** — import them, don't fork them.
- **Premium accents** via shadcn registries: **Aceternity UI** + **Magic UI** (WobbleCard, InteractiveCard, Beam, Marquee, NumberTick, ShineEffect) for GoalProject cards / Focus visuals / micro-interactions.
- **Forms:** `react-hook-form` + `@hookform/resolvers` + `zod`. **Icons:** `lucide-react` (16px nodes / 20px header). Never emoji, never custom SVG. **Typography:** self-hosted **Inter** (`@fontsource/inter`) + **JetBrains Mono** for formulas/units/data.
- **Mobile shell (Ionic):** `IonRouter`/tabs/headers/lists/modals where native chrome is wanted; detail screens open **over** the current tab (IonModal/IonSlides). Command palette = Radix Command overlay, not a route.

### Data tables & grids
- **Heavy/virtualized tables (100+ rows):** **AG Grid** (`ag-grid-community`/`ag-grid-react`) — `packages/ui` ships `AgGridTable` (`rowBuffer:10`,`maxVisibleRows:30`). **Light tables (<20 rows):** shadcn `Table` (or `DataTable`). **Not** `ion-list` for data.

### Calendar, lists, rich text
- **FullCalendar** (`@fullcalendar/react` + daygrid/timegrid/list/interaction) for day/week/month/agenda + time blocking — `packages/ui` ships `CalendarView` + `GanttRow` + `Timeline`. **Not** `ion-calendar`/`ion-datetime`; date picker = FullCalendar in a shadcn Popover.
- **Lists:** native `IonList` <100; **`react-virtuoso`** >100 (fallback OQ-09). **Kanban/reorder:** **`@dnd-kit`**.
- **Tiptap** (`@tiptap/react` + starter-kit + math/link/table/highlight/code-block) for notes/reviews/annotations/AI-assisted editing; custom exts `SourceRefInline` (provenance AD-11), `CorpusBadge` (teacher vs. Aurora text, ADR §17). Yjs = Phase 2.

### Visualization (frozen AD-10 — import ONLY inside `packages/ui`, behind the 5 renderer contracts)
Business/feature code **never** imports these directly (ESLint `no-restricted-imports` + grep G-gates; CI-red). The engines are installed **only as `packages/ui` deps**:

| Use | Engine (package) | Contract (in `packages/ui/src/renderers/`) |
| --- | --- | --- |
| Semantic Tree (knowledge hierarchy) | **React Flow** (`@xyflow/react`) + **Dagre** (`@dagrejs/dagre`/`dagre`) | `SemanticTreeRenderer` |
| Agent explanations / infographics | **AntV Infographic** (`@antv/infographic`) | `InfographicRenderer` |
| Data / proficiency / scientific charts | **AntV G2** (`@antv/g2`) | `DataVisualizationRenderer` |
| LaTeX & math | **KaTeX** (`katex`) | `MathRenderer` |
| Micro-interactions / progressive reveal | **Framer Motion** (`motion`; spine alias `motion`) | `AnimationController` |

- The **engine is never the source of truth** (AD-6); React Flow only *renders* the Knowledge-Base tree.
- **Lazy + memo:** engines load via `React.lazy` only when their screen opens; Home excludes them; the Semantic Tree renders root + level-1, lazy-loads deeper, memoizes nodes, recomputes Dagre incrementally (**30 fps, ≤150 visible nodes** — `packages/ui/scripts/semantic-tree-30fps.mts` is the device harness).
- **Graceful degradation:** `MathRenderer` on invalid LaTeX → styled raw source + `onError`, never crash. **Animations:** GPU-only, not bouncy (150–250 ms), respects `prefers-reduced-motion` (`apps/mobile/src/ux/polish.tsx`: PageTransition/NodePulse/Reveal).

### State & data
- **Zustand** = **UI state only** (`apps/mobile/src/state/ui-state.ts`: selections, view modes, scroll anchors, theme/themeStyle, focus-mode, palette). Persist cosmetics via `persist`. **Never cache a domain entity (AD-7/F-03).**
- **`@tanstack/react-query`** = **data**, reading **only** the PowerSync/SQLite local store (keys `[module, entity, …filter]`; bridge `packages/data/src/react-query-bridge.ts` + `apps/mobile/src/query/`). No Redux/RTK.
- **Local-first:** UI reads local, mutates via the owning module's use-case, PowerSync propagates. **Never mutate a SQLite table directly (single-writer AD-7/F-03).** Conflicts: server-wins + per-entity `updated_at`; merge lists use the frozen **OR-Set CRDT** (`packages/domain/crdt`).

### AI (server-side only) — the AD-1 exception
- Call AI **through the `AIProvider` port**; orchestrate with the **Vercel AI SDK** (`ai`): `streamText`/`generateText` + `maxSteps` + typed `tools` + `onStepFinish`, `aiRouter.selectModel(taskProfile)` → a `LanguageModel`.
- **`ai` is imported ONLY in `packages/agent`** (its `tools.ts`,`sdk.ts`,`model.ts`,`providers.ts`,`gateway.ts`,`adapters.ts`) — the ESLint config carves `packages/agent` out of the vendor ban *for the AI-SDK layer only* (still bans AD-10 engines + every other vendor). Domain/UI/feature code never import it (grep gate).
- Pipeline: `Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → CF AI Gateway → Provider Adapter → model`. **Agnes is ALWAYS primary** (return to it after any fallback). **CopilotKit is excluded.**
- **No keys/secrets on the device (AD-3)** — keys from env only. A **429 is never bypassed by rotating keys**; every response is traceable via `AIResponseEnvelope`. **`Agnes Image 2.5 Flash`** powers infographic photos (≤2/infographic; `fal.ai` fallback).
- **Exports** (PDF/DOCX/PPTX/XLSX/images) = server `artifact_gen` job → R2 → `ArtifactGenerated` (post-upload only).

### Scientific / engineering
- **`packages/scientific-engine`** = generic math/units behind `ScientificEngine` (LaTeX = representation). **`packages/engineering-*`** = Problem IR + 6 registries + 5-stage validation + deterministic execution + 4-layer RAG. **The LLM orchestrates; the solver computes; the verifier validates.** Surface `INSUFFICIENT_DATA`, never "100% reliable". Heavy compute = a **server job** (AD-8).

### Integrations & optional capabilities
- **Research:** `ResearchProvider` (You.com/Tavily/Exa). **Integrations:** **Composio** behind `IntegrationProvider` (a tool layer, *not* an AI provider; creds server-side). **Notifications:** **OneSignal** (server push) + Capacitor **local** (deadlines/Focus) — never both for one object. Optional capabilities (OCR, transcription, artifact gen, search, scientific compute) are swappable providers and/or async jobs that **degrade gracefully when absent.**

### Mobile platform (Capacitor)
- `packages/platform` exposes typed adapters (`lifecycle`,`LocalFileStorage`,`DocumentScanner/OCRProvider`,`Audio/Transcription` (optional),`RemoteNotification` (OneSignal),`LocalNotification`,`NetworkStatus`,`FocusController`). The app imports **only** these, **never `@capacitor/*`** (CI lint boundary). **Plugin whitelist (04 §3.1):** `@capacitor/{app,status-bar,keyboard,filesystem,http,camera,media,push-notifications,network,splash-screen}` + `@onesignal/react`. Any other plugin = Foundation PR.
- **Focus v1.8 DPC (OQ-17):** private single-device, Device-Owner provisioning (`dpm set-device-owner`), `DevicePolicyManager.setPackagesSuspended` (API 29+); consumer-app fallback = restriction-only (in-app timer + DND guidance + optional Screen Pinning). **Never promise native "app blocking"** on a consumer device.

### Testing & quality
- **Vitest** (unit/domain, no DOM) + **Playwright** (device E2E, OQ-08; Appium fallback) + the **node-native gate** (run under CI). Sentry enforces SLOs: **≤300 Ko JS gz, ≤1.5 s TTI (Pixel 4a), 30 fps on the tree** (`apps/mobile/src/perf/` is the static budget gate).
- Every async screen implements **6 UX states**: `loading / empty / success / error / offline / killed` (AD-13; "killed" = G-M2, sub-state of loading; `apps/mobile/src/ux-states.tsx` + `hooks/use-killed.ts`).

## 6. What NOT to use

| Avoid | Use instead / why |
| --- | --- |
| `ion-calendar`, `ion-list` (for data), `ion-item` (for forms), `ion-datetime` | FullCalendar / AG Grid / shadcn-Radix / FullCalendar+Popover |
| MUI / Ant Design / Chakra | shadcn/ui + Radix + Tailwind (conflicts with Ionic + tokens) |
| **CopilotKit** | Vercel AI SDK + Aurora's own AD-10 renderers |
| Redux / Redux Toolkit | Zustand (UI) + React Query (data) |
| Custom SVG decorations / hardcoded colors | Real or generated images (Agnes Image); semantic design tokens only |
| Bouncy animations / border radius > 8px | Framer Motion smooth (reduced-motion aware); DS convention (05 §3) |

## 7. Hard constraints (do not violate)

- **AD-1 vendor isolation:** no vendor SDK / concrete model name in domain/UI/feature code; providers sit behind typed ports. Vendor SDKs only in `packages/data`/`packages/agent`(AI-SDK)/`apps/server` + adapters.
- **AD-3 no secrets on device:** R2 via presigned URLs; OneSignal app-key in `capacitor.config.ts` only; all provider/OneSignal/Composio keys server-side.
- **AD-2 module boundaries via RLS:** RLS is the data-level enforcement; no cross-module table joins; no writing another module's tables. (gated by `check-rls.sh` + `check-view-joins.ts`).
- **AD-7/F-03 single-writer:** the kernel/UI never mutates a table directly — emit a command/event; the owning module applies it.
- **AD-8 async jobs:** heavy work = a persisted, idempotent, retryable, observable job (Supabase Cron + Postgres trigger → `fn-job-dispatcher`). Never block the UI.
- **AD-9 targeted events:** exactly **9** named events, one producer + declared consumers; simple ops stay direct commands.
- **AD-10 boundary:** the 5 viz engines importable **only** inside `packages/ui`; elsewhere CI-red.
- **AD-15 one SSoT per type:** all shared entities/envelopes/ports/events live in `packages/domain`; a "view" is a declared projection, not a new entity. (gated by `tests/spine`).
- **AD-14 Home invariant:** Home always answers *"What matters now?"* with the fixed composition (agenda · next action · main priority · critical progress · due reviews · Focus access · Coach suggestions). Never a widget dashboard.
- **AD-17 themes:** a theme **never** redefines `success/warning/danger/info` (theme-independent semantics); resolve via `resolveToken` + `<AuroraThemeProvider>`; `value = theme_accent[token] ?? neutral[token] ?? default`; persisted theme beats system in V1; never a silent theme change on foreground return.
- **Phase 1 mobile-only:** no Electron/microservices/Event Sourcing/Yjs/local STT in V1. **AD-13:** 1 story = 1 commit = 1 rollback; `main` buildable; merge via PR + review.

## 8. Agent roster & how the work is run

The work runs via **named agent briefings** in `prompts/` that feed the **composite workflows** in `packages/workflows` (23 workflow definitions + `w1…w23` runners) and the per-wave session prompts. Each prompt is a wave/agent briefing with an explicit "read these docs first" list, a frozen working dir, and a DoD.

| Agent prompt (`prompts/*.md`) | Wave | Role (deliverable) |
| --- | --- | --- |
| `achilles.md` | 0 | Foundation — monorepo scaffold + all domain types (`packages/domain`) |
| `minerva.md` | 0 | Backend — Supabase schema + RLS + R2 + PowerSync relay |
| `hermes.md` | 0 | CI/CD pipeline + boundary tests (G1–G4) + spine test |
| `oracle.md` | 3 | Agent Kernel (AD-12) + Vercel AI SDK + expert skills + Agnes router |
| `sophia.md` | 3 | Ascent — the pedagogical trajectory engine (Slide-Ascent) |
| `hephaestus.md` | 3 | Dynamic Goal Engine (GoalProject) + Goal Dashboard UI |
| `harpys.md` | 4 | The 23 composite workflows + 20 E2E scenarios + self-improvement + error recovery |
| `erynis.md` | 5+7 | UI polish + E2E device (OQ-08) + perf + release candidate |

Other prompts: `session-1…4-wave*.md` (per-wave session briefings), `dyad-beta-device-ui.md` (the Dyad device-UI beta build path + Ascent wiring), `dyad-design-qa.md` (the **DAPHNE** design-QA pass — "no double work"), `supabase-free-tier-heartbeat.md` (keep the `0018` `keep_alive` pg_cron job pinging the live project so it never auto-pauses).

> Note: git-log also carries **attribution labels** for sub-roles that have no dedicated prompt file — **ORION** (jobs/dispatcher), **ATLAS** (productivity slice), **HYPATIYAS** (Focus domain), **DAPHNE** (design QA → `dyad-design-qa.md`). Read them as attribution tags, not separate briefings.

---

## Decision Map (the engineering-context hub)

For any decision, **"decided in"** is the *where the invariant lives* (authority doc) and **"implemented in"** is the *where it's coded/gated* (working tree). This is the index that keeps the context "packaged" and navigable.

| Decision theme | Decided in (doc) | Implemented / gated in (code) | Owner |
| --- | --- | --- | --- |
| Vendor isolation (AD-1) | `01`/`02` + `docs/architecture/dependency-matrix.md` | `eslint.config.js` (restricted-imports carve-out for `packages/agent` AI-SDK) + `scripts/check-boundaries.sh G1/G2` | Foundation |
| Module boundaries + RLS (AD-2) | `01-backend` §2.2/§3.4 + `docs/architecture/data-ownership-matrix.md` | `supabase/migrations/*` + `scripts/check-rls.sh` + `scripts/check-view-joins.ts` + `tests/rls-penetration.sql` | Data |
| Single-writer (AD-7/F-03) | `03-sync` §5 | `packages/data` (repos/upsync/server-wins) + `packages/agent` emits-not-writes + `tests/spine` + `packages/*/test/*single-writer*` | Data |
| Local-first + CRDT (AD-7) | `03-sync` §4–§5 | `packages/data/{crdt-orset,local-store,sync-engine}` + `powersync/` (relay/schema/sync-config) | Data |
| Async jobs (AD-8) | `01` §5 + `docs/jobs/overview.md` | `supabase/migrations/0010_jobs` + `supabase/functions/fn-job-dispatcher` + `packages/*/src/jobs.ts` | Orion |
| 9 events (AD-9) | `01` §4.8 + `docs/events/overview.md` | `packages/domain/events.ts` (SSoT) + `supabase/.../0009_event_history` + `packages/workflows/event-flow.ts` | Foundation |
| Home invariant (AD-14) | `02` + `docs/architecture/goal-dashboard-ui.md` | `apps/mobile/src/pages/home/index.tsx` (+ `goal-card.tsx`) | App Shell |
| Agent Kernel loop (AD-12/F-09) | `docs/agent/kernel.md` §12–14 | `packages/agent/*` (15 components) + `supabase/functions/fn-agent-run` | Oracle |
| AI routing / fallback (AD-5) | `docs/ai/providers-and-routing.md` + `docs/ai/gateway.md` | `packages/agent/{router,model,providers,gateway}.ts` + `supabase/.../0011_registres` (model_registry) | Oracle |
| AD-10 viz engines | `05` §3.6 + `docs/ui-libraries.md` | `packages/ui/src/renderers/*` (engines confined to `packages/ui`) | DS team |
| Themes (AD-17) | `05` + `docs/design-system/overview.md` | `packages/ui/src/themes/*` (JSON SSoT) + `apps/mobile/src/ux/theme-adapter.tsx` | DS team |
| Dynamic Goal Engine | `docs/architecture/dynamic-goal-engine.md` | `packages/goal-engine/*` + `supabase/.../0017_user_goals` + `apps/mobile/src/pages/goals/*` | Hephaestus |
| Ascent (Slide-Ascent) | `docs/ascent/overview.md` + S-41 mockup | `packages/ascent/*` + `supabase/.../0016_ascent` + `apps/mobile/src/pages/ascent/*` | Sophia |
| Focus / DPC (v1.8) | `docs/focus-mode/*` (spec S13, OQ-17) | `packages/focus/controller.ts` (port SSoT) + `packages/platform/dpc*` + `apps/mobile/src/pages/focus/*` + `e2e/device/focus-dpc.ts` | Hypephias |
| Composite workflows | `docs/workflows/composite-workflows.md` | `packages/workflows/{w1..w23,event-flow,error-recovery,self-improvement}.ts` | Harpys |
| Feature Registry (G-M7) | `docs/frontend/feature-registry.md` S1–S8 | `apps/mobile/src/feature-registry.ts` + `packages/domain/registries.ts` | Hermes |
| Product modes + command palette | `docs/frontend/feature-registry.md` S4/S7 | `apps/mobile/src/modes/{product-modes,command-palette}.ts` | Daphne |
| Perf SLOs (30fps/TTI/JS) | `02` §9.1 + `docs/architecture/observability.md` | `apps/mobile/src/perf/{budgets,measure}.ts` + `apps/mobile/test/perf-budget.test.ts` | Erynis |
| 6 UX states (AD-13) | `02` + `docs/ui-libraries.md` | `apps/mobile/src/ux-states.tsx` + `hooks/use-killed.ts` | App Shell |
| R2 presign + key convention | `docs/cloudflare/r2.md` §1 (SSoT) | `scripts/r2-presign.ts` + `packages/scientific-engine/r2.ts` | Foundation |
| Secrets / env contract | `docs/architecture/secrets-checklist.md` + `set-secrets.ps1` | `.github/` (secrets, never in-repo) | Foundation |
| E2E device (OQ-08) | `docs/testing/matrix.md` S1 | `e2e/device/*` + `tests/e2e/*` + `apps/mobile/test/e2e-device.test.ts` | Erynis |

---

## 9. Run the gate (how to verify before you finish)

From a clean checkout, **all of these must pass** (mirror of `.github/workflows/ci.yml`, order in `docs/ci/gate.md`):

```bash
pnpm install
pnpm -r typecheck                 # tsc --noEmit across all 19 packages + 2 apps
pnpm -r lint                      # eslint boundary rules (AD-1/AD-10/AD-15), --max-warnings=0
pnpm -r test                      # vitest unit suites (last recorded: 236 pass / 0 fail)
sh scripts/check-boundaries.sh    # G1 vendor names · G2 secrets · G3 hardcoded user · G4 DOM-in-agent
sh scripts/check-rls.sh           # static RLS shape (01 §2.2/S7)
node --experimental-strip-types scripts/check-view-joins.ts   # no cross-module JOIN (03 §5.4/F-03)
node --experimental-strip-types tests/spine/spine.test.ts    # 2 equipes -> 1 contrat (AD-15)
# node-native CI gate tests:
node --experimental-strip-types --test apps/mobile/test/{e2e-device,focus-dpc,perf-budget,product-modes}.test.ts
```

`main` = above **+** build + Playwright device spec (OQ-08) at release. **1 story = 1 commit = 1 rollback**; on a failing gate: `git revert <commit>`.

## 10. Config & secrets (deploy contract)

Values live in **GitHub Actions secrets** (see `set-secrets.ps1`) — **never in the repo or device bundle.** Variable *names* (owner: Foundation, AD-16):
- **Supabase** `SUPABASE_URL`/`_PUBLISHABLE_KEY`/`_SECRET_KEY` · **PowerSync** `POWERSYNC_URL`/`PS_ADMIN_TOKEN`/`PS_DATABASE_PASSWORD` (Cloud secret; the `service_role` key has REPLICATION — standard postgres can't make logical slots) · **Cloudflare** `CF_ACCOUNT_ID`/`CF_API_TOKEN`/`CF_API_WORKERS_AI_TOKEN` · **AI** `AGNES_API_KEY_1/_2`/`AGNES_GATEWAY_TOKEN`/`GROQ_API_KEY`/`OPENROUTER_API_KEY` · **Research** `EXA_API_KEY`/`TAVILY_API_KEY`/`YOU_API_KEY` · **Integrations** `COMPOSIO_API_KEY`/`ONESIGNAL_APP_ID`/`ONESIGNAL_REST_API_KEY` · **Observability** `SENTRY_DSN`/`SENTRY_AUTH_TOKEN`/`POSTHOG_API_KEY`/`POSTHOG_HOST`/`POSTHOG_PROJECT_ID`.
- Three envs only: `dev` / `staging` / `prod`. **Free-tier note:** the live Supabase project auto-pauses after 7 days inactivity; the `0018` `keep_alive` job (pg_cron) pings it daily — keep it live (`prompts/supabase-free-tier-heartbeat.md`).

## 11. Where to look (docs index)

| You need… | Go to |
| --- | --- |
| Component → library + install | [docs/ui-libraries.md](docs/ui-libraries.md) |
| Tokens / themes / screens | [docs/design-system/overview.md](docs/design-system/overview.md) + pack `05` |
| Navigation / the page inventory | [docs/mobile/navigation-and-page-composition.md](docs/mobile/navigation-and-page-composition.md) + `context-preserving-navigation` |
| Data / sync / offline | [docs/data/local-first.md](docs/data/local-first.md) + pack `03` |
| Backend / RLS / jobs / R2 | pack `01` + [docs/backend/supabase.md](docs/backend/supabase.md) + [docs/jobs/overview.md](docs/jobs/overview.md) + [docs/cloudflare/r2.md](docs/cloudflare/r2.md) |
| AI / agent / models | [docs/ai/*](docs/ai/) + [docs/agent/kernel.md](docs/agent/kernel.md) |
| Scientific / engineering | [docs/scientific-engine/engineering-intelligence-layer.md](docs/scientific-engine/engineering-intelligence-layer.md) |
| Focus / DPC | [docs/focus-mode/*](docs/focus-mode/) |
| What's shipped / release | [docs/release/changelog.md](docs/release/changelog.md) (live) · [docs/epics-stories.md](docs/epics-stories.md) (wave 0→7 plan; banner stale, see §1) |
| Gaps / open questions / gates | [docs/architecture/gap-register.md](docs/architecture/gap-register.md) + `…/implementation-readiness-report-*.md` |
| CI gate / rollback | [docs/ci/gate.md](docs/ci/gate.md) + `.github/BRANCH-PROTECTION.md` |

> Conventions: decisions are versioned; a significant change needs a documented ADR (additive = normal, breaking = dedicated PR + review). Merge order: Foundation → Contracts → Data/Core → Features → Agent → UI refinement → QA; `main` buildable after every wave. When a doc banner and the tree disagree, the tree (changelog + code) wins — and **this file is the one you may keep current** (the authority docs stay frozen).
