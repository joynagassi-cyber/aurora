INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/oc-status', 'legal', 'oc-status', '', 'oc-status', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /oc-status

To run weekly, set a recurring reminder to invoke `/litigation-legal:oc-status`. Automated scheduling requires a scheduled-tasks integration, which is not bundled.

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`, filter per default rules (or per flags).
2. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → outside counsel directive style, signer defaults, budget posture.
3. Follow the workflow and reference below.
4. For each matter in scope: read `matter.md` + `history.md`, draft per-matter email.
5. Write markdown to `~/.claude/plugins/config/claude-for-legal/litigation-legal/oc-status/[YYYY-MM-DD]/[slug].md`.
6. If Gmail MCP authenticated: create Gmail drafts. Else: markdown-only, note in summary.
7. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/oc-status/[YYYY-MM-DD]/_summary.md` — what ran, what was skipped and why.

---

# OC Status

## Purpose

Writing the same status-request email to outside counsel every week across 5–15 matters is mechanical cognitive tax. The content is consistent per matter (status, decisions pending, budget check). The audience is consistent (OC lead partner). The tone is consistent (per house outside-counsel-directive style). A scheduled task drafts all of them; counsel reviews and sends.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — the filtering and field source
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — matter context (current posture, open questions)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` — recent events to inform what to ask about
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → outside counsel directive style, signer name/email, budget posture

## Filtering — which matters?

Default filter:

- `status != closed`
- `outside_counsel.firm != null` AND `outside_counsel.lead != null`
- Either: last update more than 10 days old (time for something to have happened) OR has a `next_deadline` within 21 days

Skip matters that just had a status update in the last 10 days (no need to re-ping) and matters where `outside_counsel.email` is null (email addresses needed for Gmail draft; still produce markdown).

Flags:
- `--all` → draft for every active matter regardless of recency
- `--slug=[slug]` → draft for one matter only (ad-hoc request)
- `--no-gmail` → skip Gmail draft creation even if MCP is available

## Per-matter email draft

Each email has the same skeleton; content is matter-specific.

**Subject:** per house convention (from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` outside counsel directive style; fallback: `[Matter: [matter name]] — Weekly status update`)

**Body skeleton:**

```
[lead partner first name],

[One sentence opener — natural, matches house tone.]

Checking in on [matter name]. A few items:

1. **Status since [date of last update captured in history.md]** — what's moved, what's pending? Any filings, hearings, correspondence, or calls since we last touched base?

2. **Upcoming deadlines** — I show [next_deadline from log + any deadlines in matter.md]. Confirm coverage plan and any dates we should add.

3. **Decisions pending** — [pull open questions from matter.md that require OC input; if none, omit this numbered item and renumber]

4. **Budget** — [monthly / quarterly / on-request per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` budget posture]. Where are we against [budget authorization from matter.md]? Any variance to flag?

[If material and relevant: 5. Specific ask — e.g., "Please send me the latest draft of the motion to dismiss before [date]" — drawn from matter.md open questions.]

[Signoff — name, role, contact. From `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` signer default for OC directives.]
```

Adapt tone per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` outside counsel directive style — some shops are "dear counsel" formal; others are first-name-and-bullets. Match.

## Output

### Markdown drafts

Write to: `~/.claude/plugins/config/claude-for-legal/litigation-legal/oc-status/[YYYY-MM-DD]/[slug].md`

Each file is one email, formatted as:

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# [Matter name] — OC status request — [YYYY-MM-DD]

**To:** [outside_counsel.email from log] ([outside_counsel.lead], [outside_counsel.firm])
**From:** [signer name / email from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`]
**Subject:** [subject line]

> The work-product header above applies to this internal record. The outgoing email body below goes to outside counsel on a retained matter, which is itself a privileged communication — apply the house privilege marking (`~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` privilege conventions) at the top of the email sent, typically `Privileged & Confidential — Attorney-Client Communication / Attorney Work Product`, not this internal work-product header.

---

[body per skeleton]
```

### Send gate (closing note on every draft)

Append the following to each markdown draft, immediately below the body and above the run metadata — strip before sending:

> This is a draft status email for attorney review before sending to outside counsel. Check for privileged content you did not intend to share outside the engagement circle, factual accuracy, tone, and budget posture. Do not send unreviewed — even routine weekly check-ins can surface theory, strategy, or concessions the sender didn't mean to put in writing.

### Gmail drafts (if MCP available)

If the Gmail draft-creation MCP is authenticated:

- Create a draft in the user's Gmail per matter with `to`, `from`, `subject`, `body` populated
- The draft sits in Drafts folder; user reviews and sends Monday morning
- If Gmail MCP is NOT available or fails: fall back to markdown-only and tell the user

### Run summary

After processing all matters, write `~/.claude/plugins/config/claude-for-legal/litigation-legal/oc-status/[YYYY-MM-DD]/_summary.md`:

```markdown
# OC Status Run — [YYYY-MM-DD]

**Matters processed:** [N]
**Drafts created:** [N]
**Gmail drafts:** [created / skipped — reason]

## Drafted for

| Matter | OC lead | Last updated | Reason for inclusion |
|---|---|---|---|
| [slug] | [lead] | [date] | [stale / upcoming deadline / --all / --slug] |

## Skipped

| Matter | Reason |
|---|---|
| [slug] | recent update (last touched [date]) |
| [slug] | no OC email in log — update with `/matter-update [slug]` |

## Anomalies

- Matters without outside counsel assigned: [list — if any are high/critical risk, flagged]
- Matters with outside counsel but no email in log: [list]
```

## Scheduling

This skill is designed to run weekly. Automated scheduling requires a scheduled-tasks integration that is not bundled with the plugin. To run weekly, set a recurring reminder to invoke `/litigation-legal:oc-status` — e.g., Monday morning on your calendar.

Ad-hoc: `/oc-status` any time. `/oc-status --slug=foo` for a single matter.

## What this skill does not do

- **Send the emails.** Drafts only. Counsel reviews and sends.
- **Generate content it doesn't have.** If `matter.md` is thin, the email is short and asks broad-status questions. The skill doesn't invent specific questions from nothing.
- **Retry failures.** If Gmail draft creation fails mid-run, the skill logs the failure and continues with markdown. User can retry after fixing auth.
- **Rewrite history.md.** Reads it for context; doesn't modify. (If OC's response surfaces new events, use `/matter-update [slug]` to log them.)
- **Enforce a minimum template.** If the house tone is "one line, first name, done," the draft honors that and skips the bulleted structure. Match `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/portfolio-status', 'legal', 'portfolio-status', '', 'portfolio-status', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /portfolio-status

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → risk calibration (defines how to read the `risk:` field).
2. Follow the workflow and reference below.
3. Parse `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`. Filter closed matters by default (include with `--all`).
4. Produce rollup: risk distribution, deadlines in next 14/30/60 days, matters with no update in >30 days, materiality totals, stage distribution.
5. Flag anomalies — everything marked critical, overdue next_deadline, matters without outside counsel assigned where risk is medium or high.

---

# Portfolio Status

## Purpose

One read that answers: what do I own right now, what needs attention, and what's slipping? Output is scannable — designed for a counsel who has three minutes before their next call.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — source of truth
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — risk calibration (to interpret risk/materiality fields correctly)

## Flags & filters

Default: active matters only (exclude `status: closed`).

Flags:
- `--all` — include closed
- `--risk=high` (or `critical` / `medium` / `low`) — filter by risk band
- `--stale` — only matters with `last_updated` > 30 days
- `--type=employment` — filter by matter type
- `--owner=[name]` — filter by business/HR/comms owner

## The rollup

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Portfolio Status — [today]

**Active matters:** [N]
**Closed (ytd):** [N] *(shown only with --all)*

---

## By risk

| Risk | Count | Matters |
|---|---|---|
| Critical | [N] | [slugs] |
| High | [N] | [slugs] |
| Medium | [N] | [count only — expand with `--risk=medium`] |
| Low | [N] | [count only] |

## Upcoming deadlines

| Within | Matters |
|---|---|
| 14 days | [slug — deadline — brief] |
| 15–30 days | [...] |
| 31–60 days | [...] |

*Overdue `next_deadline` flagged separately below.*

## Materiality

| Category | Count | Total exposure (midpoint) |
|---|---|---|
| Reserved | [N] | [$X] |
| Disclosed | [N] | [$X] |
| Monitored | [N] | — |
| None | [N] | — |

## By stage

[table: pleadings / discovery / dispositive motions / trial prep / settlement / appeal]

---

## ⚠️ Anomalies & flags

- **Overdue deadlines:** [list slugs where next_deadline has passed]
- **Stale (>30d no update):** [list]
- **Conflicts unresolved:** [list slugs with `conflicts.status in [pending, not-run]`]
- **Conflicts bypassed (override active):** [list slugs where `conflicts.override.by` is populated — permanent flag until manually cleared]
- **High/critical risk without outside counsel:** [list]
- **Reserved without last_updated in >60d:** [list] — reserve recalibration likely overdue
- **Hold not issued on active litigation:** [list]
- **Missing fields:** [slug → field]

---

## Closing advice

[One or two sentences on what to look at first, if anything stands out. Not boilerplate — only if something truly stands out.]
```

## Anomaly rules

These are the checks that make the skill useful rather than decorative:

1. **Overdue deadline:** `next_deadline < today` and `status != closed`
2. **Stale:** `last_updated < today - 30d` and `status != closed`
3. **Conflicts unresolved:** `conflicts.status in [pending, not-run]` and `status != closed`
3b. **Conflicts override active:** `conflicts.override.by != null` (never auto-clears)
4. **High-risk uncovered:** `risk in [high, critical]` and `outside_counsel.firm == null`
5. **Stale reserve:** `materiality == reserved` and `last_updated < today - 60d`
6. **Hold gap:** `status in [threatened, active, discovery, trial, appeal]` and `legal_hold.issued == false` — preservation duty attaches at reasonable anticipation, so `threatened` matters are in scope.
7. **Missing fields:** any required field null — `risk`, `materiality`, `status`, `opened`, `conflicts.status`

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

If the portfolio has more than ~10 matters, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by risk tier, a timeline of upcoming deadlines, and a sortable matter ledger with status, conflicts check, and last-touched date.

## What this skill does not do

- Make decisions. It surfaces what needs attention; the user decides priority.
- Pretend precision it doesn't have. Exposure midpoints are rough and should be labeled so.
- Replace a real MMS. This is a working-memory rollup, not a system of record.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/privilege-log-review', 'legal', 'privilege-log-review', '', 'privilege-log-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /privilege-log-review

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → review protocol, priv log format.
2. Follow the workflow and reference below.
3. For each entry: obvious priv / obvious not priv / needs attorney review. Flag reasons.
4. Output: reviewed log with flags. Attorney reviews all flags before production.

---

# Privilege Log Review

## Disclosed-document use restrictions

Before working with a set of litigation documents, ask: "Were any of these documents obtained through disclosure or discovery in legal proceedings?" If yes:

- **England & Wales (CPR 31.22):** Documents obtained through disclosure are subject to the implied undertaking — you may only use them for the purpose of the proceedings in which they were disclosed, unless the court grants permission, the disclosing party consents, or the document has been read in open court. Using them for a different matter, a different claim, or a commercial purpose without permission is a contempt.
- **US:** Protective orders and Rule 26(c) may impose similar restrictions. Check the order.
- **Other jurisdictions:** Similar restrictions commonly apply. Check the local rule.

Confirm: "This use is within the proceedings in which the documents were disclosed, or I have permission / consent, or the documents are now public." If not confirmed, flag it: "⚠️ Disclosed documents may have use restrictions. Confirm this use is permitted before proceeding."

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. For litigation-legal the default is `Enabled: ✓` — every case gets its own matter workspace. If `Enabled` is `✗` (you turned it off because you work one case at a time), skip the rest of this paragraph and use practice-level context. If enabled and there is no active matter, ask: "Which matter is this for? Run `/litigation-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

A privilege log has three kinds of entries: obviously privileged, obviously not, and the ones that need thought. This skill sorts the first two kinds so the attorney's time goes entirely to the third.

**This is first pass. Attorney reviews every flag. No exceptions.**

## Record fidelity — pinpoints and citation coverage

