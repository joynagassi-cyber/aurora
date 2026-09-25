# SESSION 4 — WAVE 3-7 : AGENT + INTEGRATION + RELEASE
# 4 sous-agents en parallele. Les vagues 0-2 sont terminees
# (modules, features, scientific engine).

## Contexte commun
- Projet : C:\Users\joyda\dyad-apps\aurora-2
- AD-12 : UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-3 : zero cles provider sur le device
- Agnes = PRIMARY TOUJOURS (retour apres fallback, event-reconciliation S2.6)
- Vercel AI SDK = packages/agent UNIQUEMENT (AD-1)
- docs/ui-libraries.md : composants premium

---

## SOUS-AGENT 1 : ORACLE (Agent Kernel + Vercel AI SDK + Expert Skills)

Lis :
- docs/agent/kernel.md (15 sections, 15 composants)
- docs/ai/vercel-ai-sdk-integration.md
- docs/agent/expert-skills-extensions.md
- docs/ai/providers-and-routing.md (S9-12)
- docs/architecture/event-reconciliation-and-router.md (S2.1-2.6)
- docs/scientific-engine/engineering-intelligence-layer.md
- .env.local (AGNES_API_KEY, GROQ_API_KEY, EXA, TAVILY, YOU, COMPOSIO)

Taches :
1. 15 composants du kernel (Intent, Context, Planner, Capability/Tool
   Registry, Permission, Confirmation, Model Router, Execution,
   Verification, Result, Memory, Observability, Error Recovery)
2. Vercel AI SDK (streamText, maxSteps, tools, useChat)
   - 8 tools : planDay, schedule, startFocus, blockApps, research,
     qcm_generate, mirror_analyze, scientific_verify
3. Agnes = PRIMARY (router code, S2.6 : alwaysFirst: true)
   Fallback : Workers AI (GLM-4.7, Gemma 4, Nemotron 3) -> Groq
4. Expert Skills (4 extensions) :
   - Contrastive pairs (2 min)
   - Confidence decay (deterministic formula)
   - Hypotheses (14-day window, fail-fast)
   - Cognitive-Drift Firewall (3 cycles min)
5. AgentRunState (streaming UI, 02 S4)
6. AgentActionEnvelope + NavigationIntent + UiStateCommand
   (kernel S15, command bus, PAS de React direct)
7. fn-agent-run (Edge Function, complete le stub de wave 0)

Commits : prefixe "wave3/oracle:"

---

## SOUS-AGENT 2 : HEPHAESTUS (Goal Engine + Goal Dashboard)

Lis :
- docs/architecture/dynamic-goal-engine.md
- docs/architecture/goal-dashboard-ui.md
- docs/architecture/event-reconciliation-and-router.md (S2)
- docs/ui-libraries.md (S7, GoalProject card example)

Taches :
1. GoalProject (dynamic, agent-created, PAS 7 besoins fixes)
   SubGoal + FeaturePlacement + Timeline + GoalProgress
2. 5 composition patterns (Preparation, Practice, Curation,
   Delivery, Adaptation) = hints pour le Planner
3. Goal Dashboard UI (5 layouts adaptatifs)
   - Feature nodes (position = signification)
   - Esthetique premium (WobbleCard, Progress, Framer Motion pulse)
   - Context strip (suggestion en langue naturelle)
4. Agent capabilities : goal.create, goal.status, goal.recompose,
   goal.pause, goal.complete, goal.abandon, goal.feature.add/remove
5. Integration : GoalProject -> feature-registry -> Agent Planner
   -> Progress (GoalProgress, sole producer F-07)

Commits : prefixe "wave3/hephaestus:"

---

## SOUS-AGENT 3 : HARPYS (23 Workflows + E2E + Self-Improvement)

Lis :
- docs/workflows/composite-workflows.md (W1-W23)
- docs/agent/e2e-agent-scenarios.md (20 scenarios)
- docs/agent/error-recovery.md (10 error classes)
- docs/agent/expert-skills-extensions.md (feedback loop)

Taches :
1. 23 composite workflows (Trigger -> Actors -> Modules ->
   Capabilities -> Data -> Events -> Jobs -> UI -> Agent ->
   Permissions -> Failure -> Recovery)
2. 20 E2E agent scenarios (device, OQ-08 Playwright)
3. Event wiring (AD-9, 9 events flow correctly)
4. Self-Improvement loop (Progress -> Self-Improve -> Discovery
   -> Expert Skill revised)
5. Error recovery (10 classes, partial execution, rollback)

Commits : prefixe "wave4/harpys:"

---

## SOUS-AGENT 4 : ERYNIS (UI Polish + E2E Device + Release)

