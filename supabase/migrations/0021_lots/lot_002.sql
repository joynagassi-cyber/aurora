INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/commercial-legal:customize`. They want to change something
in their practice profile — a risk posture, an escalation contact, a playbook
position, a jurisdiction, an output format — without re-running the whole
cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/commercial-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting, sales-side vs. purchasing-side orientation *(shared across all
     12 plugins — changes flow through `company-profile.md`)*
   - **Risk posture** — conservative / middle / aggressive, what each means
     for fallback positions and escalation triggers
   - **People** — escalation chain, approvers by dollar threshold and by
     clause type
   - **Playbook positions** — the substantive contract positions: liability
     caps, indemnity scope, IP ownership, data protection, termination,
     auto-renewal, price escalation, and the fallbacks for each
   - **NDA triage preferences** — what green / yellow / red looks like for
     inbound NDAs
   - **Review preferences** — redline style, explanation depth, whether to
     produce a stakeholder summary by default
   - **House style** — document format, signature block, renewal-alert
     channel, deviation-log format
   - **Workflow** — matter workspace paths, intake path, renewal watcher
     cadence
   - **Integrations** — Ironclad / DocuSign / Slack / document storage
     status, fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Liability cap fallback 12 months → 6 months:* "`/review` will now flag
     anything above 6 months as a deviation; existing deal-debrief entries
     stay as logged."
   - *New escalation approver:* "Any redline exceeding your own authority
     will now route to this approver — `/escalation-flagger` will include them by
     default for the matching risk band."
   - *Risk posture middle → aggressive:* "I'll accept more vendor-friendly
     positions without flagging them and shift the `[review]` bar higher."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/commercial-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" something, set it
  to `[Not configured]` and explain what that means for the plugin's behavior.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., risk posture aggressive + "every redline needs GC
  approval"; or "sales-side" + a purchasing-side playbook position), flag the
  tension and ask which one they want.
- **Flag guardrail degradation.** If the user asks to turn off a guardrail
  (drop the `[review]` flag, skip the privilege header, remove `[verify]`
  tags), explain what the guardrail protects against and confirm they
  understand the trade-off. The `[review]` flag, source attribution tags, and
  `[verify]` tags on cited statutes are load-bearing and should not be
  removed.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/escalation-flagger', 'legal', 'escalation-flagger', '', 'escalation-flagger', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /escalation-flagger

Names the approver for a contract issue per the `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` escalation matrix and drafts the message so you're not writing "hey got a sec" at 5pm.

## Instructions

1. **Load `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`** → Escalation section. If missing, say so — the practice profile needs editing.

2. **Characterize the issue:** dollar threshold / term deviation / automatic trigger / business decision.

3. **Match to matrix, name the approver.** Be specific — a person or role, not "legal leadership."

4. **Draft the ask** per the template below: what the contract says, what playbook says, options with recommendation, decision-by date.

5. **Do not send.** Draft it, show it, let the lawyer send.

## Examples

```
/commercial-legal:escalation-flagger
The Acme MSA has uncapped liability — who approves and what do I say?
```

```
/commercial-legal:escalation-flagger
Reference: acme-review-memo.md
Issue: §8.2 indemnity carveouts
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Every contracts team has an escalation matrix, written or not. This skill reads the written one (in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`), matches a contract issue against it, names the approver, and drafts the ask so the lawyer isn't writing "hey do you have a sec" messages at 5pm.

## Load the matrix

**Which side?** Before matching to the matrix, determine which side the company is on for the contract whose issue is being escalated. Usually obvious: if the counterparty is a vendor/supplier providing goods or services, you're purchasing-side. If the counterparty is a customer buying your product/service, you're sales-side. If it's not obvious, ask. Read the matching playbook section (`### Sales-side playbook` or `### Purchasing-side playbook`) to evaluate whether the term is inside fallbacks or triggers an automatic escalation — a term that's fine on one side can be a hard-no on the other. Note which side in the drafted ask so the approver knows which playbook was applied.

Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## Escalation`. If it's missing or vague, say so — the cold-start interview should have captured this, and if it didn't, the practice profile needs editing.

Expected structure:

| Can approve | Threshold | Escalates to | Via |
|---|---|---|---|
| Paralegal | Standard terms, <$50K | Counsel | Slack |
| Counsel | Non-standard but within fallbacks, <$500K | GC | Slack or email |
| GC | Everything else | CFO/Board | Meeting |

Plus **automatic escalation triggers** — things that escalate regardless of dollar value. Typically: unlimited liability, IP assignment, anything on the "never accept" lists.

## Workflow

### Step 1: Characterize the issue

What's being escalated?

- **Dollar threshold:** Contract value exceeds someone's approval authority
- **Term deviation:** A term is outside the playbook fallbacks — someone more senior needs to decide whether to accept
- **Automatic trigger:** One of the always-escalate items is present
- **Business decision:** Not a legal call — needs the business owner, not legal leadership

Don't escalate things that are actually fine. If the term is within the fallbacks in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, it doesn't need to go up.

### Step 2: Match to the matrix

```
Is the issue an automatic trigger?
  → YES: escalate to [person named for that trigger]
  → NO: continue

Is the contract value above the reviewer's threshold?
  → YES: escalate to whoever has authority at that dollar level
  → NO: continue

Is the term deviation outside all documented fallbacks?
  → YES: escalate to whoever can approve non-standard terms
  → NO: reviewer can approve — no escalation needed
```

### Step 3: Name the approver

Be specific. Not "escalate to legal leadership" — name the person or role from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the matrix doesn't name anyone for this situation, say so: "The escalation matrix doesn't cover [situation]. Suggest asking [GC name] who owns this."

### Step 4: Draft the ask

The approver should be able to decide from the message alone — no "let me pull up the contract."

```markdown
**Escalating to:** [name]
**Via:** [Slack #channel / email / meeting — per `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`]
**Urgency:** [deadline if there is one]

---

Hey [name] —

Need your call on the [Counterparty] [agreement type]. [One sentence on deal context.]

**The issue:** [Plain English, one paragraph. What they want, why it's outside
our standard, what the risk actually is.]

**What the contract says:**
> "[exact quote]"

**What our playbook says:** [quote from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`]

