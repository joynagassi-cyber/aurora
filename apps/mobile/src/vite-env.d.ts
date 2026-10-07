/**
 * Vite client env + asset module types.
 *
 * Declared locally so the app typechecks even before `vite` is installed
 * (the owner runs `pnpm install`); when the real Vite is present, add
 * `/// <reference types="vite/client" />` and these fall back harmlessly.
 */
interface ImportMetaEnv {
  /** `SUPABASE_URL` (AD-3, build env / .env.local). */
  readonly VITE_SUPABASE_URL?: string;
  /** `SUPABASE_PUBLISHABLE_KEY` (publishable only, AD-3). */
  readonly VITE_SUPABASE_PUBLISHABLE_KEY?: string;
  /** `POWERSYNC_URL` (the relay). */
  readonly VITE_POWERSYNC_URL?: string;
  readonly [key: string]: string | undefined;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

// Vite bundles CSS/asset imports; declare them for the type-checker.
declare module '*.css';
declare module '*.png';
declare module '*.svg';
