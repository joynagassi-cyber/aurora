import type { Workflow } from './types.ts';
export const w6: Workflow = {
  id: 'W6',
  name: 'Mirror Cognitive Mode',
  trigger: 'user explains a concept (text Tiptap / audio)',
  actors: ['user', 'Agent (Tutor, server job mirror-analysis)'],
  modules: ['Learning', 'Progress', 'Knowledge'],
  capabilities: ['learning.mirror.analyze'],
  data: ['learning_sessions', 'progress_evidences'],
  eventsEmitted: ['ProgressEvidenceCreated', 'SkillStateChanged'],
  eventsConsumed: [],
  jobs: ['agent_run', 'verify'],
  ui: [
    { from: 'coach-mode', to: 'structured-feedback' },
    { from: 'structured-feedback', to: 'flashcards' },
    { from: 'structured-feedback', to: 'qcm' },
  ],
  agent: {
    role: 'Tutor',
    action:
      'detects gaps/contradictions/errors and quotes the professor\'s formulations (no creative rewrite, ADR §17)',
  },
  permissions: ['mic (optional)'],
  failures: [
    'STT absent -> text mode',
    'analysis timeout -> partial findings + retry',
  ],
  recovery: 'session row persisted; findings are idempotent.',
};