**Options:**
1. **Accept** — [one line on why this might be okay]
2. **Push back with:** "[proposed counter-language]" — [one line on likely counterparty reaction]
3. **Walk** — [one line on whether that's realistic given the business context]

**My recommendation:** [which option and why, briefly]

**Need a decision by:** [date, if there is a deadline]

[Link to full review memo]
```

### Step 5: Record the escalation

If this team uses a ticket system or [CLM] approval workflows, log it. If not, note in the review memo that the escalation was sent, to whom, and when. The next person who reads the memo should see the status.

## Calibration: when in doubt, escalate with a note

The cost of an unnecessary escalation is ~30 seconds of the approver's time — they read, say "fine, proceed," and the record shows they saw it. The cost of a missed escalation is signing an unapproved term, which is a one-way door. The costs are not symmetric. **When in doubt, escalate.**

The calibration for what warrants escalation lives in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, not in this skill. Check the playbook's stated position, its fallbacks, and its "automatic escalation regardless of dollar value" list:

- **Clearly inside the fallback range:** no escalation needed.
- **Clearly outside the range, or on the automatic-escalation list:** escalate.
- **Uncertain — the term is ambiguous, novel, or arguably inside the range but the argument is a stretch:** escalate anyway, and note the uncertainty explicitly. The draft flags the specific question the approver needs to decide and why the skill couldn't confidently place it inside the fallback. The approver narrows; the skill does not.

Do not suppress an escalation because over-escalation might train approvers to skim. That's an approver-experience problem the attorney solves by adjusting thresholds in the playbook, not a problem the skill solves by making its own subjective call on a term it's uncertain about.

If a term comes up that the playbook doesn't address, don't guess the threshold — ask the reviewing attorney whether this class of issue should escalate, and offer to record the answer in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` so future reviews are consistent.

## What this skill does not do

- It does not approve anything. It routes.
- It does not decide between the options. The draft includes a recommendation but the approver decides.
- It does not send the escalation message — it drafts it. The lawyer sends it after reading.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This command manages those workspaces.

## Subcommands

- `/commercial-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/commercial-legal:matter-workspace list` — list matters with status and active flag
- `/commercial-legal:matter-workspace switch <slug>` — set the active matter
- `/commercial-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/_archived/`, never delete)
- `/commercial-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/commercial-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Use the subcommand logic below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; the workflow above explains the disabled state and suggests `/commercial-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/commercial-legal/
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
   - **Matter type** (read the plugin's practice profile for typical categories; for commercial-legal: vendor MSA | customer agreement | NDA | SaaS subscription | amendment | renewal | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/commercial-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/commercial-legal:matter-workspace new <slug>`.
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
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/nda-review', 'legal', 'nda-review', '', 'nda-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# NDA Review

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

Most inbound NDAs are fine. A few have landmines. This skill sorts them in under a minute so legal only reads the ones that matter.

**The goal:** a GREEN NDA should need nothing more than a signature. A YELLOW needs a lawyer's eyes on one or two specific things. A RED stops before anyone wastes time.

## Load the playbook first

**Which side?** Before applying the playbook, determine which side the company is on for this NDA. Usually obvious from the context: if the counterparty is a vendor or partner evaluating your product, you're sales-side; if you're evaluating theirs, you're purchasing-side. Mutual NDAs still have a side — whose paper is it, and which direction is the evaluation running. If it's not obvious, ask. Read the matching playbook section (`### Sales-side playbook` or `### Purchasing-side playbook`) from the config. Note which side in the output so the reviewer knows which playbook was applied. If the matching side is `[Not configured]`, stop and tell the user to run `/commercial-legal:cold-start-interview --side <side>` before this triage can proceed.

**Before triaging anything, read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## Playbook` → the matching side → `NDA triage positions`.** That section is the source of truth for what makes an NDA GREEN, YELLOW, or RED for *this* team on *this* side. This skill does not ship with default positions on NDA terms — the law, the market, and each team's risk tolerance vary too much for hardcoded defaults to be safe.

If `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` doesn't have an `NDA triage positions` section yet, or it's silent on a term that comes up in the NDA you're reviewing, ask the user:

> Your playbook doesn't cover [term — e.g., "residuals clauses," "survival period," "one-way NDAs where you're the receiver"]. What's your default position — when should this be GREEN, when YELLOW, when RED? I'll add it to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` so the next review is consistent.

Then record the answer in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` and proceed with the triage using the new position.

## Scope check

**Before reviewing NDA-specific provisions, check whether the document is doing more than its name suggests.** Mutual commercial NDAs can hide: standstills, licensing grants, exclusivity, non-solicits, non-competes, IP assignments, right of first refusal, most-favored-nation clauses, and arbitration/jurisdiction clauses that govern far more than confidentiality disputes.

If the NDA contains obligations beyond confidentiality: **auto-YELLOW regardless of the NDA-term analysis.** Flag the non-NDA provisions:

> This document is labeled an NDA but contains [standstill / license grant / non-solicit / exclusivity / IP assignment / ROFR / MFN / broad arbitration]. It's more than an NDA. Route for attorney review.

Do not silently push a document labeled "NDA" through NDA triage when the substantive obligations are a services agreement, a term sheet, or a covenant package in NDA clothing.

## The triage

Classify the NDA into one of three buckets by applying the positions from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. The bucket definitions below are stable; the *criteria* that fill each bucket come from the playbook.

### GREEN — route to signature

The NDA satisfies every position in the team's playbook, and no term triggers a RED flag per the playbook. Examples of checks the playbook typically covers: mutuality, term length, survival period, carveouts, governing law, restrictive covenants, fee-shifting. Confirm each one against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` before calling GREEN.

**GREEN requires attorney-reviewed playbook positions.** GREEN is the only path to signature without lawyer review. It cannot be issued against default or absent positions. Before issuing GREEN, check: does the practice profile have an attorney-reviewed `## NDA triage positions` section? If not:

> I can't issue GREEN without attorney-reviewed NDA positions in your practice profile. Run `/commercial-legal:cold-start-interview --full` with your commercial counsel to set them, or route this NDA for attorney review. Issuing GREEN against defaults means a non-lawyer set the positions the next non-lawyer relies on.

Do not route to signature on defaults. YELLOW is the right call when positions are missing — it surfaces the NDA to a human who can decide.

**Output:**

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

## NDA Triage: [Counterparty]

GREEN — route to signature

### Executive Summary

No red flags identified under the playbook. Route for signature per standard process.

| Check | Status | Playbook reference |
|---|---|---|
| [Each playbook check] | [pass/fail] | [`~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` section] |

**Next step:** [Submit to [CLM] standard NDA workflow | Send to [approver from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`] for signature]
```

**Before proceeding past GREEN to signature:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the Role is Non-lawyer:

> This step has legal consequences (countersigning an NDA binds the company). Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, NDA direction (mutual / one-way), the playbook checks run, anything the playbook didn't cover, what could go wrong if signed as-is, and the three things to ask the attorney.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not proceed past this gate without an explicit yes.

### YELLOW — needs a lawyer's eyes on specific items

One or more terms deviate from the playbook but aren't categorical deal-breakers, OR a term appears that the playbook doesn't address. Surface each item individually so the approver can make the call.

**Output:**

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

## NDA Triage: [Counterparty]

YELLOW — flag for [approver name from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`]

### Executive Summary

- [One-line actionable edit, e.g. "Strike non-solicit clause (Section 6)"]
- [One-line actionable edit]

### Flagged items

**1. [Issue]** — Section [X]
   What: [one line]
   Why flagged: [one line — which playbook position this hits, or "playbook is silent on this"]
   **Legal risk:** [🔴/🟠/🟡/🟢] | **Business friction:** [🔴 Blocks deals / 🟠 Slows deals / 🟡 Confuses customers / 🟢 Invisible]
   Likely resolution: [accept / push back on X / depends on deal context]

[repeat for each flag]

### Everything else

| Check | Status | Playbook reference |
|---|---|---|
| [playbook checks that passed] | pass | [`~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` section] |

**Next step:** Ask [approver] about the flagged items, then route to signature if they're okay with it.
```

### RED — stop, talk to legal first

The NDA hits a position on the playbook's "never accept" list, or the structure of the agreement is incompatible with the team's standard posture (e.g., a one-way NDA where the team's playbook requires mutual; a perpetual term where the playbook caps at a finite period; governing law on the "never" list).

**Output:**

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

## NDA Triage: [Counterparty]

RED — do not submit, talk to legal first

### Executive Summary

- [One-line actionable edit, e.g. "Section 4 — route to Legal for review"]
- [One-line actionable edit]

### Critical issues

**1. [Issue]** — Section [X]
   > "[exact quote]"
   Why this is a problem: [specific risk; cite the playbook position it violates]
   **Legal risk:** [🔴/🟠/🟡/🟢] | **Business friction:** [🔴 Blocks deals / 🟠 Slows deals / 🟡 Confuses customers / 🟢 Invisible]
   Recommended response: [use our paper instead | push back with specific language | walk]

**Next step:** Send this triage to [GC or named escalation person from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`]. Do not send to [CLM or approvals workflow]. Do not tell the counterparty we'll sign.
```

## Redline granularity

**Edit at the smallest possible granularity.** A redline is a negotiation artifact, not a rewrite. Wholesale clause replacement signals "we threw out your drafting" — it's aggressive, it forces the counterparty to re-read the whole clause, and it discards the parts of their drafting that were fine. Surgical redlines — strike a word, insert a phrase, restructure a subclause — signal "we have specific asks" and are faster to read, understand, and accept.

Default to the smallest edit that achieves the playbook position:
- Replace a **word** before a phrase. ("twelve (12)" → "twenty-four (24)")
- Replace a **phrase** before a sentence. ("paid by the Buyer" → "paid and payable by the Buyer")
- Restructure a **subclause** before replacing the sentence. (Add "(a)" and "(b)" to split a compound condition.)
- Replace a **sentence** before replacing the clause.
- Only replace a **whole clause** when the counterparty's version is so far from your position that surgical edits would be harder to read than a fresh draft — and when you do, say so in the transmittal: "We've replaced §8.2 rather than marking it up because the changes were extensive. Happy to walk you through the delta."

When in doubt, smaller. A client who receives a surgical redline trusts that you read carefully. A client who receives a wholesale replacement wonders whether you read at all.

## Jurisdiction assumption

This triage applies the governing-law and restrictive-covenant positions recorded in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. Legal rules (enforceability of non-competes, non-solicits, fee-shifting, choice of law) vary materially by jurisdiction. If the NDA involves a jurisdiction outside the team's configured posture, flag it in the output and note that the triage may not transfer as written.

## Output rules

**Complexity filter:** If addressing an issue would require drafting new
language, restructuring a clause, or inserting substantive new
provisions — do not attempt it. Instead write:
"Section [X] — route to Legal for review."
Only include simple, mechanical actions in the Executive Summary
(strike, delete, replace a word or phrase).

**Clean NDA rule:** If the NDA passes all checks with no flags, the Executive Summary
should say only: "No red flags identified. Route for signature per
standard process."

Do not produce a lengthy report for a clean NDA.

## Detailed check reference

For each check below, the bucket (GREEN/YELLOW/RED) is determined by `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. This skill lists the *categories* to check; it does not hardcode thresholds.

### Mutuality

Is the NDA mutual or one-way? Apply the team's position from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the playbook doesn't address one-way NDAs for this context, run the one-way questionnaire below and surface the result for a human.

**One-way NDA questionnaire**

When the NDA is unilateral (one party discloses, the other only receives), do not immediately flag RED or exit. Ask:

> A one-way NDA is appropriate in some situations. Before flagging this,
> let me ask a few quick questions:
>
> 1. In this relationship, are you the only party disclosing confidential
>    information? (i.e., the other side shares nothing back)
> 2. Is this for a limited, specific disclosure — for example, sharing
>    your technology with a vendor who will work on it, but not sharing
>    theirs with you?
> 3. Is this related to M&A, employment, or investment? (If yes, stop —
>    this skill is for commercial MNDAs only. Route to Legal.)

Use the answers plus the `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` position to decide GREEN/YELLOW/RED. If `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` doesn't take a position on this fact pattern, flag YELLOW and surface the questionnaire answers for the approver.

### Definition of Confidential Information

Check scope (marked-only vs. everything-disclosed), marking requirements, and oral-disclosure confirmation windows. Apply the team's position from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the playbook is silent on any of these, ask.

### Carveouts

The five carveouts typically present in an NDA:

1. Information that is or becomes public (other than through breach)
2. Information the receiving party already had
3. Information independently developed without reference to the CI
4. Information received from a third party without restriction
5. Information required to be disclosed by law or court order (with notice to discloser where legally permitted)

Which carveouts the team requires, and how strictly, is a playbook question. Check `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` for the team's position on required carveouts, acceptable variations in wording, and what happens when one is missing.

### Residuals

A residuals clause lets the receiving party use information retained in unaided memory. Whether this is acceptable — and under what conditions (e.g., narrow "unaided memory" wording vs. broader scope covering notes or copies) — is a playbook question. Apply `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the playbook doesn't address residuals, ask.

### Term and survival

Check the initial term length, the post-term survival period for confidentiality obligations, and whether trade secrets are carved out with longer protection. Apply the team's position from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the playbook doesn't cover one of these, ask.

### Restrictive covenants

Check for non-solicits (employee, customer), non-competes, exclusivity, and any restriction on who else the receiving party can engage with. Apply `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the playbook is silent, ask — restrictive covenants are jurisdiction-sensitive and the team's posture matters.

### Attorneys' fees

Check for fee-shifting provisions and whether they are mutual, one-sided, or prevailing-party. Apply `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

### Backup and archival carveout

Check whether the destruction/return clause includes an exception for standard backup and archival retention systems. Apply the team's position from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` — some teams require this carveout and will push to add it; others accept an NDA without it. If the playbook doesn't address this, ask.

### Governing law

Per `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Playbook` → `Governing law and venue`.

## Counterparty context

**BigCo NDAs:** Fortune 500 counterparties generally won't negotiate NDAs. Calibrate: is the RED flag truly a deal-breaker, or is it "different from our form"? If the business relationship matters, the call is whether to accept their paper — escalate that decision, don't make it.

**Startup NDAs:** Will usually take our paper. If their NDA has issues, the fastest path is often "let's use ours" rather than redlining theirs.

## Integration: CLM

If connected:
- GREEN → offer to create the CLM record in the standard NDA workflow
- YELLOW → offer to create it with a note attached listing the flagged items
- RED → do not create a record; the lawyer decides what happens next

## What this skill does NOT do

- It does not negotiate. It sorts.
- It does not draft an NDA. If the answer is "use our paper," the user pulls our form from [CLM or document system].
- It does not make the call on YELLOW items. It surfaces them for a human.
- It does not state a position on any NDA term. Positions live in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

## Closing action

Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## NDA triage preferences` → `closing_action`.

If configured, append the closing action verbatim at the end of every
output. Example configurations:

```
closing_action: "Send the full text of this analysis along with a copy
of the NDA to Legal at legal@[yourcompany].com for final confirmation before
signing."

closing_action: "Submit to [CLM] using the standard NDA workflow.
Legal will confirm before routing for signature."

closing_action: "Forward this output and the NDA to your contracts
manager."
```

If `closing_action` is not configured in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, append:
"Route final NDA through your standard approval process."

The cold-start interview asks: "When someone finishes an NDA
triage, what do you want them to do with the output? I'll add that as
a standing instruction at the end of every review."

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/renewal-tracker', 'legal', 'renewal-tracker', '', 'renewal-tracker', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /renewal-tracker

Surfaces what's renewing and when you have to cancel by.

## Instructions

1. **Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/renewal-register.yaml`** (the config directory — survives plugin updates).

2. **Default mode:** Mode 2 — what's coming up in the next 90 days, grouped by urgency using half-open intervals so each deadline lands in exactly one band: 🔴 0–13 days, 🟠 14–44 days, 🟡 45–89 days. Days 14, 45, and 90 are boundaries — each belongs to exactly one band, not two.

3. **`--days N`:** Change the window.

4. **`--missed`:** Mode 4 — cancel-by deadlines that passed without recorded cancellation.

5. **If register is empty and the [CLM] is connected:** Offer Mode 3 — scan the [CLM] for active agreements with renewal dates and bulk-load.

6. **Output includes recommended actions:** who to ping (the business owner from each register entry), which ones have uncapped pricing (get leverage before window closes).

## Examples

```
/commercial-legal:renewal-tracker
```

```
/commercial-legal:renewal-tracker --days 180
```

```
/commercial-legal:renewal-tracker --missed
```

---

## Purpose

Nobody reads a contract twice. The renewal date is extracted once, at review time, and then it lives somewhere — ideally somewhere that shouts at you 45 days before the cancel-by deadline, not 45 days after.

This skill maintains the renewal register and surfaces what's coming.

## The register

Lives at `~/.claude/plugins/config/claude-for-legal/commercial-legal/renewal-register.yaml` (the config directory — survives plugin updates). Each entry:

```yaml
- counterparty: "Acme SaaS Inc."
  agreement: "Acme Platform Subscription Agreement"
  signed_date: 2025-06-15
  initial_term_end: 2026-06-15
  current_term_end: 2026-06-15     # rolls forward after each auto-renewal; compute cancel_by_* from this
  renewal_mechanism: "auto-renew annual"
  notice_period_days: 60
  notice_method: "email"           # email / portal / certified mail / registered post / courier / per contract §X
  transit_buffer_days: 0           # 0 for electronic, 5 for domestic certified mail, 10 for international registered post — or per contract if specified
  cancel_by_calendar: 2026-04-16    # current_term_end minus notice_period_days
  cancel_by_effective: 2026-04-16   # rolled back to last business day if needed
  send_by_effective: 2026-04-16    # cancel_by_effective minus transit_buffer_days — the date you must SEND the notice
  cancel_by_roll_note: ""           # e.g., "rolled back from Sunday 2026-11-01; verify against contract's business-day definition"
  cancel_by_provenance: "[model calculation — verify against the notice clause]"
  price_on_renewal: "then-current list (uncapped)"
  annual_value: 48000
  business_owner: "jane@company.com"
  clm_id:        "IC-12345"        # if connected
  docusign_envelope: "abc-123"   # if connected
  status: "active"               # active | cancelled | renewed | lapsed
  notes: "Pricing uncapped — revisit before renewal. Alt vendors: X, Y."
```

**Notice transit time — alert off `send_by_effective`, not `cancel_by_effective`.** A 60-day window with a certified-mail requirement is really ~55 days. The tracker that alerts on the received-by date is the tracker that misses the deadline. Compute `send_by_effective = cancel_by_effective - transit_buffer_days` and fire alerts (the 🔴 / 🟠 / 🟡 urgency bands in Mode 2) off `send_by_effective`. Mode 2's urgency column shows `send_by_effective`; a detail column surfaces `cancel_by_effective`, `notice_method`, and `transit_buffer_days` so the reader can see the delta and challenge the buffer.

**Rolling renewals — the register that doesn't roll forward is the register that's right once.** Store `initial_term_end` for the record, but compute `cancel_by_*` from `current_term_end`. When a renewal fires (the cancel window passes and no notice was given), prompt:

> This contract auto-renewed on [date]. Update the register: new `current_term_end` is [date + renewal period], new `cancel_by_effective` is [computed], new `send_by_effective` is [computed]. Confirm?

After year one, `initial_term_end` is wrong and only `current_term_end` produces a correct cancel-by date.

## Business-day check on every cancel-by date

**The register's cancel-by date must be the last BUSINESS DAY on which notice
is effective, not the calendar date.** A calendar date that falls on a
weekend is the single most common way a renewal deadline gets missed. The
register catches it.

When you compute (or ingest) a cancel-by date:

1. **Compute the calendar date.** `cancel_by_calendar = initial_term_end − notice_period_days` (or whatever the clause specifies). This is the raw arithmetic.
2. **Business-day roll-back keyed to governing law.** The contract's governing law determines which holidays count. US: federal holidays + the state's holidays if governing law is a state. England & Wales: bank holidays. Germany: Feiertage (vary by Bundesland — ask which). Canada: federal + provincial. Singapore: public holidays. If Saturday, roll back to Friday. If Sunday, roll back to Friday. If a holiday in the governing-law jurisdiction, roll back to the prior business day. Roll BACK, never forward — forward means notice arrives after the window closes. For non-US governing law, if you can't determine the holiday calendar, flag it: "Governing law is [X] — business-day roll-back uses US federal holidays as a placeholder. Verify against the [jurisdiction] holiday calendar before relying on the effective date."
3. **Check the contract's own day-counting rule.** Look for "business day," "received by," "deemed received," "5:00 p.m. [local time]," or a notice-method clause. If the contract defines "business day" or specifies receipt mechanics (certified mail, email with read receipt), that definition controls. Flag any mismatch between the default roll-back and the contract's own rule.
4. **Record BOTH dates in the register.** `cancel_by_calendar` is the raw arithmetic; `cancel_by_effective` is the last business day on which notice is effective; `cancel_by_roll_note` records why they differ (e.g., "rolled back from Sunday 2026-11-01; verify against contract's business-day definition"). Every computed `cancel_by_effective` carries a `cancel_by_provenance` tag of `[model calculation — verify against the notice clause]` so the verify flag travels with the date, not with the surrounding prose.
5. **Fire alerts off the EFFECTIVE date, not the calendar date.** Urgency bands (🔴 / 🟠 / 🟡 in Mode 2) use `cancel_by_effective`. Mode 2 output shows `cancel_by_effective` in the urgency column and surfaces `cancel_by_calendar` and `cancel_by_roll_note` in a detail column where the roll-back happened, so the reader can see it and challenge it.

A Mode 2 report that prints `cancel_by: 2026-11-01` (a Sunday) with no weekday and no warning is a silently wrong effective deadline. The register is the place to catch it — once, at ingest — not later, when the window has already moved.

## Modes

### Mode 1: Ingest a renewal (handoff from review)

When saas-msa-review or vendor-agreement-review finds a renewal clause, it hands off a record. Append it to the register. If the counterparty already has an entry, ask whether this is a replacement (renewed agreement) or an additional agreement.

### Mode 2: What's coming up

**Default lookback window:** next 90 days.

**Urgency bands are half-open intervals — a deadline lives in exactly one band.** Use days-until-cancel-by (`cancel_by_effective - today`). Day 14, 45, and 90 each belong to exactly one band, not two; an off-by-one here puts the most-urgent items into the less-urgent bucket.

- 🔴 **0–13 days** (cancel-by in less than 14 days — including today)
- 🟠 **14–44 days**
- 🟡 **45–89 days**
- (everything 90+ days is outside the default lookback window; include only if the user passed `--horizon` beyond 90)

```markdown
## Renewals — next 90 days

### 🔴 Cancel-by deadline in 0–13 days

| Counterparty | Cancel by | Renewal date | Annual $ | Owner | Notes |
|---|---|---|---|---|---|
| [name] | **[date]** | [date] | $[n] | [email] | [notes] |

### 🟠 Cancel-by deadline in 14–44 days

[same table]

### 🟡 Cancel-by deadline in 45–89 days

[same table]

---

**Recommended actions:**
- [ ] [Counterparty] — ping [business owner]: do we want to keep this?
- [ ] [Counterparty] — pricing is uncapped; get a quote from an alternative before we lose leverage
```

If the register has more than ~10 renewals in the window, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by urgency tier (🔴 / 🟠 / 🟡), a cancel-by timeline, and a sortable register with counterparty, renewal date, annual $, and owner.

### Mode 3: Scan the [CLM] / e-signature tool to populate the register

If MCPs are connected and the register is empty or stale:

1. Query the [CLM] for all agreements with status "Active" and a renewal date field
2. Query DocuSign for completed envelopes in the last 24 months with "subscription" / "renewal" / "auto-renew" in metadata
3. For each hit, extract renewal mechanics and add to register
4. Flag any where the renewal date can't be determined from metadata — those need a human to read the contract

This is a one-time bulk load. After that, ingest happens at review time.

### Mode 4: Missed windows (the bad news report)

```markdown
## Missed cancellation windows

The following agreements had cancel-by deadlines that have passed and no
cancellation was recorded:

| Counterparty | Cancel-by was | Renewal date | Status |
|---|---|---|---|
| [name] | [date] | [date] | Will auto-renew on [date] |

**Options:**
- Negotiate late cancellation (rarely works but worth asking)
- Accept the renewal, mark next year's cancel-by now
- Check the agreement for any other termination rights (for convenience, for cause)
```

## Gate: accepting or declining a renewal

Tracking a renewal date is research. *Acting* on it — sending a notice of non-renewal, letting an auto-renewal fire, or countersigning a renewal form — is a consequential legal step.

**Before proceeding to accept or decline a renewal (including sending a non-renewal notice or letting an auto-renewal run past the cancel-by date):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the Role is Non-lawyer:

> This step has legal consequences (you're either committing to another term or terminating the relationship). Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, current term end and cancel-by date, renewal price mechanism, what happens if we do nothing, alternative vendors if we want to shop, and the three things to ask the attorney before the window closes.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not proceed past this gate without an explicit yes.

## Integration: renewal-watcher agent

The renewal-watcher agent in this plugin runs this skill on a schedule (weekly by default) and posts the "coming up" report to the channel named in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## House style` → where work product goes. Mode 2 is the agent's primary output.

## What this skill does not do

- It does not cancel contracts. It tells you when to decide.
- It does not decide whether to renew. It surfaces the deadline and the business owner.
- It does not read contracts to find renewal dates — that happens at review time. If a contract is in the register without a renewal date, it was added manually and someone needs to fill in the gap.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/review', 'legal', 'review', '', 'review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /review

Reviews an inbound agreement against the playbook in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. Identifies the agreement structure from titles, selects the appropriate skill(s), and — if confirm_routing is enabled — checks with the user before proceeding.

## Instructions

1. **Load `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.** If placeholders present, stop and prompt: "Run `/commercial-legal:cold-start-interview` first — I need to learn your playbook before I can review against it."

   Also read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## Review preferences` → `confirm_routing`. If the field is missing, treat it as `true`.

2. **Get the agreement:** From file path, Drive link, [CLM ID], or pasted text. If none provided, ask.

3. **Read the document structure — titles first.**

   Before reading the body, extract:
   - The main agreement title (e.g., "Master Services Agreement", "Non-Disclosure Agreement")
   - All exhibit, schedule, addendum, and attachment titles (e.g., "Exhibit A — Data Processing Addendum", "Schedule 1 — Subscription Order Form", "Annex B — Service Level Agreement")

   This is the routing signal. Do not rely on body keywords alone — a 40-page MSA with "confidential" throughout is not an NDA.

4. **Select the skill(s) based on document structure.**

   Map each identified document or section to a skill:

   | Document / section title contains | Skill |
   |---|---|
   | Non-Disclosure, NDA, Confidentiality Agreement (as the *main* agreement) | **nda-review** |
   | Master Services Agreement, Professional Services, Statement of Work, Consulting Agreement | **vendor-agreement-review** |
   | Subscription, SaaS, Cloud Services, Order Form with auto-renewal, Software License with recurring fees | **saas-msa-review** (overlay on vendor-agreement-review) |
   | Data Processing Addendum, DPA, Data Processing Agreement (as exhibit or standalone) | note for **vendor-agreement-review** → data protection section |
   | Service Level Agreement, SLA (as exhibit) | note for **saas-msa-review** → SLA section |

   Multiple skills may apply. Common combinations:
   - MSA + DPA exhibit → vendor-agreement-review, with DPA noted
   - SaaS subscription + Order Form + SLA exhibit → saas-msa-review (covers all three)
   - MSA + Order Form with auto-renewal → vendor-agreement-review + saas-msa-review overlay

   When the structure is genuinely ambiguous after reading titles (e.g., a document titled "Agreement" with no exhibits listed), read the first two pages of the body to resolve it — then stop and route.

5. **Confirm routing if enabled.**

   If `confirm_routing` is `true` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` (or field is absent):

   ```
   I'm going to review this as: [agreement type(s)].

   Documents identified:
   - [Main agreement title] → [skill]
   - [Exhibit A title] → [how it will be handled]
   - [Exhibit B title] → [how it will be handled]

   Sound right? (yes / no — or tell me what I got wrong)
   ```

   Wait for confirmation before proceeding. If the user corrects the routing, apply their instruction and proceed.

   If `confirm_routing` is `false`: proceed silently. Log the routing decision at the top of the review memo so the user can see what was applied.

6. **Run the skill(s).** Follow each skill's workflow fully. If multiple skills apply, run them in sequence and integrate the output into a single memo — don't produce separate memos.

7. **Check for escalations:** If any issue exceeds the reviewer's authority per the `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` matrix, invoke **escalation-flagger** to route and draft the ask.

8. **Offer follow-ups:**
   - Stakeholder summary for the business owner
   - Redline .docx with tracked changes
   - [CLM] record creation (if connected)
   - Add to renewal register (if auto-renewal found)

## Configuring confirm_routing

Add to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## Review preferences`:

```markdown
## Review preferences

confirm_routing: true   # Set to false to skip routing confirmation and proceed automatically
```

The cold-start interview should ask about this preference. Default is `true` — confirmation on. As trust builds, the user can set it to `false`.

## Examples

```
/commercial-legal:review vendor-msa.pdf
```

```
/commercial-legal:review https://drive.google.com/file/d/ABC123
```

```
/commercial-legal:review
[paste agreement text]
```

## Output

Full review memo per the skill's format. Routing decision logged at the top. Deviation-by-deviation, specific redline language, named approver. Saved where `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → House style says work product goes.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/review-proposals', 'legal', 'review-proposals', '', 'review-proposals', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /review-proposals

Steps through pending playbook update proposals from the monitor agent and applies approved changes to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

## Instructions

1. **Load the playbook-monitor agent** and run Step 5 (review and approval flow).

2. **If no proposals file exists** or it is empty: respond *"No pending proposals. Playbook is up to date."* Do not proceed further.

3. **Present proposals one at a time.** For each, show the full proposal block and offer four options: Accept, Reject, Edit, Defer.

4. **For Accept or Edit:** show the exact diff to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` before writing. Only apply after the attorney explicitly confirms.

5. **For Reject or Defer:** log the decision. Do not modify `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

6. **After all proposals are resolved:** show a summary of what changed, then archive the proposals file.

## Examples

```
/commercial-legal:review-proposals
```

```
/commercial-legal:review-proposals
(runs automatically after playbook-monitor notifies you)
```$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/saas-msa-review', 'legal', 'saas-msa-review', '', 'saas-msa-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# SaaS / Subscription Agreement Review

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

SaaS agreements have a distinct risk profile from one-time vendor contracts. The dollars compound over renewals, the data accumulates, and the switching cost grows every month. This skill reviews with that in mind.

It runs the standard playbook check from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` and adds a SaaS-specific overlay on the terms that bite hardest in subscription deals.

## Jurisdiction assumption

SaaS terms (auto-renewal notice requirements, price-escalation caps, data-portability mandates, subprocessor rules) are jurisdiction-sensitive — California, New York, and EU rules diverge materially, and some states have auto-renewal statutes that override private contract terms. This review applies the team's positions from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, which assume the governing law recorded there. If the agreement picks a different governing law, or the deal spans jurisdictions with statutory overrides (e.g., EU-based users, California consumers), flag it — the analysis may not transfer as written.

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, or firm platform) returns few or no results for a statutory override that might bear on the deal (auto-renewal statute, data-portability mandate, consumer-protection rule), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [jurisdiction / rule]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Where the review cites a statute, regulation, or case (e.g., a state auto-renewal law overriding contract terms), tag the citation: `[Westlaw]`, `[statute / regulator site]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations from the counterparty draft or house files. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

## Load the playbook

**Which side?** Before applying the playbook, determine which side the company is on for this SaaS agreement. Usually obvious: if the counterparty is a SaaS vendor selling you their platform, you're purchasing-side. If you are the SaaS vendor and the counterparty is your customer, you're sales-side. If it's not obvious (a reseller arrangement, a white-label deal), ask: "Which side is [company] on for this agreement — vendor or customer?" Read the matching playbook section (`### Sales-side playbook` or `### Purchasing-side playbook`) from the config. Note which side in the output so the reviewer knows which playbook was applied. If the matching side is `[Not configured]`, stop and tell the user to run `/commercial-legal:cold-start-interview --side <side>` before this review can proceed.

Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` first. The general playbook for the matching side (liability, indemnity, termination, governing law) applies fully — run all the standard checks from the vendor-agreement-review skill.

Then look for a `## Playbook` → matching side → `SaaS positions` section. That's where the team records its positions on auto-renewal notice windows, acceptable price escalators, data export rights, SLA thresholds, subprocessor approval rights, and deprecation notice. This skill does not ship with defaults for these — the right numbers vary by deal size, vendor leverage, and the team's risk tolerance.

If `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` doesn't address a SaaS-specific term that comes up in this review, ask:

> Your playbook doesn't cover [term — e.g., "maximum acceptable auto-renewal notice window" or "whether vendor retention of anonymized derivatives is acceptable"]. What's your team's position? I'll add it to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

Record the answer and proceed.

## SaaS-specific overlay

For each category below, list what you found in the contract and compare to the team's position in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. Do not apply hardcoded thresholds from this skill.

### 1. Auto-renewal mechanics

The single most common way a SaaS deal goes wrong: nobody notices the renewal notice window and we're locked in for another year at a higher price.

Check each element and compare against the team's `SaaS positions` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Renewal term length** (e.g., same as initial, longer, multi-year auto-convert)
- **Notice-to-cancel window** (number of days before renewal)
- **Notice method** (email, written notice to legal, portal-only, certified mail)
- **Price on renewal** (same, CPI-capped, then-current list, uncapped discretionary)

**Extract and record** the exact renewal date and the notice window regardless of whether any item is flagged. This feeds the renewal-tracker skill.

### 2. Price escalation

Check each element against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Annual escalator** (fixed %, CPI, uncapped, etc.)
- **Usage overage pricing** (published rate card, premium rate, unspecified)
- **Scope of "fees"** (subscription only vs. "additional services" broadly defined)

### 3. Data portability and exit

When (not if) we leave this vendor, can we get our data out? Check each element against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Export format** (open/standard, proprietary-but-documented, "commercially reasonable")
- **Export availability** (self-serve anytime, on request during term, only at termination)
- **Post-termination access** (days available to export after termination)
- **Export cost** (free, T&M, per-GB or per-record)
- **Deletion certification** (certified on request, none, vendor retains derivatives)

Vendor retention of "anonymized" or "aggregated" derivatives is a material position — confirm the team's stance in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` and flag either way.

### 4. Uptime and SLA

Only matters if the business actually depends on this service being up. If it's a nice-to-have tool, skip this section — don't spend negotiating capital on SLAs for a survey tool.

Check each element against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Uptime commitment** (percentage, or "commercially reasonable efforts")
- **Measurement period** (monthly, quarterly, annual)
- **Remedy** (service credits — how calculated, whether capped, whether sole remedy)
- **Scheduled maintenance exclusions** (defined window, advance notice, unlimited)
- **Credit-as-sole-remedy** interaction with the liability cap

### 5. Subprocessors

This is a data protection issue but it's SaaS-specific because the subprocessor list *changes* over the life of the subscription.

Check each element against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Current list** (published, on request, unavailable)
- **Change notification** (advance notice period, or none)
- **Objection rights** (blocking, notice-and-terminate, notice-only, none)

### 6. Service changes and deprecation

SaaS vendors change their product. Usually fine. Sometimes they deprecate the thing you bought.

Check each element against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:

- **Material adverse changes** (right to terminate on material degradation, notice-only, unrestricted)
- **Deprecation notice period** for features the team relies on
- **Feature parity on replacement** (same price tier, higher tier)



## AI and machine learning rights

**AI/ML data rights decision procedure.** Don't just check whether an AI training clause exists. The #1 emerging negotiation point in SaaS contracts is structurally more than a one-line existence check. Work through:

1. **Explicit grant.** Does the contract explicitly grant the vendor rights to use Customer Data / Customer Content / Usage Data for AI training, model improvement, or ML development? Purchasing-side: this is usually a NO — customer data training the vendor's models means the customer is subsidizing the vendor's product and possibly leaking competitive information. Sales-side: this is revenue if you get it, reputation risk if you abuse it.
2. **Implicit grant via policy.** Does the contract incorporate the vendor's privacy policy or terms of service by reference? Can the vendor add training rights via a unilateral policy update? Check: "The parties agree to the Provider's Privacy Policy as updated from time to time" is a training-rights grant waiting to happen. Also watch for "service improvement" or "analytics" catch-alls and "usage data" definitions that carve logs/telemetry out of the Customer Data definition so data-use restrictions don't apply.
3. **Anonymization standard.** If the vendor claims it only trains on "anonymized" or "aggregated" data, what's the standard? "Anonymized" without a definition is weak. Does it meet GDPR Recital 26 / HIPAA Safe Harbor / a named standard? Is it reversible?
4. **Competitive contamination.** Does the vendor serve your competitors? If so, training on your data could leak competitive intelligence into outputs your competitors see. Is there a competitive isolation commitment?
5. **Opt-out scope and durability.** If there's an opt-out, does it cover all AI uses or only some? Does it survive renewals and TOS updates? Is it per-user or per-org? Many vendors default to training and offer an opt-out buried in an admin console — check whether the contract makes the default explicit.
6. **Output ownership.** If the SaaS product is itself AI-generated (drafting, summarization, analysis), who owns the outputs? Can the vendor use your outputs as training examples? Check third-party AI subprocessors too — the vendor may send customer data to a third-party LLM (OpenAI, Anthropic, Google) and the subprocessor list / data flow is where that shows up.
7. **Downstream regulatory chain.** Does the vendor's use of your data for AI create regulatory exposure for YOU? EU AI Act deployer obligations, FTC §5 undisclosed data-sharing exposure (see *FTC v. Humor Rainbow/OkCupid*), state AI laws.

Match each to a playbook position. The practice profile's `## AI/ML training rights` section should have positions for each. If the agreement is silent on all seven, that's still a finding: "The agreement is silent on AI/ML training rights — request an explicit prohibition or a defined carve-out tied to each of the seven dimensions above."

## Liability cap decision procedure

**The cap amount is the least important part of the cap.** Limitation-of-liability is not a single "check against playbook" item. Work through:

1. **Direct vs. indirect/consequential damages.** Does the cap apply to ALL liability, or only direct damages? A 12-month cap on direct damages with uncapped consequential damages is a completely different position than a 12-month aggregate cap. State both treatments explicitly.

2. **The cap base — quote it verbatim.** "12-month cap" could mean: (a) fees paid in the 12 months preceding the claim, (b) fees payable in the current 12-month period, (c) fees over the last 12 months of usage, (d) fees under the current order form, (e) total fees ever paid. These can differ by an order of magnitude. Quote the exact language. If ambiguous, flag it: "Cap base is ambiguous — `[the quoted language]` — could mean [X] or [Y]. Confirm before signing."

3. **Cap-carveout interaction.** A $100K cap with uncapped indemnity for data breach, IP, and confidentiality is functionally uncapped for the claims that actually arise in SaaS disputes. Enumerate what sits ABOVE the cap (the carveouts), what sits BELOW (what's actually capped), and assess whether the capped surface is meaningful: "The cap covers [general contract breach]. Data breach, IP indemnity, and confidentiality are carved out and uncapped. For this vendor's risk profile, the capped surface is [meaningful / nominal]."

4. **Your playbook position per dimension.** The practice profile should have positions for: direct cap (multiple of fees), indirect damages (excluded / capped / uncapped), carveout list (what's acceptable above the cap), and cap base (which definition you'll accept). If the playbook has one "standard position" field, note: "Your playbook has a single cap position — consider splitting into direct/indirect/carveouts/base for more precise review."

## Jurisdiction delta check

**The playbook applies one governing-law preference globally. Enforceability varies materially.** Check the SaaS contract's actual governing law against the top divergences before accepting playbook positions at face value:

- **Non-solicits/non-competes:** Unenforceable in CA (Bus. & Prof. Code §16600). Restricted in many EU jurisdictions. Enforceable with limitations elsewhere. `[jurisdiction — verify]`
- **Auto-renewal:** CA GBL §17600-17606, NY GBL §527-a, IL 815 ILCS 601 have specific consumer/B2B notice requirements. Other states vary. `[jurisdiction — verify]`
- **Liability exclusions:** EU and UK unfair contract terms rules (UCTA 1977, Consumer Rights Act 2015) constrain consumer exclusions. Some US states limit exclusion of gross negligence or willful misconduct. `[jurisdiction — verify]`
- **Indemnification:** Some states void indemnification for the indemnitee's own negligence. `[jurisdiction — verify]`
- **Confidentiality term:** Some jurisdictions limit "perpetual" confidentiality to a reasonable period. `[jurisdiction — verify]`

When the playbook position conflicts with the contract's governing-law enforceability, flag: "Your playbook prefers [X], but this contract is governed by [Y] law where [X] is [unenforceable / restricted / subject to statutory override]. `[jurisdiction — verify]`"

## Redline granularity

**Edit at the smallest possible granularity.** A redline is a negotiation artifact, not a rewrite. Wholesale clause replacement signals "we threw out your drafting" — it's aggressive, it forces the counterparty to re-read the whole clause, and it discards the parts of their drafting that were fine. Surgical redlines — strike a word, insert a phrase, restructure a subclause — signal "we have specific asks" and are faster to read, understand, and accept.

Default to the smallest edit that achieves the playbook position:
- Replace a **word** before a phrase. ("twelve (12)" → "twenty-four (24)")
- Replace a **phrase** before a sentence. ("paid by the Buyer" → "paid and payable by the Buyer")
- Restructure a **subclause** before replacing the sentence. (Add "(a)" and "(b)" to split a compound condition.)
- Replace a **sentence** before replacing the clause.
- Only replace a **whole clause** when the counterparty's version is so far from your position that surgical edits would be harder to read than a fresh draft — and when you do, say so in the transmittal: "We've replaced §8.2 rather than marking it up because the changes were extensive. Happy to walk you through the delta."

When in doubt, smaller. A client who receives a surgical redline trusts that you read carefully. A client who receives a wholesale replacement wonders whether you read at all.

## Output

Use the vendor-agreement-review memo structure, with a SaaS-specific section added after the standard playbook checks. The vendor-agreement-review memo already carries the privilege header.

**Dual severity.** Every SaaS-specific finding carries both axes (see CLAUDE.md `## Dual severity`):
- **Legal risk:** 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low
- **Business friction:** 🔴 Blocks deals | 🟠 Slows deals | 🟡 Confuses customers | 🟢 Invisible

Data-exit, auto-renewal, and price-escalation findings are the ones most likely to be 🟢 legal / 🔴 business — the clause is enforceable, but it's the reason a customer can't leave or a renewal surprises finance. Surface those at the business-friction severity, not the legal one.

```markdown
### Bottom line

[Can you sign / Need to fight for X first / Walk — one-sentence why]

### AI and machine learning rights

[The #1 emerging SaaS negotiation point. Flag: explicit ML training clauses, "service improvement" catch-alls, usage data definitions, output ownership, third-party AI subprocessors, opt-out vs opt-in. If the agreement is silent: "Silent on AI/ML training rights — request explicit prohibition or defined carve-out."]

## SaaS-specific findings

### Auto-renewal
**Renewal date:** [date]
**Notice window:** Cancel by [date] ([N] days before renewal)
**Renewal price mechanism:** [as written]
**Playbook fit:** [within position / deviation / not addressed]
**Flag for renewal-tracker:** [yes — and the record the tracker needs]

### Price escalation
[findings against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` positions]

### Data exit
[findings — this is the one the business owner should read]

### SLA
[findings, or "Skipped — service is not business-critical per [stakeholder]"]

### Subprocessors
[findings against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` positions]

### Service changes
[findings against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` positions]
```

## Handoffs

**To renewal-tracker:** When you find the renewal date and notice window, hand them off. The renewal-tracker register expects the following fields (see `skills/renewal-tracker/references/renewal-register.yaml` for the full schema):

```yaml
counterparty:         [name]
agreement:            [title]
signed_date:          [ISO date]
initial_term_end:     [ISO date]
renewal_mechanism:    [e.g., "auto-renew annual"]
notice_period_days:   [integer]
cancel_by_effective:            [ISO date — initial_term_end minus notice_period_days]
price_on_renewal:     [mechanism as written]
annual_value:         [integer, if stated]
business_owner:       [email, if known]
clm_id:               [id if available]
status:               active
```

If any field is not determinable from the contract or context, leave it out and note which fields were missing so the human can fill them in. `clm_id`, `annual_value`, and `business_owner` are especially likely to need human input.

**To escalation-flagger:** If any of the SaaS-specific checks hits the team's "never accept" or escalation-trigger list in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, the escalation-flagger skill routes it.

## A note on what to fight over

SaaS vendors, especially large ones, negotiate their paper about as willingly as airlines negotiate ticket terms. Pick battles *per the team's playbook* — the `SaaS positions` section in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` should distinguish between terms the team will always push on, terms it fights over only for material deals, and terms it lets slide. If the playbook doesn't draw those lines, ask.

Calibrate based on contract value and switching cost. A $5K/year tool with easy alternatives gets a lighter touch than a $500K/year platform we'll build on top of.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/stakeholder-summary', 'legal', 'stakeholder-summary', '', 'stakeholder-summary', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Stakeholder Summary

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

The business owner who asked for this contract doesn't want a legal memo. They want to know: can I sign it, what's the catch, and what do I need to do. This skill takes a completed review and turns it into that.

## Which side?

The underlying review memo was run against either the sales-side or the purchasing-side playbook. Carry that framing through. A purchasing-side summary tells the business owner "here's what we're getting and what we agreed to give up"; a sales-side summary tells them "here's what we're selling and what we're on the hook for." Check which side the review was run on (it should be noted at the top of the review memo) and match the voice. If it's not obvious from the memo, ask the lawyer before summarizing.

## Audience calibration

Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `## House style` → who reads stakeholder summaries, how long should they be. If not specified, default to: procurement or a department head, two paragraphs max, no legal terms of art.

Different audiences need different summaries:

| Audience | Cares about | Doesn't care about |
|---|---|---|
| **Procurement** | Price, renewal mechanics, approval routing | Liability cap structure |
| **Department head (budget owner)** | Can their team use it, what happens if it breaks, cost | Indemnity scope |
| **Finance** | Total cost of ownership, renewal price risk, off-balance-sheet commitments | Governing law |
| **Security / IT** | Data handling, subprocessors, SOC 2, where data lives | Everything else |
| **Executive sponsor** | Is this going to embarrass us, is legal a blocker | Details |

Ask who this is for if it's not obvious from context.

## The summary

### Length cap — enforced

The summary is:
- **One paragraph** for the verdict and what this is (business terms, plain English)
- **One paragraph** for the catch — the thing the stakeholder would be surprised by later if nobody told them now
- **A 2-3 item checklist** for what the stakeholder actually needs to do (at most three items; if you want a fourth, the first three aren't tight enough)
- **A one-line close** with approval timing

**Under 200 words total.** If you're writing more, you're including detail the stakeholder doesn't need — they have the memo for that. This is the quick read before the stakeholder hits reply.

If the close needs a third paragraph, fold it into the checklist instead. Don't let the close grow into a fourth block.

### Scope of quote — discipline

When quoting a contract clause (in the summary, in the "catch" paragraph, or in the checklist), quote the **full conditional sentence**, not a truncated version. A clause that reads "Except as expressly provided in the Order Form, renewal of promotional or one-time priced subscriptions resets to list price" means something different from "renewal resets to list price" — the truncation drops the condition and misrepresents what the term does.

If a full conditional quote doesn't fit the summary's length cap, paraphrase rather than truncate. "For promotional pricing, renewal resets to list" is a fair paraphrase; "renewal resets to list" is not — it promotes the exception to the rule.

### Format

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]
<!-- Remove the header above if forwarding outside the legal-privileged circle (e.g., to a business stakeholder, counterparty, or vendor). Confirm the correct marking for your jurisdiction and matter before forwarding. -->

**[Counterparty] [Agreement type]** — [READY TO SIGN | NEEDS CHANGES | BLOCKED]

[One paragraph: what this agreement does, in business terms. Not "Master Services
Agreement for the provision of cloud-based analytics" — "this is the contract
for the dashboard tool the marketing team wants."]

[One paragraph: what the stakeholder needs to know. The catch, if there is one.
The thing that will surprise them later if nobody tells them now. E.g., "Heads
up: this auto-renews every year and we have to cancel 60 days out. I've added
it to the tracker but you should know." Or: "Clean agreement, no surprises,
cleared to sign."]

<!-- Do not claim "I've added it to the tracker" unless `renewal-tracker` has
actually been run for this contract — see Verify tracker entries before
asserting them below. -->

**Verify tracker entries before asserting them.** Before the summary says "I've added it to the tracker" (or any equivalent — "it's in the tracker," "tracked," "set a reminder"), verify that `renewal-tracker` has been run for this contract. Check the outputs folder or the matter folder for a `renewal-tracker` output that names this counterparty / agreement. If there isn't one:

- Either run `renewal-tracker` for this contract first, then write the summary.
- Or write the summary without asserting the tracker entry, and include an action item: "Add to renewal tracker — not yet done."

Claiming a tracker entry exists when it does not is worse than omitting the reassurance. The stakeholder then trusts the reminder that will never fire. If the truthful statement is "tracked," the skill runs the tracker. If it's "you should add this to your calendar — I haven't logged it," say that.

**What you need to do:**
- [ ] [Action item, if any — "confirm the team is okay with data living in EU"
  or "nothing — I'll route for signature"]

**Approval:** [who's approving and expected timing]
```

### What to translate

| Legal finding | Business translation |
|---|---|
| "Liability capped at 12 months fees" | "If they break something, the most we can recover is a year's worth of what we paid them." |
| "No termination for convenience" | "Once we sign, we're locked in for the full term — we can't just cancel if we stop using it." |
| "Auto-renewal with 60-day notice" | "This renews automatically every year. To cancel, we have to tell them two months before the renewal date." |
| "No IP indemnity" | "If someone sues us claiming this tool infringes their patent, the vendor isn't on the hook to defend us." |
| "Subprocessor list not disclosed" | "We don't know what other companies will have access to our data through them." |
| "Data deletion within 30 days of termination" | "When we cancel, they delete our data within a month. Export anything you need before then." |
| "SLA credits capped at 10% of monthly fee" | "If the service goes down, we get a small credit back. It won't cover the cost of the downtime to the business." |

### What NOT to include

- Section numbers
- Defined terms in quotes
- The word "indemnification" (say "they cover us if" / "we cover them if")
- The word "notwithstanding"
- Risk matrices with colored dots (unless this stakeholder has specifically asked for them before)
- Caveats about how this isn't legal advice — the stakeholder knows who sent it

## When the review found problems

If the review has 🔴 or 🟠 issues, the summary still needs to be two paragraphs — but the second paragraph is "here's what we're pushing back on and why."

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]
<!-- Remove the header above if forwarding outside the legal-privileged circle. -->

**[Counterparty] [Agreement type]** — NEEDS CHANGES

[What it is, one paragraph.]

We're going back to them on [N] things before this is ready. The main one:
[the critical issue in plain English — "they want the right to use our data
to improve their product, which means our competitors' instance gets smarter
from our data"]. We've asked them to strike it. [Realistic assessment: "They'll
probably agree" / "This might be a sticking point — will keep you posted."]

**What you need to do:**
- [ ] Nothing yet — I'll let you know when it's back from them.
  OR
- [ ] [Business decision they need to make: "If they won't budge on X, are you
  okay with Y, or do we walk?"]
```

## Handoffs

**From vendor-agreement-review / saas-msa-review:** Those skills produce the full memo. This skill reads the memo and compresses it. Don't re-review the contract — read the review.

**To the stakeholder:** Via whatever channel `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` says. If Slack, keep it under 150 words. If email, the format above is fine as-is.

## Escalation-fan-out reconciliation

The upstream review is a one-to-many producer: it can name five escalation targets (Deputy GC, CISO, Privacy Officer, CFO, business owner) across different findings. `escalation-flagger` routes one finding at a time. Without a reconciliation step, the Deputy GC sees the memo and the other four approvers never do.

Before producing the summary, read the upstream review memo and tally escalations:

1. **Count the escalation targets the review named.** Look for the routing / escalation block at the end of the review, or for per-finding "escalate to [X]" tags. De-dupe by approver name — a reviewer named for two findings counts once.
2. **Count the escalations actually routed.** Read the review folder (or matter folder) for `escalation-*.md` drafts produced by `escalation-flagger` since the review was written. Each draft names one approver.
3. **Reconcile.** If N approvers were named and M drafts exist, (N − M) escalations have not been routed.

Include a short reconciliation block in the summary — above the checklist, below the catch paragraph:

```markdown
**Escalation status:** [M] of [N] escalation targets routed. The following have not been routed and require action:
- [Approver name] — [one line on the finding that named them]
- [Approver name] — [one line]
```

If all N have been routed:
```markdown
**Escalation status:** [N] of [N] escalation targets routed.
```

If the upstream review surfaced no escalations, omit the block.

**Do not omit a named approver from the reconciliation because the stakeholder wouldn't recognize the name.** Business stakeholders often do not know who the Privacy Officer or CISO is. The reconciliation is internal-facing — it tells the lawyer sending the summary whether all the routing is done, not the stakeholder. If the stakeholder-facing summary needs to stay narrow, the reconciliation can live in a "routing status" footer or attached note — but it has to exist. A summary that implies routing is complete when it is not is worse than no summary.

**Word-count carve-out.** The escalation reconciliation block is exempt from the 200-word cap. Length-cap discipline on the summary body stays; the reconciliation is housekeeping, not narrative.

**When no escalation-flagger drafts exist.** If the upstream review named approvers and no drafts are in the folder, treat the count as M = 0. The reconciliation block lists all N as unrouted. That is the finding.

## A note on tone

Stakeholders remember two things about legal: did it block me, and did it make sense. This skill is how legal makes sense. Write like you're explaining it to a smart colleague over coffee, not like you're writing a memo to file.

If the honest summary is "this is fine, sign it," say that. Don't pad a clean review into three paragraphs to look thorough.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/vendor-agreement-review', 'legal', 'vendor-agreement-review', '', 'vendor-agreement-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Vendor Agreement Review

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

Read a vendor agreement against the playbook this team actually uses (in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`), find every term that deviates, and tell the lawyer what to do about each one — with specific redline language, not vague "consider revising."

The output is a review memo the lawyer can act on in one pass. Every issue has a severity, a business-impact explanation, a proposed fix, and an escalation call if one is needed.

## Precondition: load the playbook

**Before reading the contract, read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.** If it's missing or still has placeholders, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor playbook positions, escalation, and house style to your practice.
>
> **Two choices:**
> - Run `/commercial-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll review tailored to YOUR playbook.
> - Say **"provisional"** and I'll review against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook (flag all common vendor-contract risks from first principles) — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run the review normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no playbook (flag the common vendor-side risks from first principles — unlimited liability, no data-breach carveout, uncapped indemnity, auto-renewal without notice, etc. — rather than matching to configured positions). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/commercial-legal:cold-start-interview` to get output calibrated to YOUR practice — your playbook, your jurisdiction, your risk appetite. 2 minutes."

**Which side?** Before applying the playbook, determine which side the company is on for this contract. Usually obvious: if the counterparty is a vendor/supplier providing goods or services, you're purchasing-side. If the counterparty is a customer buying your product/service, you're sales-side. If it's not obvious (a reseller agreement, a partnership, a revenue share), ask: "Which side is [company] on for this agreement — vendor or customer?" Read the matching playbook section (`### Sales-side playbook` or `### Purchasing-side playbook`) from the config. Note which side in the output so the reviewer knows which playbook was applied. If the matching side is `[Not configured]`, stop and tell the user to run `/commercial-legal:cold-start-interview --side <side>` before this review can proceed.

This skill is typically used for purchasing-side contracts (vendors supplying you), but the side check still applies — a "vendor agreement" could be your own template sent to a vendor as part of a reseller arrangement (sales-side).

The playbook in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` is the source of truth. It tells you:
- What this team's standard positions are (not market standard — *their* standard)
- What fallbacks they've accepted before
- What they never accept
- Who approves what
- The one deal-breaker to check first

If the contract has the deal-breaker, flag it at the top of the memo and stop the detailed review. There's no point spending 30 minutes on liability caps if the agreement gives the vendor rights to use customer data for training.

## Workflow

### Step 1: Orient

Read the whole agreement once, fast. Answer:

| Question | Answer |
|---|---|
| What kind of agreement is this? | MSA / SaaS subscription / Professional services / License / Other |
| Who are we? | Customer / Vendor (this plugin assumes customer — flag if not) |
| Counterparty | Name, and are they a BigCo (won't negotiate) or a startup (will)? |
| Dollar value | Annual / total contract value if stated |
| Term | Length, renewal mechanics |
| Is there a DPA? | Attached / referenced by URL / missing |
| Is there an order form? | Separate doc or integrated |

**Dollar-value handling.** If the main agreement does not state a dollar value (the MSA sets terms but the Order Form carries price, which is typical), **stop and ask** before running escalation math or applying dollar thresholds:

> The MSA itself doesn't state an annual contract value. The Order Form carries the price. Your escalation threshold is $[X from the matrix]. Before I route this, I need the ACV. Options:
> 1. Paste the Order Form value (preferred — I'll use it for routing and the memo).
> 2. Tell me if this is above or below $[threshold] and I'll route accordingly; the memo will flag that the routing assumed [above/below threshold] without an ACV in hand.
> 3. Route conservatively to the higher approver regardless — safer for a review you haven't priced.

Do NOT silently assume a value and then use the assumed value to drive routing. The assumption propagates into the approval call, which is a place the review shouldn't be guessing.

**DPA-by-reference handling.** If the main agreement incorporates a DPA "available at [URL]" or "as set forth at [URL]" or similar by reference, the DPA is part of the contract but is not in front of you. Note it explicitly in the Orient table and in the review memo:

> This agreement incorporates a DPA by URL reference at `[URL]`. The DPA carries the real data terms — subprocessor rights, breach-notification timing, data-return mechanics, standard contractual clauses, audit rights. Without reading it, the data-protection analysis below is partial. Offer to route the DPA to `/privacy-legal:dpa-review` (if installed) for a separate review, or fetch and read it inline before completing Step 3's data-protection analysis.

If the user is installed with `privacy-legal`, explicitly offer:

> Want me to hand the DPA URL to `/privacy-legal:dpa-review` once you're ready? That skill is built for the DPA work and will catch subprocessor / SCC / breach-notification issues that this skill only flags at the gate.

Do not silently proceed as if the DPA were absent when it is incorporated by reference. A missing DPA and an unread DPA are different gaps — label them differently.

### Step 2: Deal-breaker check

Check the "one thing" from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` first. If present:

```markdown
## ⛔ DEAL-BREAKER PRESENT

**Section [X.X]** contains [the deal-breaker]. Per the team playbook, this is a
hard no. Recommend:

- [ ] Push back — propose [specific alternative language]
- [ ] Walk — if counterparty won't move, we don't sign

Detailed review below is provided for completeness but is moot unless this is
resolved.
```

### Step 3: Term-by-term comparison

For each playbook category in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, find the corresponding contract section and compare.

**For each deviation, produce:**

```markdown
### [Section X.X]: [Issue name]

**Playbook says:** [our standard position, quoted from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`]

**Contract says:**
> "[exact quote from the contract]"

**Gap:** [Missing term | Weaker than standard | Weaker than fallback | Non-standard structure | Unacceptable]

**Legal risk:** 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low
**Business friction:** 🔴 Blocks deals | 🟠 Slows deals | 🟡 Confuses customers | 🟢 Invisible

**Why it matters:** [one or two sentences in plain English — what goes wrong
for the business if this term stays as-is]

**Proposed redline:**
> "[the specific replacement language — ready to paste into a markup]"

**If they won't move:** [the fallback from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, or "escalate to [person]"
if no fallback exists]
```

**Severity calibration:**

| Level | Means |
|---|---|
| 🔴 Critical | Don't sign without fixing. A term on the team's "never accept" list in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`, or a deal-breaker. |
| 🟠 High | Strongly push; escalate if they won't move. A term outside the playbook's stated fallback range. |
| 🟡 Medium | Push in first round; accept if it's the last open item. A term inside the fallback range but short of the standard position. |
| 🟢 Low | Note it, don't spend capital. A term the playbook explicitly tolerates, or a purely stylistic deviation. |

Severity is always applied *against `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`*. If a term doesn't map cleanly to a playbook position, ask the user which bucket it belongs in and offer to record the answer in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`.

#### Liability cap decision procedure

**The cap amount is the least important part of the cap.** When reviewing the limitation-of-liability clause, do not produce a single "check liability cap against playbook" line item. Work through the four dimensions below and state each one explicitly in the finding:

1. **Direct vs. indirect/consequential damages.** Does the cap apply to ALL liability, or only direct damages? A 12-month cap on direct damages with uncapped consequential damages is a completely different position than a 12-month aggregate cap. State both treatments explicitly.

2. **The cap base — quote it verbatim.** "12-month cap" could mean: (a) fees paid in the 12 months preceding the claim, (b) fees payable in the current 12-month period, (c) fees over the last 12 months of usage, (d) fees under the current order form, (e) total fees ever paid. These can differ by an order of magnitude. Quote the exact language. If ambiguous, flag it: "Cap base is ambiguous — `[the quoted language]` — could mean [X] or [Y]. Confirm before signing."

3. **Cap-carveout interaction.** A $100K cap with uncapped indemnity for data breach, IP, and confidentiality is functionally uncapped for the claims that actually arise in SaaS disputes. Enumerate what sits ABOVE the cap (the carveouts), what sits BELOW (what's actually capped), and assess whether the capped surface is meaningful: "The cap covers [general contract breach]. Data breach, IP indemnity, and confidentiality are carved out and uncapped. For this vendor's risk profile, the capped surface is [meaningful / nominal]."

4. **Your playbook position per dimension.** The practice profile should have positions for: direct cap (multiple of fees), indirect damages (excluded / capped / uncapped), carveout list (what's acceptable above the cap), and cap base (which definition you'll accept). If the playbook has one "standard position" field, note: "Your playbook has a single cap position — consider splitting into direct/indirect/carveouts/base for more precise review."

#### Jurisdiction delta check

**The playbook applies one governing-law preference globally. Enforceability varies materially.** Check the contract's actual governing law against the top divergences before accepting playbook positions at face value:

- **Non-solicits/non-competes:** Unenforceable in CA (Bus. & Prof. Code §16600). Restricted in many EU jurisdictions. Enforceable with limitations elsewhere. `[jurisdiction — verify]`
- **Auto-renewal:** CA GBL §17600-17606, NY GBL §527-a, IL 815 ILCS 601 have specific consumer/B2B notice requirements. Other states vary. `[jurisdiction — verify]`
- **Liability exclusions:** EU and UK unfair contract terms rules (UCTA 1977, Consumer Rights Act 2015) constrain consumer exclusions. Some US states limit exclusion of gross negligence or willful misconduct. `[jurisdiction — verify]`
- **Indemnification:** Some states void indemnification for the indemnitee's own negligence. `[jurisdiction — verify]`
- **Confidentiality term:** Some jurisdictions limit "perpetual" confidentiality to a reasonable period. `[jurisdiction — verify]`

When the playbook position conflicts with the contract's governing-law enforceability, flag: "Your playbook prefers [X], but this contract is governed by [Y] law where [X] is [unenforceable / restricted / subject to statutory override]. `[jurisdiction — verify]`"

### Step 4: Favorable terms and gaps

Two short lists:

**Better than our standard:** Terms where the vendor gave us more than we'd ask for. Note these — they're trade bait if you need to give something up elsewhere.

**Missing entirely:** Standard provisions that just aren't there. Most common: assignment restrictions, audit rights (if we want them), force majeure, insurance requirements.

### Step 5: Escalation routing

Check the escalation matrix in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` against:
- Contract dollar value
- Presence of any 🔴 critical issues
- Any automatic-escalation triggers (unlimited liability, IP assignment, etc.)

State clearly who needs to approve this:

```markdown
## Approval routing

Based on [dollar value / issue severity], this agreement requires:

- [ ] **[Name/role]** approval — [reason]
- [ ] **Business owner sign-off** on [specific commercial term they should weigh in on]

**Recommended next step:** [Send redlines to counterparty | Escalate to GC before
responding | Get business input on commercial term X before legal responds]
```

**Before proceeding to send redlines to the counterparty:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Sending redlines is a legal act — the counterparty will treat every edit as our negotiating position. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, agreement type, the specific redlines proposed, the playbook positions behind each, the fallbacks, and what to ask the attorney before the package leaves.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not proceed past this gate without an explicit yes.

## Redline granularity

**Edit at the smallest possible granularity.** A redline is a negotiation artifact, not a rewrite. Wholesale clause replacement signals "we threw out your drafting" — it's aggressive, it forces the counterparty to re-read the whole clause, and it discards the parts of their drafting that were fine. Surgical redlines — strike a word, insert a phrase, restructure a subclause — signal "we have specific asks" and are faster to read, understand, and accept.

Default to the smallest edit that achieves the playbook position:
- Replace a **word** before a phrase. ("twelve (12)" → "twenty-four (24)")
- Replace a **phrase** before a sentence. ("paid by the Buyer" → "paid and payable by the Buyer")
- Restructure a **subclause** before replacing the sentence. (Add "(a)" and "(b)" to split a compound condition.)
- Replace a **sentence** before replacing the clause.
- Only replace a **whole clause** when the counterparty's version is so far from your position that surgical edits would be harder to read than a fresh draft — and when you do, say so in the transmittal: "We've replaced §8.2 rather than marking it up because the changes were extensive. Happy to walk you through the delta."

When in doubt, smaller. A client who receives a surgical redline trusts that you read carefully. A client who receives a wholesale replacement wonders whether you read at all.

### Step 6: Assemble the memo

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

This memo and the underlying agreement may be privileged, confidential, or both. The output inherits that status from the source. Distribute only within the privilege circle; mark and store it where privileged materials live; strip the work-product header before any external delivery (e.g., counterparty redlines, stakeholder summaries).

The playbook positions applied below reflect the jurisdiction recorded in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `Governing law and venue`. Legal rules and enforceability vary materially by jurisdiction. If this deal implicates a different governing law or a choice-of-law question, flag it in the memo — the analysis may not transfer as written.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a rule the memo needs (enforceability of a limitation clause, indemnity scope, governing-law choice), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / jurisdiction]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Where the memo cites a statute, regulation, or case, tag the citation: `[Westlaw]`, `[statute / regulator site]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations from the counterparty draft or house files. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# Vendor Agreement Review: [Counterparty] [Agreement Type]

**Reviewed:** [date]
**Contract value:** $[amount] / [term]
**Our role:** Customer

---

## Bottom line

[Two sentences. Can we sign this? What has to change first?]

**Issues (legal risk):** [N]🔴 [N]🟠 [N]🟡 [N]🟢
**Issues (business friction):** [N]🔴 [N]🟠 [N]🟡 [N]🟢

**Approval needed from:** [name]

---

## Deal-breaker check

[✅ Clear | ⛔ Present — see above]

---

## Issues by severity

[All the deviation blocks from Step 3, grouped Critical → Low]

---

## Favorable terms

[list]

## Missing provisions

[list]

---

## Approval routing

[from Step 5]

---

## Redline package

[If requested: consolidated markup-ready language for all proposed changes]
```

## Integration: [CLM]

If a [CLM] MCP is connected, after the review:

- Check if this counterparty already has agreements with us (may inform negotiating posture — "we already gave them 24-month cap on the last deal")
- Pull the workflow template that matches this agreement type
- Offer to create the [CLM] record with the review memo attached and approvers pre-routed

## Integration: DocuSign

If DocuSign MCP is connected and the agreement is ready to sign (all greens or all issues accepted), offer to:
- Generate the envelope
- Route to signers in the right order per the escalation matrix

Do **not** send anything for signature without explicit instruction. "Ready to sign" is the lawyer's call, not yours.

**Before generating a signature envelope or routing for countersignature:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If the Role is Non-lawyer:

> This step has legal consequences (signing binds the company to the whole agreement). Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, contract value, the issues found and how they resolved, any risk the lawyer accepted, and what to ask the attorney before envelope goes out.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not proceed past this gate without an explicit yes.

## Output formats

**Full memo (default):** As above. Goes in the [CLM] record or the Drive folder from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` house-style section.

**Slack-sized summary:** Two lines and a link. For when someone asks "is this okay?" in a channel.

```
[Counterparty] [type] — NEEDS WORK. 1🔴 (uncapped liability §8.2), 2🟠. Full review: [link]. Needs [GC] approval.
```

**Redline doc:** If the user asks for it, output a .docx with tracked changes. Use the docx skill. Comments on each change cite the playbook position.

## Quality checks before delivering

- [ ] `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` was loaded and quoted — not generic market positions
- [ ] Deal-breaker checked first
- [ ] Every issue has specific replacement language
- [ ] Risk levels are calibrated (not everything is Critical)
- [ ] Approver is named, not "escalate to legal"
- [ ] Counterparty context considered (BigCo vs. startup — affects what's worth fighting over)

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$)
ON CONFLICT (skill_key) DO NOTHING;
