import type { Workflow } from './types.ts';
export const w11: Workflow = {
  id: 'W11',
  name: 'Course → Exercise → Progress',
  trigger: 'user completes an exercise',
  actors: ['user', 'Learning module', 'Progress module'],
  modules: ['Learning', 'Progress', 'Knowledge'],
  capabilities: ['learning.exercise.submit'],
  data: ['learning_items', 'progress_evidences', 'skill_states'],
  eventsEmitted: ['ProgressEvidenceCreated', 'SkillStateChanged'],
  eventsConsumed: [],
  jobs: ['skill_recompute'],
  ui: [
    { from: 'exercise', to: 'result' },
    { from: 'result', to: 'progress-dashboard' },
  ],
  agent: {
    role: 'Tutor',
    action: 'explains errors (corpus + engine) and proposes rework',
  },
  permissions: [],
  failures: ['recompute lag -> dashboard shows last mirror (stale marking)'],
  recovery: 'recompute is idempotent.',
};
