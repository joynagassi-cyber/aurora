# PROMPT — ACHILLES (Wave 0, Foundation / Monorepo + Domain Types)

Tu es ACHILLES. Creer le squelette du monorepo Aurora + tous les types de domaine.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Lires AVANT de coder (dans cet ordre) :
1. _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md
2. _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md
3. docs/architecture/contract-catalog.md
4. docs/architecture/data-ownership-matrix.md
5. docs/epics-stories.md (W0-E1 uniquement)
6. AI_RULES.md

## Regles absolues :
- AD-1 : aucun import de vendor dans packages/domain
- AD-15 : TOUTES les entites dans packages/domain (SSoT)
- AD-13 : one-writer-per-file
- Le code doit compiler (tsc --noEmit) avant commit
- 1 story = 1 commit = 1 rollback

## Taches (1 commit par tache) :

### Commit 1 : pnpm workspace
- Creer pnpm-workspace.yaml avec 14 packages :
  packages/domain, packages/data, packages/ui, packages/platform,
  packages/agent, packages/scientific-engine, packages/integrations,
  packages/engineering-core, packages/engineering-solvers,
  packages/engineering-adapters, packages/engineering-registry,
  apps/mobile, apps/server
- Chaque package : package.json + tsconfig.json (references vers domain)
- pnpm install passe

### Commit 2 : packages/domain — entites (40+ types)
- Productivity : Task, Event, Project, Goal, Milestone, Habit, Routine, Note, Resource, Decision, FocusSession, FocusAppRule, FocusNotificationPolicy, FocusCallPolicy, FocusSessionBilan
- Learning : Course, Subject, Skill, LearningSession, Review, LearningItem, FsrsState
- Knowledge : Source, Concept, Formula, Definition, Method, SemanticNode, SemanticBridge, SemanticTreeVersion, NodeState, SourceRef
- Progress : ProgressEvidence, ProgressSnapshot, SkillState, ProgressEvent, ProgressTrajectory, Gap
- Discovery : DiscoveryItem, DiscoverySource, DiscoveryScenario
- Artifact : Artifact, ArtifactFile
- Agent : ExpertSkill, AgentRun, JobQueue, JobLog
- Integrations : IntegrationsState, Automation, NotificationPreference
- Identity : UserContext
- Engineering : ProblemIR, Quantity, Unit, PhysicalDimension, MethodDefinition, SolverDefinition, VerificationRule, ProblemPattern, FormulaDefinition, CodeRegistryEntry, SolverResult
- Goal : GoalProject, SubGoal, FeaturePlacement, GoalProgress
- 9 evenements (payloads exacts, docs/architecture/data-event-job-catalog.md)
- Enveloppes : ApiEnvelope, AIResponseEnvelope, AppError
- Ports : ObjectStorage, AIProvider, KnowledgeBase, JobRunner, NotificationProvider, FocusController, ScientificEngine, ResearchProvider, IntegrationProvider, ArtifactProvider, DocumentScanner, OCRProvider, AudioArtifactProvider, TranscriptionProvider
- UI : FeatureDescriptor, AgentCapability, NavigationIntent, UiStateCommand, AgentActionEnvelope
- tsc --noEmit passe

### Commit 3 : ESLint boundary rules
- .eslintrc avec import/no-restricted-paths
- packages/domain n'importe RIEN
- packages/ui n'importe pas packages/data ni packages/platform
- apps/mobile/src ne peut pas importer des feature-siblings
- npm run lint passe

COMMIT MESSAGES :
"wave0/achilles: pnpm workspace (14 packages)"
"wave0/achilles: domain types (AD-15 SSoT, 40+ entities, 9 events, 10 ports)"
"wave0/achilles: ESLint boundary rules (AD-1, AD-2, AD-10)"
