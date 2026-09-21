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
  qui compte maintenant ? » (AD-14, doc §11 : l'