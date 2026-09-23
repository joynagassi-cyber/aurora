# Integrations Module — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2+). Authority: ADR §7/§8 (`IntegrationProvider`,
Composio), `01-backend` §4.7/§5.2 (Cron → dispatcher), `03-sync` §4.2 (`Automation`
owner = Integrations), `04-mobile` §3.4 (notifications split).

1. **Purpose** — connect external capabilities (Composio-based integrations) and
   external notification delivery (OneSignal push + local notifications) without
   coupling business code to vendors (AD-1).
2. **Responsibilities** — `IntegrationProvider` (Composio behind the port):
   tool/app capabilities surfaced to the Agent's Tool Context; **Automations**
   (`Automation` AD-15 entity, owner Integrations, 03 §4.2): Supabase Cron →
   dispatcher (AD-8) scheduled actions; notification delivery: OneSignal
   (server-side `fn-notifications`) + Capacitor local notifications (split rule:
   server-state-driven = OneSignal; local-deadline-driven = Capacitor local; **never
   both for the same object**, anti-double-push, 04 §3.4 + test 04 §7).
3. **Non-responsibilities** — provider keys/secrets (server secret stores, AD-3);
   coaching content (Agent/Coach decides *what*; Integrations delivers); module
   business logic.
4. **User flows** — enable an integration (auth flow server-side), schedule an
   automation, receive a reminder (local) or a push (remote), silence windows
   (coaching cadence, ADR §13, via `setSubscribed`).
5. **Architecture** — `packages/integrations` adapters (Composio, OneSignal server
   client); Cron triggers feed `job_queue` (01 §5.2 — the **only** two trigger
   sources: Cron + Postgres trigger, AD-8).
6. **Domain model** — `Automation` (trigger, action, schedule, state), notification
   preferences (UserContext).
7. **Application services** — automation use-cases (create/toggle → `LocalCommandRepository`),
   delivery use-cases (job → provider call → `JobCompleted`).
8. **Ports / interfaces** — `IntegrationProvider`, `NotificationProvider`, `JobRunner`
   (ADR §8).
9. **Adapters** — Composio client (server), OneSignal server client (`fn-notifications`),
   `RemoteNotificationAdapter`/`LocalNotificationAdapter` (device side, 04 §3.2.5).
10. **Data model** — 01 §4.7 (integrations state, automations; `user_context` =
    Identity).
11. **API** — provider calls server-side only; device gets presigned/normalized
    results.
12. **Events** — consumes `JobCompleted` (delivery confirmation); producer of
    automation-triggered jobs (via `job_queue`, not via the 9-event vocabulary —
    automations are commands, AD-9 discipline).
13. **Jobs** — automation executions (persisted, idempotent, retryable).
14. **Permissions** — integration auth flows server-side (no device-held secrets, AD-3).
15. **Security** — provider key split (appKey vs server key, OneSignal, 04 §3.2.5 +
    04 §7.2e test); per-user RLS on automation rows; rate limits on provider calls
    (gateway-level, 01 §5.6).
16. **Offline behavior** — local notifications work offline; remote delivery queues
    (jobs wait).
17. **Error handling** — provider failures: bounded retry + fallback (None for
    OneSignal — delivery best-effort + `JobCompleted{failed}`); data-policy-aware
    routing for AI-adjacent integrations.
18. **Recovery** — job retry; idempotency keys prevent duplicates.
19. **Observability** — per-provider health (gateway + `job_logs`), delivery SLOs,
    double-push test results (04 §7).
20. **Tests** — anti-double-push (04 §7), key anti-leak (04 §7.2e), automation
    idempotency (01 §7), OneSignal server-key-not-in-bundle test.
21. **Known limitations** — push delivery depends on OneSignal service + Android
    battery optimization (documented limitation, not a guarantee); Composio
    coverage per app = provider-dependent.
22. **Dependencies** — jobs system, OneSignal, Composio, Agent (tool context),
    Productivity (reminders).
23. **Future evolution** — more integration families behind the same port; Phase 2
    desktop native notifications adapter (ADR §23.4).

## 11. Notification system — complete picture (mission §49)

**Sources (normative split, 04 §3.4):** (a) *server-state-driven* = OneSignal
push (`fn-notifications`, server key lives there ONLY — 04 §3.2.5): coaching
check-ins (ADR §13 cadence + silence windows), `JobCompleted` user-facing
results, reminder sweeps. (b) *local-deadline-driven* = Capacitor local
(`LocalNotificationAdapter.scheduleLocal`): due-today task/event reminders,
Focus timer/Pomodoro end (doc §2.4/§2.8). **Never both for the same object**
(anti-double-push, test 04 §7). (c) *desktop* = native notifications, **Phase 2
only** (ADR §23.4 — add adapter, not V1 scope).

**Priority & delivery:** each notification declares priority (`reminder` /
`coach` / `job-result` / `alert`); delivery respects user preferences
(`user_context` notification prefs, Identity) + OneSignal subscription state
(`setSubscribed`); foreground = in-app surface (02 §7 states), background =
system tray notification (Android).

**Suppression:** silence windows (ADR §13 coaching cadence, user-controlled) ·
Focus Mode (v1.8 DPC: blocklisted apps' notifications hidden by suspension;
Aurora's own non-critical = `reduceForFocus`, focus spec §8) · user kill-switch
per category. Suppression = state, not deletion (queue semantics documented in
wave 1).

**Permissions:** `POST_NOTIFICATIONS` requested **on first use, never at boot**;
refusal = app fully functional, reminders visible in-app, notifications off
(permission-matrix §1). OneSignal `appKey` (app-specific, allowed in
`capacitor.config.ts`, owner Foundation) ≠ server key (never in bundle, 04
§7.2e test).

**States & errors:** push job failure = `JobCompleted{failed}` (UI may retry,
01 §6); delivery is best-effort (Android battery optimization is a documented
platform limitation, not a guarantee); local schedules survive offline (04 §3.4).
