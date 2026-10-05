INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:financial-services/financial-services/plugins/agent-plugins/pitch-agent/skills/pptx-author', 'finance', 'pptx-author', '', 'pptx-author', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# pptx-author

Use this skill when running **headless** (managed-agent / CMA mode) and you need to deliver a PowerPoint deck as a **file artifact** rather than editing a live document via `mcp__office__powerpoint_*`.

## Output contract

- Write to `./out/<name>.pptx`. Create `./out/` if it does not exist.
- Return the relative path in your final message so the orchestration layer can collect it.

## How to build the deck

Write a short Python script and run it with Bash. Use `python-pptx`:

```python
from pptx import Presentation
from pptx.util import Inches, Pt

prs = Presentation("./templates/firm-template.pptx")  # if a template is provided
# or: prs = Presentation()

slide = prs.slides.add_slide(prs.slide_layouts[5])    # title-only
slide.shapes.title.text = "Valuation Summary"
# ... add tables / charts / text boxes ...

prs.save("./out/pitch-<target>.pptx")
```

## Conventions (mirror the live-Office `pitch-deck` skill)

- **One idea per slide.** Title states the takeaway; body supports it.
- **Every number traces to the model.** If a figure comes from `./out/model.xlsx`, footnote the sheet and cell.
- **Use the firm template** when one is mounted at `./templates/`; otherwise default layouts.
- **Charts**: prefer embedding a PNG rendered from the model over native pptx charts when fidelity matters.
- **No external sends.** This skill writes a file; it never emails or uploads.

## When NOT to use

If `mcp__office__powerpoint_*` tools are available (Cowork plugin mode), use those instead — they drive the user's live document with review checkpoints. This skill is the file-producing fallback for headless runs.$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/pitch-agent/skills/sector-overview', 'finance', 'sector-overview', '', 'sector-overview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Sector Overview

## Workflow

### Step 1: Define Scope

- **Sector / subsector**: What industry and how narrowly defined?
- **Purpose**: Client report, internal research, pitch material, idea generation
- **Depth**: High-level overview (5-10 pages) or deep dive (20-30 pages)
- **Angle**: Neutral landscape vs. thematic thesis (e.g., "AI infrastructure buildout")
- **Universe**: Public companies only, or include private?

### Step 2: Market Overview

**Market Size & Growth**
- Total addressable market (TAM) with source
- Historical growth rate (5-year CAGR)
- Forecast growth rate and key assumptions
- Market segmentation (by product, geography, end market, customer type)

**Industry Structure**
- Fragmented vs. consolidated — top 5 market share
- Value chain map — where does value accrue?
- Business model types (subscription, transaction, licensing, services)
- Barriers to entry (capital, regulatory, technical, network effects)

**Key Trends & Drivers**
- Secular tailwinds (3-5 major trends)
- Headwinds and risks
- Technology disruption vectors
- Regulatory developments
- M&A activity and consolidation trends

### Step 3: Competitive Landscape

**Company Profiles** (for top 5-10 players):

| Company | Revenue | Growth | EBITDA Margin | Market Share | Key Differentiator |
|---------|---------|--------|--------------|-------------|-------------------|
| | | | | | |

For each company, brief profile:
- Business description (2-3 sentences)
- Strategic positioning and moat
- Recent developments (earnings, M&A, product launches)
- Valuation snapshot (P/E, EV/EBITDA, EV/Revenue)

**Competitive Dynamics**
- How do companies compete? (price, product, service, distribution)
- Who is gaining/losing share and why?
- Disruption risk from new entrants or adjacent players

### Step 4: Valuation Context

- Sector trading multiples (current and historical range)
- Premium/discount drivers (growth, margins, market position)
- Recent M&A transaction multiples
- How does the sector compare to the broader market?

### Step 5: Investment Implications

- Where are the best risk/reward opportunities?
- What thematic bets can be expressed through this sector?
- Key debates in the sector (bull vs. bear arguments)
- Catalysts that could change the sector narrative

### Step 6: Output

- Word document or PowerPoint with:
  - Market overview and sizing
  - Competitive landscape map
  - Company comparison table
  - Valuation summary
  - Key charts: market growth, share trends, valuation history
- Excel appendix with detailed company data

## Important Notes

