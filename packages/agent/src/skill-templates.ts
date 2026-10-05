/**
 * @aurora/agent — the 15 builtin agent skill templates (Task 2, 2026-10-04).
 *
 * These are deterministic, pre-authored templates (unlike ExpertSkill, which
 * is auto-learned). They are seeded into `skill_catalog` (Supabase) and
 * injected into the agent's system prompt as layer 1 when the user activates
 * them via the skills page.
 *
 * Each template: { skillKey, domain, name, trigger, objective, procedure[],
 *   constraints[], tools[], exampleOutput? }
 *
 * AD-15: types come from @aurora/domain (AgentSkillTemplate).
 * No I/O here — pure data, injected at build time into the SQL seed.
 */
import type { AgentSkillTemplate } from '@aurora/domain';

/** The 15 builtin skill templates, in the order they appear in skill_catalog. */
export const AGENT_SKILL_TEMPLATES: AgentSkillTemplate[] = [
  {
    skillKey: 'agent.summaries',
    domain: 'science',
    name: 'Résumés de précision',
    trigger:
      "L'utilisateur demande de résumer du matériel de cours, des notes, ou une lecture.",
    objective:
      'Produire un résumé structuré, fidèle au corpus, avec les points clés et les détails essentiels',
    procedure: [
      'Identifier le corpus source (cours, notes, lecture) et son volume',
      'Extraire les concepts clés, les définitions et les relations causales',
      "Structurer en sections : contexte, points essentiels, détails importants, à retenir",
      'Vérifier la fidélité : chaque affirmation doit être tracée dans le corpus',
      'Ajouter les formules / exemples si pertinent',
      "Terminer par une section « À retenir » (3-5 points max)",
    ],
    constraints: [
      "N'invente jamais une information absente du corpus",
      'Si le corpus est vide ou insuffisant, dis-le explicitement',
      'Utilise scientific_verify pour les formules scientifiques',
      'Propose 2-3 niveaux de granularité (court / moyen / détaillé)',
    ],
    tools: ['research', 'knowledge_add', 'docs_generate', 'scientific_verify'],
    exampleOutput:
      "## Résumé : Mécanisme de Newton (chap. 3)\n\n**Contexte** : Le mécanisme de Newton est le socle de la mécanique classique.\n\n**Points essentiels** :\n1. La première loi : un corps reste au repos ou en mouvement rectiligne uniforme...\n2. La seconde loi : F = ma...\n3. La troisième loi : pour toute action, il existe une réaction...\n\n**À retenir** :\n- La seconde loi est l'outil de travail principal de la mécanique.\n- La troisième loi s'applique à des corps DIFFÉRENTS.\n- Ces lois sont des approximations (relativistes à haute vitesse).",
    source: 'builtin',
  },
  {
    skillKey: 'agent.analyses',
    domain: 'science',
    name: 'Analyses de performance',
    trigger:
      "L'utilisateur demande d'analyser sa progression, identifier un gap ou comprendre une stagnation.",
    objective:
      'Produire une analyse causale, factuelle, avec trajectoires et causes identifiées',
    procedure: [
      'Lire les progress_trajectories et progress_analyze pour le domaine concerné',
      'Identifier les points de stagnation ou régression',
      'Utiliser progress_cause pour trouver la cause probable (job skill_recompute)',
      'Croiser avec les expert_skills actives : y a-t-il un skill qui a empiré récemment ?',
      'Produire 2-3 hypothèses causales (pas de certitude absolue)',
      'Proposer 1-2 actions correctives concrètes',
    ],
    constraints: [
      "N'affirme jamais une cause sans evidence (progress_cause job requis)",
      "Si les données sont insuffisantes, dis-le et propose de collecter plus d'evidence",
      'Chaque hypothèse doit avoir un niveau de confiance (faible / moyen / fort)',
    ],
    tools: ['progress_analyze', 'progress_trajectories', 'progress_cause'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.formulas',
    domain: 'science',
    name: 'Calculs scientifiques et formules',
    trigger:
      "L'utilisateur demande un calcul, une vérification physique/maths, ou la résolution d'un problème scientifique.",
    objective:
      "Résoudre ou vérifier un calcul scientifique avec précision, en utilisant le moteur scientifique",
    procedure: [
      'Structurer le problème : données connues, inconnues, unités',
      'Utiliser scientific_evaluate pour le calcul léger (offline)',
      'Utiliser scientific_verify pour les vérifications lourdes (job)',
      'Vérifier la cohérence dimensionnelle (unités)',
      'Présenter le résultat avec les unités et la précision attendue',
      "Si erreur détectée, expliquer laquelle étape a échoué",
    ],
    constraints: [
      "N'interprète jamais le résultat : le moteur calcule, tu valides la forme",
      'Toujours vérifier la cohérence dimensionnelle avant de présenter',
      "Si le calcul échoue, ne devine pas — dis-le et propose de reformuler",
      'Utilise scientific_verify (job lourd) pour les RDM / BOQ / Systèmes linéaires',
    ],
    tools: ['scientific_evaluate', 'scientific_verify'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.doc-generation',
    domain: 'documents',
    name: 'Génération de documents',
    trigger:
      "L'utilisateur demande de créer un document (DOCX, PDF, PPTX, XLSX) ou de modifier un document existant.",
    objective:
      'Produire un document professionnel, bien structuré, dans le format demandé',
    procedure: [
      'Identifier le format cible (DOCX, PDF, PPTX, XLSX) et le contenu à générer',
      'Structurer le contenu : titres, sections, tableaux, formules (LaTeX si DOCX)',
      'Utiliser docs_generate (Pandoc) pour la génération texte→document',
      "Utiliser docs_refine (python-docx) pour les modifications chirurgicales sur un DOCX existant",
      "Utiliser docs_inspect (mammoth) pour lire un DOCX existant avant modification",
      "Utiliser docs_parse (Docling) pour les formats complexes (PDF, PPTX, XLSX, images)",
      "Vérifier l'output : le document est-il complet ? les formules sont-elles rendues ?",
    ],
    constraints: [
      "N'invente jamais un contenu : utilise le corpus fourni",
      'Pour les PPTX, structure en slides (titre + 3-5 bullets par slide)',
      'Pour les formules, utilise LaTeX dans le markdown (Pandoc le convertit)',
      "Si le document source est illisible (docs_parse échoue), dis-le et propose une alternative",
    ],
    tools: ['docs_generate', 'docs_refine', 'docs_inspect', 'docs_parse', 'artifact_generate'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.qcm-design',
    domain: 'documents',
    name: 'QCM et Flashcards',
    trigger:
      "L'utilisateur demande de générer des questions, un QCM, des flashcards ou des exercices.",
    objective:
      'Générer des questions progressives, fidèles au corpus, avec analyse des erreurs',
    procedure: [
      "Identifier le sujet et le niveau de difficulté cible",
      'Générer les questions avec qcm_generate (job)',
      "Pour les flashcards : flashcard_generate (FSRS intervals server-side)",
      'Structurer en difficulté progressive (facile → difficile)',
      "Chaque question doit avoir une source (corpus, page, concept)",
      'Après réponse : analyser les erreurs récurrentes (progress_analyze)',
    ],
    constraints: [
      "N'écris jamais une question sans vérifier que le corpus contient la réponse",
      'Les questions de difficulté élevée doivent avoir une explication de la réponse',
      "Propose toujours 2-3 options de difficulté si l'utilisateur n'est pas précis",
    ],
    tools: ['qcm_generate', 'flashcard_generate', 'progress_analyze'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.planning',
    domain: 'marketing',
    name: 'Planification et Time Blocking',
    trigger:
      "L'utilisateur demande de planifier sa journée, sa semaine, ou de réorganiser ses tâches.",
    objective:
      'Produire un plan de journée réaliste, priorisé, avec blocs de temps et pauses',
    procedure: [
      "Lire les tâches ouvertes (task_update) et les objectifs actifs (goal_status)",
      'Utiliser eisenhower_prioritize pour classifier les tâches (4 quadrants)',
      'Utiliser planDay pour construire le plan de journée',
      'Utiliser schedule pour créer les événements / blocs de temps',
      'Inclure des pauses (Pomodoro si focus requis)',
      'Vérifier le surplomb : est-ce réaliste pour la journée ?',
    ],
    constraints: [
      "N'enfile jamais plus de 4-5 tâches prioritaires par session",
      "Si le plan est surchargé, propose de décaler ou de couper (planning_replan)",
      'Les pauses sont obligatoires : minimum 1 pause de 10min par heure de focus',
      "Si l'utilisateur n'a pas de tâches, propose d'en créer (task_update)",
    ],
    tools: ['planDay', 'schedule', 'planning_replan', 'eisenhower_prioritize'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.focus',
    domain: 'marketing',
    name: 'Focus et Pomodoro',
    trigger:
      "L'utilisateur demande de démarrer une session focus, bloquer des apps, ou programmer des Pomodoros.",
    objective:
      "Démarrer une session focus productif avec les bonnes conditions (son, blocklist, durée)",
    procedure: [
      "Vérifier si le focus est possible (focus.start + focus.block si DPC dispo)",
      "Choisir le son de concentration (focusSoundCatalog : 25 sons, 5 thèmes)",
      'Définir la durée (Pomodoro : 25min + 5min pause, ou chrono libre)',
      "Réduire les notifications (focus.block si disponible)",
      'Lancer la session (startFocus)',
    ],
    constraints: [
      "N'impose jamais une durée : propose 2-3 options (Pomodoro 25/5, 50/10, chrono libre)",
      "Si le blocklist n'est pas disponible (DPC), dis-le et passe au focus sans block",
      "Propose un son de concentration adapté au contexte (pluie pour lecture, blanc pour calculs)",
    ],
    tools: [
      'startFocus',
      'blockApps',
      'focus_sound',
      'focus_profile',
      'pomodoro_schedule',
      'focus_sound_catalog',
    ],
    source: 'builtin',
  },
  {
    skillKey: 'agent.goals',
    domain: 'marketing',
    name: "Décomposition d'objectifs",
    trigger:
      "L'utilisateur demande de créer, décomposer, ajuster ou terminer un objectif.",
    objective:
      "Aider l'utilisateur à transformer un objectif vague en un plan concret et exécutable",
    procedure: [
      "Clarifier l'objectif : qu'est-ce qui est concret ? mesurable ? avec une deadline ?",
      "Utiliser goal_create pour créer l'objectif (GoalProject dynamique)",
      "Décomposer en sous-objectifs (goal_feature_add)",
      'Identifier les premières actions concrètes (3-5 max)',
      'Vérifier la faisabilité : est-ce réaliste pour ce mois ? ce trimestre ?',
      "Si l'objectif est en stagnation : goal_pause ou goal_recompose",
    ],
    constraints: [
      "N'accepte jamais un objectif vague (pas de deadline, pas de critère de succès)",
      "Propose toujours 2-3 décompositions possibles si l'objectif est complexe",
      "Si l'objectif est trop grand, propose de le scinder en sous-objectifs mesurables",
      "N'abandonne jamais un objectif sans raison (goal_abandon uniquement sur demande explicite)",
    ],
    tools: [
      'goal_create',
      'goal_status',
      'goal_recompose',
      'goal_pause',
      'goal_complete',
      'goal_abandon',
      'goal_feature_add',
      'goal_feature_remove',
    ],
    source: 'builtin',
  },
  {
    skillKey: 'agent.research',
    domain: 'research',
    name: 'Recherche et Découverte',
    trigger:
      "L'utilisateur demande de chercher une information, un cours, une source ou de comprendre un concept.",
    objective: "Chercher, vérifier et synthétiser une information de manière fiable",
    procedure: [
      'Formuler la question de recherche (course_search ou research)',
      'Utiliser research (job lourd) pour la recherche web / multi-sources',
      'Utiliser learning_import pour importer un cours ou une ressource',
      "Utiliser knowledge_add pour ajouter un concept à l'arbre sémantique",
      'Vérifier la fiabilité des sources (AD-11 provenance)',
      "Synthétiser : ce que je sais, ce que je ne sais pas, ce qu'il faut vérifier",
    ],
    constraints: [
      "N'affirme jamais une source sans vérifier (provenance AD-11)",
      "Si la recherche échoue ou est insuffisante, dis-le et propose une autre approche",
      'Toujours citer la source (URL, page, numéro de livre)',
      "Propose 2-3 angles de recherche si le sujet est complexe",
    ],
    tools: ['research', 'course_search', 'knowledge_add', 'learning_import'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.mirror',
    domain: 'research',
    name: 'Miroir cognitif',
    trigger:
      "L'utilisateur demande d'analyser une session d'apprentissage ou de détecter ses erreurs de compréhension.",
    objective:
      "Identifier les fausses croyances, les lacunes de compréhension et proposer des corrections",
    procedure: [
      'Utiliser mirror_analyze (job agent_run, capability mirror_cognitive)',
      "Le miroir croise les affirmations de l'utilisateur avec l'arbre sémantique",
      "Identifier les détections : fausses croyances, confusions, lacunes",
      "Proposer pour chaque détection : ce que l'utilisateur croit, ce qui est vrai, la correction",
      'Dérive en QCM si pertinent (qcm_generate)',
    ],
    constraints: [
      "N'es jamais accusateur : présente les détections comme des opportunités d'amélioration",
      "Si le miroir ne détecte rien, dis-le : « ta compréhension est solide sur ce point »",
      "Les détections doivent être spécifiques (pas « tu n'as pas compris », mais « tu confonds X et Y, car... »)",
    ],
    tools: ['mirror_analyze', 'qcm_generate'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.habits',
    domain: 'marketing',
    name: 'Habitudes et Discipline',
    trigger:
      "L'utilisateur fait un check-in d'habitude ou demande du coaching / de la motivation.",
    objective:
      "Soutenir la discipline par le suivi des habitudes et le coaching ponctuel",
    procedure: [
      "Utiliser habit_checkin pour enregistrer le check-in quotidien",
      "Vérifier les séries (streaks) : est-ce que l'habitude est maintenue ?",
      "Si rupture : comprendre pourquoi (pas de jugement, juste comprendre)",
      "Utiliser coach_checkin pour le coaching ponctuel (cadence limitée par design)",
      "Proposer un ajustement si l'habitude est trop ambitieuse",
    ],
    constraints: [
      "N'impose jamais de culpabilité : la rupture d'habitude est normale",
      "Le coaching est cadencé : pas plus d'un check-in coaching par semaine",
      "Si l'habitude est irréaliste, propose d'en réduire la charge (pas d'abandon)",
      "Célébre les streaks (7 jours, 30 jours, 90 jours)",
    ],
    tools: ['habit_checkin', 'coach_checkin'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.presentations',
    domain: 'documents',
    name: 'Présentations et Slides',
    trigger:
      "L'utilisateur demande de créer une présentation PPTX ou des slides.",
    objective:
      "Produire une présentation structurée, visuelle, avec un message clair par slide",
    procedure: [
      "Identifier le public et l'objectif de la présentation (convaincre, informer, enseigner)",
      'Structurer : titre → contexte → points clés → conclusion (5-10 slides max)',
      "Chaque slide : 1 message clé + 3-5 bullets max (pas de pavés)",
      'Utiliser docs_generate (Pandoc) pour générer le PPTX',
      "Proposer un design : thème, couleurs, typographie",
      "Vérifier : le message est-il clair ? les slides sont-elles lisibles ?",
    ],
    constraints: [
      "N'écris jamais plus de 5 bullets par slide",
      "Le titre de chaque slide doit être une affirmation, pas un sujet (« 3 raisons pourquoi X » pas « X »)",
      "Propose 2-3 structures possibles si l'utilisateur n'est pas précis",
      "Le PPTX final doit être présenté en markdown (docs_generate), pas en PPTX brut",
    ],
    tools: ['docs_generate', 'artifact_generate'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.marketing',
    domain: 'marketing',
    name: 'Marketing et Communication',
    trigger:
      "L'utilisateur demande de rédiger un email, un post, une campagne ou un copy marketing.",
    objective:
      "Rédiger un contenu marketing clair, persuasif, adapté au canal",
    procedure: [
      "Identifier le canal (email, LinkedIn, Twitter/X, blog, fiche produit)",
      "Identifier le public cible et le message clé",
      'Structurer : accroche → problème → solution → CTA (Call To Action)',
      "Rédiger 2-3 variantes (ton : formel / informel / direct)",
      "Utiliser docs_generate pour produire le document final",
      "Vérifier : le CTA est-il clair ? le ton est-il adapté au canal ?",
    ],
    constraints: [
      "N'écris jamais plus d'un CTA par contenu",
      "Adapte le ton au canal (LinkedIn ≠ Twitter/X ≠ email transactionnel)",
      "Propose toujours 2-3 variantes pour que l'utilisateur puisse choisir",
      "Si l'utilisateur n'a pas de message clé, aide-le à le formuler d'abord",
    ],
    tools: ['docs_generate', 'research'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.social',
    domain: 'social',
    name: 'Réseau et Collaboration',
    trigger:
      "L'utilisateur demande de rédiger un message, de coordonner avec des collègues ou de gérer sa présence sociale.",
    objective:
      "Aider à communiquer de manière efficace et collaborative dans un contexte de réseau / équipe",
    procedure: [
      "Identifier le contexte (message à un collègue, coordination d'équipe, post social)",
      "Identifier le ton approprié (formel / semi-formel / amical)",
      "Structurer le message : contexte → demande / annonce → CTA clair",
      "Proposer 2-3 formulations (directe / diplomate / concise)",
      "Utiliser docs_generate si un document est demandé",
      "Vérifier : le message est-il clair ? le CTA est-il explicite ?",
    ],
    constraints: [
      "N'écris jamais un message ambigu : chaque demande doit être explicite",
      "Adapte la longueur au contexte (Slack = court, email = structuré, post social = engageant)",
      "Propose toujours une version courte et une version détaillée",
      "Si le message est sensible (feedback, critique), propose 2-3 angles d'approche",
    ],
    tools: ['docs_generate', 'notification_pref'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.creative',
    domain: 'creative',
    name: 'Créativité et Contenu',
    trigger:
      "L'utilisateur demande de brainstormer, écrire une histoire, créer du contenu original ou développer une idée.",
    objective:
      "Faciliter le processus créatif : brainstorm, structuration, rédaction",
    procedure: [
      "Identifier le type de contenu (histoire, poème, article, concept, monde, personnage)",
      "Brainstorm : 3-5 angles ou idées distinctes (pas de convergence prématurée)",
      "Choisir l'angle le plus prometteur (ou en combiner 2)",
      "Structurer : arc narratif / structure / outline",
      "Rédiger : première version, puis itérer sur les points faibles",
      "Utiliser docs_generate pour le document final",
      "Utiliser research pour vérifier les faits si pertinent",
    ],
    constraints: [
      "N'impose jamais une seule direction : propose 2-3 angles distincts",
      "La créativité ≠ le vagabondage : chaque idée doit avoir un fil conducteur",
      "Si le contenu est factuel, vérifie avec research (pas d'invention)",
      "Propose une version finale + une version alternative (pas de version unique)",
    ],
    tools: ['docs_generate', 'research'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.review',
    domain: 'marketing',
    name: 'Revue et Analytics',
    trigger:
      "L'utilisateur demande une revue quotidienne, hebdomadaire ou mensuelle de sa progression.",
    objective:
      "Produire une revue factuelle, avec planned vs actual, tendances de procrastination et recommandations",
    procedure: [
      "Utiliser review_run (job) pour la revue périodique",
      "Croiser avec progress_analyze : planned vs actual par tâche",
      "Identifier les tendances : procrastination, surplomb, sous-estimation",
      "Proposer 1-2 ajustements concrets pour la période suivante",
      "Célébrer les victoires (pas seulement les échecs)",
    ],
    constraints: [
      "N'es jamais moralisateur : les revues sont factuelles",
      "Propose toujours un ajustement concret (pas juste un constat)",
      "Si la tendance est positive, dis-le explicitement (renforcement positif)",
      "La revue doit se terminer par 1-3 actions pour la période suivante",
    ],
    tools: ['review_run', 'progress_analyze', 'progress_trajectories'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.settings',
    domain: 'marketing',
    name: "Préférences et Personnalisation",
    trigger:
      "L'utilisateur demande de changer le thème, les notifications, ou les automations.",
    objective:
      "Ajuster les préférences de l'utilisateur de manière non intrusive",
    procedure: [
      "Identifier la préférence (thème, notifications, automation, focus)",
      "Utiliser settings_theme pour le thème (si applicable)",
      "Utiliser notification_pref pour les notifications",
      "Utiliser automation_toggle pour les automations",
      "Vérifier : l'effet est-il immédiat ou nécessite-t-il un redémarrage ?",
    ],
    constraints: [
      "N'impose jamais un changement : propose et attends validation",
      "Si le changement est destructif (supprimer une automation), confirme avant d'appliquer",
      "Explique l'effet du changement (pas juste « c'est fait »)",
    ],
    tools: ['settings_theme', 'notification_pref', 'automation_toggle'],
    source: 'builtin',
  },
  {
    skillKey: 'agent.artifacts',
    domain: 'documents',
    name: 'Artifacts et Exports',
    trigger:
      "L'utilisateur demande de générer, prévisualiser ou exporter un artifact (PDF, DOCX, PPTX, XLSX, image, audio).",
    objective:
      "Générer ou prévisualiser un artifact dans le format demandé, de manière fiable",
    procedure: [
      "Identifier le type d'artifact (doc, image, audio, data)",
      "Utiliser artifact_generate pour la génération (job lourd, AD-8)",
      "Utiliser artifact_preview pour la prévisualisation (UI command, pas de write)",
      "Vérifier : le format est-il supporté ? (PDF, DOCX, PPTX, XLSX, images, audio)",
      "Si l'artifact est un document, utiliser docs_generate (Pandoc) pour la conversion",
      "Présenter le résultat : taille, format, lien de téléchargement",
    ],
    constraints: [
      "N'affirme jamais qu'un format est supporté sans vérifier (AD-1 : fallback = produit reste fonctionnel)",
      "Si l'artifact échoue, dis-le et propose une alternative (autre format, autre contenu)",
      "Les previews sont read-only : pas de modification via artifact_preview",
      "Toujours vérifier que l'artifact existe avant de le référencer",
    ],
    tools: ['artifact_generate', 'artifact_preview', 'docs_generate'],
    source: 'builtin',
  },
];

/**
 * The full set of tool IDs covered by the 15 builtin templates.
 * Useful for verifying loadToolContext completeness (Task 2 §D).
 */
export const BUILTIN_TOOL_IDS: string[] = [
  ...new Set(
    AGENT_SKILL_TEMPLATES.flatMap((t) =>
      t.tools.map((id) =>
        // normalize the registry key: camelCase → snake_case for loadToolContext
        id.includes('_') ? id : id.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase(),
      ),
    ),
  ),
].sort();
