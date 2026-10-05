INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` — if populated and no `--redo`, confirm before overwriting.
2. Run the interview using the workflow below (includes Part 0 role + integration check).
3. Seed docs: AI/acceptable use policy (URL or file), a prior impact assessment, key vendor AI agreements, model inventory or allowlist/blocklist if they exist. Read all provided.
4. Extract: policy commitments and prohibitions, vendor positions (note gaps vs. stated), impact assessment structure, approved/prohibited tool lists.
5. Migration: if a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/ai-governance-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and tell the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` (create parent directories as needed). Show summary. Offer first task.

## Flags

- `--redo` — re-run the full interview and overwrite `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
- `--check-integrations` — re-scan available MCP connectors and refresh the `## Available integrations` table in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` without re-running the full interview. Use after setting up a new connector (Slack, document storage, scheduled-tasks).

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

```
/ai-governance-legal:cold-start-interview
/ai-governance-legal:cold-start-interview --check-integrations
```

---

## Purpose

Learn how *this* AI governance team works — what role the company plays in the AI
supply chain, which regulations actually apply to them, what their red lines are for
AI use cases, and what good impact assessment looks like here. Write it into the plugin config
so every other skill reads from the same understanding.

AI governance postures vary enormously. A company that builds AI products for enterprise
customers has almost nothing in common with a company that deploys off-the-shelf AI
tools internally. The interview figures out which one this is before anything else —
because builder obligations and deployer obligations are nearly opposite exercises.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/ai-governance-legal/*/CLAUDE.md` but not at the config path, copy it forward to the config path before proceeding.

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

> **`ai-governance-legal` is for people who run AI governance: use-case triage, impact assessments, vendor AI review, policy monitoring.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, practice setting, and which AI regulatory regimes apply (EU AI Act, NIST, state AI laws), plus working defaults for use-case triage thresholds, AIA format, and vendor AI positions. **15 minutes** adds your use-case registry and red lines, governance tiers, vendor AI playbook positions, escalation matrix, AIA house-style template extracted from a seed assessment, and the AI policy commitments extracted from your actual policy.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and regulatory scope. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for use-case triage thresholds, AIA format, and vendor AI positions. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/ai-governance-legal:cold-start-interview --full` anytime to do the whole interview, or `/ai-governance-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below. After the user picks, give the fuller orientation described next, then proceed to Part 0.

## After the user picks quick or full

Give the fuller orientation. One paragraph, in your own voice:

> "This plugin maintains: your practice profile (governance tiers, red lines, policy commitments), a use-case registry, impact assessments, and vendor AI reviews — all in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/`. It learns how you actually work — your practice, your risk calibration, your house conventions — and writes that into a plain-text file the plugin reads from every time. Everything you answer can be changed later."

Then: "Ready? A few quick questions first, then we'll go deeper."

**Why this matters** (offer if the user pushes back on the time cost). Every triage, impact assessment, vendor review, and policy-monitor sweep reads from the configuration this interview writes. A generic configuration gives generic output — a default use-case registry, default red lines, a default vendor-AI position matrix, and a triage that treats a resume-screening tool the same as an expense-anomaly flagger. Telling the plugin whether the user is a builder or a deployer, where the red lines are, and what they require from vendors is what makes the difference between "an AI-governance AI tool" and "a tool that knows your posture."

**Fresh professional profile.** Setup builds a fresh professional profile from the user's answers and the documents they explicitly share. It does not read the user's personal Claude history, unrelated conversations, or their home-directory CLAUDE.md. If something relevant surfaces in the current conversation context (e.g., they mentioned their company earlier), ask before using it — do not fold anything personal into the practice profile unless the user types it or approves it.

Corollary: the interview's inputs are the user's typed answers and documents they explicitly share. Do not pull from ambient context, prior sessions, or user memory to fill in gaps.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Pause for real answers.** Some questions are quick (pick A/B/C). Others need the user to type, describe, or share a document. When a question needs more than a quick tap:

- **Ask and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For uploads or shared documents:** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review the interview and list any questions that were skipped or answered with placeholders. Say: "Before I write your configuration, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait for the answer.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the user made to skip, not a question that scrolled past.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/ai-governance-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /ai-governance-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> I'm going to help with AI impact assessments, vendor AI reviews, use case triage,
> and keeping an eye on when the regulations move under you. Before I do any of that,
> I need to know what kind of AI governance shop this is. Ten to fifteen minutes.
>
> Then I'm going to ask you to show me a few things: your AI or acceptable use policy,
> a prior impact assessment if you have one, and your key vendor AI agreements. I'll
> learn more from those than from anything you tell me.

---

### Part 0: Who's using this, and what's connected

Two quick questions before we get into AI governance specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every output — lawyer gets "PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT"; non-lawyer gets "RESEARCH NOTES — NOT LEGAL ADVICE" and outputs framed as research for attorney review.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — founder, business lead, contracts manager, HR, procurement; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "GREEN — sign it," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — approving an AI use case for deployment, signing a vendor AI agreement, certifying an impact assessment. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent). Many offer free or low-cost initial consultations. For small businesses, local law school clinics and SCORE mentors can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### Practice setting

Ask once, early, so later questions about escalation and sign-off branch correctly:

> Practice setting? (This feeds the governance team and escalation matrix — every skill checks here before telling you to loop in someone above you, and the branching below reframes escalation as "consult" vs "route for approval" accordingly.)
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

Branching for later parts of the interview:

- **Solo practitioner or small firm without a hierarchy:** skip or reframe escalation-chain questions. Instead of "who approves above your threshold," ask "when do you call in outside counsel or a colleague for a second opinion." Escalation maps to "consult," not "route for approval." The `## Governance team and escalation` section in the practice profile should be written around consultation triggers, not internal approval levels.
- **In-house legal, midsize, or large firm:** ask the escalation chain as currently designed (Part 4).
- **Legal aid / clinic:** route toward a supervision-model framing in Part 4 — who supervises, when does a matter go up to the supervising attorney?
- **Government:** adapt — ask who inside the agency/office owns approval above the attorney's authority.

Record this in the `## Company profile` → `**Practice setting:**` line of the practice profile, and in the `## Governance team and escalation` structure.

#### What's connected?

> This plugin can work with: document storage (Google Drive, SharePoint, Box), scheduled-tasks, Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Google Drive isn't connected. In Claude Cowork: Settings → Connectors → Add → Google Drive → sign in. In Claude Code: add the Drive MCP to your config or via `/mcp`. This plugin works without it — you'll paste policies and assessments directly — but connecting it lets the policy-monitor skill crawl your AIA folder automatically."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.]

You don't need all of these. Core features work with file access alone. If you set something up later, re-run `/ai-governance-legal:cold-start-interview --check-integrations`.

Write a `## Who's using this` section and an `## Available integrations` section into the plugin config immediately after the first section. Merge the work-product-header logic into the existing `## Outputs` section per the template.

---

### Part 1: Builder, deployer, or both? (3-4 min)

**What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription). The builder/deployer question below only makes sense on top of this.

**This is the question that determines everything else.**

> **EU AI Act roles are per-system, not per-company.** If your jurisdiction
> footprint includes the EU, your role (provider, deployer, importer,
> distributor, authorized representative, product manufacturer) and risk tier
> are assessed for each AI system separately — you might be a deployer of
> one system and a provider of another. Instead of assigning one company-
> level role, I'll set up a system inventory. We can do 1-3 systems now and
> add the rest later with `/ai-governance-legal:ai-inventory add`. Or skip
> the inventory for now if you're not in the EU or not ready.

Walk through the role options if the user isn't sure:
- **Provider:** You develop an AI system (or have it developed) and place it
  on the EU market or put it into service under your own name or trademark.
- **Deployer:** You use an AI system under your own authority, not for
  personal non-professional use. (Most common inside companies.)
- **Importer:** You bring an AI system into the EU from a provider
  established outside the EU.
- **Distributor:** You make an AI system available on the EU market without
  being the provider or importer.
- **Authorized representative:** You act on behalf of a non-EU provider and
  are established in the EU.
- **Product manufacturer:** You put an AI system into a product under your
  own name or trademark. Treated as provider for the product.

**Offer to populate the inventory now.** Prompt: "Want me to walk through
1-3 of your AI systems now and set up the inventory? Or skip and come back
with `/ai-governance-legal:ai-inventory add` later?" If they accept, run the
Add flow and the classification walk-through from
`ai-governance-legal/skills/ai-inventory/SKILL.md` for each system. Save to
`~/.claude/plugins/config/claude-for-legal/ai-governance-legal/ai-systems.yaml`.

If they decline or their jurisdiction footprint excludes the EU, note that
in the config and move on. The inventory can be populated later.

**High-level context questions** (ask lightly regardless of inventory
choice, to size the practice):
- What kind of AI touches your company today — generative, classification,
  recommendation, automation, something else?
- Who experiences the AI — customers, employees, candidates, no humans?
- Do you train or fine-tune models, or only consume third-party AI?
- Do you have a model card, system card, or similar documentation
  practice — or does your AI use only involve tools built by others?
- Who manages vendor AI relationships — procurement, legal, a dedicated AI
  team?
- Are you using AI in any decisions that affect employees or customers?

**Shadow AI discovery.** After the formal tool inventory, ask: "Beyond your approved tools, what AI is actually in use?
- **Embedded AI in tools you've already approved:** Slack AI summaries, Microsoft Copilot, Salesforce Einstein, Gmail smart compose, Zoom AI Companion, CRM lead scoring, email drafting assistants. Many organizations adopted these as 'productivity tools' and never triaged them as AI.
- **Informally adopted tools:** Employees using ChatGPT, Gemini, Claude, Perplexity, or other consumer AI without central approval. Check with IT for SaaS spend, browser extension usage, and DLP alerts.
- **Vendor AI you may not know about:** A 'CRM tool' with an AI scoring feature, a 'document system' with AI classification, a 'HR platform' with AI screening. Ask vendors directly: 'Does your product use AI or machine learning for any feature we've enabled?'

Add anything surfaced to the use case registry as `[UNDOCUMENTED — NEEDS TRIAGE]`. A registry calibrated only to formal deployments while unapproved tools run in the shadows is a registry that lies. The triage skill will pick these up."

**If both:** Establish which side is the larger governance surface area for now —
that's where to go deep first.

---

### Part 2: Regulatory footprint (2-3 min)

> Which regulations are actually on your radar? I don't want to assume — tell me
> what's real for you. (This feeds /reg-gap-analysis and /policy-monitor — the gap analysis diffs new regulations against your stated scope, and policy-monitor only watches regimes you've marked in scope.)

**Do not assume any regulation applies. Ask the user which regimes they think apply, then research the AI-specific regulations currently in effect or pending in the jurisdictions where the company operates, deploys AI, or has affected parties. This landscape changes quickly — verify currency.**

Prompts to walk through:

- **Jurisdictional footprint** — where are customers, employees, data subjects, and business operations? Does AI touch people in any of those places?
- **Cross-border AI regimes** — if the company has users, customers, or employees outside its home jurisdiction, research whether those jurisdictions' AI regimes reach the company's activity.
- **US state AI laws** — ask which US states the company operates in; research the state-specific AI, biometrics, and automated-decision laws currently in effect or pending in each.
- **Sector regulation** — financial services, healthcare, employment, education, critical infrastructure — ask about the company's sector and research the sector-specific AI guidance from the relevant regulator(s).
- **Contractual requirements** — do enterprise customers require AI disclosures, impact assessments, or AI-specific DPA terms?

**Open regulatory matters:**
- Any regulator who knows you by name? Investigations, voluntary commitments,
  consent orders relating to AI?
- Any pending procurement requirements (government contracts requiring AI
  certifications)?

**Practical calibration:**
> "Some teams are in full compliance mode for one or more AI-specific regimes; others are focused primarily on contract commitments from enterprise customers. Where are you on that spectrum?"

---

### Part 3: Use case registry and red lines (4-5 min)

> Before the scenarios: do you have an existing AI use case registry, an AI policy, or a list of approved/prohibited AI tools I can read? Paste the contents, share a file path, or say 'no' and I'll walk through the scenarios. If you share one, I'll extract the positions and skip the scenarios that are already covered.

If not:

This is the equivalent of the DPA playbook for AI governance — most teams have
implicit red lines but rarely write them down. The goal is to extract the registry
*conversationally* from examples, not to ask for a formal document they don't have.

**Approach:** Ask about the most common use case categories for their context, then
walk through each one.

> "I want to build a picture of your use case landscape and where your lines are.
> I'll give you some scenarios — tell me if they'd be a yes, a conditional yes,
> or a hard no at your company."

**Scenario prompts (tailor to builder/deployer profile):**

*For deployers / internal use:*
- "An HR team wants to use AI to screen resumes before a recruiter looks at them.
  What happens — is that approved, conditional, or a no?"
- "A manager wants to use AI to summarize performance review notes before writing
  their own. Same question."
- "Customer support wants to use AI to draft responses before a human reviews and
  sends. Yes, conditional, no?"
- "Finance wants to use an AI tool to flag anomalies in expense reports."
- "Legal wants to use an AI assistant to first-draft NDAs."

*For builders / product AI:*
- "A PM wants to add an AI feature that surfaces personalized content recommendations
  based on user behavior."
- "A product team wants to use AI to score leads and prioritize sales outreach."
- "A feature uses AI to make automated decisions without human review in the loop.
  What triggers a review requirement?"

**For each use case, capture:**
- Approved / conditional / never
- If conditional: what does it take? (Privacy review, impact assessment, legal sign-off,
  specific vendor only, human-in-the-loop requirement, disclosure to affected parties?)
- If never: why is it a hard no? (Specific regulation? Company policy? Past incident?)

**The red lines question:**
> "What's the use case that's an automatic no — the thing someone could propose
> and you'd stop them immediately without needing to think about it?" (This feeds /use-case-triage — the skill checks proposed AI use cases against these red lines before doing anything else, and flags anything on the list as automatic stop.)

Common categories to probe if they're slow: biometric data, emotion detection,
political/religious inference, fully automated adverse decisions affecting employment
or credit, uses involving children.

**Governance tier question:**
> "Do you have a tiered approval process — some things the team can approve,
> some things go to legal, some things need the board? Or is it case by case?"

**If the user didn't upload a use-case registry:** at the end of this section, offer: "Want me to write this up as a standalone use-case registry and red-lines doc you can share and maintain? Same content I just captured — approved, conditional, never — formatted so product and PMs can check before they propose something."

---

### Part 4: Governance and escalation (2 min)

**The team:**
- How many people work on AI governance? Is there a dedicated AI ethics or
  responsible AI function, or does it sit in legal/privacy/security?
- Who owns the relationship with AI vendors — legal, procurement, IT?
- Is there a CISO, CPO, or equivalent who owns AI risk?

**Escalation:**

> "When a review finds something that needs someone more senior to sign off — a vendor AI agreement with training-on-data or liability issues, an AI use case that doesn't fit your registry, a regulatory gap that needs a decision, or a call above your authority — who does that go to? Give me a name or a role (the GC, the Chief Privacy Officer, your boss), or say 'I decide myself.' This is how the plugin knows when to say 'you can handle this' versus 'loop in [X].' (This feeds every skill's routing logic — /use-case-triage, /vendor-ai-review, and /reg-gap-analysis all check the escalation matrix before telling you to hand something up.)"

Also ask:
- Has anything been escalated to the board or C-suite over AI in the last year?

**External commitments:**
- Have you signed any voluntary AI commitments, adopted industry standards, or published a customer-facing AI principles page?
- Do you publish an AI transparency report or have public AI principles?

---

### Part 5: Seed documents (3-4 min)

> "I want to see what you actually have. Tell me which of these exist, and share
> what you can. (The AI policy feeds /policy-monitor drift detection; the prior impact assessment becomes the /aia-generation template; the vendor agreements become the starting playbook for /vendor-ai-review.)"
>
> 1. **AI or acceptable use policy.** Your internal or public-facing policy on how
>    AI can and can't be used. This tells me your committed positions.
>
> 2. **A prior AI impact assessment or AI risk assessment.** Even a rough one.
>    I'll learn your structure, depth, and what you flag as high-risk.
>
> 3. **Key vendor AI agreements or AI addenda.** The contracts with your main AI
>    vendors. I want to see what you've actually agreed to — liability, data use,
>    auditability, etc.
>
> 4. **Model inventory or AI system register.** If you have one — even a spreadsheet
>    listing what AI you're running and where.
>
> 5. **Allowlist or blocklist.** Approved tools, prohibited tools, or a tiered
>    approved vendor list.
>
> If you don't have any of these — that's fine and not unusual. Tell me that and
> I'll work with what you have.

**Graceful degradation — "I have nothing" path:**

If they have no seed documents:
> "That's okay. Here's what we'll do: I'll set up a baseline practice profile using what
> you told me in the interview, and I'll flag every section that's based on what you
> said rather than a reviewed document. Those are the sections to check hardest.
>
> The two things that matter most to nail down first are your use case red lines
> (so the triage skill works correctly) and your vendor positions (so we can review
> the next agreement that comes in). We can build those from scratch in the next
> 20 minutes if you want."

**How to read the seed docs:**

**AI/acceptable use policy:** Extract every commitment and prohibition. These bind
every impact assessment and vendor review — the impact assessment skill needs to
check new use cases against stated policy.

**Prior impact assessment:** Extract the structure as a template. Section headings,
depth of analysis, format of risk statements, what mitigation looks like here. This
becomes the default output format for the aia-generation skill.

**Vendor AI agreements:** Map each vendor's data use terms, liability positions,
auditability commitments, and any AI-specific provisions. Flag gaps against what the
company said they require.

**Model inventory:** Note every AI system in production. Cross-reference against
whether an impact assessment was done for each. Gaps are the backlog.

### Part 6: Outputs and policy document location (1 min)

> "Two last things — I need to know where to look to keep your AI policy current."

- **Where do you save completed AIAs, triage results, and vendor AI reviews?** A folder
  path or shared drive location. (This feeds /policy-monitor — the skill crawls this folder to detect when your practice has drifted ahead of your written AI policy.)
- **Where is the actual AI or acceptable use policy document?** The one that gets
  published internally or shared with customers/employees. I'll need to read it to
  suggest edits when drift is found.
- **Is there a naming convention for output files?** (e.g., `AIA_UseCase_YYYY-MM-DD`)
  or is it ad hoc?

If outputs aren't saved anywhere yet:
> "That's fine — the policy-monitor skill will still work in direct-query mode
> ('we want to start doing X, does our AI policy cover it?'). The crawl sweep just
> won't have anything to scan until you start saving outputs."

---

## Writing the practice profile

```markdown
# AI Governance Practice Profile

*Written by the cold-start interview on [DATE]. Edit this file directly.*

---

## Company profile

[Company] is a [description — what the company does and who its customers are].

**AI role:** [Builder / Deployer / Both — and what that means for this company
specifically]

**Builder profile (if applicable):** [Type of AI built, customer segments, whether
models are trained or fine-tuned, whether AI makes consequential decisions]

**Deployer profile (if applicable):** [AI tools in use, where AI touches the product
or operations, vendor relationship owner]

**Regulatory footprint:** [Only list what actually applies — EU AI Act / Colorado /
BIPA / sector-specific / contractual requirements only]

**Open regulatory matters:** [none / list]

**External commitments:** [voluntary commitments, public AI principles, transparency
reports — or none]

---

## Use case registry

*Extracted from interview on [DATE]. Add new use cases as they arise.*

| Use case | Approved | Conditions / Requirements | Never — reason |
|---|---|---|---|
| [e.g., Resume screening AI] | Conditional | Impact assessment required; human reviews every decision; disclosure to candidates | Fully automated adverse decision |
| [e.g., AI-drafted legal documents] | Conditional | Attorney reviews before use; no privileged matter input | — |
| [e.g., Emotion/sentiment detection for HR] | Never | — | Company policy; high litigation risk |
| [add rows from interview] | | | |

### Red lines

The following are automatic nos, regardless of framing:

- [Red line 1 — reason]
- [Red line 2 — reason]
- [Add from interview]

### Governance tiers

| Risk tier | Approval path | Example use cases |
|---|---|---|
| Standard | [team approval / department head] | Internal productivity tools, assistive drafting |
| Elevated | [Legal / privacy review required] | Customer-facing AI, HR use cases, data-heavy tools |
| High | [C-suite / board-level] | Consequential automated decisions, biometric, new AI product launch |

---

## Impact assessment house style

**Trigger:** [What requires an impact assessment — new AI feature, new vendor, new
use case, specific risk categories]

**Format:** [Structure extracted from seed impact assessment — or baseline if none
provided]

**Depth:** [Typical length / detail level — or "to be established"]

**Sign-off:** [Who approves — just legal, or a review committee]

**Template structure (from seed assessment or baseline):**

1. [Section 1 heading and rough content]
2. [Section 2]
3. [etc.]

*Note: [If no seed doc — "Baseline structure. Update after completing first
assessment."]*

---

## Vendor AI governance

### What we require from AI vendors

| Term | Our standard | Acceptable fallback | Never |
|---|---|---|---|
| Data use | [e.g., No training on our data without opt-in] | [Limited retention for safety only] | [Unrestricted training on our inputs] |
| Auditability | [e.g., SOC 2 + annual third-party audit] | [Documented internal audit process] | [No audit rights] |
| Liability for AI outputs | [e.g., within the MSA cap] | [Separate capped carveout] | [Zero vendor liability for AI errors] |
| Incident notification | [e.g., 72 hours for AI system failures affecting us] | | |
| Human review rights | [e.g., can demand human review of consequential outputs] | | |
| Model change notification | [e.g., 30 days notice for material model changes] | | |

### The one thing

[Vendor AI term that's an automatic no]

---

## AI policy commitments

*Extracted from [policy name / URL] on [date]. If the policy changes, re-run setup
or edit this section.*

**Prohibited uses stated:** [list]
**Required safeguards stated:** [list]
**Disclosure obligations stated:** [what the policy says about disclosing AI use
to customers, employees, or affected parties]
**Approved vendors / tools:** [list or "maintained in allowlist"]
**Prohibited vendors / tools:** [list or "maintained in blocklist"]

---

## Governance team and escalation

**Team:** [N people / function — where AI governance sits in the org]
**Vendor relationship owner:** [who manages AI vendor contracts]
**AI risk owner:** [CISO / CPO / GC / dedicated role]

| Issue | Handle at | Escalate to | When |
|---|---|---|---|
| New use case — standard tier | [team / department] | [you] | Ambiguous risk tier |
| New use case — elevated tier | [you + legal review] | [GC] | Outside approved categories |
| New use case — high tier | [you + GC] | [C-suite / board] | New consequential AI product, biometric, automated adverse decision |
| Vendor AI incident | [you + security] | [GC + C-suite] | Data exposure, model failure affecting customers |
| Regulator inquiry | — | [GC + you immediately] | Always |
| Employee AI misuse | [HR + you] | [GC] | Policy violation with legal exposure |

---

## Seed documents

| Doc | Location | Date reviewed | Notes |
|---|---|---|---|
| AI / acceptable use policy | [path/URL] | [date] | [version or "none — baseline used"] |
| Reference impact assessment | [path/link] | [date] | "[feature/use case it was for]" |
| Key vendor AI agreement | [path/link] | [date] | "[vendor name]" |
| Model inventory | [path/link] | [date] | "[N systems as of date — or none]" |
| Allowlist / blocklist | [path/link] | [date] | |

---

*Re-run: `/ai-governance-legal:cold-start-interview --redo`*
```

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in AI governance:**
>
> - **Review vendor AI terms** — e.g., "A vendor sent AI provisions in their SaaS agreement — check them against your training-on-data, liability, and model-change positions." Try: `/ai-governance-legal:vendor-ai-review`
> - **Triage a proposed AI use case** — e.g., "A PM wants to add an AI feature — run it against your registry for approved / conditional / not approved." Try: `/ai-governance-legal:use-case-triage`
> - **Run an AI impact assessment** — e.g., "A high-risk use case needs a structured AIA with regulatory classification and recommended conditions." Try: `/ai-governance-legal:aia-generation`
> - **Diff a new AI regulation against your posture** — e.g., "A new AI rule dropped — see what gaps it opens and what remediation it forces." Try: `/ai-governance-legal:reg-gap-analysis`
> - **Sweep for policy drift** — e.g., "Look across saved AIAs, triage results, and vendor reviews to find where your AI policy no longer matches practice." Try: `/ai-governance-legal:policy-monitor`
>
> **My suggestion for your first one:** Triage one real use case from your backlog — it's the fastest way to feel what the registry gives you. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show the summary.** "Here's what I heard. The use case registry is the part to
   check hardest — did I capture your red lines correctly? Those drive the triage
   skill."

2. **Propose first tasks:**
   - "Want me to run a triage on the use cases you mentioned and give you a risk
     tier and impact assessment checklist for each?"
   - "Got a vendor AI agreement in the queue I can review against your positions?"
   - If no impact assessment template: "Want to build your impact assessment template
     from scratch now? Fifteen minutes."
   - If no policy: "You're running without a written AI policy — if something goes
     wrong, you'll be explaining your governance verbally. Want to draft one?"

3. **Flag gaps:** Call out explicitly what's missing and what risk that creates.
   Don't soften it.
   - No model inventory: "You don't have a register of what AI you're running. That
     means you can't do a systematic impact assessment review and you can't respond
     quickly to an incident. That's the first thing to fix."
   - No vendor AI terms: "Your vendor agreements may have no AI-specific provisions —
     which means your vendors can train on your data, change their models without
     notice, and disclaim all liability for AI errors. Worth reviewing the next
     renewal."

4. **Connect to privacy:** If the company has a privacy plugin configured, note:
   "Some of this overlaps with your privacy practice — PIAs and AI impact assessments
   often cover the same ground. Once both plugins are calibrated, I can flag when a
   use case needs both."

5. **Close with a note on changeability.** End with something like:

   > "Done. Your configuration is at `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` — it's a plain text file you can read and edit directly. Anything you answered can be changed:
   >
   > - Edit the file directly for a quick change
   > - Run `/ai-governance-legal:cold-start-interview --redo` for a full re-interview
   > - Run `/ai-governance-legal:cold-start-interview --check-integrations` to re-check what's connected
   >
   > The sections most often adjusted after first setup are the use case registry and red lines, vendor AI review red lines, and the regulatory regimes in scope. Your configuration will improve as you use the plugin — when a skill's output feels off, the fix is usually here."

6. **Before your first triage**: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you.

<!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
     "Want a walkthrough? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - The `policy-monitor` agent watches for drift between your AI governance policy and your practice, and proposes updates.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## Failure modes

- **Don't let them skip the builder/deployer question.** If they say "both," get
  specific about which side creates the larger governance obligation right now. The
  skills work differently depending on the answer.
- **Don't assume any specific regime applies.** Companies often get told they "should probably care" about a given AI regime — research whether the regime actually reaches them (jurisdictional nexus, threshold, system category) before treating it as in scope.
- **Don't write a use case registry from generic positions.** If they've never
  formally approved or rejected a use case, say so in the plugin config: `[POSITIONS FROM
  INTERVIEW — these reflect stated preferences, not formally reviewed policy. Treat
  as starting points.]`
- **Don't skip the "I have nothing" path.** Some of the best-run teams haven't
  documented anything yet. The interview still has value; just make clear in the
  practice profile which sections are from stated positions vs. reviewed documents.
- **Don't merge this with the privacy interview.** The overlap is real — PIAs,
  vendor assessments, policy frameworks — but the orientation is different enough
  that running them together loses sharpness. If both plugins are being set up, run
  them sequentially.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/ai-governance-legal:customize`. They want to change something
in their practice profile — a risk posture, an escalation contact, a playbook
position, a jurisdiction, an output format — without re-running the whole
cold-start interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/ai-governance-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, jurisdictions, stage, practice
     setting *(shared across all 12 plugins — changes flow through
     `company-profile.md`)*
   - **Regulatory footprint** — EU AI Act, state AI laws, sector regulators in
     scope
   - **Risk posture** — conservative / middle / aggressive, what each means for
     triage and AIA output
   - **People** — governance team, AI risk owner, escalation chain, approvers
   - **Use case registry** — approved / conditional / never entries, and
     conditions attached to each
   - **AI system inventory** — per-system role (provider / deployer / etc.) and
     tier under the EU AI Act. Run `/ai-governance-legal:ai-inventory` for
     the dedicated editor.
   - **Vendor AI governance** — training-on-data, liability, model-change
     notice, and other positions in your vendor AI playbook
   - **AI policy commitments** — the public or internal commitments your AI
     policy has made, that the plugin cross-checks against
   - **Impact assessment house style** — AIA section order, risk scoring
     format, stakeholder framing
   - **Workflow** — intake path, output format, matter workspace paths, review
     cadence for the policy monitor
   - **Integrations** — what's connected (Slack, document storage,
     scheduled-tasks), what falls back

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples of downstream explanation:
   - *Risk posture middle → conservative:* "I'll flag more use cases as
     conditional rather than approved, surface more AIA follow-ups, and
     recommend more conservative vendor AI redlines."
   - *Adding an escalation contact:* "Every skill that routes escalations
     (`/use-case-triage`, `/vendor-ai-review`, `/reg-gap-analysis`) will now include this
     contact on the relevant risk bands."
   - *New use case registry entry:* "`/use-case-triage` will match against this entry
     on its next run. Existing AIAs aren't rewritten — re-run them if you want
     the new posture reflected."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/ai-governance-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" something, set it
  to `[Not configured]` and explain what that means for the plugin's behavior.
  ("Removing your escalation chain means `/use-case-triage` will flag escalation-worthy
  items but won't route them to a specific person.")
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., risk posture aggressive + escalation "everything goes to
  the GC"; or "EU AI Act in scope" + "no systems flagged for the EU"), flag
  the tension and ask which one they want.
- **Flag guardrail degradation.** If the user asks to turn off a guardrail
  ("stop adding the `[review]` flag," "drop the citations warning," "skip the
  privilege header"), explain what the guardrail protects against and confirm
  they understand the trade-off. Most guardrails are adjustable — a few are
  structural:
  - The `[review]` flag mechanism (tells the user when legal judgment is
    needed rather than a confident wrong answer) — load-bearing, don't
    remove.
  - Source attribution tags on retrieved content — load-bearing, don't remove.
  - `[verify]` tags on cited statutes/regulations — load-bearing, don't
    remove.
- **One change at a time.** Don't re-ask the whole interview. If the user
  wants multiple changes, handle them sequentially and confirm each before
  moving on.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/ai-governance-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/ai-governance-legal:matter-workspace list` — list matters with status and active flag
- `/ai-governance-legal:matter-workspace switch <slug>` — set the active matter
- `/ai-governance-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/_archived/`, never delete)
- `/ai-governance-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/ai-governance-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Use the workflow below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; the workflow above explains the disabled state and suggests `/ai-governance-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/ai-governance-legal/
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
   - **Matter type** (read the plugin's practice profile for typical categories; for ai-governance-legal: use case (internal) | vendor AI review | AIA | regulatory change | policy project | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/ai-governance-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/ai-governance-legal:matter-workspace new <slug>`.
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
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/policy-monitor', 'legal', 'policy-monitor', '', 'policy-monitor', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /policy-monitor

**Sweep mode** (no argument or `--sweep`):
1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → outputs folder path, AI policy document, last sweep date.
2. Use the framework below. Scan outputs folder for files since last sweep.
3. For each output: extract approved practices → diff against current policy commitments and use case registry.
4. Classify gaps: REQUIRED (policy misrepresents current practice) vs ADVISABLE (policy silent).
5. For each gap: quote current policy, describe gap, draft suggested language.
6. Flag any use cases in outputs not yet added to the `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` registry.
7. Present results to the human. Only after acknowledgment, update `Last policy sweep` and `gaps_found` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

**Direct query mode** (with description argument):
1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → current policy commitments, use case registry, actual policy document.
2. Parse proposed practice. Diff against policy: use case coverage, automation level, affected parties, disclosure, vendor data use, oversight.
3. Output: covered / missing / conflicting + suggested language for each gap + registry entry if needed + timing recommendation.

**Recurring runs:**
Set up a recurring reminder in your own scheduler to run `/ai-governance-legal:policy-monitor` weekly. Scheduled execution requires a scheduled-tasks integration, which is not bundled with this plugin.

```
/ai-governance-legal:policy-monitor
/ai-governance-legal:policy-monitor "We want to use AI to automatically flag expense reports for review"
```

---

## Purpose

AI policies drift from practice faster than almost any other policy document — the
field moves quickly, use cases multiply, and each approved AIA or triage result
represents a new commitment the policy may not have caught up with. An AIA approves
a new AI use case with a human-oversight condition. A vendor AI agreement permits
data processing the policy doesn't mention. A triage result marks a new category
of deployment as conditional with a disclosure requirement. The policy sits there
unchanged.

This skill catches the drift — either by crawling the outputs folder weekly, or by
answering the direct question: "we're about to start doing X, what does that mean
for our AI policy?"

The output is always the same: here's the gap, here's the suggested language.

---

## Load current state

Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`:
- `## AI policy commitments` — commitments extracted from the published policy
- `## Use case registry` — approved, conditional, and never use cases
- `## Outputs` — outputs folder path, AI policy document location, last sweep date

If `## Outputs` contains `[PLACEHOLDER]`:
> "Outputs aren't configured yet. I can still run a direct-query check — describe
> what you're planning to do and I'll diff it against your current AI policy. To
> enable the crawl sweep, run `/ai-governance-legal:cold-start-interview` and provide the outputs
> folder path."

Read the actual AI or acceptable use policy document from the path in `## Outputs`
→ **AI policy document**. The commitments in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` are a summary; the actual
document is authoritative for suggesting edits.

---

## Mode detection

**Sweep mode:** No argument, `--sweep`, or triggered by schedule.
→ Scan the outputs folder. Diff all outputs since last sweep against current policy.

**Direct query mode:** User provides a description of a proposed new AI practice.
→ Diff that practice against current policy and use case registry. Suggest updates.

---

## Mode 1: Sweep

### Determine scope

Read `## Outputs` → **Last policy sweep** date. Scan for output files in the
outputs folder dated after that date. If no date is recorded, scan all files and
note: "First sweep — scanning all outputs."

If the outputs folder is empty or has no new files since the last sweep:
> "No new outputs since [last sweep date]. AI policy appears current with recent
> practice. Next scheduled sweep: [date]."

**Do not update `Last policy sweep` or `gaps_found` automatically.** After the sweep results are presented, wait for the human to acknowledge them ("sweep acknowledged," "results reviewed," or equivalent). Only then update `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`:

- `Last policy sweep: [date of acknowledgment]`
- `gaps_found: [N]` (number of REQUIRED + ADVISABLE gaps found in that sweep)

Updating the stamp before acknowledgment would let an unreviewed sweep silently roll forward and suppress the next sweep's attention to the same gaps.

### What to read in each output type

**AIAs (AI Impact Assessments):**
- Extract: use case approved, AI system description, deployment mode (assistive /
  augmentative / automated), conditions imposed, affected parties, vendor used,
  any disclosure requirements to affected individuals
- Flag: use cases not in the registry, use cases approved with conditions not
  reflected in policy, vendor added that policy doesn't cover, automated decision
  deployed where policy implies human oversight

**Triage results (CONDITIONAL / APPROVED outcomes):**
- Extract: use case classified, tier assigned, conditions imposed
- Flag: new use case categories not in registry, conditions that imply policy
  commitments (e.g., "must disclose to affected parties" — does the policy say you
  do this?), newly approved practices that expand policy scope

**Vendor AI reviews (signed / approved):**
- Extract: vendor added, data use terms agreed to, any AI-specific provisions
  accepted that differ from standard positions in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`
- Flag: vendors added whose data use terms the policy should reference (e.g., "we
  use third-party AI services and ensure they do not train on our data"), approved
  deviations from standard positions that the policy implies you hold

**Use case registry updates:**
- If new entries were added to the registry since the last sweep (directly, not
  through an AIA), check whether the policy reflects those approved categories.

### Gap identification

For each flagged item, assess:

**REQUIRED update** — the policy makes a commitment that an output contradicts, or
an approved use case has no policy coverage and affects external parties. Not
updating creates a material misrepresentation.

> Example: AI policy says "we do not use AI in employment decisions." An AIA
> approved an AI-assisted hiring screening tool with human review required. Policy
> needs updating — even with human review, AI is now involved in employment
> decisions. "We do not use AI" is no longer accurate.

**ADVISABLE update** — policy is silent but not in conflict. The practice is
defensible without updating, but cleaner with it. Important when the practice
affects external parties or creates a reasonable expectation.

> Example: Policy says "we use AI to improve our products and services." An AIA
> approved an AI feature for customer support drafts. Policy technically covers it
> but is vague. Advisable to be more specific so customers know what they're
> interacting with.

### Sweep output format

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

*This sweep is derived from AIAs, triage results, and vendor AI reviews that carry the plugin's privilege/confidentiality marking. The sweep inherits that status. Distribute deliberately — forwarding gap findings outside the privilege circle can waive privilege on the underlying assessments.*

# AI Policy Monitor — Sweep Report

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
> *Add to / update [section name]:*
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

[List outputs scanned where no gaps were found]

---

## Use case registry sync

[Any use cases approved since the last sweep that aren't yet in the `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`
registry — suggest registry entries to add]

---

## Next steps

- [ ] Review REQUIRED updates — decisions needed before the associated use cases
  go live (or immediately if already live)
- [ ] Review ADVISABLE updates — lower urgency, address at next policy refresh
- [ ] Add new use cases to registry (if any flagged above)
- [ ] Next scheduled sweep: [date]
```

---

## Mode 2: Direct query

### Parse the proposed practice

Extract from the user's description:
- What AI system or capability is being introduced?
- What does it do — assistive, automated decisions, content generation?
- Who does it affect — employees, customers, third parties?
- Which vendor or model is involved?
- Is there human review, or is it fully automated?
- Are affected parties told the AI is involved?
- Any data flowing to a vendor that wouldn't be expected?

If the description is vague, ask one clarifying question. Don't run a long intake
— direct query mode should be fast.

### Policy diff

Check the proposed practice against the current policy and use case registry:

| Check | Current policy / registry | Proposed practice | Verdict |
|---|---|---|---|
| Use case category | [registry — approved / conditional / never / not present] | [new use case] | 🟢 Covered / 🟡 Gap / 🔴 Conflict |
| Scope of AI use | [what policy says AI is used for] | [new use] | |
| Automated decisions | [policy position on automation] | [is this automated?] | |
| Disclosure to affected parties | [what policy commits to] | [what this requires] | |
| Vendor data use | [policy position on vendor AI] | [this vendor's terms] | |
| Human oversight | [policy statement if any] | [what's actually in place] | |

### Direct query output format

```markdown
# AI Policy Check: [Proposed practice in one line]

**Bottom line:** [POLICY UPDATE REQUIRED / ADVISABLE / NO UPDATE NEEDED]

---

## What's covered

[Aspects of the proposed practice already addressed — brief, confirms no change needed]

## What's missing

### [Gap 1]

**Current policy:** [quote or "Silent"]
**What's needed:** [why this gap matters — legal, reputational, or expectation reason]

**Suggested language:**
> *Add to [section]:*
> "[Drafted text]"

### [Gap 2]
[same format]

## What conflicts

### [Conflict 1 — if any]

**Current policy says:** [quote]
**Proposed practice does:** [what conflicts]
**Resolution:** [which one needs to change — usually practice adjusts to match policy,
or policy is updated to a defensible new position; never silently accept both]

---

## Use case registry

[If this use case isn't in the registry: "Add to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → Use case registry:"]
```
| [use case] | [Approved/Conditional] | [conditions] | — |
```

---

## Timing

[REQUIRED: "Policy update should happen before this practice goes live — or
immediately if it's already running."
ADVISABLE: "Can proceed; update at next policy refresh."]
```

---

## Suggested language quality standards

AI policy language is unusually prone to becoming outdated — the field moves fast
and vague language ages better than specific commitments. When drafting:

- Match the voice and style of the existing policy (read the actual document)
- Prefer durable language: "AI-assisted" rather than naming specific models that
  will change; "automated or AI-assisted decisions" rather than technical descriptions
- Don't draft commitments the team can't keep — "we always have a human review
  AI outputs" is broken the moment one automated workflow ships
- When a policy position is genuinely changing (not just extending), say so
  explicitly: "This update reflects that we now use AI in [new category] — the
  previous language did not cover this."
- For disclosure language: draft it to be readable by the affected party (employee,
  customer), not just legally accurate

Always say which section to add to. If the right section doesn't exist, suggest
creating it and draft the header.

---

## Schedule integration

The weekly sweep is designed to run on a recurring cadence. Set up a recurring reminder in your own scheduler to run `/ai-governance-legal:policy-monitor` weekly. Scheduled execution requires a scheduled-tasks integration, which is not bundled with this plugin.

After each sweep, the **Last policy sweep** and **gaps_found** fields in `## Outputs` are updated only once the human has acknowledged the sweep results (see "Determine scope" above).

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't update the policy itself — it drafts suggested language and flags
  decisions, but a human reviews and approves every change.
- It doesn't catch incoming regulations — that's `reg-gap-analysis`. This skill
  monitors internal practice drift, not external legal changes.
- It doesn't enforce that outputs are saved — if AIAs and triage results aren't
  being saved to the configured folder, the sweep won't find them. Direct-query
  mode works without saved outputs.
- It doesn't read email, Slack, or informal decisions — only structured outputs
  saved to the configured folder.
- It doesn't update the use case registry automatically — it flags registry gaps
  and drafts entries for human review before adding.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/policy-starter', 'legal', 'policy-starter', '', 'policy-starter', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /policy-starter

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If the practice profile is unpopulated, stop and direct to `/ai-governance-legal:cold-start-interview`.
2. Use the framework below.
3. Run the scope interview — which sections does the policy need to cover, who's the audience, what's the deployment context. Do not skip to drafting.
4. Web search for the current published model policies and guidance relevant to the deployment context (ABA, state bars, ILTA, CLOC, NIST, peer-firm / peer-company policies, current state AI laws, EU AI Act, sector regulators as applicable).
5. Draft the selected sections, sourced from the model policies, with `[review]` flags on every choice point and `[review]` open questions at the bottom of each section.
6. Output with the draft header ("DRAFT FOR INTERNAL LEGAL REVIEW — NOT FOR DISTRIBUTION"), the sources block, the reviewer note, and the adoption checklist.
7. Close with the next-steps decision tree.

```
/ai-governance-legal:policy-starter
/ai-governance-legal:policy-starter "we need an AI policy for our 30-lawyer firm"
/ai-governance-legal:policy-starter "update our existing policy for the 2026 state AI laws"
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ai-governance-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

A lot of firms and in-house teams don't have a written AI usage policy yet, or
are running on a 2024-vintage one that doesn't mention the state AI laws, the EU
AI Act implementing acts, the 2025 COPPA amendments, or what they actually ended
up doing with Copilot and Claude for Work. This skill produces a **draft** policy
to bring to the decision-maker — GC, managing partner, executive committee,
board, head of IT, head of HR — not a finished policy to circulate.

The discipline of this skill:

1. **Source from published model policies, not from invention.** Search for and
   read the ABA AI Toolkit, state bar guidance, ILTA's model policy, CLOC's
   templates, and peer-firm / peer-company policies that are public. Cite what
   each source says and adapt it — don't generate policy language out of thin
   air.
2. **Decision-tree the scope before drafting.** A policy that tries to cover
   everything covers nothing. Ask the user what sections the policy needs. Let
   them pick. Then build each picked section with `[review]` flags on every
   choice point.
3. **Flag every judgment call.** The output is a draft the attorney reviews and
   adopts; every threshold, every named tool, every disclosure trigger, every
   enforcement consequence is a `[review]` line.
4. **Header signals the scope of the audience.** This output may be read beyond
   legal — by HR, IT, all staff. The header is adapted accordingly.

This skill does NOT finalize, distribute, publish, or even recommend a specific
position on the hard calls. It produces a draft and surfaces the choices.

## Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` first

Before drafting, always read the practice profile. The sections that drive the
draft:

- `## Company profile` — AI role (Builder / Deployer / Both), regulatory footprint,
  external commitments, practice setting
- `## Use case registry` — what's already approved, conditional, or a red line
- `## AI policy commitments` — what a prior or current policy already says
- `## Vendor AI governance` — what the team already requires from vendors
- `## Governance team and escalation` — who approves, who escalates
- `## Who's using this` — Role (lawyer / non-lawyer) governs the header and the
  "adopt this" framing

If `## AI policy commitments` is populated, this is an UPDATE, not a new draft —
treat the existing policy as the base and propose changes. If it's empty, this
is a first-cut draft.

## Scope interview (do this BEFORE drafting)

Ask the user which sections the policy should cover. Present as a checklist —
the user picks, you build. Do not pre-decide.

> **What should the AI policy cover? Pick the sections you want in the draft:**
> 1. **Scope** — who the policy applies to (all staff, certain roles, contractors), what tools it covers (GenAI only, all AI, specific vendors), what data is in/out of scope.
> 2. **Permitted and prohibited uses** — the approved categories, the red lines, the "ask first" cases.
> 3. **Approval and review** — who approves a new tool, who approves a new use case, how the review request is filed, what the SLA is.
> 4. **Disclosure** — to clients (for firms), to courts, to counterparties, to employees, to end users of an AI feature.
> 5. **Data handling** — what confidential/client/privileged data can go where, data residency, vendor retention terms, training-on-data posture.
> 6. **Training and certification** — who has to take training, on what cadence, consequences for non-completion.
> 7. **Incidents and reporting** — what counts as an AI incident, how to report, who handles.
> 8. **Enforcement** — what happens when the policy is violated, link to disciplinary framework.
> 9. **Review cadence and ownership** — how often the policy gets updated, who owns updates, how changes are communicated.
> 10. **Glossary** — defined terms (GenAI, approved tool, high-risk use, consequential decision, confidential data, etc.).
>
> Default starter pack for a firm / in-house legal team that's never had a policy: 1, 2, 3, 4, 5, 9. Skip the rest for v1.

After the user picks, ask the second question:

> **Two more inputs before I draft:**
> - **Audience** — who's reading this? (All staff / legal team only / attorneys plus staff / client-facing version also needed) This drives tone and the glossary.
> - **Deployment context** — (a) law firm, (b) in-house legal at a company (policy covers legal or company-wide?), (c) legal aid / clinic, (d) government. This drives which model policies I search.

## Source the model policies

Before drafting, run web searches for the most recent published model AI
policies and guidance.

**Derive the model policy sources from the practice profile's `## Regulatory footprint`.** Don't hardcode US sources for a global user.

| Jurisdiction | Model policy sources |
|---|---|
| US | ABA Formal Opinion 512, state bar guidance (CA, FL, NY, TX all have published AI guidance), ILTA model policy, CLOC templates, peer firm published AI policies |
| UK | Solicitors Regulation Authority risk outlook, Law Society AI principles, ICO AI guidance, Bar Council guidance |
| EU | EU AI Act compliance framework (Article 4 AI literacy, Article 17 quality management), national DPA AI guidance (CNIL, DSB, Garante, AEPD), EDPB guidelines, EU institutions' AI policies |
| Australia | Law Council of Australia AI guidelines, OAIC AI guidance, state law society guidance, Australian AI Ethics Framework |
| Singapore | PDPC Model AI Governance Framework, MinLaw guidance, MAS AI fairness principles (for financial services) |
| Canada | Law Society of Ontario/BC/Alberta AI guidance, OPC AI guidance, TBS Directive on Automated Decision-Making |
| Multi-jurisdiction | Use all applicable, and note where they diverge (e.g., EU requires human oversight documentation US doesn't; Australia focuses on voluntary ethics frameworks; Singapore focuses on sectoral regulation) |

If the practice profile's footprint is empty or `[PLACEHOLDER]`, ask: "What jurisdiction(s) does your organization operate in? I'll draft from the model policies that match your regulatory environment and professional responsibility framework, not a US-centric template."

For each source the draft uses, **record it in a "Sources" block at the top of
the output** with: name, URL, date accessed, and what the draft took from it.

If a web search can't be run, note in the reviewer note: "Could not run web
search — draft sourced from training knowledge alone, verify against current
versions of the cited sources before adopting." The verification log applies.

## The draft

Output follows a consistent structure. **Every choice point gets a `[review]`
flag.** The user has to decide; the skill presents options.

### Header

```
DRAFT FOR INTERNAL LEGAL REVIEW — NOT FOR DISTRIBUTION
Prepared for: [firm / company name from practice profile]
Date: [today's date]
Prepared by: ai-governance-legal policy-starter skill, adapted from published model policies
Not for adoption, distribution, posting, or reliance until reviewed, adapted, and approved by [attorney / GC / managing partner / executive committee per the governance team section of the practice profile].
```

When the Role in `## Who's using this` is Non-lawyer: add a second line under
the header — "If you are not a licensed attorney, solicitor, barrister, or other
authorised legal professional in your jurisdiction, bring this draft to your
attorney contact ([name from practice profile]) before using any of it. This is
a starting draft for their review, not a policy you can adopt."

### Sources block (at the top, under the header)

A table of the model policies / guidance / regulations the draft drew from:

| Source | URL | Accessed | What the draft took from it |
|---|---|---|---|
| ABA Formal Op. 512 | [url] | [date] | Disclosure and competence framing |
| ILTA Model AI Policy v.[X] | [url] | [date] | Approval workflow, data handling |
| [State] Bar Op. [X] | [url] | [date] | Disclosure to clients |
| [peer firm] published AI policy | [url] | [date] | Scope language |
| Colorado SB 24-205 | [url] | [date] | High-risk AI definition |
| EU AI Act, Art. [X] | [url] | [date] | Vendor flow-down |

### Executive summary

Three paragraphs max. What the policy does, who it binds, what the reader has
to do before it takes effect.

### The sections

Only the sections the user picked, in the order above. For each:

- A **header and scope** sentence.
- The **substantive rules**, adapted from the cited model policies. Every
  specific threshold, number, named tool, named vendor, or escalation contact
  is `[review]`. Example: "Confidential client data may not be entered into
  [general-purpose consumer AI tools] `[review — list tools, or reference the
  approved-tools list]`. Use of such data in [approved firm-licensed tools]
  `[review — list tools]` is permitted subject to the data handling section."
- **Source attribution** inline where a rule is adapted from a specific source.
  Example: "Attorneys must verify the accuracy of all AI-generated work product
  before using it in representation of a client `[ABA Formal Op. 512]`."
- **Open questions** at the bottom of each section — 2-3 decisions the attorney
  needs to make before the section is ready. These are distinct from inline
  `[review]` flags — these are the "we don't have a position here yet" items,
  not the "fill in the specifics" items.

### Adoption checklist

At the end of the draft, a checklist of the things that have to happen before
the policy is adopted. Don't invent these — pull from the practice profile's
governance team and escalation section. Typical items:

- [ ] Review by GC / managing partner `[review — name]`
- [ ] Review by IT / security `[review — name]`
- [ ] Review by HR (for enforcement / training sections) `[review — name]`
- [ ] Board / executive committee approval (if required) `[review — confirm whether required]`
- [ ] Training materials drafted
- [ ] Announcement drafted
- [ ] Effective date set `[review]`
- [ ] Review cadence calendared `[review — annual is typical]`
- [ ] Add policy to the `## AI policy commitments` section of the practice
      profile once adopted

### Reviewer note

The standard reviewer note above the header, per the `## Outputs` section of
the practice profile. Use the block format:

> **⚠️ Reviewer note**
> - **Sources:** web search ✓ / not connected — cites from training knowledge
> - **Read:** practice profile · [N] published model policies
> - **Flagged for your judgment:** [N] `[review]` items inline · [N] open questions per section
> - **Currency:** searched for developments since [date]
> - **Before relying:** this is a DRAFT — bring to [approver from practice profile], don't distribute until adopted

## Don'ts

- **Don't invent policy language.** Every substantive rule in the draft must be
  traceable to a cited source or flagged `[review — adapted, no direct source]`.
- **Don't pick the hard calls for the attorney.** "Should paralegals be
  permitted to use AI for first-draft work?" is a `[review]`, not a recommended
  position.
- **Don't produce a finished-looking policy.** The header, the reviewer note,
  and the `[review]` flags throughout are the signal that this is a draft. Do
  not soften them.
- **Don't skip the scope interview.** If the user says "just draft a full
  policy," push back: "A policy that tries to cover everything covers nothing.
  Which sections do you want? Here's the checklist." One round of negotiation
  is fine — two is also fine. Drafting without scope is the failure mode.
- **Don't generate section content the user didn't ask for.** If they picked 1,
  2, 3, 4, 5, 9, do those. Don't add section 6 because "a real policy needs
  training."
- **Don't recommend a specific vendor, tool, or consequence.** Flag those
  `[review]` with context on what a typical decision would be, not what the
  user's should be.
- **Don't promise legal sufficiency.** The draft is a starting point for
  attorney review, not a tested policy.

## Handoffs

After the draft is produced, close with the decision tree from the practice
profile. The most common next steps:

1. **Tune the draft** — the user walks through the `[review]` flags and resolves
   them with the attorney; the skill re-runs with the decisions baked in.
2. **Stakeholder summary** — produce a one-page version for the board or
   executive committee explaining what the policy does and doesn't do.
3. **Training materials** — once the policy is adopted, `/ai-governance-legal:aia-generation` can be used to produce per-use-case training notes.
4. **Vendor sweep** — once the policy is adopted, `/ai-governance-legal:vendor-ai-review` should be run against the vendors the policy references to check conformance.
5. **Gap check against new regulation** — pair with `/ai-governance-legal:reg-gap-analysis` to test the draft against a specific regulation or guidance before adoption.

## Output scope reminder

The document this skill produces reaches HR, IT, and the broader business — not
just legal. Keep the language plain enough for non-lawyers to follow. The legal
precision is in the `[review]` flags and the sources, not in jargon.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/reg-gap-analysis', 'legal', 'reg-gap-analysis', '', 'reg-gap-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /reg-gap-analysis

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. Confirm regulatory footprint and use case registry are populated.
2. Use the framework below.
3. Scope: does this regulation apply? (Jurisdiction, threshold, builder/deployer, sector.) If not, one line and done.
4. Extract requirements. Diff against current state in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
5. Prioritize gaps. Output: remediation plan with must-do / should-do / already compliant / accepted gaps.
6. Save as dated markdown doc for the file.

```
/ai-governance-legal:reg-gap-analysis "EU AI Act high-risk provisions"
```

---

## Purpose

The EU AI Act goes live. Colorado passes an AI law. The CFPB issues model risk
guidance. The FTC publishes an AI enforcement policy. Something moves — and now
you need to know what, if anything, you have to change.

This skill diffs the new requirement against your current AI governance posture
(per `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` — use case registry, vendor positions, impact assessment practices,
and AI policy commitments) and produces a gap list with a remediation plan.

The AI regulatory landscape is moving faster than any other area of law right now.
When a regulation is genuinely ambiguous, say so. Don't paper over uncertainty —
legal teams need to know when they're on solid ground versus when they're making a
judgment call.

## Load current state

Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`:
- `## Regulatory footprint` — what already applies
- `## Use case registry` — what AI you're actually running, and under what conditions
- `## AI policy commitments` — what you've publicly or contractually committed to
- `## Vendor AI governance` — what vendor positions are in place
- `## Impact assessment house style` — what assessment practices exist

If the regulation clearly doesn't apply (wrong jurisdiction, below threshold,
wrong sector, builder/deployer distinction eliminates you from scope), say so
directly: "Doesn't apply. Here's why: [reason]. No action needed."

---

## Research first, then workflow

Before running the gap analysis, research the currently operative AI regulatory regimes for the jurisdictions in the user's footprint. For each regime identify:

- **Scope** — who's covered (provider/builder vs. deployer vs. distributor vs. user; sectoral carve-outs).
- **Applicability thresholds** — revenue, user count, headcount, compute, model category, affected-population size.
- **Risk-tier definitions** — how the regime distinguishes tiers (prohibited / high-risk / limited-risk / minimal), what's in each.
- **Substantive obligations** — transparency, documentation, human oversight, bias testing, registration, incident reporting, vendor flow-down.
- **Enforcement mechanism** — which regulator, what penalties, any private right of action.
- **Effective dates** — many AI laws phase in obligations over 2-4 years; note which obligations are live vs. upcoming.

Cite the regulatory text with pinpoint references. Flag provisions subject to ongoing interpretation, delegated acts, or pending rulemaking. The AI regulatory landscape changes quickly — verify currency before advising.

Build the gap analysis from the researched requirements, not from hardcoded reference tables.

## Workflow

### Step 1: Scope the regulation

Before diffing, answer:

- **Does it apply?** Jurisdiction, threshold, sector carve-outs, builder vs. deployer distinction. Research the specific scoping rules in the regulation — don't assume.

  *Builder/deployer matters a lot here.* Many AI regimes impose different obligations on the entity that develops/provides the AI system versus the entity that deploys/uses it. Research which role the company occupies under each regime's definitions. Scope first; don't gap-analyze a law that doesn't apply.

- **When?** Effective date. Enforcement date (often different). Phase-in periods for specific provisions. Verify currency.

- **What's actually new?** Some "new" AI laws largely restate existing legal principles (consumer protection, anti-discrimination, sectoral risk management) applied to AI. Others are genuinely new obligations. Identify the delta from what you already do, not the full text of the law.

### Step 2: Extract requirements

Read the regulation, guidance, or summary. List every substantive requirement:

| # | Requirement | Citation | Category |
|---|---|---|---|
| 1 | [requirement] | [section] | [see categories below] |

**Categories:**
- **Transparency** — disclosures to users, employees, or affected parties about AI use
- **Impact assessment** — required documentation before deployment
- **Human oversight** — mandatory human review, override, or appeals mechanisms
- **Accuracy / testing** — bias testing, accuracy documentation, validation
- **Governance** — registration, record-keeping, designated responsible persons
- **Vendor flow-down** — obligations to pass down to AI vendors or pass up from AI vendors
- **Prohibited practices** — outright bans on specific AI capabilities or uses
- **Rights** — what affected parties can request or invoke

### Step 3: Diff against current state

For each requirement:

```markdown
### [Requirement #N]: [short name]

**Regulation says:** [requirement, quoted or paraphrased]

**We currently:** [what `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` / AI policy / use case registry / assessment
practice shows]

**Gap:** [None | Partial | Full]

**If partial/full — what's missing:** [specific — not "more documentation" but
"no human review step is documented for [use case category]"]

**Effort to close:** [Policy update only | Process change | Product/system change |
New assessment required | Vendor renegotiation | Registration / filing]

**Risk of non-compliance:** [penalty range, enforcement likelihood, reputational]
```

### Step 4: Prioritize

Not every gap is equal. Sort by:

1. **Hard deadline with teeth** — effective date + active enforcement + real penalties
2. **Prohibited practice** — if the gap is a prohibition, not a process requirement,
   that's the first priority regardless of enforcement date
3. **Effort-to-impact ratio** — updating policy language is cheap; adding human
   oversight to a deployed system is not
4. **Use case overlap** — gaps that affect multiple use cases in the registry are
   higher priority than single-use-case gaps

### Step 5: Remediation plan

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Remediation Plan: [Regulation name]

**Effective date:** [date]
**Enforcement begins:** [date if different]
**Applies to us as:** [Builder / Deployer / Both]

### Must-do before enforcement

| Gap | Fix | Owner | Due | Status |
|---|---|---|---|---|
| [gap] | [specific fix] | [name] | [date] | [ ] |

### Should-do (important but not blocking enforcement)

[same table]

### Already compliant

[list of requirements where gap = None — useful context for the legal/executive
summary of where you actually stand]

### Accepted gaps (risk accepted, not fixing)

[if any — with documented rationale and who accepted the risk. Documenting accepted
risk is better governance than leaving it unaddressed silently.]
```

---

## Research the regulation before building the gap analysis

Do not rely on hardcoded reference tables for specific regimes. For each regulation in scope, research the currently operative text:

- Which obligations apply to the company's role (provider/builder, deployer, importer, distributor)?
- Which tier does the system fall into under the regime's own classification (prohibited / high-risk / limited-risk / minimal, or the regime's equivalent)?
- What are the live vs. phase-in dates for each obligation?
- Are there delegated acts, implementing acts, or regulator guidance that affect interpretation?
- For builder contexts: are there model-level obligations (technical documentation, training data transparency, copyright compliance, systemic-risk testing)?
- For prohibited-practice categories: check any use case in the registry that might touch them and flag as critical regardless of enforcement date.

Cite primary sources with pinpoint references. Flag ambiguity for attorney judgment.

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, EUR-Lex, regulator sites, or firm platform) returns few or no results for a regime's text, delegated act, or guidance, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the gap analysis with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 22, the existence of Regulation (EU) 2024/1689 as the EU AI Act, Colorado AI Act as C.R.S. § 6-1-1701 et seq.). Still verify before filing, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific delegated / implementing acts, regulator guidance, standards, enforcement actions, case holdings, thresholds, effective dates, phase-in provisions, harmonized-standards references.
> - `[verify-pinpoint]` — pinpoint citations (specific article numbers, annex references, subsection letters, paragraph numbers, standard-clause references) carry the highest fabrication risk and should ALWAYS be verified against a primary source. EU AI Act article numbers in particular shifted during consolidation; every pinpoint cite to the Act should be verified against the Official Journal text.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[EUR-Lex]`, `[regulator site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.
>
> **For non-lawyer users, uncertain dates, thresholds, and phase-in provisions go in a confirm-list, not inline.** A `[verify]` tag on "effective February 1, 2026" reads as "effective February 1, 2026" to a non-lawyer who doesn't know what the tag means. Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If Role is **Non-lawyer** and a date, deadline, phase-in, threshold, or effective-date assertion is uncertain (would carry `[verify]` or `[verify-pinpoint]` if inline), replace the inline assertion with "effective date: confirm with counsel" (or "threshold: confirm with counsel") and collect all uncertain items in a final gap-analysis section titled: "**Things I'm not certain about — ask your attorney to confirm before relying on this:**" with each item listed (what I said, what's uncertain, why it matters to the gap). Lawyer-role users keep the inline `[verify]` treatment.

---

## Integration with other skills

**From aia-generation:** AIAs flag regulatory obligations for specific
systems → those feed here when a regulation is new or coverage is uncertain.

**From use case triage:** Newly triaged use cases that hit regulatory triggers →
gap analysis runs on the specific requirement for that use case type.

**To regulatory-legal plugin, if the plugin is installed:** This skill is the manual
version. The monitor plugin watches feeds and triggers this analysis automatically
when something relevant changes.

---

## Output

Save as a dated markdown doc. The remediation plan table becomes a tracker — update
status as items close.

If the gap analysis concludes "no gaps, we're compliant," still write the doc. It's
useful evidence that you looked, and useful baseline when the regulation is amended.

**Cite check before relying on this.** Citations here were generated by an AI model and have not been verified against primary sources. Before relying on any citation — statute, regulation, delegated act, guidance, or case — run a verification pass against a legal research tool (Westlaw, CourtListener, or your firm's platform) for accuracy, currency, and subsequent history. Fabricated or misquoted citations in filed materials have resulted in sanctions. Source tags on each citation (e.g., `[EUR-Lex]`, `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't interpret ambiguous regulatory language authoritatively. The EU AI Act
  in particular has significant interpretive questions that aren't resolved yet.
  When the reg is genuinely ambiguous: say so, state the conservative read, and
  flag for outside counsel if the issue is material.
- It doesn't track regulatory changes proactively. It runs when you point it at a
  change. For proactive monitoring, see the `regulatory-legal` plugin, if the plugin is installed.
- It doesn't implement fixes. It plans them.
- It doesn't substitute for sector-specific legal counsel where specialized knowledge
  is required (healthcare AI, financial services model risk management, etc.).$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/use-case-triage', 'legal', 'use-case-triage', '', 'use-case-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /use-case-triage

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. Confirm registry is populated — if not, stop and direct to setup.
2. Use the framework below. Clarify the use case if vague.
3. Registry lookup → red line check → classify.
4. Output: classification, reasoning, conditions table (if conditional), governance tier, cross-plugin handoffs.
5. Propose registry update if use case wasn't already in the registry.

```
/ai-governance-legal:use-case-triage "Sales team wants to score leads with AI automatically"
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ai-governance-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Stop the conversation that happens in a hallway and starts as "can we just use AI
for this?" Give a fast, calibrated answer from the registry — and if the answer
is conditional, make the conditions concrete and the next step obvious.

The triage skill is a gateway, not a destination. Its job is to classify, flag
what's required, and route. The aia-generation skill does the deep work.

## Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` first

Before triaging, always read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. The use case registry and red lines there
are authoritative. Generic AI ethics reasoning is not a substitute for what this
company has actually decided.

If `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` contains `[PLACEHOLDER]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor the use case registry, red lines, and governance tiers to your practice.
>
> **Two choices:**
> - Run `/ai-governance-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll triage tailored to YOUR practice.
> - Say **"provisional"** and I'll triage against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run triage normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no registry (classify by general AI governance principles rather than matching to a registered entry). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/ai-governance-legal:cold-start-interview` to get output calibrated to YOUR practice — your registry, your jurisdiction, your risk appetite. 2 minutes."

**Jurisdictional scope.** Triage applies the registry, red lines, and governance tiers configured for the regulatory footprint in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. AI rules vary materially by jurisdiction — an APPROVED classification in one footprint may be CONDITIONAL or prohibited in another. If deployment touches a jurisdiction not in the footprint, surface that and re-triage rather than extending by analogy.

---

## Triage process

### Step 1: Understand the use case

Before classifying, make sure you understand what's actually being proposed. If
the description is vague, ask:

- "What is the AI doing, exactly — generating content, making a decision, surfacing
  recommendations, automating a task?"
- "Who or what is the AI acting on — employees, customers, third parties, internal
  data only?"
- "Is a human reviewing the AI output before anything happens, or is it automated?"
- "Which vendor or tool is being proposed?"
- "Is this internal-only, or does it touch customers or other external parties?"

Don't let "we want to use AI for [vague thing]" go untriaged. Get specific enough
to classify accurately.

---

### Step 2: Registry lookup

Check the use case registry in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` for a direct or close match.

**Direct match:** If the registry has a directly matching entry, apply it.

**Near match:** If the use case is similar to a registry entry but not identical,
flag this: "This looks like [registered use case] — I'm applying that classification,
but if the scope is meaningfully different, it may need its own assessment."

**No match:** If the use case isn't in the registry, default to CONDITIONAL pending an AI impact assessment. Surface the preliminary read on risk and route to the AIA.

> "This use case isn't in your registry yet. Defaulting to CONDITIONAL pending an
> AI impact assessment. Here's my preliminary read on risk: [preliminary read].
> Next step: run the impact assessment, and I'll add the use case to the registry
> once classification is settled."

---

### Source attribution (applies whenever the triage cites regulation)

Triage typically stays high-level, but if the classification depends on citing a regulation, statute, rule, directive, standard, or guidance — tag the citation. Do not output untagged regulatory citations in the triage reasoning, the red-line explanation, or the conditions list. A triage that says "Art. 22(1)" without a tag is exactly where a fabricated pinpoint slips past the reader.

**Source attribution tiering.** For model-knowledge citations, use one of three tiers:

- `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 22 as a concept, the existence of Regulation (EU) 2024/1689 as the EU AI Act). Still verify before certifying, but lower priority.
- `[verify]` — model-knowledge citations that are real but should be verified: specific delegated / implementing acts, regulator guidance, standards, effective dates, thresholds, post-2023 amendments.
- `[verify-pinpoint]` — pinpoint citations (specific article numbers, annex references, subsection letters, paragraph numbers) carry the highest fabrication risk and should ALWAYS be verified against a primary source. EU AI Act article numbers in particular shifted during consolidation; every pinpoint cite to the Act should be verified against the Official Journal text.

Other sources keep their own tags: `[registry]` when drawn from the practice profile's use case registry; `[Westlaw]`, `[EUR-Lex]`, `[regulator site]`, or the MCP tool name when retrieved from a connected legal research tool; `[web search — verify]` for web-search citations; `[user provided]` for user-supplied citations. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

**For non-lawyer users, uncertain dates and thresholds go in a confirm-list, not inline.** A `[verify]` tag on "effective February 1, 2026" reads as "effective February 1, 2026" to someone who doesn't know what the tag means. Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If Role is **Non-lawyer** and an effective date, phase-in, threshold, or deadline is uncertain (would carry `[verify]` or `[verify-pinpoint]` if inline), replace the inline assertion with "effective date: confirm with counsel" (or "threshold: confirm with counsel") and collect all uncertain assertions in a final triage section titled: "**Things I'm not certain about — ask your attorney to confirm before relying on this:**" with each item listed (what I said, what's uncertain, why it matters). Lawyer-role users keep the inline `[verify]` treatment.

---

### Step 3: Red line check

Before going further, check the red lines in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

If the use case triggers a red line — even partially, even in a charitable reading —
say so immediately.

> "This use case touches [red line]. Your red lines treat this as an automatic no.
> If there's something different about this situation, that's a conversation for
> legal sign-off — not a triage call."

Do not soften red line outcomes. If it's a no, it's a no.

---

**Jurisdictional scope.** Ask: "Who's affected, and where are they? (Employees / customers / the general public / specific groups.) Which jurisdictions? (Not just where your company is — where the affected people are.)"

Then check the use case against EVERY regime in the practice profile's `## Regulatory footprint`, not just the primary one. Flag conflicts:
- "APPROVED under US law, but triggers EU AI Act Article 27 FRIA if EU residents are affected — confirm whether any affected individuals are in the EU."
- "Standard tier under your governance framework, but NYC LL144 requires a bias audit if used for hiring decisions affecting NYC residents."
- "Low risk under Australian AI Ethics Framework, but may be high-risk under the Colorado AI Act if Colorado residents are affected."

A use case that crosses jurisdictions gets the strictest applicable treatment, not the most convenient one.

---

### Step 4: Classification and output

The APPROVED / CONDITIONAL / NOT APPROVED buckets, the red-line definitions, and the CONDITIONAL required-controls list all come from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## AI use case triage criteria` and `## Use case registry`. If the playbook doesn't define a criterion the use case turns on, ask the user: "Your playbook doesn't cover [specific question]. What's your default position? I'll add it to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` so the next triage is consistent."

**Before issuing an APPROVED classification (approving an AI use case for deployment):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Approving this use case for deployment has legal consequences. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the use case and its scope, how it maps to the registry, what policies or red lines it touches, what could go wrong in deployment, what to ask the attorney before green-lighting.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. CONDITIONAL outputs do not require the gate.

**Before issuing a NOT APPROVED classification that cuts off a proposed use case:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If the Role is Non-lawyer, a symmetric gate applies — wrongly rejecting a use case is also a consequential error, and the business will push back regardless of the triage call:

> This is a full stop for a business ask. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the use case and its scope, the specific red line or registry entry that blocks it, what a narrower version could look like that might clear elevated tier (if anything), what the business will likely ask the attorney for, and the three questions to ask the attorney before accepting the no.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. A non-lawyer issuing a hard no on the AI plugin's behalf, without an attorney in the loop, is the mirror failure of a non-lawyer issuing a hard yes.

**Format for each triage output:**

---

[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

**USE CASE:** [State the use case as you understand it]

**CLASSIFICATION:** [APPROVED / CONDITIONAL / NOT APPROVED]

**Registry match:** [Direct match / Near match — [name] / No match]

**Reasoning:**
[1-3 sentences on why this classification. If approved, what makes it safe. If
conditional, what creates the risk that conditions are managing. If not approved,
what red line or policy position applies.]

**Red lines triggered:** [None / List any that apply]

---

*If CONDITIONAL — required before proceeding:*

| Requirement | Owner | Done? |
|---|---|---|
| [e.g., AI impact assessment] | [AI governance counsel] | ☐ |
| [e.g., Privacy review / PIA] | [Privacy counsel] | ☐ |
| [e.g., Human-in-the-loop requirement — no automated decisions] | [Product] | ☐ |
| [e.g., Disclosure to affected parties] | [Product / Legal] | ☐ |
| [e.g., Specific vendor only — [approved vendor name]] | [Procurement] | ☐ |
| [e.g., Legal sign-off] | [GC] | ☐ |

**Governance tier:** [Standard / Elevated / High — per `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`]

**Approval path:** [Who needs to sign off, per tier]

**Next step — offer to continue:**

After presenting a CONDITIONAL result, always end with:

> "Want me to start the impact assessment now? I can run the intake questions
> and produce the assessment document without you needing to run a separate command."

If they say yes, load the `aia-generation` skill and continue in the same
conversation — no need to restart. Pass the use case description and governance
tier already determined.

If they say no (or don't respond), the triage result stands as a standalone output.
The AIA can be run any time with:
`/ai-governance-legal:aia-generation [use case]`

---

*If NOT APPROVED:*

**Reason:** [Specific red line, policy prohibition, or registry entry]

**If there's a version of this that could work:** [Optional — "A narrower version
that keeps a human in the loop for every adverse decision might clear the elevated
tier. That would require..."] Only include if genuinely true. Don't offer a workaround
for every no.

---

### Step 5: Cross-plugin handoffs

**Privacy handoff:** If the use case involves personal data — employee data,
customer data, behavioral data — flag it:

> "This use case involves personal data. A PIA is likely required in addition to
> an AI impact assessment. Use `/privacy-legal:pia-generation [use case]`, if the
> plugin is installed, to run that in parallel."

**Product counsel handoff:** If this is a new product feature involving AI:

> "If this use case is part of a product launch, loop in product counsel.
> Use `/product-legal:launch-review`, if the plugin is installed — it will detect
> the AI component and route to this plugin."

Only flag handoffs that are actually relevant. Don't append both as boilerplate
to every triage.

---

### Step 6: Registry update suggestion

If this triage resulted in a classification that isn't in the registry yet — either
a no-match or a near-match that revealed a gap:

> "I'd suggest adding this to your use case registry. Proposed entry:"

```
| [Use case description] | [Approved/Conditional/Never] | [Conditions if any] | [Reason if Never] |
```

> "Add to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → Use case registry. This means next time the same request
> comes up, the answer is documented and consistent."

---

## Batch triage

If the user presents multiple use cases at once — a list, a backlog, a product
roadmap — run through each one and output a summary table first, then expand
each conditional or not-approved entry:

| # | Use case | Classification | Key condition / blocker |
|---|---|---|---|
| 1 | [use case] | 🟢 Approved | — |
| 2 | [use case] | 🟡 Conditional | Impact assessment required |
| 3 | [use case] | 🔴 Not approved | Automated adverse decision — red line |

Then expand each row that isn't a clean approved.

---

## Edge cases and failure modes

**"We're already doing this" triage:**
If someone is asking for retroactive triage — the use case is already deployed —
say so plainly, and before classifying from scratch, search the registry for an
existing entry covering the deployed version. Retroactive triages often surface a
superseded registry entry whose conditions have drifted from current practice;
updating that entry is usually the right follow-up rather than adding a new row.
> "This looks like retroactive triage. If this is already running without an
> assessment, that's a gap to document, not to wave through. I'm searching the
> registry for any existing entry covering this deployment before running the
> triage fresh. Here's the classification: [run normal triage]. If it's
> conditional, those conditions should be confirmed in place now, not assumed.
> If the registry has an existing entry and the deployed version has drifted,
> the right follow-up is updating that entry rather than adding a new one."

**"It's just internal" doesn't change the analysis:**
Internal AI use affecting employees (screening, monitoring, evaluation) is often
higher-risk than customer-facing AI. Flag this if the user implies internal scope
reduces risk.

**"The vendor says it's safe":**
Vendor representations don't substitute for your own impact assessment. Flag it:
> "The vendor's position doesn't substitute for your own assessment — especially
> for anything in the elevated or high tier."

**"We're just piloting":**
A pilot that touches real employee or customer data is not exempt from triage or
impact assessment. Apply the same classification; if conditions include an impact
assessment, the pilot should have one too.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/vendor-ai-review', 'legal', 'vendor-ai-review', '', 'vendor-ai-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /vendor-ai-review

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. Confirm vendor governance positions are populated — if not, stop and direct to setup.
2. Use the framework below.
3. Confirm document type (AI addendum / main agreement AI provisions / ToS). If only an AUP was provided, ask for the full terms.
4. Term-by-term review: training on data, confidentiality of inputs, model changes, output IP, liability, incident notification, human review rights, use restrictions, audit rights.
5. AI addendum gap check if DPA exists but no AI addendum.
6. AI policy consistency diff vs. `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
7. Output: bottom line, term-by-term, recommended redlines, if-they-won't-move routing.

```
/ai-governance-legal:vendor-ai-review openai-enterprise-agreement.pdf
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ai-governance-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Vendor AI terms are where your governance positions actually get tested. The cold-start
interview captures what you *want*. This skill checks what you *agreed to* — and flags
the gaps between those two things.

The direction here is always the same: we are the deployer or buyer reviewing the
vendor's terms. This is the opposite posture from the DPA review controller/processor
question — there's no flip.

What varies is the *input*:
- A standalone AI agreement or AI addendum (most structured)
- A vendor's universal terms of service with AI provisions embedded (often buried)
- An acceptable use policy (tells you what you can't do; says nothing about what
  the vendor can do with your data or outputs)
- A combination — master agreement + DPA + AI addendum (common for serious enterprise
  AI vendors)

When there's a DPA already in place, this review complements it — it's not a
substitute. The DPA governs data protection obligations; the AI terms govern
model-specific rights and risks. Both need to be reviewed.

---

## Load the playbook

Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## Vendor AI governance`. Also read `## AI policy commitments`
— vendor terms can't be consistent with a use restriction our own policy imposes if
we've agreed to something different.

If `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` contains `[PLACEHOLDER]`, surface this bounce:

> I notice you haven't configured your practice profile yet — that's how I tailor vendor governance positions to your practice.
>
> **Two choices:**
> - Run `/ai-governance-legal:cold-start-interview` (2 minutes) to configure your profile, then I'll review tailored to YOUR positions.
> - Say **"provisional"** and I'll review against generic defaults — US jurisdiction, middle risk appetite, lawyer role, no playbook — and tag every output `[PROVISIONAL — configure your profile for tailored output]` so you can see what I do before committing.

### Provisional mode

If the user says "provisional," run the vendor AI review normally using these generic defaults: middle risk appetite, lawyer role, US jurisdiction, no playbook (flag all common vendor-AI risks from first principles rather than matching to configured positions). Tag the reviewer note and every finding block with `[PROVISIONAL]`. At the end of the output, append:

> "That was a generic run against default assumptions. Run `/ai-governance-legal:cold-start-interview` to get output calibrated to YOUR practice — your vendor governance positions, your jurisdiction, your risk appetite. 2 minutes."

---

## Before reading the document

If the user hasn't shared the actual vendor terms, ask:

> "Can you share the vendor's AI terms? The most useful thing is the actual contract
> language — the AI addendum if there is one, or the main agreement with AI provisions
> highlighted. An acceptable use policy alone won't tell us what the vendor can do
> with our inputs; it only tells us what we're allowed to do."

If they share an acceptable use policy only:
> "This is the acceptable use policy — it tells us what we can't do with the vendor's
> AI. That's useful context, but it doesn't address the commercial terms: whether
> the vendor can train on our data, what their liability is for AI errors, whether
> they notify us when the model changes. Do you have the service agreement or AI
> addendum?"

---

## The term-by-term review

### Core AI-specific terms (check every vendor AI agreement)

Review each term below. For each, extract what the vendor's contract actually says and compare it against the position in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## Vendor AI governance` (standard / acceptable fallback / automatic no). The default positions come from the team's playbook, not from this skill.

| Term | What to look for |
|---|---|
| **Training on our data** | Does the vendor use our inputs to train, fine-tune, or improve models? Is there an explicit opt-out or prohibition? Is training opt-in or opt-out by default? |
| **Confidentiality of inputs** | Are our prompts, documents, and data confidential? Any "quality review" or human-review carveouts that would let vendor staff read inputs? |
| **Model changes** | Any notice obligation for material changes to the model? Version pinning available? |
| **Output ownership / IP** | Who owns AI-generated content? Any license-back to the vendor on outputs? Any IP indemnity? |
| **Liability for outputs** | Does the vendor accept any liability if the AI produces harmful, incorrect, or infringing outputs? Cap structure? Carve-outs? |
| **Incident notification** | How and when are we notified if the AI system fails, is compromised, or produces systematic errors affecting us? |
| **Human review rights** | Can we require human review of outputs in specific cases? Can we appeal or dispute an AI decision? |
| **Use restrictions** | What are we prohibited from doing? Does it match what we actually want to use the tool for? Any definitional terms (e.g., "automated decision-making") that could sweep in our intended uses? |
| **Audit / auditability** | SOC 2, third-party audits, bias testing results — any audit rights? |
| **Subprocessors / model providers** | Does the vendor use sub-vendors for the model? Are they disclosed? Whose terms govern? |
| **Data residency** | Where is our data processed? Where does it go for inference? |
| **Term and termination** | What happens to our data when we terminate? Deletion timelines? |
| **Stacked-vendor accountability** | Is this vendor the model provider (e.g., Anthropic, OpenAI, Google, Meta), or are they a deployer of someone else's model (e.g., a SaaS wrapper of Claude, ChatGPT, or Gemini) or a reseller of infrastructure-hosted foundation models (Anthropic-on-Bedrock, Claude-on-Vertex, OpenAI-on-Azure)? If the latter: there are TWO vendors' terms in play — the one you're reviewing, plus the upstream model provider's terms. Identify (a) whose terms govern training on inputs, retention, and safety, (b) who is contractually liable for model behavior, and (c) whether each upstream commitment (e.g., "no training on inputs") is flowed down to you, or remains between the vendor and the upstream provider only. Flag any clause where one party disclaims responsibility for the other (e.g., "Anthropic is not responsible for Bedrock or any other services it receives from AWS"; "Azure disclaims responsibility for OpenAI model outputs") and whether the counter-party's contract closes the gap. Do not review the two contracts in isolation. |

If `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` doesn't define a position for a term on this list, ask: "Your playbook doesn't cover [term]. What's your default position, your acceptable fallback, and your automatic no? I'll add it to `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` so the next review is consistent."

---

## Playbook comparison

For each term above, compare what we found to the positions in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

**Output format for each term:**

> **[Term name]**
> 🟢 / 🟡 / 🟠 / 🔴
> **Vendor says:** [summary of what the contract actually says]
> **Our position:** [from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`]
> **Gap:** [specific delta — or "Aligned"]
> **Proposed fix:** [specific redline language, or "escalate — outside fallback"]

Use the severity ratings consistently (calibrated against `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` positions):

- 🟢 **Aligned** — at or better than the standard position in the playbook.
- 🟡 **Note** — within fallback but worse than standard; flag for awareness, not a blocker.
- 🟠 **Significant** — outside standard position but within fallback; needs redline before signing.
- 🔴 **Critical** — outside fallback; deployment should not proceed without resolution. Escalate per `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

---

## AI addendum gap check

**If the vendor has a DPA but no AI addendum:**

> "There's a DPA in place but no AI-specific addendum. The DPA covers data protection
> obligations but doesn't address: training on our data, model change notification,
> liability for AI outputs, or incident notification for AI system failures.
>
> For a [Standard / Elevated / High] tier use case, this gap is [acceptable at
> Standard tier / a blocker at Elevated or High tier]. Recommend requesting an
> AI addendum or at minimum negotiating AI-specific terms into the next renewal."

**If there are no AI terms at all:**

> "There are no AI-specific terms in this agreement. The vendor is providing an
> AI-powered service under general service terms — which means we have no
> contractual protection on the highest-risk AI governance items (training, liability,
> model changes). This is a 🔴 for any Elevated or High tier use case."

---

## AI policy consistency check

Cross-check the vendor's terms against our AI policy commitments in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

Common conflicts:
- Our policy prohibits vendor training on our data — the vendor's terms permit it by
  default. (Contract needs explicit prohibition or opt-out confirmation.)
- Our policy requires human review for certain use cases — vendor's terms say AI outputs
  are final. (Workflow needs to impose the human step, not the vendor terms.)
- Our approved vendor list doesn't include this vendor — or blocklist does.
- Our policy requires disclosure to affected parties — vendor's terms impose a
  confidentiality obligation on AI system capabilities that would prevent disclosure.

Flag every mismatch. One of them has to change.

---

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

**Before recommending signature of a vendor AI agreement (the version the company will execute):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Signing this vendor AI agreement has legal consequences. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the vendor and the use case, the key terms reviewed (data use, liability, auditability, model change, human review), where vendor positions diverge from policy, what's being accepted, what could go wrong, what to ask the attorney.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. Review/redline drafts for attorney consideration do not require the gate — signature does.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

*This review is derived from vendor contract terms that are typically confidential under NDA, and it may itself be privileged. It inherits the source's confidentiality and privilege status. Distributing it beyond the privilege circle (e.g., forwarding to the vendor, sharing in an open channel) can waive privilege and breach the NDA. Mark, store, and route accordingly.*

# Vendor AI Review: [Vendor Name]

**Document reviewed:** [AI addendum / main agreement AI provisions / ToS]
**Reviewed:** [date]
**Use case(s):** [what we're deploying this vendor's AI for]
**Governance tier:** [Standard / Elevated / High]

---

## Bottom line

[Two sentences. Can we deploy under these terms? What has to change first?]

**Issues:** [N]🔴 [N]🟠 [N]🟡 [N]🟢

---

## Term-by-term

[For each term above — vendor position, our position, gap, severity, proposed fix]

---

## AI addendum status

[Present / Absent — and what that means for this deployment]

---

## AI policy consistency

[🟢 Consistent | 🟡 Flags: list]

---

## Recommended redlines

[Consolidated draft redlines. Review with counsel before sending externally. For critical
issues where no fallback exists, flag for escalation rather than proposing language.]

---

## If they won't move

[For each 🔴 and 🟠: the fallback from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`, or "escalate — outside fallback"
and routing per escalation table]
```

---

## Practical notes

**The training-on-data clause is the one most people miss.**
Vendor AI terms have historically varied widely on whether API inputs can be used
to train or improve models — some vendors permit it by default, others prohibit it,
and many have changed their position over time. Do not assume any particular vendor's
current stance without reading the specific agreement in front of you. This is almost
always the most important term for any company with confidential or sensitive data,
and it must be confirmed in writing, not assumed from reputation or prior experience.

**Map the AI stack.** Modern AI deployments are layered. Before reviewing terms, map the layers:
1. **End-user SaaS application** (e.g., a legal tech tool, a CRM with AI scoring, a document assistant) — the tool your org signs up for
2. **API gateway / orchestration layer** (e.g., Azure OpenAI Service, AWS Bedrock, Google Vertex, LangChain-hosted) — often invisible, always has its own terms
3. **Model provider** (e.g., Anthropic, OpenAI, Google, Meta) — the LLM
4. **Hosted knowledge base / RAG source** (e.g., a vector database, a third-party data corpus, a retrieval service) — the data Claude reads from
5. **Additional subprocessors** — analytics, logging, fine-tuning partners

Ask: "Walk me through the stack — what does [SaaS tool] use under the hood? Is it built on a cloud AI service? Does it call a model provider directly or through a gateway? Does it use a hosted knowledge base?" Then review terms at EACH layer, not just the top.

Each handoff between layers is a flow-down risk. A commitment at layer 1 ("we won't train on your data") means nothing if layer 3's terms say otherwise and layer 1 never flowed the commitment down.

**Flow-down test.** For each flagged stacked-vendor term — especially training-on-data, data retention, subprocessor changes, and liability — don't just flag "check upstream terms." DO THE CHECK:

1. **Search the contract for flow-down language.** Look for: "subprocessor obligations no less protective than," "flow-down of data commitments," "back-to-back terms," "Provider shall ensure that its subprocessors are bound by," "equivalent obligations."
2. **If present:** Quote it, verify it covers the specific flagged term, and flag whether it's enforceable (who can enforce it — you, or only the intermediate vendor?).
3. **If absent:** Produce a specific redline requiring it:
   > "Add to §[X]: Provider shall ensure that any third-party model providers, infrastructure providers, or subprocessors used in delivering the Services are bound by obligations with respect to [Customer Data / AI training / data retention / confidentiality] no less protective than those set forth in this Agreement, and shall be responsible for any breach of this Agreement caused by such third parties."
4. **Flag the gap with a severity:** 🔴 if the term is training-on-data or liability and there's no flow-down; 🟡 if the term is less sensitive or there's partial flow-down.

"Escalate and check upstream" is where compliance dies. Produce the test and the redline.

**Acceptable use policies flip the frame.**
AUPs tell you what you can't do; they don't tell you what the vendor can do.
Don't let a clean AUP review substitute for reading the data use and liability terms.

**Renewals are leverage points.**
If the current agreement is unfavorable and the vendor won't renegotiate mid-term,
document the gaps now and flag them for the renewal. Flag to procurement:
"This renewal should not close without AI addendum addressing [list]."

**Builder context adds a layer.**
If the company is a builder using a vendor's model as a foundation, the vendor's terms
also govern what the company can offer its own customers. Some terms prohibit certain
downstream uses. Check use restrictions against the product roadmap, not just current
internal workflows.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't review the DPA provisions of the same agreement — run
  `/privacy-legal:dpa-review`, if the plugin is installed, for that.
- It doesn't decide whether to accept terms outside the fallbacks. It routes those
  per the escalation table in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
- It doesn't evaluate vendor security posture beyond what's in the agreement —
  that's a security team function.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/amendment-history', 'legal', 'amendment-history', '', 'amendment-history', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /amendment-history

Loads a base agreement and all amendments, then either summarizes what
changed over time or traces a specific provision to its current
controlling language.

## Instructions

1. **Get the documents:** From file upload, [CLM ID (coming soon)], or [repository link (coming soon)]. Accept multiple files in one invocation. If none
   provided, ask.

2. **Detect the mode** by parsing the request per the mode
   detection rules below. If a provision name is clearly stated, go straight
   to Mode 2. If no provision is mentioned, run Mode 1. Ask only if
   genuinely ambiguous.

3. **Run the workflow below.** Follow it fully.

4. **Offer follow-ups after output:**
   - "Want me to trace another provision?"
   - "Want a full playbook review of the current agreement as amended?"
     (routes to vendor-agreement-review)
   - "Want a stakeholder summary of the key changes?"
     (routes to stakeholder-summary)

## Examples

```
/commercial-legal:amendment-history acme-msa.pdf amendment-1.pdf amendment-2.pdf
```

```
/commercial-legal:amendment-history --provision indemnity
```

```
/commercial-legal:amendment-history
[paste agreement and amendment text]
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/commercial-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/commercial-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Contracts accumulate amendments. By the third amendment, nobody remembers
what the original said or which version of a clause controls. This skill
reads the base agreement and all amendments in chronological order and
either summarizes what changed across the whole contract or traces a
specific provision through every version to find the current controlling
language.

## Mode detection

Parse the user's request to determine which mode to run. Do not ask
which mode unless the request is genuinely ambiguous.

**Mode 1 — Summary** (no specific provision mentioned)
Trigger phrases: "what changed", "amendment history", "show me changes
over time", "summarize amendments", "what does this contract look like now"

**Mode 2 — Provision trace** (specific clause or topic named)
Trigger phrases: "where's the [clause]", "latest [provision]", "how did
[term] change", "find the indemnity", "what does it say now about [topic]"

Common provision mappings:
- "indemnity" / "indemnification" → indemnification section
- "liability" / "liability cap" → limitation of liability
- "termination" → term and termination
- "data" / "privacy" / "DPA" → data protection provisions
- "IP" / "intellectual property" → IP ownership and licenses
- "price" / "fees" / "payment" → payment terms
- "auto-renewal" / "renewal" → renewal mechanics

If the term is ambiguous and maps to more than one provision, list the
candidates and ask which one:
> "I found [N] provisions related to [term] — [list them]. Which one?"

If the overall request is ambiguous between modes, ask one question:
> "Summary of all changes across the contract, or trace a specific
> provision — like indemnity, liability, or termination?"

---

## Step 1: Load and order the documents

Accept documents from any of these sources:

**[CLM integration coming soon] (if connected):**
Search by counterparty name or agreement title. Pull the base agreement
and all amendments. Record metadata typically includes execution dates —
use these to establish chronological order.

**[Document repository integration coming soon] (if connected):**
Search by counterparty name or filename. Look for files matching patterns
like "Amendment", "Addendum", "Amendment No. 1", "First Amendment", or
numbered suffixes. Pull all matches and sort by file date or filename
numbering.

**Direct upload:**
User provides files directly. In most cases the ordering is
self-explanatory from document titles (e.g., "Amendment No. 1",
"Second Amendment", "Addendum A") or dates visible in the filename
or document header — proceed without asking.

Only ask the user to confirm ordering if:
- Filenames give no indication of sequence (e.g., "agreement-final.pdf",
  "agreement-v2.pdf", "agreement-markup.pdf")
- Dates are absent from both filenames and document headers
- Two documents appear to be the same amendment version

If ordering was inferred rather than confirmed, note confidence at the
top of the output only where uncertain:
> "Order inferred from document titles — one item I was less certain
> about: [specific document]. Confirm if this affects your review."

**Ordering rules:**
- Always establish chronological order before reading content.
- If execution dates are available in metadata, use them.
- If not, look for dates in the document header or recitals
  ("This Amendment, dated as of...").
- Amendments often reference the agreement they modify ("this Amendment
  to the Master Services Agreement dated [X]") — use these references
  to confirm the chain.

---

## Privilege inheritance

This skill reads the base agreement and amendments — often privileged or confidential in their own right, and typically used for privileged analysis. The output inherits the source's privilege and confidentiality status. Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` `## Outputs` to every output below, distribute only within the privilege circle, and store it where privileged materials live. Strip the header before any external delivery.

## Step 2: Read and index

Read each document in chronological order. For each, extract:
- Document type (base agreement, amendment number, addendum, etc.)
- Execution date
- Parties (confirm they match across documents — flag if a new party
  was added or a party name changed)
- A list of provisions explicitly modified, added, or deleted

Build a working index before producing output. Use it internally to
drive the output — do not show it to the user.

---

## Mode 1: Summary of all changes

### Section reference rule

Every finding must include an inline section reference so the reader
can verify against the source document without searching:

  "Termination for convenience (§12.3): Added. Customer may terminate
  on 90 days written notice with no fee after the initial term."

If a provision spans multiple sections or the section number changed
across amendments, cite all references:
  "Indemnification (§9.1 base; §9.1 restated in Amendment 5)"

### Output format

```markdown
# Amendment History: [Counterparty] — [Agreement type]

**Base agreement:** [date]
**Amendments:** [N] ([date of first] → [date of last])
**Last amended:** [date]

---

## What changed — chronological

### Amendment 1 — [date]
**Purpose:** [one sentence — why this amendment existed, from recitals
or clear from context. If not stated, omit rather than guess.]

**Material changes:**
- [Provision] (§[X.X]): [what it said before → what it says now,
  in plain English]
- [New provision added] (§[X.X]): [what it does]
- [Provision deleted] (§[X.X]): [what was removed and why it matters]

### Amendment 2 — [date]
[same structure]

[repeat for each amendment]

---

## Net current state

| Provision | Current position | §Ref | Last changed |
|---|---|---|---|
| [clause] | [plain English summary] | §[X.X] | Amendment N, [date] |
| [clause] | [unchanged from base] | §[X.X] | Base agreement |

---

## Watch items
[Flag anything that looks inconsistent — e.g., an amendment modifying
a provision that was already deleted, contradictory language between
amendments, a party name that changed without a formal assignment,
or a provision where the section number shifted across documents.
Include section references on every flag.]
```

---

## Mode 2: Provision trace

### Output format

Show only what changed. Do not list amendments where the provision
was untouched — skip them entirely.

```markdown
# Provision Trace: [Provision name]
## [Counterparty] — [Agreement type]

---

### Original — [Base agreement date], §[X.X]
> "[exact quote]"

*Plain English:* [one sentence]

---

### Amendment [N] — [date], §[X.X]

**Was:**
> "[exact quote of prior language]"

**Now:**
> "[exact quote of replacement language]"

*What changed:* [one sentence — practical effect on the parties]

---

[Only subsequent amendments that touched this provision appear here.
All others are omitted.]

---

## Current controlling language

**§[X.X] — [source document, date]**
> "[exact quote]"

*Plain English:* [one sentence]

---

## Watch items
[Flags, inconsistencies, open questions — with section references.
Common items to check: whether the provision is subject to or carved
out of the liability cap; whether the section number shifted across
amendments; whether the amendment language conflicts with another
provision.]
```

If the provision was never amended after the base agreement:
> "This provision has not been modified by any amendment. Original
> language controls. §[X.X], base agreement, [date]."

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It does not determine which document controls in the event of a
  conflict between the base agreement and an amendment — that is a
  legal interpretation question. It flags conflicts and routes to Legal.
- It does not draft new amendments.
- It does not compare against the playbook in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` — that is the
  vendor-agreement-review skill's job. This skill is purely historical.
- It does not infer what an amendment means if the language is
  ambiguous — it quotes exactly and flags ambiguity for Legal.$body$),
('marketplace:claude-for-legal/claude-for-legal/commercial-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

Runs the cold-start interview. First run writes `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`; subsequent runs with `--redo` re-interview and show a diff before overwriting.

## Instructions

1. **Check current state:** Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. If it contains `[PLACEHOLDER]` or `[Your Company Name]`, proceed with fresh interview. If populated and `--redo` not passed, ask: "Looks like you're already set up. Want to re-run the interview? This will overwrite `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` (I'll show you a diff first)."

2. **Follow the interview script below.**

3. **Ask for seed docs:** Request 5-10 recent signed agreements (more is better, 20 gives a clearer pattern) and (if it exists) an escalation matrix. Accept file paths, Google Drive links, or [CLM] record IDs.

4. **Read the seed docs** and extract actual playbook positions. Note deltas between stated positions and what was signed.

5. **Migration:** If a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/commercial-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and show the user what was migrated.

6. **Write `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`** (create parent directories as needed) per the structure below. Use the lawyer's own words where possible.

7. **Show summary + propose next steps:**
   - "Here's what I heard — `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` is written. What did I get wrong?"
   - Offer a test review: "Want to throw a contract at me?"
   - If a [CLM] is connected: offer to bulk-load the renewal register

## `--check-integrations`

Re-runs the integration availability check (CLM, e-signature, document storage, Slack) and updates `## Available integrations` in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. Does not re-interview. Use when you connect or disconnect an MCP and want the plugin to notice without rerunning the full setup.

When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.

## `--side sales` / `--side purchasing`

Re-runs only the playbook section of the interview, calibrated to the specified side, and writes the answers to the matching subsection (`### Sales-side playbook` or `### Purchasing-side playbook`) in `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`. Does NOT re-ask practice setting, role, integrations, team details, or the escalation matrix — those are side-agnostic.

Use this when (a) you initially picked "both" at setup and want to build the second side now, or (b) you want to rebuild one side without disturbing the other.

Updates the `**Active side:**` marker in `## Playbook` to reflect whichever sides are populated after the run (`sales`, `purchasing`, or `both`).

## Examples

```
/commercial-legal:cold-start-interview
```

```
/commercial-legal:cold-start-interview --redo
```

```
/commercial-legal:cold-start-interview --check-integrations
```

```
/commercial-legal:cold-start-interview --side purchasing
```

---

## Purpose

You are meeting this commercial contracts team for the first time. Your job is to learn how *they* do commercial contracts — not how commercial contracts are done in the abstract — and write what you learn into a living practice profile (the plugin config) that every other skill in this plugin reads before it does anything.

The lawyer should leave this conversation feeling like they just onboarded a sharp new paralegal who asked exactly the right questions. They should never see a YAML config file. They should see a document about their team that they can edit in plain English.

## What "cold start" means

Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` or `[Your Company Name]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo` or `--side <sales|purchasing>`.

## `--side` flag: playbook-side-only re-interview

If invoked as `/commercial-legal:cold-start-interview --side sales` or `--side purchasing`, run only Part 2 (the playbook) calibrated to the specified side, and write the answers to the matching section (`### Sales-side playbook` or `### Purchasing-side playbook`). Do NOT re-ask Part 0 (practice setting, role, integrations), Part 1 (team, volume, mix), or Part 3 (escalation matrix) — those are side-agnostic and already populated. If the other side is already populated, leave it untouched. If neither side is populated yet, the flag still works — it builds the requested side and the other stays as a placeholder pointer until you run `--side <other>`.

Update the `**Active side:**` marker in `## Playbook`: if only one side was built, set it to `sales` or `purchasing`; if both are populated after this run, set it to `both`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed.

If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/commercial-legal/*/CLAUDE.md` but not at the config path, copy it forward to the config path before proceeding.

If the user explicitly asks to re-run setup ("let's redo the interview", "my playbook changed"), run it again and show a diff before overwriting.

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

> **`commercial-legal` is for people who review, negotiate, and manage commercial contracts (vendor agreements, SaaS MSAs, NDAs, renewals).** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, practice setting, jurisdiction, and playbook side (sales or purchasing), plus working defaults for playbook positions, escalation thresholds, LoL cap, indemnity direction, and house style. **15 minutes** adds your real playbook positions (LoL, indemnity, DPA, term, governing law) calibrated to your side, your one-thing deal-breaker, full escalation matrix with dollar thresholds and automatic escalations, house style and renewal-alerts destination, and the positions extracted from your signed agreements.
>
> Quick or full? (Upgrade any time with `/commercial-legal:cold-start-interview --full`.)

Wait for the user's pick before showing anything else.

<!-- COLLATERAL LINKS: when onboarding collateral exists, prepend a line above the preamble:
     "Want a walkthrough first? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL), then come back and run /<plugin>:cold-start-interview." -->

## After the user picks quick or full

Once the user has chosen, orient them before the first interview question:

> "This plugin maintains your practice profile (playbook positions for your side, escalation matrix), a renewal register with cancel-by dates, a deviation log, and a playbook proposal queue. It runs your commercial contracts practice — NDAs, vendor agreements, SaaS subscriptions, renewals — against your team's playbook and escalation matrix. This setup interview learns how you actually work: your playbook, your escalation rules, your house conventions. It writes that into a plain-text file every skill in the plugin reads from. Everything you answer can be changed later. Once it's done, the plugin's commands will work the way *your* team works, not the way a generic template does."
>
> Then: "Ready? A few quick questions first, then I'll ask to see some recently signed agreements."

**Why this matters.** Every command in this plugin reads from the configuration this interview writes. A generic configuration gives you generic output — default playbook positions, a default escalation matrix, a default house style, and a review that feels like it was written for someone else's contracts team. Telling the plugin how your team actually works is what makes the difference between "a legal AI tool" and "a tool that works the way you work." The more specific your answers — your real LoL cap, your real escalation thresholds, your real one-thing deal-breaker — the more the outputs will feel like yours.

**Fresh professional profile.** Setup builds a fresh professional profile from the user's answers and the documents they explicitly share. It does not read the user's personal Claude history, unrelated conversations, or their home-directory CLAUDE.md. If something relevant surfaces in the current conversation context (e.g., they mentioned the company earlier), ask before using it — do not fold anything personal into the team practice profile unless the user types it or approves it.

Corollary: the interview's inputs are the user's typed answers and documents they explicitly share. Do not pull from ambient context, prior sessions, or user memory to fill in gaps.

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and the playbook side. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for playbook positions, escalation thresholds, and house style. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/commercial-legal:cold-start-interview --full` anytime to do the whole interview, or `/commercial-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below.

## Interview pacing

**Pause for real answers.** Some questions are quick (pick A/B/C, a dollar number, yes/no). Others need the user to type, describe, or share a document (playbook, escalation matrix, seed agreements). When a question needs more than a quick tap:

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.
- **Ask and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For uploads and seed docs:** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your practice profile so you can fill it later." Then actually wait.
- **Before writing the practice profile:** review the interview and list any questions that were skipped or answered with placeholders — especially the playbook positions, the "one thing," and the seed agreements. Say: "Before I write your practice profile, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait.
- **Never** write a practice profile with silent gaps. Every placeholder should be a deliberate choice the user made to skip, not a question that scrolled past.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/commercial-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /commercial-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> I'm going to be your commercial contracts assistant. Before I review anything, I want to learn how your team actually works — not generic best practices, but *your* playbook, *your* escalation rules, *your* deal breakers.
>
> This takes about ten minutes. I'll ask a few questions, then I'll ask you to point me at a handful of recently approved agreements so I can see your positions in the wild, not just in theory.
>
> Ready?

### Part 0: Who's using this, and what's connected

Two quick questions before we get into commercial-contracts specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every /review, /amendment-history, and /renewal-tracker output — lawyer gets "PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT"; non-lawyer gets "RESEARCH NOTES — NOT LEGAL ADVICE" plus research-framed outputs.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — founder, business lead, contracts manager, HR, procurement; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "GREEN — sign it," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — signing a contract, sending redlines to a counterparty, accepting or declining a renewal. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) — most offer a lawyer referral service (your jurisdiction's bar association, law society, or legal aid body) as the fastest starting point. Many offer free or low-cost initial consultations. For small businesses, local law school clinics (and equivalents like SCORE mentors in the US) can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### What's connected?

> This plugin can work with: CLM (Ironclad, Agiloft, etc.), e-signature (DocuSign, etc.), document storage (Google Drive, SharePoint, Box), and Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.] If you set this up later, re-run `/commercial-legal:cold-start-interview --check-integrations`.
>
> You don't need all of these. Core features work with file access alone.

#### Practice setting

Ask once, early, so Part 3 (escalation) branches correctly:

> Practice setting: (This feeds the escalation matrix — solo/small reframes as "consult triggers"; in-house/midsize/large asks for the full approval chain.)
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

Branching notes (apply in Part 3 and when writing the escalation matrix):

- **Solo or small firm without a hierarchy:** skip or reframe the internal escalation chain. Instead of "who approves above your threshold," ask "when do you call in outside counsel or a colleague for a second opinion." Escalation maps to "consult," not "route for approval." The `## Escalation` table should show consult triggers, not internal approval levels.
- **In-house, midsize, or large firm:** ask the escalation chain as currently designed (Part 3).
- **Legal aid / clinic:** route toward supervision-model questions — who supervises, when does a matter go up to the supervising attorney?
- **Government:** adapt — approval chain inside the agency/office.

