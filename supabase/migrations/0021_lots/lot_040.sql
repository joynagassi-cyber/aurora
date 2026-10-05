INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/common-room/skills/call-prep', 'business', 'call-prep', '', 'call-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Call Prep

Produce a complete, scannable call prep brief by combining account research, contact research, and signal synthesis from Common Room.

## Prep Process

### Step 1: Identify the Account and Attendees

Parse what the user has provided:
- **Company name** — required; look up the account in Common Room
- **Attendee names** — optional; if provided, research each one

**Calendar lookup:** If a `~~calendar` connector is available, search for upcoming meetings with the named company to automatically surface attendee names, meeting time, and any meeting notes or agenda. Use this to fill gaps the user didn't provide.

If neither attendees nor a calendar match can be found, ask: "Who will be on the call from [Company]? I can research each attendee to make your prep more useful."

### Step 2: Run Account Research

Use the account-research skill process to build a full account snapshot. For call prep, prioritize:
- Recent product signals (what are they doing in the product right now?)
- Open opportunities or renewal timeline
- Any risk signals (declining usage, support tickets, churned seats)
- Key recent events (funding, executive change, new hire)

When reviewing activity history, prioritize Gong and call recording activities — these provide direct context about previous conversations. Do not filter out call recordings by activity origin.

### Step 3: Run Contact Research for Each Attendee

For each external attendee, use the contact-research skill process. For call prep, focus on:
- Role and influence in the buying process
- Their personal activity and engagement history
- Any recent signals that suggest their current mood/priorities
- Spark persona classification if available

### Step 4: Synthesize Talking Points and Objectives

Based on the combined account and contact research:
- Identify the **call objective** (e.g., discovery, demo, expansion conversation, renewal, QBR)
- Generate **3–5 tailored talking points** grounded in specific signal data
- Anticipate **2–3 likely objections or topics** the customer may raise
- Suggest a **recommended outcome** for the call

When the user's company context is available (see `references/my-company-context.md`), tailor talking points to the user's product and value proposition.

### Step 5: Recency Check (Web Search)

After gathering all Common Room data, run a quick recency check to catch anything that happened since the last CR data sync. This is supplementary — CR data drives the prep; web search only adds recency.

**Company news:** Search `"[company name]" news` filtered to the last 14 days. Look for funding announcements, product launches, leadership changes, layoffs, partnerships, or press coverage.

**Attendee presence:** For each external attendee, search `"[full name]" "[company name]"` — look for recent articles, LinkedIn posts, conference talks, podcasts, or published opinions.

If a company news item is significant (e.g., just raised a round, announced a major hire), flag it in Signal Highlights. Otherwise, include findings briefly — don't let web search results overshadow CR signals.

## Output Format

The output adapts to how much data Common Room returned. Only include sections where you have real data. Never fill a section with invented details.

### When data is rich (multiple field groups returned, activity history, scores, signals):

```
## Call Prep: [Company] — [Date/Time if known]

**Meeting Context**
[Attendees, meeting type, and any known agenda]

---

### Company Snapshot
[4–6 bullets: key account status, signals, and recent activity]

---

### Attendee Profiles

**[Attendee Name] — [Title]**
[3–4 bullets: role, recent activity, Spark persona if available, personal hook]

[Repeat for each attendee]

---

### Signal Highlights
[Top 3 signals most relevant to this specific call]

---

### Talking Points
1. [Point tied to a specific signal]
2. [Point tied to a specific signal]
3. [Point tied to a specific signal]

### Likely Topics / Objections to Prepare For
- [Topic or objection + suggested response]
- [Topic or objection + suggested response]

### Recommended Call Outcome
[1–2 sentences: what success looks like for this meeting]
```

### When data is sparse (few fields returned, no activity, null sparkSummary):

```
## Call Prep: [Company] — [Date/Time if known]

**Data available:** [List exactly what Common Room returned — e.g., "Name, title, email, two tags. No activity history, no scores, no Spark data."]

### What I Found
[Only the fields actually returned, presented as-is]

### Web Search Results
[Findings from web search on the company and attendees — or "No significant results"]

### Suggested Next Steps
- I can pull [specific field groups] from Common Room if available
- I can run deeper web searches on [specific topics]
- You may want to check Common Room directly for [what's missing]
```

