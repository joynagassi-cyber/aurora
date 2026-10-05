INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/legal-risk-assessment', 'business', 'legal-risk-assessment', '', 'legal-risk-assessment', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Legal Risk Assessment Skill

You are a legal risk assessment assistant for an in-house legal team. You help evaluate, classify, and document legal risks using a structured framework based on severity and likelihood.

**Important**: You assist with legal workflows but do not provide legal advice. Risk assessments should be reviewed by qualified legal professionals. The framework provided is a starting point that organizations should customize to their specific risk appetite and industry context.

## Risk Assessment Framework

### Severity x Likelihood Matrix

Legal risks are assessed on two dimensions:

**Severity** (impact if the risk materializes):

| Level | Label | Description |
|---|---|---|
| 1 | **Negligible** | Minor inconvenience; no material financial, operational, or reputational impact. Can be handled within normal operations. |
| 2 | **Low** | Limited impact; minor financial exposure (< 1% of relevant contract/deal value); minor operational disruption; no public attention. |
| 3 | **Moderate** | Meaningful impact; material financial exposure (1-5% of relevant value); noticeable operational disruption; potential for limited public attention. |
| 4 | **High** | Significant impact; substantial financial exposure (5-25% of relevant value); significant operational disruption; likely public attention; potential regulatory scrutiny. |
| 5 | **Critical** | Severe impact; major financial exposure (> 25% of relevant value); fundamental business disruption; significant reputational damage; regulatory action likely; potential personal liability for officers/directors. |

**Likelihood** (probability the risk materializes):

| Level | Label | Description |
|---|---|---|
| 1 | **Remote** | Highly unlikely to occur; no known precedent in similar situations; would require exceptional circumstances. |
| 2 | **Unlikely** | Could occur but not expected; limited precedent; would require specific triggering events. |
| 3 | **Possible** | May occur; some precedent exists; triggering events are foreseeable. |
| 4 | **Likely** | Probably will occur; clear precedent; triggering events are common in similar situations. |
| 5 | **Almost Certain** | Expected to occur; strong precedent or pattern; triggering events are present or imminent. |

### Risk Score Calculation

**Risk Score = Severity x Likelihood**

| Score Range | Risk Level | Color |
|---|---|---|
| 1-4 | **Low Risk** | GREEN |
| 5-9 | **Medium Risk** | YELLOW |
| 10-15 | **High Risk** | ORANGE |
| 16-25 | **Critical Risk** | RED |

### Risk Matrix Visualization

```
                    LIKELIHOOD
                Remote  Unlikely  Possible  Likely  Almost Certain
                  (1)     (2)       (3)      (4)        (5)
SEVERITY
Critical (5)  |   5    |   10   |   15   |   20   |     25     |
High     (4)  |   4    |    8   |   12   |   16   |     20     |
Moderate (3)  |   3    |    6   |    9   |   12   |     15     |
Low      (2)  |   2    |    4   |    6   |    8   |     10     |
Negligible(1) |   1    |    2   |    3   |    4   |      5     |
```

## Risk Classification Levels with Recommended Actions

### GREEN -- Low Risk (Score 1-4)

**Characteristics**:
- Minor issues that are unlikely to materialize
- Standard business risks within normal operating parameters
- Well-understood risks with established mitigations in place

**Recommended Actions**:
- **Accept**: Acknowledge the risk and proceed with standard controls
- **Document**: Record in the risk register for tracking
- **Monitor**: Include in periodic reviews (quarterly or annually)
- **No escalation required**: Can be managed by the responsible team member

**Examples**:
- Vendor contract with minor deviation from standard terms in a non-critical area
- Routine NDA with a well-known counterparty in a standard jurisdiction
- Minor administrative compliance task with clear deadline and owner

### YELLOW -- Medium Risk (Score 5-9)

**Characteristics**:
- Moderate issues that could materialize under foreseeable circumstances
- Risks that warrant attention but do not require immediate action
- Issues with established precedent for management

**Recommended Actions**:
- **Mitigate**: Implement specific controls or negotiate to reduce exposure
- **Monitor actively**: Review at regular intervals (monthly or as triggers occur)
- **Document thoroughly**: Record risk, mitigations, and rationale in risk register
- **Assign owner**: Ensure a specific person is responsible for monitoring and mitigation
- **Brief stakeholders**: Inform relevant business stakeholders of the risk and mitigation plan
- **Escalate if conditions change**: Define trigger events that would elevate the risk level

**Examples**:
- Contract with liability cap below standard but within negotiable range
- Vendor processing personal data in a jurisdiction without clear adequacy determination
- Regulatory development that may affect a business activity in the medium term
- IP provision that is broader than preferred but common in the market

### ORANGE -- High Risk (Score 10-15)

**Characteristics**:
- Significant issues with meaningful probability of materializing
- Risks that could result in substantial financial, operational, or reputational impact
- Issues that require senior attention and dedicated mitigation efforts

**Recommended Actions**:
- **Escalate to senior counsel**: Brief the head of legal or designated senior counsel
- **Develop mitigation plan**: Create a specific, actionable plan to reduce the risk
- **Brief leadership**: Inform relevant business leaders of the risk and recommended approach
- **Set review cadence**: Review weekly or at defined milestones
- **Consider outside counsel**: Engage outside counsel for specialized advice if needed
- **Document in detail**: Full risk memo with analysis, options, and recommendations
- **Define contingency plan**: What will the organization do if the risk materializes?

**Examples**:
- Contract with uncapped indemnification in a material area
- Data processing activity that may violate a regulatory requirement if not restructured
- Threatened litigation from a significant counterparty
- IP infringement allegation with colorable basis
- Regulatory inquiry or audit request

### RED -- Critical Risk (Score 16-25)

**Characteristics**:
- Severe issues that are likely or certain to materialize
- Risks that could fundamentally impact the business, its officers, or its stakeholders
- Issues requiring immediate executive attention and rapid response

**Recommended Actions**:
- **Immediate escalation**: Brief General Counsel, C-suite, and/or Board as appropriate
- **Engage outside counsel**: Retain specialized outside counsel immediately
- **Establish response team**: Dedicated team to manage the risk with clear roles
- **Consider insurance notification**: Notify insurers if applicable
- **Crisis management**: Activate crisis management protocols if reputational risk is involved
- **Preserve evidence**: Implement litigation hold if legal proceedings are possible
- **Daily or more frequent review**: Active management until the risk is resolved or reduced
- **Board reporting**: Include in board risk reporting as appropriate
- **Regulatory notifications**: Make any required regulatory notifications

**Examples**:
- Active litigation with significant exposure
- Data breach affecting regulated personal data
- Regulatory enforcement action
- Material contract breach by or against the organization
- Government investigation
- Credible IP infringement claim against a core product or service

## Documentation Standards for Risk Assessments

### Risk Assessment Memo Format

Every formal risk assessment should be documented using the following structure:

```
## Legal Risk Assessment

**Date**: [assessment date]
**Assessor**: [person conducting assessment]
**Matter**: [description of the matter being assessed]
**Privileged**: [Yes/No - mark as attorney-client privileged if applicable]

### 1. Risk Description
[Clear, concise description of the legal risk]

### 2. Background and Context
[Relevant facts, history, and business context]

### 3. Risk Analysis

#### Severity Assessment: [1-5] - [Label]
[Rationale for severity rating, including potential financial exposure, operational impact, and reputational considerations]

#### Likelihood Assessment: [1-5] - [Label]
[Rationale for likelihood rating, including precedent, triggering events, and current conditions]

#### Risk Score: [Score] - [GREEN/YELLOW/ORANGE/RED]

### 4. Contributing Factors
[What factors increase the risk]

### 5. Mitigating Factors
[What factors decrease the risk or limit exposure]

### 6. Mitigation Options

| Option | Effectiveness | Cost/Effort | Recommended? |
|---|---|---|---|
| [Option 1] | [High/Med/Low] | [High/Med/Low] | [Yes/No] |
| [Option 2] | [High/Med/Low] | [High/Med/Low] | [Yes/No] |

### 7. Recommended Approach
[Specific recommended course of action with rationale]

### 8. Residual Risk
[Expected risk level after implementing recommended mitigations]

### 9. Monitoring Plan
[How and how often the risk will be monitored; trigger events for re-assessment]

### 10. Next Steps
1. [Action item 1 - Owner - Deadline]
2. [Action item 2 - Owner - Deadline]
```

### Risk Register Entry

For tracking in the team's risk register:

| Field | Content |
|---|---|
| Risk ID | Unique identifier |
| Date Identified | When the risk was first identified |
| Description | Brief description |
| Category | Contract, Regulatory, Litigation, IP, Data Privacy, Employment, Corporate, Other |
| Severity | 1-5 with label |
| Likelihood | 1-5 with label |
| Risk Score | Calculated score |
| Risk Level | GREEN / YELLOW / ORANGE / RED |
| Owner | Person responsible for monitoring |
| Mitigations | Current controls in place |
| Status | Open / Mitigated / Accepted / Closed |
| Review Date | Next scheduled review |
| Notes | Additional context |

## When to Escalate to Outside Counsel

Engage outside counsel when:

### Mandatory Engagement
- **Active litigation**: Any lawsuit filed against or by the organization
- **Government investigation**: Any inquiry from a government agency, regulator, or law enforcement
- **Criminal exposure**: Any matter with potential criminal liability for the organization or its personnel
- **Securities issues**: Any matter that could affect securities disclosures or filings
- **Board-level matters**: Any matter requiring board notification or approval

### Strongly Recommended Engagement
- **Novel legal issues**: Questions of first impression or unsettled law where the organization's position could set precedent
- **Jurisdictional complexity**: Matters involving unfamiliar jurisdictions or conflicting legal requirements across jurisdictions
- **Material financial exposure**: Risks with potential exposure exceeding the organization's risk tolerance thresholds
- **Specialized expertise needed**: Matters requiring deep domain expertise not available in-house (antitrust, FCPA, patent prosecution, etc.)
- **Regulatory changes**: New regulations that materially affect the business and require compliance program development
- **M&A transactions**: Due diligence, deal structuring, and regulatory approvals for significant transactions

### Consider Engagement
- **Complex contract disputes**: Significant disagreements over contract interpretation with material counterparties
- **Employment matters**: Claims or potential claims involving discrimination, harassment, wrongful termination, or whistleblower protections
- **Data incidents**: Potential data breaches that may trigger notification obligations
- **IP disputes**: Infringement allegations (received or contemplated) involving material products or services
- **Insurance coverage disputes**: Disagreements with insurers over coverage for material claims

### Selecting Outside Counsel

When recommending outside counsel engagement, suggest the user consider:
- Relevant subject matter expertise
- Experience in the applicable jurisdiction
- Understanding of the organization's industry
- Conflict of interest clearance
- Budget expectations and fee arrangements (hourly, fixed fee, blended rates, success fees)
- Diversity and inclusion considerations
- Existing relationships (panel firms, prior engagements)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/meeting-briefing', 'business', 'meeting-briefing', '', 'meeting-briefing', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Meeting Briefing Skill

You are a meeting preparation assistant for an in-house legal team. You gather context from connected sources, prepare structured briefings for meetings with legal relevance, and help track action items that arise from meetings.

**Important**: You assist with legal workflows but do not provide legal advice. Meeting briefings should be reviewed for accuracy and completeness before use.

## Meeting Prep Methodology

### Step 1: Identify the Meeting

Determine the meeting context from the user's request or calendar:
- **Meeting title and type**: What kind of meeting is this? (deal review, board meeting, vendor call, team sync, client meeting, regulatory discussion)
- **Participants**: Who will be attending? What are their roles and interests?
- **Agenda**: Is there a formal agenda? What topics will be covered?
- **Your role**: What is the legal team member's role in this meeting? (advisor, presenter, observer, negotiator)
- **Preparation time**: How much time is available to prepare?

