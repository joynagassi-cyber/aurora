INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/ai-readiness', 'finance', 'ai-readiness', '', 'ai-readiness', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Portfolio AI Readiness

## Workflow

### Step 1: Connect to Portfolio Data

First, ask the user where the portfolio materials live. Don't assume — offer the options:

- **MCP servers** — data room, SharePoint, Google Drive, or a portfolio-ops database if one is connected
- **Local files** — a folder path on disk with quarterly decks, financials, board packs
- **File uploads** — drag PDFs, PowerPoint, or Excel directly into the conversation

Once connected, pull quarterly updates, board decks, and financials for the portfolio (or a subset). For each company, extract: sector, revenue, headcount by function, tech stack mentioned, and any AI/automation initiatives already in flight.

If the user provides a single company, still run the scan but skip the cross-portfolio ranking.

Ask up front if not obvious from materials:
- Hold period remaining per company (AI payback matters less 12 months from exit)
- Whether any portco has already deployed something that worked

### Step 2: Per-Company Scan

For each company, answer three gate questions. All three yes → **Go**. Any no → **Wait** with a note on what unblocks it.

1. **Is the data there?** Can they produce a clean input for the use case — customer list, invoice feed, contract repository — without a 6-month data project first?
2. **Is there an owner?** Someone on the management team who will drive this, not a sponsor who will "support" it.
3. **Can we pilot in 30 days?** One team, one workflow, off-the-shelf tooling. If the answer starts with "first we'd need to...", it's not a quick win.

Then identify the top 2-3 leverage points. Look for these patterns in the cost structure and operations:

**Back Office (usually fastest to pilot)**
- Invoice processing, AP/AR matching, expense categorization
- Contract abstraction — vendor agreements, leases, customer MSAs
- Month-end close: reconciliations, flux commentary, lender reporting first drafts

**Revenue / Front Office**
- RFP and proposal first drafts — big lever if revenue is project-based
- Sales call summaries and CRM hygiene
- Customer support ticket triage and first-response drafting
- Quoting for configured / complex products

**Operations (sector-dependent)**
- SOP and quality documentation generation
- Scheduling and dispatch (field services, logistics)
- Code generation and review (software portcos)

For each leverage point, capture in one line: what it replaces, FTE-hours/week saved (assume 30-50%, not 100%), and whether it's buy-off-the-shelf or needs a light build.

### Step 3: Rank Across the Portfolio

Stack every leverage point from every company into one list. Rank by:

1. **Dollar impact** — annualized EBITDA contribution (cost out + revenue lift, net of tool cost)
2. **Speed to value** — months to first measurable result
3. **Probability** — discount for data quality, change management risk, management team capability

Tiebreaker: favor opportunities with <18 months of hold period remaining — those need to move now or not at all.

Output the stack:

| Rank | Company | Opportunity | Est. EBITDA ($) | Months to Value | Gate | First Step |
|---|---|---|---|---|---|---|
| 1 | | | | | Go | |
| 2 | | | | | Go | |
| 3 | | | | | Wait — [blocker] | |

### Step 4: Find the Replays

The highest-leverage move in a portfolio is running one successful play at multiple companies. Scan for:

- **Same sector, same function** — two healthcare services portcos with manual prior-auth? One implementation, two deployments.
- **Same tool, different company** — if one portco already has a working invoice-processing setup, flag every other portco with >$Xm in AP volume as a fast follower.
- **Shared vendor leverage** — three portcos buying the same tool is a pricing conversation.

List each replay with the lead company (who proves it) and follower companies (who copy it).

### Step 5: Output

One page for the operating partner, structured for a portfolio review:

1. **Top 5 across the portfolio** — the ranked table from Step 3, with owner and 30-day first step
2. **Replays** — 2-3 playbooks that hit multiple companies at once
3. **Go / Wait by company** — one line each; for Waits, what unblocks them
4. **What we're NOT doing** — the opportunities that looked good on paper but failed a gate; saves the operating partner from relitigating them every quarter
5. **Aggregate EBITDA contribution** — total portfolio-wide AI opportunity, split Year 1 quick wins vs. Years 2-3 scale

## Important Notes

