---
title: "Aurora Implementation Readiness Report"
date: "2026-09-22"
project: "Aurora"
stepsCompleted:
  - step-01-document-discovery
documents:
  - _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/01-backend.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/02-frontend.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/03-sync.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/04-mobile.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/reviews/review-adversary.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/reviews/review-pack-coherence.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/reviews/review-reconciliation.md
  - docs/epics-stories.md
  - docs/architecture/00-overview.md
  - docs/architecture/adr-compliance-report.md
  - docs/architecture/adr-traceability.md
  - docs/architecture/contract-catalog.md
  - docs/architecture/coverage-matrix.md
  - docs/architecture/cross-feature-interactions.md
  - docs/architecture/data-event-job-catalog.md
  - docs/architecture/data-ownership-matrix.md
  - docs/architecture/gap-register.md
  - docs/architecture/implementation-readiness.md
  - docs/architecture/observability.md
  - docs/architecture/permission-matrix.md
  - docs/architecture/registries.md
  - docs/architecture/system-interaction-map.md
  - docs/agent/kernel.md
  - docs/agent/feature-agentability-matrix.md
  - docs/agent/e2e-agent-scenarios.md
  - docs/agent/error-recovery.md
  - docs/ai/providers-and-routing.md
  - docs/ai/gateway.md
  - docs/focus-mode/spec.md
  - docs/frontend/feature-registry.md
  - docs/frontend/module-ownership-matrix.md
  - docs/mobile/navigation-and-page-composition.md
  - docs/mobile/context-preserving-navigation.md
  - docs/workflows/composite-workflows.md
  - docs/features/master-feature-catalog.md
  - docs/testing/matrix.md
  - docs/security/overview.md
  - docs/deployment/overview.md
notes: >
  PRD equivalent = ADR + SPEC. Epics & Stories = docs/epics-stories.md (created 2026-09-22).
  UX = 02-frontend + 05-design-system packs. No duplicate documents found.
---

# Aurora Implementation Readiness Report

**Date:** 2026-09-22
**Project:** Aurora

## Document Inventory (Step 1)

### Source Documents (authority chain)

| # | Document | Location | Size | Role |
|---|---|---|---|---|
| 1 | ADR v1.7 (adr-extract.md) | _bmad-output/architecture/.../ | 83.1 KB | Normative authority (frozen 2026-09-21) |
| 2 | ARCHITECTURE-SPINE.md (AD-1..AD-16) | _bmad-output/architecture/.../ | 21.5 KB | Read-only spine invariants |
| 3 | SPEC.md (wave plan, OQ-01..OQ-17) | _bmad-output/architecture/.../ | 23.7 KB | Prescriptive contract + open questions |
| 4 | 01-backend.md | _bmad-output/architecture/.../dimensions/ | 48.5 KB | Backend contracts, schemas, jobs, tests |
| 5 | 02-frontend.md | _bmad-output/architecture/.../dimensions/ | 51.4 KB | Frontend 6 layers, routing, UX states |
| 6 | 03-sync.md | _bmad-output/architecture/.../dimensions/ | 48.5 KB | Local-first, repos, entity mapping, sync |
| 7 | 04-mobile.md | _bmad-output/architecture/.../dimensions/ | 49.1 KB | Platform adapters, Focus, DPC candidate |
| 8 | 05-design-system.md | _bmad-output/architecture/.../dimensions/ | 175.4 KB | DS tokens, components, screens, themes v2 |
| 9 | review-adversary.md (F-01..F-10) | _bmad-output/architecture/.../reviews/ | 24.0 KB | Adversarial findings (integrated in spine) |
| 10 | review-pack-coherence.md (H1, M1-M5, L1-L4) | _bmad-output/architecture/.../reviews/ | 29.6 KB | Coherence review + resolutions |
| 11 | review-reconciliation.md | _bmad-output/architecture/.../reviews/ | 10.9 KB | Cross-pack reconciliation |

### Planning Documents

| # | Document | Location | Role |
|---|---|---|---|
| 12 | epics-stories.md (7 epics, 38 stories) | docs/ | Implementation plan (wave 0-7) |

### Technical Documentation (88 files in docs/)

| Area | Files | Key docs |
|---|---|---|
| Architecture | 14 | 00-overview, adr-compliance, coverage-matrix, contract-catalog, registries, data-ownership, gap-register, observability, traceability, implementation-readiness |
| Agent | 14 | kernel (15 sections), agentability-matrix, e2e-scenarios (20), error-recovery (10 classes) |
| AI | 12 | providers-and-routing, gateway, 8 provider pages |
| Focus Mode | 6 | spec (S0-S15), android, device-owner, notifications, calls, recovery |
| Mobile | 5 | navigation, context-preserving, feature-registry/activation/deactivation |
| Frontend | 3 | feature-registry, module-ownership-matrix, page-contracts |
| Modules | ~10 | productivity, learning, knowledge, discovery, progress, artifacts, scientific-engine, integrations, data, jobs |
| Workflows | 1 | composite-workflows (W1-W23) |
| Features | 1 | master-feature-catalog (~40 features) |
| Testing | 1 | matrix (systemic + per-module) |
| Security | 1 | overview |
| Deployment | 1 | overview |
| Troubleshooting | 1 | overview |

**No duplicates found.** All documents are in their canonical locations.

## PRD Analysis (ADR v1.7 + SPEC)

### Functional Requirements