Do not generate a full call prep brief from sparse data. A short honest output is always better than a long fabricated one.

## Quality Standards

- Ground every talking point in a real signal — no generic filler
- Keep the brief tight — it should be readable in 5 minutes or less
- Flag unknowns explicitly — if attendee research is thin, say so
- Time-box the research — don't over-research at the expense of speed
- **Never invent deal context** — no fabricated proposals, competitor comparisons, pricing, trial terms, or objections not returned by a tool call

## Reference Files

- **`references/call-types-guide.md`** — guidance for different call types (discovery, expansion, renewal, QBR) and how to tailor prep accordingly$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/common-room/skills/compose-outreach', 'business', 'compose-outreach', '', 'compose-outreach', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Compose Outreach

Generate three personalized outreach formats — email, call script, and LinkedIn message — grounded in Common Room signals for a specific company or contact.

## Outreach Process

### Step 1: Look Up the Target

Use Common Room MCP tools to find and retrieve data for the target (company and/or specific contact). Pull:
- Recent product activity and engagement signals
- Community activity (posts, questions, reactions)
- 3rd-party intent signals (job postings, news, funding)
- Relationship history (prior contact, meetings, email opens)

If the user specified a person, run contact-level research. If only a company was given, identify the best contact to target based on title, engagement, and role.

### Step 2: Web Search for External Hooks (If CR Signals Are Thin)

If CR returned strong signals (recent activity, engagement, product usage), those should drive personalization — skip web search. If CR signals are thin or the prospect has little CR activity, run a web search for external hooks:

**What to search:**
- `"[company name]" funding OR acquisition OR launch OR announcement` — last 30 days
- `"[contact full name]" "[company name]"` — look for recent articles, interviews, LinkedIn posts, or conference talks

**Prioritize external hooks that are:**
- Very recent (< 2 weeks) — the prospect is likely still thinking about it
- Publicly visible — they know you could have seen it
- Change-signaling — growth, new role, new product, new market

If the user explicitly asks for web search or external hooks, run it regardless of CR signal richness.

### Step 3: Spark Enrichment (If Available)

If Spark is available, run enrichment on the target contact to get persona classification, background, and influence signals. Use this to calibrate tone and message angle.

### Step 4: Identify the Best Hooks

From the signal data, identify the 1–3 strongest personalization hooks. Rank by:
1. **Recency** — happened in the last 7–14 days
2. **Specificity** — a concrete action they took, not a general trend
3. **Relevance** — connects directly to a value your product delivers

Good hooks: posted a question in the community about X, just hired 5 engineers, recently started using [feature], company just raised Series B, trial nearing expiration, champion just changed jobs.

Bad hooks: "I noticed you're a customer" or generic industry trends.

### Step 5: Generate All Three Formats

Use the strongest hooks to write all three formats. Each format has different constraints and conventions — follow the format-specific guidelines in `references/outreach-formats-guide.md`.

Always produce all three, clearly labeled.

When the user's company context is available (see `references/my-company-context.md`), ground the value bridge and pitch in the user's specific product and positioning.

### Step 6: Annotate Your Choices

After the three drafts, include a brief note (2–4 sentences) explaining:
- Which signals were used and why they were chosen
- Any assumptions made (e.g., inferred call objective)
- Alternative angles if the primary hook doesn't land

## Output Format

```
## Outreach for [Name / Company]

### 📧 Email

**Subject:** [Subject line]

[Email body — 3–5 sentences]

---

### 📞 Call Script

**Opening:**
[Opening line — conversational, 1–2 sentences]

**Value Bridge:**
[Why you're calling and why now — 2–3 sentences tied to a signal]

**Ask:**
[Single, low-friction ask — e.g., 15-minute call, specific question]

---

### 💼 LinkedIn Message

[Under 300 characters. Warm, personal, no pitch.]

---

### Signal Notes
[2–4 sentences: which signals were used, why, and any alternative angles]
```

## When Signal Data Is Sparse

If Common Room returns minimal data on the target (e.g., just name, title, tags — no activity, no scores, no Spark):

1. **Do not draft outreach from thin air.** Outreach grounded in fabricated signals is worse than no outreach.
2. **Run web search first** — this becomes your primary personalization source. Look for recent news, LinkedIn posts, conference talks, company announcements.
3. **If web search also returns little**, present what you have honestly and ask the user for context:

