# Troubleshooting & Recovery — Technical Page

Status: specification (design phase). Sources: `01-backend` §6/§7/§8.2,
`03-sync` §5/§6/§7, `04-mobile` §6/§7, `05-design-system` §2.1 (theme rule),
ADR v1.7 §10.

## 1. Symptom → cause → action (normative)

| Symptom | Likely cause | Action |
|---|---|---|
| Job stuck `pending`/`running` | worker failure, missing timeout | per-kind timeout fires (01 §5.3) → retry with backoff; `job_logs` + Sentry trace; `JobCompleted{failed}` surfaces a retryable `jobId` in the UI (01 §6); duty owner = Foundation (AD-16d) |
| Duplicate side effect feared | non-idempotent job | idempotency key (`kind + hash + user_id`, 01 §5.3) prevents it; verify in `job_logs`; per-kind idempotency test (01 §7) |
| Sync not converging / stale lists | long outage, scope/view drift | re-sync path (03 §5.5) on foreground return; check `SyncStatus`; server-wins + `updated_at` is the canonical resolution (03 §5.3) |
| CRDT collision alert (`conflict` state) | un-mergeable type collision (residual, 03 §3.2) | user alert + lossless merge (03 §5.3 test); never a silent overwrite for lists |
| Provider down / 429s | availability, quota, limit type | retry only on transient (AD-5); fallback chain per task type (`AIFallbackStrategy`); 429 = cooldown, **never** key rotation; `AIResponseEnvelope` carries provider/model/attempt/reason/quality (traceability); Model Registry can auto-retire an unavailable/paid provider (AD-5) |
| AI answer degraded quality | fallback used | check `expectedQuality: 'degraded'` + `fallbackUsed` in the envelope; re-run via primary when health recovers (`AIHealthRegistry`) |
| Data sent to wrong provider risk | data-policy mismatch | `AIRequestGuard` refuses **before** the call with a readable reason (01 §6); check the provider's `DataPolicy` in the Model Registry |
| RLS change broke access | policy migration | RLS penetration test blocks bad migrations (01 §7); service_role paths must stay **via policies** (01 §3.4) |
| Theme wrong / "silent theme change" on return | violated 05 §2.1 rule | the persisted theme is re-applied on boot; auto recompute is **deferred to /settings mount, never at boot** (05 §2.1); if the persisted theme is not in the set (migration) → fallback = light default (coherence review mustFixForV2 #4) |
| App killed mid-Focus session | taskbar swipe | session row persisted (`focus_sessions`): relaunch shows `interrupted` → restore path (focus spec §7); OneSignal state reconciled from server (focus spec §11.14) |
| **Focus: apps still suspended after reboot/crash (v1.8 DPC mode)** | device policy outlives the process | `BOOT_COMPLETED` receiver reads the session row → default = un-suspend all + "resume session" offer (focus spec §7/§13 test 5); receiver missing → emergency path §9.4 |
| **Focus: device factory-reset (v1.8 DPC mode)** | DPC state wiped (documented Android behavior) | re-run provisioning (focus spec §9.1: factory reset → no accounts → install APK → `dpm set-device-owner`); until then the app runs in consumer fallback (04 §4.1) |
| **Focus: blocklist contains a non-suspendable package (v1.8 DPC)** | Android excludes certain packages (system, active launcher, default dialer, installer/uninstaller, permission controller — verify on target, OQ-17) | session pre-check reports the rejected packages with reasons; session starts with the remaining set; empty set = restriction fallback (focus spec §4) |
| Notification not delivered | OneSignal down / battery optimization (platform limitation) | delivery is best-effort (documented in integrations page); local deadline notifications remain available offline; check `JobCompleted{failed}` for push jobs |
| OCR/transcription feature missing | optional provider absent (AD-1) | product degrades gracefully: manual entry (OCR), audio without transcript (STT) — **not** a crash (01 §6, 04 §7.4) |

## 2. Recovery invariants (checklist)

1. Local store is the UI truth (AD-7) — any recovery path ends with "read local".
2. Server is the transactional truth (Postgres) — conflicts resolve server-wins.
3. Jobs are idempotent + retriable (AD-8) — re-execution is safe by construction.
4. Every provider is replaceable (AD-1) — no single-vendor lock at the domain.
5. Theme/state persistence is explicit (05 §2.1) — no silent UI state drift.
6. Focus restoration is snapshot-based within Aurora's own scope (focus spec §7).

## 3. Observability entry points

Sentry (errors/perf SLOs), PostHog (behavior), `job_logs` + per-kind SLO alerts
(Foundation duty), `AIUsageTracker`/`ai_usage` + Model Registry health, RLS/
policy test reports, theme-pair WCAG results (wave 7).
