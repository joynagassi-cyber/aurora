INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/international-expansion', 'legal', 'international-expansion', '', 'international-expansion', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# International Expansion Skill

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

International hiring gets handled sloppily at scaleups because nobody owns
the full picture. Legal knows the employment-law questions but not the PE
risk questions. Finance knows the cost model but not the employee-representation
triggers. HR knows the comp benchmarks but not the Day 1 compliance requirements.

This skill doesn't replace any of those functions. It maps the terrain, drafts
the right questions for each stakeholder, produces a briefing request that
walks outside counsel through the country-specific issues, and creates a
tracker that keeps the project moving across sessions.

This skill assumes expansion is decided. It is not a "should we expand?"
framework.

This skill does not contain country-specific employment law. The substantive
rules change frequently and vary by role, headcount, and industry — the skill
routes every country through an outside-counsel briefing rather than relying
on a stored reference table.

## Load context

Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, escalation table, any existing
expansion notes.

## Output header

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`).

## Workflow

### Step 1 — Information gathering

Ask all of the following in a single block:

> Before I build the expansion plan I need to understand the shape of this
> expansion. Please answer what you can — gaps in the answers are themselves
> useful data:
>
> **The expansion**
> - Which country?
> - What roles are you hiring? (Job function matters — a sales rep closing
>   deals creates different legal exposure than an engineer writing code)
> - How many hires are planned in the next 12 months?
> - When do you need the first person to start?
>
> **Current state**
> - Do you already have a legal entity in this country?
> - Have you used an EOR provider before? Are you already considering one?
> - Has tax or finance been looped in yet?
> - Do you have outside employment counsel in this country?
>
> **Strategic context**
> - Is this a long-term strategic commitment (building a real team) or
>   testing the market (one or two hires, see how it goes)?
> - Who is the executive sponsor making the structure decision?

Wait for responses before proceeding.

### Step 2 — EOR vs. entity framing

Do not make this decision. Frame it with enough precision that the CFO and
tax counsel can make it.

Work through the following factors against the intake answers and produce a
structured framing document:

**The core trade-off:**

| Factor | Points toward EOR | Points toward Entity |
|---|---|---|
| Headcount in 12 months | Fewer hires | More hires |
| Timeline to first hire | Short runway | Longer runway available |
| Strategic commitment | Testing the market | Long-term presence |
| Cost sensitivity | EOR markup acceptable | Scale makes entity more efficient |
| Control needs | Low — EOR employer handles local HR | High — want direct employer relationship |
| IP sensitivity | Lower | Higher — entity ownership cleaner |

Specific headcount break-even points, EOR markup ranges, setup costs, and
timelines vary by country and provider — do not hardcode them. Route those
questions to tax/finance and the EOR provider.

**PE risk flag (route to tax counsel):**
If roles include sales, business development, account management, or anyone
with authority to negotiate or sign contracts on behalf of the company —
flag this explicitly:

> PE Risk: [Role type] may create a taxable permanent establishment in
> [country] even before a legal entity exists. This is a tax question, not
> an employment question. Tax counsel must assess before the first hire.

**Produce the question for the CFO/tax:**

> Questions for your CFO and tax counsel:
> - At [N] hires over 12 months, at what headcount does entity setup become
>   more cost-effective than EOR (accounting for EOR markup, setup costs,
>   and ongoing compliance burden)?
> - [If PE-risk roles:] Do these role types create a taxable permanent
>   establishment in [country]? If yes, does that change the entity timeline?
> - If we start with EOR and convert to entity later, what are the transition
>   risks for the employees already on the EOR?
> - Who is our preferred EOR provider for this country, and have we vetted
>   their local compliance track record?

### Step 3 — Cross-functional triggers

For each function that needs to be looped in, state: what they need to do,
and the specific questions legal should ask them. Do not just say "loop in
finance." Draft the ask.

**Tax counsel** (always required before first hire)

What they need to do: PE risk analysis, determine whether entity is required
for tax purposes, advise on equity tax treatment in this jurisdiction.

Questions legal should ask:
- Does hiring a [role type] in [country] create a permanent establishment or
  taxable nexus before we have an entity?
- What is our exposure window if we start hiring before the PE question is
  resolved?
- How are our equity awards (RSUs/options) taxed in [country]? Do we need
  local tax counsel to advise employees at grant and vesting?
- If we set up an entity, what intercompany services agreement is needed
  between the subsidiary and the US parent?

**Finance / Payroll** (required before first paycheck)

What they need to do: identify local payroll provider (or confirm EOR handles
it), budget mandatory employer contributions, set up local banking if entity.

Questions legal should ask:
- Have we identified a local payroll provider? (If EOR: confirm EOR handles
  payroll including local social contributions)
- What are the mandatory employer contributions in [country] — pension,
  social insurance, healthcare — and are these budgeted in the comp model?
- How will equity grants be administered for employees in [country]? Has
  anyone modeled the employer-side tax withholding obligations at vesting?

**HR / Total Rewards** (required before offer is made)

What they need to do: benefits benchmarking, comp benchmarking against local
market, confirm mandatory vs. supplemental benefits.

Questions legal should ask:
- What benefits are legally mandatory in [country] vs. market-standard? (Do
  not want to accidentally promise more than required or less than market)
- Is our standard equity package competitive in this market, or does local
  practice differ significantly?
- Who will be this person's day-to-day manager — local or remote from HQ?
  (Affects employee-representation analysis and employment agreement terms
  in some jurisdictions)

**Outside counsel** (required — do not skip)

What they need to do: research and advise on the local employment framework
for this role and headcount, review/draft local employment agreement, flag
any structural issues with the proposed arrangement.

The outside-counsel briefing request in Step 4 is the agenda for this
engagement. Send it at the start — do not ask piecemeal.

### Step 4 — Country-specific briefing request

Instead of a stored country reference table, this skill produces a structured
outside-counsel briefing request. Substantive local law (entity requirements,
statutory benefits and contributions, termination protections, notice periods,
employee-representation / works-council / collective-bargaining obligations,
mandatory leave, restrictive covenants, data protection, work authorization)
varies by country *and* by role and headcount *and* by industry, and changes
frequently. Treat every country as a country that requires verification — do
not rely on the skill's own knowledge.

Draft the briefing request below, tailored to the intake answers:

**Outside counsel briefing request — [Country]**

> We are planning to hire [N] employees in [Country] starting [date], in the
> following roles: [roles]. Target headcount over 12 months: [N]. Preferred
> structure (subject to your advice and tax counsel): [EOR / entity /
> undecided]. We need a briefing covering each of the following. Please
> answer as questions with cites to primary law, not as a reference table —
> we want to be able to track changes over time.
>
> 1. **Entity and engagement structure** — what are our options (direct
>    hire via entity, EOR, contractor) and what are the practical and legal
>    trade-offs for this headcount and these roles?
>
> 2. **Employment contract requirements** — what form is required or standard?
>    What must be included? What cannot be included or is unenforceable?
>    What language or translation requirements apply?
>
> 3. **Termination** — what are the notice requirements and severance
>    obligations? How difficult is termination in practice (protected-cause
>    standards, social-selection rules in RIFs, reasonable-notice common-law
>    exposure)? What documentation standard should we establish from day one?
>
> 4. **Mandatory benefits and employer contributions** — what must we provide
>    by law (pension, social insurance, healthcare, paid leave, bonuses)?
>    What are the current employer contribution rates we should budget?
>    Please cite the controlling statute and verify currency.
>
> 5. **Restrictive covenants** — are non-competes enforceable? Under what
>    conditions and with what compensation requirements? What confidentiality
>    and IP assignment language holds up?
>
> 6. **Employee representation** — are there works council, employee
>    representation, union, or collective bargaining requirements? At what
>    headcount do they trigger? What consultation or co-determination rights
>    apply? Are we covered by any sectoral collective agreement even if we
>    are not unionized?
>
> 7. **Data protection** — what obligations apply to employee data? Is there
>    a data transfer mechanism needed for employee data flowing to the US?
>
> 8. **Work authorization** — what permits or visas are required for foreign
>    nationals? What are the processing timelines?
>
> 9. **Industry-specific rules** — are there sector rules, awards, or
>    collective agreements that apply to our industry regardless of whether
>    we are unionized?
>
> 10. **Contractor/independent-contractor risk** — what is the country's test
>     for classification, and what are the deemed-employment or reclassification
>     risks for any contractor arrangements we may consider?
>
> 11. **Equity / incentive compensation** — any local tax, securities, or
>     employment-law rules that govern how we grant RSUs, options, or other
>     equity here?
>
> 12. **Day 1 compliance** — what must be in place before the first employee
>     starts? Registration requirements, notices, filings, posters?
>
> 13. **Top 2-3 things that surprise US companies hiring here for the first
>     time** — what do you wish clients had asked you earlier? What has
>     *changed recently* that a US team might not have caught?

Add this briefing request to the expansion tracker as a single open item:
owner = Outside Counsel, status = open, with the full briefing agenda in
the questions field. If the jurisdiction is one the team has asked about
before, still send the briefing — this is a currency check, not a first
contact.

### Step 5 — Create the expansion tracker

Write a new file to `~/.claude/plugins/config/claude-for-legal/employment-legal/expansion-[country-slug].yaml` with all open items
identified in Steps 2-4. This file persists across sessions.

Format:

```yaml
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]
country: [Country name]
country_slug: [lowercase-hyphenated]
kickoff_date: [ISO date]
first_hire_target: [ISO date or "TBD"]
headcount_12mo: [N]
roles: [list]
strategic_commitment: [testing / long-term]
eor_or_entity: [EOR / entity / undecided]
outside_counsel_engaged: [true / false]
pe_risk_flagged: [true / false]
last_updated: [ISO date]