- **Rank by dollars, not excitement.** A boring AP automation that saves $400k at a $40m revenue company beats a flashy customer-facing chatbot every time.
- **The binding constraint is almost always data, not models.** If a company can't produce a clean customer list, AI isn't the first project — a data cleanup is. Say so plainly.
- **Off-the-shelf first.** Custom builds are slow, expensive, and fragile for companies without engineering depth. Favor tools they can buy and deploy.
- **Ownership is the real gate.** A quick win with no internal owner dies in 90 days. If no one on the management team wants it, mark it Wait regardless of the dollar size.
- **Hold period drives urgency.** A company 3 years from exit can afford a foundational data project. A company 12 months out needs something that shows up in the LTM EBITDA for the CIM — or skip it.
- **Failed pilots are signal.** If management already tried something and it didn't stick, find out why before proposing the same thing again.$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/dd-checklist', 'finance', 'dd-checklist', '', 'dd-checklist', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Due Diligence Checklist

## Workflow

### Step 1: Scope the Diligence

Ask the user for:
- **Target company**: Name, sector, business model
- **Deal type**: Platform acquisition, add-on, growth equity, recap, carve-out
- **Deal size / complexity**: Determines depth of diligence
- **Key concerns**: Any known issues to prioritize (customer concentration, regulatory, environmental, etc.)
- **Timeline**: When is LOI / close targeted?

### Step 2: Generate Workstream Checklists

Generate a checklist across all major workstreams, tailored to the sector:

**Financial Due Diligence**
- Quality of earnings (QoE) — revenue and EBITDA adjustments
- Working capital analysis — normalized vs. actual
- Debt and debt-like items
- Capital expenditure (maintenance vs. growth)
- Tax structure and exposure
- Audit history and accounting policies
- Pro forma adjustments (run-rate, synergies)

**Commercial Due Diligence**
- Market size and growth (TAM/SAM/SOM)
- Competitive positioning and market share
- Customer analysis — concentration, retention, NPS
- Pricing power and contract structure
- Sales pipeline and backlog
- Go-to-market effectiveness

**Legal Due Diligence**
- Corporate structure and org chart
- Material contracts (customer, supplier, partnership)
- Litigation history and pending claims
- IP portfolio and protection
- Regulatory compliance
- Employment agreements and non-competes

**Operational Due Diligence**
- Management team assessment
- Organizational structure and key person risk
- IT systems and infrastructure
- Supply chain and vendor dependencies
- Facilities and real estate
- Insurance coverage

**HR / People Due Diligence**
- Org chart and headcount trends
- Compensation benchmarking
- Benefits and pension obligations
- Key employee retention risk
- Culture assessment
- Union/labor agreements

**IT / Technology Due Diligence** (for tech-enabled businesses)
- Technology stack and architecture
- Technical debt assessment
- Cybersecurity posture
- Data privacy compliance (GDPR, CCPA, SOC2)
- Product roadmap and R&D spend
- Scalability assessment

**Environmental / ESG** (where applicable)
- Environmental liabilities
- Regulatory compliance history
- ESG risks and opportunities

### Step 3: Status Tracking

For each item, track:

| Item | Workstream | Priority | Status | Owner | Notes |
|------|-----------|----------|--------|-------|-------|
| QoE report | Financial | P0 | Pending | | |
| Customer interviews | Commercial | P0 | In Progress | | 3 of 10 complete |

Status options: Not Started → Requested → Received → In Review → Complete → Red Flag

### Step 4: Red Flag Summary

Maintain a running list of red flags discovered during diligence:
- What was found
- Which workstream
- Severity (deal-breaker / significant / manageable)
- Mitigant or path to resolution
- Impact on valuation or deal terms

### Step 5: Output

- Excel workbook with tabs per workstream (default)
- Summary dashboard: % complete by workstream, outstanding items, red flags
- Weekly status update format for deal team

## Sector-Specific Additions

Automatically add relevant items based on sector:
- **Software/SaaS**: ARR quality, cohort analysis, hosting costs, SOC2
- **Healthcare**: Regulatory approvals, reimbursement risk, payor mix
- **Industrial**: Equipment condition, environmental remediation, safety record
- **Financial services**: Regulatory capital, compliance history, credit quality
- **Consumer**: Brand health, channel mix, seasonality, inventory management