```
## Outreach for [Name / Company] — Limited Data

**What I found:**
[Only the real data from CR and web search]

**I don't have enough signal to draft personalized outreach yet.** To write something strong, I'd need:
- Recent activity or engagement signals
- Context you have from prior conversations
- A specific reason for reaching out now

Can you share any of the above?
```

## Quality Standards

- Every message must reference something specific — generic outreach is not acceptable output
- Match tone to context: warm and conversational for inbound/community signals; more formal for cold/executive outreach
- The LinkedIn message must be under 300 characters — no exceptions
- The call script must be speakable naturally — read it aloud mentally to check rhythm
- **Never fabricate signals** — only reference data retrieved from Common Room or web search

## Reference Files

- **`references/outreach-formats-guide.md`** — detailed format rules, examples, and tone guidelines for each channel$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/common-room/skills/contact-research', 'business', 'contact-research', '', 'contact-research', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Contact Research

Retrieve a comprehensive contact profile from Common Room. Supports lookup by email, social handle, or name + company. Returns enriched data including activity history, Spark, scores, website visits, and CRM fields.

## Step 1: Locate the Contact

Common Room supports multiple lookup methods — use whichever the user has provided:

| What the user gives | Lookup method |
|---------------------|--------------|
| Email address | Look up by email (most reliable) |
| LinkedIn, Twitter/X, or GitHub handle | Look up by social handle — specify handle type explicitly |
| Name + company | Identity resolution by name + org domain; present matches if ambiguous |
| Name only | Search by name; if multiple matches, show a brief list and ask the user to confirm |

If no match is found, respond: "Common Room doesn't have a record for this person." Do not speculate or fabricate profile data.

## Step 2: Fetch Contact Fields

Use the Common Room object catalog to see available field groups and their contents. For full profiles, request all groups. For targeted questions, request only what's relevant.

**Key field groups to know about:**
- **Scores** — always return as raw values or percentiles, never labels
- **Recent activity** — use `Contact Initiated` filter (last 60 days) for their actions, not your team's
- **Website visits** — total count + specific pages (last 12 weeks)
- **Spark** — retrieve all Sparks when tracking engagement evolution over time

## Step 3: Run Spark Enrichment (If Available)

If Spark is available, use it. Spark provides:
- Professional background and job history
- Social presence and influence signals
- Persona classification: Champion, Economic Buyer, Technical Evaluator, End User, or Gatekeeper
- Inferred role in the buying process

If Spark is unavailable but real activity data exists (recent actions, website visits, community engagement), infer a persona from those signals. If neither Spark nor activity data is available, classify as Unknown — do not guess a persona from title alone.

Retrieve **all Sparks** (not just the most recent) when the user wants to understand how this contact's engagement has evolved over time.

## Step 4: Assess Account Context

Pull an abbreviated account snapshot for this contact's parent company. Note:
- Open opportunities, expansion signals, or churn risk at the account level
- Whether other contacts at this company are also active
- How this person's engagement compares to their colleagues

## Step 5: Identify Conversation Angles

Based on activity and signals, surface the strongest 2–3 hooks:
- A recent `Contact Initiated` activity (community post, product event, support ticket)
- A specific web page they visited recently — especially if it signals evaluation intent
- A job change, promotion, or company news
- Their Spark persona and what that suggests about communication style
- Their role in a known active deal

## Output Format

Only include sections where data was actually returned. Omit sections with no data rather than filling them with guesses.

**When data is rich:**

```
## [Contact Name] — Profile

**Overview**
[2 sentences: who they are, their role, and relationship status]

**Details**
- Title: [title]
- Company: [company]
- Email: [email]
- LinkedIn: [URL]
- Other profiles: [Twitter/X, GitHub, CRM link if available]

**Scores** [If scores returned]
[All scores as raw values or percentiles]

**Recent Activity** (last 60 days) [If activity returned]
[3–5 bullets with dates]

**Website Visits** (last 12 weeks) [If visit data exists]
[Total visit count + list of pages visited]

**Spark Profile** [If Spark data is non-null]
[Persona type, background summary, influence signals]

**Segments** [If segments returned]
[List of segment names this contact belongs to]

**Account Context**
[1–2 sentences on their company's status]

**Conversation Starters**
[2–3 specific, signal-backed openers]
```

