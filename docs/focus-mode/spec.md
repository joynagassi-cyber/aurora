# Focus Mode — Technical Specification

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 1 platform + wave 2 feature). **Re-opened
2026-09-22 under the private-deployment hypothesis (v1.8 candidate ADR — see §0).**
Authority: ADR §2.8, pack 04 §4 (platform validation under the consumer hypothesis),
pack 05 §4.4 (screens), mission §15–§22 + master mission §37 rules. No capability below
is marked "supported" without mechanism + permission + component + behavior + limits +
tests.

## 0. Decision record — v1.8 candidate (NOT a silent replacement of the frozen docs)

The normative validation of 04 §4.1 was done under the hypothesis **"consumer app
distributed normally (Play Store, many devices)"** and concluded: app blocking = NOT
POSSIBLE, product promises *restriction* only. **This hypothesis has changed**
(product decision, 2026-09-22):

```
PRIVATE SINGLE-DEVICE DEPLOYMENT (v1.8 candidate)
- ONE dedicated Android device owned by the user (Horeb)
- Aurora installed as a SIDELOADED APK (no Play Store distribution)
- device PROVISIONED AS DEVICE OWNER (Device Policy Controller = Aurora)
```

Under this hypothesis, Android **officially** provides `DevicePolicyManager
setPackagesSuspended(packageName, suspended)` (API 29+; device owner / profile owner, or
authorized delegation): a suspended app can no longer launch activities, its
notifications are hidden, it disappears from recents, it can't show dialogs/toasts or
make the device ring/vibrate — **while the network stays fully active** (suspension is
a per-package restriction, not a connectivity cut).

Consequence: the verdict table below is **per deployment profile**. Per the project's
own consistency conventions, this is recorded as **candidate ADR v1.8 (additive)**:
04 §4.1 remains the **degraded/fallback mode** (consumer device, no DPC); the packs are
not modified silently; ratification = OQ-17 (SPEC) before the Focus implementation is
frozen. The `FocusController` contract (04 §4.2) keeps its signature;
`isBlockingAvailable()` becomes a **deployment-profile detection** (true when DPC is
operational + pre-check passes, false otherwise) — the no-block-CTA rule of 04 §4.2
still applies to the false case, which is exactly the consumer fallback.

## 1. Target behavior (v1.8 nominal mode)

```
FOCUS SESSION
├── user-selected blocklist (chosen BEFORE the session, never hardcoded):
│     TikTok, Facebook, Instagram, WhatsApp, YouTube, X, Telegram, … (any user apps)
├── system-level suspension      → setPackagesSuspended(names, true)
├── their notifications          → hidden by the system (suspension effect)
├── Internet                     → ACTIVE (sync, AI, KB, search all keep working)
├── Aurora itself                → ACTIVE, NEVER suspended (the DPC package is
│                                  protected; blocklist also validates this at runtime)
├── session duration             → managed by Aurora (timer + persisted session row)
└── session end / crash / reboot → setPackagesSuspended(names, false) (restore, §7)

```

## 2. Verdicts (v1.8 candidate — per capability)

