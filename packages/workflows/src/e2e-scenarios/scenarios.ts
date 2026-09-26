/**
 * scenarios.ts — the 20 E2E agent scenarios S1..S20 (OQ-08, Playwright-on-device).
 *
 * Source of truth: docs/agent/e2e-agent-scenarios.md. Deterministic tracing
 * spec that the device E2E runner replays; events ⊆ the 9 AD-9 events.
 */
import type { E2EScenario } from './types.ts';

export const S1: E2EScenario = {
  id: 'S1',
  utterance: 'Organise ma journée.',
  intent: 'planning.daily',
  context: ['Productivity (today calendar, open tasks, due-today, time blocks)', 'Personal (exam period?, silence windows)'],
  capabilities: ['planning.daily', 'task.create', 'calendar.schedule'],
  tools: ['Plan', 'EventUpdateCommand', 'TaskCreateCommand'],
  modules: ['Productivity'],
  backend: "LocalCommandRepository.apply('productivity', [EventUpdateCommand, ...]) -> upsync; deterministic, no AI",
  ui: [{ from: 'home', to: 'planning' }],
  result: 'Day organized: time blocks on calendar, tasks reordered',
  progress: 'planning adherence tracked (planned vs actual at day end, S18.3)',
  events: [],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S2: E2EScenario = {
  id: 'S2',
  utterance: "J'ai examen vendredi, prepare mon plan de revision.",
  intent: 'planning.replan + learning.session.start (compound)',
  context: ['Learning (courses, skill states from Progress mirrors)', 'Personal (exam = declared period type)'],
  capabilities: ['progress.analyze', 'planning.daily', 'learning.sheet.generate'],
  tools: ['Progress mirrors read', 'calendar time blocks', 'artifact_gen job'],
  modules: ['Progress', 'Learning', 'Productivity', 'Artifact'],
  backend: 'progress_snapshots + skill_states read; fn-job-dispatcher -> artifact_gen; R2 upload + ArtifactGenerated (F-06)',
  ui: [
    { from: 'progress-dashboard', to: 'weak-skill-list' },
    { from: 'weak-skill-list', to: 'study-plan-preview' },
    { from: 'study-plan-preview', to: 'calendar' },
  ],
  result: 'Study plan preview confirmed; calendar updated; sheet available in Artifacts',
  progress: 'study-plan adherence becomes ProgressEvidence on completion',
  events: ['ArtifactGenerated', 'GoalUpdated'],
  confirmation: 'confirm',
  offline: 'online-required',
};

export const S3: E2EScenario = {
  id: 'S3',
  utterance: 'Cre deux heures de geotechnique demain matin.',
  intent: 'calendar.schedule (2h block, geotechnique, tomorrow AM)',
  context: ['Learning (geotechnique = course ID + subject)', 'Productivity (tomorrow calendar, availability)'],
  capabilities: ['calendar.schedule'],
  tools: ['EventUpdateCommand (create time block 09:00-11:00, courseId ref)'],
  modules: ['Productivity', 'Learning'],
  backend: 'LocalCommandRepository.apply(\'productivity\', EventUpdateCommand) -> upsync',
  ui: [{ from: 'calendar', to: 'calendar' }],
  result: 'Time block persisted',
  progress: 'N/A (scheduling only)',
  events: [],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S4: E2EScenario = {
  id: 'S4',
  utterance: 'Lance une session Focus de 90 minutes.',
  intent: 'focus.start (90 min)',
  context: ['Productivity (open tasks, current time)', 'DPC state (isBlockingAvailable detection)'],
  capabilities: ['focus.start'],
  tools: ['FocusController.startSession({duration: 90, blocklist: []})'],
  modules: ['Productivity'],
  backend: 'focus_sessions table (Productivity); in-app timer + reduceForFocus(true); no AI',
  ui: [{ from: 'home', to: 'focus' }],
  result: 'Focus session started, timer active',
  progress: 'at session end, FocusSessionBilan -> Progress sole-producer emits ProgressEvidenceCreated (S18.3)',
  events: [],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S5: E2EScenario = {
  id: 'S5',
  utterance: 'Bloque TikTok et WhatsApp pendant cette session.',
  intent: 'focus.block (TikTok, WhatsApp, during active focus session)',
  context: ['DPC state (isBlockingAvailable)', 'blocklist history'],
  capabilities: ['focus.block'],
  tools: ['DpcAdapter.precheckBlocklist', 'DpcAdapter.applyBlocklist'],
  modules: ['Productivity'],
  backend: 'focus_sessions.blocklist (suspendability results per package); system-level DPC',
  ui: [{ from: 'focus', to: 'focus' }],
  result: 'setPackagesSuspended([tiktok, whatsapp], true) applied; Internet + Aurora stay active',
  progress: 'at session end, blocklist honored = discipline evidence',
  events: [],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S6: E2EScenario = {
  id: 'S6',
  utterance: "Je ne comprends pas cette notion, explique-la a mon niveau.",
  intent: 'learning.mirror.analyze (explanation mode)',
  context: ['Learning (course, chapter, concept)', 'Expert Skills (demonstrated level)', 'Semantic (tree node for the concept)'],
  capabilities: ['learning.mirror.analyze'],
  tools: ['Knowledge retrieval (FTS + pgvector)', 'AIProvider.complete (router: ROUTINE -> cheaper model)'],
  modules: ['Knowledge', 'Learning', 'Agent'],
  backend: 'fn-agent-run -> AI Gateway -> provider; result = AIResponseEnvelope + provenance (AD-11)',
  ui: [{ from: 'concept-detail', to: 'explanation-panel' }],
  result: 'Explanation panel appears with source citations; "Verifie-moi" CTA -> S7',
  progress: 'if user then quizzes (S7), the result feeds ProgressEvidenceCreated',
  events: [],
  confirmation: 'none',
  offline: 'online-required',
};

export const S7: E2EScenario = {
  id: 'S7',
  utterance: "Verifie si j'ai vraiment compris ce chapitre.",
  intent: 'learning.mirror.analyze (verification: quiz)',
  context: ['Learning (chapter, related concepts)', 'Progress (prior evidence for this chapter)'],
  capabilities: ['qcm.generate', 'flashcard.generate'],
  tools: ['artifact_gen job (QCM generation)', 'in-session QCM review (local)'],
  modules: ['Learning', 'Progress', 'Agent'],
  backend: 'fn-job-dispatcher -> QCM generation job; items in learning_items; review = local mirror read',
  ui: [
    { from: 'qcm', to: 'result' },
    { from: 'result', to: 'recurring-error-analysis' },
  ],
  result: 'QCM answered; score + error analysis; weak items -> flashcard CTA',
  progress: 'QCM score + error pattern -> SkillState update -> SkillStateChanged',
  events: ['FlashcardReviewed', 'ProgressEvidenceCreated', 'SkillStateChanged'],
  confirmation: 'none',
  offline: 'hybrid',
};

export const S8: E2EScenario = {
  id: 'S8',
  utterance: 'Fais-moi une fiche fidelle au cours.',
  intent: 'learning.sheet.generate (fidelity = corpus-dominant)',
  context: ['Learning (course, selected chapters)', 'Knowledge (source documents in R2)'],
  capabilities: ['qcm.generate', 'flashcard.generate', 'learning.sheet'],
  tools: ['artifact_gen job (AI extraction 7 structures + fidelity check + export)'],
  modules: ['Learning', 'Knowledge', 'Artifact', 'Agent'],
  backend: 'server job -> AI Gateway; R2 presigned upload; ArtifactGenerated post-upload (F-06)',
  ui: [{ from: 'learning', to: 'artifact-preview' }],
  result: 'Fidelity-checked sheet ready; artifact card with preview; "Fichu" -> Artifacts',
  progress: 'sheet reviewed = application evidence (S18.3)',
  events: ['ArtifactGenerated'],
  confirmation: 'none',
  offline: 'online-required',
};

export const S9: E2EScenario = {
  id: 'S9',
  utterance: 'Teste-moi avec 20 QCM.',
  intent: 'qcm.generate (20 items, topic from context)',
  context: ['Learning (topic/chapter)', 'Progress (weak areas for targeted items)'],
  capabilities: ['qcm.generate'],
  tools: ['artifact_gen job (20-item QCM)', 'in-session review'],
  modules: ['Learning', 'Agent', 'Progress'],
  backend: 'generation job; QCM items in learning_items; review local',
  ui: [
    { from: 'qcm', to: 'result' },
    { from: 'result', to: 'recurring-error-analysis' },
  ],
  result: '20 questions answered; score + per-question feedback; recurring-error analysis',
  progress: 'QCM accuracy -> SkillState update; recurring errors -> targeted practice',
  events: ['FlashcardReviewed', 'ProgressEvidenceCreated'],
  confirmation: 'none',
  offline: 'online-required',
};

export const S10: E2EScenario = {
  id: 'S10',
  utterance: 'Analyse mes erreurs.',
  intent: 'progress.analyze (error patterns)',
  context: ['Progress (evidence history, progress_events server-only)', 'Learning (course/chapter scope)'],
  capabilities: ['progress.analyze'],
  tools: ['read progress_evidences + progress_events (S jobs aggregation)', 'skill_states mirrors'],
  modules: ['Progress', 'Learning'],
  backend: 'S jobs (aggregation + causal analysis, S18.4); results in progress_snapshots',
  ui: [
    { from: 'progress-dashboard', to: 'error-pattern-view' },
    { from: 'error-pattern-view', to: 'progress-dashboard' },
  ],
  result: 'Error-pattern view (by topic/skill/time); "Replanifier" CTA -> S19',
  progress: 'analysis output = input for replanning',
  events: [],
  confirmation: 'none',
  offline: 'hybrid',
};

export const S11: E2EScenario = {
  id: 'S11',
  utterance: 'Que dois-je apprendre ensuite ?',
  intent: 'discovery.gaps + progress.analyze (next learning targets)',
  context: ['Progress (skill states, trajectories S18.5)', 'Learning (completed/pending)', 'Discovery (gap definitions)'],
  capabilities: ['progress.analyze', 'discovery.research', 'learning.session.start'],
  tools: ['Progress mirrors read', 'research job (optional)'],
  modules: ['Progress', 'Discovery', 'Learning'],
  backend: 'skill_states + progress_trajectories mirrors; optional research job (AD-8)',
  ui: [
    { from: 'progress-dashboard', to: 'next-up' },
    { from: 'next-up', to: 'agenda' },
  ],
  result: 'Ranked next-items list with rationale; "Planifier" CTA -> calendar blocks',
  progress: 'gap->plan loop feeds S18.5 trajectories',
  events: ['DiscoveryItemCreated', 'GoalUpdated'],
  confirmation: 'none',
  offline: 'hybrid',
};

export const S12: E2EScenario = {
  id: 'S12',
  utterance: "Recherche ce qui a recemment change dans mon domaine.",
  intent: 'discovery.research (recency filter, user domain)',
  context: ['Discovery (profile, domain, prior findings)', 'Personal (professional vs academic domain)'],
  capabilities: ['discovery.research'],
  tools: ['research job (multi-source: FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY)'],
  modules: ['Discovery', 'Knowledge'],
  backend: 'fn-job-dispatcher -> research job; results in discovery_items + sources',
  ui: [
    { from: 'discovery-feed', to: 'discovery-sheet' },
    { from: 'discovery-sheet', to: 'knowledge-base' },
  ],
  result: 'Research results with source badges + confidence markers; "Ajouter au Knowledge Base" CTA',
  progress: 'new gap knowledge -> SkillStateChanged (if a skill is affected)',
  events: ['DiscoveryItemCreated'],
  confirmation: 'none',
  offline: 'online-required',
};

export const S13: E2EScenario = {
  id: 'S13',
  utterance: "Transforme cette decouverte en plan d'apprentissage.",
  intent: 'discovery.sheet -> learning.session.start -> planning.daily (compound)',
  context: ['Discovery (the specific item)', 'Learning (relevant courses)', 'Productivity (available time)'],
  capabilities: ['discovery.sheet', 'learning.session.start', 'planning.daily'],
  tools: ['Discovery sheet content -> learning items', 'calendar time blocks'],
  modules: ['Discovery', 'Learning', 'Productivity'],
  backend: 'DiscoveryItemCreated already emitted; learning items created; calendar blocks; GoalUpdated if linked',
  ui: [
    { from: 'discovery-sheet', to: 'study-plan-preview' },
    { from: 'study-plan-preview', to: 'calendar' },
  ],
  result: 'Study plan confirmed; calendar updated; learning items in Learning screen',
  progress: 'plan adherence -> S18.3 evidence on completion',
  events: ['GoalUpdated'],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S14: E2EScenario = {
  id: 'S14',
  utterance: "Genere un PDF de ma fiche.",
  intent: 'artifact.generate (PDF, from existing sheet)',
  context: ['Artifact (the sheet artifact ID)', 'Learning'],
  capabilities: ['artifact.generate'],
  tools: ['artifact_gen job: render sheet -> PDF (server-side, R2, presigned URL)'],
  modules: ['Artifact', 'Learning'],
  backend: 'fn-job-dispatcher -> artifact_gen (PDF); R2 put; ArtifactGenerated post-upload (F-06)',
  ui: [{ from: 'artifact-hub', to: 'artifact-preview' }],
  result: 'PDF artifact card with download/preview; ArtifactGenerated triggers Artifacts refresh',
  progress: 'N/A (export is not a learning evidence)',
  events: ['ArtifactGenerated'],
  confirmation: 'none',
  offline: 'online-required',
};

export const S15: E2EScenario = {
  id: 'S15',
  utterance: "Ajoute cette information a mon Knowledge Base.",
  intent: 'knowledge.retrieval (write path: add a source) — status PARTIAL (V1 limitation)',
  context: ['Knowledge (existing tree, related nodes)', 'user-provided content (URL, text, file)'],
  capabilities: ['artifact.generate'],
  tools: ['DocumentScanner + ocr job -> CourseImported', 'manual entry flow (UI, free-form text)'],
  modules: ['Knowledge', 'Artifact', 'Learning'],
  backend: 'fn-import-course + ocr job; Knowledge ingestion (Postgres FTS + pgvector + R2)',
  ui: [{ from: 'knowledge-base', to: 'tree-node' }],
  result: 'Capture/import flow -> CourseImported -> tree node created',
  progress: 'new knowledge -> potential SkillStateChanged',
  events: ['CourseImported'],
  confirmation: 'none',
  offline: 'online-required',
};

export const S16: E2EScenario = {
  id: 'S16',
  utterance: "Montre-moi le concept dans l'arbre sémantique.",
  intent: 'knowledge.tree (navigate / inspect)',
  context: ['Semantic (the concept, its parent/child nodes, bridges)'],
  capabilities: ['course.search'],
  tools: ['SemanticTreeRenderer (AD-10)', 'NavigationIntent { route: /knowledge/tree/:nodeId }'],
  modules: ['Knowledge'],
  backend: 'local mirror read (offline); server retrieval for expanded levels (online, AD-12)',
  ui: [{ from: 'knowledge-base', to: 'tree' }],
  result: 'Tree view with node expanded; Agent deep-links via command bus',
  progress: 'N/A (navigation)',
  events: [],
  confirmation: 'none',
  offline: 'offline-capable',
};

export const S17: E2EScenario = {
  id: 'S17',
  utterance: "Analyse mes progres de cette semaine.",
  intent: 'progress.analyze (weekly window)',
  context: ['Progress (weekly snapshots, evidence, skill states)', 'Productivity (completed tasks, focus sessions)'],
  capabilities: ['progress.analyze'],
  tools: ['read progress_snapshots + progress_evidences + skill_states (mirrors)', 'S jobs aggregation if online'],
  modules: ['Progress', 'Productivity'],
  backend: 'local mirror read (offline); server S jobs for trends (online)',
  ui: [
    { from: 'progress-dashboard', to: 'weekly-view' },
    { from: 'weekly-view', to: 'progress-dashboard' },
  ],
  result: 'Weekly dashboard (G2 charts, ChartSpec); "Replanifier" CTA if delay detected',
  progress: 'the analysis itself is Progress output; delay -> S18 replanning',
  events: [],
  confirmation: 'none',
  offline: 'hybrid',
};

export const S18: E2EScenario = {
  id: 'S18',
  utterance: 'Pourquoi suis-je en retard ?',
  intent: 'progress.analyze (causal analysis, S18.4)',
  context: ['Progress (planned vs actual, evidence gaps)', 'Productivity (completion rates, focus adherence)', 'Personal (period type, external events)'],
  capabilities: ['progress.analyze'],
  tools: ['S jobs: causal analysis (correlation != causation, S18.4)'],
  modules: ['Progress', 'Productivity'],
  backend: 'server S job; results in progress_snapshots',
  ui: [
    { from: 'progress-dashboard', to: 'delay-cause-view' },
    { from: 'delay-cause-view', to: 'progress-dashboard' },
  ],
  result: 'Retards view with ranked causes + evidence refs; "Replanifier" CTA -> S19',
  progress: 'cause analysis feeds the replanning decision',
  events: [],
  confirmation: 'none',
  offline: 'online-required',
};

export const S19: E2EScenario = {
  id: 'S19',
  utterance: 'Replanifie ma semaine.',
  intent: 'planning.replan (CONFIRMATION_REQUIRED: replan discards old plan)',
  context: ['Productivity (current week plan, uncompleted tasks)', 'Progress (detected delay from S18)', 'Personal'],
  capabilities: ['planning.replan', 'calendar.schedule', 'task.update'],
  tools: ['Plan rebuild (deterministic: available time + priorities + delay offset)', 'EventUpdateCommand + TaskUpdateCommand (postpone)'],
  modules: ['Productivity'],
  backend: 'LocalCommandRepository.apply(\'productivity\', [...]) -> upsync; plan history preserved (ADR S13)',
  ui: [
    { from: 'calendar', to: 'plan-preview' },
    { from: 'plan-preview', to: 'calendar' },
  ],
  result: 'New plan preview (diff from old); "Confirmer" -> calendar updated; old plan in history',
  progress: 'replan adherence -> S18.3 evidence on next cycle',
  events: ['TaskCompleted', 'GoalUpdated'],
  confirmation: 'confirm',
  offline: 'offline-capable',
};

export const S20: E2EScenario = {
  id: 'S20',
  utterance: 'Envoie ce document par Gmail.',
  intent: 'artifact.send_external (Gmail via Composio)',
  context: ['Artifact (the document, R2 key, presigned URL)', 'Integrations (Gmail connectedAccountID)'],
  capabilities: ['artifact.send_external'],
  tools: ['IntegrationProvider -> Composio gmail.send(to, subject, attachment=presignedUrl)'],
  modules: ['Artifact', 'Integrations', 'Agent'],
  backend: 'server-side Composio call (no device-held tokens, AD-3); result = {ok, messageId}',
  ui: [
    { from: 'artifact-preview', to: 'send-recipient' },
    { from: 'send-recipient', to: 'artifact-preview' },
  ],
  result: '"Envoyer" -> recipient -> "Confirmer l\'envoi" -> "Envoye: <messageId>"',
  progress: 'N/A',
  events: [],
  confirmation: 'confirm',
  offline: 'online-required',
};

/** All 20 E2E scenarios (master mission S60). */
export const E2E_SCENARIOS: readonly E2EScenario[] = [
  S1, S2, S3, S4, S5, S6, S7, S8, S9, S10,
  S11, S12, S13, S14, S15, S16, S17, S18, S19, S20,
];

export function scenarioById(id: string): E2EScenario | undefined {
  return E2E_SCENARIOS.find((s) => s.id === id);
}
