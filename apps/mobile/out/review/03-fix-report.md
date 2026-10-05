# 03 — Fix report (Mode 2, ionic-react-capacitor)

Date : 2026-10-05 — agent Fix. Scope validé : le set technique de 9 findings.
Les décisions 🔴 de scope mort (suppression / branchement des fichiers
orphelins) ne sont PAS incluses ici. CWD : `apps/mobile`.

## Fixes appliqués

### B1 — Faux picker de fichiers — `src/pages/agent/index.tsx`
- Supprimé le bloc `Fichiers…` du `+` sheet (bouton « Ajouter un fichier »
  qui fabriquait `fichier-N.pdf` fictifs + chip `files.map`).
- Supprimé le chip `{files.length > 0 && …}` des `agent-active-chips`.
- Supprimé le `useState<string[]>([])` de `files` + le `setFiles([])` de
  `submit()` (la seule autre utilisation dans le fichier) ; remplacé par le
  commentaire `// files: local surface state — kernel not yet wired
  (wave-N, see docs/kernel §files)`.
- `FilePlus` (lucide) retiré de l'import (nulle autre occurrence) ; le header
  comment du fichier et les commentaires « files / connectors / research »
  du composant mis à jour pour rester honnêtes (la section Fichiers
  n'existe plus).

### B2 — CTA « Capturer » qui perd l'input — `src/pages/inbox/index.tsx`
Option A (recommandée).
- Retiré le button `Capturer` (qui faisait `setDraft('')` — le texte était
  perdu, l'utilisateur croyait que c'était classé) ; remplacé par le badge
  `<span className="aurora-badge">Capture en cours de wiring</span>` (badge
  existant de `atoms.css`).
- Le textarea ne se vide plus : c'est un draft relisible. `captured[] = []`
  conservé (guard de l'état vide « Inbox vide — tout est classé », état
  honnête actuel). Import `Plus` retiré (plus utilisé).

### C1 — « Tout connecter » : 5 `window.open` simultanés — `src/pages/integrations/index.tsx`
- Factorisation `connectOne(id): Promise<void>` (ex-`toggle`), `toggle`
  devenu un wrapper.
- Flag `inFlight: Set<string>` (`useState`) : le preset button
  `disabled={inFlight.size > 0}`, chaque toggle individuel
  `disabled={inFlight.has(id)}` (cartes Google + carte Spotify).
- Preset : `google.forEach((g) => toggle(g.id))` →
  `Promise.allSettled(google.map((g) => connectOne(g.id)))`.
- Rejets non écrasés : le `.catch` de `connectOne` appelle
  `setConnectError(`${label} : ${e.message}`)` (ex. `Docs : erreur`) — chaque
  échec est nommé par item, plus de `setConnectError(null)` mutualisé qui
  effaçait l'erreur du premier item.

### C2 — Rejections non gérées — `src/pages/skills/index.tsx` (+ L-C7)
- Toggle personal (ex-L.419-424) : `try/catch` autour de
  `deactivateSkill/activateSkill + listUserSkills`, catch →
  `setLoadError(e instanceof Error ? e.message : 'action skill en échec')`.
- Désactivation catalog (ex-L.451-454) : même pattern.
- `deletePersonalSkill` (ex-L.122-129, L-C7) : `deleteUserSkill` enveloppé de
  `try/catch` → `setLoadError(… 'suppression du skill en échec')`.

### D1 — A11y des 2 overlays agent — `src/pages/agent/index.tsx`
- Sur les 2 dialog (`agent-model-picker-modal`, `agent-plus-sheet`) :
  `aria-modal="true"` (en plus du `role="dialog"` + `aria-label`
  existants).
- `onMouseDown` sur le nœud conteneur (scrim) : `e.target === e.currentTarget`
  → fermeture (pattern `src/ux/floating.tsx`).
- `useEffect` (à côté des autres) : quand `showPicker || showPlusSheet`,
  listener `keydown` → `Escape` ferme les deux ; cleaner inverse.
- Set minimum approuvé : pas de focus-trap complet, pas d'`inert` sur le
  fond (scope exclu par le panel ; la D5 low n'est pas dans le set).
  Note : le ref de nœud dialog demandé par la spec a été retiré car
  inexploitable sans focus-trap — le set utile complet est Escape +
  scrim-click + `aria-modal`.

### D2 — Garde mutuelle 1 ligne — `src/pages/agent/index.tsx`
Scénario minimal (verdict panel « Low, garde 1 ligne ») :
- L.343 (swipe gauche → plus sheet) : `setShowPicker(false)` avant
  `setShowPlusSheet(true)`.
- L.355 (pull-down → picker) : `setShowPlusSheet(false)` avant
  `setShowPicker(true)`.
- L.556 (chip `+`) : `setShowPicker(false)` + `setShowPlusSheet(true)`.
- L.600 (trigger Cpu) : `setShowPlusSheet(false)` + `setShowPicker(true)`.
→ plus de stack de 2 `role="dialog"` : chaque ouverture verrouille l'autre.

### D3 — A11y tabs skills + agent
`src/pages/skills/index.tsx` (tab strip L.205-224) :
- Chaque tab button : `id={tab-${t}}`, `tabIndex={tab === t ? 0 : -1}`
  (roving), `aria-controls={panel-${t}}`, `onKeyDown` gérant
  `ArrowRight/ArrowLeft/Home/End` (focus + changement de tab).
- Les 3 corps conditionnels (`tab === 'catalog'/'personal'/'expert'`) :
  `role="tabpanel"`, `id={panel-${t}}`, `aria-labelledby={tab-${t}}`,
  `tabIndex={0}`.

`src/pages/agent/index.tsx` (tab strip L.404-419) — fix minimal, panel
partagé :
- Les 3 tabs : `id={tab-${m.id}}`, roving `tabIndex`, `aria-controls`
  pointant tous vers `agent-transcript` (le panel unique, qui a reçu
  `id="agent-transcript"`), `onKeyDown` arrow/Home/End (focus + cycle de
  mode).
- `agent-transcript` : `role="tabpanel"` + `aria-labelledby={tab-${agentMode}}`
  + `tabIndex={0}`.

### D4 — A11y tabs focus — `src/pages/focus/index.tsx`
- Sub-mode tabs (Pomodoro/Chrono) : `id` + roving `tabIndex` + `onKeyDown`
  (ArrowLeft/Right/Home/End → bascule sur l'autre tab + focus),
  `aria-controls` conditionnel (`panel-pomodoro`/`panel-chrono`, seulement
  sur le tab actif — les 2 corps ne coexistent jamais).
- Les 2 corps : `role="tabpanel"` + `id` + `aria-labelledby` + `tabIndex={0}`.
- Sound themes (5 tabs) : `id={tab-theme-${t.id}}` + roving `tabIndex` +
  `onKeyDown` (ArrowRight/Left/Home/End → cycle des 5 thèmes, focus, +
  selection du premier son du thème), `aria-controls="panel-sound-themes"`
  sur les 5.
- Panel partagé = le `select` de son qui suit le strip : `role="tabpanel"` +
  `id="panel-sound-themes"` + `aria-labelledby={tab-theme-${activeTheme}}` +
  `tabIndex={0}`.

### F1 — Header SSoT trompeur — `src/pages/integrations/index.tsx`
Les 3 lignes du header (« the UI NEVER invents a toolkit/tool slug — the
runtime catalog is the SSoT ») remplacées par le commentaire honnête
approuvé par le panel :
```
 * The 9 CONNECTORS below are a static device-side subset of the v3.1 toolkit
 * catalog (composio-analysis.md §2). discoverTools() (lib/integrations-client.ts:47)
 * is the SSoT runtime seam — it is NOT wired yet (wave-N); the server EF
 * (fn-integrations) validates every toolSlug against the live session catalog
 * before execution, so a stale slug in this array cannot corrupt data.
```
(Correctif de commentaire seulement — pas de fix fonctionnel, forme unique
viable du finding F1 après reformulation.)

## Résultats des commandes (verbatim)

`pnpm --filter @aurora/mobile typecheck` :
```
> @aurora/mobile@0.0.0 typecheck C:\Users\joyda\dyad-apps\aurora-2\apps\mobile
> tsc --noEmit -p tsconfig.json && tsc --noEmit -p tsconfig.capacitor.json
```
→ **exit 0, clean.**

`pnpm --filter @aurora/mobile lint` :
```
> @aurora/mobile@0.0.0 lint C:\Users\joyda\dyad-apps\aurora-2\apps\mobile
> eslint src capacitor.config.ts --max-warnings 0
```
→ **exit 0, clean** (0 warning, `--max-warnings 0`).

`pnpm --filter @aurora/mobile build` :
```
> @aurora/mobile@0.0.0 build C:\Users\joyda\dyad-apps\aurora-2\apps\mobile
> tsc -p tsconfig.build.json
```
→ **échec (exit 2) — PRÉEXISTANT, non causé par ces 9 fixes.**
Tous les errors sont dans `../../packages/ui/src/renderers/*`
(hors scope `apps/mobile/src/**`) :
```
contracts.ts(163,32): error TS2307: Cannot find module 'src/themes/types'
contracts.ts(166,16): error TS2307: Cannot find module 'src/themes/types'
DataVisualizationRenderer.tsx(13,20): error TS2307: Cannot find module 'src/lib/utils'
DataVisualizationRenderer.tsx(15,34): error TS2307: Cannot find module 'src/theme/provider'
DataVisualizationRenderer.tsx(28,54): error TS7006: Parameter 'v' implicitly has an 'any' type
DataVisualizationRenderer.tsx(170,21): error TS7006: Parameter 'v' implicitly has an 'any' type
index.ts(35,32): error TS2307: Cannot find module 'src/themes/types'
index.ts(57-61,27..30): error TS2307: Cannot find module 'src/components/ui/{DataTable,KeyValueList,Timeline,GanttRow,StatTile}'
InfographicRenderer.tsx(16,20): error TS2307: Cannot find module 'src/lib/utils'
MathRenderer.tsx(15,20): error TS2307: Cannot find module 'src/lib/utils'
SemanticTreeRenderer.tsx(27,20): error TS2307: Cannot find module 'src/lib/utils'
SemanticTreeRenderer.tsx(33,20): error TS2307: Cannot find module 'src/theme/provider'
SemanticTreeRenderer.tsx(99,79): error TS2307: Cannot find module 'src/perf/layout-core'
SemanticTreeRenderer.tsx(107,40): error TS7006: Parameter 'p' implicitly has an 'any' type
SemanticTreeRenderer.tsx(113,24): error TS2339: Property 'x' does not exist on type '{}'
SemanticTreeRenderer.tsx(113,32): error TS2339: Property 'y' does not exist on type '{}'
SemanticTreeRenderer.tsx(312,60): error TS2307: Cannot find module 'src/perf/layout-core'
SemanticTreeRenderer.tsx(313,32): error TS2307: Cannot find module 'src/perf/layout-core'
ERR_PNPM_RECURSIVE_RUN_FIRST_FAIL @aurora/mobile@0.0.0 build: `tsc -p tsconfig.build.json`
Exit status 2
```

**Preuve que c'est préexistant** : `git stash` des 9 fichiers modifiés →
rebuild → le même échec `packages/ui` se produit (exit 2 identique) sans
aucune de mes modifications en place → `git stash pop` (tout restauré,
vérifié par `git status`). Le problème est un défaut de résolution de
modules dans `packages/ui` (`tsconfig.build.json` résout les chemins de
celui-ci différemment de `tsconfig.json`/`tsconfig.capacitor.json`, qui
passent clean) — hors scope, non corrigé par consigne.

## Ce qui n'a PAS été touché
- Les 9 questions 🔴 de scope mort (suppression / branchement des fichiers
  orphelins) — exclues par la spec.
- B3 / L-A4, C5 / C6 — findings hors du set technique validé.
- Les findings Low non-fixés du même pass (notamment D5 du fichier agent :
  focus-trap complet + `inert` sur le fond — le panel a marqué D1 « set
  minimum » et D5 Low).
- Tout `packages/**`, `supabase/**`, `.env*`, `capacitor.config.ts` — hors
  scope.
- `apps/mobile/src/main.tsx`, `knowledge/index.tsx`, `query-client.ts`,
  `styles/*.css` — modifiés antérieurement (état du working tree au début
  de la session), non touchés par ce fix.

## Anomalies préexistantes rencontrées
- Build `tsc -p tsconfig.build.json` cassé par les chemin de résolution de
  `packages/ui/src/renderers/*` (listé plus haut) — préexistant, prouvé par
  stash/rebuild/restore, non corrigé (hors scope `apps/mobile/src/**`).
- Rien d'autre : type-check (`tsconfig.json` + `tsconfig.capacitor.json`) et
  lint (`--max-warnings 0`) passent clean avec les 9 fixes en place.
