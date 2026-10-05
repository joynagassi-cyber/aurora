INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/draft-content', 'business', 'draft-content', '', 'draft-content', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Draft Content

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Generate marketing content drafts tailored to a specific content type, audience, and brand voice.

## Trigger

User runs `/draft-content` or asks to draft, write, or create marketing content.

## Inputs

Gather the following from the user. If not provided, ask before proceeding:

1. **Content type** — one of:
   - Blog post
   - Social media post (specify platform: LinkedIn, Twitter/X, Instagram, Facebook)
   - Email newsletter
   - Landing page copy
   - Press release
   - Case study

2. **Topic** — the subject or theme of the content

3. **Target audience** — who this content is for (role, industry, seniority, pain points)

4. **Key messages** — 2-4 main points or takeaways to communicate

5. **Tone** — e.g., authoritative, conversational, inspirational, technical, witty (optional if brand voice is configured)

6. **Length** — target word count or format constraint (e.g., "1000 words", "280 characters", "3 paragraphs")

## Brand Voice

- If the user has a brand voice configured in their local settings file, apply it automatically. Inform the user that brand voice settings are being applied.
- If no brand voice is configured, ask: "Do you have brand voice guidelines you'd like me to follow? If not, I'll use a neutral professional tone."
- Apply the specified or default tone consistently throughout the draft.

## Content Generation by Type

### Blog Post
- Engaging headline (provide 2-3 options)
- Introduction with a hook (question, statistic, bold statement, or story)
- 3-5 organized sections with descriptive subheadings
- Supporting points, examples, or data references in each section
- Conclusion with a clear call to action
- SEO considerations: suggest a primary keyword, include it in the headline and first paragraph, use related keywords in subheadings

### Social Media Post
- Platform-appropriate format and length
- Hook in the first line
- Hashtag suggestions (3-5 relevant hashtags)
- Call to action or engagement prompt
- Emoji usage appropriate to brand and platform
- If LinkedIn: professional framing, paragraph breaks for readability
- If Twitter/X: concise, punchy, within character limit
- If Instagram: visual-first language, story-driven, hashtag block

### Email Newsletter
- Subject line (provide 2-3 options with open-rate considerations)
- Preview text
- Greeting
- Body sections with clear hierarchy
- Call to action button text
- Sign-off
- Unsubscribe note reminder

### Landing Page Copy
- Headline and subheadline
- Hero section copy
- Value propositions (3-4 benefit-driven bullets or sections)
- Social proof placeholder (suggest testimonial or stat placement)
- Primary and secondary CTAs
- FAQ section suggestions
- SEO: meta title and meta description suggestions

### Press Release
- Headline following press release conventions
- Dateline and location
- Lead paragraph (who, what, when, where, why)
- Supporting quotes (provide placeholder guidance)
- Company boilerplate placeholder
- Media contact placeholder
- Standard press release formatting

### Case Study
- Title emphasizing the result
- Customer overview (industry, size, challenge)
- Challenge section
- Solution section (what was implemented)
- Results section with metrics (prompt user for data)
- Customer quote placeholder
- Call to action

## SEO Considerations (for web content)

For blog posts, landing pages, and other web-facing content:
- Suggest a primary keyword based on the topic
- Recommend keyword placement: headline, first paragraph, subheadings, meta description
- Suggest internal and external linking opportunities
- Recommend a meta description (under 160 characters)
- Note image alt text opportunities

## Output

Present the draft with clear formatting. After the draft, include:
- A brief note on what brand voice and tone were applied
- Any SEO recommendations (for web content)
- Suggestions for next steps (e.g., "Review with your team", "Add customer quotes", "Pair with a visual")

Ask: "Would you like me to revise any section, adjust the tone, or create a variation for a different channel?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/email-sequence', 'business', 'email-sequence', '', 'email-sequence', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Email Sequence

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Design and draft complete email sequences with full copy, timing, branching logic, and performance benchmarks for any lifecycle or campaign use case.

## Trigger

User runs `/email-sequence` or asks to create, design, build, or draft an email sequence, drip campaign, nurture flow, or onboarding series.

## Inputs

Gather the following from the user. If not provided, ask before proceeding:

1. **Sequence type** — one of:
   - Onboarding
   - Lead nurture
   - Re-engagement
   - Product launch
   - Event follow-up
   - Upgrade/upsell
   - Win-back
   - Educational drip

2. **Goal** — what the sequence should achieve (e.g., activate new users, convert leads to customers, reduce churn, drive event attendance, upsell to a higher tier)

3. **Audience** — who receives this sequence, what stage they are at, and any relevant segmentation details (role, industry, behavior triggers, lifecycle stage)

4. **Number of emails** (optional) — if not specified, recommend a count based on the sequence type using the templates in the Sequence Type Templates section below

5. **Timing/cadence preferences** (optional) — desired spacing between emails (e.g., "every 3 days", "weekly", "aggressive first week then taper off")

6. **Brand voice** — if configured in local settings, apply automatically and inform the user. If not configured, ask: "Do you have brand voice guidelines I should follow? If not, I'll use a clear, conversational professional tone."

7. **Additional context** (optional):
   - Specific offers, discounts, or incentives to include
   - CTAs or landing pages to link to
   - Content assets available (blog posts, case studies, videos, guides)
   - Product features to highlight
   - Competitor differentiators to reference

## Process

### 1. Sequence Strategy

Before drafting any emails, define the overall sequence architecture:

- **Narrative arc** — what story does this sequence tell across all emails? What is the emotional and logical progression from first email to last?
- **Journey mapping** — map each email to a stage of the buyer or user journey (awareness, consideration, decision, activation, expansion)
- **Escalation logic** — how does the intensity, urgency, or value of each email build on the previous one?
- **Success definition** — what specific action signals that the sequence has done its job and the recipient should exit?

### 2. Individual Email Design

For each email in the sequence, produce:

#### Subject Line
- Provide 2-3 options per email
- Vary approaches: curiosity, benefit-driven, urgency, personalization, question-based
- Keep under 50 characters where possible; note preview behavior on mobile

