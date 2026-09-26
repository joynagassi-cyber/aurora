# Ascent — Implementation Guide (Wave 3+)

**Status:** PROPOSED (additive, no ADR change needed).
Owner: Ascent module (new, packages/ascent). Wave 3+.
Authority: docs/ascent/overview.md (22 sections, 2026-09-25).

## What to Build (minimum viable, 80/20)

### Step 1: packages/domain/ascent.ts (AD-15 SSoT)

```ts
// AscentLearningIR + AscentStep + AscentActivity + AscentAdaptation
// LearnerBaseline + DepthLevel
// See docs/ascent/overview.md S6 for exact types
// 1 table: ascent_paths (steps as JSONB array)
// Optional: split into ascent_steps if query perf needs it
```

### Step 2: packages/ascent/ (server-side module)

```
packages/ascent/
  src/
    path-builder.ts      // build LearningPath from goal + baseline + knowledge
    adapter.ts           // adapt path on new evidence (ProgressEvidenceCreated)
    baseline.ts          // compute LearnerBaseline from Progress skill_states
    depth.ts             // select depth per step (Quick/Standard/Deep)
    read-do-prove.ts     // sequence phases (framework, not rigid)
    source-hierarchy.ts  // enforce A>B>C>D (Level D never overrides A)
    index.ts
```

**Rules:**
- Server-side only (AD-12, like Agent Kernel)
- Reads: KnowledgeBase, ProgressEvidence (public views), DiscoveryService
- Writes: ONLY ascent_paths table (AD-7 single-writer)
- Emits: LearningCommand (to Learning via use-case, AD-7)
- Does NOT emit new AD-9 events
- Does NOT write to Progress/Learning/Knowledge tables

### Step 3: Slide-Ascent UI (apps/mobile, Dyad team)

```
Slide-Ascent = renderer for AscentLearningIR
  - 12 slide types (palette, not mandatory sequence)
  - Progressive disclosure (Level 1 = current+next, Level 2 = detail)
  - Active Reading: 5 actions (Explain, Note, Flashcard, Visualize, "Je bloque")
  - Depth badge (Quick/Standard/Deep)
  - Source hierarchy badge (A/B/C/D)
```

### Step 4: Agent Kernel integration

```
Agent Context Builder (01 S5.6) reads AscentLearningIR
  -> "What should Horeb learn next?"
  -> Agent plans the next session based on the path
  -> Agent emits LearningCommand (generate_qcm, start_mirror, etc.)
  -> Learning executes
  -> Progress captures evidence
  -> Ascent adapts the path (server-side, event-driven)
```

## Data (ascent_paths — server writes, read-only device mirror)

```sql
-- ascent_paths (the main table, can start as 1 JSONB table)
CREATE TABLE ascent_paths (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL,
  goal        TEXT NOT NULL,           -- NL goal (verbatim)
  target_skill UUID,                   -- Progress skill_id (optional)
  target_date DATE,
  steps       JSONB NOT NULL,          -- AscentStep[] (or separate table)
  depth       JSONB NOT NULL,          -- { stepId: 'quick'|'standard'|'deep' }
  baseline    JSONB NOT NULL,          -- LearnerBaseline snapshot
  status      TEXT NOT NULL DEFAULT 'active',
  adaptations JSONB NOT NULL DEFAULT '[]',  -- AscentAdaptation[]
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- RLS: user_id isolation (AD-2)
-- Writes: server-side ONLY (AD-12, like Agent Kernel)
-- Reads: read-only PowerSync mirror (device sees current path) —
-- deliberately NOT like expert_skills (AD-3: that one is never mirrored);
-- Slide-Ascent must render offline (mobile-first)
 ```
