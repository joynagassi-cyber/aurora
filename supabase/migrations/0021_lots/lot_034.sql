INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/engineering/skills/incident-response', 'business', 'incident-response', '', 'incident-response', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /incident-response

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Manage an incident from detection through postmortem.

## Usage

```
/incident-response $ARGUMENTS
```

## Modes

```
/incident-response new [description]     # Start a new incident
/incident-response update [status]       # Post a status update
/incident-response postmortem            # Generate postmortem from incident data
```

If no mode is specified, ask what phase the incident is in.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT RESPONSE                               │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: TRIAGE                                                  │
│  ✓ Assess severity (SEV1-4)                                     │
│  ✓ Identify affected systems and users                          │
│  ✓ Assign roles (IC, comms, responders)                         │
│                                                                    │
│  Phase 2: COMMUNICATE                                              │
│  ✓ Draft internal status update                                  │
│  ✓ Draft customer communication (if needed)                     │
│  ✓ Set up war room and cadence                                   │
│                                                                    │
│  Phase 3: MITIGATE                                                 │
│  ✓ Document mitigation steps taken                               │
│  ✓ Track timeline of events                                      │
│  ✓ Confirm resolution                                            │
│                                                                    │
│  Phase 4: POSTMORTEM                                               │
│  ✓ Blameless postmortem document                                 │
│  ✓ Timeline reconstruction                                       │
│  ✓ Root cause analysis (5 whys)                                  │
│  ✓ Action items with owners                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Severity Classification

| Level | Criteria | Response Time |
|-------|----------|---------------|
| SEV1 | Service down, all users affected | Immediate, all-hands |
| SEV2 | Major feature degraded, many users affected | Within 15 min |
| SEV3 | Minor feature issue, some users affected | Within 1 hour |
| SEV4 | Cosmetic or low-impact issue | Next business day |

## Communication Guidance

Provide clear, factual updates at regular cadence. Include: what's happening, who's affected, what we're doing, when the next update is.

## Output — Status Update

```markdown
## Incident Update: [Title]
**Severity:** SEV[1-4] | **Status:** Investigating | Identified | Monitoring | Resolved
**Impact:** [Who/what is affected]
**Last Updated:** [Timestamp]

### Current Status
[What we know now]

### Actions Taken
- [Action 1]
- [Action 2]

### Next Steps
- [What's happening next and ETA]

### Timeline
| Time | Event |
|------|-------|
| [HH:MM] | [Event] |
```

## Output — Postmortem

```markdown
## Postmortem: [Incident Title]
**Date:** [Date] | **Duration:** [X hours] | **Severity:** SEV[X]
**Authors:** [Names] | **Status:** Draft

### Summary
[2-3 sentence plain-language summary]

### Impact
- [Users affected]
- [Duration of impact]
- [Business impact if quantifiable]

### Timeline
| Time (UTC) | Event |
|------------|-------|
| [HH:MM] | [Event] |

### Root Cause
[Detailed explanation of what caused the incident]

### 5 Whys
1. Why did [symptom]? → [Because...]
2. Why did [cause 1]? → [Because...]
3. Why did [cause 2]? → [Because...]
4. Why did [cause 3]? → [Because...]
5. Why did [cause 4]? → [Root cause]

### What Went Well
- [Things that worked]

### What Went Poorly
- [Things that didn't work]

### Action Items
| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| [Action] | [Person] | P0/P1/P2 | [Date] |

### Lessons Learned
[Key takeaways for the team]
```

## If Connectors Available

If **~~monitoring** is connected:
- Pull alert details and metrics
- Show graphs of affected metrics

If **~~incident management** is connected:
- Create or update incident in PagerDuty/Opsgenie
- Page on-call responders

If **~~chat** is connected:
- Post status updates to incident channel
- Create war room channel

## Tips

1. **Start writing immediately** — Don't wait for complete information. Update as you learn more.
2. **Keep updates factual** — What we know, what we've done, what's next. No speculation.
3. **Postmortems are blameless** — Focus on systems and processes, not individuals.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/engineering/skills/standup', 'business', 'standup', '', 'standup', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /standup

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Generate a standup update by pulling together recent activity across your tools.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        STANDUP                                    │
├─────────────────────────────────────────────────────────────────┤
│  STANDALONE (always works)                                       │
│  ✓ Tell me what you worked on and I'll structure it             │
│  ✓ Format for daily standup (yesterday / today / blockers)      │
│  ✓ Keep it concise and action-oriented                          │
├─────────────────────────────────────────────────────────────────┤
│  SUPERCHARGED (when you connect your tools)                      │
│  + Source control: Recent commits and PRs                        │
│  + Project tracker: Ticket status changes                        │
│  + Chat: Relevant discussions and decisions                      │
│  + CI/CD: Build and deploy status                                │
└─────────────────────────────────────────────────────────────────┘
```

## What I Need From You

**Option A: Let me pull it**
If your tools are connected, just say `/standup` and I'll gather everything automatically.

**Option B: Tell me what you did**
"Worked on the auth migration, reviewed 3 PRs, got blocked on the API rate limiting issue."

## Output

```markdown
## Standup — [Date]

