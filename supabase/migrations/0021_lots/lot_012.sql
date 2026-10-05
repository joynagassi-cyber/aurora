INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/demand-draft', 'legal', 'demand-draft', '', 'demand-draft', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /demand-draft

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/intake.md`. Refuse if missing or strategic block empty (for material demands).
2. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → demand-letter practice, house style, seed-doc table.
3. Follow the workflow and reference below.
4. Run the pre-draft gate: privilege filter, admission risk, accord-and-satisfaction, FRE 408 posture, waiver scan, tone, factual accuracy. Do not proceed until each is engaged.
5. Template select: seed doc if provided in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`; else soft template for the demand type.
6. Draft in-chat for review. Iterate until user approves.
7. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/draft-v[N].docx` using the docx skill.
8. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/checklist.md` (post-send checklist).
9. Assess materiality per heuristic; offer to create a matter. If yes: hand off to `matter-intake` with pre-populated fields.

---

# Demand Draft

## Purpose

Take a completed intake and produce a sendable draft. Most of the value is in refusing to draft until privilege, waiver, admission, and settlement-communication posture have been consciously addressed — the failure mode is a letter that waives privilege or constitutes an admission because no one paused to check.

## Record fidelity — quotes and pinpoints

Demand letters are advocacy, and every quoted line from a contract, an email, or a prior communication becomes an assertion the counterparty will test. Canonical statement in the plugin's `CLAUDE.md` shared guardrails; repeated here.

**Verbatim quotes must be verbatim.** Never put quotation marks around words attributed to the counterparty, their counsel, a witness, or any document unless you have the exact passage in front of you. When you want to characterize without the exact words:

- **Paraphrase without quotation marks**, with a placeholder: "Your [date] email stated X `[verify exact quote — email cite pending]`."
- **Never fill the gap.** A misquoted contract provision in a demand letter is the fastest way to lose credibility with opposing counsel on the first round.
- Every `[verify exact quote]` must be flagged in the reviewer note before the letter leaves.

**Pinpoint cites must support the whole proposition.** If the demand asserts "Section 4.2 requires payment within 30 days upon invoice receipt," the cited section must cover the obligation AND the trigger AND the window. If it only covers one, split the cite (e.g., "Section 4.2 (payment obligation); Section 4.3 (30-day window)") or narrow the proposition. A contract cite that backs part of the demand is how the counterparty replies with the full text and flips the posture.

## Candor about weak arguments

When the law or the record is against a point, don't dress it up as solid. When an argument in the demand is weak — the contract language is ambiguous, the authority cuts the other way, the damages theory is a stretch — flag it for the sender:

> "The [claim / theory] here is weak because [authority / fact]. Options: (a) press it and frame as `[alternative framing]`, (b) drop it and rely on [stronger claim], (c) keep it as a hook but hedge the language. `[review — strategic call]`."

A demand letter that over-asserts gets a response that catalogs every overreach, shifts leverage, and burns the next round. The strongest demand letter is the one that concedes what's weak so the counterparty can't.

## Echo vs repeat

If the matter has prior correspondence, echo the key terms — the same characterization of the breach, the same framing of the core obligation, the same name for the transaction. Don't lift whole sentences. A demand letter that reads like a copy-paste of the prior one signals that nothing has changed; the new letter should advance the posture (new facts, new deadline, new consequence), not restate it.

> **External deliverable:** the drafted demand letter is sent to counterparty. Do NOT include a `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT — PREPARED AT THE DIRECTION OF COUNSEL` header on the outgoing letter. The post-send checklist and the intake file are internal work product and do carry the header.

## Side context

Drafting a demand letter is inherently an assertion — the sender is making a claim. Read `## Side` in the practice profile:

- **Plaintiff / claimant** (default for this skill): demand-draft aligns with the posture. The letter is the claim. Tone, consequence language, and relief demanded all flow from the plaintiff-side playbook.
- **Defense / respondent**: demand-drafts are less common from defense but do happen — a defense practitioner may send a counter-demand, a demand for contribution, or a demand letter in an unrelated matter. Confirm before drafting: "You said defense is your default. Is this matter plaintiff-posture for you (you're asserting a claim), or is this a different posture?"
- **Both / varies**: ask per-draft which posture applies. The draft's tone and default signer may differ.

For in-house defense practitioners who receive demand letters more than they send them, route to `demand-received` instead — that skill handles the inbound-triage case.

## Posture for this matter

