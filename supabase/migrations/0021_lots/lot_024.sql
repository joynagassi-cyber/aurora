INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:financial-services/financial-services/plugins/partner-built/spglobal/skills/tear-sheet', 'finance', 'tear-sheet', '', 'tear-sheet', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Financial Tear Sheet Generator

Generate audience-specific company tear sheets by pulling live data from S&P Capital IQ via the S&P Global MCP tools and formatting the result as a professional Word document.

## Style Configuration

These are sensible defaults. To customize for your firm's brand, modify this section — common changes include swapping the color palette, changing the font (Calibri is standard at many banks), and updating the disclaimer text.

**Colors:**
- Primary (header banner background, section header text): #1F3864
- Accent (signature section highlights): #2E75B6
- Table header row fill: #D6E4F0
- Table alternating row fill: #F2F2F2
- Table borders: #CCCCCC
- Header banner text: #FFFFFF

**Typography (sizes in half-points for docx-js):**
- Font family: Arial
- Company name: 18pt bold (size: 36)
- Section headers: 11pt bold (size: 22), Primary color
- Body text: 9pt (size: 18)
- Table text: 8.5pt (size: 17)
- Footer/disclaimer: 7pt italic (size: 14)
- Per-template overrides are specified in each reference file's Formatting Notes.

