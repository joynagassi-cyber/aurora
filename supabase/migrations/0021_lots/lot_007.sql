INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/invention-intake', 'legal', 'invention-intake', '', 'invention-intake', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /invention-intake

**This is a first-pass screen by a non-specialist, not a patentability
opinion.** The screen never concludes that an invention is patentable — it
concludes that it passes the initial screen and warrants a prior-art search
and registered-practitioner review, that it needs more information, or that
it hits a disqualifier. A prior-art search is a separate step; this skill
does not do one.

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it
   contains `[PLACEHOLDER]`, stop and direct to `/ip-legal:cold-start-interview`. If the
   practice profile shows trademark- or copyright-only (no patent practice),
   say so and route the user elsewhere — this is the wrong tool.
2. Follow the workflow below.
3. Run intake. If the user pasted or uploaded a disclosure, read it. If not,
   ask the seven intake questions (what / problem / differences / inventors /
   public disclosure / status / technology area) in one batch and wait.
4. Run the six screens: novelty signals, obviousness flags, § 101 eligibility,
   public disclosure / bar dates, detectability, strategic value. Each screen
   gets a ✓ / 🟡 / 🔴 verdict with one-line reasoning.
5. Write the invention screen memo to the matter folder (if a matter is
   active) or the practice outputs folder. Apply the work-product header per
   role.
6. Bottom-line verdict: **PURSUE** (schedule prior-art search and attorney
   review) / **INVESTIGATE** (needs more info on a specific open item) /
   **DECLINE** (state the concrete reason). Never say "patentable."
7. Close with the decision tree (prior-art search / inventor follow-up /
   specialist review / decline + thank-you / trade-secret route) and the
   non-lawyer gate if the role is non-lawyer.
8. If the screen hit a within-one-year US disclosure or any public disclosure
   with foreign rights in scope, flag at the top: **time-sensitive**.

This skill never concludes that an invention is patentable. If uncertain,
flag — a registered patent attorney or agent decides.

## Examples

```
/ip-legal:invention-intake "a new cache-eviction algorithm that uses a learned model rather than LRU; conceived Q1 this year, not yet disclosed, engineering prototype in internal staging"
```

```
/ip-legal:invention-intake
```

(And the skill will ask for the invention, the problem it solves, how it
differs, inventors, public disclosure status, usage status, and technology
area.)

---

## THIS IS A FIRST-PASS SCREEN, NOT A PATENTABILITY OPINION

**Say this at the top of every output. Do not drop it, do not soften it.**

> **This is a first-pass screen by a non-specialist, not a patentability
> opinion.** A patentability opinion requires a prior-art search, full claim
> construction, and the judgment of a registered patent attorney or agent. This
> screen does not do a prior-art search, does not assess what is in the art, and
> does not construct claims. It screens for the obvious disqualifiers (the
> invention is already on the market, it was publicly disclosed two years ago,
> it is plainly an abstract idea) and the obvious go-aheads (new mechanism,
> technical advance, recent conception, in-use secretly). Everything in between
> needs a prior-art search and a registered practitioner's review. This screen
> never concludes that something is "patentable" — it concludes that it "passes
> the initial screen, warrants investigation" or that it does not.

Under-flagging an invention that should have been filed is a one-way door — the
one-year US bar runs, foreign rights are lost at first public disclosure, the
competitor files first. Over-flagging just means a prior-art search that comes
back empty. Stay on the two-way door side.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level
CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest
of this paragraph — skills use practice-level context and the matter machinery
is invisible. If enabled and there is no active matter, ask: "Which matter is
this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load
the active matter's `matter.md` for matter-specific context and overrides.
Write outputs to the matter folder at
`~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`.
Never read another matter's files unless `Cross-matter context` is `on`.

Invention disclosures are particularly common candidates for **clean-team** or
**heightened** confidentiality at matter-open. Respect the matter's
confidentiality marking from `matter.md`. Invention content is inherently
sensitive — do not summarize, quote, or reference it outside privileged
channels.

---

## Load the practice profile first

**Before reading the disclosure, read
`~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`.** If it is
missing or still contains placeholders, stop and run `/ip-legal:cold-start-interview`. The
practice profile tells you:

- The company's **patent filing strategy** — offensive (building an assertion
  portfolio), defensive (filing to protect freedom to operate), hybrid, or
  licensing-revenue. This determines the strategic-value bar.
- The **technology areas of interest** — where the company files and where it
  does not. An invention that falls outside the areas of interest is often a
  decline even if the technical screen is clean.
- The **filing budget posture** — aggressive (file everything that passes the
  screen), selective (file the best few), or minimal (only what the business
  needs to protect). This shapes the output's recommendation.
- The **approval chain** — who signs off on a filing decision, and who the
  invention gets routed to if it passes the screen.

If the practice profile shows trademark-only or copyright-only (no patent
practice), this skill is the wrong tool — say so and route the user elsewhere.

---

## Workflow

### Step 1: Intake the disclosure

If the user pastes or uploads a disclosure, read it. If not, ask — in one
batch, not one at a time:

> To screen this, I need:
>
> 1. **What is the invention?** In plain language — what does it do, what makes
>    it work, what is the key idea.
> 2. **What problem does it solve?** What was broken or missing before.
> 3. **How does it differ from what existed before?** What did people do
>    previously? What does this do differently?
> 4. **Who invented it, and when?** Names and rough conception date.
> 5. **Has it been publicly disclosed?** Published, sold, offered for sale,
>    demonstrated at a conference, shown to a customer under an NDA, posted to
>    a public repo, written up in a paper, included in a product release note.
>    If yes, when and where.
> 6. **Is it in use or planned?** Shipping now? In a limited pilot? On the
>    roadmap? Still on paper?
> 7. **What technology area?** (Software, hardware, mechanical, biotech,
>    method-of-doing-business, AI/ML, etc.)

Wait for answers. Do not proceed on a half-disclosure — a screen of "a new
machine learning thing that helps users" is worse than no screen.

If the disclosure is a formal invention disclosure form (IDF) from an IPMS or
a template, extract these fields from the form and only ask for what's missing.

### Step 2: Screen against the checklist

Walk the five screens in order. Each produces a per-screen verdict:
`✓ clear`, `🟡 flagged — needs further look`, or `🔴 red flag`. Explain the
reasoning briefly; do not pad.

#### Screen 1: Novelty signals

Does the disclosure describe something new? This is not a full novelty
analysis — that requires a prior-art search. This screens the disclosure's own
description for self-evident novelty problems.

**Red flags (🔴):**
- "We just applied [known technique] to [new domain]" — e.g., "we took
  gradient boosting and applied it to predicting customer churn"
- "It's like [existing product] but for [X]" — Uber-for-dog-walking framing
- "Competitors do something similar" — if the disclosure itself says this,
  novelty is in question
- The disclosure describes a feature of an existing public product with minor
  tuning

**Green flags (✓):**
- A new **mechanism** — a new way of doing the thing, not a new application
- A new **combination** that produces an unexpected result (not just
  additive — "faster," "smaller," "cheaper" are sometimes unexpected, sometimes
  obvious)
- Solving a problem the field **had not solved** — the disclosure explains why
  the prior approaches failed and how this one doesn't

**Flagged (🟡):** anything ambiguous. Prior-art search settles it.

#### Screen 2: Obviousness flags

Would a person of ordinary skill in the art (POSA) have arrived at this
combination based on what's known? This is a screen, not a § 103 analysis —
flag for further investigation, never conclude obviousness or non-obviousness.

**Red flags (🔴) for further investigation:**
- Combining **known elements in a predictable way** — putting a known sensor
  on a known machine to measure a known thing
- **Routine optimization** — "we tuned the existing parameter from X to Y and
  got better results"
- **Design choice without functional advantage** — aesthetic, ergonomic, or
  stylistic changes that don't change how the thing works
- **Obvious to try** — one of a small number of identified solutions with a
  reasonable expectation of success

**Green flags (✓):**
- Teaching away — prior art expected the opposite result or said this approach
  wouldn't work
- Unexpected result — the combination produces something the POSA would not
  have predicted
- Long-felt need — the problem was known, and attempts to solve it had failed

#### Screen 3: Subject-matter eligibility (§ 101)

Is this an abstract idea, law of nature, or natural phenomenon? This is the
hardest screen, the most litigated, and the one most likely to require a
specialist read. Flag anything borderline for specialist review.

**Red flags (🔴) for § 101:**
- Pure **business method** without technical implementation — "a method of
  pricing widgets more efficiently"
- **Mathematical algorithm** on its own — even as dressed up in pseudocode
- **Organizing human activity** — scheduling, pairing, matching, reviewing —
  without a technical improvement
- Claim that reads as "**do [known thing] on a computer**" with no
  improvement to the computer itself
- AI/ML invention where the claim is the **function** (recommend, classify,
  predict) without the specific technical means that improves how the computer
  performs the function

**Green flags (✓) for software/AI inventions:**
- Technical improvement to the **computer itself** — new architecture, new
  training technique, new hardware/software interface, new security mechanism
- Specific technical means, not just results
- Improvement to a **technical field** (image processing, compression,
  cryptography, robotics) with the technical means described

**Anything borderline gets a 🟡 with "§ 101 — route to specialist for
Alice/Mayo analysis."** A non-specialist should not call a close § 101
question.

For **biotech / diagnostic** inventions, also flag for § 101 if the claim
recites:
- A natural correlation ("if level of X is above Y, patient has Z")
- A naturally occurring substance (isolated gene, natural product) without
  significant human modification

> **§101 is a US standard. Other patent offices are different.** The EPO's "technical effect" test (Art. 52 EPC) is materially more permissive for software and AI inventions than US §101 post-*Alice*. JPO and CNIPA also apply different standards. An invention that screens 🔴 under *Alice* may be perfectly eligible at EPO/JPO/CNIPA.
>
> When the practice profile includes non-US jurisdictions: "This §101 screen is US-only. If you file internationally, the eligibility posture may be different — particularly for software, AI/ML, and business methods, which EPO is more permissive on. Don't decline based on US §101 alone if you have EP/JP/CN filing plans."

#### Screen 4: Public disclosure / bar dates

Has the invention been disclosed, sold, offered for sale, or publicly used?
This is the most time-sensitive screen — the answer can kill patentability
absolutely, or start a clock that cannot be stopped.

Categorize the disclosure status:

**🔴 Likely barred:**
- Publicly disclosed, sold, or offered for sale **more than 12 months ago**
  in the US — 35 U.S.C. § 102(b) one-year grace period has run
- **Any** public disclosure, anywhere, before filing — absolute novelty bar in
  the EU, China, Japan, and most countries outside the US. If the business
  cares about foreign rights, this is potentially fatal even if US is still
  open.

**🟡 Clock is running:**
- Publicly disclosed within the last 12 months — US one-year clock is running,
  foreign rights may already be lost. Urgent. Confirm the disclosure date and
  route to filing immediately.

**✓ Clear:**
- No public disclosure. Confidential customer demonstrations under NDA, internal
  use, beta releases to named parties under NDA, draft papers not yet submitted
  — usually not "public" for § 102 purposes, but depends on the facts. When the
  disclosure was to a customer or external party, even under NDA, flag the
  specifics for the prosecution team to assess.

