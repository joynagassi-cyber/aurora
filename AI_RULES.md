# AI_RULES — Aurora

Aurora is a personal productivity + learning + agentic-orchestration suite, delivered **Phase 1 mobile-only** (Android: Ionic React + Capacitor) on a **frozen composite architecture** (ADR v1.7, spine AD-1…AD-16). This file is the **scannable reindex guide** for agents: the tech stack, *which library to use for what*, and the non-negotiables. Deep detail lives in the authoritative docs (pointers at the bottom); if this file and those docs disagree, the docs win (or it needs an ADR).

**Status:** repo is in the **design/solutioning phase** — a pnpm scaffold + architecture docs. `apps/` and `packages/` are **stubs** (workspace-only deps, `src/index.ts`); **no application code ships yet.** `AI_RULES.md` is an accepted **wave-0 gate**. Treat every capability as *designed*, not implemented.

**Authority chain (read-only):** `ADR v1.7 (adr-extract.md, frozen)` > `ARCHITECTURE-SPINE.md (AD-1…AD-16)` > `SPEC.md` > Contract Packs `01–05` > `docs/*` > this file.

---

## ⚡ Read these 8 rules first

1. **No app code exists yet.** Don't assume a working feature; build per the pack + `docs/epics-stories.md` wave you're in. `main` must stay buildable.
2. **Vendor isolation (AD-1):** domain/UI/app never import a vendor SDK or a concrete model name. External providers sit behind typed ports. Vendor SDKs live **only** in `apps/server` + adapter packages.
3. **One source of truth (AD-15):** every shared entity, envelope, port, event payload, and command type lives in `packages/domain`. **Consume it, never re-declare it.** A "view" is a declared projection (`extends Pick<Entity,…>`), not a new entity.
4. **AD-10 boundary:** the 5 visualization engines (React Flow + Dagre, AntV G2/Infographic, KaTeX, Framer Motion) are imported **only inside `packages/ui`** behind the 5 renderer contracts. Business code touching them = CI-red.
5. **No secrets on the device (AD-3):** R2 via presigned URLs only; provider/OneSignal/Composio keys are server-side; the app bundle holds zero provider keys.
6. **Local-first + single-writer (AD-7/F-03):** the UI reads SQLite/PowerSync only; mutations go through the owning module's use-case → repository. The Agent Kernel **emits commands/events**; it never writes a table directly.
7. **Home invariant (AD-14):** Home always answers *"What matters now?"* with a fixed composition (agenda · next action · main priority · critical progress · due reviews · Focus access · Coach suggestions). Never a widget dashboard.
8. **UI via the component map + tokens:** use `docs/ui-libraries.md` (never write a component a library already provides) and **100% design tokens** — no ad-hoc CSS, no excluded libs (see [What NOT to use](#what-not-to-use)).

---

## How to use this guide (where to look)

| You need… | Go to |
| --- | --- |
| Component → library + install commands | `docs/ui-libraries.md` (the single source for the UI stack) |
| Tokens, themes, screens | `docs/design-system/overview.md` + pack `05-design-system.md` |
| Navigation / the 17 pages | `docs/mobile/navigation-and-page-composition.md` + `docs/mobile/context-preserving-navigation.md` |
| Data / sync / offline | `docs/data/local-first.md` + pack `03-sync.md` |
| Backend / RLS / jobs / R2 | pack `01-backend.md` + `docs/backend/supabase.md` + `docs/jobs/overview.md` + `docs/cloudflare/r2.md` |
| AI / agent / models | `docs/ai/*` (incl. `vercel-ai-sdk-integration.md`) + `docs/agent/kernel.md` |
| Scientific / engineering compute | `docs/scientific-engine/engineering-intelligence-layer.md` |
| Focus mode / DPC | `docs/focus-mode/*` + pack `04-mobile.md` |
| What to build next / wave | `docs/epics-stories.md` (wave 0→7, IDs `W{wave}-E{epic}-{n}`) |
| Readiness / open gates | `_bmad-output/implementation-readiness-report-2026-09-22.md` + `docs/architecture/gap-register.md` |

---

## Tech Stack

- **Frontend:** Ionic React + TypeScript, mobile-first; UI from **shadcn/ui + Radix + Tailwind** driven by Aurora **design tokens** (CSS variables), never library defaults.
- **Mobile shell:** Capacitor (Android = Phase 1; `packages/platform` adapters only). **Electron = Phase 2 only** (add an adapter, never rewrite).
- **Monorepo:** pnpm + TypeScript; `apps/*` + `packages/*`; root `tsconfig.json` uses project references.
- **Local-first data:** **PowerSync + SQLite** on device; UI reads local first; offline is a first-class state (AD-7).
- **Backend:** **Supabase** — PostgreSQL (source of truth) + Auth + Edge Functions + Cron (job dispatcher) + **pgvector** (semantic retrieval).
- **Files:** **Cloudflare R2** (private buckets + presigned URLs). Documents/artifacts in R2; structure/content in PostgreSQL.
- **AI:** server-side, multi-provider behind the `AIProvider` port — **Agnes (always primary)** → Cloudflare AI Gateway → Workers AI → Groq/Cerebras/OpenRouter (optional) → CF Worker (last resort). Orchestration via the **Vercel AI SDK (`ai`)**.
- **Observation:** **Sentry** (errors + perf SLOs) + **PostHog** (analytics, EU host).
- **Testing:** **Vitest** (unit, no DOM) + **Playwright** (E2E web + Capacitor device; Appium = fallback).
- **CI/CD:** **GitHub Actions** (`main` always buildable; boundary-lint + vendor/secret grep gates).

---

## Library rules — what to use for what

> Full install commands + the complete component list + the decision tree are in **`docs/ui-libraries.md`**. This is the condensed *mapping*; every value routes through Aurora design tokens (no `#000`/`#fff`).

**UI shell & components** — **shadcn/ui + Radix + Tailwind** for all base controls (button, card, dialog, drawer, input, textarea, select/dropdown, checkbox/radio/switch, slider, tabs, accordion, tooltip, popover, command, toast, alert, badge, avatar, progress, skeleton, sidebar, breadcrumb, pagination, label, form, …). **Aceternity UI** + **Magic UI** (via shadcn registries) for premium accents (WobbleCard, InteractiveCard, Beam, Marquee, NumberTick, ShineEffect). Forms = `react-hook-form` + `zod`. Icons = `lucide-react` (no emoji/custom SVG). Fonts = self-hosted **Inter** (`@fontsource/inter`) + **JetBrains Mono** for formulas/units/data. Native chrome via Ionic `IonRouter`/`IonList`/modals; detail screens open over the tab.

**Data tables** — **AG Grid** (`ag-grid-community`/`ag-grid-react`) for >100-row virtualized data (QCM results; `rowBuffer:10`, `maxVisibleRows:30`); shadcn **`Table`** for <20 rows. Never `ion-list` for data.

**Calendar & scheduling** — **FullCalendar** (`@fullcalendar/react` + daygrid/timegrid/list/interaction) for day/week/month/agenda + time blocking; date picker = FullCalendar in a shadcn Popover. **Not** `ion-calendar`/`ion-datetime`.

**Lists & drag-and-drop** — native `IonList` (<100 items) or **`react-virtuoso`** (>100, fallback OQ-09). Kanban/reorder = **`@dnd-kit`**.

**Rich text** — **Tiptap** (`@tiptap/react` + starter-kit + math/link/table/highlight/code-block) for notes, sheets, annotations, AI-assisted editing; custom exts `SourceRefInline`, `CorpusBadge`. Yjs = Phase 2.

**Visualization (AD-10 — import only inside `packages/ui`, behind the 5 renderer contracts):**

| Use | Engine | Contract |
| --- | --- | --- |
| Semantic Tree (knowledge hierarchy) | **React Flow** + **Dagre** (`@xyflow/react`/`reactflow`, `@dagrejs/dagre`/`dagre`) | `SemanticTreeRenderer` |
| Agent explanations / infographics | **AntV Infographic** (`@antv/infographic`) | `InfographicRenderer` |
| Data / proficiency / scientific charts | **AntV G2** (`@antv/g2`) | `DataVisualizationRenderer` |
| LaTeX & math | **KaTeX** (`katex`) | `MathRenderer` |
| Micro-interactions / progressive reveal | **Framer Motion** (`framer-motion`; spine alias `motion`) | `AnimationController` |

  Engines are **never** the source of truth (AD-6); load them via `React.lazy` only when their screen opens (Home excludes them); memoize nodes + incremental Dagre (30 fps, ≤150 visible nodes); `MathRenderer` invalid LaTeX → styled raw source + `onError`. Framer Motion = GPU-only, not bouncy (150–250 ms), respects `prefers-reduced-motion`.

**State management** — **Zustand** for **UI state only** (selections, view modes, scroll anchors, theme/themeStyle, focus-mode, palette) with `persist`; **never** cache a domain entity. **`@tanstack/react-query`** for **data**, reading only the local store (query keys `[module, entity, …filter]`). No Redux/RTK.

**Local data & sync** — **PowerSync + SQLite** (repos in `packages/data`); UI reads local, mutates via the owning module's use-case. Conflicts = server-wins + per-entity `updated_at`; merge-required lists use the frozen **OR-Set CRDT** (SSoT `packages/domain`). A scope never joins another module's internal tables.

**AI (server-side only)** — call through the `AIProvider` port; orchestrate with the **Vercel AI SDK** (`ai`): `streamText`/`generateText` + `maxSteps` + typed `tools` + `onStepFinish`, `aiRouter.selectModel(taskProfile)` → a `LanguageModel`. `ai` is imported **only** in `packages/agent` (server) and via `useChat` **only** in `apps/mobile`. **Agnes always primary** (return to it after any fallback). **CopilotKit excluded.** No keys on device; a **429 is never bypassed by rotating keys**; every response is traceable via `AIResponseEnvelope`. `Agnes Image 2.5 Flash` powers infographic photos (≤2/infographic; `fal.ai` fallback). Exports (PDF/DOCX/PPTX/XLSX/images) = server `artifact_gen` job → R2 → `ArtifactGenerated` (post-upload only).

**Scientific / engineering** — `packages/scientific-engine` = generic math/units behind `ScientificEngine` (LaTeX = representation). `packages/engineering-*` = Problem IR + 6 registries (Pattern, Formula, Method, Solver, Verification, Code), 5-stage validation, deterministic execution, 4-layer RAG. **LLM orchestrates; the solver computes; the verifier validates** — surface `INSUFFICIENT_DATA`, no "100% reliable". Heavy compute = server job.

**Integrations & mobile platform** — `ResearchProvider` (You.com/Tavily/Exa), **Composio** behind `IntegrationProvider` (a tool layer, *not* an AI provider; creds server-side), **OneSignal** push + Capacitor local notifications (never both for one object). `packages/platform` exposes typed adapters (lifecycle, files, camera/scan, audio, notifications, network, `FocusController`) — the app imports **only** these, never `@capacitor/*` (whitelist in `04 §3.1`; any other plugin = Foundation PR). Optional capabilities degrade gracefully when absent.

**Testing** — Vitest (no DOM) + Playwright (web + device). Sentry enforces SLOs (≤300 Ko JS gz, ≤1.5 s TTI on Pixel 4a, 30 fps on the tree). **Every async screen implements all 6 states: `loading / empty / success / error / offline / killed`** (AD-13).

---

## What NOT to use

| Avoid | Use instead / why |
| --- | --- |
| `ion-calendar`, `ion-list` (for data), `ion-item` (for forms), `ion-datetime` | FullCalendar / AG Grid / shadcn-Radix (dated Ionic styles) |
| MUI / Ant Design / Chakra | shadcn/ui + Radix + Tailwind (conflicts with Ionic + tokens) |
| **CopilotKit** | Vercel AI SDK + Aurora's own AD-10 renderers |
| Redux / Redux Toolkit | Zustand + React Query (AD-10 already pairs React Flow with Zustand) |
| Custom SVG decorations / hardcoded colors | Real or generated images (Agnes Image); semantic tokens only |
| Bouncy animations / border radius > 8px | Framer Motion smooth (transform+opacity, reduced-motion aware); DS convention `05 §3` |

---

## Hard constraints (do not violate)

- **AD-1 vendor isolation:** no vendor SDK / model name in domain-UI-app; ports only. **AD-2 boundaries via RLS:** no cross-module joins; no writing another module's tables. **AD-7 single-writer:** kernel emits, owner applies; UI never mutates SQLite directly. **AD-8:** heavy work = persisted, idempotent, retryable, observable job (Cron + Postgres trigger → `fn-job-dispatcher`). **AD-9:** exactly 9 events, one producer + declared consumers; a simple op stays a command. **AD-15:** one SSoT per type. **AD-3:** no keys/secrets on device. **AD-14:** Home invariant. **Phase 1 mobile-only:** no Electron / microservices / Event Sourcing / Yjs / local STT. **AD-13:** Contract Pack first, one-writer-per-file, `main` buildable, merge via PR + review.

## Themes (AD-17 — `packages/ui/src/themes/` JSON SSoT)

Neutral Style (Light `#F8FAFC` / Dark `#0A0E1A`) × **10 living themes** (Aurora, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus, Cosmos) × **3 presets** (Slate, Nocturne, High Contrast) × Local Adaptation (V1 = Focus Mode). A theme **never redefines** `success/warning/danger/info` (theme-independent semantics). Resolve via `resolveToken` + `<AuroraThemeProvider>`; `value = theme_accent[token] ?? neutral[token] ?? default`. Persisted theme beats system `prefers-color-scheme` in V1.

## Config & secrets (deploy contract)

Values live in **GitHub Actions secrets** (see `set-secrets.ps1`) — **never in the repo or device bundle.** Variable *names* (owner Foundation, AD-16): Supabase `SUPABASE_URL`/`_PUBLISHABLE_KEY`/`_SECRET_KEY`; PowerSync `POWERSYNC_URL`/`PS_ADMIN_TOKEN`; Cloudflare `CF_ACCOUNT_ID`/`CF_API_TOKEN`/`CF_API_WORKERS_AI_TOKEN`; AI `AGNES_API_KEY_1/_2`/`AGNES_GATEWAY_TOKEN`/`GROQ_API_KEY`/`OPENROUTER_API_KEY`; Research `EXA_API_KEY`/`TAVILY_API_KEY`/`YOU_API_KEY`; Integrations `COMPOSIO_API_KEY`/`ONESIGNAL_APP_ID`/`ONESIGNAL_REST_API_KEY`; Observation `SENTRY_DSN`/`SENTRY_AUTH_TOKEN`/`POSTHOG_API_KEY`/`POSTHOG_HOST`/`POSTHOG_PROJECT_ID`. Three envs only: `dev` / `staging` / `prod`.

## Pointers (where the detail lives)

| Doc | Path | Owns |
| --- | --- | --- |
| **Component → library map** (start here for UI) | `docs/ui-libraries.md` | UI stack, install commands, 6 UX states, decision tree |
| Architecture spine (AD-1…AD-16) | `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` | All invariants + stack |
| ADR v1.7 (frozen) · SPEC | `…/adr-extract.md` · `…/SPEC.md` | Product/architecture decisions §1–§26 · 5 packs + wave plan + OQs |
| Contract Packs 01–05 | `…/dimensions/01-backend … 05-design-system.md` | Supabase/RLS/jobs · state/layers/routing · PowerSync/CRDT/offline · Capacitor/Focus · tokens/components/renderers/screens |
| Prescriptive docs (90+) | `docs/` (start `docs/architecture/00-overview.md`) | `ui-libraries`, `ai/*`, `scientific-engine/*`, `agent/*`, `focus-mode/*`, module pages |
| Delivery plan | `docs/epics-stories.md` | 7 epics / 38 stories, wave 0→7 |
| Readiness audit | `_bmad-output/implementation-readiness-report-2026-09-22.md` | 29 FR + 17 NFR, gaps, wave-0 gate |
| Agent prompts / workflows | `prompts/` + `.claude/workflows/` | session-1…4 wave prompts, `wave0-foundation.workflow.js` |

> Conventions: decisions are versioned; a significant change needs a documented ADR (additive = normal, breaking = dedicated PR + review). Merge order: Foundation → Contracts → Data/Core → Features → Agent → UI refinement → QA; `main` buildable after every wave.
