# 01 — Map agent: read-only frontend inventory (apps/mobile)

Scope: `C:\Users\joyda\dyad-apps\aurora-2\apps\mobile\src/**` (+ `package.json` for the AD-1 boundary check).
Method: every claim below cites a concrete file + line range. No findings are ranked; nothing is proposed.

## Structural notes (global)

- **Router paradigm — single:** the app uses `react-router-dom` v6 data router exclusively.
  - `src/router.tsx:25` `import { createBrowserRouter } from 'react-router-dom';`
  - `src/router.tsx:55` `export const appRouter: AppRouter = createBrowserRouter([...])`
  - `src/app.tsx:33` `<RouterProvider router={appRouter} />`
  - **`IonReactRouter` / `IonRoute` / `IonRouter` are NOT used anywhere in `src/**`** (grep `IonReactRouter|IonRoute\b|IonRouter` = 0 matches in code). Two router paradigms are NOT mixed.
  - Note (neutral): `src/shell/Shell.tsx:21` renders `<IonRouterOutlet />` **in addition to** the react-router `<Outlet />` (`Shell.tsx:22`) inside the same `IonContent`. `IonRouterOutlet` belongs to the Ionic router paradigm; here it sits next to the react-router outlet. This is an unused/redundant node, not a second router instance — no `IonReactRouter` wraps the tree.
- **No `IonPage` anywhere:** 0 occurrences in `src/**`. Pages are bare `IonHeader` + `IonContent` fragments mounted inside the shared `Shell` (`src/shell/Shell.tsx:12-26`), which provides the `IonApp` + `IonMenu` + root `IonContent` chrome. This is a documented app-level composition choice, not a per-page defect.
- **No `IonModal`, `IonAlert`, `IonToast`, `IonLoading` anywhere in `src/**`** (grep = 0 matches in code; the only "IonModal/IonSlides" hits are in comments: `src/shell/Shell.tsx:7`, `src/router.tsx:8,67`). Overlays are:
  - custom `role="dialog"` divs: `src/pages/agent/index.tsx:331` (model picker), `src/pages/agent/index.tsx:405` (+ sheet)
  - shadcn/Radix `Dialog`: `src/components/ui/dialog.tsx:36-54` (`DialogContent` via `@radix-ui/react-dialog`)
  - shadcn/Radix `Toast`: `src/components/ui/toast.tsx:17-48` (`@radix-ui/react-toast`)
  - token-styled custom BottomSheet: `src/ux/floating.tsx:75-106` (`role="dialog" aria-modal="true"` at line 79)
  - Radix `Dialog`-based command palette: `src/components/ui/command.tsx:41-77`
- **Ionic components actually rendered:** `IonApp`, `IonMenu`, `IonContent`, `IonHeader`, `IonTitle`, `IonRouterOutlet` (Shell: `src/shell/Shell.tsx:9,14-23`), `IonButton`/`IonButtons` (Focus: `src/pages/focus/index.tsx:16,130-134,301-314`), `IonItem`/`IonLabel` (Home card: `src/pages/home/goal-card.tsx:12,40-49`).
- **`@capacitor/*` absent from `src/**`** — AD-1 boundary holds. `package.json:30-31` declares `@capacitor/core ^7.6.9` + `@capacitor/android ^7.6.9`; no file under `src/` imports `@capacitor/*` (grep `@capacitor/` in `src/**` = 0 matches). The native boundary is `@aurora/platform` (`package.json:28` `"@aurora/platform": "workspace:*"`), referenced in doc comments only: `src/main.tsx:20`, `src/hooks/use-online.ts:4`, `src/hooks/use-killed.ts:14` (neither hook imports the platform package in code).
- **Design tokens:** `src/styles/tokens.css` defines the `--aurora-*` baseline (lines 20-79). All CSS colors in `src/styles/*.css` resolve to `var(--aurora-*)` or are token-file definitions. Hex literals appear only in `tokens.css` (the definition site, lines 21-79), in a `var(..., #b45309)` fallback in `styles/agent.css:126,138`, and in scrim `rgba(0,0,0,0.4)` / `rgba(15,23,42,0.4)` in `styles/agent.css:241,390` and `styles/floating.css:43,97`. **No `.tsx` file contains a hardcoded hex/rgba color literal** (grep `#hex|rgba?(` over `src/**/*.tsx` = 0 color matches; the only `stroke=` is `stroke="currentColor"` at `src/pages/goals/dashboard.tsx:261`, which is not a literal).

---

## 1. Routed pages table

All 21 route entries in `src/router.tsx:55-111` resolve to files that exist (see §5 for the cross-check). Line counts from `wc -l` on 2026-10-04.

"Router API" = page-level `react-router-dom` hooks imported: `useNavigate` / `useParams` / `useSearchParams` / `Link` / `useLocation` (or "—" if none). All 17 page exports + 4 shared exports live in the `src/pages/**` files listed; each is a `IonHeader`+`IonContent` fragment (no `IonPage` — global note above).

