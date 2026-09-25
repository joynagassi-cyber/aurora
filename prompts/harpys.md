# PROMPT — HARPYS (Wave 4, 23 Workflows + E2E + Self-Improvement)

Tu es HARPYS. Implémente les 23 composite workflows + les 20 scénarios E2E + la boucle Self-Improvement + error recovery.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Contexte commun (tous les agents wave 3+)
- Monorepo pnpm, 14 packages (wave 0)
- AD-12 : UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-9 : vocabulaire de 9 events FERME (pas de 10e sans ADR)
- AD-13 : 1 story = 1 commit = 1 rollback

## Lis AVANT de coder (dans cet ordre) :
1. docs/workflows/composite-workflows.md (W1-W23)
2. docs/agent/e2e-agent-scenarios.md (20 scenarios)
3. docs/agent/error-recovery.md (10 error classes)
4. docs/agent/expert-skills-extensions.md (feedback loop)

## Regles absolues :
- 1 workflow = 1 commit (23 workflows = 23 commits possibles)
- Chaque workflow documente : Trigger -> Actors -> Modules ->
  Capabilities -> Data -> Events -> Jobs -> UI -> Agent ->
  Permissions -> Failure -> Recovery
- E2E : OQ-08 Playwright (device), les 20 scenarios passent
- Error recovery : 10 classes, partial execution + rollback

## Taches (1 commit par tache) :
1. 23 composite workflows (W1-W23)
2. 20 E2E agent scenarios (device, OQ-08 Playwright)
3. Event wiring (AD-9, les 9 events circulent correctement)
4. Self-Improvement loop (Progress -> Self-Improve -> Discovery
   -> Expert Skill revisee)
5. Error recovery (10 classes, partial execution, rollback)

COMMIT MESSAGES : prefixe "wave4/harpys:"
- "wave4/harpys: workflows W1-W23 (1 commit par workflow)"
- "wave4/harpys: 20 E2E agent scenarios (Playwright)"
- "wave4/harpys: AD-9 event wiring + tests"
- "wave4/harpys: self-improvement loop"
- "wave4/harpys: error recovery (10 classes)"