#### Preview Text
- 40-90 characters that complement (not repeat) the subject line
- Should add context or intrigue that increases open likelihood

#### Email Purpose
- One sentence explaining why this email exists and what it moves the recipient toward

#### Body Copy
- Full draft ready to use
- Clear hierarchy: hook, body, CTA
- Short paragraphs (2-3 sentences max)
- Scannable formatting with bold key phrases where appropriate
- Personalization tokens where relevant (e.g., first name, company name, product used)

#### Primary CTA
- Button text and destination
- One primary CTA per email (secondary CTA only if appropriate for the sequence stage)

#### Timing
- Days after the trigger event or after the previous email
- Note if timing should adjust based on engagement (e.g., "send sooner if they opened but did not click")

#### Segment/Condition Notes
- Who receives this email vs. who skips it
- Any behavioral or attribute-based conditions (e.g., "only send to users who have not completed setup")

### 3. Sequence Logic

Define the flow control for the sequence:

- **Branching conditions** — alternate paths based on engagement. For example:
  - "If opened email 2 but did not click CTA, send email 2b (softer re-ask) instead of email 3"
  - "If clicked CTA in email 1, skip email 2 and go directly to email 3"
- **Exit conditions** — when a recipient converts (completes the desired action), remove them from the sequence. Define what "conversion" means for this sequence.
- **Re-entry rules** — can someone re-enter the sequence? Under what conditions? (e.g., "if a user churns again 90 days later, re-enter the win-back sequence")
- **Suppression rules** — do not send if the recipient is already in another active sequence, has unsubscribed from marketing, or has contacted support in the last 48 hours

### 4. Performance Benchmarks

Provide expected benchmarks based on the sequence type so the user can set targets:

| Metric | Onboarding | Lead Nurture | Re-engagement | Win-back |
|--------|-----------|--------------|---------------|----------|
| Open rate | 50-70% | 20-30% | 15-25% | 15-20% |
| Click-through rate | 10-20% | 3-7% | 2-5% | 2-4% |
| Conversion rate | 15-30% | 2-5% | 3-8% | 1-3% |
| Unsubscribe rate | <0.5% | <0.5% | 1-2% | 1-3% |

Adjust benchmarks based on industry and audience if the user has provided that context.

## Sequence Type Templates

Use these as starting frameworks. Adapt length and content based on the user's goal and audience.

**Onboarding (5-7 emails over 14-21 days):**
Welcome and set expectations -- Quick win to demonstrate value -- Core feature deep dive -- Advanced feature or integration -- Social proof and community -- Check-in and feedback request -- Upgrade prompt or next steps

**Lead Nurture (4-6 emails over 3-4 weeks):**
Value-first educational content -- Pain point identification -- Solution positioning with proof -- Social proof and results -- Soft CTA (trial, demo, resource) -- Direct CTA (buy, book, sign up)

**Re-engagement (3-4 emails over 10-14 days):**
"We miss you" with a compelling reason to return -- Value reminder highlighting what they are missing -- Incentive or exclusive offer -- Last chance with clear deadline

**Win-back (3-5 emails over 30 days):**
Friendly check-in asking what went wrong -- What is new since they left -- Special offer or incentive to return -- Feedback request (even if they do not come back) -- Final goodbye with door open

**Product Launch (4-6 emails over 2-3 weeks):**
Teaser or pre-announcement -- Launch announcement with full details -- Feature spotlight or use case -- Social proof and early results -- Limited-time offer or bonus -- Last chance or reminder

**Event Follow-up (3-4 emails over 7-10 days):**
Thank you with key takeaways or recordings -- Resource roundup from the event -- Related offer or next step -- Feedback survey

**Upgrade/Upsell (3-5 emails over 2-3 weeks):**
Usage milestone or success celebration -- Feature gap or limitation they are hitting -- Upgrade benefits with proof -- Limited-time incentive -- Direct comparison of plans

**Educational Drip (5-8 emails over 4-6 weeks):**
Introduction and what they will learn -- Lesson 1: foundational concept -- Lesson 2: intermediate concept -- Lesson 3: advanced concept -- Practical application or exercise -- Resource roundup -- Graduation and next steps

## Tool Integration

### If ~~email marketing is connected (e.g., Klaviyo, Mailchimp, Customer.io)
- Reference how to set up the sequence as a flow or automation in the platform
- Note any platform-specific features to use (e.g., smart send time, conditional splits, A/B testing)
- Map the branching logic to the platform's visual flow builder concepts

### If ~~marketing automation or ~~CRM is connected (e.g., HubSpot, Marketo)
- Reference lead scoring data to inform segmentation and exit conditions
- Use lifecycle stage data to tailor messaging per segment
- Note how to set enrollment triggers based on CRM properties or list membership

### If no tools are connected
- Deliver all email content in copy-paste-ready format
- Include a setup checklist the user can follow in any email platform:
  1. Create the automation or flow
  2. Set the enrollment trigger
  3. Add each email with the specified delays
  4. Configure branching and exit conditions
  5. Set up tracking for the recommended metrics

## Output

Present the complete sequence with the following sections:

### Sequence Overview Table

| # | Subject Line | Purpose | Timing | Primary CTA | Condition |
|---|-------------|---------|--------|-------------|-----------|

### Full Email Drafts
Each email with subject line options, preview text, purpose, body copy, CTA, timing, and segment notes.

### Sequence Flow Diagram
A text-based diagram showing the email flow, branching paths, and exit points. Use a clear format such as:

```
[Trigger] --> Email 1 (Day 0)
                |
          Opened? --Yes--> Email 2 (Day 3)
                |              |
                No        Clicked CTA? --Yes--> [EXIT: Converted]
                |              |
                v              No
          Email 1b (Day 2)     |
                |              v
                +--------> Email 3 (Day 7)
                               |
                               v
                          Email 4 (Day 10)
                               |
                          [EXIT: Sequence complete]
```

### Branching Logic Notes
Summary of all conditions, exits, and suppressions in a reference list.

### A/B Test Suggestions
- 2-3 recommended A/B tests (subject lines, CTA text, send time, email length)
- What to test, how to split, and how to measure the winner

