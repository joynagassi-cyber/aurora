# Expert Skill Self-Improvement — Extensions & Data Model (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 3, Agent team).
Authority: ADR S14 (Self-Improvement / Expert Skills), ADR S18.4
(Causal Analysis), kernel.md S12 (Memory component), 01 S4.7
(expert_skills table, server-only, AD-3), 03 S4.2 (server-only,
no local mirror).

## 1. What is an Expert Skill (recap, ADR S14)

NOT a probabilistic intuition. NOT "the AI magically gets better."
An Expert Skill is a **deterministic procedural rule** crystallized
from verified operational facts:

```
Trigger (what activates the skill)
  -> Goal (what it aims to achieve)
  -> Steps (ordered procedure)
  -> Constraints (when it applies, when it does NOT)
  -> Confidence (0-1, evidence-based)
  -> Provenance (which ProgressEvidence + corrections back it)
  -> ValidationDate (when last verified)
  -> Obsolescence conditions (when to retire it)
```

**Guardrails (ADR S14.5):**
- No one-shot hypothesis promoted to durable truth
- Provenance always kept
- User can correct / disable / delete
- Contradiction detection (two skills cannot both be "true")
- Periodic review (confidence decay, §3 below)

## 2. The 4 Extensions (additive, do not modify ADR S14 structure)

### 2.1 Contrastive Strategy Evaluation

**Problem:** A single success is not enough to crystallize a skill.
The system must verify that the success was CAUSED by the strategy,
not by coincidence.

**Mechanism:**
```
Session A (RDM revision, Tuesday): SUCCESS
Session B (RDM revision, Thursday): FAILURE
  |
  -> ProgressSnapshot diff (A vs B):
     Divergent variables:
       - start_time: 09:00 (A) vs 14:00 (B)
       - energy_level: high (A) vs low (B)
       - prior_focus: yes (A) vs no (B)
       - interruption_count: 0 (A) vs 3 (B)
  |
  -> Causal analysis (ADR S18.4: correlation != causation):
     "The success in A is likely due to morning scheduling +
      focused prior session, NOT the revision content itself."
  |
  -> Skill refinement:
     Constraint added: "only activate when energy >= medium
      AND interruptions < 2 in the prior hour"
     Confidence: 0.7 (moderate, n=2 paired sessions)
```

**Data:** `contrastive_pairs` table (server, Agent module):
```ts
interface ContrastivePair {
  id: string;
  userId: string;
  skillId: string;           // the skill being validated
  successSnapshotId: string; // ProgressSnapshot A
  failureSnapshotId: string; // ProgressSnapshot B
  divergentVariables: string[]; // which context vars differ
  conclusion: string;        // "timing + energy" / "content difficulty"
  confidenceDelta: number;   // +0.1 / -0.1 to the skill
  createdAt: string;
}
```

**Rule:** minimum 2 pairs before a skill's confidence can exceed 0.6.
One success is NOT a skill.

### 2.2 Confidence Decay (temporal)

**Problem:** A strategy that worked in week 1 of the semester may
be obsolete in week 12 (exam period, different courses, fatigue).

**Mechanism:**
```
confidence(t) = confidence_0 * exp(-lambda * (t - t_validation))
                * recency_boost

where:
  confidence_0 = initial confidence at creation
  lambda = decay rate (per 30 days, calibrated per skill type)
  t - t_validation = days since last verification
  recency_boost = +0.1 if a ProgressEvidence in the last 7 days
                  confirms the skill (re-verification)
```

**Rules:**
- `lambda` is NOT a single constant. It depends on the skill type:
  - Planning skills (rhythm, scheduling): lambda = 0.3/30d
  - Learning skills (method, technique): lambda = 0.1/30d
  - Discipline skills (focus, anti-procrastination): lambda = 0.5/30d
- When `confidence(t) < 0.3`: the skill is **flagged for re-evaluation**
  (the Agent asks: "This strategy hasn't been confirmed in 8 weeks.
  Still applicable?"). The user can: re-validate (confidence resets to
  0.6), archive (status = 'archived'), or delete.
- When `confidence(t) < 0.1`: auto-archive (no user prompt; the skill
  is retained in data, not deleted, but NOT active).
- **This is deterministic math, not an LLM judgment.** The decay is
  a formula, not a "the AI thinks it might be outdated."