open_items:
  - id: 1
    category: [structure / tax / finance / hr / outside-counsel / compliance]
    item: "[what needs to happen]"
    owner: "[function or person]"
    status: [open / in-progress / done / blocked]
    due: [ISO date or null]
    questions:
      - "[specific question drafted in Steps 2-4]"
    notes: ""

  - id: 2
    [etc.]
```

Generate one open item per action identified across Steps 2-4. Do not collapse
multiple actions into one item — each item should be completable and
attributable to a single owner.

### Step 6 — Output

> **Jurisdiction assumption.** This plan frames the expansion to the single country identified in intake. Local employment law, tax rules, employee-representation obligations, and data-protection requirements vary materially by country, region, industry, and headcount, and change frequently. Every substantive local-law answer comes from the outside-counsel briefing request, not from this skill. If the plan is adapted for another country later, re-run the briefing.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## International Expansion: [Country] — [Date]

**First hire target:** [date]
**Headcount (12 months):** [N]
**Roles:** [list]
**Tracker:** ~/.claude/plugins/config/claude-for-legal/employment-legal/expansion-[slug].yaml

---

### EOR vs. Entity

[Framing from Step 2 — table, PE risk flag if applicable, questions for CFO/tax]

---

### Who needs to be looped in — and what to ask them

**Tax counsel** — [N] questions
[Questions from Step 3]

**Finance / Payroll** — [N] questions
[Questions from Step 3]

**HR / Total Rewards** — [N] questions
[Questions from Step 3]

**Outside counsel** — see briefing request below
[Full briefing request from Step 4]

---

### Open items ([N] total)

| # | Item | Owner | Status |
|---|---|---|---|
| 1 | [item] | [owner] | Open |
[etc.]

---

Run `/employment-legal:expansion-update [country]` to update status
as items close.
```