### Metrics to Track
- Primary conversion metric for the sequence
- Per-email metrics: open rate, CTR, unsubscribe rate
- Sequence-level metrics: overall conversion rate, time to conversion, drop-off points
- Recommended review cadence (e.g., "Review performance weekly for the first month, then monthly")

## After the Sequence

Ask: "Would you like me to:
- Revise the copy or tone for any specific email?
- Add a branching path for a specific scenario?
- Create a variation of this sequence for a different audience segment?
- Draft the A/B test variants for the subject lines?
- Build a companion sequence (e.g., a post-purchase follow-up after this lead nurture converts)?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/performance-report', 'business', 'performance-report', '', 'performance-report', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Performance Report

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Generate a marketing performance report with key metrics, trend analysis, insights, and optimization recommendations.

## Trigger

User runs `/performance-report` or asks for a marketing report, performance analysis, campaign results, or metrics summary.

## Inputs

1. **Report type** — determine which type of report the user needs:
   - **Campaign report** — performance of a specific campaign
   - **Channel report** — performance across a specific channel (email, social, paid, SEO, etc.)
   - **Content performance** — how content pieces are performing
   - **Overall marketing report** — cross-channel summary (weekly, monthly, quarterly)
   - **Custom** — user-defined scope

2. **Time period** — the reporting window (last week, last month, last quarter, custom date range)

3. **Data source**:
   - If ~~marketing analytics is connected, discover what accounts and platforms are available, then pull performance data automatically
   - If ~~product analytics is connected: pull performance data automatically
   - If not connected: ask the user to provide metrics. Prompt with: "Please paste or share your performance data. I can work with spreadsheets, CSV data, dashboard screenshots described in text, or just the key numbers."

4. **Comparison period** (optional) — prior period or year-over-year for trend context

5. **Stakeholder audience** (optional) — who will read this report (executive summary style vs. detailed analyst view)

## Report Structure

### 1. Executive Summary
- 2-3 sentence overview of performance in the period
- Headline metric with trend direction (up/down/flat vs. prior period)
- One key win and one area of concern

### 2. Key Metrics Dashboard

Present core metrics in a summary table:

| Metric | This Period | Prior Period | Change | Target | Status |
|--------|------------|--------------|--------|--------|--------|

Status indicators:
- On track (meeting or exceeding target)
- At risk (below target but within acceptable range)
- Off track (significantly below target)

#### Metrics by Report Type

**Campaign Report:**
- Impressions and reach
- Click-through rate (CTR)
- Conversion rate
- Cost per acquisition (CPA)
- Return on ad spend (ROAS) or ROI
- Total conversions/signups/leads

**Channel Report (Email):**
- Emails sent, delivered, bounced
- Open rate
- Click-through rate
- Unsubscribe rate
- Conversion rate

**Channel Report (Social):**
- Impressions and reach
- Engagement rate (likes, comments, shares)
- Follower growth
- Click-through rate
- Top-performing posts

**Channel Report (Paid):**
- Spend
- Impressions and clicks
- CTR
- CPC and CPM
- Conversions and CPA
- ROAS

**Channel Report (SEO/Organic):**
- Organic sessions
- Keyword rankings (movement)
- Pages indexed
- Backlinks acquired
- Top-performing pages

**Content Performance:**
- Pageviews and unique visitors
- Time on page
- Bounce rate
- Social shares
- Conversions attributed to content
- Top and bottom performers

**Overall Marketing Report:**
- Total leads generated
- Marketing qualified leads (MQLs)
- Pipeline contribution
- Customer acquisition cost (CAC)
- Channel-by-channel summary

### 3. Trend Analysis
- Performance trend over the period (week-over-week or month-over-month)
- Notable inflection points and what caused them
- Seasonal or cyclical patterns observed
- Comparison to benchmarks or targets

### 4. What Worked
- Top 3-5 wins with specific data
- Why these performed well (hypothesis)
- How to replicate or scale

### 5. What Needs Improvement
- Bottom 3-5 performers with specific data
- Hypotheses for underperformance
- Recommended fixes

### 6. Insights and Observations
- Patterns in the data that are not obvious from the metrics alone
- Audience behavior insights
- Content or creative themes that resonated
- External factors that may have influenced performance (seasonality, news, competitive moves)

### 7. Recommendations
For each recommendation:
- What to do
- Why (linked to a specific insight from the data)
- Expected impact (high, medium, low)
- Effort to implement (high, medium, low)
- Priority (immediate, next sprint, next quarter)

Prioritize recommendations in a 2x2 matrix format:

| | Low Effort | High Effort |
|---|---|---|
| **High Impact** | Do first | Plan for next sprint |
| **Low Impact** | Do if time allows | Deprioritize |

### 8. Next Period Focus
- Top 3 priorities for the upcoming period
- Tests or experiments to run
- Targets for key metrics

## Metric Definitions and Benchmarks

### Email Marketing

| Metric | Definition | Benchmark Range | What It Tells You |
|--------|-----------|----------------|-------------------|
| Delivery rate | Emails delivered / emails sent | 95-99% | List health and sender reputation |
| Open rate | Unique opens / emails delivered | 15-30% | Subject line and sender effectiveness |
| Click-through rate (CTR) | Unique clicks / emails delivered | 2-5% | Content relevance and CTA effectiveness |
| Click-to-open rate (CTOR) | Unique clicks / unique opens | 10-20% | Email content quality (for those who opened) |
| Unsubscribe rate | Unsubscribes / emails delivered | <0.5% | Content-audience fit and frequency tolerance |
| Bounce rate | Bounces / emails sent | <2% | List quality and data hygiene |
| Conversion rate | Conversions / emails delivered | 1-5% | End-to-end email effectiveness |
| Revenue per email | Total revenue / emails sent | Varies | Direct revenue attribution |
| List growth rate | (New subscribers - unsubscribes) / total list | 2-5% monthly | Audience building health |

