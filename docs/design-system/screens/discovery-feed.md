# discovery-feed — Discovery feed (S-27)

Status: SPECIFIED (OQ: 7) · Module : Discovery · Route : `/discovery` · SSoT : WDS 03.2 (03.2-discovery-feed.md) + docs/discovery/overview.md + ADR §13 (13.1–13.9) + 05 §3.7 (matrice AD-13) + 05 §5.7.1 (Écran 5)

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur | Identifier les items de découverte typés (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY) liés à son `UserContext` et les actionner en 1 geste vers la sheet de découverte (S-40, WDS 03.3) | WDS 03.2 §4 (Desired Outcome) ; ADR §13.9 (discovery loop) |
| Contexte | Device mobile (Phase 1, Pixel 4a OQ-11) ; moment = tap du 7ᵉ bloc Home « Suggestions Coach » (WDS 03.1) ; réseau = **indifférent** (offline = état premier, AD-7 — le feed lit le mirror local `discovery_items`) | WDS 03.2 §3 (Mental State) ; 03-sync §4.2 ; discovery/overview §16 |
| Fréquence | Écran de support : l'utilisateur y revient à chaque suggestion Coach de Home ou à chaque demande de réduire un gap (gap-driven, evolution-driven, horizon-driven) — pas un écran de routine quotidienne | WDS 03.2 §2 (Entry Points) ; discovery/overview §4 (User flows) |
| État émotionnel cible | **Ciblé, pas submergé** — le feed n'est **jamais** un flux passif de liens (trigger-map trap 6 « Veille passive ») : chaque item porte une typologie et une proposition d'action ; le badge `⚠ uncertain` signale les items non confirmés sans alerter | WDS 03.2 §3 (Worry) ; ADR §13.2 ; discovery/overview §2 |
| Erreur la plus probable | L'utilisateur enchaîne les taps « Work on this » sans traiter le problème concret qui bloque son entrée professionnelle — fatigue d'alertes et de notifications (trigger-map §7 signal 4) ; le feed ne doit pas être un flux passif de liens | trigger-map §7 signal 4 ; WDS 03.2 §3 (Worry) |
| Ce que l'écran RÉSOUT | « Quels items de découverte sont typés et liés à mon profil, et quel est le ou les items qui correspondent à mon écart ? » — un seul CTA par item : « Work on this » qui mène à S-40, jamais une proposition libre de l'agent | WDS 03.2 §1 (Page Purpose) ; ADR §13.9 ; AD-14 (garde) |

## 2. Zones

Composition **fixe et ordonnée** (WDS 03.2 §6 — PROPOSITION SUGGEST, NON COUVERT par le corps gelé) :

- **header** : un `TopBar` (05 §3.4 l. 659-668) — titre « Découvertes pour toi » + sous-titre `xs` `text-muted` (`UserContext : Bénin · hydraulique · étudiant`, AD-15). **Pas de `back`** (l'écran est atteint via Home ou deep link, pas via push d'un autre écran Discovery — OQ-1). 1 `IconButton` optionnel : tri (menu).
- **content** : **liste verticale d'items typés** (pas un dashboard, pas un flux de liens — trigger-map trap 6) :
  - Chaque item = `ListItem` (05 §3.3 l. 519) avec **4 composants fixes** (WDS 03.2 §6 Note) :
    - **(a) Badge de typologie** — `Badge` (05 §3.3 l. 531-544) : FACT / TREND / ANALYSIS / SCENARIO / UNCERTAINTY (ADR §13.7) — visuel (icône + couleur par type, OQ-2 close WDS 03.2 option A)
    - **(b) Titre court** — 1 ligne max, ≤ 60 caractères, `sm` 600 `text-primary` (05 §3.3 l. 519)
    - **(c) Indicateur de source** — `Badge` tonal `text-secondary` : « ✓ N sources » (N ≥ 2 = confirmée) ou « ⚠ N source, uncertain » (N = 1 ou `ResearchProvider` dégrade, discovery/overview §8, ADR §13.2)
    - **(d) CTA fixe « Work on this »** — `Button` (05 §3.1 l. 365) — **un seul CTA par item** (invariant AD-14, WDS 03.2 §1) ; mène à S-40 (WDS 03.3) — **jamais** une proposition libre de l'agent
  - Les items de type **SCENARIO** (2030/2040/2050) portent un marqueur « horizon » — trajectoires, pas certitudes (ADR §13.7, discovery/overview §17 ; OQ-2 WDS : badge visuel)
  - Les items de type **UNCERTAINTY** portent le marqueur `⚠` distinctif (ADR §13.2)
  - Le tri est par **`UserContext`** (pertinence du profil : Bénin/hydraulique/budget étudiant — AD-15, ADR §13.1) — **pas par date** (OQ-1 WDS 03.2 close option A : anti-trap 6)
- **footer** : `BottomNav` 5 items figés (05 §3.4 l. 670-688) : `Accueil` / `Tâches` / `Apprendre` / `Progression` / `Coach` (OQ-3 WDS 03.2 close : 5ᵉ tab = `/agent` S-29, OQ-4 close option C 01.1)
- **surfaces flottantes** : `Toast` / `Snackbar` (file max 1, 05 §3.5 l. 823-836) ; **pas de `FAB`** au `/discovery` (le feed est un écran de lecture, pas de création — AD-14 : le FAB vit dans les écrans de création, 05 §3.1 l. 406-408 ; OQ-5)

## 3. Éléments / widgets

| Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|
| 1. Item typé (ligne) | `ListItem` (05 §3.3 l. 519) + `Badge` typo (a) + titre (b) + source (c) + CTA (d) | shadcn `list-item` (pas ion-list data — S3 interdit l. 136) | `text-primary` `sm` 600 titre ; `text-secondary` `xs` source ; `space.4` padding ; radius `md` item | desktop = 2 colonnes (item + extrait sheet) | 05 §3.3 l. 519 ; WDS 03.2 §6 Note |
| 1a. Badge typologie | `Badge` (05 §3.3 l. 531-544) — FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY (ADR §13.7) | shadcn `badge` | fond tonal par type : FACT = `info-surface` / TREND = `success-surface` / ANALYSIS = `primary-surface` / SCENARIO = `warning-surface` (marqueur « horizon ») / UNCERTAINTY = `warning-surface` + `⚠` (ADR §13.2) ; texte `xs` 500 ; radius `sm` | n/a | ADR §13.7 ; OQ-2 WDS 03.2 close option A (visuel) ; discovery/overview §8 |
| 1b. Titre court | Texte inline dans `ListItem`, 1 ligne max, ellipsis à 60 caractères | n/a (texte natif) | `text-primary` `sm` 600 ; `text-ellipsis` CSS (05 §2.2 l. 190) | n/a | WDS 03.2 §6 Note (b) |
| 1c. Indicateur de source | `Badge` tonal (05 §3.3 l. 531) : « ✓ N sources » ou « ⚠ N source, uncertain » | shadcn `badge` | `text-secondary` `xs` ; fond `bg-subtle` ; si uncertain = `warning-surface` (ADR §13.2, discovery/overview §8) | n/a | discovery/overview §8 ; ADR §13.2 |
| 1d. CTA « Work on this » | `Button` (05 §3.1 l. 365) — **seul CTA d'action de la surface** (AD-14, garde WDS 03.2 §10) | shadcn `button` variant=ghost (pas plein — 05 §3.3 l. 534 : Badge plein réservé aux CTAs) | `text-primary` `sm` ; 44px tap target (05 §6.3 l. 3327) ; 56px High Contrast | n/a | ADR §13.9 ; AD-14 ; WDS 03.2 §1 |
| header | `TopBar` (56px, 05 §3.4 l. 659) | shadcn `header` (pas ion-item) | `surface`, `md` 600 titre, `text-muted` `xs` sous-titre `UserContext` | n/a | 05 §3.4 l. 659-668 ; WDS 03.2 §6 |
| header actions | 1 `IconButton` (tri, optionnel) | shadcn `button` variant=default size=md | `text-secondary`, 44×44px, icône 20px (lucide S1 l. 59) ; `aria-label='Trier'` (05 §6.3) | n/a | 05 §3.4 l. 664-666 ; 05 §3.1 l. 388-396 |
| footer | `BottomNav` 5 items (05 §3.4 l. 670-688) | shadcn `tab-bar` | `primary-surface` pill, icône 24px `fill` + label `xs` ; 56px + safe-area | n/a | 05 §3.4 l. 670-688 ; OQ-3 WDS 03.2 |
| Empty state | `EmptyState` (05 §3.4 l. 641-653) : icône domaine 48px `text-muted` + titre 1 phrase + body 2 lignes + 1 CTA | shadcn `card` empty variant | icône `domaine` (05 §2.5 l. 287, jamais illustration SaaS) ; `text-secondary` `sm` body ; CTA `Button secondary` « Recharger » (WDS 03.2 §7 Empty) | n/a | 05 §3.4 l. 641-653 ; WDS 03.2 §7 |
| Offline badge | `Badge` dans le `TopBar` (S6 offline l. 184) : « Hors ligne » + dernière valeur syncée | shadcn `badge` | `info` (neutral, 05 §5.1) ; `text-secondary` `xs` | n/a | ui-libraries §6 l. 184 ; 05 §3.7 |

## 4. États (6 S6 + sémantiques §6.1 + 404) — par élément async

### 4a. 6 états S6 (ui-libraries §6 l. 174-187) par élément async

