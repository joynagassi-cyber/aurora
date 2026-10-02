# calendrier-jour — Calendrier (vue jour)

Status: SPÉCIFIABLE (OQ: 8) · Module : Productivité · Route : `/calendar` · SSoT : 05 §4.4.1 l. 1896-2043 + 05 §3.4 `Pager` l. 737-750 + 05 §3.6.12 `RoutineStep` l. 1232-1243 + 05 §3.7 l. 1244-1309 + ui-libraries S1/S3 + master-feature-catalog §2 l. 21 (`productivity.calendar`, offline-capable)

> Le `calendrier-jour` = la projection **jour** du `Pager` §3.4 (Jour | Semaine | Mois)
> du slug `calendrier` (enveloppe #51, 05 §4.4.1 : « les 3 écrans partagent **le même**
> composant, pas 3 vues séparées »). Ce doc spécifie uniquement la zone de contenu de la
> **liste `RoutineStep`-like des événements de la journée** ; les zones partagées (TopBar +
> Pager, BottomNav, 404, offline global) sont référencées vers `calendrier.md` (enveloppe)
> et ne sont pas dupliquées.

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | **Voir et planifier** les événements/tâches d'**une journée** (time-blocking granulaire heure par heure, doc §2.4 « Calendrier jour/semaine/mois ») | 05 §4.4.1 l. 1898-1900 |
| Contexte | Device mobile (Phase 1) ; moment = le matin (planifier la journée) ou l'après-midi (contrôler la suite) ; réseau = indifférent (lecture locale AD-7) | 05 §4.4.1 l. 1978-1984 ; master-feature-catalog l. 21 |
| Fréquence | **Très haute** : le mode jour est le mode le plus **détaillé** du `Pager` (le drill-down depuis semaine/mois **aboutit ici**, l. 1987-1995) — c'est l'écran de **temps réel** du planning | 05 §4.4.1 l. 1987-1995 ; 05 §3.4 l. 737-750 |
| État émotionnel cible | **Maîtrise horaire** : 24h (mobile) ou 48h en une liste lisible d'un coup d'œil ; chaque heure = une `RoutineStep`-like ; le conflit est **visible immédiatement** (pas caché au scroll, l. 1951-1954) | 05 §4.4.1 l. 1919-1931, l. 1951-1954 ; 05 §1 l. 69-80 |
| Erreur la plus probable | L'utilisateur **surcharge** une journée (ex. 8h de cours + 3h d'examens + 2h de réunion) sans s'en rendre compte : le `Callout warning` de surcharge doit être visible **en tête de liste**, pas à 14h | 05 §4.4.1 l. 1955-1962 ; 05 §3.3 l. 628-641 |
| Ce que l'écran RÉSOUT | « Ouvre-moi aujourd'hui » = 24h projetées en liste ; **drill-down** depuis semaine/mois = le switch du `Pager` (pas un push, l. 1987-1995) ; **replanifier** = demander au kernel (l'app ne calcule pas elle-même, l. 2016-2021) | 05 §4.4.1 l. 1919-1931, l. 1987-1995, l. 2010-2021 |

## 2. Zones

- **content** (la seule zone propre à ce slug) : liste `RoutineStep`-like des événements
  de la journée — **heure en `JetBrains Mono` `xs`** (l. 1919-1921), un `Badge` par type
  (cours / examen / réunion / devoir / révision / projet / routine — 7 types = 7 `Badge`,
  les couleurs suivent le **type**, pas le **statut** ; le statut = `Badge` de la tâche
  **uniquement si** l'événement **est** une tâche, l. 1916-1924) ; `Callout warning` de
  conflit **posé** au-dessus du jour concerné (l. 1951-1954) ; `Callout warning` de
  surcharge (temps planifié vs temps disponible, l. 1955-1962).
- **header / footer / surfaces flottantes** : partagés avec l'enveloppe `calendrier`
  (`calendrier.md` §2/§6 — TopBar + `Pager` §3.4, BottomNav, BottomSheet de création/détail,
  Popover date picker FullCalendar). **Non dupliqués ici** (rège 1 écran = 1 doc, §3 du prompt).
- **Breadcrumb** : **n'existe pas** ici — le calendrier est une **feuille** du module
  Productivité, pas une hiérarchie AD-6 (05 §4.4.1 l. 1996-2001).

## 3. Éléments / widgets

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| 1 | Liste `RoutineStep`-like (les événements de la journée) | `RoutineStep` §3.6.12 (05 l. 1232-1243 : une étape = `ListItem` + numérotation `JetBrains Mono` + `Checkbox`) ; ici **adapté** = une **heure** = une `RoutineStep`-like (l. 1919-1921) | OQ-27 (liste `packages/ui` — **pas** de `list` shadcn en S1 ui-libraries S1 ; `card` = S1 l. 12) ; FullCalendar v6 `timeGridDay` (ui-libraries S1 l. 22) | `surface`, `space.3`, `border` | desktop = **24h** (le mobile compacte 48h, §2.3, l. 2024-2038) | 05 §4.4.1 l. 1919-1931 ; 05 §3.6.12 l. 1232-1243 |
| 2 | Ligne d'heure (ex. « 08:00 ») | `RoutineStep`-like (la numérotation = l'heure, pas le 1./2./3. de la routine, l. 1921 « heure en `JetBrains Mono` `xs` ») | id. 1 | `JetBrains Mono` `xs` (l. 1921), `text-secondary` | 24h desktop | 05 §4.4.1 l. 1919-1921 ; 05 §2.2 l. 190 |
| 3 | `Badge` par type d'événement (7 types : cours / examen / réunion / devoir / révision / projet / routine) | `Badge` (05 §3.3 l. 531-544) | shadcn `badge` (ui-libraries S1 l. 31) | 7 types → 7 couleurs de **type** (l. 1916-1922 : « les couleurs suivent le **type**, pas le statut ») ; `radius.sm`, `space.2` | n/a | 05 §4.4.1 l. 1916-1924 ; 05 §3.3 l. 531-544 |
| 4 | `Badge` de **statut** de la tâche (si l'événement **est** une tâche) | `Badge` (id. 3, **variante statut**) | id. | `success`/`warning`/`danger` (selon le statut), `radius.sm` | n/a | 05 §4.4.1 l. 1922-1924 (« le statut = `Badge` de la tâche si l'événement **est** une tâche ») ; 05 §2.1.2 l. 124-159 |
| 5 | `ProgressBar` minuscule (durée pluri-jours, ex. examen du lundi au mercredi) | `ProgressBar` (05 §3.3 l. 620-626) | shadcn `progress` (ui-libraries S1 l. 33) | `primary`, `radius.sm` | n/a | 05 §4.4.1 l. 1931-1933 |
| 6 | `Callout warning` conflit de planning (deux événements qui **se chevauchent**) | `Callout` (05 §3.3 l. 628-641) | shadcn `alert` variant=warning (ui-libraries S1 l. 30) | `warning-surface`, `warning`, `radius.md`, `space.3` | n/a | 05 §4.4.1 l. 1949-1958 ; 05 §3.3 l. 628-641 |
| 7 | `Callout warning` surcharge temporelle (temps réellement planifié vs temps disponible) | `Callout` (id. 6) | id. | id. | n/a | 05 §4.4.1 l. 1955-1962 ; 05 §3.3 l. 628-641 |
| 8 | `Button ghost` « Replanifier » (dans le `Callout` de conflit/surcharge) | `Button` (05 §3.1 l. 378-390) | shadcn `button` variant=ghost (ui-libraries S1 l. 11) | `text-secondary`, 44px | n/a | 05 §4.4.1 l. 2010-2021 |
| 9 | `Badge danger` « à resync » (événement non syncé) | `Badge` (id. 3) | shadcn `badge` variant=destructive | `danger`, `danger-surface`, `radius.sm` | n/a | 05 §4.4.1 l. 1974-1979 ; 05 §3.7 l. 1276 |
| 10 | `Badge primary` « nouveau » (syncé depuis le cloud, pack 03 §5.5) | `Badge` (id. 3) | id. | `primary`, `primary-surface` | n/a | 05 §3.4 l. 746-750 (le « nouveau » = indigo, pas rouge) |
| 11 | `ListItem` détaillé (si un événement est **détailé** dans le mode jour, l. 1941-1943) | `ListItem` (05 §3.3, via `RoutineStep` §3.6.12) | OQ-27 (pas ion-item, S3 l. 137 ; `card` shadcn S1 l. 12) | `surface`, `space.2`, `border` | n/a | 05 §4.4.1 l. 1941-1943, l. 2001-2009 |

**Règle interdits** : `ion-calendar` (S3 l. 135, « ion-calendar = vieux », → FullCalendar
v6) ; `ion-list` pour la liste (S3 l. 136, → shadcn) ; `ion-item` pour les événements
(S3 l. 137, → shadcn/Radix). Les 7 types d'événements portent **leurs couleurs de type**
(pas de statut) — le statut = `Badge` de la tâche **uniquement si** l'événement **est**
une tâche (05 §4.4.1 l. 1916-1924).

## 4. États (6 S6 + sémantiques §6.1) — par élément async

### 4a. Matrice S6 (ui-libraries §6 l. 174-187)

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| 1-2. Liste `RoutineStep`-like + lignes d'heures | `Skeleton` des `RoutineStep` (05 §4.4.1 l. 1963-1965 : « le store local, court, pack 02 §7 ») ; transition d'entrée : `opacity 0→1` 200ms (polish.tsx l. 23-28) | Un jour **vide** = un `Callout info` « Aucun événement — **ajoutez-en un** » (l. 1966-1974 : pas un vide **mort** — le CTA ouvre une `BottomSheet` de création avec un `DateField` pré-rempli au jour courant, §3.2) ; **texte exact = OQ-27** (pas de SSoT de copy : §6 l. 182 donne le CTA générique « Demande a Aurora », 05 l. 1966-1974 n'en re-formule pas l'intitulé) | Un événement non syncé = `Badge danger` « à resync » (id. 9) — **l'événement reste dans la liste** (AD-7, l. 1974-1979) | `Toast` (3s auto-dismiss, « Synchronisé ») après une création/mutation syncée | Le calendrier **fonctionne** (lecture locale AD-7, l. 1978-1984) ; `Badge` « Offline » (ui-libraries §6 l. 184) ; la création reste possible (écriture locale, pack 03) ; seul le **scan de documents** liés à un événement est désactivé (l. 1983-1984) | `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) ; les données du mirror local s'affichent (jamais d'écran blanc, AD-7) |
| 3-4. `Badge` de type / de statut | n/a (composant, matrice §3.7 l. 1276) | n/a | id. 9 (`Badge danger` « à resync ») | n/a | identique (locale) | n/a (composant) |
| 5. `ProgressBar` pluri-jours | n/a (composant, l. 1259) | n/a (0% visible si pas de durée) | figé + `Callout` (l. 1259) | n/a | identique (locale) | n/a |
| 6-7. `Callout warning` (conflit / surcharge) | n/a (l. 1286 « c'est l'état ») | n/a (pas de conflit/surcharge = pas de `Callout` — **l'absence est l'état vide**) | n/a (le `Callout` **est** le rendu de l'erreur de planning) | n/a | `bannière` (l. 1286) ; le `Callout` local reste affiché (le calcul de conflit est local, AD-7) | n/a |
| 8. `Button ghost` « Replanifier » | n/a (l. 1254) | n/a | n/a | n/a | **désactivé** (l. 1254 « désactivé si cloud ») + `Callout info` « Hors-ligne — cette action nécessite le réseau » (05 §3.5 l. 777-779 : la replanification est une capacité du **kernel** serveur, AD-12/F-09, l. 2016-2021) | n/a |
| 9-10. `Badge danger` « à resync » / `Badge primary` « nouveau » | n/a (l. 1276) | n/a | le `Badge` **est** l'état d'erreur (id. 9) | le `Badge` disparaît après resync (id. 10) | « nouveau » = `Badge primary` indigo (05 §3.4 l. 748-750 : « le nouveau = indigo, pas rouge — le danger est réservé à l'échec, §2.1.2 ») | n/a |
| 11. `ListItem` détaillé | n/a (composant, l. 1276) | n/a | id. 9 | n/a | identique (locale) | n/a |

**Règle de test** (pack 02 §11, 05 §3.7 l. 1303-1306) : composant « écran » = test par
écran qui compose l'état ; composant « composant » = test de rendu par état.

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202)

| État | Rendu | Source SSoT |
|---|---|---|
| `en-cours` | N/A — l'écran n'exécute pas d'opération avec résultats partiels (pas de streaming, pas de QCM) ; la **plurijours** d'un événement = `ProgressBar` minuscule (id. 5), qui **n'est pas** un état, c'est une donnée de durée | 05 §4.4.1 l. 1931-1933 |
| `terminé` | N/A — le statut « terminé » d'un événement = le `Badge` de la tâche (si l'événement **est** une tâche, l. 1922-1924) ; ce n'est pas un état d'écran, c'est une donnée de l'élément | 05 §4.4.1 l. 1916-1924 |
| `échec` | `Callout warning` de conflit/surcharge (id. 6-7) + `Button ghost` « Replanifier » (id. 8) — le **conflit** est le « échec » planning, visible et actionnable (l. 1951-1958) ; le « Replanifier » ouvre `agent` §4.9.1 (l. 2010-2021) | 05 §4.4.1 l. 1949-1958, l. 2010-2021 |
| `succès` | `Toast` (S6 `success`, 3s auto-dismiss) après une création/synchro | ui-libraries §6 l. 183 |
| `erreur` | `Badge danger` « à resync » (id. 9) — transitoire, retry in-place (auto-resync) ; ≠ `échec` qui est le conflit structurel | 05 §4.4.1 l. 1974-1979 ; ui-libraries §6.1 l. 201 |
| `404 / not-found` | Page entière (partagée avec `calendrier.md`) : logo AURORA **coloré sans fond** au **centre** (05 §9.1 / ui-libraries §6.1 l. 202), message court, CTA primaire « Retour à l'accueil » ; ce slug est routé (`/calendar`) donc l'état 404 s'applique à l'enveloppe | ui-libraries §6.1 l. 202 ; 05 §3.4 l. 737-750 |

### 4c. `killed` (tout flux serveur)

Le seul flux serveur de ce slug = la **replanification** (id. 8) qui passe par le kernel
(AD-12, l. 2016-2021). `killed` = `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7
l. 1290-1296 ; ui-libraries §6 l. 185). La liste locale **reste visible** (AD-7, l. 1978).

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| `RoutineStep`-like (id. 1-2) | tap → la ligne s'expand en `ListItem` détaillé (id. 11) **ou** ouvre le détail (événement pur = `BottomSheet`, tâche = push `taches-detail` §4.3.1, l. 2001-2009) | 150-200ms (`anim.fast`/`normal`, 05 §2.6 l. 310-320) | `transform: translateY` (expand in-place, polish.tsx l. 41-54) | `static` (05 §2.6 l. 330-334, règle 2) | 05 §4.4.1 l. 2001-2009 ; 05 §2.6 l. 316-318 |
| `Badge` de type (id. 3) | tap → filtre la liste par ce type (le `Pager` reste en mode jour, c'est un **filter local**, pas une navigation) | 200ms `ease-out` | `opacity` (les autres badges s'estompent à 30%) | `static` | 05 §4.4.1 l. 1916-1924 ; 05 §2.6 l. 317 |
| `Callout warning` (id. 6-7) | tap `Button ghost` « Replanifier » → ouvre `agent` §4.9.1 (la replanification = capacité du kernel, l. 2013-2020) | 200ms `ease-out` | `opacity` (l'écran `agent` ouvre **par-dessus**, polish.tsx) | `static` | 05 §4.4.1 l. 2010-2021 |
| `Button ghost` (id. 8) | press → `scale 0.95` (`anim.fast`), puis navigation | 150ms | `transform: scale(0.95)` | `static` | 05 §3.1 l. 383-385 ; 05 §2.6 l. 316 |
| `ProgressBar` (id. 5) | **AUCUNE** animation de remplissage (05 §2.6 l. 323-330, règle 1 : « les données scientifiques ne s'animent jamais » ; l'événement **est** la donnée) | n/a | n/a | n/a | 05 §2.6 l. 323-330 |
| `Badge` (id. 9-10) | **AUCUNE** animation (le badge est **statique**, 05 §3.4 l. 688-691) | n/a | n/a | n/a | 05 §3.4 l. 688-691 |

**Règles bloquantes** : pas de `layout` animations sur mobile (ui-libraries S5 l. 169) ;
pas de bouncy (ui-libraries S3 l. 143) ; 150-250ms seulement (ui-libraries S3 l. 143) ;
`prefers-reduced-motion` = **tout** `static` (05 §2.6 l. 330-334, règle 2).

## 6. Modals / BottomSheets / Drawers (spécifiques au contenu jour)

| Surface | Déclencheur | Contenu | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|
| `BottomSheet` de **détail** (événement pur, ex. « réunion ») | tap sur un événement qui **n'est pas** une tâche | `ListItem`-like (shadcn, pas ion-item) avec titre, heure, lieu, notes | `back` descend le sheet (ferme à `peek` puis entièrement, 02 §6.3 l. 426-430) ; tap backdrop | 250ms `ease-out` (05 §2.6 l. 317) | 05 §4.4.1 l. 2007-2008 ; 05 §3.5 l. 787-810 |
| Push `taches-detail` §4.3.1 | tap sur un événement qui **est** une tâche | Écran dédié (02 §6.1 détail lourd = route push **par-dessus** le tab courant) | `back` natif (02 §6.3 l. 426-428) | 200ms `ease-out` (polish.tsx l. 23-28) | 05 §4.4.1 l. 2001-2005 ; 02 §6.1 |
| `BottomSheet` de **création** (CTA `empty`, id. 11) | tap sur le CTA du `Callout info` « Aucun événement — ajoutez-en un » (l. 1966-1974) | `DateField` pré-rempli au jour courant + `DurationField` (l. 1972-1974) | `back` / tap backdrop | 250ms `ease-out` | 05 §4.4.1 l. 1966-1974 ; 05 §3.5 l. 787 |

Les `Popover` date picker FullCalendar, le `Menu` de tri, et le `Pager` sont dans
`calendrier.md` §6 (enveloppe, non dupliqué ici).

## 7. Formulaires

| Champ | Lib | Validation | Clavier mobile | Persistance | SSoT |
|---|---|---|---|---|---|
| `DateField` (pré-rempli au jour courant dans la `BottomSheet` de création, l. 1972-1974) | shadcn `input` (lecture seule) + `Popover` FullCalendar (ui-libraries S1 l. 23, S3 l. 138 « ion-datetime → FullCalendar + Popover ») | `zod` : date ≥ aujourd'hui si création, ≤ +12 mois | Capacitor `Keyboard` pour l'avoidance (ui-libraries S5 l. 170) | Local-first (AD-7, 02 §6.3) ; la sync est différée | 05 §3.2 l. 480-489 ; 05 §4.4.1 l. 1972-1974 |
| `DurationField` (durée de l'événement, `min`/`h` en `JetBrains Mono`, **jamais** `HH:MM`) | shadcn `input` + suffixe `TextField` (05 §3.2 l. 486-488) | `zod` : min 5 min, max 480 h | id. | id. | 05 §3.2 l. 486-488 |

**Interdiction** : un `TextField` qui cache le label quand vide (05 §3.2 l. 434-436) ;
`ion-item` pour le formulaire (S3 l. 137, → shadcn/Radix).

## 8. Pagination

**Règle unique nommée** : `Pager` jour-semaine-mois (05 §3.4 l. 737-750) — le `Pager`
**est** la pagination temporelle de ce slug (le `SegmentedControl` `Jour | Semaine | Mois`
+ la ligne de navigation avant/après + `Button ghost` « Aujourd'hui »).

- **Pas de shadcn Pagination ni AG Grid** : la liste jour = 24h (mobile) × 1 jour = 24
  `RoutineStep`-like max (borné par l'échelle temporelle, pas par un nombre de lignes
  illimité) ; le volume est **trop petit** pour déclencher la décision tree ui-libraries
  S8 l. 304-307 (<20 rows → `Table` sans pagination ; ici 24 lignes → pas de pagination
  nécessaire, le scroll est suffisant).
- **Params** : le `Pager` est **persisté** par l'écran (store UI pack 02 §3.2, l. 743-745) ;
  le retour retrouve le même mode (jour) et la même position temporelle (règle de
  non-surprise, l. 745).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** depuis `calendrier-semaine`/`calendrier-mois` (drill-down) | tap sur une `CalendarCell` → le `Pager` passe en mode **jour** pour ce jour (l. 1987-1995) ; le contenu slide horizontalement (150-200ms `ease-out`) ; le Breadcrumb **n'existe pas** (feuille, l. 1996-2001) | 05 §4.4.1 l. 1987-1995, l. 1996-2001 ; 05 §2.6 l. 310-320 |
| **Drill-down** depuis ce slug vers `calendrier-semaine` | tap sur le `SegmentedControl` « Semaine » = **switch de mode** (pas un push, l. 1987-1995) ; la position temporelle est **persistée** (le retour retrouve la même semaine, l. 743-745) | 05 §4.4.1 l. 1987-1995 ; 05 §3.4 l. 743-745 |
| **Événement → détail** | événement pur = `BottomSheet` par-dessus (l. 2007-2008) ; tâche = push `taches-detail` §4.3.1 (l. 2001-2005) ; **jamais** par changement de tab (02 §6.1) | 05 §4.4.1 l. 2001-2009 ; 02 §6.1 |
| **Replanifier** | `Button ghost` → ouvre `agent` §4.9.1 (l. 2010-2021) ; le kernel calcule, l'app **demande** (AD-12/F-09, l. 2016-2020) | 05 §4.4.1 l. 2010-2021 |
| **404** (deep link invalide, ex. `?day=99999`) | → `not-found` (enveloppe, `calendrier.md` §4b) : logo AURORA coloré au centre, CTA « Retour à l'accueil » | ui-libraries §6.1 l. 202 |

## 10. Thèmes

Comportement par couche (05 §5 l. 2925-3306 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#FFFFFF` / Dark `#121212`) : fournit `surface`,
  `text-primary/secondary`, `border` — les tokens géométriques de la liste (lignes d'heures
  = `border`, cases = `surface`). Les 10 thèmes vivants **ne redéfinissent jamais** les
  sémantiques (05 §5.1 l. 2931, règle bloquante).
- **Couche 2 — Expressive** (4 accents + chartPalette, 05 §5.4 l. 3010-3047) : les 7
  couleurs de **type** d'événement (cours/examen/réunion/devoir/révision/projet/routine,
  l. 1916-1922) sont **dérivées** de `accent.primary/secondary/punctual` + `chartPalette`
  — **jamais de valeur brute par thème** (AD-17, l. 2961). Le `Badge` de type suit donc
  le thème courant (ex. `aurora` = cours en `accent.primary`, `lagoon` = cours en la
  teinte `lagoon.primary`).