## Important Notes

- Prioritize P0 items that are gating to LOI or close
- Flag items where the seller is slow to respond — may indicate issues
- Cross-reference data room contents against the checklist to identify gaps
- Update the checklist as diligence progresses — it's a living document$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/dd-meeting-prep', 'finance', 'dd-meeting-prep', '', 'dd-meeting-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Diligence Meeting Prep

## Workflow

### Step 1: Meeting Context

Ask the user for:
- **Meeting type**: Management presentation, expert call, customer reference, advisor check-in, site visit
- **Attendees**: Who from the target company or third party
- **Topic focus**: Full business overview, or specific workstream (financial, commercial, operational, tech)
- **What you already know**: Prior meetings, CIM, data room findings
- **Key concerns**: Specific issues to probe

### Step 2: Generate Question List

Organize questions by priority and topic. Structure depends on meeting type:

#### Management Presentation
**Business Overview (warm-up)**
- Walk us through the founding story and key milestones
- How do you describe the business to someone unfamiliar with the space?
- What are you most proud of? What would you do differently?

**Revenue & Growth**
- Walk us through revenue by customer/segment/geography
- What's driving growth? Price vs. volume vs. new customers
- What does the sales cycle look like? How has win rate trended?
- Where do you see the biggest growth opportunities in the next 3-5 years?

**Competitive Positioning**
- Who do you lose deals to and why?
- What's your moat? How defensible is it?
- How do customers evaluate you vs. alternatives?

**Operations & Team**
- Walk us through the org chart — who are the key people?
- What roles are you hiring for? What's been hardest to fill?
- What keeps you up at night operationally?

**Financial Deep-Dive**
- Walk us through the margin bridge — what's changed and why?
- Any one-time or non-recurring items we should understand?
- How do you think about capex — maintenance vs. growth?
- Working capital seasonality?

**Forward Look**
- Walk us through the budget/plan for next year
- What assumptions are you most/least confident in?
- What would need to go right/wrong to significantly beat/miss plan?

#### Expert Network Call
- How do you view [company]'s positioning in the market?
- What are the secular trends driving this space?
- Who are the strongest competitors and why?
- What risks should an investor be aware of?
- If you were buying this business, what would you diligence most carefully?

#### Customer Reference Call
- How did you find [company] and why did you choose them?
- What alternatives did you evaluate?
- What do they do well? Where could they improve?
- How likely are you to renew/expand? What would change that?
- If they raised prices 10-20%, how would you react?

### Step 3: Benchmarks & Context

For each key topic, provide relevant benchmarks:
- Industry growth rates and margin profiles
- Comparable company metrics (if comps analysis exists in session)
- Data points from the CIM or data room that warrant follow-up
- Discrepancies between different data sources to clarify

### Step 4: Red Flags to Probe

Based on what's known, flag specific areas to dig into:
- Inconsistencies in the CIM or financials
- Customer concentration or churn signals
- Management team gaps or recent departures
- Unusual accounting treatments
- Missing data room items

### Step 5: Output

One-page meeting prep doc:
1. **Meeting logistics**: Who, when, where, duration
2. **Objectives**: Top 3 things you need to learn from this meeting
3. **Question list**: Prioritized, grouped by topic (star the must-asks)
4. **Benchmarks**: Key numbers to reference
5. **Red flags**: Specific items to probe
6. **Follow-up items**: What to request after the meeting

## Important Notes

- Lead with open-ended questions — let management talk, then follow up on specifics
- Don't lead the witness — ask neutral questions, not "isn't it true that..."
- Take notes on body language and confidence levels, not just answers
- Always end with: "What haven't we asked about that we should?"
- Keep the question list to 15-20 max — you won't get through more in a 60-90 min session$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/deal-screening', 'finance', 'deal-screening', '', 'deal-screening', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Deal Screening

## Workflow

### Step 1: Extract Deal Facts

From the provided CIM, teaser, or description, extract:

