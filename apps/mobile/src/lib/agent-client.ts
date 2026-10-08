// =============================================================================
// agent-client.ts — device-side AgentRun client (AD-3, AD-12, F-09).
//
// The kernel is ONE, server-side (AD-12). This module is the device's
// typed door to it:
//   - `startAgentRun` enqueues via `fn-agent-run` (202 + agentRunId).
//   - `pollAgentRun` reads the `agent_runs` mirror (local-first, AD-7).
//
// AD-3: only the publishable Supabase client is used — zero provider keys
// on the device. AD-1: the vendor SDK import stays inside @aurora/data
// (`AuroraSupabaseClient` alias) — this file touches no vendor types.
// =============================================================================

import type { AuroraSupabaseClient } from '@aurora/data';

/**
 * Environment surface (AD-3, OQ-03): the same values `main.tsx` builds
 * from `.env.local` — kept here as an injectable so the client is
 * testable and the shell owns the single env source.
 */
export interface AgentClientEnv {
  /** `SUPABASE_URL`. */
  supabaseUrl: string;
  /** `SUPABASE_PUBLISHABLE_KEY` (publishable only — never a secret, AD-3). */
  supabasePublishableKey: string;
  /**
   * Pre-made client factory (tests / the app's boot provider inject it).
   * When absent, a publishable-key-only client is constructed (AD-3).
   */
  clientFactory?: () => AuroraSupabaseClient;
}

/** The `fn-agent-run` request body (01 §5.1: intent + refs + profile). */
export interface AgentRunRequest {
  intent: string;
  contextRefs?: string[];
  /**
   * The typed task profile (AD-3 public config). The kernel enforces
   * AD-5 fallback + the agent's capabilities server-side; these fields
   * are device preferences, never secrets.
   */
  taskProfile?: {
    preferredProvider?: string;
    preferredModel?: string;
    thinkingLevel?: 'low' | 'medium' | 'high' | 'max';
    researchMode?: 'off' | 'standard' | 'deep';
    agentMode?: 'chat' | 'agent' | 'mirror' | 'ascent';
  };
}

/** The `fn-agent-run` 202 response handle (the run id the device follows). */
export interface AgentRunHandle {
  /** the kernel's ULID run id (the agent_run job's trace). */
  agentRunId: string;
  /** the server job driving the run (AD-8). */
  jobId: string;
  /**
   * The `agent_runs` mirror uuid PK (F-09 SSoT) — the device polls
   * `agent_runs` by this id; the ULID `agentRunId` lives in
   * `agent_runs.trace_id`, never in the uuid `id` column.
   */
  traceId: string;
}

/**
 * A device-side view of an `agent_runs` row (0008): the status vocabulary
 * lives in the migration (`running/completed/failed/cancelled`) — distinct
 * from `AgentRunState.status` (kernel streaming, 02 §4); the client maps
 * it where needed.
 */
export interface AgentRunRow {
  /** the `agent_runs` uuid PK the device polls by (F-09 SSoT). */
  id: string;
  userId: string;
  intent: string;
  status: 'running' | 'completed' | 'failed' | 'cancelled';
  /** the kernel's ULID run id (agent_runs.trace_id — the run handle, not the uuid PK). */
  agentRunId?: string;
  /** the server job driving the run (AD-8/F-09). */
  jobId?: string;
  /** the confirmation prompt when the action is important/irreversible (ADR §5). */
  confirmationMessage?: string;
  startedAt: string;
  completedAt?: string;
}

/**
 * The device-side agent client. Constructed with the app's Supabase
 * client (signed-in scope, AD-3) — nothing else crosses this boundary.
 */
export interface AgentClient {
  /** POST `fn-agent-run` → enqueues the `agent_run` job (AD-8). */
  start(run: AgentRunRequest): Promise<AgentRunHandle>;
  /** Latest `agent_runs` mirror row for a run (AD-7 local read). */
  run(runId: string): Promise<AgentRunRow | null>;
  /**
   * The user's most recent runs, antéchronologique (PRD-AI-01
   * « Conversations » : read-only history list). AD-7 read side —
   * the device NEVER writes `agent_runs` (kernel-owned, AD-2/F-03
   * single-writer : only `fn-agent-run` + the job executor mutate it).
   */
  list(): Promise<AgentRunRow[]>;
}

/**
 * Typed agent errors (roadmap 10-07): the UI translates these kinds into
 * plain French (« connecte-toi » / « service en cours de démarrage » /
 * « réessaie ») — never raw vendor messages (AD-13 honest state).
 *   auth     — no user session (the kernel runs under the user's JWT)
 *   service  — `fn-agent-run` not deployed yet (gap G1, 404)
 *   server   — 5xx (the run job / AI gateway failed)
 *   network  — offline (fetch failed, no HTTP status)
 *   unknown  — anything else
 */
