// =============================================================================
// PowerSync local SQLite mirror schema (03 S4.1 / S4.2 — the frozen mapping).
//
// The store is a MIRROR of the AD-15 entities: one local table per module
// owner, relations (FK/join) live inside the owning module ONLY (F-03 —
// never a cross-module join; cross-module reads go through the source
// module's public view, 01 S3.4). Files NEVER live in SQLite (AD-16: R2
// + `r2_key` metadata only). Server-only tables (expert_skills, events,
// progress_evidences/trends, progress_events) have NO local table.
//
// `updated_at` on the mirror is the CANONICAL server timestamp (03 S4.2
// rule 3): the local engine stores it as `server_updated_at_ms`; a local
// mutation carries `local_mutation_id` (ULID, 03 S5.5.6) + `local_ts_ms`
// (FIFO order only, never canonical).
//
// This is the DDL the PowerSync engine materializes on the device. It is
// plain text here so the reference engine and the device engine share one
// schema definition (single source, 03 S4.1).
// =============================================================================

export interface MirrorTableDef {
  /** mirror table name (single module owner, 03 S4.2) */
  name: string;
  /** the owning module (AD-15 mapping) */
  ownerModule: string;
  /** column DDL, in order */
  columns: string[];
  /** primary key column */
  pk: string;
  /** indexes (local query paths, 02 S9 — no network on render) */
  indexes?: string[];
}

/**
 * The frozen mirror tables (03 S4.2). Every mutable entity carries the
 * sync columns: `crdt_added` / `crdt_removed` (OR-Set jsonb),
 * `local_mutation_id`, `local_ts_ms`, `server_updated_at_ms`.
 */
