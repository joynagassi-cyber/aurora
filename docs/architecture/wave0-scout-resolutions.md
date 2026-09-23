# Wave 0 — Scout Issue Resolutions (2026-09-23)

**These 5 findings from the Scout agent are resolved here. Agents proceed
with these decisions. No further discussion needed.**

## Issue 1: notes/resources ownership

**Conflict:** data-ownership-matrix.md assigns `notes` + `resources` to
Productivity (01 S4.1). 03 S4.2 (frozen) says owner = Knowledge.

**Resolution: SPLIT.**
- `notes` = **Productivity** (01 S4.1). Inbox capture, quick notes,
  decision journal. Productivity writes, all modules read via public view.
- `resources` = **Knowledge** (03 S4.2, 01 S4.11 library). Course
  PDFs, documents, images, links, exercises. Knowledge writes (ingestion),
  Productivity reads via public view (resource library screen).

If 03 S4.2 says Knowledge owns `resources`, Knowledge owns it.
The data-ownership-matrix.md is documentation, NOT the frozen mapping.
03 S4.2 wins (it is the AD-15 frozen entity->module->table mapping).

**Action for MINERVA:** create `resources` table in Knowledge schema
migration. Productivity creates a public view `v_productivity_resources`
over Knowledge's `resources` table for the library screen.

---

## Issue 2: "events" ambiguity (calendar vs AD-9 Event History)

**Conflict:** 01 S4.1 has `events` (calendar events: meetings, deadlines,
time blocks). 01 S4.8 has `events` (AD-9 Event History: 9-event vocabulary,
server-side, audit-only). Same name, different things.

**Resolution: RENAME the calendar table.**
- Calendar events = `scheduled_events` (Productivity, 01 S4.1)
- AD-9 Event History = `events` (Foundation, 01 S4.8, server-side)

`scheduled_events` is a Productivity table (local mirror via PowerSync).
`events` is the AD-9 Event History (server-only, no local mirror,
append-only, 2-year retention).

**Action for MINERVA:** name the calendar table `scheduled_events` in
the migration. Name the AD-9 table `events`. No ambiguity.

**Action for ACHILLES:** in packages/domain, the calendar entity type is
`ScheduledEvent` (not `Event`). The AD-9 event types are
`TaskCompleted`, `CourseImported`, etc. (already distinct names).

---

## Issue 3: RLS test duplication (W0 vs W1)

**Conflict:** W0-E3-1 (MINERVA) creates RLS policies + initial
penetration test. W1-E2-2 (ATHENA) re-runs "RLS penetration test [01 S7]".

**Resolution: W0 creates, W1 verifies.**
- W0 (MINERVA): creates RLS policies on ALL tables + writes the
  penetration test script (tests/user-a-cannot-read-user-b.sql).
  This test runs in CI on every migration.
- W1 (ATHENA): does NOT recreate RLS. It verifies that the PowerSync
  scope respects RLS (i.e., the sync only sees what RLS allows).
  This is a DIFFERENT test: "PowerSync relay cannot bypass RLS."

**Action:** MINERVA's commit includes `tests/rls-penetration.sql`.
ATHENA's commit includes `tests/powersync-respects-rls.test.ts`.
No duplication.

---

## Issue 4: pg_cron intervals missing from W0 scope

**Conflict:** 01 S5.2 says Cron = trigger source, but no interval values
are specified (SPEC: "valeurs d'environnement = donnees de vague 0",
OQ-03). The Scout agent correctly flags this as a gap.

**Resolution: Use placeholders in W0, fill values later.**

```sql
-- W0: structure ready, values = config (not hardcoded)
-- supabase/config.toml or .env:
CRON_FSRS_TICK = "0 2 * * *"        -- daily 02:00 (placeholder)
CRON_EVENT_DISPATCH = "*/5 * * * *"  -- every 5 min (placeholder)
CRON_SKILL_RECOMPUTE = "0 3 * * *"   -- daily 03:00 (placeholder)

-- W0 creates the cron entries with these placeholders.
-- OQ-03 resolution (Joy + Foundation) = update the values in .env.
-- The code structure is identical regardless of the interval.
```