### Social Media

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| Impressions | Number of times content was displayed | Content distribution and reach |
| Reach | Number of unique users who saw content | Audience breadth |
| Engagement rate | (Likes + comments + shares) / reach | Content resonance |
| Click-through rate | Link clicks / impressions | Traffic driving effectiveness |
| Follower growth rate | Net new followers / total followers per period | Audience building |
| Share/Repost rate | Shares / reach | Content virality and advocacy |
| Video view rate | Views / impressions | Video content hook effectiveness |
| Video completion rate | Completed views / total views | Video content quality and length fit |
| Social share of voice | Your mentions / total category mentions | Brand visibility vs. competitors |

### Paid Advertising (Search and Social)

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| Impressions | Times ad was shown | Budget utilization and targeting breadth |
| Click-through rate (CTR) | Clicks / impressions | Ad creative and targeting relevance |
| Cost per click (CPC) | Total spend / clicks | Cost efficiency of traffic generation |
| Cost per mille (CPM) | Cost per 1,000 impressions | Awareness cost efficiency |
| Conversion rate | Conversions / clicks | Landing page and offer effectiveness |
| Cost per acquisition (CPA) | Total spend / conversions | Full-funnel cost efficiency |
| Return on ad spend (ROAS) | Revenue / ad spend | Revenue generation efficiency |
| Quality Score (search) | Google's relevance rating (1-10) | Ad-keyword-landing page alignment |
| Frequency | Average times a user sees the ad | Ad fatigue risk |
| View-through conversions | Conversions from users who saw but did not click | Display/awareness campaign influence |

### SEO / Organic Search

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| Organic sessions | Visits from organic search | SEO effectiveness and content reach |
| Keyword rankings | Position for target keywords | Search visibility |
| Organic CTR | Clicks / impressions in search results | Title and meta description effectiveness |
| Pages indexed | Number of pages in search index | Crawlability and site health |
| Domain authority | Third-party authority score | Overall site strength |
| Backlinks | Number of external sites linking to you | Content authority and off-page SEO |
| Page load speed | Time to interactive | User experience and ranking factor |
| Organic conversion rate | Organic conversions / organic sessions | Content quality and intent alignment |
| Top entry pages | Most-visited pages from organic search | Content driving the most organic traffic |

### Content Marketing

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| Pageviews | Total views of content pages | Content reach and distribution |
| Unique visitors | Distinct users viewing content | Audience size |
| Average time on page | Time spent on content pages | Content engagement and depth |
| Bounce rate | Single-page sessions / total sessions | Content-audience fit and UX |
| Scroll depth | How far users scroll on a page | Content engagement through the piece |
| Social shares | Times content was shared on social | Content resonance and virality |
| Backlinks earned | External links to content | Content authority and SEO value |
| Lead generation | Leads attributed to content | Content conversion effectiveness |
| Content ROI | Revenue attributed / content production cost | Overall content investment return |

### Overall Marketing / Pipeline

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| Marketing qualified leads (MQLs) | Leads meeting marketing qualification criteria | Top-of-funnel effectiveness |
| Sales qualified leads (SQLs) | MQLs accepted by sales | Lead quality |
| MQL to SQL conversion rate | SQLs / MQLs | Marketing-sales alignment and lead quality |
| Pipeline generated | Dollar value of opportunities created | Marketing impact on revenue |
| Pipeline velocity | How fast deals move through pipeline | Campaign urgency and quality |
| Customer acquisition cost (CAC) | Total marketing + sales cost / new customers | Efficiency of customer acquisition |
| CAC payback period | Months to recover CAC from revenue | Unit economics health |
| Marketing-sourced revenue | Revenue from marketing-originated deals | Direct marketing contribution |
| Marketing-influenced revenue | Revenue from deals where marketing touched | Broader marketing impact |

## Reporting Templates by Cadence

### Weekly Marketing Report
Quick-scan format for team standups:
- **Top 3 metrics** with week-over-week change
- **What worked** this week (1-2 bullet points with data)
- **What needs attention** (1-2 bullet points with data)
- **This week's priorities** (3-5 action items)

### Monthly Marketing Report
Standard stakeholder report:
1. Executive summary (3-5 sentences)
2. Key metrics dashboard (table with MoM and target comparison)
3. Channel-by-channel performance summary
4. Campaign highlights and results
5. What worked and what did not (with hypotheses)
6. Recommendations and next month priorities
7. Budget spend vs. plan

### Quarterly Business Review (QBR)
Strategic review for leadership:
1. Quarter performance vs. goals
2. Year-to-date trajectory
3. Channel ROI analysis
4. Campaign performance summary
5. Competitive and market observations
6. Strategic recommendations for next quarter
7. Budget request and allocation plan
8. Key experiments and learnings

### Dashboard Design Principles
- Lead with the metrics that map to business objectives (not vanity metrics)
- Show trends over time, not just point-in-time snapshots
- Include comparison context: prior period, target, benchmark
- Use consistent color coding: green (on track), yellow (at risk), red (off track)
- Group metrics by funnel stage or business question
- Keep dashboards to one page/screen — detail goes in appendix
- Update cadence should match decision cadence (real-time for paid, weekly for content)

## Trend Analysis and Forecasting

### Trend Identification
When analyzing performance data, look for:

1. **Directional trends**: is the metric consistently going up, down, or flat over 4+ periods?
2. **Inflection points**: where did performance change direction and what happened then?
3. **Seasonality**: are there predictable patterns by day of week, month, or quarter?
4. **Anomalies**: one-time spikes or drops — what caused them and are they repeatable?
5. **Leading indicators**: which metrics change first and predict future outcomes?

### Trend Analysis Process
1. Chart the metric over time (at least 8-12 data points for meaningful trends)
2. Identify the overall direction (upward, downward, flat, cyclical)
3. Calculate the rate of change (is it accelerating or decelerating?)
4. Overlay key events (campaigns launched, product changes, market events)
5. Compare to benchmarks or targets
6. Identify correlations with other metrics
7. Form hypotheses about causation (and plan tests to validate)

