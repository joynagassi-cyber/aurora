# Permission Matrix (Deliverable H)

Platform permission → module → reason → fallback if denied → where enforced/tested.
V1 = Android (consumer, Google Play). Server-side items are included for completeness.

## 1. Device permissions (Android)

| Permission / role | Platform | Module / component | Reason | Fallback if denied | Enforcement & test |
|---|---|---|---|---|---|
| `POST_NOTIFICATIONS` | Android 13+ | Focus reminders, due-task local notifications (`LocalNotificationAdapter`, pack 04 §3.4) | schedule local reminders | app fully functional; due items stay visible in-app, only notifications off | requested **on first use, never at boot** (04 §3.4); 04 §7.2 |
| `FOREGROUND_SERVICE` | Android 14+ (OQ-04, unresolved) | background sync > 30 s (if Data team enables continuous bg sync, 03 §5.7) | keep PowerSync syncing in background | throttled sync (`minSyncIntervalMs` ≥ 5 min, no polling); offline = first-class state | decided by `packages/data` (OQ-04); requested on first bg > 30 s, never at boot (04 §3.2.1) |
| `BACKGROUND_ACTIVITY` | Android (Capacitor) | app-state awareness (`AppLifecycleAdapter`) | resync on foreground return (no crash, 05 §2.1 "jamais un thème qui change silencieusement") | degraded: state restored from local store on relaunch | 04 §6.1 lifecycle rules |
| Camera (`CAMERA`) | Android | `DocumentScanner` (course capture, 04 §3.2.3) | multi-page document capture | `source: 'gallery'` path; manual entry degradation (AD-1 last paragraph) | 04 §7.2(c) |
| Microphone / audio capture (`RECORD_AUDIO` / storage) | Android | `AudioArtifactProvider` (audio courses, voice notes, 04 §3.2.4) | record → upload → optional transcription job | audio playback works; transcription optional/absent → degraded (AD-1) | 04 §7.2(d) |
| Local storage / filesystem | Android | `LocalFileStorageAdapter` (preview caches, scan temp) | blobs + upload via presigned URL | in-memory where feasible; no R2 key ever on device (AD-3) | 04 §7.2(b) anti-leak |
| Media read (SAF / scoped storage) | Android | import from gallery (`DocumentScanner`, resources) | document import | camera-only path | 04 §7.2(c) |
| **Do Not Disturb access** (`NotificationPolicyAccessManager`) | Android 6+ | Focus Mode system-wide suppression | stronger suppression during a session | **V1: NOT requested programmatically** (no custom native plugin in the whitelist, 04 §3.1) — user is *guided* to enable DND manually (04 §4.1 item 2); Aurora's own notifications are suppressed in-app regardless (G-P3) | verdict in [focus-mode/spec.md §3](../focus-mode/spec.md); decision to add a custom plugin = Foundation PR (AD-16c) |
| **Call screening role** (`CallScreeningService` role) | Android 6+ | incoming-call silence/block during Focus (mission §18, product request) | Level 1 silence / Level 2 block | **V1: NOT requested, NOT promised** (role-gated, OEM/Play variability — G-P2). Documented as platform-dependent option; any UI requires Foundation decision + Play-policy review + additive ADR | [focus-mode/spec.md §4](../focus-mode/spec.md) |
| **Screen Pinning** (`startLockTask`) | Android 5+ (pinning UX API 24+ on modern devices; **OQ-06 unresolved**) | optional "stay on Aurora" during a session | reduce app-switching distraction | pure in-app focus (timer + notification reduction) remains functional; pinning = user opt-in, never silent (04 §4.1 item 3) | BEST-EFFORT / OPTIONAL / NEEDS_VERIFICATION (G-P4) |
| App-blocking (arbitrary third-party apps) | Android | — | — | **NOT POSSIBLE for a consumer app** (no public API; Digital Wellbeing = system feature; DevicePolicyManager = MDM; Accessibility = Play risk — G-P1, 04 §4.1 verdict). Product promises *restriction*, never blocking | `isBlockingAvailable()` = `false` on V1; UI must not show a "block apps" CTA (04 §4.2 rule) |

## 2. Server-side authorizations

| Item | Where | Rule | Test |
|---|---|---|---|
| Supabase RLS | every table (01 §2.2) | per-module schema + `user_id` policies; cross-user access = denied; `service_role` reads PowerSync views **via RLS policies, not BYPASSRLS** | RLS penetration test on **every** table, blocking for policy migrations (01 §7) |
| Auth (Supabase Auth) | app ↔ Edge Functions | JWT auto-refresh; expired/failed → login screen; the device **cannot** call Edge Functions without identity (01 §6) | 01 §6 error paths |
| Secrets | Supabase Secrets / Cloudflare Secrets Store | provider keys (Agnes, Cloudflare, Groq, Cerebras, …) **never** in code, **never** on device (AD-3, 01 §5.6) | CI grep (SPEC wave-0 gate) |
| OneSignal | app vs server key split (04 §3.2.5) | `appKey` (app-specific) = `capacitor.config.ts`, owner Foundation; **server key** lives in `fn-notifications` only; push token issued server-side | 04 §7.2(e): `capacitor.config.ts` contains no server-side key |
| R2 | `fn-*` presigning (01 §5.4) | presigned URLs, short TTLs; no bucket/key in client | 04 §7.2(b) |
| Agent tool permissions | kernel (AD-12, ADR §5) | Permission Context: authorized / confirmed / forbidden actions; **confirmation required for important or irreversible actions**; destructive ops always confirmed; read/write/destructive classes explicit | kernel tests wave 3 (01 §7 family + agent/kernel.md §9) |
| Electron (Phase 2, planned baseline — mission §26, not a V1 artifact) | desktop adapter | `contextIsolation=true`, `nodeIntegration=false`, minimal preload, strict CSP, navigation allowlist, minimal typed IPC | wave Phase 2 |

## 3. Rule of thumb (used across this documentation tree)

A capability is documented as **SUPPORTED** only when this row exists: mechanism +
permission/role + responsible component + expected behavior + limits + test. Anything
otherwise is labeled **BEST-EFFORT / OPTIONAL / PLATFORM-DEPENDENT / NOT POSSIBLE /
NEEDS_VERIFICATION** (mission §35 absolute rule).
