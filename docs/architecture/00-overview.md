# Aurora — Technical Documentation: Architecture Overview

> **Status note (2026-09-22):** Aurora is in the **design/solutioning phase**. No application
> code exists yet (repo = pnpm workspace stub + BMAD architecture docs). Every statement in this
> documentation tree is therefore **DOCUMENTED_ONLY** (decided and written in the authority docs)
> or **DESIGNED_NOT_IMPLEMENTED** (designed, implementation scheduled in a wave). No capability is
> described as "implemented" or "supported on device" without a mechanism + permission +
> component + behavior + limits + tests. Authority chain: `ADR v1.7 (frozen)` >
> `ARCHITECTURE-SPINE.md (AD-1..AD-16, frozen)` > `SPEC.md` > Contract Packs
> (`01-backend`, `02-frontend`, `03-sync`, `04-mobile`, `05-design-system`). Conflicts are
> flagged in [gap-register.md](./gap-register.md), never resolved silently.

## 1. What Aurora is

A personal productivity + learning + agentic-orchestration suite. Features are **capabilities of
Aurora**; the user's intent and context determine which capabilities the Agent Kernel activates
(ADR §1, §4, §5). Phase 1 is **mobile-only (Android, Ionic React + Capacitor)**; desktop
(Electron) is Phase 2, entered only after mobile is production-stable (ADR §23).

## 2. Architecture paradigm (frozen, spine)

Composite architecture, frozen in ADR v1.6/v1.7 and distilled in the spine:

- **Modular Monolith** — one deployable unit; 10 business modules: Identity, Productivity,
  Learning, Knowledge, Discovery, Progress, Agent, Scientific, Artifact, Integrations.
- **Vertical Slices** — each capability owns its code scope, tests, and contracts (AD-13).
- **Clean / Hexagonal (Ports & Adapters)** — domain and application never reference vendors or
  frameworks; every external provider sits behind a typed port (AD-1).
- **Local-First** — PowerSync + SQLite on device; UI reads local first; offline is a first-class
  state (AD-7).
- **Targeted Event-Driven** — exactly 9 named events, each with one producer and declared
  consumers; simple transactional ops stay direct commands (AD-9). Event Sourcing is **excluded**
  from V1; CQRS is applied only where a concrete need justifies it (ADR §26.4/§26.6).
- **Serverless targeted + Persisted Jobs** — Supabase Cron → dispatcher → persisted, idempotent,
  retryable, observable jobs; no heavy work blocks the UI (AD-8).
- **Central Agent Kernel** — one server-side kernel loop
  `Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory`;
  Planner/Coach/Tutor/Researcher/Executor are kernel *capabilities*, not deployed agents (AD-12).

Explicit V1 exclusions (do not document as capabilities): microservices, full Event Sourcing,
Electron, Yjs collaborative editing, local STT engine (ADR §26; spine § Deferred).

## 3. Module → package map (wave-0 seed, OQ-01 pending ratification)

| Package | Role | Owner team |
|---|---|---|
| `packages/domain` | SSoT of all frozen entity types (AD-15), domain commands, event payloads, port interfaces, `AppError`/`ApiEnvelope`/`AIResponseEnvelope` | Per-entity module owner (mapping frozen in `03-sync` §4.2; team column = OQ-02, reduced) |
| `packages/data` | PowerSync/SQLite repositories, migrations, PowerSync views/scopes, Model Registry, React-Query bridge | Data team |
| `packages/ui` | Design System, tokens, components, AD-10 renderer implementations, themes JSON SSoT | Design System team |
| `packages/platform` | Capacitor adapters behind interfaces (lifecycle, files, camera, audio, notifications, network) | Foundation (exclusive owner, AD-16c) |
| `packages/agent` | Agent kernel UI surface (`AgentRunState`); execution is server-side (F-09) | Agent team |
| `packages/scientific-engine` | Generic math/units engine behind `ScientificEngine` port | Scientific team |
| `packages/integrations` | Composio (`IntegrationProvider`), notification adapters | Integrations team |
| `apps/mobile` | Ionic React app shell + vertical feature slices (presentation / ui-state / use-cases / data-access / platform layers) | App Shell team + feature agents |

Dependency rule: `domain` imports nothing; vendor SDKs only in adapter packages and
server workers; `ui` never imports `data`/`platform`; feature slices never import sibling
slices (SPEC wave-0 "Gate de boundaries", pack 02 §11 `import/no-restricted-paths` gate).

## 4. Data architecture

- **PostgreSQL (Supabase)** = transactional source of truth; **pgvector** = semantic retrieval;
  **Event History** = progression/audit (not Event Sourcing) (AD-6, ADR §26.7).
- **Cloudflare R2** = files (private buckets, presigned URLs; presignGet TTL 15 min /
  presignUpload TTL 5 min, `01-backend` §5.4); structure/content stays in PostgreSQL.
- **Device store** = SQLite mirror of AD-15 entities; single-writer per entity (AD-7/F-03);
  conflict rule server-wins + per-entity `updated_at`; merge-required lists use the frozen
  OR-Set CRDT (SSoT `packages/domain`).

## 5. AI architecture (server-side only)

`Agent Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → Cloudflare AI
Gateway → Provider Adapter → model`, with a dedicated Cloudflare fallback Worker as last resort.
No key or secret ever ships to the device (AD-3). Model selection is by **typed task profile**,
never naive prompt keywords (ADR v1.7 §6). See [ai/providers-and-routing.md](../ai/providers-and-routing.md).

## 6. Wave plan (SPEC)

wave 0 contracts/types/tokens/CI + OQ-01/OQ-02/OQ-03 → wave 1 foundations (UI, Data, Auth, RLS,
R2) → wave 2 features → wave 3 agent kernel (server) → wave 4 integration → wave 5 UI
refinement → wave 6 Codex deep review → wave 7 release candidate (E2E Android). `main`
buildable after every wave.

## 7. Documentation map

| Topic | Page |
|---|---|
| ADR compliance summary | [adr-compliance-report.md](./adr-compliance-report.md) |
| Decision coverage matrix | [coverage-matrix.md](./coverage-matrix.md) |
| Gap & risk register | [gap-register.md](./gap-register.md) |
| All TS contracts / ports | [contract-catalog.md](./contract-catalog.md) |
| Tables, events, jobs, R2 | [data-event-job-catalog.md](./data-event-job-catalog.md) |
| Permissions (device/server/roles) | [permission-matrix.md](./permission-matrix.md) |
| Agent kernel | [../agent/kernel.md](../agent/kernel.md) |
| AI providers & routing | [../ai/providers-and-routing.md](../ai/providers-and-routing.md) |
| Local-first / sync | [../data/local-first.md](../data/local-first.md) |
| Focus Mode (deep spec) | [../focus-mode/spec.md](../focus-mode/spec.md) |
| Design system & themes | [../design-system/overview.md](../design-system/overview.md) |
| Security | [../security/overview.md](../security/overview.md) |
| Jobs | [../jobs/overview.md](../jobs/overview.md) |
| Events | [../events/overview.md](../events/overview.md) |
| Module pages (productivity, learning, knowledge, discovery, progress, artifacts, scientific-engine, integrations, identity) | [../modules/index.md](../modules/index.md) |
| Mobile platform | [../mobile/overview.md](../mobile/overview.md) |
| Testing | [../testing/matrix.md](../testing/matrix.md) |
| Deployment & environments | [../deployment/overview.md](../deployment/overview.md) |
| Troubleshooting & recovery | [../troubleshooting/overview.md](../troubleshooting/overview.md) |
