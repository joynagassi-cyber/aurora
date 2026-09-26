/**
 * Command bus — AgentActionEnvelope + NavigationIntent + UiStateCommand
 * (wave 3 task 6, kernel.md S15).
 *
 * The kernel drives the UI through TYPED COMMANDS, never React
 * (mission S77: "the agent drives the UI through commands, not
 * components"). The three types are SSoT in packages/domain
 * (registries.ts) — this file re-exports them (AD-15: consume, never
 * re-declare) and adds the BUS: the single application command bus
 * (02 S4) that UI buttons, the command palette, agent actions, deep
 * links and automations all resolve to (mission S17: business logic
 * written once).
 *
 * Data-only, no React: consumers are the apps/mobile shell store
 * (Zustand ui-state) + the Frontend Router. The bus is an in-memory
 * pub/sub the shell owns; each command is idempotent and safe to
 * drop on app-kill (the deep link re-creates it, 02 S15).
 */

// AD-15 SSoT re-exports — the types live in packages/domain; the
// kernel/agent packages CONSUME them, they never re-declare.
export type {
  AgentActionEnvelope,
  NavigationIntent,
  UiStateCommand,
} from '@aurora/domain';

import type { AgentActionEnvelope, NavigationIntent, UiStateCommand } from '@aurora/domain';

/**
 * The union of every command that flows over the application bus.
 * `UiStateCommand` carries the UI-state cases (select / filter /
 * expand-node / show-artifact / start-focus — 02 S15); `NavigationIntent`
 * carries the router cases (open / deep-link); the confirmation
 * decision closes the kernel's blocking surface (kernel S12).
 */
export type AppCommand =
  | { kind: 'ui-state'; command: UiStateCommand }
  | { kind: 'navigate'; intent: NavigationIntent }
  | {
      kind: 'confirm';
      agentRunId: string;
      stepId: string;
      answer: 'confirmed' | 'rejected';
      at: string;
    }
  | {
      kind: 'cancel-run';
      agentRunId: string;
      /** the pending plan to persist for resume (AD-8 recovery) */
      pendingPlan?: unknown;
      at: string;
    };

/** A listener for app commands. Returns a dispose fn. */
export type CommandListener = (cmd: AppCommand) => void;

/**
 * `CommandBus` — the single application command bus (02 S4).
 *
 * - `publish(cmd)` — fan out to all subscribers (UI buttons, command
 *   palette, agent, deep links, automations all publish here).
 * - `subscribe(fn)` — the shell store / router listen. Each command
 *   is idempotent; a dropped command on app-kill is re-created by
 *   the deep link (context-preserving navigation, 02 S15).
 *
 * The kernel PUBLISHES commands (action, navigation, ui-state); the
 * shell SUBSCRIBES and applies them to its Zustand ui-state + router.
 * The kernel never touches a React component (AD-10 boundary culture:
 * the bus is the only door).
 */
export class CommandBus {
  private listeners: CommandListener[] = [];
  /** publish log (bounded) — for observability + tests (AD-16d). */
  private log: AppCommand[] = [];
  private bound: number;

  constructor(bound = 500) {
    this.bound = bound;
  }

  /** Publish a command to every subscriber. Idempotent; no-op when no
   *  subscribers (the deep link recreates on reconnect, 02 S15). */
  publish(cmd: AppCommand): void {
    this.log.push(cmd);
    if (this.log.length > this.bound) this.log.shift();
    for (const l of this.listeners) {
      try {
        l(cmd);
      } catch {
        // a misbehaving subscriber must not sink the bus (AD-8:
        // observers are decoupled from producers)
      }
    }
  }

  /** Subscribe a listener; returns an unsubscribe fn. */
  subscribe(fn: CommandListener): () => void {
    this.listeners.push(fn);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== fn);
    };
  }

  /** The bounded publish log (observability). */
  history(): readonly AppCommand[] {
    return this.log;
  }
}

/**
 * Build an `AgentActionEnvelope` from a kernel action (kernel S15).
 * The envelope is what the device renders: the capability, the
 * declared effect, and whether confirmation gates it (high risk).
 * The kernel decides; the UI only renders the decision (AD-10).
 */
export function buildActionEnvelope(input: {
  capabilityId: string;
  action: string;
  agentRunId: string;
  effect?: string;
  risk: 'low' | 'medium' | 'high';
  status?: AgentActionEnvelope['status'];
}): AgentActionEnvelope {
  return {
    capabilityId: input.capabilityId,
    action: input.action,
    effect: input.effect,
    requiresConfirmation: input.risk === 'high',
    agentRunId: input.agentRunId,
    status: input.status ?? 'proposed',
  };
}

/**
 * A confirmation decision coming back over the bus (the kernel's
 * Confirmation Engine resolves it; the run resumes or safe-cancels,
 * ADR S5). This is the typed shape the shell's confirm button emits.
 */
export function confirmationCommand(
  agentRunId: string,
  stepId: string,
  answer: 'confirmed' | 'rejected',
  now: () => string,
): AppCommand {
  return { kind: 'confirm', agentRunId, stepId, answer, at: now() };
}

/** An agent-driven navigation (deep link via the bus, 02 S6). */
export function navigationCommand(intent: NavigationIntent): AppCommand {
  return { kind: 'navigate', intent };
}

/** An agent-driven ui-state mutation (select / filter / expand / …). */
export function uiStateCommand(command: UiStateCommand): AppCommand {
  return { kind: 'ui-state', command };
}