## What this skill does NOT do

- Advise on specific local employment law — that is outside counsel's job.
- Make the EOR vs. entity decision — frames it for the right decision-makers.
- Draft the local employment agreement — flags that outside counsel must do
  this.
- State country-specific rules from its own knowledge — every country is
  routed through an outside-counsel briefing.
- Substitute for outside counsel engagement — every new country requires
  local counsel, no exceptions.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/investigation-add', 'legal', 'investigation-add', '', 'investigation-add', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /investigation-add

Adds data to an open investigation log. Processes document batches using
documented pull criteria, surfaces significant items, logs everything
reviewed for coverage verification.

## Instructions

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`.
2. Load the `internal-investigation` reference skill and run Mode 2 (Add data).
3. After processing, show the surface ratio and list of surfaced items.
4. Prompt to update the sources checklist if the data covers a checklist item.

## Examples

```
/employment-legal:investigation-add [matter name]
[paste interview notes]
```

```
/employment-legal:investigation-add [matter name]
[attach email export]
```

> Detailed needle-finding process, log entry format, surface-ratio rules, and
> sources-checklist tracking live in the `internal-investigation` reference
> skill — load it before doing substantive work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/investigation-memo', 'legal', 'investigation-memo', '', 'investigation-memo', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /investigation-memo

Drafts the first cut of the privileged investigation memo from the log,
or updates an existing draft when new data has been added.

## Instructions

1. Load the `internal-investigation` reference skill and run Mode 4 (Draft or update memo).
2. If drafting for the first time, warn if high-priority sources are still
   open on the checklist.
3. If updating, show what changed before rewriting.
4. All output is marked PRIVILEGED AND CONFIDENTIAL — ATTORNEY WORK PRODUCT.

## Examples

```
/employment-legal:investigation-memo [matter name]
```

```
/employment-legal:investigation-memo [matter name]
(updates existing memo if one exists)
```

> Detailed memo structure, credibility-assessment framework, and update rules
> live in the `internal-investigation` reference skill — load it before doing
> substantive work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/investigation-open', 'legal', 'investigation-open', '', 'investigation-open', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /investigation-open

Opens a new investigation matter — runs intake, generates the sources
checklist, and creates the persistent investigation log.

## Instructions

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`.
2. Load the `internal-investigation` reference skill and run Mode 1 (Open).
3. If a matter with the same slug already exists, warn before overwriting.