| # | Route | File (component) | Lines | IonPage? | Router API used | Overlays (line refs) | Form fields (line refs) | 4-states coverage (loading / success / error / empty — exact JSX producing each; "absent" = not visibly implemented) |
|---|-------|-------------------|-------|----------|-----------------|----------------------|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `/`, `/home` | `src/pages/home/index.tsx` (`HomePage`, l.70-174) | 174 | no | `useNavigate` in child `src/pages/home/goal-card.tsx:13,45` (navigate to `/goals/:id`) | none on page; child card opens `/goals/:id` | none on page (data-only slots); card is a link, not a field | **loading**: `home/index.tsx:85-86` `isPending ? ({ status: 'loading' } as const)` (goals) + `l.95-96` (tasks); **success**: `l.87-89` `goals.length === 0 ? … : ({ status: 'success', data: goals } as const)` via `<Slot>`/`UxStates` `l.122`; **error**: `l.83-84` `isError ? ({ status: 'error', error: { code: 'goal/load_failed' … } }` + `l.97-98` task variant; **empty**: `l.87-88` `goals.length === 0 ? ({ status: 'empty' })` + `l.99-100` task variant + static empty slots `l.103` `const emptyState = { status: 'empty' as const }` |
| 2 | `/tasks` | `src/pages/tasks/index.tsx` (`TasksPage`, l.47-131) | 180 | no | `useNavigate` (TaskDetailPage, `l.135`), `useParams` (`l.134`) | none | none | **loading**: `l.57-58` `isPending ? ({ status: 'loading' })`; **success**: `l.59-61` `list.length === 0 ? … : ({ status: 'success', data: list })` rendered `l.96-126`; **error**: `l.55-56` `isError ? ({ status: 'error', … 'Tâches indisponibles' })`; **empty**: `l.59-60` `list.length === 0 ? ({ status: 'empty' })` + per-quadrant empty `l.109-110` |
| 3 | `/tasks/:id` | `src/pages/tasks/index.tsx` (`TaskDetailPage`, l.133-180) | (same file) | no | `useParams` `l.134`, `useNavigate` `l.135` | none | none | **loading**: `l.142-143` `isPending ? ({ status: 'loading' })`; **success**: `l.144-146` `!task ? … : ({ status: 'success', data: task })` rendered `l.156-177`; **error**: `l.140-141` `isError ? ({ status: 'error', … 'Tâche introuvable' })`; **empty**: `l.144-145` `!task ? ({ status: 'empty' })` |
| 4 | `/calendar` | `src/pages/calendar/index.tsx` (`CalendarPage`, l.67-183) | 183 | no | none | none | none (in-page tab buttons only) | **empty**: `l.72` `const events: RenderCalendarEvent[] = [];` → `l.127` `emptyMessage="Aucun événement — planifiez un bloc."` passed to `CalendarView`; **loading**: absent; **success**: absent (no `events.length > 0` branch — the list is hardcoded `[]`); **error**: absent (no error state wired; `CalendarView`/`Timeline` receive no `error` prop in this file) |
| 5 | `/projects` | `src/pages/projects/index.tsx` (`ProjectsPage`, l.16-59) | 59 | no | none | none | none | **empty**: `l.49-54` `<div data-state="empty"><p>Aucun projet</p><a href="/goals">…</a></div>`; **loading**: absent; **success**: absent; **error**: absent |
| 6 | `/goals` | `src/pages/goals/index.tsx` (`GoalsPage`, l.49-89) | 155 | no | `useNavigate` (`GoalDashboardPage` `l.94`), `useParams` (`l.92`) | none | none | **loading**: `l.57-58` `isPending ? ({ status: 'loading' })`; **success**: `l.59-61` `goals.length === 0 ? … : ({ status: 'success', data: goals })` rendered `l.69-85`; **error**: `l.55-56` `isError ? ({ status: 'error', … 'Objectifs indisponibles' })`; **empty**: `l.59-60` `goals.length === 0 ? ({ status: 'empty' })` |
| 7 | `/goals/:id` | `src/pages/goals/index.tsx` (`GoalDashboardPage`, l.91-127) | (same file) | no | `useParams` `l.92`, `useNavigate` `l.94` | none | none | **loading**: `l.98-99` `isPending ? ({ status: 'loading' })`; **success**: `l.102-104` `!goal ? … : ({ status: 'success', data: goal })` rendered `l.113-123` (via `GoalDashboard`, `src/pages/goals/dashboard.tsx:309-343`); **error**: `l.100-101` `isError ? ({ status: 'error', … })`; **empty**: `l.102-103` `!goal ? ({ status: 'empty' })` |
| 8 | `/goals/:id/features/:fid` | `src/pages/goals/index.tsx` (`GoalFeatureDetailPage`, l.129-155) | (same file) | no | `useParams` `l.130`, `useSearchParams` `l.131` | none | none | **loading**: absent; **success**: absent; **error**: absent; **empty**: absent — the body is static placeholder JSX `l.148-151` (`<h2>{fid}</h2><p>Détails de la feature (lecture locale).</p>`), no `AsyncState`/`UxStates` consumed. (Parent dashboard states are separate; this route itself renders none of the 4.) |
| 9 | `/learn` | `src/pages/learn/index.tsx` (`LearnPage`, l.36-72) | 118 | no | none | none | none | **empty**: `l.47-51` `<UxStates state={{ status: 'empty' }} flags={…} label="Révisions">` + `l.61-62` `data-state="empty"` "Aucun cours"; **loading**: absent; **success**: absent; **error**: absent (all surfaces are static empty states; the FSRS/course mirrors are not wired per the file header comment `l.9-11`) |
| 10 | `/learn/:id` | `src/pages/learn/index.tsx` (`LearnDetailPage`, l.74-118) | (same file) | no | `useParams` `l.75` | none | none | **empty**: `l.88` `<UxStates state={{ status: 'empty' }} flags={flags} label="Étude">`; **loading**: absent; **success**: absent; **error**: absent |
| 11 | `/knowledge` | `src/pages/knowledge/index.tsx` (`KnowledgePage`, l.37-91) | 124 | no | none | none | none | **empty**: `l.43-44` `const nodes: RenderSemanticNode[] = [];` + `l.69-79` `{nodes.length === 0 && (<div className="knowledge-tree-cta">…<a href="/learn">Importer</a>)}` + `l.54-59` killed-branch `<UxStates state={{ status: 'empty' }} …>`; **loading**: absent; **success**: absent; **error**: absent |
| 12 | `/knowledge/:nodeId` | `src/pages/knowledge/index.tsx` (`KnowledgeNodePage`, l.93-124) | (same file) | no | `useParams` `l.94` | none | none | **loading**: `l.105` `<UxStates state={{ status: 'loading' }} …>` (permanent — the node is never resolved, so it sits in loading); **success**: absent; **error**: absent; **empty**: absent |
| 13 | `/discovery` | `src/pages/discovery/index.tsx` (`DiscoveryPage`, l.16-43) | 43 | no | none | none | none | **empty**: `l.31-37` `<UxStates state={{ status: 'empty' }} flags={… emptyCta: "Lancer une recherche"}>` rendering `<div data-research="running">Recherche en cours (job pending)</div>`; **loading**: absent (the "job pending" text is a static string inside the empty block, not a `status === 'loading'` branch); **success**: absent; **error**: absent |
| 14 | `/progress` | `src/pages/progress/index.tsx` (`ProgressPage`, l.26-88) | 104 | no | none | none | none | **empty**: `l.61-83` `<UxStates state={{ status: 'empty' }} flags={… emptyCta: "Reprendre l'étude"}>` with dash tiles + `data-chart-mount` placeholder; **loading**: absent; **success**: absent; **error**: absent |
| 15 | `/progress/:id` | `src/pages/progress/index.tsx` (`ProgressDetailPage`, l.90-104) | (same file) | no | `useParams` `l.91` | none | none | **loading**: `l.97` `data-state="loading"` on the wrapper div (static attribute, no `isPending`/refetch cycle); **success**: absent; **error**: absent; **empty**: absent |
| 16 | `/focus` | `src/pages/focus/index.tsx` (`FocusPage`, l.41-339; mounted `service={null}` per `router.tsx:90`) | 339 | no | none | none | native `input type="number"` `l.188-195,199-206`; `input type="time"` `l.221-224`; `select` (focus sound) `l.249-259`; `input type="checkbox"` (Spotify) `l.271-276`; `select` (Spotify source) `l.281-290`; `IonButton` `l.132-134,301-314` | **loading**: absent as a named 4-state block — instead a `blocking` flag drives two data-attr branches: `l.80` `void service.isBlockingAvailable().then((b) => setBlocking(b))` → `l.146-151` `data-state="restriction-fallback"` + `l.152-157` `data-state="dpc-available"`; the timer itself is `l.320-322` `data-timer-state={service?.timer()?.state}` (with `service={null}` this renders `—`); **success**: absent (no `status === 'success'` — success is implicit in the active timer row `l.318-334`); **error**: absent; **empty**: absent |
| 17 | `/artifacts/:id` | `src/pages/artifacts/index.tsx` (`ArtifactPage`, l.21-53) | 53 | no | `useParams` `l.22` | none | none | **loading**: `l.39` `<UxStates state={{ status: 'loading' }} flags={flags} label="Aperçu">` (permanent — the preview never transitions out of loading in this file); **success**: absent; **error**: absent; **empty**: absent |
| 18 | `/agent` | `src/pages/agent/index.tsx` (`AgentPage`, l.100-483) | 483 | no | `useNavigate` `l.101,472` | custom `role="dialog"` divs: model picker `l.330-401`, + sheet `l.404-478` | native `<input>` (composer draft) `l.313-319`; native `<input type="checkbox">` (connectors) `l.437-446` | **loading**: `l.235-240` `{thinking && (<div className="agent-thinking">…L'agent réfléchit…</div>)}` where `thinking = activeRun !== undefined && !runRow` (`l.118`); also `l.208` `data-state={… thinking ? 'loading' : …}`; **success**: `l.242-248` `{inFlightRow && (<div className="agent-entry--agent">…{statusLine(inFlightRow)}</div>)}` + `l.92` `statusLine` `completed` branch; **error**: `l.169-174` `catch { push({ role: 'agent', body: 'Lancement du run impossible…' }) }` + `l.94` `statusLine` `failed` branch; **empty**: `l.220-227` `{agent && entries.length === 0 && !thinking && !inFlightRow && (<div className="agent-empty">…Commence par une intention.</div>)}` + offline-empty `l.211-218` `{!agent && (<div className="agent-empty">…L'agent est indisponible…</div>)}` |
| 19 | `/goals/:id/ascent` | `src/pages/ascent/index.tsx` (`SlideAscentPage`, l.136-216; `userId="me"` per `router.tsx:87`) | 270 | no | none | none | none | **loading**: `l.153-161` `if (status === 'pending') return (<IonContent><div data-state="loading">Chargement du chemin…</div></IonContent>)`; **success**: `l.188-215` happy-path `<header data-state="success">` + slides; **error**: `l.162-173` `if (status === 'error') return (…<button onClick={() => void refetch()}>Réessayer</button>)`; **empty**: `l.174-182` `if (data === undefined \|\| data.steps.length === 0) return (…<div data-state="empty">Aucun chemin actif</div>)` — all 4 present, each as a distinct early-return branch |
| 20 | `/inbox` | `src/pages/inbox/index.tsx` (`InboxPage`, l.14-66) | 66 | no | none | none | native `<textarea>` `l.29-36` + native `<button>` `l.37-44` | **empty**: `l.48-52` `{captured.length === 0 ? (<div data-state="empty">Inbox vide — tout est classé.</div>) : (<ul className="inbox-list">…</ul>)}` where `captured: string[] = []` (`l.18`) is a hardcoded empty array (mirror not wired); **loading**: absent; **success**: the non-empty branch `l.54-60` is the "list rendered" case; **error**: absent |
| 21 | `/settings` | `src/pages/settings/index.tsx` (`SettingsPage`, l.53-215) | 215 | no | none | none | shadcn `@aurora/ui` `Select` ×2 (`l.177-189` cadence, `l.195-207` silence) — these are Radix Select controls, not native `<select>`; theme swatches are `<button role="radio">` (`l.79-121,136-158`) | **loading**: absent; **success**: absent; **error**: absent; **empty**: absent — Settings is a purely local-preferences screen (no async data fetch; the `cadence`/`silence` state is local `useState` `l.57-58`, optimistic per the OQ-47 comment `l.11-12`) |
| 22 | `*` (fallback) | `src/pages/not-found/index.tsx` (`NotFoundPage`, l.25-62) | 62 | no | `useLocation` `l.16,26`, `Link` (`@aurora/ui`-wrapped router Link) `l.49,53` | none | none | none of the 4 apply (static "feature disabled" card); **empty**: `l.34` `<div data-state="feature-disabled" data-path={pathname}>` (the nearest analogue — a named static state, not `status: 'empty'`) |
| 23 | `/skills` | `src/pages/skills/index.tsx` (`SkillsPage`, l.46-505) | 505 | no | `useNavigate` (`src/pages/agent/index.tsx:472` is the only inbound link; the skills page itself uses `navigate('/skills')` from agent, not vice-versa) | none (tabs are in-page `role="tablist"` buttons, `l.205-224`) | native `<input>` (search) `l.262-267`; native `<input>` (skill name) `l.360-364`; native `<select>` (domain) `l.368-377`; native `<input>` (trigger) `l.381-385`; native submit `<button>` `l.387-394` | **loading**: `l.270-274` `{loading && catalog.length === 0 ? (<div className="skills-empty"><Loader2 …/>Chargement du catalogue…</div>) : (…catalog render)}`; **success**: the catalog-render branch `l.275-330` + personal-skills lists `l.399-462`; **error**: `l.226-235` `{loadError && (<div className="skills-error" role="alert">…<button onClick={() => void loadAll()}>Réessayer</button>)}` (set by `l.83` and `l.145` catch blocks); **empty**: `l.152-171` `if (!skills) return (…<div className="skills-empty">Skills indisponibles.</div>)` + `l.331-335` no-match empty + `l.464-469` no-active-skill empty + `l.491-498` expert-tab empty |
| 24 | `/integrations` | `src/pages/integrations/index.tsx` (`IntegrationsPage`, l.58-249) | 249 | no | none | none | none (all toggles are `<button>`; the Connect Link opens via `window.open(res.connectLink, '_blank')` at `l.99`, not a form) | **loading**: `l.162-167` `{loading ? (<div className="integrations-loading"><Loader2 …/>Chargement des comptes connectés…</div>) : null}`; **success**: the account-render pass `l.182-244` (no explicit `status === 'success'` — success is the catalog + connected-state render after `setAccounts`); **error**: `l.168-173` `{connectError ? (<div className="integrations-error" role="alert">…</div>) : null}` (set by `l.105`); **empty**: `l.116-130` `if (!integrations) return (…<div className="integrations-degraded">Intégrations indisponibles…</div>)` (AD-7 degrade-first, also `l.114-115` comment) |