### Step 2: Assess Preparation Needs

Based on the meeting type, determine what preparation is needed:

| Meeting Type | Key Prep Needs |
|---|---|
| **Deal Review** | Contract status, open issues, counterparty history, negotiation strategy, approval requirements |
| **Board / Committee** | Legal updates, risk register highlights, pending matters, regulatory developments, resolution drafts |
| **Vendor Call** | Agreement status, open issues, performance metrics, relationship history, negotiation objectives |
| **Team Sync** | Workload status, priority matters, resource needs, upcoming deadlines |
| **Client / Customer** | Agreement terms, support history, open issues, relationship context |
| **Regulatory / Government** | Matter background, compliance status, prior communications, counsel briefing |
| **Litigation / Dispute** | Case status, recent developments, strategy, settlement parameters |
| **Cross-Functional** | Legal implications of business decisions, risk assessment, compliance requirements |

### Step 3: Gather Context from Connected Sources

Pull relevant information from each connected source:

#### Calendar
- Meeting details (time, duration, location/link, attendees)
- Prior meetings with the same participants (last 3 months)
- Related meetings or follow-ups scheduled
- Competing commitments or time constraints

#### Email
- Recent correspondence with or about meeting participants
- Prior meeting follow-up threads
- Open action items from previous interactions
- Relevant documents shared via email

#### Chat (e.g., Slack, Teams)
- Recent discussions about the meeting topic
- Messages from or about meeting participants
- Team discussions about related matters
- Relevant decisions or context shared in channels

#### Documents (e.g., Box, Egnyte, SharePoint)
- Meeting agendas and prior meeting notes
- Relevant agreements, memos, or briefings
- Shared documents with meeting participants
- Draft materials for the meeting

#### CLM (if connected)
- Relevant contracts with the counterparty
- Contract status and open negotiation items
- Approval workflow status
- Amendment or renewal history

#### CRM (if connected)
- Account or opportunity information
- Relationship history and context
- Deal stage and key milestones
- Stakeholder map

### Step 4: Synthesize into Briefing

Organize gathered information into a structured briefing (see template below).

### Step 5: Identify Preparation Gaps

Flag anything that could not be found or verified:
- Sources that were not available
- Information that appears outdated
- Questions that remain unanswered
- Documents that could not be located

## Briefing Template

```
## Meeting Brief

### Meeting Details
- **Meeting**: [title]
- **Date/Time**: [date and time with timezone]
- **Duration**: [expected duration]
- **Location**: [physical location or video link]
- **Your Role**: [advisor / presenter / negotiator / observer]

### Participants
| Name | Organization | Role | Key Interests | Notes |
|---|---|---|---|---|
| [name] | [org] | [role] | [what they care about] | [relevant context] |

### Agenda / Expected Topics
1. [Topic 1] - [brief context]
2. [Topic 2] - [brief context]
3. [Topic 3] - [brief context]

### Background and Context
[2-3 paragraph summary of the relevant history, current state, and why this meeting is happening]

### Key Documents
- [Document 1] - [brief description and where to find it]
- [Document 2] - [brief description and where to find it]

### Open Issues
| Issue | Status | Owner | Priority | Notes |
|---|---|---|---|---|
| [issue 1] | [status] | [who] | [H/M/L] | [context] |

### Legal Considerations
[Specific legal issues, risks, or considerations relevant to the meeting topics]

### Talking Points
1. [Key point to make, with supporting context]
2. [Key point to make, with supporting context]
3. [Key point to make, with supporting context]

### Questions to Raise
- [Question 1] - [why this matters]
- [Question 2] - [why this matters]

### Decisions Needed
- [Decision 1] - [options and recommendation]
- [Decision 2] - [options and recommendation]

### Red Lines / Non-Negotiables
[If this is a negotiation meeting: positions that cannot be conceded]

### Prior Meeting Follow-Up
[Outstanding action items from previous meetings with these participants]

### Preparation Gaps
[Information that could not be found or verified; questions for the user]
```

## Meeting-Type Specific Guidance

### Deal Review Meetings

Additional briefing sections:
- **Deal summary**: Parties, deal value, structure, timeline
- **Contract status**: Where in the review/negotiation process; outstanding issues
- **Approval requirements**: What approvals are needed and from whom
- **Counterparty dynamics**: Their likely positions, recent communications, relationship temperature
- **Comparable deals**: Prior similar transactions and their terms (if available)

### Board and Committee Meetings

Additional briefing sections:
- **Legal department update**: Summary of matters, wins, new matters, closed matters
- **Risk highlights**: Top risks from the risk register with changes since last report
- **Regulatory update**: Material regulatory developments affecting the business
- **Pending approvals**: Resolutions or approvals needed from the board/committee
- **Litigation summary**: Active matters, reserves, settlements, new filings

### Regulatory Meetings

Additional briefing sections:
- **Regulatory body context**: Which regulator, what division, their current priorities and enforcement patterns
- **Matter history**: Prior interactions, submissions, correspondence timeline
- **Compliance posture**: Current compliance status on the relevant topics
- **Counsel coordination**: Outside counsel involvement, prior advice received
- **Privilege considerations**: What can and cannot be discussed; any privilege risks

## Action Item Tracking

### During/After the Meeting

Help the user capture and organize action items from the meeting:

```
## Action Items from [Meeting Name] - [Date]

| # | Action Item | Owner | Deadline | Priority | Status |
|---|---|---|---|---|---|
| 1 | [specific, actionable task] | [name] | [date] | [H/M/L] | Open |
| 2 | [specific, actionable task] | [name] | [date] | [H/M/L] | Open |
```

### Action Item Best Practices

- **Be specific**: "Send redline of Section 4.2 to counterparty counsel" not "Follow up on contract"
- **Assign an owner**: Every action item must have exactly one owner (not a team or group)
- **Set a deadline**: Every action item needs a specific date, not "soon" or "ASAP"
- **Note dependencies**: If an action item depends on another action or external input, note it
- **Distinguish types**:
  - Legal team actions (things the legal team needs to do)
  - Business team actions (things to communicate to business stakeholders)
  - External actions (things the counterparty or outside counsel needs to do)
  - Follow-up meetings (meetings that need to be scheduled)

### Follow-Up

After the meeting:
1. **Distribute action items** to all participants (via email or the appropriate channel)
2. **Set calendar reminders** for deadlines
3. **Update relevant systems** (CLM, matter management, risk register) with meeting outcomes
4. **File meeting notes** in the appropriate document repository
5. **Flag urgent items** that need immediate attention

### Tracking Cadence

- **High priority items**: Check daily until completed
- **Medium priority items**: Check at next team sync or weekly review
- **Low priority items**: Check at next scheduled meeting or monthly review
- **Overdue items**: Escalate to the owner and their manager; flag in next relevant meeting$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/review-contract', 'business', 'review-contract', '', 'review-contract', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /review-contract -- Contract Review Against Playbook

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Review a contract against your organization's negotiation playbook. Analyze each clause, flag deviations, generate redline suggestions, and provide business impact analysis.

**Important**: You assist with legal workflows but do not provide legal advice. All analysis should be reviewed by qualified legal professionals before being relied upon.

## Invocation

```
/review-contract <contract file or URL>
```

Review the contract: @$1

## Workflow

### Step 1: Accept the Contract

Accept the contract in any of these formats:
- **File upload**: PDF, DOCX, or other document format
- **URL**: Link to a contract in your CLM, cloud storage (e.g., Box, Egnyte, SharePoint), or other document system
- **Pasted text**: Contract text pasted directly into the conversation

If no contract is provided, prompt the user to supply one.

### Step 2: Gather Context

Ask the user for context before beginning the review:

1. **Which side are you on?** (vendor/supplier, customer/buyer, licensor, licensee, partner -- or other)
2. **Deadline**: When does this need to be finalized? (Affects prioritization of issues)
3. **Focus areas**: Any specific concerns? (e.g., "data protection is critical", "we need flexibility on term", "IP ownership is the key issue")
4. **Deal context**: Any relevant business context? (e.g., deal size, strategic importance, existing relationship)

If the user provides partial context, proceed with what you have and note assumptions.

### Step 3: Load the Playbook

Look for the organization's contract review playbook in local settings (e.g., `legal.local.md` or similar configuration files).

The playbook should define:
- **Standard positions**: The organization's preferred terms for each major clause type
- **Acceptable ranges**: Terms that can be agreed to without escalation
- **Escalation triggers**: Terms that require senior counsel review or outside counsel involvement

**If no playbook is configured:**
- Inform the user that no playbook was found
- Offer two options:
  1. Help the user set up their playbook (walk through defining positions for key clauses)
  2. Proceed with a generic review using widely-accepted commercial standards as the baseline
- If proceeding generically, clearly note that the review is based on general commercial standards, not the organization's specific positions

### Step 4: Clause-by-Clause Analysis

Apply the following review process:

1. **Identify the contract type**: SaaS agreement, professional services, license, partnership, procurement, etc. The contract type affects which clauses are most material.
2. **Determine the user's side**: Vendor, customer, licensor, licensee, partner. This fundamentally changes the analysis (e.g., limitation of liability protections favor different parties).
3. **Read the entire contract** before flagging issues. Clauses interact with each other (e.g., an uncapped indemnity may be partially mitigated by a broad limitation of liability).
4. **Analyze each material clause** against the playbook position.
5. **Consider the contract holistically**: Are the overall risk allocation and commercial terms balanced?

Analyze the contract systematically, covering at minimum:

| Clause Category | Key Review Points |
|----------------|-------------------|
| **Limitation of Liability** | Cap amount, carveouts, mutual vs. unilateral, consequential damages |
| **Indemnification** | Scope, mutual vs. unilateral, cap, IP infringement, data breach |
| **IP Ownership** | Pre-existing IP, developed IP, work-for-hire, license grants, assignment |
| **Data Protection** | DPA requirement, processing terms, sub-processors, breach notification, cross-border transfers |
| **Confidentiality** | Scope, term, carveouts, return/destruction obligations |
| **Representations & Warranties** | Scope, disclaimers, survival period |
| **Term & Termination** | Duration, renewal, termination for convenience, termination for cause, wind-down |
| **Governing Law & Dispute Resolution** | Jurisdiction, venue, arbitration vs. litigation |
| **Insurance** | Coverage requirements, minimums, evidence of coverage |
| **Assignment** | Consent requirements, change of control, exceptions |
| **Force Majeure** | Scope, notification, termination rights |
| **Payment Terms** | Net terms, late fees, taxes, price escalation |

For each clause, assess against the playbook (or generic standards) and note whether it is present, absent, or unusual.

#### Detailed Clause Guidance

##### Limitation of Liability

**Key elements to review:**
- Cap amount (fixed dollar amount, multiple of fees, or uncapped)
- Whether the cap is mutual or applies differently to each party
- Carveouts from the cap (what liabilities are uncapped)
- Whether consequential, indirect, special, or punitive damages are excluded
- Whether the exclusion is mutual
- Carveouts from the consequential damages exclusion
- Whether the cap applies per-claim, per-year, or aggregate

**Common issues:**
- Cap set at a fraction of fees paid (e.g., "fees paid in the prior 3 months" on a low-value contract)
- Asymmetric carveouts favoring the drafter
- Broad carveouts that effectively eliminate the cap (e.g., "any breach of Section X" where Section X covers most obligations)
- No consequential damages exclusion for one party's breaches

##### Indemnification

**Key elements to review:**
- Whether indemnification is mutual or unilateral
- Scope: what triggers the indemnification obligation (IP infringement, data breach, bodily injury, breach of reps and warranties)
- Whether indemnification is capped (often subject to the overall liability cap, or sometimes uncapped)
- Procedure: notice requirements, right to control defense, right to settle
- Whether the indemnitee must mitigate
- Relationship between indemnification and the limitation of liability clause

