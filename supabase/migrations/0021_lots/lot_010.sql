INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/client-comms-log', 'legal', 'client-comms-log', '', 'client-comms-log', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /client-comms-log

1. Use the workflow below.
2. Require case-id (prompt if not provided).
3. Route by flag:
   - `--add` (default): capture direction, medium, student, summary, action items, follow-up due. Confirm with user. Append (prepend most-recent-first) to `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md`.
   - `--read`: show the most recent N entries.
   - `--summary`: one-paragraph condensed read.
   - `--patterns`: scan for unanswered comms, missed follow-ups, language gaps, tone shifts, contact gaps. Supervision-oriented.
4. Integration: offer `/legal-clinic:deadlines --add` if the log establishes a deadline; route to `/legal-clinic:semester-handoff` via `--summary` when relevant.

---

# Client Communications Log

## Purpose

Four reasons to keep this log:

1. **Malpractice defense.** If a client claims "no one ever told me [X]," a dated entry showing otherwise is the answer. Clinical professors carry professional liability on student work; contemporaneous records protect them.
2. **Continuity at handoff.** The next semester's student takes over and reads the log; they don't re-ask the client questions already answered.
3. **Supervision visibility.** Five unreturned voicemails over six weeks is a pattern. The log makes patterns visible that individual students might not flag on their own.
4. **File retention.** Law school clinics have obligations to maintain complete client files. Communication history is part of that.

Light. Append-only. The student's job is to write a two-sentence entry after every contact; the skill formats it and appends.

## Load context

- `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md` (if exists) — append target
- `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → not heavily read; this skill is case-scoped

## Modes

Flag: `--add | --read | --summary | --patterns` (default: add)

### `--add` (default) — log a new entry

**Inputs:**
- Case ID (required — which case)
- Date + time (default: now)
- Direction: `in` (client → clinic) | `out` (clinic → client)
- Medium: `call | email | text | letter | in-person | video | voicemail-left | voicemail-received`
- Who (student): name
- Who (client side): client name, or "third-party: [description]" if from opposing counsel, family member, etc.
- Duration / length (e.g., "10 min call", "3-paragraph email", "45 min in-person meeting")
- Summary: 2-4 sentences. What happened, what was substantive.
- Action items:
  - What the student owes the client (with deadline)
  - What the client owes the student (with expected timing)
- Follow-up due: date if applicable
- Notes: anything that matters but doesn't fit above — language used, emotional tone, family dynamic observed

**Before writing:** show the user the formatted entry and ask for confirmation. Clinic records should be reviewed before they're written, not after.

**Append** to `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md`. If the log doesn't exist, create it with a header:

```markdown
# Communications Log — [case name]

**Case ID:** [case-id]
**Client:** [name]
**Opened:** [YYYY-MM-DD]

Append-only. Most recent at top.

---
```

Then prepend new entries at the top (most recent first).

### `--read` — show recent entries

Print the most recent N entries (default 5). Useful when picking up a case mid-semester or before a client call.

### `--summary` — condensed read

Produce a one-paragraph summary of the log — most recent contact, total entries, common medium, any open action items from the student side, any unanswered communications. Feeds `/semester-handoff` and `/status`.

### `--patterns` — flag concerns across the log

Scan for:

- **Unanswered communications from client.** Client called or emailed N times without a response entry.
- **Missed follow-up.** Action item with follow-up due date, and no later entry resolving it.
- **Language / accommodation issues.** Client language noted as non-English; check whether outgoing communications have been in that language.
- **Escalation patterns.** Client tone shifting (frustrated / distressed) across entries.
- **Gaps.** Long stretches with no contact on an active case.

This is a supervision tool. Clinical professors running `--patterns` across their cases see which students might need support.

## Integration

- **`/client-letter`:** after generating and sending a letter, offer to log it as an outgoing comm.
- **`/status client`:** when producing a client-facing status summary, offer to log it (often these summaries go to clients).
- **`/client-intake`:** first entry in every new case's log is the intake contact.
- **`/semester-handoff`:** handoff memos read `--summary` for each case to populate the communications-history section.
- **`/deadlines`:** if a communication established a deadline ("client said they need to respond by Friday"), offer to `/deadlines --add`.

## What this skill does not do

- **Store substantive legal analysis.** That lives in intake, memo, and status files. The log is communication record — facts of contact, not legal strategy.
- **Auto-log from outside systems.** If the clinic uses a case management system (Clio), an integration could pull call logs and emails automatically. That's a future add; not v1.
- **Edit past entries.** Append-only. If an entry is wrong, write a new entry referencing and correcting it. The integrity of the log depends on not rewriting history.
- **Enforce log discipline.** If a student doesn't log a call, the skill can't know. Log hygiene is a clinic-culture problem; the skill just makes logging easy.
- **Handle privileged or attorney-only notes.** If the student needs to record strategic thinking, that goes in the case's internal analysis file, not the comms log.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/client-intake', 'legal', 'client-intake', '', 'client-intake', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /client-intake

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice areas, intake templates, supervision style, flag triggers.
2. Use the workflow below.
3. Route to practice-area template. Listen for cross-area issues throughout.
4. Conflict check flags. Triage classification.
5. Output formatted case summary with AI-assisted label, verification prompts, supervision routing.

```
/legal-clinic:client-intake
```

---

# Client Intake

## Purpose

Intake is one of the biggest bottlenecks in clinics. A student might spend 45 minutes interviewing, another hour writing it up, more time spotting the issues. Meanwhile the waitlist grows.

This skill structures the conversation, produces the write-up, spots issues across practice areas, and flags conflicts — so the student's time goes to analysis, not transcription.

**What it doesn't do:** decide whether to take the case. That's the student's analysis and the professor's judgment. Claude accelerates the information-gathering and structuring, not the lawyering.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice areas, intake templates (per practice area if multiple), supervision style, jurisdiction, flag triggers.

## Read the supervisor guide

Check for a practice-area guide at `~/.claude/plugins/config/claude-for-legal/legal-clinic/guides/<practice-area>.md`. If one exists, use its intake questions, red flags, and good-fit criteria instead of the generic defaults below. If one doesn't exist, use the generic intake and note at the end of the intake summary: "This was a generic intake — your supervisor can tailor the questions for your clinic type with `/legal-clinic:build-guide`."

When the intake starts before the practice area is routed (Step 1 of the workflow below), re-check for the guide after routing — the guide path depends on which practice area the intake landed in.

## Workflow

### Step 1: Practice area routing

Which practice area does this intake start in? The client may not know — they know their problem, not the legal category.

> "Tell me what's going on — what brought you to the clinic today?"

From the answer, route to the appropriate intake template. If the clinic handles multiple areas and the problem spans them (housing client mentions immigration status, family client mentions domestic violence), note all relevant areas — cross-area issue spotting is a feature, not a bug.

### Step 2: Practice-area-specific intake

Each practice area asks different questions. Use the template from `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` for this area. Defaults if none provided:

**Immigration:**
- Current status and how entered
- Any prior applications, removals, encounters with ICE/CBP
- Country conditions relevant to any asylum/withholding claim
- Family members and their statuses
- Criminal history (sensitive — explain why asking)
- Timeline urgency: any pending hearings, deadlines, NTAs

**Housing:**
- Type of housing (private, subsidized, public)
- What happened: notice received, lockout, conditions problem, deposit dispute
- Lease terms and payment history
- Habitability issues (repairs requested, landlord response, documentation)
- Timeline urgency: notice date, court date if any

**Family:**
- Relationship and what's at issue (custody, support, divorce, protection)
- Children involved — ages, current arrangement
- Safety: any violence, threats, fear (handle carefully — see cross-area flags)
- Existing court orders
- Timeline urgency: any hearings scheduled

**Consumer:**
- Type of debt or dispute
- Who's contacting them and how (FDCPA relevance)
- Documentation: contracts, statements, collection letters
- Has anything been filed against them
- Timeline urgency: answer deadlines, garnishment, judgment

### Step 3: Cross-practice-area issue spotting

While running the practice-area template, listen for issues outside that area:

| Client says | Also flags |
|---|---|
| "I'm worried about my immigration status" | Immigration issue — even in a housing intake |
| "My partner [threatening behavior]" | DV / family law / protective order — even in a consumer intake |
| "I can't work because of my injury" | Possible benefits/disability claim |
| "They're taking money from my paycheck" | Garnishment — consumer/employment overlap |
| "The landlord said he'd call ICE" | Housing + immigration + possible retaliation claim |

Note every cross-area issue in the summary. The clinic may handle it, refer it, or both — that's the professor's call. The student should see it.

### Step 4: Conflict check flags

Per whatever conflict-check process `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` describes. At minimum:

- Opposing party name(s) — does the clinic represent or have represented them?
- Related parties — anyone else the student or clinic might have a conflict with?
- Positional conflicts — is this case asking for something that would hurt another clinic client?

Flag for professor review. Don't resolve the conflict — surface it.

### Step 5: Triage classification

Not a case-acceptance decision — a triage input:

| Classification | Means |
|---|---|
| **Urgent** | Deadline in days, safety issue, irreversible harm imminent |
| **Time-sensitive** | Deadline in weeks, harm ongoing but not immediately irreversible |
| **Standard** | No immediate deadline, can queue normally |
| **May be out of scope** | Issue is outside clinic's practice areas — flag for referral assessment |

### Step 6: Supervision flag check

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` supervision style and flag triggers. If formal queue or configurable flags are enabled, and a trigger is present (deadline mentioned, DV indicator, immigration status at issue, etc.), note the flag.