### Simple Forecasting Approaches
- **Linear projection**: extend the current trend line forward (useful for stable metrics)
- **Moving average**: smooth out noise by averaging the last 3-6 periods
- **Year-over-year comparison**: use last year's pattern as a baseline, adjusted for growth rate
- **Funnel math**: forecast outputs from inputs (e.g., if we generate X leads at Y conversion rate, we will get Z customers)
- **Scenario modeling**: create best case, expected case, and worst case projections

### Forecasting Caveats
- Short-term forecasts (1-3 months) are more reliable than long-term
- Forecasts based on fewer than 12 data points should be flagged as low confidence
- External factors (market shifts, competitive moves, economic changes) can invalidate trend-based forecasts
- Always present forecasts as ranges, not exact numbers

## Attribution Modeling Basics

### What Is Attribution?
Attribution determines which marketing touchpoints get credit for a conversion. This matters because buyers typically interact with multiple channels before converting.

### Common Attribution Models

| Model | How It Works | Best For | Limitation |
|-------|-------------|----------|------------|
| Last touch | 100% credit to last interaction before conversion | Understanding final conversion triggers | Ignores awareness and nurture |
| First touch | 100% credit to first interaction | Understanding top-of-funnel effectiveness | Ignores nurture and conversion drivers |
| Linear | Equal credit to all touchpoints | Fair representation of all channels | Does not reflect relative impact |
| Time decay | More credit to touchpoints closer to conversion | Balanced view favoring recent interactions | May undervalue awareness |
| Position-based (U-shaped) | 40% first, 40% last, 20% split among middle | Valuing both discovery and conversion | Somewhat arbitrary weighting |
| Data-driven | Algorithmic credit based on conversion patterns | Most accurate representation | Requires significant data volume |

### Attribution Practical Guidance
- Start with last-touch attribution if you have no model in place — it is the simplest and most actionable
- Compare first-touch and last-touch to understand which channels drive awareness vs. conversion
- Use position-based (U-shaped) as a reasonable middle ground for most B2B companies
- Data-driven attribution requires high conversion volume to be statistically meaningful
- No model is perfect — use attribution directionally, not as absolute truth
- Multi-touch attribution is better than single-touch, but any model is better than none

### Attribution Pitfalls
- Do not optimize one channel in isolation based on single-touch attribution
- Awareness channels (display, social, PR) will always look bad in last-touch models
- Conversion channels (search, retargeting) will always look bad in first-touch models
- Self-reported attribution ("how did you hear about us?") provides useful qualitative color but is unreliable as quantitative data
- Cross-device and cross-channel tracking gaps mean attribution data is always incomplete

## Optimization Recommendations Framework

### Optimization Process
1. **Identify**: which metrics are underperforming vs. target or benchmark?
2. **Diagnose**: where in the funnel is the problem? (impressions, clicks, conversions, retention)
3. **Hypothesize**: what is causing the underperformance? (audience, message, creative, offer, timing, technical)
4. **Prioritize**: which fixes will have the biggest impact with the least effort?
5. **Test**: design an experiment to validate the hypothesis
6. **Measure**: did the change improve the metric?
7. **Scale or iterate**: roll out wins broadly; iterate on inconclusive or failed tests

### Optimization Levers by Funnel Stage

| Funnel Stage | Problem Signal | Optimization Levers |
|-------------|---------------|---------------------|
| Awareness | Low impressions, low reach | Budget, targeting, channel mix, creative format |
| Interest | Low CTR, low engagement | Ad creative, headlines, content hooks, audience targeting |
| Consideration | High bounce rate, low time on page | Landing page content, page speed, content relevance, UX |
| Conversion | Low conversion rate | Offer, CTA, form length, trust signals, page layout |
| Retention | High churn, low repeat engagement | Onboarding, email nurture, product experience, support |

### Testing Best Practices
- Test one variable at a time for clean results
- Define the success metric before launching the test
- Calculate required sample size before starting (do not end tests early)
- Run tests for a minimum of one full business cycle (typically one week for B2B)
- Document all tests and results, regardless of outcome
- Share learnings across the team — failed tests are valuable information
- A test that confirms the status quo is not a failure — it builds confidence in your current approach

### Continuous Optimization Cadence
- **Daily**: monitor paid campaigns for budget pacing, anomalies, and disapproved ads
- **Weekly**: review channel performance, pause underperformers, scale winners
- **Bi-weekly**: refresh ad creative and test new variants
- **Monthly**: full performance review, identify new optimization opportunities, update forecasts
- **Quarterly**: strategic review of channel mix, budget allocation, and targeting strategy

## Output Formatting

- Use tables for data presentation
- Bold key numbers and trends
- Keep the executive summary concise (suitable for forwarding to leadership)
- Include a "detailed appendix" section for granular data if the user provided a lot of metrics

## After the Report

Ask: "Would you like me to:
- Create a slide-ready summary of these results?
- Draft a stakeholder email with the key takeaways?
- Dive deeper into any specific metric or channel?
- Set up a reporting template you can reuse next period?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/seo-audit', 'business', 'seo-audit', '', 'seo-audit', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /seo-audit

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Audit a website's SEO health, research keyword opportunities, identify content gaps, and benchmark against competitors. Produces a prioritized action plan a marketer can execute immediately.

## Trigger

User runs `/seo-audit` or asks for an SEO audit, keyword research, content gap analysis, technical SEO check, or competitor SEO comparison.

## Inputs

Gather the following from the user. If not provided, ask before proceeding:

1. **URL or domain** — the site to audit, or a topic/keyword if running in keyword research mode

2. **Audit type** — one of:
   - **Full site audit** — end-to-end SEO review covering all sections below
   - **Keyword research** — identify keyword opportunities for a topic or domain
   - **Content gap analysis** — find topics competitors rank for that you don't
   - **Technical SEO check** — crawlability, speed, structured data, and infrastructure issues
   - **Competitor SEO comparison** — head-to-head SEO benchmarking against specific competitors

   If not specified, default to **full site audit**.

3. **Target keywords or topics** (optional) — specific keywords the user is already targeting or wants to rank for

4. **Competitors** (optional) — domains or companies to compare against. If not provided and the audit type requires competitor data, use web search to identify 2-3 likely competitors based on the user's domain and keyword space.

