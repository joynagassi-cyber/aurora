---
name: "Aurora — Pack 05 Design System (tokens, composants, contrats AD-10, inventaire des écrans)"
type: dimension-pack
altitude: initiative
companion-of: ARCHITECTURE-SPINE.md (autorité, read-only)
sources:
  - ARCHITECTURE-SPINE.md (AD-1…AD-16, statut final, 2026-09-21)
  - adr-extract.md (ADR v1.7 gelé — §12 principe final, §14 arbre sémantique, §16 visualisation, §25 stack visuelle)
  - 02-frontend.md (contrats de CONSO des renderers AD-10 §5, états UX canoniques §7, routing §6)
  - 04-mobile.md (Focus Controller §4, contraintes perf batterie §6)
status: wave-0-draft
created: 2026-09-21
owner: Design System team (une seule équipe écrit `packages/ui` — AD-13)
binds: "packages/ui (source de vérité du DS)"
consumes: ["packages/domain (types AD-15)", "ARCHITECTURE-SPINE.md (AD-x read-only)"]
consumers: ["02-frontend.md (apps/mobile compose le DS)", "04-mobile.md (contraintes plateforme)"]
adRefs: [AD-1, AD-3, AD-6, AD-7, AD-8, AD-9, AD-10, AD-11, AD-12, AD-13, AD-14, AD-15, doc §12, doc §14, doc §25]

# G1 (02-frontend.md R8/G1) — RATIFICATION : ce pack **ratifie** (a) le choix **Zustand** pour
# l'UI state (02 §3.1) et (b) les **signatures de CONSO** des contrats AD-10 (02 §5.1–5.5) :
# section 3.6 ci-dessous définit les **implémentations** (DEF) de ces contrats ; les props d'entrée
# (RenderSemanticNode, ChartSpec, LaTeX string, RevealKey…) sont **identiques** aux signatures 02 §5.
# Toute divergence = ADR porté par ce pack (spine §162 : breaking = dedicated PR + mandatory Codex review).
g1-ratification:
  zustand: ratified
  ad10-consumption-signatures: ratified  # 02 §5.1–5.5 = spec de CONSO ; ce pack §3.6 = DÉF/impl
  signed: "Design System team lead"
  deadline: "avant découpe vague 1 UI (gating 02 R8)"

---

# 05 — PACK DESIGN SYSTEM (`packages/ui`)

> **Position du pack** : `packages/ui` est la **source de vérité** du Design System Aurora (AD-13,
> matrice doc §21.2 : « Design System → packages/ui et tokens »). Ce pack **définit** : la direction
> de design, les tokens (light + dark), la bibliothèque de composants avec leurs états (AD-13 :
> loading/empty/success/error/offline), les **implémentations** des 5 contrats AD-10 (behind-the-
> scenes : `@xyflow/react`, `@antv/*`, KaTeX, `motion` — AD-1 : les moteurs ne sont jamais importés
> par le domaine), et l'**inventaire écran par écran** (44 écrans, doc §2–§18 + §13 + §18).
>
> Ce pack **consomme** les signatures de **consommation** de `02-frontend.md` §5 (ratification G1
> ci-dessus) ; **approfondit** `04-mobile.md` §4 (Focus) et §6 (batterie) là où le DS doit s'adapter.
> Les AD-x du spine sont contraignantes et read-only. Contenu en français ; identifiants/tokens/
> props en anglais. **Prescriptif** : « Le Button primary est… », pas « il faudrait… ».
>
> **Note SPEC (gating)** : ce pack **existe et doit être ratifié** (G1 frontmatter ci-dessus)
> **avant** que la vague 1 UI commence (règle 02 R8/G1, AD-13 : Contract Pack complet AVANT le
> coding parallèle). Les 5 signatures AD-10 (02 §5.1–5.5) sont **ratifiées ici** ; l'inventaire
> des écrans (section 4) est **porté par ce pack** ; le Home AD-14 (7 items fixes) = section 4.1.2.

---

## 1. Direction de design — « Technical Calm »

**Direction nommée : *Technical Calm* (« calme technique »).**

C'est une direction **motivée** pour la cible (étudiante / jeune ingénieure en formation, génie
civil, usage intensif mobile, sessions de concentration nocturnes, §12 + AD-14) :

- **Lisibilité technique d'abord** : la cible lit des formules, des unités, des schémas et des
  tableaux de données **longuement**. La hiérarchie typographique est construite pour la lecture
  dense (mono pour les valeurs, échelle sur grille 8px, contraste élevé §6). Pas de décor qui
  concurrence la donnée.
- **Calme pour la concentration** : l'app est aussi un outil de **focus** (doc §2.8, Focus
  Controller pack 04 §4) et de **coaching non-intrusif** (ADR §13 : « privilégier la pertinence
  contextuelle, respecter les périodes de silence »). La palette est **basée sur des surfaces
  neutres très claires** (light) / **fond quasi-noir** (dark, 1ʳᵉ classe pour les sessions
  nocturnes) ; les couleurs vives (danger/success/primary) sont **réservées aux sémantiques**,
  jamais décoratives. Un écran qui « brille » perturbe ; un écran qui respire concentre.
- **Densité informationnelle progressive** (principe §12 : « simple en surface, puissante en
  profondeur ») : les listes sont **aérées** par défaut (1 ligne par item, `ListItem` dense
  option off), les détails (Gantt, arbre sémantique, dashboards) **révèlent** la complexité
  à la demande (drill-down, BottomSheet, zoom React Flow). L'accueil (AD-14) n'est **jamais**
  un tableau de widgets — une seule question : « Qu'est-ce qui compte maintenant ? ».
- **Mobile-only Phase 1** : les composants sont pensés pour une main (thumb-zone bas d'écran),
  des tap targets 44px+ (Material 40px+ / iOS HIG 44px ; on standardise à **44px**, §6),
  et des transitions **naturelles** (glissement latéral = liste→détail, montée = sheet).
- **Pas de style « générique SaaS » ni « glassmorphism » ni « brutaliste »**. L'AD-14 interdit
  explicitement le dashboard de widgets ; §12 interdit l'empilement de fonctionnalités visibles.
  Le DS *Technical Calm* est la **traduction visuelle** de ces deux interdictions.

**Contrainte de portabilité (doc §23.2)** : les composants `packages/ui` sont **purs React +
tokens** — aucun import Capacitor/Electron (§23.2). La Phase 2 Electron **réutilise** ce pack
sans réécriture (doc §23.4). Les tokens light/dark sont **les mêmes** sur les deux plateformes
(§23.2 : « les responsabilités frontend doivent être clairement séparées »).

**Règle finale de section** : toute décision de design qui **contradict** AD-14 (un widget
dashboard sur l'accueil), §12 (empilement de features visibles), ou §2.8 (blocage natif promis
pack 04 §4.1) = **rejet blocking** en review (AD-13 DoD).

---

## 2. Fondations (design tokens + règles)

> Les tokens sont **déclarés en 2 couches** (JSON source → CSS custom properties → TS typed
> wrapper, §5). Tout composant `packages/ui` **consomme** les tokens, **jamais** de valeur
> hardcodée (règle 02-frontend §8 : « Toute valeur hors token = blocking finding »).

### 2.1 Palette (light par défaut, dark 1ʳᵉ classe)

**Règle** : chaque token a **un nom sémantique** (`aurora.color.surface`), **jamais** une valeur
brute dans un composant. Le **dark mode est un 1ʳᵉ classe** (justification cible : sessions de
concentration nocturnes, §2.8 ; le génie civil = travail de bureau + terrain, la cible étudie le
soir ; le contraste light/dark est **équilibré** dès la vague 1, pas un « add-on »).

#### 2.1.1 Primitives (la nuance brute — 2 niveaux de gamme par couleur, 50–900)

> Les primitives `aurora.color.{hue}.{50..900}` sont **seules** le « nuancier brut ». Les
> composants **n'y ont jamais accès directement** — ils utilisent les tokens **sémantiques**
> (§2.1.2). Les valeurs ci-dessous sont **normatives pour la vague 1** ; toute évolution
> = ADR (spine : versionning des décisions).

| Hue | 50 | 100 | 300 | 500 | 700 | 900 | Rôle |
|---|---|---|---|---|---|---|---|
| `indigo` (primary) | `#EEF0FF` | `#DDE1FF` | `#9AA4F4` | `#4F5AE8` | `#2E3AC4` | `#1B2280` | Identité, focus, CTA principal |
| `teal` (secondary) | `#E6FBF7` | `#C7F5EE` | `#5ED8C3` | `#14B8A6` | `#0F766E` | `#0B4A44` | Apprentissage, flashcards, FSRS |
| `amber` (warning) | `#FFF4E0` | `#FFE4B8` | `#FFB84C` | `#F59E0B` | `#B45309` | `#7C3A08` | Alertes douces, « à surveiller » |
| `red` (danger) | `#FEECEC` | `#FBCFCF` | `#F87171` | `#EF4444` | `#B91C1C` | `#7F1D1D` | Erreur, destructif, « oublié » |
| `emerald` (success) | `#E8FAF0` | `#C6F0D8` | `#6EE7B7` | `#10B981` | `#047857` | `#064E3B` | Succès, « maîtrisé », complet |
| `sky` (info) | `#EAF5FF` | `#CDEBFF` | `#7CC4F8` | `#0EA5E9` | `#0369A1` | `#083B5C` | Infos neutres, tooltips, liens |
| `violet` (learning) | `#F3E8FF` | `#E4D1FF` | `#C4A7F5` | `#8B5CF6` | `#6D28D9` | `#4C1D95` | Compétences, skill-map |
| `slate` (neutral) | `#F8FAFC` | `#E2E8F0` | `#94A3B8` | `#475569` | `#1E293B` | `#0F172A` | Surfaces, texte, bordures |

#### 2.1.2 Tokens sémantiques (LIGHT — thème par défaut)

| Token (nom sémantique) | Valeur | Rôle |
|---|---|---|
| `aurora.color.primary` | `indigo.500` `#4F5AE8` | CTA principal, lien actif, focus ring |
| `aurora.color.primary-surface` | `indigo.50` `#EEF0FF` | Fond de chip/tag « priority », sélection |
| `aurora.color.on-primary` | `slate.50` `#FFFFFF` | Texte sur `primary` |
| `aurora.color.success` | `emerald.500` `#10B981` | Statut success, « maîtrisé » |
| `aurora.color.success-surface` | `emerald.50` | Fond de Callout success |
| `aurora.color.warning` | `amber.500` `#F59E0B` | Statut warning, « fragile » |
| `aurora.color.warning-surface` | `amber.50` | Fond de Callout warning |
| `aurora.color.danger` | `red.500` `#EF4444` | Statut error, « oublié », destructive |
| `aurora.color.danger-surface` | `red.50` | Fond de Callout danger |
| `aurora.color.info` | `sky.500` | Lien secondaire, info |
| `aurora.color.learning` | `violet.500` | Skill-state, apprentissage |
| `aurora.color.bg` | `slate.50` `#F8FAFC` | Fond de l'app (light) |
| `aurora.color.bg-subtle` | `slate.100` | Fond de section alternée |
| `aurora.color.surface` | `#FFFFFF` | Fond de Card, BottomSheet |
| `aurora.color.surface-alt` | `slate.50` | Fond de row alternée, input disabled |
| `aurora.color.surface-overlay` | `rgba(255,255,255,0.85)` | Fond de Modal, Drawer (flouté) |
| `aurora.color.text-primary` | `slate.900` `#0F172A` | Titre, corps principal |
| `aurora.color.text-secondary` | `slate.700` `#334155` | Corps secondaire, métadonnées |
| `aurora.color.text-muted` | `slate.400` `#94A3B8` | Placeholder, timestamp, caption |
| `aurora.color.text-disabled` | `slate.300` | Texte des éléments disabled |
| `aurora.color.border` | `slate.200` `#E2E8F0` | Bordure par défaut |
| `aurora.color.border-strong` | `slate.300` | Bordure de focus (visible), divider heavy |
| `aurora.color.focus-ring` | `indigo.300` `#9AA4F4` | Ring de focus (2px, §6) |
| `aurora.color.skeleton` | `slate.100` | Fond des `Skeleton` (shimmer léger) |
| `aurora.color.node-mastered` | `emerald.500` | `SkillStateBadge` / `SemanticTreeNode` **mastered** |
| `aurora.color.node-fragile` | `amber.500` | **fragile** (doc §14 vue de progression) |
| `aurora.color.node-forgotten` | `red.500` | **forgotten** (doc §25.3 NodeState) |
| `aurora.color.habit-weak` | `slate.200` | `HabitStreak` 1/5 (heatmap GitHub-like, 5 niveaux) |
| `aurora.color.habit-med` | `indigo.300` | 3/5 |
| `aurora.color.habit-strong` | `indigo.500` | 5/5 |

#### 2.1.3 Tokens sémantiques (DARK — 1ʳᵉ classe, sessions nocturnes §2.8)

| Token | Valeur | Note |
|---|---|---|
| `aurora.color.primary` | `indigo.300` `#9AA4F4` | Plus clair : le `indigo.500` est **insuffisant en contraste** sur fond dark (ratios §6) |
| `aurora.color.primary-surface` | `indigo.900` `#1B2280` | |
| `aurora.color.success` | `emerald.400` `#34D399` | |
| `aurora.color.danger` | `red.400` `#F87171` | |
| `aurora.color.warning` | `amber.400` `#FBBF24` | |
| `aurora.color.bg` | `#0A0E1A` | **Quasi-noir bleuté** (pas `#000` : évite le « banding » sur OLED, §2.8 concentration) |
| `aurora.color.bg-subtle` | `#0F1524` | |
| `aurora.color.surface` | `#151C2C` | |
| `aurora.color.surface-alt` | `#1B2438` | |
| `aurora.color.surface-overlay` | `rgba(21,28,44,0.88)` | |
| `aurora.color.text-primary` | `slate.100` `#F1F5F9` | |
| `aurora.color.text-secondary` | `slate.400` | |
| `aurora.color.text-muted` | `slate.500` | |
| `aurora.color.text-disabled` | `slate.600` | |
| `aurora.color.border` | `slate.700` `#334155` | |
| `aurora.color.border-strong` | `slate.500` | |
| `aurora.color.focus-ring` | `indigo.400` `#818CF8` | |
| `aurora.color.skeleton` | `#1B2438` | |
| `aurora.color.node-*` | `emerald.400` / `amber.400` / `red.400` | Toujours **la nuance 400** en dark (pas 500, contraste §6) |

**Règle de non-surprise (motivée par le pack 04 §6.1 : « retour foreground = re-sync, pas de
crash »)** : le thème est **persisté** (store UI pack 02 §3.2, `persist` middleware) ; **jamais**
un thème qui **change** silencieusement au retour foreground. Le switch auto (système /
heure / manuel) est **exposé explicitement** dans `/settings` (section 4), avec un **aperçu**
du résultat. **Jamais** un flash light/dark au boot (boot = thème persisté ; le recompute
auto = **différé** au premier mount de `/settings`, pas au boot).

### 2.2 Typographie

**Famille principale : `Inter`** (variable, `woff2`, 400–700). **Motivation** : (a) **excellente
lisibilité** pour le corps technique (génie civil = beaucoup de corps dense) ; (b) **gratuite,
self-hosted** (pas de CDN — offline-first AD-7 : les fonts sont **embarquées** dans le bundle,
pas fetchées à l'app ; le budget « 300 Ko JS gz » pack 02 §9.1 est respecté car les fonts =
assets séparés ~60 Ko woff2 pour Inter 400/600/700 variable) ; (c) **variable font** = 1 fichier
au lieu de 5 (moins de requests, meilleure perf mobile pack 04 §6.2) ; (d) **fallback** :
`system-ui` (Android = Roboto, iOS = SF Pro).

**Famille mono : `JetBrains Mono`** (variable, woff2 ~80 Ko) pour **les formules, unités,
valeurs, code, identifiants techniques** (doc §15 : les formules sont **au centre** du produit
génie civil). Motivation : les chiffres alignés (`tabular-nums` ON), la lisibilité de `M³`,
`kN·m`, `∂u/∂x` est **critique** ; Inter seul rend les unités « ambigües » (ex. `1` vs `l`).

**Échelle (base 16px, ligne de base 8px — la grille verticale du DS, §2.3)** :

| Échelon | px | rem | Usage |
|---|---|---|---|
| `xs` | 12 | 0.75 | Caption, metadata, timestamp, badge |
| `sm` | 14 | 0.875 | Corps secondaire, ListItem subtitle |
| `base` | 16 | 1 | Corps principal (règle de base, §6 WCAG) |
| `md` | 18 | 1.125 | Titre de section (Card title) |
| `lg` | 20 | 1.25 | `StatTile` value, `h4` |
| `xl` | 24 | 1.5 | `h3`, titre de BottomSheet |
| `2xl` | 32 | 2 | `h2`, titre de Card focus |
| `3xl` | 40 | 2.5 | `h1` (onboarding, splash) — **rare** sur mobile |

**Poids** : `400` (corps), `500` (labels, `Badge`), `600` (sous-titres de section), `700` (titres
de page uniquement). **Inter 300 est interdit** (lisibilité dégradée sur Android mid-range,
pack 04 G5 ; le « light weight » = **luxe desktop**, pas mobile).

**Hiérarchie des titres (normative)** : un écran **n'a qu'UN `h1`** (le titre de l'écran, dans
le `TopBar` en `md/lg` pas `2xl` — le `h1` mobile est **compact**, le titre 2xl = réservé à
l'onboarding/splash). Les `h2`/`h3` = sections de contenu. **Jamais** un titre plus grand que
le titre de l'écran (anti-pattern « dashboard de widgets », AD-14).

**Règles de ligne** : `line-height` = `1.45` (corps), `1.2` (titres) ; `letter-spacing` =
`0` (pas de tracking artificiel, lisible sur petits écrans) ; les **unités et valeurs techniques**
= **toujours** `JetBrains Mono` + `font-variant-numeric: tabular-nums` (ex. « 25,4 kN·m ») —
c'est la règle de lisibilité n°1 du domaine génie civil.

### 2.3 Spacing (grille 4/8px)

**Échelle normative** : `2, 4, 8, 12, 16, 24, 32, 48, 64` px (step 4, « step de confort » 8).

| Token | px | Usage |
|---|---|---|
| `aurora.space.0.5` | 2 | Gap intra-icône (icône + label dans un IconButton) |
| `aurora.space.1` | 4 | Padding minimal de Chip/Badge (horizontal) |
| `aurora.space.2` | 8 | Padding interne de `ListItem`, gap entre badges |
| `aurora.space.3` | 12 | Padding de `Button` (vertical), gap entre `StatTile` (grille 2×2) |
| `aurora.space.4` | 16 | Padding de `Card`, gap entre `Card` dans une liste |
| `aurora.space.6` | 24 | Padding de `BottomSheet`/`Modal` (contenu), section gap |
| `aurora.space.8` | 32 | Spacing entre sections d'un écran |
| `aurora.space.12` | 48 | Marges latérales d'un écran **large** (rare sur mobile) |
| `aurora.space.16` | 64 | Spacing du Hero/Splash uniquement |

**Règle d'usage** : (a) le **padding interne** d'un composant suit **son échelon** (Button = `3`,
Card = `4`, Modal = `6`) ; (b) le **gap entre composants** suit l'échelon **supérieur** (gap entre
Cards = `4` ; gap entre sections = `6`/`8`) ; (c) **jamais** de valeur hors échelle (ex. `10px`,
`18px`) — le linter `stylelint` le bloque (CI, §7). (d) Sur mobile, les marges latérales
d'écran = `16px` (token `space.4`) **fixes** — jamais responsive en V1 (mobile-only, doc §23.1).

### 2.4 Coins & élévations

**Radius (normatif)** :

| Token | Valeur | Usage |
|---|---|---|
| `aurora.radius.sm` | 4px | `Badge`, `Chip`, `ProgressBar` (interne) |
| `aurora.radius.md` | 8px | `Button`, `TextField`, `ListItem`, `Card` (default) |
| `aurora.radius.lg` | 12px | `Modal`, `Drawer` (coins hauts), `FAB` (carré) |
| `aurora.radius.xl` | 16px | `BottomSheet` (coins hauts), `FlashcardCard` (recto/verso) |
| `aurora.radius.full` | 9999px | `Avatar`, `ProgressRing`, `Toggle` (thumb) |

**Règle** : le radius **augmente avec la taille de surface** (un `Chip` = 4px, une `BottomSheet`
= 16px). **Interdit** : un radius incohérent (ex. une Card à 20px, un Button à 6px) — c'est la
règle de la cohérence *Technical Calm*. Les **coins bas** des `BottomSheet` = `0` (plein écran
ou arrondi en haut seulement) ; les `Modal` = 12px haut/bas (une modale mobile est une
fenêtre, pas un sheet).

**Élévations / ombres (4 niveaux, motivées)** :

| Token | Valeur | Usage |
|---|---|---|
| `aurora.shadow.1` | `0 1px 2px rgba(15,23,42,0.06)` | `Card` par défaut, `ListItem` (effet « au-dessus du fond ») |
| `aurora.shadow.2` | `0 4px 8px rgba(15,23,42,0.10)` | `FAB`, `StatTile` (élévation modérée) |
| `aurora.shadow.3` | `0 8px 16px rgba(15,23,42,0.14)` | `Modal`, `Drawer`, `Menu` ouvert (élévation forte) |
| `aurora.shadow.4` | `0 16px 32px rgba(15,23,42,0.20)` | `BottomSheet` (toujours **au-dessus** de tout) |

**Règle dark mode (motivée)** : en dark, les **ombres ne se voient pas** (fond noir = l'ombre
est invisible) ; le DS remplace `shadow.1` par une **bordure 1px** (`aurora.color.border`)
+ un fond `surface` **plus clair** que `bg` (le « niveau de surface » remplace l'élévation,
principe Material Dark). Le linter vérifie : en mode dark, **aucun composant** n'utilise
`shadow.*` pour sa hiérarchie — il utilise les **surfaces** (`surface` > `bg` > `bg-subtle`).

### 2.5 Icônes

**Fournisseur : Ionicons** (motivation prescriptive) : (a) **natif Ionic** — le framework du
pack (Ionic React) **livre** `@ionic/react` avec les icônes intégrées ; **zéro dépendance
supplémentaire** (le budget 300 Ko pack 02 §9.1 compte) ; (b) **style cohérent** avec la
plateforme mobile (les icônes Android/iOS sont déjà stylées par Ionicons selon le device) ;
(c) **2 styles** : `fill` (default, plus lisible sur les petits écrans — **celui qu'on utilise
par défaut**) et `outline` (option, pour les écrans de détail où la densité est faible).

**Règles** :
- Taille : `24px` (default), `20px` (dans un `Button` avec texte), `16px` (dans un `Chip`).
  **Jamais** en dessous de 16px (lisibilité mobile, §6 tap target 44px → l'icône doit tenir
  dedans avec du padding).
- Nom : nomenclature `ic-{concept}-{variante}` (ex. `ic-task-check`, `ic-task-blocked` ;
  `ic-focus-timer`, `ic-focus-off`) — la nomenclature suit le **domaine**, pas le fournisseur
  (on peut changer d'icônes sans toucher les composants : les noms sont **indépendants** du
  set). Les icônes **domaine** (task, focus, skill, tree, discovery) = **créées** dans
  `packages/ui/src/icons/` (SVG inline, non Ionicons) — c'est **seulement** là que le DS
  permet des icônes custom (AD-13 : une seule équipe écrit ces SVG).
- **Interdiction** : ne **jamais** utiliser Ionicons pour une icône de **domaine** (ex. un
  « nœud d'arbre sémantique » = une icône custom `ic-tree-node` dans le DS, pas un Ionicon
  générique) — les icônes de domaine = identité du produit, pas du framework.

### 2.6 Animation (contrats AD-10 `motion` + règles)

**Durées & courbes (normatives, pack 04 §6.2 : « pas de sur-animation = pas de batterie »)** :

| Token | Valeur | Usage |
|---|---|---|
| `aurora.anim.fast` | 150ms | Micro-interactions (toggle, chip, hover) — **courbe `ease-out`** |
| `aurora.anim.normal` | 250ms | Ouverture de `Modal`, `BottomSheet`, transition page — **courbe `ease-out`** |
| `aurora.anim.slow` | 400ms | Révélation progressive (formula, step, branch) — **courbe `spring`** (`stiffness: 200, damping: 25`) |
| `aurora.anim.instant` | 0ms | **Réduction de mouvement ON** (tout passe ici, §6) |

**Règles prescriptives** :

1. **Ce qui ne doit PAS être animé** (règle doc §25.5 / AD-11 « fidélité pédagogique ») :
   **les données scientifiques**. Un `ChartSpec` G2 qui **affiche** une valeur (ex. « 25,4 kN·m »)
   **ne scintille pas, ne ne compte pas** (pas d'animation « compteur » 0→25,4). La donnée =
   vérité, pas effet. Seuls les **conteneurs** s'animent (la Card apparaît), jamais la **valeur**
   qu'elle contient. Même règle : un `MathBlock` (KaTeX) **ne se trace pas** lettre par lettre
   (sauf `AnimationController.reveal('formula')` explicite, §3.6.5 — c'est la **révélation
   pédagogique** du §25.8, un choix conscient, pas un décor).
2. **Réduction de mouvement** (`prefers-reduced-motion`, §6 accessibilité) : le DS expose
   `useReducedMotion()` (hook dans `packages/ui`) ; **toute** animation `slow`/`normal` →
   `instant` si `prefers-reduced-motion: reduce`. `AnimationController.setReducedMotion(on)`
   (contrat §3.6.5) **doit** être appelé au boot par l'app (pack 02 §5.5). C'est **obligatoire**
   (AD-13 DoD, pack 02 §11).
3. **Focus Mode** (doc §2.8, pack 04 §4) : quand `focusMode=true` (store UI pack 02 §3.2),
   le DS **désactive** toutes les animations `slow` (révélation), **diffère** les toasts
   (jamais pendant un pomodoro), et passe les transitions page en `fast` → `instant` (pack
   02 §9.3 : « les micro-interactions sont réduites »). C'est un **état de perf par design**
   (règle pack 02 §9.3).
4. **Jamais** une animation qui **bloque l'input** (pas de « spinner plein écran » qui
   empêche de lire le contenu local pendant que le cloud sync — AD-7 : le local est **d'abord**
   lisible, la sync est en arrière-plan). Le `Skeleton` **pulse** doucement (opacity 0.6→1,
   1.2s, **pas** un « shimmer » agressif) — il signale « en cours » sans agacer.

---

## 3. Composants (bibliothèque `packages/ui`, états AD-13)

> **Règle transversale (normative, AD-13)** : **tout** composant `packages/ui` **expose** les
> 5 états UX canoniques (pack 02 §7 : `loading / empty / success / error / offline`) **sauf**
> ceux qui **n'ont pas d'état** (ex. `Divider`, `Breadcrumb`). Un composant **sans** l'un des
> 5 états requis = **blocking review finding** (pack 02 §11 : « 1 test par état »). Les
> **composants de donnée** (DataTable, GanttRow, Sparkline…) sont des **wrappers des
> contrats AD-10** (§3.6) — **jamais** une réimplémentation du moteur (AD-1/AD-10 : le moteur
> est l'implémentation, le composant est le contrat ; AD-13 : « ne pas créer d'abstraction
> parallèle quand un contrat existe »).

**États obligatoires par composant (matrice AD-13)** : `default / hover / pressed / focus /
disabled / loading / empty / error / offline` — un composant n'implémente **que les états qui
ont du sens** (ex. `hover` n'existe pas sur Android, mais le DS le **déclare** pour la Phase 2
Electron, doc §23.2 ; `offline` = le composant **reste utilisable** pour la lecture locale,
AD-7). La **matrice d'état par composant** est en annexe A (un tableau par composant, 5 états
+ les états intermédiaires hover/pressed/focus/disabled).

