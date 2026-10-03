# API / Contract Catalog (Deliverable F)

All TypeScript contracts and important APIs of Aurora, by surface. SSoT rule (AD-15/F-01):
domain shapes live in `packages/domain`; these listings are **documentation of the contracts**
(the packs are the prescriptive source of truth — if one line below disagrees with a pack, the
pack wins and this page is wrong: file it in [gap-register.md](./gap-register.md)).

## 1. Envelopes & shared types (SSoT `packages/domain`, owner Foundation)

```ts
// 01 §3.1
type ApiEnvelope<T> = { ok: true; data: T } | { ok: false; error: ApiError };
type ApiError = { code: string /* module-prefixed, e.g. "productivity/task_not_found" */;
                  message: string; details?: Record<string, unknown> };
type AIResponseEnvelope = { provider: string; model: string; attempt: number;
  reason: 'primary' | 'fallback' | 'last_resort';
  expectedQuality: 'full' | 'degraded'; fallbackUsed: boolean; traceId: string };
// AppError / AppErrorCode — shape currently in 02 §10 body; must move to packages/domain (G-M3/C-3)
```

## 2. Domain ports (server-side, 01 §3.2 + ADR §8/§26)

| Port | Method sketch | Notes |
|---|---|---|
| `ObjectStorage` | `put/get/delete`, `presignGet(key, ttlSec)`, `presignUpload(key, ttlSec, sizeBytes)` | R2 impl (Artifact module, AD-16 owner Foundation); client uploads via presigned URL only (AD-3) |
| `AIProvider` | `complete(req): Promise<AIResponseEnvelope>`, `stream(req, sink)` | normalized; client never sees a vendor (AD-3) |
| `ResearchProvider` | multi-source search (You.com / Tavily / Exa) | optional capability: degrades to `uncertain` marking (01 §6) |
| `IntegrationProvider` | Composio | optional |
| `ArtifactProvider` | artifact lifecycle | behind Artifact module |
| `ScientificEngine` | deterministic math/units (see module page) | swappable backends |
| `NotificationProvider` | push + local notification | OneSignal (server) + Capacitor local split, 04 §3.4 |
| `KnowledgeBase` | retrieval over Postgres+FTS+pgvector | server-only retrieval (AD-12/F-09) |
| `JobRunner` | job execution | see [jobs/overview.md](../jobs/overview.md) |
| `FocusController` | 04 §4.2 minimal: `startSession`, `endSession`, `reduceNotifications`, `isBlockingAvailable` (+ **proposed additive extension**, [focus-mode/spec.md §5](../focus-mode/spec.md)) | V1 Android: blocking NOT available |
| `DocumentScanner` | `capturePage({source, allowMulti})` | camera on device; OCR server-side (AD-8) |
| `OCRProvider` | `isAvailable()` (server) | optional; degrade → manual entry |
| `AudioArtifactProvider` | `record/stopRecording/stream/export` | 04 §3.2.4 |
| `TranscriptionProvider` (optional) | `isAvailable()`, `transcribe(fileId) → {jobId}` | job server-side; never local STT in V1 |

## 3. AI pipeline contracts (ADR v1.7 §9 — all in `packages/domain`, impl server)

`AIProvider` · `AIModelRegistry` (catalog: capabilities, context, modality, status, quotas, conditions)
· `AIModelRouter` (selection by typed `TaskProfile`, never prompt keywords) · `AIModelPolicy`
(security/privacy/criticality/cost/compatibility) · `AIFallbackStrategy` (deterministic chain per
task type) · `AIHealthRegistry` (latency, error rate, 429/5xx, cooldown, availability per
provider/model) · `AIUsageTracker` (tokens/neurons/requests/latency/cost, free-tier consumption)
· `AIBudgetManager` (budgets per provider/model/env/user; stop before overrun, job receives
`budgetSnapshot`) · `AIRequestGuard` (context-size validation, timeouts, job idempotency,
sensitive-data filtering, data-policy refusal **before** the call — 01 §6).

## 4. Local data contracts (03 §3, owner `packages/data`)

