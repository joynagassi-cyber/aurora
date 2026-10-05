INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/termination-review', 'legal', 'termination-review', '', 'termination-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /termination-review

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → termination review triggers, high-risk flags, severance practice, jurisdiction rules.
2. Use the workflow below.
3. Walk the checklist. Check every high-risk flag.
4. Final pay timing per employee's jurisdiction. Severance + release if applicable.
5. If any high-risk flag fires: escalate per table, don't proceed without sign-off.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Most terminations are fine. A few are lawsuits waiting to happen. This skill
runs the checklist that catches the second kind before the decision is final.
The skill does not state the law — every jurisdiction-specific rule and
release-period requirement is researched and cited at the time of review.

## Load context

`~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → termination review triggers, high-risk flags, standard severance,
jurisdiction table.

## Output header

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`). Match the memo format from seed term memos referenced in that config where one exists. The work-product header is always first.

## Workflow

### Step 1: The basic facts

- Employee name (or role if staying abstract)
- Jurisdiction (where they work)
- Reason for termination (performance, misconduct, RIF, position elimination)
- How long employed
- Age (relevant to release requirements for older-worker protections)
- Whether any other employees are being terminated as part of the same
  decisional unit or program (relevant to group-termination release rules)
- When is the planned term date

### Step 2: High-risk flag scan

This is the most important step. Check every flag from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. Default
set:

| Flag | Why it's high-risk | Check |
|---|---|---|
| **Recent complaint** | Retaliation claim | Has this employee filed any complaint (HR, ethics hotline, regulatory) recently? |
| **Protected leave** | Leave-law interference/retaliation | Currently on or recently returned from protected leave (FMLA/state equivalents, disability, parental, military)? |
| **Protected class + timing** | Discrimination claim | Protected class AND recently disclosed/visible (pregnancy announcement, religious accommodation request, disability disclosure)? |
| **Whistleblower** | Federal and state whistleblower statutes | Has this employee raised concerns about illegality, safety, fraud? |
| **Thin documentation** | "Why now?" problem | For performance terms: is there a PIP, written warnings, documented feedback? Or did this come out of nowhere? |
| **Comparator problem** | Disparate treatment | Is someone else doing the same thing and not being terminated? |
| **Contract/handbook promise** | Breach | Does the offer letter, handbook, or any writing promise a process that isn't being followed? |
| **Exempt misclassification** | FLSA + state wage claim with liquidated damages | See the classification check below. Fires on state + classification + title. |

**Exempt/non-exempt classification flag.** Fire this flag when ALL of the
following are true:

1. The employee works in a state with a high exempt salary threshold — **CA,
   NY, WA, CO, AK** (and any other state listed in
   `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` →
   `## Wage & hour` → Known classification risk areas as a high-threshold
   state) — **AND**
2. The employee is classified **exempt** (salaried, no overtime) — **AND**
3. The employee's title contains **"supervisor," "lead," "coordinator,"
   "analyst," "administrator,"** or **"specialist"** (case-insensitive, and
   any equivalent-scope title the practice profile flags as risky).

When all three fire, emit:

> 🔴 **Potential exempt misclassification** — [title] earning $[X] in
> [state]. The exempt salary threshold in [state] is approximately $[Y]
> `[model knowledge — verify]`. Before termination, route to
> `/employment-legal:wage-hour-qa` for a classification check — a misclassified
> employee who's terminated has a ready-made FLSA and state-wage claim with
> liquidated damages, attorneys' fees, and (in CA) PAGA exposure, which
> the separation agreement may not be able to release cleanly. A terminated
> plaintiff with unpaid-OT exposure is the most litigated wage-and-hour
> fact pattern in these states.

Do not suppress this flag because the title "looks managerial" — the whole
premise of the misclassification claim is that titles lie. Route to
`/employment-legal:wage-hour-qa` for the actual duties-and-salary test.

**If a back-pay number is being computed as part of this review (severance
modeling, settlement posture, exposure estimate), do NOT compute it in this
skill.** Route to `wage-hour-qa` → Step 2a and use its regular-rate
scaffold: §207(e) inclusions (non-discretionary bonuses, commissions,
shift diffs) in the regular rate, 0.5× premium when straight time was
already paid for OT hours (else 1.5×), liquidated damages under §216(b),
and 2-year / 3-year willful SOL under §255(a). Every back-pay number
carries `[verify — consult wage-and-hour counsel before asserting or
paying]`. A clean-looking wrong number here is the specific failure mode
this scaffold prevents.

**Any flag fires → escalate per `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` before the term proceeds.** Not
after. Before.

### Step 3: Jurisdiction-specific requirements

> **Research the applicable rules for the employee's jurisdiction before
> finalizing the plan.** Specifically:
>
> - Final-pay timing — this varies widely by state and often depends on
>   whether the employee was terminated or resigned. Research the currently
>   operative rule, including any waiting-time or late-pay penalties.
> - Accrued-PTO payout — research whether the jurisdiction requires payout,
>   and any interaction with accrual-cap or use-it-or-lose-it policies.
> - Required notices — research any jurisdiction-specific notices required at
>   termination (e.g., state unemployment, continuation-coverage notices
>   beyond federal COBRA, benefits continuation).
> - Mass-layoff / plant-closing notices — research federal WARN Act and any
>   state "mini-WARN" or local ordinance that may apply if this is part of a
>   larger reduction. Coverage thresholds and notice periods differ.
>
> Cite primary sources. Verify currency.
>
> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for the jurisdiction's final-pay, PTO, notice, or WARN rule, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [jurisdiction / rule]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) stop here and flag for attorney verification. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation in the plan — final-pay rule, PTO rule, notices, WARN / mini-WARN, OWBPA consideration periods, state release restrictions — with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the user supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

### Step 4: Severance and release

Per `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → standard severance:

- Is severance being offered? Per formula or discretionary?
- Release required? (Usually yes if paying severance — that's the
  consideration.)

> **Research the applicable release-consideration rules.** If the employee is
> 40 or over, federal law (OWBPA) imposes specific requirements that affect
> the consideration period, revocation period, required advisements, and —
> for group terminations — required decisional-unit disclosures. The specific
> consideration period differs between an individual termination, a group
> RIF, and a group exit incentive; the rule also depends on the employee's
> age and the number of employees affected. Do not state the day count from
> memory — research the currently operative rule for the specific situation
> and cite primary sources. Also research any state-law analogs or parallel
> release requirements. Verify currency.

Separately, consider whether any of the following apply to the release:
- State-specific waiver restrictions (some states limit what can be released
  or require specific language).
- Federal or state restrictions on non-disclosure or non-disparagement
  clauses that relate to sexual harassment, discrimination, or other
  protected categories.
- Separation-agreement rules on NLRA-protected activity.

### Step 5: Documentation check

For performance terminations especially:

- Is there a paper trail? Written warnings, PIP, feedback docs?
- Does the paper trail tell a consistent story?
- Is there anything in writing that contradicts the reason (recent positive
  review, bonus, promotion)?

The "why now" question: if this person has been underperforming for a year,
what changed? The answer should be documented.

## Output

> **Research-connector pre-flight.** Before emitting the memo, check whether a legal research connector is reachable for this session — Westlaw, CourtListener, or any firm-configured research MCP. Collect this into the reviewer note per CLAUDE.md `## Outputs`: if no connector returns results in Step 3 (or none is configured at run time), record it in the **Sources:** line of the reviewer note — e.g., `not connected — cites from training knowledge; the highest-fabrication topics in termination-law memos are final-pay timing, OWBPA group/individual distinctions, state-specific NDA / non-disparagement rules (e.g., CA SB 331), and NLRB positions (e.g., McLaren Macomb) — spot-check those first`. Per-citation `[model knowledge — verify]` tags remain inline. Do not emit a standalone banner above the memo.

> **Jurisdiction assumption.** This review assumes the employee's jurisdiction as stated in Step 1 and any defaults from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → Jurisdictional footprint. Employment rules, final-pay timing, release requirements, and notice obligations vary materially by jurisdiction. If the employee works in a different state or country, or if choice-of-law is contested, this analysis may not apply as written.

Match the memo format from seed term memos referenced in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If none:

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Termination Review: [Role/Name] — [Date]

**Jurisdiction:** [State]
**Reason:** [Performance / Misconduct / RIF / Elimination]
**Planned date:** [Date]

---

### Bottom line

[Can you proceed / Need to fix X first / Stop — one-sentence why]

---

### High-risk flags

[Every flag from Step 2. ✅ Clear or 🔴 FLAG with detail.]

**Escalation:** [None needed | Escalate to [name] before proceeding — [which flag]]

---

### Jurisdiction requirements ([State])

- Final pay: [researched rule and cite; state whether PTO is included per the
  researched rule and any team policy]
- Required notices: [list, each researched and cited]
- Mass-layoff notice (if applicable): [researched rule and cite]

---

### Severance and release

- Severance: [amount per formula / none]
- Release: [required / not — if required, research and apply the
  consideration-period, revocation-period, advisement, and (for groups)
  decisional-unit-disclosure requirements that govern this specific
  situation; cite primary sources and verify currency]
- [Any state-law release rules or non-disclosure/non-disparagement
  restrictions that apply]

---

### Documentation

[Assessment of paper trail. Gaps flagged.]

---

### Go / No-go

[Clear to proceed | Proceed with changes below | Hold — escalation pending]

### Checklist for term day

- [ ] Final paycheck ready, correct amount, delivered per researched rule
- [ ] Continuation-coverage notices (COBRA / state analogs) prepared
- [ ] [State] unemployment notice prepared
- [ ] Severance agreement (if applicable) with the consideration period
      required for this specific situation
- [ ] Return of property / access cutoff coordinated
- [ ] [etc.]
```

## Consequential-action gate (terminate an employee)

**Before producing a "Go" recommendation or a term-day checklist marked ready:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Terminating an employee has legal consequences — wrongful-termination, discrimination, retaliation, and wage-law claims all trace back to how this decision is structured. Have you reviewed this termination with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - Employee, jurisdiction, reason, planned date
> - Every high-risk flag the review surfaced (recent complaint, protected leave, protected class + timing, whistleblower, thin documentation, comparator, contract/handbook promise) — with detail
> - Jurisdiction-specific findings (final pay, PTO, required notices, mass-layoff rules) and where they were cited from
> - Severance/release analysis, including any OWBPA/older-worker-protection angles
> - Open questions and what's unresolved
> - What could go wrong (the claim theory this fact pattern supports)
> - What to ask the attorney (is this a clean term; do we need more documentation first; does the release need specific language; do we need to stagger decisional units)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service. Employment is one of the practice areas where a short consult before the termination meeting consistently outvalues a post-termination claim defense.

Do not produce a "Clear to proceed" output past this gate without an explicit yes. A marked-DRAFT flagged for attorney review is fine.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- Make the termination decision. It checks the decision.
- Have the conversation. The manager does that.
- State release or jurisdiction rules from memory — every rule is researched
  and cited at the time of review.
- Guarantee no lawsuit. It reduces the risk by catching the obvious problems.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/wage-hour-qa', 'legal', 'wage-hour-qa', '', 'wage-hour-qa', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /wage-hour-qa

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint.
2. Use the workflow below.
3. Identify jurisdiction the question is about. If not specified, ask.
4. Answer per that jurisdiction's rule. Cite. Flag if it's a close call or law is shifting.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

"It depends" is true but unhelpful. This skill produces a jurisdiction-specific
answer grounded in researched, cited primary sources — and flags when the
question is close enough to need human judgment. It does not state rules from
memory: wage-and-hour thresholds, exemption criteria, and final-pay timing
change frequently and vary meaningfully by state.

## Load context

`~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint. If the question doesn't specify a
jurisdiction, ask — or answer for the state with the most employees and note
that.

## The answer

### Step 1: Jurisdiction

Which state/country is this about? If not stated:
- If it's about a specific employee: where do they work?
- If it's a policy question: identify the jurisdictions in the footprint that
  are most likely to be the most restrictive on the question at hand, then
  research those.

### Step 2: Research the rule, then state it

> **Research before answering.** For the jurisdiction and question, identify
> the currently operative rule. Cite the controlling primary source (statute,
> regulation, wage order, or case) with a pinpoint cite. Note the effective
> date and whether the rule has been recently amended, indexed, or is in
> litigation. If you are uncertain or cannot verify the current state of the
> law, say so and flag for attorney verification — do not state a rule you
> haven't confirmed.

State the rule in one paragraph, tied to the cite. Use your tools (web search,
legal research integrations, team reference materials) to verify currency —
especially for:

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, or firm platform) returns few or no results for the jurisdiction-and-question, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [jurisdiction / question]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag the question as unverified and stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation in the answer with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the user supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.


- Salary thresholds for any exemption (federal and state — several states
  index annually and several have tiered thresholds by employer size).
- Final-pay timing on termination vs. resignation (many states differ).
- PTO payout requirements (jurisdiction-specific; some require, some leave
  it to policy, some depend on accrual-plan design).
- Meal and rest break rules and any penalty-pay consequence.
- Daily or weekly overtime rules (some states have daily overtime and
  double-time rules that federal law does not).
- Classification tests — see the worker-classification skill; the applicable
  test depends on jurisdiction and purpose.

Common question types you may be asked — for each, the answer is
jurisdiction-specific and time-sensitive. Do not state the rule here; route
to research:

- "Is this role exempt?" — Research the applicable federal and state salary
  thresholds (verify current amounts and any employer-size tiers) and the
  applicable duties test(s).
- "Do we have to pay overtime for X?" — Research federal FLSA overtime plus
  any state-specific overtime rules (daily OT, double-time, alternative
  workweeks).
- "Do we have to provide meal/rest breaks?" — Research the applicable
  state rule and any penalty-pay consequence for missed breaks.
- "When is final pay due?" — Research the applicable state rule, including
  whether timing differs for termination vs. resignation and whether
  waiting-time or late-pay penalties apply.
- "Do we have to pay out accrued PTO?" — Research the applicable state rule
  and any carve-out for accrual-cap or use-it-or-lose-it policies.
- "Can we classify this person as a contractor?" — Route to
  `/employment-legal:worker-classification` if the facts are not already clear.

### Step 2a: FLSA regular-rate and back-pay calculations

When the question is a back-pay computation, unpaid-OT computation, or any
question that turns on the FLSA "regular rate," use this scaffold. Do not
answer from bare hourly wage × OT hours; that's the two most common errors
this skill exists to catch.

**The regular rate is NOT just the hourly wage.** Under 29 U.S.C. §207(e),
the regular rate is **all remuneration** for employment EXCEPT the eight
statutory exclusions in §207(e)(1)–(8) (e.g., discretionary bonuses, gifts,
premium pay, expense reimbursements, profit-sharing plans meeting the DOL
regs, stock options meeting §207(e)(8), retirement/insurance contributions).
Anything NOT within those eight exclusions is IN.

1. **Non-discretionary bonuses are IN the regular rate.** Productivity
   bonuses, attendance bonuses, commissions, shift differentials, contest
   awards, and most "bonuses" a reasonable employee would expect as a matter
   of course are non-discretionary under §207(e)(3) and 29 C.F.R. §778.211.
   Divide the bonus by the total hours worked in the bonus period to get
   the per-hour increase to the regular rate. True discretionary bonuses
   (§207(e)(3)) require both the fact of payment AND the amount to be
   within the employer's sole discretion, determined at or near the end of
   the period — narrow category.
2. **The unpaid OT premium is 0.5×, not 1.5× — when straight time was
   already paid for all hours.** If the employee was paid straight time for
   every hour (including the OT hours) but no premium, they are owed the
   **half-time premium** on OT hours, not time-and-a-half: `unpaid OT =
   0.5 × regular rate × OT hours`. 29 C.F.R. §778.110(b). If the employee
   was NOT paid for the OT hours at all, the owed amount is 1.5× the
   regular rate on those hours. **State which pay posture you're assuming
   before you compute** — it determines 0.5× vs. 1.5× and is the most
   common error in this computation.
3. **Show your math.** Print the formula and the inputs explicitly:
   ```
   Regular rate    = (straight-time wages + non-discretionary bonuses + other non-excluded comp) ÷ total hours worked
   OT premium owed = 0.5 × regular rate × OT hours    [if straight time already paid for OT hours]
                   = 1.5 × regular rate × OT hours    [if OT hours were unpaid]
   ```
   A number without the formula is not usable by a wage-and-hour lawyer.
4. **Liquidated damages double the back-pay.** 29 U.S.C. §216(b). Liquidated
   damages equal the unpaid back-pay amount unless the employer proves, to
   the court's satisfaction, that the violation was in good faith and based
   on reasonable grounds to believe it was not a violation. 29 U.S.C.
   §260. Default assumption is liquidated damages apply; the employer bears
   the burden to avoid them.
5. **Statute of limitations is 2 years; 3 for willful.** 29 U.S.C. §255(a).
   State the lookback explicitly and compute both bookends unless the
   willfulness posture is already established by the user.
6. **State overlay.** Many states have longer lookback, higher overtime
   multipliers (daily OT, double-time), and different regular-rate rules.
   Check state wage-and-hour law against the jurisdiction gate from Step 1
   and flag where state law compounds (higher cap) or replaces (different
   rate) federal. California, New York, Massachusetts, and Washington are
   the most frequent overlay hits.
7. **Attach the verify tag to the number.** Any back-pay amount produced by
   this skill carries `[verify — consult wage-and-hour counsel before
   asserting or paying]` on the line the number appears. The computation is
   specialist work; the skill is scaffolding, not opinion.

If the question is a back-pay calculation and any of these inputs are
missing (bonus breakdown, whether straight time was paid for OT hours,
willfulness posture, state jurisdiction), **ask before computing**. A
confident wrong number is the worst output this skill can produce.

### Step 3: The flag

Is this a close call? Be honest.

- If the answer is clear on the researched rule: say so. "Exempt — meets
  each element of the applicable duties test and the current salary
  threshold."
- If it's close: say so. "The duties test is borderline — this role could
  go either way. Recommend classifying as non-exempt to be safe, or getting
  a formal opinion."
- If the law is in flux: say so. "This rule has been amended recently — the
  current version takes effect [date]. Confirm effective date before relying
  on this answer."
- If you could not verify currency: say so. Do not guess.

## Output format

Conversational. This is a Q&A, not a memo.

> **Research-connector pre-flight.** Before emitting the answer, check whether a legal research connector is reachable for this session — Westlaw, CourtListener, or any firm-configured research MCP. Collect this into the reviewer note per CLAUDE.md `## Outputs`: if no connector returns results in Step 2 (or none is configured at run time), record it in the **Sources:** line of the reviewer note — e.g., `not connected — cites from training knowledge; pinpoint cites (volume/page/subsection) carry the highest fabrication risk, spot-check those first`. Per-citation `[model knowledge — verify]` tags remain inline. Do not emit a standalone banner above the output.

> **Jurisdiction assumption.** Answers apply only to the jurisdiction identified. Wage-hour rules, exemption thresholds, and final-pay timing vary materially by state and country, and many rules index or change year over year. If the employee works in another jurisdiction, or the question is answered for the default-footprint state, this answer may not apply as written.

```
**[Jurisdiction]:** [The researched rule, one paragraph, with pinpoint cite
and currency note.]

[If close call or shifting law: the flag.]

[If the answer differs in other footprint jurisdictions: one line noting that,
and whether the differences are material.]
```

> **Verify citations.** Any case, statute, regulation, or wage-order cite above was generated with AI assistance. Before relying on a cite, check it against Westlaw, CourtListener, the relevant state agency's site, or your firm's research tool for accuracy, currency, and subsequent history. Fabricated or misquoted citations in filings or formal advice have resulted in sanctions.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- State the rule from memory — every answer is grounded in a researched,
  cited primary source verified for currency.
- Make classification decisions for borderline cases. It states the rule and
  flags the close call. Human decides.
- Give a 50-state survey unless asked. Answers for the relevant
  jurisdiction(s).
- Track when the answer changes. If thresholds index or law shifts, the
  answer goes stale. Re-ask for current.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/worker-classification', 'legal', 'worker-classification', '', 'worker-classification', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /worker-classification

Runs the applicable classification tests for the jurisdiction and flags where
the proposed arrangement doesn't match the structure you're trying to use.
Prospective only — for existing relationships, consult counsel.

## Instructions

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, escalation table.
2. Run the full workflow below.
3. If the attorney provides details upfront, extract what's available and ask
   only about the gaps. Do not re-ask information already provided.

## Examples

