import type { Workflow } from './types.ts';
export const w13: Workflow = {
  id: 'W13',
  name: 'Task → Focus → actual time',
  trigger: 'user starts Focus on a task (or Agent suggests)',
  actors: ['user', 'Agent (optional, DPC mode if provisioned)'],
  modules: ['Productivity'],
  capabilities: ['focus.start', 'focus.block'],
  data: ['focus_sessions'],
  eventsEmitted: [],
  eventsConsumed: [],
  jobs: [],
  ui: [
    { from: 'task', to: 'focus' },
    { from: 'focus', to: 'focus-bilan' },
  ],
  agent: {
    role: 'Coach',
    action:
      'proposes focus when Q1 tasks overload (explanation, cadence respected)',
  },
  permissions: ['POST_NOTIFICATIONS (optional)', 'DPC = OQ-17'],
  failures: [
    'DPC pre-check rejects packages -> restricted fallback',
    'timer survives kill (system clock)',
  ],
  recovery: 'session row + boot receiver (focus spec §7).',
};
