import type { Workflow } from './types.ts';
export const w9: Workflow = {
  id: 'W9',
  name: 'Course → Flashcards',
  trigger: 'sheet ready, or "send to FSRS" (ADR §17 long-term items)',
  actors: ['user', 'Learning module', 'Agent'],
  modules: ['Learning'],
  capabilities: ['flashcard.generate'],
  data: ['flashcards'],
  eventsEmitted: ['FlashcardReviewed'],
  eventsConsumed: [],
  jobs: ['fsrs-tick'],
  ui: [{ from: 'flashcards', to: 'flashcards' }],
  agent: {
    role: 'Tutor',
    action: 'derives cards from sheet gaps (structured output)',
  },
  permissions: [],
  failures: [
    'FSRS recompute delay -> local state mirror used, server wins later',
  ],
  recovery: 'due lists recomputed by the fsrs-tick job.',
};