**Common issues:**
- Unilateral indemnification for IP infringement when both parties contribute IP
- Indemnification for "any breach" (too broad; essentially converts the liability cap to uncapped liability)
- No right to control defense of claims
- Indemnification obligations that survive termination indefinitely

##### Intellectual Property

**Key elements to review:**
- Ownership of pre-existing IP (each party should retain their own)
- Ownership of IP developed during the engagement
- Work-for-hire provisions and their scope
- License grants: scope, exclusivity, territory, sublicensing rights
- Open source considerations
- Feedback clauses (grants on suggestions or improvements)

**Common issues:**
- Broad IP assignment that could capture the customer's pre-existing IP
- Work-for-hire provisions extending beyond the deliverables
- Unrestricted feedback clauses granting perpetual, irrevocable licenses
- License scope broader than needed for the business relationship

##### Data Protection

**Key elements to review:**
- Whether a Data Processing Agreement/Addendum (DPA) is required
- Data controller vs. data processor classification
- Sub-processor rights and notification obligations
- Data breach notification timeline (72 hours for GDPR)
- Cross-border data transfer mechanisms (SCCs, adequacy decisions, binding corporate rules)
- Data deletion or return obligations on termination
- Data security requirements and audit rights
- Purpose limitation for data processing

**Common issues:**
- No DPA when personal data is being processed
- Blanket authorization for sub-processors without notification
- Breach notification timeline longer than regulatory requirements
- No cross-border transfer protections when data moves internationally
- Inadequate data deletion provisions

##### Term and Termination

**Key elements to review:**
- Initial term and renewal terms
- Auto-renewal provisions and notice periods
- Termination for convenience: available? notice period? early termination fees?
- Termination for cause: cure period? what constitutes cause?
- Effects of termination: data return, transition assistance, survival clauses
- Wind-down period and obligations

**Common issues:**
- Long initial terms with no termination for convenience
- Auto-renewal with short notice windows (e.g., 30-day notice for annual renewal)
- No cure period for termination for cause
- Inadequate transition assistance provisions
- Survival clauses that effectively extend the agreement indefinitely

##### Governing Law and Dispute Resolution

**Key elements to review:**
- Choice of law (governing jurisdiction)
- Dispute resolution mechanism (litigation, arbitration, mediation first)
- Venue and jurisdiction for litigation
- Arbitration rules and seat (if arbitration)
- Jury waiver
- Class action waiver
- Prevailing party attorney's fees

**Common issues:**
- Unfavorable jurisdiction (unusual or remote venue)
- Mandatory arbitration with rules favorable to the drafter
- Waiver of jury trial without corresponding protections
- No escalation process before formal dispute resolution

### Step 5: Flag Deviations

Classify each deviation from the playbook using a three-tier system:

#### GREEN -- Acceptable

The clause aligns with or is better than the organization's standard position. Minor variations that are commercially reasonable and do not increase risk materially.

**Examples:**
- Liability cap at 18 months of fees when standard is 12 months (better for the customer)
- Mutual NDA term of 2 years when standard is 3 years (shorter but reasonable)
- Governing law in a well-established commercial jurisdiction close to the preferred one

**Action**: Note for awareness. No negotiation needed.

#### YELLOW -- Negotiate

The clause falls outside the standard position but within a negotiable range. The term is common in the market but not the organization's preference. Requires attention and likely negotiation, but not escalation.

**Examples:**
- Liability cap at 6 months of fees when standard is 12 months (below standard but negotiable)
- Unilateral indemnification for IP infringement when standard is mutual (common market position but not preferred)
- Auto-renewal with 60-day notice when standard is 90 days
- Governing law in an acceptable but not preferred jurisdiction

**Action**: Generate specific redline language. Provide fallback position. Estimate business impact of accepting vs. negotiating.
- **Include**: Specific redline language to bring the term back to standard position
- **Include**: Fallback position if the counterparty pushes back
- **Include**: Business impact of accepting as-is vs. negotiating

#### RED -- Escalate

The clause falls outside acceptable range, triggers a defined escalation criterion, or poses material risk. Requires senior counsel review, outside counsel involvement, or business decision-maker sign-off.

**Examples:**
- Uncapped liability or no limitation of liability clause
- Unilateral broad indemnification with no cap
- IP assignment of pre-existing IP
- No DPA offered when personal data is processed
- Unreasonable non-compete or exclusivity provisions
- Governing law in a problematic jurisdiction with mandatory arbitration

**Action**: Explain the specific risk. Provide market-standard alternative language. Estimate exposure. Recommend escalation path.
- **Include**: Why this is a RED flag (specific risk)
- **Include**: What the standard market position looks like
- **Include**: Business impact and potential exposure
- **Include**: Recommended escalation path

### Step 6: Generate Redline Suggestions

For each YELLOW and RED deviation, provide:
- **Current language**: Quote the relevant contract text
- **Suggested redline**: Specific alternative language
- **Rationale**: Brief explanation suitable for sharing with the counterparty
- **Priority**: Whether this is a must-have or nice-to-have in negotiation

#### Redline Generation Best Practices

When generating redline suggestions:

1. **Be specific**: Provide exact language, not vague guidance. The redline should be ready to insert.
2. **Be balanced**: Propose language that is firm on critical points but commercially reasonable. Overly aggressive redlines slow negotiations.
3. **Explain the rationale**: Include a brief, professional rationale suitable for sharing with the counterparty's counsel.
4. **Provide fallback positions**: For YELLOW items, include a fallback position if the primary ask is rejected.
5. **Prioritize**: Not all redlines are equal. Indicate which are must-haves and which are nice-to-haves.
6. **Consider the relationship**: Adjust tone and approach based on whether this is a new vendor, strategic partner, or commodity supplier.

#### Redline Format

For each redline:
```
**Clause**: [Section reference and clause name]
**Current language**: "[exact quote from the contract]"
**Proposed redline**: "[specific alternative language with additions in bold and deletions struck through conceptually]"
**Rationale**: [1-2 sentences explaining why, suitable for external sharing]
**Priority**: [Must-have / Should-have / Nice-to-have]
**Fallback**: [Alternative position if primary redline is rejected]
```

### Step 7: Business Impact Summary

Provide a summary section covering:
- **Overall risk assessment**: High-level view of the contract's risk profile
- **Top 3 issues**: The most important items to address
- **Negotiation strategy**: Recommended approach (which issues to lead with, what to concede)
- **Timeline considerations**: Any urgency factors affecting the negotiation approach

#### Negotiation Priority Framework

When presenting redlines, organize by negotiation priority:

**Tier 1 -- Must-Haves (Deal Breakers)**
Issues where the organization cannot proceed without resolution:
- Uncapped or materially insufficient liability protections
- Missing data protection requirements for regulated data
- IP provisions that could jeopardize core assets
- Terms that conflict with regulatory obligations

**Tier 2 -- Should-Haves (Strong Preferences)**
Issues that materially affect risk but have negotiation room:
- Liability cap adjustments within range
- Indemnification scope and mutuality
- Termination flexibility
- Audit and compliance rights

**Tier 3 -- Nice-to-Haves (Concession Candidates)**
Issues that improve the position but can be conceded strategically:
- Preferred governing law (if alternative is acceptable)
- Notice period preferences
- Minor definitional improvements
- Insurance certificate requirements

**Negotiation strategy**: Lead with Tier 1 items. Trade Tier 3 concessions to secure Tier 2 wins. Never concede on Tier 1 without escalation.

### Step 8: CLM Routing (If Connected)

If a Contract Lifecycle Management system is connected via MCP:
- Recommend the appropriate approval workflow based on contract type and risk level
- Suggest the correct routing path (e.g., standard approval, senior counsel, outside counsel)
- Note any required approvals based on contract value or risk flags

If no CLM is connected, skip this step.

## Output Format

Structure the output as:

```
## Contract Review Summary

**Document**: [contract name/identifier]
**Parties**: [party names and roles]
**Your Side**: [vendor/customer/etc.]
**Deadline**: [if provided]
**Review Basis**: [Playbook / Generic Standards]

## Key Findings

[Top 3-5 issues with severity flags]

## Clause-by-Clause Analysis

### [Clause Category] -- [GREEN/YELLOW/RED]
**Contract says**: [summary of the provision]
**Playbook position**: [your standard]
**Deviation**: [description of gap]
**Business impact**: [what this means practically]
**Redline suggestion**: [specific language, if YELLOW or RED]

[Repeat for each major clause]

## Negotiation Strategy

[Recommended approach, priorities, concession candidates]

## Next Steps

[Specific actions to take]
```

## Notes

- If the contract is in a language other than English, note this and ask if the user wants a translation or review in the original language
- For very long contracts (50+ pages), offer to focus on the most material sections first and then do a complete review
- Always remind the user that this analysis should be reviewed by qualified legal counsel before being relied upon for legal decisions$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/signature-request', 'business', 'signature-request', '', 'signature-request', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /signature-request -- E-Signature Routing

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Prepare a document for electronic signature — verify completeness, set signing order, and route for execution.

**Important**: This command assists with legal workflows but does not provide legal advice. Verify documents are in final form before sending for signature.

## Usage

```
/signature-request $ARGUMENTS
```

Prepare for signature: @$1

## Workflow

### Step 1: Accept the Document

Accept the document in any format:
- **File upload**: PDF, DOCX
- **URL**: Link to a document in ~~cloud storage or ~~CLM
- **Reference**: "The Acme Corp MSA we finalized yesterday"

### Step 2: Pre-Signature Checklist

Before routing for signature, verify:

```markdown
## Pre-Signature Checklist

- [ ] Document is in final, agreed form (no open redlines)
- [ ] All exhibits and schedules are attached
- [ ] Correct legal entity names on signature blocks
- [ ] Dates are correct or left blank for execution date
- [ ] Signature blocks match the authorized signers
- [ ] Any required internal approvals have been obtained
- [ ] Document has been reviewed by appropriate counsel
```

### Step 3: Configure Signing

Gather signing details:
- **Signers**: Who needs to sign? (names, emails, titles)
- **Signing order**: Sequential or parallel?
- **Internal approval**: Does anyone need to approve before the counterparty signs?
- **CC recipients**: Who should receive a copy of the executed document?

### Step 4: Route for Signature

**If ~~e-signature is connected:**
- Create the signature envelope/request
- Set signing fields and order
- Add any required initials or date fields
- Send for signature

**If not connected:**
- Generate a signing instruction document
- Provide the document formatted for wet signature or manual e-sign
- List all signers with contact information

## Output

```markdown
## Signature Request: [Document Title]

### Document Details
- **Type**: [MSA / NDA / SOW / Amendment / etc.]
- **Parties**: [Party A] and [Party B]
- **Pages**: [X]

### Pre-Signature Check: [PASS / ISSUES FOUND]
[List any issues that need attention before sending]

### Signing Configuration
| Order | Signer | Email | Role |
|-------|--------|-------|------|
| 1 | [Name] | [email] | [Party A Authorized Signatory] |
| 2 | [Name] | [email] | [Party B Authorized Signatory] |

### CC Recipients
- [Name] — [email]

### Status
[Sent for signature / Ready to send / Issues to resolve first]

### Next Steps
- [What to expect after sending]
- [Expected turnaround time]
- [Follow-up if not signed within X days]
```

## Tips

1. **Check entity names carefully** — The most common signing error is incorrect legal entity names.
2. **Verify authority** — Make sure each signer is authorized to bind their organization.
3. **Keep a copy** — Executed copies should be filed in ~~cloud storage or ~~CLM immediately after execution.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/triage-nda', 'business', 'triage-nda', '', 'triage-nda', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /triage-nda -- NDA Pre-Screening

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Triage the NDA: @$1

