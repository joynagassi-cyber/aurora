import type { Workflow } from './types.ts';
export const w20: Workflow = {
  id: 'W20',
  name: 'Focus Session (standalone, no task)',
  trigger: 'user starts a plain focus block',
  actors: ['user'],
  modules: ['Productivity'],
  capabilities: ['focus.start'],
  data: ['focus_sessions'],
  eventsEmitted: [],
  eventsConsumed: [],
  jobs: [],
  ui: [{ from: 'focus', to: 'focus' }],
  agent: {
    role: 'Coach',
    action: 'may check in after the session (ADR §13, cadence respected)',
  },
  permissions: ['POST_NOTIFICATIONS (optional)', 'DPC = OQ-17'],
  failures: ['as W13: DPC pre-check reject, timer survives kill'],
  recovery: 'session row persisted; 25 min Pomodoro default.',
};