### 2.3 Auto-Generated Triage Hypotheses (Failing Fast)

**Problem:** When Progress detects a stagnation, the Agent should
GENERATE a low-confidence hypothesis to test, rather than waiting
for a fully validated skill.

**Mechanism:**
```
Progress: "Stagnation on RDM flexion formulas (3 weeks, < 50% QCM)"
  |
  -> Self-Improvement generates a HYPOTHESIS (NOT a skill yet):
     "Try a 10-min Mirror session immediately after the theory
      lecture (within 1 hour) instead of end-of-week review."
     confidence: 0.2 (low, untested)
     status: 'hypothesis' (NOT 'skill')
     expiry: 14 days (if not validated by ProgressEvidence, auto-expire)
  |
  -> Agent proposes to user: "Je propose de tester ceci: 10 min
     de verification juste apres le cours. On voit si ca aide.
     Si pas d'amelioration en 2 semaines, on abandonne."
  |
  -> User confirms (CONFIRMATION_REQUIRED: new behavior)
  |
  -> 14-day test window:
     - ProgressEvidence in the window supports the hypothesis
       -> confidence 0.2 -> 0.5, status: 'skill' (validated)
     - No evidence / negative evidence
       -> hypothesis expires, status: 'rejected' (data preserved,
          NOT deleted; the Agent knows "this was tried and failed")
```

**Key rule: hypotheses are TEMPORARY and LOW-CONFIDENCE. They
NEVER pollute the longitudinal profile if rejected.** The user's
skill set only grows with VALIDATED skills. Failed experiments are
data points (negative knowledge), not rules.

```ts
interface SkillHypothesis {
  id: string;
  userId: string;
  skillId?: string;         // null if new (not yet a skill)
  trigger: string;
  proposedAction: string;
  confidence: number;       // always < 0.3 at creation
  status: 'hypothesis' | 'testing' | 'validated' | 'rejected' | 'expired';
  evidenceWindow: { start: string; end: string; requiredEvidence: string[] };
  createdAt: string;
  resolvedAt?: string;
}
```

### 2.4 Cognitive-Drift Firewall (Anti-Regression)

**Problem:** A single bad day (illness, personal event, unexpected
deadline) must NOT cause the Agent to create a general rule that
is wrong. "She missed her focus session because she was sick" does
NOT mean "focus sessions are ineffective for her."

**Mechanism: Double validation before modifying an established skill.**

```
Anomaly detected: "Focus session skipped 3 times this week"
  |
  -> Coach flags: "Is this a pattern or an incident?"
  |
  -> Causal analysis (ADR S18.4):
     - Was there a reported illness / personal event? (UserContext)
     - Are the skipped sessions correlated with a specific trigger
       (e.g., "all on days after a 2-hour lecture") or random?
  |
  -> FIREWALL RULE:
     An established skill (confidence >= 0.5, status = 'active')
     CANNOT be modified (confidence reduced, constraint added,
     or archived) based on a SINGLE anomalous cycle.
     
     Minimum: 3 independent cycles with the same motif
     (e.g., 3 weeks in a row, not 3 days in one week)
     before the skill is adjusted.
     
     Below 3 cycles: the anomaly is logged as an "incident"
     (ProgressEvidence with type='exception'), NOT as evidence
     against the skill.
```

**Exception (validates faster):**
- User EXPLICITLY says: "This strategy doesn't work anymore,
  stop using it." -> immediate archive (user authority > firewall).
- The skill's obsolescence condition (ADR S14.5) is met
  (e.g., "applies only during regular semester, NOT exam period")
  and the context changed -> auto-archive (deterministic, not a
  pattern detection).

## 3. The Full Feedback Loop

```
1. PROGRESS detects a gap
   "SkillState RDM.flexion = fragile (was 'mastered' 2 weeks ago)"
   |
2. SELF-IMPROVEMENT triages
   Causal analysis: "Why? Contrasting sessions show:
    timing shifted to 14:00 (low energy) + 2 interruptions"
   |
3. DISCOVERY runs (optional)
   "Research: what study techniques work for flexion formulas
    when energy is low?" -> ResearchProvider -> DiscoveryItem
   |
4. EXPERT SKILL is revised (or a hypothesis is generated)
   "Update constraint: only activate after 09:00 when energy >= medium"
   confidence: 0.7 -> 0.5 (decay + new constraint = re-validation)
   |
5. NEXT SESSION: Agent applies the updated skill
   "Plan your RDM revision at 09:00 (not 14:00),
    10-min mirror right after the lecture"
   |
6. PROGRESS records the outcome
   ProgressEvidence: "RDM flexion QCM: 50% -> 78%"
   |
   -> Skill confidence: 0.5 -> 0.7 (re-verified)
   -> Loop continues
```