- Source all market size data — cite the research firm or methodology
- Distinguish between TAM hype and realistic addressable market
- Sector overviews age fast — note the date and flag data that may be stale
- Charts are essential — market size waterfall, competitive positioning matrix, valuation scatter plot
- If for a client, tailor the "so what" to their specific situation (M&A target identification, competitive positioning, market entry)$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/pitch-agent/skills/xlsx-author', 'finance', 'xlsx-author', '', 'xlsx-author', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# xlsx-author

Use this skill when running **headless** (managed-agent / CMA mode) and you need to deliver an Excel workbook as a **file artifact** rather than editing a live workbook via `mcp__office__excel_*`.

## Output contract

- Write to `./out/<name>.xlsx`. Create `./out/` if it does not exist.
- Return the relative path in your final message so the orchestration layer can collect it.

## How to build the workbook

Write a short Python script and run it with Bash. Use `openpyxl`:

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

wb = Workbook()
ws = wb.active; ws.title = "Inputs"
ws["B2"] = "Revenue"; ws["C2"] = 1_250_000_000
ws["C2"].font = Font(color="0000FF")           # blue = hardcoded input
calc = wb.create_sheet("DCF")
calc["C5"] = "=Inputs!C2*(1+Inputs!C3)"        # black = formula
wb.save("./out/model.xlsx")
```

## Conventions (mirror `audit-xls`)

- **Blue / black / green.** Blue = hardcoded input, black = formula, green = link to another sheet/file.
- **No hardcodes in calc cells.** Every calculation cell is a formula; every input lives on an Inputs tab.
- **Named ranges** for any value referenced from a deck or memo.
- **Balance checks.** Include a Checks tab that ties (BS balances, CF ties to cash, etc.) and surfaces TRUE/FALSE.
- **One model per file.** Do not append to an existing workbook unless explicitly asked.

## When NOT to use

If `mcp__office__excel_*` tools are available (Cowork plugin mode), use those instead — they drive the user's live workbook with review checkpoints. This skill is the file-producing fallback for headless runs.$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/statement-auditor/skills/audit-xls', 'finance', 'audit-xls', '', 'audit-xls', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Audit Spreadsheet

Audit formulas and data for accuracy and mistakes. Scope determines depth — from quick formula checks on a selection up to full financial-model integrity audits.

## Step 1: Determine scope

If the user already gave a scope, use it. Otherwise **ask them**:

> What scope do you want me to audit?
> - **selection** — just the currently selected range
> - **sheet** — the current active sheet only
> - **model** — the whole workbook, including financial-model integrity checks (BS balance, cash tie-out, roll-forwards, logic sanity)

The **model** scope is the deepest — use it for DCF, LBO, 3-statement, merger, comps, or any integrated financial model before sending to a client or IC.

---

## Step 2: Formula-level checks (ALL scopes)

Run these regardless of scope:

| Check | What to look for |
|---|---|
| Formula errors | `#REF!`, `#VALUE!`, `#N/A`, `#DIV/0!`, `#NAME?` |
| Hardcodes inside formulas | `=A1*1.05` — the `1.05` should be a cell reference |
| Inconsistent formulas | A formula that breaks the pattern of its neighbors in a row/column |
| Off-by-one ranges | `SUM`/`AVERAGE` that misses the first or last row |
| Pasted-over formulas | Cell that looks like a formula but is actually a hardcoded value |
| Circular references | Intentional or accidental |
| Broken cross-sheet links | References to cells that moved or were deleted |
| Unit/scale mismatches | Thousands mixed with millions, % stored as whole numbers |
| Hidden rows/tabs | Could contain overrides or stale calculations |

---

## Step 3: Model-integrity checks (MODEL scope only)

If scope is **model**, identify the model type (DCF / LBO / 3-statement / merger / comps / custom) and run the appropriate integrity checks below.

### 3a. Structural review

| Check | What to look for |
|---|---|
| Input/formula separation | Are inputs clearly separated from calculations? |
| Color convention | Blue=input, black=formula, green=link — or whatever the model uses, applied consistently? |
| Tab flow | Logical order (Assumptions → IS → BS → CF → Valuation)? |
| Date headers | Consistent across all tabs? |
| Units | Consistent (thousands vs millions vs actuals)? |

### 3b. Balance Sheet

| Check | Test |
|---|---|
| BS balances | Total Assets = Total Liabilities + Equity (every period) |
| RE rollforward | Prior RE + Net Income − Dividends = Current RE |
| Goodwill/intangibles | Flow from acquisition assumptions (if M&A) |

If BS doesn't balance, **quantify the gap per period and trace where it breaks** — nothing else matters until this is fixed.

