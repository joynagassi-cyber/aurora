/**
 * Agent Command Bus — the device-side single bus (02 §4, kernel S15).
 *
 * THE kernel never touches React (mission §77 / AD-10): its UI effects
 * cross the device as typed commands (`UiStateCommand` + `NavigationIntent`,
 * SSoT @aurora/domain re-exported by @aurora/agent). This module is where
 * they land: one executor, every UI action (buttons, agent actions, deep
 * links, automations) resolves to the SAME commands (mission §17 —
 * business logic written once, §62).
 *
 * Invariants honored here:
 *  - closed command set: unknown commands are DROPPED + logged (the shell
 *    never executes an untyped effect, 02 §4);
 *  - idempotency: re-applying a command is a no-op (ui-state store), so a
 *    dropped-then-recreated deep link converges to the same state;
 *  - navigation = router only (details open over the current tab, 02 §6.1 —
 *    `replace` mode lands on the destination without a back-stack growth).
 *
 * AD-7: this is UI STATE wiring, not data wiring — no entity reads/writes
 * happen here; the commands describe the projection the shell applies.
 */
import type { NavigateFunction } from 'react-router-dom';
import { AGENT_UI_COMMANDS, type AgentUiEffect, type NavigationIntent, type UiStateCommand } from '@aurora/agent';
import type { TabId, UiStateStore } from '../state/ui-state';

export type NavFn = NavigateFunction;

export interface UiCommander {
  setActiveTab: (tab: TabId) => void;
  setTasksView: (view: UiStateStore['tasksView']) => void;
  setProgressPeriod: (period: UiStateStore['progressPeriod']) => void;
  toggleKnowledgeNode: (nodeId: string, expanded: boolean) => void;
  setFocusActive: (active: boolean) => void;
}

// ---- global effect channel (the bus surface the shell subscribes to) ----
//
// Producers (the agent page, deep links, automations, diagnostics) call
// `emitAgentEffect`; the mounted `AgentBus` consumes it and projects it
// onto router + ui-state. The global channel keeps the "one bus"
// invariant (02 §4): the executor lives in ONE place, so commands are
// applied exactly once.

type EffectHandler = (effect: AgentUiEffect) => void;
const effectHandlers = new Set<EffectHandler>();

/** Subscribe to agent UI effects (the CommandBus consumer side, 02 §4). */
export function onAgentEffect(handler: EffectHandler): () => void {
  effectHandlers.add(handler);
  return () => {
    effectHandlers.delete(handler);
  };
}

/** Dispatch one effect to every mounted consumer (the single door, §62). */
export function emitAgentEffect(effect: AgentUiEffect): void {
  for (const h of [...effectHandlers]) h(effect);
}

/** The known command set (re-checks the closed set at runtime, §62). */
const KNOWN = new Set<string>(AGENT_UI_COMMANDS);

const TABS: ReadonlySet<string> = new Set(['home', 'tasks', 'learn', 'progress', 'agent']);

/** A NavigationIntent → app path (target = route id, params → path values). */
export function targetToPath(target: string, params?: Record<string, unknown>): string {
  // Intents name concrete screens (target "goal" + params { id } →
  // /goals/:id). Literal paths pass through; unknown screens land on
  // the * fallback ("feature disabled" state, never a crash — 02 §6).
  if (target.startsWith('/')) return target;
  const p = params ?? {};
  switch (target) {
    case 'artifact':
      return p.id != null ? `/artifacts/${String(p.id)}` : '/';
    case 'knowledge-node':
      return p.nodeId != null ? `/knowledge/${String(p.nodeId)}` : '/knowledge';
    case 'goal':
      return p.id != null ? `/goals/${String(p.id)}` : '/goals';
    case 'task':
      return p.id != null ? `/tasks/${String(p.id)}` : '/tasks';
    case 'focus':
      return '/focus';
    case 'calendar':
      return '/calendar';
    case 'agent':
      return '/agent';
    default:
      return `/${target.replace(/[^a-z0-9/-]/gi, '')}`;
  }
}

