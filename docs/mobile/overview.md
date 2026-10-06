# Mobile Platform (Ionic React + Capacitor, Android Phase 1)

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1 platform, wave 7 device QA). Authority:
spine (no Electron V1, platform-agnostic core), `04-mobile` (whole pack), ADR
§23/§24/§26, `02-frontend` §9 (perf).

## 1. Platform stack

- Ionic React + TypeScript, mobile-first; React Router v6 routes + Ionic chrome
  (tabs = primary nav; detail screens open **over** the current tab — IonModal/
  IonSlides, never tab-switching; 44px tap targets — AI_RULES).
- Capacitor = the **only** native surface; the app never imports `@capacitor/*`
  directly (04 §7.2 anti-coupling test: sole door to native = `packages/platform`).
- Electron: Phase 2 only (ADR §23.1: no desktop agent/time in V1; §23.4: add an
  adapter, never rewrite; §23.5 "Mobile Only pour la livraison, Platform-Agnostic
  pour le cœur").

## 2. Adapter surface (04 §3.2 — the only public contracts the app consumes)

`AppLifecycleAdapter` · `LocalFileStorageAdapter` · `DocumentScanner` ·
`AudioArtifactProvider` · `RemoteNotificationAdapter` (OneSignal) ·
`LocalNotificationAdapter` · `NetworkStatusAdapter` — each = one implementation
behind one interface (AD-1). See [contract-catalog §5](../architecture/contract-catalog.md).

## 3. Whitelist (04 §3.1, frozen, additive-only)

`@capacitor/app` (lifecycle/back/permissions surface `BACKGROUND_ACTIVITY |
FOREGROUND_SERVICE | POST_NOTIFICATIONS`) · `@capacitor/status-bar` /
`@capacitor/keyboard` / `@capacitor/splash-screen` · `@capacitor/filesystem` (+
`@capacitor/http` for presigned upload) · `@capacitor/camera` ·
`@capacitor/media`/`@capacitor/audio` · `@onesignal/cordova` / `@onesignal/react` ·
`@capacitor/push-notifications` · `@capacitor/network`. Any plugin outside the
list = Foundation PR (AD-16c, ADR §21.10).

## 4. Lifecycle (normative, 04 §6.1)

`AppState = 'foreground' | 'background'` only (no reliable `killed` signal — kill =
taskbar swipe; return-to-boot = **re-read** the local store, AD-7; "retour
foreground = re-sync, pas de crash", 05 §2.1 rule). Permissions requested at first
use, never at boot (`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE` on first bg > 30 s
if OQ-04 = continuous sync; 04 §3.4).

## 5. Battery / data red lines (04 §6.2)

Background sync interval ≥ 5 min, no polling (04 imposes, 03 §5.7 defines
`minSyncIntervalMs`); memory: lazy + memo rule (02 §9.2); perf SLOs (02 §9.1,
Sentry-enforced): **≤300 Ko JS gz initial, ≤1.5 s TTI (reference device Pixel 4a,
OQ-11), 30 fps on the Semantic Tree screen**; lists: `IonList` native by default,
`react-virtuoso` only > 100 items (OQ-09).

## 6. Notifications (04 §3.4)

Server-state-driven = OneSignal (server only, `fn-notifications`); local-deadline-
driven = Capacitor local (`scheduleLocal`); **never both for the same object**
(anti-double-push, test 04 §7). Focus suppression = `reduceForFocus` (see
[focus-mode/spec.md](../focus-mode/spec.md)).

**DESIGNED_NOT_IMPLEMENTED — local deadline queue (owner, 2026-10-05)** :
`scheduleLocal`/`cancelLocal` (`packages/platform/src/local-notification.ts`)
are typed seams only: the Capacitor 7 typed surface has no native queue API,
and the Android bridge (AlarmManager/WorkManager) lands in **wave 1**. Until
then the app-shell seam no-ops, and the 04 §7 anti-double-push test is
intentionally not written (it would be a dead test) — the GAP is declared
here and in the adapter's inline comments, and the split-rule guarantee stays
documented (04 §3.4) so no consumer of the seam assumes a live local channel.

## 7. Focus Controller platform validation (04 §4.1)

The Android validation of ADR §2.8's express rule: timer + notification reduction
= **promised**; app blocking = **not promised** (platform-impossible for a
consumer app — G-P1); DND = user-guided; Screen Pinning = optional (OQ-06).
- **v1.8 candidate (private deployment, 2026-09-22)**: dedicated device, sideloaded
  APK, **Device Owner (DPC)** → app blocking via `setPackagesSuspended` (API 29+,
  per-package suspendability pre-check); the consumer behavior above remains the
  fallback profile. Decision + provisioning + verification: `docs/focus-mode/spec.md`
  §0/§9; SPEC OQ-17 (blocking for freezing the Focus implementation).

## 8. QA strategy (wave 7, OQ-08)

Playwright (web target) for scenario E2E + **Capacitor driver on real Android
device** for signature scenarios (assumption ratified: Playwright; Appium =
fallback if device 14 unsupported — OQ-08); device smoke per 04 §7.1; 5 UX states
including `offline` on device.

## 9. Desktop strategy (Phase 2, documented, not built)

Platform-agnostic core (ADR §23.2/§23.3): reusable UI in `packages/ui`;
hooks/services/use-cases/repositories/types independent of Capacitor; native APIs
behind adapters; Electron adapter added later (native notifications, desktop
layouts) without rewriting the domain. Security baseline for that phase
(contextIsolation, no nodeIntegration, strict CSP, navigation allowlist, minimal
typed IPC) is planned — see [security/overview.md §5](../security/overview.md).

## 10. Tests

Per-adapter interface tests with mocked Capacitor (04 §7.2 a–e), lifecycle tests
(04 §7.1/§6.1), battery/throttle checks (04 §6.2), perf budgets in CI (02 §9.1).
