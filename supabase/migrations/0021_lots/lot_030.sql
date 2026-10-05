INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:healthcare/healthcare/plugins/healthcare/skills/procedure-coding', 'healthcare', 'procedure-coding', '', 'procedure-coding', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:healthcare', '', $body$# Procedure Coding from Encounter Documentation

Turn one encounter's clinical documentation into the procedure codes a professional coder would submit on the claim: CPT (five digits, or four digits + F for Category II tracking codes) for physician services, procedures, and quality measures, plus HCPCS Level II (letter + four digits) for supplies, devices, and non-physician services CPT does not cover.

## Step 1 — Abstract every billable service from the note

Read the documentation and list each distinct billable service performed at this encounter. Work by category:

- **Evaluation and management** — the visit itself: office, emergency, observation, inpatient, consultation. One E/M code per encounter unless a separately identifiable service is documented. When the visit is for ongoing management of a single serious or complex chronic condition, the complexity add-on may apply alongside the office E/M code.
- **Ancillary services that ride alongside the visit** — a blood draw for any lab is a separately billable venipuncture; each lab test ordered with a result in the note bills its own code; an ECG or pulse-ox performed in the visit is its own code; an injection, infusion, or IV push administered during the visit codes the administration plus an add-on for each additional sequential push or hour.
- **Procedures and surgery** — anything with an incision, injection, scope, repair, or manipulation. Abstract from the procedure note, not the plan.
- **Laboratory and pathology** — each ordered test that has a result in the note. Panels (CBC, BMP, CMP) bill as the panel code, not the components.
- **Imaging** — each study by modality and body part, with the view/contrast detail documented.
- **Medicine services** — vaccinations administered, infusions, therapeutic injections, ECGs, pulmonary function, physical therapy.

Leave off the list: services planned but not performed, results referenced from a prior date, and items already bundled into a procedure's global package.

## HCPCS Level II — what to look for and what to leave off

HCPCS Level II codes (one letter + four digits) cover items CPT does not. Check the documentation for these specifically:

- **Hospital observation hours** — when the note shows the patient was placed in or remained in observation status, code the per-hour observation service (and the direct-referral code when the patient was placed in observation without a preceding ED visit).
- **Devices and implants used during a facility procedure (C-codes)** — for any catheterization, endoscopy, interventional, or implant procedure, read the operative/procedure narrative and the supply or implant log for each single-use device the operator names: guide wire, introducer or sheath, diagnostic or guiding catheter, lead, stent, closure or embolization device, balloon. Operative prose often names these in passing ("wire advanced," "sheath placed," "device deployed") rather than in a discrete list — abstract each one. Each device the procedure consumed codes separately under hospital outpatient rules.
- **Drugs administered in the facility (C-codes)** — certain injectable drugs given during a hospital outpatient encounter carry their own pass-through code. Scan the medication-administration record or nursing notes for IV-push or infusion drugs given during the stay and match by drug name.
- **Specimen collection performed by facility staff** — a documented swab or draw billed by the facility separately from the lab test.
- **Supplies dispensed** (A-codes) — sterile saline, dressings, trays, ostomy supplies, when the note or supply record names the specific item.
- **High-throughput infectious-disease lab tests** (U-codes) — when the lab order or result names the specific assay platform.
- **Medicare preventive and screening services** (G0-codes) — annual wellness visit, advance-care-planning, depression or alcohol screening, diabetes prevention. Code only when the note documents the specific service was performed at this visit, not when the topic appears in history.

**Do not output quality-reporting G-codes (G8-/G9- range) or non-covered-item codes.** These report participation in a quality program or a coverage determination; whether they belong on the claim depends on the practice's program enrollment and the payer, not on the clinical documentation. A data point appearing in the note (BMI in vitals, medication list reviewed, tobacco status in social history) is not by itself a reason to report the corresponding quality code.

## CPT Category II (####F) — same rule as quality G-codes

Category II tracking codes are reported when the encounter is part of a quality-reporting workflow, not whenever the data point happens to appear in routine vitals or history. Output a ####F code only when the note shows the measure was deliberately captured for reporting: a quality-measure or health-maintenance section, measure-specific attestation language, or a structured screening result.

## Step 2 — Find each code with the lookup tools

For every item on your abstracted list, search before you commit.

**HCPCS Level II (letter + four digits):** use `search_codes` for the supply, device, drug, or service name, passing the encounter date as `as_of`. Confirm with `validate_code` and the same `as_of`.