Additional exported-but-not-routed page component: `src/pages/agent/concentration.tsx` (`ConcentrationProfilesPage`, l.55-103, 103 lines) — NOT in `router.tsx` (no route points to it); it ships seed profiles (`l.33-53`) and is an orphan surface. `src/pages/ascent/slide-types.ts` (167 lines) is a type/palette module, not a route.

---

## 2. Notable shared components

### `src/components/ui/` (shadcn/Radix layer)
- **`dialog.tsx` (77 lines)** — wraps `@radix-ui/react-dialog` (headless `DialogPrimitive.Root/Portal/Overlay/Content/Title/Close/Description`). `DialogOverlay` `l.19-29` (fixed inset-0, `bg-black/80` Tailwind class at `l.23`); `DialogContent` `l.31-54` (positioned via Tailwind `-translate-x-1/2 -translate-y-1/2`, `bg-background` token class `l.41`). No hardcoded hex/rgba in the file — colors are Tailwind token classes (`bg-background`, `text-muted-foreground`) that resolve to `var(--*)` at runtime per `main.tsx:28-29` comment. Uses `cn` from `src/lib/utils.ts` (`l.12`).
- **`toast.tsx` (48 lines)** — wraps `@radix-ui/react-toast`. `Toast` `l.17-29` (destructive variant = `border-red-600 bg-red-600 text-white` Tailwind classes at `l.23`, which are framework-token utilities, not literal hex in the `.tsx`). `ToastTitle/Description/Action/Close` `l.31-45`, `ToastProvider/Viewport` re-export `l.47-48`.
- **`command.tsx` (79 lines)** — the global command palette built on the local `Dialog`/`DialogContent`/`DialogTitle` (NOT `@radix-ui/react-command`, which the header comment `l.8-11` states is unavailable in this environment). Contains a native `<input>` at `l.45-52` (search field, `autoFocus`).

