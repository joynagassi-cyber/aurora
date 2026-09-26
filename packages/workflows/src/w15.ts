import type { Workflow } from './types.ts';
export const w15: Workflow = {
  id: 'W15',
  name: 'Progress → Replanning',
  trigger: 'detected delay/stagnation (ProgressTrend) or user request',
  actors: ['Progress module', 'Agent (Planner)', 'Productivity module'],
  modules: ['Progress', 'Productivity'],
  capabilities: ['planning.replan', 'progress.analyze'],
  data: ['progress_snapshots', 'decisions'],
  eventsEmitted: ['GoalUpdated'],
  eventsConsumed: ['ProgressEvidenceCreated', 'SkillStateChanged'],
  jobs: ['verify'],
  ui: [
    { from: 'progress-dashboard', to: 'next-actions' },
    { from: 'next-actions', to: 'agenda' },
  ],
  agent: {
    role: 'Planner',
    action:
      'proposes replan with causes (ADR §18.4); confirmation mandatory (AD-12 / ADR §5)',
  },
  permissions: [],
  failures: ['analysis inconclusive -> human review prompt'],
  recovery: 'original plan preserved in history.',
};
