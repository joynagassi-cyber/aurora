# Écran — Tâches (liste) (`taches-liste`)

Module : Productivité · Route : `/tasks` · Statut : **additif** · SSoT écran : WDS `05.3-taches-liste` (OQ-1…OQ-4 closes) + `catalog productivity.tasks` · Catalogue SSoT : WDS 05.3 §Design + `05-design-system` §3.3/§3.4/§3.7/§4.3.1 + `ui-libraries` S1/S3/S5/S6/S8 + `master-feature-catalog` L19

---

## §1 Psychologie du designer

| Dimension | Valeur |
|---|---|
| Objectif utilisateur | Voir la liste plate de mes tâches, triée par priorité par défaut, et ouvrir le Kanban global en un geste (CTA fixe « Ouvrir le Kanban »). |
| Contexte (appareil/moment/réseau) | Mobile, en déplacement, réseau variable : la liste est une lecture locale (AD-7), donc toujours lisible hors-ligne. |
| Fréquence | Quotidienne, multiple fois par jour (boucle Horebs capture→exécuter). |
| État émotionnel cible | Technical Calm : un flux linéaire, prévisible, jamais bloquant ; le CTA est le seul ancrage d'action. |
| Erreur la plus probable | Tâche marquée « done » alors qu'elle est en réalité « doing » (statut intermédiaire mal choisi) ; ou tap CTA alors qu'on voulait éditer une tâche (BottomSheet s'ouvre à la place). |
| Ce que l'écran RÉSOUT | La question « qu'est-ce que je dois faire maintenant ? » en montrant la tâche à plus haute priorité d'abord (OQ-3 close B), et l'offre d'une autre vue (Kanban global) sans quitter le flux liste. |
| Invariant | AD-14 : le CTA « Ouvrir le Kanban » est la **seule** action CTA de l'écran, toujours visible, jamais conditionnel, jamais remplacé par une suggestion d'agent. (WDS 05.3 OQ-2 close A ; 05 §4.1 invariant AD-14) |

---

## §2 Zones de l'écran

| Zone | Contenu | SSoT |
|---|---|---|
| TopBar | Titre « Tâches » + icône menu (filtre) | WDS 05.3 §Design ; 05 §3.2 TopBar |
| Barre de filtre (menu) | Filtres : date / priorité (défaut) / statut | WDS 05.3 OQ-1 close A |
| Liste plate (1 colonne) | Chaque tâche = 1 ligne : titre + Badge statut/priorité | WDS 05.3 OQ-1 close A ; 05 §3.3 ListItem l.513 |
| CTA fixe | « Ouvrir le Kanban » Button primary, toujours visible | WDS 05.3 OQ-2 close A ; AD-14 |
| BottomNav | 5ᵉ tab = `/agent` (chat) ; 2ᵉ tab = cet écran | WDS 05.3 OQ-4 close C ; 05 §3.6 BottomNav |
| Détail (overlay) | Tap tâche → BottomSheet `/tasks/:id` (S-24) | WDS 05.3 §Interactions ; 02 §6.1 l.390 |

---

## §3 Éléments de l'écran (table 100 % de la zone)

| Élément | Composant DS 05 §3 | lib ui-libraries S1 | Tokens (AD-17) | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Titre « Tâches » | TopBar (05 §3.2) | shadcn Text / IconButton | `text.xl`, `color.neutral.900/100`, `spacing.xl` | même mobile/desktop | 05 §3.2 ; WDS 05.3 §Design |
| Icône menu filtre | IconButton (05 §3.2) | shadcn IconButton + Menu (shadcn) | `icon.size=20`, `touch.target=44` (HC 56) | même | 05 §3.2 ; a11y 05 §6.3 |
| Liste plate (1 col) | ListItem (05 §3.3 l.513–529) | shadcn List + ListItem custom (S3 interdit `ion-list` data) | `row.min-height=56`, `color.neutral.900/100`, `color.warning/danger/info` par statut | même mobile/desktop (1 colonne, OQ-1 close A) | 05 §3.3 l.513 ; WDS 05.3 OQ-1 |
| Badge statut/priorité | Badge/Chip (05 §3.3 l.531–544) | shadcn Badge | `color.warning/danger/info/success`, `font.mono` (JetBrains Mono xs) | même | 05 §3.3 l.531 ; WDS 05.3 §Design |
| CTA « Ouvrir le Kanban » | Button primary (05 §3.1) | shadcn Button variant `primary` | `color.brand.primary`, `touch.target=48` (HC 56), `radius=8` max | même, toujours visible (AD-14) | 05 §3.1 ; AD-14 ; WDS 05.3 OQ-2 |
| BottomNav 5 tabs | BottomNav (05 §3.6) | shadcn Tabs / custom nav (non ion) | `color.neutral.900/100`, `icon.size=20`, `touch.target=44/56` | mobile-only ; desktop = side nav (05 §3.6) | WDS 05.3 OQ-4 ; 05 §3.6 |
| BottomSheet détail | BottomSheet (05 §3.5) | shadcn Dialog/Sheet (S1 l.13–14) | `color.neutral.900/100`, `radius=8`, `touch.target=44` | même | WDS 05.3 §Interactions ; S1 l.13 |
| Toast feedback | Toast (05 §3.5) | shadcn Toast (S6 l.183–187) | `color.success` (success), auto-dismiss 3 s | même | 05 §3.5 ; S6 |

> S3 (ui-libraries l.133–143) : `ion-list` data / `ion-item` / `ion-calendar` **interdits**. La liste plate est un shadcn List + ListItem custom (composant non encore dans `packages/ui` → **OQ-2** §14).

---

## §4 États de l'écran

### §4(a) Matrice 6 états S6 (AD-13) — élément asynchrone : liste plate

| État | Composant | Tokens | Texte exact | CTA | Entrée/Sortie |
|---|---|---|---|---|---|
| **loading** | Skeleton (pulse opacity 0.6→1, 1.2 s) + ListItem skeleton | `color.neutral.400`, `spacing.m`, `anim.slow=400ms` (pulse) | (silencieux, pas de texte) | CTA « Ouvrir le Kanban » reste actif (lecture locale, AD-7) | entrée : fade 150 ms ; sortie : swap liste 250 ms |
| **empty** | Card vide (icône + CTA) | `color.neutral.400`, `icon.size=24`, `text.sm` | « Aucune tâche » | CTA « Ouvrir le Kanban » + capture rapide (si dispo) | fade 250 ms |
| **error** | Alert (retry) | `color.danger`, `text.sm` | « Impossible de charger les tâches. Réessayer ? » | Button « Réessayer » (primary) + CTA Kanban toujours actif | fade 200 ms ; retry = re-lecteur local (AD-7) |
| **success** | Toast (auto 3 s) | `color.success`, `text.sm` | « Tâches à jour » (après sync) | aucune (auto-dismiss) | slide-in bas 250 ms |
| **offline** | Badge top-bar « Hors-ligne » (02 §7 l.473 : « Bannière fine ») + liste locale | `color.neutral.400`, `icon.size=16` | « Hors-ligne — données locales » | CTA Kanban **fonctionnel** (ouvre board locale, AD-7) | fade 150 ms |
| **killed** (G-M2) | Skeleton + bandeau « Reconnexion… » | `color.neutral.400`, monochrome logo (§9.1) | « Reconnexion… » | CTA Kanban reste actif (relance depuis miroir local) ; pas de retry explicite (relance = auto-resync) | entrée : statique (pas d'animation, §2.6 r.4) ; sortie : auto-resync achevé → re-query → loading/success (fade 250 ms) |
*Source : AD-13 l. (02 §7 l.462–493 ; offline « Bannière fine » l.473) ; 05 §3.7 l.1244–1309 (matrice AD-13 : ListItem error/offline) ; l.1290–1301 (killed) ; S6 l.174–187.*

### §4(b) États sémantiques §6.1 — statuts de tâche (01 §4.1 l.165)

| Statut sémantique | Badge coloré | Icone (Lucide 16 px) | Texte Badge | SSoT |
|---|---|---|---|---|
| **todo** | `color.info` | `Circle` | « À faire » | 01 §4.1 l.165 ; 05 §3.3 l.531 |
| **doing** | `color.warning` | `Play` | « En cours » | idem |
| **blocked** | `color.danger` | `OctagonAlert` | « Bloqué » | idem |
| **done** | `color.success` | `Check` | « Terminé » | idem |
| **cancelled** | `color.neutral.400` | `X` | « Annulé » | idem |

*États sémantiques §6.1 (ui-libraries l.189–202) applicables ou N/A :*

| État §6.1 | Applicabilité sur cet écran | Texte exact / composant / CTA | SSoT |
|---|---|---|---|
| **en-cours** | N/A (raison : la liste est une **lecture locale** (AD-7) — pas d'opération à résultats partiels (pas de streaming, pas de QCM, pas d'import) ; l'attente = S6 `loading` §4(a) ; le statut de tâche `doing` = donnée (badge §4(b)), pas un état d'opération) | — | ui-libraries §6.1 l.197 ; AD-7 |
| **terminé** | N/A (raison : la liste n'exécute jamais d'opération ; tout objet terminal = S6 `success` Toast §4(a) ; le statut `done` d'une tâche = donnée (badge §4(b)), pas un état d'écran) | — | ui-libraries §6.1 l.198 |
| **échec** | N/A (raison : pas d'opération non retryable en place sur cet écran — toute erreur de lecture/chargement = S6 `error` (retryable in place, §4(a)) ; le domaine n'a pas de statut `failed` (01 §4.1 l.165 : statuts `todo, doing, blocked, done, cancelled`) ; le statut `cancelled` = décision utilisateur (badge §4(b)) ≠ échec) | — | ui-libraries §6.1 l.199 ; 01 §4.1 l.165 |
| **succès** | ✓ = S6 `success` §4(a) (transitoire, Toast 3 s auto-dismiss) | — | ui-libraries §6.1 l.200 ; S6 l.183 |
| **erreur** | ✓ = S6 `error` §4(a) (transitoire, retryable in place : Alert destructive + « Réessayer ») | — | ui-libraries §6.1 l.201 ; S6 l.181 |
| **404 / not-found** | ✓ = §4(c) ci-dessous (route `/tasks` et deep link `/tasks/:id` routés → règle §6.1 l.202 : logo AURORA coloré sans fond centré + message court + CTA « Retour à l'accueil ») | — | ui-libraries §6.1 l.202 ; §9.1 l.387 |

> Échec global = état **error** §4(a) (non lié à un statut de tâche). N/A pour « échec » de tâche individuelle (pas de statut `failed` dans le domaine, 01 §4.1 l.165).

### §4(c) 404 / not-found (route `/tasks/:id` invalide)

| Élément | Valeur | Tokens | Texte exact | CTA | SSoT |
|---|---|---|---|---|---|
| Logo centré | **Logo coloré, sans fond, centré** (S9 l.349–369, §9.1 l.387) | `color.brand.*` (coloré), `spacing.xl` | — | — | ui-libraries §6.1 l.202 ; §9.1 l.387 |
| Message court | texte sm centré | `color.neutral.700/300`, `text.sm` | « Tâche introuvable. Elle a peut-être été supprimée ou le lien est invalide. » | — | OQ-9 (kanban.md §14) : formulation non figée → **OQ-4** ici |
| CTA primaire | Button primary | `color.brand.primary`, `touch.target=48` | « Retour à l'accueil » | navigation `/` (home) | §6.1 l.202 |
| CTA secondaire (optionnel) | Button ghost | `color.neutral.700/300`, `touch.target=44` | « Consulter l'écran parent » | navigation retour (top of stack) | §6.1 l.202 |

*Portée 404 : route `/tasks` (tab 2 BottomNav) et deep link `/tasks/:id` (BottomSheet overlay S-24). Un deep link invalide (id inconnu / tâche supprimée / feature désactivée) rend l'écran 404 ci-dessus — **jamais** un crash ni un 404 brut (feature-registry S6 ; ssootCode not-found/index.tsx : deep link vers feature désactivée = `data-state=feature-disabled` + CTA re-enable, même enveloppe 404).*

### §4(d) Killed (tous flux serveur, 05 §3.7 l.1290–1301)

| Élément | Valeur | Tokens | Texte exact | SSoT |
|---|---|---|---|---|
| Bandeau top | Skeleton + logo **monochrome** (§9.1 l.383) | `color.neutral.400` skeleton, monochrome | « Reconnexion… » | 02 §7 l.481–488 (killed G-M2) ; S9 §9.1 l.383 |
| Liste | Skeleton ListItem (lecture miroir local, relance G-M2) | `color.neutral.400` | — | 02 §7 l.481–488 ; 05 §3.7 l.1290–1301 |
| CTA Kanban | Reste actif (board locale, AD-7) | `color.brand.primary` | « Ouvrir le Kanban » | AD-7 ; WDS 05.3 |

---

## §5 Micro-interactions (table GPU-only, 150–250 ms, smooth)

| Élément | Action → Feedback | Durée | GPU-only (transform+opacity) | smooth | reduced-motion=statique | SSoT |
|---|---|---|---|---|---|---|
| Liste plate | Apparition (fade + translateY 8→0) | 200 ms `anim.normal` | `transform: translateY`, `opacity` (S5 l.169) | ease-out | statique (pas d'anim, S5) | polish.tsx `PAGE_TRANSITION` ; 05 §2.6 l.310 |
| Ligne tâche (tap) | Press feedback (scale 0.98, 150 ms) | 150 ms `anim.fast` | `transform: scale` | linear | statique | 05 §2.6 l.314 ; S5 |
| BottomSheet détail | Slide-up (translateY 100 %→0, 250 ms) | 250 ms `anim.normal` | `transform: translateY` | ease-out, pas bouncy (S3 l.143) | statique (S5) | 05 §2.6 ; WDS 05.3 §Interactions |
| Toast | Slide-in bas (translateY + opacity, 250 ms) | 250 ms | `transform: translateY`, `opacity` | ease-out | statique | S6 l.183 ; 05 §2.6 |
| CTA Kanban | Press feedback (scale 0.98, 150 ms) + transition page 200 ms | 150+200 ms | `transform: scale` + fade | ease-out | statique | polish.tsx ; 05 §2.6 |
| Skeleton | Pulse (opacity 0.6→1, 1.2 s) | 1200 ms loop | `opacity` | ease-in-out | **pas de pulse, statique** (S5 ; 05 §2.6 r.2) | 05 §2.6 l.343 ; S5 |

> **Règle 1 (05 §2.6)** : les données ne s'animent jamais (pas de réordonnancement animé de la liste au tri). **Règle 4** : aucune animation ne bloque l'input. **Mobile** : pas de layout animation (S5 l.169).

---

## §6 Modals / BottomSheets

| Élément | Type | Déclencheur | Contenu | Fermeture | SSoT |
|---|---|---|---|---|---|
| BottomSheet détail tâche | BottomSheet (05 §3.5, S1 l.13–14) | Tap ligne tâche | Résumé tâche + actions (statut, priorité, sous-tâches) = `/tasks/:id` (S-24) | Tap hors zone / swipe down / bouton retour | WDS 05.3 §Interactions ; 02 §6.1 l.390 ; S1 l.13 |
| Menu filtre | Menu (shadcn) | Tap icône menu TopBar | Filtres : date / priorité / statut (segmented) | Tap item / tap hors | WDS 05.3 OQ-1 ; 05 §3.2 ; S1 |
| (pas de modal plein-écran ici) | — | — | — | — | — |

> Le détail s'ouvre **par-dessus le tab courant** (règle detail-over-tab, router.tsx l.107–108 : detail = push sur tab courant, IonModal/IonSlides) ; non `ion-item`/`ion-datetime` (S3 interdit).

---

## §7 Formulaires

| Champ | Composant | Validation | SSoT |
|---|---|---|---|
| (aucun formulaire inline dans la liste) | — | — | — |

> L'écran liste est **lecture-seule** pour les champs. Toute édition (titre, date, priorité, statut, sous-tâches) se fait dans le **BottomSheet détail** (§6) ou l'écran `/tasks/:id` (S-24), pas dans la liste. `ion-item` / `ion-datetime` interdits (S3) : les formulaires du détail utilisent shadcn Input/Select (S1). Capture rapide (si présente) = champ texte unique shadcn Input → création via `task.create` (catalog L19, agent FULL).

---

## §8 Pagination / Tri / Filtres

| Règle | Paramètre | Valeur | SSoT |
|---|---|---|---|
| **Tri par défaut** | priorité (desc) | tâche nocturne / priorité haute d'abord | WDS 05.3 OQ-3 close B |
| **Tri alternatif** | date / progression / nom | via menu filtre (SegmentedControl) | 05 §3.4 l.711–723 ; WDS 05.3 OQ-1 |
| **Filtres** | date / priorité / statut | SegmentedControl multi-select, persistant par session | WDS 05.3 OQ-1 ; 05 §3.4 |
| **Pagination** | shadcn Pagination (S8 : <20 = Table/scroll, 20–100 = +pagination, >100 = AG Grid) | Liste locale : scroll infini (react-virtuoso fallback, S8 l.304–307, OQ-9) ; pas d'AG Grid (liste plate, non dense) | ui-libraries S8 ; WDS 05.3 |
| **Paging Jour/Semaine/Mois** | SegmentedControl + prev/aujourd'hui/suiv. | **N/A** ici (c'est le Pager du Calendrier/Gantt, 05 §3.4 l.737–749) ; la liste plate est par défaut « toutes tâches », option filtre date = jour/semaine/mois si actif | 05 §3.4 l.737 |

> Les tâches sont un **store local** (AD-7) : pas de chargement serveur par page ; la « pagination » est un virtual scroll si le volume > 100 lignes (S8). Le `taskView` (list/kanban/timeline/gantt/calendar, 02 §3.3 l.143–170) est persisté par tab ; cet écran = `taskView: 'list'`.

---

## §9 Transitions entre écrans

| Transition | Direction | Durée / curve | GPU-only | SSoT |
|---|---|---|---|---|
| Liste → Kanban global (CTA) | `/tasks` → `/tasks` (tab Kanban, S-05) | 200 ms fade + y (PAGE_TRANSITION) | transform+opacity | polish.tsx ; WDS 05.3 OQ-2 ; 05 §2.6 |
| Liste → Détail (BottomSheet) | overlay sur tab courant | 250 ms slide-up | transform | WDS 05.3 ; polish.tsx REVEAL_TRANSITION |
| Retour Détail → Liste | close BottomSheet | 200 ms fade | transform | idem |
| Home → Tâches (tab 2 BottomNav) | `/` → `/tasks` | 200 ms fade | transform | 02 §6.1 ; polish.tsx |

> Transitions = données jamais animées (règle 1, 05 §2.6) ; reduced-motion = statique (règle 2). Pas de transition bouncy (S3 l.143). La transition liste↔Kanban conserve le même tab (taskView change, pas de push route, 02 §3.3).

---

## §10 Thèmes (10 + 3 presets, par couche — AD-17)

| Couche | Comportement par thème | Exemple (non figé par thème, règle 05 §5.2) | SSoT |
|---|---|---|---|
| L1 Neutral (fond/texte) | `neutral.light #FFFFFF` / `neutral.dark #121212` + texte inverse | fond liste + texte titres | 05 §5.1/§5.2 ; AD-17 |
| L2 Expressive (brand) | Couleur de marque par thème (aurora/lagoon/…) appliquée au **CTA Kanban** et aux accents du BottomNav tab actif | CTA « Ouvrir le Kanban » = `color.brand.primary` du thème courant | 05 §5.2 (per-layer, jamais per-theme value) |
| L3 Override local | `--brand-*` override utilisateur sur le CTA | CTA perso si user a personnalisé | 05 §5.2 |
| **Règle bloquante 05 §5.1** | Les thèmes **ne re-définissent jamais** `success/warning/danger/info` | Les **Badges statut** (§4(b)) restent les couleurs sémantiques fixes, quel que soit le thème | 05 §5.1 |
| Presets | `slate` / `nocturne` / `high-contrast` | High-Contrast : targets 56 px, logo monochrome (§9.1 l.384) | 05 §5.2 ; §9.1 |

> AD-17 (ui-libraries) : tokens uniquement, **aucune** valeur couleur/espacement brute dans l'écran. Le thème est une peau : seul L1/L2/L3 bouge ; les couleurs sémantiques (badges statut) et les états (error/offline/killed) sont figés.

---

## §11 Accessibilité (WCAG AA — 05 §6.3)

| Règle | Valeur | SSoT |
|---|---|---|
| Cibles tactiles | ≥ 44 px (56 px High Contrast) sur chaque ligne tâche, CTA Kanban, icône menu, tab BottomNav | 05 §6.3 |
| `aria-label` | Toute icône-button (menu filtre, icônes statut) a `aria-label` textuel | 05 §6.3 |
| `letter-spacing` | 0 sur tous les corps (pas de tracking positif) | 05 §6.3 |
| Focus visible | Anneau focus visible sur CTA Kanban, ligne tâche (focus trap dans BottomSheet) | 05 §6.3 |
| Contraste | Ratios AA (4.5:1 texte, 3:1 UI) sur badges statut et CTA | 05 §6.3 |
| reduced-motion | Toutes animations §5/§9 → statiques ; Skeleton = pas de pulse | S5 ; 05 §2.6 r.2 |
| Ordre de lecture | Ligne tâche = titre (h/strong) puis Badge (texte), pas d'ordre visuel trompeur | 05 §6.3 |

---

## §12 Offline (classe offline = master-feature-catalog)

| Aspect | Valeur | SSoT |
|---|---|---|
| Classe offline | `productivity.tasks` = **offline-capable** (catalog L19 : "offline-capable; core") | master-feature-catalog L19 |
| Miroir local | PowerSync/SQLite : la liste plate est une **lecture 100 % locale** (AD-7) ; mutation = `LocalCommandRepository.apply('productivity', completeTask(id))` en queue upsync | 02 §7 ; docs/productivity/overview #5/#16 |
| **Ce qui vit sur le miroir local (AD-7/AD-12)** | (1) Lecture de la liste : la source de vérité = le store local, l'UI lit d'abord le miroir et **jamais** le réseau au mount (AD-7). (2) Mutations locales (statut/priorité/sous-tâches) : single-writer AD-7, `completeTask` = écriture locale → queue upsync (02 §7 l.648). (3) Kanban (CTA) : le board local fonctionne — le drag = une écriture **locale** (05 §4.3.3 : « le Kanban fonctionne… »). (4) La **relance G-M2 (killed)** part du miroir : relaunch cold = données du mirror affichées, jamais d'écran blanc ni de reset (05 §3.7 colonne killed ; ui-libraries S6 n°186). (5) Agent : AD-12 = kernel **side serveur** (F-09) — l'app ne contient aucun moteur agent ; côté miroir local, seule l'UI d'état d'attente vit (AgentRunState) ; ce qui est persisté localement = les commandes émises (AD-9 : le kernel n'écrit jamais la table, il émet l'événement que Productivity applique) | 02 l.73/AD-12 (ARCHITECTURE-SPINE l.125) ; 05 §4.3.3 ; 02 §7 (killed) ; ui-libraries §6 n°186 |
| Dégradation AD-1 | Si le flux de l'agent (capture par voix/chat) est offline, **AD-1** = saisie manuelle (champ texte) ; la liste elle-même n'est jamais dégradée. Préci SSoT : la ligne catalog qui dit littéralement « degradation: manual entry (AD-1) » est `learning.import` (L34) ; L19 (`productivity.tasks`) ne fige **pas** de mode de dégradation de sa capture → **OQ-9** §14. Le pattern de dégradation (AD-1 : activation optionnelle absente = fallback manuel) reste la SSoT de référence par analogie | master-feature-catalog L34 (AD-1 manual entry) ; catalog L19 agent FULL ; 02 §7 (« feature optionnelle absente = error doux » l.474) |
| Ce qui meurt (killed) | Le **sync upsync** (mutations) + le scan/capture agent ; la liste locale + CTA Kanban (board locale) restent vivants (05 §4.3.3 l.1605–1612 : "le Kanban fonctionne… seul le scan est désactivé") | 05 §4.3.3 l.1605 ; AD-1 ; G-M2 |
| État offline affiché | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) + CTA Kanban fonctionnel | §4(a) ; 05 §3.7 |

> L'écran liste est **premier état offline** (AD-7) : on lit et on navigue sans réseau ; seules les mutations en attente d'upsync et la capture par agent meurent.

---

## §13 Occurrences du logo (S9, versions exactes)

| Occurrence | Version du logo (S9 l.349–369) | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| TopBar « Tâches » (état normal) | **Coloré, sans fond** (default in-app) | Signe de vie de marque, calme ; le coloré sans fond est l'état par défaut applicatif | §9 l.349–369 ; §9.1 l.382 (matrix : in-app default = coloré) |
| État **killed** (bandeau) | **Monochrome** (grayscale métallique #131B22→#B9BABC) | Le monochrome = état dégradé/signal faible, ne pas alerter en couleur ; cohérence avec l'indisponibilité | §9.1 l.383 (killed = monochrome) |
| État **404** | **Coloré, centré** | Le 404 est le **seul** état mandant le logo coloré centré (reconfort + rebranding) | §9.1 l.387 ; ui-libraries §6.1 l.202 |
| Presets **Nocturne / High-Contrast** | **Monochrome** | Ces presets n'exposent pas le logo coloré (contraste/restriction) | §9.1 l.384 |
| **AgentThinkingLoader** (N/A ici) | Monochrome animé (§9.3, l'unique exception animée) | Ne s'affiche pas sur cet écran (pas d'agent thinking sur la liste) ; cité pour exhaustivité S9 | §9.3 l.420–487 |

> **Interdit (S9 l.390–392)** : icône applicative full dans l'app ; jamais de logo redessiné/re-coulé/dupliqué dans `src/` ; watermark 8 % = application unique (pas sur cet écran). Aucune occurrence ad hoc.

---

## §14 Questions ouvertes (OQ)

- **OQ-1** — Route du CTA Kanban : le CTA « Ouvrir le Kanban » mène-t-il au tab `/tasks` (taskView→kanban, même route) ou à une route Kanban distincte ? WDS 05.3 dit "board Kanban global (S-05)" mais le SSoT catalogue du tab Kanban vs route `/tasks` avec `taskView=kanban` n'est pas figé. → à trancher (cf. OQ-1 kanban.md : `/projects` vs `/tasks`).
- **OQ-2** — Le composant « ListItem tâche » (titre + Badge statut/priorité, 1 colonne) **n'est pas dans `packages/ui`** : faut-il le créer (`TaskRow` / `TaskListItem`) ou réutiliser `Card` ? S3 interdit `ion-list` data. → à trancher (cf. OQ-3 kanban.md : KanbanColumn/Board pas dans packages/ui).
- **OQ-3** — Capture rapide dans la liste : WDS 05.3 §Design n'implique pas explicitement un champ de capture inline ; l'empty-state propose-t-il un CTA de capture (`task.create`) ? Si oui, quel composant (shadcn Input plein-écran vs BottomSheet) ? → à trancher.
- **OQ-4** — Formulation exacte du message 404 (ex. « Tâche introuvable… ») et libellé du Toast « Tâches à jour » (success) ne sont pas figés par SSoT (cf. OQ-9/OQ-10 kanban.md). → à trancher.
- **OQ-5** — Volume typique de la liste : <20 (scroll natif) vs 20–100 (shadcn Pagination) vs >100 (AG Grid / react-virtuoso fallback) ? S8 donne l'arbre mais pas le volume cible ; le choix virtual-scroll (react-virtuoso, OQ-9 ui-libraries) vs Pagination à trancher selon le volume réel.
- **OQ-6** — Persistance de `taskView` par tab (02 §3.3 l.143–170) : le retour sur le tab Tâches rétablit-il le `taskView` précédent (list) ou force-t-il toujours la liste ? → à trancher.
- **OQ-7** — Filtre par défaut « priorité » (OQ-3 WDS close B) : le filtre par défaut est-il **appliqué** (priorité desc visible) ou **disponible mais inactif** au chargement ? L'impact sur l'ordre initial de la liste à trancher.
- **OQ-8** — CTA secondaire optionnel du 404 (§4(c) : « Consulter l'écran parent », SSoT ui-libraries §6.1 l.202) : son libellé exact et sa cible (retour top-of-stack vs bibliothèque / parent du deep link) ne sont pas figés par SSoT → à trancher (le CTA primaire « Retour à l'accueil » = figé §6.1 l.202).
- **OQ-9** — Dégradation AD-1 de la capture de `productivity.tasks` (§12) : le SSoT ne la fige pas. Master-feature-catalog L19 (`productivity.tasks`) dit seulement « agent: task.create/update FULL ; offline-capable ; core » — la ligne qui spécifie littéralement « degradation: manual entry (AD-1) » est `learning.import` (L34), pas L19. Deux SSoT en conflit possibles : (a) AD-1 = fallback saisie manuelle appliqué par analogie à tasks (pattern générique AD-1, 02 §7 « feature optionnelle absente = error doux ») ; (b) capture de tasks = FULL (agent task.create toujours dispo) donc **pas** de dégradation manuelle, seuls le scan/upsync meurent (05 §4.3.3 l.1605). → à trancher ; §12 s'appuie sur (a) par prudence.