## Process

### 1. Keyword Research

Research keywords related to the user's domain, topic, or target keywords.

**If ~~SEO tools are connected:**
- Pull keyword data, search volume, keyword difficulty scores, and ranking positions automatically
- Identify keywords the site currently ranks for and where it's gaining or losing ground

**If ~~product analytics are connected:**
- Cross-reference keyword targets with actual organic traffic data to validate which keywords are driving visits and conversions

**If tools are not connected:**
- Use web search to research the keyword landscape
- Note: "For more precise volume and difficulty data, connect an SEO tool like Ahrefs or Semrush via MCP. The audit will auto-populate with ranking data."

For each keyword opportunity, assess:
- **Primary keywords** — high-intent terms directly tied to the user's product or service
- **Secondary keywords** — supporting terms and variations
- **Search volume signals** — relative demand (high, medium, low) based on available data
- **Keyword difficulty** — how competitive the term is (easy, moderate, hard)
- **Long-tail opportunities** — specific, lower-competition phrases with clear intent
- **Question-based keywords** — "how to", "what is", "why does" queries that mirror People Also Ask results
- **Intent classification** — informational, navigational, commercial, or transactional

### 2. On-Page SEO Audit

For each key page (homepage, top landing pages, recent blog posts), evaluate:

- **Title tags** — present, unique, within 50-60 characters, includes target keyword
- **Meta descriptions** — present, compelling, within 150-160 characters, includes a call to action
- **H1 tags** — exactly one per page, includes primary keyword
- **H2/H3 structure** — logical hierarchy, uses secondary keywords where natural
- **Keyword usage** — primary keyword appears in the first 100 words, used naturally throughout, not over-stuffed
- **Internal linking** — pages link to related content, orphan pages identified, anchor text is descriptive
- **Image alt text** — all images have descriptive alt attributes, keywords included where relevant
- **URL structure** — clean, readable, includes keywords, no excessive parameters or depth

### 3. Content Gap Analysis

Identify what's missing from the user's content strategy:

- **Competitor topic coverage** — topics and keywords competitors rank for that the user's site does not cover
- **Content freshness** — pages that haven't been updated in 12+ months and may be losing rankings
- **Thin content** — pages with insufficient depth to rank (under 300 words for informational queries, lacking substance)
- **Missing content types** — formats competitors use that the user doesn't (guides, comparison pages, glossaries, tools, templates)
- **Funnel gaps** — missing content at specific buyer journey stages (awareness, consideration, decision)
- **Topic clusters** — opportunities to build pillar pages with supporting content

### 4. Technical SEO Checklist

Evaluate technical foundations that affect crawlability and rankings:

- **Page speed** — identify slow-loading pages and likely causes (large images, render-blocking scripts, excessive redirects)
- **Mobile-friendliness** — responsive design, tap targets, font sizes, viewport configuration
- **Structured data** — opportunities for schema markup (FAQ, HowTo, Product, Article, Organization, Breadcrumb)
- **Crawlability** — robots.txt configuration, XML sitemap presence and accuracy, canonical tags, noindex/nofollow usage
- **Broken links** — internal and external 404s, redirect chains
- **HTTPS** — secure connection, mixed content issues
- **Core Web Vitals signals** — LCP, FID/INP, CLS indicators based on observable page behavior
- **Indexation** — pages that should be indexed but may not be, duplicate content risks

### 5. Competitor SEO Comparison

For each competitor, compare:

- **Keyword overlap** — keywords both sites rank for, and where each site ranks higher
- **Keyword gaps** — terms the competitor ranks for that the user does not
- **Domain authority signals** — relative site strength based on backlink profiles, referring domains, and content depth
- **Content depth** — average content length, topic coverage breadth, publishing frequency
- **Backlink profile observations** — types of sites linking to competitors, link-worthy content they've produced
- **SERP feature ownership** — which competitor appears in featured snippets, People Also Ask, image packs, or knowledge panels
- **Technical advantages** — site speed differences, mobile experience, structured data usage

## Output

### Executive Summary

Open with a 3-5 sentence summary of overall SEO health. Highlight:
- The site's biggest strength
- The top 3 priorities that will have the most impact
- An overall assessment: strong foundation, needs work, or critical issues

### Keyword Opportunity Table

| Keyword | Est. Difficulty | Opportunity Score | Current Ranking | Intent | Recommended Content Type |
|---------|----------------|-------------------|-----------------|--------|--------------------------|

Opportunity score: high, medium, or low — based on the combination of search demand, difficulty, and relevance to the user's business.

Include 15-25 keyword opportunities, sorted by opportunity score.

### On-Page Issues Table

| Page | Issue | Severity | Recommended Fix |
|------|-------|----------|-----------------|

Severity levels:
- **Critical** — directly hurting rankings or preventing indexation
- **High** — significant impact on SEO performance
- **Medium** — best practice violation, moderate impact
- **Low** — minor optimization opportunity

### Content Gap Recommendations

For each content gap identified, provide:
- **Topic or keyword** to target
- **Why it matters** — search demand, competitor coverage, funnel stage
- **Recommended format** — blog post, landing page, guide, comparison page, etc.
- **Priority** — high, medium, or low
- **Estimated effort** — quick win (1-2 hours), moderate (half day), substantial (multi-day)

### Technical SEO Checklist

| Check | Status | Details |
|-------|--------|---------|

Status: Pass, Fail, or Warning.

### Competitor Comparison Summary

| Dimension | Your Site | Competitor A | Competitor B | Winner |
|-----------|-----------|--------------|--------------|--------|

Include rows for: keyword count, content depth, publishing frequency, backlink signals, technical score, SERP feature presence.

### Prioritized Action Plan

Split recommendations into two categories:

**Quick Wins (do this week):**
- Actions that take under 2 hours and have immediate impact
- Examples: fix title tags, add meta descriptions, fix broken links, add alt text

**Strategic Investments (plan for this quarter):**
- Actions that require more effort but drive long-term growth
- Examples: build a topic cluster, create a pillar page, launch a link-building campaign, overhaul site structure

