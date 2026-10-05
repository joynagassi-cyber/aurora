INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/ai-tool-handoff', 'legal', 'ai-tool-handoff', '', 'ai-tool-handoff', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# AI Tool Handoff

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Luminance and Kira are good at one thing: reading 500 contracts and finding every change-of-control clause. They're less good at judgment — deciding whether a particular CoC provision is actually triggered by this deal structure.

This skill hands off the bulk extraction to the right tool, then runs the QA layer on what comes back.

**Before you hand off:** try `tabular-review` first (`/corporate-legal:tabular-review`). For anything the user's environment can handle — a few hundred documents, a defined column schema — native tabular review is faster to set up, has no per-document cost, and keeps the work product local. Hand off to Luminance/Kira when the corpus is genuinely too large, the team already has a license and workflow, or the matter requires a tool with a validated provenance chain.

## Load context

`~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → AI-assisted review:
- Tool in use (Luminance / Kira / none)
- What it's used for (which clause types)
- Trust level (use as-is / spot-check / full re-review)
- Handoff process (who loads, who QAs)

If `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` says no AI tool → this skill is a no-op. Everything goes through diligence-issue-extraction directly.

## When to hand off

Hand off when all of:
- Category has >50 documents (below that, faster to just read them)
- Extraction target is a clause type the tool is good at (CoC, assignment, exclusivity, MFN, termination, auto-renewal)
- Documents are reasonably uniform (all customer contracts on similar paper — not a mix of contracts, letters, and board minutes)

Don't hand off:
- Bespoke or heavily negotiated documents
- Side letters and amendments (context-dependent, tools miss the interaction with the main agreement)
- Anything where the question is "what does this mean for the deal" not "does this clause exist"

## The handoff

### Step 1: Prepare the batch

- Identify documents for the batch (from VDR inventory)
- Specify extraction targets per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` (which clause types)
- Note the materiality threshold so tool output can be filtered

### Step 2: Load (or instruct the loader)

Per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` — who loads. If it's you, generate the load instructions. If it's someone else, generate the request:

```markdown
## [Tool] Load Request — [Deal code] — [Category]

**Documents:** [N] docs from VDR folder [path]
**Load to:** [Tool workspace/matter]
**Extraction targets:**
- Change of control / assignment
- Exclusivity
- [etc. per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`]

**Filter output:** Flag only where extraction target is present — no need for "no CoC clause found" for every doc.

**Return by:** [date]
```

### Step 3: QA the output

When the tool returns results, apply the trust level:

**"Use as-is":** Ingest directly into diligence findings. (Only if `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` says this — it's rare.)

**"Spot-check X%":** Randomly sample X% of flagged documents. For each, read the actual clause and compare to the tool's extraction. If error rate is low, accept the batch. If errors found, widen the sample.

**"Full human review of flagged":** Tool narrows the universe (500 docs → 80 with CoC clauses). Human reads all 80. Tool saved the time of reading the 420 clean ones.

### Step 4: Judgment layer

The tool found the clauses. Now apply judgment:

For each flagged CoC provision: is it actually triggered by this deal?
- Stock sale vs. asset sale vs. merger — different triggers
- "Change of control" defined how in the contract — majority ownership? board control? something else?
- Is there a carve-out for this type of transaction?

This is the part the tool can't do. Output goes to diligence findings in house format.

## Output

> The QA summary below is derived from VDR documents that are privileged, confidential, or both. It inherits the sources' privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. Store with the matter's privileged files.

```markdown
## AI Tool Handoff Summary — [Category]

**Tool:** [Luminance / Kira]
**Documents processed:** [N]
**Extraction targets:** [clause types]

### QA

**Trust level:** [per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`]
**Sample size:** [N] docs spot-checked
**Error rate:** [X]% — [Accepted / Widened sample / Full re-review triggered]

### Results

| Clause type | Docs flagged | After judgment layer | Material |
|---|---|---|---|
| Change of control | [N] | [N actually triggered by deal structure] | [N above threshold] |
| Assignment | [N] | [N] | [N] |

**→ [N] findings added to diligence issues**
**→ [N] consents added to closing checklist**
```

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't run Luminance or Kira — it manages the handoff and QA. A human (or the tool's own interface) runs the extraction.
- It doesn't replace the tool's output with its own judgment entirely — if `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` says spot-check 10%, check 10%, not 100%.
- It doesn't decide the trust level — that's in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`, set at cold-start based on the team's experience with the tool.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/board-minutes', 'legal', 'board-minutes', '', 'board-minutes', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Board Minutes

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Board minutes are a legal record. They need to be accurate, complete, and in a format that will hold up under scrutiny — whether that's a financing due diligence review, a regulatory inquiry, or an M&A data room. This skill drafts them in your house format so you spend your time reviewing and correcting, not formatting and re-typing.

## Load context

- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → `## Board & Secretary` section:
  - Minutes format (long-form narrative / action minutes / hybrid)
  - Minutes template extracted from seed documents (structure, resolution language, header format)
  - Board composition and committees
  - Written consents — what they're used for and any limits
- If `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` has no minutes format: run cold-start first. Do not proceed with a generic format.

---

## Step 1: Identify the meeting

### Calendar detection

If the calendar connector is authorized, search for upcoming events matching board and committee keywords:

**Search terms:** "Board of Directors", "Board Meeting", "Audit Committee", "Compensation Committee", "Comp Committee", "Nominating", "Nom/Gov", "Governance Committee", "Special Committee", "Board of Directors — [Company]"

**Time window:** Look 30 days forward. If no upcoming meeting is found, look 14 days back (minutes are often drafted after the fact).

Present what you find:

> I found the following board or committee meetings on your calendar:
>
> 1. **[Meeting name]** — [Date], [Time], [Location/Virtual]
> 2. **[Meeting name]** — [Date], [Time], [Location/Virtual]
>
> Which one are these minutes for? Or is it a different meeting not on here?

If the calendar connector is not authorized or returns nothing: ask directly — what meeting, what date, what type (full board / which committee)?

### Meeting metadata to confirm

Once the meeting is identified, confirm or fill in:

- **Meeting type:** Full Board of Directors / [Committee name]
- **Date and time**
- **Location or platform** (in-person address / Zoom / Teams / telephonic)
- **Called by / Notice:** Was proper notice given? (Yes / waived — waiver of notice is a common exhibit)

---

## Step 2: Attendance

Ask for the attendee list, or offer to pull from the calendar invite if the connector is authorized.

**Directors present:**
- Pull from board composition in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` as the starting point
- Ask who was actually present, who was absent, and whether any absent directors had advance notice

**Management present:**
- Who from management attended? (CFO, CAO, CTO, etc.)
- Note: management attendees are typically listed separately from directors

**Guests:**
- Outside counsel present? (Name and firm)
- Investment bankers, auditors, or other advisors?
- Any guests who attended for specific agenda items only (note their attendance as limited to that item)

**Chair:**
- Who chaired the meeting?
- Who acted as secretary?

**Quorum:**

- Check the charter and bylaws for the quorum requirement. If the charter is silent, research the applicable state corporate law for the default rule for this entity type. Record what you confirmed (source and pinpoint) in the drafting notes.
- Confirm quorum was present. If not: stop and flag before drafting. Do not produce minutes that imply a valid meeting occurred. Surface the question to outside counsel — the remediation path (ratification, re-meeting, written consent, other) depends on the state of incorporation and the nature of the action.

---

## Step 3: Materials

Ask for the meeting materials. These are the source for the agenda items and any resolutions.

> Can you share the agenda and any pre-read materials for this meeting? Even a rough agenda is enough to structure the minutes. If there were board slides or a management presentation, upload those too — I'll use them to fill in the agenda item summaries.
>
> If materials weren't distributed in advance, tell me the agenda items and I'll draft placeholders for each.

**From the agenda and slides, extract:**
- Agenda items in order
- Any resolutions proposed (look for board approval language: "approve," "authorize," "ratify," "adopt," "elect")
- Any exhibits referenced (management presentations, financial reports, legal memos, valuations)
- Any votes expected

**If no materials:** Ask for the agenda items verbally and proceed with placeholders for discussion content.

---

## Step 4: Draft the minutes

Use the house format from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. Do not default to a generic format. The seed minutes are the template — replicate the structure, the header, the resolution language, the level of discussion detail.

### Standard structure (adapt to house format)

**Header block:**
```
MINUTES OF [MEETING TYPE] OF THE BOARD OF DIRECTORS
[OR: MINUTES OF THE [COMMITTEE NAME] OF THE BOARD OF DIRECTORS]
OF [COMPANY NAME]

[Date]
[Location / Telephonic / Video Conference]
```

**Opening:**
- Meeting called to order by [Chair name] at [time]
- Notice: [proper notice given / notice waived — attach waiver as exhibit if applicable]
- Quorum confirmed: [N of M directors present]
- Secretary: [name]

**Attendees:**
- Directors present: [list]
- Directors absent: [list, if any]
- Also present: [management, outside counsel, guests — with roles]

**Previous minutes:**
Standard language: approval of minutes from prior meeting. Pull date of prior meeting from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` board calendar if available, otherwise leave as [DATE OF PRIOR MEETING].

**Agenda items — one section per item:**

```
[AGENDA ITEM TITLE]

[Chair/presenter name] [presented / reported on / led a discussion of] [topic].

[Discussion summary — see drafting notes below]

[If resolution follows:]
Upon motion duly made and seconded, the following resolution was adopted [by unanimous vote / by a vote of N for, N against, N abstaining]:

RESOLVED, that [resolution text in house language from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`].
```

**Adjournment:**
Standard language: meeting adjourned at [time], there being no further business.

**Signature block:**
Secretary signature line. Some formats include a chair countersignature.

---

### Drafting notes

**Discussion summaries:** The hardest part of minutes is deciding how much discussion to capture. Follow the house format from seed documents exactly:

- *Long-form narrative:* Summarise the substance of the discussion — what questions were raised, what information was presented, what factors the board considered. Do not quote individuals unless the specific attribution matters legally.
- *Action minutes:* Note only what was presented and what action was taken. No discussion content beyond "the board discussed the matter."
- *Hybrid:* Full narrative for major items (acquisitions, financials, significant approvals), action-only for routine items.

When materials were provided: pull summary content from the slides and management presentation. The board "received and reviewed" a presentation — summarize what the presentation covered.

When no materials: insert `[PLACEHOLDER — summarize discussion here]` and flag it clearly. Do not fabricate discussion content.

**Resolutions:** Use the exact resolution language from the seed minutes — "RESOLVED, THAT" vs. "BE IT RESOLVED" vs. "RESOLVED" alone. The language is house style, not interchangeable.

**Exhibit references:** Number exhibits in the order they appear (Exhibit A, B, C). Common exhibits: management presentation, financial statements, valuation reports, legal opinions, waivers of notice, consents.

---

## Step 4.5: Consequential-action gate (adopt minutes)

**Before adopting minutes as final:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Adopting minutes makes them the official record of what the board decided — they're the primary evidence of authorization for the actions taken at the meeting. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - What was decided (resolutions, votes, who was present)
> - What the draft captures and what is still a placeholder
> - Open questions (any flagged attendance, quorum, or conflict notes)
> - What could go wrong (misstated resolutions, missing disclosures, quorum defects, privilege leakage in discussion summaries)
> - What to ask the attorney (is the discussion depth right for this board's practice; are exec-session notes properly segregated; do any items need more documentation)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not produce the final adoption-ready version past this gate without an explicit yes. A marked-DRAFT for attorney review is fine.

---

## Step 5: Output and review prompts

Produce the full draft. The minutes themselves are a corporate record, not privileged; do not apply the work-product header to the minutes as circulated. The drafting notes, placeholder flags, and review checklist below are work product — prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`):

```
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]
```

After the draft, add a review checklist:

```
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

REVIEW CHECKLIST — please verify before circulating:

□ All directors confirmed present/absent (check against actual attendance)
□ Quorum confirmed correct
□ Resolution language matches what was actually approved (check wording carefully)
□ Votes recorded correctly — any abstentions or dissents to note?
□ Exhibits numbered and referenced correctly
□ Any executive sessions held? (Add separate executive session note if so)
□ Any conflicts of interest disclosed? (Director recusal to note if applicable)
□ Time of adjournment to fill in
□ Outside counsel reviewed? (If required by your process)
```