FR1: **Inbox universelle** — capture rapide de taches, notes, evenements, projets, objectifs, documents, idees, ressources; notes libres/structurees; tags; recherche universelle + Command Palette; historique modifications; import/export (ADR S2.1)
FR2: **Gestion des taches** — taches/sous-taches; statuts (a faire, en cours, bloque, termine, annule); projet/matiere/objectif/contexte/ressources; priorite/importance/urgence/echancee/estimation; temps reellement passe; dependances; recurrence; pieces jointes; energie/contexte; historique reports (ADR S2.2)
FR3: **Priorisation Eisenhower** — matrice; priorite manuelle; priorisation assistee (echancee, impact, effort, dependances, importance, urgence, temps disponible); detection taches critiques/bloquantes; reevaluation au changement de contexte; explication par l'agent (ADR S2.3)
FR4: **Calendrier et planification** — jour/semaine/mois; agenda; time blocking; cours/examens/reunions/devoirs/revisions/projets/routines; planification selon temps reellement disponible; echances/rappels; detection conflits/surcharge; replanification agent; planification quotidienne/hebdomadaire/mensuelle (ADR S2.4)
FR5: **Projets** — objectif/echancee/jalons/taches/ressources/documents/notes/historique; vues Liste/Kanban/Timeline/Gantt/Calendrier; progression; dependances/blocages; modeles reutilisables (ADR S2.5)
FR6: **Objectifs** — court/moyen/long terme; hierarchie Objectif->Projet->Tache; jalons; indicateurs progression; historique; analyse plan/realite; suggestions agent (ADR S2.6)
FR7: **Habitudes et routines** — quotidiennes/hebdomadaires; routines matin/soir/etude; suivi regularite; analyse adherence; detection habitudes perturbatrices; adaptation routines (ADR S2.7)
FR8: **Focus Mode** — sessions concentration; minuteur/Pomodoro; blocage/limitation apps distrayantes (lorsque la plateforme le permet); reduction notifications; historique temps concentration; bilan session; le blocage natif doit etre valide techniquement par plateforme (ADR S2.8)
FR9: **Revues et pilotage** — quotidienne/hebdomadaire/mensuelle; bilan taches (accomplies, reportees, abandonnees, bloquees); analyse causes retard; revision priorites; plan d'action suivant; journal decisions (ADR S2.9)
FR10: **Analytics personnels** — temps travail/concentration; temps par projet/matiere/objectif; charge planifiee vs reelle; taux realisation; taches reportees; tendances procrastination; regularite habitudes; progression apprentissage; detection surcharge (ADR S2.10)
FR11: **Bibliotheque de ressources** — cours/PDF/documents/images/vidéos/liens/exercices/rapports/notes; rattachement matiere/competence/projet/objectif/session; recherche; recuperation contexte agent; stockage artefacts (ADR S2.11)
FR12: **Fiches de revision IA** — extraction ciblee (definitions, lois, formules, methodes, pieges, exemples); fidelite corpus enseignant; separation "formulation corpus" vs "explication Aurora"; references sources; memoire formules (variable, unites, conditions, cas particuliers); fiches adaptees matiere; generation orientation apprentissage (rappels actifs, QCM, flashcards) (ADR S17)
FR13: **QCM et exercices** — generation QCM; exercices progressifs; correction/analyse erreurs; erreurs recurrentes (ADR S3)
FR14: **Flashcards FSRS** — repetition espacee; rappel actif; suivi competences (mastered/fragile/missing) (ADR S3)
FR15: **Mirror Cognitive Mode** — l'etudiante explique ce qu'elle a compris; Aurora detecte lacunes/contradictions/erreurs; verification; enregistrement evidence (ADR S3, 01 S4.2)
FR16: **Mode Coach** — check-ins contextuels (debut/avant bloc/apres session/fin); detection changements; replanification dynamique; adaptation apprentissage; coaching discipline; dialogue bref oriente action; memoire longitudinale; parametres cadence/silence/intervention controles par l'utilisateur; non-intrusif (ADR S13)
FR17: **Orchestration agentique** — comprehension intention; recuperation contexte; identification contraintes/echancees/dependances/charge; choix capacites; construction plan; confirmation actions importantes/irreversibles; execution actions autorisees; verification resultat; enregistrement progression/etats; proposition adaptation/prochaine action (ADR S5)
FR18: **Arbre sémantique évolutif** — hierarchie lisible (racines/branches/noeuds/ponts); relations verticales (depend de, est un cas de, approfondit, applique, conduit a); ponts inter-domaines secondaires; consolidation progressive; tracabilite (documents/pages/passages); evolution temporelle; vue par domaine; vue progression (branches fragiles/consolidees, prerequis manquants); regle lisibilite (exploration par niveaux, repli/deploiement) (ADR S14)
FR19: **Scientific Engine** — LaTeX (formules, equations, symboles, matrices, derivees, integrales); edition/affichage; calcul numerique deterministe + unites/conversions; calcul symbolique (simplification, factorisation, derivation, integration, resolution); algebre lineaire; equations/systemes; fonctions scientifiques/statistiques; verification automatique (unites, dimensions, bornes, coherence, resultat); tracabilite (expression initiale, etapes, hypotheses, unites, resultat); moteurs interchangeables (ADR S15)
FR20: **Artifact Hub** — visualisation universelle (PDF/DOCX/PPTX/XLSX/images/audio/video/Markdown/LaTeX); previsualisation adaptee type; acces fichier source; fichiers generes par Aurora (metadata source/tache/contexte); formats non supportes = conservation + telechargement sans pretendre a la previsualisation (ADR S16)
FR21: **Progress** — 5 questions fondamentales; dimensions (incl. oubli); modele evidence; analyse causale (correlation != causalite); trajectoires conditionnelles (aides, pas predictions); dashboards (today/week/month/trajectory); role agent-engine (ADR S18)
FR22: **Discovery Engine** — profil utilisateur; multi-source (You.com/Tavily/Exa); FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY separation; gap analysis (curriculum vs professionnel); living history + scenarios 2030/2040/2050; feuilles de decouverte durables; boucle decouverte->apprentissage (ADR S13)
FR23: **Automatisations** — Supabase Cron -> dispatcher Aurora -> jobs persistes -> Edge Functions (ADR S7)
FR24: **Intentions principales** — planifier, organiser, executer, apprendre, rechercher, pratiquer, progresser, decouvrir, reviser, piloter; l'utilisateur ne choisit pas manuellement un module; Aurora deduit l'intention puis active les capacites (ADR S4)
FR25: **Home (AD-14)** — "Qu'est-ce qui compte maintenant?" : agenda du jour, prochaine action importante, priorite principale, progression critique, revisions a effectuer, acces immediat Focus, suggestions Coach (ADR S11)
FR26: **Multi-provider AI (v1.7)** — Agent Kernel -> AI Router -> AI Policy/Budget -> CF AI Gateway -> providers; Agnes primaire; Workers AI second pool; Groq/Cerebras fallback; OpenRouter/Cohere/Mistral/Gemini optionnels; 9 contrats IA obligatoires (ADR v1.7 S2-S9)
FR27: **Fallback AI (v1.7)** — fallback conserve compatibilite fonctionnelle (vision, tool calling, structured output); 429 = respect policy (pas de rotation de cle); retries bornes separes des fallbacks; reponse traacable (provider, modele, tentative, motif, qualite); modeles free = capacite variable, pas SLA; retrait auto du pool si indisponibles/payants (ADR v1.7 S10)
FR28: **Data policy AI (v1.7)** — documents/cours/notes/personnels non envoyes vers free tier incompatible; DataPolicy declaree dans Model Registry; Groq ZDR par defaut; Mistral/OpenRouter conditions a verifier; politique versionnee (ADR v1.7 S11)
FR29: **DPC Focus v1.8 (candidat)** — deploiement prive single-device; APK sideloade; provisionne Device Owner; setPackagesSuspended (API 29+); Internet actif; Aurora actif; appel option experimental CallScreeningService (OQ-17, 04 S4.3)

