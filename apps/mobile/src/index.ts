/**
 * @aurora/mobile — Ionic React + Capacitor app shell + vertical feature slices
 * (presentation / ui-state / use-cases / data-access / platform, 02 S4).
 * A feature slice never imports a sibling slice (AD-2/AD-13, 02 S11 gate).
 */
export { Shell } from './shell/Shell';
export { AuroraApp } from './app';
export { appRouter } from './router';
export { useUiStateStore } from './state/ui-state';
export {
  qk,
  createMobileQueryClient,
  mobileDataProviderFrom,
  type MobileDataProvider,
} from './query/query-client';
export {
  createAuroraDataProvider,
  type AuroraDataEnv,
  type AuroraDataProvider,
} from './lib/boot-data';
export {
  PRODUCT_MODES,
  MODE_PROFILES,
  getModeProfile,
  effectiveEmphasis,
  type ProductMode,
  type ModeProfile,
  type Emphasis,
} from './modes/product-modes';
export {
  buildCommandCatalog,
  filterCommands,
  type PaletteCommand,
  type CommandCatalogSource,
} from './modes/command-palette';
