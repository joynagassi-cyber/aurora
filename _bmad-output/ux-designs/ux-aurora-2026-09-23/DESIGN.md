---
name: Aurora
description: "Suite de productivité + apprentissage + orchestration agentique (Phase 1 mobile-only Android). Direction visuelle : Technical Calm (pack 05 S1). Les tokens, composants et contrats AD-10 sont SSoT dans `packages/ui` (pack 05) — ce DESIGN.md est le pont visuel pour les agents IA, pas une source de vérité (le pack 05 l'est)."
status: draft
sources:
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md (S1-S3, S5)
  - _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md (AD-10, AD-13, AD-14, AD-15, AD-17)
  - _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md (S12 principe final, S14 arbre sémantique, S16 visualisation, S25 stack visuelle)
updated: 2026-09-23
---

# Aurora — DESIGN.md (pont visuel, pas une SSoT)

> **Rôle de ce fichier** : réassemblage visuel (pack 05 S1/S2/S3/S5) pour les agents
> d'implémentation wave 0–2. Ce n'est **pas** une recopie de pack 05 — le pack 05
> est la source de vérité (`packages/ui` en wave 0/1). Les valeurs de tokens en
> ce fichier sont **des pointeurs** (`pack-05:S2.1.2`) — pas de valeur hardcodée.
>
> Règle de résolution des conflits : **spine AD-x (read-only) > ADR v1.7 > pack 05
> > ce DESIGN.md** (spine Consistency Conventions : toute divergence = ADR additif,
> breaking = dedicated PR + review).

## Brand & Style

**Direction nommée : *Technical Calm*** (calme technique) — motivée par la cible :
étudiante / jeune ingénieure, génie civil, usage intensif mobile, sessions de
concentration nocturnes. (pack 05 S1)

Les 5 motifs qui traduisent la direction en contraintes de design :

1. **Lisibilité technique d'abord** — la cible lit des formules, unités, schémas
   et tableaux longuement : hiérarchie typographique pour lecture dense
   (`pack-05:S2.3.1`), mono pour les valeurs, grille 8px, contraste élevé
   (`pack-05:S2.5`). Pas de décor qui concurrence la donnée.
2. **Calme pour la concentration** — l'app est un outil de focus (doc §2.8) et de
   coaching non-intrusif. Surfaces neutres très claires (light) / fond quasi-noir
   (dark, 1ʳᵉ classe, sessions nocturnes) (`pack-05:S2.1.2`). Les couleurs vives
   (danger/success/primary) sont **réservées aux sémantiques**, jamais décoratives.
3. **Densité informationnelle progressive** — « simple en surface, puissante en
   profondeur » : listes aérées par défaut, détails (Gantt, arbre, dashboards)
   révélés à la demande (drill-down, BottomSheet, zoom React Flow). L'accueil
   (AD-14) n'est jamais un tableau de widgets : une seule question,
   « Qu'est-ce qui compte maintenant ? ».
