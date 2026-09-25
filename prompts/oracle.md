# PROMPT — ORACLE (Wave 3, Agent Kernel + Vercel AI SDK + Expert Skills)

Tu es ORACLE. Implémente le Agent Kernel complet (AD-12) + Vercel AI SDK + Expert Skills + Agnes router.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Contexte commun (tous les agents wave 3)
- Monorepo pnpm, 14 packages (wave 0)
- AD-12 : UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-3 : zero cles provider sur le device
- Agnes = PRIMARY TOUJOURS (retour apres fallback, event-reconciliation S2.6)
- Vercel AI SDK = packages/agent UNIQUEMENT (AD-1)
- AD-9 : vocabulaire de 9 events FERME (pas de 10e sans ADR)
- docs/ui-libraries.md : composants premium (un seul systeme par ecran)
- 1 story = 1 commit = 1 rollback (AD-13)

## Lis AVANT de coder (dans cet ordre) :
1. docs/agent/kernel.md (15 sections, 15 composants)
2. docs/ai/vercel-ai-sdk-integration.md
3. docs/agent/expert-skills-extensions.md
4. docs/ai/providers-and-routing.md (S9-12)
5. docs/architecture/event-reconciliation-and-router.md (S2.1-2.6)
6. docs/scientific-engine/engineering-intelligence-layer.md
7. .env.local (AGNES_API_KEY, GROQ_API_KEY, EXA, TAVILY, YOU, COMPOSIO)

## Regles absolues :
- AD-1 : Vercel AI SDK seulement dans packages/agent, jamais ailleurs
- AD-12 : le kernel est serveur (fn-agent-run), le device ne lit que AgentRunState
- Agnes = premier choix du router (S2.6 : alwaysFirst: true),
  fallback Workers AI (GLM-4.7 Flash, Gemma 4 26B, Nemotron 3 120B) puis Groq
- ZERO secret dans le code (grep CI le verifie)
- PAS de CopilotKit

## Taches (1 commit par tache) :
1. 15 composants du kernel (Intent, Context, Planner, Capability/Tool
   Registry, Permission, Confirmation, Model Router, Execution,
   Verification, Result, Memory, Observability, Error Recovery)
2. Vercel AI SDK (streamText, maxSteps, tools, useChat)
   - 8 tools : planDay, schedule, startFocus, blockApps, research,
     qcm_generate, mirror_analyze, scientific_verify
3. Router Agnes-PRIMARY (code du router, S2.6)
4. Expert Skills (4 extensions) :
   - Contrastive pairs (2 min)
   - Confidence decay (formule deterministe)
   - Hypotheses (fenetre 14 jours, fail-fast)
   - Cognitive-Drift Firewall (3 cycles min)
5. AgentRunState (streaming UI, 02 S4)
6. AgentActionEnvelope + NavigationIntent + UiStateCommand
   (kernel S15, command bus, PAS de React direct)
7. fn-agent-run (Edge Function, complete le stub de wave 0)

COMMIT MESSAGES : prefixe "wave3/oracle:"
- "wave3/oracle: kernel core (15 composants, intent -> memory)"
- "wave3/oracle: Vercel AI SDK + 8 tools"
- "wave3/oracle: Agnes-primary router (S2.6) + fallback"
- "wave3/oracle: expert skills (4 extensions)"
- "wave3/oracle: AgentRunState + command bus"
- "wave3/oracle: fn-agent-run complete"