Lis :
- docs/testing/matrix.md
- docs/deployment/overview.md
- docs/focus-mode/spec.md (S13, 8 DPC scenarios)
- docs/ui-libraries.md (S5, S6, S8)

Taches :
1. Framer Motion polish (page transitions, node pulse, reveal)
2. Theme adaptation (OQ-15, Focus only in V1)
3. Product modes (6 modes, feature-registry S7)
4. Command palette (feature-registry S4)
5. 30fps pass (Pixel 4a, TTI < 1.5s, JS < 300Ko gz)
6. E2E on device (OQ-08, Playwright + Capacitor)
7. Focus DPC E2E (spec S13, 8 scenarios)
8. CI/CD pipeline (build, test, deploy)
9. Release notes + changelog

Commits : prefixe "wave5/erynis:" puis "wave7/erynis:"

---

## Quand les 4 sont finis
- Agent Kernel : 20 E2E scenarios passent
- Goal Engine : 5 shapes + dashboard + agent integration
- Workflows : 23/23, events flow, error recovery
- E2E device : Playwright + Capacitor, Focus DPC (si OQ-17 ok)
- 30fps + TTI + JS budget respectes
- Release candidate

---

## SOUS-AGENT 5 : SOPHIA (Ascent — Pedagogical Trajectory Engine)

Lis :
- docs/ascent/overview.md (22 sections, le concept complet)
- docs/ascent/implementation.md (guide d'implementation)
- docs/architecture/dynamic-goal-engine.md (GoalProject, Ascent = couche au-dessus)
- docs/agent/kernel.md (S12, Ascent = capability du kernel, pas un agent separe)
- docs/progress/overview.md (SkillState, ProgressEvidence)
- docs/learning/overview.md (QCM, flashcards, mirror)
- docs/knowledge/overview.md (tree, concepts, formulas)

Taches :
1. packages/domain/ascent.ts : AscentLearningIR, AscentStep,
   AscentActivity, AscentAdaptation, LearnerBaseline, DepthLevel
   (AD-15 SSoT, 1 fichier, ~200 lignes)
2. packages/ascent/ : serveur, 6 fichiers
   - path-builder.ts (construit le LearningPath)
   - adapter.ts (adapte sur ProgressEvidenceCreated)
   - baseline.ts (calcule LearnerBaseline depuis Progress)
   - depth.ts (selection Quick/Standard/Deep)
   - read-do-prove.ts (sequencing, framework pas rigide)
   - source-hierarchy.ts (A>B>C>D, D ne remplace jamais A)
3. Table : ascent_paths (1 table JSONB, server-only, AD-3)
   RLS : user_id isolation
   PAS dans le PowerSync sync scope (comme expert_skills)
4. Slide-Ascent UI (apps/mobile, 12 types de slides = palette)
   Progressive disclosure (Level 1 = current+next)
   Active Reading : 5 actions (Explain, Note, Flashcard, Visualize, "Je bloque")
   Depth badge + Source hierarchy badge
5. Agent Kernel integration :
   Context Builder lit AscentLearningIR
   Agent emet LearningCommand (generate_qcm, start_mirror)
   Ascent adapte sur events (ProgressEvidenceCreated, SkillStateChanged)
6. Tests : baseline accuracy, prerequisite enforcement, adaptation
   on evidence, depth selection, READ->DO->PROVE flexibility,
   source hierarchy, progressive disclosure, "Je bloque" flow,
   offline, RLS

Regles :
- Ascent = SERVER-SIDE (AD-12, comme Agent Kernel)
- Ascent lit Knowledge/Progress/Discovery (public views), PAS ecriture
- Ascent emet LearningCommand (domain command, AD-7), PAS ecriture Learning
- Ascent ne fait PAS de nouvel event AD-9 (consomme les 9 existants)
- 80/20 : 1 table JSONB pour demarrer, pas 4 tables separees
- PAS de 2e LLM pedagogique (Ascent = deterministe, le LLM explique)
- PAS de Graphiti/Zep (SourceRef + pgvector suffit, AD-11)
- PAS de WebGL (AntV + KaTeX + images)

Commits : prefixe "wave3/sophia:"
- "wave3/sophia: domain types (AscentLearningIR + 6 types)"
- "wave3/sophia: path-builder + adapter + baseline + depth"
- "wave3/sophia: source-hierarchy + read-do-prove"
- "wave3/sophia: ascent_paths table + RLS"
- "wave3/sophia: Slide-Ascent UI (12 slide types + progressive disclosure)"
- "wave3/sophia: Agent Kernel integration + tests"
