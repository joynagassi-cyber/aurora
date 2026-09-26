import type { Workflow } from './types.ts';
export const w12: Workflow = {
  id: 'W12',
  name: 'Goal → Project → Task',
  trigger: 'user sets a goal (short/mid/long horizon)',
  actors: ['user', 'Agent (Planner)'],
  modules: ['Productivity'],
  capabilities: ['goal.create', 'project.create', 'task.create'],
  data: ['goals', 'projects', 'tasks'],
  eventsEmitted: ['GoalUpdated'],
  eventsConsumed: [],
  jobs: [],
  ui: [
    { from: 'goals', to: 'project-board' },
  ],
  agent: {
    role: 'Planner',
    action:
      'decomposes the goal into milestones/tasks (confirmation for bulk create)',
  },
  permissions: [],
  failures: ['missing horizon -> Agent asks (inferred params flagged)'],
  recovery: 'local commands via upsync queue; 1 story = 1 commit = 1 rollback.',
};