| Capability | Private DPC deployment | Fallback (consumer device, no DPC) | Basis / limits |
|---|---|---|---|
| Block user-selected apps | **SUPPORTED** — `setPackagesSuspended` (DPC) | NOT POSSIBLE (04 §4.1 verdict, G-P1) | API 29+; some packages are **not suspendable** (system packages, active launcher, default dialer, package installer/uninstaller, permission controller — exact list **NEEDS_VERIFICATION on the target Android version, OQ-17**). TikTok/FB/IG/WhatsApp and ordinary user apps are precisely the suspendable class |
| Suppress those apps' notifications | **SUPPORTED** — hidden by suspension (system effect) | Aurora's own notifications only (04 §3.4 `reduceForFocus`) | DPC may also request Notification Policy access for whole-device DND (optional, out of V1 nominal scope) |
| Internet stays active | **SUPPORTED by non-interference** (suspension ≠ network control) | same | test scenario "Internet remains active" |
| Aurora usable during session | **SUPPORTED** — DPC package never suspended (self-suspend is rejected by Android; runtime blocklist guard adds a second check) | same | guard in the adapter |
| Duration + end-of-session auto-restore | **SUPPORTED** — timer in Aurora; `setPackagesSuspended(names, false)` on end/expiry; crash/reboot recovery via boot receiver (§7) | in-app scope only (04 §4.1) | session row = source of truth |
| Incoming calls — Level 1 (silence) | **PLATFORM_DEPENDENT / EXPERIMENTAL option** — via DND "calls from starred contacts" (user setting) or `CallScreeningService` if the user grants the call-screening role | not available as product feature | `CallScreeningService` (API 23+): role selected by user in Settings, the service must answer within ~5 s, per-device/OEM variability; **experimental opt-in, never a V1 promise** |
| Incoming calls — Level 2 (block) | **PLATFORM_DEPENDENT / EXPERIMENTAL option** — `CallScreeningService` allow/silent/block; urgent calls must ring | same | explicit opt-in + documented limitations (unknown callers, allowlist, emergency calls always ring); no UI before Foundation decision + additive ADR |
| Distribution | **No Play Store needed** for this deployment | — | sideloaded, signed APK; updates via adb/MDM channel (Phase 2: MDM), NOT via Play review — Play policies therefore do not constrain the V1 Focus design (re-run this analysis for any future consumer distribution) |

`isBlockingAvailable()` (04 §4.2) semantics under v1.8: **detection, not a constant** —
returns true when `DevicePolicyManager` reports Aurora as device owner AND the
blocklist pre-check (§4) passed; the UI rule of 04 §4.2 (never show a block CTA when
false) is unchanged and now simply reflects the actual deployment profile.

## 3. What Aurora must NOT do (invariants)

- never suspend its own package (rejected by the platform; adapter guard as second
  line of defense);

## 4. Session lifecycle (v1.8 nominal)

```
start: load FocusSession (AD-15, 03 §4.2 focus_sessions)
  → PRE-CHECK (new, v1.8): for each blocklist package:
       isDpcActive && setPackagesSuspended(pkg, true) trial-validated at provisioning
       (OQ-17 suspendability matrix) → any rejected package is reported to the user
       with its reason and EXCLUDED (session starts with the remaining set; empty
       set = session cannot start in blocking mode → fall back to restriction mode)
  → apply: setPackagesSuspended(blocklist, true); reduceForFocus(true) (Aurora's own
     notifications, 04 §3.4); start timer
  → active (state §6): timer on system clock (04 §3.6.9 rule: app kill loses nothing,
     AD-7); background = timer continues (in-app behavior per 04 §7.3)
  → end (manual/expiry): setPackagesSuspended(blocklist, false); reduceForFocus(false);
     FocusSessionBilan (SSoT shape 01 §4.1) ; persist

```

## 5. Calls (experimental option, separate opt-in)

`CallScreeningService` behind a user-selected Android role ("call screening app").
Behavior: incoming call → service answers within the ~5 s framework window
(NEEDS_VERIFICATION on target device) → policy: allow / silent / block, with
**emergency calls always ring**, an allowlist (starred/authorized contacts), and
unknown-caller policy (default: ring-as-usual). V1 status: **documented experimental
option, explicitly enabled by the user, never implied by "Focus Mode"** — the nominal
focus session does not touch call handling at all (calls ring as usual). Any UI for it
requires the Foundation decision + additive ADR (recorded in 04 §4.3 candidate, OQ-17
scope).

## 6. Session state (v1.8)

`scheduled → starting → prechecking → active(blocking|restricted) → paused →
ending → completed` / `active → interrupted → restoring → restored` / `any →
failed(restore-scheduled)`.

`FocusSession` fields (AD-15 entity, 03 §4.2; extension documented as additive):
id, start, planned/actual duration, **blocklist (selected packages + suspendability
result per package)**, notification policy, call policy (V1: `ring_as_usual` unless
experimental option enabled), **system state snapshot = the applied suspension set
(the DPC state IS the snapshot — no other system settings are touched in V1)**,
interruption reason, end reason.

