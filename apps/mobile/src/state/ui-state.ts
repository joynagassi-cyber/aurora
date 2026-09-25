/**
 * ui-state store (AD-7: ZUSTAND = UI STATE ONLY, never data state).
 *
 * What lives here: cosmetic / navigation / interaction state —
 *   - active tab (02 §6.1 max 5 tabs)
 *   - per-view modes (tasks filter/view mode, progress period selector,
 *     knowledge tree expansion — docs/mobile/navigation-and-page-composition.md)
 *   - theme override (AD-17: theme = skin only; the SSoT is packages/ui)
 *   - focus session flag (drives the 5 UX-state "killed" + notification
 *     suppression scope, focus-mode spec §8)
 *
 * What does NOT live here (AD-7): any entity data — goals, tasks, courses,
 * progress mirrors. Those are read via the React Query bridge over
 * `@aurora/data` local repositories.
 *
 * Persisted (ui-state only, cosmetic — 02 §3.2). The persist key is
 * namespaced so it never collides with the local data store (SQLite).
 */
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

export type TabId = 'home' | 'tasks' | 'learn' | 'progress' | 'agent';

export interface UiStateStore {
  /** active primary tab (02 §6.1: max 5, 44-60 px tab bar). */
  activeTab: TabId;
  /** tasks view mode (list / eisenhower / calendar family, G-L5). */
  tasksView: 'list' | 'eisenhower' | 'calendar';
  /** progress period selector (02 S6.1 / page matrix "PERIOD"). */
  progressPeriod: 'today' | 'week' | 'month' | 'trajectory';
  /** knowledge tree expansion + zoom (page matrix "tree expansion state"). */
  knowledgeExpanded: Record<string, boolean>;
  /** AD-17 theme override (skin only, 05 §2.1.3). */
  theme: 'auto' | 'light' | 'dark';
  /** focus session active flag (drives 5 UX states + notification scope). */
  focusActive: boolean;
  /** killed = app was force-killed; re-hydrate on open (04 S6.1, G-M2). */
  killed: boolean;

  setActiveTab: (tab: TabId) => void;
  setTasksView: (view: UiStateStore['tasksView']) => void;
  setProgressPeriod: (period: UiStateStore['progressPeriod']) => void;
  toggleKnowledgeNode: (nodeId: string, expanded: boolean) => void;
  setTheme: (theme: UiStateStore['theme']) => void;
  setFocusActive: (active: boolean) => void;
  /** called at boot when the lifecycle adapter detects a return-from-kill. */
  markKilled: (killed: boolean) => void;
}

export const useUiStateStore = create<UiStateStore>()(
  persist(
    (set) => ({
      activeTab: 'home',
      tasksView: 'list',
      progressPeriod: 'today',
      knowledgeExpanded: {},
      theme: 'auto',
      focusActive: false,
      killed: false,
      setActiveTab: (activeTab) => set({ activeTab }),
      setTasksView: (tasksView) => set({ tasksView }),
      setProgressPeriod: (progressPeriod) => set({ progressPeriod }),
      toggleKnowledgeNode: (nodeId, expanded) =>
        set((s) => ({ knowledgeExpanded: { ...s.knowledgeExpanded, [nodeId]: expanded } })),
      setTheme: (theme) => set({ theme }),
      setFocusActive: (focusActive) => set({ focusActive }),
      markKilled: (killed) => set({ killed }),
    }),
    {
      // ui-state only — never entity data (AD-7). localStorage bridge for
      // Capacitor webview; the SQLite mirror stays owned by @aurora/data.
      name: 'aurora.ui-state',
      storage: createJSONStorage(() => localStorage),
      partialize: (s) => ({
        activeTab: s.activeTab,
        tasksView: s.tasksView,
        progressPeriod: s.progressPeriod,
        knowledgeExpanded: s.knowledgeExpanded,
        theme: s.theme,
      }),
    },
  ),
);
