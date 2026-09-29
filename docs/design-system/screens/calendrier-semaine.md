# calendrier-semaine — Calendrier (vue semaine)

Status: SPÉCIFIABLE (OQ: 9) · Module : Productivité · Route : `/calendar` · SSoT : 05 §4.4.1 l. 1896-2043 + 05 §3.4 `Pager` l. 737-750 + 05 §3.7 l. 1244-1309 + ui-libraries S1/S3 + master-feature-catalog §2 l. 21 (`productivity.calendar`, offline-capable)

> Le `calendrier-semaine` = la projection **semaine** du `Pager` §3.4 (Jour | Semaine | Mois)
> du slug `calendrier` (enveloppe #51, 05 §4.4.1 : « les 3 écrans partagent **le même**
> composant, pas 3 vues séparées »). Ce doc spécifie uniquement la zone de contenu de la
> **grille 7 colonnes × 48h** ; les zones partagées (TopBar + Pager, BottomNav, 404,
> offline global) sont référencées vers `calendrier.md` (enveloppe) et ne sont pas dupliquées.

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | **Voir et planifier** les événements/tâches de la semaine (time-blocking visuel, doc §2.4) | 05 §4.4.1 l. 1898-1900 |
| Contexte | Device mobile (Phase 1) ; moment = session de planification ou contrôle du week-end ; réseau = indifférent (lecture locale AD-7) | 05 §4.4.1 l. 1978-1984 ; master-feature-catalog l. 21 |
| Fréquence | Haute : le mode semaine est le mode **par défaut** du `Pager` (store UI persisté, 02 §3.2) | 05 §3.4 l. 743-745 ; pack 02 §3.2 |
| État émotionnel cible | **Vue d'ensemble apaisée** : 35 lignes × 7 colonnes lisibles d'un coup d'œil, sans défilement chaotique ; le « temps réellement disponible » est visible (pas de surprise à 22h) | 05 §4.4.1 l. 1955-1962 (« Planification selon le temps réellement disponible ») ; 05 §1 l. 69-80 |
| Erreur la plus probable | L'utilisateur **surcharge** un jour sans s'en rendre compte : le `Callout warning` de surcharge doit être visible **immédiatement**, pas caché au scroll | 05 §4.4.1 l. 1955-1962 ; 05 §3.3 l. 628-641 |
| Ce que l'écran RÉSOUT | « Ouvre-moi la semaine » = 48h projetées sur 7 colonnes ; **drill-down** vers le jour = le switch du `Pager` (pas un push) ; **replanifier** = demander au kernel (l'app ne calcule pas elle-même) | 05 §4.4.1 l. 1925-1932, l. 1987-2022 |

## 2. Zones