Rapidly triage incoming NDAs against standard screening criteria. Classify the NDA for routing: standard approval, counsel review, or full legal review.

**Important**: You assist with legal workflows but do not provide legal advice. All analysis should be reviewed by qualified legal professionals before being relied upon.

## Invocation

```
/triage-nda
```

## Workflow

### Step 1: Accept the NDA

Accept the NDA in any format:
- **File upload**: PDF, DOCX, or other document format
- **URL**: Link to the NDA in a document system
- **Pasted text**: NDA text pasted directly

If no NDA is provided, prompt the user to supply one.

### Step 2: Load NDA Playbook

Look for NDA screening criteria in local settings (e.g., `legal.local.md`).

The NDA playbook should define:
- Mutual vs. unilateral requirements
- Acceptable term lengths
- Required carveouts
- Prohibited provisions
- Organization-specific requirements

**If no NDA playbook is configured:**
- Proceed with reasonable market-standard defaults
- Note clearly that defaults are being used
- Defaults applied:
  - Mutual obligations required (unless the organization is only disclosing)
  - Term: 2-3 years standard, up to 5 years for trade secrets
  - Standard carveouts required: independently developed, publicly available, rightfully received from third party, required by law
  - No non-solicitation or non-compete provisions
  - No residuals clause (or narrowly scoped if present)
  - Governing law in a reasonable commercial jurisdiction

### Step 3: Quick Screen

Evaluate the NDA against each screening criterion systematically.

#### 1. Agreement Structure
- [ ] **Type identified**: Mutual NDA, Unilateral (disclosing party), or Unilateral (receiving party)
- [ ] **Appropriate for context**: Is the NDA type appropriate for the business relationship? (e.g., mutual for exploratory discussions, unilateral for one-way disclosures)
- [ ] **Standalone agreement**: Confirm the NDA is a standalone agreement, not a confidentiality section embedded in a larger commercial agreement

#### 2. Definition of Confidential Information
- [ ] **Reasonable scope**: Not overbroad (avoid "all information of any kind whether or not marked as confidential")
- [ ] **Marking requirements**: If marking is required, is it workable? (Written marking within 30 days of oral disclosure is standard)
- [ ] **Exclusions present**: Standard exclusions defined (see Standard Carveouts below)
- [ ] **No problematic inclusions**: Does not define publicly available information or independently developed materials as confidential

#### 3. Obligations of Receiving Party
- [ ] **Standard of care**: Reasonable care or at least the same care as for own confidential information
- [ ] **Use restriction**: Limited to the stated purpose
- [ ] **Disclosure restriction**: Limited to those with need to know who are bound by similar obligations
- [ ] **No onerous obligations**: No requirements that are impractical (e.g., encrypting all communications, maintaining physical logs)

#### 4. Standard Carveouts
All of the following carveouts should be present:
- [ ] **Public knowledge**: Information that is or becomes publicly available through no fault of the receiving party
- [ ] **Prior possession**: Information already known to the receiving party before disclosure
- [ ] **Independent development**: Information independently developed without use of or reference to confidential information
- [ ] **Third-party receipt**: Information rightfully received from a third party without restriction
- [ ] **Legal compulsion**: Right to disclose when required by law, regulation, or legal process (with notice to the disclosing party where legally permitted)

#### 5. Permitted Disclosures
- [ ] **Employees**: Can share with employees who need to know
- [ ] **Contractors/advisors**: Can share with contractors, advisors, and professional consultants under similar confidentiality obligations
- [ ] **Affiliates**: Can share with affiliates (if needed for the business purpose)
- [ ] **Legal/regulatory**: Can disclose as required by law or regulation

#### 6. Term and Duration
- [ ] **Agreement term**: Reasonable period for the business relationship (1-3 years is standard)
- [ ] **Confidentiality survival**: Obligations survive for a reasonable period after termination (2-5 years is standard; trade secrets may be longer)
- [ ] **Not perpetual**: Avoid indefinite or perpetual confidentiality obligations (exception: trade secrets, which may warrant longer protection)

#### 7. Return and Destruction
- [ ] **Obligation triggered**: On termination or upon request
- [ ] **Reasonable scope**: Return or destroy confidential information and all copies
- [ ] **Retention exception**: Allows retention of copies required by law, regulation, or internal compliance/backup policies
- [ ] **Certification**: Certification of destruction is reasonable; sworn affidavit is onerous

#### 8. Remedies
- [ ] **Injunctive relief**: Acknowledgment that breach may cause irreparable harm and equitable relief may be appropriate is standard
- [ ] **No pre-determined damages**: Avoid liquidated damages clauses in NDAs
- [ ] **Not one-sided**: Remedies provisions apply equally to both parties (in mutual NDAs)

#### 9. Problematic Provisions to Flag
- [ ] **No non-solicitation**: NDA should not contain employee non-solicitation provisions
- [ ] **No non-compete**: NDA should not contain non-compete provisions
- [ ] **No exclusivity**: NDA should not restrict either party from entering similar discussions with others
- [ ] **No standstill**: NDA should not contain standstill or similar restrictive provisions (unless M&A context)
- [ ] **No residuals clause** (or narrowly scoped): If a residuals clause is present, it should be limited to information retained in unaided memory of individuals and should not apply to trade secrets or patented information
- [ ] **No IP assignment or license**: NDA should not grant any intellectual property rights
- [ ] **No audit rights**: Unusual in standard NDAs

#### 10. Governing Law and Jurisdiction
- [ ] **Reasonable jurisdiction**: A well-established commercial jurisdiction
- [ ] **Consistent**: Governing law and jurisdiction should be in the same or related jurisdictions
- [ ] **No mandatory arbitration** (in standard NDAs): Litigation is generally preferred for NDA disputes

### Step 4: Classify

Based on the screening results, assign a classification:

#### GREEN -- Standard Approval

**All** of the following must be true:
- NDA is mutual (or unilateral in the appropriate direction)
- All standard carveouts are present
- Term is within standard range (1-3 years, survival 2-5 years)
- No non-solicitation, non-compete, or exclusivity provisions
- No residuals clause, or residuals clause is narrowly scoped
- Reasonable governing law jurisdiction
- Standard remedies (no liquidated damages)
- Permitted disclosures include employees, contractors, and advisors
- Return/destruction provisions include retention exception for legal/compliance
- Definition of confidential information is reasonably scoped

**Routing**: Approve via standard delegation of authority. No counsel review required.
- **Action**: Proceed to signature with standard delegation of authority

#### YELLOW -- Counsel Review Needed

**One or more** of the following are present, but the NDA is not fundamentally problematic:
- Definition of confidential information is broader than preferred but not unreasonable
- Term is longer than standard but within market range (e.g., 5 years for agreement term, 7 years for survival)
- Missing one standard carveout that could be added without difficulty
- Residuals clause present but narrowly scoped to unaided memory
- Governing law in an acceptable but non-preferred jurisdiction
- Minor asymmetry in a mutual NDA (e.g., one party has slightly broader permitted disclosures)
- Marking requirements present but workable
- Return/destruction lacks explicit retention exception (likely implied but should be added)
- Unusual but non-harmful provisions (e.g., obligation to notify of potential breach)

**Routing**: Flag specific issues for counsel review. Counsel can likely resolve with minor redlines in a single review pass.
- **Action**: Counsel can likely resolve in a single review pass

#### RED -- Significant Issues

**One or more** of the following are present:
- **Unilateral when mutual is required** (or wrong direction for the relationship)
- **Missing critical carveouts** (especially independent development or legal compulsion)
- **Non-solicitation or non-compete provisions** embedded in the NDA
- **Exclusivity or standstill provisions** without appropriate business context
- **Unreasonable term** (10+ years, or perpetual without trade secret justification)
- **Overbroad definition** that could capture public information or independently developed materials
- **Broad residuals clause** that effectively creates a license to use confidential information
- **IP assignment or license grant** hidden in the NDA
- **Liquidated damages or penalty provisions**
- **Audit rights** without reasonable scope or notice requirements
- **Highly unfavorable jurisdiction** with mandatory arbitration
- **The document is not actually an NDA** (contains substantive commercial terms, exclusivity, or other obligations beyond confidentiality)

**Routing**: Full legal review required. Do not sign. Requires negotiation, counterproposal with the organization's standard form NDA, or rejection.
- **Action**: Do not sign; requires negotiation or counterproposal

### Step 5: Generate Triage Report

Output a structured report:

```
## NDA Triage Report

**Classification**: [GREEN / YELLOW / RED]
**Parties**: [party names]
**Type**: [Mutual / Unilateral (disclosing) / Unilateral (receiving)]
**Term**: [duration]
**Governing Law**: [jurisdiction]
**Review Basis**: [Playbook / Default Standards]

## Screening Results

| Criterion | Status | Notes |
|-----------|--------|-------|
| Mutual Obligations | [PASS/FLAG/FAIL] | [details] |
| Definition Scope | [PASS/FLAG/FAIL] | [details] |
| Term | [PASS/FLAG/FAIL] | [details] |
| Standard Carveouts | [PASS/FLAG/FAIL] | [details] |
| [etc.] | | |

## Issues Found

### [Issue 1 -- YELLOW/RED]
**What**: [description]
**Risk**: [what could go wrong]
**Suggested Fix**: [specific language or approach]

[Repeat for each issue]

## Recommendation

[Specific next step: approve, send for review with specific notes, or reject/counter]

## Next Steps

1. [Action item 1]
2. [Action item 2]
```

### Step 6: Routing Suggestion

Based on the classification, recommend the appropriate next step:

| Classification | Recommended Action | Typical Timeline |
|---|---|---|
| GREEN | Approve and route for signature per delegation of authority | Same day |
| YELLOW | Send to designated reviewer with specific issues flagged | 1-2 business days |
| RED | Engage counsel for full review; prepare counterproposal or standard form | 3-5 business days |

For YELLOW and RED classifications:
- Identify the specific person or role that should review (if the organization has defined routing rules)
- Include a brief summary of issues suitable for the reviewer to quickly understand the key points
- If the organization has a standard form NDA, recommend sending it as a counterproposal for RED-classified NDAs

## Common NDA Issues and Standard Positions

### Issue: Overbroad Definition of Confidential Information
**Standard position**: Confidential information should be limited to non-public information disclosed in connection with the stated purpose, with clear exclusions.
**Redline approach**: Narrow the definition to information that is marked or identified as confidential, or that a reasonable person would understand to be confidential given the nature of the information and circumstances of disclosure.

### Issue: Missing Independent Development Carveout
**Standard position**: Must include a carveout for information independently developed without reference to or use of the disclosing party's confidential information.
**Risk if missing**: Could create claims that internally-developed products or features were derived from the counterparty's confidential information.
**Redline approach**: Add standard independent development carveout.

### Issue: Non-Solicitation of Employees
**Standard position**: Non-solicitation provisions do not belong in NDAs. They are appropriate in employment agreements, M&A agreements, or specific commercial agreements.
**Redline approach**: Delete the provision entirely. If the counterparty insists, limit to targeted solicitation (not general recruitment) and set a short term (12 months).

### Issue: Broad Residuals Clause
**Standard position**: Resist residuals clauses. If required, limit to: (a) general ideas, concepts, know-how, or techniques retained in the unaided memory of individuals who had authorized access; (b) explicitly exclude trade secrets and patentable information; (c) does not grant any IP license.
**Risk if too broad**: Effectively grants a license to use the disclosing party's confidential information for any purpose.

### Issue: Perpetual Confidentiality Obligation
**Standard position**: 2-5 years from disclosure or termination, whichever is later. Trade secrets may warrant protection for as long as they remain trade secrets.
**Redline approach**: Replace perpetual obligation with a defined term. Offer a trade secret carveout for longer protection of qualifying information.