**Total FRs: 29**

### Non-Functional Requirements

NFR1: **Local-first** — lecture SQLite/PowerSync; mutations local-first via module owner (AD-7); offline = etat premier (AD-7); UI lit uniquement SQLite (pas de reseau sur le chemin de rendu)
NFR2: **Vendor isolation (AD-1)** — les fonctionalites metier ne dependent jamais d'un fournisseur externe; les SDK de fournisseur vivent uniquement dans les packages adapters; jamais dans domain/ui/apps
NFR3: **No keys on device (AD-3)** — zero cles sur l'appareil; secrets dans Supabase/Cloudflare secret stores; R2 = presigned URLs uniquement; OneSignal appKey (pas server key) dans capacitor.config.ts
NFR4: **Module boundaries (AD-2)** — schemas + RLS + vues publiques par module; pas de jointure inter-modules; pas d'ecriture sur tables d'un autre module
NFR5: **Single-writer (AD-7/F-03)** — le kernel ne mute jamais directement une table; il emet des commandes/evenements; le module own apply l'ecriture
NFR6: **Persisted jobs (AD-8)** — tout travail lourd = job persiste (Supabase Cron + Postgres trigger); idempotent; observable; pas de broker V1
NFR7: **Targeted events (AD-9)** — exactement 9 evenements normatifs; Event History table; pas de microservices V1; pas de Event Sourcing V1
NFR8: **One Agent Kernel (AD-12/F-09)** — un seul kernel serveur; capacites pas agents; l'appareil = surface UI uniquement (AgentRunState); pas d'execution IA cote device
NFR9: **Performance mobile** — Semantic Tree lazy/memo/Dagre incrementale; 30 fps; TTI < 1.5 s; JS < 300 Ko gz; device reference = Pixel 4a (OQ-11)
NFR10: **Security** — RLS par module; auth Supabase; secrets serveur; pas de cles dans le bundle; data policy AI; Composio credentials serveur; presigned URLs R2
NFR11: **Observability** — Sentry (erreurs) + PostHog (analytics, pas de contenu sensible); AI usage tracking; provider health; job status; sync status; focus session errors
NFR12: **CI/CD** — GitHub Actions; buildable apres chaque vague; test du spine (deux equipes -> meme contrat); grep CI (vendor names, secrets in bundle)
NFR13: **Portability** — coeur platform-agnostic (AD-7/S23.3); Phase 2 Electron = ajouter un adapter, pas reecrire; pas de microservices V1
NFR14: **Fidelite corpus (AD-11)** — corpus enseignant reste textuellement dominant; explications agent separees + etiquetees; provenance sur chaque formulation; verification de fidelite avant export
NFR15: **Design System (AD-17)** — style neutre x theme expressif x adaptation locale; 10 themes vivants + 3 presets; tokens semantiques independants du theme; resolveToken + AuroraThemeProvider
NFR16: **SSoT types (AD-15)** — toutes les entites de domaine dans packages/domain; les vues = projections declarees; pas de re-declaration
NFR17: **Quota hygiene (AD-5/v1.7 S10)** — pas de rotation de cles pour contourner les quotas; free tier = capacite variable; Model Registry versionne; auto-retirement

**Total NFRs: 17**

### Additional Requirements / Constraints

- Phase 1 = mobile-only (Android, Ionic React + Capacitor); pas d'Electron en V1 (ADR S23)
- Phase 2 = desktop (Electron adapter) apres stabilisation mobile
- Contract Packs (AD-13) : one-writer-per-file; PR = contrat d'integration; 5 etats UX obligatoires; DoD par pack
- Home invariant (AD-14) : composition fixe "Qu'est-ce qui compte maintenant?"
- Enveloppe operationnelle figee (AD-16) : 3 env; un owner Model Registry; Foundation = duty owner
- 5 moteurs figes derriere 5 contrats renderer (AD-10) : SemanticTree, Infographic, DataViz, Math, Animation
- Whitelist Capacitor (04 S3.1) : tout plugin hors liste = PR Foundation (AD-16c)
- AI multi-provider : au moins 2 providers fonctionnels au One-Day Build (Agnes + Workers AI)
- Composio = tool/integration layer (pas provider IA); credentials serveur uniquement
- Focus v1.8 DPC : condition prealable = provisioning device owner (OQ-17)

### PRD Completeness Assessment

L'ADR v1.7 + SPEC couvrent l'ensemble des exigences fonctionnelles et non fonctionnelles. Les 29 FR sont des exigences produit (le "quoi"); les 17 NFR sont les contraintes techniques (le "comment"). Le SPEC traduit les NFR en decisions d'architecture (AD-1..AD-16) et en vagues de delivery.

