/**
 * @aurora/data — local-first data layer (03 S3, owner Data team).
 *
 * Frozen contracts (contract-catalog §4): `LocalQueryRepository` (SQLite
 * reads, no network on render path — AD-7) and `LocalCommandRepository`
 * (writes queued for upsync, AD-7/F-03). PowerSync/SQLite implementations
 * ship in wave 1; these shapes are the SSoT every React Query queryKey
 * factory types against.
 */
export type { Unsubscribe } from './watch';
export type {
  LocalQueryRepository,
  LocalCommandRepository,
  LocalFilter,
  WriteResult,
} from './repos';