For each action item, include:
- What to do (specific and concrete)
- Expected impact (high, medium, low)
- Effort estimate
- Dependencies (if any)

## Follow-Up

After presenting the audit, ask:

"Would you like me to:
- Draft content briefs for the top keyword opportunities?
- Create optimized title tags and meta descriptions for your key pages?
- Build a content calendar based on the gap analysis?
- Dive deeper into any specific section of the audit?
- Run this same analysis for a different competitor or domain?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/capacity-plan', 'business', 'capacity-plan', '', 'capacity-plan', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /capacity-plan

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Analyze team capacity and plan resource allocation.

## Usage

```
/capacity-plan $ARGUMENTS
```

## What I Need From You

- **Team size and roles**: Who do you have?
- **Current workload**: What are they working on? (Upload from project tracker or describe)
- **Upcoming work**: What's coming next quarter?
- **Constraints**: Budget, hiring timeline, skill requirements

## Planning Dimensions

### People
- Available headcount and skills
- Current allocation and utilization
- Planned hires and timeline
- Contractor and vendor capacity

### Budget
- Operating budget by category
- Project-specific budgets
- Variance tracking
- Forecast vs. actual

### Time
- Project timelines and dependencies
- Critical path analysis
- Buffer and contingency planning
- Deadline management

## Utilization Targets

| Role Type | Target Utilization | Notes |
|-----------|-------------------|-------|
| IC / Specialist | 75-80% | Leave room for reactive work and growth |
| Manager | 60-70% | Management overhead, meetings, 1:1s |
| On-call / Support | 50-60% | Interrupt-driven work is unpredictable |

## Common Pitfalls

- Planning to 100% utilization (no buffer for surprises)
- Ignoring meeting load and context-switching costs
- Not accounting for vacation, holidays, and sick time
- Treating all hours as equal (creative work ≠ admin work)

## Output

```markdown
## Capacity Plan: [Team/Project]
**Period:** [Date range] | **Team Size:** [X]

### Current Utilization
| Person/Role | Capacity | Allocated | Available | Utilization |
|-------------|----------|-----------|-----------|-------------|
| [Name/Role] | [hrs/wk] | [hrs/wk] | [hrs/wk] | [X]% |

### Capacity Summary
- **Total capacity**: [X] hours/week
- **Currently allocated**: [X] hours/week ([X]%)
- **Available**: [X] hours/week ([X]%)
- **Overallocated**: [X people above 100%]

### Upcoming Demand
| Project/Initiative | Start | End | Resources Needed | Gap |
|--------------------|-------|-----|-----------------|-----|
| [Project] | [Date] | [Date] | [X FTEs] | [Covered/Gap] |

### Bottlenecks
- [Skill or role that's oversubscribed]
- [Time period with a crunch]

### Recommendations
1. [Hire / Contract / Reprioritize / Delay]
2. [Specific action]

### Scenarios
| Scenario | Outcome |
|----------|---------|
| Do nothing | [What happens] |
| Hire [X] | [What changes] |
| Deprioritize [Y] | [What frees up] |
```

## If Connectors Available

If **~~project tracker** is connected:
- Pull current workload and ticket assignments automatically
- Show upcoming sprint or quarter commitments per person

If **~~calendar** is connected:
- Factor in PTO, holidays, and recurring meeting load
- Calculate actual available hours per person

## Tips

1. **Include all work** — BAU, projects, support, meetings. People aren't 100% available for project work.
2. **Plan for buffer** — Target 80% utilization. 100% means no room for surprises.
3. **Update regularly** — Capacity plans go stale fast. Review monthly.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/change-request', 'business', 'change-request', '', 'change-request', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /change-request

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Create a structured change request with impact analysis, risk assessment, and rollback plan.

## Usage

```
/change-request $ARGUMENTS
```

## Change Management Framework

Apply the assess-plan-execute-sustain framework when building the request:

### 1. Assess
- What is changing?
- Who is affected?
- How significant is the change? (Low / Medium / High)
- What resistance should we expect?

### 2. Plan
- Communication plan (who, what, when, how)
- Training plan (what skills are needed, how to deliver)
- Support plan (help desk, champions, FAQs)
- Timeline with milestones

### 3. Execute
- Announce and explain the "why"
- Train and support
- Monitor adoption
- Address resistance

### 4. Sustain
- Measure adoption and effectiveness
- Reinforce new behaviors
- Address lingering issues
- Document lessons learned

## Communication Principles

- Explain the **why** before the **what**
- Communicate early and often
- Use multiple channels
- Acknowledge what's being lost, not just what's being gained
- Provide a clear path for questions and concerns

## Output

```markdown
## Change Request: [Title]
**Requester:** [Name] | **Date:** [Date] | **Priority:** [Critical/High/Medium/Low]
**Status:** Draft | Pending Approval | Approved | In Progress | Complete

### Description
[What is changing and why]

### Business Justification
[Why this change is needed — cost savings, compliance, efficiency, risk reduction]

### Impact Analysis
| Area | Impact | Details |
|------|--------|---------|
| Users | [High/Med/Low/None] | [Who is affected and how] |
| Systems | [High/Med/Low/None] | [What systems are affected] |
| Processes | [High/Med/Low/None] | [What workflows change] |
| Cost | [High/Med/Low/None] | [Budget impact] |

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [How to mitigate] |

### Implementation Plan
| Step | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| [Step] | [Person] | [Date] | [What it depends on] |

### Communication Plan
| Audience | Message | Channel | Timing |
|----------|---------|---------|--------|
| [Who] | [What to tell them] | [How] | [When] |

### Rollback Plan
[Step-by-step plan to reverse the change if needed]
- Trigger: [When to roll back]
- Steps: [How to roll back]
- Verification: [How to confirm rollback worked]

### Approvals Required
| Approver | Role | Status |
|----------|------|--------|
| [Name] | [Role] | Pending |
```

## If Connectors Available

If **~~ITSM** is connected:
- Create the change request ticket automatically
- Pull change advisory board schedule and approval workflows

