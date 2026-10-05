INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/policy-monitor', 'legal', 'policy-monitor', '', 'policy-monitor', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /policy-monitor

**Sweep mode** (no argument or `--sweep`):
1. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → outputs folder path, policy document, last sweep date.
2. Run the workflow below. Scan outputs folder for files since last sweep.
3. For each output: extract approved practices → diff against current policy commitments.
4. Classify gaps: REQUIRED (policy misrepresents current practice) vs ADVISABLE (policy silent).
5. For each gap: quote current policy, describe gap, draft suggested language.
6. Update Last policy sweep date in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`.

**Direct query mode** (with description argument):
1. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → current policy commitments + actual policy document.
2. Parse proposed practice. Diff against policy: data categories, purposes, third parties, retention, user rights, disclosure.
3. Output: covered / missing / conflicting + suggested language for each gap + timing recommendation.

**Schedule:** Set up a recurring reminder in your own scheduler (calendar, task manager, or CI) to run `/privacy-legal:policy-monitor` weekly. Scheduled execution requires a scheduled-tasks integration, which is not bundled with this plugin.

```
/privacy-legal:policy-monitor
/privacy-legal:policy-monitor "We want to start using behavioral data to personalize onboarding emails"
```

---

# Privacy Policy Monitor

## Purpose

Privacy policies drift from practice in one direction: practice moves forward,
policy stays behind. A PIA approves a new data category. A DPA is signed with a
subprocessor not listed anywhere. A triage result marks a new use case conditional
with a disclosure requirement that the policy doesn't yet make. Months later,
someone reads the policy and it doesn't reflect what actually happens.

This skill catches the drift before it becomes a problem — either by crawling the
outputs folder weekly, or by answering the direct question: "we're about to start
doing X, what does that mean for the policy?"

The output is always the same: here's the gap, here's the suggested language.

---

## Load current state

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`:
- `## Who we are` → `## Regulatory footprint` — the regimes in scope (GDPR, CCPA / CPRA / other state consumer privacy, GLBA, HIPAA, FERPA, COPPA, VPPA, CPNI, etc.)
- `## Privacy policy commitments` — the commitments extracted from the published policy
- `## Outputs` — outputs folder path, policy document location, last sweep date

If `## Outputs` contains `[PLACEHOLDER]`:
> "Outputs aren't configured yet. I can still run a direct-query check — describe
> what you're planning to do and I'll diff it against your current policy. To enable
> the crawl sweep, run `/privacy-legal:cold-start-interview` and provide the outputs
> folder path."

Read the actual privacy policy document from the path in `## Outputs` → **Privacy
policy document**. The commitments in the config CLAUDE.md are a summary; the actual document
is authoritative for suggesting edits.

### Privacy commitments live on multiple surfaces — sweep all of them

The website privacy policy is one surface. Modern privacy programs make binding commitments in at least four more places that regulators actively scrutinize for inconsistencies:

1. **Cookie consent banners / CMPs.** The consent management platform promises specific cookie categories and purposes. If the privacy policy says "we use analytics cookies" and the CMP offers "strictly necessary only," there's a conflict. EU DPAs and the FTC have both enforced against CMP misconfigurations.
2. **App store privacy labels.** Apple App Privacy (the "nutrition label") and Google Data Safety are self-declared and FTC-enforceable. A company that updates its privacy policy but doesn't update its App Store label has a material, regulator-visible inconsistency. Check: when was the label last updated? Does it match the current policy's data categories, purposes, and sharing?
3. **In-product consent flows.** The actual screens where users make data-use choices (onboarding consents, settings toggles, "we've updated our policy" dialogs). The policy says what you do; the consent flow says what the user agreed to. They should match.
4. **Sector-specific notices.** GLBA privacy notices, HIPAA NPPs, FERPA directory notices, COPPA direct notices. These have their own update obligations and their own consistency requirements with the general privacy policy. (Detail below under "Sectoral notices.")

**Add fields to the practice profile for each surface's location and last-updated date.** The sweep checks each against the current policy and flags divergence: "Privacy policy updated [date]. App Store label last updated [earlier date] — may not reflect the new data category. CMP last configured [date] — verify cookie purposes match the policy."

A company with a clean privacy policy and a stale App Store label is a company with an FTC complaint waiting to happen. Sweep the surfaces, not just the document.

### Sectoral notices are in scope for this sweep

The website privacy policy is one notice. Federally-regulated practices require a separate, sector-specific notice that the website policy does not substitute for. If `## Regulatory footprint` includes any of the following, the sweep diffs practice against that notice in addition to the website policy — or flags its absence if no such notice has been configured:

