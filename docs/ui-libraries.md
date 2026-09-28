# Aurora UI Libraries Reference (for all coding agents)

**Status:** Prescriptive reference. Every UI component in Aurora maps to a
specific premium library. Agents install via the exact commands below —
NEVER write components from scratch if a library covers the need.

## 1. What Aurora Uses (Component -> Library Map)

| Aurora component | Library | Install | Notes |
|---|---|---|---|
| **Button** (all variants) | shadcn/ui | `npx shadcn@latest add button` | Variants: default, destructive, outline, secondary, ghost, link |
| **Card** (GoalProject, tasks, artifacts) | shadcn/ui + Aceternity | `npx shadcn@latest add card` + `npx shadcn@latest add @aceternity/wobble-card` | Wobble for interactive cards, standard for data cards |
| **Dialog / Modal** (confirmations, detail) | shadcn/ui | `npx shadcn@latest add dialog` | Headless, fully skinnable with tokens |
| **Drawer** (longer tasks, context) | shadcn/ui | `npx shadcn@latest add drawer` | For Focus details, Goal settings |
| **Input** (text, number, search) | shadcn/ui | `npx shadcn@latest add input` | |
| **Textarea** (notes, descriptions) | shadcn/ui | `npx shadcn@latest add textarea` | |
| **Select / Dropdown** | shadcn/ui | `npx shadcn@latest add select` + `npx shadcn@latest add dropdown-menu` | |
| **Checkbox / Radio / Switch** | shadcn/ui | `npx shadcn@latest add checkbox` + `npx shadcn@latest add radio-group` + `npx shadcn@latest add switch` | |
| **Slider** (numeric, progress) | shadcn/ui | `npx shadcn@latest add slider` | |
| **Table** (QCM results, data) | AG Grid Community | `npm install ag-grid-community ag-grid-react` | Virtualized, 1000+ rows 60fps. NOT shadcn Table for heavy data |
| **Data Grid (light)** (small tables < 20 rows) | shadcn/ui | `npx shadcn@latest add table` | For simple data displays |
| **Calendar** (time blocking, events) | FullCalendar | `npm install @fullcalendar/react @fullcalendar/daygrid @fullcalendar/timegrid @fullcalendar/interaction @fullcalendar/list` | 4 views: day, week, month, agenda. NOT ion-calendar |
| **Date Picker** | FullCalendar + shadcn Popover | FullCalendar in shadcn popover | `npx shadcn@latest add popover` |
| **Tabs** (multi-view screens) | shadcn/ui | `npx shadcn@latest add tabs` | |
| **Accordion** (expandable sections) | shadcn/ui | `npx shadcn@latest add accordion` | |
| **Tooltip** (icon hover) | shadcn/ui | `npx shadcn@latest add tooltip` | |
| **Popover** (quick actions) | shadcn/ui | `npx shadcn@latest add popover` | |
| **Command Palette** (global search) | Radix Command + shadcn | `npx shadcn@latest add command` | 5 entry points (UI, palette, agent, deep link, automation) |
| **Toast / Notifications** | shadcn/ui | `npx shadcn@latest add toast` + `npx shadcn@latest add toaster` | Non-blocking feedback |
| **Alert / Inline error** | shadcn/ui | `npx shadcn@latest add alert` + `npx shadcn@latest add alert-dialog` | |
| **Badge / Tag** (status, category) | shadcn/ui | `npx shadcn@latest add badge` | |
| **Avatar** (user, agent) | shadcn/ui | `npx shadcn@latest add avatar` | |
| **Progress bar** (loading, goal %) | shadcn/ui | `npx shadcn@latest add progress` | |
| **Spinner / Loader** | shadcn/ui | `npx shadcn@latest add skeleton` | Skeleton loading states |
| **Sidebar / Navigation** | shadcn/ui | `npx shadcn@latest add sidebar` | |
| **Breadcrumbs** (context nav) | shadcn/ui | `npx shadcn@latest add breadcrumb` | "ML Mastery > QCM Thermo" |
| **Pagination** (list pages) | shadcn/ui | `npx shadcn@latest add pagination` | |
| **Scroll Area** | shadcn/ui | `npx shadcn@latest add scroll-area` | |
| **Separator** | shadcn/ui | `npx shadcn@latest add separator` | |
| **Label** (form fields) | shadcn/ui | `npx shadcn@latest add label` | |
| **Menubar** | shadcn/ui | `npx shadcn@latest add menubar` | |
| **Context Menu** (right-click) | shadcn/ui | `npx shadcn@latest add context-menu` | |
| **Hover Card** (preview on hover) | shadcn/ui | `npx shadcn@latest add hover-card` | Artifact preview |
| **Kbd** (keyboard shortcuts) | shadcn/ui | `npx shadcn@latest add kbd` | |
| **Form** (multi-field) | shadcn/ui + React Hook Form | `npx shadcn@latest add form` + `npm install react-hook-form @hookform/resolvers zod` | |
| **Semantic Tree** (knowledge) | React Flow + Dagre | `npm install reactflow dagre` | AD-10 renderer, lazy, incremental, 30fps |
| **Infographic** (multi-resource) | AntV Infographic | `npm install @antv/infographic` | Hybrid SVG + <image> (real photos + generated) |
| **Charts** (progress, analytics) | AntV G2 | `npm install @antv/g2` | AD-10 DataVisualizationRenderer |
| **Math / Formulas** | KaTeX | `npm install katex` | AD-10 MathRenderer, onError = styled raw source |
| **Rich Text Editor** (courses, sheets) | Tiptap | `npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-math @tiptap/extension-link @tiptap/extension-table @tiptap/extension-highlight @tiptap/extension-code-block` | ADR v1.5, extensions + Aurora custom (SourceRefInline, CorpusBadge) |
| **Animations** (transitions, pulse) | Framer Motion | `npm install framer-motion` | GPU, smooth, NOT bouncy, reduced-motion aware |
| **Marquee / Ticker** (notifications) | Magic UI | `npx shadcn@latest add @magicui/marquee` | |
| **Number Tick / Counter** | Magic UI | `npx shadcn@latest add @magicui/number-tick` | Progress numbers |
| **Glow / Shine effect** | Magic UI | `npx shadcn@latest add @magicui/shine-effect` | Premium card highlight |
| **Wobble Card** | Aceternity UI | `npx shadcn@latest add @aceternity/wobble-card` | GoalProject cards |
| **Interactive Cards** | Aceternity UI | `npx shadcn@latest add @aceternity/interactive-card` | Feature cards |
| **Beam / Spotlight** | Aceternity UI | `npx shadcn@latest add @aceternity/beam` | Focus mode visual |
| **Audio Waveform** | Custom (pure React, 04 S5) | Write in `packages/ui` | NOT a Capacitor adapter. Renders AudioArtifactProvider data |
| **Icons** | Lucide React | `npm install lucide-react` | 16px in nodes, 20px in header. NOT emoji, NOT custom SVG |
| **Typography** | Inter (system fallback) | `npm install @fontsource/inter` | 13px/500 labels, 16px/600 titles, 20px/700 progress |
| **Fisher-Yates / Shuffle** | Utility | `npm install immer` (if needed) | |
| **Drag & Drop** (kanban, reorder) | dnd-kit | `npm install @dnd-kit/core @dnd-kit/sortable` | Kanban views (05 S4.3) |
| **Virtual List** (1000+ items) | AG Grid OR react-virtuoso | `npm install @virtuoso.dev/virtuoso` (fallback, OQ-09) | IonList native < 100 items |
| **PDF Preview** | react-pdf | `npm install react-pdf` | Artifact Hub (PDF rendering) |
| **Audio/Video Player** | HTML5 media | Native `<audio>` / `<video>` | 04 S5: "if format + platform allow" |
| **OCR / Scanner UI** | DocumentScanner (04 S3.2) | Custom Capacitor plugin | Camera capture, multi-page |