```ts
interface LocalQueryRepository<T extends {id: string}> {
  getById(id: string): Promise<T | undefined>;
  list(filter: LocalFilter<T>): Promise<T[]>;
  watch(filter: LocalFilter<T>, onChange: (rows: T[]) => void): Unsubscribe; // local-only, reactive
}
interface LocalCommandRepository {
  apply(ownerModule: string, cmd: DomainCommand | DomainCommand[]): Promise<WriteResult>;
} // DomainCommand = partial-intent unions per entity, frozen in packages/domain
   // (TaskUpdateCommand {op:'task.update', id, patch}, TaskCreateCommand, …)
type WriteResult = { ok: true; queuedForUpsync: number } | { ok: false; error: { code: string; message: string } };

// 03 §3.2 — sync states exposed to the UI (5th canonical UX state = offline)
type SyncStatus = /* pending | syncing | idle | conflict … */ // 'conflict' reachable ONLY on un-mergeable CRDT collision
```

UI reads **only** through `LocalQueryRepository` (SQLite, no network on render path, AD-7);
writes **only** through `LocalCommandRepository` → owning module; React Query ↔ `watch`
bridge owned by `packages/data` (03 §5.8).

## 5. Platform adapters (04 §3.2, owner `packages/platform` — the only native surface the app consumes)

`AppLifecycleAdapter` (appStateChange foreground/background; back button; permission surface
`BACKGROUND_ACTIVITY | FOREGROUND_SERVICE | POST_NOTIFICATIONS`) ·
`LocalFileStorageAdapter` (saveBlob/getFile/deleteFile; `upload(fileId, presigned)` → R2,
client never holds R2 keys) · `DocumentScanner` · `AudioArtifactProvider` ·
`RemoteNotificationAdapter` (OneSignal: `init(appKey via capacitor.config.ts)`,
`onForegroundNotification`, `getSubscribed/setSubscribed`) ·
`LocalNotificationAdapter` (`scheduleLocal`, `cancelLocal`, `reduceForFocus(on)`) ·
`NetworkStatusAdapter` (`online`, `onNetworkChange`).
Whitelist (04 §3.1): any Capacitor plugin outside the list = Foundation PR (AD-16c).

## 6. Event contracts (AD-9, 01 §3.3 — payloads in `packages/domain`)

| Event | Producer | Declared consumers | Minimal payload |
|---|---|---|---|
| `TaskCompleted` | Productivity | Progress, Learning, Agent | `{taskId, userId, completedAt, evidenceRefs?}` |
| `CourseImported` | Learning | Knowledge, Discovery, Progress | `{courseId, userId, source, importedAt}` |
| `FlashcardReviewed` | Learning (FSRS) | Progress | `{cardId, userId, rating, nextDueAt, fsrsState}` |
| `ProgressEvidenceCreated` | **Progress only** | Knowledge (`NodeState`), Agent | `{evidenceId, userId, skillId?, goalId?, type, level, confidence, sourceEventId}` |
| `SkillStateChanged` | **Progress** | Agent, Discovery, Learning | `{skillId, userId, newState, freshness, confidence}` |
| `GoalUpdated` | Productivity | Progress, Agent | `{goalId, userId, changedAt, fields[]}` |
| `ArtifactGenerated` | **Artifact, after R2 upload only** | Knowledge (`SourceRef`), Learning (proof) [+ UI — OQ-05] | `{artifactId, userId, kind, r2Key, sizeBytes, generatedAt, jobId}` |
| `JobCompleted` | Job system | Artifact, UI | `{jobId, jobKind, userId, status, result?}` — `jobId`+`jobKind` mandatory (F-08) |
| `DiscoveryItemCreated` | Discovery | Learning, Knowledge, Progress, Agent | `{discoveryItemId, userId, topic, sources, createdAt}` |

Transport V1: insertion into producer's `events` table (Event History); consumers observe via
Postgres trigger → job or incremental `since_event_id` job reads. No broker (01 §3.3).

## 7. Job contracts (01 §5.2)

