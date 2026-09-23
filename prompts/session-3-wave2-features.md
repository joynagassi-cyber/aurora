# SESSION 3 — WAVE 2 : FEATURES (6 sous-agents paralleles)

Lance 6 sous-agents en parallele. Les vagues 0-1 sont terminees
(monorepo, DS, data, mobile shell). Tu codes les features.

## Contexte commun
- Projet : C:\Users\joyda\dyad-apps\aurora-2
- AD-7 : single-writer (ton module ecrit SEULEMENT ses tables)
- AD-9 : 9 evenements uniquement
- AD-8 : lourd = job persiste (job_queue, idempotent)
- AD-2 : pas de cross-module table access
- docs/ui-libraries.md : utilise les composants premium
- docs/architecture/dependency-matrix.md : qui lit/ecrit quoi

---

## SOUS-AGENT 1 : ATLAS (Productivity)

Lis : docs/productivity/overview.md, docs/productivity/eisenhower.md,
      docs/features/master-feature-catalog.md, 01 S4.1, 03 S4.2

Taches :
1. Inbox + Tasks (CRUD, statuts, subtasks, recurrence, dependencies)
2. Eisenhower quadrant (G-L5, 4 quadrants, agent-assisted)
3. Calendar + Time Blocking (FullCalendar, PAS ion-calendar)
4. Projects + Goals (Gantt/Kanban/Timeline/List, milestones)
5. Habits + Routines (HabitStreak heatmap)
6. Focus Mode (timer + Pomodoro + blocklist, DPC stub)
7. Reviews + Analytics (daily/weekly/monthly)
8. Events : TaskCompleted, GoalUpdated (producer = Productivity)

Commits : 1 par feature, prefixe "wave2/atlas:"

---

## SOUS-AGENT 2 : SAPPHO (Learning + Knowledge)

Lis : docs/learning/overview.md, docs/knowledge/discovery-gap-pipeline.md,
      01 S4.2-4.3, 05 S4.6-4.8, ADR S17

Taches :
1. Course import (camera -> R2 -> fn-import-course + OCR job)
2. Study sheets (AI generation, 7 structures, fidelity check)
3. Flashcards (FSRS server-side, state mirrored local)
4. QCM + exercises (AI generation, progressive, error analysis)
5. Mirror Cognitive Mode (01 S4.2, G-L3, server job)
6. Semantic tree (Postgres + pgvector, lazy Dagre, invariance)
7. Retrieval (FTS + pgvector + R2, server-only, AD-12)
8. Events : CourseImported, FlashcardReviewed (producer = Learning)

Commits : 1 par feature, prefixe "wave2/sappho:"

---

## SOUS-AGENT 3 : ORION (Discovery + Progress)

Lis : docs/discovery/overview.md, docs/progress/overview.md,
      docs/knowledge/discovery-gap-pipeline.md, 01 S4.4-4.5, ADR S13/S18

Taches :
1. Discovery (multi-source, FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY)
   ResearchProvider (Exa/Tavily/You.com, optional, AD-1)
   Benin filtering (UserContext.region, data-driven)
2. Gap analysis (Progress skill_states + Knowledge sources)
3. Progress (evidence model, sole-producer F-07)
   ProgressEvidenceCreated + SkillStateChanged (producer = Progress)
4. Dashboards (G2, ChartSpec), trajectories, causal analysis
5. skill_recompute jobs (S jobs, AD-8)
6. Events : ProgressEvidenceCreated, SkillStateChanged,
   DiscoveryItemCreated

Commits : 1 par feature, prefixe "wave2/orion:"

---

## SOUS-AGENT 4 : VECTOR (Scientific + Artifacts)

Lis : docs/scientific-engine/engineering-intelligence-layer.md (S1-29),
      docs/artifacts/overview.md, docs/artifacts/infographic-multi-resource.md,
      docs/ai/providers/agnes-image.md, 01 S3.2/S4.6

Taches :
1. ProblemIR + Quantity + Unit (engineering-core)
2. 5-stage validation
3. Method Registry (5 seed), Solver Registry (5 seed),
   Verification Registry (5 seed), Code Registry (EC2 + BAEL)
4. SymPy adapter (Beam 2D/3D, matrices)
5. Math solver + RDM beam + Metre engine
6. Artifact Hub (preview + export PDF/DOCX/PPTX/XLSX/PNG/TXT)
7. Infographic multi-resource (AntV + Agnes Image + Exa/Tavily)
8. R2 upload + presigned URLs
9. Events : ArtifactGenerated (producer = Artifact, post-R2 F-06)

Commits : 1 par feature, prefixe "wave2/vector:"

---

## SOUS-AGENT 5 : ECHIDNA (Integrations + Notifications)

Lis : docs/integrations/overview.md, docs/integrations/composio.md,
      01 S4.7, 04 S3.4

Taches :
1. Composio integration (tool discovery, connected accounts, auth)
   PAS un AI provider (S33)
2. OneSignal (server + local split, anti-double-push)
3. Automations (Cron -> dispatcher -> jobs)
4. Events : JobCompleted (consumer)

Commits : prefixe "wave2/echidna:"

---

## SOUS-AGENT 6 : HYPATIYAS (Focus Mode + DPC)

Lis : docs/focus-mode/spec.md (S0-15), 04 S4, OQ-17

Taches :
1. FocusController (in-app timer + Pomodoro + blocklist)
2. FocusControllerDpc (setPackagesSuspended, API 29+, DPC)
3. DpcAdapter (custom native module, Foundation)
4. Boot receiver (crash/reboot recovery)
5. FocusSessionBilan (SSoT, G-H1)
6. 13 test scenarios (spec S13)

Commits : prefixe "wave2/hypatias:"

---

## Quand les 6 sont finis
- Chaque module : tsc + tests + events + jobs passent
- Cross-module : events flow (AD-9), no cross-join (03 S5.4)
- main buildable
