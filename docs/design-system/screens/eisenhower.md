# Écran — Matrice d'Eisenhower (`eisenhower`)

Module : Productivité · Route : vue quadrants (sous `/tasks`, additif G-L5, _inventory #16) · Statut : **additif** · SSoT écran : `docs/productivity/eisenhower.md` (wave 2, DESIGNED_NOT_IMPLEMENTED) + ADR §2.3 · Catalogue SSoT : 05 §3.3/§3.4/§3.7/§4.1/§4.5 + ui-libraries S1/S3/S5/S6/S6.1/S9 + master-feature-catalog L20 + ARCHITECTURE-SPINE AD-1/AD-7/AD-8/AD-12/AD-14/AD-15/AD-17

> **Note de scope** : la matrice n'existe dans le SSoT qu'à l'ADR §2.3 (« Priorisation assistée selon échéance, impact, effort, dépendances, importance, urgence et temps disponible ») — aucun pack 05 ne la détaille (G-DOC-05, eisenhower.md l. 11-15) ; la vue quadrants est une **proposition d'écran additif** (G-L5), à ratifier par les équipes Productivité + Design System avant le cut wave 2 (eisenhower.md l. 13-15) — c'est l'**OQ-1** du présent doc (registre _inventory OQ-16). Les quadrants sont **calculés, jamais stockés** (eisenhower.md §3 : pas de colonne `urgency` dans le schéma).

---

## §1 Psychologie du designer

| Dimension | Valeur |
|---|---|
| Objectif utilisateur | Séparer le **pressant** (pression temporelle) de l'**important** (contribution aux objectifs) pour agir sur la bonne chose maintenant : Q1 = faire, Q2 = planifier, Q3 = minimiser, Q4 = reporter (eisenhower.md §1 l. 17-22). |
| Contexte (appareil/moment/réseau) | Mobile, **réseau indifférent** : la lecture est locale (AD-7), la matrice est **entièrement fonctionnelle hors-ligne** (eisenhower.md §4 l. 63-65, §10 l. 134) ; les suggestions d'agent dégradent en suggestions locales par règles (AD-1). |
| Fréquence | Chaque cycle de priorisation : la matrice **complète** le tri de la liste/Kanban, elle ne les remplace pas ; re-évaluation à chaque changement de contexte (eisenhower.md §2 l. 36-39). |
| État émotionnel cible | **Direction & clarté** — « que dois-je faire d'abord ? » résolu par la lecture Q1 ; les tâches bloquantes/critiques sont **détectées**, pas subies (eisenhower.md §2 l. 33-35). |
| Erreur la plus probable | Traiter une tâche **pressante mais non importante** (Q3) comme prioritaire au détriment de Q2 (le « progrès critique » d'Home) ; ou confondre urgence **dérivée** (due_at dépassé/aujourd'hui/48h + `status=blocked`) avec un choix manuel — d'où l'override `Task.priority` (eisenhower.md §6 l. 96-98 ; ADR §2.3). |
| Ce que l'écran RÉSOUT | La question « qu'est-ce qui compte **maintenant** ? » en classant chaque tâche dans 1 des 4 quadrants et en exposant le Q1 (« Priorité principale » AD-14 d'Home = le 1er item Q1, 05 §4.1 l. 1375) ; les recommandations d'agent sont **toujours expliquées** (signaux utilisés, ADR §2.3 « Explication par l'agent »). |
| Invariant | AD-14 : le Q1 = « Priorité principale » du Home (fix, jamais empilé) ; les quadrants **n'ajoutent pas** de statut de tâche — le cycle de vie reste `todo/doing/blocked/done/cancelled` (01 §4.1 l. 165), la matrice = un **lens** (§1 l. 20-22). |

---

## §2 Zones de l'écran

| Zone | Contenu | SSoT |
|---|---|---|
| TopBar | Titre « Matrice » + icône `more` (Menu : tri / filtre par projet) | 05 §3.2 TopBar l. 659-668 (max 2 actions → `Menu`) |
| Grille 2×2 | 4 zones Q1 DO (haut-gauche) / Q2 PLAN (haut-droite) / Q3 MINIZE (bas-gauche) / Q4 DEFER (bas-droite) ; chaque zone = titre + `ListItem` compactes (min 44 px) | eisenhower.md §4 l. 58-60 (« 4-quadrant grid, 44px items ») ; 05 §3.3 ListItem l. 513 |
| Bandeau d'agent | CTA « Réviser mes priorités » → BottomSheet de suggestion (explication des signaux) | eisenhower.md §4 l. 70-73 ; 05 §3.5 BottomSheet l. 787 |
| BottomNav | 5ᵉ tab = `/agent` (entrée agent, WDS 05.4 OQ-4 close option C) | 05 §3.4 BottomNav l. 670-691 |

> **Entrées (eisenhower.md §4 l. 55-56)** : project screen « Matrix » tab (proposé G-DOC-05) **OU** Home « Priorité principale » (AD-14, 05 §4.1 l. 1375). L'entrée par l'onglet projet est **OQ-2** du présent doc (le parent SSoT n'est pas tranché, cf. OQ-1 kanban.md pour la même question de route sur le Kanban global).

---

## §3 Éléments de l'écran (table 100 % de la zone)

| Élément | Composant DS 05 §3 | lib ui-libraries S1 | Tokens (AD-17) | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Titre « Matrice » | TopBar (05 §3.2 l. 659-668) | shadcn Text / IconButton | `text.xl`, `color.neutral.900/100`, `spacing.xl` | même mobile/desktop | 05 §3.2 |
| Icône `more` (Menu) | IconButton (05 §3.1 l. 394-398) + Menu (05 §3.5 l. 843-854) | shadcn IconButton + dropdown-menu | `icon.size=20`, `touch.target=44` (HC 56) | même | 05 §3.2 l. 665 (max 2 actions → Menu) |
| Zone Q1 (haut-gauche) | Card flat (05 §3.3 l. 498) : titre Q1 + `ListItem` compactes ; Q1 = le « Priorité principale » d'Home (AD-14) | shadcn Card + List (S1 l. 11-12) | `color.brand.primary` (accent Q1, 05 §4 l. 58-60 : theme tokens only), `surface`, radius `md` (≤ 8px, S3 l. 142), `row.min-height=56` | même (grille 2×2, jamais 3×3 — règle §12 « simple en surface », 05 §3.3 StatTile l. 578-586) | eisenhower.md §4 l. 58-60 ; 05 §4.1 l. 1375 |
| Zone Q2 (haut-droite) | Card flat : titre Q2 + `ListItem` compactes (tâches « planifier ») | idem Q1 | `color.brand.secondary` (accent Q2), `surface` | même | eisenhower.md §6 l. 108 ; 05 §4 l. 58-60 |
| Zone Q3 (bas-gauche) | Card flat : titre Q3 + `ListItem` compactes (minimiser / batch / déléguer) | idem Q1 | `color.warning` (accent Q3 — dégradant, pas sémantique critique : reste un **accent de zone**, la règle 05 §5.1 bloquante n'empêche pas un thème de re-couler l'accent, seulement de redéfinir `danger`), `surface` | même | eisenhower.md §6 l. 107 |
| Zone Q4 (bas-droite) | Card flat : titre Q4 + `ListItem` compactes (reporter / annuler candidat) | idem Q1 | `color.neutral.400` (accent Q4), `surface` | même | eisenhower.md §6 l. 108 |
| Ligne tâche dans zone | `ListItem` dense (05 §3.3 l. 513-529) : titre + `Badge` statut/priorité | shadcn List + ListItem custom (S3 l. 136 **interdit** `ion-list` data → OQ-3) | `row.min-height=56` (dense = 48 px **option** off par défaut, l. 518), `color.neutral.900/100` | même mobile/desktop | 05 §3.3 l. 513-529 ; **OQ** (le pattern WDS 05.3 « dense 48 px » n'est pas dans le SSoT — cf. OQ-3) |
| `Badge` statut (sur ligne) | `Badge` tonal (05 §3.3 l. 531-536 : fond `*-surface`, texte `sm` 500, radius `sm`) | shadcn `badge` (S1 l. 31) | `color.warning/danger/info/success` (sémantiques **fixes**, 05 §5.1 bloquante), `font.mono` (JetBrains Mono xs) | même | 05 §3.3 l. 531 ; 01 §4.1 l. 165 |
| Bandeau d'agent (CTA « Réviser mes priorités ») | `Button` secondary/ghost (05 §3.1 l. 374-386) + CTA secondaire sous le primaire si 2 actions (règle EmptyState l. 648-650) | shadcn `button` | `color.brand.primary` (si CTA crée l'action), `touch.target=48` (HC 56), radius `md` (8 px) | même | eisenhower.md §4 l. 70-73 ; ADR §2.3 |
| BottomNav 5 tabs | BottomNav (05 §3.4 l. 670-691) | shadcn Tabs / custom nav (S3 l. 137 interdit `ion-item`) | `color.neutral.900/100`, `icon.size=20`, `touch.target=44/56` | mobile-only ; desktop = side nav (05 §3.4) | WDS 05.4 OQ-4 close option C |

> **S3 (ui-libraries l. 133-143)** : `ion-list` data / `ion-item` / `ion-calendar` **interdits**. La grille 2×2 de zones est un **composant « QuadrantView » non encore dans `packages/ui`** (batterie shadcn + wrappers AD-10 seulement) → **OQ-3** §14 (à trancher : créer `QuadrantView` ou composer 4 `Card` shadcn + `List` directement dans l'écran, pattern OQ-3 kanban.md).

---

## §4 États de l'écran

### §4(a) Matrice 6 états S6 (AD-13) — élément asynchrone : grille de quadrants

| État | Composant | Tokens | Texte exact | CTA | Entrée/Sortie |
|---|---|---|---|---|---|
| **loading** | Skeleton (pulse opacity 0.6→1, 1.2 s, 05 §3.3 l. 590-603) + `SkeletonListItem` imitant les 4 zones (shape final, 05 §3.3 l. 593-597 ; pas de « bloc générique ») | `color.neutral.400`, `spacing.m` | (silencieux, pas de texte — le local est **court** : « le local-first rend le loading souvent court », 05 §3.3 l. 596-598 ; si > 300 ms, le contenu apparaît partiellement dessous, l. 598-600) | CTA « Réviser mes priorités » **actif** (lecture locale, AD-7) | entrée : fade 150 ms ; sortie : swap grille 250 ms |
| **empty** (par quadrant) | `EmptyState` **compacte** (05 §3.3 l. 643-655) par zone : icône domaine 48 px `text-muted` + titre 1 phrase + body max 2 lignes + **1 seul CTA** (crée ou cherche, l. 648-650) ; **jamais un quadrant vide mort** (eisenhower.md §4 l. 61) | `color.neutral.400`, `icon.size=48`, `text.sm` | Q1 : « Rien d'urgent et d'important — capture une idée ou planifie une tâche Q2 » ; Q2 : « Rien à planifier pour cette semaine » ; Q3 : « Rien à minimiser » ; Q4 : « Rien à reporter » | Q1 = CTA « Capturer / Planifier » (OQ-5 : libellé exact) ; Q2 = CTA « Planifier » (BottomSheet, OQ-5) ; Q3/Q4 = CTA secondaire « Passer en revue » (OQ-5) | fade 250 ms |
| **error** | `Callout` danger inline (05 §3.3 l. 606-616 : fond `danger-surface`, bordure 1 px `danger`, radius `md`) **dans** la zone en faute (la zone **reste**, AD-7 — pas un quadrants qui disparaît) | `color.danger`, `text.sm` | « Erreur de lecture du store local. Réessayer ? » | Button `Réessayer` (ghost, l. 610-612 : un Callout `danger` **doit** porter une action) + CTA « Réviser » toujours actif | fade 200 ms ; retry = re-lecture locale (AD-7, eisenhower.md §4 l. 62) |
| **success** | Toast (auto-dismiss 3 s, 05 §3.5 l. 823-841) | `color.success`, `text.sm` | « Priorités à jour » (après sync) — libellé exact = **OQ-6** | aucune (auto-dismiss) | slide-in bas 250 ms |
| **offline** | Badge top-bar « Hors-ligne » (ui-libraries S6 l. 184) + grille **locale identique** (05 §3.3 l. 510-511 : l'offline ne change JAMAIS le look) | `color.neutral.400`, `icon.size=16` | « Hors-ligne — données locales » | CTA « Réviser mes priorités » **fonctionnel** en offline (suggestions locales par règles, eisenhower.md §4 l. 63-65, §10 l. 134-135) | fade 150 ms |
| **killed** (G-M2) | Skeleton + bannière fine « Reconnexion… » (05 §3.7 l. 1290-1301 : relaunch cold **part du mirror**, jamais d'écran blanc ni de reset — AD-7) ; le logo **monochrome** dans la bannière killed = **OQ-7** (cf. OQ-8 kanban.md, décision globale) | `color.neutral.400` skeleton, monochrome (§9.1 l. 383) | « Reconnexion… » | CTA « Réviser » reste actif (re-dérive depuis le store local, eisenhower.md §4 l. 67, §10 l. 139) | entrée : instantané (pas d'animation, 05 §2.6 l. 340-343) ; sortie : fade 250 ms |

*Source : eisenhower.md §4 l. 58-67 + §10 ; 05 §3.7 l. 1258-1301 ; ui-libraries S6 l. 174-187 ; 05 §3.3 (Skeleton l. 590-603, EmptyState l. 643-655, Callout l. 606-616).*

### §4(b) États sémantiques §6.1 — tâches de la matrice

| État sémantique | Rendu sur cet écran | SSoT |
|---|---|---|
| **en-cours** | N/A — la matrice n'expose **aucun** flux mesurable avec résultat partiel (pas de streaming, pas d'import) ; la suggestion d'agent (wave 3) = un **job persisté** (AD-8) ou un appel kernel (`fn-agent-run`, eisenhower.md §5 l. 86-90) : quand ce job tourne, l'état = `loading` S6 du Bandeau d'agent (pas un `Progress` + label « en-cours ») ; le `AgentThinkingLoader` (§9.3) = l'état « l'agent réfléchit » si le flux d'agent est **visible** sur cet écran (suggestion acceptée → re-plan, eisenhower.md §4 l. 70-73) — OQ-4 : le loader n'apparaît que si l'agent est **déclenché** sur cet écran (non déclenché par défaut) | ui-libraries §6.1 l. 197 ; §9.3 l. 420-487 ; eisenhower.md §5 l. 86-90 |
| **terminé** | N/A — l'état « terminé » d'une tâche = sa **colonne Q** (la tâche `done` ne apparaît plus dans la matrice, elle est **hors** du lens) ; le `CheckCircle2` de l'objet terminé n'apparaît **que dans** le BottomSheet de détail tâche (`taches-detail` 05.5), pas dans la matrice | ui-libraries §6.1 l. 198 ; 01 §4.1 l. 165 |
| **échec** | N/A — l'échec **terminal non retryable in place** n'existe pas dans la matrice : une faute de store locale = `error` transitoire (réessayer sur place, §4a) ; une suggestion d'agent ratée = **la matrice reste** (la suggestion est un UI additif, pas le chemin critique, eisenhower.md §10 l. 136-137) ; le chemin alternatif = le réordonnancement **manuel** par drag (si OQ-3 = dnd) ou par `Task.priority` (override manuel, eisenhower.md §2 l. 26) | ui-libraries §6.1 l. 199 ; eisenhower.md §10 l. 136-137 |

### §4(c) 404 / not-found (route `/tasks?view=matrix` invalide / deep link vers feature désactivée)

| Élément | Valeur | Tokens | Texte exact | CTA | SSoT |
|---|---|---|---|---|---|
| Logo centré | **Logo coloré, sans fond, au centre** (ui-libraries §9.1 l. 387 ; §6.1 l. 202 : l'état 404 = l'unique état qui mandate le logo centré) | `color.brand.*` (coloré), `spacing.xl` | — | — | ui-libraries §6.1 l. 202 ; §9.1 l. 387 |
| Message court | texte sm centré | `color.neutral.700/300`, `text.sm` | « La matrice n'est pas disponible (fonction désactivée). » — libellé exact = **OQ-8** | — | ui-libraries §6.1 l. 202 ; `apps/mobile/src/pages/not-found/index.tsx` l. 19-21 (le fallback global = « {pathname} n'est pas disponible (fonction désactivée). ») |
| CTA primaire | Button primary | `color.brand.primary`, `touch.target=48` | « Retour à l'accueil » | navigation `/` (home) | ui-libraries §6.1 l. 202 ; not-found.tsx l. 20 |
| CTA secondaire (optionnel) | Button ghost (« optionnel » en SSoT, §6.1 l. 202) | `color.neutral.400`, `touch.target=48` | « Consulter la liste des tâches » (parent = `/tasks`) — libellé exact + inclusion = **OQ-11** | navigation `/tasks` (tab parent, cf. OQ-2) | ui-libraries §6.1 l. 202 |

### §4(d) Killed (tous flux serveur — 05 §3.7 l. 1290-1301 ; ui-libraries S6 l. 185)

La matrice = **lecture locale 100 %** (AD-7) : au kill système, le relaunch **part du mirror** (AD-7 : jamais d'écran blanc ni de reset, l. 1293-1295). Les quadrants re-dérivent du store local (eisenhower.md §4 l. 67, §10 l. 138-139 : « confirmed re-prioritizations are already persisted »).

| Élément | Valeur | Tokens | Texte exact | SSoT |
|---|---|---|---|---|
| Bandeau top | Skeleton + bannière fine « Reconnexion… » (le message = la bannière **DS**, jamais par composant, l. 1296) ; le logo **monochrome** dans la bannière = **OQ-7** (cf. OQ-8 kanban.md) | `color.neutral.400` skeleton, monochrome (§9.1 l. 383) | « Reconnexion… » | 05 §3.7 l. 1290-1301 ; §9.1 l. 383 |
| Zones Q1-Q4 | Skeleton `SkeletonListItem` (le contenu du mirror re-charge, l. 1292-1296) | `color.neutral.400` | — | 05 §3.7 l. 1290-1301 |
| CTA « Réviser mes priorités » | Reste **actif** (suggestions locales par règles, eisenhower.md §4 l. 63-65) — seul le **scan/suggestion d'agent serveur** est désactivé (§10 l. 134-135) | `color.brand.primary` | « Réviser mes priorités » | eisenhower.md §10 l. 134-135 ; 05 §3.7 l. 1290-1301 |

---

## §5 Micro-interactions (table GPU-only, 150–250 ms, smooth)

| Élément | Action → Feedback | Durée | GPU-only (transform+opacity) | smooth | reduced-motion=statique | SSoT |
|---|---|---|---|---|---|---|
| Grille de quadrants | Apparition (fade + translateY 8→0) | 200 ms `anim.normal` | `transform: translateY`, `opacity` (ui-libraries S5 l. 169) | ease-out | statique (pas d'anim, S5) | motion.tsx PAGE_TRANSITION @aurora/ui `PAGE_TRANSITION` ; 05 §2.6 l. 310 |
| Ligne tâche (tap) | Press feedback (scale 0.98, 150 ms) | 150 ms `anim.fast` | `transform: scale` | linear | statique | 05 §2.6 l. 314 ; S5 l. 169 |
| Zone Q1 (highlight au survol — desktop) | Pas de layout animation (mobile interdit S5 l. 169) ; uniquement `opacity` (le `hover` n'est pas un état mobile) | n/a (desktop) | `opacity` | ease-out | statique | S5 l. 169 ; 05 §2.6 l. 314 |
| BottomSheet de suggestion (CTA « Réviser ») | Slide-up (translateY 100 %→0, 250 ms) | 250 ms `anim.normal` | `transform: translateY` | ease-out, **pas bouncy** (S3 l. 143) | statique (S5) | 05 §2.6 ; WDS 05.3 §Interactions |
| Toast succès (« Priorités à jour ») | Slide-in bas (translateY + opacity, 250 ms) | 250 ms | `transform: translateY`, `opacity` | ease-out | statique | 05 §3.5 l. 823-841 ; S6 l. 183 |
| Skeleton | Pulse (opacity 0.6→1, 1.2 s loop) | 1200 ms loop | `opacity` | ease-in-out | **pas de pulse, statique** (05 §2.6 l. 340-343 ; S5) | 05 §3.3 l. 590-603 |
| Suggestion d'agent (si OQ-4 = visible sur l'écran) | `AgentThinkingLoader` (organisme organique, 3 blobs, GPU-only, pas de `layout` animation, 05 §2.6 l. 340 ; pas de filtre CPU-heavy S5 l. 169) ; le loader **n'est jamais** un 3ᵉ spinner/points (rejet §9.3 l. 422-424) | 200 ms `exiting` (collapse + fade quand la réponse commence à streamer, §9.3 l. 455-456) | `transform: scale/rotate` + `opacity` (S5 l. 169 ; §9.3 l. 427-428) | ease-out | statique (organisme figé au 1ᵉ mot, §9.3 l. 457-458) | ui-libraries §9.3 l. 420-487 |

> **Règle 1 (05 §2.6 l. 323-330)** : les données ne s'animent jamais (pas de réordonnancement animé de la liste au tri). **Règle 4** (l. 340-343) : aucune animation ne bloque l'input. **Mobile** : pas de layout animation (S5 l. 169).

---

## §6 Modals / BottomSheets

| Élément | Type | Déclencheur | Contenu | Fermeture | SSoT |
|---|---|---|---|---|---|
| BottomSheet de suggestion d'agent | BottomSheet (05 §3.5 l. 787-808, S1 l. 13-14) | Tap CTA « Réviser mes priorités » | List des suggestions (`Suggestion[]`, eisenhower.md §5 l. 79-82) : chaque item = titre tâche + signal utilisé (échéance / impact / effort / dépendance / importance / urgence / temps disponible, ADR §2.3) + CTA « Appliquer » (→ `TaskUpdateCommand` single-writer, eisenhower.md §5 l. 84-86) + explication du **pourquoi** (ADR §2.3 « Explication par l'agent ») | Tap hors zone / swipe down / bouton retour | eisenhower.md §4 l. 70-73 ; 05 §3.5 l. 787-808 |
| Menu (tri / filtre) | Menu (shadcn, 05 §3.5 l. 843-854) | Tap icône `more` TopBar | Max 6 items : tri par priorité (défaut), filtre par projet (si l'écran est ouvert depuis un projet, OQ-2) | Tap item / tap hors | 05 §3.5 l. 843-854 ; WDS 05.3 OQ-1 |
| (pas de modal plein-écran ici) | — | — | — | — | — |

> Le détail tâche s'ouvre **par-dessus le tab courant** (règle detail-over-tab, router.tsx l. 107-108 : le détail = push sur le tab courant, non une 2ᵉ route) — cf. `taches-detail` (S-24, WDS 05.5) ; non `ion-item` (S3 interdit, l. 137).

---

## §7 Formulaires

| Champ | Composant | Validation | SSoT |
|---|---|---|---|
| (aucun formulaire inline dans la matrice) | — | — | — |

> La matrice est **lecture-seule** pour les champs de tâche (titre, date, priorité, statut, sous-tâches). Toute édition se fait dans le **BottomSheet détail** (§6 → `taches-detail` S-24) ou le CTA « Réviser » (BottomSheet de suggestion d'agent, §6) — lequel **n'a** **pas** de formulaire : il applique des `TaskUpdateCommand` partielles single-writer (eisenhower.md §5 l. 84-86 ; 02 §4 : une commande partielle par tâche, pas d'écriture multi-tables). `ion-item` / `ion-datetime` **interdits** (S3 l. 137-138) : tout formulaire de tâche utilise shadcn Input/Select (S1 l. 14-17).

---

## §8 Pagination

| Règle | Paramètre | Valeur | SSoT |
|---|---|---|---|
| **Tri par défaut** | priorité (desc), Q1 d'abord | Q1 = le « Priorité principale » d'Home (AD-14, 05 §4.1 l. 1375) ; le reste Q2 → Q3 → Q4 | eisenhower.md §6 l. 107-108 ; 05 §4.1 l. 1375 |
| **Volume par quadrant** | shadcn Pagination (S8 : <20 = scroll natif / 20–100 = +Pagination / >100 = AG Grid) | La matrice = **4 quadrants** (pas une liste plate) ; le volume typique par quadrant est **faible** (tâches actives, pas archivées) → **scroll natif par quadrant** ; si un quadrant dépasse 100 lignes (cas multi-projets), **react-virtuoso** (fallback S8 l. 63, OQ-09 ui-libraries), **pas** AG Grid (la matrice = des cards/des lignes, pas une table dense — cf. OQ-4 kanban.md : AG Grid **interdit** pour un board qui n'est pas une table) | ui-libraries S8 l. 20-21, l. 63 ; OQ-4 kanban.md |
| **Paging Jour/Semaine/Mois** | SegmentedControl + prev/aujourd'hui/suiv. | **N/A** ici (le Pager = l'écran Calendrier, 05 §3.4 l. 737-749) ; la matrice n'a **pas** de navigation temporelle (le temps = le module calendrier/time-blocking, eisenhower.md §3 l. 50 : « not scheduling ») | 05 §3.4 l. 737 ; eisenhower.md §3 l. 50 |

> Les tâches sont un **store local** (AD-7) : pas de chargement serveur par page ; la « pagination » = un virtual scroll **par quadrant** si le volume > 100 (S8). Le `taskView` (list/kanban/timeline/gantt/calendar, 02 §3.3 l. 143-170) est persisté par tab ; cet écran = une **vue ajoutée** (additive G-L5) qui **ne** change **pas** le `taskView` (cf. OQ-2 du présent doc : est-ce une vue du tab `/tasks` ou un onglet du projet ?).

---

## §9 Transitions entre écrans

| Transition | Direction | Durée / curve | GPU-only | SSoT |
|---|---|---|---|---|
| Home → Matrice (« Priorité principale » Q1) | `/home` → `/tasks?view=matrix` (OQ-2) | 200 ms fade + y (PAGE_TRANSITION, motion.tsx PAGE_TRANSITION @aurora/ui) | transform+opacity | motion.tsx @aurora/ui ; 05 §2.6 l. 310 |
| Projet (Matrix tab) → Matrice | `/projects/:id` → matrice (OQ-2) | 200 ms fade + y | transform+opacity | eisenhower.md §4 l. 55-56 (G-DOC-05) |
| Matrice → Détail tâche (BottomSheet) | overlay sur le tab courant | 250 ms slide-up (S5 l. 169) | transform | 05 §3.5 l. 787-808 ; motion.tsx @aurora/ui REVEAL_TRANSITION l. 31 |
| Matrice → BottomSheet de suggestion | overlay sur le tab courant | 250 ms slide-up | transform | 05 §3.5 l. 787-808 |
| Retour Détail/Suggestion → Matrice | close BottomSheet | 200 ms fade | transform | idem |

> Transitions = données jamais animées (règle 1, 05 §2.6) ; reduced-motion = statique (règle 2, l. 330-334). Pas de transition bouncy (S3 l. 143). La transition Matrice ↔ Kanban conserve le **même** tab (le `taskView` change, pas de push route, 02 §3.3 l. 143-170 — OQ-2).

---

## §10 Thèmes (10 + 3 presets, par couche — AD-17)

| Couche | Comportement par thème | Exemple (non figé par thème, règle 05 §5.2) | SSoT |
|---|---|---|---|
| L1 Neutral (fond/texte) | `neutral.light #FFFFFF` / `neutral.dark #121212` + texte inverse | fond des 4 zones Card + texte titres | 05 §5.1/§5.2 ; AD-17 |
| L2 Expressive (brand) | Couleur de marque par thème (aurora/lagoon/…) appliquée aux **accents de zones** Q1/Q2/Q3/Q4 (§3 ci-dessus) et au CTA « Réviser » ; **jamais** aux `Badge` statuts (L1, sémantiques fixes) | Q1 = `color.brand.primary` du thème courant ; Q2 = `color.brand.secondary` | 05 §5.2 (per-layer, jamais per-theme value) |
| L3 Override local | `--brand-*` override utilisateur sur les accents de zones | Zone Q1 en couleur perso si user a personnalisé | 05 §5.2 |
| **Règle bloquante 05 §5.1** | Les thèmes **ne re-définissent jamais** `success/warning/danger/info` | Les **Badges statut** (§4b) restent les couleurs sémantiques fixes, quel que soit le thème ; le Q3 (accent `warning` de **zone**, pas sémantique critique) reste un accent L2, pas un danger L1 | 05 §5.1 ; AD-17 l. 159 (spine) |
| Presets | `slate` / `nocturne` / `high-contrast` | High-Contrast : targets 56 px, logo **monochrome** (§9.1 l. 384), les zones Q restent identiques en structure (ajustement, pas nouveau composant) | 05 §5.2 ; §9.1 |

> AD-17 (spine l. 159 ; ui-libraries) : tokens uniquement, **aucune** valeur couleur/espacement brute dans l'écran. Le thème est une peau : seul L1/L2/L3 bouge ; les couleurs sémantiques (Badges statut §4b) et les états (error/offline/killed) sont figés. La matrice **ne** définit **jamais** de valeur brute (eisenhower.md §4 l. 58-60 : « theme tokens only — 05 §5.1 theme/semantic rule : quadrant accents come from the active theme, success/warning/danger tokens stay semantic »).

---

## §11 Accessibilité (WCAG AA — 05 §6.3)

| Règle | Valeur | SSoT |
|---|---|---|
| Cibles tactiles | ≥ 44 px (56 px High Contrast) sur chaque ligne tâche, CTA « Réviser », icône `more`, tab BottomNav (eisenhower.md §4 l. 58-60 « 44px items ») | 05 §6.3 l. 3327-3335 |
| `aria-label` | Toute icône-button (`more`, icône de zone si présente) a un `aria-label` textuel (ex. `aria-label='Menu : trier / filtrer'`) | 05 §6.3 l. 3333 ; 05 §3.1 l. 394-398 |
| `letter-spacing` | 0 sur tous les corps (pas de tracking positif) | 05 §6.3 l. 3327-3335 |
| Focus visible | Anneau focus visible sur CTA « Réviser », ligne tâche, Menu (focus-trap dans le BottomSheet) | 05 §6.3 ; 05 §3.1 l. 382 (ring 2 px, HC = 3 px) |
| Contraste | Ratios AA (4.5:1 texte, 3:1 UI) sur Badges statut et CTA « Réviser » | 05 §6.3 |
| `aria-live` sur les quadrants | Le re-ordonnancement d'une tâche (après suggestion acceptée) = un événement `aria-live='polite'` (le quadrant change, l'annonce suit) | 05 §6.3 ; WCAG ; **OQ** (le pattern cité « OQ-49 kanban.md l. 148 » est factice — le registre OQ de kanban.md s'arrête à OQ-14, cf. OQ-10) |
| `role` sur les zones | Chaque zone Q = `role='region'` + `aria-label` (ex. `aria-label='Quadrant 1 : urgent et important'`) | 05 §6.3 |
| reduced-motion | Toutes animations §5/§9 → statiques ; Skeleton = pas de pulse | S5 ; 05 §2.6 l. 330-343 |
| Ordre de lecture | Ligne tâche = titre (h/strong) puis Badge (texte), pas d'ordre visuel trompeur | 05 §6.3 |

---

## §12 Offline (classe offline = master-feature-catalog)

| Aspect | Valeur | SSoT |
|---|---|---|
| Classe offline | `productivity.eisenhower` = **offline-capable** (catalog L20 : « DESIGNED_ONLY + NEEDS_DECISION (screen) » ; eisenhower.md §10 l. 134 : « matrix fully functional (local mirror) ») | master-feature-catalog L20 ; eisenhower.md §10 |
| Miroir local | PowerSync/SQLite : la matrice est une **lecture 100 % locale** (AD-7, `LocalQueryRepository` uniquement, eisenhower.md §5 l. 83-84) ; mutation = `LocalCommandRepository.apply('productivity', TaskUpdateCommand)` en queue upsync (single-writer, AD-7/F-03, eisenhower.md §5 l. 84-86) | eisenhower.md §5 l. 83-86 ; 02 §7 |
| Dégradation AD-1 | Si le flux de l'agent (suggestion server-side, AD-12, kernel `fn-agent-run`) est offline, **AD-1** (spine l. 35 : « optional capabilities must degrade gracefully when their provider is absent ») = les suggestions dégradent en **locales par règles** (`prioritizationSuggestion`, eisenhower.md §5 l. 79-82 : déterministe, unit-testable, pas de DOM) ; la matrice elle-même n'est **jamais** dégradée (lecture locale, AD-7) ; le scan d'impact lourd (AD-8, `fn-agent-run`) = **désactivé** en offline avec explicatif (eisenhower.md §10 l. 134-135 : « agent suggestions unavailable → rule-based local suggestions ») | master-feature-catalog L20 ; AD-1 (spine l. 31-35) ; eisenhower.md §10 l. 134-135 |
| Ce qui vit sur le miroir local (AD-7/AD-12) | **Vivant même en offline/killed** (AD-7 : UI lit le local d'abord, spine l. 81-85) : la matrice 100 % lue sur le miroir PowerSync/SQLite (eisenhower.md §5 l. 83-84 : `LocalQueryRepository` uniquement) ; les mutations `TaskUpdateCommand` appliquées **localement** (single-writer AD-7/F-03) + re-queue upsync au retour ; les re-priorisations **confirmées** déjà persistées (eisenhower.md §10 l. 138-139) ; le Q1 « Priorité principale » (AD-14) ; les suggestions locales par règles ; le relaunch après kill **part du mirror**, jamais d'écran blanc ni de reset (05 §3.7 l. 1290-1301). **Attention AD-12 (spine l. 125-129)** : l'agent kernel = **server-only** (contexte `agent/expert-skills` jamais mirroré, AD-3) — le miroir local ne contient **aucun** état d'agent : la dégradation AD-1 (règles locales) est donc le **seul** chemin agent en offline | AD-7 (spine l. 81-85) ; AD-12 (spine l. 125-129) ; AD-3 (spine l. 56-60) ; eisenhower.md §10 l. 134-139 ; 05 §3.7 l. 1290-1301 |
| Ce qui meurt (killed) | Le **scan d'impact lourd** (AD-8, `fn-agent-run`, eisenhower.md §5 l. 86-90) + le sync upsync (mutations en attente) + **tout état d'agent kernel (AD-12 : server-only, jamais sur le miroir)** ; la matrice locale + le CTA « Réviser » (suggestions locales) + le Q1 (AD-14) restent **vivants** (eisenhower.md §4 l. 67, §10 l. 138-139 : « confirmed re-prioritizations are already persisted ») | eisenhower.md §4 l. 67 ; §10 l. 138-139 ; 05 §3.7 l. 1290-1301 ; AD-7 |
| État offline affiché | Badge top-bar « Hors-ligne » (05 §3.7 l. 1258) + CTA « Réviser » **fonctionnel** (suggestions locales) | §4(a) ; 05 §3.7 l. 1258 |

> La matrice est **premier état offline** (AD-7) : on lit et on re-priorise sans réseau ; seules les mutations en attente d'upsync et le scan d'impact lourd (AD-8) meurent. Les `TaskUpdateCommand` confirmées **restent** (persistance locale, single-writer, eisenhower.md §10 l. 138-139).

---

## §13 Occurrences du logo (S9, versions exactes)

| Occurrence | Version du logo (S9 l. 349-369) | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| TopBar « Matrice » (état normal) | **Aucune occurrence de logo** (le SSoT ui-libraries S3 l. 141 **interdit** les décorations SVG ad hoc ; le §9 SSoT n'a pas de ligne « écran matrice » — le logo in-app mandaté (§9.1 l. 380) ne s'applique qu'aux surfaces SSoT : header global, empty states, onboarding, in-app splash, 404 §6.1 l. 202). Usage ad hoc **interdit** (S9 l. 390-392 : pas de recolor/duplication dans `src/`) | — | ui-libraries S3 l. 141 ; §9 l. 349-369 ; §9.1 l. 380 |
| État **killed** (bannière fine) | **Monochrome** (grayscale métallique #131B22→#B9BABC, §9.1 l. 383 : « Killed / disabled states = monochrome ») ; le choix **avec** logo dans la bannière = **OQ-7** (cf. OQ-8 kanban.md) | Le monochrome = état dégradé/signal faible, ne pas alerter en couleur ; cohérence avec l'indisponibilité | §9.1 l. 383 |
| État **404 / feature-disabled** (page entière) | **Coloré, centré** (§9.1 l. 387 : « 404 = COLORED without-background, CENTERED » — l'unique état qui mandate le logo centré, §6.1 l. 202) | Le 404 est un état **actif** (CTA primaire présent) = logo **coloré**, pas monochrome (interdit §9.1 l. 391 : « monochrome in a living empty state = FORBIDDEN ») | §9.1 l. 387 ; ui-libraries §6.1 l. 202 |
| Presets **Nocturne / High-Contrast** | **Monochrome** (§9.1 l. 384 : « Nocturne + High Contrast = monochrome » ; les 10 thèmes expressifs = coloré) | Ces presets n'exposent pas le logo coloré (contraste/restriction, §9.1 l. 384) | §9.1 l. 384 |
| **AgentThinkingLoader** (§9.3, si l'agent est **déclenché** sur cet écran — OQ-4) | **Monochrome animé** (l'unique exception animée, §9.3 l. 420-451) ; pas affiché par défaut (l'agent n'est pas déclenché au mount de la matrice) | « L'agent réfléchit » : calme en gris, la couleur revient à la réponse (fluidité, §9.1 l. 382) ; le marque reste **statique** au centre (S9 : le marque n'est **jamais** redessiné/animé lui-même, §9.3 l. 432-436) | §9.3 l. 420-487 ; §9.1 l. 382 |

> **Interdit (S9 l. 390-392)** : la version **complète** (fond coloré) **jamais** dans l'UI applicatif (§9 l. 357) ; jamais de logo **redessiné/re-coulé/dupliqué** dans `src/` (l. 352, l. 367) ; le watermark 8 % = application **unique** (l. 397-398, pas sur cet écran) ; le monochrome **n'animé jamais** en dehors de §9.3 (l. 403). Aucune occurrence ad hoc.

---

## §14 Questions ouvertes (OQ)

| # | Écran | Élément | Question | Options envisagées | Décideur | SSoT manquante |
|---|---|---|---|---|---|---|
| **OQ-1** | `eisenhower` | Ratification de l'écran additif (G-L5, _inventory OQ-16) | La vue quadrants est une **proposition** d'écran additif (G-L5, eisenhower.md l. 11-15, master-feature-catalog L20 « DESIGNED_ONLY + NEEDS_DECISION (screen) ») — le SSoT écran 05 §4 **ne la liste pas** (44 écrans SSoT, §4 l. 1316-1321 ; eisenhower = le 45ᵉ, additif). **À ratifier** par les équipes Productivité + Design System avant le cut wave 2 (eisenhower.md l. 13-15) | (a) Ratifier comme écran additif (G-L5, ajouter au décompte 44 SSoT → 45) (b) Garder la matrice comme une **vue** de `/tasks` (sans écran distinct, intégrée au `taskView`, 02 §3.3 l. 143-170) (c) Refuser (revoir la proposition G-L5) | Product / Design System / G-L5 owner | eisenhower.md l. 11-15 (G-DOC-05) ; _inventory OQ-16 ; master-feature-catalog L20 |
| **OQ-2** | `eisenhower` | Parent de la vue : onglet du projet **ou** vue du tab `/tasks` ? | eisenhower.md §4 l. 55-56 dit « project screen ‘Matrix’ tab (proposed G-DOC-05) **OR** Home ‘Priorité principale’ » ; le SSoT **ne tranche pas** le parent (cf. OQ-1 kanban.md : même question sur le Kanban global `/projects` vs `/tasks`) | (a) Onglet du projet (`/projects/:id`, vue « Matrix », G-DOC-05 l. 55) (b) Vue du tab `/tasks` (`taskView='matrix'`, additive, 02 §3.3 l. 143-170) (c) Les deux (2 entrées, 1 écran, deep link distinctes) | Product / 05 owner | eisenhower.md §4 l. 55-56 (G-DOC-05, non tranché) ; 02 §3.3 l. 143-170 ; OQ-1 kanban.md |
| **OQ-3** | `eisenhower` | Composant « QuadrantView » (4 zones Q1-Q4) : créer ou composer ? | La grille 2×2 de zones + `ListItem` compactes **n'est pas dans `packages/ui`** (batterie shadcn + wrappers AD-10 seulement ; S3 l. 136 **interdit** `ion-list` data) ; le composant `QuadrantView` n'existe pas (cf. OQ-3 kanban.md : `KanbanColumn`/`KanbanCard` = wrapper non autonome, à trancher par la DS team) | (a) Créer `QuadrantView` dans `packages/ui` (composant DS autonome, 4 zones + scroll par zone, SSoT 05 §3.3 Card/ListItem, à trancher par la DS team) (b) Composer 4 `Card` shadcn + `List` shadcn directement dans l'écran (pas de wrapper DS — le `QuadrantView` = une composition écran, pas un composant autonome) | Design System team / 05 owner | 05 §3.3 l. 498-529 (Card/ListItem) ; `packages/ui/src/components/ui/` (pas de `QuadrantView`) ; OQ-3 kanban.md |
| **OQ-4** | `eisenhower` | `AgentThinkingLoader` visible sur la matrice ? | L'état « l'agent réfléchit » (§9.3) n'apparaît que si l'agent est **déclenché** sur cet écran (suggestion acceptée → re-plan, eisenhower.md §4 l. 70-73) ; le SSoT ne dit **pas** si le trigger est **visible** sur la matrice (vs uniquement sur le chat `/agent`, 5ᵉ tab) | (a) Visible sur la matrice (le CTA « Réviser » déclenche le re-plan, l'`AgentThinkingLoader` s'affiche **dans** le BottomSheet de suggestion, pas sur la matrice elle-même) (b) Invisible sur la matrice (le re-plan = un job AD-8 en fond, le résultat = le BottomSheet mis à jour, pas de loader intermédiaire) | Design System team / Agent owner | eisenhower.md §4 l. 70-73 ; §5 l. 86-90 ; ui-libraries §9.3 l. 420-487 |
| **OQ-5** | `eisenhower` | Libellés exacts des CTA des `EmptyState` par quadrant (Q1/Q2/Q3/Q4) | Le SSoT dit « CTA ‘capture’ / ‘plan’ (never a dead quadrant) » (eisenhower.md §4 l. 61) mais **ne donne pas** les libellés exacts par quadrant (Q1 = « Capturer / Planifier » ? Q2 = « Planifier » ? Q3 = « Minimiser » ? Q4 = « Reporter » ?) | (a) Libellés à trancher par la DS team (pattern : verbe d'action, FR, ton calme, max 2 lignes body, 1 seul CTA primaire + 1 ghost max, 05 §3.3 l. 648-650) (b) SSoT à compléter (libellés CTA par quadrant) | Design System team / 05 owner | eisenhower.md §4 l. 61 (CTA, libellés non figés) ; 05 §3.3 l. 643-655 |
| **OQ-6** | `eisenhower` | Libellé exact du Toast succès (« Priorités à jour ») + du Callout error (« Erreur de lecture du store local. Réessayer ? ») | La matrice §4a fixe le **rendu** (Toast / Callout) mais les **libellés exacts** ne sont **pas dans le SSoT** (cf. OQ-10 kanban.md : même question sur le Toast succès du move) | (a) Libellés à trancher par la DS team (FR, pattern : phrase courte, ton calme, pas de jargon technique) (b) SSoT à compléter (libellés toast + callout) | Design System team | eisenhower.md §4 l. 62-63 (pas de libellés normatifs) ; 05 §3.5 l. 823-841 ; OQ-10 kanban.md |
| **OQ-7** | `eisenhower` | Bannière fine killed « Reconnexion… » : logo monochrome **dans** la bannière ou pas ? | La bannière killed (05 §3.7 l. 1290-1301 ; ui-libraries S6 l. 185) est un rendu DS **non spécifié** pour le logo ; la SSoT §9.1 l. 383 dit « Killed = monochrome » mais **n'assigne pas** de logo à la bannière (la bannière = un composant DS, pas un écran entier) — idem OQ-8 kanban.md (décision **globale** à tous les écrans) | (a) Bannière sans logo (texte « Reconnexion… » seul) (b) Logo monochrome `vs_monochrome_en_svg.svg` (stripped, §9.2 l. 407-418) dans la bannière | Design System team | 05 §3.7 l. 1290-1301 ; ui-libraries S6 l. 185 ; §9.1 l. 383 ; §9.2 ; OQ-8 kanban.md |
| **OQ-8** | `eisenhower` | Libellé exact du message court 404 / feature-disabled (état entier, §4c) | Le §4c mandate le logo AURORA **coloré au centre** (§9.1 l. 387) + un « message court » + le CTA primaire « Retour à l'accueil » (§6.1 l. 202) ; le **libellé exact** (ex. « La matrice n'est pas disponible (fonction désactivée). » vs « Écran indisponible ») **n'est pas dans le SSoT** (le fallback global not-found.tsx l. 19-21 = « {pathname} n'est pas disponible (fonction désactivée). » mais c'est le **fallback global**, pas le libellé spécifique à la matrice) | (a) Libellé à trancher par la DS team (pattern : phrase courte, ton calme, pas de « 404 » nu) (b) SSoT à compléter (message 404 spécifique matrice) | Design System team / 05 owner | ui-libraries §6.1 l. 202 ; §9.1 l. 387 ; `apps/mobile/src/pages/not-found/index.tsx` l. 19-21 ; OQ-9 kanban.md |
| **OQ-9** | `eisenhower` | Volume typique par quadrant (20-100 vs >100 → virtualisation) | Le SSoT **ne mentionne jamais** le volume par quadrant (eisenhower.md est muet sur le threshold de virtualisation) ; le volume réel (tâches actives, pas archivées) est **faible** en cas courant ; si un quadrant dépasse 100 lignes (multi-projets), **quelle** virtualisation : react-virtuoso (maintien du rendu `ListItem`, scroll par quadrant) ou **pas** de virtualisation (le SSoT à compléter) ? AG Grid = **interdit** (la matrice = des cards/des lignes, pas une table dense — cf. OQ-4 kanban.md) | (a) Pas de virtualisation (le cas courant < 100 par quadrant, scroll natif — le SSoT à compléter si > 100 devient un cas réel) (b) react-virtuoso par quadrant (maintien du rendu `ListItem`, le budget 60 fps est respecté) | Product / Data team | eisenhower.md (muet) ; ui-libraries S8 l. 63 (Virtuoso = fallback OQ-09) ; OQ-4 kanban.md |
| **OQ-10** | `eisenhower` | SSoT manquante (§3 « dense 48 px off par défaut » + §11 annonce `aria-live` du re-ordonnancement) | Deux lignes du doc reposaient sur une référence factice : (1) §3 ligne « Ligne tâche » — le pattern « WDS 05.3 pattern dense 48 px **option** off par défaut » **n'existe pas dans la SSoT** (05 §3.3 l. 513-529 fixe le `ListItem` dense ; le comportement « 48 px option off par défaut » n'est nulle part) ; (2) §11 `aria-live` — le « pattern OQ-49 kanban.md l. 148 » cité est **factice** (le registre OQ de kanban.md s'arrête à OQ-14 ; aucune annonce `aria-live` de re-ordonnancement dans le SSoT, 05 §6.3 n'impose pas de `aria-live` sur les quadrants) | (a) Libellé/règle « dense 48 px option » à trancher par la DS team (pattern : densité par zone, 05 §3.3 l. 513-529) (b) Annonce `aria-live` du changement de quadrant : à trancher par la DS team (05 §6.3 l. 3327-3335 ; pattern WCAG annonce de réordonnancement) — SSoT à compléter | Design System team | 05 §3.3 l. 513-529 (dense `ListItem`) ; 05 §6.3 l. 3327-3335 (aria-labels, pas de `aria-live` quadrants) ; WDS 05.3 (pattern muet sur la densité) |
| **OQ-11** | `eisenhower` | CTA secondaire 404 / feature-disabled (« Consulter l'écran parent », §6.1 l. 202) | La SSoT (§6.1 l. 202) liste le CTA secondaire comme **optionnel** ; le parent de la matrice n'est pas tranché (OQ-2 : onglet projet **ou** `/tasks`) → le libellé exact et l'inclusion du CTA secondaire de l'état 404 **ne sont pas dans le SSoT** (not-found.tsx ne porte que le CTA primaire « Retour à l'accueil ») | (a) Inclusion + libellé à trancher par la DS team (parent = `/tasks` si OQ-2 = (b), parent = `/projects/:id` si OQ-2 = (a)) (b) SSoT à compléter (CTA secondaire optionnel par écran) | Design System team / 05 owner | ui-libraries §6.1 l. 202 (CTA secondaire « optionnel ») ; `apps/mobile/src/pages/not-found/index.tsx` l. 20 ; OQ-2 |
| **OQ-12** | `eisenhower` | La bannière killed « Reconnexion… » (05 §3.7 l. 1290-1301) peut-elle exposer le logo monochrome, même en offline/killed ? | §12 (AD-7/AD-12) précise que l'état d'agent (contexte kernel) est **server-only** (AD-12 : jamais mirroré, AD-3) — aucun SSoT ne règle la présence du **logo** sur la bannière killed/offline (OQ-7 = le tranché global, cf. OQ-8 kanban.md) ; le §9.1 l. 383 dit « Killed = monochrome » sans assigner de logo à la bannière | (a) Bannière sans logo (texte « Reconnexion… » seul) (b) Logo monochrome `vs_monochrome_en_svg.svg` (stripped, §9.2 l. 407-418) | Design System team | 05 §3.7 l. 1290-1301 ; §9.1 l. 383 ; §9.2 ; OQ-7 ; OQ-8 kanban.md |
