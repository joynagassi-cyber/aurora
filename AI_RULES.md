# AI_RULES — Aurora

Aurora is a personal productivity + learning + agentic-orchestration suite, delivered **Phase 1 mobile-only** (Android: Ionic React + Capacitor) on a **frozen composite architecture** (ADR v1.7). This file is the scannable project guide; the **authoritative, read-only** decisions live in the architecture docs (see [References](#references) at the bottom). Any conflict resolves in favor of the spine/ADR, or by a documented ADR.

Architecture paradigm: **Modular Monolith + Vertical Slices + Hexagonal (Ports & Adapters) + Local-First + targeted Event-Driven + central Agent Kernel.** No microservices, no Event Sourcing, and no Electron in V1.

## Tech Stack

- **Frontend:** Ionic React + TypeScript (mobile-first), pure-React reusable UI layer.
- **Mobile shell:** Capacitor (Android = Phase 1 target). Electron desktop is **Phase 2 only** — add an adapter, never rewrite.
- **Monorepo:** pnpm. Layout: `apps/mobile` + `packages/{domain,data,ui,platform,agent,scientific-engine,integrations}`.
- **Local-First data:** PowerSync + SQLite on device; UI reads local state first, syncs to the cloud. Offline is a first-class state, not a failure.
- **Backend:** Supabase — PostgreSQL (transactional source of truth) + Auth + Edge Functions + Cron (async job dispatcher) + **pgvector** (semantic retrieval).
- **Files:** Cloudflare R2 (private bucket + presigned URLs). Documents live in R2; structure/content lives in PostgreSQL.
- **AI:** server-side, multi-provider behind a typed `AIProvider` port — **Agnes (primary)** → Cloudflare AI Gateway → Cloudflare Workers AI (second pool) → Groq/Cerebras (optional); last-resort dedicated Cloudflare Worker. **No key or secret ever ships to the device.**
- **Observation:** Sentry (errors + perf SLOs) + PostHog (product analytics).
- **Tooling:** TypeScript, Vitest (unit, no DOM) + Playwright (E2E, web target) + Capacitor smoke (Android); CI/CD via GitHub Actions.

## Library Rules (what to use for what)

### UI & app shell
- **Ionic React** for mobile containers: `IonRouter`, tabs, headers, `IonList`, modals/sheets, native transitions. Standardize tap targets at **44px**.
- **React Router v6** for routes; Ionic handles native nav chrome. Tabs = primary nav; detail screens open **over** the current tab (IonModal/IonSlides), never by switching tabs.
- **Design System = `packages/ui` (`@aurora/ui`).** Consume components + tokens only; never write a DS component inside `apps/mobile`. A reusable business component → PR into `packages/ui`, never a local copy.
- **Colors/spacing/typography/radius = 100% design tokens** (semantic CSS custom properties, light + dark). Any hardcoded value outside a token = blocking finding. **No ad-hoc CSS.**
- **Fonts:** self-hosted variable **Inter** (body) + **JetBrains Mono** (formulas, units, data values). Embedded in the bundle (offline-first); no CDN.

### State management
- **Zustand** for **UI state only** (selections, view modes, scroll anchors, theme, focus-mode, palette open/close). ~1 Ko, aligns with React Flow. Persist cosmetic state via the `persist` middleware.
- **`@tanstack/react-query`** for **data** state, reading **only** from the PowerSync/SQLite local store (never a network fetch to render). Reads are queries; writes are use-case commands.
- **Never** use Redux/Redux Toolkit. **Never** cache a domain entity in the Zustand store as if it were its source of truth — store holds UI state + IDs, real data flows React Query → repository → PowerSync (single-writer, AD-7).

### Data & sync
- **PowerSync + SQLite** for local persistence; repositories live in `packages/data`. The UI reads local, mutates via the owning module's use-case, PowerSync propagates. **Never mutate a SQLite table directly.**
- **Supabase** is the backend of record. RLS enforces module isolation (AD-2). Long/heavy work = **persisted, idempotent, retryable, observable Job** (Supabase Cron → dispatcher → Edge Functions/Workers) — never blocks the UI.
- **Conflicts:** server-wins + per-entity `updated_at` by default; lists that must merge use a frozen **OR-Set CRDT** (SSoT in `packages/domain`). A sync scope never joins another module's internal tables.
- **Lists in UI:** native `IonList` by default; `react-virtuoso` only for lists > 100 items.

### Domain & types
- Domain rules + all shared entity types have **exactly one source of truth in `packages/domain`** (AD-15: Task, Goal, SemanticNode, Progress*, …). Other teams **consume** the type, **never re-declare it**. A "view" (e.g. `TaskRow`) is a declared projection (`extends Pick<Task, …>`), not a new entity.

### AI (server-side only)
- Call AI **through the `AIProvider` port** only. The domain, Agent Kernel, and feature code **never import a vendor SDK or a concrete model name** (AD-1).
- Pipeline: `Agent Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → Cloudflare AI Gateway → Provider Adapter → model`. Model selection is by typed task profile, not by naive prompt keywords.
- **No keys/secrets on the device** (AD-3): all AI runs server-side; the client sees only the normalized `AIProvider` contract.
- Fallback discipline (AD-5): retry on transient faults, fallback on unavailability/incompatibility/limit. A **429 is never bypassed by rotating keys/accounts**. Every fallback response is traceable (provider, model, attempt, reason, expected quality). Free tiers are capacities, not SLAs.
- The Agent Kernel (Planner/Coach/Tutor/Researcher/Executor) is **one server-side kernel**, not N deployed agents. The app consumes only its UI surface (`AgentRunState`); it never runs kernel logic or imports `AIProvider`/`AIModelRouter` on the client.

### Visualization (frozen engines behind renderer contracts — AD-10)
Business/feature code **never imports these engines directly**; they are encapsulated behind the Design System's renderer contracts. Enforced by an ESLint `import/no-restricted-paths` boundary (CI-red on violation).

| Use | Engine | Contract |
| --- | --- | --- |
| Semantic Tree (knowledge hierarchy) | `@xyflow/react` + `@dagrejs/dagre` | `SemanticTreeRenderer` |
| Agent-generated explanations/infographics | `@antv/infographic` | `InfographicRenderer` |
| Data/proficiency/scientific charts | `@antv/g2` | `DataVisualizationRenderer` |
| LaTeX & math rendering | `KaTeX` | `MathRenderer` |
| Micro-interactions & progressive reveal | `motion` | `AnimationController` |

- The **rendering engine is never the source of truth** (AD-6) — the Semantic Tree's truth lives in the Knowledge Base, React Flow only visualizes.
- **Lazy + memo:** engines load only when their screen opens (`React.lazy`), never in the Home bundle. Semantic Tree renders root + level-1 only, lazy-loads deeper branches, memoizes node components, recomputes Dagre layout incrementally.
- **Graceful degradation:** e.g. `MathRenderer` on invalid LaTeX → show styled raw source + `onError`, never crash.
- **Rich text editing:** **Tiptap** (notes, review sheets, annotations, structured blocks). Decoupled from the domain.

### Integrations & capabilities
- **Research:** `ResearchProvider` port (You.com, Tavily, Exa). **Integrations:** `Composio` behind `IntegrationProvider`. **Notifications:** OneSignal + Capacitor local (mobile); Electron native (Phase 2).
- Optional capabilities (OCR, transcription, scientific compute, artifact generation) are **swappable providers and/or async Jobs**. A missing provider must degrade gracefully — it must never break the product.

### Math / scientific
- **Scientific Engine** = generic, swappable math/units layer behind a `ScientificEngine` port; LaTeX is the representation format. Don't encode per-subject calculators.

### Testing & quality
- **Vitest** for unit/domain logic (no DOM, no Capacitor). **Playwright** for scenario E2E (web target); **Capacitor smoke** on device. **Sentry** enforces perf SLOs (≤300 Ko JS gz initial, ≤1.5 s TTI on reference device, 30 fps on the tree screen).
- Every screen implements **all 5 UX states**: `loading / empty / success / error / offline` (AD-13). Missing one = DoD not closed.

## Hard Constraints (do not violate)

- **No Electron / no desktop adapter in V1** (Phase 1 is mobile-only; keep the core platform-agnostic).
- **No microservices, no Event Sourcing** in V1 — modular boundaries in code only; extraction only on measurable need.
- **No vendor SDK or concrete model name in domain/application** (hexagonal AD-1).
- **No keys or secrets on the device** (AD-3).
- **No direct engine import** of `@xyflow/react`, `@antv/*`, `KaTeX`, or `motion` in business code (AD-10 boundary).
- **No re-declaration** of a shared domain type (AD-15 SSoT).
- **No direct SQLite mutation** by the UI / no multi-table write from one use-case (AD-7 single-writer).
- **No ad-hoc CSS** — tokens only (Design System rule).
- **Home screen invariant (AD-14):** fixed composition answering *"What matters now?"* — today's agenda, next important action, main priority, critical progress, due reviews, immediate Focus access, Coach suggestions. It must never become a widget dashboard.
- **Events are targeted (AD-9):** 9 named events, each with one producer + declared consumers; a simple transactional op stays a direct command.
- **Parallel work (AD-13):** Contract Pack first, one-writer-per-file, `main` always buildable, merge via PR + review.

## References (authoritative, read-only)

The deep, normative detail is **not** duplicated here — read the source docs:

| Doc | Path | Owns |
| --- | --- | --- |
| Architecture Spine (AD-1…AD-16, final) | `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` | All invariants + stack + structural seed |
| ADR v1.7 (frozen) | `_bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md` | Product/architecture decisions §1–§26 |
| SPEC (prescriptive contract) | `_bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md` | The 5 dimension packs + wave plan + open questions |
| Pack 01 — Backend | `…/dimensions/01-backend.md` | Supabase/RLS/R2/jobs/AI server contracts |
| Pack 02 — Frontend | `…/dimensions/02-frontend.md` | State (Zustand), layers, AD-10 consumption, routing, UX states, perf |
| Pack 03 — Sync | `…/dimensions/03-sync.md` | PowerSync/SQLite, single-writer, conflict + CRDT, offline |
| Pack 04 — Mobile | `…/dimensions/04-mobile.md` | Capacitor adapters, focus controller, battery/lifecycle |
| Pack 05 — Design System | `…/dimensions/05-design-system.md` | Tokens, components, AD-10 renderer impls, screen inventory |

> Conventions from the spine: decisions are versioned; a significant change requires a documented ADR (additive = normal, breaking = dedicated PR + mandatory review). Merge order: Foundation → Contracts → Data/Core → Features → Agent → UI refinement → QA.
