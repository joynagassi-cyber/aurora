// =============================================================================
// @aurora/data — Wave 1: the local-first store (03-sync, AD-7).
//
// The UI reads ONLY through `LocalQueryRepository` and writes ONLY through
// `LocalCommandRepository` (03 S3.1, F-03 single-writer). The store is the
// SQLite/PowerSync mirror of the AD-15 entities; the server remains the
// authority (server-wins + per-entity `updated_at`, 03 S5.3), and merge
// lists use the frozen OR-Set CRDT (03 S5.3, SSoT `@aurora/domain`).
//
// Vendors (PowerSync engine) stay in this package (AD-1: it is one of the
// 5 adapters). The test/spine path runs the reference `InMemoryLocalStore`
// under Node type-stripping, zero dependency.
// =============================================================================

// contracts
export type {
  LocalFilter,
  LocalRow,
  Unsubscribe,
} from './local-filter';

// store engine
export type {
  LocalStore,
  DownstreamBatch,
} from './local-store';
export { InMemoryLocalStore } from './local-store';

// commands + ownership
export type {
  DomainCommand,
  CommandBase,
  TaskUpdateCommand,
  TaskCreateCommand,
  TaskDeleteCommand,
  GoalUpdateCommand,
  NoteUpdateCommand,
  ResourceUpdateCommand,
  FocusSessionStartCommand,
  FocusSessionEndCommand,
  ReviewRatedCommand,
  CourseUpdateCommand,
  DiscoveryItemUpdateCommand,
  AutomationUpdateCommand,
  UserContextUpdateCommand,
} from './commands';
export {
  OWNER_MODULE_BY_ENTITY,
  commandEntity,
} from './commands';

// repositories
export type {
  WriteResult,
  LocalQueryRepository,
  LocalCommandRepository,
} from './repositories';
export {
  SqliteQueryRepository,
  SqliteCommandRepository,
} from './repositories';

// sync status (03 S3.2)
export type {
  SyncState,
  SyncStatus,
  SyncStatusChange,
} from './sync-status';
export { SyncStatusMachine } from './sync-status';

// upsync queue (03 S5.1 / S5.5.6)
export type { UpsyncEntry, BatchOptions } from './upsync-queue';
export { UpsyncQueue } from './upsync-queue';

// sync engine (03 S5.1 / S5.2 / S5.5 — offline-to-online orchestration)
export type {
  UpsyncResponse,
  SyncTransport,
  SyncEngineOptions,
} from './sync-engine';
export { SyncEngine } from './sync-engine';

// CRDT OR-Set (03 S5.3 — the single implementation)
export type {
  OrSetRemove,
  OrSetState,
} from './crdt-orset';
export {
  addOrSetElement,
  removeOrSetElement,
  orSetLive,
  mergeOrSets,
  mergeLocalWithServer,
  mergeOrSetValues,
} from './crdt-orset';

// server-wins conflict resolution (03 S5.3)
export {
  resolveServerWins,
  CRDT_LIST_FIELDS,
} from './server-wins';

// ULID (03 S5.5.6 — localMutationId)
export {
  UlidGenerator,
  encodeUlid,
  ulidTimestamp,
} from './ulid';
export type { UlidOptions } from './ulid';

// local notifications (04 S3.4)
export type {
  LocalNotificationPayload,
  ScheduledNotification,
  LocalNotificationTransport,
} from './notifications';
export {
  LocalNotificationAdapter,
  InMemoryNotificationTransport,
} from './notifications';

// React Query bridge (03 S5.8 — owner of the RQ ↔ LocalQueryRepository
// contract; no vendor import, the hook lives in packages/ui)
export {
  localQueryKey,
  entityQueryKey,
  localQueryClient,
  localInvalidationKey,
} from './react-query-bridge';
export type { LocalQueryClient } from './react-query-bridge';
