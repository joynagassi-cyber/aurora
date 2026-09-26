import type { Workflow } from './types.ts';
export const w23: Workflow = {
  id: 'W23',
  name: 'Habit/Routine Loop',
  trigger: 'daily/weekly anchors (routines) or review',
  actors: ['user', 'Agent (Coach)'],
  modules: ['Productivity', 'Progress'],
  capabilities: ['habit.checkin', 'planning.daily'],
  data: ['habits', 'routines'],
  eventsEmitted: ['TaskCompleted'],
  eventsConsumed: [],
  jobs: ['verify'],
  ui: [
    { from: 'habit-heatmap', to: 'reviews' },
  ],
  agent: {
    role: 'Coach',
    action:
      'disruptive-habit detection (ADR §2.7) + routine adaptation suggestions',
  },
  permissions: ['local notifications'],
  failures: ['missed check-in = honest streak break (no silent correction)'],
  recovery: 'local data; streak state is deterministic.',
};
