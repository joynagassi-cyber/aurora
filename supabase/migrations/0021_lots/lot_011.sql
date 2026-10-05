INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/ramp', 'legal', 'ramp', '', 'ramp', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /ramp

1. Check `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` is set up. If placeholders: "Ask [professor] to run `/legal-clinic:cold-start-interview` first."
2. Use the walkthrough below.
3. Walk through: clinic context (from handbook) → commands → practice exercises (fake intake, practice draft, research roadmap) → verification habits.
4. `--card`: generate the one-page reference card.

```
/legal-clinic:ramp
```

```
/legal-clinic:ramp --card
```

---

# Ramp: Semester Onboarding

## Purpose

Every semester, the clinic loses its entire workforce and rebuilds from scratch. New students need to learn procedures, case management, filing conventions, and practice-area basics before they're useful. Traditionally that takes weeks of reading PDFs and asking the professor the same questions every semester.

This skill is the guided walkthrough. It reads what the professor uploaded during cold-start — the handbook, the filing guides, the local rules — and teaches it interactively, with practice exercises so students try the tools in a low-stakes setting before a real client is on the line.

**Audience: students.** Professors don't run this (they run `/cold-start-interview`).

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → clinic profile, practice areas, jurisdiction, handbook path, supervision style, practice-area templates.

If that file is missing or still has placeholders: "The clinic hasn't been set up yet. Ask [supervising professor] to run `/cold-start-interview` first."

## The walkthrough

### Opening

> Welcome to [clinic name]. I'm going to walk you through how this clinic works and how to use these tools — about twenty minutes, and you can pause anytime. By the end you'll have run a practice intake, drafted a practice document, and you'll know what to do when you get your first real case.
>
> One thing up front: everything I generate is a starting point, not a final answer. You do the analysis. [Professor] reviews your work [per supervision style]. I handle the formatting and the first draft so you spend your time on the lawyering, not on writing "Dear Judge" for the twentieth time.

### Part 1: This clinic (5 min)

Read from `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` and the ingested handbook. Cover, interactively:

- **Practice areas** — what the clinic handles, what it doesn't (and where to refer if someone walks in with an out-of-scope issue)
- **Clients** — who they are, what they're facing, languages
- **Jurisdiction** — which courts, which judges, what the local quirks are
- **Case management** — how cases are tracked, where files live, what a well-documented case looks like
- **Supervision** — how review works in this clinic (per the supervision style in CLAUDE.md). Be specific: "Before anything goes to a client or a court, [it goes in the review queue / you check with Professor X / etc.]"

Don't lecture — check understanding. "So if a client comes in with an eviction notice but also mentions they're undocumented, what do you do?" (Answer: both issues get noted in intake; the immigration question may need a referral or a flag to the professor, depending on the clinic's scope.)

### Part 2: The commands (5 min)

Walk through each command the student will actually use:

| Command | When you use it | What you get |
|---|---|---|
| `/client-intake` | Client interview | Formatted case summary with issues spotted, conflict flags, triage |
| `/draft [doc type]` | Need a first draft of a common document | Practice-area template filled from case notes — *starting point, not final* |
| `/memo` | Need to analyze a case internally | IRAC-format memo with research gaps flagged |
| `/research-start [issue]` | Starting legal research | Roadmap: statutes to check, case law areas, search terms — *leads, not authoritative cites* |
| `/status [audience]` | Updating someone on a case | Summary tailored to client / professor / court |
| `/client-letter [type]` | Routine correspondence | Appointment confirm, doc request, status update from templates |

For each: what it does, what it explicitly doesn't do, what the student verifies before relying on it.

### Part 3: Practice exercises (8-10 min)

**Low-stakes. Fake client. Real tools.**

**Exercise 1 — Practice intake:**
> Here's a fake client scenario: [practice-area-appropriate hypo — e.g., for a housing clinic, "Maria got a 3-day notice to quit last Tuesday. She's two months behind on rent after losing her job. The apartment has had a broken heater since November. She has two kids."]
>
> Run `/client-intake` and interview me as if I'm Maria. I'll answer as Maria would. At the end, look at the case summary it produces — what issues did it spot? Did it catch the habitability defense?

Debrief: what the intake caught, what the *student* should have probed deeper on, what gets flagged for the professor.

**Exercise 2 — Practice draft:**
> Using Maria's intake, run `/draft eviction-answer`. You'll get a first draft.
>
> Read it. What's right about it? What's wrong? What would you change before showing it to [Professor]?

The point: the draft is competent but not final. The student learns to read critically, not accept.

**Exercise 3 — Research roadmap:**
> Run `/research-start "habitability defense to eviction in [state]"`. You'll get a roadmap — statutes, case law areas, search terms.
>
> None of those citations are verified. That's on purpose. Pick one statute from the roadmap and tell me how you'd verify it's current and applies here.

The point: `/research-start` is a starting place, not a citation. The student still does the research.

### Part 4: Verification habits (2 min)

The habits that matter:

- **Every output is a starting point.** If it went to a client or a court without you reading it critically, something went wrong.
- **Verify every citation** before it goes in anything. `/research-start` gives leads, not authorities.
- **Check jurisdiction-specific details.** The plugin knows your state from setup, but local court quirks change — double-check against current local rules.
- **When uncertain, it says so.** If an output has a `[UNCERTAIN: ...]` flag, that's a prompt to research or ask the professor, not to delete the flag and move on.
- **[Supervision reminder per CLAUDE.md style]** — what gets reviewed before it goes out, and how.

### Closing

> That's it. You've run an intake, drafted a document, and built a research roadmap. Your first real case will feel similar, except the client is real and the professor is reading your work.
>
> The one-page reference card: `/ramp --card`

## `/ramp --card`

Generate the one-page student reference card per the one-page card spec. Contents:

- The commands (table from Part 2, condensed)
- What Claude can help with / what it can't (starting points yes, final work product no, authoritative citations no)
- Verification habits (the bullets from Part 4)
- Who to ask when stuck (professor name from CLAUDE.md)

Printable. One page. Hand it out on day one.

## What this skill does NOT do

- Replace the professor's orientation. It covers procedures and tools; the professor covers judgment, strategy, and the things you only learn by watching someone good do it.
- Teach substantive law. Practice-area *orientation*, not a doctrinal course.
- Certify the student as ready. The professor decides when a student takes a real case.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/research-start', 'legal', 'research-start', '', 'research-start', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /research-start

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → jurisdiction, practice area.
2. Use the workflow below.
3. Frame the issue specifically. Build roadmap: statutory starting points (unverified), case law areas (not cases), secondary sources, search terms.
4. If student has existing research uploaded: synthesize and identify gaps.
5. Output with prominent "leads not authorities" header. Everything is a starting point the student verifies.

```
/legal-clinic:research-start "habitability defense to nonpayment eviction in [State]"
```

---

# Research Start: Roadmap, Not Research

## Purpose

Legal research is essential to clinical education. But the initial phase — figuring out *what* to research, finding the right statute, understanding the framework — is often the most time-consuming and least educational part. Students spend hours finding the starting point before they can do the actual research.

This skill produces the starting point: statutes to check, case law areas to investigate, search terms for Westlaw and CourtListener. **None of it is verified. None of it is authoritative. All of it is a lead for the student to run down.**

**This is a pedagogical safeguard, not just an ethical one.** Students still learn to research. They just start from a better place.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → jurisdiction (state), practice areas.

## Workflow

### Step 0: Seed documents first

**Before building the roadmap, read the clinic's own seed documents.** The supervising attorney uploaded them at cold-start (handbook, filing guides, local court rules, intake forms, example case files, prior memos) — they are pre-vetted, jurisdiction-specific, and will beat any Westlaw query on the first 20 minutes of a student's research.

1. Read `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → `## Seed documents`. Identify any item whose purpose or filename matches the research area (e.g., "Alameda UD filing guide" for a UD habitability question; a redacted sample case file in the same practice area; a prior memo on the same issue).
2. For each match, surface it as a **Seed documents to read first** block at the top of the roadmap output. Name the file, say why it matters for this specific question, and say what it likely covers vs. where outside research will still be needed.
3. If no seed documents match the issue, say so plainly ("No clinic seed documents match this issue — proceeding straight to primary sources"). Don't fabricate a match.
4. If the clinic has the `LIMITED DATA` flag set in `## Seed documents`, add a one-line note: "Clinic has fewer than 10 seed docs; your professor's precedent bank is thin — lean harder on primary sources and flag what's missing for your supervisor."

The roadmap still covers statutes, case law areas, secondary sources, and search terms — seed docs are the first lead, not a replacement for the rest. But surface them above everything else so the student starts where their supervisor's precedent starts.

### Step 1: Frame the issue

What's the research question? Be specific. Not "eviction defenses" — "habitability defense to nonpayment eviction in [State], specifically whether a broken heater qualifies and whether the tenant had to give written notice."

If the question is too broad, narrow it with the student: "That's three research questions. Let's take them one at a time. Which first?"

### Step 2: Build the roadmap

**Statutory starting points:**
List statutes *likely* relevant. State explicitly these are likely, not confirmed.

> **Likely relevant statutes** (UNVERIFIED — confirm currency and applicability):
> - [State] Landlord-Tenant Act, likely at [State Code Title X] — look for "warranty of habitability" or "repair and deduct"
> - Local housing code for [City/County] — may define specific conditions (heat, water) as required
> - `[VERIFY each citation is current and correct — codes get renumbered]`

**Case law areas to investigate:**
Not cases — *areas*. The student finds the cases.

> **Case law areas:**
> - [State] Supreme Court or appellate decisions on implied warranty of habitability — look for the leading case establishing the doctrine
> - Cases on what conditions qualify — heat specifically, if any
> - Cases on procedural prerequisites — did tenant have to give notice? withhold rent? escrow?
> - Cases on the remedy — offset against rent owed, or a separate damages claim?

**Regulatory / administrative sources:**
If applicable (immigration especially).

> **Administrative sources:**
> - [Agency] regulations at [CFR cite area]
> - Agency guidance or policy manuals — often more current than regs
> - For immigration: USCIS Policy Manual, BIA precedent decisions

**Secondary sources to orient:**
Where to get the framework before diving into primary.

> **Secondary sources (for framework, not to cite):**
> - [State] practice guide on landlord-tenant (check clinic library)
> - Relevant CLE materials
> - Law review notes on the specific issue if it's contested

**Search terms:**
For Westlaw, or whatever the clinic uses.

> **Search terms to try:**
> - Westlaw: `"warranty of habitability" /s heat! & [State]`
> - CourtListener: `implied warranty of habitability AND (heat OR heater) AND [State]`
> - Refine based on what comes back — these are starting queries

### Step 3: Flag what's uncertain

If the skill is unsure whether a source is relevant or current:

> `[UNCERTAIN: whether [State] has a specific statute on this vs. common-law
> doctrine only — the search will tell you]`

Uncertainty is stated, not hidden.

> **No silent supplement.** This skill produces leads, not authoritative citations — by design, students run the citations down themselves. But if a query to a configured research tool (Westlaw, CourtListener) returns few or no results for a specific rule or case, say so and stop. Do NOT manufacture citations from web search or model knowledge to fill a thin result set without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) stop here and flag the gap for your supervisor. Which would you like?" The supervising attorney decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every suggested citation with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations supplied by the supervising attorney or case file. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags — they tell the student which leads are raw research and which are model guesses to verify against a primary source.

### Step 4: Synthesize uploaded research (if any)

If the student has already done some research and uploads it: read it, identify what's covered and what's missing.