## Examples

```
/employment-legal:investigation-open
Harassment complaint filed against a manager in the Austin office.
```

```
/employment-legal:investigation-open
(skill will ask for details)
```

> Detailed intake, privilege-formation requirements, sources checklist, and log
> templates live in the `internal-investigation` reference skill — load it
> before doing substantive work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/investigation-query', 'legal', 'investigation-query', '', 'investigation-query', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /investigation-query

Answers questions against the investigation log — what witnesses said,
where accounts conflict, what gaps exist, what the strongest evidence is
on each issue.

## Instructions

1. Load the `internal-investigation` reference skill and run Mode 3 (Query).
2. Always cite log entry IDs in the answer.
3. If the log contains nothing relevant to the question, say so explicitly —
   "I have not seen any information on [topic] in this investigation log
   ([N] entries reviewed)" — and offer to flag it as a gap.

## Examples

```
/employment-legal:investigation-query [matter name]
What did the respondent say about the December team dinner?
```

```
/employment-legal:investigation-query [matter name]
Where do the complainant's and respondent's accounts conflict?
```

```
/employment-legal:investigation-query [matter name]
What do we still need?
```

> Detailed log-query process, citation rules, and gap-flagging templates live
> in the `internal-investigation` reference skill — load it before doing
> substantive work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/investigation-summary', 'legal', 'investigation-summary', '', 'investigation-summary', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /investigation-summary

Drafts a stripped-down, audience-appropriate summary from the privileged
investigation memo. HR summaries contain no privilege analysis. Leadership
summaries are high-level. Outside counsel briefings include full context.

## Instructions

