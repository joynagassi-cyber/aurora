/**
 * @aurora/focus — Focus Mode contract (wave 2, HYPATIYAS).
 *
 * The FOCUS CONTRACT layer: `FocusControllerPort` (04 S4.2 base,
 * unchanged signature) + the v1.8 DPC additive extension (spec S10).
 * Pure contract + pure session/bilan state machine — no vendor, no
 * DOM (AD-1). The DPC system layer (setPackagesSuspended, boot
 * receiver) lives in `@aurora/platform` and is implemented against
 * this port; session persistence is ATLAS/Productivity's
 * (`focus_sessions`), never this module's tables.
 */
export * from './controller.ts';
export * from './bilan.ts';
export * from './timer.ts';
export * from './pomodoro.ts';
export * from './service.ts';
