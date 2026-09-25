/**
 * @aurora/productivity — AD-1/AD-10 boundary.
 * Vendor SDKs (supabase, powersync, ion, react…) are banned here:
 * the module is pure domain logic + use-cases. UI rendering is
 * owned by @aurora/ui + the apps/mobile feature slices.
 *
 * Exports (wave 2, ATLAS):
 *   - events:        TaskCompleted + GoalUpdated builders (AD-9 producers)
 *   - tasks:         task / subtask / recurrence / OR-Set commands (AD-7)
 *   - inbox:         capture → triage lens
 *   - eisenhower:    quadrant computation + explainable prioritization (G-L5)
 *   - calendar:      events, conflicts, time blocking, recurrence
 *   - goals-projects: goals / projects / milestones + view projections
 *   - habits:        streaks, heatmap, routines
 *   - focus:         sessions, pomodoro, blocklist (DPC = HYPATIYAS)
 *   - reviews:       daily/weekly/monthly bilan, decisions, analytics
 *   - jobs:          idempotent handler factories (AD-8, wired by ORION)
 */
export * from './events.ts';
export * from './tasks.ts';
export * from './inbox.ts';
export * from './eisenhower.ts';
export * from './calendar.ts';
export * from './goals-projects.ts';
export * from './habits.ts';
export * from './focus.ts';
export * from './reviews.ts';
export * from './jobs.ts';
