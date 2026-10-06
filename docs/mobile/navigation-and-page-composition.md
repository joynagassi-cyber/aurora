# Navigation & Page Composition (product graph, not isolated pages)

Status: design phase. Authority: 02 §6 (routing decision), 05 §4 (screen inventory, 44
screens), AD-14 (Home invariant), AD-7 (local reads). Aurora is a **navigation/product
graph**: every page has entry points, outgoing/incoming routes, context passed,
agent-triggered opening, return behavior, and persistent state.

## 1. Route structure (frozen, 02 §6.1)

Primary tabs (max 5, 44-60 px tab bar): `/home` · `/tasks` · `/learn` · `/progress` ·
`/agent`. Details open **over** the current tab (IonModal/IonSlides — never a tab
switch, 02 §6.1): `/tasks/:id`, `/learn/:id`, `/progress/:id`, `/knowledge` +
`/knowledge/:nodeId`, `/artifacts/:id`, `/inbox`, `/settings`. Native back (Android
gesture) works on every route; a route that blocks back **saves first** (02 §6.3 —
local-first makes form state auto-persisted).

Feature detail routes (19 pages total, matrix §2): `/calendar`, `/projects`,
`/goals`, `/discovery`, `/focus` (session screen), `/tasks/:id`, `/learn/:id`,
`/knowledge/:nodeId`, `/artifacts/:id`, `/skills` (ADR S14, fn-skills, OQ-03),
`/integrations` (Composio, fn-integrations, OQ-33-35), `/ascent` (module Ascent),
`/progress/:id`, `/goals/:id`, `/calendar/:date`, `/tasks?view=matrix` (Eisenhower).
The `/skills` and `/integrations` routes are server-backed (fn-skills /
fn-integrations) and degrade to honest empty states when no Supabase env
(AD-7, OQ-03 / OQ-33-35) — they are NOT in the frozen 17-page core.

## 2. Page matrix (required fields per page)

Legend: EP = entry points; OUT = outgoing routes; IN = incoming; CTX = context passed;
DEEP = deep link; AGT = agent-triggered opening; RET = return behavior; PERSIST =
persistent state; EMPTY = empty state; PERM = permission state.

