# 02 — Detect agent E (Performance): apps/mobile read-only findings

Input: `out/review/01-map.md`, `out/review/00-scoping.md`.
Scope: `apps/mobile/src/**` only (~4 900 lines, 21 routes). Read-only — no source was edited.
Method: every claim below was confirmed in-file (line numbers quoted from the source, not the Map).

## Summary

**6 findings: 0 Critical / 0 High / 1 Medium / 5 Low.** For an app this size, nothing here threatens frame rate or causes runaway re-rendering. The most concrete issue is the `useUiStateStore()` bare-call pattern (3 call sites) which defeats per-field subscription; the "all 21 pages in one bundle" framing is overstated (React tree-shakes unreachable JSX elements — only ~20 small component modules genuinely land in the entry chunk, not their heavy deps).

## Ranked findings

| # | severity | file:line | category | symptom | fix_hint | confidence |
|---|----------|-----------|----------|---------|----------|------------|
| 1 | Medium | `src/shell/AgentBus.tsx:17` | performance (state) | `const ui = useUiStateStore()` bare call subscribes to the entire store; every `set()` in it (incl. `toggleKnowledgeNode` writing a new `knowledgeExpanded` object on each tree click, `ui-state.ts:74`) re-renders the bus root and its `useEffect` re-runs `mountAgentCommandBus` (deps at `AgentBus.tsx:28-31`) — the most frequent store mutation in the app. | Subscribe to the 5 setter functions individually (they are referentially stable) instead of the whole store; drop the bare call. | 🟢 |
| 2 | Low | `src/pages/settings/index.tsx:54` | performance (state) | `useUiStateStore()` bare call (destructures `theme, setTheme, auroraTheme, setAuroraTheme`): Settings re-renders on unrelated store writes — `activeTab` changes on every tab switch, `knowledgeExpanded` on every tree click, `focusActive`, `killed`. | One selector per field (or `useShallow` over the 4 fields). | 🟢 |
| 3 | Low | `src/pages/focus/index.tsx:42` | performance (state) | `useUiStateStore()` bare call (destructures `focusActive, setFocusActive`): Focus re-renders on every store write including `activeTab` / `knowledgeExpanded`. | `useUiStateStore((s) => s.focusActive)` + `(s) => s.setFocusActive`. | 🟢 |
| 4 | Low | `src/pages/skills/index.tsx:181-195` | performance (render) | `filteredCatalog`, `personalSkills`, `catalogActivated` recomputed on every render of `SkillsPage`; on each keystroke in the catalog search box (lines 263-267) the whole page re-renders and `userSkills.filter` ×2 re-runs too. | Memoize the two `userSkills` filters on `[userSkills]` (like `activeKeys` at 66-69); `filteredCatalog` only if the catalog grows. | 🟢 |
| 5 | Low | `src/router.tsx:29` | performance (comment / hygiene) | Comment "17 pages. Each is a lazy boundary" is factually false — zero `React.lazy`/`Suspense` in `src/**`; Vite does not split features (no `manualChunks`), but React itself tree-shakes the unused JSX elements so only the 20 tiny component modules (~1-3 KB each pre-min, most files <120 lines) truly reach the entry chunk — Framer-Motion/SVG code, `lucide-react` icons, and the `@aurora/*` deps of unreached pages do NOT. | Delete or rewrite the comment ("static imports, all pages in one bundle"). | 🟢 |
| 6 | Low | `src/pages/goals/dashboard.tsx:209-238` | performance (render) | `WorkflowLines` rebuilds `byRow` + `pos` Maps and the `lines` array on every render, but `layout` is `useMemo`d in the parent and `layout === layout` in `AnimatePresence`'s child — the recomputation happens on unrelated parent re-renders. | `React.useMemo` keyed on `[layout]`. | 🟢 |

### Verified clean / NOT findings

- **`useAgentRun` poll (`src/query/agent-runs.ts:28-31`)** — confirmed the 3000 ms poll **does** stop: `refetchInterval` is a function returning `false` on `completed`/`failed`/`cancelled` (TanStack Query v5 = `refetchInterval: false` ⇒ interval disabled), `3000` otherwise. No runaway ticker. The transient "one extra poll" between a terminal fetch and the interval re-evaluation is framework behavior, not a defect.
- **`agent/index.tsx` per-render derivations** — `inFlightRow` (line 177) is a single guarded boolean expression; `entries` is `useState` state, not a per-render derivation; `MODEL_CATALOG`/`AGENT_MODES`/`RESEARCH_MODES`/`THINKING_LEVELS`/`DEFAULT_CONNECTORS` (lines 39-73) are module-level consts. Nothing to flag on the mission's item 2 for this file (its inline `onSubmit`/`onClick` closures are normal React and re-create on every render but are not measurable here).
- **`skills/index.tsx` `activeKeys` / `domains`** — correctly `useMemo`d (66-69, 174-177); the non-memoized ones are finding #4.
- **`useEffect` dep arrays** — all `useEffect`s in `src/pages/` + `src/query/` confirmed: `focus/index.tsx:74` (deps `[service]`, `service` is the `null` const from `router.tsx:90` → runs once, fine), `agent/index.tsx:129,143` (deps `[runRow, activeRun]`, both correct — no stale closures), `integrations/index.tsx:66`, `skills/index.tsx:89` (`[loadAll]`, `loadAll` is `useCallback([skills])`), `floating.tsx:43`, `theme-adapter.tsx:80`, `use-online.ts:17`, `use-killed.ts:21` — none have missing/stale deps or over-broad deps causing re-fetches. No `refetchInterval` anywhere else in `src/**` (single grep match = agent-runs only).
- **O(n²) / missing `key` on `.map()`** — across all `src/pages/` + `src/ux/`: 0 missing `key` (checked `skills`, `agent`, `dashboard`, `ascent`, `tasks`, `calendar`, `home`, `learn`, `inbox`, `progress`, `settings`, `integrations`, `projects`, `floating.tsx:90`). No O(n²) list rendering in `focus/index.tsx` (only `FOCUS_SOUNDS.filter` per render, 25 items × per-render, below threshold) or `goals/dashboard.tsx`.
- **`focus-sounds.ts` / other per-render statics** — `FOCUS_SOUNDS`/`FOCUS_SOUND_THEMES` are module consts; `selectThemeSound`'s `find()` over 25 items on select-change is negligible.
- **Store-wide subscriptions elsewhere** — `knowledge/index.tsx:30` does `JSON.stringify(useUiStateStore((s) => s.knowledgeExpanded))` — an intentional string-snapshot trick for React.memo; it re-renders only when expansion state changes (correct, not a defect). `progress/index.tsx:27-29`, `learn/index.tsx:32`, `discovery/index.tsx:18`, `artifacts/index.tsx:24`, `main.tsx:114-116` all use field selectors — clean.
- **`build.rollupOptions.output.manualChunks`** — `vite.config.ts` has no chunk config; but per the analysis under finding #5, that is *not* a measurable problem for this app (React tree-shaking already keeps unreached pages' heavy deps out of the entry chunk; total app surface is ~4 900 lines). No finding issued for its absence.

### 🔴-confidence check

No 🔴 findings: every claim above was verified directly in the cited file/line; the only judgment call is the tree-shaking assessment in #5 (stated with the mechanism, not just "all pages in the bundle").
