-- =============================================================================
-- Aurora Migration 0019: User Skills + Skill Catalog (Task 1 + 2, 2026-10-04)
--
-- Two new tables:
--   skill_catalog : the global, curated skill catalog (public read, service_role write)
--                   Seeded with the 15 builtin agent skill templates (Task 2).
--   user_skills   : per-user activated skills (RLS-isolated, AD-3/AD-7)
--                   User can activate/deactivate catalog skills or create personal ones.
--
-- AD-3: no provider keys in the schema. RLS user-isolation enforced.
-- AD-7: single-writer — only the skills module writes user_skills.
-- =============================================================================

-- ─── skill_catalog : the global curated catalog ───────────────────────────
-- Public read (no RLS needed — no user_id column), service_role write only.
-- The Aurora team curates entries; the EF fn-skills manages the catalog via
-- service_role; the mobile app reads it via the publishable scope (public RLS
-- on this table).

CREATE TABLE skill_catalog (
  skill_key   text PRIMARY KEY,
  domain      text NOT NULL,
               -- 'science' | 'marketing' | 'social' | 'research' | 'documents' | 'creative'
  name        text NOT NULL,
  trigger_    text,
  objective   text,
  procedure   jsonb NOT NULL DEFAULT '[]'::jsonb,
  constraints jsonb NOT NULL DEFAULT '[]'::jsonb,
  tools       jsonb NOT NULL DEFAULT '[]'::jsonb,
  source      text NOT NULL DEFAULT 'builtin',
               -- 'builtin' | 'marketplace:<name>' | 'user-created'
  description text
);

-- Public read for ANY client that carries the project API key (the mobile
-- app reads the catalog with the publishable scope, AD-3 — it does not
-- require a user JWT to browse the curated catalog). service_role has full
-- write access (EF fn-skills curates the catalog).
ALTER TABLE skill_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY skill_catalog_public_read ON skill_catalog
  FOR SELECT TO anon, authenticated USING (true);
-- Rationale: skill_catalog is a global public registry curated by the Aurora
-- team via service_role. No user dimension. Read is open to all authenticated
-- users (AD-3: no per-user scoping needed); write is service_role-only.
CREATE POLICY skill_catalog_service_write ON skill_catalog
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ─── user_skills : per-user activated skills (RLS-isolated) ───────────────
-- The user's active skill set. The EF fn-skills upserts rows; the mobile
-- app reads its own rows. The agent bootstrap loads active skills to inject
-- them into the system prompt (layer 1).

CREATE TABLE user_skills (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  skill_key  text NOT NULL,
             -- 'builtin:agent.summaries' | 'user:<random>' | 'marketplace:<name>:<key>'
  domain     text NOT NULL,
  name       text NOT NULL,
  trigger_   text,
  objective  text,
  procedure  jsonb NOT NULL DEFAULT '[]'::jsonb,
  constraints jsonb NOT NULL DEFAULT '[]'::jsonb,
  tools      jsonb NOT NULL DEFAULT '[]'::jsonb,
  source     text NOT NULL DEFAULT 'user-created',
             -- 'builtin' | 'marketplace:<name>' | 'user-created'
  active     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, skill_key)
);

ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_skills_user_isolation ON user_skills
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_skills_service_role ON user_skills
  FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Rationale: user_skills is written by the EF fn-skills with the service key
-- (PostgREST upsert); the user row is self-contained and RLS-isolated for the
-- user role via user_skills_user_isolation above. service_role bypass is
-- scoped to the EF only (AD-7: identity from the Bearer token, EF acts as
-- the single server-side writer).
CREATE TRIGGER user_skills_updated BEFORE UPDATE ON user_skills
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_user_skills_user_active ON user_skills (user_id, active);

-- ─── Seed : les 15 skills builtin (Task 2) ──────────────────────────────────

