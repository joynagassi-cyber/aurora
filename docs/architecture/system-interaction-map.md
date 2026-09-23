# System Interaction Map — Aurora as one unified system

Status note: design phase (no code yet). This page is the navigation hub that proves
the ADR → architecture → modules → contracts → backend → frontend → agent →
integrations → data → workflows chain is coherent; every link points to the
prescriptive source (spine / packs), not a restatement.

## 1. The vertical chain (how one user request moves through the system)

```
User (natural language or UI action)
  ↓
FRONTEND — apps/mobile vertical slice (6 layers, 02 §4:
  presentation → ui-state (Zustand: UI state + IDs only, AD-7) →
  use-cases (orchestration, emits partial DomainCommands) → domain (consumed
  from packages/domain, AD-15) → data-access (injected repositories) →
  platform (injected Capacitor adapters))
  ↓  (writes) LocalCommandRepository.apply(owner, cmd)   (reads) LocalQueryRepository (SQLite only)
  ↓
APPLICATION / API — local-first: mutations queue for upsync; heavy/async = server
  ↓
AGENT KERNEL (server, F-09) when the intent is agent-shaped (docs/agent/kernel.md)
   — or direct feature path (no agent) for simple transactional operations
  ↓  kernel: Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory
  ↓
DOMAIN — packages/domain SSoT (AD-15): entities, commands, event payloads, ports
  ↓
PORTS — typed contracts only (AD-1): AIProvider, ResearchProvider, IntegrationProvider,
  ObjectStorage, ScientificEngine, NotificationProvider, FocusController(+Dpc v1.8),
  KnowledgeBase, JobRunner, OCRProvider/TranscriptionProvider (optional), AI pipeline
  contracts (ADR v1.7 §9)
  ↓
ADAPTERS — packages/data (PowerSync/SQLite, RLS views, Model Registry),
  packages/platform (Capacitor whitelist + v1.8 DPC native module),
  packages/integrations (Composio/OneSignal), packages/scientific-engine (swappable
  backends); server: Supabase Edge Functions + Cloudflare Workers + AI Gateway
  ↓
DATA / JOBS / EVENTS / PROVIDERS — Postgres+pgvector (source of truth, RLS), R2
  (files only), 9 frozen events (AD-9, 01 §3.3), job_queue + dispatcher (AD-8, 01
  §5.2), providers behind the gateway (docs/ai/*)
```

Key invariants on the chain: single-writer per entity (AD-7/F-03 — the kernel and the
UI never write tables they don't own) · no vendor name below the ports (AD-1) · no
keys on the device (AD-3) · heavy = persisted idempotent jobs (AD-8) · events = the
9 and only the 9 (AD-9) · UI render path is network-free (AD-7, 02 §9).

## 2. Module interaction map (who talks to whom, and through what)

```
                    Identity (user_context, auth)
                        │ RLS root + theme v2 value (01 §2.1)
   Productivity ────────┼─────────────────────────────────
     │ GoalUpdated,TaskCompleted │
     ▼                        ▼
   Progress ◄──ProgressEvidenceCreated── Learning
     │ SkillStateChanged            ▲ CourseImported, FlashcardReviewed
     │                              │
     ▼                              │
   Knowledge ◄─DiscoveryItemCreated─ Discovery
     │ (NodeState writer, AD-6)     │ ResearchProvider (You.com/Tavily/Exa)
     ▼                              ▼
   Semantic Tree (renderer = view only, AD-10) ── Agent Kernel
                                               (Capabilities: Planner/Coach/Tutor/
                                                Researcher/Executor — AD-12)
     Agent ──ArtifactGenerated──► Artifact ◄──R2/ObjectStorage── Integrations
     Agent ──jobs (fn-agent-run, verify, scientific, mirror-analysis)── Job system
```

Interaction channels (exactly three, per AD-2/AD-7/AD-9 — no others):

| Channel | Use | Rule |
|---|---|---|
| **Events (AD-9, 01 §3.3)** | cross-module reactions, decoupled | 9 frozen; one producer; declared consumers; transport = `events` table + Postgres trigger → job / incremental read (no broker V1) |
| **Public views / public contract types (AD-2, 03 §5.4)** | cross-module *reads* | read another module's public view only; never internal tables; no cross-module joins |
| **Commands to the owning module (AD-7)** | cross-module *writes* | the only write path to another module's data = a command applied by the owner (or the owner's own direct write); kernel/UI emit, owner applies |

## 3. Sync vs async — where each operation lands

| Operation class | Sync/async | Mechanism |
|---|---|---|
| Local reads (any screen) | sync (instant) | `LocalQueryRepository` / SQLite (AD-7) |
| Simple transactional writes (rename a task, rate a card) | local sync write + upsync queue | `LocalCommandRepository` partial command (03 §3.1) |
| Heavy generation (sheets, QCM, OCR, transcription, artifact render, research, mirror-analysis) | async | persisted job (AD-8, 01 §5) → `JobCompleted` |
| Agent runs / verify | async (critical verify = job) | `fn-agent-run` + jobs (01 §5.6) |
| Cross-module state reactions | async | AD-9 events → consumer jobs (01 §3.3) |
| Aggregates / recompute (skill_states, trends, FSRS ticks) | async | Postgres triggers → `job_queue` (01 §5.2) |
| AI inference | async/ streaming via gateway | AD-4 pipeline (docs/ai/*) |
| Device capabilities (notifications, capture, audio, DPC suspension v1.8) | local sync | platform adapters (04 §3.2, focus spec §4) |

## 4. Where each concern lives (quick map)

Architecture + decisions → [adr-compliance-report](./adr-compliance-report.md) ·
contracts → [contract-catalog](./contract-catalog.md) · tables/events/jobs →
[data-event-job-catalog](./data-event-job-catalog.md) · permissions →
[permission-matrix](./permission-matrix.md) · cross-feature flows →
[cross-feature-interactions](./cross-feature-interactions.md) · workflows →
[../workflows/composite-workflows.md](../workflows/composite-workflows.md) · pages &
navigation → [../mobile/navigation-and-page-composition.md](../mobile/navigation-and-page-composition.md) ·
frontend contracts & feature registry → [../frontend/page-contracts.md](../frontend/page-contracts.md),
[../frontend/feature-registry.md](../frontend/feature-registry.md) · backend →
[../backend/supabase.md](../backend/supabase.md), [../cloudflare/r2.md](../cloudflare/r2.md),
[../cloudflare/workers.md](../cloudflare/workers.md), [../ai/gateway.md](../ai/gateway.md) ·
feature catalog → [../features/master-feature-catalog.md](../features/master-feature-catalog.md) ·
agent → [../agent/kernel.md](../agent/kernel.md) +
[../agent/feature-agentability-matrix.md](../agent/feature-agentability-matrix.md).