## 2. Installation Order (one-time setup)

Run ONCE in `apps/mobile` (or `packages/ui` if shared):

```bash
# 1. shadcn/ui init (creates components.json, lib/utils, theme tokens)
npx shadcn@latest init

# 2. Add all shadcn components (one command)
npx shadcn@latest add button card dialog drawer input textarea select \
  dropdown-menu checkbox radio-group switch slider table tabs accordion \
  tooltip popover command toast toaster alert alert-dialog badge avatar \
  progress skeleton sidebar breadcrumb pagination scroll-area separator \
  label menubar context-menu hover-card kbd form

# 3. Premium additions (shadcn registries)
npx shadcn@latest add @aceternity/wobble-card
npx shadcn@latest add @aceternity/interactive-card
npx shadcn@latest add @aceternity/beam
npx shadcn@latest add @magicui/marquee
npx shadcn@latest add @magicui/number-tick
npx shadcn@latest add @magicui/shine-effect
npx shadcn@latest add @magicui/blurred-spotlight
npx shadcn@latest add @magicui/text-reveal
npx shadcn@latest add @magicui/cool-mode
npx shadcn@latest add @magicui/borders
npx shadcn@latest add @magicui/flicker-loading
npx shadcn@latest add @magicui/partition
npx shadcn@latest add @magicui/flip
npx shadcn@latest add @magicui/particles
npx shadcn@latest add @magicui/interactive-highlighted-card

# 4. Data & visualization
npm install ag-grid-community ag-grid-react
npm install @fullcalendar/react @fullcalendar/daygrid @fullcalendar/timegrid \
  @fullcalendar/interaction @fullcalendar/list
npm install @antv/g2
npm install @antv/infographic
npm install reactflow dagre
npm install katex
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-math \
  @tiptap/extension-link @tiptap/extension-table @tiptap/extension-highlight \
  @tiptap/extension-code-block
npm install framer-motion
npm install lucide-react
npm install @fontsource/inter
npm install @dnd-kit/core @dnd-kit/sortable
npm install react-pdf
npm install react-hook-form @hookform/resolvers zod
npm install clsx tailwind-merge (shadcn prerequisites)

# 5. shadcn registries config (components.json)
# Add to components.json:
# {
#   "registries": {
#     "@aceternity": "https://ui.aceternity.com/registry/{name}.json",
#     "@magicui": "https://magicui.design/r/{name}.json",
#     "@react-bits": "https://reactbits.dev/r/{name}.json",
#     "@21st": "https://21st.dev/r/{name}.json"
#   }
# }
```