### Step 7: Deadline handoff — required deliverable

If the intake surfaces any timeline deadline (answer due, hearing, statute-of-limitations cutoff, cure period, filing window, notice window, ICE check-in, removal hearing, eviction court date, protective order renewal), **emit a copy-paste-ready `/legal-clinic:deadlines --add ...` block as part of the intake output**. This is a required deliverable, not a suggestion — the intake identifies deadlines, and the student shouldn't have to re-transcribe them into the deadline skill.

Format each deadline as a fenced code block the student can copy, with every field pre-populated from the intake:

```
/legal-clinic:deadlines --add
  case=[case slug or client-last-name-keyword]
  type=[response|hearing|statute-of-limitations|discovery|cure-period|filing-window|notice|other]
  description="[one-line description of what is due]"
  due=[VERIFY — student + supervisor compute from triggering event]
  source="[triggering event + statute/rule cite, e.g., 'UD complaint served 2026-05-04, CCP § 1167']"
  owner=[student name]
  warnings=[14,7,3,1]
```

Rules:
- One block per deadline surfaced. Do not combine. Each one will route through the deadlines skill's pre-add duplicate check.
- Leave the `due=` value as `[VERIFY — student + supervisor compute]` when the deadline is jurisdictional (response deadline, SOL, notice window under a specific rule). The deadlines skill will not compute for you; the student + supervisor do the math and update the entry.
- When a date is given in the triggering document (a hearing date on a summons, an ICE check-in date, a renewal deadline on a protective order), put that date in `due=`. When the date is computed (count N days from triggering event), leave the `[VERIFY]` marker.
- If no deadline is surfaced in the intake, omit this section — don't fabricate one.

## Output

```markdown
# Intake Summary: [Client name or ID]

---
[AI-ASSISTED DRAFT — requires student analysis and attorney review]

**Privilege and confidentiality.** This summary is derived from client communications that may be privileged, confidential, or both. It inherits the source's privilege status. Distributing it beyond the privilege circle (including outside the clinic) can waive privilege. Keep it in the clinic's privileged file store, mark it appropriately, and make distribution decisions with your supervisor.
---

**Date:** [date] | **Intake by:** [student] | **Practice area:** [primary + any cross-area]

## Bottom line

[Take the case / Decline because X / Need more info on Y — next step is Z]

## Client's situation (in their words)

[The narrative the client gave, before legal categorization. This is the human story.]

## Legal issues identified

*Every statutory, ordinance, regulatory, rule, or case citation in this section carries a provenance tag (see plugin CLAUDE.md `## Shared guardrails` for the tag vocabulary). `[user provided]` if the supervisor uploaded the text, `[statute / regulator site]` if you fetched it this session from an official source, a research-connector tag (`[CourtListener]`, etc.) if it came from a tool result in this conversation, `[model knowledge — verify]` otherwise. The default is `[model knowledge — verify]`. A supervising attorney who cannot verify a cite against a connector needs to see the tag to know what to check first.*

### Primary ([practice area])
- [Issue 1]: [one line with any cite tagged, e.g., "RLTO §5-12-080 `[model knowledge — verify]`"]
- [Issue 2]: [one line]

### Cross-practice-area flags
- [Other area]: [what the client said that raised it]
  [UNCERTAIN: whether clinic handles this or refers — professor call]

## Key facts

| Fact | Source | Documentation |
|---|---|---|
| [fact] | [client statement / document provided] | [have it / need it] |

## Conflict check

**Opposing party:** [name(s)]
**Related parties:** [any]
**Flag:** [clear / needs conflict check against clinic database]

## Triage

**Classification:** [Urgent / Time-sensitive / Standard / May be out of scope]
**Driving deadline:** [if any — date and what it is]

## Deadlines to log

[One `/legal-clinic:deadlines --add ...` block per surfaced deadline — Step 7.
If none, omit this section.]

## Jurisdictional notes

*Every statute, ordinance, rule, or case citation in this section carries a provenance tag — same vocabulary as `## Legal issues identified`. Default `[model knowledge — verify]`. When no research connector is reachable for this session, record it in the **Sources:** line of the reviewer note (see plugin CLAUDE.md `## Outputs`) — do not emit a standalone banner.*

[State-specific or local-rule-specific issues relevant to this case type, per
CLAUDE.md jurisdiction, with each cite tagged]

## Supervision flags

[If supervision style includes flags: which fired and why. If formal queue:
"QUEUED for [professor]."]

---

## Verification prompts for the student

