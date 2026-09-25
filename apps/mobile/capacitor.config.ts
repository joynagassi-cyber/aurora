/**
 * Capacitor app config (04 §3.2.5 — AD-3: NO server key, secret or credential
 * ever ships to the device; only the OneSignal *app* key is allowed here).
 *
 * The whitelisted native surface (04 §3.1) is the ONLY door to the platform
 * (apps/mobile never imports @capacitor/* directly; all adapters live in
 * @aurora/platform — 04 §7.2 anti-coupling test).
 */
const config = {
  id: 'com.aurora.mobile',
  appId: 'com.aurora.mobile',
  appName: 'Aurora',
  webDir: 'dist',
  plugins: {
    // OneSignal (04 §3.2.5, AD-3): appKey only — the server key stays server-side.
    OneSignal: {
      appId: process.env.AURORA_ONESIGNAL_APP_ID ?? 'REPLACE_WITH_ONESIGNAL_APP_KEY',
    },
  },
};

export default config;