export const MIRROR_TABLES: readonly MirrorTableDef[] = [
  // ---- Identity (owner Identity) -----------------------------------------
  {
    name: 'user_context',
    ownerModule: 'identity',
    pk: 'user_id',
    columns: [
      'user_id TEXT NOT NULL',
      'theme TEXT NOT NULL DEFAULT \'aurora\'',
      'theme_style TEXT NOT NULL DEFAULT \'light\'',
      'coaching_prefs TEXT NOT NULL DEFAULT \'{}\';',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Productivity (owner Productivity, 01 S4.1) ------------------------
  {
    name: 'tasks',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'project_id TEXT',
      'goal_id TEXT',
      'subject TEXT NOT NULL',
      'description TEXT',
      'status TEXT NOT NULL DEFAULT \'todo\'',
      'priority INTEGER NOT NULL DEFAULT 3',
      'importance INTEGER NOT NULL DEFAULT 3',
      'due_at TEXT',
      'parent_recurrence_key TEXT',
      'energy TEXT',
      'work_context TEXT',
      'actual_minutes INTEGER',
      'dependencies TEXT NOT NULL DEFAULT \'[]\'', // OR-Set (03 S5.3)
      'evidence_refs TEXT NOT NULL DEFAULT \'[]\'', // OR-Set (03 S5.3)
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
    indexes: ['CREATE INDEX idx_tasks_user ON tasks (user_id, status);'],
  },
  {
    name: 'projects',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'goal_id TEXT',
      'name TEXT NOT NULL',
      'description TEXT',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'start_date TEXT',
      'end_date TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'goals',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'description TEXT',
      'horizon TEXT NOT NULL DEFAULT \'mid\'',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'target_date TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'milestones',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'project_id TEXT',
      'goal_id TEXT',
      'title TEXT NOT NULL',
      'due_date TEXT',
      'status TEXT NOT NULL DEFAULT \'open\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'habits',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'name TEXT NOT NULL',
      'frequency TEXT NOT NULL DEFAULT \'{}\'',
      'target TEXT',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'streak INTEGER NOT NULL DEFAULT 0',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'routines',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'name TEXT NOT NULL',
      'anchor TEXT NOT NULL DEFAULT \'{}\'',
      'steps TEXT NOT NULL DEFAULT \'[]\'',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'focus_sessions',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'task_id TEXT',
      'started_at TEXT NOT NULL',
      'ended_at TEXT',
      'planned_minutes INTEGER',
      'actual_minutes INTEGER',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'notification_policy TEXT NOT NULL DEFAULT \'{}\'',
      'call_policy TEXT NOT NULL DEFAULT \'{}\'',
      'focus_app_rules TEXT NOT NULL DEFAULT \'{}\'',
      'session_bilan TEXT NOT NULL DEFAULT \'{}\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'decisions',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'context TEXT',
      'outcome TEXT',
      'decided_at TEXT NOT NULL',
      'reviewed_at TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'calendar_events',
    ownerModule: 'productivity',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'description TEXT',
      'start_at TEXT NOT NULL',
      'end_at TEXT',
      'all_day INTEGER NOT NULL DEFAULT 0',
      'recurrence TEXT NOT NULL DEFAULT \'{}\'',
      'location TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Knowledge (owner Knowledge, 01 S4.3; NO embedding column) --------
  {
    name: 'notes',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT',
      'body TEXT',
      'kind TEXT NOT NULL DEFAULT \'free\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'resources',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'mime_type TEXT',
      'r2_key TEXT', // AD-16: metadata + key only, the binary lives in R2
      'size_bytes INTEGER',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'semantic_nodes',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'kind TEXT NOT NULL',
      'label TEXT NOT NULL',
      'summary TEXT',
      'body TEXT',
      'parent_id TEXT',
      'domain_path TEXT',
      'source_ref_ids TEXT NOT NULL DEFAULT \'[]\'', // OR-Set; NO embedding (03 S4.2)
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'semantic_edges',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'source_node TEXT NOT NULL',
      'target_node TEXT NOT NULL',
      'relation TEXT NOT NULL',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'semantic_bridges',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'source_node TEXT NOT NULL',
      'target_node TEXT NOT NULL',
      'label TEXT',
      'secondaries TEXT NOT NULL DEFAULT \'[]\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'node_state',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'node_id TEXT NOT NULL',
      'state TEXT NOT NULL DEFAULT \'collapsed\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'source_refs',
    ownerModule: 'knowledge',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'entity TEXT',
      'entity_id TEXT',
      'source_document_id TEXT',
      'page INTEGER',
      'passage TEXT',
      'kind TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Learning (owner Learning, 01 S4.2; FSRS runs server-side) --------
  {
    name: 'courses',
    ownerModule: 'learning',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'description TEXT',
      'subject_id TEXT',
      'status TEXT NOT NULL DEFAULT \'active\'',
      'progress_pct REAL NOT NULL DEFAULT 0',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'subjects',
    ownerModule: 'learning',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'name TEXT NOT NULL',
      'description TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'skills',
    ownerModule: 'learning',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'name TEXT NOT NULL',
      'definition TEXT',
      'subject_id TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'learning_sessions',
    ownerModule: 'learning',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'course_id TEXT',
      'skill_id TEXT',
      'started_at TEXT NOT NULL',
      'ended_at TEXT',
      'duration_min INTEGER',
      'notes TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'reviews',
    ownerModule: 'learning',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'flashcard_id TEXT',
      'skill_id TEXT',
      'rating INTEGER NOT NULL',
      'reviewed_at TEXT NOT NULL',
      'fsrs_state TEXT NOT NULL DEFAULT \'{}\'', // due/stability/difficulty (read-only mirror)
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Progress (owner Progress; LIMITED mirror, 03 S4.2) --------------
  {
    name: 'skill_states',
    ownerModule: 'progress',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'skill_id TEXT NOT NULL',
      'level TEXT NOT NULL DEFAULT \'beginner\'',
      'freshness TEXT NOT NULL DEFAULT \'stale\'',
      'confidence REAL NOT NULL DEFAULT 0',
      'last_evidence_at TEXT',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  {
    name: 'progress_snapshots',
    ownerModule: 'progress',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'taken_at TEXT NOT NULL',
      'payload TEXT NOT NULL DEFAULT \'{}\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
  // `gaps` rows are owned by Progress (03 S4.2); Discovery READS them
  // through Progress's public view — the local mirror is read-only for
  // Discovery (F-04: it never writes).
  {
    name: 'gaps',
    ownerModule: 'discovery',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'kind TEXT NOT NULL',
      'description TEXT',
      'evidence_refs TEXT NOT NULL DEFAULT \'[]\'', // OR-Set (03 S5.3)
      'detected_at TEXT NOT NULL',
      'status TEXT NOT NULL DEFAULT \'open\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Discovery (owner Discovery, 01 S4.5) ----------------------------
  {
    name: 'discovery_items',
    ownerModule: 'discovery',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'title TEXT NOT NULL',
      'question TEXT',
      'why_now TEXT',
      'factual_summary TEXT',
      'sources TEXT NOT NULL DEFAULT \'[]\'',
      'kind TEXT NOT NULL',
      'status TEXT NOT NULL DEFAULT \'new\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Artifact (owner Artifact, 01 S4.6 — metadata + r2_key only) ----
  {
    name: 'artifacts',
    ownerModule: 'artifact',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'kind TEXT NOT NULL',
      'title TEXT',
      'mime_type TEXT',
      'r2_key TEXT', // AD-16: the binary lives in R2, never SQLite
      'size_bytes INTEGER',
      'source_event_id TEXT',
      'status TEXT NOT NULL DEFAULT \'queued\'',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },

  // ---- Integrations (owner Integrations, 01 S4.7) ----------------------
  {
    name: 'automations',
    ownerModule: 'integrations',
    pk: 'id',
    columns: [
      'id TEXT NOT NULL',
      'user_id TEXT NOT NULL',
      'name TEXT',
      'trigger TEXT NOT NULL DEFAULT \'{}\'',
      'action TEXT NOT NULL DEFAULT \'{}\'',
      'enabled INTEGER NOT NULL DEFAULT 1',
      'created_at TEXT NOT NULL',
      'server_updated_at_ms INTEGER NOT NULL DEFAULT 0',
      'local_mutation_id TEXT NOT NULL DEFAULT \'\'',
      'local_ts_ms INTEGER NOT NULL DEFAULT 0',
      'crdt_added TEXT NOT NULL DEFAULT \'[]\'',
      'crdt_removed TEXT NOT NULL DEFAULT \'[]\'',
    ],
  },
] as const;

/** The entities that have a local mirror table (03 S4.2 frozen set). */
export const MIRROR_ENTITY_NAMES: readonly string[] = MIRROR_TABLES.map(
  (t) => t.name,
);

/**
 * Build the `CREATE TABLE` DDL for one mirror table (idempotent: the
 * engine creates each once at store init; re-apply is a no-op via
 * `IF NOT EXISTS`).
 */
export function mirrorTableDdl(name: string): string {
  const def = MIRROR_TABLES.find((t) => t.name === name);
  if (!def) {
    throw new Error(
      `no mirror table "${name}" (03 S4.2 frozen mapping — add it to MIRROR_TABLES)`,
    );
  }
  const cols = [
    ...def.columns,
    `PRIMARY KEY (${def.pk})`,
  ].join(', ');
  let ddl = `CREATE TABLE IF NOT EXISTS ${def.name} (${cols});`;
  for (const idx of def.indexes ?? []) {
    ddl += ` ${idx}`;
  }
  return ddl;
}

/** Full schema bootstrap (all mirror tables + sync bookkeeping). */
export function fullMirrorSchema(): string {
  const syncMeta = `
CREATE TABLE IF NOT EXISTS _sync_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS _upsync_queue (
  local_mutation_id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  row_id TEXT NOT NULL,
  owner_module TEXT NOT NULL,
  patch TEXT NOT NULL,
  is_delete INTEGER NOT NULL DEFAULT 0,
  local_ts_ms INTEGER NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  acked INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_upsync_fifo ON _upsync_queue (local_mutation_id);
`;
  return MIRROR_TABLES.map((t) => mirrorTableDdl(t.name)).join('\n') + syncMeta;
}