- **content** (la seule zone propre à ce slug) : grille 7 colonnes (Lun→Dim) × 48h
  (00:00-23:00, lignes d'heures) ; chaque case = `CalendarCell` §3.6 ; les événements
  sont **empilés** verticalement dans la case ; un `ProgressBar` minuscule si l'événement
  a une durée pluri-jours ; `Callout warning` de conflit **posé** au-dessus du jour
  concerné (05 §4.4.1 l. 1925-1932, l. 1949-1958).
- **header / footer / surfaces flottantes** : partagés avec l'enveloppe `calendrier`
  (`calendrier.md` §2/§6 — TopBar + `Pager` §3.4, BottomNav, BottomSheet de création/détail,
  Popover date picker FullCalendar). **Non dupliqués ici** (rège 1 écran = 1 doc, §3 du prompt).
- **Breadcrumb** : **n'existe pas** ici — le calendrier est une **feuille** du module
  Productivité, pas une hiérarchie AD-6 (05 §4.4.1 l. 1996-2001).

## 3. Éléments / widgets

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| 1 | Grille 7 colonnes (Lun→Dim) | `CalendarCell` §3.6 (05 l. 1928) | FullCalendar `timeGridWeek` (ui-libraries S1 l. 22) | `surface`, `border`, `space.4` (gap colonnes) | desktop = **24h** (le mobile compacte 48h, §2.3) | 05 §4.4.1 l. 1925-1927, l. 2024-2038 |
| 2 | Lignes d'heures (00:00-23:00) | `CalendarCell` §3.6 (grille horaire) | FullCalendar `timeGridWeek` | `JetBrains Mono` `xs` (l. 1926), `border` | 24h desktop | 05 §4.4.1 l. 1925-1927 |
| 3 | `CalendarCell` (case = jour × tranchée) | `CalendarCell` §3.6 (05 §3.7 l. 1276) | FullCalendar + shadcn `card` (wrapper, AD-10) | `surface`, `space.2` | desktop = cellules plus larges | 05 §4.4.1 l. 1928 ; 05 §3.7 l. 1276 |
| 4 | Événements empilés dans la case | `Badge` (type, 05 §3.3 l. 531-544) | shadcn `badge` (ui-libraries S1 l. 31) | 7 types → 7 couleurs type (l. 1916-1922) ; `text-secondary` `xs` | desktop = texte en lieu de pastille si case vide (l. 2031-2036) | 05 §4.4.1 l. 1929-1931, l. 1916-1922 |
| 5 | `ProgressBar` minuscule (durée pluri-jours) | `ProgressBar` (05 §3.3 l. 620-626) | shadcn `progress` (ui-libraries S1 l. 33) | `primary`, `radius.sm` | n/a | 05 §4.4.1 l. 1931-1933 |
| 6 | `Callout warning` conflit de planning | `Callout` (05 §3.3 l. 628-641) | shadcn `alert` variant=warning (ui-libraries S1 l. 30) | `warning-surface`, `warning`, `radius.md`, `space.3` | n/a | 05 §4.4.1 l. 1949-1958 ; 05 §3.3 l. 628-641 |
| 7 | `Callout warning` surcharge temporelle | `Callout` (id. 6) | id. | id. | n/a | 05 §4.4.1 l. 1955-1962 |
| 8 | `Button ghost` « Replanifier » | `Button` (05 §3.1 l. 378-390) | shadcn `button` variant=ghost (ui-libraries S1 l. 11) | `text-secondary`, 44px | n/a | 05 §4.4.1 l. 2010-2021 |
| 9 | `Badge danger` « à resync » (événement non syncé) | `Badge` (05 §3.3 l. 531-544) | shadcn `badge` variant=destructive | `danger`, `danger-surface`, `radius.sm` | n/a | 05 §4.4.1 l. 1974-1979 ; 05 §3.7 l. 1276 |
| 10 | `Badge primary` « nouveau » (syncé depuis le cloud) | `Badge` (id. 4) | id. | `primary`, `primary-surface` | n/a | 05 §4.4.1 l. 748-750 ; 05 §3.4 `Pager` l. 746-750 |

**Règle interdits** : `ion-calendar` (S3 l. 135, « ion-calendar = vieux ») ; `ion-list` pour
la grille (S3 l. 136, → FullCalendar) ; `ion-item` pour les événements (S3 l. 137, → shadcn).
Les 7 types d'événements (cours / examen / réunion / devoir / révision / projet / routine)
portent **leurs couleurs de type** (pas de statut) — le statut = `Badge` de la tâche
**uniquement si** l'événement **est** une tâche (05 §4.4.1 l. 1916-1924).

## 4. États (6 S6 + sémantiques §6.1) — par élément async

### 4a. Matrice S6 (ui-libraries §6 l. 174-187)

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| 1-3. Grille 7 colonnes + lignes + `CalendarCell` | `Skeleton` des cellules (05 §4.4.1 l. 1963-1965 ; le store local, court, pack 02 §7) ; transition d'entrée : `opacity 0→1` 200ms (polish.tsx l. 23-28) | « Semaine vide » (05 §3.7 l. 1276 « jour vide ») ; `Callout info` « Aucun événement cette semaine — ajoutez-en un » (CTA ouvre `BottomSheet` de création, `DateField` pré-rempli au jour courant, 05 §4.4.1 l. 1966-1974) | Un événement non syncé = `Badge danger` « à resync » (l. 9) — **l'événement reste dans la case** (AD-7, l. 1974-1979) | `Toast` (3s auto-dismiss, « Synchronisé ») après une création/mutation syncée | Le calendrier **fonctionne** (lecture locale AD-7, l. 1978-1984) ; `Badge` « Offline » (ui-libraries §6 l. 184) ; la création reste possible (écriture locale, pack 03) | `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) ; les données du mirror local s'affichent (jamais d'écran blanc, AD-7) |
| 4. Événements empilés | n/a (composant, matrice §3.7 l. 1276) | n/a | id. 9 (`Badge danger` « à resync ») | n/a | identique (locale) | n/a (composant) |
| 5. `ProgressBar` pluri-jours | n/a (composant, l. 1259) | n/a (0% visible si pas de durée) | figé + `Callout` (l. 1259) | n/a | identique (locale) | n/a |
| 6-7. `Callout warning` (conflit / surcharge) | n/a (l. 1286 « c'est l'état ») | n/a (pas de conflit = pas de `Callout` — **l'absence est l'état vide**) | n/a (le `Callout` **est** le rendu de l'erreur de planning) | n/a | `bannière` (l. 1286) ; le `Callout` local reste affiché (le calcul de conflit est local) | n/a |
| 8. `Button ghost` « Replanifier » | n/a (l. 1254) | n/a | n/a | n/a | **désactivé** (l. 1254 « désactivé si cloud ») + `Callout info` « Hors-ligne — cette action nécessite le réseau » (05 §3.5 l. 777-779 : la replanification est une capacité du **kernel** serveur, AD-12/F-09, l. 2016-2021) | n/a |
| 9-10. `Badge danger` « à resync » / `Badge primary` « nouveau » | n/a (l. 1276) | n/a | le `Badge` **est** l'état d'erreur (l. 9) | le `Badge` disparaît après resync (l. 10) | « nouveau » = `Badge primary` indigo (05 §3.4 l. 748-750 : « le nouveau = indigo, pas rouge — le danger est réservé à l'échec, §2.1.2 ») | n/a |

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
l. 1290-1296 ; ui-libraries §6 l. 185). La grille locale **reste visible** (AD-7, l. 1978).

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| `CalendarCell` (id. 3) | tap → le `Pager` passe en mode **jour** pour ce jour (drill-down = switch du `Pager`, **pas** un push, l. 1987-1995) | 150-200ms (`anim.fast`/`normal`, 05 §2.6 l. 310-320) | `transform: translateX` (slide du contenu semaine→jour) | `static` (05 §2.6 l. 330-334, règle 2) | 05 §4.4.1 l. 1987-1995 ; 05 §2.6 l. 316-318 |
| Événement (id. 4) | tap → `BottomSheet` de détail (si événement pur) **ou** push `taches-detail` §4.3.1 (si l'événement **est** une tâche, l. 2001-2009) | 250ms `ease-out` (05 §2.6 l. 317, ouverture de `BottomSheet`) | `transform: translateY` (montée du sheet, polish.tsx l. 41-54) | `static` | 05 §4.4.1 l. 2001-2009 ; 05 §3.5 l. 787 |
| `Callout warning` (id. 6-7) | tap `Button ghost` « Replanifier » → ouvre `agent` §4.9.1 (la replanification = capacité du kernel, l. 2013-2020) | 200ms `ease-out` | `opacity` (l'écran `agent` ouvre **par-dessus**, polish.tsx) | `static` | 05 §4.4.1 l. 2010-2021 |
| `Button ghost` (id. 8) | press → `scale 0.95` (`anim.fast`), puis navigation | 150ms | `transform: scale(0.95)` | `static` | 05 §3.1 l. 383-385 ; 05 §2.6 l. 316 |
| `ProgressBar` (id. 5) | **AUCUNE** animation de remplissage (05 §2.6 l. 323-330, règle 1 : « les données scientifiques ne s'animent jamais » ; l'événement **est** la donnée) | n/a | n/a | n/a | 05 §2.6 l. 323-330 |
| `Badge` (id. 9-10) | **AUCUNE** animation (le badge est **statique**, 05 §3.4 l. 691 « le badge est statique, §2.6 règle 1 ») | n/a | n/a | n/a | 05 §3.4 l. 688-691 |

**Règles bloquantes** : pas de `layout` animations sur mobile (ui-libraries S5 l. 169) ;
pas de bouncy (ui-libraries S3 l. 143) ; 150-250ms seulement (ui-libraries S3 l. 143) ;
`prefers-reduced-motion` = **tout** `static` (05 §2.6 l. 330-334, règle 2).

## 6. Modals / BottomSheets / Drawers (spécifiques au contenu semaine)

| Surface | Déclencheur | Contenu | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|
| `BottomSheet` de **détail** (événement pur, ex. « réunion ») | tap sur un événement qui **n'est pas** une tâche | `ListItem`-like (shadcn, pas ion-item) avec titre, heure, lieu, notes | `back` descend le sheet (ferme à `peek` puis entièrement, 02 §6.3 l. 426-430) ; tap backdrop | 250ms `ease-out` (05 §2.6 l. 317) | 05 §4.4.1 l. 2007-2008 ; 05 §3.5 l. 787-810 |
| Push `taches-detail` §4.3.1 | tap sur un événement qui **est** une tâche | Écran dédié (02 §6.1 détail lourd = route push **par-dessus** le tab courant) | `back` natif (02 §6.3 l. 426-428) | 200ms `ease-out` (polish.tsx l. 23-28) | 05 §4.4.1 l. 2001-2005 ; 02 §6.1 |

Les `BottomSheet` de **création** (CTA `empty`), la `Popover` date picker FullCalendar, et
le `Menu` de tri sont dans `calendrier.md` §6 (enveloppe, non dupliqué ici).

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

- **Pas de shadcn Pagination ni AG Grid** : la grille semaine = 35 lignes × 7 colonnes,
  le volume est **borné** par l'échelle temporelle (48h × 7j = 336 cases max), pas par
  un nombre de lignes illimité (ui-libraries S8 l. 304-307 : 20-100 rows → + pagination ;
  ici le « volume » est la **période**, pas les rows).
- **Params** : le `Pager` est **persisté** par l'écran (store UI pack 02 §3.2, l. 743-745) ;
  le retour retrouve le même mode et la même position (règle de non-surprise, l. 745).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** depuis `calendrier-jour` (drill-down remontée) | `Pager` passe de jour à semaine = **switch de mode** (pas un push, l. 1987-1995) ; le contenu slide horizontalement (150-200ms `ease-out`) | 05 §4.4.1 l. 1987-1995 ; 05 §2.6 l. 310-320 |
| **Drill-down** vers `calendrier-jour` | tap sur une `CalendarCell` → le `Pager` passe en mode **jour** pour ce jour ; le Breadcrumb **n'existe pas** (feuille, l. 1996-2001) | 05 §4.4.1 l. 1987-1995, l. 1996-2001 |
| **Événement → détail** | événement pur = `BottomSheet` par-dessus (l. 2007-2008) ; tâche = push `taches-detail` §4.3.1 (l. 2001-2005) ; **jamais** par changement de tab (02 §6.1) | 05 §4.4.1 l. 2001-2009 ; 02 §6.1 |
| **Replanifier** | `Button ghost` → ouvre `agent` §4.9.1 (l. 2010-2021) ; le kernel calcule, l'app **demande** (AD-12/F-09, l. 2016-2020) | 05 §4.4.1 l. 2010-2021 |
| **404** (deep link invalide, ex. `?week=99999`) | → `not-found` (enveloppe, `calendrier.md` §4b) : logo AURORA coloré au centre, CTA « Retour à l'accueil » | ui-libraries §6.1 l. 202 |

## 10. Thèmes

Comportement par couche (05 §5 l. 2925-3306 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#F8FAFC` / Dark `#0A0E1A`) : fournit `surface`,
  `text-primary/secondary`, `border`, `shadow` — les tokens géométriques de la grille
  (lignes d'heures = `border`, cases = `surface`). Les 10 thèmes vivants **ne
  redéfinissent jamais** les sémantiques (05 §5.1 l. 2931, règle bloquante).
- **Couche 2 — Expressive** (4 accents + chartPalette, 05 §5.4 l. 3010-3047) : les 7
  couleurs de **type** d'événement (cours/examen/réunion/devoir/révision/projet/routine,
  l. 1916-1922) sont **dérivées** de `accent.primary/secondary/punctual` + `chartPalette`
  — **jamais de valeur brute par thème** (AD-17, l. 2961). Le `Badge` de type suit donc
  le thème courant (ex. `aurora` = cours en `accent.primary`, `lagoon` = cours en la teinte
  `lagoon.primary`).
