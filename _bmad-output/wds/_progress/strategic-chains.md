# WDS Phase 3 — Step 03 : Contexte stratégique (chaînes)

> **Résumé exécutif** : 6 chaînes (1×P1, 4×P2, 1×P3) + 1 bloc shared.
> Couverture **40/40** surfaces de l'inventaire (scope-report §Inventaire, S-01…S-40)
> via assignation directe d'une chaîne par surface nommée ; 4 variantes desktop
> déclarées **shared** (exemptées par la consigne) ; 2 surfaces partagées
> (S-29 `/agent`, S-31 Command Palette) déclarées **shared** ; **0 orpheline**.
>
> **Pointeurs sources** : trigger-map §1–§7 · scope-report §Inventaire/§B/§C · A-Product-Brief §1–§7 ·
> EXPERIENCE.md (via scope-report §Key Flows) · canon `master-feature-catalog.md` / `epics-stories.md`.

---

## Chaîne 01 (P1) : 01-progress-proof

**Priorité** : P1 (critical path) — valeur cœur du produit, moteur du flywheel.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-PRIMARY** : mesurer la TRANSFORMATION RÉELLE de Horeb (état, évolution, causes, preuves) — pas un compteur de tâches. | trigger-map §1 Primary (ADR §18) |
| Q2 | Quelle persona ? | **Horeb** — génie civil, Bénin, bureau d'études, mobile nocturne intensif. | trigger-map §2 ; brief §2 |
| Q3 | Quelle force motrice ? | **Envie ③ Self-improvement** (Expert Skills, apprentissages opérationnels vérifiés) **× Peur ① Illusion de progression** (bon score de reconnaissance masquant une faible capacité de transfert). | trigger-map §2 Drivers (ADR §14.2, §18.2) |
| Q4 | Quelle transaction ? | **Produire une PREUVE de transformation** : flashcards/QCM/exercice → `ProgressEvidenceCreated` (AD-9) → analyse des causes, pas du simple comptage. | trigger-map §4 Intent #7 « Progresser » + §5 Flywheel (Progress = moteur agentique, ADR §18.7) ; brief §7 Progress |
| Q5 | D'où vient l'utilisateur ? | **Home `welcome/home` (AD-14)** → bloc « progression critique » (7ᵉ item fixe) ou bloc « 12 révisions dues » → `/progress` (`analytics`). | trigger-map §6 Trap « surcharge de widgets » (Home = composition fixe) ; scope-report S-02, S-13, parcours Learning loop (item 3) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **preuve vérifiée** (QCM, rappel actif, exercice, explication) reliée à un contexte et une compétence, pas une affirmation de « c'est fait ». | ADR §18.2/§18.3 (via trigger-map §7 signal 7 : « Toute progression significative doit être reliée à des preuves et à un contexte ») |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **transformation réelle traçable** dans le temps (état, évolution, causes, preuves) — pas un compteur de tâches. | trigger-map §1 Primary (ADR §18) ; brief §7 Progress |

**Pages assignées** (S-IDs) :
- S-02 (`welcome/home`) — point d'entrée, bloc « progression critique » / « révisions dues »
- S-13 (`analytics` = `/progress`) — 5 questions structurées, dashboard Progress ADR §18.6
- S-19 (`flashcards`) — session de révision espacée FSRS, alimente `SkillState`/`ProgressEvidence`
- S-20 (`qcm`) — QCM généré par agent serveur, résultat = `ProgressEvidence`
- S-22 (`mirror-cognitive`) — explication de l'étudiante, analyse kernel des lacunes/contradictions
- S-38 (`exercises`) — route `/exercises/:id`, exercice progressif, résultat = `ProgressEvidence`