### 3.1 Actions

#### `Button`
- **Rôle** : CTA principal d'un écran (jamais plus de 1 `Button primary` par écran — AD-14 :
  l'écran a **une** action dominante).
- **Variantes (normatives)** :
  - `variant="primary"` : fond `aurora.color.primary`, texte `on-primary`. Le seul bouton qui
    « saute » à l'œil. **Max 1 par écran.**
  - `variant="secondary"` : fond `surface`, bordure `border-strong`, texte `text-primary`.
    L'action « normale » (sauvegarder, confirmer).
  - `variant="ghost"` : fond transparent, texte `text-secondary`. Action tertiaire (« passer »,
    « annuler »). Ne se **met jamais** côte-à-côte de `primary` sans espacer ≥ `space.2`.
  - `variant="destructive"` : fond `danger-surface`, texte `danger`. **Obligatoirement**
    confirmé par un `Modal` (jamais un destructive sans confirmation — règle de non-surprise,
    §6 accessibilité : une action irréversible **doit** demander).
- **Tailles** : `sm` (32px, dans un `ListItem`), `md` (44px, **default**, = tap target §6),
  `lg` (56px, CTA d'un `EmptyState` ou `Modal`).
- **États** : `default / pressed (fond scintille, `anim.fast`) / focus (ring 2px `focus-ring`,
  §6) / disabled (fond `surface-alt`, texte `text-disabled`, **pas** de pressed) / `loading`
  (le label est **remplacé** par un `ProgressRing` 16px **dans** le bouton, pas un spinner
  externe — l'utilisateur **sait** où c'est ; `aria-busy` présent). **Jamais** un button
  `loading` qui **désactive** tout l'écran (le reste reste interactif, AD-7).
- **Props essentielles** : `variant`, `size`, `icon?: IconName`, `iconSide?: 'left'|'right'`,
  `loading?: boolean`, `onPress`, `disabled`, `aria-label` (obligatoire si `icon` sans texte).
- **Règle d'espacement** : deux boutons côte-à-côte = `ghost` + `primary` (le `ghost` **à
  gauche**, le `primary` **à droite** — le pouce droit = action positive, §1 « mobile 1 main »).

#### `IconButton`
- **Rôle** : action contextuelle (supprimer une tâche, ouvrir un menu) **sans** label texte.
- **Règles** : **toujours** un `aria-label` (test CI, §7). Taille **44×44px** (tap target §6),
  icône 20px **centrée** (pas de « coin de l'écran »). Variantes : `default` (fond transparent,
  icône `text-secondary`), `tonal` (fond `bg-subtle`, icône `text-primary`), `destructive`
  (icône `danger` — **confirmé** par `Modal`, comme `Button destructive`).
- **Interdiction** : un `IconButton` **isolé** sans `aria-label` = CI rouge (a11y, §6).

#### `FAB` (Floating Action Button)
- **Rôle** : l'action **dominante** de l'écran (une seule FAB par écran, **max 1** — si 2
  actions dominantes, ce n'est plus une FAB, ce sont 2 boutons dans le footer). Position :
  **bas-droit**, au-dessus du `BottomNav` (si présent) ou du safe-area.
- **Variantes** : `default` (56px circulaire, icône `on-primary`), `extended` (FAB + label,
  ex. « Nouvelle tâche », fond `primary`), `mini` (40px, contexte de liste). **Interdit** :
  un FAB dans un écran **déjà** saturé (AD-14 : l'accueil **n'a pas** de FAB — l'accueil est
  calme ; le FAB vit dans les écrans de **création** : inbox, tâches, fiches).
- **États** : `default / pressed (scale 0.95, `anim.fast`) / focus / disabled / `loading`
  (icône → ProgressRing, **rare** : le FAB déclenche une action qui **retourne vite** — si
  c'est long, le FAB disparaît, l'écran gère l'état `loading` du contenu).

### 3.2 Formulaires

> **Règle transversale** : un champ = **un seul label visible** (pas de placeholder en
> double emploi — le placeholder = exemple, le label = nom du champ). Label **au-dessus**
> (jamais à l'intérieur) ; l'erreur est **inline** (sous le champ, `danger` + icône), jamais
> dans une `Toast`. Tous les champs **supportent** l'état `disabled`, `error`, `loading`
> (skeleton du label).

#### `TextField` / `TextArea`
- **Props** : `label`, `placeholder`, `value`, `onChange`, `error?: string`, `maxLength`,
  `type?: 'text'|'number'|'email'`, `inputMode?` (mobile : `decimal` pour les unités, `none`
  pour le LaTeX — le clavier `numeric` = essentiel pour les formules, doc §15).
- **`TextArea`** : **toujours** un compteur de caractères si `maxLength` défini ; la hauteur
  est **auto** (min 3 lignes) ; un bouton « étendre » (Fullscreen) si > 500 caractères.
- **`TextField` + unités** (doc §15) : le composant `UnitTextField` (wrapper DS, §3.6.4
  indirect) = `TextField` + un suffixe fixe (ex. `kN·m` en `JetBrains Mono`) — l'utilisateur
  ne tape **que le nombre**, l'unité est **fixe et explicite** (règle de non-surprise :
  « 25,4 » + suffixe `kN·m` ≠ « 25,4 kN·m est-ce compris ? »).
- **États** : `default / focus (border 2px `primary`, pas de saut de layout) / error
  (border `danger` + message inline) / disabled (fond `surface-alt`) / loading (label →
  Skeleton 8px, le champ est **verrouillé**, pas supprimé). **`offline`** : un TextField
  **toujours** fonctionne (la saisie locale = AD-7 ; la sync est différée, §3.6.4 note).
- **Interdiction** : un `TextField` qui **cache** le label quand le champ est vide
  (le label = **toujours** au-dessus, règle WCAG §6 — un placeholder **n'est jamais**
  un label accessible).

#### `Select` / `MultiSelect`
- **`Select`** : un `TextField` stylé en select (icône chevron, `aria-expanded`). L'ouverture
  = une `BottomSheet` (jamais un menu déroulant natif Android — le DS est **cohérent**,
  pas un « OS default »). Options = `ListItem` (44px tap). **Max 1 Select visible par
  formulaire** si > 8 options (au-delà = `MultiSelect` avec recherche).
- **`MultiSelect`** : un `Chip` **par option sélectionnée** (le chip est **removable**
  = tap sur le `×` 44px) + un `Button` « Ajouter » qui ouvre la `BottomSheet` de choix.
  **Règle** : un MultiSelect avec > 20 options **doit** avoir une **recherche** dans la
  BottomSheet (le scroll seul est **interdit** au-delà de 20 items, règle de non-surprise).
- **États** : `empty` = un `Select` sans options = un `EmptyState` inline (pas un select
  vide muet) ; `loading` = options = `Skeleton` × 5 (pas un spinner plein écran, §2.6).

#### `Checkbox` / `RadioButton`
- **Taille** : **44×44px** (tap target §6 ; le « visuel » = 24px, centré dans la zone).
  `Checkbox` = `success` quand cochée (pas `primary` — le « fait » = vert, la « priorité » =
  indigo, règle de séparation des sémantiques §2.1). `RadioButton` = `primary` quand actif.
- **Règle** : une liste de `RadioButton` = **exclusif** (pas de « aucun » si le domain le
  permet — le `null` = un choix explicite, pas l'absence de cocher).
- **États** : `loading` = le `Checkbox` est **verrouillé** (disabled + Skeleton du label si
  le label est dynamique) ; `error` = le `Checkbox` qui déclenche une mutation **échouée**
  → le checkbox **revient** à l'état précédent (règle de non-surprise : un tick qui
  disparaît silencieusement = interdit, pack 02 §7 état `error`).

#### `Toggle` / `Switch`
- **Rôle** : un **switch de préférence** (pas un action « destructive » — si c'est
  destructif, ce n'est pas un switch, c'est un `Button destructive` confirmé, §3.1).
  Exemple DS : « Dark mode », « Notifications Focus », « Rappels locaux ».
- **États** : `default (off) / on / disabled (fond `surface-alt`, thumb `text-disabled`)`.
  Un switch **jamais** avec un `loading` (un switch qui « tourne » = interdit ; si l'action
  du switch est **longue** (ex. active le sync background, pack 04 O4), le switch est
  **immédiat** (optimistic, AD-7 local-first) + une `Toast` de confirmation **différée**
  (pas bloquante).

#### `Slider`
- **Rôle** : un **ajustement continu** (ex. durée d'une session Focus 5–90min, pack 04 §4 ;
  difficulté d'un exercice, doc §3). **Jamais** une saisie de valeur précise (un Slider =
  un estimate, pas une entrée — si l'utilisateur doit taper « 25,4 », c'est un `UnitTextField`).
- **États** : le `Slider` **affiche toujours** la valeur courante (ex. `25 min`, `JetBrains
  Mono`, à droite du track, `xs`). `disabled` = track `surface-alt` + thumb `text-disabled`.
  `loading` = le track est **verrouillé** (pas de drag), la valeur affiche `—` (pas un
  Skeleton qui « clignote » — un slider qui pulse = agaçant, §2.6).

#### `DateField` / `DurationField`
- **`DateField`** : un `TextField` (lecture seule) qui **ouvre** un `BottomSheet` avec un
  **calendar picker** (Ionic `IonDatetime` stylé, **pas** le natif Android — cohérence DS).
  Le format d'affichage = **locale FR** (`jeu. 25 sept. 2026`) + un `xs` sous le champ
  (`dans 3 jours`, sémantique). **Interdiction** : un `DateField` qui **change de format**
  entre écrans (le format = **le même partout**, règle de non-surprise).
- **`DurationField`** : un `TextField` + un suffixe `min`/`h` (`JetBrains Mono`). **Jamais**
  un « 00:30:00 » (le format heure `HH:MM` est **interdit** pour une durée — le génie civil
  pense en « 2 h 30 », pas en « 02:30:00 », §2.2 lisibilité).
- **États** : `empty` = un `DateField` vide affiche « Choisir une date » (pas un `—` muet).

### 3.3 Affichage

> **Règle transversale** : un composant d'affichage **n'a pas** de CTA (pas de bouton
> « voir plus » **dans** le composant — le CTA vit **autour** du composant, pas dedans,
> §1 « simple en surface »). Un composant d'affichage **expose** son `data-state` (pack
> 02 §7) pour que l'écran **décide** de l'état, pas le composant.

#### `Card`
- **Rôle** : un **conteneur sémantique** (pas une « box grise » décorative). Une Card =
  **une seule idée** (pas un « dashboard card » qui mélange 5 stats — AD-14). Fond
  `surface`, `shadow.1`, radius `md`. Padding `space.4`. **Interdiction** : une Card
  **sans titre** (le titre = `md`, `text-primary`, en haut — le contenu qui commence sans
  titre = interdit, règle de lisibilité).
- **Variantes** : `default` (fond `surface`, shadow.1), `elevated` (shadow.2, pour une Card
  qui « pop » — **max 1 par écran**, ex. la « prochaine action importante » du Home AD-14),
  `flat` (pas de shadow, fond `bg-subtle`, pour une Card **dans** une liste dense).
- **États** : `loading` = Card avec `Skeleton` dedans (le contenu est **skeleton**, pas un
  Card vide qui « pulse ») ; `error` = Card qui **affiche** l'erreur (un `Callout` inline
  dedans, pas le Card qui disparaît — AD-7 : le contenu local reste, l'erreur est **affichée**) ;
  `offline` = Card **identique** (la lecture locale = normale, §2.1.3 ; un `offline` qui
  « change le look » de toutes les Cards = interdit, règle de non-surprise).

#### `ListItem`
- **Rôle** : la **ligne d'une liste** (tâches, ressources, fiches). **Hauteur min 56px**
  (1 ligne), **80px** (2 lignes = titre + subtitle) — **jamais** en dessous de 56px (§6
  tap target). Structure : `leading` (icône 24px **ou** avatar, `space.4` à gauche) /
  `title` (`base`, `text-primary`) / `subtitle` (`sm`, `text-secondary`, **max 1 ligne**,
  ellipsis) / `trailing` (icône chevron **ou** valeur `JetBrains Mono`, **ou** un
  `Badge`, `space.4` à droite).
- **Variantes** : `default` (1 ligne), `subtitle` (2 lignes), `dense` (48px, **option**
  pour une liste très longue — le dense est **off** par défaut, §1 « aéré »). `ListItem`
  **sélectable** = un tap **tout** le long de la ligne (pas seulement le titre, §6).
- **États** : `pressed` = fond `bg-subtle` (pas de « flash » animé, `anim.fast`) ; `selected`
  = fond `primary-surface` + icône « check » `success` (jamais un fond `primary` plein pour
  la sélection — le `primary` = l'action, la sélection = le « déjà là », §2.1.2) ; `disabled`
  = texte `text-disabled` + **pas** de chevron (un item disabled n'est **pas** « cassé ») ;
  `error` = un item qui a **échoué** (ex. une tâche qui n'a pas sync) = une `Badge`
  `danger` « à resync » à droite (pas un item qui disparaît, AD-7) ; `offline` = ListItem
  **identique** (lecture locale, §2.1.3).

#### `Badge` / `Chip`
- **`Badge`** : un **statut** (pas un tag amovible — un tag amovible = un `Chip`). Fond
  **tonal** (`primary-surface`, `success-surface`…), texte `sm` 500. Radius `sm`. **Jamais**
  un Badge « plein » (un fond `primary` + texte blanc = réservé aux **CTAs**, §3.1).
  Usage : « en cours », « bloqué », « maîtrisé », « fragile », « oublié » (couleur = §2.1.2
  `node-*` pour les 3 états de compétence, doc §14/§25.3).
- **`Chip`** : un **tag amovible** (un tag « Génie civil », « FSRS »). Un `×` **44px**
  (le `×` est **au moins** 44px de tap, §6). Radius `sm`. Fond `bg-subtle` par défaut ;
  `primary-surface` si **sélectionné**. Un Chip **amovible** qui **supprime** = **jamais**
  sans undo (un `Toast` avec « Annuler », §3.4 — règle de non-surprise).
- **États** : `disabled` (Chip) = texte `text-disabled`, **pas** de `×` (un chip disabled
  n'est **pas** amovible, c'est une règle). `loading` = un Chip qui **représente** un
  chargement (ex. un tag « en cours d'import ») = fond `bg-subtle` + un `ProgressRing`
  12px **à gauche** du label (pas un Chip qui pulse).

#### `Avatar`
- **Rôle** : un **représentant** (l'utilisateur, un collaborateur, une matière). Taille :
  `sm` 32px, `md` 44px (default), `lg` 64px. **Jamais** un Avatar < 32px (§6). Fond =
  initiales sur `learning` (violet, §2.1.2 — le « profil » = violet, pas indigo qui est
  l'action) si pas de photo ; une photo = **jamais** cropée « en visages » (un crop
  centré sages, règle de non-surprise). Un Avatar **avec un statut** = une `Badge` 16px
  en bas-droite (ex. « en ligne » = `success`, « en Focus » = `primary`).

#### `ProgressBar`
- **Rôle** : une **progression** (pas un « chargement indéterminé » — le chargement
  indéterminé = un `ProgressRing` **sans** pourcentage). Hauteur **8px** (1 ligne) ou
  **12px** (2 lignes si label). Radius `full`. **Couleur** = `primary` **par défaut** ;
  `success` si 100% ; **jamais** `danger` pour une barre qui « baisse » (un danger = une
  valeur **statique**, pas une barre qui se vide — la dégradation est signalée par un
  `Callout`, pas par la couleur de la barre).
- **États** : `indeterminate` (une barre qui « glisse » : `anim.slow` infinie, **interdite**
  en `focusMode` §2.6 ; le glissement = uniquement pour un chargement **réellement**
  indéterminé — si la durée est connue, la barre **pourcentue** toujours, règle de
  non-surprise). `empty` (0%) = barre **vide visible** (fond `surface-alt`, 8px) — jamais
  une barre qui disparaît à 0%. `disabled` = fond `surface-alt`, **pas** de glissement.
- **`aria`** : `role="progressbar"`, `aria-valuenow/min/max` **obligatoires** (a11y §6).
- **Règle donnée scientifique (§2.6 règle 1)** : une ProgressBar qui représente une
  **valeur mesurée** (ex. 72% de progression d'un chapitre, Progress §18) **affiche**
  le % en `JetBrains Mono` `xs` à droite — **sans animation de comptage** (la valeur
  apparaît, elle ne « tourne » pas).

#### `ProgressRing`
- **Rôle** : un **temps restant** ou un **pourcent circulaire** (le `FocusTimer` §3.6.4,
  le ring **dans** un `Button loading` §3.1, un quota de budget AI **non affiché** —
  le quota AI est un backend concept, AD-4/AD-5 ; un ring de quota **n'existe pas**
  dans l'UI V1, règle §12 « simple en surface »).
- **Spéc** : diamètre `48px` (default), épaisseur de trait `4px`, `stroke` = `primary`
  (complet) / `success` (terminé). **Animation** : le ring **avance** au fil du temps
  (pas un « spin » indéterminé — le temps est **connu**, donc le ring est **déterminé**,
  règle de non-surprise). En `focusMode`, le ring **continue** (c'est le cœur du Focus,
  §2.6 règle 3 : on ne coupe PAS le timer, on coupe les toasts et les animations
  secondaires).
- **États** : `paused` (le trait est **interrompu** visuellement : un gap au point
  d'interruption, `JetBrains Mono` `xs` « pause » au centre) ; `complete` (trait
  `success` + icône « check » `on-primary` au centre, **pas** de feu d'artifice, §2.6) ;
  `error` (un job qui alimente un ring qui **échoue** = le ring se fige + un `Callout`
  `danger` en dessous, le ring **n'explose pas**).
- **`aria`** : `role="progressbar"` + `aria-valuetext` (ex. « 12 min restantes »).

#### `Skeleton`
- **Rôle** : l'état `loading` **universel** (tout écran qui a un `loading` utilise le
  Skeleton du DS, pack 02 §7 : « Skeleton **design system** (tokens), jamais un blanc
  plein »). **Forme = le shape du contenu final** (pas des « lignes génériques » : un
  `SkeletonListItem` qui imite le `ListItem` §3.3, un `SkeletonCard` qui imite la
  `Card`). Fond `aurora.color.skeleton` + **pulse** opacity 0.6→1 / 1.2s (le seul
  « mouvement » autorisé, §2.6 règle 4 — **pas** de shimmer directionnel, batterie
  pack 04 §6.2).
- **Règles** : le Skeleton est **toujours** **local** (une data locale qui se charge
  = Skeleton **court**, pack 02 §7 : « le local-first rend le loading souvent **court** ») ;
  un Skeleton qui dure **> 300ms** (pack 02 §7 seuil) **doit** laisser apparaître le
  contenu partiellement en dessous (règle pack 02 §7 : « le content doit se montrer
  partiellement »). **Interdiction** : un Skeleton **sans** forme (un bloc gris = un
  Skeleton qui ment, règle de non-surprise).

#### `StatTile` (KPI)
- **Rôle** : une **valeur clé** (un KPI d'écran analytics / dashboard Progress §18.6,
  ex. « temps de concentration cette semaine : 14 h 20 »). **Composition fixe** :
  `label` (`xs`, `text-muted`) en haut, `value` (`lg`, `JetBrains Mono`, `text-primary`)
  au centre, `delta` (`xs`, `sm` optionnel : « +2 h vs s.m. » en `success`/`danger`
  **texte**, jamais une flèche seule — le texte dit la **direction**, l'icône ne fait
  pas le sens, a11y §6) en bas. Fond `surface`, `shadow.1`, radius `md`, padding `space.3`.
- **Règle AD-14** : les StatTiles ne vivent **pas** sur le Home (le Home n'a pas de
  KPI, il a une question — AD-14/§11 ; les StatTiles vivent dans `progress-dashboard`
  §4.31 et `analytics` §4.30). **Grille** : max **4** StatTiles par écran (2×2),
  jamais une grille 3×3 (règle §12 « simple en surface »).
- **États** : `loading` = valeur → `Skeleton` (8px × 64px) sous le label (le label
  reste, la valeur pulse) ; `empty` = valeur `—` (tiret `text-muted`, **pas** `0` —
  un 0 peut être une mesure, un `—` est une absence, règle de non-surprise) ;
  `error` = valeur `—` + `Callout` inline `danger` sous le tile ; `offline` = identique
  (lecture locale, AD-7).

#### `Divider`
- 1px, `aurora.color.border`, padding vertical `space.2`. **Variante** `strong` =
  `border-strong` (entre 2 sections majeures, ex. Home §4.4 entre « Priorité » et
  « Révisions »). Un Divider **jamais** en double (pas 2 dividers consécutifs —
  si 2 séparations sont nécessaires, c'est que les sections sont mal coupées, §1).

#### `Callout` (info / warning / danger / success)
- **Rôle** : un **message de niveau** (pas un toast — le Callout est **posé** dans le
  contenu, persistant ; le toast **transitoire**, §3.4). Composition : icône (24px,
  couleur du niveau) + `title` (`sm` 600) + `body` (`sm` 400) + optionnel `action`
  (un `Button ghost` sm, ex. « Réessayer » sur un Callout `danger`). Fond =
  `{level}-surface`, bordure 1px `{level}`, radius `md`, padding `space.3`.
- **Règle de ton** (ADR §13 : « dialogue bref et orienté action ») : un Callout
  `warning`/`danger` **doit** porter **une action** (un CTA, même `ghost`) — un
  Callout d'alerte **sans** action = un mur, pas un message. Un Callout `info`
  **peut** être passif (un contexte, pas un appel).
- **États** : un Callout n'a pas de `loading` (il **est** le contenu, il n'arrive
  pas « en train de se charger ») ; `offline` : un Callout qui annonce « hors-ligne »
  = le Callout **global** de l'écran (§4, bannière fine pack 02 §7), pas un Callout
  par item.

#### `EmptyState`
- **Rôle** : l'état `empty` (pack 02 §7 : « un état vide **actionnable** … **Jamais**
  un vide mort »). **Composition normative** : une icône **domaine** (48px, `text-muted`,
  §2.5 — jamais une « illustration générique SaaS »), un `title` (`md`, 600,
  `text-primary`, **1 phrase** — ex. « Aucune tâche aujourd'hui »), un `body`
  (`sm`, `text-secondary`, **max 2 lignes**, motivation + prochaine brique, ex.
  « Capture une idée dans l'inbox, elle apparaîtra ici. »), et **un seul** CTA
  (`Button secondary` ou `primary` **si** le CTA crée l'objet, ex. « Créer une tâche »).
- **Règle** : le CTA d'un EmptyState **crée** ou **cherche** (pas les deux — si 2
  actions utiles, le 2ᵉ est un `Button ghost` sous le 1ᵉʳ, **max 2**). Exemples
  normatifs par écran : inbox vide → « Capturer maintenant » (primary, ouvre la
  BottomSheet de capture §4.3) ; bibliothèque vide → « Importer un cours » (primary,
  ouvre le scanner pack 04 §3.2.3) + « Rechercher » (ghost).

### 3.4 Navigation

#### `TopBar`
- **Hauteur 56px**, fond `surface` (ou `surface-overlay` si le contenu scrolle
  **sous** — le flou s'applique au **défilement**, pas par défaut, §2.1.3).
  Contenu : `back` (icône 44px, **si** l'écran est un push) + **titre** (`md`, 600,
  **max 1 ligne**, ellipsis) + **actions** (max **2** IconButtons, ex. « recherche »,
  « plus » — au-delà de 2 actions = un `Menu` dans l'icône `more`, règle §12).
- **Règle AD-14** : le Home **n'a pas** de back (écran racine) ; son titre =
  « Aujourd'hui » + la **date** (`xs`, `text-muted`, sous-titre du TopBar — le Home
  **date** toujours son contenu, règle de non-surprise : « Qu'est-ce qui compte
  **maintenant** » nécessite l'ancrage temporel).

#### `BottomNav`
- **Rôle** : la navigation **primaire** (pack 02 §6.1 : « Tab bar = navigation
  primaire ; les détails = push par-dessus »).
- **Max 5 items — motivation prescriptive** : (a) le pouce mobile couvre la zone
  centrale : > 5 items force le **pouce gauche** (fatigue, pack 04 §6) ; (b) la règle
  de §12 « simple en surface » : chaque item **est** une destination, pas un hub ;
  (c) l'Ionic `IonTabs` + Android Material sont standardisés à 5. Les 5 du V1
  (figées, pack 02 §6.1) : `Accueil` (ic-home), `Tâches` (ic-task), `Apprendre`
  (ic-learn), `Progression` (ic-progress), `Coach` (ic-coach). **Interdit** : un
  6ᵉ item ; l'accès au 6ᵉ niveau (ex. `Inbox`, `Calendrier`) passe par les
  5 existants (Inbox = FAB du Home §3.1 ; Calendrier = un mode de la Tâches,
  §4.15 Pager jour/semaine/mois).
- **Hauteur 56px + safe-area**. Item = icône 24px + label `xs`. **Sélectionné** =
  icône `fill` `primary` + label `text-primary` + un **pill tonal** `primary-surface`
  derrière l'icône (pas un soulignement — le pill = cohérent avec les `Chip`, §3.3).
  **Jamais** de « centre FAB flottant » sur le nav (le FAB vit **au-dessus** de la
  BottomNav, dans le contenu de l'écran, §3.1 — la BottomNav **reste plate**).
- **États** : un item en `disabled` n'existe **pas** (un tab = une route vivante ;
  une route morte = on retire le tab, ADR). Un badge de compteur sur un item (ex.
  « 12 révisions dues » sur `Apprendre`) = un `Badge` 16px, `danger` si > 0 **dû
  aujourd'hui**, `primary` si simplement dû plus tard — **jamais** un compteur qui
  s'incrémenté « en bougeant » (le badge est **statique**, §2.6 règle 1).

#### `Tabs` (in-page)
- **Rôle** : le **switch de vue d'un même écran** (ex. dans `taches-liste` :
  « Liste / Kanban / Timeline / Gantt / Calendrier » — pack 02 §3.3 `taskView`).
  **Différence avec `BottomNav` (normative)** : `BottomNav` = **changer d'écran**
  (la stack change) ; `Tabs` = **changer de vue d'un écran** (la stack **ne change
  pas**, le `taskView` du store UI pack 02 §3.3 est **persisté** par tab).
- **Rendu** : une ligne horizontale scrollable (si > 4 tabs) de labels `sm` 600 ;
  l'actif = `primary` + une **underline 2px** `primary` (l'underline **slide** en
  `anim.fast`, **interdit** en reduced-motion §2.6). Les Tabs **ne s'empilent pas** :
  **une seule** ligne de Tabs par écran (les sous-vues passent par un
  `SegmentedControl`, §3.4 — règle d'anti-nesting : **Tabs = vue d'écran,
  SegmentedControl = sous-option**). L'état des Tabs est **persisté** par écran
  (store UI pack 02 §3.2 — le retour sur un tab retrouve **la vue d'avant**,
  règle de non-surprise). **États** : `loading` = le contenu sous les Tabs
  (jamais les Tabs eux-mêmes — les Tabs sont **toujours** cliquables, le
  contenu pulse) ; `empty/error/offline` = gérés par le contenu sous les Tabs
  (§3.3, pas par les Tabs).

#### `SegmentedControl`
- **Rôle** : un **choix exclusif binaire/ternaire** à l'intérieur d'un écran
  (ex. le mode `Jour | Semaine | Mois` du `Pager` §4.15 ; le mode de révision
  « Fiches / QCM / Explication » dans `fiches-detail` §4.22). Rendu : un
  **track** `bg-subtle` radius `full`, le segment sélectionné = fond
  `surface` + `shadow.1` + texte `text-primary` (la « pilule qui glisse » =
  `anim.fast`, interdite en reduced-motion §2.6). **Max 3 segments** — au-delà,
  ce sont des `Tabs` (règle §12 : un contrôle compact, pas un menu déguisé).
- **États** : `disabled` = track `surface-alt`, segments `text-disabled` ;
  `loading` = le switch de segment **est** une lecture locale (AD-7) donc
  **immédiat** — le `loading` du SegmentedControl n'existe que si la donnée de
  la vue cible est **absente** du store local (cas rare, ex. un mois
  non encore syncé, pack 03).

#### `Breadcrumb`
- **Rôle** : le **chemin d'un élément** dans la hiérarchie (ex.
  `Électrotechnique › Machines › Moteur asynchrone` dans `cours-detail`
  §4.19 ; `Projet › Jalon › Tâche` dans `taches-detail` §4.6). Rendu mobile :
  une **ligne** `xs` `text-muted` scrollable horizontalement, séparée par
  `›` ; le **dernier** élément = `text-primary` 600 (on est **ici**).
  **Règle mobile** : le Breadcrumb est **compact** (max 2 niveaux visibles,
  puis un `Menu` pour les ancêtres — jamais 5 niveaux qui défilent
  en permanence, §12). Tappable : oui, chaque élément **monte** d'un niveau
  (AD-6 : le chemin **est** la hiérarchie Knowledge/Produit, pas un fil
  d'Ariane décoratif).

#### `Pager` (jour / semaine / mois)
- **Rôle** : le **navigateur temporel** des écrans calendrier (§4.15–§4.17,
  pack 02 §6.1). Composition normative : un `SegmentedControl`
  `Jour | Semaine | Mois` + une **ligne de navigation** (icône « précédent »,
  le label central « 8 – 14 sept. 2026 » en `sm` 600 `JetBrains Mono` pour
  les dates, icône « suivant ») + un `Button ghost` « Aujourd'hui » (le
  retour au présent, **jamais** caché). Le mode et l'ancrage temporel sont
  **persistés** par l'écran (store UI pack 02 §3.2) — le retour retrouve le
  même mode et la même position (règle de non-surprise).
- **États** : `offline` = le pager **fonctionne** (la navigation temporelle
  est locale, AD-7) ; les éléments **nouveaux** (syncés depuis le cloud)
  apparaissent **au retour** du réseau (pack 03 §5.5 re-sync) avec leur
  `Badge` « nouveau » `primary` (le « nouveau » = indigo, pas rouge — le
  danger est réservé à l'échec, §2.1.2).

### 3.5 Surfaces flottantes

> **Règle de stacking (normative)** : l'ordre de z est **figé** (le DS gère
> le `z-index`, les écrans **n'en définissent jamais**) :
> `contenu (0) < TopBar/BottomNav (10) < BottomSheet/Menu/Drawer (30) <
> Modal (40) < Toast/Snackbar (50) < Splash (60)`. Une surface qui « sort de
> son rang » = review blocking (AD-13 : le DS est le **seul** à définir le
> stacking).

#### `Modal`
- **Rôle** : un **dialogue court** (confirmation, saisie courte, choix
  binaire) qui **interrompt** — le contenu derrière est **verrouillé**
  (backdrop `surface-overlay`, flou 4px). Fond `surface`, radius `lg`
  (haut **et** bas, §2.4), `shadow.3`, padding `space.6`, largeur **85% du
  viewport** (le Modal est une **fenêtre** ; le plein écran = le
  `BottomSheet`, §3.5). **Contenu max** : 1 CTA primaire + 1 ghost + 3
  lignes de body — au-delà, **ce n'est plus un Modal, c'est un
  BottomSheet** (séparation normative, §12 : le Modal = **interrompt et
  décide**, le Sheet = **explore sans s'éloigner**).
- **États** : `loading` = le CTA déclencheur passe en `loading` §3.1, le
  Modal **reste ouvert** (un modal qui se ferme seul pendant la mutation
  = interdit ; l'utilisateur **doit** voir le résultat, AD-7 : le
  succès/échec arrive via `JobCompleted`/`AppError`, pack 02 §7). `error`
  = un `Callout danger` §3.3 **dans** le modal (retry **dans** le modal,
  pas une toast qui passe dans le backdrop flouté). `offline` = un Modal
  qui **exige le cloud** (ex. « Générer un résumé IA », pack 02 §7)
  **désactive** son CTA + un `Callout info` « Hors-ligne — cette action
  nécessite le réseau » (les actions **locales** restent actives, AD-7).
- **Comportement** : le back Android **ferme** le Modal (le verrouillage
  = le contenu, pas le back, pack 02 §6.3 : le formulaire du modal est
  **auto-persisté**, le back ne **perd rien**). **Interdiction** : un
  Modal **empilé** sur un Modal (si 2 décisions se suivent, ce sont 2
  Modaux **séquentiels**, jamais 2 en même temps — l'empilement =
  confusion, §1).

#### `BottomSheet`
- **Rôle** : l'**exploration par-dessus** (le détail d'un item, le choix
  d'une option — pack 02 §6.1 : « les écrans de détail s'ouvrent
  **par-dessus** le tab courant »). Rendu : fond `surface`, coins hauts
  `xl` (§2.4), `shadow.4` (le sheet est **au-dessus** de tout), une
  **handle** 32×4px `border-strong` centrée en haut (la « tirette »,
  signal du drag). **Deux hauteurs nommées** : `peek` (≈ 25% du viewport :
  le titre + 3 lignes + 1 CTA — « sans quitter le contexte ») et `full`
  (≈ 85% : le contenu complet, défilement vertical libre).
- **Règles** : le sheet **ne remplace jamais** un écran de détail
  **lourd** (un écran qui a sa propre TopBar + routing = une **route**,
  pack 02 §6.1 ; le sheet = le détail **léger** qui reste « à côté » du
  contexte). Un sheet **persiste** l'état de défilement quand on le
  ré-ouvre (store UI, AD-7) — jamais un retour en haut surprise.
  Le back Android **descend** le sheet (ferme à `peek` puis
  entièrement, pas de saut direct).
- **États** : `loading` = contenu en `Skeleton` (le sheet **est déjà
  ouvert**, c'est le contenu qui pulse) ; `empty` = un `EmptyState`
  compact (pas de CTA si le sheet n'a pas d'action dédiée) ;
  `error` = un `Callout danger` inline + retry **dans** le sheet ;
  `offline` = lecture locale normale (AD-7), les actions cloud sont
  désactivées avec explicatif (pack 02 §7).

#### `Drawer` (latéral)
- **Rôle** : une **navigation secondaire** (ex. le tri/filtres d'une
  liste, le menu « paramètres rapides » d'un écran). Rendu : panneau
  latéral (gauche par défaut) 80% de la largeur, fond `surface`,
  `shadow.3`, radius `lg` (coin opposé), backdrop `surface-overlay`.
  **Règle** : en mobile, le Drawer est **réservé** aux options de
  l'écran (filtres/tri/contexte) — **jamais** la navigation
  principale (celle-ci = `BottomNav`, §3.4 ; un Drawer de nav
  en mobile = anti-pattern). Un Drawer **ferme au back** et au tap du
  backdrop. `loading` = contenu en Skeleton ; `empty` = « aucun filtre
  actif » (un état **lisible**, pas un vide muet) ; `offline` = identique
  (les filtres sont **locaux**, AD-7).

#### `Toast` / `Snackbar`
- **Différence normative (motivée)** : `Toast` = un
  **acknowledgement passif** (« Tâche terminée ✓ », 2 s, **pas d'action**
  dedans) ; `Snackbar` = une **action + undo** (« Supprimé » + « Annuler
  », 5 s, un **seul** CTA `primary` texte). **Pourquoi deux** : le
  `Toast` **ne bloque jamais** (on le lit et on continue — §1 « calme »)
  ; le `Snackbar` **attend une décision** (l'undo est **le CTA**, il
  reste 5 s — l'undo de `Button destructive` §3.1 **est** un
  `Snackbar`, règle de non-surprise).
- **Règles** : position **bas de l'écran, au-dessus du safe-area**,
  **jamais** en haut (le haut = le TopBar, le feedback bas = la zone du
  pouce). **File** : max **1 visible** — un 2ᵉ event met le 1ᵉʳ en
  attente (jamais 3 toasts qui s'écrasent, règle §1). **Focus Mode**
  (doc §2.8, §2.6 règle 3) : les toasts/snickers sont **différés**
  (ils s'affichent **à la fin** de la session Focus — jamais pendant
  le pomodoro). `offline` : un toast **d'erreur réseau** existe
  (`AppError` `cause:'network'`, pack 02 §10) — c'est le **seul**
  toast qui peut être « statique » (pas de fade : il **reste** tant
  que l'état network ne change pas, pack 02 §7 `offline`).

#### `Menu`
- **Rôle** : la **liste d'actions contextuelles** d'un item (le `⋮`
  d'un `ListItem` : « Modifier / Dupliquer / Supprimer », ex. §4.5).
  Rendu : **pas** de `<select>` natif, pas de menu Android natif —
  un **overlay custom** (cohérence DS) : fond `surface`, radius `md`,
  `shadow.3`, ancré à l'item (pas centré dans l'écran), items =
  `ListItem` 48px avec icône 24px. Un item `destructive` = texte
  `danger` (pas de fond rouge plein — le menu reste **calme**, §1).
  **Règle** : max **6** items dans un Menu (au-delà, un « Plus… » qui
  ouvre le 2ᵉ niveau — jamais plus de 2 niveaux, §12). `disabled`
  (un item du menu) = texte `text-disabled`, **jamais** retiré du menu
  (l'utilisateur doit **voir** ce qui n'est pas possible, a11y §6).

#### `Dropdown`
- **Rôle** : le **choix d'une valeur** (pas d'actions — les actions =
  `Menu`, §3.5). Un `Dropdown` **est** un `Select` (pack §3.2 :
  ouverture en `BottomSheet` + `ListItem` 44px, recherche si > 20
  options). Le DS n'expose **pas** de 2ᵉ composant de choix :
  `Dropdown` = alias exporté de `Select` (API identique, `aria`
  identique) pour la compatibilité des apps qui parlent
  « dropdown » — AD-13 : **une seule** implémentation, deux noms,
  jamais deux composants (pas d'abstraction parallèle).

### 3.6 Composants données / visualisation (wrappers des contrats AD-10)

> **Règle de section (normative, AD-10 + AD-13)** : **chaque** composant
> de cette section est un **wrapper** du contrat renderer AD-10 — le DS
> **définit l'implémentation** (le moteur est **derrière** le
> composant), et **l'app ne voit que le composant** (pack 02 §5.6 :
> l'app n'importe **jamais** `@xyflow/react`, `@antv/*`, `KaTeX`,
> `motion` en dur ; le lint boundary CI fait la police). Les props
> d'entrée = **identiques** aux signatures de consommation ratifiées
> dans le frontmatter G1 (02 §5.1–5.5).

#### 3.6.1 `DataTable` (wrapper `DataVisualizationRenderer`, moteur G2)
- **Rôle** : le **tableau de données** (résultats de calcul,
  comparaison d'essais, charge planifiée vs réelle §2.10). Le
  `DataTable` **n'est pas** un G2 chart : c'est un **tableau HTML
  sémantique** (`<table>`, en-tête sticky, colonnes `JetBrains Mono`
  pour les valeurs, `tabular-nums`), défilant **horizontalement**
  sur mobile (les colonnes sortent de l'écran, **pas** d'écrasement —
  la donnée technique **ne se comprime pas**, §1). Le G2 vit dans
  `Sparkline`/`DataChart` (§3.6.5) pour la **visualisation** ; le
  `DataTable` = la **lecture exacte**.
- **États** : `loading` = Skeleton des lignes (le header reste, les
  lignes pulsent) ; `empty` = un `Callout info` « aucune donnée pour
  ce filtre » (le header **reste visible** — l'utilisateur sait ce
  qu'il **pourrait** voir) ; `error` = `Callout danger` + retry, le
  dernier dataset **syncé** reste affiché (AD-7 : on ne cache pas
  les données locales pour une erreur cloud) ; `offline` = le
  `DataTable` local **fonctionne** (lecture SQLite, AD-7).

#### 3.6.2 `KeyValueList`
- **Rôle** : les **méta-données** d'un objet (les détails d'un
  `Artifact` §4.34 : source, date, taille, `jobKind` ; l'aperçu
  d'un `SemanticNode` : domaine, prérequis, `SourceRef`). Rendu :
  lignes `key` (`sm`, `text-muted`) + `value` (`sm`, `text-primary`,
  **mono si valeur technique**, `JetBrains Mono`) + un **divider**
  `border` entre les paires si > 5 paires (le groupe, pas la ligne,
  se sépare — §2.3).
- **États** : `loading` = Skeleton des valeurs (les clés restent —
  la structure est connue, seule la valeur pulse) ; `empty` =
  « aucune information » (un `KeyValueList` vide **affirme** son
  vide, pas un muet) ; `error/offline` = les valeurs connues restent,
  les manquantes affichent `—` (jamais de trou vide sans légende).

#### 3.6.3 `Timeline`
- **Rôle** : l'**historique d'événements** (l'historique d'une tâche
  §2.2 « historique des reports », le journal des décisions §2.9,
  l'évolution temporelle du Semantic Tree §14 « évolution
  temporelle »). Rendu : une **colonne** verticale, un point (8px,
  couleur sémantique de l'événement : `success` complétion,
  `warning` report, `primary` décision) + une ligne `border`, le
  temps en `xs` `text-muted` `JetBrains Mono`. **Pas** de Gantt
  ici — le `GanttRow` (§3.6.4) est la vue **planification**, la
  `Timeline` est la vue **récit** (règle de séparation des deux,
  doc §2.5 vues).
- **États** : `loading` = les 3 premiers événements en Skeleton (le
  reste se lazy-charge — la timeline est **longue**, pack 02 §9.3
  virtualisation si > 100 items) ; `empty` = « aucun historique » ;
  `offline` = l'historique **local** reste (AD-7) ; `error` = le
  dernier événement synchronisé reste affiché + `Callout danger` en
  tête de liste (l'historique **précède** l'erreur, pas l'inverse —
  l'utilisateur lit son passé, pas un panneau d'erreur).

#### 3.6.4 `GanttRow` (simplifié)
- **Rôle** : une **barre de planification** (la vue Gantt §2.5 des
  projets/tâches, en version **mobile-first simplifiée** : pas de
  diagramme Gantt complet à l'écran — **une tâche = une ligne** avec
  sa barre). Rendu : une ligne 44px : `titre` (`sm`, 1 ligne,
  ellipsis) + une **barre** (hauteur 8px, radius `sm`, fond
  `primary` si en cours / `success` si terminée / `border-strong` si
  à faire) positionnée **proportionnellement** sur un axe de dates
  **partagé** (l'axe = le `Pager` §3.4, `JetBrains Mono` `xs`) +
  le pourcent de complétion en `xs` `JetBrains Mono` à droite.
  L'écran `timeline-gantt` §4.12 = une **liste** de `GanttRow`
  (pas une grille 2D — la grille 2D est le **desktop Phase 2**,
  doc §23 ; le mobile **liste**, règle §12 « simple en surface »).
- **États** : `loading` = les barres en Skeleton (l'axe de dates
  reste, il est **stable**) ; `empty` = « aucun planifié sur la
  période » ; `offline` = les données locales (AD-7) ; une barre
  **bloquée** (doc §2.2 « bloqué ») = fond `danger-surface` +
  icône `ic-task-blocked` à gauche de la barre (le blocage est
  **visible**, pas seulement dans le statut).

#### 3.6.5 `Sparkline` (wrapper `DataVisualizationRenderer`, moteur G2)
- **Rôle** : la **tendance micro** (les 7 derniers jours de
  concentration dans un `StatTile`, la fraîcheur FSRS d'une
  matière). Rendu : un **polygone/ligne** G2 minimal, hauteur 24px,
  `stroke` `primary` 2px, **pas** de grille ni d'axe (la sparkline
  **tendance**, le `DataChart` complet a les axes, §4.30).
  **Règle donnée scientifique (§2.6 règle 1)** : la sparkline
  **n'animé pas** (pas de trace qui se « dessine ») — elle
  **apparaît**. `hover` (Phase 2 desktop uniquement) = un
  `tooltip` avec la valeur `JetBrains Mono`.
- **États** : `loading` = une ligne plate `border` (pas un
  Skeleton — une sparkline skeleton **ment** sur sa forme) ;
  `empty` = une ligne plate `border-strong` + `xs` « pas encore
  de données » ; `error/offline` = la **dernière** valeur locale
  reste (AD-7).

#### 3.6.6 `SemanticTreeNode` (wrapper `SemanticTreeRenderer`, moteur React Flow)
- **Rôle** : le **nœud** de l'arbre sémantique (pack 02 §5.1
  `RenderSemanticNode`) — le DS **ne définit pas le graphe**, il
  définit le **composant de nœud** (React Flow = le moteur, AD-10 :
  « le moteur ne doit pas devenir la source de vérité », §25.3 :
  la vérité = Knowledge, le nœud est **pur** : il **reçoit**
  `RenderSemanticNode`, il n'écrit rien).
- **Rendu** (normatif) : une **pill** (fond `surface`, `shadow.1`,
  radius `md`, padding `space.2`) : `concept` (`sm`, 600, max 2
  lignes) + une **pastille d'état** 10px (gauche) :
  `mastered` = `aurora.color.node-mastered` (vert),
  `fragile` = `node-fragile` (ambre), `forgotten` =
  `node-forgotten` (rouge) — **les 3 états de compétence
  = les 3 couleurs du DS, figées** (doc §14 vue de progression +
  §25.3 `NodeState` ; doc §18.2 « découvert, compris, rappelable »
  = `text-muted`/`info`/`primary` — les états intermédiaires ne
  prennent **pas** les couleurs « fortes » : seules les 3
  extrémités maîtrisé/fragile/oublié sont codées en couleur,
  règle §1 « les couleurs vives sont réservées aux sémantiques »).
- **Règles** (pack 02 §9.2, perf normative) : le nœud est
  **mémoïsé** (`React.memo`, données stables par référence) ;
  l'expansion/repli d'une branche = un `+`/`−` **à l'intérieur**
  du nœud (44px tap, §6) ; un nœud `collapsed` affiche un
  compteur `xs` `JetBrains Mono` (« 12 ») = ses enfants masqués.
  **Jamais** un nœud qui **pulse** (un état `fragile` est **statique**
  — la couleur est l'information, pas l'animation, §2.6).
- **États** (rendu du `SemanticTreeRenderer` 02 §5.1, pas du nœud
  seul) : `loading` = les nœuds racine + niveau 1 en Skeleton
  (règle 02 §9.2 point 1 : **seule** la racine + niveau 1 au
  mount) ; `empty` = un `EmptyState` plein écran (« L'arbre
  commence avec vos premiers cours importés » + CTA) ; `error` =
  `Callout danger` + retry, le sous-arbre **chargé** reste
  (AD-7) ; `offline` = l'arbre **local** reste interactif (pan/
  `offline` = l'arbre **local** reste interactif (pan/zoom/repli,
  lecture SQLite AD-7) ; les sous-arbres **non encore syncés**
  affichent un `Badge` `info` « à synchroniser » (jamais de nœud
  **inventé** — le `loading` n'est que pour le sous-arbre en cours
  de chargement, jamais pour l'arbre entier).

#### 3.6.7 `InfographicSlot` (wrapper `InfographicRenderer`, moteur AntV)
- **Rôle** : le **slot de rendu d'une explication visuelle** générée
  par l'agent (doc §25.4 : flux `AI → InfographicSpec → validation →
  moteur → SVG → affichage/export`). L'app **passe** une
  `InfographicSpec` validée (02 §5.2) ; le slot la rend en
  **SVG** (scalable, léger, exportable) — jamais en raster par
  défaut (le PNG est l'**export**, pas le rendu, doc §25.4 :
  « les infographies peuvent être exportées en SVG ou PNG »).
- **Règle fidélité (AD-11 / §25.5)** : `fidelityMode="strict"`
  est le **défaut** (doc §17 : le corpus du professeur reste
  textuellement dominant) ; un texte qui vient du corpus est rendu
  **tel quel** (AntV met en **page**, il ne **réécrit pas** le
  contenu, §25.5) ; l'explication d'Aurora est **séparée** (un bloc
  labelisé « Explication d'Aurora » `info` sous l'infographie —
  règle AD-11 « explicite ») — le contenu du
  corpus et l'explication de l'agent **ne se mélangent jamais**
  dans le même bloc visuel (règle doc §17 : « Séparation explicite
  entre formulation du corpus et explication d'Aurora »).
- **Export** : un `IconButton` « export » (SVG/PNG, menu 2 items)
  **posé** dans le slot, jamais automatique. Les palettes Aurora
  (`aurora-light`/`aurora-dark`) sont **enregistrées** comme
  thèmes réutilisables du moteur (doc §25.4).
- **États** : `loading` = le **slot entier** en Skeleton (une
  infographie à moitié rendue **ment** sur sa structure, §2.6) ;
  `empty` n'existe pas (un slot = une spec **donnée** ; l'absence
  du slot ≠ un état du slot) ; `error` = le **fallback** texte
  brut (la spec **dégradée** en `KeyValueList` §3.6.2 + un
  `Callout danger` « visualisation indisponible » — AD-1 :
  capacité absente dégrade proprement) ; `offline` = les specs
  **générées** (cloud, pack 02 §7) sont **indisponibles** avec
  explicatif, les specs **déjà téléchargées** restent (cache R2,
  pack 04 §5).

#### 3.6.8 `MathBlock` (wrapper `MathRenderer`, moteur KaTeX)
- **Rôle** : le **rendu d'une formule LaTeX** (doc §15, §25.7).
  L'app passe `latex: string` + `displayMode` (02 §5.4) ; le bloc
  **affiche** le rendu KaTeX ; le source LaTeX est **dépliable**
  en dessous (icône « code » `sm`) — l'étudiante **doit** pouvoir
  vérifier la formule brute (règle de confiance, §15 « Traçabilité
  du calcul »).
- **États** : `loading` = un `MathBlock` **n'a jamais** de loading
  (KaTeX est **local**, rendu < 50ms — le `loading` n'existerait
  que pour la **source** qui arrive par l'agent, et dans ce cas
  c'est l'écran qui est en loading, pas le bloc) ; `error` = le
  fallback **texte brut** dans un bloc stylé « formule non
  rendue » + `onError` (02 §5.4 : « KaTeX fail → fallback texte
  brut, PAS de crash ») ; `empty` n'existe pas (un bloc vide =
  un composant qui **ne doit pas** exister) ; `offline` = le bloc
  reste (le rendu est **local**, AD-7).
- **Règle fidélité (AD-11)** : une formule **issue du corpus**
  porte une `SourceRef` en `xs` `text-muted` sous le bloc
  (« §3.2, p. 47, doc. béton armé ») — la formule du corpus n'est
  **jamais** ré-énoncée par l'agent (AD-11 : formulation
  textuellement dominante).

#### 3.6.9 `FocusTimer` (Pomodoro ring, doc §2.8)
- **Rôle** : le **timer de session de concentration** (doc §2.8
  « Minuteur/Pomodoro », pack 04 §4 Focus Controller). Le timer
  **est un `ProgressRing`** (§3.3) au mode « temps restant » :
  diamètre `160px` (l'écran `focus-mode` §4.11), au centre le
  temps restant en `3xl` `JetBrains Mono` (le seul endroit où le
  DS autorise `3xl` sur mobile — le Focus est l'écran « temps ») +
  le label de l'activité sous (`sm`, `text-secondary`).
- **Règles** : le timer **continue** quand l'app passe en
  arrière-plan (pack 04 §7.3 : « le timer se met en pause au
  passage background et se **reprend** au retour ») ; la base de
  temps = l'horloge système, **pas** un compteur JS (pack 04
  §6.1 : le kill de l'app **ne perd rien**, AD-7) ; un Pomodoro =
  **25 min par défaut** (configurable, `Slider` 5–90, §3.2) ;
  la pause (5 min) = le ring repasse en `success` (le break, le
  repos, est vert — le rouge est réservé au danger, §2.1.2).
- **États** : `loading` = le timer ne se « charge » **pas** (le
  temps est **connu** immédiatement ; l'unique `loading` = le
  **bilan** de fin de session, `FocusSessionBilan`, qui est une
  lecture : Skeleton du bilan, pack 04 §4.1 point 4 : le bilan
  **doit** exister dans l'inventaire §4.11 avec le G2
  contractuel) ; `error` = `Callout danger`, le timer
  **continue** (une erreur de bilan **ne casse pas** la
  session, AD-7) ; `offline` = le timer est **parfaitement**
  fonctionnel (tout est local, §2.8 n'a aucune dépendance
  cloud).

#### 3.6.10 `FlashcardCard`
- **Rôle** : la **carte mémoire** (doc §3 : Flashcards + répétition
  espacée FSRS). Rendu : une carte recto/verso (radius `xl`, §2.4,
  `shadow.2`), le recto = la **question**, le verso = la
  **réponse**. **Règle AD-11 / doc §17 (fidélité corpus)** : le
  contenu du recto/verso vient du **corpus** (les définitions du
  professeur, §17) ; l'explication d'Aurora est un bloc
  **séparé** labelisé (comme §3.6.7) — jamais mélangée à la
  formulation du cours. Une formule dans la carte = un
  `MathBlock` §3.6.8 (pas du texte bricolé).
- **Interaction** : le **flip** = un tap (toute la carte = tap
  target), rotation 3D `anim.normal` (**interdite** en
  reduced-motion §2.6 : le flip devient un **cross-fade**
  instantané — même contenu, aucun effet). **Jamais** un
  auto-flip (l'utilisatrice **devine**, puis **voit** — le flip
  **forcé** détruit le rappel actif, doc §3).
- **États** : le feedback de qualité de rappel (FSRS : « oublié /
  difficile / bon / facile ») = 4 `Button secondary` en bas de
  l'écran (le choix **après** le flip, jamais pendant) — pas de
  `Chip` amovible : c'est une **évaluation**, pas un tag (§3.3).
  `loading` (la carte arrive du cloud, cas rare local-first) =
  Skeleton recto/verso ; `empty` = « aucune carte due — tout est
  maîtrisé » (un état **positif**, pas un vide négatif, §12) ;
  `error` = la dernière carte **syncée** reste + `Callout
  danger` ; `offline` = les cartes **locales** (AD-7) restent.

#### 3.6.11 `SkillStateBadge` (maîtrisé / fragile / oublié)
- **Rôle** : le **badge d'état de compétence** (doc §18.2,
  `SkillState` AD-15 ; l'échelle complète « découverte →
  compréhension → rappel → application guidée → autonome →
  problème nouveau → maîtrise → expertise » = **8 niveaux**,
  §18.2). Le badge n'affiche **que 3 familles** de couleur (règle
  §3.6.6 des 3 couleurs fortes) : `maîtrisé` (niveaux 6-8,
  `success`) / `fragile` (niveaux 3-5, `warning`) /
  `oublié` (niveau < 3 ou FSRS dégradé, `danger`) ; les états
  intermédiaires (découverte, compris) = `neutral` (grise
  `text-muted`) — l'information **fine** reste dans le niveau
  1–8 (affiché en `xs` `JetBrains Mono` « 4/8 » à côté du
  badge, pack §18.2 : chaque compétence a un **niveau**, pas
  seulement une couleur).
- **États** : le badge **n'a pas** de `loading` (c'est une
  projection d'un `SkillState` AD-15, qui est **connu** dès
  qu'il existe) ; `empty` = le niveau 1 « découvert »
  (l'état initial **est** un état du badge, pas un vide) ;
  `error/offline` = le **dernier** `SkillState` syncé reste
  affiché (AD-7) + le `Badge` porte un petit « » si l'état est
  peut-être obsolète (la fraîcheur FSRS, §18.2 « distinguer
  une compétence acquise d'une compétence encore
  disponible »).

#### 3.6.12 `HabitStreak` (heatmap type GitHub) + `RoutineStep`
- **`HabitStreak`** : l'**adhérence temporelle** d'une habitude
  (doc §2.7 : « Suivi de régularité », « Analyse de l'adhérence
  »). Rendu : une **grille de 7 colonnes** (jours) × N semaines,
  les cellules 12×12px, 5 niveaux de teinte (token
  `habit-weak` → `habit-med` → `habit-strong`, §2.1.2) ; le
  niveau 0 (non faite) = `bg-subtle`. **Règle donnée (§2.6
  règle 1)** : pas d'animation de remplissage — les cellules
  **sont**, elles ne se « peignent pas ». Un **streak courant**
  (ex. « 12 jours ») est affiché en `JetBrains Mono` `lg` à
  côté (la **chiffre** parle, la heatmap est la **preuve**).
  `empty` = « commencez aujourd'hui » + CTA « Marquer le
  jour » (le `Habit` local, AD-7 — la première case se remplit
  **immédiatement**, pas besoin de cloud).
- **`RoutineStep`** : une **étape** d'une routine (doc §2.7
  « Routines matin/soir et routines d'étude »). Rendu : un
  `ListItem` avec, à gauche, une **numérotation** `JetBrains
  Mono` (1., 2., 3. — l'ordre de la routine **est**
  l'information, pas un bullet générique) + un `Checkbox`
  (§3.2, 44px) à droite. Une étape **reportée** porte un
  `Badge warning` « reportée » (l'analyse de l'adhérence,
  §2.7 : « Détection des habitudes perturbatrices » lit les
  reports). La routine entière = une `Card` qui contient les
  `RoutineStep` (pas une liste plate — la routine est un
  **objet**, l'étape est sa partie, §1).

### 3.7 État des composants — matrice AD-13 (annexe A, normative)

Le tableau ci-dessous fixe, **par composant**, quels états
existent (1) et lesquels sont **gérés par l'écran** (2) vs par
le composant (3). Règle : un composant **rend** un état,
l'écran **décide** de l'état (pack 02 §7 : « l'état est décidé
par l'app, le rendu par le Design System »).

| Composant | `loading` | `empty` | `error` | `offline` | Géré par |
|---|---|---|---|---|---|
| `Button`/`FAB` | ✓ (ring interne) | n/a | n/a (le CTA reflète) | ✓ (désactivé si cloud) | composant |
| `TextField`/`TextArea` | ✓ (verrouillé) | n/a | ✓ (inline) | ✓ (toujours actif) | composant |
| `Select`/`MultiSelect` | ✓ (skeleton options) | ✓ (CTA) | ✓ (Callout inline) | ✓ (locale) | composant |
| `Card` | ✓ (skeleton contenu) | n/a | ✓ (Callout dedans) | ✓ (identique) | composant |
| `ListItem` | n/a | n/a | ✓ (badge resync) | ✓ (identique) | composant |
| `ProgressBar` | n/a | ✓ (0% visible) | ✓ (figé + callout) | ✓ (identique) | composant |
| `StatTile` | ✓ (skeleton valeur) | ✓ (`—`) | ✓ (`—` + callout) | ✓ (identique) | composant |
| `Skeleton` | (c'est l'état) | n/a | n/a | n/a | composant |
| `EmptyState` | n/a | (c'est l'état) | n/a | ✓ (CTA local) | composant |
| `TopBar`/`BottomNav` | n/a | n/a | n/a | ✓ (badges statiques) | composant |
| `Tabs`/`Segmented` | n/a (le contenu oui) | n/a | n/a | n/a | écran |
| `Pager` | n/a | n/a | n/a | ✓ (fonctionne) | composant |
| `Modal` | ✓ (CTA loading) | n/a | ✓ (callout dans) | ✓ (CTA cloud désactivé) | composant |
| `BottomSheet` | ✓ (skeleton) | ✓ (compact) | ✓ (callout + retry) | ✓ (locale) | composant |
| `Drawer` | ✓ (skeleton) | ✓ (« aucun filtre ») | ✓ (callout) | ✓ (identique) | composant |
| `Toast` | n/a | n/a | ✓ (network) | ✓ (statique) | écran |
| `Menu`/`Dropdown` | n/a | n/a | n/a | n/a | composant |
| `DataTable` | ✓ (skeleton lignes) | ✓ (callout info) | ✓ (data locale reste) | ✓ (locale) | composant |
| `KeyValueList` | ✓ (skeleton values) | ✓ (« aucune info ») | ✓ (`—` + callout) | ✓ (locale) | composant |
| `Timeline` | ✓ (3 premiers) | ✓ (« aucun historique ») | ✓ (syncé reste) | ✓ (locale) | composant |
| `GanttRow` | ✓ (skeleton barres) | ✓ (« aucun planifié ») | ✓ (statut reste) | ✓ (locale) | composant |
| `KanbanColumn/Card` | ✓ (skeleton cards) | ✓ (« colonne vide ») | ✓ (badge resync) | ✓ (locale) | composant |
| `CalendarCell` | n/a | ✓ (jour vide) | n/a | ✓ (locale) | composant |
| `FocusTimer` | n/a (bilan oui) | n/a | ✓ (callout, continue) | ✓ (100% local) | composant |
| `FlashcardCard` | ✓ (skeleton recto/verso) | ✓ (« aucune due ») | ✓ (syncé reste) | ✓ (locale) | composant |
| `SkillStateBadge` | n/a | ✓ (niveau 1) | n/a (dernier syncé) | ✓ (syncé) | composant |
| `SemanticTreeNode` | ✓ (niv. 1 skeleton) | ✓ (EmptyState) | ✓ (sous-arbre reste) | ✓ (arbre local) | composant |
| `InfographicSlot` | ✓ (slot entier) | n/a | ✓ (fallback texte) | ✓ (specs TL restent) | composant |
| `MathBlock` | n/a (local) | n/a | ✓ (source brute) | ✓ (local) | composant |
| `Sparkline` | ✓ (ligne plate) | ✓ (ligne plate + label) | ✓ (dernière valeur) | ✓ (locale) | composant |
| `HabitStreak` | n/a | ✓ (« commencez ») | ✓ (journées locales) | ✓ (locale) | composant |
| `RoutineStep` | n/a | n/a | ✓ (badge reporté) | ✓ (locale) | composant |
| `Callout` | n/a | n/a | (c'est l'état) | ✓ (bannière) | écran |
| `Divider` | n/a | n/a | n/a | n/a | n/a |

**Règle de test (pack 02 §11)** : un composant qui **implémente** un
état de cette matrice a **un test de rendu par état** ; un composant
marqué « écran » a **un test par écran** qui compose l'état (les 5
états d'écran, pack 02 §7).

---

## 4. Documentation des écrans (inventaire écran par écran, AD-14 + §12)

> **Format de section (normatif)** : pour **chaque** écran :
> `slug` · **Objectif** (1 ligne) · **Zones** (header/content/footer/
> surfaces flottantes) · **DS** (composants §3 utilisés) · **États**
> (loading/empty/error/offline — pack 02 §7, toujours les 5) ·
> **Transitions** (vers quels écrans) · **Notes responsive**
> (mobile-first Phase 1 → adaptation Phase 2 desktop, doc §23).
>
> **Liste exhaustive dérivée du doc (§2 à §18 + §13 Discovery +
> §18 Progress)** — 44 écrans, regroupés par module. La **variante**
> (liste + détail) est traitée **séparément** pour chaque paire.
>
> **Règle transversale des transitions (pack 02 §6)** : un écran de
> **détail** s'ouvre **par-dessus** le tab courant (BottomSheet ou
> push), **jamais** par changement de tab ; le retour = le
> **contexte** (règle de non-surprise). L'écran de détail **léger**
> = `BottomSheet` (§3.5) ; le détail **lourd** (sa propre TopBar +
> sub-navigation) = une **route** push (pack 02 §6.1).

### 4.1 Module Onboarding / Écran racine

#### 4.1.1 `onboarding`
- **Objectif** : l'installatrice choisit **qu'elle est** (étudiante,
  matière, horaire de silence, thème) — 3 écrans max, **pas** un
  tour de fonctions (règle §12 : simple en surface).
- **Zones** : content (carrousel 3 slides, un `Avatar` + titre
  `2xl` + corps `sm`), footer (un `Button primary` « Continuer » +
  un `Button ghost` « Passer »).
- **DS** : `Avatar`, `Button` (primary/ghost), `Toggle` (thème),
  `Select` (matière), `DateField`/`DurationField` (horaires),
  `Skeleton` (le fond des slides pendant le chargement de la
  matrice de cours locale).
- **États** : `loading` (le fond des slides pendant le chargement
  de la matière locale) ; `empty` n'existe pas (l'onboarding
  **précède** les données) ; `error` = le choix de la matière qui
  **échoue** (upload de cours) → `Callout danger` + retry (la
  matière **peut** être choisie plus tard, l'onboarding
  **s'achève** malgré l'échec — on ne bloque pas l'entrée dans
  l'app, AD-7) ; `offline` = l'onboarding **fonctionne** (les
  choix sont **locaux**, AD-7 ; l'import de cours est différé,
  `Badge info` « importera à la connexion »).
- **Transitions** : → `welcome/home` (fin) ; un `onboarding`
  interrompu **reprend** au premier choix manquant (store
  local, AD-7 — l'exit/retour **ne perd rien**).
- **Notes responsive (Phase 2)** : desktop = l'onboarding passe
  en **panneau latéral** (le carrousel devient 3 étapes
  empilées, le CTA reste en bas) — la logique (les 3 choix) est
  **inchangée** (doc §23.4 : adapter le layout, pas le contenu).

#### 4.1.2 `welcome/home` (AD-14 — invariant, 7 items fixes)
- **Objectif** : répondre à **une seule** question : « Qu'est-ce
  qui compte maintenant ? » (AD-14, doc §11 : l' qui compte maintenant ? » (AD-14, doc §11 : l'accueil
  **n'est jamais** un tableau de widgets (il répond à une
  **question**, il n'empile pas des chiffres, §1).
- **Zones (composition **fixe** et ordonnée, pack 02 §6.2 —
  toute dérive = blocking)** : header (un `TopBar` : «
  Aujourd'hui » + la date en `xs` `JetBrains Mono` + 2
  IconButtons : recherche, menu) ; content (les 7 blocs, dans
  **cet ordre**) : 1. `Agenda du jour` (une liste de
  `ListItem subtitle`, événements + tâches du jour, heure
  en `JetBrains Mono` `xs`) ; 2. `Prochaine action
  importante` (un **seul** `Card elevated` §3.3 : le titre de
  la tâche + son projet/matière en `Badge`, un CTA «
  Démarrer le Focus » si c'est l'action du moment) ;
  3. `Priorité principale` (un `ListItem` dense si distincte
  de la 2 — **sinon le bloc est masqué** : AD-14 n'empile
  pas) ; 4. `Progression critique` (un `ListItem` dense + un
  `SkillStateBadge` : l'élément Progress le plus urgent, doc
  §18.1) ; 5. `Révisions à effectuer` (un `Chip` compteur
  « 12 révisions dues » `primary` + un CTA ghost « Réviser »
  qui ouvre `flashcards` §4.22) ; 6. `Accès Focus` (un
  `Button primary` **large** (lg), un accès **immédiat** au
  `focus-mode` §4.11 — **le 6ᵉ bloc est un bouton, pas une
  liste** : le Focus est une **action**, pas une info, AD-14)
  ; 7. `Suggestions Coach` (1–2 **max**, courtes, orientées
  action, doc §13 « dialogue bref et orienté action » — un
  `Callout info` **posé** (pas un toast qui apparaît, §2.6
  règle 3 : le Home est **calme**, les suggestions du Coach
  s'affichent de **façon persistante** sous « Suggestions »,
  jamais intrusives).
- **DS** : `TopBar`, `ListItem`, `Card` (elevated ×1),
  `SkillStateBadge`, `Chip`, `Button`, `Callout`, `Badge`,
  `Divider` (entre les blocs, §3.3).
- **États** : `loading` = **jamais** sur le Home (pack 02
  §6.2 : « les données du Home = **tout** depuis le store
  local — pas d'appel réseau au mount » ; le Home est
  **immédiat**, AD-14 — le seul `loading` = le sync en
  arrière-plan, **invisible**, AD-7) ; `empty` = un état
  vide **propre** par bloc (le Home **affiche** ses blocs
  même vides : « aucune tâche aujourd'hui » + un CTA
  « Capturer une idée » qui ouvre la BottomSheet de capture,
  doc §2.1 ; le bloc 6 « Focus » est **jamais vide** (le
  Focus est **toujours** disponible — c'est un bouton, pas
  une donnée, AD-14) ; le bloc 7 « Coach » vide =
  **masqué** (pas de bloc vide muet — le bloc 7 n'existe que
  s'il **y a** une suggestion, AD-14 « pas de dashboard ») ;
  `error` = un bloc qui **échoue** à se calculer (ex. le
  calcul du « critique ») = le bloc affiche un `Callout
  danger` « progression indisponible » + retry, les
  **autres** blocs restent (le Home **ne tombe pas** entier,
  AD-7 : le local reste lisible) ; `offline` = le Home
  **fonctionne** (tout est local, AD-7) — les blocs 4/7
  (ceux qui dépendent de l'analyse serveur) affichent leur
  **dernière valeur syncée** + un `Badge info` « valeur
  d'avant la coupure » (jamais de bloc qui disparaît).
- **Transitions** : bloc 1 → `calendrier-jour` §4.15 ; bloc
  2 → `taches-detail` §4.2.3 ; bloc 5 → `flashcards` §4.22 ;
  bloc 6 → `focus-mode` §4.11 ; bloc 7 → le CTA de la
  suggestion (varie : `taches-liste`, `fiches-liste`,
  `decouverte-feed` §4.27).
- **Notes responsive (Phase 2)** : desktop = les 7 blocs
  passent en **2 colonnes** (la liste d'agenda à gauche, les
  5 blocs restants à droite) — l'ordre **logique** reste
  (AD-14), l'ordre **visuel** s'adapte (doc §23.4 : « créer
  des layouts desktop sans modifier la logique métier »).

### 4.3 Module Productivité — projets, objectifs, habitudes
(doc §2.5–§2.7)

#### 4.3.1 `projets-liste`
- **Objectif** : **voir** l'ensemble des projets (les jalons,
  la progression, les tâches associées — doc §2.5) ; un
  projet **est** une hiérarchie (Objectif → Projet →
  Tâche, doc §2.6), la liste affiche les projets en
  **racines**.
- **Zones** : header (`TopBar` « Projets » + un `Menu` de
  tri : par date / par progression / par priorité) ;
  content (une liste de `Card flat` §3.3 — pas de
  `ListItem` : un projet est un **objet riche** (un % de
  progression, un prochain jalon), pas une ligne simple ;
  chaque Card = `titre` (`md` 600) + `ProgressBar`
  (§3.3, le % de complétion du projet, `JetBrains Mono`
  `xs`) + 2 `Badge` (le statut, le prochain jalon en
  `JetBrains Mono` `xs`) + un `KeyValueList` compact
  (les tâches totales/terminées, `xs`) ; footer
  (`BottomNav`).
- **DS** : `TopBar`, `Menu`, `Card` (flat),
  `ProgressBar`, `Badge`, `KeyValueList`, `EmptyState`,
  `Skeleton`, `FAB` (« Nouveau projet », §3.1).
- **États** : `loading` = les Cards en Skeleton (le
  store local, pack 02 §7) ; `empty` = un
  `EmptyState` : icône « projet », « Aucun projet
  pour l'instant — un projet commence par un
  objectif » + CTA « Créer un projet » (le CTA ouvre
  une `BottomSheet` de création avec un `Select`
  d'objectif, un `DateField` d'échéance, un
  `TextField` de titre) ; `error` = un projet non
  syncé = un `Badge danger` « à resync » sur la
  Card (le projet **reste**, AD-7) ; `offline` =
  la liste **fonctionne** (lecture locale, AD-7),
  la création reste **possible** (l'écriture
  est locale, pack 03) — seul le **scan de
  documents** (les « documents » du projet, doc
  §2.5) est désactivé (l'action cloud).
- **Transitions** : une `Card` → `projets-detail`
  §4.3.2 (un **push** détail **lourd** — un projet
  a sa propre TopBar + sub-navigation
  (les 5 vues §2.5 : Liste/Kanban/Timeline/
  Gantt/Calendrier), ce n'est **pas** une
  BottomSheet, c'est une **route**, pack 02 §6.1) ;
  le FAB → la `BottomSheet` de création.
- **Notes responsive (Phase 2)** : desktop = les
  Cards passent en **grille 2 colonnes** (pas
  4 — un projet est riche, §3.3 Card = une
  seule idée, on ne « compacte » pas) ; le
  `FAB` devient un `Button` dans le header
  (le FAB est un **mobile-only** pattern,
  doc §23.2 — desktop = un CTA dans la
  `TopBar`).

#### 4.3.2 `projets-detail` (doc §2.5)
- **Objectif** : **un** projet, tout son
  contexte (l'objectif, les jalons, les tâches,
  les ressources, les documents, les notes,
  l'historique — doc §2.5 **complet**) ;
  les vues (Liste/Kanban/Timeline/Gantt/
  Calendrier) sont **empotées** dans ce
  détail (pas des écrans séparés — le
  projet est **le** contexte, les vues
  sont ses **projections**, §12 «
  puissant en profondeur »).
- **Zones** : header (`TopBar` « titre du
  projet » (éditable inline, `md` 600) +
  un `Menu` (renommer / supprimer /
  dupliquer / partager) — le «
  supprimer » = `destructive` confirmé
  par `Modal`, §3.1) ; content (un
  `Tabs` « Infos | Tâches | Jalons |
  Documents | Notes » §3.4 : Infos =
  un `KeyValueList` §3.6.2 (l'objectif,
  l'échéance, la progression — les 3
  valeurs du projet) + un `ProgressBar`
  (la complétion globale) + un
  `Callout info` (le « prochain jalon »
  en `JetBrains Mono` `xs`) ; Tâches =
  une liste `ListItem` (les tâches du
  projet, **sans** le `Tabs` de vue
  global §4.2.2 — ici les tâches sont
  **filtrées** par projet, le switch de
  vue = un `SegmentedControl` « Liste /
  Kanban » (2 options, §3.4) si
  l'utilisateur veut un Kanban **du
  projet** (pas global) ; Jalons = une
  liste `RoutineStep` §3.6.12 (un jalon
  est une **étape** du projet, avec
  checkbox + date `DateField`
  inline) ; Documents = une liste
  `ListItem` qui **pousse**
  `artefacts-detail` §4.34 ; Notes =
  une liste `ListItem` (les notes, doc
  §2.5 « notes ») ; footer (le
  `BottomNav` n'est **pas** présent —
  le détail **remplace** la nav, un
  push route §4.3.1, pas une
  BottomSheet).
- **DS** : `TopBar` (inline-edit),
  `Menu`, `Tabs`, `KeyValueList`,
  `ProgressBar`, `Callout`,
  `SegmentedControl` (la sous-vue des
  tâches), `RoutineStep` (jalons),
  `ListItem`, `EmptyState` (par tab),
  `Breadcrumb` (§3.4, `Objectif ›
  Projet`, si le projet est **dans**
  un objectif, doc §2.6 « Hiérarchie
  Objectif → Projet → Tâche »).
- **États** : `loading` = les 5 tabs en
  Skeleton (le contenu des tabs, pas
  les tabs eux-mêmes §3.4) ; `empty` =
  par tab (le tab « Documents » vide =
  « Aucun document — scannez votre
  premier PDF » + CTA qui ouvre le
  scanner pack 04 §3.2.3) ; `error` =
  un jalon **échoué** à se syncer =
  le `Badge danger` sur la jalon
  (le reste du projet **reste** lisible,
  AD-7) ; `offline` = tout le projet
  reste **lisible** (lecture locale,
  AD-7), les mutations restent
  **possibles** (pack 03), seul le
  **scan/upload** de documents est
  désactivé (pack 02 §7 `offline`).
- **Transitions** : un jalon →
  `taches-detail` §4.2.3 (si le jalon
  est **lié** à une tâche, doc §2.5) ;
  un document → `artefacts-detail`
  §4.34 ; le Breadcrumb « Objectif » →
  `objectifs-detail` §4.3.4 (l'objectif
  parent, doc §2.6).
- **Notes responsive (Phase 2)** :
  desktop = les 5 tabs deviennent un
  **panneau latéral** (les tabs
  passés en **liste verticale**, pas en
  ligne — le contenu central reste
  **large** pour les Gantt/grilles,
  doc §23.4 : le layout s'adapte, la
  logique (5 sections) est
  **inchangée**).

#### 4.3.3 `kanban` (vue Kanban globale, doc §2.5)
- **Objectif** : le **board** de tâches **transverses**
  (pas par projet — le Kanban **par** projet vit
  dans `projets-detail` §4.3.2 ; le Kanban global =
  le **tri** des tâches par **statut**, doc §2.2
  « Statuts : à faire, en cours, bloqué,
  terminé, annulé »).
- **Zones** : header (`TopBar` « Kanban » + un
  `Menu` filtre : par projet / par priorité /
  par matière) ; content (une **rangée
  horizontale** de `KanbanColumn` §3.6.4 — 5
  colonnes (1 par statut, doc §2.2), chaque
  colonne **scroll verticale**, les
  `KanbanCard` sont **drag** vers une autre
  colonne (le drag = le **move** de statut,
  pas de « drop » vers une 6ᵉ colonne
  inexistante — l'état `annulé` = une
  colonne **séparée**, jamais un « trash »
  déguisé) ; footer (`BottomNav`).
- **DS** : `TopBar`, `Menu`,
  `KanbanColumn`, `KanbanCard`, `Badge`
  (le statut de la card), `ProgressBar`
  (le % de complétion d'une card si elle
  a des sous-tâches), `EmptyState` (une
  colonne vide), `Skeleton`, `FAB`
  (« Nouvelle tâche », §3.1).
- **États** : par colonne (matrice §3.7 :
  le contenu de la colonne en
  Skeleton/Empty/`Callout`/`—`) ;
  `empty` = une colonne vide = un
  `EmptyState` **compacte** (pas de
  CTA si c'est la colonne « terminé »
  — un vide positif, pas un vide
  négatif, §12) ; `error` = une card
  non syncée = un `Badge danger` « à
  resync » (la card **reste** dans sa
  colonne, AD-7) ; `offline` = le
  Kanban **fonctionne** (le drag
  **local** est **possible** — le
  mouvement de card est une écriture
  locale, pack 03 ; la **sync** se
  fait au retour, pack 03 §5.5
  re-sync), seul le **scan** est
  désactivé.
- **Transitions** : une `KanbanCard` →
  `taches-detail` §4.2.3 (le détail
  est une `BottomSheet full` §3.5,
  **par-dessus** le Kanban — le
  Kanban **reste** visible en
  arrière-plan, règle de non-surprise
  : on revient au board, pas à une
  liste).
- **Notes responsive (Phase 2)** :
  desktop = le Kanban devient une
  **grille 4–5 colonnes côte à
  côte** (pas de scroll horizontal —
  le viewport est **large**, les
  colonnes sont **latérales**, doc
  §23.4) ; le drag passe en
  **horizontal** (colonne → colonne,
  le même `KanbanCard`, seul le
  **layout** change, le composant
  est **identique** mobile/desktop,
  doc §23.4 « réutiliser les
  contrats existants »).

#### 4.3.4 `objectifs-liste` + `objectifs-detail`
(doc §2.6)
- **Objectif** (liste) : **voir** les
  objectifs (court/moyen/long terme,
  doc §2.6) ; **Objectif** (détail) :
  **un** objectif, sa hiérarchie
  (les projets qui **y contribuent**,
  doc §2.6 « Hiérarchie Objectif →
  Projet → Tâche ») + les
  « indicateurs de progression »
  (doc §2.6) = un `ProgressBar` +
  les jalons (`RoutineStep`).
- **Zones** : liste = une liste de
  `Card flat` (un objectif par card,
  le `Badge` de terme : court/moyen/
  long, `JetBrains Mono` `xs`) ;
  détail = une `KeyValueList` (la
  date, le terme, la progression) +
  un `ProgressBar` + une liste de
  `RoutineStep` (les jalons) + un
  `KeyValueList` (les projets qui y
  **contribuent** — chaque projet
  est un `ListItem` qui **pousse**
  `projets-detail` §4.3.2).
- **DS** : `TopBar`, `Card` (flat),
  `Badge`, `KeyValueList`,
  `ProgressBar`, `RoutineStep`,
  `ListItem`, `EmptyState`,
  `Breadcrumb` (§3.4, `Objectif` est
  la **racine** de la hiérarchie
  doc §2.6 — pas de breadcrumb au-
  dessus de l'objectif lui-même,
  c'est le **niveau 0**).
- **États** : `loading`/`empty`/
  `error`/`offline` = **identiques**
  à `projets-liste`/`projets-detail`
  §4.3.1/§4.3.2 (le pattern est
  **le même**, les types sont
  différents — `Objectif` vs
  `Projet` AD-15, le DS est
  **agnostique** du type métier,
  il rend des **projections**, pack
  02 §4 : les `*Row`/`*Card` sont
  des **projections déclarées**
  du type partagé AD-15).
- **Transitions** : liste → détail
  (un push, le détail est une
  **route** §4.3.2 pattern) ; un
  projet dans le détail →
  `projets-detail` §4.3.2 ; le FAB
  (liste) ouvre une `BottomSheet` de
  création d'objectif (un
  `TextField` titre + un `Select`
  terme court/moyen/long).
- **Notes responsive (Phase 2)** :
  desktop = la liste devient une
  **grille 2 colonnes** de Cards
  (les objectifs sont **riches**,
  comme les projets §4.3.1 note) ;
  le détail a un **panneau latéral**
  pour les jalons/projets (les 2
  sections s'affichent **côte à
  côte**, doc §23.4).

#### 4.3.5 `habitudes` (doc §2.7)
- **Objectif** : **suivre** les
  habitudes quotidiennes/hebdo et
  les routines (matin/soir, étude —
  doc §2.7) ; l'**adhérence** est
  **visible** (pas un compteur, un
  **pattern** — doc §2.7 « Analyse
  de l'adhérence », « Détection des
  habitudes perturbatrices »).
- **Zones** : header (`TopBar`
  « Habitudes » + un `Menu` :
  « Routines » (les routines = un
  mode séparé) / « Adhérence »
  (l'analyse)) ; content (une liste
  d'habitudes = une `Card flat` par
  habitude : le titre + un
  `HabitStreak` §3.6.12 (la heatmap
  7 colonnes × 5 semaines) + un
  `Button secondary` « Marquer
  aujourd'hui » (le **check-in
  quotidien** de l'habitude, doc §2.7
  « Suivi de régularité » — un tap
  **unique**, pas un formulaire) +
  un `KeyValueList` compact (le
  « streak courant » en
  `JetBrains Mono` `lg`, ex. « 12
  jours ») ; footer (`BottomNav`).
- **DS** : `TopBar`, `Menu`,
  `Card` (flat), `HabitStreak`,
  `Button` (secondary),
  `KeyValueList`, `EmptyState`,
  `Skeleton`.
- **États** : `loading` = les
  Cards en Skeleton (le store
  local, court) ; `empty` = un
  `EmptyState` : icône « habitude
  », « Aucune habitude — commencez
  par une seule, par jour » + CTA
  « Créer une habitude » (le
  `EmptyState` **insiste** sur le
  « une seule » — doc §12 « simple
  en surface », une habitude à la
  fois, pas 8) ; `error` = une
  habitude non syncée = un
  `Badge danger` sur la Card
  (l'habitude **reste**, AD-7) ;
  `offline` = la liste
  **fonctionne**, le
  « Marquer aujourd'hui » reste
  **possible** (l'écriture est
  locale, pack 03 — le check-in
  quotidien **ne** doit pas
  **exiger** le réseau, AD-7).
- **Transitions** : une Card →
  un détail en `BottomSheet`
  (l'analyse de l'habitude : les
  `Timeline` §3.6.3 de ses
  reports + les `HabitStreak`
  **étendus** (12 mois) + les
  « routines perturbatrices » qui
  la **ciblent** (doc §2.7 «
  Détection des habitudes
  perturbatrices » = un
  `KeyValueList` de routines
  **liées** qui **s'opposent** —
  l'habitude « lire » est
  perturbée par la routine «
  écran le soir », ce lien est
  **affiché** (pas un « insight »
  mystérieux, §1 « calme »)) ;
  le FAB ouvre une `BottomSheet` de
  création d'habitude (un
  `TextField` titre + un
  `SegmentedControl` « quotidien /
  hebdo » §3.4 + un `Select`
  d'heure).
- **Notes responsive (Phase 2)** :
  desktop = les Cards passent en
  grille 2 colonnes ; le
  `HabitStreak` s'élargit (la
  heatmap devient **12 semaines**
  visibles, pas 5 — le desktop a
  la **largeur**, le mobile est
  **compact** par design, §2.6
  règle 1 : la donnée est
  **dense** sur desktop, pas
  « plus jolie »).

#### 4.3.6 `routines` (doc §2.7)
- **Objectif** : **voir** et
  **exécuter** les routines (matin/
  soir, étude — doc §2.7) ; une
  routine **est** une suite
  ordonnée d'étapes
  (`RoutineStep` §3.6.12), pas
  une liste de to-do (les to-do
  vivent dans `taches-liste`
  §4.2.2, la routine est une
  **séquence**, le §2.7 « Routines
  matin/soir et routines d'étude »).
- **Zones** : header (`TopBar`
  « Routines » + un
  `SegmentedControl` « Matin |
  Soir | Étude » §3.4 — 3
  familles, doc §2.7, **pas** un
  select : le choix est
  **exclusif** et
  **binaire/ternaire**, le
  `SegmentedControl` est
  **justifié** ici, §3.4) ;
  content (une liste de
  `RoutineStep` §3.6.12 — chaque
  étape = numéro + `Checkbox` +
  titre + durée estimée
  `JetBrains Mono` `xs`) + un
  `ProgressBar` (le % de
  complétion de la routine du
  jour, doc §2.7 « Suivi de
  régularité ») + un `Callout
  warning` **posé** si une
  routine est **perturbée**
  (doc §2.7 « Détection des
  habitudes perturbatrices » —
  « Votre routine du matin est
  incohérente cette semaine ») ;
  footer (`BottomNav`).
- **DS** : `TopBar`,
  `SegmentedControl`,
  `RoutineStep`, `ProgressBar`,
  `Callout`, `EmptyState`,
  `Skeleton`. Un bouton
  « Tout faire » **n'existe
  pas** — la routine est
  **séquentielle**, pas un
  « play » automatique, doc §2.7 :
  l'habitude **appartient**
  à l'utilisatrice, l'app ne
  « joue » pas la routine à sa
  place, §1 « simple en surface »).
- **États** : `loading` = les
  étapes en Skeleton (le
  numéro reste, la valeur pulse —
  la **structure** est connue,
  les **durations** peuvent
  être syncées, §3.6.12) ;
  `empty` = un
  `EmptyState` par famille
  (le tab « Soir » vide = «
  Aucune routine du soir —
  créez-en une » + CTA) ;
  `error` = une étape non
  syncée = un `Badge danger`
  sur l'étape (l'étape
  **reste**, AD-7) ;
  `offline` = les routines
  restent **lisibles** (lecture
  locale, AD-7), le
  « Marquer l'étape » reste
  **possible** (l'écriture est
  locale, pack 03 — une
  routine ne doit jamais
  exiger le réseau, AD-7).
- **Transitions** : un tap sur une
  `RoutineStep` **coche** l'étape
  (pas de push — le check est
  **inline**, doc §2.7 « suivi de
  régularité » : la régularité
  se **voit** dans le
  `ProgressBar` qui avance, pas
  dans un écran de confirmation) ;
  le FAB ouvre une `BottomSheet`
  de création de routine (un
  `TextField` titre + un
  `SegmentedControl` « Matin /
  Soir / Étude » + un
  `MultiSelect` d'étapes
  existantes ou un `Button
  ghost` « Nouvelle étape » qui
  **empile** une `RoutineStep`
  vide dans la sheet, §3.2).
- **Notes responsive (Phase 2)** :
  desktop = les 3 familles
  (matin/soir/étude) passent en
  **3 colonnes côte à côte** (le
  `SegmentedControl` disparaît —
  le desktop a la **largeur** pour
  montrer les 3 en même temps,
  doc §23.4) ; les
  `RoutineStep` s'élargissent
  (la durée devient un `Slider`
  inline édite par l'
  utilisatrice, §3.2
  `Slider`).

### 4.4 Module Productivité — calendrier & focus (doc
§2.4, §2.8)

#### 4.4.1 `calendrier-jour` / `calendrier-semaine` /
`calendrier-mois` (doc §2.4)
- **Objectif** : **voir** et **planifier** les
  événements/tâches selon l'échelle (jour /
  semaine / mois — doc §2.4 « Calendrier
  jour/semaine/mois ») ; le `Pager` §3.4 est
  **le** composant partagé des 3 écrans (le
  `SegmentedControl` du `Pager` **est** le
  switch jour/semaine/mois — les 3 écrans
  partagent **le même** composant, pas 3
  vues séparées, doc §2.4 « Agenda »).
- **Zones** : header (`TopBar` «
  Calendrier » + le `Pager` §3.4
  (Jour/Semaine/Mois + la navigation
  avant/après + « Aujourd'hui »)) ;
  content (selon le mode du `Pager` :
  **jour** = une liste `RoutineStep`-
  like des événements de la journée
  (heure en `JetBrains Mono` `xs`,
  un `Badge` par type : cours /
  examen / réunion / devoir /
  révision / projet / routine — doc
  §2.4 « Cours, examens, réunions,
  devoirs, révisions, projets et
  routines » : 7 types = 7 `Badge`,
  les couleurs suivent le type,
  **pas** le statut (le statut =
  `Badge` de la tâche si l'événement
  **est** une tâche) ; **semaine**
  = une grille 7 colonnes × 48h
  (lignes d'heures, `JetBrains Mono`
  `xs`), chaque case = un
  `CalendarCell` §3.6 (les
  événements sont **empilés**
  verticalement dans la case, un
  `ProgressBar` minuscule si
  l'événement a une durée
  pluri-jours) ; **mois** = une
  grille 7×5 `CalendarCell` (une
  pastille par événement, max 3
  visibles + un « +N » en `xs` si
  plus — le mois est **dense**, le
  détail passe au mode jour/semaine,
  §12) ; footer (`BottomNav`).
- **DS** : `TopBar`, `Pager`
  (`SegmentedControl` +
  navigation), `RoutineStep` (mode
  jour), `CalendarCell` (modes
  semaine/mois), `Badge` (le type
  d'événement), `ListItem` (si un
  événement est **détailé** dans
  le mode jour), `EmptyState` (un
  jour vide), `Skeleton`,
  `Callout` (un « conflit de
  planning » = un `Callout
  warning` **posé** au-dessus du
  jour concerné — doc §2.4
  « Détection des conflits et de la
  surcharge » : le conflit est
  **visible**, pas caché ; «
  temps de travail
  surchargé » = un `Callout
  warning` du jour (le temps
  réellement planifié vs le temps
  disponible, doc §2.4 «
  Planification selon le temps
  réellement disponible »).
- **États** : `loading` = les
  cellules/`RoutineStep` en
  Skeleton (le store local, court,
  pack 02 §7) ; `empty` = un jour
  vide = un `Callout info` «
  Aucun événement — ajoutez-en
  un » (pas un vide **mort** :
  le CTA ouvre une
  `BottomSheet` de création
  d'événement avec un
  `DateField` pré-rempli au
  jour courant, §3.2) ; `error` =
  un événement non syncé = un
  `Badge danger` « à resync »
  (l'événement **reste** dans la
  case, AD-7) ; `offline` = le
  calendrier **fonctionne**
  (lecture locale, AD-7), la
  création reste **possible**
  (écriture locale, pack 03),
  seul le **scan de documents**
  liés à un événement est
  désactivé.
- **Transitions** : un
  `CalendarCell` (semaine/mois)
  → le **jour** concerné (le
  `Pager` passe en mode jour,
  **pas** un push séparé — le
  drill-down **est** le switch de
  mode du `Pager`, la règle de
  non-surprise : l'écran de
  calendrier est **un seul**
  écran avec 3 modes, pas 3
  écrans ; le Breadcrumb
  **n'existe pas** ici (le
  calendrier est une **feuille**
  du module Productivité, pas une
  hiérarchie AD-6 comme le
  `SemanticTree`) ; un événement
  → un `ListItem` qui **pousse**
  le détail (si l'événement
  **est** une tâche →
  `taches-detail` §4.2.3 ; si
  c'est un événement **pur**
  (doc §2.4 « réunion ») → une
  `BottomSheet` de détail
  `BottomSheet` §3.5) ; un
  `Callout warning` de conflit →
  un `Button ghost` «
  Replanifier » qui ouvre
  l'`agent` §4.40 (la
  replanification est une
  capacité du kernel, doc §2.4
  « Replanification assistée par
  l'agent » — l'app ne
  **calcule pas** elle-même,
  elle **demande** au kernel,
  AD-12/F-09 : le kernel est
  **serveur**, l'app est la
  surface).
- **Notes responsive (Phase 2)** :
  desktop = le mode **semaine**
  devient une **grille 7 colonnes
  × 24h** (pas 48h — le desktop
  a la **hauteur**, le mobile
  compacte à 48h, §2.3) ; le mode
  **mois** devient 7×5 cellules
  **plus larges** (les
  événements s'affichent en
  **texte** pas en pastille si
  la case est **vide** — le
  desktop a l'espace pour
  montrer le **titre**, le
  mobile reste **compact** en
  pastille, §1 « dense
  progressivement ») ; le
  `Pager` reste **identique**
  (le composant est
  **mobile/desktop-agnostique**,
  doc §23.4).

#### 4.4.2 `focus-mode` (doc §2.8)
- **Objectif** : **concentrer**
  (pas « voir » le focus — le
  focus est une **action**, pas
  une donnée, AD-14 bloc 6 :
  « Accès Focus » = un
  `Button`, pas une Card).
- **Zones** : **pas** de
  `TopBar` (le Focus **enlève**
  le chrome, doc §2.8 «
  anti-distraction » : l'écran
  est **minimal**) ; content
  (un `FocusTimer` §3.6.9 — le
  ring 160px + le temps restant
  `3xl` `JetBrains Mono` au
  centre + le label de la tâche
  focusée en `sm`
  `text-secondary` sous le ring)
  + un `SegmentedControl`
  « Pomodoro | Temps libre »
  §3.4 (le mode de session, doc
  §2.8 « Minuteur/Pomodoro » —
  Pomodoro = 25 min + 5 min de
  break, temps libre = le
  `Slider` 5–90 min
  personnalisé) + un `KeyValueList`
  compact (les tâches
  **associées** à la session,
  doc §2.8 « sessions de
  concentration » : le
  `FocusSession` AD-15 porte
  `taskIds`, le `KeyValueList`
  affiche les titres des tâches
  liées) ; footer (le
  `BottomNav` est **masqué** —
  le Focus **enlève** la
  navigation, l'utilisateur est
  **dedans**, pas « dessus » ;
  le retour au `BottomNav`
  s'effectue par le back Android
  ou un `IconButton` « Terminer
  la session » en bas, pas par
  le nav) ; surfaces
  flottantes (un `Callout info`
  **posé** en haut (le seul
  chrome restant) : « Les
  notifications sont réduites
  pour cette session » —
  l'affichage de la capacité
  **réelle** du
  `FocusController` (pack 04
  §4.2 : « l'UI affiche la
  capacité **réelle** » — la
  réduction des
  notifications, **pas** le
  blocage qui n'existe pas sur
  Android, pack 04 §4.1).
- **DS** : `FocusTimer`
  (§3.6.9), `SegmentedControl`
  (Pomodoro/Temps libre),
  `Slider` (la durée, si mode
  « temps libre »),
  `KeyValueList` (les tâches
  associées), `Callout` (la
  réduction des notifications),
  `IconButton` (« Terminer la
  session », `ghost`, pas
  `destructive` — terminer le
  focus n'est **pas** destructif,
  le timer **enregistre** le
  bilan, doc §2.8 « Bilan de
  session »), `Button`
  (`primary` : « Démarrer » —
  le seul CTA de l'écran).
- **États** : `loading` = le
  timer ne se « charge »
  **pas** (le temps est connu,
  §3.6.9 — le seul `loading`
  **parmi** les états du Focus =
  le **bilan** de fin de session
  qui arrive, un `Skeleton` du
  bilan, pack 04 §4.1 point 4 :
  le bilan **doit** exister dans
  l'inventaire avec le G2
  contractuel, §3.6.9) ; `empty`
  n'existe **pas** (un
  `FocusSession` vide = une
  session qui **n'a pas** de
  tâches associées = le
  `KeyValueList` affiche
  « Aucune tâche associée » —
  le Focus **fonctionne
  quand même** (on peut
  concentrer **sans** tâche,
  doc §2.8 : la concentration
  n'est pas **conditionnée**
  par une tâche) ; `error` =
  un échec de **bilan** (le
  timer **continue** de
  tourner, la session n'est
  **pas** perdue à cause d'un
  échec de bilan, AD-7 —
  l'état `error` = un `Callout
  danger` **sous** le timer,
  le timer reste
  **préeminent**) ; `offline` =
  le Focus est **parfaitement**
  fonctionnel (tout est local :
  le timer, les tâches
  associées, la réduction des
  notifications **locales** via
  `LocalNotificationAdapter`
  pack 04 §3.2.5 — les
  notifications **OneSignal**
  (serveur, pack 04 §3.4) sont
  **uniquement** réduites si le
  réseau le permet ; sans
  réseau, la réduction se
  limite aux **locales**,
  c'est la capacité **réelle**
  affichée dans le `Callout
  info`, pack 04 §4.2 : «
  l'UI affiche la capacité
  **réelle** »).
- **Transitions** : « Terminer
  la session » → un
  `BottomSheet` de
  **bilan** (le `FocusSessionBilan`,
  pack 04 §4.1 point 4 : durée
  réelle, interruptions, score
  de concentration — le bilan
  est un `ChartSpec` consommé
  par `DataVisualizationRenderer`
  G2, pack 02 §5.3 : « l'écran
  de bilan Focus **doit** être
  dans l'inventaire d'écrans du
  pack 05 avec le G2
  contractuel », pack 04 §4.1)
  + un CTA « Revenir au Home »
  (le bilan **précède** le
  retour, pas l'inverse —
  l'utilisateur **voit** le
  résultat **avant** de quitter
  le Focus, doc §2.8 « Bilan de
  session ») ; un `Callout
  info` de réduction qui **échoue**
  (pas de `LocalNotificationAdapter`
  dispo) = un `Callout warning`
  à la place (la capacité
  **réelle** n'a pas pu être
  mise en place, pack 04 §4.2 :
  « l'UI affiche la capacité
  **réelle** » — un échec de
  réduction **doit** être
  signalé, pas caché).
- **Notes responsive (Phase 2)** :
  desktop = le Focus passe en
  **fenêtre** (pas plein
  écran — le desktop permet de
  **rester** sur une autre
  fenêtre pendant le Focus, la
  concentration **n'exige
  pas** l'exclusivité du
  viewport sur desktop, doc
  §23.4) ; le `FocusTimer`
  reste **identique** (le
  composant est
  **plateforme-agnostique**,
  le timer = l'horloge
  système, pas un compteur
  d'écran, pack 04 §6.1) ;
  la **réduction** des
  notifications passe par
  l'adapter Electron (les
  notifications natives, spine
  §Stack « Electron native ») —
  le composant **n'a pas
  changé**, seul l'adapter a
  changé (doc §23.4 « ajouter
  les adapters Electron
  nécessaires »).

### 4.5 Module Productivité — revues & analytics
(doc §2.9, §2.10)

#### 4.5.1 `revues-jour` / `revues-semaine` /
`revues-mois` (doc §2.9)
- **Objectif** : **réviser**
  (pas « voir » les revues —
  une revue est une **action**
  périodique, doc §2.9
  « Revue quotidienne /
  hebdomadaire / mensuelle ») ;
  la revue est un **formulaire**
  guidé (pas un free-form
  journal — le DS **structure**
  la revue, l'utilisateur
  **remplit**, §1 « simple en
  surface, puissant en
  profondeur » : la structure
  est **fixe** par échelle
  (jour/semaine/mois), le contenu
  est **libre** dans la
  structure).
- **Zones** : header (`TopBar`
  « Revue » + le `Pager`
  §3.4 (Jour/Semaine/Mois) + un
  `SegmentedControl` « À faire /
  Faite » §3.4 (le statut de la
  revue — une revue **à faire**
  est une `Review` AD-15
  `pending`, une revue **faite**
  est `completed`, le
  `SegmentedControl` bascule
  entre les 2 statuts, pas
  3 — le 3ᵉ « annulée » n'est
  **pas** un état de revue, une
  revue annulée = une
  `Callout info` **historisée**,
  pas un tab actif) ;
  content (une `Review` = une
  `Card` **posée** (pas un
  `ListItem` : une revue est
  **riche** (bilan + causes +
  plan, doc §2.9 « Bilan des
  tâches accomplies, reportées,
  abandonnées et bloquées /
  Analyse des causes de retard /
  Révision des priorités / Plan
  d'action suivant / Journal
  des décisions importantes » =
  **5 sections** — une Card,
  pas 5 lignes de liste) ;
  les 5 sections = 5
  `KeyValueList`/`TextArea`/
  `RoutineStep` **mixtes** :
  « Bilan des tâches » = un
  `DataTable` §3.6.1 (les
  tâches accomplies/reportées/
  abandonnées/bloquées, 4
  colonnes : statut / titre /
  projet / « pourquoi »
  (cause, doc §2.9 « Analyse
  des causes de retard ») ;
  « Révision des priorités » =
  une liste `RoutineStep`
  (les nouvelles priorités,
  ordonnées, doc §2.9) ;
  « Plan d'action suivant » =
  une liste `RoutineStep`
  (les actions, doc §2.9) ;
  « Journal des décisions » =
  une `TextArea` (le texte
  libre, doc §2.9 « Journal des
  décisions importantes ») ;
  « Analyse des causes » = une
  `TextArea` + un `Badge`
  d'hypothèse de cause (le
  « pourquoi » est **structuré**
  par 3 `Chip` de cause
  courantes (charge / fatigue /
  blocage technique — les
  3 causes les plus courantes
  en génie civil, doc §2.9
  « Analyse des causes de
  retard »), le reste est
  libre dans la `TextArea`) ;
  footer (`BottomNav`).
- **DS** : `TopBar`, `Pager`
  (le `SegmentedControl`
  jour/semaine/mois),
  `SegmentedControl` (à
  faire/faite), `Card`,
  `DataTable` (le bilan des
  tâches), `RoutineStep`
  (les priorités/actions),
  `TextArea` (le journal,
  l'analyse des causes),
  `Chip` (les 3 causes
  courantes), `Callout` (un
  « revue en retard » = un
  `Callout warning` **posé**
  si la revue de la période
  précédente **n'a pas** été
  faite, doc §2.9 « Pilotage
  personnel » — le retard est
  **signalé**, pas caché),
  `EmptyState` (pas de revue
  dans la période),
  `Skeleton`.
- **États** : `loading` = les
  sections de la revue en
  Skeleton (le store local,
  court) ; `empty` = pas de
  revue dans la période = un
  `EmptyState` : icône
  « revue », « Pas de revue
  cette semaine » + CTA « Faire
  la revue » (la CTA ouvre la
  `BottomSheet` de création de
  revue — une `Review` AD-15
  `pending` est **créée**, pas
  « une action à planifier »,
  la revue **est** l'action,
  doc §2.9) ; `error` = une
  revue non syncée = un
  `Badge danger` « à resync »
  sur la Card (la revue
  **reste** lisible, AD-7) ;
  `offline` = les revues
  restent **lisibles** (lecture
  locale, AD-7), la création
  reste **possible** (écriture
  locale, pack 03) — une
  revue **n'exige jamais** le
  réseau (c'est une
  **auto-évaluation**, pas une
  requête de l'agent, doc
  §2.9 : le pilotage est
  **personnel**, l'agent
  **suggère** (doc §2.9
  « Suggestions d'ajustement par
  l'agent »), l'utilisateur
  **décide**).
- **Transitions** : « Faire la
  revue » → la `BottomSheet` de
  création (les 5 sections sont
  **pré-remplies** par les
  données locales (le bilan des
  tâches vient du `Task` AD-15
  local, les priorités viennent
  du `Goal` AD-15 local — la
  revue est **pré-remplie**,
  l'utilisateur **ajuste**,
  pas « écrit à blanc », doc
  §12 : simple en surface) ;
  un `Callout` de retard → un
  `Button ghost` « Suggérer
  un ajustement » qui ouvre
  l'`agent` §4.40 (la
  suggestion est une capacité
  du kernel, AD-12/F-09,
  doc §2.9 « Suggestions
  d'ajustement par l'agent ») ;
  une `RoutineStep` du plan
  d'action → si l'étape
  **devient** une tâche, un
  `Button ghost` « En faire une
  tâche » (le plan d'action
  **sert** à créer des tâches,
  doc §2.9 « Plan d'action
  suivant » : la revue
  **génère** des tâches, pas
  l'inverse).
- **Notes responsive (Phase 2)** :
  desktop = les 5 sections de
  la revue passent en **2
  colonnes** (le bilan à
  gauche, le reste à droite) —
  la logique (5 sections) est
  **inchangée**, le layout
  s'adapte (doc §23.4) ; le
  `Pager` reste **identique**
  (le composant est
  **plateforme-agnostique**).

#### 4.5.2 `analytics` (doc §2.10)
- **Objectif** : **mesurer**
  (pas « voir » les
  statistiques — les stats sont
  **secondaires**, la
  **mesure** est
  **primaire** : l'analystique
  est le **miroir** de la
  progression, pas le
  tableau de bord, §1 «
  calm » : l'écran est
  **structuré** par
  question (les 5 questions
  fondamentales du Progress,
  doc §18.1), pas par widget
  (pas un « dashboard de
  KPIs », AD-14).
- **Zones** : header (`TopBar`
  « Analytics » + un `Menu`
  de période : 7j / 30j /
  semestre / année (doc §18.2
  « Progression temporelle » :
  les 4 échelles — le
  `Menu` §3.5, 4 items, pas
  un `SegmentedControl` (4
  segments = trop, §3.4 :
  max 3) ;
  content (les 5 questions
  fondamentales du doc §18.1
  **structurent** l'écran (pas
  des widgets libres) :
  « Où en suis-je
  réellement ? » = un
  `StatTile` par dimension
  (doc §18.2 : académique /
  compétences / réelle vs
  illusion / temporelle /
  objectifs / professionnelle /
  oubli / discipline — 8
  dimensions = 8 `StatTile`,
  **pas** 8 widgets empilés :
  les 8 sont **groupés** en
  2×4 (le `StatTile` §3.3
  tolère 4 max par écran,
  §3.3 : les 8 passent en
  **2 écrans** ou en scroll
  vertical de 2 groupes
  (académique+compétences+
  illusion / temporelle+
  objectifs+professionnelle+
  oubli+discipline) — le scroll
  **structure** les 8, il ne
  « les empile pas »
  aléatoirement, §1) ;
  « Qu'est-ce qui s'est
  réellement amélioré ? » =
  un `Timeline` §3.6.3 (les
  preuves de progression,
  doc §18.3 : QCM / rappel
  actif / exercice / explication
  — les 8 types de
  `ProgressEvidence`
  AD-15, chaque preuve = un
  point de la timeline) ;
  « Qu'est-ce qui stagne,
  régresse ou a été oublié ? »
  = un `Callout warning` **posé**
  (les stagnations, doc §18.2
  « Oubli et consolidation » :
  les compétences qui se
  dégradent, l'écran **affiche**
  le `Callout` **avant** les
  8 `StatTile` — le
  **problème** précède la
  mesure, pas l'inverse, doc
  §18.1 : l'ordre des
  questions = l'ordre de
  l'écran) ; « Pourquoi cette
  évolution ? » = un
  `Callout info` (l'analyse
  causale, doc §18.4 : la
  corrélation ≠ la causalité,
  le `Callout` **affiche**
  l'hypothèse de cause
  **testée** par l'agent, pas
  une vérité) ; « Quelle
  prochaine action ? » = un
  `Button primary` (la
  « prochaine action
  productive », doc §18.1 —
  le CTA ouvre
  l'`agent` §4.40 :
  l'analyse causale
  **alimente** l'agent,
  l'agent **suggère**,
  l'utilisateur **décide**,
  doc §18.7 « Progress comme
  moteur agentique ») ;
  footer (`BottomNav`).
- **DS** : `TopBar`, `Menu`
  (les 4 périodes),
  `StatTile` (les 8
  dimensions, 2×4),
  `Timeline` (les preuves,
  doc §18.3), `Callout`
  (warning de stagnation,
  info de causalité),
  `Button` (primary, la
  prochaine action),
  `Sparkline` (le 7 derniers
  jours dans chaque
  `StatTile` — la tendance
  **micro** accompagne le KPI,
  §3.6.5), `EmptyState`
  (pas de données sur la
  période), `Skeleton`.
- **États** : `loading` = les
  8 `StatTile` + le
  `Timeline` en Skeleton (le
  store local, les 8
  dimensions sont
  **calculées** par le module
  Progress, pas lues
  directement — le `loading`
  **couvre** le calcul
  (la donnée est locale,
  l'agrégation est
  **rapide**, pack 02 §7 :
  le `loading` est **court**)
  ; `empty` = une période sans
  données = un `EmptyState`
  par dimension (pas un
  vide global : 7 vides +
  1 rempli = **7**
  `EmptyState` compacts, pas
  1 `EmptyState` global qui
  « cache » la 1 dimension
  remplie — le DS **n'aggrave
  jamais** l'état de l'autre,
  la donnée reste visible,
  AD-7) ; `error` = une
  dimension qui **échoue** à
  se calculer = un
  `Callout danger` **sous** la
  dimension (les 7 autres
  restent, AD-7) ; `offline`
  = les 8 dimensions
  **locales** restent
  (l'agrégation est
  **locale** (SQLite), l'agent
  est **serveur** —
  l'analyse causale (le
  `Callout info` de
  « Pourquoi ») est
  **désactivée** avec un
  `Callout info` « L'analyse
  causale nécessite le réseau
  — l'état actuel est
  affiché sans analyse »
  (la donnée **locale** reste,
  l'analyse **serveur**
  attend, AD-7/AD-12 :
  l'agent est **serveur**,
  pas local, pack 02 §6.4).
- **Transitions** : un
  `StatTile` → un détail en
  `BottomSheet` (les preuves
  de cette dimension — le
  `Timeline` s'élargit, la
  `Sparkline` devient un
  `DataChart` complet avec
  axes §3.6.5 — le
  drill-down **est** le
  switch du `StatTile` en
  détail, pas un push
  séparé) ; le `Button
  primary` « Prochaine
  action » → l'`agent`
  §4.40 (la suggestion est
  **générée** par le kernel,
  l'app est la surface,
  AD-12/F-09) ; le `Menu` de
  période → le `Pager`
  §3.4 s'adapte (le
  `SegmentedControl` passe de
  3 à 4 options si l'on
  ajoute l'échelle
  « semestre » — le
  `Pager` reste **le
  composant**, le switch
  d'échelle est **une**
  option du `Pager`, pas
  4 écrans séparés).
- **Notes responsive (Phase 2)** :
  desktop = les 8
  `StatTile` passent en
  **grille 4×2** (pas 2×4 —
  le desktop a la
  **largeur**, les 4 par
  ligne) ; le `Timeline`
  s'élargit (les preuves
  s'affichent en
  **texte** pas en
  pastille, le desktop a
  l'espace pour le
  **titre**, §1 « dense
  progressivement ») ;
  l'analyse causale
  (serveur, AD-12)
  **reste** le même
  `Callout` (le composant
  est **plateforme-
  agnostique**, seul
  l'agent est serveur,
  doc §23.4 : « réutiliser
  les contrats existants »).

### 4.6 Module Learning — bibliothèque & cours
(doc §2.11, §3)

#### 4.6.1 `bibliotheque-ressources` (doc §2.11)
- **Objectif** : **retrouver**
  (pas « classer » — les
  ressources sont **rattachées**
  aux matières/compétences/
  projets/objectifs, doc §2.11
  « Rattachement à matière,
  compétence, projet, objectif
  ou session » : la
  bibliothèque est le **miroir**
  du rattachement, pas un
  catalogue libre) ; la
  recherche universelle
  (doc §2.1 « Recherche
  universelle et Command
  Palette ») **vive** dans
  l'inbox, pas ici — ici
  c'est le **listing**, pas
  la recherche (la
  recherche est un overlay
  global, pack 02 §6.3 :
  l'`IonModal` de
  `commandPaletteOpen`, pas
  un écran).
- **Zones** : header
  (`TopBar` « Bibliothèque » +
  un `Menu` de filtre : par
  matière / par type / par
  projet — le `Menu` §3.5,
  max 6 items) ; content
  (une liste de
  `ListItem` `subtitle` —
  chaque ressource = titre +
  type en `Badge` (PDF /
  DOCX / PPTX / XLSX / image /
  audio / vidéo / Markdown /
  texte / code / LaTeX /
  autre — les 12 types du
  doc §16 « Visualisation
  universelle des fichiers et
  artefacts », les 12
  `Badge` couvrent les 12
  types, **pas** 12 icônes
  différentes : le `Badge`
  affiche le type en texte
  (pas une icône par type —
  le type est **lisible**,
  pas reconnu, §1 «
  lisibilité technique ») +
  date en `JetBrains Mono`
  `xs`) + un
  `ProgressBar` si la
  ressource a une
  progression de lecture
  (un PDF lu à 60%, un cours
  audio écouté à 30% — la
  progression est **par
  ressource**, doc §2.11
  « cours, PDF, documents,
  images, vidéos ») ; footer
  (`BottomNav`).
- **DS** : `TopBar`,
  `Menu`, `ListItem`
  (`subtitle`), `Badge`
  (le type de ressource),
  `ProgressBar` (la
  progression de lecture),
  `EmptyState`, `Skeleton`,
  `FAB` (« Importer », §3.1
  — l'écran de **création**
  a son FAB : le FAB ouvre
  le scanner pack 04
  §3.2.3 ou l'import
  local, §4.6.1 note).
- **États** : `loading` =
  les items en Skeleton (le
  store local, les
  ressources sont
  **lourd** (les PDF, les
  cours audio) — le
  `loading` **couvre**
  l'index local, pas le
  téléchargement (le
  téléchargement est un
  job serveur AD-8,
  l'index est local
  AD-7) ; `empty` = un
  `EmptyState` : icône
  « bibliothèque »,
  « Aucune ressource —
  importez votre premier
  cours » + CTA « Importer
  » (le CTA ouvre le
  scanner pack 04
  §3.2.3 **ou** un
  `BottomSheet` de
  sélection de source
  (fichier local /
  scanner / lien web —
  les 3 sources du
  doc §16 « tout
  fichier importé ou
  généré », §4.6.1) ;
  `error` = une ressource
  non syncée = un
  `Badge danger` « à
  resync » (la ressource
  **reste** visible, son
  type est **connu**
  localement, AD-7) ;
  `offline` = la liste
  **fonctionne** (lecture
  locale, AD-7),
  l'**import** reste
  **possible** si c'est
  un fichier **local**
  (l'écriture est
  locale, pack 03) —
  l'import **web**
  (le lien) et le
  **scanner** (l'OCR,
  job serveur pack 01)
  sont **désactivés**
  avec un `Callout info`
  (l'action cloud,
  pack 02 §7
  `offline`).
- **Transitions** : une
  `ListItem` →
  `artefacts-detail`
  §4.34 (l'aperçu de
  la ressource, doc
  §16 : « tout
  fichier importé
  ou généré doit
  disposer d'un
  parcours de
  visualisation ») ;
  le FAB → le
  scanner (pack 04
  §3.2.3) ou la
  `BottomSheet`
  d'import ; un
  `ProgressBar` de
  lecture qui
  **toure** (la
  progression
  change) = un
  « dernier lu »
  en `xs` sous
  le titre (la
  date du dernier
  accès, pas
  la durée —
  le §18.2
  « Oubli et
  consolidation »
  lit les dates
  d'accès, pas
  la durée de
  lecture, la
  durée est un
  `FocusSession`,
  pas une
  ressource).
- **Notes responsive
  (Phase 2)** :
  desktop = la
  liste passe en
  **grille 2
  colonnes** de
  `ListItem` (le
  titre + le type
  + la
  progression,
  pas une Card
  riche — la
  bibliothèque
  est une **liste**
  dense, pas un
  dashboard, §1
  « simple en
  surface ») ;
  le FAB devient
  un `Button`
  dans le
  header (le
  FAB est un
  **mobile-only**
  pattern,
  doc §23.2 —
  desktop = un
  CTA dans
  la `TopBar`) ;
  l'aperçu
  (`artefacts-detail`
  §4.34) passe
  en **fenêtre**
  latérale
  (le détail
  **côte à
  côte** avec
  la liste,
  pas en
  push, doc
  §23.4 :
  « créer des
  layouts
  desktop sans
  modifier la
  logique
  métier »).

#### 4.6.2 `cours-liste` + `cours-detail`
(doc §3, §14)
- **Objectif**
  (liste) : **voir**
  les cours
  (les cours
  **importés**
  par le
  scanner,
  doc §3
  « Suivi
  des
  compétences
  et
  sujets
  maîtrisés/non
  maîtrisés »)
  ; **Objectif**
  (détail) :
  **un** cours,
  sa
  progression
  (les
  chapitres,
  les notions,
  les formules
  — doc §14
  « arbre
  sémantique
  évolutif du
  savoir » :
  le cours
  est la
  **racine**
  d'une
  branche de
  l'arbre,
  pas un
  objet
  isolé).
- **Zones** :
  liste = une
  liste de
  `Card
  flat`
  §3.3
  (un
  cours par
  Card :
  titre
  `md`
  600 +
  `ProgressBar`
  (la
  progression
  du cours,
  doc §3
  « Suivi
  des
  compétences
  et sujets
  maîtrisés/
  non
  maîtrisés »)
  + 2
  `Badge`
  (le niveau
  de
  maîtrise
  global
  (maîtrisé/
  fragile/
  oublié,
  §3.6.11)
  + le
  semestre/
  année en
  `JetBrains
  Mono`
  `xs`) ;
  détail =
  un
  `Breadcrumb`
  §3.4
  (`Cours ›
  Chapitre ›
  Notion`,
  le
  cours est
  le
  **niveau
  1** de
  l'arbre,
  le
  chapitre
  le
  niveau 2,
  la notion
  le niveau
  3 —
  l'arbre
  sémantique
  est
  **hiérarchique**,
  pas un
  graphe,
  doc §14
  « véritable
  arbre
  sémantique
  de
  connaissances
  … hiérarchie
  lisible du
  savoir, et
  non un
  réseau de
  notes ou un
  graphe de
  type
  « second
  brain » »),
  une liste
  de
  `RoutineStep`
  (les
  chapitres,
  les notions
  — chaque
  chapitre =
  une
  « étape »
  avec
  checkbox +
  `SkillStateBadge`
  §3.6.11),
  un
  `KeyValueList`
  (les
  méta :
  enseignant,
  semestre,
  nombre de
  chapitres,
  nombre de
  notions
  maîtrisées/
  fragiles/
  oubliées —
  les 3
  compteurs
  en
  `JetBrains
  Mono`
  `xs`,
  couleurs
  des 3
  familles,
  §3.6.11),
  un
  `Callout
  info`
  (le
  prochain
  chapitre
  à
  travailler,
  doc §3
  « Suivi
  des
  compétences
  et sujets
  maîtrisés/
  non
  maîtrisés »
  : le
  « prochain »
  est
  **calculé**
  par le
  module
  Progress,
  pas
  choisi
  par
  l'utilisateur
  — le
  cours
  **suit**
  la
  progression,
  pas
  l'ordre
  du
  programme,
  doc §18.2
  «
  Progression
  académique
  : suivre
  les
  chapitres,
  concepts,
  définitions,
  formules et
  méthodes
  selon leur
  état :
  découvert,
  compris,
  rappelable,
  fragile,
  maîtrisé,
  oublié »).
- **DS** :
  `TopBar`,
  `Card`
  (flat),
  `ProgressBar`,
  `Badge`,
  `Breadcrumb`
  (§3.4),
  `RoutineStep`
  (les
  chapitres/
  notions),
  `SkillStateBadge`
  (§3.6.11),
  `KeyValueList`
  (§3.6.2),
  `Callout`
  (info, le
  prochain
  chapitre),
  `EmptyState`
  (pas de
  cours
  importés),
  `Skeleton`.
- **États** :
  `loading`
  = les
  Cards/
  sections
  en
  Skeleton
  (le
  store
  local,
  court) ;
  `empty`
  = pas de
  cours =
  un
  `EmptyState`
  : icône
  « cours »,
  « Aucun
  cours
  importé —
  scannez
  votre
  premier
  PDF » +
  CTA
  «
  Scanner »
  (le CTA
  ouvre le
  scanner
  pack 04
  §3.2.3)
  ;
  `error`
  = un
  cours non
  syncé
  = un
  `Badge
  danger`
  sur la
  Card
  (le
  cours
  **reste**
  visible,
  AD-7) ;
  `offline`
  = les
  cours
  restent
  **lisibles**
  (lecture
  locale,
  AD-7),
  le
  **scanner**
  reste
  **possible**
  si c'est
  un
  fichier
  local
  (l'OCR
  est
  serveur,
  pack 01
  — le
  scan
  local
  **fonctionne**,
  l'OCR
  est
  différé,
  pack 02
  §7
  `offline`).
- **Transitions** :
  une
  `Card`
  →
  `cours-detail`
  (un
  push, le
  détail
  est une
  **route**
  (le
  Breadcrumb
  `Cours ›
  Chapitre ›
  Notion`
  est
  **persistant**,
  le cours
  a sa
  propre
  TopBar +
  sub-navigation,
  pas une
  BottomSheet
  comme
  `taches-detail`
  §4.2.3 —
  le cours
  est
  **riche**
  (5
  sections :
  chapitres,
  notions,
  formules,
  progression,
  méta), pas
  une entité
  simple) ;
  une
  `RoutineStep`
  (chapitre)
  →
  `arbre-semantique`
  §4.30
  (le
  chapitre
  **est**
  une
  branche de
  l'arbre,
  doc §14
  : le
  cours
  **ouvre**
  l'arbre
  au
  niveau du
  chapitre,
  pas un
  écran
  séparé —
  le Breadcrumb
  **monte**
  dans
  l'arbre,
  pas
  l'inverse) ;
  un
  `Callout
  info`
  (prochain
  chapitre)
  → un
  `Button
  ghost`
  «
  Travailler »
  qui ouvre
  l'`agent`
  §4.40
  (le
  « travailler »
  est une
  capacité
  du
  kernel,
  AD-12/F-09,
  pas un
  bouton
  local —
  l'app
  **demande**
  à
  l'agent,
  l'agent
  **suggère**,
  l'utilisateur
  **décide**,
  doc §5
  « Orchestration
  agentique
  »).
- **Notes
  responsive
  (Phase 2)**
  : desktop
  = les
  Cards
  passent
  en
  **grille
  2
  colonnes**
  ; le
  Breadcrumb
  du
  cours
  s'élargit
  (les 3
  niveaux
  s'affichent
  en
  **texte**
  pas en
  pastille,
  le
  desktop a
  la
  **largeur**,
  §1 «
  dense
  progressivement
  ») ; le
  FAB
  devient
  un
  `Button`
  dans le
  header
  (le
  scanner
  est un
  **mobile-only**
  pattern,
  doc
  §23.2 —
  desktop
  = un
  CTA
  dans
  la
  `TopBar`).

### 4.7 Module Learning — fiches, QCM, flashcards,
mode coach & mirror (doc §3, §17)

#### 4.7.1 `fiches-liste` + `fiches-detail`
(doc §3, §17)
- **Objectif**
  (liste) :
  **retrouver**
  les fiches
  de
  révision
  (les
  fiches
  **générées**
  par
  l'agent,
  doc
  §17
  « Fiches
  de révision
  intelligentes
  et
  fidèles au
  corpus »)
  ; **Objectif**
  (détail)
  : **une**
  fiche,
  son
  contenu
  (les
  définitions,
  les
  formules,
  les
  méthodes,
  les
  exemples
  — doc
  §17
  « Extraction
  ciblée :
  définitions,
  lois,
  principes,
  formules,
  hypothèses,
  unités,
  méthodes,
  étapes,
  pièges,
  exemples
  et
  relations
  importantes
  »).
- **Zones** :
  liste =
  une
  liste de
  `Card
  flat`
  (une
  fiche par
  Card :
  titre
  `md`
  600 +
  type en
  `Badge`
  (les 7
  types du
  doc
  §17
  « Exemples
  de
  structures
  :
  fiche de
  définitions,
  fiche de
  formules,
  fiche
  méthode,
  fiche
  comparative,
  fiche
  procédure,
  fiche de
  synthèse
  théorique
  et
  fiche
  d'exercices
  » = 7
  `Badge`,
  le type
  **guide**
  la lecture,
  pas
  l'aperçu
  — le
  contenu
  est **sous**
  le type,
  pas le
  type
  lui-même)
  + un
  `SkillStateBadge`
  §3.6.11
  (l'état
  de la
  notion
  couverte
  par la
  fiche,
  doc
  §17
  « Dét

### 4.8 Module Learning — flashcards & QCM (doc §3)

#### 4.8.1 `flashcards` (répétition espacée FSRS, doc §3)
- **Objectif** : **réviser**
  (pas « voir » les cartes — la
  révision est une
  **action**, la
  carte est
  **l'objet**, doc
  §3 « Fiches
  de révision
  IA …
  Flashcards,
  Répétition
  espacée
  FSRS, Rappel
  actif » :
  l'écran
  est une
  **session
  de
  révision**,
  pas une
  liste).
- **Zones** :
  header
  (`TopBar`
  «
  Révision »
  + un
  `Badge`
  compteur
  « 24
  cartes
  dues »
  (le
  compteur
  est
  **statique**,
  §2.6
  règle 1 —
  le chiffre
  ne
  s'incrémenté
  pas « en
  bougeant
  »)
  + un
  `Menu`
  (changer
  de
  matière /
  passer
  la
  session)
  ;
  content
  (un
  `FlashcardCard`
  §3.6.10
  **centré**
  — la
  carte
  est
  **plein
  écran**
  (pas
  une liste
  de
  cartes,
  §1 «
  simple
  en
  surface »
  : une
  carte
  à la
  fois,
  le
  focus
  est
  sur
  la
  carte,
  pas
  sur
  5
  cartes
  empilées)
  + en
  bas,
  les 4
  `Button
  secondary`
  (FSRS :
  « Oublié
  /
  Difficile
  /
  Bon /
  Facile »
  — les
  4
  boutons
  de
  **qualité
  de
  rappel**,
  pas
  4
  boutons
  qui
  « jouent
  » la
  carte,
  §3.6.10
  : le
  feedback
  est
  **séparé**
  du
  contenu
  de la
  carte,
  il
  **suit**
  la
  carte,
  il ne
  la
  **précède
  pas**)
  ;
  footer
  (le
  `BottomNav`
  est
  **masqué**
  — la
  session
  de
  révision
  est
  une
  **action**,
  pas une
  feuille
  de
  nav,
  le
  retour
  au
  `BottomNav`
  s'effectue
  par
  le
  back
  Android
  ou un
  `IconButton`
  «
  Terminer
  la
  session
  »
  (pas
  un
  CTA
  «
  Passer
  à la
  suivante
  »
  — le
  « Passer
  »
  est
  **dans**
  la
  sheet
  de
  fin,
  pas dans
  le
  nav)).
- **DS** :
  `TopBar`,
  `Badge`
  (le
  compteur
  «
  N
  cartes
  dues
  »
  ,
  **statique**,
  §2.6),
  `Menu`
  (§3.5,
  changer
  de
  matière
  ou
  passer
  la
  session),
  `FlashcardCard`
  (§3.6.10,
  le
  flip
  recto/verso),
  `Button`
  (4
  ×
  `secondary`
  ,
  les
  4
  niveaux
  de
  qualité
  FSRS
  ),
  `Callout`
  (un
  `Callout
  info`
  **posé**
  en
  bas
  si
  la
  session
  est
  **terminée**
  :
  «
  Session
  terminée
  —
  N
  cartes
  revisées
  »
  ,
  le
  compteur
  est
  un
  **fait**,
  pas un
  KPI
  ,
  §1
  «
  calme
  »),
  `EmptyState`
  (pas
  de
  cartes
  dues
  =
  un
  état
  **positif**,
  pas un
  vide
  négatif
  ,
  §12
  :
  «
  Aucune
  carte
  due
  —
  tout
  est
  maîtrisé
  »
  +
  CTA
  ghost
  «
  Voir
  les
  fiches
  »
  qui
  ouvre
  `fiches-liste`
  §4.7.1),
  `Skeleton`
  (le
  flip
  de
  la
  carte
  est
  **immédiat**
  ,
  le
  `loading`
  n'existe
  que
  si la
  carte
  **arrive**
  du
  cloud
  ,
  cas
  rare
  local-first
  ,
  AD-7
  ).
- **États** :
  `loading`
  = la
  carte
  en
  Skeleton
  (le
  store
  local
  ,
  la
  carte
  est
  **connue**
  localement
  ,
  le
  flip
  est
  **immédiat**
  —
  le
  `loading`
  **couvre**
  le
  rechargement
  de la
  **prochaine**
  carte
  si elle
  n'est
  pas
  syncée
  ,
  pas la
  carte
  courante
  ) ;
  `empty`
  = pas
  de
  cartes
  dues
  =
  un
  `EmptyState`
  **positif**
  (le
  «
  tout
  est
  maîtrisé
  »
  est
  un
  état
  **visé**,
  pas un
  échec
  ,
  §12
  :
  «
  simple
  en
  surface
  »
  —
  l'écran
  **n'affiche
  pas**
  un
  «
  0
  cartes
  dues
  »
  en
  rouge
  ,
  il
  **invite**
  à
  la
  fiche
  ,
  pas à
  la
  panique
  ) ;
  `error`
  = un
  échec
  de
  sync
  de
  la
  prochaine
  carte
  =
  le
  compteur
  de
  `Badge`
  **reste**
  (les
  cartes
  locales
  sont
  **comptées**,
  pas le
  delta
  cloud
  ,
  AD-7
  )
  +
  un
  `Callout
  danger`
  «
  N
  cartes
  à
  re-synchroniser
  »
  en
  bas
  (le
  compteur
  est
  **présent**,
  pas
  caché
  —
  l'état
  `error`
  est
  **affiché**,
  pas
  silencieux
  ,
  pack 02
  §7
  :
  «
  l'erreur
  est
  lisible
  »)
  ;
  `offline`
  = la
  session
  de
  révision
  **fonctionne**
  (les
  cartes
  locales
  sont
  lisibles
  ,
  AD-7
  )
  —
  le
  feedback
  FSRS
  (les
  4
  boutons
  )
  est
  **écrit
  localement**
  ,
  la
  sync
  se
  fait
  au
  retour
  du
  réseau
  (pack
  03
  §5.5
  re-sync
  )
  —
  une
  révision
  **n'exige
  jamais**
  le
  réseau
  (c'est
  une
  **action
  personnelle**,
  pas une
  requête
  serveur
  ,
  doc
  §3
  :
  «
  Fiches
  de
  révision
  IA
  »
  =
  la
  génération
  est
  IA
  (serveur
  ,
  AD-12
  )
  ,
  la
  **révision**
  est
  **humaine**
  (locale
  ,
  AD-7
  )
  .
- **Transitions** :
  un
  tap
  sur
  la
  carte
  = le
  flip
  (recto
  →
  verso
  ,
  §3.6.10
  :
  le
  flip
  est
  **toujours**
  un
  tap
  au
  centre
  ,
  jamais
  un
  swipe
  latéral
  —
  le
  swipe
  est
  réservé
  à
  la
  navigation
  entre
  écrans
  ,
  doc
  §23.2
  )
  ;
  un
  tap
  sur
  l'un
  des
  4
  boutons
  = la
  carte
  **avance**
  (le
  compteur
  diminue
  ,
  le
  `Badge`
  se
  met
  à
  jour
  **statiquement**
  ,
  §2.6
  :
  le
  chiffre
  **change**,
  il ne
  «
  pulse
  »
  pas
  )
  +
  la
  prochaine
  carte
  apparaît
  (le
  flip
  de
  la
  nouvelle
  carte
  est
  **immédiat**
  ,
  pas
  de
  transition
  entre
  2
  cartes
  si la
  carte
  courante
  est
  locale
  —
  la
  transition
  existe
  **seulement**
  si la
  carte
  **arrive**
  du
  cloud
  ,
  §3.6.10
  )
  ;
  «
  Terminer
  la
  session
  »
  =
  une
  `BottomSheet`
  de
  **bilan**
  (le
  `FlashcardSessionBilan`
  ,
  analogue
  au
  `FocusSessionBilan`
  pack 04
  §4.1
  )
  :
  la
  durée
  réelle
  ,
  les
  N
  cartes
  revisées
  ,
  les
  N
  cartes
  «
  oubliées
  »
  (le
  niveau
  FSRS
  le
  plus
  bas
  ),
  un
  CTA
  «
  Revoir
  les
  oubliées
  »
  (le
  re-passe
  **immediat**
  sur
  les
  cartes
  qui
  ont
  échoué
  ,
  doc
  §3
  «
  Correction
  et
  analyse
  des
  erreurs
  »
  )
  ;
  le
  `Menu`
  «
  Changer
  de
  matière
  »
  =
  une
  `Select`
  (§3.2
  )
  qui
  **recharge**
  la
  pile
  de
  cartes
  (le
  compteur
  de
  `Badge`
  est
  **par
  matière**
  ,
  pas
  global
  —
  le
  changement
  de
  matière
  **ne**
  perd
  pas
  le
  compteur
  global
  ,
  le
  compteur
  est
  **par
  contexte**
  ,
  §1
  «
  non-surprise
  »
  :
  l'utilisateur
  **sait**
  que
  le
  compteur
  change
  quand
  elle
  change
  de
  matière
  ,
  elle ne
  sait
  pas
  que
  le
  compteur
  change
  sans
  raison
  ).
- **Notes
  responsive
  (Phase
  2)** :
  desktop
  = la
  carte
  reste
  **centrée**
  (le
  desktop
  n'élargit
  pas
  la
  carte
  —
  une
  carte
  de
  révision
  est
  une
  **carte**
  ,
  pas un
  document
  ,
  §1
  «
  simple
  en
  surface
  »
  )
  +
  les
  4
  boutons
  de
  qualité
  FSRS
  passent
  en
  **rangée
  horizontale**
  sous
  la
  carte
  (le
  mobile
  est
  2×2
  ,
  le
  desktop
  est
  4×1
  —
  le
  layout
  s'adapte
  ,
  la
  logique
  (4
  niveaux
  de
  qualité
  )
  est
  **inchangée**
  ,
  doc
  §23.4
  )
  ;
  le
  `Badge`
  compteur
  de
  cartes
  dues
  reste
  **en
  haut**
  (le
  header
  est
  **identique**
  mobile/desktop
  ,
  doc
  §23.4
  :
  «
  réutiliser
  les
  contrats
  existants
  »
  )
  ;
  un
  **second**
  panneau
  latéral
  (desktop
  )
  affiche
  la
  **pile
  restante**
  (les
  cartes
  à
  venir
  ,
  en
  **texte**
  ,
  pas en
  pastille
  —
  le
  desktop
  a
  la
  largeur
  ,
  le
  mobile
  est
  **compact**
  par
  design
  ,
  §1
  «
  dense
  progressivement
  »
  ).

#### 4.8.2 `qcm` (doc §3)
- **Objectif** :
  **évaluer**
  (pas
  «
  voir
  »
  les
  questions
  — le
  QCM
  est une
  **session
  d'évaluation**
  ,
  doc
  §3
  «
  QCM
  ,
  Rappel
  actif
  ,
  Exercices
  progressifs
  ,
  Correction
  et
  analyse
  des
  erreurs
  »
  )
  ;
  l'écran
  est une
  **question**
  à la
  fois
  (pas
  10
  questions
  empilées
  —
  le
  QCM
  est
  **séquentiel**,
  la
  correction
  vient
  **après**
  chaque
  question
  si
  le
  mode
  est
  «
  correction
  immédiate
  »
  ,
  ou
  **après**
  la
  session
  si
  le
  mode
  est
  «
  évaluation
  pure
  »
  —
  les
  2
  modes
  sont
  **séparés**
  par
  un
  `SegmentedControl`
  §3.4
  ,
  pas
  mélangés
  dans
  le
  même
  écran
  ,
  §12
  :
  «
  simple
  en
  surface
  ,
  puissant
  en
  profondeur
  »
  :
  le
  mode
  «
  correction
  immédiate
  »
  est
  le
  **coaching**
  (le
  `mode-coach`
  §4.9
  )
  ,
  le
  mode
  «
  évaluation
  pure
  »
  est
  la
  **mesure**
  (le
  Progress
  §18
  )
  —
  les
  2
  modes
  ont
  des
  **finalités
  différentes**,
  l'UI
  les
  **sépare**.
- **Zones** :
  header
  (`TopBar`
  «
  QCM
  »
  +
  un
  `SegmentedControl`
  «
  Correction
  |
  Évaluation
  »
  §3.4
  —
  2
  segments
  ,
  le
  `SegmentedControl`
  est
  **justifié**
  §3.4
  (binaire
  exclusif
  )
  +
  un
  `Badge`
  compteur
  «
  3/15
  »
  (la
  question
  courante
  /
  le
  total
  ,
  en
  `JetBrains
  Mono`
  `xs`
  ,
  **statique**
  §2.6
  )
  ;
  content
  (un
  `Card`
  §3.3
  **par
  question**
  (la
  question
  est
  **centrée**
  ,
  pas une
  liste
  de
  15
  questions
  empilées
  ,
  §1
  «
  une
  question
  à
  la
  fois
  »
  )
  +
  les
  réponses
  =
  des
  `ListItem`
  **sélectables**
  (pas
  des
  `RadioButton`
  §3.2
  —
  le
  `RadioButton`
  est
  pour
  les
  choix
  **exclusifs**
  dans
  un
  formulaire
  ; le
  QCM
  est
  une
  **réponse**
  ,
  pas un
  formulaire
  : les
  réponses
  sont
  des
  **items**
  qu'on
  **choisit**
  ,
  pas des
  **options**
  qu'on
  coche
  —
  le
  `ListItem`
  **sélectable**
  §3.3
  est
  le
  bon
  composant
  ,
  pas le
  `RadioButton`
  )
  +
  (si
  le
  mode
  est
  «
  correction
  immédiate
  »
  )
  un
  `Callout`
  **posé**
  (
  `success`
  si
  bonne
  ,
  `danger`
  si
  mauvaise
  )
  +
  l'explication
  (si
  le
  mode
  est
  «
  correction
  immédiate
  »
  ,
  l'explication
  est
  **séparée**
  de
  la
  question
  —
  la
  question
  est
  dans
  la
  `Card`
  ,
  l'explication
  est
  dans
  le
  `Callout`
  ,
  le
  `MathBlock`
  si
  la
  question
  est
  une
  formule
  (§3.6.8
  ,
  doc
  §17
  «
  Mémorisation
  des
  formules
  »
  )
  )
  ;
  footer
  (le
  `BottomNav`
  est
  **masqué**
  —
  la
  session
  de
  QCM
  est
  une
  **action**
  ,
  pas une
  feuille
  de
  nav
  ,
  le
  retour
  au
  `BottomNav`
  s'effectue
  par
  le
  back
  Android
  ou
  un
  `IconButton`
  «
  Terminer
  »
  ).
- **DS** :
  `TopBar`,
  `SegmentedControl`
  (le
  mode
  correction
  /
  évaluation
  ,
  2
  segments
  ,
  §3.4
  ),
  `Badge`
  (le
  compteur
  «
  N/M
  »
  ,
  **statique**
  ,
  §2.6
  ),
  `Card`
  (la
  question
  ,
  une
  par
  écran
  ,
  §3.3
  ),
  `ListItem`
  (les
  réponses
  ,
  **sélectables**
  ,
  pas
  des
  `RadioButton`
  ,
  §3.3
  ),
  `Callout`
  (le
  feedback
  de
  correction
  ,
  `success`/`danger`
  ,
  le
  `Callout`
  est
  **posé**
  ,
  pas
  un
  toast
  ,
  §2.6
  règle
  3
  ,
  `focusMode`
  :
  les
  toasts
  sont
  **différés**
  ,
  le
  `Callout`
  **reste**
  ),
  `MathBlock`
  (§3.6.8
  ,
  si
  la
  question
  contient
  une
  formule
  —
  doc
  §17
  «
  Mémorisation
  des
  formules
  :
  formule
  ,
  signification
  de
  chaque
  variable
  ,
  unités
  ,
  conditions
  d'utilisation
  »
  ,
  la
  formule
  est
  **toujours**
  rendue
  par
  KaTeX
  ,
  jamais
  en
  texte
  brut
  ,
  §2.2
  «
  les
  unités
  et
  valeurs
  techniques
  =
  toujours
  `JetBrains
  Mono`
  +
  `tabular-nums`
  »
  ),
  `EmptyState`
  (pas
  de
  QCM
  dans
  la
  matière
  =
  un
  CTA
  «
  Générer
  un
  QCM
  »
  qui
  ouvre
  l'agent
  §4.40
  —
  la
  génération
  du
  QCM
  est
  une
  **capacité
  de
  l'agent**
  ,
  doc
  §3
  «
  Fiches
  de
  révision
  IA
  »
  ,
  le
  QCM
  est
  **généré**
  ,
  pas
  «
  écrit
  »
  par
  l'app
  ,
  AD-12
  )
  ,
  `Skeleton`
  (le
  `loading`
  du
  QCM
  =
  les
  questions
  en
  Skeleton
  ,
  le
  compteur
  reste
  ,
  le
  mode
  reste
  ).
- **États** :
  `loading`
  = les
  questions
  en
  Skeleton
  (le
  store
  local
  ,
  les
  questions
  sont
  **générées**
  par
  l'agent
  —
  le
  `loading`
  **couvre**
  la
  génération
  serveur
  ,
  pas la
  lecture
  locale
  : un
  QCM
  **existant**
  est
  **immédiat**
  ,
  un
  QCM
  **généré**
  attend
  le
  serveur
  ,
  AD-12/F-09
  :
  le
  kernel
  est
  **serveur**
  ,
  l'app
  est
  la
  surface
  )
  ;
  `empty`
  = pas
  de
  QCM
  dans
  la
  matière
  =
  un
  `EmptyState`
  :
  icône
  «
  QCM
  »
  ,
  «
  Aucun
  QCM
  pour
  cette
  matière
  —
  demandez-en
  un
  à
  Aurora
  »
  +
  CTA
  «
  Générer
  un
  QCM
  »
  (le
  CTA
  ouvre
  l'agent
  §4.40
  ,
  la
  génération
  est
  **déclarée**
  comme
  une
  capacité
  du
  kernel
  ,
  AD-12
  :
  le
  `AgentRunState`
  pack
  02
  §6.4
  =
  la
  surface
  de
  l'agent
  ,
  le
  QCM
  est
  le
  **résultat**
  )
  ;
  `error`
  = un
  échec
  de
  génération
  du
  QCM
  (le
  kernel
  **échoue**
  )
  =
  un
  `Callout
  danger`
  «
  La
  génération
  du
  QCM
  a
  échoué
  »
  +
  retry
  (le
  QCM
  **précédent**
  reste
  accessible
  si
  un
  existait
  —
  l'échec
  ne
  **supprime
  pas**
  le
  QCM
  existant
  ,
  AD-7
  :
  le
  local
  reste
  lisible
  )
  ;
  `offline`
  = les
  QCM
  **existants**
  restent
  **lisibles**
  (lecture
  locale
  ,
  AD-7
  )
  ,
  la
  génération
  est
  **désactivée**
  avec
  un
  `Callout
  info`
  «
  La
  génération
  de
  QCM
  nécessite
  le
  réseau
  »
  (le
  kernel
  est
  serveur
  ,
  AD-12
  :
  le
  QCM
  est
  **généré**
  par
  l'agent
  ,
  pas par
  l'app
  —
  sans
  réseau
  ,
  pas de
  génération
  ,
  mais
  les
  QCM
  **existants**
  restent
  )
  .
- **Transitions** :
  un
  tap
  sur
  une
  réponse
  (mode
  «
  correction
  immédiate
  »
  )
  = le
  `Callout`
  **apparaît**
  (
  `success`/`danger`
  )
  +
  l'explication
  (si
  présente
  )
  +
  le
  compteur
  **avance**
  (le
  `Badge`
  se
  met
  à
  jour
  **statiquement**
  ,
  §2.6
  )
  +
  la
  prochaine
  question
  apparaît
  (le
  `loading`
  de
  la
  prochaine
  question
  est
  **courant**
  si elle
  est
  locale
  ,
  AD-7
  )
  ;
  un
  tap
  sur
  une
  réponse
  (mode
  «
  évaluation
  pure
  »
  )
  =
  la
  question
  **avance**
  (pas
  de
  `Callout`
  —
  le
  mode
  «
  évaluation
  pure
  »
  est
  une
  **mesure**
  ,
  pas un
  **coaching**
  ,
  le
  feedback
  arrive
  **après**
  la
  session
  ,
  doc
  §3
  «
  Correction
  et
  analyse
  des
  erreurs
  »
  =
  le
  bilan
  de
  session
  ,
  pas le
  feedback
  immédiat
  )
  ;
  «
  Terminer
  »
  =
  une
  `BottomSheet`
  de
  **bilan**
  (le
  `QcmSessionBilan`
  ,
  analogue
  au
  `FocusSessionBilan`
  pack 04
  §4.1
  )
  :
  le
  score
  ,
  les
  N
  erreurs
  ,
  les
  erreurs
  **récurrentes**
  (le
  même
  type
  d'erreur
  plusieurs
  fois
  ,
  doc
  §3
  «
  Correction
  et
  analyse
  des
  erreurs
  »
  )
  +
  un
  CTA
  «
  Suggérer
  une
  correction
  »
  qui
  ouvre
  l'agent
  §4.40
  (le
  coaching
  après
  le
  QCM
  est
  une
  **capacité
  de
  l'agent**
  ,
  AD-12
  :
  l'app
  **demande**
  ,
  l'agent
  **suggère**
  ,
  l'utilisateur
  **décide**
  ,
  doc
  §5
  «
  Orchestration
  agentique
  »
  )
  ;
  le
  `Menu`
  (le
  `TopBar`
  ,
  changer
  de
  matière
  )
  =
  une
  `Select`
  (§3.2
  )
  qui
  **recharge**
  la
  pile
  de
  QCM
  (le
  compteur
  de
  `Badge`
  est
  **par
  matière**
  ,
  pas
  global
  ,
  le
  changement
  de
  matière
  **ne**
  perd
  pas
  le
  compteur
  global
  ,
  le
  compteur
  est
  **par
  contexte**
  ,
  §1
  «
  non-surprise
  »
  )
  .
- **Notes
  responsive
  (Phase
  2)** :
  desktop
  = les
  questions
  restent
  **centrées**
  (le
  desktop
  n'élargit
  pas
  la
  question
  —
  un
  QCM
  est
  une
  **question**
  ,
  pas
  un
  document
  ,
  §1
  «
  simple
  en
  surface
  »
  )
  +
  les
  réponses
  passent
  en
  **grille
  2
  colonnes**
  (le
  mobile
  est
  **liste**
  ,
  le
  desktop
  est
  **grille**
  —
  le
  layout
  s'adapte
  ,
  la
  logique
  (les
  réponses
  sont
  des
  `ListItem`
  **sélectables**
  )
  est
  **inchangée**
  ,
  doc
  §23.4
  )
  ;
  le
  `SegmentedControl`
  (correction
  /
  évaluation
  )
  reste
  **en
  haut**
  (le
  header
  est
  **identique**
  mobile/desktop
  ,
  doc
  §23.4
  )
  ;
  le
  bilan
  de
  session
  (le
  `BottomSheet`
  )
  passe
  en
  **fenêtre**
  latérale
  (le
  desktop
  a
  la
  largeur
  pour
  le
  bilan
  **côte
  à
  côte**
  avec
  le
  QCM
  ,
  pas en
  plein
  écran
  ,
  doc
  §23.4
  :
  «
  créer
  des
  layouts
  desktop
  sans
  modifier
  la
  logique
  métier
  »
  ).

### 4.9 Module Learning — mode coach &
mirror cognitive (doc §3, §13, §14)

#### 4.9.1 `mode-coach` (doc §3, §13)
- **Objectif** :
  **apprendre**
  (pas
  «
  voir
  »
  le
  coach
  —
  le
  coach
  est
  une
  **capacité
  adaptative**
  ,
  doc
  §3
  «
  Mode
  Coach
  »
  ,
  doc
  §13
  «
  Aurora
  Coach
  —
  accompagnement
  personnel
  adaptatif
  »
  :
  le
  coach
  est
  le
  **miroir**
  de
  l'apprentissage
  ,
  pas un
  «
  chatbot
  »
  (le
  chatbot
  est
  l'chat
  **interactif**
  du
  kernel
  ,
  pack
  02
  §6.4
  :
  l'
  `agent`
  §4.40
  est
  la
  **surface
  de
  dialogue**
  ,
  le
  `mode-coach`
  est
  la
  **capacité**
  du
  kernel
  (AD-12
  :
  «
  Planner/Coach/Tutor/Researcher/Executor
  sont
  des
  **capacités**
  du
  kernel
  ,
  pas
  des
  agents
  séparés
  »
  )
  —
  le
  DS
  **rend**
  le
  coach
  ,
  il ne
  **l'exécute
  pas**
  (le
  kernel
  est
  **serveur**
  ,
  AD-12/F-09
  :
  l'app
  est
  la
  surface
  ,
  le
  kernel
  est
  l'exécution
  )
  .
- **Zones** :
  header
  (`TopBar`
  «
  Coach
  »
  +
  un
  `Badge`
  d'état
  du
  coach
  (le
  `AgentRunState`
  pack
  02
  §6.4
  :
  `planning`/`retrieving`/`acting`/`done`/`error`
  =
  les
  5
  états
  de
  la
  surface
  du
  kernel
  ,
  le
  `Badge`
  affiche
  le
  `phase`
  courant
  en
  `JetBrains
  Mono`
  `xs`
  ,
  **statique**
  §2.6
  —
  le
  `Badge`
  **change**
  quand
  la
  phase
  change
  ,
  il ne
  «
  pulse
  »
  pas
  )
  +
  un
  `Menu`
  (changer
  de
  matière
  ,
  passer
  la
  session
  )
  ;
  content
  (le
  `mode-coach`
  n'est
  **pas**
  un
  écran
  de
  contenu
  —
  c'est
  un
  **mode**
  ,
  pas
  un
  lieu
  :
  le
  contenu
  du
  coach
  s'affiche
  **par-dessus**
  l'écran
  courant
  (un
  `BottomSheet`
  §3.5
  qui
  **monte**
  au-dessus
  de
  l'écran
  en
  cours
  ,
  pas
  un
  push
  séparé
  —
  le
  coach
  **contextualise**
  ,
  il ne
  **déplace**
  pas
  :
  un
  coach
  qui
  remplace
  l'écran
  de
  travail
  est
  un
  **interruption**
  ,
  pas un
  accompagnement
  ,
  doc
  §13
  :
  «
  le
  coaching
  ne
  doit
  pas
  devenir
  intrusif
  :
  l'agent
  doit
  privilégier
  la
  pertinence
  contextuelle
  ,
  respecter
  les
  périodes
  de
  silence
  et
  pouvoir
  être
  désactivé
  ou
  ajusté
  »
  )
  ;
  le
  contenu
  du
  `BottomSheet`
  =
  un
  `Callout`
  **posé**
  (le
  **constat**
  du
  coach
  ,
  doc
  §13
  «
  Dialogue
  bref
  et
  orienté
  action
  :
  Aurora
  explique
  le
  constat
  »
  —
  le
  `Callout`
  est
  **posé**
  ,
  pas
  un
  toast
  ,
  §2.6
  règle
  3
  :
  le
  coach
  est
  **persistant**
  dans
  la
  sheet
  ,
  il ne
  **disparaît**
  pas
  )
  +
  une
  **action**
  proposée
  (un
  `Button
  primary`
  dans
  la
  sheet
  ,
  doc
  §13
  «
  propose
  une
  action
  »
  —
  le
  coach
  **propose**
  une
  action
  ,
  il ne
  **force**
  pas
  :
  l'action
  est
  un
  CTA
  que
  l'utilisatrice
  **choisit**
  ,
  pas un
  CTA
  qui
  **s'exécute**
  ,
  doc
  §5
  «
  Demander
  confirmation
  pour
  les
  actions
  importantes
  ou
  irréversibles
  »
  )
  +
  un
  `Button
  ghost`
  «
  Suivre
  le
  résultat
  »
  (doc
  §13
  «
  suit
  le
  résultat
  au
  lieu
  de
  multiplier
  les
  notifications
  »
  :
  le
  `Button
  ghost`
  ouvre
  le
  **suivi**
  de
  la
  recommandation
  ,
  pas
  un
  2ᵉ
  toast
  )
  ;
  footer
  (le
  `BottomNav`
  **reste
  visible**
  par-dessus
  la
  sheet
  ,
  §3.5
  :
  le
  coach
  est
  une
  surface
  flottante
  ,
  pas
  une
  feuille
  —
  l'utilisatrice
  **peut**
  naviguer
  **en
  continu**
  pendant
  le
  coach
  ,
  le
  coach
  **n'exige
  pas**
  d'attention
  pleine
  ,
  doc
  §13
  :
  «
  préférence
  la
  pertinence
  contextuelle
  »
  .
- **DS** :
  `TopBar`
  (
  le
  `Badge`
  du
  `phase`
  du
  kernel
  ,
  `JetBrains
  Mono`
  `xs`
  ,
  **statique**
  §2.6
  )
  ,
  `Menu`
  (§3.5
  ,
  changer
  de
  matière
  /
  passer
  la
  session
  )
  ,
  `BottomSheet`
  (§3.5
  ,
  le
  coach
  **monte**
  par-dessus
  l'écran
  courant
  ,
  pas
  un
  push
  )
  ,
  `Callout`
  (
  le
  constat
  du
  coach
  ,
  **posé**
  ,
  pas
  un
  toast
  ,
  §2.6
  )
  ,
  `Button`
  (
  `primary`
  :
  l'action
  proposée
  ;
  `ghost`
  :
  «
  Suivre
  le
  résultat
  »
  )
  ,
  `KeyValueList`
  (§3.6.2
  ,
  le
  contexte
  qui
  a
  **déclenché**
  le
  coach
  :
  la
  tâche
  en
  cours
  ,
  le
  temps
  écoulé
  ,
  la
  matière
  —
  le
  `KeyValueList`
  **explique**
  pourquoi
  le
  coach
  parle
  **maintenant**
  ,
  pas
  pourquoi
  il
  a
  parlé
  il
  y a
  10
  minutes
  ,
  doc
  §13
  «
  Détection
  des
  changements
  »
  :
  le
  contexte
  est
  **affiché**
  ,
  pas
  **supposé**
  )
  ,
  `EmptyState`
  (
  le
  coach
  n'a
  **rien**
  à
  dire
  =
  un
  `EmptyState`
  :
  icône
  «
  coach
  »
  ,
  «
  Aucune
  suggestion
  pour
  le
  moment
  »
  +
  CTA
  ghost
  «
  Explorer
  les
  découvertes
  »
  qui
  ouvre
  `decouverte-feed`
  §4.27
  —
  le
  coach
  **n'est
  pas**
  un
  chatbot
  permanent
  ,
  il
  est
  **contextuel**
  ,
  doc
  §13
  :
  le
  `mode-coach`
  est
  un
  **mode**
  ,
  pas
  un
  lieu
  ,
  §4.9.1
  )
  ,
  `Skeleton`
  (
  le
  `loading`
  du
  coach
  =
  le
  `Callout`
  en
  Skeleton
  ,
  le
  `KeyValueList`
  reste
  ,
  le
  `BottomSheet`
  **demeure**
  ouverte
  )
  .
- **États** :
  `loading`
  =
  le
  coach
  **calcule**
  (
  `phase`
  =
  `planning`/`retrieving`
  du
  `AgentRunState`
  pack
  02
  §6.4
  )
  =
  le
  `Callout`
  et
  le
  `KeyValueList`
  en
  Skeleton
  (
  le
  `BottomSheet`
  **monte**
  **avec**
  le
  Skeleton
  dedans
  ,
  pas
  une
  sheet
  vide
  qui
  **pulse**
  ,
  §3.5
  )
  ;
  `empty`
  =
  le
  coach
  n'a
  **rien**
  à
  dire
  =
  un
  `EmptyState`
  **compact**
  dans
  la
  sheet
  (
  pas
  de
  sheet
  **plein**
  écran
  pour
  un
  coach
  vide
  —
  le
  `EmptyState`
  est
  **léger**
  ,
  le
  coach
  **n'appelle**
  pas
  l'attention
  ,
  doc
  §13
  )
  ;
  `error`
  =
  un
  échec
  du
  kernel
  (
  `phase`
  =
  `error`
  du
  `AgentRunState`
  )
  =
  un
  `Callout
  danger`
  dans
  la
  sheet
  «
  Le
  coach
  est
  indisponible
  »
  +
  un
  retry
  (
  le
  `Button
  ghost`
  «
  Réessayer
  »
  —
  pas
  un
  `Button
  primary`
  :
  le
  retry
  est
  une
  **action
  mineure**
  ,
  pas
  la
  **dominante**
  de
  l'écran
  ,
  §3.1
  )
  ;
  `offline`
  =
  le
  coach
  est
  **désactivé**
  avec
  un
  `Callout
  info`
  «
  Le
  coach
  nécessite
  le
  réseau
  »
  (
  le
  kernel
  est
  serveur
  ,
  AD-12
  :
  le
  coach
  est
  une
  capacité
  du
  kernel
  ,
  sans
  réseau
  ,
  pas
  de
  coach
  —
  mais
  l'app
  **reste**
  fonctionnelle
  :
  les
  données
  locales
  ,
  le
  Focus
  ,
  les
  tâches
  ,
  tout
  est
  **local**
  ,
  AD-7
  )
  .
- **Transitions** :
  le
  `Button
  primary`
  (l'action
  proposée
  par
  le
  coach
  )
  =
  l'action
  s'exécute
  **localement**
  si
  elle
  est
  locale
  (
  ex.
  «
  Planifier
  30
  min
  sur
  la
  tâche
  X
  »
  =
  une
  mutation
  du
  `Task`
  local
  ,
  pack
  03
  —
  le
  coach
  **propose**
  ,
  l'app
  **exécute**
  ,
  le
  kernel
  ne
  mute
  **jamais**
  directement
  une
  table
  ,
  AD-7/F-03
  :
  le
  kernel
  **émet**
  la
  commande
  ,
  le
  module
  owner
  **applique**
  ,
  PowerSync
  **propage**
  )
  ;
  le
  `Button
  ghost`
  «
  Suivre
  le
  résultat
  »
  =
  ouvre
  l'écran
  concerné
  (
  ex.
  «
  Suivre
  le
  résultat
  »
  d'une
  recommandation
  de
  révision
  =
  `flashcards`
  §4.8.1
  )
  ;
  le
  `Menu`
  «
  Changer
  de
  matière
  »
  =
  une
  `Select`
  (§3.2
  )
  qui
  **recharge**
  le
  contexte
  du
  coach
  (
  le
  coach
  est
  **par
  matière**
  ,
  pas
  global
  —
  le
  changement
  de
  matière
  **recharge**
  le
  `KeyValueList`
  et
  le
  `Callout`
  ,
  le
  coach
  **recontextualise**
  ,
  il ne
  **s'adapte
  pas**
  sans
  que
  l'utilisatrice
  le
  sache
  ,
  §1
  «
  non-surprise
  »
  )
  ;
  le
  back
  Android
  **ferme**
  la
  sheet
  du
  coach
  (
  le
  coach
  est
  une
  surface
  flottante
  ,
  §3.5
  :
  le
  back
  **descend**
  la
  sheet
  ,
  le
  coach
  **se
  replie**
  ,
  l'écran
  sous-jacent
  **redevient**
  actif
  )
  .
- **Notes
  responsive
  (Phase
  2)**
  :
  desktop
  =
  le
  coach
  passe
  en
  **panneau
  latéral**
  (
  le
  `BottomSheet`
  mobile
  devient
  un
  **drawer**
  à
  droite
  ,
  §3.5
  `Drawer`
  —
  le
  coach
  **reste**
  une
  surface
  flottante
  ,
  pas
  un
  écran
  :
  le
  desktop
  permet
  de
  **travailler**
  **côte
  à
  côte**
  avec
  le
  coach
  ,
  pas
  de
  le
  «
  lancer
  puis
  revenir
  »
  ,
  doc
  §23.4
  :
  le
  composant
  est
  **identique**
  ,
  seul
  le
  **layout**
  change
  )
  ;
  le
  `KeyValueList`
  (le
  contexte
  qui
  a
  déclenché
  le
  coach
  )
  reste
  **visible**
  même
  si
  le
  panneau
  est
  replié
  (
  un
  `Badge`
  `primary`
  «
  Coach
  a
  un
  contexte
  »
  signale
  que
  le
  contexte
  existe
  ,
  sans
  l'expand
  —
  le
  desktop
  a
  la
  **largeur**
  pour
  le
  panneau
  ,
  mais
  le
  contexte
  ne
  doit
  pas
  **s'imposer**
  ,
  doc
  §13
  :
  «
  le
  coaching
  ne
  doit
  pas
  devenir
  intrusif
  »
  )
  .

#### 4.9.2 `mirror-cognitive` (doc §3, §14)
- **Objectif** :
  **révéler**
  (
  pas
  «
  noter
  »
  —
  le
  `mirror-cognitive`
  est
  une
  **vérification**
  de
  la
  compréhension
  ,
  doc
  §3
  «
  Mirror
  Cognitive
  Mode
  :
  l'étudiante
  explique
  ce
  qu'elle
  a
  compris
  et
  Aurora
  détecte
  lacunes
  ,
  contradictions
  et
  erreurs
  »
  :
  l'utilisatrice
  **explique**
  une
  notion
  (
  en
  texte
  ou
  en
  vocal
  )
  ,
  l'app
  **analyse**
  (
  le
  kernel
  ,
  AD-12
  )
  ,
  et
  l'écran
  **affiche
  le
  résultat
  de
  l'analyse
  (
  les
  lacunes
  ,
  les
  contradictions
  ,
  les
  erreurs
  —
  doc
  §3
  «
  détecte
  lacunes
  ,
  contradictions
  et
  erreurs
  »
  )
  ,
  pas
  l'analyse
  elle-même
  (
  l'analyse
  est
  le
  **serveur**
  ,
  le
  résultat
  est
  la
  **surface**
  ,
  AD-12/F-09
  :
  le
  kernel
  tourne
  côté
  serveur
  ,
  l'app
  n'exécute
  aucun
  Context
  Builder
  /
  Plan
  /
  Router
  local
  )
  .
- **Zones** :
  header
  (`TopBar`
  «
  Miroir
  »
  +
  un
  `Badge`
  du
  `phase`
  du
  kernel
  (
  `AgentRunState`
  pack
  02
  §6.4
  ,
  `JetBrains
  Mono`
  `xs`
  ,
  **statique**
  §2.6
  )
  )
  ;
  content
  (
  une
  `TextArea`
  **grasse**
  (
  la
  saisie
  de
  l'ex