INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/audit-support', 'business', 'audit-support', '', 'audit-support', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Audit Support

**Important**: This skill assists with SOX compliance workflows but does not provide audit or legal advice. All testing workpapers and assessments should be reviewed by qualified financial professionals. While "significance" and "materiality" are context-specific concepts that are ultimately assessed by auditors, this skill is intended to assist professionals in the creation and evaluation of effective internal controls and documentation for audits.

SOX 404 control testing methodology, sample selection approaches, testing documentation standards, control deficiency classification, and common control types.

## SOX 404 Control Testing Methodology

### Overview

SOX Section 404 requires management to assess the effectiveness of internal controls over financial reporting (ICFR). This involves:

1. **Scoping:** Identify significant accounts and relevant assertions
2. **Risk assessment:** Evaluate the risk of material misstatement for each significant account
3. **Control identification:** Document the controls that address each risk
4. **Testing:** Test the design and operating effectiveness of key controls
5. **Evaluation:** Assess whether any deficiencies exist and their severity
6. **Reporting:** Document the assessment and any material weaknesses

### Scoping Significant Accounts

An account is significant if there is more than a remote likelihood that it could contain a misstatement that is material (individually or in aggregate).

**Quantitative factors:**
- Account balance exceeds materiality threshold (typically 3-5% of a key benchmark)
- Transaction volume is high, increasing the risk of error
- Account is subject to significant estimates or judgment

**Qualitative factors:**
- Account involves complex accounting (revenue recognition, derivatives, pensions)
- Account is susceptible to fraud (cash, revenue, related-party transactions)
- Account has had prior misstatements or audit adjustments
- Account involves significant management judgment or estimates
- New account or significantly changed process

### Relevant Assertions by Account Type

| Account Type | Key Assertions |
|-------------|---------------|
| Revenue | Occurrence, Completeness, Accuracy, Cut-off |
| Accounts Receivable | Existence, Valuation (allowance), Rights |
| Inventory | Existence, Valuation, Completeness |
| Fixed Assets | Existence, Valuation, Completeness, Rights |
| Accounts Payable | Completeness, Accuracy, Existence |
| Accrued Liabilities | Completeness, Valuation, Accuracy |
| Equity | Completeness, Accuracy, Presentation |
| Financial Close/Reporting | Presentation, Accuracy, Completeness |

### Design Effectiveness vs Operating Effectiveness

**Design effectiveness:** Is the control properly designed to prevent or detect a material misstatement in the relevant assertion?
- Evaluated through walkthroughs (trace a transaction end-to-end through the process)
- Confirm the control is placed at the right point in the process
- Confirm the control addresses the identified risk
- Performed at least annually, or when processes change

**Operating effectiveness:** Did the control actually operate as designed throughout the testing period?
- Evaluated through testing (inspection, observation, re-performance, inquiry)
- Requires sufficient sample sizes to support a conclusion
- Must cover the full period of reliance

## Sample Selection Approaches

### Random Selection

**When to use:** Default method for transaction-level controls with large populations.

**Method:**
1. Define the population (all transactions subject to the control during the period)
2. Number each item in the population sequentially
3. Use a random number generator to select sample items
4. Ensure no bias in selection (all items have equal probability)

**Advantages:** Statistically valid, defensible, no selection bias
**Disadvantages:** May miss high-risk items, requires complete population listing

### Targeted (Judgmental) Selection

**When to use:** Supplement to random selection for risk-based testing; primary method when population is small or highly varied.

**Method:**
1. Identify items with specific risk characteristics:
   - High dollar amount (above a defined threshold)
   - Unusual or non-standard transactions
   - Period-end transactions (cut-off risk)
   - Related-party transactions
   - Manual or override transactions
   - New vendor/customer transactions
2. Select items matching risk criteria
3. Document rationale for each targeted selection

**Advantages:** Focuses on highest-risk items, efficient use of testing effort
**Disadvantages:** Not statistically representative, may over-represent certain risks

### Haphazard Selection

**When to use:** When random selection is impractical (no sequential population listing) and population is relatively homogeneous.