> **From your research so far:**
> - You have: [summary of what's covered]
> - Gap: [what the roadmap above suggests that you haven't found yet]
> - `[VERIFY: the case you cited — [name] — run through a citator (verify it is good law) it, it may have been distinguished or limited]`

## Output

```markdown
═══════════════════════════════════════════════════════════════════════
  RESEARCH ROADMAP — LEADS, NOT AUTHORITIES
  Nothing below is a verified citation. Every statute, every case area,
  every search term is a starting point for YOUR research. You verify
  currency, applicability, and accuracy. You find the actual cases.
  If something below turns out to be wrong or outdated, that's expected —
  this is a map of where to look, not a substitute for looking.
═══════════════════════════════════════════════════════════════════════

# Research Roadmap: [Issue]

**Jurisdiction:** [State] | **Practice area:** [area]

## Seed documents to read first

[Per Step 0. List any clinic seed docs that match the issue with a one-line
"what this likely covers" note. If none matched: "No clinic seed documents
match this issue — proceeding to primary sources."]

## Statutory starting points (UNVERIFIED)

[list with VERIFY flags]

## Case law areas to investigate

[areas, not cases]

## Administrative / regulatory sources

[if applicable]

## Secondary sources (for framework, not citation)

[list]

## Search terms

**Westlaw:** [queries]

## Uncertainty flags

[Everywhere the roadmap is genuinely unsure]

---

## What to do with this

1. Start with a secondary source to get the framework
2. Find and read the primary statutes — confirm the citations above are current
3. Run the searches, find the leading cases
4. run through a citator (verify it is good law) everything before relying on it
5. Come back and run `/memo` to scaffold your analysis once you have the rule

## What this roadmap does NOT do

- **It does not give you citations you can use.** Every cite above is a lead
  to verify, not an authority to rely on.
- **It does not do the research.** You do the research. This gets you to the
  starting line faster.
- **It does not replace Westlaw.** Those have the actual cases. This
  tells you where to point them.

---

**Cite verification — required before use.** Citations above were generated by an AI model and have not been verified. Before relying on any case, statute, or rule — or including it in client work — run it through Westlaw, CourtListener, or your clinic's research platform for accuracy and current good-law status. Flag unverified citations to your supervisor.
```

## What this skill does NOT do

- **Provide authoritative citations.** Explicitly, by design. The student verifies every cite before using it.
- **Replace legal research.** Accelerates the "where do I start" phase; the research itself is still the student's.
- **Guarantee the roadmap is complete.** It's a starting set of leads. The research may reveal sources the roadmap missed — that's fine, that's research.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/semester-handoff', 'legal', 'semester-handoff', '', 'semester-handoff', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /semester-handoff

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → clinic profile, semester dates, supervision style.
2. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml` and `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md` per case.
3. Use the workflow below.
4. Take active-case list as input (ask if clinic doesn't have a central list). Map outgoing → incoming owners.
5. Generate per-case handoff memo → `~/.claude/plugins/config/claude-for-legal/legal-clinic/handoffs/[semester]/[case_id].md`.
6. Generate cohort summary → `~/.claude/plugins/config/claude-for-legal/legal-clinic/handoffs/[semester]/_summary.md`.
7. Route per supervision model — formal queue / configurable flags / lighter-touch.

---

# Semester Handoff

## Purpose

Every semester, clinics lose their entire workforce and rebuild. `/ramp` solves half the problem — it onboards the new cohort. This skill solves the other half: it offboards the departing cohort by producing handoff memos that capture what the next student needs to know about every active case.

Without this, case knowledge walks out the door with the student. The new student starts from the case file and intake summary, which is never enough. Two weeks are wasted re-learning the case before the new student can do anything useful. The client experiences the re-learning as a regression — calls go unanswered while the new student catches up, questions already answered get asked again.

## Audience

Professor or departing students. The professor runs it to orchestrate the full cohort offboarding; individual students can run it on their own cases if they're transitioning mid-semester (graduation, withdrawal).

## Load context

- `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → clinic profile, semester, practice areas, supervision style
- `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml` → all active deadlines, grouped by case
- `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md` (per case) → communications history
- Case files / intake summaries the clinic maintains
- Student roster — who owns what going into the handoff

## Workflow

### Step 1: Identify cases and owners

- Pull all active cases (from intake records + `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml` case_ids + client-comms folders)
- For each case: who's the current owner student? Are they staying or leaving?
- Map: outgoing owner → incoming owner (if known; otherwise mark "TBD — professor to assign")

If the clinic doesn't maintain a central active-case list, the skill needs one input: a list of active cases. Ask for it. Don't guess.

### Step 2: Per-case handoff memo

For each case:

```markdown
# Case Handoff — [case name] — [semester ending]

**Case ID:** [case_id]
**Practice area:** [area]
**Outgoing student:** [name]
**Incoming student:** [name or "TBD"]
**Supervising attorney:** [professor]
**Client:** [name or client ID]

---

## Where we are

[One paragraph: current posture. What's been done, what's pending, where the case is heading. If the case is at a natural pause point or between filings, say so.]

## Pending deadlines

*Pulled from `~/.claude/plugins/config/claude-for-legal/legal-clinic/deadlines.yaml`. Incoming student's first job is to confirm these are accurate and owned.*

| Due | Type | Description | Notes |
|---|---|---|---|
| [date] | [type] | [one-line] | [if tight: "URGENT — due within [N] days of semester start"] |

## What's been done

- [Key actions this semester: intake, filings, hearings, major correspondence]
- [Documents produced — with pointers to where they live]

## What's open

- [Decisions pending: e.g., "client hasn't decided whether to accept settlement offer"]
- [Research gaps: e.g., "need to confirm whether [jurisdiction] allows [remedy]"]
- [Open communications: e.g., "awaiting response from opposing counsel's office"]

## Client relationship

- [How often has the student been in touch? Phone, email, in-person?]
- [Any relationship context the next student should know: language preference, trust-building notes, circumstances that affect scheduling]
- [Upcoming planned contact or appointments]

## Documents drafted / filed

*Pointers, not content.*

- [Date] [Document type] — [path or file reference] — [status: filed / drafted / in review queue]

## Communications history summary

*From `~/.claude/plugins/config/claude-for-legal/legal-clinic/client-comms/[case-id]/log.md`. Three-line summary here; incoming student reads the full log.*

[Short summary of recent contact patterns — e.g., "3 phone calls since intake, all in Spanish, client prefers evenings. Last contact: 2026-04-15, confirmed address for hearing notice."]

## Professor's flags for incoming student

*Added by professor review before the handoff memo goes to the incoming student. Could include: "this case has a sensitive family dynamic — read the intake carefully before calling client"; "client has requested all mail go to PO box not home address"; "there's a scope question here we haven't resolved — check with me in week 1."*

[flags, or "none"]

## First-week priorities for incoming student

1. [Specific — e.g., "Call [client] within 48 hours of taking the case. Introduce yourself. Confirm you've received the case file."]
2. [Deadline-driven — e.g., "Answer to eviction complaint is due [date]. Review outgoing student's draft, revise, file."]
3. [Knowledge-gap — e.g., "Read outgoing student's memo on the habitability defense before the 4/28 status conference."]

---

**Handoff prepared by:** [outgoing student]
**Date:** [YYYY-MM-DD]
**Reviewed by:** [supervising attorney, if applicable per supervision model]
```

### Step 3: Cohort summary

After all per-case memos, produce `~/.claude/plugins/config/claude-for-legal/legal-clinic/handoffs/[semester]/_summary.md`:

```markdown
# Cohort Handoff Summary — [semester ending]

**Departing students:** [N]
**Incoming students:** [N]
**Active cases transitioning:** [N]
**Cases closing at semester end (no transition):** [N]

---

## Transitions

| Case | Outgoing | Incoming | Practice area | Urgency |
|---|---|---|---|---|
| [case_id] | [name] | [name or TBD] | [area] | [standard / deadline within 2 weeks / urgent] |

## Unassigned

[cases whose incoming student is "TBD" — professor assigns before next semester]

## Deadlines within 30 days of semester start

[pulled from deadlines.yaml — these are the cases the new cohort hits running]

## Notes for professor

- [Any case that raised concern about student performance, flagged for closer supervision]
- [Any case where the outgoing student is willing to stay on consult — e.g., graduating 3L who wants to mentor the 2L taking over]
- [Patterns across handoffs — e.g., "three of six cases have active deadlines in first 14 days; consider front-loading ramp exercises on those practice areas"]
```

### Step 4: Professor review (if supervision model calls for it)

Closing a case or transitioning it to a new student is a consequential action. The gate is the supervision workflow in `## Supervision style` in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`, reinforced by the Part 0 role check confirming a licensed supervising attorney owns the setup. Case-closing memos always get professor sign-off before the case is marked closed in the handoff document, regardless of supervision-style choice.

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` supervision style:

- **Formal review queue:** every handoff memo goes into the review queue before release to the incoming student. Professor approves, edits, or returns.
- **Configurable flags:** memos carry "CHECK WITH [PROFESSOR] BEFORE RELYING" — professor reviews informally, student responsible for checking in.
- **Lighter-touch:** memos carry standard AI-assisted label; professor reviews through existing structure. Case-closing memos still route to the professor before closure.

### Step 5: Hand off

Once reviewed, handoff memos live at `~/.claude/plugins/config/claude-for-legal/legal-clinic/handoffs/[semester]/[case_id].md`. The incoming student reads them during their `/ramp` run at the start of next semester — `/ramp` should surface the memos for cases the new student is assigned.

## Integration

- **`/ramp`:** at the start of next semester, reads `~/.claude/plugins/config/claude-for-legal/legal-clinic/handoffs/[most-recent-semester]/` and surfaces per-case memos for the cases each new student is taking on.
- **`/deadlines`:** feeds the pending-deadlines section of each memo.
- **`/client-comms-log`:** feeds the communications history summary.
- **`/supervisor-review-queue` (if formal review enabled):** handoff memos route here for professor approval.

## What this skill does not do

- **Close cases.** Handoff is for cases transitioning to the next cohort. Cases closing at semester end should get a final internal status memo (`/legal-clinic:status internal`) for the file and be marked closed in the handoff document; the status skill supports `client | internal | court` audiences.
- **Assign incoming students.** Professor assigns. Skill records what the assignment is; doesn't pick.
- **Generate handoffs from scratch without clinic data.** Needs the active case list as input. If the clinic doesn't maintain one, the skill surfaces that gap as a blocker rather than inventing.
- **Replace a conversation.** The written memo is the record. The outgoing student should also have a conversation with the incoming student where feasible — the memo captures facts; a conversation captures judgment and relationship context the memo can't.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/status', 'legal', 'status', '', 'status', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /status

1. Load `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → supervision style, plain-language standards, jurisdiction.
2. Use the workflow below. Read case notes.
3. Generate for the specified audience:
   - `client` — plain language, what happened/next/you do/reach us
   - `internal` — procedural posture, done since last check-in, upcoming, needs professor input, student's assessment
   - `court` — formal status report in caption format per local rules
4. Supervision routing per audience (client-facing and court-ready usually flag).

```
/legal-clinic:status client
```

```
/legal-clinic:status internal
```

```
/legal-clinic:status court
```

---

# Status: Audience-Aware Case Summaries

## Purpose

Clinics generate enormous numbers of status updates — to clients, to professors, to co-counsel, to courts. Same case, same facts, completely different documents. This skill takes the case notes and produces the right summary for the right reader.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → supervision style, plain-language standards (for client-facing), jurisdiction.
Case notes for facts.

## Audience modes

### Client-facing

**Reader:** The client. Probably stressed. Possibly unfamiliar with legal process. Reading level per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` plain-language standards (default 6th grade).

**Include:**
- What's happened since they last heard from the clinic
- What's happening next and when
- What (if anything) they need to do
- How to reach the clinic

**Don't include:**
- Legal analysis (they don't need to know the IRAC)
- Weaknesses in their case (unless it's time to have that conversation — and that's a call for the professor, not a status update)
- Jargon

*Review label for the student (not for the client — strip before sending):*
`[AI-ASSISTED DRAFT — requires student review and supervision step per plugin config]`

Check your jurisdiction's student practice rule for required law-student sign-off language; some jurisdictions require specific forms.

```markdown
Dear [Client],

I wanted to update you on your case.

**What's happened:** [Plain English. "We filed your answer with the court on
[date]" not "The responsive pleading was submitted."]

**What's next:** [What and when. "The court scheduled a hearing for [date] at
[time]. You need to be there." Or: "We're waiting for the landlord's lawyer
to respond. That could take a few weeks."]

**What you need to do:** [Specific and clear. Or: "Nothing right now — we'll
let you know when we need something from you."]

**How to reach us:** [Clinic phone, hours, student name]

[Student name]
Law Student, Certified Legal Intern
Under the supervision of [Supervising Attorney]
[Clinic name]
```

**Before sending:** sending a client status update is a consequential action. The gate is the supervision workflow in `## Supervision style` in `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`, reinforced by the Part 0 role check confirming a licensed supervising attorney owns the setup. Confirm the draft has been reviewed per the supervision protocol (queue / flag / lighter-touch) and all internal review labels (`[AI-ASSISTED DRAFT]`, `[VERIFY]`, etc.) have been removed from the client-facing copy.

### Internal (for the professor)

**Reader:** The supervising professor. Knows the law. Wants to know where the case stands and what the student needs from them.

**Include:**
- Procedural status (where in the life of the case)
- What's been done since last check-in
- What's coming up (deadlines, hearings)
- Issues needing professor input
- Student's assessment (how it's going, concerns)

```markdown
# Status: [Client] — [Matter] — [date]

**Student:** [name] | **Procedural posture:** [pre-filing / answer filed /
discovery / motion pending / etc.]

## Since last check-in

- [What's been done]

## Upcoming

| Date | What | Action needed by |
|---|---|---|
| [date] | [deadline/hearing] | [date] |

## Needs professor input

- [Question or decision point — specific]

## Student's assessment

[How it's going. Strengths, concerns, strategic questions. This is where the
student's thinking shows.]

---
[AI-ASSISTED DRAFT — student should revise the assessment section especially;
that's your thinking, not a summary of notes]
```

### Court-ready

**Reader:** A judge or clerk. Formal. Specific to what the court needs (often a status report ordered by the court, or a statement in advance of a status conference).

**Include:**
- Procedural history (briefly)
- Current status of discovery/motions/settlement
- What's outstanding
- Proposed next steps or scheduling

**Format:** Per local rules. Caption, signature block, certificate of service if filed.

```markdown
═══════════════════════════════════════════════════════════════════════
  AI-ASSISTED DRAFT — requires student analysis and attorney review
  Court filings ALWAYS require professor review before filing
═══════════════════════════════════════════════════════════════════════

[Caption per jurisdiction — VERIFY against current local rules]

STATUS REPORT

[Party] respectfully submits this status report pursuant to [the court's
order of [date] / local rule [X] / in advance of the status conference
scheduled for [date]].

1. Procedural history: [brief]

2. Current status: [discovery status / motion status / settlement status]

3. Outstanding matters: [what's pending]

4. Proposed next steps: [scheduling, if the court wants input]

[Signature block — student attorney under supervision of [Professor]]

[Certificate of service if filing]

---

[VERIFY: caption format, local status report requirements, service
requirements — per current [Court] rules]
```

## Supervision routing

Per `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md`:
- Client-facing → usually a flag trigger (client communication)
- Internal → no flag (it's going to the professor anyway)
- Court-ready → always flagged if formal queue enabled (court filings)

## What this skill does NOT do

- **Decide what to tell the client.** Especially on bad news or case weaknesses — that's a conversation for the student and professor to have, then the student to have with the client. Status updates are status, not strategic advice.
- **File anything with a court.** Drafts the document; professor reviews; filing per clinic procedure.
- **Replace the student's assessment in internal status.** The "student's assessment" section is the student's thinking — the draft can scaffold it but can't write it.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/legal-clinic/skills/supervisor-review-queue', 'legal', 'supervisor-review-queue', '', 'supervisor-review-queue', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /supervisor-review-queue

1. Check `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → supervision style. If NOT "formal review queue": explain the clinic is set up for [flags/lighter-touch], no formal queue exists, and how to switch.
2. Use the workflow below.
3. Default: show what's waiting, by urgency, by student.
4. Actions: approve / edit-then-approve / return with note. All logged.

```
/legal-clinic:supervisor-review-queue
```

```
/legal-clinic:supervisor-review-queue --approve Q-003
```

```
/legal-clinic:supervisor-review-queue --return Q-004 "Check the service requirement — local rules changed"
```

---

# Supervisor Review Queue (Optional)

## Purpose

Some clinics want a formal gate: student drafts, professor reviews, output releases. Others find that too prescriptive — they supervise through case rounds and one-on-ones, not through a queue.

**This skill is only active if `~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → Supervision style is "formal review queue."** Otherwise it's dormant — the cold-start interview asks the professor which model they want, and this is one of three options.

Whether to use a formal review workflow is genuinely an open question for clinic adoption. It depends on student experience level, caseload, and how the professor already runs supervision. The professor decides at setup and can change it later.

## Load context

`~/.claude/plugins/config/claude-for-legal/legal-clinic/CLAUDE.md` → supervision style. If NOT "formal review queue": respond with "The clinic is set up for [flags/lighter-touch] supervision — there's no formal queue. [Professor] reviews through [the clinic's existing structure]. To switch to a formal queue, edit CLAUDE.md → Supervision style."

If formal queue IS enabled → read flag triggers and proceed.

## The queue

Lives at `references/review-queue.yaml`. Each entry:

```yaml
- id: Q-001
  type: "draft"  # intake | draft | memo | status | client-letter
  client: "[name or ID]"
  student: "[name]"
  submitted: [timestamp]
  flags:
    - rule: "Court filing"
      detail: "Eviction answer — always queued"
  content_path: "[path to the document]"
  status: "pending"  # pending | approved | edited-approved | returned
```

## Modes

### What's waiting

```markdown
## Review Queue — [date]

**Pending:** [N] | **Oldest:** [N] hours

### 🔴 Deadline-sensitive
| ID | Type | Client | Student | Why flagged | Waiting |
|---|---|---|---|---|---|

### Standard
[same table]

### By student
[Breakdown — spot patterns: who's queueing a lot, who might need a check-in]
```

### Review an item

Show full content + why it was flagged + student notes.

### Approve / edit-then-approve / return

- **Approve:** Status → approved, student notified, logged.
- **Edit then approve:** Professor edits inline, approved version is the edited one, original preserved in log so student sees the diff (teaching moment).
- **Return:** With a note. Student revises and resubmits.

## Logging

Every action logged. Approval logs are clinic records — they document that a licensed attorney, solicitor, barrister, or other authorised legal professional in the clinic's jurisdiction reviewed student work before it went to a client or court. That matters for the clinic's own compliance and for student evaluation.

## Teaching signal

The queue is also data. Pattern in returns ("Student X keeps missing the service requirement") is a coaching conversation. Pattern in edits ("Everyone's demand letters are too long") is a `/ramp` update for next semester.

## What this skill does NOT do

- **Run unless the professor chose it.** It's one of three supervision models, not the only one.
- **Auto-approve.** The professor approves.
- **Replace the clinic's existing supervision structure.** It's a gate for work product, not a substitute for case rounds, one-on-ones, or watching students in action.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/brief-section-drafter', 'legal', 'brief-section-drafter', '', 'brief-section-drafter', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /brief-section-drafter

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → case theory, house style.
2. Follow the workflow and reference below.
3. Draft in house format/tone/citation style. Consistent with theory.
4. Output: draft section. Flag every place a fact or cite needs verification.

---

# Brief Section Drafter

## Witness statements for England & Wales — PD 57AC

If the user's jurisdiction includes England & Wales and they're asking for a trial witness statement for the Business & Property Courts (or any CPR-governed proceeding), PD 57AC applies. The statement must be in the witness's own words, must not contain argument, must identify the documents the witness used to refresh their memory, and must carry the required confirmation of compliance and the legal representative's certificate.

**Drafting a narrative "as the witness" from a chronology, document set, or your account of the case is exactly what PD 57AC was designed to prevent.** Courts are actively sanctioning AI-assisted witness statement drafting. If you ask me to do it, I won't.

What I WILL do: prepare question prompts to elicit the witness's actual recollection; capture and organize what the witness says (their words, not mine); generate the list of documents they were shown; run a PD 57AC compliance checklist against a statement they've drafted; draft the solicitor's certificate of compliance. I help you get the witness's evidence into the statement. I don't write the evidence.

For US depositions, declarations, and affidavits: different rules, but the same discipline applies. A declaration in the declarant's voice that the declarant didn't write is a credibility problem at best.

## Purpose

A good brief section is consistent with the theory, cited to the record, written in house style, and checkable. This skill produces the first draft — emphasis on *draft*. Partner edits.

## Written or oral?

Ask before drafting: "Is this for a written submission or oral argument?" They are different crafts:

- **Written:** thorough. Cover the points, develop the authority, anticipate the responses.
- **Oral (rebuttal, closing, argument):** strategic. Pick the 3-4 points that matter most. Concede or ignore the weak ones. Lead with your strongest. A tribunal remembers the first two minutes and the last two. "Too thorough" for oral advocacy reads as unfocused. If you're responding to a multi-issue submission, tell the user which issues you'd press and which you'd let go — that's the draft of the strategy, not just the words.

## Record fidelity — quotes and pinpoints

Two rules that govern every citation and every quotation in advocacy drafting. The canonical statement lives in the plugin's `CLAUDE.md` shared guardrails; repeated here because this skill is the most common place the rule gets tested.

**Verbatim quotes from the record must be verbatim.** Never put quotation marks around words attributed to opposing counsel, a witness, the court, or any record document unless you have the exact passage in front of you and can cite to it. A quote that's almost right is worse than a paraphrase — it misrepresents the record, it's sanctionable if filed, and it will be caught. When you want to characterize what someone said but can't find the exact words:

- **Paraphrase without quotation marks**, attributing clearly: "Opposing counsel argued that X `[verify against record — Tr. p. __]`."
- **Mark the placeholder:** `[verify exact quote — record cite pending]`
- **Never fill the gap.** An invented quote, even one word, is a fabrication. The reviewer note must flag every `[verify exact quote]` in the output.

Before citing any passage with quotation marks, have the source open. If you're working from memory or a summary, no quotation marks.

**Pinpoint cites must support the whole proposition.** If the argument is "opposing counsel said X, Y, and Z" and you're citing one pinpoint, verify the pinpoint supports X AND Y AND Z. If it only supports Z, either (a) split the cite — "said X (Tr. p. 10), Y (Tr. p. 12), and Z (Tr. p. 15)" — or (b) narrow the proposition to what the pinpoint actually supports. A cite that supports part of a claim is how a tribunal catches you stretching. It's the single most common way a lawyer's credibility erodes in front of a court. This is the "misgrounded citation" failure mode: the cite exists, the passage exists, but the passage doesn't support the proposition as stated.

## Candor about weak arguments

When the law is against you, say so. When an argument is weak — the authority cuts the other way, the facts don't support it, the inference is a stretch — don't construct a shaky argument and present it as if it were solid. Flag it:

> "This point is weak — [authority] cuts the other way. Consider whether to press it (here's how you'd frame it), concede and pivot to [stronger point], or drop it. `[review — strategic call]`."

Asserting a weak argument without flagging it erodes the lawyer's credibility with the tribunal and creates a candor problem (MR 3.1 — a lawyer must have a basis in law and fact). The draft should make the lawyer smarter, not confident about a bad position.

## Citation extraction coverage

When this draft is cite-checked — by you, by another skill, or by a reviewer running through what you produced — the check must be exhaustive, not selective:

1. **First pass: extract.** Read the whole document and build a list of every citation — cases, statutes, regulations, record cites, secondary authority. Report the count: "Found [N] citations."
2. **Second pass: check.** Check each one against the source. Don't sample. Don't stop when you get tired.
3. **Report coverage.** At the end: "Checked [N] of [M] citations. [K] could not be retrieved — verify manually. [J] confirmed. [I] flagged as potential miscitations. [H] flagged as misgrounded (cite exists but doesn't support the proposition)."
4. **When source text is unavailable, say "could not check," never "confirmed."** A false positive ("this cite is fine" when you couldn't read the source) is worse than "couldn't check this one."
5. **The hardest errors to catch are partial support.** A cite that backs part of a claim but not all of it. Read the proposition the brief makes, read what the source actually holds, and compare element by element.

## Echo vs repeat

Echo key framings; don't lift sentences. Consistency with prior submissions is good — it reinforces your theory of the case and makes the record coherent. But there's a line between echoing and repeating.

- **Echo:** use the same key terms, the same framing of the central issue, the same characterization of the other side's theory.
- **Don't:** lift whole sentences, re-use distinctive phrasings so often the tribunal notices, or repeat the same argument verbatim without advancing it.

A rebuttal that sounds like a re-read of the opening loses ground. The draft should advance the argument, not restate it.

## Load context

`~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → case theory, house style (citation format, structure, tone, length norms).

**Conflicts gate — unbypassable.** Before drafting, check `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for the matter slug this skill is being invoked on. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't draft substantive work product on a matter that hasn't been intaken — the conflicts check is the gate."

Do not proceed on an unintaken matter. Intake is what runs conflicts, sets up `matter.md` / `history.md`, and writes the `_log.yaml` row this skill reads from. Skipping it produces work in an unmanaged location and bypasses the firm's conflicts discipline.

## Workflow

### Step 1: Which section?

| Section | What it does | Inputs needed |
|---|---|---|
| Statement of facts | Tells the story, in our frame, cited to record | Chronology, key docs, depo cites |
| Standard of review | Sets the bar the court applies | Procedural posture |
| Argument | Makes the legal case | Issue, authorities, facts |
| Conclusion | Asks for relief | What we want |

### Step 2: Theory check

Before writing: what does this section need to accomplish for the theory?

- Statement of facts: Frame the story so our theory is the natural reading.
- Argument: Connect the law to the facts in a way that supports the theory.

If the section you're about to draft contradicts the theory — stop. Either the theory is wrong or the section approach is wrong. Flag it, don't paper over it.

### Step 3: Draft in house style

**Research the forum's local rules and the judge's standing orders for length, formatting, citation, and filing requirements; don't rely on preferences. Cite primary sources (local rule number, standing order section) in the drafting notes. Verify currency — local rules change.**

Per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`:

- **Citation format:** Bluebook, ALWD, or local — match exactly. Signals, pincites, parentheticals per house practice, confirmed against the local rule.
- **Structure:** How does this firm organize arguments? CRAC? Topic sentences first? Headings that argue vs. headings that describe?
- **Tone:** Aggressive ("Defendants' argument is meritless") or measured ("The evidence does not support Defendants' position")? Match the seed brief.
- **Length:** per the local rule / standing order — never relying on "what this judge usually wants" when the rule is checkable.

### Step 4: Cite everything

Every fact → record cite (Bates, depo page:line, exhibit).
Every legal proposition → case cite with pincite.

**Marker discipline — use liberally:**
- `[VERIFY: specific factual assertion]` — anything not confirmed against the record
- `[UNCERTAIN: specific legal proposition]` — anything not confirmed against current authority
- `[CITE NEEDED: specific cite — fact/rule believed but cite not yet pinned]`

A draft with unresolved markers is not final. The markers make the verification step explicit.

**No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for an authority the draft needs, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [issue / holding]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave the `[CITE NEEDED]` marker and stop here. Which would you like?" A partner decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every citation in the draft with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the partner or senior associate supplied. Citations tagged `verify` carry higher fabrication risk than tool-retrieved citations and should be checked first. Never strip or collapse the tags — they are the reviewing attorney's fastest signal about which citations to Shepardize first before the brief is filed.

### Step 5: Output

**Before the brief is filed (the consequential act — this skill drafts, but the gate runs at the filing step regardless of who triggers it):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Filing a brief has legal consequences — it becomes the record, binds the client on arguments and facts asserted, and a Rule 11 / equivalent certification attaches to signature. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the section drafted, the theory tie-in, authorities relied on, open `[VERIFY]` / `[UNCERTAIN]` / `[CITE NEEDED]` markers unresolved, what could go wrong (factual misstatement, unsupported citation, argument outside the theory), what to ask the attorney before filing.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not treat the draft as filing-ready without an explicit yes. Drafting itself does not require the gate — filing does.

The section, in house style, with markers inline.

Preface (not in the brief — a note to the reviewing attorney):

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Drafting Notes — [Section] — [date]

**Theory tie-in:** [How this section supports the case theory]
**Authorities relied on:** [list — all need Shepardizing]
**Record cites to verify:** [N] flagged inline
**Open questions for the partner:** [anything the draft assumes that should be confirmed]
**Length:** [words/pages vs. house norm]

---

**Cite check before filing.** Citations in this draft were generated by an AI model and have not been verified against a primary source. Run every case, statute, and regulation through Westlaw, CourtListener, or your firm's research platform for accuracy, good-law status, and subsequent history. Fabricated or misquoted citations in filed briefs have resulted in Rule 11 sanctions.

**Draft only — not a filing.** Filing this section initiates (or participates in) a proceeding and carries Rule 11 / Rule 3.3 exposure. A licensed attorney reviews, edits, and takes professional responsibility before it goes on the docket. Do not file unreviewed.
```

## Statement of facts specifics

The statement of facts is advocacy through selection and sequence, not argument.

- Chronological unless there's a reason not to be
- **Every fact in the statement of facts must cite to the record — a page and line reference, a docket entry, an exhibit.** "Or conceded" is not a substitute for a record cite. If the fact is established by a concession or stipulation, cite the stipulation document or the hearing transcript where the concession was made.
- Frame through selection: which facts lead, which get one line, which get omitted (if not necessary and not helpful)
- No argument. "The contract unambiguously required X" is argument. "The contract stated 'X.'" is fact.

## Argument section specifics

- Lead with the rule, not the facts (usually — house style may differ)
- One argument per section. If it's really two arguments, it's two sections.
- Address the other side's best counterargument. Don't hide from it — a brief that ignores the obvious counter is a brief the judge doesn't trust.
- Parentheticals earn their space. If a parenthetical doesn't add something the cite alone doesn't, cut it.

## What this skill does not do

- Produce a final brief. It produces a draft. Every cite needs verification, every argument needs a partner's eyes.
- Decide strategy. If there are two ways to argue the issue, flag both and let the partner choose.
- File anything. Ever.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/chronology', 'legal', 'chronology', '', 'chronology', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /chronology

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` → theory, pivot fact, key facts.
2. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → Document storage sources, default matter folder pattern.
3. Follow the workflow and reference below.
4. Identify sources in order: user-provided paths this session, default matter folder, declared sources from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`.
5. For readable sources: extract dated events. For unreachable sources: note in Gaps.
6. De-dupe, merge with sources list per event.
7. Tag significance (🔴/🟡/⚪) per matter theory.
8. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/chronology.md` (or format variant per flag).
9. If prior version exists: version number increments, diff summary presented to user.
10. Confirm before finalizing: "Here's what I built. Scan the 🔴 entries — anything I miscalled?"

---

# Chronology

## Disclosed-document use restrictions

Before working with a set of litigation documents, ask: "Were any of these documents obtained through disclosure or discovery in legal proceedings?" If yes:

- **England & Wales (CPR 31.22):** Documents obtained through disclosure are subject to the implied undertaking — you may only use them for the purpose of the proceedings in which they were disclosed, unless the court grants permission, the disclosing party consents, or the document has been read in open court. Using them for a different matter, a different claim, or a commercial purpose without permission is a contempt.
- **US:** Protective orders and Rule 26(c) may impose similar restrictions. Check the order.
- **Other jurisdictions:** Similar restrictions commonly apply. Check the local rule.

Confirm: "This use is within the proceedings in which the documents were disclosed, or I have permission / consent, or the documents are now public." If not confirmed, flag it: "⚠️ Disclosed documents may have use restrictions. Confirm this use is permitted before proceeding."

## Purpose

Facts happen in order. The chronology is the spine every narrative hangs on — the statement of facts in a brief, reserve memos, settlement memos, depo prep, witness prep. Building a chron by hand is slow; AI is good at structured extraction. The catch: garbage-in, garbage-out. This skill pulls from the sources the configuration declares and from whatever the user uploads.

## Modes

This skill serves two practice settings. Pick a default from the user's `## Role` in the plugin's configuration CLAUDE.md; the user can override per-run with a flag.

- **`--matter` mode (default for in-house litigation counsel).** Matter-history-focused. Reads the matter's case theory and key facts from `matter.md`, pulls from declared document-storage sources (Google Drive, SharePoint, Gmail, iManage, CLM — whatever the `## Landscape` section of CLAUDE.md declares), and treats `history.md` as the running internal log (decisions, holds, reserve memos — intentionally not in the chronology). Output is matter-centric: what happened across the dispute, tagged for advocacy use.
- **`--documents` mode (default for firm associate / paralegal).** Production-document-focused. Reads the case theory from the configuration, then extracts from an eDiscovery export, a custodial file set, or a Bates-numbered production. Output is production-centric: what the documents show, with Bates citations, tagged per the case theory.

Both modes converge on the same output structure (timeline, 🔴/🟡/⚪ significance tags, gaps, SoF variant). The difference is the source profile and the significance frame.

If `## Role` is `solo` or `other`, default to `--matter` but mention both modes on the first run and let the user pick.

## Side framing (significance tags)

The same event is significant in different ways depending on whether the practitioner is proving a claim or disproving it. Read `## Side` in the practice profile (and the per-matter posture if the matter overrides the default):

- **Plaintiff (offensive framing)** — 🔴 marks events that *establish* elements of the claim (liability, causation, damages, notice), *close* gaps the defense will try to open, or *start* statute-of-limitations clocks in the plaintiff's favor. 🟡 marks events that support the claim but are subject to impeachment. ⚪ is background context.
- **Defense (defensive framing)** — 🔴 marks events that *break* elements of the claim (failure of causation, notice, reliance), *open* statute-of-limitations or jurisdictional defenses, or *support* affirmative defenses (release, waiver, assumption of risk, comparative fault). 🟡 marks events that undermine the plaintiff's narrative. ⚪ is background.
- **Both / varies** — ask the user per-chronology which side's framing to apply for significance tags. The underlying timeline is side-neutral; only the significance read changes.

Note the applied framing at the top of the output: `Significance tags applied from [plaintiff / defense] perspective.` When producing a Statement of Facts variant, use the side default unless the user specifies otherwise.

## Load context

Common:
- Plugin configuration CLAUDE.md → case theory context (in-house: `## Landscape` for document sources; firm associate: `## Case theory` and `## Document review` for platform + custodians), `## Outputs` for the work-product header, `## Decision posture` for the privilege-flagging rule.
- Prior `chronology.md` for this matter, if it exists.
- Any files the user uploads or paths they provide in-session.

`--matter` mode also reads:
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` → case theory, key facts, pivot fact (for significance tagging), key dates.
- Default matter folder pattern from CLAUDE.md → where docs for this slug live.

`--documents` mode also reads:
- eDiscovery platform metadata if a connector is available (Everlaw, Relativity, DISCO, Aurora) — by custodian + date range.
- Bates-range manifest or production index if the user points at one.

**Conflicts gate — unbypassable (`--matter` mode).** Before building the chronology, check `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't build a chronology on a matter that hasn't been intaken — the conflicts check is the gate."

Do not proceed on an unintaken matter. Intake is what runs conflicts and writes the `_log.yaml` row this skill reads from. `--documents` mode (running against an ad-hoc document set without a matter slug) is exempt from the gate, but its outputs should be treated as pre-matter research and not filed as if matter work product.

## Workflow

### Step 0: Privilege gate (runs first, every time)

Chronology work pulls from documents. Documents are often privileged (attorney-client, work product, common interest, joint defense) — in-house matter files often are by default; eDiscovery productions, especially rolling productions or common-interest productions, often contain privileged or unreviewed material. Extracting content from a privileged document into a chronology that later gets shared can *risk* waiver, depending on who receives it and under what doctrine (common-interest, joint-defense, Kovel, and work-product protections may apply). Waiver analysis is fact-specific — get counsel sign-off before distributing.

The skill will not extract until the user picks a privilege posture:

> Before I extract: how have the sources been privilege-screened?
>
> - **A. All sources cleared** — you've already screened these. I extract without privilege flags. Output is discovery-ready posture; still marked work product.
>
> - **B. Mixed or not yet screened** — I extract and tag every entry with a `priv` flag: `ok` (sourced from clearly non-privileged material), `flag` (sourced from potentially privileged material — A/C, WP, common interest), or `review` (source unclear). Flagged entries are visually marked in the output, and the Statement-of-Facts variant filters them out by default.
>
> - **C. Abort — screen first** — pause the skill. Screen the sources. Return and re-run.

Record the choice in the chronology header as `privilege_posture: A-cleared | B-mixed | C-aborted`. If B or C, record the rationale briefly.

**Why a gate and not just a warning:** a warning gets read once and forgotten. A gate forces the posture decision into the record, which means every chronology file carries its own provenance — anyone reading it later knows whether entries were derived from privilege-screened material.

### Step 1: Identify document sources

**`--matter` mode:**

1. **User-provided paths** — anything dropped in this session (file paths, drive links, email exports).
2. **Default matter folder** — from CLAUDE.md's document-storage pattern, expanded for this slug (e.g., `G:/Legal/Matters/acme-v-us-2026`).
3. **Declared sources** — the `Document storage` table in CLAUDE.md, filtered to ones this matter might touch (e.g., Gmail archive for sender-side communications, SharePoint legal folder).
4. **Ask** — if sources look thin, prompt: "I can build from what I have, but the chronology will be incomplete. Anything else to point me at? Key emails, contracts, internal memos, production letters?"

**`--documents` mode:**

1. **Production export / Bates set** — the user points at the production directory or a manifest; the skill reads by Bates range + date.
2. **eDiscovery connector** — if an MCP connector is available (Everlaw, Relativity, DISCO, Aurora), pull by custodian + date range.
3. **Custodial files** — if the user provides raw custodial mailboxes or drive exports, read those too.
4. **Ask** — if coverage looks thin for a key custodian or date range, prompt.

### Step 2: Pull + read

For each source with readable files:

- **PDFs, emails (.eml), .docx, .txt** — read directly.
- **Email archives (Gmail, Outlook)** — if an MCP connector is authenticated, query by date range + counterparty / key terms; otherwise the user exports relevant threads to a folder.
- **eDiscovery platforms (Everlaw, Relativity, DISCO, Aurora)** — if connector is available, pull by custodian + date range; otherwise the user provides an export.

If the skill can't access a declared source, name it explicitly in the output's Gaps section rather than silently proceeding.

**No silent supplement.** If source coverage for an era of the matter is thin — fewer documents than expected for a claimed time window, a custodian whose mailbox isn't accessible, a production that hasn't landed — report what was found and stop. Do NOT fill gaps from web search, public record search, or model knowledge about the matter without asking. Say: "Sources returned [N] events for [period / custodian]. Coverage appears thin. Options: (1) point me at additional sources (Bates, folder, mailbox), (2) try a different MCP connector if configured, (3) search the web for public-record events in this window — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) stop here and note the gap. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every chronology entry with where the event came from: the file path, Bates number, MCP connector, or declared document-storage source for events extracted from retrieved documents (already captured in the Sources column). For any event or date that cannot be traced to a retrieved document — e.g., a fact recalled from model training data, a public-record event found via web search — tag it inline: `[web search — verify]`, `[model knowledge — verify]`, or `[user provided]` where the user stated the fact in-session. Entries tagged `verify` carry higher fabrication risk than document-sourced entries and should be checked first. Never strip or collapse the tags — they are counsel's fastest signal about which entries to verify before pulling them into a brief or SoF.

**Tagging reaches every section that states a legal conclusion, deadline, or computed date — not just timeline entries.** The timeline is sourced from documents. The Gaps section, the Key events section, the Theory tie lines, and any statement of limitations, tolling event, filing deadline, discovery cutoff, or privilege determination are legal analysis the skill writes from model knowledge unless sourced. Every such statement carries a provenance tag: `[computed from: <rule cited with tag>]`, `[model knowledge — verify]`, `[user provided]`, or a research-connector tag if retrieved in this session. A statute-of-limitations window with no tag defaults to `[model knowledge — verify]`. A "key event" line that characterizes a fact's legal significance is analysis and needs the tag. The rule is simple: if it's an assertion about the law, not an assertion about what a document says, it must carry the same provenance tag the timeline entries do. When no research connector is reachable and the skill is computing deadlines or citing rules, record it in the **Sources:** line of the reviewer note (see plugin CLAUDE.md `## Outputs`) — do not emit a standalone banner.

### Step 3: Extract events

For each document, identify dated events:

- **Email:** `[date] [sender] told [recipient] [subject/content]`
- **Meeting:** `[date] [attendees] met about [topic]` (per calendar entry or notes)
- **Decision:** `[date] [decision-maker] decided [what]` (per memorializing doc)
- **Filing / pleading:** `[date] [party] filed [motion/complaint/response]`
- **External event:** `[date] [thing happened]` (contract signed, product launched, regulator acted, event crossed a threshold)

One event per document usually. Occasionally zero (undated or no event established). Sometimes multiple (meeting summary covering several decisions).

**Privilege flag per entry (only when privilege_posture == B-mixed). Three-state rule — never silently decide a subjective privilege test isn't met:**

- `priv: ok` — source is **confidently** non-privileged (filings, regulatory correspondence, public docs, counterparty communications without our counsel). Used only when there's no plausible privilege theory.
- `priv: flag` — source is confidently or likely privileged (communications with counsel, work-product memos, privileged drafts, joint-defense material). **Default for anything uncertain** — if the dominant-purpose call is close, or litigation contemplation is borderline, or the content is mixed, it goes here, not in `ok`.
- `priv: review` — source unclear on its face, but the skill could not make the call at all (no sender/recipient metadata, unreadable, etc.).

When `priv: flag` or `priv: review`, add `[SME VERIFY: privilege status]` inline so the counsel sees it during review. Under-flagging waives privilege (one-way door); over-flagging is corrected by counsel in review (two-way door). Prefer the recoverable error.

### Step 4: De-dupe

The same event surfaces in multiple documents: a meeting is on three calendars and produces a summary email — that's **one event with four sources**, not four events. Merge. The merged entry cites all sources.

### Step 5: Tag significance — per case theory

Read the pivot fact and key facts from `matter.md` (`--matter` mode) or from the configuration's `## Case theory` section (`--documents` mode). Tag each event:

- 🔴 **Key** — event is part of the pivot fact or a key fact for/against us
- 🟡 **Relevant** — context, pattern evidence, supports a secondary argument
- ⚪ **Background** — useful for completeness, not going in the brief

**Discipline:** a chronology of 300 entries with 300 🔴 tags has no tags. Reserve 🔴 for events that would genuinely move a factfinder. If in doubt, 🟡.

**Borderline tagging:** when an entry sits between 🔴 and 🟡 (or 🟡 and ⚪), tag at the lower significance and add `[SME VERIFY — borderline significance call]` inline. Counsel's judgment will override the skill's call. A chronology that confidently over-tags is less useful than one that surfaces its uncertainty.

### Step 6: Write

Default output is the working chronology. Variants on request.

## Output formats

### Working chronology (default)

Location: `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/chronology.md`. Complete, tagged, annotated. The reference doc counsel works from.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> **Privilege inheritance.** This chronology is derived from matter documents that may be attorney-client-privileged, work-product-protected, common-interest / joint-defense material, or a mix. It inherits the sources' protection status. Distributing it beyond the privilege circle — to business stakeholders outside the engagement, to opposing counsel, to a regulator — can waive protection over both the chronology and the underlying sources. Store with privileged matter material, mark consistently with house privilege conventions, and make distribution decisions deliberately. The privilege-posture choice captured below is the provenance stamp for any later distribution call.

# Chronology — [Matter Name]

> Significance tags (🔴/🟡/⚪) and privilege flags (🔒) are first-pass reads requiring `[SME VERIFY]` before use in any external work product (briefs, SoF, board memo, outside counsel deliverable).

**Matter:** [slug]
**Mode:** matter | documents
**Built:** [YYYY-MM-DD]
**Sources:** [N] documents across [source types]
**Entries:** [N] ([N] 🔴 / [N] 🟡 / [N] ⚪)
**Pivot fact:** [one sentence]
**Privilege posture:** A-cleared | B-mixed | C-aborted
**Flagged entries:** [N] 🔒 *(only present when posture == B-mixed)*

---

## Timeline

| Date | Event | Tag | 🔒 | Sources |
|---|---|---|---|---|
| [YYYY-MM-DD] | [what happened, one sentence] | 🔴/🟡/⚪ | [blank / 🔒-flag / 🔒-review] | [file paths or Bates] |

---

## Key events (🔴 only)

[Pulled out, each with a line on why it matters to the theory.]

### [date] — [event title]
- What: [one line]
- Theory tie: [why this matters]
- Sources: [list]

---

## Gaps

**Date ranges with no events:**
[ranges — where are documents for this period?]

**Expected but missing:**
[events we'd expect to see documented but don't — e.g., "contract amendments between 2024-06 and 2025-03 — not produced"]

**Unreadable sources:**
[sources declared in CLAUDE.md but not accessible this run — e.g., "Everlaw production — no MCP connector; export needed"]

---

## Marker discipline

- `[VERIFY: factual assertion — date, attendees, content]` — not yet confirmed against the underlying doc
- `[UNCERTAIN: legal characterization — e.g., whether an event establishes a regulatory trigger]`
- `[CITE NEEDED: Bates / exhibit / depo page:line]`
- `[SME VERIFY: privilege status | borderline significance call]` — counsel judgment needed

---

## Version
- v[N] built on [date] from [source summary]
- v[N-1] built on [date] (prior, superseded)
```

### Statement-of-facts chronology (on request)

Filter to 🔴 and relevant 🟡 only. Present as prose in chronological narrative order — the skeleton for a brief's fact section. Each paragraph is one event or tightly linked cluster, with record citations.

**Privilege filter default:** when `privilege_posture == B-mixed`, 🔒-flagged and 🔒-review entries are **excluded** by default. The SoF variant is intended for eventual external use (briefs, disclosures, negotiating counterparty) — 🔒 entries don't belong there until counsel confirms privilege status. If the user wants 🔒 entries included anyway, require explicit `--include-flagged` acknowledgment; capture the acknowledgment in the output header as permanent record.

### Witness-specific chronology (on request)

Filter to events where a named witness is sender, recipient, attendee, or subject. Feeds witness prep and helps reconstruct what a witness knew when.

## Incremental builds

If `chronology.md` exists:

- Read prior version
- Build new chronology from current sources
- Diff: new events (since last build), modified entries (new sources added to existing events), removed entries (rare; note why)
- Preserve the prior version number; write new version with `v[N+1]`
- Output summary of what changed

## Integration with matter.md / history.md

**Intentionally separate** (in-house `--matter` mode). `history.md` is counsel's running log — decisions, updates, procedural milestones, internal strategy notes. `chronology.md` is the advocacy-facing timeline of facts. They overlap but don't merge:

- A hold was issued → goes in history.md (internal action). Usually not in chronology (not a fact of the dispute).
- The counterparty sent a breach notice on March 14 → goes in chronology.md (🟡 — establishes their knowledge). Also in history.md if the intake referenced it.
- Our reserve recommendation memo was drafted → history.md only.

When counsel wants history events in the chronology, they can paste them. The default is they stay separate.

## What this skill does not do

- **Resolve contradictions.** When two documents say different things about when an event happened, both entries go in with a flag. Resolution is counsel's call; may require witness interview or further discovery.
- **Invent events not in the sources.** If it's not in the documents (and not in matter.md or the configuration as a captured fact), it's not in the chronology — but "Gaps" might call it out as missing.
- **Guarantee completeness.** A chronology is only as good as the sources. If the eDiscovery production is ongoing and only 20% has landed, the chronology reflects that. Name the limitation.
- **Decide privilege status for the user.** The Step 0 gate forces the posture choice; the per-entry `priv` flag captures first-pass classification. Actual privilege determinations are counsel's call per `[SME VERIFY]` flags.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/claim-chart', 'legal', 'claim-chart', '', 'claim-chart', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /claim-chart

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → role, work-product header, decision posture, document storage.
2. If matter workspaces enabled, confirm or select the active matter; load `matter.md` (side, jurisdiction, phase, theory, pleadings).
3. Follow the workflow and reference below.
4. Mode selection:
   - `--patent` → patent claim chart. Require patent number and at least one asserted claim. Sub-modes: `--infringement`, `--invalidity`, `--review`.
   - `--civil` → civil element chart. Require the cause of action (or defense) and the side.
   - No flag → ask the user which.
5. For civil mode: consult `references/element-templates.md` in the skill directory for the baseline element list. Confirm the controlling pattern instruction or statute with the user before mapping.
6. For patent mode: parse asserted claims into elements, flag disputed terms for construction, apply any Markman order.
7. Map elements against the target (accused product / prior art / evidence corpus / chart under review). Every cell pin-cited. Apply the apostrophe-prefix neutralization before writing any cell value starting with `=`, `+`, `-`, `@`, tab, or CR.
8. Produce the gap list (civil) or needs-evidence list (patent) — the priority output.
9. Write markdown, CSV (values + `_sources` companion), and Excel or Sheets per user preference. Work-product header on every output.
10. Write to the matter's `claim-charts/` folder if a matter is active; otherwise the practice-level `claim-charts/` folder. Append a one-line entry to `history.md` if a matter is active.
11. Return a summary readout: claim(s), target(s), jurisdiction, phase, element counts by state, the gap list, file paths, and the reminder that every cell is a lead.

---

# Claim Chart

## Disclosed-document use restrictions

Before working with a set of litigation documents, ask: "Were any of these documents obtained through disclosure or discovery in legal proceedings?" If yes:

- **England & Wales (CPR 31.22):** Documents obtained through disclosure are subject to the implied undertaking — you may only use them for the purpose of the proceedings in which they were disclosed, unless the court grants permission, the disclosing party consents, or the document has been read in open court. Using them for a different matter, a different claim, or a commercial purpose without permission is a contempt.
- **US:** Protective orders and Rule 26(c) may impose similar restrictions. Check the order.
- **Other jurisdictions:** Similar restrictions commonly apply. Check the local rule.

Confirm: "This use is within the proceedings in which the documents were disclosed, or I have permission / consent, or the documents are now public." If not confirmed, flag it: "⚠️ Disclosed documents may have use restrictions. Confirm this use is permitted before proceeding."

## A CHART IS A DRAFT, NOT A FINDING OR A CONTENTION

**Put this at the top of every output. Do not drop it. Do not soften it.**

> This chart is a draft for attorney analysis and verification, not a filed contention, an MSJ brief, an opening statement, or a legal opinion. Every mapping is a lead the attorney must verify against the source. The elements listed come from pattern jury instructions, the Restatement, or the claim language as parsed — the **controlling** authority in the user's jurisdiction (CACI / NYPJI / the circuit's pattern charge / the governing statute / a Markman order) may differ and always controls. Gap detection is a starting point for discovery or a motion; it is not a conclusion about the merits.

Under-flagging a gap is a one-way door — a complaint filed without plausibility on an element, an MSJ response served without evidence for a disputed element, or a case tried without proof of damages. Over-flagging is a two-way door — the attorney clears flags in review. The default is biased toward the two-way door.

---

## Matter context

Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/litigation-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` — especially the case theory, the pleading / complaint (for the elements actually alleged), the jurisdiction, any Markman order or stipulated constructions (patent mode), and the phase of the case. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/<matter-slug>/claim-charts/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → role, work-product header, decision posture, document storage, case-theory scaffolding
- Active matter's `matter.md` — claims, defenses, side, jurisdiction, phase, theory
- For civil mode: the complaint or counterclaim (for the actually-pleaded counts), any answer (for the actually-pleaded affirmative defenses), the relevant pattern jury instruction source, and the governing statute if statutory. Also the evidence corpus — deposition transcripts, declarations, produced documents, expert reports.
- For patent mode: the patent, the asserted claims, the specification, prosecution history if available, the accused-product material or prior art reference, any Markman order or stipulated constructions.

If `CLAUDE.md` has `[PLACEHOLDER]` markers, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor risk calibration, landscape, and house style to your practice.
>
> **Two choices:**
> - Run `/litigation-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll run this tailored to YOUR practice.
> - Say **"provisional"** and I'll run this against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," build the claim chart normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no practice-level playbook (work from the matter's pleadings and the elements of the claims as pleaded). Tag the reviewer note and every row of the chart with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/litigation-legal:cold-start-interview` to get output calibrated to YOUR practice — your risk calibration, your landscape, your house style. 2 minutes."

**Conflicts gate — unbypassable.** Before building a claim chart, check `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't build a claim chart on a matter that hasn't been intaken — the conflicts check is the gate."

Do not proceed on an unintaken matter. Intake is what runs conflicts and writes the `_log.yaml` row this skill reads from.

---

## Mode selection

Ask at the top, before anything else:

> Which kind of chart?
>
> 1. **Patent claim chart** — element-by-element mapping of claim limitations against an accused product (`--infringement`), prior art (`--invalidity`), or another party's chart (`--review`). For patent contentions, IPR petitions / responses, FTO charts.
> 2. **Civil element chart** — elements of a cause of action (or affirmative defense) mapped against the evidence. For complaint plausibility checks, discovery planning, MSJ prep, order-of-proof outlines.

Plus intake (common to both):

- **Side.** Asserting or defending? (In civil mode this flips the burden; in patent mode it flips infringement/invalidity framing.)
- **Jurisdiction / forum.** State and court — pattern instructions vary (CACI in California, NYPJI in New York, federal circuits' pattern charges, state-specific variations). In patent mode, Patent Local Rules vary (N.D. Cal., E.D. Tex., D. Del., ITC, PTAB). Flag which controls.
- **Phase.** Pre-filing, pleadings, discovery, MSJ, trial prep, post-trial. The chart is the same; the framing of the output changes.
- **Existing chart?** If `--review`, load it.

---

# MODE 1 — Patent claim chart

## Sub-modes

- `--infringement` — claim elements vs. accused product (PLR 3-1 infringement contentions, IPR/PGR response exhibits, complaint exhibits)
- `--invalidity` — claim elements vs. prior art (PLR 3-3 invalidity contentions, IPR/PGR petition exhibits, §102/§103 defenses)
- `--review` — audit a chart someone else produced

## Additional patent-mode intake

- **Patent number and asserted claims.** Which independent, which dependent. (Don't chart unasserted claims unless asked.)
- **Priority date.** Establishes the §102 bar and the effective filing date for the AIA / pre-AIA regime.
- **Existing constructions.** Markman order, stipulated constructions, constructions proposed in briefing.

## Patent-mode workflow

### Step 1: Parse the claims

Parse asserted independent claims into numbered elements. Handle:

- **Preamble.** Note whether it's limiting — a question of claim construction (*Catalina Marketing Int'l, Inc. v. Coolsavings.com, Inc.*, 289 F.3d 801 (Fed. Cir. 2002)). Flag `preamble-limiting: unresolved` unless the construction order resolves it.
- **Transitional phrase.** "Comprising" (open) / "consisting of" (closed) / "consisting essentially of" (semi-open). Affects whether additional unrecited elements defeat infringement.
- **Elements** separated by commas / semicolons, numbered `[1a]`, `[1b]`, `[1c]`. Keep numbering stable — it's the chart's spine.
- **Means-plus-function (§112(f))** — every "means for [function]" or non-structural functional term. Scope is the structure disclosed in the spec plus equivalents. Cite corresponding structure by col./line. If the spec fails to disclose structure, flag `indefinite-112f`.
- **Markush groups, Jepson claims, product-by-process, method-step order dependencies** — flag with a note on unusual construction rules.
- **Dependent claims** — reference parent; chart only the additional limitations. **Execute, don't gesture.** If asserted claims include dependents, produce the actual additional-limitation rows for each dependent in Step 4 — do not emit a note that dependents "should be charted."
- **Structural-term cognates — default to `construction-dependent`.** For each element that recites a structural noun with a common cognate in the prior art of the field, default the row's state to `literal-construction-dependent` (not `literal`) unless the spec expressly defines the term or an existing Markman order forecloses the ambiguity. These are the terms most commonly disputed at Markman — presuming a clean literal read under-flags the risk. Common cognate families to flag proactively:

  | Field | Cognate family (flag as `structural-term-cognate`) |
  |---|---|
  | Fasteners / anchors | barb / thread / projection / ridge / fin / tooth |
  | Fluidics / catheters | lumen / channel / bore / passage / conduit |
  | Mechanical housings | hub / boss / flange / collar / shoulder |
  | Fasteners / joints | socket / recess / pocket / cavity |
  | Electrical / electronic | contact / terminal / pad / lead |
  | Optical | lens / reflector / window / aperture |
  | Structural | wall / member / support / strut / rib |
  | Surfaces | surface / face / interface |

  This list is not exhaustive — if the claim recites a structural noun that could reasonably be read narrowly (pointed barb vs. any projection) or broadly (channel vs. any passage), flag `structural-term-cognate` in `_constructions` and default the row to `construction-dependent`. The attorney can demote it to `literal` after a Markman order or a definition in the spec forecloses the ambiguity.

Show the parse to the user. Confirm before mapping. A wrong parse poisons every row below it.

### Step 2: Claim construction check

Flag disputed terms:

- Coined terms or terms defined in the spec
- Terms with prosecution history (amendments, arguments, disavowals — *Phillips v. AWH Corp.*, 415 F.3d 1303 (Fed. Cir. 2005); *Festo* estoppel)
- Functional language ("configured to", "adapted to", "operable to")
- Relative terms ("substantially", "about") — definiteness risk under *Nautilus, Inc. v. Biosig Instruments, Inc.*, 572 U.S. 898 (2014)
- Computer-implemented terms — Alice / §101 exposure for invalidity

For each flagged term, state the construction(s) under which the mapping works and the construction(s) under which it fails. If a Markman order exists, apply it. If briefing is underway, chart under each side's proposed construction.

### Step 3: Map

For each element, for each target:

1. **Find evidence.** Accused product: documentation, manuals, data sheets, source code, teardowns, deposition testimony, expert reports. Prior art: column/line for US patents, paragraph for published apps, page/figure for NPL. For prior art, flag whether the reference qualifies (§102(a)(1), (a)(2), (b); AIA vs. pre-AIA cutoffs). If prior-art status isn't obvious, mark `prior-art-status: needs-evidence`.
2. **Quote verbatim.** Character-for-character. No paraphrase. Cut at sentence boundaries and mark elision.
3. **Characterize the mapping.**

   | Mapping | Meaning | Where |
   |---|---|---|
   | `literal` | Claim language reads on the accused feature / prior-art disclosure | Both |
   | `literal-construction-dependent` | Literal under X; fails under Y | Both |
   | `doe` | Equivalent (function-way-result or insubstantial differences) | Infringement only |
   | `anticipation` | Every element in a single reference, arranged as claimed (*Net MoneyIN, Inc. v. VeriSign, Inc.*, 545 F.3d 1359 (Fed. Cir. 2008)) | Invalidity only |
   | `obviousness-combination` | Secondary reference supplies the missing element; motivation to combine required under *KSR Int'l Co. v. Teleflex Inc.*, 550 U.S. 398 (2007) | Invalidity only |
   | `partial` | Some of the element is present | Both |
   | `not-found` | Element not present | Both |
   | `needs-evidence` | Can't tell from available material | Both |
   | `construction-dependent` | Turns on how a disputed term is construed | Both |

4. **State per cell.** `mapped` / `mapped-doe` / `partial` / `not-found` / `needs-evidence` / `construction-dependent` / `anticipation` / `obviousness-combination`.
5. **Flag open questions.** "This maps if [X]. Need [teardown / source code / deposition / expert] to confirm."

**No silent supplement.** Thin documentation means `needs-evidence`, not extrapolation from similar products.

### Step 4: Dependent claims — execute, don't gesture

For each asserted dependent claim, produce an actual row (or set of rows) charting the additional limitation(s) against the target. The parent dependency is noted, and infringement / invalidity of the dependent requires the parent's. **Produce the rows, not a placeholder note that rows should be produced.**

If the user provided a list of asserted claims that includes dependents, the chart's output MUST contain rows for each of them. If the user gave only the independent claim and said "chart the independents for now," fine — then the output doesn't chart dependents, but it surfaces the dropped ones explicitly ("Asserted dependents [X, Y, Z] not charted in this run — request: rerun with `--include-dependents` or paste the dependent claim text"). Do not silently skip dependents.

A dependent-claim row format:

```markdown
| [#] | Element (verbatim) | Accused feature (or prior-art disclosure) | Evidence (pin-cited) | Mapping | State | Verified |
|---|---|---|---|---|---|---|
| 2 [add'l] | "wherein the barb extends at an angle of 15° to 30° from the body axis" | AnchorFast Mini barb angle 18° per [CM-AM-2026-03 Fig. 4 + §2.3] | [CM-AM-2026-03 §2.3] "barb angle 18° ±2°" | literal-construction-dependent | mapped | ☐ |
```

### Step 4.5: DOE supplements — execute, don't gesture

For every element charted as `literal` where the accused feature is structurally similar but not literally identical — or every element where the `literal` mapping turns on a contested construction — produce a **paired DOE candidacy row** (infringement mode). Do not footnote "DOE analysis is separate" without producing the actual DOE mapping.

A DOE candidacy row adds a one-paragraph function-way-result sketch, flags prosecution history estoppel and dedication-to-the-public risks per element, and cites the evidence that would support the equivalent. If DOE is inapplicable (the element reads literally on the accused product beyond dispute), skip. If `literal` is construction-dependent and DOE would be the attorney's fallback under the narrower construction, produce the DOE row.

Format:

```markdown
| [#-DOE] | Element | Accused feature | Function-way-result | PH estoppel? | Dedication risk? | State |
|---|---|---|---|---|---|---|
| 1b-DOE | "at least one barb" | three-barb opposing-face array | function: resist withdrawal; way: mechanical engagement with cancellous bone; result: anchor remains seated under tensile load. | [needs-evidence: prosecution history] | [needs-evidence: disclosed-but-unclaimed alternatives in spec] | construction-dependent |
```

As with dependents: if the skill can't produce the DOE rows for a reason (no accused-product evidence to ground function-way-result, no prosecution history available), say so explicitly and route to `needs-evidence`. Do not skip DOE silently.

### Step 5: Indirect, divided, willfulness (infringement only)

Flag, don't opine:

- **Induced (§271(b))** — *Commil USA, LLC v. Cisco Systems, Inc.*, 575 U.S. 632 (2015); *Global-Tech Appliances, Inc. v. SEB S.A.*, 563 U.S. 754 (2011)
- **Contributory (§271(c))** — component especially made for infringing use
- **Divided / joint (§271(a))** — *Akamai Techs., Inc. v. Limelight Networks, Inc.*, 797 F.3d 1020 (Fed. Cir. 2015) (en banc) directs/controls test
- **Willfulness** — *Halo Elecs., Inc. v. Pulse Elecs., Inc.*, 579 U.S. 93 (2016); treble damages under §284

### Step 6: Invalidity thresholds (invalidity only)

For §102: every element in a single reference. Partial across references is §103.

For §103: primary reference + secondary reference(s) + documented motivation under *KSR*. Flag explicit teaching/suggestion/motivation, market or design-need motivation, reasonable expectation of success, and **secondary considerations** (*Graham v. John Deere Co.*, 383 U.S. 1 (1966)) — commercial success, long-felt need, failure of others, industry praise, copying.

Also flag:
- **§101** — *Alice Corp. Pty. Ltd. v. CLS Bank Int'l*, 573 U.S. 208 (2014); *Mayo Collaborative Servs. v. Prometheus Labs., Inc.*, 566 U.S. 66 (2012)
- **§112 ¶ 1** — written description, enablement (*Amgen Inc. v. Sanofi*, 598 U.S. 594 (2023))
- **§112 ¶ 2** — definiteness (*Nautilus*, supra)
- **§112 ¶ 6** — means-plus-function structure
- **Unenforceability** — inequitable conduct, prosecution laches, assignor/licensee estoppel (attorney-only flags)

Invalidity must be shown by clear and convincing evidence — *Microsoft Corp. v. i4i Ltd. P'ship*, 564 U.S. 91 (2011). Prima facie in a chart is not proof at trial.

### Step 7 (review sub-mode): Audit

For each row: is the mapping supported? Is the pin cite accurate? Is the element fully accounted for? What's the strongest counter? What's the rebuttal opportunity? Output verdicts per row (`supported` / `weak` / `unsupported`) and the chart's vulnerabilities.

## Patent-mode guardrails (in addition to shared guardrails)

- **Rule 11 / Patent Local Rule.** Infringement and invalidity contentions require a reasonable inquiry and a non-frivolous basis. A chart out of this skill is a draft, not a contention.
- **Claim construction candor.** Every construction-dependent row states the construction assumed and the construction under which the mapping fails.
- **DOE candor.** A DOE mapping is not equivalent to a literal one. Flag prosecution history estoppel and dedication-to-the-public risks per element.
- **Indirect is separate.** Don't fold induced / contributory into direct-infringement rows.
- **Invalidity burden on the chart.** State the clear-and-convincing standard.

---

# MODE 2 — Civil element chart

Map the elements of a cause of action (or affirmative defense) against the evidence. The killer outputs are (a) a chart that says what evidence goes with what element and (b) a gap list that tells the attorney what's missing.

## Workflow

### Step 1: Identify the claim(s)

- What cause of action? (Or defense?) If multiple counts, chart each separately.
- Which side? Plaintiff's prima facie case, defendant's affirmative defense, defendant's challenge to plaintiff's prima facie case (MSJ mode). Read `## Side` in the practice profile for the default — `plaintiff` defaults to mapping the prima facie case (proving the elements); `defense` defaults to mapping gaps and affirmative defenses (disproving or avoiding the elements). Confirm the posture matches this matter before starting.
- Which jurisdiction? State and court. **Elements and pattern-instruction language vary by jurisdiction.** The template library is a baseline; the controlling pattern instruction or statute controls.
- Which pleading? Load the complaint / counterclaim / answer so the chart tracks the counts actually pleaded, not a generic version.

### Step 2: Load the elements

Three paths:

**(a) Template library.** Reference `references/element-templates.md` (in this skill's directory). Baseline elements for common causes of action and common affirmative defenses, with citations to the Restatement / pattern instructions and a jurisdiction caveat. Select the template that matches the pleaded count.

**(b) Custom.** User defines elements, or pastes a jury instruction / statute / a count from the complaint to parse. Parse into numbered elements.

**(c) Affirmative defenses.** Also support mapping defenses — statute of limitations, laches, estoppel, waiver, unclean hands, release, accord and satisfaction, failure to mitigate, comparative fault, contributory negligence, assumption of risk, etc. Defenses have their own elements the defendant must prove (or, for some, the plaintiff must negate once raised).

**Jurisdiction-specific formulations — surface proactively.** If the practice profile's `## Company profile → Core jurisdictions` or the active matter's `matter.md` names **Delaware, New York, or California** (the three most-common commercial fora), surface the state-specific formulation proactively alongside the baseline — do not ask "does your jurisdiction add/drop/reword" first. The user shouldn't have to teach the skill the local rule; the skill should offer it and let the user choose.

Divergences to surface without being asked (non-exhaustive — add to this list as patterns recur):

| Cause of action / defense | Baseline (Restatement / pattern) | Jurisdiction-specific formulation |
|---|---|---|
| Breach of contract | 4 elements (contract, performance, breach, damages; CACI 303) | **DE:** 3 elements — contractual obligation, breach, damages (causation folded into breach) per *VLIW Tech., LLC v. Hewlett-Packard Co.*, 840 A.2d 606 (Del. 2003). **DE adds a 5th element** — no adequate remedy at law — when the claim seeks specific performance. |
| Breach of contract — goods | Common-law breach elements | **If goods + U.C.C. Article 2 jurisdiction (all 50 states except LA):** load U.C.C. breach elements (conforming tender, acceptance / rejection / revocation, cure, cover, seller's remedies). Present both; let user pick. |
| Breach of contract — multi-lot goods / installment contract | Common-law breach or U.C.C. § 2-711 (single-delivery breach framework) | **Installment contracts under U.C.C. § 2-612** — "substantial impairment of the value of the installment" replaces the perfect-tender rule; aggregate breach requires "substantial impairment of the value of the whole contract." If the contract calls for goods to be delivered in separate lots (multiple shipments, deliveries), default to § 2-612 framing — it is the governing regime and the analysis is materially different from single-delivery breach. Flag for signer: "This is drafted as an installment contract under § 2-612 — confirm that characterization matches the contract's delivery structure." |
| Negligence | 4 elements (duty, breach, causation, damages; Restatement (Second) Torts § 281) | **CA:** follow CACI No. 400 formulation (negligence per se per CACI 418 when applicable). **NY:** PJI 2:10 formulation — slightly different language on proximate cause. |
| Negligent misrepresentation | Restatement (Second) Torts § 552 — justifiable reliance, pecuniary loss | **NY:** requires **contemporaneous privity** or a relationship "so close as to approach that of privity" per *Credit Alliance Corp. v. Arthur Andersen & Co.*, 65 N.Y.2d 536 (1985). |
| Fraud | 9 elements (often condensed to 5 — representation, materiality, knowledge of falsity, intent to induce, justifiable reliance, damages) | **DE:** 5 elements per *Stephenson v. Capano Dev.*, 462 A.2d 1069 (Del. 1983). **CA:** CACI 1900 formulation — 5 elements with reliance being "justifiable." **NY:** requires pleading with particularity under CPLR 3016(b), and scienter is a distinct element. |
| Breach of fiduciary duty | Restatement / common law — fiduciary duty, breach, damages | **DE:** the most-developed body of fiduciary-duty law (*Aronson v. Lewis*, *Cede & Co. v. Technicolor*, *In re Trados*) — default to the Delaware formulation for any DE-entity matter regardless of forum. |

When a jurisdiction-specific formulation differs materially from the baseline, the chart opens with a one-line callout:

> **Jurisdiction note:** You told me this is a [DE/NY/CA] matter. Here's how [jurisdiction]'s formulation differs from the baseline: [divergence]. The chart below uses the [jurisdiction] formulation. If that's wrong, say so and I'll reload.

Confirm the element list with the user before mapping. If the user's jurisdiction isn't DE/NY/CA, ask: "Does your jurisdiction's pattern instruction add / drop / reword any of these?" If yes, use their version.

### Step 3: Map

For each element:

- **Evidence supporting** — what proves this element? Cite the source with a pin cite.
  - Deposition testimony — `[Doe Dep. 42:15–43:7]`
  - Declaration — `[Smith Decl. ¶ 12]`
  - Produced document — `[DEF00012345 at 3]`
  - Admission — `[Def.'s Resp. to RFA No. 5]`
  - Exhibit — `[Trial Ex. 14 at 2]`
  - Expert report — `[Jones Expert Rep. at 18]`
  - Discovery response — `[Pl.'s Resp. to Interrog. No. 8]`
  - Statute / case — for purely legal elements
- **Verbatim quote** where the evidence is testimonial or documentary. No paraphrase.
- **Evidence contradicting** — what cuts the other way? Cite it. This is the row's vulnerability.
- **Strength** — `strong` / `moderate` / `weak` / `none`. Keep it simple. Over-calibrated strength scores are noise; `weak` and `none` are the rows that matter.
- **State per cell** — `supported` / `partial` / `disputed` / `gap` / `needs-discovery`.

### Step 4: Gap detection — the killer output

After mapping, produce a gap list. This is the point of the chart.

> **Elements with thin or no evidence:** [list]
>
> - If asserting (plaintiff): these defeat your complaint's plausibility (Iqbal/Twombly), your MSJ opposition, or your case at trial. Close them before the next motion.
> - If defending: these are your MSJ targets and your directed-verdict motion. The plaintiff has to prove each element; a gap is a defense.
> - If pre-discovery: these are your discovery priorities — the depositions, document requests, and interrogatories that turn a gap into `supported` or confirm `none`.

Gap detection is not a conclusion about the merits. It's a map of where the case is light.

### Step 5: Phase-aware framing

Ask the phase. Same chart; different framing on the output:

- **Pre-filing / pleadings.** Does the complaint allege each element with plausibility (*Ashcroft v. Iqbal*, 556 U.S. 662 (2009); *Bell Atl. Corp. v. Twombly*, 550 U.S. 544 (2007))? Any element pleaded on information and belief without factual support is a 12(b)(6) target.
- **Discovery.** For each `gap` or `needs-discovery` element, what discovery is needed? Which witnesses, which document custodians, which interrogatories, which RFAs.
- **MSJ.** For each element, is there a genuine dispute of material fact? A `supported` cell for the movant with no contradicting evidence is summary-judgment ammunition; a `disputed` cell is MSJ-defeating.
- **Trial.** Order of proof. Which witness proves element 1, which exhibit proves element 2, who authenticates, what's the foundation. The chart becomes the trial outline.

### Step 6 (review sub-mode): Audit

For an opposing party's MSJ brief, a motion to dismiss, or outside counsel's draft: for each element, does their cited evidence actually prove it? Where is their chart thin? What's your strongest counter?

## Civil-mode guardrails (in addition to shared guardrails)

- **Jurisdiction.** The element list is a baseline. Always confirm the controlling pattern instruction (CACI, NYPJI, federal circuit pattern charge, etc.) or statute. State the source on the chart's `_elements` sheet.
- **Pleaded counts only.** Chart what's actually pleaded. Don't add a count the complaint doesn't allege just because the facts might support it — that's a different analysis.
- **Affirmative defenses.** If mapping defenses, note whether the burden is on the defendant (most) or whether raising the defense shifts a burden to the plaintiff.
- **"Gap" ≠ "case over."** A gap is a lead. Discovery, a declaration, or an expert report can close it. The chart shows where to dig.

---

# Shared chassis (both modes)

## Output

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` `## Outputs`.

### Markdown table (always)

One table per claim / defense / patent-claim per target.

**Patent mode example:**

```markdown
| [#] | Element (verbatim) | Accused feature | Evidence (pin-cited) | Mapping | State | Verified |
|---|---|---|---|---|---|---|
| 1a | "a processor configured to..." | SoC per datasheet | [Datasheet p. 7] "..." | literal-construction-dependent | mapped | ☐ |
| 1b | "means for [function]" (§112(f)) | [alleged equiv.] | [source, file.c:124] "..." | needs-evidence | needs-evidence | ☐ |
```

**Civil mode example:**

```markdown
| [#] | Element | Evidence supporting (pin-cited) | Evidence contradicting | Strength | State | Verified |
|---|---|---|---|---|---|---|
| 1 | Existence of a contract | [Ex. 3, MSA § 1; Smith Dep. 22:4–14] | none | strong | supported | ☐ |
| 2 | Plaintiff's performance | [Jones Decl. ¶¶ 4–9] | [Doe Dep. 101:3–11: "they never delivered Phase 2"] | moderate | disputed | ☐ |
| 3 | Defendant's breach | — | [Doe Dep. 101:3–11] | none | gap | ☐ |
| 4 | Causation | — | — | none | needs-discovery | ☐ |
| 5 | Damages | [Expert Rep. at 18 — $2.4M lost profits] | [Def.'s Expert Rep. at 6 — critiques methodology] | moderate | disputed | ☐ |
```

Follow with:
- **Defenses / thresholds** (patent mode: invalidity / indirect / willfulness flags; civil mode: affirmative-defense flags, Iqbal/Twombly flags pre-pleading)
- **Gap list** (civil mode) / **needs-evidence list** (patent mode) — **the priority output**
- **What cuts which way — summary** — strongest elements, weakest elements
- **Conclusion line** — *"This skill does not conclude."* Elements mapped/supported: [list]. Elements needing evidence / in a gap state: [list]. Elements construction-dependent (patent) / disputed (civil): [list]. Attorney judgment required.
- **Citation verification** — every pin cite, case, column/line, deposition page:line must be verified against the source.

### CSV (always)

Two files per chart:
- `[chart-slug].csv` — values
- `[chart-slug]_sources.csv` — verbatim quotes, pin cites, notes

**CSV / spreadsheet cell safety.** Before writing any cell value, check the first character. If it is `=`, `+`, `-`, `@`, tab (`\t`), or carriage return (`\r`), prepend a single apostrophe (`'`) to neutralize Excel/Sheets formula interpretation. Verbatim evidence from adversarial sources (opposing counsel's contentions, competitor product manuals, third-party prior art, scraped web pages, deposition transcripts, discovery productions) can contain strings that a spreadsheet will execute as formulas (`=HYPERLINK(...)`, `=cmd|...!A1`, `+WEBSERVICE(...)`), turning the chart into a data-exfiltration or RCE vector when an attorney opens it. RFC 4180 quoting alone does not defeat this — the leading `=` is still interpreted. Apply the apostrophe prefix in CSV, XLSX, and Sheets outputs. Log cells where this was applied so the reviewer can see which quotes were neutralized.

### Spreadsheet (Excel or Sheets)

Ask which the team works in. Use the pattern from `corporate-legal`'s `tabular-review` skill — same cell-level citation model, same state-based color coding, same `Verified` column, same schema sheet:

- One row per element (or element × target if comparing multiple targets)
- Each evidence column paired with a hidden source column containing the verbatim quote and pin cite; cell comments (Excel) or notes (Sheets) surface the quote on hover
- Color coding by state:
  - *Patent:* white = `mapped`, yellow = `construction-dependent` / `partial` / DOE, orange = `needs-evidence`, red = `not-found`
  - *Civil:* white = `supported`, yellow = `partial` / `disputed`, orange = `needs-discovery`, red = `gap`
- `Verified` column per evidence column, blank by default — reviewer marks it
- `_elements` sheet documenting the element source: pattern jury instruction (CACI No. X, NYPJI §Y, federal circuit pattern charge), statute (cite), Restatement section, or patent-claim parse. This is what makes the chart auditable — a reader can see where the elements came from.
- `_gaps` sheet listing every `gap`, `needs-evidence`, or `needs-discovery` row with what's still needed
- For patent mode only: `_claim-parse` sheet (element decomposition), `_constructions` sheet (disputed terms and assumed constructions)

Apply the apostrophe-prefix neutralization to every cell written into the spreadsheet.

Prepend the work-product header as the top row. Alongside it, include:

> This chart is derived from source documents that may be privileged, confidential, or both. It inherits the sources' privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. Store with the matter's privileged files and make distribution decisions deliberately. Nothing in this chart has been filed or served; it is a draft for attorney review.

### Filename and location

- Patent infringement: `claim-chart-infringement-[patent#]-claim[#]-[target]-YYYY-MM-DD.{md,csv,xlsx}`
- Patent invalidity: `claim-chart-invalidity-[patent#]-claim[#]-[ref]-YYYY-MM-DD.{md,csv,xlsx}`
- Civil: `element-chart-[count-slug]-[side]-YYYY-MM-DD.{md,csv,xlsx}`
- Review: `chart-review-[subject]-YYYY-MM-DD.{md,csv,xlsx}`

If matter workspaces enabled and a matter is active: `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/<matter-slug>/claim-charts/`. Otherwise: `~/.claude/plugins/config/claude-for-legal/litigation-legal/claim-charts/`. Surface the path. Append a one-line entry to the matter's `history.md`.

## Summary readout

After the chart is written, give a one-screen readout:

- Claim(s) / count(s) / patent claim(s), target(s), jurisdiction, phase
- Elements charted · supported/mapped · partial · disputed · gap / needs-evidence · not-found
- The gap list (civil) or needs-evidence list (patent) — **this is the priority list**
- Where the output files are
- Reminder: every cell is a lead. The chart is a draft, not a contention / brief / order of proof.

## Non-lawyer gate

If `## Who's using this` Role is Non-lawyer:

> This chart is a research draft, not a legal filing. Serving contentions, filing a brief, or relying on this for a merits opinion has Rule 11 and substantive legal consequences. An attorney in the relevant jurisdiction must review before this is used for any legal purpose.
>
> Here's a one-page brief to bring to an attorney:
>
> [Generate: claim / patent, side, jurisdiction, phase, elements, supported / gap / needs-discovery counts, the three most load-bearing open questions.]

Deliver the chart alongside the brief.

## Shared guardrails — checklist

- **Citation verification.** Every pin cite (column/line, page, deposition page:line, Bates, ¶) is a claim about the source. The attorney verifies. The skill does not fabricate cites — if a cite cannot be produced, the cell is `needs-evidence` or `gap`.
- **Source attribution.** Every verbatim quote has its source in the companion CSV and the spreadsheet's hidden source column. A quote without a source is not evidence.
- **No silent supplement.** Thin evidence means `needs-evidence` / `gap`, not "extrapolate." Do not fill from web search, training data, or "how these cases usually go" to close a gap.
- **Matter workspace check.** Confirm the active matter before writing. Never write matter A's chart into matter B's folder.
- **Decision posture.** When uncertain whether an element is met, flag; do not decide. `partial` tells the attorney what part is missing.
- **Formula injection.** Every cell written to CSV / XLSX / Sheets is checked for leading `=`, `+`, `-`, `@`, `\t`, `\r` and prefixed with `'`. Default: neutralize-then-write.
- **Elements are jurisdiction-specific.** The template library is a baseline. The controlling pattern instruction or statute controls.
- **A chart is not a brief, a filing, or a contention.** Every output is a draft.

---

## Relationship to other skills

- `ip-legal:infringement-triage` (patent mode) — the first-pass flag list. This skill is the full chart that comes next.
- `ip-legal:fto-triage` — FTO uses the same mechanics from the potentially-accused posture. If evaluating own product vs. a third-party patent, route to FTO and use this skill's format.
- `corporate-legal:tabular-review` — the underlying cell-level citation and verification-state pattern. A claim / element chart is a specialized tabular review.
- `litigation-legal:chronology` — the chronology is the timeline; the element chart is the proof matrix. A chronology entry often becomes a cell's evidence cite.
- `litigation-legal:deposition-prep` — a `needs-discovery` cell often becomes a depo topic. After a depo, new testimony fills cells.
- `litigation-legal:brief-section-drafter` — an MSJ brief's fact section is often built directly off the supported rows of an element chart.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **It does not conclude.** Not infringement, not non-infringement, not liability, not non-liability. Ever.
- **It does not decide claim construction** (patent) or **the controlling elements** (civil). It flags disputed terms / baseline elements and charts under stated assumptions.
- **It does not meet the clear-and-convincing burden for invalidity** or **the preponderance at trial**. It produces a prima facie draft for attorney review.
- **It does not substitute for expert analysis.** Source code review, teardowns, technical experts, damages experts are separate work products this chart routes to, not replaces.
- **It does not serve, file, or sign anything.** Every output is a draft. An attorney serves and files.
- **It does not extrapolate.** If the evidence isn't there, the cell is `needs-evidence` / `gap` — never a guess.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If already populated and no `--redo`, ask before overwriting.
2. Follow the workflow and reference below.
3. Run Part 0 (role, side, integration check). The interview branches by role and side.
   - **Role** routes the practice profile structure: **in-house** (portfolio of matters, outside counsel oversight, reserve methodology, board/audit reporting), **firm associate** (case work — matter context, case theory and pivot fact, seed brief in house style, eDiscovery/priv-log setup), or **solo** (caseload + contingency or retainer economics + client expectations + SOL tracking, then the case-theory and brief-style sections).
   - **Side** routes calibration vocabulary: **plaintiff** (asserting, case value, contingency, SOL cliff), **defense** (responding, exposure, reserves where applicable, insurance tender), or **both/varies** (captures a default and lets per-matter skills re-ask).

   After Part 0, walk the sections that match the selected role. Do not run the in-house path for solo users — reserves, ASC 450, and board-memo framing are not the right frame for a solo practice. Offer defaults; capture freeform overrides. Ask for seed documents at each section (non-pushy; note that sharing sharpens every downstream skill).
4. Surface gaps. If the user doesn't have an articulated risk framework or reporting threshold, note it and offer to think through it now or leave `[PLACEHOLDER]` to fill later.
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/litigation-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. Date the footer.
7. Confirm with the user before finalizing: "Here's what I captured — anything wrong?"

## Flags

- `--redo` — re-run the full interview and overwrite `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`.
- `--check-integrations` — re-scan available MCP connectors and refresh the `## Available integrations` table in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` without re-running the full interview. Use after setting up a new connector (DMS, document storage, Gmail, scheduled-tasks, CLM).

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

---

# Cold-Start Interview: Litigation

## Purpose

Every matter intake, every chronology build, every brief draft, every status rollup reads from this file. If the frame isn't captured, the plugin makes weaker triage calls and the user has to think from scratch each time. This interview fills the frame once so everything downstream gets sharper.

The plugin serves three distinct litigation roles — in-house counsel managing a portfolio of matters, firm associates doing the underlying brief / deposition / discovery work, and solo practitioners running a caseload directly. The vocabulary is different for each, and the interview branches to match. Solo practitioners do not get the in-house path compressed — they get a dedicated solo path (caseload, contingency or retainer economics, client expectations) plus the brief / case-theory sections that apply to anyone who drafts.

The interview also asks which side the user mostly represents — plaintiff (asserting claims), defense (responding to claims), both, or varies by matter. Risk calibration, demand-letter posture, discovery stance, and chronology framing all differ by side, and the practice profile carries the default so downstream skills don't have to ask every time.

**Tone:** socratic, not checklist. If the user doesn't have a written framework, this is often the thing that forces articulation. Lean into that. Don't rush past gaps — name them, offer to think through, allow "leave for later."

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed. If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/litigation-legal/*/CLAUDE.md` but not here, copy it forward.

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

Open with the fork-first preamble. Keep it to 3-4 short lines. Ask quick-or-full before anything else.

> **`litigation-legal` is for people who work litigation — managing a portfolio of matters in-house, drafting briefs and doing discovery at a firm, or both as a solo practitioner.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role (in-house / firm-associate / solo), practice setting, side default (plaintiff / defense), and active matter count, plus working defaults for risk calibration, house brief style, and privilege conventions. **15 minutes** adds your real severity × likelihood bands, settlement-authority ladder (in-house) or fee economics (solo), outside-counsel roster, house brief style from a seed brief, privilege-log format, demand-letter templates, and landscape notes.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and the path branch. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for risk calibration, house style, and case-theory scaffolding. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/litigation-legal:cold-start-interview --full` anytime to do the whole interview, or `/litigation-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below. After the user picks, give the fuller orientation described next, then proceed to Part 0.

## After the user picks quick or full

Give the fuller orientation. One paragraph, in your own voice:

> "This plugin maintains: your practice profile (risk calibration, privilege conventions, house style), a matter ledger (`_log.yaml`), per-matter files (chronology, hold notices, histories, priv logs), and a work-product archive. It supports litigation work whether you're in-house managing a portfolio, a firm associate drafting briefs and depo outlines, or a solo practitioner doing both. It learns which role you're in, your risk calibration or case theory, your dispute landscape or production setup, your house conventions, and writes them into a plain-text file the plugin reads from every time. Everything you answer can be changed later."

Then the fresh-profile note:

> "Setup builds a fresh professional profile from your answers. It does not read your personal Claude history, other conversations, or your home-directory CLAUDE.md. If I notice relevant information in our conversation context — e.g., you mentioned your company or matter earlier — I'll ask before using it. Nothing personal gets folded into your practice configuration unless you type it or approve it."

Then: "Ready? A few quick questions first."

**Why this matters** (offer if the user pushes back on the time cost). Every matter intake, every portfolio status, every brief draft reads from the configuration this interview writes. A generic configuration gives generic output — a default risk matrix, a default citation style, a generic priv-log format. Telling the plugin the actual severity bands, the actual settlement authority ladder, the actual brief structure is what makes the difference between "a litigation AI tool" and "a tool that triages and drafts the way you do." Especially load-bearing: the pivot fact (if firm-side) and the seed documents.

Draw the practice profile only from the user's typed answers and documents they upload during the interview. Do not read `~/CLAUDE.md` or pull practice facts from ambient context. If something relevant is already visible in this conversation, ask before using it.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.

**Pause for real answers.** Some questions have quick tap-through answers. Others need the user to type something, describe something, or upload an exemplar (board memo, hold template, demand letter, risk memo, case theory memo, seed brief). When a question needs more than a quick tap:

- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.
- **Ask the question and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds. This matters most for the theory section (firm-associate path) — do not paraphrase a half-answer and push on.
- **For seed-document uploads:** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review every captured answer. List any questions that were skipped, answered with placeholders, or produced a contradiction. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait.
- **Never** write a practice profile with silent gaps. Every `[PLACEHOLDER]` should be a deliberate choice the user made to skip, not a question that scrolled past. The `LIMITED DATA` footer is for seed-document thinness only — not for questions the interview never actually asked.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/litigation-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration with a `<!-- SETUP PAUSED AT: [section name] — run /litigation-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## Part 0: Who's using this + role routing

### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every matter briefing, chronology, priv log, and demand draft — lawyer outputs get the privilege header, non-lawyer outputs get the "research notes, review with counsel" header.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — founder, business lead, contracts manager, HR, procurement; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "GREEN — sign it," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — sending a demand, responding to a subpoena, issuing or releasing a legal hold, filing a brief, submitting a privilege log, designating documents in discovery, closing a matter, accepting a settlement. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). Many offer free or low-cost initial consultations.

### Role (the branching question — ask early)

> **How do you work litigation?** (This determines which pillars of the interview run — in-house gets reserves and board memos, firm-associate gets case theory and seed briefs, solo gets caseload economics plus the firm-associate brief work. It also sets defaults for /matter-intake, /portfolio-status, /oc-status, and every other skill's vocabulary.)
>
> **(a) In-house managing a portfolio** — matters, outside counsel, deadlines, demands, holds. You own many matters at once, most of which are run by outside firms. Status rollups and board memos are part of your job.
>
> **(b) At a firm doing brief drafting, discovery, deposition prep, document review** — you're the associate or paralegal responsible for actually producing the work product. One or a few matters, deep on each.
>
> **(c) Solo / small firm running a caseload** — you intake, triage, advise, and draft. No partner above you; no in-house reserve / board-memo layer. Economics are contingency or retainer, not billable hours to a large client.
>
> **(d) Something else** — describe in a sentence.

Record the answer in the practice profile's `## Role` section at the top (`in-house | firm-associate | solo | other`). Downstream skills read this to pick defaults (e.g., chronology mode, which commands are primary, which vocabulary to use).

**Branching rules for the rest of this interview:**

- `in-house` → run the **In-house path** (Pillars 1–3 below). Skip the firm-associate and solo sections.
- `firm-associate` → run the **Firm-associate path** (Parts A–D below). Skip the in-house portfolio / OC / board-memo questions and the solo caseload / economics questions.
- `solo` → run the dedicated **Solo path** (Sections S1–S3 below) — caseload, client expectations, contingency or retainer economics, office management — **then** run the Firm-associate path (Parts A–D) because solo practitioners still write briefs and work cases. Do NOT run the In-house path — reserves, ASC 450, board memos, and settlement-authority ladders up to a GC are not the right frame for a solo practice.
- `other` → ask for a one-sentence description, then pick the closest branch.

### Which side do you mostly represent?

Ask this right after the role question. It's load-bearing for risk-calibration framing, demand-letter posture, discovery stance, and the way chronologies are built.

> **Which side do you mostly represent?** (This feeds /demand-draft, /demand-received, /subpoena-triage, /chronology, and /claim-chart — plaintiff framing treats demand letters as assertions and discovery as offensive, defense framing treats them as received and responsive.)
>
> **(a) Plaintiff / claimant** — you bring claims for individuals or businesses. Demand letters are assertions you draft and send. Discovery is offensive. Statute of limitations is a cliff you work against. Economics are often contingency.
>
> **(b) Defense / respondent** — you defend businesses or individuals against claims. Demand letters are received and triaged. Discovery is defensive. Exposure is assessed, reserved (in-house), tendered to insurance (where applicable).
>
> **(c) Both** — your practice regularly includes both. Ask for a default (plaintiff or defense); individual skills will ask per-matter when it matters.
>
> **(d) Varies by matter** — no strong default; every matter gets asked.

Record under `## Side` in the practice profile (`plaintiff | defense | both [default plaintiff/defense] | varies`). Branching rules for calibration that follows:

- **Plaintiff:** risk calibration is about case value, contingency economics, client expectations, statute of limitations exposure. Demand letters are the assertion. Discovery is offensive. Settlement-authority conversations are with the client, not a GC/board. (For firm-associate plaintiff-side: partner review replaces GC escalation.)
- **Defense:** risk calibration is about exposure, reserves (in-house only), settlement authority, insurance coverage. Demand letters are received and triaged. Discovery is defensive — responding, asserting privilege, narrowing.
- **Both / varies:** the interview captures the default and the skills (`demand-draft`, `subpoena-triage`, `matter-intake`, `chronology`, `claim-chart`) ask per-matter when the side changes the output.

### Practice setting

> Which best describes where you're practicing?
>
> 1. **Solo practitioner**
> 2. **Small firm (2–10)**
> 3. **Midsize firm**
> 4. **Large firm / Am Law**
> 5. **In-house** (company legal department)
> 6. **Government**
> 7. **Legal aid**
> 8. **Clinic**
> 9. **Other**

This refines escalation / supervision language in the practice profile:

- **Solo / small without hierarchy (1, 2):** Reframe authority-ladder questions as "when do you call in outside counsel or a colleague for a second opinion." Escalation maps to *consult* not *route for approval*.
- **Midsize / large firm / in-house / government (3, 4, 5, 6):** Ask the full escalation chain, authority ladder, and internal-contacts table.
- **Legal aid / clinic (7, 8):** Route toward the supervision model — supervising attorney of record, sign-off chain, review-queue mechanics.
- **Other (9):** Ask for a one-sentence description, then pick the closest branch.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

### What's connected?

> This plugin can work with: DMS (iManage), document storage (Google Drive, SharePoint, Box), Gmail, scheduled-tasks, CLM (Ironclad), eDiscovery (Everlaw, Relativity, DISCO, Aurora), legal research (CourtListener, Descrybe, Trellis), outside-counsel recommendations (TopCounsel). Let me check which connectors you have configured — features that need them will work, and features that don't will fall back gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need all of these. Core features work with file access alone.

Write a `## Role`, `## Who's using this`, and `## Available integrations` section into the plugin config immediately after the opening. Add `## Outputs` with the work-product header rule per the CLAUDE.md template.

---

## In-house path (role == `in-house`)

*Skip this whole section if the user's role is `firm-associate` or `solo`.*

> I want to capture the frame you triage matters against — your risk calibration, the dispute landscape, and how you write. Once, so every matter intake reads from it. I'll offer defaults where there are reasonable ones. You can accept, edit, or leave blank to come back to.
>
> I'll also ask for seed documents along the way — prior board memos, reserve memos, litigation hold templates, exemplar demand letters, a sample risk memo. Ten to twenty total across the interview is the target. Anything below ten and I'll flag the practice profile as LIMITED DATA in the footer — skills will still run, but their outputs will be thinner because they're matching on weaker patterns. Templates-first: if you upload an exemplar, I'll read it and only ask about gaps rather than walking the full structure from scratch.

### Pillar 0 — Company profile

Team-level context. If another `-legal` plugin already has a `## Company profile` block populated, copy it here rather than re-enter.

- Org / legal entity
- Industry
- Public / private / subsidiary
- Regulated status
- Core jurisdictions (operational + frequent-fora)
- Headcount + legal team size
- Key internal contacts (GC, CFO, HR lead, Comms, CISO, Board lit/audit chair) — names + when to loop in
- This counsel's name and reporting line

### Pillar 1 — Risk calibration

> Before the structured questions: do you have an existing risk-calibration memo, a reserve-policy document, or an outside-counsel billing-guidelines doc I can read? Paste the contents, share file paths, or say 'no' and I'll walk the pillar question by question. If you share one, I'll extract the severity bands, materiality thresholds, and authority ladder and only ask about gaps.

If not:

**Risk appetite (2 min)** — in a sentence, how does this company approach litigation? (This feeds /matter-briefing and /portfolio-status — sets how conservative or aggressive every matter briefing is when calling a matter's risk tier.)

**Severity × likelihood (3–5 min)** — offer the default 3×3. Severity bands (dollar and non-dollar triggers). Likelihood bands. If unarticulated: "Fair. A lot of counsel don't. Want to sketch now, or leave the default?"

**Materiality thresholds (2–3 min)** — reserve trigger, disclosure trigger, board/audit committee, GC-only escalation. *Seed doc opportunity:* reserve memo template or disclosure checklist.

**Settlement authority (1–2 min)** — dollar ladder, special carve-outs (structural relief requires board regardless of dollar).

**Plain-English escalation (1 min).** Ask directly:

> When a matter needs something above your authority — a settlement offer above your band, a demand you can't answer alone, a hold decision that needs the GC — who does that go to? Give me a name, a role, or "I decide myself."

(Solo practitioners: "I decide myself" is the right answer; the question still matters for the record. If you loop in outside counsel for second opinions, name the firm.)

**Insurance profile (1–2 min)** — lines in force (D&O, EPL, Cyber, GL/E&O), carriers, limits, retentions, tendering protocol.

**Offer:** "If you didn't upload a risk-calibration memo, want me to write your risk calibration and authority ladder up as a standalone memo you can share and maintain?"

### Pillar 2 — Landscape

*Company profile lives in Pillar 0. Landscape is litigation-specific.*

- Business context (30 sec) — one-paragraph on what we do and why we get sued.
- Dispute patterns (2–3 min) — matter types, frequency, posture.
- Frequent adversaries (1–2 min).
- Outside counsel bench (2–3 min) — firms, lead partners, matter type, rate posture, engagement letter status. *Seed doc:* outside counsel guidelines. (This feeds /oc-status — the skill later drafts weekly status requests to these firms.)
- Frequent fora (30 sec).
- Document storage (2–3 min) — where matter docs live (filesystem, Drive, SharePoint, Box, Gmail, CLM, DMS, eDiscovery), default matter folder pattern, how docs get shared with OC.
- Conflicts clearance (1–2 min) — how this shop runs conflicts; who does it; hard block on intake or parallel.

### Pillar 3 — House style

> Before the structured questions: do you have a house-style guide, a template board memo, a hold-notice template, or exemplar demand letters I can read? Paste the contents, share file paths, or say 'no' and I'll walk the questions.

If not:

- Board / audit committee memo (2 min) — format, tone, cadence. *Seed doc:* recent board memo (redacted fine).
- Reserve memo — format and approver. *Seed doc:* sample reserve memo.
- Outside counsel directives — email format, cadence, budget posture.
- Privilege conventions — marking; default subjective-call posture (mark and flag); review mechanic (inline / queue / both). (This feeds /privilege-log-review — the skill applies your marking rules and review mechanic on every priv-log pass.)
- Legal hold — template, issuance protocol, refresh cadence. *Seed doc:* hold template. (This feeds /legal-hold — the skill issues, refreshes, and releases holds using your house template.)
- Escalation — channel norms, subject-line convention.
- Demand-letter practice — *not asked here.* Demand posture (tone, time limits, marking, signer) is set per matter, not per practice. `/litigation-legal:demand-intake` and `/litigation-legal:demand-draft` will ask when they need it — those calls depend on the relationship, the amount, and whether litigation is likely, and a practice-level default tends to mis-calibrate the specific letter. What the setup interview *does* want here: insurance-tender timing (who you notify and when, before sending) and materiality threshold for matter creation (below $X, record only; above, create a matter). Those are practice-level.

**Offer:** "If you didn't upload a house-style guide or templates, want me to write your house-style rules up as a standalone style memo?"

---

## Solo path (role == `solo`)

*Skip this whole section if the user's role is `in-house` or `firm-associate`. Solo users run this path **and** the Firm-associate path that follows.*

> Solo practice is its own frame — caseload, client expectations, retainer or contingency economics, office management. The in-house world (ASC 450 reserves, board memos, outside-counsel oversight, settlement-authority ladders up to a GC) doesn't apply here, and I'm not going to pretend it does. The firm-world reserves questions don't apply either. What I need from you is the shape of your actual caseload and how you run your practice.
>
> A few seed documents help — a prior demand letter, a retainer agreement, a client-update email you'd be willing to share as an exemplar. Anything we can learn from saves a round trip later.

### Section S1 — Practice shape and caseload

- **Caseload size** — roughly how many active matters do you carry at once? What's too many?
- **Matter mix** — rough percentages: plaintiff vs defense, practice areas (e.g., PI, family, employment, small business disputes, landlord/tenant). No need to be precise; a sentence is enough.
- **Jurisdictions** — the state(s) and courts you primarily practice in. Include federal if relevant.
- **Typical case duration** — weeks, months, years? Useful for downstream skills to scale effort and deadline horizons.
- **Capacity flags** — is there a point where you stop accepting cases? How do you know you're over capacity?

### Section S2 — Client expectations and economics

*This replaces what the in-house path calls "risk calibration / reserve methodology / settlement authority ladder." Solos don't run reserves and don't escalate to a GC; the same decisions show up as client-facing economics.*

**Fee structure (the main driver).** Pick the one that fits most of your work:

- **Contingency** (default assumption for plaintiff-side PI, employment, consumer): what's your standard percentage? Pre-suit vs post-suit? What's the cost advance posture — client, firm, hybrid? At what exposure do you stop taking a case on contingency?
- **Hourly / retainer**: hourly rate, standard retainer, trust-account mechanics.
- **Flat fee**: which matter types, and the fee range.
- **Mixed**: describe the mix.

**Client expectations (2 min).** Ask directly:

- How often do you update clients on their matters (weekly, monthly, event-based)?
- What form do updates take — phone call, email, letter, client portal?
- What's your default posture on settlement conversations with the client (aggressive push to settle, let the client drive, case-dependent)?

**Exposure / case-value read (plaintiff-side).** What's your quick mental framework for deciding a case is worth taking? Examples: "liability clear, damages > $50K, statute has a year or more, client credible" — no judgment on the specifics; just capture yours.

**Exposure read (defense-side solo — less common but possible).** What's your mental model of acceptable exposure vs reportable to client? Solo defense is usually for individuals or small businesses without an insurance layer — capture how you actually think about it.

**When you call for help.** Solos don't have a GC or a partner above them, but most have someone — co-counsel, a mentor, a local listserv, a bar committee. Who do you call for a second opinion, and on what kinds of matters?

> Give me a name, a role, or "nobody — I decide on my own."

**Client updates in writing (1 min).** *Seed doc opportunity:* a recent client update email or letter (redacted). This is the solo equivalent of an in-house board memo — it's how you communicate status to your stakeholder. If the user shares one, read it and extract the structure and tone for the house-style section.

### Section S3 — Office management and landscape

*Skip any question where the answer is obvious from earlier context.*

- **Statute of limitations tracking** — how do you track SOL cutoffs across the caseload? (Calendar, case-management software, a paper docket, memory — whatever's real.) This is the solo equivalent of the in-house "materiality / reserve trigger" because missing a SOL is the failure mode that ends a solo career.
- **Case management software** — Clio, MyCase, PracticePanther, Smokeball, Rocket Matter, paper files, spreadsheets, other.
- **Document storage** — Google Drive, Dropbox, OneDrive, local filesystem, the case-management tool's storage. Where do matter documents actually live?
- **Frequent fora** — courts you actually appear in.
- **Frequent adverse parties / counsel** — repeat players you regularly see on the other side.
- **Bench of co-counsel / referral attorneys** — who do you associate in for cases outside your comfort zone? Who refers out to you?
- **Conflicts clearance** — how do you run conflicts? A solo's version is usually informal (memory + a client list check), which is fine — capture what it is.

### Solo house style

Skip the board-memo / reserve-memo / outside-counsel-directive questions entirely. Solo house style is:

- **Client update** — format, tone, cadence. *Seed doc:* a recent update letter or email.
- **Retainer / engagement agreement** — template. *Seed doc:* the exemplar (redacted fine).
- **Privilege conventions** — marking; review mechanic.
- **Legal hold** — even for a solo, preservation matters when litigation is anticipated. Template, if any. *Seed doc:* hold notice if issued.
- **Demand-letter practice** — *not asked here.* Demand posture (tone, time limits, marking, signer) is set per matter, not per practice — the solo equivalent of "who signs" answers itself (you), and tone/marking/timing depend on the specific dispute. `/litigation-legal:demand-intake` will ask when it drafts.

**Offer:** "If you didn't upload a client-update exemplar or retainer, want me to write your house-style rules up as a standalone memo you can reuse?"

After Section S3, continue to the **Firm-associate path** below. Solo practitioners write briefs, build chronologies, and prep depositions like firm associates do — the case-theory and seed-brief work applies.

---

## Firm-associate path (role == `firm-associate` or `solo`)

> Before I touch a document, I need the theory. What's our story? What's theirs? What does the case turn on? Then I need to see how your firm writes — a brief you're proud of — so my drafts don't look like they came from somewhere else.

### Part A: The matter (2 min)

- Matter name, client, case number, court
- Our side (plaintiff / defendant)
- Partner and senior associate (skip if solo / small without hierarchy)
- Stage (pleadings, discovery, summary judgment, trial prep)
- Key dates coming up

### Part B: The theory — this is everything (3–4 min)

> Tell me our theory of the case. Not the complaint — the story. If you had to tell a jury why we win in two sentences, what are they?

- Our theory in a paragraph
- Their theory in a paragraph (know the other side)
- **The pivot fact** — the fact the case turns on
- Key facts for us
- Key facts against us (the ones you're worried about)
- The legal issue that matters most

### Part C: Seed documents (3–4 min)

> Two things:
>
> 1. **The case theory memo**, if one exists. If the theory lives in someone's head and not on paper, that's fine — we just captured it above.
>
> 2. **A prior brief in house style.** Not from this case — any case. The best one you've got. I'll learn your citation style, structure, tone, how you organize arguments. (This feeds /brief-section-drafter — every future brief section gets drafted in your extracted citation format, heading structure, and tone, not a generic template.)

**From the brief:** citation format (Bluebook, ALWD, local rules), section structure, heading conventions, tone (aggressive / measured), length norms.

### Part D: Document review setup (1–2 min)

> Before the questions: do you have a privilege-log format, a chronology format, or a review-protocol doc I can read? Paste the contents, share file paths, or say 'no' and I'll ask one at a time.

If not:
- eDiscovery platform (Everlaw, Relativity, DISCO, Aurora)
- Review protocol — coding categories, who makes priv calls
- Privilege log format
- Key custodians and date range

**Offer:** "If you didn't upload a priv-log or chronology format, want me to write your review protocol and priv-log format up as a standalone reference you can share with a review team?"

---

## Before writing — re-read

Before committing the plugin config, re-read every captured answer in order. This catches three categories of mistake:

1. **Contradictions between answers** — e.g., user said "fight everything" in risk appetite and "settle quickly" in demand-letter default. Surface both, ask which governs.
2. **Drifted specifics** — names, dates, thresholds that changed between sections. Confirm the final value.
3. **Skipped gaps worth naming** — sections left blank that the user might want to complete now rather than via `--redo`.

Also: if the role is `firm-associate`, double-check that the pivot fact and the seed brief were captured. These are load-bearing. If either is missing, name it explicitly before writing.

## Writing the practice profile

Write the completed practice profile to the plugin config, using the template at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` as the section scaffold. Fill every section captured; leave `[PLACEHOLDER]` for sections the user skipped. Date the footer.

**Section gating by role:**

- `in-house` → full in-house structure (Company profile, Risk calibration with ASC 450 / reserve / board-memo rows, Outside counsel bench, Board/audit committee memo). Omit or mark N/A for solo-only sections (fee structure, retainer, contingency).
- `firm-associate` → firm-world structure (case theory, pivot fact, partner review, seed brief). Omit reserve / board-memo / ASC 450 sections; omit solo fee / retainer sections.
- `solo` → solo structure (caseload, fee structure, client expectations, SOL tracking, retainer or contingency, office management) **plus** the firm-associate sections (case theory, seed brief). Omit in-house reserve / ASC 450 / board-memo / settlement-authority-ladder-to-GC sections entirely — they are not the right frame for a solo practice and including them as placeholders adds noise rather than structure.

Where a template section carries in-house-only vocabulary ("ASC 450 reserves", "board / audit committee memo"), either omit the section for non-in-house roles or translate the vocabulary into the equivalent solo or firm-associate concept. Solo equivalent of "board memo" is "client update letter." Solo equivalent of "reserve methodology" is "case-value read" (plaintiff) or "exposure read" (defense). Do not carry the accounting-standard language into a solo profile.

**LIMITED DATA flag:** if fewer than 10 seed documents were shared across the interview, add a `> LIMITED DATA` note at the top (under the written-on date): "This practice profile was written from [N] seed documents and interview answers. Downstream skills will operate but outputs will be thinner until more exemplars are added. Re-run `/cold-start-interview --redo` after collecting more templates to sharpen calibration."

## Gap surfacing

After the interview, before writing, summarize and **wait for an answer**:

> Here's what I captured. Gaps I noticed:
> - [list any skipped sections, placeholders left blank, questions where the user said "come back later"]
>
> Want to fill any of these now, or leave them as placeholders? You can also fill them later via `/litigation-legal:cold-start-interview --redo` or by editing the plugin config directly. This one is worth thinking about before I write: [name the most important gap and why].

Do not proceed to writing until the user answers.

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in litigation practice:**
>
> - **Intake a new matter** — e.g., "Uniform intake questions, writes matter.md + history.md, appends to the portfolio log." Try: `/litigation-legal:matter-intake`
> - **Triage an inbound demand** — e.g., "Options analysis, portfolio cross-check, handoff to matter intake if it graduates." Try: `/litigation-legal:demand-received`
> - **Draft a demand letter** — e.g., "Privilege / FRE 408 gate, .docx output, post-send checklist, matter-creation offer." Try: `/litigation-legal:demand-draft`
> - **Build a deposition outline** — e.g., "Docs + topics + impeachment + exhibits, tied to case theory." Try: `/litigation-legal:deposition-prep`
> - **Issue or refresh a legal hold** — e.g., "Draft the hold memo, update the log, schedule a refresh." Try: `/litigation-legal:legal-hold`
> - **Portfolio rollup** — e.g., "Risk distribution, upcoming deadlines, stale matters across the active portfolio." Try: `/litigation-legal:portfolio-status`
>
> **My suggestion for your first one:** Run `/portfolio-status` — it shows you at a glance where the portfolio sits, and it's zero-input to try. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


- If `in-house`: "The in-house practice profile is now written. Every matter intake will read from it. Want to run `/litigation-legal:matter-intake` on your most live matter to see it in action?"
- If `firm-associate`: "Here's the theory as I captured it. Read the pivot fact — did I get it right? What's the next deadline? Let's start there."
- If `solo`: "Your solo practice profile is written — caseload shape, fee economics, how you run the office — plus the case-theory and brief-style work for a live matter. Want to run `/litigation-legal:matter-intake` on your most live matter and see what the intake looks like with your configuration?"

### Close with the "you can change anything later" note

> "Your practice profile is at `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — a plain text file you can read and edit directly. Anything you answered can be changed:
>
> - Edit the file directly for a quick change
> - Run `/litigation-legal:cold-start-interview --redo` for a full re-interview
> - Run `/litigation-legal:cold-start-interview --new-matter` to reuse the practice profile on a new matter (firm-associate / solo)
> - Run `/litigation-legal:cold-start-interview --check-integrations` to re-check what's connected
>
> The sections people adjust most: for in-house, the **severity × likelihood thresholds** and the **outside counsel bench**; for firm associate, the **case theory** (especially the pivot fact) and the **house brief style** extracted from the seed brief; for solo, the **fee structure** (contingency percentage or hourly rate) and the **side default** (plaintiff / defense) — a wrong default there skews every demand-letter and chronology output. When an output feels off, the fix is usually here."

### Before your first matter

**Connect a research tool.** Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you.

<!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
     "Want a walkthrough? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->

### Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## What this skill does not do

- Decide the framework for the user. Defaults are starting points; the user's judgment is the actual content.
- Pretend gaps aren't there. Better to leave `[PLACEHOLDER]` honestly than to invent a threshold.
- Fight the user. If they say "I don't have that yet," note it and move on.
- Read personal `~/CLAUDE.md` or other ambient context without asking.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/litigation-legal:customize`. They want to change something
in their litigation profile — a risk calibration, a house style rule, an
escalation contact, a landscape note — without re-running the whole
cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/litigation-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting *(shared across all 12 plugins — changes flow through
     `company-profile.md`)*
   - **Practice role** — in-house counsel / outside counsel / solo / clinic
   - **Side** — plaintiff / defense / mixed, and any posture nuances (class
     action defense, regulatory enforcement defense, commercial
     plaintiff, etc.)
   - **Risk calibration** — what counts as high / medium / low risk on an
     inbound demand, subpoena, or new matter; escalation triggers
   - **Landscape** — regular adversaries, friendly and unfriendly venues,
     judges to know, standing OC relationships
   - **House style** — brief style, declaration format, demand letter
     template, deposition outline structure, legal hold template
   - **Severity vocabulary map** — how you translate severity labels across
     client / internal / court-facing outputs
   - **People** — matter leads, in-house team, outside counsel by matter
     type, escalation chain
   - **Workflow** — matter workspaces, portfolio log, OC status cadence,
     legal hold refresh cadence
   - **Integrations** — document storage / e-filing / calendar / Slack
     status, fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Side mixed → defense-only:* "`/matter-intake` will stop asking the
     plaintiff-side questions. `/demand-draft` will still work for
     defense-side pre-suit demands but the starting frame will be different."
   - *Risk calibration tightening high-risk threshold:* "More inbound
     demands and subpoenas will route through `/matter-briefing` and
     `/oc-status`."
   - *New standing OC for IP matters:* "`/oc-status` will include this firm
     in weekly sweeps for IP-tagged matters."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/litigation-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" a matter type
  from scope, offer to mark it `[Not currently handled]` and explain what
  intake routing changes.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., plaintiff-only side + defense-only OC roster; or
  "high volume" portfolio + no matter workspaces configured), flag the
  tension.
- **Flag guardrail degradation.** The FRE 408 / privilege gate on
  `/demand-draft`, the privilege header on matter outputs, source
  attribution tags, and `[verify]` tags on cited authorities are load-
  bearing — do not remove. The `[review]` flag and the "do not file
  without attorney review" framing are load-bearing.
- **One change at a time.** Don't re-ask the whole interview.$body$)
ON CONFLICT (skill_key) DO NOTHING;