```
### Local mirror (device)

- PowerSync mirrors ONLY `ascent_paths` (current path + steps + depth +
  baseline snapshot) as read-only. The device never computes adaptations
  (AD-12: server-side, like Agent Kernel).
 - Stale mirror + user offline = frozen path, not an error state. The UI
   shows the last synced path; adaptations arrive on reconnect.

## SQL Migration + Sync Surface (exact files, 1 commit)

Three files, all in the existing wave-0 pattern (MINERVA). Gates
`check-rls.sh` and `check-view-joins.ts` scan them — both must stay green.

### 1. `supabase/migrations/0016_ascent.sql` (next free number after 0015_powersync_relay_views)

```sql
-- Ascent module (wave 3) — writes server-only (AD-12),
-- read-only device mirror via PowerSync (this migration + relay.sql).
CREATE TABLE ascent_paths ( /* schema from "Data" above */ );

ALTER TABLE ascent_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE ascent_paths FORCE ROW LEVEL SECURITY;  -- service_role bound too (01 S2.2)

-- user isolation (0008 pattern) — relay reads THROUGH RLS, never BYPASSRLS
CREATE POLICY ascent_paths_user_isolation ON ascent_paths
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- NO un-justified USING(true) anywhere (check-rls (b))
```

### 2. `powersync/relay.sql` — append the scope view

```sql
-- Ascent scope (owner Ascent) — read-only mirror surface, no cross-module JOIN
CREATE VIEW v_ascent_scope WITH (security_invoker = on) AS
SELECT * FROM ascent_paths;
```

### 3. `powersync/schema.json` — register the mirror

- `mirrorTables`: add `"ascent": ["ascent_paths"]`
- `scopes`: add `{ "name": "ascent", "ownerModule": "Ascent", "type": "custom", "sql": "SELECT * FROM v_ascent_scope" }`
- `excludedFromMirror`: add NOTHING (ascent_paths IS mirrored, read-only;
  expert_skills-style exclusion would break offline Slide-Ascent)

### Intrusion test

User A must not read user B's `ascent_paths` (RLS + view security_invoker).
Follow the wave-0 MINERVA test pattern (tests/rls-penetration.sql).

### Apply to Supabase dev (SOPHIA step, via Supabase MCP)

SOPHIA applies the 0015 migration to the Supabase DEV project through the
Supabase MCP server configured in Claude Code (the ONLY sanctioned write
path — no dashboard edits, no manual SQL). Post-apply verification:
table + RLS (ENABLE+FORCE) + `user_isolation` policy + `v_ascent_scope`
view all present. The completion report MUST state
"migration applied via Supabase MCP: YES/NO" (NO = red flag, user applies).

### Slide-Ascent (UI) — no SQL of its own

Slide-Ascent renders `ascent_paths` from the LOCAL MIRROR (offline-safe).
It creates no table, no migration, no relay view. The 3 async states
(empty / loading / error) are UI concerns per docs/ui-libraries.md Partie 3.

## Events (consumed only — AD-9 stays closed)

Ascent CONSUMES 6 existing events. It EMITS NO new AD-9 event.
`AscentAdaptation` is internal log data, read by the Agent Kernel
(Context Builder, 01 S5.6), not a vocabulary entry.

| Event (AD-9) | Ascent reaction |
|---|---|
| ProgressEvidenceCreated | Adaptation check (mastery changed) |
| SkillStateChanged | Baseline refresh (e.g. fragile -> mastered) |
| DiscoveryItemCreated | Possible new step insertion (gap) |
| GoalUpdated | Path recomposition |
| TaskCompleted | Passage criteria check |
| ArtifactGenerated | READ phase completion |

## Error / Edge Cases

| Case | Behavior |
|---|---|
| No active goal | No path. Ascent idle, kernel plans Productivity only |
| Baseline not computable | Skill marked `unknown`, path starts at Quick depth |
| Prerequisite cycle (A needs B, B needs A) | Detect at build time -> `recompose` adaptation + flag for manual review |
| Level D source contradicts Level A | Flag conflict in path metadata; Level A wins; never silent |
| Goal target date passed | Path `paused`, kernel proposes re-date or `abandoned` |
| User pauses/resumes | `status` field only, no re-computation |
| New gap arrives mid-path | `insert_remediation` / new step, logged as AscentAdaptation |

## Integration Points

| With | How | Direction |
|---|---|---|
| Agent Kernel | Context Builder reads AscentLearningIR | Ascent -> Agent |
| Learning | Ascent emits LearningCommand (generate_qcm, start_mirror) | Ascent -> Learning |
| Progress | Ascent reads SkillState + ProgressEvidence (public view) | Progress -> Ascent |
| Knowledge | Ascent references concept/formula IDs | Knowledge -> Ascent |
| Discovery | Ascent reads DiscoveryItemCreated (new gap) | Discovery -> Ascent |
| GoalProject | AscentLearningIR feeds GoalProject.featurePlacements | Ascent -> Goal |
| Slide-Ascent | UI renders AscentLearningIR | Ascent -> UI |
| Dynamic Goal Engine | GoalProject.composition includes Ascent path | Goal <-> Ascent |

## Decision Classification (keep the doc honest)

| Item | Class | Note |
|---|---|---|
| Server-side only, no device computation | DECIDED | AD-12, same as Agent Kernel |
| Single-writer `ascent_paths` | DECIDED | AD-7 |
| No new AD-9 events | DECIDED | AD-9 closed vocabulary |
| 5 active-reading actions only | DECIDED | 80/20, overview S14 |
| 12 slide types = palette, not sequence | DECIDED | overview S12 |
| 3 depth levels, 5-state baseline (no single score) | DECIDED | overview S6.2, S13 |
| Start with 1 JSONB table, split into 4 later | PROPOSED | perf decision, deferred until data volume proves it |
| Dedicated `fn-ascent` vs inside `fn-agent-run` | PROPOSED | decide at implementation, both are server-side |
| Local read-only mirror of current path | PROPOSED | UX requirement, not yet a frozen ADR |
| Multi-goal composition | DEFERRED | V1 = 1 active goal |
| Ascent-FSRS co-optimization (Ascent decides WHEN) | DEFERRED | FSRS owns timing in V1 |
| Second LLM pedagogical model | REJECTED | Ascent = deterministic rules, LLM explains |
| 13+ specialized agents | REJECTED | AD-12: 1 kernel, Ascent = capability |
| Graphiti/Zep vector memory | REJECTED | AD-11: SourceRef + pgvector |
| WebGL/3D rendering | REJECTED | AntV + KaTeX + images |
| 15 contextual actions on every element | REJECTED | 5 actions cover 90% |

## What NOT to Build (80/20)

- No second LLM "pedagogical model" (Ascent = deterministic rules)
- No 13+ specialized agents (AD-12: 1 kernel)
- No Graphiti/Zep (AD-11: SourceRef + pgvector)
- No WebGL/3D (AntV + KaTeX + images)
- No Drift Guardian 24/7 (event-driven)
- No distributed pipeline (1 function, 4 tables)
- No 15 contextual actions (5 is enough: Explain, Note, Flashcard, Visualize, "Je bloque")

## Test Plan

| Test | Pass criteria |
|---|---|
| Baseline accuracy | Ascent reads Progress skill_states, does NOT re-declare |
| Prerequisite enforcement | Step 3 blocked if step 2 not done |
| Adaptation on evidence | QCM 50% -> remediation inserted |
| Depth selection | Exam + 2 weeks -> Deep for core, Quick for peripheral |
| READ->DO->PROVE flexibility | Skip READ if mastered (no forced sequence) |
| Source hierarchy | Level D does NOT override Level A |
| Progressive disclosure | Level 1 = current+next only |
| "Je bloque" flow | Stuck -> diagnose -> remediate -> new evidence |
| Offline | Path readable offline (local mirror) |
| RLS | User A cannot read user B's path |