### Yesterday
- [Completed item with ticket reference if available]
- [Completed item]

### Today
- [Planned item with ticket reference]
- [Planned item]

### Blockers
- [Blocker with context and who can help]
```

## If Connectors Available

If **~~source control** is connected:
- Pull recent commits and PRs (opened, reviewed, merged)
- Summarize code changes at a high level

If **~~project tracker** is connected:
- Pull tickets moved to "in progress" or "done"
- Show upcoming sprint items

If **~~chat** is connected:
- Scan for relevant discussions and decisions
- Flag threads needing your response

## Tips

1. **Run it every morning** — Build a habit and never scramble for standup notes.
2. **Add context** — After I generate, add any nuance about blockers or priorities.
3. **Share format** — Ask me to format for Slack, email, or your team's standup tool.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/engineering/skills/system-design', 'business', 'system-design', '', 'system-design', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# System Design

Help design systems and evaluate architectural decisions.

## Framework

### 1. Requirements Gathering
- Functional requirements (what it does)
- Non-functional requirements (scale, latency, availability, cost)
- Constraints (team size, timeline, existing tech stack)

### 2. High-Level Design
- Component diagram
- Data flow
- API contracts
- Storage choices

### 3. Deep Dive
- Data model design
- API endpoint design (REST, GraphQL, gRPC)
- Caching strategy
- Queue/event design
- Error handling and retry logic

### 4. Scale and Reliability
- Load estimation
- Horizontal vs. vertical scaling
- Failover and redundancy
- Monitoring and alerting

### 5. Trade-off Analysis
- Every decision has trade-offs. Make them explicit.
- Consider: complexity, cost, team familiarity, time to market, maintainability

## Output

Produce clear, structured design documents with diagrams (ASCII or described), explicit assumptions, and trade-off analysis. Always identify what you'd revisit as the system grows.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/engineering/skills/tech-debt', 'business', 'tech-debt', '', 'tech-debt', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Tech Debt Management

Systematically identify, categorize, and prioritize technical debt.

## Categories

| Type | Examples | Risk |
|------|----------|------|
| **Code debt** | Duplicated logic, poor abstractions, magic numbers | Bugs, slow development |
| **Architecture debt** | Monolith that should be split, wrong data store | Scaling limits |
| **Test debt** | Low coverage, flaky tests, missing integration tests | Regressions ship |
| **Dependency debt** | Outdated libraries, unmaintained dependencies | Security vulns |
| **Documentation debt** | Missing runbooks, outdated READMEs, tribal knowledge | Onboarding pain |
| **Infrastructure debt** | Manual deploys, no monitoring, no IaC | Incidents, slow recovery |

## Prioritization Framework

Score each item on:
- **Impact**: How much does it slow the team down? (1-5)
- **Risk**: What happens if we don't fix it? (1-5)
- **Effort**: How hard is the fix? (1-5, inverted — lower effort = higher priority)

Priority = (Impact + Risk) x (6 - Effort)

## Output

Produce a prioritized list with estimated effort, business justification for each item, and a phased remediation plan that can be done alongside feature work.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/engineering/skills/testing-strategy', 'business', 'testing-strategy', '', 'testing-strategy', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Testing Strategy

Design effective testing strategies balancing coverage, speed, and maintenance.

## Testing Pyramid

```
        /  E2E  \         Few, slow, high confidence
       / Integration \     Some, medium speed
      /    Unit Tests  \   Many, fast, focused