## 4. SQLite / Supabase Data Model (server-side, 01 S4.7)

```sql
-- expert_skills (server-only, AD-3, 03 S4.2: NO local mirror)
CREATE TABLE expert_skills (
  id              UUID PRIMARY KEY,
  user_id         UUID NOT NULL,
  trigger         TEXT NOT NULL,        -- what activates the skill
  goal            TEXT NOT NULL,        -- what it achieves
  steps           JSONB NOT NULL,       -- ordered procedure
  constraints     JSONB NOT NULL,      -- when it applies / not
  confidence      REAL NOT NULL DEFAULT 0.0,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','archived','hypothesis',
                                     'testing','rejected','expired')),
  provenance      JSONB NOT NULL,      -- { evidenceIds[], corrections[], sessions[] }
  validation_date TIMESTAMPTZ,
  obsolescence    JSONB,              -- { condition, auto_archive_at }
  decay_lambda    REAL NOT NULL,       -- per-skill-type decay rate
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- skill_hypotheses (triage, §2.3)
CREATE TABLE skill_hypotheses (
  id              UUID PRIMARY KEY,
  user_id         UUID NOT NULL,
  skill_id        UUID REFERENCES expert_skills(id),  -- null if new
  trigger         TEXT NOT NULL,
  proposed_action TEXT NOT NULL,
  confidence      REAL NOT NULL DEFAULT 0.2,
  status          TEXT NOT NULL DEFAULT 'hypothesis'
                  CHECK (status IN ('hypothesis','testing','validated','rejected','expired')),
  evidence_window JSONB NOT NULL,      -- { start, end, requiredEvidence[] }
  created_at      TIMESTAMPTZ DEFAULT now(),
  resolved_at     TIMESTAMPTZ
);

-- contrastive_pairs (§2.1)
CREATE TABLE contrastive_pairs (
  id              UUID PRIMARY KEY,
  user_id         UUID NOT NULL,
  skill_id        UUID NOT NULL REFERENCES expert_skills(id),
  success_snapshot_id UUID NOT NULL,   -- ProgressSnapshot
  failure_snapshot_id UUID NOT NULL,
  divergent_vars  JSONB NOT NULL,      -- ["start_time", "energy_level", ...]
  conclusion      TEXT NOT NULL,
  confidence_delta REAL NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- skill_validation_log (audit trail, ADR S14.5)
CREATE TABLE skill_validation_log (
  id              UUID PRIMARY KEY,
  user_id         UUID NOT NULL,
  skill_id        UUID NOT NULL,
  event           TEXT NOT NULL,       -- 'created', 'revalidated', 'decayed',
                                        -- 'archived', 'user_corrected',
                                        -- 'contradiction_detected',
                                        -- 'hypothesis_promoted',
                                        -- 'hypothesis_rejected'
  detail          JSONB,               -- { confidence_before, confidence_after, reason }
  evidence_refs   UUID[],             -- ProgressEvidence ids
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- RLS: all tables = user_id isolated (AD-2, Identity root)
-- These tables are NOT in the PowerSync sync scope (03 S4.2:
-- expert_skills = server-only, no local mirror, AD-3)
```

### Linking Expert Skills to ProgressEvidence

```
expert_skills.provenance = {
  "evidenceIds": ["uuid-1", "uuid-2"],   -- the ProgressEvidence rows
  "corrections": ["uuid-3"],              -- user corrections
  "sessions": ["uuid-4"]                  -- LearningSession / FocusSession
}

progress_evidences (Progress, 01 S4.4, sole producer F-07):
  id, user_id, skill_id?, type, level, confidence, source_event_id, ...

The link: a ProgressEvidence with type='discipline' or
type='understanding' references the skill_id that was active
during that session. The skill's provenance.evidenceIds point
back to these rows.

This is a BIDIRECTIONAL reference (skill -> evidence,
evidence -> skill), both in Postgres. No local mirror
(AD-3): the Agent reads these server-side (fn-agent-run, AD-12).
```

