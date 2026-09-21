---
name: "Revue de cohérence inter-packs 01–04 ↔ 05 (test du spine)"
type: review
altitude: initiative
reviewed:
  - ARCHITECTURE-SPINE.md (16 ADs, autorité)
  - dimensions/01-backend.md
  - dimensions/02-frontend.md
  - dimensions/03-sync.md
  - dimensions/04-mobile.md
  - dimensions/05-design-system.md (§1–§4 ratifiés + frontmatter G1)
status: final
created: 2026-09-21
reviewer: inter-pack coherence
schema-returns:
  verdict: "Packs 01–04 cohérents entre eux (single-writer, scopes, événements, jobs alignés) ; la jonction 05 a un trou High (FocusSessionBilan non porteur) et les paires 02/04 portent chacune une supposition binaire light/dark qui doit être corrigée pour le futur §5 v2 (10 thèmes) du pack 05."
  criticalCount: 0
  highCount: 1
  mediumCount: 5
  lowCount: 4
  mustFixForV2:
    - "02-frontend §3.3 : `UiState.theme` = 'light' | 'dark' → remplacer par une enum de thèmes v2 (10 thèmes, SSoT `packages/domain`), l'énumération actuelle verrouille le binaire dans le store UI persisté"
    - "02-frontend §5.2 : `InfographicRendererProps.theme` = 'aurora-light' | 'aurora-dark' → le contrat de CONSO doit accepter le type thème v2 (sinon 05 v2 ne peut pas s'aligner sans ADR breaking — c'est la seule signature §5 touchée par le v2)"
    - "02-frontend §8 : règle « Dark mode » (bascule theme light/dark + persist) → réécrire pour un switcher multi-thèmes (persistance par thème, pas binaire)"
    - "04-mobile : ajouter à O3 (gating, à trancher vague 0) — trancher la valeur du thème par défaut Android (système light/dark vs thème Aurora persisté) pour la phase « kill de l'app » / session nocturne du §6.1 (pack 05 §2.1.3 « jamais un thème qui change silencieusement »)"
    - "01-backend §4.x : `user_context` (UserContext, writer Identity) est le seul champ qui porte la préférence de thème utilisateur (SSoT AD-15) — documenter que la valeur est l'enum de thèmes v2, pas le binaire light/dark"
  reviewPath: "_bmad-output/architecture/architecture-aurora-2026-09-21/reviews/review-pack-coherence.md"
---

# Revue de cohérence inter-packs 01–04 ↔ 05

Méthode : pour chaque paire de packs, le **test du spine** — « deux équipes obéissant à la lettre aux deux packs produisent-elles des choses incompatibles ? » — appliqué sur les 7 axes demandés (SSoT, événements déclarés, états UX, contrats AD-10 CONSO/DEF, Focus Controller, scopes PowerSync, thème).

## Verdict

**Packs 01–04 cohérents entre eux sur les axes structurant (single-writer AD-7, ownership des scopes AD-7, vocabulaire events AD-9, jobs AD-8, RLS/RLS-service_role) ; le pack 05, en l'état, présente 1 High (FocusSessionBilan non porteur dans le contrat G2 de 02 §5.3) et 5 Medium, dont 4 sont des « préparations » à corriger dans 02/04/01 pour le futur §5 v2 (10 thèmes) — et non des incohérences actuelles.**

Le test du spine **passe** pour 01↔03, 01↔04, 03↔04, 04↔05, 03↔05 (zéro trou). Il **échoue partiellement** pour 02↔05 (High H1 + préparations v2) et 01↔02 (Medium M4, AppError SSoT ambiguë).

---

## Findings classés par sévérité

### Critical

*(aucun)*

### High

**H1 — Paire 04-mobile ↔ 05-design-system (axe 5, Focus Controller / blocage natif)**