Before the pre-draft gate, confirm the matter-level posture. Demand-letter tone and terms are case-by-case, not a practice default. Confirm with the user (reading the intake's `## Posture` section if present; asking if not):

> **Posture for this matter.** Demand-letter tone and terms are case-by-case, not a practice default. Ask:
> - **Tone:** measured / assertive / aggressive? (depends on the relationship, the amount, and whether litigation is likely)
> - **Response window:** what's reasonable given the claim? (14 days is common for payment demands; 30 days for cure; 7 days for cease-and-desist — but the contract or protocol may set it)
> - **Marking:** does this need a "without prejudice" or "without prejudice save as to costs" marking? (settlement communications do; assertions of claim often don't; jurisdiction matters — ask if unsure)
> - **Signer:** you, the client, the GC, instructed solicitor/counsel?
> Don't assume. Read the prior demand correspondence in the matter file if there is any — it establishes the register.

The answers drive tone verb choice, the consequence language, the `Without prejudice` header (or its absence), the signature block, and the compliance deadline. A posture that wasn't captured in intake gets captured here — do not fall back to a practice-level default.

## Jurisdiction assumption

This draft assumes the jurisdiction identified in the intake and the forum's applicable settlement-communication rule (FRE 408 in federal, the state equivalent otherwise). Legal rules, deadlines, fee-shifting, and statutory hooks vary materially by jurisdiction. If the underlying facts touch a different forum, a different counterparty's home state, or a choice-of-law question, the draft may not apply as written — confirm before sending.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/intake.md` — required; refuse to proceed if missing
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → Demand-letter practice (seed-doc paths, insurance-tender timing, materiality threshold for matter creation), house style (privilege markings, outside counsel directive format for tone reference). **Tone, compliance period, marking, and signer come from `## Posture for this matter` — they are matter-level, not practice-level.**
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — to check for existing related matters (same counterparty) and offer cross-link

### Strategic-block skipped handling

If the intake has `strategic_block: skipped` or `partial`, prompt the user before running the pre-draft gate:

> The intake skipped [all / some] of the strategic block (leverage, BATNA, tone, privilege filters). Drafting now will produce a usable letter but the strategic sections will be generic and flagged with `[SME VERIFY]`.
>
> - **Complete strategic block now** — pause, return to `/demand-intake [slug] --resume-strategic`
> - **Proceed anyway** — continue to pre-draft gate; downstream sections flagged

If "proceed anyway," every section of the draft that depends on a skipped strategic question gets `[SME VERIFY: [specific question]]` inline.

## Flags

- `--skip-gate` → bypass the pre-draft checklist. Available but logged; use only when the checklist was run separately and documented.
- `--version=N` → draft as `draft-vN.docx` (default: next version number)

## The pre-draft gate

**This runs before any drafting. If the user doesn't engage with it, stop.**

```
PRE-DRAFT CHECKLIST — [slug]

1. Privilege filter
   Per intake privilege filters: [list]
   Confirm: none of these will appear in the draft?  [y/n]

2. Admission risk
   Per intake admission risk: [list]
   For each, is the phrasing controlled or removed?  [y/n per item]

3. Accord-and-satisfaction
   Per intake: [flagged risk, if any]
   Does the demand inadvertently satisfy or accept a separate claim?  [y/n]

4. Settlement-communication posture
   Research the settlement-communication protections applicable in the forum
   (FRE 408 in federal, the state equivalent otherwise). Note that protection
   attaches from conduct and context, not merely from labeling the communication.
   Intake says: [protected / not protected / case-by-case]
   Draft will [include / omit] settlement-communication markers, and will be
   structured so the substance — not just the label — supports the posture.
   Confirm.

5. Privilege waiver scan
   Will any sentence in the draft reveal the substance of our internal legal analysis (not just the conclusion)?  [y/n]
   If yes, rephrase before drafting.

6. Tone posture
   Intake says: [relationship-preserving / measured / scorched-earth]
   This will drive verb choice, framing, and consequence language. Confirm.

7. Factual accuracy
   Every fact in the draft must be verified. Not "probably true" — verified. List any facts that are not yet verified, and they will be flagged [VERIFY: ___] inline.
```

Only proceed when the user has engaged with each item. A blank-acknowledged checklist is worse than no checklist.

## Template selection

### Step 1: Seed doc

Check `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → Demand-letter practice → seed-doc table for the intake's demand type.

- **Seed doc provided:** read it. Match structure, tone, signature block, privilege markings, typical section ordering. The seed doc is the template.
- **No seed doc:** use the soft template below for the demand type.

### Step 2: Soft templates (used only when no seed doc)

Each is a skeleton — headings and expected content. Deviate when the facts require.

**Payment demand skeleton:**
1. Parties and relationship context (1 paragraph)
2. Facts — the obligation and its source (contract § / invoice / order), dates
3. The default — what's owed, when due, what happened (or didn't)
4. Demand — specific amount, deadline, method of payment
5. Consequences — referral to counsel, interest, fees, collections, litigation
6. Preservation notice (if relevant)
7. Signature block

**Breach / cure notice skeleton:**
1. Parties and agreement (identify the contract — effective date, parties)
2. The obligation alleged breached — contract section, plain language
3. The breach — specific facts, dates, evidence available
4. Cure — what specifically would cure; cure period (from contract or reasonable)
5. Consequences of failure to cure — termination, damages, specific remedies in the contract
6. Preservation of rights
7. Signature block

**Cease & desist skeleton:**
1. Parties and our rights (trademark/copyright/contract/common law — identify the right)
2. The infringement / violation — specific acts, dates, evidence
3. Demand — cease immediately, remove, account for past use, confirm compliance in writing
4. Compliance deadline
5. Consequences of non-compliance — litigation, injunctive relief, statutory damages if applicable, fees
6. Preservation demand (documents, metadata, systems related to the alleged conduct)
7. Signature block

**Employment separation demand skeleton:**
1. Parties and relationship context (ex-employee, dates of employment)
2. The obligation — post-employment obligations breached (confidentiality, non-solicit, non-compete, IP assignment); cite the agreement
3. The specific conduct alleged
4. Demand — cease, return property/IP, confirm compliance, non-disparagement reinforcement if applicable
5. Consequences — litigation, injunctive relief, fee-shifting if in the agreement
6. Offer of informal resolution (if strategically appropriate)
7. Preservation demand
8. Signature block

**Preservation demand skeleton:**
1. Parties and context — what dispute is anticipated
2. Scope — categories of documents, data, systems, communications
3. Custodians — named individuals expected to have relevant material
4. Date range
5. Affirmative preservation obligation — suspend auto-delete, preserve metadata, preserve devices
6. Consequences of spoliation — adverse inference, sanctions, fee-shifting
7. Acknowledgment request
8. Signature block

## Drafting rules

0. **Installment-contract default for multi-lot goods disputes.** For any breach-of-contract demand involving a multi-delivery goods contract under the U.C.C. (multiple shipments, lots, or deliveries over time), default to the installment-contract framework of **U.C.C. § 2-612** — "substantial impairment of the value of the installment" — rather than § 2-601's perfect-tender rule or § 2-711's single-delivery buyer's-remedies framework.

Perfect tender under § 2-601 applies cleanly to single-delivery goods contracts. It does NOT transfer cleanly to installment contracts, where § 2-612 modifies the rule: a buyer can reject a nonconforming installment only when the nonconformity substantially impairs the value of that installment and cannot be cured; and can treat the whole contract as breached only when the nonconformity substantially impairs the value of the whole contract.

When drafting the demand letter for a multi-lot goods breach:

- Cite `[CITE: U.C.C. § 2-612 — installment contracts; substantial impairment of the installment]` as the primary framework, not § 2-601.
- Cite § 2-711 and § 2-712 (cover) as remedies flowing from breach, but state the breach standard in § 2-612 terms.
- Flag for the signer in a `[SIGNER NOTE:]` block above the draft: "This letter is drafted under U.C.C. § 2-612 (installment contracts), not § 2-601 (perfect tender). The two have materially different breach standards. Confirm the contract's delivery structure supports installment-contract characterization before sending."
- If the contract's delivery structure is unclear from the intake (e.g., the intake says "three lots delivered" but doesn't confirm whether the contract called for separate lot deliveries or a single shipment split for convenience), flag it `[VERIFY: is this an installment contract under § 2-612, or a single-delivery contract split into lots by shipping convenience?]` — do not silently assert § 2-612 applies.

Single-delivery breach: use § 2-601 perfect-tender framing. Installment: use § 2-612. Do not conflate them.

1. **Specificity over adjectives.** "On March 14, 2026, you sent X" beats "You repeatedly and improperly sent X." Adjectives are the draftsperson's tell that the facts are thin.

2. **Facts traceable to sources.** Every factual assertion maps to a document, date, or witness. If not verifiable yet: `[VERIFY: specific claim]`.

3. **Citations as placeholders.** `[CITE: statute/section/case]` wherever legal authority goes. Do not invent citations. If the user provided authorities in the intake, use them faithfully.

4. **Consequence language matches tone posture.**
   - `relationship-preserving`: "We hope to resolve this without further action."
   - `measured`: "If not cured within [N] days, we will consider our options, including litigation."
   - `scorched-earth`: "Failure to cure within [N] days will result in immediate legal action, including [specific relief]."

5. **Inline alternative phrasings.** Where tone could shift, the draft includes a compact alternative. Format:
   > *The attached invoice of $X remains unpaid.* [or more assertive: *You have failed to pay the attached invoice of $X, due [date].*]

6. **No settlement discussion on the record unless intended.** If the intake flagged the communication as not carrying settlement-communication protection in the forum, the draft does not include any offer to compromise, any "without prejudice" framing, or any language that could be characterized as a settlement communication. Remember that protection attaches from conduct and context; labeling alone is not a cure.

7. **Privilege markings per house style.** Apply `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` privilege conventions exactly.

## Output

### Primary: `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/draft-v[N].docx`

Use the `docx` skill to produce a letter-formatted .docx:
- Letterhead / sender address block
- Date
- Recipient address block
- Re: line (concise; does not reveal privileged strategy)
- Salutation
- Body (per template + drafting rules)
- Closing
- Signature block per intake

### In-chat review

Show the draft as readable plain text for the user to review and request edits. Iterate before writing the final .docx. Once approved, write to disk.

### Send gate (closing note on the draft)

Append the following, set apart from the body, to the in-chat presentation and to any internal preview — it is a reviewer-facing note, not letter text, and is stripped before the letter goes out:

> This is a draft demand letter for attorney review, not a letter ready to send. Sending it may constitute an attorney communication, create FRE 408 (or state-equivalent) implications, and start the clock on disputes, counterclaims, and statutes. A licensed attorney reviews, edits, and takes professional responsibility before sending. Do not send this draft unreviewed.

### Citation verification

Every `[CITE:___]` placeholder — and any citation pulled from the intake or the seed doc — is unverified until a human runs it through a citator. Before sending, run a verification pass: check each case, statute, and regulation against a legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or your firm's platform) for accuracy, good law status, and subsequent history. Fabricated or misquoted citations in sent demand letters and filed documents have resulted in sanctions.

**Source attribution.** Tag every citation in the draft with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the specific MCP tool name for citations retrieved via a legal research connector; `[web search — verify]` for citations surfaced by web search; `[model knowledge — verify]` for citations the model recalled from training data; `[user provided]` for citations supplied in the intake or seed doc. Citations tagged `verify` carry higher fabrication risk than tool-retrieved citations and should be checked first. Never strip or collapse the tags — they are the signer's fastest signal about which citations to verify before the letter goes out.

**No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for an authority the draft needs, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [issue]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave the `[CITE:___]` placeholder and stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

### `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/checklist.md` — the post-send checklist

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`. This header applies to the internal checklist file; the outgoing letter does NOT carry it.]

# Post-Send Checklist — [slug]

**Draft version sent:** [v1 / v2 / etc.]
**Sent date:** [YYYY-MM-DD — filled in after send]
**Signer:** [name]

## Pre-send (before the letter goes out)

- [ ] Final read-through by signer
- [ ] Factual accuracy: all [VERIFY] flags resolved
- [ ] Citations: all [CITE] placeholders filled and run through a citator (verify it is good law)d (if live law cited)
- [ ] Privilege markings applied per house style — note: this is an external deliverable; do not include the `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT` header in the version sent to counterparty
- [ ] Settlement-communication markers [present / absent] as intake specified, and substance aligns with posture
- [ ] Internal copies cleared (per intake distribution list)
- [ ] Insurance tender sent (if required per house practice)
- [ ] Conflicts confirmed (if not yet cleared)

**Before the letter is sent (the consequential act):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Sending this demand letter has legal consequences — it creates a record, can trigger statutes and counterclaims, and may waive privileges or constitute admissions. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty and dispute, the demand and deadline, tone posture, FRE 408 / settlement-communication status, privilege and admission risks flagged in the pre-draft gate, what could go wrong, what to ask the attorney before sending.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not mark as sent — do not execute the Send mechanics below — without an explicit yes.

## Send mechanics

- [ ] Delivery method executed: [certified / email / both]
- [ ] Proof of delivery retained (certified receipt, email read-receipt, courier confirmation)
- [ ] Copies sent per distribution list

## After send

- [ ] Compliance deadline calendared: [YYYY-MM-DD]
- [ ] Escalation plan if no response: [next step + date]
- [ ] Follow-up check-in calendared: [date — typically deadline + 2 business days]
- [ ] Matter created in `_log.yaml`: [yes / no — see materiality below]

## Materiality call

**Heuristic says:** [material / immaterial]
**Reason:** [demand type / exposure / counterparty type]
**Your call:** [material → create matter] [immaterial → demand-letters record only]

If material: `/litigation-legal:matter-intake` with `source: demand-letter` pre-populated from this intake.
```

### Matter auto-creation offer

After drafting and writing the checklist, assess materiality per heuristic:

- **Default yes if ANY of:**
  - Demand type is `cease-desist`, `breach-cure`, `employment-separation`, or `preservation`
  - Desired outcome $$ ≥ `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` medium-severity band
  - Counterparty is a customer, competitor, or frequent adversary per landscape
- **Default no otherwise**

Present the call:
> Materiality heuristic: [result]. [One-sentence reason.]
> Create a tracked matter in `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`? (default: [yes/no])

If user accepts: trigger `matter-intake` with fields pre-populated from the intake (counterparty, type, jurisdiction, `source: demand-letter`, initial theory, internal stakeholders). User reviews pre-filled fields and confirms.

If user declines: update intake `status: drafted` (later `sent` when user confirms). The record stays in `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/` only.

## Versioning

Never overwrite a draft that has been sent. If revising after send, `draft-v2.docx`. The sent-version history is itself the record of what the counterparty received.

## What this skill does not do

- **Send the letter.** Drafting only. The user sends.
- **Research citations.** `[CITE:___]` placeholders stay as placeholders. If the user provided authorities in the intake, they're used; otherwise, blanks. Inventing cites is malpractice exposure.
- **Bypass the pre-draft gate.** Even with `--skip-gate`, the skill notes in the draft file that the gate was skipped and why.
- **Rewrite the intake.** If the intake is thin, send the user back to `demand-intake`. The draft is only as good as what it reads from.
- **Decide materiality.** The heuristic offers a default; the user's call is the record.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/demand-intake', 'legal', 'demand-intake', '', 'demand-intake', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /demand-intake

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → demand-letter practice, landscape, risk calibration.
2. Follow the workflow and reference below.
3. Run the adaptive intake (core 8 always; strategic block if material or `--full`).
4. Generate slug from title + counterparty + year-month.
5. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/intake.md`.
6. Confirm with user: "Intake saved. Run `/litigation-legal:demand-draft [slug]` when ready."

---

# Demand Intake

## Purpose

The drafting is downstream. The value is in the pre-writing — forcing the questions a careless letter skips. Leverage, BATNA, downside tolerance, privilege filters, the actual audience. A demand letter sent without thinking about those is worse than no letter.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → Demand-letter practice (insurance-tender timing, materiality threshold for matter creation, any seed-doc templates), landscape (counterparty type, repeat-adversary patterns), risk calibration (to pre-estimate materiality), house style. **Tone, compliance period, marking, signer are NOT practice-level defaults — they are set per matter in the `## Posture for this matter` step below.**

## Flags

- `--full` → run the complete intake regardless of materiality heuristics (for counsel who wants thorough every time)

## The intake

### Posture for this matter (ask FIRST, before the core)

> **Posture for this matter.** Demand-letter tone and terms are case-by-case, not a practice default. Ask:
> - **Tone:** measured / assertive / aggressive? (depends on the relationship, the amount, and whether litigation is likely)
> - **Response window:** what's reasonable given the claim? (14 days is common for payment demands; 30 days for cure; 7 days for cease-and-desist — but the contract or protocol may set it)
> - **Marking:** does this need a "without prejudice" or "without prejudice save as to costs" marking? (settlement communications do; assertions of claim often don't; jurisdiction matters — ask if unsure)
> - **Signer:** you, the client, the GC, instructed solicitor/counsel?
> Don't assume. Read the prior demand correspondence in the matter file if there is any — it establishes the register.

Record the answers in the intake under a `## Posture` section before `## Parties`. These answers govern the rest of the intake and the downstream draft — do not fall back to a practice-level default if the user left any of them blank; ask again.

### Core — always asked (8 questions)

**1. Demand type**
`payment | breach-cure | cease-desist | employment-separation | preservation | other`

**2. Parties**
- **Sender:** our company (and any specific entity if multi-entity)
- **Recipient:** counterparty — name, entity, address
- **Recipient audience:** who actually reads (GC? CEO? individual? in-house legal?)
- **Relationship:** `customer | vendor | ex-employee | competitor | third-party | other`

**3. Triggering event**
- What happened and when (dates matter — statute-of-limitations, notice periods)
- Evidence available (contracts, emails, records, witnesses)

*Seed doc opportunity: "If you can share the underlying contract, correspondence, or evidence, the draft will be materially sharper. Paths work."*

**4. Legal / contractual basis**
- Which provisions — specific contract sections if applicable
- Governing law (jurisdiction, choice-of-law clause)
- Statutes or rules relied on (placeholders OK — the draft will flag `[CITE:___]` anyway)

**5. Desired outcome**
- Specific asks. Not "resolution" — payment of $X by date Y; cessation of specific activity Z; cure within N days; return of specific property.
- If multiple asks, order them (primary vs. fallback)

**6. Deadlines**
- External deadline driving this (SoL, ongoing harm window, business event)
- Demand compliance deadline — how long we give the recipient. Use the response window captured in `## Posture for this matter` above; do not fall back to a practice-level default.

**7. Prior outreach**
- Has this been raised informally? When, by whom, in what form?
- Any response so far?
- Why is escalation to a demand letter happening now?

**8. Distribution**
- Delivery method (ask; no practice-level default)
- Signer — captured in `## Posture for this matter` above
- Copies — internal stakeholders, insurance carrier (if tendering pre-demand per practice-level tender-timing rule), counsel

### Strategic — asked if material, or if `--full`

Materiality heuristic: ask the strategic block if any of the following are true.

- Demand type is `cease-desist`, `breach-cure`, `employment-separation`, or `preservation`
- Desired outcome dollar value ≥ the medium-severity band from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` risk calibration
- Counterparty is a customer, competitor, or frequent adversary per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` landscape
- User ran with `--full`

**Explicit skip option.** When the strategic block is triggered, the user can decline to answer it. Ask plainly:

> This is a material demand by the heuristic. The strategic block (leverage, BATNA, tone, privilege filters) is where most of the pre-writing value lives. Skipping it produces a thinner draft.
> - **Answer now** — walk the strategic block (5-7 min)
> - **Answer partial** — walk the subset you feel prepared for
> - **Skip** — proceed to draft with only the core block; I'll flag `strategic_block: skipped` in the intake

If the user chooses Skip, the intake file records it:

```yaml
strategic_block: skipped        # answered | partial | skipped
skipped_reason: string | null   # captured if user provided one
```

The draft skill honors the skip — pre-draft gate runs regardless, but sections that depend on strategic-block answers get `[SME VERIFY: leverage/tone/privilege not captured in intake]` markers. The `/demand-draft` command also prompts a second time, asking whether the user wants to complete the strategic block before drafting.

**9. Leverage and BATNA**
- What gives us negotiating power (contractual rights, factual leverage, reputational, commercial)
- What if they refuse — are we prepared to litigate? Go public? Accept a smaller outcome?
- Their likely BATNA — what's their best alternative? (If they don't think we'll sue, the demand is weak.)

**10. Downside tolerance**
- Reputational exposure if this becomes public
- Precedent risk — does this letter set a pattern that affects other matters?
- Regulatory / disclosure implications (is this the kind of dispute that becomes a 10-Q item?)
- Insurance implications — does sending without tendering waive coverage?

**11. Tone posture**
- Already captured in `## Posture for this matter` above. Here, probe the trade-off if the user chose a stronger tone than the facts seem to warrant, or a weaker tone than the facts seem to warrant.
- Worth naming explicitly: aggressive tone burns the relationship. If you want to keep the business relationship but need to protect the legal position, `measured` is usually the right call.

**12. Settlement-communication posture**
- Research the settlement-communication protections applicable in the forum (FRE 408 in federal, the state equivalent otherwise). Is this letter a settlement communication that should be protected? Or an assertion of rights that shouldn't be?
- If protected: the draft will include the settlement-communication marker and will be structured so the substance (a discussion of compromise) — not just the label — supports the posture.
- Protection attaches from conduct and context, not merely from labeling. The marker is a belt-and-suspenders choice.

**13. Privilege filters**
- What's in our internal analysis that must NOT appear in the letter? (Facts we haven't verified, our doubts about our case, strategic reasoning, prior settlement discussions)
- A single badly-worded sentence can waive privilege on related analysis. Be explicit about what stays out.

**14. Admission and accord-and-satisfaction risk**
- Anything in the letter that the counterparty could later characterize as an admission of fact or liability?
- Does this demand risk inadvertently satisfying (or purporting to accept) a separate claim? (Accord-and-satisfaction: cashing a check marked "payment in full" can end a disputed debt.)

## Writing the intake

### Slug

`[type]-[counterparty-short]-[yyyy-mm]`. Confirm uniqueness in `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/`.

### `~/.claude/plugins/config/claude-for-legal/litigation-legal/demand-letters/[slug]/intake.md`

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Demand Intake: [title]

**Slug:** [slug]
**Demand type:** [type]
**Drafted by:** [counsel]
**Opened:** [YYYY-MM-DD]
**Status:** intake | ready-to-draft | drafted | sent | closed
**Strategic block:** answered | partial | skipped
**Skipped reason:** [if applicable]

---

## Posture

- **Tone:** [measured / assertive / aggressive — with one-line rationale tied to the relationship and the amount]
- **Response window:** [N days — tied to the claim / contract / protocol]
- **Marking:** [none / without prejudice / without prejudice save as to costs / other — with rationale]
- **Signer:** [name / role — you / client / GC / instructed counsel]

*This is the per-matter posture captured at intake. The draft skill reads from here.*

---

## Parties

- **Sender:** [our entity]
- **Recipient:** [counterparty, entity, address]
- **Recipient audience:** [who reads]
- **Relationship:** [type]

## Triggering event

[What happened, when, evidence]

## Legal / contractual basis

[Provisions, governing law, statutes]

## Desired outcome

[Specific asks in priority order]

## Deadlines

- **External:** [SoL, ongoing harm window]
- **Compliance:** [how long we give them]

## Prior outreach

[History, most recent first]

## Distribution

- **Delivery:** [method]
- **Signer:** [name/role]
- **Copies:** [list]

---

## Strategic (if applicable)

### Leverage & BATNA

[Our power, their likely response]

### Downside tolerance

[Reputational, precedent, regulatory, insurance]

### Tone posture

[relationship-preserving / measured / scorched-earth — with rationale]

### Settlement-communication posture

[Protected or not in the forum — with reasoning. Cite primary source per the applicable rule (FRE 408 or state equivalent).]

### Privilege filters

[What CANNOT appear in the draft]

### Admission / accord-and-satisfaction risk

[Specific risks flagged]

---

## Seed documents

| Doc | Path |
|---|---|
| [underlying contract] | [path or "not shared"] |
| [prior correspondence] | [path or "not shared"] |
| [evidence] | [path or "not shared"] |

---

## Materiality assessment

**Auto-heuristic says:** [material / immaterial — with reasoning]
**User call:** [material / immaterial / TBD at post-send]
```

## Confirm before writing

Show the user the draft intake. Flag anything thin:

> Here's the intake. I notice [thin spots]. Before I save, anything to add?

## Handoff to drafting

End with:
> Intake saved. When ready: `/litigation-legal:demand-draft [slug]`

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- Draft the letter. That's `demand-draft` — the two steps are intentionally separate so counsel can pause for business input, outside counsel consult, or insurance tender before drafting.
- Decide whether to send the letter. Some intake sessions end with "actually, don't send — let's negotiate directly." That's a valid outcome; the intake record still has value.
- Run the conflicts check. If the counterparty is a customer or known entity, flag that this should clear conflicts (per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`) before sending — but the check itself lives in the matter-intake workflow or outside this skill.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/demand-received', 'legal', 'demand-received', '', 'demand-received', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /demand-received

