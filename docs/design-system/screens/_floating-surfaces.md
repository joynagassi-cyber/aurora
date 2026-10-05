# Surfaces flottantes — doc transversal (05 §3.5 + ui-libraries S1/S9.3 + motion.tsx @aurora/ui)

Status: SPÉCIFIABLE (inventaire #54) · transversal — **pas un écran, pas une route**
(`_inventory.md` §1 règle 3 : les surfaces flottantes NE SONT PAS des écrans).
Chaque doc écran référence ce doc (§6 de son template) ; **jamais dupliqué**.
SSoT principales : `05-design-system.md` §3.5 l. 752–864 (normes), §3.1 `FAB`
l. 400–411, §2.4 coins & élévations, §2.6 règles animation ;
`docs/ui-libraries.md` S1 l. 13–29 (carte lib), S5 l. 162–172 (mobile + batterie),
§9.3/§9.3.1 (AgentThinkingLoader, owner 2026-09-27/28) ;
`apps/mobile/src/ux/motion.tsx @aurora/ui` (primitives GPU du shell, Phase 3 S3).

## 0. Règle de stacking (normative, 05 §3.5 l. 754–759)

Ordre de z **figé** — le DS est le **seul** à définir le stacking (AD-13) ;
les écrans **n'en définissent jamais** :

```
contenu (0) < TopBar/BottomNav (10) < BottomSheet/Menu/Drawer (30)
< Modal (40) < Toast/Snackbar (50) < Splash (60)
```

Une surface qui « sort de son rang » = review blocking.

## 1. BottomSheet — exploration par-dessus (05 §3.5 l. 787–808)

- **Rôle** : le détail **léger** qui reste « à côté » du contexte
  (02 §6.1 : « les écrans de détail s'ouvrent par-dessus le tab courant »).
  Un écran qui a sa propre TopBar + routing = une **route** (02 §6.1),
  PAS un sheet (règle de séparation §3.5 l. 1327).
- **Déclencheur** : tap sur un item de liste / `ListItem` → ouvre le sheet
  par-dessus (le tab courant **reste**).
- **Rendu** : fond `surface`, coins hauts `xl` (05 §2.4), `shadow.4`
  (le sheet est au-dessus de tout), **handle** 32×4px `border-strong`
  centrée en haut (la « tirette », signal du drag).
- **Deux hauteurs nommées** : `peek` (≈ 25% viewport : titre + 3 lignes +
  1 CTA) et `full` (≈ 85% : contenu complet, défilement vertical libre).
- **Contenu par état** (AD-13) : `loading` = contenu en `Skeleton`
  (le sheet est déjà ouvert, c'est le contenu qui pulse) ; `empty` =
  `EmptyState` compact (pas de CTA si le sheet n'a pas d'action dédiée) ;
  `error` = `Callout danger` inline + retry **dans** le sheet ;
  `offline` = lecture locale normale (AD-7), actions cloud désactivées
  avec explicatif (02 §7).
- **Focus-trap** : le focus reste DANS le sheet (Radix Dialog semantics ;
  le backdrop **verrouille** le contenu arrière).
- **Dismissal** : drag vers le bas (handle) ; le back Android **descend**
  le sheet (ferme à `peek` puis entièrement, pas de saut direct) ; tap
  backdrop. L'état de défilement **persiste** quand on le ré-ouvre
  (store UI, AD-7) — jamais de retour en haut surprise.
- **Transition** : `aurora.anim.normal` = 250ms ease-out (05 §2.6) —
  dans la fenêtre 150–250ms GPU-only (transform + opacity, ui-libraries S5
  l. 169 ; motion.tsx @aurora/ui `PAGE_TRANSITION` = même courbe, 200ms).
  `prefers-reduced-motion` ON = `aurora.anim.instant` (05 §2.6 règle 2) :
  appari **statique**, zéro animation.
- **Lib S1 (l. 14)** : shadcn `drawer` (Vaul) `npx shadcn@latest add drawer`
  + `sheet` (Radix Dialog). Le **naming** SSoT (05 §3.5) = `BottomSheet`
  (hauteurs `peek`/`full`, drag-to-dismiss, back qui **descend**) vs
  la lib shadcn `Sheet` (side variants top/bottom/left/right) et `drawer`
  (Vaul, mobile) : **OQ-1** ci-dessous.

## 2. Modal — dialogue court qui interrompt (05 §3.5 l. 761–785)

- **Rôle** : confirmation, saisie courte, choix binaire — le contenu
  derrière est **verrouillé** (backdrop `surface-overlay`, flou 4px).
  Modal = **interrompt et décide** ; le Sheet = **explore sans s'éloigner**
  (séparation normative, 05 §12).
- **Déclencheur** : `Button` (action qui demande une décision) / geste
  contextuel. Contenu **max** : 1 CTA primaire + 1 ghost + 3 lignes de
  body — au-delà, **ce n'est plus un Modal, c'est un BottomSheet**.
- **Rendu** : fond `surface`, radius `lg` (haut **et** bas, 05 §2.4),
  `shadow.3`, padding `space.6`, largeur **85% du viewport** (le Modal
  est une **fenêtre** ; le plein écran = le `BottomSheet`).
- **Contenu par état** : `loading` = le CTA déclencheur passe en
  `loading` (§3.1), le Modal **reste ouvert** (un modal qui se ferme
  seul pendant la mutation = **interdit** ; l'utilisateur **doit** voir
  le résultat, AD-7 : succès/échec arrive via `JobCompleted`/`AppError`,
  02 §7). `error` = `Callout danger` **dans** le modal (retry **dans**
  le modal, pas une toast qui passe dans le backdrop flouté).
  `offline` = un Modal qui exige le cloud **désactive** son CTA +
  `Callout info` « Hors-ligne — cette action nécessite le réseau »
  (les actions **locales** restent actives, AD-7).
- **Focus-trap** : le focus reste DANS le modal (verrouillage = le
  contenu, pas le back).
- **Dismissal** : le back Android **ferme** le modal (le formulaire du
  modal est **auto-persisté**, le back ne **perd rien**, 02 §6.3).
  **Interdiction** : un Modal **empilé** sur un Modal — si 2 décisions se
  suivent, ce sont 2 Modaux **séquentiels**, jamais 2 en même temps.
- **Transition** : `aurora.anim.normal` = 250ms ease-out (05 §2.6 :
  « Ouverture de Modal ») — GPU-only (transform + opacity), reduced-motion
  = statique (05 §2.6 règle 2, motion.tsx @aurora/ui pattern).
- **Lib S1 (l. 13)** : shadcn `dialog` (Radix, headless, skinnable par
  tokens), `npx shadcn@latest add dialog`.

## 3. Drawer (latéral) — navigation secondaire (05 §3.5 l. 810–821)

- **Rôle** : une **navigation secondaire** — le tri/filtres d'une liste,
  le menu « paramètres rapides » d'un écran.
- **Déclencheur** : `IconButton` (filtres/chevron) dans le header de
  l'écran.
- **Rendu** : panneau latéral (**gauche par défaut**) = **80% de la
  largeur**, fond `surface`, `shadow.3`, radius `lg` (coin opposé),
  backdrop `surface-overlay`.
- **Règle mobile** : le Drawer est **réservé** aux options de l'écran
  (filtres/tri/contexte) — **jamais** la navigation principale
  (celle-ci = `BottomNav`, 05 §3.4 ; un Drawer de nav en mobile =
  anti-pattern).
- **Contenu par état** : `loading` = contenu en Skeleton ; `empty` =
  « aucun filtre actif » (un état **lisible**, pas un vide muet) ;
  `offline` = identique (les filtres sont **locaux**, AD-7).
- **Focus-trap** : le focus reste dans le panneau latéral (Radix
  Dialog semantics).
- **Dismissal** : le back **ferme** le Drawer ; tap du **backdrop**
  ferme. `loading`/`error`/`offline` = contenu dans le panneau.
- **Transition** : `aurora.anim.normal` = 250ms ease-out (05 §2.6),
  GPU-only (transform + opacity), reduced-motion = statique.
- **Lib S1 (l. 14)** : shadcn `drawer` (Vaul), `npx shadcn@latest add
  drawer` — « For Focus details, Goal settings ». ⚠️ **Collision de
  nom** : la lib shadcn `drawer` (Vaul = sheet-like mobile) vs le
  **composant DS** `Drawer (latéral)` 05 §3.5 (panneau latéral 80%) :
  le SSoT DS (05 §3.5) définit le **comportement** (latéral, 80%,
  filtre/tri) ; l'**implémentation** lib shadcn `drawer` (Vaul) est
  orientée bottom-sheet — **OQ-2** ci-dessous.

## 4. Command palette — recherche globale (ui-libraries S1 l. 28)

- **Rôle** : le **global search** de l'app — « Command Palette
  (global search) », Radix Command + shadcn. **5 entry points**
  (S1 l. 28) : UI (SearchBar → palette), palette (raccourci clavier /
  gesture mobile), agent (le /agent **est** le point d'entrée,
  screen `agent-chat`), deep link (route → commande), automation
  (jobs/edge → commande). Le `SearchBar` d'écran = **recherche locale**
  (AD-7) ; le **Command palette** = **global** (les deux cohabitent,
  `bibliotheque-ressources.md` OQ-01).
- **Déclencheur** : tap sur l'icône de recherche (SearchBar d'écran →
  ouvre la palette) ; gesture/raccourci clavier (desktop/webview) ;
  deep link (route → commande) ; automation (jobs).
- **Rendu** : fond `surface`, radius `md` (05 §2.4), `shadow.3`,
  ancré (pas centré dans l'écran). Input = `shadcn Input` + icône
  `Search` Lucide 24px (05 §2.5) ; items = `ListItem` 48px avec
  icône 24px (05 §3.5 l. 848–850, modèle du `Menu`). Max **6** items
  visibles ; au-delà, « Plus… » qui ouvre le 2ᵉ niveau — **jamais**
  plus de 2 niveaux (05 §3.5 l. 851–854, règle du `Menu`, transposée).
- **Contenu par état** : `loading` = résultats en `Skeleton` (les
  group headings restent) ; `empty` = `EmptyState` compact « aucun
  résultat pour … » (pas de CTA dédié) ; `error` = `Callout danger`
  inline + retry **dans** la palette ; `offline` = recherche **locale
  uniquement** (AD-7 : les résultats cloud sont masqués, les
  résultats locaux restent ; le `SearchBar` d'écran = locale,
  la palette = globale — la palette **dégrade** en locale si
  offline, `bibliotheque-ressources.md` OQ-01).
- **Focus-trap** : le focus reste dans l'input de la palette (Radix
  Command semantics).
- **Dismissal** : le back **ferme** la palette ; tap backdrop ;
  `Esc` (clavier, webview/desktop).
- **Transition** : `aurora.anim.normal` = 250ms ease-out (05 §2.6),
  GPU-only (transform + opacity), reduced-motion = statique.
- **Lib S1 (l. 28)** : Radix `Command` + shadcn `command`,
  `npx shadcn@latest add command`. ⚠️ Le SSoT 05 §3.5 (l. 752–864)
  ne mentionne **pas** la Command palette (elle n'est ni `Menu`
  ni `Dropdown`) ; la SSoT = `ui-libraries.md` S1 l. 28 (« 5 entry
  points ») + `command.tsx` (shadcn, `CommandDialog` = `Dialog` +
  `Command`). Les **détails interactionnels** (recherche local vs
  global, dégradation offline, « Plus… » 2ᵉ niveau) = **OQ-3**
  ci-dessous (le SSoT est muet sur le contenu par état et le
  comportement offline de la palette).

## 5. Toast / Snackbar — acknowledgement passif vs action + undo
(05 §3.5 l. 823–841)

- **Différence normative (motivée)** : `Toast` = un
  **acknowledgement passif** (« Tâche terminée ✓ », **2s**, **pas
  d'action** dedans) ; `Snackbar` = une **action + undo**
  (« Supprimé » + « Annuler », **5s**, un **seul** CTA `primary`
  texte). **Pourquoi deux** : le `Toast` **ne bloque jamais**
  (on le lit et on continue — 05 §1 « calme ») ; le `Snackbar`
  **attend une décision** (l'undo est **le CTA**, il reste 5s —
  l'undo de `Button destructive` §3.1 **est** un `Snackbar`,
  règle de non-surprise).
- **Déclencheur** : `Toast` = événement passif (`JobCompleted`,
  `success` S6 l. 183) ; `Snackbar` = `Button destructive`
  (l'undo **est** le CTA du snackbar, §3.1).
- **Rendu / position** : **bas de l'écran, au-dessus du safe-area**,
  **jamais** en haut (le haut = le TopBar ; le feedback bas = la
  zone du pouce).
- **File** : max **1 visible** — un 2ᵉ event met le 1ᵉʳ en attente
  (jamais 3 toasts qui s'écrasent, règle 05 §1).
- **Focus Mode** (05 §2.8, §2.6 règle 3) : les toasts/snickers sont
  **différés** — ils s'affichent **à la fin** de la session Focus
  (jamais pendant le pomodoro). C'est un **état de perf par
  design** (règle 02 §9.3).
- **États** : `offline` = un toast **d'erreur réseau** existe
  (`AppError` `cause:'network'`, 02 §10) — c'est le **seul** toast
  qui peut être « statique » (pas de fade : il **reste** tant que
  l'état network ne change pas, 02 §7 `offline`). Les autres toasts
  = fade out auto.
- **Focus-trap** : N/A — le toast/snackbar est **non-focusable**
  (pas de focus-trap, pas de backdrop, pas de verrouillage du
  contenu arrière). Le `Snackbar` a un `Button` CTA (focusable,
  mais le focus **revient** au contenu derrière au dismiss).
- **Dismissal** : `Toast` = **auto-dismiss** **2s** (05 §3.5 l. 825)
  ; swipe vers le bas (zone du pouce, ui-libraries S8 l. 320).
  `Snackbar` = **auto-dismiss** **5s** ou **CTA `Annuler`**
  (l'undo **est** le CTA, 05 §3.5 l. 830). Le toast d'erreur
  réseau (offline) = **statique** (pas de fade, il reste tant que
  l'état ne change pas, 02 §7).
- **Transition** : `aurora.anim.fast` = 150ms ease-out (05 §2.6,
  micro-interaction) — GPU-only (transform + opacity), reduced-motion
  = statique (pas de fade, pas de slide).
- **Lib S1 (l. 29)** : shadcn `toast` + `toaster`,
  `npx shadcn@latest add toast` + `add toaster` — « Non-blocking
  feedback ». Le **timing** (2s toast / 5s snackbar) et la
  **différence normative** (passif vs action+undo) = **OQ-4**
  ci-dessous (la SSoT 05 §3.5 définit les **durations** mais le
  **comportement du file** (1 visible, queue) et la **position
  exacte** (safe-area) sont **OQ-4**).

## 6. FAB — l'action dominante de l'écran (05 §3.1 l. 400–411)

- **Rôle** : l'action **dominante** de l'écran — **une seule FAB par
  écran, max 1** (si 2 actions dominantes, ce n'est plus une FAB, ce
  sont 2 boutons dans le footer). Position : **bas-droit**, au-dessus
  du `BottomNav` (si présent) ou du safe-area.
- **Variantes** (05 §3.1 l. 405–408) : `default` (56px circulaire,
  icône `on-primary`), `extended` (FAB + label, ex. « Nouvelle tâche »,
  fond `primary`), `mini` (40px, contexte de liste).
- **Interdit** : un FAB dans un écran **déjà saturé** (AD-14 :
  l'accueil **n'a pas** de FAB — l'accueil est calme ; le FAB vit
  dans les écrans de **création** : inbox, tâches, fiches).
- **Déclencheur** : **tap** (44px min, 05 §6.3 ; `default` = 56px,
  `mini` = 40px — le `mini` **dépasserait** 44px ? **OQ-5**).
- **États** (05 §3.1 l. 410–411) : `default / pressed (scale 0.95,
  `anim.fast`) / focus / disabled / `loading` (icône → `ProgressRing`,
  **rare** : le FAB déclenche une action qui **retourne vite** — si
  c'est long, le FAB **disparaît**, l'écran gère l'état `loading` du
  contenu). `offline` = le FAB **reste actif** si l'action est
  **locale** (AD-7) ; il est **désactivé** si l'action exige le
  cloud (02 §7, règle du `Modal` offline transposée).
- **Focus-trap** : N/A — le FAB est **non-focusable** en lui-même
  (pas de focus-trap, pas de backdrop). Le focus reste au contenu
  de l'écran (le FAB est un **bouton flottant**, pas une surface).
- **Dismissal** : N/A — le FAB **n'est pas une surface flottante au
  sens dismissal** (il **n'a pas** de backdrop, il **n'interrompt
  pas** l'écran ; il **trigger** une action). Il **apparaît/disparaît**
  selon l'état (loading = disparaît si l'action est longue, §3.1 l. 411).
- **Transition** : `pressed` = `aurora.anim.fast` = 150ms ease-out
  (scale 0.95, 05 §3.1 l. 410) — GPU-only (transform), reduced-motion
  = statique (pas de scale). Apparaître/disparaître (si l'action est
  longue) = `aurora.anim.normal` = 250ms (05 §2.6), GPU-only.
- **Lib S1** : **OQ-5** — la SSoT 05 §3.1 spécifie le FAB (variantes,
  position, états) mais **ne l'ancre à aucune lib S1** (pas de
  `shadcn add fab` ; le FAB = un `Button` shadcn positionné
  `position: fixed`, bas-droit, `z-index` = 10 (au-dessus du
  BottomNav, stacking §0) + `safe-area` bottom (05 §3.4 l. 682–686).
  L'**implémentation** = shadcn `button` (S1 l. 11) + CSS `position:
  fixed` — **OQ-5** ci-dessous (le SSoT est muet sur la **lib
  exacte** pour le FAB positionné fixed).

## 7. AgentThinkingLoader — l'état « l'agent réfléchit »
(ui-libraries §9.3 l. 420–487 + §9.3.1 l. 491–526)

- **Rôle** : l'état de réflexion de l'agent (écran `/agent`,
  `agent-chat.md` §4 élément 5). **PAS** un trois-points / spinner
  (owner 2026-09-27 : « l'état est un **ORGANISME** organique »).
  Rejected : three dots, plain spinner.
- **Déclencheur** : le `AgentRunState` passe en `thinking`
  (kernel §13, `agent-chat.md` §4 l. 21 : le `Badge AgentRunState`
  dans le header). Le loader **s'insère** entre le message
  utilisateur et la réponse agent (streaming).
- **Rendu / contenu** (ui-libraries §9.3 l. 426–448) :
  - **3 blobs morphing** (back/middle/front, loops 2.6/3.4/4.2s)
    — GPU **ONLY** (transform scale/rotate + opacity), **no**
    `layout` animations, **no** CPU-heavy filters (S5 mobile
    battery + 05 §2.6).
  - Couleur = `--aurora-accent-primary-h` / `--aurora-accent-
    secondary-h` CSS vars → suit le thème expressif actif ;
    Nocturne / High Contrast desature **automatiquement** via
    token (§9.3.1 l. 494–500 : « les blobs = accent only, zéro
    couleur inutile »).
  - **Marque monochrome** (butterfly, stripped copy §9.2) = **prop**
    `butterfly` (ReactNode, optionnelle) — rendue **STATIQUE** au
    centre (S9 : « the organism thinks, the brand stays calm »).
    Le papillon **ne s'anime jamais** lui-même (§9.3 l. 433–436).
  - **Ligne de mots réfléchissants** (rotating thinking-verbs,
    `DEFAULT_THINKING_WORDS` = 12 verbes FR présent, mix sérieu +
    one playful, à la Claude) : crossfade toutes les
    `wordIntervalMs` (défaut **2400ms**). Boîtier `h-5` fixe =
    **pas de reflow** ; le rotator est `aria-hidden` et le
    **SCREEN READER** lit le `label` **STABLE** (défaut
    « L'agent réfléchit… », 13px/500 `text-secondary`) —
    **pas de SR spam**.
  - **Chip durée** optionnelle (`elapsedSeconds`) : « Réflexion · Ns »
    (pattern Claude « Thought for Ns » — l'APP **possède**
    l'horloge, le composant ne **rend** que ; mono +
    `tabular-nums` = pas de jitter).
- **Focus-trap** : N/A — le loader est **non-interactif**
  (pas de focus, pas de touch target, ui-libraries §9.3 l. 462 :
  « non-interactive (no touch target needed) »). Le focus reste
  au contenu du chat (le loader **s'insère** inline, il ne
  **verrouille** pas l'écran).
- **Dismissal / transition** : l'état `exiting` = **collapse +
  fade 200ms ease-out** (ui-libraries §9.3 l. 455–456) quand le
  1ᵉʳ token du streaming **arrive** (le texte **commence** à
  streamer **pendant** le repli, pas après). La durée 200ms est
  **dans** la fenêtre 150–250ms (S3 l. 143 : smooth, motion.tsx @aurora/ui
  `PAGE_TRANSITION` = 200ms). GPU-only (transform scale 1→0.8 +
  opacity 1→0). **`prefers-reduced-motion` ON = le loader
  disparaît **instantanément** (pas de repli, pas de fade,
  05 §2.6 l. 330–334 : reduced-motion = `instant`, 0ms) ;
  le texte commence à streamer **immédiatement**.
- **Retouches owner 2026-09-28** (§9.3.1 l. 491–526, implémentées) :
  - **INHALE** : à chaque changement de mot, l'organisme « inhale »
    (scale 1 → 1.04 → 1, 250ms ease-in-out, GPU) — les 2 couches
    de mouvement (blobs + mot) respirent **ENSEMBLE**.
    reduced-motion = **pas de pulsation**.
  - **FLOAT DU MOT** : le mot **sortant** monte (−4px) en
    s'estompant pendant que le suivant **arrive** depuis le bas
    (+4px → 0), 200ms, GPU (transform + opacity), boîtier h-5
    fixe (zéro reflow). reduced-motion = **swap sans animation**.
  - **CHIP REPLIABLE** « Réflexion · Ns ▸ » (spécifié pour
    l'écran agent-chat, lot 6 DYAD — le composant n'expose
    que `elapsedSeconds`) : à la fin de la réflexion, la chip
    devient une **ligne repliable** avec chevron (pattern Claude
    « Thought for 7s ») ; au clic elle **révèle** un court
    extrait de la réflexion (le `thinking` summary de l'agent,
    **jamais** la chaîne brute — claudelog : thinking blocks =
    brief summaries) ; a11y = **bouton `aria-expanded`** ; le
    chevron pointe vers le bas quand ouvert. L'organisme,
    lui, **disparaît** (état `exiting`).
- **S9 guardrail** (ui-libraries §9.3 l. 465–466) : le loader ne
  **TRANSFORME** que des vecteurs existants (scale / rotate /
  opacity / mask). **ANY** new stroke path / simplified outline /
  decomposed wing groups = a **NEW logo** = **FORBIDDEN** (S9
  « do NOT redraw »).
- **A11y** (ui-libraries §9.3 l. 457–462, `agent-chat.md` §11
  l. 144) : `role="status"` + `aria-live="polite"` ; les mots
  rotatifs = `aria-hidden` (le SR lit le `label` **stable**
  uniquement) ; le papillon = `aria-hidden` (§9.3 l. 433–436 :
  décoratif) ; testable via `data-reduced-motion` /
  `data-thinking-state` attributes (l. 458–459, test
  `agent-thinking-loader.test.tsx`).
- **Contraste QA** (ui-libraries §9.3 l. 487–489 + §9.3.1
  l. 494–500) : le gris le plus foncé (#131B22) ne doit **jamais
  s'asseoir** sur le canvas brut #121212 — le loader est **toujours
  sur un `surface`** (05 §2.1.3) en light ET dark ; **DAPHNE
  vérifie la lisibilité** (blocking si < 3:1, WCAG 1.4.3
  non-text). **TOUS THÈMES SANS EXCEPTION** : le loader doit
  rester lisible sur les 10 thèmes expressifs × {light, dark}
  × 3 presets (Nocturne, High Contrast, Slate) — zéro exception
  (DAPHNE check bloquant : rendu sur 13 combinaisons × 2 styles
  neutres).
- **Sizing (owner 2026-09-28, `agent-chat.md` l. 483–486)** :
  l'organisme reste **48px à gauche** (marque, pas texte) ; la
  ligne de mots + la chip sont à la **taille du texte du chat**
  (même corps que le streaming de réponse) — le loader s'insère
  **inline**, il **ne surdimensionne pas** la conversation.
  `size` prop : défaut 88px ; **64–96px** en chat (ui-libraries
  §9.3 l. 454) — mais l'owner 2026-09-28 dit **48px**
  (marque) : **OQ-6** ci-dessous (contradiction entre
  §9.3 l. 454 « 64–96 in chat » et l. 483–486 « 48px à gauche »).
- **Wing-flap (v2, STRETCH, BLOQUÉ)** (ui-libraries §9.3
  l. 467–478) : v1 SHIPPED = les 3 blobs organiques (pas de
  wing motion). v2 (battement d'aile organique left/right) =
  **BLOQUÉ sur un asset owner-provided** : le SVG actuel est
  une liste plate de ~50 paths gradient-filled, **sans**
  groupes d'ailes indépendants / axes de rotation ; S9
  **interdit** restructurer l'art. Si l'owner fournit une
  variante DECOMPOSEE (leftWing / rightWing / body groups +
  transform-origins, enregistrement comme 5ᵉ SSoT S9),
  alors per-group `rotate` autour de l'axe du corps (GPU,
  3–5° amplitude, 1.2–1.6s ease-in-out, reduced-motion =
  statique). En attendant : **respiration uniquement**.
- **Lib S1** : **OQ-6** — le composant est un **custom**
  `packages/ui/src/components/ui/AgentThinkingLoader.tsx`
  (exported from `@aurora/ui`), **pas** une lib shadcn
  (S1 ne l'ancre à aucune lib — il est **unique**, S9 +
  §9.3 = SSoT). Le code existe (test
  `packages/ui/test/agent-thinking-loader.test.tsx`).

## 8. Transitions — fenêtre normative (05 §2.6 + motion.tsx @aurora/ui +
ui-libraries S3 l. 143 + S5 l. 169)

| Surface | Token 05 §2.6 | Durée | Courbe | GPU (ui-libraries S5) | reduced-motion (05 §2.6 règle 2, motion.tsx @aurora/ui) |
|---|---|---|---|---|---|
| `Modal` (ouverture) | `anim.normal` | **250ms** | `ease-out` | transform (translateY 8→0) + opacity (0→1) | statique (appari instantané, motion.tsx @aurora/ui `PageTransition` pattern) |
| `BottomSheet` (slide-in) | `anim.normal` | **250ms** | `ease-out` | transform (translateY 100%→0) + opacity (backdrop 0→1) | statique |
| `Drawer` (slide-in latéral) | `anim.normal` | **250ms** | `ease-out` | transform (translateX ±80%→0) + opacity | statique |
| `Command palette` (apparition) | `anim.normal` | **250ms** | `ease-out` | transform (scale 0.96→1) + opacity | statique |
| `Toast` (slide-in bas) | `anim.fast` | **150ms** | `ease-out` | transform (translateY 24px→0) + opacity | statique (pas de slide) |
| `Snackbar` (slide-in bas) | `anim.fast` | **150ms** | `ease-out` | idem | statique |
| `FAB` (pressed) | `anim.fast` | **150ms** | `ease-out` | transform (scale 1→0.95→1) | statique (pas de scale) |
| `AgentThinkingLoader` (exiting) | — (ui-libraries §9.3 l. 455) | **200ms** | `ease-out` | transform (scale 1→0.8) + opacity (1→0) | **instantané** (05 §2.6 l. 330–334) |
| `AgentThinkingLoader` (inhale, §9.3.1) | — | **250ms** | `ease-in-out` | transform (scale 1→1.04→1) | **pas de pulsation** |
| `AgentThinkingLoader` (float mot, §9.3.1) | — | **200ms** | `ease-in-out` (GPU) | transform (translateY ±4px) + opacity (crossfade) | **swap sans animation** |
| Page transition (motion.tsx @aurora/ui) | — | **200ms** | `ease-out` | transform (translateY 8→0) + opacity | statique |

**Règle 05 §2.6 (l. 322–334)** : `aurora.anim.fast` = 150ms
(micro-interactions, toggle, chip, hover) ; `aurora.anim.normal`
= 250ms (ouverture Modal/BottomSheet, transition page) ;
`aurora.anim.slow` = 400ms (révélation progressive) —
**aucune** surface flottante n'utilise `slow` (elles sont
toutes `fast` ou `normal`). `prefers-reduced-motion` ON =
**tout passe à `instant`** (05 §2.6 règle 2 : « toute
animation `slow`/`normal` → `instant` si `prefers-reduced-motion:
reduce` ») — motion.tsx @aurora/ui `useReducedMotion()` (motion v13) :
`if (reduced) return <div data-ux="…-static">{children}</div>`
(pas de `motion.div`, zéro keyframe).

**GPU-only (ui-libraries S5 l. 169, §5 l. 51)** : `Framer Motion`
: **GPU** (transform + opacity), **pas** de `layout` animations
sur mobile (battery), `prefers-reduced-motion` = statique.
Les surfaces flottantes utilisent **uniquement** `transform`
(translate/scale) + `opacity` — **jamais** de `layout` prop,
**jamais** de `filter` (blur, shadow animé = CPU, S5 l. 169),
**jamais** de `width`/`height` animé (reflow).

## 9. Focus-trap & dismissal — matrice (05 §3.5 + motion.tsx @aurora/ui)

| Surface | Focus-trap (05 §3.5 + Radix) | Dismissal | reduced-motion (05 §2.6 règle 2) |
|---|---|---|---|
| `Modal` | **OUI** (le contenu arrière est **verrouillé**, Radix Dialog) | back Android **ferme** (le formulaire est **auto-persisté**, 02 §6.3) ; tap backdrop ; **pas d'empilement** (2 Modaux **séquentiels**, 05 §3.5 l. 784–785) | statique (appari/desapparition instantanés, pas de fade) |
| `BottomSheet` | **OUI** (le focus reste dans le sheet, Radix Dialog) | drag vers le bas (handle) ; back Android **descend** (ferme à `peek` puis entièrement, 05 §3.5 l. 801–802) ; tap backdrop ; l'état de défilement **persiste** (store UI, AD-7) | statique |
| `Drawer` | **OUI** (le focus reste dans le panneau latéral) | back **ferme** ; tap **backdrop** **ferme** (05 §3.5 l. 818–819) | statique |
| `Command palette` | **OUI** (le focus reste dans l'input, Radix Command) | back **ferme** ; tap backdrop ; `Esc` (clavier) | statique |
| `Toast` | **NON** (non-focusable, pas de backdrop, pas de verrouillage) | **auto-dismiss 2s** ; swipe vers le bas (zone du pouce) | statique (pas de fade, pas de slide) |
| `Snackbar` | **NON** (non-focusable ; le CTA `Annuler` est focusable mais le focus **revient** au contenu derrière au dismiss) | **auto-dismiss 5s** ou **CTA `Annuler`** (l'undo **est** le CTA) | statique |
| `FAB` | **NON** (bouton flottant, pas de focus-trap, pas de backdrop) | N/A (le FAB **n'est pas** une surface au sens dismissal ; il **apparaît/disparaît** selon l'état) | statique (pas de scale pressé) |
| `AgentThinkingLoader` | **NON** (non-interactif, pas de touch target, ui-libraries §9.3 l. 462) | N/A (le loader **n'est pas** dismissible par l'utilisateur ; il **disparaît** quand le streaming **commence** (état `exiting`, 200ms) ou quand le run est **killé** (re-lecture = `idle`, statique, `agent-chat.md` §12 l. 163) | **instantané** (pas de repli, pas de fade, 05 §2.6 l. 330–334) ; les mots sont **frozen** sur le 1ᵉʳ mot (§9.3 l. 445–446) ; **pas de pulsation** (§9.3.1 l. 514) ; **swap sans animation** (§9.3.1 l. 518) |

## 10. Open questions

| OQ | Surface | Question | Options envisagées | Décideur | SSoT muette |
|----|---------|----------|-------------------|----------|-------------|
| **OQ-1** | `BottomSheet` | Le SSoT 05 §3.5 (l. 787–808) définit le **comportement** (hauteurs `peek`/`full`, drag-to-dismiss, back qui **descend**, état de défilement **persiste**) mais **ne l'ancre à aucune lib S1** (ni `shadcn drawer` (Vaul) ni `shadcn sheet` (Radix)) — laquelle ? | (a) `shadcn drawer` (Vaul, S1 l. 14 « For Focus details, Goal settings ») — mobile-first, drag-to-dismiss **natif** ; (b) `shadcn sheet` (Radix Dialog, S1 l. 14, side variants) — plus flexible (top/bottom/left/right) ; (c) **custom** `BottomSheet` dans `packages/ui` (le SSoT 05 §3.5 = le contrat, l'implémentation = à construire) | UI team (owner 05 §3.5) ; owner decision si custom | 05 §3.5 l. 787–808 (pas d'ancrage lib) ; ui-libraries S1 l. 14 (2 options, pas de choix) |
| **OQ-2** | `Drawer` (latéral) | **Collision de nom** : la lib shadcn `drawer` (Vaul, S1 l. 14) est un **bottom-sheet** mobile ; le **composant DS** `Drawer (latéral)` 05 §3.5 (l. 810–821) est un **panneau latéral** 80% (gauche par défaut). Le SSoT DS définit le **comportement** (latéral, filtre/tri) ; l'implémentation lib (Vaul) est **orientée bottom** — comment résoudre ? | (a) Le `Drawer` latéral = `shadcn sheet` (Radix Dialog, side=`left`) — le SSoT 05 §3.5 = le contrat, la lib shadcn `sheet` = l'implémentation (side variants) ; (b) Le `Drawer` latéral = **custom** dans `packages/ui` (le SSoT 05 §3.5 = le contrat, la lib n'existe **pas**) ; (c) Renommer le composant DS `Drawer (latéral)` → `SidePanel` (pour éviter la collision avec la lib shadcn `drawer` Vaul) | UI team / Design System (owner 05 §3.5) ; owner decision si renommage | 05 §3.5 l. 810–821 (le SSoT ne précise **pas** la lib) ; ui-libraries S1 l. 14 (lib `drawer` = Vaul, **collision de nom**) |
| **OQ-3** | `Command palette` | Le SSoT `ui-libraries.md` S1 l. 28 définit la palette (« Command Palette (global search) », 5 entry points, Radix Command + shadcn) mais **ne spécifie pas** : (a) le contenu par état (`loading`/`empty`/`error`/`offline` — la SSoT est muet) ; (b) le **comportement offline** (recherche locale uniquement vs global, la SSoT est muet) ; (c) la **position** (ancrée vs centrée, la SSoT est muet) ; (d) le **file** (max items visibles, la SSoT est muet — transposé du `Menu` 05 §3.5 l. 851–854 : max 6, 2 niveaux) | (a) Les détails (contenu par état, offline, position, file) = **à spécifier** dans ce doc (ce doc = SSoT transversal, le §4 ci-dessus **propose** les règles) ; (b) Les détails = **OQ** (le SSoT est muet, la décision = UI team) | UI team (owner ui-libraries S1 l. 28) ; owner decision si les règles du §4 sont ratifiées | ui-libraries S1 l. 28 (pas de spécif. contenu par état / offline / position / file) ; 05 §3.5 l. 752–864 (la Command palette **n'y figure pas** — elle est ni `Menu` ni `Dropdown`) |
| **OQ-4** | `Toast` / `Snackbar` | Le SSoT 05 §3.5 (l. 823–841) définit la **différence normative** (passif 2s vs action+undo 5s), la **position** (bas, au-dessus du safe-area), le **file** (max 1 visible, queue) et le **Focus Mode** (différé) — mais **ne spécifie pas** : (a) le **comportement du file** (si 3 toasts arrivent en même temps, la queue = FIFO ? LIFO ? Priorité ? La SSoT est muet) ; (b) la **largeur exacte** du toast/snackbar (la SSoT est muet) ; (c) le **z-index exact** (le stacking §0 dit `Toast/Snackbar (50)` — mais le safe-area + BottomNav = le z est **50** ou **55** ? La SSoT est muet) | (a) File = FIFO (le 1ᵉʳ event = le 1ᵉʳ affiché, le 2ᵉ en attente) ; (b) File = LIFO (le dernier event = le plus important) ; (c) File = Priorité (erreur > succès > info) | UI team (owner 05 §3.5) ; owner decision si la priorité = erreur > succès > info | 05 §3.5 l. 834–835 (le file est « max 1 visible — un 2ᵉ event met le 1ᵉʳ en attente » — **pas de règle FIFO/LIFO/priorité**) ; le safe-area + z-index = 05 §3.5 l. 832–833 (pas de valeur exacte) |
| **OQ-5** | `FAB` | Le SSoT 05 §3.1 (l. 400–411) spécifie le FAB (variantes `default`/`extended`/`mini`, position bas-droit, états) mais **ne l'ancre à aucune lib S1** (pas de `shadcn add fab` — le FAB = un `Button` shadcn positionné `position: fixed`). De plus, la variante `mini` (40px) **dépasserait** le minimum de tap target de 44px (05 §6.3 l. 3327–3335, `agent-chat.md` §11 l. 142) : **OQ-5** (le `mini` = 40px < 44px — le SSoT est en **contradiction** avec 05 §6.3) | (a) Le FAB `mini` = 44px (pas 40px) — le SSoT 05 §3.1 l. 408 est à **corriger** (40px → 44px, conformité 05 §6.3) ; (b) Le FAB `mini` = 40px **toléré** (l'exception = contexte de liste, le tap target effectif = 44px si le FAB est **entouré** de padding) ; (c) Le FAB = `shadcn button` (S1 l. 11) + CSS `position: fixed` (bas-droit, `z-index` = 10 (au-dessus du BottomNav, stacking §0)) + `safe-area` bottom (05 §3.4 l. 682–686) | UI team (owner 05 §3.1 + 05 §6.3) ; owner decision si le `mini` = 44px (correction SSoT) | 05 §3.1 l. 408 (`mini` = 40px) **vs** 05 §6.3 l. 3327–3335 (tap target ≥ 44px) = **contradiction SSoT** ; ui-libraries S1 (pas de `fab`, le FAB = `button` S1 l. 11) |
| **OQ-6** | `AgentThinkingLoader` | La SSoT ui-libraries §9.3 (l. 454) dit « `size` (défaut 88px ; **64–96 in chat**) » ; **mais** l. 483–486 (owner 2026-09-28, écran agent-chat) dit « l'organisme reste **48px** à gauche (marque, pas texte) ; la ligne de mots + la chip sont à la **taille du texte du chat** (même corps que le streaming de réponse) » : **contradiction SSoT** (64–96 vs 48) | (a) L'organisme = 48px (owner 2026-09-28, l. 483–486 = **la plus récente**, elle **override** l. 454) ; la ligne de mots + la chip = taille du texte du chat (ex. 16px) ; (b) L'organisme = 64–96px (l. 454, défaut) ; la ligne de mots + la chip = 88px (défaut) ; (c) **À arbitrer** par l'owner (le SSoT a **deux valeurs**, la dernière (2026-09-28) = 48px, elle **devrait** être ratifiée) | Owner (designer 05 §3.1 + ui-libraries §9.3) ; owner decision si 48px (l. 483–486) **override** 64–96px (l. 454) | ui-libraries §9.3 l. 454 (`size` défaut 88px ; 64–96 in chat) **vs** l. 483–486 (organisme = 48px) = **contradiction SSoT** ; `agent-chat.md` §4 l. 41 (l'organisme = 48px, marque, pas texte) |

**Règle (05 §3.5 l. 754–759 + ui-libraries S8 l. 332)** : le SSoT DS
(05 §3.5) est **normatif** (le comportement, les états, la stacking,
les transitions) ; la SSoT ui-libraries (S1 l. 13–29, S3, S5) est
**prescriptive** (la lib, l'installation, la batterie) ; le code
(`packages/ui`, `apps/mobile`) est **implémentatif** (le code
**suit** les 2 SSoT). En cas de **contradiction** entre les 2 SSoT
(ex. OQ-5, OQ-6) : **l'owner arbitre** (le SSoT DS (05) = le
**comportement** ; le SSoT ui-libraries = la **lib** ; l'owner
**décide**).