### `src/shell/`
- **`Shell.tsx` (26 lines)** — the root Ionic chrome: `IonApp > IonMenu (menuId="start", type="reveal") + IonContent > IonRouterOutlet + Outlet` (`l.14-23`). This is the shared shell all routed pages render into. `IonRouterOutlet` (`l.21`) is the one Ionic-router-primitive present; no `IonReactRouter`/`useIonRouter` anywhere.
- **`AgentBus.tsx` (33 lines)** — mounts the single Agent Command Bus (`mountAgentCommandBus` from `src/lib/agent-bus.ts`) under the router; subscribes `useNavigate` + `useUiStateStore` and returns `null` (`l.32`). No UI of its own.

### `src/ux/`
- **`floating.tsx` (109 lines)** — `CaptureFab`: token-styled FAB + custom BottomSheet (no Radix/Salt — a hand-rolled `role="dialog" aria-modal="true"` div at `l.79-106`), with an Escape-key focus-trap effect (`l.43-54`). Wraps `lucide-react` `Plus` only; no Ionic, no Radix.
- **`polish.tsx` (125 lines)** — three Framer-Motion (`motion/react`) primitives: `PageTransition` `l.41-55`, `NodePulse` `l.63-88`, `Reveal` `l.96-125`. All gate on `useReducedMotion()` (static fallback when reduced). No color literals.
- **`theme-adapter.tsx` (98 lines)** — `FocusThemeAdapter`: wraps `@aurora/ui` `AuroraThemeProvider`, computes `--aurora-node-secondary-opacity`/`--aurora-node-active-contrast` CSS vars from `FOCUS_OVERRIDES` (`l.38-41`) and writes them to `document.documentElement` (`l.80-91`). No hex in code — values are numeric multipliers (`0.4`, `1`).