1. Read the incoming document from provided path.
2. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for portfolio cross-check.
3. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → risk calibration, landscape, demand-letter practice.
4. Follow the workflow and reference below.
5. Extract fields; cross-check portfolio; assess merit; present options with recommendation.
6. Write `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/triage.md`. Copy or link incoming to `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/incoming.[ext]`.
7. Hand off per user choice:
   - Create matter → `matter-intake` pre-populated
   - Respond with counter-demand → `demand-intake` pre-populated
   - Link to existing matter → update `related_matters` in log
   - Standalone → no further action

---

# Demand Received

## Purpose

Inbound demand letters are the bread and butter of an in-house litigation practice. A small fraction need escalation; most can be handled with a structured response or a holding letter. The failure mode is treating them all alike. This skill triages, cross-checks the portfolio, and produces options.

## Load context

- The incoming document (user provides path or drops it in-session)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — scan for related matters (same counterparty, overlapping counterparties via entity relationships, or matter type + recent date)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → risk calibration (for merit assessment), landscape (is the sender a frequent adversary?), demand-letter practice (house tone and response defaults)

## Workflow

### Step 1: Read the demand

Extract from the incoming:

- **Sender** — entity, signer, counsel (if signed by outside firm)
- **Recipient** — which entity/person at our company
- **Delivery** — certified, email, courier (matters for deadline calculation)
- **Date received** vs. **date signed**
- **Demand type** — payment, breach/cure, C&D, preservation, settlement, other
- **Specific asks** — what they want, by when
- **Facts alleged** — their version of what happened
- **Legal basis** — statutes, contract provisions, theories they cite
- **Threats** — what they say they'll do if we don't comply
- **Settlement-communication framing** — research the settlement-communication protections applicable in the forum (FRE 408 in federal, the state equivalent otherwise). Note whether the demand is marked as a settlement communication, but remember: protection attaches from conduct and context, not merely from labeling. Capture both the label (if any) and a first-pass read of whether the substance is in fact a compromise discussion.