```ts
type DispatcherApi = {
  dispatchDue(now: Date, limit?: number): Promise<{ picked: number; skipped: number }>;
  claimJob(jobId: string, workerKind: string): Promise<{ ok: boolean; payload?: JobPayload }>;
  reportResult(jobId: string, result: { status: 'done' | 'failed'; result?: unknown }): Promise<void>;
}
```
Triggers = **exclusively** Supabase Cron + Postgres trigger on INSERT `job_queue` (AD-8).
`workerKind = job_queue.kind`; one kind vocabulary in `packages/domain` (AD-15).
Edge Functions catalog: `fn-job-dispatcher`, `fn-import-course`, `fn-notifications`,
`fn-agent-run`, + per-kind workers (01 §5.1).

## 8. UI state & renderer contracts (02 §3/§5, 05 §3.6/§5.8)

- Zustand UI store: selections, view modes, scroll anchors, theme (v2 enum after G-H3 fixes),
  focus-mode, palette open/close; `persist` middleware for cosmetics. **Never domain entities**
  (single-writer AD-7).
- React Query: data reads from local repositories only (02 §3.2).
- AD-10 renderer CONSO signatures (02 §5.1–5.5): `SemanticTreeRenderer` (`RenderSemanticNode`
  projection, lazy level-1 + incremental Dagre), `InfographicRenderer` (`InfographicSpec`
  validation → SVG), `DataVisualizationRenderer` (`ChartSpec`), `MathRenderer` (LaTeX +
  `onError` → styled raw source, never crash), `AnimationController` (RevealKey/reduced motion).
  DEFs in 05 §3.6 (9 DS data components + renderers); G1 frontmatter ratifies equality of props.
- Theme contracts (05 §5.8, AD-17 candidate): `packages/ui/src/themes/` JSON SSoT (10 living
  themes + 3 presets: Slate/Nocturne/High Contrast per §5.5), `resolveToken` +
  `<AuroraThemeProvider>` (wave-0 deliverable, 05 §7.2).

## 9. Agent kernel surface (F-09)

Device sees **only** `AgentRunState` (02 §4); kernel execution = server jobs + gateway
(AD-12, 01 §5.6); `Verify` of critical tasks runs as a persisted server job, optionally a
second "judge" model only when justified (01 §5.6, ADR v1.7 §14).

## 10. Registry contracts (master mission S65/S66 — additive, registries.md)

| Contract | Purpose | Methods | Input | Output | Errors | Permissions | Platform | Implementation | Consumers |
|---|---|---|---|---|---|---|---|---|---|
| `FeatureRegistry` | feature activation / deactivation | `get(id)`, `list(filter?)`, `set(id, patch)`, `available(id)` | `FeatureDescriptor` (feature-registry.md S1) | `FeatureDescriptor[]` / availability bool | `feature_not_found`, `dependency_unsatisfied` | identity:write | shared | `packages/domain` type; seed in `user_context`; runtime owner Foundation + App Shell | Navigation Registry, Screen Registry, Agent Capability Registry, Availability Policy |
| `CapabilityRegistry` | agent capability discovery | `list(filter?)`, `get(id)`, `available(id, context?)` | `AgentCapability` (kernel S14) | `AgentCapability[]` | `capability_unavailable` (provider absent / feature disabled / platform mismatch) | per-capability scopes | shared (server) | `packages/agent` (server); types in `packages/domain` | Agent Kernel (Tool Registry, Planner) |
| `NavigationRegistry` | route / nav entry management | `routes(filter?)`, `deepLink(featureId, params)`, `visible(featureId)` | route definitions (02 S6.1) | `RouteDefinition[]` / deep link URL | `route_disabled` (feature off) | — | mobile | `packages/navigation` (shell) | Frontend Router, Command Palette, Agent `NavigationIntent` |
| `ProviderRegistry` | external provider enumeration | `list(category?)`, `get(id)`, `status(id)` | provider entries (registries.md S1) | provider entries + status | `provider_retired` | foundation:read | server | Supabase `provider_registry` table; owner Foundation (AD-16) | AIModelRouter, ResearchProvider, ObjectStorage, NotificationProvider, IntegrationProvider |
| `ModelRegistry` | AI model catalog | `list(filter?)`, `get(modelId)`, `retire(modelId)`, `quota(modelId)` | model entries (registries.md S2) | model entries + quota snapshot | `model_unavailable`, `quota_exhausted` | foundation:read | server | Supabase `model_registry` (owner `packages/data`, AD-16b) | AIModelRouter, AIHealthRegistry, AIBudgetManager |
| `ArtifactRegistry` | artifact type catalog | `list(kind?)`, `previewSpec(artifactId)`, `exportFormats(artifactId)` | artifact type entries (registries.md S6) | type specs / preview renderer ref / formats | `format_unsupported` | artifact:read | shared | Artifact module; R2 key conventions | UI (artifact cards), Agent (`artifact.generate`) |
| `IntegrationRegistry` | external integration catalog | `list(vendor?)`, `connectionState(userId, vendor)`, `tools(userId, vendor?)` | integration entries (registries.md S7) | integration entries + connection state + tool schemas | `disconnected`, `reauth_required` | integrations:read | server | Integrations module; Composio API | Agent Tool Registry, NotificationProvider |

