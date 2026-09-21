# Dimension FRONTEND — Aurora

> Pack de dimension « Contract Pack » (wave 0) — apps/mobile (Ionic React + TypeScript + Capacitor).
> Ce pack **référence et approfondit** le spine (AD-x) ; il ne le répète pas. Les AD du spine sont
> contraignantes et read-only — tout conflit se règle en faveur du spine, ou par ADR.
> Contenu en français ; identifiants de code en anglais.

Frontmatter BMad :

```yaml
name: 'Aurora — Dimension Frontend (Ionic React + Capacitor, Phase 1 mobile-only)'
type: contract-pack
dimension: frontend
altitude: initiative
status: draft-for-wave-0
owner: 'app-shell team (feature agents consument ce pack)'
binds: ['apps/mobile', 'packages/ui (consommé)', 'packages/platform (adaptateur mobile)']
consumes: ['01-backend', '03-sync', '05-design-system', 'packages/domain (types AD-15)', 'packages/data (repositories)']
adRefs: [AD-1, AD-2, AD-3, AD-7, AD-8, AD-9, AD-10, AD-12, AD-13, AD-14, AD-15, AD-16, F-03, F-09]
```

---

## 1. Périmètre et objectifs

**Périmètre du pack** : `apps/mobile` — la seule application déployable de Phase 1 (spine §Structural Seed,
§Stack : Ionic React + Capacitor, Android cible Phase 1, Electron reporté Phase 2). Ce pack couvre :

- la structure interne de `apps/mobile` (pages, layouts, state, routing) ;
- la **décision state management** (tranchée section 3.2) ;
- les **séparations de responsabilités** (section 4, doc §23.3) ;
- les **contrats de la couche visualisation** consommés par l'app (AD-10, section 5) ;
- le **routing mobile-first** (section 6) ;
- les **états UX canoniques** (AD-13, section 7) ;
- la **consommation du Design System** (section 8 — référence, pas duplication : voir `05-design-system.md`) ;
- la **performance mobile** (section 9, dont la règle perf du Semantic Tree).

**Objectifs mesurables** (DoD de la vague 1 Foundation UI) :

1. `apps/mobile` buildable et lançable en dev (HMR web) et en build Android debug via Capacitor, sans Electron.
2. La navigation, les états UX (loading/empty/success/error/offline) et les écrans du Home invariant (AD-14)
   marchent **hors-ligne** : tout se lit depuis SQLite/PowerSync, jamais d'appel réseau synchronisant l'UI.
3. Aucun import direct d'un moteur de visualisation (React Flow, AntV, KaTeX, motion) depuis le code
   **métier** de l'app — uniquement via les contrats AD-10 (section 5). Un lint boundary (eslint
   `import/no-restricted-paths`) fait la police.
4. Le cœur applicatif (hooks, use-cases, state, services) est testable sans DOM ni Capacitor :
   les tests de logique tournent en `vitest` unitaire ; les tests E2E de scénario en `playwright`
   (web target) + smoke Capacitor (Android).

**Hors périmètre (pointeurs vers les autres packs)** :

- Schéma SQL / views PowerSync / migrations → `01-backend.md` + `03-sync.md` (AD-7, AD-16 : `packages/data`
  possède les scopes serveur, provisionnés wave 0).
- Le Design System lui-même (tokens, composants) → `05-design-system.md` (`packages/ui`). Ce pack **le
  consomme**, ne le définit pas (AD-13 : une seule équipe écrit `packages/ui`).
- Sémantique de sync, conflits, offline-detection → `03-sync.md`. Ce pack définit seulement **comment l'UI
  lit et écrit** à travers les repositories et surfacer les états.
- Le Design System **écran par écran** → dimension design (pack 05 + inventaire écrans séparé).

---

## 2. Modules / packages concernés (ownership AD-13 / matrice §21.2)

Écriture unique (one-writer-per-file, AD-13) :

| Package / app | Équipe owner | Rôle dans ce pack |
|---|---|---|
| `apps/mobile` | **App Shell team** | Cette dimension. Pages, layouts, routing, state, composition des composants `packages/ui`, wiring Capacitor. |
| `packages/ui` | Design System team | Composants + tokens **consommés** par l'app. Interdit pour l'App Shell team d'y écrire (AD-13, §21.10). |
| `packages/platform` | Foundation | Adapter mobile Capacitor derrière interfaces (doc §23.3 « Platform »). L'app ne importe que l'interface, jamais `@capacitor/*` directement (§23.2 : hooks/services indépendants de Capacitor). |
| `packages/data` | Data team | Repositories PowerSync/SQLite + **scopes serveur** (AD-7). L'app consomme les repositories via DI ; l'app ne touche jamais le SQL/PowerSync directement. |
| `packages/domain` | (owner par entité, AD-15) | Types de domaine SSoT (Task, Goal, …). L'app **consomme** les types, ne les ré- déclare jamais (AD-15 / F-01). |
| `packages/agent` (rendu côté client) | Agent team | L'app consomme **uniquement la surface UI du kernel** (déclenche une capacité, reçoit un `AgentRunState`). Le kernel (Context/Plan/Routage/AI) tourne **côté serveur** (AD-12 F-09, AD-3) — l'app n'exécute jamais de logique kernel locale. |

Règle de dépendance (hexagonal, AD-1/§4) : `apps/mobile` peut importer `packages/ui`, `packages/domain`,
`packages/platform`, `packages/data`, la **surface UI** de `packages/agent`. Il ne peut importer **aucun**
moteur de visualisation externe, **aucun** SDK fournisseur (Supabase, Capacitor, R2), **aucune** clé
(AD-3). Toute dépendance externe nouvelle = justification + review (AD-13, §21.10).

---

## 3. Décision d'implémentation clé : state management

### 3.1 La tranchée — **Zustand**, pas Redux Toolkit

**Décision (normative pour ce pack) : `zustand` (+ `@tanstack/react-query` pour les données serveur/loCALES).**

| Critère | Zustand (retenu) | Redux Toolkit (rejeté) |
|---|---|---|
| **Compatibilité AD-10** | Doc §25.2 : « Supporte l'intégration directe avec **Zustand** et notre Design System » — le choix du spine est déjà aligné sur React Flow. | Nulle mention React Flow/Zustand ; ajout d'une 2ᵉ tech de state dans le chemin visuel. |
| Boilerplate | ~0 : un `create<T>()`, slices par feature, hook `useStore(selector)`. | Plus de code (reducers, actions, configureStore) ; verbeux pour une app à écrans verticaux. |
| Sélectivité / re-renders | `useStore(selector)` auto-mémoïsé par référence ; `useShallow` pour les objets. | `useSelector` + memo ; équivalent mais plus de surface d'erreur. |
| Persistance & offline | `persist` middleware natif (localStorage/IndexedDB) — s'ajoute proprement à PowerSync (state UI local ≠ state source de vérité, cf. AD-7). | Requiert `redux-persist` (dépendance tierce de plus). |
| Bundle | ~1 Ko | ~11 Ko (avec RTK + immer). Mobile-first = poids compte. |
| Intégration React Query | Cohabite naturellement (le store tient l'UI state ; RQ tient le serveur/data). | Idem. |
| Testabilité (AD-13 DoD) | Store = objet pur, testable sans React. | Store + actions à monter pour tester. |

Justification décisive : **AD-10 a déjà lié les renderers (React Flow) à Zustand** (doc §25.2, §25.4
"Intégration directe avec Zustand"). Adopter RTK imposerait **deux** couches de state (RTK pour l'app +
Zustand imposé par React Flow) = violation d'AD-13 (« ne pas créer d'abstraction parallèle quand un
contrat existe »). Un seul store global UI évite la dualité.