**Ask specifically about:**
- Papers submitted to journals or conferences (submission ≠ publication; but
  check the journal's policy and whether preprints were posted)
- Talks given at conferences, meetups, internal company events open to
  non-employees
- Posts to public repos, blogs, social media, or forums
- Product releases, even in limited beta
- Sales activity including quotes, RFP responses, and offers for sale
- Disclosures to investors or board members who are not under NDA

The **on-sale bar** catches offers for sale of a product embodying the
invention, not just completed sales. An RFP response describing the invention
can trigger it.

#### Screen 5: Detectability

If a competitor were to infringe this invention, could you tell? An invention
that's practiced in secret — server-side processing, back-office operations,
internal manufacturing techniques — may be better protected as a **trade
secret** than as a patent. Publishing a patent on an undetectable invention is
giving it to competitors in exchange for an asset you can never enforce.

**🔴 Low detectability flags:**
- Server-side algorithm with no observable output pattern
- Internal manufacturing process (e.g., a novel etch step in a semiconductor
  process)
- Data-pipeline or analytics methodology that happens inside a competitor's
  infrastructure
- Training data composition or training technique for an ML model — visible
  only through fine-grained probing, if at all

For these, flag for the **patent-vs-trade-secret decision**. The question is
not "is this patentable" but "should we patent it if we could." Route to
whoever in the practice profile owns trade-secret classification decisions.

**✓ High detectability:**
- Consumer product — visible in the product
- Published API, SDK, protocol — visible in network traffic or integration
  docs
- Physical mechanism in a distributed product — reverse-engineerable
- Compiled code with distinctive signatures in a distributed binary

#### Screen 6: Strategic value

Does this align with the company's patent strategy from the practice profile?
This is where the screen becomes company-specific rather than doctrinal.

Check against the profile:

- **Offensive strategy (build to assert):** is this asset assert-worthy? A
  narrow, easily designed-around patent has lower offensive value than a broad
  mechanism claim. Is the competitive landscape one where you would want to
  sue?
- **Defensive strategy (build to protect FTO):** does this cover a technology
  area where competitors are filing? A defensive filing in an area nobody
  files in is a wasted spend.
- **Licensing / revenue strategy:** is this licensable? Who would pay for it,
  and under what circumstances?

Also check:

- Is this **core** technology (part of the product's differentiation) or
  **peripheral** (incidental to a side feature)? Core is worth more.
- What is the **competitive landscape**? Patent-heavy (semiconductors,
  pharmaceuticals) — file early or lose the race. Patent-light (many
  open-source-heavy software segments) — sometimes skip entirely and spend
  the money elsewhere.
- Is the technology area on the company's list of **tech areas of interest**
  from the practice profile? If not, it is often a decline regardless of
  doctrine.

### Step 3: Assemble the invention screen memo

Format:

> **Invention screen memo — [invention title]**
>
> **Bottom line: [PURSUE / INVESTIGATE / DECLINE]**
>
> *[One sentence — the reason in plain language.]*
>
> ---
>
> ### Screen results
>
> | Screen | Verdict | Notes |
> |---|---|---|
> | Novelty signals | [✓ / 🟡 / 🔴] | [one-line reasoning] |
> | Obviousness flags | [✓ / 🟡 / 🔴] | [one-line reasoning] |
> | § 101 eligibility | [✓ / 🟡 / 🔴] | [one-line reasoning] |
> | Public disclosure / bar dates | [✓ / 🟡 / 🔴] | [one-line reasoning + dates] |
> | Detectability | [✓ / 🟡 / 🔴] | [one-line reasoning] |
> | Strategic value | [✓ / 🟡 / 🔴] | [one-line reasoning, referenced to profile] |
>
> ---
>
> ### Open questions
>
> *Things that would change the answer. The inventor, the prosecution team, or
> a specialist would need to address these before this screen converts to a
> filing decision.*
>
> - [question]
> - [question]
>
> ### Next steps (decision tree)
>
> Pick one and I'll help you build it out:
>
> 1. **Commission the prior-art search** — I'll draft the search request for
>    [outside counsel / search vendor] with the claim concepts, inventors,
>    technology classification, and any known references.
> 2. **Go back to the inventor for more facts** — I'll draft the follow-up
>    questions on [specific open items above].
> 3. **Route to outside counsel for § 101 / patent-vs-trade-secret judgment** —
>    I'll draft a transmittal summarizing what the screen found and what
>    specialist judgment is needed.
> 4. **Decline and send the standard thank-you** — I'll draft the inventor
>    thank-you and archive the disclosure with the declination reason.
> 5. **Flag for trade secret instead** — I'll draft a note to whoever owns
>    trade-secret classification explaining why a trade-secret approach is a
>    better fit.

Apply the work-product header per role. Apply the reviewer note. Keep the
deliverable clean of internal narration ("I'm using the invention-intake
skill..." etc.).

### Step 4: Recommend the bottom-line verdict

The bottom line is one of three:

- **PURSUE** — enough screens are clear (or clearly fixable) to warrant a
  prior-art search and attorney review. This is NOT "patentable" — it is
  "passes the initial screen, investigation warranted."
- **INVESTIGATE** — one or more screens flagged something that needs more
  information, specialist review, or a clarifying question back to the
  inventor before a pursue/decline decision can be made. Name the specific
  open item.
- **DECLINE** — a screen hit a fatal flag (barred by disclosure over 12
  months old with no foreign rights concern, plainly obvious, plainly abstract
  under Alice, outside the company's technology areas of interest, fundamentally
  undetectable with no trade-secret path). State the reason clearly.

A DECLINE should always be backed by a concrete reason the inventor can
understand. "Not patentable" is not an acceptable decline reason; "barred by
your paper at NeurIPS 2023 — the US one-year bar ran in December 2024" is.

## Guardrails

**Never say "patentable."** The closest you can come is "passes the initial
screen, warrants further investigation." Patentability is a conclusion a
registered practitioner reaches after a prior-art search and claim
construction.

**Never do a prior-art search in this skill.** A WebSearch for "does this
already exist" is not a prior-art search — it's a credibility check the
user can also run. If you want to sanity-check novelty, say so explicitly
("quick web check — the technique was discussed in [X] — this is not a prior-
art search, it's context for the screen") and flag it as `[web — verify]`.

**Defer on § 101 calls.** For anything borderline under Alice/Mayo, flag for
specialist review. § 101 is where practitioners routinely disagree and where
a non-specialist's confident call ages badly.

**Flag detectability before strategic value.** An undetectable invention that
would be "high strategic value" as a patent is usually higher strategic value
as a trade secret. Do not recommend PURSUE on an undetectable invention
without addressing the trade-secret alternative.

**Urgent cases get urgent flagging.** If the screen hits a within-one-year
public disclosure in the US, or any public disclosure with foreign rights in
scope, say so at the top of the memo. Bottom line, then: "**Time-sensitive —
US bar runs [date], foreign rights already at risk.**" This is the kind of
finding a lawyer needs to see in the first three seconds.

**Respect the routing.** Per the practice profile, this screen is a triage
step. The person who decides what to file is the attorney or agent responsible
for patent prosecution. The screen feeds that person; it does not replace them.

## Non-lawyer gate

If the role is **non-lawyer** (with or without attorney access), close the
memo with:

> **This is a screening tool for your disclosure, not a patentability opinion.
> The decision about whether to file — and how — belongs to a registered
> patent attorney or agent. If this screen says PURSUE or INVESTIGATE, your
> next step is not to file or draft claims; it is to share this memo (and the
> underlying disclosure) with patent counsel. If there is no counsel engaged
> yet, [contact from profile / "your professional regulator's IP referral service — state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent"] is the
> starting point.**$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/ip-clause-review', 'legal', 'ip-clause-review', '', 'ip-clause-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /ip-clause-review

Reviews the IP clauses in an agreement against the practice profile in `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Flags assignment gaps, ownership ambiguity, license-scope issues, and IP warranty/indemnity problems. Produces a memo with per-clause findings, prioritized by risk, with suggested redline language where appropriate.

## Instructions

1. **Load `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`.** If placeholders present, stop and prompt: "Run `/ip-legal:cold-start-interview` first — I need to learn your practice profile before I can review IP clauses against it."

2. **Get the agreement:** From file path, Drive link, or pasted text. If none provided, ask.

3. **Follow the workflow below.** In particular:
   - Establish the agreement type and which side the company is on for IP (granting / receiving / both). The side question is per-document, not a one-time setup answer.
   - Run the assignment gap check first if the agreement is an employment, consulting, SOW, or work-for-hire document.
   - Produce per-clause findings prioritized by risk.
   - Check cross-clause consistency, not just clause-by-clause.
   - Note jurisdiction implications (moral rights, work-for-hire, implied license, patent indemnity).

4. **Output the memo** per the template below — work-product header first, bottom line, assignment gap check, clauses by severity, consistency flags, jurisdiction note, approval routing.

5. **Respect the decision posture.** When a clause could be read to allocate IP either way, flag for attorney review and surface the factors cutting both ways. Never silently decide a subjective allocation question.

## Examples

```
/ip-legal:ip-clause-review ~/Documents/vendor-sow.pdf
/ip-legal:ip-clause-review https://docs.google.com/document/d/...
/ip-legal:ip-clause-review
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Read the IP clauses in an agreement and tell the lawyer what each one does, how it deviates from market or from the team's standard position, what the risk is, and — where appropriate — the specific redline to propose. The goal is a memo the lawyer can act on in one pass.

**The highest-stakes clauses in most agreements are IP ownership and assignment.** They are hard to fix later. A failure to get a clean assignment on an employment or consulting agreement surfaces in M&A diligence, in financing, and in litigation, sometimes years after the agreement was signed. If assignment language is weak or missing in a document that should have it, flag it loudly at the top of the memo — not buried as one line item among many.

## Precondition: load the practice profile

**Before reading the agreement, read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`.** If it is missing or still contains placeholders, stop and run `/ip-legal:cold-start-interview`. The practice profile tells you:

- The jurisdiction footprint — which affects whether moral rights waivers are enforceable, whether work-for-hire applies, whether implied assignment fills a gap, how broad license grants can be
- Who approves deviations and at what severity
- The work-product header to prepend to outputs

## Workflow

### Step 1: Orient

Read the whole agreement once, fast. Answer:

| Question | Answer |
|---|---|
| What kind of agreement is this? | Employment / consulting or SOW / vendor MSA / in-license / out-license / collaboration or JDA / settlement / acquisition or asset purchase / other |
| Which side are we on for IP? | Granting rights or receiving them / assigning IP or acquiring it / licensor or licensee |
| Who is the counterparty? | Name, and sophistication — individual, startup, BigCo |
| Is there consideration flowing for the IP specifically? | Salary, fee, royalty, upfront payment, equity, none |
| Governing law and venue | What does it say — and does our practice profile flag that jurisdiction as escalate/never? |

The side question is per-document, not a one-time setup answer. An in-house counsel reviewing an employment agreement is on the "receiving" side; reviewing an out-license the same day, on the "granting" side. The posture inverts.

If the side is ambiguous (a collaboration agreement where both parties contribute and both receive rights, a reseller agreement with flow-through IP), ask:

> Which side is [company] on for this agreement's IP? Granting rights, receiving rights, or both? If both, I'll review each direction separately.

### Step 2: Assignment gap check (highest priority)

If the agreement is an employment agreement, consulting agreement, SOW, work-for-hire contract, or anything else where the company should be receiving an assignment of the counterparty's IP in work product — check the assignment language first.

Look for:

- **Present-tense assignment** ("hereby assigns" or "hereby irrevocably assigns and agrees to assign"). A bare "agrees to assign" is a promise to assign, not an assignment, and can require a second document to perfect.
- **Scope** — does it cover all IP created in the course of engagement, or only IP related to the company's business, or only IP created using company resources? Narrow scope is a gap if work product is expected to range broadly.
- **Moral rights waiver** (for jurisdictions that recognize moral rights — EU member states, Canada, many others — the US recognizes a narrow version for visual art). If the agreement is governed by or has counterparties in a moral-rights jurisdiction, a waiver or non-assertion covenant matters.
- **Further assurances** clause — counterparty agrees to sign whatever else is needed to perfect the assignment later.
- **Pre-existing IP carveout** — what does the counterparty exclude from the assignment, and is that list specific or open-ended?

If any of the above is missing or weak, flag at the top of the memo with a 🔴 or 🟠 severity and a specific redline.

```markdown
## ⚠️ ASSIGNMENT GAP

**Section [X]** assigns IP in the work product, but: [specific issue — e.g.,
"'agrees to assign' rather than 'hereby assigns,'" or "no moral rights waiver
and governing law is France," or "no carveout list is provided and the
counterparty has pre-existing platform IP"].

**Risk:** This is the kind of gap that surfaces in M&A diligence years later.
The counterparty (or a successor) may have residual rights in work product we
thought we owned.

**Proposed redline:**
> "[specific replacement language]"

**Escalation:** Per `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`, assignment-scope gaps escalate to [approver].
```

> **Can the assignment convey AI-generated content?** *Thaler v. Perlmutter* and the Copyright Office's 2023 AI registration guidance suggest that AI-generated works without any human authorship may not be copyrightable, though the boundaries remain unclear and this area is evolving. If the contractor uses AI for substantial portions of the deliverables, the copyright status of those portions is uncertain — and an assignment clause can only convey rights that exist.
>
> Check: does the agreement have an AI-use disclosure obligation? A representation about the role of AI in the deliverables? A mechanism to identify which portions are AI-assisted vs. human-authored?
>
> If absent and AI-assisted creation is foreseeable (consulting, development, content creation, design): 🟠 High. "The assignment clause is well-drafted but there's no AI-use disclosure. The copyright status of AI-generated content is unsettled, and without a disclosure obligation you won't know which portions are affected. Add an AI-use representation and a disclosure obligation." `[review — copyright status of AI-generated works is an evolving area; verify against current Copyright Office guidance and case law]`

> **AI-assisted inventorship.** A patent filed with incorrect inventorship is unenforceable. If a consultant uses AI tools that contribute to an inventive concept, the inventorship question is unsettled and the patent is at risk. For any agreement with patent assignment provisions covering potentially patentable work product:
>
> Check: does the agreement have an AI-use representation? A process for determining inventorship where AI contributed? A disclosure obligation about AI use in the inventive process?
>
> If absent: flag. "Patent assignment without an AI-use representation. If AI tools contributed to the inventive concept, inventorship determination is complicated and an incorrectly-attributed patent is unenforceable. Add an AI-use representation and inventorship protocol."

### Step 3: Clause-by-clause review

For every IP-relevant clause, produce a block. The clauses to look for:

- **Assignment / work-for-hire** — who owns what's created under the agreement
- **Ownership of deliverables** — distinct from assignment; often states the output of the engagement
- **Improvements and derivatives** — who owns improvements to pre-existing IP, who owns derivative works
- **Background IP vs. foreground IP** — does the agreement define pre-existing IP and newly-created IP separately, and license the background IP to the extent needed?
- **License grants** — scope, exclusivity, territory, field of use, sublicensability, term, termination triggers, royalty or fee structure
- **IP warranties** — non-infringement of third-party rights, authority to grant, original work
- **IP indemnities** — scope, cap, procedure, exclusions (user modifications, combinations, unauthorized use)
- **Moral rights waiver** — jurisdiction-dependent
- **Open source representations** — representations about what OSS is and is not embedded in deliverables
- **Trademark use** — any grant or restriction on use of the other party's marks; brand guidelines; quality control for licensor
- **Confidentiality / trade secrets** — treatment of trade secret material, reasonable measures, return or destruction, post-term obligations

For each clause present, produce:

```markdown
### [Section X.X]: [Clause name]

**What it says:** [plain-English summary, one or two sentences]

**What's market (for this agreement type, this side, this jurisdiction):**
[brief reference point]

**Risk:** 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

**Why it matters:** [one or two sentences — what goes wrong for the business
if this stays as-is]

**Proposed redline (if needed):**
> "[specific replacement language]"

**Decision call:** [If uncertain whether the clause achieves the intended IP
allocation, flag for attorney review and state the factors cutting both
ways. Do not silently decide a subjective allocation question.]
```

**Severity calibration:**

| Level | Means |
|---|---|
| 🔴 Critical | Don't sign without fixing. Assignment gap in a document that should have one. Unlimited license where a narrow one was intended. Exclusive grant where non-exclusive was intended. |
| 🟠 High | Strongly push; escalate if they won't move. Ambiguous scope, missing moral rights waiver in a moral rights jurisdiction, missing further assurances, narrow indemnity. |
| 🟡 Medium | Push in first round; accept if it's the last open item. Cosmetic but imprecise language, survival periods shorter than standard. |
| 🟢 Low | Note it, don't spend capital. A stylistic deviation that doesn't change the allocation. |

### Step 4: Cross-clause consistency

IP clauses fail as a system. Check:

- **Does the license grant match the scope of what's being licensed?** (A license to "use" the deliverable is narrower than a license to "use, modify, and create derivative works.")
- **Do the warranties cover everything the grant covers?** (A warranty of non-infringement limited to patents, in a license that also covers copyrights and trade secrets, leaves gaps.)
- **Does the indemnity cover what the warranty promises?** (A warranty without indemnity is a promise without a remedy.)
- **Does termination pull the license back?** (Or does a paid-up license survive termination? Either is defensible — the question is whether it matches intent.)
- **Is the IP allocation between this agreement and any related SOW, order form, or related side letter consistent?** Flag conflicts.

### Step 5: Jurisdiction note

IP rules are jurisdiction-specific in ways that change the outcome. Flag if the agreement implicates any of these:

- **Moral rights** — EU member states, Canada, much of the civil-law world recognize moral rights (paternity, integrity) that may not be fully assignable or waivable. US recognition is narrow (VARA, for visual art).
- **Work-for-hire** — US doctrine is statutory (17 U.S.C. § 101) and only applies to enumerated categories for independent contractors. UK implies assignment in the employment context but not always for contractors. Civil-law jurisdictions handle this differently again.
- **Implied license** — common-law jurisdictions may read in an implied license where the written grant is silent. Civil-law jurisdictions tend not to.
- **Patent indemnity exclusions** — combinations, modifications, and user supply of accused features are standard US exclusions; the interaction with EU patent and UPC is still developing.

State what jurisdiction the agreement is governed by, and whether the practice profile flags that jurisdiction as standard, escalate, or never.

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

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`).

This memo and the underlying agreement may be privileged, confidential, or both. The output inherits that status from the source. Distribute only within the privilege circle; mark and store it where privileged materials live; strip the work-product header before any external delivery.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a rule the memo needs (enforceability of a moral rights waiver in a given jurisdiction, scope of an implied license, standard for an IP warranty survival period), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / jurisdiction]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Where the memo cites a statute, regulation, case, or treatise, tag the citation: `[Westlaw]`, `[statute / regulator site]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations from the counterparty draft or house files. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# IP Clause Review: [Counterparty] [Agreement Type]

**Reviewed:** [date]
**Our side for IP:** [Granting / Receiving / Both]
**Governing law:** [jurisdiction]

---

## Bottom line

[Two sentences. Can the IP allocation stand? What has to change first?]

**Issues:** [N]🔴 [N]🟠 [N]🟡 [N]🟢

**Approval needed from:** [name, per practice profile]

---

## Assignment gap check

[✅ Clear | ⚠️ Gap present — see above]

---

## Clauses by severity

[All clause blocks from Step 3, grouped Critical → Low]

---

## Cross-clause consistency

[Flags from Step 4]

---

## Jurisdiction note

[Flags from Step 5]

---

## Approval routing

[From practice profile — who approves, what triggers automatic escalation]
```

## Decision posture

When a clause could be read to allocate IP either way, or when it is unclear whether the drafter's chosen words achieve the stated intent, **flag it for attorney review and surface the factors cutting both ways**. Do not silently decide a subjective allocation question. An unresolved IP allocation that gets signed is a one-way door — the error surfaces in diligence, financing, or litigation. Flagging an ambiguous clause that turns out to be fine is a two-way door.

## Quality checks before delivering

- [ ] Practice profile was loaded and the jurisdiction note reflects what's there
- [ ] Assignment gap checked first (for employment/consulting/SOW/WFH)
- [ ] Every 🔴 and 🟠 issue has specific replacement language
- [ ] Cross-clause consistency checked, not just clause-by-clause
- [ ] Source tags applied to citations; no stripped `verify` tags
- [ ] Approver named per practice profile, not "escalate to legal"
- [ ] Output marked with the work-product header

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/ip-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/ip-legal:matter-workspace list` — list matters with status and active flag
- `/ip-legal:matter-workspace switch <slug>` — set the active matter
- `/ip-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/_archived/`, never delete)
- `/ip-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/ip-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/ip-legal:matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Follow the subcommand logic below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; instead it explains the disabled state and suggests `/ip-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/ip-legal/
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

Slugs are lowercase with hyphens. Examples: `acme-trademark-2026`, `zenith-dmca`, `novacorp-fto`.

## Active matter is in the practice CLAUDE.md

The `Active matter:` line under `## Matter workspaces` in the practice-level CLAUDE.md is the single source of truth. Switching a matter edits that line. No separate state file.

## Subcommand logic

### `new <slug>`

1. Confirm slug is not already present in `matters/<slug>/` or `matters/_archived/<slug>/`. If reused, ask the user to pick a different slug.
2. Run the intake interview:
   - **Client** (the party we represent, or the internal business unit if in-house)
   - **Counterparty** (the other side — may be multiple; may be "unknown third-party infringer" for watch-triggered matters)
   - **Matter type** (read the plugin's practice profile for typical categories; for ip-legal: trademark clearance | trademark enforcement | DMCA | patent FTO | patent infringement | IP clause review | OSS compliance | portfolio maintenance | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings; clean-team common in patent FTO work)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice posture** (e.g., "client wants aggressive posture for this mark only", "counterparty is a strategic partner — measured tone only", "inventor unavailable — don't surface for interview")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/ip-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/ip-legal:matter-workspace new <slug>`.
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

[trademark clearance | trademark enforcement | DMCA | patent FTO | patent infringement | IP clause review | OSS compliance | portfolio maintenance | other — with one-line rationale]

## Key facts

[2–5 sentences. What this matter is about. Who the stakeholders are. What's at stake. What makes it different from the default posture.]

## Matter-specific overrides

*Any deviation from the practice-level posture that applies to this matter and only this matter.*

- [e.g., "Enforcement posture: measured here even though house default is aggressive — counterparty is a key channel partner."]
- [e.g., "Approval for assertion: extra sign-off from marketing required before any letter goes out."]
- [e.g., "Clean-team: matter files not readable even with cross-matter context on."]

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
[Any initial context worth preserving beyond matter.md — e.g., "Opened in response to watch-service hit on `APEXLEAF` in class 25."]
```

## Cross-matter context

The practice-level CLAUDE.md has a `Cross-matter context:` flag. When it's `off` (the default), a skill working in matter A **never reads** files in `matters/B/` for any other `B`. Period. This is the confidentiality guarantee the setting exists to provide.

When it's `on`, a skill may read files across matter folders only when the user explicitly asks it to (e.g., "show me every enforcement letter we've sent on this mark across matters"). Even when `on`, the default is to load only the active matter unless the user asks for a cross-matter view.

## What this skill does not do

- **Run a conflicts check.** Conflicts are the practitioner's/firm's job; the intake captures what the user declares.
- **Enforce retention.** Closing archives a matter; it does not delete. Retention policy is out of scope.
- **Auto-route outputs.** The substantive skill decides where to write; this skill tells it *which folder* is active, not what to put in it.
- **Decide whether cross-matter is appropriate.** It reads the flag and obeys.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/oss-review', 'legal', 'oss-review', '', 'oss-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /oss-review

Runs an open source license compliance check against the practice profile in `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. Classifies dependencies by license family, maps obligations to the deployment model, flags license-unknown and non-OSI-posing-as-OSS packages, and recommends actions — comply, replace, remove, seek legal review, seek commercial license.

## Instructions

1. **Load `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`.** If placeholders present, stop and prompt: "Run `/ip-legal:cold-start-interview` first — I need to learn your practice profile (and OSS policy, if any) before I can review." If the practice profile points at an uploaded OSS policy, read that too — it is the source of truth for accepted / review / banned licenses on this team.

2. **Establish the scope:** a dependency list (package.json, requirements.txt, go.mod, Gemfile, Cargo.toml, pom.xml, SBOM), a single library, or outbound code the team is preparing to open-source. If the user passed a path, infer from the file; otherwise ask.

3. **Establish the deployment model** before classifying obligations — SaaS, distributed binary, internal only, or embedded. The same dependency list triggers different obligations depending on this.

4. **Follow the workflow below.** In particular:
   - Read the actual license text, not just metadata — LICENSE files can be wrong, package metadata can be stale.
   - Classify each package into permissive / weak copyleft / strong copyleft / public domain / non-OSI / unknown.
   - Flag license-unknown as "needs review," not permissive by default.
   - Flag non-OSI source-available licenses (SSPL, BUSL, Commons Clause, Elastic License, fair-source) — these are not open source.
   - For outbound code, check that the chosen outbound license is compatible with every embedded dependency.

5. **Output the memo** per the template below — work-product header first, bottom line, top-of-memo flags, per-package blocks grouped by severity, jurisdiction note, outbound check (if applicable), approval routing.

6. **Respect the decision posture.** When a copyleft-trigger analysis turns on a contested question (AGPL's "interacts over a network," GPL-3.0's "conveying," LGPL linking scope), flag for attorney review and surface the factors cutting both ways. Anything flagged as strong copyleft or license-unknown goes to an attorney before the dependency ships or the code is released.

## Examples

```
/ip-legal:oss-review ~/code/my-project/package.json
/ip-legal:oss-review ~/code/my-project/requirements.txt
/ip-legal:oss-review redis
/ip-legal:oss-review ~/code/my-project  # repo root — scan all manifests
```

---

## Works better connected

OSS clearance requests usually come in via a ticketing system. Connected to
Jira, Linear, or Asana, this skill can: monitor incoming OSS requests, respond
with guidance directly in the ticket (flagging incomplete info, asking for the
repo link, returning the license-family classification), and track clearance
status across requests.

Without a connector, paste the ticket or describe the request and I'll handle
it one at a time. See `CONNECTORS.md` at the repo root for how to add a
ticketing connector.

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Tell the user what licenses are in their dependency tree, what obligations those licenses trigger given how the code will be deployed, and what to do about each one. The output is a memo the lawyer (or the engineer with attorney access) can act on — comply, replace, remove, seek legal review, seek commercial license.

**This is a first-pass classification.** Copyleft analysis depends on the deployment model, the degree of linking, the jurisdiction, and sometimes on legal questions that have not been tested in court (notably AGPL's "interacts over a network," GPL-3.0's patent clause). For anything that classifies as strong copyleft or license-unknown, an attorney evaluates before the dependency ships or the code is released. The skill reports what it found; the lawyer decides what to do.

## Precondition: load the practice profile

**Before scanning dependencies, read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`.** If it is missing or still contains placeholders, stop and run `/ip-legal:cold-start-interview`. The practice profile tells you:

- Who owns OSS review on this team (often engineering with legal sign-off)
- Escalation routing for copyleft obligations
- The work-product header to prepend

If the practice profile has an OSS policy uploaded, read that too — it is the source of truth for which licenses the team accepts, which trigger review, and which are banned.

## Workflow

### Step 1: What's the scope?

Ask (or infer from what the user provided):

> What are we reviewing?
>
> 1. **A dependency list** — `package.json`, `requirements.txt`, `go.mod`, `Gemfile`, `Cargo.toml`, `pom.xml`, an SBOM (SPDX / CycloneDX), a lockfile
> 2. **A single library** — one specific package you're considering adding
> 3. **Our own code** — we're planning to open-source this and need to check what's embedded

The analysis path differs:

- Dependency list → classify every entry, roll up obligations
- Single library → classify one package and walk its transitive dependencies if available
- Outbound code → check what's embedded (direct and transitive), check whether chosen outbound license is compatible with all embedded licenses, check that LICENSE / NOTICE files are correct

### Step 2: What's the deployment model?

This is the single most important input after the license list — the same library carries different obligations depending on how the software is delivered. Ask:

> How will this be deployed?
>
> 1. **SaaS / hosted service** — users access over a network; nothing ships to the user
> 2. **Distributed binary** — we ship compiled code to users (desktop app, mobile app, on-prem server, CLI tool)
> 3. **Internal only** — used only inside the company, not distributed outside
> 4. **Embedded / firmware** — shipped in hardware or as closed-system firmware

| Deployment | Licenses that materially matter |
|---|---|
| SaaS | AGPL (network-trigger), permissive attribution in any UI, SSPL/BUSL/Elastic if repurposing as competing service |
| Distributed binary | GPL, LGPL, MPL, EPL (all trigger on distribution), permissive attribution |
| Internal only | Most copyleft does not trigger — no distribution. Permissive attribution still good hygiene. AGPL still triggers if users outside the company interact over the network. |
| Embedded / firmware | GPL is especially hard to comply with here (source disclosure + reproducible build + installation information in some cases). Plan for this before shipping, not after. |

Flag the deployment model in the output memo — the same dependency list reviewed against "SaaS" vs. "distributed binary" yields different obligations.

### Step 3: Classify each dependency

For every package, determine the license. Read the actual license text, not just the metadata — LICENSE files can be wrong (the file says MIT but the headers say GPL; the README claims Apache but there's no license file), and package manager metadata can be stale.

Classify into:

| Bucket | Examples | Key obligations |
|---|---|---|
| **Permissive** | MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, Zlib, Unlicense | Attribution, preserve license text, Apache-2.0 adds patent grant + NOTICE requirement |
| **Weak copyleft** | LGPL-2.1, LGPL-3.0, MPL-2.0, EPL-1.0, EPL-2.0, CDDL | File-level or library-level source disclosure; linking rules vary |
| **Strong copyleft** | GPL-2.0, GPL-3.0, AGPL-3.0, OSL, EUPL (depending on version) | Broad source disclosure; AGPL extends to network use |
| **Public domain / dedication** | CC0, Unlicense, WTFPL | Typically no obligations, but some are contested in jurisdictions that don't recognize dedication to public domain |
| **Non-OSI source-available** | SSPL, BUSL, Commons Clause, Elastic License, Confluent Community, fair-source family | Not open source — restrict commercial use, competing-service use, or both. Read the specific license. |
| **Other / custom / unknown** | vendor-specific, proprietary, missing license file, license conflict between file and headers | Stop — do not treat as permissive by default |

Flag:

- **Dual-licensed packages** — which license are we using? The choice may change obligations.
- **Deprecated packages** — the package is no longer maintained; is there a supported replacement?
- **Packages with a copyleft dependency in their own tree** — the top-level license is permissive but a transitive dependency is copyleft.
- **Packages that changed license recently** — Redis, MongoDB, Elastic, HashiCorp — make sure the version pinned is under the license you think it is.

### Step 4: Map obligations to the deployment model

For each classified dependency, state what the deployment model triggers:

```markdown
### [package@version] — [License]

**Classification:** [Permissive / Weak copyleft / Strong copyleft / Public domain / Non-OSI / Unknown]

**Obligations for our deployment ([SaaS / binary / internal / embedded]):**

- [ ] [Specific obligation — e.g., "Include attribution in a NOTICES file shipped with the app"]
- [ ] [e.g., "If we modify and distribute, publish source of our modifications"]
- [ ] [e.g., "AGPL network trigger — if users access our modified version over a network, source must be offered to them"]

**Risk:** 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

**Recommendation:** [Comply with obligations | Replace with [alternative] | Remove | Attorney review before shipping | Seek commercial license from [vendor]]
```

> **How is the copyleft dependency consumed?** The linking relationship determines whether copyleft actually triggers. Ask or determine:
> - **Static linking / compilation together:** The works are combined into one binary. Strong signal that copyleft triggers (LGPL "work based on the Library," GPL derivative work).
> - **Dynamic linking / shared library:** The works remain separable at runtime. LGPL explicitly permits this ("work that uses the Library"). GPL's position is contested (FSF says derivative, others disagree).
> - **Header inclusion / inline functions:** Can create a derivative work depending on how much is included.
> - **Subprocess / IPC:** Separate processes communicating over well-defined interfaces. Generally not derivative.
> - **Network API call:** For most licenses, no. For **AGPL**, the network-interaction clause means serving the software over a network IS distribution. In a microservices architecture, an AGPL component behind an API still triggers.
> - **File-scope copyleft (MPL):** Only the modified files carry copyleft, not the whole work. Check whether any copyleft files were modified.
>
> **The severity rating depends on this.** "LGPL — weak copyleft, linking rules vary" without the linking analysis is the answer that gets an engineer sued. Static-linked LGPL in a proprietary product is 🔴 Critical. Dynamic-linked LGPL is 🟢 Low. Same license, opposite rating.

**Severity calibration:**

| Level | Means |
|---|---|
| 🔴 Critical | Strong copyleft in a deployment that triggers it (e.g., GPL in a distributed binary, AGPL in a SaaS). Non-OSI license that the business model actually conflicts with (e.g., SSPL while we're building a managed service). License cannot be determined and the package is load-bearing. |
| 🟠 High | Weak copyleft with obligations the team hasn't set up for (file-level disclosure, NOTICE requirements). Dual-licensed where the chosen license is ambiguous. License file says one thing, headers say another. |
| 🟡 Medium | Permissive with attribution requirements that haven't been wired into the build (missing NOTICES file, missing LICENSE in distribution). Transitive copyleft in a position that may or may not trigger, depending on how the library is consumed. |
| 🟢 Low | Permissive with obligations already satisfied. Copyleft in a deployment model that doesn't trigger it (e.g., GPL library used internally only, with no redistribution). |

### Step 5: Flag failure modes

Call out any of the following in a top-of-memo section:

- **License unknown** — classify as "needs review," not permissive. An unclassified dependency should stop a ship decision, not slip through.
- **License file conflicts with file headers** — read both and report the conflict.
- **Incompatible combinations** — GPL-2.0 only + Apache-2.0 historically a known incompatibility; check MPL / EPL / GPL combinations carefully.
- **Non-OSI licenses posing as open source** — SSPL, BUSL, Commons Clause, Elastic License, Confluent Community. Read the license; don't rely on GitHub's "open source" badge.
- **License changes** — if a prior version was permissive and the current version is source-available, the pin matters.

### Step 6: Outbound check (if reviewing our own code before open-sourcing)

If the user is preparing to open-source code:

- Confirm the chosen outbound license is compatible with every embedded dependency's license (e.g., you cannot release under MIT if you've embedded GPL code — the combined work must be GPL)
- Confirm LICENSE file is present and correct
- Confirm NOTICE file is present and lists required attributions (Apache-2.0 and others)
- Confirm third-party license texts are bundled where required
- Confirm no proprietary or confidential code, no customer data, no embedded credentials in the repo history
- Confirm trademark and brand policy for any project name (separate from the copyright license)

### Step 7: Assemble the memo

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → `## Outputs` (differs by user role — see `## Who's using this`).

This memo and any dependency list reviewed may be privileged, confidential, or both. The output inherits that status from the source. Distribute only within the privilege circle; strip the work-product header before any external delivery (including before attaching the memo to an engineering ticket outside the privilege circle).

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a rule the memo needs (enforceability of AGPL's network trigger in a given jurisdiction, scope of GPL-3.0's patent grant, latest license text for a recently-relicensed package), report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [rule / license / jurisdiction]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Where the memo cites a license text, a court decision interpreting a license, or guidance from a steward (FSF, OSI, SPDX, SFLC), tag the citation: `[OSI]`, `[SPDX]`, `[FSF]`, `[SFC/SFLC]`, `[Westlaw]`, or the MCP tool name for citations retrieved from a connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for license text read directly from the repo. Citations tagged `verify` carry higher fabrication risk. Never strip or collapse the tags.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# OSS Review: [Project / Dependency List / Package]

**Reviewed:** [date]
**Scope:** [Dependency list / Single library / Outbound code]
**Deployment model:** [SaaS / Binary / Internal / Embedded]

---

## Bottom line

[Two sentences. Can this ship? What has to happen first?]

**Packages reviewed:** [N]
**By classification:** [N permissive, N weak copyleft, N strong copyleft, N public domain, N non-OSI, N unknown]
**Issues:** [N]🔴 [N]🟠 [N]🟡 [N]🟢

**Approval needed from:** [name, per practice profile]

---

## Top-of-memo flags

[License-unknown list, license-conflict list, non-OSI-posing-as-OSS list, incompatible combinations]

---

## By package

[Blocks from Step 4, grouped by severity]

---

## Jurisdiction note

OSS license enforceability varies — AGPL's network trigger has not been broadly tested in court; GPL-3.0's patent clause reads differently under US vs. EU patent law; dedications to public domain are not universally recognized. State the governing-law choice for any downstream distribution (e.g., vendor agreements incorporating the code) and flag jurisdictions the practice profile marks as escalate.

---

## Outbound check (if applicable)

[From Step 6]

---

## Approval routing

[From practice profile — who approves, what triggers automatic escalation]
```

## Decision posture

When a license cannot be confidently classified, flag it as **"needs review"** — do not call it permissive. Under-classifying license risk is a one-way door: a ship decision made on a permissive-by-default assumption becomes a source-disclosure obligation or an injunction months later. Over-flagging is a two-way door — the attorney narrows the list in review.

Likewise, when the copyleft-trigger analysis turns on a contested question (AGPL's "interacts over a network," GPL-3.0's "conveying," the scope of LGPL linking), flag for attorney review and surface the factors cutting both ways.

## Quality checks before delivering

- [ ] Practice profile and any OSS policy were loaded
- [ ] Deployment model was established before classifying obligations
- [ ] Every dependency has a classification, including transitives where available
- [ ] License-unknown packages are flagged, not defaulted to permissive
- [ ] License text was read (not just metadata) for any copyleft or non-OSI finding
- [ ] Source tags applied to citations; no stripped `verify` tags
- [ ] Approver named per practice profile
- [ ] Output marked with the work-product header

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

If the scan surfaced more than ~10 packages, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer to what's useful here — counts by license family (permissive / weak copyleft / strong copyleft / AGPL / proprietary / unknown), risk distribution, and a table of findings with severity and package version.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/portfolio', 'legal', 'portfolio', '', 'portfolio', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /portfolio

Surfaces what's renewing, adds assets, records filings, and audits the register.

## Instructions

1. **Follow the workflow below** and read
   `~/.claude/plugins/config/claude-for-legal/ip-legal/portfolio.yaml`.

2. **Default (no args):** equivalent to `--report` — show deadlines in the
   next 90 days grouped by urgency (🔴 lapsed/grace, ⏰ due within window,
   🟡 upcoming, 🌐 agent-managed, ❓ unknown).

3. **`--report [--days N]`:** Mode 2. Change the window with `--days`
   (30 / 60 / 90 / 180 typical). Always prepend the work-product header
   per CLAUDE.md → Outputs. Always close with the verification caveat.

4. **`--add`:** Mode 3. Walk through a new asset interactively — type,
   jurisdiction, number, dates, owner, business owner. Capture a custom
   rule if the jurisdiction isn't built in.

5. **`--update`:** Mode 4. Record that a maintenance filing or fee payment
   was made, sync with the IP management system, or change an asset's
   status. Enforce the consequential-action gate before setting any
   deadline to `filed`.

6. **`--audit`:** Mode 5. Broader health check — deadline hygiene,
   registration gaps, use-in-commerce questions on §8-approaching marks,
   owner inconsistencies, expiration horizon, unwatched marks.

7. **If the register is empty and an IP management system is connected:**
   Offer Mode 1 — pull the portfolio from the system of record and
   initialise the register.

8. **Guardrail reminder:** Computed deadlines are reference only. Every
   output closes with a line directing verification against the USPTO
   TSDR, WIPO, or relevant registry before filing or paying. A
   docketed-but-wrong deadline creates false confidence; do not let the
   user treat this as the system of record unless the IP management
   system is sync-integrated.

## Examples

```
/ip-legal:portfolio
```

```
/ip-legal:portfolio --report --days 180
```

```
/ip-legal:portfolio --add
```

```
/ip-legal:portfolio --update
```

```
/ip-legal:portfolio --audit
```

---

## Works better connected

This skill tracks deadlines from what you tell it. It works much better
connected to:

- **An IP management system (IPMS) via MCP** — Anaqua, Clarivate IPfolio,
  AppColl, Patrix, Alt Legal, FoundationIP. A connected IPMS gives you the
  full docket, maintenance fee schedules, and incoming correspondence in one
  place, instead of the register being whatever the lawyer remembers to
  paste. Ask your IPMS vendor if they have an MCP connector, or see
  `CONNECTORS.md` at the repo root for how to get one added.
- **USPTO directly via customer number** — pulls status, deadlines, and
  correspondence for your whole portfolio rather than one application at a
  time. Not currently available as an MCP; on the wish list in
  `CONNECTORS.md`.

Without either, paste your docket or upload a spreadsheet and I'll track from
there.

## Purpose

A trademark registration that isn't renewed on time can be cancelled. A patent
without its maintenance fee paid lapses. A domain that expires can be sniped
within the hour. All of this is avoidable, and all of it depends on one thing:
the right deadline is on someone's calendar, tied to the right registration
number, in the right jurisdiction.

This skill maintains that calendar.

## Important: deadline reference caveat

> The deadline rules this skill applies reflect publicly available requirements
> as of the skill's build date. IP office requirements, grace periods, fee
> structures, and maintenance schedules change. **Always confirm computed
> deadlines against the USPTO TSDR / Patent Center, WIPO Madrid Monitor /
> Patentscope, EUIPO eSearch, UKIPO online records, or the relevant national
> registry before acting.** If you use Anaqua, CPA Global, Clarivate, Alt Legal,
> or another IP management system, their docket is authoritative for your
> assets — use this tracker to organize and surface their data, not to replace
> it.
>
> A docketed-but-wrong deadline is worse than an undocketed one: it creates
> false confidence. "No deadline soon" outputs especially deserve a second
> look before you rely on them.

## Jurisdiction and type assumptions

Maintenance mechanics vary by jurisdiction and asset type:

- **US trademarks:** §8 Declaration of Use between 5th and 6th anniversary of
  registration (or §71 for Madrid designations), then combined §8/§9 renewal
  at 10 years and every 10 years thereafter. §15 Incontestability available
  after 5 years of continuous use. 6-month grace period with surcharge for §8
  and §9; no grace for the underlying use itself.
- **Madrid International trademarks:** 10-year registration term renewable at
  WIPO; individual designated countries may have local use or declaration
  requirements (e.g., US §71).
- **EUIPO trademarks:** 10-year renewal; 6-month grace with surcharge.
- **US utility patents:** Maintenance fees due at 3.5, 7.5, and 11.5 years
  from grant. 6-month grace window with surcharge; after that, potential
  revival by petition if lapse was unintentional.
- **US design patents:** No maintenance fees — 15-year term from grant for
  applications filed on or after May 13, 2015 (14 years if earlier). No action
  required mid-term.
- **EPO / national patents:** Annuities typically due annually from filing or
  from national phase entry. National rules vary — confirm per jurisdiction.
- **US copyright:** No maintenance for works created 1978 or later.
  Pre-1978 works may have had renewal obligations; flag for attorney review
  if the asset pre-dates 1964 (rarely in scope for modern portfolios).
- **Domains:** Annual or multi-year renewal per registrar; typical 30-day
  grace then redemption period (~30 days at high fee) then drop.

If the portfolio includes assets in jurisdictions not listed above, capture
the maintenance mechanic in the register's `custom_rules` block and the
report will surface them as `agent_managed` — confirm status with the
foreign associate rather than computing a date this skill doesn't understand.

---

## The register

Lives at `~/.claude/plugins/config/claude-for-legal/ip-legal/portfolio.yaml`.
Structure:

```yaml
# IP Portfolio Register
# Generated: [date]
# Last updated: [date]
# Disclaimer: computed deadlines are reference only — confirm with USPTO/WIPO/
# relevant registry or the IP management system of record before acting.

metadata:
  company: "[Company Name]"
  generated: "[date]"
  last_updated: "[date]"
  last_audit: "[date or null]"
  source_system: "[Anaqua / CPA Global / manual / none]"

custom_rules:   # non-built-in jurisdictions captured manually
  []

assets:
  - id: "TM-US-001"
    type: "trademark"                          # trademark / patent / copyright / design / domain
    jurisdiction: "US"
    mark_or_title: "[Mark or title]"
    owner: "[Record owner — registered entity name]"
    status: "registered"                       # pending / registered / lapsed / abandoned / cancelled
    application_number: "[number or null]"
    registration_number: "[number or null]"
    classes: ["9", "42"]                       # Nice classes for TM; CPC/IPC for patents; null otherwise
    filing_date: "[YYYY-MM-DD or null]"
    registration_date: "[YYYY-MM-DD or null]"
    priority_date: "[YYYY-MM-DD or null]"
    grant_date: "[YYYY-MM-DD or null]"         # patents
    next_deadlines:                            # computed; refreshed on --report and --audit
      - type: "§8 Declaration of Use"
        due_date: "[YYYY-MM-DD]"
        grace_end: "[YYYY-MM-DD or null]"
        basis: "5th-6th anniversary of registration"
        action: "File §8 Declaration of Use (or excusable nonuse)"
        status: "upcoming"                     # upcoming / due_soon / overdue / grace / filed
    use_in_commerce: true                      # TM only — drives §8 analysis
    agent_managed: false                       # true for foreign associate / outside counsel managed
    local_agent: null
    docket_id: "[IP-mgmt-system ID or null]"
    outside_counsel: "[firm or null]"
    business_owner: "[email or team]"
    notes: ""

  - id: "PAT-US-001"
    type: "patent"
    jurisdiction: "US"
    mark_or_title: "[Invention title]"
    owner: "[Owner]"
    status: "granted"
    application_number: "[number]"
    registration_number: "[patent number]"
    filing_date: "[YYYY-MM-DD]"
    grant_date: "[YYYY-MM-DD]"
    priority_date: "[YYYY-MM-DD or null]"
    expiration_date: "[YYYY-MM-DD]"            # 20 years from earliest non-provisional filing
    next_deadlines:
      - type: "3.5-year maintenance fee"
        due_date: "[YYYY-MM-DD]"
        grace_end: "[YYYY-MM-DD]"
        basis: "3.5 years from grant"
        action: "Pay maintenance fee (small/micro entity if applicable)"
        status: "upcoming"
    claims_count: 20
    entity_size: "large"                       # large / small / micro (drives USPTO fees)
    docket_id: null
    outside_counsel: null
    business_owner: null
    notes: ""
```

Status values for `next_deadlines`:
- `upcoming` — more than 90 days out
- `due_soon` — due within 90 days, not yet filed
- `overdue` — past the primary due date, within grace window (if any)
- `grace` — in the grace period (explicit flag — carries surcharge)
- `lapsed` — past grace with no action; asset effectively lost unless revivable
- `filed` — action completed this cycle

---

## Mode 1: Initialise

Run when no register exists, or with `--rebuild`.

### Step 1: Determine the source

Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`:
- **IP management system connected** (Anaqua, CPA Global, etc.): pull the portfolio via its integration. The IP system is the authoritative source; this register mirrors it and adds no deadlines the system doesn't already have.
- **No IP management system, but spreadsheet / export available:** ask the user to share the export. Import what's present; flag any asset missing a registration or grant date as `unknown` for deadline computation.
- **Nothing at hand:** walk through assets interactively — type, jurisdiction, number, key dates, owner.

### Step 2: For each asset, compute deadlines

Apply the rules at the top of this file. Populate `next_deadlines` with the
two or three closest upcoming items — further-out deadlines (10-year renewals
decades away) are computed on demand during reports rather than stored
speculatively.

**For assets the skill cannot confidently schedule:**
- Unknown jurisdiction rules → add a stub under `custom_rules` and flag the
  asset `agent_managed: true` with a TODO to confirm with the foreign associate.
- Missing dates needed for computation (no grant date for a patent, no
  registration date for a TM) → set `next_deadlines` empty with a note in
  `notes`, and list the asset as `unknown` in the initialisation summary.

### Step 3: Write the register

Generate `portfolio.yaml` at the config path. Show a summary:

```
Portfolio register initialised.

Assets: [N]
  Trademarks: [N]   ([N registered] / [N pending])
  Patents:    [N]   ([N granted] / [N pending])
  Copyrights: [N]
  Designs:    [N]
  Domains:    [N]

Deadlines computed: [N]
Agent-managed / jurisdiction TBC: [N] — confirm with foreign associates
Unknown (missing key dates): [N] — fill in before relying on reports

Run /ip-legal:portfolio --report to see what's due.
```

---

## Mode 2: Report

```
/ip-legal:portfolio --report [--days 30|60|90|180]
```

Default window: 90 days. Refresh computed deadlines for every asset before
producing the report — don't rely on stored dates alone.

Output (prepend work-product header per `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → Outputs):

```
IP PORTFOLIO DEADLINE REPORT — [date]
[Company Name] — window: next [N] days

🔴 LAPSED / IN GRACE ([N])
  [Asset ID] / [Jurisdiction] / [Type] / [Mark or title]
    [Action] — original due [date], grace ends [date]
    Status: [grace / lapsed]

⏰ DUE WITHIN [N] DAYS ([N])
  [Asset ID] / [Jurisdiction] / [Type] / [Mark or title]
    [Action] — due [date]
    Basis: [e.g., "5th-6th anniversary of registration"]
    [Agent: firm / docket: id — if present]

🟡 UPCOMING (next window beyond 30 days, within [N] days)
  [list]

🌐 AGENT-MANAGED ([N])
  [Asset ID] / [Jurisdiction] — managed by [local agent]; confirm directly
  [Asset ID] / [Jurisdiction] — no local agent recorded; add with --update

❓ UNKNOWN ([N])
  [Asset ID] — missing [field]; cannot compute deadline
  Confirm with [IP management system / USPTO TSDR / relevant registry] before relying on this report.

SUMMARY
  Total assets tracked: [N]
  Deadlines in window: [N]
  Last audit: [date]
```

Close the report with the caveat line: *"Computed from portfolio register. Verify each deadline against the USPTO/WIPO/registry of record before filing or paying."*

If the report lists more than ~10 assets, or any time the user asks: offer the dashboard (see CLAUDE.md `## Outputs → Dashboard offer for data-heavy outputs`). Shape the offer for this output — counts by registration status (live / in grace / lapsed / pending), a deadline timeline, and a sortable portfolio table with jurisdiction, type, and next-action date.

---

## Mode 3: Add

```
/ip-legal:portfolio --add
```

Interactive add of a single asset. Ask for:
1. Type (trademark / patent / copyright / design / domain)
2. Jurisdiction
3. Mark or title / invention name
4. Owner (record owner — matters for §8 filings and assignments)
5. Key dates (per type: filing, registration, grant, priority, expiration)
6. Number(s)
7. Classes / claims count
8. Source — is this being tracked in the IP management system under a docket ID?
9. Outside counsel / foreign associate, if any
10. Business owner (who does this matter to — product line, brand manager)

After capture:
- Compute next deadlines per the rules at the top of this file.
- If jurisdiction rules aren't built in, walk through the `custom_rules` capture flow (see below).
- Append to `assets:` in `portfolio.yaml`.

### Custom rules capture

When a jurisdiction isn't in the built-in list:

> I don't have maintenance rules for [Jurisdiction] / [Asset type] built in.
> Let me capture them so we can track this going forward.
>
> 1. What maintenance events apply? (Renewal every N years? Annuities annually?
>    Declarations of use? Something else?)
> 2. What triggers the due date — filing date, registration date, grant date,
>    national phase entry, anniversary of something else?
> 3. Is there a grace period? At what cost?
> 4. Is there a foreign associate or local agent managing this?

Store under `custom_rules:` and apply to future assets in that jurisdiction.

---

## Mode 4: Update

```
/ip-legal:portfolio --update
```

### Consequential-action gate

**Before recording that a maintenance filing or fee payment was made:** Read
`## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Recording a §8 declaration, a §9 renewal, a patent maintenance fee payment,
> or an international annuity as "filed" has consequences. If the record is
> wrong — missed due date, wrong entity size, wrong specimen of use — the
> deadline doesn't move, and the asset can still lapse. Have you confirmed
> this with the attorney or foreign associate who actually made the filing
> (or with the USPTO TSDR / WIPO Madrid Monitor / relevant registry)? If yes,
> proceed. If no:
>
> - Do not record as filed yet.
> - Here is what to bring to the attorney: asset ID, jurisdiction, deadline
>   type, what the IP management system shows, what you believe was filed and
>   when, and the source of that belief.
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service
> is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not set a deadline's `status` to `filed` past this gate without an
explicit yes. Status refresh, report generation, and upcoming-deadline
surfacing do not require the gate.

### Sub-modes

**Manual update:** "We filed the §8 for TM-US-001 on March 4, specimen
attached." Update the matching deadline: `status: filed`, `filed_date`,
and compute the next deadline in its lifecycle (for §8 that's the §9
renewal 10 years out).

**From IP management system sync:** If Anaqua / CPA Global / similar is
connected, pull the latest docket and reconcile. Flag mismatches between
the register and the system of record — the system of record wins; update
the register to match and surface anything the register had that the
system doesn't.

**Status change:** "Mark TM-US-004 as abandoned." Update `status`, clear
`next_deadlines`, note the date abandoned.

---

## Mode 5: Audit

```
/ip-legal:portfolio --audit
```

Broader health check beyond this month's deadlines:

**Deadline hygiene**
- Any deadlines in `grace` status right now? (In progress but surcharge-costing.)
- Any `lapsed` assets that aren't marked `abandoned` or `cancelled`? Either
  revive or update status.
- Any assets with no `next_deadlines` computed? Either missing data or a
  jurisdiction the skill doesn't know.

**Registration gaps**
- Trademark applications filed more than 18 months ago still `pending`?
  Flag for status check at the office — may need response to an action.
- Patents filed more than 4 years ago still `pending`? Flag for prosecution
  check.

**Use-in-commerce (TM only)**
- §8 approaching on a mark flagged `use_in_commerce: false` or uncertain?
  The §8 requires use; mark needs a use audit before filing or an excusable
  nonuse declaration.

**Ownership hygiene**
- Any assets where the `owner` is not a currently active entity per the
  entity register (if available)? Flag — may need recordal of assignment.
- Owner name inconsistencies across assets (same entity, different name
  strings)? Surface for cleanup.

**Expiration horizon**
- Any patents expiring in the next 24 months? Even without a maintenance
  deadline, the business may want to know — product planning, continuation
  strategy, licensing window.

**Unwatched assets**
- Any registered marks not on the watch list in CLAUDE.md → Brand protection?
  Flag as a gap for the attorney to decide whether to add.

Output format:

```
IP PORTFOLIO AUDIT — [date]

DEADLINE HYGIENE
  In grace: [N] — acting now avoids lapse
  Lapsed (not marked abandoned): [N] — confirm status
  Missing next-deadline computation: [N] — fill data or mark agent-managed

REGISTRATION GAPS
  TM applications pending >18 months: [list]
  Patent applications pending >4 years: [list]

USE IN COMMERCE (TM)
  §8 approaching on uncertain-use marks: [list]

OWNERSHIP
  Assets with unrecognised owner strings: [N]
  Owner name inconsistencies: [list]

EXPIRATION HORIZON (24 months)
  Patents expiring: [list]

BRAND WATCH
  Registered marks not on watch list: [list]

RECOMMENDED ACTIONS
  1. [highest priority]
  2. [etc.]
```

---

## Integration: ip-renewal-watcher agent

The `ip-renewal-watcher` agent in this plugin runs this skill on a schedule
(weekly by default) and posts the Mode 2 report to the channel named in
CLAUDE.md → Renewal alerts. If 🔴 items appear (grace / lapsed), the agent
posts them immediately regardless of schedule.

## Handoffs

- Receives: new asset records from prosecution skills (when an application
  is filed or a mark clears), from clearance skills (when a mark is adopted
  and a filing is queued), and from assignment recordals.
- Sends: "file §8 now" triggers to the attorney — this skill doesn't file
  anything; it tells the attorney the deadline and what to bring.

## What this skill does not do

- It does not file anything. Every action it surfaces is for the attorney
  or foreign associate to execute.
- It does not verify deadlines against the USPTO TSDR, WIPO, or any other
  registry. It computes them from the dates you give it. The register is
  a working copy; the registry is the source of truth.
- It does not decide whether to renew. Renewal is a business call — is the
  mark still in use, is the patent still valuable, does the domain still
  matter. This skill surfaces the deadline and the cost; the business and
  the attorney decide.
- It does not replace an IP management system for multi-hundred-asset
  portfolios. Anaqua, CPA Global, Clarivate, Alt Legal, and similar systems
  have direct registry feeds, deadline automation, and annuity payment
  services. This skill is best suited for smaller portfolios, or as a
  lightweight layer that surfaces what the system of record shows.
- It does not read office records to verify status. A §8 shown as "filed"
  here means someone told it so — not that the USPTO accepted it. Confirm
  acceptance through TSDR or the IP management system.$body$),
('marketplace:claude-for-legal/claude-for-legal/ip-legal/skills/takedown', 'legal', 'takedown', '', 'takedown', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /takedown

Three modes. Pick one:

- `/ip-legal:takedown --send` — draft a §512(c)(3) takedown notice. Fair-use gate (*Lenz*) + loud perjury / §512(f) gate before delivery.
- `/ip-legal:takedown --respond` — triage a takedown someone sent you. Options: comply / counter / engage / ignore.
- `/ip-legal:takedown --counter` — draft a §512(g)(3) counter-notice. Loud gate for the federal-jurisdiction admission and the perjury statement.

## Instructions

1. **Read the practice profile.** Load `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md`. If it contains `[PLACEHOLDER]` markers or does not exist, stop and say: "This plugin needs setup before it can give you useful output. Run `/ip-legal:cold-start-interview` — the takedown skill depends on your approval matrix and practice profile."

2. **Check matter workspaces.** Per `## Matter workspaces`: if `Enabled` is `✗`, skip. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`."

3. **Dispatch on `$ARGUMENTS`:**
   - `--send` → run send mode (below). Walk identify-the-work, identify-the-infringing-material, fair-use gate (*Lenz*), good-faith belief, accuracy/authority, draft the §512(c)(3) notice, run the loud gate, write output.
   - `--respond` → run respond mode (below). Read the incoming notice, assess (license, fair use, defects, host §512(g) compliance, sender credibility), present the four options, recommend, write the triage memo.
   - `--counter` → run counter mode (below). Confirm the predicate (taken down in response to a §512 notice, good-faith belief of mistake/misidentification, ready for federal-jurisdiction admission, attorney in the loop), draft the §512(g)(3) counter-notice, run the loud gate, write output.
   - No flag → ask once: "Are we sending a DMCA takedown, triaging one we received, or drafting a counter-notice?"

4. **Respect the gates.** In `--send` and `--counter`, the loud gate runs before any final output is written. The fair-use gate in `--send` is separate and runs earlier; "debatable" or "likely" fair use stops the draft and routes to attorney review.

5. **Jurisdiction note.** DMCA §512 is US federal law. If the service provider, content, or infringer sits outside US jurisdiction, flag before drafting — you may need an EU DSA notice, UK OSA notice, or local-regime instrument instead of (or in addition to) a DMCA notice.

6. **Hand off where appropriate.** `--respond` with a counter-notice recommendation chains into `/ip-legal:takedown --counter` — but only after the triage memo has been reviewed and the decision to counter has been made deliberately.

## Examples

```
/ip-legal:takedown --send
/ip-legal:takedown --respond ~/Downloads/youtube-takedown-notice.pdf
/ip-legal:takedown --counter
/ip-legal:takedown
```

## Notes

- The outgoing notice and counter-notice do not carry the work-product header. Internal drafts, fair-use analyses, and triage memos do.
- §512(c)(3) and §512(g)(3) are element-by-element statutes — every required element must be present or the notice is defective.
- Counter-notices consent to federal court jurisdiction in the claimant's district (or a designated district for non-US subscribers). This is not a formality.
- Non-lawyer users get a one-page brief for the attorney conversation before the gate clears — particularly important for counter-notices, which are the step before litigation.

---

## Purpose

The DMCA §512 notice-and-takedown system is fast, cheap, and consequential in equal measure. A takedown is a sworn statement under penalty of perjury that gets content pulled with no judicial review. A counter-notice is another sworn statement that consents to federal jurisdiction and puts the content back. Both decisions can become litigation. This skill handles all three moves with the guardrails each warrants.

Three modes:

- `--send` — draft a §512(c)(3) takedown notice
- `--respond` — triage a takedown someone sent you; produce options
- `--counter` — draft a §512(g)(3) counter-notice

If the user does not pass a flag, ask once: "Are we sending a DMCA takedown, triaging one we received, or drafting a counter-notice?"

> **External deliverables (send and counter modes):** the outgoing notice/counter-notice goes to the service provider's designated agent. Do NOT include the `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT` header on the outgoing document. The notice itself is not privileged — it's a statement made in a statutory process. Internal drafts, pre-send briefs, fair-use analyses, and triage memos keep the header per plugin config `## Outputs`.

## Jurisdiction assumption

DMCA §512 is **US federal law**. It runs against service providers subject to US jurisdiction. Other jurisdictions have their own notice-and-action regimes — EU Digital Services Act Art. 16, UK Online Safety Act, India IT Rules 2021, etc. — that differ materially in required elements, counter-notice mechanics, and liability for misuse. If the service provider, content, or infringer sits outside US jurisdiction, flag it — a US DMCA notice may be the wrong instrument, or may need to be paired with a local regime's notice. Copyright subsistence itself is Berne-multilateral, but enforcement mechanics are jurisdiction-specific.

## Load context

- `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → `## IP practice profile` (copyright registrations if any), `## Enforcement posture` → `Approval matrix → DMCA takedown (ordinary)` row, `## Outputs` (work-product header, role), `## Who's using this` (role — lawyer vs. non-lawyer)
- **Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (in-house default), skip matter machinery. If enabled and no active matter, ask: "Which matter? Run `/ip-legal:matter-workspace switch <slug>` or say `practice-level`." Write outputs to the active matter's folder at `~/.claude/plugins/config/claude-for-legal/ip-legal/matters/<matter-slug>/takedown/<slug>/` (or `takedown/<slug>/` at practice level). Never read another matter's files unless `Cross-matter context` is `on`.

## Send mode — drafting a §512(c)(3) takedown notice

### Step 1: Identify the copyrighted work

> What is the copyrighted work?
>
> - **Title / description** — what is the work (software, image, text, video, audio)?
> - **Registration status** — US Copyright Office registration number and date (if any). Registration is NOT required to send a takedown, but it is required to file suit on a US work and its pre-infringement timing controls statutory damages and fees.
> - **Ownership** — do we own it outright, or hold an exclusive license with takedown authority? (Non-exclusive licensees typically cannot send takedowns on the licensor's work.)
> - **Prior licensing** — have we ever licensed this use, or a broader use that might cover it?

Ownership and authority are the first things §512(f) cases look at. Get them clearly on the record before drafting.

### Step 2: Identify the infringing material and its location

> Where is the infringing material?
>
> - **Platform / service provider** — YouTube, Twitter/X, GitHub, Reddit, Amazon, a web host, etc.
> - **URL(s)** — specific permalinks to the infringing material. One notice can cover multiple URLs if they're all from the same service.
> - **Description** — what is the infringing material and how does it infringe (verbatim copy, substantially similar, derivative)?
> - **Screenshots / evidence** — preserved with timestamp and URL visible

§512(c)(3) requires "information reasonably sufficient to permit the service provider to locate the material." URLs alone are usually enough; be precise.

### Step 3: Fair-use gate

Under *Lenz v. Universal Music Corp.*, 801 F.3d 1126 (9th Cir. 2015), a copyright holder must consider fair use before sending a takedown. This is not a judgment about fair use — it is a consideration step that the sender must take and can prove they took.

Ask:

> Before we draft the notice, walk through fair use. Under *Lenz*, you have to consider it before sending — even if the conclusion is "not fair use." The four factors:
>
> 1. **Purpose and character** — commercial? transformative? criticism, comment, news reporting, teaching, scholarship, research?
> 2. **Nature of the copyrighted work** — factual or creative? published or not?
> 3. **Amount and substantiality** — how much of the work is used? is it the heart of the work?
> 4. **Effect on the market** — does the use substitute for the original or harm a derivative market?
>
> Your read on each? And your conclusion — fair use unlikely, debatable, likely?

Record the answer in the notice file. If "debatable" or "likely," do not draft. Stop and route to attorney review: "Fair use is debatable/likely on these facts. Sending a takedown on a use that is protected by fair use is the exact §512(f) exposure the statute creates. Route this to counsel before any notice goes out."

### Step 4: Good-faith belief

§512(c)(3)(A)(v) requires "a statement that the complaining party has a good faith belief that use of the material in the manner complained of is not authorized by the copyright owner, its agent, or the law."

The sender forms this belief on the record. Have they:

- Confirmed the work is theirs (or they have takedown authority via exclusive license)?
- Confirmed the use is not licensed (no prior deal, no implied license, no Creative Commons grant that would cover it)?
- Considered fair use (Step 3)?
- Reviewed the accused content directly (not just a report about it)?

If yes on all four, the good-faith belief is colorable. If no on any, pause.

### Step 5: Accuracy and agent authority

§512(c)(3)(A)(vi) requires "a statement that the information in the notification is accurate, and under penalty of perjury, that the complaining party is authorized to act on behalf of the owner of an exclusive right that is allegedly infringed."

This is the perjury statement. It applies to the accuracy of the identification and the authority — not to the fair-use determination itself, though §512(f) liability reaches both.

Confirm signer: who is sending this on behalf of whom, and do they have authority to do so?

### Step 6: Draft the notice

§512(c)(3)(A) elements — every one must be present:

1. **Signature** (physical or electronic) of the rights holder or authorized agent
2. **Identification of the copyrighted work** — "Copyrighted work: [title, description, registration no. if any]"
3. **Identification of the infringing material** with location information — "Infringing material: [URL(s), description, how it infringes]"
4. **Contact information** — address, phone, email of the complaining party or agent
5. **Good-faith belief statement** — verbatim, adapted: "I have a good faith belief that use of the copyrighted material described above is not authorized by the copyright owner, its agent, or the law."
6. **Accuracy and authority statement under penalty of perjury** — verbatim, adapted: "I swear, under penalty of perjury, that the information in this notification is accurate and that I am the copyright owner, or am authorized to act on behalf of the owner, of an exclusive right that is allegedly infringed."

Structure:

- Sender address block / date
- Recipient: designated DMCA agent at [service provider] (find via Copyright Office's DMCA Designated Agent Directory — `https://www.copyright.gov/dmca-directory/`)
- Re: Notice of Copyright Infringement pursuant to 17 U.S.C. §512(c)
- The six elements above, numbered or clearly set apart
- Signature line

Most service providers publish a preferred form or a web intake (YouTube Content ID / Copyright webform, Twitter / X copyright report, GitHub DMCA repo, etc.). The skill produces the notice content; the user submits through the provider's path. Note in the output which intake path is expected for the named service provider.

### Step 7: The loud gate before delivery

```
┌─────────────────────────────────────────────────────────────┐
│  BEFORE THIS TAKEDOWN GOES ANYWHERE                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  A DMCA takedown is a statement under penalty of perjury.   │
│  Signing and sending it is not a routine administrative     │
│  step — it is a sworn declaration with specific legal       │
│  consequences.                                              │
│                                                             │
│  • 17 U.S.C. §512(f) creates LIABILITY for knowing          │
│    material misrepresentations. People have been sued,      │
│    and have lost, for bad-faith takedowns — *Lenz v.        │
│    Universal*, 801 F.3d 1126 (9th Cir. 2015); *Online       │
│    Policy Group v. Diebold*, 337 F. Supp. 2d 1195 (N.D.     │
│    Cal. 2004); *Stephens v. Clash*, 796 F.3d 281 (3d        │
│    Cir. 2015).                                              │
│                                                             │
│  • The accuracy and authority statement is sworn under      │
│    penalty of perjury. That is a real statement, not a      │
│    formality.                                               │
│                                                             │
│  • Sending a takedown on material that is in fact           │
│    licensed, owned by someone else, or fair use is the      │
│    fact pattern §512(f) was written for.                    │
│                                                             │
│  Confirm before the notice leaves:                          │
│                                                             │
│    1. You own the copyright, or you hold an exclusive       │
│       license with takedown authority.                      │
│    2. The accused use is not authorized — you have          │
│       checked licenses, grants, and any prior consents.     │
│    3. You considered fair use per *Lenz* (see Step 3 of     │
│       this draft); your conclusion is on the record.        │
│    4. Whoever has authority to sign approves sending.       │
│                                                             │
│  Approver per your practice profile: [approver from         │
│  Enforcement posture → Approval matrix → DMCA takedown      │
│  (ordinary) row]                                            │
│                                                             │
│  Automatic escalations that apply here: [list any from      │
│  the practice profile that this matter triggers]            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

If the user is a non-lawyer (per `## Who's using this`), add:

> A DMCA takedown is sworn under penalty of perjury and creates §512(f) exposure for bad-faith or overbroad use. Have you reviewed this with an attorney? If not, here's a brief to bring to them: [generate a short summary: work, ownership, accused use, licensing check, fair-use analysis, signer, service provider]. A few thousand dollars of attorney time now is materially cheaper than a §512(f) suit.
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent); ABA IP section referral roster (US); law school IP clinics for individual creators and small businesses.

Do not write the final output without explicit engagement with the gate.

### Step 8: Output

**Primary:** `<matter-folder>/takedown/<slug>/notice-v<N>.md` (or .docx if the service provider accepts it — most accept pasted text or web-form submission). The notice content, ready to paste into the service provider's DMCA intake form or send to its designated agent.

**In-chat:** show the notice as plain text for review before writing. Iterate before committing to disk.

**Reviewer-facing closing note** (in the in-chat preview only):

> This is a draft DMCA notice for attorney review, not a notice ready to send. Sending it is a sworn statement with §512(f) exposure. A licensed attorney reviews, edits, and takes professional responsibility before submission. Do not send this unreviewed.

**Citation verification.** Any case or statutory citation included (for example, in internal memoranda around the notice) must be verified on a legal research tool. Source-tag each — `[Westlaw]`, `[CourtListener]`, `[user provided]`, `[model knowledge — verify]`, `[web search — verify]`. Citations tagged `verify` get checked first. No silent supplement from web or model knowledge if a configured research tool comes up thin — present options to the user.

**Post-send record.** After submission, write `<matter-folder>/takedown/<slug>/submission.md`: service provider, designated agent used (address or web form URL), date submitted, confirmation ID if returned, URLs targeted, counter-notice watch date (generally 10–14 business days), legal hold refreshed.

## Respond mode — triaging a takedown you received

Your content was taken down. A service provider has notified you of a §512(c)(3) notice. You have options.

### Step 1: Read the notice you received

Extract:

- **Sender** — entity, signer, address, email
- **Service provider** — who notified you (the platform)
- **Claimed work** — what they say is theirs
- **Your content alleged to infringe** — URL(s) or identifiers as they named them
- **Date of takedown / notice**
- **Whether the notice appears to meet §512(c)(3) on its face** — flag missing elements; a defective notice is not a proper notice

### Step 2: Assess

- **Do we have a license?** Negotiated, implied, Creative Commons, prior settlement, assignment — anything that authorizes the use.
- **Is it fair use?** Walk the *Lenz* four factors. Be honest; this is for us, not the response.
- **Is the notice defective?** Missing any of the §512(c)(3)(A) elements, lacking the perjury statement, signed by someone without apparent authority? Defective notices are not properly compliant; the host may still act on them but the sender's §512(f) exposure rises and our leverage rises.
- **Did the host comply properly with §512(g)?** Were we given notice and an opportunity to counter? If the host acted without giving us the chance, that is a separate issue with the host (not the sender).
- **Is the sender a troll?** Repeat pattern of overbroad takedowns on this platform?

### Step 3: Options

Present 4 options with tradeoffs:

**A — Comply (let the takedown stand)**
- When: they're right, or the fight isn't worth it
- Tradeoff: content stays down; may affect SEO, accounts with strikes policies, livelihood for creators
- Next step: log the event, confirm no counter-notice deadline issues, move on

**B — Send a counter-notice** (§512(g)(3))
- When: we have a good-faith belief the material was misidentified or removed by mistake — often applies where the use is licensed, fair use, or the sender doesn't own the work
- Tradeoff: sworn under penalty of perjury, consents to federal court jurisdiction in the sender's district (or our own if outside the US and we designate), puts the decision in the sender's hands for 10–14 business days — if they sue, content stays down; if they don't, content is restored
- Next step: `/ip-legal:takedown --counter`

**C — Engage the sender directly**
- When: there's room for a business resolution (license, credit, takedown of a narrower portion)
- Tradeoff: the content stays down during the conversation; settlement-communication hygiene matters (FRE 408 or equivalent; protection from substance and context, not labeling)
- Next step: outreach letter to the sender; do not send the counter-notice while discussions are live

**D — Ignore and let it stand; raise it elsewhere**
- When: the harm is small, we don't want the federal-jurisdiction admission, and we'd rather deal with the sender separately
- Tradeoff: content stays down; if the takedown itself was bad-faith, we may have §512(f) to assert on our own schedule — but that's its own fight

Recommend one with two sentences of rationale.

### Step 4: Write triage memo

Output: `<matter-folder>/takedown/inbound/<slug>/triage.md`.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

> **Privilege inheritance.** This triage records our first-pass assessment of an adverse takedown. It is attorney-client and/or work-product material. Do not forward outside the privilege circle or attach to counter-notice submissions without scrubbing.

# DMCA Takedown Received — Triage

> **READ FOR TRIAGE, NOT OPINION.** Structured intake scan, not a legal merit opinion. Every authority flagged for SME verification; every merit call is counsel's.

**Slug:** [slug]
**Received:** [YYYY-MM-DD]
**Service provider:** [platform]
**Incoming file:** [path]

## The notice

**Sender:** [entity, signer, counsel if any]
**Claimed work:** [title, description, reg no. if provided]
**Our content targeted:** [URLs / identifiers]
**Date of takedown:** [YYYY-MM-DD]
**Notice meets §512(c)(3) on its face:** [yes / no — list any missing elements]

## Assessment

**License / authorization check:** [read]
**Fair use walkthrough (Lenz factors):** [read — each factor + conclusion; `[SME VERIFY]`]
**Notice defects:** [list or none]
**Host compliance with §512(g):** [were we given notice and opportunity]
**Sender credibility:** [troll / real claimant / repeat takedown pattern]

## Options

### A. Comply
### B. Counter-notice (§512(g)(3))
### C. Engage sender
### D. Ignore

**Recommendation:** [A/B/C/D] — [two sentences why] — `[SME VERIFY: counsel to confirm before executing]`

## Deadlines

- **Counter-notice watch window:** 10–14 business days after counter-notice is submitted — content stays down if sender files suit in that window
- **Sender's suit filing timing:** typically on our counter-notice clock, if we counter
- **Any contractual deadlines with the host:** [check]

## Immediate actions

- [ ] Legal hold issued on the accused work and our related content — [yes/no]
- [ ] Business impact assessed (revenue, account strikes, SEO) — [yes/no]
- [ ] Matter created in log — [yes/no/TBD]
- [ ] Counsel assigned — [who]
```

Close the in-chat presentation with:

> This is a triage memo, not advice. The assessments above are a first read from the four corners of the notice. An attorney evaluates before you counter-notice (which consents to federal jurisdiction) or decide not to respond.

## Counter mode — drafting a §512(g)(3) counter-notice

Counter-notices put content back up unless the original sender sues within 10–14 business days. They are the step before litigation.

### Step 1: Confirm the predicate

- The content was taken down in response to a §512 notice (not a terms-of-service action by the host).
- You have a good-faith belief the material was removed by mistake or misidentification — the statutory test.
- You are prepared to consent to federal court jurisdiction in the original sender's district (or designate if you are outside the US).
- The decision has been made deliberately — not in reaction, not without attorney input.

### Step 2: Draft per §512(g)(3)

§512(g)(3) elements — every one must be present:

1. **Signature** (physical or electronic) of the subscriber
2. **Identification of the material removed** and its location before removal (the URL where the content was)
3. **Statement under penalty of perjury that the subscriber has a good faith belief the material was removed or disabled as a result of mistake or misidentification** — verbatim, adapted
4. **Subscriber's name, address, telephone number** — and, critically, **consent to the jurisdiction of the federal district court** for the district where the subscriber's address is located (or, if outside the US, any district in which the service provider may be found), and acceptance of service of process from the person who provided notification or that person's agent

Structure:

- Subscriber address block / date
- Recipient: designated DMCA agent at the service provider (same agent that received the original takedown)
- Re: Counter-Notification pursuant to 17 U.S.C. §512(g)
- The four elements above, numbered or clearly set apart
- Signature line

### Step 3: The loud gate before delivery

```
┌─────────────────────────────────────────────────────────────┐
│  BEFORE THIS COUNTER-NOTICE GOES ANYWHERE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  A DMCA counter-notice is a statement under penalty of      │
│  perjury AND consents to federal court jurisdiction. It     │
│  is the step before litigation.                             │
│                                                             │
│  • If the original claimant files suit within 10–14         │
│    business days after your counter-notice, the content     │
│    stays down pending the suit. 17 U.S.C. §512(g)(2)(C).    │
│                                                             │
│  • If they do not sue within the window, the host must      │
│    restore the content within 14 business days of your      │
│    counter-notice.                                          │
│                                                             │
│  • You are consenting to be sued in federal court in the    │
│    claimant's judicial district (or, if you are outside     │
│    the US, designating a district). This is a jurisdiction  │
│    admission you make by signing.                           │
│                                                             │
│  • The perjury statement is real. §512(f) liability runs    │
│    in both directions — senders and counter-senders.        │
│                                                             │
│  Confirm before the counter-notice leaves:                  │
│                                                             │
│    1. The material was removed in response to a §512        │
│       notice (not a TOS action).                            │
│    2. You have a good-faith belief the removal was a        │
│       mistake or misidentification — because the use is     │
│       licensed, fair use, not actually infringing, or the   │
│       sender doesn't own the work.                          │
│    3. You are prepared to be sued in federal court in the   │
│       claimant's district. Budget, counsel, and risk        │
│       tolerance are all set.                                │
│    4. An attorney has reviewed this before it is sent.      │
│                                                             │
│  Approver per your practice profile: [approver from         │
│  Enforcement posture → Approval matrix — counter-notices    │
│  generally route above the DMCA takedown (ordinary)         │
│  approver because of the federal-jurisdiction admission]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

If the user is a non-lawyer:

> A counter-notice consents to federal court jurisdiction and is sworn under penalty of perjury. Have you reviewed with a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction? This is not the Claude-review layer; this is the step where you need licensed professional judgment. Brief for the conversation: [generate a 1-page summary]. Referral resources: your professional regulator's referral service (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent); law school IP clinics; ABA IP section (US).

Do not write the final output without explicit engagement.

### Step 4: Output

**Primary:** `<matter-folder>/takedown/<slug>/counter-notice-v<N>.md` — the counter-notice content, ready to submit via the service provider's counter-notice intake.

**In-chat:** present as plain text for review before committing.

**Reviewer-facing closing note** (in-chat only):

> This is a draft counter-notice for attorney review, not a counter ready to send. Sending it is a sworn statement and consents to federal court jurisdiction in the claimant's district. A licensed attorney reviews before submission. Do not send this unreviewed.

**Post-submission record.** After submission, write `<matter-folder>/takedown/<slug>/counter-submission.md`: service provider, date submitted, confirmation ID, 10–14 business-day watch window end date calendared, watch for suit filing in the claimant's district, plan if content is restored, plan if suit is filed.

## Decision posture

Per `## Decision posture on subjective legal calls` in the practice profile: when uncertain whether the use is fair, whether the rights holder is us, whether the work is actually ours, whether fair use defeats the claim on the receiving side — do not silently decide. Fair use is the paradigmatic uncertain call. Flag for attorney review; surface the factors. Sending a takedown or a counter-notice on an assumption is a one-way door.

## What this skill does not do

- **Submit the notice.** Drafting only. The user submits through the service provider's designated channel.
- **Pick a service provider's intake form for the user.** Notes which path is expected; does not auto-submit.
- **Decide fair use.** Walks the four factors; flags. An attorney decides whether to proceed.
- **Validate the sender's claim on the receive side.** Structured read; every authority flagged for SME verification.
- **Bypass the gate.** The gate runs every time in `--send` and `--counter` modes.
- **Invent citations.** Any cites included are source-tagged and flagged for verification; no silent supplement.
- **Handle non-US regimes.** DMCA is US-specific. For EU DSA, UK OSA, India IT Rules, and other regimes — flag and route.$body$),
('marketplace:claude-for-legal/claude-for-legal/law-student/skills/bar-prep-questions', 'legal', 'bar-prep-questions', '', 'bar-prep-questions', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /bar-prep-questions

1. Load `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → bar jurisdiction, exam format (NextGen / traditional UBE / state-specific), weak subjects, prep course.
2. Also load `~/.claude/plugins/config/claude-for-legal/law-student/study-plan.yaml` if it exists — it tells you what subject is scheduled for today and what subtopics are still weak.
3. Apply the framework below.
4. **Exam-type gate (do not skip).** If exam format or jurisdiction isn't in the practice profile, ask before generating anything. The NextGen Bar Exam and the traditional UBE test materially different subjects — studying the wrong list is the one mistake that isn't recoverable. Point the student at the NCBE's jurisdiction page (<https://www.ncbex.org/>) to confirm their exam format and subject scope.
5. **Jurisdiction-rule gate.** If the student's jurisdiction has a state-specific component (CA, LA, NY Law Exam, FL state essay, VA, etc.) AND the subject is one where majority-vs-state rules diverge (Evidence, PR, Civ Pro, Criminal), ask whether this session is UBE/majority-rule, state-specific, or mixed. Do not silently default.
6. Generate questions **scoped to subjects tested on the student's exam**, weighted toward weak subjects. Label each question by rule body (`[UBE/majority]` or `[CA-specific]` / `[NY-specific]` / etc.) when running mixed.
7. When rules diverge between UBE/majority and the student's jurisdiction, explain the split explicitly in the answer — see `## Jurisdiction handling` below.
8. After each answer: explain why right/wrong. Track patterns in misses.
9. `--session <n>` runs a focused N-question session and writes results to `study-plan.yaml` under `session_history`.

---

## Real-matter check

If the question the student is asking sounds like it's about a REAL situation — their lease, their parking ticket, their family's business, their friend's arrest, a real dollar amount, a real deadline, a real party name — stop.

> "This sounds like a real situation, not a hypothetical. I can't give you legal advice, and you can't give it either — you're not a lawyer yet. If this is real, [the person] needs an actual lawyer: legal aid, your school's clinic, a lawyer referral service (your jurisdiction's bar association, law society, or legal aid body), or (if there's money) a private attorney. I'm happy to help you understand the general legal concepts involved, but that's study, not advice."

Watch for: real names, real addresses, real dates, specific dollar amounts, "my landlord/boss/parent/friend," "I got a ticket/letter/notice," deadlines measured in days. Any one of these is a trigger.

## Purpose

The bar exam tests a defined body of subjects. This skill drills you on them — weighted toward your weak spots.

## Exam type — ask first, do not assume

**The bar exam is in transition.** As of the July 2026 administration, the NextGen Bar Exam (developed by the NCBE) has launched in some jurisdictions, while others continue to administer the traditional Uniform Bar Exam (UBE). State-specific exams (California, Louisiana, Puerto Rico, etc.) are their own thing. The subject scope is materially different between the NextGen and the traditional UBE — **subjects no longer independently tested on the NextGen include Trusts & Estates, Family Law, Conflict of Laws, and Secured Transactions** (some underlying concepts may appear inside integrated "foundational concepts and skills" questions, but they are not standalone tested subjects the way they were on MEE).

Do not assume the subject list. Before generating any questions:

1. Load `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` and read the bar jurisdiction and bar date.
2. If the practice profile does not specify which exam format the student is sitting for (NextGen / traditional UBE / state-specific), **ask**:

   > Which bar exam are you sitting for?
   > 1. **NextGen Bar Exam** (NCBE, launched July 2026 in some jurisdictions)
   > 2. **Traditional Uniform Bar Exam (UBE)** (MBE + MEE + MPT)
   > 3. **State-specific exam** (California, Louisiana, Puerto Rico, Washington, etc. — tell me which)
   >
   > And which jurisdiction? The scope of what's tested depends on both.

3. **Point the student at the authoritative source.** Jurisdiction-by-jurisdiction exam format (and whether a given state has moved to NextGen) is on the NCBE's website at <https://www.ncbex.org/> under "Exams" → jurisdiction information. The NextGen subject outline lives at <https://www.ncbex.org/exams/nextgen>. The traditional UBE subjects (MBE and MEE) are at <https://www.ncbex.org/exams/mbe> and <https://www.ncbex.org/exams/mee>.

> **Verify your jurisdiction's exam format and subject list against the NCBE's current outline before studying. This is the single most important thing you can get right** — studying the wrong subject list is the one mistake this skill can't undo for you. If your prep course and the NCBE outline disagree, go with the NCBE outline and tell your prep course.

Scope every question-generation session to the subjects actually tested on the student's exam. If the practice profile lists a weak subject that is not tested on their exam (e.g., Secured Transactions for a NextGen jurisdiction), flag it:

> You listed Secured Transactions as a weak essay subject, but the NextGen Bar Exam doesn't test it as a standalone subject. Do you want to (a) skip it, (b) drill the UCC Article 9 concepts that may appear inside integrated NextGen questions, or (c) drill it anyway because you're curious / auditing the area?

## Jurisdiction handling

The bar exam is not one exam. It is a family of exams. Rules that are "correct" on one are "wrong" on another. Getting this right matters more than almost anything else this skill does.

### Two things to distinguish

1. **Exam structure.** What does the student's jurisdiction administer?
   - **Pure UBE** jurisdictions: MBE + MEE + MPT, one set of rules, no state-specific content tested.
   - **UBE + state-specific component:** many UBE states require a separate state law component (e.g., NY Law Exam, DC Mandatory Course). These are pass/fail or supplementary, not graded into the UBE score.
   - **Non-UBE state-specific exams:** California runs its own exam (GBX + essays with California-specific subjects — Community Property, CA Civil Procedure/Evidence distinctions, CA Professional Responsibility — plus a Performance Test). Louisiana runs a civil-law exam that shares almost nothing with the UBE. Florida, Virginia, and several others keep state-specific essay days alongside or instead of the MEE.
   - **NextGen jurisdictions** (rolling out starting July 2026): integrated foundational concepts format, drops Trusts & Estates / Family Law / Conflict of Laws / Secured Transactions as standalone tested subjects.

   Before generating questions, confirm structure via the `## Exam type` gate above. Do not assume.

2. **Rule content — where majority rule, UBE default, and the student's jurisdiction's rule can diverge.** Common divergence areas:
   - **Criminal law:** common-law vs. MPC vs. state code (e.g., CA Penal Code on murder degrees, felony murder scope, consent defenses).
   - **Evidence:** FRE vs. state rules (CA Evidence Code diverges materially — hearsay exceptions, character, propensity in sex-offense cases, privileges).
   - **Civil procedure:** FRCP vs. state (CA Code of Civil Procedure — 170.6 peremptory challenges, demurrers vs. 12(b)(6), different discovery scope).
   - **Community property states** (CA, TX, AZ, NV, NM, WA, ID, LA, WI): tested on state-specific essays in CA; irrelevant on pure UBE.
   - **Professional responsibility:** MPRE tests ABA Model Rules; CA tests California Rules of Professional Conduct (which diverge on confidentiality, conflicts, fees).

### Rule when generating questions

For every question, internally classify by which body of rules applies:

- **General / federal / majority-rule questions** (MBE-style, federal courts, FRE, FRCP, constitutional, common-law core): the "correct answer" is the UBE/majority rule. State.
- **Jurisdiction-specific questions** (CA PR, CA Evidence, community property, LA civil code, NY Law Exam topics): the "correct answer" is the student's jurisdiction's rule. State that.

### Divergence tags — per-rule, not per-subject

**Tag divergences at the rule level, not the subject level.** "[CA does not materially diverge on this rule]" stamped on every question in a subject is noise — a student sees the same tag on every Contracts question and stops reading. Scope the tag to the specific rule being tested.

Rules to apply when emitting divergence tags:

- If the specific rule tested in a question has no material CA/NY/LA/etc. divergence, tag **at the rule level** within that question: `[CA does not diverge on UCC § 2-207 — this answer holds on the CA bar.]`
- If the specific rule tested has a material divergence, fire the `**Your jurisdiction (X) diverges:**` block per the format above. Do not use a subject-level tag when a rule-level divergence exists.
- Do NOT blanket-apply a subject-level tag like "[CA does not materially diverge on this subject]" across all questions in a subject. Contracts-as-a-subject has both divergent rules (CA statute of frauds specific carve-outs, CA-specific consumer contract rules) and non-divergent ones (UCC § 2-207, Restatement § 71 consideration), and stamping them all with the same tag hides the divergences that matter.
- If a question is CA-specific by construction (e.g., a CA Community Property question on a state-specific essay day), skip the tag — the CA-specific framing is already explicit.

Short rule: the tag lives inside the question (at the rule being tested), not outside it (at the subject level).

### Rule when the rules diverge

When a question's answer differs between the majority/UBE rule and the student's jurisdiction's rule, the explanation must say so explicitly:

```markdown
**Correct: C**

**Why C (UBE/majority rule):** [rule + application]

**Your jurisdiction (CA) diverges:** Under [California Evidence Code § X / CRPC Rule Y / CA Penal Code § Z], the rule is [jurisdiction-specific rule]. Under that rule, the answer would be [A/B/C/D].

**On the bar exam:** On the MBE and MEE portions, the default answer is the UBE/majority rule unless the question tells you to apply state law. On a state-specific essay day (e.g., California's essay subjects, NY Law Exam, Florida state essay), the default is your jurisdiction's rule. Check the call of the question.

**Rule to remember:** [one-line takeaway flagging the split]
```

If the student sits for a state-specific exam day (CA, LA, FL state essay, VA, NY Law Exam, etc.), weight some sessions toward state-specific content. Ask:

> You're sitting for California. Do you want this session to be (a) MBE-style federal/majority rule, (b) California-specific essay subjects (Community Property, CA Evidence, CA PR, CA Civ Pro), or (c) mixed?

Never silently default to one. If the student says "mixed" or doesn't answer, generate a mix and label each question `[MBE / UBE default]` or `[CA-specific]` so they know which body of rules governs.

### When unsure of the jurisdiction's rule

The skill does not know every state's idiosyncrasies with confidence. If the student's jurisdiction has a known divergence but the skill is not confident on the specific current rule, flag it: `[UNCERTAIN: CA's exact rule here — verify against CA-specific prep materials (e.g., your prep course's California supplement, the California Bar's released essay graded answers)]`. Do not invent. The cost of a wrong California rule stated confidently is higher than the cost of flagging uncertainty.

## Confidence discipline

Every question generated states a rule. A wrong rule stated confidently is worse than no question. The rule for this skill:

- **Confident:** rule is black-letter in the subject; write the question normally.
- **Uncertain:** rule varies by jurisdiction, is a minority rule, or I'm not sure I've got it exactly right — flag inline with `[UNCERTAIN: specific reason]` and tell the student to verify against their prep course materials before relying on the question.
- **Don't know:** don't invent a question. Say "I don't have a reliable rule for this area; skip or use your prep course." Do not fabricate.

Every MBE question answer explanation carries the same rule: if the "why C is correct" rule isn't one the skill is confident on, flag `[VERIFY: rule — confirm against your prep course outline]`. Use liberally.

## Load context

`~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → bar jurisdiction, exam format (NextGen / traditional UBE / state-specific), weak subjects, prep course. If exam format isn't specified, run the "Exam type" gate above before continuing. If jurisdiction is specified, apply the `## Jurisdiction handling` rules — label questions by which rule body governs, and flag divergences explicitly.

Also load `~/.claude/plugins/config/claude-for-legal/law-student/study-plan.yaml` if it exists (written by the `study-plan` skill). If the plan has a session scheduled for today or specifies weak subjects to weight, honor it.

## Session mode

`--session <n>` runs a focused N-question session on a specific subject, tracks performance, and writes session results back to `~/.claude/plugins/config/claude-for-legal/law-student/study-plan.yaml` under `session_history` so the study plan adapts.

Trigger phrasing the student might use: "let's do 5 questions on Contracts", "run me 10 Evidence questions", "/law-student:session Evidence 10".

**Session flow:**

1. Confirm subject, N, and MBE-vs-essay (or mixed). If the student's jurisdiction has a state-specific component and the subject is one where rules diverge (Evidence, PR, Civ Pro, Criminal), ask whether to run UBE/majority rule, state-specific rule, or mixed.
2. Generate N questions. Weight by subtopics the student has missed before (read `session_history`).
3. Present them one at a time. After each, show correct answer + why each wrong answer is wrong, with jurisdiction handling per the rules above.
4. At session end, report:

```markdown
## Session: [Subject], [N] questions

**Score:** [X]/[N] ([percentage])
**Missed:** [list — subtopic + what went wrong]
**Weak subtopics:** [the 2-3 subtopics where misses clustered]
**Strong subtopics:** [where the student nailed it]

**Pattern vs. prior sessions:** [if session_history has prior sessions on this subject: "Hearsay exceptions missed in 3 of last 4 sessions — this is stuck. Route to /law-student:socratic-drill." Or: "Improvement from 40% to 70% on Evidence. Still shaky on character evidence."]

**Study plan update:** Weak subtopics added to priority list. Next scheduled [Subject] session: [date from study-plan.yaml].
```

5. Append session results to `study-plan.yaml` under `session_history`:

```yaml
session_history:
  - date: 2026-05-08
    subject: Evidence
    type: bar-prep-mbe
    n_questions: 10
    score: 6
    weak_subtopics: [hearsay-exceptions, character-evidence]
    jurisdiction_mode: mixed  # or ube / state-specific
```

If no `study-plan.yaml` exists, write session history to `~/.claude/plugins/config/claude-for-legal/law-student/session-history.yaml` instead so future sessions can still weight appropriately.

## MBE mode

> **Note on "MBE" terminology.** The traditional UBE uses the MBE (Multistate Bar Examination) for the multiple-choice portion. The NextGen Bar Exam replaces the MBE with its own integrated multiple-choice + short-answer question sets. If the student is sitting for the NextGen, generate NextGen-style questions (integrated foundational concepts across subjects, some shorter scenarios with selected-response answers) rather than classic MBE questions, and say so. Use the student's NCBE-listed subject outline as the subject universe.

### Generate questions

Classic MBE format (traditional UBE): fact pattern + call + four answer choices, one correct.
NextGen format: refer the student to released NextGen sample questions on the NCBE site for the current authoritative format and mimic that structure.

Subject distribution: weight toward weak subjects **within the subjects actually tested on the student's exam**. If `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` says weak on Evidence and Civ Pro, 60% of questions come from those.

Difficulty: bar-level. Not law school issue-spotter difficulty (which is higher). Bar questions are about knowing the black-letter rule and applying it cleanly.

### After each answer

Show correct answer + why each wrong answer is wrong.

```markdown
**Correct: C**

**Why C:** [the rule + application]

**Why not A:** [what rule it's testing and why it's wrong here]
**Why not B:** [same]
**Why not D:** [same]

**Rule to remember:** [the one-line takeaway]

---

**Citation check.** Rules and any cases cited in the explanation were generated by an AI model and have not been verified. Before you commit a rule to memory for the bar, cross-check it against your prep course outline or a jurisdiction-specific source. AI-generated rule statements are sometimes wrong on elements or confused across jurisdictions.
```

### Track patterns

Keep a running tally: which subjects, which sub-topics, which wrong-answer traps. After a session:

> "You missed 3 of 5 Evidence questions, all on hearsay exceptions. That's a pattern. Let's drill hearsay specifically."

## Essay mode

### Generate a prompt

Bar essay format for the student's exam and jurisdiction.
- **Traditional UBE states:** MEE format.
- **NextGen jurisdictions:** NextGen integrated performance task / short-answer format (per current NCBE released samples).
- **State-specific exams:** that state's essay format (California, Louisiana, etc.).

Subject per weak areas or user choice — **constrained to subjects tested on the student's exam.**

### Grade

After the student writes:

- Issue spotting: what did they spot, what did they miss
- Rule statements: accurate? Complete?
- Analysis: did they apply the rule to the facts, or just restate both?
- Organization: IRAC/CRAC or equivalent? Readable?

Bar grading is about competence, not brilliance. A complete, organized, accurate answer passes. A brilliant but incomplete answer doesn't.

```markdown
## Essay feedback

**Issues spotted:** [X] of [Y]
**Missed:** [list — these are points left on the table]

**Rule statements:** [Accurate / close / wrong — for each issue]

**Analysis:** [Did they actually apply, or just list rule + facts?]

**Organization:** [Clear or muddled]

**If this were graded:** [Pass / borderline / not yet — with what to fix]
```

## Schedule integration

If the student has a study schedule: weight questions toward what's on the schedule for this week. Fresh material gets drilled.

## What this skill does not do

- Replace a bar prep course. Commercial prep courses have the full curriculum. This is supplemental drilling.
- Predict the bar exam. Nobody can. Study everything.
- Pass the bar for you. Obviously.
- **State rules it isn't confident on without flagging.** If I'm not sure the rule is right, you will see `[UNCERTAIN]` or `[VERIFY]` — check the cited rule against your prep course before relying on the question. A wrong rule I state confidently is a worse study session than one I skip.$body$),
('marketplace:claude-for-legal/claude-for-legal/law-student/skills/case-brief', 'legal', 'case-brief', '', 'case-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /case-brief

1. Load `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → outline/brief preferences.
2. Apply the workflow below.
3. Brief in the student's format. If drill-me mode: ask the student to state the holding first.

---

## Purpose

A case brief is a tool for remembering what a case does. This skill makes one in your format — the format you'll actually use in your outline.

## Confidence discipline

Case briefs state holdings, rules, and reasoning. Getting them wrong turns your outline into a false map. The rule for this skill:

- **If you paste the case text:** I extract holding/rule/reasoning from what's in front of me. Confident.
- **If you only give a case name:** I brief from knowledge. Worth a lot less. I flag every line I'm not sure about with `[UNCERTAIN: specific reason]`, and I strongly recommend you confirm against the actual case before putting the brief in your outline. If I don't know the case well enough, I say so.
- **If the case has famous-but-contested interpretations:** I give the majority read and `[VERIFY: check your casebook and professor's framing]`.

A brief built on my guess and your good faith is worse than no brief. Better to err toward "I'm not sure — read it yourself" than to invent.

## Load context

`~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → outline/brief preferences (format, depth), learning style.

## The "don't brief it for me" rule (hard rule)

A brief you didn't write is a brief you won't remember. Every mode of this skill defaults to scaffolding the student's brief-writing, not to writing the brief.

**What this skill will do in every mode:**
- Ask the student what they already got from reading: the facts, the issue, the holding as they understand it.
- Provide the blank template in their preferred format (headings for Facts, Issue, Holding, Reasoning, Rule, Notes).
- Ask pointed follow-ups on whichever section is thin: "What were the key facts the court actually relied on?", "What's the narrow issue vs. the broader question?", "Why did the court reject the dissent's framing?"
- If the student pastes the case text, extract verbatim the court's own language for holding and reasoning — that is not writing-for-them; that is pointing at what the case says.
- Flag confused or wrong understandings: "You said the holding is X. The court's actual language is closer to Y. Which one is the rule you'll carry into your outline?"

**What this skill will not do, even if asked:**
- Write a full case brief from a case name alone. That is the exact thing the student is learning not to need.
- "Summarize this case for me" — refused. The brief is for remembering, which requires writing.

**Exception** (the only one): the student explicitly overrides — "I've read it three times, I'm stuck on phrasing the holding, just give me a starter sentence so I can rewrite it." Then write a minimal starter with `[VERIFY]` flags and prompt them to rewrite in their own words before it goes into an outline.

## Mode fork

**Drill-me mode:** Ask the student to state the holding before anything else:
> "You've read this case. What's the holding? One sentence."

If they can't state it, make them read it again. The brief is a memory aid, not a substitute for reading. Then proceed to the scaffold — ask them to state facts, issue, reasoning, and rule in turn. Push back on thin or wrong statements.

**Explain-to-me mode:** Same scaffolded workflow, softer tone. The skill walks the student through each section, offers structural prompts ("a good holding is one sentence, yes/no + the rule"), but still waits for the student to write the content. **Explain-to-me does not mean "write the brief for me."** It means "explain what a good brief looks like, and guide me through writing mine."

If the student pastes the case text in either mode, the skill can extract the court's own language into the Facts/Holding/Reasoning slots — that's not writing-for-them, that's pointing at the source.

## The brief — scaffold, then the student fills

The skill produces the **template with questions**, not the filled-in brief. Student fills each section; skill reviews, pushes back, suggests what's missing.

Per the student's format in `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md`. If none captured, default:

```markdown
## [Case Name], [cite]

**Court:** [court, year]

**Facts:** [The facts that matter to the holding. Not every fact — the ones
the court relied on. Two to four sentences.]

**Procedural posture:** [How did this get here? Trial court ruled X, this
is an appeal from that. One sentence.]

**Issue:** [The question the court answered. Phrased as a yes/no question.]

**Holding:** [The answer. One sentence. Yes/no + the rule.]

**Reasoning:** [Why. The court's logic. This is where the law is. Three to
five sentences.]

**Rule:** [The rule you'd put in your outline. The portable takeaway.]

**Notes:** [Dissent worth knowing? Distinguishable on these facts? How
professor emphasized it?]

---

**Citation check.** The case cite, quoted language, and any supporting authority above were generated by an AI model and have not been verified. Before you rely on them — in a brief, memo, outline entry, or exam answer — look them up on Westlaw, CourtListener, or your school's research tool. AI-generated citations are sometimes fabricated or misquoted.
```

## Depth calibration

Per `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` — some students want one-line briefs (rule + cite), some want full treatment. Match their format.

If they're a 1L still learning to read cases: fuller briefs. If they're a 3L doing bar prep: rules only.

## What this skill does not do

- Brief a case the student hasn't read. In drill-me mode, the holding check enforces this.
- Tell you what's on the exam. Brief everything; the exam will surprise you.
- **Brief from memory without flagging.** If you only give me a case name and I brief from what I think I know, every line I'm unsure about gets `[UNCERTAIN]` or `[VERIFY]`. Don't put a brief in your outline unless you've confirmed it against the actual case.$body$),
('marketplace:claude-for-legal/claude-for-legal/law-student/skills/cold-call-prep', 'legal', 'cold-call-prep', '', 'cold-call-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-call-prep

1. Load `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → class list, professors, learning style.
2. Apply the workflow below.
3. Identify reading (case name + citation, professor, class, syllabus context).
4. Predict 6-10 likely questions across categories (Facts / Holding / Reasoning / Application / Policy), weighted to professor's known tendencies.
5. Drill using socratic pattern — ask, wait, push back, narrow when stuck. Don't give answers.
6. Post-drill summary: strong/shaky/missed; what to re-check before class.

---

## Real-matter check

If the question the student is asking sounds like it's about a REAL situation — their lease, their parking ticket, their family's business, their friend's arrest, a real dollar amount, a real deadline, a real party name — stop.

> "This sounds like a real situation, not a hypothetical. I can't give you legal advice, and you can't give it either — you're not a lawyer yet. If this is real, [the person] needs an actual lawyer: legal aid, your school's clinic, a lawyer referral service (your jurisdiction's bar association, law society, or legal aid body), or (if there's money) a private attorney. I'm happy to help you understand the general legal concepts involved, but that's study, not advice."

Watch for: real names, real addresses, real dates, specific dollar amounts, "my landlord/boss/parent/friend," "I got a ticket/letter/notice," deadlines measured in days. Any one of these is a trigger.

## Purpose

Cold-calling lives or dies on preparation. The professor has read the case dozens of times and knows the questions; the student has read it once. This skill narrows the gap — predicts the likely question patterns for the case, drills the student on them, and surfaces what they haven't locked in.

Not a replacement for reading the case. A test that you actually did.

## Confidence discipline

- When the student provides case text or casebook excerpts: I predict questions based on the actual text. Confident.
- When the student provides only a case name: I predict based on what I know about the case. Flag `[UNCERTAIN]` on any question that depends on case details I'm not sure of. Strongly recommend the student pastes the case or casebook treatment first.
- If I don't know the case well: say so. "I don't have a reliable read on this case — paste the text or casebook treatment and I can work from that. Otherwise my questions are educated guesses."

## Load context

- `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` → current classes, professors, learning style
- User-provided: case name / case text / casebook pages / reading list

## Workflow

### Step 1: Identify the reading + professor

- Case name and citation
- Professor (from ~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md class list — tone and focus vary by professor)
- Class / subject area
- Where this case falls in the syllabus (for context — is this the first case on the topic, a narrowing case, a counterexample?)

### Step 2: Predict the questions

Professors cold-call in recurring patterns. Predict across these categories:

**Facts-level (warm-up):**
- Who are the parties? What happened? Procedural posture?
- What did the trial court do? The appellate court below?
- Why is this in the casebook? What subject is it illustrating?

**Holding / rule:**
- What's the holding? One sentence.
- What's the rule that comes out of this case — the portable takeaway?
- How would you phrase the rule if it were in your outline?

**Reasoning:**
- Why did the court decide this way?
- What arguments did the court reject?
- Was there a dissent? What did it argue?

**Application / hypos:**
- What if [fact X] were different — same outcome?
- How does this case compare to [prior case in the syllabus]?
- What's the limiting principle? Where does this rule stop?

**Policy / theory:**
- What's the policy the court is protecting?
- Does this rule make sense? Alternative approaches?

**Professor-specific flavor (from ~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md notes):**
- If the professor is known for hypo-heavy calls, weight Application/Hypo questions
- If policy-heavy, weight Policy/Theory
- If fact-heavy socratic (Socratic 101 Paper Chase style), weight Facts + Holding

Pick 6-10 questions across these categories. Rank by likelihood of being asked first (Facts usually go first, then Holding, then the harder categories).

### Step 3: Drill

Use the `socratic-drill` pattern:

1. Ask Question 1. Wait for answer.
2. If right + well-reasoned: acknowledge, move to Question 2.
3. If right but sloppy: don't let it slide. "You got there, but explain — why does the court's reasoning support that?"
4. If wrong: don't give the answer. Ask a narrowing question. "What facts does the court rely on?" Walk them to it.
5. If stuck: narrow further. "Before we go to the holding — what's the procedural posture?"
6. If genuinely lost: tell them to re-read the case. "This is a re-read, not a guess-your-way-through. Come back when you've read it again."

### Step 4: Post-drill summary

At the end:

```markdown
# Cold-Call Prep — [case] — [date]

**Questions drilled:** [N]
**Strong:** [questions where they were confident + right]
**Shaky:** [questions where they guessed or hedged]
**Missed:** [questions where they didn't know]

## Before class tomorrow:
- [specific thing to re-check — facts they got wrong, rule they couldn't state]
- [if shaky on policy/theory: "read the dissent again — that's usually where policy questions come from"]

## Questions likely to come up in class:
- [top 3 of the 10 — the ones the professor is most likely to lead with]
```

## Integration

- **case-brief:** if the student hasn't briefed the case yet, offer to run `/law-student:case-brief` before cold-call prep. A brief is a cold-call prep tool too.
- **socratic-drill:** if prep surfaces a weak spot in the subject (not just this case), follow with `/law-student:socratic-drill [subject]`.
- **flashcards:** if the case's rule is one the student should memorize, offer to add to the flashcard deck.

## What this skill does not do

- **Be the professor.** The actual cold-call can go anywhere. This skill predicts patterns; professors surprise.
- **Replace reading the case.** If you haven't read it, the skill can't help you — questions require text you've absorbed.
- **Give you the case's holding without asking you first.** Drill-me pattern: I ask, you answer.
- **Predict jurisdiction-specific niche questions.** If the professor has known hobby horses, capture them in ~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md class notes and the skill can weight accordingly; otherwise, it works from general patterns.$body$),
('marketplace:claude-for-legal/claude-for-legal/law-student/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md`. If already populated and no `--redo`, confirm before overwriting. If a populated ~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/law-student/*/CLAUDE.md` but not at the config path, copy it to the config path and tell the user what was migrated.
2. Apply the interview workflow below.
3. Walk Part 0 (who's using / what's connected — student vs. grad vs. other; document storage availability), Part 1 (where you are), Part 2 (how you learn — drill-me vs explain-to-me), Part 3 (strong/shaky/avoid), Part 4 (materials intake — target 10-20 items).
4. Re-read captured answers. Catch contradictions, drifted specifics, gaps worth naming now.
5. Write `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` (creating parent directories as needed), including `## Who's using this` and `## Available integrations`. Add `LIMITED DATA` flag if fewer than 10 materials were shared.
6. Confirm with the user: "Here's what I captured — anything wrong?"

**`--check-integrations`:** Re-run only the Part 0 integration-availability check. Updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` without touching the role or the rest of the profile. Use after adding or removing an MCP connector.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

---

## Purpose

The other cold-starts learn an organization. This one learns you. How you study, what you avoid, whether you want to be pushed or scaffolded.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the student and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed. If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/law-student/*/CLAUDE.md` but not here, copy it forward.

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

> **`law-student` is for law students studying for class or the bar.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you year in school (1L/2L/3L/bar prep), current classes, and bar exam date if applicable. **15 minutes** adds your learning style default (drill-me vs. explain-to-me), weak areas, past materials (outlines, graded essays, old exams), professor exam history from uploads, and flashcard subjects.
>
> Quick or full? (Upgrade any time with `/law-student:cold-start-interview --full`.)

## After the user picks quick or full

Once the student has picked, orient them. Cover, in your own voice:

- **What this plugin maintains:** your profile (classes, exam dates, weak areas, learning style), a study plan, per-subject outlines, flashcard buckets, and a practice-exam log.
- **What this setup does:** helps the student study law — outlines, case briefs, cold-call prep, exam forecasts, bar prep — in the format that fits how they actually learn. Learns study style, subjects, and exam schedule, and writes it into a plain-text file the plugin reads from every time. Everything can be changed later. Once it's done, the commands will work the way the student studies, not the way a generic template does.
- **Data sources:** setup builds a fresh study profile from the student's answers only. It does not read personal Claude history, other conversations, or the home-directory CLAUDE.md. If something relevant came up earlier in this conversation (e.g., a class or a bar date), ask before folding it in. Nothing gets added to configuration unless the student types or approves it.

**Why this matters.** Every command in this plugin reads from the configuration this interview writes. A generic configuration gives generic output — a default outline format, a default drill intensity, and exam forecasts calibrated to no one's actual classes. Telling the plugin how the student actually studies — drill-me vs. explain-to-me, subjects, professors, what gets avoided — is what makes the difference between "a study AI tool" and "a tool that pushes you the way you need to be pushed." The more specific the answers and the more materials uploaded (outlines, graded essays, old exams), the more the outputs will match the student's classes.

### Quick start or full setup — branching

The student picked quick or full in the preamble. Branch:

**Quick start path:** ask only the basics (who you are, what you're studying, bar jurisdiction if applicable). Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for case-brief format, flashcard style, and outlining conventions. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/law-student:cold-start-interview --full` anytime to do the whole interview, or `/law-student:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.

**Pause for real answers.** Part 1 has quick tap-through answers. Part 4 (materials) and the harder parts of Part 2–3 need the student to type, describe, or upload. When a question needs more than a quick tap:

- **Ask the question and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the student responds.
- **For uploads (syllabi, outlines, graded essays, old exams, MBE sets):** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in the practice profile so you can fill it later." Then actually wait. Don't silently move on.
- **Before writing the practice profile:** review the interview. List every question that was skipped or answered with a placeholder. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait for the answer.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the student made to skip — not a question that scrolled past because they paused to think.
- **Pause and resume.** Tell the student up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/law-student:cold-start-interview` again later and I'll pick up where you left off." When the student pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /law-student:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the student: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> I'm going to help you study. Not by giving you answers — by making you work for them. But first I need to know how you work. Ten to fifteen minutes.
>
> I'll also ask for materials along the way — past outlines, old exams, graded essays, syllabi. Ten to twenty documents across the interview is the target. More is better. Papers you've written count. If you share fewer than ten I'll flag the practice profile as LIMITED DATA — skills will still work, but outputs will be thinner because I'm pattern-matching on less of your actual work. Templates-first: if you upload an existing outline, I read it and match your format rather than asking you to describe it.

### Part 0: Who's using this, and what's connected

Two quick questions before we learn how you study. These shape how the plugin works, not what it can do.

#### Who's using this?

> Are you a law student, a recent grad studying for the bar, or someone else using this for legal study? (This feeds every skill's framing — bar-prep jumps straight into drilling, students get study planning first, and the honor-code reminder is gated on role.)
>
> 1. **Law student** — 1L, 2L, 3L, LLM; currently enrolled.
> 2. **Recent grad studying for the bar** — graduated, prepping for a bar exam.
> 3. **Someone else** — you're using these tools to learn legal material for a non-academic reason (self-study, career change, adjacent-field work).

If the answer is 1 or 2 (student or recent grad), say this once:

> Two reminders on using this for school or bar prep:
>
> 1. **Check your school's honor code and your professor's AI policy before using this on any graded work.** Most schools distinguish study tools (fine) from exam / graded-paper assistance (often restricted or prohibited). This plugin is built for study — drilling, outlining, IRAC practice, exam forecasting — not for producing work you turn in. When in doubt, ask.
> 2. **Don't paste real client facts into this plugin.** If you're in a clinic, externship, or summer job and a study question ends up touching a real matter, stop — that's a supervised-practice situation, not study. Use your clinic or job's approved workflow, or talk to your supervising attorney. See the real-client-matter check below.

If the answer is 3 (someone else), say this once:

> You can use every feature — drilling, outlines, writing practice, exam forecasts — the same way a student would. Two things change in how I'll frame things:
>
> 1. **I'll frame outputs as study material, not as legal advice.** Learning doctrine is not the same as applying it to your own situation. If you're using this because you're navigating a real legal issue yourself, a study tool isn't the right starting point — find a lawyer (your jurisdiction's lawyer referral service is the fastest door: state bar in the US; SRA/Bar Standards Board in England & Wales; Law Society in Scotland/NI/Ireland/Canada/Australia; or the jurisdiction's equivalent. Legal aid for individuals; local law school clinics can point you). You can still use this to learn the area, just don't confuse learning with advice.
> 2. **I'll pause if it looks like you've shifted from study into a real matter.** See the real-client-matter check below.

**Real-client-matter check (applies to all roles):** If the user describes a real matter with real facts (real client name, real dates, real filings, real legal exposure they or someone they know is facing) rather than a study hypothetical, pause:

> That sounds like a real matter, not a study hypothetical. If it is:
>
> - **If you're in a clinic, externship, or supervised practice:** don't paste client facts into a study tool — use your clinic's approved workflow or talk to your supervising attorney.
> - **If this is your own legal situation:** a study plugin is the wrong tool. Your jurisdiction's lawyer referral service is the fastest starting point (state bar in the US; SRA/Bar Standards Board in England & Wales; Law Society in Scotland/NI/Ireland/Canada/Australia; or the jurisdiction's equivalent); legal aid organizations cover many practice areas for individuals.
>
> I can still help you study the doctrine in the abstract. Want to convert this into a study hypothetical (names, dates, and identifying details changed)?

Do not continue analyzing the specific facts until the user confirms it's a study hypothetical or has been redirected.

#### What's connected?

> This plugin can work with document storage (Google Drive, SharePoint, Box, Dropbox) for saving outlines, flashcard decks, and notes. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need it. Every feature works with local file access alone.

Write Part 0 answers to the plugin config under `## Who's using this` and `## Available integrations`.

### Part 1: Where you are (1 min)

*(This feeds `/law-student:study-plan` and `/law-student:outline-builder` — classes become scheduled study blocks, exam formats drive what `/law-student:exam-forecast` and `/law-student:irac-practice` prepare you for, and the bar date schedules `/law-student:bar-prep-questions` backward from the exam.)*

- Year (1L, 2L, 3L, LLM)
- School type — T1 / T2 / T3 / T4. (This calibrates difficulty in downstream drill and exam-forecast skills; the school *name* isn't needed.)
- This semester's classes — name, exam format, where you are in the syllabus
- Bar jurisdiction and target date (if known) (This feeds `/law-student:bar-prep-questions` — schedules MBE sets and essay practice backward from this date, filtered to your jurisdiction's essay subjects.)

**Situations that don't fit the boxes.** If your situation doesn't match the standard options (non-US law school, JD/LLM hybrid, dual-degree, part-time evening program, self-study for a non-UBE state, foreign-trained attorney preparing for a US bar, visiting scholar, PhD candidate auditing courses, or anything else the standard categories assume away), say so. I'll shift: "It sounds like your program doesn't fit my usual categories. Tell me about it in your own words — what you're studying, what the schedule looks like, what's on the horizon (exam, bar, paper) — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

**Don't ask for the professor's name.** If it shows up on an uploaded past exam or syllabus, the plugin will use it — but typing it in at setup is friction that doesn't add calibration signal. See the materials prompt below.

### Part 2: How you learn (the key question) (2 min)

*(This feeds `/law-student:socratic-drill`, `/law-student:irac-practice`, and `/law-student:cold-call-prep` — drill-me pushes back without giving you the answer; explain-to-me scaffolds first, then tests. The default can be overridden per session.)*

> Some people learn by being asked hard questions and pushed back on. Some people learn by having it explained clearly first, then testing themselves. Which one are you?

**Drill-me:** I ask. You answer. I push back. I don't give you the answer — I make you find it. Socratic, but I'm on your side.

**Explain-to-me:** I explain clearly. Then I ask questions to check understanding. Less pressure, more scaffolding.

(You can switch per session. But the default matters.)

### Part 3: Where you're strong and weak (1 min)

*(This feeds `/law-student:study-plan` and `/law-student:bar-prep-questions` — weak areas and avoided subjects get more scheduled time and more drill sessions than strong ones.)*

- What comes easy?
- What's hard?
- What do you keep not studying? (Everyone has one. That's the thing to drill.)

### Part 4: Materials (3-5 min) — this is where the seed docs live

*(This feeds `/law-student:outline-builder` (your format and depth), `/law-student:exam-forecast` (professor patterns from past exams), `/law-student:legal-writing` (your writing voice from graded essays), and `/law-student:irac-practice` (feedback patterns). Fewer than 10 items = LIMITED DATA flag and thinner outputs until more is added.)*

Say this first, once, as a single ask:

> **Paste or link anything you've got: outlines (yours or commercial), class syllabi, past exams, graded essays, MBE question sets, class notes. The more I have, the more I can tailor. Professor names on past exams help me match patterns — if the professor's name is on an exam you upload, I'll use it. You don't need to type it.**

Then walk the categories below, capturing what the student has. More is always better for the downstream skills.

**Outlines:**
- Past outlines across subjects (any subject — format transfers)
- Flashcard decks if you keep them
- How you outline (format, depth, rules-only vs rules+cases)

**Graded work:**
- Graded essays with professor feedback — this is gold for the writing and IRAC-practice skills
- Old papers you've written (any length, any subject)
- Mid-term or practice exams you've taken with a grade on them

**Exam prep materials:**
- Old exams from the same professors (especially same-professor; those are highest signal)
- Syllabi for current classes
- Reading assignments / casebooks for current classes
- Practice MBE question sets with answer explanations (from your prep course — full sets if you have them)
- Bar prep course outlines if you're at that stage

**Class specifics:**
- Anything a professor has said about what they emphasize
- Class-specific study group outputs you trust

Target 10-20 items across these categories. Below 10: LIMITED DATA flag on the practice profile. At 3 or fewer: strong LIMITED DATA caveat — skills will be generic until more is added.

**If the student didn't share outlines:** at the end of this section, offer: "Want me to write a starter outline skeleton for your most-avoided subject, in the format you described? You can edit it as you go and it seeds the outline builder for future runs."

## Before writing — re-read

Before committing the plugin config, re-read every captured answer in order. Catches:

1. **Contradictions** — e.g., you said you're a "drill-me" learner but also "I panic under pressure." Surface both, ask which governs the default.
2. **Drifted specifics** — professor names, class abbreviations, dates that changed between sections. Confirm final values.
3. **Skipped gaps worth naming** — classes with no exam format captured, a bar jurisdiction mentioned but no target date, etc. Offer to fill now rather than leaving for `--redo`.

## Writing the practice profile

Per the template at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`. Short — it's about one person.

**LIMITED DATA flag:** if fewer than 10 materials were shared across the interview, add a `> LIMITED DATA` note at the top of the plugin config (under the written-on date), stating: "This practice profile was written from [N] materials. Downstream skills will operate but outputs will be thinner — the outline builder doesn't have your format yet, the exam forecast has thin signal on your professors, the IRAC grader won't know your writing patterns. Re-run `/law-student:cold-start-interview --redo` after gathering more outlines, graded essays, or old exams to sharpen it."

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in 1L / 2L / 3L study:**
>
> - **Brief a case in your format** — e.g., "Opinion in, brief out — in the format you actually use for class." Try: `/law-student:case-brief`
> - **Grade an IRAC essay** — e.g., "Structure, issue-spotting, rules, analysis, organization — does not rewrite." Try: `/law-student:irac-practice`
> - **Build or extend a class outline** — e.g., "Your format, your subject, iteratively built as you go." Try: `/law-student:outline-builder`
> - **Cold-call prep for tomorrow's class** — e.g., "Predict your professor's questions and drill them." Try: `/law-student:cold-call-prep`
> - **Flashcards by subject with Leitner buckets** — e.g., "Generate, drill, and promote / demote across sessions." Try: `/law-student:flashcards`
> - **Bar prep questions targeted at weak subjects** — e.g., "MBE or essay, drawn from your weak-subject list." Try: `/law-student:bar-prep-questions`
>
> **My suggestion for your first one:** Run `/law-student:case-brief` on the next case you have to read — it'll tell you whether the brief format matches how you actually study. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


**If the student is in bar prep mode** (Role is "Law student studying for bar," or they told you they're prepping for a bar exam): jump straight into questions — that's what bar prep users want.

- "What's the MBE subject you're most worried about? Let's drill that."
- If drill-me mode: "Okay. [Subject]. First question: [ask something about the subject]. Don't look it up."

**If the student is a regular law student** (not in bar prep): suggest a plan before a drill. Plans beat cold-drilling for a semester.

- **Start here:** `/law-student:study-plan` — builds a study schedule from your classes, exam dates, and weak areas. It'll suggest when to drill, when to outline, and when to do practice exams.

**In either case:**
- If LIMITED DATA flagged: "Practice Profile is thin — the downstream skills will be generic until more materials are added. Biggest gaps: [list]. Want to flag the top thing to gather?"
- **Before your first citation-heavy session, connect a research tool if you have one.** Say: "Before your first IRAC practice or case brief that leans on citations: if you have a research connector (CourtListener), wire it up. Without one, I'll flag every citation as unverified — cross-check against your casebook or bar-prep service. In Cowork: Settings → Connectors."

<!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
     "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->

Then close with the "you can change anything later" note:

> Done. Your configuration is at `~/.claude/plugins/config/claude-for-legal/law-student/CLAUDE.md` — a plain text file you can read and edit directly. Anything you answered can be changed:
>
> - Edit the file directly for a quick change
> - Run `/law-student:cold-start-interview --redo` for a full re-interview
> - Run `/law-student:cold-start-interview --check-integrations` to re-check what's connected
>
> The things students most commonly tweak later: your class list (swap in next semester's), your bar jurisdiction or exam date, and your learning-style default (drill-me vs explain-to-me). Your configuration will improve as you use the plugin — if an outline feels off or a cold-call-prep session misses what your professor actually cares about, the fix is usually here.

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/law-student:cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.$body$)
ON CONFLICT (skill_key) DO NOTHING;