### 3c. Cash Flow Statement

| Check | Test |
|---|---|
| Cash tie-out | CF Ending Cash = BS Cash (every period) |
| CF sums | CFO + CFI + CFF = Δ Cash |
| D&A match | D&A on CF = D&A on IS |
| CapEx match | CapEx on CF matches PP&E rollforward on BS |
| WC changes | Signs match BS movements (ΔAR, ΔAP, ΔInventory) |

### 3d. Income Statement

| Check | Test |
|---|---|
| Revenue build | Ties to segment/product detail |
| Tax | Tax expense = Pre-tax income × tax rate (allow for deferred tax adj) |
| Share count | Ties to dilution schedule (options, converts, buybacks) |

### 3e. Circular references

- Interest → debt balance → cash → interest is a common intentional circ in LBO/3-stmt models
- If intentional: verify iteration toggle exists and works
- If unintentional: trace the loop and flag how to break it

### 3f. Logic & reasonableness

| Check | Flag if |
|---|---|
| Growth rates | >100% revenue growth without explanation |
| Margins | Outside industry norms |
| Terminal value dominance | TV > ~75% of DCF EV (yellow flag) |
| Hockey-stick | Projections ramp unrealistically in out-years |
| Compounding | EBITDA compounds to absurd $ by Year 10 |
| Edge cases | Model breaks at 0% or negative growth, negative EBITDA, leverage goes negative |

### 3g. Model-type-specific bugs

**DCF:**
- Discount rate applied to wrong period (mid-year vs end-of-year)
- Terminal value not discounted back
- WACC uses book values instead of market values
- FCF includes interest expense (should be unlevered)
- Tax shield double-counted

**LBO:**
- Debt paydown doesn't match cash sweep mechanics
- PIK interest not accruing to principal
- Management rollover not reflected in returns
- Exit multiple applied to wrong EBITDA (LTM vs NTM)
- Fees/expenses not deducted from Day 1 equity

**Merger:**
- Accretion/dilution uses wrong share count (pre- vs post-deal)
- Synergies not phased in
- Purchase price allocation doesn't balance
- Foregone interest on cash not included
- Transaction fees not in sources & uses

**3-statement:**
- Working capital changes have wrong sign
- Depreciation doesn't match PP&E schedule
- Debt maturity schedule doesn't match principal payments
- Dividends exceed net income without explanation

---

## Step 4: Report

Output a findings table:

| # | Sheet | Cell/Range | Severity | Category | Issue | Suggested Fix |
|---|---|---|---|---|---|---|

**Severity:**
- **Critical** — wrong output (BS doesn't balance, formula broken, cash doesn't tie)
- **Warning** — risky (hardcodes, inconsistent formulas, edge-case failures)
- **Info** — style/best-practice (color coding, layout, naming)

For **model** scope, prepend a summary line:

> Model type: [DCF/LBO/3-stmt/...] — Overall: [Clean / Minor Issues / Major Issues] — [N] critical, [N] warnings, [N] info

**Don't change anything without asking** — report first, fix on request.

---

## Notes

- **BS balance first** — if it doesn't balance, everything downstream is suspect
- **Hardcoded overrides are the #1 source of silent bugs** — search aggressively
- **Sign convention errors** (positive vs negative for cash outflows) are extremely common
- If the model uses VBA macros, note any macro-driven calculations that can't be audited from formulas alone$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/statement-auditor/skills/nav-tieout', 'finance', 'nav-tieout', '', 'nav-tieout', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# NAV tie-out

Given a generated LP statement and the period's NAV pack (via the nav MCP), independently recompute the LP's capital account and compare line by line.

> **The generated statement is the thing under test.** The NAV pack is the source of truth.

## Recompute the LP capital account

```
Beginning capital (prior statement ending)
  + Contributions (capital calls paid this period)
  − Distributions (cash + in-kind)
  + Allocated net income / (loss)
      = LP% × (realized + unrealized P&L − management fee − fund expenses)
  − Carried interest allocation (if crystallized this period)
Ending capital
```

Pull each input from the NAV pack: LP commitment %, fund-level P&L components, fee and expense totals, waterfall outputs.

## Compare

For each line on the statement, compare to your recomputed value. Tolerance: `0.01`. For each mismatch, note which input drives it (e.g., "allocated P&L differs — statement used 12.40% ownership, NAV pack shows 12.38% after the Q1 transfer").

## Additional checks