### 3.2 Topologie du state (3 couches distinctes, ne pas mélanger)

```
┌──────────────────────────────────────────────────────────────────────┐
│ UI state (Zustand)  — packages/mobile/src/state  (ou store/)         │
│   selection, filters, view modes, scroll anchors, focus-mode on/off, │
│   command palette open, theme (dark/light)                            │
│   → état purement visuel & transitoire ; PERSISTÉ (persist middleware)   │
│     — périmètre strict : seulement l'UI state transitoire/cosmétique    │
│     (thème, open/close, ancres de scroll). État « important » (ex.      │
│     sélection persistée d'une tâche à re-ouvrir après kill) = STORE     │
│     LOCAL (PowerSync/SQLite), PAS Zustand/localStorage (pack 04 R6/§6.1:│
│     « tout l'état important vit dans le store local »). Classification  │
│     normative : important → store local ; cosmétique/transitoire →      │
│     persist middleware du store UI.                                      │
│   Ne contient JAMAIS de données métier (pas de Task, pas de Goal).    │
├──────────────────────────────────────────────────────────────────────┤
│ Data state (@tanstack/react-query + repositories PowerSync/SQLite)    │
│   tâches, projets, cours, skills, arbre, progressions…                │
│   → source de vérité = store local (AD-7) ; l'UI lit, jamais ne      │
│   recalcule. Query = lecture ; mutation = commande use-case.          │
├──────────────────────────────────────────────────────────────────────┤
│ Domain state (packages/domain, AD-15)                                  │
│   règles & types métier (statuts Task, priorités, récurrence…)        │
│   → platform-agnostic, jamais de React/TypeScript-app ici.            │
└──────────────────────────────────────────────────────────────────────┘
```

- **Règle de séparation (normative)** : le store Zustand ne cache **jamais** une entité `packages/domain`
  comme si c'était sa source de vérité. Il stocke de l'UI state + **des ID de sélections/ancres** qui
  pointent vers les données (ex. `selectedTaskId`), pas des copies de `Task`. La donnée vient toujours de
  React Query ← repository PowerSync (AD-7 single-writer : la mutation passe par le use-case, pas par le
  store).
- Les **mutations** de données vont : bouton → `useCase` (section 4) → repository `packages/data` →
  PowerSync. Le store UI n'émet jamais de mutation de donnée (ce serait un 2ᵉ writer, violation F-03/AD-7).

### 3.3 Contrats TS publics du store (exemples, identifiants anglais)

```ts
// packages/mobile/src/state/ui-store.ts  (App Shell team owns)
interface UiState {
  selection: { taskId: string | null; artifactId: string | null; nodeId: string | null };
  // REGISTRY des vues par tab (normatif, AD-13) : chaque feature équipe (Productivity, Learn,
  // Progress, …) déclare ses vues dans CE registry partagé ; le shape `views` est la union de
  // toutes les déclarations (ex. taskView ci-dessous ; progressView, learnView déclarations futures).
  // Deux équipes ne peuvent pas déclarer deux shapes divergentes : la déclaration est une entrée
  // de type dans ce package, pas un ad-hoc par feature. Jamais de type métier ici (IDs + modes).
  views: { taskView: 'list' | 'kanban' | 'timeline' | 'gantt' | 'calendar' };
  // AD-17 candidate (pack 05 §5, système v2) : le thème n'est PLUS binaire light/dark.
  // `AuroraTheme` est une enum SSoT (packages/domain, AD-15) : les 10 thèmes expressifs
  // (aurora [défaut], lagoon, boreal, sakura, vesper, solara, terra, verdant, citrus,
  // cosmos) + 3 presets techniques (slate, nocturne, high-contrast). Le style neutre
  // (light/dark) est un second axe orthogonal : `themeStyle: 'light' | 'dark'`.
  // Migration : le persist binaire 'light'|'dark' ancien migre vers { theme:'aurora',
  // themeStyle:<valeur> } au premier boot post-upgrade (port par packages/domain).
  theme: AuroraTheme;
  themeStyle: 'light' | 'dark';
  commandPaletteOpen: boolean;
  focusMode: boolean;
}
type UiActions = {
  selectTask: (id: string | null) => void;
  setTaskView: (v: UiState['views']['taskView']) => void;
  toggleFocusMode: () => void;
};
// crée: export const useUiStore = create<UiState & UiActions>()(persist(...))
// SÉLECTEURS STABLES (anti re-render) : export const useSelectedTaskId = (s) => s.selection.taskId;
```

