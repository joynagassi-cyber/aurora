## 5. Système de thèmes multi-couches (AD-17 candidate)

Ce chapitre **remplace** la section 2.1 v1 (light/dark binaire) par un système de thèmes en **3
niveaux de résolution**. Ce qu'il ne change pas : la direction *Technical Calm* (§1), les
primitives de la couche 0 (§2.2–§2.6 : typo, spacing, radius, durées, icônes — **figées**), et
les tokens sémantiques `success` / `warning` / `danger` / `info` (couche style neutre,
§2.1.2/2.1.3 — **invariant sous tout thème**, règle §5.1).

Ce chapitre **confirme** le style neutre light tel que figé en §2.1 : le canvas du light est
l'**off-white `#F8F9FA`** (pas le blanc pur `#FFFFFF`, agressif en lecture longue — cible :
sessions de concentration nocturnes et lectures denses, §1). Le blanc pur `#FFFFFF` n'est
autorisé **qu'en surface surélevée** (Card, BottomSheet, Modal), jamais en canvas. `bg` =
`#F8F9FA`, `surface` = `#FFFFFF` : la surélévation se lit par le fond plus clair + l'ombre
`shadow.1`, pas par le blanc du canvas.

### 5.1 Règle 1 — Le thème ne définit JAMAIS la sémantique fonctionnelle

C'est la règle **la plus importante** de tout le pack 05 (AD-17 candidate, bloquante en
review, §5.8).

Un thème expressif (§5.4) ou un preset (§5.5) ne porte que la **personnalité visuelle** :

```
THEME            → personnalité visuelle (accent, gradient, shapes, motion, chart palette)
SEMANTIC STATES  → signification fonctionnelle (success / warning / danger / info)
NEUTRAL STYLE    → structure (canvas, surfaces, texte, bordures, ombres)
```

- `success` / `warning` / `danger` / `info` restent des **tokens sémantiques indépendants**
  définis par le **style neutre** (§2.1.2 light / §2.1.3 dark). Le thème ne les connaît pas,
  ne les référence pas, ne les surcharge pas. Un thème qui déclare `danger` dans son fichier
  JSON = **rejet immédiat** en review (Codex, AD-13 / doc §21.6).
