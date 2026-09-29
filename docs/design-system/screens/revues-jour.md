# revues-jour — Revues (jour)

Status: SPÉCIFIABLE (OQ: 5) · Module : Productivité · Route : (reviews) · SSoT : 05 §4.5.1 (l. 2229-2409) + 05 §3.4 `Pager` (l. 737-750) + 05 §3.7 (l. 1244-1309) + ui-libraries S1/S3/§6/§9 + master-feature-catalog §2 l. 26 (`productivity.reviews`, offline-capable)

> Le `revues-jour` = l'échelle **jour** de la chaîne `revues-jour / revues-semaine / revues-mois`
> (05 §4.5.1, doc §2.9 « Revue quotidienne / hebdomadaire / mensuelle »). Une revue est une
> **action** périodique (pas un objet à « voir ») : le DS **structure** la revue (5 sections
> fixes par échelle), l'utilisateur **remplit** le contenu libre dans la structure (05 §4.5.1
> l. 2229-2247, doc §1 « simple en surface, puissant en profondeur »). Ce doc spécifie le pager
> `Jour` (le même composant `Pager` partagé avec `revues-semaine`/`revues-mois`, 05 §4.5.1
> l. 2398-2402) ; les zones partagées (BottomNav, 404, offline global) sont référencées.

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | **Réviser** sa journée (5 sections guidées pré-remplies) — **pas** « voir » une revue | 05 §4.5.1 l. 2229-2244 |
| Contexte | Device mobile (Phase 1) ; moment = fin de journée / soirée (revue quotidienne) ; réseau = **indifférent** (la revue n'exige jamais le réseau, 05 §4.5.1 l. 2356-2361) | 05 §4.5.1 l. 2353-2367 ; master-feature-catalog l. 26 |
| Fréquence | **Haute** : une revue **quotidienne** (l'échelle du slug = `Jour`) | 05 §4.5.1 l. 2231-2247 (doc §2.9) |
| État émotionnel cible | **Contrôlé / confiant** : le retard est **signalé, pas caché** (`Callout warning`, 05 §4.5.1 l. 2314-2321, doc §2.9 « Pilotage personnel ») — l'utilisateur **décide**, l'agent ne fait que **suggérer** (l. 2360-2361) | 05 §4.5.1 l. 2353-2367 ; doc §2.9 |
| Erreur la plus probable | Remplir la revue « à blanc » alors que les 5 sections sont **pré-remplies** par les données locales (le bilan vient du `Task` AD-15, les priorités du `Goal` AD-15) — l'usage cible = **ajuster**, pas écrire (05 §4.5.1 l. 2368-2377, doc §12) | 05 §4.5.1 l. 2368-2377 |
| Ce que l'écran RÉSOUT | « Comment s'est passée **cette** journée ? » = le bilan structuré (5 sections) + la décision suivante (le plan d'action **génère** des tâches) | 05 §4.5.1 l. 2229-2409 ; doc §2.9 |

## 2. Zones

- **header** : `TopBar` « Revue » (05 §3.4 l. 659-668) + `Pager` §3.4 (Jour | Semaine | Mois — **ce slug = le mode `Jour`**) + `SegmentedControl` « À faire / Faite » (05 §4.5.1 l. 2248-2263 : `pending` / `completed` ; **2 statuts seulement** — le 3ᵉ « annulée » n'est pas un état, une revue annulée = une `Callout info` **historisée**, l. 2256-2262).
- **content** : une `Review` = une `Card` **posée** (pas un `ListItem` — une revue est **riche**, 05 §4.5.1 l. 2264-2269) avec les **5 sections** (l. 2270-2297, doc §2.9) :
  1. `Bilan des tâches` = `DataTable` §3.6.1 (4 colonnes : statut / titre / projet / « pourquoi »)
  2. `Révision des priorités` = liste `RoutineStep` ordonnée
  3. `Plan d'action suivant` = liste `RoutineStep` (→ « En faire une tâche », l. 2388-2394)
  4. `Journal des décisions` = `TextArea`
  5. `Analyse des causes` = `TextArea` + 3 `Chip` de causes courantes (charge / fatigue / blocage technique)
  - `Callout warning` « revue en retard » **posé** si la période précédente n'a pas été revue (l. 2314-2321)
  - `EmptyState` si pas de revue dans la période (l. 2336-2347)
- **footer** : `BottomNav` (05 §3.4 l. 670-688)
- **CTA** : le seul CTA **dominant** (AD-14) = `Button primary` « Faire la revue » (état `empty`, l. 2338-2344, ouvre la `BottomSheet` de création **pré-remplie**).
- **Surfaces flottantes** : `BottomSheet` de création (5 sections pré-remplies, l. 2368-2377), `Toast` (après création/sync), `Callout` (retard, killed).

## 3. Éléments / widgets

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| 1 | `TopBar` « Revue » | `TopBar` (05 §3.4 l. 659-668) | shadcn `header` | `surface`, `md` 600 titre, `text-muted` `xs` (la période) | n/a | 05 §4.5.1 l. 2248 |
| 2 | `Pager` (Jour active) | `Pager` §3.4 (l. 737-750) : `SegmentedControl` Jour\|Semaine\|Mois + ligne navigation (précédent / label `JetBrains Mono` sm / suivant) + `Button ghost` « Aujourd'hui » | shadcn `tabs` (ui-libraries S1 l. 24) | `primary-surface` pill actif, `border` inactif, `JetBrains Mono` `sm` 600 (dates) | n/a (composant plateforme-agnostique, l. 2398-2402) | 05 §4.5.1 l. 2248-2251 ; l. 737-750 |
| 3 | `SegmentedControl` « À faire / Faite » | `SegmentedControl` (05 §4.5.1 l. 2251-2263) | shadcn `tabs` variant=segmented | `primary` (statut actif), `text-secondary` (inactif) | n/a | 05 §4.5.1 l. 2251-2263 |
| 4 | `Card` de la `Review` (posée) | `Card` **posée** (05 §4.5.1 l. 2264-2269 ; §3.3 l. 499-515 : fond `surface`, `shadow.1`, radius `md`, padding `space.4`, **obligatoirement** un titre) | shadcn `card` | `surface`, `radius.md`, `space.4`, `shadow.1` | desktop = 2 colonnes (l. 2399-2407 : bilan à gauche, le reste à droite ; la logique 5 sections est **inchangée**) | 05 §4.5.1 l. 2264-2269 ; §3.3 |
| 5 | §1 `Bilan des tâches` | `DataTable` §3.6.1 (4 colonnes : statut / titre / projet / « pourquoi ») | shadcn `table` / `DataTable.tsx` (SSoT code `packages/ui`) | `border` lignes, `text-secondary` `sm`, `JetBrains Mono` `xs` (les statuts) | n/a | 05 §4.5.1 l. 2272-2287 |
| 6 | §2 `Révision des priorités` | `RoutineStep` ordonné (05 §4.5.1 l. 2288-2294) | shadcn `list-item` (pas ion-list — S3 l. 136) | `text-primary` `sm`, `space.2` | n/a | 05 §4.5.1 l. 2288-2294 |
| 7 | §3 `Plan d'action suivant` | `RoutineStep` + `Button ghost` « En faire une tâche » (si l'étape **devient** une tâche) | shadcn `button` variant=ghost (S1) | `text-secondary` (ghost), `space.2` | n/a | 05 §4.5.1 l. 2290-2294, l. 2388-2394 |
| 8 | §4 `Journal des décisions` | `TextArea` (05 §3.2 ; le texte libre, doc §2.9) | shadcn `textarea` (S1) | `border`, `text-primary` `sm` | n/a | 05 §4.5.1 l. 2295-2297 |
| 9 | §5 `Analyse des causes` | `TextArea` + 3 `Chip` (charge / fatigue / blocage technique — causes courantes génie civil) ; un `Chip` = tag **amovible** (× ≥ 44px, §3.3 l. 552-556, undo `Toast` « Annuler ») | shadcn `textarea` + `badge` (variante Chip, S1/S3) | `bg-subtle` (Chip par défaut), `primary-surface` (sélectionné), `radius.sm` | n/a | 05 §4.5.1 l. 2295-2297 ; §3.3 l. 552-560 |
| 10 | `Callout warning` « revue en retard » | `Callout` (05 §3.3 l. 628-641 ; **posé**, persistant, **doit porter une action** — CTA ghost) | shadcn `alert` variant=warning (S1) | `warning` (figé, 05 §5.1 l. 2931), `warning-surface`, `radius.md`, `space.3` | n/a | 05 §4.5.1 l. 2314-2321 ; §3.3 |
| 11 | `Button ghost` « Suggérer un ajustement » (dans le `Callout` de retard) | `Button` (05 §3.1 l. 365-390, variant=ghost) → ouvre `agent` §4.9.1 (la suggestion = capacité kernel AD-12/F-09) | shadcn `button` variant=ghost | `text-secondary`, `space.2` min. espacement du `primary` | n/a | 05 §4.5.1 l. 2380-2387 ; doc §2.9 |
| 12 | `EmptyState` (pas de revue dans la période) | `EmptyState` (05 §3.3 l. 644-656 : icône domaine 48px + title 1 phrase + body ≤ 2 lignes + **1 seul CTA**) | shadcn (pattern §6, S1) | icône `text-muted`, title `text-primary` `md` 600, CTA `primary` 56px (`lg`) | n/a | 05 §4.5.1 l. 2336-2347 |
| 13 | CTA « Faire la revue » (dans le `EmptyState`) | `Button primary` (05 §3.1 l. 365-390 ; `EmptyState` : le CTA **crée** l'objet → `primary` si 1, §3.3 l. 650-652) → ouvre la `BottomSheet` de création (une `Review` AD-15 `pending` est **créée**, l. 2338-2347) | shadcn `button` variant=default, 56px | `primary`, `on-primary`, 56px (`lg`) | n/a | 05 §4.5.1 l. 2338-2347 ; §3.1 l. 381 |
| 14 | `BottomNav` (footer) | `BottomNav` (05 §3.4 l. 670-688) | shadcn `tab-bar` | `primary-surface` pill, 56px + safe-area | n/a | 05 §3.4 l. 670-688 |

**Règle interdits** : `ion-list` pour le bilan (S3 l. 136, → shadcn `table`/AG Grid) ; `ion-item` pour les sections (S3 l. 137, → shadcn/Radix) ; `ion-datetime` (S3 l. 138, → FullCalendar + Popover) ; `border-radius > 8px` (S3 l. 142) ; bouncy (S3 l. 143) ; **plus de 1 `Button primary` par écran** (AD-14, 05 §3.1 l. 372-374).

## 4. États (6 S6 + sémantiques §6.1 + 404) — par élément async

### 4a. Matrice S6 (ui-libraries §6 l. 174-187)

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| 1-3. `TopBar` + `Pager` + `SegmentedControl` | n/a (chrome, 05 §3.7 l. 1282) | n/a | n/a | n/a | `Badge` « Offline » en `TopBar` (ui-libraries §6 l. 184) ; le `Pager` **fonctionne** (la navigation temporelle est locale, AD-7, l. 747-750) | n/a (chrome) |
| 4-9. `Card` de la `Review` (5 sections : `DataTable` + `RoutineStep` + `TextArea` + `Chip`) | `Skeleton` des sections (05 §4.5.1 l. 2330-2337, « le store local, **court** » ; 05 §3.7 l. 1264-1269 : `Card` = skeleton contenu) ; transition d'entrée `opacity 0→1` 200ms (polish.tsx) | `EmptyState` (id. 12-13) : icône « revue » 48px + « Pas de revue aujourd'hui » (l. 2340-2344) + CTA primary « Faire la revue » (l. 2338-2347) — la CTA ouvre la `BottomSheet` de **création** (la revue **est** l'action, l. 2345-2347, doc §2.9) | Une revue non syncée = `Badge danger` « à resync » **sur la Card** (05 §4.5.1 l. 2348-2352) — la revue **reste lisible** (AD-7) ; le `Callout warning` de retard **n'apparaît pas** à cause de ça (le retard = un objet **réussi**, pas un échec de sync) | `Toast` (3s auto-dismiss, ui-libraries §6 l. 183) après création/sync ; le `SegmentedControl` bascule vers « Faite » (la `Review` AD-15 = `completed`, l. 2255) | **Identique** à l'état `success` local : les revues **restent lisibles** (lecture locale AD-7), la **création reste possible** (écriture locale, pack 03) — « une revue **n'exige jamais** le réseau » (05 §4.5.1 l. 2356-2361, doc §2.9 : auto-évaluation) | `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; G-M2 : les données du mirror local s'affichent, jamais d'écran blanc, AD-7) |
| 10-11. `Callout warning` « revue en retard » + `Button ghost` « Suggérer un ajustement » | n/a (le `Callout` **est** l'état, 05 §3.7 l. 1286) | n/a (pas de retard = pas de `Callout`) | n/a (le retard est un état **sémantique**, pas une erreur de sync) | n/a | n/a (le calcul du retard est **local**, AD-7) | n/a |
| 12-13. `EmptyState` + CTA « Faire la revue » | n/a (le `EmptyState` **est** l'état, 05 §3.7 l. 1270) | (c'est l'état) | n/a | n/a | **CTA local** (05 §3.7 l. 1270 : `EmptyState` `offline` = « CTA local ») — la création reste **possible** (écriture locale, pack 03, l. 2353-2361) | n/a |
| 14. `BottomNav` | n/a (chrome) | n/a | n/a | n/a | n/a | n/a |

**Règle de test** (pack 02 §11, 05 §3.7 l. 1303-1306) : composant « écran » (ici le `Callout`/`EmptyState`) = test par écran qui compose l'état ; composant « composant » = test de rendu par état.

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202)

| État | Rendu | Source SSoT |
|---|---|---|
| `en-cours` | Le `SegmentedControl` « **À faire** » = la `Review` AD-15 `pending` **est en cours** (05 §4.5.1 l. 2251-2259 : « une revue **à faire** est une `Review` AD-15 `pending` ») ; le statut `en-cours` (ui-libraries §6.1 l. 197) = la revue **se fait** dans la `BottomSheet` de création (l. 2368-2377 : les 5 sections **pré-remplies**, l'utilisateur **ajuste**) | 05 §4.5.1 l. 2251-2259 ; ui-libraries §6.1 l. 197 |
| `terminé` | Le `SegmentedControl` « **Faite** » = la `Review` AD-15 `completed` (05 §4.5.1 l. 2255, ui-libraries §6.1 l. 198) ; la Card affiche les 5 sections **lues** du mirror local | 05 §4.5.1 l. 2255 ; ui-libraries §6.1 l. 198 |
| `échec` | N/A (raison) — une revue annulée **n'est pas un état de revue** (05 §4.5.1 l. 2256-2262 : « le 3ᵉ « annulée » n'est **pas** un état de revue, une revue annulée = une `Callout info` **historisée**, pas un tab actif » ; ui-libraries §6.1 l. 199) | 05 §4.5.1 l. 2256-2262 |
| `succès` | `Toast` (3s auto-dismiss, ui-libraries §6 l. 183, §6.1 l. 200) après la **création** de la `Review` `pending` (le CTA « Faire la revue » a créé l'objet, l. 2338-2347) ; le basculement « Faite » = le succès **sémantique** de la période | 05 §4.5.1 l. 2255, 2338-2347 ; ui-libraries §6 l. 183 |
| `erreur` | `Badge danger` « à resync » **sur la Card** (05 §4.5.1 l. 2348-2352 ; ui-libraries §6.1 l. 201) — transitoire : auto-resync au retour réseau (l. 2353-2367, pack 03 §5.5), la revue **reste lisible** (AD-7) | 05 §4.5.1 l. 2348-2367 ; ui-libraries §6.1 l. 201 |
| `404 / not-found` | Page entière (partagée avec l'enveloppe `revues` #52) : logo AURORA **coloré sans fond** au **centre** (ui-libraries §9.1 l. 387, §6.1 l. 202), message court, CTA primaire « Retour à l'accueil » ; `revues-jour` = un **état** du `Pager` (mode `Jour`, l. 2248-2251), pas une route distincte — le 404 s'applique à l'enveloppe `(reviews)` | ui-libraries §6.1 l. 202 ; §9.1 l. 387 ; _inventory #52 |

### 4c. `killed` (tout flux serveur)

Le seul flux serveur de ce slug = la **re-synchronisation** de la revue (AD-8, pack 03 §5.5
— 05 §4.5.1 l. 2353-2367 : « une revue **n'exige jamais** le réseau »). `killed` = `Skeleton`
+ bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) ; les
données du **mirror local** s'affichent (jamais d'écran blanc, AD-7), le composant repasse en
état normal au resync (05 §3.7 l. 1297-1298, G-M2 : sous-état de `loading`, pas un 6ᵉ état
canonique).

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| `Pager` (id. 2) | tap « Jour » → le contenu **switch** (pas un push, 05 §4.5.1 l. 2248-2251) ; le contenu slide horizontalement | 150-200ms `ease-out` (05 §2.6 l. 310-320) | `transform: translateX` | `static` (05 §2.6 l. 330-334, règle 2) | 05 §4.5.1 l. 2248-2251 ; polish.tsx |
| `Pager` ligne navigation (id. 2) | tap « précédent / suivant » → le label central `JetBrains Mono` (l. 743) **change** (l'ancrage temporel **persisté** par l'écran, pack 02 §3.2, l. 745) ; tap « Aujourd'hui » → retour au présent (**jamais caché**, l. 741-743) | 200ms `ease-out` | `transform` + `opacity` | `static` | 05 §3.4 l. 737-750 |
| `SegmentedControl` (id. 3) | tap « Faite » (la revue est `completed`) → le contenu passe en **lecture** (le statut est **figé**, pas de feedback d'animation) ; tap « À faire » (la revue est `pending`) → le contenu reste éditable | 150ms (le switch de segment, 05 §2.6 l. 316) | `transform: translateX` | `static` | 05 §4.5.1 l. 2251-2263 |
| `RoutineStep` (id. 7) « En faire une tâche » | tap `Button ghost` (l. 2388-2394) → la step **devient** une tâche (le plan d'action **génère** des tâches, pas l'inverse, l. 2392-2394, doc §2.9) ; `Toast` (3s, l. 2338 pattern) | 200ms `ease-out` | `opacity` | `static` | 05 §4.5.1 l. 2388-2394 |
| `Callout warning` (id. 10-11) | tap `Button ghost` « Suggérer un ajustement » → ouvre `agent` §4.9.1 (l. 2380-2387 : la suggestion = capacité du **kernel** AD-12/F-09, l'utilisateur **décide**) | 200ms `ease-out` (PAGE_TRANSITION, polish.tsx) | `translateY(8px→0)` + `opacity` | `static` | 05 §4.5.1 l. 2380-2387 |
| CTA « Faire la revue » (id. 13) | press → `scale 0.95` (`anim.fast`, 05 §3.1 l. 383-385) puis `BottomSheet` de création (l. 2338-2347, §3.5 l. 787-808) | 150ms press + 250ms `ease-out` sheet | `transform: scale` + `translateY` | `static` | 05 §3.1 l. 383-385 ; §3.5 l. 787 |
| `BottomNav` (id. 14) | tap tab → navigation tab (slide, 05 §3.4 l. 670-688) | 200ms `ease-out` | `transform: translateX` | `static` | 05 §3.4 l. 670-688 ; polish.tsx |
| `Chip` des causes (id. 9) | tap `×` (≥ 44px, §3.3 l. 552-556) → le chip est **supprimé** avec un `Toast` « Annuler » (undo **obligatoire**, §3.3 l. 558-560, règle de non-surprise) | 150ms `ease-out` | `opacity` | `static` | 05 §3.3 l. 552-560 |

**Règles bloquantes** : pas de `layout` animations sur mobile (ui-libraries S5 l. 169) ; pas de
bouncy (S3 l. 143) ; transitions **standard** 150-250ms seulement (S3 l. 143) ; `prefers-reduced-motion`
= **tout** `static` (05 §2.6 l. 330-334, règle 2) ; les **données** ne s'animent jamais (05 §2.6
l. 323-330, règle 1) — les 5 sections (id. 5-9) = du **contenu**, pas des animations.

## 6. Modals / BottomSheets / Drawers (spécifiques à la revue)

| Surface | Déclencheur | Contenu | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|
| `BottomSheet` de **création** de revue | CTA « Faire la revue » (id. 13, l. 2338-2347) ou l'état `pending` de la `Review` | Les **5 sections pré-remplies** par les données locales (l. 2368-2377 : le bilan vient du `Task` AD-15 local, les priorités du `Goal` AD-15 — « **pré-remplies**, l'utilisateur **ajuste**, pas « écrit à blanc » ») ; `Button primary` « Valider » (AD-14 : 1 seul CTA dominant dans la sheet, §3.5 l. 787-808) + `Button ghost` « Plus tard » (l. 2256-2262 : « annulée » = la `Callout info` **historisée**) | Swipe down / `Button` (05 §3.5 l. 787-808) | `translateY` + `opacity`, 250ms `ease-out` (S3 l. 143) | 05 §4.5.1 l. 2338-2347, 2368-2377 ; §3.5 l. 787-808 |
| `Toast` (après CTA / création) | tap CTA (id. 13) ou valider la `BottomSheet` | « Revue créée » / « Synchronisé » (3s auto-dismiss, ui-libraries §6 l. 183 ; verbatim exact = **OQ-2**) | auto 3s | `opacity` 200ms | ui-libraries §3.5 l. 823-841 ; 05 §3.5 l. 823 |
| `Callout info` (killed) | `killed` (G-M2) | « Reconnexion… » (bannière fine, 05 §3.7 l. 1290-1296) | n/a (persistante tant que le flux est down) | n/a | 05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185 |
| `Modal` de **confirmation** destructive | N/A ici (la création d'une revue = **ajout** local, pas une mutation destructive — pas de `Modal`, 05 §3.1 l. 378-380 : le `destructive` **seulement** si irréversible) | n/a | n/a | n/a | 05 §3.1 l. 378-380 |

## 7. Formulaires

| Champ | Lib | Validation | Clavier mobile | Persistance | SSoT |
|---|---|---|---|---|---|
| Les **5 sections** (id. 5-9) = le **contenu** du `BottomSheet` de création (`TextArea` pour le journal + l'analyse des causes, `RoutineStep` pour les priorités/actions, `Chip` pour les causes courantes) | shadcn `textarea` / `input` / `badge`-Chip (ui-libraries S1, S3 l. 137 : **pas** `ion-item`) | Pas de validation **stricte** (le contenu est **libre dans la structure**, 05 §4.5.1 l. 2240-2247) ; les `Chip` = amovibles (undo `Toast`, §3.3 l. 558-560) | `soft-input` mobile (05 §3.2 l. 412-432) | La `Review` AD-15 (`pending`/`completed`, l. 2251-2255) dans SQLite (AD-6), sync différée (AD-7, pack 03) | 05 §4.5.1 l. 2368-2377 ; §3.2 ; §3.3 |

**Interdiction** : un `TextField` qui cache le label quand vide (05 §3.2 l. 434-436) ; `ion-item`
pour les sections (S3 l. 137, → shadcn/Radix) ; un formulaire **free-form** (le DS
**structure** la revue, l'utilisateur remplit — 05 §4.5.1 l. 2240-2244, doc §1).

## 8. Pagination

**Règle unique nommée** : `Pager` jour-semaine-mois (05 §3.4 l. 737-750) — le `Pager` **est** la
pagination temporelle de ce slug (le `SegmentedControl` `Jour | Semaine | Mois` + la ligne de
navigation avant/après + le `Button ghost` « Aujourd'hui »).

- **Pas de shadcn Pagination ni AG Grid** : le volume = **borné** par la période (1 journée, le
  slug `Jour` — le bilan des tâches = 4 colonnes, 05 §4.5.1 l. 2280-2287, pas 100+ lignes) ; les
  5 sections = un nombre **fixe** d'éléments (< 20 items, ui-libraries S8 l. 304-307 : < 20 rows
  → `Table`, pas de pagination).
- **Params** : le mode (`Jour` ici) et l'ancrage temporel sont **persistés** par l'écran (store
  UI pack 02 §3.2, 05 §3.4 l. 743-745) — le retour retrouve le même mode et la même position
  (règle de non-surprise, l. 745).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** depuis le Home | Tab « Productivité » / deep link `(reviews)` → `revues-jour` (le mode `Jour` par défaut, 05 §4.5.1 l. 2248) ; `PAGE_TRANSITION` : `opacity 0→1`, `translateY(8px→0)`, 200ms `ease-out` | polish.tsx ; 02 §6.1 (détail par-dessus le tab) |
| **Retour natif** (back Android) | Depuis le `BottomSheet` de création (id. 13 → §6) → retour sur la Card (la revue **reste** `pending`, l. 2251) ; depuis la `BottomSheet` dismissée (swipe) → retour sur l'écran courant (pas de push, l. 2368-2377 : la création est **in-situ**) | 02 §6.3 ; 05 §4.5.1 l. 2368-2377 |
| **CTA « Faire la revue »** | Ouvre la `BottomSheet` (id. 13 → §6) — **pas** un push (la `BottomSheet` = surface flottante, 05 §3.5 l. 787-808 ; le contenu **reste** en dessous, AD-7) | 05 §4.5.1 l. 2338-2347 ; §3.5 l. 787 |
| **Drill-down « Suggérer un ajustement »** | tap `Button ghost` (id. 11) → ouvre `agent` §4.9.1 (l. 2380-2387 : le **kernel** suggère, l'utilisateur **décide**) ; le `AgentThinkingLoader` (§9.3) **peut** apparaître pendant la suggestion (ui-libraries §9.3 l. 420-487, l'organisme = le thinking, la marque **reste calme** = le butterfly mark **statique**) | 05 §4.5.1 l. 2380-2387 ; ui-libraries §9.3 |
| **Basculement « Faite »** | La `Review` passe `pending` → `completed` (l. 2255) : le `SegmentedControl` (id. 3) **switch** (pas un push, l. 2248-2251) ; le contenu passe en **lecture** (les 5 sections **existent**, pas de re-push) | 05 §4.5.1 l. 2251-2263 |
| **404** (deep link invalide, ex. `?range=quarter`) | → `not-found` (enveloppe `(reviews)` #52) : logo AURORA coloré au centre, CTA « Retour à l'accueil » (ui-libraries §6.1 l. 202 ; §9.1 l. 387) | ui-libraries §6.1 l. 202 ; §9.1 l. 387 ; _inventory #52 |

## 10. Thèmes

Comportement par couche (05 §5 l. 2925-3306 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#F8FAFC` / Dark `#0A0E1A`) : fournit `surface`,
  `text-primary/secondary`, `border`, `shadow` — les tokens **géométriques** de la Card (id. 4)
  et des 5 sections (id. 5-9). Les 10 thèmes vivants **ne redéfinissent jamais** les
  sémantiques (05 §5.1 l. 2931, règle bloquante : un thème **ne touche jamais**
  `success`/`warning`/`danger`/`info`).
- **Couche 2 — Expressive** (4 accents + gradients, 05 §5.4 l. 3010-3047) : le `SegmentedControl`
  actif (id. 3) = `accent.primary` ; la `Chip` sélectionnée (id. 9) = `accent.primary-surface`
  (dérivé, pas une valeur brute, AD-17 l. 2961) ; le CTA « Faire la revue » (id. 13) =
  `accent.primary` (le **seul** `primary` de l'écran, AD-14). **Jamais de valeur par thème**
  (AD-17) — les 10×3 combinaisons = un comportement **par couche**, pas par thème (05 §5.2
  l. 2961-2990).
- **Couche 3 — Presets** (`slate` / `nocturne` / `high-contrast`, 05 §5.5 l. 3153) : High
  Contrast = tap targets 56px (05 §6.3) ; les `Callout warning` / `Badge danger` / `Badge
  primary` = **figés** (pas redéfinis par le thème, 05 §5.1 l. 2931) — le retard **reste**
  `warning` dans les 13 univers (10 thèmes + 3 presets).
- **Test 10×5** (05 §5.7 l. 3183-3227) : le `revues-jour` doit passer les 5 styles × 10
  thèmes (la `Card` posée = le cas limite : le `shadow.1` en Dark Nocturne, l. 3032).

## 11. A11y (WCAG AA, 05 §6.3)

- Tap targets **≥ 44px** (56px en High Contrast, 05 §6.3) : le CTA « Faire la revue » (id. 13)
  = **56px** (`lg`, 05 §3.1 l. 381) ; les `RoutineStep` (id. 6-7) = **44px** min ; le `×` des
  `Chip` (id. 9) = **≥ 44px** (§3.3 l. 552-556) ; le `Pager` (id. 2) = **56px** (le `SegmentedControl`
  + la ligne de navigation, l. 741-745).
- `aria-label` sur **tous** les icon buttons (le `Pager` = icône + texte visible, pas icon-only ;
  si icon-only = `aria-label` **obligatoire**, 05 §3.1 l. 388-396, test CI §7) ; le `TopBar`
  (id. 1) = `aria-label` « Revue » (le titre, pas un icon button seul).
- `letter-spacing 0` (05 §6.3) ; `focus-visible` ring = `focus-ring` (token, 05 §2.4 l. 254-264) ;
  le `Callout warning` (id. 10) porte `role="status"` (le `Callout` est **posé**, pas un toast,
  AD-14).
- Le `Badge danger` « à resync » (id. 4-9, §4a `error`) = **texte + couleur** (pas couleur seule,
  05 §6.3 non-color-only) ; le `SegmentedControl` (id. 3) = le statut est **lu** à voix haute
  (pas une pastille de couleur seule, 05 §6.3).

## 12. Offline

### 12.1 Classe offline (catalog) + classe de dégradation AD-1 (master-feature-catalog l. 26)

- **Classe offline** (master-feature-catalog l. 26) : `productivity.reviews` = **offline-capable**
  (daily/weekly/monthly + decisions journal ; agent `review.run` = CONFIRMATION_REQUIRED ;
  offline-capable) — le `revues-jour` **fonctionne** sans réseau (le slug est **déclaré**
  offline-capable, pas « dégradé »).
- **Classe de dégradation AD-1** : le SSoT `master-feature-catalog` l. 26 donne **seulement** la classe
  `offline-capable` — **pas** de note de dégradation explicite (contrairement aux autres chaînes du
  même doc, ex. `learning.import` l. 34 « degradation: manual entry (AD-1) ») ; spine AD-1 (l. 31-35) =
  « Optional capabilities must **degrade gracefully** when their provider is absent » (port-based).
  Interprétation SSoT par défaut (non citée par le catalog pour `reviews`) : le kernel **down** ne
  dégrade **rien** sur ce slug — lecture/création **restent locales** (AD-7, pack 02 §7) ; seul le
  flux serveur mort = la re-synchronisation (pack 03 §5.5, killed G-M2, §12.3) ; l'agent `review.run`
  CONFIRMATION_REQUIRED = **désactivé** (non exécutable côté serveur) en mode `killed`/`offline`
  sans dégradation visuelle dédiée (le `Button ghost` « Suggérer un ajustement », id. 11, **n'est pas**
  spécifié comme désactivé dans le SSoT — **OQ-5**).

### 12.2 AD-1 (dégradation propre)

- **Miroir local** (AD-7 / AD-12, pack 02 §7) : les 5 sections (id. 5-9) sont **lues** du
  mirror local (PowerSync/SQLite) ; la **création** reste **possible** (écriture locale, pack
  03) — « une revue **n'exige jamais** le réseau » (05 §4.5.1 l. 2356-2361, doc §2.9 : le
  pilotage est **personnel**, l'agent **suggère**, l'utilisateur **décide**).
- **Ce qui meurt (killed)** : le **seul** flux serveur = la **re-synchronisation** (pack 03
  §5.5) — si le kernel est down, la sync **meurt** (killed, G-M2 : `Skeleton` + « Reconnexion…
  », 05 §3.7 l. 1290-1296), mais la **création** et la **lecture** restent **locales** (AD-7) —
  l'écran ne **meurt pas** (le miroir local **reste** affiché, l. 1297-1298 : « les données du
  mirror local s'affichent, jamais d'écran blanc »).

### 12.3 Killed (G-M2)

- `killed` = `Skeleton` des sections + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ;
  ui-libraries §6 l. 185) ; le composant repasse en état normal **automatiquement** au resync
  (G-M2, l. 1297-1298 : « sous-état de `loading`, pas un 6ᵉ état canonique »).
- **Au retour du réseau** : les revues **nouveaux** syncées depuis le cloud apparaissent avec
  leur `Badge` « nouveau » `primary` (05 §3.4 l. 748-750 : le « nouveau » = indigo, **pas
  rouge** — le `danger` est réservé à l'échec, §2.1.2) — pack 03 §5.5 re-sync.

### 12.4 Logo dans les états offline/killed (S9)

- `offline` = le logo **n'apparaît pas** (l'état **est** vivant : la lecture locale
  **fonctionne**, la création **fonctionne** — pas de marque, pas de signal « coupé », 05
  §4.5.1 l. 2353-2361).
- `killed` = le logo **peut** apparaître en **monochrome SANS fond** (ui-libraries §9.1 l.
  383 : « Killed / disabled states (S6) = monochrome ») **si** la bannière fine l'intègre —
  le SSoT ne **précise pas** (OQ-4, cf. le pattern de `retro-actions` §12.4) ; le logo reste
  **silencieux** (« brand present but not speaking », ui-libraries §9.1 l. 374-376).

## 13. Occurrences logos (version exacte + raison + SSoT ref)

| Où | Version | Raison (designer psychology) | SSoT |
|---|---|---|---|
| **404 / not-found** (deep link invalide, ex. `?range=quarter`) | **COLORED sans fond**, au **centre** de la page (ui-libraries §9.1 l. 387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; message court + CTA primaire « Retour à l'accueil » | L'état 404 = **état vivant** (le CTA primaire = action active) ; la marque **doit** être colorée pour signifier « l'app répond encore » (ui-libraries §9.1 l. 390-392 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») | ui-libraries §9.1 l. 378-388, l. 390-392, l. 394-405 ; §6.1 l. 202 |
| **Killed / bannière « Reconnexion… »** (id. §4c, l. 1290-1296) | **MONOCHROME** (grayscale tonal, ui-libraries §9.1 l. 383 « Killed / disabled states (S6) = monochrome ») — le logo **peut** être intégré dans la bannière fine (OQ-4 : le SSoT ne **précise** pas la présence du logo dans la bannière, cf. `retro-actions` §12.4) | La marque **est présente mais silencieuse** : « brand present but not speaking » (ui-libraries §9.1 l. 374-376) ; le `killed` = l'app **attend** le resync, pas une action | ui-libraries §9.1 l. 378-388, l. 383 ; 05 §3.7 l. 1290-1296 |
| **Nocturne / High Contrast presets** (id. §10, couche 3) | **MONOCHROME** (ui-libraries §9.1 l. 384 « Nocturne + High Contrast presets = monochrome ») ; les 10 thèmes expressifs = **colorés** | « desaturated / high-contrast universes ; the 10 expressive themes = colored version » (l. 384) — le monochrome = neutralité (le preset = un **mode**, pas la marque **vivante**) | ui-libraries §9.1 l. 378-388, l. 384 ; 05 §5.5 l. 3153 |
| **Jamais** | La version **full** (fond arrondi) **n'est PAS** dans ce slug (ni dans l'app, ui-libraries §9 l. 357 « NEVER inside the app UI ») ; usage ad hoc **interdit** (ui-libraries §9 l. 352-353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else ») ; le `AgentThinkingLoader` (ui-libraries §9.3) = le **butterfly mark** est **statique** (l'organisme **respire** = les blobs, la marque **reste calme** = le mark **sans** animation, l. 420-487) — le thinking du kernel **peut** apparaître (id. §9, drill-down « Suggérer un ajustement »), le mark **reste** le SSoT `vs_monochrome_en_svg.svg` (copy stripped, §9.2 l. 407-418) | S9 l. 352-353 : la version full = **exclusivement** l'icône app externe (Capacitor / Play Store / splash) ; le mark **statique** = la **calme** de la marque pendant l'activité (le thinking = l'organisme, pas la marque) | ui-libraries §9 l. 349-369 ; §9.1 l. 390-392 ; §9.2 l. 407-418 ; §9.3 l. 420-487 |

**Règle bloquante** : 0 `usage ad hoc` du logo sur ce slug — les 4 occurrences ci-dessus
(exclusives : 404 / killed / presets / **jamais**) = les seules, toutes citées par SSoT
(ui-libraries §9.1 l. 378-388). Le `AgentThinkingLoader` (id. §9) **peut** apparaître (la
suggestion du kernel, 05 §4.5.1 l. 2380-2387) — le mark **doit** rester **statique**
(ui-libraries §9.3 l. 420-487, l'organisme = les blobs, la marque = **calme**).

## 14. Open questions (OQ)

| # | Élément | Question | Options envisagées | Décideur | SSoT manquante |
|---|---|---|---|---|---|
| **OQ-1** | `Pager` (id. 2) — le mode `Jour` par défaut vs `Semaine` | Le slug `revues-jour` = le mode `Jour` **par défaut** du `Pager` (05 §4.5.1 l. 2248 : « le `Pager` §3.4 (Jour/Semaine/Mois) »), **ou** le `Pager` **partagé** (id. 2, l. 2248-2251) est-il **persisté** par l'écran (pack 02 §3.2, l. 743-745 : « le retour retrouve le même mode et la même position ») de sorte que le slug `revues-jour` = **juste** la **route** et le mode **réel** = celui **persisté** ? Si par défaut = le deep link `(reviews)` **toujours** `Jour` (la fréquence quotidienne, l. 2231-2247) ; si persisté = le deep link **respecte** le dernier mode (le slug est **un** des 3 pagers, _inventory #24-26) | (a) Par défaut `Jour` (le slug = le mode, la **persistance** du `Pager` ne **s'applique pas** au deep link **initial**) (b) **Persisté** (le slug = la **route** `(reviews)`, le mode = le **store** UI pack 02 §3.2, l. 745 : le retour retrouve le même mode) — le `revues-jour` = le **composant** du mode `Jour`, pas la **valeur** du mode | Design System team (owner 05 §4.5) ; Product owner (la fréquence, doc §2.9) | 05 §4.5.1 l. 2248-2251 (le `Pager` = le composant **partagé**) ; 05 §3.4 l. 743-745 (la **persistance** par l'écran) ; _inventory #24-26 (3 slugs = 3 modes) — **le SSoT ne tranche pas** si le slug **force** le mode ou **respecte** la persistance |
| **OQ-2** | `Toast` (id. §6, après CTA / création) — le verbatim exact | Le SSoT 05 §4.5.1 l. 2338-2347 (le CTA « Faire la revue » ouvre la `BottomSheet` de **création**) **ne donne pas** le texte du `Toast success` (ui-libraries §6 l. 183 : le `Toast` = 3s auto-dismiss, pas de verbatim **fixe**) ; la proposition de spec = « **Revue créée ✓** » (le pattern `Toast success`, ui-libraries §6 l. 183) ou « **Synchronisée ✓** » (le resync, pack 03 §5.5) — **lequel** est correct (la **création** locale vs le **sync** serveur) ? | (a) « Revue créée ✓ » (la création **locale**, l. 2338-2347 — le `Toast` = le feedback **immédiat** de la mutation locale) (b) « Synchronisée ✓ » (le resync **différé**, pack 03 §5.5 — le `Toast` = le feedback du **sync**, pas de la création) (c) **Deux** `Toast` séquentiels (la création **puis** le sync, 05 §3.5 l. 823-841) | Product / 05 §4.5.1 owner ; Design System (05 §3.5 l. 823-841 `Toast` copy) | 05 §4.5.1 l. 2338-2347 (la **création**, pas le verbatim) ; ui-libraries §6 l. 183 (le `Toast` pattern, pas le texte) ; pack 03 §5.5 (le resync, pas le verbatim) — **le SSoT ne tranche pas** entre les 2 verbatims |
| **OQ-3** | `Callout warning` « revue en retard » (id. 10-11) — le **calcul** du retard (local vs `Job` serveur) | Le SSoT 05 §4.5.1 l. 2314-2321 dit « un `Callout warning` **posé** si la revue de la **période précédente** n'a pas été faite » (doc §2.9 « Pilotage personnel ») — le **calcul** de la comparaison (la période précédente = `pending` ?) est-il **local** (le store UI **compare** au mount, AD-7) **ou** un `Job` serveur (AD-8, 05 §4.5.1 l. 2444-2462 : les agrégats = **calculés côté serveur**) ? Si local = le `Callout` est **immédiat** ; si `Job` = le `Callout` arrive en **streaming** (`en-cours`, id. §4b — mais `en-cours` = la `Review` **se fait**, pas le calcul) | (a) Calcul **local** (le « retard » = une **lecture** du store UI, AD-7 — le `Callout` est **immédiat**, le coût = O(1) sur la période précédente) (b) `Job` serveur (le `Callout` = résultat d'un calcul **agrégat**, 05 §4.5.1 l. 2444-2462, pack 01 §4) — le `Callout` **arrive** en streaming (le `en-cours` = la période **précédente** n'est **pas encore** comparée) | Feature owner (`productivity.reviews`, master-feature-catalog l. 26) ; 05 §4.5.1 owner | 05 §4.5.1 l. 2314-2321 (le `Callout` **posé**, pas le **calcul**) vs l. 2444-2462 (les agrégats = **serveur**) — **le SSoT ne tranche pas** si la comparaison de la période précédente est un **agrégat** `Job` ou une **lecture** `Review` locale |
| **OQ-4** | Bannière `killed` « Reconnexion… » (id. §12.4) — la **présence** du logo S9 dans la bannière fine | Le SSoT 05 §3.7 l. 1290-1296 (G-M2 : « message « Reconnexion… » = **bannière fine** DS, **jamais** par composant ») ne mentionne **aucun** logo ; le `ui-libraries §9.1` l. 383 (Killed / disabled states (S6) = **monochrome**) **préscrit** un logo monochrome **dans l'état** killed (la **surface**, pas la bannière) — le logo **doit-il** être **intégré** dans la bannière fine (id. §12.4) ou **absent** (la bannière = texte **seul** + shimmer) ? (cf. `retro-actions` §12.4, OQ-9 idem — le pattern est **partagé** entre les 4 slugs `revues-*` + `retro-actions`) | (a) Bannière fine **sans** logo (le texte « Reconnexion… » **seul**, la bannière = une **surface**, le logo **peut** apparaître en monochrome **dans** la Card (id. 4, la `Badge` « Offline » **peut** porter le mark, §9.1 l. 383) (b) Bannière fine **avec** le logo monochrome SANS fond (`vs_monochrome_en_svg.svg`, §9.2 copy stripped, 16-24px, à **gauche** du texte — le §9.1 l. 383 s'applique à la **bannière**, pas à la surface Card) (c) Le logo monochrome n'apparaît **que** sur les surfaces killed **complètes** (pas sur une bannière fine) — le §4c `killed` = pas de logo, le §12.4 à **corriger** en « pas de logo dans la bannière » | Design System team ; 05 §3.7 owner (G-M2) ; S9 owner (ui-libraries §9.1) | 05 §3.7 l. 1290-1296 (la bannière fine, pas le logo) ; ui-libraries §9.1 l. 383 (le killed = monochrome, la **surface**) ; §12.4 (le pattern partagé, OQ-9 de `retro-actions`) — **le SSoT ne tranche pas** si le monochrome killed **s'applique** à la bannière ou à la Card |
| **OQ-5** | `Button ghost` « Suggérer un ajustement » (id. 11) — le comportement en `killed`/`offline` (dégradation AD-1 du CTA agent) | La chaîne `productivity.reviews` (master-feature-catalog l. 26) porte l'agent `review.run` = **CONFIRMATION_REQUIRED** — le `Button ghost` « Suggérer un ajustement » (id. 11, 05 §4.5.1 l. 2380-2387) ouvre l'`agent` §4.9.1 (le **kernel** tourne côté **serveur**, AD-12/F-09, 02 §6.4) ; le SSoT **n'indique pas** si ce CTA est **désactivé** (state `offline` : CTA cloud désactivé, 05 §3.7 l. 1266 `Modal` row ; `killed` = l'agent ne **peut pas** tourner) ou **actif** (grâce au cache du miroir local, AD-7) quand le kernel est down — **OQ-5** : le SSoT 05 §4.5.1 l. 2380-2387 ne **spécifie** **pas** le state du `Button ghost` en mode `killed`/`offline` | (a) `Button` **désactivé** (grisé + `Callout info` « Suggestion indisponible hors ligne ») en `killed`/`offline` (05 §3.7 l. 1266 : CTA cloud = **désactivé**) (b) `Button` **actif** = la suggestion **locale** (le `Task`/`Goal` AD-15 local **suffit**, AD-7 : le CTA ouvre la `BottomSheet` de suggestion **sans** le kernel, le `AgentThinkingLoader` **n'apparaît** **que** en `online`) (c) `Button` **actif** + **retry** (la suggestion est **mise en file**, resync au retour, pack 03 §5.5) | Feature owner (`productivity.reviews`, master-feature-catalog l. 26) ; 05 §4.5.1 owner ; AD-12 owner (spine l. 125) ; 02 §6.4 owner | 05 §4.5.1 l. 2380-2387 (la transition « Callout → Button ghost → agent §4.9.1 » — **pas** le state du `Button` en `killed`/`offline`) ; 02 §6.4 l. 435-453 (le kernel = **côté serveur**, AD-12/F-09 — la `surface UI` du kernel **n'est pas** consommable hors ligne) ; 05 §3.7 l. 1266 (le `Modal` CTA cloud = **désactivé** en `offline` — le `Button` = le **même** pattern, **non cité** pour ce slug) ; master-feature-catalog l. 26 (la classe `offline-capable` **sans** note de dégradation AD-1, cf. `learning.import` l. 34 « degradation: manual entry (AD-1) ») — **le SSoT ne tranche pas** le state du CTA agent en `killed`/`offline` |

> **Note OQ** : les 5 OQ ci-dessus sont **locales** au slug `revues-jour` ; le OQ-1 (le mode
> `Jour` par défaut vs persisté) **structure** le `Pager` partagé (les 3 slugs `revues-*`
> partagent **le même** composant, 05 §4.5.1 l. 2248-2251 — le OQ-1 **ouvre/ferme** la
> sémantique du deep link) ; le OQ-2 (le verbatim du `Toast`) et le OQ-3 (le **calcul** du
> retard) sont **bloquants** pour l'implémentation ; le OQ-4 (le logo dans la bannière
> killed) est **partagé** avec `retro-actions` OQ-9 (le pattern `revues-*` + `retro-actions`,
> le SSoT 05 §3.7 l. 1290-1296 ne **précise pas**) ; le OQ-5 (le CTA agent « Suggérer un
> ajustement » en `killed`/`offline`, dégradation AD-1 du slug `productivity.reviews`) est
> **nouveau** (le SSoT 05 §4.5.1 l. 2380-2387 + 02 §6.4 ne **précise pas** le state du
> `Button` hors ligne).

## Références SSoT (comptage officiel)

- **05 §4.5.1** : `_bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md` l. 2229-2409 (`revues-jour` / `revues-semaine` / `revues-mois`, doc §2.9 ; la structure 5 sections l. 2270-2297 ; le `Pager` + `SegmentedControl` l. 2248-2263 ; la `Card` posée l. 2264-2269 ; les états `pending`/`completed` l. 2251-2255 ; le `Callout warning` l. 2314-2321 ; le `EmptyState` + CTA l. 2336-2347 ; le `BottomSheet` de création pré-remplie l. 2368-2377 ; la persistance du `Pager` l. 743-745 (05 §3.4) ; la dégradation offline l. 2353-2367).
- **Routes primaires** : `(reviews)` (enveloppe, _inventory #52 : les 3 pagers #24-26 = `revues-jour` / `revues-semaine` / `revues-mois`, le `retro-actions` = l'état **post**-rétrospective de `revues-semaine`, OQ-4 partagé) ; le `Pager` (id. 2) = le composant **partagé** (05 §4.5.1 l. 2248-2251, le mode **courant** = le slug).
- **Classes offline** : `docs/features/master-feature-catalog.md` l. 26 (`productivity.reviews` = **offline-capable** ; agent `review.run` = CONFIRMATION_REQUIRED).
- **6 états S6 + sémantiques §6.1** : `docs/ui-libraries.md` §6 l. 174-187 ; §6.1 l. 189-202 (ici : `en-cours` = la `Review` `pending` **se fait** (§4b), `terminé` = la `Review` `completed` (la Card **lue**, §4b), `échec` = N/A (la revue **annulée** = une `Callout info` **historisée**, l. 2256-2262), `succès` = le `Toast` après création (§4b), `erreur` = le `Badge danger` « à resync » (§4a), 404 = logo coloré au centre (§4b / §13)).
- **Logos S9** : `docs/ui-libraries.md` §9 l. 349-369 ; §9.1 l. 371-405 (matrice l. 378-388, interdits l. 390-392, précision l. 394-405) ; §9.2 l. 407-418 (C2PA stripped copy, `vs_monochrome_en_svg.svg`) ; §9.3 l. 420-487 (`AgentThinkingLoader`, le mark **statique** = la marque **calme**, l'organisme = les blobs).
- **Motion** : `05-design-system.md` §2.6 l. 310-346 (les transitions 150-250ms, le reduced-motion = statique l. 330-334) ; `ui-libraries.md` S5 l. 169 (GPU only, `prefers-reduced-motion` = statique) ; S3 l. 143 (pas bouncy, 150-250ms seulement) ; polish.tsx (PAGE_TRANSITION `opacity 0→1`, `translateY(8px→0)`, 200ms `ease-out`).
- **Pagination** : `ui-libraries.md` S1 l. 37 (`Pagination` = shadcn) ; S8 l. 304-307 (volume : < 20 rows → `Table`, **pas** de pagination) ; **ici** = le `Pager` §3.4 (l. 737-750), pas le `Pagination` shadcn (le volume est **borné** par la période, cf. §8).
- **Thèmes** : `05-design-system.md` §5 l. 2925-3306 (5.1 l. 2931, 5.2 l. 2961-2990, 5.4 l. 3010-3047, 5.5 l. 3153, 5.7 l. 3183-3227) ; **ici** : le `SegmentedControl` actif = `accent.primary` (couche 2, la **seule** occurrence `primary` de l'écran, AD-14) ; les `Callout` / `Badge` = **figés** (05 §5.1 l. 2931) ; les 10×3 combinaisons = un comportement **par couche**, pas par thème (05 §5.2 l. 2961-2990).
- **Tokens** : `05-design-system.md` §2 l. 93-346 (2.1.2 l. 124-159, 2.2 l. 190, 2.3 l. 232, 2.4 l. 254) ; `docs/design-system/overview.md` §2 l. 15-25 (discipline tokens, AD-17) ; `ui-libraries.md` S4 l. 145-160 (tokens via CSS variables, `var(--aurora-*)`).