4. **Mobile-only Phase 1** — pensés pour une main (thumb-zone bas d'écran),
   tap targets standardisés à **44px+** (Material 40px / iOS HIG 44px),
   transitions naturelles (glissement latéral = liste→détail, montée = sheet).
5. **Traduction visuelle des interdictions** — pas de style « générique SaaS »,
   « glassmorphism » ni « brutaliste » ; AD-14 interdit le dashboard de widgets,
   §12 interdit l'empilement de features visibles.

Contrainte de portabilité (doc §23.2) : les composants `packages/ui` sont des
**purs React + tokens**, aucun import Capacitor/Electron — la Phase 2 Electron
réutilise le pack sans réécriture, mêmes tokens light/dark sur les deux plateformes.

**Règle de rejet (blocking en review, AD-13 DoD)** : toute décision de design qui
**contradict** (a) **AD-14** (un widget dashboard sur l'accueil), (b) **§12**
(empilement de features visibles), ou (c) **§2.8** (blocage natif promis pack 04 §4.1)
= **rejet blocking** en review.

## Colors

Architecture en 2 couches : JSON source (`pack-05:S2.1`) → CSS custom properties →
TS typed wrapper (`resolveToken`, wave 0, AD-17). Les composants consomment les
tokens **sémantiques**, jamais les primitives brutes. Dark mode = **1ʳᵉ classe**
(sessions nocturnes, équilibre light/dark dès vague 1).

### Primitives (pointeurs — valeurs SSoT pack 05 S2.1.1, 8 hues, gamme 50–900)

| Hue (rôle) | 500 |
|---|---|
| `indigo` (primary) | `pack-05:S2.1.1.indigo.500` |
| `teal` (secondary / apprentissage, FSRS) | `pack-05:S2.1.1.teal.500` |
| `amber` (warning) | `pack-05:S2.1.1.amber.500` |
| `red` (danger) | `pack-05:S2.1.1.red.500` |
| `emerald` (success) | `pack-05:S2.1.1.emerald.500` |
| `sky` (info) | `pack-05:S2.1.1.sky.500` |
| `violet` (learning / skill-map) | `pack-05:S2.1.1.violet.500` |
| `slate` (neutral) | `pack-05:S2.1.1.slate.500` |

Les primitives sont **normatives pour la vague 1** ; toute évolution = ADR.

### Tokens sémantiques — LIGHT (thème par défaut)

Famille de noms (valeurs SSoT `pack-05:S2.1.2` — JSON source, SSoT
`packages/ui/src/themes/`, AD-17) :

- Marque/CTA : `primary`, `primary-surface`, `on-primary`
- Statuts : `success` (+`success-surface`), `warning` (+`warning-surface`),
  `danger` (+`danger-surface`), `info`, `learning`
- Surfaces : `bg`, `bg-subtle`, `surface`, `surface-alt`, `surface-overlay`
- Texte : `text-primary`, `text-secondary`, `text-muted`, `text-disabled`
- Bordures/focus : `border`, `border-strong`, `focus-ring`
- Squelette : `skeleton`
- Nœuds de compétence (figés, doc §14/§25.3) : `node-mastered` (vert),
  `node-fragile` (ambre), `node-forgotten` (rouge)
- Habitude (heatmap GitHub-like, 5 niveaux) : `habit-weak` (1/5), `habit-med` (3/5),
  `habit-strong` (5/5)

### Tokens sémantiques — DARK (1ʳᵉ classe, mêmes noms de tokens)

- `primary` remonté en nuance **300** (`pack-05:S2.1.3`, `indigo.500` insuffisant
  en contraste sur fond dark, ratios §6) ; `success`/`danger`/`warning` en nuance
  **400**.
- `bg` = **quasi-noir bleuté** (SsoT `pack-05:S2.1.3.bg`, pas `#000` — évite le
  banding OLED, §2.8) ; `surface`/`surface-alt` plus clairs que `bg`
  (niveau de surface = élévation, principe Material Dark).
- `node-*` toujours en **nuance 400** (pas 500, contraste §6).
- Règle linter : en dark, **aucun composant** ne s'appuie sur `shadow.*` pour sa
  hiérarchie — les ombres sont remplacées par une bordure 1px + des surfaces.

### Règle thème / sémantique (AD-17, figée pack 05)

Un thème ne touche **jamais** les tokens sémantiques d'état
(`success`/`warning`/`danger`/`info` restent dans le style neutre). Thèmes V1
= **10 vivants + 3 presets** (Slate/Nocturne/High Contrast, OQ-14) ; `Nocturne`
= preset autonome (OQ-16) ; SSoT = `packages/ui/src/themes/` JSON, `resolveToken`
en wave 0.

## Typography

Famille principale : **Inter variable** (woff2, 400–700), **self-hosted / embedded**
dans le bundle (offline-first AD-7, pas de CDN ; ~60 Ko woff2). Fallback
`system-ui`. **Inter 300 interdit** (lisibilité dégradée Android mid-range ; le
« light » = luxe desktop, pas mobile). (pack 05 S2.3.1)

Famille mono : **JetBrains Mono variable** (~80 Ko) pour formules, unités, valeurs,
code, identifiants techniques ; `font-variant-numeric: tabular-nums` toujours ON
(règle de lisibilité n°1 du domaine génie civil : « 25,4 kN·m »). (pack 05 S2.3.2)

Échelle (base 16px, grille verticale 8px) : `xs` 12 / `sm` 14 / `base` 16 /
`md` 18 / `lg` 20 / `xl` 24 / `2xl` 32 / `3xl` 40 (rare sur mobile — onboarding/splash
et `FocusTimer`). Poids : 400 (corps), 500 (labels/Badge), 600 (sous-titres),
700 (titres de page uniquement). (pack 05 S2.3.3)

Un écran n'a qu'**UN `h1`** (compact, dans le TopBar en `md/lg`) ; jamais un
titre plus grand que le titre de l'écran (anti-pattern AD-14).

## Layout & Spacing

Grille 4/8px. Échelle normative (SsoT `pack-05:S2.2`) : `2, 4, 8, 12, 16, 24, 32, 48, 64` px
(step 4, confort 8). Mapping : `space.0.5`=2 (gap icône+label), `space.1`=4
(padding min Chip/Badge), `space.2`=8 (padding interne ListItem), `space.3`=12
(padding Button / gap grille 2×2 StatTile), `space.4`=16 (padding Card / gap entre
Cards), `space.6`=24 (padding BottomSheet/Modal), `space.8`=32 (espacement entre
sections), `space.12`=48 (marge écran large, rare), `space.16`=64 (Hero/Splash uniquement).

Règles : le padding interne suit **son échelon** (Button 3, Card 4, Modal 6) ; le
gap entre composants suit l'échelon **supérieur** ; **jamais** une valeur hors
échelle (linter stylelint bloque, CI). **Marges latérales mobile = `16px`
(`space.4`) fixes** — jamais responsive en V1 (mobile-only, doc §23.1).

Tap targets standardisés 44px+ (thumb-zone bas d'écran).

## Elevation & Depth

4 niveaux d'ombre (`shadow.1` → `shadow.4`, SsoT `pack-05:S2.4`). Principes :
le niveau de surface = élévation (Material Dark) ; `surface-overlay` est le niveau
le plus élevé. **En dark, aucun composant ne s'appuie sur `shadow.*` pour sa
hiérarchie** — les ombres sont remplacées par une bordure 1px + des surfaces
(règle linter, `pack-05:S2.1.3`).

## Shapes

Radius (SsoT `pack-05:S2.5`, §2.4–§2.6 figés) : `sm` 4 / `md` 8 / `lg` 12 / `xl` 16 /
`full` (augmentant avec la taille de surface). Icônes **Ionicons** (fill défaut,
outline option) + nomenclature `ic-{concept}-{variante}` ; les icônes de domaine =
SVG custom `packages/ui/src/icons/`, seule équipe qui les écrit.

Animations normatives (SsoT `pack-05:S2.6`) : `fast` 150ms (ease-out) /
`normal` 250ms (ease-out) / `slow` 400ms (spring `stiffness:200, damping:25`) /
`instant` 0ms (reduced-motion).

Règle de non-surprise (thème) : le thème est **persisté** (store UI pack 02 §3.2,
middleware `persist`) ; **jamais** un thème qui change silencieusement au retour
foreground (retour foreground = re-sync, pas de crash/flash). Le switch auto
(système/heure/manuel) est **exposé explicitement** dans `/settings` avec aperçu
du résultat. **Jamais** un flash light/dark au boot : boot = thème persisté ; le
recompute auto = **différé au premier mount de `/settings`, pas au boot**.

## Components

**Règle transversale (AD-13, normative)** : tout composant `packages/ui` expose les
5 états UX canoniques (pack 02 §7 : `loading / empty / success / error / offline`)
sauf ceux sans état (ex. `Divider`, `Breadcrumb`) ; un composant manquant un état
requis = **blocking review finding** (1 test par état, pack 02 §11). Les états
intermédiaires `hover / pressed / focus / disabled` sont **déclarés** (pas tous
implémentés : `hover` n'existe pas sur Android mais est déclaré pour la Phase 2
Electron). `offline` = le composant **reste utilisable** pour la lecture locale
(AD-7). Les composants de donnée sont des **wrappers des contrats AD-10** — jamais
une réimplémentation du moteur (AD-1 : le moteur est l'implémentation, le
composant est le contrat). Matrice d'état par composant : pack 05 §3.7 (annexe A,
normative).

### Les 9 composants data (wrappers des contrats AD-10, SsoT `pack-05:S3.6`)

1. **`DataTable`** — tableau de lecture exacte (résultats de calcul, comparaison,
   charge planifiée vs réelle) : `<table>` HTML sémantique, valeurs en
   `JetBrains Mono` `tabular-nums`, défilement horizontal (la donnée technique
   ne se comprime pas).
2. **`KeyValueList`** — méta-données d'un objet (détails `Artifact`, aperçu
   `SemanticNode`) : paires `key`/`value` (valeur en mono si technique), groupe
   séparé par divider si > 5 paires.
3. **`Timeline`** — vue **récit** de l'historique d'événements (reports de tâches,
   journal des décisions, évolution du Semantic Tree) : colonne verticale, points
   sémantiques (success/warning/primary), temps en mono ; s'oppose à la vue
   **planification** (`GanttRow`).
4. **`GanttRow`** — barre de planification mobile-first simplifiée (une tâche =
   une ligne 44px : titre + barre proportionnée sur axe de dates partagé + %
   complétion mono) ; le Gantt 2D complet = desktop Phase 2, le mobile reste en
   liste (§12).
5. **`Sparkline`** — tendance micro (7 derniers jours de concentration, fraîcheur
   FSRS) : polygone/ligne G2 minimal 24px, sans grille ni axe ; **n'animé pas**
   (la donnée apparaît, elle ne se « dessine » pas — §2.6 règle 1).
6. **`SemanticTreeNode`** — le **nœud** de l'arbre sémantique (pill avec
   pastille d'état `mastered`/`fragile`/`forgotten` figée aux 3 couleurs du DS) ;
   le DS définit le nœud, pas le graphe ; nœud **pur et mémoïsé** (reçoit
   `RenderSemanticNode`, n'écrit rien, expansion `+`/`−` 44px).
7. **`InfographicSlot`** — slot de rendu d'explication visuelle générée par l'agent
   (`AI → InfographicSpec → validation → moteur → SVG`) ; `fidelityMode="strict"`
   par défaut (AD-11 : le texte du corpus reste dominant, l'explication d'Aurora
   est un bloc séparé labelisé) ; export SVG/PNG posé dans le slot, jamais
   automatique.
8. **`MathBlock`** — rendu d'une formule LaTeX (source dépliable en dessous —
   règle de confiance/traçabilité §15) ; formule du corpus = `SourceRef` en
   `xs` sous le bloc (AD-11).
9. **`HabitStreak` + `RoutineStep`** (le §3.6.12 compte **un** composant data de
   la section 3.6) — heatmap type GitHub (grille 7×semaines, 5 niveaux de teinte
   `habit-*`, pas d'animation de remplissage ; le streak courant en mono « parle »)
   + `RoutineStep` (étape de routine : numéro mono + `Checkbox` 44px, report =
   `Badge warning`).

> Note : la section 3.6 liste 12 sous-sections (3.6.1–3.6.12) ; les composants data
> **wrapper d'un contrat AD-10** sont au nombre de **9** (`DataTable`, `KeyValueList`,
> `Timeline`, `GanttRow`, `Sparkline`, `SemanticTreeNode`, `InfographicSlot`,
> `MathBlock`, `FocusTimer` — voir §5 ci-dessous). Les 3 autres sous-sections
> (3.6.10 `FlashcardCard`, 3.6.11 `SkillStateBadge`, 3.6.12 `HabitStreak`+`RoutineStep`)
> sont des composants **déclaratifs** (pas de moteur AD-10) et font partie de la
> bibliothèque `packages/ui` standard (§3.1–§3.5 + états AD-13).

### Les 5 contrats renderer AD-10 (DEF `packages/ui` — ratifiés G1, props = 02 §5.1–5.5)

| # | Contrat renderer | Moteur derrière (AD-1, jamais importé par l'app/domaine) | Props d'entrée normalisées | Comportement d'erreur / dégradation |
|---|---|---|---|---|
| 1 | `SemanticTreeRenderer` | `@xyflow/react` + `@dagrejs/dagre` | `nodes: RenderSemanticNode[]`, `edges: RenderSemanticEdge[]`, `bridges?`, `fitView?`, `initialFocusId?`, `onSelectNode?`, `onToggleBranch?`, `visibleBranches?`, `lazyChildren?` (tout typé depuis `packages/domain`, AD-15/AD-6) | `loading` : nœuds racine + niveau 1 en Skeleton (seule la racine au mount) ; `empty` : `EmptyState` plein écran + CTA ; `error` : `Callout danger` + retry, le **sous-arbre chargé reste** (AD-7) ; `offline` : l'arbre local reste interactif (pan/zoom/repli, SQLite), sous-arbres non syncés = `Badge info` « à synchroniser » (jamais de nœud inventé) |
| 2 | `InfographicRenderer` | `@antv/infographic` (moteur AntV) | `spec: InfographicSpec` (déjà validée par le kernel), `theme?`, `onExport?`, `fidelityMode?` (défaut `strict`) | `loading` : slot entier en Skeleton ; `empty` n'existe pas (slot = spec donnée) ; `error` : **fallback texte brut** (spec dégradée en `KeyValueList` + `Callout danger` « visualisation indisponible » — AD-1 : capacité absente dégrade proprement) ; `offline` : specs générées (cloud) indisponibles avec explicatif, specs téléchargées (cache R2) restent |
| 3 | `DataVisualizationRenderer` | `@antv/g2` | `spec: ChartSpec` (`{marks, axes, scales}`), `width?`, `height?`, `seriesLabel?` (séries typées, projection des `Progress*` AD-15 — jamais le graphe interne) | `error`/`offline` : dernière valeur/dataset **local** reste affiché (AD-7) ; les composants qui l'instancient (`StatTile`, `Sparkline`, `DataTable`, `FocusTimer`-bilan) portent la dégradation (valeurs `—`, ligne plate, données locales). `ChartSpec` = SSoT à trancher = `packages/ui` (**G-M5**, ci-dessous) |
| 4 | `MathRenderer` | `KaTeX` | `latex: string`, `displayMode?`, `onError?` | KaTeX fail → **fallback texte brut** dans un bloc stylé « formule non rendue » + `onError` (AD-8, PAS de crash) ; `empty` n'existe pas (un bloc vide = composant qui ne doit pas exister) ; `offline` : le bloc reste (rendu local, AD-7) ; le bloc **n'a jamais** de `loading` (rendu < 50ms) |
| 5 | `AnimationController` | `motion` | `reveal(nodeRef, key: RevealKey)`, `setReducedMotion(on)`, `prefersReducedMotion()` ; `RevealKey = 'formula'\|'arrow'\|'step'\|'result'\|'branch'` | Révélation pédagogique (§25.8) = choix conscient, pas décor ; `prefers-reduced-motion` **obligatoire** (AD-13 DoD) : `setReducedMotion` appelé au boot (pack 02 §5.5) et tout `slow`/`normal` → `instant` ; `focusMode=true` : animations `slow` désactivées, toasts différés (jamais pendant un pomodoro), transitions page `fast`→`instant` ; **jamais** une animation qui bloque l'input (AD-7 : le local d'abord, sync en arrière-plan). **G-M1** : wrapper `packages/ui` du `AnimationController` (contrat `motion`) = ouvert, ci-dessous |