- **Company**: Name, location, sector/subsector
- **Description**: What they do (1-2 sentences)
- **Financials**: Revenue, EBITDA, margins, growth rate
- **Deal type**: Platform, add-on, recap, minority, carve-out
- **Asking price / valuation**: Multiple, enterprise value if stated
- **Seller motivation**: Why selling now
- **Management**: Rolling or exiting
- **Key customers**: Concentration risk
- **Key risks**: Obvious red flags

### Step 2: Screen Against Criteria

Apply the fund's investment criteria (ask user if not known):

| Criterion | Target | Actual | Pass/Fail |
|-----------|--------|--------|-----------|
| Revenue range | | | |
| EBITDA range | | | |
| EBITDA margin | | | |
| Growth profile | | | |
| Sector fit | | | |
| Geography | | | |
| Deal size / EV | | | |
| Valuation (x EBITDA) | | | |
| Customer concentration | | | |
| Management continuity | | | |

### Step 3: Quick Assessment

Provide a 3-part assessment:

1. **Verdict**: Pass / Further Diligence / Hard Pass
2. **Bull case** (2-3 bullets): Why this could be a good deal
3. **Bear case** (2-3 bullets): Key risks and concerns
4. **Key questions**: What you'd need to answer on a first call

### Step 4: Output

One-page screening memo suitable for sharing with partners or an IC quick screen.

## Important Notes

- Speed matters — screening should take minutes, not hours
- Be direct about red flags. Don't bury concerns
- If financials seem inconsistent or incomplete, flag it explicitly
- Ask for the fund's criteria upfront if this is the first screening
- Save screening criteria in memory for future deals once confirmed$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/deal-sourcing', 'finance', 'deal-sourcing', '', 'deal-sourcing', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Deal Sourcing

## Workflow

This skill follows a 3-step sourcing pipeline:

### Step 1: Discover Companies

Research and identify potential target companies based on the user's criteria:

- **Sector/industry focus**: Ask the user what space they're looking in (e.g., "B2B SaaS in healthcare", "industrial services in the Southeast")
- **Deal parameters**: Revenue range, EBITDA range, growth profile, geography, ownership type (founder-owned, PE-backed, corporate carve-out)
- **Sources**: Use web search to find companies matching criteria. Look at industry reports, conference attendee lists, trade publications, and competitor landscapes
- **Output**: A shortlist of companies with: name, description, estimated revenue/size, location, founder/CEO name, website, and why they fit the thesis

### Step 2: CRM Check

Before outreach, check if the company or founder already exists in the firm's CRM:

- Search the user's email (Gmail) for prior correspondence with the company or founder
- Search Slack for any internal mentions or prior discussions about the target
- Ask the user: "Have you or your team had any prior contact with [Company]?"
- Flag any existing relationships, prior passes, or known context
- **Output**: For each company, note: "New" (no prior contact), "Existing" (prior correspondence found — summarize), or "Previously Passed" (if evidence of a prior pass)

### Step 3: Draft Founder Outreach

Draft personalized cold emails to founders/CEOs:

- **Tone**: Professional but warm. Not overly formal — founders respond better to genuine, concise outreach
- **Structure**:
  1. Brief intro — who you are and your firm (ask user for their firm intro if not known)
  2. Why this company caught your attention — reference something specific (product, market position, growth)
  3. What you're looking for — partnership, not just a transaction
  4. Soft ask — "Would you be open to a brief conversation?"
- **Personalization**: Reference the company's specific product, recent news, or market position. Never use generic templates
- **Length**: 4-6 sentences max. Founders are busy
- **Voice matching**: If the user has sent prior outreach emails, study them to match their tone and style. Search Gmail for "sent" emails with keywords like "reaching out", "introduction", "partnership" to find examples

### Email Draft Guidelines

- Subject line: Keep it short and specific. Reference the company or sector, not "Investment Opportunity"
- No attachments on first touch
- Include a clear but low-pressure CTA
- Draft in Gmail if available, otherwise output as text for the user to copy

## Example Interaction

**User**: "Find me founder-owned industrial services companies in Texas doing $10-50M revenue"

**Assistant**:
1. Searches web for industrial services companies in Texas matching the criteria
2. Presents a shortlist of 5-8 companies with key details
3. For each, checks Gmail/Slack for prior contact
4. Drafts personalized outreach emails for the ones marked "New"
5. Presents drafts for user review before sending

