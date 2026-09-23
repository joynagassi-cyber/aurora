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