### Step 2: Portfolio cross-check

Search `_log.yaml` for:

- **Direct match** — matter with same counterparty (their slug matches the sender)
- **Type match** — similar matter type with this counterparty in the past (closed matters count — they inform pattern)
- **Subject overlap** — matters where the subject might be the same dispute (e.g., same contract, same product, same project)

Present findings:

- If **direct match + active:** flag as almost certainly the same matter; recommend adding incoming to the existing matter, not opening a new one. Update `related_matters` if it's a tangent.
- If **direct match + closed:** flag — counterparty is back. May be a new dispute (open new matter) or a resurrected one (reopen or amend). User decides.
- If **type match:** note as precedent/context; probably distinct matter but inform the response strategy.
- If **no match:** novel. Treat as fresh.

### Step 3: Merit assessment

Not a legal opinion — a structured read:

- **Facts** — do the alleged facts align with what we know? Where's the disconnect?
- **Legal basis** — are the cited provisions/statutes actually applicable? (Flag cites for user verification — do not attempt to validate law autonomously.)
- **Strength on their side** — if they went to court tomorrow, what's their story?
- **Strength on our side** — what are our likely defenses?
- **Damages demanded vs. likely** — is the ask proportionate to what a court would award if they won?
- **Leverage and pressure** — are they credibly prepared to sue? Do they have capacity? Are they a repeat-litigant adversary per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`?

Output a triage rating: **substantial merit / debatable / weak / frivolous**. Be blunt. The user is triaging, not writing the brief.

### Step 4: Response options

Present 3-4 options with tradeoffs:

**Option A — substantive response**
- When: their demand has merit or is at least debatable; a reasoned reply protects the record
- Tradeoff: commits us to a position in writing
- Next step: `/demand-intake` with pre-populated fields for a counter-response letter

**Option B — holding letter**
- When: need time to investigate; don't want to concede anything or trigger their deadline math
- Tradeoff: doesn't resolve anything; buys 2-4 weeks
- Next step: short acknowledgment draft

**Option C — settlement response**
- When: early resolution is cheaper than litigation; willing to discuss without admitting
- Tradeoff: settlement-communication posture required — research the applicable rule (FRE 408 or state equivalent) and structure the response so the substance, not just the label, qualifies as a compromise discussion. Must be careful not to waive claims.
- Next step: `/demand-intake` with `type: settlement-response`

**Option D — ignore + preserve**
- When: demand is frivolous or the deadline doesn't create legal prejudice
- Tradeoff: silence can be used against us in some contexts (e.g., account stated); legal hold still required
- Next step: issue legal hold via `/legal-hold --issue` if not already; log the demand and move on

Recommend one. Be specific about why.

### Step 5: Deadline triage

- **Their stated deadline** — note it, but it doesn't bind us
- **Our internal deadline** — when we must decide (often: stated deadline minus 5 business days to draft + approve)
- **Legal deadlines** — statute of limitations, contractual cure periods, procedural requirements

Flag any legal deadlines that are tight. Calendar them.

**No silent supplement.** If the inbound demand cites rules, cases, or statutes that require verification, and a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for a given authority, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [cite / doctrine]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave the `[SME VERIFY]` flag and stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every citation carried into the triage — including the sender's cited authorities, our response-option rationales, and any research pulled for merit assessment — with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations supplied in the demand itself. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

### Step 6: Write triage

Output: `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/[slug]/triage.md`.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

> **Privilege inheritance.** This triage is derived from the inbound demand and from the portfolio log, and it records our first-pass merit read and response posture. Those internal analyses are attorney-client and/or work-product material. Distributing this triage beyond the privilege circle — including forwarding it to the business lead without marking, sharing with the counterparty, or attaching to an insurance tender without scrubbing — can waive protection over both this document and the reasoning inside it. Store with privileged matter material, mark consistently with house privilege conventions, and make distribution decisions deliberately.

# Demand Received — Triage

> **READ FOR TRIAGE, NOT OPINION.** This document is an intake scan and an options analysis — not a legal merit opinion. The `Triage rating` below is a structured read to support the counsel's decision on how to route the demand. It is not a recommendation on the merits and does not substitute for case-specific legal analysis. Every cited statute, rule, or case is flagged for SME verification; every merit call is the counsel's, not this skill's.

**Slug:** [slug]
**Received:** [YYYY-MM-DD]
**Received by:** [entity / person]
**Incoming file:** [path]

---

## The demand

**Sender:** [entity, signer, counsel]
**Demand type:** [type]
**Specific asks:** [list]
**Their stated deadline:** [date]
**Settlement-communication framing:** [labeled / substantively / neither / ambiguous] — *protection turns on conduct and context, not the label; `[SME VERIFY]` against the forum's applicable rule*

## Facts alleged

[their version, in one paragraph]

## Legal basis cited

[citations — each inline-flagged with `[SME VERIFY: applicability / currency / jurisdiction]` — do not rely on any citation here without independent check]

## Threats / next steps they state

[list]

---

## Portfolio cross-check

**Direct match:** [slug if exists, or "none"]
**Type match / precedent:** [list or "none"]
**Subject overlap:** [list or "none"]
**Recommendation:** [new matter / add to existing / link via related_matters / standalone inbound]

---

## Merit assessment

**Facts:** [alignment with our version; disconnects]
**Legal basis:** [applicability, with flags]
**Their case if litigated:** [one paragraph]
**Our defenses:** [one paragraph]
**Damages proportionality:** [assessment]
**Credibility of threat:** [will they sue? capacity? repeat litigant?]

**Triage rating:** [substantial / debatable / weak / frivolous] — *structured read for routing, not a merit opinion; `[SME VERIFY: counsel to confirm before relying on this]`*

---

## Response options

### A. Substantive response
[Rationale, tradeoffs, next step]

### B. Holding letter
[Rationale, tradeoffs, next step]

### C. Settlement response
[Rationale, tradeoffs, next step]

### D. Ignore + preserve
[Rationale, tradeoffs, next step]

**Recommendation:** [A/B/C/D] — [two sentences why] — `[SME VERIFY: counsel to confirm before executing]`

---

## Deadlines

- **Their stated deadline:** [date]
- **Our internal decision deadline:** [date]
- **Legal deadlines:** [SoL, cure periods, procedural — with dates]

---

## Immediate actions

- [ ] Legal hold issued — [yes/no] — if no, run `/legal-hold [slug] --issue`
- [ ] Matter created in log — [yes/no/TBD]
- [ ] Counsel assigned — [who]
- [ ] Insurance tendered — [yes/no/N-A]
- [ ] Internal escalation (GC/CFO/business lead) — [who/when]
```

### Step 7: Hand off

Based on recommendation and user confirmation:

- Matter creation → hand off to `/matter-intake` with: counterparty, type, `source: demand-letter` (inbound), initial theory framed defensively, pre-populated.
- Counter-response as outbound demand → hand off to `/demand-intake` with: counterparty, context from triage, desired outcome as the response.
- Link to existing matter → update that matter's `related_matters` in `_log.yaml`; append event to its `history.md`.
- Standalone → leave in `~/.claude/plugins/config/claude-for-legal/litigation-legal/inbound/`; no portfolio change.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Validate cited law.** Flags cites for the user to run through a citator (verify it is good law) or check with outside counsel. Inventing legal analysis on inbound demands is malpractice exposure.
- **Send a response.** Drafts are drafted in `demand-draft`; this skill stops at the triage decision.
- **Decide merit definitively.** The rating is a read for triage; a formal merit opinion lives with outside counsel or more thorough analysis.
- **Make the matter-creation call.** Surfaces the recommendation; user decides.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/deposition-prep', 'legal', 'deposition-prep', '', 'deposition-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /deposition-prep

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → case theory, key facts.
2. Follow the workflow and reference below.
3. Pull docs authored by / mentioning witness from eDiscovery platform.
4. Build outline: background, key docs, topics tied to theory, impeachment material.

---

# Deposition Prep

## Witness statements for England & Wales — PD 57AC

If the user's jurisdiction includes England & Wales and they're asking for a trial witness statement for the Business & Property Courts (or any CPR-governed proceeding), PD 57AC applies. The statement must be in the witness's own words, must not contain argument, must identify the documents the witness used to refresh their memory, and must carry the required confirmation of compliance and the legal representative's certificate.

**Drafting a narrative "as the witness" from a chronology, document set, or your account of the case is exactly what PD 57AC was designed to prevent.** Courts are actively sanctioning AI-assisted witness statement drafting. If you ask me to do it, I won't.

What I WILL do: prepare question prompts to elicit the witness's actual recollection; capture and organize what the witness says (their words, not mine); generate the list of documents they were shown; run a PD 57AC compliance checklist against a statement they've drafted; draft the solicitor's certificate of compliance. I help you get the witness's evidence into the statement. I don't write the evidence.

For US depositions, declarations, and affidavits: different rules, but the same discipline applies. A declaration in the declarant's voice that the declarant didn't write is a credibility problem at best.

## Destination check

Before producing output, check where it's going. If the user has named a destination (a channel, a distribution list, a counterparty, "everyone"), ask whether it's inside the privilege circle. Public channels, company-wide lists, counterparty/opposing counsel, vendors, and clients (for work product) waive the protection. When the destination looks outside the circle, flag it and offer (a) the privileged version for legal only, (b) a sanitized version for the broader channel, or (c) both — don't silently apply a privileged header and then help paste it somewhere the header won't protect it. See the canonical `## Shared guardrails → Destination check` in this plugin's CLAUDE.md.

## Purpose

A depo outline is a map: background → lock in the good facts → confront with the bad ones → box in on the theory. This skill builds the map from the documents and the case theory.

## Record fidelity — quotes and pinpoints

Two rules that govern every citation and every quotation pulled from the record into this outline. Canonical statement lives in the plugin's `CLAUDE.md` shared guardrails; repeated here because an impeachment confrontation built on a misquoted prior statement or a misgrounded transcript cite collapses the impeachment.

**Verbatim quotes from the record must be verbatim.** Never put quotation marks around words attributed to opposing counsel, the witness, another deponent, the court, or any record document unless you have the exact passage in front of you and can cite to it. When you want to characterize what someone said but can't find the exact words:

- **Paraphrase without quotation marks**, attributing clearly: "Witness previously testified that X `[verify against record — Tr. p. __]`."
- **Mark the placeholder:** `[verify exact quote — record cite pending]`
- **Never fill the gap.** An invented prior statement destroys the impeachment the moment the witness disavows it and the transcript doesn't back you up. Every `[verify exact quote]` must be flagged in the reviewer note.