- Ending capital on this statement = beginning capital on next period's draft (if available).
- Sum of all LP ending capitals = fund NAV (within rounding).
- Commitment, unfunded, and recallable figures agree to the commitment register.

## Output

A pass/fail per line, the recomputed values alongside the statement values, and a list of flags. Do not edit the statement — the publisher acts on the flags after review.$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/statement-auditor/skills/xlsx-author', 'finance', 'xlsx-author', '', 'xlsx-author', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# xlsx-author

Use this skill when running **headless** (managed-agent / CMA mode) and you need to deliver an Excel workbook as a **file artifact** rather than editing a live workbook via `mcp__office__excel_*`.

## Output contract

- Write to `./out/<name>.xlsx`. Create `./out/` if it does not exist.
- Return the relative path in your final message so the orchestration layer can collect it.

## How to build the workbook

Write a short Python script and run it with Bash. Use `openpyxl`:

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

wb = Workbook()
ws = wb.active; ws.title = "Inputs"
ws["B2"] = "Revenue"; ws["C2"] = 1_250_000_000
ws["C2"].font = Font(color="0000FF")           # blue = hardcoded input
calc = wb.create_sheet("DCF")
calc["C5"] = "=Inputs!C2*(1+Inputs!C3)"        # black = formula
wb.save("./out/model.xlsx")
```

## Conventions (mirror `audit-xls`)

- **Blue / black / green.** Blue = hardcoded input, black = formula, green = link to another sheet/file.
- **No hardcodes in calc cells.** Every calculation cell is a formula; every input lives on an Inputs tab.
- **Named ranges** for any value referenced from a deck or memo.
- **Balance checks.** Include a Checks tab that ties (BS balances, CF ties to cash, etc.) and surfaces TRUE/FALSE.
- **One model per file.** Do not append to an existing workbook unless explicitly asked.

## When NOT to use

If `mcp__office__excel_*` tools are available (Cowork plugin mode), use those instead — they drive the user's live workbook with review checkpoints. This skill is the file-producing fallback for headless runs.$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/valuation-reviewer/skills/ic-memo', 'finance', 'ic-memo', '', 'ic-memo', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Investment Committee Memo

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
('marketplace:financial-services/financial-services/plugins/agent-plugins/valuation-reviewer/skills/portfolio-monitoring', 'finance', 'portfolio-monitoring', '', 'portfolio-monitoring', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Portfolio Monitoring

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
('marketplace:financial-services/financial-services/plugins/agent-plugins/valuation-reviewer/skills/returns-analysis', 'finance', 'returns-analysis', '', 'returns-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Returns Analysis

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
('marketplace:financial-services/financial-services/plugins/agent-plugins/valuation-reviewer/skills/xlsx-author', 'finance', 'xlsx-author', '', 'xlsx-author', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# xlsx-author

Use this skill when running **headless** (managed-agent / CMA mode) and you need to deliver an Excel workbook as a **file artifact** rather than editing a live workbook via `mcp__office__excel_*`.

## Output contract

- Write to `./out/<name>.xlsx`. Create `./out/` if it does not exist.
- Return the relative path in your final message so the orchestration layer can collect it.

## How to build the workbook

Write a short Python script and run it with Bash. Use `openpyxl`:

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

wb = Workbook()
ws = wb.active; ws.title = "Inputs"
ws["B2"] = "Revenue"; ws["C2"] = 1_250_000_000
ws["C2"].font = Font(color="0000FF")           # blue = hardcoded input
calc = wb.create_sheet("DCF")
calc["C5"] = "=Inputs!C2*(1+Inputs!C3)"        # black = formula
wb.save("./out/model.xlsx")
```

## Conventions (mirror `audit-xls`)

- **Blue / black / green.** Blue = hardcoded input, black = formula, green = link to another sheet/file.
- **No hardcodes in calc cells.** Every calculation cell is a formula; every input lives on an Inputs tab.
- **Named ranges** for any value referenced from a deck or memo.
- **Balance checks.** Include a Checks tab that ties (BS balances, CF ties to cash, etc.) and surfaces TRUE/FALSE.
- **One model per file.** Do not append to an existing workbook unless explicitly asked.

## When NOT to use

If `mcp__office__excel_*` tools are available (Cowork plugin mode), use those instead — they drive the user's live workbook with review checkpoints. This skill is the file-producing fallback for headless runs.$body$)
ON CONFLICT (skill_key) DO NOTHING;