```
/employment-legal:worker-classification
We want to bring on a data scientist for 6 months, working out of our
SF office, using our tools, embedded in our analytics team.
```

```
/employment-legal:worker-classification
Is our recruiter contractor arrangement okay? She works exclusively for
us, sets her own hours, uses her own laptop, project fee per placement.
```

```
/employment-legal:worker-classification
(skill will ask for details)
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

The most expensive classification decision is the one nobody made consciously.
Someone describes what they want ("a contractor"), the engagement starts, and
two years later the facts look like employment. This skill walks the applicable
tests on the proposed arrangement before it starts — and tells you when what
you're describing doesn't match the structure you're trying to use.

This skill teaches the reasoning pattern. It does not state the law. Every
test formulation, statutory citation, threshold, and carve-out must come from
current research for the applicable jurisdiction.

## Prospective-only hard gate — run BEFORE intake

**This skill analyzes a PROPOSED engagement before the work starts.** Before any substantive intake (Step 1), ask:

> Has this work already started? Is the worker currently engaged, or have they been performing work under this arrangement for any period of time (days, weeks, months, or years)?

If the answer is yes — the engagement already exists, in any form, for any duration — **STOP**. Do not proceed to Step 1 intake. Classifying an existing arrangement is not a planning exercise; it's a liability assessment with remediation implications: back pay (OT, meal/rest premiums), unpaid employer-side payroll tax, benefits eligibility that was denied, unemployment and workers' comp back-exposure, state penalties (in CA, PAGA), IRS § 530 relief analysis, and — in strict-test jurisdictions with ongoing work — the prospective exposure of letting it run another day. That analysis is privileged, led by counsel, and coupled with a remediation plan.

Output exactly this block and wait for a response:

> **Out of scope — existing arrangement.**
>
> This skill is designed to analyze a worker engagement *before it starts*, so the classification choice informs how to structure the contract and operations. You've described an arrangement that already exists. Analyzing an existing engagement retroactively is a different exercise: reclassification risk assessment coupled with remediation planning — back-pay exposure, payroll-tax back-exposure, penalty exposure, benefits exposure, IRS § 530 relief analysis, and prospective restructuring. That work should be privileged, led by an attorney, and likely coupled with outside-counsel review given the dollar and enforcement exposure.
>
> Recommended next step: escalate per your config's escalation table (for retroactive classification, this typically routes to GC + outside employment counsel). I've flagged this for escalation routing.
>
> **If you want to proceed with the prospective-style analysis anyway for planning purposes, say "proceed anyway" — but understand:**
>
> - The output is NOT a remediation plan and should not be treated as one.
> - The output does NOT scope back-pay, penalty, or payroll-tax exposure for the period already worked.
> - The output does NOT substitute for the reclassification-risk assessment that this fact pattern actually calls for.
> - The output will carry a prominent banner reflecting this scope mismatch, and the consequential-action gate will require an attorney yes before the analysis is treated as reliable.
>
> Only say "proceed anyway" if you're using this skill for forward-looking planning (e.g., "if we were structuring this fresh today, how should we think about it?") and you have a separate plan for the remediation question.

**Only proceed past this gate with an explicit `"proceed anyway"` (or equivalent user instruction). A hesitant "I guess" does not count — re-prompt. If the user proceeds anyway, prepend this banner to every output of this skill for this session:**

```
⚠️ SCOPE MISMATCH — OUT-OF-SCOPE USE
This skill analyzes prospective worker engagements. The arrangement here
already exists. This output is the prospective-style analysis the user
requested for planning purposes only — it is NOT a remediation plan, does
NOT scope existing back-pay / penalty / payroll-tax exposure, and does
NOT substitute for the reclassification-risk assessment this fact pattern
requires. The remediation question has been flagged for escalation to
counsel per your config's escalation table.
```

If the answer to "has this work already started?" is no (the engagement is genuinely prospective, not yet begun), proceed to load context.

---

## Load context

Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, any classification history or
prior settlements noted, escalation table, and any house classification
policy the team has recorded.

## Output header

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`).

## Workflow

### Step 1 — Information gathering

Ask all of the following in a single block. Do not drip questions one at a
time. Briefly explain why you're asking — attorneys answer better when they
understand what the question is testing.

> To run the right classification tests I need to understand the proposed
> arrangement in detail. Please answer as many of these as you can — the more
> complete the picture, the more accurate the analysis:
>
> **The work**
> - What will this person actually do day-to-day?
> - Is this work part of your company's core business, or peripheral to it?
>   (e.g., a software engineer at a software company = core; an IT
>   contractor at a law firm = more peripheral)
> - Is this a defined project with a clear end, or ongoing indefinite work?
> - How specialized is the skill? Does this person have expertise your team
>   doesn't?
>
> **Control**
> - Who sets their hours and schedule — them or you?
> - Where will they work — your office, their location, or either?
> - Will you direct how they do the work (methods, process, sequence), or
>   just what the end result should be?
> - Will they supervise any of your employees?
>
> **Economics**
> - How will they be paid — hourly, daily, or fixed project fee?
> - Will you provide equipment, tools, or software, or do they use their own?
> - Do they work for other companies, or will this be exclusive?
> - Will they bear any financial risk — can they profit beyond the fee, or
>   lose money on the engagement?
> - Do they have their own business entity (LLC, S-corp, sole proprietor)?
>
> **The arrangement**
> - How do you want to structure this — direct contractor, staffing agency
>   temp, or vendor/SOW (company-to-company)?
> - If staffing agency: who pays the worker — the agency or you? Who controls
>   day-to-day work?
> - Will there be a written contract? Do you have a template in mind?
> - Roughly how long is the engagement — weeks, months, over a year?
> - Will they work alongside your employees doing similar work?
>
> **Purpose(s) of the classification**
> - What legal purposes does the classification need to serve — federal
>   payroll tax, FLSA wage/hour, state wage/hour, unemployment insurance,
>   workers' compensation, benefits eligibility? Different purposes are often
>   governed by different tests, and the answers can diverge.
>
> **Jurisdiction**
> - Where will this person physically perform the work?

Wait for responses before proceeding. If the attorney can't answer certain
questions, note the gaps — they affect the analysis.

### Step 2 — Identify the applicable tests

> **Research the applicable tests before proceeding.** For the jurisdiction(s)
> and purpose(s) identified in intake, research the currently operative
> classification test(s). Jurisdictions commonly use one or more of: an ABC
> test, an economic-realities test, a common-law right-to-control test, a
> hybrid, or a purpose-specific statutory test. The test that governs for
> federal payroll tax may not be the same test that governs for state
> wage/hour, unemployment, or workers' compensation — run each purpose on its
> own track. Cite the controlling statute, regulation, or case. Note the
> effective date of each rule and whether it has been recently amended.
> Identify any carve-outs or exceptions that may apply (e.g., B2B,
> professional services, construction, referral-agency, business-to-business
> contracting relationship). Verify currency. If you are uncertain about the
> current state of the law in any jurisdiction, flag it for attorney
> verification — do not state a test you haven't confirmed.

If `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` records the company's house classification policy, apply it
first and flag any tension with the researched test.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a jurisdiction-and-purpose combination, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [jurisdiction / purpose / test]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation — each classification test, statute, regulation, or case — with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the attorney supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

### Step 3 — Apply the researched tests to the facts

For each test identified in Step 2, apply it to the intake facts. Score each
factor or prong explicitly — do not summarize. The attorney needs to see which
factors are clean and which are problems.

Use a structure like the one below, but populate the *factors* from the
researched test, not from this file:

```
Test: [name of test, per research]
Purpose: [what this test governs — federal tax / state wage-hour / UI / etc.]
Source: [pinpoint cite to statute/regulation/case]
Currency: [verified as of date]

| Factor / prong | Intake facts | Signal / pass-fail |
|---|---|---|
| [Factor 1 from researched test] | [from intake] | [direction or pass/fail] |
| [Factor 2] | [from intake] | [direction or pass/fail] |
| ...                            |                |                   |

Structure of the test:
[How the test weighs factors — e.g., a multi-factor balancing test, or a
conjunctive test where each prong must be satisfied, or a hybrid. State this
from research, not from memory.]

Result under this test:
[Employee-leaning / IC-leaning / Fails prong X / Uncertain — contested prong]
```

Repeat for each applicable test.

**Notes on contested prongs.** Some prongs of some tests are heavily contested
in case law and fact-sensitive. Identify contested prongs explicitly — do not
paper over them. The fact that a test is stated does not mean its application
to these facts is settled; flag prongs that require attorney judgment or that
have generated recent litigation in the jurisdiction.

### Step 4 — Classify and flag gaps

**The classification call**

Based on the test results, state the most accurate classification for this
proposed arrangement:

- **Employee (W-2):** Facts support employment under one or more applicable
  tests for the relevant purpose(s).
- **Independent Contractor (1099):** Facts support IC status under all
  applicable tests for the relevant purpose(s).
- **Temp via staffing agency:** Worker will be on the agency's payroll;
  company is a client — co-employment risk exists if company exercises
  day-to-day control. Research the applicable joint-employer standard if
  relevant.
- **Vendor/SOW:** Company-to-company engagement; worker is employed by the
  vendor entity — cleanest structure if facts support it.
- **Unclear / close call:** Facts cut both ways under one or more tests —
  state which test is the problem and why.

If tests give different answers for different purposes (e.g., defensible as
IC for federal tax but fails a state wage/hour test), say so explicitly and
name the controlling purpose and jurisdiction.

**The gap analysis**

This is the most important output. Compare the intended structure against what
the facts actually support:

```
Intended structure: [what they said they want]
What the facts suggest: [what the researched tests say this actually is]

Gaps — where the arrangement doesn't match the intended structure:
🔴 [Factor]: [What they described] conflicts with [intended classification]
   because [specific researched test language + cite]. This is a significant
   misclassification risk if the engagement proceeds as described.
🟡 [Factor]: [What they described] is a weaker point under [test]. Not
   disqualifying alone, but combined with other factors increases risk.
✅ [Factor]: Supports [intended classification]. No issue.
```

**Escalation trigger**

Escalate per `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` if any of the following, or any team-specific
triggers recorded in that config:
- The jurisdiction uses a strict test and the proposed work is core to the
  company's business — do not proceed without counsel review.
- Prior misclassification settlement or audit noted in the config — heightened
  scrutiny applies.
- Worker will supervise employees or have significant budget authority.
- Engagement expected to exceed 12 months with no clear project endpoint.
- Any contested prong where the outcome changes the classification.

### Step 5 — Output

> **Research-connector pre-flight.** Before emitting the analysis, check whether a legal research connector is reachable for this session — Westlaw, CourtListener, or any firm-configured research MCP. Collect this into the reviewer note per CLAUDE.md `## Outputs`: if no connector returns results in Step 2 (or none is configured at run time), record it in the **Sources:** line of the reviewer note — e.g., `not connected — cites from training knowledge; the highest-fabrication pinpoints in classification analyses are ABC-test codifications, state carve-out subsections (e.g., CA Lab. Code §§ 2775/2776/2783), element counts in B2B exemptions, and purpose-specific test selection — spot-check those first`. Per-citation `[model knowledge — verify]` tags remain inline. Do not emit a standalone banner above the output.

> **Jurisdiction assumption.** This analysis applies the tests operative in the jurisdiction(s) identified in intake. Classification rules vary materially by state and country, and the test that governs for one purpose (e.g., federal payroll tax) often differs from the test that governs another (e.g., state wage/hour). If the work will be performed in a jurisdiction not analyzed here, or if a new purpose is added later, this analysis may not apply as written.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Worker Classification Analysis
**Proposed arrangement:** [what they described]
**Jurisdiction:** [state/country]
**Purpose(s):** [federal tax / state wage-hour / UI / WC / benefits]
**Tests applied:** [list, each with pinpoint cite and currency date]

---

### Bottom line

[Can you proceed / Need to fix X first / Stop — one-sentence why]

---

### Classification

**Closest classification:** [Employee / IC / Temp via agency / Vendor-SOW / Unclear]

[One paragraph summary of why — test results in plain language, tied to the
cited sources.]

---

### Test results

#### [Test name — per research]
Purpose: [...] | Source: [...] | Currency: [...]
[Scored table from Step 3]
**Result:** [Employee-leaning / IC-leaning / Fails prong X / Mixed]

#### [Additional researched tests — repeat the block]

---

### Gap analysis

[Flags as structured in Step 4 — 🔴 significant risks, 🟡 weaker points,
✅ clean factors]

---

### Escalation

[None needed | Escalate to [name] before proceeding — [reason]]

---

### Next steps