When this skill cites a rule, local variant, or authority for a privilege call (FRCP 26(b)(5)(A), state rule, local rule, case on waiver scope, case on dominant purpose), two rules apply.

**Pinpoint cites must support the whole proposition.** If the review cites one rule or case to support a multi-part proposition — "the log must describe each document and withhold only materials prepared in anticipation of litigation" — verify the pinpoint covers every element. If it only covers one, split the cite or narrow the proposition. A cite that backs part of a privilege position gets the position rejected when opposing counsel reads the cite and points out it doesn't reach the contested element. This is the "misgrounded citation" failure mode: the cite exists, the passage exists, but it doesn't support the proposition as stated.

**Extract all citations before checking any.** When this review cites authority — or when a separate citation-check is requested on the log, a related brief, or the supporting motion:

1. **First pass: extract.** Read the document and build a list of every citation (rules, cases, statutes, local orders, record cites). Report the count: "Found [N] citations."
2. **Second pass: check.** Check each against the source. Don't sample. Don't stop at the first five.
3. **Report coverage.** "Checked [N] of [M] citations. [K] could not be retrieved — verify manually. [J] confirmed. [I] flagged as potential miscitations. [H] flagged as misgrounded (cite exists but doesn't support the proposition)."
4. **When source text is unavailable, say "could not check," never "confirmed."** A false positive is worse than a "couldn't check" — it lets a bad cite through.
5. **The hardest errors are partial support.** Read the proposition, read the source, compare element by element.

## Load context

`~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → privilege log format, review protocol.

**Conflicts gate — unbypassable.** Before reviewing a privilege log, check `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't review a privilege log on a matter that hasn't been intaken — the conflicts check is the gate, and a privilege log review is work product that needs to live in the matter file."

**Jurisdiction matters.** Privilege scope (A/C and work product), waiver doctrine, and log-form requirements vary materially across federal circuits and state courts. This review applies the rules for the forum specified in config. If the matter involves a different forum, a transferred case, multi-jurisdictional production, or a choice-of-law question on privilege, the calls here may not transfer — re-run against the controlling forum.

## Step 0: Research the forum's privilege-log rules

**Before reviewing entries, research the forum's privilege-log requirements (FRCP 26(b)(5)(A) or state equivalent), any local rule variant, and the judge's standing orders. Identify the required fields, the level of description, and any category-log or metadata-log accommodations. Cite primary sources.**

**No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for the forum's rule, waiver doctrine, or local variant, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / doctrine]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave the `[UNCERTAIN]` marker and stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every rule reference and authority in the review output with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the reviewing attorney supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags — they are the reviewing attorney's signal about which authorities to re-confirm before service.

**Waiver doctrine differs by privilege type:**

- **Attorney-client privilege waiver** is often broad: subject-matter waiver can sweep in related communications on the same topic.
- **Work-product waiver** is narrower: courts typically distinguish opinion work product (stronger protection) from fact work product. Waiver of fact work product doesn't automatically waive opinion work product.

Confirm the forum's waiver doctrine for each privilege claimed before recommending production of anything. `[UNCERTAIN]` flags stay on waiver calls until counsel confirms.

## The calls

**Three-state rule. The skill never silently decides a subjective threshold isn't met.** On any uncertain call — dominant purpose unclear, litigation contemplation borderline, mixed legal/business content, ambiguous third-party presence — the skill keeps the privilege designation on and adds a ⚠️ flag for the attorney. Under-marking waives privilege (one-way door); over-marking is corrected by the attorney in review (two-way door). Prefer the recoverable error.

**In-house counsel privilege is jurisdiction-specific and contested.** Before classifying any communication with in-house counsel as privileged, check the jurisdiction:

- **US:** In-house counsel communications are generally privileged when made for the purpose of obtaining or providing legal advice, and the attorney is acting in a legal (not business) capacity. The legal-vs-business distinction is fact-specific and contested.
- **EU (competition / DG COMP proceedings):** Under *Akzo Nobel Chemicals v. Commission* (C-550/07 P), communications with in-house counsel are NOT privileged in EU competition proceedings. The CJEU held privilege applies only to communications with independent external lawyers. If the matter involves EU competition or state aid, in-house counsel documents are compellable.
- **Germany (Syndikusanwalt):** The German Syndikusanwalt has a hybrid status. Privilege depends on the capacity in which the lawyer was acting and whether the communication is in the "advocate" or "employee" role. Post-2016 registration rules changed the analysis.
- **UK:** In-house counsel privilege generally recognized, but the "dominant purpose" test applies, and the legal-vs-commercial advice distinction is scrutinized.
- **France, Belgium, some other EU:** In-house lawyers may not be members of the bar, and their communications may have no privilege at all.

**Never classify an in-house counsel communication as "confidently privileged" without stating which privilege regime applies.** If the matter involves non-US jurisdictions, especially EU competition or any EU regulator: "Documents from in-house counsel may have NO privilege in [jurisdiction]. Under *Akzo Nobel*, in-house communications are compellable in EU competition proceedings. Flag for review by a [jurisdiction] litigation specialist before asserting privilege."

The ✅ "confidently privileged, no flag" tier below is the one designed to bypass attorney review. That's exactly where the *Akzo Nobel* risk lives. When the jurisdiction is non-US or the matter touches EU regulators, there is no ✅ tier for in-house communications — everything goes to 🟡 "flag for attorney review with jurisdiction note."

### Confidently privileged (✅) — keep designation, no flag

- Communication between client and outside counsel seeking/providing legal advice, no third parties copied
- Communication between client and in-house counsel, clearly legal (not business) advice, no third parties
- Work product created in anticipation of litigation, by or for counsel
- Communications within the control group about legal strategy

### Uncertain — keep designation AND flag (✅ + ⚠️)

The default for anything that isn't confidently in ✅ or ❌. The skill does not withhold a privilege designation on its own assessment of a subjective test. Examples:

- **In-house counsel doing both legal and business** — was this communication legal advice or business advice? The dominant-purpose call is the attorney's, not the skill's.
- **Third party present** — is the third party within the privilege (common interest, agent) or does their presence waive? Keep the designation; flag for attorney.
- **Mixed purpose documents** — part legal, part business. Partial redaction? Full withhold? Produce? Keep the designation; flag for attorney to decide the treatment.
- **Attachments** — analyze separately and keep each attachment's designation unless confidently ❌; flag the ones where privilege turns on a subjective call.
- **Pre-litigation work product** — "reasonable contemplation of litigation" is fact-specific; keep the designation; flag.
- **Waiver risk** — later-share history is ambiguous; keep the designation; flag the waiver question.

Each flag records the specific open question and the evidence cutting each way, so the attorney can decide without re-reading the document cold.

### Confidently not privileged (❌) — recommend remove, but note the assessment

Only for the unambiguous cases. The output still records the assessment rationale so the attorney can spot-check; it does not remove the designation from the log on its own.

