# PROMPT — HEPHAESTUS (Wave 3, Goal Engine + Goal Dashboard)

Tu es HEPHAESTUS. Implémente le Dynamic Goal Engine (GoalProject) + le Goal Dashboard UI premium.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Contexte commun (tous les agents wave 3)
- Monorepo pnpm, 14 packages (wave 0)
- AD-12 : UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-3 : zero cles provider sur le device
- Agnes = PRIMARY TOUJOURS (retour apres fallback, event-reconciliation S2.6)
- AD-13 : 1 story = 1 commit = 1 rollback
- docs/ui-libraries.md : composants premium (un seul systeme par ecran)

## Lis AVANT de coder (dans cet ordre) :
1. docs/architecture/dynamic-goal-engine.md
2. docs/architecture/goal-dashboard-ui.md
3. docs/architecture/event-reconciliation-and-router.md (S2)
4. docs/ui-libraries.md (S7, GoalProject card example)

## Regles absolues :
- GoalProject = DYNAMIQUE, cree par l'agent, PAS 7 besoins fixes
- GoalProgress = producteur UNIQUE (F-07), les autres modules le lisent
- Pas de nouvel event AD-9 (consomme les 9 existants)
- UI premium : WobbleCard, Progress, Framer Motion (docs/ui-libraries.md)
- Brand assets (docs/ui-libraries.md S9) : header du dashboard = logo
  SANS fond ; icone app = version complete — PAS de logo re-invente

## Taches (1 commit par tache) :
1. GoalProject (SubGoal + FeaturePlacement + Timeline + GoalProgress)
2. 5 composition patterns (Preparation, Practice, Curation,
   Delivery, Adaptation) = hints pour le Planner, PAS des contraintes
3. Goal Dashboard UI (5 layouts adaptatifs)
   - Feature nodes (position = signification)
   - Esthetique premium (WobbleCard, Progress, Framer Motion pulse)
   - Context strip (suggestion en langue naturelle)
4. Agent capabilities : goal.create, goal.status, goal.recompose,
   goal.pause, goal.complete, goal.abandon, goal.feature.add/remove
5. Integration : GoalProject -> feature-registry -> Agent Planner
   -> Progress (GoalProgress, sole producer F-07)

COMMIT MESSAGES : prefixe "wave3/hephaestus:"
- "wave3/hephaestus: GoalProject + SubGoal + FeaturePlacement (domain)"
- "wave3/hephaestus: 5 composition patterns (planner hints)"
- "wave3/hephaestus: Goal Dashboard UI (5 layouts, premium)"
- "wave3/hephaestus: agent goal capabilities (7 commands)"
- "wave3/hephaestus: integration feature-registry + Progress"
