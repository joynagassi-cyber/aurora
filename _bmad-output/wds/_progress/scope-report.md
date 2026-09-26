# Phase 3 — Analyse de périmètre (scope analysis)

```yaml
project: Aurora
phase: Phase 3 — WDS UX Scenarios (step 02: scope analysis)
date: 2026-09-23
status: draft
type: bridge document — chaque affirmation porte un pointeur source ; rien n'est inventé
sources:
  - inventaire « Screen Registry » (WDS Phase 3) → `05-design-system.md` §4 + frontmatter (compteur 44), § `EXPERIENCE.md` §Information Architecture (15/17/19)
  - inventaire « Surfaces utilisateur » (matrice 15 pages) → `docs/mobile/navigation-and-page-composition.md` §2 + `.working/extract-05-section4-screens.md`
  - inventaire « parcours et boucles nommés » → `EXPERIENCE.md` §Key Flows + `adr-extract.md` §2/§5/§13.9/§15(v1.7)/§19/§25.11/v1.6 §8 + `docs/knowledge/discovery-gap-pipeline.md` §1/§1.1/§3/§5
  - inventaire « Cross-cutting UX states & product modes » → `EXPERIENCE.md` §State Patterns/§Feature Registry & Product Modes + `feature-registry.md` §1/§4/§6/§7 + `05-design-system.md` §3 matrice AD-13
  - findings critique (verdict FAIL) → `docs/productivity/eisenhower.md` §4, `docs/architecture/coverage-matrix.md` L33, `docs/architecture/gap-register.md` L40, `docs/features/master-feature-catalog.md` L20, `docs/frontend/module-ownership-matrix.md` L39, `docs/discovery/overview.md` §4, `docs/focus-mode/spec.md` §4/§6/§7, `05-design-system.md` §5.7.2/§7.2
  - skill WDS Phase 3 (typologie & scale) → `.claude/skills/wds-3-scenarios/steps-c/step-02-analyze-scope.md` §1–§4
```

> Note de périmètre : le rapport est un **bridge** — il consolide les 4 inventaires dimensionnels + la critique sans réinventer de contenu. Les comptes en conflit sont rapportés **verbatim** et marqués UNRECONCILED, comme demandé ; aucune résolution silencieuse.

---

## Typologie & format de scénario

**Classification (selon le skill WDS Phase 3, `step-02-analyze-scope.md` §1) : Dynamic App.**

- **Justification par l'inventaire des surfaces** : Aurora est une app mobile **local-first** (productivité + apprentissage + agent) — « offline = état premier » (AD-7, pointé par l'inventaire Screen Registry §E : `ARCHITECTURE-SPINE.md` AD-7), 15 pages de matrice mobile + overlays/routes de détail (`docs/mobile/navigation-and-page-composition.md` §2), registres de features/modes (`feature-registry.md` §1–§7), capability/agent kernel (`adr-extract.md` §5, §8 v1.6). C'est un outil de productivité/apprentissage à usage quotidien, pas un site vitrine → **Dynamic App** du taxonomy du skill (« SaaS, booking system, social platform, productivity tool »).

**Recommandation (selon skill, `step-02-analyze-scope.md` §1, branche Dynamic App) :**

