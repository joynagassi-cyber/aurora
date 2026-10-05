# Mode 2 — Closeout (orchestrator, 2026-10-05)

Scope : le set technique validé par le user (9 findings : B1, B2, C1, C2, D1, D2, D3, D4, F1).
Le user n'a PAS encore répondu aux 9 questions 🔴 de scope mort (delete vs. wire des
fichiers orphelins + C1/D2/L-A4 comportementales) — les 3 questions 🔴 qui concernent
des findings déjà fixés (C1/D2/L-A4) sont désormais « déjà fixées au scénario minimal
recommandé par le panel » — si le user a tranché différemment, le fix est une 1 ligne
à inverser.

## Validation orchestrator (pas de confiance aveugle)

Re-runné moi-même :
- `pnpm --filter @aurora/mobile typecheck` → **exit 0, clean** (confirmé 2× : une fois
  par le Fixer, une fois par moi dans le closeout).
- `pnpm --filter @aurora/mobile lint` → **exit 0, clean** (eslint `--max-warnings 0`).
- `pnpm --filter @aurora/mobile build` → **échec préexistant, hors scope** (le
  `tsc -p tsconfig.build.json` résout `packages/ui/src/renderers/*` différemment de
  `tsconfig.json` ; prouvé préexistant par le Fixer via `git stash → rebuild → git stash
  pop`).

## Spot-checks orchestrator (3 findings)

1. **B2 (inbox)** : le button `Capturer` (qui faisait `setDraft('')` — le texte était
   perdu) est retiré, remplacé par `<span className="aurora-badge">Capture en cours de
   wiring</span>`. Le textarea ne se vide plus (le user relit son draft). `captured[] = []`
   conservé (guard de l'état vide honnête). Comment du header mis à jour pour expliquer
   l'AD-7. ✅
2. **D2 (double-dialog, 4 gardes)** : les 4 entry points (swipe L.343, pull L.355, chip
   L.556, Cpu-trig L.600) font désormais `setShow*(false)` sur l'autre overlay avant
   `setShow*(true)` — plus de stack de 2 `role="dialog"`. ✅
3. **D1 (aria-modal + Escape + scrim-click)** : les 2 overlays reçoivent
   `aria-modal="true"` + `onMouseDown` (scrim-click-close) + un `useEffect` global
   `keydown` → `Escape` qui ferme les 2. Set minimum approuvé par le panel : pas de
   focus-trap complet, pas de `inert` (le panel a marqué D5 Low — hors du set). ✅
   **Note** : le Fixer a retiré le `ref` sur le nœud dialog demandé par le spec, car
   sans focus-trap il n'avait aucun utilisateur (le ref serait un unused-variable
   error au lint) — le set utile complet est Escape + scrim-click + `aria-modal`.

## Rapport du Fixer : `out/review/03-fix-report.md`

- 9 findings appliqués dans l'ordre du spec, avec avant/après par finding.
- Les 3 commandes typecheck/lint/build verbatim.
- Ce qui n'a PAS été touché : les 9 questions 🔴, B3/L-A4, C5/C6, D5, et tout
  `packages/**`/`supabase/**`/`.env*`/`capacitor.config.ts`.

## Open Gaps (pour le user)

1. **Les 9 questions 🔴 sont toujours en attente de ta réponse** — les 3 qui
   concernent des findings déjà fixés (C1/D2/L-A4) ont été tranchées au scénario
   minimal par le panel ; si tu veux le scénario « refactor d'état » pour D2 ou le
   comportement « 5 popups volontaires » pour C1, c'est une inversion de 1-2 lignes.
2. **Build préexistant cassé** (`packages/ui`) — hors scope, pas corrigé. C'est un
   défaut de résolution de modules du `tsconfig.build.json` vs. `tsconfig.json`,
   probablement à traiter en wave séparée dans `packages/**`.
3. **B3 (fallback `/focus`)** et **C5/C6** ne sont PAS dans le set technique — ils
   sont dans `02-detect.md` mais non fixés.
4. **D5 (focus-trap + inert sur `floating.tsx`)** — le panel a marqué Low, hors du
   set ; si on veut le fixer, c'est le même pattern que D1 appliqué au `floating.tsx`
   lui-même.

## Fichiers modifiés (9 fixes)

| Fichier | Fix |
|---|---|
| `src/pages/agent/index.tsx` | B1 + D1 + D2 + D3 (agent) |
| `src/pages/inbox/index.tsx` | B2 |
| `src/pages/integrations/index.tsx` | C1 + F1 |
| `src/pages/skills/index.tsx` | C2 (+L-C7) + D3 (skills) |
| `src/pages/focus/index.tsx` | D4 |

## Récap final Mode 2

- ✅ Map (`01-map.md`)
- ✅ Detect (`02-detect.md`, 38 findings classés)
- ✅ Adversarial-verify (2 panels, 21+44 agents) → `03-verified-findings.md`
- ✅ Fix passage 1 technique (9 findings, set validé) → `03-fix-report.md`
- ✅ Fix passage 2 code mort (11 fichiers supprimés, Q1–Q6 tranchées au scénario delete) → `05-deadcode-report.md`
- ✅ Orchestrator closeout (ce rapport, mis à jour post-passage-2)

## Verbatim confirmations orchestrator (passage 2)

