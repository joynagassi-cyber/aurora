# Mode 2 — Passage 2 : suppression du code mort (Q1–Q6, scénario « delete »)

Cible : `apps/mobile` (CWD `C:\Users\joyda\dyad-apps\aurora-2\apps\mobile`).
Toutes les suppressions ci-dessous ont été **précédées d'un grep de vérification
confirmant l'absence de consommateur live restant**. Zéro STOP rencontré.

## 1. Suppressions de fichiers (11 fichiers)

### Q1 (A1) — concentration (orphan non routée, SEED hardcoded, CSS jamais importée)
- `src/pages/agent/concentration.tsx`
- `src/styles/concentration.css`
- **Grep de vérification** : `grep -rn "concentration\|ConcentrationProfilesPage" src/ test/`
  → les hits sont le fichier lui-même, sa CSS, `src/lib/focus-sounds.ts` (commentaire
  « sons de concentration » — sans rapport), `src/pages/focus/index.tsx` (commentaire
  UI « Son de concentration » — sans rapport), et **uniquement des artefacts**
  `dist/` (stale, gitignored). Aucune référence dans `src/main.tsx`, `src/router.tsx`,
  ni dans `src/pages/agent/index.tsx`. Le composant `ConcentrationProfilesPage` n'a
  **aucun importeur** dans `src/**` (confirmation : grep global, seul hit = `dist/`).
- **Aucune ligne d'import à retirer** dans `main.tsx` (non importé), aucune route à
  retirer dans `router.tsx` (non référencé).

### Q2 (A2) — command palette (trio)
- `src/components/ui/command.tsx`
- `src/components/ui/dialog.tsx`
- `src/modes/command-palette.ts`
- **Grep de vérification** : `grep -rn "command.tsx\|dialog.tsx\|command-palette\|ui/command\|ui/dialog\|modes/command-palette" src/ test/`
  → hits : `src/index.ts:35` (re-export, supprimé au Q6), `src/modes/command-palette.ts`
  (commentaire interne pointant vers `command.tsx` — les 2 supprimés ensemble),
  `test/product-modes.test.ts:22` (supprimé au Q3). `command.tsx` importait
  `dialog.tsx` (les 2 partagent le même sort). **Aucun fichier restant** n'importe
  `ui/command` ou `ui/dialog`.
- **Prune de dep `@radix-ui/react-dialog`** : `grep -rln "@radix-ui/react-dialog" src/ test/`
  → seul consommateur = `src/components/ui/dialog.tsx` (supprimé). La dep est
  prunée de `package.json` (voir §2). C'était le seul consommateur, pas d'ambiguïté.

### Q3 (A3) — product-modes
- `src/modes/product-modes.ts`
- `test/product-modes.test.ts`
- **Grep de vérification** : `grep -rn "product-modes\|PRODUCT_MODES\|MODE_PROFILES\|getModeProfile\|effectiveEmphasis" src/ test/`
  → hits : `src/index.ts:22-29` (re-exports, supprimé au Q6), `test/product-modes.test.ts`
  (supprimé), le fichier lui-même. **Aucun autre fichier restant** n'importe
  `product-modes`. Le test couvrait aussi `command-palette` (Q2) — supprimé ensemble.

### Q4 (A4) — toast
- `src/components/ui/toast.tsx`
- **Grep de vérification** : `grep -rn "Toast\|toast.tsx" src/ test/`
  → hits : `toast.tsx` lui-même, `src/styles/floating.css` (commentaire de
  z-index « Toast / snackbar z-50 » — sans rapport, non supprimé), et
  `src/ux-states.tsx:8` (**commentaire header** « success → Toast (auto-dismiss 3s) —
  surfaced via the toaster »). `ux-states.tsx` ne **n'importe pas** `toast.tsx` —
  c'est un commentaire de référence. Conformément à la consigne : le commentaire est
  laissé tel quel. **À signaler (non fixé, pas de consigne)** : le header de
  `src/ux-states.tsx:8` est désormais trompeur (il décrit un `Toast` qui n'existe
  plus). Ne PAS modifié ici — signalé pour trancher ultérieurement.