- **Format de scénario = Storyboard** (états dans les vues, « document states within views ») pour les workflows cœur. Justifié par l'inventaire **cross-cutting** : l'app expose 5 états UX canoniques (`loading`/`empty`/`success`/`error`/`offline`) + sous-état `killed` + 4 intermédiaires (`hover`/`pressed`/`focus`/`disabled`) — source : inventaire cross-cutting §A (A1–A10), `EXPERIENCE.md` §State Patterns, matrice AD-13 de `05-design-system.md` §3.7. Les états par vue sont le matériau de base du format Storyboard.
- **Format de scénario = Screen Flow** pour les parcours multi-étapes :
  - **Onboarding** — 3 écrans max, sans tour de fonctions (inventaire Screen Registry §A, #1 `onboarding` §4.1.1 ; inventaire surfaces §2, #16 ; pointeur `extract-05-section4-screens.md` ligne `onboarding`).
  - **Equivalent de checkout dans Aurora** : capture → triage (CTA « Capture this » → `/inbox` → triage vers tasks/learn/settings) et focus session (lancement → timer ring → bilan BottomSheet) — source : inventaire parcours, flows 1 & 4 (`EXPERIENCE.md` §Key Flows items 1/4).
  - Justification : ces flux sont séquentiels (page-à-page), là où les workflows de productivité (révisions, projets, reviews) vivent **dans** des vues persistes (Home AD-14 invariant, overlays au-dessus du tab courant, retour à la destination d'origine — invariants S6.2, `EXPERIENCE.md` §Information Architecture lignes 60-64 ; inventaire parcours flow 5 « Return destination »).

**Citation du dimension-file justificatif** : l'inventaire **Screen Registry §E** (l'AD-14 comme surface signature + AD-13 pour les états + AD-7 offline-first) est le dimension-file qui justifie « Storyboard pour les workflows cœur + Screen Flow pour onboarding/capture-focus ».

---

## Inventaire des surfaces

Liste fusionnée et dédupliée. Chaque surface porte ses pointeurs ; les surfaces présentes dans plusieurs inventaires portent tous les pointeurs. **Numérotation** continue : S-01…S-26 (base canonique), S-27…S-31 (référencés sans section propre), S-32…S-36 (critique G1–G3 + `exercises`).

### A. Surfaces nommées (base canonique)

1. **`onboarding`** — 3 écrans max, choix de profil (étudiante/matière/horaire silence/thème), sans tour de fonctions. [Screen Registry §A #1 §4.1.1 ; Surfaces §2 #16 ; Critique : absente de la matrice 15 (justifie le compteur 17)]
2. **`welcome/home`** — écran racine (AD-14 invariant), 7 blocs fixes ordonnés (agenda, prochaine action, priorité, progression critique, révisions dues, accès Focus, suggestions Coach). [Screen Registry §A #2 §4.1.2 AD-14 ; Surfaces §1 #1 `/home`]
3. **`projets-liste`** — tous les projets (jalons, progression, tâches) en Cards flat, tri par date/progression/priorité. [Screen Registry §A #3 §4.3.1 ; Surfaces §1 #5 `/projects`]
4. **`projets-detail`** — un projet avec tout son contexte (objectif, jalons, tâches, documents, notes, historique). [Screen Registry §A #4 §4.3.2 ; Surfaces §6 (non détaillée, pointeur `extract-05-section4-screens.md`)]
5. **`kanban`** — board Kanban global des tâches par statut (5 colonnes : à faire/en cours/bloqué/terminé/annulé), drag local entre colonnes. [Screen Registry §A #5 §4.3.3 ; Surfaces §1 #3 `/tasks`]
6. **`objectifs-liste`** — objectifs court/moyen/long terme en Cards. [Screen Registry §A #6 §4.3.4 (1ʳᵉ composante de la paire)]
7. **`objectifs-detail`** — un objectif : hiérarchie (projets qui y contribuent), indicateurs, jalons. [Screen Registry §A #7 §4.3.4 (2ᵉ composante) ; Surfaces §1 #6 `Goals`]
8. **`habitudes`** — suivi d'habitudes/routines, heatmap d'adhérence `HabitStreak`, check-in « Marquer aujourd'hui ». [Screen Registry §A #8 §4.3.5 ; Surfaces §3 #18 ; variant desktop §5 (heatmap 12 sem. vs 7 mobile)]
9. **`routines`** — routines ordonnées (matin/soir/étude) — une séquence d'étapes, pas un to-do. [Screen Registry §A #9 §4.3.6 ; Surfaces §3 #19]
10. **`calendrier-jour` / `calendrier-semaine` / `calendrier-mois`** (1 écran, 3 modes — composant partagé `Pager`) [Screen Registry §A #10-12 §4.4.1 ; Surfaces §1 #4 `/calendar` + variant desktop §5 (semaine 7×24h)]
11. **`focus-mode`** — session de concentration (timer ring 160px, sans chrome) + bilan de fin en `BottomSheet`. [Screen Registry §A #13 §4.4.2 ; Surfaces §1 #12 `Focus` ; Critique T1 : états v1.8 de `docs/focus-mode/spec.md` §4/§6/§7 non couverts par l'inventaire]
12. **`revues-jour` / `revues-semaine` / `revues-mois`** (1 écran, 3 modes ; formulaire guidé / structure `pending`/`completed` / pilotage personnel avec signalement « revue en retard ») [Screen Registry §A #14-16 §4.5.1]
13. **`analytics`** — 5 questions structurées (pas un dashboard de KPIs) ; c'est le dashboard Progress §18.6. [Screen Registry §A #17 §4.5.2 ; Surfaces §1 #11 `/progress`]
14. **`bibliotheque-ressources`** — centralise toute la matière (cours, PDF, docs, images, vidéos, liens, notes), rattachée et recherchable localement. [Screen Registry §A #18 §4.6.1 ; Surfaces §5 (variant desktop 30/70 liste/aperçu)]
15. **`cours-liste`** — liser les cours rattachés (par matière/semestre) avec progression et import de cours. [Screen Registry §A #19 §4.6.2 (1ʳᵉ composante de la paire)]
16. **`cours-detail`** — structure d'un cours (chapitres, concepts, formules `MathBlock`), vue agrégée par matière. [Screen Registry §A #20 §4.6.2 (2ᵉ composante)]
17. **`fiches-liste`** — consulter/générer des fiches de révision intelligentes et fidèles au corpus. [Screen Registry §A #21 §4.7.1 (1ʳᵉ composante de la paire)]
18. **`fiches-detail`** — une fiche par blocs (définitions, formules, méthodes, pièges, relations), `SourceRef` par bloc. [Screen Registry §A #22 §4.7.1 (2ᵉ composante)]
19. **`flashcards`** — session de révision espacée FSRS ; file locale de cartes dues, auto-évaluation qui alimente `SkillState`/`ProgressEvidence`. [Screen Registry §A #23 §4.8.1 ; Surfaces §1 #8 `Flashcards/QCM/Exercices`]
20. **`qcm`** — tester la compréhension : QCM généré par l'agent serveur, exécuté séquentiellement, résultat = `ProgressEvidence`. [Screen Registry §A #24 §4.8.2 ; Surfaces §1 #8 `Flashcards/QCM/Exercices`]
21. **`mode-coach`** — coaching adaptatif du kernel (check-ins contextuels courts, actions proposées, réglages du coaching, désactivation du jour). [Screen Registry §A #25 §4.9.1 ; Surfaces §2 #17 (compteur 17)]
22. **`mirror-cognitive`** — l'étudiante explique ce qu'elle a compris (texte/vocal), le kernel analyse et affiche lacunes/contradictions/erreurs. [Screen Registry §A #26 §4.9.2]
23. **`/inbox`** — capture universelle et triage vers tasks/learn/settings, draft Tiptap persisté. [Screen Registry §A #35 ; Surfaces §1 #2 ; Critique C1 : **présente dans la matrice 15 mais ABSENTE du registre 19** (pointeur `extract-05-section4-screens.md` L19)]
24. **`/tasks/:id`** (overlay de détail) — sous-tâches, matrice Eisenhower (vue en contenu, **pas** l'écran quadrant), focus CTA. [Surfaces §1 #3 ; Critique G1 : le quadrant d'Eisenhower lui-même n'est jamais listé dans l'inventaire]
25. **`/learn` (+ overlays)** — cours → chapitres → fiches/QCM/flashcards/miroir ; position de cours persistée. [Surfaces §1 #7]
26. **`/knowledge` (+ `/knowledge/:nodeId`)** — arbre sémantique, provenance, « study » (branche vide = CTA import). [Surfaces §1 #9]
27. **Discovery (feed)** — feed de découverte, sheets → « work on this ». [Surfaces §1 #10 ; Critique G3 : l'écran de **sheet de découverte** lui-même n'est dans aucun registre]
28. **`/artifacts/:id`** — preview par format → source/download/share (jamais de preview factice). [Surfaces §1 #13]
29. **`/agent`** — dialogue → confirmations d'actions → écrans cibles (conversation locale). [Screen Registry §A #33 ; Surfaces §1 #14]
30. **`/settings`** — thème + preview, fenêtres de silence, préférences de notifications, compte. [Screen Registry §A #35 ; Surfaces §1 #15 ; Critique C1 : **présente dans la matrice 15 mais ABSENTE du registre 19** (pointeur `extract-05-section4-screens.md` L19)]
31. **Command Palette** — overlay global (pas une route), 5 points d'entrée (UI button · command palette · trigger NL agent · deep link · automatisation Intégrations/Cron→jobs) ; exemples `task.create`, `focus.start`, `discovery.research`. [EXPERIENCE.md §Interaction Primitives ; feature-registry.md §4]

### B. Surfaces référencées sans section propre (Screen Registry §A #27–35, flag discrepancy)

32. **`taches-liste` / `taches-detail`** — référencées §4.3.1 & §4.7.1, slug non défini en §4. [Screen Registry §A #27 ; Surfaces §6]
33. **`timeline-gantt`** — référencé §3.6.4 (une liste de `GanttRow`). [Screen Registry §A #28]
34. **`arbre-semantique`** — référencé §4.6.2 (« l'écran dédié = `arbre-semantique`, §4.7.1.3 »). [Screen Registry §A #30 ; Surfaces §6 (pointeur `extract-05-section4-screens.md`)]
35. **`decouverte-feed`** — référencé §4.1.2 (7ᵉ bloc → `decouverte-feed` §4.5.2). [Screen Registry §A #31 ; Surfaces §6]
36. **`artefacts-detail`** — référencé §4.3.2 (« un document → `artefacts-detail` §4.6.1 »). [Screen Registry §A #32 ; Surfaces §6]
37. **`progress-dashboard`** — référencé §4.5.2 (dashboard §18.6). [Screen Registry §A #34]
38. **`exercises`** (route Learning `/exercises/:id`) — nommée seulement dans la section « Surfaces référencées mais non détaillées » de l'inventaire des surfaces ; absorbée dans la ligne composite « Flashcards/QCM/Exercices » de la matrice 15. [Surfaces §6 ; Critique G2 : `docs/frontend/module-ownership-matrix.md` L39]

### C. Surfaces ajoutées par la critique (G1–G3, non comptées dans 15/17/19/44)

39. **Vue/matrice Eisenhower (4 quadrants)** — surface réelle, absente de toutes les sections de l'inventaire ; `productivity.eisenhower` = « UI = quadrant screen **additive to 05 inventory** », NEEDS_DECISION avant le wave-2 cut. [Critique G1 ; sources primaires : `docs/productivity/eisenhower.md` §4, `docs/architecture/coverage-matrix.md` L33, `docs/architecture/gap-register.md` L40, `docs/features/master-feature-catalog.md` L20]
40. **Sheet de découverte** (detail d'un item du feed) — chaque item → discovery sheet (7+ champs typés, ADR §13.8) → activité d'apprentissage ou projet (13.9). [Critique G3 ; sources primaires : `docs/discovery/overview.md` §4, `adr-extract.md` §13.8]

**Variantes desktop nommées (non comptées, surcharges de la même surface)** — [Surfaces §5, source `EXPERIENCE.md` §Responsive & Platform, figées doc §23.2] :
- `projets-liste` (desktop 2 colonnes)
- `calendrier-*` (semaine 7×24h)
- `bibliotheque-ressources` (30/70 liste/aperçu, Sidebar remplace BottomNav)
- `habitudes` (heatmap 12 sem. desktop vs 7 mobile)

**Surfaces citées mais hors matrice de pages** [inventaire Surfaces §7] — pointeurs exacts :
- `02-frontend.md` §5 — 5 contrats de visualisation consommés (surfaces de rendu, pas de pages) : `SemanticTreeRenderer`, `InfographicRenderer`, `DataVisualizationRenderer` (G2, instanciation `focusBilan`), `MathRenderer` (KaTeX), `AnimationController` (motion).
- `04-mobile.md` §3.2 — surfaces d'adapters (non visibles à l'utilisateur, contrats de la couche) : `AppLifecycleAdapter`, `LocalFileStorageAdapter`, `DocumentScanner`/`OCRProvider`, `AudioArtifactProvider`/`TranscriptionProvider`, `RemoteNotificationAdapter` (OneSignal) + `LocalNotificationAdapter`, `NetworkStatusAdapter`.
- `04-mobile.md` §4.1/§4.2 — capacité Focus « promise » (timer, réduction notifs, bilan `FocusSessionBilan` + `ChartSpec` G2) : l'écran de bilan = 05 §4.4.2 (non lu).

**Total (verbatim, non réconcilié)** : liste de surfaces citées distinctes = **34** (15 + 2 + 2 + 6 + 11, hors variantes desktop §5 et « à tracer » §6) — source : inventaire des surfaces « Compté (surfaces nommées dans les sources lues, sans double-comptage des variantes §5 ni des « à tracer » §6) ». Cette liste fusionnée ci-dessus **inclut** les 7 surfaces référencées-sans-section (§B) et les 2 additions de la critique (§C) pour les besoins du pont, ce qui la place au-dessus de 34 par design — aucune réconciliation silencieuse ; voir section « Discrepancies de comptes ».

---

## États & modes produits

**5 états UX canoniques** (verbatim de `EXPERIENCE.md` frontmatter « 5 états » et `05-design-system.md` §3 intro — concordance 5 = 5 = 5, inventaire cross-cutting §A) :

| État | But | Source (inventaire cross-cutting §A) |
|---|---|---|
| `loading` (A1) | Chargement : skeleton du DS, ~300 ms max, jamais de blanc plein | `EXPERIENCE.md` §State Patterns ; `05-design-system.md` §3.6.10 / matrice AD-13 §3.7 |
| `empty` (A2) | Vide **actionnable** (CTA), jamais un vide mort | `EXPERIENCE.md` §State Patterns ; `05-design-system.md` §3.6.10, §3.1 |
| `success` (A3) | Confirmation brève (toast/inline) ; un `JobCompleted` ne surface que si l'app a filtré par `jobId`/`jobKind` | `EXPERIENCE.md` §State Patterns |
| `error` (A4) | Message lisible (pas de stack), **retry** toujours disponible, différenciation erreurs réseau/AI vs métier | `EXPERIENCE.md` §State Patterns ; `feature-registry.md` §6 |
| `offline` (A5) | Bannière fine, l'app **fonctionne** (AD-7 : offline = état premier) ; actions cloud désactivées **avec explicatif**, pas masquées | `EXPERIENCE.md` §State Patterns ; `05-design-system.md` §3.6.10, matrice AD-13 ; `feature-registry.md` §1 `offlineClass` |

**Sous-état tué** : `killed` (A6) — sous-état de `loading`, reboot/kill mid-chain = re-lecture depuis les IDs de l'URL + drafts persistés, pas un crash ; G-M2 wave 0 ; **unique à `EXPERIENCE.md`**, absent de `05-design-system.md` et de `feature-registry.md`. [inventaire cross-cutting §A A6]

**États intermédiaires déclarés (4)** : `hover` (A7 — Phase 2 Electron, inopérant sur Android), `pressed` (A8 — micro-interaction d'appui), `focus` (A9 — anneau de focus 2px `focus-ring`), `disabled` (A10 — fond `surface-alt`, texte `text-disabled`). [inventaire cross-cutting §A, concordance `EXPERIENCE.md` ↔ matrice AD-13 de `05-design-system.md`]

**Machine d'états Focus (interne, non confondu avec l'état UX canonique)** : `scheduled → starting → prechecking → active (blocking|restricted) → paused → ending → completed` + `active → interrupted → restoring → restored` + `any → failed (restore-scheduled)` ; en UI le seul `loading` = le **bilan** de fin (Skeleton) ; `empty` n'existe pas ; `error` = `Callout danger` sous le timer, le timer **continue**. [inventaire cross-cutting §A « Focus Mode » ; `05-design-system.md` §3.6.9 `FocusTimer` + §2.6 règle 3] — **Note critique T1** : `docs/focus-mode/spec.md` v1.8 (§4/§6/§7) étend cette machine (verdicts par capacité, blocking = device-owner only, G-P1) mais n'est cité par aucun inventaire.

**États de registry (FeatureDescriptor)** (B1–B3) : `available` / `recommended` / `locked` / `deprecated` (4 états de cycle de vie, distincts de `enabled`/`visible` ; un feature `deprecated` rend + stocke toujours ses données), champs `enabled`/`visible` (2 axes, se composent avec `state`), axe `offlineClass` (`offline-capable` / `online-required` / `hybrid`). [inventaire cross-cutting §B, concordance `feature-registry.md` §1 ↔ `EXPERIENCE.md` S1]

**Effets de désactivation (8)** (C1–C8) : nav / shortcut / agent / dashboard / jobs / notifications / data / deep links — aucun ne touche les données ; réactivation inverse, instantanée, sans migration. [inventaire cross-cutting §C, concordance `feature-registry.md` §6 (table 8 lignes) ↔ `EXPERIENCE.md` S6 (liste 8 items) — concordance 8 = 8] — **Note critique T3** : `docs/frontend/feature-registry.md` L46/L267 traduit l'effet par « widgets, dashboards, suggestions all filter on enabled » — divergence terminologique avec l'effet « shortcut/slots AD-14 » de `EXPERIENCE.md` S6 (flag, pas de nouvelle surface).

**6 modes produit** (D1–D6) (profil nommé sur les registries, déclaré dans `UserContext` AD-15, appliqué par la politique de disponibilité — « modes = profils nommés, pas 5 apps ») :

| # | Mode | Réglage (verbatim, inventaire cross-cutting §D) |
|---|---|---|
| D1 | **Core** | Productivity + Knowledge + Agent core ; Learning/Discovery dé-emphasés |
| D2 | **Study** | Learning + Progress + Focus + Calendar en avant ; Discovery/Projects minimisés (données intègres) |
| D3 | **Exam period** | Learning/Progress/Focus/Calendar devant ; Discovery/Projects/Analytics minimisés ; profil **déclaré** dans le contexte, pas un check utilisateur |
| D4 | **Focus-heavy** | Cadence Focus en hausse, suppression de notifs élargie (focus spec §8), slots Home re-pondérés (re-résolution AD-14) |
| D5 | **Professional** | Goals/Projects/Progress (dimension pro, ADR §18.2) devant ; features exam dé-emphasées |
| D6 | **Minimal** | Inbox + Tasks + Calendar seulement ; le reste masqué-mais-préservé |

Source : `feature-registry.md` §7 (table 6 lignes) + `EXPERIENCE.md` S7 (liste 6 items). **Flag critique C4** : le titre de `feature-registry.md` §7 dit « five faces » mais la table en a 6 — le compteur de la table (6) fait autorité, confirmé par le frontmatter de `EXPERIENCE.md` (« 6 product modes »). [inventaire cross-cutting §D note]

---

## Boucles & parcours nommés

22 parcours/boucles nommés (total de l'inventaire des parcours) : 5 parcours nommés de `EXPERIENCE.md` §Key Flows + Command Palette + 8 effets de désactivation + 6 modes = 8 items ; 10 items de l'`adr-extract.md` ; 4 items de `discovery-gap-pipeline.md`.

| # | Nom | Séquence de surfaces/états | Source |
|---|---|---|---|
| 1 | **Capture → triage** | CTA « Capture this » (tout écran) → `/inbox` (draft Tiptap persisté) → triage vers tasks/learn/settings | EXPERIENCE.md §Key Flows item 1 ; §Information Architecture L111 |
| 2 | **Agent-triggered navigation (AGT)** | Coach/Planner/Tutor/Executor → AGT → `/agent` ou `/tasks/:id` ou flashcards ciblées ; deep link OneSignal → `:id` du feature owner | EXPERIENCE.md §Key Flows item 2 ; §Information Architecture L115-118 |
| 3 | **Learning loop** | Home bloc 5 (« 12 révisions dues ») → flashcards → `SkillStateChanged` (AD-9) → `ProgressEvidence` (F-07) → `/progress` | EXPERIENCE.md §Key Flows item 3 |
| 4 | **Focus session** | Home bloc 6 « Démarrer le Focus » (ou /tasks/:id, ou Agent) → timer ring → bilan (ChartSpec G2) → Focus « terminé » | EXPERIENCE.md §Key Flows item 4 ; §State Patterns (Focus Mode states) |
| 5 | **Return destination** | back natif + « close overlay » → la page d'origine revient dans son état sauvegardé (scroll, filtres, branches ouvertes) | EXPERIENCE.md §Key Flows item 5 ; §Information Architecture invariants S6.2 L60-64 |
| 6 | **Boucle globale Aurora (10 étapes)** | Capture → Organize → Plan → Execute → Learn → Discover → Practice → Progress → Self-Improve → Adapt → Review | adr-extract.md §19 (sur-ensemble du cycle de productivité §2, qui ajoute Discover, Self-Improve et Progress explicites) |
| 7 | **Sous-cycle Discovery → Learning → Self-Improvement** | Discovery (trouve info/compétence) → Learning (compréhension + maîtrise) → Practice (vérifie application) → Progress (mesure évolution) → Self-Improvement (apprend ce qui a fonctionné) → l'agent personnalise les prochaines découvertes/séances/plans | adr-extract.md §15 v1.7 L424-431 |
| 8 | **Orchestration agentique (9 étapes)** | Comprendre l'intention → Récupérer le contexte personnel → Identifier contraintes/échéances/dépendances/charge → Choisir les capacités → Construire un plan → Demander confirmation (actions importantes/irréversibles) → Exécuter les actions autorisées → Vérifier le résultat → Enregistrer progression + état → Proposer une adaptation/prochaine action | adr-extract.md §5 (§123 : l'utilisateur ne choisit pas manuellement un module) |
| 9 | **Boucle de découverte (10 étapes)** | Observer profil/contexte → Identifier besoin/lacune/curiosité/changement → Lancer recherche multi-source → Comparer et qualifier → Sélectionner découvertes à forte utilité → Expliquer à l'utilisatrice → Relier au savoir existant → Créer éventuellement activité d'apprentissage/projet → Mesurer ce qui a été compris/appliqué/ignoré → Améliorer les prochaines recommandations | adr-extract.md §13.9 |
| 10 | **Noyau agentique (9 étapes, v1.6 §8)** | Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory | adr-extract.md v1.6 §8 « Architecture agentique figée » |
| 11 | **Systemic Synergy Loop (5 étapes, autonome)** | DISCOVERY détecte un gap (objet `Gap` + `DiscoveryItemCreated` AD-9) → KNOWLEDGE insère le gap dans l'arbre (`semantic_tree_version++`) → LEARNING propose une explication visuelle ciblée (infographie AntV+KaTeX) → PRACTICE génère un problème concret (Scientific Engine, vérification déterministe) → PROGRESS capture la preuve (`ProgressEvidenceCreated` F-07) → `NodeState` not_started→mastered → Self-Improvement → Discovery lance le gap suivant ; les étapes intermédiaires sont invisibles à l'utilisateur | discovery-gap-pipeline.md §3 |
| 12 | **Pipeline de Gap Analysis** | Corpus Universitaire (Cours BA/RDM/Hydraul.) → Arbre Sémantique (Savoir réel de Horeb) → Identification de l'écart technique → Discovery Multi-Source → Matrice d'Écarts (Gap objects) → Plan d'ouverture (Learning + Practice) | discovery-gap-pipeline.md §1 |
| 13 | **Ingestion Multi-Source (5 sources typées)** | Bureaux d'études → Rapports de chantiers → Evolutions normatives (Eurocode, BAEL, normes locales Bénin) → International excellence (FEMA, ASCE) → Local practices (BEN : matériaux, climat, méthodes) ; résultats typés FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY (ADR S13.7) | discovery-gap-pipeline.md §1.1 |
| 14 | **Discovery Filtering Policy (Bénin, 3 règles data-driven)** | DOMAIN MATCH → INFRASTRUCTURE REALITY → CAREER RELEVANCE → DiscoveryItem (FACT/TREND) + mise à jour du Gap si pertinent ; sinon « Noted but not actionable » ; incertitude → status `UNCERTAINTY` + question à l'utilisateur | discovery-gap-pipeline.md §5 |
| 15 | **Pipeline audio (optionnel)** | Audio Artifact → TranscriptionProvider (optionnel) → Transcript → Segmentation → Concepts → Knowledge Base → Semantic Tree → Learning/Progress ; traitements lourds asynchrones, persistés comme Jobs | adr-extract.md v1.6 §Nouveaux composants L791 |
| 16 | **Pipeline du document scanner** | caméra → scan de pages → OCR → structuration → Knowledge Base → extraction des définitions/formules → apprentissage | adr-extract.md v1.6 §Nouveaux composants L785 |
| 17 | **Command Palette (capacité à 5 points d'entrée)** | bouton UI · palette de commandes · trigger NL agent · deep link · automatisation (Intégrations/Cron → jobs) — tous résolvent la même use-case/capacité du capability registry ; overlay, pas une route (invariant S6.2 L65-66) | EXPERIENCE.md §Interaction Primitives ; §Information Architecture |
| 18 | **Flux agentique de génération visuelle (7 étapes)** | Intent (identifier ce que l'utilisatrice cherche à comprendre) → Context (cours, sources, niveau, connaissances déjà maîtrisées, Progress) → Structure (arbre/infographie/graphique/formule/combo) → Content validation (sources, définitions, formules) → Render (moteur adapté) → Explain (explication progressive) → Interact (zoom/sélection/révélation/comparaison/exercice) → Evidence (enregistrer ce qui a été compris/appliqué, alimenter Progress) | adr-extract.md §25.11 |
| 19 | **Cycle global de productivité (7 étapes)** | Capturer → Organiser → Planifier → Exécuter → Suivre → Réviser → Améliorer | adr-extract.md §2 |
| 20 | **Flux des 8 effets de désactivation (chaîne S2)** | nav → shortcut → agent → dashboard → jobs → notifications → data → deep links (détails complets dans la section États & modes, C1–C8) | EXPERIENCE.md §Feature Registry & Product Modes S6 |
| 21 | **6 product modes (profiles nommés)** | Core / Study / Exam period / Focus-heavy / Professional / Minimal (détails complets dans la section États & modes, D1–D6) | EXPERIENCE.md §Feature Registry & Product Modes S7 |
| 22 | **Exemples de parcours nommés (§6)** | Planification (cours + échéances + temps disponible → planning réaliste avec priorités + time blocking) ; Blocage (rapport n'avance pas → analyse tâches/dépendances/reports/temps → prochaine action concrète) ; Apprentissage (notion incomprise → récupération du cours → explication → questionnement en rappel actif → QCM ou flashcards) ; Progression (objectif professionnel → compétences/ressources/exercices/projets/habitudes/points de contrôle) ; Recherche (recherche web → collecte des sources → synthèse → transformation en ressources/artefacts) | adr-extract.md §6 |

---

## Discrepancies de comptes

**Tout conflit de comptes est marqué UNRECONCILED — recommandé : à résoudre au standup de la wave-0, pas de choix silencieusement effectué.**

- **15 vs 17 vs 19** (verbatim, inventaire Screen Registry §D + inventaire des surfaces §1) :
  - **15** = matrice mobile `pack-02:S6` (`docs/mobile/navigation-and-page-composition.md` §2, 15 lignes de table ; reprise en 15 lignes dans `EXPERIENCE.md` §Information Architecture « Les 15 pages »).
  - **17** = « plan de vagues » = 15 + `onboarding` + `mode-coach` (verbatim, `EXPERIENCE.md`, note de compteur sous le tableau 15 pages).
  - **19** = Screen Registry `pack-05:S4` = 17 + `habitudes` + `routines` (verbatim, `EXPERIENCE.md` §Information Architecture L91-98 « **19 surfaces** (incluant `onboarding`, `habitudes`, `routines`, `revues-*`, `analytics`, `bibliotheque-ressources`, `cours-*`, `fiches-*`, `flashcards`, `qcm`, `mode-coach`, `mirror-cognitive`) » + `.working/extract-05-section4-screens.md` « Total surfaces : 19 »).
  - **UNRECONCILED** : l'inventaire des surfaces §B/C/D se revendique « 15 ⊂ 17 ⊂ 19 » ; la critique **C1** réfute cette inclusion : `inbox` et `settings` sont dans la matrice 15 mais **ABSENTES** du registre 19 (pointeur : `extract-05-section4-screens.md` L19, tableau de 19 lignes sans `inbox`/`settings`). **Recommandation : résolution au standup de wave-0 (pas de choix silencieusement effectué)**.
- **44 (compteur canonique du frontmatter du pack 05)** : le frontmatter de `05-design-system.md` déclare « l'**inventaire écran par écran** (44 écrans, doc §2–§18 + §13 + §18) » ; les sections §4.x visibles ne nomment que **26** entrées (§4.1.1–§4.1.2, §4.3.1–§4.3.6, §4.4.1–§4.4.2, §4.5.1–§4.5.2, §4.6.1–§4.6.2, §4.7.1, §4.8.1–§4.8.2, §4.9.1–§4.9.2) ; les 10 slugs référencés sans section propre (§B de l'inventaire : `taches-liste`, `taches-detail`, `timeline-gantt`, `arbre-semantique`, `decouverte-feed`, `artefacts-detail`, `agent`, `progress-dashboard`, `inbox`, `settings`) comblent l'écart 44 vs 26 mais **la liste des 44 n'a jamais été produite en entier** ; l'écart de **25** entre 44 et 19 reste non expliqué ligne par ligne. **Critique C2** : le §4.2 n'existe pas (saut de 4.1 à 4.3). **UNRECONCILED**. **Recommandation : résolution au standup de wave-0 (pas de choix silencieusement effectué)**.
- **19 sous-compté par rapport à la règle de variante du §4** : **Critique C3** — `05-design-system.md` L1246-1247 stipule « La variante (liste + détail) est traitée **séparément** pour chaque paire », ce qui ferait compter `cours-*`, `fiches-*`, `objectifs-*`, `calendrier-*`, `revues-*` chacun double, en portant le total au-dessus de 19 ; la règle de comptage « 19 » (composants groupés) n'est pas spécifiée dans l'extract. **UNRECONCILED**. **Recommandation : résolution au standup de wave-0 (pas de choix silencieusement effectué)**.
- **`feature-registry.md` §7 — 6 vs 5** : le titre dit « five faces » mais la table en a 6 (Core/Study/Exam period/Focus-heavy/Professional/Minimal). **Critique C4** (déjà flaguée dans l'inventaire cross-cutting §D note) : le compteur de la table (6) fait autorité, confirmé par `EXPERIENCE.md` frontmatter « 6 product modes ». **Non résolu par guessing** — recommandé : résoudre au standup de wave-0 en alignant le titre de la section sur la table (6 modes). **UNRECONCILED**.
- **`exercises`** (route `/exercises/:id`) : nommée seulement dans la section « Surfaces référencées mais non détaillées » de l'inventaire des surfaces (pointeur `extract-05-section4-screens.md` L50) ; **Critique G2** confirme qu'elle n'apparaît dans aucun registre (ni 15, ni 19, ni 44) — la matrice 15 l'absorbe dans « Flashcards/QCM/Exercices » (1 surface composite). **À trancher : à compter comme une surface distincte, ou à réconcilier avec le compteur 19 — UNRECONCILED, résolution au standup de wave-0 (pas de choix silencieusement effectué)**.
- **Surface additive `productivity.eisenhower` (critique G1)** : « UI = quadrant screen **additive to 05 inventory** », NEEDS_DECISION — non comptée dans 15/17/19/44 ; **critique G3** : le sheet de découverte (detail d'un item du feed) est dans aucun registre. **UNRECONCILED**. **Recommandation : résolution au standup de wave-0 (pas de choix silencieusement effectué)**.

---

## Gaps (critique)

Les ajouts et remarques du critique (verdict FAIL), avec pointeurs exacts :

**G1. Vue/matrice Eisenhower (4 quadrants) — surface réelle, absente de toutes les sections de l'inventaire.**
*Source : `docs/productivity/eisenhower.md` §4 User flows — « success (4-quadrant grid, 44px items) », entrée « project screen Matrix tab (proposed G-DOC-05) » ; confirmé par `docs/architecture/coverage-matrix.md` L33 (G-L5 : « quadrant screen not in 05 inventory »), `docs/architecture/gap-register.md` L40 (G-L5), `docs/features/master-feature-catalog.md` L20 (`productivity.eisenhower` — « UI = quadrant screen **additive to 05 inventory** », NEEDS_DECISION).* L'inventaire cite « Eisenhower » uniquement comme contenu du detail overlay des Tâches (`EXPERIENCE.md` §15-pages L77 ; §6.2) mais ne liste jamais l'écran quadrant lui-même. **Statut : surface additive documentée avec ratification pendante avant le wave-2 cut — à ajouter explicitement à l'inventaire comme G-L5 (non compté dans 15/17/19/44).**

**G2. `exercises` (`/exercises/:id`) — surface réelle, partiellement couverte.**
*Source : `docs/frontend/module-ownership-matrix.md` L39 — routes Learning incluant `/exercises/:id`.* L'inventaire la nomme seulement dans sa section 6 « Surfaces référencées mais non détaillées » (pointeur `extract-05-section4-screens.md` L50) — elle n'apparaît dans aucun registre (ni 15, ni 19, ni 44) ; la matrice 15 pages l'absorbe dans « Flashcards/QCM/Exercices » (1 surface composite). **À tracer comme surface distincte ou à réconcilier avec le compteur 19.**

**G3. Vue de détails d'une fiche de découverte (sheet) — surface réelle, implicite.**
*Source : `docs/discovery/overview.md` §4 « User flows » — « each item → discovery sheet → optional learning activity or project (13.9) » ; ADR §13.8 décrit le contenu de la sheet (7+ champs typés).* L'inventaire ne liste que le *feed* Discovery (15 pages L10) et dit « sheets → work on this » ; l'écran de sheet lui-même n'est dans aucun registre.

**T1. États v1.8 de la session Focus (machine étendue) — absent de l'inventaire combiné.**
`docs/focus-mode/spec.md` §4 (Session lifecycle), §6 (Session state), §7 (Restoration discipline) + §0 Decision record v1.8 : états supplémentaires « scheduled/starting/prechecking/active(blocking|restricted)/paused/ending/completed » + « interrupted/failed (restore-scheduled) » et verdicts par capacité (blocking = device-owner only, G-P1). Aucun des 4 inventaires repris par l'agent ne cite le focus-spec v1.8 — il n'ajoute pas de surface mais son machine d'états complète celle de l'inventaire cross-cutting qui ne cite que les états du pack 05.

**T2. 49 paires thème × écran = livrables UI manquants.**
`05-design-system.md` §5.7.2 (L3153-3157) + §7.2 (L3286) : les 49 mockups restants sont un livrable de vague 0 (ADR §22) — artefacts de surface, pas une page, mais hors périmètre de l'inventaire actuel.

**T3. « widgets (Home slots) » comme effet de désactivation.**
`docs/frontend/feature-registry.md` L46 et L267 (« widgets, dashboards, suggestions all filter on enabled »). La Cross-cutting inventory cite 8 effets (S6) ; le « widgets » de `EXPERIENCE.md` S6 est traduit par « shortcut/slots AD-14 » — la terminologie diverge entre les deux sources (flag, pas de nouvelle surface).

**C1. Erreur factuelle : « 15 n'est pas dans 17/19 » est FAUX** (déjà flagué dans la section Discrepancies de comptes) : `inbox` et `settings` sont dans la matrice 15 mais ABSENTES des 19 du Screen Registry (pointeur `extract-05-section4-screens.md` L19).

**C2. 44 vs 26 : la liste des 44 n'est pas produite** (déjà flagué dans la section Discrepancies de comptes) ; le §4.2 n'existe pas (saut de 4.1 à 4.3) ; écart de 18 non explicable ligne par ligne.

**C3. « Total surfaces : 19 » est sous-compté par rapport à la règle de variante du §4** (déjà flagué dans la section Discrepancies de comptes) : `05-design-system.md` L1246-1247 impose « La variante (liste + détail) est traitée **séparément** pour chaque paire » ; la règle de comptage « 19 » (composants groupés) n'est pas spécifiée dans l'extract.

**C4. « six modes / five faces »** (déjà flagué dans la section Discrepancies de comptes) : le titre de `feature-registry.md` §7 dit « five faces » mais la table a 6 lignes. Réconciliation correcte : le compteur de la table (6) fait autorité, confirmé par `EXPERIENCE.md` frontmatter « 6 product modes ».

---

## Recommandations de stratégie d'échelle

**Bande de page-count (selon le skill WDS Phase 3, `step-02-analyze-scope.md` §3) :**

Le compteur de référence pour l'analyse d'échelle est **19 surfaces** (Screen Registry canonique, SSoT : `05-design-system.md` §4 ; le frontmatter du pack 05 et les comptages « Les 15 pages » / « 17 pages » / « 44 » étant des sous-listes ou des compteurs non confirmés — voir section Discrepancies de comptes, UNRECONCILED). La liste fusionnée ci-dessus (40 entrées comptant variantes desktop + références sans section + additions critique) est un index de pont, pas un compteur d'échelle.

| Seuil (skill) | Critère | Verdict Aurora |
|---|---|---|
| **Small (< 20 pages)** | Couverture complète — tout les pages documentées dans les scénarios ; Mode Dream ou Suggest ; chaque page apparaît dans exactement un scénario | ✅ **Aurora tombe dans cette bande** : 19 surfaces Screen Registry < 20. (15 pages matrice < 19 ; le « 44 » frontmatter est non confirmé / non listé ligne-par-ligne → UNRECONCILED, ne change pas la bande tant que la résolution du standup de wave-0 n'élève pas le compteur à ≥ 20.) |

**Recommandation : Mode = Suggest** (non Dream) — le compteur 19 est juste au-dessus de la ligne « petite » pour s'en sortir : le mode Dream conviendrait à < 20 avec couverture exhaustive, mais les discrepancies non résolues de 44 vs 26 (UNRECONCILED, critique C2) et les ajouts additive de la critique (G1/G3) ajoutent de l'incertitude au périmètre réel ; le mode Suggest conserve la flexibilité de couvrir les pages en sous-groupes « naturelles » plutôt qu'une couverture exhaustive de chaque page dans exactement un scénario.

**Page-stratégie (individuel vs template-avec-variantes, `step-02-analyze-scope.md` §4) :**

- **Pages individualisées (variante haute)** : `welcome/home` (AD-14, surface signature), `onboarding`, `mode-coach`, `mirror-cognitive`, `analytics`, `projets-detail`, `objectifs-detail`, `cours-detail`, `fiches-detail` — structure/contentement/spécialisation substantiellement différents.
- **Templates avec variantes (variante basse)** :
  - **calendrier-{jour,semaine,mois}** — 3 modes du même écran, composant partagé `Pager` (pointeur : inventaire Screen Registry §A #10-12, §4.4.1).
  - **revues-{jour,semaine,mois}** — 3 modes du même écran (pointeur : inventaire Screen Registry §A #14-16, §4.5.1).
  - **Surfaces variantes desktop nommées** (pointeur : inventaire des surfaces §5, source `EXPERIENCE.md` §Responsive & Platform, figées doc §23.2) : `projets-liste` (desktop 2 colonnes), `calendrier-*` (semaine 7×24h), `bibliotheque-ressources` (30/70 liste/aperçu, Sidebar remplace BottomNav), `habitudes` (heatmap 12 sem. desktop vs 7 mobile) — ce sont des variantes par-device de la même surface de base, pas des pages distinctes.
- **Groupe « pairs » de détail** (règle critique C3 : variante compte séparée par paire) : `cours-*`, `fiches-*`, `objectifs-*` — si la résolution du standup de wave-0 applique la règle de comptage des variantes du §4, ce groupe monte de 3×2 à 6 entrées, changeant le compteur 19 → 21+ et **éventuellement repoussant Aurora dans la bande Medium** ; ce cas de figure est UNRECONCILED tant que la résolution n'est pas prise.

---

*Fin du rapport de pont. Le standup de wave-0 devra trancher : (a) le compteur canonical (44 frontmatter vs 19 Screen Registry vs 15 matrice vs 17 plan de vagues), (b) l'absence de `inbox`/`settings` dans le registre 19 (critique C1), (c) le comptage des paires (liste + détail séparé) — critique C3, (d) le « five faces » vs 6 modes — critique C4, (e) l'addition de `productivity.eisenhower` (G1) et du sheet de découverte (G3) au registre des surfaces.*