**Action for MINERVA:** create pg_cron entries with placeholder
intervals. Add a comment: `-- OQ-03: values TBD, update in .env`.
The Edge Function `fn-job-dispatcher` reads `due_at` from
`job_queue`, not from the cron interval. The cron just triggers
`dispatchDue(now)`.

---

## Issue 5: model_registry / ai_usage / ai_health missing from W0-E3

**Conflict:** 01 S4.10 defines `model_registry`, `ai_usage`, `ai_health`
tables (Foundation-owned, AD-16b). W0-E3 stories only cover
`job_queue` + `job_logs`. The 3 AI tables are not in any W0 story.

**Resolution: Add to MINERVA's scope (she owns Supabase tables).**

**Action for MINERVA:** add 3 tables to her migration (Commit 1):

```sql
-- model_registry (Foundation, AD-16b, 01 S4.10)
CREATE TABLE model_registry (
  model_id      TEXT PRIMARY KEY,     -- 'agnes-3.0-flash', 'glm-4.7-flash'
  provider      TEXT NOT NULL,        -- 'agnes', 'workers-ai', 'groq'
  capabilities  TEXT[] NOT NULL,     -- ['reasoning','tools','vision']
  context_window INT,
  modality      TEXT,                 -- 'text', 'text->image', 'multimodal'
  status        TEXT NOT NULL DEFAULT 'active'
               CHECK (status IN ('active','retired','deprecated')),
  free_tier_quota JSONB,             -- { snapshotDate, value, source }
  pricing       JSONB,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- ai_usage (01 S4.10, per-call tracking)
CREATE TABLE ai_usage (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL,
  provider      TEXT NOT NULL,
  model         TEXT NOT NULL,
  tokens_in     INT,
  tokens_out    INT,
  neurons       INT,             -- for Workers AI
  latency_ms    INT,
  cost          NUMERIC(10,6),
  task_profile  JSONB,           -- the TaskProfile that triggered this
  envelope      JSONB,           -- AIResponseEnvelope
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- ai_health (01 S4.10, provider/model health)
CREATE TABLE ai_health (
  provider      TEXT PRIMARY KEY,
  model         TEXT PRIMARY KEY,
  status        TEXT NOT NULL DEFAULT 'healthy'
               CHECK (status IN ('healthy','degraded','cooldown','unavailable')),
  error_rate    NUMERIC(5,2),  -- percentage
  last_429_at   TIMESTAMPTZ,
  last_success  TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,
  updated_at    TIMESTAMPTZ DEFAULT now()
);
-- Composite primary key: (provider, model)
```

Plus seed data:
```sql
-- Seed (W0, updated as models change):
INSERT INTO model_registry (model_id, provider, capabilities, status) VALUES
  ('agnes-3.0-flash', 'agnes', '{reasoning,tools,streaming}', 'active'),
  ('agnes-2.5-flash', 'agnes', '{tools,streaming}', 'active'),
  ('agnes-image-2.5-flash', 'agnes', '{image-generation}', 'active'),
  ('agnes-image-2.1-flash', 'agnes', '{image-generation}', 'active'),
  ('@cf/zai-org/glm-4.7-flash', 'workers-ai', '{tools}', 'active'),
  ('@cf/google/gemma-4-26b-a4b-it', 'workers-ai', '{vision,multimodal}', 'active'),
  ('@cf/nvidia/nemotron-3-120b-a12b', 'workers-ai', '{reasoning,tools}', 'active');
```

**Action for MINERVA:** add these 3 tables + seed to her Commit 1.
Update her commit message: "wave0/minerva: Supabase migrations + RLS
+ views + model_registry + ai_usage + ai_health"

---

## Summary for the 3 agents

| Agent | What changed |
|---|---|
| ACHILLES | `ScheduledEvent` (not `Event`) for calendar. `Event` = AD-9 only. |
| HERMES | RLS test = W0 (create) + W1 (verify PowerSync respects RLS). No duplication. |
| MINERVA | +3 tables (model_registry, ai_usage, ai_health) + pg_cron placeholders + `resources` in Knowledge schema + `scheduled_events` rename |

**These resolutions are FINAL. The agents proceed. No further
clarification needed on these 5 points.**
