/**
 * @aurora/progress — Progress module public surface (wave 2, ORION).
 *
 * Pure domain logic: evidence model (F-07 sole producer of
 * ProgressEvidence), SkillState recompute (S18.8, idempotent AD-8),
 * G2 ChartSpec dashboards (S18.6), conditional trajectories (S18.5),
 * causal analysis (S18.4, correlation ≠ causation discipline). Progress
 * writes ONLY its own tables (AD-7) and emits exactly 2 events of the
 * closed 9-event vocabulary (AD-9).
 */

export * from './evidence.ts';
export * from './recompute.ts';
export * from './dashboard.ts';
export * from './trajectories.ts';
export * from './jobs.ts';
