import type { Workflow } from './types.ts';
export const w5: Workflow = {
  id: 'W5',
  name: 'Concept Coaching',
  trigger: 'user flags "I don\'t understand X", or Agent detects a gap',
  actors: ['user', 'Agent (Tutor)'],
  modules: ['Knowledge', 'Learning', 'Progress'],
  capabilities: ['knowledge.retrieve', 'qcm.generate', 'flashcard.generate'],
  data: ['semantic_nodes', 'sources'],
  eventsEmitted: ['FlashcardReviewed'],
  eventsConsumed: [],
  jobs: ['scientific'],
  ui: [
    { from: 'knowledge-node', to: 'explanation' },
    { from: 'explanation', to: 'active-recall' },
  ],
  agent: {
    role: 'Tutor',
    action: 'explains + asks questions with corpus fidelity (AD-11 provenance)',
  },
  permissions: [],
  failures: ['retrieval miss -> suggested actions (empty state, 02 §7)'],
  recovery: 'node state updated via AD-9 chain only.',
};
