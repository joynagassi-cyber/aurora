/**
 * @aurora/ascent — Ascent module public surface (wave 3, W3-E2).
 *
 * Ascent = the pedagogical trajectory engine (docs/ascent/overview.md).
 * Server-side, deterministic (AD-12: same placement rule as the Agent
 * Kernel; S22: no second pedagogical LLM). Pure domain logic over the
 * AD-15 SSoT types (`@aurora/domain/ascent`).
 *
 * Invariants respected across this package:
 *  - AD-7: Ascent writes ONLY `ascent_paths`; everything here is data /
 *    commands — the module never writes Progress/Learning/Knowledge tables.
 *  - AD-9: Ascent CONSUMES the 6 existing events (adapter.ts) and EMITS
 *    NO new AD-9 event; `AscentAdaptation` is internal log data.
 *  - AD-6: steps reference Knowledge by id, never content.
 *  - AD-1: no vendor SDK, no DOM (the kernel's placement, F-09).
 */
export * from './baseline.ts';
export * from './depth.ts';
export * from './path-builder.ts';
export * from './adapter.ts';
export * from './read-do-prove.ts';
export * from './source-hierarchy.ts';
export * from './kernel-integration.ts';