| Footprint entry | Sectoral notice to diff against | What to flag |
|---|---|---|
| **GLBA / Reg P** (financial institution handling NPI) | GLBA initial + annual privacy notice (12 C.F.R. Part 1016, or the functional regulator's equivalent) | Outputs implying new NPI categories, sharing with non-affiliated third parties, or changes to opt-out mechanics that the Reg P notice doesn't reflect. A DPA signed with an analytics vendor receiving NPI with no matching Reg P notice update is a gap. |
| **HIPAA** (covered entity or BA) | Notice of Privacy Practices (45 C.F.R. § 164.520) | Outputs implying new uses or disclosures, new routine categories, or changes to patient-rights mechanics. A BAA signed with a new subcontractor flowing PHI with no matching NPP refresh is a gap. |
| **FERPA** (school or school service provider) | Annual directory-information / rights notice (34 C.F.R. § 99.37) | Outputs implying new disclosure categories to service providers under the school-official exception, new directory-information elements, or changes that implicate parental-consent flow-through. |
| **COPPA** (operator of service directed to children <13) | Direct notice to parents + online notice (16 C.F.R. § 312.4) | Outputs implying new data categories collected from children, new third-party disclosures, or changes to the verifiable-parental-consent mechanic. |
| **VPPA / CPNI / DPPA / other sectoral** | The regime's specific notice or consent regime | Processing activities the regime restricts that aren't reflected in the configured notice. |

**If no sectoral notice is configured for a regime in the footprint**, surface this as a standing gap on every sweep, not a one-time finding. The sweep output should include:

> **Sectoral notice coverage:**
> - [regime]: [configured notice path + last updated, or "NOT CONFIGURED — flag each sweep until resolved"]

**If the sweep cannot locate the sectoral notice**, say so explicitly — do not silently default to diffing only against the website policy. A fintech DPO relying on a policy-monitor sweep that ignored GLBA would ship with an outdated regulator-facing notice and no warning. Surface the gap loudly.

**Ask the user if the footprint is ambiguous.** If `## Regulatory footprint` says "GDPR / CCPA" but the outputs scan surfaces PHI, NPI, or student data categories, surface the footprint-vs-practice mismatch before proceeding: "Your footprint doesn't list [GLBA / HIPAA / FERPA / COPPA] but this sweep is looking at outputs that involve [category]. Should this regime be added to the footprint, and is there a sectoral notice to diff against?"

---

## Mode detection

**Sweep mode:** No argument, `--sweep`, or triggered by schedule.
→ Scan the outputs folder. Diff all outputs since last sweep against current policy.

**Direct query mode:** User provides a description of a proposed new practice.
→ Diff that practice against current policy. Suggest updates.

---

## Mode 1: Sweep

### Determine scope

Read `## Outputs` → **Last policy sweep** date. Scan for output files in the
outputs folder that are dated after that date. If no date is recorded, scan all
files and note: "First sweep — scanning all outputs."

If the outputs folder is empty or has no new files since the last sweep:
> "No new outputs since [last sweep date]. Policy appears current with recent
> practice. Next scheduled sweep: [date]."

Update **Last policy sweep** in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` to today's date after completing the sweep.

### What to read in each output type

**PIAs (Privacy Impact Assessments):**
- Extract: data categories processed, purposes, third parties / subprocessors involved,
  retention periods, user rights implications, any conditions placed on the processing
- Flag: anything in that list not present in the current privacy policy commitments

**DPA reviews (signed or approved):**
- Extract: subprocessors added, data locations agreed to, processing purposes covered,
  any obligations to data subjects created by the DPA terms
- Flag: subprocessors not listed in the policy (if policy names them), new processing
  categories, new data locations, obligations inconsistent with policy

**Triage results (PIA REQUIRED / PROCEED outcomes):**
- Extract: what was approved, any conditions imposed that imply a public commitment
  (e.g., "disclosure to affected parties required before launch")
- Flag: approved practices not covered by policy, conditions that require policy language

**DSAR responses:**
- Extract: any new data categories surfaced that weren't in previous DSAR responses,
  any systems added to the systems list
- Flag: data categories collected but not stated in policy

### Gap identification

For each flagged item, assess:

**REQUIRED update** — the policy makes a commitment that this output contradicts, or
the processing is occurring and the policy has no coverage at all. Not updating creates
a material misrepresentation.

> Example: Policy says "we collect name, email, and payment information." A PIA
> approved collection of location data. Policy says nothing about location. That's
> a REQUIRED update — you're collecting data you haven't disclosed.

**ADVISABLE update** — the policy is silent but not in conflict. The processing is
defensible without updating, but cleaner with it.

> Example: Policy says "we may share data with service providers." A DPA was signed
> with a new analytics vendor. Policy doesn't name the vendor but doesn't exclude
> them either. Advisable to add to a named subprocessor list if one is maintained.

### Sweep output format

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Privacy Policy Monitor — Sweep Report

**Date:** [date]
**Outputs scanned:** [N files] | **New since last sweep:** [N files]
**Gaps found:** [N] REQUIRED | [N] ADVISABLE

---

## REQUIRED updates

### [Gap 1 short name]

**Source:** [filename / output type that triggered this]
**What's happening:** [plain description of the new practice]
**Current policy:** [quote the relevant section — or "No coverage"]
**Gap:** [what's missing or inconsistent]

**Suggested language:**
> *Add to [section name]:*
> "[Drafted policy text — specific, consistent with house style of the actual policy]"

---

[repeat for each REQUIRED gap]

---

## ADVISABLE updates

### [Gap name]

**Source:** [filename]
**What's happening:** [description]
**Current policy:** [quote or "Silent"]
**Suggested language:**
> *Add to / update [section]:*
> "[Drafted text]"

---

## No action needed

[List outputs scanned where no gaps were found — confirms they were reviewed]

---

## Next steps

- [ ] Review REQUIRED updates — each needs a decision before the associated
  feature/processing goes live (or immediately if already live)
- [ ] Review ADVISABLE updates — lower urgency but worth addressing at next
  policy refresh
- [ ] Next scheduled sweep: [date]
```

---

## Mode 2: Direct query

### Parse the proposed practice

Extract from the user's description:
- What data is being collected or processed?
- What's the purpose?
- Who else is involved (vendors, partners, third parties)?
- Who are the data subjects?
- Is there any automated decision-making?
- Any new disclosure to data subjects required?

If the description is vague, ask one clarifying question before proceeding. Don't
run a long intake — this mode should be fast.

### Policy diff

Check the proposed practice against every relevant section of the current policy:

| Check | Current policy says | Proposed practice | Verdict |
|---|---|---|---|
| Data categories | [what policy lists] | [new category if any] | 🟢 Covered / 🟡 Gap / 🔴 Conflict |
| Purposes | [stated purposes] | [new purpose] | |
| Third parties / subprocessors | [stated parties] | [new party if any] | |
| Retention | [retention commitment] | [implied retention] | |
| User rights | [rights offered] | [any new rights implications] | |
| Disclosure / notice | [what policy says about telling users] | [what this practice requires] | |

### Direct query output format

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Privacy Policy Check: [Proposed practice in one line]

**Bottom line:** [POLICY UPDATE REQUIRED / ADVISABLE / NO UPDATE NEEDED]

---

## What's covered

[List aspects of the proposed practice already addressed by the current policy —
brief, confirms they don't need to change]

## What's missing

### [Gap 1]

**Current policy:** [quote or "Silent"]
**What's needed:** [why this gap matters — legal, reputational, or consistency reason]

**Suggested language:**
> *Add to [section]:*
> "[Drafted text]"

### [Gap 2]
[same format]

## What conflicts

### [Conflict 1 — if any]

**Current policy says:** [quote]
**Proposed practice does:** [what conflicts]
**Resolution:** [which one needs to change and why — usually the practice adjusts
to match the policy, or the policy gets updated to a defensible new position]

---

## Timing

[If any gap is REQUIRED: "Policy update should happen before this goes live."
If ADVISABLE: "Can proceed; update at next policy refresh."]
```

---

## Suggested language quality standards

Policy language should:
- Match the voice and style of the existing policy (read the actual document, not
  just the config CLAUDE.md summary, before drafting)
- Be specific enough to be meaningful but not so specific that routine changes
  break it ("service providers who assist us in operating our business" ages better
  than naming every vendor)
- Not make commitments the team can't keep (e.g., don't draft "we will never share
  location data" if the architecture has that data flowing to an analytics vendor)
- Flag where a broader policy position change might be needed, not just a
  sentence addition

When drafting, always say which section to add to. If the right section doesn't
exist, say so and suggest creating it.

---

## Schedule integration

Set up a recurring reminder in your own scheduler (calendar, task manager, or CI)
to run `/privacy-legal:policy-monitor` weekly. Scheduled execution requires a
scheduled-tasks integration, which is not bundled with this plugin.

Whenever the sweep runs, it updates `## Outputs` → **Last policy sweep** in
`~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`, so the next sweep only looks at new files.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

If the sweep surfaced more than ~10 drift findings, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by surface (policy clause / PIA / DPA / triage), counts by severity, and a sortable grid of findings with source artifact and recommended remediation.

## What this skill does not do

- It doesn't update the policy itself — it drafts suggested language and flags
  decisions, but a human reviews and approves every change.
- It doesn't catch regulatory changes — that's `reg-gap-analysis`. This skill
  monitors internal practice drift, not external legal changes.
- It doesn't enforce that outputs are saved — if the team isn't saving PIAs to the
  configured folder, the sweep won't find them. The direct-query mode works without
  saved outputs.
- It doesn't read email or Slack for informal decisions — only structured outputs
  saved to the configured folder.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/reg-gap-analysis', 'legal', 'reg-gap-analysis', '', 'reg-gap-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /reg-gap-analysis

1. Load `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → privacy policy commitments, regulatory footprint, DSAR systems.
2. Run the workflow below.
3. Scope: does the regulation apply? (jurisdiction, thresholds, sector)
4. Extract requirements → diff against current state → gap list.
5. Remediation plan with owners, dates, prioritization.
6. Save dated doc. Even "no gaps" gets documented.

```
/privacy-legal:reg-gap-analysis "Colorado Privacy Act"
```

```
/privacy-legal:reg-gap-analysis
[paste guidance / reg text]
```

---

# Regulation-to-Policy Gap Analysis

## Purpose

A state passes a new privacy law. The ICO issues new guidance. The CPPA finalizes regulations. Something moves — and now you need to know what, if anything, you have to change.

This skill diffs the new requirement against what you currently do (per `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → Privacy policy commitments + the practices documented in PIAs) and produces a gap list with a remediation plan.

## Load current state

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`:
- `## Privacy policy commitments` — what you've publicly promised
- `## Regulatory footprint` — what already applies
- `## DSAR process` → systems list — what you actually do operationally

If the regulation doesn't apply to you (wrong jurisdiction, below threshold, different sector), the gap analysis is one line: "Doesn't apply. Here's why: [reason]. No action needed."

## Workflow

### Step 1: Scope the regulation

Before diffing, answer:

- **Does it apply?** Jurisdiction (do you have data subjects there?), threshold (revenue, user count, data volume), sector carve-outs
- **When?** Effective date, enforcement date (often later), any phase-in
- **What's actually new?** Many "new" state privacy laws are 90% CCPA with tweaks. Identify the delta from what you already comply with, not the full text.

### Step 2: Extract requirements

Read the regulation (or summary/guidance). List every substantive requirement as a discrete item:

| # | Requirement | Citation | Category |
|---|---|---|---|
| 1 | [requirement as stated] | [section] | [Notice / Rights / Security / Vendor / Other] |

**Categories:**
- **Notice** — what you have to tell users (privacy policy content)
- **Rights** — what users can ask for (DSAR-adjacent)
- **Security** — technical/organizational measures
- **Vendor** — what you have to flow down to processors
- **Consent** — opt-in/opt-out mechanics
- **Governance** — DPO, impact assessments, record-keeping

### Step 3: Diff against current state

For each requirement:

```markdown
### [Requirement #N]: [short name]

**Regulation says:** [requirement, quoted or paraphrased]

**We currently:** [what the config CLAUDE.md / privacy policy / practice shows]

**Gap:** [None | Partial | Full]

**If partial/full gap — what's missing:** [specific]

**Effort to close:** [Policy update only | Product change | Vendor renegotiation |
New process]

**Risk of non-compliance:** [regulatory penalty range, enforcement likelihood,
reputational]
```

### Step 4: Prioritize

Not every gap is equal. Sort by:

1. **Hard deadline with teeth** — effective date + active enforcement + real penalties
2. **Effort-to-impact ratio** — policy language update is cheap; product rebuild is not
3. **What you've already half-done** — if you're 80% there for GDPR, the state law delta may be small

### Step 5: Remediation plan

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

> **Research-connector pre-flight.** Before emitting the remediation plan, check whether a legal research connector is reachable for this session — Westlaw, an EUR-Lex / regulator-site connector, or any firm-configured research MCP. Collect this into the reviewer note per CLAUDE.md `## Outputs`: if no connector returns results in Step 2 or the Common regulation categories research step (or none is configured at run time), record it in the **Sources:** line of the reviewer note — e.g., `not connected — cites from training knowledge; the highest-fabrication items in privacy gap analyses are new state-law effective dates, enforcement-begins dates, and article/section pinpoints — spot-check those first`. Per-citation `[model knowledge — verify]` tags remain inline. Do not emit a standalone banner above the output.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

## Remediation Plan: [Regulation name]

**Effective date:** [date]
**Enforcement begins:** [date]

### Must-do before enforcement

| Gap | Fix | Owner | Due | Status |
|---|---|---|---|---|
| [gap] | [specific fix] | [name] | [date] | [ ] |

### Should-do (lower risk, not blocking)

[same table]

### Already compliant

[list of requirements where gap = None — useful for the "we're mostly fine" message]

### Accepted gaps (risk-accepted, not fixing)

[if any — with documented rationale and who accepted the risk]
```

## Common regulation categories

When scoping the delta, it helps to place the new regulation into a rough category and then research the specifics:

- **Baseline data-protection / privacy law** — broad coverage of a jurisdiction's personal data practices
- **Sector-specific overlay** — health, finance, children, education, employment, etc.
- **AI-specific regime** — transparency, impact assessments, or governance for automated decision-making
- **Data broker / ad-tech regime** — registration, opt-out, deletion mechanisms
- **Breach-notification regime** — standalone or embedded in a broader law
- **Cross-border transfer regime** — adequacy, mechanism, and assessment requirements

For each category relevant to the new regulation, **research the currently operative requirements** before drafting the gap analysis. Cite primary sources. Verify currency — new state laws come online each legislative session, and regulators issue interpretive guidance that shifts what "compliance" means for a given control. Flag uncertainty for attorney verification rather than assert a rule you haven't confirmed.

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, regulator databases, or firm platform) returns few or no results for a regulation, guidance document, or enforcement action, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the gap analysis with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 33, CCPA § 1798.100, FTC Act § 5). Still verify before filing, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific implementing regulations, agency guidance, case holdings, thresholds, effective dates, newly enacted state statutes.
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, volume/page numbers, paragraph numbers, regulatory subpart references) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[issuing authority site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

## Integration with other skills

**From PIA generation:** PIAs flag privacy policy inconsistencies → those feed here as known gaps.

**To the regulatory-legal plugin (if installed):** This skill is the manual version. The monitor plugin watches feeds and triggers this analysis automatically when something changes.

## Output

Save as a dated markdown doc. The remediation plan table becomes a tracker — update status as items close.

If the gap analysis concludes "no gaps, we're compliant," still write the doc — it's useful evidence later that you looked.

**Close with a citation-verification note:**

> Citations in this output were generated by an AI model and have not been verified against a primary source. Before relying on any regulation, statute, guidance, or enforcement action, check it against a legal research tool (Westlaw, your firm's research platform, or the issuing authority's website) for accuracy and current status. AI-generated citations are sometimes fabricated or misquoted. Source tags on each citation (e.g., `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't interpret ambiguous regulatory language authoritatively. When the reg is unclear, say so: "Section X could be read as [A] or [B]. [A] is the conservative read. Suggest outside counsel if this is material."
- It doesn't track regulatory changes proactively. It runs when you point it at a change. For proactive monitoring, see the regulatory-legal plugin.
- It doesn't implement fixes. It plans them.$body$),
('marketplace:claude-for-legal/claude-for-legal/privacy-legal/skills/use-case-triage', 'legal', 'use-case-triage', '', 'use-case-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /use-case-triage

1. Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. Confirm privacy practice is configured — if not, stop and direct to setup.
2. Run the workflow below. Clarify the activity if vague.
3. House trigger check → mandatory DPIA check (if GDPR in footprint) → privacy policy conflict check.
4. Output: classification (PROCEED / PIA REQUIRED / DPIA MANDATORY / STOP), reasoning, conditions table if required, cross-plugin handoffs.
5. Offer to continue into PIA generation if assessment is required.

```
/privacy-legal:use-case-triage "New feature that uses behavioral data to personalize content recommendations"
```

---

# Privacy Use Case Triage

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/privacy-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/privacy-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

Answer the question that comes up before anyone runs a PIA: "does this thing even
need one?" And if it does, what kind, and what's blocking the way?

Privacy triage is faster than PIA generation but upstream of it. It doesn't write
the assessment — it determines whether one is needed and on what terms. The PIA
generation skill does the deep work.

The output is one of four classifications:
- **PROCEED** — No PIA needed. Standard safeguards apply.
- **PIA REQUIRED** — Assessment needed before or alongside deployment.
- **DPIA MANDATORY** — A regime-mandated data protection impact assessment is
  required (research the applicable regime's trigger and cite primary sources).
  Harder bar, DPO/GC involvement likely.
- **STOP** — Processing activity conflicts with the privacy policy or has no
  lawful basis as described. Needs redesign before proceeding.

## Jurisdiction assumption

This triage assumes the jurisdictional scope specified in your configuration. Privacy rules, assessment triggers, and lawful bases vary materially by jurisdiction (GDPR vs. state consumer privacy laws vs. sectoral). If the processing activity, controller, or affected data subjects fall under a different jurisdiction, this classification may not apply as written.

## Read the config first

Before triaging, always read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md`. The PIA trigger criteria, regulatory
footprint, and privacy policy commitments there are authoritative. Generic privacy
law reasoning is not a substitute for what this company has actually committed to.

If the file is missing or contains `[PLACEHOLDER]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor the PIA trigger criteria, regulatory footprint, and privacy policy commitments to your practice.
>
> **Two choices:**
> - Run `/privacy-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll triage tailored to YOUR practice.
> - Say **"provisional"** and I'll triage against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run triage normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction (CCPA + common federal sectoral baselines), no playbook (classify from general privacy-law principles rather than matching to configured commitments). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/privacy-legal:cold-start-interview` to get output calibrated to YOUR practice — your regulatory footprint, your privacy policy commitments, your risk appetite. 2 minutes."

---

## Triage process

### Step 1: Understand the activity

If the description is vague, ask before classifying. Get specific on:

- What data is being collected or processed? Which categories?
- Who are the data subjects — customers, employees, third parties?
- What's the purpose? What problem is this solving?
- Is this new data collection, or repurposing data you already have?
- Is a third-party vendor involved? New vendor or existing?
- Is any automated decision-making involved — does the output affect anyone?
- What's the deployment context — internal only, customer-facing, public?

"New feature" and "data processing activity" are not enough to triage accurately.

---

### Step 2: Check house triggers

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## PIA house style` → Trigger criteria. Apply them.

If the house trigger is met → at minimum **PIA REQUIRED**.

If house trigger is not met, continue to Step 3 before concluding PROCEED. Some
activities need a PIA regardless of internal policy.

---

### Step 3: Mandatory assessment check

**Before researching regime-specific triggers, ask the activity-based federal overlay question first.** If the processing touches a federally-regulated data category, the federal overlay is usually the controlling framework, not state privacy law, and the triage needs to surface that early rather than as an afterthought.

> **Activity-based federal overlays — ask first:**
>
> Does this processing touch:
> - **Financial account data or "nonpublic personal information" about consumers** (GLBA / Reg P — applies to financial institutions and their non-affiliated third parties; imposes substantive restrictions on sharing NPI for marketing, separate from and on top of any state privacy-law exemption)?
> - **Protected health information held by a covered entity or business associate** (HIPAA Privacy / Security Rules — substantive restrictions on use and disclosure, breach notification at 500+ records, BAA required for any vendor)?
> - **Education records held by a school or a service provider acting for a school** (FERPA — consent requirements for disclosure, directory-information carve-outs)?
> - **Data from children under 13 collected by an operator of an online service directed to children or with actual knowledge** (COPPA — parental consent, notice, deletion rights, strict limits on retention and sharing)?
> - **Another sectoral federal regime** (e.g., VPPA for video-viewing records, CPNI for carrier data, DPPA for DMV records, TCPA for SMS/call consent)?
>
> If yes to any: the federal overlay usually supplies the controlling substantive restriction, not just an exemption from a state consumer privacy law. Research and cite the specific provision before continuing. An activity that is "exempt" from CCPA under § 1798.145(e) because it is GLBA-covered is still subject to the GLBA restrictions (e.g., § 6802(a)-(c) on NPI sharing) — the CCPA exemption does not make the activity lawful; it just moves the governing framework to GLBA.

For each regime in `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Regulatory footprint`, **research the currently operative mandatory privacy/data-protection assessment triggers**. Cite controlling statute, regulation, or regulator guidance with pinpoint references. Note effective dates — national and state regulators publish and update trigger lists regularly; do not rely on a static checklist. Flag uncertainty for attorney verification rather than guess.

If **any** applicable regime's mandatory trigger is met → **DPIA MANDATORY** (or the equivalent regime-specific mandate), regardless of house trigger.

**Strong indicators (not necessarily mandatory but do one anyway):**
- New technology or novel use of existing technology
- Children's data
- Combining datasets that weren't collected together
- Data that could enable discrimination
- Processing users would not expect
- Lookalike audiences, cross-context behavioral advertising, or other tracking-based ad-tech activity (recurring question for consumer-facing companies; surfaces policy-commitment conflicts and federal sectoral overlays reliably)

One or more strong indicators with no researched mandatory trigger → escalate to **PIA REQUIRED**
(not DPIA mandatory, but flag in the output).

---

### Step 4: Privacy policy conflict check

Read `~/.claude/plugins/config/claude-for-legal/privacy-legal/CLAUDE.md` → `## Privacy policy commitments`. Check the proposed activity
against every stated commitment.

**Common conflicts to catch:**
- Policy says "we collect X, Y, Z" — this activity collects W. Policy update
  needed before launch, or stop collecting W.
- Policy says "we don't sell or share data with third parties" — this activity
  passes data to a vendor for their own purposes. Research whether the flow falls
  within a regulated "sale," "share," or other disclosure category under each
  applicable regime.
- Policy states retention limits — this activity retains data longer.
- Policy says "we use data only for [purpose]" — this activity uses it for a new
  purpose without fresh consent or legitimate interest assessment.
- Policy specifies user rights offered — this activity creates a new data category
  the rights process wasn't built for.

If a direct conflict exists → **STOP**. Not "proceed with caution" — the policy
conflict has to be resolved (policy update or activity redesign) before this
proceeds.

---

### Step 5: Classification and output

---

### Bottom line
[PIA required / Mandatory DPIA required / Proceed — one-sentence why]

---

**ACTIVITY:** [State the processing activity as you understand it]

**CLASSIFICATION:** [PROCEED / PIA REQUIRED / DPIA MANDATORY / STOP]

**House trigger met?** [Yes / No]
**GDPR mandatory DPIA trigger?** [Yes — [trigger] / No / N/A (GDPR not in footprint)]
**Privacy policy conflict?** [None / Yes — [specific conflict]]

**Reasoning:**
[1-3 sentences. For PROCEED: what makes it safe under current policy. For PIA/DPIA:
what creates the obligation. For STOP: which specific policy commitment or principle
is in conflict.]

---

*If PIA REQUIRED or DPIA MANDATORY — conditions before proceeding:*

| Requirement | Owner | Done? |
|---|---|---|
| [e.g., Privacy Impact Assessment — full DPIA format] | [Privacy counsel] | ☐ |
| [e.g., Legitimate interest assessment (if LI basis)] | [Privacy counsel] | ☐ |
| [e.g., DPO consultation (DPIA mandatory track)] | [DPO] | ☐ |
| [e.g., Vendor DPA in place] | [Privacy / Legal] | ☐ |
| [e.g., Privacy policy update before launch] | [Privacy counsel] | ☐ |
| [e.g., Consent mechanism built and tested] | [Product] | ☐ |
| [e.g., Data subject rights process covers new data category] | [Privacy / Product] | ☐ |

**Lawful basis (if GDPR in footprint):** [Consent / Contract / Legitimate Interest /
Legal Obligation — or "unclear — needs determination in PIA"]

**Next step — offer to continue:**

After presenting a PIA REQUIRED or DPIA MANDATORY result, always end with:

> "Want me to start the PIA now? I can run the intake questions and produce the
> assessment document without you needing to run a separate command."

If they say yes, load the `pia-generation` skill and continue in the same
conversation — pass the activity description and any triggers already identified.

If they say no, the triage result stands. The PIA can be run any time with:
`/privacy-legal:pia-generation [activity]`

---

*If STOP:*

**Conflict:** [Specific privacy policy commitment or principle in conflict]

**To proceed, one of these has to change:**
- [Option A — redesign the activity so it doesn't create the conflict]
- [Option B — update the privacy policy to cover this processing (requires review
  of whether the update is itself consistent with lawful basis)]

Don't offer a path forward if there isn't one. If the processing simply can't be
reconciled with stated commitments or lawful basis, say so.

---

### Step 6: Cross-plugin handoffs

**AI governance handoff:** If the activity involves an AI system making or
influencing decisions about individuals:

> "This activity involves AI decision-making. An AI impact assessment is likely
> required in addition to a PIA. Use `/ai-governance-legal:aia-generation [activity]`
> to run that in parallel — they're not substitutes."

**Product counsel handoff:** If this is a new product feature or launch:

> "If this is part of a product launch, loop in product counsel.
> Use `/product-legal:launch-review` — it will detect the privacy component
> and route to this plugin."

Only flag handoffs that are actually relevant. Don't append both as boilerplate.

---

## Batch triage

If the user presents a feature list, roadmap, or backlog — summary table first,
then expand each non-PROCEED entry:

| # | Activity | Classification | Key condition / blocker |
|---|---|---|---|
| 1 | [activity] | 🟢 Proceed | — |
| 2 | [activity] | 🟡 PIA required | Lawful-basis assessment needed; vendor DPA not in place |
| 3 | [activity] | 🟠 DPIA mandatory | Large-scale special category data |
| 4 | [activity] | 🔴 Stop | Privacy policy conflict — purpose limitation |

---

## Edge cases and failure modes

**"It's anonymized" doesn't automatically mean PROCEED.**
Ask how it's anonymized and whether re-identification is realistically possible
given the data set. Pseudonymized data is still personal data under GDPR.

**"We already do something similar" isn't a triage.**
Existing processing that was never assessed doesn't grandfather new processing.
If the new activity is materially different in scale, purpose, or data category,
triage it fresh.

**"Just a pilot" doesn't skip triage.**
A pilot that touches real user or employee data is subject to the same triggers.
Apply the same classification; if a PIA is required, the pilot should have one.

**"The vendor handles all the privacy."**
Vendor handles the infrastructure. You're still the controller determining the
purposes. If personal data flows to the vendor, a DPA is required and triage still
applies to the purpose.

**Inferred data and derived attributes count.**
If the activity generates inferred data about individuals (e.g., a behavioral score,
a predicted preference), treat the inferred attribute as personal data for triage
purposes. Don't let "we're just computing a score" obscure what the score represents.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` state.
2. Run the cold-start interview below.
3. Seed docs: 10 past launch review docs (from tracker or Drive). Read them all.
4. Build risk calibration table from what actually blocked vs. shipped.
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/product-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` (create parent directories as needed). Show calibration table for confirmation.

## `--check-integrations`

Re-runs the integration availability check (launch tracker, document storage, Slack) and updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`. Does not re-interview. Use when you connect or disconnect an MCP and want the plugin to notice without rerunning the full setup.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

```
/product-legal:cold-start-interview
```

```
/product-legal:cold-start-interview --check-integrations
```

---

# Cold-Start Interview: Product Counsel

## Purpose

Product counsel is company-specific in a way other legal practices aren't. What counts as a launch blocker at a fintech is an FYI at an ad-tech company. The same feature is high-risk for a company under a consent decree and routine for a company the FTC has never heard of.

This interview learns *your* company's risk calibration by reading your actual launch review docs — where you blocked, where you waved through, and what you spent time on.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/product-legal/*/CLAUDE.md` but not at the config path, copy it forward.

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

> **`product-legal` is for people who review product launches, marketing claims, and feature risk — the legal side of shipping.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, your review framework level (formal gate vs. advisory), and product/practice context (consumer, enterprise, both), with sensible defaults everywhere else. **15 minutes** adds your risk calibration table (what blocks vs. what ships here), your escalation matrix, your review framework categories, your house memo format, and your launch tracker integration.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

Wait for the user's pick before showing anything else.

<!-- COLLATERAL LINKS: when onboarding collateral exists, prepend a line above the preamble:
     "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL), then come back and run /cold-start-interview." -->

## After the user picks quick or full

Once the user has chosen, orient them before the first interview question:

> "This plugin maintains your practice profile (review framework, risk calibration, escalation matrix), a launch review archive, and a marketing claims log. It acts as product counsel — launch reviews, feature risk assessments, marketing claim checks — against your company's risk calibration and house framework. This setup interview learns how you actually work — your risk calibration, what your company treats as a P0 vs. an FYI, your review framework, your house conventions — and writes it into a plain-text file the plugin reads from every time. Everything you answer can be changed later. Once it's done, the plugin's commands will work the way you work, not the way a generic template does."
>
> Then: "Setup builds a fresh professional profile from your answers. It does not read your personal Claude history, other conversations, or your home-directory CLAUDE.md. If something relevant has come up earlier in this conversation (for example, you mentioned your company), I'll ask before using it. Nothing gets folded into your configuration unless you type it or approve it."
>
> Then: "Ready? A few quick questions first, then we'll go deeper."

**Why this matters.** Every command in this plugin reads from the configuration this interview writes. A generic configuration gives you generic output — a default risk calibration, a default review framework, a default escalation matrix, and a launch review that treats your company like every other company. Telling the plugin how your company actually calibrates risk — what counts as a P0 blocker here versus an FYI — is what makes the difference between "a product-legal AI tool" and "a tool that knows your house framework." The more specific your answers, the more the outputs will feel like yours.

Do not read the user's home-directory `~/CLAUDE.md`, `~/user.md`, or other personal memory to pre-populate the interview. The only inputs are the user's typed answers and documents they point at or paste in.

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and product area. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for launch review framework, risk calibration, and marketing claims posture. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/product-legal:cold-start-interview --full` anytime to do the whole interview, or `/product-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Pause for real answers.** Some questions have quick tap-through answers. Others need the user to type, describe, or upload something. When a question needs more than a quick tap:

- **Ask the question and wait.** Say it plainly: "This one needs a typed answer — I'll wait." Don't queue the next question until they respond.
- **For uploads (seed launch review docs, PRDs, links to the tracker):** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your configuration so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review the interview. List every question that was skipped or answered with a placeholder. Say: "Before I write your configuration, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Wait for the answer before writing.
- **Never** write the practice profile with silent gaps. Every placeholder should be a deliberate user choice to skip, not a question that scrolled past unanswered.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/product-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /product-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> Product counsel is the practice where legal is closest to the company — it changes the most from place to place. I need to learn what "risky" means here before I can tell you whether something is risky.
>
> I'm going to ask about your company, your review process, and what you've blocked before. Then I want to read ten of your past launch reviews. Not the PRDs — *your* reviews. That's where your calibration lives.

### Part 0: Who's using this, and what's connected

Two quick questions before we get into product-legal specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds every skill's work-product header and output framing — lawyer gets "ATTORNEY WORK PRODUCT," non-lawyer gets research framing and attorney-review checkpoints before a launch clears.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, product-legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — PM, founder, business lead, marketing ops; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — launch review, feature risk assessment, marketing-claims review, and triage. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "cleared to ship," you'll get "here's what I found and here are the questions to ask before you ship." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — clearing a launch, publishing a marketing claim, approving a claim for external use. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find a lawyer: your professional regulator's referral service is the fastest starting point (state bar in the US; SRA/Bar Standards Board in England & Wales; Law Society in Scotland/NI/Ireland/Canada/Australia; or your jurisdiction's equivalent). Many offer free or low-cost initial consultations. For small businesses, local law school clinics and (in the US) SCORE mentors can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### What's connected?

> This plugin can work with: launch tracker (Jira, Linear, Asana), document storage (Google Drive, SharePoint), and Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Jira isn't connected. In Claude Cowork: Settings → Connectors → Add → Jira → sign in. In Claude Code: add the Jira MCP to your config or via `/mcp`. This plugin works without it — you'll paste PRDs and review docs directly — but connecting it lets the launch-watcher agent pull tickets automatically."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need all of these. Core features work with file access alone. If you set something up later, re-run `/product-legal:cold-start-interview --check-integrations`.

#### Record to the plugin config

Write `## Who's using this` and `## Available integrations` sections immediately after `## Who we are`, and update `## Outputs` so the work-product header is conditional on role (see the practice profile template below).

#### Practice setting

> One more quick one before we go deep:
>
> What's the setting? (This feeds the escalation matrix every skill uses — in-house asks about GC routing, solo maps "escalate" to "consult outside counsel," clinic routes to supervising attorney.)
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

Use this to branch later questions:

- **Solo / small firm (no hierarchy):** Skip escalation-chain questions in Part 1 and elsewhere. Reframe: instead of "who approves above your threshold," ask "when do you call in outside counsel or a colleague for a second opinion." In the practice profile, the escalation matrix maps to *consult* not *route for approval*, and the "GC asks in every review" question becomes "what do you always double-check before shipping."
- **Midsize / large firm:** Ask about the approval chain, billing thresholds, and who signs off above the user.
- **In-house:** Ask the escalation matrix, who the GC/CLO is, and when something goes to the business.
- **Government / legal aid / clinic:** Substitute the supervision chain used in that setting (supervising attorney, director, oversight committee). Ask about any restrictions on practice. Keep the escalation structure but relabel the roles.

Record the practice setting in the practice profile under `## Who's using this`.

### Part 1: The company (3-4 min)

**What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription).

**What are we?**
- What does the company make?
- Who uses it?
- Is the company consumer, B2B, or both?
- Are you in a regulated industry?
- If so, which industry regime(s)?
- Are there any regulators you're on a first-name basis with?
- Any active consent decrees?
- Any active investigations?
- Is the product international?
- If so, which countries matter most for legal calibration?

**Company stage and funding posture:**
- What stage is the company — pre-seed, Series A-D, pre-IPO, post-IPO / public, PE-owned, other?
- Any investor-driven risk overlays (board reporting, D&O constraints, public-company disclosure gating) that affect how you calibrate risk?

**Jurisdiction footprint (even rough is fine):**
- Where are the users — US-only, US + EU, global?
- Where are the employees and data centers?
- Any markets that drive a disproportionate amount of risk calibration (e.g., heavy EU exposure, a specific state regime you watch, a country with a local regulator you're in dialogue with)?

**Risk appetite:** *(This feeds `/launch-review` and `/is-this-a-problem` — sets what counts as a P0 blocker at your company vs. an FYI.)*
- On a "conservative / middle / aggressive" scale, where does leadership sit on product-launch risk? Any specific category where that's different (e.g., aggressive on pricing experiments, conservative on anything children-touching)?
- Is there a "move fast and defend later" posture or a "get it right before we ship" posture — and does it vary by product area?

**What keeps you up at night?** *(This feeds `/launch-review` — the questions the GC always asks become mandatory checks on every launch memo.)*
- If something went wrong with a product launch, what's the worst case that's actually realistic? (Not "someone sues us" — who, for what, and would it stick?)
- What's the thing your GC asks about in every launch review?

**Escalation — who signs off above you?** *(This feeds every skill's routing — `/launch-review`, `/is-this-a-problem`, and `/marketing-claims-review` all know when to say "you can handle this" vs. "loop in [X]".)*

> "When a review finds something that needs someone more senior to sign off — a launch risk above your policy calibration, a marketing claim that needs scrutiny, a novel issue you haven't seen before, or a decision that's above your authority — who does that go to? Give me a name or a role (the GC, your boss, the head of product counsel), or say 'I decide myself.' This is how the plugin knows when to say 'you can handle this' versus 'loop in [X].'"

### Part 2: The review process (3-4 min)

Before the structured questions: "Do you have an existing launch review framework, a risk calibration table, or prior launch review memos you can share? Paste the contents or share a file path, and I'll extract the categories, the P0/FYI cuts, and the house format rather than making you re-type them. If not, say 'no' and I'll ask the questions one at a time."

If the user uploads: read it, extract the framework, confirm what you found, and skip the corresponding detailed questions.

**How do launches get to you?**
- Launch tracker — Jira? Linear? Asana? A spreadsheet?
- Do PMs know to loop you in, or do you find out from the launch calendar?
- How much lead time do you usually get? Is it enough?

**What's your framework?** *(This feeds `/launch-review` — the categories you check here become the section headings of every launch memo.)*
- Do you have categories you check every launch against? (Contractual, privacy, IP, regulatory, etc.)
- Formal sign-off, or advisory?
- What's the output — a memo, a ticket comment, a Slack thread?

**P0 vs. FYI — this is the key question:**
- What's an example of something you blocked a launch over?
- What's an example of something that looked scary but you said "ship it"?
- What's the thing PMs keep asking about that's almost never a problem?

**If the user didn't upload a framework or past reviews:** at the end of this section, offer: "Want me to write this up as a standalone launch review framework you can share and maintain? Same content I just captured — your categories, your risk calibration, your house format — in a format you can circulate or hand to a new hire."

### Part 3: Marketing and claims (1-2 min)

*(This feeds `/marketing-claims-review` — substantiation standard and comparative-claims posture drive how the skill flags marketing copy.)*

- Who reviews marketing copy — you, or a separate marketing legal function?
- Comparative claims ("faster than X") — allowed, discouraged, banned?
- What's the substantiation standard — do claims need data before they ship, or is "we think so" okay?

### Part 4: Seed documents (3-4 min)

> I want to read ten of your recent launch reviews. Not ten PRDs — ten of *your* docs. Where you said "here's what I'm worried about" or "this is fine, ship it."
>
> If you have a launch tracker connected, I can find them. Otherwise, point me at a folder or a few docs.

**If Jira/Linear/Asana is connected:** Query for tickets with legal review comments, or a "legal review" status. Pull the last 10-15.

**Read the seed docs and extract:**

1. **Categories used** — do they use a formal framework or freestyle? Either way, note what they actually check.
2. **Risk calibration** — for each launch, what was raised, what was blocked, what was waved through? Build a table.
3. **Output format** — memo, ticket comment, checklist? Length, tone, structure.
4. **Common patterns** — same issue across multiple launches? That's a systemic thing to note.

**The calibration table (this is the key output):**

| Issue seen | How often | Typical call | Example |
|---|---|---|---|
| New data collection | 8/10 | PIA required, rarely blocks | "Analytics event added — PIA done, shipped" |
| Third-party integration | 6/10 | DPA check, rarely blocks | "Stripe webhook — existing DPA covers it" |
| Comparative marketing claim | 3/10 | Substantiation required | "'Fastest' claim blocked until benchmarks" |
| Children's data | 1/10 | **Blocked pending full review** | "School district pilot — COPPA review first" |

## Writing the practice profile

```markdown
# Product Counsel Practice Profile

*Written by cold-start on [DATE]. Edit directly.*

---

## Who we are

[Company] makes [product]. [Consumer/B2B]. [Regulated: yes/no, by whom].
[International: regions]. [Consent decrees / active matters: none or list].

**Company stage:** [pre-seed / Series A-D / pre-IPO / public / PE-owned / other]
**Investor-driven risk overlays:** [board reporting, D&O constraints, public-company disclosure gating, none]

**Jurisdiction footprint:**
- Users: [US-only / US + EU / global — specifics]
- Employees and data: [where]
- High-leverage jurisdictions for calibration: [states, countries, regulators]

**Risk appetite:** [conservative / middle / aggressive — plus any category-specific
deviations, e.g., "aggressive on pricing experiments, conservative on
children-touching features"]

**What keeps us up at night:** [their answer, in their words]

**The question the GC always asks:** [their answer]

---

## Who's using this

**Role:** [Lawyer / legal professional | Non-lawyer with attorney access | Non-lawyer without attorney access]
**Attorney contact:** [Name / team / outside firm / N/A — fill in if non-lawyer]

---

## Available integrations

| Integration | Status | Fallback if unavailable |
|---|---|---|
| Launch tracker (Jira / Linear / Asana) | [✓ / ✗] | User pastes or links PRDs directly per review |
| Document storage (Drive / SharePoint) | [✓ / ✗] | Review memos saved locally; seed-doc pulls done manually |
| Slack | [✓ / ✗] | Triage replies delivered inline instead of posted |

*Re-check: `/product-legal:cold-start-interview --check-integrations`*

---

## Outputs

**Work-product header** (prepended to launch review memos, feature risk assessments, marketing-claims analyses, triage replies):

- If Role is Lawyer / legal professional: `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT — PREPARED AT THE DIRECTION OF COUNSEL`
- If Role is Non-lawyer: `RESEARCH NOTES — NOT LEGAL ADVICE — REVIEW WITH A LICENSED ATTORNEY BEFORE ACTING`

Toggle the header off for externally-facing deliverables (public FAQs, customer-facing letters, marketing-side communications) — see the specific skill's instructions. Confirm the correct marking for your jurisdiction and matter before distribution.

---

## Launch review process

**How launches reach legal:** [tracker: Jira/Linear/etc., or informal]
**Lead time we usually get:** [N days/weeks]
**Output format:** [memo / ticket comment / etc. — extracted from seed docs]
**Sign-off:** [formal gate / advisory]

---

## Review framework

*Categories checked on every launch (extracted from seed docs + interview):*

1. **[Category]** — [what you check, what triggers escalation]
2. **[Category]** — [...]
[etc. — use their categories if they have them; offer the 7-cat framework
from launch-review skill if they don't]

---

## Risk calibration

*Learned from [N] past launch reviews. This is what P0 vs. FYI actually means here.*

### Usually blocks

| Pattern | Why it blocks here | Resolution path |
|---|---|---|
| [e.g., Children's data] | [e.g., COPPA + we're not set up for it] | [Full review, parental consent flow] |

### Usually requires work but ships

| Pattern | Work required | Typical timeline |
|---|---|---|
| [e.g., New data collection] | [PIA] | [1-2 days] |

### Usually FYI

| Pattern | Why it's fine here | Caveat |
|---|---|---|
| [e.g., New vendor already on approved list] | [DPA exists] | [Unless they're touching new data category] |

---

## Marketing claims

**Reviewer:** [product counsel / separate marketing legal]
**Comparative claims:** [allowed with substantiation / discouraged / never]
**Substantiation standard:** [what's required before a claim ships]
**Common rejected claims:** [patterns from seed docs — "always-on", "guaranteed", unqualified superlatives]

---

## Escalation

| Trigger | Escalates to | Via |
|---|---|---|
| [Pattern from "usually blocks"] | [GC] | [method] |
| Novel issue not in calibration table | [You, then GC if unclear] | |
| Regulatory inquiry tied to a launch | [GC immediately] | |

---

## Connected systems

**Launch tracker:** [Jira project / Linear team / etc.]
**PRD location:** [Drive folder / Confluence / etc.]
**Launch calendar:** [where]

---

## Seed reviews

| Launch | Date | Call | Notes |
|---|---|---|---|
| [name] | [date] | [blocked / shipped / shipped with conditions] | [key learning] |

---

*Re-run: `/product-legal:cold-start-interview --redo`*
```

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in product counsel practice:**
>
> - **Legal review of a product launch** — e.g., "PRD in, review memo out against your review framework and risk calibration." Try: `/product-legal:launch-review`
> - **Fast triage on a Slack question** — e.g., "'Hey legal, quick question' gets a same-minute fine / needs a real look / stop." Try: `/product-legal:is-this-a-problem`
> - **Marketing claims review** — e.g., "Check copy for claims needing substantiation, comparatives, superlatives, and promises the product can't keep." Try: `/product-legal:marketing-claims-review`
>
> **My suggestion for your first one:** Run `/is-this-a-problem` on one PM question you already answered — see if the answer matches how you calibrated it. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show the calibration table.** "This is what I learned from your past reviews — does this match your sense of what blocks and what doesn't?"

2. **Research connector prompt.** Say:

   > "Before your first launch review: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you."

3. **Propose first task:** "What's on the launch calendar this week? Let me take a first pass."

4. **Offer the launch-watcher agent:** "I can watch the launch tracker and flag anything that looks like it'll need review before you get surprised by it."

5. **Close with the changeability note.** Say:

   > "Done. Your configuration is at `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` — a plain-text file you can read and edit directly. Anything you answered can be changed:
   >
   > - Edit the file directly for a quick change
   > - Run `/product-legal:cold-start-interview --redo` for a full re-interview
   > - Run `/product-legal:cold-start-interview --check-integrations` to re-check what's connected
   >
   > The settings people tune most often: the risk calibration tables (what blocks vs. what ships), the review framework categories, and the escalation matrix. Your configuration will improve as you use the plugin — when a review feels off (too cautious, too loose, wrong frame), the fix is usually here."

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## Failure modes

- **Don't invent a framework they don't use.** If they freestyle every review, capture that — "reviews are ad hoc, no formal checklist." The launch-review skill can offer structure later.
- **Don't mistake "we've never blocked this" for "this is fine."** Sometimes they've just never hit the issue. Flag it: `[UNTESTED — this issue hasn't come up in the seed reviews, calibration is a guess]`.
- **Don't read PRDs instead of review docs.** The PRD tells you what the feature does. The review doc tells you what the lawyer worried about. You want the second one.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/product-legal:customize`. They want to change something
in their product counsel profile — a risk calibration threshold, an
escalation contact, a framework section — without re-running the whole
cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/product-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting, product surface area *(shared across all 12 plugins — changes
     flow through `company-profile.md`)*
   - **Launch review process** — intake (Jira / Linear / Asana / doc),
     review SLA, launch tiering, PRD location
   - **Review framework** — the categories you review launches against
     (privacy, IP, safety, claims, regulatory, accessibility, security,
     etc.) and the depth you go on each
   - **Risk calibration** — what's P0 blocker / needs a real look / fine at
     your company, with examples that anchor the labels
   - **Marketing claims** — posture on puffery vs. substantiated, comparative
     claims framing, superlatives, house rules for AI-feature claims
   - **People** — product partners by surface, escalation chain (your
     manager, GC, risk committee), marketing counterpart
   - **Workflow** — matter workspaces, launch-radar watcher cadence, launch
     review template
   - **Integrations** — Jira / Linear / Asana / Slack / document storage
     status, fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Risk calibration tightening "fine" → "needs a real look" for a
     pattern:* "`/is-this-a-problem` and `/launch-review` will start flagging this
     pattern. Existing reviews stay as written; re-run if you want the new
     posture applied."
   - *New launch-review category:* "`/launch-review` will add a section for
     this category. `/is-this-a-problem` will pattern-match it in triage."
   - *Marketing claims posture tightening:* "`/marketing-claims-review` will flag more
     language as needing substantiation or reframing."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/product-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" a review
  category, offer to mark it `[Not in scope — route elsewhere]` and name
  the plugin / team that picks it up.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., AI-feature claims scrutiny on + no AI policy
  commitments set in `/ai-governance-legal`; or "fast SLA" + "every
  launch requires GC sign-off"), flag the tension.
- **Flag guardrail degradation.** The `[review]` flag, source attribution
  tags, and `[verify]` tags on cited regulations are load-bearing — do not
  remove. The substantiation requirement on claims is the thing
  `/marketing-claims-review` exists for; weakening it defeats the skill.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/feature-risk-assessment', 'legal', 'feature-risk-assessment', '', 'feature-risk-assessment', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Feature Risk Assessment

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/product-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

The launch review is broad. This is deep. When a single issue needs more than a table row — a novel AI feature, a children's product, something a regulator is actively looking at — this skill produces a standalone assessment.

Not every launch needs one. Most don't. This is for the 10% where "PIA done, shipped" isn't the right level of scrutiny.

## When to run this

- Launch review found a pattern that's **not in the calibration table** (novel)
- Launch review found something in the **"usually blocks"** category
- GC or leadership asked "what's the risk here" and wants more than a one-liner
- The feature is in an area with **active regulatory attention** (AI, children, biometric, health)
- Someone outside legal is worried and a structured answer would help

If none of the above, the launch review is enough. Don't generate paperwork for its own sake.

## Structure

### 1. What we're assessing

One paragraph. What the feature does, what's new about it, why it got escalated to a full assessment.

### 2. The risks

For each distinct risk (aim for 2-5, not 15):

```markdown
### Risk [N]: [Short name]

**Scenario:** [What would have to happen for this to go wrong. Be specific —
not "data breach" but "the recommendation algo surfaces a user's sensitive
category interest to someone who shouldn't see it because X."]

**Who gets hurt:** [Users? The company? A third party? Specific.]

**How likely:** [Low / Medium / High — with a reason. "Low — would require
both X and Y to fail simultaneously." Not just a vibes rating.]

**How bad if it happens:** [Low / Medium / High — with a reason. "High —
regulatory fine + class action exposure + press" vs. "Low — one angry
tweet, no actual harm."]

**Existing mitigations:** [What already reduces the likelihood or impact]

**Gap:** [What's missing, if anything]

**Residual risk:** [After existing mitigations — is this acceptable or does
it need more?]
```

### 3. Regulatory landscape (if relevant)

Only include if a regulator is actively interested in this space. If so:

- Which regulator, what they've said/done recently
- How this feature would look to them
- Whether we'd rather they hear about it from us or from a headline

### 4. Precedent (if any)

Has another company done something similar? What happened?

- If nothing bad happened → useful, not dispositive
- If something bad happened → what was different about their situation, does it apply here

Don't overweight precedent. Regulators change priorities; one company getting away with something doesn't mean the next one will.

### 5. Options

Present 2-3 realistic paths:

```markdown
| Option | Description | Risk reduction | Cost |
|---|---|---|---|
| A: Ship as designed | [current plan] | None | None |
| B: Ship with [mitigation] | [change] | [how much] | [eng effort, timeline, UX] |
| C: Don't ship [component] | [scope cut] | [how much] | [product impact] |
```

### 6. Recommendation

Pick one. Explain why. Acknowledge what you're trading off.

```markdown
**Recommended: Option [X]**

[Why. What risk remains. Why that's acceptable. Who accepts it.]

**If the answer is "not my call":** [Who decides, what they need to know]
```

## Calibration check

Before finalizing, check against `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Risk calibration:

- Is this risk assessment calibrated to *this company*, or is it generic?
- A risk that's "High" at a company under a consent decree might be "Medium" at one that isn't
- The assessment should reflect the actual regulatory posture, litigation history, and risk appetite captured in the practice profile

## Handoffs

- **To AI governance:** If the deep-dive was triggered by an AI feature — which
  it often is — run `/ai-governance-legal:aia-generation [feature]` in parallel or
  immediately after. The feature risk assessment frames the decision; the AIA
  documents the AI system specifically in the format AI governance needs. They're
  not duplicates: the FRA is a product-legal decision doc; the AIA is the
  governance record.
- **To privacy:** If the feature involves new data collection or processing,
  run `/privacy-legal:pia-generation [feature]`. The FRA's risk section
  will likely overlap with the PIA's — flag that overlap so work isn't duplicated,
  but both docs need to exist.
- **To AI governance vendor review:** If the feature uses a new AI vendor,
  run `/ai-governance-legal:vendor-ai-review [vendor agreement]` if not already done
  during the launch review.

## Output format

Standalone doc, 2-4 pages. Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

Not a slide deck, not a memo to file — a decision document someone reads and then decides.

Save where `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Launch review process says review docs go. If the doc is going to be shared with anyone outside the privileged loop (e.g., posted to a broadly-shared ticket), drop the work-product header only for that externally-facing copy and keep the privileged original in the matter file.

## Citation check

If the assessment cites cases, statutes, regulations, or enforcement actions — in the Regulatory landscape or Precedent sections especially — those citations were generated by an AI model and have not been verified against a primary source. Before the decision document goes to a decisionmaker, verify each citation against a legal research tool (Westlaw, CourtListener, or your firm's research platform) for accuracy, good law status, and current enforcement posture. A risk assessment built on a fabricated enforcement action is worse than no assessment.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for the regime or precedent the assessment needs, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / precedent]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation in the Regulatory landscape and Precedent sections with where it came from: `[Westlaw]`, `[CourtListener]`, `[regulator site]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations from the feature team. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags — the decisionmaker needs to see which citations to verify first.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't assess every feature. Most features get a launch review and that's it.
- It doesn't make the decision. It frames the decision. Someone with authority picks an option.
- It doesn't do quantitative risk modeling. If the company has a formal risk framework with numbers, use that — this is qualitative.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/is-this-a-problem', 'legal', 'is-this-a-problem', '', 'is-this-a-problem', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /is-this-a-problem

1. Load `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Risk calibration.
2. Apply the triage workflow below.
3. Pattern-match. Check for common traps.
4. Answer in one minute: ✅ Fine / ⚠️ Needs a look / 🛑 Hold. One sentence why.
5. If ⚠️ or 🛑: name the next step.

```
/product-legal:is-this-a-problem "Can we use customer logos on the pricing page?"
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/product-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

Most "quick legal question" Slacks are one of three things: (a) not a problem, say so fast, (b) a real thing that needs a real look, route it, (c) a thing that looks fine but has a trap, catch the trap. This skill sorts in under a minute using the calibration table.

The goal is speed. The PM asked at 4:47pm. They want an answer, not a memo.

## Load calibration

Read `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → `## Risk calibration`. The whole point of this skill is pattern-matching against that table.

## The triage

### Match against calibration

Does the question match a pattern in the calibration table?

**Matches "usually FYI":**
→ Say so. One line. "You're fine — [pattern]. Ship it."

**Matches "usually requires work":**
→ Name the work. "Needs a [PIA / vendor review / claims check]. Takes [timeline from table]. Want me to start it?"

**Matches "usually blocks":**
→ Stop them. "Hold on — [pattern]. This needs a real look before anyone commits to a date. Let's talk."

**Doesn't match anything:**
→ Say that too. "This doesn't pattern-match to anything I've seen here. Needs a human look — [your name] or me tomorrow?"

### The trap check

Some questions are fine on the surface but have a twist. Recognize the fact pattern, ask the catch question, then research the applicable doctrine for the specific fact pattern before concluding whether it's a problem or not.

| Question sounds like | Why it might not be simple | Catch it by asking |
|---|---|---|
| "Can we add [vendor] to the integration?" | Vendor touches a new data category — flag as potentially implicating privacy and vendor-risk regimes and route for research | "What data flows to them?" |
| "Can we A/B test the pricing page?" | Differential pricing by segment can implicate consumer-protection and anti-discrimination regimes — flag and route for research | "Are both arms seeing the same price for the same thing? How are users assigned to arms?" |
| "Can we auto-enroll users in the new feature?" | Default-on behavior for users who previously opted out can implicate consent and consumer-protection rules — flag and route for research | "Does this respect existing preferences?" |
| "Can we use customer logos on the site?" | Logo use is a separate permission from the contract relationship — flag as potentially implicating publicity / endorsement rules and the customer's own contract terms | "What does the contract say about publicity? Do we have written permission?" |
| "Can we train on this data?" | Usage rights for the original collection purpose may not extend to training — flag and research the notice/consent the users were given at collection | "What did we tell users when we collected it? What jurisdictions are the users in?" |
| "It's just an internal tool" | Internal tools still process personal data — flag as potentially implicating privacy regimes and route for research | "Whose data does it touch? Employees, customers, third parties?" |
| "We already do something similar" | "Similar" is doing a lot of work — the delta is where the issue usually is | "Similar how? What's actually different?" |
| "Can we use [AI vendor / LLM] for this?" | Vendor AI terms may permit training on inputs; use case may need an AIA — flag and route to `/ai-governance-legal:use-case-triage` | "Is there an AI addendum? What data goes into the model?" |
| "Can we add AI to this feature?" | May be a new use case not in the registry; may trigger AIA requirement — flag and route to `/ai-governance-legal:use-case-triage` | "What does the AI do — assistive or automated? Who does it act on?" |
| "The model just decides automatically" | Automated decision-making without human review is regulated in some jurisdictions — flag and research the applicable rules for the affected users' jurisdictions | "Who's affected? Is there a human in the loop? Where are the affected users?" |
| "It's AI-generated content" | Output IP and disclosure duties vary by jurisdiction and vendor terms — flag and route for research | "What's the content type? Does the vendor's ToS address output ownership? Who is the audience?" |
| "We're just fine-tuning on our data" | Training data rights, output IP, and vendor obligations all change — flag and route to `/ai-governance-legal:vendor-ai-review` | "What's in the training data? Is any of it customer or employee data?" |

If a trap might be present, ask the one question before answering. One question, not a checklist. When the answer suggests a real issue, flag for research and route — don't pattern-match to a legal conclusion from the question alone.

## Output format

**For Slack (the common case):**

Slack triage replies are internal legal advice. If the reply is being pasted into a ticket, document, or channel that's broadly shared with non-legal, prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`):

```
[WORK-PRODUCT HEADER — per plugin config ## Outputs]
```

For an in-the-flow Slack DM reply to the PM, the short form is:

```
[✅ Fine | ⚠️ Needs a look | 🛑 Hold]

[One sentence: the call and why.]

[If ⚠️: what the look involves, how long]
[If 🛑: who to talk to, when]
```

**Examples:**

```
✅ Fine — adding an analytics event is an FYI here as long as it's covered by
the existing privacy policy categories. This one is.
```

```
⚠️ Needs a PIA — new data collection for [category]. Usually takes a day.
Want me to kick it off?
```

```
🛑 Hold — "train on customer data" triggers a bunch of things. What did the
customer agreement say about data use? Let's pull it before anyone promises
this to the customer.
```

```
⚠️ Needs an AI governance triage — adding an LLM to this workflow means we need
to check the use case against the registry and confirm an AIA is done before it
ships. Takes a day. Want me to run `/ai-governance-legal:use-case-triage` now?
```

## When to NOT use this skill

- The question is actually complex (multiple issues, novel area) → route to launch-review or feature-risk-assessment
- The question is "can you review this PRD" → that's launch-review, not triage
- You're not sure → say "I'm not sure, let me look properly" — a wrong fast answer is worse than a slow right one

## Tone

Fast, direct, helpful. The PM is not asking for a lecture. If it's fine, say "fine" — don't list the seven things you checked. If it's not fine, say what's not fine and what to do about it.

You are the lawyer people want to ask, not the one they route around.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/launch-review', 'legal', 'launch-review', '', 'launch-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /launch-review

1. Load `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → framework + calibration. Stop if placeholders.
2. Get PRD + related docs. If tracker connected, pull ticket and comments.
3. Walk every framework category using the workflow below.
4. Calibrate each finding against the table. Novel = flag explicitly.
5. Output review memo in house format. Post summary to ticket if connected.
6. Hand off: marketing-claims-review if substantial marketing; feature-risk-assessment if a finding needs depth.

```
/product-legal:launch-review PROJ-1234
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/product-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

Read the PRD, check every category in this team's framework, calibrate against what actually blocks here (per `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`), and output a review in house format. Goal: a PM reads it and knows exactly what has to happen before they ship.

## Load calibration

Read `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`:
- `## Review framework` — the categories to check
- `## Risk calibration` — what blocks vs. what's FYI *at this company*
- `## Launch review process` — output format
- `## Escalation` — when to route up

The calibration table is the difference between this skill and a generic checklist. If the table says "new data collection → PIA, ships in 1-2 days," don't write "this might require a full DPIA and regulatory consultation." Match the team's actual practice.

## Workflow

### Step 1: Get the inputs

- **PRD** — from file, Drive, or the launch tracker ticket
- **Spec/design doc** — if separate
- **Marketing plan** — if there is one (hands off to marketing-claims-review if substantial)
- **Launch date** — for urgency calibration
- **Launch tracker ticket** — if connected, pull it for context and comments

If Jira/Linear MCP is connected, pull the ticket history — often there's context in earlier comments that the PRD doesn't capture.

### Step 2: Understand what's launching

Before the checklist, answer in plain English:

- What does this thing do?
- Who uses it — existing users, new users, a new segment?
- What's new vs. what's an extension of something already reviewed?
- Any new data, new vendors, new claims, new jurisdictions?

**AI detection — run before the framework walk.** Check whether this launch uses
AI in any form: a third-party model, an internally built model, an AI-powered
vendor feature, automated scoring or classification, generative content,
recommendations, predictions. Look for this even if the PRD doesn't label it
"AI" — words like "intelligent", "automated", "personalized", "generated",
"suggested" are tells.

If AI component detected → flag it, then run `/ai-governance-legal:use-case-triage [feature]`
alongside the framework walk. Category 8 below handles the detail; this flag
ensures it's never skipped even if the PRD is vague.

### Step 3: Walk the framework

For each category in `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Review framework. If the team doesn't have one, use the 8-category default below. The categories are stable framing concepts; within each category, research the regulatory regimes applicable to the product's sector, audience, and jurisdictions before calibrating severity. What blocks in one jurisdiction or sector may be routine in another — `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` captures the team's calibration.

| # | Category | Key question | Auto-skip if |
|---|---|---|---|
| 1 | **Contractual commitments** | Does this conflict with any customer-facing promise (ToS, SLA, marketing)? | No customer-facing changes |
| 2 | **Privacy** | New data collection, new purpose, new sharing? | No data changes |
| 3 | **Security** | New attack surface, new data at rest, new access patterns? | UI-only, no backend change |
| 4 | **IP** | Third-party code/content? Open-source license check? Outputs that could infringe? | No new dependencies, no user-generated content |
| 5 | **Third-party** | New vendor, partner, or integration? | No new external parties |
| 6 | **Regulatory** | Does this touch a regulated sector, audience, or jurisdiction? Research the applicable regimes. | Same users, same sectors, same jurisdictions as existing product |

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, regulator sites, or firm platform) returns few or no results for a regime, enforcement precedent, or regulator guidance, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the review with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., FTC Act § 5, GDPR Art. 33, CCPA § 1798.100). Still verify before relying on it to clear a launch, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific implementing regulations, agency guidance, enforcement actions, case holdings, thresholds, effective dates, post-2023 amendments.
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, volume/page numbers, paragraph numbers) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[CourtListener]`, `[regulator site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations (from the PRD or seed materials) remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.
>
> `[platform policy — verify against live docs]` — platform rules (Apple App Store Review Guidelines, Google Play policies, Meta / Snap / TikTok creator rules, ESRB / PEGI descriptors, card-network rules, app-store in-app-purchase policies) cited without fetching the live page. Never use `[settled]` for a platform policy — these change without notice and the model's snapshot is almost always stale. If the launch hinges on a platform rule, fetch the current policy page in-session before relying on it.
| 7 | **Marketing claims** | Any claims that need substantiation? | No marketing component |
| 8 | **AI governance** | Does this use AI in any form? Is the use case in the registry? AIA done? Vendor AI terms reviewed? | No AI component detected in Step 2 |

**For each category, output:**

```markdown
### [N]. [Category]

**Checked:** [what you looked at]
**Finding:** [Clear | Needs work | Blocker | Skipped]
**Detail:** [what the issue is, if any — specific to the PRD, not generic]
**Calibration:** [per the config CLAUDE.md — this is usually an FYI / usually needs X / usually blocks]
**Action:** [what has to happen, who owns it, by when]
```

**Auto-skip honestly.** If a category doesn't apply, say so with a one-line reason. Don't pad.

**Sector hints.** The 8-category framework above is enterprise-SaaS-shaped. If the launch involves any of the sectors below, add the overlay: ask the overlay question alongside the base-framework question for each affected category, and surface the sector-specific regime before calibrating severity. A launch that checks all 8 boxes but misses a sector regime still ships with a hole.

| Sector | Overlay regimes to surface |
|---|---|
| **Children / minors** | COPPA (US — operators of services directed to children under 13 or with actual knowledge), CA AADC / state age-appropriate design codes, platform age ratings (ESRB, PEGI), addictive-design scrutiny (NY Safe for Kids Act, CA SB 976 and analogs), FTC endorsement guides for kid-directed influencers |
| **Gaming / loot boxes / in-game currency** | Loot-box odds disclosure (CA AB 2476-style, Chinese / Korean / Belgian / Dutch regimes), ESRB / PEGI descriptors (In-Game Purchases, Loot Boxes, Real Gambling), state gambling law (games-of-chance vs. games-of-skill lines, sweepstakes promotions law), FTC dark-patterns guidance, platform-store policies (Apple, Google, console) |
| **Financial / fintech** | GLBA (NPI, Safeguards Rule, Reg P), state money transmission licensing (MTLs across ~50 states + DC), CFPB UDAAP, state UDAP, bank-partner sponsorship requirements and "true lender" exposure, Reg E / Reg Z where applicable, FINRA if brokerage |
| **Health** | HIPAA (if CE or BA), FDA SaMD / clinical decision support / general wellness exemption, state health-privacy (WA MHMDA, NV SB 370, CT HIPAA-analog), FTC Health Breach Notification Rule for non-HIPAA entities |
| **Education** | FERPA (if school or school-acting service provider), state student-privacy (NY Ed Law 2-d, IL SOPPA, CA SOPIPA + AB 1584), COPPA if K-12 data under 13 |
| **Employment / HR tech** | Title VII, EEOC guidance on AI in hiring, ADA, state AI-hiring laws (IL AIVIA, NYC Local Law 144, CA / CO / UT / NJ analogs under consideration or enacted), state biometric laws (IL BIPA, TX / WA analogs) for video-interview and keystroke products, FCRA for background / verification products |
| **Government / public sector** | FedRAMP (Low / Moderate / High), FAR / DFARS, CMMC where applicable, state-level equivalents (StateRAMP), CJIS for law-enforcement data, IRS Publication 1075 for tax data, StateRAMP and state procurement rules |
| **Consumer / retail / marketing** | FTC Act § 5, Made-in-USA rule, Green Guides, CAN-SPAM, TCPA (with TCPA-Shaken/Stir for calls), state auto-renewal (ROSCA, CA ARL, NY GBL § 527-a [consumer] or GOL § 5-903 [B2B services] — verify which applies), state sweepstakes/promotions law |

If a sector hint fires and no dedicated category in the base framework covers it, insert it as a category (e.g., "6a. Sector overlay — children / COPPA + CA AADC"). Don't let it disappear into category 6 Regulatory as an afterthought; the sector regime often supplies the controlling floor, not a footnote.

### Step 4: Calibrate severity

For each finding, check against the calibration table in ~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md:

- If it matches a "usually FYI" pattern → note it, don't block
- If it matches "usually requires work" → specify the work, estimate timeline from the table
- If it matches "usually blocks" → flag prominently, route per escalation table
- If it's **novel** (not in the table) → say so explicitly: "This doesn't match any pattern in the calibration — needs a human call"

### Step 5: Assemble the review

Format per `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Launch review process → output format. Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`). If no house format is specified:

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# Launch Review: [Feature name]

**Reviewed:** [date] | **Launch date:** [date] | **Reviewer:** [name]
**PRD:** [link] | **Ticket:** [link if connected]

---

## Bottom line

[One paragraph: can this ship? What has to happen first?]

**Call:** [Clear to ship | Ship with conditions | Blocked pending X | Needs escalation]

> **Before emitting a "Clear to ship" or "Ship with conditions" call:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`. If the Role is Non-lawyer:
>
> > Clearing a launch is a legal act — once the product ships, the company is committed to the legal posture documented here. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
> >
> > [Generate a 1-page summary: the launch, the findings by category, any open questions, the residual risk after conditions, and the three things to ask the attorney before the launch goes out.]
> >
> > If you need to find a lawyer: your professional regulator's referral service is the fastest starting point (state bar in the US; SRA/Bar Standards Board in England & Wales; Law Society in Scotland/NI/Ireland/Canada/Australia; or your jurisdiction's equivalent).
>
> Do not proceed past this gate to a "Clear to ship" or "Ship with conditions" call without an explicit yes. "Blocked pending X" and "Needs escalation" do not require the gate — those are review calls, not clearances.

---

## Findings by category

[All the category blocks from Step 3 — skip-noted categories at the bottom]

---

## Action items

| # | Item | Owner | Due | Blocking? |
|---|---|---|---|---|
| 1 | [specific] | [PM/eng/legal] | [date] | Yes/No |

---

## Escalations

[If any — who, why, drafted per escalation skill]

---

## Notes for next time

[If this launch surfaced a pattern that should update the calibration table]

---

## Citation check

Any cases, statutes, regulations, or enforcement actions referenced in this review were generated by an AI model and have not been verified against a primary source. Before relying on a citation in a launch decision, verify it against a legal research tool (Westlaw, CourtListener, or your firm's research platform) for accuracy, good law status, and current enforcement posture. Fabricated or misquoted citations in launch reviews can steer the business wrong. Source tags on each citation (e.g., `[Westlaw]`, `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.
```

### Step 6: Produce BOTH outputs — the privileged memo AND the redacted ticket comment

⚠️ **Privilege warning:** Posting the full privileged memo to a Jira/Linear ticket that is widely shared with engineering, PM, and other non-legal roles may waive privilege. Don't paste the full memo into a broadly-shared ticket.

**Both of the following are REQUIRED outputs of this skill.** Neither is optional. Print them in the order below, with a clear divider between them so the user cannot miss the redacted block.

**Output 1 — Privileged launch review memo.** The full analysis assembled in Step 5: work-product header, bottom line, findings by category with risk rationale, action items, escalations, notes for next time, citation check. This is internal legal work product. Keep it in your matter file (Drive, DMS, or wherever `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` says review docs go). Distribute only to people inside the privilege circle.

**Output 2 — Redacted ticket-comment block — SAFE TO POST TO TRACKER.** After the memo, with a clear `---` divider and the header `## SAFE TO POST TO TRACKER (non-privileged)`, produce a short comment block containing ONLY:

- **Launch status:** green / yellow / red (i.e., Clear to ship / Ship with conditions / Blocked pending X / Needs escalation)
- **Conditions as action items:** each condition is a bullet, written as an instruction to the PM/eng ("add PIA link to ticket before ship", "remove 'most accurate' language from homepage copy"). No legal reasoning.
- **Deadline per condition.**
- **Owner per condition.**

The redacted block contains NO work-product / privilege header, NO risk rationale, NO internal legal discussion, NO regulatory citations, NO escalation notes. If a condition's phrasing would leak the underlying legal theory ("retaliation risk"), rewrite it as the action ("route to GC before term date").

Example divider and block:

```markdown
---

## SAFE TO POST TO TRACKER (non-privileged)

**Launch status:** Blocked pending conditions below.

**Conditions:**
- [ ] Attach completed PIA to ticket — Owner: [PM] — Due: [date]
- [ ] Remove "most accurate on the market" copy from homepage draft — Owner: [Marketing] — Due: [date]
- [ ] Confirm with GC before changing retention window — Owner: [PM] — Due: [date]
```

Paste Output 2 (and only Output 2) to the tracker. Link Output 1 only to the people inside the privilege circle who need to read the full analysis.

## Handoffs

- **To marketing-claims-review:** If there's a substantial marketing component, hand off the claims section.
- **To feature-risk-assessment:** If a finding is complex enough to need its own doc (e.g., novel AI feature, children's product), spawn a deeper assessment.
- **To privacy:** If the launch touches personal data, run `/privacy-legal:use-case-triage [feature]`. If triage returns PIA REQUIRED or DPIA MANDATORY, run `/privacy-legal:pia-generation [feature]`. Don't just note "PIA needed" — trigger it.
- **To AI governance:** If an AI component was detected in Step 2, run `/ai-governance-legal:use-case-triage [feature]`. If triage returns CONDITIONAL, run `/ai-governance-legal:aia-generation [feature]`. If a new AI vendor is involved, run `/ai-governance-legal:vendor-ai-review [vendor agreement]`.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't replace a conversation with the PM. Often the PRD is wrong or out of date — the review surfaces questions, a human asks them.
- It doesn't approve the launch. It informs the approval.
- It doesn't retroactively calibrate. If this launch turns out fine (or badly) in a way that should update the calibration table, a human updates ~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/marketing-claims-review', 'legal', 'marketing-claims-review', '', 'marketing-claims-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /marketing-claims-review

1. Load `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → Marketing claims standards.
2. Apply the claim taxonomy and review workflow below.
3. Extract every claim. Classify: puffery / factual / comparative / implied / absolute.
4. For each non-puffery claim: substantiation check, suggested fix.
5. Output: claim-by-claim with calls, suggested revision if short enough.

```
/product-legal:marketing-claims-review
[paste landing page copy]
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/product-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Marketing wants to say the product is the best. Legal needs it to be true, or at least not provably false. This skill finds the claims that will get a demand letter from a competitor or an inquiry from a regulator, and suggests how to keep the energy while fixing the exposure.

## Load standards

Read `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` → `## Marketing claims`:
- Comparative claims policy (allowed with substantiation / discouraged / never)
- Substantiation standard (what's required before a claim ships)
- Common rejected claims (learn from history)

## Research the applicable standards before clearing copy

Research the currently operative advertising and substantiation standards for the applicable jurisdictions and media (for example, FTC, NAD, state UDAP regimes, sector regulators for healthcare / financial / children's products, and platform-specific policies). Identify what substantiation the *specific claim* requires — who measured it, when, sample size, apples-to-apples basis — not just whether *some* substantiation exists on file. Flag implied claims and comparative claims for heightened scrutiny. Verify currency: endorsement and review guides have been updated recently and continue to evolve. Cite primary sources with pinpoint references. If you cannot verify the current standard, flag for attorney verification — do not state a rule you haven't confirmed.

> **Only cite the standards that apply to the specific claims under review.** A blanket list of every FTC guideline, NAD practice note, or sector rule makes the load-bearing ones invisible. Do not cite the Endorsement Guides (16 CFR Part 255) unless the copy contains an endorsement, testimonial, or influencer content. Do not cite disclosure-overlay rules unless a claim in the asset triggers the overlay. Do not cite a sector regulator unless the copy targets or implicates that sector. A standard earns its place in the output by mapping to a specific quoted claim; otherwise drop it.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for the applicable standard (FTC rule, NAD decision, state UDAP, sector rule, platform policy), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [standard / jurisdiction]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., FTC Act § 5, Lanham Act § 43(a) as a concept). Still verify before approving copy, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific FTC enforcement actions, NAD decisions, state UDAP statutes, sector-specific rules, platform policies, case holdings, thresholds, effective dates, recent updates (the Endorsement Guides and disclosure rules update frequently).
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, CFR subpart references, case paragraph numbers) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[CourtListener]`, `[FTC site]`, `[NAD]`, `[platform policy]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations (from substantiation files) remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

## Claim taxonomy

The categories below are structural patterns the reviewer should be able to recognize. Whether a given phrase is actionable depends on the currently operative rule in the applicable jurisdiction, the specific substantiation available, and the audience — research that before concluding.

### Vague / subjective claims

Subjective assertions with no measurable content. Whether they are actionable depends on jurisdiction, context, and audience — research before concluding.

| Example |
|---|
| "The best way to manage your projects" |
| "You'll love it" |
| "Revolutionary" |

### Specific factual claims

Measurable, specific, a reasonable person might rely on it.

| Example | Substantiation to look for |
|---|---|
| "50% faster than [competitor]" | Benchmark data, disclosed methodology, date |
| "Trusted by 10,000 companies" | Actual count (not cumulative signups — *currently* trusted) |
| "Saves 5 hours per week" | Study or customer data, disclosed sample |
| "Enterprise-grade security" | What does that mean? SOC 2? Spell it out or it's a promise |
| "HIPAA compliant" | BAA available, actually configured for it — this is a contractual promise |

### Comparative claims (heightened scrutiny)

Naming a competitor or implying one. Research the applicable rules for comparative advertising in the relevant jurisdictions and media before clearing.

| Example | Fix pattern |
|---|---|
| "Faster than Slack" | Either name Slack with head-to-head data you can defend, or abstract to "faster than legacy chat tools" with substantiation |
| "The only platform that does X" | False if anyone else does X — "The first platform to..." (if true) or drop "only" |
| "[Competitor] can't do this" | Show your feature. Let the viewer compare. |

Per `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` — if comparative claims are "never," flag all of them. If "allowed with substantiation," check for the substantiation.

### Implied claims

Not stated outright but a reasonable reader infers it. Research the treatment of implied claims under the applicable advertising regime — implied claims often carry the same substantiation burden as express ones.

| Example | Implication | Fix |
|---|---|---|
| "Finally, a secure alternative" | Competitors are insecure | "Finally, security you can verify" |
| Customer logos without context | These companies endorse us | "Customers include..." is fine; "Trusted by..." implies more |
| "Built for healthcare" | HIPAA compliant | Clarify or qualify |

### Absolute claims

No room for error. One counter-example makes them false. Research whether qualifications cure the issue in the applicable jurisdiction.

| Example | Fix pattern |
|---|---|
| "Never goes down" | "99.9% uptime" (with SLA that defines it) |
| "100% accurate" | A specific, substantiated percentage tied to a benchmark |
| "Guaranteed" | Only if you actually offer a guarantee with terms — this creates warranty exposure |
| "Always" / "Every" | "Typically" / "Most" |

## The review

### Step 1: Extract every claim

Read the copy. List every sentence or phrase that asserts a fact, makes a comparison, or promises something. Ignore pure puffery in the list.

### Step 2: Classify and check

For each claim:

```markdown
**Claim:** "[exact quote]"
**Type:** [Specific factual | Comparative | Implied | Absolute]
**Substantiation on file:** [Yes — link | No | Unknown]
**Call:** [✅ Fine | ⚠️ Needs substantiation | ⚠️ Needs rewording | 🔴 Cut]
**Suggested fix:** "[alternative phrasing that keeps the energy]"
**Why:** [one line]
```

### Step 3: Check against the product

Does the product actually do what the copy says? Not a philosophical question — check the PRD or ask the PM.

Common drift: marketing copy written from an early spec, product changed, nobody updated the copy.

### Step 4: Output

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# Marketing Review: [Campaign/Asset name]

**Reviewed:** [date]
**Asset:** [landing page / email / ad / etc.]

---

## Summary

[N] claims reviewed. [N]✅ [N]⚠️ [N]🔴

**Ready to ship:** [Yes | With changes below | No — rewrite needed]

> **Before emitting "Ready to ship: Yes" (i.e., approving a claim for external use / publication):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md`. If the Role is Non-lawyer:
>
> > Approving a marketing claim for publication is a legal act — once published, substantiation gaps and comparative-claim exposure become enforcement or competitor-challenge risk. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
> >
> > [Generate a 1-page summary: asset, claims approved, claim types (specific factual / comparative / implied / absolute), substantiation on file for each, any implied claims flagged, and the three things to ask the attorney before the copy goes live.]
> >
> > If you need to find a lawyer: your professional regulator's referral service is the fastest starting point (state bar in the US; SRA/Bar Standards Board in England & Wales; Law Society in Scotland/NI/Ireland/Canada/Australia; or your jurisdiction's equivalent).
>
> Do not proceed past this gate to "Ready to ship: Yes" without an explicit yes. "With changes below" and "No — rewrite needed" do not require the gate — those are review calls, not approvals.

---

## Claim-by-claim

[All the claim blocks from Step 2, grouped: 🔴 first, then ⚠️, then ✅]

---

## Suggested revision

[For short assets — under 50 words, or a tweet, headline, one-liner, tagline, short ad — the output in this block is the actual revised copy with the fixes applied inline, not a description of what changed. The reader should be able to copy-paste this block into the asset.
For longer assets (>50 words but <300 words), show the revised copy with fixes applied inline.
For longer assets (300+ words), summarize the changes as a bulleted diff ("Strip Claim 1. Rewrite Claim 3 to drop 'any.' Soften Claim 4 for regulated-domain risk.") rather than pasting the whole asset.
A meta-description of changes is never an acceptable output for a short asset — when the asset is one line, the output should BE the revised one line.]

---

## Substantiation needed before ship

| Claim | Need | From whom |
|---|---|---|
| [claim] | [data type] | [PM / data team / eng] |

---

## Citation check

Any FTC rules, NAD decisions, state UDAP statutes, sector regulations, or platform policies cited in this review were generated by an AI model and have not been verified against a primary source. Before relying on a specific rule to clear or reject copy, verify it against a legal research tool (Westlaw, CourtListener, or your firm's research platform) for accuracy and current effective date — endorsement guides, platform rules, and state UDAP regimes all update frequently. Source tags on each citation (e.g., `[FTC site]`, `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.
```

## Disclosure overlays

Copy that involves any of the fact patterns below sits inside an additional disclosure regime. Research the currently operative disclosure requirements in the applicable jurisdictions (including any platform policies and sector-specific rules) and verify currency — these regimes are updated frequently.

- **Testimonials / reviews** — material connections between the speaker and the advertiser are typically disclosable; research the current form and placement rules
- **Influencer content** — research the current tagging, clarity, and conspicuousness requirements for the channel and audience
- **"Results may vary" / atypical results** — research whether a disclosure (and what form) is required when shown results aren't representative
- **Free trial / auto-renewal / negative option** — research the current conspicuousness and consent requirements for auto-conversion terms

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't write the marketing. It fixes what's wrong with it. The suggested rewrites keep the energy, but the marketer owns the voice.
- It doesn't substantiate claims. It identifies which ones need it and who has the data.
- It doesn't review design or imagery — words only. If an image implies a claim (competitor logo with a red X through it), flag it, but visual review is a human judgment.$body$),
('marketplace:claude-for-legal/claude-for-legal/product-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/product-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/product-legal:matter-workspace list` — list matters with status and active flag
- `/product-legal:matter-workspace switch <slug>` — set the active matter
- `/product-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/product-legal/matters/_archived/`, never delete)
- `/product-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/product-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/product-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Apply the storage layout and subcommand logic below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/product-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/product-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/product-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- This skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

# Matter Workspace

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; the `/matter-workspace` command explains the disabled state and suggests `/cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/product-legal/
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
   - **Matter type** (read the plugin's practice profile for typical categories; for product-legal: launch | feature review | marketing claim review | risk deep dive | product area (standing) | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/product-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/product-legal:matter-workspace new <slug>`.
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
- **Decide whether cross-matter is appropriate.** It reads the flag and obeys.$body$)
ON CONFLICT (skill_key) DO NOTHING;