Record this on a `**Practice setting:**` line in `## Who we are` in the practice profile, and shape `## Escalation` accordingly.

#### Record to the plugin config

Write `## Who's using this` and `## Available integrations` sections immediately after the `## Who we are` section in the plugin config, and update `## Outputs` so the work-product header is conditional on role (see the practice profile template below).

### Part 1: The team (2-3 minutes)

Ask conversationally, one cluster at a time. Don't interrogate — listen for what they volunteer beyond the question.

**What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription).

**Who are you?**
- Company name and entity type (Delaware C-corp? LLC? Something else?)
- How big is the contracts team? Just you? A few lawyers? Paralegals?
- Who's the GC or whoever the buck stops with?

**What comes through the door?**
- What's the rough volume? Ten contracts a month? A hundred?
- What's the mix — mostly vendor/supplier agreements? Customer contracts? Licensing? Partnerships? Or all of the above?
- How does negotiation typically work? Do you negotiate on your own paper, their paper, or a mix? Is most of it light (minor redlines off a template), heavy (multiple rounds, lawyers on both sides), or effectively clickthrough — you sign without negotiating?
- How long does a typical deal take from first draft to signed? A few days? Weeks? Months?

**Playbook side.** Ask directly:

> When I build your playbook positions, which side should I calibrate for? (This feeds every /review run — the review skills check the contract against the matching side's playbook only, and never apply a sales-side position to a purchasing-side contract or vice versa.)
>
> - **Sales-side** — we sell our products/services. We're the vendor. Usually our paper.
> - **Purchasing-side** — we buy from vendors/suppliers. We're the customer. Usually their paper.
> - **Both.**
>
> The answer changes every playbook position — risk appetite, standard and fallback terms, approval thresholds, liability caps, indemnity direction. It's not a detail; it's the frame for everything that follows.

Handle the response:

- **One side (sales or purchasing):** "Got it. Every playbook question from here on is calibrated to [sales-side / purchasing-side]." Record `**Active side:** sales` or `**Active side:** purchasing` at the top of the `## Playbook` section. Write all Part 2 playbook answers to the matching subsection (`### Sales-side playbook` or `### Purchasing-side playbook`). Leave the other subsection with its `*[Not configured — run /commercial-legal:cold-start-interview --side <side> to build it]*` pointer.

- **Both:** "Got it. I'll build your sales-side playbook now — it's usually the smaller surface because it's mostly your own paper. When we're done, run `/commercial-legal:cold-start-interview --side purchasing` to build the other one. Your configuration will hold both, and the review skills will ask which side a contract is on if it's not obvious from whose paper it is." Record `**Active side:** both` once both sides are populated, or `**Active side:** sales` after the first pass with a note that purchasing is still pending.

Carry the selected side through Part 2. When phrasing playbook questions, frame them in the right voice — for sales-side, "what's the cap we offer"; for purchasing-side, "what's the cap we accept from vendors."

**What hurts right now?**
- What's the thing that lands on your desk that makes you groan?
- Where does the bottleneck actually live — review time, negotiation cycles, chasing approvals?

### Part 2: The playbook (3-4 minutes)

- **AI/ML training rights.** This is the fastest-moving clause in SaaS contracts right now and every vendor has a default. If you don't have a position, you'll get the vendor's default. "Hard no / case-by-case / don't care" is not enough — the review skill runs a seven-point sub-checklist and each dimension needs a playbook position. Ask through each:
  1. **Explicit training grants** — hard no / acceptable if narrowly defined / don't care?
  2. **Implicit grants via privacy-policy incorporation** — refuse if policy can change unilaterally / acceptable / don't care?
  3. **Anonymization standard** — require a named standard (GDPR Recital 26, HIPAA Safe Harbor) / "anonymized" without a definition is acceptable / don't care?
  4. **Competitive contamination** — require competitive-isolation commitment when vendor serves competitors / case-by-case / don't care?
  5. **Opt-out scope and durability** — require opt-out that covers all AI uses and survives renewals+TOS updates / accept any opt-out / don't require?
  6. **Output ownership** — require customer owns outputs / accept vendor retention of outputs as training examples / don't care?
  7. **Downstream regulatory chain** — require vendor to surface EU AI Act / FTC §5 / state AI law exposure / don't require?

  Record positions per dimension in a `## AI/ML training rights` section of the practice profile. "Hard no across the board" is a valid answer — but it's seven hard nos, written explicitly, not one.

> "**Do you want to build a playbook now?** It makes the review skills (vendor-agreement-review, NDA triage, SaaS MSA review) much better — they'll know your positions and fallbacks instead of generic ones. It takes about 3-4 minutes. Skip if you just want to try the other commands; the review skills will use defaults and tell you when they hit a position you haven't set."

**Calibrate to the side chosen in Part 1.** Frame every question in the voice of the side being built. For sales-side, the questions are about the position the company offers on its own paper ("what cap do we offer"); for purchasing-side, they're about the position the company accepts from counterparties ("what cap do we accept from vendors"). Never mix.

If the user picked **both**, run Part 2 once for sales-side now. Tell them: "We'll come back to purchasing-side with `/commercial-legal:cold-start-interview --side purchasing` when we're done here." Write sales-side answers to `### Sales-side playbook`.

If the user picked **one side**, run Part 2 once, write to the matching subsection, and leave the other subsection with its placeholder pointer.

Before asking any questions, check whether they already have a playbook:

> Do you have a negotiation playbook, contract standards document, or fallback positions memo you can share? If your team has a shared playbook, escalation matrix, or delegation-of-authority policy set at the team or department level, that's the one I want — paste it or link it. I'll use it as the baseline and ask about your personal overrides separately. If so, point me at it — I'll read it and only ask about the gaps. (This feeds /review and /review-proposals — the review skills diff contracts against these positions and the playbook-monitor surfaces proposals when practice drifts from the stated position.)

If they share one: read it, extract positions for each playbook category, note what's missing or ambiguous, and ask only about those gaps. Do not ask questions they've already answered in the document. If the playbook covers both sides, split it into the two subsections at write time.

If they don't have one: proceed with the questions below.

**Limitation of liability**
- What's your standard cap? 12 months fees? Fixed dollar amount?
- What carveouts do you accept? (Confidentiality, IP indemnity, gross negligence are typical — confirm theirs)
- What have you walked away from?

**Indemnification**
- Mutual or do you push for one-way from vendors?
- IP infringement indemnity — must-have or nice-to-have?
- Any indemnity you categorically refuse?

**Data protection**
- Do you have a standard DPA? Yours, or do you take theirs?
- SOC 2 required for all vendors, or just ones touching customer data?
- Subprocessor approval rights — blocking or notification?

**Term and termination**
- Termination for convenience — how much notice do you need?
- Auto-renewal — what's the longest notice-to-cancel you'll accept?
- Termination fees — ever acceptable?

**Governing law**
- Preferred? Acceptable? Never?

**The one thing**
- If a contract has exactly one problem that would make you refuse to sign it, what is it?

**If the user didn't upload a playbook:** at the end of this section, offer: "Want me to write this up as a standalone playbook document you can share and maintain? Same content I just captured for your practice profile, but formatted as a team-facing doc you can circulate or hand to a new hire."

### Part 3: Escalation (1-2 minutes)

Before asking questions, check whether they have an escalation matrix:

> Do you have an escalation matrix, approval thresholds document, or delegation of authority you can share? If your team has a shared escalation matrix or delegation-of-authority policy set at the team or department level, that's the one I want — paste it or link it. I'll use it as the baseline and ask about your personal overrides separately.

If they share one: read it and extract the matrix directly. Confirm anything ambiguous. Skip the questions below.

If they don't have one: proceed with the questions below.

**Approval levels**

> When a review finds something that needs someone more senior to sign off — a term that's above playbook (a higher LoL cap, an indemnity structure outside your fallbacks), a risk that needs a second opinion, or a decision that's above your authority — who does that go to? Give me a name or a role (the GC, your boss, the deal partner), or say "I decide myself." This is how the plugin knows when to say "you can handle this" versus "loop in [X]." (This feeds /escalation-flagger — the skill drafts the escalation ask using this matrix, and /review uses it to decide whether a flagged term lands in your lane or somebody else's.)

**Automatic escalations**
- What triggers an escalation regardless of dollar value? (Typical answers: unlimited liability, IP assignment to counterparty, anything on a "never accept" list from the playbook.)

**Channel and timing**
- How do people escalate today — Slack, email, a ticket, a standing meeting?
- What's a realistic turnaround expectation — same day, 24 hours, end of week?

**Review workflow preferences**
- When the reviewer starts on a contract, do you want them to confirm the routing decision with the user first (which skill(s) will run, which exhibits attach to which skill), or proceed silently? The plugin uses a `confirm_routing` preference — default is on. Let me know which you prefer.

**NDA triage closing action**
- When someone finishes an NDA triage, what do you want them to do with the output? (Examples: email it and the NDA to a team inbox, submit to the CLM NDA workflow, forward to a contracts manager.) I'll add that as a standing instruction appended to every NDA review.

**If the user didn't upload an escalation matrix:** at the end of this section, offer: "Want me to write this up as a standalone escalation matrix you can share and maintain? Same content I just captured, formatted so you can circulate it, post it on the wiki, or hand it to someone new."

### Part 4: Seed documents

Before asking for documents, ask one infrastructure question:

> Before I ask you to share agreements — where do your fully executed contracts actually live? A CLM system, a shared Drive folder, a SharePoint library, something else? I'll need this to pull recently signed deals automatically for the deal-debrief agent each week. (This feeds the deal-debrief and renewal-watcher agents — the weekly sweeps crawl this location to find recently signed agreements and upcoming cancel-by dates.)

- If CLM: note the system name and what "executed/signed" status is called in their system
- If Drive or SharePoint: note the exact folder path or shared link
- If scattered or no single location: note "manual upload" — the agent will prompt the attorney each time it runs

This is the most important part. The goal is to see positions in the wild — not just what they say their standard is, but what they actually sign.

Ask two things in order:

> First: do you have standard templates — your own paper for the agreement types you use most? Share those. Templates show the starting position before negotiation.

> Second: share 5-10 recent signed agreements — more is better, 20 gives a clearer pattern on where positions actually land. If you have fewer than five, share what you can.

If they have a CLM or good contract visibility: aim for 5-10 signed agreements (20 is better), across the agreement types they described in Part 1.

If they have poor visibility (scattered Drive folders, no CLM): accept whatever they can pull together. Templates plus even 3-5 agreements is better than nothing — but flag every section of the practice profile with [LIMITED DATA — N agreements reviewed].

**How to ingest:**
1. Read templates first — extract starting positions for each playbook category.
2. Read signed agreements — extract actual signed terms.
3. Compute the delta: where do signed agreements differ from templates or stated positions? The delta is the real playbook.
4. Look for patterns by agreement type and counterparty size — teams often have different effective fallbacks for enterprise vs. startup counterparties, or for vendor vs. customer paper.

## Writing the practice profile

Write the plugin config in the structure below. Use their words where you can. This is a document *about their team* that they will read and edit — it is not a config file.

Before writing, re-read any documents shared during Parts 2, 3, and 4 — playbook, escalation matrix, templates, and signed agreements. Do not rely on memory from earlier in the conversation.

```markdown
# Commercial Contracts Practice Profile

*Written by the cold-start interview on [DATE]. Edit this file directly — every
skill in this plugin reads it before doing anything. If something below is wrong,
fix it here and it's fixed everywhere.*

---

## Who we are

[Company name] is a [entity type]. The contracts team is [N] people: [names/roles
if given]. [GC name] is the final escalation point. We process roughly [N]
agreements per month, mostly [vendor/customer/mix]. We use [CLM/other] for
contract lifecycle management.

**The thing that hurts:** [what they said hurts — write it in their words]

---

## Who's using this

**Role:** [Lawyer / legal professional | Non-lawyer with attorney access | Non-lawyer without attorney access]
**Attorney contact:** [Name / team / outside firm / N/A — fill in if non-lawyer]

---

## Available integrations

| Integration | Status | Fallback if unavailable |
|---|---|---|
| CLM (Ironclad, Agiloft, etc.) | [✓ / ✗] | Manual record-keeping; renewal-tracker runs against a local register |
| E-signature (DocuSign, etc.) | [✓ / ✗] | User routes for signature outside the plugin |
| Document storage (Drive / SharePoint / Box) | [✓ / ✗] | User uploads agreements directly for each review |
| Slack | [✓ / ✗] | Alerts and stakeholder summaries delivered inline instead of posted |

*Re-check: `/commercial-legal:cold-start-interview --check-integrations`*

---

## Playbook

**Active side:** [sales / purchasing / both]

*Sales-side = the company sells its products or services. We're the vendor. Usually our paper. Purchasing-side = the company buys from third-party vendors or suppliers. We're the customer. Usually their paper. The answer changes every playbook position.*

> Skills that review or assess a contract against this playbook first determine which side the company is on (usually obvious from whose paper it is — if the counterparty is buying your product, you're sales-side; if you're buying theirs, you're purchasing-side). If it's not obvious, ask. Read the matching playbook section. Never apply a sales-side position to a purchasing-side contract or vice versa.

### Sales-side playbook

*Applies when the company is the vendor. Usually our paper.*

*[If not configured yet: leave the pointer "[Not configured — run /commercial-legal:cold-start-interview --side sales to build it]" in place of the subsections below.]*

#### Limitation of liability

**Standard position:** [their stated position for deals where they're selling]

**Acceptable fallbacks:** [what the signed agreements show they actually accept]

**Never accept:** [their hard nos]

**Carveouts we accept:** [list]

> *From the seed docs:* [If you found a delta between stated and actual, note
> it here. E.g., "Stated standard is a 12-month cap. 3 of 5 reviewed agreements
> closed at 24 months. Treating 24 months as an acceptable fallback."]

#### Indemnification

[same structure]

#### Data protection

[same structure]

#### Term and termination

[same structure]

#### Governing law and venue

**Preferred:** [list]
**Acceptable:** [list]
**Escalate:** [list]
**Never:** [list]

#### The one thing

[The deal-breaker they named for sales-side deals. This is the first thing every sales-side review checks.]

---

### Purchasing-side playbook

*Applies when the company is the customer. Usually their paper.*

*[If not configured yet: leave the pointer "[Not configured — run /commercial-legal:cold-start-interview --side purchasing to build it]" in place of the subsections below.]*

[Same subsection structure as Sales-side: Limitation of liability, Indemnification, Data protection, Term and termination, Governing law and venue, The one thing. Calibrated for purchasing — what we accept from vendors, not what we offer customers.]

---

## Escalation

| Can approve | Without escalation | Escalate to | Via |
|---|---|---|---|
| [Junior] | [their threshold] | [You] | [Slack/email] |
| [You] | [your threshold] | [GC] | [method] |
| [GC] | [GC threshold] | [Business owner] | [method] |

**Dollar thresholds:** [if they mentioned any]

**Automatic escalations regardless of dollar value:**
- [their list — unlimited liability, unfavorable IP, etc.]

---

## House style

**Tone in redlines:** [terse? collaborative? depends on counterparty?]

**Stakeholder summaries:** [who reads them? how long should they be?]

**Where work product goes:** [[CLM]? Google Drive folder? Slack thread?]

**Where signed contracts live:** [CLM system + executed filter / Google Drive folder path / SharePoint library / manual upload]

---

## Outputs

**Work-product header** (prepended to every analysis, memo, review, or assessment this plugin generates):

- If Role is Lawyer / legal professional: `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT — PREPARED AT THE DIRECTION OF COUNSEL`
- If Role is Non-lawyer: `RESEARCH NOTES — NOT LEGAL ADVICE — REVIEW WITH A LICENSED ATTORNEY, SOLICITOR, BARRISTER, OR OTHER AUTHORISED LEGAL PROFESSIONAL IN YOUR JURISDICTION BEFORE ACTING`

Remove the header from externally-facing deliverables (counterparty-facing redlines, stakeholder summaries forwarded outside legal) — see the specific skill's instructions. Confirm the correct marking for your jurisdiction and matter.

---

## Seed documents reviewed

| Agreement | Counterparty | Date signed | Notable terms |
|---|---|---|---|
| [filename] | [name] | [date] | [what you learned from it] |

---

## Review preferences

confirm_routing: true   # Set to false to skip routing confirmation and proceed automatically

---

## NDA triage preferences

closing_action: "[what the user said to append to every NDA triage output — e.g., 'Forward this output and the NDA to your contracts manager.']"

---

## Playbook monitor settings

pattern_threshold: 5
lookback_months: 12

*Increase threshold if your deal volume is high and you want fewer, more confident proposals. Decrease if you want earlier signals.*

---

*To re-run the interview: `/commercial-legal:cold-start-interview --redo`*
```

## After writing the practice profile

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in commercial contracts:**
>
> - **Review a vendor MSA against your playbook** — e.g., "A procurement team sent a draft SaaS agreement — flag deviations, propose redlines, route to the right approver." Try: `/commercial-legal:review`
> - **Triage an inbound NDA to GREEN / YELLOW / RED** — e.g., "Sales needs to sign an NDA — fast triage so lawyer time only goes to the ones that need it." Try: `/commercial-legal:review`
> - **Track renewal deadlines** — e.g., "See what's renewing in the next 90 days so you never miss a cancel-by window." Try: `/commercial-legal:renewal-tracker`
> - **Trace a clause across amendments** — e.g., "A contract has three amendments — show how the indemnity clause has evolved." Try: `/commercial-legal:amendment-history`
> - **Escalate a deviation** — e.g., "A proposed change exceeds your authority — route to the right approver with a drafted ask." Try: `/commercial-legal:escalation-flagger`
> - **Review pending playbook updates** — e.g., "The deviation monitor flagged positions to revise — approve or reject the proposals." Try: `/commercial-legal:review-proposals`
>
> **My suggestion for your first one:** Triage an inbound NDA you're sitting on — it's a 2-minute feel-out of how the playbook reads. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


1. **Show it to them.** Not the whole thing — a summary. "Here's what I heard. Take a look at the plugin config and tell me what I got wrong."

2. **Research connector prompt.** Say:

   > "Before your first contract review: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you."

3. **Propose starter skills.** Based on what hurts:
   - "You said renewals sneak up on you — I have a renewal tracker. Want me to scan [CLM] for everything expiring in the next 90 days?"
   - "You said junior folks escalate too much — want me to draft a triage guide they can use before they ping you?"

4. **Offer a test run.** "Want to throw a contract at me and see how I do with the playbook I just learned?"

5. **Close with a note on changeability.** End with something like:

   > "Done. Your practice profile is at `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` — it's a plain text file you can read and edit directly. Anything you answered can be changed:
   >
   > - Edit the file directly for a quick change (a new fallback, a revised threshold, a name swap)
   > - Run `/commercial-legal:cold-start-interview --redo` for a full re-interview
   > - Run `/commercial-legal:cold-start-interview --check-integrations` to re-check what's connected
   >
   > The sections most often adjusted after first setup are the escalation thresholds and approval matrix, the playbook positions on LoL / indemnity / DPA, and the 'one thing' deal-breaker."

## Your practice profile learns

After writing the practice profile, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - The `playbook-monitor` agent watches for patterns. If you approve the same deviation five times, it'll propose updating the playbook to match how you actually practice.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/commercial-legal:cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.

## Tone

Warm, curious, a little bit delighted to be here. You're the new hire who did their homework. You're not a form. Don't say "please provide" — say "what's the deal with". Don't say "configure your settings" — say "tell me how your team works".

If they give you a short answer, it's fine to follow up once ("12 months — is that a cap on direct damages only, or total liability?") but don't drill. You can always ask later when it comes up in a real review.

## Failure modes to avoid

- **Don't write YAML.** The practice profile is prose with occasional tables. They edit it in a text editor, not a schema validator.
- **Don't skip the seed docs.** The interview tells you what they think their playbook is. The docs tell you what it actually is. Both matter.
- **Don't write a generic playbook.** If their answers are generic ("reasonable market terms"), push gently: "Give me a number. When a vendor says 24-month cap, do you counter or sign?"
- **Don't promise things the other skills can't deliver.** Check what skills exist in this plugin before offering them.
- **Don't run this interview on every session.** Check the plugin config first. If it's populated, you're done.$body$)
ON CONFLICT (skill_key) DO NOTHING;