## 11. Agent UI command contracts (kernel S15, mission S61-S63)

```ts
// SSoT packages/domain, consumed by apps/mobile shell + packages/agent
interface AgentActionEnvelope {
  actionId: string;             // ULID, idempotent
  kind: 'navigate' | 'select' | 'filter' | 'expand_node'
     | 'show_artifact' | 'start_focus' | 'schedule'
     | 'confirm' | 'result';
  payload: unknown;             // typed per kind (NavigationIntent, UiStateCommand, …)
  confirmationRequired?: boolean;
  deepLink?: string;           // optional route target (NavigationRegistry)
}

interface NavigationIntent {
  route: string;               // from NavigationRegistry
  params?: Record<string, string>;
  query?: Record<string, string>;
  focusElement?: string;       // optional in-page anchor
}

interface UiStateCommand {
  command: 'select' | 'filter' | 'expand_node' | 'show_artifact' | 'start_focus' | 'open_page';
  target: string;             // entity ID / node ID / artifact ID / route
  params?: Record<string, unknown>;
}
```

Rule (mission S77): the kernel emits these envelopes; the mobile shell
consumes them through the command bus (02 S4). The kernel NEVER imports
React components, Zustand stores, or DOM APIs.

## 12. Vercel AI SDK (implementation detail, AD-1 boundary)

The Vercel AI SDK (`ai` npm package) is the **implementation framework**
behind `AIProvider` (contract-catalog S2, ADR v1.7 S9). It is NOT a
domain contract — it lives in `packages/agent` (server) and
`apps/mobile` (client `useChat` only). No other package imports it.

| Aspect | Detail |
|---|---|
| Server | `streamText` / `generateText` in `fn-agent-run` + jobs; `maxSteps` for autonomous tool-calling loop; tool definitions mapped to Aurora ports (ResearchProvider, KnowledgeBase, IntegrationProvider, ScientificEngine, FocusController) |
| Client | `useChat` hook in `apps/mobile` (Ionic React compatible); streams `AgentRunState`; attachment handling (files -> R2 presigned); tool-call interception -> AD-10 renderers |
| Router | `aiRouter.selectModel(taskProfile)` returns a `LanguageModel` adapter (Agnes, Workers AI, Groq, OpenRouter, etc.); all behind CF AI Gateway (primary) or direct (fallback) |
| Fallback | Gateway 429/5xx -> next provider; last resort = CF Worker (Workers AI direct); `AIResponseEnvelope` tracks every step |
| Security | Zero provider keys in device bundle (AD-3); SDK runs server-side; `useChat` calls Supabase Edge Function (authenticated) |
| Tiptap | Server AI outputs markdown/JSON; client Tiptap editor renders with CorpusBadge (AD-11) + SourceRef; Yjs = future only |
| Exports | artifact_gen job (PDF/DOCX/PPTX/XLSX/PNG/TXT/LaTeX/Audio) -> R2 -> `ArtifactGenerated` (F-06) |
| Excluded | CopilotKit (conflicts with AD-10 frozen engines + 5-state UX + local-first) |
| Docs | docs/ai/vercel-ai-sdk-integration.md (full spec, 2026-09-22) |