- Un thème ne porte que : `accent.primary`, `accent.secondary`, `accent.punctual`,
  `accent.highlight`, `accent.on-accent`, `accent.focus-ring`, le **gradient propriétaire**,
  les **decorative shapes**, le **motion mood** (dans l'enveloppe AD-10), la **chart
  palette** (contrat `DataVisualizationRenderer`, AD-10 §25.6), et les **treatments**
  (icône, focus, sélection).
- Le même invariant couvre les **état-nœuds** (§2.1.2 `node-mastered` / `node-fragile` /
  `node-forgotten`, doc §14/§25.3) et les **streaks** (`habit-*`) : ils sont des
  projections de `SkillState` AD-15 / des habitudes (types du domaine), **pas** de
  l'accent du thème.

**Exemple de référence (normatif)** : en thème **Sakura** (rosé), une tâche urgente n'est
**pas** rose — `danger` reste le rouge `#EF4444` (light) / `#F87171` (dark) du style neutre.
En thème **Verdant** (vert), un `warning` ne devient **pas** vert — `warning` reste l'ambre
`#F59E0B` du style neutre. **Danger reste Danger. Success reste Success.** — quel que soit
le thème, quel que soit le style neutre.

Rationnel : séparer *personnalité* de *signification* (modèle Material / Fluent / CMS design
systems). Si un thème mutait `danger`, l'utilisatrice ne saurait plus ce que sa couleur veut
dire : une erreur de calcul en rose (Sakura), une tâche bloquée en vert (Verdant) = un
signal de confiance détruit. Or Aurora est un outil de **lecture dense** (formules, unités,
Gantt, §1 *Technical Calm*) : la fiabilité sémantique y est **critique**, pas décorative.

### 5.2 Architecture 3 niveaux

Le système final est en **3 niveaux de résolution** — chaque niveau écrit des tokens
différents, jamais le même token qu'un niveau inférieur :

| Niveau | Nom | Définit | Qui l'écrit |
|---|---|---|---|
| 1 | **Style Neutre** (light `#F8F9FA` off-white / dark `#121212`) | fond, texte, surfaces, bordures, ombres — et **la sémantique fonctionnelle** (`success/warning/danger/info`, `node-*`, `habit-*`) | pack 05 §2.1.2/2.1.3 (figé) — un thème **ne** déclare **jamais** ces tokens |
| 2 | **Thème Expressif** (1 des 10 vivants §5.4) **ou** preset spécialisé (§5.5) | accent, gradient, decorative shapes, motion mood (AD-10), chart palette, treatments (icône/focus/sélection) | catalogue JSON `packages/ui/src/themes/` (AD-15 SSoT, §5.8) |
| 3 | **Adaptation Locale** (module/écran) | des **valeurs** de tokens existants, déclaratives (token → valeur), dans le périmètre du module seul | Contract Pack du module (AD-13) |

- **Niveau 1 — Style Neutre** : l'utilisatrice choisit `light` (canvas off-white `#F8F9FA`)
  ou `dark` (canvas `#121212`). Les valeurs exactes = §2.1.2 / §2.1.3. La sémantique
  fonctionnelle vit **ici** et ne vit nulle part ailleurs (règle §5.1).
- **Niveau 2 — Thème Expressif** : 1 des 10 thèmes vivants (§5.4) — **ou** un preset
  spécialisé (§5.5, qui se **combine** avec un thème expressif, jamais à sa place).
- **Niveau 3 — Adaptation Locale** : un module (ex. Focus Controller, pack 04 §4) **déclare**
  des adaptations token → valeur, applicables **dans son périmètre seul**. Déclaratif,
  jamais branché en code (contrat §5.8). **JAMAIS un changement de thème par écran** :
  « Normal = bleu, Focus = vert, Study = orange » = interdit (§5.10).

```
AURORA THEME SYSTEM
   Niveau 1  Style Neutre      : Light #F8F9FA (off-white)  |  Dark #121212
   Niveau 2  Thème Expressif   : 1 des 10 (§5.4)  +  presets (§5.5)
   Niveau 3  Adaptation Locale : module/écran — token → valeur (déclaratif, AD-13)
```

### 5.3 Résolution 3 niveaux (token → valeur)

Pour chaque token, la valeur retenue est :

```ts
valeur = theme_accent[token] ?? style_neutre[token] ?? défaut_du_thème_par_défaut
```

| Famille de tokens | Résolution | Source |
|---|---|---|
| `accent.primary` / `accent.secondary` / `accent.punctual` / `accent.highlight` / `accent.on-accent` / `accent.focus-ring` / `chart.*` | thème expressif (§5.4) | couche 2 |
| `canvas` / `surface.*` / `text.*` / `border.*` / `shadow.*` — et **`success` / `warning` / `danger` / `info`**, `node-*`, `habit-*` | style neutre **uniquement** (règle §5.1) | §2.1.2 / §2.1.3, couche 1 |
| `typo.*`, `space.*`, `radius.*`, `duration.*` | primitives figées — aucune couche ne les surcharge | §2.2–§2.6, couche 0 |

Le thème par défaut (`Aurora`) est le seul qui a l'obligation de couvrir **tous** les tokens
d'accent : le fallback de la résolution est `THEMES["aurora"][token]`. Les tokens
**structurels** (canvas, surface, text, border, shadow) et **sémantiques** (success, warning,
danger, info) n'ont **pas** de fallback thème : ils sont résolus **exclusivement** par le
style neutre (§5.3, règle §5.1).

### 5.4 Les 10 thèmes vivants (couche 2 — catalogue extensible)

Chaque thème est un **univers visuel complet** — pas trois couleurs tirées au hasard. Les 4
couleurs de chaque thème ont des **rôles fixes** :

- `primary` (c1) : CTA principal, liens actifs, tracés de charts dominants — **le** accent
- `secondary` (c2) : gradients, charts secondaires, accents tonals
- `punctual` (c3) : accent ponctuel — **jamais** pour du texte au corps
- `highlight` (c4) : surface de sélection tonale (fond de `ListItem` selected, pill de
  `BottomNav`, chip sélectionné) ; **jamais** pour du texte sombre au corps

**Contraste (normatif, §5.9)** : le texte **sur** `primary` = `on-accent` fixé par thème
(vérifié ≥ 4.5:1, tableau ci-dessous) — jamais le `on-primary` du style neutre si le ratio
n'est pas atteint. Un thème dont le `primary` passe sous 3:1 sur un canvas light **devra**
déclarer son `primary` comme **non-autorisé en fond de Button** sur ce style (le composant
tombe sur le tonal, §5.9).

| # | `primary` c1 | `on-accent` (texte sur c1) | Ratio c1×#F8F9FA | Ratio c1×#121212 | Ratio c4×#0A0E1A (ink) | Ratio c4×#121212 (sur) |
|---|---|---|---|---|---|---|
| Aurora | `#3678F6` | `#FFFFFF` | 3.85 | 4.62 | 13.79 | 13.41 |
| Lagoon | `#007C91` | `#FFFFFF` | 4.64 | 3.83 | 16.74 | 16.29 |
| Boreal | `#2E5C8A` | `#FFFFFF` | 6.61 | 2.69 | 15.67 | 15.25 |
| Sakura | `#D85B86` | `#FFFFFF` | 3.46 | 5.14 | 15.02 | 14.61 |
| Vesper | `#6554C0` | `#FFFFFF` | 5.56 | 3.20 | 14.76 | 14.36 |
| Solara | `#D99A24` | `#3B2405` (encre ambre) | 2.32 | 7.67 | 16.96 | 16.50 |
| Terra | `#B85C38` | `#FFFFFF` | 4.31 | 4.13 | 14.98 | 14.57 |
| Verdant | `#247A55` | `#FFFFFF` | 4.99 | 3.56 | 16.57 | 16.12 |
| Citrus | `#F28C28` | `#3B2405` (encre ambre) | 2.33 | 7.63 | 16.88 | 16.42 |
| Cosmos | `#3B3FA7` | `#FFFFFF` | 8.11 | 2.19 | 16.36 (`#E9ECFA`) | 5.84 (`#E95BAA`) |

Interprétation normative :
- **Solara / Citrus** (primaires dorés/orangés, ratio < 3:1 en light) : en style neutre
  light, le `Button primary` de ces thèmes est **tonal** (fond = `accent.highlight`, texte =
  encre du style) + accent ponctuel `punctual` ; le `primary` reste autorisé en **grande
  surface** (ring du FocusTimer, charts, gradient du TopBar du Home) et en **dark** (ratio
  7:1). C'est la seule exception au « primary = fond du Button » — et elle est **prévue
  contractuellement**, pas ad hoc.
- **Boreal / Vesper / Cosmos** (primaires sombres, ratio < 3:1 en dark) : symétrique — en
  style neutre dark, le `Button primary` reste plein mais le ring focus passe en
  `accent.highlight` (les 4e couleurs de Boreal `#DCEAF2`, Vesper `#E7DDF8` et Cosmos
  `#E9ECFA` ont ≥ 4.5:1 sur dark, cf. tableau).
- Les `highlight` (c4) : ≥ 13:1 en tous les cas = **texte** sur surface tonale toujours
  lisible (encre du style neutre), et `surface` tonale `#121212` ≥ 5:1 pour Cosmos
  (exception tolérée : Cosmos est le thème **contrôlé**, règle ci-dessous).

#### 5.4.1 Tableau récapitulatif

| # | Thème | Univers | 4 couleurs (c1 primary · c2 secondary · c3 punctual · c4 highlight) | Impression |
|---|-------|---------|------------|------------|
| 1 | **Aurora** (défaut) | ciel à l'aube | `#3678F6` `#22C7D6` `#7B61FF` `#B8DFFF` | intelligent, frais, tech |
| 2 | **Lagoon** | eau tropicale | `#007C91` `#18B7A0` `#50D8C0` `#D9F5EF` | fluide, respirant |
| 3 | **Boreal** | paysage nordique | `#2E5C8A` `#4A8C6A` `#8DC7D9` `#DCEAF2` | précis, scientifique |
| 4 | **Sakura** | fleurs de cerisier | `#D85B86` `#E98EAD` `#9B78C9` `#F8DCE7` | élégant, doux, humain |
| 5 | **Vesper** | ciel violet du soir | `#6554C0` `#8C5BD6` `#D05AA8` `#E7DDF8` | profond, contemplatif |
| 6 | **Solara** | lumière dorée | `#D99A24` `#F0B83F` `#E86F42` `#FFF0C2` | ambitieux, énergique |
| 7 | **Terra** | terre cuite / argile | `#B85C38` `#C9823B` `#D8AE72` `#F2E1C3` | artisanal, créatif |
| 8 | **Verdant** | végétation vivante | `#247A55` `#42A96B` `#8CCF8A` `#DFF3E3` | naturel, stable |
| 9 | **Citrus** | agrumes / énergie | `#F28C28` `#F7C948` `#B7D83D` `#FFF0B8` | joyeux, ludique |
| 10 | **Cosmos** | espace / nébuleuse | `#3B3FA7` `#5964E8` `#18BFD4` `#E95BAA` | futuriste (règle : 1 dom + 1 sec + 1 accent) |

#### 5.4.2 Détail par thème

**01 — Aurora (défaut)**
- **Univers** : ciel à l'aube. L'identité native d'Aurora — premier thème au lancement (le
  gradient `cyan → blue → violet` est déjà la charte visuelle du nom, doc §14/§25).
