import type { Workflow } from './types.ts';
export const w10: Workflow = {
  id: 'W10',
  name: 'Course → QCM',
  trigger: 'sheet/exercise generation, or targeted revision (SkillStateChanged)',
  actors: ['user', 'Learning module', 'Agent'],
  modules: ['Learning', 'Progress'],
  capabilities: ['qcm.generate'],
  data: ['learning_items'],
  eventsEmitted: ['FlashcardReviewed'],
  eventsConsumed: ['SkillStateChanged'],
  jobs: ['artifact_gen'],
  ui: [
    { from: 'qcm', to: 'result' },
    { from: 'result', to: 'recurring-error-analysis' },
  ],
  agent: {
    role: 'Tutor',
    action: 'generates from corpus (fidelity) and adapts difficulty (Progress)',
  },
  permissions: [],
  failures: ['generation fallback (AD-5) -> degraded-quality flag shown to user'],
  recovery: 'attempts persisted; jobs retry idempotently.',
};