Garde-fous normatifs (02 §5.6) : lint CI `eslint import/no-restricted-paths` —
`apps/mobile` interdit `@xyflow/react`, `@dagrejs/dagre`, `@antv/*`, `katex`,
`motion` (autorisés seulement via `packages/ui`) ; la vérité n'est jamais dans le
moteur (AD-6 : chaque renderer accepte des séries entrantes, aucun renderer ne
possède de repository ni de `useState` de domaine). Toute divergence 02/05 = ADR
(spine §162 : breaking = dedicated PR + mandatory Codex review).

### Les états de composants (matrice AD-13, SsoT `pack-05:S3.7`)

- **5 états UX canoniques** (pack 02 §7) : `loading` / `empty` / `success` /
  `error` / `offline` — « l'état est décidé par l'app (l'écran), le rendu par le
  Design System ».
- **États intermédiaires déclarés** : `hover` (déclaré pour Phase 2 Electron,
  inopérant sur Android), `pressed`, `focus` (ring 2px `focus-ring`, §6),
  `disabled`.
- **`killed` (G-M2)** : état d'application **non inclus** dans la matrice 5-états UX.
  À ajouter **comme sous-état de `loading`** dans 02 S7 + 05 S3.7 (le kill du
  système n'annule pas le local, AD-7 : au retour, l'app retrouve l'état).
  **Fix wave-0** (1 fichier, pack/domaine).
- Règle de test (pack 02 §11) : 1 composant qui implémente un état de la matrice
  = **un test de rendu par état** ; un composant marqué « écran » = un test
  **par écran** qui compose l'état (les 5 états d'écran, pack 02 §7).

### Gaps ouverts mentionnés dans la section 3 (source : rapport de readiness)

- **G-M1 — `AnimationController` wrapper (5e contrat AD-10)** : le wrapper
  `packages/ui` du contrat `Animation` (moteur `motion`) n'est **pas encore
  ratifié/implémenté** — à livrer par l'équipe DS en wave 0/1 (contrat ouvert,
  COVERED au niveau architecture mais GAP au niveau contrat).
