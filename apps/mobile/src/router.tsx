/**
 * 17-page router (02 S6.1, docs/mobile/navigation-and-page-composition.md).
 *
 * Frozen route table (page matrix S2, "Routing" S6 of goal-dashboard-ui.md):
 *
 *  Primary tabs (max 5, 44-60 px bar):
 *   /home · /tasks · /learn · /progress · /agent
 *  Details open OVER the current tab (IonModal/IonSlides — 02 §6.1):
 *   /tasks/:id · /learn/:id · /progress/:id · /knowledge · /knowledge/:nodeId
 *  Additional routes:
 *   /artifacts/:id · /inbox · /settings · /goals · /goals/:id ·
 *   /goals/:id/features/:fid · /focus · /calendar
 *
 * Frozen 17-page inventory (02 S6.1):
 *   1 /home  2 /tasks  3 /tasks/:id  4 /calendar  5 /projects  6 /goals
 *   7 /goals/:id  8 /learn  9 /learn/:id  10 /knowledge  11 /knowledge/:nodeId
 *   12 /discovery  13 /progress  14 /progress/:id  15 /focus  16 /artifacts/:id
 *   17 /agent  (+ /inbox, /settings = tab-adjacent routes, * = fallback)
 *
 * Context-preserving navigation: route params + query (?goalId=X) —
 * see docs/mobile/context-preserving-navigation.md. Native back (Android
 * gesture) works on every route; a route that blocks back saves first
 * (02 §6.3, local-first auto-persist).
 */
import { createBrowserRouter } from 'react-router-dom';
import { Shell } from './shell/Shell';
import { InboxPage } from './pages/inbox';

// 17 pages. Each is a lazy boundary; the tab family renders inside Shell,
// details render over the current tab (S1 / S3 detail-over-tab rule).

import { HomePage } from './pages/home';
import { TasksPage, TaskDetailPage } from './pages/tasks';
import { CalendarPage } from './pages/calendar';
import { ProjectsPage } from './pages/projects';
import { GoalsPage, GoalDashboardPage, GoalFeatureDetailPage } from './pages/goals';
import { LearnPage, LearnDetailPage } from './pages/learn';
import { KnowledgePage, KnowledgeNodePage } from './pages/knowledge';
import { DiscoveryPage } from './pages/discovery';
import { ProgressPage, ProgressDetailPage } from './pages/progress';
import { FocusPage } from './pages/focus';
import { ArtifactPage } from './pages/artifacts';
import { AgentPage } from './pages/agent';
import { AgentConversationsPage } from './pages/agent/conversations';
import { AgentCapacitesPage } from './pages/agent/capacites';
import { AgentBibliothequePage } from './pages/agent/bibliotheque';
import { CanvasPage } from './pages/canvas';
import { SlideAscentPage } from './pages/ascent';
import { SettingsPage } from './pages/settings';
import { NotFoundPage } from './pages/not-found';
import { SkillsPage } from './pages/skills';
import { HabitsPage } from './pages/habits';
import { RoutinesPage } from './pages/routines';
import { ReviewsPage } from './pages/reviews';
import { RetroActionsPage } from './pages/retro';
import { CountdownsPage } from './pages/countdown';
import { IntegrationsPage } from './pages/integrations';
import { LoginPage } from './pages/login';
import { OnboardingPage } from './pages/onboarding';
import { FeatureGate } from './ux/feature-gate';