- **Couleurs** : `#3678F6` (bleu aube, **primary**) · `#22C7D6` (cyan aurore,
  **secondary**) · `#7B61FF` (violet indigo, **punctual**) · `#B8DFFF` (ciel pâle,
  **highlight** — fond de sélection tonale).
- **Gradient propriétaire** : `cyan → blue → violet`, 135°, sur les grandes surfaces
  uniquement (hero du TopBar du Home, ring du FocusTimer complet, fond du splash —
  jamais sur une Card de contenu, règle §1 « calme technique »).
- **Decorative shapes** : courbes orbitales douces (arcs, trajectoires) — en EmptyStates et
  sur le splash uniquement (le contenu **dense** reste non-décoré, §1).
- **Motion mood (AD-10)** : fluide, léger — `anim.fast` 150ms / `normal` 250ms, ease-out ;
  révélations pédagogiques en `spring` (stiffness 200, damping 25).
- **Chart palette (G2, AD-10 §25.6)** : bleu `#3678F6`, cyan `#22C7D6`, violet `#7B61FF`,
  indigo soutenu — 4 séries max par chart (règle §12 : la donnée parle, pas le décor).
- **Icon / focus / selection** : icônes Ionicons §2.5 (fill par défaut), teintées `#3678F6`
  + accents cyan sur les icônes de domaine `packages/ui/src/icons/` ; focus ring 2px
  `#3678F6` offset 2px (§6) ; sélection = fond tonal `#B8DFFF` + bordure `#3678F6`
  (ListItem §3.3, chip §3.3).
- **Usage émotionnel recommandé (pas imposé)** : le mode par défaut ; sessions mixtes
  productivité + apprentissage.

**02 — Lagoon**
- **Univers** : eau tropicale.
- **Couleurs** : `#007C91` (teal profond, **primary**) · `#18B7A0` (turquoise,
  **secondary**) · `#50D8C0` (turquoise clair, **punctual**) · `#D9F5EF` (sable-vert,
  **highlight**).
- **Gradient propriétaire** : `teal → turquoise → sable vert`, vertical, halos doux
  (le TopBar du Home peut porter ce gradient ; un écran dense non).
- **Decorative shapes** : vagues, courbes organiques (un seul par écran max, EmptyStates /
  splash).
- **Motion mood** : très fluide, lent — `anim.normal` 250–400ms, spring doux (le mouvement
  « respire », §1 calme).
- **Chart palette** : teal / turquoise / emeraude (la série `#50D8C0` porte la tendance
  courante).
- **Icon / focus / selection** : fill `#007C91`, accent turquoise ; focus ring 2px `#007C91`
  (light) / `#50D8C0` (dark, ratio 7.42:1 — vérifié §5.9) ; sélection fond `#D9F5EF`.
- **Usage émotionnel recommandé (pas imposé)** : Focus Mode, lecture longue, habitudes et
  routines — le contexte de respiration (§2.8, doc §2.7). Le verdict du test §5.7.1 (Lagoon ×
  Focus Mode) le confirme : c'est le **thème contextuel recommandé** pour le Focus
  (adaptation locale niveau 3, **pas** un changement de thème par écran, §5.2).

**03 — Boreal**
- **Univers** : paysage nordique.
- **Couleurs** : `#2E5C8A` (bleu glacier, **primary**) · `#4A8C6A` (vert froid,
  **secondary**) · `#8DC7D9` (argent-glace, **punctual**) · `#DCEAF2` (blanc polaire,
  **highlight**).
- **Gradient propriétaire** : `glacier → lichen → argent`, horizontal sobre (le seul thème
  dont le gradient peut porter la ligne de temps du GanttRow §3.6.4).
- **Decorative shapes** : géométriques, droites (pin, montagne, strates).
- **Motion mood** : sobre, précis — `anim.fast` 150ms, ease-out, **pas** de spring en
  révélation (Boreal = précision, la donnée apparaît **vite**, §2.6 règle 1 : le scientifique
  ne scintille pas).