### Q5 (A5) — polish
- `src/ux/polish.tsx`
- **Grep de vérification** : `grep -rn "polish.tsx\|PageTransition\|NodePulse\|Reveal\|PAGE_TRANSITION\|REVEAL_TRANSITION" src/ test/`
  → hits : uniquement `polish.tsx` lui-même. `src/pages/goals/dashboard.tsx` et
  `src/ux/theme-adapter.tsx` consomment `motion/react` **directement** (grep confirmé
  « from 'motion/react' ») — **PAS** via `polish.tsx`. Aucune dépendance restante.

### Q6 (L-A9) — façade + pipeline build
- `src/index.ts`
- `tsconfig.build.json`
- **Grep de vérification monorepo-wide** : `grep -rn "@aurora/mobile" apps/ packages/ supabase/functions scripts/`
  → **0 importeur** (le panel a confirmé ; re-vérifié). Les seules références à
  `@aurora/mobile` sont : le `name` de `apps/mobile/package.json` lui-même, le script
  `dev` du root (`pnpm -F @aurora/mobile dev` — le lance comme app, pas import), et
  l'alias self-build de `apps/mobile/vite.config.ts:51` (pointe vers `./src`, pas un
  consommateur externe). **Aucun consommateur de la façade.**
- **`tsconfig.build.json` référencé QUE par le script `build`** :
  `grep -n "tsconfig.build.json" package.json` → `package.json:18` :
  `"build": "tsc -p tsconfig.build.json"`. Ce script est **retiré** de
  `package.json` (voir §3). Aucune autre référence tooling (CI, editorconfig) :
  le grep global confirme que les seuls hits dans le code live sont
  `package.json` (le script, retiré) + un **commentaire** dans
  `src/perf/measure.ts:3` (non bloquant, non touché) + les artefacts `out/`/`dist/`
  et `.claude/worktrees`/`.dyad/chats` (historique, hors scope).
- **`tsconfig.json` (typecheck) ne pointe PAS sur `src/index.ts`** :
  `tsconfig.json` a `"include": ["src"]` (tout le dossier, pas le fichier) et
  `"exclude": ["dist"]`. La suppression de `src/index.ts` n'a aucun impact sur le
  `include` du typecheck — confirmé par le typecheck qui passe (exit 0, §4).

## 2. Prunes de `package.json` (dependencies)

Deux deps mortes prunées (chaque une confirmée consommée UNIQUEMENT par le fichier
supprimé) :
- `@radix-ui/react-dialog: ^1.1.23` — seul consommateur : `ui/dialog.tsx` (Q2, supprimé).
- `@radix-ui/react-toast: ^1.2.23` — seul consommateur : `ui/toast.tsx` (Q4, supprimé).

Les autres deps `@radix-ui/react-*` (`react-dropdown-menu`, `react-slot`) **sont
laissées en l'état** : elles n'avaient pas non plus de consommateur dans `src/` au
moment de la vérification (grep `@radix-ui/react-dropdown-menu` et
`@radix-ui/react-slot` = 0 hits dans `src/`/`test/`). **Non prunées par décision** —
elles ne figurent pas dans le périmètre du message (seuls `react-toast` (Q4) et
`react-dialog` (Q2, si seul consommateur) étaient en scope). Signalé ci-dessous
comme finding bonus.

## 3. Champs `package.json` retirés (façade lib + build)

- `"main": "src/index.ts"` — **retiré**
- `"types": "src/index.ts"` — **retiré**
- `"exports": { ".": { "types": "./src/index.ts", "default": "./src/index.ts" } }` — **retiré**
- `"build": "tsc -p tsconfig.build.json"` — **retiré**

Raison : `@aurora/mobile` est une app exécutable (entry `src/main.tsx`, host
`index.html`), pas une lib. 0 consommateur externe de la façade. Le script `build`
émettait uniquement des `.d.ts` (`emitDeclarationOnly`) pour les refs composites —
pipeline mort dès que `src/index.ts` disparaît. Les scripts gardés : `typecheck`,
`lint`, `dev` (vite), `build:web` (vite build).

## 4. Validation (verbatim)