| Page (route) | EP | OUT | IN | CTX | DEEP / AGT | RET | PERSIST | EMPTY | PERM |
|---|---|---|---|---|---|---|---|---|---|
| **Home** `/home` (05 §4.1.2, AD-14 fixed composition) | app boot; tab | /tasks, /learn, /progress, /agent, /knowledge, /inbox, /settings (via cards/CTA) | all tabs (return to home = fresh render from local store) | global today-context (no params — data from local store only, 02 §6.2: **no network on mount**) | deep: push/OneSignal click routes (04 §3.2.5 `route` in notification payload); AGT: Coach suggestion cards open /agent or /tasks/:id | returns to today state | theme+persist UI prefs only | each of the 7 AD-14 slots renders a clean per-slot empty (05 §4.1), never a web-search skeleton | none (read-only) |
| **Inbox** `/inbox` | tab-adjacent (02 §6.1 route), capture buttons everywhere, quick-capture from any screen (05 §4) | triage → /tasks/:id, /learn/:id, /settings… | all screens (capture CTA); OneSignal reminders | captured item kind + draft text | AGT: agent "capture this" command | back to previous screen | draft persistence (local, Tiptap) | "inbox cleared" state (05 §4) | camera/mic if capturing media (optional) |
| **Tasks** `/tasks` (+`/tasks/:id` overlay) | tab; Home next-action; Agent suggestions; /inbox triage | detail overlay (edit, subtasks, eisenhower view, focus CTA → focus screen) | Home, /agent, /inbox, /projects/:id, /goals/:id | task list filters (view mode = ui-state store, 02 §3); `:id` param | deep: push "task due" → `/tasks/:id`; AGT: planner opens task lists; **Eisenhower quadrant view** (docs/productivity/eisenhower.md, G-L5) | return to list w/ scroll + filters kept (persistent ui-state) | list order/filter/virtualization state (ui-state, cosmetic persist, 02 §3.2); data = local store | "no tasks" + capture CTA | none |
| **Calendar** `/calendar` (inside /tasks family views + 05 §4.4.2) | tab switch in /tasks, Home agenda | time-block editor, event detail | Home, /tasks, goals (exam dates), Agent replan | day/week/month view + time blocks | AGT: scheduling action confirmation screens land here | previous view kept | view mode + time blocks | empty day/week | `POST_NOTIFICATIONS` (reminders, first-use) |
| **Projects** `/projects` → 05 §4.3 | /tasks, goals, Home | Gantt/Kanban/Timeline/List views + project detail (milestones, docs, notes) | goals (`GoalUpdated`), agent plan | project filters | AGT: project creation from goal decomposition | return to list | view modes (Kanban/Timeline/Gantt) persisted per project | "no projects" + goal CTA | none |
| **Goals** (05 §4.3) | /projects, Home critical-progress slot | goal detail → milestones/projects (goal→project→task hierarchy, 01 §4.1) | Progress (trajectory), Agent | goal horizon (short/mid/long) | AGT: "what to work on" opens goal | back to list | progress snapshot read | "no goals" + capture CTA | none |
| **Learning** `/learn` (+`/learn/:id` overlays: course, sheet, flashcards, QCM, coach) | tab; Home due-reviews; Agent tutor | course → chapter → sheet/QCM/flashcards/mirror (05 §4.6–4.9); due-reviews list | Home, /agent, /knowledge (node → "study"), discovery sheets ("work on this") | due/review context; course id chain (context-preserving, §3) | deep: push "review due" → `/learn/:courseId`; AGT: targeted revision opens flashcards | previous course position | FSRS state read-only local; study position persisted | "no due reviews" (05 §4.8) | camera/mic (capture/record, optional) |
| **Flashcards/QCM/Exercises** (05 §4.8) | /learn, Home due-reviews | result → Progress (skill view); error analysis | /learn/:id chain | card deck / QCM set id | AGT: "test me on X" | back to deck | session progress (resume) | empty deck = generate CTA | none |
| **Knowledge** `/knowledge` (+`/knowledge/:nodeId`) | tab-adjacent route (02 §6.1); Home; Learning (tree link) | node detail (lazy deeper branches, 02 §9.2), provenance drill-down, "study" → /learn | Home, /learn, discovery (tree links), Artifacts (source refs) | node id + path (domain_path, 01 §4.3) | AGT: explain-the-concept opens node + Tutor | previous node/zoom kept | tree expansion state (ui-state) | empty tree = import CTA | none (server retrieval only when online — AD-12) |
| **Discovery** (feed, 05 §4 / ADR §13.9) | /agent suggestions; Home coach slot | sheet detail → "work on this" → /learn or /tasks | Agent, goals (gap analysis) | discovery profile filters | AGT: weekly discovery digest | back to feed | feed scroll + read state | "research running" (job state, 01 §6 loading) | none (jobs) |
| **Progress** `/progress` (+`/progress/:id`) | tab; Home critical-progress; session bilans | dashboards today/week/month/trajectory (ADR §18.6), skill-map, gaps view | Home, flashcards (result), focus bilan | period selector (ui-state) | AGT: "how am I doing?" opens dashboard | previous period | read-only mirrors (skill_states, progress_snapshots — 03 §4.2) | "not enough data yet" (honest) | none |
| **Focus** (05 §4.4.2) | Home slot 6 (AD-14 immediate Focus), /tasks/:id CTA, Agent | session screen (timer ring) → bilan sheet (`focusBilan` ChartSpec, 05 §3.6.9) | Home, tasks, /agent | task link + blocklist (v1.8 DPC) | AGT: "start focus, block X+Y" (v1.8 candidate — OQ-17) | back to origin task | session row (focus_sessions) | session not started state | `POST_NOTIFICATIONS`; DPC = OQ-17 |
| **Artifacts** `/artifacts/:id` | search/results, course (exports), /agent | preview (per format, ADR §16) → source/download/share | /learn, /agent, discovery | artifact id + kind | AGT: "show me the generated X" | back to origin list | cached previews (04 §3.2.2) | "loading preview / unsupported" (no fake preview, ADR §16) | none (presigned) |
| **Agent** `/agent` | tab; any screen assistant CTA; Home coach slot | conversation → actions confirmation → target screens (/tasks, /learn, /focus…); **peelable deep-link bubbles** (`route` payload, 04 §3.2.5) open the target page over the chat (agent-chat.md §5.1 G4) | Home, all features (assistant CTA), deep links | AgentRunState (F-09, 02 §4) + run history | deep: push "coach check-in" → /agent | back returns to the chat (`{ state: { from: '/agent' } }` — the transcript is kept, 02 §6.3); conversation history local | conversation + confirmations pending | "start with an intent" | destructive ops = confirmation (AD-12) |
| **Skills** `/skills` | Home, /agent (+ sheet), Settings | 3 tabs: catalogue / mes skills / expert (ADR S14) | Home, /agent, /settings | skill domain grouping | — | back to origin | activated skills (user_skills, RLS) | honest empty state when no Supabase env (AD-7 / OQ-03) | none |
| **Integrations** `/integrations` | Home, /agent (+ sheet) | connect external accounts (Composio) | Home, /agent | connected-account state | — | back to origin | integrations_state (RLS user-isolated) | "intégrations indisponibles" when no Supabase env (AD-3/AD-7) | OAuth via WebView / deep link (tokens stay server-side, AD-3) |
| **Settings** `/settings` | Home, any top bar | theme selector + preview (05 §2.1: auto-switch deferred to /settings mount, never boot), silence windows (coaching cadence, ADR §13), notification prefs, account | all | none | — | back to origin | theme = persisted (store persist middleware) | n/a | OneSignal appKey only in `capacitor.config.ts` (04 §3.2.5) |

## 3. Context-preserving navigation (details)

The full graph + the course→chapter→formula→flashcards→QCM→progress chain is
documented in [context-preserving-navigation.md](./context-preserving-navigation.md)
(route params vs query params, navigation state, entity/session ids, draft
persistence, return destination).

## 4. Feature visibility rules (Aurora must grow AND shrink)

A hidden feature disappears from **navigation, shortcuts, command palette, agent
capabilities, widgets, dashboards, suggestions** — its historical data stays intact
([../frontend/feature-registry.md](../frontend/feature-registry.md), G-M7
NEEDS_DECISION). Tabs themselves are stable (max 5, 02 §6.1); what hides/shows is
within-tab content + routes + agent capability surface.