Flag any sections where content is a placeholder and needs the attorney's input before the minutes are accurate.

Add as a final pre-adoption note on the draft, stripped before adoption:

> This is a draft for attorney review, not adopted minutes. Adopted minutes are the official record of board action and carry legal consequences — a licensed attorney reviews, edits, and takes professional responsibility before adoption. Do not adopt this draft unreviewed.

---

## Written consents

For drafting written consents in lieu of a meeting, use `/corporate-legal:written-consent`. That skill handles precedent search, state-law confirmation, and the scope warning for major one-off actions.

---

## What this skill does not do

- It does not attend the meeting or capture real-time discussion — it drafts from materials and attorney input.
- It does not determine whether a resolution is legally valid or sufficient — it drafts in house format; legal judgment on adequacy is the attorney's call.
- It does not finalize minutes — the draft requires attorney review before circulation.
- It does not distribute minutes — output is for the attorney to review, edit, and circulate via their own process.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/closing-checklist', 'legal', 'closing-checklist', '', 'closing-checklist', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /closing-checklist

1. Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/closing-checklist.yaml` and use the modes below.
2. If status update provided: Mode 3 (update item).
3. Otherwise Mode 4: blocking items, critical path, days to close.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Deals close when the checklist is done. Everything on it, done. Nothing missing. This skill maintains the list, ingests new items as they surface from diligence, and tells the team what's blocking.

## The checklist

Lives at `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/closing-checklist.yaml`. Structure:

```yaml
deal_code: "Project Falcon"
target_close: [DATE]
signing_date: [DATE]
last_updated: [DATE]

conditions_precedent:
  - id: CP-001
    item: "HSR waiting period expiration"
    category: "Regulatory"
    responsible: "Buyer counsel"
    due: 2026-04-15
    status: "Filed 2026-03-01, waiting period runs"
    blocking: true
    source: "Purchase Agreement §7.1(a)"

  - id: CP-002
    item: "Acme Corp consent to assignment"
    category: "Third-party consents"
    responsible: "Target — Jane Doe"
    due: 2026-04-20
    status: "Request sent 2026-03-10, no response"
    blocking: true
    source: "Schedule 3.12(a)(4); Acme MSA §14.2"

closing_deliverables:
  - id: CD-001
    item: "Certificate of good standing — Target (DE)"
    category: "Corporate"
    responsible: "Target counsel"
    due: 2026-04-28
    status: "Not started"
    blocking: true
    source: "Purchase Agreement §2.3(b)(iv)"

  # ... etc
```

## Modes

### Mode 1: Initialize from the purchase agreement

Read the signed (or near-final) purchase agreement. Extract:

- Every condition precedent (location varies by agreement — read the actual section headings)
- Every closing deliverable (closing deliverables schedule or corresponding section)
- Every covenant with a pre-closing deadline

Each becomes a checklist item with a source cite to the agreement section.

**Research obligations before populating regulatory/approval items.** Antitrust, foreign-investment, and sector-specific approvals (for example, HSR-style filings, CFIUS, industry regulators) have jurisdiction-specific mechanics, thresholds, and timing windows that change. Extract the name of each regulatory condition from the PA, then research the currently operative mechanics (who files, when, what triggers a second request, what the waiting period is). Cite primary sources and verify currency. Do not populate a timing assumption from memory.

**Material-adverse-effect / material-adverse-change closing conditions.** Pull the defined term from the PA — MAC/MAE framing is negotiated, not a standard. Research the governing-law interpretation of the specific language used (Delaware, New York, and other jurisdictions treat carve-outs and quantitative tests differently) before flagging an event as a potential MAC trigger.

**Consent-requirement extraction from material contracts** depends on governing-law default rules and the specific anti-assignment language in each contract. Research the applicable rule per contract rather than assuming a default.

### Mode 2: Ingest from diligence (the "self-updating" part)

Mode 2 is triggered when an upstream skill produces a finding with a pre-closing action. The upstream skills and output types this mode ingests:

- **`diligence-issue-extraction` findings** — any finding flagged for a closing action (consent, shareholder vote, board resolution, regulatory filing, release, escrow mechanic, pay-off letter). Not just "consents" — see the extraction skill's Handoffs section for the full list.
- **`material-contract-schedule` CoC / assignment items** — change-of-control provisions, anti-assignment clauses, MFN triggers surfaced during schedule build.
- **`deal-team-summary` output** — the exec-tier brief aggregates extraction findings and sometimes surfaces a closing-action item that a mechanical read of the individual extraction memos would miss (e.g., a §280G cleansing vote rolled up across multiple employment agreements, or a composite consent package). Mode 2 reads the latest deal-team-summary in the deal folder and reconciles its closing-action items against the checklist. Anything flagged by deal-team-summary as requiring pre-closing action that is not already on the checklist is appended.

The handoff schema covers the full range of pre-closing actions, not just consents:

```yaml
handoff:
  # Required fields
  item: "[Counterparty or action, one line]"
  category: "[Third-party consents | Shareholder / board action | Regulatory filing | Release / termination | Escrow / holdback | Closing deliverable]"
  source: "[Contract name / statutory section / VDR path + Bates]"
  blocking: true  # unless the agreement has a materiality qualifier
  severity: "[🔴 / 🟠 / 🟡 / 🟢 — carried from upstream, see severity-floor rule in CLAUDE.md]"

  # Consent / third-party action fields
  counterparty: "[e.g., Dunmore Holdings LLC]"
  guarantor: "[e.g., Buyer parent guaranty required, or N/A]"
  conditions: "[any substantive condition the counterparty attached — e.g., 'replacement guaranty from buyer parent required before consent effective']"
  notice_deadline: "[e.g., 30 days prior to closing, or specific date]"

  # Corporate action fields
  approval_body: "[Shareholders | Board | Committee | Regulator]"
  approval_threshold: "[e.g., 75% disinterested stockholder vote for §280G cleansing]"
  statutory_or_charter_source: "[e.g., IRC §280G(b)(5)(B); Charter Art. IV §2]"

  # Timing
  estimated_time_to_complete: "[e.g., 30 days]"
  must_occur_before: "[e.g., closing | signing | end of hiatus period]"
```

Preserve every field the upstream skill populated. A "Dunmore consent required, with replacement guaranty condition and 30-day notice" should surface on the checklist with all three elements (consent, guarantor, notice), not collapse to "Dunmore consent to change of control." When the upstream skill provides a severity, carry it — see the cross-skill severity floor rule in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`.

Append to the checklist. De-dupe on (counterparty + action type), not on the freeform item name — a Dunmore consent and a Dunmore release are different items even though both name Dunmore. When de-duping, merge fields rather than overwrite: if one handoff populated `guarantor` and a later handoff populated `notice_deadline`, the checklist row carries both.

### Mode 3: Status update

User (or dataroom-watcher agent) provides a status update. Find the item, update status and last-updated.

```
/corporate-legal:closing-checklist
CP-002: Acme responded, consent form attached, needs countersignature
```

### Mode 4: What's blocking

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> This status report is derived from the purchase agreement, diligence findings, and internal deal records. It inherits their privilege and confidentiality status — distribution beyond the privilege circle (counterparty, broader business teams) can waive privilege. Confirm the distribution list before sending.

## Closing Checklist Status — [Deal code] — [date]

**Target close:** [date] ([N] days out)
**Items:** [N] total — [N] done, [N] in progress, [N] not started

### 🔴 Blocking and at risk

| ID | Item | Due | Status | Days to due |
|---|---|---|---|---|
| [CP-XXX] | [item] | [date] | [status] | **[N]** |

### 🟡 Blocking, on track

[same table]

### ✅ Complete

[N] items — [collapsed list]

### Not blocking (post-closing, informational)

[N] items

---