- **Couche 3 — Presets** (`slate` / `nocturne` / `high-contrast`, 05 §5.5 l. 3153) :
  le `Badge` de type reste lisible ; en `high-contrast` = tap targets 56px
  (05 §6.3, a11y) ; les `Callout warning` (conflit/surcharge) = **figés** (pas redéfinis
  par le thème, 05 §5.1 l. 2931).
- **Test 10×5** (05 §5.7 l. 3183-3227) : la grille semaine doit passer les 5 styles ×
  10 thèmes (OQ-17 : le `chartPalette` = 5 séries, l. 3032 — SSoT factice : les JSON
  `packages/ui/src/themes/*.json` définissent 3–4 couleurs par palette, la 5ᵉ nulle
  part dans la SSoT ; le test 10×5 lui-même est bien SSoT).

## 11. A11y (WCAG AA, 05 §6.3)

- Tap targets **≥ 44px** (56px en `high-contrast`, 05 §6.3) : chaque `CalendarCell`
  (case = jour × tranchée) et chaque `Badge` d'événement = **44×44px minimum** ; la
  grille semaine est **bornée** (35 lignes × 7 colonnes) donc le tap n'est **pas**
  ambigu (05 §3.4 l. 676 : « le pouce mobile couvre la zone centrale »).
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
  (05 §3.5 l. 777-779) ; la grille locale **reste visible** (AD-7, l. 1978-1984).