- **Couche 3 — Presets** (`slate` / `nocturne` / `high-contrast`, 05 §5.5 l. 3153) :
  le `Badge` de type reste lisible ; en `high-contrast` = tap targets 56px
  (05 §6.3, a11y) ; les `Callout warning` (conflit/surcharge) = **figés** (pas redéfinis
  par le thème, 05 §5.1 l. 2931).
- **Test 10×5** (05 §5.7 l. 3183-3227) : la liste jour doit passer les 5 styles ×
  10 thèmes (le `chartPalette` = 5 séries, l. 3032).

## 11. A11y (WCAG AA, 05 §6.3)

- Tap targets **≥ 44px** (56px en `high-contrast`, 05 §6.3) : chaque `RoutineStep`-like
  (ligne d'heure + badge) et chaque `Badge` d'événement = **44×44px minimum** ; la liste
  jour est **bornée** (24 lignes max) donc le tap n'est **pas** ambigu (05 §3.4 l. 676 :
  « le pouce mobile couvre la zone centrale »).
- `aria-label` sur **tous** les icon buttons (le `Button ghost` « Replanifier » = icône
  + texte visible, pas un icon-only ; si icon-only = `aria-label` obligatoire, 05 §3.1
  l. 388-396, test CI §7).
- `letter-spacing 0` (05 §6.3) ; `focus-visible` ring = `focus-ring` (token, 05 §2.4
  l. 254-264, l. 1254 « focus (ring 2px `focus-ring`) ») ; les `Callout warning`
  (conflit/surcharge) portent `role="alert"` (WCAG 4.1.3).
