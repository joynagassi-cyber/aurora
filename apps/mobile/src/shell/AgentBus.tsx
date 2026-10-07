/**
 * Agent Command Bus — mount point (02 §4, kernel S15).
 *
 * Mounted ONCE at the router root (`<Shell />` → under `<RouterProvider>`,
 * so `useNavigate` works). Subscribes the shell executor (router +
 * ui-state store) to the global effect channel (`lib/agent-bus`): any
 * producer — the agent page, deep links, automations — dispatches an
 * `AgentUiEffect` through the same single door (mission §17/§62).
 */
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUiStateStore } from '../state/ui-state';
import { mountAgentCommandBus, type NavFn, type UiCommander } from '../lib/agent-bus';

export function AgentBus() {
  const nav = useNavigate();
  const ui = useUiStateStore();

  const uiSlice: UiCommander = {
    setActiveTab: ui.setActiveTab,
    setTasksView: ui.setTasksView,
    setProgressPeriod: ui.setProgressPeriod,
    toggleKnowledgeNode: ui.toggleKnowledgeNode,
    setFocusActive: ui.setFocusActive,
  };

  const navRef = nav as NavFn;
  useEffect(
    () => mountAgentCommandBus(navRef, uiSlice),
    [navRef, ui.setActiveTab, ui.setTasksView, ui.setProgressPeriod, ui.toggleKnowledgeNode, ui.setFocusActive],
  );
  return null;
}