### `src/ux-states.tsx` (122 lines)
- `UxStates` — the 6-state (loading/empty/success/error/offline/killed) block every async screen consumes. `resolveUxState` `l.40-56` (precedence: killed > offline > query status). `UxStates` `l.64-122`: loading = 3× `Skeleton` stack `l.78-85`; killed = skeleton + "Reconnexion…" `l.86-93`; offline = `aurora-badge` + last-known children `l.94-100`; empty = `p` + CTA button `l.101-107`; error = `role="alert"` + retry button `l.108-116`; success = children passthrough `l.117-120`. Imports `Skeleton` from `@aurora/ui` (`l.23`).

---

## 3. Capacitor plugin usages (AD-1 check)

- `grep "@capacitor/"` across `src/**` (all `.ts`/`.tsx`) = **0 matches**. No file under `src/` imports `@capacitor/core`, `@capacitor/android`, or any other `@capacitor/*` package.
- `package.json:30-31` still declares `@capacitor/core ^7.6.9` + `@capacitor/android ^7.6.9` as devDeps (used by `capacitor.config.ts` + the native build, not by app code).
- `package.json:28` `"@aurora/platform": "workspace:*"` is the declared native-boundary package; `src/main.tsx:19-20` documents it as the AD-1 shell exception for Ionic web CSS, and `src/hooks/use-online.ts:4` / `src/hooks/use-killed.ts:14` reference `@aurora/platform` in doc comments only (no `import` statements for it in code — the hooks use `navigator.onLine` / `document.visibilityState` as the webview fallback, `l.80-94` and `l.21-64` respectively).
- **No AD-1 boundary violation in `src/**`.**

