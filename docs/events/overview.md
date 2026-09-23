# Targeted Event-Driven (AD-9) — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1 transport; waves 2–4 consumers).
Authority: spine AD-9 (normative matrix, frozen by F-04), `01-backend` §3.3,
ADR §26.6.

## 1. Discipline (mission §25)

Events exist **only** where multiple components must react independently or async
decoupling is wanted. A simple transactional operation stays a **direct command**
(renaming a task ≠ distributed event, ADR §26.6). V1 vocabulary is **frozen at
9 events** — "event-everywhere" is a review violation (01 §3.3, R3 mitigation:
undeclared consumer = blocking test failure).

## 2. The 9 (normative matrix, 01 §3.3)

| Event | Producer | Declared consumers |
|---|---|---|
| `TaskCompleted` | Productivity | Progress, Learning, Agent |
| `CourseImported` | Learning | Knowledge, Discovery, Progress |
| `FlashcardReviewed` | Learning (FSRS) | Progress |
| `ProgressEvidenceCreated` | **Progress only** (F-07) | Knowledge (`NodeState`), Agent |
| `SkillStateChanged` | Progress | Agent, Discovery, Learning |
| `GoalUpdated` | Productivity | Progress, Agent |
| `ArtifactGenerated` | **Artifact, after R2 upload only** (F-06) | Knowledge (`SourceRef`), Learning [+ UI — OQ-05] |
| `JobCompleted` | Job system (payload carries `jobId`+`jobKind`, F-08) | Artifact, UI |
| `DiscoveryItemCreated` | Discovery | Learning, Knowledge, Progress, Agent |

Payload types live in `packages/domain` (AD-15). Hard rules: Learning never creates
a `ProgressEvidence` row directly (F-07); the kernel never emits `ArtifactGenerated`
(it requests generation, F-06); `JobCompleted` without `jobId`/`jobKind` is rejected
(F-08).

## 3. Transport (V1, 01 §3.3)

Event = INSERT into the producer module's `events` table (Event History, AD-6);
consumers observe via **Postgres trigger → job** or **incremental `since_event_id`
job read**. **No broker** (Kafka etc.) in V1. Mobile reads states via PowerSync
mirrors — it **never** consumes events directly (AD-7/F-03, 04 §3.3).

## 4. Declaration (AD-13)

A module consumes an event **only** if it declares it in its Contract Pack; the
consumer list of the AD-9 matrix is the normative one (ratify additions additively,
e.g. OQ-05 for the UI consumer of `ArtifactGenerated`).

## 5. Tests (01 §7 event family)

(a) exactly one producer per event (a second = failure) · (b) every declared
consumer declared + tested, undeclared = failure · (c) `JobCompleted` without
`jobId`/`jobKind` rejected · (d) `ArtifactGenerated` only after R2 confirmation ·
(e) Progress sole producer of `ProgressEvidenceCreated`.

## 6. Exclusions & limits

- Full Event Sourcing: **excluded from V1** (ADR §26.4; Event History is
  analysis/audit, not a state model — spine § Deferred).
- CQRS: applied only on concrete need (ADR §26.4 "CQRS ciblé").

## 7. Per-event operational detail (mission §51)

Transport notes apply to ALL: payload = `packages/domain` TS types (AD-15);
insertion into the producer's `events` table (Event History, AD-6); consumers
observe via Postgres trigger → job or incremental `since_event_id` read (no
broker V1). **Idempotency**: consumers process per event identity
(`events.id` + `since_event_id` cursor) — re-delivery of an event must be a
no-op (consumer jobs are idempotent, AD-8). **Retention**: Event History rows
persist for analysis/audit (ADR §26.7) — no V1 TTL; archiving policy = wave-1
data-team decision (documented, not assumed).

| Event | Producer (sole) | Consumers (declared) | Purpose | Payload (minimal) |
|---|---|---|---|---|
| `TaskCompleted` | Productivity | Progress, Learning, Agent | execution proof + re-plan + revision trigger | taskId, userId, completedAt, evidenceRefs? |
| `CourseImported` | Learning | Knowledge, Discovery, Progress | tree ingestion + gap analysis | courseId, userId, source, importedAt |
| `FlashcardReviewed` | Learning (FSRS) | Progress | memory freshness | cardId, userId, rating, nextDueAt, fsrsState |
| `ProgressEvidenceCreated` | **Progress only** (F-07) | Knowledge (NodeState), Agent | evidence → state + context | evidenceId, userId, skillId?, goalId?, type, level, confidence, sourceEventId |
| `SkillStateChanged` | Progress | Agent, Discovery, Learning | competence signal | skillId, userId, newState, freshness, confidence |
| `GoalUpdated` | Productivity | Progress, Agent | trajectory + re-plan | goalId, userId, changedAt, fields[] |
| `ArtifactGenerated` | **Artifact, after R2 upload only** (F-06) | Knowledge (SourceRef), Learning (+ UI — OQ-05) | provenance + proof | artifactId, userId, kind, r2Key, sizeBytes, generatedAt, jobId |
| `JobCompleted` | Job system | Artifact, UI | success/retry states | jobId, jobKind (mandatory F-08), userId, status, result? |
| `DiscoveryItemCreated` | Discovery | Learning, Knowledge, Progress, Agent | discovery loop | discoveryItemId, userId, topic, sources, createdAt |

**Rejected proposals (normative check, mission §51 "Ne pas créer un event
parce qu'un CRUD existe")**: `FocusSessionStarted` / `FocusSessionCompleted`
= CRUD of the `FocusSession` entity → **direct commands** (owner Productivity)
+ the `FocusSessionBilan` → evidence chain via Progress jobs (W14) — NOT events
(AD-9 discipline: 9 and only 9). "DiscoveryFindingCreated" = the frozen
`DiscoveryItemCreated` (naming aligned). `SkillStateChanged`/`GoalUpdated`/
`JobCompleted`/`ArtifactGenerated` are already inside the 9 (the mission's
example list omits them — the frozen matrix, not the example, is normative).
