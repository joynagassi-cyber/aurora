import type { Workflow } from './types.ts';
export const w4: Workflow = {
  id: 'W4',
  name: 'Weekly Planning',
  trigger: 'weekly review (05 §4.5) or Agent',
  actors: ['user', 'Agent'],
  modules: ['Productivity', 'Progress'],
  capabilities: ['planning.weekly', 'progress.analyze'],
  data: ['tasks', 'decisions'],
  eventsEmitted: ['GoalUpdated'],
  eventsConsumed: [],
  jobs: ['verify'],
  ui: [
    { from: 'reviews', to: 'agenda' },
  ],
  agent: {
    role: 'Planner',
    action: 'causal analysis of slippage (ADR §18.4), priority review',
  },
  permissions: [],
  failures: ['missing data -> Agent degrades to manual review prompts'],
  recovery: 'journals are local; week plan history preserved.',
};