## Important Notes

- Always present the shortlist for user review before drafting emails
- Never send emails without explicit user approval
- If the user's firm intro or investment criteria aren't clear, ask before drafting
- Prioritize quality over quantity — 5 well-researched targets beat 20 generic ones$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/ic-memo', 'finance', 'ic-memo', '', 'ic-memo', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Investment Committee Memo

## Workflow

### Step 1: Gather Inputs

Collect from the user (or from prior analysis in the session):

- Company overview and business description
- Industry/market context
- Historical financials (3-5 years)
- Management assessment
- Deal terms (price, structure, financing)
- Due diligence findings (commercial, financial, legal, operational)
- Value creation plan / 100-day plan
- Returns analysis (base, upside, downside)

### Step 2: Draft Memo Structure

Standard IC memo format:

**I. Executive Summary** (1 page)
- Company description, deal rationale, key terms
- Recommendation and headline returns
- Top 3 risks and mitigants

**II. Company Overview** (1-2 pages)
- Business description, products/services
- Customer base and go-to-market
- Competitive positioning
- Management team

**III. Industry & Market** (1 page)
- Market size and growth
- Competitive landscape
- Secular trends / tailwinds
- Regulatory environment

**IV. Financial Analysis** (2-3 pages)
- Historical performance (revenue, EBITDA, margins, cash flow)
- Quality of earnings adjustments
- Working capital analysis
- Capex requirements

**V. Investment Thesis** (1 page)
- Why this is an attractive investment (3-5 pillars)
- Value creation levers (organic growth, margin expansion, M&A, multiple expansion)
- 100-day priorities

**VI. Deal Terms & Structure** (1 page)
- Enterprise value and implied multiples
- Sources & uses
- Capital structure / leverage
- Key legal terms

**VII. Returns Analysis** (1 page)
- Base, upside, and downside scenarios
- IRR and MOIC across scenarios
- Key assumptions driving returns
- Sensitivity analysis

**VIII. Risk Factors** (1 page)
- Key risks ranked by severity and likelihood
- Mitigants for each risk
- Deal-breaker risks (if any)

**IX. Recommendation**
- Clear recommendation: Proceed / Pass / Conditional proceed
- Key conditions or next steps

### Step 3: Output Format

- Default: Word document (.docx) with professional formatting
- Alternative: Markdown for quick review
- Include tables for financials and returns, not just prose

## Important Notes

- IC memos should be factual and balanced — present both bull and bear cases honestly
- Don't minimize risks. IC members will find them anyway; credibility matters
- Use the firm's standard memo template if the user provides one
- Financial tables should tie — check that EBITDA bridges, S&U balances, and returns math is consistent
- Ask for missing inputs rather than making assumptions on deal terms or returns$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/portfolio-monitoring', 'finance', 'portfolio-monitoring', '', 'portfolio-monitoring', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Portfolio Monitoring

## Workflow

### Step 1: Ingest Financial Package

- Accept the user's portfolio company financial package (Excel workbook, PDF, or CSV)
- Extract key financials: Revenue, EBITDA, cash balance, debt outstanding, capex, working capital
- Identify the reporting period and compare to prior period and budget/plan

### Step 2: KPI Extraction & Variance Analysis