INSERT INTO skill_catalog (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source)
VALUES
(
  'agent.summaries', 'science',
  'Résumés de précision',
  "L'utilisateur demande de résumer du matériel de cours, des notes, ou une lecture.",
  'Produire un résumé structuré, fidèle au corpus, avec les points clés et les détails essentiels',
  '[
    "Identifier le corpus source (cours, notes, lecture) et son volume",
    "Extraire les concepts clés, les définitions et les relations causales",
    "Structurer en sections : contexte, points essentiels, détails importants, à retenir",
    "Vérifier la fidélité : chaque affirmation doit être tracée dans le corpus",
    "Ajouter les formules / exemples si pertinent",
    "Terminer par une section ''À retenir'' (3-5 points max)"
  ]'::jsonb,
  '[
    "n''invente jamais une information absente du corpus",
    "si le corpus est vide ou insuffisant, dis-le explicitement",
    "utilise scientific_verify pour les formules scientifiques",
    "propose 2-3 niveaux de granularité (court / moyen / détaillé)"
  ]'::jsonb,
  '["research", "knowledge_add", "docs_generate", "scientific_verify"]'::jsonb,
  'builtin'
),
(
  'agent.analyses', 'science',
  'Analyses de performance',
  "L'utilisateur demande d'analyser sa progression, identifier un gap ou comprendre une stagnation.",
  'Produire une analyse causale, factuelle, avec trajectoires et causes identifiées',
  '[
    "Lire les progress_trajectories et progress_analyze pour le domaine concerné",
    "Identifier les points de stagnation ou régression",
    "Utiliser progress_cause pour trouver la cause probable (skill_recompute job)",
    "Croiser avec les expert_skills actives : y-a-t-il un skill qui a empiré récemment ?",
    "Produire 2-3 hypothèses causales (pas de certitude absolue)",
    "Proposer 1-2 actions correctives concrètes"
  ]'::jsonb,
  '[
    "n''affirme jamais une cause sans evidence (progress_cause job requis)",
    "si les données sont insuffisantes, dis-le et propose de collecter plus d''evidence",
    "chaque hypothèse doit avoir un niveau de confiance (faible / moyen / fort)"
  ]'::jsonb,
  '["progress_analyze", "progress_trajectories", "progress_cause"]'::jsonb,
  'builtin'
),
(
  'agent.formulas', 'science',
  'Calculs scientifiques et formules',
  "L'utilisateur demande un calcul, une vérification physique/maths, ou la résolution d'un problème scientifique.",
  'Résoudre ou vérifier un calcul scientifique avec précision, en utilisant le moteur scientifique',
  '[
    "Structurer le problème : données connues, inconnues, unités",
    "Utiliser scientific_evaluate pour le calcul léger (offline)",
    "Utiliser scientific_verify pour les vérifications lourdes (job)",
    "Vérifier la cohérence dimensionnelle (unités)",
    "Présenter le résultat avec les unités et la précision attendue",
    "Si erreur détectée, expliquer laquelle étape a échoué"
  ]'::jsonb,
  '[
    "n''interprète jamais le résultat : le moteur calcule, tu valides la forme",
    "toujours vérifier la cohérence dimensionnelle avant de présenter",
    "si le calcul échoue, ne devine pas — dis-le et propose de reformuler",
    "utilise scientific_verify (job lourd) pour les RDM / BOQ / Systèmes linéaires"
  ]'::jsonb,
  '["scientific_evaluate", "scientific_verify"]'::jsonb,
  'builtin'
),
(
  'agent.doc-generation', 'documents',
  'Génération de documents',
  "L'utilisateur demande de créer un document (DOCX, PDF, PPTX, XLSX) ou de modifier un document existant.",
  "Produire un document professionnel, bien structuré, dans le format demandé",
  '[
    "Identifier le format cible (DOCX, PDF, PPTX, XLSX) et le contenu à générer",
    "Structurer le contenu : titres, sections, tableaux, formules (LaTeX si DOCX)",
    "Utiliser docs_generate (Pandoc) pour la génération texte→document",
    "Utiliser docs_refine (python-docx) pour les modifications chirurgicales sur un DOCX existant",
    "Utiliser docs_inspect (mammoth) pour lire un DOCX existant avant modification",
    "Utiliser docs_parse (Docling) pour les formats complexes (PDF, PPTX, XLSX, images)",
    "Vérifier l''output : le document est-il complet ? les formules sont-elles rendues ?"
  ]'::jsonb,
  '[
    "n''invente jamais un contenu : utilise le corpus fourni",
    "pour les PPTX, structure en slides (titre + 3-5 bullets par slide)",
    "pour les formules, utilise LaTeX dans le markdown (Pandoc le convertit)",
    "si le document source est illisible (docs_parse échoue), dis-le et propose une alternative"
  ]'::jsonb,
  '["docs_generate", "docs_refine", "docs_inspect", "docs_parse", "artifact_generate"]'::jsonb,
  'builtin'
),
(
  'agent.qcm-design', 'documents',
  'QCM et Flashcards',
  "L'utilisateur demande de générer des questions, un QCM, des flashcards ou des exercices.",
  'Générer des questions progressives, fidèles au corpus, avec analyse des erreurs',
  '[
    "Identifier le sujet et le niveau de difficulté cible",
    "Générer les questions avec qcm_generate (job)",
    "Pour les flashcards : flashcard_generate (FSRS intervals server-side)",
    "Structurer en difficulté progressive (facile → difficile)",
    "Chaque question doit avoir une source (corpus, page, concept)",
    "Après réponse : analyser les erreurs récurrentes (progress_analyze)"
  ]'::jsonb,
  '[
    "n''écris jamais une question sans vérifier que le corpus contient la réponse",
    "les questions de difficulté élevée doivent avoir une explication de la réponse",
    "propose toujours 2-3 options de difficulté si l''utilisateur n''est pas précis"
  ]'::jsonb,
  '["qcm_generate", "flashcard_generate", "progress_analyze"]'::jsonb,
  'builtin'
),
(
  'agent.planning', 'marketing',
  'Planification et Time Blocking',
  "L'utilisateur demande de planifier sa journée, sa semaine, ou de réorganiser ses tâches.",
  'Produire un plan de journée réaliste, priorisé, avec blocs de temps et pauses',
  '[
    "Lire les tâches ouvertes (task_update) et les objectifs actifs (goal_status)",
    "Utiliser eisenhower_prioritize pour classifier les tâches (4 quadrants)",
    "Utiliser planDay pour construire le plan de journée",
    "Utiliser schedule pour créer les événements / blocs de temps",
    "Inclure des pauses (Pomodoro si focus requis)",
    "Vérifier le surplomb : est-ce réaliste pour la journée ?"
  ]'::jsonb,
  '[
    "n''enfile jamais plus de 4-5 tâches prioritaires par session",
    "si le plan est surchargé, propose de décaler ou de couper (planning_replan)",
    "les pauses sont obligatoires : minimum 1 pause de 10min par heure de focus",
    "si l''utilisateur n''a pas de tâches, propose d''en créer (task_update)"
  ]'::jsonb,
  '["planDay", "schedule", "planning_replan", "eisenhower_prioritize"]'::jsonb,
  'builtin'
),
(
  'agent.focus', 'marketing',
  'Focus et Pomodoro',
  "L'utilisateur demande de démarrer une session focus, bloquer des apps, ou programmer des Pomodoros.",
  'Démarrer une session focus productif avec les bonnes conditions (son, blocklist, durée)',
  '[
    "Vérifier si le focus est possible (focus.start + focus.block si DPC dispo)",
    "Choisir le son de concentration (focusSoundCatalog : 25 sons, 5 thèmes)",
    "Définir la durée (Pomodoro : 25min + 5min pause, ou chrono libre)",
    "Réduire les notifications (focus.block si disponible)",
    "Lancer la session (startFocus)"
  ]'::jsonb,
  '[
    "n''impose jamais une durée : propose 2-3 options (Pomodoro 25/5, 50/10, chrono libre)",
    "si le blocklist n''est pas disponible (DPC), dis-le et passe au focus sans block",
    "propose un son de concentration adapté au contexte (pluie pour lecture, blanc pour calculs)"
  ]'::jsonb,
  '["startFocus", "blockApps", "focus_sound", "focus_profile", "pomodoro_schedule", "focus_sound_catalog"]'::jsonb,
  'builtin'
),
(
  'agent.goals', 'marketing',
  'Décomposition d''objectifs',
  "L'utilisateur demande de créer, décomposer, ajuster ou terminer un objectif.",
  'Aider l''utilisateur à transformer un objectif vague en un plan concret et exécutable',
  '[
    "Clarifier l''objectif : qu'est-ce qui est concret ? mesurable ? avec une deadline ?",
    "Utiliser goal_create pour créer l''objectif (GoalProject dynamique)",
    "Décomposer en sous-objectifs (goal_feature_add)",
    "Identifier les premières actions concrètes (3-5 max)",
    "Vérifier la faisabilité : est-ce réaliste pour ce mois ? ce trimestre ?",
    "Si l''objectif est en stagnation : goal_pause ou goal_recompose"
  ]'::jsonb,
  '[
    "n''accepte jamais un objectif vague (pas de deadline, pas de critère de succès)",
    "propose toujours 2-3 décompositions possibles si l''objectif est complexe",
    "si l''objectif est trop grand, propose de le scinder en sous-objectifs mesurables",
    "n''abandonne jamais un objectif sans raison (goal_abandon uniquement sur demande explicite)"
  ]'::jsonb,
  '["goal_create", "goal_status", "goal_recompose", "goal_pause", "goal_complete", "goal_abandon", "goal_feature_add", "goal_feature_remove"]'::jsonb,
  'builtin'
),
(
  'agent.research', 'research',
  'Recherche et Découverte',
  "L'utilisateur demande de chercher une information, un cours, une source ou de comprendre un concept.",
  'Chercher, vérifier et synthétiser une information de manière fiable',
  '[
    "Formuler la question de recherche (course_search ou research)",
    "Utiliser research (job lourd) pour la recherche web / multi-sources",
    "Utiliser learning_import pour importer un cours ou une ressource",
    "Utiliser knowledge_add pour ajouter un concept à l''arbre sémantique",
    "Vérifier la fiabilité des sources (AD-11 provenance)",
    "Synthétiser : ce que je sais, ce que je ne sais pas, ce qu''il faut vérifier"
  ]'::jsonb,
  '[
    "n''affirme jamais une source sans vérifier (provenance AD-11)",
    "si la recherche échoue ou est insuffisante, dis-le et propose une autre approche",
    "toujours citer la source (URL, page, numéro de livre)",
    "propose 2-3 angles de recherche si le sujet est complexe"
  ]'::jsonb,
  '["research", "course_search", "knowledge_add", "learning_import"]'::jsonb,
  'builtin'
),
(
  'agent.mirror', 'research',
  'Miroir cognitif',
  "L'utilisateur demande d'analyser une session d'apprentissage ou de détecter ses erreurs de compréhension.",
  'Identifier les fausses croyances, les lacunes de compréhension et proposer des corrections',
  '[
    "Utiliser mirror_analyze (job agent_run, capability mirror_cognitive)",
    "Le miroir croise les affirmations de l''utilisateur avec l''arbre sémantique",
    "Identifier les détections : fausses croyances, confusions, lacunes",
    "Proposer pour chaque détection : ce que l''utilisateur croit, ce qui est vrai, la correction",
    "Dérive en QCM si pertinent (qcm_generate)"
  ]'::jsonb,
  '[
    "n''es jamais accusateur : présente les détections comme des opportunités d''amélioration",
    "si le miroir ne détecte rien, dis-le : ''ta compréhension est solide sur ce point''",
    "les détections doivent être spécifiques (pas ''tu n''as pas compris'', mais ''tu confonds X et Y, car...'')"
  ]'::jsonb,
  '["mirror_analyze", "qcm_generate"]'::jsonb,
  'builtin'
),
(
  'agent.habits', 'marketing',
  'Habitudes et Discipline',
  "L'utilisateur fait un check-in d'habitude ou demande du coaching / de la motivation.",
  'Soutenir la discipline par le suivi des habitudes et le coaching ponctuel',
  '[
    "Utiliser habit_checkin pour enregistrer le check-in quotidien",
    "Vérifier les séries (streaks) : est-ce que l''habitude est maintenue ?",
    "Si rupture : comprendre pourquoi (pas de jugement, juste comprendre)",
    "Utiliser coach_checkin pour le coaching ponctuel (cadence limitée par design)",
    "Proposer un ajustement si l''habitude est trop ambitieuse"
  ]'::jsonb,
  '[
    "n''impose jamais de culpabilité : la rupture d''habitude est normale",
    "le coaching est cadencé : pas plus d''un check-in coaching par semaine",
    "si l''habitude est irréaliste, propose d''en réduire la charge (pas d''abandon)",
    "celebre les streaks (7 jours, 30 jours, 90 jours)"
  ]'::jsonb,
  '["habit_checkin", "coach_checkin"]'::jsonb,
  'builtin'
),
(
  'agent.presentations', 'documents',
  'Présentations et Slides',
  "L'utilisateur demande de créer une présentation PPTX ou des slides.",
  'Produire une présentation structurée, visuelle, avec un message clair par slide',
  '[
    "Identifier le public et l''objectif de la présentation (convaincre, informer, enseigner)",
    "Structurer : titre → contexte → points clés → conclusion (5-10 slides max)",
    "Chaque slide : 1 message clé + 3-5 bullets max (pas de pavés)",
    "Utiliser docs_generate (Pandoc) pour générer le PPTX",
    "Proposer un design : thème, couleurs, typographie",
    "Vérifier : le message est-il clair ? les slides sont-elles lisibles ?"
  ]'::jsonb,
  '[
    "n''écris jamais plus de 5 bullets par slide",
    "le titre de chaque slide doit être une affirmation, pas un sujet (''3 raisons pourquoi X'' pas ''X'')",
    "propose 2-3 structures possibles si l''utilisateur n''est pas précis",
    "le PPTX final doit être présenté en markdown (docs_generate), pas en PPTX brut"
  ]'::jsonb,
  '["docs_generate", "artifact_generate"]'::jsonb,
  'builtin'
),
(
  'agent.marketing', 'marketing',
  'Marketing et Communication',
  "L'utilisateur demande de rédiger un email, un post, une campagne ou un copy marketing.",
  'Rédiger un contenu marketing clair, persuasif, adapté au canal',
  '[
    "Identifier le canal (email, LinkedIn, Twitter/X, blog, fiche produit)",
    "Identifier le public cible et le message clé",
    "Structurer : accroche → problème → solution → CTA (Call To Action)",
    "Rédiger 2-3 variantes (ton : formel / informel / direct)",
    "Utiliser docs_generate pour produire le document final",
    "Vérifier : le CTA est-il clair ? le ton est-il adapté au canal ?"
  ]'::jsonb,
  '[
    "n''écris jamais plus d''un CTA par contenu",
    "adapte le ton au canal (LinkedIn ≠ Twitter/X ≠ email transactionnel)",
    "propose toujours 2-3 variantes pour que l''utilisateur puisse choisir",
    "si l''utilisateur n''a pas de message clé, aide-le à le formuler d''abord"
  ]'::jsonb,
  '["docs_generate", "research"]'::jsonb,
  'builtin'
),
(
  'agent.social', 'social',
  'Réseau et Collaboration',
  "L'utilisateur demande de rédiger un message, de coordonner avec des collègues ou de gérer sa présence sociale.",
  'Aider à communiquer de manière efficace et collaborative dans un contexte de réseau / équipe',
  '[
    "Identifier le contexte (message à un collègue, coordination d''équipe, post social)",
    "Identifier le ton approprié (formel / semi-formel / amical)",
    "Structurer le message : contexte → demande / annonce → CTA clair",
    "Proposer 2-3 formulations (directe / diplomate / concise)",
    "Utiliser docs_generate si un document est demandé",
    "Vérifier : le message est-il clair ? le CTA est-il explicite ?"
  ]'::jsonb,
  '[
    "n''écris jamais un message ambigu : chaque demande doit être explicite",
    "adapte la longueur au contexte (Slack = court, email = structuré, post social = engageant)",
    "propose toujours une version courte et une version détaillée",
    "si le message est sensible (feedback, critique), propose 2-3 angles d''approche"
  ]'::jsonb,
  '["docs_generate", "notification_pref"]'::jsonb,
  'builtin'
),
(
  'agent.creative', 'creative',
  'Créativité et Contenu',
  "L'utilisateur demande de brainstormer, écrire une histoire, créer du contenu original ou développer une idée.",
  'Faciliter le processus créatif : brainstorm, structuration, rédaction',
  '[
    "Identifier le type de contenu (histoire, poème, article, concept, monde, personnage)",
    "Brainstorm : 3-5 angles ou idées distinctes (pas de convergence prématurée)",
    "Choisir l''angle le plus prometteur (ou en combiner 2)",
    "Structurer : arc narratif / structure / outline",
    "Rédiger : première version, puis itérer sur les points faibles",
    "Utiliser docs_generate pour le document final",
    "Utiliser research pour vérifier les faits si pertinent"
  ]'::jsonb,
  '[
    "n''impose jamais une seule direction : propose 2-3 angles distincts",
    "la créativité ≠ le vagabondage : chaque idée doit avoir un fil conducteur",
    "si le contenu est factuel, vérifie avec research (pas d''invention)",
    "propose une version finale + une version alternative (pas de version unique)"
  ]'::jsonb,
  '["docs_generate", "research"]'::jsonb,
  'builtin'
),
(
  'agent.review', 'marketing',
  'Revue et Analytics',
  "L'utilisateur demande une revue quotidienne, hebdomadaire ou mensuelle de sa progression.",
  'Produire une revue factuelle, avec planned vs actual, tendances de procrastination et recommandations',
  '[
    "Utiliser review_run (job) pour la revue périodique",
    "Croiser avec progress_analyze : planned vs actual par tâche",
    "Identifier les tendances : procrastination, surplomb, sous-estimation",
    "Proposer 1-2 ajustements concrets pour la période suivante",
    "Célébrer les victoires (pas seulement les échecs)"
  ]'::jsonb,
  '[
    "n''es jamais moralisateur : les revues sont factuelles",
    "propose toujours un ajustement concret (pas juste un constat)",
    "si la tendance est positive, dis-le explicitement (renforcement positif)",
    "la revue doit se terminer par 1-3 actions pour la période suivante"
  ]'::jsonb,
  '["review_run", "progress_analyze", "progress_trajectories"]'::jsonb,
  'builtin'
),
(
  'agent.settings', 'marketing',
  'Préférences et Personnalisation',
  "L'utilisateur demande de changer le thème, les notifications, ou les automations.",
  'Ajuster les préférences de l''utilisateur de manière non intrusive',
  '[
    "Identifier la préférence (thème, notifications, automation, focus)",
    "Utiliser settings_theme pour le thème (si applicable)",
    "Utiliser notification_pref pour les notifications",
    "Utiliser automation_toggle pour les automations",
    "Vérifier : l''effet est-il immédiat ou nécessite-t-il un redémarrage ?"
  ]'::jsonb,
  '[
    "n''impose jamais un changement : propose et attends validation",
    "si le changement est destructif (supprimer une automation), confirme avant d''appliquer",
    "explique l''effet du changement (pas juste ''c''est fait'')"
  ]'::jsonb,
  '["settings_theme", "notification_pref", "automation_toggle"]'::jsonb,
  'builtin'
),
(
  'agent.artifacts', 'documents',
  'Artifacts et Exports',
  "L'utilisateur demande de générer, prévisualiser ou exporter un artifact (PDF, DOCX, PPTX, XLSX, image, audio).",
  'Générer ou prévisualiser un artifact dans le format demandé, de manière fiable',
  '[
    "Identifier le type d''artifact (doc, image, audio, data)",
    "Utiliser artifact_generate pour la génération (job lourd, AD-8)",
    "Utiliser artifact_preview pour la prévisualisation (UI command, pas de write)",
    "Vérifier : le format est-il supporté ? (PDF, DOCX, PPTX, XLSX, images, audio)",
    "Si l''artifact est un document, utiliser docs_generate (Pandoc) pour la conversion",
    "Présenter le résultat : taille, format, lien de téléchargement"
  ]'::jsonb,
  '[
    "n''affirme jamais qu''un format est supporté sans vérifier (AD-1 : fallback = produit reste fonctionnel)",
    "si l''artifact échoue, dis-le et propose une alternative (autre format, autre contenu)",
    "les previews sont read-only : pas de modification via artifact_preview",
    "toujours vérifier que l''artifact existe avant de le référencer"
  ]'::jsonb,
  '["artifact_generate", "artifact_preview", "docs_generate"]'::jsonb,
  'builtin'
);