/**
 * Execute one UI command against the shell (router + ui-state store).
 * Pure projection — the owning modules apply the domain mutations
 * (AD-7 single writer); this only moves the camera / state the user sees.
 * Returns true when the command was applied (idempotent).
 */
export function applyUiCommand(cmd: UiStateCommand, nav: NavFn, ui: UiCommander): boolean {
  const { command, payload = {} } = cmd;
  if (!KNOWN.has(command)) {
    console.warn('[agent-bus] unknown ui command dropped:', command);
    return false;
  }
  switch (command) {
    case 'open_page': {
      const target = String(payload.target ?? 'home');
      const path = targetToPath(target, payload);
      const replace = payload.mode === 'replace';
      nav(path, { replace });
      if (TABS.has(target)) ui.setActiveTab(target as TabId);
      return true;
    }
    case 'select_entity': {
      // Selection = navigation to the entity detail (details over the
      // current tab, 02 §6.1); the entity itself is read by the page.
      const kind = String(payload.kind ?? '');
      const map: Record<string, string> = { goal: 'goal', task: 'task', node: 'knowledge-node' };
      return applyUiCommand(
        { command: 'open_page', payload: { target: map[kind] ?? kind, id: payload.id, mode: 'replace', nodeId: payload.nodeId } },
        nav,
        ui,
      );
    }
    case 'filter': {
      // Per-page view modes are ui-state (02 §6.1 T4); a filter payload is
      // a view-mode switch when it names one, otherwise a no-op projection
      // (the page owns the full filter surface — AD-7, no data here).
      const view = String(payload.view ?? '');
      if (view === 'today' || view === 'list' || view === 'eisenhower' || view === 'calendar') {
        ui.setTasksView(view);
      }
      const period = String(payload.period ?? '');
      if (period === 'today' || period === 'week' || period === 'month' || period === 'trajectory') {
        ui.setProgressPeriod(period);
      }
      return true;
    }
    case 'expand_node': {
      const nodeId = String(payload.nodeId ?? payload.id ?? '');
      if (nodeId) ui.toggleKnowledgeNode(nodeId, payload.collapsed !== true);
      return true;
    }
    case 'show_artifact': {
      return applyUiCommand(
        { command: 'open_page', payload: { target: 'artifact', id: payload.id, mode: 'replace' } },
        nav,
        ui,
      );
    }
    case 'start_focus': {
      ui.setFocusActive(true);
      return applyUiCommand({ command: 'open_page', payload: { target: 'focus', mode: 'replace' } }, nav, ui);
    }
    case 'request_confirmation':
    case 'show_result': {
      // These surface in the /agent transcript (the Confirmation Engine
      // blocks the run, the device renders — AD-12: the user decides, the
      // kernel never forces). The bus only guarantees the surface is visible.
      return applyUiCommand({ command: 'open_page', payload: { target: 'agent' } }, nav, ui);
    }
    default:
      return false;
  }
}

/** Project one agent UI effect: navigation first, then the ui-state commands. */
export function applyAgentEffect(effect: AgentUiEffect, nav: NavFn, ui: UiCommander): void {
  const n = effect.navigation;
  if (n) {
    applyUiCommand(
      {
        command: 'open_page',
        payload: { target: n.target, mode: n.mode, ...(n.params ?? {}) },
      },
      nav,
      ui,
    );
  }
  for (const c of effect.uiCommands) applyUiCommand(c, nav, ui);
}

/**
 * Subscribe the shell executor to the global effect channel (02 §4).
 * Call it ONCE under the router (in `<AgentBus />`, apps/mobile) so
 * `nav` / the ui-state store are in scope. Returns an unsubscribe.
 */
export function mountAgentCommandBus(nav: NavFn, ui: UiCommander): () => void {
  return onAgentEffect((effect) => applyAgentEffect(effect, nav, ui));
}

/** Convenience re-exports for producers (deep links, the agent page). */
export type { AgentUiEffect, NavigationIntent, UiStateCommand };
