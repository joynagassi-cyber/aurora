import type { Workflow } from './types.ts';
export const w3: Workflow = {
  id: 'W3',
  name: 'Daily Planning',
  trigger: 'morning check-in (Coach) or user',
  actors: ['user', 'Agent (Planner)'],
  modules: ['Productivity'],
  capabilities: ['planning.daily'],
  data: ['tasks', 'events', 'habits'],
  eventsEmitted: ['TaskCompleted'],
  eventsConsumed: [],
  jobs: [],
  ui: [
    { from: 'home', to: 'agenda' },
    { from: 'agenda', to: 'time-blocking' },
  ],
  agent: {
    role: 'Planner',
    action: 'prioritizes (Eisenhower signals, eisenhower.md §6) and explains the plan',
  },
  permissions: [],
  failures: ['missing estimates -> Agent asks / infers (flagged as inferred)'],
  recovery: 'plan = local state, instant rollback to previous plan.',
};