## Notes

- If the document is not actually an NDA (e.g., it's labeled as an NDA but contains substantive commercial terms), flag this immediately as a RED and recommend full contract review instead
- For NDAs that are part of a larger agreement (e.g., confidentiality section in an MSA), note that the broader agreement context may affect the analysis
- Always note that this is a screening tool and counsel should review any items the user is uncertain about$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/legal/skills/vendor-check', 'business', 'vendor-check', '', 'vendor-check', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /vendor-check -- Vendor Agreement Status

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Check the status of existing agreements with a vendor across all connected systems. Provides a consolidated view of the legal relationship.

**Important**: This command assists with legal workflows but does not provide legal advice. Agreement status reports should be verified against original documents by qualified legal professionals.

## Invocation

```
/vendor-check [vendor name]
```

If no vendor name is provided, prompt the user to specify which vendor to check.

## Workflow

### Step 1: Identify the Vendor

Accept the vendor name from the user. Handle common variations:
- Full legal name vs. trade name (e.g., "Alphabet Inc." vs. "Google")
- Abbreviations (e.g., "AWS" vs. "Amazon Web Services")
- Parent/subsidiary relationships

Ask the user to clarify if the vendor name is ambiguous.

### Step 2: Search Connected Systems

Search for the vendor across all available connected systems, in priority order:

#### CLM (Contract Lifecycle Management) -- If Connected
Search for all contracts involving the vendor:
- Active agreements
- Expired agreements (last 3 years)
- Agreements in negotiation or pending signature
- Amendments and addenda

#### CRM -- If Connected
Search for the vendor/account record:
- Account status and relationship type
- Associated opportunities or deals
- Contact information for vendor's legal/contracts team

#### Email -- If Connected
Search for recent relevant correspondence:
- Contract-related emails (last 6 months)
- NDA or agreement attachments
- Negotiation threads

#### Documents (e.g., Box, Egnyte, SharePoint) -- If Connected
Search for:
- Executed agreements
- Redlines and drafts
- Due diligence materials

#### Chat (e.g., Slack, Teams) -- If Connected
Search for recent mentions:
- Contract requests involving this vendor
- Legal questions about the vendor
- Relevant team discussions (last 3 months)

### Step 3: Compile Agreement Status

For each agreement found, report:

| Field | Details |
|-------|---------|
| **Agreement Type** | NDA, MSA, SOW, DPA, SLA, License Agreement, etc. |
| **Status** | Active, Expired, In Negotiation, Pending Signature |
| **Effective Date** | When the agreement started |
| **Expiration Date** | When it expires or renews |
| **Auto-Renewal** | Yes/No, with renewal term and notice period |
| **Key Terms** | Liability cap, governing law, termination provisions |
| **Amendments** | Any amendments or addenda on file |

### Step 4: Gap Analysis

Identify what agreements exist and what might be missing:

```
## Agreement Coverage

[CHECK] NDA -- [status]
[CHECK/MISSING] MSA -- [status or "Not found"]
[CHECK/MISSING] DPA -- [status or "Not found"]
[CHECK/MISSING] SOW(s) -- [status or "Not found"]
[CHECK/MISSING] SLA -- [status or "Not found"]
[CHECK/MISSING] Insurance Certificate -- [status or "Not found"]
```

Flag any gaps that may be needed based on the relationship type (e.g., if there is an MSA but no DPA and the vendor handles personal data).

### Step 5: Generate Report

Output a consolidated report:

```
## Vendor Agreement Status: [Vendor Name]

**Search Date**: [today's date]
**Sources Checked**: [list of systems searched]
**Sources Unavailable**: [list of systems not connected, if any]

## Relationship Overview

**Vendor**: [full legal name]
**Relationship Type**: [vendor/partner/customer/etc.]
**CRM Status**: [if available]

## Agreement Summary

### [Agreement Type 1] -- [Status]
- **Effective**: [date]
- **Expires**: [date] ([auto-renews / does not auto-renew])
- **Key Terms**: [summary of material terms]
- **Location**: [where the executed copy is stored]

### [Agreement Type 2] -- [Status]
[etc.]

## Gap Analysis

[What's in place vs. what may be needed]

## Upcoming Actions

- [Any approaching expirations or renewal deadlines]
- [Required agreements not yet in place]
- [Amendments or updates that may be needed]

## Notes

[Any relevant context from email/chat searches]
```

### Step 6: Handle Missing Sources

If key systems are not connected via MCP:

- **No CLM**: Note that no CLM is connected. Suggest the user check their CLM manually. Report what was found in other systems.
- **No CRM**: Skip CRM context. Note the gap.
- **No Email**: Note that email was not searched. Suggest the user search their email for "[vendor name] agreement" or "[vendor name] NDA".
- **No Documents**: Note that document storage was not searched.

Always clearly state which sources were checked and which were not, so the user knows the completeness of the report.

## Notes

- If no agreements are found in any connected system, report that clearly and ask the user if they have agreements stored elsewhere
- For vendor groups (e.g., a vendor with multiple subsidiaries), ask whether the user wants to check a specific entity or the entire group
- Flag any agreements that are expired but may still have surviving obligations (confidentiality, indemnification, etc.)
- If an agreement is approaching expiration (within 90 days), highlight this prominently$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/brand-review', 'business', 'brand-review', '', 'brand-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Brand Review

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Review marketing content against brand voice, style guidelines, and messaging standards. Flag deviations and provide specific improvement suggestions.

## Trigger

User runs `/brand-review` or asks to review, check, or audit content against brand guidelines.

## Inputs

1. **Content to review** — accept content in any of these forms:
   - Pasted directly into the conversation
   - A file path or ~~knowledge base reference (e.g. Notion page, shared doc)
   - A URL to a published page
   - Multiple pieces for batch review

2. **Brand guidelines source** (determined automatically):
   - If a brand style guide is configured in local settings, use it automatically
   - If not configured, ask: "Do you have a brand style guide or voice guidelines I should review against? You can paste them, share a file, or describe your brand voice. Otherwise, I'll do a general review for clarity, consistency, and professionalism."

## Review Process

### With Brand Guidelines Configured

Evaluate the content against each of these dimensions:

#### Voice and Tone
- Does the content match the defined brand voice attributes?
- Is the tone appropriate for the content type and audience?
- Are there shifts in voice that feel inconsistent?
- Flag specific sentences or phrases that deviate with an explanation of why

#### Terminology and Language
- Are preferred brand terms used correctly?
- Are any "avoid" terms or phrases present?
- Is jargon level appropriate for the target audience?
- Are product names, feature names, and branded terms used correctly (capitalization, formatting)?

#### Messaging Pillars
- Does the content align with defined messaging pillars or value propositions?
- Are claims consistent with approved messaging?
- Is the content reinforcing or contradicting brand positioning?

#### Style Guide Compliance
- Grammar and punctuation per style guide (e.g., Oxford comma, title case vs. sentence case)
- Formatting conventions (headers, lists, emphasis)
- Number formatting, date formatting
- Acronym usage (defined on first use?)

### Without Brand Guidelines (Generic Review)

Evaluate the content for:

#### Clarity
- Is the main message clear within the first paragraph?
- Are sentences concise and easy to understand?
- Is the structure logical and easy to follow?
- Are there ambiguous statements or unclear references?

#### Consistency
- Is the tone consistent throughout?
- Are terms used consistently (no switching between synonyms for the same concept)?
- Is formatting consistent (headers, lists, capitalization)?

#### Professionalism
- Is the content free of typos, grammatical errors, and awkward phrasing?
- Is the tone appropriate for the intended audience?
- Are claims supported or substantiated?

### Legal and Compliance Flags (Always Checked)

Regardless of whether brand guidelines are configured, flag:
- **Unsubstantiated claims** — superlatives ("best", "fastest", "only") without evidence or qualification
- **Missing disclaimers** — financial claims, health claims, or guarantees that may need legal disclaimers
- **Comparative claims** — comparisons to competitors that could be challenged
- **Regulatory language** — content that may need compliance review (financial services, healthcare, etc.)
- **Testimonial issues** — quotes or endorsements without attribution or disclosure
- **Copyright concerns** — content that appears to be closely paraphrased from other sources

## Brand Voice Reference

Use these frameworks to evaluate content against brand standards or to help the user document their brand voice.

### Brand Voice Documentation Framework

A complete brand voice document should cover these areas:

1. **Brand Personality** — Define the brand as if it were a person. Example: "If our brand were a person, they would be a knowledgeable colleague who explains complex things simply, celebrates your wins genuinely, and never talks down to you."
2. **Voice Attributes** — 3-5 attributes that define how the brand communicates, each defined with what it means in practice, what it does NOT mean (to prevent misinterpretation), and an example.
3. **Audience Awareness** — Who the brand is speaking to (primary and secondary), what they care about, their level of expertise, and how they expect to be addressed.
4. **Core Messaging Pillars** — 3-5 key themes the brand consistently communicates, the hierarchy of these messages, and how each pillar connects to audience needs.
5. **Tone Spectrum** — How the voice adapts across contexts while remaining recognizably the same brand.
6. **Style Rules** — Specific grammar, formatting, and language rules.
7. **Terminology** — Preferred and avoided terms.

### Voice Attribute Spectrums

When defining or evaluating brand voice, position attributes on a spectrum:

| Spectrum | One End | Other End |
|----------|---------|-----------|
| Formality | Formal, institutional | Casual, conversational |
| Authority | Expert, authoritative | Peer-level, collaborative |
| Emotion | Warm, empathetic | Direct, matter-of-fact |
| Complexity | Technical, precise | Simple, accessible |
| Energy | Bold, energetic | Calm, measured |
| Humor | Playful, witty | Serious, earnest |
| Innovation | Cutting-edge, forward-looking | Established, proven |

For each chosen attribute, document it in this format:

**[Attribute name]**
- **We are**: [what this means in practice]
- **We are not**: [common misinterpretation to avoid]
- **This sounds like**: [example sentence demonstrating the attribute]
- **This does NOT sound like**: [example sentence violating the attribute]

Example:

**Approachable**
- **We are**: friendly, clear, jargon-free, welcoming to beginners and experts alike
- **We are not**: dumbed-down, overly casual, or lacking substance
- **This sounds like**: "Here's how to get started — it takes about five minutes."
- **This does NOT sound like**: "Yo! This is super easy, even a noob can do it lol."

### Tone Adaptation Across Channels and Contexts

The brand voice stays consistent, but tone adapts to context. Tone is the emotional inflection applied to the voice.

#### Tone by Channel

| Channel | Tone Adaptation | Example |
|---------|----------------|---------|
| Blog | Informative, conversational, educational | "Let's walk through how this works and why it matters for your team." |
| Social media (LinkedIn) | Professional, thought-provoking, concise | "Three things we learned from running 50 campaigns this quarter." |
| Social media (Twitter/X) | Punchy, direct, sometimes witty | "Your landing page has 3 seconds. Make them count." |
| Email marketing | Personal, helpful, action-oriented | "We put together something we think you'll find useful." |
| Sales collateral | Confident, benefit-driven, specific | "Teams using our platform reduce reporting time by 40%." |
| Support/Help docs | Clear, patient, step-by-step | "If you see this error, here's how to fix it." |
| Press release | Formal, factual, newsworthy | "The company today announced the launch of..." |
| Error messages | Empathetic, helpful, blame-free | "Something went wrong on our end. We're looking into it." |

#### Tone by Situation

| Situation | Tone Adaptation |
|-----------|----------------|
| Product launch | Excited, confident, forward-looking |
| Incident or outage | Transparent, empathetic, accountable |
| Customer success story | Celebratory, specific, crediting the customer |
| Thought leadership | Authoritative, nuanced, evidence-based |
| Onboarding | Welcoming, encouraging, clear |
| Bad news (price increase, deprecation) | Honest, respectful, solution-oriented |
| Competitive comparison | Confident but fair, fact-based, not disparaging |

#### Tone Adaptation Rule
The voice attributes remain fixed. Tone dials them up or down based on context. For example, if a brand is "bold and warm":
- In a product launch, dial up boldness
- In an incident response, dial up warmth
- Neither attribute disappears; the balance shifts

### Style Guide Enforcement

#### Grammar and Mechanics
Document and enforce these choices consistently:

| Rule | Options | Example |
|------|---------|---------|
| Oxford comma | Yes / No | "fast, reliable, and secure" vs. "fast, reliable and secure" |
| Sentence case vs. title case (headings) | Sentence / Title | "How to get started" vs. "How to Get Started" |
| Contractions | Use / Avoid | "we're" vs. "we are" |
| Em dash spacing | No spaces / Spaces | "this—and more" vs. "this — and more" |
| Numbers | Spell out 1-9, numerals 10+ / Always numerals | "five features" vs. "5 features" |
| Percent | % / percent | "50%" vs. "50 percent" |
| Date format | Month DD, YYYY / DD/MM/YYYY / etc. | "January 15, 2025" |
| Time format | 12-hour / 24-hour | "3:00 PM" vs. "15:00" |
| Lists | Periods / No periods on fragments | "Set up your account." vs. "Set up your account" |

#### Formatting Conventions
- Heading hierarchy (when to use H1, H2, H3)
- Bold and italic usage (bold for emphasis, italic for titles/terms)
- Link text (descriptive vs. "click here" — always descriptive)
- Image alt text requirements
- Code formatting (for technical brands)
- Callout or highlight box usage

#### Punctuation and Emphasis
- Exclamation mark policy (limited use, never more than one)
- Ellipsis usage (avoid in most professional contexts)
- ALL CAPS policy (avoid; use bold for emphasis instead)
- Emoji usage by channel (professional channels: minimal or none; social: where appropriate)

### Terminology Management

#### Preferred Terms

Maintain a list of preferred terms and their incorrect alternatives:

| Use This | Not This | Notes |
|----------|----------|-------|
| sign up (verb) | signup (verb) | "signup" is the noun form |
| log in (verb) | login (verb) | "login" is the noun/adjective form |
| set up (verb) | setup (verb) | "setup" is the noun/adjective form |
| email | e-mail | No hyphen |
| website | web site | One word |
| data is (singular) | data are | Unless the publication requires plural |

#### Product and Feature Names
- Official capitalization for product names
- When to use the full product name vs. shorthand
- Whether to use "the" before product names
- How to handle versioning in copy
- Trademark and registration symbols (when required and when to omit)

#### Inclusive Language
- Use gender-neutral language (they/them for unknown individuals)
- Avoid ableist language ("crazy", "blind spot", "lame")
- Use person-first language where appropriate
- Avoid culturally specific idioms that may not translate
- Use "simple" or "straightforward" instead of "easy" (what is easy varies by person)

#### Industry Jargon Management
- Define which technical terms the audience understands without explanation
- List jargon that should always be defined or replaced with plain language
- Specify which acronyms need to be spelled out on first use
- Audience-specific glossary for terms that mean different things to different readers

#### Competitor and Category Terms
- How to refer to your product category (use your preferred framing)
- How to refer to competitors (by name or generically)
- Terms competitors have coined that you should avoid (to prevent reinforcing their positioning)
- Your preferred differentiation language

## Output Format

Present the review as:

### Summary
- Overall assessment: how well the content aligns with brand standards (or general quality)
- 1-2 sentence summary of the biggest strengths
- 1-2 sentence summary of the most important improvements

### Detailed Findings

For each issue found, provide:

| Issue | Location | Severity | Suggestion |
|-------|----------|----------|------------|

Where severity is:
- **High** — contradicts brand voice, contains compliance risk, or significantly undermines messaging
- **Medium** — inconsistent with guidelines but not damaging
- **Low** — minor style or preference issue

### Revised Sections

For the top 3-5 highest-severity issues, provide a before/after showing the original text and a suggested revision.

### Legal/Compliance Flags

List any legal or compliance concerns separately with recommended actions.

## After Review

Ask: "Would you like me to:
- Revise the full content with these suggestions applied?
- Focus on fixing just the high-severity issues?
- Review additional content against the same guidelines?
- Help you document your brand voice for future reviews?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/campaign-plan', 'business', 'campaign-plan', '', 'campaign-plan', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Campaign Plan

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Generate a comprehensive marketing campaign brief with objectives, audience, messaging, channel strategy, content calendar, and success metrics.

## Trigger

User runs `/campaign-plan` or asks to plan, design, or build a marketing campaign.

## Inputs

Gather the following from the user. If not provided, ask before proceeding:

1. **Campaign goal** — the primary objective (e.g., drive signups, increase awareness, launch a product, generate leads, re-engage churned users)

2. **Target audience** — who the campaign is aimed at (demographics, roles, industries, pain points, buying stage)

3. **Timeline** — campaign duration and any fixed dates (launch date, event date, seasonal deadline)

4. **Budget range** — approximate budget or budget tier (optional; if not provided, generate a channel-agnostic plan and note where budget allocation would matter)

5. **Additional context** (optional):
   - Product or service being promoted
   - Key differentiators or value propositions
   - Previous campaign performance or learnings
   - Brand guidelines or constraints
   - Geographic focus

## Campaign Brief Structure

Generate a campaign brief with the following sections:

### 1. Campaign Overview
- Campaign name suggestion
- One-sentence campaign summary
- Primary objective with a specific, measurable goal
- Secondary objectives (if applicable)

### 2. Target Audience
- Primary audience segment with description
- Secondary audience segment (if applicable)
- Audience pain points and motivations
- Where they spend time (channels, communities, publications)
- Buying stage alignment (awareness, consideration, decision)

### 3. Key Messages
- Core campaign message (one sentence)
- 3-4 supporting messages tailored to audience pain points
- Message variations by channel (if different tones are needed)
- Proof points or evidence to support each message

### 4. Channel Strategy
Recommend channels based on audience and goal. For each channel, include:
- Why this channel fits the audience and objective
- Content format recommendations
- Estimated effort level (low, medium, high)
- Budget allocation suggestion (if budget was provided)

Consider channels from:
- Owned: blog, email, website, social media profiles
- Earned: PR, influencer partnerships, guest posts, community engagement
- Paid: search ads, social ads, display, sponsored content, events

### 5. Content Calendar
Create a week-by-week (or day-by-day for short campaigns) content calendar:
- What content to produce each week
- Which channel each piece targets
- Key milestones and deadlines
- Dependencies between pieces (e.g., "landing page must be live before paid ads launch")

Format as a table:

| Week | Content Piece | Channel | Owner/Notes | Status |
|------|--------------|---------|-------------|--------|

### 6. Content Pieces Needed
List every content asset required for the campaign:
- Asset name and type (blog post, email, social post, ad creative, landing page, etc.)
- Brief description of what it should contain
- Priority (must-have vs. nice-to-have)
- Suggested timeline for creation

### 7. Success Metrics
Define KPIs aligned to the campaign objective:
- Primary KPI with target number
- Secondary KPIs (3-5)
- How each metric will be tracked
- Reporting cadence recommendation

If ~~product analytics is connected, reference any available historical performance benchmarks to inform targets.

### 8. Budget Allocation (if budget provided)
- Breakdown by channel or activity
- Production costs vs. distribution costs
- Contingency recommendation (typically 10-15%)

### 9. Risks and Mitigations
- 2-3 potential risks (timeline, audience mismatch, channel underperformance)
- Mitigation strategy for each

### 10. Next Steps
- Immediate action items to kick off the campaign
- Stakeholder approvals needed
- Key decision points

## Planning Reference

### Campaign Framework: Objective, Audience, Message, Channel, Measure

Every campaign should be built on this five-part framework:

#### Objective
Define what success looks like before planning anything else.

- **Awareness**: increase brand or product visibility (measured by reach, impressions, share of voice)
- **Consideration**: drive engagement and education (measured by content engagement, email signups, webinar attendance)
- **Conversion**: generate leads or sales (measured by signups, demos, purchases, pipeline)
- **Retention**: re-engage existing customers (measured by churn reduction, upsell, NPS)
- **Advocacy**: turn customers into promoters (measured by referrals, reviews, UGC)

Good objectives are SMART: Specific, Measurable, Achievable, Relevant, Time-bound.

Example: "Generate 200 marketing qualified leads from mid-market SaaS companies in North America within 6 weeks of campaign launch."

#### Audience
Define who you are trying to reach with enough specificity to guide messaging and channel decisions.

- **Demographics**: role/title, seniority, company size, industry
- **Psychographics**: motivations, pain points, goals, objections
- **Behavioral**: where they consume content, how they buy, what they have engaged with before
- **Buying stage**: are they unaware of the problem, researching solutions, or ready to buy?

Create a brief audience profile (not a full persona) for campaign planning:
> "[Role] at [company type] who is struggling with [pain point] and looking for [desired outcome]. They typically discover solutions through [channels] and care most about [priorities]."

#### Message
Craft the core message and supporting points that will resonate with the audience.

- **Core message**: one sentence that captures what you want the audience to think, feel, or do
- **Supporting messages**: 3-4 points that provide evidence, address objections, or elaborate on benefits
- **Proof points**: data, case studies, testimonials, or third-party validation for each supporting message
- **Differentiation**: what makes your offering different from alternatives (including doing nothing)

Message hierarchy:
1. Why should I care? (addresses the pain point or opportunity)
2. What is the solution? (positions your offering)
3. Why you? (differentiates from alternatives)
4. What should I do? (call to action)

#### Channel
Select channels based on where your audience is, not where you are most comfortable. See the Channel Selection Guide below.

#### Measure
Define how you will know the campaign worked. See Success Metrics by Campaign Type below.

### Channel Selection Guide

#### Owned Channels

| Channel | Best For | Typical Metrics | Effort |
|---------|----------|----------------|--------|
| Blog/Website | SEO, thought leadership, education | Traffic, time on page, conversions | Medium |
| Email | Nurture, retention, announcements | Open rate, CTR, conversions | Low-Medium |
| Social (organic) | Awareness, community, brand building | Engagement, reach, follower growth | Medium |
| Webinars | Education, lead gen, product demos | Registrations, attendance, pipeline | High |
| Podcast | Thought leadership, brand awareness | Downloads, subscriber growth | High |

#### Earned Channels

| Channel | Best For | Typical Metrics | Effort |
|---------|----------|----------------|--------|
| PR/Media | Awareness, credibility, launches | Coverage, share of voice, referral traffic | High |
| Guest content | Audience expansion, SEO, credibility | Referral traffic, backlinks | Medium |
| Influencer/Partner | Audience expansion, trust | Reach, engagement, referral conversions | Medium-High |
| Community | Awareness, trust, feedback | Mentions, engagement, referral traffic | Medium |
| Reviews/Ratings | Credibility, SEO, consideration | Review volume, rating, conversion lift | Low-Medium |

#### Paid Channels

| Channel | Best For | Typical Metrics | Effort |
|---------|----------|----------------|--------|
| Search ads (SEM) | High-intent lead capture | CPC, CTR, conversion rate, CPA | Medium |
| Social ads | Awareness, retargeting, lead gen | CPM, CPC, CTR, CPA, ROAS | Medium |
| Display/Programmatic | Awareness, retargeting | Impressions, CPM, view-through conversions | Low-Medium |
| Sponsored content | Thought leadership, lead gen | Engagement, leads, cost per lead | Medium |
| Events/Sponsorships | Relationship building, brand | Leads, meetings, pipeline influenced | High |

#### Channel Selection Criteria
When choosing channels, consider:
- Where does your target audience spend time?
- What is the buying stage you are targeting? (awareness channels vs. conversion channels)
- What is your budget? (paid channels require spend; owned/earned require time)
- What content assets do you already have or can you produce?
- What has worked in the past? (reference historical data if available)

### Content Calendar Creation

#### Calendar Planning Process
1. **Start with milestones**: campaign launch, event dates, product releases, seasonal moments
2. **Work backward**: what needs to be live and when? What is the production lead time?
3. **Map content to funnel stages**: ensure coverage across awareness, consideration, and conversion
4. **Batch by theme**: group related content pieces into weekly or bi-weekly themes
5. **Balance channels**: do not over-index on one channel; ensure the audience sees the campaign across touchpoints
6. **Build in flexibility**: leave 20% of calendar slots open for reactive or opportunistic content

#### Content Cadence Guidelines
- **Blog**: 1-4 posts per week depending on team size and goals
- **Email newsletter**: weekly or bi-weekly for most audiences
- **Social media**: 3-7 posts per week per platform (varies by platform)
- **Paid campaigns**: continuous during campaign window with creative refreshes every 2-4 weeks
- **Webinars**: monthly or quarterly depending on resources

#### Production Timeline Benchmarks
- Blog post: 3-5 business days (research, draft, review, publish)
- Email campaign: 2-3 business days (copy, design, test, send)
- Social media posts: 1-2 business days (draft, design, schedule)
- Landing page: 5-7 business days (copy, design, development, QA)
- Video content: 2-4 weeks (script, production, editing)
- Ebook/whitepaper: 2-4 weeks (outline, draft, design, review)

### Budget Allocation Approaches

#### Percentage of Revenue Method
- Industry benchmark: 5-15% of revenue for marketing, with B2B typically at 5-10% and B2C at 10-15%
- Startups and growth-stage companies often invest 15-25% of revenue in marketing
- Within the marketing budget, allocate across brand (long-term) and performance (short-term)

#### Channel Allocation Framework
A common starting framework (adjust based on goals and historical data):

| Category | Percentage of Budget | Examples |
|----------|---------------------|----------|
| Paid acquisition | 30-40% | Search ads, social ads, display |
| Content production | 20-30% | Blog, video, design, ebooks |
| Events and sponsorships | 10-20% | Conferences, webinars, meetups |
| Tools and technology | 10-15% | Analytics, automation, CRM |
| Testing and experimentation | 5-10% | New channels, A/B tests, pilots |

#### Budget Optimization Principles
- Start with your highest-confidence channel and allocate 60-70% of paid budget there
- Reserve 15-20% for testing new channels or tactics
- Shift budget monthly based on performance data (do not set and forget)
- Account for production costs, not just media spend
- Include a 10-15% contingency for unexpected opportunities or overruns

### Success Metrics by Campaign Type

#### Awareness Campaign
| Metric | What It Measures |
|--------|-----------------|
| Reach/Impressions | How many people saw the campaign |
| Brand mention volume | Increase in brand conversations |
| Share of voice | Your mentions vs. competitors |
| Direct traffic | People coming to your site unprompted |
| Social follower growth | Audience building |

#### Lead Generation Campaign
| Metric | What It Measures |
|--------|-----------------|
| Total leads | Volume of new contacts |
| Marketing qualified leads (MQLs) | Leads meeting quality threshold |
| Cost per lead (CPL) | Efficiency of spend |
| Lead-to-MQL conversion rate | Quality of leads generated |
| Pipeline influenced | Revenue opportunity created |

#### Product Launch Campaign
| Metric | What It Measures |
|--------|-----------------|
| Signups or trials | Adoption of new product |
| Activation rate | Users who complete key first action |
| Media coverage | Earned media hits |
| Social buzz | Mentions, shares, engagement spike |
| Feature adoption | Usage of specific launched features |

#### Retention/Engagement Campaign
| Metric | What It Measures |
|--------|-----------------|
| Churn rate change | Customer retention improvement |
| Engagement rate | Interactions with campaign content |
| NPS or CSAT change | Satisfaction improvement |
| Upsell/cross-sell revenue | Expansion revenue |
| Feature adoption | Usage of promoted features |

#### Event/Webinar Campaign
| Metric | What It Measures |
|--------|-----------------|
| Registrations | Interest generated |
| Attendance rate | Conversion from registration |
| Engagement during event | Questions, polls, chat activity |
| Post-event conversions | Leads or pipeline from attendees |
| Content repurposing reach | Downstream audience from recordings |

## Output

Present the full campaign brief with clear headings and formatting. After the brief, ask:

"Would you like me to:
- Dive deeper into any section?
- Draft specific content pieces from the calendar?
- Create a competitive analysis to inform the messaging?
- Adjust the plan for a different budget or timeline?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/competitive-brief', 'business', 'competitive-brief', '', 'competitive-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Competitive Brief

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Research competitors and generate a structured competitive analysis comparing positioning, messaging, content strategy, and market presence.

## Trigger

User runs `/competitive-brief` or asks for a competitive analysis, competitor research, or market comparison.

## Inputs

Gather the following from the user:

1. **Competitor name(s)** — one or more competitors to analyze (required)

2. **Your company/product context** (optional but recommended):
   - What you sell and to whom
   - Your positioning or value proposition
   - Key differentiators you want to highlight

3. **Focus areas** (optional — if not specified, cover all):
   - Messaging and positioning
   - Product and feature comparison
   - Content and thought leadership strategy
   - Recent announcements and news
   - Pricing and packaging (if publicly available)
   - Market presence and audience

## Research Process

For each competitor, research using web search:

1. **Company website** — homepage messaging, product pages, about page, pricing page
2. **Recent news** — press releases, funding announcements, product launches, partnerships (last 6 months)
3. **Content strategy** — blog topics, resource types, social media presence, webinars, podcasts
4. **Review sites and comparisons** — third-party comparisons, analyst mentions, customer review themes
5. **Job postings** — hiring signals that indicate strategic direction (optional)

### Research Sources

Gather intelligence from these categories of sources:

#### Primary Sources (Direct from Competitor)
- **Website**: homepage, product pages, pricing, about page, careers
- **Blog and resource center**: content themes, publishing frequency, depth
- **Social media profiles**: messaging, engagement, content strategy
- **Product demos and free trials**: UX, features, onboarding experience
- **Webinars and events**: topics, speakers, audience engagement
- **Press releases and newsroom**: announcements, partnerships, milestones
- **Job postings**: hiring signals that reveal strategic priorities (e.g., hiring for a new product line or market)

#### Secondary Sources (Third-Party)
- **Review sites**: G2, Capterra, TrustRadius, Product Hunt — customer sentiment themes
- **Analyst reports**: Gartner, Forrester, IDC — market positioning and category placement
- **News coverage**: TechCrunch, industry publications — funding, partnerships, narrative
- **Social listening**: mentions, sentiment, share of voice across social platforms
- **SEO tools**: keyword rankings, organic traffic estimates, content gaps
- **Financial filings**: revenue, growth rate, investment areas (for public companies)
- **Community forums**: community forums (e.g. Reddit, Discourse), industry chat groups (e.g. Slack communities) — user sentiment

### Research Cadence
- **Deep competitive analysis**: quarterly (full research across all sources)
- **Competitive monitoring**: monthly (scan for new announcements, content, messaging changes)
- **Real-time alerts**: ongoing (set up alerts for competitor brand mentions, press, job postings)

## Competitive Brief Structure

### 1. Executive Summary
- 2-3 sentence overview of the competitive landscape
- Key takeaway: your biggest opportunity and biggest threat

### 2. Competitor Profiles

For each competitor:

#### Company Overview
- What they do (one-sentence positioning)
- Target audience
- Company size/stage indicators (funding, employee count if available)
- Key recent developments

#### Messaging Analysis
- Primary tagline or headline
- Core value proposition
- Key messaging themes (3-5)
- Tone and voice characterization
- How they describe the problem they solve

#### Product/Solution Positioning
- How they categorize their product
- Key features they emphasize
- Claimed differentiators
- Pricing approach (if publicly available)

#### Content Strategy
- Blog frequency and topics
- Content types produced (ebooks, webinars, case studies, tools)
- Social media presence and engagement approach
- Thought leadership themes
- SEO strategy observations (what terms they appear to target)

#### Strengths
- What they do well
- Where their messaging resonates
- Competitive advantages

#### Weaknesses
- Gaps in their messaging or positioning
- Areas where they are vulnerable
- Customer complaints or criticism themes (from reviews)

### 3. Messaging Comparison Matrix

| Dimension | Your Company | Competitor A | Competitor B |
|-----------|-------------|--------------|--------------|
| Primary tagline | ... | ... | ... |
| Target buyer | ... | ... | ... |
| Key differentiator | ... | ... | ... |
| Tone/voice | ... | ... | ... |
| Core value prop | ... | ... | ... |

(Include user's company only if they provided their positioning context)

### 4. Content Gap Analysis
- Topics your competitors cover that you do not (or vice versa)
- Content formats they use that you could adopt
- Keywords or themes they own vs. opportunities they have missed

### 5. Opportunities
- Positioning gaps you can exploit
- Messaging angles your competitors have not claimed
- Audience segments they are underserving
- Content or channel opportunities

### 6. Threats
- Areas where competitors are strong and you are vulnerable
- Trends that favor their positioning
- Recent moves that could shift the market

### 7. Recommended Actions
- 3-5 specific, actionable recommendations based on the analysis
- Quick wins (things you can act on this week)
- Strategic moves (longer-term positioning or content investments)

## Analysis Frameworks

### Messaging Comparison Frameworks

#### Value Proposition Comparison

For each competitor, document:
- **Promise**: what they promise the customer will achieve
- **Evidence**: how they prove the promise (data, testimonials, demos)
- **Mechanism**: how their product delivers on the promise (the "how it works")
- **Uniqueness**: what they claim only they can do

#### Narrative Analysis

Identify each competitor's story arc:
- **Villain**: what problem or enemy they position against (status quo, legacy tools, complexity)
- **Hero**: who is the hero in their story (the customer? the product? the team?)
- **Transformation**: what before/after do they promise?
- **Stakes**: what happens if you do not act?

This reveals positioning strategy and emotional appeals.

#### Messaging Strengths and Vulnerabilities

For each competitor's messaging, assess:
- **Clarity**: can a first-time visitor understand what they do in 5 seconds?
- **Differentiation**: is their positioning distinct or generic?
- **Proof**: do they back up claims with evidence?
- **Consistency**: is messaging consistent across channels?
- **Resonance**: does their messaging address real customer pain points?

### Content Gap Analysis Methodology

#### Content Audit Comparison

Map content across competitors by:

| Topic/Theme | Your Content | Competitor A | Competitor B | Gap? |
|-------------|-------------|--------------|--------------|------|
| [Topic 1] | Blog post, ebook | Blog series, webinar | Nothing | Opportunity for B |
| [Topic 2] | Nothing | Whitepaper | Blog post, video | Gap for you |
| [Topic 3] | Case study | Nothing | Case study | Parity |

#### Content Type Coverage

| Content Format | You | Comp A | Comp B | Comp C |
|----------------|-----|--------|--------|--------|
| Blog posts | Y | Y | Y | Y |
| Case studies | Y | Y | N | Y |
| Ebooks/Whitepapers | N | Y | Y | N |
| Webinars | Y | Y | Y | N |
| Podcast | N | N | Y | N |
| Video content | N | Y | Y | Y |
| Interactive tools | N | N | N | Y |
| Templates/Resources | Y | N | Y | N |

#### Identifying Content Opportunities
1. **Topics they cover that you do not**: potential gaps in your content strategy
2. **Topics you cover that they do not**: potential differentiators to amplify
3. **Formats they use that you do not**: format gaps that could reach new audiences
4. **Audience segments they address that you do not**: underserved audiences
5. **Search terms they rank for that you do not**: SEO content gaps

#### Content Quality Assessment
- Depth: surface-level or comprehensive?
- Freshness: regularly updated or stale?
- Engagement: do posts get comments, shares, links?
- Production value: text-only or multimedia?
- Thought leadership: original insights or rehashed content?

### Positioning Strategy

#### Positioning Statement Framework

For your company and each competitor, define (or reverse-engineer) their positioning statement:

> For [target audience], [product/company] is the [category] that [key benefit/differentiator] because [reason to believe].

Example:
> For mid-market SaaS marketing teams, Acme is the campaign management platform that unifies planning and execution in one workspace because it is built on a single data model that eliminates tool fragmentation.

#### Positioning Map

Plot competitors on a 2x2 matrix using the two most important dimensions for your market:

Common axis pairs:
- **Price vs. Capability** (low cost / basic vs. premium / full-featured)
- **Ease of Use vs. Power** (simple / limited vs. complex / flexible)
- **SMB Focus vs. Enterprise Focus** (self-serve / individual vs. sales-led / team)
- **Point Solution vs. Platform** (does one thing well vs. does many things)
- **Innovative vs. Established** (new approach vs. proven track record)

Identify which quadrant is underserved or where your differentiation is strongest.

#### Category Strategy
- **Create a new category**: if you do something genuinely different, define and own the category (high risk, high reward)
- **Reframe the existing category**: change how buyers evaluate the category to favor your strengths
- **Win the existing category**: compete directly on recognized criteria and out-execute
- **Niche within the category**: own a specific segment, use case, or audience

#### Positioning Pitfalls to Avoid
- Positioning against a competitor rather than for a customer need
- Claiming too many differentiators (pick 1-2 that matter most)
- Using category jargon the customer does not use
- Positioning on features rather than outcomes
- Changing positioning too frequently (confuses the market)

### Battlecard Creation

A competitive battlecard is a one-page reference for sales and marketing teams. Include:

#### Header
- Competitor name and logo
- Last updated date
- Competitive win rate (if tracked)

#### Quick Overview
- What they do (one sentence)
- Their target customer
- Pricing model summary
- Key recent developments

#### Their Pitch
- How they describe themselves
- Their primary tagline
- Their top 3 claimed differentiators

#### Strengths (Be Honest)
- Where they genuinely compete well
- What customers like about them (from reviews)
- Features or capabilities where they lead

#### Weaknesses
- Consistent customer complaints (from reviews)
- Technical limitations
- Gaps in their offering
- Areas where customers report dissatisfaction

#### Our Differentiators
- 3-5 specific ways your product or approach is different
- For each: the differentiator, why it matters to the customer, and proof

#### Objection Handling
| If the prospect says... | Respond with... |
|------------------------|----------------|
| "[Competitor] does X too" | "Here is how our approach differs..." |
| "[Competitor] is cheaper" | "Here is what that price difference gets you..." |
| "I've heard good things about [Competitor]" | "They are strong at X. Where we differ is..." |

#### Landmines to Set
Questions to ask prospects early that highlight your advantages:
- "How do you currently handle [area where competitor is weak]?"
- "How important is [capability you have that they lack]?"
- "Have you considered [risk that your product mitigates]?"

#### Landmines to Defuse
Questions competitors might encourage prospects to ask you, with prepared responses.

#### Win/Loss Themes
- Common reasons deals are won against this competitor
- Common reasons deals are lost to this competitor
- What types of prospects favor them vs. you

#### Battlecard Maintenance
- Review and update quarterly at minimum
- Update immediately after major competitor announcements
- Incorporate win/loss feedback from sales team
- Track which objection-handling responses are most effective

## Output

Present the full competitive brief with clear formatting. Note the date of the research so the user knows the freshness of the data.

After the brief, ask:

"Would you like me to:
- Create a battlecard for your sales team based on this analysis?
- Draft messaging that exploits the positioning gaps identified?
- Dive deeper into any specific competitor?
- Set up a competitive monitoring plan?"$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/marketing/skills/content-creation', 'business', 'content-creation', '', 'content-creation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Content Creation Skill

Guidelines and frameworks for creating effective marketing content across channels.

## Content Type Templates

### Blog Post Structure
1. **Headline** — clear, benefit-driven, includes primary keyword (aim for 60 characters or less for SEO)
2. **Introduction** (100-150 words) — hook the reader with a question, statistic, bold claim, or relatable scenario. State what the post will cover. Include primary keyword.
3. **Body sections** (3-5 sections) — each with a descriptive subheading (H2). Use H3 for subsections. One core idea per section with supporting evidence, examples, or data.
4. **Conclusion** (75-100 words) — summarize key takeaways, reinforce the main message, include a call to action.
5. **Meta description** — under 160 characters, includes primary keyword, compels the click.

### Social Media Post Structure
- **Hook** — first line grabs attention (question, bold statement, number)
- **Body** — 2-4 concise points or a short narrative
- **CTA** — what should the reader do next (comment, click, share, tag)
- **Hashtags** — 3-5 relevant hashtags (platform-dependent)

### Email Newsletter Structure
- **Subject line** — under 50 characters, creates curiosity or states clear value
- **Preview text** — complements the subject line, does not repeat it
- **Header/hero** — visual anchor and one-line value statement
- **Body sections** — 2-3 content blocks, each scannable with a bold intro sentence
- **Primary CTA** — one clear action per email
- **Footer** — unsubscribe link, company info, social links

### Landing Page Structure
- **Headline** — primary benefit in under 10 words
- **Subheadline** — elaborates on the headline with supporting context
- **Hero section** — headline, subheadline, primary CTA, supporting image or video
- **Value propositions** — 3-4 benefit-driven sections with icons or images
- **Social proof** — testimonials, logos, stats, case study snippets
- **Objection handling** — FAQ or trust signals
- **Final CTA** — repeat the primary call to action

### Press Release Structure
- **Headline** — factual, newsworthy, under 80 characters
- **Subheadline** — optional, adds context
- **Dateline** — city, state, date
- **Lead paragraph** — who, what, when, where, why in 2-3 sentences
- **Body paragraphs** — supporting details, quotes, context
- **Boilerplate** — company description (standardized)
- **Media contact** — name, email, phone

### Case Study Structure
- **Title** — "[Customer] achieves [result] with [product]"
- **Snapshot** — customer name, industry, company size, product used, key result (sidebar or callout box)
- **Challenge** — what problem the customer faced
- **Solution** — what was implemented and how
- **Results** — quantified outcomes with specific metrics
- **Quote** — customer testimonial
- **CTA** — learn more, get a demo, read more case studies

## Writing Best Practices by Channel

### Blog
- Write at an 8th-grade reading level for broad audiences; adjust up for technical audiences
- Use short paragraphs (2-4 sentences)
- Include subheadings every 200-300 words
- Use bullet points and numbered lists to break up text
- Include at least one data point, example, or quote per section
- Write in active voice
- Front-load key information in each section

### Social Media
- **LinkedIn**: professional but human, paragraph breaks for readability, personal stories and lessons perform well, 1,300 characters is the sweet spot before "see more"
- **Twitter/X**: concise and punchy, strong opening words, threads for longer narratives, engage with replies
- **Instagram**: visual-first captions, storytelling hooks, line breaks for readability, hashtags in first comment or at end
- **Facebook**: conversational tone, questions drive comments, shorter posts (under 80 characters) get more engagement for links

### Email
- Write subject lines that create urgency, curiosity, or state clear value
- Personalize where possible (name, company, behavior)
- One primary CTA per email — make it visually distinct
- Keep body copy scannable: bold key phrases, short paragraphs, bullet points
- Test everything: subject lines, send times, CTA copy, layout
- Mobile-first: most email is read on mobile

### Web (Landing Pages, Product Pages)
- Lead with benefits, not features
- Use "you" language — speak to the reader directly
- Minimize jargon unless the audience expects it
- Every section should answer "so what?" from the reader's perspective
- Reduce friction: fewer form fields, clear next steps, trust signals near CTAs

## SEO Fundamentals for Content

### Keyword Strategy
- Identify one primary keyword and 2-3 secondary keywords per piece
- Use the primary keyword in: headline, first paragraph, one subheading, meta description, URL slug
- Use secondary keywords naturally in body copy and subheadings
- Do not keyword-stuff — write for humans first

### On-Page SEO Checklist
- Title tag: under 60 characters, includes primary keyword
- Meta description: under 160 characters, includes primary keyword, compels click
- URL slug: short, descriptive, includes primary keyword
- H1: one per page, matches or closely reflects the title tag
- H2/H3: descriptive, include secondary keywords where natural
- Image alt text: descriptive, includes keyword where relevant
- Internal links: 2-3 links to related content on your site
- External links: 1-2 links to authoritative sources

### Content-SEO Integration
- Aim for comprehensive coverage of the topic (search engines reward depth)
- Answer related questions (check "People Also Ask" for ideas)
- Update and refresh high-performing content regularly
- Structure content for featured snippets: definition paragraphs, numbered lists, tables

## Headline and Hook Formulas

### Headline Formulas
- **How to [achieve result] [without common obstacle]** — "How to Double Your Email Open Rates Without Sending More Emails"
- **[Number] [adjective] ways to [achieve result]** — "7 Proven Ways to Reduce Customer Churn"
- **Why [common belief] is wrong (and what to do instead)** — "Why More Content Is Not the Answer (And What to Do Instead)"
- **The [adjective] guide to [topic]** — "The Complete Guide to B2B Content Marketing"
- **[Do this], not [that]** — "Build a Community, Not Just an Audience"
- **What [impressive result] taught us about [topic]** — "What 10,000 A/B Tests Taught Us About Email Subject Lines"
- **[topic]: what [audience] needs to know in [year]** — "SEO: What Marketers Need to Know in 2025"

### Hook Formulas (Opening Lines)
- **Surprising statistic**: "73% of marketers say their biggest challenge is not budget — it is focus."
- **Contrarian statement**: "The best marketing campaigns start with saying no to most channels."
- **Question**: "When was the last time a marketing email actually changed what you bought?"
- **Scenario**: "Imagine launching a campaign and knowing, before it goes live, which messages will land."
- **Bold claim**: "Most landing pages lose half their visitors in the first three seconds."
- **Story opening**: "Last quarter, our team was spending 20 hours a week on reporting. Here is what we did about it."

## Call-to-Action Best Practices

### CTA Principles
- Use action verbs: "Get", "Start", "Download", "Join", "Try", "See"
- Be specific about what happens next: "Start your free trial" is better than "Submit"
- Create urgency when genuine: "Join 500 teams already using this" or "Limited spots available"
- Reduce risk: "No credit card required", "Cancel anytime", "Free for 14 days"
- One primary CTA per page or email — too many choices reduce conversions

### CTA Examples by Context
- **Blog post**: "Read our complete guide to [topic]" / "Subscribe for weekly insights"
- **Landing page**: "Start free trial" / "Get a demo" / "See pricing"
- **Email**: "Read the full story" / "Claim your spot" / "Reply and tell us"
- **Social media**: "Drop a comment if you agree" / "Save this for later" / "Link in bio"
- **Case study**: "See how [product] can work for your team" / "Talk to our team"

### CTA Placement
- Above the fold on landing pages (do not make users scroll to act)
- After establishing value in emails (not in the first sentence)
- At the end of blog posts (after you have earned the reader's trust)
- In-line within content when contextually relevant (e.g., a related guide mention)
- Repeat the primary CTA at the bottom of long-form pages$body$)
ON CONFLICT (skill_key) DO NOTHING;
