# SESSION 2 — WAVE 1 : UI + DATA (3 sous-agents paralleles)

Lance 3 sous-agents en parallele. La vague 0 est terminee
(packages/domain, CI, Supabase, R2, PowerSync existent).

## Contexte commun
- Projet : C:\Users\joyda\dyad-apps\aurora-2
- La vague 0 est mergee sur main
- UI premium : docs/ui-libraries.md (SHADCN/U + FULLCALENDAR + AG GRID + FRAMER MOTION)
- Design : docs/design-system/overview.md + 05-design-system.md
- Regle : PAS ion-calendar, PAS ion-list data tables, PAS ion-item forms

---

## SOUS-AGENT 1 : APOLLO (Design System + Premium UI)

Lis :
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md
- docs/design-system/overview.md
- docs/architecture/goal-dashboard-ui.md
- docs/ui-libraries.md (TOUT, c'est ta reference)
- docs/mobile/navigation-and-page-composition.md
- docs/focus-mode/spec.md (S6 states)

Taches :
1. packages/ui/src/themes/ : 10 themes JSON + 3 presets
   (Light #F8FAFC, Dark #0A0E1A, G-H2 resolved)
   G-M5 : ChartSpec shape publiee
2. shadcn/ui init dans packages/ui
   npx shadcn@latest init
   npx shadcn@latest add button card dialog drawer input textarea select
     dropdown-menu checkbox radio-group switch slider table tabs accordion
     tooltip popover command toast toaster alert alert-dialog badge avatar
     progress skeleton sidebar breadcrumb pagination scroll-area separator
     label menubar context-menu hover-card kbd form
3. Premium additions :
   npx shadcn@latest add @aceternity/wobble-card
   npx shadcn@latest add @aceternity/interactive-card
   npx shadcn@latest add @aceternity/beam
   npx shadcn@latest add @magicui/marquee
   npx shadcn@latest add @magicui/number-tick
   npx shadcn@latest add @magicui/shine-effect
   npx shadcn@latest add @magicui/blurred-spotlight
4. 9 composants data (05 S3.6 DEF) :
   SemanticTreeRenderer (React Flow + Dagre, lazy, 30fps)
   InfographicRenderer (AntV Infographic, hybrid SVG + <image>)
   DataVisualizationRenderer (AntV G2, ChartSpec)
   MathRenderer (KaTeX, onError = styled raw source)
   AnimationController (Framer Motion, G-M1: AnimationSlot)
   + 4 DS data components
5. resolveToken + <AuroraThemeProvider>
6. FullCalendar integration (PAS ion-calendar)
7. AG Grid Community (data tables, virtualized)
8. 49 theme x screen mockups (G-L2)
9. 30fps test (1000-node tree, Pixel 4a spec)

Commits :
- "wave1/apollo: themes JSON (10 + 3 presets) + resolveToken + provider"
- "wave1/apollo: shadcn/ui init + 30+ composants"
- "wave1/apollo: premium effects (Aceternity + Magic UI)"
- "wave1/apollo: 9 renderer contracts (AD-10) + 4 DS components"
- "wave1/apollo: FullCalendar + AG Grid + 30fps test"
- "wave1/apollo: 49 theme x screen mockups (G-L2)"

---

## SOUS-AGENT 2 : ATHENA (Local-First Data + PowerSync)

Lis :
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/03-sync.md
- docs/data/local-first.md
- docs/architecture/event-reconciliation-and-router.md (S1, battery)
- docs/architecture/contract-catalog.md (S4, local data)
- .env.local (POWERSYNC_URL, PS_ADMIN_TOKEN)

Taches :
1. LocalQueryRepository / LocalCommandRepository (03 S3.1)
2. PowerSync schema (03 S4.2, toutes les tables mirrors)
3. SQLite local (Capacitor Filesystem)
4. SyncStatus (pending, syncing, idle, conflict)
5. Conflict rule : server-wins + updated_at (03 S5.1)
6. OR-Set CRDT (03 S5.3, SSoT packages/domain)
7. Upsync queue (offline -> online, idempotent)
8. React Query bridge (03 S5.8)
9. Local notifications (Capacitor, 04 S3.4)
10. Tests : single-writer, CRDT merge, server-wins, view-join, re-sync

Commits :
- "wave1/athena: LocalQuery/CommandRepository (03 S3.1)"
- "wave1/athena: PowerSync schema + SQLite"
- "wave1/athena: SyncStatus + CRDT + upsync queue"
- "wave1/athena: React Query bridge (03 S5.8)"
- "wave1/athena: local notifications + tests"

---

## SOUS-AGENT 3 : PROMETHEUS (Mobile Shell + Capacitor + Routing)

Lis :
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/02-frontend.md
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/04-mobile.md
- docs/mobile/navigation-and-page-composition.md (17 pages)
- docs/mobile/context-preserving-navigation.md
- docs/frontend/feature-registry.md (G-M7)
- docs/ui-libraries.md (S2, S5, S8)

Taches :
1. apps/mobile : Ionic React + Capacitor shell
2. Zustand (ui-state ONLY, AD-7)
3. React Query (data reads from local repos)
4. Routing (02 S6.1) : 17 pages, context-preserving
5. 5 UX states + killed (G-M2)
6. Home (AD-14) : 7 slots + GoalProject cards
7. Feature Registry (G-M7)
8. FullCalendar (PAS ion-calendar)
9. shadcn components (dialog, command, toast)
10. OneSignal + local notifications (split rule, 04 S3.4)
11. AppLifecycleAdapter + NetworkStatusAdapter

Commits :
- "wave1/prometheus: Ionic + Capacitor shell"
- "wave1/prometheus: Zustand + React Query + routing (17 pages)"
- "wave1/prometheus: 5 UX states + killed + Home AD-14"
- "wave1/prometheus: Feature Registry + premium components"
- "wave1/prometheus: OneSignal + local + lifecycle adapters"

---

## Quand les 3 sont finis
- packages/ui compile + 30fps test passe
- apps/mobile build + route a toutes les 17 pages
- PowerSync sync + offline re-sync test passe
- main buildable