[If IC viable: "Proceed — ensure the written agreement reflects the terms that
support IC status under the researched test."]
[If gaps exist: "Address the following before using IC structure: [list]"]
[If agency/vendor is cleaner: "Consider restructuring as [agency/SOW] — here's
why it's cleaner for this fact pattern."]
[If escalation needed: "Do not proceed until counsel reviews the [specific
issue]."]
[If employee confirmed: "Classification confirmed as W-2 employee — run
`/employment-legal:hiring-review` to review the offer letter, restrictive
covenants, and jurisdiction-specific requirements."]
[If IC confirmed: "Classification confirmed as independent contractor — no
offer letter review needed. Ensure the written agreement reflects IC-supporting
terms before the engagement starts."]
[If agency/vendor: "Engagement should be structured through [agency/vendor
entity] — coordinate with them on worker agreement. No `/hiring-review` needed."]
```

## Consequential-action gate (classify a worker)

**Before producing a "Proceed as IC / employee / agency / vendor" final recommendation:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Classifying a worker has legal consequences — misclassification exposes the company to back wages, taxes, benefits, penalties, and private-action risk, and in several states is strict-liability. Have you reviewed this classification call with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - The arrangement (work, control, economics, structure) as described
> - Jurisdiction and which tests were applied
> - Test-by-test results with cites and currency
> - Gap analysis (🔴 / 🟡 / ✅) with the weak prongs called out
> - Open questions and what's unresolved
> - What could go wrong (the misclassification theory this arrangement most likely fails on; prior-audit/settlement overlay if any)
> - What to ask the attorney (is IC viable here; would restructuring through an agency or vendor remove the risk; what contract terms do we need to support the classification)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not produce a final "IC viable" / "use this classification" output past this gate without an explicit yes. A marked-DRAFT analysis for attorney review is fine.

---

## What this skill does NOT do

- Analyze an existing relationship retroactively — this is prospective only.
- Draft the contractor agreement or SOW.
- Advise on remediation if misclassification has already occurred.
- State the law for any jurisdiction on its own — every test, factor, and
  carve-out must come from verified current research.
- Substitute for outside counsel on close calls — strict-test jurisdictions,
  contested prongs, and prior-audit situations should always get a human
  review before the engagement starts.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/external_plugins/cocounsel-legal/skills/deep-research', 'legal', 'deep-research', '', 'deep-research', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Westlaw Deep Research

Westlaw Deep Research searches Westlaw's database of caselaw, statutes, and administrative decisions and returns a written research report that explains, analyzes, or synthesizes relevant authority.

Deep Research employs an agentic process that mirrors the methodology of human researchers, utilizing Westlaw's proprietary tools to systematically analyze the trusted content available on Westlaw and Practical Law.

This skill will autonomously run the full research cycle: start, poll, report.

## Prerequisites

The `cocounsel-legal` MCP server must be connected. Verify it is available before starting research. If the server is not connected, inform the user and stop.

## When to Use

- Use for any questions answerable from caselaw, statutes, regulations, administrative materials, secondary sources, Practical Law documents and Current Awareness materials, including JD Supra. Examples include:
- How courts have ruled on an issue or what authority supports or challenges a position
- The elements or defenses of a claim, or the governing standard for an issue in a particular jurisdiction
- How a statute, regulation, or doctrine is being interpreted and applied
- The arguments on both sides of an unsettled question

## When Not to Use

- If the request falls into one of the categories below, briefly explain that this skill isn't the right fit and point the user to the suggested alternative.
  - **Retrieving the full text of a specific document**
    - _Instead:_ Suggest the traditional search box on Westlaw.
  - **Summarizing what a specific statute, regulation, or treatise says on its own** (e.g., "what does the California Evidence Code say about hearsay?")
    - _Instead:_ Suggest the traditional search box on Westlaw.
  - **Analytics requests** ("How often has Justice Scalia ruled in favor of…?")
    - _Instead:_ Suggest Litigation Analytics on Westlaw.
  - **Calculations** ("What is the last possible filing date if…?")
    - _Instead:_ This request is out of scope of Westlaw Deep Research
  - **Outcome predictions**
    - _Instead:_ This request is out of scope of Westlaw Deep Research
  - **Drafting legal documents, forms, or templates**
    - _Instead:_ Suggest CoCounsel
  - **Information about specific judges, attorneys, or parties**
    - _Instead:_ Suggest Litigation Analytics on Westlaw
  - **Foreign or non-U.S. law**
  - _Instead:_ Suggest country-specific version of Westlaw, such as Westlaw UK or Westlaw Canada, or use Westlaw International
  - **Comparisons across more than three jurisdictions**
    - _Instead:_ Suggest AI Jurisdictional Surveys on Westlaw
  - **Terms and Connectors (boolean) search queries**
    - _Instead:_ Suggest the traditional search box on Westlaw
  - **Commands for execution of tasks**
    - _Instead:_ Suggest CoCounsel
  - **Obtaining an exhaustive list of results**
    - _Instead:_ Suggest Boolean search or Precision Research on Westlaw
  - **Identifying potential causes of action**
    - _Instead:_ Suggest Claims Explorer on Westlaw.
  - **An exhaustive review of fact patterns** (e.g., "Find all cases discussing...")
    - _Instead:_ Suggest Precision Research on Westlaw.
- If you suggest an alternative, do not attempt to use the Deep Research skill further for that task.

## Communication Rules

- Never mention tool calls, tool-call budgets, polling, status checks, internal limits, conversation IDs, percent_complete, or any other implementation details to the user. Always speak about the research itself, not the mechanics of how you are tracking it.
- If you need to pause before the research completes (for any internal reason), do NOT explain why.
- Let the user know that research is ongoing and that a report will be completed soon.

## Research Workflow

### 1. Frame the query

- Extract the legal research question from the user's query using clear, natural language.
- Use up to three jurisdictions if the user names them.
- If no jurisdictions are mentioned, ask the user which jurisdiction(s) to use.

### 2. Start Research

- Call the MCP tool to initiate the research: `legal_research_start_deep_research(query, jurisdictions)`
- Parameters:
  - `query` (string, required): The legal research question
  - `jurisdictions` (list of strings, optional): Up to 3 jurisdictions (e.g., ["California", "New York"])
- This returns a `conversation_id` and initial `status`. Save the `conversation_id` for subsequent calls.
- Next step: call check_deep_research_status with the conversation_id.
- Before the first status check, wait ~10 seconds (the server is still setting up).

#### Rendering

- Inform the user that deep research is underway, briefly restating the legal question in natural, professional language.
- Do not show the conversation_id to the user.

### 3. Poll for Completion

- Poll `legal_research_check_deep_research_status(conversation_id)`.
- Always run a Bash `sleep` between polls. Never call check_deep_research_status back-to-back without sleeping.
- Continue until `is_terminal` is true.
- Decide the next action based on the response:
  - (1) If is_terminal is true and status is 'complete', call get_deep_research_report with the conversation_id.
  - (2) If status is 'failed', stop and report the error_type and failure_reason to the user in plain language, without exposing field names.
  - (3) Otherwise, sleep for the duration in the response's `next_action_poll_backoff_ms` field (milliseconds), then poll again.
- If percent_complete has not changed across two consecutive checks, add 5 seconds to the sleep.

#### Rendering

- Communicate in plain language as if narrating the research process.
- Render research_plan as a markdown unordered list (one item per line, each line prefixed with '- '), so the steps display with clear visual separation.
- Insert a blank line before and after the list so it renders cleanly.
- Only update the user when there is something new to say (a step completed, or a new step started). Do not repeat the same status.

### 4. Retrieve and Present Report **Verbatim**

- Once status is "complete", fetch the final report: `legal_research_get_deep_research_report(conversation_id)`
- The report is the `answer_text` field
- This is the final output of the research lifecycle. No further tool calls are required.
- If the user asks a follow-up question on the same topic, use follow_up_deep_research with the same conversation_id rather than starting a fresh research session.

#### Rendering

- Paste the contents of `answer_text` into your response with no edits, additions, removals, or restructuring. The payload contains markdown, HTML anchors, inline anchor citations, blockquoted source excerpts, and horizontal rules — every element is intentional and must remain.

## Helpful information

If the system fails or the user has questions about access, share the following:

- Support email: cocounselsupport@tr.com
- Subscription required: CoCounsel Legal subscription with the MCP connector enabled for the user's account. Direct entitlement or access questions to cocounselsupport@tr.com.
- Provider: Thomson Reuters
- Relevant policies:
  - Privacy: https://www.thomsonreuters.com/en/privacy-statement.html
  - Terms: https://www.thomsonreuters.com/en/terms-of-use.html
  - Accessibility: https://www.thomsonreuters.com/en/policies/accessibility.html$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/cease-desist', 'legal', 'cease-desist', '', 'cease-desist', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cease-desist

Two modes. Pick one:

- `/ip-legal:cease-desist --send` — draft a cease-and-desist letter calibrated to your enforcement posture. Loud gate runs before delivery.
- `/ip-legal:cease-desist --receive` — triage a C&D someone sent you. Produces an options memo with a recommendation.

## Instructions

1. **Read the practice profile.** Load `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it contains `[PLACEHOLDER]` markers or does not exist, stop and say: "This plugin needs setup before it can give you useful output. Run `/ip-legal:cold-start-interview` — the C&D skill depends on your enforcement posture, approval matrix, and practice-area mix, none of which are configured yet."

2. **Check matter workspaces.** Per `## Matter workspaces`: if `Enabled` is `✗`, skip — skills use practice-level context. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`."

3. **Dispatch on `$ARGUMENTS`:**
   - If `--send` is present: run send mode (below). Walk through identify-the-right, identify-the-conduct, identify-the-relationship, identify-the-demand, calibrate-to-posture, draft, and the pre-delivery gate.
   - If `--receive` is present: run receive mode (below). Ask for the incoming letter (path or pasted text), then assess, identify exposure, present options, and write the triage memo.
   - If neither flag is present: ask once — "Are we sending a cease-and-desist (you're asserting) or triaging one we received (you're defending)?" — and then dispatch.

4. **Respect the gate.** In send mode, the loud gate runs before any final draft is written to disk. Do not skip it.

5. **Respect the approval matrix.** Pull the approver for the C&D row from `## Enforcement posture → Approval matrix`. Pull automatic escalations. Surface both in the gate; do not smother them.

6. **Hand off where appropriate.** In receive mode, if the recommendation is to respond firmly, offer to chain into `/ip-legal:cease-desist --send` pre-populated with the response context. If the recommendation is to pre-empt with a DJ action or TTAB cancellation, escalate to outside counsel per the practice profile's IP litigation row — do not draft.

## Examples

```
/ip-legal:cease-desist --send
/ip-legal:cease-desist --receive ~/Downloads/incoming-cd-acme.pdf
/ip-legal:cease-desist
```

## Notes

- The outgoing C&D does not carry the work-product header. The internal draft, the pre-send brief, and the triage memo do.
- Trademark rights are territorial; the draft assumes the jurisdictions declared in your practice profile's `Registered in:` footprint. If the conduct or counterparty is somewhere else, flag before drafting.
- Every `[CITE:___]` is unverified until a citator run. Source attribution tags stay on the draft.
- Non-lawyer users get a one-page brief for the attorney conversation before the gate clears.

---

## Purpose

A cease-and-desist letter asserts a legal right and demands that someone stop doing something. It is one of the most consequential letters an IP practice sends or receives. Sending one is a first step toward litigation — recipients can file a declaratory judgment action in a forum of their choosing, and overbroad or bad-faith assertions can be used against the sender. Receiving one starts a clock and forces a decision. This skill handles both sides with the guardrails the decision deserves.

Two modes:

- `--send` — you are asserting. Draft a C&D calibrated to the posture, gate before delivery.
- `--receive` — you are defending. Triage the incoming letter, produce an options memo, route to matter creation if warranted.

If the user does not pass a flag, ask once: "Are we sending a cease-and-desist (you're asserting) or triaging one we received (you're defending)?"

> **External deliverable (send mode):** the drafted C&D is sent to counterparty. Do NOT include the `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT` header on the outgoing letter. Internal drafts, pre-send briefs, and triage memos keep the header per plugin config `## Outputs`.

## Jurisdiction assumption

Trademark rights are territorial — a US registration does not travel. Copyright is Berne-multilateral but enforcement is jurisdiction-specific, and statutory remedies (including US §504 statutory damages) turn on local law. This skill assumes the jurisdiction declared in the matter or the practice profile's `Registered in:` footprint. If the infringing conduct, counterparty, or forum is somewhere else, flag it — the draft may not apply as written.

## Load context

- `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → `## Enforcement posture` (posture, C&D triggers, soft-letter criteria, approval matrix, automatic escalations), `## IP practice profile` (practice area mix, registered jurisdictions, outside counsel roster), `## Outputs` (work-product header, role), `## Who's using this` (role — lawyer vs. non-lawyer)
- Any C&D template or enforcement playbook referenced in the practice profile's seed documents — read it, match the structure
- **Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip matter machinery — skills use practice-level context. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific overrides (e.g., posture override, approver override). Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

## Send mode — drafting the C&D

### Step 1: Identify the right

Ask, in one batch:

> Which IP right are we asserting?
>
> - **Trademark** — is it registered? Where (USPTO, EUIPO, UKIPO, national)? Reg number and class(es)? Or common-law-only (first-use date, geographic scope)?
> - **Copyright** — is it registered? Title, registration number, date? Or unregistered (note: US suits require registration for filed claims; statutory damages and fees require pre-infringement registration)?
> - **Both** — identify each.

Record each right. Registered rights get cited by number. Common-law rights get the first-use evidence paragraph. Unregistered copyrights get a flag: "We may not be able to file suit on an unregistered US copyright without registering first — `[SME VERIFY]` before the letter threatens litigation."

### Step 2: Identify the conduct

> Describe the infringing conduct in specifics, not adjectives:
>
> - **Who** is doing it — entity name, individual, platform handle?
> - **What** — the accused mark, the accused copy, the accused product? Attach or describe samples.
> - **Where** — website URL, marketplace listing, physical retail, social media?
> - **Since when** — date first observed, date of the earliest use you can document?
> - **Evidence** — screenshots, receipts, watch-service hit, customer confusion reports?

Facts go in specific. "You sold product X on [URL] bearing the mark [Y] on [date]" beats "You have been infringing our rights." Adjectives tell on a thin record.

### Step 3: Identify the relationship

> What's the relationship between us and the recipient?
>
> - **Competitor** (direct or adjacent) — standard posture applies
> - **Reseller / channel partner** — tone adjusts; consider the soft-letter path
> - **Former licensee / ex-employee / former partner** — contract provisions likely apply; cite them
> - **Stranger / random infringer** — standard
> - **Current customer / partner** — automatic escalation per practice profile; flag before drafting

This changes tone, approver, and whether to draft at all without escalation.

### Step 4: Identify the demand

> What does the client actually want?
>
> - **Stop** — cease the infringing use
> - **Account** — report sales, profits, volumes (for damages baseline)
> - **Destroy** — destroy or recall infringing inventory
> - **Damages** — monetary settlement
> - **Transfer / assign** — transfer the domain, hand over the account, assign the accused mark or copyright
> - **Public correction** — takedown of offending content, public statement
> - **Confirm in writing** — compliance undertaking by a date

Pick the actual remedies. The demand must be proportionate to the harm — an overbroad demand is evidence of bad faith if the matter is ever litigated.

**Channel-takedown parallel path (marketplace infringement).** If the accused conduct is on a marketplace (Amazon, Etsy, eBay, Alibaba, TikTok Shop, AliExpress, Walmart Marketplace, Shopify-hosted storefronts), flag the platform's brand-protection / IP-infringement reporting path as a faster, cheaper parallel track that does not require a C&D or litigation:

- **Amazon Brand Registry** (trademark and copyright takedown, counterfeit removal)
- **Etsy IP Infringement reporting** (trademark / copyright / patent forms)
- **eBay VeRO** (Verified Rights Owner program)
- **Alibaba IPP** (IP Protection Platform)
- **TikTok Shop IP Protection**
- **Shopify DMCA / trademark reporting**

A marketplace takedown often resolves in days; a C&D gives the infringer time to sell through inventory while negotiating. The two paths are not mutually exclusive — recommend filing both when the conduct is marketplace-based, with the C&D covering off-platform conduct (DTC site, wholesale, social, physical retail) that the platform report cannot reach. Note in the pre-send brief whether the parallel-path has been filed, is queued, or is declined (and why).

### Step 5: Calibrate to posture

Read `## Enforcement posture` → `Default posture:` and apply:

- **Aggressive** — firm letter, short deadline (often 7–14 days), explicit consequence language (litigation, statutory damages, fees, injunctive relief), no settlement softening
- **Measured** — firm but professional, standard deadline (14–30 days), consequences noted without theatrics, openness to discussion if they respond
- **Conservative** — soft letter framing, longer deadline or no hard deadline, "we'd like to discuss" opening, consequence language muted or absent

Also read `When we send a C&D`, `When we send a soft letter first`, and `When we just file`. If the facts suggest this should be a soft letter or a direct filing per the practice profile, flag it before drafting: "Per your enforcement posture, this pattern matches [soft letter / filing]. Do you still want a C&D, or would you prefer [alternative]?"

Matter-level overrides in `matter.md` beat the practice default.

### Step 5.5: Counterparty diligence — REQUIRED PRECONDITION

**Before drafting, run counterparty diligence and present the results to the user.** This is not conditional on "if the counterparty looks big." Every C&D assertion carries DJ / fee-shifting / bad-faith exposure calibrated to *who* the recipient is. The skill does not draft a C&D until the user has seen the diligence and confirmed they still want to pick this fight.

Collect and present — in one block, for user sign-off — the following:

- **Legal entity** — exact corporate name, state/country of formation, registered agent, any `d/b/a` aliases. USPTO / EUIPO ownership records; state Secretary of State business search; public company filings if any. Flag `[SME VERIFY]` if the source is unconfirmed.
- **Size and resources** — approximate headcount, revenue band if publicly known, funding if a startup, parent company if a subsidiary. Public sources (LinkedIn headcount, press, Crunchbase, SEC filings). Flag honestly if size can't be determined.
- **IP portfolio** — do they hold registered marks, patents, or copyrights in adjacent classes? A counterparty with its own IP portfolio is more likely to (a) understand the posture, (b) counter-assert, and (c) file DJ. USPTO TESS / TSDR quick search on the accused entity and affiliates.
- **Litigation history** — PACER / Court Listener quick pass for prior IP litigation as plaintiff or defendant. A repeat litigant or DJ-happy counterparty changes the calculus. Flag any prior C&D campaigns in the industry.
- **Counsel** — do they have known outside IP counsel? Firm, lead partner if identifiable from prior filings. "No counsel on file" is itself a data point.
- **DJ-plaintiff risk posture** — given size, IP portfolio, litigation history, counsel, and forum: is this a counterparty likely to welcome a C&D as an invitation to file DJ in a forum of their choosing? Flag high / medium / low with a one-sentence reason.
- **Relationship risk** — are we a customer of theirs, do we share investors, are they a potential acquirer or partner? "Not a customer" confirmation pulled from the practice profile; anything else flagged.

Present this as a short memo in-chat BEFORE the draft:

```
## Counterparty diligence — [Entity Name]

- **Entity:** [name, state of formation, parent if any]
- **Size:** [headcount band, revenue band, funding stage] — [source, `[SME VERIFY]` where applicable]
- **IP portfolio:** [registered marks / patents / copyrights in adjacent classes — or "none found"]
- **Litigation history:** [prior IP cases as plaintiff or defendant — or "none found in quick pass"]
- **Counsel:** [known outside IP counsel — or "none identified"]
- **DJ-plaintiff risk:** [high / medium / low — reasoning]
- **Relationship risk:** [any customer / investor / partner / acquirer overlap — or "none identified"]

**Automatic escalations this triggers** (per practice profile `## Enforcement posture` → Automatic escalations):
- [list each trigger that this diligence surfaces]

**Confirm before I draft:**
- Do you want to proceed with a C&D against this counterparty, given the diligence above?
- Any of the automatic escalations applicable? If yes, the approver named in the profile signs off before drafting, not after.
```

**Do not proceed to Step 6 (Draft) until the user has engaged with the diligence block.** A blank "ok" is worse than no confirmation — push back: "Before I draft — anything in the diligence that changes the calculus? Size, prior litigation, their counsel, relationship?"

If diligence surfaces anything in the practice profile's automatic-escalation list (customer, bigger counterparty, patent matter, press-attracting, etc.), route to the named approver per the profile — do not draft on the reviewer's behalf until the approver has signed off on going forward.

If critical diligence items cannot be answered (e.g., entity cannot be confirmed, size is unknown and the counterparty is not on any public register), say so and flag: "I can't confirm [entity / size / counsel] from available sources. Do you have this, or should we pause until a paralegal or OC runs the confirmation?"

### Step 6: Draft

Draft structure:

1. **Sender / letterhead and date**
2. **Recipient block**
3. **Re: line** — concise, does not reveal privileged strategy. `Re: Unauthorized use of [MARK] (US Reg. No. [•])`
4. **Opening** — identify the sender, the right, the registration (if any), and the fact of the letter
5. **The right** — trademark: reg number, class, first-use date, registration status; copyright: registration number, title, year, work description; common-law: first-use date, geographic scope, evidence of acquired distinctiveness
6. **The infringing conduct** — specific: who, what, where, when, evidence
7. **The legal basis** — `[CITE: Lanham Act §32 / §43(a) / 17 U.S.C. §501 / state UCL / contract §]` as applicable
8. **The demand** — numbered, specific, proportionate
9. **The deadline** — calendar date, method of confirmation
10. **Consequences of non-compliance** — calibrated to posture
11. **Preservation demand** — documents, communications, metadata related to the accused conduct
12. **Reservation of rights** — "without waiver of any claims or remedies, whether at law or in equity"
13. **Signature block** — approver per practice profile

**Drafting rules:**

- **Specificity over adjectives.** Dates, URLs, reg numbers, samples. Adjectives are a draftsperson's tell that the facts are thin.
- **No overbroad assertions.** If the mark is registered in one class and the accused use is in a different class, say so — don't pretend the registration covers both. Overbroad C&Ds are evidence of bad faith and can support §43(a)(1)(B) or Rule 11 exposure.
- **Citations as placeholders unless verified.** `[CITE: Lanham Act §32, 15 U.S.C. §1114]` stays as a placeholder unless the user provided the cite or a research tool returned it. Tag every citation with source — `[Westlaw]`, `[user provided]`, `[model knowledge — verify]`, `[web search — verify]`. Never strip the tags.
- **Consequence language matches posture.** Aggressive → specific relief threatened (injunction, statutory damages under 15 U.S.C. §1117 / 17 U.S.C. §504, attorneys' fees). Measured → "we reserve all rights." Conservative → "we'd like to discuss before considering further steps."
- **Jurisdiction-specific hooks** — if US, watch for Anti-Cybersquatting (15 U.S.C. §1125(d)) for domain matters, §43(a) for unregistered marks, §504(c) for pre-registration timing. Non-US: flag the forum and note the draft may need foreign associate review.

### Step 7: The loud gate before delivery

Before presenting the draft in-chat or writing the .docx, display this gate verbatim. **The user must engage with it** — a blank acknowledgment is worse than no gate.

```
┌─────────────────────────────────────────────────────────────┐
│  BEFORE THIS DRAFT GOES ANYWHERE                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  This is a draft for attorney review — not a letter to      │
│  send. Sending a cease-and-desist letter is an assertion    │
│  of legal rights with real consequences:                    │
│                                                             │
│  • It can trigger a declaratory judgment action in a        │
│    jurisdiction of the recipient's choosing. A well-funded  │
│    recipient can use a C&D as an invitation to pick a       │
│    hostile forum.                                           │
│                                                             │
│  • Overbroad or bad-faith assertions can be used against    │
│    the sender — §43(a)(1)(B) claims, Rule 11 sanctions,     │
│    attorneys' fees under the Lanham Act / Copyright Act.    │
│                                                             │
│  • It starts a dispute that may not settle cheaply.         │
│                                                             │
│  Confirm before the letter leaves:                          │
│                                                             │
│    1. The rights asserted are valid — registered (pulled    │
│       from the register, not assumed) or solidly common     │
│       law with evidence of acquired distinctiveness.        │
│    2. The claim is colorable — a reasonable practitioner    │
│       would make it on these facts.                         │
│    3. The demand is proportionate — we are asking for       │
│       relief the conduct warrants, not everything.          │
│    4. Whoever has authority to start a fight has approved.  │
│    5. Counterparty diligence (Step 5.5) was presented       │
│       and confirmed — entity, size, IP portfolio, prior     │
│       litigation, counsel, DJ-plaintiff risk, and           │
│       relationship risk. Not conditional. Required.         │
│                                                             │
│  Approver per your practice profile: [approver name/role    │
│  from Enforcement posture → Approval matrix → C&D row]      │
│                                                             │
│  Automatic escalations that apply here: [list any from the  │
│  practice profile that this matter triggers — customer,     │
│  bigger counterparty, patent, press-attracting, etc. —      │
│  surfaced in Step 5.5 diligence]                            │
│                                                             │
│  Parallel-path status (marketplace conduct): [filed /       │
│  queued / declined — from Step 4. "Not applicable" if       │
│  conduct is not on a marketplace.]                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

If the user is a non-lawyer (per `## Who's using this`), add:

> Sending a C&D has legal consequences that go beyond the recipient's response — it is an affirmative assertion of rights that can be held against you. Have you reviewed this with an attorney? If not, here's a brief to bring to them: [generate a 1-page summary: parties, rights asserted, infringing conduct, demand, posture, risks flagged above, what could go wrong, specific questions for the attorney].
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). The ABA IP section and state IP associations (US), CIPA/ITMA (UK), and equivalent bodies elsewhere maintain referral rosters for trademark and copyright practitioners.

Do not write the .docx or mark the draft as ready without explicit engagement with the gate.

### Step 8: Output

**Primary:** `<matter-folder>/cease-desist/<slug>/draft-v<N>.docx` (or `cease-desist/<slug>/draft-v<N>.docx` at practice level). Use the `docx` skill. Letter-formatted per the draft structure above. Strip the work-product header from the outgoing letter.

**In-chat:** show the draft as plain text for review before writing the .docx. Iterate before committing to disk.

**Reviewer-facing closing note** (appended to the in-chat preview only, stripped from the .docx):

> This is a draft cease-and-desist letter for attorney review, not a letter ready to send. Sending it is an assertion of legal rights with the consequences described in the pre-delivery gate. A licensed attorney reviews, edits, and takes professional responsibility before sending. Do not send this draft unreviewed.

**Citation verification.** Every `[CITE:___]` and every cite carried from a template or provided authority is unverified until run through a citator. Before sending, verify each cite is good law on a legal research platform. Fabricated or misquoted cites in sent assertion letters are professional responsibility exposure. Preserve the source-attribution tags — `[Westlaw]`, `[CourtListener]`, `[Descrybe]`, `[user provided]`, `[model knowledge — verify]`, `[web search — verify]` — tags flagged `verify` get checked first.

**No silent supplement.** If a configured research tool returns few or no results for an authority the draft needs, report what was found and stop. Do NOT backfill from web search or model knowledge without asking. Present options — broaden the query, try a different tool, accept web search with tags, leave the placeholder — and let the user decide.

**Post-send checklist.** After the draft is approved, write `<matter-folder>/cease-desist/<slug>/checklist.md` with: final read by approver, all `[VERIFY]` resolved, all `[CITE]` filled and verified, privilege markings stripped from the outgoing letter, approver signed, delivery method executed, proof of delivery retained, compliance deadline calendared, escalation plan if no response, matter created in `matters/` if not already.

## Receive mode — triaging the incoming C&D

### Step 1: Read the letter

Extract:

- **Sender** — entity, signer, outside counsel if any
- **Recipient** — which of our entities/people
- **Delivery method and date**
- **Asserted right** — trademark (reg number? jurisdiction?), copyright (registered? title?), both, something else
- **Alleged conduct** — their version of what we're doing
- **Legal basis** — statutes, contract provisions, theories cited
- **Demand** — what they want; is the deadline stated?
- **Threats** — what they say they'll do
- **Tone** — firm / soft / scorched-earth; counsel signature usually signals seriousness

### Step 2: Assess the assertion

Not a legal opinion — a structured read:

- **Rights validity.** Are the asserted registrations real and active? (Check USPTO TSDR, EUIPO eSearch, Copyright Office records — flag any that look dormant or not in force.) For common-law claims, what evidence do they actually cite?
- **Plausibility of confusion / similarity / infringement.** On the facts as alleged, is this a colorable claim or is it stretching? For trademark: likelihood of confusion turns on multi-factor tests (Polaroid / AMF / Sleekcraft depending on circuit — `[SME VERIFY]` the forum's test). For copyright: access + substantial similarity. Flag where the claim looks weakest.
- **Overbreadth.** Are they demanding more than the conduct warrants? (They want the mark transferred when registration would at most cover re-labeling? They want all sales when only one channel touched the right?) Overbroad demands weaken leverage and strengthen a §43(a)(1)(B) / unclean-hands counter.
- **Timing.** Laches, statute of limitations, registration timing (for US copyright statutory damages) — flag any date issues on the face of the letter.
- **Forum.** Where would they sue? Is the forum contractually fixed (most unlikely in a stranger IP dispute)? Is there a DJ opportunity for us?

### Step 3: Assess our exposure

- **Are we actually infringing?** Honest look. What does the record show?
- **Could we stop easily?** Cost of compliance vs. cost of fight.
- **Is the sender a troll or a real claimant?** Repeat-plaintiff? Known-willing-to-fight? Recent C&D campaign on comparable use? Check public dockets if time permits.
- **What's at stake beyond this dispute?** Brand equity, customer relationships, precedent for similar inbound C&Ds.

### Step 4: Options

Present 4-5 options with tradeoffs:

**A — Comply quickly**
- When: the claim is colorable, compliance is cheap, and the fight isn't worth it
- Tradeoff: establishes a concession they may point to later; may embolden future assertions
- Next step: confirm compliance in writing (narrow), do not concede broader theory

**B — Negotiate**
- When: there's a middle-ground business deal (license, coexistence, rebranding timeline) that resolves it
- Tradeoff: commits time; requires care on settlement-communication posture (FRE 408 or state equivalent; protection attaches from substance and context, not labeling alone)
- Next step: holding letter + opening negotiation track

**C — Respond firmly (reject)**
- When: their claim is weak, overbroad, or factually wrong; we want to close this down without litigating
- Tradeoff: locks in a position; if the claim is in fact colorable, our response becomes an exhibit
- Next step: draft a response letter — consider running it through `/ip-legal:cease-desist --send` reframed as a response

**D — Ignore (and preserve)**
- When: the claim is frivolous, the sender has no apparent capacity to sue, the deadline has no legal consequence
- Tradeoff: silence can be used as non-denial in some contexts; legal hold required regardless; risk that filing follows
- Next step: issue legal hold via matter-level process; log the demand; move on

**E — Pre-empt with a DJ action or cancellation**
- When: we face real business uncertainty, the claim is weak, and we benefit from our own forum
- Tradeoff: we go on offense; budget and leadership sign-off required; now there's a lawsuit
- Next step: escalate to outside counsel per practice profile, do not draft

**F — File to cancel their mark (TTAB) or invalidate their copyright registration**
- When: their rights themselves are vulnerable and we want to take the instrument off the board
- Tradeoff: slow, expensive, public; separate from the dispute itself
- Next step: escalate to outside counsel

Recommend one with two sentences of rationale. Be specific about why.

### Step 5: Deadline triage

- Their stated deadline — note it, but it doesn't legally bind us (unless a specific statute gives it teeth).
- Our internal decision deadline — typically stated deadline minus enough time to draft, review, and approve a response. Flag it on the calendar.
- Legal deadlines — statute of limitations on any underlying claim, contractual cure periods, forum-specific timelines.

Ignoring a stated deadline entirely is a choice, not a default. Note that filing usually follows silence, not the deadline date.

### Step 6: Write the triage memo

Output: `<matter-folder>/cease-desist/inbound/<slug>/triage.md` (or at practice level if matter workspaces are off).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

[PRIVILEGE INHERITANCE BLOCK — pick by role and matter type; see guidance below the template]

# C&D Received — Triage

> **READ FOR TRIAGE, NOT OPINION.** This is an intake scan and options analysis — not a legal merit opinion. The assessment below is a structured read to support counsel's decision on routing and response. Every cited statute, rule, or case is flagged for SME verification; every merit call is the counsel's, not this skill's.

**Slug:** [slug]
**Received:** [YYYY-MM-DD]
**Received by:** [entity / person]
**Incoming file:** [path]

## The assertion

**Sender:** [entity, signer, counsel]
**Asserted right:** [trademark / copyright / both — with specifics, reg numbers, jurisdictions]
**Alleged conduct:** [their version, one paragraph]
**Demand:** [list — specific asks]
**Their stated deadline:** [date]
**Tone:** [firm / soft / scorched-earth]

## Rights validity

[Registrations as asserted — `[SME VERIFY]` against the register; common-law claims evaluated against the evidence cited]

## Legal basis cited

[Each citation inline-tagged with `[SME VERIFY: applicability / currency / jurisdiction]` and source `[Westlaw / user provided / model knowledge — verify / web search — verify]`. Do not rely on any citation here without independent check.]

## Plausibility assessment

- **Confusion / similarity / infringement on the facts:** [read]
- **Overbreadth:** [read]
- **Timing issues (laches, SoL, registration timing):** [read]
- **Forum:** [their likely forum; DJ opportunity]

## Our exposure

- **Actually infringing?** [honest look]
- **Cost of compliance vs. cost of fight:** [read]
- **Sender credibility:** [troll / real claimant / repeat plaintiff — with any public-docket evidence]
- **Collateral stakes:** [brand, customers, precedent]

**Triage rating:** [substantial / debatable / weak / frivolous] — *structured read for routing, not a merit opinion; `[SME VERIFY]`*

## Options

### A. Comply quickly
[Rationale, tradeoffs, next step]

### B. Negotiate
[Rationale, tradeoffs, next step]

### C. Respond firmly
[Rationale, tradeoffs, next step]

### D. Ignore + preserve
[Rationale, tradeoffs, next step]

### E. Pre-empt (DJ)
[Rationale, tradeoffs, next step]

### F. File to cancel / invalidate
[Rationale, tradeoffs, next step]

**Recommendation:** [A/B/C/D/E/F] — [two sentences why] — `[SME VERIFY: counsel to confirm before executing]`

## Deadlines

- **Their stated deadline:** [date]
- **Our internal decision deadline:** [date]
- **Legal deadlines on any underlying claim:** [SoL, cure, procedural — with dates]

## Immediate actions

- [ ] Legal hold issued — [yes/no]
- [ ] Matter created in log — [yes/no/TBD]
- [ ] Counsel assigned — [who]
- [ ] Insurance tendered — [yes/no/N-A]
- [ ] Internal escalation — [who/when]
```

**Privilege inheritance block — pick by role and matter type.** Read `## Who's using this` (Role) in the plugin config and the matter type (trademark / copyright / patent / OSS / other). This triage records a first-pass merit read on an adverse assertion; whether it's actually privileged depends on who prepared it and what it's about. Getting this wrong in either direction is harmful — a false "privileged" marking creates a discoverable admission that reads as a concession; under-marking a genuinely privileged memo can waive the protection. Insert exactly one of the following:

- **Role = Lawyer / legal professional:**
  > **Privilege inheritance.** This triage records our first-pass merit read and response posture on an adverse assertion. It is attorney-client and/or work-product material. Do not forward, attach to an insurance tender without scrubbing, or share with counterparty. Store with privileged matter material and mark per house privilege conventions.

- **Role = Registered patent agent, matter is a patent matter before the USPTO:**
  > **Privilege (patent agent-client).** This triage is privileged under the federal patent agent-client privilege recognized in *In re Queen's University at Kingston*, 820 F.3d 1287 (Fed. Cir. 2016), because it relates to a matter reasonably necessary and incident to the prosecution of patents before the USPTO. That privilege is narrow: it does not extend to matters outside USPTO practice. Do not forward, attach to an insurance tender without scrubbing, or share with counterparty. Bring to supervising counsel for matter-specific privilege decisions.

- **Role = Registered patent agent, matter is NOT a patent matter** (trademark, copyright, OSS, trade secret, contract, or anything else outside USPTO practice):
  > **CONFIDENTIAL — NOT PRIVILEGED.** This triage is not privileged because a registered patent agent's privilege is limited to patent prosecution before the USPTO (*In re Queen's University at Kingston*, 820 F.3d 1287 (Fed. Cir. 2016)). A trademark, copyright, OSS, or other non-patent matter falls outside that privilege. Treat this document as confidential, store it with care, bring it to counsel, and let counsel mark it. Do not forward it as a privileged document.

- **Role = Non-lawyer and not a registered patent agent:**
  > **CONFIDENTIAL — NOT PRIVILEGED.** This document is not privileged unless and until reviewed by a licensed attorney. Treat it as confidential; do not forward to anyone outside the legal review chain; bring it to counsel and let counsel mark it. Forwarding this document as "privileged" before an attorney reviews it does not make it so and can harm you if the matter becomes contested.

Close the in-chat presentation with this guardrail verbatim:

> This is a triage memo, not advice. The strength assessment above is a first read based on the letter alone — it does not account for facts you haven't told me, registrations I can't verify, or jurisdictional issues. An attorney evaluates before you respond, decide to ignore, or commit to a path.

If the user is a non-lawyer, add the "find-an-attorney" routing paragraph from send mode.

### Step 7: Hand off

Based on the recommendation and user confirmation:

- Respond firmly → hand off to `/ip-legal:cease-desist --send` with context pre-populated as a response letter (this triggers the send-mode gate anew).
- Negotiate → start a holding letter / negotiation track in the matter.
- Pre-empt or file to cancel → escalate to outside counsel per the practice profile's IP litigation row; do not draft.
- Matter creation → if there isn't one and the matter is material, offer `/ip-legal:matter-workspace new <slug>` pre-populated.
- Comply / ignore → log the decision in the matter history; issue or confirm the legal hold; close the triage record.

## Decision posture

Per `## Decision posture on subjective legal calls` in the practice profile: when uncertain whether there is infringement, whether a mark is confusingly similar, whether a work is substantially similar, whether a claim is colorable, or whether sending is safe — do not silently decide it's fine. Flag for attorney review, surface the factors cutting both ways, note the uncertainty. Sending a C&D on an assumption is a one-way door; surfacing doubt is a two-way door.

## What this skill does not do

- **Send the letter.** Drafting only. The user sends, after approval.
- **Research citations.** Placeholders stay as placeholders unless the user provides authorities or a connected research tool returns them. Inventing cites is professional responsibility exposure.
- **Bypass the gate.** The send-mode gate runs every time. Even with an `--skip-gate` flag (none is provided), the skill would log the skip in the draft file.
- **Decide merit definitively on the receive side.** The rating is a structured read for routing; a formal merit opinion lives with counsel.
- **Validate the sender's cited law.** Flags for the user; does not autonomously call a claim valid or invalid.
- **Make the matter-creation call.** Surfaces the recommendation; user decides.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/clearance', 'legal', 'clearance', '', 'clearance', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /clearance

**This is a triage, not a clearance opinion.** A trademark clearance opinion
requires a full professional search and registered trademark counsel's
judgment. A "no obvious conflicts" result means the triage
didn't find anything — it does not mean the mark is clear. Clients have been
sued over marks that passed a knockout search.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it
   contains `[PLACEHOLDER]`, stop and direct to `/ip-legal:cold-start-interview`.
2. Follow the workflow below.
3. Run intake (mark, goods/services, classes, jurisdictions, visual/stylization).
4. Knockout check for intrinsic bars — generic, descriptive, deceptive,
   geographic, surname, false connection, prohibited matter, functional.
5. Similar-marks search against what's connected (Solve Intelligence, CourtListener, Descrybe, or whatever MCP is available). If nothing is
   connected, say so in the output and proceed with the factor analysis only.
6. Walk the applicable circuit's likelihood-of-confusion factors — du Pont /
   Polaroid / Sleekcraft / other. Flag each; never conclude.
7. Write the triage memo to the matter folder (if a matter is active) or the
   practice outputs folder. Apply the work-product header per role.
8. End with recommended next steps and the non-lawyer gate if the role is
   non-lawyer.

This skill never concludes a mark is clear. If uncertain, flag — the attorney
decides.

## Examples

```
/ip-legal:clearance "APEXLEAF for an outdoor apparel line, planned launch US + EU"
```

```
/ip-legal:clearance
```

(And the skill will ask for the mark, goods, classes, and jurisdictions.)

---

## THIS IS A FIRST PASS, NOT A CLEARANCE OPINION

**Say this at the top of every output. Do not drop it. Do not soften it.**

> **This is a first pass, not a clearance opinion.** A trademark clearance opinion
> requires a full professional search (TESS, state registries, common law sources,
> international registries, domain and social, trade dress and design marks where
> relevant) and attorney judgment on likelihood of confusion, which depends on
> factors a structured triage cannot fully assess. A "no obvious conflicts" result
> from this skill means the triage didn't find anything — it does not mean the
> mark is clear. Clients have been sued over marks that passed a knockout search.
> A registered trademark attorney evaluates before anyone adopts, files, or
> invests in this mark.

This is the loudest guardrail in the plugin. Under-calling a conflict is a
one-way door — a logo on trucks, a product launched, a TM application filed, all
with a problem underneath. Over-calling is a two-way door — the attorney narrows
the list in review. Stay on the two-way door side.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Load the practice profile first

Before running clearance, read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Pull:

- **Role** from `## Who's using this` (lawyer vs. non-lawyer changes the work-product header and the non-lawyer gate below).
- **Registered in** and **enforce where** from `## IP practice profile` and `## Enforcement posture` (default jurisdictions if the user doesn't specify).
- **Integrations** from `## Available integrations` (CourtListener / Solve Intelligence / Descrybe — each determines what searches are available to run, what the fallback is, and what gets attributed in the output).
- **Decision posture** from `## Decision posture on subjective legal calls` — this skill never concludes "not confusingly similar."

If `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` contains `[PLACEHOLDER]` or `[Your Company Name]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor posture, jurisdictions, and approval chain to your practice.
>
> **Two choices:**
> - Run `/ip-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll run this tailored to YOUR practice.
> - Say **"provisional"** and I'll run this against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run the clearance normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction (USPTO + common-law), no playbook (do the full analysis rather than matching against a position list). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/ip-legal:cold-start-interview` to get output calibrated to YOUR practice — your playbook, your jurisdiction, your risk appetite. 2 minutes."

---

## Intake

Ask once, in a single batch (don't drag out a quick job):

> A few questions before I run the triage:
>
> 1. **Proposed mark.** Exact spelling, any stylization, and whether it's a word mark, logo, or both.
> 2. **Goods or services.** What's actually being sold or offered under this mark. A sentence or two — I'll map to international classes.
> 3. **Classes.** If you already know the Nice classes, list them. Otherwise describe the goods/services and I'll suggest the likely classes and confirm with you before running the search.
> 4. **Jurisdictions.** Where do you plan to use, register, or enforce? (US / EU / UK / Madrid / specific countries — I'll default to `Registered in` from your practice profile if you don't say.)
> 5. **How it will appear in use.** Any taglines, adjacent product names, trade dress, or design elements that would show up with it in market.

Wait for the answer. If the description is vague ("AI tool," "platform"), push once:

> Give me the actual thing a customer sees — is it a consumer mobile app, enterprise API, physical product, service? The classes turn on this.

---

## Knockout check

Before any database search, run the intrinsic problems that kill a mark regardless
of prior registrations. For each, assess plainly and flag. Do not rationalize away
a clear issue.

| Bar | What it means | Flag when |
|---|---|---|
| **Generic** | The term IS the category (e.g., "Soap" for soap) | The mark names what the thing is |
| **Descriptive** | Directly describes a feature, function, quality, or ingredient | A consumer reads the mark and knows what the product does without imagination |
| **Deceptive / deceptively misdescriptive** | Misrepresents a material feature | The mark suggests a quality the goods don't have and that quality would matter |
| **Primarily geographically descriptive / deceptive** | Mark is primarily a place name and goods come from (or don't) that place | Mark = place + generic; or place + goods where customers would assume origin |
| **Primarily merely a surname** | Mark is primarily a surname | Mark reads as someone's last name to the relevant consumer |
| **False connection** | Mark falsely suggests connection with person, institution, national symbol | Mark invokes a specific identifiable person or institution |
| **Prohibited matter** | Flags, coats of arms, insignia, specific prohibited categories | Mark contains a prohibited element |
| **Functional (for design marks / trade dress)** | The feature is essential to use or affects cost/quality | Design mark — and the feature performs a function |

Note on scandalous/immoral marks: after *Iancu v. Brunetti* (2019) and *Matal v.
Tam* (2017), the USPTO no longer refuses registration on those bases. The
surviving statutory bar in this zone is false connection under §2(a). Apply that;
don't flag under the struck-down bars.

**Output:** for each knockout category, either "no issue identified" or a
specific flag with a one-line reason. Don't produce a blank table of passes.

---

## Similar marks check

The purpose here is to **find potentially confusingly similar prior marks**, not
to decide whether confusion is likely. That is the attorney's call.

### What the user has connected

Read `## Available integrations` from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`:

- **If a trademark search connector is available** (Solve Intelligence,
  Descrybe — or any MCP exposing TM-registry search): run a preliminary search
  across the relevant classes and jurisdictions. Attribute every result to its
  source. Note the date of the search and the scope (which registries, which
  classes, exact-match vs. fuzzy, design search or not).
- **If a legal research connector is available** (CourtListener for litigation for case law and TTAB decisions): sweep for reported disputes involving
  the mark or a close variant. Same attribution rule.
- **If no search connector is available:** say so, explicitly, in the output.
  Do not infer results from model knowledge and present them as search findings.

### Fallback when no database access exists

Write out, in the output, this exact statement:

> **No database search was run.** This triage did not hit TESS, Solve
> Intelligence, Descrybe, CourtListener, state registries, Madrid/WIPO, or any
> common law / unregistered-mark sources. A knockout or full search across those
> databases is required before any conclusion about availability. The triage
> below is limited to intrinsic-bar analysis and structured confusion factors
> against marks the user has identified or that come up in the conversation.

Then proceed — the intrinsic checks and the factors analysis are still useful,
just labeled honestly.

### For each similar mark found (or supplied)

Capture:

- **Mark** (exact characters, any stylization)
- **Source** (TESS registration no., Madrid designation, state registry, case
  citation, domain, social handle — whichever)
- **Classes / goods-services description** from the register
- **Owner**
- **Status** (registered / pending / abandoned / cancelled — a dead mark is not a
  bar but can be relevant to fame and to a predecessor's rights)
- **First-use date if available**

**Do not supplement silently.** If you cite a USPTO registration number, it came
from the search you ran; if you describe a mark the user mentioned, say that.
Never invent a registration and never "fill in" a detail the record doesn't
support. If the search didn't return a first-use date, write "first-use date not
available from search result" — do not guess.

### Adjacent families sweep (required before concluding)

A clearance that only checks exact and near-exact matches misses the marks a
competitor adopted *because* yours was taken. Before concluding, identify 3–5
adjacent word families the practitioner should also sweep, and ask the user to
confirm or add to the list.

Adjacent families are category-conventional substitutes a reasonable competitor
would consider when the direct mark is unavailable. For a mark like
`NEXUS HOME` in the smart-home hub space, the adjacent families include at
minimum:

- **Category synonyms** for NEXUS: `HUB`, `NEST`, `CORE`, `LINK`, `CONNECT`,
  `BRIDGE`, `CENTRAL`, `GATEWAY`.
- **Assistant-style names** in the same product category: `ALEXA`,
  `ECHO`, `SIRI`, `GOOGLE HOME`, `CORTANA`, `HOMEY`, `HOMEBASE`.
- **HOME / HOUSE / SMART variants**: `SMART HOME`, `HOUSEHOLD`, `HOUSE`,
  `ABODE`, `CASA`, `DOM`.
- **Phonetic twins** on the root: `NEXIS`, `NEKSUS`, `NEXXUS`, `NECTIS`,
  `KNOXUS` (depending on how the word sits in the market).

The skill should output an adjacent-families block in the Similar Marks section
with a confirmation prompt:

> **Adjacent families to sweep (please confirm or add):**
>
> - [family 1 — e.g., HUB / NEST / LINK / CONNECT]
> - [family 2 — e.g., ALEXA-style assistant names]
> - [family 3 — e.g., HOME / HOUSE / SMART variants]
> - [family 4 — phonetic twins on the root]
>
> A clearance that only checks exact and near-exact matches misses the marks a
> competitor adopted because yours was taken. Confirm this list is complete for
> the category before I continue.

> **When non-English-speaking jurisdictions are in scope,** the English-only phonetic sweep misses the most common source of cross-border conflicts. Add:
> - **Translation equivalents.** The mark translated into the relevant languages. The EU's foreign-equivalents doctrine treats a translation as the same mark for confusion purposes.
> - **Transliteration.** The mark written in the relevant script (Cyrillic, Chinese/Japanese/Korean, Arabic, Hangul, Thai). Phonetic equivalence across scripts is a recognized conflict basis.
> - **Script variations.** Marks registered in a non-Latin script that sound like your mark when romanized.
>
> If you can't perform cross-language analysis, say so: "Cross-language phonetic and translation-equivalent analysis not performed — this is the most common source of cross-border conflicts. A clearance search in [jurisdiction] should include it."

If the practitioner has a connected TM search tool, re-run the sweep against
each confirmed adjacent family (exact + phonetic + translation-of-foreign-equivalent
where relevant) and add the results to the Similar Marks table with the
`Adjacent family` source noted. If no connector is available, say so, and list
the families as the explicit next-step input for a full professional search —
do not silently skip the sweep.

---

## Likelihood-of-confusion factors

> **Confusion framework is jurisdiction-specific.** The US and EU assess likelihood of confusion differently. Don't apply the wrong one.
>
> - **US (federal circuits):** Multi-factor tests (*du Pont*, *Polaroid*, *Sleekcraft*) — strength of the mark, similarity (sight/sound/meaning), proximity of goods, channels, buyer sophistication, actual confusion, intent.
> - **EU (Art. 8(1)(b) EUTMR):** Global appreciation — all relevant factors assessed holistically through the eyes of the average consumer. Key differences: greater weight on phonetic similarity; translation equivalents as standard (the mark translated into EU languages); "likelihood of association" beyond source confusion; the distinctiveness of the earlier mark carries more weight.
> - **UK (TMA 1994 §5(2)):** Follows the EU global appreciation approach post-Brexit but diverging case law. Check for UK-specific decisions.
> - **Other jurisdictions:** If the intake includes a jurisdiction without a framework above, say: "I don't have [jurisdiction]'s confusion framework. Applying the US test would give you a wrong answer that looks right. Options: (a) I search for the applicable standard, (b) you route to a [jurisdiction] trademark specialist, (c) I note this jurisdiction is out of scope." Never silently apply US doctrine.

The relevant circuit's test determines the factors to walk through. Cite the
test that applies:

- **TTAB / Federal Circuit:** *In re E. I. du Pont de Nemours & Co.*, 476 F.2d
  1357 (C.C.P.A. 1973) (13 factors).
- **Second Circuit:** *Polaroid Corp. v. Polarad Electronics Corp.*, 287 F.2d 492
  (2d Cir. 1961) (8 factors).
- **Ninth Circuit:** *AMF Inc. v. Sleekcraft Boats*, 599 F.2d 341 (9th Cir. 1979)
  (8 factors).
- **Other circuits:** walk through the circuit's named multi-factor test (e.g.,
  *Frisch's Restaurants* in the Sixth Circuit, *Scotch Whisky Association* in the
  Seventh, *Lapp* in the Third).

Pick based on where the user plans to enforce (practice profile), the TTAB if
the immediate forum is registration, or the primary commercial forum otherwise.
Note your pick in the output.

For each factor, produce a **flag**, not a verdict. Each factor should say what
cuts each way and where the uncertainty is:

- **Similarity of marks** (appearance, sound, meaning / connotation, commercial
  impression). Sight-sound-meaning, considered together.
- **Similarity of goods or services.** Not whether the goods are identical —
  whether consumers would expect them to come from the same source.
- **Channels of trade.** Where each side actually sells (or would sell). Same
  stores? Same distribution? Same trade shows? Online-only?
- **Sophistication of consumers.** Impulse buy at a gas station vs. considered
  enterprise purchase changes the standard of care.
- **Strength of prior mark found.** Fanciful / arbitrary / suggestive /
  descriptive / generic, and fame evidence if any. A strong prior mark gets
  wider protection.
- **Intent.** Evidence of intent to trade on goodwill — a near-copy with similar
  trade dress in an adjacent class is different from an independent coinage.
- **Actual confusion.** Any evidence (misdirected inquiries, surveys, reviews,
  social posts).
- **Likelihood of expansion** (bridge-the-gap). Whether the senior user is
  likely to expand into the junior's lane, and vice versa.

Per the decision posture in `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`:

- **Never conclude "not confusingly similar."**
- If uncertain, write: "Similar marks found — confusion assessment required
  before adoption." Or: "Factors cut both ways; attorney judgment required."
- Clear space for "no similar marks found in the databases searched" is fine
  *only* if a real search was run; see the no-search fallback above otherwise.

---

## Recommended next steps

Every clearance output ends with concrete next steps, bucketed by what the
triage found:

- **If knockout issues found:** reframe the mark, or accept the descriptiveness
  bar and plan for secondary-meaning over time; route for attorney review before
  adopting.
- **If similar marks found in the databases searched:** attorney review is
  required before adopting, filing, or marketing. Often the next step is a full
  professional search to find everything the triage missed.
- **If no similar marks found but no database search ran:** a full search is
  required before adoption. Name the databases that need to be hit.
- **If similar marks found and the senior mark is weak, old, in a different
  class, or abandoned:** flag for attorney review — the triage will not make
  this call.
- **Always:** a full clearance opinion from registered trademark counsel, scaled
  to the investment the mark will carry. A mark you'll put on a product line and
  a Super Bowl ad carries more weight than a mark for a one-off pop-up.

---

## Output format

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` `## Outputs`.

```markdown
[WORK-PRODUCT HEADER]

# Trademark Clearance — First Pass (NOT AN OPINION)

**This is a first pass, not a clearance opinion.** A clearance opinion requires
a full professional search and attorney judgment. A "no obvious conflicts"
result here means the triage didn't find anything — it does not mean the mark
is clear. A registered trademark attorney evaluates before anyone adopts, files,
or invests in this mark.

**Triage result:** [GREEN / YELLOW / RED — one sentence why]

## Proposed mark

- **Mark:** [exact text, stylization noted]
- **Mark type:** [word / design / composite]
- **Goods / services:** [description]
- **Classes:** [Nice class numbers with one-line descriptions]
- **Jurisdictions:** [US / EU / UK / Madrid / specific countries]
- **Confusion test applied:** [du Pont / Polaroid / Sleekcraft / other — with the
  reason it's the right one]

## Knockout issues

| Bar | Flag | Note |
|---|---|---|
| Generic / descriptive / deceptive / geographic / surname / false connection / prohibited / functional | [none / flagged] | [one line if flagged] |

## Similar marks check

**Sources searched:** [registries and databases hit, with dates — or "no database
search run; see scope note below."]
**Scope:** [classes, jurisdictions, exact-vs-fuzzy, design search or not]

**Adjacent families swept (confirmed with user):**
- [family 1 — e.g., HUB / NEST / LINK / CONNECT / BRIDGE / GATEWAY]
- [family 2 — e.g., ALEXA-style assistant names]
- [family 3 — e.g., HOME / HOUSE / SMART variants]
- [family 4 — phonetic twins on the root]

*A clearance that only checks exact and near-exact matches misses the marks a
competitor adopted because yours was taken. If any family was not swept (no
connector, time not available), it is listed explicitly as a next-step input
to the full professional search — not silently skipped.*

| Mark | Source | Classes / G&S | Owner | Status | First use | Note |
|---|---|---|---|---|---|---|
| [exact] | [registration no. / citation / URL] | [class list] | [owner from record] | [reg/pending/abandoned/cancelled] | [date or "not available"] | [why it matters — exact match / adjacent family] |

*If no search was run:* **No database search was run.** This triage did not hit
TESS, Solve Intelligence, Descrybe, CourtListener, state registries,
Madrid/WIPO, or any common law / unregistered-mark sources. A knockout or full
search across those databases is required before any conclusion about availability.

## Confusion factors — flags for attorney review

For each of the factors under the test applied, a one-line flag noting what cuts
each way.

| Factor | Flag | Direction |
|---|---|---|
| Similarity of marks (sight / sound / meaning / commercial impression) | [note] | [weighs toward / against conflict / mixed] |
| Similarity of goods or services | [note] | [direction] |
| Channels of trade | [note] | [direction] |
| Consumer sophistication | [note] | [direction] |
| Strength of prior mark | [note] | [direction] |
| Intent | [note] | [direction] |
| Actual confusion | [note or "no evidence surfaced"] | [direction] |
| Likelihood of expansion / bridge-the-gap | [note] | [direction] |

**Conclusion on confusion:** *This skill does not conclude.* Either:
- "Similar marks found; attorney confusion assessment required before adoption."
- "No similar marks found in the databases searched; full clearance required
  before adoption."
- "Factors cut both ways; attorney judgment required."

## Recommended next steps

- [specific next step 1 — e.g., "Full professional search across USPTO, state
  registries, common law sources, EUIPO, and UK IPO before adoption"]
- [specific next step 2 — e.g., "Design-around review of the `APEXLEAF` mark
  in Class 25 if the intent is to proceed"]
- [specific next step 3 — e.g., "Reframe the mark — current form is descriptive
  and will require secondary meaning"]
- [routing per `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` —
  trademark OC or in-house IP counsel named in the practice profile]

## Citation verification

Every case, registration number, statute, and database result in this memo must
be verified against the authoritative source before relying on it. Registration
numbers, class designations, and first-use dates are the most common sites of
error. Do not cite a result you cannot open.
```

---

## Non-lawyer gate

Before issuing the output, read `## Who's using this`. If the Role is Non-lawyer:

> This output is a research triage, not legal advice. Adopting, filing, or
> investing in this mark based on this triage alone has legal consequences —
> including being sued for infringement over a mark that "passed" this check.
> A registered trademark attorney needs to evaluate before you move.
>
> Here's a brief to bring to an attorney — it'll cut the time the conversation
> takes:
>
> [Generate a 1-page summary: the proposed mark, the goods/services and classes,
> the knockout issues (if any), the similar marks surfaced (if any), what was
> and wasn't searched, and the three questions to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). The INTA (International Trademark Association)
> maintains a member directory of registered trademark practitioners.

Deliver the full triage memo alongside the brief. Do not withhold the analysis.

---

## Output location

If matter workspaces are enabled and a matter is active, write the output to
`~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/outputs/clearance-<mark-slug>-YYYY-MM-DD.md`.
Otherwise write to
`~/.claude/plugins/config/claude-for-legal/ip-legal/outputs/clearance-<mark-slug>-YYYY-MM-DD.md`
and surface the path to the user.

Append a one-line entry to the matter's `history.md` if a matter is active.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Conclude a mark is clear.** Ever. The loudest guardrail in the plugin.
- **Substitute for TESS search, state-registry search, common-law search,
  international search, watch-service check, or design-mark search.**
- **File a trademark application.** Filing is an attorney task; this skill
  informs the decision to file.
- **Evaluate trade dress, trademark dilution, or famous-mark claims** beyond a
  preliminary flag. Dilution under the TDRA requires a fame analysis this
  skill does not attempt.
- **Address foreign local-law bars** (e.g., phonetic similarity standards in
  Japan, translation-of-foreign-equivalents in the EU) beyond flagging that
  foreign analysis is required when a foreign jurisdiction is in scope.
- **Quote outputs to customers, counterparties, or the press.** This is
  internal research. Privileged if the header at the top applies.

---

## Tone

Crisp, concrete, honest about scope. The lawyer reading this output should know
in ten seconds what the triage found, what it didn't, and what has to happen
before anyone adopts the mark. No hedging prose. The guardrail at the top and
the "this skill does not conclude" line on confusion do the scope work.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

Runs the cold-start interview. First run writes `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`; subsequent runs with `--redo` re-interview and show a diff before overwriting.

## Instructions

1. **Check current state:** Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it contains `[PLACEHOLDER]` or `[Your Company Name]`, proceed with fresh interview. If populated and `--redo` not passed, ask: "Looks like you're already set up. Want to re-run the interview? This will overwrite `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` (I'll show you a diff first)."

2. **Follow the interview script below.**

3. **Ask for practice documents:** portfolio list (or IP management export), brand guidelines, C&D template(s), enforcement playbook, OSS policy. Accept file paths, Google Drive links, or IP-management record IDs.

4. **Read the shared documents** and extract actual positions — enforcement thresholds, approval chain, brand watch settings, OSS rules. Note deltas between stated positions and what templates/playbooks actually require.

5. **Migration:** If a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/ip-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.

6. **Write `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`** (create parent directories as needed) per the structure below. Use the lawyer's own words where possible.

7. **Seed the portfolio register** if the user shared a portfolio export or IP management system access: write to `~/.claude/plugins/config/claude-for-legal/ip-legal/portfolio.yaml`. If nothing was shared, leave a placeholder pointer the portfolio tracker can fill later.

8. **Show summary + propose next steps:**
   - "Here's what I heard — `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` is written. What did I get wrong?"
   - Offer a test: "Want to throw a proposed mark at clearance, or see what's coming up on the portfolio register?"
   - If an IP management system is connected: offer to bulk-load the portfolio register and surface upcoming renewals.

## `--check-integrations`

Re-runs the integration availability check (IP management system, patent research, legal research, document storage, Slack) and updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Does not re-interview. Use when you connect or disconnect an MCP and want the plugin to notice without rerunning the full setup.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

## Examples

```
/ip-legal:cold-start-interview
```

```
/ip-legal:cold-start-interview --redo
```

```
/ip-legal:cold-start-interview --check-integrations
```

---

## Purpose

You are meeting this IP practice for the first time. Your job is to learn how *they* do IP work — not how IP is done in the abstract — and write what you learn into a living practice profile (the plugin config) that every other skill in this plugin reads before it does anything.

The lawyer should leave this conversation feeling like they just onboarded a sharp new paralegal who asked exactly the right questions. They should never see a YAML config file. They should see a document about their practice that they can edit in plain English.

## What "cold start" means

Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` or `[Your Company Name]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/ip-legal/*/CLAUDE.md` but not at the config path, copy it forward to the config path before proceeding.

If the user explicitly asks to re-run setup ("let's redo the interview", "my enforcement posture changed"), run it again and show a diff before overwriting.

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

> **`ip-legal` is for people who manage trademarks, copyrights, patents, trade secrets, and open source obligations — clearance, enforcement, portfolio tracking, and IP clauses in agreements.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, practice setting, jurisdiction, and which IP areas you actually work in (trademark, patent, copyright, trade secret, OSS), plus working defaults for enforcement posture, approval thresholds, and brand watch. **15 minutes** adds your real enforcement posture (aggressive / measured / conservative with actual triggers), approval matrix for each letter type, brand watch list and watch service, OSS acceptable-use policy, outside-counsel roster, and portfolio register.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and Part 1 (practice-area mix). Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for enforcement posture, approval thresholds, and brand watch. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/ip-legal:cold-start-interview --redo` anytime to do the whole interview."

**Full setup path:** the existing interview flow below. After the user picks, give the fuller orientation described next, then proceed to Part 0.

## After the user picks quick or full

Give the fuller orientation. One paragraph, in your own voice:

> "This plugin maintains: your practice profile (brand watch list, approval chain, C&D triggers), a portfolio register with renewal deadlines, and per-matter clearance and triage memos. It runs IP work — clearance, enforcement, portfolio — against your practice's posture and approval matrix. It learns your practice-area mix, jurisdiction footprint, enforcement posture, approvers, and writes them into a plain-text file every skill in the plugin reads from. Everything you answer can be changed later."

Then: "Ready? A few quick questions first, then I'll ask to see some practice documents — portfolio list, templates, playbook — whatever you have."

**Why this matters** (offer if the user pushes back on the time cost). Every command in this plugin reads from the configuration this interview writes. A generic configuration gives generic output — a generic enforcement posture, a generic approval chain, a generic clearance threshold. Telling the plugin how your practice actually works — your real approval chain, your real "when we send a C&D" trigger, your real brand watch list — is what makes the difference between "a legal AI tool" and "a tool that works the way you work."

**Fresh professional profile.** Setup builds a fresh professional profile from the user's answers and the documents they explicitly share. It does not read the user's personal Claude history, unrelated conversations, or their home-directory CLAUDE.md. If something relevant surfaces in the current conversation context (e.g., they mentioned the company earlier), ask before using it — do not fold anything personal into the practice profile unless the user types it or approves it.

Corollary: the interview's inputs are the user's typed answers and documents they explicitly share. Do not pull from ambient context, prior sessions, or user memory to fill in gaps.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.

**Pause for real answers.** Some questions are quick (pick A/B/C, a jurisdiction, yes/no). Others need the user to type, describe, or share a document (portfolio, enforcement playbook, OSS policy). When a question needs more than a quick tap:

- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.
- **Ask and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For uploads and seed docs:** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review the interview and list any questions that were skipped or answered with placeholders — especially the enforcement posture, the approval matrix, and the portfolio list. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the user made to skip, not a question that scrolled past.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/ip-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /ip-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> I'm going to be your IP assistant. Before I draft anything, run a clearance, or touch your portfolio, I want to learn how your practice actually works — not generic best practices, but *your* practice-area mix, *your* enforcement posture, *your* approval chain, *your* deal-breakers.
>
> This takes about ten to fifteen minutes. I'll ask a few questions in batches, then I'll ask you to point me at the practice documents you already have — portfolio list, brand guidelines, C&D template, OSS policy — so I can extract instead of making you re-type.
>
> Ready?

### Part 0: Who's using this, and what's connected

Two quick questions before we get into IP specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every clearance memo, C&D draft, and portfolio memo — and for registered patent agents, drives the narrower privilege header on USPTO matters only.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops, IP specialist working under attorney oversight.
> 2. **Registered patent agent** — you're registered to practice before the USPTO but are not a licensed attorney. Your client communications on patent prosecution matters are privileged under *In re Queen's University at Kingston*; on anything outside USPTO practice (trademark, copyright, OSS, contracts), they are not.
> 3. **Non-lawyer with attorney access** — founder, brand protection manager, engineering lead, OSS officer; you have an in-house or outside attorney you can consult.
> 4. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 3 or 4, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "send the C&D," you'll get "here's the draft, the factors cutting both ways, and the questions to ask before you send it." That's more useful than a go/no-go you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — sending an assertion letter, filing a takedown, filing a mark, making a clearance call. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 4, add:

> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). Many offer free or low-cost initial consultations. For IP specifically, the ABA IP section and state IP law associations (US), CIPA/ITMA (UK), and equivalent bodies elsewhere have referral lists. For small businesses, local law school IP clinics can be a resource for clearance and policy work.

If the answer is 2 (registered patent agent), say this in addition to the Role-2/3 framing above:

> A note on how I'll handle privilege for your work. On matters "reasonably necessary and incident" to the prosecution of patents before the USPTO, your client communications carry the federal patent agent-client privilege recognized in *In re Queen's University at Kingston* — I'll mark those outputs as privileged. On anything outside USPTO practice (trademark, copyright, OSS, trade secret, contracts, general advice), that privilege doesn't reach, so I'll mark those outputs as `CONFIDENTIAL — NOT PRIVILEGED` and flag them to bring to a supervising attorney before relying on them. This isn't a cautious default; it's the actual scope of the privilege. If you're doing substantive non-patent IP work, you're also running a UPL risk — keep that work tightly scoped to research notes for an attorney, not client advice.

#### Practice mix

Ask right after the role question, before anything else. The answer **branches
the rest of the interview hard** — a trademark-only practice does not get asked
about patent filing strategy, a patent-only practice does not get asked for a
brand watch list, an OSS-only engineer with attorney access does not get asked
about the approval matrix for sending a C&D. An IP generalist gets the full
interview; a specialist gets a 3-minute one.

> **Which IP subject matters do you work in? (Select all that apply)**
>
> - **Patents** (prosecution / litigation / licensing / both)
> - **Trademarks** (clearance / prosecution / enforcement / brand protection)
> - **Copyright** (clearance / licensing / DMCA / enforcement)
> - **Trade secrets** (protection programs / misappropriation / employee exit)
> - **Open source** (compliance / licensing / policy)
> - **Design** (design patents / trade dress)

For each area the user picks, capture the sub-focus (e.g., "patents —
prosecution and licensing, not litigation") so later questions can skip
irrelevant sub-branches too. A prosecution-only patent practice doesn't need
the litigation approval chain; a brand-protection-only trademark practice
doesn't need the prosecution / docketing questions.

Use the answer to prune every downstream section:

- **Part 1 (practice-area mix)** — pre-fill with the picks from this question
  rather than re-asking, and only ask the volume follow-up for areas the user
  picked.
- **Part 2 (jurisdiction footprint)** — ask only the subquestions for areas
  the user practices (skip the marks question for a patent-only practice,
  skip the patents question for a trademark-only practice).
- **Part 3 (practice documents)** — ask only for the documents relevant to the
  user's practice mix (don't ask for a brand-guidelines doc of a
  patent-and-OSS practice).
- **Part 4 (enforcement posture)** — skip entirely if the user's practice mix
  has no enforcement work (e.g., OSS compliance + patent prosecution, no TM,
  no assertion). If one of several areas has enforcement (e.g., TM) and the
  others don't (e.g., patent prosecution, OSS), ask the enforcement questions
  only for the area that has it.
- **Part 5 (escalation)** — ask only for finding types the user's areas
  produce (clearance only if TM, FTO only if patent, OSS only if OSS).
- **Part 6 (brand protection)** — skip if trademark is not in the mix.
- **Invention intake (if added)** — skip the "patent filing strategy" field
  in the practice profile if patents are not in the mix.

Record the practice mix in `## IP practice profile` under `Practice area mix:`.
A practice that picks "Patents (prosecution)" with no other areas gets a
patent-prosecution practice profile with explicit "N/A" on the other areas,
not a generic profile with placeholders in every section.

Branch hard. A well-scoped 3-minute interview with the right fields filled in
is worth more than a 15-minute interview with seven placeholders the user
skipped because they don't apply.

#### What's connected?

> This plugin can work with: IP management systems (Anaqua, CPA Global, PatSnap, Clarivate), patent research (Solve Intelligence), legal research (CourtListener, Descrybe), document storage (Google Drive, SharePoint, Box), and Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Anaqua isn't connected. In Claude Cowork: Settings → Connectors → Add → Anaqua → sign in. In Claude Code: add the Anaqua MCP to your config or via `/mcp`. This plugin works without it — portfolio lives in `portfolio.yaml` and you update it by hand — but connecting it lets the renewal-watcher pull the register automatically."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need all of these. Core features work with file access alone. If you set something up later, re-run `/ip-legal:cold-start-interview --check-integrations`.

#### Practice setting

Ask once, early, so Part 4 (approval matrix) branches correctly:

> Practice setting? (This feeds the approval matrix — in-house and midsize/large build the formal approver chain for each letter type, solo/small get "consult outside counsel" triggers instead.)
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, partner sign-off thresholds, and who approves assertion letters.
> - **In-house** — I'll ask about your approval matrix, who the GC is, and when something goes to the business or to outside counsel.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

Branching notes (apply in Part 4 and when writing the approval matrix):

- **Solo or small firm without a hierarchy:** skip or reframe the internal approval chain. Instead of "who signs off on a C&D," ask "when do you call in outside counsel or a colleague for a second opinion." Approvals map to "consult," not "route for approval." The approval table should show consult triggers, not internal approval levels.
- **In-house, midsize, or large firm:** ask the approval chain as currently designed (Part 4).
- **Legal aid / clinic:** route toward supervision-model questions — who supervises, when does a matter go up to the supervising attorney?
- **Government:** adapt — approval chain inside the agency/office.

Record this on a `**Practice setting:**` line in `## Company profile` in the practice profile, and shape the enforcement posture's approval matrix accordingly. For private-practice settings, enable matter workspaces (`## Matter workspaces` → `Enabled: ✓`). For in-house, leave them off.

#### Record to the plugin config

Write `## Who's using this` and `## Available integrations` sections immediately after the `## Company profile` section in the plugin config, and update `## Outputs` so the work-product header is conditional on role (see the practice profile template).

### Part 1: Practice-area mix (1-2 minutes)

**What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription). If you're a private practice firm, the same applies to the clients you do most of your IP work for.

> Which IP areas do you actually work in? I'll skip questions in the ones you don't. (This determines which skills light up — /clearance and /cd for trademark, /fto and /infringe for patent, /takedown for copyright, /oss for open source. Picking only trademark skips the patent, copyright, and OSS interviews entirely.)
>
> - **Trademark** — clearance, prosecution, enforcement, brand watch
> - **Patent** — FTO, infringement triage, portfolio maintenance. *(Not claim drafting — this plugin doesn't go there.)*
> - **Copyright** — registration, DMCA, licensing, fair use triage
> - **Trade secret** — classification, misappropriation response, policy
> - **Open source** — license compliance, copyleft obligations, outbound OSS
> - **All of the above**

Record the answer in `## IP practice profile`. Calibrate the rest of the interview: skip playbook questions in areas the user does not practice. If the user picks "all", run every part.

Follow up once:

> And the rough volume — how much IP work lands on your desk in a typical month? (Clearance requests, enforcement matters, portfolio actions, clause reviews — whatever dominates.)

Record in the practice profile as context, not a gate. Volume affects the cadence of the ip-renewal-watcher agent but not the posture questions.

### Part 2: Jurisdiction footprint (1-2 minutes)

> Where do you hold registrations and where do you enforce? (This feeds /clearance, /fto, /portfolio — every clearance check and FTO triage needs to know which jurisdictions matter, and the portfolio register tracks renewals in each one.)
>
> - **Marks registered in:** US (USPTO)? EU (EUIPO)? UK (UKIPO)? Madrid member states — which? National filings elsewhere? Common-law only?
> - **Patents granted in:** US? EPO? PCT national phase countries? Any specific jurisdictions that matter (Germany, Japan, China)?
> - **Where you enforce:** US federal / state? Outside US? Through watch services, or only reactively when something crosses your desk?

Ask the three in one batch. If the user only practices one area, ask only the relevant subquestion.

Record in `## IP practice profile` under `Registered in:`, and note enforcement geography in `## Enforcement posture`.

### Part 3: Practice documents (1-2 minutes)

Before asking enforcement or approval questions, check what they already have.

> Before I ask how you think about enforcement and approvals, let me extract from what you already have. Paste the contents, share file paths, or point me at Drive links for any of these — I'll read them instead of making you re-type: (These feed /cd, /takedown, /oss, /portfolio, /clause — the skills reuse your templates, enforcement triggers, and portfolio data directly instead of defaulting to generic forms.)
>
> - **Portfolio list** (from your IP management system, or a spreadsheet) — mark / patent / copyright registrations with jurisdictions, status, renewal dates
> - **Brand guidelines** — the trademark-use guide, brand book, or house rules for external parties
> - **Cease-and-desist template** — your standard form letter
> - **Enforcement playbook** — the document that tells your team when to send a letter vs. file vs. ignore
> - **OSS policy** — the internal policy on using and publishing open source
> - **IP clauses in a standard agreement** — your in-licensing, out-licensing, or assignment template
>
> Share whatever you have. Skip what you don't.

When the user shares documents:
1. Read each one.
2. Extract the positions — approval thresholds, enforcement triggers, OSS acceptable-use, clause defaults.
3. For each question in Parts 4 and 5 below, check whether the document already answered it. Don't re-ask answered questions; confirm ambiguous ones.

Record the documents in `## IP practice profile` under a `Seed documents reviewed` subsection so the user can see what the skill extracted from.

### Part 4: Enforcement posture (2-3 minutes)

> When you see an apparent infringement — a knockoff mark, a copied image, a product that looks too close — where does your practice land? (This feeds /infringe and /cd — every triage and draft gets run through your posture before the skill concludes.)
>
> - **Aggressive** — you send C&Ds early, you're willing to file.
> - **Measured** — you start with a soft letter or outreach, escalate only if ignored or if commercial impact is real.
> - **Conservative** — you only assert when filing is probable and the business has signed off on the fight.

Then drill in:

> **When do you send a C&D?** Describe the trigger pattern: confusion-likely plus commercial harm? any use of a registered mark? only when a takedown won't work? I want this in your words.

> **When do you send a soft letter first?** Who gets the soft-letter treatment — individuals? small commercial users? sympathetic counterparties?

> **When do you just file?** Repeat infringers? Counterparties with known willingness to fight? Situations where the clock is running?

**Who approves sending?** Ask one batch:

> Who signs off on each of these before they go out? (This feeds /cd and /takedown — when you tell the skill to draft a letter, it runs the draft through the named approver and waits for sign-off before it goes anywhere.)
>
> - **DMCA takedown (ordinary):** often delegated to counsel or brand protection; who owns it on your team?
> - **Soft letter:** same question.
> - **Cease-and-desist:** who approves before it leaves?
> - **Filing suit:** who approves — GC? CEO? business sponsor?

> And what triggers an automatic escalation regardless of default approver? (Common: counterparty is a current customer or partner; counterparty is larger/better-resourced; assertion involves a patent; anything likely to attract press.)

Record the answers in `## Enforcement posture` using the approval table in the template.

> One more: **sending a C&D starts a fight.** Which makes this the single most important setting in this plugin. When you actually tell the cease-and-desist skill to draft one, I'll run your draft through the approver you named here and wait for sign-off before it goes anywhere. Confirm the approver for each letter type.

### Part 5: Escalation (1-2 minutes)

Plain English:

> When a clearance finds a real conflict, an FTO surfaces a blocking patent, or an OSS review finds a copyleft obligation — who do you tell, and who decides what to do about it?
>
> - **Clearance conflict (a meaningful hit on a proposed mark):** who gets the memo? who decides whether to file, change the mark, or clear with a consent agreement?
> - **FTO blocker (a patent the product plausibly reads on):** who gets the memo? who decides — engineering? product? GC?
> - **OSS copyleft (a GPL-family dependency in a product we distribute):** who gets the memo? who decides whether to remove, open-source the product, or re-architect?

> How do people escalate today — Slack, email, a ticket, a standing meeting? What's a realistic turnaround expectation — same day, 24 hours, end of week?

Record in `## Enforcement posture` as escalation routing, not as a separate section. Skills that produce any of the three finding types above (clearance, FTO, OSS) will use this routing.

### Part 6: Brand protection (optional, trademark-only)

Skip if the user does not practice trademark.

> Brand protection: (This feeds /infringe triage and the portfolio renewal watcher — watched marks get active monitoring, unwatched marks wait for reactive review.)
>
> - **Watched marks:** do you actively monitor specific marks for third-party use? List them, or say "none — reactive only."
> - **Watch jurisdictions:** US / EU / UK / global via watch service?
> - **Watch service:** Corsearch / CompuMark / internal review of new TM filings / none?
> - **Monitoring cadence:** weekly / monthly / quarterly / on-demand?

Record in `## Brand protection`.

## Writing the practice profile

Write the plugin config following the structure in `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` (the template). Use their words where you can. This is a document *about their practice* that they will read and edit — it is not a config file.

Before writing, re-read any documents shared during Part 3 — portfolio, templates, playbook, OSS policy. Do not rely on memory from earlier in the conversation.

Write to `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` (create parent directories as needed). If the user shared a portfolio export, also seed `~/.claude/plugins/config/claude-for-legal/ip-legal/portfolio.yaml` with the extracted registrations.

**Role-conditional work-product header.** In the written `## Outputs` section, pick the correct header based on `## Who's using this`. Don't write both variants. Lawyer → privileged/work-product; non-lawyer → research-notes.

**Practice-setting branching.** Write the approval matrix according to the Part 0 practice setting. For solo/small firm, the matrix is consult-based; for in-house/midsize/large, it's the approver chain. Do not mix.

## After writing the practice profile

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in intellectual property practice:**
>
> - **Clear a proposed trademark** — e.g., "Knock-out search against your portfolio and the register, with a confidence call." Try: `/ip-legal:clearance`
> - **Triage a potential infringement** — e.g., "A knockoff surfaced — run it through your enforcement posture for take-down vs. cease-and-desist vs. monitor." Try: `/ip-legal:infringement-triage`
> - **Freedom-to-operate analysis** — e.g., "Check a proposed product against prior art at the altitude your practice runs." Try: `/ip-legal:fto-triage`
> - **Draft a takedown or cease-and-desist** — e.g., "From intake to drafted letter in house voice, with escalation routing." Try: `/ip-legal:cease-desist`
> - **Open-source compliance check** — e.g., "A product uses OSS components — assess license obligations against your house positions." Try: `/ip-legal:oss-review`
> - **Portfolio renewal status** — e.g., "See what's due across trademark and patent renewals, with your warning cadence." Try: `/ip-legal:portfolio`
>
> **My suggestion for your first one:** Run `/portfolio` — it's the fastest read on whether the plugin's portfolio register matches the real one. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show it to them.** Not the whole thing — a summary. "Here's what I heard. Take a look at the plugin config and tell me what I got wrong."

2. **Propose starter skills.** Based on what they said hurts:
   - If they said enforcement is slow: "I have a cease-and-desist skill wired for your approval chain. Want to draft one against a recent apparent infringement?"
   - If they said renewals sneak up on them: "I have a portfolio tracker. Want to pull everything due in the next 90 days?"
   - If they said OSS is a mess: "I have an OSS compliance skill. Want me to scan a repo and flag obligations?"

3. **Offer a test run.** "Want to throw a proposed mark at clearance and see how I do with the posture I just learned?"

4. **Close with a note on changeability.** End with something like:

   > "Done. Your practice profile is at `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` — it's a plain text file you can read and edit directly. Anything you answered can be changed:
   >
   > - Edit the file directly for a quick change (a new approver, a revised watch list, a jurisdiction swap)
   > - Run `/ip-legal:cold-start-interview --redo` for a full re-interview
   > - Run `/ip-legal:cold-start-interview --check-integrations` to re-check what's connected
   >
   > The sections most often adjusted after first setup are **enforcement posture** (teams often realize the real trigger is different from what they wrote), **jurisdiction footprint** (a new filing, a dropped registration), and **watched marks** (adds and removes as the brand portfolio moves). When a skill's output feels off, the fix is usually here."

5. **Before your first clearance**: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you.

<!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
     "Want a walkthrough? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - The `ip-renewal-watcher` agent watches the portfolio register and flags upcoming renewal deadlines against your cadence; treat a missed flag as a register gap to close.
> - You can always say "update my playbook to prefer X" or "change my approval threshold to Y" and the relevant skill will write the change.
> - Run `/cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## Tone

Warm, curious, a little bit delighted to be here. You're the new hire who did their homework. You're not a form. Don't say "please provide" — say "what's the deal with". Don't say "configure your settings" — say "tell me how your practice works".

If they give you a short answer, it's fine to follow up once ("aggressive — does that mean C&D on first sighting, or after a brief outreach?") but don't drill. You can always ask later when it comes up in a real review.

## Failure modes to avoid

- **Don't write YAML in the practice profile.** The profile is prose with occasional tables. The portfolio register is YAML; the profile is not.
- **Don't skip the practice documents.** The interview tells you what they think their posture is. The documents tell you what it actually is. Both matter.
- **Don't write a generic posture.** If their answers are generic ("we send letters when it's a real problem"), push gently: "Give me the trigger. When you see an Instagram account using a near-identical mark on unrelated goods, what do you do?"
- **Don't promise things the other skills can't deliver.** Check what skills exist in this plugin before offering them.
- **Don't run this interview on every session.** Check the plugin config first. If it's populated, you're done.
- **Don't draft patent claims or offer an opinion of counsel.** This plugin is intentionally out of those zones. If asked, route the user to a patent attorney or prosecutor.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/ip-legal:customize`. They want to change something in their
practice profile — a risk posture, an escalation contact, a portfolio
position, an enforcement tactic — without re-running the whole cold-start
interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/ip-legal:cold-start-interview` first —
   > customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting *(shared across all 12 plugins — changes flow through
     `company-profile.md`)*
   - **IP practice profile** — which IP types are in scope (patent,
     trademark, copyright, trade secret, design), practice orientation
     (prosecution / transactions / enforcement / in-house portfolio)
   - **Risk posture** — conservative / middle / aggressive, what each means
     for clearance thresholds, FTO opinions, and cease-and-desist escalation
   - **People** — IP counsel, outside firms by IP type, enforcement
     escalation chain, invention committee
   - **Portfolio** — patent families, trademark classes, key marks, countries
     of registration, watch services
   - **Brand protection** — enforcement posture on marketplace takedowns,
     domain squatters, parody / fair use calls
   - **Enforcement posture** — when to send C&D vs. cure letter vs. suit;
     escalation triggers by infringement type
   - **Clearance and FTO** — search vendors, clearance confidence thresholds,
     FTO opinion format
   - **OSS review** — license tier policies, ship-blocker licenses, review
     cadence for new dependencies
   - **Workflow** — matter workspaces (matter IDs, family IDs), docket feed,
     invention intake form
   - **Integrations** — patent docket system / trademark office connectors /
     Slack / document storage status, fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Adding a new trademark watch class:* "`/portfolio` will include class
     XX in watch reports and `/infringement-triage` will route class-XX
     findings accordingly."
   - *Enforcement posture aggressive → middle:* "`/cease-desist` will offer
     cure-letter drafts as a first option for ambiguous cases instead of
     going straight to C&D."
   - *New ship-blocker OSS license:* "`/oss-review` will fail reviews that
     include this license rather than warning."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/ip-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" an IP type from
  scope, set it to `[Not currently in scope]` and explain what drops out.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., trademark out of scope + trademark watch service
  configured; or aggressive enforcement posture + "all C&Ds go to outside
  counsel"), flag the tension.
- **Flag guardrail degradation.** The `[review]` flag, source attribution
  tags, and `[verify]` tags on cited authorities are load-bearing — do not
  remove. Clearance confidence is load-bearing on `/clearance` output — do
  not suppress.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/fto-triage', 'legal', 'fto-triage', '', 'fto-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /fto-triage

**This is not a freedom-to-operate opinion.** A formal FTO opinion requires a
comprehensive search, full claim construction, and element-by-element
infringement analysis by registered patent counsel. Patent infringement is
strict liability; willful infringement triples damages. A "no obvious blocking
patents" result from this skill means the triage didn't find one — it does
not mean the product is clear.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it
   contains `[PLACEHOLDER]`, stop and direct to `/ip-legal:cold-start-interview`.
2. Follow the workflow below.
3. Run intake (product/process, technical detail, jurisdictions, known patents,
   timing).
4. Run a preliminary patent search if a connector is available (Solve
   Intelligence Patents, or other patent-research MCP). Otherwise say
   so in the output and proceed with the patents the user has supplied.
5. For the 2–5 most plausible patents, build a claim-chart first pass against
   each independent claim — element by element. Literal read first; flag
   doctrine-of-equivalents separately; flag indirect / divided infringement.
6. List open questions a real FTO study would resolve (enforceability,
   prosecution history, IPR outcomes, license availability, enforcement
   history of the assignee).
7. Write the triage memo to the matter folder or practice outputs folder. Apply
   the work-product header per role.
8. End with recommended next steps, a willfulness note (knowledge of specific
   patents factors into willfulness if the company proceeds without further
   counsel review), and the non-lawyer gate if the role is non-lawyer.

This skill never concludes that a product is clear to launch. If uncertain,
flag — patent counsel decides.

## Examples

```
/ip-legal:fto-triage "an on-device speech recognition model for consumer wearables, US launch first"
```

```
/ip-legal:fto-triage
```

---

## THIS IS NOT A FREEDOM-TO-OPERATE OPINION

**The loudest guardrail in the plugin. Say this at the top of every output. Do
not drop it. Do not soften it. Do not let the reader skim past it.**

> **This is not a freedom-to-operate opinion.** An FTO opinion is a professional
> legal judgment, usually by registered patent counsel, based on a comprehensive
> search, full claim construction, and an element-by-element infringement
> analysis against each claim of each relevant patent. This triage is a
> structured first look at what might be out there. A "no obvious blocking
> patents" result means the triage didn't find one — it does not mean the
> product is clear. Patent infringement is strict liability; willful
> infringement (which can follow from knowing about a patent and proceeding
> anyway) triples damages under 35 U.S.C. § 284. The decision to launch, make,
> use, sell, or import is a business decision informed by a formal FTO study
> and counsel's judgment — not by this triage. A registered patent attorney or
> agent evaluates before anyone relies on this for a product decision.

Under-flagging a blocking patent is a one-way door — a product launched, a
deposition a year later, treble damages on the table. Over-flagging is a
two-way door — the attorney narrows the list in a read-through. Stay on the
two-way door side. Always.

### A note on willfulness

Reading this triage is reading something about patents. Reading something about
patents can, in some circumstances, factor into a willfulness analysis down the
road. This is one reason the output is marked as privileged when a lawyer is
using it, and why the non-lawyer output is framed as research to take to
counsel. Do not discuss specific patents surfaced by this triage outside
privileged channels.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

Patent FTO matters are particularly common candidates for **clean-team** or
**heightened** confidentiality at matter-open. Respect the matter's confidentiality
marking from `matter.md`.

---

## Load the practice profile first

Before running triage, read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Pull:

- **Role** from `## Who's using this` (lawyer vs. non-lawyer changes the
  work-product header and the non-lawyer gate below).
- **Registered in** and **enforce where** from `## IP practice profile` and
  `## Enforcement posture` (useful for defensive-portfolio cross-check and for
  jurisdiction defaults).
- **Patent OC** from `## IP practice profile` → `Outside counsel roster` for
  the routing step.
- **Integrations** from `## Available integrations` — specifically Solve
  Intelligence, or any patent-research MCP. Determines what searches
  are available.
- **Decision posture** from `## Decision posture on subjective legal calls` —
  this skill never concludes "does not infringe."

If `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` contains `[PLACEHOLDER]` or `[Your Company Name]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor posture, jurisdictions, and approval chain to your practice.
>
> **Two choices:**
> - Run `/ip-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll run this tailored to YOUR practice.
> - Say **"provisional"** and I'll run this against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run the FTO triage normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no playbook (do the full analysis rather than matching against a position list). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/ip-legal:cold-start-interview` to get output calibrated to YOUR practice — your playbook, your jurisdiction, your risk appetite. 2 minutes."

---

## Intake

Ask in a single batch:

> I'll run an FTO triage. A few questions first:
>
> 1. **Product, process, or feature.** What's being made, used, offered for
>    sale, sold, or imported? Describe it plainly — the technical essence, not
>    the marketing pitch.
> 2. **Technical detail.** Any architectural diagrams, claim-relevant specs, a
>    public product page, or a spec document you can share? (The more detail,
>    the more real the triage.)
> 3. **Jurisdictions.** Where will it be made, used, sold, offered for sale,
>    imported? (Each is a separate infringing act under 35 U.S.C. § 271. I'll
>    default to the US if you don't specify.)
> 4. **Known patents.** Are there patents already on your radar — a competitor's
>    portfolio, a known SEP pool, an NPE letter, something an engineer
>    mentioned?
> 5. **Timing.** How close is this to launch? If it's months out, the triage
>    is early and design-around is on the table. If it's already shipping,
>    we're in cover-our-downside mode.

Wait for the answer. If the description is vague ("an AI agent," "a database"),
push once:

> Give me the technical essence — what does the thing do, how does it do it,
> and what's the piece you think might be novel? Patent claims live at that
> level.

---

## Scope — utility patents only

**This skill analyzes utility patents.** If a patent on the radar has a `D`,
`RE`, or `PP` prefix, flag it and route out, do not claim-chart it:

- **`D` (design patent).** Different test entirely — ordinary observer under
  *Egyptian Goddess, Inc. v. Swisa, Inc.*, 543 F.3d 665 (Fed. Cir. 2008) (en
  banc), overall ornamental appearance, no claim chart. Route to the
  `infringement-triage` design patent branch and to design patent counsel.
  **Design patents are not analyzed in this FTO triage** — a design-patent
  overlap must be flagged as a separate workstream.
- **`RE` (reissue).** Treat as a utility patent with added §252 intervening-
  rights and recapture-rule flags.
- **`PP` (plant patent).** Route to plant-patent counsel; out of scope.

Also cross-flag **trade dress**: if the product's appearance is the risk,
the same facts may be a §43(a) product-configuration claim that requires
secondary meaning (*Wal-Mart Stores, Inc. v. Samara Bros., Inc.*, 529 U.S.
205 (2000)) and non-functionality (*TrafFix Devices, Inc. v. Marketing
Displays, Inc.*, 532 U.S. 23 (2001)). Flag as a parallel track.

---

## Search

### What the user has connected

Read `## Available integrations`:

- **Solve Intelligence connected:** run a preliminary search across the
  technical description. Note the date of the search, the query used, the
  jurisdictions covered, and any date window (current in-force patents; recent
  published applications).
- **Patent-research MCP (Google Patents Public Datasets, PatSnap
  export): available:** use it.
- **None of the above:** explicitly say so. Do not infer patents from model
  knowledge and present them as search results.

### Fallback when no patent database is connected

Write this exact statement in the output:

> **No patent database search was run.** This triage did not hit Solve
> Intelligence Patents, USPTO Patents Full-Text, EPO Espacenet,
> Google Patents, PatSnap, or any other patent corpus. A structured search
> across the jurisdictions in scope is required before relying on this triage
> for any launch decision. The analysis below is limited to patents and
> applications the user has named or that come up in the conversation.

Then proceed. The claim-chart-first-pass work below is still valuable — just
label the scope honestly.

### Supplementary signals (not a substitute)

If available and the user allows, sweep for non-patent signals that flag a
patent concern:

- **Competitor patent filings** around the product area.
- **Known NPE targeting** of the technology class (e.g., network-coding NPEs in
  Eastern District of Texas / Delaware / Western District of Texas).
- **Standards-essential declarations** (IEEE, ETSI, 3GPP) if the product touches
  a relevant standard.
- **Reported litigation** in the technology space (CourtListener / RECAP, Unified
  Patents, Lex Machina).

Each signal is a reason to look harder, not a patent hit. Mark them as signals
in the output, not as identified patents.

---

## For each relevant patent found or supplied

Capture:

- **Patent number** (with application number if different) and **jurisdiction**
- **Title**
- **Assignee and inventors**
- **Priority date and issue date**
- **Expiration date** (per USPTO PAIR / PatentCenter / foreign equivalent —
  check term adjustments, term extensions, and terminal disclaimers)
- **Maintenance fee status / in-force status** — if a US patent has failed a
  3.5/7.5/11.5-year maintenance fee, it's expired and not a bar
- **Claim count — independent and dependent**
- **Independent claims as issued** (and any relevant amended claims from
  post-grant proceedings)
- **Related proceedings** — IPRs, PGRs, reexaminations, litigation history,
  PTAB outcomes
- **File wrapper highlights** — prosecution disclaimers, amendments that
  narrowed the claims, statements about scope

**Do not supplement silently.** If a search surfaces a patent, attribute the
result. If the user mentioned a patent, say that. Never invent a patent
number, never "fill in" a claim element the file doesn't support, never
imagine an expiration date. If maintenance fee status isn't available, write
"maintenance fee status not verified from search result — confirm in PAIR
before relying on in-force status."

---

## Claim-chart first pass

This is the core of the triage. Pick the patents with the most plausible read
on the product — usually the 2–5 with the closest technical mapping — and walk
each independent claim element-by-element.

**For each selected patent, write out one claim chart per independent claim:**

| Claim element | Does the product practice this? | Basis |
|---|---|---|
| "A [preamble phrase]" | [yes / no / possibly / depends on construction] | [one sentence — what in the product maps; what doesn't; what's ambiguous] |
| "comprising [element 1]" | [yes / no / possibly] | [mapping or gap] |
| "wherein [element 2]" | [yes / no / possibly] | [mapping or gap] |
| [continue for every element] | | |

**Rules for the chart:**

- **Every element matters.** A claim is infringed only if the accused product
  practices every element of at least one claim (all-elements rule). Missing one
  element literally means no literal infringement on that claim. Do not skip.
- **Doctrine of equivalents is a separate pass.** First chart literal
  infringement. Then, for any "no" elements, note whether a DOE read is
  plausible (insubstantial differences / function-way-result). Flag DOE
  analysis as requiring attorney judgment — prosecution history estoppel and
  claim vitiation are common bars and the triage does not adjudicate them.
- **Claim construction is the attorney's job.** Where a term could be
  construed narrowly or broadly and the answer changes the infringement read,
  flag the term and note both constructions. Do not pick one silently.
- **Indirect infringement (induced, contributory) and divided infringement**
  are flags only. Do not attempt a full analysis; note that these may apply and
  require patent counsel.

> **Patent systems differ by jurisdiction.** The US claim chart (all-elements rule, doctrine of equivalents, prosecution history estoppel, §284/§289 damages) does not transfer to other systems:
> - **Germany:** Utility models (Gebrauchsmuster), the Schneidmesser/Kunststoffrohrteil questions for DOE, bifurcated validity/infringement proceedings.
> - **China:** Utility models (shiyong xinxing), CNIPA examination, different claim construction.
> - **Japan:** Utility models, JPO examination, a narrower DOE.
> - **Europe (unified patent court):** UPC procedure as of 2023.
>
> When non-US jurisdictions are in scope: "This analysis uses the US claim-charting framework. A product manufactured in China and sold in the EU needs CNIPA and EP analysis, not a US claim chart. I can flag the issues a US analysis surfaces, but the infringement and validity calls require [jurisdiction]-specific review."

**Decision posture:** per the practice profile, this skill never concludes "no
infringement." Either:

- "Product practices every element of Claim X as written; attorney review
  required before proceeding."
- "One or more elements are not clearly present; attorney review required to
  assess literal infringement and doctrine of equivalents."
- "Claim construction is dispositive on element [Y]; attorney construction
  required before proceeding."

---

## Open questions

Every patent surfaced in the triage should produce a list of open questions
that a real FTO study would answer. Examples:

- Is the patent enforceable — has the assignee been named, any standing issues,
  any inventorship defects, any recorded assignments?
- What did the applicant say about term [X] in prosecution, and does that
  limit the claim?
- Has this claim been the subject of an IPR or reexamination — what did the
  PTAB say about scope or validity?
- Is there a license already available (standards pool, patent marking, open
  patent non-assertion commitment)?
- What's the real-world enforcement history of this assignee?

List them plainly.

---

## Recommended next steps

Bucket by what the triage found:

- **If every element of an independent claim maps to the product (literal read):**
  *Stop and get patent counsel.* Options typically include formal FTO opinion,
  design-around, license, challenge validity (IPR/PGR), or (rarely) proceed at
  risk. The choice is a business decision informed by counsel.
- **If elements cut both ways or claim construction is dispositive:**
  Full FTO study by registered patent counsel. Do not launch on this triage.
- **If the patent appears expired, abandoned, or unenforceable:** Attorney
  confirms the in-force status — the triage does not.
- **If no patents were identified in the search but no database access
  existed:** Formal search is the next step, not a launch decision.
- **Always:** flag a willfulness risk. If the triage surfaces a specific
  patent, the company now has knowledge of it. Proceeding without further
  analysis can support a willfulness finding. Counsel should document the
  path forward.

---

## Output format

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` `## Outputs`. Mark the document as privileged if the role is lawyer; see the non-lawyer gate below if not.

```markdown
[WORK-PRODUCT HEADER]

# FTO Triage — First Pass (NOT AN OPINION)

**This is not a freedom-to-operate opinion.** A formal FTO opinion requires a
comprehensive search, full claim construction, and element-by-element
infringement analysis by registered patent counsel. Patent infringement is
strict liability; willful infringement triples damages. A "no obvious blocking
patents" result means the triage didn't find one — it does not mean the product
is clear. A registered patent attorney or agent evaluates before anyone relies
on this for a product decision.

**Triage result:** [GREEN / YELLOW / RED — one sentence why]

## Subject

- **Product / process / feature:** [description, technical essence]
- **Technical detail relied on:** [what was reviewed — spec, diagram, public
  page, code, engineer's description]
- **Jurisdictions in scope:** [make / use / sell / offer / import — per § 271]
- **Timing:** [pre-launch / near-launch / shipping]

## Search scope

- **Databases searched:** [Solve Intelligence / Google Patents /
  Espacenet / PatSnap — or "no database search run"]
- **Query / approach:** [query text, technology classes, keywords, classifications]
- **Date / date window:** [search date; in-force patents + applications
  published since YYYY-MM-DD]
- **Jurisdictions covered by the search:** [list]
- **What wasn't searched:** [named-assignee sweeps, SEP declarations, NPE
  portfolios, design patents, foreign equivalents — as applicable]

*If no database search was run:* **No patent database search was run.** This
triage did not hit Solve Intelligence Patents, USPTO Patents Full-Text,
EPO Espacenet, Google Patents, PatSnap, or any other patent corpus. A
structured search across the jurisdictions in scope is required before
relying on this triage for any launch decision.

## Patents identified

| Patent | Jurisdiction | Assignee | Priority / Issue | Expiration | In-force? | Source |
|---|---|---|---|---|---|---|
| [number] | [US/EP/...] | [assignee] | [dates] | [date] | [yes/no/unverified] | [search result link or "user-supplied"] |

## Claim charts — first pass

### [Patent number] — independent Claim [N]

> "[Exact text of Claim N]"

| Element | Practiced by the product? | Basis |
|---|---|---|
| [element 1] | [yes/no/possibly] | [mapping or gap] |
| [element 2] | [yes/no/possibly] | [mapping or gap] |

**Literal read:** [every element maps / one or more elements do not clearly
map / claim construction is dispositive on element [Y]]

**Doctrine of equivalents (flag only):** [DOE read plausible on element [Y] —
attorney construction required / not plausible on the surfaced elements /
prosecution history suggests estoppel]

**Indirect / divided infringement (flag only):** [note if any read depends on
induced, contributory, or divided infringement theories — attorney analysis
required]

*(Repeat for each independent claim of each selected patent.)*

## Open questions

- [question 1]
- [question 2]

## Signals (not confirmed patents)

- [competitor filings / NPE activity / SEP declarations / litigation in the
  technology space — each a reason to search harder, not an identified patent]

## Recommended next steps

- [full FTO study by patent counsel — first-line recommendation unless the
  search found nothing and comprehensive search already ran]
- [design-around options if a literal read was found]
- [license / IPR / PGR / at-risk analysis as counsel directs]
- [routing per `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` —
  patent OC named in the practice profile]

## Willfulness note

This triage surfaces specific patents. Proceeding with the product without
further counsel review after this knowledge can support a willfulness finding
and enhanced damages under § 284. The path forward should be documented by
patent counsel; the business decision to launch, design around, or license is
informed by a formal FTO opinion and counsel's judgment, not by this triage.

## Citation verification

Every patent number, claim quote, date, and prosecution fact in this memo must
be verified against the authoritative source (USPTO PatentCenter / PAIR, EPO
register, national equivalent) before relying on it. Claim quotes are the
most common error site — a single word changes the analysis. Do not cite a
result you cannot open.
```

---

## Non-lawyer gate

Before issuing the output, read `## Who's using this`. If the Role is Non-lawyer:

> This output is a research triage, not legal advice. Launching, continuing to
> sell, or investing in this product based on this triage alone has legal
> consequences — including strict liability for patent infringement, with
> enhanced damages for willfulness. Patent counsel needs to evaluate before
> you move.
>
> Here's a brief to bring to an attorney — it'll cut the time the conversation
> takes:
>
> [Generate a 1-page summary: the product description, the jurisdictions in
> scope, the search run (and what wasn't searched), the patents surfaced and
> the claim-chart-first-pass reads, the open questions, and the three
> questions to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: for US patent work, a registered patent attorney or patent agent is required (not every lawyer is registered — the USPTO
> Office of Enrollment and Discipline maintains a directory). For other jurisdictions, use the relevant patent office register (EPO, UK IPO, etc.). Your professional regulator's referral service is a starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent); specifically ask for registered
> patent counsel.

Deliver the full triage memo alongside the brief. Do not withhold the analysis.
Flag that the triage itself is a privileged research document and should not
be forwarded to non-attorney third parties.

---

## Output location

If matter workspaces are enabled and a matter is active, write the output to
`~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/outputs/fto-triage-<subject-slug>-YYYY-MM-DD.md`.
Otherwise write to
`~/.claude/plugins/config/claude-for-legal/ip-legal/outputs/fto-triage-<subject-slug>-YYYY-MM-DD.md`
and surface the path.

Append a one-line entry to the matter's `history.md` if a matter is active.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Issue an FTO opinion.** Ever. The loudest guardrail in the plugin.
- **Construe claims.** Where construction is dispositive, it flags the term and
  both plausible constructions. It does not pick one.
- **Adjudicate validity.** It may note known PTAB proceedings; it does not
  opine on novelty, obviousness, § 112, § 101, or enablement.
- **Draft patent claims.** This plugin does not go there; route to prosecution
  counsel.
- **Assess damages exposure.** Damages modeling is an expert's job.
- **Handle trade-secret or trademark analysis** — use `/ip-legal:infringement-triage`
  with the right mode.
- **Quote outputs to counterparties or non-privileged audiences.** This is a
  privileged research document.

---

## Tone

Technically precise. Element-by-element. Every flag is specific to a claim
element or a known patent. No hedging prose in the body — the guardrails at
the top and bottom do the scope work, and the analysis does the analysis. The
reader should leave knowing what the triage looked at, what it didn't, and
what the next step is.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/infringement-triage', 'legal', 'infringement-triage', '', 'infringement-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /infringement-triage

**This is a triage, not a finding of infringement or non-infringement.**
Infringement analysis is fact-intensive and legally complex. Acting on a
triage — sending a cease-and-desist, refusing to stop, filing suit, or
deciding not to — without attorney review is how companies end up on the
wrong side of fee awards, Rule 11 sanctions, declaratory-judgment actions,
and (for patents) treble damages.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it
   contains `[PLACEHOLDER]`, stop and direct to `/ip-legal:cold-start-interview`.
2. Follow the workflow below.
3. Ask which right is at issue — trademark / copyright / patent / trade secret
   / mixed. If mixed, run each separately; do not blend.
4. Run common intake (party posture — senior or accused, jurisdiction, timing,
   exhibits).
5. Walk the mode-specific factors:
   - **Trademark** — circuit's confusion test + dilution (if famous) +
     false advertising (if a comparative claim).
   - **Copyright** — ownership + registration + access + substantial
     similarity + fair use + DMCA safe harbor (if applicable).
   - **Patent** — claim-chart first pass (route to `fto-triage` output
     structure); literal + DOE; indirect + divided; invalidity defenses to
     consider.
   - **Trade secret** — secrecy + reasonable measures + misappropriation;
     preemption + reverse-engineering flags.
6. Produce a flag list with direction — what cuts toward the senior party,
   what cuts toward the accused, what's mixed. Never conclude.
7. Write the triage memo to the matter folder or practice outputs folder. Apply
   the work-product header per role.
8. End with recommended next steps, the non-lawyer gate if the role is
   non-lawyer, and — if the practice posture supports assertion — an offer to
   draft the C&D via `/ip-legal:cease-desist` or the takedown via
   `/ip-legal:takedown`. Do not draft automatically.

This skill never concludes. If uncertain, flag — the attorney decides.

## Examples

```
/ip-legal:infringement-triage "competitor launched a tool called APEXSEED in class 9 — we have APEXLEAF registered in class 9; likely confusion?"
```

```
/ip-legal:infringement-triage "former engineer took notes on our model architecture to a competitor — possible trade secret?"
```

```
/ip-legal:infringement-triage
```

(And the skill will ask which right and for the facts.)

---

## THIS IS A TRIAGE, NOT A FINDING

**The loudest guardrail in the plugin. Say this at the top of every output. Do
not drop it. Do not soften it.**

> **This is a triage, not a finding of infringement or non-infringement.**
> Infringement analysis is fact-intensive and legally complex. The triage
> identifies the factors and flags the ones that matter most; it does not
> conclude. A conclusion that something does or does not infringe is a legal
> opinion that requires an attorney's judgment on the facts, the claim or
> right scope, the relevant jurisdiction's law, and the likely defenses.
> Acting on a triage — sending a cease-and-desist, refusing to stop, filing
> suit, or deciding not to — without attorney review is how companies end up
> on the wrong side of fee awards, Rule 11 sanctions, declaratory-judgment
> actions, and (for patents) treble damages.

Under-calling a conflict is a one-way door — a C&D not sent and a mark goes
generic in the market; a claim not chased and the statute of limitations runs;
a copied copyrighted work kept on the site. Over-calling is a two-way door —
the attorney narrows. Stay on the two-way door side.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

Infringement triages often lead into cease-and-desist drafting or takedown
routing. Open a matter if one isn't active and the practice is private — the
triage, the C&D, and any downstream response belong in one workspace.

---

## Load the practice profile first

Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Pull:

- **Role** from `## Who's using this`.
- **Enforcement posture** from `## Enforcement posture` — the triage output
  should end with a routing suggestion consistent with the stated posture
  (aggressive / measured / conservative) and the named approver for the
  relevant letter type.
- **Registered in / enforce where** from `## IP practice profile` — determines
  which circuit / jurisdiction test to apply by default.
- **Integrations** from `## Available integrations` — CourtListener,
  Solve Intelligence each affects whether the triage can cite to case law,
  prior rulings, or prior art.
- **Decision posture** from `## Decision posture on subjective legal calls` —
  this skill never concludes on a subjective threshold.

If the config has `[PLACEHOLDER]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor posture, jurisdictions, and approval chain to your practice.
>
> **Two choices:**
> - Run `/ip-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll run this tailored to YOUR practice.
> - Say **"provisional"** and I'll run this against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run the infringement triage normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no playbook (do the full analysis rather than matching against a position list). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/ip-legal:cold-start-interview` to get output calibrated to YOUR practice — your playbook, your jurisdiction, your risk appetite. 2 minutes."

---

## Mode selection

Ask at the top, before anything else:

> Which right are we triaging?
>
> 1. **Trademark** — confusion, dilution, or false advertising
> 2. **Copyright** — substantial similarity, fair use, DMCA safe harbor
> 3. **Patent** — claim-chart first pass, literal read + doctrine of equivalents
> 4. **Trade secret** — secrecy, reasonable measures, misappropriation
> 5. **Mixed / not sure** — describe the facts and I'll pick

If the user picks "not sure," help them sort. The same facts can implicate
multiple rights (e.g., a competitor's product uses our logo — trademark; and
the product is a near-copy of ours — possible patent, copyright on packaging,
possible trade dress; and a former employee launched it — trade secret).

**If more than one right is in play, run the triage for each, separately.**
Don't mash them together. Each right has different factors, different
jurisdictional rules, and different remedies.

---

## Intake (common to all modes)

> Before I walk factors:
>
> 1. **Posture.** Are you the potentially senior party (they're taking
>    yours) or the potentially accused party (we're the ones being looked at)?
>    The factors are symmetric but the output differs — a "mine's being
>    copied" triage routes toward an assertion letter; a "we might be
>    exposed" triage routes toward a risk memo.
> 2. **Jurisdiction.** Which country / circuit / court? US federal default if
>    not specified. Flag if foreign law may apply.
> 3. **Timing.** Is a statute of limitations or laches clock running?
> 4. **What exhibits / evidence / source documents do you have?** A screenshot,
>    a URL, a packaging photo, a code excerpt, an ex-employee contract.

Wait for the answer before walking factors.

---

## Trademark mode

### Confusion

Use the applicable circuit's multi-factor test. Cite the test (du Pont /
Polaroid / Sleekcraft / other — see the `clearance` skill for the case
citations and pick logic). Walk each factor and flag what cuts each way.

- **Similarity of marks** — sight / sound / meaning / commercial impression.
- **Similarity of goods or services** — expected-source test, not identity.
- **Channels of trade.**
- **Consumer sophistication.**
- **Strength of the senior mark** — fanciful / arbitrary / suggestive /
  descriptive with secondary meaning / generic.
- **Intent** — evidence of copying, knock-off trade dress, near-miss mark.
- **Actual confusion** — any evidence (surveys, misdirected inquiries, social).
- **Likelihood of expansion / bridge-the-gap** — whether the zones overlap
  commercially.

### Dilution

Apply the federal TDRA (15 U.S.C. § 1125(c)) and any applicable state statute.

- **Fame threshold.** The senior mark must be famous to the general consuming
  public — a niche-famous mark is not enough. *Starbucks Corp. v. Wolfe's
  Borough Coffee, Inc.*, 588 F.3d 97 (2d Cir. 2009) is representative.
- **Blurring vs. tarnishment.** Blurring = distinctiveness harm; tarnishment
  = reputation harm.
- **Defenses** — comparative advertising, news reporting, fair use,
  non-commercial use.

If the senior mark is not plainly famous nationally, flag dilution as a
stretch.

### False advertising / comparative claims

If the triage is prompted by a competitor's comparative ad or a claim about
product attributes:

- Apply Lanham Act § 43(a) / 15 U.S.C. § 1125(a) for the materiality,
  falsity-or-misleading, deception, commercial-speech, and injury elements.
- Flag whether the statement is literally false, implicitly false, or
  puffery. Puffery is not actionable.
- Substantiation evidence the claimant has or needs.

### Output

Factors table; what cuts each way; a "not a finding" conclusion line. End with
a routing suggestion against the enforcement posture in the practice profile.

---

## Copyright mode

### Ownership

Is the claimant the owner (or exclusive licensee with standing)? Work-for-hire
issues; joint authorship; assignments; and termination rights all flag.

### Registration

17 U.S.C. § 411 requires registration (or preregistration) as a precondition
to filing an infringement action in US federal court. *Fourth Estate Public
Benefit Corp. v. Wall-Street.com, LLC*, 586 U.S. 296 (2019) — registration
means actually issued, not just applied for. Flag registration status; if
not registered, flag the practical bar on filing.

### Access + substantial similarity

Two paths to proving copying:

- **Access + probative similarity** — defendant had access and the works share
  features probative of copying.
- **Striking similarity** — even absent proof of access, the similarity is so
  striking that independent creation is unlikely.

For substantial similarity, apply the circuit's test (Second Circuit's
ordinary-observer; Ninth Circuit's extrinsic / intrinsic under *Krofft* and
*Swirsky*; Fourth / Seventh / Eleventh circuits' variations). Flag which
test applies.

### Fair use

17 U.S.C. § 107 four factors, analyzed as a whole:

1. Purpose and character of the use (transformativeness; commercial vs.
   non-commercial).
2. Nature of the copyrighted work (factual / functional vs. creative).
3. Amount and substantiality of the portion used.
4. Effect on the market for the original.

Recent touchstones: *Google LLC v. Oracle America, Inc.*, 593 U.S. 1 (2021);
*Andy Warhol Found. for the Visual Arts, Inc. v. Goldsmith*, 598 U.S. 508
(2023). Flag the transformativeness analysis carefully — *Warhol* narrowed
the scope of transformative use and is still being applied by lower courts.

### DMCA safe harbor

17 U.S.C. § 512. If the accused is a service provider hosting user content,
flag whether § 512(c) applies: designated agent, notice-and-takedown
procedure, no actual or red-flag knowledge, no financial benefit
attributable to infringement the provider could control, expeditious
takedown on valid notice. Repeat-infringer policy required. Safe harbor does
not cover direct infringement by the service provider itself.

### Output

Factors flagged; fair-use balance with "the triage does not conclude";
ownership / registration / safe-harbor threshold notes. Routing per posture.

---

## Patent mode

**Route to `/ip-legal:fto-triage` for the detailed framework.** This mode is the
mirror image of the FTO skill — same claim charts, same doctrine-of-equivalents
flag, same all-elements rule — applied to an accused product instead of one's
own.

### Design patent (D-number) — branch before the workflow

**Check the asserted patent's registration number FIRST.** If it has a `D`,
`RE`, or `PP` prefix (e.g., `D712,345`), it's not a utility patent and the
workflow below does NOT apply. Branch per prefix:

- **`D` prefix — design patent (35 U.S.C. §171).** Different test, different
  claim structure, different damages. Do NOT build a claim chart, do NOT run
  doctrine of equivalents, do NOT do element-by-element mapping. Design
  patents have a single claim defined by the drawings; charting a figure as
  if it were a utility claim element list is wrong doctrine.
- **`RE` prefix — reissue patent.** Treat as the utility patent it reissued,
  but flag reissue-specific defenses (intervening rights under §252,
  recapture rule, original-patent requirement).
- **`PP` prefix — plant patent.** Separate regime (35 U.S.C. §161). Asexually
  reproduced plant varieties. Route to plant-patent counsel; this skill does
  not analyze plant patents.

**Design patent infringement test — ordinary observer.** *Egyptian Goddess,
Inc. v. Swisa, Inc.*, 543 F.3d 665 (Fed. Cir. 2008) (en banc). The question
is whether an ordinary observer, **familiar with the prior art designs**,
would be deceived into thinking the accused design is the same as the
patented design. Compare **overall ornamental appearance**, not individual
elements. The accused product must appropriate the **novelty** that
distinguishes the patented design from the prior art (the "point of novelty"
survives as a guidepost inside the ordinary-observer test, not as a separate
test).

**Functional-vs-ornamental filter.** Design patents protect ornamental
features only; functional features are not protected. If the accused
similarity is in features dictated by function, flag that the overlap may
fall outside the patented scope.

**§289 total-profit damages flag.** Design patent damages under 35 U.S.C.
§289 are the infringer's **total profits on the "article of manufacture,"**
which can be the whole product or a component. *Samsung Electronics Co. v.
Apple Inc.*, 580 U.S. 53 (2016). This is a separate analysis from utility
patent reasonable-royalty / lost-profits and is specialist work — do not
compute.

**Trade dress cross-flag.** The same ornamental-shape facts are usually also
a **trade dress** question under Lanham Act §43(a) (15 U.S.C. §1125(a)).
Product configuration trade dress requires **secondary meaning** (*Wal-Mart
Stores, Inc. v. Samara Bros., Inc.*, 529 U.S. 205 (2000)) and must be
**non-functional** (*TrafFix Devices, Inc. v. Marketing Displays, Inc.*,
532 U.S. 23 (2001)). Flag trade dress as a parallel track; the tests are
different but the evidence overlaps.

### Design patent triage — output

Because you cannot see the patent drawings or the accused product directly,
the design patent triage is mostly a request for the materials and a frame
for the analysis:

- **Ask for the drawings.** "I can't run the ordinary-observer test without
  seeing the patent figures and the accused product. Paste or attach: (a)
  the patent drawings (all figures, including any broken-line disclaimers),
  (b) photos of the accused product from comparable angles, (c) any prior
  art designs you're aware of."
- **Prior-art landscape.** Ordinary observer is a *comparison* test — the
  observer is "familiar with the prior art," so the scope of the patented
  design narrows as the prior-art field crowds. Flag what prior art is
  known and what's missing.
- **Functional-vs-ornamental analysis.** Walk the features and flag which
  look functional (and therefore unprotected) vs. ornamental.
- **Broken lines.** Design patents use solid lines for claimed features and
  broken lines for unclaimed environmental context. Flag whether the
  alleged copying is in claimed (solid-line) or unclaimed (broken-line)
  territory.
- **§289 damages flag** as above.
- **Trade dress cross-flag** as above.

**Route to a design patent specialist for anything beyond first-pass triage.**
Design patent litigation is a subspecialty (Perkins Coie, Sterne Kessler,
Desmarais, Kirkland's design team, Gibson Dunn's design group are
representative; use your practice profile's IP litigation OC as the starting
point). This skill flags issues; it does not assess infringement.

### Utility patent workflow

The rest of this mode assumes the asserted patent is a **utility patent**
(no `D`/`RE`/`PP` prefix). If the D-number branch above applies, stop here.

> **Patent systems differ by jurisdiction.** The US claim chart (all-elements rule, doctrine of equivalents, prosecution history estoppel, §284/§289 damages) does not transfer to other systems:
> - **Germany:** Utility models (Gebrauchsmuster), the Schneidmesser/Kunststoffrohrteil questions for DOE, bifurcated validity/infringement proceedings.
> - **China:** Utility models (shiyong xinxing), CNIPA examination, different claim construction.
> - **Japan:** Utility models, JPO examination, a narrower DOE.
> - **Europe (unified patent court):** UPC procedure as of 2023.
>
> When non-US jurisdictions are in scope: "This analysis uses the US claim-charting framework. A product manufactured in China and sold in the EU needs CNIPA and EP analysis, not a US claim chart. I can flag the issues a US analysis surfaces, but the infringement and validity calls require [jurisdiction]-specific review."

### Workflow

- Accused product / process / method — described in technical detail.
- Identified patent(s) at issue.
- Claim chart for each independent claim: element-by-element mapping to the
  accused product.
- Literal infringement first. DOE as a flag.
- Indirect (induced, contributory) and divided infringement as flags.
- **Invalidity defenses to consider** — anticipation (§ 102), obviousness
  (§ 103), § 112 written-description / enablement / definiteness, § 101
  subject-matter eligibility (*Alice* / *Mayo*). Known IPR or PGR outcomes,
  known prior art, known prosecution history. Flag each; do not opine.
- **Unenforceability defenses** — inequitable conduct flag, prosecution
  laches flag, assignor / licensee estoppel flag. Each is attorney-only.
- **Damages posture** — lost profits vs. reasonable royalty (Georgia-Pacific
  factors), marking, pre-suit notice, willfulness (reading this triage may
  factor into willfulness — see the FTO skill's willfulness note).

### Output

Claim charts. Element flags. Defense flags. Routing to patent counsel. See
the `fto-triage` skill for the full output structure — the infringement-triage
patent mode uses the same format with "accused product" substituted for
"own product."

### Handoff to the full claim chart

For a detailed element-by-element claim chart suitable for infringement or
invalidity contentions, run `/litigation-legal:claim-chart`. This triage's
claim chart is a first pass to identify the strongest and weakest mappings;
the litigation claim chart builds the full chart with pin cites, claim
construction flags, dependent claims, and the verification workflow that
contentions require.

---

## Trade secret mode

### Was it a secret?

Apply the Defend Trade Secrets Act (18 U.S.C. § 1836 et seq.) for federal
purposes and the applicable state UTSA (or, in New York / Massachusetts /
other non-UTSA jurisdictions, the state's common-law test). Flag:

- **Not generally known** — to the public or to others in the industry who can
  obtain economic value from disclosure.
- **Economic value from secrecy** — independent economic value actual or
  potential, derived from not being generally known.
- **Combinations and compilations** — a combination of public elements can
  be a trade secret (*Altavion v. Konica Minolta*, and the Restatement view).

### Reasonable measures

- NDAs with employees, contractors, counterparties. Scope, signed, enforced?
- Access controls — technical (role-based), physical (doors, badges),
  organizational (need-to-know).
- Marking — confidentiality legends on documents, code, data.
- Exit interviews / return of materials on termination.
- Trade-secret policy / training.

Flag what's in place and what's missing. *Reasonable* is fact-specific; the
triage does not decide whether the measures were reasonable — it lists them.

### Misappropriation

Acquisition by improper means, or disclosure / use in breach of duty.
Improper means includes theft, bribery, misrepresentation, breach or
inducement of breach of a duty to maintain secrecy, or espionage (electronic
or otherwise). 18 U.S.C. § 1839(6).

- **Former employee fact pattern:** new employer, overlapping work,
  departure timing, documents taken (and returned?), access logs, recruiting
  channels, assignment and invention-assignment agreements.
- **Inadvertent disclosure:** Was disclosure made by a person with a duty? Did
  the recipient know or have reason to know of the breach?
- **Reverse engineering** — a defense if the means were lawful. Flag whether
  reverse engineering is plausible on the facts.

### Preemption

Where state tort claims (unfair competition, conversion, breach of confidence)
might be preempted by the UTSA, flag preemption. Some jurisdictions preserve
contract claims; others preempt most tort claims addressing the same facts.

### Output

Three flag groups — secrecy, measures, misappropriation — each with what cuts
each way. Routing per posture.

---

## Output format (all modes)

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` `## Outputs`.

```markdown
[WORK-PRODUCT HEADER]

# Infringement Triage — [Trademark | Copyright | Patent | Trade Secret] (NOT A FINDING)

**This is a triage, not a finding of infringement or non-infringement.** The
triage identifies factors and flags what matters most; it does not conclude.
A conclusion requires an attorney's judgment on the facts, the right scope,
jurisdiction, and defenses. Acting on a triage without attorney review is
how companies end up on the wrong side of fee awards, Rule 11 sanctions,
declaratory-judgment actions, and enhanced damages.

**Triage result:** [GREEN / YELLOW / RED — one sentence why]

## Posture and scope

- **Party posture:** [senior / accused]
- **Right at issue:** [trademark / copyright / patent / trade secret]
- **Jurisdiction:** [US federal — specific circuit / state / foreign]
- **Legal framework applied:** [cite the governing test and statute]
- **Statute of limitations / laches posture:** [clock status]
- **Exhibits / evidence reviewed:** [list]

## Factor analysis

[Mode-specific factor table — confusion factors / fair-use factors / claim chart
/ trade-secret elements. Each factor has a flag and a direction. This is
a flag list, not a verdict.]

## Defenses and thresholds

[Mode-specific: dilution fame threshold / registration prerequisite /
§ 512 safe harbor / invalidity / inequitable conduct / preemption /
reverse-engineering / consent / license / laches / statute of limitations.
Flag each.]

## What cuts which way — summary

| Factor | Flag | Direction (senior / accused / mixed) |
|---|---|---|
| [factor 1] | [note] | [direction] |

**Conclusion:** *This skill does not conclude.* Attorney judgment required
before acting. The factors cutting [direction] are [brief summary]; the
factors cutting [direction] are [brief summary].

## Recommended next steps

- [formal opinion from counsel / route to IP OC named in the practice profile]
- [evidence preservation and hold — if a litigation clock is running]
- [fact development needed before a decision — e.g., access logs, prosecution
  history, market studies, survey evidence]
- [routing per `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`
  `## Enforcement posture`, if the posture is to assert]

## Citation verification

Every case, statute, registration number, claim quote, and exhibit cited here
must be verified against the authoritative source before relying on it.
Jurisdictional tests vary by circuit and change over time — confirm the
current controlling authority.
```

---

## Non-lawyer gate

Before issuing the output, read `## Who's using this`. If the Role is Non-lawyer:

> This output is a research triage, not legal advice. Sending a C&D, deciding
> not to stop, filing suit, or relying on "it's fair use" based on this triage
> alone has legal consequences — including Rule 11 sanctions for a baseless
> assertion, declaratory-judgment exposure for a threatening letter, treble
> damages on the patent side, and fee awards in unfair-competition cases.
> An attorney needs to evaluate before you move.
>
> Here's a brief to bring to an attorney:
>
> [Generate a 1-page summary: the right at issue, the posture, the facts and
> evidence, the factors surfaced, the defenses flagged, and the three
> questions to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is
> the starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). For patents in the US, the attorney must be registered before the
> USPTO; for other jurisdictions, use the relevant patent office register. For trademarks, INTA maintains a directory of practitioners worldwide.

Deliver the triage alongside the brief.

---

## Output location

If matter workspaces are enabled and a matter is active, write to
`~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/outputs/infringe-<mode>-<subject-slug>-YYYY-MM-DD.md`.
Otherwise write to
`~/.claude/plugins/config/claude-for-legal/ip-legal/outputs/infringe-<mode>-<subject-slug>-YYYY-MM-DD.md`
and surface the path.

Append a one-line entry to the matter's `history.md` if a matter is active.

---

## Handoff to enforcement skills

If the triage output points toward an assertion and the practice profile's
posture supports it, offer:

> Want me to draft a cease-and-desist on this? Run `/ip-legal:cease-desist`.
> I'll use the flag list from this triage as the factual basis and apply the
> approval chain from your practice profile — the letter won't go anywhere
> without the approver signing off.

Or, if the mode is copyright and the accused is hosted content:

> Want me to prepare a DMCA takedown? Run `/ip-legal:takedown`.

Do not draft the letter automatically from the triage. The decision to assert
is the approver's, not the triage's.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Conclude infringement or non-infringement.** Ever. The loudest guardrail.
- **Substitute for survey evidence, damages experts, or claim construction.**
- **Evaluate jurisdiction-specific defenses outside the triage's jurisdiction
  scope.** If the facts cross borders, flag that foreign-law analysis is
  required.
- **Decide fair use as a matter of law.** Fair use is fact-intensive and
  reserved for the attorney and, ultimately, the court.
- **Draft the C&D, takedown, or complaint.** Those are separate skills
  (`/ip-legal:cease-desist`, `/ip-legal:takedown`) gated by the approval
  chain in the practice profile.
- **Quote outputs to counterparties.** Privileged if the header applies.

---

## Tone

Factor-by-factor, flag-by-flag. No hedging prose. The guardrail at the top
does the scope work; the analysis does the analysis. A lawyer should leave
the output knowing exactly which factors are flagged, which defenses apply,
and what they need to do next to either assert or stand down.$body$)
ON CONFLICT (skill_key) DO NOTHING;
