/**
 * Pomodoro timer (in-app timer + Pomodoro feature, master-feature-catalog
 * productivity.focus = FULL). The Pomodoro STATE MACHINE lives in
 * @aurora/productivity (owned session logic); this module re-exports it
 * as the FOCUS contract so the timer feature has one import surface.
 */
export {
  newPomodoro,
  tickPomodoro,
  pomodoroDisplay,
  POMODORO,
} from '@aurora/productivity';
export type {
  PomodoroState,
  FocusMode,
} from '@aurora/productivity';