export type AgentErrorKind = 'auth' | 'service' | 'server' | 'network' | 'unknown';

export class AgentClientError extends Error {
  readonly kind: AgentErrorKind;
  constructor(kind: AgentErrorKind, message: string, cause?: unknown) {
    super(message);
    this.name = 'AgentClientError';
    this.kind = kind;
    if (cause instanceof Error && cause.cause === undefined) {
      (this as { cause?: unknown }).cause = cause;
    }
  }
}

/** Map a `functions.invoke` failure to a kind the UI can translate. */
export function categorizeAgentError(error: unknown): AgentClientError {
  const status = (error as { status?: unknown } | null)?.status;
  const message = error instanceof Error ? error.message : String(error);
  const http = typeof status === 'number' ? status : undefined;
  if (http === 404) {
    return new AgentClientError(
      'service',
      'Le service agent n\'est pas encore en ligne — réessaie dans un instant.',
      error,
    );
  }
  if (http !== undefined && http >= 500) {
    return new AgentClientError('server', 'Un problème serveur est survenu — réessaie.', error);
  }
  if (http === 400 || http === 401 || http === 403) {
    return new AgentClientError('auth', 'Connecte-toi pour lancer l\'agent.', error);
  }
  if (http === undefined && /fetch|network|timeout|econn/i.test(message)) {
    return new AgentClientError('network', 'Pas de connexion — réessaie quand tu es en ligne.', error);
  }
  return new AgentClientError('unknown', 'Le lancement a échoué — réessaie.', error);
}

/**
 * Map one raw `agent_runs` row (0008, snake_case) to the device-side
 * `AgentRunRow` view. Shared by `run()` (single row) and `list()` (the
 * PRD-AI-01 conversation history) — one mapper, no drift.
 */
function mapAgentRunRow(row: Record<string, unknown>): AgentRunRow {
  const steps = Array.isArray(row.steps_json)
    ? (row.steps_json as Array<Record<string, unknown>>)
    : [];
  const pending = steps.find((s) => s?.kind === 'confirmation' && s.status === 'pending');
  return {
    id: String(row.id),
    userId: String(row.user_id ?? ''),
    intent: String(row.intent ?? ''),
    status: (row.status as AgentRunRow['status']) ?? 'running',
    agentRunId: row.trace_id ? String(row.trace_id) : undefined,
    jobId: row.trace_id ? String(row.trace_id) : undefined,
    confirmationMessage: pending ? String(pending.message ?? '') : undefined,
    startedAt: String(row.started_at ?? ''),
    completedAt: row.completed_at ? String(row.completed_at) : undefined,
  } satisfies AgentRunRow;
}

export function createAgentClient(supabase: AuroraSupabaseClient): AgentClient {
  return {
    async start(run) {
      // The kernel runs under the USER'S JWT (AD-3) — without a session the
      // EF is uselessly enqueued; surface the honest "sign in" state (10-07).
      const { data: session } = await supabase.auth.getSession();
      if (!session?.session) {
        throw new AgentClientError('auth', 'Connecte-toi pour lancer l\'agent.');
      }
      const { data, error } = await supabase.functions.invoke('fn-agent-run', {
        body: run,
      });
      if (error) throw categorizeAgentError(error);
      // ApiEnvelope (01 §3.1): `ok` returns `{ ok: true, data }` —
      // supabase-js `data` IS that envelope body.
      const handle = (data as { ok?: boolean; data?: AgentRunHandle })?.data;
      if (!handle?.agentRunId) {
        throw new AgentClientError('service', 'Le service agent n\'a pas répondu — réessaie.');
      }
      return handle;
    },

    async list() {
      // PRD-AI-01 (Conversations) : read-only history — the device NEVER
      // writes agent_runs (kernel-owned, AD-2/F-03 single-writer : only
      // `fn-agent-run` + the job executor mutate it). RLS user isolation
      // keeps the device on its own runs (0008).
      const { data, error } = await supabase
        .from('agent_runs')
        .select('id, intent, status, started_at, completed_at, trace_id, steps_json')
        .order('started_at', { ascending: false })
        .limit(50);
      if (error) throw error;
      return ((data as unknown as Record<string, unknown>[] | undefined) ?? []).map(
        (row) => mapAgentRunRow(row),
      );
    },

    async run(runId) {
      // AD-7 local-first mirror (agent_runs, 0008): read side only — RLS
      // user isolation keeps the device on its own runs; a null row = the
      // job is still pending (honest empty state, never fake data).
      const { data, error } = await supabase.from('agent_runs').select('*').eq('id', runId);
      if (error) throw error;
      const row = (data as unknown as Record<string, unknown>[] | null)?.[0];
      if (!row) return null;
      return mapAgentRunRow(row);
    },
  };
}