Les sélecteurs exportés sont **la seule surface publique** du store (les composants importent des
sélecteurs, pas `useUiStore` brut — évite le re-render de tout l'arbre).

---

## 4. Séparations strictes de responsabilités (doc §23.3)

Quatre couches, **chacune dans son dossier**, la dépendance pointe toujours vers la gauche (pas le
contraire) :

```
apps/mobile/src/
  presentation/   # 1. Composants visuels purs (JSX + design system). AUCUNE logique métier.
                  #    Reçoit props/état, émet des événements (onX). Testable par storybook/snapshot.
  ui-state/       # 2. Store Zustand + hooks d'état UI (ci-dessus §3). Ne contient pas de donnée métier.
  use-cases/      # 3. Orchestration de vue + logique applicative : combine repositories + domain +
                  #    store. C'est la couche qui DÉCIDE (ex. completeTask) mais ne REND PAS.
  domain/         # 4. Règles métier & modèles → CONSOMMÉS depuis packages/domain (AD-15 SSoT).
                  #    L'app NE redéfinit PAS de type métier ; elle importe Task, Goal, SemanticNode…
  data-access/    # Injection des repositories (03-sync). Adapté à la DI du use-case.
  platform/       # Adaptateurs Capacitor INJECTÉS (via packages/platform) : camera, notification,
                  #    focus/anti-distraction. Jamais @capacitor/* importé en dur.
```

**Contrats des layers (normatifs, AD-13)** :

- **Presentation** : pas d'import de repository, de `packages/domain` logique, de `@tanstack/react-query`.
  Un composant = `(props, uiStoreSelectors) → JSX`. Toute règle métier dans un composant = **blocking
  finding** en review (Cf. §21.6 Codex).
- **Use-cases** : fonction pure d'orchestration. Signature type :

  ```ts
  // use-cases/task-use-case.ts (App Shell team)
  interface TaskUseCase {
    completeTask(id: string): Promise<void>;   // → repo, émet l'événement métier (AD-9)
    rescheduleTask(id: string, newDueAt: Date): Promise<void>;
    toggleTaskSubTask(id: string): Promise<void>;
  }
  // implémentation via DI du repository ; retourne des résultats typés (Result<T, AppError>).
  ```
- **Domain** : importé depuis `packages/domain` (AD-15). Règle d'or du pack : **l'app ne crée jamais de
  type qui duplique une entité frozen** (Task, Goal, Project, Note, … liste §10 / Consistency Conventions du
  spine). Toute "vue" d'un type (ex. `TaskRow` pour une liste) est **déclarée comme projection du type
  partagé**, jamais une ré-définition (AD-15 / F-01) — ex. :

  ```ts
  // PROJECTION déclarée du type partagé (AD-15), PAS une nouvelle entité :
  export interface TaskRow extends Pick<Task, 'id' | 'title' | 'status' | 'dueAt' | 'priority'> {
    // champs d'affichage seulement ; toute extension non affichée reste dans Task (domain)
  }
  ```
- **Événements (AD-9)** : la couche use-case est l'unique point où l'app **consomme** (déclaré dans ce
  pack, AD-13) et **produit côté client** des événements du vocabulaire figé. Rappel — ce que l'app
  **consomme** (déclaré ici, c'est le contrat AD-9, pas une re-implication) : `JobCompleted` (→ état
  success UI, AD-9/F-08 : le payload porte `jobId`+`jobKind` ; l'app filtre par `jobKind` avant de
  surfacer un succès), `ArtifactGenerated` (→ Artefacts screen) — consommation **déclarée** ici
  (AD-13, R9) : ce pack l'ajoute à la matrice AD-9 (UI = consumer déclaré, au même titre que
  Knowledge/Learning) ; l'écart « matrice spine complète ou pas » est consigné comme open question
  [OQ-05] dans le SPEC (la matrice du spine AD-9 liste pour `ArtifactGenerated` les consumers
  Knowledge/Learning ; la consommation UI déclarée ici est additive et normée, pas une violation —
  à ratifier dans la matrice AD-9 au prochain ADR spine). Ce que l'app **produit** côté client :
  aucune — le kernel serveur produit les événements agentiques ; l'app produit seulement les **commandes**
  (mutations de données via use-cases → repositories). (AD-9 : une opération transactionnelle simple reste
  une commande directe, pas un événement distribué — doc §6 v1.6.)

**Single-writer (AD-7 / F-03)** : l'UI **écrit** une entité locale uniquement via le repository du module
owner de cette entité (Productivity écrit `Task`, Learning écrit `Review`…). L'UI est donc **toujours**
l'émetteur de la commande ; le repository route vers le store local du bon module. L'app ne mutera **jamais**
directement une table SQLite (violation = blocking finding). La mutation « Agent complete une tâche »
n'est **jamais** faite par l'app : le kernel (serveur, F-09) émet `TaskCompleted`, le module Productivity
aplique, PowerSync propage, l'app **reçoit** la nouvelle valeur via le repository et n'a qu'à **afficher**.
L'app n'est jamais le 3ᵉ writer d'un `Task.status`.

---

## 5. Contrats de la couche visualisation (AD-10) — consommation par l'app

AD-10 fige les 5 contrats (et les moteurs derrière). **L'app ne importe JAMAIS `@xyflow/react`,
`@antv/*`, `KaTeX`, `motion` directement dans du code métier** — seulement via les implémentations livrées
par le Design System (`05-design-system.md`) derrière ces contrats. **Séparation de responsabilité des
contrats (AD-13)** : ce pack documente **la spécification de consommation** (ce que l'app passe à chaque
contrat — les props ci-dessous sont la spéc de signature) ; `05-design-system.md` est l'**autorité de
définition** (les implémentations, les composants DS, les tokens). Les signatures ci-dessous sont
figées : toute divergence entre les deux packs = **ADR** (spine §162 : « breaking = dedicated PR +
mandatory Codex review »), jamais une dérive silencieuse. Ce pack reste au niveau de consommation.

### 5.1 `SemanticTreeRenderer` (Knowledge tree)

Moteur derrière (figé) : `@xyflow/react` + `@dagrejs/dagre`. **Aucune vérité** dans le moteur (AD-6 : la
truth est dans Knowledge Base / `packages/domain`). L'app passe des données projetées (AD-15) :

```ts
// CONTRAT CONSOMMÉ PAR L'APP (défini par le Design System, AD-10)
interface SemanticTreeRendererProps {
  nodes: RenderSemanticNode[];          // PROJECTION (AD-15) de SemanticNode + NodeState, jamais le type complet
  edges: RenderSemanticEdge[];
  bridges?: RenderSemanticBridge[];     // liens transverses affichés à la demande (doc §14)
  fitView?: boolean;
  initialFocusId?: string;              // nœud au focus (ex. depuis un clic dans un écran list)
  onSelectNode?: (id: string) => void;
  onToggleBranch?: (id: string, open: boolean) => void;
  // PERFORMANCE (règle AD-10 / doc §25.2, section 9) :
  visibleBranches?: string[];           // seules les branches déployées sont rendues
  lazyChildren?: (parentId: string) => Promise<RenderSemanticNode[]>; // chargement progressif
}
// L'APP n'expose jamais getNodes() du moteur ; la vérité reste côté domain.
export interface RenderSemanticNode {
  id: string; concept: string; state: NodeState; // NodeState : type consommé de packages/domain (AD-15)
  hasChildren?: boolean; sourceRef?: SourceRef;
}
export interface RenderSemanticEdge  { id: string; source: string; target: string; relation: TreeRelation; }
export interface RenderSemanticBridge { id: string; source: string; target: string; label: string; }
export type TreeRelation = 'dependsOn' | 'isCaseOf' | 'deepens' | 'applies' | 'leadsTo'; // doc §14
```

`NodeState` et `SourceRef` sont **consommés depuis `packages/domain`** (AD-15, AD-6 : Knowledge est owner)
— `import { NodeState, SourceRef } from '@aurora/domain'`. L'app n'en définit pas la valeur ; elle lit
l'état local et le passe. Les 7 états canoniques (doc §25.3 : collapsed/expanded/selected/focused/
mastered/fragile/forgotten) sont **figés dans `packages/domain`**, jamais inline dans ce pack ; les
états conceptuels supplémentaires (doc §18.2 : découvert, compris, rappelable) vivent côté domain —
une évolution de `NodeState` = contrat breaking, géré par ADR (spine §162) + migration des
consommateurs ; le contrat renderer reste `state: NodeState` (référence de type, pas une liste de
valeurs copiée ici).

### 5.2 `InfographicRenderer` (explanations agentiques)

