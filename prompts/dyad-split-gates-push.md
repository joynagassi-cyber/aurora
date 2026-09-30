# PROMPT — DYAD · Suite chantier : split du commit `e95cee2` + gate complet + push + préparation ratification

Tu as livré specs + Phase A + `impl-plan.md` en **un seul commit local**
(`e95cee2`, 62 fichiers, NON poussé — `origin/main` = `7049116`). Ce prompt =
remise en ordre selon la règle owner « 1 story = 1 commit = 1 rollback »,
fermeture du gate, push, et préparation de la ratification. Zéro inférence :
tout est cité `fichier:ligne` ou `commit`.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## État vérifié (2026-09-30)
- `e95cee2` (local, non poussé) mêle **3 chantiers** :
  1. **B0** — les 51 specs `docs/design-system/screens/*` (44 écrans + `index.md` + 6 transverses).
  2. **B2** — `docs/design-system/impl-plan.md` (345 l., structure §0-§9).
  3. **Phase A** — `apps/mobile/vite.config.ts` (57 l.) · `index.html` · `src/main.tsx` (75 l.) · `src/vite-env.d.ts` · `package.json` · `src/lib/ascent-repo.ts` (109 l.) · `src/lib/boot-data.ts` · `src/query/query-client.ts` · `capacitor.config.ts` (OneSignal fail-fast) · `src/perf/measure.ts`.
- **Gate déjà vérifié** : `pnpm -r typecheck` VERT + `pnpm -r lint` VERT (`--max-warnings 0`), 2026-09-30. Non vérifié : `pnpm -r test` + check scripts (Tâche 2).
- `impl-plan.md §0` = 8 recommandations au statut « NON — owner ratifie » : OQ-1 → (b) N=54 · OQ-16 (Eisenhower) · OQ-48 (404 global) · OQ-47 (optimistic) · OQ-6 (48px) · logos 404 (COLORED centre) · routes OQ-12 (router frozen) · 8 docs modules.
- `_gen_oq.py` : **ABSENT de la racine du repo** (vérifié 2026-09-29/30) → B0-8 = décision owner.

## Tâche 1 — Split non destructif (AVANT tout push)

`git reset --soft HEAD~1` (retour à `7049116`, le contenu reste staged) puis
re-commit par chantier — **aucune modification de fichier, regroupement uniquement** :
- **7× `cc/screens:`** = lots 1-7 de `_report.md §5` (1 inventaire · 2 les 41 docs lots 2-6 · 3 flashcards+inbox+relecture · 4 `_floating-surfaces.md` · 5 `_open-questions.md` · 6 `index.md` v1 + `INDEX_REVIEW.md` · 7 lot final `focus-mode`+`timeline-gantt`+`_flows.md`+`index.md` v2+`_report.md`).
- **8ᵉ `cc/screens:`** = B0-8 : ajout NON destructif de 1 ligne dans `_report.md §4` (« `_gen_oq.py` : registre maintenu main — script hors repo, ré-export owner possible si souhaité ») → `cc/screens: _gen_oq.py = registre maintenu main (décision B0-8, owner peut ré-exporter le script)`.
- **1× `cc/plan:`** → `docs/design-system/impl-plan.md` seul.
- **4× `dyad/beta:`** :
  - A1 `dyad/beta: mobile build (vite + cap)` = `vite.config.ts` + `index.html` + `src/main.tsx` + `src/vite-env.d.ts` + `package.json`
  - A2 `dyad/beta: ascent local-mirror wiring` = `src/lib/ascent-repo.ts` + `src/lib/boot-data.ts` + `src/query/query-client.ts`
  - A3 `dyad/beta: onesignal env key (fail-fast)` = `capacitor.config.ts`
  - A5 `dyad/beta: perf measures` = `src/perf/measure.ts`
- Règles : `git status` propre entre chaque commit · gate typecheck+lint vert au début ET à la fin du split · préfixes exacts comme ci-dessus · **ne pas toucher `docs/design-system/screens/` au-delà de la ligne B0-8** (propriété du chantier specs).

## Tâche 2 — Gate complet + push

- `pnpm -r test` + `sh scripts/check-boundaries.sh` + `sh scripts/check-rls.sh` + `sh scripts/check-view-joins.ts` → VERT (preuves dans le rapport).
- `git push origin main` → `origin/main` passe de `7049116` au 13ᵉ commit du split. **Le push fait partie du livrable.**

## Tâche 3 — Préparation de la ratification owner (ne modifier les SSoT qu'APRÈS ratification)

- Les 8 décisions de `impl-plan.md §0` restent « NON — owner ratifie » — **pas d'update SSoT avant validation owner** (R4 : jamais de dérive silencieuse).
- Produire la **fiche de ratification** (1 bloc lisible : pour chaque décision — recommandation + SSoT impactée + ce que ça débloque) : OQ-1 (b) N=54 → `05 §4 l.1316` « 44 »→« 54 » · OQ-16 → `docs/productivity/eisenhower.md` (G-L5) · OQ-48 → `feature-registry S6` (libellé FR) + `not-found.md` · OQ-47 → `docs/design-system/overview.md §6` + WDS 04.5 §8 · OQ-6 → `ui-libraries §9.3 l.454` (64-96px → 48px) · logos → dédoublonnage `05 §9.1` (matrice l.378-388 vs l.387) · routes OQ-12 → `router.tsx` (frozen) + WDS résiduel · 8 docs modules (PAIGE + équipes, table `impl-plan §0`).
- Après ratification owner **UNIQUEMENT** : 1 commit `cc/plan:` d'updates SSoT → puis déverrouillage des lots B3 (`dyad/impl:`, `impl-plan.md §2-§3`).

## Tâche 4 — Commit de ce prompt
- `wave3/dyad: split+gates+push prompt (suite e95cee2)` = ce fichier `prompts/dyad-split-gates-push.md` seul, commité avec le split et poussé avec la suite.

## Hors périmètre
- Les 8 docs modules (PAIGE + équipes modules) · DAPHNE Phase C (post-ratification B3) · backend · captures device (owner : `npx cap add android` + `npx cap sync` + `.env.local` OneSignal).

## Rapport de fin OBLIGATOIRE
- « Split : OUI/NON (13 commits = 8 `cc/screens:` + 1 `cc/plan:` + 4 `dyad/beta:` + prompt `wave3/dyad:`) »
- « Gate : typecheck / lint / test / check-boundaries / check-rls / check-view-joins = VERT/ROUGE (preuves) »
- « Push : OUI/NON (`origin/main` = quel hash) »
- « Ratification : fiche des 8 décisions prête — owner attendu sur [liste] »
- « B3 : verrouillé en attente de ratification `impl-plan §0` (R2) »