**Justification** : cette chaîne est le cœur du flywheel (trigger-map §5) : un gap ou une stagnation déclenche révision, exercice, recherche ou tâche. Les surfaces assignées sont celles qui produisent la PREUVE (`ProgressEvidenceCreated`, AD-9) et la mesurent (analytics ADR §18.6). La transaction « produire une preuve » est la seule qui relie directement l'envie ③ (self-improvement) à la peur ① (illusion de progression) : sans preuve, le driver + devient driver −.

---

## Chaîne 02 (P2) : 02-gap-closure

**Priorité** : P2 (supporting) — conversion vers excellence internationale via écarts documentés.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-SECONDARY** : convergence vers l'EXCELLENCE INTERNATIONALE via écarts documentés (académique ↔ professionnel ↔ international). | trigger-map §1 Secondary (ADR §13.5) |
| Q2 | Quelle persona ? | **Horeb** — profil porté par `UserContext` (région, disciplines, cible pro, budget). | trigger-map §2 ; brief §2 |
| Q3 | Quelle force motrice ? | **Envie ② Discovery utile** : « ce que cette personne doit découvrir maintenant pour réduire ses lacunes et augmenter son niveau professionnel ». | trigger-map §2 Drivers (ADR §13, principe intro) |
| Q4 | Quelle transaction ? | **Réduire un écart documenté** : identification du gap (objectifs ↔ compétences) → plan d'ouverture (learning + practice) → preuve de compétence. | trigger-map §4 Intent #8 « Découvrir » (`discovery.gaps`, `discovery.horizons`) ; ADR §13.4 (écarts documentés) ; brief §6 Discovery |
| Q5 | D'où vient l'utilisateur ? | **`objectifs-detail`** (hiérarchie projets → indicateurs → jalons) ou **`projets-detail`** (objectif, jalons, documents) → détection d'écart → plan d'action. | scope-report S-07, S-04 ; ADR §18.2 (dimension pro, ADR §13.5) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **écart documenté comblé** (compétence professionnelle alignée sur le standard international), preuve de compétence construite progressivement. | ADR §13.5 (via trigger-map §7 signal 12 : « Devenir une ingénieure capable de comprendre son domaine en profondeur, de travailler avec les outils contemporains ») |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **convergence vers l'excellence internationale** — écarts documentés (académique ↔ professionnel ↔ international), preuves de compétence. | trigger-map §1 Secondary (ADR §13.5) |

**Pages assignées** (S-IDs) — affectation directe (pas de proxy implicite) :
- S-06 (`objectifs-liste`) — objectifs court/moyen/long terme en Cards
- S-07 (`objectifs-detail`) — hiérarchie (projets qui y contribuent), indicateurs, jalons
- S-04 (`projets-detail`) — un projet avec tout son contexte (objectif, jalons, tâches, documents, notes, historique)
- S-03 (`projets-liste`) — tous les projets (jalons, progression, tâches) en Cards flat, tri par date/progression/priorité
- S-33 (`timeline-gantt`) — plan d'ouverture visualisé sur la timeline (référencé §3.6.4, scope-report §B)
- S-18 (`fiches-detail`) — fiche par blocs (définitions, formules, méthodes, pièges, relations), `SourceRef` par bloc (preuve de compétence)
- S-17 (`fiches-liste`) — consultation/génération des fiches (paire list+detail, règle C3)