**When data is sparse (e.g., only name, title, email, tags returned; sparkSummary is null):**

```
## [Contact Name] — Profile (Limited Data)

**Data available:** [List exactly what Common Room returned]

[Present only the returned fields]

**Web Search**
[Any findings from searching their name + company]

**Note:** Common Room has limited data on this contact. No activity history, scores, or Spark profile available. I can run deeper web searches or look up their company for additional context.
```

Do not generate conversation starters, persona inferences, or engagement assessments from sparse data. These require real signals.

## Quality Standards

- Lookup must use the correct method for the input type — don't guess on email vs. handle
- Scores as raw/percentile only — never labels
- `Contact Initiated` activity (last 60 days) is the primary engagement signal — lead with it
- If Spark is unavailable, say so — don't fabricate a persona from title alone
- Flag any contact where the most recent activity is older than 30 days

## Reference Files

- **`references/contact-signals-guide.md`** — full field descriptions, Spark persona guide, and conversation starter principles$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/common-room/skills/prospect', 'business', 'prospect', '', 'prospect', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Prospecting

Build targeted account and contact lists using Common Room's Prospector. Supports iterative refinement through natural conversation, intent-based discovery, and both net-new prospecting and signal-based queries against existing accounts.

## Critical Distinction: Two Object Types

Common Room's Prospector operates against two fundamentally different object types. Always clarify which one is in play before running a query:

**`ProspectorOrganization`** — Companies **not yet in Common Room**
- Net-new companies that match specified criteria
- Available fields are firmographic only: name, domain, size, industry, capital raised, annual revenue, location
- Fewer filter options — no signal-based filters, no scores, no activity history
- Use when: building a brand-new target list, territory planning, top-of-funnel expansion

**`Organization`** (in Common Room) — Companies **already in your CR workspace**
- Full signal data available: product usage, community activity, CRM fields, scores, custom fields
- Much richer filter set — includes signal-based, score-based, segment-based, and firmographic filters
- Use when: finding warm accounts to prioritize, identifying expansion candidates, surfacing intent signals within existing pipeline

When a user's request could apply to both (e.g., "Show companies hiring AI engineers this month"), clarify:
> "Are you looking for net-new companies not yet in Common Room, or filtering accounts already in your workspace?"

The catalog should make this distinction explicit so the LLM can select the right Prospector endpoint.

## Step 0: Load User Context (Me)

Fetch the `Me` object to get the user's segments. When prospecting against `Organization` records (accounts already in CR), default to filtering within "My Segments" unless the user asks for a broader search.

## Step 1: Gather Targeting Criteria

If criteria are already provided, proceed. Otherwise ask:

> "What kind of accounts or contacts are you looking for? For example: company size, industry, job titles, signals like recent product activity or community engagement, geographic region, or specific intent signals like recent funding or job postings."

Use the Common Room object catalog to see available filters for each object type. The key distinction:
- **ProspectorOrganization** — firmographic and technographic filters only (industry, size, geography, funding, tech stack)
- **Organization** — all firmographic filters plus signal-based, score-based, segment-based, and CRM filters

**Lookalike search:** If the user asks to "find companies like [X]", first look up the reference company in Common Room (or via web search if not in CR). Extract its key attributes — industry, employee range, tech stack, funding stage, geography — and propose those as filter criteria. Present the derived criteria to the user for confirmation before running the search, since lookalike targeting works best when the user can refine which attributes matter most.

## Step 2: Support Iterative Refinement

Prospecting is conversational. Support multi-turn refinement naturally:

1. Run initial query with provided criteria
2. If results are large (50+), summarize and offer: "I found [N] results. Want to narrow by [suggested filter]?"
3. If results are too few (< 5), suggest: "Only [N] results with those filters — I can broaden by relaxing [specific criterion]."
4. Apply each refinement as a follow-up query, not a new search from scratch

Example flow:
- Rep: "Find cybersecurity companies in California." → 500 results
- Rep: "Only show ones over 300 employees using AWS." → 47 results
- Rep: "Focus on the ones with recent hiring activity." → 12 results ✓

## Step 3: Run the Query and Present Results