Moteur : `@antv/infographic`. L'app reçoit une `InfographicSpec` **déjà validée** (flux AD-10/doc §25.4 :
`AI → InfographicSpec → validation → moteur → SVG → affichage/export`). L'app n'est pas le validateur ;
le Design System expose :

```ts
interface InfographicRendererProps {
  spec: InfographicSpec;          // produit & validé par le kernel / ExplainEngine (AD-11 fidélité corpus)
  theme?: AuroraTheme;  // palettes Aurora enregistrées (doc §25.4 ; AD-17 v2 : les 10 thèmes expressifs + 3 presets — pack 05 §5)
  onExport?: (mime: 'image/svg+xml' | 'image/png') => Promise<Blob>; // export SVG/PNG
  fidelityMode?: 'strict' | 'explanatory'; // AD-11 : strict = texte source dominant, pas de paraphrase
}
```

`fidelityMode='strict'` est la **valeur par défaut** pour tout contenu qui provient d'un corpus
professeur (AD-11 / doc §17 : les définitions officielles restent textuellement dominantes ; l'explication
d'Aurora est séparée et labelisée). L'app n'écrit jamais de texte pédagogique dans ce composant.

### 5.3 `DataVisualizationRenderer` (G2)

Moteur : `@antv/g2`. Usage (doc §25.6) : progression, séries temporelles, distributions, comparaisons,
résultats scientifiques. L'app passe des **séries typées** (projection des `Progress*` AD-15), jamais le
graphe interne :

```ts
interface DataVisualizationRendererProps {
  spec: ChartSpec; // { marks, axes, scales } — grammaticalement G2, mais figé par le Design System
  width?: number; height?: number;
  seriesLabel?: string;
}
// L'app ne construit jamais un Chart G2 en dur : elle passe un spec ; le Design System le rend.
```

### 5.4 `MathRenderer` (KaTeX)

Moteur : `KaTeX`. L'app passe une chaîne LaTeX + un mode (display/inline) :

```ts
interface MathRendererProps {
  latex: string;             // du contenu domain/fiche/exercice (AD-15)
  displayMode?: boolean;
  onError?: (err: MathRenderError) => void; // KaTeX fail → fallback texte brut, PAS de crash (doc §15)
}
```

Règle (AD-8 / graceful degradation) : si un bloc LaTeX échoue, l'app **affiche le source** dans un bloc
stylé « formule non rendue » + `onError` ; elle ne fait pas tomber la page (une capacité absente dégrade
proprement, doc §26 principe complémentaire).

### 5.5 `AnimationController` (motion)

Moteur : `motion`. L'app pilote les micro-interactions & la révélation progressive (doc §25.8) **sans**
importer `motion` en dur :

```ts
interface AnimationController {
  reveal(nodeRef: RefObject<HTMLElement | SVGElement>, key: RevealKey): void; // formule, flèche, étape, résultat
  setReducedMotion(on: boolean): void;         // accessibilité : respect de prefers-reduced-motion
  prefersReducedMotion(): boolean;
}
type RevealKey = 'formula' | 'arrow' | 'step' | 'result' | 'branch';
```

Le Design System fournit une instance ; l'app l'appelle. `prefers-reduced-motion` = **obligatoire** (états
a11y, AD-13 DoD).

### 5.6 Garde-fous des contrats (normatifs)

- **Test anti-couplage (CI)** : `eslint` `import/no-restricted-paths` — `apps/mobile` interdit
  `@xyflow/react`, `@dagrejs/dagre`, `@antv/*`, `katex`, `motion` ; autorisés seulement via
  `packages/ui` (qui ré-exports les contrats). Toute violation = CI rouge (AD-10, §21.5 pipeline).
- **La vérité n'est jamais dans le moteur** (AD-6 / §25.3) : chaque renderer accepte des données **séries
  entrantes** ; aucun renderer ne possède de repository, ne fait de fetch, ne contient de `useState` de
  domaine. Le moteur = vue pure + interaction ; le state vient de l'app (store + data).

---

## 6. Routing / navigation mobile-first

### 6.1 Stack (décision)

- **`@ionic/react` `IonRouter` + `react-router` v6** (Ionic gère nativement la nav mobile : tabs,
  header, back, transitions). Les écrans = `Routes` ; les containers = `Tabs`.
- **Structure de route (mobile-first, 5 onglets max, règle 44–60 px pour la tab bar)** :

  ```
  /                     → /home         (AD-14 invariant, écran signature)
  /tasks                → /tasks        (liste / kanban / gantt / calendrier)
  /learn                → /learn        (cours, fiches, flashcards, FSRS)
  /progress             → /progress     (dashboards Progress, AD-15 ProgressSnapshot/Evidence/SkillState)
  /agent                → /agent        (Assistant/Coach — surface kernel UI, F-09)
  ── routes de détail (pas dans les tabs) ──
  /tasks/:id            /learn/:id      /progress/:id
  /knowledge            (Semantic Tree) /knowledge/:nodeId
  /artifacts/:id        (Artifact Hub, AD-10 visualisation)
  /inbox                (capture universelle, doc §2.1)
  /settings
  ```

- **Tab bar = navigation primaire ; les détails = push modales/sheets** : les écrans de détail (une tâche,
  un nœud, un artefact) s'ouvrent **par-dessus** le tab courant (IonSlides/IonModal), jamais par un
  changement de tab (l'utilisateur revient au contexte).

### 6.2 L'écran Home — invariant AD-14 (composition fixe, normative)

L'app doit rendre, **dans cet ordre**, et **uniquement** cela (le Home est figé par AD-14 ;
tout écart = blocking review finding) :

1. **Agenda du jour** (tâches/événements du jour, heure locale, statut).
2. **Prochaine action importante** (1 seule, la plus prioritaire du moment, avec son projet/matière).
3. **Priorité principale** (celle de la journée — peut = 2, si distincte).
4. **Progression critique** (l'élément Progress le plus urgent : un chapitre fragile, un review due, une
    compétence à rafraîchir).
5. **Révisions à effectuer** (due today, via le FSRS — `Review`/`LearningSession` AD-15).
6. **Accès Focus immédiat** (un bouton unique, entre dans Focus Mode, doc §2.8 ; le Focus Mode réduit
   les notifications & active le `FocusController` port — doc §7/§8 contrats internes).
7. **Suggestions d'Aurora Coach** (1–2 max, courtes, orientées action, doc §13 : « brièvement, orienté
   action, suit le résultat » — jamais une liste de notifications).

Données de l'Home : **tout depuis le store local** (PowerSync/SQLite, AD-7) — pas d'appel réseau au
mount. Si un champ manque, l'Home affiche un **état vide** propre (section 7), jamais un skeleton de
recherche web.

### 6.3 Transitions & back