- **Chart palette** : glacier / vert froid / argent-glace — idéale pour séries multiples de
  données scientifiques (§15).
- **Icon / focus / selection** : fill `#2E5C8A` (light) ; focus ring 2px `#8DC7D9` (dark —
  le primary à 2.69:1 en dark **n'est pas** autorisé en ring, le punctual le remplace,
  tableau §5.4) ; sélection fond `#DCEAF2`.
- **Usage émotionnel recommandé (pas imposé)** : révisions exigeantes, Scientific Engine,
  calculs et tables de données (doc §15, §25.5).

**04 — Sakura**
- **Univers** : fleurs de cerisier.
- **Couleurs** : `#D85B86` (framboise, **primary**) · `#E98EAD` (rose poudré,
  **secondary**) · `#9B78C9` (lilas, **punctual**) · `#F8DCE7` (blanc rosé,
  **highlight**).
- **Gradient propriétaire** : `rose → lilas`, doux, vertical (halo discret sur le TopBar ;
  le canvas reste off-white `#F8F9FA` — Sakura n'est **pas** un thème « fond rose »,
  règle §5.10 : l'univers vit dans l'accent, jamais dans le canvas).
- **Decorative shapes** : pétales, formes organiques arrondies (EmptyStates, splash —
  un seul par écran).
- **Motion mood** : doux, flottant — `anim.normal` 250–300ms, spring léger (le mouvement
  descend, il ne glisse pas — analogie pétale).
- **Chart palette** : framboise / rose poudré / lilas — les séries se distinguent par
  **luminosité** (framboise = série forte), pas par teinte (le rose pâle se fond dans le
  blanc, §5.9 : 2e série minimum `#E98EAD`).
- **Icon / focus / selection** : fill `#D85B86` (light) / `#E98EAD` (dark, ratio 3.20→5.14
  vérifié) ; focus ring 2px `#D85B86` ; sélection fond `#F8DCE7`.
- **Usage émotionnel recommandé (pas imposé)** : personnalisation douce, créativité, notes
  manuscrites et routines (doc §2.7) ; « je veux que mon app soit douce » — **sans**
  devenir une app « tech bleue » (la couleur n'est **jamais** une catégorie d'utilisateur,
  §5.10).

**05 — Vesper**
- **Univers** : ciel violet du soir.
- **Couleurs** : `#6554C0` (indigo, **primary**) · `#8C5BD6` (violet, **secondary**) ·
  `#D05AA8` (magenta, **punctual**) · `#E7DDF8` (lilas clair, **highlight**).