Execute the Prospector query with confirmed criteria. Sort by signal strength or fit score where available (not alphabetically).

**For `ProspectorOrganization` (net-new) results:**

| Company | Domain | Industry | Size | Capital Raised | Revenue | Location |
|---------|--------|----------|------|---------------|---------|----------|

**For `Organization` (in CR) results:**

| Company | Industry | Size | Top Signal | Signal Date | Score | CRM Stage |
|---------|----------|------|-----------|-------------|-------|-----------|

Flag any results where data is thin or the most recent signal is older than 90 days.

## Step 3.5: Enrich Net-New Results with Web Search

For `ProspectorOrganization` results (net-new companies not in CR), run a quick web search on the top 3–5 companies to add context beyond firmographics. CR has no behavioral signals for these companies, so web search fills the gap — look for recent funding, product launches, leadership changes, or news coverage. Include findings as brief annotations next to each company in the results.

## Step 4: Offer Next Steps

- "Want me to draft outreach for the top 3–5 prospects?"
- "Should I run a full account brief on any of these?"
- "Want to refine the criteria or add another filter?"
- "I can format this as a CSV if you'd like to export it."
- "For any net-new companies here, I can add them to Common Room for enrichment." *(future capability)*

## Quality Standards

- Always confirm which object type (ProspectorOrg vs Organization) before running the query
- Default to "My Segments" when querying Organization records, unless user specifies otherwise
- Support iterative refinement — treat each follow-up as a filter adjustment, not a fresh start
- Never mix result fields from ProspectorOrganization and Organization in the same list
- Fewer high-quality results beat a long unqualified list
- **Only show data the query returned** — leave blank or "—" for missing fields, don't invent values

## Reference Files

- **`references/prospect-guide.md`** — filter types, signal-based sorting, object type distinctions, and list-building strategies$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/common-room/skills/weekly-prep-brief', 'business', 'weekly-prep-brief', '', 'weekly-prep-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Weekly Prep Brief

Generate a single comprehensive weekly briefing that covers every external customer or prospect call in the next 7 days, with per-meeting account and contact research from Common Room.

## Briefing Process

### Step 1: Get the Week's External Meetings

**Option A — Calendar connected:**
Use the `~~calendar` connector to fetch all meetings scheduled in the next 7 days (or a user-specified range). Filter to keep only external meetings — those with attendees from outside your organization. Discard internal-only meetings, one-on-ones with colleagues, and recurring internal syncs.

Identify for each external meeting:
- Company name
- Meeting date and time
- External attendee names and email addresses

**Option B — No calendar connected:**
Ask the user: "To build your weekly prep brief, I'll need your upcoming external calls. Please list them: company name, date/time, and attendee names."

Accept freeform input and parse it into a structured list before proceeding.

### Step 2: Confirm the Meeting List

Present the identified meetings to the user for confirmation before beginning research:

> "Here are the external calls I found for this week. Let me know if anything's missing or should be excluded:
> - [Company] — [Day], [Time] — [Attendees]
> - ..."

This prevents wasted research on cancelled or incorrect meetings.

### Step 3: Research Each Meeting

For each confirmed external meeting, run in parallel where possible:
1. **Account research** — full account snapshot using the account-research skill
2. **Contact research** — profile for each external attendee using the contact-research skill

Common Room data is the primary source. After CR research, run a quick **recency check** for each company — this is supplementary, not primary:
- Search `"[company name]" news` scoped to the last 7 days
- For executive attendees, search their name for recent public posts or interviews
- Only include findings that are genuinely noteworthy (funding, leadership changes, major press). Don't pad the brief with generic news.

Depth calibration:
- For high-priority accounts (large accounts, open opportunities, renewal risk), produce full depth research
- For lower-priority or short meetings, produce abbreviated snapshots (3–4 bullets each)

### Step 4: Synthesize the Weekly Brief

Compile all per-meeting research into a single structured document, sorted by meeting date/time.

Open with a brief week-level overview that flags:
- Any accounts with urgent signals (at-risk, trial expiring, expansion opportunity)
- Any meetings that need special preparation or executive involvement
- Total external call count and estimated time commitment

## Output Format

