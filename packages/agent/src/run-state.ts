/**
 * AgentRunState — the device-facing streaming surface (wave 3 task 5,
 * 02 S4, AD-12/F-09).
 *
 * AD-12: there is ONE kernel, server-side. The device consumes ONLY
 * this type — it never imports `AIProvider` / the router / any
 * provider internals (AD-3: zero provider keys on the device). This
 * file is data-only: NO React, no state management library, no
 * rendering. The mobile shell (apps/mobile) projects these snapshots
 * into its own stores; the kernel / `fn-agent-run` produce them.
 *
 * The shape mirrors the `AgentRun` SSoT entity (packages/domain,
 * entities-agent.ts) and extends it with the streaming fields the UI
 * needs (kernel.md S12: "AgentRunState for the UI"). The streaming
 * surface is a sequence of snapshots: the device renders the latest,
 * and the confirmation surface blocks until a decision arrives via
 * the command bus (task 6, run-bus.ts).
 */
import type { AgentRunState } from './types.ts';

/** The 5-state UX lifecycle every screen (and every run) exposes (AD-13). */
export type RunPhase = 'loading' | 'empty' | 'success' | 'error' | 'offline';

/**
 * A single streamed snapshot of the run. `fn-agent-run` emits these as
 * SSE / data-stream chunks; the device's `useChat` consumer applies
 * each one in order. Every snapshot is SELF-CONTAINED (idempotent
 * render: replaying any subset still yields a consistent UI).
 */
export interface AgentRunStateChunk {
  /** monotonic sequence number (ULID-ordered) — the device drops
   *  out-of-order chunks; late chunks are re-applied at reconnect */
  seq: number;
  /** the run this chunk belongs to */
  agentRunId: string;
  /** the full state snapshot at this point in the loop (02 S4) */
  state: AgentRunState;
  /** which chunk kind drove this snapshot (ad-hoc, human-readable) */
  kind:
    | 'stage' // a kernel loop stage advanced (intent→…→memory)
    | 'text' // a model text chunk streamed
    | 'tool' // a tool call / result was logged
    | 'confirmation' // a confirmation prompt was raised / resolved
    | 'envelope' // the AIResponseEnvelope of the last model call (AD-5)
    | 'done' // terminal: succeeded / failed / cancelled
    | 'heartbeat'; // keep-alive while a heavy job is pending (AD-8)
  /** emitted at (server clock) */
  at: string;
}

/**
 * Fold a stream of chunks into the run state the device renders.
 * Pure reducer: `state = applyChunk(state, chunk)`. The device keeps
 * NO kernel internals — only the reduced snapshot + its phase.
 */
export function applyChunk(
  prev: AgentRunState | undefined,
  chunk: AgentRunStateChunk,
): AgentRunState {
  // Out-of-order / stale chunk: drop it (the snapshot is self-contained,
  // so a fresh replay converges — the device never polls, it re-renders).
  if (prev && prev.updatedAt > chunk.state.updatedAt && chunk.kind !== 'done') {
    return prev;
  }
  // Text accumulates (streamed tokens) — every other field is replaced.
  const text =
    chunk.kind === 'text' && prev?.text
      ? `${prev.text}${chunk.state.text ?? ''}`
      : chunk.state.text;
  return { ...chunk.state, text };
}

/**
 * Derive the 5-state UX phase (AD-13) from a run snapshot. The shell
 * uses this to drive `loading / empty / success / error / offline`:
 * the agent surface is a screen, and it must expose the 5 states
 * like any other (AD-13 spine rule).
 */
export function phaseFor(state: AgentRunState): RunPhase {
  switch (state.status) {
    case 'running':
    case 'awaiting-confirmation':
      return 'loading';
    case 'succeeded':
      return state.text || state.plan ? 'success' : 'empty';
    case 'failed':
      return 'error';
    case 'cancelled':
      return 'empty';
    default:
      return 'loading';
  }
}

/** A terminal chunk (done / failed / cancelled) the stream ends with. */
export function terminalChunk(
  state: AgentRunState,
  seq: number,
  at: string,
): AgentRunStateChunk {
  return { seq, agentRunId: state.agentRunId, state, kind: 'done', at };
}

/** A keep-alive chunk so the device knows the run is alive on a
 *  heavy job (AD-8: the job is persisted, the run is not stuck). */
export function heartbeatChunk(
  state: AgentRunState,
  seq: number,
  at: string,
): AgentRunStateChunk {
  return { seq, agentRunId: state.agentRunId, state, kind: 'heartbeat', at };
}
