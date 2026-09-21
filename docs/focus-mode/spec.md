# Focus Mode — Technical Specification (Deliverable D)

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1 platform, wave 2 feature). Authority: ADR §2.8
(incl. the express rule: *"Le blocage natif doit être validé techniquement par plateforme
avant de promettre un blocage absolu"*), pack 04 §4 (the platform validation), pack 05 §4.4
(screens), mission §15–§22 requirements. This document separates, per mission §35:
*architecture target / current design / planned implementation / platform capability /
platform limitation*. No capability below is marked "supported" without mechanism +
permission + component + behavior + limits + tests.

## 1. Functional target (user-facing, per ADR §2.8 + mission §15)

A focus session during which Aurora reduces (and, where the platform allows, restricts)
digital distraction while **Internet stays fully active**. The user selects which
applications/notifications to restrict — Facebook/TikTok/WhatsApp are examples, **not a
hardcoded list** (configuration on the user side; V1 in-app scope = Aurora's own
notifications, see §3 verdicts).

```
Focus Session START → Internet REMAINS ACTIVE → distracting apps restricted (within what
Android allows a consumer app) → distracting notifications suppressed (Aurora's, V1) →
social networks inaccessible only if the user restricts them manually (system features) →
Aurora work fully functional (sync, search, AI, KB, cloud services)

```

## 2. What "block" legally means on Android (platform capability table)

| Capability | Android mechanism | Permission / role | Component (Aurora) | Behavior | Limits | Verdict |
|---|---|---|---|---|---|---|
| Block arbitrary apps | **None for a third-party consumer app.** Digital Wellbeing App Timers = system feature, no third-party API; `DevicePolicyManager` = device owner/MDM only; AccessibilityService blocking = Google Play policy risk; launcher-based enforcement = out of scope | — | — | Aurora cannot guarantee another app won't open | pack 04 §4.1 verdict (normative): *never promise absolute blocking* | **NOT POSSIBLE** (consumer app, Play-compliant) — product promises **restriction**, and `isBlockingAvailable()` returns `false` (UI never shows a "block apps" CTA, 04 §4.2) |
| In-app focus (timer/Pomodoro + session) | app timer + `LocalNotificationAdapter` (`@capacitor/push-notifications`) | `POST_NOTIFICATIONS` optional | `FocusController` → `AndroidFocusAdapter` (`packages/platform`) | countdown, local reminder at deadline, session persisted (`FocusSession`) | in-app only; background timers depend on app being alive (FOREGROUND_SERVICE = OQ-04, separate concern: sync, not timer) | **SUPPORTED** (in-app) — tests: 04 §7.1/§7.3 |
| Suppress **Aurora's** notifications (in-app + OneSignal) | `RemoteNotificationAdapter.setSubscribed(false)` (server-side OneSignal mute) + `LocalNotificationAdapter.reduceForFocus(true)` (silence non-critical local notifications) | no extra permission (builds on §1 rows) | `packages/platform` adapters | all non-critical notifications silenced during the session; restore on end | scope = notifications Aurora emits; other apps' notifications NOT suppressed (that's system DND) | **SUPPORTED** (V1) — test: 04 §7.2(e) + focus §11 scenario 9 |
| System-wide DND (suppress all apps' notifications, incl. calls → "calls from starred contacts") | `NotificationManager` + DND interruption filters; programmatic control needs Notification Policy access (user grant in system settings) | user grant, system settings | **Not in V1**: no custom native plugin in the 04 §3.1 whitelist | V1 = Aurora **guides** the user to the DND switch (recommended, not imposed, 04 §4.1 item 2); a custom plugin + policy access = Foundation PR (AD-16c) + user grant | if added: DND profile is user-owned; Aurora must not toggle silently | **NOT POSSIBLE in V1 (automated)** — PLATFORM-DEPENDENT option, `OPTIONAL` if a custom-plugin decision is taken (wave 0/1) |
| Stay on Aurora (limit switching) | Screen Pinning `startLockTask()` | user explicit opt-in per session | optional native plugin (not in V1 whitelist) | pins Aurora; user approves explicitly | availability on target Android versions = **OQ-06 (NEEDSVERIFICATION)**; never silent | **BEST-EFFORT / OPTIONAL** |

## 3. Internet during a session (mission §16 — explicit constraint)

Aurora's Focus mechanisms **never touch the network stack**: no Wi-Fi/mobile-data
disabling is part of the design (and a consumer app cannot do it anyway). During a session:
sync continues (PowerSync; background throttling is governed by `minSyncIntervalMs`, 03
§5.7 — independent of Focus), AI/KB/research/search remain usable, OneSignal stays muted
only for **notifications**, not connectivity. Verdict: **SUPPORTED by non-interference**
(documented as a non-goal, test scenario 7 of §11: "Internet remains active").

## 4. Calls (mission §18 — product request: "block calls if technically possible")

Documented as two levels, each with its platform reality:

- **Level 1 — silence incoming calls.** Achievable only through user-controlled system
  features (DND "calls from starred contacts only", or Call Screening settings) or a
  `CallScreeningService` role grant. `CallScreeningService` (API 23+): the app must be
  selected by the user as the device's call-screening app; it must answer framework calls
  within a strict deadline (order of seconds; missed deadline = framework falls back to
  normal ring); Google Play reviews the category; OEM/region variability makes it
  non-uniform. **Verdict V1: NOT PROMISED.** If ever built: role + consent UX + Play
  policy review + constructor-permission checks + urgent-call handling + allowlists
  (starred/authorized contacts) + unknown-call policy, all documented before any UI
  appears. Status: **PLATFORM-DEPENDENT / NEEDS_VERIFICATION** (G-P2).
- **Level 2 — real call blocking.** Same role, `silentCall()`/`blockCall()` semantics.
  **No documentation in this tree may state "Aurora blocks calls"** — the capability is a
  platform possibility, not a product guarantee. Status: **NOT POSSIBLE as a V1 promise**;
  an option behind a dedicated Foundation decision + additive ADR (mission §18 compliance
  = document the constraint, do not promise it).
- V1 fallback behavior: calls ring as usual during a session (documented limitation,
  mission §22 "if a full restoration is not guaranteed, document the limitation").

## 5. Contract

Current frozen contract (04 §4.2, SSoT `packages/domain`):

```ts
export interface FocusController {
  startSession(opts: { durationMin?: number; taskIds?: string[]; context: string }): Promise<FocusSession>;
  endSession(): Promise<FocusSessionBilan>;      // bilan: actual duration, interruptions, focus score (G-H1: shape to be defined)
  reduceNotifications(on: boolean): Promise<void>; // via platform adapters (04 §3.2.5)
  isBlockingAvailable(): Promise<boolean>;         // V1 Android = false (never hide it — don't promise it)
}
```

**Proposed additive extension** (mission §20; additive = normal per Consistency
Conventions; owner Productivity + Foundation; ratify before wave 2 — recorded as C-5 in
`adr-compliance-report.md`, not silently merged):

```ts
// proposed — additive superset of 04 §4.2
interface FocusController {
  startSession(config: FocusSessionConfig): Promise<FocusSession>;
  pauseSession(id: string): Promise<void>;
  resumeSession(id: string): Promise<void>;
  endSession(id: string): Promise<void>;
  getStatus(): Promise<FocusSessionStatus>;
  restoreSystemState(): Promise<void>;   // restores whatever the session modified (V1: Aurora-own notification state only — §6)
  isBlockingAvailable(): Promise<boolean>; // unchanged: false on V1 Android
}
```

Architecture (never native code in the domain):

```
FocusController (port, packages/domain)
      ↓
AndroidFocusAdapter (packages/platform)
      ↓
Native Android APIs (in-app timer, Capacitor local notifications, OneSignal server mute,
optional Screen Pinning plugin — each behind its own whitelist entry)
```

## 6. Session state (mission §21)

`FocusSession` (AD-15 entity, local table `focus_sessions`, owner Productivity, 03 §4.2):
id, start, planned duration, actual duration, selected blocked/restricted targets,
notification policy, call policy (V1: `ring_as_usual` — §4), system state snapshot,
interruption reason, end reason.

State machine: `scheduled → starting → active → paused → ending → completed` /
`active → interrupted → restoring → restored` / `any → failed`. Persistence = the local
`focus_sessions` mirror + server record (Productivity module, 01 §4.1) = the durable truth.

## 7. Restoration (mission §22 — mandatory discipline)

- **Capture** (before applying policy): OneSignal subscription state, scheduled local
  notifications, timer state, UI state.
- **Apply**: Aurora focus policy (§2 rows, in-app scope).
- **Restore**: exact previous state on end, expiry, interruption, crash, force-close,
  reboot, permission revocation — driven by the persisted `FocusSession` row (source of
  truth; on relaunch, a session in `interrupted`/`restoring` → UI offers resume-or-close
  and re-applies the restore path).
- **Limitation (documented, V1)**: Aurora modifies **only its own** system-visible state
  (its push subscription, its local notifications). It never mutates system settings in V1
  (no programmatic DND, no roles) → **there is no OS-level state to restore**; restoration
  is total within Aurora's scope. If a custom DND plugin is ever added (G-P3), a
  snapshot/restore of the DND profile becomes a **hard requirement of that plugin's PR**
  plus platform tests.

## 8. Notification behavior (mission §17, precisely)

- **Suppressed during session (V1, in-app scope):** all OneSignal pushes to the user
  (`setSubscribed(false)`, server-side) + all non-critical local notifications
  (`reduceForFocus(true)`).
- **May pass:** system notifications of other apps (V1: only if the user enabled DND
  themselves — Aurora does not), calls (V1: ring as usual — §4), critical local alarms if
  the user marked them critical (design detail, wave 2; default = suppressed).
- **Restore previous state:** §7; on session **expiry** (timer end) the adapter path is
  identical to `endSession`.
- **User leaves Aurora / crash / reboot:** notification suppression state is derived from
  the persisted session row, not from in-memory flags → crash-safe by construction
  (OneSignal subscription is server state; local schedules are re-derived on boot, 04 §7.1
  kill test).

## 9. Data & observability

`FocusSession` + `FocusSessionBilan` (G-H1 shape pending: proposed
`{ sessionId, startedAt, endedAt, durationSec, interruptions[], focusScore, taskIds[] }`
per coherence-review H1 correction) feed the analytics (05 §4.4, G2 via
`DataVisualizationRenderer` — pack 05 carries the contract, not pack 02, 04 §4.1 item 4).
Sessions are Productivity-owned (AD-15 mapping 03 §4.2).

## 10. Mobile strategy & future desktop

V1 Android: everything above. Phase 2 desktop (ADR §23.4): a desktop `FocusController`
adapter (per-app restrictions ARE possible on desktop OSes — different platform, re-run
this capability table for the desktop OS before promising anything; no desktop work in V1).

## 11. Mandatory test scenarios (mission §30 + 04 §7.3)

1. start session · 2. restricted-app list honored (in-app scope) · 3. "open blocked app" =
documented **limitation**: on Android V1 the user *can* open other apps (restriction ≠
blocking — the test asserts the documented behavior, not a nonexistent one) · 4. receive
notification during session (Aurora's = suppressed; other apps' = pass, by design) ·
5. receive phone call (rings as usual in V1 — documented limitation, §4) · 6. Internet
remains active (sync/AI/KB usable) · 7. Aurora remains usable · 8. pause · 9. resume ·
10. end · 11. restore state (snapshot diff = empty within Aurora scope) · 12. crash
recovery (kill app mid-session, relaunch → session row `interrupted`, restore path) ·
13. permission revoked mid-session (`POST_NOTIFICATIONS` revoked → timer/UI still work,
notifications silently off, documented degradation) · 14. device reboot (session row
recovered, OneSignal state reconciled from server).