Before analysis, verify:
- [ ] [Specific fact the intake relies on — confirm with client or documents]
- [ ] [Deadline date — confirm from the actual notice/court document, not client's memory]
- [ ] [Any legal conclusion above is a starting hypothesis — research before relying on it]

## What this summary does NOT do

This summary does not decide whether the clinic takes this case. That's your
analysis and [Professor]'s judgment. It structures what the client told you
so you can spend your time on the analysis instead of the write-up.
```

## Practice-area intake template references

Store practice-area-specific question sets at `references/intake-templates/[area].md`. Cold-start populates these from the professor's intake form(s); if none provided, use the defaults above.

## What this skill does NOT do

- **Decide case acceptance.** Student analyzes, professor decides.
- **Resolve conflicts.** Flags them for the professor.
- **Give advice during intake.** Intake is gathering; advice comes after analysis and professor review.
- **Produce a final document.** The summary is a starting point — the student reads it, corrects anything mischaracterized, and builds the analysis from it.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/client-letter', 'legal', 'client-letter', '', 'client-letter', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /client-letter

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → plain-language standards, supervision style, clinic contact info.
2. Use the templates and workflow below.
3. Match type to template. Plain-language check.
4. Output with AI-assisted label, supervision routing.

Scope: routine only. Substantive advice → `/status client` or a conversation with the professor.

```
/legal-clinic:client-letter appointment
```

```
/legal-clinic:client-letter doc-request
```

---

# Client Letter: Routine Correspondence

## Purpose

Clinics send a lot of routine correspondence: "your appointment is Tuesday at 2pm," "please bring your lease," "we filed your answer." This skill handles those from templates so students aren't typing the same letter every week.

**Scope: routine only.** Substantive advice, bad news, case strategy — those are `/status client` or a conversation, not a template letter.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → plain-language standards, supervision style, clinic contact info.

## Pedagogy check

Read the supervisor guide for this practice area at `~/.claude/plugins/config/claude-for-legal/legal-clinic/guides/<practice-area>.md`. Check the `pedagogy_posture` setting:

- **`guide` (default):** Produce the structure and the checklist (required elements, plain-language targets, sign-off per student practice rule). Ask the student to draft each section. Give feedback on their draft (register, reading level, required elements, what they missed). Offer to fill a section only when the student has tried once.
- **`assist`:** Produce the letter. Flag items for student review. The student edits and learns by reviewing.
- **`teach`:** Don't produce the letter. Ask the student to draft it. Give feedback. Ask leading questions when they're stuck. Only show a model paragraph after two attempts, and only the section they're stuck on. Track what they got right and wrong so the supervisor can see progress.

If no guide exists, use `guide`. If the guide exists but doesn't set a posture, use `guide`.

Whatever the posture, the output always includes: "**Pedagogy mode: [assist/guide/teach]** — set by your supervisor's guide. This means I [description of what the student did vs what the skill did]."

## Sign-off and student-attorney disclosure

Check your jurisdiction's student practice rule for required disclosure language in letters signed by a law student. Some jurisdictions require specific forms; most require that the student identify themselves as a law student / certified legal intern and identify the supervising attorney. The templates below use a generic form — conform the sign-off to your rule before sending.

## Letter types

> **Review label goes OUTSIDE the letter.** The `[AI-ASSISTED DRAFT — requires review per plugin config supervision step]` tag is a note to the student, not part of the letter body. Place it above the rendered template (or in a header the student deletes before sending), never inside the fenced letter content. If it ends up in the client-facing copy, the skill has failed.

### Appointment confirmation

*Review label for the student (not for the client — strip before sending):*
`[AI-ASSISTED DRAFT — requires review per plugin config supervision step]`

```markdown
Dear [Client],

This confirms your appointment with [Clinic name]:

**Date:** [date]
**Time:** [time]
**Where:** [address / room / or "by phone at [number]"]
**With:** [student name]

**Please bring:** [documents needed — from case notes or leave as prompt
for student to fill]

If you need to reschedule, call us at [clinic phone] at least 24 hours before.

[Student name]
Law Student, Certified Legal Intern
Under the supervision of [Supervising Attorney]
[Clinic name] | [phone] | [hours]
```

### Document request

*Review label for the student (not for the client — strip before sending):*
`[AI-ASSISTED DRAFT — requires review per plugin config supervision step]`

```markdown
Dear [Client],

To move your case forward, we need the following documents from you:

- [Document 1 — e.g., "Your lease agreement"]
- [Document 2 — e.g., "The notice you received from your landlord"]
- [Document 3]

**How to get them to us:** [drop off at clinic / email to [address] / bring
to next appointment]

**Please send by:** [date — if there's a deadline, say why: "We need these
by [date] so we can file your answer before the court deadline."]

If you don't have some of these or aren't sure what we mean, call us at
[clinic phone] and we can help.

[Student name]
Law Student, Certified Legal Intern
Under the supervision of [Supervising Attorney]
[Clinic name] | [phone] | [hours]
```

### Brief status update

For routine "we filed it" / "we're waiting" updates. (Fuller status updates → `/status client`.)

*Review label for the student (not for the client — strip before sending):*
`[AI-ASSISTED DRAFT — requires review per plugin config supervision step]`

```markdown
Dear [Client],

Quick update: [one-line what happened — "We filed your answer with the court
on [date]" / "We sent the demand letter to your landlord on [date]"].

**What's next:** [one line — "We're waiting for their response" / "The court
will schedule a hearing and let us know the date"].

You don't need to do anything right now. We'll let you know when we do.

[Student name]
Law Student, Certified Legal Intern
Under the supervision of [Supervising Attorney]
[Clinic name] | [phone] | [hours]
```

## Before sending

Sending a letter to a client is a consequential action. This plugin's gate is the supervision workflow described in `## Supervision style` in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`, reinforced by the Part 0 role check that confirms a licensed supervising attorney owns the clinic setup. That gate still holds: every letter clears review before it leaves the clinic.

Before sending any of the letters above, confirm:

1. The draft has been reviewed per the supervision protocol in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` (queue / flag / lighter-touch).
2. All internal review labels (`[AI-ASSISTED DRAFT]`, any `[VERIFY]` or `[FACT NEEDED]` tags) have been removed from the client-facing copy.
3. The sign-off conforms to your jurisdiction's student practice rule for law-student-signed correspondence.

**This is a student draft for supervising-attorney review, not a final letter.** Sending it has legal consequences for the client and may constitute legal advice or communication on the client's behalf. A licensed supervising attorney reviews, edits, and signs off before the letter leaves the clinic. Do not send without supervisor approval.

## Plain-language check

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` standards. Short sentences. No jargon. Reading level target enforced. If a template above includes a legal term the client might not know, explain it the first time: "We filed your 'answer' — that's the document that tells the court your side of the story."

## Supervision routing

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`. Routine correspondence may or may not be a flag trigger depending on the supervision style the professor chose. If lighter-touch: these go out after student review without a queue step. If formal queue: even routine letters queue.

## What this skill does NOT do

- **Substantive advice.** If the letter would say "here's what I think about your case" or "here's what you should do," that's not routine — that's `/status client` or a conversation with the professor first.
- **Bad news.** Case closing, adverse ruling, can't-help — those need thought, not a template. Flag for professor.
- **Anything to opposing counsel or a court.** Different audience, different skill (`/draft` or `/status court`).$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`. If populated and no `--redo`, confirm before overwriting.
2. Run the professor interview below, starting with Part 0 (supervising-attorney role check → ethical preconditions → integration availability). If the user isn't the supervising attorney, stop and redirect.
3. Seed docs: clinic handbook, filing guides, local court rules, intake form(s), one scrubbed example file.
4. Key decision: supervision style (formal queue / flags / lighter-touch).
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/legal-clinic/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` including `## Who's using this` and `## Available integrations`. Show supervision choice and practice-area templates for confirmation.
7. Offer `/legal-clinic:ramp` preview.

```
/legal-clinic:cold-start-interview
```

**`--check-integrations`:** Re-run only the Part 0 integration-availability check (Clio, document storage). Updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` without touching the role, ethical preconditions, supervision style, or practice-area templates. Use after adding or removing an MCP connector.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

---

# Cold-Start Interview: Law School Clinic

## Purpose

Clinics are structurally capacity-constrained. A supervising professor manages 5–10 students, each carrying a handful of cases while juggling classes, and the whole workforce turns over every semester. The waitlist grows. People give up waiting.

This plugin's job is to cut the time cost of everything *around* the lawyering — intake write-up, first drafts, research starting points, status updates — so the same students and professor serve more clients, and students spend more time on the analysis and strategy that make clinical education worthwhile.

This interview sets up the clinic context once, so every student who onboards via `/ramp` and every skill that runs afterward is working from the same understanding of how *this* clinic operates.

**Audience: the supervising professor.** Students don't run this — they run `/ramp`.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

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

Show this preamble first (3-4 short lines, nothing more):

> **`legal-clinic` is for supervising attorneys setting up a law school clinic and onboarding students.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you practice area(s), jurisdiction, and supervision model basics — plus working defaults for client-letter format, IRAC scaffolding, and deadline cadence. **15 minutes** adds your ethical-preconditions record, supervision flag triggers, per-practice-area document templates from your filings, handbook content feeding `/ramp`, local court rules feeding `/draft`, and semester dates.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

## After the user picks quick or full

Once the supervising attorney has picked, orient them. Cover, in your own voice:

- **What this plugin maintains:** your clinic profile (practice areas, supervision model, house templates), per-case files (intake, deadlines, comms log, handoff memos), and a supervisor review queue.
- **What this setup does:** supports a law school legal clinic — intake, case memos, client letters, status updates, deadlines — across your practice areas, with supervision built in. Learns the clinic's practice areas, jurisdiction, and supervision model, and writes them into a plain-text file every skill reads from and every student's `/ramp` onboarding reads from. Everything can be changed later. Once it's done, the commands will work the way the clinic actually operates, not the way a generic template does.
- **Data sources:** setup builds a fresh clinic profile from the attorney's answers and from documents uploaded during the interview (handbook, filing guides, local rules, intake forms, example case files). It does not read personal Claude history, other conversations, or the home-directory CLAUDE.md. If something relevant came up earlier in this conversation (e.g., school or practice area), ask before folding it in. Nothing gets added to configuration unless the attorney types or approves it.
- **Next up:** Part 0 — who's running the setup and the ethical preconditions.

**Why this matters.** Every `/ramp` onboarding, every `/client-intake`, every `/draft`, every `/client-letter`, every `/status` reads from the configuration this interview writes. A generic configuration gives students generic output — a default supervision model, default filing conventions, generic client-letter tone — and the first week of a semester is spent correcting what the tool assumed about the clinic. Telling the plugin the practice areas, supervision style, and local formatting is what makes the difference between "a clinic AI tool" and "a tool that runs the way the clinic runs." The more specific the answers, the less a new student has to unlearn.

### Quick start or full setup — branching

The attorney picked quick or full in the preamble. Branch:

**Quick start path:** ask only the basics (practice area, jurisdiction, supervision style). Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for client-letter format, IRAC scaffolding, and deadline cadence. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/legal-clinic:cold-start-interview --full` anytime to do the whole interview, or `/legal-clinic:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.

**Pause for real answers.** Part 0 has tap-through role and integration checks. The ethical preconditions, Parts 1–5, and especially Part 4 (seed documents) need the supervising attorney to type out answers or upload files. When a question needs more than a quick tap:

- **Ask the question and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the attorney responds.
- **For uploads (handbook, filing guides, local rules, intake forms, example case files, sample motions, sample client letters):** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in the practice profile so you can fill it later — and I'll note what that means for `/ramp`, `/draft`, and `/client-letter` (they'll be thinner or fall back to defaults)." Then actually wait. Don't silently move on.
- **Before writing the practice profile:** review the interview. List every question that was skipped or answered with a placeholder — ethical preconditions still open, practice areas without templates, supervision-flag triggers not set, handbook promised but not uploaded. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the supervising attorney made to skip — not a question that scrolled past.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.
- **Pause and resume.** Tell the supervising attorney up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/legal-clinic:cold-start-interview` again later and I'll pick up where you left off." When the attorney pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /legal-clinic:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the attorney: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Part 0: Who's running this setup, ethical preconditions, and what's connected (before anything else)

#### Who's running this setup?

> Are you the supervising attorney for this clinic? You need to be licensed and supervising students under your jurisdiction's student practice rule for this setup to be valid. (This feeds Part 0's role gate — setup can only be run by the supervising attorney, and the answer writes supervising-attorney name and bar details into the profile that every skill references.)
>
> 1. **Yes, I'm the supervising attorney.** Continue.
> 2. **No, I'm a student / staff / administrator.** Stop. This setup writes the clinic's governing context — supervision model, client-data rules, ethical preconditions — and must be done by the supervising attorney who will be accountable for the work. Ask them to run `/legal-clinic:cold-start-interview`. Students run `/legal-clinic:ramp` to onboard each semester.

If the answer is 2, stop the interview and surface the above. Do not proceed.

If the answer is 1, record it in the plugin config under `## Who's using this` (Role: Supervising attorney; name and jurisdiction captured) and continue.

*Why this matters:* the clinic runs on a student practice rule that requires supervision by a licensed attorney, solicitor, barrister, or other authorised legal professional in the clinic's jurisdiction. Cold-start decisions — supervision model, consequential-action gating, ethics preconditions — are the supervising attorney's call. The role question gates those decisions to the right person.

#### Ethical & confidentiality preconditions

Before the professor interview starts — and before any student uses this plugin on a real client matter — confirm the following with the clinic's supervising attorney and the school's IT / ethics office. Do not skip this step.

1. **Account tier and data-handling terms.** Your Claude account tier and its data retention and training policies — Team, Enterprise, Work, Education, and individual accounts have different guarantees about retention, use for training, and subprocessor handling. Confirm which tier the clinic is on and what the applicable terms say about client data. Document the answer in the plugin config.

2. **Client consent and disclosure practices for AI-assisted work.** Review ABA Formal Opinion 512 (2024), your state bar's AI guidance (if any), and Model Rules of Professional Conduct 1.1 (competence), 1.4 (communication), 1.6 (confidentiality), and 5.3 (supervision of nonlawyer assistance). Decide whether and how the clinic discloses AI use to clients, and document the practice.

3. **How privileged and confidential material is handled.** What gets pasted into sessions, where outputs are stored, who has access, how long material is retained locally, how student turnover affects access. Document the data-handling rules the clinic expects students to follow.

4. **Practice-area heightened-confidentiality considerations.** Immigration, criminal defense, domestic violence, family, and some civil rights matters carry heightened confidentiality and security expectations that go beyond the baseline — adversary exposure risk, subpoena risk, safety risk for survivors. Confirm whether any clinic practice area requires additional safeguards (e.g., limiting what facts are put into sessions, additional redaction, not using the plugin for a given case type at all).

Capture the professor's answers. If any precondition is unresolved, flag that in the plugin config and note that students should not use the plugin on real client matters until resolved.

#### What's connected?

> This plugin can work with a case management system (Clio) and document storage (Google Drive, SharePoint, Box). Let me check which connectors are configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need all of these. Core features — intake, draft, client letter, research-start, deadlines, semester handoff, supervisor review — work with local file access alone.

Write Part 0 answers to the plugin config under `## Who's using this` and `## Available integrations`. If a populated CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/legal-clinic/*/CLAUDE.md` but not here, copy it forward first.

### Opening

> This is the one-time setup for your clinic. Ten to fifteen minutes. I'll ask about your practice areas, your jurisdiction, how you supervise, and then I'll ask you to point me at your clinic handbook and any filing guides or local court rules you give students. Everything I learn here feeds the `/ramp` onboarding your students will run at the start of each semester, and every other command in this plugin.
>
> None of this replaces your judgment or your students' analysis. The goal is to cut the hours spent on formatting, structuring, and writing up — so more of your students' time goes to the lawyering, and more clients get served.
>
> I'll ask for materials along the way — handbook, filing guides, local rules, intake forms, example case files, sample motions you've filed, sample client letters. Ten to twenty documents across the interview is the target. More is better. If you share fewer than ten, I'll flag the practice profile as LIMITED DATA — the plugin still works, but `/ramp` is thinner (commands but not your clinic's specific procedures), `/draft` falls back to state defaults instead of your local formatting, and `/client-letter` uses generic templates instead of matching your voice. Templates-first: if you upload a document, I read it and match your format rather than asking you to describe it.

### Part 1: The clinic (2-3 min)

**What kind of clinic?** (Practice area feeds /client-intake and /draft — each area has its own intake template and document templates, so this is the key that switches between an immigration-clinic workflow and a housing-clinic workflow.)
- Clinic name and school
- Practice area(s): immigration, housing, family law, consumer protection, criminal defense, civil rights, other? (Can be multiple — many clinics handle overlapping issues)

   **Practices that don't fit the boxes.** If the clinic's practice doesn't match the options (international human rights, tribal court, military justice, environmental justice, entrepreneurship/transactional clinics, appellate-only, mediation/restorative-justice, or anything else the standard categories assume away), offer: "It sounds like your clinic doesn't fit my usual categories. Tell me about it in your own words — what the clinic does, who it serves, what jurisdictions and forums, what the work looks like — and I'll build your clinic profile from that instead of forcing it into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.
- How many students this semester? How many active cases at a time, roughly?
- How many supervising professors/attorneys?

**Who are the clients?**
- Typical client situations — who walks in, what are they facing?
- Languages spoken beyond English?
- Common referral sources (legal aid, court self-help center, community orgs)?

### Part 2: Jurisdiction (1-2 min)

(This feeds /draft, /research-start, /memo, and /deadlines — jurisdiction determines filing formats, research scope, and default deadline calculations.)

- State. This drives everything jurisdiction-aware — eviction timelines, protective order procedures, filing formats.
- Primary court(s): which county/district court do cases land in most often?
- Any local rules or standing orders that diverge from state defaults?

### Part 3: Supervision style (2-3 min — this is the key design question)

> Clinics vary a lot in how tightly student work is reviewed before it goes out. Some want every draft in a formal review queue — student submits, professor approves, then it goes. Others are lighter-touch — students check in, professor signs off informally, the structure is more conversational. What's your model? (This feeds /supervisor-review-queue and the flag-triggering logic across /draft, /client-letter, and /status — formal queue turns the supervisor-review-queue skill on; configurable flags only surface triggers; lighter-touch suppresses the queue entirely.)

Three options to offer:

**Formal review queue:** Student output that's client-facing or court-bound goes into a queue. Professor reviews, approves or edits, then it releases. Every approval logged. (I'll keep a review queue skill active — `supervisor-review-queue` turns on.)

**Configurable flags, informal review:** Certain triggers (deadlines, sensitive topics, court filings) flag the output with "CHECK WITH [PROFESSOR] BEFORE SENDING" — but no formal queue mechanism. Student is responsible for checking in. (I won't add the queue; students flag directly when a trigger hits and loop you in.)

**Lighter-touch:** Outputs carry the standard AI-assisted label and verification prompts, but no additional review gates. Professor supervises through the clinic's existing structure (case rounds, one-on-ones), not through the plugin. (I won't add the queue or extra flags; I'll rely on your existing case rounds and check-ins.)

> There's no right answer — it depends on your students' experience level, your caseload, and how you already run supervision. You can change this later by editing CLAUDE.md.

Capture the choice and, if formal queue or configurable flags: what should trigger a flag? (Court filings always? Any deadline mention? Topics like DV, immigration status, criminal exposure?)

**Pedagogy dial.** After the supervision choice is captured, ask:

> **How much should the skills do?** This is the most important setting. Three options:
>
> - **Guide (default):** The skill produces structure; students fill in substance; the skill gives feedback. Balanced — most clinics start here.
> - **Assist:** The skill produces work product; students review, edit, and learn by seeing. Fastest, most productive, least pedagogical. Good for high-volume clinics.
> - **Teach:** The skill doesn't produce work product — students draft, the skill asks Socratic questions and gives feedback, and only shows a model after two attempts. Slowest, most pedagogical. Good for clinics where learning is the primary goal.
>
> You can set this per document type later with `/legal-clinic:build-guide`. For now, pick a default.

Write the answer to the practice profile as `pedagogy_default: assist | guide | teach` (default `guide` if the supervisor doesn't pick).

**Practice-area guide.** After the pedagogy default is captured, offer:

> Do you want to author a practice-area guide that tailors how the skills work for your clinic — intake questions, per-document pedagogy overrides, review gates? I can help you build one in 5-10 minutes with `/legal-clinic:build-guide`. You can also do it later. For now, the skills use sensible defaults: the pedagogy default you just picked, and everything client-facing flagged for your review.

Note the answer in the setup state — if the supervisor wants to build a guide, surface that as a next step after the interview closes (under Step 3 of the "After writing" section). Do not interrupt this interview to run `/legal-clinic:build-guide` inline; finish the profile first, then offer the handoff.

### Part 4: Seed documents (3-4 min)

> Three things, as many as you have. (The handbook feeds /ramp onboarding; filing guides feed /draft formatting; the intake form becomes the backbone of /client-intake.)
>
> 1. **Your clinic handbook or procedures doc.** Whatever you give students on day one. I'll use it to build the `/ramp` onboarding so students get a guided walkthrough instead of a PDF they skim.
>
> 2. **Filing guides and local court rules.** Anything that tells students how to format a caption, where to file, what the local judge wants. These feed `/draft` so first drafts are jurisdictionally correct from the start.
>
> 3. **Your intake form, and if you have one, a scrubbed example case file.** The intake form becomes the backbone of `/client-intake`. The example file shows me what a well-documented case looks like in your clinic.

**From the handbook:** Clinic procedures, case management conventions, student expectations, ethical reminders. This is what `/ramp` will teach.

**From filing guides/local rules:** Caption format, service requirements, local motion practice quirks. This is what `/draft` will apply.

**From the intake form:** Practice-area-specific fields. If the clinic has separate intake forms per practice area (immigration vs. housing), take all of them.

### Part 5: Practice-area templates (1-2 min)

For each practice area the clinic handles: what are the 3-5 documents students draft most often? (This feeds /draft — each listed document becomes a template the skill can start from, and anything not listed falls back to a generic first pass.)

| Practice area | Common documents |
|---|---|
| Immigration | Asylum application (I-589), motion to change venue, client declaration, FOIA request |
| Housing | Eviction answer, demand letter, repair request, motion to stay |
| Family | Protective order petition, custody motion, financial disclosure |
| Consumer | Debt validation letter, FDCPA demand, answer to collection suit |

These become the template set for `/draft`. If the professor has existing templates, ingest them. If not, note which ones to build.

**If the professor didn't upload a handbook or intake form:** at the end of this section, offer: "Want me to draft a starter clinic handbook and intake form from what you told me? Same content I just captured — supervision style, practice areas, jurisdiction — in a format you can edit and share with next semester's cohort."

## Before writing — re-read

Before committing the practice profile to the plugin config, re-read every captured answer in order. Catches:

1. **Contradictions between answers** — e.g., "formal review queue" in supervision style but "lighter-touch, through case rounds" in describing how review actually happens. Surface both and ask which governs.
2. **Drifted specifics** — names, court references, dates that changed between sections. Confirm final values.
3. **Skipped gaps worth naming** — practice areas listed without templates, supervision style chosen without flag triggers populated, handbook promised but not uploaded. Offer to complete now rather than leaving for `--redo`.

## Writing the practice profile

Per the CLAUDE.md template. Key sections:

- **Clinic profile** — name, school, practice areas, jurisdiction, student count
- **Supervision style** — which of the three models, and flag triggers if applicable
- **Practice-area templates** — intake templates and document templates per area
- **Jurisdiction** — state, courts, local rules ingested
- **Semester** — when do students turn over (so `/ramp` knows when it'll be needed, and `/semester-handoff` knows when it'll be triggered)
- **Handbook path** — where the ingested handbook lives, for `/ramp` to read

**LIMITED DATA flag:** if fewer than 10 materials were shared across the interview, add a `> LIMITED DATA` note at the top of CLAUDE.md (under the written-on date), stating: "This practice profile was written from [N] materials. Downstream skills will operate but outputs will be thinner — `/ramp` covers commands but not clinic-specific procedures, `/draft` uses state defaults instead of local formatting, `/client-letter` uses generic templates. Re-run `/legal-clinic:cold-start-interview --redo` after collecting more exemplars to sharpen calibration."

## Built-in safeguard framing

Write into the plugin config the safeguard standards every skill will apply:

```markdown
## Output safeguards (applied by every skill)

Every output includes:
- **AI-assisted label:** "[AI-ASSISTED DRAFT — requires student analysis and attorney review]"
- **Confidence indicators:** Where the skill is uncertain, it says so explicitly
- **Verification prompts:** Specific things the student should fact-check before relying on the output
- **Ethical reminders calibrated to task:** e.g., /draft outputs remind about ABA Formal Op. 512 supervision requirements

These are not optional and not configurable. They're the baseline.
```

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in law school clinic practice:**
>
> - **Student intake on a new case** — e.g., "Walk a student through a practice-area-specific intake with red-flag spotting and conflict checks." Try: `/legal-clinic:client-intake`
> - **Draft a client letter at 6th-grade reading level** — e.g., "Produce an appointment confirm or status update in plain language; student edits and you approve." Try: `/legal-clinic:client-letter`
> - **Build an IRAC memo scaffold** — e.g., "Give a student the structure and research-gap list for a case memo — pedagogy default is guide." Try: `/legal-clinic:memo`
> - **Track deadlines across the active docket** — e.g., "See what's due in the next 14 / 7 / 3 / 1 days with warnings per your cadence." Try: `/legal-clinic:deadlines`
> - **Ramp up a new cohort** — e.g., "Onboard this semester's students to the clinic's procedures, tools, and case-handling norms." Try: `/legal-clinic:ramp`
> - **Semester handoff** — e.g., "Build per-case transition memos for the incoming cohort." Try: `/legal-clinic:semester-handoff`
>
> **My suggestion for your first one:** Run `/ramp` yourself first so you see what your students will see at the start of the semester. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show the supervision style choice.** "You picked [formal queue / flags / lighter-touch]. That means [what it means in practice]. Right call?"

2. **Show the practice-area templates table.** "These are the documents `/draft` will know how to start. Missing anything?"

3. **Offer a `/ramp` preview.** "Want to see what a student's onboarding will look like? I can walk you through it as if you were a new student."

4. **Note what wasn't provided.** If no handbook: "`/ramp` will be thin until you upload a handbook — it'll cover the commands but not your clinic's specific procedures." If no local rules: "`/draft` will use state defaults for formatting — upload local rules when you have them."

5. **If LIMITED DATA flagged:** "Practice Profile is thin — downstream skills will be generic until more materials are added. Biggest gap: [specific — e.g., no handbook means /ramp covers commands only]. Biggest easy win: [specific — e.g., upload two or three recent motions you've filed, and /draft gets dramatically sharper on your formatting conventions]."

6. **Before your first case review, connect a research tool.** Say: "Before your first case review or memo: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you."

   <!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
        "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->

7. **Close with the "you can change anything later" note:**

> Done. Your clinic's configuration is at `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` — a plain text file you can read and edit directly. Anything you answered can be changed:
>
> - Edit the file directly for a quick change
> - Run `/legal-clinic:cold-start-interview --redo` for a full re-interview
> - Run `/legal-clinic:cold-start-interview --check-integrations` to re-check what's connected
>
> The things clinics most commonly tweak later: practice areas (when the clinic takes on a new one), supervision style (formal review queue vs. configurable flags vs. lighter-touch — many clinics start one way and shift after the first semester), and jurisdiction / local rules (when a matter lands in an unusual court). Your configuration will improve as students use the plugin — when `/ramp` misses something or `/draft` uses the wrong caption format, the fix is usually here.

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## What this does NOT do

- **Make supervision decisions.** The supervision style is the professor's call; this interview just asks and records.
- **Replace the clinic's existing case management.** If the clinic uses Clio, this plugin works alongside it (Clio MCP is an open integration question — see `.mcp.json`).
- **Onboard students.** That's `/ramp`. This is the professor's one-time setup.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/legal-clinic:customize`. They (usually the professor, sometimes
a student) want to change something in the clinic profile — a jurisdiction, a
supervision style, a practice-area template, a semester rollover — without
re-running the whole cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`.
   If the plugin config does not exist or still contains `[PLACEHOLDER]`
   values, say:

   > You haven't run setup yet. Run `/legal-clinic:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Clinic profile** — clinic name, host school, faculty lead, active
     practice areas, case type limits
   - **Jurisdiction** — primary state, courts, agencies, local rules path
   - **Supervision style** — informal vs. formal review queue; if formal,
     who reviews what before it goes out
   - **Practice-area templates** — which templates are active (immigration,
     housing, small business, family, expungement, etc.) and any local
     overrides
   - **Semester** — current semester, active students, rollover rules,
     handoff memo format
   - **Output safeguards** — plain-language standards for client-facing
     outputs, deadline warning rules, privilege labeling
   - **Seed documents** — clinic handbook, jurisdiction rules, template
     letters, sample memos, form libraries
   - **Outputs** — supervisor guide format, client letter templates, memo
     scaffolds
   - **Workflow** — case directories, deadline tracker location, review
     queue channel
   - **Integrations** — document storage / Slack / court e-filing status,
     fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Adding a new practice area:* "`/client-intake` will route matters of this
     type through the new template. `/draft`, `/memo`, and `/client-letter`
     will use the practice-area prompts. `/research-start` will add the
     corresponding Westlaw search terms."
   - *Supervision style informal → formal review queue:* "`/supervisor-review-queue` becomes
     active — student output will land there for supervisor sign-off before
     it goes to the client."
   - *New semester rollover:* "I'll archive the prior semester's active
     cases, carry forward matters you flag as continuing, and prompt the
     incoming students through `/ramp`."

5. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/legal-clinic:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "drop" a practice area,
  offer to mark it `[Archived]` and explain that archiving keeps case
  history accessible but hides the template from `/client-intake` routing.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., formal review queue on + informal supervision note;
  or practice area on + no jurisdiction rules configured), flag the
  tension.
- **Flag guardrail degradation.** These are load-bearing and should not be
  removed: the "NOT final work product" framing on `/draft`, plain-language
  standards on client-facing outputs, "does NOT decide case acceptance" on
  `/client-intake`, "NOT substantive advice" on `/client-letter`, and the
  scaffold-not-analysis framing on `/memo`. These exist because students
  ship work product — if the safeguards go, the risk of student work
  reaching a client without supervisor review goes up. Confirm the
  trade-off with the user, and if they're a student rather than the
  professor, suggest they discuss it with the supervisor first.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/deadlines', 'legal', 'deadlines', '', 'deadlines', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /deadlines

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → jurisdiction, practice areas, warning-day cadence.
2. Use the workflow below.
3. Route by flag:
   - `--add`: capture case, type, description, due date, source, owner. Write to `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml`. Check for duplicates first.
   - `--report` (default): cross-case rollup — overdue, next 3d, next 7d, next 14d; by owner; by practice area; unassigned flags.
   - `--update [id]`: modify fields; log note with date.
   - `--complete [id]`: mark done; confirm with student that work is actually filed/submitted.
   - `--close [id]`: close-without-completing; require rationale in notes.
4. Confirm any write before committing.

---

# Deadlines

## Purpose

A clinic's biggest operational risk is a missed deadline. Students carry multiple cases, work part-time, turn over every semester. Deadlines that live only in individual students' heads get dropped at handoff, get forgotten during finals week, get missed when a student unexpectedly withdraws from the clinic. This skill is the central operational record.

The supervising attorney is on the hook if a deadline is missed. The skill is calibrated to that stakes level — warnings fire early, overdue items stay visible until explicitly resolved, handoffs (via `/semester-handoff`) pull the deadline list forward to the next student.

## Load context

- `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → jurisdiction, practice areas, deadline warning days (default 14/7/3/1), supervising attorneys
- `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml` — the ledger

**Jurisdiction assumption.** Deadline calculations and warning thresholds assume the jurisdiction set in CLAUDE.md. Deadlines, tolling rules, computation-of-time rules, and local court practices vary materially by jurisdiction and by specific court. If a matter involves a different state, a specific court's local rules, or a federal vs. state forum question, confirm the deadline against the governing rule with your supervisor before relying on it.

## Modes

Flag: `--add | --report | --update | --complete | --close` (default: report)

### `--add` — log a new deadline

**Inputs:**
- Case ID + name (which case)
- Practice area
- Type (filing / hearing / statute-of-limitations / discovery / cure-period / response / notice / other)
- Description — one line of what's due
- Due date (and time + timezone if applicable)
- Source — where the deadline came from (court order served 2026-04-20, statute 8 USC § 1229a, cure period in contract §7)
- Owner student — the student responsible

The skill generates an `id` slug automatically: `[case]-[short-desc]-[YYYY-MM]`.

**Extraction from other skills:** when `/client-intake`, `/draft`, or `/status` surface a deadline in their output, they should hand off to this skill with pre-populated fields. Student confirms and adds.

**Pre-add check:** if a deadline with the same case_id + type + due_date already exists, flag as likely duplicate and ask before adding.

**Plausibility sanity band.** After the student enters a due date, do NOT compute or verify — but apply a rough plausibility check against typical ranges for the filing type, and flag the student if the date falls far outside. This is scaffolding to catch gross errors in the student's own math, not an alternative to computing against the rule.

**Bands are jurisdiction-keyed.** Load the band file for this clinic's jurisdiction from `references/plausibility-bands/{state}.md` where `{state}` is the two-letter code from `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → clinic jurisdiction (and federal always loads alongside). The legal-clinic plugin ships `references/plausibility-bands/CA.md` (fully populated) and `references/plausibility-bands/IL.md` (placeholder structure) as starting points.

**Hard stop at cold-start if the band file is missing.** If `references/plausibility-bands/{state}.md` does not exist for the clinic's jurisdiction, do NOT silently run without plausibility checks. At cold-start, tell the supervisor:

> "I don't have deadline plausibility checks for [state] — the sanity band for this clinic's jurisdiction isn't in the shipped reference files. I can still track deadlines (add, report, update, complete, close), but I cannot sanity-check them against typical ranges. Here's how to build the band file from your state's rules: copy `references/plausibility-bands/IL.md` as a template, fill in one row per deadline type your clinic sees most (typical range, triggering-event handling, computation-of-time rule, short cite), save at `references/plausibility-bands/{state}.md`, and re-run `/legal-clinic:deadlines`. Until then, every deadline I accept will carry `warnings: no-plausibility-band` and your review should treat dates as unchecked."

Do not fall back to the CA table for a non-CA clinic. The silent-degradation case — shipping a California sanity check to an Illinois clinic — is the failure this fix exists to close.

**Sanity check logic:**

1. Load the bands table for this clinic's jurisdiction from `references/plausibility-bands/{state}.md` (plus federal-always).
2. After the student enters `due:`, compare to triggering-event date + typical range for that `type:` (if a typical range exists in the loaded band file for the filing type).
3. If inside the range, write the entry. Say nothing — the band exists to catch errors, not to congratulate correct math.
4. If outside the range by a material margin, stop before writing and say:
   > The date you entered falls outside the typical range for [type] in [jurisdiction]. [Type] deadlines for [filing type] typically fall ~[range] after [triggering event]. Your entry: [date], which is [N] days from [triggering event]. Re-check your calculation against [cited rule from the band file] and the jurisdiction's computation-of-time rule. If your calculation is correct (local rule exception, atypical triggering event, tolling, waiver), confirm and I will add the entry as-is. Otherwise, recompute and re-run `/deadlines --add`.
5. If no band is known for this `type:` (unusual filing, non-standard deadline), do not sanity-check — write the entry and note in the `warnings:` field that no plausibility band applies.
6. If the band file is missing entirely for this jurisdiction, the hard stop above applies at cold-start; in steady-state (supervisor acknowledged the gap and proceeded), every entry is written with `warnings: no-plausibility-band`.

**The skill does not compute.** If the student enters `[VERIFY]` in the `due:` field because they haven't done the math yet, write the entry with `due: [VERIFY]` — the sanity band runs only when the student supplies a concrete date. The computation stays with the student and supervisor.

### `--report` (default) — cross-case rollup

Read `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml`. Produce:

```markdown
# Deadline Report — [today]

**Active deadlines:** [N]
**Overdue:** [N] ⚠️
**Due this week (next 7 days):** [N]

---

## ⚠️ Overdue (flagged for immediate attention)

| ID | Case | Type | Due | Owner | Days overdue |
|---|---|---|---|---|---|

## 🔴 Due today / next 3 days

| ID | Case | Type | Due | Owner |
|---|---|---|---|---|

## 🟡 Due in 4-7 days

| ID | Case | Type | Due | Owner |
|---|---|---|---|---|

## 🟢 Due in 8-14 days

[list]

## Beyond 14 days

[count only — expand with `/deadlines --report --horizon=30` for details]

---

## By owner student (workload distribution)

| Student | Overdue | Next 7d | Next 14d | Total active |
|---|---|---|---|---|

## By practice area

[same table, grouped by area]

## Unassigned deadlines

[list — flag if any active deadline has no owner_student]
```

### `--update` — modify an existing deadline

Common updates: due date changed (court continuance), owner changed (reassignment), notes added.

Every update writes a dated note inline; history is visible in the entry.

### `--complete` — mark done

- Sets `status: completed`, `completed_date: [today]`.
- Confirms with the student that the actual work is done and filed/submitted.
- Removes from active reports but stays in the yaml.

### `--close` — close without completing

For deadlines that no longer apply — case settled, motion withdrawn, client dropped the matter. Requires a `notes:` entry explaining why.

## Warning cadence

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` deadline warning days. Default 14, 7, 3, 1.

Warnings don't auto-surface — this plugin has no scheduled/agent behavior. But any time `/deadlines` is invoked (or `/status`, which routes to this skill for deadline checks), the report pulls forward anything hitting a warning threshold.

If a deadline passes its due date without being marked complete, it moves to `status: overdue` and stays there in every report until explicitly resolved. Overdue deadlines do not auto-close.

## Integration

- **`/client-intake`:** when intake surfaces a timeline urgency (eviction notice date, asylum filing deadline, hearing date), offer to `/deadlines --add` with pre-populated fields.
- **`/draft`:** when a filing draft references a deadline (answer due, objection window), offer to add.
- **`/status`:** the status skill reads `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml` for the relevant case and includes upcoming deadlines in its output.
- **`/semester-handoff`:** reads deadlines.yaml to identify all active deadlines across departing-student cases; each handoff memo carries the deadlines forward.
- **`/supervisor-review-queue` (if formal review enabled):** deadlines near their cutoff get priority in the review queue.

## What this skill does not do

- **Calculate deadlines from triggering events.** If a complaint was served today and the answer is due in 21 days per local rules, the skill doesn't do that math — the student does, using the rule, and logs the resulting date. (Doing the math autonomously creates a liability the skill shouldn't own; rules vary by jurisdiction and court.)
- **File or serve anything.** The skill tracks dates; filing happens outside the plugin.
- **Auto-notify.** No scheduled notifications. The report surfaces warnings when invoked; it doesn't push. A scheduled cron could be added later but would need explicit professor opt-in per clinic.
- **Override local rules.** If the student logs a due date that contradicts local rules, the skill doesn't catch it. Another reason to calendar with `[VERIFY: confirm against local rule]` for any non-routine deadline.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/draft', 'legal', 'draft', '', 'draft', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /draft

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice-area templates, jurisdiction, local rules, supervision style.
2. Use the workflow below.
3. Match doc type to template. Gather facts from case notes — flag missing, never guess.
4. Apply jurisdiction formatting. Draft with `[FACT NEEDED]`, `[VERIFY]`, `[UNCERTAIN]` flags inline.
5. Output with prominent AI-assisted label, student review checklist, supervision routing.

```
/legal-clinic:draft eviction-answer
```

```
/legal-clinic:draft asylum-declaration
```

---

# Draft: First-Draft Document Generation

## Purpose

Students spend enormous time on first drafts of documents where the educational value is in the analysis and strategy, not in formatting a caption or writing "Dear Judge." This skill produces the first draft from case notes and practice-area templates so the student's time goes to the thinking.

**Every draft is explicitly a starting point.** Not final work product. The student analyzes, revises, and the professor reviews before anything goes anywhere.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice areas, practice-area templates, jurisdiction (state + local court + any local rules ingested), supervision style.

Case notes or intake summary for the facts.

## Pedagogy check

Read the supervisor guide for this practice area at `~/.claude/plugins/config/claude-for-legal/legal-clinic/guides/<practice-area>.md`. Check the `pedagogy_posture` setting:

- **`guide` (default):** Produce the structure and the checklist. Ask the student to draft each section. Give feedback on their draft (register, reading level, required elements, what they missed). Offer to fill a section only when the student has tried once.
- **`assist`:** Produce the work product. Flag items for student review. The student edits and learns by reviewing.
- **`teach`:** Don't produce the work product. Ask the student to draft it. Give feedback. Ask leading questions when they're stuck. Only show a model paragraph after two attempts, and only the section they're stuck on. Track what they got right and wrong so the supervisor can see progress.

If no guide exists, use `guide`. If the guide exists but doesn't set a posture, use `guide`.

Whatever the posture, the output always includes: "**Pedagogy mode: [assist/guide/teach]** — set by your supervisor's guide. This means I [description of what the student did vs what the skill did]."

**Jurisdiction assumption.** The draft assumes the state, court, and local rules set in CLAUDE.md. Caption format, service requirements, page limits, filing windows, and substantive rules vary materially across jurisdictions and even between courts in the same state. If the matter is in a different court or a different state, confirm with your supervisor before relying on any format, deadline, or argument in the draft.

## Workflow

### Step 1: Which document?

Match the request to the clinic's template set (from `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`). Common set by practice area:

| Practice area | Documents |
|---|---|
| **Immigration** | I-589 asylum application narrative, client declaration, motion to change venue, motion to continue, FOIA request, country conditions summary |
| **Housing** | Eviction answer, demand letter (repairs/deposit), motion to stay execution, discovery requests |
| **Family** | Protective order petition, custody declaration, motion to modify, financial affidavit |
| **Consumer** | Debt validation letter, FDCPA demand letter, answer to collection complaint, motion to vacate default |
| **General litigation** | Motion template, notice of appearance, certificate of service |

If the requested document isn't in the template set: "The clinic's templates don't include [X]. I can attempt a draft from general principles, but flag this heavily — it hasn't been tuned for your practice area or jurisdiction. Better to ask [Professor] if there's an existing template."

### Step 2: Gather the facts

Read the intake summary or case notes. For each fact the document needs: do we have it?

| Document needs | Have? | Source |
|---|---|---|
| [fact] | ✓ / ✗ | [intake / client doc / need to get] |

Missing required facts → don't guess. Mark them: `[FACT NEEDED: client's entry date — get from I-94 or ask client]`.

### Step 3: Apply jurisdiction

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` jurisdiction:

- **Caption format:** state and local court rules. If local rules were ingested at cold-start, use them. If not, use state default and flag: `[VERIFY CAPTION: local rules not loaded — confirm format against [Court]'s current rules]`
- **Service requirements:** who gets served, how, by when per the court's rules
- **Local quirks:** page limits, font requirements, standing orders. Apply what's ingested; flag what isn't.

### Step 4: Draft

Use the practice-area template. Fill what can be filled from facts. Leave placeholders explicit — never fill with plausible-sounding invention.

**Everywhere the draft makes a legal assertion:** that assertion is a hypothesis the student verifies, not a conclusion the draft guarantees. Mark accordingly.

### Step 5: Flag uncertainty

Three kinds of flags, in-line:

- `[FACT NEEDED: ...]` — the document needs a fact the case notes don't have
- `[VERIFY: ...]` — a legal or factual assertion that needs checking before this is filed
- `[UNCERTAIN: ...]` — the skill is genuinely unsure and says so rather than guessing

### Step 6: Supervision routing

Filing a document with a court or agency is a consequential action. The gate is the supervision workflow in `## Supervision style` in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`, reinforced by the Part 0 role check that confirms a licensed supervising attorney owns the clinic setup. Court filings always route through supervision before filing, regardless of the supervision-style choice.

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` supervision style:
- **Formal queue:** draft goes to queue, student sees "queued for [Professor]"
- **Configurable flags:** if this document type is a flag trigger (court filings usually are), output includes "CHECK WITH [PROFESSOR] BEFORE FILING"
- **Lighter-touch:** standard safeguard label, no additional gate — but court filings still go to the professor before filing per the clinic's existing supervision structure

## Output

```markdown
═══════════════════════════════════════════════════════════════════════
  AI-ASSISTED DRAFT — REQUIRES STUDENT ANALYSIS AND ATTORNEY REVIEW
  This is a starting point, not final work product.
  Every [VERIFY] and [FACT NEEDED] flag must be resolved before filing.
═══════════════════════════════════════════════════════════════════════

[The document — in the practice-area template format, jurisdiction-aware,
with flags inline]

═══════════════════════════════════════════════════════════════════════

## Student review checklist

Before showing this to [Professor]:

- [ ] Read the whole thing. Does it say what you want it to say?
- [ ] Every fact: is it accurate per the client's actual documents, not just the intake notes?
- [ ] Every [VERIFY] flag: resolved with research or struck
- [ ] Every [FACT NEEDED] flag: filled with verified information or the section removed
- [ ] Legal theory: is this the right argument? Are there better ones? (That's your analysis, not the draft's.)
- [ ] Jurisdiction: caption, service, format correct per current local rules
- [ ] [Supervision step per CLAUDE.md style]

## What this draft does NOT do

- It does not decide strategy. The draft follows the most common approach for
  this document type — you decide if that's right for this client.
- It does not verify its own legal assertions. Every legal conclusion above is
  a hypothesis until you research it.
- It does not file itself. [Professor] reviews, you file per clinic procedure.

---

**Before this leaves the clinic.** This is a student draft for supervising-attorney review, not a final letter, filing, or form. Filing it with a court or agency, or sending it to a client or opposing party, has legal consequences for the client. A licensed supervising attorney reviews, edits, and signs off before it leaves the clinic. Strip the AI-assisted draft header only after that sign-off. Do not send or file this draft without supervisor approval.

*ABA Formal Opinion 512 (2024): generative AI use requires competence,
supervision, and verification. This draft is designed to be supervised and
verified — it is not designed to be trusted without that.*
```

## What this skill does NOT do

- **Produce final work product.** First draft only. Student revises, professor reviews.
- **Guess at missing facts.** Flags them for the student to get.
- **Decide the legal theory.** Uses the common approach; the student decides if it's the right one for this case.
- **Replace jurisdiction-specific research.** Applies ingested local rules; flags where rules weren't ingested or might have changed.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/form-generation', 'legal', 'form-generation', '', 'form-generation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# [DEPRECATED] Form Generation → see `/draft`

This skill was folded into `skills/draft/` during the v2 rebuild. The `/draft`
command handles first-draft generation for all clinic documents including form
population (asylum applications, eviction answers, protective order petitions,
etc.) with practice-area templates and jurisdiction-aware formatting.

**Use `/draft [document type]` instead.**

See `skills/draft/SKILL.md` for the full workflow.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/memo', 'legal', 'memo', '', 'memo', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /memo

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice areas, jurisdiction.
2. Use the workflow below. Read intake summary / case notes.
3. Frame issues as questions. Scaffold IRAC for each — Rule blocks are RESEARCH NEEDED, Application is STUDENT ANALYSIS prompts, Conclusion is blank.
4. Strengths/weaknesses/open questions. Research gaps summary.
5. Output with prominent "the analysis is yours" label.

```
/legal-clinic:memo
```

---

# Memo: Internal Case Analysis

## Purpose

The case analysis memo is where the student's thinking lives. This skill provides the IRAC scaffolding and flags the research gaps — the student fills in the analysis.

**The analysis is the student's.** This skill structures; it doesn't conclude.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → practice areas, jurisdiction, supervision style.
Intake summary and case notes for facts.

## Pedagogy check

Read the supervisor guide for this practice area at `~/.claude/plugins/config/claude-for-legal/legal-clinic/guides/<practice-area>.md`. Check the `pedagogy_posture` setting:

- **`guide` (default):** Produce the IRAC structure and the research-gap list. Ask the student to draft each rule statement themselves from research, rather than giving them a framework. Give feedback on what they wrote. Offer to fill the framework rule for a section only when the student has tried once.
- **`assist`:** Produce the memo scaffold and fill what can be filled. Flag items for student review. The student edits and learns by reviewing. (Note: this memo skill always leaves the `[STUDENT ANALYSIS]` and `[STUDENT CONCLUSION]` blocks blank by design — `assist` means the skill produces the IRAC scaffold and framework rule statement; it does not produce the application or the conclusion.)
- **`teach`:** Don't produce the framework or the scaffold content. Ask the student to frame the issues, state the rules from their research, and do the application. Give feedback. Ask leading questions when they're stuck. Only show a model rule statement or a model application paragraph after two attempts, and only for the section they're stuck on. Track what they got right and wrong so the supervisor can see progress.

If no guide exists, use `guide`. If the guide exists but doesn't set a posture, use `guide`.

Whatever the posture, the output always includes: "**Pedagogy mode: [assist/guide/teach]** — set by your supervisor's guide. This means I [description of what the student did vs what the skill did]."

## Workflow

### Step 1: Frame the issues

From the intake summary and case notes: what are the legal questions this case presents?

State each as a question. Not "habitability" — "Can the client assert a habitability defense to the eviction based on the broken heater, and if so, does it offset the rent owed?"

If there are multiple issues, each gets its own IRAC block.

### Step 2: Scaffold the IRAC

For each issue:

**Issue:** Stated as a question (from Step 1).

**Rule:** This is a research gap, not a conclusion. State what the student needs to find:

> `[RESEARCH NEEDED: [State] habitability doctrine — warranty of habitability
> elements, what conditions qualify, remedies available including rent offset.
> Start with: [State] landlord-tenant statute, then case law on heater/heat
> specifically. See /research-start for a roadmap.]`

If the skill has high confidence in the general rule framework (e.g., "most states recognize an implied warranty of habitability"), state that as a framework starting point — **but explicitly mark it as unverified**:

> *Framework (unverified — confirm for [State]):* Most jurisdictions recognize
> an implied warranty of habitability requiring landlords to maintain
> conditions fit for human occupation. Breach may give rise to rent withholding,
> repair-and-deduct, or rent abatement.
> `[VERIFY: [State]'s specific elements and remedies]`

**Application:** This is where the student's analysis goes. Scaffold the structure, don't fill it:

> `[STUDENT ANALYSIS: Apply the rule to the facts. Key facts to address:
> - Heater broken since November — how long is "unreasonable"?
> - Client notified landlord [when? how? documented?]
> - Landlord's response or lack thereof
> - [State]-specific: does client need to have given written notice?
>   deposited rent in escrow? other procedural prerequisites?]`

List the facts that matter. Let the student do the applying.

**Conclusion:** Explicitly blank:

> `[STUDENT CONCLUSION: Based on your research and analysis above, what's the
> likely outcome? How strong is this defense? What are the weaknesses?]`

### Step 3: Identify strengths, weaknesses, open questions

Separate section, after the IRAC blocks:

**Strengths (apparent from facts — student should test these):**
- [Fact that seems helpful and why]

**Weaknesses (apparent from facts — student should assess how serious):**
- [Fact that seems harmful and why]
- `[UNCERTAIN: whether [X] is actually a weakness — depends on [State] rule on [Y]]`

**Open questions (things the memo can't answer without more info):**
- Factual: [what we don't know from the client]
- Legal: [what needs research]
- Strategic: [judgment calls for the student/professor]

## Output

```markdown
═══════════════════════════════════════════════════════════════════════
  AI-ASSISTED SCAFFOLD — THE ANALYSIS IS YOURS TO WRITE
  Every [RESEARCH NEEDED] and [STUDENT ANALYSIS] block is a prompt, not
  a placeholder to delete. The thinking happens when you fill them in.
═══════════════════════════════════════════════════════════════════════

# Case Analysis Memo: [Client] — [Matter]

**Date:** [date] | **By:** [student] | **For:** [Professor]

---

## Bottom line

[Take the case / Decline because X / Need more info on Y — next step is Z]

---

## Issues Presented

1. [Issue as question]
2. [Issue as question]

---

## Issue 1: [Issue]

### Rule

[Framework starting point with VERIFY flags, and RESEARCH NEEDED blocks]

### Application

[STUDENT ANALYSIS scaffold with the facts that matter]

### Conclusion

[STUDENT CONCLUSION — blank]

---

[repeat for each issue]

---

## Strengths

[list with caveats]

## Weaknesses

[list with UNCERTAIN flags where applicable]

## Open Questions

**Factual:** [list]
**Legal:** [list — these feed /research-start]
**Strategic:** [list — these are for discussion with Professor]

---

## Research gaps summary

[Every RESEARCH NEEDED block pulled out into one list, so the student can
work through them systematically — and can run /research-start on each]

═══════════════════════════════════════════════════════════════════════

## What this memo is NOT

This is a scaffold, not an analysis. The [STUDENT ANALYSIS] blocks are where
the educational value lives — filling them in is the work. A memo where those
blocks are still empty is a memo that hasn't been written yet.

---

**Cite verification — required before use.** Any framework rules, cases, or statutes suggested above were generated by an AI model and have not been verified. Before relying on any citation — or including it in client work — run it through Westlaw, CourtListener, or your clinic's research platform for accuracy and current good-law status. Flag unverified citations to your supervisor.

**Source attribution.** Tag every suggested citation in the scaffold with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the supervising attorney or case file supplied. Citations tagged `verify` carry higher fabrication risk than tool-retrieved citations and should be checked first. Never strip or collapse the tags — they are the supervisor's fastest signal about which citations to verify.

**No silent supplement.** If a query to a configured research tool returns few or no results for a rule the memo needs, say so and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / issue]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave `[RULE TO VERIFY]` and stop. Which would you like?" The supervising attorney decides whether to accept lower-confidence sources.
```

## What this skill does NOT do

- **Write the analysis.** It scaffolds the IRAC and flags the gaps. The student reasons through the application.
- **Provide verified rules.** Every rule statement is explicitly unverified until the student researches it.
- **Reach conclusions.** The C in IRAC is blank on purpose.
- **Replace the conversation with the professor.** The Open Questions / Strategic section is the agenda for that conversation, not a substitute.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/plain-language-letters', 'legal', 'plain-language-letters', '', 'plain-language-letters', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# [DEPRECATED] Plain-Language Letters → see `/client-letter` and `/status client`

This skill was split during the v2 rebuild:

- **Routine correspondence** (appointment confirms, document requests, brief
  "we filed it" updates) → `skills/client-letter/` — use `/client-letter [type]`

- **Substantive client status updates** → `skills/status/` in client-facing
  mode — use `/status client`

Both apply the plain-language standards (reading level, no jargon) from CLAUDE.md.

See the respective SKILL.md files for full workflows.$body$)
ON CONFLICT (skill_key) DO NOTHING;