```

## Strategy by Component Type

- **API endpoints**: Unit tests for business logic, integration tests for HTTP layer, contract tests for consumers
- **Data pipelines**: Input validation, transformation correctness, idempotency tests
- **Frontend**: Component tests, interaction tests, visual regression, accessibility
- **Infrastructure**: Smoke tests, chaos engineering, load tests

## What to Cover

Focus on: business-critical paths, error handling, edge cases, security boundaries, data integrity.

Skip: trivial getters/setters, framework code, one-off scripts.

## Output

Produce a test plan with: what to test, test type for each area, coverage targets, and example test cases. Identify gaps in existing coverage.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/enterprise-search/skills/digest', 'business', 'digest', '', 'digest', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Digest Command

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Scan recent activity across all connected sources and generate a structured digest highlighting what matters.

## Instructions

### 1. Parse Flags

Determine the time window from the user's input:

- `--daily` — Last 24 hours (default if no flag specified)
- `--weekly` — Last 7 days

The user may also specify a custom range:
- `--since yesterday`
- `--since Monday`
- `--since 2025-01-20`

### 2. Check Available Sources

Identify which MCP sources are connected (same approach as the search command):

- **~~chat** — channels, DMs, mentions
- **~~email** — inbox, sent, threads
- **~~cloud storage** — recently modified docs shared with user
- **~~project tracker** — tasks assigned, completed, commented on
- **~~CRM** — opportunity updates, account activity
- **~~knowledge base** — recently updated wiki pages

If no sources are connected, guide the user:
```
To generate a digest, you'll need at least one source connected.
Check your MCP settings to add ~~chat, ~~email, ~~cloud storage, or other tools.
```

### 3. Gather Activity from Each Source

**~~chat:**
- Search for messages mentioning the user (`to:me`)
- Check channels the user is in for recent activity
- Look for threads the user participated in
- Identify new messages in key channels

**~~email:**
- Search recent inbox messages
- Identify threads with new replies
- Flag emails with action items or questions directed at the user

**~~cloud storage:**
- Find documents recently modified or shared with the user
- Note new comments on docs the user owns or collaborates on

**~~project tracker:**
- Tasks assigned to the user (new or updated)
- Tasks completed by others that the user follows
- Comments on tasks the user is involved with

**~~CRM:**
- Opportunity stage changes
- New activities logged on accounts the user owns
- Updated contacts or accounts

**~~knowledge base:**
- Recently updated documents in relevant collections
- New documents created in watched areas

### 4. Identify Key Items

From all gathered activity, extract and categorize:

**Action Items:**
- Direct requests made to the user ("Can you...", "Please...", "@user")
- Tasks assigned or due soon
- Questions awaiting the user's response
- Review requests

**Decisions:**
- Conclusions reached in threads or emails
- Approvals or rejections
- Policy or direction changes

**Mentions:**
- Times the user was mentioned or referenced
- Discussions about the user's projects or areas

**Updates:**
- Status changes on projects the user follows
- Document updates in the user's domain
- Completed items the user was waiting on

### 5. Group by Topic

Organize the digest by topic, project, or theme rather than by source. Merge related activity across sources:

```
## Project Aurora
- ~~chat: Design review thread concluded — team chose Option B (#design, Tuesday)
- ~~email: Sarah sent updated spec incorporating feedback (Wednesday)
- ~~cloud storage: "Aurora API Spec v3" updated by Sarah (Wednesday)
- ~~project tracker: 3 tasks moved to In Progress, 2 completed

## Budget Planning
- ~~email: Finance team requesting Q2 projections by Friday
- ~~chat: Todd shared template in #finance (Monday)
- ~~cloud storage: "Q2 Budget Template" shared with you (Monday)
```

### 6. Format the Digest

Structure the output clearly:

```
# [Daily/Weekly] Digest — [Date or Date Range]

Sources scanned: ~~chat, ~~email, ~~cloud storage, [others]

## Action Items (X items)
- [ ] [Action item 1] — from [person], [source] ([date])
- [ ] [Action item 2] — from [person], [source] ([date])

## Decisions Made
- [Decision 1] — [context] ([source], [date])
- [Decision 2] — [context] ([source], [date])

## [Topic/Project Group 1]
[Activity summary with source attribution]

## [Topic/Project Group 2]
[Activity summary with source attribution]

## Mentions
- [Mention context] — [source] ([date])

## Documents Updated
- [Doc name] — [who modified, what changed] ([date])
```

### 7. Handle Unavailable Sources

If any source fails or is unreachable:
```
Note: Could not reach [source name] for this digest.
The following sources were included: [list of successful sources].
```

Do not let one failed source prevent the digest from being generated. Produce the best digest possible from available sources.

### 8. Summary Stats

End with a quick summary:
```
---
[X] action items · [Y] decisions · [Z] mentions · [W] doc updates
Across [N] sources · Covering [time range]
```

## Notes

- Default to `--daily` if no flag is specified
- Group by topic/project, not by source — users care about what happened, not where it happened
- Action items should always be listed first — they are the most actionable part of a digest
- Deduplicate cross-source activity (same decision in ~~chat and email = one entry)
- For weekly digests, prioritize significance over completeness — highlight what matters, skip noise
- If the user has a memory system (CLAUDE.md), use it to decode people names and project references
- Include enough context in each item that the user can decide whether to dig deeper without clicking through$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/enterprise-search/skills/knowledge-synthesis', 'business', 'knowledge-synthesis', '', 'knowledge-synthesis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Knowledge Synthesis

The last mile of enterprise search. Takes raw results from multiple sources and produces a coherent, trustworthy answer.

## The Goal

Transform this:
```
~~chat result: "Sarah said in #eng: 'let's go with REST, GraphQL is overkill for our use case'"
~~email result: "Subject: API Decision — Sarah's email confirming REST approach with rationale"
~~cloud storage result: "API Design Doc v3 — updated section 2 to reflect REST decision"
~~project tracker result: "Task: Finalize API approach — marked complete by Sarah"
```

Into this:
```
The team decided to go with REST over GraphQL for the API redesign. Sarah made the
call, noting that GraphQL was overkill for the current use case. This was discussed
in #engineering on Tuesday, confirmed via email Wednesday, and the design doc has
been updated to reflect the decision. The related ~~project tracker task is marked complete.

Sources:
- ~~chat: #engineering thread (Jan 14)
- ~~email: "API Decision" from Sarah (Jan 15)
- ~~cloud storage: "API Design Doc v3" (updated Jan 15)
- ~~project tracker: "Finalize API approach" (completed Jan 15)
```

## Deduplication

### Cross-Source Deduplication

The same information often appears in multiple places. Identify and merge duplicates:

**Signals that results are about the same thing:**
- Same or very similar text content
- Same author/sender
- Timestamps within a short window (same day or adjacent days)
- References to the same entity (project name, document, decision)
- One source references another ("as discussed in ~~chat", "per the email", "see the doc")

**How to merge:**
- Combine into a single narrative item
- Cite all sources where it appeared
- Use the most complete version as the primary text
- Add unique details from each source

### Deduplication Priority

When the same information exists in multiple sources, prefer:
```
1. The most complete version (fullest context)
2. The most authoritative source (official doc > chat)
3. The most recent version (latest update wins for evolving info)
```

### What NOT to Deduplicate

Keep as separate items when:
- The same topic is discussed but with different conclusions
- Different people express different viewpoints
- The information evolved meaningfully between sources (v1 vs v2 of a decision)
- Different time periods are represented

## Citation and Source Attribution

Every claim in the synthesized answer must be attributable to a source.

### Attribution Format

Inline for direct references:
```
Sarah confirmed the REST approach in her email on Wednesday.
The design doc was updated to reflect this (~~cloud storage: "API Design Doc v3").
```

Source list at the end for completeness:
```
Sources:
- ~~chat: #engineering discussion (Jan 14) — initial decision thread
- ~~email: "API Decision" from Sarah Chen (Jan 15) — formal confirmation
- ~~cloud storage: "API Design Doc v3" last modified Jan 15 — updated specification
```

### Attribution Rules

- Always name the source type (~~chat, ~~email, ~~cloud storage, etc.)
- Include the specific location (channel, folder, thread)
- Include the date or relative time
- Include the author when relevant
- Include document/thread titles when available
- For ~~chat, note the channel name
- For ~~email, note the subject line and sender
- For ~~cloud storage, note the document title

## Confidence Levels

Not all results are equally trustworthy. Assess confidence based on:

### Freshness

| Recency | Confidence impact |
|---------|------------------|
| Today / yesterday | High confidence for current state |
| This week | Good confidence |
| This month | Moderate — things may have changed |
| Older than a month | Lower confidence — flag as potentially outdated |

For status queries, heavily weight freshness. For policy/factual queries, freshness matters less.

### Authority

| Source type | Authority level |
|-------------|----------------|
| Official wiki / knowledge base | Highest — curated, maintained |
| Shared documents (final versions) | High — intentionally published |
| Email announcements | High — formal communication |
| Meeting notes | Moderate-high — may be incomplete |
| Chat messages (thread conclusions) | Moderate — informal but real-time |
| Chat messages (mid-thread) | Lower — may not reflect final position |
| Draft documents | Low — not finalized |
| Task comments | Contextual — depends on commenter |

### Expressing Confidence

When confidence is high (multiple fresh, authoritative sources agree):
```
The team decided to use REST for the API redesign. [direct statement]
```

When confidence is moderate (single source or somewhat dated):
```
Based on the discussion in #engineering last month, the team was leaning
toward REST for the API redesign. This may have evolved since then.
```

When confidence is low (old data, informal source, or conflicting signals):
```
I found a reference to an API migration discussion from three months ago
in ~~chat, but I couldn't find a formal decision document. The information
may be outdated. You might want to check with the team for current status.
```

### Conflicting Information

When sources disagree:
```
I found conflicting information about the API approach:
- The ~~chat discussion on Jan 10 suggested GraphQL
- But Sarah's email on Jan 15 confirmed REST
- The design doc (updated Jan 15) reflects REST

The most recent sources indicate REST was the final decision,
but the earlier ~~chat discussion explored GraphQL first.
```

Always surface conflicts rather than silently picking one version.

## Summarization Strategies

### For Small Result Sets (1-5 results)

Present each result with context. No summarization needed — give the user everything:
```
[Direct answer synthesized from results]

[Detail from source 1]
[Detail from source 2]

Sources: [full attribution]
```

### For Medium Result Sets (5-15 results)

Group by theme and summarize each group:
```
[Overall answer]

Theme 1: [summary of related results]
Theme 2: [summary of related results]

Key sources: [top 3-5 most relevant sources]
Full results: [count] items found across [sources]
```

### For Large Result Sets (15+ results)

Provide a high-level synthesis with the option to drill down:
```
[Overall answer based on most relevant results]

Summary:
- [Key finding 1] (supported by N sources)
- [Key finding 2] (supported by N sources)
- [Key finding 3] (supported by N sources)

Top sources:
- [Most authoritative/relevant source]
- [Second most relevant]
- [Third most relevant]

Found [total count] results across [source list].
Want me to dig deeper into any specific aspect?
```

### Summarization Rules

- Lead with the answer, not the search process
- Do not list raw results — synthesize them into narrative
- Group related items from different sources together
- Preserve important nuance and caveats
- Include enough detail that the user can decide whether to dig deeper
- Always offer to provide more detail if the result set was large

## Synthesis Workflow

```
[Raw results from all sources]
          ↓
[1. Deduplicate — merge same info from different sources]
          ↓
[2. Cluster — group related results by theme/topic]
          ↓
[3. Rank — order clusters and items by relevance to query]
          ↓
[4. Assess confidence — freshness × authority × agreement]
          ↓
[5. Synthesize — produce narrative answer with attribution]
          ↓
[6. Format — choose appropriate detail level for result count]
          ↓
[Coherent answer with sources]
```

## Anti-Patterns

**Do not:**
- List results source by source ("From ~~chat: ... From ~~email: ... From ~~cloud storage: ...")
- Include irrelevant results just because they matched a keyword
- Bury the answer under methodology explanation
- Present conflicting info without flagging the conflict
- Omit source attribution
- Present uncertain information with the same confidence as well-supported facts
- Summarize so aggressively that useful detail is lost

**Do:**
- Lead with the answer
- Group by topic, not by source
- Flag confidence levels when appropriate
- Surface conflicts explicitly
- Attribute all claims to sources
- Offer to go deeper when result sets are large$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/enterprise-search/skills/search', 'business', 'search', '', 'search', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Search Command

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Search across all connected MCP sources in a single query. Decompose the user's question, run parallel searches, and synthesize results.

## Instructions

### 1. Check Available Sources

Before searching, determine which MCP sources are available. Attempt to identify connected tools from the available tool list. Common sources:

- **~~chat** — chat platform tools
- **~~email** — email tools
- **~~cloud storage** — cloud storage tools
- **~~project tracker** — project tracking tools
- **~~CRM** — CRM tools
- **~~knowledge base** — knowledge base tools

If no MCP sources are connected:
```
To search across your tools, you'll need to connect at least one source.
Check your MCP settings to add ~~chat, ~~email, ~~cloud storage, or other tools.

Supported sources: ~~chat, ~~email, ~~cloud storage, ~~project tracker, ~~CRM, ~~knowledge base,
and any other MCP-connected service.
```

### 2. Parse the User's Query

Analyze the search query to understand:

- **Intent**: What is the user looking for? (a decision, a document, a person, a status update, a conversation)
- **Entities**: People, projects, teams, tools mentioned
- **Time constraints**: Recency signals ("this week", "last month", specific dates)
- **Source hints**: References to specific tools ("in ~~chat", "that email", "the doc")
- **Filters**: Extract explicit filters from the query:
  - `from:` — Filter by sender/author
  - `in:` — Filter by channel, folder, or location
  - `after:` — Only results after this date
  - `before:` — Only results before this date
  - `type:` — Filter by content type (message, email, doc, thread, file)

### 3. Decompose into Sub-Queries

For each available source, create a targeted sub-query using that source's native search syntax:

**~~chat:**
- Use available search and read tools for your chat platform
- Translate filters: `from:` maps to sender, `in:` maps to channel/room, dates map to time range filters
- Use natural language queries for semantic search when appropriate
- Use keyword queries for exact matches

**~~email:**
- Use available email search tools
- Translate filters: `from:` maps to sender, dates map to time range filters
- Map `type:` to attachment filters or subject-line searches as appropriate

**~~cloud storage:**
- Use available file search tools
- Translate to file query syntax: name contains, full text contains, modified date, file type
- Consider both file names and content

**~~project tracker:**
- Use available task search or typeahead tools
- Map to task text search, assignee filters, date filters, project filters

**~~CRM:**
- Use available CRM query tools
- Search across Account, Contact, Opportunity, and other relevant objects

**~~knowledge base:**
- Use semantic search for conceptual questions
- Use keyword search for exact matches

### 4. Execute Searches in Parallel

Run all sub-queries simultaneously across available sources. Do not wait for one source before searching another.

For each source:
- Execute the translated query
- Capture results with metadata (timestamps, authors, links, source type)
- Note any sources that fail or return errors — do not let one failure block others

### 5. Rank and Deduplicate Results

**Deduplication:**
- Identify the same information appearing across sources (e.g., a decision discussed in ~~chat AND confirmed via email)
- Group related results together rather than showing duplicates
- Prefer the most authoritative or complete version

**Ranking factors:**
- **Relevance**: How well does the result match the query intent?
- **Freshness**: More recent results rank higher for status/decision queries
- **Authority**: Official docs > wiki > chat messages for factual questions; conversations > docs for "what did we discuss" queries
- **Completeness**: Results with more context rank higher

### 6. Present Unified Results

Format the response as a synthesized answer, not a raw list of results:

**For factual/decision queries:**
```
[Direct answer to the question]

Sources:
- [Source 1: brief description] (~~chat, #channel, date)
- [Source 2: brief description] (~~email, from person, date)
- [Source 3: brief description] (~~cloud storage, doc name, last modified)
```

**For exploratory queries ("what do we know about X"):**
```
[Synthesized summary combining information from all sources]

Found across:
- ~~chat: X relevant messages in Y channels
- ~~email: X relevant threads
- ~~cloud storage: X related documents
- [Other sources as applicable]

Key sources:
- [Most important source with link/reference]
- [Second most important source]
```

**For "find" queries (looking for a specific thing):**
```
[The thing they're looking for, with direct reference]

Also found:
- [Related items from other sources]
```

### 7. Handle Edge Cases

**Ambiguous queries:**
If the query could mean multiple things, ask one clarifying question before searching:
```
"API redesign" could refer to a few things. Are you looking for:
1. The REST API v2 redesign (Project Aurora)
2. The internal SDK API changes
3. Something else?
```

**No results:**
```
I couldn't find anything matching "[query]" across [list of sources searched].

Try:
- Broader terms (e.g., "database" instead of "PostgreSQL migration")
- Different time range (currently searching [time range])
- Checking if the relevant source is connected (currently searching: [sources])
```

**Partial results (some sources failed):**
```
[Results from successful sources]

Note: I couldn't reach [failed source(s)] during this search.
Results above are from [successful sources] only.
```

## Notes

- Always search multiple sources in parallel — never sequentially
- Synthesize results into answers, do not just list raw search results
- Include source attribution so users can dig deeper
- Respect the user's filter syntax and apply it appropriately per source
- When a query mentions a specific person, search for their messages/docs/mentions across all sources
- For time-sensitive queries, prioritize recency in ranking
- If only one source is connected, still provide useful results from that source$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/enterprise-search/skills/search-strategy', 'business', 'search-strategy', '', 'search-strategy', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Search Strategy

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

The core intelligence behind enterprise search. Transforms a single natural language question into parallel, source-specific searches and produces ranked, deduplicated results.

## The Goal

Turn this:
```
"What did we decide about the API migration timeline?"
```

Into targeted searches across every connected source:
```
~~chat:  "API migration timeline decision" (semantic) + "API migration" in:#engineering after:2025-01-01
~~knowledge base: semantic search "API migration timeline decision"
~~project tracker:  text search "API migration" in relevant workspace
```

Then synthesize the results into a single coherent answer.

## Query Decomposition

### Step 1: Identify Query Type

Classify the user's question to determine search strategy:

| Query Type | Example | Strategy |
|-----------|---------|----------|
| **Decision** | "What did we decide about X?" | Prioritize conversations (~~chat, email), look for conclusion signals |
| **Status** | "What's the status of Project Y?" | Prioritize recent activity, task trackers, status updates |
| **Document** | "Where's the spec for Z?" | Prioritize Drive, wiki, shared docs |
| **Person** | "Who's working on X?" | Search task assignments, message authors, doc collaborators |
| **Factual** | "What's our policy on X?" | Prioritize wiki, official docs, then confirmatory conversations |
| **Temporal** | "When did X happen?" | Search with broad date range, look for timestamps |
| **Exploratory** | "What do we know about X?" | Broad search across all sources, synthesize |

### Step 2: Extract Search Components

From the query, extract:

- **Keywords**: Core terms that must appear in results
- **Entities**: People, projects, teams, tools (use memory system if available)
- **Intent signals**: Decision words, status words, temporal markers
- **Constraints**: Time ranges, source hints, author filters
- **Negations**: Things to exclude

### Step 3: Generate Sub-Queries Per Source

For each available source, create one or more targeted queries:

**Prefer semantic search** for:
- Conceptual questions ("What do we think about...")
- Questions where exact keywords are unknown
- Exploratory queries

**Prefer keyword search** for:
- Known terms, project names, acronyms
- Exact phrases the user quoted
- Filter-heavy queries (from:, in:, after:)

**Generate multiple query variants** when the topic might be referred to differently:
```
User: "Kubernetes setup"
Queries: "Kubernetes", "k8s", "cluster", "container orchestration"
```

## Source-Specific Query Translation

### ~~chat

**Semantic search** (natural language questions):
```
query: "What is the status of project aurora?"
```

**Keyword search:**
```
query: "project aurora status update"
query: "aurora in:#engineering after:2025-01-15"
query: "from:<@UserID> aurora"
```

**Filter mapping:**
| Enterprise filter | ~~chat syntax |
|------------------|--------------|
| `from:sarah` | `from:sarah` or `from:<@USERID>` |
| `in:engineering` | `in:engineering` |
| `after:2025-01-01` | `after:2025-01-01` |
| `before:2025-02-01` | `before:2025-02-01` |
| `type:thread` | `is:thread` |
| `type:file` | `has:file` |

### ~~knowledge base (Wiki)

**Semantic search** — Use for conceptual queries:
```
descriptive_query: "API migration timeline and decision rationale"
```

**Keyword search** — Use for exact terms:
```
query: "API migration"
query: "\"API migration timeline\""  (exact phrase)
```

### ~~project tracker

**Task search:**
```
text: "API migration"
workspace: [workspace_id]
completed: false  (for status queries)
assignee_any: "me"  (for "my tasks" queries)
```

**Filter mapping:**
| Enterprise filter | ~~project tracker parameter |
|------------------|----------------|
| `from:sarah` | `assignee_any` or `created_by_any` |
| `after:2025-01-01` | `modified_on_after: "2025-01-01"` |
| `type:milestone` | `resource_subtype: "milestone"` |

## Result Ranking

### Relevance Scoring

Score each result on these factors (weighted by query type):

| Factor | Weight (Decision) | Weight (Status) | Weight (Document) | Weight (Factual) |
|--------|-------------------|------------------|--------------------|-------------------|
| Keyword match | 0.3 | 0.2 | 0.4 | 0.3 |
| Freshness | 0.3 | 0.4 | 0.2 | 0.1 |
| Authority | 0.2 | 0.1 | 0.3 | 0.4 |
| Completeness | 0.2 | 0.3 | 0.1 | 0.2 |

### Authority Hierarchy

Depends on query type:

**For factual/policy questions:**
```
Wiki/Official docs > Shared documents > Email announcements > Chat messages
```

**For "what happened" / decision questions:**
```
Meeting notes > Thread conclusions > Email confirmations > Chat messages
```

**For status questions:**
```
Task tracker > Recent chat > Status docs > Email updates
```

## Handling Ambiguity

When a query is ambiguous, prefer asking one focused clarifying question over guessing:

```
Ambiguous: "search for the migration"
→ "I found references to a few migrations. Are you looking for:
   1. The database migration (Project Phoenix)
   2. The cloud migration (AWS → GCP)
   3. The email migration (Exchange → O365)"
```

Only ask for clarification when:
- There are genuinely distinct interpretations that would produce very different results
- The ambiguity would significantly affect which sources to search

Do NOT ask for clarification when:
- The query is clear enough to produce useful results
- Minor ambiguity can be resolved by returning results from multiple interpretations

## Fallback Strategies

When a source is unavailable or returns no results:

1. **Source unavailable**: Skip it, search remaining sources, note the gap
2. **No results from a source**: Try broader query terms, remove date filters, try alternate keywords
3. **All sources return nothing**: Suggest query modifications to the user
4. **Rate limited**: Note the limitation, return results from other sources, suggest retrying later

### Query Broadening

If initial queries return too few results:
```
Original: "PostgreSQL migration Q2 timeline decision"
Broader:  "PostgreSQL migration"
Broader:  "database migration"
Broadest: "migration"
```

Remove constraints in this order:
1. Date filters (search all time)
2. Source/location filters
3. Less important keywords
4. Keep only core entity/topic terms

## Parallel Execution

Always execute searches across sources in parallel, never sequentially. The total search time should be roughly equal to the slowest single source, not the sum of all sources.

```
[User query]
     ↓ decompose
[~~chat query] [~~email query] [~~cloud storage query] [Wiki query] [~~project tracker query]
     ↓            ↓            ↓              ↓            ↓
  (parallel execution)
     ↓
[Merge + Rank + Deduplicate]
     ↓
[Synthesized answer]
```$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/enterprise-search/skills/source-management', 'business', 'source-management', '', 'source-management', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Source Management

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Knows what sources are available, helps connect new ones, and manages how sources are queried.

## Checking Available Sources

Determine which MCP sources are connected by checking available tools. Each source corresponds to a set of MCP tools:

| Source | Key capabilities |
|--------|-----------------|
| **~~chat** | Search messages, read channels and threads |
| **~~email** | Search messages, read individual emails |
| **~~cloud storage** | Search files, fetch document contents |
| **~~project tracker** | Search tasks, typeahead search |
| **~~CRM** | Query records (accounts, contacts, opportunities) |
| **~~knowledge base** | Semantic search, keyword search |

If a tool prefix is available, the source is connected and searchable.

## Guiding Users to Connect Sources

When a user searches but has few or no sources connected:

```
You currently have [N] source(s) connected: [list].

To expand your search, you can connect additional sources in your MCP settings:
- ~~chat — messages, threads, channels
- ~~email — emails, conversations, attachments
- ~~cloud storage — docs, sheets, slides
- ~~project tracker — tasks, projects, milestones
- ~~CRM — accounts, contacts, opportunities
- ~~knowledge base — wiki pages, knowledge base articles

The more sources you connect, the more complete your search results.
```

When a user asks about a specific tool that is not connected:

```
[Tool name] isn't currently connected. To add it:
1. Open your MCP settings
2. Add the [tool] MCP server configuration
3. Authenticate when prompted

Once connected, it will be automatically included in future searches.
```

## Source Priority Ordering

Different query types benefit from searching certain sources first. Use these priorities to weight results, not to skip sources:

### By Query Type

**Decision queries** ("What did we decide..."):
```
1. ~~chat (conversations where decisions happen)
2. ~~email (decision confirmations, announcements)
3. ~~cloud storage (meeting notes, decision logs)
4. Wiki (if decisions are documented)
5. Task tracker (if decisions are captured in tasks)
```

**Status queries** ("What's the status of..."):
```
1. Task tracker (~~project tracker — authoritative status)
2. ~~chat (real-time discussion)
3. ~~cloud storage (status docs, reports)
4. ~~email (status update emails)
5. Wiki (project pages)
```

**Document queries** ("Where's the doc for..."):
```
1. ~~cloud storage (primary doc storage)
2. Wiki / ~~knowledge base (knowledge base)
3. ~~email (docs shared via email)
4. ~~chat (docs shared in channels)
5. Task tracker (docs linked to tasks)
```

**People queries** ("Who works on..." / "Who knows about..."):
```
1. ~~chat (message authors, channel members)
2. Task tracker (task assignees)
3. ~~cloud storage (doc authors, collaborators)
4. ~~CRM (account owners, contacts)
5. ~~email (email participants)
```

**Factual/Policy queries** ("What's our policy on..."):
```
1. Wiki / ~~knowledge base (official documentation)
2. ~~cloud storage (policy docs, handbooks)
3. ~~email (policy announcements)
4. ~~chat (policy discussions)
```

### Default Priority (General Queries)

When query type is unclear:
```
1. ~~chat (highest volume, most real-time)
2. ~~email (formal communications)
3. ~~cloud storage (documents and files)
4. Wiki / ~~knowledge base (structured knowledge)
5. Task tracker (work items)
6. CRM (customer data)
```

## Rate Limiting Awareness

MCP sources may have rate limits. Handle them gracefully:

### Detection

Rate limit responses typically appear as:
- HTTP 429 responses
- Error messages mentioning "rate limit", "too many requests", or "quota exceeded"
- Throttled or delayed responses

### Handling

When a source is rate limited:

1. **Do not retry immediately** — respect the limit
2. **Continue with other sources** — do not block the entire search
3. **Inform the user**:
```
Note: [Source] is temporarily rate limited. Results below are from
[other sources]. You can retry in a few minutes to include [source].
```
4. **For digests** — if rate limited mid-scan, note which time range was covered before the limit hit

### Prevention

- Avoid unnecessary API calls — check if the source is likely to have relevant results before querying
- Use targeted queries over broad scans when possible
- For digests, batch requests where the API supports it
- Cache awareness: if a search was just run, avoid re-running the same query immediately

## Source Health

Track source availability during a session:

```
Source Status:
  ~~chat:        ✓ Available
  ~~email:        ✓ Available
  ~~cloud storage:  ✓ Available
  ~~project tracker:        ✗ Not connected
  ~~CRM:   ✗ Not connected
  ~~knowledge base:      ⚠ Rate limited (retry in 2 min)
```

When reporting search results, include which sources were searched so the user knows the scope of the answer.

## Adding Custom Sources

The enterprise search plugin works with any MCP-connected source. As new MCP servers become available, they can be added to the `.mcp.json` configuration. The search and digest commands will automatically detect and include new sources based on available tools.

To add a new source:
1. Add the MCP server configuration to `.mcp.json`
2. Authenticate if required
3. The source will be included in subsequent searches automatically$body$)
ON CONFLICT (skill_key) DO NOTHING;
