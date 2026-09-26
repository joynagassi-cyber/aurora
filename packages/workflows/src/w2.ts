import type { Workflow } from './types.ts';
export const w2: Workflow = {
  id: 'W2',
  name: 'Exam Preparation',
  trigger: 'due date in calendar + user goal, or Agent proactive (Coach check-in)',
  actors: ['user', 'Agent (Planner+Coach)', 'Learning module', 'Productivity module'],
  modules: ['Productivity', 'Learning', 'Progress'],
  capabilities: ['calendar.schedule', 'learning.sheet.generate', 'flashcard.generate', 'progress.analyze'],
  data: ['goals', 'courses', 'calendar'],
  eventsEmitted: ['GoalUpdated', 'TaskCompleted'],
  eventsConsumed: [],
  jobs: ['artifact_gen'],
  ui: [
    { from: 'home', to: 'agenda' },
    { from: 'agenda', to: 'focus' },
  ],
  agent: {
    role: 'Planner + Coach',
    action: 'builds a realistic plan (load check ADR §6), dynamically replans on deviation',
  },
  permissions: ['local notifications (reminders)'],
  failures: ['overload detected -> Agent proposes trimmed plan (confirmation required)'],
  recovery: "plan history preserved (ADR §13 \"sans détruire l'historique\").",
};