### Avant `pnpm install` (juste les suppressions + package.json)
```
$ pnpm typecheck
> @aurora/mobile@0.0.0 typecheck C:\Users\joyda\dyad-apps\aurora-2\apps\mobile
> tsc --noEmit -p tsconfig.json && tsc --noEmit -p tsconfig.capacitor.json

TYPECHECK_EXIT=0

$ pnpm lint
> @aurora/mobile@0.0.0 lint C:\Users\joyda\dyad-apps\aurora-2\apps\mobile
> eslint src capacitor.config.ts --max-warnings 0

LINT_EXIT=0
```

### `pnpm install` (re-sync du lockfile après les prunes)
Le lockfile était out-of-sync (les 2 deps prunées). `CI=true pnpm install` a d'abord
échoué sur `frozen-lockfile` (comportement CI par défaut), puis ré-usé avec le flag :
```
$ CI=true pnpm install --no-frozen-lockfile
  + @radix-ui/react-dropdown-menu 2.1.24
  ... (deps restantes)
  - @radix-ui/react-dialog   (retrait)
  - @radix-ui/react-toast    (retrait)
Done in 4m 19.5s using pnpm v10.28.0
PNPM_INSTALL_EXIT=0
```

### Après `pnpm install` (re-run, gate final)
```
$ pnpm typecheck
TYPECHECK_EXIT=0

$ pnpm lint
LINT_EXIT=0
```

Les deux gates passent **avant ET après** `pnpm install`. Le lockfile est
ré-syncé (les 2 deps retirées du lockfile).

### Build (`pnpm --filter @aurora/mobile build`) — NON re-exécuté, **signalement**
Conformément à la consigne, le build n'a PAS été re-exécuté. À noter : le script
`build` (`tsc -p tsconfig.build.json`) est **supprimé** dans `package.json` (façade
lib morte, Q6). Le build préexistant (échec sur `packages/ui`, hors scope) concernait
le script de typecheck/declaration — le pipeline `tsconfig.build.json` est désormais
retiré du projet mobile. La seule commande build restante côté mobile est
`build:web` (Vite), pas le `tsc -p tsconfig.build.json` historique.

## 5. STOP rencontrés
**Aucun.** Chaque fichier supprimé avait un consommateur au maximum dans
`src/index.ts` (façade, Q6 — supprimée ensemble) ou dans le test Q3
(supprimé ensemble). Aucun consommateur live restant ne bloquait une suppression.

## 6. Ce qui n'a PAS été touché (out-of-scope / signalements)

- **Q7/Q8/Q9 (C1 / D2 / L-A4)** — les 3 dernières questions 🔴 du 1er passage :
  déjà fixées au passage 1 (scénario minimal, B3/C5/C6, D5). Non re-tentatives ici.
- **`src/ux-states.tsx:8`** — le header commente « success → Toast (auto-dismiss 3s)
  — surfaced via the toaster ». Désormais trompeur (le Toast est supprimé). **Non
  modifié** (pas de consigne) — signalé en Q4.
- **`src/perf/measure.ts:3`** — commentaire fait référence à `tsconfig.build.json`
  (maintenant supprimé). Non modifié — commentaire historique.
- **`@radix-ui/react-dropdown-menu` / `@radix-ui/react-slot`** — 0 consommateur dans
  `src/`, mais **pas en scope du message** (seuls `react-toast` et `react-dialog`
  étaient prunables). Laissez en l'état — candidate pour une passe future.
- **Artifacts `apps/mobile/.build/`, `dist/` (dont `dist/index.d.ts`)**, et
  `.env.example` (untracked) — hors scope.
- **`packages/**`, `supabase/**`, `.env*`, `capacitor.config.ts`** — hors scope, non touchés.

## 7. État final (git status)
- Modifiés : `package.json` (prunes + champs/façade retirés).
- Supprimés : les 11 fichiers de §1 (concentration.tsx/.css, command.tsx, dialog.tsx,
  command-palette.ts, product-modes.ts, product-modes.test.ts, toast.tsx, polish.tsx,
  index.ts, tsconfig.build.json).
- Touchés au passage 1 (non re-modifiés ici) : `src/main.tsx`, `src/pages/*/index.tsx`,
  `src/query/query-client.ts`, `src/styles/*.css` — déjà commités du passage 1.