- Ionic gère les transitions (slide/push) ; **pas de custom transitions** qui cassent le back natif.
- Le back matériel (Android gesture) doit fonctionner sur tout route ; un route qui bloque le back (ex.
  un formulaire non sauvegardé) **sauvegarde** avant (le local-first rend ce pattern naturel :
  l'état de formulaire est auto-persisté via le store UI / repository).
- **Command Palette** (doc §2.1) : overlay accessible depuis n'importe quel tab (swipe-down ou icône),
  ouvre le store `commandPaletteOpen` (section 3.2) ; n'est PAS une route (pas de back-stack pollué).

### 6.4 Routage des capacités (AD-12 / F-09)

Les capacités agentiques (Planner, Coach, Tutor, Researcher, Executor) ne sont **pas** des écrans
séparés avec leur routing interne : l'écran `/agent` est une **surface de dialogue** qui déclenche une
capacité du kernel. Le kernel tourne **côté serveur** (AD-12 F-09, AD-3) ; l'app **n'exécute** aucun
Context Builder / Plan / Router local. Elle : (a) envoie l'intent (une `Intent` typée, §16 doc), (b)
stream le résultat (une `AgentRunState` typée : `planning`, `retrieving`, `acting`, `done`, `error`),
(c) rend le résultat via les contrats AD-10 si c'est du contenu visuel.

```ts
// surface UI du kernel que l'APP consomme (AD-12/F-09 : le reste du kernel est serveur)
type AgentRunState =
  | { phase: 'idle' }
  | { phase: 'planning'; plan: AgentPlan }
  | { phase: 'retrieving'; context: ContextForm[] }        // Context forms AD-12 (Intent/Personal/…)
  | { phase: 'acting'; progress: ActionProgress }
  | { phase: 'done'; result: AgentResult; runId: string }
  | { phase: 'error'; code: AgentErrorCode; retryable: boolean };
// L'APP n'importe JAMAIS la boucle kernel elle-même (AD-12 : One Kernel, server-side).
```

Si la capacité produit une infographie/formule/graphe → l'app appelle les contrats AD-10 (section 5).
Le kernel **ne produit jamais** un `ArtifactGenerated` (AD-9 / F-06) : l'artefact est généré puis
**l'app** l'affiche via l'Artefact Hub quand l'événement arrive.

---

## 7. États UX (AD-13 : les 5 états canoniques, obligatoires par écran)

Chaque écran a **obligatoirement** les 5 états (AD-13 : « required states loading/empty/success/error/
offline » ; doc §21.1). **Un écran qui n'implémente pas l'un des 5 = DoD non-fermé, blocking review.**

| État | Quand | Exigence de rendu (Design System `05-design-system.md`) |
|---|---|---|
| **`loading`** | 1ʳe ouverture d'un écran qui lit des données, ou refresh. | Skeleton **design system** (tokens), jamais un blanc plein. Max ~300 ms ; sinon le content doit se montrer partiellement (le local-first rend le loading souvent **court** car les données sont locales). |
| **`empty`** | Pas d'objet (ex. « aucune tâche aujourd'hui », « aucun cours importé »). | Un état vide **actionnable** (CTA : « créer une tâche », « importer un cours », « rechercher »). **Jamais** un vide mort. |
| **`success`** | Opération terminée (job, upload, generation). | Confirmation **brève** (toast/inline), état terminal persistant. Pour un `JobCompleted` : l'app filtre par `jobId`/`jobKind` (AD-9/F-08) et n'affiche le succès que pour le job qu'elle a déclenché. |
| **`error`** | Échec d'une opération ou d'une lecture. | État local lisible (pas de stack trace au user), **retry** toujours disponible, lien vers `/settings` pour l'état du service. Les erreurs **réseau/AI** ≠ erreurs métier : différencier (une feature optionnelle absente = `error` doux, doc §26). |
| **`offline`** | Sans réseau **ET** sans store local disponible (ex. 1ʳe sync non terminée). | Bannière fine « Hors-ligne — vos données locales sont disponibles ». L'app **fonctionne** (AD-7 : offline = état premier, pas un failure mode). Les données locales sont affichées normalement ; seules les actions **nécessitant le cloud** (générer un artefact, recherche web) sont désactivées avec un explicatif, pas masquées. |

**Règle de surface (normative)** : un composant de `presentation/` expose un `data-state` (`loading|
empty|success|error|offline`) et **un seul** composant par état (le Design System). L'état est **décidé
par l'app** (use-case/store), le **rendu** par le Design System. Cette séparation rend les 5 états
testables unitairement (chaque composant a un test par état = AD-13 DoD).

`offline` est détecté via `@capacitor/network` (injecté par `packages/platform`) : `onNetworkChange →
store.uiStore.setOffline(bool)` → tout l'app bascule en mode offline. La détection réseau est
**injectée**, jamais importée en dur dans `presentation/` (§23.2 indépendant de Capacitor).

---

## 8. Intégration Design System (référence, pas duplication)

Ce pack **consomme** `packages/ui` ; **tout** ce qui suit vit dans `05-design-system.md` (owner :
Design System team, AD-13). Règles de consommation pour l'App Shell team :

- **Import uniquement via `@aurora/ui`** (le nom du package `packages/ui`). Jamais de chemin relatif vers
  `packages/ui/src` (violation de boundary = CI rouge). Les contrats AD-10 (section 5) sont **ré-exports**
  par `@aurora/ui` ; l'app importe les contrats, pas les moteurs.
- **Tokens, jamais de CSS « ad hoc »** : couleurs, espacements, typo, radius, ombres = 100 % tokens du
  Design System (light + dark). Toute valeur hors token = blocking finding (doc §25.4 : les palettes
  Aurora sont des thèmes réutilisables du Design System).
- **Composants composables** : l'app compose les composants DS (Card, Button, List, Tabs…) ; elle n'**écrit
  pas** de composant DS dans `apps/mobile`. Un composant métier qui **devient** réutilisable → PR vers
  `packages/ui` (accord inter-équipes, AD-13), jamais une copie locale.
- **Accessibilité** (règle transversale, AD-13 DoD) : tous les composants du DS sont accessibles
  (focus visible, ARIA, `prefers-reduced-motion` respecté — voir section 5.5), les écrans de l'app les
  composent sans casser l'a11y. Audit `a11y` (axe/lighthouse) en CI sur les 5 états de chaque écran
  signature (Home, tasks, learn, progress, agent).