---

## 4. Data providers / hooks

### `src/query/query-client.ts` (139 lines)
- `MobileDataProvider` interface (`l.21-46`): `goals` + `tasks` (required `LocalQueryRepository` from `@aurora/data`), optional `ascent` (`l.25`), optional `agent?: AgentClient` (`l.31`), optional `integrations?: IntegrationClient` (`l.37`), optional `skills?: SkillClient` (`l.43`), optional `onLocalChange` (`l.45`).
- `createMobileQueryClient(provider)` `l.83-105`: `QueryClient` with `staleTime: 60_000, retry: 1` (`l.86-91`); wires `provider.onLocalChange` → `invalidateQueries` on `goal`/`task`/`ascent` keys (`l.95-102`).
- `mobileDataProviderFrom(provider, agent?, integrations?, skills?)` `l.113-139`: the production bridge — passes through the `@aurora/data` `goals`/`tasks`/`ascent` repos (`l.120-123`) and the three optional EF clients.

### `src/query/context.tsx` (22 lines)
- `MobileDataCtx` / `useMobileData()` — the React context carrying the `MobileDataProvider` into the tree. Throws if consumed outside the provider (`l.18-21`).

### `src/query/hooks.ts` (53 lines)
- `useGoals()` `l.15-24`: `useQuery` over `qk.goal.list()`, reads `goals.list({ entity: 'goals' })` filtered to `status === 'active'`.
- `useGoal(goalId)` `l.26-33`: `enabled: goalId !== undefined`.
- `useTasks(filter?)` `l.35-42`: `useQuery` over `qk.task.list()`, reads `tasks.list({ entity: 'tasks', … })`.
- `useTask(taskId)` `l.44-51`: `enabled: taskId !== undefined`.
- All four are local-repo reads (AD-7: no network on the render path, per the file header `l.2-8`).

### `src/query/agent-runs.ts` (34 lines)
- `useAgentRun(runId)` `l.22-34`: `useQuery` over `qk.agent.run(runId)`; `queryFn` returns `agent?.run(runId) ?? null`; `enabled: runId !== undefined && runId !== '' && agent !== undefined` (`l.27`); `refetchInterval` polls at 3000 ms while `status` is non-terminal, returns `false` (stops polling) when `completed`/`failed`/`cancelled` (`l.28-31`); `retry: false`. **Degrades to `data: null`** when the `agent` client is absent (no Supabase env) — the `/agent` page then renders the `!agent` empty branch (`src/pages/agent/index.tsx:211-218`), not a fake run.

### `src/lib/agent-client.ts` (137 lines)
- `createAgentClient(supabase: AuroraSupabaseClient)` `l.98-137`:
  - `start(run)` `l.100-112`: `supabase.functions.invoke('fn-agent-run', { body: run })` — invokes the **`fn-agent-run`** Edge Function; unwraps the `ApiEnvelope` `{ ok, data }` (`l.107`), throws if `agentRunId` is absent.
  - `run(runId)` `l.114-135`: `supabase.from('agent_runs').select('*').eq('id', runId)` — direct table read (AD-7 local-first mirror, `l.115-117` comment); maps snake_case row → `AgentRunRow`.
- **AD-7 degrade guard**: the client is only *constructed* when env is present — the guard lives in `src/main.tsx:67-77`:
  ```
  const agent =
    env.supabaseUrl && env.supabasePublishableKey
      ? createAgentClient(createAuroraSupabaseClient({ env: { … } }))
      : undefined;
  ```
  (i.e. `env.supabaseUrl && env.supabasePublishableKey` is the exact guard; `env` fields come from `import.meta.env.VITE_SUPABASE_URL ?? ''` / `VITE_SUPABASE_PUBLISHABLE_KEY ?? ''` at `main.tsx:55-56`.)

### `src/lib/integrations-client.ts` (106 lines)
- `createIntegrationClient(supabase)` `l.56-106` — all four verbs POST to the **`fn-integrations`** EF via `supabase.functions.invoke('fn-integrations', { body: { verb, … } })`:
  - `listAccounts()` `l.58-65` (`verb: 'list_accounts'`)
  - `discoverTools(opts)` `l.66-77` (`verb: 'discover_tools'`)
  - `executeTool(toolSlug, input, idempotencyKey?)` `l.78-93` (`verb: 'execute_tool'`)
  - `connect(app)` `l.94-104` (`verb: 'connect'`)
