/**
 * @aurora/productivity — AD-1/AD-10 boundary.
 * Vendor SDKs (supabase, powersync, ion, react…) are banned here:
 * the module is pure domain logic + use-cases. UI rendering is
 * owned by @aurora/ui + the apps/mobile feature slices.
 */
export * from './events.ts';
export * from './tasks.ts';
export * from './inbox.ts';