- Les 7 couleurs de **type** (l. 1916-1922) = **jamais la seule information** : chaque
  `Badge` porte **texte** (le type) + couleur (05 §6.3, non-color-only) ; le `Badge
  danger` « à resync » (id. 9) = texte + couleur, pas couleur seule.

## 12. Offline

- **Classe offline** (master-feature-catalog §2 l. 21) : `productivity.calendar` =
  **offline-capable** (agenda / time blocking / détection conflits+surcharge ; agent
  `calendar.schedule` = CONFIRMATION_REQUIRED ; `POST_NOTIFICATIONS` au 1ʳᵉ usage,
  jamais au boot — `apps/mobile/src/pages/calendar/index.tsx` l. 9).
- **Miroir local** (AD-7 / AD-12) : le calendrier **fonctionne** offline — lecture
  locale du store local (PowerSync/SQLite, pack 02 §7) ; la création reste **possible**
  (écriture locale, pack 03) ; le seul qui meurt = le **scan de documents** liés à un
  événement (l. 1983-1984, « seul le scan de documents liés à un événement est désactivé »)
  → `killed` = cette feature (le scan, pas le calendrier).
- **Dégradation AD-1** : si le kernel est down (la replanification, id. 8) = `Button
  ghost` **désactivé** + `Callout info` « Hors-ligne — cette action nécessite le réseau »
  (05 §3.5 l. 777-779) ; la liste locale **reste visible** (AD-7, l. 1978-1984).