- **G-M5 — `ChartSpec` SSoT** : l'owner et le shape du `ChartSpec` (le `spec` du
  contrat `DataVisualizationRenderer`, G2) **ne sont pas publiés** — à publier
  dans 05 S3.6 par l'équipe DS (AD-15 : **un seul** SSoT de `ChartSpec`, à
  trancher = `packages/ui`). Le `ChartSpec` de bilan Focus (`focusBilan`) est une
  instanciation **inchangée** de ce contrat (correction H1) — le shape du
  `FocusSessionBilan` lui est **figé dans `packages/domain`** (SSoT, AD-15),
  consommé par l'écran de bilan (§4.4.2) et par le `ChartSpec` de G2.

## Do's and Don'ts

**Do** :
- Lire les valeurs via `resolveToken` — jamais une valeur hardcodée hors token
  (règle 02 §8 : « toute valeur hors token = blocking finding »).
- Utiliser `JetBrains Mono` + `tabular-nums` pour toutes les valeurs techniques
  (formules, unités, pourcentages).
- Garder `primary`/`success`/`danger` **réservés aux sémantiques**, jamais
  décoratives (Technical Calm).
- Respecter le 1 `h1` par écran (TopBar, `md/lg`).

**Don't** :
- Promettre du « free tier » sans date de snapshot (OQ-12, spine silent =
  intentional).
- Utiliser Inter 300 (lisibilité dégradée Android mid-range).
- Un widget dashboard sur l'accueil (AD-14) ; empilement de features visibles
  (§12) ; blocage natif promis (§2.8) → **rejet blocking** en review.
- Rappeler le thème silencieusement au retour foreground (règle de
  non-surprise).