## 3. What NOT to Use (explicitly excluded)

| Library | Reason |
|---|---|
| ion-calendar | "Vieux", English-style, corporate. Replace with FullCalendar |
| ion-list (for data tables) | Dated. Replace with AG Grid (heavy) or shadcn Table (light) |
| ion-item (for forms) | Dated. Replace with shadcn/Radix form components |
| ion-datetime | Replace with FullCalendar date picker + shadcn Popover |
| MUI / Ant Design / Chakra | Web-first, heavy, conflicts with Ionic + design tokens |
| CopilotKit | Conflicts with AD-10 frozen engines + 5-state UX |
| Custom SVG decorations | Use real/generated images (Agnes Image) |
| Border radius > 8px | DS convention (05 S3) |
| Bouncy animations | Framer Motion: smooth, 150-250ms, reduced-motion aware |

## 4. Design Token Integration (AD-17, 05 S2.1)

Every component uses Aurora's design tokens, NOT the library's defaults:

```
shadcn/ui -> components/ui/*.tsx
  -> uses CSS variables (--primary, --background, --radius, ...)
  -> which come from Aurora's theme JSON (packages/ui/src/themes/)
  -> resolved by resolveToken() + <AuroraThemeProvider>

So: changing the theme = changing the JSON, NOT changing components.
All 10 themes + 3 presets work automatically (AD-17: theme = skin only).
```

**Rule: after installing a shadcn component, replace its default
colors with Aurora's CSS variables. Never hardcode `#000` or `#fff`.**

## 5. Mobile-Specific Adaptations