**Method:**
1. Select items without any specific pattern or bias
2. Ensure selections are spread across the full population period
3. Avoid unconscious bias (don't always pick items at the top, round numbers, etc.)

**Advantages:** Simple, no technology required
**Disadvantages:** Not statistically valid, susceptible to unconscious bias

### Systematic Selection

**When to use:** When population is sequential and you want even coverage across the period.

**Method:**
1. Calculate the sampling interval: Population size / Sample size
2. Select a random starting point within the first interval
3. Select every Nth item from the starting point

**Example:** Population of 1,000, sample of 25 → interval of 40. Random start: item 17. Select items 17, 57, 97, 137, ...

**Advantages:** Even coverage across population, simple to execute
**Disadvantages:** Periodic patterns in the population could bias results

### Sample Size Guidance

| Control Frequency | Expected Population | Low Risk Sample | Moderate Risk Sample | High Risk Sample |
|------------------|--------------------|-----------------|--------------------|-----------------|
| Annual | 1 | 1 | 1 | 1 |
| Quarterly | 4 | 2 | 2 | 3 |
| Monthly | 12 | 2 | 3 | 4 |
| Weekly | 52 | 5 | 8 | 15 |
| Daily | ~250 | 20 | 30 | 40 |
| Per-transaction (small pop.) | < 250 | 20 | 30 | 40 |
| Per-transaction (large pop.) | 250+ | 25 | 40 | 60 |

**Factors increasing sample size:**
- Higher inherent risk in the account/process
- Control is the sole control addressing a significant risk (no redundancy)
- Prior period control deficiency identified
- New control (not tested in prior periods)
- External auditor reliance on management testing

## Testing Documentation Standards

### Workpaper Requirements

Every control test should be documented with:

1. **Control identification:**
   - Control number/ID
   - Control description (what is done, by whom, how often)
   - Control type (manual, automated, IT-dependent manual)
   - Control frequency
   - Risk and assertion addressed

2. **Test design:**
   - Test objective (what you are trying to determine)
   - Test procedures (step-by-step instructions)
   - Expected evidence (what you expect to see if the control is effective)
   - Sample selection methodology and rationale

3. **Test execution:**
   - Population description and size
   - Sample selection details (method, items selected)
   - Results for each sample item (pass/fail with specific evidence examined)
   - Exceptions noted with full description

4. **Conclusion:**
   - Overall assessment (effective / deficiency / significant deficiency / material weakness)
   - Basis for conclusion
   - Impact assessment for any exceptions
   - Compensating controls considered (if applicable)

5. **Sign-off:**
   - Tester name and date
   - Reviewer name and date

### Evidence Standards

**Sufficient evidence includes:**
- Screenshots showing system-enforced controls
- Signed/initialed approval documents
- Email approvals with identifiable approver and date
- System audit logs showing who performed the action and when
- Re-performed calculations with matching results
- Observation notes (with date, location, observer)

**Insufficient evidence:**
- Verbal confirmations alone (must be corroborated)
- Undated documents
- Evidence without identifiable performer/approver
- Generic system reports without date/time stamps
- "Per discussion with [name]" without corroborating documentation

### Working Paper Organization

Organize testing files by control area:

```
SOX Testing/
├── [Year]/
│   ├── Scoping and Risk Assessment/
│   ├── Revenue Cycle/
│   │   ├── Control Matrix
│   │   ├── Walkthrough Documentation
│   │   ├── Test Workpapers (one per control)
│   │   └── Supporting Evidence
│   ├── Procure to Pay/
│   ├── Payroll/
│   ├── Financial Close/
│   ├── Treasury/
│   ├── Fixed Assets/
│   ├── IT General Controls/
│   ├── Entity Level Controls/
│   └── Summary and Conclusions/
│       ├── Deficiency Evaluation
│       └── Management Assessment
```

## Control Deficiency Classification

### Deficiency

A deficiency in internal control exists when the design or operation of a control does not allow management or employees, in the normal course of performing their assigned functions, to prevent or detect misstatements on a timely basis.

**Evaluation factors:**
- What is the likelihood that the control failure could result in a misstatement?
- What is the magnitude of the potential misstatement?
- Is there a compensating control that mitigates the deficiency?

### Significant Deficiency

A deficiency, or combination of deficiencies, that is less severe than a material weakness yet important enough to merit attention by those charged with governance.

**Indicators:**
- The deficiency could result in a misstatement that is more than inconsequential but less than material
- There is more than a remote (but less than reasonably possible) likelihood of a material misstatement
- The control is a key control and the deficiency is not fully mitigated by compensating controls
- Combination of individually minor deficiencies that together represent a significant concern

### Material Weakness

A deficiency, or combination of deficiencies, such that there is a reasonable possibility that a material misstatement of the financial statements will not be prevented or detected on a timely basis.

**Indicators:**
- Identification of fraud by senior management (any magnitude)
- Restatement of previously issued financial statements to correct a material error
- Identification by the auditor of a material misstatement that would not have been detected by the company's controls
- Ineffective oversight of financial reporting by the audit committee
- Deficiency in a pervasive control (entity-level, IT general control) affecting multiple processes

### Deficiency Aggregation

Individual deficiencies that are not significant individually may be significant in combination:

1. Identify all deficiencies in the same process or affecting the same assertion
2. Evaluate whether the combined effect could result in a material misstatement
3. Consider whether deficiencies in compensating controls exacerbate other deficiencies
4. Document the aggregation analysis and conclusion

### Remediation

For each identified deficiency:

1. **Root cause analysis:** Why did the control fail? (design gap, execution failure, staffing, training, system issue)
2. **Remediation plan:** Specific actions to fix the control (redesign, additional training, system enhancement, added review)
3. **Timeline:** Target date for remediation completion
4. **Owner:** Person responsible for implementing the remediation
5. **Validation:** How and when the remediated control will be re-tested to confirm effectiveness

## Common Control Types

### IT General Controls (ITGCs)

Controls over the IT environment that support the reliable functioning of application controls and automated processes.

**Access Controls:**
- User access provisioning (new access requests require approval)
- User access de-provisioning (terminated users removed timely)
- Privileged access management (admin/superuser access restricted and monitored)
- Periodic access reviews (user access recertified on a defined schedule)
- Password policies (complexity, rotation, lockout)
- Segregation of duties enforcement (conflicting access prevented)

**Change Management:**
- Change requests documented and approved before implementation
- Changes tested in a non-production environment before promotion
- Separation of development and production environments
- Emergency change procedures (documented, approved post-implementation)
- Change review and post-implementation validation

**IT Operations:**
- Batch job monitoring and exception handling
- Backup and recovery procedures (regular backups, tested restores)
- System availability and performance monitoring
- Incident management and escalation procedures
- Disaster recovery planning and testing

### Manual Controls

Controls performed by people using judgment, typically involving review and approval.

**Examples:**
- Management review of financial statements and key metrics
- Supervisory approval of journal entries above a threshold
- Three-way match verification (PO, receipt, invoice)
- Account reconciliation preparation and review
- Physical inventory observation and count
- Vendor master data change approval
- Customer credit approval

**Key attributes to test:**
- Was the control performed by the right person (proper authority)?
- Was it performed timely (within the required timeframe)?
- Is there evidence of the review (signature, initials, email, system log)?
- Did the reviewer have sufficient information to perform an effective review?
- Were exceptions identified and appropriately addressed?

### Automated Controls

Controls enforced by IT systems without human intervention.

**Examples:**
- System-enforced approval workflows (cannot proceed without required approvals)
- Three-way match automation (system blocks payment if PO/receipt/invoice don't match)
- Duplicate payment detection (system flags or blocks duplicate invoices)
- Credit limit enforcement (system prevents orders exceeding credit limit)
- Automated calculations (depreciation, amortization, interest, tax)
- System-enforced segregation of duties (conflicting roles prevented)
- Input validation controls (required fields, format checks, range checks)
- Automated reconciliation matching

**Testing approach:**
- Test design: Confirm the system configuration enforces the control as intended
- Test operating effectiveness: For automated controls, if the system configuration has not changed, one test of the control is typically sufficient for the period (supplemented by ITGC testing of change management)
- Verify change management ITGCs are effective (if system changed, re-test the control)

### IT-Dependent Manual Controls

Manual controls that rely on the completeness and accuracy of system-generated information.

**Examples:**
- Management review of a system-generated exception report
- Supervisor review of a system-generated aging report to assess reserves
- Reconciliation using system-generated trial balance data
- Approval of transactions identified by a system-generated workflow

**Testing approach:**
- Test the manual control (review, approval, follow-up on exceptions)
- AND test the completeness and accuracy of the underlying report/data (IPE — Information Produced by the Entity)
- IPE testing confirms the data the reviewer relied on was complete and accurate

### Entity-Level Controls

Broad controls that operate at the organizational level and affect multiple processes.

**Examples:**
- Tone at the top / code of conduct
- Risk assessment process
- Audit committee oversight of financial reporting
- Internal audit function and activities
- Fraud risk assessment and anti-fraud programs
- Whistleblower/ethics hotline
- Management monitoring of control effectiveness
- Financial reporting competence (staffing, training, qualifications)
- Period-end financial reporting process (close procedures, GAAP compliance reviews)

**Significance:**
- Entity-level controls can mitigate but typically cannot replace process-level controls
- Ineffective entity-level controls (especially audit committee oversight and tone at the top) are strong indicators of a material weakness
- Effective entity-level controls may reduce the extent of testing needed for process-level controls$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/close-management', 'business', 'close-management', '', 'close-management', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Close Management

**Important**: This skill assists with close management workflows but does not provide financial advice. All close activities should be reviewed by qualified financial professionals.

Month-end close checklist, task sequencing and dependencies, status tracking, and common close activities organized by day.

## Month-End Close Checklist

### Pre-Close (Last 2-3 Business Days of the Month)

- [ ] Send close calendar and deadline reminders to all contributors
- [ ] Confirm cut-off procedures with AP, AR, payroll, and treasury
- [ ] Verify all sub-systems are processing normally (ERP, payroll, banking)
- [ ] Complete preliminary bank reconciliation (all but last-day activity)
- [ ] Review open purchase orders for potential accrual needs
- [ ] Confirm payroll processing schedule aligns with close timeline
- [ ] Collect information for any known unusual transactions

### Close Day 1 (T+1: First Business Day After Month-End)

- [ ] Confirm all sub-ledger modules have completed period-end processing
- [ ] Run AP accruals for goods/services received but not invoiced
- [ ] Post payroll entries and payroll accrual (if pay period straddles month-end)
- [ ] Record cash receipts and disbursements through month-end
- [ ] Post intercompany transactions and confirm with counterparties
- [ ] Complete bank reconciliation with final bank statement
- [ ] Run fixed asset depreciation
- [ ] Post prepaid expense amortization

### Close Day 2 (T+2)

- [ ] Complete revenue recognition entries and deferred revenue adjustments
- [ ] Post all remaining accrual journal entries
- [ ] Complete AR subledger reconciliation
- [ ] Complete AP subledger reconciliation
- [ ] Record inventory adjustments (if applicable)
- [ ] Post FX revaluation entries for foreign currency balances
- [ ] Begin balance sheet account reconciliations

### Close Day 3 (T+3)

- [ ] Complete all balance sheet reconciliations
- [ ] Post any adjusting journal entries identified during reconciliation
- [ ] Complete intercompany reconciliation and elimination entries
- [ ] Run preliminary trial balance and income statement
- [ ] Perform preliminary flux analysis on income statement
- [ ] Investigate and resolve material variances

### Close Day 4 (T+4)

- [ ] Post tax provision entries (income tax, sales tax, property tax)
- [ ] Complete equity roll-forward (stock compensation, treasury stock)
- [ ] Finalize all journal entries — soft close
- [ ] Generate draft financial statements (P&L, BS, CF)
- [ ] Perform detailed flux analysis and prepare variance explanations
- [ ] Management review of financial statements and key metrics

### Close Day 5 (T+5)

- [ ] Post any final adjustments from management review
- [ ] Finalize financial statements — hard close
- [ ] Lock the period in the ERP/GL system
- [ ] Distribute financial reporting package to stakeholders
- [ ] Update forecasts/projections based on actual results
- [ ] Conduct close retrospective — identify process improvements

## Task Sequencing and Dependencies

### Dependency Map

Tasks are organized by what must complete before the next task can begin:

```
LEVEL 1 (No dependencies — can start immediately at T+1):
├── Cash receipts/disbursements recording
├── Bank statement retrieval
├── Payroll processing/accrual
├── Fixed asset depreciation run
├── Prepaid amortization
├── AP accrual preparation
└── Intercompany transaction posting

LEVEL 2 (Depends on Level 1 completion):
├── Bank reconciliation (needs: cash entries + bank statement)
├── Revenue recognition (needs: billing/delivery data finalized)
├── AR subledger reconciliation (needs: all revenue/cash entries)
├── AP subledger reconciliation (needs: all AP entries/accruals)
├── FX revaluation (needs: all foreign currency entries posted)
└── Remaining accrual JEs (needs: review of all source data)

LEVEL 3 (Depends on Level 2 completion):
├── All balance sheet reconciliations (needs: all JEs posted)
├── Intercompany reconciliation (needs: both sides posted)
├── Adjusting entries from reconciliations
└── Preliminary trial balance

LEVEL 4 (Depends on Level 3 completion):
├── Tax provision (needs: pre-tax income finalized)
├── Equity roll-forward
├── Consolidation and eliminations
├── Draft financial statements
└── Preliminary flux analysis

LEVEL 5 (Depends on Level 4 completion):
├── Management review
├── Final adjustments
├── Hard close / period lock
├── Financial reporting package
└── Forecast updates
```

### Critical Path

The critical path determines the minimum close duration. Typical critical path:

```
Cash/AP/AR entries → Subledger reconciliations → Balance sheet recs →
  Tax provision → Draft financials → Management review → Hard close
```

To shorten the close:
- Automate Level 1 entries (depreciation, prepaid amortization, standard accruals)
- Pre-reconcile accounts during the month (continuous reconciliation)
- Parallel-process independent reconciliations
- Set clear deadlines with consequences for late submissions
- Use standardized templates to reduce reconciliation prep time

## Status Tracking and Reporting

### Close Status Dashboard

Track each close task with the following attributes:

| Task | Owner | Deadline | Status | Blocker | Notes |
|------|-------|----------|--------|---------|-------|
| [Task name] | [Person/role] | [Day T+N] | Not Started / In Progress / Complete / Blocked | [If blocked, what's blocking] | [Any notes] |

### Status Definitions

- **Not Started:** Task has not yet begun (may be waiting on dependencies)
- **In Progress:** Task is actively being worked on
- **Complete:** Task is finished and has been reviewed/approved
- **Blocked:** Task cannot proceed due to a dependency, missing data, or issue
- **At Risk:** Task is in progress but may not meet its deadline

### Daily Close Status Meeting (Recommended)

During the close period, hold a brief (15-minute) daily standup:

1. **Review status board:** Walk through open tasks, flag any that are behind
2. **Identify blockers:** Surface any issues preventing task completion
3. **Reassign or escalate:** Adjust ownership or escalate blockers to resolve quickly
4. **Update timeline:** If any tasks are at risk, assess impact on overall close timeline

### Close Metrics to Track Over Time

| Metric | Definition | Target |
|--------|-----------|--------|
| Close duration | Business days from period end to hard close | Reduce over time |
| # of adjusting entries after soft close | Entries posted during management review | Minimize |
| # of late tasks | Tasks completed after their deadline | Zero |
| # of reconciliation exceptions | Reconciling items requiring investigation | Reduce over time |
| # of restatements / corrections | Errors found after close | Zero |

## Common Close Activities by Day

### Typical 5-Day Close Calendar

| Day | Key Activities | Responsible |
|-----|---------------|-------------|
| **T+1** | Cash entries, payroll, AP accruals, depreciation, prepaid amortization, intercompany posting | Staff accountants, payroll |
| **T+2** | Revenue recognition, remaining accruals, subledger reconciliations (AR, AP, FA), FX revaluation | Revenue accountant, AP/AR, treasury |
| **T+3** | Balance sheet reconciliations, intercompany reconciliation, eliminations, preliminary trial balance, preliminary flux | Accounting team, consolidation |
| **T+4** | Tax provision, equity roll-forward, draft financial statements, detailed flux analysis, management review | Tax, controller, FP&A |
| **T+5** | Final adjustments, hard close, period lock, reporting package distribution, forecast update, retrospective | Controller, FP&A, finance leadership |

### Accelerated Close (3-Day Target)

For organizations targeting a faster close:

| Day | Key Activities |
|-----|---------------|
| **T+1** | All JEs posted (automated + manual), all subledger reconciliations, bank reconciliation, intercompany reconciliation, preliminary trial balance |
| **T+2** | All balance sheet reconciliations, tax provision, consolidation, draft financial statements, flux analysis, management review |
| **T+3** | Final adjustments, hard close, reporting package, forecast update |

**Prerequisites for a 3-day close:**
- Automated recurring journal entries (depreciation, amortization, standard accruals)
- Continuous reconciliation during the month (not all at month-end)
- Automated intercompany elimination
- Pre-close activities completed before month-end (cut-off, accrual estimates)
- Empowered team with clear ownership and minimal handoffs
- Real-time or near-real-time sub-system integration

## Close Process Improvement

### Common Bottlenecks and Solutions

| Bottleneck | Root Cause | Solution |
|-----------|-----------|---------|
| Late AP accruals | Waiting for department spend confirmation | Implement continuous accrual estimation; set cut-off deadlines |
| Manual journal entries | Recurring entries prepared manually each month | Automate standard recurring entries in the ERP |
| Slow reconciliations | Starting from scratch each month | Implement continuous/rolling reconciliation |
| Intercompany delays | Waiting for counterparty confirmation | Automate intercompany matching; set stricter deadlines |
| Management review changes | Large adjustments found during review | Improve preliminary review process; empower team to catch issues earlier |
| Missing supporting documents | Scrambling for documentation at close | Maintain documentation throughout the month |

### Close Retrospective Questions

After each close, ask:
1. What went well this close that we should continue?
2. What took longer than expected and why?
3. What blockers did we encounter and how can we prevent them?
4. Were there any surprises in the financial results we should have caught earlier?
5. What can we automate or streamline for next month?$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/financial-statements', 'business', 'financial-statements', '', 'financial-statements', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /financial-statements

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

**Important**: This command assists with financial statement workflows but does not provide financial advice. All statements should be reviewed by qualified financial professionals before use in reporting or filings.

Generate financial statements with period-over-period comparison and variance analysis. The workflow below walks through income statement generation; balance sheet and cash flow statement reference formats, GAAP presentation requirements (ASC 220/210/230), and common period-end adjustments are included as supporting reference material.

## Usage

```
/financial-statements <period-type> <period>
```

### Arguments

- `period-type` — The reporting period type:
  - `monthly` — Single month P&L with prior month and prior year month comparison
  - `quarterly` — Quarter P&L with prior quarter and prior year quarter comparison
  - `annual` — Full year P&L with prior year comparison
  - `ytd` — Year-to-date P&L with prior year YTD comparison
- `period` — The period to report (e.g., `2024-12`, `2024-Q4`, `2024`)

## Workflow

### 1. Gather Financial Data

If ~~erp or ~~data warehouse is connected:
- Pull trial balance or income statement data for the specified period
- Pull comparison period data (prior period, prior year, budget/forecast)
- Pull account hierarchy and groupings for presentation

If no data source is connected:
> Connect ~~erp or ~~data warehouse to pull financial data automatically. You can also paste trial balance data, upload a spreadsheet, or provide income statement data for analysis.

Prompt the user to provide:
- Current period revenue and expense data (by account or category)
- Comparison period data (prior period, prior year, and/or budget)
- Any known adjustments or reclassifications

### 2. Generate Income Statement

Present in standard multi-column format:

```
INCOME STATEMENT
Period: [Period description]
(in thousands, unless otherwise noted)

                              Current    Prior      Variance   Variance   Budget    Budget
                              Period     Period     ($)        (%)        Amount    Var ($)
                              --------   --------   --------   --------   --------  --------
REVENUE
  Product revenue             $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Service revenue             $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Other revenue               $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
                              --------   --------   --------              --------  --------
TOTAL REVENUE                 $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX

COST OF REVENUE
  [Cost items]                $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
                              --------   --------   --------              --------  --------
GROSS PROFIT                  $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Gross Margin                XX.X%      XX.X%

OPERATING EXPENSES
  Research & development      $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Sales & marketing           $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  General & administrative    $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
                              --------   --------   --------              --------  --------
TOTAL OPERATING EXPENSES      $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX

OPERATING INCOME (LOSS)       $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Operating Margin            XX.X%      XX.X%

OTHER INCOME (EXPENSE)
  Interest income             $XX,XXX    $XX,XXX    $X,XXX     X.X%
  Interest expense           ($XX,XXX)  ($XX,XXX)   $X,XXX     X.X%
  Other, net                  $XX,XXX    $XX,XXX    $X,XXX     X.X%
                              --------   --------   --------
TOTAL OTHER INCOME (EXPENSE)  $XX,XXX    $XX,XXX    $X,XXX     X.X%

INCOME BEFORE TAXES           $XX,XXX    $XX,XXX    $X,XXX     X.X%
  Income tax expense          $XX,XXX    $XX,XXX    $X,XXX     X.X%
                              --------   --------   --------

NET INCOME (LOSS)             $XX,XXX    $XX,XXX    $X,XXX     X.X%       $XX,XXX   $X,XXX
  Net Margin                  XX.X%      XX.X%
```

### 3. Variance Analysis

For each line item, calculate and flag material variances.

#### Variance Calculation

For each line item, calculate:
- **Dollar variance:** Current period - Prior period (or current period - budget)
- **Percentage variance:** (Current - Prior) / |Prior| x 100
- **Basis point change:** For margins and ratios, express change in basis points (1 bp = 0.01%)

#### Materiality Thresholds

Define what constitutes a "material" variance requiring investigation. Common approaches:

- **Fixed dollar threshold:** Variances exceeding a set dollar amount (e.g., $50K, $100K)
- **Percentage threshold:** Variances exceeding a set percentage (e.g., 10%, 15%)
- **Combined:** Either the dollar OR percentage threshold is exceeded
- **Scaled:** Different thresholds for different line items based on their size and volatility

*Example thresholds (adjust for your organization):*

| Line Item Size | Dollar Threshold | Percentage Threshold |
|---------------|-----------------|---------------------|
| > $10M        | $500K           | 5%                  |
| $1M - $10M    | $100K           | 10%                 |
| < $1M         | $50K            | 15%                 |

#### Variance Decomposition

Break down total variance into component drivers:

- **Volume/quantity effect:** Change in volume at prior period rates
- **Rate/price effect:** Change in rate/price at current period volume
- **Mix effect:** Shift in composition between items with different rates/margins
- **New/discontinued items:** Items present in one period but not the other
- **One-time/non-recurring items:** Items that are not expected to repeat
- **Timing effect:** Items shifting between periods (not a true change in run rate)
- **Currency effect:** Impact of FX rate changes on translated results

#### Investigation and Narrative

For each material variance:
1. Quantify the variance ($ and %)
2. Identify whether favorable or unfavorable
3. Decompose into drivers using the categories above
4. Provide a narrative explanation of the business reason
5. Assess whether the variance is temporary or represents a trend change
6. Note any actions required (further investigation, forecast update, process change)

### 4. Key Metrics Summary

```
KEY METRICS
                              Current    Prior      Change
Revenue growth (%)                                  X.X%
Gross margin (%)              XX.X%      XX.X%      X.X pp
Operating margin (%)          XX.X%      XX.X%      X.X pp
Net margin (%)                XX.X%      XX.X%      X.X pp
OpEx as % of revenue          XX.X%      XX.X%      X.X pp
Effective tax rate (%)        XX.X%      XX.X%      X.X pp
```

### 5. Material Variance Summary

List all material variances requiring investigation:

| Line Item | Variance ($) | Variance (%) | Direction | Preliminary Driver | Action |
|-----------|-------------|-------------|-----------|-------------------|--------|
| [Item]    | $X,XXX      | X.X%        | Unfav.    | [If known]        | Investigate |

### 6. Output

Provide:
1. Formatted income statement with comparisons
2. Key metrics summary
3. Material variance listing with investigation flags
4. Suggested follow-up questions for unexplained variances
5. Offer to drill into any specific variance with `/flux`

## GAAP Presentation Requirements

### Income Statement (ASC 220 / IAS 1)

- Present all items of income and expense recognized in a period
- Classify expenses either by nature (materials, labor, depreciation) or by function (COGS, R&D, S&M, G&A) — function is more common for US companies
- If classified by function, disclose depreciation, amortization, and employee benefit costs by nature in the notes
- Present operating and non-operating items separately
- Show income tax expense as a separate line
- Extraordinary items are prohibited under both US GAAP and IFRS
- Discontinued operations presented separately, net of tax

**Common presentation considerations:**

- **Revenue disaggregation:** ASC 606 requires disaggregation of revenue into categories that depict how the nature, amount, timing, and uncertainty of revenue are affected by economic factors
- **Stock-based compensation:** Classify within the functional expense categories (R&D, S&M, G&A) with total SBC disclosed in notes
- **Restructuring charges:** Present separately if material, or include in operating expenses with note disclosure
- **Non-GAAP adjustments:** If presenting non-GAAP measures (common in earnings releases), clearly label and reconcile to GAAP

### Balance Sheet (ASC 210 / IAS 1)

- Distinguish between current and non-current assets and liabilities
- Current: expected to be realized, consumed, or settled within 12 months (or the operating cycle if longer)
- Present assets in order of liquidity (most liquid first) — standard US practice
- Accounts receivable shown net of allowance for credit losses (ASC 326)
- Property and equipment shown net of accumulated depreciation
- Goodwill is not amortized — tested for impairment annually (ASC 350)
- Leases: recognize right-of-use assets and lease liabilities for operating and finance leases (ASC 842)

### Cash Flow Statement (ASC 230 / IAS 7)

- Indirect method is most common (start with net income, adjust for non-cash items)
- Direct method is permitted but rarely used (requires supplemental indirect reconciliation)
- Interest paid and income taxes paid must be disclosed (either on the face or in notes)
- Non-cash investing and financing activities disclosed separately (e.g., assets acquired under leases, stock issued for acquisitions)
- Cash equivalents: short-term, highly liquid investments with original maturities of 3 months or less

## Balance Sheet Reference Format

```
ASSETS
Current Assets
  Cash and cash equivalents
  Short-term investments
  Accounts receivable, net
  Inventory
  Prepaid expenses and other current assets
Total Current Assets

Non-Current Assets
  Property and equipment, net
  Operating lease right-of-use assets
  Goodwill
  Intangible assets, net
  Long-term investments
  Other non-current assets
Total Non-Current Assets

TOTAL ASSETS

LIABILITIES AND STOCKHOLDERS' EQUITY
Current Liabilities
  Accounts payable
  Accrued liabilities
  Deferred revenue, current portion
  Current portion of long-term debt
  Operating lease liabilities, current portion
  Other current liabilities
Total Current Liabilities

Non-Current Liabilities
  Long-term debt
  Deferred revenue, non-current
  Operating lease liabilities, non-current
  Other non-current liabilities
Total Non-Current Liabilities

Total Liabilities

Stockholders' Equity
  Common stock
  Additional paid-in capital
  Retained earnings (accumulated deficit)
  Accumulated other comprehensive income (loss)
  Treasury stock
Total Stockholders' Equity

TOTAL LIABILITIES AND STOCKHOLDERS' EQUITY
```

## Cash Flow Statement Reference Format (Indirect Method)

```
CASH FLOWS FROM OPERATING ACTIVITIES
Net income (loss)
Adjustments to reconcile net income to net cash from operations:
  Depreciation and amortization
  Stock-based compensation
  Amortization of debt issuance costs
  Deferred income taxes
  Loss (gain) on disposal of assets
  Impairment charges
  Other non-cash items
Changes in operating assets and liabilities:
  Accounts receivable
  Inventory
  Prepaid expenses and other assets
  Accounts payable
  Accrued liabilities
  Deferred revenue
  Other liabilities
Net Cash Provided by (Used in) Operating Activities

CASH FLOWS FROM INVESTING ACTIVITIES
  Purchases of property and equipment
  Purchases of investments
  Proceeds from sale/maturity of investments
  Acquisitions, net of cash acquired
  Other investing activities
Net Cash Provided by (Used in) Investing Activities

CASH FLOWS FROM FINANCING ACTIVITIES
  Proceeds from issuance of debt
  Repayment of debt
  Proceeds from issuance of common stock
  Repurchases of common stock
  Dividends paid
  Payment of debt issuance costs
  Other financing activities
Net Cash Provided by (Used in) Financing Activities

Effect of exchange rate changes on cash

Net Increase (Decrease) in Cash and Cash Equivalents
Cash and cash equivalents, beginning of period
Cash and cash equivalents, end of period
```

## Common Adjustments and Reclassifications

### Period-End Adjustments

1. **Accruals:** Record expenses incurred but not yet paid (AP accruals, payroll accruals, interest accruals)
2. **Deferrals:** Adjust prepaid expenses, deferred revenue, and deferred costs for the period
3. **Depreciation and amortization:** Book periodic depreciation/amortization from fixed asset and intangible schedules
4. **Bad debt provision:** Adjust allowance for credit losses based on aging analysis and historical loss rates
5. **Inventory adjustments:** Record write-downs for obsolete, slow-moving, or impaired inventory
6. **FX revaluation:** Revalue foreign-currency-denominated monetary assets and liabilities at period-end rates
7. **Tax provision:** Record current and deferred income tax expense
8. **Fair value adjustments:** Mark-to-market investments, derivatives, and other fair-value items

### Reclassifications

1. **Current/non-current reclassification:** Reclassify long-term debt maturing within 12 months to current
2. **Contra account netting:** Net allowances against gross receivables, accumulated depreciation against gross assets
3. **Intercompany elimination:** Eliminate intercompany balances and transactions in consolidation
4. **Discontinued operations:** Reclassify results of discontinued operations to a separate line item
5. **Equity method adjustments:** Record share of investee income/loss for equity method investments
6. **Segment reclassifications:** Ensure transactions are properly classified by operating segment$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/journal-entry', 'business', 'journal-entry', '', 'journal-entry', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Journal Entry Preparation

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

**Important**: This command assists with journal entry workflows but does not provide financial advice. All entries should be reviewed by qualified financial professionals before posting.

Prepare journal entries with proper debits, credits, supporting detail, and review documentation.

## Usage

```
/je <type> <period>
```

### Arguments

- `type` — The journal entry type. One of:
  - `ap-accrual` — Accounts payable accruals for goods/services received but not yet invoiced
  - `fixed-assets` — Depreciation and amortization entries for fixed assets and intangibles
  - `prepaid` — Amortization of prepaid expenses (insurance, software, rent, etc.)
  - `payroll` — Payroll accruals including salaries, benefits, taxes, and bonus accruals
  - `revenue` — Revenue recognition entries including deferred revenue adjustments
- `period` — The accounting period (e.g., `2024-12`, `2024-Q4`, `2024`)

## Workflow

### 1. Gather Source Data

If ~~erp or ~~data warehouse is connected:
- Pull the trial balance for the specified period
- Pull subledger detail for the relevant accounts
- Pull prior period entries of the same type for reference
- Identify the current GL balances for affected accounts

If no data source is connected:
> Connect ~~erp or ~~data warehouse to pull GL data automatically. You can also paste trial balance data or upload a spreadsheet.

Prompt the user to provide:
- Trial balance or GL balances for affected accounts
- Subledger detail or supporting schedules
- Prior period entries for reference (optional)

### 2. Calculate the Entry

Based on the JE type:

**AP Accrual:**
- Identify goods/services received but not invoiced by period end
- Calculate accrual amounts from PO receipts, contracts, or estimates
- Debit: Expense accounts (or asset accounts for capitalizable items)
- Credit: Accrued liabilities

**Fixed Assets:**
- Pull the fixed asset register or depreciation schedule
- Calculate period depreciation by asset class and method (straight-line, declining balance, units of production)
- Debit: Depreciation expense (by department/cost center)
- Credit: Accumulated depreciation

**Prepaid:**
- Pull the prepaid amortization schedule
- Calculate the period amortization for each prepaid item
- Debit: Expense accounts (by type — insurance, software, rent, etc.)
- Credit: Prepaid expense accounts

**Payroll:**
- Calculate accrued salaries for days worked but not yet paid
- Calculate accrued benefits (health, retirement contributions, PTO)
- Calculate employer payroll tax accruals
- Calculate bonus accruals (if applicable, based on plan terms)
- Debit: Salary expense, benefits expense, payroll tax expense
- Credit: Accrued payroll, accrued benefits, accrued payroll taxes

**Revenue:**
- Review contracts and performance obligations
- Calculate revenue to recognize based on delivery/performance
- Adjust deferred revenue balances
- Debit: Deferred revenue (or accounts receivable)
- Credit: Revenue accounts (by stream/category)

### 3. Generate the Journal Entry

Present the entry in standard format:

```
Journal Entry: [Type] — [Period]
Prepared by: [User]
Date: [Period end date]

| Line | Account Code | Account Name | Debit | Credit | Department | Memo |
|------|-------------|--------------|-------|--------|------------|------|
| 1    | XXXX        | [Name]       | X,XXX |        | [Dept]     | [Detail] |
| 2    | XXXX        | [Name]       |       | X,XXX  | [Dept]     | [Detail] |
|      |             | **Total**    | X,XXX | X,XXX  |            |      |

Supporting Detail:
- [Calculation basis and assumptions]
- [Reference to supporting schedule or documentation]

Reversal: [Yes/No — if yes, specify reversal date]
```

### 4. Review Checklist

Before finalizing, verify:

- [ ] Debits equal credits
- [ ] Correct accounting period
- [ ] Account codes are valid and map to the right GL accounts
- [ ] Amounts are calculated correctly with supporting detail
- [ ] Memo/description is clear and specific enough for audit
- [ ] Department/cost center coding is correct
- [ ] Entry is consistent with prior period treatment
- [ ] Reversal flag is set appropriately (accruals should auto-reverse)
- [ ] Supporting documentation is referenced or attached
- [ ] Entry is within the user's approval authority
- [ ] No unusual or out-of-pattern amounts that need investigation

### 5. Output

Provide:
1. The formatted journal entry
2. Supporting calculations
3. Comparison to prior period entry of the same type (if available)
4. Any items flagged for review or follow-up
5. Instructions for posting (manual entry or upload format for the user's ERP)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/journal-entry-prep', 'business', 'journal-entry-prep', '', 'journal-entry-prep', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Journal Entry Preparation

**Important**: This skill assists with journal entry workflows but does not provide financial advice. All entries should be reviewed by qualified financial professionals before posting.

Best practices, standard entry types, documentation requirements, and review workflows for journal entry preparation.

## Standard Accrual Types and Their Entries

### Accounts Payable Accruals

Accrue for goods or services received but not yet invoiced at period end.

**Typical entry:**
- Debit: Expense account (or capitalize if asset-qualifying)
- Credit: Accrued liabilities

**Sources for calculation:**
- Open purchase orders with confirmed receipts
- Contracts with services rendered but unbilled
- Recurring vendor arrangements (utilities, subscriptions, professional services)
- Employee expense reports submitted but not yet processed

**Key considerations:**
- Reverse in the following period (auto-reversal recommended)
- Use consistent estimation methodology period over period
- Document basis for estimates (PO amount, contract terms, historical run-rate)
- Track actual vs accrual to refine future estimates

### Fixed Asset Depreciation

Book periodic depreciation expense for tangible and intangible assets.

**Typical entry:**
- Debit: Depreciation/amortization expense (by department or cost center)
- Credit: Accumulated depreciation/amortization

**Depreciation methods:**
- **Straight-line:** (Cost - Salvage) / Useful life — most common for financial reporting
- **Declining balance:** Accelerated method applying fixed rate to net book value
- **Units of production:** Based on actual usage or output vs total expected

**Key considerations:**
- Run depreciation from the fixed asset register or schedule
- Verify new additions are set up with correct useful life and method
- Check for disposals or impairments requiring write-off
- Ensure consistency between book and tax depreciation tracking

### Prepaid Expense Amortization

Amortize prepaid expenses over their benefit period.

**Typical entry:**
- Debit: Expense account (insurance, software, rent, etc.)
- Credit: Prepaid expense

**Common prepaid categories:**
- Insurance premiums (typically 12-month policies)
- Software licenses and subscriptions
- Prepaid rent (if applicable under lease terms)
- Prepaid maintenance contracts
- Conference and event deposits

**Key considerations:**
- Maintain an amortization schedule with start/end dates and monthly amounts
- Review for any prepaid items that should be fully expensed (immaterial amounts)
- Check for cancelled or terminated contracts requiring accelerated amortization
- Verify new prepaids are added to the schedule promptly

### Payroll Accruals

Accrue compensation and related costs for the period.

**Typical entries:**

*Salary accrual (for pay periods not aligned with month-end):*
- Debit: Salary expense (by department)
- Credit: Accrued payroll

*Bonus accrual:*
- Debit: Bonus expense (by department)
- Credit: Accrued bonus

*Benefits accrual:*
- Debit: Benefits expense
- Credit: Accrued benefits

*Payroll tax accrual:*
- Debit: Payroll tax expense
- Credit: Accrued payroll taxes

**Key considerations:**
- Calculate salary accrual based on working days in the period vs pay period
- Bonus accruals should reflect plan terms (target amounts, performance metrics, payout timing)
- Include employer-side taxes and benefits (FICA, FUTA, health, 401k match)
- Track PTO/vacation accrual liability if required by policy or jurisdiction

### Revenue Recognition

Recognize revenue based on performance obligations and delivery.

**Typical entries:**

*Recognize previously deferred revenue:*
- Debit: Deferred revenue
- Credit: Revenue

*Recognize revenue with new receivable:*
- Debit: Accounts receivable
- Credit: Revenue

*Defer revenue received in advance:*
- Debit: Cash / Accounts receivable
- Credit: Deferred revenue

**Key considerations:**
- Follow ASC 606 five-step framework for contracts with customers
- Identify distinct performance obligations in each contract
- Determine transaction price (including variable consideration)
- Allocate transaction price to performance obligations
- Recognize revenue as/when performance obligations are satisfied
- Maintain contract-level detail for audit support

## Supporting Documentation Requirements

Every journal entry should have:

1. **Entry description/memo:** Clear, specific description of what the entry records and why
2. **Calculation support:** How amounts were derived (formula, schedule, source data reference)
3. **Source documents:** Reference to the underlying transactions or events (PO numbers, invoice numbers, contract references, payroll register)
4. **Period:** The accounting period the entry applies to
5. **Preparer identification:** Who prepared the entry and when
6. **Approval:** Evidence of review and approval per the authorization matrix
7. **Reversal indicator:** Whether the entry auto-reverses and the reversal date

## Review and Approval Workflows

### Typical Approval Matrix

| Entry Type | Amount Threshold | Approver |
|-----------|-----------------|----------|
| Standard recurring | Any amount | Accounting manager |
| Non-recurring / manual | < $50K | Accounting manager |
| Non-recurring / manual | $50K - $250K | Controller |
| Non-recurring / manual | > $250K | CFO / VP Finance |
| Top-side / consolidation | Any amount | Controller or above |
| Out-of-period adjustments | Any amount | Controller or above |

*Note: Thresholds should be set based on your organization's materiality and risk tolerance.*

### Review Checklist

Before approving a journal entry, the reviewer should verify:

- [ ] Debits equal credits (entry is balanced)
- [ ] Correct accounting period (not posting to a closed period)
- [ ] Account codes exist and are appropriate for the transaction
- [ ] Amounts are mathematically accurate and supported by calculations
- [ ] Description is clear, specific, and sufficient for audit purposes
- [ ] Department/cost center/project coding is correct
- [ ] Treatment is consistent with prior periods and accounting policies
- [ ] Auto-reversal is set appropriately (accruals should reverse)
- [ ] Supporting documentation is complete and referenced
- [ ] Entry amount is within the preparer's authority level
- [ ] No duplicate of an existing entry
- [ ] Unusual or large amounts are explained and justified

## Common Errors to Check For

1. **Unbalanced entries:** Debits do not equal credits (system should prevent, but check manual entries)
2. **Wrong period:** Entry posted to an incorrect or already-closed period
3. **Wrong sign:** Debit entered as credit or vice versa
4. **Duplicate entries:** Same transaction recorded twice (check for duplicates before posting)
5. **Wrong account:** Entry posted to incorrect GL account (especially similar account codes)
6. **Missing reversal:** Accrual entry not set to auto-reverse, causing double-counting
7. **Stale accruals:** Recurring accruals not updated for changed circumstances
8. **Round-number estimates:** Suspiciously round amounts that may not reflect actual calculations
9. **Incorrect FX rates:** Foreign currency entries using wrong exchange rate or date
10. **Missing intercompany elimination:** Entries between entities without corresponding elimination
11. **Capitalization errors:** Expenses that should be capitalized, or capitalized items that should be expensed
12. **Cut-off errors:** Transactions recorded in the wrong period based on delivery or service date$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/reconciliation', 'business', 'reconciliation', '', 'reconciliation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Reconciliation

**Important**: This skill assists with reconciliation workflows but does not provide financial advice. All reconciliations should be reviewed by qualified financial professionals before sign-off.

Methodology and best practices for account reconciliation, including GL-to-subledger, bank reconciliations, and intercompany. Covers reconciling item categorization, aging analysis, and escalation.

## Reconciliation Types

### GL to Subledger Reconciliation

Compare the general ledger control account balance to the detailed subledger balance.

**Common accounts:**
- Accounts receivable (GL control vs AR subledger aging)
- Accounts payable (GL control vs AP subledger aging)
- Fixed assets (GL control vs fixed asset register)
- Inventory (GL control vs inventory valuation report)
- Prepaid expenses (GL control vs prepaid amortization schedule)
- Accrued liabilities (GL control vs accrual detail schedules)

**Process:**
1. Pull GL balance for the control account as of period end
2. Pull subledger trial balance or detail report as of the same date
3. Compare totals — they should match if posting is real-time
4. Investigate any differences (timing of posting, manual entries not reflected, interface errors)

**Common causes of differences:**
- Manual journal entries posted to the control account but not reflected in the subledger
- Subledger transactions not yet interfaced to the GL
- Timing differences in batch posting
- Reclassification entries in the GL without subledger adjustment
- System interface errors or failed postings

### Bank Reconciliation

Compare the GL cash balance to the bank statement balance.

**Process:**
1. Obtain the bank statement balance as of period end
2. Pull the GL cash account balance as of the same date
3. Identify outstanding checks (issued but not cleared at the bank)
4. Identify deposits in transit (recorded in GL but not yet credited by bank)
5. Identify bank charges, interest, or adjustments not yet recorded in GL
6. Reconcile both sides to an adjusted balance

**Standard format:**

```
Balance per bank statement:         $XX,XXX
Add: Deposits in transit            $X,XXX
Less: Outstanding checks           ($X,XXX)
Add/Less: Bank errors               $X,XXX
Adjusted bank balance:              $XX,XXX

Balance per general ledger:         $XX,XXX
Add: Interest/credits not recorded  $X,XXX
Less: Bank fees not recorded       ($X,XXX)
Add/Less: GL errors                 $X,XXX
Adjusted GL balance:                $XX,XXX

Difference:                         $0.00
```

### Intercompany Reconciliation

Reconcile balances between related entities to ensure they net to zero on consolidation.

**Process:**
1. Pull intercompany receivable/payable balances for each entity pair
2. Compare Entity A's receivable from Entity B to Entity B's payable to Entity A
3. Identify and resolve differences
4. Confirm all intercompany transactions have been recorded on both sides
5. Verify elimination entries are correct for consolidation

**Common causes of differences:**
- Transactions recorded by one entity but not the other (timing)
- Different FX rates used by each entity
- Misclassification (intercompany vs third-party)
- Disputed amounts or unapplied payments
- Different period-end cut-off practices across entities

## Reconciling Item Categorization

### Category 1: Timing Differences

Items that exist because of normal processing timing and will clear without action:

- **Outstanding checks:** Checks issued and recorded in GL, pending bank clearance
- **Deposits in transit:** Deposits made and recorded in GL, pending bank credit
- **In-transit transactions:** Items posted in one system but pending interface to the other
- **Pending approvals:** Transactions awaiting approval to post in one system

**Expected resolution:** These items should clear within the normal processing cycle (typically 1-5 business days). No adjusting entry needed.

### Category 2: Adjustments Required

Items that require a journal entry to correct:

- **Unrecorded bank charges:** Bank fees, wire charges, returned item fees
- **Unrecorded interest:** Interest income or expense from bank/lender
- **Recording errors:** Wrong amount, wrong account, duplicates
- **Missing entries:** Transactions in one system with no corresponding entry in the other
- **Classification errors:** Correctly recorded but in the wrong account

**Action:** Prepare adjusting journal entry to correct the GL or subledger.

### Category 3: Requires Investigation

Items that cannot be immediately explained:

- **Unidentified differences:** Variances with no obvious cause
- **Disputed items:** Amounts contested between parties
- **Aged outstanding items:** Items that have not cleared within expected timeframes
- **Recurring unexplained differences:** Same type of difference appearing each period

**Action:** Investigate root cause, document findings, escalate if unresolved.

## Aging Analysis for Outstanding Items

Track the age of reconciling items to identify stale items requiring escalation:

| Age Bucket | Status | Action |
|-----------|--------|--------|
| 0-30 days | Current | Monitor — within normal processing cycle |
| 31-60 days | Aging | Investigate — follow up on why item has not cleared |
| 61-90 days | Overdue | Escalate — notify supervisor, document investigation |
| 90+ days | Stale | Escalate to management — potential write-off or adjustment needed |

### Aging Report Format

| Item # | Description | Amount | Date Originated | Age (Days) | Category | Status | Owner |
|--------|-------------|--------|-----------------|------------|----------|--------|-------|
| 1      | [Detail]    | $X,XXX | [Date]          | XX         | [Type]   | [Status] | [Name] |

### Trending

Track reconciling item totals over time to identify growing balances:

- Compare total outstanding items to prior period
- Flag if total reconciling items exceed materiality threshold
- Flag if number of items is growing period over period
- Identify recurring items that appear every period (may indicate process issue)

## Escalation Thresholds

Define escalation triggers based on your organization's risk tolerance:

| Trigger | Threshold (Example) | Escalation |
|---------|---------------------|------------|
| Individual item amount | > $10,000 | Supervisor review |
| Individual item amount | > $50,000 | Controller review |
| Total reconciling items | > $100,000 | Controller review |
| Item age | > 60 days | Supervisor follow-up |
| Item age | > 90 days | Controller / management review |
| Unreconciled difference | Any amount | Cannot close — must resolve or document |
| Growing trend | 3+ consecutive periods | Process improvement investigation |

*Note: Set thresholds based on your organization's materiality level and risk appetite. The examples above are illustrative.*

## Reconciliation Best Practices

1. **Timeliness:** Complete reconciliations within the close calendar deadline (typically T+3 to T+5 business days after period end)
2. **Completeness:** Reconcile all balance sheet accounts on a defined frequency (monthly for material accounts, quarterly for immaterial)
3. **Documentation:** Every reconciliation should include preparer, reviewer, date, and clear explanation of all reconciling items
4. **Segregation:** The person who reconciles should not be the same person who processes transactions in that account
5. **Follow-through:** Track open items to resolution — do not just carry items forward indefinitely
6. **Root cause analysis:** For recurring reconciling items, investigate and fix the underlying process issue
7. **Standardization:** Use consistent templates and procedures across all accounts
8. **Retention:** Maintain reconciliations and supporting detail per your organization's document retention policy$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/sox-testing', 'business', 'sox-testing', '', 'sox-testing', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# SOX Compliance Testing

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

**Important**: This command assists with SOX compliance workflows but does not provide audit or legal advice. All testing workpapers and assessments should be reviewed by qualified financial professionals before use in audit documentation.

Generate sample selections, create testing workpapers, document control assessments, and provide testing templates for SOX 404 internal controls over financial reporting.

## Usage

```
/sox <control-area> <period>
```

### Arguments

- `control-area` — The control area to test:
  - `revenue-recognition` — Revenue cycle controls (order-to-cash)
  - `procure-to-pay` or `p2p` — Procurement and AP controls (purchase-to-pay)
  - `payroll` — Payroll processing and compensation controls
  - `financial-close` — Period-end close and reporting controls
  - `treasury` — Cash management and treasury controls
  - `fixed-assets` — Capital asset lifecycle controls
  - `inventory` — Inventory valuation and management controls
  - `itgc` — IT general controls (access, change management, operations)
  - `entity-level` — Entity-level and monitoring controls
  - `journal-entries` — Journal entry processing controls
  - Any specific control ID or name
- `period` — The testing period (e.g., `2024-Q4`, `2024`, `2024-H2`)

## Workflow

### 1. Identify Controls to Test

Based on the control area, identify the key controls. Present the control matrix:

| Control # | Control Description | Type | Frequency | Key/Non-Key | Risk | Assertion |
|-----------|-------------------|------|-----------|-------------|------|-----------|
| [ID]      | [Description]     | Manual/Automated/IT-Dependent | Daily/Weekly/Monthly/Quarterly/Annual | Key | High/Medium/Low | [CEAVOP] |

**Control types:**
- **Automated:** System-enforced controls with no manual intervention
- **Manual:** Controls performed by personnel with judgment
- **IT-dependent manual:** Manual controls that rely on system-generated data

**Assertions (CEAVOP):**
- **C**ompleteness — All transactions are recorded
- **E**xistence/Occurrence — Transactions actually occurred
- **A**ccuracy — Amounts are correctly recorded
- **V**aluation — Assets/liabilities are properly valued
- **O**bligations/Rights — Entity has rights to assets, obligations for liabilities
- **P**resentation/Disclosure — Properly classified and disclosed

### 2. Determine Sample Size

Calculate sample sizes based on control frequency and risk:

| Control Frequency | Population Size (approx.) | Recommended Sample |
|------------------|--------------------------|-------------------|
| Annual           | 1                        | 1 (test the instance) |
| Quarterly        | 4                        | 2 |
| Monthly          | 12                       | 2-4 (based on risk) |
| Weekly           | 52                       | 5-15 (based on risk) |
| Daily            | ~250                     | 20-40 (based on risk) |
| Per-transaction  | Varies                   | 25-60 (based on risk and volume) |

Adjust for:
- **Risk level:** Higher risk controls require larger samples
- **Prior year results:** Controls with prior deficiencies need larger samples
- **Reliance:** Controls relied upon by external auditors may need larger samples

### 3. Generate Sample Selection

Select samples from the population using the appropriate method:

**Random selection** (default for transaction-level controls):
- Generate random numbers to select specific items from the population
- Ensure coverage across the full period

**Systematic selection** (for periodic controls):
- Select items at fixed intervals with a random start point
- Ensure representation across all sub-periods

**Targeted selection** (supplement to random, for risk-based testing):
- Select items with specific risk characteristics (high dollar, unusual, period-end)
- Document rationale for targeted selections

Present the sample:

```
SAMPLE SELECTION
Control: [Control ID] — [Description]
Period: [Testing period]
Population: [Count] items, $[Total value]
Sample size: [N] items
Selection method: [Random/Systematic/Targeted]

| Sample # | Transaction Date | Reference/ID | Amount | Selection Basis |
|----------|-----------------|--------------|--------|-----------------|
| 1        | [Date]          | [Ref]        | $X,XXX | Random          |
| 2        | [Date]          | [Ref]        | $X,XXX | Random          |
| ...      | ...             | ...          | ...    | ...             |
```

### 4. Create Testing Workpaper

Generate a testing template for each control:

```
SOX CONTROL TESTING WORKPAPER
==============================
Control #: [ID]
Control Description: [Full description of the control activity]
Control Owner: [Role/title — to be filled by tester]
Control Type: [Manual/Automated/IT-Dependent Manual]
Frequency: [How often the control operates]
Key Control: [Yes/No]
Relevant Assertion(s): [CEAVOP]
Testing Period: [Period]

TEST OBJECTIVE:
To determine whether [control description] operated effectively throughout the testing period.

TEST PROCEDURES:
1. [Step 1 — What to inspect, examine, or re-perform]
2. [Step 2 — What evidence to obtain]
3. [Step 3 — What to compare or verify]
4. [Step 4 — How to evaluate completeness of performance]
5. [Step 5 — How to assess timeliness of performance]

EXPECTED EVIDENCE:
- [Document type 1 — e.g., signed approval form]
- [Document type 2 — e.g., system screenshot showing review]
- [Document type 3 — e.g., reconciliation with preparer sign-off]

TEST RESULTS:

| Sample # | Ref | Procedure 1 | Procedure 2 | Procedure 3 | Result | Exception? | Notes |
|----------|-----|-------------|-------------|-------------|--------|------------|-------|
| 1        |     | Pass/Fail   | Pass/Fail   | Pass/Fail   | Pass/Fail | Y/N    |       |
| 2        |     | Pass/Fail   | Pass/Fail   | Pass/Fail   | Pass/Fail | Y/N    |       |

EXCEPTIONS NOTED:
| Sample # | Exception Description | Root Cause | Compensating Control | Impact |
|----------|----------------------|------------|---------------------|--------|
|          |                      |            |                     |        |

CONCLUSION:
[ ] Effective — Control operated effectively with no exceptions
[ ] Effective with exceptions — Control operated effectively; exceptions are isolated
[ ] Deficiency — Control did not operate effectively
[ ] Significant Deficiency — Deficiency is more than inconsequential
[ ] Material Weakness — Reasonable possibility of material misstatement not prevented/detected

Tested by: ________________  Date: ________
Reviewed by: _______________  Date: ________
```

### 5. Provide Common Control Templates

Based on the control area, provide pre-built test step templates:

**Revenue Recognition:**
- Verify sales order approval and authorization
- Confirm delivery/performance evidence
- Test revenue recognition timing against contract terms
- Verify pricing accuracy to contract/price list
- Test credit memo approval and validity

**Procure to Pay:**
- Verify purchase order approval and authorization limits
- Confirm three-way match (PO, receipt, invoice)
- Test vendor master data change controls
- Verify payment approval and segregation of duties
- Test duplicate payment prevention controls

**Financial Close:**
- Verify account reconciliation completeness and timeliness
- Test journal entry approval and segregation of duties
- Verify management review of financial statements
- Test consolidation and elimination entries
- Verify disclosure checklist completion

**ITGC:**
- Test user access provisioning and de-provisioning
- Verify privileged access reviews
- Test change management approval and testing
- Verify batch job monitoring and exception handling
- Test backup and recovery procedures

### 6. Document Control Assessment

Classify any identified deficiencies:

**Deficiency:** A control does not allow management or employees to prevent or detect misstatements on a timely basis. Consider:
- Likelihood of misstatement
- Magnitude of potential misstatement
- Whether compensating controls exist

**Significant Deficiency:** A deficiency (or combination) that is less severe than a material weakness but important enough to merit attention by those responsible for oversight.

**Material Weakness:** A deficiency (or combination) such that there is a reasonable possibility that a material misstatement will not be prevented or detected on a timely basis.

### 7. Output

Provide:
1. Control matrix for the selected area
2. Sample selections with methodology documentation
3. Testing workpaper templates with pre-populated test steps
4. Results documentation template
5. Deficiency evaluation framework (if exceptions are identified)
6. Suggested remediation actions for any noted deficiencies$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/finance/skills/variance-analysis', 'business', 'variance-analysis', '', 'variance-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Variance Analysis

**Important**: This skill assists with variance analysis workflows but does not provide financial advice. All analyses should be reviewed by qualified financial professionals before use in reporting.

Techniques for decomposing variances, materiality thresholds, narrative generation, waterfall chart methodology, and budget vs actual vs forecast comparisons.

## Variance Decomposition Techniques

### Price / Volume Decomposition

The most fundamental variance decomposition. Used for revenue, cost of goods, and any metric that can be expressed as Price x Volume.

**Formula:**
```
Total Variance = Actual - Budget (or Prior)

Volume Effect  = (Actual Volume - Budget Volume) x Budget Price
Price Effect   = (Actual Price - Budget Price) x Actual Volume
Mix Effect     = Residual (interaction term), or allocated proportionally

Verification:  Volume Effect + Price Effect = Total Variance
               (when mix is embedded in the price/volume terms)
```

**Three-way decomposition (separating mix):**
```
Volume Effect = (Actual Volume - Budget Volume) x Budget Price x Budget Mix
Price Effect  = (Actual Price - Budget Price) x Budget Volume x Actual Mix
Mix Effect    = Budget Price x Budget Volume x (Actual Mix - Budget Mix)
```

**Example — Revenue variance:**
- Budget: 10,000 units at $50 = $500,000
- Actual: 11,000 units at $48 = $528,000
- Total variance: +$28,000 favorable
  - Volume effect: +1,000 units x $50 = +$50,000 (favorable — sold more units)
  - Price effect: -$2 x 11,000 units = -$22,000 (unfavorable — lower ASP)
  - Net: +$28,000

### Rate / Mix Decomposition

Used when analyzing blended rates across segments with different unit economics.

**Formula:**
```
Rate Effect = Sum of (Actual Volume_i x (Actual Rate_i - Budget Rate_i))
Mix Effect  = Sum of (Budget Rate_i x (Actual Volume_i - Expected Volume_i at Budget Mix))
```

**Example — Gross margin variance:**
- Product A: 60% margin, Product B: 40% margin
- Budget mix: 50% A, 50% B → Blended margin 50%
- Actual mix: 40% A, 60% B → Blended margin 48%
- Mix effect explains 2pp of margin compression

### Headcount / Compensation Decomposition

Used for analyzing payroll and people-cost variances.

```
Total Comp Variance = Actual Compensation - Budget Compensation

Decompose into:
1. Headcount variance    = (Actual HC - Budget HC) x Budget Avg Comp
2. Rate variance         = (Actual Avg Comp - Budget Avg Comp) x Budget HC
3. Mix variance          = Difference due to level/department mix shift
4. Timing variance       = Hiring earlier/later than planned (partial-period effect)
5. Attrition impact      = Savings from unplanned departures (partially offset by backfill costs)
```

### Spend Category Decomposition

Used for operating expense analysis when price/volume is not applicable.

```
Total OpEx Variance = Actual OpEx - Budget OpEx

Decompose by:
1. Headcount-driven costs    (salaries, benefits, payroll taxes, recruiting)
2. Volume-driven costs       (hosting, transaction fees, commissions, shipping)
3. Discretionary spend       (travel, events, professional services, marketing programs)
4. Contractual/fixed costs   (rent, insurance, software licenses, subscriptions)
5. One-time / non-recurring  (severance, legal settlements, write-offs, project costs)
6. Timing / phasing          (spend shifted between periods vs plan)
```

## Materiality Thresholds and Investigation Triggers

### Setting Thresholds

Materiality thresholds determine which variances require investigation and narrative explanation. Set thresholds based on:

1. **Financial statement materiality:** Typically 1-5% of a key benchmark (revenue, total assets, net income)
2. **Line item size:** Larger line items warrant lower percentage thresholds
3. **Volatility:** More volatile line items may need higher thresholds to avoid noise
4. **Management attention:** What level of variance would change a decision?

### Recommended Threshold Framework

| Comparison Type | Dollar Threshold | Percentage Threshold | Trigger |
|----------------|-----------------|---------------------|---------|
| Actual vs Budget | Organization-specific | 10% | Either exceeded |
| Actual vs Prior Period | Organization-specific | 15% | Either exceeded |
| Actual vs Forecast | Organization-specific | 5% | Either exceeded |
| Sequential (MoM) | Organization-specific | 20% | Either exceeded |

*Set dollar thresholds based on your organization's size. Common practice: 0.5%-1% of revenue for income statement items.*

### Investigation Priority

When multiple variances exceed thresholds, prioritize investigation by:

1. **Largest absolute dollar variance** — biggest P&L impact
2. **Largest percentage variance** — may indicate process issue or error
3. **Unexpected direction** — variance opposite to trend or expectation
4. **New variance** — item that was on track and is now off
5. **Cumulative/trending variance** — growing each period

## Narrative Generation for Variance Explanations

### Structure for Each Variance Narrative

```
[Line Item]: [Favorable/Unfavorable] variance of $[amount] ([percentage]%)
vs [comparison basis] for [period]

Driver: [Primary driver description]
[2-3 sentences explaining the business reason for the variance, with specific
quantification of contributing factors]

Outlook: [One-time / Expected to continue / Improving / Deteriorating]
Action: [None required / Monitor / Investigate further / Update forecast]
```

### Narrative Quality Checklist

Good variance narratives should be:

- [ ] **Specific:** Names the actual driver, not just "higher than expected"
- [ ] **Quantified:** Includes dollar and percentage impact of each driver
- [ ] **Causal:** Explains WHY it happened, not just WHAT happened
- [ ] **Forward-looking:** States whether the variance is expected to continue
- [ ] **Actionable:** Identifies any required follow-up or decision
- [ ] **Concise:** 2-4 sentences, not a paragraph of filler

### Common Narrative Anti-Patterns to Avoid

- "Revenue was higher than budget due to higher revenue" (circular — no actual explanation)
- "Expenses were elevated this period" (vague — which expenses? why?)
- "Timing" without specifying what was early/late and when it will normalize
- "One-time" without explaining what the item was
- "Various small items" for a material variance (must decompose further)
- Focusing only on the largest driver and ignoring offsetting items

## Waterfall Chart Methodology

### Concept

A waterfall (or bridge) chart shows how you get from one value to another through a series of positive and negative contributors. Used to visualize variance decomposition.

### Data Structure

```
Starting value:  [Base/Budget/Prior period amount]
Drivers:         [List of contributing factors with signed amounts]
Ending value:    [Actual/Current period amount]

Verification:    Starting value + Sum of all drivers = Ending value
```

### Text-Based Waterfall Format

When a charting tool is not available, present as a text waterfall:

```
WATERFALL: Revenue — Q4 Actual vs Q4 Budget

Q4 Budget Revenue                                    $10,000K
  |
  |--[+] Volume growth (new customers)               +$800K
  |--[+] Expansion revenue (existing customers)      +$400K
  |--[-] Price reductions / discounting               -$200K
  |--[-] Churn / contraction                          -$350K
  |--[+] FX tailwind                                  +$50K
  |--[-] Timing (deals slipped to Q1)                 -$150K
  |
Q4 Actual Revenue                                    $10,550K

Net Variance: +$550K (+5.5% favorable)
```

### Bridge Reconciliation Table

Complement the waterfall with a reconciliation table:

| Driver | Amount | % of Variance | Cumulative |
|--------|--------|---------------|------------|
| Volume growth | +$800K | 145% | +$800K |
| Expansion revenue | +$400K | 73% | +$1,200K |
| Price reductions | -$200K | -36% | +$1,000K |
| Churn / contraction | -$350K | -64% | +$650K |
| FX tailwind | +$50K | 9% | +$700K |
| Timing (deal slippage) | -$150K | -27% | +$550K |
| **Total variance** | **+$550K** | **100%** | |

*Note: Percentages can exceed 100% for individual drivers when there are offsetting items.*

### Waterfall Best Practices

1. Order drivers from largest positive to largest negative (or in logical business sequence)
2. Keep to 5-8 drivers maximum — aggregate smaller items into "Other"
3. Verify the waterfall reconciles (start + drivers = end)
4. Color-code: green for favorable, red for unfavorable (in visual charts)
5. Label each bar with both the amount and a brief description
6. Include a "Total Variance" summary bar

## Budget vs Actual vs Forecast Comparisons

### Three-Way Comparison Framework

| Metric | Budget | Forecast | Actual | Bud Var ($) | Bud Var (%) | Fcast Var ($) | Fcast Var (%) |
|--------|--------|----------|--------|-------------|-------------|---------------|---------------|
| Revenue | $X | $X | $X | $X | X% | $X | X% |
| COGS | $X | $X | $X | $X | X% | $X | X% |
| Gross Profit | $X | $X | $X | $X | X% | $X | X% |

### When to Use Each Comparison

- **Actual vs Budget:** Annual performance measurement, compensation decisions, board reporting. Budget is set at the beginning of the year and typically not changed.
- **Actual vs Forecast:** Operational management, identifying emerging issues. Forecast is updated periodically (monthly or quarterly) to reflect current expectations.
- **Forecast vs Budget:** Understanding how expectations have changed since planning. Useful for identifying planning accuracy issues.
- **Actual vs Prior Period:** Trend analysis, sequential performance. Useful when budget is not meaningful (new business lines, post-acquisition).
- **Actual vs Prior Year:** Year-over-year growth analysis, seasonality-adjusted comparison.

### Forecast Accuracy Analysis

Track how accurate forecasts are over time to improve planning:

```
Forecast Accuracy = 1 - |Actual - Forecast| / |Actual|

MAPE (Mean Absolute Percentage Error) = Average of |Actual - Forecast| / |Actual| across periods
```

| Period | Forecast | Actual | Variance | Accuracy |
|--------|----------|--------|----------|----------|
| Jan    | $X       | $X     | $X (X%)  | XX%      |
| Feb    | $X       | $X     | $X (X%)  | XX%      |
| ...    | ...      | ...    | ...      | ...      |
| **Avg**|          |        | **MAPE** | **XX%**  |

### Variance Trending

Track how variances evolve over the year to identify systematic bias:

- **Consistently favorable:** Budget may be too conservative (sandbagging)
- **Consistently unfavorable:** Budget may be too aggressive or execution issues
- **Growing unfavorable:** Deteriorating performance or unrealistic targets
- **Shrinking variance:** Forecast accuracy improving through the year (normal pattern)
- **Volatile:** Unpredictable business or poor forecasting methodology$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/human-resources/skills/comp-analysis', 'business', 'comp-analysis', '', 'comp-analysis', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /comp-analysis

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Analyze compensation data for benchmarking, band placement, and planning. Helps benchmark compensation against market data for hiring, retention, and equity planning.

## Usage

```
/comp-analysis $ARGUMENTS
```

## What I Need From You

**Option A: Single role analysis**
"What should we pay a Senior Software Engineer in SF?"

**Option B: Upload comp data**
Upload a CSV or paste your comp bands. I'll analyze placement, identify outliers, and compare to market.

**Option C: Equity modeling**
"Model a refresh grant of 10K shares over 4 years at a $50 stock price."

## Compensation Framework

### Components of Total Compensation
- **Base salary**: Cash compensation
- **Equity**: RSUs, stock options, or other equity
- **Bonus**: Annual target bonus, signing bonus
- **Benefits**: Health, retirement, perks (harder to quantify)

### Key Variables
- **Role**: Function and specialization
- **Level**: IC levels, management levels
- **Location**: Geographic pay adjustments
- **Company stage**: Startup vs. growth vs. public
- **Industry**: Tech vs. finance vs. healthcare

### Data Sources
- **With ~~compensation data**: Pull verified benchmarks
- **Without**: Use web research, public salary data, and user-provided context
- Always note data freshness and source limitations

## Output

Provide percentile bands (25th, 50th, 75th, 90th) for base, equity, and total comp. Include location adjustments and company-stage context.

```markdown
## Compensation Analysis: [Role/Scope]

### Market Benchmarks
| Percentile | Base | Equity | Total Comp |
|------------|------|--------|------------|
| 25th | $[X] | $[X] | $[X] |
| 50th | $[X] | $[X] | $[X] |
| 75th | $[X] | $[X] | $[X] |
| 90th | $[X] | $[X] | $[X] |

**Sources:** [Web research, compensation data tools, or user-provided data]

### Band Analysis (if data provided)
| Employee | Current Base | Band Min | Band Mid | Band Max | Position |
|----------|-------------|----------|----------|----------|----------|
| [Name] | $[X] | $[X] | $[X] | $[X] | [Below/At/Above] |

### Recommendations
- [Specific compensation recommendations]
- [Equity considerations]
- [Retention risks if applicable]
```

## If Connectors Available

If **~~compensation data** is connected:
- Pull verified market benchmarks by role, level, and location
- Compare your bands against real-time market data

If **~~HRIS** is connected:
- Pull current employee comp data for band analysis
- Identify outliers and retention risks automatically

## Tips

1. **Location matters** — Always specify location for benchmarking. SF vs. Austin vs. London are very different.
2. **Total comp, not just base** — Include equity, bonus, and benefits for a complete picture.
3. **Keep data confidential** — Comp data is sensitive. Results stay in your conversation.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/human-resources/skills/draft-offer', 'business', 'draft-offer', '', 'draft-offer', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /draft-offer

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Draft a complete offer letter for a new hire.

## Usage

```
/draft-offer $ARGUMENTS
```

## What I Need From You

- **Role and title**: What position?
- **Level**: Junior, Mid, Senior, Staff, etc.
- **Location**: Where will they be based? (affects comp and benefits)
- **Compensation**: Base salary, equity, signing bonus (if applicable)
- **Start date**: When should they start?
- **Hiring manager**: Who will they report to?

If you don't have all details, I'll help you think through them.

## Output

```markdown
## Offer Letter Draft: [Role] — [Level]

### Compensation Package
| Component | Details |
|-----------|---------|
| **Base Salary** | $[X]/year |
| **Equity** | [X shares/units], [vesting schedule] |
| **Signing Bonus** | $[X] (if applicable) |
| **Target Bonus** | [X]% of base (if applicable) |
| **Total First-Year Comp** | $[X] |

### Terms
- **Start Date**: [Date]
- **Reports To**: [Manager]
- **Location**: [Office / Remote / Hybrid]
- **Employment Type**: [Full-time, Exempt]

### Benefits Summary
[Key benefits highlights relevant to the candidate]

### Offer Letter Text

Dear [Candidate Name],

We are pleased to offer you the position of [Title] at [Company]...

[Complete offer letter text]

### Notes for Hiring Manager
- [Negotiation guidance if needed]
- [Comp band context]
- [Any flags or considerations]
```

## If Connectors Available

If **~~HRIS** is connected:
- Pull comp band data for the level/role
- Verify headcount approval
- Auto-populate benefits details

If **~~ATS** is connected:
- Pull candidate details from the application
- Update offer status in the pipeline

## Tips

1. **Include total comp** — Candidates compare total compensation, not just base.
2. **Be specific about equity** — Share count, current valuation method, vesting schedule.
3. **Personalize** — Reference something from the interview process to make it warm.$body$)
ON CONFLICT (skill_key) DO NOTHING;