```
# Weekly Prep Brief — Week of [Date]

## Week Overview
[2–4 bullets: key themes, flagged priorities, call count]

---

## [Monday / Tuesday / etc.]

### [Company Name] — [Time]
**Attendees:** [Names and titles]
**Meeting type:** [Discovery / QBR / Renewal / Expansion / etc. — inferred if possible]

**Company Snapshot**
[4–5 bullets: account status, top signals, recent activity]

**Attendee Profiles**
- **[Name]** ([Title]): [2–3 bullets on their signals, persona, conversation angle]
- [Repeat per attendee]

**Top Signals This Week**
[2–3 most relevant signals for this specific call]

**This Week's News** [If notable news found]
[Only genuinely noteworthy findings — funding, leadership changes, major press]

**Recommended Objectives**
[1–2 sentences: what to accomplish in this meeting]

---

[Repeat per meeting, sorted by date/time]
```

## When a Meeting Has Sparse Data

If Common Room returns limited data for a particular meeting's account or attendees, use a compressed format for that meeting instead of the full template:

```
### [Company Name] — [Time] ⚠️ Limited Data
**Attendees:** [Names and titles if known]
**Data available:** [What Common Room actually returned]

**Web Search Results**
[Findings from web search — company news, attendee LinkedIn profiles]

**Note:** Common Room has limited data on this account. The rep may want to check directly in CR or gather context from colleagues before this call.
```

Do not generate a full meeting prep section (company snapshot, signal highlights, talking points, recommended objectives) from sparse data. A short honest section is more useful than a fabricated full one.

## Quality Standards

- Keep each meeting section scannable — reps read these in the morning, often on mobile
- Always sort by date/time ascending
- Flag urgent situations prominently (risk, trial expiration, open opps) — don't bury them
- If a meeting has very thin Common Room data, use the sparse-data format above — never fill the full template with guesses
- Total brief should be readable in 10–15 minutes for a week with 4–6 meetings
- **Every fact must come from a tool call** — no invented deal context, activity, or signals

## Reference Files

- **`references/briefing-guide.md`** — guidelines for structuring briefings, prioritization logic, and how to handle edge cases (cancelled meetings, new accounts with no data, etc.)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/slack/skills/slack-messaging', 'business', 'slack-messaging', '', 'slack-messaging', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Slack Messaging Best Practices

This skill provides guidance for composing well-formatted, effective Slack messages.

## When to Use

Apply this skill whenever composing, drafting, or helping the user write a Slack message — including when using `slack_send_message`, `slack_send_message_draft`, or `slack_create_canvas`.

## Slack Formatting (mrkdwn)

Slack uses its own markup syntax called **mrkdwn**, which differs from standard Markdown. Always use mrkdwn when composing Slack messages:

| Format | Syntax | Notes |
|--------|--------|-------|
| Bold | `*text*` | Single asterisks, NOT double |
| Italic | `_text_` | Underscores |
| Strikethrough | `~text~` | Tildes |
| Code (inline) | `` `code` `` | Backticks |
| Code block | `` ```code``` `` | Triple backticks |
| Quote | `> text` | Angle bracket |
| Link | `<url\|display text>` | Pipe-separated in angle brackets |
| User mention | `<@U123456>` | User ID in angle brackets |
| Channel mention | `<#C123456>` | Channel ID in angle brackets |
| Bulleted list | `- item` or `• item` | Dash or bullet character |
| Numbered list | `1. item` | Number followed by period |

### Common Mistakes to Avoid

- Do NOT use `**bold**` (double asterisks) — Slack uses `*bold*` (single asterisks)
- Do NOT use `## headers` — Slack does not support Markdown headers. Use `*bold text*` on its own line instead.
- Do NOT use `[text](url)` for links — Slack uses `<url|text>` format
- Do NOT use `---` for horizontal rules — Slack does not render these

## Message Structure Guidelines

- **Lead with the point.** Put the most important information in the first line. Many people read Slack on mobile or in notifications where only the first line shows.
- **Keep it short.** Aim for 1-3 short paragraphs. If the message is long, consider using a Canvas instead.
- **Use line breaks generously.** Walls of text are hard to read. Separate distinct thoughts with blank lines.
- **Use bullet points for lists.** Anything with 3+ items should be a list, not a run-on sentence.
- **Bold key information.** Use `*bold*` for names, dates, deadlines, and action items so they stand out when scanning.

