/**
 * Capacitor app config (04 §3.2.5 — AD-3: NO server key, secret or credential
 * ever ships to the device; only the OneSignal *app* key is allowed here).
 *
 * The whitelisted native surface (04 §3.1) is the ONLY door to the platform
 * (apps/mobile never imports @capacitor/* directly; all adapters live in
 * @aurora/platform — 04 §7.2 anti-coupling test).
 */
// A3 (dyad/beta): OneSignal fail-fast. AD-3 — the app key comes from the build
// env (owner-provided `.env.local`, NEVER committed). The silent
// `REPLACE_WITH_…` fallback is removed: a missing key must make the build
// fail explicitly, not ship a placeholder. Mechanism of how `.env`/`.env.local`
// reaches the CLI is an owner decision (AD-3); the value is always in the env.
const oneSignalAppId = process.env.AURORA_ONESIGNAL_APP_ID;
if (!oneSignalAppId) {
  throw new Error(
    '[capacitor] AURORA_ONESIGNAL_APP_ID is required (A3 fail-fast, AD-3). ' +
      'Provide it via the build env (.env.local, owner-provided — never committed).',
  );
}

const config = {
  id: 'com.aurora.mobile',
  appId: 'com.aurora.mobile',
  appName: 'Aurora',
  webDir: 'dist',
  plugins: {
    // OneSignal (04 §3.2.5, AD-3): appKey only — the server key stays server-side.
    OneSignal: {
      appId: oneSignalAppId,
    },
  },
};

export default config;