| Concern | Solution |
|---|---|
| FullCalendar on mobile (webview) | Touch-optimized: day/week views (not year). `height: auto`, responsive CSS. 44px min tap targets |
| AG Grid on mobile | `rowBuffer: 10`, `maxVisibleRows: 30`. 60fps on Pixel 4a |
| shadcn on mobile (touch) | Headless = fully skinnable. Touch targets >= 44px. Custom touch handlers where needed |
| Framer Motion battery | GPU only (transform + opacity). No `layout` animations on mobile. `prefers-reduced-motion` = static |
| Tiptap mobile keyboard | `contenteditable` in webview. Keyboard avoidance: Capacitor `Keyboard` plugin |
| Theme switching | CSS variables (instant, GPU, no re-render) |
| Dark mode | `prefers-color-scheme` + user override (UserContext.theme, AD-17) |

## 6. The 5 UX States (AD-13) on Every Async Component

Every component that loads async data MUST handle:

| State | Component | Visual |
|---|---|---|
| **loading** | shadcn Skeleton | Shimmer pulse (Framer Motion, GPU) |
| **error** | shadcn Alert (destructive) | Red border + message + retry button |
| **empty** | shadcn Card (empty variant) | Icon + text + CTA ("Demande a Aurora") |
| **success** | shadcn Toast | Green check + auto-dismiss (3s) |
| **offline** | Badge (top bar) | "Offline" badge + last-known data |
| **killed** (G-M2) | Skeleton + auto-resync | "Reconnexion..." + shimmer |

**No async component may be missing any of these 6 states.**

### 6.1 Screen-level semantic states (beyond the S6 component states, owner decision 2026-09-27)

S6 is the SSoT for async COMPONENTS. Screens additionally document these
semantic states — each screen spec lists WHICH apply, with exact text /
component / token / CTA (state not applicable = "N/A (raison)", never blank):

| State | Meaning | Component + visual | Distinction (blocking) |
|---|---|---|---|
| **en-cours** | operation actively running WITH partial results (streaming, import, QCM in progress, sync) | shadcn `Progress` (value %) + live label; agent = streaming tokens | ≠ S6 `loading` (data not arrived, no progress): en-cours has a MEASURABLE progress |
| **terminé** | terminal, neutral-positive: the object is done, nothing left to do | Lucide `CheckCircle2` + summary + next-action hint (AD-14 "What matters now?") | ≠ S6 `success` (transient Toast): terminé is the OBJECT's state |
| **échec** | terminal, negative: failed and NOT retryable in place | shadcn `Alert` (destructive) + reason + CTA to an ALTERNATIVE path | ≠ S6 `error` (transient, "Réessayer" in place): échec = no in-place retry |
| **succès** | transient positive confirmation after an action | S6 `success` (Toast, 3s auto-dismiss) | unchanged S6 |
| **erreur** | transient failure, retryable in place | S6 `error` (destructive Alert + "Réessayer") | unchanged S6 |
| **404 / not-found** | unknown route / deep link into a disabled feature | FULL-SCREEN: COLORED without-background Aurora logo CENTERED (§9.1), short message, primary CTA "Retour à l'accueil", optional secondary "Consulter l'écran parent"; NO crash, NO bare 404 text (feature-registry S6) | the only state that MANDATES the centered logo (S9) |

## 7. Premium Component Examples (for reference)

### GoalProject Card (Home screen)

```tsx
// Uses: Aceternity WobbleCard + shadcn Card + Progress + Lucide
import { WobbleCard } from "@/components/ui/wobble-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Target } from "lucide-react";

export function GoalProjectCard({ goal }: { goal: GoalProject }) {
  return (
    <WobbleCard>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target size={16} />
            {goal.objective}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <Progress value={goal.progress.overallPct} />
          <p className="text-xs text-muted-foreground">
            {goal.progress.subGoalProgress.active} / {goal.subGoals.length} sous-objectifs
          </p>
          {/* Next action from Agent suggestion */}
          {goal.nextAction && (
            <div className="text-sm">
              Prochain: {goal.nextAction.label}
            </div>
          )}
        </CardContent>
      </Card>
    </WobbleCard>
  );
}
```

### Focus Timer (Focus screen)

