# Frontend ↔ Backend Contracts (per feature; commands vs queries; offline behavior)

Status: design phase. Authority: 02 §4 (6 layers, contract per layer), 03 §3
(repositories), 01 §3.1 (envelopes), 01 §6 (states/errors), 02 §7 (5 UX states),
03 §5 (sync). This is the wiring every feature page must follow — no feature
talks to the network directly.

## 1. The two chains (mission §18)

**Commands (writes):**

```
UI (presentation, emits onX)
  ↓ Use-Case (02 §4: pure orchestration, one command per mutation, Result<T, AppError>)
  ↓ LocalCommandRepository.apply(ownerModule, DomainCommand partial)   [AD-7/F-03]
  ↓ owning module applies locally (single-writer) → upsync queue → Supabase (RLS, 01 §2.2)
  ↓ downstream PowerSync view push → other devices/surfaces
```

**Queries (reads):**

```
UI (presentation)
  ↓ React Query (data state, 02 §3.2) ← bridge (03 §5.8) ← LocalQueryRepository.watch
  ↓ SQLite mirror (AD-15 entities, 03 §4)  — NO network on the render path (AD-7, 02 §9)
```

Rule: the use-case layer **decides, never renders** (02 §4); presentation is
`(props, uiStoreSelectors) → JSX` (no repository/domain imports, 02 §4 layer
contracts); a component that contains business logic = blocking review finding.

## 2. Per-feature contract rows (owner slice → command → backend → persistence)

| Feature (slice) | Command(s) (partial, 03 §3.1) | Backend touch | Persistence / state |
|---|---|---|---|
| Tasks (productivity) | `TaskUpdateCommand`/`TaskCreateCommand`/`TaskDeleteCommand` (op + id + patch) | upsync → `tasks` (01 §4.1, RLS user) ; heavy re-plan = job | `tasks` local mirror; 5 states (02 §7) |
| Calendar/time blocking | `EventUpdateCommand`, time-block patch | upsync; conflict detection local (data) | `events` (calendar ≠ server Event History `events`, 03 §4.2 note) |
| Goals/projects/habits | `GoalUpdateCommand`, `ProjectUpdateCommand`, `HabitCheckinCommand` | upsync; analytics = jobs | 01 §4.1 tables |
| Focus | `focus_sessions` command (owner Productivity) + `reduceForFocus` (platform) + v1.8 DPC `applyBlocklist` (platform adapter, OQ-17) | session row upsync; bilan SSoT 01 §4.1 | `focus_sessions` |
| Courses/OCR import | `course_import` request → **job** (01 §5.1 `fn-import-course`, OCR `ocr` kind) | R2 upload (presigned, 01 §5.4) + Postgres + pgvector | `courses`/`course_imports`; UI `loading` until `JobCompleted` |
| Sheets/QCM/flashcards generation | `sheet.generate`/`qcm.generate` = **jobs** (agent + fidelity) | AI gateway (AD-4) + `ArtifactGenerated` post-R2 (F-06) for exports | generation state = job state (01 §6) |
| Flashcard review | `ReviewRatedCommand` (partial, FSRS input) | FSRS tick = **server job** (01 §5.2 trigger); device reads FSRS state mirror (03 §4.2) | `flashcards` + FSRS cols |
| Mirror mode | `learning_sessions.mode='mirror'` + findings (server job `mirror-analysis`) | agent job; evidence via Progress only (F-07) | session + findings rows |
| Knowledge tree | read-only UI (mirror); server ingestion/consolidation jobs | pgvector + FTS server-only (AD-12/F-09) | `semantic_*`, `node_state` (Knowledge-only writer, AD-6) |
| Discovery | `discovery.research` = **job** (multi-source) | `ResearchProvider` (server) | `discovery_items`; uncertainty marking (01 §6) |
| Progress | read mirrors only; `skill_recompute`/evidence jobs (Progress owner) | 01 §4.4 + jobs | `skill_states`, `progress_snapshots` (mirrors), rest server-only (03 §4.2) |
| Artifacts | presign request (Edge Function) → client upload (04 §3.2.2) | R2 + `artifacts` metadata (01 §4.6) | metadata + `r2_key` local; binaries never in SQLite |
| Agent | `fn-agent-run` (server) via jobs; UI consumes `AgentRunState` only (F-09) | kernel + AI gateway | run history server |
| Automations (Integrations) | `AutomationUpdateCommand` | Cron → dispatcher → jobs (AD-8) | `automations` |

## 3. The eight mandatory behaviors (mission §18, per screen)

| Behavior | Where it lives (normative) |
|---|---|
| **optimistic update** | local command applies immediately (SQLite write) + upsync queue (`WriteResult.queuedForUpsync`, 03 §3.1) — that IS the optimistic pattern; rollback on server rejection = server-wins resolution applied to the mirror (03 §5.3) |
| **offline** | reads = local always; writes = queued; cloud-only actions disabled with honest UI (02 §7 `offline`, 03 §5.9) |
| **retry** | jobs: bounded exponential backoff + idempotency (AD-8, 01 §5.3); UI: retry affordance on `error` states with `jobId` (01 §6) |
| **loading** | skeletons per component (05 §3.7 matrix) — data comes from local, so "loading" = first-hydrate or job-waiting, never a web fetch spinner on the render path (02 §9) |
| **stale data** | `SyncStatus`/`SyncState` exposed to UI (03 §3.2); stale = badge + re-sync action; CRDT lists merge losslessly, scalars server-wins silently (03 §5.3) |
| **errors** | `AppError`/`ApiEnvelope` (01 §3.1, SSoT `packages/domain` — G-M3: shape to move there) module-prefixed codes; 5 states per screen (AD-13) |
| **conflict** | default silent server-wins + per-entity `updated_at`; `conflict` state only on un-mergeable CRDT type-collision (user alert + lossless merge, 03 §3.2) |
| **synchronization** | PowerSync scopes/views owned by `packages/data` (AD-7, 03 §5.4); background throttle `minSyncIntervalMs` (03 §5.7, 04 §6.2); long-outage re-sync (03 §5.5) |

## 4. Offline class per feature (mission §19 — the agent must know it)

**Offline-capable** (fully usable on the local mirror): tasks/calendar/habits/goals
views, flashcards review (FSRS state read; rating queued), focus session (timer +
in-app; DPC block = device-local, no network), notes/drafts (Tiptap local), tree
browsing (mirror), progress dashboards (mirrors), artifacts previews (cached).
**Online-required** (need server): AI generation (sheets/QCM/mirror analysis, AD-12
server-side), semantic retrieval (pgvector, AD-12/F-09), discovery research
(providers), exports (jobs), auth re-validation. **Hybrid**: course import (upload
local capture works offline; OCR/ingestion = job), flashcard **generation** (review
offline-capable, generation online), focus bilans (local) vs focus evidence
qualification (job). The class is metadata of the feature (feature registry
`offlineClass`) and of the agent capability (kernel §8: the planner must not plan an
online-only step into an offline window — it marks it "will run when online").
