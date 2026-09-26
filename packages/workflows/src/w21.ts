import type { Workflow } from './types.ts';
export const w21: Workflow = {
  id: 'W21',
  name: 'Calendar Conflicts & Overload',
  trigger: 'schedule change or Agent load check',
  actors: ['Productivity module', 'Agent'],
  modules: ['Productivity'],
  capabilities: ['calendar.schedule'],
  data: ['events', 'time_blocks', 'tasks'],
  eventsEmitted: ['GoalUpdated'],
  eventsConsumed: [],
  jobs: [],
  ui: [{ from: 'calendar', to: 'agenda' }],
  agent: {
    role: 'Planner',
    action: 'replans around conflicts with explanation',
  },
  permissions: ['local notifications'],
  failures: ['missing estimates -> flagged assumptions'],
  recovery: 'calendar = local mirror; plan history preserved.',
};