Key metrics to track (adapt to the company's sector):

**Financial KPIs:**
- Revenue vs. budget ($ and %)
- EBITDA and EBITDA margin vs. budget
- Cash balance and net debt
- Leverage ratio (Net Debt / LTM EBITDA)
- Interest coverage ratio
- Capex vs. budget
- Free cash flow

**Operational KPIs** (ask user or infer from data):
- Customer count / revenue per customer
- Employee headcount / revenue per employee
- Backlog / pipeline
- Churn / retention rates

### Step 3: Flag & Summarize

- **Green**: Within 5% of plan
- **Yellow**: 5-15% below plan — flag for discussion
- **Red**: >15% below plan or covenant breach risk — immediate attention

Output a concise summary:
1. One-paragraph executive summary ("Company X is tracking [ahead/behind/on] plan...")
2. KPI table with actual vs. budget vs. prior period
3. Red/yellow flags with context
4. Covenant compliance status (if applicable)
5. Questions for management

### Step 4: Trend Analysis

If multiple periods are provided:
- Chart key metrics over time (revenue, EBITDA, cash)
- Identify trends — accelerating, decelerating, or stable
- Compare vs. underwriting case

## Important Notes

- Always ask for the budget/plan to compare against if not provided
- Don't assume sector-specific KPIs — ask what matters for this company
- If covenant levels aren't known, ask the user for the credit agreement terms
- Output should be board-ready — concise, factual, no fluff$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/returns-analysis', 'finance', 'returns-analysis', '', 'returns-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Returns Analysis

## Workflow

### Step 1: Gather Deal Inputs

Ask for (or extract from prior analysis):

**Entry:**
- Entry EBITDA (LTM or NTM)
- Entry multiple (EV / EBITDA)
- Enterprise value
- Net debt at close
- Equity check size
- Transaction fees & expenses

**Financing:**
- Senior debt (x EBITDA, rate, amortization)
- Subordinated debt / mezzanine (if any)
- Total leverage at entry (x EBITDA)
- Equity contribution

**Operating Assumptions:**
- Revenue growth rate (annual)
- EBITDA margin trajectory
- Capex as % of revenue
- Working capital changes
- Debt paydown schedule

**Exit:**
- Hold period (years)
- Exit multiple (EV / EBITDA)
- Exit EBITDA (calculated from growth assumptions)

### Step 2: Base Case Returns

Calculate:

| Metric | Value |
|--------|-------|
| Entry EV | |
| Equity invested | |
| Exit EBITDA | |
| Exit EV | |
| Net debt at exit | |
| Exit equity value | |
| **MOIC** | |
| **IRR** | |
| Cash-on-cash | |

Show the returns waterfall:
- EBITDA growth contribution
- Multiple expansion/contraction contribution
- Debt paydown contribution
- Fee/expense drag

### Step 3: Sensitivity Tables

Build 2-way sensitivity matrices:

**Entry Multiple vs. Exit Multiple**
| | Exit 6x | Exit 7x | Exit 8x | Exit 9x | Exit 10x |
|---|---------|---------|---------|---------|----------|
| Entry 7x | | | | | |
| Entry 8x | | | | | |
| Entry 9x | | | | | |
| Entry 10x | | | | | |

**EBITDA Growth vs. Exit Multiple** (at fixed entry)

**Leverage vs. Exit Multiple** (at fixed entry and growth)

**Hold Period vs. Exit Multiple**

Show both IRR and MOIC in each cell (IRR / MOIC format).

### Step 4: Scenario Analysis

Build 3 scenarios:

| | Bull | Base | Bear |
|---|------|------|------|
| Revenue CAGR | | | |
| Exit EBITDA margin | | | |
| Exit multiple | | | |
| Exit EBITDA | | | |
| MOIC | | | |
| IRR | | | |

### Step 5: Output

- Excel workbook with:
  - Assumptions tab
  - Returns calculation
  - Sensitivity tables (formatted with conditional coloring)
  - Scenario summary
- One-page returns summary suitable for IC deck

## Key Formulas

- **MOIC** = Exit Equity Value / Equity Invested
- **IRR** = solve for r: Equity Invested × (1 + r)^n = Exit Equity Value (adjust for interim cash flows)
- **Returns attribution**:
  - Growth: (Exit EBITDA - Entry EBITDA) × Exit Multiple / Equity
  - Multiple: (Exit Multiple - Entry Multiple) × Entry EBITDA / Equity
  - Leverage: Debt paydown over hold period / Equity

## Important Notes

- Always show returns both gross and net of fees/carry where applicable
- Management rollover and co-invest change the equity check — ask if relevant
- Dividend recaps or interim distributions affect IRR significantly — include if planned
- Don't forget transaction costs (typically 2-4% of EV) — they reduce Day 1 equity value
- Tax considerations (asset vs. stock deal, 338(h)(10) election) can materially affect after-tax returns$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/unit-economics', 'finance', 'unit-economics', '', 'unit-economics', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Unit Economics Analysis

## Workflow

### Step 1: Identify Business Model

Determine the revenue model to tailor the analysis:
- **SaaS / Subscription**: ARR, net retention, cohorts
- **Recurring services**: Contract value, renewal rates, upsell
- **Transaction / usage-based**: Revenue per transaction, volume trends, take rate
- **Hybrid**: Break down by revenue stream

### Step 2: Core Metrics

#### ARR / Revenue Quality
- **ARR bridge**: Beginning ARR → New → Expansion → Contraction → Churn → Ending ARR
- **ARR by cohort**: Vintage analysis — how does each annual cohort retain and grow?
- **Revenue concentration**: Top 10/20/50 customers as % of total
- **Revenue by type**: Recurring vs. non-recurring vs. professional services
- **Contract structure**: ACV distribution, multi-year %, auto-renewal %

#### Customer Economics
- **CAC (Customer Acquisition Cost)**: Total S&M spend / new customers acquired
- **LTV (Lifetime Value)**: (ARPU × Gross Margin) / Churn Rate
- **LTV:CAC ratio**: Target >3x for healthy businesses
- **CAC payback period**: Months to recover acquisition cost
- **Blended vs. segmented**: Break down by customer segment (enterprise vs. SMB vs. mid-market)

#### Retention & Expansion
- **Gross retention**: % of beginning ARR retained (excludes expansion)
- **Net retention (NDR)**: % of beginning ARR retained including expansion
- **Logo churn**: % of customers lost
- **Dollar churn**: % of revenue lost (often different from logo churn)
- **Expansion rate**: Upsell + cross-sell as % of beginning ARR

#### Cohort Analysis
Build a cohort matrix showing:

| Cohort | Year 0 | Year 1 | Year 2 | Year 3 | Year 4 |
|--------|--------|--------|--------|--------|--------|
| 2020 | $1.0M | $1.1M | $1.2M | $1.1M | |
| 2021 | $1.5M | $1.7M | $1.8M | | |
| 2022 | $2.0M | $2.3M | | | |
| 2023 | $3.0M | | | | |

Show both absolute $ and indexed (Year 0 = 100%) views.

#### Margin Waterfall
- Revenue → Gross Profit → Contribution Margin → EBITDA
- Fully loaded unit economics: what does it cost to acquire, serve, and retain a customer?
- Gross margin by revenue stream (subscription vs. services vs. other)

### Step 3: Benchmarking

Compare unit economics to relevant benchmarks:
- **SaaS Rule of 40**: Growth rate + EBITDA margin > 40%
- **SaaS Magic Number**: Net new ARR / prior period S&M spend > 0.75x
- **NDR benchmarks**: Best-in-class >120%, good >110%, concerning <100%
- **LTV:CAC**: Best-in-class >5x, good >3x, concerning <2x
- **Gross retention**: Best-in-class >95%, good >90%, concerning <85%
- **CAC payback**: Best-in-class <12mo, good <18mo, concerning >24mo

### Step 4: Revenue Quality Score

Synthesize into a revenue quality assessment:

| Factor | Score (1-5) | Notes |
|--------|-------------|-------|
| Recurring % | | |
| Net retention | | |
| Customer concentration | | |
| Cohort stability | | |
| Growth durability | | |
| Margin profile | | |
| **Overall** | | |

### Step 5: Output

- Excel workbook with ARR bridge, cohort matrix, unit economics dashboard
- Summary slide with key metrics and benchmarks
- Red flags and areas for further diligence

## Important Notes

- Always ask for raw customer-level data if available — aggregate metrics can hide problems
- NDR above 100% can mask high gross churn if expansion is strong enough — always show both
- Cohort analysis is the single most important view for revenue quality — push for this data
- Differentiate between contracted ARR and actual recognized revenue
- For usage-based models, focus on consumption trends and expansion patterns rather than traditional ARR metrics
- Professional services revenue should be evaluated separately — it's not recurring and margins are typically lower$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/private-equity/skills/value-creation-plan', 'finance', 'value-creation-plan', '', 'value-creation-plan', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Value Creation Plan

## Workflow

### Step 1: Baseline Assessment

Understand the starting point:
- Current revenue, EBITDA, and margins
- Organizational structure and capabilities
- Key operational metrics by function
- Management team strengths and gaps
- Quick wins already identified during diligence

### Step 2: Value Creation Levers

Map all levers to an EBITDA bridge over the hold period:

#### Revenue Growth Levers
- **Organic growth**: Price increases, volume growth, market expansion
- **Cross-sell / upsell**: New products to existing customers
- **New market entry**: Geographic expansion, new verticals, new channels
- **Sales force effectiveness**: Hire reps, improve conversion, shorten cycle
- **M&A / add-ons**: Bolt-on acquisitions to add revenue and capabilities

For each lever:
- Current state → Target state
- Revenue impact ($)
- Timeline to impact
- Investment required
- Confidence level (high/medium/low)

#### Margin Expansion Levers
- **Pricing optimization**: Price increases, mix shift, bundling
- **COGS reduction**: Procurement savings, supplier consolidation, automation
- **OpEx optimization**: Overhead reduction, shared services, offshoring
- **Technology investment**: Automation, systems integration, data analytics
- **Scale leverage**: Fixed cost leverage as revenue grows

#### Strategic / Multiple Expansion
- **Platform building**: Add-on acquisitions, tuck-ins
- **Recurring revenue shift**: Move from project to recurring/subscription
- **Market positioning**: Category leadership, brand building
- **Management upgrades**: Key hires to professionalize the business
- **ESG / governance**: Board formation, reporting improvements

### Step 3: EBITDA Bridge

Build the walk from current to target EBITDA:

| Lever | Year 1 | Year 2 | Year 3 | Year 4 | Year 5 |
|-------|--------|--------|--------|--------|--------|
| Base EBITDA | | | | | |
| Organic revenue growth | | | | | |
| Pricing | | | | | |
| Add-on M&A | | | | | |
| COGS savings | | | | | |
| OpEx optimization | | | | | |
| Technology investment | | | | | |
| **Pro Forma EBITDA** | | | | | |
| **Margin** | | | | | |

### Step 4: 100-Day Plan

Prioritize the first 100 days post-close:

**Days 1-30: Stabilize & Assess**
- Management alignment and retention (sign employment agreements, set comp)
- Quick wins — pricing, obvious cost cuts, low-hanging fruit
- Detailed operational assessment by function
- Customer communication plan
- Set up reporting and KPI dashboards

**Days 31-60: Plan & Initiate**
- Finalize strategic plan and communicate to organization
- Launch top 3-5 value creation initiatives
- Begin add-on M&A pipeline development
- Hire for critical gaps
- Implement new reporting cadence (weekly flash, monthly review, quarterly board)

**Days 61-100: Execute & Measure**
- First results from quick-win initiatives
- First board meeting with operating metrics
- Progress report on each value creation lever
- Adjust plan based on early learnings

### Step 5: KPI Dashboard

Define the metrics that will track value creation:

| KPI | Current | Year 1 Target | Owner | Reporting Frequency |
|-----|---------|---------------|-------|-------------------|
| Revenue | | | CEO | Monthly |
| EBITDA | | | CFO | Monthly |
| EBITDA margin | | | CFO | Monthly |
| New customer wins | | | CRO | Weekly |
| Net retention | | | CRO | Monthly |
| Employee turnover | | | CHRO | Monthly |
| Cash conversion | | | CFO | Monthly |

### Step 6: Output

- Word document or PowerPoint with:
  - Executive summary (1 page)
  - EBITDA bridge chart
  - Value creation levers detail (1 page per lever)
  - 100-day plan timeline
  - KPI dashboard
  - Accountability matrix (who owns what)
- Excel model backing the EBITDA bridge

## Important Notes

- Be realistic about timing — most PE value creation takes 12-24 months to show in financials
- Quick wins matter for momentum and credibility, but don't over-rotate on cost cuts at the expense of growth
- Management buy-in is critical — co-develop the plan, don't impose it
- Track initiative-level P&L impact, not just top-line EBITDA — you need to know what's working
- Add-on M&A is often the largest value creation lever — start the pipeline on Day 1
- Always pressure-test assumptions with operating partners or industry experts$body$)
ON CONFLICT (skill_key) DO NOTHING;