If **~~project tracker** is connected:
- Link to related implementation tasks and dependencies
- Track change progress against milestones

If **~~chat** is connected:
- Draft stakeholder notifications for the communication plan
- Post change updates to the relevant team channels

## Tips

1. **Be specific about impact** — "Everyone" is not an impact assessment. "200 users in the billing team" is.
2. **Always have a rollback plan** — Even if you're confident, plan for failure.
3. **Communicate early** — Surprises create resistance. Previews create buy-in.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/compliance-tracking', 'business', 'compliance-tracking', '', 'compliance-tracking', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Compliance Tracking

Help track compliance requirements, prepare for audits, and maintain regulatory readiness.

## Common Frameworks

| Framework | Focus | Key Requirements |
|-----------|-------|-----------------|
| SOC 2 | Service organizations | Security, availability, processing integrity, confidentiality, privacy |
| ISO 27001 | Information security | Risk assessment, security controls, continuous improvement |
| GDPR | Data privacy (EU) | Consent, data rights, breach notification, DPO |
| HIPAA | Healthcare data (US) | PHI protection, access controls, audit trails |
| PCI DSS | Payment card data | Encryption, access control, vulnerability management |

## Compliance Tracking Components

### Control Inventory
- Map controls to framework requirements
- Document control owners and evidence
- Track control effectiveness

### Audit Calendar
- Upcoming audit dates and deadlines
- Evidence collection timelines
- Remediation deadlines

### Evidence Management
- What evidence is needed for each control
- Where evidence is stored
- When evidence was last collected

### Gap Analysis
- Requirements vs. current state
- Prioritized remediation plan
- Timeline to compliance

## Output

Produce compliance status dashboards, gap analyses, audit prep checklists, and evidence collection plans.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/process-doc', 'business', 'process-doc', '', 'process-doc', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /process-doc

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Document a business process as a complete standard operating procedure (SOP).

## Usage

```
/process-doc $ARGUMENTS
```

## How It Works

Walk me through the process — describe it, paste existing docs, or just tell me the name and I'll ask the right questions. I'll produce a complete SOP.

## Output

```markdown
## Process Document: [Process Name]
**Owner:** [Person/Team] | **Last Updated:** [Date] | **Review Cadence:** [Quarterly/Annually]

### Purpose
[Why this process exists and what it accomplishes]

### Scope
[What's included and excluded]

### RACI Matrix
| Step | Responsible | Accountable | Consulted | Informed |
|------|------------|-------------|-----------|----------|
| [Step] | [Who does it] | [Who owns it] | [Who to ask] | [Who to tell] |

### Process Flow
[ASCII flowchart or step-by-step description]

### Detailed Steps

#### Step 1: [Name]
- **Who**: [Role]
- **When**: [Trigger or timing]
- **How**: [Detailed instructions]
- **Output**: [What this step produces]

#### Step 2: [Name]
[Same format]

### Exceptions and Edge Cases
| Scenario | What to Do |
|----------|-----------|
| [Exception] | [How to handle it] |

### Metrics
| Metric | Target | How to Measure |
|--------|--------|----------------|
| [Metric] | [Target] | [Method] |

### Related Documents
- [Link to related process or policy]
```

## If Connectors Available

If **~~knowledge base** is connected:
- Search for existing process documentation to update rather than duplicate
- Publish the completed SOP to your wiki

If **~~project tracker** is connected:
- Link the process to related projects and workflows
- Create tasks for process improvement action items

## Tips

1. **Start messy** — You don't need a perfect description. Tell me how it works today and I'll structure it.
2. **Include the exceptions** — "Usually we do X, but sometimes Y" is the most valuable part to document.
3. **Name the people** — Even if roles change, knowing who does what today helps get the process right.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/process-optimization', 'business', 'process-optimization', '', 'process-optimization', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Process Optimization

Analyze existing processes and recommend improvements.

## Analysis Framework

### 1. Map Current State
- Document every step, decision point, and handoff
- Identify who does what and how long each step takes
- Note manual steps, approvals, and waiting times

### 2. Identify Waste
- **Waiting**: Time spent in queues or waiting for approvals
- **Rework**: Steps that fail and need to be redone
- **Handoffs**: Each handoff is a potential point of failure or delay
- **Over-processing**: Steps that add no value
- **Manual work**: Tasks that could be automated

### 3. Design Future State
- Eliminate unnecessary steps
- Automate where possible
- Reduce handoffs
- Parallelize independent steps
- Add checkpoints (not gates)

### 4. Measure Impact
- Time saved per cycle
- Error rate reduction
- Cost savings
- Employee satisfaction improvement

## Output

Produce a before/after process comparison with specific improvement recommendations, estimated impact, and an implementation plan.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/operations/skills/risk-assessment', 'business', 'risk-assessment', '', 'risk-assessment', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Risk Assessment

Systematically identify, assess, and plan mitigations for operational risks.

## Risk Assessment Matrix

| | Low Impact | Medium Impact | High Impact |
|---|-----------|---------------|-------------|
| **High Likelihood** | Medium | High | Critical |
| **Medium Likelihood** | Low | Medium | High |
| **Low Likelihood** | Low | Low | Medium |

## Risk Categories

- **Operational**: Process failures, staffing gaps, system outages
- **Financial**: Budget overruns, vendor cost increases, revenue impact
- **Compliance**: Regulatory violations, audit findings, policy breaches
- **Strategic**: Market changes, competitive threats, technology shifts
- **Reputational**: Customer impact, public perception, partner relationships
- **Security**: Data breaches, access control failures, third-party vulnerabilities

## Risk Register Format

For each risk, document:
- **Description**: What could happen
- **Likelihood**: High / Medium / Low
- **Impact**: High / Medium / Low
- **Risk Level**: Critical / High / Medium / Low
- **Mitigation**: What we're doing to reduce likelihood or impact
- **Owner**: Who is responsible for managing this risk
- **Status**: Open / Mitigated / Accepted / Closed

## Output

Produce a prioritized risk register with specific, actionable mitigations. Focus on risks that are controllable and material.$body$)
ON CONFLICT (skill_key) DO NOTHING;