- **Theming (AD-17 v2, pack 05 §5)** : bascule via `theme` (enum `AuroraTheme` — 10 expressifs + 3
  presets) ET `themeStyle` ('light' | 'dark', axe orthogonal) du store UI (section 3.2) + tokens du DS ;
  l'app ne fait **aucun** override inline. Le changement est **persisté** (store persist middleware).
  **Migration** : le persist binaire `'light'|'dark'` ancien migre vers `{ theme:'aurora', themeStyle:<valeur> }`
  au premier boot post-upgrade — port par `packages/domain` (AD-15 SSoT de l'enum + du migrateur), pas ici.

→ **Aucune définition de composant ici.** `05-design-system.md` porte : le token set, le library
  de composants, les états de composants, la theming engine (AD-10 palettes), les contrats des
  renderers (réf. section 5 ci-dessus). Ce pack reste au **niveau de consommation**.

---

## 9. Performance mobile

### 9.1 Règles globes (normatives, mesurables en CI)

- **Budget initial (first interactive)** : ≤ 300 Ko JS (gz) hors PowerSync moteur ; ≤ 1.5 s TTI sur un
  appareil Android de référence (Pixel 4a / équivalent, CPU mid-range). `performance.mark` + Sentry
  perf (AD-16 observation) en watch.
- **Lazy loading (route-level)** : chaque route de détail + chaque moteur de visualisation est un
  `React.lazy` + `Suspense` (fallback = état `loading` du Design System). **Le home (AD-14) n'est PAS
  lazy** (écran signature, doit être immédiat). Les tabs secondaires (`learn`, `progress`, `agent`)
  sont code-split (chunk par tab).
- **Moteurs visuels = lazy par essence** : `@xyflow/react`, `@antv/*`, `KaTeX`, `motion` sont **jamais**
  dans le bundle initial du Home ; ils se chargent quand on ouvre l'écran `knowledge`/`artifacts`/
  contenu maths (AD-10 : les moteurs sont des implémentations optionnelles de contrats ; ne pas les
  charger au boot = bon pour la perf ET pour AD-10/AD-8 dégradation).
- **Memoisation des listes** : `Task`, `Review`, `Artifact`, `Node` lists = `memo` + `React.memo`
  sur les items de liste + `useMemo` sur le filtrage/tri (le filtre du store UI ne doit pas re-filter
  à chaque re-render parent). Les listes virtuelles : **IonList virtuel** ou `react-virtuoso` pour les
  listes > 100 items (ex. bibliothèque de ressources doc §2.11).
- **Pas de re-render en cascade** : sélecteurs stables du store (section 3.3) ; `useShallow` pour les
  sélecteurs d'objets ; **jamais** `useUiStore` brut dans un composant (re-render de tout l'arbre).

### 9.2 Règle performance du Semantic Tree (AD-10 / doc §25.2, normative)

Le Semantic Tree est **l'écran le plus coûteux** (graphes). Règle figée par l'AD-10 (doc §25.2 :
« Aurora ne rend pas obligatoirement tout l'arbre. Les branches profondes sont chargées/affichées
progressivement et peuvent être repliées. Les composants de nœuds doivent être mémorisés pour éviter
les re-renders inutiles. ») :

1. **Pas de rendu entier** : au mount de `/knowledge`, **seule la racine + les branches au niveau 1**
   sont rendues. Les descendants = lazy (`lazyChildren` du contrat §5.1) ; l'utilisateur déplie
   (`onToggleBranch`) → chargement à la demande. `visibleBranches` (section 5.1) pilote cela.
2. **Mémoisation des nœuds React** : chaque `NodeComponent` = `React.memo` ; la donnée d'un nœud
   (un `RenderSemanticNode`) est **stable par référence** (le store UI ne recrée pas les objets de
   nœud à chaque cycle). Un re-render du parent ne doit re-render **que** les nœuds dont la référence
   a changé.
3. **Layout Dagre = incrémental** : le layout `@dagrejs/dagre` est recalculé **seulement** sur les
   branches touchées (pas un layout global à chaque toggle). Le Design System s'en charge ; l'app passe
   juste `onToggleBranch` (la responsabilité du layout est **dans** le renderer, pas dans l'app).
4. **Zoom/pan non bloquant** : le pan/zoom est `requestAnimationFrame` (React Flow est optimisé
   dessus) ; les interactions (sélection, focus) ne déclenchent **pas** de re-layout global.
5. **Budget nœud visible** : ≤ 150 nœuds DOM visibles à la fois (au-delà = virtualisation par
   viewport du moteur). Un arbre de 1 000+ nœuds **doit** rester fluide grâce aux points 1–4 ;
   un test perf de l'écran `knowledge` (1 000 nœuds, scroll + zoom sur appareil réel) = CI perf
   (seuil figé : 30 fps min, p95 frame time < 50 ms).

### 9.3 Perf des listes & transitions

- **IonList** natif (recyclage natif sur Android) = préférence pour les longues listes (tâches, fiches,
  artefacts, ressources). Un `IonList` virtuel ou `react-virtuoso` si nécessaire.
- **Images/artefacts** : thumbs lazy (`<img loading="lazy">` / IntersectionObserver), les PDF/DOCX/
  PPTX previews sont **lazy per-item** (on ne pré-charge pas la preview de 20 artefacts d'un coup,
  doc §16 : tout fichier a un parcours de visualisation **adaptatif** — un preview lourd n'est rendu
  que quand il entre dans le viewport).
- **Pendant une session Focus** (doc §2.8) : réduire les micro-interactions & animations (le `motion`
  `AnimationController` `setReducedMotion` + le store `focusMode=true` → les transitions de page sont
  minimales, les toasts différés) pour ne pas casser la concentration. C'est un état de perf **par
  design**, pas juste une fonctionnalité.
- **PowerSync = perf local** : toute lecture d'écran = query **locale** (SQLite), pas de fetch réseau
  (AD-7). La « perf réseau » n'existe pas au mount ; seule la **sync** (arrière-plan) consomme du
  réseau. La sync ne doit **jamais** bloquer un frame UI (c'est le moteur PowerSync qui gère ; l'app
  n'a qu'à lire le store — voir `03-sync.md` § 5.8 : le **bridge React Query** (`useLocalQuery`,
  query keys `[module, entity, ...filter]`, invalidation sur `SyncStateChanged`) est documenté par
  le pack `03-sync` (owner `packages/data`) — ce pack ne ré-invente pas la mécanique RQ↔watch).

### 9.4 Mesure (AD-16 : observation Sentry + PostHog)

- **Sentry perf** : TTI, LCP, largest layout shift, frame drops sur l'écran `knowledge` (graphes) et
  les listes longues. **Budgets ci-dessus = SLO** (si un écran dépasse, c'est un incident perf à traiter
  comme les incidents jobs, AD-16d duty owner).
- **PostHog** : mesurer **temps jusqu'au 1ʳe action utile** (ex. « Home → tâche complétée »), % écrans
  avec un `empty` mal géré, % sessions avec `offline` prolongé. Ces méutres **informent** les itérations
  d'UX (Phase 5 refinement, doc §21.12) — pas un SLO strict mais un signal.

---

## 10. Contrats d'erreurs (envelopes normalisées, Consistency Conventions du spine)

Toute erreur **fournisseur/AI** qui remonte à l'UI arrive **normalisée** (spine Consistency
Conventions : « every provider response normalized (provider, model, attempt, reason, expected quality) »).
L'app **n'affiche jamais** une raw exception. Contrat d'erreur consommé par l'app :