- **AD-7 degrade guard** in `src/main.tsx:84-94`:
  ```
  const integrations =
    env.supabaseUrl && env.supabasePublishableKey
      ? createIntegrationClient(createAuroraSupabaseClient({ env: { … } }))
      : undefined;
  ```

### `src/lib/skills-client.ts` (192 lines)
- `createSkillClient(supabase)` `l.118-192` — six verbs POST to the **`fn-skills`** EF via `supabase.functions.invoke('fn-skills', { body: { verb, … } })`:
  - `listCatalog(domain?)` `l.120-128` (`verb: 'list_catalog'`)
  - `listUserSkills()` `l.129-137` (`verb: 'list_user_skills'`)
  - `activateSkill(skillKey, opts?)` `l.138-156` (`verb: 'activate_skill'`)
  - `deactivateSkill(skillKey)` `l.157-164` (`verb: 'deactivate_skill'`)
  - `createUserSkill(payload)` `l.165-182` (`verb: 'create_user_skill'`)
  - `deleteUserSkill(skillKey)` `l.183-190` (`verb: 'delete_user_skill'`)
- **AD-7 degrade guard** in `src/main.tsx:100-110`:
  ```
  const skills =
    env.supabaseUrl && env.supabasePublishableKey
      ? createSkillClient(createAuroraSupabaseClient({ env: { … } }))
      : undefined;
  ```

### `src/lib/boot-data.ts` (146 lines)
- `createAuroraDataProvider(env: AuroraDataEnv)` `l.84-146`: builds the `@aurora/data` production `AuroraSupabaseClient` (`l.85-94`, guarded by `env.clientFactory ?? …`), the PowerSync engine (`l.96-100`), and `SqliteQueryRepository` for `goals`/`tasks` (`l.107-108`) + `createAscentRepo(bridge)` for `ascent_paths` (`l.110`). `connect()` `l.119-135` adds scopes `identity`/`productivity`/`ascent` (`l.125-128`) and binds engine watches on `goals`/`tasks`/`ascent_paths` (`l.132-134`). **Not gated on Supabase env** — this is the local-mirror provider that always exists; the *optional* network gate lives in `main.tsx` boot: `src/main.tsx:131-138` `try { await provider.connect(); } catch (error) { console.warn('[Aurora] data provider connect() unavailable — offline / local-mirror mode', error); }` — i.e. a failed `connect()` degrades to the local-mirror shell and never blocks render (AD-7, `main.tsx:132-133` comment).

### `src/lib/ascent-repo.ts` (109 lines)
- `createAscentRepo(store: LocalStore)` `l.82-108`: the `ascent_paths` read-only mirror repo — `getById` `l.87-90`, `list` `l.91-96` (camelCase `where` → snake_case via `toSnakeWhere` `l.37-44`), `watch` `l.97-107`. Pure local read (AD-7, `l.13-14` comment).

### `src/lib/focus-sounds.ts` (290 lines)
- `FOCUS_SOUNDS` catalog (25 sounds, 5 themes) `l.40-…`; `FOCUS_SOUND_THEMES` `l.…`. Pure static data (URLs are public `archive.org` asset links, `l.46,55,64,73,…`), no env guard needed — the Focus page consumes the catalog unconditionally; the Spotify override is feature-gated by `useSpotify` state in `src/pages/focus/index.tsx:56,271-276`.

### `src/lib/agent-bus.ts` (192 lines)
- `mountAgentCommandBus(nav, ui)` + `emitAgentEffect(effect)` — the closed-set Agent Command Bus (`l.36-40` header comment). No Supabase/EF call; no env guard. UI-state wiring only (AD-7, `l.19-20` comment).

### `src/lib/utils.ts` (12 lines)
- `cn(...inputs)` = `twMerge(clsx(inputs))` — the shadcn class combiner. No env guard.

---

## 5. Missing routes / mismatches (router.tsx vs. files)

`src/router.tsx:55-111` registers **21 route entries** (counting `index` + `/home` separately as lines 60-61):

