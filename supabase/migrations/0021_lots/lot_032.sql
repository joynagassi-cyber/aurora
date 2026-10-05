INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/create-viz', 'business', 'create-viz', '', 'create-viz', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /create-viz - Create Visualizations

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Create publication-quality data visualizations using Python. Generates charts from data with best practices for clarity, accuracy, and design.

## Usage

```
/create-viz <data source> [chart type] [additional instructions]
```

## Workflow

### 1. Understand the Request

Determine:

- **Data source**: Query results, pasted data, CSV/Excel file, or data to be queried
- **Chart type**: Explicitly requested or needs to be recommended
- **Purpose**: Exploration, presentation, report, dashboard component
- **Audience**: Technical team, executives, external stakeholders

### 2. Get the Data

**If data warehouse is connected and data needs querying:**
1. Write and execute the query
2. Load results into a pandas DataFrame

**If data is pasted or uploaded:**
1. Parse the data into a pandas DataFrame
2. Clean and prepare as needed (type conversions, null handling)

**If data is from a previous analysis in the conversation:**
1. Reference the existing data

### 3. Select Chart Type

If the user didn't specify a chart type, recommend one based on the data and question:

| Data Relationship | Recommended Chart |
|---|---|
| Trend over time | Line chart |
| Comparison across categories | Bar chart (horizontal if many categories) |
| Part-to-whole composition | Stacked bar or area chart (avoid pie charts unless <6 categories) |
| Distribution of values | Histogram or box plot |
| Correlation between two variables | Scatter plot |
| Two-variable comparison over time | Dual-axis line or grouped bar |
| Geographic data | Choropleth map |
| Ranking | Horizontal bar chart |
| Flow or process | Sankey diagram |
| Matrix of relationships | Heatmap |

Explain the recommendation briefly if the user didn't specify.

### 4. Generate the Visualization

Write Python code using one of these libraries based on the need:

- **matplotlib + seaborn**: Best for static, publication-quality charts. Default choice.
- **plotly**: Best for interactive charts or when the user requests interactivity.

**Code requirements:**

```python
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

# Set professional style
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

# Create figure with appropriate size
fig, ax = plt.subplots(figsize=(10, 6))

# [chart-specific code]

# Always include:
ax.set_title('Clear, Descriptive Title', fontsize=14, fontweight='bold')
ax.set_xlabel('X-Axis Label', fontsize=11)
ax.set_ylabel('Y-Axis Label', fontsize=11)

# Format numbers appropriately
# - Percentages: '45.2%' not '0.452'
# - Currency: '$1.2M' not '1200000'
# - Large numbers: '2.3K' or '1.5M' not '2300' or '1500000'

# Remove chart junk
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('chart_name.png', dpi=150, bbox_inches='tight')
plt.show()
```

### 5. Apply Design Best Practices

**Color:**
- Use a consistent, colorblind-friendly palette
- Use color meaningfully (not decoratively)
- Highlight the key data point or trend with a contrasting color
- Grey out less important reference data

**Typography:**
- Descriptive title that states the insight, not just the metric (e.g., "Revenue grew 23% YoY" not "Revenue by Month")
- Readable axis labels (not rotated 90 degrees if avoidable)
- Data labels on key points when they add clarity

**Layout:**
- Appropriate whitespace and margins
- Legend placement that doesn't obscure data
- Sorted categories by value (not alphabetically) unless there's a natural order