```ts
// SSoT : `packages/domain` (AD-15) — l'APP importe, ne redéfinit pas :
// import { AppError, AppErrorCode } from '@aurora/domain'
// (enveloppe produite par 01-backend §3.1 / transportée par 03-sync §6 ; le type complet vit
// dans `packages/domain`, owner = Foundation/AD-15 — une copie inline dans ce pack serait
// une violation AD-15/F-01. Ci-dessous : documentation du contrat consommé, pas la définition.)
export interface AppError {
  code: AppErrorCode;        // stable, branchable par l'UI
  message: string;          // lisible, utilisateur (pas de stack, pas d'identifiant technique)
  cause?: 'network' | 'quota' | 'provider' | 'permission' | 'data' | 'unknown';
  retryable: boolean;       // pilote le bouton « Réessayer » (états error, section 7)
  details?: { provider?: string; model?: string; attempt?: number; reason?: string; expectedQuality?: string };
}
export type AppErrorCode =
  | 'TASK_NOT_FOUND' | 'SYNC_PENDING' | 'OFFLINE' | 'JOB_FAILED' | 'JOB_QUEUED'
  | 'AI_UNAVAILABLE' | 'AI_QUOTA' | 'PERMISSION_DENIED' | 'MEDIA_UNSUPPORTED' | 'UNKNOWN';
// L'APP branch sur `code` + `cause` pour rendre un état d'écran (section 7) ; la règle AD-5 (429 jamais
// bypass) est côté serveur — l'APP reçoit simplement un AppError{ cause:'quota', retryable:false }.
```

Règle d'affichage (normative) : `retryable=false` → pas de bouton retry, CTA alternatif (ex. « vous
êtes hors-ligne », « quota atteint, l'IA sera de retour plus tard »). `MEDIA_UNSUPPORTED` (doc §16
formats non pris en charge) → l'app affiche « téléchargement/partage externe possible » + le fichier
source, **sans** prétendre à une prévisualisation native (doc §16 : les formats inconnus sont
conservés, métadonnées + download, jamais une preview factice).

---

## 11. Tests obligatoires (AD-13 DoD — à chaque PR de ce pack)

**Par composant `presentation/`** :
- 5 tests d'état (loading/empty/success/error/offline — section 7) : 1 render par état.
- 1 test de **couplage DS** : le composant n'importe **que** `@aurora/ui` (lint `import/no-restricted-paths`
  CI + un test de « pas de moteur AD-10 en dur »).
- 1 test de **pas de logique métier** : un composant qui reçoit `onX` ne **fait** rien de métier
  (il émet, ne décide pas).

**Par use-case** (section 4) :
- Test unitaire de **chaque** mutation : que le use-case envoie **une seule** commande au repository du
  module owner (single-writer AD-7/F-03) et qu'il n'écrit **jamais** 2 tables. Ex. `completeTask` →
  `repoTasks.complete(id)` et **pas** `repoReviews` / `repoProgress`.
- Test de **projection AD-15** : qu'un type `*Row` (projection) n'est **pas** ré-déclaré (le linter
  type + un test de « extends Pick<Task,…> » le garantit).

**Par écran** :
- Un E2E (Playwright, web target) par **scénario** (ex. « créer → terminer une tâche »), par écran
  signature (Home AD-14, knowledge perf §9.2) — E2E de la **vague 4 intégration** (doc §21.12).
- Test **offline** (intercept réseau en Playwright + `store.setOffline(true)`) : que l'app reste
  **utilisable** (lecture locale) et que seules les actions cloud sont désactivées (AD-7).

**Par contrat AD-10** (rendu visuel) :
- Test de **non-couplage** : qu'aucun moteur (xyflow, antv, katex, motion) n'apparaît dans le DOM
  **métier** (les composants DS les encapsulent).
- Test **perf du Semantic Tree** (section 9.2) : 1 000 nœuds, lazy branches, memo node, 30 fps min
  (test de perf dédié, CI sur appareil émulé ou golden file).
- Test **MathRenderer** : `onError` déclenché sur LaTeX invalide, fallback texte brut (pas de crash, §15).

**Accessibilité** : audit axe/lighthouse sur Home + 4 écrans, dans les 5 états (AD-13 DoD) +
`prefers-reduced-motion` vérifié (section 5.5).

**CI du pack (obligatoire, doc §21.5 pipeline)** : type-check (tS) + lint/format + **lint boundary**
(import/no-restricted-paths, AD-1/AD-10/AD-15 police) + build `apps/mobile` + tests unitaires
(vitest, sans DOM) + E2E (playwright web) + review Codex (obligatoire sur **tout** contrat public).
`main` buildable (doc §21.8). Un pack = **blocking review** si : un écran manque un des 5 états, un
moteur AD-10 importé en dur, un type domain ré-déclaré, ou une mutation multi-table par un use-case.

---

## 12. Risques et dépendances

