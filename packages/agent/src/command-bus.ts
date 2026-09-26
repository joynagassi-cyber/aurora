/**
 * The Agent ↔ UI command bus (kernel S15, wave 3 task 5).
 *
 * The kernel NEVER touches React (mission §77 / AD-10 boundary). Its UI
 * effects are typed commands consumed by the single Application Command
 * Bus in the mobile shell (02 S4). This module is the typed contract
 * between the server-side kernel and the device shell:
 *
 *   Agent Action (server, AgentKernel)
 *     ↓ AgentActionEnvelope { capabilityId, action, effect, requiresConfirmation,
 *        agentRunId, status } — AD-15 SSoT (packages/domain/registries.ts)
 *   Application Command Bus (apps/mobile shell — the single bus)
 *     ↓ NavigationIntent { target, params, mode, deepLink }   → router
 *     ↓ UiStateCommand { command, payload }                   → ui-state store
 *   User-visible result (a screen opened / entity selected / artifact shown)
 *
 * Invariants (mission §17 / §62):
 *  - the command bus is the SINGLE source of UI actions: UI buttons, the
 *    command palette, agent actions, deep links and automations all
 *    resolve to the same commands — business logic is written once,
 *    never duplicated between agent and UI.
 *  - every UiStateCommand is idempotent and safe to drop on app-kill
 *    (the deep link re-creates it — context-preserving navigation).
 *  - raw DOM / React manipulation is FORBIDDEN (the router / bus is the
 *    only door; Permission Engine decisions are final, the UI renders).
 *
 * AD-12/F-09: this surface carries AgentRunState + the typed commands
 * only. No AIProvider / router / keys cross this boundary (AD-3).
 */
import type {
  AgentActionEnvelope,
  NavigationIntent,
  UiStateCommand,
} from '@aurora/domain';

/**
 * A UI effect produced by the kernel: one AgentActionEnvelope plus the
 * commands it resolves to on the bus (the "what" + "where" of the UI
 * effect — never the "how", §77).
 */
export interface AgentUiEffect {
  /** the wrapped action (AD-15 SSoT, registries.ts S11) */
  envelope: AgentActionEnvelope;
  /** the navigation, when the action opens / deep-links a screen */
  navigation?: NavigationIntent;
  /** the ui-state commands the shell store applies */
  uiCommands: UiStateCommand[];
}

/**
 * The allowed agent UI actions (mission §61/§62), as a closed set. The
 * kernel emits only these; anything else is a contract violation
 * (the shell logs it and drops it — it never executes unknown commands).
 */
export const AGENT_UI_COMMANDS = [
  'open_page',
  'select_entity',
  'filter',
  'expand_node',
  'show_artifact',
  'start_focus',
  'request_confirmation',
  'show_result',
] as const;

export type AgentUiCommand = (typeof AGENT_UI_COMMANDS)[number];

/**
 * Wrap an agent action into the typed envelope + UI effects
 * (registries.ts S11 AgentActionEnvelope, AD-15). High-risk actions
 * (destructive / important — ADR S5) carry `requiresConfirmation: true`
 * and the shell renders them behind the confirmation surface (the
 * kernel's Confirmation Engine drives the real decision, 02 S4).
 */
export function buildAgentUiEffect(input: {
  capabilityId: string;
  action: string;
  effect?: string;
  agentRunId: string;
  /** the action's risk class (Permission Engine, kernel §5) */
  risk?: 'low' | 'medium' | 'high';
  status?: AgentActionEnvelope['status'];
  /** the destination screen, when the action navigates */
  navigation?: NavigationIntent;
  /** the ui-state commands to apply (idempotent, §62) */
  uiCommands?: UiStateCommand[];
}): AgentUiEffect {
  const requiresConfirmation = input.risk === 'high';
  const envelope: AgentActionEnvelope = {
    capabilityId: input.capabilityId,
    action: input.action,
    effect: input.effect,
    requiresConfirmation,
    agentRunId: input.agentRunId,
    status: input.status ?? (requiresConfirmation ? 'proposed' : 'executed'),
  };
  return {
    envelope,
    navigation: input.navigation,
    uiCommands: input.uiCommands ?? [],
  };
}

/**
 * A ui-state command the shell applies (02 S4). The closed set keeps
 * the bus safe: each command is idempotent (re-applying = no-op) and
 * safe to drop on app-kill (the deep link re-creates it).
 */
export function uiCommand(cmd: AgentUiCommand, payload?: Record<string, unknown>): UiStateCommand {
  return { command: cmd, payload };
}

/**
 * The command bus consumer contract (the shell implements it; the
 * kernel emits). `dispatch` is the single door — raw React / DOM
 * access from the kernel is forbidden (§77 / AD-10).
 */
export interface CommandBus {
  dispatch(effect: AgentUiEffect): void;
}

/**
 * The streaming surface (02 S4): the device sees ONLY AgentRunState
 * chunks. The kernel's KernelEvent stream (kernel.ts) is mapped to
 * AgentRunState snapshots by fn-agent-run (task 6); this type is the
 * device-side consumer shape (AD-12: the device never sees the
 * provider / router / keys behind it).
 */
export type { NavigationIntent, UiStateCommand, AgentActionEnvelope };

/**
 * A pending action the shell is rendering for confirmation (ADR S5).
 * The shell surfaces this; the user's decision goes back to the
 * kernel's Confirmation Engine (the device does NOT decide — it
 * renders, AD-12).
 */
export interface ConfirmationSurface {
  /** the envelope being confirmed */
  envelope: AgentActionEnvelope;
  /** the blocking UI surface (02 S4: the run is 'awaiting-confirmation') */
  blocking: boolean;
}

export function confirmationSurfaceFor(effect: AgentUiEffect): ConfirmationSurface | undefined {
  if (!effect.envelope.requiresConfirmation) return undefined;
  return { envelope: effect.envelope, blocking: true };
}
