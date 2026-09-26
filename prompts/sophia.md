# PROMPT — SOPHIA (Wave 3, Ascent — Pedagogical Trajectory Engine)

Tu es SOPHIA. Implémente le module Ascent : le moteur de trajectoire pédagogique adaptatif.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Contexte commun (tous les agents wave 3)
- Monorepo pnpm, 14 packages (wave 0)
- AD-12 : UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-7 : single-writer (chaque module n'ecrit QUE ses tables)
- AD-9 : vocabulaire de 9 events FERME (pas de 10e sans ADR)
- AD-13 : 1 story = 1 commit = 1 rollback
- docs/ui-libraries.md : composants premium (un seul systeme par ecran)

## Lis AVANT de coder (dans cet ordre) :
1. docs/ascent/overview.md (22 sections, le concept complet)
2. docs/ascent/implementation.md (guide d'implementation + erreurs/edges)
3. docs/architecture/dynamic-goal-engine.md (GoalProject, Ascent = couche au-dessus)
4. docs/agent/kernel.md (S12, Ascent = capability du kernel, pas un agent separe)
5. docs/progress/overview.md (SkillState, ProgressEvidence)
6. docs/learning/overview.md (QCM, flashcards, mirror)
7. docs/knowledge/overview.md (tree, concepts, formulas)

## Regles absolues :
- Ascent = SERVER-SIDE (AD-12, comme Agent Kernel), package neuf packages/ascent
- Ascent lit Knowledge/Progress/Discovery (public views), PAS ecriture
- Ascent emet LearningCommand (domain command, AD-7), PAS ecriture dans les tables Learning
- Ascent ne fait PAS de nouvel event AD-9 (consomme les 6 existants, voir implementation.md)
- 80/20 : 1 table JSONB (ascent_paths) pour demarrer, PAS 4 tables separees
- PAS de 2e LLM pedagogique (Ascent = deterministe, le LLM explique)
- PAS de Graphiti/Zep (SourceRef + pgvector suffit, AD-11)
- PAS de WebGL (AntV + KaTeX + images)
- Brand assets (docs/ui-libraries.md S9) : ecrans Slide-Ascent
  (header / centre de page / empty states) = logo SANS fond
  (assets/aurora_icon_a_integre_dans_l'applciation.png) ;
  icone app = version complete — PAS de logo re-invente

## Taches (1 commit par tache) :
1. packages/domain/ascent.ts : AscentLearningIR, AscentStep,
   AscentActivity, AscentAdaptation, LearnerBaseline, DepthLevel
   (AD-15 SSoT, 1 fichier, ~200 lignes, types exacts = overview.md S6)
2. packages/ascent/ : serveur, 6 fichiers
   - path-builder.ts (construit le LearningPath)
   - adapter.ts (adapte sur ProgressEvidenceCreated)
   - baseline.ts (calcule LearnerBaseline depuis Progress)
   - depth.ts (selection Quick/Standard/Deep)
   - read-do-prove.ts (sequencing, framework pas rigide)
   - source-hierarchy.ts (A>B>C>D, D ne remplace jamais A)
3. Migration SQL + surface de sync (1 commit, fichiers exacts, cf
   docs/ascent/implementation.md "SQL Migration + Sync Surface") :
   a. supabase/migrations/0015_ascent.sql (prochain numero libre apres 0014) :
      CREATE TABLE ascent_paths (JSONB, schema du doc)
      + ENABLE/FORCE ROW LEVEL SECURITY + policy user_isolation
      (USING (user_id = auth.uid()), pattern 0008)
      + AUCUN USING(true) injustifie (check-rls (b) reste vert)
   b. powersync/relay.sql : + vue v_ascent_scope
      (security_invoker=on, SELECT * FROM ascent_paths,
      PAS de JOIN inter-module — check-view-joins reste vert)
   c. powersync/schema.json :
      + mirrorTables : "ascent": ["ascent_paths"]
      + scopes : {name:"ascent", ownerModule:"Ascent",
                 type:"custom", sql:"SELECT * FROM v_ascent_scope"}
      + excludedFromMirror : RIEN (le mirror lecture seule est
      REQUIS pour Slide-Ascent offline — contrairement a expert_skills)
   d. Test d'intrusion RLS (user A ne lit pas user B, pattern MINERVA)
   e. APPLIQUER la migration sur le Supabase DEV avec le SUPABASE MCP
      (configure dans Claude Code par le user) :
      - Appliquer 0015_ascent.sql au projet dev VIA le MCP
        (PAS d'edits SQL manuels / dashboard — le MCP est le chemin d'ecriture)
      - Verifier apres application : table ascent_paths existe,
        RLS active (ENABLE + FORCE), policy user_isolation presente,
        vue v_ascent_scope existe
   NB : les migrations 0013/0014 existantes sont deja sur main ;
   si le Supabase dev les contient pas encore, les appliquer aussi
   via le meme MCP (0013 subtasks + 0014 cron placeholders).
4. Slide-Ascent UI (apps/mobile, 12 types de slides = palette, PAS sequence)
   Lit le LOCAL MIRROR de ascent_paths (offline, aucun SQL propre)
   Progressive disclosure (Level 1 = current+next seulement)
   Active Reading : 5 actions (Explain, Note, Flashcard, Visualize, "Je bloque")
   Depth badge + Source hierarchy badge (A/B/C/D)
   3 etats asynchrones sur tout (vide, chargement, erreur — ui-libraries.md Partie 3)
5. Agent Kernel integration :
   Context Builder lit AscentLearningIR
   Agent emet LearningCommand (generate_qcm, start_mirror)
   Ascent adapte sur events (ProgressEvidenceCreated, SkillStateChanged)
6. Tests : baseline accuracy, prerequisite enforcement, adaptation
   on evidence, depth selection, READ->DO->PROVE flexibility,
   source hierarchy, progressive disclosure, "Je bloque" flow,
   offline (mirror), RLS

## Rapport de fin OBLIGATOIRE
Mentionner explicitement dans le rapport de fin :
- "Migration 0015 appliquee via Supabase MCP : OUI / NON"
- Si OUI : resultats des 4 verifications (table / RLS / policy / vue)
- Si NON (MCP indisponible) : migration en attente, a appliquer par le user,
  signale en rouge dans le rapport

COMMIT MESSAGES : prefixe "wave3/sophia:"
- "wave3/sophia: domain types (AscentLearningIR + 6 types)"
- "wave3/sophia: path-builder + adapter + baseline + depth"
- "wave3/sophia: source-hierarchy + read-do-prove"
- "wave3/sophia: 0015_ascent.sql (table + RLS) + v_ascent_scope + schema.json (mirror lecture seule)"
- "wave3/sophia: Slide-Ascent UI (12 slide types + progressive disclosure)"
- "wave3/sophia: Agent Kernel integration + tests"
