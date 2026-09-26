import type { Workflow } from './types.ts';
export const w1: Workflow = {
  id: 'W1',
  name: 'Study Session',
  trigger: 'user opens a course/chapter, or Agent plans a session',
  actors: ['user', 'Learning module', 'Agent (Tutor)', 'Scientific Engine'],
  modules: ['Learning', 'Knowledge'],
  capabilities: ['learning.session.start', 'qcm.generate', 'scientific.evaluate'],
  data: ['learning_sessions', 'flashcards'],
  eventsEmitted: ['FlashcardReviewed'],
  eventsConsumed: [],
  jobs: ['fsrs-tick', 'artifact_gen'],
  ui: [
    { from: 'course', to: 'chapter' },
    { from: 'chapter', to: 'sheet' },
    { from: 'chapter', to: 'flashcards' },
    { from: 'chapter', to: 'qcm' },
  ],
  agent: {
    role: 'Tutor',
    action: 'explains the concept (corpus fidelity AD-11) and verifies answers',
  },
  permissions: ['camera (optional capture)', 'mic (optional capture)'],
  failures: [
    'provider down -> fallback chain (AD-5)',
    'OCR absent -> manual entry',
  ],
  recovery: 'local mirror of due lists; jobs retry idempotently (AD-8).',
};
