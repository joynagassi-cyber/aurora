# not-found — Not found / feature-disabled (fallback wildcard `*`)

Status: SPECIFIED (OQ: 4, §14) · Module : Shell · Route : `*` (wildcard, `apps/mobile/src/router.tsx` l. 102) · SSoT : page matrix S2 (inventaire #48, `_inventory.md` l. 125) + feature-registry S6 (`docs/frontend/feature-registry.md` §6 l. 107) + ui-libraries §6.1 l. 202 / §9.1 l. 387

> La page de fallback du wildcard `*` : un deep link inconnu, obsolète ou vers une
> feature **désactivée** (feature-registry S6, G-M7) rend cette page **entière** —
> **jamais** un crash, **jamais** un « 404 » nu (feature-registry S6 l. 107 ;
> `apps/mobile/src/pages/not-found/index.tsx` l. 2, 18-21 : `data-state="feature-disabled"` + CTA re-enable).

## 1. Psychologie designer

| Champ | Valeur | SSoT |
|---|---|---|
| Objectif utilisateur (1 ligne) | Retrouver son chemin en **un geste** (CTA « Retour à l'accueil ») sans s'interroger ni sentir que l'app « a cassé » | feature-registry S6 l. 107 ; ui-libraries §6.1 l. 202 |
| Contexte (device/moment/réseau) | Mobile Android Pixel 4a ; moment = l'utilisateur a suivi un deep link (notification, partage, lien externe, URL obsolète) ou un route interne désactivée ; réseau = **indifférent** — la page est 100 % locale (AD-7, aucun serveur requis) ; **offline = comportement normal** (pas de dégradation : il n'y a rien à synchroniser ici) | AD-7 ; feature-registry S6 l. 107 |
| Fréquence | **Rare** (erreur/route inconnue) mais **impact émotionnel fort** : c'est LA page de finition du produit — « le travail de finition se voit là où rien ne va » (prompt SPEC EXTRAS) ; **jamais** de texte nu, **jamais** d'écran blanc | prompt ; feature-registry S6 l. 107 ; §6.1 l. 202 |
| État émotionnel cible | **Rassuré, pas coupé du produit** : la marque est **vivante** (logo coloré centré, CTA primaire actif) — pas une page « tombeau » monochrome ni un error dump technique | ui-libraries §9.1 l. 387 (living empty state = COLORED) |
| Erreur la plus probable | L'utilisateur **abandonne** la suite du flow parce que le message est cryptique (« 404 Not Found » nu, « feature désactivée » sans issue) ; le 2ᵉ CTA « Consulter l'écran parent » absorbe ce cas (règle de non-surprise : le retour au contexte, 02 §6.3) | §6.1 l. 202 ; 02 §6.3 l. 426-430 |
| Ce que l'écran RÉSOUT | « Je suis perdu(e), où va mon deep link ? » → **un CTA primaire** (« Retour à l'accueil », → `/home`) + **un CTA secondaire optionnel** (« Consulter l'écran parent », → parent tab, OQ-2) : la page est un **état entier**, pas une erreur (inventaire #48 : « n/a (état entier, 404 = logo COLORED centre, §9.1/§6.1) ») | inventaire #48 l. 125 ; §6.1 l. 202 |

## 2. Zones (header / content / footer + surfaces flottantes)

- **Header** : `TopBar` 56px — titre = « Indisponible » (nom actuel, `not-found/index.tsx` l. 15 ; le titre exact est une question de copy = **OQ-1**) ; **pas** de logo dans le header (règle S9 : le header est **toujours** le logo COLORED **sans fond** — §9.1 l. 380 ; mais ici le logo « vivant » vit **au centre de la page**, pas dans le chrome — OQ-3 : doublement du logo header + centre ?) ; pas de `IconButton` back (route wildcard = le back matériel gère le retour, 02 §6.3)
- **Content** : **le centre de la page = le logo AURORA COLORE SANS fond, au CENTRE** (ui-libraries §9.1 l. 387 : « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED » ; fichier SSoT = `assets/aurora_icon_a_integre_dans_l'applciation.png`, §9 l. 358 — **jamais** la version full avec fond en in-app, §9 l. 357/365) + **message court** (2 lignes max, `text-secondary` `md`) — le verbatim est **OQ-1** (le composant actuel n'écrit « n'est pas disponible (fonction désactivée) » avec `pathname`, l. 19 ; la version spec = message court sans dump de route, 02 §6.3 non-surprise) + CTA primaire `Button primary` « Retour à l'accueil » (→ `/home`) + CTA secondaire `Button ghost` « Consulter l'écran parent » (→ parent tab, **optionnel** selon §6.1 l. 202, OQ-2)
- **Footer** : `BottomNav` 5 items figés (05 §3.4 l. 670-688) — le fallback s'affiche **dans le Shell** (router.tsx : `NotFoundPage` est un child de `Shell`, l. 54-103) → la nav reste vivante (cohérent « état vivant » du §9.1 l. 387) ; le tab actif = le dernier tab courant (pas de changement de tab sur entrée, 02 §6.1)
- **Surfaces flottantes** : **aucune** (pas de Modal/BottomSheet/Drawer sur une page d'erreur — l'erreur est **posée**, pas poussée ; 05 §3.5 l. 797-800)

## 3. Éléments / widgets (100 % de la zone)

| # | Élément | Composant DS (05 §3) | Lib (ui-libraries S1) | Tokens | Responsive (Phase 2) | SSoT |
|---|---|---|---|---|---|---|
| 1 | **Logo AURORA COLORE au CENTRE** | Logo sans fond, centré (EmptyState center variant, 05 §3.3 l. 491) | `assets/aurora_icon_a_integre_dans_l'applciation.png` importé par le bundler (ui-libraries §9 l. 358, 367 : « both are referenced from repo-root /assets — never duplicated into src/ ») ; **pas** de custom SVG (S3 l. 141 interdit), **pas** de recolor (S9 l. 368) | Fond = `bg` (couche neutre) ; le logo est **coloré** (suit le thème expressif actif, §9.1 l. 387 — « active brand ») ; **pas de fond coloré derrière** (S9 l. 368 : « no background color behind the transparent version ») | desktop = inchangé (centré, pleine largeur) | ui-libraries §9.1 l. 387 ; §9 l. 358 |
| 2 | **Message court** | Texte `md` (05 §2.2 l. 190) | Inter (ui-libraries S1 l. 60) ; 2 lignes max, **pas** de dump de route, **pas** de « 404 » nu | `text-secondary` (couche neutre) ; `letter-spacing 0` (05 §6.3 l. 3327-3335) | n/a | prompt ; feature-registry S6 l. 107 ; copy = OQ-1 |
| 3 | **CTA primaire « Retour à l'accueil »** | `Button primary` (05 §3.1 l. 365 — **max 1 primary par écran**) | shadcn `button` (ui-libraries S1 l. 11, `npx shadcn@latest add button`) | Fond = `primary` (accent thème expressif — le CTA est **coloré**, « active brand » §9.1 l. 387) ; texte = `on-primary` ; tap ≥ 44px / 56px High Contrast (05 §6.3) ; radius ≤ 8px (S3 l. 142) | n/a | §6.1 l. 202 ; 05 §3.1 l. 365 |
| 4 | **CTA secondaire « Consulter l'écran parent »** | `Button ghost` (05 §3.1 l. 365 — jamais à côté de primary sans espacement ≥ `space.2`) | shadcn `button` variant=ghost | `text-secondary` ; tap ≥ 44px ; 56px High Contrast | n/a | §6.1 l. 202 (secondary **optionnel** → OQ-2) |
| 5 | **Bandeau `feature-disabled` (si deep link vers feature désactivée)** | `Callout` (05 §3.3 l. 491) : « Fonction indisponible — [CTA réactiver] » (feature-registry S6 l. 107 : « dedicated "feature disabled" state (02 §7 error variant with a re-enable CTA + a redirect to the parent tab) ») | shadcn `alert` (S1 l. 30) ; le `data-state="feature-disabled"` est déjà porté par le composant (not-found/index.tsx l. 18) | Bordure/fond = `warning` (couche **neutre**, 05 §5.1 l. 2931 — le thème ne touche jamais success/warning/danger/info) ; icône Lucide `info`/`alert` (S1 l. 59) | n/a | feature-registry S6 l. 107 ; 02 §7 (voir OQ-4 : SSoT 02 §7 non citée dans le digest) |
| 6 | **Header** : `TopBar` 56px | `TopBar` (05 §3.4 l. 657-668) | shadcn `header` ; titre `md` 600 (polish.tsx pattern) | `surface`, `text-primary` (titre) | n/a | 05 §3.4 l. 657-668 |
| 7 | **Footer** : `BottomNav` 5 items | `BottomNav` (05 §3.4 l. 670-688 : Accueil / Tâches / Apprendre / Progression / Coach) | shadcn `tab-bar` | `primary-surface` (pill actif) ; icône 24px + label `xs` ; 56px + safe-area (05 §3.4 l. 682-686) | n/a | 05 §3.4 l. 670-688 |

## 4. États (6 S6 + sémantiques §6.1 + 404) — par élément async

### 4a. 6 états S6 (ui-libraries §6 l. 174-187) par élément async

| Élément | `loading` | `empty` | `error` | `success` | `offline` | `killed` (G-M2) | SSoT |
|---|---|---|---|---|---|---|---|
| **Page entière** (éléments 1-4) | **N/A** — la page est **100 % locale** (aucune donnée serveur ; AD-7, prompt Contexte) : pas de `loading`, pas de `Skeleton` (05 §3.7 l. 1244 : un composant sans async n'expose pas les 5 états) | (c'est l'état — voir §4b 404) | N/A (l'erreur **est** la page, §4b) | N/A | **Comportement normal** (pas de dégradation : rien à synchroniser, §1) ; le `BottomNav` reste actif (Shell, 05 §3.4) ; si le système est offline **en même temps** = le badge offline du Shell (S6 l. 184, « Offline » badge top bar) s'affiche **en plus**, pas de changement de la page | `Skeleton` + « Reconnexion… » (05 §3.7 l. 1294-1300, G-M2 : killed = sous-état de loading) + auto-resync en arrière-plan (AD-8) ; la page elle-même **reste affichée** (locale) ; les CTA restent actionnables (navigation locale, 02 §6.3) | 05 §3.7 l. 1244-1309 ; AD-7 |
| **CTA primaire (3)** | N/A | N/A | N/A | N/A | **actionnable** (→ `/home` = navigation locale, AD-7) | **actionnable** (idem, navigation locale) | AD-7 |
| **CTA secondaire (4)** | N/A | N/A | N/A | N/A | **actionnable** (→ parent tab = navigation locale, 02 §6.3 l. 426-430) | **actionnable** | 02 §6.3 |
| **Bandeau feature-disabled (5)** | N/A | N/A | N/A | N/A | **actionnable** (le CTA réactiver = écriture du feature-registry local (UserContext preferences, AD-15), AD-7) | **actionnable** (id) | feature-registry §1 l. 33 ; AD-7 |
| **Header / Footer (6, 7)** | N/A | N/A | N/A | N/A | `Badge info` « Offline » dans le `TopBar` (S6 l. 184) — le chrome **ne** mute **jamais** (05 §3.4 l. 657-668) | badges statiques (05 §3.7 l. 1294-1300) | S6 l. 184 ; 05 §3.4 |

### 4b. États sémantiques §6.1 (ui-libraries l. 189-202) + 404

| État | Appliqué ? | Composant + texte + CTA + tokens + transition | SSoT |
|---|---|---|---|
| **en-cours** (l. 197) | **N/A** (raison : la page n'a **aucun** cycle de vie mesurable — elle n'exécute pas d'opération, elle **affiche** un état ; ≠ S6 `loading`) | N/A | ui-libraries §6.1 l. 197 |
| **terminé** (l. 198) | **N/A** (raison : pas d'objet terminal sur une page d'erreur — le « terminé » est du deep link, pas de la page) | N/A | ui-libraries §6.1 l. 198 |
| **échec** (l. 199) | **N/A** (raison : `échec` = terminal non-réessayable **sur un objet** ; ici c'est la **route** qui est inconnue/désactivée = l'état 404, l. 202 ; le CTA « Retour à l'accueil » **est** le chemin alternatif de l. 199, porté par l'état 404) | N/A | ui-libraries §6.1 l. 199, 202 |
| **succès** (l. 200) | **Oui** — après réactivation d'une feature (CTA du bandeau §4a él. 5) : `Toast` « Fonction réactivée ✓ » auto-dismiss 3s (S6 l. 183) + navigation vers le parent tab (feature-registry S6 l. 107 : « redirect to the parent tab ») | S6 `success` (Toast, 3s) | ui-libraries §6.1 l. 200 ; §6 l. 183 |
| **erreur** (l. 201) | **N/A** (raison : `erreur` S6 = transitoire, réessayable **en place** ; la route inconnue n'est **pas** réessayable en place → c'est l'état 404, l. 202 ; le retry = navigation, pas retry) | N/A | ui-libraries §6.1 l. 201, 202 |
| **404 / not-found** (l. 202) | **Oui — C'EST la page** (état entier, inventaire #48 : « état entier, 404 = logo COLORED centre, §9.1/§6.1 ») : **logo AURORA COLORE SANS fond au CENTRE** (ui-libraries §9.1 l. 387 : « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED » ; `aurora_icon_a_integre_dans_l'applciation.png`, §9 l. 358) + **message court** (`text-secondary` `md`, 2 lignes max, OQ-1) + **CTA primaire** `Button primary` « Retour à l'accueil » (→ `/home`, §6.1 l. 202 : obligatoire) + **CTA secondaire optionnel** `Button ghost` « Consulter l'écran parent » (→ parent tab, §6.1 l. 202 ; OQ-2) ; transition d'entrée = `opacity 0→1` + `translateY(8px→0)` 200ms ease-out (PAGE_TRANSITION, polish.tsx l. 23-28) ; sortie = `PAGE_TRANSITION` exit (l. 41-54) ; **pas de crash, pas de 404 nu** (feature-registry S6 l. 107) ; le 404 = **état vivant** (CTA primaire = action active) → la marque **doit** être **colorée** (interdits §9.1 l. 390-392 : « le monochrome version in a living empty state (primary CTA = active brand = colored) ») | ui-libraries §6.1 l. 202 ; §9.1 l. 387, 390-392 ; inventaire #48 l. 125 ; polish.tsx l. 23-54 |

### 4c. Matrice AD-13 (05 §3.7 l. 1244-1309) — **Aucune case vide**

| Composant | `loading` | `empty` | `error` | `success` | `offline` | `killed` | Géré par |
|---|---|---|---|---|---|---|---|
| `Logo center` (élément 1) | n/a (local) | n/a | n/a | n/a | n/a | n/a (statique) | écran |
| `Message` (2) | n/a | n/a | n/a | n/a | n/a | n/a | écran |
| `Button primary` (3) | n/a | n/a | n/a | n/a | n/a (actionnable) | n/a (actionnable) | composant (S6) |
| `Button ghost` (4) | n/a | n/a | n/a | n/a | n/a (actionnable) | n/a (actionnable) | composant |
| `Callout` (5, feature-disabled) | n/a | n/a | (c'est l'état) | n/a | n/a (actionnable) | n/a (actionnable) | écran |
| `TopBar` (6) | n/a | n/a | n/a | n/a | badge « Offline » (S6 l. 184) | badges statiques (05 §3.7 l. 1294-1300) | composant |
| `BottomNav` (7) | n/a | n/a | n/a | n/a | n/a (nav locale) | n/a | composant |

Source : 05 §3.7 matrice AD-13 l. 1244-1309 (normative) ; « no async component may ship without the 6 states » (02 §11 gate) — ici **aucun** composant n'est async (tous locaux, AD-7) → les cases = `n/a` **motivées**, jamais vides.

## 5. Micro-interactions

| Élément | Action → feedback | Durée (150–250 ms) | GPU only | reduced-motion = static | Source SSoT |
|---|---|---|---|---|---|
| CTA primaire (3) : tap → navigation `/home` | press → `scale 0.95` (`anim.fast`) ; release → `PAGE_TRANSITION` (polish.tsx l. 23-28) : `translateY(8px→0)` + `opacity(0→1)` | **200ms** ease-out (PAGE_TRANSITION) — dans la fenêtre 150-250ms (ui-libraries S3 l. 143) | `transform + opacity` uniquement (ui-libraries S5 l. 169 : GPU only, **pas** de `layout` sur mobile) | `static` (polish.tsx l. 42-44, `useReducedMotion`) ; 05 §2.6 l. 330-334 (règle 2) | polish.tsx l. 23-54 ; 05 §2.6 ; S5 l. 169 |
| CTA secondaire (4) : tap → navigation parent tab | idem | **200ms** ease-out | `transform + opacity` | `static` | polish.tsx ; 05 §2.6 |
| CTA réactiver (bandeau 5) : tap → réactivation + redirect parent | press → `scale 0.95` ; après action : le bandeau **disparaît** (la feature redevient active, navigation vers le parent) + `Toast` « Fonction réactivée ✓ » (S6 l. 183, auto-dismiss 3s) | **150ms** (`anim.fast`) + 3s auto-dismiss | `transform + opacity` | `static` | feature-registry S6 l. 107 ; 05 §3.1 l. 383-385 ; S6 l. 183 |
| Reveal initial de la page (logo + message + CTA, entrée) | `PAGE_TRANSITION` (polish.tsx l. 23-28) : `opacity 0→1` + `translateY(8px→0)` ; le logo est **statique** (pas d'animation sur le logo, §9.1 l. 403-404 : « Monochrome never animates outside §9.3 » — et le coloré non plus : S9 l. 352-353 : « do NOT redraw / generate / détourner ») | **200ms** ease-out | `transform + opacity` | `static` (polish.tsx l. 42-44) | polish.tsx l. 23-54 ; §9.1 l. 403-404 ; S9 |
| Focus Mode (si actif, 05 §2.6 l. 338-342, règle 3) | Les animations `slow` sont coupées ; les transitions page passent en `fast` → `instant` (05 §2.6 l. 338-342) ; la page est **calme** (pas de sur-animation, AD-11) | — (état de perf par design) | GPU only | `static` | 05 §2.6 l. 338-342 ; AD-11 |

**Règle bloquante** (ui-libraries S5 l. 169 + S3 l. 143 + 05 §2.6) : **jamais** de `layout` animations sur mobile ; **jamais** de bouncy (S3 l. 143 : Framer Motion smooth 150-250ms uniquement) ; `prefers-reduced-motion` = **static** (05 §2.6 l. 330-334 : tout passe en `instant`, 0ms) ; le logo **ne s'anime jamais** (S9 : ni redraw, ni animation, §9.1 l. 403-404).

## 6. Modals / BottomSheets / Drawers

| Surface | Déclencheur | Contenu | Focus-trap | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|---|
| **Aucune** | N/A | N/A | N/A | N/A | N/A | 05 §3.5 l. 797-800 (pas de modal sur une erreur — l'erreur est posée, pas poussée) ; l'état 404 est un **état entier** (inventaire #48), pas une surface flottante |

**Interdits** (05 §3.5 l. 797-800 + S9) : un `Modal` empilé sur un `Modal` (n/a ici) ; un `FAB` sur /not-found (interdit, 05 §3.1 l. 406-408 : le FAB vit dans les écrans de création) ; un `Drawer` de nav principale en mobile (anti-pattern, 05 §3.5 l. 823-828).

## 7. Formulaires

Le /not-found n'a **pas de formulaire** (pas de `Form` avec validation zod — la page est read-only : elle **affiche** un état, ne saisit rien).

| Champ | Lib | Validation | SSoT |
|---|---|---|---|
| *(aucun)* | n/a | n/a | feature-registry S6 l. 107 (état + CTA, pas de saisie) |

## 8. Pagination

**Règle unique nommée pour l'écran** : **Aucune pagination sur /not-found** — la page est un **état entier** (inventaire #48 : « état entier, 404 = logo COLORED centre, §9.1/§6.1 »), pas une liste de données : pas de `shadcn Pagination` (ui-libraries S1 l. 37), pas d'AG Grid (S8 l. 304-307 : volume = n/a), pas de `Pager jour-semaine-mois` (05 §3.4 l. 657, calendrier uniquement). Si un jour la page **liste** les routes inconnues (OQ-1) = `shadcn Pagination` (S1 l. 37) — mais V1 = **pas** de liste, pas de pagination.

Source : inventaire #48 l. 125 ; ui-libraries S1 l. 37 ; S8 l. 304-307 ; 05 §3.4 l. 657.

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** (deep link → /not-found) | `PAGE_TRANSITION` (polish.tsx l. 23-28) : `opacity 0→1`, `translateY(8px→0)`, 200ms ease-out ; `exit` = `translateY(0→-4px)` (l. 41-54) ; GPU only, `reduced-motion` = statique (aurora.css l. 126-134) | polish.tsx l. 23-54 ; 05 §2.6 l. 310-320 |
| **Sortie** (CTA « Retour à l'accueil », → `/home`) | `PAGE_TRANSITION` 200ms ease-out (polish.tsx l. 23-28) ; le tab `/home` devient actif (02 §6.1 : le changement de tab est **ici** le **but**, pas un effet de bord) | polish.tsx ; 02 §6.1 l. 310-344 |
| **Sortie** (CTA « Consulter l'écran parent ») | Navigation vers le **parent tab** (feature-registry S6 l. 107 : « redirect to the parent tab » ; 02 §6.3 l. 426-430 : le retour au contexte, règle de non-surprise) ; `PAGE_TRANSITION` 200ms | feature-registry S6 l. 107 ; 02 §6.3 l. 426-430 |
| **Back natif Android** (bouton back sur /not-found) | 02 §6.3 l. 426-430 : le back matériel **fonctionne sur toute route** ; sur /not-found = retour au tab précédent (le contexte, pas un nouvel écran) ; **jamais** un écran blanc (AD-7) | 02 §6.3 l. 426-430 ; AD-7 |
| **Réactivation (bandeau feature-disabled)** | Le CTA réactiver → la feature redevient active → **redirect automatique** vers le parent tab (feature-registry S6 l. 107 : « a redirect to the parent tab ») + `Toast` « Fonction réactivée ✓ » (S6 l. 183) ; le back reste **actionnable** (02 §6.3) | feature-registry S6 l. 107 ; S6 l. 183 ; 02 §6.3 |

**Règle bloquante** (02 §6.1 l. 310-344 + 02 §6.3 l. 426-430) : le /not-found **n'ouvre jamais** de BottomSheet/Drawer (pas de détail léger/lourd — c'est une **page entière**, inventaire #48) ; le back natif **doit** fonctionner (règle 02 §6.3).

## 10. Thèmes

Comportement des 3 couches (05 §5.2 l. 2961, design-system/overview.md §3 l. 27-54) sur le /not-found :

- **Couche 1 — Style Neutre** (light `#FFFFFF` / dark `#121212`, overview.md §2 l. 15-25, 05 §2.1 l. 124/159) : `bg`, `surface`, `text-primary/secondary`, `border` — les tokens **géométriques et sémantiques** de la page (fond, texte, bordures du `Callout` feature-disabled : `warning` est **gelé** couche neutre, 05 §5.1 l. 2931 — **le thème ne le touche JAMAIS**).
- **Couche 2 — Thème Expressif** (10 thèmes, 05 §5.4 l. 3010/3032/3047) : fournit **le logo** — le logo AURORA COLORE **suit** le thème expressif actif (ui-libraries §9.1 l. 387 : « active brand ») ; le CTA primaire (`primary` = accent thème) est **coloré** (idem). **Règle bloquante 05 §5.1** : un thème ne redéfinit **JAMAIS** `success`/`warning`/`danger`/`info` (l. 2931-2959) — le `Callout` feature-disabled (`warning`) est **thème-indépendant** (couche neutre).
- **Couche 3 — Preset** (05 §5.5 l. 3153 : Slate / Nocturne / High Contrast) : Nocturne / High Contrast = **monochrome** (ui-libraries §9.1 l. 384 : « Nocturne + High Contrast presets = monochrome » : desaturated / high-contrast universes, le logo passe en `vs_monochrome_en_svg.svg` §9 l. 360) ; High Contrast = 56px tap targets / 3px focus ring (overview.md §3 l. 27-54, 05 §5.5 l. 3153) ; **V1 = 10 thèmes** (overview.md §9 l. 101-115, G-H2/G-M6 résolus).
- **Local Adaptation** (05 §5.10, OQ-15) : `FocusThemeAdapter` (apps/mobile/src/ux/theme-adapter.tsx) — **V1 = Focus screen ONLY, OQ-15** ; le /not-found **n'a pas** de local adaptation.
- **Règle bloquante 05 §5.1** : le thème ne redéfinit **JAMAIS** `success`/`warning`/`danger`/`info` (l. 2931-2959) ; `warning` (Callout feature-disabled) = couche neutre uniquement.

## 11. A11y

| Règle | Détail sur le /not-found | SSoT |
|---|---|---|
| Contraste (thème × style neutre) | Vérifié par thème × style neutre (05 §6.3 l. 3327-3335, overview.md §7 l. 87-91) ; 10 thèmes × 5 écrans (05 §5.7 l. 3183, lagoon×focus l. 3201, 49 restants = vague 0 l. 3227) ; le logo coloré sur `bg` = contraste du logo **vérifié par thème** (le logo suit l'accent, §10 Couche 2) | 05 §5.7 + §6.3 |
| Tap targets | `Button primary` + `Button ghost` ≥ 44px (05 §6.3 l. 3327-3335) ; 56px sur `High Contrast` (05 §5.5 l. 3153 ; overview.md §3 l. 27-54) ; `tapTargetPx` / `focusRingWidth` (packages/ui/src/themes/types.ts l. 113-118) | 05 §6.3 + §5.5 + overview.md §3 |
| Focus ring | Visible (ring contrast, 05 §6.3) ; 2px par défaut, 3px sur High Contrast (05 §5.5, overview.md §7 l. 87-91) ; `focus-ring` (05 §2.6 l. 325-330) | 05 §2.6 + §5.5 + §6.3 |
| `aria-label` sur **tous** les icon buttons (05 §6.3, a11yRefs) | **Aucun** `IconButton` sur /not-found (pas d'icône sans texte) → **n/a** (règle respectée par construction) ; le `Logo` (élément 1) est **non interactif** (pas de tap target, §5) → pas d'`aria-label` requis (05 §6.3 : uniquement les icon **buttons**) | 05 §3.1 l. 388-396 ; 05 §6.3 |
| `aria-label` sur les `Button` (éléments 3, 4) | Chaque CTA a un `aria-label` explicite (ex. `aria-label='Retour à l'accueil'` / `aria-label='Consulter l'écran parent'`) — les boutons ont du texte visible, l'`aria-label` est **redondant mais obligatoire** (CI, 05 §3.1 l. 388-396) | 05 §3.1 l. 388-396 ; 05 §6.3 |
| `role` + `aria` sur la page (état 404) | `role='alert'` sur le conteneur de la page (état d'erreur, ux-states.tsx pattern : `error` = `role='alert'`, a11yRefs) ; le message (élément 2) est lu par le SR (pas de `aria-hidden`) ; le logo est `aria-hidden` (décoratif, non interactif — S9 : pas de SR spam sur le logo) | ux-states.tsx ; a11yRefs |
| `letter-spacing` 0 (05 §6.3 l. 3327-3335) | Pas de `letter-spacing` sur le message (05 §6.3) | 05 §6.3 |
| Reduced-motion | `@media (prefers-reduced-motion: reduce)` → `0.01ms !important` (packages/ui/src/styles/aurora.css l. 126-134) ; `useReducedMotion` gate (polish.tsx) ; 05 §2.6 l. 330-334 (règle 2) = **obligatoire** : la page s'affiche **instantanée**, statique | 05 §2.6 + aurora.css l. 126-134 |

Règle : un `IconButton` sans `aria-label` = CI rouge (05 §3.1 l. 388-396, test CI, §7) — ici **n/a** (pas d'IconButton).

## 12. Offline

Classe offline : le /not-found est **100 % local (offline-capable, miroir local AD-7)** — la page n'a **aucun** appel serveur (AD-7, §1) ; le feature-registry est lu depuis le miroir local (`user_context` preferences, AD-15, AD-7 PowerSync mirror) ; le CTA réactiver = écriture **locale** (miroir, AD-7), synchronisée en arrière-plan (AD-8).

| Aspect | Spécification | SSoT |
|---|---|---|
| Classe offline | `offline-capable (miroir local, AD-7)` — le /not-found **est** le comportement offline **par défaut** (pas de dégradation : rien à synchroniser, §1) ; le feature-registry (G-M7) = lecture du miroir local `user_context` (AD-15 SSoT, AD-7 PowerSync mirror) ; l'activation/désactivation = écriture locale, sync AD-8 en arrière-plan | AD-7 ; feature-registry §1 l. 33 (`UserContext preferences`); AD-15 |
| Miroir local (AD-7/AD-12) | Le feature-registry est **miroiré** localement (AD-7, `user_context` = Racine RLS, AD-12 : retrieval = serveur **mais** le state enabled/disabled est **local** (UserContext preferences, AD-15) ; le deep link vers une feature désactivée = lecture du miroir (pas de serveur requis pour **afficher** la page, AD-7) | AD-7/AD-12/AD-15 ; feature-registry §1 l. 33 |
| Dégradation AD-1 (offline) | **Aucune** dégradation AD-1 (pas de provider absent, pas de recherche, pas d'IA — la page est purement locale, AD-7) ; le CTA réactiver reste **actionnable** (écriture locale, AD-7) ; le CTA parent = navigation locale (02 §6.3) | AD-7 ; feature-registry S6 l. 107 |
| Killed | Le /not-found **ne meurt pas** (pas de flux serveur, AD-7) : la page reste affichée ; le `BottomNav` reste actif (Shell, 05 §3.4) ; si le **système** est killed (AD-8 sync) = le badge offline du Shell s'affiche **en plus** (S6 l. 184), la page elle-même **ne change pas** (locale) ; re-synchro au retour réseau (AD-8) : le state du feature-registry se met à jour, la page **re-rend** (la feature peut redevenir active → le bandeau disparaît) | AD-7/AD-8 ; S6 l. 184 ; 05 §3.4 |

Règle : le /not-found est **immuni** au kill (pas de serveur, AD-7) — le « killed » de la page = le **chrome** (Shell/BottomNav) qui est killed, pas la page (05 §3.4 l. 657-688).

## 13. Logos S9 (ui-libraries §9 l. 349-369, §9.1 l. 371-405)

Règle ui-libraries S9 (l. 349-369) : version **SANS fond** = centres de page / empty states **UNIQUEMENT** ; version complète = icône d'app externe **UNIQUEMENT** ; monochrome = l'état (pas le thème).

| Occurrence | Version exacte | Raison (designer psychology) | SSoT ref |
|---|---|---|---|
| **Centre de la page** (élément 1) | **COLORED SANS fond, au CENTRE** (`aurora_icon_a_integre_dans_l'applciation.png`, §9 l. 358) | L'état 404/not-found = **état vivant** (CTA primaire « Retour à l'accueil » = action active) → la marque **doit** être **colorée** (ui-libraries §9.1 l. 387 : « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED » ; l. 391 : « FORBIDDEN : the monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») ; la marque colorée = « l'app est **encore là**, pas un échec » (§1 : rassuré, pas coupé) | ui-libraries §9.1 l. 387, 391 ; §9 l. 358 |
| **Preset Nocturne / High Contrast** (Couche 3, §10) | **MONOCHROME SANS fond** (`vs_monochrome_en_svg.svg`, §9 l. 360) ; **pas** de fond (S9 l. 368 : « no background color behind the transparent version ») ; **pas** de recolor (S9 l. 368/390-392 : « any recolor = forbidden ») ; le logo **ne s'anime jamais** (§9.1 l. 403-404 : « Monochrome never animates outside §9.3 » — et le coloré non plus, S9 l. 352-353) | « Nocturne + High Contrast presets = monochrome : desaturated / high-contrast universes » (§9.1 l. 384) ; le monochrome = « brand present but **not speaking** » (§9.1 l. 374-376 : neutrality / waiting / inactive) — sur une page d'erreur **avec** CTA actif, la marque **doit** « parler » (colorée) → le monochrome n'est **que** pour les presets désaturés (Nocturne/High Contrast), **pas** pour l'état vivant coloré | ui-libraries §9.1 l. 384, 374-376, 403-404 ; §9 l. 360 ; S9 l. 352-353, 368 |
| **Header / TopBar** (élément 6) | **Aucun** logo (le header est **texte** uniquement, « Indisponible » — Shell.tsx l. 17 : `IonTitle` = chrome, pas de logo asset, ssootCode logoRefs) ; le logo **n'est pas** dupliqué dans le header (OQ-3 : si le header **et** le centre portent le logo = doublon, S9 l. 367-368 : « never duplicated into src/ ») | Le logo « vivant » vit **au centre** (état 404, §9.1 l. 387) ; le header est le **chrome** (02 §6.1 : le TopBar est la zone de contexte, pas de brand) ; pas de doublement (S9 l. 367-368) | Shell.tsx l. 17 (ssootCode logoRefs) ; 05 §3.4 l. 657-668 ; S9 l. 367-368 |
| **CTA primaire / secondaire** (éléments 3, 4) | **Aucun** logo (boutons text-only, 05 §3.1 l. 365) | Un CTA n'emporte pas le logo (05 §3.1 : le `Button` est un composant d'action, pas de brand) | 05 §3.1 l. 365 |
| **Callout feature-disabled** (élément 5) | **Aucun** logo (l'icône = Lucide `info`/`alert`, S1 l. 59 — **pas** un logo, S3 l. 141 : custom SVG **interdit**) | Le bandeau est un **état** (02 §7 `error` variant, feature-registry S6 l. 107), pas un brand moment ; l'icône = Lucide (pas de logo, S9) | feature-registry S6 l. 107 ; S1 l. 59 ; S3 l. 141 |

**Règle bloquante** (ui-libraries §9.1 l. 390-392, S9 l. 352-353) : le logo **n'est jamais** redessiné / généré / détourné ; la version **complète** (fond) est **jamais** en in-app (S9 l. 357 : « NEVER inside the app UI ») ; le monochrome est **interdit** dans les états **vivants** colorés (§9.1 l. 391) ; **pas** de recolor (l. 368/390-392) ; **usage ad hoc interdit** (toute occurrence hors 404 / AgentThinkingLoader / settings = OQ, ssootCode logoRefs) ; le logo **ne s'anime jamais** (§9.1 l. 403-404, S9 l. 352-353).

## 14. Open questions

| N° | Écran | Élément | Question | Options envisagées | Décideur |
|---|---|---|---|---|---|
| **OQ-1** | Global | Message court (élément 2) | Le **verbatim exact** du message ? (le composant actuel : « « {pathname} » n'est pas disponible (fonction désactivée). », not-found/index.tsx l. 19 — mais le prompt SPEC EXTRAS impose « message court » **sans** dump de route, 02 §6.3 non-surprise) | A : « Cette page est introuvable. » (générique, pas de `pathname`) ; B : « Cette fonction est indisponible. » (feature-disabled uniquement, sans `pathname`) ; C : le `pathname` en `text-muted` `xs` sous le message (trace, pas le message principal) | Open — Product / Design System (05 §3.3 `EmptyState` copy) |
| **OQ-2** | Global | CTA secondaire (élément 4) | Le CTA « Consulter l'écran parent » est-il **toujours** affiché, ou seulement quand le deep link a un **parent** identifié (feature-registry S6 l. 107 : « a redirect to the parent tab ») ? (ui-libraries §6.1 l. 202 : secondary = **optionnel**) | A : toujours (parent = `/home` si inconnu) ; B : seulement si le deep link résout un parent (feature-registry §1 l. 16 : `routes` = prefixes the feature owns → le parent = le prefix) | Open — Product / Feature Registry (G-M7, feature-registry S6 l. 107) |
| **OQ-3** | Header | Doublement du logo (§13 él. 3) | Le header `TopBar` du /not-found porte-t-il **aussi** le logo (en plus du centre) ? (S9 l. 367-368 : « never duplicated » ; §9.1 l. 380 : « the header ALWAYS carries the COLORED brand » — mais ici le logo **vivant** est au **centre**, pas dans le chrome) | A : header **texte** uniquement (pas de logo, le logo = centre uniquement) ; B : header **avec** logo coloré (règle §9.1 l. 380, « header ALWAYS carries the COLORED brand ») — le centre = le logo « vivant » en plus | Open — Design System (ui-libraries §9.1 l. 380 vs. S9 l. 367-368) |
| **OQ-4** | Bandeau | CTA « Réactiver » (élément 5) | Le feature-registry S6 (G-M7) est **NEEDS_DECISION** (feature-registry l. 1 : « decision pending, wave 0 ») : le CTA « Réactiver » est-il **V1** ou **wave 1+** ? (feature-registry §6 l. 107 : le dedicated "feature disabled" state = **obligatoire**, mais le CTA réactiver = la **déactivation** doit être **utilisateur-controllable**, pas système) | A : CTA « Réactiver » = V1 (l'utilisateur contrôle sa feature, 02 §6.3 non-surprise) ; B : CTA absent V1 (le bandeau = information seule, la réactivation = /settings, wave 1) | Open — Feature Registry (G-M7, NEEDS_DECISION wave 0) |

Note : les OQ-1 à OQ-4 = **ouvertes** (pas de SSoT explicite, OQ dans le sens du prompt : « Pas de SSoT = ligne OQ-<n> dans §14 »). Le /not-found est l'écran **le plus** OQ du produit (feature-registry G-M7 NEEDS_DECISION + inventaire #48 « GAP ») — jusqu'à la ratification G-M7, le comportement 404 est défini ici **par inférence de règle** (ui-libraries §6.1 l. 202 + §9.1 l. 387 + feature-registry S6 l. 107), **pas** par un SSoT écran dédié.