`04-mobile` §4.1 point 4 dit que le bilan de session Focus **doit** exister « dans l'inventaire d'écrans du pack 05 avec le G2 contractuel » et que « si le pack 02 ne définit pas cette vue G2, les équipes Productivity + Design produisent des UIs de bilan incompatibles — le pack 05 porte le contrat, pas le pack 02 ».
`05` §3.6.9 (`FocusTimer`) dit : « le bilan de fin de session, `FocusSessionBilan`… Skeleton du bilan, pack 04 §4.1 point 4 : le bilan **doit** exister dans l'inventaire §4.11 avec le G2 contractuel ».
`05` §4.4.2 (`focus-mode`, Transitions) dit : « Terminer la session → un BottomSheet de bilan (le `FocusSessionBilan`, pack 04 §4.1 point 4 : durée réelle, interruptions, score de concentration — le bilan est un **`ChartSpec` consommé par `DataVisualizationRenderer` G2, pack 02 §5.3 : « l'écran de bilan Focus **doit** être dans l'inventaire d'écrans du pack 05 avec le G2 contractuel ») ».
Le pack 05 dit « le G2 **contractuel** » mais **ne dégage pas** la forme du contrat — i.e. il ne définit **nulle part** :
- le type `FocusSessionBilan` (les 4 champs exacts : durée réelle, interruptions, score de concentration, tâches associées ?),
- le `ChartSpec` de bilan (les marks/axes/scales du spec G2),
- le composant DS qui l'affiche (le `FocusTimer` §3.6.9 dit « Skeleton du bilan » mais ne spécifie **pas** de composant `BilanSheet` / `SessionBilan` dédié, contrairement aux 12 autres composants §3.6).
Deux équipes (Productivity, qui produit `FocusSessionBilan` ; Design, qui le rend) obéissent à la lettre à 04 + 05 et **produisent deux spécifications divergentes** (04 : « 3 champs, score de concentration » ; 05 : « 1 composant + ChartSpec non nommé ») — violation de AD-13 (pas de contrat porteur = abstraction parallèle) et de AD-15 (shape de domaine sans SSoT).
**Correction recommandée** (avant découpe vague 1 UI, G1 02 R8) :
1. Définir `FocusSessionBilan` dans `packages/domain` (AD-15, owner Productivity module, `01-backend` §2.1) : `{ sessionId, startedAt, endedAt, durationSec, interruptions[], focusScore, taskIds[] }` ;
2. Définir le `ChartSpec` de bilan dans `05-design-system` §3.6.9 (les marks : `ProgressBar` (temps total) + `Timeline` des interruptions + `Sparkline` du score, pas un G2 chart complet — le bilan n'est **pas** une série temporelle volumineuse) ;
3. Nommer le composant DS qui l'affiche (ex. `FocusBilan` §3.6.13) et l'ajouter à la matrice §3.7 ;
4. `04-mobile` §4.1 point 4 : pointer vers le SSoT (1) — « le shape `FocusSessionBilan` est défini dans `packages/domain`, pas ici » ;
5. Vérifier que `02-frontend` §5.3 (`DataVisualizationRendererProps.spec: ChartSpec`) couvre le `ChartSpec` de bilan **sans** modifier la signature (le v2 des 10 thèmes n'y touche pas).

### Medium

**M1 — Paire 02-frontend ↔ 05-design-system (axe 4, contrats AD-10 CONSO/DEF)**

`05-design-system` frontmatter G1 ratifie « les signatures de CONSO des contrats AD-10 (02 §5.1–5.5) : section 3.6 ci-dessous définit les implémentations (DEF) ; les props d'entrée (RenderSemanticNode, ChartSpec, LaTeX string, RevealKey…) sont **identiques** aux signatures 02 §5 ». La vérification de l'égalité exacte des props est **impossible en l'état** : `05` §3.6 dit « les props d'entrée = identiques aux signatures de consommation ratifiées dans le frontmatter G1 » mais **ne reproduit pas** les 5 signatures CONSO dans le corps du pack — il les pré-suppose. De plus, `05` §3.6 introduit **9 composants data** (§3.6.1 `DataTable` + §3.6.2 `KeyValueList` + §3.6.3 `Timeline` + §3.6.4 `GanttRow` + §3.6.5 `Sparkline` + §3.6.6 `SemanticTreeNode` + §3.6.7 `InfographicSlot` + §3.6.8 `MathBlock` + §3.6.9 `FocusTimer`) qui **enveloppent** les 5 contrats AD-10, mais n'importe **que 4 des 5** (le 5ᵉ, `AnimationController` §3.6.5 de 02, n'a **pas de wrapper DS dédié** — `05` §2.6 dit `useReducedMotion()` + `AnimationController.setReducedMotion(on)` mais ne spécifie pas quel composant DS l'appelle).
Deux équipes obéissent à la lettre : (a) Productivity implémente `02 §5.5 AnimationController` (CONSO) ; (b) Design implémente les 4 wrappers §3.6 (DEF) **sans** le 5ᵉ ; (c) l'app fait `import { reveal, setReducedMotion } from '@aurora/ui'` et reçoit une **API qui n'existe pas dans le §3.6 de 05** (le §2.6 dit `packages/ui` l'expose mais ne dégage pas le **contrat de props** du composant qui l'enveloppe).
**Correction recommandée** : ajouter à `05` §3.6.5 (ou créer §3.6.13) un composant `AnimationSlot` (ou `useAuroraAnimation` hook) qui **enveloppe** `AnimationController` avec les props exactes de `02 §5.5` (`RevealKey`, `nodeRef`, `reducedMotion`) et déclarer explicitement dans le frontmatter G1 : « 02 §5.5 = CONSO ; 05 §3.6.13 = DEF (props identiques) ».

**M2 — Paire 02-frontend ↔ 04-mobile (axe 3, états UX divergents)**

`02-frontend` §7 liste **5 états canoniques** par écran : `loading` / `empty` / `success` / `error` / `offline` (AD-13 DoD, pack 02 §11 : « un écran qui n'implémente pas l'un des 5 = DoD non-fermé, blocking review »).
`04-mobile` §6.1 (cycle de vie) définit un **6ᵉ état implicite** : `killed` (Android n'expose pas de signal fiable ; le kill = swipe du taskbar ; le retour au boot = **re-lecture** du store local, AD-7). `04` §7.1 (tests) dit : « kill de l'app (swipe) + relance = l'état local **est intact** ». Cet état `killed` n'est **pas dans la matrice des 5 états de 02 §7**, **ni** dans la matrice §3.7 de 05 (les composants n'ont **pas de colonne killed**). Deux équipes obéissent à la lettre : (a) App Shell implémente 5 états (pack 02) ; (b) Foundation implémente le test de kill (pack 04) ; (c) les 5 états de (a) sont **tests sur l'app en vie** — le **reboot après kill** n'est **pas couvert** par la matrice 02 (le `loading` après reboot est couvert par le test de re-sync §5.5 de 03, mais le **`killed` comme état de composant** n'est **pas nommé nulle part**).
**Correction recommandée** : ajouter un 6ᵉ état **nommé** `killed` (ou `resumed`) dans `02-frontend` §7 (la matrice des 5 états reste les 5 **premières classes** ; le `killed` = un **sous-état d'**`loading` : « le store local est relancé, les composants repartent en skeleton jusqu'à la re-synchro du store ») + ajouter une colonne `killed` dans la matrice §3.7 de 05 (les composants qui **ont** de la mémoire volatile = `Killed` = skeleton + re-sync) et **pas** dans les composants qui **n'en ont pas** (les pure display).

**M3 — Paire 01-backend ↔ 02-frontend (axe 1, SSoT d'`AppError`)**

`02-frontend` §10 définit `AppError` / `AppErrorCode` dans un bloc `export interface` (le **corps du pack**) avec un commentaire en ligne « SSoT : `packages/domain` (AD-15) — l'APP importe, ne redéfinit pas : `import { AppError, AppErrorCode } from '@aurora/domain'` ». Le **corps est le SSoT de la forme** — une copie inline **duplique** le type que le commentaire dit être dans `packages/domain` (AD-15/F-01 : « une copie inline dans ce pack serait une violation AD-15/F-01 »). `01-backend` §3.1 dit : « AppError (SSoT `packages/domain`, AD-15 — le type consommé par l'UI, pack 02 §10 ; la SSoT de `AppError`/`AppErrorCode` vit dans `packages/domain`, owner Foundation, **jamais ré-déclaré ici**) » — i.e. `01` **refuse** d'en donner le shape, renvoie vers `packages/domain`, mais **le shape complet n'est dans **aucun** des deux packs** (02 le donne **en corps**, 01 le **refuse**). Deux équipes obéissent à la lettre : (a) le Feature agent lit le shape dans `02 §10` (le corps) et l'**utilise** tel quel ; (b) le Data agent lit la **règle** dans `01 §3.1` (jamais ré-déclaré) et **n'écrit pas** le shape dans `packages/domain` → le shape `AppErrorCode` n'est **pas figé en SSoT** et l'`UI branch` sur des codes que le `server` n'a pas défini (violation AD-15/F-01).
**Correction recommandée** : (1) Déplacer **le shape** de `AppError`/`AppErrorCode` dans `packages/domain` (AD-15, owner Foundation — `01-backend` §2.3) ; (2) `02-frontend` §10 : remplacer le bloc `export interface` par **un commentaire** qui **renvoie** à `@aurora/domain` (le corps ne doit **pas** contenir le shape, seulement la **documentation** du contrat consommé) ; (3) `01-backend` §3.1 : ajouter le shape (1) et pointer vers `@aurora/domain` (les 2 packs **doivent** pointer vers le même SSoT, **pas** l'un vers l'autre).

**M4 — Paire 03-sync ↔ 02-frontend (axe 2, événements consommés sans déclarer)**

`03-sync` §3.2 définit `SyncStatus` (`{ online, pendingUpstream, lastSyncAt, state }`) + `SyncStateChanged` (interne, **non**-AD-9, hook de notification **interne** du store local, §5.8 : « pas d'invalidate par événement AD-9 (l'UI lit le store local, AD-7/F-03) »).
`02-frontend` §7 (état `offline`) dit : « `offline` est détecté via `@capacitor/network` (injecté par `packages/platform`) : `onNetworkChange → store.uiStore.setOffline(bool) → tout l'app bascule en mode offline. La détection réseau est **injectée**, jamais importée en dur dans `presentation/` » — i.e. le store UI **écrit** `offline` **directement** depuis le `@capacitor/network` (via l'adapter `NetworkStatusAdapter` pack 04 §3.2.6), **pas** depuis `SyncStatus.online` (le contrat §3.2 de 03).
Deux équipes obéissent à la lettre : (a) la Data team implémente `SyncStatus` (03 §3.2) ; (b) l'App Shell team implémente `setOffline(bool)` depuis `NetworkStatusAdapter` (04 §3.2.6 / 02 §7) ; (c) les **deux** sont **déclarés** dans les packs — mais `02 §7` **consomme** un **signal réseau** (`@capacitor/network`) **sans le déclarer dans son Contract Pack** (le frontmatter de 02 consomme `03-sync` (state UI, use-cases, états UX) — **pas** le plugin `@capacitor/network` (il est **whitelisted** par 04 §3.1 mais **pas déclaré consommé par 02**) — violation AD-13 (F-04 : « un module qui consomme un événement doit le déclarer dans son Contract Pack » ; le `NetworkStatusAdapter.onNetworkChange` **est** un **événement** (même interne) **consommé par 02** et **non déclaré** dans 02).
De plus : `03 §5.9` dit « l'UI **ne décide jamais** de l'offline elle-même (le `SyncStatus` **est** le contrat, pas le store UI) » — i.e. **03 dit que le signal offline = `SyncStatus.online`** (03 §3.2), mais **02 dit que le signal offline = `@capacitor/network`** (02 §7) — **les 2 packs se contredisent** sur **qui** est le **producteur** du signal offline. `04 §3.2.6` (`NetworkStatusAdapter`) et `03 §5.8` (bridge React Query) **doivent** être alignés : le **signal** offline (le booléen) **vient** de `@capacitor/network` (le plugin, via l'adapter), **mais** le **état** offline (le booléen **persisté** dans le store UI, qui **pilote** la bannière + le `data-state` des composants) **doit** passer par `SyncStatus.online` (03 §3.2, l'état de sync), **pas** par un `setOffline` **direct** (02 §7).
**Correction recommandée** : (1) `02-frontend` §7 : remplacer `store.uiStore.setOffline(bool)` par `useSyncStatus(s => s.online)` (le store UI **consomme** `SyncStatus`, ne le **produit** pas — le producteur de `SyncStatus.online` = `packages/data` (03 §3.2) qui **écoute** `NetworkStatusAdapter` (04 §3.2.6, injecté par `packages/platform`) et **met à jour** `SyncStatus.online` → l'UI **lit** `SyncStatus.online` (03) **pas** le plugin **directement** (02) ; (2) `02-frontend` frontmatter : ajouter `consumes: ['NetworkStatusAdapter (via packages/platform, 04 §3.2.6) → SyncStatus (03 §3.2)']` ; (3) `03 §5.9` : clarifier que le **chaîne** = `@capacitor/network` (plugin) → `NetworkStatusAdapter` (04) → `packages/data` (produit `SyncStatus.online`, 03) → `store UI` (consomme `SyncStatus`, 02) — **une** chaîne, **pas** deux (le `setOffline` **direct** de 02 §7 est le **2ᵉ producteur** à supprimer).

**M5 — Paire 04-mobile ↔ 02-frontend (axe 7, thème binaire light/dark — « préparation » v2, pas incohérence)**

`02-frontend` §3.2 (store UI) : `theme: 'light' | 'dark'` (l'état cosmétique persisté par le `persist` middleware, pas le store local — §3.2 : « l'état important = store local (PowerSync/SQLite), **pas** Zustand/localStorage » ; mais le **thème** est classé **cosmétique** = Zustand). `04-mobile` §6.1 : « **jamais** un thème qui **change** silencieusement au retour foreground » (05 §2.1.3) ; le kill de l'app = le thème persisté **reprend** (le `persist` middleware Zustand, pas le store local AD-7).
Deux équipes obéissent à la lettre : (a) App Shell (02) implémente `theme: 'light' | 'dark'` (binaire) ; (b) le pack 05 **§5 v2** (10 thèmes, futur) dit « le thème = une enum de **10** valeurs, SSoT `packages/domain` » — (a) et (b) sont **incompatibles** : le store UI (a) **persiste** une **union binaire** ; le §5 v2 (b) **exige** une enum de **10** valeurs ; l'**ADR v1.7** **ne définit** **pas** le type `Theme` (le spine AD-15 dit « l'enum de thèmes = SSoT `packages/domain` » — **le type n'est figé nulle part**). **Ce n'est pas une incohérence actuelle** (le §5 v2 **n'existe pas** encore, c'est un futur pack) — c'est une **« préparation »** à faire **avant** la découpe vague 1 UI (sinon le store UI **verrouille** le binaire **avant** le §5 v2, et le v2 **doit** être porté par un **ADR breaking** — spine §162 : « breaking = dedicated PR + mandatory Codex review », plus coûteux que de le faire **maintenant** en vague 0).
**Correction recommandée (préparation, pas correction d'incohérence)** : voir `mustFixForV2` ci-dessous (5 entrées, 02 + 04 + 01).

### Low

**L1 — Paire 02-frontend ↔ 05-design-system (axe 4, ratification G1 signée sans date)**

`05-design-system` frontmatter G1 : `signed: "Design System team lead"` (pas de **nom**, pas de **date**, pas de **référence** au PR de ratification). `02-frontend` R8/G1 dit : « la ratification est signée par le team-lead de la DS team et l'App Shell team ; **deadline = avant la découpe de la vague 1 UI** (blocant, spine Open Question #1) ». La **signature** du G1 est **absente** du frontmatter (pas de `signed: [...]` ; pas de `date: 2026-09-21` ; pas de `pr: ...`). Le **mécanisme** est figé (02 R8) mais le **fait** de ratification est **non consignée** dans les deux packs (05 dit « ratifié » **sans** nommer **qui** ni **quand**). **Correction** : ajouter à `05-design-system` frontmatter G1 : `signed: ['<nom team-lead DS>', '<nom team-lead App Shell>'], date: 2026-09-21, pr: '<URL PR ratif>'` (le PR de ratification **est** le **premier** PR de la vague 1 UI — **gating** 02 R8).

**L2 — Paire 03-sync ↔ 01-backend (axe 6, `jobKind` nomenclature partagée mais non vérifiée)**

`03-sync` §5.5 (re-sync) : « la clé de déduplication côté client (figée, normative) : `localMutationId` = ULID… ; le serveur déduit la clé depuis le `source_local_mutation_id` (ULID, champ de `job_queue`) si le job est ré-emis par un re-sync » — i.e. le **champ** `source_local_mutation_id` (ULID) **existe dans `job_queue`** (03 §5.5) **et** dans `01 §5.3` (l'`idempotency_key` UNIQUE : `job_kind + hash du payload logique + user_id` ; « si le job est déclenché par une mutation locale (re-sync, pack 03 §5.5), le champ `source_local_mutation_id` (ULID, pack 03) entre dans le hash »). Les **deux packs** **pointent** l'un vers l'autre (03 → 01 pour `job_queue` ; 01 → 03 pour `localMutationId`/`source_local_mutation_id`) — **la forme du type** (ULID) **et** le **lieu du SSoT** (`job_queue` = 01 §5.3, owner Foundation) **sont** cohérents ; **mais** le **nom** du **champ** est **différent** dans les **deux** (03 : `localMutationId` (le client génère) → `source_local_mutation_id` (le serveur reçoit) ; 01 : `idempotency_key` (le hash, le serveur **calcule**) — le **lien** `localMutationId` (client) ↔ `source_local_mutation_id` (serveur) ↔ `idempotency_key` (le hash de `source_local_mutation_id`)**n'est pas figé dans un seul pack** (il **traverse** 01 + 03 **sans un SSoT unique**). **Correction** : `01-backend` §5.3 : figer le **shape complet** de `job_queue` (y compris `source_local_mutation_id?: string` (ULID, **nullable**, champ de dédup client-originé) **et** `idempotency_key` (calculé, le hash) — **un seul** pack (01, owner `packages/data` / Foundation, AD-16) **définit** la **table** ; `03` **pointe** (pas **définit**).

**L3 — Paire 04-mobile ↔ 03-sync (axe 6, `minSyncIntervalMs` paramètre PowerSync owner `packages/data` mais « imposé » par 04)**

`04-mobile` §5.7 / §6.2 : « le pack `04-mobile` §6.2 **impose** la contrainte : « la fréquence de sync PowerSync baisse automatiquement en background, intervalle ≥ 5 min, pas de polling réseau en app background ». Cette mécanique **est** de l'owner de ce pack (`packages/data`) : le paramètre PowerSync **figé** est : `minSyncIntervalMs` (foreground ~30 s ; **background ≥ 5 min**) ».
`03-sync` §5.7 : « **Déclenchement** : le passage foreground/background est signalé par `AppLifecycleAdapter` (pack 04 §3.2.1, injecté par `packages/platform`) → `packages/data` ajuste `minSyncIntervalMs` ».
Les **deux** packs sont **cohérents** (03 **définit** le paramètre ; 04 **impose** la contrainte — « les deux packs sont cohérents », dit 04 §5.7 lui-même) — **mais** la **déclaration** dans le frontmatter de 04 est **ambiguë** : `04` consomme `03-sync` (repositories, offline) — **pas** le paramètre `minSyncIntervalMs` (c'est le **contraire** : 04 **impose** la contrainte **à** 03, pas l'inverse ; le **consommation** est dans le sens 04 → 03, pas 03 → 04). **Correction** : `04-mobile` frontmatter : ajouter `03-sync.md (minSyncIntervalMs §5.7 — 04 **impose** la contrainte (≥ 5 min background), 03 **définit** le paramètre ; le sens de la dépendance est 04 → 03, **pas** 03 → 04)` ; **pas** une incohérence, une **clarification**.

**L4 — Paire 05-design-system ↔ 02-frontend (axe 1, SSoT des types de rendu `RenderSemanticNode` / `ChartSpec`)**

`02-frontend` §5.1 / §5.3 dit : `RenderSemanticNode` (le type de projection de `SemanticNode` + `NodeState`) **est** défini **dans le pack 02** (le corps) — `export interface RenderSemanticNode { id, concept, state: NodeState, hasChildren?, sourceRef? }` ; `ChartSpec` (le spec G2) **est** « **figé** par le Design System » (§5.3 : « spec: ChartSpec ; // L'app ne construit jamais un Chart G2 en dur ; le Design System le rend ») — i.e. le **shape** de `ChartSpec` **n'est** **pas** défini dans 02 (02 dit « **figé** par le DS ») **ni** dans 05 (05 §3.6.5 `Sparkline` dit « un polygone/ligne G2 minimal » **sans** le shape du spec). **Le SSoT de `ChartSpec` n'est dans **aucun** des 2 packs** (AD-15 : chaque shape **frozen** a **exactly one** owning package — `ChartSpec` = `packages/domain` ? `packages/ui` ? **non résolu**). `RenderSemanticNode` **est** dans 02 (le corps) — **c'est cohérent** avec le G1 (05 ratifie 02 §5.1) **mais** le **type** est **dans le corps de 02** (pas dans `packages/domain`) — **AD-15** dit « l'entité **frozen** (liste spine § Consistency Conventions : `SemanticNode/Edge/Bridge/State`) a **exactly one** owning **package** » — `RenderSemanticNode` est une **projection** (AD-15 : « une projection **est** une vue déclarée du type partagé, **pas** une ré-définition ») — **c'est OK** (c'est une **vue**, pas une **ré-définition**) — mais **le shape** de `ChartSpec` **n'est** **pas** une **vue** d'une entité AD-15 (c'est un **spec** de **rendu**, **pas** un **type de domaine**) — le **SSoT** de `ChartSpec` **doit** être **tranché** (05 §3.6.5 dit « **figé** par le DS » → `packages/ui` ; **ou** `packages/domain` (le spec **est** le **contrat** entre l'UI et le moteur, **pas** le **moteur**)). **Correction** : `02-frontend` §5.3 : ajouter le **shape** de `ChartSpec` (les props **entrantes** du G2, **pas** le moteur) **ou** le **renvoyer** vers `packages/ui` (AD-15 : le spec **est** le **contrat** de **rendu**, le **wrapper** de 05 **est** le **def**) — **pas** laisser **flottant** (l'équipe Feature **peut** **écrire** **son** `ChartSpec` **différemment** **de** l'équipe Design = AD-15 violation).

---

## Préparations (01–04 à ajuster pour compatibilité avec le futur §5 v2 — 10 thèmes)

Ces 5 entrées **sont dans** `mustFixForV2` (frontmatter) et **sont** **détaillées** ici. Elles **ne sont** **pas** des **incohérences** (le §5 v2 **n'existe** **pas** **encore** ; les packs 01–04 **supposent** **un** thème **binaire** **light/dark** qui **doit** être **ouvert** à **10** valeurs **avant** la découpe vague 1 UI, **sinon** le **verrouillage** **binaire** **devient** un **ADR breaking** (spine §162)) :

1. **`02-frontend` §3.3** (le store UI) : `theme: 'light' | 'dark'` → **remplacer** par `theme: AuroraTheme` (l'enum v2, SSoT `packages/domain`, AD-15) ; **ne pas** figer le **binaire** dans le **corps** du **store** (le **persist** middleware **persiste** le **thème** : si le **type** est **binaire**, le **v2** (10) **doit** être un **migrateur** (le **persist** **doit** migrer **l'ancien** binaire vers **le** v2, **pas** vers **le** binaire **nouveau**).
2. **`02-frontend` §5.2** (le `InfographicRenderer`) : `theme?: 'aurora-light' | 'aurora-dark'` (le G1 dit que le v2 **n'a** **pas** de **palettes** nommées **par thème**, **mais** **par hue** : le v2 **enregistre** les **10 thèmes** comme **palettes** **du** moteur, **pas** 2 palettes **binaires**) → **remplacer** par `theme?: AuroraTheme` (le **type** v2, **pas** le binaire).
3. **`02-frontend` §8** (le DS intégré) : « **Dark mode** : bascule via le `theme` du store UI (section 3.2) + tokens du DS ; l'app ne fait aucun override inline. Le changement de thème est **persisté** (store persist middleware). » → **réécrire** : « **Thème** (v2 : 10 valeurs, SSoT `packages/domain` AD-15) : bascule via le `theme` du store UI + tokens du DS ; l'app ne fait **aucun** override **inline** (règle 02 §8 : « Toute valeur hors token = blocking finding ») ; le **changement** de **thème** est **persisté** (store persist middleware — le **persist** **doit** **migrer** le binaire **ancien** (light/dark) vers l'enum **v2** (10), **pas** le **recréer**). »
4. **`04-mobile`** (le kill de l'app §6.1 + la session nocturne §2.8) : ajouter à **O3** (gating, à trancher vague 0) : « trancher la **valeur** du **thème** par **défaut** Android (**système** light/dark **vs** thème Aurora **persisté**) pour la phase « kill de l'app » / session nocturne du §6.1 (05 §2.1.3 : « jamais un thème qui change silencieusement au retour foreground ») ; le v2 (10 thèmes) **doit** avoir une **stratégie de fallback** si le thème persisté **n'est** **pas** dans le set de 10 (ex. un thème désactivé, une migration majeure) — le fallback **par défaut** = le thème **light** (le §1 de 05 dit light **par défaut**). »
5. **`01-backend` §4.x** (`user_context` / `UserContext`, AD-15, owner Identity, le mapping `03-sync` §4.2) : documenter que **la valeur** de la **préférence** de **thème** utilisateur (un **champ** de `UserContext`) est **l'enum de thèmes** **v2** (10), **pas** le binaire light/dark ; le **champ** **est** **nullable** (pas de **préférence** = thème système / par défaut, le §1 de 05 dit « light par défaut ») ; le **migrateur** (le binaire **ancien** → le v2) **est** **porté** par **`packages/domain`** (AD-15), **pas** par 01 (01 **persiste** **l'enum** **v2**, ne **migre** **pas**).

---

## Axes vérifiés sans trou (à référence)

- **01 ↔ 03 (scopes PowerSync)** : `01 §3.4` (« `packages/data` possède TOUTES les vues, provisionnées en vague 0 ») **et** `03 §5.4` (« `packages/data` possède **TOUTES** les vues PowerSync (scopes), provisionnées en vague 0 ») **sont** **cohérents** ; les **2 packs** **partagent** le **même owner** (`packages/data`, AD-7, AD-16) ; **aucun** des **deux** packs **n'ajoute** une vue **sans** **PR** (spine § Consistency Conventions). **Axe 6 : PAS de TROU.**
- **04 ↔ 03 (throttling sync background)** : `04 §6.2` **impose** la contrainte (intervalle ≥ 5 min, pas de polling) ; `03 §5.7` **définit** le paramètre (`minSyncIntervalMs`) ; **les** **2** **sont** **cohérents** (« les deux packs sont cohérents », 04 §5.7). **Axe 6/5 : PAS de TROU.**
- **03 ↔ 05 (états UX)** : `03 §6` (la matrice des 5 états) **et** `05 §3.7` (la matrice des 5 états par composant) **portent** **le** **même** set **(`loading` / `empty` / `success` / `error` / `offline`)** ; **l'état** `success` **de** `03 §6` (l'échec de job → `error`, le retry `jobId`) **est** **dans** `05 §3.7` (`ProgressBar` / `FlashcardCard` : « le dernier syncé reste ») — **pas** de divergence. **Axe 3 : PAS de TROU.**
- **01 ↔ 04 (jobs / R2 / OneSignal)** : `04 §5` (scan, audio, R2) **dit** « les OCR / STT = jamais embarqué (AD-1) ; les clés R2 / OneSignal **n'existent** **jamais** sur **l'appareil** (AD-3, 01 §5.4) » ; `01 §5.4` (presigned URLs : `presignGet` TTL 15 min, `presignUpload` TTL 5 min) **et** `04 §3.2.2` (`LocalFileStorageAdapter.upload` **n'a** **jamais** de clé R2) **sont** **cohérents** ; **le test** `04 §7.2b/e` **vérifie** que **`capacitor.config.ts`** **ne** contient **pas** de clé OneSignal **serveur-side** (AD-3, 01 §5.1 `fn-notifications`). **Axe 1/2 : PAS de TROU.**
- **02 ↔ 03 (états UX + use-cases)** : `02 §4` (use-cases, **partial-intent** `DomainCommand` SSoT `packages/domain`, AD-15) **et** `03 §3.1` (les `cmd` **sont** **toujours** des `DomainCommand` **partials**, **pas** des entités **complètes**) **sont** **cohérents** (« le pack 02 §4 use-cases émet des partials — `completeTask(id)`, `rescheduleTask(id, newDueAt)` ; les commandes par entité sont figées dans `packages/domain` (owner par entité, AD-15) »). **Axe 1/3 : PAS de TROU.**

---

## Recommandation d'ordre de correction

1. **H1** (FocusSessionBilan, 04 ↔ 05) : **before** découpe vague 1 UI (G1 02 R8).
2. **M1** (AnimationController §3.6, 02 ↔ 05) : **before** découpe vague 1 UI (G1 02 R8).
3. **M4** (AppError SSoT, 01 ↔ 02) : **vague 0** (le shape doit être **figé** dans `packages/domain` **avant** le mapping AD-15, spine § Deferred).
4. **M2** (killed, 02 ↔ 04) : **vague 1** (le test de kill 04 §7.1 **doit** exister dans la matrice 02 §7 **avant** l'implémentation des écrans signature).
5. **M5** (thème v2, 01 ↔ 02 ↔ 04) : **vague 0** (les 5 `mustFixForV2` **doivent** être faites **avant** que le §5 v2 **ne** soit découpé — le store UI **ne doit** **pas** figer le binaire **avant** que le §5 v2 **n'existe**).
6. **L1–L4** : **vague 0 / 1** (l'ordre exact **peut** être **arbitré** par le team-lead ; les **4** **sont** de **faible** **sévérité**).
