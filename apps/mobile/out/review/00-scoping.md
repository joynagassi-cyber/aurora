# Mode 2 — Scoping & conventions (orchestrator inline scout)

## Préconditions (Step 0 du protocole)

- [x] `@ionic/react` + Capacitor : `apps/mobile/package.json` (`@ionic/react ^8.8.19`, `@capacitor/core ^7.6.9`, `@capacitor/android`), `capacitor.config.ts` présent.
- [x] Conventions projet lues : `CLAUDE.md` (graphify — pas touché car ce sont des lectures seules), `docs/ui-libraries.md` existant (SSoT des composants UI), `styles/tokens.css` = baseline des tokens `--aurora-*` (AD-17, 05 §2.1/§5.8, radius caps 0.5rem, zéro valeur brute hors token).
- [ ] Scope confirmé : **l'ensemble du frontend mobile** (`apps/mobile/src`, ~4 900 lignes, 17 pages routées + shell + lib/ux/query) + `capacitor.config.ts`. C'est le plus petit scope utile cohérent — le diff en cours (skills/agent) y est inclus.
- [x] Read-only ou fix : **read-only d'abord (Map + Detect)**, le Fix n'arrive que si l'utilisateur valide la liste des findings.

## Contrainte non-négociable (Reversa / règles projet)

- **Ne JAMAIS modifier `supabase/migrations/**`, `.env*`, `capacitor.config.ts` (hors finding explicite), ni `packages/**`** — la règle absolue s'applique à tout le projet, pas seulement à `_reversa_sdd`.
- `capacitor.config.ts` a un **fail-fast AD-3** : `AURORA_ONESIGNAL_APP_ID` manquant → `throw` au build. C'est un guardrail volontaire, ne pas le « réparer ».
- Le design system `--aurora-*` prime sur les conventions génériques du skill Ionic : **zéro valeur brute** hors token (`ui-libraries §4`), radius caps `0.5rem`, surfaces blanches par défaut (G-H2 re-2026-10).

## Périmètre d'analyse

- `apps/mobile/src/**` (pages, shell, lib, query, ux, styles)
- `apps/mobile/capacitor.config.ts` (lecture seule, fail-fast = attendu)
- Hors périmètre : `packages/**`, `supabase/functions/**` (server-only, pas du frontend), `node_modules`, `dist`.

## Ce qu'on a déjà repéré en lecture inline (input au Map agent)

- `main.tsx` (148) : mount chain PowerSync → theme adapter → data provider → 3 clients (agent/integrations/skills) tous sur le **même** publishable-scope Supabase client. Absent env → client undefined → empty state honnête (AD-7).
- `pages/skills/index.tsx` (505) + `lib/skills-client.ts` (193) : nouveau, 3 tabs (catalog/personal/expert), état de chargement/erreur/vide couverts, mais pas de `useEffect` cleanup / pas de `useCallback` sur le toggle personnel (inline async, lines 420–424 et 451–454 — re-run possible si le tab change en vol).
- `pages/agent/index.tsx` (483) : composer + picker modal + plus-sheet, état streaming/empty/loading/offline présent (`data-state` attr), mais `files` state = fake filenames (`fichier-${n}.pdf`, line 458) — faux état visuel (pas de fichier réel). `MODEL_CATALOG` = noms de modèles statiques (Agnes/Workers AI/Groq/OpenRouter, lines 39–44) — vérifier si ça colle au router S2.6 réel (`alwaysFirst` + fallback, zéro nom de modèle en code business selon l'exécution ORACLE).
- `router.tsx` (119) : 17 pages routées, `React.lazy` ABSENT (import static partout, comment « 17 pages. Each is a lazy boundary » = faux, ce sont des imports statiques). `/focus` prend `service={null}` (line 90) — service jamais branché ?
- 10 fichiers CSS under `styles/` + `tw.css` (Tailwind v3 + shadcn layer) + `tokens.css` (baseline `--aurora-*`) : à vérifier zéro hex brut hors token (`ui-libraries §4`), safe-area insets sur les pages qui ont un `IonContent` au bord.
- 0 import `@capacitor/*` dans `src/**` (le platform boundary = `@aurora/platform`, AD-1 lense déjà vérifié — bon signe, rien à fixer de ce côté-là).

## Prochaines étapes

1. **Map agent** (ici) → `01-map.md` : inventaire complet des pages routées, composants partagés, plugins Capacitor, overlays, forms, 4 états (loading/success/error/empty).
2. **Detect agent** (ici) → `02-detect.md` : findings classés (Critical/High/Medium/Low), `file:line`, 6 catégories du skill, fix_hint.
3. **Juge panel** (ici, 3 lenses) : adversarial verify sur les findings Critical/High — « est-ce un vrai finding ou un faux positif du skill générique Ionic appliqué au design system Aurora ? ».
4. **User review** : la liste des findings validés s'affiche ici. Si l'utilisateur dit « fixe », on passe au **Fix agent** (le seul qui écrit), jamais au-delà.
5. **Orchestrator closeout** : vérif map/detect/fix, report final.