- **Gradient propriétaire** : `indigo → violet → magenta`, horizon crépusculaire — le
  thème qui **vit le mieux** en style neutre dark (le dark n'est pas une contrainte pour
  Vesper, c'est son univers : le test §5.6 est le canonical de cette combinaison).
- **Decorative shapes** : halos, lumières diffuses (le seul thème dont le décor peut
  **flouter** légèrement, opacité ≤ 8%, surfaces de fond **uniquement** — jamais sous du
  texte, règle §1).
- **Motion mood** : lent, contemplatif — `anim.normal` 250ms et `slow` 400ms, ease-in-out
  (le mouvement **décélère**, il n'interrompt pas la lecture).
- **Chart palette** : indigo / violet / magenta — la série magenta est **toujours** la 3e
  ou 4e (l'accent, §5.4 règle).
- **Icon / focus / selection** : fill `#6554C0` ; focus ring 2px `#8C5BD6` (light) /
  `#E7DDF8` (dark, 14.36:1) ; sélection fond `#E7DDF8`.
- **Usage émotionnel recommandé (pas imposé)** : revues hebdo/mensuelles (doc §2.9),
  Progress dashboard (doc §18.6), Journal des décisions — les écrans **rétrospectifs**
  (Vesper = le temps qui passe, pas le temps qui presse).

**06 — Solara**
- **Univers** : lumière dorée.
- **Couleurs** : `#D99A24` (ambre profond, **primary**) · `#F0B83F` (or clair,
  **secondary**) · `#E86F42` (corail, **punctual**) · `#FFF0C2` (ivoire doré,
  **highlight**).
- **Gradient propriétaire** : `or → ambre → corail` (golden hour) — le seul thème dont le
  gradient **chauffe** (les 9 autres refroidissent ou restent neutres : règle de
  distinction, §5.10).
- **Decorative shapes** : rayons, cercles lumineux (un seul par écran, EmptyStates).
- **Motion mood** : lumineux, énergique — `anim.fast` 150–200ms, ease-out (le mouvement
  **accélère**, c'est l'anti-Vesper).
- **Chart palette** : ambre / or / corail — le corail porte **toujours** la valeur
  d'alerte visuelle (sans être `danger` : rappel règle §5.1, corail ≠ danger, c'est
  **l'accent** qui attire l'œil).
- **Icon / focus / selection** : en light, `primary` `#D99A24` = Button **tonal**
  (§5.4 tableau : ratio 2.32:1 — le contrat, pas un cas particulier) ; focus ring 2px
  `#D99A24` ; sélection fond `#FFF0C2`. En dark (ratio 7.67:1) le primary **redevient
  plein** — le même thème change de traitement selon le style neutre, **c'est normal**
  (la résolution §5.3 est par style).
- **Usage émotionnel recommandé (pas imposé)** : objectifs ambitieux, jalons, « Vision de
  l'excellence internationale » (ADR §13.5) — Solara est le thème de l'**horizon**, pas de
  la routine.

**07 — Terra**
- **Univers** : terre cuite / argile.
- **Couleurs** : `#B85C38` (terracotta, **primary**) · `#C9823B` (ocre, **secondary**) ·
  `#D8AE72` (sable, **punctual**) · `#F2E1C3` (crème terre, **highlight**).
- **Gradient propriétaire** : `sable → ocre → terracotta` (strates de terre, horizontal).
- **Decorative shapes** : organiques, architecturales (briques, arcs — écho de la cible :
  génie civil, §1).
- **Motion mood** : sobre, terrestre — 150–200ms, ease-out (Terra **ne bouge pas**,
  c'est lui qui est **solide** — le seul thème dont le motion mood est le plus proche de
  `anim.instant`).
- **Chart palette** : terracotta / ocre / sable — les séries se distinguent par **valeur**
  (sable = tendance faible), pas par teinte (les 3 teintes sont dans la même famille,
  §5.9 : Terra est le thème qui **exige** le plus de séparation par luminance).
- **Icon / focus / selection** : fill `#B85C38` ; focus ring 2px `#B85C38` (light, 4.31:1 —
  sous le seuil 3:1 d'un ring large ? Non : ring = élément UI, seuil 3:1 ATTC §5.9 —
  4.31 passe) ; sélection fond `#F2E1C3`.
- **Usage émotionnel recommandé (pas imposé)** : projets, construction, disciplines
  techniques, créativité matière (doc §2.5) — Terra est le thème du **faire**, pas du
  « rêver ».

**08 — Verdant**
- **Univers** : végétation vivante.
- **Couleurs** : `#247A55` (vert profond, **primary**) · `#42A96B` (vert vif,
  **secondary**) · `#8CCF8A` (menthe, **punctual**) · `#DFF3E3` (feuillage clair,
  **highlight**).
- **Gradient propriétaire** : `vert profond → menthe` (canopée, vertical).
- **Decorative shapes** : feuilles, courbes naturelles (un seul par écran).
- **Motion mood** : naturel, vivant mais stable — 200ms, ease-out (Verdant **ne
  vacille pas** : c'est la stabilité qui fait le vert, pas le mouvement).
- **Chart palette** : vert profond / vert vif / menthe — **attention (règle §5.1, rappel)**
  : le vert de Verdant est **esthétique**, le vert de `success` (`#10B981`, §2.1.2) est
  **sémantique**. Ils ne sont **pas** la même valeur, et ils ne doivent **jamais** être
  confondus : un `SkillStateBadge mastered` (§3.6.11) reste `success` même sous Verdant
  (le nœud maîtrisé n'est pas **doré** par le thème — la donnée technique parle, §2.6
  règle 1).
- **Icon / focus / selection** : fill `#247A55` ; focus ring 2px `#247A55` (light) /
  `#8CCF8A` (dark, 10.18:1) ; sélection fond `#DFF3E3`.
- **Usage émotionnel recommandé (pas imposé)** : habitudes, routines, santé, travail long
  (doc §2.7) — le thème qui **supporte** plusieurs heures sans fatigue (§1 calme technique).

**09 — Citrus**
- **Univers** : agrumes / énergie solaire.
- **Couleurs** : `#F28C28` (orange vif, **primary**) · `#F7C948` (citron,
  **secondary**) · `#B7D83D` (lime, **punctual**) · `#FFF0B8` (jaune pâle,
  **highlight**).
- **Gradient propriétaire** : `orange → jaune → lime` (fruits du soleil, 135°).
- **Decorative shapes** : formes rondes, segments d'orange (EmptyStates, splash).
- **Motion mood** : vif, énergique — 100–150ms, ease-out (le **plus rapide** des 10 —
  Citrus est le thème du rythme, pas de la contemplation).
- **Chart palette** : orange / citron / lime — 3 séries max (les teintes sont trop proches
  entre elles pour 4, §5.9 ; 4ᵉ série = `punctual` lime en **haché**, pas en plein).
- **Icon / focus / selection** : en light, `primary` `#F28C28` = Button **tonal**
  (§5.4 : ratio 2.33:1) ; focus ring 2px `#F28C28` ; sélection fond `#FFF0B8`. En dark
  (7.63:1) le primary redevient **plein**.
- **Usage émotionnel recommandé (pas imposé)** : « je veux que mon app soit colorée »,
  mode ludique, productivité en rythme rapide (les listes de tâches courtes, pas les
  revues longues — Citrus **épuise** en lecture dense, §1).

**10 — Cosmos**
- **Univers** : espace / nébuleuse.
- **Couleurs (rôle fixé)** : `#3B3FA7` (indigo profond, **dominante**) · `#5964E8`
  (bleu-violet, secondaire de support) · `#18BFD4` (cyan, **secondaire**) · `#E95BAA`
  (fuchsia, **accent ponctuel**).
- **Règle spécifique Cosmos (normative, §5.4)** : Cosmos ne met **pas** ses 4 couleurs
  partout. Sa règle : **1 dominante** (`#3B3FA7`) + **1 secondaire** (`#18BFD4`) +
  **1 accent ponctuel** (`#E95BAA`) + le gradient propriétaire. C'est ce qui donne son
  esthétique « spectaculaire mais **contrôlée** » : le fuchsia est l'étoile, pas le fond du
  ciel. Si un écran Cosmos est fuchsia **partout**, il a **échoué** au test §5.7
  (le verdict « à ajuster » = le fuchsia a dépassé sa dose de 10% de l'écran, max).
- **Gradient propriétaire** : `indigo → cyan → magenta` (nébuleuse, 135° — le seul thème
  dont le gradient traverse **3** dominantes).
- **Decorative shapes** : étoiles, particules, orbitales (le décor est **épars**, pas
  dense : 5–8 éléments max par écran, opacité ≤ 12%, **jamais** sous du texte).
- **Motion mood** : légèrement dynamique — particules douces, 300ms, spring (le mouvement
  **drift**, il ne **pulse** pas : un Cosmos qui scintille devient du « SaaS générique »,
  §5.10).
- **Chart palette** : indigo / cyan / fuchsia (3 séries — le fuchsia porte **toujours** la
  série d'exception, jamais la série de base).
- **Icon / focus / selection** : fill `#3B3FA7` (light, 8.11:1 — le primary **le plus
  contrasté** des 10 en light) ; focus ring 2px `#18BFD4` (dark, 8.42:1) ; sélection fond
  `#E9ECFA` (un **support** indigo pâle **dérivé** du thème, pas le fuchsia — la
  sélection reste **calme**, §1).
- **Usage émotionnel recommandé (pas imposé)** : découverte (ADR §13), l'arbre sémantique
  (les « ponts » inter-domaines, doc §14), « mode futuriste » — Cosmos est le thème
  **rêve**, pas le thème **travail** (la donnée dense = Boreal, §5.4.2 n°3).

### 5.5 Presets spécialisés (hors des 10 expressifs)

Ces 3 **n'ont pas d'univers** — ce sont des **modes techniques** qui se **combinent** avec
n'importe quel thème expressif, jamais à sa place :

| Preset | Rôle | Valeurs |
|---|---|---|
| **Slate** | lecture longue, sobriété pro, faible stimulation | gris-bleu / ardoise (`#4A4A5A` primaire, `#707080` secondaire) ; gradients **désactivés** ; shapes épurées (pas d'illustration, le texte **est** le décor) |
| **Nocturne** | dark doux pour la nuit (moins éblouissant que le Dark standard `#121212`) | canvas `#0A0E1A` (le quasi-noir bleuté du dark standard §2.1.3, **repris** comme style neutre dédié) ; surfaces plus foncées (`#151C2C` → `#0F1524`), accents du thème **désaturés** (saturation − 30%, la luminance reste : le thème est **reconnaissable** sans être éblouissant) |
| **High Contrast** | accessibilité forcée, contrastes 7:1, tap targets 56px | noir/blanc purs, bordures épaisses (2px → 3px), focus ring 3px, les 4 accents du thème **re-liftés** pour ≥ 7:1 sur le canvas courant (le preset **override** les ratios §5.9 — c'est le seul cas où un thème peut **changer** sa valeur d'accent : le preset est un **mode d'accessibilité**, pas un thème) |

Combinaison : `Dark + Cosmos + High Contrast` = cosmos avec contrastes renforcés, tap
targets 56px. Le preset **s'applique en plus** du thème : il ne le remplace pas (le
Cosmos reste **reconnaissable** — indigo + cyan + fuchsia re-liftés, pas un thème
noir/blanc générique).

### 5.6 Exemple de thème composite (Dark + Vesper)

Le composite = style neutre Dark (`#121212`) **×** thème expressif Vesper (+ preset
optionnel). Le tableau ci-dessous montre **qui fournit chaque valeur** — c'est le
mécanisme, pas un simple « look » :

| Rôle | Valeur | Fourni par |
|---|---|---|
| Canvas | `#121212` | style neutre Dark (§2.1.3) |
| Surfaces | `#1E1E1E` / `#2A2A2A` / `#353535` | Dark (les ombres ne se voient pas en dark, §2.4 — les **surfaces** remplacent l'élévation) |
| Accent primaire | `#6554C0` | Vesper (§5.4.2 n°5) |
| Accent secondaire | `#8C5BD6` | Vesper |
| Accent ponctuel | `#D05AA8` | Vesper |
| Chart palette | `#6554C0` / `#8C5BD6` / `#D05AA8` | Vesper |
| `success` / `warning` / `danger` / `info` | **Dark standard** (§2.1.3, nuances 400) | style neutre — **pas** Vesper (règle §5.1) |
| `node-mastered` / `node-fragile` / `node-forgotten` | `emerald.400` / `amber.400` / `red.400` (§2.1.3) | style neutre — le nœud maîtrisé **reste vert** sous Vesper (§5.4.2 n°8, rappel) |

Résultat : « un crépuscule violet sur fond sombre » — l'atmosphère change, la
signification **ne** change pas. C'est **ça** qu'un thème doit produire : un
changement d'atmosphère, pas un changement de signification. (Dark + Vesper est
**le** canonical du test §5.7, écran 3 « Arbre sémantique » : un nœud `mastered`
vert sur fond violet-obscur = la preuve que la sémantique a **survécu** au thème.)

### 5.7 Test des 10 thèmes sur 5 écrans (mécanisme + 1 exemple concret)

**Mécanisme** (le pack 05 fournit, les 49 autres paires = vague 0, équipe Dyad/UI, doc
§22) :

Les 5 écrans testés (issus du §4 de ce pack) :

1. **Accueil** (AD-14, `welcome/home` §4.1.2) — le test de la **7ᵉ règle** : aucun widget,
   une seule question ; le thème doit rester **calme** ici (le Home AD-14 est
   **contraignant** sous tout thème — un thème qui « explose » le Home = verdict
   « à ajuster », §5.10).
2. **Focus Mode** (§4.4.2) — le test du **ring** : le FocusTimer §3.6.9 est le
   composant le plus visible ; un thème qui rend le ring « moche » ou « brouillon »
   échoue.
3. **Arbre sémantique** (`SemanticTreeNode` §3.6.6 + doc §14/§25.3) — le test de
   **density** : 3 couleurs de nœud (mastered/fragile/forgotten, §5.1) **doivent**
   rester lues sur le fond du thème ; un thème qui les « fond » échoue.
4. **Progress Dashboard** (§4.5.2 + doc §18.6) — le test des **charts** : la palette
   du thème (G2, AD-10) doit distinguer **4 séries** min sans confusion (règle §5.4
   par thème).
5. **Discovery Feed** (ADR §13.9, doc §13) — le test de l'**écart** : un feed est
   **vivant** (les découvertes sont colorées par type, pas par thème) ; le thème doit
   rester **fond**, le contenu doit **parler**.

Pour **chaque** paire thème × écran (10 × 5 = 50 paires) :

- Un mockup (vague 0 : sur les vrais composants React, équipe Dyad/UI, doc §22) montrant
  : bouton primaire, carte, focus ring, badge sémantique (le `danger` **doit** être
  visible — le test **spécifique** de la règle §5.1), chart (4 séries).
- Une note 2 lignes : ce que le thème fait **ressentir** sur cet écran (pas « il est
  joli » — « le turquoise du timer apaise, le fond off-white ne se dispute pas »).
- Un verdict : **bien** / **à ajuster** / **proposer comme défaut pour X**.

**Exemple concret (1 des 50, ici fourni par le pack 05)** : Thème Lagoon × Focus Mode.

```
┌─────────────────────────────────────┐
│  LAGOON — Focus Mode (Light)        │
│                                     │
│        [Timer ring 12:00]          │
│        (stroke #007C91)            │
│                                     │
│  Focus: Rapport de sol             │
│  ██████████████░░░░░░  68%        │
│  (bar #007C91 → #50D8C0)           │
│                                     │
│  [Button "Reprendre"] (#007C91)    │
│  [Button "Terminer"]  (ghost)      │
│                                     │
│  Surfaces : #D9F5EF (cartes)       │
│  Fond     : #F8F9FA (off-white)    │
│  Badge danger (ex. "3 tâches bloquées") :
│    reste #EF4444 (rule 5.1)        │
└─────────────────────────────────────┘
```

Note : Lagoon sur Focus Mode = **parfait**. Le turquoise profond `#007C91` du timer
est apaisant, le gradient de la barre de progression (teal → turquoise) est fluide
sans être bruyant. Le fond off-white `#F8F9FA` (style neutre Light, §5.2) ne se
dispute pas à l'accent. Et le badge `danger` (ici « 3 tâches bloquées », le focus
**réduit** les notifications mais **n'efface pas** les états, §5.1) reste le rouge
standard `#EF4444` — pas le turquoise. C'est la règle 5.1 **en action** : le thème
change l'atmosphère, pas la sémantique.

Verdict : **BIEN** — proposer comme **thème contextuel recommandé** pour Focus Mode
(adaptation locale §5.2 niveau 3, pas un changement de thème — l'utilisatrice qui
choisit Lagoon **globalement** aura le Focus en Lagoon ; l'adaptation locale n'est
qu'un **renfort** (surfaces secondaires atténuées, focus ring renforcé), pas un
**swap**).

**Les 49 autres paires (10 × 5 − 1 exemple) = livrable de vague 0, équipe Dyad/UI**
(doc §22 : « Dyad : refinement UI/UX et validation des flows »), sur les vrais
composants React du pack 05. Ce pack fournit le **mécanisme** (§5.1–§5.6 + §5.8) ;
les 49 mockups restants sont un **livrable d'acceptation UI** (vague 0,
non-blocking pour la V1 du système lui-même, §5.8), pas un contenu du pack 05.

### 5.8 Contrats techniques (AD-17 candidate)

Le système de thèmes est un **contrat** au sens AD-13 / AD-15 du spine (AD-17 = candidate,
à ratifier au prochain ADR du spine — breaking change = dedicated PR + mandatory Codex
review, spine §162) :

- **Live** : les 10 thèmes expressifs + 3 presets = **13 fichiers JSON** dans
  `packages/ui/src/themes/` (AD-15 SSoT, owner = Design System team, matrice doc
  §21.2 : « Design System → packages/ui et tokens »).
- **Format** : `aurora.theme.{themeName}.{dimension} = valeur` ; dimensions = les 10 de
  §5.4 (colors c1–c4, onAccent, gradients, illustrationMood, iconTreatment,
  selectionTreatment, focusTreatment, chartPalette, decorativeShapes, motionMood,
  usageEmotionnelRecommande). Les presets §5.5 = 3 fichiers JSON **dans le même
  catalogue** (ils **surchargent** les ratios §5.9, jamais les tokens sémantiques
  §5.1).
- **Ajout de thème = 1 fichier JSON + 1 ligne dans le catalogue `themes.json`,
  pas de code.** Un 11ᵉ thème (ex. « Indigo », « Rose », « Ombre ») s'ajoute
  **sans** toucher au domaine, aux composants, ou au `resolveToken` (AD-13 :
  additive change = intégration normale, spine §21.7 — le linter de §5.4 (les
  4 rôles c1–c4 + le ratio check §5.9) bloque l'ajout si le JSON est malformé,
  c'est le **seul** code impliqué).
- **Résolution** : la fonction `resolveToken` (couche TypeScript, `packages/ui`) :

```ts
// packages/ui/src/themes/resolve.ts
export function resolveToken(
  theme: ThemeName,        // ex. "vesper"
  preset: PresetName | null, // ex. "high-contrast" | null
  style: NeutralStyle,     // "light" | "dark"
  tokenKey: string,        // ex. "accent.primary"
): string {
  const themeValue = THEMES[theme]?.[tokenKey];
  if (themeValue !== undefined) return themeValue;
  const neutralValue = NEUTRAL[style][tokenKey];
  if (neutralValue !== undefined) return neutralValue;
  return THEMES["aurora"]![tokenKey]; // fallback = thème par défaut (unique à couvrir tout)
}
```

Les composants **n'appellent jamais** `resolveToken` directement — ils lisent les
tokens **sémantiques** §2.1.2 (couche 2), et c'est le **provider React**
(`<AuroraThemeProvider theme={…} preset={…} style={…}>`) qui résout les valeurs
à la racine et les **injecte en CSS custom properties** (§5 : « JSON source → CSS
custom properties → TS typed wrapper »). Le preset **s'applique dans** la résolution
(pas après : le High Contrast re-lifté **doit** passer par le theme *avant* d'être
comparé au seuil 7:1, sinon le re-lift ne se voit pas, §5.5).

- **Adaptations locales (niveau 3, §5.2)** : chaque module/feature **déclare** dans
  son Contract Pack (AD-13) quelles adaptations il supporte, **déclarativement**
  (token → valeur), par ex. :

```yaml
# Contract Pack — Focus Module (pack 04 §4)
localThemeAdaptations:
  - token: surface.secondary
    value: "attenuated"   # surfaces secondaires plus calmes en Focus
  - token: focus.ring
    value: "enhanced"     # focus ring renforcé
```

  L'adaptation est **déclarative** (token → valeur), **jamais** un code branché
  (`if (focusMode) return GREEN` = violation AD-13, **rejet** en review :
  c'est le motif même du §5.10).
- **Règle §5.1 bloquante en review** : un PR qui modifie un des 4 tokens
  sémantiques (`success` / `warning` / `danger` / `info`) **ou** un des
  3 tokens nœuds (`node-mastered` / `node-fragile` / `node-forgotten`) dans un
  fichier `themes/*.json` = **rejet immédiat** (Codex review, doc §21.6 ; le linter
  §5.4 **bloque** le commit en local si le JSON touche un token de la liste
  blanche sémantique §5.1).

### 5.9 Accessibilité (complément du §6 du pack d'origine)

- **Contraste (normatif)** : chaque `thème × style neutre` doit respecter WCAG AA
  (4.5:1 texte normal, 3:1 texte large/UI) **pour les couleurs d'accent SUR les
  surfaces du style neutre** — le thème n'est **jamais** seul en jeu : c'est
  `thème × style neutre` qui est testé (ex. accent Vesper `#6554C0` sur surface
  Dark `#1E1E1E` = ratio **à vérifier**, pas sur fond clair). Le tableau de
  ratios §5.4 est le **mininum normatif** (vérifié, valeurs ci-dessus) : tout
  thème **ajouté** au catalogue doit **passer** ce tableau (le linter §5.4,
  §5.8 — le ratio est **calculé**, pas « supposé »).
- **Les 4 rôles (c1–c4) ont chacun leur test** : `primary` ≥ 3:1 (élément UI) sur
  le canvas du style courant (§5.4 tableau : les 2 valeurs sous seuil — Solara
  light, Citrus light — déclenchent le **fallback tonal** §5.4, c'est le
  contrat, pas un bug) ; `highlight` ≥ 13:1 avec l'encre du style (tableau
  §5.4, vérifié) ; `secondary`/`punctual` = libres (c'est du **décor**, pas du
  texte — le seuil ne s'applique qu'au texte, §2.1.2 : les accents ne sont
  **jamais** le seul porteur d'information, règle §5.10 : une info **doit**
  aussi être dans le texte/la forme, pas seulement dans la couleur).
- **Focus** : le `focusTreatment` de chaque thème (§5.4) doit être visible sur les
  **deux** styles neutres (test contrastuel light + dark — le ring Vesper en dark
  = `#E7DDF8` 14.36:1, tableau §5.4 ; un ring < 3:1 = le thème **échoue** au
  test §5.7 sur **tous** les écrans, verdict « à ajuster » automatique).
- **Réduction de mouvement (AD-10 / §2.6)** : chaque `motionMood` (§5.4) doit
  avoir un mode « réduit » (désactivable, `prefers-reduced-motion` §2.6 —
  Citrus 100ms → `instant` ; Lagoon spring doux → `instant` : le reduced-motion
  **efface** le mood, pas le « ralentit » — c'est un **switch**, pas un slider,
  §2.6 règle 2).
- **High Contrast preset (§5.5)** : pour les utilisateurs qui ont besoin de
  contrastes renforcés, **indépendamment** du thème choisi (le preset est
  **orthogonal** au thème : un utilisateur « Cosmos + High Contrast » existe,
  §5.6) — le seuil 7:1 **remplace** le seuil AA du thème (le preset est une
  **override d'accessibilité**, pas un thème de plus, §5.5).
- **Tap targets** : 44×44px minimum partout (§6 du pack d'origine ; pack 04 §6 :
  la cible mobile est **une main**) ; preset High Contrast = 56×56px (le
  **seul** cas où la taille change : l'accessibilité forcée **élève** le seuil,
  ne le diminue pas).

### 5.10 Ce que ce système **n'est PAS**

- **Pas** un thème qui change de couleurs par module : « Normal = bleu, Focus =
  vert, Study = orange » = **interdit** (§5.2 niveau 3 : adaptation locale
  **déclarative** (token → valeur), pas un autre thème — le thème est **un**,
  l'adaptation est **locale** ; si 3 modules veulent 3 couleurs **différentes**
  en permanence, ce sont 3 **thèmes distincts**, pas 1 thème « multi » — le
  multi-thème **dans** un module = la confusion que §5.2 niveau 3 interdit).
- **Pas** une palette aléatoire : chaque thème a une **logique de couleur
  motivée** (§5.4) — l'univers visuel **précède** les couleurs, pas
  l'inverse (un thème qui commence par « 3 couleurs qui me plaisent » =
  **rejet** au test §5.7, il n'a pas de logique, donc pas de verdict « bien »
  possible).
- **Pas** un système qui brouille la sémantique : `success/warning/danger/info`
  **restent stables** sous tout thème (§5.1, règle **bloquante en review**
  §5.8 — le linter local + le review Codex, 2 portes).
- **Pas** un changement de code : les 10 thèmes = 10 fichiers JSON + 1 fichier
  `resolve.ts` + 1 provider React (§5.8), le code des **composants** reste
  **identique** quel que soit le thème choisi (AD-13 : le composant ne **sait
  pas** quel thème est actif — il lit les tokens sémantiques, le provider a
  déjà résolu, c'est la **règle de portabilité** doc §23.2 : le DS est pur
  React + tokens, **aucun** import Capacitor/Electron, Phase 2 Electron =
  **les mêmes** 13 JSON + resolve.ts, §23.4).
