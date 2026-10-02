# retro-actions — Rétro-actions (journal des décisions, post-rétrospective)

Status: SPÉCIFIABLE (OQ: 8) · Module : Productivité · Route : (reviews) · SSoT : WDS 06.3 + 05 §4.5.1 (l. 2229-2408) + 05 §3.4 `Pager` (l. 737-750) + 05 §3.7 (l. 1244-1309) + ui-libraries S1/S3/§6/§9 + master-feature-catalog §2 l. 26 (`productivity.reviews`, offline-capable)

> Le `retro-actions` = le **point de clôture** de la chaîne de rétrospective :
> l'état **post-rétrospective** (après la revue semaine bouclée, WDS 06.2) où
> l'utilisateur voit les **écarts documentés** (S-07 Objectifs, jalons non
> atteints en rouge) + les **actions correctives identifiées** (blocs BAC) + le
> **rythme posé** pour la semaine suivante — et **ferme la boucle** Self-Improve
> → Adapt (ADR §19). Ce doc spécifie la zone de contenu des 3 sections + CTA
> fixe ; les zones partagées (BottomNav, 404, offline global) sont référencées
> et non dupliquées.

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | **Voir** les écarts documentés (S-07) + les actions correctives (BAC) + le rythme posé — et **fermer** la boucle rétrospective (preuve : rythme posé + régularité mesurée + actions planifiées) | WDS 06.3 §4 ; 05 §4.5.1 l. 2229-2247 |
| Contexte | Device mobile (Phase 1) ; moment = **dimanche soir**, fin de la semaine d'étude, après la revue semaine bouclée (WDS 06.2) ; réseau = indifférent (lecture locale AD-7) | WDS 06.3 §3 ; master-feature-catalog l. 26 |
| Fréquence | Basse : un **clôture de rétrospective par semaine** (la revue = action périodique, pas un widget quotidien) | 05 §4.5.1 l. 2231-2247 (doc §2.9) |
| État émotionnel cible | **Résolu** : l'utilisateur voit que la stagnation est **documentée** (pas cachée) et que les actions correctives sont **concrètes** (pas une vague intention) — la preuve que la trajectoire s'adapte | WDS 06.3 §3 (Hope) ; ADR §19 |
| Erreur la plus probable | L'utilisateur **scrolle** à la recherche d'un CTA d'action qui n'existe pas (le CTA fixe = **un seul**, AD-14 ; les 3 sections sont **consultatives**, l'action = le CTA) | WDS 06.3 §3 (Contrainte UX) ; 05 §4.5.1 AD-14 |
| Ce que l'écran RÉSOUT | « Ma rétrospective est bouclée : que se passe-t-il maintenant ? » = les écarts + les actions + le rythme — **fermeture de la boucle** (pas un formulaire, pas une proposition libre de l'agent) | WDS 06.3 §1 ; 05 §4.5.1 l. 2244-2247 |

## 2. Zones

- **header** : `TopBar` « Revue » (05 §3.4 l. 659-668) + `Pager` §3.4 (Jour | Semaine | Mois, l. 737-750) + `SegmentedControl` « À faire / Faite » (l. 2249-2263 : le statut de la revue — `pending` / `completed`). Le `retro-actions` = **état « Faite »** (la revue est **bouclée**).
- **content** : **3 sections compactes** (WDS 06.3 §6, Option A close OQ-1) :
  1. `Écarts documentés` — jalons non atteints (S-07), en rouge (`danger`), `Card` posée (05 §4.5.1 l. 2264-2276 : « une `Review` = une `Card` **posée** »)
  2. `Actions correctives` — les 2 blocs BAC identifiés (compactes, pas de Gantt, WDS 06.3 §6 note) — `RoutineStep` (05 §4.5.1 l. 2288-2294)
  3. `Rythme posé` — calendrier de la semaine suivante (S-05 compact), les 2 blocs BAC intégrés — `CalendarView` / `GanttRow` (05 §3.6 ; WDS 06.3 §6 option A)