**Lacune identifiee :** le document Epics & Stories (docs/epics-stories.md) etait absent du flux BMAD standard. Il a ete cree le 2026-09-22 pour combler ce trou. Les 38 stories couvrent les 29 FR + 17 NFR de la vague 0 a la vague 7.

**Gaps restants (non bloquants pour l'evaluation) :**
- OQ-01/02/03/17 = decisions a ratifier en vague 0 (voir implementation-readiness.md)
- G-L5 (Eisenhower screen) = design prescriptif dans docs/productivity/eisenhower.md, a ratifier avec DS
- G-M7 (Feature Registry) = specifie dans docs/frontend/feature-registry.md, a ratifier vague 0

## Epic Coverage Validation

### Coverage Matrix

| FR | PRD Requirement | Epic/Story Coverage | Status |
|---|---|---|---|
| FR1 | Inbox universelle | W2-E1-1 (Inbox + Tasks) | COVERED |
| FR2 | Gestion des taches | W2-E1-1 (Task CRUD) | COVERED |
| FR3 | Priorisation Eisenhower | W2-E1-1 (Eisenhower quadrant, G-L5) | COVERED |
| FR4 | Calendrier + time blocking | W2-E1-2 (Calendar + Time Blocking) | COVERED |
| FR5 | Projets (Gantt/Kanban/Timeline) | W2-E1-3 (Projects + Goals) | COVERED |
| FR6 | Objectifs (hierarchie) | W2-E1-3 (Goal -> Project -> Task) | COVERED |
| FR7 | Habitudes + routines | W2-E1-4 (Habits + Routines) | COVERED |
| FR8 | Focus Mode | W2-E1-5 (Focus + DPC) + W0-E4-3 (DPC provisioning) + W7-E1-3 (DPC E2E) | COVERED |
| FR9 | Revues (quotidienne/hebdo/mensuelle) | W2-E1-6 (Reviews + Analytics) | COVERED |
| FR10 | Analytics personnels | W2-E1-6 (planned vs actual, trends) | COVERED |
| FR11 | Bibliotheque de ressources | 01 S4.1 + feature catalog `productivity.library` — **pas de story dedie dans epics-stories.md** | GAP |
| FR12 | Fiches de revision IA + fidelite | W2-E2-2 (Study sheets AI + fidelity) | COVERED |
| FR13 | QCM + exercices progressifs | W2-E2-4 (QCM + exercises) | COVERED |
| FR14 | Flashcards FSRS | W2-E2-3 (Flashcards FSRS) | COVERED |
| FR15 | Mirror Cognitive Mode | W2-E2-5 (Mirror Cognitive Mode) | COVERED |
| FR16 | Mode Coach (check-ins, cadence, silence) | W3-E1-4 (Memory/Expert Skills) + 01 S5.6 + 04 S3.4 — **pas de story Coach dedie** | GAP |
| FR17 | Orchestration agentique (plan, confirm, execute, verify) | W3-E1-1/2/3 (Intent + Planning + Execution + Verification) | COVERED |
| FR18 | Arbre sémantique évolutif | W2-E3-1 (Semantic tree + Dagre) | COVERED |
| FR19 | Scientific Engine (LaTeX, calc, unites) | W2-E6-1 (Scientific engine deterministic) | COVERED |
| FR20 | Artifact Hub (visualisation universelle) | W2-E6-2 (Artifact Hub + R2) | COVERED |
| FR21 | Progress (evidence, dashboards, trajectories) | W2-E5-1 + W2-E5-2 (Evidence + Dashboards) | COVERED |
| FR22 | Discovery Engine (multi-source, gaps, horizons) | W2-E4-1 + W2-E4-2 (Research + Gap analysis) | COVERED |
| FR23 | Automatisations (Cron -> dispatcher -> jobs) | W1-E2-3 (Job system) — **pas de story "automations" dedie** | MINOR GAP |
| FR24 | Intentions principales (deduction, activation) | W3-E1-1 (Intent Engine) + W4-E1-2 (Agent orchestration) | COVERED |
| FR25 | Home (AD-14 invariant) | W0-E4-2 (Mobile shell + Home) + W5-E1-2 (Navigation polish) | COVERED |
| FR26 | Multi-provider AI (9 contrats) | W0-E5-1/2/3 (AI pipeline + Model Registry + Gateway) | COVERED |
| FR27 | Fallback AI (429, retry, traceability) | W0-E5-1 (AIFallbackStrategy, AIHealthRegistry) | COVERED |
| FR28 | Data policy AI (pas de fuite vers free tier incompatible) | W0-E5-1 (AIRequestGuard, data policy refusal) | COVERED |
| FR29 | DPC Focus v1.8 (device owner, suspension) | W0-E4-3 + W2-E1-5 + W7-E1-3 | COVERED |

### Missing / Gap FRs

**FR11 — Bibliotheque de ressources (GAP):**
- 01 S4.1 specifie les tables `resources` + `notes` + `documents`; le feature catalog a `productivity.library`.
- Dans les epics, c'est implicitement dans W2-E1-1 mais pas une story dediee.
- **Action:** ajouter une story `W2-E1-7: Resource Library` (courser/PDFs/images/liens/exercices; rattachement matiere/competence/projet; recherche; R2 storage).

**FR16 — Mode Coach dedie (GAP):**
- Le Coach est reparti entre W3-E1-4 (Expert Skills/memoire) et 04 S3.4 (notifications OneSignal + cadence).
- Pas de story qui assemble le flux complet: check-ins contextuels + detection changements + replanification + adaptation apprentissage + coaching discipline + memoire longitudinale + parametres cadence/silence.
- **Action:** ajouter une story `W3-E1-6: Coach Mode` (flux complet ADR S13; OneSignal + local; silence windows; non-intrusif).

**FR23 — Automatisations dediees (MINOR GAP):**
- Le systeme de jobs (W1-E2-3) couvre le mecanisme; les automations specifiques (Cron triggers, `Automation` entity) ne sont pas une story.
- **Action:** ajouter une story `W2-E1-7b: Automations` (Automation entity, Cron triggers, user-facing toggle, `integrations.automation.toggle` capability).

### Coverage Statistics

- Total FRs (PRD): **29**
- FRs fully covered: **26** (89.7%)
- FRs with gap: **3** (FR11, FR16, FR23)
- Coverage: **89.7%** — les 3 gaps sont des stories a ajouter dans epics-stories.md

## UX Alignment Assessment

### UX Document Status: **FOUND** (sharded across packs + docs/)

UX/UI documentation is distributed across:
- `_bmad-output/.../dimensions/02-frontend.md` (51.4 KB) — 6-layer architecture, routing, 5 UX states, perf, AD-10 renderer contracts
- `_bmad-output/.../dimensions/05-design-system.md` (175.4 KB) — tokens, 9 DS components, 5 renderer DEFs, screen inventory (S4), themes v2 (S5-6), 49 theme x screen mockups [G-L2]
- `docs/mobile/navigation-and-page-composition.md` — all 17 pages: entry/outgoing/incoming routes, context, actions, deep links, agent-triggered opening, return behavior, persistent/empty/permission states
- `docs/mobile/context-preserving-navigation.md` — route params, query params, navigation state, entity IDs, session IDs, draft persistence, return destination
- `docs/frontend/page-contracts.md` — UI -> Application command -> Contract -> Backend service -> Domain -> Persistence; optimistic update, offline, retry, loading, stale data, errors, conflict, sync
- `docs/frontend/feature-registry.md` — feature activation/deactivation, product modes, adaptive navigation
- `docs/design-system/overview.md` — 10 themes + 3 presets, semantic tokens, local adaptation, accessibility

### UX <-> PRD Alignment

| Check | Status | Detail |
|---|---|---|
| All FR screens have a route + states | COVERED | 05 S4 inventory + 02 S7 (5 UX states: loading/error/empty/success/offline + killed [G-M2]); 17 pages in navigation doc |
| FR8 Focus Mode UI states | COVERED | focus spec S6 (7 states: scheduled/starting/prechecking/active/paused/ending/completed + interrupted/restoring/failed); 05 S4.4 |
| FR15 Mirror Cognitive Mode screen | GAP | 01 S4.2 prescriptive design; dedicated screen = additive 05 inventory item, wave 2 [G-L3] |
| FR3 Eisenhower quadrant screen | GAP | 05 S4.3-4.5 does not include it; prescriptive design in docs/productivity/eisenhower.md; ratify before wave-2 cut [G-L5] |
| Home invariant (FR25/AD-14) | COVERED | 05 S4.1 + 02 S6.2; 7 fixed slots |
| Agent UI surface (FR17) | COVERED | 02 S4 F-09: device sees only AgentRunState; kernel S15 command bus |
| Command Palette (FR1/FR24) | COVERED | feature-registry.md S4; 5 entry points, 0 duplicated logic |
| Product modes (FR24/FR25) | COVERED | feature-registry.md S7; 6 modes (Core/Study/Exam/Focus/Professional/Minimal) |
| Context-preserving navigation | COVERED | mobile/context-preserving-navigation.md; Course -> Chapter -> Formula -> Flashcards -> QCM -> Progress |
| Feature deactivation UI | COVERED | feature-registry.md S6; 8 effects (nav, shortcut, agent, dashboard, jobs, notifications, data, deep links) |

### UX <-> Architecture Alignment

| Check | Status | Detail |
|---|---|---|
| 5 renderer contracts supported | COVERED | AD-10: SemanticTree, Infographic, DataViz, Math, Animation; 02 S5 CONSO + 05 S3.6 DEF; G-M1 (AnimationController wrapper) open |
| Performance budget (NFR9) | COVERED | 02 S9: 30 fps, TTI < 1.5s, JS < 300Ko gz; Pixel 4a reference [OQ-11] |
| Theme system (NFR15) | COVERED | AD-17: neutral style x 10 themes x 3 presets; packages/ui/src/themes/ JSON SSoT; G-H2 resolved; G-M5 (ChartSpec) open |
| Offline states (NFR1) | COVERED | 02 S7: 5 UX states + offline state; 03 S3.2 SyncStatus; data/local-first.md |
| DPC Focus UI (FR29) | COVERED | focus spec S10 contract; S6 states; blocklist UI with per-package status; consumer fallback = no block CTA [04 S4.2] |
| Agent never touches React | COVERED | kernel S15; command bus (AgentActionEnvelope -> NavigationIntent / UiStateCommand); mission S77 |

### Warnings

- **G-L3:** Mirror Cognitive Mode screen is not in the 05 S4 inventory. Prescriptive design in 01 S4.2; screen to be added as additive item in wave 2. **Not a blocker for wave 0/1/2.**
- **G-L5:** Eisenhower quadrant screen absent from 05 S4.3-4.5. Prescriptive design in docs/productivity/eisenhower.md. Ratify before wave-2 cut. **Not a blocker for wave 0/1.**
- **G-M2:** `killed` app state not in the 5-state UX matrix. Add as sub-state of loading in 02 S7 + 05 S3.7. **Wave-0 fix.**
- **G-L2:** 49 theme x screen mockups not produced (wave-0 Dyad/UI deliverable, ADR S22). **Not a blocker for architecture; blocks DS polish.**

## Epic Quality Review

### Validation against create-epics-and-stories standards

#### A. User Value Focus

| Epic | User-centric? | Finding |
|---|---|---|
| W0-E1 (Monorepo + Domain Types) | No | Technical milestone. Acceptable for wave 0 (infrastructure prerequisite), but NOT a user-facing epic. |
| W0-E2 (DS Foundations) | No | Technical milestone (theme JSON, components). Prerequisite for wave 1 UI. |
| W0-E3 (Backend Schemas + RLS) | No | Technical milestone (database setup). Prerequisite. |
| W0-E4 (Platform + Mobile Shell) | Partial | Shell setup is technical; DPC provisioning (W0-E4-3) has user value (Focus capability). |
| W0-E5 (AI Pipeline) | No | Technical milestone (contracts, registry, gateway). Prerequisite. |
| W1-E1 (UI Foundation) | Partial | Component library = technical; Feature Registry = user-facing (can enable/disable features). |
| W1-E2 (Data Foundation) | No | Technical milestone (sync, auth, jobs). Prerequisite. |
| W1-E3 (Notification Foundation) | Partial | Notifications = user-facing; OneSignal setup = technical. |
| W2-E1..E6 (Features) | **Yes** | All user-facing: Productivity, Learning, Knowledge, Discovery, Progress, Scientific/Artifacts. |
| W3-E1 (Agent Kernel) | **Yes** | User can interact with Aurora via natural language. |
| W4-E1 (Integration) | **Yes** | Cross-module workflows deliver user value. |
| W5-E1 (UI/UX Polish) | **Yes** | User-facing refinement. |
| W6-E1 (Deep Review) | No | QA activity, not user-facing. |
| W7-E1 (E2E + Release) | Partial | E2E tests are QA; release = user-facing. |

**Verdict:** Waves 0-1 are technical milestones (acceptable for a foundation phase). Waves 2-5 are user-centric. W6 is QA. W7 is mixed. This matches the SPEC wave plan (0=contracts, 1=fondations, 2=features, 3=agent, 4=integration, 5=dyad, 6=codex, 7=release). No violation of the SPEC structure, but the epics are NOT in standard BMAD "user value per epic" format. **This is a structural deviation, not a defect, given the project's wave-based delivery model.**

#### B. Epic Independence (sequential chain)

```
W0 -> W1 -> W2 -> W3 -> W4 -> W5 -> W6 -> W7
```

Each wave depends only on the previous one. No circular dependencies. No epic requires a future epic. **PASS.**

#### C. Forward Dependencies (violations found)

| Violation | Detail | Severity |
|---|---|---|
| W2-E2-5 (Mirror Cognitive Mode) depends on W3 (Agent Kernel) | Mirror analysis is a server job that uses the Agent Tutor capability. In wave 2, the Agent Kernel doesn't exist yet. | MAJOR |
| W2-E1-5 (Focus DPC) depends on W0-E4-3 (DPC provisioning) + W7-E1-3 (DPC E2E) | The E2E test is in wave 7, but the story in wave 2 should be self-contained. The DPC E2E in W7 is a re-verification, not a dependency. | MINOR (W7 is verification, not implementation) |

**Remediation for W2-E2-5:** Mirror Cognitive Mode should be split:
- W2 story: "Mirror analysis job + detections + evidence path" (server-side, uses 01 S4.2 design; does NOT require the full Agent Kernel)
- W3 story: "Mirror as Agent Tutor capability" (the agent can trigger mirror analysis via NL)
- The wave-2 story is independently completable (the job runs, the screen renders, evidence is recorded); the wave-3 story adds the NL trigger.

#### D. Story Sizing

| Story | Size | Concern |
|---|---|---|
| W0-E2-1 (Theme JSON: 10 themes + 3 presets + resolveToken + AuroraThemeProvider + 49 mockups [G-L2]) | XL | Too large. Split: (a) theme JSON files + resolveToken + provider; (b) 49 mockups = separate wave-0 deliverable (G-L2, DS team). |
| W2-E1-1 (Inbox + Tasks + Eisenhower) | XL | Too large. Split: (a) Inbox + Task CRUD; (b) Eisenhower quadrant [G-L5]. |
| W2-E1-5 (Focus in-app + DPC + timer + Pomodoro + blocklist + crash/reboot) | XL | Too large. Split: (a) in-app timer + Pomodoro; (b) DPC blocklist + crash/reboot recovery. |
| W3-E1-1/2/3 (Intent+Context / Planner+Registries / Execution+Verification+Result) | XL x3 | Each is a large chunk. Acceptable for a kernel (cohesive unit), but consider splitting E1-2 (Planner + 2 registries) into Planner and Registry. |

#### E. Acceptance Criteria Quality

The ACs in epics-stories.md are **descriptive** ("Timer works offline; DPC: setPackagesSuspended applied + restored"), not in Given/When/Then BDD format. For a wave-based delivery with code agents, descriptive ACs are sufficient (the code agent reads the doc, not a BDD test). **MINOR concern — not a blocker.**

#### F. Database/Entity Creation Timing

W0-E3-2 creates ALL module tables in one story (Productivity, Learning, Knowledge, Progress, Discovery, Artifact, Agent, Identity). This is the "create all tables upfront" anti-pattern. **However**, in a Supabase/Postgres setup with RLS, creating all tables in the migration phase (wave 0) is the pragmatic choice — the tables are empty and RLS-gated. The alternative (per-wave table creation) would fragment the schema. **Acceptable deviation, documented.**

#### G. Best Practices Compliance Checklist

| Check | Status |
|---|---|
| Epic delivers user value | PARTIAL (W0-W1 = technical; W2-W5 = user-facing) |
| Epic can function independently | PASS (sequential chain, no forward deps except W2-E2-5) |
| Stories appropriately sized | 3 XL stories should be split (W0-E2-1, W2-E1-1, W2-E1-5) |
| No forward dependencies | 1 MAJOR (W2-E2-5 -> W3) |
| DB tables created when needed | DEVIATION (all tables in W0-E3-2, acceptable for Supabase) |
| Clear acceptance criteria | PASS (descriptive, not BDD — acceptable for wave delivery) |
| Traceability to FRs | PASS (coverage matrix in step 3) |

### Findings Summary

| Severity | Count | Items |
|---|---|---|
| RED (Critical) | 0 | — |
| ORANGE (Major) | 1 | W2-E2-5 forward dependency on W3 |
| YELLOW (Minor) | 4 | W0-E2-1 too large; W2-E1-1 too large; W2-E1-5 too large; ACs not BDD |
| NOTE | 2 | W0-W1 are technical epics (acceptable); all tables in W0-E3-2 (acceptable) |

**Remediation (actionable):**
1. **Split W2-E2-5** into W2 story (job + screen + evidence, no agent) + W3 story (NL trigger via Tutor capability)
2. **Split W0-E2-1** into W0-E2-1a (theme JSON + resolveToken + provider) + W0-E2-1b (49 mockups, G-L2, wave-0 DS deliverable)
3. **Split W2-E1-1** into W2-E1-1a (Inbox + Task CRUD) + W2-E1-1b (Eisenhower quadrant, G-L5)
4. **Split W2-E1-5** into W2-E1-5a (in-app timer + Pomodoro) + W2-E1-5b (DPC blocklist + crash/reboot)

## Summary and Recommendations

### Overall Readiness Status: **NEEDS WORK** (pre-wave-0 audit, not a green light for code agents)

Aurora's architecture documentation is **extensive and coherent** (88 docs + 11 source files, 29 FRs, 17 NFRs, 16 AD invariants, 9-event vocabulary, 38 stories across 7 waves). The ADR v1.7 + Spine + 5 packs + 3 reviews form a solid normative foundation. The 2026-09-22 pass resolved 9 documentation gaps (G-D1..G-D9) and closed G-H1, G-H2, G-H3, G-M6, G-L3.

However, **5 decisions remain open** that gate the wave-0 start, and **1 structural defect** in the epics (forward dependency) must be fixed before code agents launch.

### Critical Issues Requiring Immediate Action

1. **OQ-17 DPC provisioning (BLOCKING for Focus):** The v1.8 candidate (private single-device deployment, Device Owner, `setPackagesSuspended`) is specified but **not verified on the target phone**. Without this verification, Focus Mode implementation cannot be frozen. If the phone cannot be DPC-provisioned, the consumer fallback (04 S4.1, restriction-only) applies and the entire DPC spec section becomes inapplicable. **Owner: Foundation + Productivity, wave 0.**

2. **OQ-01 pnpm layout ratification:** The monorepo layout (9 packages + 2 apps) is specified but not ratified. All packages, CI rules, and team ownership depend on this. **Owner: Foundation, wave 0 standup.**

3. **OQ-02 team column in 03 S4.2:** The entity->module->table mapping is frozen, but the team assignment column is empty. Every module team needs to know which entities they own. **Owner: Foundation + all module teams, wave 0.**

4. **OQ-03 environment values:** 3 envs (dev/staging/prod) have Supabase project IDs, R2 bucket names, OneSignal appKeys, provider account IDs = all TBD. **Owner: Foundation, wave 0.**

5. **G-M7 Feature Registry ratification:** The FeatureDescriptor + registry chain + deactivation effects + product modes are fully specified (feature-registry.md S1-S11) but not ratified. Types must be in packages/domain (AD-15). **Owner: Foundation + App Shell, wave 0.**

### Major Issues (fix before wave 2)

6. **W2-E2-5 forward dependency:** Mirror Cognitive Mode story in wave 2 depends on the Agent Kernel in wave 3. **Remediation:** split into W2 story (job + screen + evidence, no agent trigger) + W3 story (NL trigger via Tutor capability).

### Minor Issues (fix during wave 0/1)

7. **3 XL stories too large** (W0-E2-1, W2-E1-1, W2-E1-5) — split per quality review findings
8. **G-M2: killed app state** not in 5-state UX matrix — add as sub-state of loading
9. **G-M3: AppError SSoT** still in 02 S10 body, not in packages/domain — move to domain
10. **G-M4: job_queue full shape** not frozen — freeze in 01 S5.3
11. **G-M5: ChartSpec SSoT** owner + shape unpublished — publish in 05 S3.6 (DS team)
12. **G-L2: 49 theme x screen mockups** not produced — wave-0 DS deliverable

### 3 FR Coverage Gaps (add stories to epics-stories.md)

13. **FR11 Resource Library** — no dedicated story (implicit in W2-E1-1)
14. **FR16 Coach Mode** — no dedicated story (split across W3-E1-4 + 04 S3.4)
15. **FR23 Automations** — no dedicated story (part of W1-E2-3 job system)

### Recommended Next Steps

1. **Ratify OQ-01/02/03/17 + G-M7** at the wave-0 standup (5 decisions, ~2h discussion). This unblocks the wave-0 gate.
2. **Split W2-E2-5** (Mirror) into W2 + W3 stories; **add 3 missing stories** (FR11, FR16, FR23) to epics-stories.md. Update the file.
3. **Split the 3 XL stories** (W0-E2-1, W2-E1-1, W2-E1-5) into 6 smaller stories.
4. **Fix G-M2/M3/M4/M5** during wave 0 (all are 1-file fixes in the packs or domain types).
5. **Run the wave-0 DPC provisioning procedure** (focus spec S9.1) on the target phone. Record results. If it fails, update the Focus spec to consumer fallback mode.
6. **Launch wave-0 code agents** with the updated epics + ratified decisions.

### Final Note

This assessment identified **15 issues** across **4 categories** (5 blocking decisions, 1 structural defect, 6 minor fixes, 3 FR coverage gaps). The architecture documentation is complete and traceable; the gap is in **ratification** (5 OQ/G decisions) and **epic structure** (1 forward dep + 3 XL stories + 3 missing stories). None of these require re-architecting — they are administrative fixes. Once the 5 blocking decisions are ratified and the 7 epic fixes applied, Aurora is ready for wave-0 code agent launch.

---
*Assessment date: 2026-09-22. Assessor: BMAD bmad-check-implementation-readiness skill. Sources: ADR v1.7, ARCHITECTURE-SPINE, SPEC, packs 01-05, reviews, docs/ (88 files), epics-stories.md.*

---
## UPDATE 2026-09-22 (re-run after 11 new architecture docs)

### New documents since first run

| # | Document | What it adds |
|---|---|---|
| 1 | docs/architecture/dependency-matrix.md (S1-15) | 4-module asymmetric hierarchy, 9-event closed vocabulary, port contracts, decoupling by orchestration, anti-patterns + CI tests |
| 2 | docs/architecture/dynamic-goal-engine.md | Universal Problem IR (replaces fixed-need model), GoalProject (dynamic, agent-created), 5 composition patterns (hints, not constraints), capability discovery |
| 3 | docs/architecture/goal-dashboard-ui.md | GoalProject card (Home), adaptive Goal Dashboard (5 layouts per shape), feature nodes with positional meaning, aesthetics rules (NOT robotic), theme integration |
| 4 | docs/architecture/event-reconciliation-and-router.md | Battery-aware event sync (PowerSync push, WorkManager, not poll), TaskProfile typed routing (5 levels), Agnes = ALWAYS PRIMARY (fallback only on error, return to Agnes) |
| 5 | docs/ai/vercel-ai-sdk-integration.md | Vercel AI SDK as Agent Kernel implementation framework (streamText, maxSteps, tools, useChat), CopilotKit excluded, AD-1 boundary, Tiptap + AD-10 renderer integration |
| 6 | docs/ai/providers/agnes-image.md | Agnes Image 2.5 Flash full API ref: endpoint, params (size 1K-4K, ratio 8 values), output dimensions table, 5 capabilities, prompting guide, pricing (ALL FREE, snapshot 2026-09-22), error handling, Model Registry entry |
| 7 | docs/artifacts/infographic-multi-resource.md | Agent as Art Director: Search Tool (Exa/Tavily) + GenAI Tool (Agnes Image 2.5 Flash / fal.ai fallback) + AntV hybrid SVG rendering, WebP compression, Capacitor local cache (offline), 2 images max per infographic |
| 8 | docs/scientific-engine/engineering-intelligence-layer.md (S1-29) | Problem IR (universal, quantity-based), 6 registries (Pattern, Formula, Method, Solver, Verification, Code), 5-stage validation, 5 engine families, 4-layer RAG, source hierarchy (5 levels), "no 100% reliable" rule, INSUFFICIENT_DATA handling, GenieCivilPDF pipeline |
| 9 | docs/knowledge/discovery-gap-pipeline.md | Gap Analysis Pipeline (structured, not text comparison), invariance principle (same formula = same node), phased layering (vertical tree, bridges hidden by default), progress backlink (node state = mastered/fragile), Benin filtering policy (data-driven, not hardcoded) |
| 10 | docs/agent/expert-skills-extensions.md | 4 extensions to ADR S14: Contrastive Evaluation (2 pairs min), Confidence Decay (deterministic formula), Failing Fast (hypotheses, 14-day window), Cognitive-Drift Firewall (3 cycles min). SQLite schema (4 tables). AI Router weighting (measurable context vars, not sentiment) |
| 11 | docs/epics-stories.md | 7 epics, 38 stories (wave 0-7), acceptance criteria, module owners, dependencies, sizes. 3 FR coverage gaps identified (FR11, FR16, FR23) |

### Re-validated FR Coverage (29 FRs)

FR1-FR29: **26 covered, 3 gaps (FR11, FR16, FR23)** — unchanged from first run.
The 3 gaps are story-level omissions in epics-stories.md, NOT architecture gaps.
The architecture fully specifies all 29 FRs; the epics just need 3 more stories.

### Updated Verdict

**NEEDS WORK** (unchanged). The 5 blocking decisions (OQ-01/02/03/17 + G-M7)
remain open. The 11 new architecture docs significantly REDUCE the gap between
"designed" and "implementable":

- The Agent Kernel now has a concrete implementation framework (Vercel AI SDK)
- The Scientific Engine has a full 6-registry architecture (Problem IR + 5 engine families)
- The Goal system is dynamic (not 7 hardcoded needs) with a visual dashboard spec
- The Discovery + Semantic Tree have a structured Gap Analysis Pipeline
- The 4-module dependency matrix has CI-enforced anti-patterns
- The Event reconciliation is battery-aware (WorkManager, not continuous service)
- Agnes Image 2.5 Flash is fully specified (API ref, params, pricing, integration)
- Expert Skills have 4 deterministic extensions (contrast, decay, hypothesis, firewall)

**The documentation is now sufficient for wave-0 code agent launch**
**once the 5 blocking decisions are ratified.** No new architectural
gaps were introduced by the 11 new docs; they are all additive
and consistent with the frozen spine (AD-1..AD-16) + ADR v1.7.

### New Gaps Introduced by New Docs

| ID | Gap | Severity | Action |
|---|---|---|---|
| G-D10 | Vercel AI SDK is an implementation detail not in the ADR spine | LOW | Additive (AD-1 boundary: SDK in packages/agent only). No spine change needed. Document as wave-3 decision |
| G-D11 | Agnes Image 2.5 Flash not in Model Registry seed (wave 0) | MEDIUM | Add to W0-E5-2 (Model Registry seed). Capability: image-generation. Currently free (snapshot 2026-09-22) |
| G-D12 | Engineering Intelligence Layer (6 registries) not in package structure (OQ-01) | MEDIUM | Add `packages/engineering-core`, `packages/engineering-solvers`, `packages/engineering-adapters` to pnpm layout ratification |
| G-D13 | Dynamic Goal Engine (GoalProject) not in AD-15 entity list | MEDIUM | Additive: `GoalProject`, `SubGoal`, `FeaturePlacement`, `GoalProgress` to packages/domain. Additive ADR (spine Consistency Conventions) |
| G-D14 | Discovery filtering policy (Benin context) uses UserContext fields not yet in 01 S2.1 | LOW | Additive: `region`, `disciplines`, `professional_target`, `budget_constraint` to UserContext. Wave 0 (Identity) |

### Final Verdict (updated)

**Status: NEEDS WORK -> READY FOR WAVE-0 PLANNING**

The 5 blocking decisions are ratification exercises (not design work):
1. OQ-01: confirm pnpm layout (now includes engineering packages, G-D12)
2. OQ-02: fill team column in 03 S4.2
3. OQ-03: provide environment values
4. OQ-17: run DPC provisioning on target phone
5. G-M7: ratify Feature Registry

Plus 4 new minor gaps (G-D11..D14) that are additive (no spine change):
- Add Agnes Image to Model Registry seed (W0-E5-2)
- Add engineering packages to pnpm layout (OQ-01)
- Add GoalProject entities to AD-15 (additive ADR)
- Add UserContext fields for Discovery filtering (wave 0)

**None of these block wave-0 start.** They are wave-0 deliverables
to complete alongside the existing 38 stories.
