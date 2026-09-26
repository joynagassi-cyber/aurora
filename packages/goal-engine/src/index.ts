/**
 * @aurora/goal-engine — Dynamic Goal Engine (wave 3, HEPHAESTUS).
 *
 * Pure server-side composition logic over the frozen AD-15 types
 * (`GoalProject` / `SubGoal` / `FeaturePlacement` / `TimelineBlock` /
 * `GoalProgress` in `packages/domain/src/entities-goal.ts`).
 *
 * AD-7 single-writer: this package PRODUCES GoalProject composition data
 * only — it does not write other modules' tables. `GoalProgress` rows and
 * `ProgressEvidence` are owned by Progress (F-07 sole producer); this
 * package only EVALUATES progress against success criteria and returns the
 * resulting `GoalProgress` value for the Progress module to persist.
 *
 * AD-12: nothing here runs on the device — the device sees AgentRunState
 * only. AD-3: no provider key is ever referenced by this logic.
 */

export * from './patterns.ts';
export * from './decomposition.ts';
export * from './progress.ts';
export * from './mutations.ts';
export * from './layout.ts';
