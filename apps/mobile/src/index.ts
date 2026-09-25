/**
 * @aurora/mobile — Ionic React + Capacitor app shell + vertical feature slices
 * (presentation / ui-state / use-cases / data-access / platform, 02 S4).
 * A feature slice never imports a sibling slice (AD-2/AD-13, 02 S11 gate).
 */
export { Shell } from './shell/Shell';
export { AuroraApp } from './app';
export { appRouter } from './router';
export { useUiStateStore } from './state/ui-state';
export { qk, createMobileQueryClient, type MobileDataProvider } from './query/query-client';