**Critical path:** [The item(s) that, if they slip, push the close date]
```

## Critical path analysis

Not all blocking items are equal. A consent that takes 30 days to get is critical path. A good-standing certificate that takes 2 days is not, even though both are blocking.

For each blocking item, estimate time-to-complete. The ones where `(due date - today) < estimated time` are at risk. Those go at the top of every status report.

If the checklist has more than ~10 items, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by status (done / in progress / not started / at risk), a critical-path view grouped by workstream, and a sortable grid with item, owner, due date, and days-to-due.

## Integration: dataroom-watcher agent

The agent checks the checklist daily, pulls any status updates from email/Slack if connected, and posts the "what's blocking" report to the deal team channel. Mode 4 is the agent's output.

## Consequential-action gate (certify closing)

**Before producing a "ready to close / all CPs satisfied" certification or closing memo:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Certifying that closing conditions have been satisfied (or producing a closing memo asserting this) has legal consequences — it's the signal that drives funds flow and post-closing obligations. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - The full CP list with status (what's done, what's in progress, what's not started)
> - Anything where evidence of completion is weak or missing
> - Any waivers or side letters needed for items that won't close in time
> - Open questions (counterparty consents still pending, any MAC/bring-down risk)
> - What to ask the attorney (is this ready to call closed; are any conditions being walked past that shouldn't be; what needs to go on a schedule of exceptions)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not produce a final "ready to close" certification past this gate without an explicit yes. Status tracking and "what's blocking" reports do not require the gate.

---

## What this skill does not do

- It doesn't obtain consents, file forms, or draft documents. It tracks that they need to happen.
- It doesn't decide what's blocking — the purchase agreement decides that. This skill reads the agreement.
- It doesn't close the deal. It tells you when you can.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If `--new-deal`, skip to per-deal setup. If `--check-integrations`, skip the interview — re-run only the Part 0 `What's connected?` check and rewrite the `## Available integrations` table in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.
2. Run the interview below (Part 0 first — role + integrations — then modules).
3. Seed docs: diligence request list + one prior issues memo.
4. Extract: categories, thresholds, memo format, AI tool config.
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/corporate-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and tell the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` (create parent directories as needed). For `--new-deal`, write `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md`.

---

## Purpose

Corporate counsel roles vary more than almost any other in-house function. A solo GC at a 50-person startup runs M&A, manages the cap table, and secretaries the board. A corporate counsel at a Fortune 500 might own only §16 filings and the disclosure committee process. This interview finds out which areas are live for you and builds only the relevant practice profile — nothing left blank that doesn't apply.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo` or `--module [name]`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/corporate-legal/*/CLAUDE.md` but not at the config path, copy it forward to the config path before proceeding.

- `--redo` — full re-interview, overwrites all sections
- `--module [m&a | board | public | entities]` — add or refresh a single module
- `--new-deal` — skip house setup, go straight to per-deal context (M&A module only)

---

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

> **`corporate-legal` is for people who support M&A deals, board and corporate governance, public company compliance, and entity management.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, practice setting, jurisdiction, and module selection (M&A, board, public, entity management), plus working defaults for materiality thresholds, issues-memo format, board-minutes format, and disclosure-schedule format. **15 minutes** adds your real materiality thresholds, house consent and minutes formats from seed documents, your entity list and compliance cadence, deal-team briefing cadence, and escalation matrix.
>
> Quick or full? (Upgrade any time with `/corporate-legal:cold-start-interview --full`.)

Wait for the user's pick before showing anything else.

<!-- COLLATERAL LINKS: when onboarding collateral exists, prepend a line above the preamble:
     "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL), then come back and run /corporate-legal:cold-start-interview." -->

## After the user picks quick or full

Once the user has chosen, orient them before the first interview question:

> "This plugin maintains your practice profile (materiality thresholds, consent style, board format), per-deal folders with diligence grids, closing checklists, disclosure schedules, and a compliance calendar. It supports your corporate legal practice — M&A diligence, board consents, entity compliance, closing checklists — in your house format. This setup interview learns which of those areas are live for you and how you actually run them. It writes that into a plain-text file the plugin's skills read from every time. Everything you answer can be changed later. Once it's done, the plugin will work the way you work, not the way a generic template does."
>
> Then: "Ready? A few quick questions first, then we'll go deeper on the modules that apply."

**Why this matters.** Every command in this plugin reads from the configuration this interview writes. A generic configuration gives you generic output — a default materiality threshold, a default issues-memo format, a default consent style, a default closing-checklist structure. Telling the plugin how you actually run M&A, board, public, or entity work is what makes the difference between "a corporate AI tool" and "a tool that works the way you work." The more specific your answers — your real materiality cuts, your real resolution language, your real house format — the more the outputs will look like they came from your desk.

**Fresh professional profile.** Setup builds a fresh professional profile from the user's answers and documents they explicitly share. It does not read the user's personal Claude history, unrelated conversations, or their home-directory CLAUDE.md. If something relevant surfaces in the current conversation context (e.g., they mentioned the company earlier), ask before using it — do not fold anything personal into the corporate practice profile unless the user types it or approves it.

Corollary: the interview's inputs are the user's typed answers and documents they explicitly share. Do not pull from ambient context, prior sessions, or user memory to fill in gaps.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Pause for real answers.** Some questions are quick (entity type, exchange, fiscal year end). Others need the user to type, describe, or upload (prior issues memo, board minutes, consent precedent, org chart). When a question needs more than a quick tap:

- **Ask and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For uploads (issues memo, minutes, consents, org chart):** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait. These seed documents drive format extraction — skipping silently means every future output will be in a generic template instead of house format.
- **Before writing the practice profile:** review the interview and list any questions that were skipped or answered with placeholders — especially the seed documents per active module. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the user made to skip, not a question that scrolled past.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/corporate-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /corporate-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

---

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> Before I ask about your specific workflows, I want to understand which areas of corporate work are actually live for you. That way I only set up what you need and skip the rest.

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and which modules are active. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for materiality thresholds, disclosure schedule format, and board-minutes format. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/corporate-legal:cold-start-interview --full` anytime to do the whole interview, or `/corporate-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

---

### Part 0: Who's using this, and what's connected

Three quick questions before we get into corporate specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every memo, consent, minutes draft, and diligence memo — lawyer outputs get the privilege header, non-lawyer outputs get the "research notes, review with counsel" header.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — founder, business lead, contracts manager, HR, procurement; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "GREEN — sign it," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — signing a contract, terminating someone, sending a demand, filing something, clearing a launch, responding to a regulator. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) — most offer a lawyer referral service as the fastest starting point. Many offer free or low-cost initial consultations. For small businesses, local law school clinics (and equivalents like SCORE mentors in the US) can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### What's connected?

> This plugin can work with: VDR (Intralinks, Datasite, Box), board portal (Diligent, BoardEffect), document storage, and Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.] If you set this up later, re-run `/corporate-legal:cold-start-interview --check-integrations`.
>
> You don't need all of these. Core features work with file access alone.

#### Practice setting

Ask once, early, so Part 1 (company profile) and every module's escalation question branch correctly:

> Practice setting? (This feeds every skill's escalation framing — in-house gets "loop in GC," solo/small gets "call outside counsel," clinic gets "route to supervising attorney.")
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

Branching notes:

- **Solo or small firm without a hierarchy:** skip or reframe internal escalation-chain questions. Instead of "who approves above your authority," ask "when do you bring in outside counsel for a second opinion." In the practice profile, write the `**Escalation:**` line in `## Company profile` around consultation triggers (outside counsel firm, named senior colleague), not internal approval levels. In the M&A module, the "deal lead" question still applies.
- **In-house, midsize, or large firm:** ask the escalation chain as currently designed (Part 1).
- **Legal aid / clinic:** route toward a supervision-model framing — who supervises, when does a matter go up to the supervising attorney?
- **Government:** adapt — approval chain inside the agency/office.

Record this on a `**Practice setting:**` line in `## Company profile`.

#### Write to the config

Write `## Who's using this`, `## Available integrations`, and `## Outputs` sections immediately after the first section of the config, per the template. These drive work-product header choice and feature-fallback behavior across every skill in this plugin.

---

### Part 0.5: Module selection (1–2 min)

Ask which of the following apply. More than one is common. All four is not unusual for a GC.

> Which of these are part of your regular work? (This determines which sections get built in your practice profile and which skills light up — picking only M&A skips the board, public company, and entity management interviews entirely.)
>
> 1. **M&A** — deals: buying, selling, investing, or divesting business units
> 2. **Board & Secretary** — board meeting prep, minutes, resolutions, committee management
> 3. **Public Company** — SEC reporting, disclosure committee, §16 filings, insider trading
> 4. **Entity Management** — subsidiary management, registered agents, cap table, annual filings
>
> Tell me the numbers that apply. You can always add a module later with `/corporate-legal:cold-start-interview --module [name]`.

Record active modules. Proceed to the section for each active module only. Skip the rest entirely.

---

### Part 1: Company profile (2 min, always)

These questions apply regardless of which modules are active.

> Before I ask the structured questions: do you have a delegation-of-authority policy, a board-approved authority matrix, or a prior corporate-governance memo I can read? Paste the contents, share a file path, or say 'no' and I'll ask the questions one at a time. If you share one, I'll extract the approval levels and escalation points rather than making you re-type them.

If the user uploads: read it, extract company identity, legal-team size, and escalation/authority structure, confirm what you found, and skip the corresponding detailed questions.

If not:

> **What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription).

- What's the company name (or the name you want to use in outputs)?
- What industry are you in?
- Private, public, or a subsidiary of a public company?
- Primary jurisdiction of incorporation?
- How big is the legal team — just you, or a team?
- "When a review finds something that needs someone more senior to sign off — a novel issue in diligence, a materiality threshold decision, a consent matter with director conflicts, a schedule item that needs judgment, or a decision that's above your authority — who does that go to? Give me a name or a role (the GC, your partner, the deal lead), or say 'I decide myself.' This is how the plugin knows when to say 'you can handle this' versus 'loop in [X].' (This feeds /diligence-issue-extraction, /material-contract-schedule, /written-consent, and every other skill's escalation routing.)"

**If the user didn't upload a delegation of authority:** at the end of this section, offer: "Want me to write your escalation and authority lines up as a standalone delegation-of-authority note you can share and maintain? Same content I just captured, in a format you can circulate."

Write to `## Company profile` in the config.

---

### Part 2M: M&A module (4–6 min, if active)

#### 2M-a: Deal posture

- Buy-side, sell-side, or both? Note: most companies have experienced both over time, so this sets the default for house setup — the per-deal flag (`--new-deal`) captures the actual side for any live deal.
- Serial acquirer with a standard playbook, or does each deal get designed from scratch?
- Who runs deals on your end — corp dev, legal, outside counsel as lead, or a mix?

#### 2M-b: Diligence structure

> Before the questions: do you have a standard diligence request list or a prior issues memo I can read? Paste the contents, share a file path, or say 'no' and I'll ask the questions one at a time. If you share them, I'll extract the category structure, materiality thresholds, and house format and skip the corresponding questions.

If not:

- Do you have a standard diligence request list? How is it organized — by function (legal/finance/HR) or by document type?
- What's your materiality threshold for contract review? (All contracts? Above $X? Top N by revenue?) (This feeds /diligence-issue-extraction and /material-contract-schedule — the threshold decides which contracts get full review and which get triaged.)
- What's your usual VDR — Intralinks, Datasite, Box, SharePoint, something else?
- Do you use AI-assisted review tools — Luminance, Kira, anything else? For what specifically?

**If the user didn't upload a request list or prior issues memo:** at the end of this module, offer: "Want me to draft a starter diligence request list and issues-memo skeleton in your format? I'll base them on what you told me about materiality and category structure. You can edit and reuse on the next deal."

#### 2M-c: Issues memo format

> Two things I need:
>
> 1. Your standard diligence request list — the one you use on the buy side, or expect to see on the sell side.
> 2. One prior deal's issues memo — a closed deal, nothing live. I want to see how you structure findings: what you call things, how you categorize issues, what severity scheme you use, what depth you write at.
>
> These two documents become the backbone. Your categories, your format, your standards — not a generic template. (These feed /diligence-issue-extraction — the skill reuses your section structure, severity scheme, and finding template on every future deal.)

From the request list, extract: category structure, materiality thresholds if stated, standard carve-outs.
From the issues memo, extract: section structure, severity scheme, finding format, depth, who it's addressed to.

#### 2M-d: Sell-side specifics (if sell-side is active)

If the attorney works sell-side at all, ask these additional questions:

- When you're preparing a data room, who decides what goes in?
- Do you prepare a disclosure memo or issues log anticipating what the buyer will flag?
- Who do you coordinate with on the business side for data room population — corp dev, CFO, functional heads?

Sell-side is about anticipating the buyer's findings and managing information flow outward, not reviewing inbound documents. This shapes how the diligence-issue-extraction skill behaves when sell-side context is set.

#### 2M-e: Closing checklist and deal team briefing

- Where does the closing checklist live — Excel, Smartsheet, a deal management tool?
- Who owns updates to it?
- How do you brief the deal team — daily, weekly, milestone-based? Email, Slack, call?
- What does the business side actually read versus what's for the file?

Write to `## M&A` in the config.

---

### Part 2B: Board & Secretary module (3–4 min, if active)

- What's your formal role — corporate secretary, assistant secretary, or do you act in an advisory capacity without the formal title?
- How big is the board, and what's the composition — mostly independent directors, insider-heavy, classified board?
- Which committees exist? (Audit, Compensation, Nom/Gov, Strategy, anything else?)
- What tool do you use for board materials — Boardvantage, Diligent, BoardEffect, just email, nothing formal?
- How many regular board meetings per year, and roughly what months?

**Minutes:**
- Long-form narrative minutes, action minutes, or something in between?
- How quickly do you turn minutes around after a meeting?
- How do they get approved — circulated for written comments, or ratified at the next meeting?

**Written consents:**
- Do you routinely use written consents in lieu of meetings? For what types of board or committee action — routine officer appointments, equity grants, annual actions, or more broadly?
- Any limits on what can be approved by consent versus requiring a meeting (charter restrictions, committee charters, or just practice)?

**Seed minutes (required for board-minutes skill):**

> Upload 5–6 prior board or committee minutes. Closed meetings only, nothing currently active. These teach the skill your house format — how minutes are structured, what level of discussion detail you capture, how resolutions are worded, how attendance is recorded. One full-board set and one committee set if you have both formats. (This feeds the board-minutes skill — every future minutes draft is built from your extracted structure, discussion depth, and resolution language.)
>
> If you don't have shareable minutes right now, you can add them later with `/corporate-legal:cold-start-interview --module board`. The board-minutes skill will prompt you for them if they're missing.

From the seed minutes, extract:
- Overall structure and section order
- Header format (company name, meeting type, date, location)
- Attendance recording format (directors present/absent, management, guests)
- Discussion depth — long-form narrative, action minutes, or hybrid
- Resolution language (exact phrasing: "RESOLVED, THAT" / "BE IT RESOLVED" / other)
- Exhibit referencing convention
- Signature block format
- Any standard recitals or boilerplate that appears in every set

Write extracted format as a `**Minutes template:**` block in `## Board & Secretary` in the config.

**Consents repository (required for written-consent skill):**

> Do you have a folder or repository where executed written consents are stored? (This feeds /written-consent — the skill searches the repository for the closest prior consent and uses it as the substantive starting point, not just for format but for specific resolution language already approved for that type of action.)
>
> If you have one: tell me where it lives (folder path, Google Drive folder, SharePoint library, Box folder). The skill will search it at runtime.
>
> If you don't have a centralized repository: upload 3–5 prior consents now for format learning. The skill will still work — it just won't have precedent search capability until a repository is set up.

From the repository or seed consents, extract:
- House resolution language (exact phrasing: "RESOLVED, THAT" / "BE IT RESOLVED" / other)
- Recital structure (WHEREAS / NOW, THEREFORE depth and style)
- Authorisation language (officer delegation language at the end)
- Counterparts and electronic signature language (if present)
- Signature block format

Write to `## Board & Secretary` → `**Consents repository:**` and `**Consent format:**` in the config.

**Annual governance cycle:**
- What annual items do you manage? (Director elections, auditor ratification, equity plan approvals, say-on-pay if public, annual board self-assessment — whatever applies to you.)

Write to `## Board & Secretary` in the config.

---

### Part 2P: Public Company module (3–4 min, if active)

- What exchange are you on — NYSE, Nasdaq, other?
- What's your fiscal year end?
- What's your filer status — large accelerated, accelerated, or non-accelerated?

**Disclosure committee:**
- Do you have a formal disclosure committee? Who's on it — CFO, CAO, IR, Legal, others?
- How often does it meet — quarterly pre-earnings, or as needed?

**§16 reporting:**
- Who tracks §16 filer transactions — you, outside counsel, IR, or a combination?
- What's your internal target for getting Form 4 filed? (SEC requires 2 business days; internal targets are often tighter.)
- Does your insider trading policy require pre-clearance? Who approves?

**Insider trading policy:**
- When are your trading windows open relative to earnings?
- Who is covered by pre-clearance requirements — all officers and directors, or a broader list?
- What's the process for a blackout exception if one is ever needed?

**Earnings call:**
- What's legal's role in earnings call prep — reviewing scripts, preparing Q&A, something else, or no direct role?
- How far in advance of the call are you typically involved?

Write to `## Public Company` in the config.

---

### Part 2E: Entity Management module (2–3 min, if active)

> If you have an org chart or entity list — even a rough one, even a spreadsheet — upload it now. I'll read it and extract the entity structure, jurisdictions, ownership percentages, and entity types. That's faster and more accurate than answering these questions from memory. (This feeds /entity-compliance — the skill initializes the compliance calendar from this list and surfaces annual-report and registered-agent deadlines.)
>
> If you don't have one handy, answer the questions below and I'll build a starter entity table from your answers.

**From uploaded org chart or entity list, extract:**
- Entity names and entity types (Corp, LLC, Ltd, branch, etc.)
- Jurisdiction of formation for each
- Ownership chain and percentages
- Any entities flagged as dormant or inactive

**If no upload, ask:**

- How many active legal entities are you managing, roughly?
- What are the key jurisdictions — just Delaware, or a meaningful multi-jurisdiction footprint?
- Who's your registered agent — CT Corp, National Registered Agents, in-house, or varies by jurisdiction?
- Do you use an entity management system — Athena, Kira, Blueprint — or are you working off a spreadsheet?
- What's your cap table situation — Carta, Shareworks, Ledgr, or still manual? (Or not applicable if wholly owned with no external equity.)
- Who owns routine filing work — annual reports, foreign qualifications, registered agent renewals? Legal, legal ops, or does the registered agent handle it automatically?
- Do your subsidiaries have their own governance cadence, or are they effectively dormant holding companies?
- Do you have intercompany agreements in place — services agreements, IP licenses, loans?

Write to `## Entity Management` in the config.

---

### After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in corporate and M&A practice:**
>
> - **Extract diligence issues from the VDR** — e.g., "Point at a VDR folder and get findings categorized per your house materiality thresholds." Try: `/corporate-legal:diligence-issue-extraction`
> - **Build the material contracts schedule** — e.g., "From diligence findings, build the disclosure schedule in the purchase agreement's format." Try: `/corporate-legal:material-contract-schedule`
> - **Draft a board or committee written consent** — e.g., "Precedent search from your consents repository, then drafted in house format." Try: `/corporate-legal:written-consent`
> - **Entity compliance tracker** — e.g., "See what filings are due in the next 30 / 60 / 90 days across your subsidiaries." Try: `/corporate-legal:entity-compliance`
> - **Closing checklist status** — e.g., "What's left to close — conditions, documents, consents, filings — with critical path." Try: `/corporate-legal:closing-checklist`
> - **Post-closing integration** — e.g., "Phased workplan, consent tracking, contract assignment at scale for a just-closed deal." Try: `/corporate-legal:integration-management`
>
> **My suggestion for your first one:** If you have an active deal, run `/corporate-legal:closing-checklist` — it shows immediately where the plugin fits in your workflow. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


**Research connector prompt.** Before showing the active modules, say:

> "Before your first diligence extraction or consent: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you."

Then show the active modules and the populated sections:

> Here's what I've captured: [list active modules]. Practice Profile is written. A few things to check:
> - [Flag any thin or ambiguous answers worth revisiting]
> - [If M&A active and no seed docs provided: "Ping me with your request list and a prior issues memo when you have them — I'll update the diligence structure and memo format sections."]
> - [If M&A active: "When a deal comes in, run `/corporate-legal:cold-start-interview --new-deal` to set up deal-specific context on top of the house approach. M&A skills available now: diligence extraction, deal team summaries, material contracts schedule, closing checklist, and post-closing integration."]
> - [If Board & Secretary active: "Board skills available now: `/corporate-legal:written-consent` for written consents, and the board-minutes skill for drafting minutes in your house format."]
> - [If Entity Management active: "Entity skill available now: `/corporate-legal:entity-compliance` initializes a compliance tracker from your entity list and surfaces what's due."]
> - [If Public Company active: "Public Company skills are coming in a future release — the practice profile section is ready to populate when they ship."]

Close with a note on changeability:

> "Your practice profile is at `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` — it's a plain text file you can read and edit directly. Anything you answered can be changed:
>
> - Edit the file directly for a quick change (a new threshold, a jurisdiction added, a committee renamed)
> - Run `/corporate-legal:cold-start-interview --redo` for a full re-interview
> - Run `/corporate-legal:cold-start-interview --module [m&a | board | public | entities]` to add or refresh one module
> - Run `/corporate-legal:cold-start-interview --check-integrations` to re-check what's connected
>
> The sections most often adjusted after first setup are the M&A materiality thresholds, the disclosure schedule format / issues memo template, and the entity tracker cadence."

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/corporate-legal:cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

---

## Per-deal setup (`--new-deal`, M&A module only)

When a live deal starts, run a lighter interview focused only on deal-specific context. House approach stays from the plugin config.

Ask:
- Deal code name
- Side for this deal (buy-side or sell-side — may differ from the house default)
- Target or acquirer name
- VDR location (folder path or URL)
- Deal lead name
- Signing date and close date (if known)
- Any deal-specific threshold differences (a $50M deal may review smaller contracts than a $1B deal)
- Outside counsel firm and lead contact for this deal

Write to `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code-name]/deal-context.md`. Skills read both the plugin config (house) and `deal-context.md` (this deal), with deal-context.md taking precedence on conflicts.

---

## Practice Profile quality check

Before finishing, re-read what was written. Flag:
- Any section still showing a placeholder because the answer was skipped or vague — ask again
- Any active module where no seed document was provided — note it and ask the user to provide one when available
- The `*Active modules:*` line at the top of the plugin config — update it to list exactly which modules are on

---

## Failure modes

- **Don't assume all modules are active.** Ask first, interview only for what's live. A deal-only attorney doesn't need public company governance setup.
- **Don't hard-code buy-side.** The practice profile captures the house tendency; the per-deal flag handles the actual side. Write the house practice profile to be side-agnostic; posture is set per deal at `--new-deal`.
- **Don't write generic placeholders.** If the answer was vague ("standard materiality thresholds"), ask what that means in numbers. The practice profile is only useful if thresholds are actual thresholds.
- **Sell-side posture is not buy-side reversed.** On sell-side you're anticipating the buyer's findings and managing outward information flow, not reviewing inbound documents. Flag this distinction if sell-side is active.
- **Don't request seed documents for inactive modules.** Only ask for the request list and issues memo if M&A is active. A board-only attorney doesn't need to provide diligence documents.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/corporate-legal:customize`. They want to change something
in their practice profile — a risk posture, an escalation contact, a module
toggle, an output format — without re-running the whole cold-start interview
and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/corporate-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, public
     vs. private, practice setting *(shared across all 12 plugins — changes
     flow through `company-profile.md`)*
   - **Active modules** — which of M&A, Board & Secretary, Public Company,
     Entity Management are on. Turning a module on/off changes which skills
     prompt for setup.
   - **Risk posture** — conservative / middle / aggressive, what each means
     for diligence materiality and disclosure schedule scope
   - **People** — deal team, board secretary, entity management owner,
     escalation chain
   - **M&A module** — materiality thresholds (contract value, headcount,
     revenue), data room platforms trusted, AI bulk-review trust level
     (Luminance / Kira), deal-team briefing cadence
   - **Board & Secretary module** — house consent format, signatory
     preferences, committee structure
   - **Public Company module** — reporting calendar, disclosure controls,
     10-K/10-Q review timing
   - **Entity Management module** — entity table, registered agent, filing
     jurisdictions, annual report calendar
   - **Workflow** — matter workspaces (deal rooms), closing checklist
     location, VDR watcher cadence
   - **Integrations** — Box / Intralinks / Datasite / CT Corp / Slack status,
     fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Materiality threshold $250K → $500K:* "`/diligence-issue-extraction`
     and `/material-contract-schedule` will now treat $500K as the cutoff.
     Existing findings stay as logged; re-run if you want the new threshold
     applied retroactively."
   - *Turning on the Public Company module:* "I'll prompt you for reporting
     calendar and disclosure controls next time you run anything in that
     area."
   - *AI bulk-review trust "check every row" → "spot-check 10%":* "`/ai-tool-
     handoff` will QA a 10% sample rather than every extraction."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/corporate-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" something, set it
  to `[Not configured]` and explain what that means for the plugin's behavior.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., Public Company module off + "SEC counsel" in
  escalation; or aggressive risk posture + $25K materiality threshold), flag
  the tension.
- **Flag guardrail degradation.** The `[review]` flag, source attribution
  tags on retrieved documents, and `[verify]` tags on cited authorities are
  load-bearing — explain the trade-off before removing.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/deal-team-summary', 'legal', 'deal-team-summary', '', 'deal-team-summary', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Deal Team Summary

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

The deal lead doesn't read 200 findings. They read: what's material, what changed since last brief, what needs a decision. This skill compresses the diligence output to the right level for the reader.

## Load context

- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → Deal team briefing (cadence, format, what the business reads)
- `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md` → deal lead, timeline
- Current findings from diligence-issue-extraction output

## Audience tiers

Per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` — what the business reads vs. what's for the file. Default tiers:

| Audience | Gets | Doesn't get |
|---|---|---|
| **Board / exec sponsor** | Top 3-5 material issues, price/structure impact, decision items | Category detail, green findings, process |
| **Deal lead** | All reds, all yellows, progress, decision items, next steps | Green finding detail |
| **Working team** | Everything — full findings, status by category, gaps | Nothing withheld |

Ask which tier if not obvious.

## The summary

### Exec tier

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> This brief aggregates privileged diligence findings and inherits the sources' privilege and confidentiality status. Distribution beyond the privilege circle (including to broader business teams) can waive privilege — confirm the distribution list matches the privilege circle before sending.

# [Deal code] — Diligence Brief — [date]

**Status:** [On track / Issues identified / Material findings]
**Coverage:** [X]% of VDR reviewed

## Material findings

[3-5 max. One paragraph each. What it is, why it matters to the deal, what
we're doing about it.]

## Decisions needed

- [ ] [Specific decision — price adjustment, indemnity ask, walk-away trigger]
  — [who decides] — [by when]

## Since last brief

[What changed. New findings, findings resolved, coverage progress.]
```

### Deal lead tier

Same as above plus:

```markdown
## All open issues by category

### 🔴 Red
[Finding title + one-line — link to full finding for detail]

### 🟡 Yellow
[same]

## Progress

| Category | Docs reviewed | Coverage | Reds | Yellows | Status |
|---|---|---|---|---|---|
| [name] | [N/M] | [%] | [N] | [N] | [Complete / In progress / Blocked] |

## Gaps and follow-ups

- [Supplemental request items outstanding]
- [Questions to management]

## Next 72 hours

[What's getting reviewed, what briefings are scheduled]
```

### Working team tier

Full finding detail. Same structure as above but every finding gets its full house-format block, not a one-liner.

## Deltas

If this is a recurring brief (per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` cadence), lead with what changed:

- New findings since last brief
- Findings upgraded/downgraded in severity
- Findings resolved (consent obtained, issue clarified away)
- Coverage movement

Deal leads care more about movement than state. "Still 12 yellows" is less useful than "2 new yellows, 3 resolved."

## Handoffs

- **From diligence-issue-extraction:** This skill reads the accumulated findings.
- **To closing-checklist:** Any "decision needed" items that resolve into closing conditions go on the checklist.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't make the materiality call — it reports the calls that were made at extraction time.
- It doesn't decide what the deal team does about a finding — it surfaces the decision.
- It doesn't distribute the brief — drafts it, human sends.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/diligence-issue-extraction', 'legal', 'diligence-issue-extraction', '', 'diligence-issue-extraction', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /diligence-issue-extraction

1. Load `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` + `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md`.
2. Use the workflow below.
3. Check `ai-tool-handoff` — if category is bulk and tool is configured, hand off first.
4. Read docs, apply materiality filter, extract per category.
5. Findings in house memo format. Hand off consents to closing checklist.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

The VDR has 2,000 documents. Somewhere in there are the 30 that matter for the deal. This skill reads documents against the diligence categories and materiality thresholds from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`, extracts issues, and writes them in house memo format.

## Load context

- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → Diligence structure (categories, materiality thresholds)
- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → Issues memo format (how findings are stated)
- `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md` → deal-specific thresholds, VDR location

If deal-context.md doesn't exist, ask which deal this is for.

## Workflow

### Step 1: Inventory the VDR

If VDR MCP (Box/Intralinks/Datasite) is connected, pull the index. Map VDR folders to diligence request list categories. Note gaps — request list categories with no corresponding VDR content.

```markdown
## VDR Inventory: [Deal code]

| Request category | VDR folder | Docs | Status |
|---|---|---|---|
| Corporate & Organizational | /01-Corporate | 45 | Reviewed |
| Material Contracts | /02-Contracts | 312 | In progress |
| IP | /03-IP | 89 | Not started |
| [etc.] | | | |

**Gaps:** [Request categories with no VDR content — follow-up request needed]
```

### Step 2: Apply materiality filter

Per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` / deal-context thresholds. Don't review everything if the threshold says contracts >$X.

For contracts specifically: sort by stated value (if in filename/metadata) or by counterparty significance. Review top-down until you hit the threshold or the category is exhausted.

### Step 3: Extract issues

For each document read, check against the standard diligence concerns for its category:

**Material contracts — standard extraction set:**
- Change of control provision (triggered by this deal? consent required?)
- Assignment restriction (can the contract move to buyer?)
- Exclusivity / non-compete (restricts buyer's business?)
- MFN (most favored nation — pricing constraints)
- Termination rights (can counterparty walk because of the deal?)
- Unusual indemnities or liability exposure

**Corporate — standard extraction set:**
- Cap table accuracy, outstanding options/warrants
- Board consent requirements for the transaction
- Stockholder agreement restrictions (drags, tags, ROFR)
- Subsidiary structure and intercompany arrangements

**IP — standard extraction set:**
- Ownership chain (assignments from founders/employees in place?)
- Open source in the product (copyleft risk)
- Key IP licensed vs. owned
- Pending or threatened IP litigation

**Employment — standard extraction set:**
- Change-of-control severance triggers (parachute cost)
- Key employee retention risk
- Pending employment litigation
- Classification risk (contractors who look like employees)

**Litigation — standard extraction set:**
- Pending matters and reserves
- Threatened claims
- Regulatory inquiries
- Pattern litigation (consumer class actions, etc.)

### Step 4: State each finding

> **Source attribution.** Where a finding references a statute, regulation, case, or regulator action — e.g., a change-of-control provision analyzed under an applicable law, an IP ownership gap cited against a specific doctrine, a pending litigation matter with a case citation — tag the citation with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations from the VDR, deal-team memos, or outside-counsel feedback. Document-source citations (VDR path, Bates, filename) retain their native reference. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.
>
> **When disagreeing with a user's cited statute, quote the text or decline to characterize it.** If the user (or a deal-team note, or a sell-side disclosure) cites a statute for a proposition you don't think is correct, and you don't have the statute text available from a connected research tool or the VDR, do not invent a description of what the statute says. Say instead: "That section doesn't match what I'd expect a [bulk-sales notice / successor-liability / whatever] requirement to say — I'd need to pull the actual text to tell you what it actually covers. `[statute unretrieved — verify]`" Then either (a) retrieve the text via the configured research tool and quote it, (b) ask the user to paste the text, or (c) flag for outside counsel. A confident wrong description of a real statute is worse than "I don't know" — a deal-team memo citing a fabricated subchapter is harder to un-believe than a gap. Applies in every skill that characterizes a statute, not just issue extraction.
>
> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a legal basis the finding needs (e.g., the rule governing a change-of-control consent requirement, an IP assignment doctrine, an employment classification test), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / doctrine]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.

Per the finding template in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If the seed memo used this:

```
Issue #N: [Title]
Category: [request list category]
Severity: [level per house scheme]
Documents: [VDR path + doc name]
Finding: [what the document says and why it matters]
Recommendation: [price adjustment / indemnity / consent required / rep & warranty / walk]
```

...then use exactly that. If the seed memo was bullets, write bullets.

**Severity calibration** (if house scheme is R/Y/G):
- 🔴 **Red:** Affects deal value or structure. Change of control requiring major customer consent. Undisclosed material litigation. IP ownership gap.
- 🟡 **Yellow:** Needs attention, solvable. Consent required but likely obtainable. Open source requiring remediation. Employment classification risk.
- 🟢 **Green:** Noted for file. Consistent with reps. No action needed beyond the rep.

### Step 5: Assemble per category

Group findings by request list category. Within category, sort by severity.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> This output is derived from VDR materials that are privileged, confidential, or both. It inherits the source's privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. Store with the matter's privileged files and make distribution decisions deliberately.

# Diligence Issues: [Deal code] — [Category]

**Documents reviewed:** [N] of [M] in category
**Coverage:** [All | >$X threshold | Top N]
**Findings:** [N]🔴 [N]🟡 [N]🟢

---

### Bottom line

[🔴 N blocking · 🟠 N high · 🟡 N medium] — [the one thing the deal team needs to know]

---

[Each finding in house format]

---

## Gaps

- [Request list item with no responsive document]
- [Document referenced but not in VDR]
```

## Handoffs

- **To ai-tool-handoff:** If Luminance/Kira is in use per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`, hand bulk contract review there. This skill handles the nuanced documents (side letters, amendments, anything the AI tool struggles with).
- **To deal-team-summary:** Aggregated findings feed the deal team brief.
- **To material-contract-schedule:** Contract-level extractions feed the disclosure schedule.
- **To closing-checklist:** Any finding that implies a discrete pre-closing action becomes a checklist item. The handoff is not limited to third-party consents — it also covers:
  - **Shareholder vote / other closing action** — §280G cleansing votes, required stockholder consents, required board resolutions, appraisal-rights notice periods, conversion mechanics, or any other corporate approval the deal needs to close. Characterize the action, the approval threshold, the statutory or charter source, and the timing constraint.
  - **Regulatory filings and approvals** — HSR, CFIUS, foreign-investment review, sector-specific approvals flagged during extraction.
  - **Consents from counterparties** — change-of-control, anti-assignment, MFN-triggering consents.
  - **Releases, terminations, or pay-offs** — employment releases tied to change-of-control, payoff letters, lien releases.
  - **Escrow / holdback mechanics** — if extraction surfaces an indemnity escrow, R&W insurance deliverable, or holdback tied to a specific issue.
  Every finding with a pre-closing action tag should reach closing-checklist, not just the ones labeled "consent." If a finding sits in the gray zone (might need a closing action, might be a post-closing covenant), hand it off with a flag — closing-checklist can drop it if the purchase agreement says otherwise. Under-handoff is a one-way door; over-handoff is corrected in review.


**Successor liability.** Flag: pending or threatened tort/products-liability claims, environmental matters and cleanup obligations, bulk-sale/fraudulent-transfer exposure (is the seller retaining enough assets to pay its remaining creditors?), seller's post-closing dissolution plan (if seller dissolves, plaintiffs chase the buyer), and whether the purchase agreement has an assumed/excluded-liabilities schedule that actually covers the known exposures. Even in asset deals, the "de facto merger," "mere continuation," and "product line" doctrines can transfer liability — this is the analysis that surprises buy-side clients who think they're buying assets clean.

## Batch processing

For large categories (300 contracts), process in batches. After each batch, update the running issues list and flag anything 🔴 immediately — don't wait for the full category to surface a deal-affecting issue.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

If the extraction surfaced more than ~10 issues, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by severity (🔴 / 🟠 / 🟡 / 🟢), counts by house category, and a sortable grid of issues with materiality, category, and VDR source.

## What this skill does not do

- It doesn't make the materiality call on close cases. It applies the threshold; a human decides the borderline.
- It doesn't negotiate reps and warranties. It produces the findings that inform them.
- It doesn't replace bulk AI review. For high-volume clause extraction, hand off to Luminance/Kira per `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. This skill is for the judgment layer.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/entity-compliance', 'legal', 'entity-compliance', '', 'entity-compliance', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /entity-compliance

1. Load `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → `## Entity Management` (entity table, jurisdictions, registered agent).
2. Route to the correct mode below based on flag:
   - No flag or `--init`: Mode 1 — initialize tracker from entity table
   - `--report`: Mode 2 — surface upcoming deadlines and overdue items
   - `--update`: Mode 3a (manual) or 3b (--from-report upload) — update status
   - `--sweep`: Mode 3c — walk through unknown/overdue items one by one
   - `--audit`: Mode 4 — full health audit
   - `--export`: Mode 5 — produce CSV or table export
3. Read/write `~/.claude/plugins/config/claude-for-legal/corporate-legal/entities/compliance-tracker.yaml`.
4. After any update: show summary of changes and next action.

---

## Purpose

Annual reports, franchise taxes, Statements of Information, biennial filings —
every entity in every state has its own schedule and its own consequences for
missing the deadline. This skill maintains a single YAML tracker that knows
what's due, when, and for which entity. It's lightweight by design: the tracker
is a file you own, Claude updates it on command, and you export it when you need
to share it.

## Important: deadline reference caveat

> The filing deadlines in this skill's reference table reflect publicly available
> requirements as of the skill's build date. State filing requirements and due
> dates can change. **Always confirm deadlines with your registered agent or
> directly with the relevant Secretary of State before relying on them for
> compliance purposes.** If you use CT Corp, National Registered Agents, or
> another registered agent service, their compliance calendar is authoritative
> for your specific entities — use this tracker to organize and surface their
> data, not to replace it.

## Jurisdiction assumption

> This tracker computes deadlines against the state or country of formation / qualification recorded per entity. Filing rules, due-date mechanics, and fee structures vary materially by jurisdiction. If an entity's actual footprint differs from what's in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` (undisclosed foreign qualification, dissolved entities, jurisdictional re-domestication, international filings managed by a local agent), the output may not apply as written — confirm with the registered agent or local counsel for that jurisdiction.

## Entity-type disambiguation (especially Delaware)

> The filing calendar depends on **entity type**, not just jurisdiction. Treating a "Delaware entity" as a single bucket is a common and consequential error — DE corporations, DE LLCs, and DE LPs have different filings, different deadlines, and different consequences for a miss. Confirm the entity type from the entity table before computing or reporting a deadline, and never copy a deadline from one entity-type to another in the same state.
>
> **Delaware — the split that matters:**
>
> - **DE Corporation (Inc., Corp.):** Annual report AND franchise tax, both due **March 1**. Franchise tax is calculated by the authorized-shares method or the assumed-par-value capital method (whichever is lower); the annual report captures director / officer information. Statutory basis: 8 Del. C. §§ 501–502 [verify current].
> - **DE LLC:** No annual report required. Annual tax is a **flat $300**, due **June 1**. Statutory basis: 6 Del. C. § 18-1107(d) [verify current fee and date].
> - **DE LP:** No annual report required. Annual tax is a **flat $300**, due **June 1** (parallel to the LLC rule). Statutory basis: 6 Del. C. § 17-1109 [verify current].
>
> A DE LLC is NOT required to file a March 1 annual report — writing that deadline for an LLC carries real risk (spurious "overdue" flags that mask actual June 1 exposure, or worse, the inverse: a user who treats the March 1 corporation rule as universal and misses the June 1 LLC deadline). If the entity table records a Delaware entity without a type, flag it as `type_unknown` and ask the user to confirm before computing either deadline.
>
> The same entity-type discipline applies in every other jurisdiction with divergent filing regimes by entity type (e.g., CA corp Statement of Information vs. CA LLC SOI cadence; TX franchise tax applies to corporations, LLCs, and LPs but with different no-tax-due thresholds). When the reference table for a jurisdiction is populated, make sure it is indexed by entity type, not just by state.

---

## Tracker file

Lives at `~/.claude/plugins/config/claude-for-legal/corporate-legal/entities/compliance-tracker.yaml`. Structure:

```yaml
# Entity Compliance Tracker
# Generated: [date]
# Last updated: [date]
# Disclaimer: deadlines are reference only — confirm with registered agent or Secretary of State

metadata:
  company: "[Company Name]"
  generated: "[date]"
  last_updated: "[date]"
  last_audit: "[date or null]"

custom_jurisdictions:   # manually added — US states or countries not in built-in reference table
  []                    # populated when a new jurisdiction is encountered

entities:
  - name: "[Entity Name]"
    type: "[Corporation / LLC / LP / other]"
    state_of_formation: "[state]"
    formation_date: "[date or null]"
    status: "[active / dormant / dissolving]"
    registered_agent: "[CT Corp / National / in-house / other]"
    notes: ""

    jurisdictions:
      - state: "[state]"
        qualification: "[domestic / foreign]"
        qualified_date: "[date or null]"
        agent_managed: false   # set true for international entities where a local agent handles compliance
        local_agent: "[name or null]"
        filings:
          - type: "[Annual Report / Franchise Tax / Statement of Information / Biennial Statement / other]"
            due_date: "[YYYY-MM-DD]"
            due_basis: "[fixed date / anniversary month / other]"
            last_filed: "[date or null]"
            last_fee: "[amount or null]"
            status: "[current / due_soon / overdue / unknown]"
            confirmed_good_standing: "[date or null]"
            notes: ""
```

Status values:
- `current` — filed for current period, nothing due within 90 days
- `due_soon` — due within 90 days
- `overdue` — past due date with no filed date recorded
- `unknown` — no information; needs manual confirmation

---

## Mode 1: Initialise

Run when no tracker exists, or with `--rebuild` to regenerate from scratch.

### Step 1: Load entity table

Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → `## Entity Management` → Entity table. If the entity table
is populated (from org chart upload at cold-start), use it directly. If not,
ask the user to either run the cold-start module or provide the entity list.

### Step 2: For each entity × jurisdiction, confirm the filing requirements

For each entity, confirm the current filing schedule with the registered agent or the relevant Secretary of State. State filing schedules change (some states move from fixed dates to anniversary-based schedules and back, fee structures are revised, filing categories are reclassified). Do not rely on a cached schedule. The tracker below records the dates you confirm; update them when your registered agent sends reminders.

For each jurisdiction where the entity is registered (domestic or foreign):

1. Ask the user whether they have a current compliance report from the registered agent — that's the most authoritative source.
2. If not, ask the user what they know (filing type, due-date basis, last filed date, typical fee). Record what they provide.
3. For anything the user does not know, flag the entity × jurisdiction entry as `unknown` — do not populate dates from a cached reference. The user's next step is to confirm with the registered agent or Secretary of State.

**Capture details in the tracker rather than a reference table:**

> I don't have filing requirements for [Jurisdiction] in the reference table.
> Let me capture them so we can track this going forward.
>
> For [Entity] in [Jurisdiction]:
> 1. What type of filing is required? (Annual report, franchise tax, confirmation
>    statement, annual return, or something else?)
> 2. When is it due? (Fixed date like May 1, anniversary month, or other?)
> 3. What's the typical fee? (Approximate is fine — or "unknown".)
> 4. Who is your registered agent or local filing agent there?

Store the answer in a `custom_jurisdictions` block in the tracker:

```yaml
custom_jurisdictions:
  - jurisdiction: "[State / Country]"
    jurisdiction_type: "[US state / Canada province / EU member state / other]"
    filings:
      - type: "[filing type]"
        due_basis: "[fixed: MM-DD / anniversary month / other description]"
        typical_fee: "[amount or unknown]"
        notes: "[any other relevant information — e.g., local agent required, filing in local language]"
    added_by: "manual"
    added_date: "[date]"
```

This custom definition is then applied to all entities in that jurisdiction.
Future `--init` runs and entity additions will use it automatically.

**International jurisdictions specifically:**

International filings vary enormously by jurisdiction. Always go through the
custom definition flow above — confirm the filing type, cadence, and fee with
the local filing agent or registered office agent before populating the tracker.

For international entities, also ask:
- Is there a local filing agent or registered office agent handling compliance?
  If yes, note the agent name — the tracker can flag when to follow up with them
  rather than calculating due dates independently.
- Is the entity required to file any group-level reports in this jurisdiction
  (e.g., country-by-country reporting, beneficial ownership registers,
  economic substance filings)?

Flag international entities with a local agent as `agent_managed: true` in the
tracker. The report mode will list them separately with a note to confirm status
with the local agent rather than showing a calculated due date.

For anniversary-based filings: calculate from the formation_date in the tracker.
If formation_date is null: set status to `unknown` and flag for confirmation.

### Step 3: Write the tracker

Generate `~/.claude/plugins/config/claude-for-legal/corporate-legal/entities/compliance-tracker.yaml` with all entities and their
calculated filing requirements. Set initial status:
- `current` if last_filed is within the current filing period
- `due_soon` if due within 90 days and no last_filed for current period
- `overdue` if due date has passed and no last_filed for current period
- `unknown` if formation_date is missing or state is not in reference table

Show a summary after generating:

```
Entity compliance tracker initialized.

Entities: [N]
Total jurisdictions: [N]
Filings tracked: [N]

Status summary:
  ✅ Current:   [N]
  ⏰ Due soon:  [N] (next 90 days)
  🔴 Overdue:   [N]
  ❓ Unknown:   [N] (confirm with registered agent)

Run /corporate-legal:entity-compliance --report to see what's due.
```

---

## Mode 2: Report

Surfaces upcoming deadlines and flags overdue items. Default: next 90 days.

```
/corporate-legal:entity-compliance --report [--days 30|60|90|180]
```

Output format:

```
ENTITY COMPLIANCE REPORT — [date]
[Company Name]

🔴 OVERDUE ([N]):
  [Entity] / [State] / [Filing type] — was due [date]

⏰ DUE WITHIN [N] DAYS ([N]):
  [Entity] / [State] / [Filing type] — due [date]  [registered agent]
  [Entity] / [State] / [Filing type] — due [date]

✅ RECENTLY FILED ([N] in last 90 days):
  [Entity] / [State] / [Filing type] — filed [date]

❓ UNKNOWN STATUS ([N]):
  [Entity] / [State] / [Filing type] — no information; confirm with registered agent

🌐 AGENT-MANAGED ([N]):
  [Entity] / [Country] / [Filing type] — managed by [local agent]; confirm status directly
  [Entity] / [Country] — no local agent recorded; add one with --update

GOOD STANDING:
  Last confirmed: [date]
  Entities with confirmed good standing: [N] of [total]
  Entities not confirmed in last 12 months: [list]
```

If the tracker covers more than ~10 entities, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by filing status (overdue / due soon / filed / unknown), counts by good-standing state, and a sortable entity table with jurisdiction, filing type, and next due date.

---

## Mode 3: Update

Updates one or more entities in the tracker. Three sub-modes:

### Consequential-action gate (file SOI / annual report)

**Before directing or confirming a filing:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Filing a Statement of Information, annual report, or franchise tax return with a Secretary of State has legal consequences — it's a formal representation from the entity, it carries fees, and missed or incorrect filings can cause loss of good standing or franchise-tax defaults. Have you reviewed this with an attorney (or a qualified registered agent) before filing? If yes, proceed to record the filing. If no, here's a brief to bring to them:
>
> - Entity, jurisdiction, filing type, and due date
> - What the tracker says about the last filing (date, fee, officer/director information last reported)
> - Open questions (is the officer/director information still accurate; has the registered agent changed; has the principal office changed)
> - What could go wrong (out-of-date officer information, missed deadline triggering franchise tax or dissolution, fee calculation error)
> - What to ask the attorney (is a filing actually needed this year; are there any charter amendments or officer changes that need to be reflected; who should sign)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not record a new `last_filed` date past this gate without an explicit yes. Tracker reads, deadline reports, and "what's due soon" output do not require the gate.

### 3a: Manual update

```
/corporate-legal:entity-compliance --update
```

Attorney tells Claude what was filed:
> "We filed the Delaware annual report for [Entity] on March 1. Fee was $450."

Claude updates:
- `last_filed` → March 1 date
- `last_fee` → $450
- `status` → `current`
- `last_updated` in metadata

### 3b: Registered agent report upload

```
/corporate-legal:entity-compliance --update --from-report
```

User uploads a CT Corp, National Registered Agents, or similar compliance
report (PDF, CSV, or Excel). Claude reads it and updates matching entities:

From the report, extract for each entity:
- Filing type and due date
- Last filed date (if present)
- Good standing status and date confirmed
- Any flags or warnings from the agent

Match report entities to tracker entities by name (flag near-matches for
confirmation — "Acme Holdings LLC" vs. "Acme Holdings, LLC" are probably
the same entity).

After processing:
```
Updated [N] entities from report.

Matched: [N]
Unmatched (in report, not in tracker): [list — may need to add to entity table]
Not in report (in tracker, no update): [list — status unchanged]
```

### 3c: Bulk status sweep

```
/corporate-legal:entity-compliance --sweep
```

Walks through each entity with `unknown` or `overdue` status and asks for
current information one at a time:

> [Entity] / [State] / [Filing type] — currently showing as [status].
> Has this been filed? If yes, when and what was the fee?

Updates tracker after each confirmation. Produces a completion summary.

---

## Mode 4: Health audit

```
/corporate-legal:entity-compliance --audit
```

Broader review beyond just filing status. Surfaces:

**Filing compliance:**
- Overdue items (from report mode)
- Unknown status items

**Entity health:**
- Entities marked as `dormant` — flag for review: should these be dissolved?
  Carrying dormant entities costs money (annual fees, registered agent fees)
  and creates ongoing compliance obligations.
- Entities with formation_date older than 5 years and status `dormant` — flag
  as dissolution candidates.
- Entities missing formation_date — flag as data gap.

**Good standing gaps:**
- Entities with no `confirmed_good_standing` date — unknown whether in good
  standing; risk if a transaction requires a certificate on short notice.
- Entities with `confirmed_good_standing` older than 12 months — stale; worth
  refreshing, especially if M&A or financing is anticipated.

**Foreign qualification gaps:**
- Based on `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` entity table: are there states in the company's
  operational footprint (offices, employees) where entities are not foreign
  qualified? This requires the attorney to confirm operational presence —
  Claude can flag the question but cannot determine presence independently.

**Intercompany agreement gaps:**
- From `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`: if intercompany agreements are marked as partial or no,
  flag which entity relationships likely need agreements (parent-subsidiary
  services, IP licenses, loans).

Output format:

```
ENTITY HEALTH AUDIT — [date]

FILING COMPLIANCE
  Overdue: [N]
  Unknown status: [N]
  Action: run --sweep to confirm unknown items

DORMANT ENTITIES ([N])
  [List of dormant entities with age and annual carrying cost if known]
  Dissolution candidates (>5 years dormant): [list]

GOOD STANDING
  No record: [N] entities
  Stale (>12 months): [N] entities
  Consider refreshing before: [any upcoming transactions or contract renewals if known]

POTENTIAL GAPS
  Foreign qualification: [flag question — confirm operational presence in:]
    [list of states from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` footprint not in tracker as qualified]
  Intercompany agreements: [status from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`]

RECOMMENDED ACTIONS
  1. [Highest priority action]
  2. [etc.]
```

---

## Mode 5: Export

```
/corporate-legal:entity-compliance --export [--format csv|table]
```

Produces a flat export suitable for sharing with finance, legal ops, or
outside registered agent. Default: CSV.

CSV columns:
`Entity Name, Entity Type, State of Formation, Formation Date, Status,
Registered Agent, Jurisdiction, Qualification Type, Filing Type, Due Date,
Last Filed, Last Fee, Good Standing Confirmed, Notes`

One row per filing per jurisdiction. Multiple rows per entity (one per
jurisdiction × filing type combination).

If `--format table`: produce a markdown table suitable for pasting into
a report or Slack message, showing only the next 90 days of filings.

---

## What this skill does not do

- It does not file anything. Output is a tracker and a to-do list; filing
  is done by the attorney, outside counsel, or registered agent.
- It does not pull good standing certificates. It tracks when certificates
  were last confirmed; obtaining them is manual or via registered agent.
- It does not determine whether foreign qualification is required in a given
  state. That analysis depends on facts about business activity that the
  attorney must confirm.
- It does not replace a registered agent service for companies with complex
  multi-entity structures. CT Corp, National Registered Agents, and similar
  services have dedicated compliance teams and direct state relationships.
  This skill is best suited for smaller organizations without agent support,
  or as a lightweight layer on top of agent data for organizations that do
  have support.
- The filing deadline reference table is not legal advice and may not reflect
  current requirements. Confirm all deadlines before relying on them.


## Formula injection defense

Before writing any cell in Excel, Sheets, or CSV output, neutralize formula injection. Counterparty-sourced text (contract quotes, party names, registered agent data, CLM exports) is attacker-controlled. A cell starting with `=`, `+`, `-`, `@`, `	`, `
`, or `
` will be interpreted as a formula or break the row structure.

- **Prefix with a single quote:** `'=SUM(A1:A10)` → `=SUM(A1:A10)` (displayed as text, not executed)
- **Applies to every cell that contains text sourced from a document, a tool result, or a user paste.** Column headers you control and computed values you produce are safe.
- **CSV: also escape embedded commas, double quotes, newlines** (RFC 4180 quoting).
- This is not optional. A spreadsheet your user opens in Excel that triggers a macro or exfiltrates data via DDE is a supply-chain attack on your user.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/integration-management', 'legal', 'integration-management', '', 'integration-management', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /integration-management

1. Load `deal-context.md` for deal code, target, close date, deal lead.
2. Load `integration-tracker.yaml` if it exists (or create on --init).
3. Use the workflow below.
4. Route by flag:
   - `--init`: Mode 1 — read PA, build phased workplan, consent tracker
   - `--contracts`: Mode 2 — import contract list (repository or upload), tier and classify
   - `--report`: Mode 3 — generate status report
   - `--update`: Mode 4 — manual update or parse uploaded status document
   - `--export`: Mode 5 — CSV or table export
5. Read/write `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/integration-tracker.yaml`.
6. After any write: show summary of changes and surface any new flags.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Outside counsel closes the deal. Legal inherits the mess. This skill is the
program management layer for post-closing integration — not the business
integration, not IT systems, not HR org design. The legal workstream: consents,
contract assignments, entity rationalization, IP recordals, PA obligations.
It tracks what's done, what's due, what's blocked, and what needs a decision.

---

## Tracker file

Lives at `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/integration-tracker.yaml`. Read `deal-context.md` for
the deal code, target name, close date, and deal lead. Inherit any post-close
items from `closing-checklist.yaml` if it exists.

```yaml
# integration-tracker.yaml

metadata:
  deal_code: "[code]"
  target: "[company name]"
  close_date: "[YYYY-MM-DD]"
  deal_lead: "[name]"
  outside_counsel: "[firm and lead attorney]"
  last_updated: "[date]"
  last_status_report: "[date or null]"

pa_dates:
  required_consents_deadline: "[YYYY-MM-DD — extract from PA]"
  rep_survival_expires: "[YYYY-MM-DD]"
  escrow_release: "[YYYY-MM-DD or null]"
  earnout_milestones:
    - description: "[milestone]"
      measurement_date: "[YYYY-MM-DD]"
      payment_date: "[YYYY-MM-DD]"
      owner: "finance"   # always finance — legal tracks date only

workplan:
  day_1:
    target_date: "[close_date + 7 days]"
    items: []
  day_30:
    target_date: "[close_date + 30 days]"
    items: []
  day_90:
    target_date: "[close_date + 90 days]"
    items: []
  day_180:
    target_date: "[close_date + 180 days]"
    items: []

required_consents: []
desired_consents: []

contracts:
  source: "[repository / manual-upload / disclosure-schedule]"
  repository_path: "[path or null]"
  last_imported: "[date]"
  total: 0
  tier_1: []
  tier_2: []
  tier_3: []
  tier_4: []
```

**Workplan item structure:**
```yaml
- id: "W-001"
  description: "[action item]"
  phase: "[day_1 / day_30 / day_90 / day_180]"
  owner: "[legal-owns / legal-supports]"
  workstream: "[legal / hr / it / finance / real-estate / other]"
  priority: "[critical / high / medium / low]"
  deadline: "[YYYY-MM-DD or null]"
  deadline_basis: "[pa-obligation / regulatory / best-practice]"
  status: "[not_started / in_progress / complete / blocked / deferred]"
  blocker: "[description or null]"
  depends_on: "[item id or null]"
  notes: ""
```

**Consent entry structure:**
```yaml
- id: "CON-001"
  counterparty: "[name]"
  contract_type: "[customer / vendor / lease / IP-license / financial / other]"
  required_consent: true        # true = named in PA Required Consents schedule
  pa_deadline: "[YYYY-MM-DD]"   # only for required_consent: true
  status: "[not_started / outreach_sent / in_negotiation / obtained / waived / refused]"
  assigned_to: "[name or null]"
  outreach_date: "[date or null]"
  obtained_date: "[date or null]"
  notes: ""
```

**Contract entry structure:**
```yaml
- id: "C-001"
  name: "[contract name or filename]"
  counterparty: "[party name]"
  contract_type: "[MSA / SaaS / lease / IP-license / employment / NDA / other]"
  annual_value: "[amount or unknown]"
  assignment_mechanism: "[auto-assign / consent-required / coc-provision / silent]"
  tier: 1   # 1=Required Consent, 2=material+consent-required, 3=CoC, 4=auto-assign
  required_consent: false
  pa_deadline: "[YYYY-MM-DD or null]"
  status: "[not_reviewed / no_action / consent_pending / outreach_sent / in_negotiation / consent_obtained / assignment_complete / waived / refused / coc_triggered]"
  assigned_to: "[name or null]"
  notes: ""
  last_updated: "[date]"
```

---

## Mode 1: Initialize

```
/corporate-legal:integration-management --init [--deal [code]]
```

### Step 1: Load deal context

Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md`. If not found: ask for deal code name,
target company, close date, deal lead, and outside counsel. Write to
deal-context.md if it doesn't exist.

Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/closing-checklist.yaml` if it exists. Any items marked as
post-closing become Day 1 or Day 30 workplan items (inherit status from
closing-checklist).

### Step 2: Read deal inputs

**A full purchase agreement produces the most complete tracker.** The PA's Required
Consents schedule and post-closing covenants section are the authoritative source
for hard deadlines and legal obligations. But the skill can initialize usefully
from whatever is available — partial inputs produce a starter tracker the attorney
fills in rather than an empty page.

> What deal artifacts do you have available? Share whatever exists:
>
> **Ideal:** The purchase agreement (upload or connected document path). I'll read
> the post-closing covenants, Required Consents schedule, survival periods, escrow
> terms, and earn-out provisions.
>
> **Also useful — share any combination of:**
> - Deal summary or term sheet (gives me the key economics and timeline)
> - Integration to-do list or post-close checklist from outside counsel
> - Existing workplan or integration tracker (I'll import and continue from it)
> - Closing checklist — if generated by the M&A cold-start skill, I'll inherit it
>   automatically from `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/closing-checklist.yaml`
> - Required Consents list alone (if the PA is held by outside counsel)
>
> **If you have nothing written down:** Tell me the deal in plain terms — who was
> acquired, when it closed, what the main open items are — and I'll build a
> starter tracker from the standard Day 1/30/90/180 workplan that you edit.

**What changes based on what's provided:**

| Input | What you get |
|---|---|
| Full PA | Complete workplan + Required Consents with deadlines + PA dates |
| PA + contract list | Full tracker + contract assignment tier list |
| Deal summary / to-do list | Standard workplan skeleton, Required Consents as placeholders |
| Nothing | Standard workplan scaffold; attorney fills in consents and contract lists |

The tracker is designed to be built out progressively — a skeleton today, filled
in as more information becomes available.

**From the PA extract:**

*Required Consents schedule:*
- For each consent: counterparty name, contract type, and the contractual
  deadline. Set as required_consent: true with pa_deadline populated.

*Post-closing obligations:*
- Map each obligation to a workplan item. Assign to the correct phase based
  on the deadline. Tag as pa-obligation in deadline_basis.

*Key dates:*
- Required Consents deadline — extract from the PA
- Rep and warranty survival expiry — pull the specific survival periods from the PA.
  General, fundamental, and tax reps typically have different survival periods; pull
  each one the PA defines and record them separately. Do not assume a default.
- Escrow release date(s) — extract from the PA
- Any earn-out measurement and payment dates — add to pa_dates.earnout_milestones,
  owner always set to "finance"

### Step 3: Build the phased workplan

Generate standard workplan items for each phase. Add PA obligations extracted
in Step 2. Items inherited from the closing checklist are pre-populated.

**Day 1 — legal-owns:**
- Entity name change filing (if acquired entity is being renamed) [priority: critical]
- Bank account signatory updates — notify bank with closing documentation [priority: critical]
- Registered agent notification of ownership change [priority: high]
- Key IP assignment execution — if any IP assignments were deferred from closing [priority: critical]
- Domain name and social media account transfer [priority: high]
- D&O insurance — confirm tail policy is bound for acquired entity directors [priority: critical]
- Secretary of State ownership notifications where required by state law [priority: high]

**Day 1 — legal-supports:**
- Employee announcement and communications (HR owns, legal reviews) [priority: critical]
- Benefits day-1 coverage confirmation (HR owns, legal advises on COBRA and plan terms)
- Customer communication letters (business owns, legal reviews for accuracy)

**Day 30 — legal-owns:**
- Required Consents initial push — contact all counterparties, document outreach [priority: critical]
- IP assignment recordal at USPTO (patents, trademarks) [priority: high]
- Copyright assignment filing [priority: medium]
- Trademark assignment recording [priority: high]
- Material contract review — complete tier 1 and tier 2 contract assignment analysis [priority: high]
- Insurance tail policy final confirmation [priority: high]

**Day 30 — legal-supports:**
- Data migration privacy review (IT owns, legal advises on data transfer mechanisms)
- Real estate lease review for assignment provisions (facilities owns, legal advises)

**Day 90 — legal-owns:**
- Required Consents deadline — all Required Consents must be obtained or escalated [priority: critical, deadline: pa_dates.required_consents_deadline]
- Entity rationalization decision — recommend keep separate / merge / dissolve [priority: high]
- Benefits plan assumption or termination documentation [priority: high]
- Secondary consent push — remaining outstanding consents [priority: high]
- Tier 3 change of control contract resolution [priority: critical]

**Day 90 — legal-supports:**
- Full HR harmonization documentation (HR owns, legal advises on employment law)

**Day 180 — legal-owns:**
- Entity merger filing — if rationalization decision is to merge [priority: high]
- Entity dissolution filing — if rationalization decision is to wind down [priority: high]
- Full contract novation — contracts requiring acquiror's name [priority: high]
- Rep survival tracking — note upcoming expiry date [priority: medium]

Show summary after generating:

```
Integration tracker initialized — [Deal code] / [Target]

Close date: [date]
Required Consents deadline: [date] ([N] days from today)
Rep survival expires: [date]

Workplan items: [N] ([N] legal-owns, [N] legal-supports)
Required Consents: [N] (from PA schedule)
Desired Consents: [N] (from diligence — no PA deadline)

Contract assignment: not yet imported — run --contracts to populate

Next step: run /corporate-legal:integration-management --contracts to import the
contract list, then --report to see your first status summary.
```

---

## Mode 2: Contract Assignment

```
/corporate-legal:integration-management --contracts [--deal [code]]
```

This is the dedicated contract assignment initialization. Separate from the
main init so it can be run independently and re-run when the contract list
changes.

### Step 1: Get the contract list

Two paths — use whichever applies:

**Path A: Connected repository**

> Is your contract repository connected? (Google Drive, Box, SharePoint,
> or a VDR that's still accessible post-close?)
>
> If yes: give me the folder path or folder name for the acquired company's
> contracts. I'll pull a list of what's there and read each contract for the
> assignment clause and counterparty.

Search the connected repository. For each document found:
- Extract filename and file path
- Read the document — identify: contract party (counterparty name), contract
  type (from header or subject matter), assignment clause text, change of
  control clause text if present, and annual value if stated.

**Path B: Manual list upload**

> Upload a contract list. This can be:
> - The Material Contracts schedule from the PA disclosure schedules
> - A CSV or Excel export from their contract management system
> - A manually prepared list
>
> Minimum required columns: Contract Name, Counterparty. Helpful but optional:
> Contract Type, Annual Value, Assignment Clause text.

Read the uploaded list. For contracts where no assignment clause text is
provided, set assignment_mechanism to "not_reviewed" and flag for follow-up.

**Path C: Disclosure schedule**

If neither repository nor list is available, read the Material Contracts
schedule from the PA disclosure schedules (from the PA uploaded in --init).
This gives the minimum required list — parties and contract types. Assignment
clauses will need manual review.

### Step 2: Determine assignment mechanism

For each contract, classify the assignment mechanism:

| Mechanism | Definition | Tier |
|---|---|---|
| `consent-required` | Explicit clause prohibiting assignment without counterparty consent | 1 or 2 |
| `coc-provision` | Change of control clause giving counterparty termination or consent right triggered by the deal | 3 |
| `auto-assign` | No restriction, or explicit permission to assign to affiliates or successors | 4 |
| `silent` | No assignment clause — default to governing law. Research the governing-law default for contract assignment when the contract is silent and cite the controlling rule. Flag for attorney review. | 2 |
| `not_reviewed` | Could not read or locate assignment clause | Flag for manual review |

For contracts flagged in the Required Consents PA schedule: override tier to 1
regardless of assignment mechanism classification.

### Step 3: Tier assignment

```
Tier 1 — Required Consents: [N] contracts
  Named in PA schedule, hard deadline [date], must obtain consent

Tier 2 — Material, consent required: [N] contracts
  Assignment restriction present, not in PA schedule
  Recommended timeline: obtain within Day 90

Tier 3 — Change of control provisions: [N] contracts ⚠️
  Counterparty has termination or consent right triggered by close
  ACTION REQUIRED: contact counterparty immediately — CoC may already be triggered

Tier 4 — Auto-assign / no action: [N] contracts
  Assigns automatically or by affiliate/successor provision
  Tracking only — no outreach needed

Not reviewed: [N] contracts
  Could not determine assignment mechanism — manual review required
```

Show tier 3 separately and prominently. A change of control clause may have
already triggered on the close date — counterparty may have a right to terminate
that is running right now.

### Step 4: Generate status entries

For each contract, create a tracker entry with:
- All extracted fields (counterparty, type, value, mechanism, tier)
- Initial status: tier 4 → `no_action`; tier 3 → `coc_triggered`; tiers 1/2 → `consent_pending`; not_reviewed → `not_reviewed`
- pa_deadline populated for tier 1 from Required Consents schedule

---

## Mode 3: Status Report

```
/corporate-legal:integration-management --report [--deal [code]]
```

Reads current tracker state. Produces:

```
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> This status report is derived from the purchase agreement, diligence findings, and post-closing integration records. It inherits their privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. Confirm the recipient list before sending.

INTEGRATION STATUS — [Deal code] / [Target]
[Date] — Day [N] post-close

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXECUTIVE SUMMARY
[2-3 sentence paragraph: overall status, biggest risk, key win since last report]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REQUIRED CONSENTS  [deadline: DATE — N days remaining]
  Obtained:        [N] of [total]  ████████░░  [%]
  In negotiation:  [N]
  Outreach sent:   [N]
  Not started:     [N]
  Refused:         [N] ⚠️

⚠️ AT RISK: [counterparty] — deadline in [N] days, no response to outreach
⚠️ REFUSED: [counterparty] — PA obligation not met; escalate to outside counsel

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONTRACT ASSIGNMENT
  Tier 1 (Required Consents):   [N] complete / [N] in progress / [N] pending
  Tier 2 (Material contracts):  [N] complete / [N] in progress / [N] pending
  Tier 3 (CoC provisions):      [N] resolved / [N] outstanding ⚠️
  Tier 4 (Auto-assign):         [N] — no action required

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WORKPLAN — LEGAL OWNS
  🔴 OVERDUE ([N]):
    [item] — was due [date]

  ⏰ DUE THIS WEEK ([N]):
    [item] — due [date]

  ✅ COMPLETED SINCE LAST REPORT ([N]):
    [item] — completed [date]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BLOCKERS & DECISIONS NEEDED
  [item] — blocked on: [description] — owner: [name]
  [item] — decision needed: [description] — recommend: [option]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KEY DATES COMING UP
  [date] — [milestone / deadline]
  [date] — Rep survival expires — confirm no pending indemnification claims

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Mode 4: Update

```
/corporate-legal:integration-management --update [--deal [code]]
```

**Manual update:** Attorney tells Claude what changed.

> "We got the Salesforce consent. Mark it obtained, assigned to [name], date today."
> "The entity rationalization decision is to merge. Update status and add the merger
> filing to Day 180."
> "[Counterparty] refused consent. Flag it and note we need outside counsel on
> whether this triggers a PA indemnification claim."

Claude updates the relevant tracker entry, recalculates any downstream status
(e.g., if all tier 1 consents are now obtained, flag the PA obligation as met),
and shows what changed.

**Upload update:** Workstream owner or outside counsel sends a status document.

> Upload the status update from [outside counsel / HR lead / corp dev team].
> I'll parse it and update the tracker.

Read the uploaded document. Match described items to tracker entries by
counterparty name or workplan item description. Update status fields.
Flag any items in the update that don't match an existing tracker entry —
may be new items to add.

After any update, show:
```
Updated [N] items.

Changes:
  CON-003 Salesforce: not_started → obtained
  W-014 Entity rationalization: in_progress → complete

New flags:
  CON-007 [Counterparty]: refused — PA obligation may be unmet. Consider:
  outside counsel review of indemnification claim. ⚠️
```

---

## Mode 5: Export

```
/corporate-legal:integration-management --export [--format csv|table] [--section all|consents|contracts|workplan]
```

Produces a flat CSV or markdown table. Default: all sections, CSV.

CSV format — one row per item, section indicated by a `section` column.
Columns vary by section:

*Workplan:* id, phase, description, owner, workstream, priority, deadline, status, blocker

*Consents:* id, counterparty, contract_type, required_consent, pa_deadline, status, assigned_to, obtained_date, notes

*Contracts:* id, name, counterparty, contract_type, annual_value, assignment_mechanism, tier, required_consent, pa_deadline, status, assigned_to, notes

Export is the shareable format — suitable for outside counsel, corp dev, or a
board integration update.

---

## What this skill does not do

- It does not manage business integration workstreams (IT, HR, finance, real
  estate). It tracks legal's touchpoints in those workstreams and flags when
  legal input is needed. Ownership stays with the business function.
- It does not draft the consent request letters or novation agreements — those
  are produced by the written-consent skill or by outside counsel.
- It does not advise on indemnification claims or PA breach. When a consent is
  refused or a deadline is missed, it flags the situation — the legal analysis
  of consequences is the attorney's call.
- It does not track earn-out performance. Earn-out milestones and payment dates
  appear in the tracker as reference dates with owner set to finance. The
  business drives the numbers.
- It does not read contracts in real time during status reporting. Contract
  status is what the attorney has updated in the tracker. The skill reads the
  tracker, not the contracts, at report time.


## Formula injection defense

Before writing any cell in Excel, Sheets, or CSV output, neutralize formula injection. Counterparty-sourced text (contract quotes, party names, registered agent data, CLM exports) is attacker-controlled. A cell starting with `=`, `+`, `-`, `@`, `	`, `
`, or `
` will be interpreted as a formula or break the row structure.

- **Prefix with a single quote:** `'=SUM(A1:A10)` → `=SUM(A1:A10)` (displayed as text, not executed)
- **Applies to every cell that contains text sourced from a document, a tool result, or a user paste.** Column headers you control and computed values you produce are safe.
- **CSV: also escape embedded commas, double quotes, newlines** (RFC 4180 quoting).
- This is not optional. A spreadsheet your user opens in Excel that triggers a macro or exfiltrates data via DDE is a supply-chain attack on your user.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/material-contract-schedule', 'legal', 'material-contract-schedule', '', 'material-contract-schedule', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /material-contract-schedule

1. Load purchase agreement → Material Contract definition + schedule format.
2. Use the workflow below.
3. Apply definition to diligence findings. Flag edge cases.
4. Format per agreement. Consent overlay feeds closing checklist.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

The purchase agreement has a rep: "Schedule 3.X lists all Material Contracts." This skill builds that schedule from the diligence findings — which contracts are material per the agreement's definition, in the format the agreement requires.

## Load context

- Purchase agreement draft — for the definition of "Material Contract" and the schedule format
- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → materiality thresholds (may differ from the agreement definition — use the agreement's)
- Diligence findings from diligence-issue-extraction — contract-level data

## Workflow

### Step 1: Get the definition

Pull the definition of "Material Contract" from the purchase agreement — the PA definition controls. Deal-structure differences (stock vs. asset vs. merger) can change how a prong is interpreted, and regulated-industry overlays (healthcare, defense, financial services, telecom, government contracting) can add consent requirements that live outside the PA. If the deal involves any of those overlays, research the applicable anti-assignment or novation rules (for example, federal contracts, government contracting novation, sector-specific consent statutes) and cite the controlling rule.

Common prong categories to look for in the PA definition — these are not a substitute for reading the PA, and the list the PA uses controls:

- Dollar-value threshold (annual or aggregate)
- Term length
- Change-of-control or anti-assignment provision
- Exclusivity or non-compete
- Top N customer or supplier contracts
- Real property leases
- IP licenses (in-bound and out-bound)
- Related-party agreements
- Government contracts
- Contracts outside the ordinary course

The PA's definition is the test. Apply it mechanically — every contract that meets any prong in the PA's definition goes on the schedule.

### Step 2: Apply the definition to the findings

For each contract reviewed in diligence:

| Contract | Meets prong(s) | Include |
|---|---|---|
| [name] | [$X+ annual value; CoC provision] | Yes |
| [name] | [none] | No |

**Edge cases to flag for human decision:**
- Contract is $X-1 (just under threshold) but important to the business
- Contract meets a prong but is being terminated anyway
- Oral agreements or side letters that may or may not count

### Step 3: Gather schedule data

For each included contract, the schedule typically needs:

| Field | Source |
|---|---|
| Counterparty name | Contract |
| Contract title/type | Contract |
| Date | Contract |
| Term / expiration | Contract |
| Annual/total value | Contract or management data |
| Which materiality prong it meets | Step 2 analysis |
| Consent required for the deal | Diligence finding |
| VDR reference | Diligence inventory |

Pull from existing diligence extractions. If a field is missing, flag it — don't guess.

### Step 4: Format per the agreement

Disclosure schedules have a format — usually a numbered list or a table, sometimes with sub-parts by contract type. Match the format of the other schedules in the draft agreement.

```markdown
## Schedule 3.[X] — Material Contracts

The following are the Material Contracts as of the date hereof:

### (a) Customer Contracts

1. [Agreement Title], dated [date], between [Target] and [Counterparty].
   [Brief description if the format calls for it.]
   [VDR: path]

2. [...]

### (b) Supplier Contracts

[...]

### (c) Real Property

[...]

[etc. — sub-parts per the agreement's definition structure]
```

### Step 5: Consent tracking overlay

Separately (not in the schedule itself — this is internal), track which scheduled contracts require consent.

> The consent overlay and any pre-delivery working draft of the schedule are derived from privileged diligence materials and inherit their privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. The schedule itself, once delivered as an exhibit to the executed PA, is a deal document and is not privileged; strip any internal annotations before delivery.


| Schedule # | Counterparty | Consent required | Status | Owner | Due |
|---|---|---|---|---|---|
| 3.X(a)(1) | [name] | Yes — CoC §12.2 | Requested | [name] | [date] |

This feeds closing-checklist.

## Cross-check

Before delivering:

- Every contract that met a prong is on the schedule (completeness)
- No contract is on the schedule that doesn't meet a prong (no over-disclosure — it's a rep, not a data dump)
- Schedule is consistent with the other reps (a contract on Schedule 3.X that creates a lien should also be on the liens schedule)
- Every entry has a VDR cite so buyer's counsel can find the underlying doc

## Handoffs

- **From diligence-issue-extraction:** Contract-level findings are the input.
- **To closing-checklist:** Consent items go on the checklist.

## What this skill does not do

- It doesn't decide the materiality definition — that's in the purchase agreement.
- It doesn't obtain consents — it tracks which ones are needed.
- It doesn't draft the rep — it populates the schedule the rep references.$body$)
ON CONFLICT (skill_key) DO NOTHING;