| # | Risque | Impact | Mitigation (normative) |
|---|---|---|---|
| R1 | **Zustand vs RTK** : équipe qui impose RTK « car plus connu ». | Dual state (AD-10/React Flow déjà sur Zustand) = abstraction parallèle (violation AD-13), re-render, 2 sources d'UI state. | **Décision section 3 figée : Zustand.** Toute déviation = ADR (spine : « any significant change requires a documented ADR »). Le `05-design-system.md` **doit** assumer Zustand (AD-10) — si le DS team n'est pas aligné, c'est un **gating** avant la vague 1 (section 13). |
| R2 | **Le store UI double avec PowerSync** : mettre des données métier dans Zustand, qui drift vs le store local. | 2 sources de vérité UI (violation AD-7 single-writer à l'échelle UI, F-03). | Règle section 3.2 : le store UI = **UI state + IDs**, **jamais** de Task/Goal complets. Test de séparation en CI (un test qui vérifie que le store n'expose pas de type `packages/domain`). |
| R3 | **Couplage moteur AD-10** : un dev importe `@xyflow/react` pour « aller plus vite ». | Violation AD-1/AD-10 (isolation fournisseur), impossible de changer le moteur, re-render de l'app. | Lint boundary CI (section 5.6, 11). **Blocking finding** en review. |
| R4 | **L'app exécute du kernel** (Context/Plan/Router local, F-09). | Le domaine tourne côté client (violation AD-12/F-09), clé IA sur l'appareil (violation AD-3), logique du kernel dupliquée mobile/serveur. | L'app consomme **la surface UI du kernel seulement** (section 6.4, `AgentRunState`). Lint : `apps/mobile` n'importe pas la boucle kernel, pas d'import d'`AIProvider`/`AIModelRouter` (ceux-là sont serveur, 01-backend). Un test qui vérifie qu'aucun `AIProvider` n'est resolu côté client. |
| R5 | **Semantic Tree perf** : un arbre de 1 000+ nœuds qui scrolle/jaillie. | L'écran `knowledge` est inutilisable (le pack §9.2 est le SLO). | Le lazy/memo/incremental Dagre est **figé** (section 9.2) ; test perf CI ; un arbre > 500 nœuds = **obligatoire** de virtualiser. |
| R6 | **Écrans Home (AD-14) dérive** en dashboard de widgets. | Violation AD-14 (le Home est un **invariant figé**, section 6.2). | La composition **fixe + l'ordre** du Home (section 6.2) = normatif. Toute demande d'ajouter un widget = **rejet** (AD-14 : « ne doit pas devenir un dashboard de widgets »). Une itération du contenu **passé** par ADR. |
| R7 | **Offline mal géré** : l'app devient « brisée » sans réseau. | Violation AD-7 (offline = état premier, pas un failure mode). | Section 7 (`offline` est un état, pas une erreur) + test offline CI (section 11). Toute action qui **exige** le cloud est **désactivée avec explicatif**, jamais crash. |
| R8 | **DS/contract mismatch** : le `05-design-system.md` définit un contrat AD-10 **différent** de ce pack. | 2 contrats AD-10 = violation AD-13 (ne pas créer d'abstraction parallèle). | **Ce pack est la source pour la CONSO** ; `05-design-system.md` est la source pour la **DEFINITION**. Avant la vague 1, un **review conjoint** App Shell + DS team aligne les signatures (section 5 ci-dessus = spéc de la signature). **Mécanisme de gating (figé, G1)** : le pack `05-design-system.md` (owner Design System team) **ratifie** par écrit les signatures de la section 5 + le choix Zustand (R1) dans son frontmatter (section 13) — la ratification est signée par le team-lead de la DS team et l'App Shell team ; **deadline = avant la découpe de la vague 1 UI** (blocant, spine Open Question #1) ; en cas d'écart, l'ADR est porté par le pack 05 (breaking = dedicated PR + mandatory Codex review, spine §162). Tant que le pack 05 n'est pas ratifié, le coding parallèle de la vague 1 UI n'est **pas autorisé** (AD-13 : Contract Pack complet AVANT le coding parallèle). |
| R9 | **Événements AD-9 non déclarés** : l'app consomme un événement qu'elle n'a pas déclaré (AD-13/AD-9). | Double consommation, re-persist, incohérence. | Section 4 : **ce pack déclare** ses consommateurs d'événements (`JobCompleted`, `ArtifactGenerated`) — c'est **le** contrat AD-13 (pack doit lister consommateur d'événements, spine AD-13). Toute consommation non listée ici = violation. |

### Dépendances (wave gating, doc §21.12 / spine merge order Foundation → Contracts → Data/Core → Features → Agent → UI)

- **`05-design-system.md`** (Zustand + contrats AD-10 figés, section 8/R8) → **gating de la vague 1** (UI).
- **`03-sync.md`** (repositories + offline + single-writer, sections 3.2/4/7/R2/R7) → **gating**.
- **`01-backend.md`** (envelope d'erreur `AppError`, `JobCompleted`/`ArtifactGenerated` payloads, AD-9) → gating.
- **`packages/domain` (AD-15 mapping entité→package→équipe, spine Open Questions)** : l'app **consomme** les
  types ; **la SSoT de chaque entité doit être figée avant la vague 2** (sinon l'app ré-déclara — violation
  AD-15/F-01, R2/R3). **Gating de la vague 2** = l'AD-15 mapping entité→package→équipe est complété
  (spine « Deferred » → wave-0 data ; ce pack le **pré-requis**).
- **`packages/agent` (surface UI du kernel, F-09/R4)** → **gating de la vague 3** (l'app consomme la
  `AgentRunState` seulement).
- **Capacitor + Android** (phase 1) : **aucune** dépendance à Electron (spine : Electron = phase 2,
  **pas** dans le V1 ; doc §23.1). Le pack ne définit **aucun** adaptateur desktop ; la portabilité
  (doc §23.2/§23.5) est **garantie** par la séparation des couches (section 4) : le hook/service/use-case
  ne connaît **pas** Capacitor (il est **injecté**) ; seul `apps/mobile/platform` + `packages/platform`
  le connaissent. C'est ce qui rend la migration Electron (phase 2) = **ajouter un adapter**, pas
  réécrire le cœur (doc §23.4/§23.5).

### Ouvertures (à trancher avant la vague 1)

- **G1 (gating, section 8/R8)** : **ratifier** `05-design-system.md` (owner Design System team) sur **Zustand** + les
  signatures des contrats AD-10 de ce pack (section 5), par **review conjoint** App Shell + DS team. **Mécanisme
  figé** (règle du Medium du review 05) : la ratification est signée dans le frontmatter du pack 05 (AD-13 : owner
  une équipe = la DS team, one-writer-per-file) par le team-lead DS + App Shell, **deadline = avant la découpe de
  la vague 1 UI** (blocant) ; en cas d'écart = ADR porté par le pack 05 (spine §162 : breaking = dedicated PR +
  mandatory Codex review). Si le DS team résiste à Zustand = ADR (R1). Tant que G1 n'est pas ratifié, le coding
  parallèle de la vague 1 UI est **interdit** (AD-13 : Contract Pack complet AVANT le coding parallèle).
- **G2 (wave-0 data)** : **compléter** le mapping AD-15 entité→package→équipe pour les entités que l'app
  consomme (Task, Goal, Review, FocusSession, Artifact, ProgressSnapshot, SemanticNode, …) — le spine
  le marque « Deferred → wave-0 » ; ce pack le **réclame**.
- **G3 (tranchée ici)** : list virtualisation = **`IonList` natif par défaut ; `react-virtuoso` en
  fallback pour les listes > 100 items** (section 9.3) — décision normative adoptée (plus d'ouverture) ;
  la décision est consignée comme [ASSUMPTION] dans le SPEC (ratification par DS team / App Shell en
  vague 1 si divergence).
- **G4 (tranchée ici)** : nom du package `@aurora/ui` pour `packages/ui` (section 8) — figé comme
  [ASSUMPTION] dans le SPEC, ratifié avec le monorepo pnpm (spine Open Question #1, Foundation, AD-16)
  avant la vague 1.
- **G5 (tranchée ici)** : device de référence Android = **Pixel 4a (CPU mid-range, §9.1)** — figé
  comme [ASSUMPTION] dans le SPEC ; l'équipe Foundation (AD-16 observation) peut ajuster via ADR si
  l'observation Sentry/perf montre que le budget n'est pas atteignable.

---

*Pack 02/16. Prochain : 03-synchronisation (PowerSync/SQLite/Supabase) — qui définit les repositories,
l'offline-detection et la sémantique de conflit que ce pack consomme (sections 3.2, 4, 7). Le pack
05-design-system (composants + tokens + contrats AD-10 + **inventaire écran par écran**, owner
Design System team) et 01-backend (envelopes d'erreur) sont des **gating de la vague 1 UI**
(R8/G1, G4, G5 ; G2 = mapping AD-15 = gating vague 2 ; mécanisme de ratification figé en R8/G1,
section 13) — tant que le pack 05 n'est pas ratifié, le coding parallèle de la vague 1 UI est
interdit (AD-13).*
