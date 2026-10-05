# calendrier-mois — Calendrier (vue mois)

Status: SPÉCIFIABLE (OQ: 9) · Module : Productivité · Route : `/calendar` · SSoT : 05 §4.4.1 l. 1896-2043 + 05 §3.4 `Pager` l. 737-750 + 05 §3.6 `CalendarCell` (matrice l. 1276) + 05 §3.7 l. 1244-1309 + ui-libraries S1/S3 + master-feature-catalog §2 l. 21 (`productivity.calendar`, offline-capable)

> Le `calendrier-mois` = la projection **mois** du `Pager` §3.4 (Jour | Semaine | Mois)
> du slug `calendrier` (enveloppe #51, 05 §4.4.1 : « les 3 écrans partagent **le même**
> composant, pas 3 vues séparées »). Zone propre : la **grille 7×5** `CalendarCell`
> (05 l. 1934-1939) — chaque case = 1 jour, **max 3 pastilles** visibles + un « +N » en
> `xs` si plus ; le mois est **dense par construction** : le détail passe au mode
> jour/semaine (drill-down = le switch du `Pager`, pas un push, l. 1987-1995). Les zones
> partagées (TopBar + `Pager`, BottomNav, 404, offline global) sont référencées vers
> `calendrier.md` (enveloppe) et non dupliquées.

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | **Avoir une vue d'ensemble** du mois (voir et planifier, doc §2.4) : 5 semaines de l'un coup d'œil, repérer les jours **chargés** (pastilles saturées) et **vides** avant d'engager | 05 §4.4.1 l. 1898-1906, l. 1934-1939 |
| Contexte | Device mobile (Phase 1) ; moment = le soir (anticiper la semaine qui vient) ou le week-end (planifier le mois) ; réseau = indifférent (lecture locale AD-7) | 05 §4.4.1 l. 1978-1984 ; master-feature-catalog l. 21 |
| Fréquence | **Faible** vs le mode jour (le mois = vue d'ensemble, pas le mode de travail quotidien) ; **haute valeur** pour la détection **proactive** de la surcharge du mois (doc §2.4 « Planification selon le temps réellement disponible ») | 05 §4.4.1 l. 1898-1906 |
| État émotionnel cible | **Orientation** : « où suis-je dans le mois ? » — densité lisible (pastilles, jamais du texte en mobile, §1 « dense progressivement », l. 2034-2038) ; un mois vide n'est **pas un échec**, c'est l'endroit pour **agir** (CTA de création) | 05 §4.4.1 l. 1934-1939, l. 1966-1974 ; 05 §1 l. 69-80 |
| Erreur la plus probable | Ne pas **voir** la surcharge du mois (3 pastilles + « +4 » = 7 événements non perçus) ; le « +N » existe **précisément** pour rendre la saturation visible sans détailler (l. 1936-1938) | 05 §4.4.1 l. 1936-1938, l. 1949-1962 |
| Ce que l'écran RÉSOUT | « Montre-moi tout ce mois » = grille 7×5 bornée (5 semaines max affichées, les jours hors mois affichés grisés) ; **drill-down** = tap case → le `Pager` passe en mode **jour** pour ce jour (l. 1987-1995) ; **replanifier** = le kernel (l. 2016-2021) | 05 §4.4.1 l. 1934-1939, l. 1987-1995, l. 2010-2021 |

## 2. Zones

- **content** (la seule zone propre à ce slug) : la **grille 7×5** `CalendarCell` — 7
  colonnes (lun→dim) × 5 lignes max (les semaines du mois courant + les jours
  bordures de mois précédent/suivant) ; chaque case = **1 jour** : numéro de jour +
  **max 3 pastilles** (la couleur = le **type** d'événement, l. 1916-1922 « les couleurs
  suivent le type, pas le statut ») + un **« +N » en `xs`** si plus de 3 (l. 1936-1938) ;
  un jour **surchargé** porte un `Callout warning` « posé au-dessus du jour concerné »
  (l. 1949-1954) — en grille, le signal = l'indication de surcharge du `Pager` (id. 5).
- **header / footer / surfaces flottantes** : partagés avec l'enveloppe `calendrier`
  (`calendrier.md` §2/§6 — TopBar « Calendrier » + `Pager` §3.4, BottomNav, BottomSheet
  de création/détail, Popover date picker FullCalendar). **Non dupliqués ici**.
- **Breadcrumb** : **n'existe pas** — le calendrier est une **feuille** du module
  Productivité, pas une hiérarchie AD-6 (05 §4.4.1 l. 1996-2001).

## 3. Éléments / widgets

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| 1 | Grille 7×5 `CalendarCell` | `CalendarCell` (05 §3.6, matrice l. 1276 : « n/a / ✓ (jour vide) / n/a / ✓ (locale) ») ; 7 cols × 5 lines max, les jours hors mois grisés (`text-disabled`) | shadcn `card`-like wrapper (AD-10, `CalendarView.tsx` = FullCalendar v6 `dayGridMonth`) — **pas** `ion-calendar` (S3 l. 135) | `surface`, `surface-alt` (mois voisin), `border`, `space.2` | desktop = **plus larges** ; si case **vide** → les événements en **texte** (pas pastille) (l. 2029-2038) | 05 §4.4.1 l. 1934-1939 ; 05 §3.6 l. 1276 |
| 2 | Numéro de jour | texte `JetBrains Mono` `xs` (`text-secondary` ; jours hors mois = `text-disabled`) | id. 1 | `JetBrains Mono` `xs` (l. 1926-1927, pattern partagé semaine/mois), `text-secondary` | n/a | 05 §4.4.1 l. 1934 ; 05 §2.2 l. 190 |
| 3 | Pastille d'événement (**max 3** visibles par case) | pastille = point couleur **type** (l. 1935-1937 : « une pastille par événement, max 3 visibles ») ; couleur = `accent.*`/`chartPalette` **dérivées** (id. 5 du jour, OQ-21 du registre `calendrier-jour`) | id. 1 | 7 types → 7 couleurs de **type** (l. 1916-1922) ; `radius.full` (pastille ronde) | desktop : si case vide → **texte** (l. 2034-2038) | 05 §4.4.1 l. 1934-1939, l. 1916-1922 |
| 4 | Indicateur **« +N »** (`xs`) | texte `JetBrains Mono` `xs` « +N » (N = total − 3) (l. 1936-1938 : « le mois est **dense**, le détail passe au mode jour/semaine, §12 ») | id. 1 | `JetBrains Mono` `xs`, `text-muted` | n/a | 05 §4.4.1 l. 1936-1938 |
| 5 | Indication de **surcharge** du jour (temps planifié vs disponible) | signal porté par la `Case` (`Badge warning`/pastille `warning-surface`) — le `Callout warning` complet vit en mode **jour** (l. 1949-1962) ; le mois **signale** sans détailler | id. 1 | `warning`, `warning-surface`, `radius.sm` | n/a | 05 §4.4.1 l. 1955-1962 ; 05 §3.3 l. 531-544 |
| 6 | Jour **courant** (aujourd'hui) | casemark `primary` (la case du jour = fond `primary-surface` + numéro `primary` 600) — ancré par le `Button ghost` « Aujourd'hui » du `Pager` (l. 742-745) | id. 1 | `primary-surface`, `primary` (05 §2.1.2 l. 124-159 : « la sélection = le 'déjà là', pas l'action ») | n/a | 05 §3.4 l. 742-745 ; 05 §4.4.1 l. 1934 |
| 7 | Jours **bordure** (mois précédent/suivant, complétent la grille 7×5) | `CalendarCell` désaturé : fond `surface-alt`, numéro `text-disabled` — restes **navigables** (le drill-down vers le mois voisin n'est **pas** bloqué) | id. 1 | `surface-alt`, `text-disabled` (l. 124-159 : « un item disabled n'est pas cassé ») | n/a | 05 §4.4.1 l. 1934 (grille = mois entier, 7×5) |
| 8 | `Badge danger` « à resync » (événement non syncé) | `Badge` (matrice l. 1258 `ListItem` : « error = badge resync ») — en mois : l'événement **reste dans la case** (pastille conservée) + pastille `danger` si le jour contient un événement non syncé (AD-7, l. 1974-1979) | id. 1 | `danger`, `danger-surface`, `radius.sm` | n/a | 05 §4.4.1 l. 1974-1979 ; 05 §3.7 l. 1276 |
| 9 | `Badge primary` « nouveau » (syncé depuis le cloud) | `Badge` (l. 748-750 : « le nouveau = indigo, pas rouge — le danger est réservé à l'échec, §2.1.2 ») | id. 1 | `primary`, `primary-surface` | n/a | 05 §3.4 l. 748-750 |
| 10 | `EmptyState` mois vide (`Callout info` « Aucun événement ce mois-ci — ajoutez-en un », CTA = `BottomSheet` de création `DateField` pré-rempli au 1ʳᵉ jour, l. 1966-1974) | `EmptyState`/`Callout info` (05 §3.3 ; matrice l. 1262 : CTA **local**) | shadcn `alert` variant=info + `button` (ui-libraries S1 l. 30-31) | `info`, `info-surface`, `radius.md`, `space.3` | n/a | 05 §4.4.1 l. 1966-1974 ; 05 §3.3 |
| 11 | Tap sur case → **drill-down** jour (le `Pager` passe en mode **jour** pour ce jour, l. 1987-1995) | `CalendarCell` (tap target = la case entière, 44px min) | id. 1 | `focus-ring` (l. 254-264) | n/a | 05 §4.4.1 l. 1987-1995 ; 05 §6.3 |
| 12 | Ligne d'en-tête de la grille (lun→dim) | texte `xs` `text-muted` (les 7 colonnes, ancrées) | id. 1 | `text-muted`, `space.2` | n/a | 05 §4.4.1 l. 1934 (grille 7 cols) ; 05 §2.2 |

**Règle interdits** : `ion-calendar` (S3 l. 135, → FullCalendar v6 `dayGridMonth` via
le wrapper `CalendarView.tsx` AD-10) ; `ion-list` (S3 l. 136) ; `ion-item` (S3 l. 137) ;
`border-radius > 8px` (S3 l. 142) ; **aucun** texte d'événement en mode mobile (la
pastille **est** le format, l. 2034-2038).

## 4. États (6 S6 + sémantiques §6.1) — par élément async

### 4a. Matrice S6 (ui-libraries §6 l. 174-187)

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| 1-2. Grille 7×5 + numéros | `Skeleton` des **cellules** (05 §4.4.1 l. 1963-1965 : « le store local, court, pack 02 §7 ») ; entrée : `opacity 0→1` 200ms (motion.tsx PAGE_TRANSITION @aurora/ui) | Mois **vide** = `Callout info` « Aucun événement ce mois-ci — ajoutez-en un » (id. 10, l. 1966-1974 : pas un vide **mort** — le CTA ouvre la `BottomSheet` de création, `DateField` pré-rempli au 1ʳᵉ jour, §3.2) | Un événement non syncé = pastille `Badge danger` « à resync » (id. 8) — **il reste dans la case** (AD-7, l. 1974-1979) | `Toast` (3s auto-dismiss, « Synchronisé ») après une mutation syncée | Le mois **fonctionne** (lecture locale AD-7, l. 1978-1984) ; `Badge` « Offline » (ui-libraries §6 l. 184) ; création possible (écriture locale, pack 03) ; seul le **scan de documents** est désactivé (l. 1983-1984) | `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) ; le mirror local reste affiché (jamais d'écran blanc, AD-7) |
| 3. Pastilles (id. 3) | n/a (composant, matrice l. 1276) | n/a (pas d'événement = pas de pastille — l'absence est l'état) | la pastille **reste** + passe `danger` (id. 8) | n/a | identique (locale) | n/a |
| 4. « +N » (id. 4) | n/a (l. 1276) | n/a (0 événement → rien, pas de « +0 ») | le compte inclut les non syncés (le « +N » ne filtre **pas** le statut) | n/a | identique (locale) | n/a |
| 5. Surcharge (id. 5) | n/a (« c'est l'état », l. 1286) | n/a (pas de surcharge = pas de signal) | n/a (le signal **est** le rendu de l'erreur de planning) | n/a | le calcul local reste affiché (AD-7) | n/a |
| 6-7. Jour courant / jours bordure (id. 6-7) | n/a (composant, l. 1276) | n/a | n/a | n/a | identique (locale) | n/a |
| 8-9. `Badge` « à resync » / « nouveau » | n/a (l. 1276) | n/a | le `Badge` **est** l'état d'erreur (id. 8) | « nouveau » disparaît après resync (id. 9) | « nouveau » = indigo, pas rouge (l. 748-750) | n/a |
| 10. `EmptyState` mois vide | n/a (« c'est l'état », l. 1262) | (c'est l'état) | n/a | n/a | CTA **local** (la création reste possible, l. 1981-1982 ; matrice l. 1262 « offline = CTA local ») | n/a |
| 11. Tap case (id. 11) | n/a (l. 1276) | n/a (le drill-down vers un jour vide **est** utile — le CTA du jour vit dans `calendrier-jour` §4a) | n/a | n/a | fonctionnel (la navigation temporelle est locale, `Pager` l. 746-747) | n/a |
| 12. En-tête lun→dim | n/a (l. 1276) | n/a | n/a | n/a | identique (locale) | n/a |
| 13. **Scan de documents** liés à un événement (flux serveur AD-12, l. 1983-1984) — `killed` (05 §3.7 l. 1290-1296 ; ui-libraries §6 l. 185) ; la grille locale **reste visible** (AD-7, l. 1978) — **lignes 1-2 de §4a de ce doc et §4b « `échec`/`erreur`/`404` = OQ** (l. SSoT de ce row est factice ; remplacée par OQ ci-dessous, §14) | OQ | OQ | OQ | OQ | OQ |

**Règle de test** (pack 02 §11, 05 §3.7 l. 1303-1306) : composant « composant »
(`CalendarCell`) = test de rendu par état ; la grille = test par écran.

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202)

| État | Rendu | Source SSoT |
|---|---|---|
| `en-cours` | N/A — le mois n'exécute pas d'opération à résultats partiels (pas de streaming, pas de QCM) ; la durée pluri-jours = traitée en mode **jour/semaine** (`ProgressBar` minuscule, §4.4.1 l. 1931-1933, hors de la zone mois) | 05 §4.4.1 l. 1931-1933 |
| `terminé` | N/A — le statut « terminé » d'un événement = donnée de l'événement (badge statut en mode **jour**, l. 1922-1924) ; le mois affiche les **pastilles de type** seulement (l. 1916-1922) | 05 §4.4.1 l. 1916-1924 |
| `échec` | `Callout warning` de conflit/surcharge **posé au-dessus du jour concerné** (l. 1949-1954) ; en grille = l'indication de surcharge (id. 5) — le « Replanifier » = le `Callout` du mode **jour** (ce slug signale, le jour agit) ; **CTA de l'`échec` du slug mois** = le `Button ghost` « Replanifier » (id. 5, 05 §4.4.1 l. 2010-2021) — **texte exact OQ-37 ci-dessous** (la SSoT dit « le jour agit », mais le mois ne doit pas rester **sans CTA** — règle §6.1 l. 193 : « exact text / component / token / CTA, never blank ») | 05 §4.4.1 l. 1949-1962, l. 2010-2021 |
| `succès` | `Toast` (S6 `success`, 3s auto-dismiss) après une création/synchro d'événements du mois | ui-libraries §6 l. 183 |
| `erreur` | `Badge danger` « à resync » (id. 8) — transitoire, auto-resync au retour du réseau (pack 03 §5.5) ; ≠ `échec` (conflit structurel) | 05 §4.4.1 l. 1974-1979 ; ui-libraries §6.1 l. 201 |
| `404 / not-found` | Page entière (partagée avec `calendrier.md`) : logo AURORA **coloré sans fond** au **centre** (ui-libraries §9.1 l. 387 ; §6.1 l. 202), message court, CTA primaire « Retour à l'accueil » ; ce slug est routé (`/calendar`) donc l'état 404 s'applique à l'enveloppe | ui-libraries §6.1 l. 202 ; 05 §3.4 l. 737-750 |

### 4c. `killed` (tout flux serveur)

Les flux serveurs de ce slug (AD-12, l. 2016-2021 + l. 1983-1984) :

1. **Replanification** (mode **jour**, `Button ghost` « Replanifier ») — traitée dans
   `calendrier-jour` §4c ; **pas** un flux de ce slug (le mois signale, le jour agit,
   l. 2010-2021).
2. **Scan de documents** liés à un événement (id. 13, l. 1983-1984) : `killed` =
   `Skeleton` + bannière fine DS « Reconnexion… » (05 §3.7 l. 1290-1296 ; ui-libraries
   §6 l. 185) ; la grille locale **reste visible** (AD-7, l. 1978) — le scan reste
   **indisponible** (AD-12, l. 2016-2021) — **texte exact = OQ-36 ci-dessous** (la SSoT
   ne cite pas explicitement cette ligne).

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| Tap sur case (id. 11) | tap → le `Pager` passe en mode **jour** pour ce jour (l. 1987-1995, **pas** un push — le drill-down **est** le switch de mode) ; le contenu slide (150-200ms `ease-out`) | 150-200ms (`anim.fast`/`normal`, 05 §2.6 l. 310-320) | `transform: translate` + `opacity` (motion.tsx PAGE_TRANSITION @aurora/ui) | `static` (05 §2.6 l. 330-334, règle 2) | 05 §4.4.1 l. 1987-1995 |
| `Pager` (mode + avant/après, partagé) | switch Jour/Semaine/**Mois** + navigation mois | 200ms `ease-out` | `opacity` (le mode change, la position est **persistée**, l. 743-745) | `static` | 05 §3.4 l. 737-745 |
| `Button ghost` « Aujourd'hui » (partagé, `Pager`) | press → `scale 0.95`, ancre la grille au mois courant | 150ms | `transform: scale(0.95)` | `static` | 05 §3.4 l. 742-743 ; 05 §3.1 l. 383-385 |
| Pastilles (id. 3) / « +N » (id. 4) | **AUCUNE** animation (la pastille est **statique** — les données ne s'animent jamais, 05 §2.6 l. 323-330 règle 1 ; l'événement **est** la donnée) | n/a | n/a | n/a | 05 §2.6 l. 323-330 |

**Règles bloquantes** : pas de `layout` animations sur mobile (ui-libraries S5 l. 169) ;
pas de bouncy (ui-libraries S3 l. 143) ; 150-250ms seulement (ui-libraries S3 l. 143) ;
`prefers-reduced-motion` = **tout** `static` (05 §2.6 l. 330-334, règle 2).

## 6. Modals / BottomSheets / Drawers (spécifiques au contenu mois)

| Surface | Déclencheur | Contenu | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|
| `BottomSheet` de **création** (CTA `empty`, id. 10) | tap sur le CTA du `Callout info` « Aucun événement ce mois-ci » (l. 1966-1974) | `DateField` pré-rempli au 1ʳᵉ jour du mois + `DurationField` (l. 1972-1974, §3.2) | `back` / tap backdrop | 250ms `ease-out` (05 §2.6 l. 317) | 05 §4.4.1 l. 1966-1974 ; 05 §3.5 l. 787-810 |
| Drill-down case → **mode jour** | tap sur une `CalendarCell` (id. 11) | **pas** une surface flottante : le `Pager` switch en mode jour pour ce jour (l. 1987-1995) ; le détail événement vit dans `calendrier-jour` §6 (`BottomSheet` événement pur / push `taches-detail`) | `back` (le mode revient en **mois**, position persistée, l. 743-745) | 200ms `ease-out` | 05 §4.4.1 l. 1987-1995, l. 2001-2009 |

Le `Popover` date picker FullCalendar et le `Menu` de tri sont dans `calendrier.md` §6
(enveloppe, non dupliqué ici).

## 7. Formulaires

| Champ | Lib | Validation | Clavier mobile | Persistance | SSoT |
|---|---|---|---|---|---|
| `DateField` (pré-rempli au 1ʳᵉ jour du mois dans la `BottomSheet` de création, l. 1972-1974) | shadcn `input` (lecture seule) + `Popover` FullCalendar (ui-libraries S1 l. 23 ; S3 l. 138 « ion-datetime → FullCalendar + Popover ») | `zod` : date dans le mois courant si création depuis l'`EmptyState`, sinon [−12 mois, +12 mois] | Capacitor `Keyboard` pour l'avoidance (ui-libraries S5 l. 170) | Local-first (AD-7, 02 §6.3) ; la sync est différée (pack 03) | 05 §3.2 l. 480-489 ; 05 §4.4.1 l. 1966-1974 |
| `DurationField` (durée de l'événement, `min`/`h` en `JetBrains Mono`, **jamais** `HH:MM`) | shadcn `input` + suffixe `TextField` (05 §3.2 l. 486-488) | `zod` : min 5 min, max 480 h | id. | id. | 05 §3.2 l. 486-488 |

**Interdiction** : un `TextField` qui cache le label quand vide (05 §3.2 l. 434-436) ;
`ion-item` pour le formulaire (S3 l. 137, → shadcn/Radix).

## 8. Pagination

**Règle unique nommée** : `Pager` jour-semaine-mois (05 §3.4 l. 737-750) — le `Pager`
**est** la pagination temporelle de ce slug (`SegmentedControl` `Jour | Semaine | Mois`
+ la ligne de navigation avant/après en **mois** + `Button ghost` « Aujourd'hui »).

- **Pas de shadcn Pagination ni AG Grid** : la grille mois = 7×5 = **35 cases max**
  (borné par l'échelle temporelle, pas par un nombre de lignes illimité) ; le volume
  est **trop petit** pour la décision tree ui-libraries S8 l. 304-307 (<20 rows →
  `Table` sans pagination ; ici 35 cases → pas de pagination, le scroll est
  suffisant).
- **Params** : le `Pager` est **persisté** par l'écran (store UI pack 02 §3.2, l. 743-745) ;
  le retour retrouve le même mode (mois) et le même mois ancré (règle de non-surprise,
  l. 745).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** depuis `calendrier-jour`/`calendrier-semaine` (drill-down **retour**) | tap sur le `SegmentedControl` « Mois » = **switch de mode** (pas un push, l. 1987-1995) ; la position temporelle est **persistée** (le retour retrouve le même mois, l. 743-745) ; contenu : slide 150-200ms `ease-out` | 05 §4.4.1 l. 1987-1995 ; 05 §3.4 l. 743-745 ; 05 §2.6 l. 310-320 |
| **Drill-down** case → jour | tap sur `CalendarCell` → le `Pager` passe en mode **jour** pour ce jour (l. 1987-1995) ; le Breadcrumb **n'existe pas** (feuille, l. 1996-2001) | 05 §4.4.1 l. 1987-1995, l. 1996-2001 |
| **Événement → détail** | **pas ici** : le mois ne détaille **rien** (pastille = format borné, l. 1934-1939) ; le détail passe au mode jour/semaine → `calendrier-jour` §9 | 05 §4.4.1 l. 1934-1939, l. 1987-1995 |
| **Replanifier** | **pas ici** : le `Button ghost` « Replanifier » vit dans le `Callout warning` du mode **jour** (l. 2010-2021) ; ce slug **signale** (id. 5) mais n'agit pas | 05 §4.4.1 l. 2010-2021 |
| **404** (deep link invalide, ex. `?month=99999`) | → `not-found` (enveloppe, `calendrier.md` §4b) : logo AURORA coloré au centre, CTA « Retour à l'accueil » | ui-libraries §6.1 l. 202 |

## 10. Thèmes

Comportement par couche (05 §5 l. 2925-3306 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#FFFFFF` / Dark `#121212`) : fournit `surface`,
  `surface-alt` (mois voisin), `text-primary/secondary/disabled`, `border` — les tokens
  géométriques de la grille (cases = `surface`, bordures = `border`). Les 10 thèmes
  vivants **ne redéfinissent jamais** les sémantiques (05 §5.1 l. 2931, règle bloquante).
- **Couche 2 — Expressive** (4 accents + chartPalette, 05 §5.4 l. 3010-3047) : les 7
  couleurs de **type** de pastille (cours/examen/réunion/devoir/révision/projet/routine,
  l. 1916-1922) sont **dérivées** de `accent.primary/secondary/punctual` + `chartPalette`
  — **jamais de valeur brute par thème** (AD-17, l. 2961). Le jour **courant** (id. 6)
  suit `primary-surface`/`primary` du thème courant.
- **Couche 3 — Presets** (`slate` / `nocturne` / `high-contrast`, 05 §5.5 l. 3153) :
  les pastilles restent lisibles ; en `high-contrast` = tap targets 56px (05 §6.3, a11y) ;
  le signal `warning` de surcharge (id. 5) = **figé** (pas redéfini par le thème, 05 §5.1
  l. 2931).
- **Test 10×5** (05 §5.7 l. 3183-3227) : la grille 7×5 doit passer les 5 styles ×
  10 thèmes (`chartPalette` = 5 séries, l. 3032).

## 11. A11y (WCAG AA, 05 §6.3)

- Tap targets **≥ 44px** (56px en `high-contrast`, 05 §6.3) : la **case entière** de la
  grille = tap target (id. 11) — le mois = 7 cols × 5 lines sur 1 écran, chaque case
  dépasse largement 44×44px ; les pastilles (« +N », le signal surcharge) = **jamais**
  le tap target (le tap = la case, les pastilles sont des **indicateurs**, pas des
  boutons, OQ-31 ci-dessous).
- `aria-label` sur **tous** les icon buttons (les icônes « précédent/suivant » du
  `Pager` = icon-only → `aria-label` obligatoire, 05 §3.1 l. 388-396, test CI §7) ; la
  case porte `aria-label` « <jour> <mois> <n> événements » (N = le total, **pas** 3 —
  l'indicateur « +N » ne doit **pas** tromper le lecteur d'écran, OQ-31).
- `letter-spacing 0` (05 §6.3) ; `focus-visible` ring = `focus-ring` (token, 05 §2.4
  l. 254-264) sur la case active.
- Les 7 couleurs de **type** (l. 1916-1922) = **jamais la seule information** : la
  pastille porte le **couleur de type** mais l'information passe par le **drill-down**
  (le détail jour affiche le texte, l. 2001-2009) + `aria-label` (non-color-only,
  05 §6.3) ; le `Badge danger` « à resync » (id. 8) = texte + couleur, pas couleur seule.

## 12. Offline

- **Classe offline** (master-feature-catalog §2 l. 21) : `productivity.calendar` =
  **offline-capable** (agenda / time blocking / détection conflits+surcharge ; agent
  `calendar.schedule` = CONFIRMATION_REQUIRED ; `POST_NOTIFICATIONS` au 1ʳᵉ usage,
  jamais au boot — `apps/mobile/src/pages/calendar/index.tsx` l. 9).
- **Miroir local** (AD-7 / AD-12) : le mois **fonctionne** offline — lecture locale du
  store local (PowerSync/SQLite, pack 02 §7) ; la navigation temporelle (`Pager`) est
  **locale** (l. 746-747) ; la création reste **possible** (écriture locale, pack 03) ;
  seul le **scan de documents** liés à un événement est désactivé (l. 1983-1984) →
  `killed` = cette feature (le scan, pas le calendrier).
- **Dégradation AD-1** : si le kernel est down (la replanification, mode **jour**) =
  `Button ghost` **désactivé** + `Callout info` « Hors-ligne — cette action nécessite le
  réseau » (05 §3.5 l. 777-779) ; la grille locale **reste visible** (AD-7, l. 1978-1984).
- **Au retour du réseau** : les événements **nouveaux** syncés depuis le cloud
  apparaissent avec leur `Badge` « nouveau » `primary` (indigo, pas rouge, l. 748-750) —
  pack 03 §5.5 re-sync.

## 13. Occurrences logos (version exacte + raison + SSoT ref)

| Où | Version | Raison (designer psychology) | SSoT |
|---|---|---|---|
| **404 / not-found** (deep link invalide, ex. `?month=99999`, id. 11) | **COLORED sans fond**, au **centre** de la page (ui-libraries §9.1 l. 387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; message court + CTA primaire « Retour à l'accueil » | L'état 404 = **état vivant** (le CTA primaire = action active) ; la marque **doit** être colorée pour signifier « l'app répond encore » (ui-libraries §9.1 l. 390-392 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») | ui-libraries §9.1 l. 378-388 (matrice), l. 390-392 (interdits), l. 394-405 (précision bloquantes) ; ui-libraries §6.1 l. 202 ; 05 §3.4 l. 737-750 |
| **Killed / bannière « Reconnexion… »** (id. 4a `killed`, l. 1290-1296) | **MONOCHROME** (grayscale tonal, ui-libraries §9.1 l. 383 « Killed / disabled states (S6) = monochrome ») — les `Badge` « à resync »/« nouveau » (id. 8-9) restent **colorés** (ils sont vivants, pas killed) | La marque **est présente mais silencieuse** : « brand present but not speaking » (ui-libraries §9.1 l. 374-376) ; le `killed` = l'app attend le resync, pas une action | ui-libraries §9.1 l. 378-388, l. 383 ; 05 §3.7 l. 1290-1296 |
| **Nocturne / High Contrast presets** (id. 10, couche 3) | **MONOCHROME** (ui-libraries §9.1 l. 384 « Nocturne + High Contrast presets = monochrome ») ; les 10 thèmes expressifs = **colorés** | « desaturated / high-contrast universes ; the 10 expressive themes = colored version » (l. 384) — le monochrome = neutralité, les 10 expressifs = vivants | ui-libraries §9.1 l. 378-388, l. 384 ; 05 §5.5 l. 3153 |
| **Jamais** | La version **full** (fond arrondi) **n'est PAS** dans ce slug (ni dans l'app, ui-libraries §9 l. 357-358 « NEVER inside the app UI ») ; usage ad hoc **interdit** (ui-libraries §9 l. 352-353) | S9 l. 352-353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else » ; la version full = **exclusivement** l'icône app externe (Capacitor / Play Store / splash) | ui-libraries §9 l. 349-369 ; §9.1 l. 390-392 ; §9.2 l. 407-418 (C2PA stripped) |

**Règle bloquante** : 0 `usage ad hoc` du logo sur ce slug — les 3 occurrences ci-dessus
(exclusives : 404 / killed / presets) = les seules, toutes citées par SSoT (ui-libraries
§9.1 l. 378-388). Le `AgentThinkingLoader` (ui-libraries §9.3) **n'apparaît pas** ici
(ce slug n'a pas de flux de **thinking** du kernel — le « Replanifier » ouvre `agent`
§4.9.1, pas un in-place thinking sur le calendrier, comme le mode jour).

## 14. Open Questions (OQ)

| # | Écran | Élément | Question | Décideur | Blocage |
|---|---|---|---|---|---|
| OQ-1 | (global, inventaire) | règle de comptage des variantes (liste + détail + vues + pagers) | Le slug `calendrier-mois` = **variante** du `calendrier` (05 §4.4.1 l. 1901-1906 : « le `Pager` §3.4 est le composant partagé, les 3 écrans partagent le **même** composant ») **ou** écran indépendant (inventaire `_inventory.md` l. 99 : `calendrier-mois` = **slug #22** distinct de `calendrier-jour` l. 97 et `calendrier-semaine` l. 98) ? | Design System team (owner 05 §4, pack 02 §4/§6) | Ouvre / ferme ce doc (variante = section du `calendrier.md` ; écran = ce doc) ; `_inventory.md` l. 58 « le delta exact 44→54 est l'OQ n°1 §3 » |
| OQ-30 | `calendrier-mois` | Grille 7×5 (id. 1) | Le « 7×5 » de 05 §4.4.1 l. 1934 = **5 lignes fixes** (les jours hors mois = grisés, toujours affichés, id. 7) **ou** 5-6 lignes **selon le mois** (janv. 2026 = 6 semaines, 31 jours + 3 du mois précédent) ? Si 5 fixes = 6 lignes pour les mois longs (le `CalendarCell` « hors mois » existe déjà, id. 7) ; si variable = la grille change de hauteur entre les mois (la **règle de non-surprise** l. 745 parle de position temporelle, pas de hauteur de grille) | UI owner (`CalendarView.tsx`) | Non bloquant Phase 1 (mobile) : les 2 rendus sont valides ; le **test** (pack 02 §11, l. 1303-1306) doit couvrir les mois à 5 **et** 6 semaines (ex. janv./avr./juin 2026 = 6) |
| OQ-31 | `calendrier-mois` | Pastilles + « +N » (id. 3-4) | Le **drill-down** = la **case entière** (OQ-31a : la pastille n'est **pas** le tap target) **ou** la pastille **individuelle** (tap sur la pastille « examen » → le jour se pré-filtre sur ce **type**) ? 05 §4.4.1 l. 1987-1995 dit « un `CalendarCell` (semaine/mois) → le **jour** concerné » (= la case, pas la pastille) mais ne **proscrit pas** le pré-filtre par type ; si pré-filtre = 7 tap targets par case (a11y : `aria-label` par pastille, §11) + le mode jour **filtre** par type au mount (OQ-22 du `calendrier-jour` = le filter local est déjà posé là) | UI owner (`CalendarView.tsx`) + a11y owner | Non bloquant pour le rendu (la pastille reste un **indicateur**) ; bloquant pour l'interaction (case-only vs pastille-préfiltre) + le `aria-label` de la case (N = total vs N = filtré) |
| OQ-32 | `calendrier-mois` | Surcharge du jour (id. 5) | Le **calcul** de surcharge (l. 1955-1962 : « temps réellement planifié vs temps disponible ») est-il **local** (le store UI calcule au mount, AD-7) **ou** un `Job` serveur (AD-8) ? En mode **mois** = le signal (id. 5) est **agrégré** (pas le `Callout` détaillé du jour) : si local = immédiat ; si `Job` = le signal arrive en **différé** (le mois peut afficher un état **stale** jusqu'au resync) | Feature owner (`productivity.calendar`, master-feature-catalog l. 21) | Non bloquant : l'écran affiche le signal dans les 2 cas ; le `loading` du calcul (si `Job`) = `Skeleton` du signal (matrice l. 1286) |
| OQ-33 | `calendrier-mois` | `CalendarCell` (id. 1) | Le `CalendarCell` (05 §3.6, matrice l. 1276) est un **composant dédié** de `packages/ui` (type `CalendarCell.tsx`, SSoT code l. 24-26 de `keyFiles`) **ou** un wrapper `shadcn card` + `FullCalendar` v6 `dayGridMonth` ? Si wrapper = `OQ` (S3 l. 135 interdit `ion-calendar` mais **pas** un wrapper `CalendarView` maison) ; si maison = S3 l. 141 « custom SVG decorations » ne s'applique **pas** (la pastille n'est pas un décor) mais la règle S1 « 1 écran = 1 système de composants » **s'applique** (le FullCalendar + un `CalendarCell` maison = 2 libs, S8 l. 333) | UI owner (`packages/ui`) | Bloquant : `CalendarCell` §3.6 est cité comme **composant DS** (05 §3.6, matrice l. 1276) mais le SSoT code `CalendarView.tsx` (l. 24-26 `keyFiles`) est un **wrapper** — la matrice §3.7 (l. 1276) le liste comme composant **à part** (pas comme « FullCalendar ») → l'implémentation attend l'arbitrage wrapper-vs-dédié (idem OQ-20 du `calendrier-jour`) |
| OQ-34 | `calendrier-mois` | Couleurs de pastilles (id. 3) | Les 7 couleurs de **type** (l. 1916-1922 : cours / examen / réunion / devoir / révision / projet / routine) sont-elles **dérivées** de `accent.primary/secondary/punctual` (id. 10, couche 2) **ou** des **tokens sémantiques figés** (`success/warning/danger/info`, 05 §2.1.2 l. 124-159) ? Si dérivées = la pastille suit le thème (id. 10) ; si figées = 7 tokens neufs (pas dans la matrice §2.1.2) → **OQ** (AD-17, l. 2961 : les couleurs de **type** ≠ couleurs de **statut**, l. 1922-1924) | Token owner (`packages/ui/src/styles/aurora.css`) | Non bloquant si dérivées ; bloquant si figées (il faut 7 tokens sémantiques neufs, pas dans la matrice §2.1.2 l. 124-159) (idem OQ-21 du `calendrier-jour`) |
| OQ-35 | `calendrier-mois` | Desktop : texte vs pastille (id. 3, l. 2029-2038) | « si la case est **vide** → les événements en **texte** pas en pastille » (l. 2034-2038) : **quelle case** est « vide » — celle sans **pastille** (0 événement) **ou** celle sans **texte** (≤3 événements = pastilles, jamais de texte) ? Le mot « vide » de l. 2033 = **pas d'événement** (la case ne peut pas être « vide de texte » si elle a des pastilles) ; mais alors, une case avec **4+ événements** (le « +N » du mobile) en desktop = **texte** (les 4+ événements en liste dans la case) **ou** pastilles + « +N » comme le mobile ? Si texte = la case déborde (la grille 7 cols × 6 lignes a une **hauteur fixe**, le contenu texte = scroll par case ?) | Responsive owner (Phase 2, doc §23.4 l. 2041-2042) | Non bloquant Phase 1 (mobile-only, l. 2026) ; bloquant Phase 2 (desktop, l. 2024-2028) : le comportement de la case « dense » (4+ événements) en desktop n'est **pas précisé** par la SSoT |
| OQ-36 | `calendrier-mois` | `killed` — flux serveur du slug (l. 13 de §4a) | Le §4c de ce doc dit « le **seul** flux serveur de ce slug = la **replanification** (mode **jour**…) » (l. 2016-2021), mais la replanification n'est pas un élément listé dans §3 — elle n'a donc pas de ligne dans la matrice §4a ; et §12 dit que le **scan de documents** liés à un événement est la feature **désactivée** offline (`killed` = le scan, pas le calendrier, l. 1983-1984) — le scan étant porté par le calendrier (l'événement s'y rattache, l. 1974-1979), il **est** un flux serveur de ce slug. À trancher : (a) le scan est-il le **seul** flux serveur de ce slug (la replanification étant le flux de `calendrier-jour`, non de ce slug) ? (b) quelle est la **ligne** qui le porte dans la matrice §4a — la l. 13 (id. 13, ligne que j'ajoute) **ou** l'id. 8 (`Badge danger` « à resync ») ? (c) le texte exact de `killed` pour cette ligne est-il « `Skeleton` + bannière fine DS « Reconnexion… » » (l. 1290-1296) **ou** « bannière « Reconnexion… » + scan désactivé, grille locale affichée » (le scan étant **non critique**, l. 1983-1984) ? | Feature owner (`productivity.calendar`, master-feature-catalog l. 21) + UI owner | **Bloquant pour la complétude de la matrice §4a** : la règle AD-13 (ui-libraries §6 l. 187 « no async component may ship without the 6 states ») s'applique au scan ; la l. 13 actuellement = OQ. Non bloquant pour le rendu Phase 1 mobile (le scan est désactivé offline de toute façon) |
| OQ-37 | `calendrier-mois` | `échec` (ligne de §4b) | La ligne « `échec` » de §4b dit « le « Replanifier » = le `Callout` du mode **jour** (ce slug signale, le jour agit) » (l. 2010-2021) ; le §9 dit « le `Button ghost` « Replanifier » vit dans le `Callout warning` du mode **jour** ; ce slug **signale** (id. 5) mais n'agit pas », et le §13 documente le `AgentThinkingLoader` comme **absent** de ce slug (« le « Replanifier » ouvre `agent` §4.9.1, pas un in-place thinking sur le calendrier »). À trancher : (a) le CTA d'`échec` de **ce** slug (mois) est-il le **même** `Button ghost` « Replanifier » que le jour (le mois **signale**, le jour **agit** — mais alors l'`échec` du mois n'a **pas** de CTA, en contradiction avec la règle §6.1 l. 193 « exact text / component / token / CTA, never blank ») **ou** le mois a-t-il son propre CTA (ex. « Voir le jour » = le drill-down id. 11) ? (b) le texte exact du CTA d'`échec` est-il « Replanifier » (id. jour) **ou** « Voir le jour » (drill-down, OQ-31 = case-only) ? | Feature owner (`productivity.calendar`) + UI owner | **Bloquant pour la complétude de la matrice §4b** : la règle §6.1 (ui-libraries l. 193) s'applique à `échec` ; la ligne actuellement = « le mois **signale** sans détailler » (pas de CTA explicite). Non bloquant pour le rendu Phase 1 mobile (le mois affiche l'indication de surcharge, le CTA vit dans le jour) |

> **Note OQ** : le slug `calendrier-mois` **n'apparaît pas** dans le registre OQ
> global de `_inventory.md` §3 (l. 176-192, qui liste les OQ n°1/13/16/36/39/40/41/42/43/44/46/47/48
> **par écran**) — les 8 OQ ci-dessous (n°30-37, **numérotées 30-37 pour éviter la
> collision** avec le registre global et les OQ-20-26 de `calendrier-jour` l. 229-236)
> sont des **OQ locales** à ce slug ; le OQ-1 (ci-dessous) **est** le OQ-1 du registre
> global (l. 180, « OQ-1 = la 1ʳᵉ du registre »). Les OQ 30-37 = à **additionner** dans
> le registre global (05 §4, pack 02 §11, DoD écran-par-écran l. 1303-1306).

## Références SSoT (comptage officiel)

- **Comptage officiel 44** : `_bmad-output/architecture/.../05-design-system.md` l. 39
  (« inventaire écran par écran (44 écrans, doc §2-§18 + §13 + §18) ») + l. 1316-1321
  (règle variante « séparément pour chaque paire »). `calendrier-mois` = **slug #22**
  de `_inventory.md` l. 99 (table §2, N = 54 slugs spécifiables, l. 35).
- **Routes primaires** : `docs/mobile/navigation-and-page-composition.md` §1 (02 §6.1) ;
  matérialisées dans `apps/mobile/src/router.tsx` (routes primaires : 17, dont `/calendar`
  l. 219 de `_inventory.md` l. 218-220). `calendrier-mois` = **pas une route distincte**
  (la route = `/calendar`, l. 99 de `_inventory.md` : « `/calendar` (Pager mois) ») — le
  slug est un **état** du `Pager` (store UI pack 02 §3.2), pas une route (05 §3.4 l. 737-750).
- **Classes offline** : `docs/features/master-feature-catalog.md` l. 21 (col. « offline-capable »
  par feature, §2 Productivity l. 14-29) ; `calendrier-mois` = `productivity.calendar`
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
  est borné par la période : 35 cases max, cf. §8).
- **États S6 / §6.1** : `ui-libraries.md` §6 l. 174-187 ; §6.1 l. 189-202 (en-cours
  l. 197, terminé l. 198, échec l. 199, succès l. 200, erreur l. 201, 404/not-found
  l. 202) ; **ici** : en-cours = N/A, terminé = N/A, échec = signal surcharge +
  `Callout` en mode jour (§4b), succès = `Toast` (§4b), erreur = `Badge danger`
  « à resync » (§4a), 404 = logo AURORA coloré centre (§4b / §13).
- **Thèmes** : `05-design-system.md` §5 l. 2925-3306 (5.1 l. 2931, 5.2 l. 2961, 5.3
  l. 2992, 5.4 l. 3010-3047, 5.5 l. 3153, 5.6 l. 3167, 5.7 l. 3183-3227, 5.8 l. 3235,
  5.10 l. 3295) ; **ici** : les 7 couleurs de type des pastilles (§4a id. 3) =
  **dérivées** de `accent.*` (OQ-34) ; le signal `warning` de surcharge (id. 5) =
  **figé** (05 §5.1 l. 2931) ; les presets Nocturne/HC = monochrome (§13).
- **Tokens** : `05-design-system.md` §2 l. 93-346 (2.1 l. 99, 2.1.1 l. 106, 2.1.2
  l. 124-159, 2.1.3 l. 159-189, 2.2 l. 190, 2.3 l. 232, 2.4 l. 254, 2.5 l. 287) ;
  `docs/design-system/overview.md` §2 l. 15-25 (discipline tokens blocking rule, AD-17) ;
  `ui-libraries.md` S4 l. 145-160 (intégration tokens via CSS variables, `var(--aurora-*)`).