## 7. Restoration discipline (mandatory)

- **Before applying**: snapshot = the exact package set being suspended (nothing else
  is modified in V1).
- **On end / expiry**: `setPackagesSuspended(set, false)` — total restore within
  Aurora's scope (the apps were *suspended by Aurora*, so Aurora restores them).
- **Crash / force-close**: session row = `interrupted`; default restore policy =
  **un-suspend everything** (device returns to normal), then UI offers "resume session"
  (re-applies the suspension) or "close session" — the user decides, never silent.
- **Reboot**: device policy persists across reboot; a **BOOT_COMPLETED receiver**
  (custom native module, `packages/platform`, Foundation) reads the session row and
  runs the same crash path (default: un-suspend + offer resume).
- **Factory reset**: **wipes the device owner** (documented Android behavior) → the
  device must be re-provisioned (§9) before it is an Aurora device again; until then
  the app is a plain consumer app (restriction mode). This is a *planned* limitation of
  DPC deployments, not a defect — recovery = the provisioning procedure.
- **Permission/role revoked**: DPC role cannot be unilaterally revoked by the user in
  settings (it's a provisioning state, not a runtime permission); the emergency path
  is §9.4.

## 8. Notifications, precisely

- **Suppressed during session:** blocklisted apps' notifications (suspension effect)
  + Aurora's own non-critical notifications (`reduceForFocus`, 04 §3.4: OneSignal
  server mute + local mute).
- **May pass:** notifications of non-blocklisted apps (V1 nominal: Aurora doesn't
  touch whole-device DND — that would be a device-owner *power* used beyond scope,
  documented as an option, not enabled), calls (§5).
- **Restore:** §7 (end/expiry/crash/reboot all end in the same un-suspend +
  `reduceForFocus(false)` path); an expired timer runs the `ending` path, identical to
  manual end.
- **App killed / reboot:** suspension state is *system* state (survives the process);
  the boot receiver is what reconciles it (§7) — crash-safe by construction.

## 9. Provisioning & verification procedure (to run on the target phone BEFORE freezing the implementation — OQ-17)

### 9.1 Provisioning (AOSP test procedure, re-verify on target device)

```
1. FACTORY RESET the dedicated phone (device-owner provisioning is only possible on a
   non-provisioned device) — wipe all data; the phone becomes an Aurora device.
2. Boot with NO user account added (the test procedure requires the device to have no
   accounts; document this as a deployment constraint for the user).
3. Install Aurora (signed APK, sideload) — Aurora must contain a `DeviceAdminReceiver`
   (custom native module in `packages/platform`, owner Foundation; NOT a Capacitor
   plugin → whitelist exception = Foundation PR, AD-16c) declared with
   `android.permission.BIND_DEVICE_ADMIN` + a device_admin metadata resource.
4. `adb shell dpm set-device-owner com.aurora/.AuroraDeviceAdminReceiver`
   → Aurora becomes the Device Policy Controller.
5. Verify: `adb shell dpm list-owners`; in-app `isDpcActive() = true`.
```

Every step above is `NEEDS_VERIFICATION` on the target phone (Android version, OEM
firmware quirks, `dpm` shell availability) — the procedure is the **documented**
procedure (AOSP test setup + DPM API reference), the run on the real device is the
wave-0 validation (owner Foundation + Productivity).

### 9.2 Suspendability matrix (per candidate package, on target device)

For each app the user may block: `setPackagesSuspended(pkg, true)` → check: activity
launch denied? notifications hidden? gone from recents? then `false` and confirm
return. Record the outcome per package. **Expected non-suspendable class (verify, don't
assume):** system packages, the active launcher, the default dialer, the package
installer/uninstaller, the permission controller, and Aurora itself. The blocklist UI
displays, per app: `suspendable | not-suspendable (<reason>) | aurora-protected`.

### 9.3 API-level check

