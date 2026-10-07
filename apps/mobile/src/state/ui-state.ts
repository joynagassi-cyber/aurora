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
import type { ImageThemeSlug, ThemeName } from '@aurora/ui';

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
  /**
   * AD-17 layer-2 expressive theme / preset name (05 §5, G-M5 SSoT:
   * `packages/ui` catalog). Skin only — changing it = changing the JSON
   * tokens the provider injects, never the components (ui-libraries §4).
   * 'auto' = the default (aurora) theme.
   */
  auroraTheme: ThemeName | 'auto';
  /**
   * AD-17 image theme (05 §5.4-annexe, 10-07): the chosen image-theme slug,
   * or 'none' for the plain neutral canvas. Skin only — the image becomes
   * the app background + the anchor color drives the accents (see
   * `ux/image-theme.tsx`); the neutral canvas + semantic states never move.
   */
  auroraImageTheme: ImageThemeSlug | 'none';
  /** focus session active flag (drives 5 UX states + notification scope). */
  focusActive: boolean;
  /** killed = app was force-killed; re-hydrate on open (04 S6.1, G-M2). */
  killed: boolean;
  /**
   * Onboarding first-run flag (usage personnel, 10-07) : `true` une fois
   * le parcours /onboarding terminé (sign-up → onboarding → app). State
   * cosmétique par device (jamais de données entités — AD-7).
   */
  onboardingSeen: boolean;

  setActiveTab: (tab: TabId) => void;
  setTasksView: (view: UiStateStore['tasksView']) => void;
  setProgressPeriod: (period: UiStateStore['progressPeriod']) => void;
  toggleKnowledgeNode: (nodeId: string, expanded: boolean) => void;
  setTheme: (theme: UiStateStore['theme']) => void;
  setAuroraTheme: (theme: UiStateStore['auroraTheme']) => void;
  setAuroraImageTheme: (theme: UiStateStore['auroraImageTheme']) => void;
  setFocusActive: (active: boolean) => void;
  /** called at boot when the lifecycle adapter detects a return-from-kill. */
  markKilled: (killed: boolean) => void;
  setOnboardingSeen: (seen: boolean) => void;
}

export const useUiStateStore = create<UiStateStore>()(
  persist(
    (set) => ({
      activeTab: 'home',
      tasksView: 'list',
      progressPeriod: 'today',
      knowledgeExpanded: {},
      theme: 'auto',
      auroraTheme: 'auto',
      auroraImageTheme: 'none',
      focusActive: false,
      killed: false,
      onboardingSeen: false,
      setActiveTab: (activeTab) => set({ activeTab }),
      setTasksView: (tasksView) => set({ tasksView }),
      setProgressPeriod: (progressPeriod) => set({ progressPeriod }),
      toggleKnowledgeNode: (nodeId, expanded) =>
        set((s) => ({ knowledgeExpanded: { ...s.knowledgeExpanded, [nodeId]: expanded } })),
      setTheme: (theme) => set({ theme }),
      setAuroraTheme: (auroraTheme) => set({ auroraTheme }),
      setAuroraImageTheme: (auroraImageTheme) => set({ auroraImageTheme }),
      setFocusActive: (focusActive) => set({ focusActive }),
      markKilled: (killed) => set({ killed }),
      setOnboardingSeen: (onboardingSeen) => set({ onboardingSeen }),
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
        auroraTheme: s.auroraTheme,
        auroraImageTheme: s.auroraImageTheme,
        onboardingSeen: s.onboardingSeen,
      }),
    },
  ),
);