## 5. AI Router Weighting (emotional state / energy)

**The Router does NOT use "emotional state" as a magic factor.**
It uses **measurable context variables** from the 9 context forms
(ADR S16, kernel.md S12 Context Builder):

| Context form | Variable | Source | Router use |
|---|---|---|---|
| Personal | `energy_level` (user-declared or inferred from Focus adherence) | UserContext + Progress | Task profile: low energy -> shorter session, lower complexity model |
| Personal | `silence_window` | UserContext | Agent proactivity: NO coach check-in during silence |
| Productivity | `interruption_count` (last hour) | FocusSession bilans | Task profile: high interruptions -> "urgent" routing (faster model) |
| Productivity | `overload_score` | Analytics (planned vs actual) | Task profile: overload -> suggest "replan" not "add more" |
| Learning | `skill_freshness` (Progress mirrors) | Progress `skill_states` | Task profile: stale skill -> "review" routing (ROUTINE, not AGENT) |
| Discovery | `gap_urgency` | Progress + Discovery | Task profile: urgent gap -> CRITICAL routing (stronger model + verification) |

**The routing formula (ai/providers-and-routing.md S11):**

```
model = f(taskProfile)

taskProfile = {
  complexity:  derived from gap_urgency + skill_freshness
  reasoning:   derived from problem_type (engineering = high, routine = low)
  tools:       number of tools needed (more = AGENT profile)
  vision:      false (text-based)
  context_size: sum of context forms (large = needs big context window)
  latency:     derived from energy_level + interruption_count
               (low energy / high interruptions = low latency needed)
  cost:        derived from budget_remaining (AIBudgetManager)
  criticality: derived from gap_urgency + deadline proximity
  verification: derived from problem_type (engineering = always)
  data_sensitivity: derived from user_context (private data = local models preferred)
}
```

**Example:**
- Tuesday 09:00, energy=high, interruptions=0, skill_freshness=stale:
  -> taskProfile: complexity=medium, latency=low, verification=yes
  -> model: Agnes 3.0 (AGENT profile, reasoning)
  
- Thursday 14:00, energy=low, interruptions=3, overload_score=high:
  -> taskProfile: complexity=low, latency=critical, cost=constrained
  -> model: Agnes 2.5 Flash (ROUTINE profile, fast + cheap)
  -> session: 10 min max (not 2h), content: review not new material

**The energy/overload variables are DATA, not "mood detection."**
They come from:
- UserContext (user explicitly sets "low energy today" or the system
  infers from Focus adherence: 0 focus sessions in 3 days = low
  engagement)
- Progress mirrors (skill_freshness, interruption trends)
- FocusSession bilans (interruptions, actual vs planned)

**NOT from:** LLM sentiment analysis of chat messages, facial
recognition, or "the AI feels you're stressed." The system is
deterministic and data-driven.

## 6. What does NOT change (ADR S14 invariants)

- Expert Skills are **server-only** (AD-3, 03 S4.2): no local mirror
- The kernel is **one** (AD-12): capabilities, not agents
- Skills are **procedural rules**, not neural network weights
- **No one-shot promotion** (ADR S14.5): minimum 2 contrastive pairs
- **User authority** (ADR S14.5): user can always override / delete
- **Provenance** (AD-11): every skill traces to specific evidence
- **Contradiction detection** (ADR S14.5): two active skills cannot
  contradict each other; the Agent flags and asks the user

## 7. Tests (wave 3+)

- Contrastive pair: create 2 sessions (success + failure) ->
  `contrastive_pairs` row -> skill confidence adjusts
- Confidence decay: create skill (confidence=0.8, lambda=0.3/30d) ->
  60 days pass without re-validation -> confidence = 0.8 * exp(-0.6)
  = 0.44 -> flag for re-evaluation
- Hypothesis: create hypothesis (confidence=0.2) -> 14 days, no
  evidence -> status='expired', NOT in active skill set
- Anti-regression: 1 anomalous week -> skill UNCHANGED (firewall);
  3 anomalous weeks -> skill adjusted
- Router: same task, different energy levels -> different model
  selected (high energy = AGENT model, low energy = ROUTINE model)
- User override: user says "stop using this strategy" -> immediate
  archive (bypasses firewall)
- RLS: user A cannot read user B's expert_skills