**Pinpoint cites must support the whole proposition.** If an impeachment point is "the witness said X, Y, and Z on [date]," verify the pinpoint cite supports X AND Y AND Z. If it only supports Z, split the cite — "said X (Tr. p. 10), Y (Tr. p. 12), Z (Tr. p. 15)" — or narrow the proposition. A cite that supports part of an impeachment is the failure mode where opposing counsel asks the witness to read more of the surrounding transcript and your confrontation falls apart.

## Oral calibration

A depo outline is read aloud in real time. That's oral advocacy, not written. It means:

- Pick the 3-4 topics that actually matter. Don't try to cover everything — a 200-question outline on a 4-hour depo makes the lawyer skim, and skimming is how lines of questioning get lost mid-sequence.
- Lead with your strongest confrontation. The witness is freshest at the start, and the transcript's opening pages are the ones a judge or jury is most likely to see.
- For adverse witnesses: the tightest questions go in the tightest sequences. Everything else is scaffolding.
- If you're preparing a rebuttal closing after the depo, the calibration is stricter still — the tribunal remembers the first two minutes and the last two.

"Too thorough" for oral work reads as unfocused. If the outline is long because the record is deep, say so and flag where the lawyer should collapse.

## Load context

`~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → case theory (theory, pivot fact, key facts for/against), eDiscovery platform.

**Conflicts gate — unbypassable.** Before building an outline, check `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't build a deposition outline on a matter that hasn't been intaken — the conflicts check is the gate."

Do not proceed on an unintaken matter. Intake is what runs conflicts and writes the `_log.yaml` row this skill reads from.

## Workflow

### Step 1: Who is this witness?

- Name, role, relationship to the case
- Why are we deposing them — what do we need from this witness?

The "why" connects to the theory. If the witness can establish the pivot fact, that's the centerpiece of the outline.

### Step 1a: Witness posture — branch before drafting questions

Prep structure differs by posture. Identify the witness posture before writing a single question:

- **Adverse / hostile** — cross-examination style: closed, leading, one fact at a time. Build the box.
- **Friendly / your own** — direct-examination style: open questions that let the witness tell the story. Closed leading questions with your own witness are usually improper and undercut credibility with the factfinder.
- **Neutral third-party** — mix; often open to get the story, closed to pin specifics.
- **Corporate representative (30(b)(6) or state equivalent)** — topic designation, binding-the-entity rules, and the witness's personal-knowledge vs. corporate-knowledge distinction all have distinct rules. Research the applicable deposition rule for the forum and the 30(b)(6) / state-equivalent procedure. Confirm: what topics were designated, who was produced, scope of binding testimony.