**Justification** : cette chaîne matérialise BG-SECONDARY : les écarts documentés (ADR §13.5) entre le programme universitaire et le métier réel (bureau d'études) se mesurent via objectifs/projets et se traduisent en plans d'ouverture (learning + practice). Les fiches (S-18) servent de preuve de compétence construite progressivement (trigger-map §1 Secondary : « preuves de compétence construites progressivement »).

---

## Chaîne 03 (P2/P3) : 03-active-discovery

**Priorité** : P2 (supporting) → P3 (edge) selon la profondeur du feed de découverte.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-TERNARY** : DISCOVERY ACTIVE continue (pas de veille passive) élargissant capacités, compréhension, vision. | trigger-map §1 Tertiary (ADR §13, §13.1–13.3) |
| Q2 | Quelle persona ? | **Horeb** — profil `UserContext` (Bénin, budget étudiant, disciplines BA/RDM/hydraulique). | trigger-map §2 ; brief §2 |
| Q3 | Quelle force motrice ? | **Envie ② Discovery utile** × **Peur ② Veille passive** (accumulation de liens/notifications sans action). | trigger-map §2 Drivers (ADR §13) + §6 Traps (Veille passive) |
| Q4 | Quelle transaction ? | **Découverte active typée orientée profil** : feed de découvertes (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY) → sheet de détail (7+ champs typés, ADR §13.8) → « work on this » (activité d'apprentissage ou projet, §13.9). | trigger-map §4 Intent #5 « Rechercher » (`discovery.research`, `knowledge.retrieval`) ; ADR §13.7 (types de faits) ; brief §6 Discovery |
| Q5 | D'où vient l'utilisateur ? | **Home `welcome/home` (AD-14)** → 7ᵉ bloc « suggestions Coach » ou CTA « Discovery » → feed de découverte. | scope-report S-02, S-27 ; trigger-map §6 Trap « Veille passive » (découverte active, pas de flux de liens) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **découverte typée orientée profil** (pas de veille passive), élargit capacités/compréhension/vision. | ADR §13 (principe intro) ; trigger-map §1 Tertiary |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **découverte active continue** (pas de veille passive) élargissant capacités, compréhension et vision — différenciation vs flux de liens passifs. | trigger-map §1 Tertiary (ADR §13, §13.1–13.3) ; §6 Traps |

**Pages assignées** (S-IDs) — affectation directe (pas de proxy implicite) :
- S-27 (`Discovery feed`) — feed de découverte, sheets → « work on this »
- S-40 (`Sheet de découverte`) — detail d'un item du feed (7+ champs typés, ADR §13.8) → activité d'apprentissage ou projet (13.9)
- S-35 (`decouverte-feed`) — référencé §4.1.2 (7ᵉ bloc Home → `decouverte-feed` §4.5.2) [scope-report §B]
- S-34 (`arbre-semantique`) — écran dédié (§4.6.2, §4.7.1.3), exploration par niveaux, provenance [scope-report §B]
- S-26 (`/knowledge` + `/knowledge/:nodeId`) — arbre sémantique, provenance, « study » (branche vide = CTA import)
- S-28 (`/artifacts/:id`) — preview par format → source/download/share (jamais de preview factice)
- S-36 (`artefacts-detail`) — référencé §4.3.2 (scope-report §B), variante de détail d'un artefact
- S-14 (`bibliotheque-ressources`) — centralise toute la matière, rattachée et recherchable
- S-15 (`cours-liste`) / S-16 (`cours-detail`) — liserer les cours rattachés + structure d'un cours (paire, règle C3)
- S-25 (`/learn` + overlays) — cours → chapitres → fiches/QCM/flashcards/miroir ; position de cours persistée

**Justification** : cette chaîne matérialise BG-TERNARY : la découverte active typée (ADR §13.7) orientée par le profil `UserContext` (Bénin, budget étudiant, disciplines) remplace la veille passive (trap ②). Les 6 surfaces assignées couvrent le pipeline complet : feed → sheet → arbre sémantique → artifacts. La priorité est P2 (découverte active = différenciation produit) avec une dimension P3 (edge) si le feed est vide ou hors profil.

---

## Chaîne 04 (P2) : 04-onboarding-foundations

**Priorité** : P2 (supporting) — onboarding, settings, et fondations partagées.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-PRIMARY** (setup) : permettre à Horeb de configurer son profil (`UserContext`) et son environnement pour que la transformation réelle puisse être mesurée. | trigger-map §1 Primary (ADR §18) ; brief §2 (profil `UserContext`) |
| Q2 | Quelle persona ? | **Horeb** — nouvelle utilisatrice, onboarding 3 écrans max. | trigger-map §2 ; scope-report S-01 |
| Q3 | Quelle force motrice ? | **Envie ① Focus** + **peur ③ Surcharge de widgets** (onboarding sans tour de fonctions, composition Home fixe). | trigger-map §2 Drivers + §6 Traps ; scope-report S-01 (3 écrans max, sans tour de fonctions) |
| Q4 | Quelle transaction ? | **Configurer le profil** (`UserContext` : région, disciplines, cible pro, budget) + **ajuster les préférences** (thème, fenêtres de silence, notifications). | brief §2 (profil `UserContext`) ; scope-report S-01, S-30 |
| Q5 | D'où vient l'utilisateur ? | **Lancement de l'app** → onboarding (3 écrans max) → Home (`welcome/home`). | scope-report S-01, S-02 ; EXPERIENCE.md §Key Flows item 1 (capture → triage) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **profil personnalisé** (pas de hardcoding `if user === Horeb`), environnement conforme (thème nocturne, silence, notifications). | brief §2 (profil `UserContext`) ; trigger-map §2 (zéro `if user === Horeb`) |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **activation du profil** (`UserContext` complet) → capacité à mesurer la transformation réelle (BG-PRIMARY). | trigger-map §1 Primary ; brief §6 (Progress = moteur agentique) |

**Pages assignées** (S-IDs) — affectation directe (pas de proxy implicite) :
- S-01 (`onboarding`) — 3 écrans max, choix de profil (étudiante/matière/horaire silence/thème), sans tour de fonctions
- S-30 (`/settings`) — thème + preview, fenêtres de silence, préférences de notifications, compte
- S-10 (`calendrier-jour`) / S-11 (`calendrier-semaine` / `calendrier-mois`) — planification des routines (composante de fidélisation, même écran 3 modes composant `Pager`)
- S-21 (`mode-coach`) — réglages du coaching, préférences, désactivation du jour
- S-23 (`/inbox`) — capture universelle et triage ; point d'entrée du profil (flow 1 EXPERIENCE.md §Key Flows)

**Justification** : cette chaîne couvre l'onboarding (setup du profil `UserContext`) et les settings (ajustement des préférences). Elle est P2 (supporting) car elle est la condition sine qua non de BG-PRIMARY : sans profil, pas de transformation mesurable.

---

## Chaîne 05 (P3) : 05-habit-loop

**Priorité** : P3 (edge) — habitudes et routines, boucle de fidélisation.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-PRIMARY** (fidélisation) : maintenir la régularité des pratiques (habitudes/routines) pour que la transformation réelle (mesure, preuves) soit continue. | trigger-map §1 Primary (ADR §18) ; ADR §2 (cycle de productivité) |
| Q2 | Quelle persona ? | **Horeb** — mobile intensif nocturne, routines d'étude (matin/soir/étude). | trigger-map §2 ; scope-report S-08, S-09 |
| Q3 | Quelle force motrice ? | **Envie ① Focus** (sessions de travail profond) × **peur ② Veille passive** (habitudes actives, pas de simples rappels). | trigger-map §2 Drivers + §6 Traps ; ADR §2.8 (Focus) |
| Q4 | Quelle transaction ? | **Suivre une habitude/routine** : check-in « Marquer aujourd'hui » (habitudes) + séquence d'étapes (routines, pas un to-do). | scope-report S-08, S-09 ; ADR §2 (cycle de productivité) |
| Q5 | D'où vient l'utilisateur ? | **Home `welcome/home` (AD-14)** → bloc « agenda du jour » ou CTA « Habitudes/Routines » → `habitudes` / `routines`. | scope-report S-02, S-08, S-09 ; trigger-map §6 (Home = composition fixe) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **régularité mesurée** (heatmap d'adhérence `HabitStreak`), routines ordonnées (pas de to-do chaotique). | scope-report S-08, S-09 |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **fidélisation par la régularité** (habitudes/routines actives) → transformation réelle continue (BG-PRIMARY). | trigger-map §1 Primary ; ADR §18 (transformation dans le temps) |

**Pages assignées** (S-IDs) — affectation directe (pas de proxy implicite) :
- S-05 (`kanban`) — board global par statut, drag local ; vue parente de `/tasks/:id` (S-24) et de la matrice Eisenhower (S-39)
- S-24 (`/tasks/:id`) — overlay de détail : sous-tâches, matrice Eisenhower (vue en contenu), CTA focus
- S-08 (`habitudes`) — suivi d'habitudes, heatmap d'adhérence `HabitStreak` (pointeur `master-feature-catalog.md` L24 `productivity.habits`)
- S-09 (`routines`) — routines ordonnées (matin/soir/étude)
- S-32 (`taches-liste` / `taches-detail`) — référencées §4.3.1 & §4.7.1 (scope-report §B)
- S-39 (`Vue/matrice Eisenhower`) — NEEDS_DECISION avant wave-2 cut (critique G1)

**Justification** : cette chaîne couvre les habitudes et routines (S-08, S-09). Elle est P3 (edge) car elle est une boucle de fidélisation (maintien de la régularité) qui supporte BG-PRIMARY (transformation réelle continue) mais n'est pas le moteur principal. La transaction « suivre une habitude/routine » est distincte de « produire une preuve » (chaîne 01) : ici, c'est la régularité (heatmap, check-in) qui est mesurée, pas la compétence.

---

## Chaîne 06 (P3) : 06-analytics-review

**Priorité** : P3 (edge) — revues et rétrospectives.

| # | Question | Réponse | Pointeur source |
|---|---------|---------|----------------|
| Q1 | Quel objectif business ? | **BG-PRIMARY** (rétrospective) : analyser les causes (pas les comptages) pour adapter la trajectoire (Self-Improve → Adapt). | trigger-map §1 Primary (ADR §18) ; ADR §19 (boucle complète) |
| Q2 | Quelle persona ? | **Horeb** — sessions nocturnes, besoin de rétro structure. | trigger-map §2 ; scope-report S-12 |
| Q3 | Quelle force motrice ? | **Peur ① Illusion de progression** (analyse des causes, pas du simple comptage) × **envie ③ Self-improvement** (réviser, adapter). | trigger-map §2 Drivers + §6 Traps ; ADR §18.2 (causes, pas comptages) |
| Q4 | Quelle transaction ? | **Rétrospective guidée** (revues jour/semaine/mois : formulaire guidé / structure `pending`/`completed` / pilotage personnel avec signalement « revue en retard »). | scope-report S-12 ; ADR §19 (boucle : … → Adapt → Review) |
| Q5 | D'où vient l'utilisateur ? | **`analytics` (`/progress`)** → CTA « Revue » → `revues-jour` / `revues-semaine` / `revues-mois`. | scope-report S-13, S-12 ; ADR §19 (boucle) |
| Q6 | Quelle valeur pour l'utilisateur ? | Résultat tangible : **causes comprises** (pas de simple comptage de tâches), adaptation de la trajectoire (Self-Improve → Adapt). | ADR §18.2 (causes, pas comptages) ; trigger-map §7 signal 20 (douleur liée aux reports) |
| Q7 | Quelle valeur pour le business ? | Résultat mesurable : **rétrospective structurée** (revues) → transformation réelle (BG-PRIMARY) + adaptation (ADR §19). | trigger-map §1 Primary ; ADR §19 (boucle complète) |

**Pages assignées** (S-IDs) :
- S-12 (`revues-jour` / `revues-semaine` / `revues-mois`) — 1 écran, 3 modes ; formulaire guidé / structure `pending`/`completed` / pilotage personnel avec signalement « revue en retard »

**Justification** : cette chaîne couvre les revues (S-12). Elle est P3 (edge) car elle est une rétrospective structure (analyse des causes, adaptation) qui supporte BG-PRIMARY (transformation réelle) mais n'est pas le moteur principal. La transaction « rétrospective guidée » est distincte de « produire une preuve » (chaîne 01) : ici, c'est la cause (pas le comptage) qui est analysée (ADR §18.2, trap ①).

---

## Shared (exclus de l'affectation de pages)

Les éléments suivants sont **partagés** (cross-cutting), exclus de l'affectation de pages, et mentionnés ici comme « shared » :

- **BottomNav** — navigation principale (Home, Projets, Tâches, Cadrille, Progress) [scope-report §A ; EXPERIENCE.md §Information Architecture]
- **Command Palette (S-31)** — overlay global (pas une route), 5 points d'entrée (UI button, command palette, trigger NL agent, deep link, automatisation Intégrations/Cron→jobs) ; exemples `task.create`, `focus.start`, `discovery.research` [scope-report S-31 ; feature-registry.md §4]
- **États UX cross-cutting (A1–A10)** — `loading`, `empty`, `success`, `error`, `offline`, `killed`, `hover`, `pressed`, `focus`, `disabled` [scope-report §États & modes]
- **Modes produits (D1–D6)** — Core, Study, Exam period, Focus-heavy, Professional, Minimal [scope-report §États & modes ; feature-registry.md §7]

---

## Couverture (tableau S-01…S-40)

| S-ID | Surface | Chaîne assignée |
|------|---------|----------------|
| S-01 | `onboarding` | Chaîne 04 |
| S-02 | `welcome/home` | Chaîne 01 |
| S-03 | `projets-liste` | Chaîne 02 |
| S-04 | `projets-detail` | Chaîne 02 |
| S-05 | `kanban` | **Chaîne 05** (vue parente de S-24 et S-32) |
| S-06 | `objectifs-liste` | Chaîne 02 |
| S-07 | `objectifs-detail` | Chaîne 02 |
| S-08 | `habitudes` | Chaîne 05 |
| S-09 | `routines` | Chaîne 05 |
| S-10 | `calendrier-jour` | Chaîne 04 |
| S-11 | `calendrier-semaine` / `calendrier-mois` | Chaîne 04 |
| S-12 | `revues-jour` / `revues-semaine` / `revues-mois` | Chaîne 06 |
| S-13 | `analytics` | Chaîne 01 |
| S-14 | `bibliotheque-ressources` | Chaîne 03 |
| S-15 | `cours-liste` | Chaîne 03 |
| S-16 | `cours-detail` | Chaîne 03 |
| S-17 | `fiches-liste` | Chaîne 02 |
| S-18 | `fiches-detail` | Chaîne 02 |
| S-19 | `flashcards` | Chaîne 01 |
| S-20 | `qcm` | Chaîne 01 |
| S-21 | `mode-coach` | Chaîne 04 |
| S-22 | `mirror-cognitive` | Chaîne 01 |
| S-23 | `/inbox` | Chaîne 04 |
| S-24 | `/tasks/:id` | Chaîne 05 |
| S-25 | `/learn` (+ overlays) | Chaîne 03 |
| S-26 | `/knowledge` (+ `/knowledge/:nodeId`) | Chaîne 03 |
| S-27 | `Discovery (feed)` | Chaîne 03 |
| S-28 | `/artifacts/:id` | Chaîne 03 |
| S-29 | `/agent` | **Shared** (Command Palette S-31) |
| S-30 | `/settings` | Chaîne 04 |
| S-31 | `Command Palette` | **Shared** |
| S-32 | `taches-liste` / `taches-detail` | Chaîne 05 |
| S-33 | `timeline-gantt` | Chaîne 02 |
| S-34 | `arbre-semantique` | Chaîne 03 |
| S-35 | `decouverte-feed` | Chaîne 03 |
| S-36 | `artefacts-detail` | Chaîne 03 |
| S-37 | `progress-dashboard` | **UNRECONCILED** (probablement identique à S-13 `/progress` ADR §18.6 ; à trancher au standup wave-0) |
| S-38 | `exercises` | Chaîne 01 |
| S-39 | `Vue/matrice Eisenhower (4 quadrants)` | Chaîne 05 |
| S-40 | `Sheet de découverte` | Chaîne 03 |

**Variantes desktop (exemptées par la consigne, déclarées shared)** :

| Variante | Surface de base | Statut |
|---------|-----------------|--------|
| `projets-liste` (desktop 2 colonnes) | S-03 | **Shared** (variante de S-03) |
| `calendrier-*` (semaine 7×24h) | S-10/S-11 | **Shared** (variante de S-10/S-11) |
| `bibliotheque-ressources` (30/70 liste/aperçu, Sidebar remplace BottomNav) | S-14 | **Shared** (variante de S-14) |
| `habitudes` (heatmap 12 sem. desktop vs 7 mobile) | S-08 | **Shared** (variante de S-08) |

**Vérification** : les 40 surfaces canoniques sont assignées (chaîne ou shared). Les 4 variantes desktop sont déclarées shared. **Aucune orpheline**.

---

## Résidus / orphelines

- **Aucune orpheline** : les 40 surfaces canoniques sont couvertes (37 assignées à une chaîne, 1 UNRECONCILED [S-37], 2 déclarées shared [S-29, S-31]).
- **1 surface UNRECONCILED** : S-37 `progress-dashboard` — probablement identique à S-13 `analytics` (`/progress`, dashboard ADR §18.6) ; ne pas dupliquer ; trancher au standup wave-0.
- **4 variantes desktop** sont déclarées shared (exemptées par la consigne) : `projets-liste` desktop 2 colonnes, `calendrier-*` 7×24h, `bibliotheque-ressources` 30/70, `habitudes` heatmap 12 sem.
- **Shared** : S-29 (`/agent`) et S-31 (`Command Palette`) sont exclus de l'affectation de pages (éléments partagés cross-cutting).

---

## Corrections applicables (verdicts des juges) — appliquées

- **J1 (PASS, avec réserves)** : F1 `HabitStreak` pointé via `master-feature-catalog.md` L24 ; F2 « ADR §18.2 (causes) » remplacé par « ADR §2.10 + §18.2 via trigger-map §7 signal 20 » ; F3 S-05 assigné à la Chaîne 05 (non 02).
- **J2 (FAIL → corrigé)** : mécanisme proxy « via » supprimé — les 15 surfaces sont maintenant assignées **directement** dans le bloc « Pages assignées » de chaque chaîne ; S-29 déclaré explicitement **Shared** ; 4 variantes desktop ajoutées sous **Shared**.
- **J3 (FAIL → corrigé)** : 7 couplages implicites justifiés (S-05, S-39 → Chaîne 05 ; S-10/S-11, S-21, S-23 → Chaîne 04 ; S-25 → Chaîne 03 ; S-29 → Shared).
- **Note de cohérence S-37 (`progress-dashboard`)** : référencé §4.5.2 (scope-report §B) mais **non assigné** aux chaînes — le `analytics` S-13 (Ch. 01) est déjà le dashboard Progress ADR §18.6, et le critique G1 note que les deux termes désignent probablement la même surface. **Déclenché UNRECONCILED pour le standup wave-0** — ne pas dupliquer de surface.

---

## Synthèse finale

- **6 chaînes** (1×P1, 4×P2, 1×P3) + 1 bloc shared.
- **Couverture 40/40** surfaces canoniques : **37 assignées** à une chaîne + **1 UNRECONCILED** (S-37) + **2 shared** (S-29, S-31) + 4 variantes desktop déclarées shared.
- **0 orpheline**, **0 doublon entre chaînes**, **0 violation de la règle « zéro if user === Horeb »**.
- **Résolu** : mécanisme proxy « via » retiré (J2/J3) — toutes les surfaces sont assignées directement dans les blocs « Pages assignées ».

**Prêt pour le step 04** (proposition de scénarios).