```tsx
// Uses: shadcn Card + Progress + Framer Motion (pulse on active)
import { motion } from "framer-motion";

export function FocusTimer({ session }: { session: FocusSession }) {
  return (
    <motion.div
      animate={session.status === "active" ? { opacity: 1 } : { opacity: 0.6 }}
      transition={{ duration: 0.2 }}
      className="p-4 rounded-lg border"
    >
      <h2>{session.plannedMinutes} min</h2>
      <Progress value={(session.actualMinutes / session.plannedMinutes) * 100} />
      {session.blocklist?.map(pkg => (
        <Badge key={pkg.packageName} variant={pkg.suspended ? "default" : "secondary"}>
          {pkg.label}
        </Badge>
      ))}
    </motion.div>
  );
}
```

### Semantic Tree (Knowledge)

```tsx
// Uses: React Flow + Dagre (AD-10 SemanticTreeRenderer)
import ReactFlow, { useNodesState, useEdgesState } from "reactflow";
import { topologicalSort } from "dagre";

// Lazy level-1, incremental expand, 30fps
// Node colors: mastered=green, fragile=yellow, unknown=gray (NodeState, AD-6)
// Bridges: hidden by default, cross-domain view = toggle (Phased Layering)
```

### Calendar (FullCalendar, NOT ion-calendar)

```tsx
// Uses: FullCalendar (day/week/month/agenda) + time blocking
import { FullCalendar } from "@fullcalendar/react";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";

// Time blocks = events with backgroundColor per type (etude, focus, projet)
// Conflict = double red border (FullCalendar eventOverlap)
// Focus sessions = special event type with blocklist icon
```

## 8. Agent Decision Framework (autonomous, no user input)

**When an agent needs a UI component, it follows this decision tree
WITHOUT asking the user:**

```
1. What is the NEED? (not the component name)
   "I need to show 500 QCM results with filtering"
   -> Data table, virtualized -> AG Grid

2. What is the VOLUME?
   < 20 rows -> shadcn Table
   20-100 rows -> shadcn Table + pagination
   > 100 rows -> AG Grid (virtualized)

3. What is the STATE?
   loading -> Skeleton (shimmer, Framer Motion)
   error -> Alert (red, retry)
   empty -> Card + icon + CTA
   success -> Toast (auto-dismiss)
   offline -> Badge + last-known data
   killed -> Skeleton + auto-resync

4. What is the INTERACTION?
   Tap -> navigate (deep link)
   Long-press -> context menu
   Swipe -> dismiss (toast) / reorder (kanban)
   Drag -> kanban move, timeline adjust

5. What is the CONTEXT?
   Mobile (primary) -> dense, 44px targets, bottom nav
   Goal Dashboard -> adaptive layout (5 shapes)
   Focus mode -> attenuated secondary nodes, pulse on active

6. Which LIBRARY covers it?
   Check docs/ui-libraries.md (this file)
   If covered: use the library component
   If NOT covered: build with shadcn primitives + tokens
   NEVER: write a custom component if a library has it
   NEVER: mix 2 libraries on the same screen

7. Does it fit the 5 UX states?
   If yes -> implement
   If no -> add the missing states

8. Is it theme-aware?
   Uses CSS variables? Yes -> good
   Hardcoded colors? NO -> fix to use tokens

Document the decision in a 1-line comment above the component:
// AG Grid: 500+ QCM results, virtualized, filter by topic
// shadcn Table: < 20 rows, simple data display
// WobbleCard: GoalProject on Home, interactive, premium feel
```

## 9. Brand Assets (the 4 official logo files, /assets)

SSoT for branding: exactly 4 files at the repo root (2 official colored +
2 monochrome, owner decision 2026-09-27) — do NOT redraw, do NOT generate,
do NOT fetch a logo from anywhere else.

| File | What it is | Where it is used |
|---|---|---|
| `assets/aurora_logo_icon_d'affichage_l'applicaiton.png` | Full logo (butterfly + light rounded background) | **External app icon ONLY**: Capacitor icons, Play Store, splash screen, install screen. NEVER inside the app UI |
| `assets/aurora_icon_a_integre_dans_l'applciation.png` | Logo WITHOUT background (transparent butterfly, COLORED) | **In-app logo (default)**: header (top bar), page center (empty states, onboarding, in-app splash), footer. NEVER as the external app icon |
| `assets/lg_aurora_vs_monochrome.png` | MONOCHROME rendition (grayscale metallic tones, no background) | Raster fallback / document exports only (see §9.1–9.3). In-app = the SVG |
| `assets/vs_monochrome_en_svg.svg` | MONOCHROME vector (same art, grayscale, 1024×1024 viewBox) | In-app monochrome usage ONLY: animated `AgentThinkingLoader` (§9.3) + static monochrome states (§9.1). Vector = sharp at any size |