// Explicit annotation (TS2742): the inferred return type of
// `createBrowserRouter` pulls in @remix-run/router's Router type through
// a pnpm transitive path that is not portable from apps/mobile's node_modules
// graph; naming it here keeps the declaration emit self-contained.
export type AppRouter = ReturnType<typeof createBrowserRouter>;
export const appRouter: AppRouter = createBrowserRouter([
  {
    element: <Shell />,
    children: [
      // --- Primary tabs (5, 02 §6.1) ---
      { index: true, element: <HomePage />, path: '/' },
      { path: '/home', element: <HomePage /> },
      { path: '/tasks', element: <TasksPage /> },
      { path: '/learn', element: <LearnPage /> },
      { path: '/progress', element: <ProgressPage /> },
      { path: '/agent', element: <AgentPage /> },
      // PRD-AI-01/06 (10-08) : the Assistant module's secondary views —
      // details that open OVER the agent tab (02 §6.1 : the tab bar stays,
      // /agent/* keeps the agent tab active via ShellTabBar's prefix rule).
      { path: '/agent/conversations', element: <AgentConversationsPage /> },
      { path: '/agent/capacites', element: <AgentCapacitesPage /> },
      // PRD-AI-05 (10-08) : the library (files / media import surface).
      { path: '/agent/bibliotheque', element: <AgentBibliothequePage /> },
      // Canvas (0022): dedicated session-editing surface — blocs TipTap,
      // commentaires, bascule md ⇄ HTML. 'new' = creation mode (Task 6).
      // G-M7: gated (creation mode opens over the module home).
      { path: '/canvas/:id', element: <FeatureGate feature="canvas"><CanvasPage /></FeatureGate> },

      // --- Details over the current tab (IonModal/IonSlides, 02 §6.1) ---
      { path: '/tasks/:id', element: <TaskDetailPage /> },
      { path: '/learn/:id', element: <LearnDetailPage /> },
      { path: '/progress/:id', element: <ProgressDetailPage /> },
      // G-M7 (feature-registry S6): the 8 module routes are gated — a deep
      // link into a disabled module renders the « module désactivé » state
      // (CTA → /settings?section=modules), NEVER the 404 fallback.
      { path: '/knowledge', element: <FeatureGate feature="knowledge"><KnowledgePage /></FeatureGate> },
      { path: '/knowledge/:nodeId', element: <FeatureGate feature="knowledge"><KnowledgeNodePage /></FeatureGate> },
      { path: '/artifacts/:id', element: <ArtifactPage /> },

      // --- Tab-adjacent routes (02 §6.1 page matrix) ---
      { path: '/inbox', element: <FeatureGate feature="inbox"><InboxPage /></FeatureGate> },
      { path: '/settings', element: <SettingsPage /> },

      // --- Goals family (goal-dashboard-ui.md S6) ---
      { path: '/goals', element: <GoalsPage /> },
      { path: '/goals/:id', element: <GoalDashboardPage /> },
      { path: '/goals/:id/features/:fid', element: <GoalFeatureDetailPage /> },

      // --- Ascent (wave 3, W3-E2): the pedagogical path of the active
      //   goal. The current userId arrives at boot with the authenticated
      //   session (05 §4.8); Slide-Ascent renders the local mirror.
      { path: '/goals/:id/ascent', element: <SlideAscentPage userId="me" /> },

      // --- Focus + calendar family views (G-M7 gated) ---
      { path: '/focus', element: <FeatureGate feature="focus"><FocusPage service={null} /></FeatureGate> },
      { path: '/calendar', element: <FeatureGate feature="calendar"><CalendarPage /></FeatureGate> },

      // --- Projects family view ---
      { path: '/projects', element: <ProjectsPage /> },

      // --- Habits + routines family views (PRD-1 §4.5, 05 §4.3.5–§4.3.6) —
      //     daily check-in + gallery; routines = temporal anchors. Ungated
      //     (core productivity domain entities, like /projects). ---
      { path: '/habits', element: <HabitsPage /> },
      { path: '/routines', element: <RoutinesPage /> },

      // --- Reviews family (05 §4.5.1, WDS 06.1/06.3 — lot C v3 2026-10-08) :
      //     the period review (Jour|Semaine|Mois shared Pager) + the
      //     post-retrospective closure (retro-actions, the « Faite » state).
      //     Ungated local-first mirrors (AD-7, offline-capable). ---
      { path: '/reviews', element: <ReviewsPage /> },
      { path: '/retro', element: <RetroActionsPage /> },

      // --- Countdowns (PRD-CD-01, lot C 2026-10-08) — days-to-a-date.
      //     Ungated like /habits (local-only domain entity, no mirror
      //     wired yet → honest empty state, AD-7). ---
      { path: '/countdown', element: <CountdownsPage /> },

      // --- Discovery feed (G-M7 gated) ---
      { path: '/discovery', element: <FeatureGate feature="discovery"><DiscoveryPage /></FeatureGate> },

      // --- Skills (ADR S14, ClawHub marketplace + expert skills; G-M7 gated) ---
      { path: '/skills', element: <FeatureGate feature="skills"><SkillsPage /></FeatureGate> },

      // --- Integrations (Composio, Google Workspace default preset; G-M7 gated) ---
      { path: '/integrations', element: <FeatureGate feature="integrations"><IntegrationsPage /></FeatureGate> },

      // --- Supabase Auth entry point (P1-4, 10-07) ---
      { path: '/login', element: <LoginPage /> },
      // --- Onboarding first-run (usage personnel, 10-07 : sign-up →
      //     onboarding → app) — state cosmétique par device (ui-state). ---
      { path: '/onboarding', element: <OnboardingPage /> },

      // --- Flashcards / QCM / exercises: /learn/:id overlays (05 §4.8) ---
      // (already registered under details above; no second registration)

      // --- Fallback: deep link into a disabled feature renders a
      //   "feature disabled" state, NOT a crash / 404 (feature-registry S6).
      { path: '*', element: <NotFoundPage /> },
    ],
  },
]);

export type AppRoute = '/home' | '/tasks' | '/learn' | '/progress' | '/agent'
  | '/agent/conversations' | '/agent/capacites' | '/agent/bibliotheque'
  | '/tasks/:id' | '/learn/:id' | '/progress/:id' | '/knowledge' | '/knowledge/:nodeId'
  | '/artifacts/:id' | '/inbox' | '/settings' | '/goals' | '/goals/:id'
  | '/goals/:id/features/:fid' | '/goals/:id/ascent' | '/focus' | '/calendar' | '/projects' | '/habits' | '/routines' | '/reviews' | '/retro' | '/countdown' | '/discovery'
  | '/skills' | '/integrations' | '/login' | '/onboarding'
  | '/canvas/:id';