**CPT (five-digit and ####F):** if a CPT lookup connector is available (`cpt_search_codes`), use it with the service in plain words taken from the note and confirm with `cpt_lookup_code`. If no CPT connector is available, propose CPT codes from your knowledge of the current code set and state that they are pending verification against the user's licensed CPT reference — CPT descriptors are AMA-licensed and not bundled with this skill.

One or two searches per item is sufficient. If the right code is not in the first results, refine the query once with more specific wording from the note; then commit or move on. Do not loop on the same item.

## Step 3 — Output

After tool calls, output only the codes that belong on the claim, one per line, no other text. List each code once. Do not output J#### or Q#### codes. If a service you abstracted has no matching code in the lookup results and you cannot confidently propose one, omit it rather than guessing.$body$),
('marketplace:k12-teacher-skills/k12-teacher-skills/plugin/skills/k12-check-for-understanding', 'students', 'k12-check-for-understanding', '', 'k12-check-for-understanding', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:k12-teacher-skills', '', $body$# K-12 Check for Understanding

1–3 formative items for a standard the teacher is about to teach or just taught: scoped to one
learning component within it, distractors drawn from documented student errors, plus a teacher guide
saying what each response reveals and what to do. A CFU is small on purpose — a five-minute read
of where a class is, not an assessment event. "The teacher" is the user you're talking with.

**Asset-based language everywhere**, in both files and every chat message. No "weak," "fragile,"
"can't," "behind," "deficient," "low," "struggling," "failing." Reframe with specificity, not
euphemism: not "fragile understanding of denominators" but "treats the denominator as a count of
parts rather than the size of each part."

---

## Keeping the teacher posted

Keep the teacher posted in a sentence or two as you go, in a teacher's words: the topic, the grade,
what students will be asked to do, what they're getting. The machinery in this document — steps,
lookups and connectors, learning components, the checks you run, file names and formats — stays
invisible; this applies to every message, progress notes included. "I'll ground this in the
standard and the common errors for it, then build the check and a guide for reading responses", not
"Reading the math build guidance required by Step 0."

---

## Step 0 — Route (silently)

**Subject.** Math — arithmetic, fractions, ratio and proportion, geometry, algebra, functions,
statistics and probability, calculus, CCSS-M codes → **read `references/math.md` NOW**. Loading it is
mandatory; designing items without it is a critical failure, and it is your skill instructions for
the turn. For ELA, science, or social studies, set this document aside and help as you normally would,
without naming the skill. If the subject is ambiguous, ask in Step 1.

**Connector.** Are Learning Commons KG tools (e.g. `find_standard_statement`) available? This decides
Step 2; the skill works fully without them.

---

## Step 1 — Clarify

At most one question, and only when the answer changes the items:

- **Grade**, when not stated or inferable — "fractions" spans several grades, and the standard
  decides number values, representations, and what is on-grade. Ask before Step 2.
- **Which standard**, when the topic maps to two plausible ones.

Everything else defaults silently; never ask about item count, format, or rigor.

---

## Step 2 — Ground in the standard

**Connected:** follow `references/learning-commons-kg.md` — call BEFORE designing anything; not
calling when connected is a critical failure.

**Not connected:** work from the standard as you know it and add a footer to the teacher guide *"The standard,
progression, and common errors here reflect general best practice."* with nothing
about what was or wasn't retrieved. Never invent KG citations or cite research you haven't seen.

---

## Step 3 — Select and confirm the learning-component focus

A standard holds several separable ideas; scoping to one gives more actionable signal.

1. Review **every** learning component returned in Step 2, if available.
2. Select the **most assessable** — a genuine decision point in student understanding, probeable with
   1–3 items, separating students at different levels of understanding.
3. **State the selection and rationale, then stop and ask.** What the component asks students to do
   in one plain sentence — a teacher's words, not the component's own wording — naming any constraint
   it carries; one line on why; one direct question. **Do not proceed to Step 4 until the teacher
   answers.**
4. **If the teacher redirects** — a different component, or more than one — their choice becomes the
   scope anchor. Restate it and its rationale in one line and scope every item to it.

Then say in a sentence or two what you're about to do (*"I'll pull the common errors research has
documented for this standard, then build the check and a guide for reading the responses"*) — teacher
language, no tool or file names.

---

## Step 4 — Build the check

Follow the subject file's build section: coherence-map analysis, documented errors prioritized
against the confirmed component, the misconception-to-stem map, item design by rigor, teacher-facing
notes.

**Data-use guardrail.** Curriculum guidance and misconception data inform item design and next-step
wording internally only. **No curriculum, publisher, or research-source attribution appears anywhere
in either file or in any chat message.** Write original items; never reproduce retrieved
student-facing text, contexts, or teacher notes verbatim.

---

## Step 5 — Output

In the turn Step 4 completes. Read `references/output.md` in full first, then write both files to
`$OUTPUT_DIR`.

---

## Step 6 — Verify

**Starts only once both files exist.** Do not open `references/verification.md` during Step 4 or 5:
it is a gate on the written artifact, not build guidance, and reading it early turns it back into a
checklist you tick against what you meant to write.

Now read it in full, read both files back from `$OUTPUT_DIR`, and run its two gates on every item —
whether more than one choice can be defended, and whether each distractor is a choice a real
student's reasoning reaches. Fix what they find and rewrite the files. **Delivering a check that
hasn't been through both gates is a critical failure.**

---

## Step 7 — Close

Ask whether the check is what the teacher needs, offering at most two specific changes drawn from
what this check is — a different rigor level, a second item on the same component, a
constructed-response version. Not "let me know if you want changes." If they take one up, make it,
rewrite both files, and ask again.

**Plain language.** Never mention formats, file names, templates, how the documents were made, or the
verification and what it changed: *"Here's the check and a guide for reading the responses"*, not
*"I've written two HTML files."*

---

## Cross-cutting checklist

- [ ] Focus confirmed with the teacher first, and every item scoped to it
- [ ] The check has 1–3 items, no more
- [ ] Labeled rigor matches the standard, format follows the rigor table, and numbers and
      representations respect the grade's range and the confirmed component's constraints
- [ ] The coherence map grounds every prior-grade vs. on-grade route
- [ ] One distractor is a prerequisite gap, one an on-grade confusion; no two rows route alike; every
      next step names a sub-skill, representation, or task type
- [ ] Every student-facing sentence sits inside its grade band (K–2 ~8 words, 3–5 ~12 with at most
      one subordinate clause, 6–8 ~15), counted on the written stems and choices
- [ ] Every figure carries `<title>`/`<desc>` with `role="img"` and `aria-labelledby` in both files;
      item text and choice order are identical between them
- [ ] The student file has only prompts and choices/response space plus the name/date line; neither
      file carries a provenance marker or names a source$body$),
('marketplace:k12-teacher-skills/k12-teacher-skills/plugin/skills/k12-lesson-differentiation', 'students', 'k12-lesson-differentiation', '', 'k12-lesson-differentiation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:k12-teacher-skills', '', $body$# K-12 Lesson Differentiation

Adapts an existing K-12 lesson for below / at / above grade-level proficiency using
research-based differentiation principles (Tomlinson framework + subject-specific access
design). Works with or without the Learning Commons Knowledge Graph connector.

"The teacher" throughout this skill is the user you are talking with — the same person, never
a third party. "Teacher-facing" names a document's audience: that user, as opposed to their
students.

---

## Keeping the teacher posted

Once the teacher's path is set (the draft offer answered), say in one or two sentences
what you're about to do (e.g. *"I'll read your lesson, ground it in the standard and
curriculum materials, design the three tiers, and build the worksheets."*).

When a task-list or to-do tool is available, also outline this skill's steps there so the
teacher can watch them check off; the only reason to skip this is that no such tool exists
in this conversation.

---

## Step 0 — Route (silent, before anything else)

1. **Subject.** Detect math / ELA / science / social studies from the source lesson or the
   request, then read the matching reference file NOW:

   - math → `references/math.md`
   - ELA → `references/ela.md`
   - science → `references/science.md`
   - social studies → `references/social_studies.md`

   **Loading the matching reference file is mandatory.** It carries the pedagogy for Steps 1
   and 3 (source-lesson identification, curriculum detection, the eight differentiation rules
   R1–R8, the document content templates, and the differentiation.json mapping).
2. **Curriculum.** The subject file's "Identify the source lesson" section includes curriculum
   detection (Illustrative Mathematics / OpenSciEd). When confirmed, use that
   curriculum's discourse language and structures in the teacher plan, per the subject file.

   **Curriculum is confirmed when:** the teacher explicitly names it, OR the uploaded source
   lesson references it (the upload is implicit confirmation).

   **If curriculum is NOT confirmed** (not detectable from upload or link, no explicit mention):
   never name a specific module, unit number, lesson number, or proprietary routine name anywhere
   in the output OR in any chat message — even if you recognize the routine from training.
   Describe the instructional move in your own generic terms ("a compare-strategies
   discussion", not the routine's trademarked name). This is a hard rule; violating it fails P9,
   and chat messages count. See **Copyright guardrail** (after Step 3) for the companion rule on
   verbatim reproduction.
3. **Connector.** Check whether the Learning Commons Knowledge Graph tools (e.g.
   `find_standard_statement`) are available in this conversation. This decides which path
   Step 2 takes. The skill is fully functional without the connector.

4. **State.** Before any KG call, scan the conversation and any uploaded source lesson for
state signals and store as `state`:
   - Teacher says "I teach in [state]," "I'm in [state]," or "We're in [state]"
   - Standard codes follow a state-specific format (TEKS, SOL, OAS/PASS, MA, CA/HSS or
     CA/CCSS; other state-prefixed codes → check state)
   - Source lesson URL includes a state agency domain (tea.texas.gov, etc.)

   If state found: store `state = [state name]`. Pass as `jurisdiction="<state>"` in every
   `find_standard_statement` call in Step 2. Use state framework codes (not national proxies)
   in all output.

   If state not found:
   - for science, math, or ELA, proceed with national defaults (CCSS for math/ELA, NGSS for science). Add this single footer line to the teacher plan:
   *"Standards applied using [CCSS / NGSS] — if you're in Texas, Virginia,
   Oklahoma, or another state with a distinct framework, share your state and I'll re-anchor."*
   - for social studies, ask the teacher what state they teach in before proceeding.

---

## Step 1 — Identify the source lesson

Follow the subject file's source-lesson section: Scenario A (lesson exists earlier in this
conversation — use it directly, do not re-ask), Scenario B (teacher uploads a lesson — read it
first; if unreadable, say so and ask to re-share, never silently fabricate), Scenario B2
(teacher links a lesson by URL — fetch and read it; if the fetch fails,
ask them to paste or upload), Scenario B3 (math or science only — teacher names a curriculum lesson by position or title —
e.g. "IM Grade 6, Unit 2, Lesson 3" or "the OpenSciEd lesson on ecosystem dynamics" — Step 1
is complete; proceed directly to Step 2 where `find_curriculum_lessons` will retrieve the
lesson materials; do NOT ask the teacher to upload or link the lesson), or Scenario C (no source lesson present —
ask the subject file's clarifying question before proceeding).

A fetched link lands in the conversation whole, so a document bigger than one lesson
(a module or unit teacher edition) will not fit. When a link points at one, work from
what the request itself tells you about the lesson and confirm the specifics with the
teacher — topic, grade, and standard carry enough to build from, the same way Scenario C
proceeds after its clarify.

**Learner needs check (silent, runs every time):** Before generating, scan the conversation
for any mention of ELL levels, WIDA levels, IEP goal areas, 504 accommodations, or specific
student needs. If found, incorporate into the tier design — especially the Below tier.
Say "home language," not a specific language, unless the teacher names one.

If no learner needs are mentioned AND the pre-generation R8 ask hasn't fired (scope was already
specified), add one sentence to the FIRST response: "No specific learner needs were provided —
I've applied UDL defaults (sentence supports and vocabulary across all tiers). Share any ELL
levels, IEP goals, or specific student data and I'll adjust."

This check runs even when scope is already specified.


---

## Step 2 — Ground in standards

**If the LC Knowledge Graph is connected:** follow the subject's section in
`references/learning-commons-kg.md` — call BEFORE drafting; not calling when connected is a
critical failure, no matter how the source lesson was obtained — retrieving
the lesson never satisfies this step.

**If not connected:** proceed from best knowledge and add this footer to the teacher plan:
*"Generated without the Learning Commons KG. Standard text, prerequisite grounding, and
misconceptions reflect general best practice."* Do not invent KG citations.

---

## Step 3 — The differentiation rules

Apply **all eight rules (R1–R8)** from the subject file to every differentiated lesson. The
rules are subject-specific (scaffold types, tier entry points, extension quality tests differ
by subject) but their structure is shared: output structure (R1), standard scope preservation
(R2), tier entry points (R3), below-level scaffolds with a density cap (R4), required
pedagogical infrastructure (R5), invisible modifications (R6), within-level progressive
scaffolding (R7), and scope/defaults (R8).

---

## Copyright guardrail

Always write original content. When the source lesson draws from a named curriculum (IM,
OpenSciEd), use it to understand structure, scope, task context, and standards
alignment only — never reproduce student-facing text, activity narratives, investigation
prompts, comprehension questions, or problem contexts verbatim from curriculum materials.
Each subject reference file carries a **Copyright** line with subject-specific details.

If curriculum is NOT confirmed (see Step 0.2 detection rules), never name a specific
curriculum, module, unit number, lesson number, or proprietary routine name anywhere in the
output or in any chat message — even if recognizable from training. The source lesson and
KG data inform the design without being cited. See Step 0.2 for the full rule (P9).

---

## Step 4 — The draft offer

The teacher gets the choice of a fast draft before the build. The offer rides with
whatever you ask before Step 2 (state, source lesson, learner needs — structured question
tool when available, chat otherwise) as its own separate question, and is asked on its
own when nothing else needs asking. Its two sides are always the set and the draft. The
wording below lives in the question itself:

- Question: *Should I build a full classroom-ready set (teacher plan + three tier
  documents, as editable Word docs), or do you want to see a quick draft first?*
- Options: **Go ahead and build it** · **Quick draft first** — what changes for each
  tier, right here in chat

**The full set is the default.** A reply that selects the draft option or asks to see
the draft gets the draft; every other reply runs Steps 2–3 and goes straight to Step 5.

**The draft (on a yes) is built on Steps 2–3, never instead of them.** Run Step 2 in
full — every KG call, exactly as written — and Step 3 before sketching anything. A draft
sketched without the Step 2 grounding is a critical failure. Then present the design in
chat — the draft is chat text only;
rendering happens at Step 5 once the teacher approves. Show:

- one line reading back the source lesson, standard, and grade;
- for each tier (below / at / above), 2–3 bullets on what changes and why;
- the student work at a glance — each tier's actual tasks, enough for the teacher to
  skim and judge coverage;
- one line on what every tier shares — the essential question or core task — and the
  regroup rule

The draft borrows its names from the documents it previews — phases, tasks, tiers,
and sections are called what the plan will call them.

Afterwards, ask what's next in plain chat — a typed reply can carry the changes themselves,
which a picked option cannot: *"Want anything different? Tell me here — or tell me to go
ahead and I'll create the materials (teacher plan and the three tier documents, as editable
Word docs)."*

Apply change requests to the draft in chat and re-present it — changes are quick at this
stage. Step 5 runs in the turn the teacher gives the go-ahead.

---

## Step 5 — Output (one turn)

Runs immediately when the teacher chose the full set, or in the turn the draft is
approved.

Four artifacts — **1 teacher-facing plan + 3 student tier documents (below / at / above)** —
are all rendered by a bundled script from **one `differentiation.json` (the material source)**. Anything that
appears in more than one artifact (standard, problem/task set, exit ticket, vocabulary,
sentence supports, misconceptions) lives ONCE in the JSON's `shared` block and is pulled into
each document with `{"type": "from_shared", "key": …}` blocks, so the teacher plan and the
tier documents cannot drift apart — and R6 (same context, same core tasks across tiers) is
enforced structurally.

Every change goes into `differentiation.json` and is re-rendered (instant) — never write
layout code, hand-edit a generated document, or re-type one into another format.

**Plain language with the teacher.** The machinery above is invisible to the teacher: never
mention JSON, HTML, schemas, scripts, tool names, rendering, file names, or code
in any teacher-facing message — and never link or name the `.html` files the render command
also writes. Say *"Here's your differentiation plan — the three tier documents are on their
way"*, not *"I've rendered differentiation.json"*. The only format word in your prose is
"Word document". This applies to every
turn, the keeping-posted announcement included: presenting artifacts, the satisfaction
ask, revision summaries, and error messages (if
generation fails, say the documents couldn't be created — not that a script or JSON failed).

Before writing `differentiation.json`, read `references/output.md` in full — it carries
the hard requirements, cross-checks, schema, revision rules, and student-page language
rules. Re-read it before any revision turn.

### 5b. Render all four Word documents — one command, same turn

```bash
bash scripts/render_all.sh differentiation.json "$OUTPUT_DIR"
```

This writes `$OUTPUT_DIR/teacher_plan.docx`, `$OUTPUT_DIR/worksheet_group_a.docx`,
`$OUTPUT_DIR/worksheet_group_b.docx`, and `$OUTPUT_DIR/worksheet_group_c.docx` in one invocation,
plus `.html` working files — no copy step needed; leave everything
the script writes in place (later revision turns re-render from the working files). Then list
`$OUTPUT_DIR` and confirm every document has both its `.docx` and `.html`; if either is
missing or tiny, rerun the script. Present all four Word documents to the teacher together —
attach the teacher plan last so it lands on top (chat surfaces stack newest-first). If the script errors, fix
`differentiation.json` (it is almost always malformed JSON) and rerun. If file generation
fails entirely, say so clearly — do not silently fall back to a chat-only delivery.

### 5c. The close (every output turn)

The chat message that delivers artifacts ends with three things, in order. Each must appear in
the chat message itself — saying it only inside the printed plan does not count. When the
message mentions the sheets, use their group names with the association noted once
(Group A = below grade level, etc.).

1. **Learner-variability statement (first output turn, when you didn't ask).** If you never
   asked about specific learner needs in this conversation (the R8 question), state in chat
   that UDL defaults were applied and invite specifics — e.g. *"I didn't have details on
   specific learner needs, so I applied UDL defaults — sentence stems and a vocabulary
   glossary on all three tier sheets. Tell me about any multilingual learners or students
   with IEPs or 504 plans and I'll tailor further."* Skip this only when the teacher already
   gave learner information (then reflect it instead: "the Below sheet builds in the sentence
   frames for your newcomer ELLs").
2. **Three lesson-specific next steps (first output turn).** Offer 3–4 iteration options in
   chat, one short line each, specific to THIS lesson (e.g., a tiered ELD layer with
   WIDA-banded sentence supports; IEP-goal-specific scaffolds for a named goal area; a fourth
   intervention tier below the prerequisite; tightening scope to the exit ticket only). The
   subject reference's FA follow-up prompt must be one of them.
3. **The satisfaction ask.** Ask whether the teacher is satisfied with **all four artifacts**
   or wants changes. Do not skip the ask — on every output turn, including revisions.

## Step 6 — Complete

The skill is complete when the teacher has confirmed they are satisfied with all four Word
documents (5c).$body$),
('marketplace:k12-teacher-skills/k12-teacher-skills/plugin/skills/k12-lesson-plan-creation', 'students', 'k12-lesson-plan-creation', '', 'k12-lesson-plan-creation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:k12-teacher-skills', '', $body$# K-12 Lesson Planning

Produces a teacher-ready, standards-aligned lesson plan + student-facing materials + teacher
observation template as editable Word documents in a single output turn, rendered from one material-source JSON via
bundled scripts. Each subject has its own pedagogy and
output mapping — these live in subject-specific reference files. This skill routes to the
right one. Works with or without the Learning Commons Knowledge Graph.

"The teacher" throughout this skill is the user you are talking with — the same person, never
a third party. "Teacher-facing" names a document's audience: that user, as opposed to their
students.

---

## Keeping the teacher posted

Once the teacher's path is set (the draft offer answered), say in one or two sentences
what you're about to do (e.g. *"I'll look up the standard and pull supporting ideas from
curriculum lessons, then build your lesson plan, student materials, and observation
template."*).

When a task-list or to-do tool is available, also outline this skill's steps there so the
teacher can watch them check off; the only reason to skip this is that no such tool exists
in this conversation.

Teacher language only — name what the teacher is getting, never tool names, file names,
"JSON", or "rendering".

---

## Step 0 — Route (silent, before anything else)

1. **Subject.** Determine the subject of the requested lesson from the prompt and any prior
   conversation:

   - **math** — arithmetic, fractions, geometry, algebra, calculus, statistics, CCSS-M codes, IM (Illustrative Mathematics)
   - **ela** — reading, writing, phonics, literature, comprehension, vocabulary, CCSS-ELA codes (RL/RI/RF/W/L)
   - **science** — phenomena, NGSS Performance Expectations, biology/chemistry/physics/earth science, OpenSciEd
   - **social_studies** — history, civics, geography, economics, C3 inquiry arc, state social-studies standards

   Then read the matching reference file NOW:

   - math → `references/math.md`
   - ELA → `references/ela.md`
   - science → `references/science.md`
   - social studies → `references/social_studies.md`

   **Loading the matching reference file is mandatory.** Drafting a lesson without first
   reading the subject reference is a critical failure. The reference file carries the
   complete subject-specific instructions: clarify priorities, curriculum branching,
   grade-band structures, section structure, non-negotiables, and the lesson.json mapping.
   Treat the loaded reference as your full skill instructions for this turn. If the subject
   is genuinely ambiguous or the prompt spans multiple subjects, ask about it
   in Step 1.

2. **Curriculum.** If the teacher names or implies a curriculum (Illustrative Mathematics,
   OpenSciEd, …), the subject file's curriculum branch covers it — each subject
   file carries its curriculum's structures and language inline (curriculum and subject are
   1:1: IM→math, OpenSciEd→science). If they use a curriculum the subject
   file doesn't cover, follow its "no curriculum named" path and do not fake
   curriculum-specific terminology.
3. **Connector.** Check whether the Learning Commons Knowledge Graph tools (e.g.
   `find_standard_statement`) are available in this conversation. This decides which path
   Step 2 takes. The skill is fully functional without the connector.

---

## Step 1 — Clarify

Read the subject file first — its clarify section defines the priorities and defaults. Ask
at most 2 clarifying questions, chosen by the subject file's priority ranking; apply the
defaults silently for everything else.

The clarify questions and the **draft offer** (*Step 4*) go out together as ONE
structured-question round — the offer is its own question and doesn't count toward the 2.
When nothing needs clarifying, the offer is asked on its own. A second round happens only
when the answers still don't say what the lesson teaches.

---

## Step 2 — Ground in standards

**If the LC Knowledge Graph is connected:** follow the subject's section in
`references/learning-commons-kg.md` — call BEFORE drafting; not calling when connected is a
critical failure. Extract only what each call specifies, then proceed directly to Step 3 — do
not summarize findings in chat.

**If not connected:** draft from best knowledge and add this footer to the lesson plan:
*"Generated without the Learning Commons Knowledge Graph. Standards and misconceptions reflect
general best practice."* Do not invent KG citations or attribute content to curriculum
materials you have not seen.

---

## Step 3 — Build the lesson

Follow the subject file's build section: curriculum branching, grade-band structure, section
structure, and non-negotiables. Respect the **Copyright guardrail** below — never reproduce
curriculum student-facing text verbatim.

---

## Copyright guardrail

Always write original content. KG curriculum materials inform structure, scope, text
selection, phenomenon selection, problem context, and lesson-arc design only — never
reproduce student-facing text, teacher notes, comprehension questions, investigation
prompts, discussion questions, activity narratives, or problem contexts verbatim from KG
curriculum materials.

If the loaded reference identifies a source curriculum (e.g., IM for math, OpenSciEd for science) and the teacher is not curriculum-confirmed for it, never name
that curriculum anywhere in the output or in any chat message — not in headers, footnotes,
rationale sections, facilitation notes, or your message presenting the artifacts. The KG
data informs the design without being cited.

---

## Step 4 — The draft offer

The teacher gets the choice of a fast draft before the build. The offer rides in Step 1's
round (structured question tool when available, chat otherwise), and its two sides are
always the packet and the draft. The wording below lives in the question itself — the
teacher may act on it without reading the chat text around it:

- Question: *Should I build a full classroom-ready packet (lesson plan + student
  materials, as editable Word docs), or do you want to see a quick draft first?*
- Options: **Go ahead and build it** · **Quick draft first** — the lesson at a glance,
  right here in chat

**The full packet is the default.** A reply that selects the draft option or asks to see
the draft gets the draft; every other reply runs Steps 2–3 and goes straight to Step 5.

**The draft (on a yes) is built on Steps 2–3, never instead of them.** Run Step 2 in
full — every KG call, exactly as written — and Step 3 before sketching anything. A draft
sketched without the Step 2 grounding is a critical failure, the same failure as skipping
the KG on the full build. Then present the lesson in chat — the draft is chat text only;
rendering happens at Step 5 once the teacher approves. Show:

- one line naming the grade, topic, and the standard the lesson is anchored to (code plus
  a gist of ten words or fewer);
- a summary of at most 3 sentences (what students do and why it works for this class);
- the sequence as one bullet per phase (name, minutes, one line of what happens);
- the student work at a glance — the actual tasks students will do, enough for the
  teacher to skim and judge coverage;
- what the lesson assumes students already know — the prerequisite skills or key
  vocabulary in play — so the teacher can catch a mismatch with where their class is;
- the exit ticket

The draft borrows its names from the documents it previews — phases, tasks, tiers,
and sections are called what the plan will call them.

Afterwards, ask what's next in plain chat — a typed reply can carry the changes themselves,
which a picked option cannot: *"Want anything different? Tell me here — or tell me to go
ahead and I'll create the materials (lesson plan, student materials, and observation
template, as editable Word docs)."*

Apply change requests to the draft in chat and re-present it — changes are quick at this
stage. Step 5 runs in the turn the teacher gives the go-ahead.

---

## Step 5 — Output (one turn)

Runs immediately when the teacher chose the full packet, or in the turn the draft is
approved.

The artifacts are rendered by bundled scripts from **one material-source `lesson.json`**. The JSON
holds a `shared` block (content registered once) and a `documents[]` array (each document
authored as free-form `sections`). A section's `heading` renders as a large title directly
above its blocks; a block's `label` renders as a bold lead-in on the block itself. A label
that repeats its section's heading prints the same words twice in a row — labels carry what
the heading doesn't (the task's name belongs in one of them, not both). You
compose every page — the lesson plan, the student
materials, the observation template, and any others the lesson needs (e.g. a source packet)
— directly in `documents[]`. Anything that appears on more than one page is registered once
in `shared` under a key you choose and pulled into each document with
`{"type": "from_shared", "key": …}`, so the pages cannot drift apart.

Never write layout code, never re-type lesson content into another format, and never edit a
generated document directly — every change goes into `lesson.json` and is re-rendered
(re-rendering is instant). **Do not open, cat, head, or grep the renderer scripts** — their
behavior is fully specified by the commands and output paths in §5a–5e, and
`references/example_lesson.json` is a filled-in worked example. Reading script source tells
you nothing these instructions don't already state.

**Plain language with the teacher.** The machinery above is invisible to the teacher: never
mention JSON, HTML, schemas, scripts, rendering, file names (`lesson.json`), or code in any
teacher-facing message — and never link or name the `.html` files the render command also
writes. Say *"Here's your lesson plan — the student materials and observation template are on
their way"*, not *"I've rendered lesson.json"*. The only format word in your prose is
"Word document". This
applies to every turn: presenting artifacts, the satisfaction ask, revision summaries, and
error messages (if generation fails, say the documents couldn't be created — not that a
script or JSON failed).

Before writing `lesson.json`, read `references/output.md` in full — it carries the hard
requirements for every document (density, consistency, reading level, integrity) and the
complete `lesson.json` schema and block guide (§5a and §5e live there).

### 5b. Render every Word document — one command, same turn

```bash
bash scripts/render_all.sh lesson.json "$OUTPUT_DIR"
```

This writes one editable `.docx` per `documents[]` entry, named by `id` (e.g.
`$OUTPUT_DIR/lesson_plan.docx`, `student_materials.docx`, `observation_template.docx`,
`source_packet.docx`), plus `.html` and `lesson.json` working files. Render straight into
`$OUTPUT_DIR` and leave everything the script writes in place — later revision turns
re-render from the working files even though the teacher only sees the Word documents. Then list `$OUTPUT_DIR`
and confirm every document has both its `.docx` and `.html`; if either is missing or tiny,
rerun the script. Present the Word documents to the teacher together — attach the lesson plan
last so it lands on top (chat surfaces stack newest-first). If there is no `student_materials`
document, say so plainly ("This lesson is oral, so there's no student handout — students will
work with …"). If the script errors, fix `lesson.json` (it is almost always malformed JSON)
and rerun. If file generation fails entirely, say so clearly — do not silently fall back to a
chat-only delivery.

### 5c. The satisfaction ask + iteration options (every output turn)

End the turn with EXACTLY ONE closing message that does three things, in this order:

1. **If Materials names equipment the classroom has that a paper version can stand in
   for** — coins, blocks, dice, a hundred chart — lead with a bolded offer to print it:
   *"**This lesson uses base-ten blocks — want me to make a printable set in case
   yours are short?**"* Anything whose content this lesson wrote — word cards, a
   source excerpt, a sorting mat with this lesson's categories — already ships with
   the package.
2. Asks whether the teacher is satisfied with **every artifact produced** or wants changes —
   e.g. *"Take a look at the lesson plan, student materials, and observation template — anything
   you'd like me to adjust?"* Do not skip the ask.
3. Offers 3–4 high-leverage, **specific** iteration options customized to the subject and
   topic. Do not write "let me know if you want changes" — that's a non-offer. For example,
   for a 3–5 ELA reading comprehension lesson: *"Would you like to (1) add more scaffolds for
   English learners, (2) differentiate by proficiency level, or (3) adapt to be specific to
   your state standards?"*

### 5d. Revisions — one edit, every artifact stays in sync

Make **targeted edits to `lesson.json`**, then re-render every document (instant). Rules that
keep the artifacts consistent:

- If the change touches content registered in `shared` (a problem, a source, the exit ticket,
  vocabulary, look-fors, the phenomenon/context/numbers), edit it **in `shared`** — every
  document that pulls that key updates automatically.
- **Consistency sweep after any context/number/task change:** after editing `shared`, re-read
  every prose block in every `documents[]` entry and update every sentence that still mentions
  the old context, names, or numbers. When you are done, no document may reference the
  replaced content anywhere — stale prose is the most common consistency failure.
- A change aimed at one document (e.g. "more workspace on the worksheet", "add a column to the
  observation grid") goes in that document's `sections` — never by forking a `shared` key into
  two variants.
- Styling: `theme` fields (`primary`, `title_size`, `body_size`) apply to every artifact.
  Artifacts use minimal color so they print cleanly in black-and-white; do not set
  per-section or per-phase colors.$body$),
('marketplace:k12-teacher-skills/k12-teacher-skills/plugin/skills/k12-lesson-prep', 'students', 'k12-lesson-prep', '', 'k12-lesson-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:k12-teacher-skills', '', $body$# K-12 Lesson Preparation

The goal is for the teacher to internalize what's most important about the key student tasks of the lesson. You are the teacher's teammate in this process. Get the actual lesson and try its key task first; never prep from a guess. Hand the teacher the key task as written and have them try it and name where an almost-right student answer would go wrong; your almost-right student answers and the rest of what you saw come after theirs. Keep the talk on the task's design rather than their students. If the teacher gets something about the content wrong, say so plainly. Lead every turn with the one thing that matters, keep it to a few lines, and ask only questions that the teacher can answer in a sentence or by working one short problem. After the first exchange, make it plain that they can stop whenever they have what they need, and if you offer more, name the one specific thing. Leave a prep note of 200–300 words at $OUTPUT_DIR/prep_note.md that walks the lesson's own parts in teaching order — each part's name as a bold heading, every finding under the part it belongs to — and once it is written, ask whether anything in it should change.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/instrument-data-to-allotrope', 'business', 'instrument-data-to-allotrope', '', 'instrument-data-to-allotrope', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Instrument Data to Allotrope Converter

Convert instrument files into standardized Allotrope Simple Model (ASM) format for LIMS upload, data lakes, or handoff to data engineering teams.

> **Note: This is an Example Skill**
>
> This skill demonstrates how skills can support your data engineering tasks—automating schema transformations, parsing instrument outputs, and generating production-ready code.
>
> **To customize for your organization:**
> - Modify the `references/` files to include your company's specific schemas or ontology mappings
> - Use an MCP server to connect to systems that define your schemas (e.g., your LIMS, data catalog, or schema registry)
> - Extend the `scripts/` to handle proprietary instrument formats or internal data standards
>
> This pattern can be adapted for any data transformation workflow where you need to convert between formats or validate against organizational standards.

## Workflow Overview

1. **Detect instrument type** from file contents (auto-detect or user-specified)
2. **Parse file** using allotropy library (native) or flexible fallback parser
3. **Generate outputs**:
   - ASM JSON (full semantic structure)
   - Flattened CSV (2D tabular format)
   - Python parser code (for data engineer handoff)
4. **Deliver** files with summary and usage instructions

> **When Uncertain:** If you're unsure how to map a field to ASM (e.g., is this raw data or calculated? device setting or environmental condition?), ask the user for clarification. Refer to `references/field_classification_guide.md` for guidance, but when ambiguity remains, confirm with the user rather than guessing.

## Quick Start

```python
# Install requirements first
pip install allotropy pandas openpyxl pdfplumber --break-system-packages

# Core conversion
from allotropy.parser_factory import Vendor
from allotropy.to_allotrope import allotrope_from_file

# Convert with allotropy
asm = allotrope_from_file("instrument_data.csv", Vendor.BECKMAN_VI_CELL_BLU)
```

## Output Format Selection

**ASM JSON (default)** - Full semantic structure with ontology URIs
- Best for: LIMS systems expecting ASM, data lakes, long-term archival
- Validates against Allotrope schemas

**Flattened CSV** - 2D tabular representation
- Best for: Quick analysis, Excel users, systems without JSON support
- Each measurement becomes one row with metadata repeated

**Both** - Generate both formats for maximum flexibility

## Calculated Data Handling

**IMPORTANT:** Separate raw measurements from calculated/derived values.

- **Raw data** → `measurement-document` (direct instrument readings)
- **Calculated data** → `calculated-data-aggregate-document` (derived values)

Calculated values MUST include traceability via `data-source-aggregate-document`:

```json
"calculated-data-aggregate-document": {
  "calculated-data-document": [{
    "calculated-data-identifier": "SAMPLE_B1_DIN_001",
    "calculated-data-name": "DNA integrity number",
    "calculated-result": {"value": 9.5, "unit": "(unitless)"},
    "data-source-aggregate-document": {
      "data-source-document": [{
        "data-source-identifier": "SAMPLE_B1_MEASUREMENT",
        "data-source-feature": "electrophoresis trace"
      }]
    }
  }]
}
```

**Common calculated fields by instrument type:**
| Instrument | Calculated Fields |
|------------|-------------------|
| Cell counter | Viability %, cell density dilution-adjusted values |
| Spectrophotometer | Concentration (from absorbance), 260/280 ratio |
| Plate reader | Concentrations from standard curve, %CV |
| Electrophoresis | DIN/RIN, region concentrations, average sizes |
| qPCR | Relative quantities, fold change |

See `references/field_classification_guide.md` for detailed guidance on raw vs. calculated classification.

## Validation

Always validate ASM output before delivering to the user:

```bash
python scripts/validate_asm.py output.json
python scripts/validate_asm.py output.json --reference known_good.json  # Compare to reference
python scripts/validate_asm.py output.json --strict  # Treat warnings as errors
```

**Validation Rules:**
- Based on Allotrope ASM specification (December 2024)
- Last updated: 2026-01-07
- Source: https://gitlab.com/allotrope-public/asm

**Soft Validation Approach:**
Unknown techniques, units, or sample roles generate **warnings** (not errors) to allow for forward compatibility. If Allotrope adds new values after December 2024, the validator won't block them—it will flag them for manual verification. Use `--strict` mode to treat warnings as errors if you need stricter validation.

**What it checks:**
- Correct technique selection (e.g., multi-analyte profiling vs plate reader)
- Field naming conventions (space-separated, not hyphenated)
- Calculated data has traceability (`data-source-aggregate-document`)
- Unique identifiers exist for measurements and calculated values
- Required metadata present
- Valid units and sample roles (with soft validation for unknown values)

## Supported Instruments

See `references/supported_instruments.md` for complete list. Key instruments:

| Category | Instruments |
|----------|-------------|
| Cell Counting | Vi-CELL BLU, Vi-CELL XR, NucleoCounter |
| Spectrophotometry | NanoDrop One/Eight/8000, Lunatic |
| Plate Readers | SoftMax Pro, EnVision, Gen5, CLARIOstar |
| ELISA | SoftMax Pro, BMG MARS, MSD Workbench |
| qPCR | QuantStudio, Bio-Rad CFX |
| Chromatography | Empower, Chromeleon |

## Detection & Parsing Strategy

### Tier 1: Native allotropy parsing (PREFERRED)
**Always try allotropy first.** Check available vendors directly:

```python
from allotropy.parser_factory import Vendor

# List all supported vendors
for v in Vendor:
    print(f"{v.name}")

# Common vendors:
# AGILENT_TAPESTATION_ANALYSIS  (for TapeStation XML)
# BECKMAN_VI_CELL_BLU
# THERMO_FISHER_NANODROP_EIGHT
# MOLDEV_SOFTMAX_PRO
# APPBIO_QUANTSTUDIO
# ... many more
```

**When the user provides a file, check if allotropy supports it before falling back to manual parsing.** The `scripts/convert_to_asm.py` auto-detection only covers a subset of allotropy vendors.

### Tier 2: Flexible fallback parsing
**Only use if allotropy doesn't support the instrument.** This fallback:
- Does NOT generate `calculated-data-aggregate-document`
- Does NOT include full traceability
- Produces simplified ASM structure

Use flexible parser with:
- Column name fuzzy matching
- Unit extraction from headers
- Metadata extraction from file structure

### Tier 3: PDF extraction
For PDF-only files, extract tables using pdfplumber, then apply Tier 2 parsing.

## Pre-Parsing Checklist

Before writing a custom parser, ALWAYS:

1. **Check if allotropy supports it** - Use native parser if available
2. **Find a reference ASM file** - Check `references/examples/` or ask user
3. **Review instrument-specific guide** - Check `references/instrument_guides/`
4. **Validate against reference** - Run `validate_asm.py --reference <file>`

## Common Mistakes to Avoid

| Mistake | Correct Approach |
|---------|------------------|
| Manifest as object | Use URL string |
| Lowercase detection types | Use "Absorbance" not "absorbance" |
| "emission wavelength setting" | Use "detector wavelength setting" for emission |
| All measurements in one document | Group by well/sample location |
| Missing procedure metadata | Extract ALL device settings per measurement |

## Code Export for Data Engineers

Generate standalone Python scripts that scientists can hand off:

```python
# Export parser code
python scripts/export_parser.py --input "data.csv" --vendor "VI_CELL_BLU" --output "parser_script.py"
```

The exported script:
- Has no external dependencies beyond pandas/allotropy
- Includes inline documentation
- Can run in Jupyter notebooks
- Is production-ready for data pipelines

## File Structure

```
instrument-data-to-allotrope/
├── SKILL.md                          # This file
├── scripts/
│   ├── convert_to_asm.py            # Main conversion script
│   ├── flatten_asm.py               # ASM → 2D CSV conversion
│   ├── export_parser.py             # Generate standalone parser code
│   └── validate_asm.py              # Validate ASM output quality
└── references/
    ├── supported_instruments.md     # Full instrument list with Vendor enums
    ├── asm_schema_overview.md       # ASM structure reference
    ├── field_classification_guide.md # Where to put different field types
    └── flattening_guide.md          # How flattening works
```

## Usage Examples

### Example 1: Vi-CELL BLU file
```
User: "Convert this cell counting data to Allotrope format"
[uploads viCell_Results.xlsx]

Claude:
1. Detects Vi-CELL BLU (95% confidence)
2. Converts using allotropy native parser
3. Outputs:
   - viCell_Results_asm.json (full ASM)
   - viCell_Results_flat.csv (2D format)
   - viCell_parser.py (exportable code)
```

### Example 2: Request for code handoff
```
User: "I need to give our data engineer code to parse NanoDrop files"

Claude:
1. Generates self-contained Python script
2. Includes sample input/output
3. Documents all assumptions
4. Provides Jupyter notebook version
```

### Example 3: LIMS-ready flattened output
```
User: "Convert this ELISA data to a CSV I can upload to our LIMS"

Claude:
1. Parses plate reader data
2. Generates flattened CSV with columns:
   - sample_identifier, well_position, measurement_value, measurement_unit
   - instrument_serial_number, analysis_datetime, assay_type
3. Validates against common LIMS import requirements
```

## Implementation Notes

### Installing allotropy
```bash
pip install allotropy --break-system-packages
```

### Handling parse failures
If allotropy native parsing fails:
1. Log the error for debugging
2. Fall back to flexible parser
3. Report reduced metadata completeness to user
4. Suggest exporting different format from instrument

### ASM Schema Validation
Validate output against Allotrope schemas when available:
```python
import jsonschema
# Schema URLs in references/asm_schema_overview.md
```$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/nextflow-development', 'business', 'nextflow-development', '', 'nextflow-development', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# nf-core Pipeline Deployment

Run nf-core bioinformatics pipelines on local or public sequencing data.

**Target users:** Bench scientists and researchers without specialized bioinformatics training who need to run large-scale omics analyses—differential expression, variant calling, or chromatin accessibility analysis.

## Workflow Checklist

```
- [ ] Step 0: Acquire data (if from GEO/SRA)
- [ ] Step 1: Environment check (MUST pass)
- [ ] Step 2: Select pipeline (confirm with user)
- [ ] Step 3: Run test profile (MUST pass)
- [ ] Step 4: Create samplesheet
- [ ] Step 5: Configure & run (confirm genome with user)
- [ ] Step 6: Verify outputs
```

---

## Step 0: Acquire Data (GEO/SRA Only)

**Skip this step if user has local FASTQ files.**

For public datasets, fetch from GEO/SRA first. See [references/geo-sra-acquisition.md](references/geo-sra-acquisition.md) for the full workflow.

**Quick start:**

```bash
# 1. Get study info
python scripts/sra_geo_fetch.py info GSE110004

# 2. Download (interactive mode)
python scripts/sra_geo_fetch.py download GSE110004 -o ./fastq -i

# 3. Generate samplesheet
python scripts/sra_geo_fetch.py samplesheet GSE110004 --fastq-dir ./fastq -o samplesheet.csv
```

**DECISION POINT:** After fetching study info, confirm with user:
- Which sample subset to download (if multiple data types)
- Suggested genome and pipeline

Then continue to Step 1.

---

## Step 1: Environment Check

**Run first. Pipeline will fail without passing environment.**

```bash
python scripts/check_environment.py
```

All critical checks must pass. If any fail, provide fix instructions:

### Docker issues

| Problem | Fix |
|---------|-----|
| Not installed | Install from https://docs.docker.com/get-docker/ |
| Permission denied | `sudo usermod -aG docker $USER` then re-login |
| Daemon not running | `sudo systemctl start docker` |

### Nextflow issues

| Problem | Fix |
|---------|-----|
| Not installed | `curl -s https://get.nextflow.io \| bash && mv nextflow ~/bin/` |
| Version < 23.04 | `nextflow self-update` |

### Java issues

| Problem | Fix |
|---------|-----|
| Not installed / < 11 | `sudo apt install openjdk-11-jdk` |

**Do not proceed until all checks pass.** For HPC/Singularity, see [references/troubleshooting.md](references/troubleshooting.md).

---

## Step 2: Select Pipeline

**DECISION POINT: Confirm with user before proceeding.**

| Data Type | Pipeline | Version | Goal |
|-----------|----------|---------|------|
| RNA-seq | `rnaseq` | 3.22.2 | Gene expression |
| WGS/WES | `sarek` | 3.7.1 | Variant calling |
| ATAC-seq | `atacseq` | 2.1.2 | Chromatin accessibility |

Auto-detect from data:
```bash
python scripts/detect_data_type.py /path/to/data
```

For pipeline-specific details:
- [references/pipelines/rnaseq.md](references/pipelines/rnaseq.md)
- [references/pipelines/sarek.md](references/pipelines/sarek.md)
- [references/pipelines/atacseq.md](references/pipelines/atacseq.md)

---

## Step 3: Run Test Profile

**Validates environment with small data. MUST pass before real data.**

```bash
nextflow run nf-core/<pipeline> -r <version> -profile test,docker --outdir test_output
```

| Pipeline | Command |
|----------|---------|
| rnaseq | `nextflow run nf-core/rnaseq -r 3.22.2 -profile test,docker --outdir test_rnaseq` |
| sarek | `nextflow run nf-core/sarek -r 3.7.1 -profile test,docker --outdir test_sarek` |
| atacseq | `nextflow run nf-core/atacseq -r 2.1.2 -profile test,docker --outdir test_atacseq` |

Verify:
```bash
ls test_output/multiqc/multiqc_report.html
grep "Pipeline completed successfully" .nextflow.log
```

If test fails, see [references/troubleshooting.md](references/troubleshooting.md).

---

## Step 4: Create Samplesheet

### Generate automatically

```bash
python scripts/generate_samplesheet.py /path/to/data <pipeline> -o samplesheet.csv
```

The script:
- Discovers FASTQ/BAM/CRAM files
- Pairs R1/R2 reads
- Infers sample metadata
- Validates before writing

**For sarek:** Script prompts for tumor/normal status if not auto-detected.

### Validate existing samplesheet

```bash
python scripts/generate_samplesheet.py --validate samplesheet.csv <pipeline>
```

### Samplesheet formats

**rnaseq:**
```csv
sample,fastq_1,fastq_2,strandedness
SAMPLE1,/abs/path/R1.fq.gz,/abs/path/R2.fq.gz,auto
```

**sarek:**
```csv
patient,sample,lane,fastq_1,fastq_2,status
patient1,tumor,L001,/abs/path/tumor_R1.fq.gz,/abs/path/tumor_R2.fq.gz,1
patient1,normal,L001,/abs/path/normal_R1.fq.gz,/abs/path/normal_R2.fq.gz,0
```

**atacseq:**
```csv
sample,fastq_1,fastq_2,replicate
CONTROL,/abs/path/ctrl_R1.fq.gz,/abs/path/ctrl_R2.fq.gz,1
```

---

## Step 5: Configure & Run

### 5a. Check genome availability

```bash
python scripts/manage_genomes.py check <genome>
# If not installed:
python scripts/manage_genomes.py download <genome>
```

Common genomes: GRCh38 (human), GRCh37 (legacy), GRCm39 (mouse), R64-1-1 (yeast), BDGP6 (fly)

### 5b. Decision points

**DECISION POINT: Confirm with user:**

1. **Genome:** Which reference to use
2. **Pipeline-specific options:**
   - **rnaseq:** aligner (star_salmon recommended, hisat2 for low memory)
   - **sarek:** tools (haplotypecaller for germline, mutect2 for somatic)
   - **atacseq:** read_length (50, 75, 100, or 150)

### 5c. Run pipeline

```bash
nextflow run nf-core/<pipeline> \
    -r <version> \
    -profile docker \
    --input samplesheet.csv \
    --outdir results \
    --genome <genome> \
    -resume
```

**Key flags:**
- `-r`: Pin version
- `-profile docker`: Use Docker (or `singularity` for HPC)
- `--genome`: iGenomes key
- `-resume`: Continue from checkpoint

**Resource limits (if needed):**
```bash
--max_cpus 8 --max_memory '32.GB' --max_time '24.h'
```

---

## Step 6: Verify Outputs

### Check completion

```bash
ls results/multiqc/multiqc_report.html
grep "Pipeline completed successfully" .nextflow.log
```

### Key outputs by pipeline

**rnaseq:**
- `results/star_salmon/salmon.merged.gene_counts.tsv` - Gene counts
- `results/star_salmon/salmon.merged.gene_tpm.tsv` - TPM values

**sarek:**
- `results/variant_calling/*/` - VCF files
- `results/preprocessing/recalibrated/` - BAM files

**atacseq:**
- `results/macs2/narrowPeak/` - Peak calls
- `results/bwa/mergedLibrary/bigwig/` - Coverage tracks

---

## Quick Reference

For common exit codes and fixes, see [references/troubleshooting.md](references/troubleshooting.md).

### Resume failed run

```bash
nextflow run nf-core/<pipeline> -resume
```

---

## References

- [references/geo-sra-acquisition.md](references/geo-sra-acquisition.md) - Downloading public GEO/SRA data
- [references/troubleshooting.md](references/troubleshooting.md) - Common issues and fixes
- [references/installation.md](references/installation.md) - Environment setup
- [references/pipelines/rnaseq.md](references/pipelines/rnaseq.md) - RNA-seq pipeline details
- [references/pipelines/sarek.md](references/pipelines/sarek.md) - Variant calling details
- [references/pipelines/atacseq.md](references/pipelines/atacseq.md) - ATAC-seq details

---

## Disclaimer

This skill is provided as a prototype example demonstrating how to integrate nf-core bioinformatics pipelines into Claude Code for automated analysis workflows. The current implementation supports three pipelines (rnaseq, sarek, and atacseq), serving as a foundation that enables the community to expand support to the full set of nf-core pipelines.

It is intended for educational and research purposes and should not be considered production-ready without appropriate validation for your specific use case. Users are responsible for ensuring their computing environment meets pipeline requirements and for verifying analysis results.

Anthropic does not guarantee the accuracy of bioinformatics outputs, and users should follow standard practices for validating computational analyses. This integration is not officially endorsed by or affiliated with the nf-core community.

## Attribution

When publishing results, cite the appropriate pipeline. Citations are available in each nf-core repository's CITATIONS.md file (e.g., https://github.com/nf-core/rnaseq/blob/3.22.2/CITATIONS.md).

## Licenses

- **nf-core pipelines:** MIT License (https://nf-co.re/about)
- **Nextflow:** Apache License, Version 2.0 (https://www.nextflow.io/about-us.html)
- **NCBI SRA Toolkit:** Public Domain (https://github.com/ncbi/sra-tools/blob/master/LICENSE)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/scientific-problem-selection', 'business', 'scientific-problem-selection', '', 'scientific-problem-selection', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Scientific Problem Selection Skills

A conversational framework for systematic scientific problem selection based on Fischbach & Walsh's "Problem choice and decision trees in science and engineering" (Cell, 2024).

## Getting Started

Present users with three entry points:

**1) Pitch an idea for a new project** — to work it up together

**2) Share a problem in a current project** — to troubleshoot together

**3) Ask a strategic question** — to navigate the decision tree together

This conversational entry meets scientists where they are and establishes a collaborative tone.

---

## Option 1: Pitch an Idea

### Initial Prompt
Ask: **"Tell me the short version of your idea (1-2 sentences)."**

### Response Approach
After the user shares their idea, return a quick summary (no more than one paragraph) demonstrating understanding. Note the general area of research and rephrase the idea in a way that highlights its kernel—showing alignment and readiness to dive into details.

### Follow-up Prompt
Then ask for more detail: "Now give me a bit more detail. You might include, however briefly or even say where you are unsure:
1. What exactly you want to do
2. How you currently plan to do it
3. If it works, why will it be a big deal
4. What you think are the major risks"

### Workflow
From there, guide the user through the early stages of problem selection and evaluation:
- **Skill 1: Intuition Pumps** - Refine and strengthen the idea
- **Skill 2: Risk Assessment** - Identify and manage project risks
- **Skill 3: Optimization Function** - Define success metrics
- **Skill 4: Parameter Strategy** - Determine what to fix vs. keep flexible

See `references/01-intuition-pumps.md`, `references/02-risk-assessment.md`, `references/03-optimization-function.md`, and `references/04-parameter-strategy.md` for detailed guidance.

---

## Option 2: Troubleshoot a Problem

### Initial Prompt
Ask: **"Tell me a short version of your problem (1-2 sentences or whatever is easy)."**

### Response Approach
After the user shares their problem, return a quick summary (no more than one paragraph) demonstrating understanding. Note the context of the project where the problem occurred and rephrase the problem—highlighting its core essence—so the user knows the situation is understood. Also raise additional questions that seem important to discuss.

### Follow-up Prompt
Then ask: "Now give me a bit more detail. You might include, however briefly:
1. The overall goal of your project (if we have not talked about it before)
2. What exactly went wrong
3. Your current ideas for fixing it"

### Workflow
From there, guide the user through troubleshooting and decision tree navigation:
- **Skill 5: Decision Tree Navigation** - Plan decision points and navigate between execution and strategic thinking
- **Skill 4: Parameter Strategy** - Fix one parameter at a time, let others float
- **Skill 6: Adversity Response** - Frame problems as opportunities for growth
- **Skill 7: Problem Inversion** - Strategies for navigating around obstacles

Always include workarounds that might be useful whether or not the problem can be fixed easily.

See `references/05-decision-tree.md`, `references/06-adversity-planning.md`, `references/07-problem-inversion.md`, and `references/04-parameter-strategy.md` for detailed guidance.

---

## Option 3: Ask a Strategic Question

### Initial Prompt
Ask: **"Tell me the short version of your question (1-2 sentences)."**

### Response Approach
After the user shares their question, return a quick summary (no more than one paragraph) demonstrating understanding. Note the broader context and rephrase the question—highlighting its crux—to confirm alignment with their thinking.

### Follow-up Prompt
Then ask: "Now give me a bit more detail. You might include, however briefly:
1. The setting (i.e., is this about a current or future project)
2. A bit more detail about what you're thinking"

### Workflow
From there, draw on the specific modules from the problem choice framework most appropriate to the question:
- **Skills 1-4** for future project planning (ideation, risk, optimization, parameters)
- **Skills 5-7** for current project navigation (decision trees, adversity, inversion)
- **Skill 8** for communication and synthesis
- **Skill 9** for comprehensive workflow orchestration

See the complete reference materials in the `references/` folder.

---

## Core Framework Concepts

### The Central Insight
**Problem Choice >> Execution Quality**

Even brilliant execution of a mediocre problem yields incremental impact. Good execution of an important problem yields substantial impact.

### The Time Paradox
Scientists typically spend:
- **Days** choosing a problem
- **Years** solving it

This imbalance limits impact. These skills help invest more time choosing wisely.

### Evaluation Axes
**For Evaluating Ideas:**
- **X-axis:** Likelihood of success
- **Y-axis:** Impact if successful

Skills help move ideas rightward (more feasible) and upward (more impactful).

### The Risk Paradox
- Don't avoid risk—befriend it
- No risk = incremental work
- But: Multiple miracles = avoid or refine
- **Balance:** Understood, quantified, manageable risk

### The Parameter Paradox
- Too many fixed = brittleness
- Too few fixed = paralysis
- **Sweet spot:** Fix ONE meaningful constraint

### The Adversity Principle
- Crises are inevitable (don't be surprised)
- Crises are opportune (don't waste them)
- **Strategy:** Fix problem AND upgrade project simultaneously

---

## The 9 Skills Overview

| Skill | Purpose | Output | Time |
|-------|---------|--------|------|
| 1. Intuition Pumps | Generate high-quality research ideas | Problem Ideation Document | ~1 week |
| 2. Risk Assessment | Identify and manage project risks | Risk Assessment Matrix | 3-5 days |
| 3. Optimization Function | Define success metrics | Impact Assessment Document | 2-3 days |
| 4. Parameter Strategy | Decide what to fix vs. keep flexible | Parameter Strategy Document | 2-3 days |
| 5. Decision Tree Navigation | Plan decision points and altitude dance | Decision Tree Map | 2 days |
| 6. Adversity Response | Prepare for crises as opportunities | Adversity Playbook | 2 days |
| 7. Problem Inversion | Navigate around obstacles | Problem Inversion Analysis | 1 day |
| 8. Integration & Synthesis | Synthesize into coherent plan | Project Communication Package | 3-5 days |
| 9. Meta-Framework | Orchestrate complete workflow | Complete Project Package | 1-6 weeks |

---

## Skill Workflow

```
SKILL 1: Intuition Pumps
         | (generates idea)
         v
SKILL 2: Risk Assessment
         | (evaluates feasibility)
         v
SKILL 3: Optimization Function
         | (defines success metrics)
         v
SKILL 4: Parameter Strategy
         | (determines flexibility)
         v
SKILL 5: Decision Tree
         | (plans execution and evaluation)
         v
SKILL 6: Adversity Planning
         | (prepares for failure modes)
         v
SKILL 7: Problem Inversion
         | (provides pivot strategies)
         v
SKILL 8: Integration & Communication
         | (synthesizes into coherent plan)
         v
SKILL 9: Meta-Skill
         (orchestrates complete workflow)
```

---

## Key Design Principles

1. **Conversational Entry** - Meet users where they are with three clear starting points
2. **Thoughtful Interaction** - Ask clarifying questions; low confidence prompts additional input
3. **Literature Integration** - Use PubMed searches at strategic points for validation
4. **Concrete Outputs** - Every skill produces tangible 1-2 page documents
5. **Building Specificity** - Progressive detail emerges through targeted questions
6. **Flexibility** - Skills work independently, sequentially, or iteratively
7. **Scientific Rigor** - Claims about generality and feasibility should be evidence-based

---

## Who Should Use These Skills

### Graduate Students (Primary Audience)
- **When:** Choosing thesis projects, qualifying exams, committee meetings
- **Focus:** Skills 1-3 (ideation, risk, impact) + Skill 9 (complete workflow)
- **Timeline:** 2-4 weeks for comprehensive planning

### Postdocs
- **When:** Starting new position, planning independent projects, fellowship applications
- **Focus:** All skills, emphasizing independence and risk management
- **Timeline:** 1-2 weeks intensive planning

### Principal Investigators
- **When:** New lab, new direction, mentoring trainees, grant cycles
- **Focus:** Skills 1, 3, 4, 6 (ideation, impact, parameters, adversity)
- **Timeline:** Ongoing, integrate into lab culture

### Startup Founders
- **When:** Company inception, pivot decisions, investor pitches
- **Focus:** Skills 1-4 (ideation through parameters) + Skill 8 (communication)
- **Timeline:** 1-2 weeks for initial planning, revisit quarterly

---

## Reference Materials

Detailed skill documentation is available in the `references/` folder:

| File | Content | Search Patterns |
|------|---------|-----------------|
| `01-intuition-pumps.md` | Generate research ideas | `Intuition Pump #`, `Trap #`, `Phase [0-9]` |
| `02-risk-assessment.md` | Risk identification | `Risk.*1-5`, `go/no-go`, `assumption` |
| `03-optimization-function.md` | Success metrics | `Generality.*Learning`, `optimization`, `impact` |
| `04-parameter-strategy.md` | Parameter fixation | `fixed.*float`, `constraint`, `parameter` |
| `05-decision-tree.md` | Decision tree navigation | `altitude`, `Level [0-9]`, `decision` |
| `06-adversity-planning.md` | Adversity response | `adversity`, `crisis`, `ensemble` |
| `07-problem-inversion.md` | Problem inversion strategies | `Strategy [0-9]`, `inversion`, `goal` |
| `08-integration-synthesis.md` | Integration and synthesis | `narrative`, `communication`, `story` |
| `09-meta-framework.md` | Complete workflow | `Phase`, `workflow`, `orchestrat` |

---

## Expected Outcomes

### Immediate (After Completing Workflow)
- Clear project vision
- Honest risk assessment
- Contingency plans
- Communication materials ready
- Confidence in problem choice

### 6-Month
- Faster decisions (have framework)
- Productive adversity handling
- No existential crises (risks mitigated)

### 2-Year
- Published results or strong progress
- Avoided dead-end projects
- Career aligned with goals
- **Time well-spent** (ultimate measure)

---

## Foundational Reference

**Fischbach, M.A., & Walsh, C.T. (2024).** "Problem choice and decision trees in science and engineering." *Cell*, 187, 1828-1833.

Based on course BIOE 395 taught at Stanford University.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/scvi-tools', 'business', 'scvi-tools', '', 'scvi-tools', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# scvi-tools Deep Learning Skill

This skill provides guidance for deep learning-based single-cell analysis using scvi-tools, the leading framework for probabilistic models in single-cell genomics.

## How to Use This Skill

1. Identify the appropriate workflow from the model/workflow tables below
2. Read the corresponding reference file for detailed steps and code
3. Use scripts in `scripts/` to avoid rewriting common code
4. For installation or GPU issues, consult `references/environment_setup.md`
5. For debugging, consult `references/troubleshooting.md`

## When to Use This Skill

- When scvi-tools, scVI, scANVI, or related models are mentioned
- When deep learning-based batch correction or integration is needed
- When working with multi-modal data (CITE-seq, multiome)
- When reference mapping or label transfer is required
- When analyzing ATAC-seq or spatial transcriptomics data
- When learning latent representations of single-cell data

## Model Selection Guide

| Data Type | Model | Primary Use Case |
|-----------|-------|------------------|
| scRNA-seq | **scVI** | Unsupervised integration, DE, imputation |
| scRNA-seq + labels | **scANVI** | Label transfer, semi-supervised integration |
| CITE-seq (RNA+protein) | **totalVI** | Multi-modal integration, protein denoising |
| scATAC-seq | **PeakVI** | Chromatin accessibility analysis |
| Multiome (RNA+ATAC) | **MultiVI** | Joint modality analysis |
| Spatial + scRNA reference | **DestVI** | Cell type deconvolution |
| RNA velocity | **veloVI** | Transcriptional dynamics |
| Cross-technology | **sysVI** | System-level batch correction |

## Workflow Reference Files

| Workflow | Reference File | Description |
|----------|---------------|-------------|
| Environment Setup | `references/environment_setup.md` | Installation, GPU, version info |
| Data Preparation | `references/data_preparation.md` | Formatting data for any model |
| scRNA Integration | `references/scrna_integration.md` | scVI/scANVI batch correction |
| ATAC-seq Analysis | `references/atac_peakvi.md` | PeakVI for accessibility |
| CITE-seq Analysis | `references/citeseq_totalvi.md` | totalVI for protein+RNA |
| Multiome Analysis | `references/multiome_multivi.md` | MultiVI for RNA+ATAC |
| Spatial Deconvolution | `references/spatial_deconvolution.md` | DestVI spatial analysis |
| Label Transfer | `references/label_transfer.md` | scANVI reference mapping |
| scArches Mapping | `references/scarches_mapping.md` | Query-to-reference mapping |
| Batch Correction | `references/batch_correction_sysvi.md` | Advanced batch methods |
| RNA Velocity | `references/rna_velocity_velovi.md` | veloVI dynamics |
| Troubleshooting | `references/troubleshooting.md` | Common issues and solutions |

## CLI Scripts

Modular scripts for common workflows. Chain together or modify as needed.

### Pipeline Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `prepare_data.py` | QC, filter, HVG selection | `python scripts/prepare_data.py raw.h5ad prepared.h5ad --batch-key batch` |
| `train_model.py` | Train any scvi-tools model | `python scripts/train_model.py prepared.h5ad results/ --model scvi` |
| `cluster_embed.py` | Neighbors, UMAP, Leiden | `python scripts/cluster_embed.py adata.h5ad results/` |
| `differential_expression.py` | DE analysis | `python scripts/differential_expression.py model/ adata.h5ad de.csv --groupby leiden` |
| `transfer_labels.py` | Label transfer with scANVI | `python scripts/transfer_labels.py ref_model/ query.h5ad results/` |
| `integrate_datasets.py` | Multi-dataset integration | `python scripts/integrate_datasets.py results/ data1.h5ad data2.h5ad` |
| `validate_adata.py` | Check data compatibility | `python scripts/validate_adata.py data.h5ad --batch-key batch` |

### Example Workflow

```bash
# 1. Validate input data
python scripts/validate_adata.py raw.h5ad --batch-key batch --suggest

# 2. Prepare data (QC, HVG selection)
python scripts/prepare_data.py raw.h5ad prepared.h5ad --batch-key batch --n-hvgs 2000

# 3. Train model
python scripts/train_model.py prepared.h5ad results/ --model scvi --batch-key batch

# 4. Cluster and visualize
python scripts/cluster_embed.py results/adata_trained.h5ad results/ --resolution 0.8

# 5. Differential expression
python scripts/differential_expression.py results/model results/adata_clustered.h5ad results/de.csv --groupby leiden
```

### Python Utilities

The `scripts/model_utils.py` provides importable functions for custom workflows:

| Function | Purpose |
|----------|---------|
| `prepare_adata()` | Data preparation (QC, HVG, layer setup) |
| `train_scvi()` | Train scVI or scANVI |
| `evaluate_integration()` | Compute integration metrics |
| `get_marker_genes()` | Extract DE markers |
| `save_results()` | Save model, data, plots |
| `auto_select_model()` | Suggest best model |
| `quick_clustering()` | Neighbors + UMAP + Leiden |

## Critical Requirements

1. **Raw counts required**: scvi-tools models require integer count data
   ```python
   adata.layers["counts"] = adata.X.copy()  # Before normalization
   scvi.model.SCVI.setup_anndata(adata, layer="counts")
   ```

2. **HVG selection**: Use 2000-4000 highly variable genes
   ```python
   sc.pp.highly_variable_genes(adata, n_top_genes=2000, batch_key="batch", layer="counts", flavor="seurat_v3")
   adata = adata[:, adata.var['highly_variable']].copy()
   ```

3. **Batch information**: Specify batch_key for integration
   ```python
   scvi.model.SCVI.setup_anndata(adata, layer="counts", batch_key="batch")
   ```

## Quick Decision Tree

```
Need to integrate scRNA-seq data?
├── Have cell type labels? → scANVI (references/label_transfer.md)
└── No labels? → scVI (references/scrna_integration.md)

Have multi-modal data?
├── CITE-seq (RNA + protein)? → totalVI (references/citeseq_totalvi.md)
├── Multiome (RNA + ATAC)? → MultiVI (references/multiome_multivi.md)
└── scATAC-seq only? → PeakVI (references/atac_peakvi.md)

Have spatial data?
└── Need cell type deconvolution? → DestVI (references/spatial_deconvolution.md)

Have pre-trained reference model?
└── Map query to reference? → scArches (references/scarches_mapping.md)

Need RNA velocity?
└── veloVI (references/rna_velocity_velovi.md)

Strong cross-technology batch effects?
└── sysVI (references/batch_correction_sysvi.md)
```

## Key Resources

- [scvi-tools Documentation](https://docs.scvi-tools.org/)
- [scvi-tools Tutorials](https://docs.scvi-tools.org/en/stable/tutorials/index.html)
- [Model Hub](https://huggingface.co/scvi-tools)
- [GitHub Issues](https://github.com/scverse/scvi-tools/issues)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/single-cell-rna-qc', 'business', 'single-cell-rna-qc', '', 'single-cell-rna-qc', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Single-Cell RNA-seq Quality Control

Automated QC workflow for single-cell RNA-seq data following scverse best practices.

## When to Use This Skill

Use when users:
- Request quality control or QC on single-cell RNA-seq data
- Want to filter low-quality cells or assess data quality
- Need QC visualizations or metrics
- Ask to follow scverse/scanpy best practices
- Request MAD-based filtering or outlier detection

**Supported input formats:**
- `.h5ad` files (AnnData format from scanpy/Python workflows)
- `.h5` files (10X Genomics Cell Ranger output)

**Default recommendation**: Use Approach 1 (complete pipeline) unless the user has specific custom requirements or explicitly requests non-standard filtering logic.

## Approach 1: Complete QC Pipeline (Recommended for Standard Workflows)

For standard QC following scverse best practices, use the convenience script `scripts/qc_analysis.py`:

```bash
python3 scripts/qc_analysis.py input.h5ad
# or for 10X Genomics .h5 files:
python3 scripts/qc_analysis.py raw_feature_bc_matrix.h5
```

The script automatically detects the file format and loads it appropriately.

**When to use this approach:**
- Standard QC workflow with adjustable thresholds (all cells filtered the same way)
- Batch processing multiple datasets
- Quick exploratory analysis
- User wants the "just works" solution

**Requirements:** anndata, scanpy, scipy, matplotlib, seaborn, numpy

**Parameters:**

Customize filtering thresholds and gene patterns using command-line parameters:
- `--output-dir` - Output directory
- `--mad-counts`, `--mad-genes`, `--mad-mt` - MAD thresholds for counts/genes/MT%
- `--mt-threshold` - Hard mitochondrial % cutoff
- `--min-cells` - Gene filtering threshold
- `--mt-pattern`, `--ribo-pattern`, `--hb-pattern` - Gene name patterns for different species

Use `--help` to see current default values.

**Outputs:**

All files are saved to `<input_basename>_qc_results/` directory by default (or to the directory specified by `--output-dir`):
- `qc_metrics_before_filtering.png` - Pre-filtering visualizations
- `qc_filtering_thresholds.png` - MAD-based threshold overlays
- `qc_metrics_after_filtering.png` - Post-filtering quality metrics
- `<input_basename>_filtered.h5ad` - Clean, filtered dataset ready for downstream analysis
- `<input_basename>_with_qc.h5ad` - Original data with QC annotations preserved

If copying outputs for user access, copy individual files (not the entire directory) so users can preview them directly.

### Workflow Steps

The script performs the following steps:

1. **Calculate QC metrics** - Count depth, gene detection, mitochondrial/ribosomal/hemoglobin content
2. **Apply MAD-based filtering** - Permissive outlier detection using MAD thresholds for counts/genes/MT%
3. **Filter genes** - Remove genes detected in few cells
4. **Generate visualizations** - Comprehensive before/after plots with threshold overlays

## Approach 2: Modular Building Blocks (For Custom Workflows)

For custom analysis workflows or non-standard requirements, use the modular utility functions from `scripts/qc_core.py` and `scripts/qc_plotting.py`:

```python
# Run from scripts/ directory, or add scripts/ to sys.path if needed
import anndata as ad
from qc_core import calculate_qc_metrics, detect_outliers_mad, filter_cells
from qc_plotting import plot_qc_distributions  # Only if visualization needed

adata = ad.read_h5ad('input.h5ad')
calculate_qc_metrics(adata, inplace=True)
# ... custom analysis logic here
```

**When to use this approach:**
- Different workflow needed (skip steps, change order, apply different thresholds to subsets)
- Conditional logic (e.g., filter neurons differently than other cells)
- Partial execution (only metrics/visualization, no filtering)
- Integration with other analysis steps in a larger pipeline
- Custom filtering criteria beyond what command-line params support

**Available utility functions:**

From `qc_core.py` (core QC operations):
- `calculate_qc_metrics(adata, mt_pattern, ribo_pattern, hb_pattern, inplace=True)` - Calculate QC metrics and annotate adata
- `detect_outliers_mad(adata, metric, n_mads, verbose=True)` - MAD-based outlier detection, returns boolean mask
- `apply_hard_threshold(adata, metric, threshold, operator='>', verbose=True)` - Apply hard cutoffs, returns boolean mask
- `filter_cells(adata, mask, inplace=False)` - Apply boolean mask to filter cells
- `filter_genes(adata, min_cells=20, min_counts=None, inplace=True)` - Filter genes by detection
- `print_qc_summary(adata, label='')` - Print summary statistics

From `qc_plotting.py` (visualization):
- `plot_qc_distributions(adata, output_path, title)` - Generate comprehensive QC plots
- `plot_filtering_thresholds(adata, outlier_masks, thresholds, output_path)` - Visualize filtering thresholds
- `plot_qc_after_filtering(adata, output_path)` - Generate post-filtering plots

**Example custom workflows:**

**Example 1: Only calculate metrics and visualize, don't filter yet**
```python
adata = ad.read_h5ad('input.h5ad')
calculate_qc_metrics(adata, inplace=True)
plot_qc_distributions(adata, 'qc_before.png', title='Initial QC')
print_qc_summary(adata, label='Before filtering')
```

**Example 2: Apply only MT% filtering, keep other metrics permissive**
```python
adata = ad.read_h5ad('input.h5ad')
calculate_qc_metrics(adata, inplace=True)

# Only filter high MT% cells
high_mt = apply_hard_threshold(adata, 'pct_counts_mt', 10, operator='>')
adata_filtered = filter_cells(adata, ~high_mt)
adata_filtered.write('filtered.h5ad')
```

**Example 3: Different thresholds for different subsets**
```python
adata = ad.read_h5ad('input.h5ad')
calculate_qc_metrics(adata, inplace=True)

# Apply type-specific QC (assumes cell_type metadata exists)
neurons = adata.obs['cell_type'] == 'neuron'
other_cells = ~neurons

# Neurons tolerate higher MT%, other cells use stricter threshold
neuron_qc = apply_hard_threshold(adata[neurons], 'pct_counts_mt', 15, operator='>')
other_qc = apply_hard_threshold(adata[other_cells], 'pct_counts_mt', 8, operator='>')
```

## Best Practices

1. **Be permissive with filtering** - Default thresholds intentionally retain most cells to avoid losing rare populations
2. **Inspect visualizations** - Always review before/after plots to ensure filtering makes biological sense
3. **Consider dataset-specific factors** - Some tissues naturally have higher mitochondrial content (e.g., neurons, cardiomyocytes)
4. **Check gene annotations** - Mitochondrial gene prefixes vary by species (mt- for mouse, MT- for human)
5. **Iterate if needed** - QC parameters may need adjustment based on the specific experiment or tissue type

## Reference Materials

For detailed QC methodology, parameter rationale, and troubleshooting guidance, see `references/scverse_qc_guidelines.md`. This reference provides:
- Detailed explanations of each QC metric and why it matters
- Rationale for MAD-based thresholds and why they're better than fixed cutoffs
- Guidelines for interpreting QC visualizations (histograms, violin plots, scatter plots)
- Species-specific considerations for gene annotations
- When and how to adjust filtering parameters
- Advanced QC considerations (ambient RNA correction, doublet detection)

Load this reference when users need deeper understanding of the methodology or when troubleshooting QC issues.

## Next Steps After QC

Typical downstream analysis steps:
- Ambient RNA correction (SoupX, CellBender)
- Doublet detection (scDblFinder)
- Normalization (log-normalize, scran)
- Feature selection and dimensionality reduction
- Clustering and cell type annotation$body$)
ON CONFLICT (skill_key) DO NOTHING;
