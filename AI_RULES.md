# AI_RULES — Aurora

Aurora is a personal productivity + learning + agentic-orchestration suite, delivered **Phase 1 mobile-only** (Android: Ionic React + Capacitor) on a **frozen composite architecture** (ADR v1.7, spine AD-1…AD-16). This file is the scannable **reindex guide** for coding agents: it captures the real tech stack and the rules for *which library to use for what*, grounded in the authoritative docs. If this file and the authority docs disagree, the authority docs win (or it needs an ADR).

**Authority chain (read-only):** `ADR v1.7 (adr-extract.md, frozen)` > `ARCHITECTURE-SPINE.md (AD-1…AD-16)` > `SPEC.md` > Contract Packs `01–05` > `docs/*` (prescriptive detail) > this file.

**Current status:** the repo is in the **design/solutioning phase** — a pnpm workspace scaffold + architecture docs. The `apps/` and `packages/` are stubs (`src/index.ts`, workspace-only deps); **no application code ships yet.** `AI_RULES.md` is an accepted gate for wave 0. Treat every capability as `DOCUMENTED_ONLY` or `DESIGNED_NOT_IMPLEMENTED`, not "implemented."

## Repo layout (the real tree)

- `apps/mobile` — `@aurora/mobile`: Ionic React + Capacitor app shell + vertical feature slices.
- `apps/server` — `@aurora/server`: Supabase Edge Functions + Cloudflare Workers (server-side AI, jobs, gateway). **Vendor SDKs are only allowed here / in adapter packages (AD-1).**
- `packages/domain` — **SSoT of every frozen entity type + envelopes + events + commands + ports** (AD-15). Imports nothing; no vendor.
- `packages/data` — PowerSync/SQLite repositories, migrations, PowerSync views/scopes, Model Registry, React-Query bridge.
- `packages/ui` — Design System: tokens, shadcn components, AD-10 renderer impls, **themes JSON SSoT** (AD-17).
- `packages/platform` — Capacitor adapters **behind interfaces**; the only native surface the app consumes.
- `packages/agent` — Agent Kernel UI surface (`AgentRunState`); execution is server-side (F-09). **Only place the Vercel AI SDK `ai` is imported.**
- `packages/scientific-engine` — generic math/units behind the `ScientificEngine` port.
- `packages/engineering-core|solvers|adapters|registry` — the Engineering Intelligence Layer (Problem IR + 6 registries + deterministic solvers).
- `packages/integrations` — Composio (`IntegrationProvider`), notification adapters.
- `docs/` — ~90 prescriptive pages (start with `docs/architecture/00-overview.md` and `docs/ui-libraries.md`).
- `prompts/` + `.claude/workflows/` — agent orchestration (wave-0…4 session prompts, `wave0-foundation.workflow.js`).
- `set-secrets.ps1` — pushes the config/env contract to GitHub Actions secrets (see [Config & secrets](#config--secrets-deploy-contract)).

## Tech Stack

- **Frontend:** Ionic React + TypeScript, mobile-first; UI built from **shadcn/ui + Radix + Tailwind** consumed through the Aurora **design tokens** (CSS variables), never the library defaults.
- **Mobile shell:** Capacitor (Android = Phase 1 target, `packages/platform` adapters only). **Electron = Phase 2 only** (add an adapter, never rewrite).
- **Monorepo:** pnpm + TypeScript; layout `apps/*` + `packages/*` (see [Repo layout](#repo-layout-the-real-tree)); root `tsconfig.json` uses project references.
- **Local-first data:** **PowerSync + SQLite** on device; UI reads local first; offline is a first-class state (AD-7).
- **Backend:** **Supabase** — PostgreSQL (source of truth) + Auth + Edge Functions + Cron (job dispatcher) + **pgvector** (semantic retrieval).
- **Files:** **Cloudflare R2** (private buckets + presigned URLs); documents/artifacts live in R2, structure/content in PostgreSQL.
- **AI:** server-side, multi-provider behind the `AIProvider` port — **Agnes (always primary)** → Cloudflare AI Gateway → Workers AI (second pool) → Groq/Cerebras/OpenRouter optional → CF Worker last-resort. Orchestration via the **Vercel AI SDK (`ai`)**. **No key/secret ever ships to the device.**
- **Observation:** **Sentry** (errors + perf SLOs) + **PostHog** (product analytics, EU host).
- **Testing:** **Vitest** (unit, no DOM) + **Playwright** (E2E web + Capacitor device driver; Appium = fallback).
- **CI/CD:** **GitHub Actions** (`main` always buildable; boundary-lint + vendor/secret grep gates).

## Library Rules — what to use for what

> Authoritative component map: **`docs/ui-libraries.md`** (prescriptive; install commands + "never write a component from scratch if a library covers it"). Every value below routes through **Aurora design tokens (CSS variables)** — no `#000`/`#fff`, no ad-hoc CSS.

### UI shell & components
- **shadcn/ui + Radix + Tailwind** for buttons, cards, dialog, drawer, input, textarea, select/dropdown, checkbox/radio/switch, slider, tabs, accordion, tooltip, popover, command palette, toast, alert, badge, avatar, progress, skeleton, sidebar, breadcrumb, pagination, scroll-area, separator, label, menubar, context-menu, hover-card, kbd, form.
- **Premium accents** via shadcn registries: **Aceternity UI** (WobbleCard, InteractiveCard, Beam) + **Magic UI** (Marquee, NumberTick, ShineEffect, etc.). Use for GoalProject cards, Focus visuals, micro-interactions.
- **Forms:** `react-hook-form` + `@hookform/resolvers` + `zod`.
- **Icons:** **`lucide-react`** (16px in nodes, 20px in header). Never emoji, never custom SVG decorations.
- **Typography:** self-hosted **Inter** via `@fontsource/inter` + **JetBrains Mono** for formulas/units/data values. Embedded, offline-first, no CDN.
- **Mobile shell (Ionic):** `IonRouter`/tabs/headers/lists/modals where native chrome is wanted; detail screens open **over** the current tab (IonModal/IonSlides). Command Palette = Radix Command overlay, not a route.

### Data tables & grids
- **Heavy/virtualized tables (100+ rows, e.g. QCM results):** **AG Grid** (`ag-grid-community` + `ag-grid-react`), `rowBuffer:10`, `maxVisibleRows:30`.
- **Light tables (<20 rows):** shadcn `Table`. **Not** AG Grid, **not** `ion-list` for data.

### Calendar & scheduling
- **FullCalendar** (`@fullcalendar/react` + daygrid/timegrid/list/interaction) for day/week/month/agenda + time blocking. **Not** `ion-calendar`/`ion-datetime`; date picker = FullCalendar in a shadcn Popover.

### Lists & drag-and-drop
- **Lists:** native `IonList` for <100 items; **`react-virtuoso`** for >100 (fallback, OQ-09).
- **Kanban/reorder:** **`@dnd-kit`** (`@dnd-kit/core` + `@dnd-kit/sortable`).

### Rich text & documents
- **Tiptap** (`@tiptap/react` + starter-kit + math/link/table/highlight/code-block) for notes, review sheets, annotations, AI-assisted editing. Custom extensions: `SourceRefInline` (provenance, AD-11), `CorpusBadge` (teacher vs. Aurora text, ADR §17). Yjs collaboration = Phase 2, not V1.

### Visualization (frozen AD-10 engines — import ONLY inside `packages/ui`, behind the 5 renderer contracts)
Business/feature code **never** imports these directly (ESLint `import/no-restricted-paths` + grep CI). Concrete packages per `docs/ui-libraries.md`:

| Use | Engine (package) | Contract |
| --- | --- | --- |
| Semantic Tree (knowledge hierarchy) | **React Flow** (`@xyflow/react`/`reactflow`) + **Dagre** (`@dagrejs/dagre`/`dagre`) | `SemanticTreeRenderer` |
| Agent explanations / infographics | **AntV Infographic** (`@antv/infographic`, hybrid SVG + `<image>`/real+generated photos via Agnes Image) | `InfographicRenderer` |
| Data / proficiency / scientific charts | **AntV G2** (`@antv/g2`) | `DataVisualizationRenderer` |
| LaTeX & math | **KaTeX** (`katex`) | `MathRenderer` |
| Micro-interactions / progressive reveal | **Framer Motion** (`framer-motion`; spine alias `motion`) | `AnimationController` |

- The **engine is never the source of truth** (AD-6): the tree's truth is in the Knowledge Base; React Flow only renders.
- **Lazy + memo:** engines load via `React.lazy` only when their screen opens; the Home bundle excludes them. Semantic Tree renders root + level-1, lazy-loads deeper, memoizes nodes, recomputes Dagre incrementally (30 fps, ≤150 visible nodes).
- **Graceful degradation:** `MathRenderer` on invalid LaTeX → styled raw source + `onError`, never crash.
- **Animations:** Framer Motion is GPU-only (transform+opacity), **not bouncy** (150–250 ms), and respects `prefers-reduced-motion`.

### State management
- **Zustand** for **UI state only** (selections, view modes, scroll anchors, theme/themeStyle, focus-mode, palette open/close). Persist cosmetic state via the `persist` middleware. **Never** cache a domain entity here (AD-7/F-03).
- **`@tanstack/react-query`** for **data** state, reading **only** the PowerSync/SQLite local store (query keys `[module, entity, …filter]`, owner `packages/data` bridge §5.8). No Redux/Redux Toolkit.
- **Important state lives in the local store**, not Zustand/`localStorage` (kill-tolerance, AD-7).

### Local-first data & sync
- **PowerSync + SQLite** for device persistence; repositories in `packages/data`. UI reads local, mutates via the owning module's use-case, PowerSync propagates. **Never mutate a SQLite table directly** (single-writer, AD-7/F-03).
- Conflicts: **server-wins + per-entity `updated_at`** by default; merge-required lists use the frozen **OR-Set CRDT** (SSoT `packages/domain`). A sync scope never joins another module's internal tables.
- Chat history is persisted locally (`chat_messages`) and upsynced (Vercel doc).

### AI (server-side only)
- Call AI **through the `AIProvider` port**; orchestrate with the **Vercel AI SDK (`ai`)**: `streamText`/`generateText` + `maxSteps` + typed `tools` + `onStepFinish`, and `aiRouter.selectModel(taskProfile)` → a `LanguageModel` (any OpenAI-compatible endpoint). **Never** a naive prompt-keyword branch.
- **`ai` is imported only in `packages/agent`** (server) and via `useChat` **only in `apps/mobile`**; `packages/domain`, `packages/ui` and feature code never import it (grep CI, AD-1). **No vendor SDK or concrete model name in the domain.**
- Pipeline: `Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → CF AI Gateway → Provider Adapter → model`. **Agnes is ALWAYS primary** (fallback only on error, then return to Agnes). **CopilotKit is excluded.**
- **No keys/secrets on the device** (AD-3). Fallback discipline (AD-5): retry on transient faults; a **429 is never bypassed by rotating keys/accounts**; every response is traceable via `AIResponseEnvelope` (provider, model, attempt, reason, expectedQuality). Free tiers are capacities, not SLAs; the Model Registry can auto-retire a provider.
- **`Agnes Image 2.5 Flash`** powers generated/real photos inside infographics ("Agent as Art Director"; ≤2 images per infographic; `fal.ai` fallback).
- **Export formats (Artifact Hub jobs):** PDF = puppeteer/wkhtmltopdf; DOCX = docx/pandoc; PPTX = `pptxgenjs`; XLSX/CSV = SheetJS/`xlsx`; images = canvas/`html2canvas`; LaTeX = KaTeX. All exports = server `artifact_gen` job → R2 upload → `ArtifactGenerated` (post-upload only).

### Scientific / engineering compute
- **`packages/scientific-engine`** = generic math/units behind `ScientificEngine` (LaTeX = representation). **`packages/engineering-*`** implement the Engineering Intelligence Layer: a universal **Problem IR** (quantity+unit guardrails), 6 registries (Pattern, Formula, Method, Solver, Verification, Code), 5-stage validation, deterministic execution, 4-layer RAG. The **LLM interprets/orchestrates; the solver computes; the verifier validates.** No "100% reliable" claims — surface `INSUFFICIENT_DATA` / low confidence.
- Never encode per-subject calculators; run heavy compute as a **server job** (AD-8).

### Integrations & optional capabilities
- **Research:** `ResearchProvider` (You.com, Tavily, **Exa**). **Integrations:** **Composio** behind `IntegrationProvider` (tool/integration layer, **not** an AI provider; credentials server-side only). **Notifications:** **OneSignal** (server push) + Capacitor **local** notifications (deadlines/Focus) — never both for the same object.
- Optional capabilities (OCR, transcription, artifact gen, search, scientific compute) are **swappable providers and/or async jobs** and must degrade gracefully when absent.

### Mobile platform (Capacitor)
- **`packages/platform`** exposes typed adapters (`AppLifecycleAdapter`, `LocalFileStorageAdapter`, `DocumentScanner`/`OCRProvider`, `AudioArtifactProvider`/`TranscriptionProvider` (optional), `RemoteNotificationAdapter` (OneSignal), `LocalNotificationAdapter`, `NetworkStatusAdapter`, `FocusController`). The app imports **only** these interfaces, **never `@capacitor/*`** (CI lint boundary).
- **Plugin whitelist (04 §3.1):** `@capacitor/app`, `status-bar`, `keyboard`, `filesystem`, `http`, `camera`, `media`/`audio`, `push-notifications`, `network`, `splash-screen`, `@onesignal/react`. Any other plugin = Foundation PR.
- **Focus v1.8 DPC (candidate, OQ-17):** private single-device, Device-Owner provisioning (`adb shell dpm set-device-owner`), `DevicePolicyManager.setPackagesSuspended` (API 29+); consumer-app fallback = restriction-only (in-app timer + DND guidance + optional Screen Pinning). **Never promise native "app blocking"** on a consumer device.

### Testing & quality
- **Vitest** (unit/domain, no DOM). **Playwright** for scenario E2E (web target + Capacitor device driver; Appium fallback). **Sentry** enforces perf SLOs: ≤300 Ko JS gz, ≤1.5 s TTI (Pixel 4a reference), 30 fps on the tree screen.
- Every async screen/component implements **6 UX states**: `loading / empty / success / error / offline / killed` (AD-13; "killed" = G-M2, sub-state of loading). Missing one = DoD not closed.

## What NOT to use (explicitly excluded)

| Avoid | Use instead / why |
| --- | --- |
| `ion-calendar`, `ion-list` (for data), `ion-item` (for forms), `ion-datetime` | FullCalendar / AG Grid / shadcn-Radix / FullCalendar+Popover (dated Ionic styles) |
| MUI / Ant Design / Chakra | shadcn/ui + Radix + Tailwind (web-first, conflicts with Ionic + tokens) |
| **CopilotKit** | Vercel AI SDK + Aurora's own AD-10 renderers (copilot UI layer conflicts with the frozen 5-engine + 5-state model) |
| Redux / Redux Toolkit | Zustand + React Query (AD-10 already pairs React Flow with Zustand) |
| Custom SVG decorations / hardcoded colors | Real or generated images (Agnes Image); semantic design tokens only |
| Bouncy animations | Framer Motion smooth (transform+opacity, reduced-motion aware) |
| Border radius > 8px | DS convention (05 §3) |

## Hard Constraints (do not violate)

- **Vendor isolation (AD-1):** domain/UI/app never import a vendor SDK or a concrete model; providers sit behind typed ports. Vendor SDKs only in `apps/server` + adapter packages.
- **No keys or secrets on the device (AD-3):** R2 via presigned URLs; OneSignal app-key in `capacitor.config.ts` only; R2/OneSignal/provider keys server-side.
- **Module boundaries (AD-2) via RLS:** RLS is the data-level enforcement of AD-2; no cross-module table joins; no writing another module's tables.
- **Single-writer (AD-7/F-03):** the Agent Kernel never mutates a table directly — it emits a command/event; the owning module applies it.
- **Async jobs (AD-8):** everything heavy = a persisted, idempotent, retryable, observable job (Supabase Cron + Postgres trigger → `fn-job-dispatcher` → workers). Never block the UI.
- **Targeted events (AD-9):** exactly 9 named events, one producer + declared consumers; simple transactional ops stay direct commands.
- **AD-10 boundary:** the 5 visualization engines importable **only** inside `packages/ui`; elsewhere CI-red.
- **No re-declaration of shared domain types (AD-15):** one SSoT in `packages/domain`; a "view" is a declared projection (`extends Pick<Entity,…>`), not a new entity.
- **No ad-hoc CSS:** 100% design tokens (light + dark + themes).
- **Home invariant (AD-14):** fixed composition answering *"What matters now?"* — agenda, next action, main priority, critical progress, due reviews, immediate Focus, Coach suggestions. Never a widget dashboard.
- **Phase 1 mobile-only:** no Electron / desktop adapter, no microservices, no Event Sourcing, no Yjs, no local STT engine in V1.
- **Parallel work (AD-13):** Contract Pack first, one-writer-per-file, `main` buildable, merge via PR + review.

## Themes (AD-17, candidate — `packages/ui/src/themes/` JSON SSoT)

- **3 resolution layers:** Neutral Style (Light `#F8FAFC` / Dark `#0A0E1A` blue-tinted near-black) × **10 living themes** (Aurora, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus, Cosmos) × **3 presets** (Slate, Nocturne, High Contrast) × Local Adaptation (V1 = Focus Mode only).
- **Rule 1:** a theme **never redefines** `success/warning/danger/info` — semantic states are theme-independent (neutral layer). `value = theme_accent[token] ?? style_neutre[token] ?? default` via `resolveToken` + `<AuroraThemeProvider>`.
- Theme choice persists via the UI store; **never a silent theme change on foreground return** (persisted theme beats system `prefers-color-scheme` in V1).

## Config & secrets (deploy contract)

Env/config is a **GitHub Actions secrets** contract (see `set-secrets.ps1`; **values never in the repo or device bundle**). Variable names (owner: Foundation, AD-16):
- **Supabase:** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`.
- **PowerSync:** `POWERSYNC_URL`, `PS_ADMIN_TOKEN`.
- **Cloudflare:** `CF_ACCOUNT_ID`, `CF_API_TOKEN`, `CF_API_WORKERS_AI_TOKEN`.
- **AI providers:** `AGNES_API_KEY_1/_2`, `AGNES_GATEWAY_TOKEN`, `GROQ_API_KEY`, `OPENROUTER_API_KEY`.
- **Research:** `EXA_API_KEY`, `TAVILY_API_KEY`, `YOU_API_KEY`.
- **Integrations/notifications:** `COMPOSIO_API_KEY`, `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`.
- **Observability:** `SENTRY_DSN`, `SENTRY_AUTH_TOKEN`, `POSTHOG_API_KEY`, `POSTHOG_HOST`, `POSTHOG_PROJECT_ID`.

Three environments only — `dev` / `staging` / `prod` (structure frozen by AD-16; values are wave-0 data).

## References (authoritative, read-only)

| Doc | Path | Owns |
| --- | --- | --- |
| Component → library map (**start here for UI**) | `docs/ui-libraries.md` | shadcn/Radix/Tailwind, AG Grid, FullCalendar, Tiptap, framer-motion, dnd-kit, AD-10 engines, 6 UX states, decision tree |
| Architecture spine (AD-1…AD-16, final) | `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` | All invariants + stack + structural seed |
| ADR v1.7 (frozen) | `…/adr-extract.md` | Product/architecture decisions §1–§26 |
| SPEC + open questions | `…/SPEC.md` | 5 dimension packs + wave plan + OQs |
| Packs 01–05 | `…/dimensions/01-backend … 05-design-system.md` | Supabase/RLS/jobs/AI · state/layers/routing/UX · PowerSync/CRDT/offline · Capacitor/Focus · tokens/components/renderers/screens |
| Prescriptive docs (90+) | `docs/` (start `docs/architecture/00-overview.md`) | `docs/ui-libraries.md`, `docs/ai/vercel-ai-sdk-integration.md`, `docs/ai/providers/*`, `docs/scientific-engine/engineering-intelligence-layer.md`, `docs/architecture/dynamic-goal-engine.md`, `docs/knowledge/discovery-gap-pipeline.md`, `docs/focus-mode/*`, module pages |
| Delivery plan | `docs/epics-stories.md` | 7 epics / 38 stories, wave 0→7 (story IDs `W{wave}-E{epic}-{n}`) |
| Readiness audit | `_bmad-output/implementation-readiness-report-2026-09-22.md` | 29 FR + 17 NFR, gaps, wave-0 gate (this file must be "accepted") |
| Agent prompts / workflows | `prompts/` + `.claude/workflows/` | session-1…4 wave prompts, `wave0-foundation.workflow.js` |

> Conventions: decisions are versioned; a significant change needs a documented ADR (additive = normal, breaking = dedicated PR + review). Merge order: Foundation → Contracts → Data/Core → Features → Agent → UI refinement → QA; `main` buildable after every wave.