**Company Header Banner:**
- The header is a navy (#1F3864) banner spanning the full page width with company name in white.
- **Below the banner, key-value pairs MUST be rendered in a two-column borderless table spanning the full page width.** Left column: company identifiers (ticker, HQ, founded, employees, sector). Right column: financial identifiers (market cap, EV, stock price, shares outstanding). Each cell contains a bold label and regular-weight value on the same line (e.g., "**Market Cap** $124.7B"). Do not left-justify all fields in a single column — this wastes horizontal space and looks unprofessional. The two-column spread is the single most important visual signal that distinguishes a professional tear sheet from a default document.
  - **Implementation:** Create a 2-column table with `borders: none` and `shading: none` on all cells. Set column widths to 50% each. Place left-column fields (ticker, HQ, founded, employees) as separate paragraphs in the left cell. Place right-column fields (market cap, EV, stock price, shares outstanding) in the right cell. Each field is a single paragraph: bold run for the label, regular run for the value.
  - The specific fields in each column vary by audience — see the reference file's header spec. The principle is always: spread across the page, not clumped left.
- **Do not use a bordered table for the header key-value block.** Bordered tables are reserved for financial data only.
- Key metrics in the header (market cap, EV, stock price) should be displayed as inline key-value pairs, not in a separate bordered table.

**Section Headers:**
- Each section header gets a horizontal rule (thin line, #CCCCCC, 0.5pt) directly beneath it to create clean visual separation between sections.
- **Render the rule as a bottom border on the header paragraph itself** — do not insert a separate paragraph element for the rule. A separate paragraph adds its own before/after spacing and causes excessive whitespace below section titles.
- **Implementation:** In docx-js, apply a bottom border to the section header paragraph via `paragraph.borders.bottom = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" }`. Do not use `doc.addParagraph()` with a separate horizontal rule element. Do not use `thematicBreak`. The border must be on the heading paragraph itself with 0pt spacing after, so the rule sits tight against the header text.
- Spacing: 12pt before the header paragraph, 0pt after the header paragraph, 4pt before the next content element.

**Bullet Formatting:**
- Use a single bullet character (•) for all bulleted content across all tear sheet types. Do not mix •, -, ▸, or numbered lists within or across tear sheets.
- **Synthesis/analysis bullets** (Earnings Highlights, Strategic Fit, Integration Considerations, Conversation Starters): indented block-style formatting with left indent 360 DXA (0.25") and a hanging indent for the bullet character. These should be visually offset from body text — they're interpretive content and should look distinct from data tables and prose paragraphs.
- **Informational bullets** within relationship sections: standard body indent (180 DXA), no hanging indent.
- **Do not apply left-border accents to any bullet sections.** Left-border styling renders inconsistently in docx-js and creates visual artifacts. Use indentation and text size differentiation to distinguish signature sections instead.

**Tables (financial data only):**
- Header row: Table Header Fill (#D6E4F0) with bold dark text
- Body rows: alternating white / Table Alternating Fill (#F2F2F2)
- Borders: Table Border color (#CCCCCC), thin (BorderStyle.SINGLE, size 1)
- Cell padding: top/bottom 40 DXA, left/right 80 DXA
- Right-align all numeric columns
- Always use ShadingType.CLEAR (never SOLID — SOLID causes black backgrounds)

**Layout:**
- US Letter portrait, 0.75" margins (1080 DXA all sides)

**Number formatting:**
- Currency: USD. Use millions unless company revenue > $50B (then billions, one decimal). Label units in column headers (e.g., "Revenue ($M)"), not in individual cells.
- **Table cells: plain numbers with commas, no dollar signs.** Example: a revenue cell shows "4,916" not "$4,916". The column header carries the unit.
- Fiscal years: actual years (FY2022, FY2023, FY2024), never relative labels (FY-2, FY-1).
- Negatives: parentheses, e.g., (2.3%)
- Percentages: one decimal place
- Large numbers: commas as thousands separators

**Footer (document footer, not inline):**
Place the source attribution and disclaimer in the actual document footer (repeated on every page), not as inline body text at the bottom. The footer is exactly two lines, centered, on every page:
- Line 1: "Data: S&P Capital IQ via Kensho | Analysis: AI-generated | [Month Day, Year]"
- Line 2: "For informational purposes only. Not investment advice."
- Style: 7pt italic, centered, #666666 text color
- This footer text must be identical across all tear sheet types for the same company. Do not vary the wording by audience.
- **This footer is required on every tear sheet, every audience type, every page.** Do not omit it.

## Component Functions

**You MUST use these exact functions to create document elements. Do NOT write custom docx-js styling code.** Copy these functions into your generated Node script and call them. The Style Configuration prose above remains as documentation; these functions are the enforcement mechanism.

```javascript
const docx = require("docx");
const {
  Document, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, AlignmentType, BorderStyle, ShadingType,
  Header, Footer, PageNumber, HeadingLevel, TableLayoutType,
  convertInchesToTwip
} = docx;

// ── Color constants ──
const COLORS = {
  PRIMARY: "1F3864",
  ACCENT: "2E75B6",
  TABLE_HEADER_FILL: "D6E4F0",
  TABLE_ALT_ROW: "F2F2F2",
  TABLE_BORDER: "CCCCCC",
  HEADER_TEXT: "FFFFFF",
  FOOTER_TEXT: "666666",
};

const FONT = "Arial";

// ── 1. createHeaderBanner ──
// Returns an array of docx elements: [banner paragraph, key-value table]
function createHeaderBanner(companyName, leftFields, rightFields) {
  // leftFields / rightFields: arrays of { label: string, value: string }
  const banner = new Paragraph({
    children: [
      new TextRun({
        text: companyName,
        bold: true,
        size: 36, // 18pt
        color: COLORS.HEADER_TEXT,
        font: FONT,
      }),
    ],
    shading: { type: ShadingType.CLEAR, color: "auto", fill: COLORS.PRIMARY },
    spacing: { after: 0 },
    alignment: AlignmentType.LEFT,
  });

  function buildCellParagraphs(fields) {
    return fields.map(
      (f) =>
        new Paragraph({
          children: [
            new TextRun({ text: f.label + "  ", bold: true, size: 18, font: FONT }),
            new TextRun({ text: f.value, size: 18, font: FONT }),
          ],
          spacing: { after: 40 },
        })
    );
  }

  const noBorder = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
  const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
  const noShading = { type: ShadingType.CLEAR, color: "auto", fill: "FFFFFF" };

  const kvTable = new Table({
    rows: [
      new TableRow({
        children: [
          new TableCell({
            children: buildCellParagraphs(leftFields),
            width: { size: 50, type: WidthType.PERCENTAGE },
            borders: noBorders,
            shading: noShading,
          }),
          new TableCell({
            children: buildCellParagraphs(rightFields),
            width: { size: 50, type: WidthType.PERCENTAGE },
            borders: noBorders,
            shading: noShading,
          }),
        ],
      }),
    ],
    width: { size: 100, type: WidthType.PERCENTAGE },
  });

  return [banner, kvTable];
}

// ── 2. createSectionHeader ──
// Returns a single Paragraph with bottom border rule
function createSectionHeader(text) {
  return new Paragraph({
    children: [
      new TextRun({
        text: text,
        bold: true,
        size: 22, // 11pt
        color: COLORS.PRIMARY,
        font: FONT,
      }),
    ],
    spacing: { before: 240, after: 0 }, // 12pt before, 0pt after
    border: {
      bottom: { style: BorderStyle.SINGLE, size: 1, color: COLORS.TABLE_BORDER },
    },
  });
}

// ── 3. createTable ──
// headers: string[], rows: string[][], options: { accentHeader?, fontSize? }
function createTable(headers, rows, options = {}) {
  const fontSize = options.fontSize || 17; // 8.5pt default
  const headerFill = options.accentHeader ? COLORS.ACCENT : COLORS.TABLE_HEADER_FILL;
  const headerTextColor = options.accentHeader ? COLORS.HEADER_TEXT : "000000";

  const cellBorders = {
    top: { style: BorderStyle.SINGLE, size: 1, color: COLORS.TABLE_BORDER },
    bottom: { style: BorderStyle.SINGLE, size: 1, color: COLORS.TABLE_BORDER },
    left: { style: BorderStyle.SINGLE, size: 1, color: COLORS.TABLE_BORDER },
    right: { style: BorderStyle.SINGLE, size: 1, color: COLORS.TABLE_BORDER },
  };

  const cellMargins = { top: 40, bottom: 40, left: 80, right: 80 };

  function isNumeric(val) {
    if (typeof val !== "string") return false;
    const cleaned = val.replace(/[,$%()]/g, "").trim();
    return cleaned !== "" && !isNaN(cleaned);
  }

  // Header row
  const headerRow = new TableRow({
    children: headers.map(
      (h) =>
        new TableCell({
          children: [
            new Paragraph({
              children: [
                new TextRun({
                  text: h,
                  bold: true,
                  size: fontSize,
                  color: headerTextColor,
                  font: FONT,
                }),
              ],
            }),
          ],
          shading: { type: ShadingType.CLEAR, color: "auto", fill: headerFill },
          borders: cellBorders,
          margins: cellMargins,
        })
    ),
  });

  // Data rows with alternating shading
  const dataRows = rows.map((row, rowIdx) => {
    const fill = rowIdx % 2 === 1 ? COLORS.TABLE_ALT_ROW : "FFFFFF";
    return new TableRow({
      children: row.map((cell, colIdx) => {
        const align = colIdx > 0 && isNumeric(cell)
          ? AlignmentType.RIGHT
          : AlignmentType.LEFT;
        return new TableCell({
          children: [
            new Paragraph({
              children: [
                new TextRun({ text: cell, size: fontSize, font: FONT }),
              ],
              alignment: align,
            }),
          ],
          shading: { type: ShadingType.CLEAR, color: "auto", fill: fill },
          borders: cellBorders,
          margins: cellMargins,
        });
      }),
    });
  });

  return new Table({
    rows: [headerRow, ...dataRows],
    width: { size: 100, type: WidthType.PERCENTAGE },
  });
}

// ── 4. createBulletList ──
// items: string[], style: "synthesis" | "informational"
function createBulletList(items, style = "synthesis") {
  const indent =
    style === "synthesis"
      ? { left: 360, hanging: 180 }   // 360 DXA left, hanging indent for bullet
      : { left: 180 };                 // 180 DXA, no hanging

  return items.map(
    (item) =>
      new Paragraph({
        children: [
          new TextRun({ text: "•  ", font: FONT, size: 18 }),
          new TextRun({ text: item, font: FONT, size: 18 }),
        ],
        indent: indent,
        spacing: { after: 60 },
      })
  );
}

// ── 5. createFooter ──
// date: string (e.g., "February 23, 2026")
function createFooter(date) {
  return new Footer({
    children: [
      new Paragraph({
        children: [
          new TextRun({
            text: `Data: S&P Capital IQ via Kensho | Analysis: AI-generated | ${date}`,
            italics: true,
            size: 14, // 7pt
            color: COLORS.FOOTER_TEXT,
            font: FONT,
          }),
        ],
        alignment: AlignmentType.CENTER,
      }),
      new Paragraph({
        children: [
          new TextRun({
            text: "For informational purposes only. Not investment advice.",
            italics: true,
            size: 14,
            color: COLORS.FOOTER_TEXT,
            font: FONT,
          }),
        ],
        alignment: AlignmentType.CENTER,
      }),
    ],
  });
}
```

**Usage in generated scripts:**
1. Copy all functions and constants above into the generated Node.js script
2. Call `createHeaderBanner(...)` instead of manually building banner paragraphs and tables
3. Call `createSectionHeader(...)` for every section title — never manually set paragraph borders
4. Call `createTable(...)` for **all** tabular data — financial summaries, trading comps, M&A activity, relationship tables, funding history, etc. Pass `{ accentHeader: true }` for M&A activity tables (IB/M&A template). For non-numeric tables (e.g., relationships, ownership), the function still works correctly — it only right-aligns cells that contain numeric values.
5. Call `createBulletList(items, "synthesis")` for earnings highlights, strategic fit, integration considerations, and conversation starters
6. Call `createBulletList(items, "informational")` for relationship entries
7. Pass `createFooter(date)` to the Document constructor's `footers.default` property

**What these functions eliminate:**
- Black background tables (enforces `ShadingType.CLEAR` everywhere)
- Separate horizontal rule paragraphs under section headers (enforces `border.bottom` on the paragraph itself)
- Bordered key-value tables in headers (enforces `borders: none`)
- Inconsistent bullet styles (enforces `•` character only)
- Missing footers (provides the exact footer structure)

## Workflow

### Step 1: Identify Inputs

Gather up to four things before proceeding:

1. **Company** — name or ticker. If only a ticker, resolve the full company name with an initial query (e.g., use the company info tool).
2. **Audience** — one of four types:
   - **Equity Research** — for buy-side/sell-side analysts evaluating an investment
   - **IB / M&A** — for bankers profiling a company in transaction context
   - **Corp Dev** — for internal strategic teams evaluating an acquisition target
   - **Sales / BD** — for commercial teams preparing for a client meeting
3. **Comparable companies** (optional) — if the user has specific comps in mind, note them. Otherwise the skill will identify peers from S&P Global data. This matters for Equity Research, IB/M&A, and Corp Dev tear sheets.
4. **Page length preference** (optional) — defaults vary by audience (see below), but the user can override.

If the user doesn't specify an audience, ask.

### Step 2: Read the Audience-Specific Reference

Read the corresponding reference file from this skill's directory:

- Equity Research → `references/equity-research.md`
- IB / M&A → `references/ib-ma.md`
- Corp Dev → `references/corp-dev.md`
- Sales / BD → `references/sales-bd.md`

Each reference defines sections, a query plan, formatting guidance, and page length defaults.

### Step 3: Pull Data via S&P Global MCP

**First:** Create the intermediate file directory:
```bash
mkdir -p /tmp/tear-sheet/
```

Use the **S&P Global** MCP tools (also known as the Kensho LLM-ready API). Claude will have access to structured tools for financial data, company information, market data, consensus estimates, earnings transcripts, M&A transactions, and business relationships. The query plans in each reference file describe what data to retrieve for each section — map these to the appropriate S&P Global tools available in the conversation.

**After each query step, immediately write the retrieved data to the intermediate file(s) specified in the reference file's query plan.** Do not defer writes — data written to disk is protected from context degradation in long conversations.

**Query strategy:**
Each reference file includes a query plan with 4-6 data retrieval steps. These are starting points, not rigid constraints. Prioritize data completeness over minimizing calls:

- **Always pull 4 fiscal years of financial data**, even though only 3 years are displayed. The fourth (earliest) year is needed to compute YoY revenue growth for the first displayed year. Without it, the earliest year's growth rate will show "N/A" — which looks like missing data, not a design choice.
- Execute the query plan as written, using whichever S&P Global tools match the data needed.
- If a tool call returns incomplete results, try alternative tools or narrower queries. For example, if company summary doesn't include segment detail, try the segments tool directly.
- If a data point isn't returned after a targeted retry, move on — label it "N/A" or "Not disclosed."
- Never fabricate data. If the tools don't return a number, do not estimate from training knowledge.

**User-specified comps:** If the user provided comparable companies, query financials and multiples for each comp explicitly. If no comps were provided, use whatever peer data the tools return, or identify peers from the company's sector using the competitors tool.

**Optional context from the user:** Listen for additional context the user provides naturally. If they mention who the acquirer is ("we're looking at this for our platform"), what they sell ("we sell data analytics to banks"), or who the likely buyers are ("this would be interesting to Salesforce or Microsoft"), incorporate that context into the relevant synthesis sections (Strategic Fit, Conversation Starters, Deal Angle). Don't prompt for this information — just use it if offered.

**Private company handling:**
CIQ includes private company data, so query the same way. However, expect sparser results. When generating for a private company:
- Skip: stock price, 52-week range, beta, stock performance, consensus estimates, trading comps
- Lean into: business overview, relationships, ownership structure, whatever financials are available
- Note "Private Company" prominently in the header

### Step 3b: Calculate Derived Metrics

After all data collection is complete and intermediate files are written, compute all derived metrics in a single dedicated pass. This is a calculation-only step — no new MCP queries.

**Read all intermediate files back into context**, then compute:

- **Margins:** Gross Margin %, EBITDA Margin %, FCF Margin %, Operating Margin %
- **Growth rates:** YoY revenue growth, YoY segment revenue growth, YoY EPS growth
- **Efficiency ratios:** FCF Conversion (FCF/EBITDA), R&D as % of Revenue, Capex as % of Revenue
- **Capital structure:** Net Debt (Total Debt − Cash & Equivalents), Net Debt / EBITDA
- **Segment mix:** Each segment's revenue as % of consolidated total revenue (use consolidated revenue as denominator per Data Integrity Rule 8)

**Validation (moved from Arithmetic Validation):** During this calculation pass, enforce all arithmetic checks:

- **Margin calculations:** Verify EBITDA Margin = EBITDA / Revenue, Gross Margin = Gross Profit / Revenue, etc. If the computed margin doesn't match the raw numbers, use the computation from raw components.
- **Growth rates:** Verify YoY growth = (Current − Prior) / Prior. Don't rely on pre-computed growth rates if you have the underlying values.
- **Segment totals:** If showing revenue by segment, verify segments sum to total revenue (within rounding tolerance). If they don't, omit the total row rather than publishing inconsistent math.
- **Percentage columns:** Verify "% of Total" columns sum to ~100%.
- **Valuation cross-checks:** If you show both EV and EV/Revenue, verify EV / Revenue ≈ the stated multiple.

If a validation fails: attempt recalculation from raw data. If still inconsistent, flag the metric as "N/A" rather than publishing incorrect numbers. Quiet math errors in a tear sheet destroy credibility.

**Write results** to `/tmp/tear-sheet/calculations.csv` with columns: `metric,value,formula,components`

Example rows:
```
metric,value,formula,components
gross_margin_fy2024,72.4%,gross_profit/revenue,"9524/13159"
revenue_growth_fy2024,12.3%,(current-prior)/prior,"13159/11716"
net_debt_fy2024,2150,total_debt-cash,"4200-2050"
```

### Step 3c: Verify Data Files

Before generating the document, verify that all intermediate files are present and populated.

**Read each intermediate file** via separate read operations and print a verification summary:

```
=== Tear Sheet Data Verification ===
company-profile.txt: ✓ (12 fields)
financials.csv:      ✓ (36 rows)
segments.csv:        ✓ (8 rows)
valuation.csv:       ✓ (5 rows)
calculations.csv:    ✓ (18 rows)
earnings.txt:        ✓ (populated)
relationships.txt:   ⚠ MISSING
peer-comps.csv:      ✓ (12 rows)
================================
```

**Soft gate:** If any file expected for the current audience type is missing or empty, print a warning but continue. The tear sheet handles missing data gracefully with "N/A" and section skipping. However, the warning ensures visibility into what data was lost.

**Critical rule: The files — not your memory of earlier conversation — are the single source of truth for every number in the document.** When generating the DOCX in Step 4, read values from the intermediate files. Do not rely on conversation context for financial data.

### Step 4: Format as DOCX

Read `/mnt/skills/public/docx/SKILL.md` for docx creation mechanics (docx-js via Node). Apply the Style Configuration above plus the section-specific formatting in the reference file.

**Page length defaults (user can override):**
- Equity Research: 1 page (density is the convention)
- IB / M&A: 1-2 pages
- Corp Dev: 1-2 pages
- Sales / BD: 1-2 pages

If content exceeds the target, each reference file specifies which sections to cut first.

**Output filename:** `[CompanyName]_TearSheet_[Audience]_[YYYYMMDD].docx`
Example: `Nvidia_TearSheet_CorpDev_20260220.docx`

Save to `/mnt/user-data/outputs/` and present to the user.

## Data Integrity Rules

These override everything else:
1. **S&P Global tools are the only source for financial data.** Do not fill gaps with training knowledge — it may be stale or wrong.
2. **Label what you can't find.** Use "N/A" or "Not disclosed" rather than omitting a row silently.
3. **Dates matter.** Note the fiscal year end or reporting period. Don't assume calendar year = fiscal year. Market data (stock prices, market cap) should include an "as of" date.
4. **Don't mix reporting periods.** If you have FY2023 revenue and LTM EBITDA, label them distinctly.
5. **Prefer MCP-returned fields over manual computation.** If the S&P Global tools return a pre-computed field (e.g., net debt, EBITDA, FCF), use that value directly rather than computing it from components. Only compute derived metrics manually when the tools do not return the field. This reduces discrepancies.
6. **Ensure consistency across tear sheet types.** If generating multiple tear sheets for the same company (e.g., equity research and IB/M&A in the same session), the same underlying data points must produce identical values across all outputs. Net debt, revenue, EBITDA, margins, and growth rates must match exactly. Do not re-query or re-compute independently per report — reuse the same retrieved values.
7. **Never downgrade known transaction values.** If the M&A tools return a deal value for a transaction, that value must appear in the output. Do not replace a known deal value with "Undisclosed." Use "Undisclosed" only when the tools genuinely return no value for a transaction.
8. **Use consolidated revenue as the denominator for segment percentages.** When computing "% of Total" for segment tables, divide each segment's revenue by consolidated total revenue (as reported on the income statement), not by the sum of segment revenues. The sum of segments often exceeds consolidated revenue due to intersegment eliminations. Using consolidated revenue ensures percentages align with the total revenue figure shown elsewhere in the document.
9. **Always include forward (NTM) multiples when available.** If the tools return both trailing and forward valuation multiples, both must appear in the output. Forward multiples are the primary valuation reference for equity research, IB/M&A, and corp dev audiences. Never show only trailing multiples when forward data is available.
10. **No S&P Global tool returns executive or management data.** Do not populate management names, titles, or biographical details from training data — this violates Rule 1 and produces stale information. If a management section appears in a template, omit it entirely. Ownership structure (institutional holders, insider %, PE sponsor) may be included only if returned by the tools — gate with "data permitting."

## Intermediate File Rule

All data retrieved from MCP tools must be persisted to structured intermediate files before document generation. These files — not conversation context — are the single source of truth for every number in the document.

**Setup:** At the start of Step 3, create the working directory:
```
mkdir -p /tmp/tear-sheet/
```

**Write-after-query mandate:** After each MCP query step completes, immediately write the retrieved data to the appropriate intermediate file(s). Do not wait until all queries finish. Each reference file's query plan specifies which file(s) to write after each step.

**File schemas:**

| File | Format | Columns / Structure | Used By |
|---|---|---|---|
| `/tmp/tear-sheet/company-profile.txt` | Key-value text | name, ticker, exchange, HQ, sector, industry, founded, employees, market_cap, enterprise_value, stock_price, 52wk_high, 52wk_low, shares_outstanding, beta, ownership | All |
| `/tmp/tear-sheet/financials.csv` | CSV | `period,line_item,value,source` | All |
| `/tmp/tear-sheet/segments.csv` | CSV | `period,segment_name,revenue,source` | ER, IB, CD |
| `/tmp/tear-sheet/valuation.csv` | CSV | `metric,trailing,forward,source` | ER, IB, CD |
| `/tmp/tear-sheet/consensus.csv` | CSV | `metric,fy_year,value,source` | ER |
| `/tmp/tear-sheet/earnings.txt` | Structured text | Quarter, date, key quotes, guidance, key drivers | ER, IB, Sales |
| `/tmp/tear-sheet/relationships.txt` | Structured text | Customers, suppliers, partners, competitors — each with descriptors | IB, CD, Sales |
| `/tmp/tear-sheet/peer-comps.csv` | CSV | `ticker,metric,value,source` | ER, IB, CD |
| `/tmp/tear-sheet/ma-activity.csv` | CSV | `date,target,deal_value,type,rationale,source` | IB, CD |
| `/tmp/tear-sheet/calculations.csv` | CSV | `metric,value,formula,components` | All (written in Step 3b) |

**Abbreviations:** ER = Equity Research, IB = IB/M&A, CD = Corp Dev, Sales = Sales/BD.

Not every audience type uses every file — the reference files define which query steps apply. Files not relevant to the current audience type need not be created.

**Raw values only.** Intermediate files store raw values as returned by the tools. Do not pre-compute margins, growth rates, or other derived metrics in these files — that happens in Step 3b.

**Page budget enforcement:** Each reference file specifies a default page length and a numbered cut order. If the rendered document exceeds the target, apply cuts in the order specified — do not attempt to shrink font sizes or margins below the template minimums. The cut order is a strict priority stack: cut section 1 completely before touching section 2.

## Content Quality Rules

11. **Rewrite every narrative section for the audience.** The CIQ company summary is an input, not an output. Each audience type needs a different description: concise and thesis-oriented for equity research, pitchbook prose for IB, product-focused for Corp Dev, plain language for Sales/BD. Never paste the CIQ summary verbatim into any tear sheet.
12. **Differentiate earnings highlights by audience.** The same earnings call produces different takeaways for different readers. Equity research wants segment-level performance and consensus beat/miss. IB wants margin trajectory and strategic commentary. Sales/BD wants strategic themes that create conversation angles. Do not reuse the same bullets across tear sheet types.
13. **Synthesis sections are the differentiator.** Strategic Fit Analysis, Integration Considerations, Conversation Starters, and Business Overview paragraphs are where the tear sheet earns its value. These sections require analytical reasoning that connects data points into a narrative — listing company names without context is not synthesis.
14. **Flag pending divestitures in segment tables.** If a company has announced a pending divestiture of a segment or business unit, add a footnote or parenthetical to the segment table noting the pending transaction (e.g., "Mobility* — *Pending divestiture, expected mid-2026"). For Corp Dev and IB/M&A tear sheets, include a one-line note below the segment table showing pro-forma revenue and revenue mix excluding the divested segment. This helps the reader evaluate the "go-forward" business without doing the math themselves.

### Arithmetic Validation

**→ Arithmetic validation is now enforced in Step 3b (Calculate Derived Metrics).** All margin calculations, growth rates, segment totals, percentage columns, and valuation cross-checks are validated during the dedicated calculation pass, before document generation begins. See Step 3b for the full validation checklist.$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/catalyst-calendar', 'finance', 'catalyst-calendar', '', 'catalyst-calendar', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Catalyst Calendar

## Workflow

### Step 1: Define Coverage Universe

- List of companies to track (tickers or names)
- Sector / industry focus
- Include macro events? (Fed meetings, economic data, regulatory deadlines)
- Time horizon (next 2 weeks, month, quarter)

### Step 2: Gather Catalysts

For each company, identify upcoming events:

**Earnings & Financial Events**
- Quarterly earnings date and time (pre/post market)
- Annual shareholder meeting
- Investor day / analyst day
- Capital markets day
- Debt maturity / refinancing dates

**Corporate Events**
- Product launches or announcements
- FDA approvals / regulatory decisions
- Contract renewals or expirations
- M&A milestones (close dates, regulatory approvals)
- Management transitions
- Insider trading windows (lockup expirations)

**Industry Events**
- Major conferences (dates, which companies presenting)
- Trade shows and expos
- Regulatory comment periods or rulings
- Industry data releases (monthly sales, traffic, etc.)

**Macro Events**
- Fed meetings (FOMC dates)
- Jobs report, CPI, GDP releases
- Central bank decisions (ECB, BOJ, etc.)
- Geopolitical events with market impact

### Step 3: Calendar View

| Date | Event | Company/Sector | Type | Impact (H/M/L) | Our Positioning | Notes |
|------|-------|---------------|------|-----------------|----------------|-------|
| | | | Earnings/Corp/Industry/Macro | | Long/Short/Neutral | |

### Step 4: Weekly Preview

Each week, generate a forward-looking summary:

**This Week's Key Events:**
1. [Day]: [Company] Q[X] earnings — consensus [$X EPS], our estimate [$X], key focus: [metric]
2. [Day]: [Event] — why it matters for [stocks]
3. [Day]: [Macro release] — expectations and positioning

**Next Week Preview:**
- Early heads-up on important events coming

**Position Implications:**
- Events that could move specific positions
- Any pre-positioning recommended
- Risk management ahead of binary events

### Step 5: Output

- Excel workbook with calendar view and sortable columns
- Weekly preview email/note (markdown)
- Optional: integration with Google Calendar

## Important Notes

- Earnings dates shift — verify against company IR pages and Bloomberg/FactSet closer to the date
- Pre-announce risk: track companies with a history of pre-announcing (positive or negative)
- Conference attendance lists are valuable — which companies are presenting and which are conspicuously absent?
- Some catalysts are recurring (monthly industry data) — build a template and auto-populate
- Color-code by impact level: Red = high impact, Yellow = moderate, Green = routine
- Archive past catalysts with the actual outcome — builds pattern recognition over time$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/earnings-analysis', 'finance', 'earnings-analysis', '', 'earnings-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Equity Research Earnings Update

Create professional **EARNINGS UPDATE REPORTS** analyzing quarterly results for companies already under coverage, following institutional standards (JPMorgan, Goldman Sachs, Morgan Stanley format).

**Key Characteristics:**
- **Length**: 8-12 pages
- **Word Count**: 3,000-5,000 words
- **Tables**: 1-3 summary tables (NOT comprehensive)
- **Figures**: 8-12 charts
- **Turnaround**: 1-2 days (within 24-48 hours of earnings)
- **Audience**: Clients already familiar with the company
- **Focus**: What's NEW - beat/miss, updated estimates, thesis impact
- **Font**: Times New Roman throughout (unless user specifies otherwise)

## When to Use

Use when the user requests:
- "Create an earnings update for [Company] Q3 2024"
- "Analyze [Company]'s quarterly results"
- "Post-earnings report for [Company]"
- "Q1/Q2/Q3/Q4 update for [Company]"

**Do NOT use if:**
- User requests "initiation report" → Use different skill
- User requests "flash note" or "quick take" → Different format
- Company is not already covered → Need initiation first

## Critical Requirements

### 1. Speed & Timeliness
- Publish within 24-48 hours of earnings release
- Focus on NEW information only
- Don't rehash company background extensively

### 2. Beat/Miss Analysis
- Lead with whether company beat or missed estimates
- Quantify variances (e.g., "Revenue beat by $120M or 3%")
- Explain WHY results differed from expectations

### 3. Summary Format
- Keep tables to 1-3 (summary only, not comprehensive)
- No full P&L/Cash Flow/Balance Sheet (just key metrics)
- Assume reader has seen initiation report

### 4. Citations & Source Attribution ⭐⭐⭐ MANDATORY

**CRITICAL**: Properly cite all data with SPECIFIC sources and CLICKABLE HYPERLINKS.

**Include specific citations WITH CLICKABLE LINKS in every figure and table:**

```
Source: Q3 2024 10-Q filed November 8, 2024; Company earnings release
        [Hyperlink "10-Q" to: https://www.sec.gov/cgi-bin/viewer?accession=...]
        [Hyperlink "earnings release" to: https://investor.company.com/news/q3-2024]
```

**HOW HYPERLINKS SHOULD APPEAR IN WORD:**
- Document names appear as blue, underlined clickable links
- Reader can Ctrl+Click to open source directly
- Not plain text URLs - formatted hyperlinks with display text

**REQUIRED SOURCES LIST:**

Cite in every earnings update:
- ✅ Earnings release (with date and URL)
- ✅ 10-Q filing (with filing date and EDGAR link)
- ✅ Earnings call transcript (with date)
- ✅ Investor presentation/supplemental materials (if available)
- ✅ Consensus estimates source (Bloomberg/FactSet/etc. with date)
- ✅ Prior guidance (from previous quarter's materials)

**REFERENCE SECTION WITH CLICKABLE HYPERLINKS:**

Include "Sources" section at end of report:

```
SOURCES & REFERENCES

Earnings Materials (Q3 2024):
• Earnings Release (November 7, 2024)
  [Hyperlink entire line to: https://investor.company.com/news/q3-2024-earnings]

• Form 10-Q (Filed November 8, 2024)
  [Hyperlink to: https://www.sec.gov/cgi-bin/viewer?accession=...]

• Earnings Call Transcript (November 7, 2024)
  [Hyperlink to: https://seekingalpha.com/article/...]

• Investor Presentation (November 7, 2024)
  [Hyperlink to: https://investor.company.com/presentations/q3-2024.pdf]
```

**VERIFICATION CHECKLIST:**
- [ ] Every figure has source with specific document and date
- [ ] Every table has source with document reference
- [ ] Beat/miss analysis cites consensus source with date
- [ ] Guidance changes cite current and prior guidance sources
- [ ] Key statistics have footnotes
- [ ] Sources section lists all materials with URLs
- [ ] ALL URLs are CLICKABLE HYPERLINKS (not plain text)
- [ ] All SEC filings hyperlinked to EDGAR viewer

### 5. Updated Estimates
- Update forward estimates based on results
- Show old vs. new estimates clearly
- Explain what changed and why

## High-Level Workflow

The earnings update process follows 5 phases:

### Phase 1: Data Collection (30-60 minutes)

**🚨🚨🚨 CRITICAL: TRAINING DATA IS OUTDATED 🚨🚨🚨**

**BEFORE STARTING - COMPLETE THESE 4 STEPS IN ORDER:**
1. **CHECK TODAY'S DATE** - Write down the current date
2. **SEARCH FOR LATEST** - Use web search: "[Company] latest earnings results"
3. **VERIFY THE DATE** - Confirm earnings release is within last 3 months
4. **CHECK TRANSCRIPT DATE** - Verify transcript date matches release date

**COMMON MISTAKE**: Using outdated earnings calls from training data instead of searching for the latest.

**REQUIREMENTS:**
- ✅ Search for latest earnings - do NOT rely on training data
- ✅ Write down today's date and the release date found
- ✅ Verify release date is within 3 months of today
- ✅ Verify transcript date matches release date
- ✅ If dates don't match or are old (>3 months), search again

**See [references/workflow.md](references/workflow.md)** for detailed search procedures and verification steps.

### Phase 2: Analysis (2-3 hours)
- Beat/miss analysis for each key metric
- Segment/geographic/product breakdown
- Margin and guidance analysis
- Update financial model and estimates

**See [references/workflow.md](references/workflow.md)** for detailed analysis framework.

### Phase 3: Chart Generation (1-2 hours)
Create 8-12 charts focusing on quarterly trends and what's new:
- Quarterly revenue progression
- Quarterly EPS progression
- Quarterly margin trends
- Revenue by segment/geography
- Key operating metrics
- Beat/miss summary
- Estimate revisions
- Valuation charts

**See [references/workflow.md](references/workflow.md)** for chart specifications.

### Phase 4: Report Creation (2-3 hours)
Create 8-12 page DOCX report with specific structure.

**See [references/report-structure.md](references/report-structure.md)** for complete page-by-page templates and formatting requirements.

**High-level structure:**
- Page 1: Earnings summary with rating and price target
- Pages 2-3: Detailed results analysis
- Pages 4-5: Key metrics & guidance
- Pages 6-7: Updated investment thesis
- Pages 8-10: Valuation & estimates
- Pages 11-12: Appendix (optional)

### Phase 5: Quality Check & Delivery (30 minutes)
Verify content, formatting, accuracy, and timeliness before delivery.

**See [references/best-practices.md](references/best-practices.md)** for quality checklist and common mistakes to avoid.

## Output Specification

**Primary Deliverable**: DOCX report (8-12 pages)
**File Name**: `[Company]_Q[Quarter]_[Year]_Earnings_Update.docx`
**Example**: `Nike_Q2_FY24_Earnings_Update.docx`

**Contents:**
- Page 1: Summary with rating, price target, key takeaways
- Pages 2-3: Detailed results analysis
- Pages 4-5: Key metrics and guidance
- Pages 6-7: Updated thesis assessment
- Pages 8-10: Valuation and estimates
- Pages 11-12: Appendix (optional)
- 8-12 embedded charts
- 1-3 summary tables
- Complete sources section with clickable hyperlinks

**Optional Deliverable**: XLS model update (optional for earnings updates)

## Key Differences from Initiation Report

| Aspect | Earnings Update | Initiation Report |
|--------|----------------|-------------------|
| **Length** | 8-12 pages | 30-50 pages |
| **Words** | 3,000-5,000 | 10,000-15,000 |
| **Tables** | 1-3 summary | 12-20 comprehensive |
| **Figures** | 8-12 | 25-35 |
| **Turnaround** | 1-2 days | 3-6 weeks |
| **Scope** | Quarterly results | Complete company |
| **Focus** | What's NEW | Everything |
| **Company Background** | Brief mention | 6-10 pages |
| **XLS Model** | Optional | Required |

## Resources

### references/workflow.md
Detailed Phase 1-5 instructions with step-by-step procedures for data collection, analysis, chart generation, and report creation.

### references/report-structure.md
Complete page-by-page templates, table formats, and formatting requirements for the DOCX report.

### references/best-practices.md
Examples of good/bad headlines, tips for success, common mistakes to avoid, and comprehensive quality checklist.

## Dependencies

**Required:**
- Python (matplotlib, pandas, seaborn) for chart generation
- DOCX skill for report creation

**Optional:**
- XLS skill for model updates (not required for earnings updates)$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/earnings-preview', 'finance', 'earnings-preview', '', 'earnings-preview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Earnings Preview

## Workflow

### Step 1: Gather Context

- Identify the company and reporting quarter
- Pull consensus estimates via web search (revenue, EPS, key segment metrics)
- Find the earnings date and time (pre-market vs. after-hours)
- Review the company's prior quarter earnings call for any guidance or commentary

### Step 2: Key Metrics Framework

Build a "what to watch" framework specific to the company:

**Financial Metrics:**
- Revenue vs. consensus (total and by segment)
- EPS vs. consensus
- Margins (gross, operating, net) — expanding or contracting?
- Free cash flow
- Forward guidance vs. consensus

**Operational Metrics** (sector-specific):
- Tech/SaaS: ARR, net retention, RPO, customer count
- Retail: Same-store sales, traffic, basket size
- Industrials: Backlog, book-to-bill, price vs. volume
- Financials: NIM, credit quality, loan growth, fee income
- Healthcare: Scripts, patient volumes, pipeline updates

### Step 3: Scenario Analysis

Build 3 scenarios with stock price implications:

| Scenario | Revenue | EPS | Key Driver | Stock Reaction |
|----------|---------|-----|------------|----------------|
| Bull | | | | |
| Base | | | | |
| Bear | | | | |

For each scenario:
- What would need to happen operationally
- What management commentary would signal this
- Historical context — how has the stock moved on similar prints?

### Step 4: Catalyst Checklist

Identify the 3-5 things that will determine the stock's reaction:

1. [Metric] vs. [consensus/whisper number] — why it matters
2. [Guidance item] — what the buy-side expects to hear
3. [Narrative shift] — any strategic changes, M&A, restructuring

### Step 5: Output

One-page earnings preview with:
- Company, quarter, earnings date
- Consensus estimates table
- Key metrics to watch (ranked by importance)
- Bull/base/bear scenario table
- Catalyst checklist
- Trading setup: recent stock performance, implied move from options

## Important Notes

- Consensus estimates change — always note the source and date of estimates
- "Whisper numbers" from buy-side surveys are often more relevant than published consensus
- Historical earnings reactions help calibrate expectations (search for "[company] earnings reaction history")
- Options-implied move tells you what the market expects — compare to your scenarios$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/idea-generation', 'finance', 'idea-generation', '', 'idea-generation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Idea Generation

## Workflow

### Step 1: Define Search Criteria

Ask the user for parameters:
- **Direction**: Long ideas, short ideas, or both
- **Market cap**: Large, mid, small, micro
- **Sector**: Specific sector or cross-sector
- **Style**: Value, growth, quality, special situation, event-driven
- **Geography**: US, international, global
- **Theme**: Any specific thematic angle (AI, reshoring, aging demographics, etc.)

### Step 2: Quantitative Screens

Run screens based on the style:

**Value Screen**
- P/E below sector median
- EV/EBITDA below historical average
- Free cash flow yield >5%
- Price/book below 1.5x
- Insider buying in last 90 days
- Dividend yield above market average

**Growth Screen**
- Revenue growth >15% YoY
- Earnings growth >20% YoY
- Revenue acceleration (growth rate increasing)
- Expanding margins
- High return on invested capital (>15%)
- Strong net retention (>110% for SaaS)

**Quality Screen**
- Consistent revenue growth (5+ years)
- Stable or expanding margins
- ROE >15%
- Low debt/equity
- High free cash flow conversion
- Insider ownership >5%

**Short Screen**
- Declining revenue or decelerating growth
- Margin compression
- Rising receivables / inventory vs. sales
- Insider selling
- Valuation premium to peers without justification
- High short interest with deteriorating fundamentals
- Accounting red flags (auditor changes, restatements)

**Special Situation Screen**
- Recent IPOs / SPACs with lockup expirations
- Spin-offs in last 12 months
- Companies emerging from restructuring
- Activist involvement
- Management changes at underperforming companies

### Step 3: Thematic Sweep

For thematic ideas, research the theme and identify beneficiaries:

1. Define the thesis (e.g., "AI infrastructure spending accelerates through 2026")
2. Map the value chain — who benefits directly vs. indirectly?
3. Identify pure-play vs. diversified exposure
4. Assess which names are already "priced in" vs. under-appreciated
5. Look for second-order beneficiaries that the market hasn't connected to the theme

### Step 4: Idea Presentation

For each idea that passes the screen, present:

**[Company Name] — [Long/Short] — [One-Line Thesis]**

| Metric | Value | vs. Peers |
|--------|-------|-----------|
| Market cap | | |
| EV/EBITDA (NTM) | | |
| P/E (NTM) | | |
| Revenue growth | | |
| EBITDA margin | | |
| FCF yield | | |

**Thesis (3-5 bullets):**
- Why this is mispriced
- What the market is missing
- Catalyst to realize value

**Key Risks:**
- What would make this wrong

**Suggested Next Steps:**
- Build full model? Deep-dive diligence? Expert call?

### Step 5: Output

- Shortlist of 5-10 ideas with one-page summaries
- Screening criteria and methodology documented
- Comparison table across all ideas
- Prioritized list: which ideas to research first

## Important Notes

- Screens surface candidates, not conclusions — every screen output needs fundamental work
- The best ideas often come from intersections (e.g., quality company at value price due to temporary headwind)
- Avoid crowded trades — check ownership data, short interest, and how many analysts cover the name
- Contrarian ideas need a catalyst — being early without a catalyst is the same as being wrong
- Track idea hit rates over time — which screens and approaches produce the best ideas?
- Short ideas need higher conviction — timing is harder and risk is asymmetric$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/initiating-coverage', 'finance', 'initiating-coverage', '', 'initiating-coverage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Initiating Coverage

Create institutional-quality equity research initiation reports through a structured 5-task workflow. Each task must be executed separately with verified inputs.

## Overview

This skill produces comprehensive first-time coverage reports following institutional standards (JPMorgan, Goldman Sachs, Morgan Stanley format). Tasks are executed individually, each verifying prerequisites before proceeding.

**Default Font**: Times New Roman throughout all documents (unless user specifies otherwise).

---

## ⚠️ CRITICAL: One Task at a Time

**THIS SKILL OPERATES IN SINGLE-TASK MODE ONLY.**

### If User Requests Full Pipeline

When user requests:
- "Create a coverage initiation report for [Company]"
- "Write an initiation report for [Company]"
- "Do the entire equity research process for [Company]"
- "Complete all 5 tasks for [Company]"
- Any request that implies running multiple tasks or the entire workflow

**REQUIRED RESPONSE:**

1. **Ask which specific task to perform:**
   ```
   I can help you create an equity research initiation report for [Company].
   This involves 5 separate tasks that need to be completed individually:

   1. Company Research - Research business, management, industry
   2. Financial Modeling - Build projection model
   3. Valuation Analysis - DCF and comparable companies
   4. Chart Generation - Create 25-35 charts
   5. Report Assembly - Compile final report

   Which task would you like to start with?
   ```

2. **When user explicitly requests all tasks together:**
   ```
   I understand you'd like to complete the entire initiation report pipeline.
   Currently, this skill supports executing one task at a time, which allows
   for better quality control and review at each stage.

   We're working on a seamless end-to-end workflow that will make this process
   more automated, but for now, we'll need to complete each task separately.

   Would you like to start with Task 1 (Company Research)?
   ```

3. **Never automatically assume which task to start** - always ask user to confirm.

4. **Never execute multiple tasks in sequence** - complete one task, deliver outputs, then wait for next user request.

### Task Execution Rules

- ✅ Execute exactly ONE task per user request
- ✅ Always verify prerequisites before starting a task
- ✅ Deliver task outputs and confirm completion
- ✅ Wait for user to explicitly request the next task
- ❌ Never chain multiple tasks together automatically
- ❌ Never assume user wants to proceed to next task
- ❌ Never execute Tasks 3-5 without verifying required inputs exist

### ⚠️ Deliverables Policy: NO SHORTCUTS

**DELIVER ONLY THE SPECIFIED OUTPUTS. DO NOT CREATE EXTRA DOCUMENTS.**

Each task specifies exact deliverables. Do NOT create:
- ❌ "Completion summaries"
- ❌ "Executive summaries"
- ❌ "Quick reference guides"
- ❌ "Next steps documents"
- ❌ "Task completion reports"
- ❌ Any other "helpful" documentation not explicitly specified

**Why**: These extras waste context and are not part of the professional workflow.

**What TO deliver**:
- ✅ Task 1: Research document (.md) — **NOTHING ELSE**
- ✅ Task 2: Financial model (.xlsx) — **NOTHING ELSE**
- ✅ Task 3: Valuation analysis (.md) + Excel tabs added to Task 2 file — **NOTHING ELSE**
- ✅ Task 4: Charts zip file (.zip) — **NOTHING ELSE**
- ✅ Task 5: Final report (.docx) — **NOTHING ELSE**

**If a deliverable is not listed above, DO NOT CREATE IT.**

---

## Task Selection

Select which task to execute:

| Task | Name | Prerequisites | Output |
|------|------|--------------|--------|
| **1** | Company Research | Company name/ticker | 6-8K word document |
| **2** | Financial Modeling | 10-K or financials access | Excel model (6 tabs) |
| **3** | Valuation Analysis | Financial model (Task 2) | Valuation + price target |
| **4** | Chart Generation | Tasks 1, 2, 3 + external data | 25-35 PNG/JPG charts |
| **5** | Report Assembly | ALL previous tasks (1-4) | 30-50 page DOCX report |

---

## How to Use This Skill

### User Request Patterns and Responses

**Pattern 1: User specifies a specific task**
```
User: "Use initiating-coverage, Task 1 for Tesla"
Response: ✅ Execute Task 1 immediately
```

**Pattern 2: User asks for "initiation report" or "full pipeline"**
```
User: "Create a coverage initiation report for Tesla"
Response: ❌ DO NOT start any task automatically
         ✅ Ask which task to start with (see template above)
```

**Pattern 3: User wants to do "all tasks" or "entire workflow"**
```
User: "I want to complete all 5 tasks for Tesla"
Response: ❌ DO NOT chain tasks together
         ✅ Explain one-at-a-time limitation (see template above)
         ✅ Ask if they want to start with Task 1
```

### Correct Usage Examples

**Executing a single task:**
```
"Use initiating-coverage skill, Task 1 for Tesla"
"Do Task 2 of initiating-coverage for Tesla"
"Run Task 3 for Tesla using the initiating-coverage skill"
```

**Completing full report (requires 5 separate requests):**
```
Request 1: "Do Task 1 for Tesla" → Complete → Deliver outputs
Request 2: "Do Task 2 for Tesla" → Complete → Deliver outputs
Request 3: "Do Task 3 for Tesla" → Complete → Deliver outputs
Request 4: "Do Task 4 for Tesla" → Complete → Deliver outputs
Request 5: "Do Task 5 for Tesla" → Complete → Deliver outputs
```

### Task Execution Order

For a complete initiation report, tasks must be executed in separate user requests following this order:

```
Request 1: Task 1 - Company Research (independent)
           ↓ [User reviews outputs and requests next task]
Request 2: Task 2 - Financial Modeling (independent)
           ↓ [User reviews outputs and requests next task]
Request 3: Task 3 - Valuation Analysis (requires Task 2 output)
           ↓ [User reviews outputs and requests next task]
Request 4: Task 4 - Chart Generation (requires Tasks 2 & 3 outputs)
           ↓ [User reviews outputs and requests next task]
Request 5: Task 5 - Report Assembly (requires ALL previous task outputs)
```

**Note**: Tasks 1 and 2 can be run in any order. Tasks 3-5 have strict dependencies and must verify inputs before proceeding.

---

## Task 1: Company Research

**Purpose**: Research company's business, management, competitive position, industry, and risks.

**Prerequisites**: ✅ None (fully independent)
- Company name or ticker symbol

**Process**:
1. Verify company name/ticker provided
2. Load detailed instructions from references/task1-company-research.md
3. Execute qualitative research workflow
4. Deliver research document

**Output**: Company Research Document (6,000-8,000 words)
- Company overview & history
- Management bios (300-400 words × 3-4 execs)
- Products & services analysis
- Industry overview
- Competitive analysis (5-10 competitors)
- TAM sizing
- Risk assessment (8-12 risks)

**File name**: `[Company]_Research_Document_[Date].md`

**⚠️ DELIVER ONLY THIS 1 FILE. NO completion summaries, no extra documents.**

**⚠️ DO NOT TAKE SHORTCUTS:**
- ✅ Write full 6,000-8,000 words (not summaries)
- ✅ Complete 300-400 word bios for ALL 3-4 executives
- ✅ Analyze ALL 5-10 competitors thoroughly
- ✅ Cover all 8-12 risks across 4 categories
- ❌ Do not abbreviate sections to save time
- ❌ Do not skip any required sections

**Verification before proceeding**: None required for this task.

---

## Task 2: Financial Modeling

**Purpose**: Extract historical financials and build comprehensive Excel financial model with projections and scenarios.

**Prerequisites**: ⚠️ Verify before starting
- **Required**: Access to company financial data
  - For public companies: Latest 10-K from SEC EDGAR
  - For private companies: Financial statements or available estimates
  - OR: Pre-extracted historical financials provided by user
- **Optional**: Company research (Task 1) for business context

**Input Verification**:
```
BEFORE STARTING - Select approach:

Option A: Extract financials (most common)
- [ ] Have access to 10-K or financial statements?
- [ ] Ready to extract 3-5 years of data?

Option B: User provided pre-extracted financials
- [ ] Historical financials file received?
- [ ] Contains income statement, cash flow, balance sheet (3-5 years)?

Optional:
- [ ] Company research (Task 1) complete for context?
```

**Process**:
1. Verify access to financial data
2. Load detailed instructions from references/task2-financial-modeling.md
3. **Step 1**: Extract historical financials (if needed)
4. **Step 2+**: Build projection model with 6 essential tabs
5. Deliver Excel model

**Output**: Excel Financial Model (.xlsx)
- 6 essential tabs:
  1. **Revenue Model** - Product breakdown (20-30 rows) + Geography breakdown (15-20 rows)
  2. **Income Statement** - Full P&L with 40-50 line items, historical (3-5 years) + projected (5 years)
  3. **Cash Flow Statement** - Operating/Investing/Financing activities, historical + projected
  4. **Balance Sheet** - Assets/Liabilities/Equity, historical + projected
  5. **Scenarios** - Bull/Base/Bear comparison table
  6. **DCF Inputs** - Prepared for Task 3 valuation

**File name**: `[Company]_Financial_Model_[Date].xlsx`

**⚠️ DELIVER ONLY THIS 1 FILE. NO completion summaries, no extra documents.**

**⚠️ DO NOT TAKE SHORTCUTS:**
- ✅ If extracting financials: Extract ALL line items from 3 financial statements (3-5 years)
- ✅ Build ALL 6 projection tabs completely with full detail
- ✅ Create detailed revenue model with 20-30 product rows AND 15-20 geography rows
- ✅ Build complete income statement with 40-50 line items (not abbreviated)
- ✅ Include full cash flow statement and balance sheet with all line items
- ✅ Complete ALL three scenarios (Bull/Base/Bear) with different parameters
- ❌ Do not create simplified/abbreviated versions
- ❌ Do not skip any of the 6 essential tabs
- ❌ Do not skip historical financials extraction if needed

**Verification before proceeding to Task 3**:
- [ ] Historical financials extracted (if needed) or provided
- [ ] Excel file created and can be opened
- [ ] Model has all 6 essential tabs (Revenue Model, Income Statement, Cash Flow, Balance Sheet, Scenarios, DCF Inputs)
- [ ] Historical data (3-5 years) incorporated
- [ ] Projections complete (5 years forward)
- [ ] Scenarios complete (Bull/Base/Bear)

---

## Task 3: Valuation Analysis

**Purpose**: Perform comprehensive valuation using DCF, comparables, and precedent transactions.

**Prerequisites**: ⚠️ Verify before starting
- **Required**: Financial model from Task 2
  - Projected income statements
  - Projected cash flows
  - Revenue and EBITDA forecasts
  - DCF inputs (unlevered FCF)

**⚠️ CRITICAL: DO NOT START THIS TASK UNLESS TASK 2 IS COMPLETE**

This task requires the financial model from Task 2. Starting without it will result in incomplete work.

**IF TASK 2 IS NOT COMPLETE**: Stop immediately and inform the user that Task 2 (Financial Modeling) must be completed first. Do not attempt to proceed or create placeholder valuations.

**Input Verification**:
```
BEFORE STARTING:
- [ ] Task 2 complete? (Financial model exists)
- [ ] Model file path/location known?
- [ ] Can access projected financials from model?

Required from model:
- [ ] Projected FCF (5 years)
- [ ] Revenue projections
- [ ] EBITDA projections
- [ ] Terminal year metrics
```

**Process**:
1. Verify financial model is accessible
2. Load detailed instructions from references/task3-valuation.md
3. Execute valuation workflow
4. Deliver valuation analysis

**Output**: Valuation Analysis (4-6 pages + Excel tabs)
- DCF analysis with sensitivity tables
- Comparable companies (5-10 peers with statistical summary)
- Precedent transactions (if applicable)
- Valuation football field
- **Price target**: $XX.XX
- **Recommendation**: BUY/HOLD/SELL
- **Upside**: XX%
- Key catalysts (3-5)

**Files**:
- `[Company]_Valuation_Analysis_[Date].md` (written analysis document)
- Excel tabs added to `[Company]_Financial_Model_[Date].xlsx` (from Task 2)
  - DCF tab with calculations
  - Sensitivity analysis tab
  - Comparable companies tab
  - Valuation summary tab

**⚠️ DELIVER ONLY: 1 markdown file + 4 tabs added to existing Excel. NO completion summaries, no extra documents.**

**⚠️ DO NOT TAKE SHORTCUTS:**
- ✅ Complete full DCF analysis with sensitivity matrix (not simplified)
- ✅ Analyze ALL 5-10 comparable companies with full data
- ✅ Include statistical summary in comps table (max/75th/median/25th/min)
- ✅ Create complete sensitivity analysis tab with multiple WACC and terminal growth scenarios
- ✅ Write full 4-6 pages of valuation analysis (not abbreviated)
- ✅ Research and justify price target with specific methodology
- ❌ Do not skip comparable company analysis
- ❌ Do not create simplified DCF without sensitivity

**Verification before proceeding to Task 4**:
- [ ] Price target determined
- [ ] Valuation uses multiple methods (DCF + Comps minimum)
- [ ] DCF sensitivity table complete
- [ ] Comparable companies table includes statistical summary

---

## Task 4: Chart Generation

**Purpose**: Generate 25-35 professional financial charts for the report.

**Prerequisites**: ⚠️ Verify before starting
- **Required**: Company research from Task 1
  - Company history and milestones (for timeline charts)
  - Management team and org structure (for org charts)
  - Product portfolio (for product charts)
  - Customer segmentation (for customer charts)
  - Competitive landscape (for competitive charts)
  - TAM analysis (for market size charts)
- **Required**: Financial model from Task 2 (with Task 3 valuation tabs added)
  - Revenue by product/geography data (Task 2 tabs)
  - Margin trends (Task 2 tabs)
  - Scenario comparison data (Task 2 tabs)
  - DCF sensitivity table (Task 3 tab in same Excel file)
  - Comparable companies data (Task 3 tab in same Excel file)
  - Valuation ranges (Task 3 tab in same Excel file)
- **Required**: External market data
  - Historical stock price data (Yahoo Finance, Bloomberg, etc.)
  - Historical valuation multiples (for historical trend charts)

**⚠️ CRITICAL: DO NOT START THIS TASK UNLESS TASKS 1, 2, AND 3 ARE COMPLETE**

This task requires outputs from all three previous tasks. Starting without them will result in incomplete charts.

**IF ANY OF TASKS 1, 2, OR 3 ARE NOT COMPLETE**: Stop immediately and inform the user which tasks need to be completed first. The specific requirements are:
- Task 1: Company research document (for 9 charts)
- Task 2: Financial model with all 6 tabs (for 8 charts)
- Task 3: Valuation tabs added to the model (for 6 charts)
- External data access (for 2 charts)

Do not attempt to create placeholder charts or skip charts due to missing data.

**Input Verification**:
```
BEFORE STARTING:
- [ ] Task 1 complete? (Company research exists)
- [ ] Task 2 complete? (Financial model exists)
- [ ] Task 3 complete? (Valuation analysis exists)
- [ ] Can access external market data sources?

Required from Task 1:
- [ ] Company history and milestones (for charts 05, 06)
- [ ] Management team structure (for chart 07)
- [ ] Product portfolio details (for chart 08)
- [ ] Customer segmentation data (for chart 09)
- [ ] Competitive landscape analysis (for charts 16, 17, 18)
- [ ] TAM sizing and market data (for chart 15)

Required from Task 2:
- [ ] Revenue by product (historical + projected) - for chart 03 ⭐
- [ ] Revenue by geography (historical + projected) - for chart 04 ⭐
- [ ] Income statement with margins (for charts 02, 10, 11)
- [ ] Cash flow statement (for chart 12)
- [ ] Scenario comparison data (for chart 14)

Required from Task 3:
- [ ] DCF sensitivity matrix - for chart 28 ⭐
- [ ] DCF components (for chart 29)
- [ ] Comparable companies data (for charts 30, 31)
- [ ] Valuation ranges - for chart 32 ⭐

Required from External Sources:
- [ ] Historical stock price data (for chart 01)
- [ ] Historical valuation multiples (for chart 34)
```

**Process**:
1. Verify model and valuation outputs are accessible
2. Load detailed instructions from references/task4-chart-generation.md
3. Execute chart generation workflow
4. Package all charts into a zip file
5. Deliver zip file

**Output**: 25-35 Professional Chart Files (PNG/JPG, 300 DPI) packaged in zip

**4 MANDATORY Charts** (must be present) ⭐:
- chart_03: Revenue by product (stacked area)
- chart_04: Revenue by geography (stacked bar)
- chart_28: DCF sensitivity (2-way heatmap)
- chart_32: Valuation football field (horizontal bars)

**25 REQUIRED Charts** (specific list):
- Investment Summary: chart_01
- Financial Performance: charts 02, 03⭐, 04⭐, 10, 11, 12, 14
- Company 101: charts 05, 06, 07, 08, 09, 15, 16
- Competitive/Market: charts 17, 18
- Scenario Analysis: chart 13
- Valuation: charts 28⭐, 29, 30, 31, 32⭐, 33, 34

**10 OPTIONAL Charts** (for 26-35 range):
- charts 19-27, 35 (customer acquisition, unit economics, product roadmap, etc.)

**IMPORTANT**: Task 5 embeds ALL charts created (25-35) for visual density (1 chart per 200-300 words).

**File naming**: `chart_01_description.png`, `chart_02_description.png`, etc.

**Deliverable**: `[Company]_Charts_[Date].zip` containing all 25-35 chart files + chart_index.txt

**⚠️ DELIVER ONLY THIS 1 ZIP FILE. NO completion summaries, no separate chart lists, no extra documents.**

**⚠️ DO NOT TAKE SHORTCUTS:**
- ✅ Create ALL 25 required charts minimum (specific list provided in task4-chart-generation.md)
- ✅ Include ALL 4 mandatory charts:
  - chart_03: Revenue by product (stacked area) ⭐
  - chart_04: Revenue by geography (stacked bar) ⭐
  - chart_28: DCF sensitivity (heatmap) ⭐
  - chart_32: Valuation football field ⭐
- ✅ Optional: Add 1-10 more charts to reach 26-35 total for greater visual density
- ✅ Generate professional-quality charts at 300 DPI (not low-res placeholders)
- ✅ Create unique, well-formatted charts for each visualization
- ✅ Package all charts in zip file with chart index
- ❌ Do not create only 10-15 charts (minimum is 25)
- ❌ Do not skip any of the 4 mandatory charts
- ❌ Do not use low-quality/placeholder images

**Verification before proceeding to Task 5**:
- [ ] Minimum 25 chart files created (required)
- [ ] All 4 mandatory charts present:
  - [ ] chart_03: Revenue by product ⭐
  - [ ] chart_04: Revenue by geography ⭐
  - [ ] chart_28: DCF sensitivity ⭐
  - [ ] chart_32: Valuation football field ⭐
- [ ] All charts open and display correctly
- [ ] Charts saved at 300 DPI (print quality)
- [ ] Chart index created listing all files with categories
- [ ] All charts packaged in zip file
- [ ] File naming follows convention: chart_##_description.png

---

## Task 5: Report Assembly

**Purpose**: Write and assemble the comprehensive final DOCX report.

**Prerequisites**: ⚠️ Verify before starting
- **Required**: Company research from Task 1
  - All 6-8K words of content
  - Management bios
  - Competitive analysis
  - Risk assessment
- **Required**: Financial model from Task 2
  - Excel workbook
  - All projections and scenarios
- **Required**: Valuation analysis from Task 3
  - Price target and recommendation
  - DCF, comps, precedent transactions
  - All valuation data
- **Required**: Chart files from Task 4
  - Zip file containing all 25-35 PNG/JPG files
  - Chart index included in zip

**⚠️ CRITICAL: DO NOT START THIS TASK UNLESS ALL TASKS 1-4 ARE COMPLETE**

This is the final assembly task. It cannot be completed without all previous work products.

**IF ANY OF TASKS 1, 2, 3, OR 4 ARE NOT COMPLETE**: Stop immediately and inform the user which tasks need to be completed first. The specific requirements are:
- Task 1: Company research document (6-8K words)
- Task 2: Financial model with all 6 tabs
- Task 3: Valuation analysis with price target and recommendation
- Task 4: Charts zip file with 25-35 charts

Do not attempt to create placeholder content, substitute missing sections, or assemble an incomplete report. The report requires ALL inputs to be publication-ready.

**Input Verification**:
```
BEFORE STARTING - ALL TASKS MUST BE COMPLETE:

Task 1 Verification:
- [ ] Company research document exists? (6-8K words)
- [ ] Management bios complete? (300-400 words × 3-4 execs)
- [ ] Competitive analysis complete? (5-10 competitors)
- [ ] Risk assessment complete? (8-12 risks)

Task 2 Verification:
- [ ] Financial model exists and can be opened?
- [ ] Model has projections (5 years)?
- [ ] Scenarios exist (Bull/Base/Bear)?

Task 3 Verification:
- [ ] Valuation analysis complete?
- [ ] Price target determined?
- [ ] Recommendation set? (BUY/HOLD/SELL)
- [ ] DCF and comps complete?

Task 4 Verification:
- [ ] Chart zip file exists?
- [ ] Can extract/access all 25-35 chart files from zip?
- [ ] All 4 mandatory charts present?
  - [ ] Revenue by product (stacked area)
  - [ ] Revenue by geography (stacked bar)
  - [ ] DCF sensitivity (heatmap)
  - [ ] Valuation football field
- [ ] Chart files accessible and can be opened?

IF ANY VERIFICATION FAILS: Stop and complete missing task first.
```

**Process**:
1. **CRITICAL**: Verify ALL prerequisites before starting
2. Load detailed instructions from references/task5-report-assembly.md
3. Execute report assembly workflow using Claude's built-in skills:
   - **Use DOCX skill** to create and manipulate the Word document
   - **Use XLSX skill** to read Excel data from Task 2/3
   - **Use Read tool** to read Task 1 and Task 3 markdown files
   - Read Task 1 .md file → Convert to Word formatting → Insert charts inline
   - Read Task 2 .xlsx file → Extract tables → Write quantitative analysis
   - Read Task 3 .md file + Excel tabs → Copy/adapt valuation analysis
   - Insert Task 4 .png chart files throughout using DOCX skill
   - Create text-dense report with charts interspersed every 200-300 words
4. Save and deliver final DOCX report

**Key Principles**:
- Use Claude's DOCX and XLSX skills (NOT Python libraries)
- Use actual file operations (read .md/.xlsx/.png files, write .docx file)
- Good equity research reports are text-dense with lots of illustrating images (60-80% page coverage, 1+ chart per page)

**🔥 CRITICAL: GO ALL OUT ON THIS TASK**

**THIS IS THE FINAL DELIVERABLE. DO NOT TAKE SHORTCUTS.**

- ✅ **Use full token budget** - This is the culmination of all previous work
- ✅ **Write every section completely** - Do not summarize or abbreviate
- ✅ **Hit ALL minimum requirements** - 30+ pages, 10,000+ words, 25+ charts, 12+ tables
- ✅ **Be thorough on projection assumptions** - 2,000-3,000 words with product-by-product detail
- ✅ **Be comprehensive on scenarios** - 1,500-2,000 words with specific Bull/Base/Bear parameters
- ✅ **Insert ALL charts from Task 4** - Not just a few, ALL 25-35 charts throughout
- ✅ **Create ALL tables from Task 2/3** - Extract every financial table, don't skip any
- ✅ **Use Task 1 content verbatim** - Copy/paste full Company 101 sections (6-8K words)
- ✅ **Professional quality only** - This must be indistinguishable from JPMorgan/Goldman Sachs research

**NEVER:**
- ❌ "This section would include..." - WRITE THE ACTUAL SECTION
- ❌ "Charts would be inserted here..." - INSERT THE ACTUAL CHARTS
- ❌ "See financial model for details..." - EXTRACT AND INCLUDE THE DETAILS
- ❌ Skip sections due to length - Every section MUST be complete
- ❌ Abbreviate for token conservation - Use whatever tokens are needed

**This is publication-ready institutional research. Spare no effort, tokens, or detail.**

**Output**: Comprehensive Equity Research Report (.docx)

**Specifications**:
- **Length**: 30-50 pages (MINIMUM 30)
- **Word count**: 10,000-15,000 words (MINIMUM 10,000)
- **Charts**: 25-35 embedded images
- **Tables**: 12-20 comprehensive tables
- **Format**: Professional DOCX with clickable hyperlinks

**Structure**:
- Page 1: Investment Summary (INITIATING COVERAGE format)
- Pages 2-5: Investment thesis & risks
- Pages 6-17: Company 101
- Pages 18-30: Financial analysis & projections
- Pages 31-40: Valuation analysis
- Pages 41-50: Appendices

**File name**: `[Company]_Initiation_Report_[Date].docx`

**⚠️ DELIVER ONLY THIS 1 DOCX FILE. NO executive summaries, no "highlights" documents, no extra files.**

**Final Verification**:
- [ ] Report is 30-50 pages
- [ ] Word count is 10,000-15,000
- [ ] 25-35 charts embedded
- [ ] 12-20 tables included
- [ ] All citations are clickable hyperlinks
- [ ] Numbers match financial model exactly

---

## Input Verification Protocol

### Why Input Verification Matters

Each task has strict prerequisites. Running a task without required inputs will:
- Waste time with incomplete work
- Produce low-quality outputs
- Require rework

**Always verify inputs before starting a task.**

### Verification Checklist by Task

**Task 1**: ✅ No verification needed (independent)

**Task 2**: Check historical financials available

**Task 3**: Check financial model exists and is accessible

**Task 4**: Check both model (Task 2) AND valuation (Task 3) exist

**Task 5**: Check ALL previous tasks complete (1, 2, 3, 4)

### What to Do if Verification Fails

```
IF prerequisites are missing:
1. Stop the current task
2. Identify which prerequisite task(s) need to be completed
3. Execute the missing task(s) first
4. Return to current task once prerequisites are met
```

### Example Verification Dialogue

```
User: "Use initiating-coverage, Task 5 for Tesla"

Claude: "Starting Task 5: Report Assembly for Tesla

VERIFICATION - Checking prerequisites:
- Task 1 (Company research)... ❌ NOT FOUND
- Task 2 (Financial model)... ❌ NOT FOUND
- Task 3 (Valuation)... ❌ NOT FOUND
- Task 4 (Charts)... ❌ NOT FOUND

⚠️ VERIFICATION FAILED

Task 5 requires ALL previous tasks to be complete.

To proceed:
1. Complete Task 1: Company Research
2. Complete Task 2: Financial Modeling
3. Complete Task 3: Valuation Analysis
4. Complete Task 4: Chart Generation
5. Then return to Task 5

Would you like to start with Task 1 first?"
```

---

## Task Reference Files

Detailed instructions for each task are in separate reference files to keep this skill lean:

- **references/task1-company-research.md** - Company research workflow
- **references/task2-financial-modeling.md** - Financial modeling workflow
- **references/task3-valuation.md** - Valuation methodology
  - Also see: references/valuation-methodologies.md for DCF/comps deep dive
- **references/task4-chart-generation.md** - Chart generation workflow
- **references/task5-report-assembly.md** - Report writing workflow
  - Also see: assets/report-template.md for report structure
  - Also see: assets/quality-checklist.md for quality checks

**When to load reference files**: Load ONLY the reference file associated with the specific task being performed. These files are very large - do not load multiple reference files at once. Read the appropriate task reference file at the start of the task for detailed step-by-step instructions.

---

## Quality Standards

All outputs meet institutional standards from leading investment banks (JPMorgan, Goldman Sachs, Morgan Stanley):

- **Comprehensive**: Meet all minimum requirements
- **Detailed**: Specific data and examples, not generic statements
- **Quantified**: Lead with numbers and metrics
- **Cited**: Proper sources with clickable hyperlinks
- **Professional**: Institutional-quality formatting
- **Accurate**: All numbers verified and cross-checked

---

## Important Notes

### Task Independence

- **Task 1** can run anytime (no dependencies)
- **Task 2** can run anytime (just needs historical data)
- **Tasks 1 & 2** can run in parallel
- **Task 3** requires Task 2
- **Task 4** requires Tasks 2 & 3
- **Task 5** requires Tasks 1, 2, 3, & 4

### Session Management

**Same session**: Outputs automatically available to subsequent tasks

**Different sessions**: Reference previous task outputs explicitly
```
"Use Task 3 with the model from yesterday at [path]"
"Use Task 5 with the research document at [path]"
```

### File Organization

Recommended structure during workflow:
```
ProjectFolder/
├── Task1_Research/
│   └── [Company]_Research_Document.md
├── Task2_Model/
│   └── [Company]_Financial_Model.xlsx
├── Task3_Valuation/
│   └── [Company]_Valuation_Analysis.pdf
├── Task4_Charts/
│   ├── chart_01.png
│   └── ... (25-35 files)
└── Task5_Report/
    └── [Company]_Initiation_Report.docx
```

### No End-to-End Execution

This skill does **NOT** support running all tasks automatically in sequence. Each task must be explicitly requested and verified.

**Why**: This ensures:
- Quality control at each stage
- Ability to review outputs before proceeding
- Flexibility to pause/resume workflow
- Clear verification of prerequisites

---

## Success Criteria

A successful initiation report workflow should:
1. Complete all 5 tasks in order
2. Pass all input verifications
3. Meet all quality standards
4. Produce all required deliverables
5. Numbers cross-check between outputs
6. Final report is publication-ready

**Output quality**: Institutional (JPMorgan/Goldman/Morgan Stanley level)
**Use case**: First-time comprehensive coverage of a company$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/model-update', 'finance', 'model-update', '', 'model-update', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Model Update

## Workflow

### Step 1: Identify What Changed

Determine the update trigger:
- **Earnings release**: New quarterly actuals to plug in
- **Guidance change**: Company updated forward outlook
- **Estimate revision**: Analyst changing assumptions based on new data
- **Macro update**: Interest rates, FX, commodity prices changed
- **Event-driven**: M&A, restructuring, new product, management change

### Step 2: Plug New Data

#### After Earnings
Update the model with reported actuals:

| Line Item | Prior Estimate | Actual | Delta | Notes |
|-----------|---------------|--------|-------|-------|
| Revenue | | | | |
| Gross Margin | | | | |
| Operating Expenses | | | | |
| EBITDA | | | | |
| EPS | | | | |
| [Key metric 1] | | | | |
| [Key metric 2] | | | | |

**Segment Detail** (if applicable):
- Update each segment's revenue and margin
- Note any segment mix shifts

**Balance Sheet / Cash Flow Updates**:
- Cash and debt balances
- Share count (buybacks, dilution)
- Capex actual vs. estimate
- Working capital changes

### Step 3: Revise Forward Estimates

Based on the new data, adjust forward estimates:

| | Old FY Est | New FY Est | Change | Old Next FY | New Next FY | Change |
|---|-----------|-----------|--------|------------|------------|--------|
| Revenue | | | | | | |
| EBITDA | | | | | | |
| EPS | | | | | | |

**Key Assumption Changes:**
- What assumptions are you changing and why?
- Revenue growth rate: old → new (reason)
- Margin assumption: old → new (reason)
- Any new items (restructuring charges, one-time gains, etc.)

### Step 4: Valuation Impact

Recalculate valuation with updated estimates:

| Valuation Method | Prior | Updated | Change |
|-----------------|-------|---------|--------|
| DCF fair value | | | |
| P/E (NTM EPS × target multiple) | | | |
| EV/EBITDA (NTM EBITDA × target multiple) | | | |
| **Price Target** | | | |

### Step 5: Summary & Action

**Estimate Change Summary:**
- One paragraph: what changed, why, and what it means for the stock
- Is this a thesis-changing event or noise?

**Rating / Price Target:**
- Maintain or change rating?
- New price target (if changed) with methodology
- Upside/downside to current price

### Step 6: Output

- Updated Excel model (if user provides the existing model)
- Estimate change summary (markdown or Word)
- Updated price target derivation

## Important Notes

- Always reconcile your estimates to the company's reported figures before projecting forward
- Note any non-recurring items and whether your estimates are GAAP or adjusted
- Track your estimate revision history — it shows your analytical progression
- If the quarter was noisy, separate signal from noise in your estimate changes
- Check consensus after updating — how do your revised estimates compare to the Street?
- Share count matters — dilution from stock comp, converts, or buybacks can materially affect EPS$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/morning-note', 'finance', 'morning-note', '', 'morning-note', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Morning Note

## Workflow

### Step 1: Overnight Developments

Scan for relevant events across coverage universe:

**Earnings & Guidance**
- Any coverage companies reporting overnight or pre-market?
- Earnings surprises (beat/miss on revenue, EPS, key metrics)
- Guidance changes (raised, lowered, maintained)

**News & Events**
- M&A announcements or rumors
- Management changes
- Product launches or regulatory decisions
- Analyst upgrades/downgrades from competitors
- Macro data or policy changes affecting the sector

**Market Context**
- Overnight futures / pre-market moves
- Sector ETF performance
- Relevant commodity or currency moves
- Key economic data releases today

### Step 2: Morning Note Format

Keep it tight — a morning note should be readable in 2 minutes:

---

**[Date] Morning Note — [Analyst Name]**
**[Sector Coverage]**

**Top Call: [Headline — the one thing PMs need to hear]**
- 2-3 sentences on the key development and why it matters
- Stock impact: price target, rating reiteration/change

**Overnight/Pre-Market Developments**
- [Company A]: One-line summary of earnings/news + our take
- [Company B]: One-line summary + our take
- [Sector/Macro]: Relevant sector-wide development

**Key Events Today**
- [Time]: [Company] earnings call
- [Time]: Economic data release (expectations vs. our view)
- [Time]: Conference or investor day

**Trade Ideas** (if any)
- [Long/Short] [Company]: 1-2 sentence thesis + catalyst
- Risk: What would make this wrong

---

### Step 3: Quick Takes on Earnings

If a coverage company reported, provide a quick reaction:

| Metric | Consensus | Actual | Beat/Miss |
|--------|-----------|--------|-----------|
| Revenue | | | |
| EPS | | | |
| [Key metric] | | | |
| Guidance | | | |

**Our Take**: 2-3 sentences — is this good or bad for the stock? Does it change our thesis?

**Action**: Maintain / Upgrade / Downgrade rating? Adjust price target?

### Step 4: Output

- Markdown text for email/Slack distribution
- Word document if formal distribution is needed
- Keep to 1 page max — PMs and traders won't read more

## Important Notes

- Be opinionated — morning notes that just summarize news without a view are useless
- Lead with the most important thing — don't bury the headline
- "No news" is a valid morning note — say "nothing material overnight, maintaining positioning"
- Distinguish between actionable events (earnings, M&A) and noise (minor analyst notes, non-events)
- Time-stamp your takes — if you're writing at 6am, note that pre-market may change by open
- If you're wrong, own it in the next morning note — credibility matters more than being right every time$body$),
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/sector-overview', 'finance', 'sector-overview', '', 'sector-overview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Sector Overview

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
('marketplace:financial-services/financial-services/plugins/vertical-plugins/equity-research/skills/thesis-tracker', 'finance', 'thesis-tracker', '', 'thesis-tracker', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Thesis Tracker

## Workflow

### Step 1: Define or Load Thesis

If creating a new thesis:
- **Company**: Name and ticker
- **Position**: Long or Short
- **Thesis statement**: 1-2 sentence core thesis (e.g., "Long ACME — margin expansion from pricing power + operating leverage as mix shifts to software")
- **Key pillars**: 3-5 supporting arguments
- **Key risks**: 3-5 risks that would invalidate the thesis
- **Catalysts**: Upcoming events that could prove/disprove the thesis (earnings, product launches, regulatory decisions)
- **Target price / valuation**: What's it worth if the thesis plays out
- **Stop-loss trigger**: What would make you exit

If updating an existing thesis, ask the user for the new data point or development.

### Step 2: Update Log

For each new data point or development:

- **Date**: When this happened
- **Data point**: What changed (earnings beat, management departure, competitor move, etc.)
- **Thesis impact**: Does this strengthen, weaken, or neutralize a specific pillar?
- **Action**: No change / Increase position / Trim / Exit
- **Updated conviction**: High / Medium / Low

### Step 3: Thesis Scorecard

Maintain a running scorecard:

| Pillar | Original Expectation | Current Status | Trend |
|--------|---------------------|----------------|-------|
| Revenue growth >20% | On track | Q3 was 22% | Stable |
| Margin expansion | Behind | Margins flat YoY | Concerning |
| New product launch | Pending | Delayed to Q2 | Watch |

### Step 4: Catalyst Calendar

Track upcoming catalysts:

| Date | Event | Expected Impact | Notes |
|------|-------|-----------------|-------|
| | | | |

### Step 5: Output

Thesis summary suitable for:
- Morning meeting discussion
- Portfolio review
- Risk committee presentation

Format: Concise markdown or Word doc with the scorecard, recent updates, and current conviction level.

## Important Notes

- A thesis should be falsifiable — if nothing could disprove it, it's not a thesis
- Track disconfirming evidence as rigorously as confirming evidence
- Review theses at least quarterly, even when nothing dramatic has happened
- If the user manages multiple positions, offer to do a full portfolio thesis review
- Store thesis data in a structured format so it can be referenced across sessions$body$)
ON CONFLICT (skill_key) DO NOTHING;