**Research the applicable deposition rules for the forum and witness type** (FRCP 30 / state equivalent, local rules, judge's standing orders on depositions). Cite primary sources. Don't apply a one-size prep structure — the question form, the approach to documents, and the use of impeachment material all depend on posture.

**No silent supplement.** If a research query to the configured legal research tool (Westlaw, CourtListener, Trellis, Descrybe, or firm platform) returns few or no results for the forum's deposition rules or a cite you need for impeachment, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / authority]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) leave the `[UNCERTAIN]` marker and stop here. Which would you like?" A lawyer decides whether to accept lower-confidence sources; the skill does not decide for them.

**Source attribution.** Tag every rule reference, case cite, and authority in the outline with where it came from: `[Westlaw]`, `[CourtListener]`, `[Trellis]`, `[Descrybe]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the partner or senior associate supplied. Document citations (Bates, production numbers) retain their native source. Citations tagged `verify` carry higher fabrication risk and should be checked before the deposition. Never strip or collapse the tags.

### Step 2: Pull their documents

From the eDiscovery platform (Everlaw/Relativity/DISCO if connected):

- Documents authored by witness
- Documents sent to or from witness
- Documents mentioning witness by name
- Calendar entries and meeting notes with witness present

Organize by date. Flag the hot docs — the ones that matter most for the theory.

### Step 3: Build topics

Each topic is a thing you want to establish or explore. Organize around the theory:

**Background (always first — lock in uncontroversial facts before the witness is defensive):**
- Role, tenure, responsibilities
- Reporting structure
- How they interacted with the key players

**Good facts (lock them in before confronting):**
- Facts from `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → key facts for us, that this witness can establish
- Documents that support our theory, authored or received by this witness

**Bad facts (confront with documents):**
- Facts against us that this witness will be asked about anyway — get your version first
- Documents that hurt — know how the witness will explain them

**Impeachment (if hostile or if they contradict):**
- Prior inconsistent statements (from docs, prior testimony, declarations)
- Documents that contradict what you expect them to say

**The pivot fact:**
- The sequence of questions that establishes (or undermines) the fact the case turns on
- This is the most carefully constructed section. Question form follows witness posture from Step 1a: tight closed leading on adverse, controlled open on friendly, mixed on neutral. Don't default to one pattern.

### Step 4: Write the outline

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# Deposition Outline: [Witness Name]

**Date:** [depo date]
**Witness role:** [title, relationship to case]
**Witness posture:** [adverse / friendly / neutral / 30(b)(6) or state equivalent] — drives question form
**Applicable deposition rules:** [FRCP 30 / state rule / local rule / standing order — with pinpoint cites] `[UNCERTAIN — verify currency]`
**Why we're taking this depo:** [one sentence — the goal]
**Theory connection:** [how this witness fits the case theory]

---

## I. Background

[Questions — closed, one fact each. Lock in the uncontroversial stuff.]

## II. [Good fact topic]

**Goal:** Establish [fact] for use at summary judgment / trial.

**Documents:**
- [Bates] — [description] — [why it matters]

**Questions:**
[The sequence. Each question closed. Build to the admission.]

## III. [Bad fact topic]

**Goal:** Get the witness's explanation of [bad fact] on our terms before they're prepped for trial.

[Same structure]

## IV. Impeachment material (use if needed)

[Prior statements / documents to confront with, if the witness contradicts]

## V. [Pivot fact sequence]

**Goal:** [The thing the case turns on]

[This is the tightest section. Every question is a yes/no. Every question establishes one fact. Build the box.]

---

## Exhibit list

| # | Bates | Description | Used in section |
|---|---|---|---|

## Marker discipline

Use inline while building and reviewing:
- `[VERIFY: factual assertion]` — any fact not confirmed against the record
- `[UNCERTAIN: legal proposition]` — any legal point (rule, deadline, scope-of-questioning limit) not confirmed against current authority
- `[CITE NEEDED: specific cite]` — record or authority cite pending

## Notes for the attorney

- [Anything the outline doesn't capture — witness demeanor notes, strategic calls to make in the moment]

---

**Privileged / work-product material.** This outline is built from case materials and work product and inherits their protection status. Keep it in the privileged-materials folder, mark it appropriately, and make any distribution decision (co-counsel, client, experts) deliberately — distribution outside the privilege circle can waive protection.

**Cite check any authority relied on.** Rule citations (FRCP 30, state equivalents, local rules, standing orders) and any case law pulled into the outline were generated by an AI model. Verify each against Westlaw, CourtListener, or your research platform — confirm currency and scope before using at the deposition. Source tags on each citation (e.g., `[Westlaw]`, `[web search — verify]`) show where the cite came from; `verify` tags carry higher fabrication risk and should be checked first.
```

## What this skill does not do

- Take the deposition. The outline is a map; the attorney drives.
- Predict what the witness will say. It prepares for likely answers, but witnesses surprise.
- Decide what to ask on the fly. Follow-ups are the attorney's judgment in the room.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/legal-hold', 'legal', 'legal-hold', '', 'legal-hold', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /legal-hold

1. If `--status` (no slug): read `_log.yaml`, produce portfolio-wide hold report.
2. Otherwise: load `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` + log row.
3. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → privilege markings, hold template pointer, escalation norms.
4. Follow the workflow and reference below.
5. Route by flag:
   - `--issue`: capture scope, custodians, date range, systems. Draft `legal-hold-v1.docx`. Update `legal_hold` fields. Append history entry. Set `next_refresh` (default +6mo).
   - `--refresh`: capture scope/custodian changes. Draft next version. Update `last_refresh` + `next_refresh`. Flag departed custodians.
   - `--release`: capture release date, retention instruction. Draft release notice. Set `released:` field.
6. Confirm before writing. Show the user the draft notice and the log diff.

---

# Legal Hold

## Purpose

A legal hold is the most mechanical high-stakes document in-house counsel writes. The notice itself is templated. The failure modes are operational: issued too late, scoped too narrowly, never refreshed, never released. This skill owns all four phases: **issue → refresh → (release) → track**.

The portfolio already flags missing holds; this skill writes them.

## Jurisdiction assumption

Preservation duties vary materially by forum. Federal common law (via Zubulake / Residential Funding / Rule 37(e)) differs from state practice; states differ from each other on trigger timing, scope, sanctions, and spoliation remedies; regulatory preservation obligations overlay civil rules in some matters (SEC Rule 17a-4, HIPAA, etc.). The trigger, scope, and sanctions exposure cited in the draft are a starting-point read for the forum named in the matter — confirm with counsel before issuing, refreshing, or releasing.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — log row (legal_hold fields + status)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — matter context (counterparty, facts, key custodians from internal_owners)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — house style for litigation hold template pointer, privilege marking, escalation norms

**Conflicts gate — unbypassable.** Before issuing, refreshing, or releasing a hold, check `_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't issue, refresh, or release a legal hold on a matter that hasn't been intaken — the conflicts check is the gate, and a hold issued against an unmanaged matter has no `_log.yaml` row to track `last_refresh` / `next_refresh` / `released` against."

Do not proceed on an unintaken matter. Intake is what runs conflicts and writes the `_log.yaml` row the `--refresh` / `--release` / `--status` flags operate against.

## Modes

The command takes a flag: `--issue | --refresh | --release | --status`. Default (no flag) → prompt.

### `--issue` — first issuance

Required when `legal_hold.issued == false` and the matter is active or reasonably anticipated.

**Before issuing the hold to custodians (the consequential act):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Issuing a legal hold has legal consequences — the scope, custodian list, and timing create the preservation record the company will be judged on if spoliation is argued later. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the matter and trigger, the proposed scope and custodians, the forum-specific preservation rule researched, known spoliation exposure, what could go wrong (too broad / too narrow), what to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not send the notice without an explicit yes. Drafting and scoping do not require the gate — issuance does.

**Research the applicable preservation rule before issuing.** Identify the jurisdiction and the source of the preservation duty (common law, rule of civil procedure, regulatory preservation obligation, contractual). Confirm the currently operative trigger standard (when the duty attaches), scope standard (what must be preserved), and sanctions exposure (spoliation doctrine for the forum). Cite primary sources. Note that federal and state law can differ materially on trigger timing, scope, and remedy — flag the forum you're relying on. If uncertain, say so and get outside-counsel sign-off before issuing.

> **External deliverable:** the notice below is sent to custodians. Do NOT include a `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT — PREPARED AT THE DIRECTION OF COUNSEL` header on the outgoing notice; use the attorney-client marking in the template. Confirm the correct marking for your jurisdiction and matter.

**Inputs:**
1. **Scope** — categories of documents, data, communications. Start specific: contracts with counterparty, all communications referencing [project/subject], related financial records, calendar entries. `[SME VERIFY — scope too broad = operational burden; too narrow = spoliation risk]`
2. **Custodians** — named individuals likely to hold responsive material. Pull suggestions from matter.md internal_owners and from common roles (business lead, HR partner if employment, CISO if data). `[SME VERIFY — the custodian list is the difference between defensible preservation and a gap argument]`
3. **Date range** — when to start preserving from (usually: triggering event or earlier), through the present + ongoing.
4. **Systems** — email, Slack/Teams, file shares, devices (including BYOD if applicable), Jira/Asana, CRM, legacy systems.
5. **Urgency** — if litigation already served or demand received with threat of suit, this goes out today.
6. **Effective date** — date of the hold.

**Draft the notice** to each custodian, using the house template in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` if one is configured; otherwise the default template below.

**Default hold notice template:**

```
[PRIVILEGED & CONFIDENTIAL — ATTORNEY-CLIENT COMMUNICATION]

DATE: [effective date]
TO: [custodian name]
FROM: [signer — per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` default]
RE: LITIGATION HOLD NOTICE — [matter short name]

You are receiving this notice because [company] has determined that [one-
sentence description of the dispute / investigation, avoiding prejudicial
detail]. The law requires preservation of documents and communications
potentially relevant to this matter.

EFFECTIVE IMMEDIATELY, you must preserve:

1. All documents, emails, text messages, Slack/Teams messages, and other
   communications relating to [scope bullet 1].
2. [scope bullet 2]
3. [scope bullet 3]
...

This preservation obligation applies to:
- Email (including sent, archived, deleted folders)
- Slack/Teams/messaging platforms
- Shared drives and cloud storage
- Personal devices used for company business (BYOD)
- Paper documents
- Voicemails
- Calendar entries and meeting notes

DO NOT:
- Delete, modify, destroy, or dispose of any potentially responsive material
- Auto-delete or "Inbox Zero" any email or messaging

Coordinate with [legal contact] before sharing this notice with direct reports
or IT.

Direct questions about this notice or your preservation obligations to [legal
contact]. You may continue to discuss the underlying business subject matter
with colleagues as needed for your work, but do not discuss this legal notice,
the litigation, or legal strategy.

IF YOU ARE UNSURE whether something is covered, ERR ON THE SIDE OF PRESERVING.

Please acknowledge receipt of this notice by [reply / link / form] within
three business days. If you have questions, contact [signer email].

This notice remains in effect until you receive written notice of its
release. You may be asked to reaffirm compliance at periodic intervals.

[Signer signature block]
```

**Send gate (closing note on the draft):** Append to the in-chat preview of the notice — stripped before the notice goes to custodians:

> This is a draft legal hold notice for attorney review, not a notice ready to issue. Issuing a hold triggers preservation obligations the company will be judged on in any later spoliation argument, and the notice itself may be discoverable. A licensed attorney reviews, approves, and issues. Do not distribute this draft unreviewed.

**Writes:**
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/legal-hold-v1.docx` via the `docx` skill
- Appends to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`:
  ```
  ## [YYYY-MM-DD] — Legal hold issued

  Hold issued to [N] custodians: [list].
  Scope: [one-line summary].
  Next refresh: [YYYY-MM-DD (default issued + 6 months)].
  ```
- Updates `_log.yaml` row:
  ```yaml
  legal_hold:
    issued: true
    issued_date: [YYYY-MM-DD]
    scope: "[one-line summary]"
    custodians: [list]
    last_refresh: [YYYY-MM-DD]   # same as issued_date on first issuance
    next_refresh: [YYYY-MM-DD]   # default: issued_date + 6 months
    released: null
  ```

### `--refresh` — periodic reaffirmation

Refresh cadence: default 6 months; adjustable per matter. When `next_refresh < today` (or user invokes manually), the skill drafts a refresh notice.

**Inputs:**
1. Any **scope changes** since last refresh (new topics surfaced in discovery, new custodians, new systems).
2. Any **custodians to add or remove** (departures need special handling — see below).
3. Re-confirmation language.

**Refresh notice template:** similar to issuance; opens with "This is a reaffirmation of the legal hold originally issued [date]." Lists current scope (amended if needed). Requests re-acknowledgment.

**Departed custodians:** if a custodian has left the company since last refresh, the skill flags this as a preservation action item — the departing employee's files and email archive need to be preserved at IT level, not just via notice to the individual. Records this in history.md as a separate entry requiring action.

**Writes:**
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/legal-hold-v[N].docx` (next version number)
- `history.md` entry
- `_log.yaml`: updates `last_refresh` and `next_refresh` fields; modifies `custodians` list if changed

### `--release` — close the hold

Usually at matter close. Confirm the matter is truly over (not on appeal, not likely to reopen, statute of limitations passed on related claims).

**Before releasing the hold (the consequential act — preservation obligations resume normal retention):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Releasing a legal hold has legal consequences — once released, custodians may begin deleting material. Release at the wrong time creates spoliation exposure. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the matter status, why release is proposed now, related-claim / appeal / SOL exposure, custodian impact, what could go wrong, what to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not send the release notice without an explicit yes.

**Inputs:**
1. Confirmation of release authority (usually the signer or GC).
2. Release date.
3. Retention instruction — what happens to the material that was under hold? (Return to normal retention? Continue preserving for defined period? Transfer to archive?)

**Release notice template:** one paragraph, formal. "The litigation hold issued [date] regarding [matter] is released effective [date]. Normal retention resumes."

**Writes:**
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/legal-hold-release.docx`
- `history.md` entry
- `_log.yaml`: sets `released: [YYYY-MM-DD]`

### `--status` — report across the portfolio

Read `_log.yaml`. Produce a report:

```markdown
# Legal Hold Status — [today]

## Active holds

| Matter | Issued | Last refresh | Next refresh | Custodians | Status |
|---|---|---|---|---|---|
| [slug] | [date] | [date] | [date] | [N] | [ok / ⚠️ refresh due / ❌ overdue] |

## ⚠️ Attention

- **Refresh overdue:** [list slugs where next_refresh < today]
- **Refresh due within 30 days:** [list]
- **Matters active without hold issued:** [list — high/critical risk first]
- **Matters closed with hold still active:** [list — consider release]

## Recently released

[last 5 released holds with dates]
```

This is a separate command invocation (`/legal-hold --status` with no slug) OR invoked by `/portfolio-status` as a section in the portfolio rollup.

## Integration with portfolio-status

The `portfolio-status` skill already flags "Hold not issued on active litigation." This skill is what resolves those flags. Worth cross-referencing in the briefing when a matter is opened: if `legal_hold.issued == false`, `/matter-intake` closes by offering to run `/legal-hold --issue`.

## What this skill does not do

- **Enforce preservation.** It issues the notice; IT/custodians preserve. The skill flags when a custodian leaves (so IT can preserve at system level) but doesn't reach into systems.
- **Make scope calls alone.** The skill proposes scope from matter context; the user confirms. Scope too broad = operational burden. Scope too narrow = spoliation risk. User's judgment.
- **Auto-refresh without review.** Even when `next_refresh` comes up, the user reviews scope changes before the refresh notice goes out.
- **Send the notice.** Drafts .docx; user sends via email per house convention. (Future integration: Gmail/O365 MCP could send directly after user review.)$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/matter-briefing', 'legal', 'matter-briefing', '', 'matter-briefing', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-briefing

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → risk calibration + relevant stakeholders.
2. Follow the workflow and reference below.
3. Read `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` + `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` + log row from `_log.yaml`.
4. Produce briefing: current posture, what's changed since last update, next deadline, open questions, risk re-assessment check ("does the `risk:` field still reflect reality?").
5. Flag staleness: if `last_updated` > 30 days, say so.

---

# Matter Briefing

## Purpose

Give the counsel a clean read on one matter in the time it takes to walk to a conference room. Current posture, what's changed, what's next, what's worth reconsidering.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — structured row
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — narrative intake
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` — event log
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — risk calibration (so "risk: high" means something specific, not generic)

**Conflicts gate — unbypassable.** Before briefing, check `_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace is set up. I won't build a briefing on a matter that hasn't been intaken — the conflicts check is the gate."

## Input

Slug (required). If ambiguous or missing, ask the user to pick from a list of active matters.

## The briefing

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# [Matter Name] — Briefing as of [today]

**Status:** [status / stage]
**Risk:** [rating] ([severity] × [likelihood])
**Materiality:** [category]
**Outside counsel:** [firm — lead]
**Last updated:** [date] [flag ⚠️ STALE if >30d]
**Conflicts:** [status — flag ⚠️ if `pending` or `not-run`]

---

## One-paragraph summary

[Current posture. What are we doing and why. Name the pivot fact if one is captured.]

## What's changed recently

[Last 3-5 entries from history.md, most recent first. If history is thin, say so.]

## What's next

- **Immediate deadline:** [next_deadline + what it is]
- **Upcoming milestones:** [anything dated in matter.md or recent history]
- **Decisions pending:** [open questions flagged in matter.md]

## Exposure

[Range + any change since intake. If reserved, current reserve + whether recalibration is overdue.]

## Internal owners

[Who's looped in; whether anyone should be looped in and isn't]

## Risk re-assessment check

*A prompt, not an answer.*

- Does `risk: [rating]` still feel right, or has the case moved?
- Does `materiality: [category]` still match? (New facts might push toward reserve or disclosure.)
- Any new stakeholder the matter needs (e.g., CISO becomes relevant after a discovery development)?

## Open questions

[From matter.md and anything unresolved in history]

## For the conversation

[If user specified a purpose — "brief me before the call with outside counsel" — tailor the final section: questions to ask, decisions to get, updates to extract. If no purpose given, omit this section.]
```

## Staleness

If `last_updated > 30 days ago`: flag at the top AND suggest running `/litigation-legal:matter-update [slug]` after the meeting to capture whatever's discussed.

## Tone

This is not marketing. Say what's known; flag what's not. If a matter has thin history and was just opened, the briefing is short — and that's correct. Don't pad.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- Predict outcomes. Risk rating is a captured judgment, not a forecast.
- Recommend strategy. Surfaces questions; the counsel answers them.
- Re-triage. If the user wants to re-triage, that's an `/matter-update` with field changes — this skill reads, doesn't write.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/matter-close', 'legal', 'matter-close', '', 'matter-close', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-close

1. Follow the workflow and reference below.
2. Confirm slug and current status.
3. Capture outcome: resolution type (settled, dismissed, judgment for/against, withdrawn, consolidated), date, final exposure/cost, lessons.
4. Update `_log.yaml`: `status: closed`, add `closed: YYYY-MM-DD` and `outcome:` fields.
5. Append final entry to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`.
6. Matter stays in `_log.yaml` and `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/` — not deleted. `/portfolio-status` filters it from active rollups.

---

# Matter Close

## Purpose

Matters end. The outcome is the single most valuable data point the portfolio generates — it calibrates the risk framework for future matters. Closing a matter captures the outcome structurally so the record is useful, not just archived.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — find the row
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — reference (intake context)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` — append target

**Conflicts gate — unbypassable.** Before closing, check `_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Nothing to close — either the slug is wrong or the matter was never intaken through `/litigation-legal:matter-intake`. Check the slug first; if it genuinely was never intaken, there's no row to update and no file structure to close."

## Input

Slug (required).

## The close

### 1. Resolution type

- `settled` — with counterparty, dollar amount, structural terms
- `dismissed` — with or without prejudice, by what mechanism
- `judgment-for-us` — at what stage, appeal exposure
- `judgment-against-us` — at what stage, appeal status, exposure crystallized
- `withdrawn` — by counterparty, circumstances
- `consolidated` — merged into another matter (provide slug of parent)
- `other` — with explanation

### 2. Resolution date

The date the matter actually ended (settlement executed, order issued, dismissal filed).

### 3. Final exposure

- Actual cost to company (settlement amount + fees + injunctive/structural cost)
- vs. initial exposure range at intake (did we call it?)
- Reserve accuracy (if reserved): booked vs. actual

### 4. Lessons

Two or three sentences. What did we get right? What did we misjudge? Anything the intake should have flagged earlier?

This is the part future counsel will reread. Be honest. "Misjudged likelihood — plaintiff firm was more aggressive than expected" is worth more than "resolved favorably."

### 5. Seed doc prompt

Settlement agreement, final order, dismissal — path if available. Not required.

## Writing

**Before closing the matter (the consequential act — the matter is archived and active tracking ends):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Closing a matter has legal consequences — it ends active tracking, may affect any associated legal hold (run `/legal-hold --release` separately if appropriate), and establishes the final record the company relies on. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the matter, resolution type and terms, final exposure vs. initial, reserve accuracy, related matters or appeals still live, what could go wrong with premature closure, what to ask the attorney.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not write the close fields or append the close entry without an explicit yes.

### Update `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`

```yaml
status: closed
closed: [YYYY-MM-DD]
outcome: [resolution-type]
final_cost: [dollar amount]
last_updated: [today]   # close is the last touch; record it
```

Retain all existing fields. Do not delete the row.

### Append final entry to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`

```markdown
## [YYYY-MM-DD] — Matter closed: [resolution-type]

**Resolution:** [narrative — what happened, on what terms]
**Final cost:** [amount + structural terms if any]
**vs. initial exposure:** [compare to matter.md intake range]
**Reserve accuracy:** [if applicable]

**Lessons:**
[2-3 sentences — honest retrospective]

**Related doc:** [settlement agreement / final order / etc., if provided]
```

### Touch `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md`

Add a closing block at the end (don't modify earlier sections — they're the historical intake):

```markdown
---

## Closed [YYYY-MM-DD]

[Resolution summary in one paragraph. Pointer to the final history entry for detail.]
```

## Confirm

Show the user the full close entry and the yaml changes before writing.

## What this skill does not do

- Delete matters. Closed matters stay in `_log.yaml` and on disk — they're the training set for the portfolio's judgment.
- Re-open. If a closed matter comes back (appeal, related litigation), open a new matter that references the closed one in `matter.md`.
- Summarize lessons the user didn't say. If the user skips the lessons section, leave it empty rather than invent.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/matter-intake', 'legal', 'matter-intake', '', 'matter-intake', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-intake

1. Load `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → risk calibration (for triage), landscape (for context, conflicts method), stakeholders (for who to loop in).
2. Follow the workflow and reference below.
3. Run the uniform intake: identification, conflicts check, source, risk triage, materiality, outside counsel, internal owners, legal hold, key dates, initial posture.
4. Generate slug from matter name (lowercase, hyphens, year).
5. Create `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — full narrative intake.
6. Create `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` — seeded with the intake as the first entry.
7. Append structured row to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`.
8. Confirm with the user: "Here's the row I'll write — any edits?"

---

# Matter Intake

## Purpose

Every new matter goes through the same intake so the portfolio stays comparable. Uniform rows in `_log.yaml` let the status skill roll up. Narrative in `matter.md` captures what the row can't. History file seeded here becomes the event record.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — risk calibration (triage thresholds, materiality, settlement ladder), landscape (stakeholders, outside counsel bench).
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — to confirm slug uniqueness.

## The intake

### 1. Identification

- Matter name (as commonly referenced, e.g., "Acme v. Us 2026")
- Counterparty
- Matter type: `contract | employment | ip | regulatory | investigation | product | other`
- Our role: `plaintiff | defendant | claimant | respondent | investigated`
  - If the practice profile's `## Side` is `plaintiff`, `defense`, or a "both — default X" variant, pre-fill the role from that default and confirm. If `## Side` is `varies by matter`, ask cold. Never silently assume a posture the practice profile hasn't set.
  - The role drives downstream skills: plaintiff-posture matters route risk triage to case value / contingency economics; defense-posture matters route to exposure / reserves / insurance tender.
- Jurisdiction (court, arbitration forum, or regulatory body)

### 2. Conflicts check

Before going further, run the conflicts step per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` → Conflicts clearance.

- **Status:** `cleared | pending | not-run | waived`
- **Method:** match what `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` declares (`corporate-legal | outside-counsel | system-check | informal | other`). If the declared method is `informal`, say so — the record still captures that a counsel's-judgment check was the basis.
- **Cleared by:** name / team / firm
- **Cleared date:** YYYY-MM-DD
- **Checked against:** brief list of the specific names/entities run (counterparty, known affiliates, adverse counsel if known, key witnesses). Thin is fine; "no" is not.
- **Notes:** anything flagged but cleared (e.g., "Smith on our board sat on counterparty's board 2019–2021 — cleared as non-overlapping to this matter").

Behavior by status:

- `cleared` → proceed.
- `pending` → proceed with intake; flag prominently in `matter.md` and in the log row that conflicts are outstanding; surface again on every `/matter-update` and in `/portfolio-status` until resolved.
- `waived` → rare; requires a conflict-waiver rationale (writing the waiver is outside this skill — capture that one exists, who signed it, and where it lives).
- `not-run` → **STOP. This is a gate.** The skill will not create `matter.md`, `history.md`, or a `_log.yaml` entry until the conflicts posture is resolved. Three acceptable paths:

  **Path 1 — Run conflicts now.** Pause this intake. Clear per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` Conflicts clearance. Return with `status: cleared` or `status: waived` with rationale.

  **Path 2 — Mark pending with owner + due date.** Allowed only when `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` Conflicts clearance declares parallel-intake acceptable. Capture: who is running conflicts, when they're expected to return, what entities they're checking. Intake proceeds; matter row carries `conflicts.status: pending`; `/portfolio-status` flags it every run; `/matter-update` re-prompts until resolved.

  **Path 3 — Bypass with documented rationale.** Only if the user explicitly acknowledges the bypass. Record in `conflicts.override`:

  ```yaml
  conflicts:
    status: not-run               # preserved as-is
    override:
      by: [user name]
      date: [YYYY-MM-DD]
      rationale: [why conflicts were bypassed — permanent record; does not auto-expire]
  ```

  This field is visible in every `/portfolio-status`, every `/matter` briefing, and every `/matter-update` until removed. It is never removed by the skill — only by explicit user edit to `_log.yaml` after conflicts are actually cleared.

  **Do not proceed silently.** "I'll do it later" is not an acceptable response. One of Path 1/2/3 must be chosen, and the choice is captured in the record.

This step is not about the skill deciding whether a conflict exists — that's the user's/firm's judgment. It's about making sure the check happened and the record reflects it.

### 3. Source

How did this arrive?
- `demand-letter | complaint-served | subpoena | regulator-inquiry | internal-report | pre-suit-threat`
- *Seed doc opportunity:* "If you have the initiating document (complaint, demand, subpoena), attach or share the path. It sharpens the intake."

### 4. Risk triage — against house calibration

- Severity: high | medium | low (reference the `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` severity bands)
- Likelihood: high | medium | low (reference the `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` likelihood bands)
- Resulting risk rating (per the matrix): high | medium | low | critical
- Damages exposure range (best estimate)
- Non-monetary exposure (injunction? consent decree? publicity? precedent?)

If the risk calibration in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` is thin, don't fake precision. Use the user's gut and note the thinness.

### 5. Materiality

Against the house thresholds in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`:
- `reserved | disclosed | monitored | none`
- If `reserved`: reserve amount and whether finance has been notified
- If `disclosed`: filing and footnote location

### 6. Outside counsel

- Firm
- Lead partner
- **Lead partner email** (used by `/oc-status` to draft status requests)
- Engagement letter status: `signed | pending | none`
- Budget authorization: amount and approver
- *Seed doc opportunity:* "Engagement letter path, if signed."

If risk is medium or higher and no outside counsel is assigned — flag it.

### 7. Internal owners

From `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` landscape — which internal stakeholders are involved?
- Business lead
- HR partner (if employment)
- Comms contact (if reputational risk)
- CISO (if data or cyber)
- Other

### 8. Legal hold

- Issued? If yes: date, scope, custodians (list of names).
- Next refresh date (default: six months from issuance; adjust per matter).
- If no and this is active litigation or reasonably anticipated: flag urgently; offer to run `/litigation-legal:legal-hold [slug] --issue` after intake completes.
- *Seed doc opportunity:* "Hold notice, if issued."

### 9. Key dates

- Response deadline (answer, objection, opposition)
- Next hearing / conference
- Statute of limitations cutoff (if applicable)
- Any regulatory deadlines

### 10. Initial posture

One-paragraph theory:
- What's our story?
- What's theirs?
- What's the pivot fact?
- Initial posture: `fight | settle | investigate | wait`

## Writing the outputs

### Slug

Lowercase, hyphens, year at the end. Examples: `acme-v-us-2026`, `employment-smith-2026`, `ftc-inquiry-2026`.

Confirm slug is unique in `_log.yaml` before writing.

### `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md`

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# [Matter Name]

**Slug:** [slug]
**Opened:** [YYYY-MM-DD]
**Our role:** [plaintiff/defendant/etc.]
**Status:** [status]

---

## Identification

[counterparty, jurisdiction, matter type, source]

## Conflicts

**Status:** [cleared / pending / not-run / waived]
**Method:** [corporate-legal / outside-counsel / system-check / informal / other]
**Cleared by:** [name]
**Cleared date:** [YYYY-MM-DD]
**Checked against:** [entities run]
**Notes:** [any flags cleared, waiver reference if applicable]

## Risk triage

**Severity:** [band] — [why, with reference to house severity definitions]
**Likelihood:** [band] — [why]
**Risk rating:** [high/medium/low/critical]
**Exposure:** [dollar range + non-monetary]

## Materiality

[reserved/disclosed/monitored/none — with reserve amount, disclosure location, or reasoning if "none"]

## Outside counsel

[firm, lead, engagement status, budget]

## Internal owners

[stakeholders and why each is involved]

## Legal hold

[status, date, scope]

## Key dates

[list]

## Initial theory

[one paragraph: our story, their story, pivot fact, initial posture] `[SME VERIFY — theory at intake is a working hypothesis; confirm with outside counsel before any filing or material communication that assumes this framing]`

## Open questions

[anything not yet known that matters — e.g., "insurance tender pending", "unclear whether we have coverage for X"]

---

## Seed documents

| Doc | Path / pointer |
|---|---|
| [e.g., complaint] | [path or "not yet shared"] |
```

### `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`

Seed the history file with the intake as entry zero:

```markdown
# History: [Matter Name]

Append-only event log. Most recent at top.

---

## [YYYY-MM-DD] — Matter opened

[Source, who brought it in, initial triage summary, outside counsel assigned, legal hold issued yes/no.]
```

### Append to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`

Add a row per the schema. Example:

```yaml
- id: acme-v-us-2026
  name: "Acme Corp v. Company"
  type: contract
  role: defendant
  counterparty: "Acme Corp"
  jurisdiction: "N.D. Cal."
  # status is derived from source:
  #   source: pre-suit-threat | demand-letter           → status: threatened
  #   source: complaint-served | subpoena | regulator-inquiry → status: active
  #   source: internal-report                           → status: threatened (default) or active if formal process has started
  status: active
  stage: pleadings
  source: complaint-served
  outside_counsel:
    firm: "Wilson Sonsini"
    lead: "J. Reyes"
    email: "jreyes@wsgr.example.com"
    engagement: signed
  conflicts:
    status: cleared
    method: corporate-legal
    cleared_by: "K. Patel"
    cleared_date: 2026-04-20
    override:                   # populated only on Path 3 bypass
      by: null
      date: null
      rationale: null
  risk: high
  materiality: reserved
  exposure_range: "$2M–$5M"
  internal_owners:
    business_lead: "Jane Smith"
    hr_partner: null
    comms_contact: null
  legal_hold:
    issued: true
    issued_date: 2026-02-15
    scope: "Sales org 2023–2026"
    custodians: ["Jane Smith", "R. Chen", "T. Patel"]
    last_refresh: 2026-02-15
    next_refresh: 2026-08-15
    released: null
  related_matters: []
  opened: 2026-04-20
  next_deadline: 2026-05-15
  last_updated: 2026-04-20
  path: matters/acme-v-us-2026/
```

## Confirm before writing

Show the user the row and the matter.md content:

> Here's what I'll write. Flag anything wrong or thin before I commit.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **Run the conflicts check itself.** It records the result, status, method, and the entities checked. The actual clearance happens in whatever system (or judgment) the house practice profile declares. If the user says "cleared," the skill takes that at face value and captures the metadata.
- Decide the initial theory. It captures what the user says; it doesn't invent one.
- Issue the legal hold. Flags it if missing. User issues it.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/matter-update', 'legal', 'matter-update', '', 'matter-update', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-update

1. Follow the workflow and reference below.
2. Confirm slug exists in `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/` and `_log.yaml`.
3. Prompt for event type, date (default today), summary, and any log field updates (risk change, status change, next deadline shift, materiality reclassification).
4. Append dated entry to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`.
5. Update `_log.yaml` — set `last_updated` to today, apply any field updates.
6. Confirm.

---

# Matter Update

## Purpose

The portfolio only stays useful if it stays current. This skill makes logging an update cheap — two minutes of structured capture, no freeform drift.

## Load context

- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml` — find the row
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md` — append target
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/matter.md` — reference (don't rewrite)
- `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — risk calibration (if re-assessing risk)

**Conflicts gate — unbypassable.** Before logging an update, check `_log.yaml` for the matter slug. If the matter is not in `_log.yaml`, refuse and route:

> "I don't see [matter slug] in the matter log. Run `/litigation-legal:matter-intake` first so the conflicts check runs and the matter workspace exists. I won't append history to an unmanaged matter — the conflicts check is the gate, and there's no `history.md` to append to until the matter is intaken."

## Input

Slug (required). If not provided, ask — with a short list of recently updated matters to pick from.

## The update

### 1. Event type

Offer categories:

- **Procedural** — motion filed/received, order issued, hearing held, deadline set
- **Discovery** — production made/received, depositions taken, subpoena served
- **Substantive** — new facts, key document surfaced, ruling on merits
- **Strategy** — posture shift, settlement offer made/received, authority update
- **Risk re-assessment** — severity or likelihood changed
- **Stakeholder** — new person looped in, outside counsel change
- **Administrative** — engagement letter executed, budget adjusted, hold refreshed

Or freeform if none fits.

### 2. Date

Default today. Accept an override (e.g., capturing an event from last week).

### 3. Summary

One-paragraph narrative. What happened, what it means, any immediate implication.

### 4. Log field changes

Walk through potentially affected fields:

- `status:` — has the stage shifted (e.g., pleadings → fact discovery)?
- `stage:` — substage update
- `risk:` — reassessment required?
- `materiality:` — any change (new facts might trigger reserve or disclosure)?
- `exposure_range:` — revise if new information
- `next_deadline:` — new upcoming date, if any
- `outside_counsel:` — change?
- `internal_owners:` — anyone new or removed?
- `legal_hold:` — refreshed, expanded, released?

Only prompt for fields likely affected by the event type. Procedural updates usually touch `stage` and `next_deadline` only; a settlement offer might touch `materiality`, `exposure_range`, `status`.

### 4pre. Settlement-acceptance gate

If the Strategy update is a **settlement acceptance** (the company is accepting a settlement offer, executing a settlement agreement, or authorizing acceptance in principle — not merely logging an offer made or received): Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Accepting a settlement has legal consequences — it resolves claims, typically requires a release, and can affect insurance, tax, and related matters. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the matter, proposed settlement terms (dollar, structural, release scope, confidentiality, non-disparagement), exposure at stake, authority ladder status (see `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` settlement authority), what could go wrong, what to ask the attorney before accepting.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not log the acceptance or flip materiality on acceptance basis without an explicit yes. Logging offers or counters does not require the gate — acceptance does.

### 4a. Materiality trigger — explicit prompt

Certain event types force a materiality re-check. When the event type is in this list, **always prompt** — don't let the user move on without an explicit answer:

| Event type | Materiality trigger prompt |
|---|---|
| Substantive (new facts, key document, merits ruling) | "This event is substantive. Does it push `materiality`? Current: `[current]`. Options: `reserved / disclosed / monitored / none`. Change?" |
| Strategy (posture shift, settlement offer made or received) | "Settlement activity often triggers materiality reclassification. Current: `[current]`. If the offer, counter, or acceptance moves exposure or shifts from contested to probable-and-estimable, reclassify." |
| Risk re-assessment (severity or likelihood changed) | "Risk moved. Materiality should track. Current: `[current]`. Reclassify?" |
| Regulatory / enforcement development | "Regulator action (subpoena, CID, enforcement notice) usually triggers disclosure analysis. Current: `[current]`. Change?" |

Acceptable answers include `no change` — but `no change` must be explicit, not implied by silence. Capture in the history entry:

```markdown
**Materiality check:** [no change / changed from X to Y]
**Reasoning:** [one sentence]
```

If materiality moves to `reserved` or `disclosed`, and the matter did not previously carry a reserve or disclosure, flag the event as requiring finance / audit-committee notification per `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` materiality thresholds.

### 5. Seed doc prompt (optional)

If the update references a document (order, filing, correspondence), ask if there's a path to link. Not pushy.

## Writing

### Append to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/[slug]/history.md`

Most recent at top, directly under the `---` that follows the header.

```markdown
## [YYYY-MM-DD] — [Event type]: [short title]

[Paragraph summary.]

**Fields changed:**
- [field]: [old → new]
- [field]: [old → new]

**Related doc:** [path, if provided]
```

If no fields changed, omit the "Fields changed" block.

### Update `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_log.yaml`

- Apply any field changes.
- Set `last_updated: [today]` (or the event date if the user overrode — the log tracks when the record was last touched).

## Confirm

Show the user the history entry and the yaml diff before writing:

> Here's what I'll append and update. Good to commit?

## What this skill does not do

- Edit past history entries. Corrections are new entries that reference and correct prior ones.
- Silently change the log. Every field change is shown to the user before write.
- Decide whether a new development warrants reserve/disclosure. It surfaces the question ("this might push materiality — want to reclassify?"), the user answers.$body$),
('marketplace:claude-for-legal/claude-for-legal/litigation-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This command manages those workspaces.

## Subcommands

- `/litigation-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/litigation-legal:matter-workspace list` — list matters with status and active flag
- `/litigation-legal:matter-workspace switch <slug>` — set the active matter
- `/litigation-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_archived/`, never delete)
- `/litigation-legal:matter-workspace none` — detach from any active matter, work at practice-level only

Note: `/litigation-legal:matter-briefing [slug]` (no subcommand) is a separate command that produces a briefing on a specific matter — useful for in-house portfolio review. Matter workspace management lives here.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/litigation-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/litigation-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Follow the workflow and reference below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/litigation-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

# Matter Workspace

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; the `/matter-workspace` skill explains the disabled state and suggests `/cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/litigation-legal/
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
   - **Matter type** (read the plugin's practice profile for typical categories; for litigation-legal: contract dispute | employment | IP | regulatory / investigation | product liability | class action | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/litigation-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/litigation-legal:matter-workspace new <slug>`.
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