- No attorney involved anywhere
- Business advice with a lawyer CC'd (CC'ing legal doesn't make it privileged)
- Underlying facts (facts aren't privileged — communications *about* facts can be)
- Third party copied who's clearly outside privilege (breaks confidentiality)
- Attachments that are independently non-privileged (the email might be privileged; the attached spreadsheet of sales numbers is not)

If any of these is *close* — the third party might be an agent, the lawyer's CC might actually be on a legal request — it's uncertain, not ❌. Route it to the uncertain bucket and flag.

## Workflow

### Step 1: Format check

Does the log have what it needs?

| Field | Present? |
|---|---|
| Date | |
| Author | |
| Recipients (all — TO, CC, BCC) | |
| Document type | |
| Privilege claimed (A/C, WP, both) | |
| Description (enough to assess without revealing privileged content) | |

Missing fields → flag for completion before substantive review.

### Step 2: Entry-by-entry

For each entry:

```
Entry [N] ([Bates]): [✅ Priv | ✅ Priv + ⚠️ Flag | ❌ Not priv (assessed)]
[If ✅ (no flag): one-line reason]
[If ✅ + ⚠️: keep designation; the specific question the attorney needs to answer; evidence cutting each way]
[If ❌: one-line reason — but the designation stays on the log until the attorney removes it]
```

**Never produce an entry that silently strips a privilege designation based on the skill's own subjective call.** A ❌ is a recommendation logged alongside the flag; the attorney acts on it.

### Step 3: Pattern flags

Across the log:

- Same issue repeating? (E.g., same third party on 50 entries — one decision resolves 50 flags)
- Over-designation pattern? (If everything's designated without differentiation, surface it for the attorney — but the call to narrow the log is the attorney's, not the skill's. Under-designation waives; over-designation is correctable.)
- Under-description? (Descriptions so vague a court would order in camera review)

## Output

**Before the privilege log is served on the opposing party (the consequential act — this includes serving the log AND designating documents withheld or produced under a protective-order designation such as Confidential / Highly Confidential / AEO):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Submitting a privilege log and designating documents in discovery both have legal consequences — over-designation risks sanctions and loss of credibility; under-designation risks waiver; a misdesignated production may be unrecallable. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the matter, log entry counts, the ⚠️ flags and close calls, pattern observations (over-designation, vague descriptions), waiver-doctrine posture by privilege type, what could go wrong on service or designation, what to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not treat the log as service-ready without an explicit yes. First-pass review, sorting, and flagging do not require the gate — service and designation do.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Privilege Log Review: [Matter] — [date]

**Applicable rule:** [FRCP 26(b)(5)(A) / state rule / local rule / standing order — pinpoint cites] `[UNCERTAIN — verify currency]`
**Entries reviewed:** [N]
**Results:** [N] ✅ confident priv / [N] ✅+⚠️ priv kept & flagged / [N] ❌ recommend remove (attorney confirms)

### ✅ + ⚠️ Flagged — designation kept, attorney decides

| Entry | Bates | Issue | Evidence for priv | Evidence against | Question |
|---|---|---|---|---|---|
| [N] | [range] | [what's subjective] | [one line] | [one line] | [the specific call to make] |

### ❌ Recommend remove designation (attorney confirms before stripping)

| Entry | Bates | Reason |
|---|---|---|

*Recorded, not executed. The skill does not remove privilege designations from the log — the attorney does, after reviewing the rationale.*

### ✅ Privileged (no action)

[Count. List available on request.]

### Pattern observations

[Repeating issues, over-designation, description problems]

### Marker discipline

- `[VERIFY: factual assertion about document/custodian/date]`
- `[UNCERTAIN: close privilege call / waiver scope / doctrine question]`
- `[CITE NEEDED: rule, local variant, or authority supporting a call]`

---

**Attorney must review all ⚠️ and ❌ before any action.**

**Privileged source material.** This review reads entries and underlying documents that are, by definition, privilege-candidate material. The review output inherits that status — keep it with privileged materials, mark it appropriately, and don't circulate outside the privilege circle. Distributing it can itself waive protection.
```

## What this skill emphatically does not do

- Make close calls. ⚠️ means "a human decides." On any subjective test (dominant purpose, reasonable contemplation, common-interest scope, waiver by later sharing) the skill keeps the privilege designation on and flags.
- Strip a privilege designation from the log based on its own assessment. ❌ is a *recommendation* recorded for the attorney, not an action taken against the log.
- Produce or withhold documents. It advises; attorney decides; attorney acts.
- Guarantee correctness on ✅ calls. The attorney is responsible for the log. This is a first pass.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/subpoena-triage', 'legal', 'subpoena-triage', '', 'subpoena-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /subpoena-triage

1. Read the subpoena from provided path.
2. Classify (third-party-docs / third-party-depo / party / CID / grand-jury).
3. If grand jury → stop, escalate per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. Otherwise continue.
4. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for cross-check. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → landscape, privilege conventions, escalation norms.
5. Follow the workflow and reference below.
6. Extract key fields, analyze scope/burden/privilege, produce objections framework + compliance plan + deadline calendar.
7. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/triage.md`. Copy or link subpoena to `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/incoming.[ext]`.
8. Hand off: `/legal-hold --issue` if hold not in place; `/matter-intake` if materiality warrants; `/matter-briefing [slug]` if party subpoena in existing matter.

---

# Subpoena Triage

## Purpose

Subpoenas arrive with deadlines. The failure modes: missing the deadline, over-producing (privilege waiver, burden we should have objected to), under-producing (contempt exposure), or missing a motion-to-quash window. This skill classifies, analyzes, and produces a compliance plan with objections framework.

## Jurisdiction assumption

The rule cited in Step 0 is the operative one for this subpoena in this forum. Subpoena practice varies materially: federal (FRCP 45) vs. state equivalents, state-to-state variants, local rules, court-specific standing orders, and the subpoena type (trial, deposition, document production) all change objection deadlines, place-of-compliance limits, privilege-log requirements, and cost-shifting. Every rule output here is a starting-point heuristic — confirm currency and the local variant before asserting in writing.

## Side context

This skill is inherently defensive — a subpoena has been served on the recipient and the posture is respond/object/comply. Read `## Side` in the practice profile. If the user's default side is **plaintiff**, note that receiving a subpoena is common for plaintiffs too (witness subpoenas, third-party requests directed at the plaintiff's own records) but the framing here is always "subpoena served on us, how do we respond." If the user is **defense** (typical), the framing aligns with the default. If the matter has a different posture than the default (e.g., defense practitioner receiving a subpoena in a matter where they're pro se for a family member), prompt the user to confirm posture before proceeding.

## Load context

- The subpoena document (user provides path or drops it in-session)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — for related matter lookup and legal hold status
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → landscape (regulators we deal with), house privilege conventions, escalation norms

## Workflow

### Step 0: Research the applicable rule

**Before analyzing this subpoena, research the applicable rule of civil procedure for the forum (FRCP 45 for federal, the state equivalent otherwise) and the subpoena type (trial, deposition, document production). Identify: place-of-compliance limits, objection deadlines (these often run from the EARLIER of the compliance date or a fixed number of days after service), privilege-log requirements, and who bears costs. Cite with pinpoint references. Verify currency — rules and local variants change. Flag grand-jury subpoenas for immediate criminal-counsel escalation.**

**No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for the forum's rule, variant, or pinpoint, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / forum / variant]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every rule reference, case, statute, and regulation in the triage output with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for citations from web search; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the user supplied (e.g., from the subpoena or prior matter work). Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags — they are counsel's fastest signal about which citations to verify before asserting in objections or filings.

### Step 1: Classify

Subpoenas come in flavors with different rules; confirm the specifics against the rule you just researched:

- **Third-party document subpoena (civil)** — we're not a party to the litigation; someone wants our documents. Usual objection categories: relevance, burden, privilege, place-of-compliance / geographic reach.
- **Third-party deposition subpoena** — someone wants an employee to testify. Scope, relevance, burden; possible motion to quash; witness prep required.
- **Party subpoena** — we ARE a party; this is discovery in a litigation we're tracking. Treat as discovery, not inbound — it should map to an existing matter.
- **Regulatory civil investigative demand (CID)** — FTC, SEC, DOJ, state AG. Different rules, different posture; often more deferential but also more consequential.
- **Grand jury subpoena** — criminal. Escalate immediately to criminal counsel; different skill path (outside this skill's scope — flag for escalation).

### Step 2: Extract key fields

- **Issuing authority** — court (which), agency (which), counsel (if civil)
- **Issuing party** — who requested (if civil)
- **Case / matter caption** — the litigation we're being asked about
- **Document categories sought** — numbered list
- **Testimony topics** (if depo) — Rule 30(b)(6) designations
- **Deadline for response/objection** — date served + computing the response window per applicable rule
- **Production date** — date by which documents must be produced
- **Geographic scope** — custodians, locations, systems implicated
- **Custodian of record designation** — who at the company is the witness/signatory

### Step 3: Portfolio cross-check

- **Party subpoena → related to existing matter:** verify the caption matches a matter in `_log.yaml`. If yes, route to that matter's workflow; this triage is informational.
- **Third-party subpoena → caption we don't recognize:** capture the parties; log as standalone inbound.
- **Multiple subpoenas from same case:** flag coordinated issuance; a single response strategy may apply.

### Step 4: Analyze scope, burden, privilege

**Scope / relevance**
- Do the categories map to actual documents we plausibly have?
- Is any category a fishing expedition (overbroad, untethered to claims/defenses of the underlying case)?
- Place of compliance / geographic reach — apply the researched rule; limits differ by subpoena type (trial vs. document vs. deposition).

**Burden**
- Custodians implicated, systems searched, time period
- Estimated volume (rough: small / medium / large / extreme)
- Cost — third-party responders may have cost-shifting available; check the researched rule.

**Privilege**
- Attorney-client or work product likely implicated? (Almost always yes for anything legal-related; often yes for communications involving in-house or outside counsel.)
- Other privileges — trade secret, HIPAA (if applicable), state privilege, common interest
- Privilege log will be required — flag the format per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`

**Other objection grounds**
- Confidentiality — protective order needed?
- Duplicative — do they already have this from another party?
- Not possessed — we don't have what they're asking for (document with specificity)
- Improperly served — check the researched rule's service requirements

### Step 5: Objections framework

Draft a structured objections outline — not the final objections letter, but the outline of what objections apply and why. The user (often with outside counsel) finalizes.

Each objection:
- Legal basis — cite the pinpoint from the rule researched in Step 0
- Specific application to this subpoena (which categories, which custodians)
- Strength (strong / reasonable / weak)

### Step 6: Compliance plan

Even when objecting, we often produce some of what's requested. Plan:

- **Scope of likely production** — after objections, what we'd produce
- **Custodians to search** — names and systems
- **Date range**
- **Review protocol** — who reviews for privilege (us, outside counsel, contract reviewers)
- **Production format** — per the subpoena or per negotiated protocol (TIFF+load file, native, PDF)
- **Privilege log requirements** — format, fields

### Step 7: Deadlines

Use the deadlines identified in the Step 0 research. Note that objection deadlines often run from the EARLIER of the compliance date or a fixed number of days after service — do not default to a single number without checking the applicable rule and local variant.

- **Response deadline** — per researched rule; note if user needs more time (meet-and-confer to extend is standard)
- **Objection deadline** — per researched rule (federal / state rule + any local variant)
- **Production date** — if no objections succeed
- **Motion to quash window** — if pursuing that path, timing is critical

Calendar all of them. Immediate action item.

### Step 8: Write triage

Output: `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/triage.md`.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Subpoena Triage

> **NOT A SUBSTITUTE FOR OUTSIDE COUNSEL.** This is a structured classification and scoping read to support fast decisions on deadlines, holds, and engagement. Every rule reference is a starting-point heuristic; jurisdiction-specific analysis, objections finalization, motions practice, and merit calls on privilege require licensed counsel familiar with the forum. Engage outside counsel for any subpoena above routine third-party document scope.

**Slug:** [slug]
**Served:** [YYYY-MM-DD]
**Served on:** [entity / registered agent]
**Incoming file:** [path]
**Classification:** [third-party-docs / third-party-depo / party / CID / grand-jury]

---

## Key fields

- **Issuing authority:** [court/agency]
- **Issuing party:** [name]
- **Case caption:** [caption]
- **Response deadline:** [date]
- **Production date:** [date]
- **Motion-to-quash window:** [date range]

## Categories sought (summary)

[numbered list, concise]

## Custodians / systems likely implicated

[list]

---

## Portfolio cross-check

**Related matter:** [slug or "none"]
**If party subpoena:** [routed to existing matter or new matter?]
**If third-party:** [standalone inbound]

---

## Scope & burden analysis

**Scope:** [relevance assessment by category]
**Burden estimate:** [small / medium / large / extreme — with reasoning]
**Geographic reach issues:** [any]

## Privilege analysis

*Privilege scoping is a first-pass read; final call is counsel's, not this skill's.*

**Attorney-client / work product likely implicated:** [yes/no + which categories] `[SME VERIFY]`
**Other privileges:** [trade secret, HIPAA, state, common interest] `[SME VERIFY]`
**Privilege log format required:** [per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`]

---

## Objections framework

*Every row below requires `[SME VERIFY]` before asserting in writing — jurisdiction, rule currency, waiver risk.*

| Objection | Legal basis | Applies to | Strength | SME verified? |
|---|---|---|---|---|
| Relevance | [rule] | [categories] | [strong/reasonable/weak] | [ ] |
| Burden | [rule] | [categories] | | [ ] |
| Privilege | A/C, WP | [all producing docs] | strong (always) | [ ] |
| Duplicative | [rule/doctrine] | [if applicable] | | [ ] |
| [other] | | | | [ ] |

---

## Compliance plan (if responding)

- **Scope of likely production:** [after objections]
- **Custodians / systems:** [list]
- **Date range:** [range]
- **Review protocol:** [who, how]
- **Production format:** [format]
- **Privilege log:** [format, est. entries]

---

## Deadlines (calendar these)

*All deadlines below come from the Step 0 rule research. `[SME VERIFY]` confirms the rule, variant, and computation for this forum and this subpoena type — state variants and local rules differ.*

- **Response deadline:** [date] `[SME VERIFY]`
- **Objection deadline:** [date] — cite: [rule + pinpoint] `[SME VERIFY]`
- **Meet-and-confer by:** [date] (typically before objection deadline) `[SME VERIFY]`
- **Production date:** [date]

---

## Immediate actions

- [ ] Legal hold issued — [yes/no] — if no, run `/legal-hold [slug] --issue` with subpoena scope
- [ ] Outside counsel engaged — [yes/who/TBD]
- [ ] Meet-and-confer scheduled — [date]
- [ ] Matter created in log — [yes/no/TBD — usually yes for anything above the smallest third-party docs subpoena]
- [ ] Insurance / cost-shifting analysis — [if burden is large]
- [ ] Internal escalation — [who]

---

## Recommendation

[Two paragraphs: what to do. Objection posture. Production posture. Whether outside counsel handles objections or we do. Whether to move to quash.]

---

## Citation verification

Every rule reference, case, statute, and regulation in this triage — including the Step 0 research citations, objection bases, and the privilege-log format pointer — is AI-generated and unverified. Before relying on any cite (especially in objections, a motion to quash, or correspondence with the issuing party), run a verification pass against a legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or your firm's platform) for accuracy, good law status, and local variants. Fabricated or misquoted citations in filed documents have resulted in sanctions. Source tags on each citation (e.g., `[Westlaw]`, `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.
```

### Step 9: Hand off

**Before responding to the subpoena (serving objections, producing documents, appearing for deposition, or filing a motion to quash — any substantive response to the issuing party or court):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Responding to a subpoena has legal consequences — missing a deadline risks contempt, over-producing waives privilege, under-producing risks sanctions. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the subpoena type, issuing authority, deadlines, scope of what's sought, objections framework and strength, privilege and burden issues, proposed response posture, what could go wrong, what to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. Triage, scoping, and internal calendaring do not require the gate — the response to the issuing authority does.

- If classified as **grand jury subpoena** → stop, flag for escalation per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`, do not proceed with standard triage.
- If classified as **CID**: flag that regulator-specific norms apply; recommend outside regulatory counsel.
- Otherwise: offer to create a matter (usually yes — subpoenas are almost always material enough to track).
- If a legal hold isn't issued with subpoena scope, hand off to `/legal-hold --issue` immediately.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Draft the final objections letter.** Produces the framework; the letter is drafted by user + outside counsel (future: a dedicated objections-draft skill).
- **Move to quash.** Surfaces the option; the motion is legal work that requires jurisdiction-specific analysis.
- **Validate rules across jurisdictions.** The Step 0 research produces the operative rule for this subpoena; the skill doesn't independently confirm currency or local variants. Flag for counsel verification before acting.
- **Handle grand jury subpoenas.** Escalates. This is outside the triage scope.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` — if populated and no `--redo`, confirm before overwriting.
2. Run the interview workflow below.
3. Seed docs: privacy policy (URL or file), DPA template, one reference PIA. Read all three.
4. Extract: policy commitments, DPA positions (note deltas vs. stated), PIA structure.
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/privacy-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` (create parent directories as needed). Show summary. Offer first task.

## `--check-integrations`

Re-runs the integration availability check (document storage, Slack, scheduled-tasks) and updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. Does not re-interview. Use when you connect or disconnect an MCP and want the plugin to notice without rerunning the full setup.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

```
/privacy-legal:cold-start-interview
```

```
/privacy-legal:cold-start-interview --check-integrations
```

---

# Cold-Start Interview: Privacy & Data Protection

## Purpose

Learn how *this* privacy team works — what regulations actually apply to them, what they will and won't agree to in a DPA, what a good PIA looks like here versus anywhere else. Write it into `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` so every other skill reads from the same understanding.

Privacy practices vary wildly by company. A B2B SaaS processor has almost nothing in common with a consumer app controller. The interview figures out which one this is before anything else.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/privacy-legal/*/CLAUDE.md` but not at the config path, copy it forward.

## Check for the shared company profile

Look for `~/.claude/plugins/config/claude-for-legal/company-profile.md`.

- **If it exists:** Read it. Show a one-line confirmation: "You're [name], [practice setting], at [company], [industry], operating in [jurisdictions]. Right? (Or say 'update' to change the shared profile.)" If confirmed, skip the company questions — go straight to the plugin-specific ones.
- **If it doesn't exist:** You'll be the first plugin this user set up. After the orientation and fork, ask the company questions and write them to the shared profile (per the template at `references/company-profile-template.md` in the plugin root), then continue with the plugin-specific questions. Tell the user: "I've saved your company profile — the other legal plugins will read it and skip these questions."

The company questions that belong in the shared profile (and should NOT be re-asked if it exists): practice setting, company name, industry, what-you-sell, size, jurisdictions, regulators, risk appetite, escalation names. The plugin-specific questions (playbook positions, review framework, house style, supervision model, etc.) stay per-plugin.

## Install scope check

Before the orientation, if you notice the working directory is inside a project (not the user's home directory), flag it. Say once:

> **Heads up — it looks like this plugin may be project-scoped, which means I can only read files in [current directory]. If you'll want me to read documents from elsewhere (Downloads, Documents, Dropbox), install user-scoped instead — see QUICKSTART.md. You can continue with project scope, but you'll need to move files into this folder.**

Ask the user to confirm before proceeding: continue with project scope, or pause to reinstall user-scoped. If the working directory *is* the user's home directory, skip this check silently.

## Before the interview starts

Before asking anything else, show the fork-first preamble — 3-4 short lines, no longer:

> **`privacy-legal` is for people who run the privacy program: PIAs, DPA reviews, DSAR responses, regulatory gap analysis.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, which side of a DPA you sit on (processor/controller/both), and primary jurisdictions, with sensible defaults everywhere else. **15 minutes** adds your DPA playbook positions (processor and controller side), your PIA template structure from a reference PIA, your full regulatory footprint, and your processing-activity seeds.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

Wait for the user's pick before showing anything else.

<!-- COLLATERAL LINKS: when onboarding collateral exists, prepend a line above the preamble:
     "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL), then come back and run /cold-start-interview." -->

## After the user picks quick or full

Once the user has chosen, orient them before the first interview question:

> "This plugin maintains your practice profile (DPA playbook, PIA house style, regulatory footprint), a processing-activity register, and per-activity PIAs and DPA reviews. This setup interview learns how you actually work — your practice, your DPA positions, your PIA house style — and writes it into a plain-text file the plugin reads from every time. Everything you answer can be changed later. Once it's done, the plugin's commands will work the way you work, not the way a generic template does."
>
> Then: "Setup builds a fresh professional profile from your answers. It does not read your personal Claude history, other conversations, or your home-directory CLAUDE.md. If I notice relevant information in our conversation context — e.g., you mentioned your company earlier — I'll ask before using it. Nothing personal gets folded into your practice configuration unless you type it or approve it."
>
> Then: "Ready? A few quick questions first, then we'll go deeper."

**Why this matters.** Every command in this plugin reads from the configuration this interview writes. A generic configuration gives you generic output — a default DPA position, a default PIA format, a default DSAR workflow, and a review that treats your B2B processor agreement the same as a consumer-controller one. Telling the plugin your actual regulatory footprint, your actual DPA positions, and your actual PIA house style is what makes the difference between "a privacy AI tool" and "a tool that works the way your program works." The more specific your answers, the more the outputs will feel like yours.

Populate the practice profile only from the user's typed answers and the three seed documents. Do not read `~/CLAUDE.md` or pull practice facts from ambient context. If something relevant is already visible in the conversation, ask before using it.

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and regulatory footprint. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for DPA positions, DSAR timing, and PIA thresholds. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/privacy-legal:cold-start-interview --full` anytime to do the whole interview, or `/privacy-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Pause for real answers.** Some questions have quick tap-through answers (controller vs. processor, regulatory footprint). Others need the user to type something, describe something, or upload a document (privacy policy, DPA template, reference PIA, DPA negotiating positions, systems-list for DSARs). When a question needs more than a quick tap:

- **Ask the question and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For seed-document uploads:** "Paste the contents, share a file path or URL, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review the interview. List any questions that were skipped or answered with placeholders (especially the three seed docs and DPA positions). Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait for the answer.
- **Never** write a practice profile with silent gaps. Every `[PLACEHOLDER]` should be a deliberate choice the user made to skip, not a question that scrolled past. If the DPA template or reference PIA was skipped, note `[POSITIONS UNTESTED]` so downstream skills know.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/privacy-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /privacy-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> I'm going to help with DPAs, DSARs, PIAs, and keeping an eye on when the regs move under you. Before I do any of that, I need to know what kind of privacy shop this is. Ten minutes.
>
> Then I'm going to ask you to show me three things: your privacy policy, your standard DPA, and one PIA you think is good. I'll learn more from those than from anything you tell me.

### Part 0: Who's using this, and what's connected

Three quick questions before we get into privacy specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds every skill's work-product header and output framing — lawyer gets "ATTORNEY WORK PRODUCT," non-lawyer gets research framing and attorney-review checkpoints before legally consequential steps.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, privacy ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — DPO-office non-lawyer, privacy program manager, founder handling privacy with an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — triage, DPA review, PIAs, DSAR responses, reg-gap analysis, policy monitoring. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "cleared to sign," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — sending a DSAR response, signing a DPA, submitting a DPIA to a regulator, giving breach notification. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). Many offer free or low-cost initial consultations. For small businesses, local law school clinics and SCORE mentors can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### Practice setting

> Which of these best describes where you're practicing? (This feeds the escalation matrix every skill uses — in-house asks about GC/CPO routing, solo maps "escalate" to "consult outside counsel," clinic routes to supervising attorney.)
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

This reshapes the escalation section and some of the DPA-authority questions:

- **Solo / small firm (no hierarchy):** Skip internal escalation chain. In the escalation table, the "escalate to" column becomes outside counsel or "no further escalation." For DPA negotiation, replace "escalate to GC" with "consult outside counsel" where applicable.
- **Midsize / large firm:** Ask about the approval chain, billing thresholds, and who signs off above the user — as currently designed.
- **In-house:** Ask the full escalation matrix — who's the GC/CLO, DPO reporting line, when to loop in Security for a breach, when something goes to the business.
- **Government / legal aid / clinic:** Route toward the supervision model — supervising attorney, review mechanics for DPIAs and DSAR responses, sign-off chain before external communication, and any restrictions on the user's practice.

Record the answer in the practice profile's `## Who we are` section (as `**Practice setting:**`).

#### What's connected?

> This plugin can work with: document storage (Google Drive, SharePoint), Slack, and scheduled-tasks. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.] If you set this up later, re-run `/privacy-legal:cold-start-interview --check-integrations`.
>
> You don't need all of these. Core features work with file access alone.

#### Record to CLAUDE.md

Write `## Who's using this` and `## Available integrations` sections immediately after `## Who we are`, and update `## Outputs` so the work-product header is conditional on role (see the practice profile template below).

### Part 1: What kind of privacy shop is this? (2-3 min)

**The business model question (this determines everything):**

> **What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription).

- Whose data flows through the company?
- Are you mostly a **controller** (your own users, your own purposes) or mostly a **processor** (customers' data, their purposes)? Both? (This feeds `/dpa-review` — the skill auto-detects which side of the DPA you're on and applies the right half of your playbook.)
- B2B, B2C, or both? Enterprise or SMB customers?

**Regulatory footprint:**
- Which regulations actually apply? GDPR? CCPA/CPRA? HIPAA? FERPA? Sector-specific? (This feeds `/reg-gap-analysis` — every new reg gets diffed against this list to see if it reaches you, and `/use-case-triage` uses it to spot which regimes apply to a new processing activity.)
- Any regulators who know you by name yet? Open inquiries, consent decrees, anything?
- Where does the data physically live? US only? EU? Multi-region?

**The team:**
- How many privacy people? Is there a DPO? In-house or outside?
- "When a review finds something that needs someone more senior to sign off — a DPA position above your approval threshold, a DSAR with legal exemptions in play, a novel processing activity that doesn't fit the PIA template, a regulator inquiry, or a decision that's above your authority — who does that go to? Give me a name or a role (the GC, the CPO, your boss), or say 'I decide myself.' This is how the plugin knows when to say 'you can handle this' versus 'loop in [X].'"

### Part 2: DPA negotiating positions (3-4 min)

*(These positions feed `/dpa-review` — every inbound DPA is redlined against your standards, fallbacks, and never-accepts. Wrong positions here = wrong redlines every time.)*

Before the structured questions: "Do you have an existing DPA template, a DPA negotiation playbook, or a fallback-positions memo I can read? Paste the contents or share a file path, and I'll extract the positions rather than making you re-type them. If not, say 'no' and I'll ask the questions one at a time."

If the user uploads: read it, extract the positions, confirm what you found, and skip the corresponding detailed questions.

**If the user didn't upload a DPA playbook:** at the end of this section, offer: "Want me to write this up as a standalone DPA playbook you can share and maintain? Same content I just captured for your practice profile, formatted as a team-facing doc you can circulate or hand to a new privacy hire."


This is where the skill earns its keep — most privacy teams have DPA positions but rarely write them down.

**When you're the processor (customers send you a DPA):**
- Do you have a standard DPA you push, or do you take customer paper?
- Audit rights: SOC 2 report is the offer, right? Or do you accept on-site?
- Breach notification: what's the shortest window you've agreed to?
- Subprocessor approval: notification only, or does the customer get a veto?
- Data location commitments: can you commit to a region, or is it "wherever AWS puts it"?
- Deletion on termination: how many days, and do you certify?

**When you're the controller (you send a DPA to vendors):**
- Same questions, opposite polarity. What do you *require* from vendors?

**The one thing in a DPA that makes you say no:**
- What's the term that's an automatic reject?

### Part 3: House style (1-2 min)

**PIAs:** *(This feeds `/pia-generation` — the skill uses your trigger, format, depth, and sign-off as the default template for every PIA it drafts.)*
- What triggers a PIA at your company? Every new feature? Only certain categories?
- How long is a good PIA — two pages or twenty?
- Who signs off — just you, or is there a review committee?

**DSARs:** *(This feeds `/dsar-response` — the systems list drives the locate step, the handler drives who gets the runbook, the SLA drives deadline calculations.)*
- Volume — one a month or a hundred?
- Who handles them — you, or a support team with a runbook?
- What systems does a DSAR touch — how many places does user data live?

### Part 4: Seed documents (3-4 min)

> I want to see three things. They'll tell me how you actually work.
>
> 1. **Your current privacy policy.** The public one. I'll read it to understand what you've committed to — every PIA and DPA has to be consistent with it.
>
> 2. **Your standard DPA template.** The one you push on customers (or vendors). This is your stated playbook — I'll compare it to what you told me.
>
> 3. **One PIA you're happy with.** Not a perfect one — a *representative* one. I'll learn your structure, your tone, how deep you go, what you skip.

**How to read the seed docs:**

**Privacy policy:** Extract every commitment. Data categories collected, purposes, retention, third parties, user rights. These are promises the PIA skill needs to check against.

**DPA template:** Map every term to the interview answers. Deltas are interesting — "you said 72-hour breach notification but your template says 'without undue delay' — which is the real position?"

**PIA:** Extract the structure as a template. Section headings, depth of analysis, format of risk statements. This becomes the default output format for the pia-generation skill.

### Part 5: Outputs and policy document location (1 min)

> "Two last things — I need to know where to look to keep your policy current."

- **Where do you save completed PIAs, DPA reviews, and triage results?** A folder path
  or shared drive location. This is where the policy-monitor skill will crawl to detect
  when your practice has drifted ahead of your written policy. (This feeds `/policy-monitor` — without this path, the drift sweep only runs in direct-query mode.)
- **Where is the actual privacy policy document?** The one that gets published or shared
  with customers. I'll need to read it to suggest edits when drift is found.
- **Is there a naming convention for output files?** (e.g., `PIA_FeatureName_YYYY-MM-DD`)
  or is it ad hoc?

If outputs aren't saved anywhere yet:
> "That's fine — the policy-monitor skill will still work in direct-query mode
> ('we want to start doing X, does our policy cover it?'). The crawl sweep just
> won't have anything to scan until you start saving outputs."

## Writing the practice profile

```markdown
# Privacy & Data Protection Practice Profile

*Written by the cold-start interview on [DATE]. Edit this file directly.*

---

## Who we are

[Company] is a [B2B SaaS / consumer app / platform / etc.]. We are primarily a
[controller / processor / both] with respect to [whose data]. Data lives in
[regions]. Privacy team is [N] people. [DPO name or "no formal DPO"]. Escalation
goes to [GC / CPO / name].

**Regulatory footprint:** [GDPR / CCPA / HIPAA / etc. — only list what applies]

**Open regulatory matters:** [none / list]

---

## Who's using this

**Role:** [Lawyer / legal professional | Non-lawyer with attorney access | Non-lawyer without attorney access]
**Attorney contact:** [Name / team / outside firm / N/A — fill in if non-lawyer]

---

## Available integrations

| Integration | Status | Fallback if unavailable |
|---|---|---|
| Document storage (Drive / SharePoint) | [✓ / ✗] | Outputs saved locally; policy-monitor sweep runs in direct-query mode only |
| Slack | [✓ / ✗] | Breach / triage notifications delivered inline instead of posted |
| Scheduled tasks | [✓ / ✗] | Policy-monitor sweep runs on demand only |

*Re-check: `/privacy-legal:cold-start-interview --check-integrations`*

---

## DPA playbook

### When we are the processor (customer DPAs)

| Term | Our standard | Fallback | Never |
|---|---|---|---|
| Audit rights | [e.g., SOC 2 Type II annual] | [e.g., virtual audit on 60 days' notice] | [on-site without notice] |
| Breach notification | [e.g., team's standard window from discovery] | [e.g., team's acceptable fallback] | [windows tighter than the team can meet] |
| Subprocessor changes | [e.g., advance notice, customer may object] | [notice only] | [approval required per subprocessor] |
| Data location | [e.g., US + EU selectable] | [follows customer region] | [hard commitment to single DC] |
| Deletion on termination | [e.g., standard days post-termination, certification on request] | [longer window] | [immediate] |
| Liability for data | [e.g., within the MSA cap] | [separate capped carveout] | [uncapped] |

> *From the DPA template:* [any deltas between template and stated positions]

### When we are the controller (vendor DPAs)

| Term | We require | Acceptable | Never accept |
|---|---|---|---|
| [Term] | [what we require] | [what we'll accept] | [what we won't accept] |

### The one thing

[DPA term that's an automatic no]

---

## Privacy policy commitments

*Extracted from [URL / filename] on [date]. If the policy changes, re-run setup
or edit this section.*

**Data categories we say we collect:** [list]
**Purposes we state:** [list]
**Retention commitments:** [what the policy says]
**Third-party disclosures we name:** [list]
**User rights we offer:** [access / delete / port / correct / etc.]

---

## PIA house style

**Trigger:** [what requires a PIA — new data collection, new vendor, etc.]
**Format:** [structure extracted from the seed PIA]
**Depth:** [typical length / detail level]
**Sign-off:** [who approves]

**Template structure (from seed PIA):**
[section headings and rough content of each]

---

## DSAR process

**Volume:** [rough monthly count]
**Handler:** [privacy team / support team / automated]
**Systems to check:** [list of every place user data lives — prod DB, analytics, support tickets, backups, etc.]
**Identity verification method:** [how you confirm the requester is the data subject]
**Response SLA:** [internal SLA target — research the applicable regulatory deadline(s) for each regime in the footprint and cite primary sources before committing]

---

## Escalation

| Issue type | Handle at | Escalate to | When |
|---|---|---|---|
| Routine DSAR | [handler] | [you] | Unusual scope, litigation hold, potential dispute |
| Customer DPA negotiation | [you] | [GC] | Outside fallbacks above |
| PIA for high-risk processing | [you + review committee?] | [GC / DPO] | Biometric, children, automated decisions |
| Regulator contact | — | [GC + you immediately] | Always |
| Suspected breach | — | [Security + you + GC immediately] | Always |

---

## Seed documents

| Doc | Location | Date reviewed | Notes |
|---|---|---|---|
| Privacy policy | [URL] | [date] | [version] |
| DPA template | [path/link] | [date] | |
| Reference PIA | [path/link] | [date] | "[name of product/feature it was for]" |

---

## Outputs

**Outputs folder:** [path where completed PIAs, DPA reviews, and triage results are saved]
**Naming convention:** [file naming pattern, or "ad hoc"]
**Privacy policy document:** [path or URL to the actual published privacy policy]
**Policy last updated:** [date]
**Last policy sweep:** [date of last policy-monitor crawl — updated automatically]

**Work-product header** (prepended to DPA reviews, PIAs, reg-gap analyses, policy-monitor sweeps, and triage outputs):

- If Role is Lawyer / legal professional: `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT — PREPARED AT THE DIRECTION OF COUNSEL`
- If Role is Non-lawyer: `RESEARCH NOTES — NOT LEGAL ADVICE — REVIEW WITH A LICENSED ATTORNEY BEFORE ACTING`

For externally-facing deliverables (DSAR response letters, regulator responses, client communications) the header is omitted — see the specific skill's instructions. Confirm the correct marking for your jurisdiction and matter before sending.

---

*Re-run: `/privacy-legal:cold-start-interview --redo`*
```

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in privacy practice:**
>
> - **Review a DPA against your playbook** — e.g., "Auto-detects processor vs. controller; flags deviations from your positions." Try: `/privacy-legal:dpa-review`
> - **Triage a processing activity** — e.g., "PIA, mandatory GDPR DPIA, or proceed — with privacy-policy conflict surfaces." Try: `/privacy-legal:use-case-triage`
> - **Generate a PIA in house format** — e.g., "Structured intake, risk analysis, regulatory classification, recommendation." Try: `/privacy-legal:pia-generation`
> - **Walk through a DSAR** — e.g., "Verify, locate, assess exemptions, draft the response letter." Try: `/privacy-legal:dsar-response`
> - **Diff a new regulation against your policy** — e.g., "Outputs the gap list and a remediation plan with owners and deadlines." Try: `/privacy-legal:reg-gap-analysis`
> - **Sweep for policy drift** — e.g., "Look across saved PIAs, DPA reviews, and triage results to find where the privacy policy no longer matches practice." Try: `/privacy-legal:policy-monitor`
>
> **My suggestion for your first one:** Run `/use-case-triage` on one real processing activity — it's the fastest way to see whether your playbook is capturing the right cuts. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show the summary.** "Here's what I heard. The DPA playbook is the part to check hardest — did I get your positions right?"

2. **Research connector prompt.** Say:

   > "Before your first DPA review or PIA: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you."

3. **Propose first tasks:**
   - "Want me to diff your privacy policy against your actual data collection? Sometimes those drift."
   - "Got a customer DPA in the queue I can take a crack at?"
   - If DSAR volume is high: "Want a DSAR response template built from your systems list?"

4. **Flag gaps:** If they couldn't produce a DPA template or a reference PIA, note it: "You're running without a standard DPA — first time a customer asks, you'll be negotiating from scratch. Want to draft one?"

5. **Close with the "you can change anything later" note:**

   > "Your practice profile is at `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` — a plain text file you can read and edit directly. Anything you answered can be changed:
   >
   > - Edit the file directly for a quick change
   > - Run `/privacy-legal:cold-start-interview --redo` for a full re-interview
   > - Run `/privacy-legal:cold-start-interview --check-integrations` to re-check what's connected
   >
   > The three sections people adjust most: the **DPA playbook** (as you negotiate more and harden positions), the **regulatory footprint** (as the company enters new markets), and the **DSAR response timing and systems list** (as the data landscape changes)."

6. **Your practice profile learns.** End with this note:

   > **Your practice profile learns.** It gets better as you use the plugins:
   >
   > - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
   > - The `policy-monitor` skill watches for drift between your privacy policy and how you actually practice. When it finds drift, it'll propose edits to match reality.
   > - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
   > - Run `/privacy-legal:cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
   >
   > Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## Failure modes

- **Don't assume GDPR applies.** Lots of US-only B2B companies are told they "should probably care about GDPR" — ask whether they actually have EU data subjects.
- **Don't let them skip the controller/processor question.** If they're not sure, walk through it: "When your customer's user data comes into your system, whose privacy policy governs it — yours or the customer's?"
- **Don't write a DPA playbook from generic positions.** If they haven't negotiated many DPAs, say so in the config CLAUDE.md: `[POSITIONS UNTESTED — this team hasn't negotiated many DPAs yet. Treat as starting points, not settled positions.]`$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/privacy-legal:customize`. They want to change something in
their privacy profile — a risk posture, an escalation contact, a DPA
position, a PIA section, a DSAR timeline — without re-running the whole
cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/privacy-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting, controller vs. processor orientation *(shared across all 12
     plugins — changes flow through `company-profile.md`)*
   - **Risk posture** — conservative / middle / aggressive, what each means
     for processor obligations, cross-border transfers, and retention
   - **People** — DPO, privacy team, engineering liaison, outside counsel,
     escalation chain
   - **DPA playbook** — positions on sub-processor notice, deletion, audit,
     liability, international transfers, SCCs — as processor and as
     controller
   - **Privacy policy commitments** — the commitments your privacy notice
     has made that `/policy-monitor` watches practice against
   - **PIA house style** — section order, risk scoring, stakeholder framing,
     when DPIA triggers apply
   - **DSAR process** — verification, statutory timelines per regime,
     exemption application, template response structure
   - **Workflow** — intake path, matter workspaces, policy-monitor sweep
     cadence
   - **Integrations** — document storage / privacy tool / Slack status,
     fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Sub-processor notice 30 days → 14 days:* "`/dpa-review` will now flag
     anything shorter than 14 days as a deviation. Existing DPAs stay as
     logged."
   - *New DSAR exemption in the playbook:* "`/dsar-response` will surface this
     exemption in the assessment step where the facts match."
   - *Risk posture middle → conservative:* "I'll flag more activities for
     PIA escalation, recommend stricter SCC clauses, and be more
     conservative on retention."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/privacy-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" a regime from
  scope, offer to mark it `[Not currently in scope]` and explain what
  flagging drops.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., "processor only" + controller playbook positions
  active; or "no EU nexus" + SCCs in the default template), flag the
  tension.
- **Flag guardrail degradation.** The `[review]` flag, source attribution
  tags, `[verify]` tags on cited regulations, and the DPIA-trigger
  mandatory-check on `/use-case-triage` are load-bearing — do not remove. If
  statutory DSAR timelines are adjusted below the regulatory minimum,
  refuse and explain why.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/dpa-review', 'legal', 'dpa-review', '', 'dpa-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /dpa-review

1. Load `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → DPA playbook. If placeholders, stop and prompt setup.
2. Get the DPA. Determine direction: are we processor (customer's DPA) or controller (vendor's)? Ask if ambiguous.
3. Run the workflow below — term-by-term against the appropriate playbook row.
4. Run privacy policy consistency check.
5. Output: review memo with redlines. Save per house style.

```
/privacy-legal:dpa-review customer-dpa.pdf
```

---

# DPA Review

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/privacy-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

DPAs come in two flavors and the review is nearly opposite for each. When a customer sends their DPA, we're defending our operational flexibility. When we send one to a vendor, we're protecting our (and our customers') data. Both reviews read from the same `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` playbook but from opposite rows.

## First: which direction?

Before anything else, establish:

- **We are the processor** → customer is sending us their DPA → read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → "When we are the processor" table
- **We are the controller** → we're sending a DPA to a vendor (or reviewing theirs) → read "When we are the controller" table

If unclear, ask. Getting this wrong inverts every recommendation.

## Jurisdiction assumption

This review assumes the jurisdictional scope specified in your configuration. Privacy rules, response deadlines, and lawful bases vary materially by jurisdiction (GDPR vs. state consumer privacy laws vs. sectoral). If the controller, processor, or data subjects are in a different jurisdiction than configured, this review may not apply as written.

## Load prior context on this counterparty / activity

Before reviewing, check the outputs folder for prior work on this counterparty or processing activity. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Outputs` for the outputs folder path. Scan for:

- **Prior `use-case-triage` results** for the same counterparty / processing activity — the triage produces a risk rating and conditions that this DPA review should honor or explicitly depart from.
- **Prior `pia-generation` outputs** covering this counterparty / processing activity — the PIA may have flagged risk mitigations the DPA needs to implement.
- **Prior `dpa-review` outputs** for the same counterparty — earlier DPA reviews set expectations about what was acceptable, what was flagged, and what was settled. A fresh review that silently contradicts the earlier one erodes trust in the work product.

If a prior output is found, cite it in the review:

> "Prior triage ([date]) rated this [risk level] and conditioned approval on [X]. This DPA review is consistent with that finding." — or —
> "Prior triage ([date]) rated this [risk level]. This DPA review departs from that finding because [reason — new facts, different scope, contract term that changed the picture]."

**Carry severity from the upstream output as a floor** per the cross-skill severity floor rule in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Shared guardrails`. A processing activity the triage rated 🔴 cannot be quietly downgraded to 🟢 in the DPA review; any demotion is stated and explained.

If no prior output is found (new counterparty / new activity), say so explicitly in the review — "No prior triage or PIA on this counterparty in outputs folder" — so the reviewing attorney knows the check ran.

## Load the playbook

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## DPA playbook`. Also read `## Privacy policy commitments` — the DPA can't contradict what the privacy policy promises.

## Federal sectoral overlay (ask first, before the term-by-term walk)

Before walking the term-by-term review, answer: **does the data flowing through this DPA include any federally-regulated category?** GDPR and state consumer-privacy law supply one floor; federal sectoral law often supplies another that does not appear in the generic DPA playbook. A DPA that is GDPR-complete can still be GLBA-blind, HIPAA-blind, or COPPA-blind, and a fintech / healthtech / edtech / kidtech counterparty will notice.

> **Activity-based federal overlays — ask first:**
>
> Does this processing touch:
> - **Financial account data or "nonpublic personal information" about consumers** (GLBA / Reg P)? If yes, the DPA needs: (a) an NPI-sharing restriction consistent with 15 U.S.C. § 6802(a)-(c) and Reg P (no sharing for marketing to non-affiliated third parties without opt-out / opt-in), (b) safeguards language aligned with the Safeguards Rule (16 C.F.R. Part 314), (c) incident notification that reaches FTC/OCC timing where applicable, (d) a clean carve-out so a CCPA § 1798.145(e) exemption doesn't accidentally waive GLBA-level obligations.
> - **Protected health information held by a covered entity or business associate** (HIPAA Privacy / Security Rules)? If yes, the DPA needs: a Business Associate Agreement (BAA) layered with or integrated into the DPA per 45 C.F.R. § 164.504(e), breach notification timing aligned with HITECH (60 days to CE; CE 60 days to HHS; 500+ threshold for media), permitted-uses clause, subcontractor BAA flow-down. A commercial DPA without BAA flow-down for PHI is a defect.
> - **Education records held by a school or a service provider acting for a school** (FERPA)? If yes, the DPA needs: a "school official" / directory-information framing consistent with 34 C.F.R. § 99.31, parental-consent flow-through, state student-privacy analog handling (NY Ed Law 2-d, CA SOPIPA, IL SOPPA).
> - **Data from children under 13 collected by an operator of an online service directed to children or with actual knowledge** (COPPA)? If yes, the DPA needs: verifiable-parental-consent flow-through, retention limits, deletion-on-request machinery, prohibition on behavioral advertising absent VPC.
> - **Another sectoral federal regime** (VPPA for video-viewing records, CPNI for carrier data, DPPA for DMV records, TCPA / Shaken-Stir for call/SMS, GLBA Reg S-P for broker-dealers, §5 FTC Act for unfair/deceptive practices around sensitive data)?
>
> If yes to any: the federal overlay usually supplies the controlling substantive restriction, not just an exemption from a state consumer privacy law. Research the currently-operative provision and cite it. A DPA that is "exempt" from CCPA under § 1798.145(e) because it is GLBA-covered is still subject to the GLBA restrictions — the CCPA exemption moves the governing framework, it doesn't eliminate it. Flag sectoral gaps in the deal-breakers list alongside GDPR / state-privacy gaps.

If no sectoral overlay applies, note that explicitly — "no federally-regulated data categories identified; sectoral overlay n/a" — so the reviewing attorney sees that the check happened, rather than wondering whether it was skipped.

## The term-by-term review

### Core terms (check every DPA)

Walk every DPA through these terms, clause by clause. The *specific* numeric and substantive positions (notice periods, breach timelines, acceptable/unacceptable floors) come from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## DPA playbook`. The regulatory floors that any DPA has to clear come from primary law — **research the currently operative rule** for each applicable regime and cite primary sources before stating a floor.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a regime's breach window, transfer-mechanism requirement, subprocessor-change rule, or any other floor, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the review — regulatory floors, SCC versions, adequacy decisions, regulator guidance, case law — with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 28, Art. 33 72-hour breach notice, SCC Decision 2021/914 by number). Still verify before filing, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific implementing regulations, regulator guidance, case holdings, adequacy decisions, SCC modules and versions, UK Addendum / IDTA status, thresholds, effective dates.
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, clause numbers within SCCs, paragraph numbers, volume/page references) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[Commission / regulator site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

| Term | Looking for | Playbook field | Common fights |
|---|---|---|---|
| **Roles** | Clear controller/processor designation; matches reality | — | Counterparty labels the relationship (e.g., "joint controller") in a way that doesn't match reality |
| **Processing scope** | Limited to documented instructions; defined purposes | — | Open-ended scope expanders ("and related purposes") |
| **Subprocessors** | Current list disclosed, change mechanism defined | Subprocessor changes | Blanket approval vs. veto vs. notice-only |
| **Security measures** | Annex references specific controls or standards | Security standards | "appropriate technical and organizational measures" with no annex = empty promise |
| **Breach notification** | Defined trigger ("discovery" vs "confirmation"), defined timeline | Breach notification | Timeline tightness; clock trigger; "without undue delay" is vague |
| **Audit rights** | Method (report vs. on-site), frequency, notice, cost allocation | Audit rights | On-site audits on tight notice |
| **International transfers** | Transfer mechanism identified, supplementary measures, transfer impact assessment reference | Transfers | Outdated or missing transfer mechanisms |
| **Deletion/return** | Timeline post-termination, certification, backup carveout | Deletion on termination | "Commercially reasonable" deletion = ??? |
| **Liability** | Within MSA cap or separate; carveouts | Liability for data | Uncapped data breach liability = existential |

### When we're the processor: defensive review

Customer DPAs try to push operational burden onto us. For each clause below, compare the customer's ask to the playbook. Where the customer's ask is outside the playbook, push back to the team's standard position (from the config CLAUDE.md) and be ready to fall back to the acceptable position.

| Clause | Risk | Research / playbook lookup |
|---|---|---|
| Subprocessor approval right (veto) | Can't add infrastructure without customer-by-customer approval | Apply playbook position on subprocessor changes |
| On-site audit on short notice | Unworkable at scale | Apply playbook position on audit rights |
| Aggressive breach notification window | Often demands notice before we know what happened | Research the regulatory floor for each applicable regime (cite primary sources); compare to playbook position |
| Hard data residency (single country/DC) | May not match architecture | Apply playbook position on data location; confirm what we can actually commit to |
| Processor liability uncapped | Bet-the-company | Apply playbook position on liability for data |
| Customer may issue binding "instructions" | Open-ended operational control | Define instructions as "documented in the Agreement or agreed in writing" |
| Deletion on very short timeline | Backup and log retention makes this impossible | Apply playbook position on deletion on termination; document backup rotation carveout |

### When we're the controller: protective review

Vendor DPAs try to give us nothing. For each clause below, compare to the controller-side playbook.

| Clause | Gap | Research / playbook lookup |
|---|---|---|
| No subprocessor list | Don't know who touches our data | Require published current list + advance notice per playbook |
| "Industry standard security" | Means nothing | Require annex with specific controls, or reference to a named standard (e.g., SOC 2, ISO 27001) |
| No breach notification timeline | They tell us whenever | Research applicable regulatory floor; require playbook position |
| No audit rights at all | Can't verify anything | Require at minimum an independent audit report per playbook |
| Vendor can use data for "service improvement" | Potential training on our data | Strike; processing limited to providing the service to us |
| No international transfer mechanism | No lawful transfer mechanism | **Research the currently operative transfer mechanism** for the corridor in question (origin/destination jurisdictions, applicable regime, any adequacy decision, any supplementary measures). Cite primary sources and verify currency. |
| No deletion commitment | Data lives forever | Require playbook position on deletion + certification on request |

## Consistency check: privacy policy

The DPA you sign can't promise something the privacy policy doesn't cover, and vice versa.

- If the DPA commits to processing only for purposes X, Y, Z — does the privacy policy list those purposes?
- If the privacy policy says "we never sell data" — does any DPA clause look like a sale under CCPA?
- If the privacy policy names specific subprocessor categories — does the DPA subprocessor list match?

Flag mismatches. They're usually the privacy policy being stale, not the DPA being wrong, but someone needs to fix one of them.

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

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# DPA Review: [Counterparty]

**Direction:** [We are processor / We are controller]
**Reviewed:** [date]
**Attached to:** [MSA / standalone]

---

## Bottom line

[Two sentences. Can we sign? What has to change?]

**Issues:** [N]🟢 [N]🟡 [N]🟠 [N]🔴

---

## Term-by-term

[For each core term, use a standard deviation-memo format: what the
counterparty's DPA says, what our playbook says, the gap, the risk, and the
proposed redline language. Keep each term to a short self-contained block so a
reviewer can skim.]

---

## Privacy policy consistency

[🟢 Consistent | 🟡 Flags: list]

---

## Recommended redlines

[Consolidated — ready to send back]

---

## If they won't move

[For each issue: the fallback from the config CLAUDE.md, or escalation routing if no
fallback exists]
```

## International transfers note

If the DPA contemplates cross-border data transfers, **research the currently operative transfer mechanism requirements** for the applicable corridor(s). For each origin/destination pair, identify: the applicable regime, whether any adequacy decision is in force, which transfer mechanism is required or available (e.g., Standard Contractual Clauses and their applicable version/module, UK Addendum or IDTA, BCRs, derogations), whether a transfer impact assessment or equivalent is required, and what supplementary measures may be needed. Cite primary sources (regulation, Commission decision, regulator guidance, controlling case law) with pinpoint cites and verify currency — adequacy decisions, SCC versions, and required supplementary measures change through new Commission decisions, court rulings, and regulator guidance. Flag uncertainty for attorney verification.

If a transfer mechanism is missing and there is an international transfer, that is a 🔴 — there is no lawful transfer mechanism.

## Gate: signing a DPA

Reviewing a DPA is research. *Signing* it — or instructing someone to countersign on our behalf — is the consequential act.

**Before proceeding to sign or countersign a DPA (including returning an executed version, consenting to automatic execution on a counterparty platform, or instructing a signatory to execute):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Signing a DPA is a legal act — it binds the company to specific data-protection obligations that flow to regulators and data subjects. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, direction (we are processor / controller), the terms that deviate from the playbook and how they were resolved, any open fallback decisions, and the three things to ask the attorney before executing.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't draft a DPA from scratch. If the answer is "use our template," pull the template from the seed docs path in the config CLAUDE.md.
- It doesn't do the Transfer Impact Assessment itself — it flags when one is needed.
- It doesn't decide whether to accept terms outside the fallbacks. It routes those per the escalation table.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/dsar-response', 'legal', 'dsar-response', '', 'dsar-response', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /dsar-response

1. Load `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → DSAR process (systems list, verification method, SLA).
2. Run the workflow below.
3. Classify request type. Check escalation triggers — if any fire, route before proceeding.
4. Walk through: verify identity → walk systems list → exemption analysis → draft.
5. Output response draft. Do NOT send — human reviews and sends.
6. Log the DSAR per house process.

**Before pasting the request:** the request will contain the data subject's PII. Confirm your session and output storage meet your data-handling requirements. Redact anything you don't need (ID attachments, unrelated email threads). Do not store the subject's name in filenames.

```
/privacy-legal:dsar-response
[paste the request email]
```

---

# DSAR Response Drafting

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/privacy-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

A DSAR has a deadline (set by the applicable regime), a process (verify, locate, assess exemptions, respond), and a bunch of places it can go wrong. This skill walks through each step and drafts the response.

## Jurisdiction assumption

This analysis assumes the jurisdictional scope specified in your configuration. Privacy rules, response deadlines, and lawful bases vary materially by jurisdiction (GDPR vs. state consumer privacy laws vs. sectoral). If the data subject, processing activity, or controller is in a different jurisdiction than configured, this analysis may not apply as written.

## Load the process

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## DSAR process`. That section has:
- The systems list (every place user data lives)
- Identity verification method
- Response SLA
- Who handles routine vs. who gets escalated

If the systems list is empty or stale, flag it — can't do a complete DSAR without knowing where to look.

## Workflow

### Step 1: Classify the request

Identify which right the data subject is invoking. Common categories:

- **Access** — copy of their data + information about processing
- **Deletion / erasure** — remove their data (subject to exemptions)
- **Portability** — their data in machine-readable format
- **Correction / rectification** — fix inaccurate data
- **Objection** — stop a particular processing (often marketing)
- **Restriction** — pause processing pending a dispute
- **Opt-out of sale/share / automated decision-making** — regime-specific rights

**Research the applicable rule before proceeding.** For each invoked right, identify the jurisdiction(s) whose law applies (GDPR, UK GDPR, CCPA/CPRA, other US state privacy laws, sectoral regimes). Cite the controlling statute or regulation with pinpoint references — the specific article/section, the scope of the right, any carve-outs. Note effective dates; data subject rights are amended frequently (new state laws each legislative session). Flag uncertainty and escalate for attorney verification rather than stating a rule you haven't confirmed.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for the jurisdiction's rights, exemptions, or deadlines, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / right]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 33, CCPA § 1798.100, FTC Act § 5, 45-day CCPA response window under § 1798.130(a)(2) as a concept). Still verify before filing, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific implementing regulations, agency guidance, case holdings, thresholds, effective dates, post-2023 amendments.
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, volume/page numbers, paragraph numbers, regulatory subpart references) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[issuing authority site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

Some requests are combinations — "delete my account and send me my data first" is deletion + portability. Handle as two linked requests.

### Step 2: Verify identity

Per the method in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. Common approaches:

- **Logged-in verification:** Request came from within an authenticated session → identity confirmed
- **Email match:** Request came from an email on file → usually sufficient for low-risk requests
- **Additional verification:** For high-value accounts or deletion requests → challenge question, phone verification, ID document

**Calibrate to risk.** Over-verifying turns the DSAR process into a barrier (bad look with regulators). Under-verifying risks handing someone else's data to a fraudster.

If identity can't be verified:

```markdown
We were unable to verify that this request came from the individual whose data
is at issue. To proceed, please [verification step]. We cannot provide personal
data in response to a request we cannot verify.
```

This pauses the clock (arguably) but don't sit on it — respond to say you need verification within a few days, not on day 29.

### Step 3: Locate the data

Walk the systems list from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. For each system:

| System | Queried? | Data found? | What |
|---|---|---|---|
| Production database | | | |
| Analytics (e.g., Mixpanel, Amplitude) | | | |
| Support tickets (e.g., Zendesk) | | | |
| CRM (e.g., Salesforce, HubSpot) | | | |
| Email marketing (e.g., Marketo) | | | |
| Logs | | | |
| Backups | | | (note: usually exempt from deletion — see below) |
| Third-party processors | | | (they may need to be notified for deletion) |

For a B2B processor: the "data subject" is usually *your customer's* end user. Check whether this is actually your customer's DSAR to handle, not yours. Many processor DPAs say "forward DSARs to the controller."

### Step 4: Exemption analysis

Not everything gets produced or deleted. **Research the applicable rule before proceeding.** For each item, identify every exemption that plausibly applies under the regime in scope (e.g., third-party privacy, privilege, trade secret, security, legal obligation to retain, establishment/defense of legal claims, transactional necessity, backup rotation accommodations, freedom of expression). Cite the controlling statute, regulation, or case with a pinpoint cite. Exemption scope varies by jurisdiction and regime — verify currency and flag uncertainty.

**Don't narrow the list on a subjective call.** The skill proposes exemptions where a good-faith basis exists and flags the uncertain ones; the attorney narrows the list before the response goes out. Dropping an exemption that later turns out to apply is costly — once material is disclosed, the exemption is functionally gone. Over-asserting a plausible exemption is correctable by the attorney in review. Prefer the recoverable error.

Every proposed exemption carries an explicit note: **"proposed — requires attorney review before asserting. Regulators scrutinize blanket exemption claims, so the attorney narrows this list; the skill does not."**

Common recurring questions to work through:

- Does the record contain data about *other* people that needs to be redacted before production?
- Is there a specific legal retention obligation that blocks deletion? Cite it.
- Is there an active litigation hold covering this individual's data?
- Are there backup rotation or technical-feasibility accommodations that need to be documented (not used as a general excuse)?

**Document every exemption claimed.** If a regulator asks why you didn't delete something, "we had a legal obligation" needs a citation.

### Step 5: Draft the response — TWO LETTERS

> **Research-connector pre-flight.** Before emitting either letter or the internal exemption analysis, check whether a legal research connector is reachable for this session — Westlaw, an EUR-Lex / regulator-site connector, or any firm-configured research MCP. Collect this into the reviewer note per CLAUDE.md `## Outputs` — the reviewer note sits on the INTERNAL exemption-analysis and cover memo, NOT on the outward-facing DSAR letters to the data subject. If no connector returns results in Step 1 (right classification), Step 4 (exemption analysis), or the Deadline management research step (or none is configured at run time), record it in the **Sources:** line of the internal reviewer note — e.g., `not connected — cites from training knowledge; claimed exemptions, response deadlines, and extension mechanisms are especially fabrication-prone, verify before asserting any exemption to a data subject or regulator`. Per-citation `[model knowledge — verify]` tags remain inline. Do not emit a standalone banner above the output.

Most regimes expect (or require) a prompt acknowledgment separate from the substantive response. Produce both; do not collapse them into one letter that waits until the 45-day deadline to go out.

- **Step 5a — Acknowledgment letter.** Sent within days of receipt (target: same-day to 3–5 days, always well inside the regime's statutory window). Confirms receipt, states what the controller understands the request to be, states the response clock and the target date, asks for any identity-verification material still outstanding. Does NOT contain the substantive disclosure. A prompt acknowledgment is the first regulator-visible signal that the DSAR process is working; it also reduces the risk of a duplicate request or an early complaint.
- **Step 5b — Substantive response letter.** The actual disclosure, deletion confirmation, or portability export. Goes out by the statutory deadline (or the internal SLA if tighter). Only after identity verification is complete and the Step 3 / Step 4 data location + exemption analysis is done.

**Before proceeding to send either letter to the data subject:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Sending a DSAR response has legal consequences — the content, the exemptions claimed, and the omissions are all reviewable by a regulator, and misstatements become enforcement exposure. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: data subject, right invoked, applicable regime(s), what was located across the systems list, what is being withheld and under which exemption, identity verification posture, response deadline, and the three things to ask the attorney before the letter goes out.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes.

> **Note:** Both DSAR letters are externally-facing deliverables sent to the data subject. Do **not** include the work-product header from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` `## Outputs` on either letter. Internal notes, logs, and exemption analyses that accompany the letters are attorney work product — keep those separate and prepend the work-product header per `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` `## Outputs` (which differs by user role — see `## Who's using this`).

> **Before sending either letter:** This is a draft for attorney review, not a response to send. Sending commits the controller to a position, may waive exemptions, and may start a regulator's clock. A licensed attorney reviews, edits, and approves before either letter goes to the data subject. Do not send unreviewed.

#### Step 5a — Acknowledgment letter template

```markdown
Subject: We received your privacy request — [Company] — [date]

Dear [Name],

We received your [access / deletion / portability / correction] request on [date received].

**Your request, as we understand it:** [one-sentence restatement — e.g., "a copy of all personal data we hold associated with your account, along with the categories of third parties with whom we share it, and deletion of your account after we provide the copy."]

**What happens next:**
- Our target date for the substantive response is [date — no later than the regime's statutory deadline; use internal SLA if tighter]. [If identity verification is outstanding: "We need [specific verification step] before we can proceed — see below."]
- If we need more time because the request is complex or we receive other requests from you at the same time, we will tell you before the initial deadline and explain why. [If the regime allows an extension, cite the controlling provision.]
- No fee applies to this request. [Or: the fee applies only if the regime permits it and the request is manifestly unfounded or excessive — cite the provision.]

[If identity verification is outstanding:]
**To verify your identity,** please [specific verification step — e.g., reply to this email from the address on file with the last 4 digits of the payment method we have on file]. This does not pause our deadline; we continue to work in parallel.

If you have questions, contact [privacy contact].

[Sender]
```

**Clock-start rule.** The response clock starts on receipt of the request, not on completion of identity verification — unless the applicable regime says otherwise. Do not tacitly toll the clock on verification. If a regime has a different trigger, cite it; do not assume.

#### Step 5b — Substantive response letter templates

**Access request response:**

```markdown
Subject: Your Data Access Request — [Company] — [date]

We received your request on [date] for a copy of the personal data we hold about you.

**What we found:**

We hold the following categories of personal data associated with [identifier]:

| Category | Source | Purpose | Retained until |
|---|---|---|---|
| [Account info: name, email] | You, at signup | Account management | Account deletion |
| [Usage data] | Our service | Analytics, product improvement | [period] |
| [Support correspondence] | You | Customer support | [period] |

**Your data is attached** in [format]. [Secure delivery note — password-protected
archive, secure link with expiry, etc.]

**Third parties:** We share data with the following processors: [list or link to
subprocessor page].

**Your other rights:** You may also request [deletion / correction / portability].
To do so, [method].

**Data we did not include:**
- [Category] — [exemption and reason, e.g., "internal security logs — disclosure
  would compromise security measures"]
- [Data about other individuals has been redacted from support correspondence]

If you have questions about this response, contact [privacy contact].
```

**Deletion request response:**

```markdown
Subject: Your Deletion Request — [Company] — [date]

We received your request on [date] to delete the personal data we hold about you.

**What we deleted:**

| Category | System | Deleted on |
|---|---|---|
| [Account and profile] | Production | [date] |
| [Analytics events] | [Amplitude/etc.] | [date] |
| [etc.] | | |

**What we retained and why:**

| Category | Reason | Retained until |
|---|---|---|
| [Transaction records] | Legal obligation (tax record retention, [cite law]) | [date] |
| [Backup snapshots] | Will be deleted on next rotation | [date] |

**Third-party processors:** We have instructed [list] to delete your data from
their systems.

Your account is now closed. If you have questions, contact [privacy contact].
```

### Step 6: Log it

DSARs get audited. Record:
- Date received
- Date identity verified
- Date responded
- What was produced/deleted
- Exemptions claimed and basis
- Who handled it

If your team uses a DSAR tracking tool, create the record there. If not, a log file works.

## Escalation triggers

Per `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → Escalation table, escalate when:

- Requester is (or might be) a plaintiff, opposing counsel, or journalist
- Request scope is unusual ("all data including internal communications about me")
- There's a litigation hold on this individual's data (deletion request + lit hold = conflict, lawyer decides)
- Requester is disputing a previous DSAR response
- Any regulator is cc'd or mentioned

## Deadline management

**Two-letter rule.** Every DSAR produces an acknowledgment letter (prompt — target same-day to 3–5 days after receipt) AND a substantive response letter (by the statutory deadline). Most regimes either require or expect a prompt acknowledgment separate from the substantive response; a single combined letter sent on day 45 is a process failure even if it is substantively correct.

**Research the currently operative response deadline for the specific right invoked and the applicable jurisdictions.** Check whether an extension mechanism exists, how much extra time it buys, and what notice the data subject must receive to invoke it. Identify when the clock starts (receipt vs. verification vs. some other trigger — default rule is receipt; verify per regime). Cite the controlling statute or regulation with pinpoint references. Note effective dates — data protection response timelines are amended frequently and new state laws introduce their own clocks.

If `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## DSAR process` records an internal SLA that is tighter than the legal deadline, use the internal SLA and note the legal backstop.

If you're going to need an extension, send the "we need more time" notice well before the first deadline. Day-of extensions look bad.

## What this skill does not do

- It doesn't query systems directly. It walks you through the checklist; a human (or a connected tool) does the actual queries.
- It doesn't make exemption calls on close cases. It flags them for a lawyer.
- It doesn't send the response. Draft, review, human sends.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/privacy-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/privacy-legal:matter-workspace list` — list matters with status and active flag
- `/privacy-legal:matter-workspace switch <slug>` — set the active matter
- `/privacy-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/_archived/`, never delete)
- `/privacy-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/privacy-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Use the subcommand logic below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

# Matter Workspace

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; the workflow above explains the disabled state and suggests `/privacy-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/privacy-legal/
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
   - **Matter type** (read the plugin's practice profile for typical categories; for privacy-legal: PIA (processing activity) | DPA review | DSAR | regulator inquiry | transfer-mechanism review | incident | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/privacy-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/privacy-legal:matter-workspace new <slug>`.
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
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/pia-generation', 'legal', 'pia-generation', '', 'pia-generation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /pia-generation

1. Load `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → PIA house style (trigger, structure, depth, sign-off).
2. Run the workflow below.
3. Check: is a PIA actually needed? (House trigger + research the mandatory-assessment triggers for each applicable regime — cite primary sources, verify currency.)
4. Intake: ask the product-team questions. Can pull from PRD if provided.
5. Write PIA in house format. Include privacy policy consistency check.
6. Output with conditions list and named owners. Route for sign-off.

```
/privacy-legal:pia-generation "Location sharing feature"
```

```
/privacy-legal:pia-generation
PRD: [Drive link]
```

---

# PIA Generation

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/privacy-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

A PIA is a conversation with the product team, captured. It asks: what data, why, how long, who sees it, what could go wrong. This skill structures that conversation and writes the output in this team's format — the one learned from the seed PIA during cold-start.

## Jurisdiction assumption

This assessment assumes the jurisdictional scope specified in your configuration. Privacy rules, assessment triggers, and lawful bases vary materially by jurisdiction (GDPR vs. state consumer privacy laws vs. sectoral). If the processing activity, controller, or affected data subjects fall under a different jurisdiction, this analysis may not apply as written.

## Load prior context on this feature / activity

Before writing a new PIA, check the outputs folder for prior work on the same feature, processing activity, or counterparty. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Outputs` for the path. Scan for:

- **Prior `use-case-triage` results** covering this activity — the triage's risk rating, mandatory conditions, and called-out concerns are the entry point for the PIA.
- **Prior `pia-generation` outputs** for the same or an overlapping activity — a superseding PIA should reconcile (what changed, what carried over). A PIA that silently produces different conclusions than a prior PIA on the same activity is a contradiction a reviewing attorney cannot see.
- **Prior `dpa-review` outputs** for vendors in scope — the DPA review's findings inform the PIA's analysis of subprocessor / cross-border / retention risk.

If a prior output is found, cite it in the PIA:

> "Prior triage ([date]) rated this [risk level] and required [conditions]. This PIA builds on that finding — [which conditions are satisfied, which remain, which are re-scoped]."

If a prior PIA exists:
> "This PIA supersedes the [date] PIA because [reason — scope change, new data category, vendor change, regulatory change]. Conclusions carried over: [X]. Conclusions revised: [Y, because Z]."

**Carry severity from upstream as a floor** per the cross-skill severity floor rule in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Shared guardrails`. A use-case-triage that rated the activity high-risk cannot become a PIA that concludes low-risk without stating why and what changed.

If no prior output is found, say so explicitly — "No prior triage or PIA on this activity in outputs folder; this is a cold start" — so the reviewing attorney knows the check ran and didn't find anything to reconcile.

## Load house style

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## PIA house style`. That has:
- What triggers a PIA here (may not match regulatory DPIA triggers — some teams PIA everything, some only high-risk)
- The structure template extracted from the seed PIA
- Typical depth
- Who signs off

If the seed PIA structure is in the config CLAUDE.md, **use it**. The point is that this PIA looks like the other PIAs this team produces, not like a generic one.

## Step 0: Is a PIA needed?

Check the trigger criteria in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. That is the team's house answer.

In addition, **research the currently operative mandatory-assessment triggers** for each regime in the regulatory footprint (GDPR/UK GDPR DPIA triggers, CCPA/CPRA risk-assessment triggers, other US state data-protection assessment triggers, sectoral regimes). Cite the controlling statute, regulation, or regulator guidance with pinpoint references. Verify currency — assessment thresholds and definitions shift through new state laws, rulemaking, and enforcement guidance. Flag uncertainty rather than guess.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a regime's DPIA / risk-assessment triggers or lawful-basis rules, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / question]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation in the PIA with where it came from: `[Westlaw]`, `[regulator site]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the user supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

Beyond statutory mandates, treat these as **strong indicators** that a PIA is worth doing even if not strictly mandatory (research whether any of them independently triggers a mandatory assessment under the applicable regime):

- New technology or novel use of existing tech
- Children's data
- Combining datasets that weren't collected together
- Data that could enable discrimination
- Processing that users wouldn't expect

If no statutory trigger applies and the house trigger also isn't met → "Doesn't look like this needs a PIA. Here's a one-paragraph note for the file explaining why, in case anyone asks."

## The intake

Before writing anything, get answers to these from the product team. Conversational is fine — this isn't a form to send them.

### What and why

- What's the feature/product/change?
- What problem does it solve for users?
- What personal data does it touch? Be specific — "user data" is not an answer. Which fields?
- Is any of it new collection, or is it all data you already have?
- What's the processing — storage, analysis, sharing, automated decisions?

### Legal basis / regime-specific checks

For each applicable regime, **research the currently operative framework** for the question below and cite primary sources:

- Under regimes that require an identified lawful basis for processing (e.g., GDPR, UK GDPR), identify the basis for each purpose (contract / legitimate interest / consent / legal obligation / vital interests / public task / other). Research the specific requirements and any balancing-test or consent-standard expectations; cite controlling authority.
- Under regimes that regulate disclosures (e.g., CCPA/CPRA and other US state privacy laws), check whether any flow looks like a "sale," "share," or other regulated disclosure under the currently operative statutory definitions. Third-party advertising is a recurring trap — research whether it falls within the regulated category for the applicable regime.
- Under sectoral regimes (HIPAA, GLBA, COPPA, FERPA, etc.), research any regime-specific basis or disclosure rules.

Verify currency; statutory definitions and bases are amended often. Flag uncertainty for attorney verification.

### Who and where

- Who inside the company can see this data? Engineers? Support? Analysts?
- Any third parties? Vendors, partners, analytics?
- Where is it stored? Which region? New infrastructure or existing?
- How long is it kept? Is there a deletion schedule or does it live forever?

### What could go wrong

- If this data leaked, what's the harm to the person?
- Could this data be used to discriminate, even accidentally?
- Would users be surprised this is happening? (The "creepy test" — not a legal standard but a useful one.)
- Is there an opt-out? Should there be?

## Writing the PIA

**Use the seed PIA structure from the config CLAUDE.md.** If none was captured, use this default. Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# Privacy Impact Assessment: [Feature/Product Name]

**Prepared by:** [name] | **Date:** [date] | **Status:** DRAFT / APPROVED
**Product owner:** [name] | **Privacy reviewer:** [name]

---

## Executive summary

[Two sentences: what this is, whether it's okay. E.g., "Feature X collects
location data to provide Y. Processing is consistent with existing privacy
policy commitments and uses consent as lawful basis. Two mitigations
recommended below; no blockers identified."]

**Overall risk:** [Reviewer to set: 🟢 Low / 🟡 Medium / 🟠 High / 🔴 Very high]

---

## 1. Description of processing

**What:** [the feature, in plain English]
**Data categories:** [specific fields — not "user data"]
**Data subjects:** [customers / end users / employees / etc.]
**Purpose:** [why — tie to user benefit]
**New collection?** [yes — these fields are new / no — reusing existing data]

---

## 2. Lawful basis

| Purpose | Basis | Notes |
|---|---|---|
| [purpose 1] | [Contract / LI / Consent / etc.] | [if LI: balancing test summary; if consent: how obtained] |

---

## 3. Data flow

**Collection:** [how/where data enters]
**Storage:** [system, region, encryption]
**Access:** [who, via what controls]
**Sharing:** [third parties, purpose, governed by which DPA]
**Retention:** [how long, deletion mechanism]

---

## 4. Privacy policy consistency

| Policy commitment | Consistent? | Notes |
|---|---|---|
| [commitment from config CLAUDE.md privacy policy section] | 🟢 / 🟡 | |

[If any 🟡: policy update needed before launch, or processing needs to change]

---

## 5. Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation | Status | Owner |
|---|---|---|---|---|---|---|
| 1 | [specific risk, tied to the design — not "data breach" generically] | L/M/H | L/M/H | [specific control] | Done / Planned / Gap | [name] |

**Residual risk after mitigations:** [assessment]

---

## 6. Data subject rights

| Right | Can be exercised? | How |
|---|---|---|
| Access | | |
| Deletion | | |
| Correction | | |
| Portability | | |
| Objection | | |

---

## 7. Recommendation

[APPROVED / APPROVED WITH CONDITIONS / CHANGES REQUIRED / NOT APPROVED]

**Conditions (if any):**
- [ ] [specific thing that has to happen before launch]

**Sign-off:** [name, date]
```

## Risk quality standards

Risks in a PIA should be **specific and tied to the design**, not generic. Bad risks pad the document and train readers to skim.

| Bad risk | Why bad | Better |
|---|---|---|
| "Data breach" | Applies to everything; says nothing | "Location history accessible by support staff via the admin panel without audit logging — a malicious insider could track a user undetected" |
| "Non-compliance with GDPR" | Circular — the PIA is supposed to *assess* compliance | Name the specific article and the gap |
| "Users might not like it" | Vague | "Users who opted out of marketing may still receive this because the opt-out flag isn't checked in this flow" |

Aim for 2-5 real risks, not 15 padded ones.

## Privacy policy diff

Every PIA should cross-check against the privacy policy commitments in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. The common drift:

- Policy says "we collect X, Y, Z" — new feature collects W. Policy needs updating, or stop collecting W.
- Policy says "we don't sell data" — new feature shares with an ad partner. That might be a CCPA sale.
- Policy says retention is "as long as your account is active" — new feature keeps data post-deletion.

Flag every mismatch. One of them has to change before launch.

## Handoff

- **To product team:** Conditions list with owners and deadlines. Not "improve security" — "add audit logging to the admin panel's location lookup, owner: [eng lead], before launch."
- **To reg-gap-analysis skill:** If the PIA uncovered a policy inconsistency, that skill tracks the policy update.
- **To the sign-off process:** Per `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → who approves PIAs.

## Gate: submitting a DPIA to a regulator

Producing an internal PIA is research and documentation. *Submitting a DPIA to a supervisory authority* — or voluntarily disclosing one to a regulator in response to an inquiry — is the consequential act.

**Before proceeding to submit a DPIA (or any equivalent impact assessment) to a regulator, supervisory authority, or enforcement body:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Submitting to a regulator has legal consequences — the document becomes part of the supervisory record and any material omission or error becomes enforcement exposure. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: regime and regulator, why a submission is being made (mandatory trigger or voluntary), the risks identified, residual risk after mitigations, any flagged uncertainty, and the three things to ask the attorney before filing.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't approve the processing. A human signs the PIA.
- It doesn't write a DPIA for a supervisory authority — that's a more formal document with specific regulatory requirements. This is the internal assessment.
- It doesn't design the mitigation. It describes what needs mitigating; engineering designs the fix.$body$)
ON CONFLICT (skill_key) DO NOTHING;