- **Au retour du réseau** : les événements **nouveaux** syncés depuis le cloud
  apparaissent avec leur `Badge` « nouveau » `primary` (indigo, pas rouge, l. 748-750) —
  pack 03 §5.5 re-sync.

## 13. Occurrences logos (version exacte + raison + SSoT ref)

| Où | Version | Raison (designer psychology) | SSoT |
|---|---|---|---|
| **404 / not-found** (deep link invalide, ex. `?week=99999`, id. 8) | **COLORED sans fond**, au **centre** de la page (ui-libraries §9.1 l. 387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; message court + CTA primaire « Retour à l'accueil » | L'état 404 = **état vivant** (le CTA primaire « Retour à l'accueil » = action active) ; la marque **doit** être colorée pour signifier « l'app répond encore » (ui-libraries §9.1 l. 390-392 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») | ui-libraries §9.1 l. 378-388 (matrice), l. 390-392 (interdits), l. 394-405 (précision bloquantes) ; ui-libraries §6.1 l. 202 ; 05 §3.4 l. 737-750 |
| **Killed / bannière « Reconnexion… »** (id. 4a `killed`, l. 1290-1296) | **MONOCHROME** (grayscale tonal, ui-libraries §9.1 l. 383 « Killed / disabled states (S6) = monochrome ») — le `Badge` « Offline » (id. 9-10) reste **coloré** (il est vivant, pas killed) | La marque **est présente mais silencieuse** : « brand present but not speaking » (ui-libraries §9.1 l. 374-376) ; le `killed` = l'app attend le resync, pas une action | ui-libraries §9.1 l. 378-388, l. 383 ; 05 §3.7 l. 1290-1296 |
| **Nocturne / High Contrast presets** (id. 10, couche 3) | **MONOCHROME** (ui-libraries §9.1 l. 384 « Nocturne + High Contrast presets = monochrome ») ; les 10 thèmes expressifs = **colorés** | « desaturated / high-contrast universes ; the 10 expressive themes = colored version » (l. 384) — le monochrome = neutralité, les 10 expressifs = vivants | ui-libraries §9.1 l. 378-388, l. 384 ; 05 §5.5 l. 3153 |
| **Header / TopBar** (enveloppe `calendrier.md` §2/§6, partagée) | **COLORED sans fond** — **nulle occurrence** dans ce slug (le `TopBar` partagé n'est pas dupliqué ici, règle 1 écran = 1 doc, §2) ; l'enveloppe `calendrier.md` **doit** déclarer cette occurrence (ui-libraries §9.1 l. 380 « Header / top bar (every screen) = ALWAYS COLORED without-background ») ; si une sous-section §13 est absente de `calendrier.md` = **OQ-18** §14 | La marque est **toujours** colorée dans le header (owner decision 2026-09-27, l. 380) : « brand active » — le calendrier est un écran **vivant** (lecture + planification locale) ; le monochrome serait **interdit** (§9.1 l. 390-392) | ui-libraries §9.1 l. 380 ; 05 §3.4 l. 737-750 (TopBar partagé de l'enveloppe) |
| **Jamais** | La version **full** (fond arrondi) **n'est PAS** dans ce slug (ni dans l'app, ui-libraries §9 l. 357-358 « NEVER inside the app UI ») ; usage ad hoc **interdit** (ui-libraries §9 l. 352-353) | S9 l. 352-353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else » ; la version full = **exclusivement** l'icône app externe (Capacitor / Play Store / splash) | ui-libraries §9 l. 349-369 ; §9.1 l. 390-392 ; §9.2 l. 407-418 (C2PA stripped) |

**Règle bloquante** : 0 `usage ad hoc` du logo sur ce slug — les 5 occurrences ci-dessus
(exclusives : 404 / killed / presets / header partagée (OQ-18) / « jamais la version full »)
= les seules, toutes citées par SSoT (ui-libraries §9.1 l. 378-388 + l. 352-353 pour la
version full). Le `AgentThinkingLoader` (ui-libraries §9.3) **n'apparaît pas** ici
(ce slug n'a pas de flux de **thinking** du kernel — le « Replanifier » ouvre `agent`
§4.9.1, pas un in-place thinking sur le calendrier).

## 14. Open Questions (OQ)

| # | Écran | Élément | Question | Décideur | Blocage |
|---|---|---|---|---|---|
| OQ-1 | (global, inventaire) | règle de comptage des variantes (liste + détail + vues + pagers) | Le slug `calendrier-semaine` = **variante** du `calendrier-jour` (05 §4.4.1 l. 1901-1906 : « le `Pager` §3.4 est le composant partagé, les 3 écrans partagent le **même** composant ») **ou** écran indépendant (inventaire `_inventory.md` l. 98 : `calendrier-semaine` = **slug #21** distinct de `calendrier-jour` l. 97 et `calendrier-mois` l. 99) ? | Design System team (owner 05 §4, pack 02 §4/§6) | Ouvre / ferme ce doc (variante = section du `calendrier-jour.md` ; écran = ce doc) ; `_inventory.md` l. 58 « le delta exact 44→54 est l'OQ n°1 §3 » |
| OQ-10 | `calendrier-semaine` | `CalendarCell` (id. 3) | Le `CalendarCell` §3.6 (05 l. 1276) est un **wrapper FullCalendar** (ui-libraries S1 l. 22 : « Calendar (time blocking, events) = FullCalendar, NOT ion-calendar ») **ou** un composant `packages/ui` dédié (type `CalendarView.tsx`, SSoT code l. 24-26 de `keyFiles`) ? Si wrapper = `OQ` (S3 l. 135 interdit `ion-calendar` mais **pas** un wrapper `CalendarView` maison) ; si maison = S3 l. 141 « custom SVG decorations » ne s'applique **pas** (ce n'est pas un décor) mais la règle S1 « 1 écran = 1 système de composants » **s'applique** (le FullCalendar + un `CalendarCell` maison = 2 libs, S8 l. 333) | UI owner (`packages/ui`) | Bloquant : `CalendarCell` §3.6 (l. 1928, l. 1276) est cité comme **composant DS** (05 §3.6) mais le SSoT code `CalendarView.tsx` (l. 24-26 `keyFiles`) est un **wrapper** — la matrice §3.7 (l. 1276) le liste comme composant **à part** (pas comme « FullCalendar ») → l'implémentation attend l'arbitrage wrapper-vs-Dedicated |
| OQ-11 | `calendrier-semaine` | `Badge` de type (id. 4) | Les 7 couleurs de type (l. 1916-1922 : cours / examen / réunion / devoir / révision / projet / routine) sont-elles **dérivées** de `accent.primary/secondary/punctual` (id. 10, couche 2) **ou** des **tokens sémantiques figés** (`success/warning/danger/info`, 05 §2.1.2 l. 124-159) ? Si dérivées = le badge suit le thème (id. 10) ; si figées = 7 tokens neufs (pas dans la matrice §2.1.2) → **OQ** (AD-17, l. 2961 : les couleurs de **type** ≠ couleurs de **statut**, 05 §4.4.1 l. 1922-1924 : « les couleurs suivent le **type**, pas le statut ») | Token owner (`packages/ui/src/styles/aurora.css`) | Non bloquant si dérivées ; bloquant si figées (il faut 7 tokens sémantiques neufs, pas dans la matrice §2.1.2 l. 124-159) |
| OQ-12 | `calendrier-semaine` | `Callout warning` conflit (id. 6) | Le **calcul** de conflit (l. 1949-1958 : « le conflit est visible, pas caché ») est-il **local** (le store UI calcule au mount, AD-7) **ou** un `Job` serveur (AD-8, 05 §2.6 l. 310-318 : les traitements lourds = `Job` persisté) ? Si local = le `Callout` est immédiat ; si `Job` = le `Callout` arrive en streaming (en-cours, id. 4b) | Feature owner (`productivity.calendar`, master-feature-catalog l. 21) | Non bloquant : l'écran affiche le `Callout` dans les 2 cas ; le `loading` du calcul (si `Job`) = `Skeleton` du `Callout` (l. 1286) |
| OQ-13 | `calendrier-semaine` | `Button ghost` « Replanifier » (id. 8) | La replanification ouvre `agent` §4.9.1 (l. 2010-2021) **avec** quel **profil** d'agent (le `agent` a plusieurs modes, 05 §4.9.1) ? Le kernel reçoit **tout** le planning de la semaine (id. 1, 48h × 7j) **ou** seulement le conflit (id. 6) + le jour concerné ? | Kernel owner (AD-12, F-09) | Non bloquant pour l'UI (le `Button` est le même dans les 2 cas) ; bloquant pour le **payload** de l'appel au kernel (l. 2013-2020 : « l'app ne **calcule pas** elle-même, elle **demande** au kernel ») |
| OQ-14 | `calendrier-semaine` | 48h (mobile) vs 24h (desktop) (id. 1) | La **transition** mobile→desktop (l. 2024-2038) est-elle un **switch** (la grille passe de 48→24 lignes, le contenu **ré-agrége**) **ou** un **zoom** (le contenu est le même, la grille est simplement plus haute) ? 05 §2.3 (l. 1927) dit « le mobile compacte à 48h » mais **ne précise pas** le comportement de switch | Responsive owner (Phase 2, doc §23.4 l. 2041-2042) | Non bloquant Phase 1 (mobile-only, l. 2026) ; bloquant Phase 2 (desktop, l. 2024-2028) |
| OQ-15 | `calendrier-semaine` | `Progress bar` d'événement **pluri-jours** (id. 5) | La durée pluri-jours est-elle affichée **en continu** (la `ProgressBar` traverse les jours, ex. un examen du lundi au mercredi) **ou** **par jour** (une pastille par jour, la `ProgressBar` = le % du jour) ? 05 §4.4.1 l. 1931-1933 dit « un `ProgressBar` minuscule si l'événement a une durée pluri-jours » mais ne précise pas si c'est un **seul** barre (continuum) **ou** 3 barres (par jour) | UI owner (`CalendarView.tsx`) | Non bloquant : les 2 rendus sont valides ; le **test** (pack 02 §11, l. 1303-1306) doit couvrir les 2 (le `ProgressBar` = composant §3.7 l. 1259, pas un état propre) |
| OQ-16 | `calendrier-semaine` | `BottomSheet` de détail (id. 6, événement pur, l. 2007-2008) | La `BottomSheet` de détail (événement **pur**, ex. « réunion ») est-elle un **nouveau composant** (pas dans la matrice §3.7 l. 1244-1289, qui n'a que `Modal` l. 1266 et `BottomSheet` l. 1267 **génériques**) **ou** une variante de `BottomSheet` §3.5 l. 787-810 **existante** ? Si nouveau = il faut le déclarer dans la matrice §3.7 (AD-13, l. 1303-1306) ; si variante = il est déjà couvert (l. 1267 « `BottomSheet` : loading ✓, empty ✓, error ✓, offline ✓ ») | DS owner (05 §3.7, pack 02 §11) | Non bloquant (la variante existe dans la matrice l. 1267) ; mais si **nouveau** composant = bloquant pour la matrice §3.7 (AD-13 l. 1244-1289) |
| OQ-17 | `calendrier-semaine` | Couche 2 / `chartPalette` (id. 10, 05 §5.4 l. 3010-3047) | La ligne §10 « le `chartPalette` = 5 séries, l. 3032 » est **factice** : la SSoT `packages/ui/src/themes/*.json` (SSoT code l. 24-26 `keyFiles`) définit `chartPalette` = **3-4 couleurs** par thème (`aurora` = 4, `vesper` = 3, autres = 4 — JSON l. 15-16), et 05 l. 3032 = « 5.4.1 Tableau récapitulatif » (la 4 couleurs du thème, pas 5 séries de G2) ; le Test 10×5 (05 §5.7 l. 3183-3227) = « tester visuellement les **10 thèmes sur 5 écrans** », pas 5 séries de `chartPalette`. **OQ** : la 5ᵉ couleur par `chartPalette` (ex. pour 5 séries de données **simultanées** sur un screen = non couvert par la SSoT existante) ? | Token owner (`packages/ui/src/styles/aurora.css` + JSON thème) | Non bloquant : le `Badge` de type (id. 4) suit le thème courant via `accent.*` (OQ-11), le Test 10×5 passe **sans** 5ᵉ couleur (G2 consomme la `chartPalette` existante, 05 §5.4 l. 3021 : « `chartPalette` (pour G2 — cohérente avec le thème, AD-10) ») ; **bloquant** si l'écran calendrier-semaine exige 5 séries de données **simultanées** sur un G2 → la 5ᵉ couleur = **nouveau** (il faut ajouter 1 couleur × 10 thèmes + 3 presets) → **OQ** |

> **Note OQ** : le slug `calendrier-semaine` **n'apparaît pas** dans le registre OQ
> global de `_inventory.md` §3 (l. 176-192, qui liste les OQ n°1/13/16/36/39/40/41/42/43/44/46/47/48
> **par écran**) — les 9 OQ ci-dessus (n°10-18 ici, **numérotées 10-18 pour éviter la
> collision** avec le OQ-10/11/12 du registre global `projets-liste.md` l. 33-41) sont des
> **OQ locales** à ce slug ; le OQ-1 (ci-dessus) **est** le OQ-1 du registre global
> (l. 180, « OQ-1 = la 1ʳᵉ du registre »). Les OQ 10-18 = à **additionner** dans le
> registre global (05 §4, pack 02 §11, DoD écran-par-écran l. 1303-1306).

## Références SSoT (comptage officiel)

- **Comptage officiel 44** : `_bmad-output/architecture/.../05-design-system.md` l. 39
  (« inventaire écran par écran (44 écrans, doc §2-§18 + §13 + §18) ») + l. 1316-1321
  (règle variante « séparément pour chaque paire »). `calendrier-semaine` = **slug #21**
  de `_inventory.md` l. 98 (table §2, N = 54 slugs spécifiables, l. 35).
- **Routes primaires** : `docs/mobile/navigation-and-page-composition.md` §1 (02 §6.1) ;
  matérialisées dans `apps/mobile/src/router.tsx` (routes primaires : 17, dont `/calendar`
  l. 219 de `_inventory.md` l. 218-220). `calendrier-semaine` = **pas une route distincte**
  (la route = `/calendar`, l. 98 de `_inventory.md` : « `/calendar` (Pager semaine) ») — le
  slug est un **état** du `Pager` (store UI pack 02 §3.2), pas une route (05 §3.4 l. 737-750).
- **Classes offline** : `docs/features/master-feature-catalog.md` l. 21 (col. « offline-capable »
  par feature, §2 Productivity l. 14-29) ; `calendrier-semaine` = `productivity.calendar`
  (l. 21, **offline-capable**).
- **5 états UX + killed (G-M2)** : `docs/ui-libraries.md` §6 l. 174-187 (loading = `Skeleton`,
  error = `Alert` destructive, empty = `Card`, success = `Toast`, offline = `Badge` +
  last-known data, killed G-M2 = `Skeleton` + auto-resync « Reconnexion… » l. 185) ;
  **6 états** ici = les 5 S6 + `killed` (l. 185) ; la matrice §4a ci-dessus couvre les 6.
- **Logos S9** : `docs/ui-libraries.md` §9 l. 349-369 (4 fichiers SSoT, l. 357-360) ;
  §9.1 l. 371-405 (matrice monochrome l. 378-388, interdits l. 390-392, précision
  bloquantes l. 394-405) ; §9.2 l. 407-418 (C2PA stripped copy) ; **ici** = 5 occurrences
  (§13) : 404 (coloré centré), killed (monochrome), presets Nocturne/HC (monochrome),
  header partagé **OQ-18** (coloré, porté par l'enveloppe `calendrier.md`), « jamais »
  la version full in-app (§9 l. 357-358) ; `AgentThinkingLoader` §9.3 = **absent**
  (pas de flux de thinking in-place sur ce slug).
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
  5.10 l. 3295) ; **ici** : les 7 couleurs de type (§4a id. 4) = **dérivées** de
  `accent.*` (OQ-11) ; les `Callout` figés (OQ-12) ; les presets Nocturne/HC =
  monochrome (§13) ; le `chartPalette` = **3-4 couleurs** par JSON thème
  (`packages/ui/src/themes/*.json` l. 15-16, SSoT code) — la ligne §10
  « `chartPalette` = 5 séries, l. 3032 » = **factice** (la SSoT l. 3032 =
  « 5.4.1 Tableau récapitulatif », le 5 du Test 10×5 = 5 **écrans** testés,
  05 §5.7 l. 3183-3227, pas 5ᵉ couleur de `chartPalette`) → **OQ-17**.
- **Tokens** : `05-design-system.md` §2 l. 93-346 (2.1 l. 99, 2.1.1 l. 106, 2.1.2
  l. 124-159, 2.1.3 l. 159-189, 2.2 l. 190, 2.3 l. 232, 2.4 l. 254, 2.5 l. 287) ;
  `docs/design-system/overview.md` §2 l. 15-25 (discipline tokens blocking rule, AD-17) ;
  `ui-libraries.md` S4 l. 145-160 (intégration tokens via CSS variables, `var(--aurora-*)`).
