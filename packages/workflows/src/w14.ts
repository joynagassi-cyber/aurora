import type { Workflow } from './types.ts';
export const w14: Workflow = {
  id: 'W14',
  name: 'Focus → Progress (discipline)',
  trigger: 'focus session end',
  actors: ['Productivity module', 'Progress module'],
  modules: ['Productivity', 'Progress'],
  capabilities: ['progress.analyze'],
  data: ['focus_sessions', 'progress_evidences', 'skill_states'],
  eventsEmitted: ['ProgressEvidenceCreated'],
  eventsConsumed: [],
  jobs: ['verify'],
  ui: [{ from: 'focus-bilan', to: 'progress-dashboard' }],
  agent: {
    role: 'Coach',
    action:
      'on stagnation: cause analysis BEFORE any new recommendation (ADR §18.7)',
  },
  permissions: [],
  failures: ['evidence lag -> dashboard shows last-known state'],
  recovery: 'jobs idempotent.',
};