1. Load the `internal-investigation` reference skill and run Mode 5 (Audience summary).
2. If no memo exists yet, offer to draft the memo first.
3. HR summaries must not include attorney mental impressions, credibility
   methodology, or legal exposure analysis.

## Examples

```
/employment-legal:investigation-summary [matter name] hr
```

```
/employment-legal:investigation-summary [matter name] leadership
```

```
/employment-legal:investigation-summary [matter name] outside-counsel
```

> Detailed audience-stripping rules and summary templates live in the
> `internal-investigation` reference skill — load it before doing substantive
> work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/leave-tracker', 'legal', 'leave-tracker', '', 'leave-tracker', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /leave-tracker

Checks all open leaves with hard legal deadlines and surfaces only the ones
requiring a decision or action. Not a status board — tells you what you need
to do and why.

## Instructions

1. Load the `leave-tracker` agent and run the full workflow.

2. If no HRIS is connected and no `~/.claude/plugins/config/claude-for-legal/employment-legal/leave-register.yaml` exists, prompt
   the attorney to upload a leave spreadsheet or use
   `/employment-legal:log-leave` to add entries.

3. Alerts only for leaves requiring action. Clean leaves summarized one line each.

## Examples

```
/employment-legal:leave-tracker
```

Run this weekly — set a Monday-morning reminder to invoke
`/employment-legal:leave-tracker`. Automated scheduling requires a separate
integration (calendar reminder, cron job, etc.); Claude Code agents do not
self-schedule.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/log-leave', 'legal', 'log-leave', '', 'log-leave', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /log-leave

Adds a new leave entry to `~/.claude/plugins/config/claude-for-legal/employment-legal/leave-register.yaml` with the minimum
information needed to start tracking deadlines. Use when an employee goes on
leave and you want the tracker to watch the clocks from day one.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdiction table and Systems section.

2. Ask all of the following in a single prompt — do not drip them one at a time:

   > A few quick questions to set up leave tracking:
   >
   > - Employee name or role (anonymized is fine)
   > - Where do they work? (State — this determines which rules apply)
   > - Leave type: FMLA / state leave (which state) / USERRA / ADA accommodation
   > - Leave start date
   > - Is this intermittent leave?
   > - Expected return date (if known — leave blank if not)
   > - Has the designation notice been sent? If yes, when?
   > - Has medical certification been requested? If yes, when?

3. Using the jurisdiction table in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`, look up the applicable leave
   entitlement (hours/weeks) for this leave type in this jurisdiction.

4. Compute the first upcoming deadline based on the information provided:
   - Designation not yet sent → deadline is 5 business days from leave start
   - Med cert requested but not received → deadline is 15 days from request date
   - Both sent and received → next deadline is at 75% exhaustion

5. Write a new entry to `~/.claude/plugins/config/claude-for-legal/employment-legal/leave-register.yaml` using the leave register
   format from the leave-tracker agent. If the file doesn't exist, create it.

6. Confirm with a single line:
   > "Logged. [Employee/Role] — [Leave type] — [Jurisdiction] — started [date].
   > First deadline: [what it is and when]. Leave tracker will alert automatically."

## Examples

```
/employment-legal:log-leave
```

```
/employment-legal:log-leave
Sarah (Sr. Engineer, works in California) just started FMLA today for a
serious health condition. Intermittent. No designation sent yet.
```$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/employment-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/employment-legal:matter-workspace list` — list matters with status and active flag
- `/employment-legal:matter-workspace switch <slug>` — set the active matter
- `/employment-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/_archived/`, never delete)
- `/employment-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/employment-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Use the subcommand logic below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

## Reference

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; instead it explains the disabled state and suggests `/employment-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/employment-legal/
├── CLAUDE.md                       # practice-level practice profile
└── matters/
    ├── <slug>/
    │   ├── matter.md               # client, counterparty, matter type, key facts, overrides
    │   ├── history.md              # dated log of events, decisions, drafts, reviews
    │   ├── notes.md                # free-form working notes
    │   └── outputs/                # skill outputs for this matter (optional subfolder)
    └── _archived/
        └── <slug>/                 # closed matters — readable but not active