- **footer** : `BottomNav` (5 items figés, 05 §3.4 l. 670-688)
- **CTA fixe** : `Button primary` « Planifier la semaine » (WDS 06.3 §3 Contrainte UX, AD-14 : le **seul** CTA d'action ; → calendrier S-05, pose des 2 blocs BAC)
- **Breadcrumb** : **n'existe pas** — le `retro-actions` est une **feuille** du module Productivité (WDS 06.3 §6, pas de hiérarchie AD-6)
- **Surfaces flottantes** : `Toast` (après « Planifier la semaine »), `Callout info` (reconnexion, killed). Pas de `BottomSheet` de création ici (la création = WDS 06.2, l'état « À faire »).

## 3. Éléments / widgets

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| 1 | `TopBar` « Revue » | `TopBar` (05 §3.4 l. 659-668) | shadcn `header` | `surface`, `md` 600 titre, `text-muted` `xs` sous-titre (période) | desktop = titre + date à droite | 05 §4.5.1 l. 2248 |
| 2 | `Pager` (Jour | Semaine | Mois) | `Pager` §3.4 (l. 737-750) | shadcn `tabs` (ui-libraries S1 l. 24) | `primary-surface` pill, `text-primary` icône + label `xs` | 05 §4.5.1 l. 2249-2251, l. 2254-2263 |
| 3 | `SegmentedControl` « À faire / Faite » | `SegmentedControl` §3.4 (l. 2251-2263) | shadcn `tabs` variant=segmented | `primary` (Faite = actif), `text-secondary` (À faire) | n/a | 05 §4.5.1 l. 2251-2263 |
| 4 | `Card` « Écarts documentés » (section 1) | `Card` **posée** (05 §4.5.1 l. 2264-2276) | shadcn `card` | `surface`, `radius.md`, `space.4`, `shadow.2` ; jalons non atteints = `danger` (figé, §5.1) | desktop = 2 colonnes (l. 2399-2407) | 05 §4.5.1 l. 2264-2276 ; WDS 06.3 §6 option A |
| 5 | Jalon non atteint (`Badge danger`) | `Badge` (05 §3.3 l. 531-544) | shadcn `badge` variant=destructive | `danger`, `danger-surface`, `radius.sm` ; `JetBrains Mono` `xs` pour la date | n/a | 05 §4.5.1 l. 2264-2276 (S-07 jalons non atteints en rouge) |
| 6 | `Card` « Actions correctives » (section 2) | `RoutineStep` (05 §4.5.1 l. 2288-2294) | shadcn `card` + liste `RoutineStep` | `surface`, `space.3` ; `primary` pour le titre de l'action | n/a | 05 §4.5.1 l. 2288-2294 ; WDS 06.3 §6 |
| 7 | Action corrective (BAC, `RoutineStep`) | `RoutineStep` (05 §4.5.1 l. 2290-2293) | shadcn `list-item` (pas ion-list — S3 l. 136) | `text-primary` `sm`, `JetBrains Mono` `xs` (durée « 30 min »), `space.2` | n/a | 05 §4.5.1 l. 2288-2294 ; WDS 06.3 §6 (compactes, pas de Gantt) |
| 8 | `Card` « Rythme posé » (section 3) | `CalendarView` / `GanttRow` compact (05 §3.6 ; WDS 06.3 §6 option A) | `CalendarView.tsx` (SSoT code, `packages/ui`) + shadcn `card` | `surface`, `border`, `space.2` ; jours en `JetBrains Mono` `xs` | desktop = Gantt interactif (WDS 06.3 §6 option C, **rejeter** budget OQ-11) | WDS 06.3 §6 option A ; 05 §3.6 |
| 9 | Semaine suivante (7 jours, compacte) | `GanttRow` (05 §3.6) | `GanttRow.tsx` (SSoT code) | `border` lignes, `text-secondary` `xs`, `space.2` gap | n/a | WDS 06.3 §6 (calendrier compact S-05) |
| 10 | Bloc BAC posé sur la semaine | `Badge` `primary` (WDS 06.3 §6 note) | shadcn `badge` variant=default | `primary`, `primary-surface`, `radius.sm` ; `JetBrains Mono` `xs` « BAC 30 min » | n/a | WDS 06.3 §6 (les 2 blocs BAC intégrés) |
| 11 | Routines tenues (jours sans BAC) | `KeyValueList` (05 §4.5.1 l. 2277-2280, « mixtes ») | shadcn `list-item` | `text-secondary` `sm`, `space.2` | n/a | WDS 06.3 §6 |
| 12 | Ligne de preuve « rythme posé » (texte) | `Callout info` (05 §3.3 l. 628-641) | shadcn `alert` variant=info | `info` (figé, §5.1), `text-secondary` `sm` | n/a | WDS 06.3 §6 note (l. 157-159 : « 2 blocs BAC + routines tenues = rythme posé ») |
| 13 | CTA fixe « Planifier la semaine » | `Button primary` (05 §3.1 l. 365-390) | shadcn `button` variant=default | `primary`, `on-primary`, 56px (`lg`, 05 §3.1 l. 381) | desktop = `Button` dans la `TopBar` (05 §4.4.1 pattern) | WDS 06.3 §3 (Contrainte UX) ; AD-14 |
| 14 | `BottomNav` (footer) | `BottomNav` (05 §3.4 l. 670-688) | shadcn `tab-bar` | `primary-surface` pill, 56px + safe-area | n/a | 05 §3.4 l. 670-688 ; WDS 06.3 §6 (5 tabs S-31 shared) |

**Règle interdits** : `ion-list` pour les sections (S3 l. 136, → shadcn/AG Grid) ; `ion-item` pour les actions correctives (S3 l. 137, → shadcn/Radix) ; Gantt interactif (WDS 06.3 §6 option C **rejeter** — budget OQ-11 : 30 fps, 1,5 s TTI, 300 Ko gz) ; proposition libre de l'agent (AD-14, WDS 06.3 §3 : le CTA = **planifier**, pas « l'agent suggère »).

## 4. États (6 S6 + sémantiques §6.1) — par élément async

### 4a. Matrice S6 (ui-libraries §6 l. 174-187)

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| 1-3. `TopBar` + `Pager` + `SegmentedControl` | n/a (composants chrome, pas de data async) | n/a | n/a | n/a | `Badge` « Offline » en `TopBar` (ui-libraries §6 l. 184) | n/a (chrome) |
| 4-5. `Card` « Écarts documentés » + `Badge danger` | `Skeleton` de la Card (05 §4.5.1 l. 2334-2337, « store local, court » ; pack 02 §7 : > 300ms = contenu partiel en dessous) ; transition d'entrée `opacity 0→1` 200ms (polish.tsx) | « Semaine parfaite — pas de correctif nécessaire » (WDS 06.3 §7 État vide) ; `Callout info` (la section **existe**, pas de jalon non atteint = pas de `Badge danger`) ; le CTA (id. 13) reste **actionnable** (AD-14 : le chemin, invariant) | Un écart non syncé = `Badge danger` « à resync » sur la Card (05 §4.5.1 l. 2348-2352, la revue **reste** lisible, AD-7) | `Toast` (3s auto-dismiss, « Synchronisé ») après resync de la section | Identique (lecture locale AD-7, 05 §4.5.1 l. 2353-2367 : les revues **restent lues**) | `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296) ; les données du mirror local s'affichent (AD-7) |
| 6-7. `Card` « Actions correctives » + `RoutineStep` | `Skeleton` des `RoutineStep` (idem id. 4) | « Pas d'action corrective identifiée » (WDS 06.3 §7) ; `Callout info` ; le CTA reste **actionnable** | Une action non syncée = `Badge danger` « à resync » (idem id. 4) | `Toast` « Synchronisé » | Identique (locale) | `Skeleton` + « Reconnexion… » ; mirror local visible |
| 8-11. `Card` « Rythme posé » + `GanttRow` + `Badge primary` + `KeyValueList` | `Skeleton` des 7 jours (idem) | « Semaine suivante non planifiée » (WDS 06.3 §7) ; `Callout info` ; le CTA **est** le chemin (AD-14) | Une ligne non syncée = `Badge danger` « à resync » ; la ligne **reste** dans le Gantt (AD-7) | `Toast` « Synchronisé » | Identique (locale) | `Skeleton` + « Reconnexion… » |
| 12. `Callout info` « rythme posé » | n/a (le `Callout` **est** l'état, 05 §3.7 l. 1286) | n/a (pas de preuve = pas de `Callout`) | n/a | n/a | n/a (le calcul de preuve est **local**, AD-7) | n/a |
| 13. CTA « Planifier la semaine » | n/a (05 §3.7 l. 1254) | n/a (le CTA = **chemin**, AD-14 : il **reste** actionnable même si les sections sont vides) | n/a | n/a | **Reste actif** (WDS 06.3 §7 : « le CTA reste **actionnable** » — la pose des 2 blocs BAC sur le calendrier S-05 = **écriture locale**, sync au retour réseau, AD-7/pack 03) | n/a |
| 14. `BottomNav` | n/a (chrome) | n/a | n/a | n/a | n/a | n/a |

**Règle de test** (pack 02 §11, 05 §3.7 l. 1303-1306) : composant « écran » = test par écran qui compose l'état ; composant « composant » = test de rendu par état.

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202)

| État | Rendu | Source SSoT |
|---|---|---|
| `en-cours` | N/A — le `retro-actions` n'exécute pas d'opération avec résultats partiels (pas de streaming, pas de QCM) ; la **revue** = l'action déjà **bouclée** (05 §4.5.1 l. 2254-2259, `completed`) ; le « en-cours » = WDS 06.2 (la revue **se fait**, pas elle est faite) | WDS 06.3 §2 (Précédent 06.2) ; 05 §4.5.1 l. 2254-2259 |
| `terminé` | `Card` « Écarts documentés » + `Badge danger` (id. 4-5) + `Callout info` « rythme posé » (id. 12) = le **statut terminal positif** de la rétrospective : la revue est **bouclée**, les écarts sont **documentés**, les actions sont **planifiées** — l'objet (la revue) est `completed` (AD-15, 05 §4.5.1 l. 2255) | 05 §4.5.1 l. 2255 ; ui-libraries §6.1 l. 198 ; WDS 06.3 §4 (User Goal : « fermer la boucle ») |
| `échec` | N/A — le `retro-actions` est un écran **consultatif** de clôture : le « échec » (la stagnation RDM) est **documenté** dans la section 1 (id. 4-5, `Badge danger`), pas un échec **opérationnel** de l'écran ; l'opération (la pose des 2 blocs BAC sur S-05) = **écriture locale**, pas un échec retryable | 05 §4.5.1 l. 2348-2352 ; WDS 06.3 §4 |
| `succès` | `Toast` (S6 `success`, 3s auto-dismiss) après « Planifier la semaine » (id. 13) — les 2 blocs BAC sont **posés** sur le calendrier S-05 de la semaine suivante (AD-7 écriture locale, sync différée) | ui-libraries §6 l. 183 ; WDS 06.3 §2 (CTA 06.2 → S-13) |
| `erreur` | `Badge danger` « à resync » (id. 4-5) — transitoire, retry in-place (auto-resync au retour réseau, 05 §4.5.1 l. 2348-2352) ; ≠ `échec` (opérationnel) | 05 §4.5.1 l. 2348-2352 ; ui-libraries §6.1 l. 201 |
| `404 / not-found` | Page entière (partagée avec l'enveloppe `reviews`) : logo AURORA **coloré sans fond** au **centre** (ui-libraries §9.1 l. 387, §6.1 l. 202), message court, CTA primaire « Retour à l'accueil » ; le slug `retro-actions` est un **état** du `Pager` (WDS 06.3 §6), pas une route distincte — l'état 404 s'applique à l'enveloppe `/progress` (WDS 06.3 route `/progress`) | ui-libraries §6.1 l. 202 ; §9.1 l. 387 |

### 4c. `killed` (tout flux serveur)

Le seul flux serveur de ce slug = la **re-synchronisation** de la revue (AD-8, Job
persisté — 05 §4.5.1 l. 2353-2367 : « une revue **n'exige jamais** le réseau »).
`killed` = `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ;
ui-libraries §6 l. 185). Les **3 sections** restent visibles du mirror local
(AD-7, WDS 06.3 §7 État Offline : « Bandeau fine 'hors-ligne' », CTA reste
**actionnable**).

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| `Pager` (id. 2) | tap « Semaine » → le contenu **switch** (pas un push, 05 §4.5.1 l. 2249-2251) ; le contenu slide horizontalement | 150-200ms `ease-out` (05 §2.6 l. 310-320) | `transform: translateX` | `static` (05 §2.6 l. 330-334, règle 2) | 05 §4.5.1 l. 2249-2251 ; polish.tsx l. 23-28 |
| `SegmentedControl` (id. 3) | tap « Faite » (état courant) → **aucun** feedback (le statut est déjà `completed`) ; tap « À faire » → push `/progress` **état pré** (WDS 01.2) | 200ms `ease-out` | `opacity` | `static` | 05 §4.5.1 l. 2254-2263 |
| Jalon `Badge danger` (id. 5) | tap → push `objectifs-detail` §4.3.1 (le jalon **est** un objectif, S-07) | 200ms `ease-out` (PAGE_TRANSITION, polish.tsx) | `translateY(8px→0)` | `static` | 05 §4.5.1 l. 2264-2276 ; polish.tsx l. 23-28 |
| Action corrective `RoutineStep` (id. 7) | tap → **aucun** drill-down (l'action est **compacte**, WDS 06.3 §6 : « pas de Gantt interactif ») ; la navigation vers le **calendrier** = le CTA (id. 13) | n/a | n/a | n/a | WDS 06.3 §6 (Option A, budget OQ-11) |
| CTA « Planifier la semaine » (id. 13) | press → `scale 0.95` (`anim.fast`), puis navigate `/calendar` (S-05, pose des 2 blocs BAC sur la semaine suivante) | 150ms | `transform: scale(0.95)` | `static` | 05 §3.1 l. 383-385 ; 05 §2.6 l. 316 ; WDS 06.3 §3 |
| `BottomNav` (id. 14) | tap tab → navigation tab (slide, Ionic) | 200ms `ease-out` | `transform: translateX` | `static` | polish.tsx ; 05 §3.4 l. 670-688 |
| `GanttRow` (id. 8-9) | **AUCUNE** animation (les données du rythme posé = **données**, 05 §2.6 l. 323-330, règle 1 : « les données ne s'animent jamais ») | n/a | n/a | n/a | 05 §2.6 l. 323-330 |

**Règles bloquantes** : pas de `layout` animations sur mobile (ui-libraries S5 l. 169) ;
pas de bouncy (ui-libraries S3 l. 143) ; 150-250ms seulement (S3 l. 143) ;
`prefers-reduced-motion` = **tout** `static` (05 §2.6 l. 330-334, règle 2).

## 6. Modals / BottomSheets / Drawers (spécifiques au contenu post-retrospective)

| Surface | Déclencheur | Contenu | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|
| N/A (pas de `BottomSheet` de **création** ici — la création = WDS 06.2, état « À faire ») | n/a | n/a | n/a | n/a | 05 §4.5.1 l. 2336-2347 (la CTA « Faire la revue » ouvre la `BottomSheet` de **création**, pas ici) |
| `Toast` (après CTA) | tap CTA « Planifier la semaine » (id. 13) | « Semaine planifiée — 2 blocs BAC posés » (3s auto-dismiss) | auto 3s (ui-libraries §6 l. 183) | `opacity` 200ms | ui-libraries §3.5 l. 823 ; 05 §3.5 l. 823-842 |
| `Callout info` (killed) | `killed` (G-M2) | « Reconnexion… » (bannière fine, 05 §3.7 l. 1290-1296) | n/a (persistante tant que le flux est down) | n/a | 05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185 |

Le `Modal` de **confirmation** « Planifier la semaine ? » (le CTA pose **2** blocs BAC
sur le calendrier S-05 de la semaine suivante — l'utilisateur **décide**, 05 §4.5.1
l. 2358-2367 : « l'agent **suggère**, l'utilisateur **décide** ») = **OQ-3**.

## 7. Formulaires

| Champ | Lib | Validation | Clavier mobile | Persistance | SSoT |
|---|---|---|---|---|---|
| N/A — le `retro-actions` est **consultatif** (pas de formulaire) ; les 3 sections sont **lues** du mirror local (AD-7) ; l'écriture = le CTA (id. 13) qui **pose** les 2 blocs BAC sur S-05 (la création des **événements** = le formulaire du calendrier S-05, pas ici) | n/a | n/a | n/a | La revue (écarts + actions + rythme) = `Review` AD-15 `completed` (05 §4.5.1 l. 2255) dans SQLite (AD-6), sync différée (AD-7) | 05 §4.5.1 l. 2229-2408 ; WDS 06.3 §7 |

**Interdiction** : un `TextField` qui cache le label quand vide (05 §3.2 l. 434-436) ;
`ion-item` pour les actions correctives (S3 l. 137, → shadcn/Radix) ; proposition
libre de l'agent dans un formulaire (AD-14, WDS 06.3 §3).

## 8. Pagination

**Règle unique nommée** : `Pager` jour-semaine-mois (05 §3.4 l. 737-750) — le `Pager`
**est** la pagination temporelle de ce slug (le `SegmentedControl` `Jour | Semaine |
Mois` + la ligne de navigation avant/après).

- **Pas de shadcn Pagination ni AG Grid** : le volume = **borné** par la période (1
  semaine, WDS 06.3 §6 : « fenêtre mobile compacte, 1 semaine visible à la fois, pas de
  zoom/drag », OQ-11 budget) ; les 3 sections = un nombre **fixe** d'éléments (écarts +
  2 actions BAC + 7 jours = < 20 items max, ui-libraries S8 l. 304-307 : < 20 rows →
  `Table`, pas de pagination).
- **Params** : le `Pager` est **persisté** par l'écran (store UI pack 02 §3.2,
  05 §3.4 l. 743-745) ; le retour retrouve le même mode (règle de non-surprise, l. 745).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** depuis WDS 06.2 (revue semaine bouclée) | CTA 06.2 « Voir les actions correctives » → push `/progress` (S-13, état post-retrospective) ; `PAGE_TRANSITION` : `opacity 0→1`, `translateY(8px→0)`, 200ms `ease-out` | polish.tsx l. 23-28 ; WDS 06.3 §2 (Entrée 1) ; 02 §6.1 (détail par-dessus le tab) |
| **Retour natif** (back Android) | Depuis WDS 06.2 → retour sur 06.2 (la revue **n'est pas** encore bouclée) ; depuis le tab 4 (Progress) → retour sur le tab courant (le `retro-actions` = **état** du `/progress`, pas une route, WDS 06.3 §6) | 02 §6.3 l. 426-428 ; WDS 06.3 §2 (Entrée 2, 3) |
| **CTA « Planifier la semaine »** | Navigate `/calendar` (S-05) — les 2 blocs BAC sont **posés** sur la semaine suivante (écriture locale, AD-7) ; le `/calendar` ouvre **par-dessus** le tab courant (02 §6.1) | WDS 06.3 §3 (Contrainte UX) ; 02 §6.1 ; polish.tsx l. 23-28 |
| **Drill-down jalon** (id. 5) | tap `Badge danger` → push `objectifs-detail` §4.3.1 (le jalon **est** un objectif S-07) | 05 §4.5.1 l. 2264-2276 ; 02 §6.1 |
| **404** (deep link invalide, ex. `?range=quarter`) | → `not-found` (enveloppe, `calendrier.md` §4b pattern) : logo AURORA coloré au centre, CTA « Retour à l'accueil » | ui-libraries §6.1 l. 202 ; §9.1 l. 387 |

## 10. Thèmes

Comportement par couche (05 §5 l. 2925-3306 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#FFFFFF` / Dark `#121212`) : fournit `surface`,
  `text-primary/secondary`, `border`, `shadow` — les tokens **géométriques** des 3
  sections (Cards = `surface`, jalons = `border`, `GanttRow` = `border` lignes).
  Les 10 thèmes vivants **ne redéfinissent jamais** les sémantiques (05 §5.1 l. 2931,
  règle bloquante).
- **Couche 2 — Expressive** (4 accents + chartPalette, 05 §5.4 l. 3010-3047) : le
  `Badge primary` (id. 10, blocs BAC) = dérivé de `accent.primary` ; la `GanttRow`
  (id. 8-9) suit le `chartPalette` du thème courant (ex. `aurora` = bleu électrique,
  `lagoon` = teinte lagoon). **Jamais de valeur brute par thème** (AD-17, l. 2961).
  Le WDS 06.3 **défaut** = Nocturne (OQ-16, WDS 06.3 §5 : thème Nocturne par défaut) —
  Nocturne = **preset** (couche 3), pas un thème expressif (05 §5.5 l. 3153).
- **Couche 3 — Presets** (`slate` / `nocturne` / `high-contrast`, 05 §5.5 l. 3153) :
  Nocturne = fond sombre (le WDS 06.3 variante par défaut, l. 100-102) ; High
  Contrast = tap targets 56px (05 §6.3) ; les `Callout info` / `Badge danger` =
  **figés** (pas redéfinis par le thème, 05 §5.1 l. 2931).
- **Test 10×5** (05 §5.7 l. 3183-3227) : le `retro-actions` doit passer les 5 styles
  × 10 thèmes (le `chartPalette` du Gantt, l. 3032).

## 11. A11y (WCAG AA, 05 §6.3)

- Tap targets **≥ 44px** (56px en High Contrast, 05 §6.3) : le CTA (id. 13) = **56px**
  (`lg`, 05 §3.1 l. 381) ; les `RoutineStep` (id. 7) = **44px** min ; le `GanttRow`
  (id. 8-9) = **44px** par jour (la grille est **bornée** 7 jours, pas de tap ambigu).
- `aria-label` sur **tous** les icon buttons (le `Pager` = icône + texte visible, pas
  icon-only ; si icon-only = `aria-label` obligatoire, 05 §3.1 l. 388-396, test CI
  §7).
- `letter-spacing 0` (05 §6.3) ; `focus-visible` ring = `focus-ring` (token, 05 §2.4
  l. 254-264) ; le `Callout info` (id. 12) porte `role="status"` (le `Callout` est
  **posé**, pas un toast, AD-14).
- Le `Badge danger` (id. 5, jalon non atteint) = **texte + couleur** (pas couleur
  seule, 05 §6.3 non-color-only) ; le `GanttRow` (id. 8-9) = les jours portent un
  **texte** (lun/mar/… `xs` `JetBrains Mono`), pas une pastille de couleur seule.

## 12. Offline

- **Classe offline** (master-feature-catalog l. 26) : `productivity.reviews` =
  **offline-capable** (daily/weekly/monthly + decisions journal ; agent
  `review.run` = CONFIRMATION_REQUIRED ; offline-capable). Le Plan (kernel
  l. 197-198 : `offlineClass` = `offline-capable`) **ne doit pas** planifier
  d'étape online-only dans une fenêtre offline.
- **Miroir local — ce qui VIT offline** (AD-7 local-first / AD-12) :
  - Les 3 sections sont **lues** du mirror local (PowerSync/SQLite, pack 02 §7 :
    UI reads local only) — les 7 jours du « Rythme posé » **inclus**.
  - Le CTA (id. 13) **reste actionnable** (WDS 06.3 §7 État Offline) — la pose
    des 2 blocs BAC sur S-05 = **écriture locale** via `LocalCommandRepository`
    (AD-7), upsync queue, sync au retour réseau (pack 03 §5.5 re-sync).
  - Le statut « à resync » (id. 4a `error`) **est calculé localement** :
    `SyncStatus` (AD-7) + CRDT server-wins / OR-Set — l'indication ne **meurt
    jamais**.
  - `AgentRunState` (AD-12) : la surface UI du kernel est un simple **état**
    lisible hors-ligne (le kernel **n'exécute rien** sur-device, F-09) —
    sur ce slug : aucune requête agent (le CTA = écriture locale, pas une
    action du kernel, AD-7/AD-14) → pas de dégradation `AgentRunState` ici.
- **Ce qui MEURT (killed)** (AD-13/G-M2, kill matrix kernel S12) :
  - `agent review.run` = **agent** (CONFIRMATION_REQUIRED, master-feature-catalog
    l. 26) → **killed** (la suggestion de création de la revue = WDS 06.2 ; la
    boucle d'ajustement 05 §4.5.1 l. 2380-2387 : « l'agent **suggère**,
    l'utilisateur **décide** » = un flux serveur qui **meurt**).
  - Job serveur de **re-sync** (AD-8) = **killed** : les données déjà
    synchronisées **demeurent** lues (les 3 sections + le « rythme posé »
    restants sur le mirror) ; seulement la **re-synchronisation** est down.
  - Rendu `killed` (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) :
    `Skeleton` + bannière fine « Reconnexion… » + logo **monochrome** (ui-libraries
    §9.1 l. 383, cf. §13).
- **Dégradation AD-1 (vendor isolation)** : le CTA **reste actif** — la pose des
  blocs BAC = écriture **locale** (AD-7), **indépendante** du kernel ; le `retro-actions`
  n'importe **aucun** vendor d'AI (AD-1, kernel : device = `AgentRunState` seul,
  AD-12/F-09). Les 3 sections **restent visibles** (AD-7, 05 §4.5.1 l. 2353-2367 :
  « une revue **n'exige jamais** le réseau »).
- **Au retour du réseau** : les actions **nouvelles** syncées depuis le cloud
  apparaissent avec leur `Badge` « nouveau » `primary` (indigo, pas rouge —
  05 §3.4 l. 748-750, le danger est réservé à l'échec) — pack 03 §5.5 re-sync.

## 13. Occurrences logos (version exacte + raison + SSoT ref)

| Où | Version | Raison (designer psychology) | SSoT |
|---|---|---|---|
| **404 / not-found** (deep link invalide, ex. `?range=quarter`, id. 9) | **COLORED sans fond**, au **centre** de la page (ui-libraries §9.1 l. 387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; message court + CTA primaire « Retour à l'accueil » | L'état 404 = **état vivant** (le CTA primaire = action active) ; la marque **doit** être colorée pour signifier « l'app répond encore » (ui-libraries §9.1 l. 390-392 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») | ui-libraries §9.1 l. 378-388, l. 390-392, l. 394-405 ; §6.1 l. 202 |
| **Killed / bannière « Reconnexion… »** (id. 4a `killed`, l. 1290-1296) | **MONOCHROME** (grayscale tonal, ui-libraries §9.1 l. 383 « Killed / disabled states (S6) = monochrome ») — le `Badge` « Offline » (id. 1-3) reste **coloré** (il est vivant, pas killed) | La marque **est présente mais silencieuse** : « brand present but not speaking » (ui-libraries §9.1 l. 374-376) ; le `killed` = l'app attend le resync, pas une action | ui-libraries §9.1 l. 378-388, l. 383 ; 05 §3.7 l. 1290-1296 |
| **Nocturne / High Contrast presets** (id. 10, couche 3) | **MONOCHROME** (ui-libraries §9.1 l. 384 « Nocturne + High Contrast presets = monochrome ») ; les 10 thèmes expressifs = **colorés** | « desaturated / high-contrast universes ; the 10 expressive themes = colored version » (l. 384) — le monochrome = neutralité ; le WDS 06.3 **défaut** = Nocturne (OQ-16, WDS 06.3 §5) → le logo **monochrome** est l'occurrence **courante** sur ce slug | ui-libraries §9.1 l. 378-388, l. 384 ; 05 §5.5 l. 3153 |
| **Jamais** | La version **full** (fond arrondi) **n'est PAS** dans ce slug (ni dans l'app, ui-libraries §9 l. 357 « NEVER inside the app UI ») ; usage ad hoc **interdit** (ui-libraries §9 l. 352-353) | S9 l. 352-353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else » ; la version full = **exclusivement** l'icône app externe (Capacitor / Play Store / splash) | ui-libraries §9 l. 349-369 ; §9.1 l. 390-392 ; §9.2 l. 407-418 (C2PA stripped) |

**Règle bloquante** : 0 `usage ad hoc` du logo sur ce slug — les 3 occurrences
ci-dessus (exclusives : 404 / killed / presets) = les seules, toutes citées par
SSoT (ui-libraries §9.1 l. 378-388). Le `AgentThinkingLoader` (ui-libraries
§9.3) **n'apparaît pas** ici (ce slug n'a pas de flux de **thinking** du kernel —
le CTA « Planifier la semaine » = **écriture locale**, pas une requête agent,
AD-7/AD-14).

## 14. Open Questions (OQ)

| # | Élément | Question | Options envisagées | Décideur | SSoT manquante |
|---|---|---|---|---|---|
| **OQ-1** | `CalendarView` / `GanttRow` (id. 8-9) | Le « Rythme posé » (section 3) est-il un **wrapper FullCalendar** (ui-libraries S1 l. 22 : « Calendar = FullCalendar, NOT ion-calendar ») **ou** un `GanttRow` maison (SSoT code : `packages/ui/src/components/ui/GanttRow.tsx`, mobile-first gantt line, 05 §3.6) ? Si wrapper = le FullCalendar **affche** la semaine suivante en `timeGridWeek` compact ; si maison = le `GanttRow` (line par jour, pas de zoom/drag, WDS 06.3 §6 option A) — la règle S1 « 1 écran = 1 système de composants » **s'applique** (FullCalendar + GanttRow = 2 libs, S8 l. 333) | (a) `GanttRow` maison (mobile-first, compact, WDS 06.3 §6 option A) (b) FullCalendar wrapper (le S-05 **est** déjà FullCalendar — cohérent avec le calendrier existant) | UI owner (`packages/ui`) | SSoT code : `GanttRow.tsx` (mobile-first gantt line, 05 §3.6) ; WDS 06.3 §6 (Option A : « calendrier compact S-05 ») |
| **OQ-2** | `Callout info` « rythme posé » (id. 12) | Le **calcul** de la preuve (WDS 06.3 §6 note : « 2 blocs BAC + routines tenues = rythme posé ») est-il **local** (le store UI calcule au mount, AD-7) **ou** un `Job` serveur (AD-8, 05 §4.5.1 l. 2444-2462 : les agrégats = **calculés côté serveur**) ? Si local = le `Callout` est **immédiat** ; si `Job` = le `Callout` arrive en streaming (`en-cours`, id. 4b — mais `en-cours` = N/A ici, id. 4b) | (a) Calcul **local** (le « rythme posé » = une **lecture** du store, pas un agrégat serveur) (b) `Job` serveur (le `Callout` = résultat d'un calcul `ProgressTrend`, pack 01 §4) | Feature owner (`productivity.reviews`, master-feature-catalog l. 26) | 05 §4.5.1 l. 2444-2462 (l'`analytics` = calculs serveur) vs WDS 06.3 §6 (le « rythme posé » = lecture locale) — **le SSoT ne tranche pas** si le « rythme posé » est un agrégat `ProgressTrend` ou une lecture `Review` locale |
| **OQ-3** | CTA « Planifier la semaine » (id. 13) | Le CTA ouvre-t-il **directement** `/calendar` (S-05, les 2 blocs BAC sont **pré-posés** dans le calendrier) **ou** un `Modal` de confirmation (id. 6 : « Planifier la semaine ? 2 blocs BAC posés » → Confirm / Cancel) ? 05 §4.5.1 l. 2358-2367 dit « l'agent **suggère**, l'utilisateur **décide** » — le CTA **pose** les blocs (pas l'agent qui suggère), donc **pas** de confirmation ? Mais 2 blocs posés sur le calendrier = **mutation** du planning (05 §4.4.1 l. 1974-1979) → `Modal` de confirmation requis ? | (a) Navigate **directe** `/calendar` (le CTA = la décision, AD-14 : l'utilisateur **a déjà décidé** en tapant) (b) `Modal` de confirmation (la mutation du planning = 2 événements, confirmation requise, 05 §3.5 l. 761-779) | Product / 05 §4.5.1 owner | 05 §4.5.1 l. 2358-2367 (l'utilisateur décide) vs 05 §3.5 l. 761-779 (Modal = « interrompt et décide ») |
| **OQ-4** | `Pager` (id. 2) — le `retro-actions` = état du `/progress` ou slug distinct ? | Le WDS 06.3 (route `/progress`, S-13 état post-retrospective) et le SSoT 05 §4.5.1 (`revues-jour` / `revues-semaine` / `revues-mois`, doc §2.9) — le `retro-actions` = **une variante** de `revues-semaine` (le `Pager` §3.4 l. 737-750, le `SegmentedControl` « À faire / Faite » l. 2254-2263) **ou** un **slug distinct** (WDS 06.3 `slug: retro-actions`, l. 3) ? Si variante = section du `revues-semaine.md` ; si distinct = ce doc | (a) Variante de `revues-semaine` (le `SegmentedControl` « Faite » = l'état post, 05 §4.5.1 l. 2254-2259) (b) Slug **distinct** `retro-actions` (WDS 06.3, l. 3 — le « journal des décisions » = un écran **propres** à la clôture, pas un mode du `Pager`) | Design System team (owner 05 §4.5) | WDS 06.3 l. 3 (`slug: retro-actions`) vs 05 §4.5.1 l. 2249-2251 (le `Pager` = le composant partagé, les 3 écrans partagent **le même** composant) |
| **OQ-5** | Section 1 « Écarts documentés » (id. 4-5) | Les **écarts** (jalons non atteints, S-07) sont-ils **lus** de `objectifs-detail` §4.3.1 (le S-07 = un module **différent**, 05 §4.3) **ou** calculés **localement** par le `retro-actions` (le bilan des tâches = `DataTable` §3.6.1, 05 §4.5.1 l. 2280-2287 : « les tâches accomplies/reportées/abandonnées/bloquées, 4 colonnes ») ? Si S-07 = le SSoT du jalon non atteint ; si local = le `retro-actions` **recalcule** les écarts (la revue **est** l'action, doc §2.9) | (a) **Lecture** de S-07 (le jalon = un `Goal` AD-15, le module Objectifs détient la donnée, 05 §4.3) (b) **Calcul local** (le `retro-actions` = la revue **structure** l'écart, 05 §4.5.1 l. 2237-2247 : « le DS **structure** la revue ») | Feature owner (`productivity.reviews`) | 05 §4.5.1 l. 2280-2287 (le `DataTable` bilan = 4 colonnes, le S-07 = le jalon) — le SSoT ne dit **pas** si le jalon vient de S-07 ou du calcul local |
| **OQ-6** | CTA fixe (id. 13) — le texte exact | WDS 06.3 §3 (Contrainte UX) : « le CTA fixe **AD-14** : 'Planifier la semaine' (→ calendrier S-05, pose des 2 blocs BAC sur la semaine suivante) ». 05 §4.5.1 l. 2388-2397 dit « une `RoutineStep` du plan d'action → **si l'étape devient** une tâche, un `Button ghost` « En faire une tâche » ». Le CTA = **primary** « Planifier la semaine » (WDS 06.3) **ou** `Button ghost` « En faire une tâche » (05 §4.5.1) ? | (a) `Button primary` « Planifier la semaine » (WDS 06.3 §3, AD-14 : le **seul** CTA, l'action = le calendrier) (b) `Button ghost` « En faire une tâche » (05 §4.5.1 l. 2388-2397 : le plan d'action **génère** des tâches) | Product / 05 §4.5.1 owner | WDS 06.3 §3 (CTA = « Planifier la semaine », primary) vs 05 §4.5.1 l. 2388-2397 (CTA = « En faire une tâche », ghost) — **les 2 SSoT divergent sur le verbe** |
| **OQ-7** | `EmptyState` (id. 4a, `empty`) — le CTA dans l'état vide | WDS 06.3 §7 État vide : « Semaine parfaite — pas de correctif nécessaire » + CTA « Planifier la semaine » (reste le chemin, invariant AD-14). 05 §4.5.1 l. 2336-2347 dit le `empty` = « Pas de revue cette semaine » + CTA « Faire la revue » (ouvre la `BottomSheet` de **création**, l. 2338-2347). Le CTA dans l'état **vide** = « Planifier la semaine » (WDS 06.3, le CTA **reste** le chemin) **ou** « Faire la revue » (05 §4.5.1, la revue **n'existe pas** encore) ? | (a) CTA « Planifier la semaine » (WDS 06.3 : le CTA **reste** le chemin, AD-14) (b) CTA « Faire la revue » (05 §4.5.1 l. 2338-2347 : la revue **n'existe pas**, la CTA = la **création**) | Design System / Product owner | WDS 06.3 §7 (CTA = « Planifier la semaine ») vs 05 §4.5.1 l. 2338-2347 (CTA = « Faire la revue ») — **les 2 SSoT divergent sur le CTA de l'état vide** |

| **OQ-8** | §12 offline — périmètre du mirror local | Le §12 (killed) suppose que le CTA « Planifier la semaine » (id. 13) **pose les 2 blocs BAC sur S-05 hors-ligne** (écriture locale, AD-7) — mais **quand** le CTA **s'exécute-t-il** : (a) **instantanément** (écriture locale immédiate, `LocalCommandRepository`, AD-7) **ou** (b) en **attente du réseau** pour valider les 2 événements S-05 (si S-05 = `productivity.calendar` online pour **créer** les événements, master-feature-catalog l. 21 : `calendar.schedule` = CONFIRMATION_REQUIRED mais le CTA n'a **pas** de confirmation ici, §6/§12) ? Le SSoT ne tranche **pas** si la pose locale des 2 blocs BAC **persiste** (killed = écriture **effective**) ou **échoue silencieusement** (killed = CTA **inactive** tant que le kernel n'est pas disponible) — le §12 suppose la (a) mais le SSoT ne le **garantit** pas (ni `SyncStatus` ni la kill matrix ne spécifient le comportement du CTA dans l'état killed). | (a) CTA = écriture **effective** offline (AD-7 local-first : `LocalCommandRepository` + upsync, le planning S-05 est **persisté** localement) (b) CTA = **inactive** en killed (le CTA **attent** le kernel/la re-sync, OQ-3 `Modal` de confirmation qui **meurt** avec le flux serveur) | Feature owner (`productivity.reviews`) + 05 §4.5.1 owner | SSoT manquante : kill matrix (AD-13, kernel S12) ne **spécifie** pas le comportement du CTA d'écriture locale dans l'état `killed` (ni « écriture effective » ni « inactive ») ; ni le `SyncStatus` (AD-7) ni le pack 03 §5.5 ne **tranchent** si la pose des 2 blocs BAC **persiste** ou **échoue** hors-ligne |

> **Note OQ** : les 8 OQ ci-dessus sont **locales** au slug `retro-actions` ; le
> OQ-4 (variante vs slug distinct) **ouvre/ferme** ce doc (variante = section du
> `revues-semaine.md` ; distinct = ce doc). Les OQ 2/5 (le SSoT ne tranche pas entre
> lecture S-07 et calcul local) sont **bloquantes** pour l'implémentation. Le OQ-6
> (le verbe du CTA : « Planifier » vs « En faire une tâche ») est **bloquant** pour
> la copy. Le OQ-3 (Modal de confirmation ou non) est **bloquant** pour le flux.
> Les OQ 1/7 sont **non bloquantes** (les 2 options sont valables dans le SSoT).

## Références SSoT (comptage officiel)

- **WDS 06.3** : `_bmad-output/wds/C-UX-Scenarios/06-horebs-retrospective/06.3-retro-actions/06.3-retro-actions.md` (slug `retro-actions`, route `/progress`, S-13 état post-retrospective ; Option A close OQ-1, OQ-2 close ; budget OQ-11 : 30 fps, TTI < 1.5 s, JS < 300 Ko gz ; thème Nocturne OQ-16 ; AD-14 : le CTA « Planifier la semaine » = le **seul** CTA d'action).
- **Routes primaires** : `/progress` (WDS 06.3 route) = l'enveloppe `analytics` §4.5.2 (05 l. 2410-2476 : « §4.5.2 **est** le dashboard Progress, doc §18.6 : ce n'est pas un écran séparé — c'est lui ») — le `retro-actions` = **l'état post-retrospective** de cette route (WDS 06.3 §1, l. 18 : « **re-utilisation** de S-13 en état post-retrospective »).
- **Classes offline** : `docs/features/master-feature-catalog.md` l. 26 (`productivity.reviews` = **offline-capable** ; agent `review.run` = CONFIRMATION_REQUIRED).
- **6 états S6 + sémantiques §6.1** : `docs/ui-libraries.md` §6 l. 174-187 ; §6.1 l. 189-202 (ici : `en-cours` = N/A, `terminé` = `Card` + `Callout info` (§4b), `échec` = N/A, `succès` = `Toast` (§4b), `erreur` = `Badge danger` « à resync » (§4a), 404 = logo coloré centre (§4b / §13)).
- **Logos S9** : `docs/ui-libraries.md` §9 l. 349-369 ; §9.1 l. 371-405 (matrice l. 378-388, interdits l. 390-392, précision l. 394-405) ; §9.2 l. 407-418.
- **Motion** : `05-design-system.md` §2.6 l. 310-346 ; `ui-libraries.md` S5 l. 169 (GPU only, `prefers-reduced-motion` = statique) ; S3 l. 143 (pas bouncy, 150-250 ms).
- **Pagination** : `ui-libraries.md` S1 l. 37 (`Pagination` = shadcn) ; S8 l. 304-307 (volume : < 20 rows → Table) ; **ici** = `Pager` §3.4 (l. 737-750), pas `Pagination` (le volume est **borné** par la période, cf. §8).
- **Thèmes** : `05-design-system.md` §5 l. 2925-3306 (5.1 l. 2931, 5.2 l. 2961, 5.4 l. 3010-3047, 5.5 l. 3153, 5.7 l. 3183-3227) ; **ici** : Nocturne = preset (couche 3, OQ-16 WDS 06.3 §5) ; les `Badge` / `GanttRow` = dérivés de `accent.*` (couche 2) ; les `Callout` / `Badge danger` = **figés** (05 §5.1 l. 2931).
- **Tokens** : `05-design-system.md` §2 l. 93-346 (2.1.2 l. 124-159, 2.2 l. 190, 2.3 l. 232, 2.4 l. 254) ; `docs/design-system/overview.md` §2 l. 15-25 (discipline tokens, AD-17) ; `ui-libraries.md` S4 l. 145-160 (tokens via CSS variables, `var(--aurora-*)`).
