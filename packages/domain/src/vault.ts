/**
 * Vault entities + port (AD-15 SSoT, additive — Discovery module).
 *
 * The veille vault: a per-user, per-domain folder of Markdown synthesis
 * (VAULT.md) + append-only daily runs (runs/YYYY-MM-DD/rapport.md +
 * PNGs), persisted in Postgres (discovery_vault) + Supabase Storage
 * (PNGs), synced via PowerSync. Written ONLY by the `research` job
 * (AD-7 single-writer); the chat agent READS + proposes, never commits.
 *
 * 6 deterministic verbs (V1 heuristic; LLM verb-choice = backlog):
 *   appuier / ajouter / ameliorer / consolider / comparer / supprimer.
 */

/** The 6 mutation verbs of the vault synthesis (Yumi's lexicon). */
export type VaultVerbe =
  | 'appuier'
  | 'ajouter'
  | 'ameliorer'
  | 'consolider'
  | 'comparer'
  | 'supprimer';

/** A single mutation recorded on the manifest (verb + the run that did it). */
export interface VaultMutation {
  verbe: VaultVerbe;
  /** the run id that produced this mutation (traceability) */
  runId: string;
  /** the VAULT.md section touched ("Ce que je sais", "Ce qui a changé", …) */
  section: string;
  /** short human note (what changed, one line) */
  note?: string;
}

/** One append-only daily run (runs/YYYY-MM-DD/). */
export interface VaultRunManifest {
  /** run id (ULID, monotonic) */
  id: string;
  /** ISO date yyyy-MM-dd (the folder name) */
  date: string;
  /** the vault domain this run belongs to */
  domaine: string;
  /** number of NEW sources found this run (dedup vs previous runs) */
  newSources: number;
  /** total sources accumulated in the vault post-run */
  totalSources: number;
  /** the filter verdict of the run (0..1 relevance signal for the card UI) */
  relevance: number;
  /** the sections touched this run */
  sectionsTouched: string[];
  /** the mutations produced this run */
  mutations: VaultMutation[];
  /** asset keys uploaded to Supabase Storage this run (PNGs) */
  assets?: string[];
  /** ISO timestamp of the run */
  at: string;
}

/**
 * The per-(user, domain) vault document — the SSoT that evolves over
 * time. Persisted as one row (discovery_vault), one per user+domain.
 */
export interface VeilleVault {
  id: string;
  userId: string;
  /** the domain (e.g. 'structures', 'genie-civil') */
  domaine: string;
  /** the current VAULT.md content (the evolving single document) */
  vaultMd: string;
  /** SHA-256 of vaultMd (integrity check: hash ≠ manifest = corrupted) */
  vaultHash: string;
  /** the append-only manifest (index.json shape) */
  runs: VaultRunManifest[];
  /** the Supabase Storage prefix for this vault's PNGs */
  storagePrefix?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * `VaultStore` — the hexagonal port (AD-15, wave 2 additive).
 *
 * AD-7 single-writer: `write` is called ONLY by the Discovery `research`
 * job handler (packages/discovery/src/jobs.ts). `read` / `readRun` are
 * for the client mirror + the chat agent (Lot 3, READ-ONLY tool).
 */
export interface VaultStore {
  /** the sole writer path (AD-7) — the research job commits here */
  write(userId: string, domaine: string, next: VeilleVault): Promise<VeilleVault>;
  /** read the current vault (client + chat agent, READ-ONLY) */
  read(userId: string, domaine: string): Promise<VeilleVault | null>;
  /** read one run's rapport (append-only, never mutated) */
  readRun(userId: string, domaine: string, runId: string): Promise<VaultRunManifest | null>;
}