| Route (router.tsx line) | Import / element (router.tsx line) | Target file | Exists? |
|---|---|---|---|
| `index` (l.60) + `/home` (l.61) | `HomePage` (import l.32) | `src/pages/home/index.tsx` `HomePage` | yes |
| `/tasks` (l.62) | `TasksPage` (import l.33) | `src/pages/tasks/index.tsx` | yes |
| `/learn` (l.63) | `LearnPage` (import l.37) | `src/pages/learn/index.tsx` | yes |
| `/progress` (l.64) | `ProgressPage` (import l.40) | `src/pages/progress/index.tsx` | yes |
| `/agent` (l.65) | `AgentPage` (import l.43) | `src/pages/agent/index.tsx` | yes |
| `/tasks/:id` (l.68) | `TaskDetailPage` (import l.33) | `src/pages/tasks/index.tsx` | yes |
| `/learn/:id` (l.69) | `LearnDetailPage` (import l.37) | `src/pages/learn/index.tsx` | yes |
| `/progress/:id` (l.70) | `ProgressDetailPage` (import l.40) | `src/pages/progress/index.tsx` | yes |
| `/knowledge` (l.71) | `KnowledgePage` (import l.38) | `src/pages/knowledge/index.tsx` | yes |
| `/knowledge/:nodeId` (l.72) | `KnowledgeNodePage` (import l.38) | `src/pages/knowledge/index.tsx` | yes |
| `/artifacts/:id` (l.73) | `ArtifactPage` (import l.42) | `src/pages/artifacts/index.tsx` | yes |
| `/inbox` (l.76) | `InboxPage` (import l.27) | `src/pages/inbox/index.tsx` | yes |
| `/settings` (l.77) | `SettingsPage` (import l.45) | `src/pages/settings/index.tsx` | yes |
| `/goals` (l.80) | `GoalsPage` (import l.36) | `src/pages/goals/index.tsx` | yes |
| `/goals/:id` (l.81) | `GoalDashboardPage` (import l.36) | `src/pages/goals/index.tsx` | yes |
| `/goals/:id/features/:fid` (l.82) | `GoalFeatureDetailPage` (import l.36) | `src/pages/goals/index.tsx` | yes |
| `/goals/:id/ascent` (l.87) | `SlideAscentPage` (import l.44) | `src/pages/ascent/index.tsx` | yes |
| `/focus` (l.90) | `FocusPage` (import l.41) | `src/pages/focus/index.tsx` | yes |
| `/calendar` (l.91) | `CalendarPage` (import l.34) | `src/pages/calendar/index.tsx` | yes |
| `/projects` (l.94) | `ProjectsPage` (import l.35) | `src/pages/projects/index.tsx` | yes |
| `/discovery` (l.97) | `DiscoveryPage` (import l.39) | `src/pages/discovery/index.tsx` | yes |
| `/skills` (l.100) | `SkillsPage` (import l.47) | `src/pages/skills/index.tsx` | yes |
| `/integrations` (l.103) | `IntegrationsPage` (import l.48) | `src/pages/integrations/index.tsx` | yes |
| `*` (l.110) | `NotFoundPage` (import l.46) | `src/pages/not-found/index.tsx` | yes |

**No missing route files** — every import in `router.tsx` resolves to an existing, named-export file.

**Orphan pages (file exists but no route points to it):**
- `src/pages/agent/concentration.tsx` — `ConcentrationProfilesPage` (l.55) is exported but **not imported by `router.tsx`** and not reachable from any route in `src/router.tsx:115-119` (`AppRoute` union type lists no `/concentration` or `/agent/concentration` path). It ships `SEED_PROFILES` hardcoded (`l.33-53`).

**File-count vs. frozen 17-page inventory (02 S6.1, `router.tsx:14-18`):** the header comment lists 17 named pages (`/home … /agent`) + `/inbox` + `/settings` as "tab-adjacent" + `*` fallback = 20 surface names. The actual `router.tsx` registers **21 entries** because `/home` is registered twice (`index` at l.60 and `/home` at l.61, both → `HomePage`). The router has since grown beyond the frozen 17: `/skills` (l.100), `/integrations` (l.103), and `/goals/:id/ascent` (l.87) are additions documented inline in `router.tsx` (l.84-86 "wave 3, W3-E2"; l.99 "ADR S14"; l.102 "Composio"). No route in `router.tsx` is unresolvable.

---

## 6. Design-system compliance spot-check (`.tsx` color literals)

Task scope: any hardcoded hex/rgba literal in a `.tsx` file outside `src/styles/*.css` (CSS is the expected token-definition site; `.tsx` should only reference `var(--*)`).

- **Result: 0 hardcoded hex/rgba color literals in any `.tsx` under `src/`.** A regex sweep `#[0-9a-fA-F]{3,8}\b|rgba?\(` over all `.tsx` files returned only:
  - `src/pages/goals/dashboard.tsx:261` `stroke="currentColor"` — this is an SVG keyword, not a color literal (it inherits `color` from CSS, which is `var(--aurora-*)`).
  - No `rgba(`, `#fff`, `#000`, etc. in any `.tsx`.
- The only `style={{ background: … }}` in code is `src/pages/settings/index.tsx:43-51` `swatchGradient()` → `linear-gradient(120deg, ${c.primary}, ${c.secondary}, ${c.accent})` where `c` is read from the `@aurora/ui` `THEMES`/`PRESETS` catalog (theme-owned color values, `l.44-49` comment "its OWN tokens, 05 §5.7") — i.e. the values come from the design-system theme catalog, not a hardcoded literal in this file.
- `src/styles/agent.css:126,138` use `var(--aurora-accent-warning, #b45309)` — a CSS token with a hex *fallback* (acceptable per the "CSS files are the definition site" rule, noted for completeness).
- `src/styles/agent.css:241,390` and `src/styles/floating.css:43,97` use `rgba(0,0,0,0.4)` / `rgba(15,23,42,0.4)` for scrims — CSS-side, within the allowed scope.

**`.tsx` files are clean on the color-literal rule.** The only color-bearing `style={{}}` in code (`settings/index.tsx:91,112`) is theme-catalog-driven.