- **Au retour du réseau** : les événements **nouveaux** syncés depuis le cloud
  apparaissent avec leur `Badge` « nouveau » `primary` (indigo, pas rouge, l. 748-750) —
  pack 03 §5.5 re-sync.

## 13. Occurrences logos (version exacte + raison + SSoT ref)

| Où | Version | Raison (designer psychology) | SSoT |
|---|---|---|---|
| **404 / not-found** (deep link invalide, ex. `?day=99999`, id. 9) | **COLORED sans fond**, au **centre** de la page (ui-libraries §9.1 l. 387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; message court + CTA primaire « Retour à l'accueil » | L'état 404 = **état vivant** (le CTA primaire « Retour à l'accueil » = action active) ; la marque **doit** être colorée pour signifier « l'app répond encore » (ui-libraries §9.1 l. 390-392 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») | ui-libraries §9.1 l. 378-388 (matrice), l. 390-392 (interdits), l. 394-405 (précision bloquantes) ; ui-libraries §6.1 l. 202 ; 05 §3.4 l. 737-750 |
| **Killed / bannière « Reconnexion… »** (id. 4a `killed`, l. 1290-1296) | **MONOCHROME** (grayscale tonal, ui-libraries §9.1 l. 383 « Killed / disabled states (S6) = monochrome ») — le `Badge` « Offline » (id. 9-10) reste **coloré** (il est vivant, pas killed) | La marque **est présente mais silencieuse** : « brand present but not speaking » (ui-libraries §9.1 l. 374-376) ; le `killed` = l'app attend le resync, pas une action | ui-libraries §9.1 l. 378-388, l. 383 ; 05 §3.7 l. 1290-1296 |
| **Nocturne / High Contrast presets** (id. 10, couche 3) | **MONOCHROME** (ui-libraries §9.1 l. 384 « Nocturne + High Contrast presets = monochrome ») ; les 10 thèmes expressifs = **colorés** | « desaturated / high-contrast universes ; the 10 expressive themes = colored version » (l. 384) — le monochrome = neutralité, les 10 expressifs = vivants | ui-libraries §9.1 l. 378-388, l. 384 ; 05 §5.5 l. 3153 |
| **Jamais** | La version **full** (fond arrondi) **n'est PAS** dans ce slug (ni dans l'app, ui-libraries §9 l. 357-358 « NEVER inside the app UI ») ; usage ad hoc **interdit** (ui-libraries §9 l. 352-353) | S9 l. 352-353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else » ; la version full = **exclusivement** l'icône app externe (Capacitor / Play Store / splash) | ui-libraries §9 l. 349-369 ; §9.1 l. 390-392 ; §9.2 l. 407-418 (C2PA stripped) |

**Règle bloquante** : 0 `usage ad hoc` du logo sur ce slug — les 3 occurrences ci-dessus
(exclusives : 404 / killed / presets) = les seules, toutes citées par SSoT (ui-libraries
§9.1 l. 378-388). Le `AgentThinkingLoader` (ui-libraries §9.3) **n'apparaît pas** ici
(ce slug n'a pas de flux de **thinking** du kernel — le « Replanifier » ouvre `agent`
§4.9.1, pas un in-place thinking sur le calendrier).

## 14. Open Questions (OQ)

| # | Écran | Élément | Question | Décideur | Blocage |
|---|---|---|---|---|---|
| OQ-1 | (global, inventaire) | règle de comptage des variantes (liste + détail + vues + pagers) | Le slug `calendrier-jour` = **variante** du `calendrier` (05 §4.4.1 l. 1901-1906 : « le `Pager` §3.4 est le composant partagé, les 3 écrans partagent le **même** composant ») **ou** écran indépendant (inventaire `_inventory.md` l. 97 : `calendrier-jour` = **slug #20** distinct de `calendrier-semaine` l. 98 et `calendrier-mois` l. 99) ? | Design System team (owner 05 §4, pack 02 §4/§6) | Ouvre / ferme ce doc (variante = section du `calendrier.md` ; écran = ce doc) ; `_inventory.md` l. 58 « le delta exact 44→54 est l'OQ n°1 §3 » |
| OQ-20 | `calendrier-jour` | `RoutineStep`-like (id. 1-2) | Le `RoutineStep` §3.6.12 (05 l. 1232-1243) est un **composant dédié** de `packages/ui` (type `RoutineStep.tsx`, SSoT code l. 24-26 de `keyFiles`) **ou** un wrapper `shadcn list` + `FullCalendar` `timeGridDay` ? Si wrapper = `OQ` (S3 l. 135 interdit `ion-calendar` mais **pas** un wrapper `CalendarView` maison) ; si maison = S3 l. 141 « custom SVG decorations » ne s'applique **pas** (ce n'est pas un décor) mais la règle S1 « 1 écran = 1 système de composants » **s'applique** (le FullCalendar + un `RoutineStep` maison = 2 libs, S8 l. 333) | UI owner (`packages/ui`) | Bloquant : `RoutineStep` §3.6.12 (l. 1921, l. 1232) est cité comme **composant DS** (05 §3.6.12) mais le SSoT code `CalendarView.tsx` (l. 24-26 `keyFiles`) est un **wrapper** — la matrice §3.7 (l. 1285) le liste comme composant **à part** (pas comme « FullCalendar ») → l'implémentation attend l'arbitrage wrapper-vs-dédié |
| OQ-21 | `calendrier-jour` | `Badge` de type (id. 3) | Les 7 couleurs de type (l. 1916-1922 : cours / examen / réunion / devoir / révision / projet / routine) sont-elles **dérivées** de `accent.primary/secondary/punctual` (id. 10, couche 2) **ou** des **tokens sémantiques figés** (`success/warning/danger/info`, 05 §2.1.2 l. 124-159) ? Si dérivées = le badge suit le thème (id. 10) ; si figées = 7 tokens neufs (pas dans la matrice §2.1.2) → **OQ** (AD-17, l. 2961 : les couleurs de **type** ≠ couleurs de **statut**, 05 §4.4.1 l. 1922-1924 : « les couleurs suivent le **type**, pas le statut ») | Token owner (`packages/ui/src/styles/aurora.css`) | Non bloquant si dérivées ; bloquant si figées (il faut 7 tokens sémantiques neufs, pas dans la matrice §2.1.2 l. 124-159) |
| OQ-22 | `calendrier-jour` | `Callout warning` conflit (id. 6) | Le **calcul** de conflit (l. 1949-1958 : « le conflit est visible, pas caché ») est-il **local** (le store UI calcule au mount, AD-7) **ou** un `Job` serveur (AD-8, 05 §2.6 l. 310-318 : les traitements lourds = `Job` persisté) ? Si local = le `Callout` est immédiat ; si `Job` = le `Callout` arrive en streaming (en-cours, id. 4b) | Feature owner (`productivity.calendar`, master-feature-catalog l. 21) | Non bloquant : l'écran affiche le `Callout` dans les 2 cas ; le `loading` du calcul (si `Job`) = `Skeleton` du `Callout` (l. 1286) |
| OQ-23 | `calendrier-jour` | `Button ghost` « Replanifier » (id. 8) | La replanification ouvre `agent` §4.9.1 (l. 2010-2021) **avec** quel **profil** d'agent (le `agent` a plusieurs modes, 05 §4.9.1) ? Le kernel reçoit **tout** le planning du jour (id. 1, 24h) **ou** seulement le conflit (id. 6) + l'heure concernée ? | Kernel owner (AD-12, F-09) | Non bloquant pour l'UI (le `Button` est le même dans les 2 cas) ; bloquant pour le **payload** de l'appel au kernel (l. 2013-2020 : « l'app ne **calcule pas** elle-même, elle **demande** au kernel ») |
| OQ-24 | `calendrier-jour` | 24h (mobile) vs 48h (desktop) (id. 1) | La **transition** mobile→desktop (l. 2024-2038) est-elle un **switch** (la liste passe de 24→48 lignes, le contenu **ré-agrége**) **ou** un **zoom** (le contenu est le même, la liste est simplement plus longue) ? 05 §2.3 (l. 1927) dit « le mobile compacte à 48h » mais **ne précise pas** le comportement de switch | Responsive owner (Phase 2, doc §23.4 l. 2041-2042) | Non bloquant Phase 1 (mobile-only, l. 2026) ; bloquant Phase 2 (desktop, l. 2024-2028) |
| OQ-25 | `calendrier-jour` | `Progress bar` d'événement **pluri-jours** (id. 5) | La durée pluri-jours est-elle affichée **en continu** (la `ProgressBar` traverse les jours, ex. un examen du lundi au mercredi) **ou** **par jour** (une pastille par jour, la `ProgressBar` = le % du jour) ? 05 §4.4.1 l. 1931-1933 dit « un `ProgressBar` minuscule si l'événement a une durée pluri-jours » mais ne précise pas si c'est un **seul** barre (continuum) **ou** 3 barres (par jour) | UI owner (`CalendarView.tsx`) | Non bloquant : les 2 rendus sont valides ; le **test** (pack 02 §11, l. 1303-1306) doit couvrir les 2 (le `ProgressBar` = composant §3.7 l. 1259, pas un état propre) |
| OQ-26 | `calendrier-jour` | `BottomSheet` de détail (id. 6, événement pur, l. 2007-2008) | La `BottomSheet` de détail (événement **pur**, ex. « réunion ») est-elle un **nouveau composant** (pas dans la matrice §3.7 l. 1244-1289, qui n'a que `Modal` l. 1266 et `BottomSheet` l. 1267 **génériques**) **ou** une variante de `BottomSheet` §3.5 l. 787-810 **existante** ? Si nouveau = il faut le déclarer dans la matrice §3.7 (AD-13, l. 1303-1306) ; si variante = il est déjà couvert (l. 1267 « `BottomSheet` : loading ✓, empty ✓, error ✓, offline ✓ ») | DS owner (05 §3.7, pack 02 §11) | Non bloquant (la variante existe dans la matrice l. 1267) ; mais si **nouveau** composant = bloquant pour la matrice §3.7 (AD-13 l. 1244-1289) |
| OQ-27 | `calendrier-jour` | Liste / `ListItem` détaillé (§3 id. 1, 2, 11 — lib `shadcn list`/`card`) + texte exact du `Callout info` `empty` (id. 1-2, §4a) | (a) **Lib de liste** : ni `list` ni `card` shadcn en S1 ui-libraries S1 (S1 = table l. 20-21, virtual list l. 63 ; `ion-list` = data tables S3 l. 136) → composant de liste `packages/ui` à arbitrer (wrapper `FullCalendar timeGridDay` ou `ListItem` shadcn, cf. OQ-20) ; (b) **copy `empty`** : « Aucun événement — **ajoutez-en un** » (05 §4.4.1 l. 1966-1974) **ou** la règle §6 l. 182 de `ui-libraries.md` (CTA générique « Demande a Aurora ») ? Le SSoT §6 donne le texte générique pour le CTA `empty`, mais 05 §4.4.1 spécialise le CTA (ouverture `BottomSheet` de création `DateField` pré-rempli, l. 1970-1974) **sans** re-formuler le texte → **pas de SSoT de texte exact** pour cette case (OQ par défaut, matrice §4a) | Feature owner (`productivity.calendar`, master-feature-catalog l. 21) ; UI owner pour (a) | Non bloquant pour le design (le CTA ouvre la `BottomSheet` dans les 2 cas ; (a) = arbitrage lib, cf. OQ-20) ; bloquant pour la **copy** (b) et le choix de lib (a) |

> **Note OQ** : le slug `calendrier-jour` **n'apparaît pas** dans le registre OQ
> global de `_inventory.md` §3 (l. 176-192, qui liste les OQ n°1/13/16/36/39/40/41/42/43/44/46/47/48
> **par écran**) — les 8 OQ ci-dessus (n°20-27 ici, **numérotées 20-27 pour éviter la
> collision** avec le OQ-20/21/22 du registre global `kanban.md` l. 33-41) sont des
> **OQ locales** à ce slug ; le OQ-1 (ci-dessus) **est** le OQ-1 du registre global
> (l. 180, « OQ-1 = la 1ʳᵉ du registre »). Les OQ 20-27 = à **additionner** dans le
> registre global (05 §4, pack 02 §11, DoD écran-par-écran l. 1303-1306).

## Références SSoT (comptage officiel)

- **Comptage officiel 44** : `_bmad-output/architecture/.../05-design-system.md` l. 39
  (« inventaire écran par écran (44 écrans, doc §2-§18 + §13 + §18) ») + l. 1316-1321
  (règle variante « séparément pour chaque paire »). `calendrier-jour` = **slug #20**
  de `_inventory.md` l. 97 (table §2, N = 54 slugs spécifiables, l. 35).
- **Routes primaires** : `docs/mobile/navigation-and-page-composition.md` §1 (02 §6.1) ;
  matérialisées dans `apps/mobile/src/router.tsx` (routes primaires : 17, dont `/calendar`
  l. 219 de `_inventory.md` l. 218-220). `calendrier-jour` = **pas une route distincte**
  (la route = `/calendar`, l. 97 de `_inventory.md` : « `/calendar` (Pager jour) ») — le
  slug est un **état** du `Pager` (store UI pack 02 §3.2), pas une route (05 §3.4 l. 737-750).
- **Classes offline** : `docs/features/master-feature-catalog.md` l. 21 (col. « offline-capable »
  par feature, §2 Productivity l. 14-29) ; `calendrier-jour` = `productivity.calendar`
  (l. 21, **offline-capable**).
- **5 états UX + killed (G-M2)** : `docs/ui-libraries.md` §6 l. 174-187 (loading = `Skeleton`,
  error = `Alert` destructive, empty = `Card`, success = `Toast`, offline = `Badge` +
  last-known data, killed G-M2 = `Skeleton` + auto-resync « Reconnexion… » l. 185) ;
  **6 états** ici = les 5 S6 + `killed` (l. 185) ; la matrice §4a ci-dessus couvre les 6.
- **Logos S9** : `docs/ui-libraries.md` §9 l. 349-369 (4 fichiers SSoT, l. 357-360) ;
  §9.1 l. 371-405 (matrice monochrome l. 378-388, interdits l. 390-392, précision
  bloquantes l. 394-405) ; §9.2 l. 407-418 (C2PA stripped copy).
- **Motion** : `05-design-system.md` §2.6 l. 310-346 ; `ui-libraries.md` S5 l. 169
  (GPU only / no `layout` on mobile, `prefers-reduced-motion` = statique) ; S3 l. 143
  (pas bouncy, 150-250 ms) ; §9.3 l. 420-487 (blobs GPU 2.6/3.4/4.2 s — **pas utilisé**
  ici, cf. §13).
- **Pagination** : `ui-libraries.md` S1 l. 37 (`Pagination` = `npx shadcn@latest add
  pagination`) ; S8 l. 304-307 (volume : < 20 rows → `Table`, 20-100 → + pagination,
  > 100 → AG Grid) ; **ici** = `Pager` §3.4 (l. 737-750), pas `Pagination` (le volume
  est borné par la période, pas par les rows, cf. §8).
- **États S6 / §6.1** : `ui-libraries.md` §6 l. 174-187 ; §6.1 l. 189-202 (en-cours
  l. 197, terminé l. 198, échec l. 199, succès l. 200, erreur l. 201, 404/not-found
  l. 202) ; **ici** : en-cours = N/A, terminé = N/A, échec = `Callout warning` +
  « Replanifier » (§4b), succès = `Toast` (§4b), erreur = `Badge danger` « à resync »
  (§4a), 404 = logo AURORA coloré centre (§4b / §13).
- **Thèmes** : `05-design-system.md` §5 l. 2925-3306 (5.1 l. 2931, 5.2 l. 2961, 5.3
  l. 2992, 5.4 l. 3010-3047, 5.5 l. 3153, 5.6 l. 3167, 5.7 l. 3183-3227, 5.8 l. 3235,
  5.10 l. 3295) ; **ici** : les 7 couleurs de type (§4a id. 3) = **dérivées** de
  `accent.*` (OQ-21) ; les `Callout` figés (OQ-22) ; les presets Nocturne/HC =
  monochrome (§13).
- **Tokens** : `05-design-system.md` §2 l. 93-346 (2.1 l. 99, 2.1.1 l. 106, 2.1.2
  l. 124-159, 2.1.3 l. 159-189, 2.2 l. 190, 2.3 l. 232, 2.4 l. 254, 2.5 l. 287) ;
  `docs/design-system/overview.md` §2 l. 15-25 (discipline tokens blocking rule, AD-17) ;
  `ui-libraries.md` S4 l. 145-160 (intégration tokens via CSS variables, `var(--aurora-*)`).