## Thread vs. Channel Etiquette

- **Reply in threads** when responding to a specific message to keep the main channel clean.
- **Use `reply_broadcast`** (also post to channel) only when the reply contains information everyone needs to see.
- **Post in the channel** (not a thread) when starting a new topic, making an announcement, or asking a question to the whole group.
- **Don't start a new thread** to continue an existing conversation — find and reply to the original message.

## Tone and Audience

- Match the tone to the channel — `#general` is usually more formal than `#random`.
- Use emoji reactions instead of reply messages for simple acknowledgments (though note: the MCP tools can't add reactions, so suggest the user do this manually if appropriate).
- When writing announcements, use a clear structure: context, key info, call to action.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/slack/skills/slack-search', 'business', 'slack-search', '', 'slack-search', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Slack Search

This skill provides guidance for effectively searching Slack to find messages, files, and information.

## When to Use

Apply this skill whenever you need to find information in Slack — including when a user asks you to locate messages, conversations, files, or people, or when you need to gather context before answering a question about what's happening in Slack.

## Search Tools Overview

| Tool | Use When |
|------|----------|
| `slack_search_public` | Searching public channels only. Does not require user consent. |
| `slack_search_public_and_private` | Searching all channels including private, DMs, and group DMs. Requires user consent. |
| `slack_search_channels` | Finding channels by name or description. |
| `slack_search_users` | Finding people by name, email, or role. |

## Search Strategy

### Start Broad, Then Narrow

1. Begin with a simple keyword or natural language question.
2. If too many results, add filters (`in:`, `from:`, date ranges).
3. If too few results, remove filters and try synonyms or related terms.

### Choose the Right Search Mode

- **Natural language questions** (e.g., "What is the deadline for project X?") — Best for fuzzy, conceptual searches where you don't know exact keywords.
- **Keyword search** (e.g., `project X deadline`) — Best for finding specific, exact content.

### Use Multiple Searches

Don't rely on a single search. Break complex questions into smaller searches:
- Search for the topic first
- Then search for specific people's contributions
- Then search in specific channels

## Search Modifiers Reference

### Location Filters
- `in:channel-name` — Search within a specific channel
- `in:<#C123456>` — Search in channel by ID
- `-in:channel-name` — Exclude a channel
- `in:<@U123456>` — Search in DMs with a user

### User Filters
- `from:<@U123456>` — Messages from a specific user (by ID)
- `from:username` — Messages from a user (by Slack username)
- `to:me` — Messages sent directly to you

### Content Filters
- `is:thread` — Only threaded messages
- `has:pin` — Pinned messages
- `has:link` — Messages containing links
- `has:file` — Messages with file attachments
- `has::emoji:` — Messages with a specific reaction

### Date Filters
- `before:YYYY-MM-DD` — Messages before a date
- `after:YYYY-MM-DD` — Messages after a date
- `on:YYYY-MM-DD` — Messages on a specific date
- `during:month` — Messages during a specific month (e.g., `during:january`)

### Text Matching
- `"exact phrase"` — Match an exact phrase
- `-word` — Exclude messages containing a word
- `wild*` — Wildcard matching (minimum 3 characters before `*`)

## File Search

To search for files, use the `content_types="files"` parameter with type filters:
- `type:images` — Image files
- `type:documents` — Document files
- `type:pdfs` — PDF files
- `type:spreadsheets` — Spreadsheet files
- `type:canvases` — Slack Canvases

Example: `content_types="files" type:pdfs budget after:2025-01-01`

## Following Up on Results

After finding relevant messages:
- Use `slack_read_thread` to get the full thread context for any threaded message.
- Use `slack_read_channel` with `oldest`/`latest` timestamps to read surrounding messages for context.
- Use `slack_read_user_profile` to identify who a user is when their ID appears in results.

## Common Pitfalls

- **Boolean operators don't work.** `AND`, `OR`, `NOT` are not supported. Use spaces (implicit AND) and `-` for exclusion.
- **Parentheses don't work.** Don't try to group search terms with `()`.
- **Search is not real-time.** Very recent messages (last few seconds) may not appear in search results. Use `slack_read_channel` for the most recent messages.
- **Private channel access.** Use `slack_search_public_and_private` when you need to include private channels, but note this requires user consent.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/build-zoom-bot', 'business', 'build-zoom-bot', '', 'build-zoom-bot', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-bot

Use this skill for automation that joins meetings, captures media, or reacts to live session data.

## Covers

- Bot architecture
- Meeting join strategy
- Real-time media and transcript handling
- Backend orchestration
- Storage, post-processing, and event flow design

## Workflow

1. Clarify whether the bot needs to join, observe, transcribe, summarize, or act.
2. Route to Meeting SDK and RTMS as the core implementation path.
3. Add REST API for meeting/resource management and Webhooks for asynchronous events when needed.
4. Call out environment and lifecycle constraints early.

## Primary References

- [meeting-sdk](../meeting-sdk/SKILL.md)
- [rtms](../rtms/SKILL.md)
- [scribe](../scribe/SKILL.md)
- [rest-api](../rest-api/SKILL.md)
- [webhooks](../webhooks/SKILL.md)

## Common Mistakes

- Treating batch transcription and live media as the same workflow
- Designing the bot before defining join authority and auth model
- Forgetting post-meeting storage and retry behavior$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/build-zoom-meeting-app', 'business', 'build-zoom-meeting-app', '', 'build-zoom-meeting-app', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-meeting-app

Use this skill for embedded meeting experiences and meeting lifecycle implementation.

## Covers

- Meeting SDK selection and platform routing
- Join/auth implementation planning
- Meeting creation plus join flow design
- Web vs native platform considerations
- Meeting SDK vs Video SDK boundary decisions

## Workflow

1. Confirm whether the user wants a Zoom meeting or a custom video session.
2. Route to Meeting SDK if the user needs actual Zoom meetings.
3. Pull in the relevant platform references.
4. Add REST API only for meeting creation, resource management, or reporting.
5. Add webhooks or RTMS only when the use case explicitly needs them.

## Primary References

- [meeting-sdk](../meeting-sdk/SKILL.md)
- [rest-api](../rest-api/SKILL.md)
- [webhooks](../webhooks/SKILL.md)
- [rtms](../rtms/SKILL.md)
- [video-sdk](../video-sdk/SKILL.md)

## Common Mistakes

- Using Video SDK for normal Zoom meeting embeds
- Mixing resource-management APIs into the core join flow without reason
- Skipping platform-specific SDK constraints until too late$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/choose-zoom-approach', 'business', 'choose-zoom-approach', '', 'choose-zoom-approach', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Choose Zoom Approach

Pick the smallest correct Zoom surface for the job, then layer in only the supporting pieces that are actually required.

## Decision Framework

| Problem Type | Primary Zoom Surface |
|---|---|
| Deterministic backend automation, account management, reporting, scheduled jobs | [rest-api](../rest-api/SKILL.md) |
| Event delivery to your backend | [webhooks](../webhooks/SKILL.md) or [websockets](../websockets/SKILL.md) |
| Embed Zoom meetings into your app | [meeting-sdk](../meeting-sdk/SKILL.md) |
| Build a fully custom video experience | [video-sdk](../video-sdk/SKILL.md) |
| Build inside the Zoom client | [zoom-apps-sdk](../zoom-apps-sdk/SKILL.md) |
| AI-agent tool workflows over Zoom data | [zoom-mcp](../zoom-mcp/SKILL.md) |
| Real-time media extraction or meeting bots | [rtms](../rtms/SKILL.md) plus [meeting-sdk](../meeting-sdk/SKILL.md) when needed |
| Phone workflows | [phone](../phone/SKILL.md) |
| Contact Center or Virtual Agent flows | [contact-center](../contact-center/SKILL.md) or [virtual-agent](../virtual-agent/SKILL.md) |

## Guardrails

- Do not recommend Video SDK when the user actually needs Zoom meeting semantics.
- Do not recommend Meeting SDK when the user needs a fully custom session product.
- Do not replace deterministic backend automation with MCP-only guidance.
- Prefer hybrid `rest-api + zoom-mcp` when the user needs both stable system actions and AI-driven discovery.

## What To Produce

- One recommended path
- Minimum supporting components
- Hard constraints and tradeoffs
- Immediate next implementation step$body$)
ON CONFLICT (skill_key) DO NOTHING;
