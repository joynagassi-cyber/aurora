/**
 * @aurora/integrations — Wave 0 skeleton.
 * Consumes @aurora/domain types (AD-15 SSoT); vendors only where AD-1 allows.
 *
 * LOT 1 (discovery-vault plan 2026-10-10): the re-exports carry the
 * explicit `.ts` extension — the workspace runs `node --experimental-strip-types`
 * for its node:test suites, and that runtime resolves ESM-relative
 * specifiers ONLY with the extension; the extension-less form resolves
 * under TS `moduleResolution: bundler` (typecheck) but not in the node
 * runtime. Same shape the `@aurora/discovery` root uses (its root
 * re-export surface is already `.ts`-extensioned).
 */
export * from './research-provider.ts';
export * from './composio.ts';
export * from './notifications.ts';
export * from './automations.ts';