`setPackagesSuspended` = API 29+ (Android 10+). Verify the target phone's
`ro.build.version.sdk` ≥ 29 (and the exact method surface in use, incl.
`getPackagesSuspended()` for the boot-receiver reconciliation).

### 9.4 Emergency path (documented)

If the device is ever stuck with apps suspended and Aurora is unreachable (e.g.,
corrupt APK): `adb shell pm`/`dpm` tooling or a **factory reset** restores the device
(accepting the §7 wipe of the DPC state, then re-provision). This is the documented
last resort, not a supported daily flow.

## 10. Contract (04 §4.2 base + v1.8 additive extension — proposed, ratify before wave 2)

```ts
// base (04 §4.2, unchanged signature)
interface FocusController {
  startSession(opts): Promise<FocusSession>;
  endSession(): Promise<FocusSessionBilan>;
  reduceNotifications(on: boolean): Promise<void>;
  isBlockingAvailable(): Promise<boolean>;   // v1.8: DETECTION (DPC + pre-check), not a constant
}
// v1.8 additive (proposed — additive = normal, Consistency Conventions)
interface FocusControllerDpc {
  precheckBlocklist(names: string[]): Promise<BlocklistPrecheck>; // per-package suspendable/reason
  applyBlocklist(names: string[], on: boolean): Promise<{ applied: string[]; rejected: {pkg: string; reason: string}[] }>;
}
```

Architecture (never native code in the domain):

```
FocusController / FocusControllerDpc (port, packages/domain)
      ↓
AndroidFocusAdapter / DpcAdapter (packages/platform — custom native module, Foundation)
      ↓
DevicePolicyManager (Android) — the ONLY system surface touched in V1 nominal mode
```

## 11. Data & observability

`FocusSession` (+ v1.8 blocklist/snapshot fields) persisted in `focus_sessions`
(Productivity, 03 §4.2) — durable truth across kill/reboot. `FocusSessionBilan`
(SSoT shape 01 §4.1, ChartSpec `focusBilan` 05 §3.6.9). Observability: Sentry
(session lifecycle errors), PostHog (start/end/restore events, blocklist size,
pre-check rejection rate), `job_logs` not involved (device capability, not a server
job — the DPC call is synchronous local, no heavy work, AD-8 not triggered).

## 12. Mobile strategy & desktop

V1 = the dedicated Android device (DPC). Consumer devices (e.g., a second phone) =
restriction fallback mode (04 §4.1) — the app must run in BOTH profiles (the
detection, §2, makes this the same binary). Phase 2 desktop: re-run this capability
table for the desktop OS before promising app restriction there (different platform).

## 13. Mandatory test scenarios

consumer list (unchanged): start · blocklist honored (in-app scope) · "open blocked
app" = documented limitation in consumer mode · receive notification · receive phone
call · Internet remains active · Aurora remains usable · pause · resume · end ·
restore · crash recovery · permission revoked · device reboot.

v1.8 DPC additions (wave-0 provisioning tests + wave-7 E2E):

1. provisioning: factory reset → no accounts → `dpm set-device-owner` →
   `isBlockingAvailable() = true`.
2. `precheckBlocklist` reports per-package status; non-suspendable packages shown
   with reasons; blocklist excluding Aurora is rejected.
3. session start suspends the set (verify: activities denied, notifications hidden,
   recents clean) while Internet/Aurora/search remain usable.
4. session end un-suspends the exact set (diff against snapshot = empty).
5. reboot mid-session → BOOT_COMPLETED receiver → un-suspend default + resume offer.
6. factory reset → DPC wiped → app runs in restriction fallback; re-provisioning
   procedure documented and re-runnable.
7. emergency: device with stuck suspensions → §9.4 path documented.
8. calls (experimental only): with the role granted, silence/block per policy;
   emergency calls always ring; no role = calls ring as usual (documented).

## 14. Limits & risks (documented, not hidden)

- **Factory reset wipes the DPC** (planned limitation; recovery = §9.1 re-provisioning;
  the phone has no user accounts + all data wiped = deployment constraint).
