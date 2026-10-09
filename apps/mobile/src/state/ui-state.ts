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
  /**
   * tasks view mode (G-L5 + PRD-1 2026-10 : `today` = la vue quotidienne
   * « Aujourd'hui » — en retard / aujourd'hui / habitudes / terminées).
   */
  tasksView: 'today' | 'list' | 'eisenhower' | 'calendar';
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
  /**
   * Agent research setting (PRD-AI-06 « Capacités », 10-08) : the user's
   * web-search preference, SHARED between the /agent composer chips and
   * the /agent/capacites screen (cosmetic user preference, AD-7 — it is
   * SENT with each request via `taskProfile.researchMode`, never a
   * domain-entity cache).
   */
  agentResearchMode: 'off' | 'standard' | 'deep';
  /**
   * Per-page active in-page view (C5 2026-10-08) : the in-page Segmented
   * control + the horizontal glide are BOTH bound to this one T4
   * cosmetic-persistent key — the return always finds the same view
   * (05 §3.4 l.743-746, non-surprise). Never entity data (AD-7).
   */
  projectsView: 'kanban' | 'rapports' | 'gantt' | 'timeline' | 'list';
  /** The hidden side-panel revealed by the horizontal glide (C5) : open/closed. */
  panelOpen: boolean;
  /** C5 : « /settings?section=projects » — the global sort + kanban column order,
   *  the last item of the ⋮ menu routes here (le réglage global, retrouvable
   *  depuis chaque page). Cosmetic (AD-7).
   *  NOTE : `projectsColumnOrder` est LE SEUL réglage « Kanban » persistant
   *  (le tri par l'ordre des colonnes du board, 05 §4.3.1 l.1438) ; le TRI
   *  de la Liste vit dans `projectsSort` (05 §4.3.1 l.1436-1437) — les deux
   *  sont des réglages globaux distincts, jamais mélangés (05 §3.5 l.851 :
   *  « les options sont persistantes par page, pas partagées »). */
  projectsSort: 'date' | 'progression' | 'priorite';
  projectsColumnOrder: 'statut' | 'echeance' | 'priorite';
  /**
   * Tri des tâches (C5.4 propagation, 10-08) : `echeance` (la date
   * d'échéance, l'ordre le plus courant) · `priorite` (la priorité,
   * l'ordre le plus « important ») · `titre` (alphabétique). T4
   * cosmetic-persistent (le retour retrouve le même tri, 05 §3.4
   * l.743-746). Jamais de données entités (AD-7).
   */
  tasksSort: 'echeance' | 'priorite' | 'titre';

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
  setAgentResearchMode: (mode: UiStateStore['agentResearchMode']) => void;
  /** C5 2026-10-08 : switch the in-page view (pager + glide share this). */
  setProjectsView: (view: UiStateStore['projectsView']) => void;
  /** C5 : reveal / hide the hidden side panel. */
  setPanelOpen: (open: boolean) => void;
  /** C5 : the global « /settings?section=projects » values (menu ⋮ last item). */
  setProjectsSort: (sort: UiStateStore['projectsSort']) => void;
  setProjectsColumnOrder: (order: UiStateStore['projectsColumnOrder']) => void;
  /** C5.4 : the global « /settings?section=tasks » sort value (menu ⋮). */
  setTasksSort: (sort: UiStateStore['tasksSort']) => void;
}

export const useUiStateStore = create<UiStateStore>()(
  persist(
    (set) => ({
      activeTab: 'home',
      // PRD-1 (2026-10) : la vue quotidienne est la vue par défaut du
      // module Tâches (« Aujourd'hui » avant « Liste »).
      tasksView: 'today',
      progressPeriod: 'today',
      knowledgeExpanded: {},
      theme: 'auto',
      auroraTheme: 'auto',
      auroraImageTheme: 'none',
      focusActive: false,
      killed: false,
      onboardingSeen: false,
      // PRD-AI-06 (10-08) : préférence de recherche web par défaut « off »
      // (l'agent ne cherche sur le web que si l'utilisateur l'autorise).
      agentResearchMode: 'off',
      projectsView: 'kanban',
      panelOpen: false,
      projectsSort: 'date',
      projectsColumnOrder: 'statut',
      // C5.4 (10-08) : le tri par défaut des tâches = l'échéance (l'ordre
      // le plus courant, le retour retrouve le même tri).
      tasksSort: 'echeance',
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
      setAgentResearchMode: (agentResearchMode) => set({ agentResearchMode }),
      setProjectsView: (projectsView) => set({ projectsView }),
      setPanelOpen: (panelOpen) => set({ panelOpen }),
      setProjectsSort: (projectsSort) => set({ projectsSort }),
      setProjectsColumnOrder: (projectsColumnOrder) => set({ projectsColumnOrder }),
      setTasksSort: (tasksSort) => set({ tasksSort }),
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
        agentResearchMode: s.agentResearchMode,
        projectsView: s.projectsView,
        panelOpen: s.panelOpen,
        projectsSort: s.projectsSort,
        projectsColumnOrder: s.projectsColumnOrder,
        tasksSort: s.tasksSort,
      }),
    },
  ),
);