**Accuracy:**
- Y-axis starts at zero for bar charts
- No misleading axis breaks without clear notation
- Consistent scales when comparing panels
- Appropriate precision (don't show 10 decimal places)

### 6. Save and Present

1. Save the chart as a PNG file with descriptive name
2. Display the chart to the user
3. Provide the code used so they can modify it
4. Suggest variations (different chart type, different grouping, zoomed time range)

## Examples

```
/create-viz Show monthly revenue for the last 12 months as a line chart with the trend highlighted
```

```
/create-viz Here's our NPS data by product: [pastes data]. Create a horizontal bar chart ranking products by score.
```

```
/create-viz Query the orders table and create a heatmap of order volume by day-of-week and hour
```

## Tips

- If you want interactive charts (hover, zoom, filter), mention "interactive" and Claude will use plotly
- Specify "presentation" if you need larger fonts and higher contrast
- You can request multiple charts at once (e.g., "create a 2x2 grid of charts showing...")
- Charts are saved to your current directory as PNG files$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/data-context-extractor', 'business', 'data-context-extractor', '', 'data-context-extractor', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Data Context Extractor

A meta-skill that extracts company-specific data knowledge from analysts and generates tailored data analysis skills.

## How It Works

This skill has two modes:

1. **Bootstrap Mode**: Create a new data analysis skill from scratch
2. **Iteration Mode**: Improve an existing skill by adding domain-specific reference files

---

## Bootstrap Mode

Use when: User wants to create a new data context skill for their warehouse.

### Phase 1: Database Connection & Discovery

**Step 1: Identify the database type**

Ask: "What data warehouse are you using?"

Common options:
- **BigQuery**
- **Snowflake**
- **PostgreSQL/Redshift**
- **Databricks**

Use `~~data warehouse` tools (query and schema) to connect. If unclear, check available MCP tools in the current session.

**Step 2: Explore the schema**

Use `~~data warehouse` schema tools to:
1. List available datasets/schemas
2. Identify the most important tables (ask user: "Which 3-5 tables do analysts query most often?")
3. Pull schema details for those key tables

Sample exploration queries by dialect:
```sql
-- BigQuery: List datasets
SELECT schema_name FROM INFORMATION_SCHEMA.SCHEMATA

-- BigQuery: List tables in a dataset
SELECT table_name FROM `project.dataset.INFORMATION_SCHEMA.TABLES`

-- Snowflake: List schemas
SHOW SCHEMAS IN DATABASE my_database

-- Snowflake: List tables
SHOW TABLES IN SCHEMA my_schema
```

### Phase 2: Core Questions (Ask These)

After schema discovery, ask these questions conversationally (not all at once):

**Entity Disambiguation (Critical)**
> "When people here say 'user' or 'customer', what exactly do they mean? Are there different types?"

Listen for:
- Multiple entity types (user vs account vs organization)
- Relationships between them (1:1, 1:many, many:many)
- Which ID fields link them together

**Primary Identifiers**
> "What's the main identifier for a [customer/user/account]? Are there multiple IDs for the same entity?"

Listen for:
- Primary keys vs business keys
- UUID vs integer IDs
- Legacy ID systems

**Key Metrics**
> "What are the 2-3 metrics people ask about most? How is each one calculated?"

Listen for:
- Exact formulas (ARR = monthly_revenue × 12)
- Which tables/columns feed each metric
- Time period conventions (trailing 7 days, calendar month, etc.)

**Data Hygiene**
> "What should ALWAYS be filtered out of queries? (test data, fraud, internal users, etc.)"

Listen for:
- Standard WHERE clauses to always include
- Flag columns that indicate exclusions (is_test, is_internal, is_fraud)
- Specific values to exclude (status = 'deleted')

**Common Gotchas**
> "What mistakes do new analysts typically make with this data?"

Listen for:
- Confusing column names
- Timezone issues
- NULL handling quirks
- Historical vs current state tables

### Phase 3: Generate the Skill

Create a skill with this structure:

```
[company]-data-analyst/
├── SKILL.md
└── references/
    ├── entities.md          # Entity definitions and relationships
    ├── metrics.md           # KPI calculations
    ├── tables/              # One file per domain
    │   ├── [domain1].md
    │   └── [domain2].md
    └── dashboards.json      # Optional: existing dashboards catalog
```

**SKILL.md Template**: See `references/skill-template.md`

**SQL Dialect Section**: See `references/sql-dialects.md` and include the appropriate dialect notes.

**Reference File Template**: See `references/domain-template.md`

### Phase 4: Package and Deliver

1. Create all files in the skill directory
2. Package as a zip file
3. Present to user with summary of what was captured

---

## Iteration Mode

Use when: User has an existing skill but needs to add more context.

### Step 1: Load Existing Skill

Ask user to upload their existing skill (zip or folder), or locate it if already in the session.

Read the current SKILL.md and reference files to understand what's already documented.

### Step 2: Identify the Gap

Ask: "What domain or topic needs more context? What queries are failing or producing wrong results?"

Common gaps:
- A new data domain (marketing, finance, product, etc.)
- Missing metric definitions
- Undocumented table relationships
- New terminology

### Step 3: Targeted Discovery

For the identified domain:

1. **Explore relevant tables**: Use `~~data warehouse` schema tools to find tables in that domain
2. **Ask domain-specific questions**:
   - "What tables are used for [domain] analysis?"
   - "What are the key metrics for [domain]?"
   - "Any special filters or gotchas for [domain] data?"

3. **Generate new reference file**: Create `references/[domain].md` using the domain template

### Step 4: Update and Repackage

1. Add the new reference file
2. Update SKILL.md's "Knowledge Base Navigation" section to include the new domain
3. Repackage the skill
4. Present the updated skill to user

---

## Reference File Standards

Each reference file should include:

### For Table Documentation
- **Location**: Full table path
- **Description**: What this table contains, when to use it
- **Primary Key**: How to uniquely identify rows
- **Update Frequency**: How often data refreshes
- **Key Columns**: Table with column name, type, description, notes
- **Relationships**: How this table joins to others
- **Sample Queries**: 2-3 common query patterns

### For Metrics Documentation
- **Metric Name**: Human-readable name
- **Definition**: Plain English explanation
- **Formula**: Exact calculation with column references
- **Source Table(s)**: Where the data comes from
- **Caveats**: Edge cases, exclusions, gotchas

### For Entity Documentation
- **Entity Name**: What it's called
- **Definition**: What it represents in the business
- **Primary Table**: Where to find this entity
- **ID Field(s)**: How to identify it
- **Relationships**: How it relates to other entities
- **Common Filters**: Standard exclusions (internal, test, etc.)

---

## Quality Checklist

Before delivering a generated skill, verify:

- [ ] SKILL.md has complete frontmatter (name, description)
- [ ] Entity disambiguation section is clear
- [ ] Key terminology is defined
- [ ] Standard filters/exclusions are documented
- [ ] At least 2-3 sample queries per domain
- [ ] SQL uses correct dialect syntax
- [ ] Reference files are linked from SKILL.md navigation section$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/data-visualization', 'business', 'data-visualization', '', 'data-visualization', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Data Visualization Skill

Chart selection guidance, Python visualization code patterns, design principles, and accessibility considerations for creating effective data visualizations.

## Chart Selection Guide

### Choose by Data Relationship

| What You're Showing | Best Chart | Alternatives |
|---|---|---|
| **Trend over time** | Line chart | Area chart (if showing cumulative or composition) |
| **Comparison across categories** | Vertical bar chart | Horizontal bar (many categories), lollipop chart |
| **Ranking** | Horizontal bar chart | Dot plot, slope chart (comparing two periods) |
| **Part-to-whole composition** | Stacked bar chart | Treemap (hierarchical), waffle chart |
| **Composition over time** | Stacked area chart | 100% stacked bar (for proportion focus) |
| **Distribution** | Histogram | Box plot (comparing groups), violin plot, strip plot |
| **Correlation (2 variables)** | Scatter plot | Bubble chart (add 3rd variable as size) |
| **Correlation (many variables)** | Heatmap (correlation matrix) | Pair plot |
| **Geographic patterns** | Choropleth map | Bubble map, hex map |
| **Flow / process** | Sankey diagram | Funnel chart (sequential stages) |
| **Relationship network** | Network graph | Chord diagram |
| **Performance vs. target** | Bullet chart | Gauge (single KPI only) |
| **Multiple KPIs at once** | Small multiples | Dashboard with separate charts |

### When NOT to Use Certain Charts

- **Pie charts**: Avoid unless <6 categories and exact proportions matter less than rough comparison. Humans are bad at comparing angles. Use bar charts instead.
- **3D charts**: Never. They distort perception and add no information.
- **Dual-axis charts**: Use cautiously. They can mislead by implying correlation. Clearly label both axes if used.
- **Stacked bar (many categories)**: Hard to compare middle segments. Use small multiples or grouped bars instead.
- **Donut charts**: Slightly better than pie charts but same fundamental issues. Use for single KPI display at most.

## Python Visualization Code Patterns

### Setup and Style

```python
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import pandas as pd
import numpy as np

# Professional style setup
plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams.update({
    'figure.figsize': (10, 6),
    'figure.dpi': 150,
    'font.size': 11,
    'axes.titlesize': 14,
    'axes.titleweight': 'bold',
    'axes.labelsize': 11,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.titlesize': 16,
})

# Colorblind-friendly palettes
PALETTE_CATEGORICAL = ['#4C72B0', '#DD8452', '#55A868', '#C44E52', '#8172B3', '#937860']
PALETTE_SEQUENTIAL = 'YlOrRd'
PALETTE_DIVERGING = 'RdBu_r'
```

### Line Chart (Time Series)

```python
fig, ax = plt.subplots(figsize=(10, 6))

for label, group in df.groupby('category'):
    ax.plot(group['date'], group['value'], label=label, linewidth=2)

ax.set_title('Metric Trend by Category', fontweight='bold')
ax.set_xlabel('Date')
ax.set_ylabel('Value')
ax.legend(loc='upper left', frameon=True)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Format dates on x-axis
fig.autofmt_xdate()

plt.tight_layout()
plt.savefig('trend_chart.png', dpi=150, bbox_inches='tight')
```

### Bar Chart (Comparison)

```python
fig, ax = plt.subplots(figsize=(10, 6))

# Sort by value for easy reading
df_sorted = df.sort_values('metric', ascending=True)

bars = ax.barh(df_sorted['category'], df_sorted['metric'], color=PALETTE_CATEGORICAL[0])

# Add value labels
for bar in bars:
    width = bar.get_width()
    ax.text(width + 0.5, bar.get_y() + bar.get_height()/2,
            f'{width:,.0f}', ha='left', va='center', fontsize=10)

ax.set_title('Metric by Category (Ranked)', fontweight='bold')
ax.set_xlabel('Metric Value')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('bar_chart.png', dpi=150, bbox_inches='tight')
```

### Histogram (Distribution)

```python
fig, ax = plt.subplots(figsize=(10, 6))

ax.hist(df['value'], bins=30, color=PALETTE_CATEGORICAL[0], edgecolor='white', alpha=0.8)

# Add mean and median lines
mean_val = df['value'].mean()
median_val = df['value'].median()
ax.axvline(mean_val, color='red', linestyle='--', linewidth=1.5, label=f'Mean: {mean_val:,.1f}')
ax.axvline(median_val, color='green', linestyle='--', linewidth=1.5, label=f'Median: {median_val:,.1f}')

ax.set_title('Distribution of Values', fontweight='bold')
ax.set_xlabel('Value')
ax.set_ylabel('Frequency')
ax.legend()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('histogram.png', dpi=150, bbox_inches='tight')
```

### Heatmap

```python
fig, ax = plt.subplots(figsize=(10, 8))

# Pivot data for heatmap format
pivot = df.pivot_table(index='row_dim', columns='col_dim', values='metric', aggfunc='sum')

sns.heatmap(pivot, annot=True, fmt=',.0f', cmap='YlOrRd',
            linewidths=0.5, ax=ax, cbar_kws={'label': 'Metric Value'})

ax.set_title('Metric by Row Dimension and Column Dimension', fontweight='bold')
ax.set_xlabel('Column Dimension')
ax.set_ylabel('Row Dimension')

plt.tight_layout()
plt.savefig('heatmap.png', dpi=150, bbox_inches='tight')
```

### Small Multiples

```python
categories = df['category'].unique()
n_cats = len(categories)
n_cols = min(3, n_cats)
n_rows = (n_cats + n_cols - 1) // n_cols

fig, axes = plt.subplots(n_rows, n_cols, figsize=(5*n_cols, 4*n_rows), sharex=True, sharey=True)
axes = axes.flatten() if n_cats > 1 else [axes]

for i, cat in enumerate(categories):
    ax = axes[i]
    subset = df[df['category'] == cat]
    ax.plot(subset['date'], subset['value'], color=PALETTE_CATEGORICAL[i % len(PALETTE_CATEGORICAL)])
    ax.set_title(cat, fontsize=12)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

# Hide empty subplots
for j in range(i+1, len(axes)):
    axes[j].set_visible(False)

fig.suptitle('Trends by Category', fontsize=14, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig('small_multiples.png', dpi=150, bbox_inches='tight')
```

### Number Formatting Helpers

```python
def format_number(val, format_type='number'):
    """Format numbers for chart labels."""
    if format_type == 'currency':
        if abs(val) >= 1e9:
            return f'${val/1e9:.1f}B'
        elif abs(val) >= 1e6:
            return f'${val/1e6:.1f}M'
        elif abs(val) >= 1e3:
            return f'${val/1e3:.1f}K'
        else:
            return f'${val:,.0f}'
    elif format_type == 'percent':
        return f'{val:.1f}%'
    elif format_type == 'number':
        if abs(val) >= 1e9:
            return f'{val/1e9:.1f}B'
        elif abs(val) >= 1e6:
            return f'{val/1e6:.1f}M'
        elif abs(val) >= 1e3:
            return f'{val/1e3:.1f}K'
        else:
            return f'{val:,.0f}'
    return str(val)

# Usage with axis formatter
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, p: format_number(x, 'currency')))
```

### Interactive Charts with Plotly

```python
import plotly.express as px
import plotly.graph_objects as go

# Simple interactive line chart
fig = px.line(df, x='date', y='value', color='category',
              title='Interactive Metric Trend',
              labels={'value': 'Metric Value', 'date': 'Date'})
fig.update_layout(hovermode='x unified')
fig.write_html('interactive_chart.html')
fig.show()

# Interactive scatter with hover data
fig = px.scatter(df, x='metric_a', y='metric_b', color='category',
                 size='size_metric', hover_data=['name', 'detail_field'],
                 title='Correlation Analysis')
fig.show()
```

## Design Principles

### Color

- **Use color purposefully**: Color should encode data, not decorate
- **Highlight the story**: Use a bright accent color for the key insight; grey everything else
- **Sequential data**: Use a single-hue gradient (light to dark) for ordered values
- **Diverging data**: Use a two-hue gradient with neutral midpoint for data with a meaningful center
- **Categorical data**: Use distinct hues, maximum 6-8 before it gets confusing
- **Avoid red/green only**: 8% of men are red-green colorblind. Use blue/orange as primary pair

### Typography

- **Title states the insight**: "Revenue grew 23% YoY" beats "Revenue by Month"
- **Subtitle adds context**: Date range, filters applied, data source
- **Axis labels are readable**: Never rotated 90 degrees if avoidable. Shorten or wrap instead
- **Data labels add precision**: Use on key points, not every single bar
- **Annotation highlights**: Call out specific points with text annotations

### Layout

- **Reduce chart junk**: Remove gridlines, borders, backgrounds that don't carry information
- **Sort meaningfully**: Categories sorted by value (not alphabetically) unless there's a natural order (months, stages)
- **Appropriate aspect ratio**: Time series wider than tall (3:1 to 2:1); comparisons can be squarer
- **White space is good**: Don't cram charts together. Give each visualization room to breathe

### Accuracy

- **Bar charts start at zero**: Always. A bar from 95 to 100 exaggerates a 5% difference
- **Line charts can have non-zero baselines**: When the range of variation is meaningful
- **Consistent scales across panels**: When comparing multiple charts, use the same axis range
- **Show uncertainty**: Error bars, confidence intervals, or ranges when data is uncertain
- **Label your axes**: Never make the reader guess what the numbers mean

## Accessibility Considerations

### Color Blindness

- Never rely on color alone to distinguish data series
- Add pattern fills, different line styles (solid, dashed, dotted), or direct labels
- Test with a colorblind simulator (e.g., Coblis, Sim Daltonism)
- Use the colorblind-friendly palette: `sns.color_palette("colorblind")`

### Screen Readers

- Include alt text describing the chart's key finding
- Provide a data table alternative alongside the visualization
- Use semantic titles and labels

### General Accessibility

- Sufficient contrast between data elements and background
- Text size minimum 10pt for labels, 12pt for titles
- Avoid conveying information only through spatial position (add labels)
- Consider printing: does the chart work in black and white?

### Accessibility Checklist

Before sharing a visualization:
- [ ] Chart works without color (patterns, labels, or line styles differentiate series)
- [ ] Text is readable at standard zoom level
- [ ] Title describes the insight, not just the data
- [ ] Axes are labeled with units
- [ ] Legend is clear and positioned without obscuring data
- [ ] Data source and date range are noted$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/explore-data', 'business', 'explore-data', '', 'explore-data', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /explore-data - Profile and Explore a Dataset

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Generate a comprehensive data profile for a table or uploaded file. Understand its shape, quality, and patterns before diving into analysis.

## Usage

```
/explore-data <table_name or file>
```

## Workflow

### 1. Access the Data

**If a data warehouse MCP server is connected:**

1. Resolve the table name (handle schema prefixes, suggest matches if ambiguous)
2. Query table metadata: column names, types, descriptions if available
3. Run profiling queries against the live data

**If a file is provided (CSV, Excel, Parquet, JSON):**

1. Read the file and load into a working dataset
2. Infer column types from the data

**If neither:**

1. Ask the user to provide a table name (with their warehouse connected) or upload a file
2. If they describe a table schema, provide guidance on what profiling queries to run

### 2. Understand Structure

Before analyzing any data, understand its structure:

**Table-level questions:**
- How many rows and columns?
- What is the grain (one row per what)?
- What is the primary key? Is it unique?
- When was the data last updated?
- How far back does the data go?

**Column classification** — categorize each column as one of:
- **Identifier**: Unique keys, foreign keys, entity IDs
- **Dimension**: Categorical attributes for grouping/filtering (status, type, region, category)
- **Metric**: Quantitative values for measurement (revenue, count, duration, score)
- **Temporal**: Dates and timestamps (created_at, updated_at, event_date)
- **Text**: Free-form text fields (description, notes, name)
- **Boolean**: True/false flags
- **Structural**: JSON, arrays, nested structures

### 3. Generate Data Profile

Run the following profiling checks:

**Table-level metrics:**
- Total row count
- Column count and types breakdown
- Approximate table size (if available from metadata)
- Date range coverage (min/max of date columns)

**All columns:**
- Null count and null rate
- Distinct count and cardinality ratio (distinct / total)
- Most common values (top 5-10 with frequencies)
- Least common values (bottom 5 to spot anomalies)

**Numeric columns (metrics):**
```
min, max, mean, median (p50)
standard deviation
percentiles: p1, p5, p25, p75, p95, p99
zero count
negative count (if unexpected)
```

**String columns (dimensions, text):**
```
min length, max length, avg length
empty string count
pattern analysis (do values follow a format?)
case consistency (all upper, all lower, mixed?)
leading/trailing whitespace count
```

**Date/timestamp columns:**
```
min date, max date
null dates
future dates (if unexpected)
distribution by month/week
gaps in time series
```

**Boolean columns:**
```
true count, false count, null count
true rate
```

**Present the profile as a clean summary table**, grouped by column type (dimensions, metrics, dates, IDs).

### 4. Identify Data Quality Issues

Apply the quality assessment framework below. Flag potential problems:

- **High null rates**: Columns with >5% nulls (warn), >20% nulls (alert)
- **Low cardinality surprises**: Columns that should be high-cardinality but aren't (e.g., a "user_id" with only 50 distinct values)
- **High cardinality surprises**: Columns that should be categorical but have too many distinct values
- **Suspicious values**: Negative amounts where only positive expected, future dates in historical data, obviously placeholder values (e.g., "N/A", "TBD", "test", "999999")
- **Duplicate detection**: Check if there's a natural key and whether it has duplicates
- **Distribution skew**: Extremely skewed numeric distributions that could affect averages
- **Encoding issues**: Mixed case in categorical fields, trailing whitespace, inconsistent formats

### 5. Discover Relationships and Patterns

After profiling individual columns:

- **Foreign key candidates**: ID columns that might link to other tables
- **Hierarchies**: Columns that form natural drill-down paths (country > state > city)
- **Correlations**: Numeric columns that move together
- **Derived columns**: Columns that appear to be computed from others
- **Redundant columns**: Columns with identical or near-identical information

### 6. Suggest Interesting Dimensions and Metrics

Based on the column profile, recommend:

- **Best dimension columns** for slicing data (categorical columns with reasonable cardinality, 3-50 values)
- **Key metric columns** for measurement (numeric columns with meaningful distributions)
- **Time columns** suitable for trend analysis
- **Natural groupings** or hierarchies apparent in the data
- **Potential join keys** linking to other tables (ID columns, foreign keys)

### 7. Recommend Follow-Up Analyses

Suggest 3-5 specific analyses the user could run next:

- "Trend analysis on [metric] by [time_column] grouped by [dimension]"
- "Distribution deep-dive on [skewed_column] to understand outliers"
- "Data quality investigation on [problematic_column]"
- "Correlation analysis between [metric_a] and [metric_b]"
- "Cohort analysis using [date_column] and [status_column]"

## Output Format

```
## Data Profile: [table_name]

### Overview
- Rows: 2,340,891
- Columns: 23 (8 dimensions, 6 metrics, 4 dates, 5 IDs)
- Date range: 2021-03-15 to 2024-01-22

### Column Details
[summary table]

### Data Quality Issues
[flagged issues with severity]

### Recommended Explorations
[numbered list of suggested follow-up analyses]
```

---

## Quality Assessment Framework

### Completeness Score

Rate each column:
- **Complete** (>99% non-null): Green
- **Mostly complete** (95-99%): Yellow -- investigate the nulls
- **Incomplete** (80-95%): Orange -- understand why and whether it matters
- **Sparse** (<80%): Red -- may not be usable without imputation

### Consistency Checks

Look for:
- **Value format inconsistency**: Same concept represented differently ("USA", "US", "United States", "us")
- **Type inconsistency**: Numbers stored as strings, dates in various formats
- **Referential integrity**: Foreign keys that don't match any parent record
- **Business rule violations**: Negative quantities, end dates before start dates, percentages > 100
- **Cross-column consistency**: Status = "completed" but completed_at is null

### Accuracy Indicators

Red flags that suggest accuracy issues:
- **Placeholder values**: 0, -1, 999999, "N/A", "TBD", "test", "xxx"
- **Default values**: Suspiciously high frequency of a single value
- **Stale data**: Updated_at shows no recent changes in an active system
- **Impossible values**: Ages > 150, dates in the far future, negative durations
- **Round number bias**: All values ending in 0 or 5 (suggests estimation, not measurement)

### Timeliness Assessment

- When was the table last updated?
- What is the expected update frequency?
- Is there a lag between event time and load time?
- Are there gaps in the time series?

## Pattern Discovery Techniques

### Distribution Analysis

For numeric columns, characterize the distribution:
- **Normal**: Mean and median are close, bell-shaped
- **Skewed right**: Long tail of high values (common for revenue, session duration)
- **Skewed left**: Long tail of low values (less common)
- **Bimodal**: Two peaks (suggests two distinct populations)
- **Power law**: Few very large values, many small ones (common for user activity)
- **Uniform**: Roughly equal frequency across range (often synthetic or random)

### Temporal Patterns

For time series data, look for:
- **Trend**: Sustained upward or downward movement
- **Seasonality**: Repeating patterns (weekly, monthly, quarterly, annual)
- **Day-of-week effects**: Weekday vs. weekend differences
- **Holiday effects**: Drops or spikes around known holidays
- **Change points**: Sudden shifts in level or trend
- **Anomalies**: Individual data points that break the pattern

### Segmentation Discovery

Identify natural segments by:
- Finding categorical columns with 3-20 distinct values
- Comparing metric distributions across segment values
- Looking for segments with significantly different behavior
- Testing whether segments are homogeneous or contain sub-segments

### Correlation Exploration

Between numeric columns:
- Compute correlation matrix for all metric pairs
- Flag strong correlations (|r| > 0.7) for investigation
- Note: Correlation does not imply causation -- flag this explicitly
- Check for non-linear relationships (e.g., quadratic, logarithmic)

## Schema Understanding and Documentation

### Schema Documentation Template

When documenting a dataset for team use:

```markdown
## Table: [schema.table_name]

**Description**: [What this table represents]
**Grain**: [One row per...]
**Primary Key**: [column(s)]
**Row Count**: [approximate, with date]
**Update Frequency**: [real-time / hourly / daily / weekly]
**Owner**: [team or person responsible]

### Key Columns

| Column | Type | Description | Example Values | Notes |
|--------|------|-------------|----------------|-------|
| user_id | STRING | Unique user identifier | "usr_abc123" | FK to users.id |
| event_type | STRING | Type of event | "click", "view", "purchase" | 15 distinct values |
| revenue | DECIMAL | Transaction revenue in USD | 29.99, 149.00 | Null for non-purchase events |
| created_at | TIMESTAMP | When the event occurred | 2024-01-15 14:23:01 | Partitioned on this column |

### Relationships
- Joins to `users` on `user_id`
- Joins to `products` on `product_id`
- Parent of `event_details` (1:many on event_id)

### Known Issues
- [List any known data quality issues]
- [Note any gotchas for analysts]

### Common Query Patterns
- [Typical use cases for this table]
```

### Schema Exploration Queries

When connected to a data warehouse, use these patterns to discover schema:

```sql
-- List all tables in a schema (PostgreSQL)
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Column details (PostgreSQL)
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'my_table'
ORDER BY ordinal_position;

-- Table sizes (PostgreSQL)
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Row counts for all tables (general pattern)
-- Run per-table: SELECT COUNT(*) FROM table_name
```

### Lineage and Dependencies

When exploring an unfamiliar data environment:

1. Start with the "output" tables (what reports or dashboards consume)
2. Trace upstream: What tables feed into them?
3. Identify raw/staging/mart layers
4. Map the transformation chain from raw data to analytical tables
5. Note where data is enriched, filtered, or aggregated

## Tips

- For very large tables (100M+ rows), profiling queries use sampling by default -- mention if you need exact counts
- If exploring a new dataset for the first time, this command gives you the lay of the land before writing specific queries
- The quality flags are heuristic -- not every flag is a real problem, but each is worth a quick look$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/sql-queries', 'business', 'sql-queries', '', 'sql-queries', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# SQL Queries Skill

Write correct, performant, readable SQL across all major data warehouse dialects.

## Dialect-Specific Reference

### PostgreSQL (including Aurora, RDS, Supabase, Neon)

**Date/time:**
```sql
-- Current date/time
CURRENT_DATE, CURRENT_TIMESTAMP, NOW()

-- Date arithmetic
date_column + INTERVAL '7 days'
date_column - INTERVAL '1 month'

-- Truncate to period
DATE_TRUNC('month', created_at)

-- Extract parts
EXTRACT(YEAR FROM created_at)
EXTRACT(DOW FROM created_at)  -- 0=Sunday

-- Format
TO_CHAR(created_at, 'YYYY-MM-DD')
```

**String functions:**
```sql
-- Concatenation
first_name || ' ' || last_name
CONCAT(first_name, ' ', last_name)

-- Pattern matching
column ILIKE '%pattern%'  -- case-insensitive
column ~ '^regex_pattern$'  -- regex

-- String manipulation
LEFT(str, n), RIGHT(str, n)
SPLIT_PART(str, delimiter, position)
REGEXP_REPLACE(str, pattern, replacement)
```

**Arrays and JSON:**
```sql
-- JSON access
data->>'key'  -- text
data->'nested'->'key'  -- json
data#>>'{path,to,key}'  -- nested text

-- Array operations
ARRAY_AGG(column)
ANY(array_column)
array_column @> ARRAY['value']
```

**Performance tips:**
- Use `EXPLAIN ANALYZE` to profile queries
- Create indexes on frequently filtered/joined columns
- Use `EXISTS` over `IN` for correlated subqueries
- Partial indexes for common filter conditions
- Use connection pooling for concurrent access

---

### Snowflake

**Date/time:**
```sql
-- Current date/time
CURRENT_DATE(), CURRENT_TIMESTAMP(), SYSDATE()

-- Date arithmetic
DATEADD(day, 7, date_column)
DATEDIFF(day, start_date, end_date)

-- Truncate to period
DATE_TRUNC('month', created_at)

-- Extract parts
YEAR(created_at), MONTH(created_at), DAY(created_at)
DAYOFWEEK(created_at)

-- Format
TO_CHAR(created_at, 'YYYY-MM-DD')
```

**String functions:**
```sql
-- Case-insensitive by default (depends on collation)
column ILIKE '%pattern%'
REGEXP_LIKE(column, 'pattern')

-- Parse JSON
column:key::string  -- dot notation for VARIANT
PARSE_JSON('{"key": "value"}')
GET_PATH(variant_col, 'path.to.key')

-- Flatten arrays/objects
SELECT f.value FROM table, LATERAL FLATTEN(input => array_col) f
```

**Semi-structured data:**
```sql
-- VARIANT type access
data:customer:name::STRING
data:items[0]:price::NUMBER

-- Flatten nested structures
SELECT
    t.id,
    item.value:name::STRING as item_name,
    item.value:qty::NUMBER as quantity
FROM my_table t,
LATERAL FLATTEN(input => t.data:items) item
```

**Performance tips:**
- Use clustering keys on large tables (not traditional indexes)
- Filter on clustering key columns for partition pruning
- Set appropriate warehouse size for query complexity
- Use `RESULT_SCAN(LAST_QUERY_ID())` to avoid re-running expensive queries
- Use transient tables for staging/temp data

---

### BigQuery (Google Cloud)

**Date/time:**
```sql
-- Current date/time
CURRENT_DATE(), CURRENT_TIMESTAMP()

-- Date arithmetic
DATE_ADD(date_column, INTERVAL 7 DAY)
DATE_SUB(date_column, INTERVAL 1 MONTH)
DATE_DIFF(end_date, start_date, DAY)
TIMESTAMP_DIFF(end_ts, start_ts, HOUR)

-- Truncate to period
DATE_TRUNC(created_at, MONTH)
TIMESTAMP_TRUNC(created_at, HOUR)

-- Extract parts
EXTRACT(YEAR FROM created_at)
EXTRACT(DAYOFWEEK FROM created_at)  -- 1=Sunday

-- Format
FORMAT_DATE('%Y-%m-%d', date_column)
FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', ts_column)
```

**String functions:**
```sql
-- No ILIKE, use LOWER()
LOWER(column) LIKE '%pattern%'
REGEXP_CONTAINS(column, r'pattern')
REGEXP_EXTRACT(column, r'pattern')

-- String manipulation
SPLIT(str, delimiter)  -- returns ARRAY
ARRAY_TO_STRING(array, delimiter)
```

**Arrays and structs:**
```sql
-- Array operations
ARRAY_AGG(column)
UNNEST(array_column)
ARRAY_LENGTH(array_column)
value IN UNNEST(array_column)

-- Struct access
struct_column.field_name
```

**Performance tips:**
- Always filter on partition columns (usually date) to reduce bytes scanned
- Use clustering for frequently filtered columns within partitions
- Use `APPROX_COUNT_DISTINCT()` for large-scale cardinality estimates
- Avoid `SELECT *` -- billing is per-byte scanned
- Use `DECLARE` and `SET` for parameterized scripts
- Preview query cost with dry run before executing large queries

---

### Redshift (Amazon)

**Date/time:**
```sql
-- Current date/time
CURRENT_DATE, GETDATE(), SYSDATE

-- Date arithmetic
DATEADD(day, 7, date_column)
DATEDIFF(day, start_date, end_date)

-- Truncate to period
DATE_TRUNC('month', created_at)

-- Extract parts
EXTRACT(YEAR FROM created_at)
DATE_PART('dow', created_at)
```

**String functions:**
```sql
-- Case-insensitive
column ILIKE '%pattern%'
REGEXP_INSTR(column, 'pattern') > 0

-- String manipulation
SPLIT_PART(str, delimiter, position)
LISTAGG(column, ', ') WITHIN GROUP (ORDER BY column)
```

**Performance tips:**
- Design distribution keys for collocated joins (DISTKEY)
- Use sort keys for frequently filtered columns (SORTKEY)
- Use `EXPLAIN` to check query plan
- Avoid cross-node data movement (watch for DS_BCAST and DS_DIST)
- `ANALYZE` and `VACUUM` regularly
- Use late-binding views for schema flexibility

---

### Databricks SQL

**Date/time:**
```sql
-- Current date/time
CURRENT_DATE(), CURRENT_TIMESTAMP()

-- Date arithmetic
DATE_ADD(date_column, 7)
DATEDIFF(end_date, start_date)
ADD_MONTHS(date_column, 1)

-- Truncate to period
DATE_TRUNC('MONTH', created_at)
TRUNC(date_column, 'MM')

-- Extract parts
YEAR(created_at), MONTH(created_at)
DAYOFWEEK(created_at)
```

**Delta Lake features:**
```sql
-- Time travel
SELECT * FROM my_table TIMESTAMP AS OF '2024-01-15'
SELECT * FROM my_table VERSION AS OF 42

-- Describe history
DESCRIBE HISTORY my_table

-- Merge (upsert)
MERGE INTO target USING source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *
```

**Performance tips:**
- Use Delta Lake's `OPTIMIZE` and `ZORDER` for query performance
- Leverage Photon engine for compute-intensive queries
- Use `CACHE TABLE` for frequently accessed datasets
- Partition by low-cardinality date columns

---

## Common SQL Patterns

### Window Functions

```sql
-- Ranking
ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)
RANK() OVER (PARTITION BY category ORDER BY revenue DESC)
DENSE_RANK() OVER (ORDER BY score DESC)

-- Running totals / moving averages
SUM(revenue) OVER (ORDER BY date_col ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
AVG(revenue) OVER (ORDER BY date_col ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as moving_avg_7d

-- Lag / Lead
LAG(value, 1) OVER (PARTITION BY entity ORDER BY date_col) as prev_value
LEAD(value, 1) OVER (PARTITION BY entity ORDER BY date_col) as next_value

-- First / Last value
FIRST_VALUE(status) OVER (PARTITION BY user_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
LAST_VALUE(status) OVER (PARTITION BY user_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

-- Percent of total
revenue / SUM(revenue) OVER () as pct_of_total
revenue / SUM(revenue) OVER (PARTITION BY category) as pct_of_category
```

### CTEs for Readability

```sql
WITH
-- Step 1: Define the base population
base_users AS (
    SELECT user_id, created_at, plan_type
    FROM users
    WHERE created_at >= DATE '2024-01-01'
      AND status = 'active'
),

-- Step 2: Calculate user-level metrics
user_metrics AS (
    SELECT
        u.user_id,
        u.plan_type,
        COUNT(DISTINCT e.session_id) as session_count,
        SUM(e.revenue) as total_revenue
    FROM base_users u
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY u.user_id, u.plan_type
),

-- Step 3: Aggregate to summary level
summary AS (
    SELECT
        plan_type,
        COUNT(*) as user_count,
        AVG(session_count) as avg_sessions,
        SUM(total_revenue) as total_revenue
    FROM user_metrics
    GROUP BY plan_type
)

SELECT * FROM summary ORDER BY total_revenue DESC;
```

### Cohort Retention

```sql
WITH cohorts AS (
    SELECT
        user_id,
        DATE_TRUNC('month', first_activity_date) as cohort_month
    FROM users
),
activity AS (
    SELECT
        user_id,
        DATE_TRUNC('month', activity_date) as activity_month
    FROM user_activity
)
SELECT
    c.cohort_month,
    COUNT(DISTINCT c.user_id) as cohort_size,
    COUNT(DISTINCT CASE
        WHEN a.activity_month = c.cohort_month THEN a.user_id
    END) as month_0,
    COUNT(DISTINCT CASE
        WHEN a.activity_month = c.cohort_month + INTERVAL '1 month' THEN a.user_id
    END) as month_1,
    COUNT(DISTINCT CASE
        WHEN a.activity_month = c.cohort_month + INTERVAL '3 months' THEN a.user_id
    END) as month_3
FROM cohorts c
LEFT JOIN activity a ON c.user_id = a.user_id
GROUP BY c.cohort_month
ORDER BY c.cohort_month;
```

### Funnel Analysis

```sql
WITH funnel AS (
    SELECT
        user_id,
        MAX(CASE WHEN event = 'page_view' THEN 1 ELSE 0 END) as step_1_view,
        MAX(CASE WHEN event = 'signup_start' THEN 1 ELSE 0 END) as step_2_start,
        MAX(CASE WHEN event = 'signup_complete' THEN 1 ELSE 0 END) as step_3_complete,
        MAX(CASE WHEN event = 'first_purchase' THEN 1 ELSE 0 END) as step_4_purchase
    FROM events
    WHERE event_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT
    COUNT(*) as total_users,
    SUM(step_1_view) as viewed,
    SUM(step_2_start) as started_signup,
    SUM(step_3_complete) as completed_signup,
    SUM(step_4_purchase) as purchased,
    ROUND(100.0 * SUM(step_2_start) / NULLIF(SUM(step_1_view), 0), 1) as view_to_start_pct,
    ROUND(100.0 * SUM(step_3_complete) / NULLIF(SUM(step_2_start), 0), 1) as start_to_complete_pct,
    ROUND(100.0 * SUM(step_4_purchase) / NULLIF(SUM(step_3_complete), 0), 1) as complete_to_purchase_pct
FROM funnel;
```

### Deduplication

```sql
-- Keep the most recent record per key
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY entity_id
            ORDER BY updated_at DESC
        ) as rn
    FROM source_table
)
SELECT * FROM ranked WHERE rn = 1;
```

## Error Handling and Debugging

When a query fails:

1. **Syntax errors**: Check for dialect-specific syntax (e.g., `ILIKE` not available in BigQuery, `SAFE_DIVIDE` only in BigQuery)
2. **Column not found**: Verify column names against schema -- check for typos, case sensitivity (PostgreSQL is case-sensitive for quoted identifiers)
3. **Type mismatches**: Cast explicitly when comparing different types (`CAST(col AS DATE)`, `col::DATE`)
4. **Division by zero**: Use `NULLIF(denominator, 0)` or dialect-specific safe division
5. **Ambiguous columns**: Always qualify column names with table alias in JOINs
6. **Group by errors**: All non-aggregated columns must be in GROUP BY (except in BigQuery which allows grouping by alias)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/statistical-analysis', 'business', 'statistical-analysis', '', 'statistical-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Statistical Analysis Skill

Descriptive statistics, trend analysis, outlier detection, hypothesis testing, and guidance on when to be cautious about statistical claims.

## Descriptive Statistics Methodology

### Central Tendency

Choose the right measure of center based on the data:

| Situation | Use | Why |
|---|---|---|
| Symmetric distribution, no outliers | Mean | Most efficient estimator |
| Skewed distribution | Median | Robust to outliers |
| Categorical or ordinal data | Mode | Only option for non-numeric |
| Highly skewed with outliers (e.g., revenue per user) | Median + mean | Report both; the gap shows skew |

**Always report mean and median together for business metrics.** If they diverge significantly, the data is skewed and the mean alone is misleading.

### Spread and Variability

- **Standard deviation**: How far values typically fall from the mean. Use with normally distributed data.
- **Interquartile range (IQR)**: Distance from p25 to p75. Robust to outliers. Use with skewed data.
- **Coefficient of variation (CV)**: StdDev / Mean. Use to compare variability across metrics with different scales.
- **Range**: Max minus min. Sensitive to outliers but gives a quick sense of data extent.

### Percentiles for Business Context

Report key percentiles to tell a richer story than mean alone:

```
p1:   Bottom 1% (floor / minimum typical value)
p5:   Low end of normal range
p25:  First quartile
p50:  Median (typical user)
p75:  Third quartile
p90:  Top 10% / power users
p95:  High end of normal range
p99:  Top 1% / extreme users
```

**Example narrative**: "The median session duration is 4.2 minutes, but the top 10% of users spend over 22 minutes per session, pulling the mean up to 7.8 minutes."

### Describing Distributions

Characterize every numeric distribution you analyze:

- **Shape**: Normal, right-skewed, left-skewed, bimodal, uniform, heavy-tailed
- **Center**: Mean and median (and the gap between them)
- **Spread**: Standard deviation or IQR
- **Outliers**: How many and how extreme
- **Bounds**: Is there a natural floor (zero) or ceiling (100%)?

## Trend Analysis and Forecasting

### Identifying Trends

**Moving averages** to smooth noise:
```python
# 7-day moving average (good for daily data with weekly seasonality)
df['ma_7d'] = df['metric'].rolling(window=7, min_periods=1).mean()

# 28-day moving average (smooths weekly AND monthly patterns)
df['ma_28d'] = df['metric'].rolling(window=28, min_periods=1).mean()
```

**Period-over-period comparison**:
- Week-over-week (WoW): Compare to same day last week
- Month-over-month (MoM): Compare to same month prior
- Year-over-year (YoY): Gold standard for seasonal businesses
- Same-day-last-year: Compare specific calendar day

**Growth rates**:
```
Simple growth: (current - previous) / previous
CAGR: (ending / beginning) ^ (1 / years) - 1
Log growth: ln(current / previous)  -- better for volatile series
```

### Seasonality Detection

Check for periodic patterns:
1. Plot the raw time series -- visual inspection first
2. Compute day-of-week averages: is there a clear weekly pattern?
3. Compute month-of-year averages: is there an annual cycle?
4. When comparing periods, always use YoY or same-period comparisons to avoid conflating trend with seasonality

### Forecasting (Simple Methods)

For business analysts (not data scientists), use straightforward methods:

- **Naive forecast**: Tomorrow = today. Use as a baseline.
- **Seasonal naive**: Tomorrow = same day last week/year.
- **Linear trend**: Fit a line to historical data. Only for clearly linear trends.
- **Moving average forecast**: Use trailing average as the forecast.

**Always communicate uncertainty**. Provide a range, not a point estimate:
- "We expect 10K-12K signups next month based on the 3-month trend"
- NOT "We will get exactly 11,234 signups next month"

**When to escalate to a data scientist**: Non-linear trends, multiple seasonalities, external factors (marketing spend, holidays), or when forecast accuracy matters for resource allocation.

## Outlier and Anomaly Detection

### Statistical Methods

**Z-score method** (for normally distributed data):
```python
z_scores = (df['value'] - df['value'].mean()) / df['value'].std()
outliers = df[abs(z_scores) > 3]  # More than 3 standard deviations
```

**IQR method** (robust to non-normal distributions):
```python
Q1 = df['value'].quantile(0.25)
Q3 = df['value'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR
outliers = df[(df['value'] < lower_bound) | (df['value'] > upper_bound)]
```

**Percentile method** (simplest):
```python
outliers = df[(df['value'] < df['value'].quantile(0.01)) |
              (df['value'] > df['value'].quantile(0.99))]
```

### Handling Outliers

Do NOT automatically remove outliers. Instead:

1. **Investigate**: Is this a data error, a genuine extreme value, or a different population?
2. **Data errors**: Fix or remove (e.g., negative ages, timestamps in year 1970)
3. **Genuine extremes**: Keep them but consider using robust statistics (median instead of mean)
4. **Different population**: Segment them out for separate analysis (e.g., enterprise vs. SMB customers)

**Report what you did**: "We excluded 47 records (0.3%) with transaction amounts >$50K, which represent bulk enterprise orders analyzed separately."

### Time Series Anomaly Detection

For detecting unusual values in a time series:

1. Compute expected value (moving average or same-period-last-year)
2. Compute deviation from expected
3. Flag deviations beyond a threshold (typically 2-3 standard deviations of the residuals)
4. Distinguish between point anomalies (single unusual value) and change points (sustained shift)

## Hypothesis Testing Basics

### When to Use

Use hypothesis testing when you need to determine whether an observed difference is likely real or could be due to random chance. Common scenarios:

- A/B test results: Is variant B actually better than A?
- Before/after comparison: Did the product change actually move the metric?
- Segment comparison: Do enterprise customers really have higher retention?

### The Framework

1. **Null hypothesis (H0)**: There is no difference (the default assumption)
2. **Alternative hypothesis (H1)**: There is a difference
3. **Choose significance level (alpha)**: Typically 0.05 (5% chance of false positive)
4. **Compute test statistic and p-value**
5. **Interpret**: If p < alpha, reject H0 (evidence of a real difference)

### Common Tests

| Scenario | Test | When to Use |
|---|---|---|
| Compare two group means | t-test (independent) | Normal data, two groups |
| Compare two group proportions | z-test for proportions | Conversion rates, binary outcomes |
| Compare paired measurements | Paired t-test | Before/after on same entities |
| Compare 3+ group means | ANOVA | Multiple segments or variants |
| Non-normal data, two groups | Mann-Whitney U test | Skewed metrics, ordinal data |
| Association between categories | Chi-squared test | Two categorical variables |

### Practical Significance vs. Statistical Significance

**Statistical significance** means the difference is unlikely due to chance.

**Practical significance** means the difference is large enough to matter for business decisions.

A difference can be statistically significant but practically meaningless (common with large samples). Always report:
- **Effect size**: How big is the difference? (e.g., "Variant B improved conversion by 0.3 percentage points")
- **Confidence interval**: What's the range of plausible true effects?
- **Business impact**: What does this translate to in revenue, users, or other business terms?

### Sample Size Considerations

- Small samples produce unreliable results, even with significant p-values
- Rule of thumb for proportions: Need at least 30 events per group for basic reliability
- For detecting small effects (e.g., 1% conversion rate change), you may need thousands of observations per group
- If your sample is small, say so: "With only 200 observations per group, we have limited power to detect effects smaller than X%"

## When to Be Cautious About Statistical Claims

### Correlation Is Not Causation

When you find a correlation, explicitly consider:
- **Reverse causation**: Maybe B causes A, not A causes B
- **Confounding variables**: Maybe C causes both A and B
- **Coincidence**: With enough variables, spurious correlations are inevitable

**What you can say**: "Users who use feature X have 30% higher retention"
**What you cannot say without more evidence**: "Feature X causes 30% higher retention"

### Multiple Comparisons Problem

When you test many hypotheses, some will be "significant" by chance:
- Testing 20 metrics at p=0.05 means ~1 will be falsely significant
- If you looked at many segments before finding one that's different, note that
- Adjust for multiple comparisons with Bonferroni correction (divide alpha by number of tests) or report how many tests were run

### Simpson's Paradox

A trend in aggregated data can reverse when data is segmented:
- Always check whether the conclusion holds across key segments
- Example: Overall conversion goes up, but conversion goes down in every segment -- because the mix shifted toward a higher-converting segment

### Survivorship Bias

You can only analyze entities that "survived" to be in your dataset:
- Analyzing active users ignores those who churned
- Analyzing successful companies ignores those that failed
- Always ask: "Who is missing from this dataset, and would their inclusion change the conclusion?"

### Ecological Fallacy

Aggregate trends may not apply to individuals:
- "Countries with higher X have higher Y" does NOT mean "individuals with higher X have higher Y"
- Be careful about applying group-level findings to individual cases

### Anchoring on Specific Numbers

Be wary of false precision:
- "Churn will be 4.73% next quarter" implies more certainty than is warranted
- Prefer ranges: "We expect churn between 4-6% based on historical patterns"
- Round appropriately: "About 5%" is often more honest than "4.73%"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/validate-data', 'business', 'validate-data', '', 'validate-data', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /validate-data - Validate Analysis Before Sharing

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Review an analysis for accuracy, methodology, and potential biases before sharing with stakeholders. Generates a confidence assessment and improvement suggestions.

## Usage

```
/validate-data <analysis to review>
```

The analysis can be:
- A document or report in the conversation
- A file (markdown, notebook, spreadsheet)
- SQL queries and their results
- Charts and their underlying data
- A description of methodology and findings

## Workflow

### 1. Review Methodology and Assumptions

Examine:

- **Question framing**: Is the analysis answering the right question? Could the question be interpreted differently?
- **Data selection**: Are the right tables/datasets being used? Is the time range appropriate?
- **Population definition**: Is the analysis population correctly defined? Are there unintended exclusions?
- **Metric definitions**: Are metrics defined clearly and consistently? Do they match how stakeholders understand them?
- **Baseline and comparison**: Is the comparison fair? Are time periods, cohort sizes, and contexts comparable?

### 2. Run the Pre-Delivery QA Checklist

Work through the checklist below — data quality, calculation, reasonableness, and presentation checks.

### 3. Check for Common Analytical Pitfalls

Systematically review against the detailed pitfall catalog below (join explosion, survivorship bias, incomplete period comparison, denominator shifting, average of averages, timezone mismatches, selection bias).

### 4. Verify Calculations and Aggregations

Where possible, spot-check:

- Recalculate a few key numbers independently
- Verify that subtotals sum to totals
- Check that percentages sum to 100% (or close to it) where expected
- Confirm that YoY/MoM comparisons use the correct base periods
- Validate that filters are applied consistently across all metrics

Apply the result sanity-checking techniques below (magnitude checks, cross-validation, red-flag detection).

### 5. Assess Visualizations

If the analysis includes charts:

- Do axes start at appropriate values (zero for bar charts)?
- Are scales consistent across comparison charts?
- Do chart titles accurately describe what's shown?
- Could the visualization mislead a quick reader?
- Are there truncated axes, inconsistent intervals, or 3D effects that distort perception?

### 6. Evaluate Narrative and Conclusions

Review whether:

- Conclusions are supported by the data shown
- Alternative explanations are acknowledged
- Uncertainty is communicated appropriately
- Recommendations follow logically from findings
- The level of confidence matches the strength of evidence

### 7. Suggest Improvements

Provide specific, actionable suggestions:

- Additional analyses that would strengthen the conclusions
- Caveats or limitations that should be noted
- Better visualizations or framings for key points
- Missing context that stakeholders would want

### 8. Generate Confidence Assessment

Rate the analysis on a 3-level scale:

**Ready to share** -- Analysis is methodologically sound, calculations verified, caveats noted. Minor suggestions for improvement but nothing blocking.

**Share with noted caveats** -- Analysis is largely correct but has specific limitations or assumptions that must be communicated to stakeholders. List the required caveats.

**Needs revision** -- Found specific errors, methodological issues, or missing analyses that should be addressed before sharing. List the required changes with priority order.

## Output Format

```
## Validation Report

### Overall Assessment: [Ready to share | Share with caveats | Needs revision]

### Methodology Review
[Findings about approach, data selection, definitions]

### Issues Found
1. [Severity: High/Medium/Low] [Issue description and impact]
2. ...

### Calculation Spot-Checks
- [Metric]: [Verified / Discrepancy found]
- ...

### Visualization Review
[Any issues with charts or visual presentation]

### Suggested Improvements
1. [Improvement and why it matters]
2. ...

### Required Caveats for Stakeholders
- [Caveat that must be communicated]
- ...
```

---

## Pre-Delivery QA Checklist

Run through this checklist before sharing any analysis with stakeholders.

### Data Quality Checks

- [ ] **Source verification**: Confirmed which tables/data sources were used. Are they the right ones for this question?
- [ ] **Freshness**: Data is current enough for the analysis. Noted the "as of" date.
- [ ] **Completeness**: No unexpected gaps in time series or missing segments.
- [ ] **Null handling**: Checked null rates in key columns. Nulls are handled appropriately (excluded, imputed, or flagged).
- [ ] **Deduplication**: Confirmed no double-counting from bad joins or duplicate source records.
- [ ] **Filter verification**: All WHERE clauses and filters are correct. No unintended exclusions.

### Calculation Checks

- [ ] **Aggregation logic**: GROUP BY includes all non-aggregated columns. Aggregation level matches the analysis grain.
- [ ] **Denominator correctness**: Rate and percentage calculations use the right denominator. Denominators are non-zero.
- [ ] **Date alignment**: Comparisons use the same time period length. Partial periods are excluded or noted.
- [ ] **Join correctness**: JOIN types are appropriate (INNER vs LEFT). Many-to-many joins haven't inflated counts.
- [ ] **Metric definitions**: Metrics match how stakeholders define them. Any deviations are noted.
- [ ] **Subtotals sum**: Parts add up to the whole where expected. If they don't, explain why (e.g., overlap).

### Reasonableness Checks

- [ ] **Magnitude**: Numbers are in a plausible range. Revenue isn't negative. Percentages are between 0-100%.
- [ ] **Trend continuity**: No unexplained jumps or drops in time series.
- [ ] **Cross-reference**: Key numbers match other known sources (dashboards, previous reports, finance data).
- [ ] **Order of magnitude**: Total revenue is in the right ballpark. User counts match known figures.
- [ ] **Edge cases**: What happens at the boundaries? Empty segments, zero-activity periods, new entities.

### Presentation Checks

- [ ] **Chart accuracy**: Bar charts start at zero. Axes are labeled. Scales are consistent across panels.
- [ ] **Number formatting**: Appropriate precision. Consistent currency/percentage formatting. Thousands separators where needed.
- [ ] **Title clarity**: Titles state the insight, not just the metric. Date ranges are specified.
- [ ] **Caveat transparency**: Known limitations and assumptions are stated explicitly.
- [ ] **Reproducibility**: Someone else could recreate this analysis from the documentation provided.

## Common Data Analysis Pitfalls

### Join Explosion

**The problem**: A many-to-many join silently multiplies rows, inflating counts and sums.

**How to detect**:
```sql
-- Check row count before and after join
SELECT COUNT(*) FROM table_a;  -- 1,000
SELECT COUNT(*) FROM table_a a JOIN table_b b ON a.id = b.a_id;  -- 3,500 (uh oh)
```

**How to prevent**:
- Always check row counts after joins
- If counts increase, investigate the join relationship (is it really 1:1 or 1:many?)
- Use `COUNT(DISTINCT a.id)` instead of `COUNT(*)` when counting entities through joins

### Survivorship Bias

**The problem**: Analyzing only entities that exist today, ignoring those that were deleted, churned, or failed.

**Examples**:
- Analyzing user behavior of "current users" misses churned users
- Looking at "companies using our product" ignores those who evaluated and left
- Studying properties of "successful" outcomes without "unsuccessful" ones

**How to prevent**: Ask "who is NOT in this dataset?" before drawing conclusions.

### Incomplete Period Comparison

**The problem**: Comparing a partial period to a full period.

**Examples**:
- "January revenue is $500K vs. December's $800K" -- but January isn't over yet
- "This week's signups are down" -- checked on Wednesday, comparing to a full prior week

**How to prevent**: Always filter to complete periods, or compare same-day-of-month / same-number-of-days.

### Denominator Shifting

**The problem**: The denominator changes between periods, making rates incomparable.

**Examples**:
- Conversion rate improves because you changed how you count "eligible" users
- Churn rate changes because the definition of "active" was updated

**How to prevent**: Use consistent definitions across all compared periods. Note any definition changes.

### Average of Averages

**The problem**: Averaging pre-computed averages gives wrong results when group sizes differ.

**Example**:
- Group A: 100 users, average revenue $50
- Group B: 10 users, average revenue $200
- Wrong: Average of averages = ($50 + $200) / 2 = $125
- Right: Weighted average = (100*$50 + 10*$200) / 110 = $63.64

**How to prevent**: Always aggregate from raw data. Never average pre-aggregated averages.

### Timezone Mismatches

**The problem**: Different data sources use different timezones, causing misalignment.

**Examples**:
- Event timestamps in UTC vs. user-facing dates in local time
- Daily rollups that use different cutoff times

**How to prevent**: Standardize all timestamps to a single timezone (UTC recommended) before analysis. Document the timezone used.

### Selection Bias in Segmentation

**The problem**: Segments are defined by the outcome you're measuring, creating circular logic.

**Examples**:
- "Users who completed onboarding have higher retention" -- obviously, they self-selected
- "Power users generate more revenue" -- they became power users BY generating revenue

**How to prevent**: Define segments based on pre-treatment characteristics, not outcomes.

### Other Statistical Traps

- **Simpson's paradox**: Trend reverses when data is aggregated vs. segmented
- **Correlation presented as causation** without supporting evidence
- **Small sample sizes** leading to unreliable conclusions
- **Outliers disproportionately affecting averages** (should medians be used instead?)
- **Multiple testing / cherry-picking** significant results
- **Look-ahead bias**: Using future information to explain past events
- **Cherry-picked time ranges** that favor a particular narrative

## Result Sanity Checking

### Magnitude Checks

For any key number in your analysis, verify it passes the "smell test":

| Metric Type | Sanity Check |
|---|---|
| User counts | Does this match known MAU/DAU figures? |
| Revenue | Is this in the right order of magnitude vs. known ARR? |
| Conversion rates | Is this between 0% and 100%? Does it match dashboard figures? |
| Growth rates | Is 50%+ MoM growth realistic, or is there a data issue? |
| Averages | Is the average reasonable given what you know about the distribution? |
| Percentages | Do segment percentages sum to ~100%? |

### Cross-Validation Techniques

1. **Calculate the same metric two different ways** and verify they match
2. **Spot-check individual records** -- pick a few specific entities and trace their data manually
3. **Compare to known benchmarks** -- match against published dashboards, finance reports, or prior analyses
4. **Reverse engineer** -- if total revenue is X, does per-user revenue times user count approximately equal X?
5. **Boundary checks** -- what happens when you filter to a single day, a single user, or a single category? Are those micro-results sensible?

### Red Flags That Warrant Investigation

- Any metric that changed by more than 50% period-over-period without an obvious cause
- Counts or sums that are exact round numbers (suggests a filter or default value issue)
- Rates exactly at 0% or 100% (may indicate incomplete data)
- Results that perfectly confirm the hypothesis (reality is usually messier)
- Identical values across time periods or segments (suggests the query is ignoring a dimension)

## Documentation Standards for Reproducibility

### Analysis Documentation Template

Every non-trivial analysis should include:

```markdown
## Analysis: [Title]

### Question
[The specific question being answered]

### Data Sources
- Table: [schema.table_name] (as of [date])
- Table: [schema.other_table] (as of [date])
- File: [filename] (source: [where it came from])

### Definitions
- [Metric A]: [Exactly how it's calculated]
- [Segment X]: [Exactly how membership is determined]
- [Time period]: [Start date] to [end date], [timezone]

### Methodology
1. [Step 1 of the analysis approach]
2. [Step 2]
3. [Step 3]

### Assumptions and Limitations
- [Assumption 1 and why it's reasonable]
- [Limitation 1 and its potential impact on conclusions]

### Key Findings
1. [Finding 1 with supporting evidence]
2. [Finding 2 with supporting evidence]

### SQL Queries
[All queries used, with comments]

### Caveats
- [Things the reader should know before acting on this]
```

### Code Documentation

For any code (SQL, Python) that may be reused:

```python
"""
Analysis: Monthly Cohort Retention
Author: [Name]
Date: [Date]
Data Source: events table, users table
Last Validated: [Date] -- results matched dashboard within 2%

Purpose:
    Calculate monthly user retention cohorts based on first activity date.

Assumptions:
    - "Active" means at least one event in the month
    - Excludes test/internal accounts (user_type != 'internal')
    - Uses UTC dates throughout

Output:
    Cohort retention matrix with cohort_month rows and months_since_signup columns.
    Values are retention rates (0-100%).
"""
```

### Version Control for Analyses

- Save queries and code in version control (git) or a shared docs system
- Note the date of the data snapshot used
- If an analysis is re-run with updated data, document what changed and why
- Link to prior versions of recurring analyses for trend comparison

## Examples

```
/validate-data Review this quarterly revenue analysis before I send it to the exec team: [analysis]
```

```
/validate-data Check my churn analysis -- I'm comparing Q4 churn rates to Q3 but Q4 has a shorter measurement window
```

```
/validate-data Here's a SQL query and its results for our conversion funnel. Does the logic look right? [query + results]
```

## Tips

- Run /validate-data before any high-stakes presentation or decision
- Even quick analyses benefit from a sanity check -- it takes a minute and can save your credibility
- If the validation finds issues, fix them and re-validate
- Share the validation output alongside your analysis to build stakeholder confidence$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/write-query', 'business', 'write-query', '', 'write-query', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /write-query - Write Optimized SQL

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Write a SQL query from a natural language description, optimized for your specific SQL dialect and following best practices.

## Usage

```
/write-query <description of what data you need>
```

## Workflow

### 1. Understand the Request

Parse the user's description to identify:

- **Output columns**: What fields should the result include?
- **Filters**: What conditions limit the data (time ranges, segments, statuses)?
- **Aggregations**: Are there GROUP BY operations, counts, sums, averages?
- **Joins**: Does this require combining multiple tables?
- **Ordering**: How should results be sorted?
- **Limits**: Is there a top-N or sample requirement?

### 2. Determine SQL Dialect

If the user's SQL dialect is not already known, ask which they use:

- **PostgreSQL** (including Aurora, RDS, Supabase, Neon)
- **Snowflake**
- **BigQuery** (Google Cloud)
- **Redshift** (Amazon)
- **Databricks SQL**
- **MySQL** (including Aurora MySQL, PlanetScale)
- **SQL Server** (Microsoft)
- **DuckDB**
- **SQLite**
- **Other** (ask for specifics)

Remember the dialect for future queries in the same session.

### 3. Discover Schema (If Warehouse Connected)

If a data warehouse MCP server is connected:

1. Search for relevant tables based on the user's description
2. Inspect column names, types, and relationships
3. Check for partitioning or clustering keys that affect performance
4. Look for pre-built views or materialized views that might simplify the query

### 4. Write the Query

Follow these best practices:

**Structure:**
- Use CTEs (WITH clauses) for readability when queries have multiple logical steps
- One CTE per logical transformation or data source
- Name CTEs descriptively (e.g., `daily_signups`, `active_users`, `revenue_by_product`)

**Performance:**
- Never use `SELECT *` in production queries -- specify only needed columns
- Filter early (push WHERE clauses as close to the base tables as possible)
- Use partition filters when available (especially date partitions)
- Prefer `EXISTS` over `IN` for subqueries with large result sets
- Use appropriate JOIN types (don't use LEFT JOIN when INNER JOIN is correct)
- Avoid correlated subqueries when a JOIN or window function works
- Be mindful of exploding joins (many-to-many)

**Readability:**
- Add comments explaining the "why" for non-obvious logic
- Use consistent indentation and formatting
- Alias tables with meaningful short names (not just `a`, `b`, `c`)
- Put each major clause on its own line

**Dialect-specific optimizations:**
- Apply dialect-specific syntax and functions (see `sql-queries` skill for details)
- Use dialect-appropriate date functions, string functions, and window syntax
- Note any dialect-specific performance features (e.g., Snowflake clustering, BigQuery partitioning)

### 5. Present the Query

Provide:

1. **The complete query** in a SQL code block with syntax highlighting
2. **Brief explanation** of what each CTE or section does
3. **Performance notes** if relevant (expected cost, partition usage, potential bottlenecks)
4. **Modification suggestions** -- how to adjust for common variations (different time range, different granularity, additional filters)

### 6. Offer to Execute

If a data warehouse is connected, offer to run the query and analyze the results. If the user wants to run it themselves, the query is ready to copy-paste.

## Examples

**Simple aggregation:**
```
/write-query Count of orders by status for the last 30 days
```

**Complex analysis:**
```
/write-query Cohort retention analysis -- group users by their signup month, then show what percentage are still active (had at least one event) at 1, 3, 6, and 12 months after signup
```

**Performance-critical:**
```
/write-query We have a 500M row events table partitioned by date. Find the top 100 users by event count in the last 7 days with their most recent event type.
```

## Tips

- Mention your SQL dialect upfront to get the right syntax immediately
- If you know the table names, include them -- otherwise Claude will help you find them
- Specify if you need the query to be idempotent (safe to re-run) or one-time
- For recurring queries, mention if it should be parameterized for date ranges$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/design/skills/accessibility-review', 'business', 'accessibility-review', '', 'accessibility-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /accessibility-review

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Audit a design or page for WCAG 2.1 AA accessibility compliance.

## Usage

```
/accessibility-review $ARGUMENTS
```

Audit for accessibility: @$1

## WCAG 2.1 AA Quick Reference

### Perceivable
- **1.1.1** Non-text content has alt text
- **1.3.1** Info and structure conveyed semantically
- **1.4.3** Contrast ratio >= 4.5:1 (normal text), >= 3:1 (large text)
- **1.4.11** Non-text contrast >= 3:1 (UI components, graphics)

### Operable
- **2.1.1** All functionality available via keyboard
- **2.4.3** Logical focus order
- **2.4.7** Visible focus indicator
- **2.5.5** Touch target >= 44x44 CSS pixels

### Understandable
- **3.2.1** Predictable on focus (no unexpected changes)
- **3.3.1** Error identification (describe the error)
- **3.3.2** Labels or instructions for inputs

### Robust
- **4.1.2** Name, role, value for all UI components

## Common Issues

1. Insufficient color contrast
2. Missing form labels
3. No keyboard access to interactive elements
4. Missing alt text on meaningful images
5. Focus traps in modals
6. Missing ARIA landmarks
7. Auto-playing media without controls
8. Time limits without extension options

## Testing Approach

1. Automated scan (catches ~30% of issues)
2. Keyboard-only navigation
3. Screen reader testing (VoiceOver, NVDA)
4. Color contrast verification
5. Zoom to 200% — does layout break?

## Output

```markdown
## Accessibility Audit: [Design/Page Name]
**Standard:** WCAG 2.1 AA | **Date:** [Date]

### Summary
**Issues found:** [X] | **Critical:** [X] | **Major:** [X] | **Minor:** [X]

### Findings

#### Perceivable
| # | Issue | WCAG Criterion | Severity | Recommendation |
|---|-------|---------------|----------|----------------|
| 1 | [Issue] | [1.4.3 Contrast] | 🔴 Critical | [Fix] |

#### Operable
| # | Issue | WCAG Criterion | Severity | Recommendation |
|---|-------|---------------|----------|----------------|
| 1 | [Issue] | [2.1.1 Keyboard] | 🟡 Major | [Fix] |

#### Understandable
| # | Issue | WCAG Criterion | Severity | Recommendation |
|---|-------|---------------|----------|----------------|
| 1 | [Issue] | [3.3.2 Labels] | 🟢 Minor | [Fix] |

#### Robust
| # | Issue | WCAG Criterion | Severity | Recommendation |
|---|-------|---------------|----------|----------------|
| 1 | [Issue] | [4.1.2 Name, Role, Value] | 🟡 Major | [Fix] |

### Color Contrast Check
| Element | Foreground | Background | Ratio | Required | Pass? |
|---------|-----------|------------|-------|----------|-------|
| [Body text] | [color] | [color] | [X]:1 | 4.5:1 | ✅/❌ |

### Keyboard Navigation
| Element | Tab Order | Enter/Space | Escape | Arrow Keys |
|---------|-----------|-------------|--------|------------|
| [Element] | [Order] | [Behavior] | [Behavior] | [Behavior] |

### Screen Reader
| Element | Announced As | Issue |
|---------|-------------|-------|
| [Element] | [What SR says] | [Problem if any] |

### Priority Fixes
1. **[Critical fix]** — Affects [who] and blocks [what]
2. **[Major fix]** — Improves [what] for [who]
3. **[Minor fix]** — Nice to have
```

## If Connectors Available

If **~~design tool** is connected:
- Inspect color values, font sizes, and touch targets directly from Figma
- Check component ARIA roles and keyboard behavior in the design spec

If **~~project tracker** is connected:
- Create tickets for each accessibility finding with severity and WCAG criterion
- Link findings to existing accessibility remediation epics

## Tips

1. **Start with contrast and keyboard** — These catch the most common and impactful issues.
2. **Test with real assistive technology** — My audit is a great start, but manual testing with VoiceOver/NVDA catches things I can't.
3. **Prioritize by impact** — Fix issues that block users first, polish later.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/design/skills/design-critique', 'business', 'design-critique', '', 'design-critique', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /design-critique

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Get structured design feedback across multiple dimensions.

## Usage

```
/design-critique $ARGUMENTS
```

Review the design: @$1

If a Figma URL is provided, pull the design from Figma. If a file is referenced, read it. Otherwise, ask the user to describe or share their design.

## What I Need From You

- **The design**: Figma URL, screenshot, or detailed description
- **Context**: What is this? Who is it for? What stage (exploration, refinement, final)?
- **Focus** (optional): "Focus on mobile" or "Focus on the onboarding flow"

## Critique Framework

### 1. First Impression (2 seconds)
- What draws the eye first? Is that correct?
- What's the emotional reaction?
- Is the purpose immediately clear?

### 2. Usability
- Can the user accomplish their goal?
- Is the navigation intuitive?
- Are interactive elements obvious?
- Are there unnecessary steps?

### 3. Visual Hierarchy
- Is there a clear reading order?
- Are the right elements emphasized?
- Is whitespace used effectively?
- Is typography creating the right hierarchy?

### 4. Consistency
- Does it follow the design system?
- Are spacing, colors, and typography consistent?
- Do similar elements behave similarly?

### 5. Accessibility
- Color contrast ratios
- Touch target sizes
- Text readability
- Alternative text for images

## How to Give Feedback

- **Be specific**: "The CTA competes with the navigation" not "the layout is confusing"
- **Explain why**: Connect feedback to design principles or user needs
- **Suggest alternatives**: Don't just identify problems, propose solutions
- **Acknowledge what works**: Good feedback includes positive observations
- **Match the stage**: Early exploration gets different feedback than final polish

## Output

```markdown
## Design Critique: [Design Name]

### Overall Impression
[1-2 sentence first reaction — what works, what's the biggest opportunity]

### Usability
| Finding | Severity | Recommendation |
|---------|----------|----------------|
| [Issue] | 🔴 Critical / 🟡 Moderate / 🟢 Minor | [Fix] |

### Visual Hierarchy
- **What draws the eye first**: [Element] — [Is this correct?]
- **Reading flow**: [How does the eye move through the layout?]
- **Emphasis**: [Are the right things emphasized?]

### Consistency
| Element | Issue | Recommendation |
|---------|-------|----------------|
| [Typography/spacing/color] | [Inconsistency] | [Fix] |

### Accessibility
- **Color contrast**: [Pass/fail for key text]
- **Touch targets**: [Adequate size?]
- **Text readability**: [Font size, line height]

### What Works Well
- [Positive observation 1]
- [Positive observation 2]

### Priority Recommendations
1. **[Most impactful change]** — [Why and how]
2. **[Second priority]** — [Why and how]
3. **[Third priority]** — [Why and how]
```

## If Connectors Available

If **~~design tool** is connected:
- Pull the design directly from Figma and inspect components, tokens, and layers
- Compare against the existing design system for consistency

If **~~user feedback** is connected:
- Cross-reference design decisions with recent user feedback and support tickets

## Tips

1. **Share the context** — "This is a checkout flow for a B2B SaaS" helps me give relevant feedback.
2. **Specify your stage** — Early exploration gets different feedback than final polish.
3. **Ask me to focus** — "Just look at the navigation" gives you more depth on one area.$body$)
ON CONFLICT (skill_key) DO NOTHING;