- **Device owner is a large grant** (install/uninstall, accounts, camera, lock, …):
  V1 uses the *minimum* — `setPackagesSuspended` + (optionally) Notification Policy
  access; all other DPM powers are documented as **not used** (least-privilege rule,
  review checklist).
- **Suspendability is per-package and per-Android-version** — the §9.2 matrix is
  re-run at each Android level of the target device (drift item, like OQ-12).
- **Updates** to Aurora on the DPC device go through adb/MDM channel (no Play);
  a broken update of the DPC app = the §9.4 emergency path (risk documented).
- **Consumer distribution in the future** (if V1.x ever ships to Play): this entire
  section collapses back to 04 §4.1 restriction mode — re-run the platform analysis.

## 15. Focus data model (master mission S41)

Named entities (SSoT `packages/domain`, AD-15; table owner = Productivity,
03 S4.2):

```ts
interface FocusSession {
  id: string;                    // ULID
  userId: string;
  startedAt: string;            // ISO 8601
  plannedMinutes: number;
  actualMinutes: number;        // filled on end
  taskRefs: string[];           // optional task IDs this session targets
  blocklist: FocusAppRule[];   // v1.8: selected packages + precheck results
  notificationPolicy: FocusNotificationPolicy;
  callPolicy: FocusCallPolicy; // V1: 'ring_as_usual' unless experimental
  systemStateSnapshot: string[]; // v1.8: the exact package set suspended
  interruptions: { at: string; reason: string; durationSec: number }[];
  endReason: 'manual' | 'expiry' | 'crash' | 'reboot' | 'restoring';
  endedAt: string | null;
}

interface FocusAppRule {
  packageName: string;          // e.g. "com.zhiliaoapp.musically" (TikTok)
  label: string;               // user-visible name
  suspendable: boolean;        // precheck result (v1.8, OQ-17)
  rejectReason?: string;       // 'system_package' | 'active_launcher' | 'default_dialer' | 'aurora_protected' | ...
  suspended: boolean;          // current state (mirrors DPC state)
}

interface FocusNotificationPolicy {
  scope: 'aurora_only' | 'device_wide'; // V1 nominal: aurora_only (reduceForFocus)
  suppressCategories: string[];         // e.g. ['social', 'entertainment']
  exceptions: string[];                 // package names that may still notify
}

interface FocusCallPolicy {
  mode: 'ring_as_usual' | 'silence' | 'block'; // V1: ring_as_usual; block = experimental (G-P2)
  allowlist: string[];                   // phone numbers / contact IDs that always ring
  emergencyAlwaysRings: true;           // invariant, not configurable
}

interface FocusSessionBilan {
  // SSoT shape pinned in 01 S4.1 + 05 S3.6.9 (G-H1 RESOLVED)
  sessionId: string;
  plannedMinutes: number;
  actualMinutes: number;
  interruptions: number;
  score: number;          // 0-100, composite (focus adherence, interruption count, task completion)
  endedAt: string;
}
```

**Relations:**

```
Task (productivity.tasks)
  | taskRefs
  v
FocusSession (productivity.focus_sessions, 03 S4.2)
  | sessionId
  v
FocusSessionBilan (productivity, 01 S4.1 SSoT)
  |
  v
ProgressEvidence (progress.progress_evidences, sole-producer F-07)
  | type = 'discipline', sourceEventId = FocusSession end
  v
ProgressEvidenceCreated (AD-9 event, Progress sole producer)
```

- A focus session MAY target zero tasks (pure focus, no task link).
- The bilan is produced by the Productivity module on session end;
  Progress reads it via the public view + `ProgressEvidenceCreated`
  event (F-07: Progress is the sole producer of evidence rows;
  Productivity never writes `progress_evidences` directly).
- `FocusAppRule.suspendable` is filled at pre-check time (focus spec
  S4); the per-package result is persisted for crash-recovery
  reconciliation (S7: the boot receiver re-reads `systemStateSnapshot`
  and restores only the packages that were actually suspended).