Rules (every UI agent):
- Header / empty state / page center = ALWAYS the COLORED WITHOUT-background
  version — EXCEPT where the §9.1 matrix prescribes the monochrome version.
- Home screen / store / app splash = ALWAYS the full version.
- Both are referenced from repo-root `/assets` (imported by the app
  bundler) — never duplicated into src/, node_modules or any other folder.
- No background color behind the transparent version, no crop, no recolor.
- When generating app icons (Capacitor build / store assets): source = full version.

### 9.1 Monochrome usage matrix (owner decision, 2026-09-27)

« Monochrome » = a grayscale TONAL rendition (metallic grays #131B22 →
#B9BABC), NOT a flat silhouette. It is a STATE, not a theme: monochrome
reads as "brand present but not speaking" (neutrality / waiting / inactive);
the colored version reads as "brand active".

| Case | Version | Why (designer psychology) |
|---|---|---|
| Header / top bar (every screen) | colored without-background | owner decision 2026-09-27: the header ALWAYS carries the COLORED brand |
| Agent chat — new session / empty state | monochrome | the agent has not spoken yet = neutral presence; color returns on the first message (fluidity) |
| Agent thinking / loading (animated) | monochrome SVG, animated (§9.3) | "the brand is thinking": calm grayscale while processing; response = color returns |
| Killed / disabled states (S6) | monochrome | "inactive" visual consistency on killed surfaces |
| Nocturne + High Contrast presets | monochrome | desaturated / high-contrast universes; the 10 expressive themes = colored version |
| Watermark / low-opacity backgrounds (QCM sheets, empty library) | monochrome at low opacity | grayscale never fights the content |
| Document exports (PDF/DOCX/PNG, infographics) | monochrome | print-friendly, neutral |
| 404 / not-found / feature-disabled (page center) | COLORED without-background, CENTERED | living empty state (primary CTA "Retour à l'accueil") = active brand; S9 page-center rule (§6.1 row 404) |
| In-app splash / onboarding / Home / store | colored (or full, external) | S9 default — unchanged |

FORBIDDEN: the full (background) version inside the app UI; the monochrome
version in a "living" empty state (primary CTA = active brand = colored);
any recolor.

Precision (blocking, DAPHNE-enforced — no ambiguity left):
- Monochrome mark = grayscale TONAL range #131B22 → #B9BABC (metallic),
  transparent background ONLY (S9: no background behind, no crop, no recolor).
- Watermark usage = a SINGLE application at 8% opacity over the content
  zone (never a gradient fill, never repeated tiles, never above text).
- Dark neutral style: the monochrome mark sits on `surface` (05 §2.1.3),
  NEVER on the raw #0A0E1A canvas; DAPHNE measures the mark's dominant
  tone vs that surface — blocking if < 3:1 (WCAG 1.4.3 non-text);
  fallback = render on the elevated `surface-alt` tone.
- Monochrome never animates outside §9.3 (the only animated monochrome
  usage in the product = AgentThinkingLoader).
- Per-version occurrence list is part of EVERY screen spec (template §13).

### 9.2 Monochrome in the bundle (C2PA + size)

`vs_monochrome_en_svg.svg` (owner-provided, 2026-09-27) ships with an
embedded C2PA manifest (Recraft AI provenance): ~140 Ko, of which the
bulk is a base64 blob inside `<metadata>`. The original stays the UNTOUCHED
SSoT (S9). For the bundler: a build step emits a STRIPPED copy (metadata
removed, art identical) — stripping metadata is NOT a redraw.
RESOLVED 2026-09-27 (owner feu vert): the stripped-copy approach is RATIFIED.
A build-time script (`scripts/strip-logo-metadata.mjs`) emits
`apps/mobile/.build/aurora-mono.stripped.svg` (gitignored — a generated
artifact, NOT a duplicated SSoT source). The originals in `assets/` are
NEVER modified. Bundle −~125 Ko; no provenance shipped to the device (AD-3).

### 9.3 `AgentThinkingLoader` — l'état « l'agent réfléchit » (IMPLEMENTED 2026-09-27)

- Owner decision 2026-09-27: NO three-dot / linear loader — the thinking
  state is an ORGANIC organism. Rejected: three dots, plain spinner.
- Component (DS, AD-10): `packages/ui/src/components/ui/AgentThinkingLoader.tsx`,
  exported from `@aurora/ui`. Test: `packages/ui/test/agent-thinking-loader.test.tsx`.
- Organic organism = 3 layered morphing SVG blobs (back/middle/front,
  staggered 2.6/3.4/4.2 s loops) — GPU ONLY (transform scale/rotate +
  opacity), no `layout` animations, no CPU-heavy filters (S5 mobile
  battery + 05 §2.6). Color = `--aurora-accent-primary-h` /
  `--aurora-accent-secondary-h` CSS vars → follows the active expressive
  theme; Nocturne / High Contrast desaturate automatically via token.
- The monochrome butterfly mark (stripped copy, §9.2) is a PROP
  (`butterfly`), rendered STATIC at center (S9: the mark is never
  redrawing/animated itself — the organism thinks, the brand stays calm).
  @aurora/ui stays asset-free (AD-1): the APP imports
  `apps/mobile/.build/aurora-mono.stripped.svg` and passes it.
- THINKING-WORDS layer (researched 2026-09-27 — Claude Code pairs its
  pulsing star with a rotating list of 184 thinking verbs "Pondering… /
  Ruminating… / Combobulating…" + a "Thought for Ns" elapsed chip; source:
  blog.alexbeals.com/posts/claude-codes-thinking-animation, 2026-02-07):
  a rotating line of thinking verbs (default `DEFAULT_THINKING_WORDS`, 12
  FR present-tense verbs mixing serious + one playful register, à la
  Claude's mix) that crossfades every `wordIntervalMs` (default 2400 ms).
  Fixed h-5 box = NO reflow; the rotator is aria-hidden and the SCREEN
  READER reads the STABLE `label` (no SR spam); reduced-motion = first
  word static. An optional `elapsedSeconds` chip renders "Réflexion · Ns"
  (Claude's "Thought for Ns" pattern — the APP owns the clock, the
  component only renders; mono + tabular-nums = no jitter).
- Props: `state` ("thinking" | "idle" | "exiting") · `butterfly`
  (ReactNode, optional) · `label` (STABLE screen-reader text, default
  "L'agent réfléchit…", 13 px/500 text-secondary) · `words`
  (rotating thinking-verbs, default `DEFAULT_THINKING_WORDS`; pass `[]`
  for the static label) · `wordIntervalMs` (default 2400) ·
  `elapsedSeconds` (optional "Réflexion · Ns" chip) · `size` (default
  88 px; 64–96 in chat). `exiting` = collapse + fade 200 ms ease-out
  when the response starts streaming.
- `prefers-reduced-motion` ON = fully STATIC organism + static mark
  (05 §2.6 rule 2); testable via `data-reduced-motion` /
  `data-thinking-state` attributes.
- A11y: `role="status"` + `aria-live="polite"`; the rotating words are
  `aria-hidden` and the SCREEN READER hears the stable `label` only;
  non-interactive (no touch target needed).
- S9 guardrail: the loader only TRANSFORMS existing vectors
  (scale / rotate / opacity / mask). ANY new stroke paths / simplified
  outline / decomposed wing groups = a NEW logo = FORBIDDEN (S9 "do NOT
  redraw").
- WING-FLAP SCOPE (owner decision 2026-09-27, "le battement d'aile
  organique sera compliqué" → v1 = breathing only):
  - v1 SHIPPED = the organic organism above (3 staggered GPU blobs; NO
    wing motion).
  - v2 (STRETCH, BLOCKED on an owner-provided asset): an organic
    left/right wing-flap is NOT achievable on the current SVG — it is a
    flat list of ~50 gradient-filled paths with NO independent wing
    groups / rotation axes, and S9 forbids restructuring the art. IF the
    owner later provides a DECOMPOSED variant (leftWing / rightWing /
    body groups + transform-origins, registered as a 5th S9 SSoT file),
    then per-group `rotate` about the body axis (GPU, 3–5° amplitude,
    1.2–1.6 s ease-in-out, reduced-motion = static). Until then: breathing.
- A stroke-dash "drawing" style is likewise BLOCKED on an owner-provided
  outline variant (a redraw — not allowed under S9 by default).
- In chat: 48–64 px mark + rotating thinking-verb line + optional
  "Réflexion · Ns" elapsed chip; non-interactive (no touch target needed).
  SIZING (owner 2026-09-28, écran agent-chat) : la ligne de mots + la
  chip sont à la TAILLE DU TEXTE DU CHAT (même corps que le streaming de
  réponse) — le loader s'insère inline, il ne surdimensionne pas la
  conversation. L'organisme reste 48 px à gauche (marque, pas texte).
- Contrast QA: the darkest gray (#131B22) must never sit on the raw
  #0A0E1A canvas — the loader sits on a `surface` in both neutral styles;
  DAPHNE verifies legibility (blocking if not).

### 9.3.1 Précisions owner (2026-09-28) — à respecter par TOUT agent UI

- **TOUS THÈMES SANS EXCEPTION** : le loader doit rester lisible sur les
  10 thèmes expressifs × {light, dark} × 3 presets (Nocturne, High
  Contrast, Slate) — zéro exception. Par construction : les blobs =
  `--aurora-accent-primary/secondary` uniquement (ils s'adaptent à tous
  les thèmes), le papillon = grayscale monochrome (lisible en light ET
  dark), les textes = tokens neutres (`text-secondary` / `text-muted`).
  DAPHNE check bloquant : rendu du loader sur les 13 combinaisons
  (10 + 3 presets) × 2 styles neutres.
- **BLANC PAR DÉFAUT, NOIR À LA DEMANDE** (owner 2026-09-28) : le style
  neutre par défaut est LIGHT (#F8FAFC) ; le DARK (#0A0E1A) n'apparaît
  QUE si l'utilisateur le choisit (settings, 05 §2.1 — jamais de
  bascule silencieuse au retour foreground). Le loader ne contient
  AUCUNE hypothèse de fond : il est identique en light et dark (tokens).
- **ACCENT ONLY — zéro couleur inutile** (owner 2026-09-28) : les thèmes
  existent UNIQUEMENT pour l'accentuation sur la base neutre blanche/noire.
  Le loader n'introduit AUCUNE nuance hors tokens : blobs = accent,
  papillon = gris, texte = neutre. Toute autre couleur = finding bloquant
  (règle S6 de DAPHNE).
- **INHALE (retouche 1, implémentée)** : à chaque changement de mot,
  l'organisme « inhale » (scale 1 → 1.04 → 1, 250 ms ease-in-out, GPU) —
  les deux couches de mouvement respirent ENSEMBLE. reduced-motion = pas
  de pulsation.
- **FLOAT DU MOT (retouche 2, implémentée)** : le mot sortant monte
  (−4 px) en s'estompant pendant que le suivant arrive depuis le bas
  (+4 px → 0), 200 ms, GPU (transform + opacity), boîtier h-5 fixe
  (zéro reflow). reduced-motion = swap sans animation.
- **CHIP REPLIABLE « Réflexion · Ns ▸ » (spécifié pour l'écran
  agent-chat, lot 6 DYAD — le composant n'expose que `elapsedSeconds`)** :
  à la fin de la réflexion, la chip devient une ligne repliable avec
  chevron (pattern Claude « Thought for 7s ») ; au clic elle révèle un
  court extrait de la réflexion (le `thinking` summary de l'agent,
  jamais la chaîne brute — claudelog: thinking blocks = brief summaries) ;
  a11y = bouton `aria-expanded` ; le chevron pointe vers le bas quand
  ouvert. L'organisme, lui, disparaît (état `exiting`).