| Élément async | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) |
|---|---|---|---|---|---|---|
| **Feed (liste d'items)** | `Skeleton` × 5 items (05 §3.7 : Card = skeleton contenu) — badges typo en skeleton, CTA indisponible ; ~300ms max (AD-13, WDS 03.2 §7) ; transition d'entrée = `opacity 0→1` 200ms ease-out (polish.tsx l. 42-44) | `EmptyState` (05 §3.4 l. 641-653) : icône `domaine` 48px + titre « Pas encore de découverte pour ton profil » + body « Vérifie ton `UserContext` (domaine, niveau, budget) » + CTA `Button secondary` « Recharger » (WDS 03.2 §7 Empty) — **pas de flux passif de liens** (trap 6) ; transition = `opacity` 200ms | `Alert` destructive (ui-libraries §6 l. 181) : « Le feed ne peut pas être synchronisé » + raison (provider échec, mirror corrompu) + CTA `Button primary` « Réessayer » (retry, discovery/overview §17) ; transition = `opacity` 200ms | `Toast` auto-dismiss 3s (ui-libraries §6 l. 183) : « Feed synchronisé ✓ » (après rechargement réussi) ; `success` = transient, pas d'état persistant | `Badge info` « Hors ligne » dans le `TopBar` (S6 l. 184) + items lus depuis le mirror local `discovery_items` (03-sync §4.2, AD-7) — CTA « Work on this » **reste actionnable** (mène à S-40 qui lit aussi le mirror local, WDS 03.2 §7 Offline) ; transition = `opacity` 200ms | `Skeleton` + auto-resync en arrière-plan (05 §3.7 l. 1294-1300 : killed = sous-état de loading) — bannière fine « Reconnexion… » (05 §3.7 l. 1299) ; les données du mirror s'affichent (jamais d'écran blanc, AD-7) ; transition = `opacity` 200ms |
| **CTA « Work on this » (par item)** | n/a (le CTA est actif dès que l'item est visible) | n/a (pas d'item = pas de CTA) | n/a (le CTA reflète l'état de l'item : si item = `error`, CTA désactivé — 05 §3.7 Button « le CTA reflète ») | n/a (pas de success par CTA) | CTA **actionnable** (S-40 lit le mirror local, WDS 03.2 §7) ; si `ResearchProvider` = `uncertain` (AD-1, discovery/overview §8), le CTA ouvre S-40 avec le marqueur `⚠ uncertain` pré-rempli | n/a (le CTA est un composant `loading = n/a` — 05 §3.7) |
| **Badge source (par item)** | skeleton (avec l'item) | n/a | badge `danger` « source indisponible » si le source est en erreur (05 §3.7 ListItem error = badge resync) | n/a | badge identique (lecture locale, 05 §3.7) | n/a |
| **Header sous-titre `UserContext`** | skeleton texte `xs` | n/a | n/a (texte local, pas d'async) | n/a | n/a (local) | n/a |

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202)

| État | Appliqué ? | Composant + texte + CTA | SSoT |
|---|---|---|---|
| **en-cours** | n/a — le feed ne lance pas de job visible ; les jobs `ResearchProvider` sont serveur (AD-8), le feed lit le mirror local ; l'état en-cours est du job, pas du feed | N/A (raison : le job est serveur, le feed = lecture mirror, discovery/overview §5/§11) | ui-libraries §6.1 l. 197 |
| **terminé** | n/a — un item n'a pas de cycle de vie terminal dans le feed (le sheet S-40 gère la feuille de découverte) | N/A (raison : le feed liste les items, la gestion de cycle de vie est dans S-40, ADR §13.9) | ui-libraries §6.1 l. 198 |
| **échec** | n/a — le feed n'a pas de cycle d'échec non-réessayable ; l'échec d'un provider est un `error` S6 (réessayable, discovery/overview §17) | N/A (raison : provider failure = retry/transient, discovery/overview §17) | ui-libraries §6.1 l. 199 |
| **succès** | oui — après rechargement réussi du feed : `Toast` « Feed synchronisé ✓ » auto-dismiss 3s | S6 `success` (Toast, 3s auto-dismiss) | ui-libraries §6.1 l. 200 ; §6 l. 183 |
| **erreur** | oui — `Alert` destructive + CTA « Réessayer » (ci-dessus 4a) | S6 `error` | ui-libraries §6.1 l. 201 ; §6 l. 181 |
| **404 / not-found** | oui — page entière : `Logo AURORA coloré SANS fond` au CENTRE (§9.1 l. 378, `aurora_icon_a_integre_dans_l'applciation.png`, 24px → 64px), message court « Ce n'est pas une page de découverte » + CTA primaire `Button primary` « Retour à l'accueil » (→ `/home`) + CTA secondaire `Button ghost` « Consulter l'écran parent » (→ Home, 02 §6.3 l. 426-430) ; **pas de crash, pas de 404 nu** (feature-registry S6, not-found/index.tsx l. 2) | §9.1 l. 387 (404 = COLORED without-background, CENTERED, living empty state) ; §6.1 l. 202 | ui-libraries §9.1 l. 387 ; §6.1 l. 202 |

### 4c. Matrice AD-13 par composant (05 §3.7 l. 1244-1309)

| Composant | `loading` | `empty` | `error` | `offline` | `killed` | Géré par |
|---|---|---|---|---|---|---|
| `ListItem` (item typé) | ✓ (skeleton contenu) | n/a | ✓ (badge resync, ci-dessus) | ✓ (identique, lecture locale) | ✓ (comme loading + resync) | composant |
| `Badge` (typo + source) | ✓ (skeleton, avec l'item) | n/a | ✓ (badge `danger` si source en erreur) | ✓ (identique) | ✓ | composant |
| `Button` (CTA « Work on this ») | ✓ (ring interne si item en cours de sync) | n/a | ✓ (CTA reflète : désactivé si item en erreur) | ✓ (actionnable, S-40 mirror local) | ✓ (comme loading) | composant |
| `EmptyState` | n/a | (c'est l'état) | n/a | ✓ (CTA local « Recharger ») | n/a | composant |
| `Alert` (destructive, error feed) | n/a | n/a | (c'est l'état) | n/a | n/a | écran |
| `TopBar` / `BottomNav` | n/a | n/a | n/a | ✓ (badge statique « Hors ligne ») | ✓ (badges statiques) | composant |
| `Toast` (success, offline) | n/a | n/a | ✓ (network error) | ✓ (statique) | n/a | écran |

## 5. Micro-interactions

| Élément | Action → feedback | Durée | GPU only | reduced-motion | Source SSoT |
|---|---|---|---|---|---|
| `ListItem` (item typé) | tap → ouvre S-40 sheet de découverte (WDS 03.3) **par-dessus** le feed (02 §6.1 : détail léger = BottomSheet, pas de changement de tab) | 200ms ease-out (PAGE_TRANSITION, polish.tsx l. 23-28) | `transform: translateY(8px→0)`, `opacity` | `static` (polish.tsx l. 104-110, `useReducedMotion` gate) | polish.tsx l. 23-28 ; 05 §2.6 l. 310-320 ; 02 §6.1 |
| CTA « Work on this » | press → `scale 0.95` (`anim.fast`), puis ouvre S-40 (BottomSheet par-dessus le feed) | 150ms (`aurora.anim.fast`, 05 §3.1 l. 383-385) | `transform: scale(0.95)` | `static` (05 §2.6 l. 330-334, règle 2) | polish.tsx ; 05 §2.6 ; 05 §3.1 |
| Badge typo (tap) | tap → ouvre `Tooltip` (shadcn S1 l. 26) avec description de la typologie (ADR §13.7) | 150ms `ease-out` | `opacity` | `static` | 05 §2.6 ; ui-libraries S1 l. 26 |
| Reveal on scroll (items du feed) | entrée en view → `opacity 0→1`, `translateY(12px→0)`, stagger ≤ 0.4s (05 §2.6 l. 323-330) | 250ms (`REVEAL_TRANSITION`, polish.tsx l. 31-35) | `transform + opacity` (pas de `layout` sur mobile, ui-libraries S5 l. 169) | `static` (05 §2.6 règle 2) | polish.tsx l. 31-35, 94-124 ; 05 §2.6 |
| `Toast` success | entrée `fade-in` + `translateY(8px→0)`, auto-dismiss 3s, file max 1 | 150ms `ease-out` | `transform + opacity` | `static` | 05 §3.5 l. 815-836 ; ui-libraries S1 l. 28-29 |

**Règle bloquante** (05 §2.6 l. 310-346 + ui-libraries S5 l. 169) : **jamais** d'animation qui bloque l'input ; **jamais** de `layout` animations sur mobile ; **jamais** de bouncy ; `prefers-reduced-motion` = **static** (05 §2.6 l. 330-334) ; les **données du feed ne s'animent jamais** (05 §2.6 règle 1 l. 323-330) — seuls les conteneurs (Card, ListItem, Toast) s'animent.

## 6. Modals / BottomSheets / Drawers

| Surface | Déclencheur | Contenu | Focus-trap | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|---|
| `BottomSheet` S-40 (sheet de découverte) | Tap sur un item ou CTA « Work on this » | Les 13 champs de ADR §13.8 (titre, why-now, factual summary, typed sources, confirm/refute, course links, target-domain links, skills, new concepts, open questions, recommended actions, tree/goal links, status) — voir WDS 03.3 | Radix `Dialog` (02 §6.3 : back ne perd rien, auto-persist) | `back` descend le sheet (ferme à `peek` puis entièrement) ; tap backdrop | 250ms `ease-out` (05 §2.6 `aurora.anim.normal`) ; `prefers-reduced-motion` = `instant` | 05 §3.5 l. 780-800 ; 02 §6.3 l. 426-430 ; ADR §13.8 ; WDS 03.3 |
| `Menu` de tri (header `IconButton`) | Tap sur `IconButton` tri (si présent) | Liste : « Par pertinence `UserContext` » (défaut, OQ-1 close) / « Par date » / « Par typologie » (FACT→UNCERTAINTY) — max 6 items (05 §3.4 l. 665) | Radix `dropdown-menu` | `back` ferme ; tap backdrop | 150ms `ease-out` | 05 §3.5 l. 838-850 ; 05 §3.1 l. 401-404 |
| `Tooltip` (badge typo) | Tap sur un `Badge` typologie | Description de la typologie en 1 ligne (ADR §13.7) | n/a (pas de focus-trap) | Tap extérieur ferme | 150ms `ease-out` | ui-libraries S1 l. 26 ; 05 §3.5 |

**Interdits** (05 §3.5 l. 797-800 + S9) : un `Modal` empilé sur un `Modal` (2 décisions séquentielles = 2 Modaux **séquentiels**, jamais 2 en même temps) ; un `FAB` au `/discovery` (interdit — écran de lecture, pas de création, 05 §3.1 l. 406-408 ; OQ-5) ; un `Drawer` de nav principale en mobile (anti-pattern, 05 §3.5 l. 823-828).

## 7. Formulaires

Le `/discovery` n'a **pas de formulaire** (le feed est read-only : lecture du mirror local `discovery_items`, 03-sync §4.2, discovery/overview §11 « job-driven, UI reads mirrors, no screen-level HTTP »).

Le seul formulaire de la chaîne 03 = le formulaire de **création/édition de la sheet S-40** (ADR §13.8, WDS 03.3) — spécifié dans WDS 03.3, pas dans ce spec.

| Champ | Lib | Validation | SSoT |
|---|---|---|---|
| *(aucun au `/discovery`)* | n/a | n/a | discovery/overview §11 |

## 8. Pagination

**Règle unique nommée** : le feed `/discovery` utilise **`shadcn Pagination`** (ui-libraries S1 l. 37 : `npx shadcn@latest add pagination`) — **pas** de `AG Grid` (pas de table lourde, le feed = liste de `ListItem`, pas de data grid) et **pas** de `Pager jour-semaine-mois` (règle 05 §3.4 l. 657, applicables uniquement au calendrier).

**Params** :
- Volume : < 20 items → liste simple sans pagination (ui-libraries S8 l. 304-307 : < 20 rows = shadcn Table) ; 20-100 items → `shadcn Pagination` (20-100 rows = shadcn Table + pagination) ; > 100 items → `AG Grid virtualized` (OQ-4 : le feed dépasse-t-il jamais 100 items ? → voir §14)
- Page par défaut : `UserContext` pertinence (OQ-1 WDS 03.2 close option A), 10 items par page (défaut shadcn Pagination, 05 §3.4)
- `shadcn Pagination` labels : EN par défaut (`Previous` / `Next` / `More pages`, pagination.tsx) — OQ-6 (traduction FR)
- Tri par `UserContext` : `user_context.profile.domaine` + `user_context.level` + `user_context.budget` (AD-15, 01 §4.2 l. 202 : profil de découverte = vue déclarée des types partagés, **jamais** de recopie des niveaux)
- **Règle bloquante** : la pagination ne s'applique **jamais** aux items `UNCERTAINTY` (ADR §13.2) — les items `uncertain` sont toujours visibles (marqueur `⚠`), même si le feed est paginé ; le `⚠ uncertain` = information encore incertaine, pas un item à masquer

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** du `/discovery` (depuis Home 7ᵉ bloc ou deep link) | `PAGE_TRANSITION` : `opacity 0→1`, `translateY(8px→0)`, 200ms ease-out ; `exit` = `opacity 1→0`, `translateY(0→-4px)` (polish.tsx l. 23-28) | polish.tsx l. 23-28, 41-54 ; 05 §2.6 l. 310-320 |
| **Retour** sur le Home depuis S-40 | 02 §6.1 : la S-40 s'ouvre **par-dessus** le feed (BottomSheet), **jamais** par changement de tab ; le retour = le **contexte** (règle de non-surprise) ; le feed re-rend depuis le store local (mirror PowerSync, AD-7) | 02 §6.1 ; 05 §4.1.2 l. 1420-1425 |
| **Back natif** (Android gesture) | Ionic gère les transitions slide/push ; **pas de custom transitions** qui cassent le back natif ; le back matériel doit fonctionner sur toute route (02 §6.3 l. 426-428) | 02 §6.3 l. 426-430 |
| **Items → S-40** | Tap sur un item ou CTA « Work on this » → `BottomSheet` S-40 par-dessus le feed (détail léger, 02 §6.1) ; le feed **ne disparaît pas** (règle de non-surprise : le retour = le contexte, WDS 03.2 §2 Entry Point 4) | 02 §6.1 ; WDS 03.2 §2 |
| **Feed → autres destinations** | n/a — le feed ne dirige jamais vers un écran autre que S-40 (invariant AD-14 : CTA unique, WDS 03.2 §1) ; le 5ᵉ tab `/agent` (BottomNav) est accessible mais **masqué** sur `/discovery` (OQ-3 WDS 03.2 close) | WDS 03.2 §2 ; AD-14 |

**Règle bloquante** (02 §6.1, 05 §4.1.2 l. 1323-1328) : un détail **léger** = `BottomSheet` par-dessus le feed ; un détail **lourd** (sa propre TopBar + sub-navigation) = une **route** push ; **jamais** de changement de tab (Shell.tsx l. 7).

## 10. Thèmes

Comportement des 3 couches sur le `/discovery` (05 §5 l. 2925-3307 ; overview.md §3 l. 27-54) :

- **Couche 1 — Style neutre** (Light `#FFFFFF` / Dark `#121212`) : fournit `surface`, `text-primary/secondary`, `border`, `shadow` — les tokens **géométriques et sémantiques** du feed (fond, texte, ombres des `ListItem`). Le Dark est **première classe** (sessions nocturnes §2.8, `#121212` plain dark, pas `#000` — overview §2 l. 17-23). **WDS 03.2 §5** : la variante Nocturne (défaut pour Horeb, OQ-16) = fond sombre + accent normal, pas de désaturation (OQ-3 close option B 01.1).
- **Couche 2 — Thème expressif** (10 thèmes vivants : Aurora par défaut, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus, Cosmos — 05 §5.4 l. 3010-3046) : fournit `accent.primary/secondary/punctual/focus-ring` — les tokens **couleur** du feed (le `Badge` typo ANALYSIS = `primary-surface`, le CTA « Work on this » si `primary`, le `Badge` `✓ sources`). **Règle bloquante §5.1** : un thème **ne redéfinit JAMAIS** `success`/`warning`/`danger`/`info` — les badges typo FACT (`info-surface`) / TREND (`success-surface`) / SCENARIO (`warning-surface`) / UNCERTAINTY (`warning-surface` + `⚠`) sont **thème-indépendants** (neutral layer, 05 §5.1 l. 2931-2959 ; overview §3 l. 39-43).
- **Couche 3 — Presets** (Slate / Nocturne / High Contrast, 05 §5.5 l. 3153-3165) : Nocturne = desaturated universe (le `Badge` typo reste thème-indépendant, les accents se désaturent via token) ; High Contrast = `7:1 contrast`, `56px targets`, `3px focus ring` (overview §3 l. 45-49 ; 05 §6.3) — le CTA « Work on this » (44px md) passe en `56px` (ajustement, pas de nouveau composant) ; le `Badge` typo passe en `56px tap target` si interactif (OQ-2 WDS : badge visuel = interactif ? → voir §14 OQ-3)
- **Local adaptation V1** = Focus Mode **uniquement** (OQ-15, 05 §5.2 l. 2961-2990) — le `/discovery` n'a **pas** de local adaptation (le Focus Mode bloque les autres surfaces, focus-mode §7, WDS 03.2 §5 : pas de variante Focus)
- **Résolution** : `valeur = theme_accent[token] ?? style_neutre[token] ?? défaut` (05 §5.3 l. 2992-3008) — changée par `resolveToken` + `<AuroraThemeProvider>` (JSON dans `packages/ui/src/themes/`, **jamais** de changement silencieux au foreground, 05 §5.8 l. 3235-3250)
- **Test 10×5** (05 §5.7.1 l. 3183-3194) : le `/discovery` = **Écran 5** (ADR §13.9) du test 10 thèmes × 5 écrans : chaque thème × `/discovery` = mockup ASCII (grille) + note 2 lignes + verdict (bien / à ajuster / proposer comme défaut)

## 11. A11y

| Exigence | Valeur | SSoT |
|---|---|---|
| Contraste | WCAG AA par thème × style neutre (vérifié par test, 05 §6.3 l. 3327-3335 ; overview §7 l. 87-91) ; le `Badge` typo `warning-surface` (SCENARIO/UNCERTAINTY) = contraste `warning` vs `warning-surface` vérifié par test (05 §6.3) | 05 §6.3 ; overview §7 |
| Focus visible | `ring 2px` `focus-ring` (05 §3.1 l. 384) ; High Contrast = `3px focus ring` (05 §5.5 l. 3153-3165) ; vérifié sur les 2 styles (Light + Dark) | 05 §3.1 ; 05 §5.5 |
| Tap targets | `≥ 44px` (05 §6.3 l. 3327-3335) ; `56px` en High Contrast (05 §5.5) ; `BottomNav` = 56px + safe-area (05 §3.4 l. 682-686) ; CTA « Work on this » = 44px md / 56px HC ; `ListItem` = 56px (05 §3.3 l. 519) | 05 §6.3 ; 05 §5.5 ; 05 §3.4 |
| `aria-label` sur tous les `IconButton` | Test CI (05 §3.1 l. 388-396 ; 05 §6.3) ; le `/discovery` a **1 `IconButton`** (tri, si présent) — **chacun** a un `aria-label` (ex. `aria-label='Trier le feed'`) ; un `IconButton` isolé sans `aria-label` = CI rouge | 05 §3.1 ; 05 §6.3 |
| `aria-label` sur les `Badge` typo | Chaque `Badge` typologie (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY) a un `aria-label` descriptif (ex. `aria-label='Typologie : Trend — ADR §13.7'`) — le `Tooltip` (S1 l. 26) fournit le label visuel ; le `aria-label` = le texte du `Tooltip` | 05 §6.3 ; ui-libraries S1 l. 26 |
| `aria-label` sur les CTA « Work on this » | Chaque CTA a un `aria-label` (ex. `aria-label='Travailler sur cette découverte : [titre court]` + `aria-haspopup='dialog'` si S-40 = BottomSheet Radix Dialog) | 05 §6.3 ; ui-libraries S1 l. 13 |
| `Letter-spacing 0` (05 §6.3 l. 3327-3335) | Pas de `letter-spacing` sur le `/discovery` (règle DS) | 05 §6.3 |
| `SR labels` par état (ux-states.tsx l. 79-107) | `loading`/`killed` = `role='status'` + `aria-label` ; `error` = `role='alert'` ; `offline` = `role='status'` + `aria-label='Hors ligne'` ; `empty` = `role='status'` + `aria-label='Aucune découverte pour votre profil'` ; `success` = `role='status'` + `aria-label='Feed synchronisé'` | ux-states.tsx l. 79-107 ; a11yRefs digest |
| `prefers-reduced-motion` | Toutes les micro-interactions §5 passent en `static` (05 §2.6 règle 2 l. 330-334) ; le `Skeleton` shimmer (S6 loading l. 180) = `animation: none` ; le `Toast` = `opacity` instant (pas de `fade-in` 150ms) ; `aurora.css` media query clamps all durations to 0.01ms | 05 §2.6 ; aurora.css (keyFiles digest) ; ui-libraries S5 l. 169 |

## 12. Offline

**Classe offline** (master-feature-catalog §5 Discovery l. 50-58) : le `/discovery` est **`online-required`** pour les **nouveaux items** (jobs `ResearchProvider`, 01 §5.1, AD-8) mais **`offline-capable`** pour la **lecture du feed** (mirror local `discovery_items`, 03-sync §4.2, AD-7/AD-12).

| Ce qui vit sur le **miroir local** (AD-7/AD-12) | Ce qui **meurt** (killed) | SSoT |
|---|---|---|
| Items de découverte existants (`discovery_items`, 01 §4.5 l. 201 : `user_id, title, question, why_now, factual_summary, sources[], kind [scientific\|professional\|innovation\|trend\|uncertain], status`) — lus via PowerSync/SQLite (03-sync §4.2) | Nouveaux items (jobs `ResearchProvider` = serveur, AD-8 — aucun résultat de recherche ne peut être généré offline, discovery/overview §5) | 01 §4.5 l. 201 ; 03-sync §4.2 ; discovery/overview §16 |
| `UserContext` (profil de découverte, 01 §4.2 l. 202 : vue déclarée des skills/goals/cours — JAMAIS de recopie, AD-15) — le tri par pertinence (OQ-1 close) fonctionne offline | Recherche multi-sources (You.com/Tavily/Exa, 01 §3.2 — provider keys server-only, AD-3, discovery/overview §14) | 01 §4.2 l. 202 ; discovery/overview §14 |
| CTA « Work on this » **actionnable** (mène à S-40 qui lit aussi le mirror local, WDS 03.2 §7 Offline) | `DiscoveryItemCreated` event (AD-9, discovery/overview §12 : le consommateur Learning = activité — l'event ne peut pas être émis offline, pas d'activité créée) | WDS 03.2 §7 ; discovery/overview §12 |
| `Badge` source (nombre de sources + marquage `uncertain`, ADR §13.2) — lu depuis le mirror | `uncertain` marking par `ResearchProvider` **nouveau** (si le provider dégrade, le marquage est fait au **serveur** (01 §6, AD-1 last paragraph), pas sur le device) | discovery/overview §8, §17 ; 01 §6 ; AD-1 |

**Dégradation AD-1** (master-feature-catalog l. 50-58) : un deep link vers une feature **désactivée** = état « feature disabled » (02 §7 `error` variant + CTA re-enable + redirect vers le parent tab), **jamais** un 404/crash (feature-registry S6 ; not-found/index.tsx l. 2, 18). Le `/discovery` **a** un deep link (WDS 03.2 §2 Entry Point 3 : push notification, automatisation) — si `discovery.research` est désactivée (feature-registry), le deep link `/discovery` rend l'état « feature disabled » (pas un 404, AD-1). Le feed existe encore (mirror local), mais le CTA « Work on this » = `disabled` (la sheet S-40 dépend de `discovery.sheet` qui est activée ou désactivée par feature-registry).

**Killed** (G-M2, 05 §3.7 l. 1294-1300) : le `kill-app` = un relaunch qui part du **mirror** (pas un nouvel état du moteur). Le `/discovery` re-lecture le store local au boot (02 §6.2) ; **jamais** d'écran blanc ni de reset (AD-7). Le `Skeleton` + auto-resync en arrière-plan (05 §3.7 l. 1299) : bannière fine « Reconnexion… » ; les items du mirror s'affichent dès que le relaunch est complet ; le feed passe en état normal quand le resync s'achève (05 §3.7 l. 1300). Les composants `loading = n/a` (le CTA « Work on this », les `Badge`) n'ont **rien** de nouveau à rendre pour `killed` — ils re-chargent du mirror comme au boot (05 §3.7 l. 1298-1300).

## 13. Logos S9

| Occurrence | Version | Raison (designer psychology) | SSoT ref |
|---|---|---|---|
| `TopBar` (header) — icône 16px à gauche du titre « Découvertes pour toi » | **Version SANS fond** (transparence, `aurora_icon_a_integre_dans_l'applciation.png`) — colorée, **pas** la version complète (ici, dans l'app, pas dans le store/Capacitor) ; 16px (lucide S1 l. 59, pas custom SVG S3 l. 141) ; **pas** de fond coloré derrière l'icône transparente (S9 l. 349 : « No background color behind the transparent version, no crop, no recolor ») | Le header **toujours** porte la marque COLOREE (S9 l. 380 : owner decision 2026-09-27) — le feed est un écran de lecture active (pas un empty state passif), la marque est « active » = colorée | ui-libraries §9 l. 349-369 ; §9.1 l. 380 ; S1 l. 59 |
| Empty state (« Pas encore de découverte pour ton profil ») | **Version SANS fond** au centre du bloc (S9 l. 342 : « page center (empty states, onboarding, in-app splash) »), icône `domaine` 48px (05 §2.5 l. 287, jamais illustration SaaS l. 641) + le logo `aurora_icon_a_integre` en **fond transparent** (pas de fond coloré, S9 l. 349) | Empty state **living** (CTA « Recharger » = marque active = colorée, §9.1 l. 391 : « la monochrome version est **interdite** dans un état vivant (primary CTA = active brand = colored) ») ; le feed vide n'est **pas** un état passif — l'utilisateur **choisit** de recharger | ui-libraries §9 l. 342, 349 ; §9.1 l. 391 ; 05 §3.4 l. 641 |
| 404 / not-found (page entière, §4b ci-dessus) | **Version COLORED SANS fond**, CENTRÉ (S9 §9.1 l. 387 : « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED ») ; `aurora_icon_a_integre_dans_l'applciation.png`, 64px | 404 = living empty state (primary CTA « Retour à l'accueil » = active brand = colored, §9.1 l. 387 + l. 391) ; le 404 n'est **jamais** un crash nu, **jamais** un 404 textuel (feature-registry S6, §6.1 l. 202) ; la marque colorée = « l'app est encore là, pas un échec » | ui-libraries §9.1 l. 387, 391 ; §6.1 l. 202 |
| `BottomSheet` S-40 (header de la sheet) | **Version SANS fond** (S9 l. 342) — 16px à gauche du titre de la sheet ; **pas** de fond coloré (S9 l. 349) ; **pas** la version complète (ici, dans l'app, S9 l. 341-349) | La S-40 est un écran de lecture active (feuille de découverte, ADR §13.8) — la marque est « active » = colorée ; la sheet s'ouvre **par-dessus** le feed, le logo est le même que le header du feed (cohérence, §9.1 l. 380 : header TOUJOURS colorée) | ui-libraries §9 l. 341-349 ; §9.1 l. 380 |
| **Jamais** (interdit, S9 l. 341-349, §9.1 l. 390-392) | `aurora_logo_icon_d'affichage_l'applicaiton.png` (version **complète** = icône d'app **externe** UNIQUEMENT : Capacitor, Play Store, splash screen, install screen — **jamais** dans le UI de l'app, S9 l. 341-349) ; la version **monochrome** dans un état vivant (S9 §9.1 l. 391 : interdite) ; toute recolor (S9 l. 368) ; tout logo custom SVG (S3 l. 141 : interdit) | La version complète = « l'application dans le store », pas dans l'app elle-même ; la monochrome = « marque présente mais silencieuse » (S9 §9.1 l. 374-376) — le feed est un écran **actif** (lecture + CTA), la marque ne doit pas être silencieuse | ui-libraries §9 l. 341-349 ; §9.1 l. 374-376, 390-392 |

**Règle bloquante** (S9 l. 349-368 + §9.1 l. 394-405) : chaque occurrence de logo dans ce spec est **documentée** ; l'usage ad hoc (un logo qui n'apparaît dans aucune des 4 occurrences ci-dessus) est **interdit** ; le logo monochrome n'apparaît **que** dans `AgentThinkingLoader` (§9.3) — **jamais** dans le feed (l'agent n'est pas en train de réfléchir, il lit le mirror, AD-7).

## 14. Open questions

| # | Élément | Question | Options envisagées | Décideur | SSoT manquante |
|---|---|---|---|---|---|
| **OQ-1** | `TopBar` (header) | Le `/discovery` est un écran **racine** (atteint via Home 7ᵉ bloc ou deep link, WDS 03.2 §2 Entry Points 1/3) ou un **push** depuis un autre écran Discovery ? Si racine = **pas de `back`** (05 §3.4 l. 667-670 : « le Home n'a pas de back » ; règle AD-14 : l'écran racine n'a pas de back). Si push depuis S-40 (retour natif, WDS 03.2 §2 Entry Point 4) = **`back` présent**. Le SSoT (05 §3.4 l. 667-670) ne tranche pas pour `/discovery` spécifiquement — la règle est « si l'écran est un push, le `back` est présent ; si écran racine, pas de `back` » — **le `/discovery` est-il un écran racine ou un push ?** | (a) Écran **racine** (pas de `back` — 05 §3.4 l. 667-670, AD-14) (b) Écran **push** (avec `back` — 05 §3.4 l. 663) (c) Le `back` est conditionnel : présent **seulement** si le feed est atteint via S-40 (retour natif, WDS 03.2 §2 Entry Point 4), absent si atteint via Home 7ᵉ bloc (WDS 03.2 §2 Entry Point 1) | Product / 02 §6.1 owner | 05 §3.4 l. 663-670 ; 02 §6.1 ; WDS 03.2 §2 (Entry Points 1 et 4) |
| **OQ-2** | `ListItem` (item typé) | Le titre court (≤ 60 caractères, WDS 03.2 §6 Note (b)) est-il **ellipsé** à 60 caractères (05 §2.2 l. 190 : `text-ellipsis`) ou **tronqué** à 60 caractères avec un CTA « Plus » (ouvre S-40 avec le titre complet) ? La WDS 03.2 §6 propose 1 ligne max — **pas de CTA « Plus »** (le CTA unique = « Work on this », AD-14) ; mais si le titre est trop long, l'ellipsis masque une partie du titre — **faut-il** un `Tooltip` (S1 l. 26) qui montre le titre complet au long-press ? | (a) Ellipsis à 60 caractères, `Tooltip` au long-press (titre complet, `aria-label` = titre complet, 05 §6.3) (b) Ellipsis à 60 caractères, **pas** de `Tooltip` (le titre complet est dans S-40, WDS 03.3) (c) Pas d'ellipsis : le titre est **toujours** complet (2 lignes max, `sm` `line-height: 1.4`) — l'item est plus haut, le feed est moins dense | Design System / 05 §3.3 owner | 05 §3.3 l. 519 ; WDS 03.2 §6 Note (b) ; ui-libraries S1 l. 26 |
| **OQ-3** | `Badge` typologie (a) | Le `Badge` typologie (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY) est-il **interactif** (tap → `Tooltip` description, §5 ci-dessus) ou **non-interactif** (affichage seul, pas de tap target) ? La WDS 03.2 OQ-2 close option A = « badge visuel (icône + couleur par type) » — **visuel** ≠ **interactif**. Si non-interactif : pas de `aria-label` (pas de `tap target` requis, 05 §6.3) ; si interactif : `aria-label` obligatoire (05 §6.3 l. 3327-3335) + `44px` tap target (05 §6.3) — le `Badge` à `44px` = plus grand que le `ListItem` (56px) — **contradiction** de hauteur si `Badge` = 44px et `ListItem` = 56px (le `Badge` dépasse pas, il est **dans** le `ListItem`) | (a) `Badge` **non-interactif** (affichage seul, pas de `tap target`, pas d'`aria-label` — la typologie est décrite dans S-40 (WDS 03.3)) (b) `Badge` **interactif** (`tap` → `Tooltip`, `aria-label` = description, `44px` tap target **dans** le `ListItem` — le `ListItem` reste 56px, le `Badge` est 44px, c'est compatible : le `Badge` est **plus petit** que le `ListItem`) | Design System / 05 §3.3 owner | 05 §3.3 l. 531-544 ; 05 §6.3 l. 3327-3335 ; ui-libraries S1 l. 26 ; WDS 03.2 OQ-2 |
| **OQ-4** | Pagination (§8) | Le feed `/discovery` dépasse-t-il **jamais** 100 items ? Si oui : `AG Grid virtualized` (ui-libraries S8 l. 304-307) — **mais** le feed = liste de `ListItem`, **pas** de data grid (05 §3.3 l. 519 : `ListItem`, pas `AG Grid`). `AG Grid` = table (rows + cols), le feed = liste (1 col) — **la règle S8 l. 304-307 s'applique-t-elle aux listes ?** S8 l. 304-307 = « 20-100 rows + pagination, >100 AG Grid » — « rows » = lignes de table, **pas** items de liste. Le feed = liste → `shadcn Pagination` **toujours** (pas d'`AG Grid`), mais si > 100 items = `react-virtuoso` (ui-libraries S1 l. 63 : « Virtual List (1000+ items) = AG Grid OR react-virtuoso ») — **OQ** : le feed utilise-t-il `react-virtuoso` (pas d'`AG Grid`) si > 100 items ? | (a) `shadcn Pagination` **toujours** (max 100 items par page, jamais d'`AG Grid` pour une liste) (b) `react-virtuoso` si > 100 items (virtualized liste, S1 l. 63) + `shadcn Pagination` (les 2 coexistent : `react-virtuoso` gère le rendu virtuel, `shadcn Pagination` gère la navigation) (c) `AG Grid` si > 100 items (interdit pour une liste — `AG Grid` = table, 05 §3.3) | Design System / ui-libraries owner | ui-libraries S1 l. 37, 63 ; S8 l. 304-307 ; 05 §3.3 l. 519 |
| **OQ-5** | `FAB` (footer) | Le `FAB` est **interdit** au `/discovery` (05 §3.1 l. 406-408 : « le FAB vit dans les écrans de création : inbox, tâches, fiches » ; le feed = écran de lecture, pas de création). **Mais** le CTA « Work on this » (ADR §13.9 : « create activity/project », discovery/overview §2) = **création** d'une activité Learning via `DiscoveryItemCreated` (AD-9, discovery/overview §12) — le feed **déclenche-t-il** une création ? Si oui : un `FAB` « + » (ouvrir S-40 pour créer une sheet) serait **justifié** (05 §3.1 l. 406-408 : le FAB vit dans les écrans de **création**) ; le CTA « Work on this » **par item** = **pas** un `FAB` (le `FAB` = global, pas par item) — **faut-il** un `FAB` global « Créer une sheet de découverte » **en plus** des CTA par item ? | (a) Pas de `FAB` (le feed n'a **pas** de création globale, la création = par item via « Work on this », AD-14 : CTA unique par item) (b) `FAB` « + » global (crée une sheet vide, S-40) **en plus** des CTA par item (exception à AD-14, OQ-5 du home.md : même raisonnement) | Product / AD-14 owner | 05 §3.1 l. 406-408 ; AD-14 ; discovery/overview §12 ; WDS 03.2 §1 |
| **OQ-6** | `shadcn Pagination` (labels) | Les labels de `shadcn Pagination` sont **EN** par défaut (« Previous » / « Next » / « More pages », pagination.tsx l. 51 : « labels hardcoded EN ») — le `/discovery` est un écran **FR** (05 §2.2 : Inter, FR) — **faut-il** traduire les labels (« Précédent » / « Suivant » / « Plus de pages ») ? La règle S1 l. 37 = « `shadcn Pagination` = add pagination » — les labels ne sont **pas** spécifiés en SSoT (pas de section « labels Pagination » dans 05) — OQ pour i18n/FR | (a) Labels **FR** (« Précédent » / « Suivant » / « Plus de pages ») — cohérent avec le reste de l'app (FR, 05 §2.2) (b) Labels **EN** (par défaut shadcn, non-thématisés, OQ i18n) (c) Labels **icônes** uniquement (pas de texte : `ChevronLeft` / `ChevronRight` / `MoreHorizontal` lucide S1 l. 59) + `aria-label` FR (accessibilité, 05 §6.3) | Design System / i18n owner | ui-libraries S1 l. 37 ; pagination.tsx (packages/ui/src/components/ui/pagination.tsx l. 51) ; 05 §2.2 ; 05 §6.3 |
| **OQ-7** | Tri par `UserContext` (OQ-1 WDS 03.2 close option A) | Le tri par `UserContext` (pertinence du profil, ADR §13.1) est **spécifié** mais **pas implementé** (DESIGNED_NOT_IMPLEMENTED, waves 2-4, discovery/overview.md) — **le feed est-il** déjà **trié** par `UserContext` au moment de l'implémentation Phase 1 (mobile, Pixel 4a) ? Si non : le tri = par **date** (les items les plus récents en haut, trigger-map trap 6 « Veille passive » = **moins** pertinent, OQ-1 WDS 03.2 : « Un tri par date serait plus 'flux de liens' (trap 6) ») — **OQ** : le tri Phase 1 = par date (temporaire, jusqu'au moteur `UserContext`) ou par `UserContext` dès Phase 1 ? | (a) Tri par `UserContext` dès Phase 1 (conforme OQ-1 WDS 03.2 close, ADR §13.1) — nécessite le moteur de découverte (AD-8, jobs, waves 2-4) (b) Tri par **date** en Phase 1 (temporaire, anti-trap 6 = moins pertinent, mais implementable sans le moteur `UserContext`) + migration vers tri par `UserContext` en wave 2 (OQ-1 WDS 03.2 : « Un tri par date serait plus 'flux de liens' (trap 6) ») | Product / Discovery owner | ADR §13.1 ; WDS 03.2 OQ-1 ; discovery/overview §2 (DESIGNED_NOT_IMPLEMENTED, waves 2-4) |