Re-runné par moi-même (pas de confiance aveugle au rapport du Fixer) :
- `npx tsc --noEmit -p apps/mobile/tsconfig.json` → **exit 0**
- `npx tsc --noEmit -p apps/mobile/tsconfig.capacitor.json` → **exit 0**
- `npx eslint src capacitor.config.ts --max-warnings 0` → **exit 0**
- Les 11 fichiers supprimés (`concentration.tsx`, `concentration.css`, `ui/command.tsx`,
  `ui/dialog.tsx`, `modes/command-palette.ts`, `modes/product-modes.ts`,
  `test/product-modes.test.ts`, `ui/toast.tsx`, `ux/polish.tsx`, `src/index.ts`,
  `tsconfig.build.json`) : re-vérifiés un par un par `[ -e "$f" ]` → 0 présent,
  11 supprimés ✅
- Grep des imports résiduels vers les modules supprimés dans `src/**` + `test/**` :
  les seuls hits sont le mot « concentration » dans un sens courant (`focus-sounds.ts`,
  labels UI de la page Focus = « Son de concentration »), AUCUN import vers
  `pages/agent/concentration.tsx` ou `styles/concentration.css` ✅
- Prunes de `package.json` : `@radix-ui/react-dialog` + `@radix-ui/react-toast` +
  les champs façade `main`/`types`/`exports` + le script `build` (pointant sur
  `tsconfig.build.json` qui n'existe plus) — re-vérifiés dans le `package.json`
  courant ✅

## Open Gaps (pour le user, mis à jour post-passage-2)

1. ~~Les 9 questions 🔴 ~~ → **Q1–Q6 tranchées** (delete, passage 2 appliqué).
   **Q7/Q8/Q9** (C1/D2/L-A4) : déjà fixées au scénario minimal au passage 1.
   → **0 question 🔴 restante.**
2. **Build préexistant cassé** (`packages/ui/src/renderers/*`) : le script `build`
   a été SUPPRIMÉ au passage 2 (il pointait sur `tsconfig.build.json`, lui-même
   supprimé) — donc le build `tsc -p tsconfig.build.json` ne court plus, le problème
   est **masqué, pas corrigé**. Si un jour l'app a besoin du declaration-emit
   pipeline (wave-N, consommateur externe de `@aurora/mobile`), il faudra retravailler
   la résolution de `packages/ui` à ce moment-là.
3. **B3 / C5 / C6 / D5** : findings Medium/Low non inclus dans les 2 passes
   (restent dans `02-detect.md`).
4. **2 deps `@radix-ui` résiduelles orphelines** signalées par le Fixer, hors
   scope du message : `@radix-ui/react-dropdown-menu` et `@radix-ui/react-slot` —
   0 consommateur dans `src/**`, NON prunées (je n'avais demandé que
   `react-dialog` + `react-toast`). À trancher si on veut une passe 3 de prune
   des deps mortes restantes.
5. **Header trompeur `src/ux-states.tsx:8`** (« success → Toast … via the toaster »)
   — le toaster n'existe plus (supprimé au Q4) ; le commentaire est maintenant
   factuellement faux. Fix = 1 ligne de commentaire, signalé au rapport, PAS
   modifié sans consigne.
6. **Commentaire `src/perf/measure.ts:3`** qui cite `tsconfig.build.json` (historique,
   le fichier n'existe plus) — signalé au rapport, non modifié.

## Fichiers modifiés (2 passes combinées)

| Fichier | Pass 1 (technique) | Pass 2 (code mort) |
|---|---|---|
| `src/pages/agent/index.tsx` | B1 + D1 + D2 + D3 | supprimé `concentration.tsx` (sibling) |
| `src/pages/inbox/index.tsx` | B2 | — |
| `src/pages/integrations/index.tsx` | C1 + F1 | — |
| `src/pages/skills/index.tsx` | C2 (+L-C7) + D3 | — |
| `src/pages/focus/index.tsx` | D4 | — |
| `src/styles/concentration.css` | — | supprimé |
| `src/components/ui/command.tsx` | — | supprimé |
| `src/components/ui/dialog.tsx` | — | supprimé |
| `src/components/ui/toast.tsx` | — | supprimé |
| `src/modes/command-palette.ts` | — | supprimé |
| `src/modes/product-modes.ts` | — | supprimé |
| `test/product-modes.test.ts` | — | supprimé |
| `src/ux/polish.tsx` | — | supprimé |
| `src/index.ts` | — | supprimé |
| `tsconfig.build.json` | — | supprimé |
| `package.json` | — | prunes `@radix-ui/react-dialog` + `@radix-ui/react-toast` + façade fields + script `build` |

## Prochaine étape (à ta discrétion)

- **Option A** (recommandée, 5 min) : je fais le micro-fix du header trompeur
  `ux-states.tsx:8` + le commentaire `measure.ts:3` (2 lignes de commentaire,
  alignement AD-7 documentation-honest, comme B2).
- **Option B** : passe 3 = pruner les 2 deps `@radix-ui` résiduelles orphelines
  (`react-dropdown-menu` + `react-slot`), + re-scan du `package.json` pour d'autres
  deps mortes similaires.
- **Option C** : s'attaquer aux findings restants `02-detect.md` non traités
  (B3, C5, C6, D5).
- **Option D** : committer les 2 passes (il y a ~30 fichiers modifiés + 11 supprimés
  + 2 deps prunées, `pnpm-lock.yaml` resyncé) — je peux préparer le commit
  (pas le pusher sans ta consigne).