```

Slugs are lowercase with hyphens. Examples: `acme-msa-2026`, `zenith-renewal`, `vendor-xyz-nda`.

## Active matter is in the practice CLAUDE.md

The `Active matter:` line under `## Matter workspaces` in the practice-level CLAUDE.md is the single source of truth. Switching a matter edits that line. No separate state file.

## Subcommand logic

### `new <slug>`

1. Confirm slug is not already present in `matters/<slug>/` or `matters/_archived/<slug>/`. If reused, ask the user to pick a different slug.
2. Run the intake interview:
   - **Client** (the party we represent, or the internal business unit if in-house)
   - **Counterparty** (the other side — may be multiple)
   - **Matter type** (read the plugin's practice profile for typical categories; for employment-legal: hire | termination | investigation | leave | accommodation | classification | country expansion | policy project | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/employment-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/employment-legal:matter-workspace new <slug>`.
2. Edit the `Active matter:` line in the practice-level CLAUDE.md to `Active matter: <slug>`.
3. Show the user the matter.md summary so they can confirm they're on the right matter.

### `close <slug>`

1. Confirm `matters/<slug>/` exists.
2. Append a "Closed" entry to `matters/<slug>/history.md` with today's date.
3. Move `matters/<slug>/` → `matters/_archived/<slug>/`.
4. If the closed matter was the active matter, set `Active matter:` to `none — practice-level context only`.

### `none`

Set `Active matter:` in the practice-level CLAUDE.md to `none — practice-level context only`. Confirm with the user.

## `matter.md` template

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this` in the practice-level CLAUDE.md]

# Matter: [Client] — [short description]

**Slug:** [slug]
**Opened:** [YYYY-MM-DD]
**Status:** active
**Confidentiality:** [standard / heightened / clean-team]

---

## Parties

**Client:** [name]
**Counterparty:** [name(s)]

## Matter type

[vendor MSA | customer agreement | NDA | SaaS subscription | amendment | renewal | other — with one-line rationale]

## Key facts

[2–5 sentences. What this matter is about. Who the stakeholders are. What's at stake. What makes it different from the default playbook.]

## Matter-specific overrides

*Any deviation from the practice-level playbook that applies to this matter and only this matter.*

- [e.g., "LoL cap: client requires 24 months, not house standard 12."]
- [e.g., "Tone: relationship-preserving — counterparty is a strategic partner."]
- [e.g., "Governing law: must be English law, not Delaware."]

## Related matters

- [slug — one line why related]

## Notes on confidentiality

[If heightened or clean-team, describe why. Who may see matter files. Whether cross-matter context is permissible even if globally on.]
```

## `history.md` seed

```markdown
# History: [Client] — [short description]

Append-only event log. Most recent at top.

---

## [YYYY-MM-DD] — Matter opened

Intake completed. Slug: `[slug]`. Status: active.
[Any initial context worth preserving beyond matter.md — e.g., "Opened in response to inbound MSA draft from [counterparty]."]
```

## Cross-matter context

The practice-level CLAUDE.md has a `Cross-matter context:` flag. When it's `off` (the default), a skill working in matter A **never reads** files in `matters/B/` for any other `B`. Period. This is the confidentiality guarantee the setting exists to provide.

When it's `on`, a skill may read files across matter folders only when the user explicitly asks it to (e.g., "compare our position on liability caps across the last five vendor matters"). Even when `on`, the default is to load only the active matter unless the user asks for a cross-matter view.

## What this skill does not do

- **Run a conflicts check.** Conflicts are the practitioner's/firm's job; the intake captures what the user declares.
- **Enforce retention.** Closing archives a matter; it does not delete. Retention policy is out of scope.
- **Auto-route outputs.** The substantive skill decides where to write; this skill tells it *which folder* is active, not what to put in it.
- **Decide whether cross-matter is appropriate.** It reads the flag and obeys.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/policy-drafting', 'legal', 'policy-drafting', '', 'policy-drafting', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /policy-drafting

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, handbook location.
2. Use the workflow below.
3. Draft core policy. Check each jurisdiction in footprint for required variants.
4. Output: core policy + state supplements. Flag where law is currently shifting.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

A policy that's right for California may be wrong (or unnecessary) in Texas. This skill drafts a core policy and generates state supplements where the footprint requires different rules.

## Load context

`~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, handbook location and format.

## Workflow

### Step 1: Scope the policy

- What's the policy for? (Remote work, parental leave, social media, etc.)
- Why now? (Legal requirement, incident, growth, gap noticed)
- Who does it apply to? (All employees, certain roles, certain locations)

### Step 2: Jurisdictional scan

For each state/country in the footprint, check: does this jurisdiction have a specific rule on this topic?

**Common topics with jurisdictional variance:**

| Topic | Variance |
|---|---|
| Paid leave | State mandates (CA, NY, CO, WA, etc.) with different accrual rates, uses, carryover |
| Parental leave | State programs layer on top of FMLA (CA PFL, NY PFL, etc.) |
| Meal and rest breaks | CA is the outlier (penalty pay); most states minimal |
| Expense reimbursement | CA requires; most states don't |
| Pay transparency | Growing list of states requiring ranges in postings |
| Non-competes | See hiring-review skill — unenforceable in some states |
| Final pay | Timing varies widely |

If the topic has no jurisdictional variance (dress code, say), skip this step.

### Step 3: Draft the core policy

One policy. Applies everywhere. Clear and readable — employees should understand it without a lawyer.

Structure:
- Purpose (one sentence — why this policy exists)
- Scope (who it applies to)
- The rule (what's required/permitted/prohibited)
- Process (how to request, who approves, what happens if)
- Questions (who to ask)

Avoid: "heretofore," "notwithstanding," nested exceptions. This is a handbook policy, not a contract.

### Step 4: State supplements

For each jurisdiction where the rule differs, a supplement:

```markdown
### [State] Supplement

Employees working in [State] are subject to the following in addition to / instead of the core policy:

- [Specific difference]
- [Cite the state law if helpful]
```

Keep supplements tight. Only what's different — don't repeat the core.

### Step 5: Cross-check

- Does this policy conflict with anything already in the handbook?
- Does it promise more than the company intends to deliver? (A policy is a promise — courts hold employers to handbook promises.)
- Does it inadvertently create a contract? (Some states treat handbook policies as contractual — include the standard "this is not a contract" language if the handbook doesn't already.)

## Output

```markdown
# [Policy Name]

## Core Policy

[Full text]

## State Supplements

### [State 1]
[Supplement]

### [State 2]
[Supplement]

---

## Drafting Notes (internal — remove before handbook insertion)

- **Jurisdictional scan:** [which states checked, which have variance]
- **Conflicts with existing handbook:** [none | list]
- **Law currently shifting:** [any state where this is in flux]
- **Review cadence:** [when to revisit — annual, or when X happens]
```

> **Draft, not a policy in effect.** This is a drafting aid for attorney review, not a policy you can publish. Publishing a handbook policy has legal consequences — in several states it can bind the company as a contractual promise, and wage/leave/accommodation policies are routinely read against the employer. A licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction reviews, edits as needed, and takes professional responsibility before the policy is rolled out. Do not publish or distribute this draft unreviewed.

## Handoff

To handbook-updates skill: when this policy is approved, it diffs against the current handbook and flags what changes.

## What this skill does not do

- Approve the policy. It drafts; a human approves.
- Roll out the policy. Communication to employees is an HR workflow.
- Cover every jurisdiction on earth — only the ones in the footprint. If the footprint expands, re-run.$body$)
ON CONFLICT (skill_key) DO NOTHING;
