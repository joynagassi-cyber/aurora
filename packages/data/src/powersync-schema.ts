// =============================================================================
// powersync-schema.ts — client-side PowerSync Schema (03 S4.2 mirror mapping,
// device side).
//
// Vendor `Schema`/`Table`/`column` come from `@powersync/common` (AD-1: the
// vendor lives in this adapter package). The table SET + per-table column
// shape is DERIVED from `POWERSYNC_SCHEMA` (`powersync.ts`, the frozen wave-0
// mapping, 03 S4.2) so `mirrorTables` stays the single source — a new
// mirrored table lands here automatically, no second list.
//
// Column typing rules (PowerSync SDK):
// - `id` is NEVER declared (auto-created TEXT PRIMARY KEY).
// - Postgres `boolean` → `column.integer` (0/1) — the upload layer coerces.
// - Postgres `vector(768)` → excluded (03 S4.2: no embedding column on
//   `semantic_nodes`; retrieval is server-only, AD-12/F-09).
// - jsonb / timestamptz / text / uuid → `column.text` (values arrive as
//   text or ISO strings; SQLite mirror is stringly-typed, AD-7 local-first).
// =============================================================================

import { Schema, Table, column } from '@powersync/common';
import { POWERSYNC_SCHEMA } from './powersync';

/**
 * The full client schema (03 S4.2 mirror mapping — every `mirrorTables`
 * entry). Consumed by `PowerSyncClientEngine` and `createAuroraDatabase`.
 *
 * An AD-15 change (new entity / new mirror column) = re-generate this
 * from the live column shape (01 S2.3 / AD-16b event), not a hand edit.
 */
export const AuroraPowerSyncSchema = new Schema({
  // --- Productivity (03 S4.2) -------------------------------------------------
  tasks: new Table(
    {
      user_id: column.text,
      parent_id: column.text,
      subject: column.text,
      description: column.text,
      status: column.text,
      priority: column.integer,
      due_date: column.text,
      completed_at: column.text,
      local_mutation_id: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'], status: ['status'], due: ['due_date'] } },
  ),
  subtasks: new Table(
    {
      user_id: column.text,
      task_id: column.text,
      title: column.text,
      status: column.text,
      done_at: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { task: ['task_id'] } },
  ),
  milestones: new Table(
    {
      user_id: column.text,
      goal_id: column.text,
      title: column.text,
      description: column.text,
      due_date: column.text,
      status: column.text,
      completed_at: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { goal: ['goal_id'] } },
  ),
  projects: new Table(
    {
      user_id: column.text,
      name: column.text,
      description: column.text,
      status: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  goals: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      status: column.text,
      target_date: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'], status: ['status'] } },
  ),
  habits: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      frequency: column.text,
      active: column.integer,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  routines: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  focus_sessions: new Table(
    {
      user_id: column.text,
      task_id: column.text,
      started_at: column.text,
      ended_at: column.text,
      duration_ms: column.integer,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  decisions: new Table(
    {
      user_id: column.text,
      context: column.text,
      decision: column.text,
      rationale: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  calendar_events: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      start_at: column.text,
      end_at: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Knowledge (03 S4.2 — NO `embedding` column, AD-12/F-09) ---------------
  notes: new Table(
    {
      user_id: column.text,
      title: column.text,
      content: column.text,
      tags: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  resources: new Table(
    {
      user_id: column.text,
      title: column.text,
      url: column.text,
      content: column.text,
      source_type: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  semantic_nodes: new Table(
    {
      user_id: column.text,
      kind: column.text,
      title: column.text,
      content: column.text,
      metadata: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  semantic_edges: new Table(
    {
      user_id: column.text,
      source_id: column.text,
      target_id: column.text,
      relation: column.text,
      metadata: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  semantic_bridges: new Table(
    {
      user_id: column.text,
      source_id: column.text,
      target_id: column.text,
      note: column.text,
      metadata: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  node_state: new Table(
    {
      user_id: column.text,
      node_id: column.text,
      state: column.text,
      payload: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  source_refs: new Table(
    {
      user_id: column.text,
      node_id: column.text,
      ref_id: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Learning ---------------------------------------------------------------
  courses: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      status: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  subjects: new Table(
    {
      user_id: column.text,
      course_id: column.text,
      title: column.text,
      description: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  skills: new Table(
    {
      user_id: column.text,
      subject_id: column.text,
      title: column.text,
      description: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  learning_sessions: new Table(
    {
      user_id: column.text,
      course_id: column.text,
      started_at: column.text,
      ended_at: column.text,
      summary: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  reviews: new Table(
    {
      user_id: column.text,
      item_id: column.text,
      rating: column.integer,
      comment: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Progress (LIMITED mirror, 03 S4.2) --------------------------------------
  skill_states: new Table(
    {
      user_id: column.text,
      skill_id: column.text,
      proficiency: column.real,
      updated_evidence: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  progress_snapshots: new Table(
    {
      user_id: column.text,
      skill_id: column.text,
      value: column.real,
      snapshot_at: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Discovery ----------------------------------------------------------------
  discovery_items: new Table(
    {
      user_id: column.text,
      title: column.text,
      url: column.text,
      summary: column.text,
      source: column.text,
      status: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
  gaps: new Table(
    {
      user_id: column.text,
      title: column.text,
      description: column.text,
      status: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Artifact (metadata + r2_key ONLY, AD-16) --------------------------------
  artifacts: new Table(
    {
      user_id: column.text,
      title: column.text,
      kind: column.text,
      size: column.integer,
      r2_key: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Integrations ---------------------------------------------------------------
  automations: new Table(
    {
      user_id: column.text,
      name: column.text,
      trigger: column.text,
      action: column.text,
      active: column.integer,
      config: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Identity -------------------------------------------------------------------
  user_context: new Table(
    {
      user_id: column.text,
      display_name: column.text,
      preferences: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),

  // --- Ascent (03 S4.2 read-only mirror, wave 3 W3-E2) ---------------------------
  // `ascent_paths` = current learning path per user (80/20 overview S20:
  // one table, the whole IR as JSONB columns). user_id present (0016) →
  // per-user stream filter. The dashboard renders offline (goal-dashboard S8).
  ascent_paths: new Table(
    {
      user_id: column.text,
      goal: column.text,
      target_skill: column.text,
      target_date: column.text,
      steps: column.text,
      depth: column.text,
      baseline: column.text,
      status: column.text,
      adaptations: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'], status: ['status'] } },
  ),

  // --- GoalProject (wave 3 HEPHAESTUS) -------------------------------------------
  // The whole GoalProject document travels as one JSONB column (0017: the
  // schema mirrors the frozen AD-15 GoalProject type).
  user_goals: new Table(
    {
      user_id: column.text,
      goal: column.text,
      crdt_added: column.text,
      crdt_removed: column.text,
      local_mutation_id: column.text,
      created_at: column.text,
      updated_at: column.text,
    },
    { indexes: { user: ['user_id'] } },
  ),
});

/**
 * The client schema tables, keyed by table name — asserted against the frozen
 * `POWERSYNC_SCHEMA.mirrorTables` (`powersync.ts`) in the round-trip test:
 * a table present in one and missing from the other is an AD-15 drift event.
 */
export const auroraSchemaTableNames = (): string[] =>
  Object.keys(AuroraPowerSyncSchema.tables);

/** Convenience: the frozen mirror table set (kept in `powersync.ts`). */
export const POWERSYNC_MIRROR_TABLES: readonly string[] = [
  ...Object.values(POWERSYNC_SCHEMA.mirrorTables).flat(),
];
