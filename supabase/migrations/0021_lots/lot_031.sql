INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/bio-research/skills/start', 'business', 'start', '', 'start', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Bio-Research Start

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

You are helping a biological researcher get oriented with the bio-research plugin. Walk through the following steps in order.

## Step 1: Welcome

Display this welcome message:

```
Bio-Research Plugin

Your AI-powered research assistant for the life sciences. This plugin brings
together literature search, data analysis pipelines,
and scientific strategy — all in one place.
```

## Step 2: Check Available MCP Servers

Test which MCP servers are connected by listing available tools. Group the results:

**Literature & Data Sources:**
- ~~literature database — biomedical literature search
- ~~literature database — preprint access (biology and medicine)
- ~~journal access — academic publications
- ~~data repository — collaborative research data (Sage Bionetworks)

**Drug Discovery & Clinical:**
- ~~chemical database — bioactive compound database
- ~~drug target database — drug target discovery platform
- ClinicalTrials.gov — clinical trial registry
- ~~clinical data platform — clinical trial site ranking and platform help

**Visualization & AI:**
- ~~scientific illustration — create scientific figures and diagrams
- ~~AI research platform — AI for biology (histopathology, drug discovery)

Report which servers are connected and which are not yet set up.

## Step 3: Survey Available Skills

List the analysis skills available in this plugin:

| Skill | What It Does |
|-------|-------------|
| **Single-Cell RNA QC** | Quality control for scRNA-seq data with MAD-based filtering |
| **scvi-tools** | Deep learning for single-cell omics (scVI, scANVI, totalVI, PeakVI, etc.) |
| **Nextflow Pipelines** | Run nf-core pipelines (RNA-seq, WGS/WES, ATAC-seq) |
| **Instrument Data Converter** | Convert lab instrument output to Allotrope ASM format |
| **Scientific Problem Selection** | Systematic framework for choosing research problems |

## Step 4: Optional Setup — Binary MCP Servers

Mention that two additional MCP servers are available as separate installations:

- **~~genomics platform** — Access cloud analysis data and workflows
  Install: Download `txg-node.mcpb` from https://github.com/10XGenomics/txg-mcp/releases
- **~~tool database** (Harvard MIMS) — AI tools for scientific discovery
  Install: Download `tooluniverse.mcpb` from https://github.com/mims-harvard/ToolUniverse/releases

These require downloading binary files and are optional.

## Step 5: Ask How to Help

Ask the researcher what they're working on today. Suggest starting points based on common workflows:

1. **Literature review** — "Search ~~literature database for recent papers on [topic]"
2. **Analyze sequencing data** — "Run QC on my single-cell data" or "Set up an RNA-seq pipeline"
3. **Drug discovery** — "Search ~~chemical database for compounds targeting [protein]" or "Find drug targets for [disease]"
4. **Data standardization** — "Convert my instrument data to Allotrope format"
5. **Research strategy** — "Help me evaluate a new project idea"

Wait for the user's response and guide them to the appropriate tools and skills.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/cowork-plugin-management/skills/cowork-plugin-customizer', 'business', 'cowork-plugin-customizer', '', 'cowork-plugin-customizer', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Cowork Plugin Customization

Customize a plugin for a specific organization — either by setting up a generic plugin template for the first time, or by tweaking and refining an already-configured plugin.

> **Finding the plugin**: To find the plugin's source files, run `find mnt/.local-plugins mnt/.plugins -type d -name "*<plugin-name>*"` to locate the plugin directory, then read its files to understand its structure before making changes. If you cannot find the plugin directory, the user is likely running this conversation in a remote container. Abort and let them know: "Customizing plugins is currently only available in the desktop app's Cowork mode."

## Determining the Customization Mode

After locating the plugin, check for `~~`-prefixed placeholders: `grep -rn '~~\w' /path/to/plugin --include='*.md' --include='*.json'`

> **Default rule**: If `~~` placeholders exist, default to **Generic plugin setup** unless the user explicitly asks to customize a specific part of the plugin.

**1. Generic plugin setup** — The plugin contains `~~`-prefixed placeholders. These are customization points in a template that need to be replaced with real values (e.g., `~~Jira` → `Asana`, `~~your-team-channel` → `#engineering`).

**2. Scoped customization** — No `~~` placeholders exist, and the user asked to customize a specific part of the plugin (e.g., "customize the connectors", "update the standup skill", "change the ticket tool"). Read the plugin files to find the relevant section(s) and focus only on those. Do not scan the entire plugin or present unrelated customization items.

> **Legacy `commands/` directories**: Some plugins include a `commands/` directory. The Cowork UI now presents these alongside skills as a single "Skills" concept, so treat `commands/*.md` files the same way you would `skills/*/SKILL.md` files when customizing.

**3. General customization** — No `~~` placeholders exist, and the user wants to modify the plugin broadly. Read the plugin's files to understand its current configuration, then ask the user what they'd like to change.

> **Important**: Never change the name of the plugin or skill being customized. Do not rename directories, files, or the plugin/skill name fields.

> **Nontechnical output**: All user-facing output (todo list items, questions, summaries) must be written in plain, nontechnical language. Never mention `~~` prefixes, placeholders, or customization points to the user. Frame everything in terms of the plugin's capabilities and the organization's tools.

## Customization Workflow

### Phase 0: Gather User Intent (scoped and general customization only)

For **scoped customization** and **general customization** (not generic plugin setup), check whether the user provided free-form context alongside their request (e.g., "customize the standup skill — we do async standups in #eng-updates every morning").

- **If the user provided context**: Record it and use it to pre-fill answers in Phase 3 — skip asking questions that the user already answered here.
- **If the user did not provide context**: Ask a single open-ended question using AskUserQuestion before proceeding. Tailor the question to what they asked to customize — e.g., "What changes do you have in mind for the brief skill?" or "What would you like to change about how this plugin works?" Keep it short and specific to their request.

  Use their response (if any) as additional context throughout the remaining phases.

### Phase 1: Gather Context from Knowledge MCPs

Use company-internal knowledge MCPs to collect information relevant to the customization scope. See `references/search-strategies.md` for detailed query patterns by category.

**What to gather** (scope to what's relevant):

- Tool names and services the organization uses
- Organizational processes and workflows
- Team conventions (naming, statuses, estimation scales)
- Configuration values (workspace IDs, project names, team identifiers)

**Sources to search:**

1. **Chat/Slack MCPs** — tool mentions, integrations, workflow discussions
2. **Document MCPs** — onboarding docs, tool guides, setup instructions
3. **Email MCPs** — license notifications, admin emails, setup invitations

Record all findings for use in Phase 3.

### Phase 2: Create Todo List

Build a todo list of changes to make, scoped appropriately:

- **For scoped customization**: Only include items related to the specific section the user asked about.
- **For generic plugin setup**: Run `grep -rn '~~\w' /path/to/plugin --include='*.md' --include='*.json'` to find all placeholder customization points. Group them by theme.
- **For general customization**: Read the plugin files, understand the current config, and based on the user's request, identify what needs to change.

Use user-friendly descriptions that focus on the plugin's purpose:

- **Good**: "Learn how standup prep works at Company"
- **Bad**: "Replace placeholders in skills/standup-prep/SKILL.md"

### Phase 3: Complete Todo Items

Work through each item using context from Phase 0 and Phase 1.

**If the user's free-form input (Phase 0) or knowledge MCPs (Phase 1) provided a clear answer**: Apply directly without confirmation.

**Otherwise**: Use AskUserQuestion. Don't assume "industry standard" defaults are correct — if neither the user's input nor knowledge MCPs provided a specific answer, ask. Note: AskUserQuestion always includes a Skip button and a free-text input box for custom answers, so do not include `None` or `Other` as options.

**Types of changes:**

1. **Placeholder replacements** (generic setup): `~~Jira` → `Asana`, `~~your-org-channel` → `#engineering`
2. **Content updates**: Modifying instructions, skills, workflows, or references to match the organization
3. **URL pattern updates**: `tickets.example.com/your-team/123` → `app.asana.com/0/PROJECT_ID/TASK_ID`
4. **Configuration values**: Workspace IDs, project names, team identifiers

If user doesn't know or skips, leave the value unchanged (or the `~~`-prefixed placeholder, for generic setup).

### Phase 4: Search for Useful MCPs

After customization items have been resolved, connect MCPs for any tools that were identified or changed. See `references/mcp-servers.md` for the full workflow, category-to-keywords mapping, and config file format.

For each tool identified during customization:

1. Search the registry: `search_mcp_registry(keywords=[...])` using category keywords from `references/mcp-servers.md`, or search for the specific tool name if already known
2. If unconnected: `suggest_connectors(directoryUuids=["chosen-uuid"])` — user completes auth
3. Update the plugin's MCP config file (check `plugin.json` for custom location, otherwise `.mcp.json` at root)

Collect all MCP results and present them together in the summary output (see below) — don't present MCPs one at a time during this phase.

## Packaging the Plugin

After all customizations are applied, package the plugin as a `.plugin` file for the user:

1. **Zip the plugin directory** (excluding `setup/` since it's no longer needed):
   ```bash
   cd /path/to/plugin && zip -r /tmp/plugin-name.plugin . -x "setup/*" && cp /tmp/plugin-name.plugin /path/to/outputs/plugin-name.plugin
   ```
2. **Present the file to the user** with the `.plugin` extension so they can install it directly. (Presenting the .plugin file will show to the user as a rich preview where they can look through the plugin files, and they can accept the customization by pressing a button.)

> **Important**: Always create the zip in `/tmp/` first, then copy to the outputs folder. Writing directly to the outputs folder may fail due to permissions and leave behind temporary files.

> **Naming**: Use the original plugin directory name for the `.plugin` file (e.g., if the plugin directory is `coder`, the output file should be `coder.plugin`). Do not rename the plugin or its files during customization — only replace placeholder values and update content.

## Summary Output

After customization, present the user with a summary of what was learned grouped by source. Always include the MCPs sections showing which MCPs were connected during setup and which ones the user should still connect:

```markdown
## From searching Slack

- You use Asana for project management
- Sprint cycles are 2 weeks

## From searching documents

- Story points use T-shirt sizes

## From your answers

- Ticket statuses are: Backlog, In Progress, In Review, Done
```

Then present the MCPs that were connected during setup and any that the user should still connect, with instructions on how to connect them.

If no knowledge MCPs were available in Phase 1, and the user had to answer at least one question manually, include a note at the end:

> By the way, connecting sources like Slack or Microsoft Teams would let me find answers automatically next time you customize a plugin.

## Additional Resources

- **`references/mcp-servers.md`** — MCP discovery workflow, category-to-keywords mapping, config file locations
- **`references/search-strategies.md`** — Knowledge MCP query patterns for finding tool names and org values
- **`examples/customized-mcp.json`** — Example fully configured `.mcp.json`$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/cowork-plugin-management/skills/create-cowork-plugin', 'business', 'create-cowork-plugin', '', 'create-cowork-plugin', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Create Cowork Plugin

Build a new plugin from scratch through guided conversation. Walk the user through discovery, planning, design, implementation, and packaging — delivering a ready-to-install `.plugin` file at the end.

## Overview

A plugin is a self-contained directory that extends Claude's capabilities with skills, agents, hooks, and MCP server integrations. This skill encodes the full plugin architecture and a five-phase workflow for creating one conversationally.

The process:

1. **Discovery** — understand what the user wants to build
2. **Component Planning** — determine which component types are needed
3. **Design & Clarifying Questions** — specify each component in detail
4. **Implementation** — create all plugin files
5. **Review & Package** — deliver the `.plugin` file

> **Nontechnical output**: Keep all user-facing conversation in plain language. Do not expose implementation details like file paths, directory structures, or schema fields unless the user asks. Frame everything in terms of what the plugin will do.

## Plugin Architecture

### Directory Structure

Every plugin follows this layout:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json           # Required: plugin manifest
├── skills/                   # Skills (subdirectories with SKILL.md)
│   └── skill-name/
│       ├── SKILL.md
│       └── references/
├── agents/                   # Subagent definitions (.md files)
├── .mcp.json                 # MCP server definitions
└── README.md                 # Plugin documentation
```

> **Legacy `commands/` format**: Older plugins may include a `commands/` directory with single-file `.md` slash commands. This format still works, but new plugins should use `skills/*/SKILL.md` instead — the Cowork UI presents both as a single "Skills" concept, and the skills format supports progressive disclosure via `references/`.

**Rules:**

- `.claude-plugin/plugin.json` is always required
- Component directories (`skills/`, `agents/`) go at the plugin root, not inside `.claude-plugin/`
- Only create directories for components the plugin actually uses
- Use kebab-case for all directory and file names

### plugin.json Manifest

Located at `.claude-plugin/plugin.json`. Minimal required field is `name`.

```json
{
  "name": "plugin-name",
  "version": "0.1.0",
  "description": "Brief explanation of plugin purpose",
  "author": {
    "name": "Author Name"
  }
}
```

**Name rules:** kebab-case, lowercase with hyphens, no spaces or special characters.
**Version:** semver format (MAJOR.MINOR.PATCH). Start at `0.1.0`.

Optional fields: `homepage`, `repository`, `license`, `keywords`.

Custom component paths can be specified (supplements, does not replace, auto-discovery):

```json
{
  "commands": "./custom-commands",
  "agents": ["./agents", "./specialized-agents"],
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

### Component Schemas

Detailed schemas for each component type are in `references/component-schemas.md`. Summary:

| Component                          | Location            | Format                      |
| ---------------------------------- | ------------------- | --------------------------- |
| Skills                             | `skills/*/SKILL.md` | Markdown + YAML frontmatter |
| MCP Servers                        | `.mcp.json`         | JSON                        |
| Agents (uncommonly used in Cowork) | `agents/*.md`       | Markdown + YAML frontmatter |
| Hooks (rarely used in Cowork)      | `hooks/hooks.json`  | JSON                        |
| Commands (legacy)                  | `commands/*.md`     | Markdown + YAML frontmatter |

This schema is shared with Claude Code's plugin system, but you're creating a plugin for Claude Cowork, a desktop app for doing knowledge work.
Cowork users will usually find skills the most useful. **Scaffold new plugins with `skills/*/SKILL.md` — do not create `commands/` unless the user explicitly needs the legacy single-file format.**

### Customizable plugins with `~~` placeholders

> **Do not use or ask about this pattern by default.** Only introduce `~~` placeholders if the user explicitly says they want people outside their organization to use the plugin.
> You can mention this is an option if it seems like the user wants to distribute the plugin externally, but do not proactively ask about this with AskUserQuestion.

When a plugin is intended to be shared with others outside their company, it might have parts that need to be adapted to individual users.
You might need to reference external tools by category rather than specific product (e.g., "project tracker" instead of "Jira").
When sharing is needed, use generic language and mark these as requiring customization with two tilde characters such as `create an issue in ~~project tracker`.
If used any tool categories, write a `CONNECTORS.md` file at the plugin root to explain:

```markdown
# Connectors

## How tool references work

Plugin files use `~~category` as a placeholder for whatever tool the user
connects in that category. Plugins are tool-agnostic — they describe
workflows in terms of categories rather than specific products.

## Connectors for this plugin

| Category        | Placeholder         | Options                         |
| --------------- | ------------------- | ------------------------------- |
| Chat            | `~~chat`            | Slack, Microsoft Teams, Discord |
| Project tracker | `~~project tracker` | Linear, Asana, Jira             |
```

### ${CLAUDE_PLUGIN_ROOT} Variable

Use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin path references in hooks and MCP configs. Never hardcode absolute paths.

## Guided Workflow

When you ask the user something, use AskUserQuestion. Don't assume "industry standard" defaults are correct. Note: AskUserQuestion always includes a Skip button and a free-text input box for custom answers, so do not include `None` or `Other` as options.

### Phase 1: Discovery

**Goal**: Understand what the user wants to build and why.

Ask (only what is unclear — skip questions if the user's initial request already answers them):

- What should this plugin do? What problem does it solve?
- Who will use it and in what context?
- Does it integrate with any external tools or services?
- Is there a similar plugin or workflow to reference?

Summarize understanding and confirm before proceeding.

**Output**: Clear statement of plugin purpose and scope.

### Phase 2: Component Planning

**Goal**: Determine which component types the plugin needs.

Based on the discovery answers, determine:

- **Skills** — Does it need specialized knowledge that Claude should load on-demand, or user-initiated actions? (domain expertise, reference schemas, workflow guides, deploy/configure/analyze/review actions)
- **MCP Servers** — Does it need external service integration? (databases, APIs, SaaS tools)
- **Agents (uncommon)** — Are there autonomous multi-step tasks? (validation, generation, analysis)
- **Hooks (rare)** — Should something happen automatically on certain events? (enforce policies, load context, validate operations)

Present a component plan table, including component types you decided not to create:

```
| Component | Count | Purpose |
|-----------|-------|---------|
| Skills    | 3     | Domain knowledge for X, /do-thing, /check-thing |
| Agents    | 0     | Not needed |
| Hooks     | 1     | Validate writes |
| MCP       | 1     | Connect to service Y |
```

Get user confirmation or adjustments before proceeding.

**Output**: Confirmed list of components to create.

### Phase 3: Design & Clarifying Questions

**Goal**: Specify each component in detail. Resolve all ambiguities before implementation.

For each component type in the plan, ask targeted design questions. Present questions grouped by component type. Wait for answers before proceeding.

**Skills:**

- What user queries should trigger this skill?
- What knowledge domains does it cover?
- Should it include reference files for detailed content?
- If the skill represents a user-initiated action: what arguments does it accept, and what tools does it need? (Read, Write, Bash, Grep, etc.)

**Agents:**

- Should each agent trigger proactively or only when requested?
- What tools does it need?
- What should the output format be?

**Hooks:**

- Which events? (PreToolUse, PostToolUse, Stop, SessionStart, etc.)
- What behavior — validate, block, modify, add context?
- Prompt-based (LLM-driven) or command-based (deterministic script)?

**MCP Servers:**

- What server type? (stdio for local, SSE for hosted with OAuth, HTTP for REST APIs)
- What authentication method?
- What tools should be exposed?

If the user says "whatever you think is best," provide specific recommendations and get explicit confirmation.

**Output**: Detailed specification for every component.

### Phase 4: Implementation

**Goal**: Create all plugin files following best practices.

**Order of operations:**

1. Create the plugin directory structure
2. Create `plugin.json` manifest
3. Create each component (see `references/component-schemas.md` for exact formats)
4. Create `README.md` documenting the plugin

**Implementation guidelines:**

- **Skills** use progressive disclosure: lean SKILL.md body (under 3,000 words), detailed content in `references/`. Frontmatter description must be third-person with specific trigger phrases. Skill bodies are instructions FOR Claude, not messages to the user — write them as directives about what to do.
- **Agents** need a description with `<example>` blocks showing triggering conditions, plus a system prompt in the markdown body.
- **Hooks** config goes in `hooks/hooks.json`. Use `${CLAUDE_PLUGIN_ROOT}` for script paths. Prefer prompt-based hooks for complex logic.
- **MCP configs** go in `.mcp.json` at plugin root. Use `${CLAUDE_PLUGIN_ROOT}` for local server paths. Document required env vars in README.

### Phase 5: Review & Package

**Goal**: Deliver the finished plugin.

1. Summarize what was created — list each component and its purpose
2. Ask if the user wants any adjustments
3. Run `claude plugin validate <path-to-plugin-json>` to check the plugin structure. If this command is unavailable (e.g., when running inside Cowork), verify the structure manually:
   - `.claude-plugin/plugin.json` exists and contains valid JSON with at least a `name` field
   - The `name` field is kebab-case (lowercase letters, numbers, and hyphens only)
   - Any component directories referenced by the plugin (`commands/`, `skills/`, `agents/`, `hooks/`) actually exist and contain files in the expected formats — `.md` for commands/skills/agents, `.json` for hooks
   - Each skill subdirectory contains a `SKILL.md`
   - Report what passed and what didn't, the same way the CLI validator would

   Fix any errors before proceeding.
4. Package as a `.plugin` file:

```bash
cd /path/to/plugin-dir && zip -r /tmp/plugin-name.plugin . -x "*.DS_Store" && cp /tmp/plugin-name.plugin /path/to/outputs/plugin-name.plugin
```

> **Important**: Always create the zip in `/tmp/` first, then copy to the outputs folder. Writing directly to the outputs folder may fail due to permissions.

> **Naming**: Use the plugin name from `plugin.json` for the `.plugin` file (e.g., if name is `code-reviewer`, output `code-reviewer.plugin`).

The `.plugin` file will appear in the chat as a rich preview where the user can browse the files and accept the plugin by pressing a button.

## Best Practices

- **Start small**: Begin with the minimum viable set of components. A plugin with one well-crafted skill is more useful than one with five half-baked components.
- **Progressive disclosure for skills**: Core knowledge in SKILL.md, detailed reference material in `references/`, working examples in `examples/`.
- **Clear trigger phrases**: Skill descriptions should include specific phrases users would say. Agent descriptions should include `<example>` blocks.
- **Skills are for Claude**: Write skill body content as instructions for Claude to follow, not documentation for the user to read.
- **Imperative writing style**: Use verb-first instructions in skills ("Parse the config file," not "You should parse the config file").
- **Portability**: Always use `${CLAUDE_PLUGIN_ROOT}` for intra-plugin paths, never hardcoded paths.
- **Security**: Use environment variables for credentials, HTTPS for remote servers, least-privilege tool access.

## Additional Resources

- **`references/component-schemas.md`** — Detailed format specifications for every component type (skills, agents, hooks, MCP, legacy commands, CONNECTORS.md)
- **`references/example-plugins.md`** — Three complete example plugin structures at different complexity levels$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/customer-support/skills/customer-escalation', 'business', 'customer-escalation', '', 'customer-escalation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /customer-escalation

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Package a support issue into a structured escalation brief for engineering, product, or leadership. Gathers context, structures reproduction steps, assesses business impact, and identifies the right escalation target.

## Usage

```
/customer-escalation <issue description> [customer name or account]
```

Examples:
- `/customer-escalation API returning 500 errors intermittently for Acme Corp`
- `/customer-escalation Data export is missing rows — 3 customers reported this week`
- `/customer-escalation SSO login loop affecting all Enterprise customers`
- `/customer-escalation Customer threatening to churn over missing audit log feature`

## Workflow

### 1. Understand the Issue

Parse the input and determine:

- **What's broken or needed**: The core technical or product issue
- **Who's affected**: Specific customer(s), segment, or all users
- **How long**: When did this start? How long has the customer been waiting?
- **What's been tried**: Any troubleshooting or workarounds attempted
- **Why escalate now**: What makes this need attention beyond normal support

Use the "When to Escalate vs. Handle in Support" criteria below to confirm this warrants escalation.

### 2. Gather Context

Pull together relevant information from available sources:

- **~~support platform**: Related tickets, timeline of communications, previous troubleshooting
- **~~CRM** (if connected): Account details, key contacts, previous escalations
- **~~chat**: Internal discussions about this issue, similar reports from other customers
- **~~project tracker** (if connected): Related bug reports or feature requests, engineering status
- **~~knowledge base**: Known issues or workarounds, relevant documentation

### 3. Assess Business Impact

Using the impact dimensions below, quantify:

- **Breadth**: How many customers/users affected? Growing?
- **Depth**: Blocked vs. inconvenienced?
- **Duration**: How long has this been going on?
- **Revenue**: ARR at risk? Pending deals affected?
- **Time pressure**: Hard deadline?

### 4. Determine Escalation Target

Using the escalation tiers below, identify the right target: L2 Support, Engineering, Product, Security, or Leadership.

### 5. Structure Reproduction Steps (for bugs)

If the issue is a bug, follow the reproduction step best practices below to document clear repro steps with environment details and evidence.

### 6. Generate Escalation Brief

```
## ESCALATION: [One-line summary]

**Severity:** [Critical / High / Medium]
**Target team:** [Engineering / Product / Security / Leadership]
**Reported by:** [Your name/team]
**Date:** [Today's date]

### Impact
- **Customers affected:** [Who and how many]
- **Workflow impact:** [What they can't do]
- **Revenue at risk:** [If applicable]
- **Time in queue:** [How long this has been an issue]

### Issue Description
[Clear, concise description of the problem — 3-5 sentences]

### What's Been Tried
1. [Troubleshooting step and result]
2. [Troubleshooting step and result]
3. [Troubleshooting step and result]

### Reproduction Steps
[If applicable — follow the format below]
1. [Step]
2. [Step]
3. [Step]
Expected: [X]
Actual: [Y]
Environment: [Details]

### Customer Communication
- **Last update to customer:** [Date and what was communicated]
- **Customer expectation:** [What they're expecting and by when]
- **Escalation risk:** [Will they escalate further if not resolved by X?]

### What's Needed
- [Specific ask — "investigate root cause", "prioritize fix",
  "make product decision on X", "approve exception for Y"]
- **Deadline:** [When this needs resolution or an update]

### Supporting Context
- [Related tickets or links]
- [Internal discussion threads]
- [Documentation or logs]
```

### 7. Offer Next Steps

After generating the escalation:
- "Want me to post this in a ~~chat channel for the target team?"
- "Should I update the customer with an interim response?"
- "Want me to set a follow-up reminder to check on this?"
- "Should I draft a customer-facing update with the current status?"

---

## When to Escalate vs. Handle in Support

### Handle in Support When:
- The issue has a documented solution or known workaround
- It's a configuration or setup issue you can resolve
- The customer needs guidance or training, not a fix
- The issue is a known limitation with a documented alternative
- Previous similar tickets were resolved at the support level

### Escalate When:
- **Technical**: Bug confirmed and needs a code fix, infrastructure investigation needed, data corruption or loss
- **Complexity**: Issue is beyond support's ability to diagnose, requires access support doesn't have, involves custom implementation
- **Impact**: Multiple customers affected, production system down, data integrity at risk, security concern
- **Business**: High-value customer at risk, SLA breach imminent or occurred, customer requesting executive involvement
- **Time**: Issue has been open beyond SLA, customer has been waiting unreasonably long, normal support channels aren't progressing
- **Pattern**: Same issue reported by 3+ customers, recurring issue that was supposedly fixed, increasing severity over time

## Escalation Tiers

### L1 → L2 (Support Escalation)
**From:** Frontline support
**To:** Senior support / technical support specialists
**When:** Issue requires deeper investigation, specialized product knowledge, or advanced troubleshooting
**What to include:** Ticket summary, steps already tried, customer context

### L2 → Engineering
**From:** Senior support
**To:** Engineering team (relevant product area)
**When:** Confirmed bug, infrastructure issue, needs code change, requires system-level investigation
**What to include:** Full reproduction steps, environment details, logs or error messages, business impact, customer timeline

### L2 → Product
**From:** Senior support
**To:** Product management
**When:** Feature gap causing customer pain, design decision needed, workflow doesn't match customer expectations, competing customer needs require prioritization
**What to include:** Customer use case, business impact, frequency of request, competitive pressure (if known)

### Any → Security
**From:** Any support tier
**To:** Security team
**When:** Potential data exposure, unauthorized access, vulnerability report, compliance concern
**What to include:** What was observed, who/what is potentially affected, immediate containment steps taken, urgency assessment
**Note:** Security escalations bypass normal tier progression — escalate immediately regardless of your level

### Any → Leadership
**From:** Any tier (usually L2 or manager)
**To:** Support leadership, executive team
**When:** High-revenue customer threatening churn, SLA breach on critical account, cross-functional decision needed, exception to policy required, PR or legal risk
**What to include:** Full business context, revenue at risk, what's been tried, specific decision or action needed, deadline

## Business Impact Assessment

When escalating, quantify impact where possible:

### Impact Dimensions

| Dimension | Questions to Answer |
|-----------|-------------------|
| **Breadth** | How many customers/users are affected? Is it growing? |
| **Depth** | How severely are they impacted? Blocked vs. inconvenienced? |
| **Duration** | How long has this been going on? How long until it's critical? |
| **Revenue** | What's the ARR at risk? Are there pending deals affected? |
| **Reputation** | Could this become public? Is it a reference customer? |
| **Contractual** | Are SLAs being breached? Are there contractual obligations? |

### Severity Shorthand

- **Critical**: Production down, data at risk, security breach, or multiple high-value customers affected. Needs immediate attention.
- **High**: Major functionality broken, key customer blocked, SLA at risk. Needs same-day attention.
- **Medium**: Significant issue with workaround, important but not urgent business impact. Needs attention this week.

## Writing Reproduction Steps

Good reproduction steps are the single most valuable thing in a bug escalation. Follow these practices:

1. **Start from a clean state**: Describe the starting point (account type, configuration, permissions)
2. **Be specific**: "Click the Export button in the top-right of the Dashboard page" not "try to export"
3. **Include exact values**: Use specific inputs, dates, IDs — not "enter some data"
4. **Note the environment**: Browser, OS, account type, feature flags, plan level
5. **Capture the frequency**: Always reproducible? Intermittent? Only under certain conditions?
6. **Include evidence**: Screenshots, error messages (exact text), network logs, console output
7. **Note what you've ruled out**: "Tested in Chrome and Firefox — same behavior" "Not account-specific — reproduced on test account"

## Follow-up Cadence After Escalation

Don't escalate and forget. Maintain ownership of the customer relationship.

| Severity | Internal Follow-up | Customer Update |
|----------|-------------------|-----------------|
| **Critical** | Every 2 hours | Every 2-4 hours (or per SLA) |
| **High** | Every 4 hours | Every 4-8 hours |
| **Medium** | Daily | Every 1-2 business days |

### Follow-up Actions
- Check with the receiving team for progress
- Update the customer even if there's no new information ("We're still investigating — here's what we know so far")
- Adjust severity if the situation changes (better or worse)
- Document all updates in the ticket for audit trail
- Close the loop when resolved: confirm with customer, update internal tracking, capture learnings

## De-escalation

Not every escalation stays escalated. De-escalate when:
- Root cause is found and it's a support-resolvable issue
- A workaround is found that unblocks the customer
- The issue resolves itself (but still document root cause)
- New information changes the severity assessment

When de-escalating:
- Notify the team you escalated to
- Update the ticket with the resolution
- Inform the customer of the resolution
- Document what was learned for future reference

## Escalation Best Practices

1. Always quantify impact — vague escalations get deprioritized
2. Include reproduction steps for bugs — this is the #1 thing engineering needs
3. Be clear about what you need — "investigate" vs. "fix" vs. "decide" are different asks
4. Set and communicate a deadline — urgency without a deadline is ambiguous
5. Maintain ownership of the customer relationship even after escalating the technical issue
6. Follow up proactively — don't wait for the receiving team to come to you
7. Document everything — the escalation trail is valuable for pattern detection and process improvement$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/customer-support/skills/customer-research', 'business', 'customer-research', '', 'customer-research', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /customer-research

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Multi-source research on a customer question, product topic, or account-related inquiry. Synthesizes findings from all available sources with clear attribution and confidence scoring.

## Usage

```
/customer-research <question or topic>
```

## Workflow

### 1. Parse the Research Request

Identify what type of research is needed:
- **Customer question**: Something a customer has asked that needs an answer (e.g., "Does our product support SSO with Okta?")
- **Issue investigation**: Background on a reported problem (e.g., "Has this bug been reported before? What's the known workaround?")
- **Account context**: History with a specific customer (e.g., "What did we tell Acme Corp last time they asked about this?")
- **Topic research**: General topic relevant to support work (e.g., "Best practices for webhook retry logic")

Before searching, clarify what you're actually trying to find:
- Is this a factual question with a definitive answer?
- Is this a contextual question requiring multiple perspectives?
- Is this an exploratory question where the scope is still being defined?
- Who is the audience for the answer (internal team, customer, leadership)?

### 2. Search Available Sources

Search systematically through the source tiers below, adapting to what is connected. Don't stop at the first result — cross-reference across sources.

**Tier 1 — Official Internal Sources (highest confidence):**
- ~~knowledge base (if connected): product docs, runbooks, FAQs, policy documents
- ~~cloud storage: internal documents, specs, guides, past research
- Product roadmap (internal-facing): feature timelines, priorities

**Tier 2 — Organizational Context:**
- ~~CRM notes: account notes, activity history, previous answers, opportunity details
- ~~support platform (if connected): previous resolutions, known issues, workarounds
- Meeting notes: previous discussions, decisions, commitments

**Tier 3 — Team Communications:**
- ~~chat: search for the topic in relevant channels; check if teammates have discussed or answered this before
- ~~email: search for previous correspondence on this topic
- Calendar notes: meeting agendas and post-meeting notes

**Tier 4 — External Sources:**
- Web search: official documentation, blog posts, community forums
- Public knowledge bases, help centers, release notes
- Third-party documentation: integration partners, complementary tools

**Tier 5 — Inferred or Analogical (use when direct sources don't yield answers):**
- Similar situations: how similar questions were handled before
- Analogous customers: what worked for comparable accounts
- General best practices: industry standards and norms

### 3. Synthesize Findings

Compile results into a structured research brief:

```
## Research: [Question/Topic]

### Answer
[Clear, direct answer to the question — lead with the bottom line]

**Confidence:** [High / Medium / Low]
[Explain what drives the confidence level]

### Key Findings

**From [Source 1]:**
- [Finding with specific detail]
- [Finding with specific detail]

**From [Source 2]:**
- [Finding with specific detail]

### Context & Nuance
[Any caveats, edge cases, or additional context that matters]

### Sources
1. [Source name/link] — [what it contributed]
2. [Source name/link] — [what it contributed]
3. [Source name/link] — [what it contributed]

### Gaps & Unknowns
- [What couldn't be confirmed]
- [What might need verification from a subject matter expert]

### Recommended Next Steps
- [Action if the answer needs to go to a customer]
- [Action if further research is needed]
- [Who to consult for verification if needed]
```

### 4. Handle Insufficient Sources

If no connected sources yield results:

- Perform web research on the topic
- Ask the user for internal context:
  - "I couldn't find this in connected sources. Do you have internal docs or knowledge base articles about this?"
  - "Has your team discussed this topic before? Any ~~chat channels I should check?"
  - "Is there a subject matter expert who would know the answer?"
- Be transparent about limitations:
  - "This answer is based on web research only — please verify against your internal documentation before sharing with the customer."
  - "I found a possible answer but couldn't confirm it from an authoritative internal source."

### 5. Customer-Facing Considerations

If the research is to answer a customer question:

- Flag if the answer involves product roadmap, pricing, legal, or security topics that may need review
- Note if the answer differs from what may have been communicated previously
- Suggest appropriate caveats for the customer-facing response
- Offer to draft the customer response: "Want me to draft a response to the customer based on these findings?"

### 6. Knowledge Capture

After research is complete, suggest capturing the knowledge:

- "Should I save these findings to your knowledge base for future reference?"
- "Want me to create a FAQ entry based on this research?"
- "This might be worth documenting — should I draft a runbook entry?"

This helps build institutional knowledge and reduces duplicate research effort across the team.

---

## Source Prioritization and Confidence

### Confidence by Source Tier

| Tier | Source Type | Confidence | Notes |
|------|-------------|------------|-------|
| 1 | Official internal docs, KB, policies | **High** | Trust unless clearly outdated — check dates |
| 2 | CRM, support tickets, meeting notes | **Medium-High** | May be subjective or incomplete |
| 3 | Chat, email, calendar notes | **Medium** | Informal, may be out of context or speculative |
| 4 | Web, forums, third-party docs | **Low-Medium** | May not reflect your specific situation |
| 5 | Inference, analogies, best practices | **Low** | Clearly flag as inference, not fact |

### Confidence Levels

Always assign and communicate a confidence level:

**High Confidence:**
- Answer confirmed by official documentation or authoritative source
- Multiple sources corroborate the same answer
- Information is current (verified within a reasonable timeframe)
- "I'm confident this is accurate based on [source]."

**Medium Confidence:**
- Answer found in informal sources (chat, email) but not official docs
- Single source without corroboration
- Information may be slightly outdated but likely still valid
- "Based on [source], this appears to be the case, but I'd recommend confirming with [team/person]."

**Low Confidence:**
- Answer is inferred from related information
- Sources are outdated or potentially unreliable
- Contradictory information found across sources
- "I wasn't able to find a definitive answer. Based on [context], my best assessment is [answer], but this should be verified before sharing with the customer."

**Unable to Determine:**
- No relevant information found in any source
- Question requires specialized knowledge not available in sources
- "I couldn't find information about this. I recommend reaching out to [suggested expert/team] for a definitive answer."

### Handling Contradictions

When sources disagree:
1. Note the contradiction explicitly
2. Identify which source is more authoritative or more recent
3. Present both perspectives with context
4. Recommend how to resolve the discrepancy
5. If going to a customer: use the most conservative/cautious answer until resolved

## When to Escalate vs. Answer Directly

### Answer Directly When:
- Official documentation clearly addresses the question
- Multiple reliable sources corroborate the answer
- The question is factual and non-sensitive
- The answer doesn't involve commitments, timelines, or pricing
- You've answered similar questions before with confirmed accuracy

### Escalate or Verify When:
- The answer involves product roadmap commitments or timelines
- Pricing, legal terms, or contract-specific questions
- Security, compliance, or data handling questions
- The answer could set a precedent or create expectations
- You found contradictory information in sources
- The question involves a specific customer's custom configuration
- The answer requires specialized expertise you don't have
- The customer is at risk and the wrong answer could exacerbate the situation

### Escalation Path:
1. **Subject matter expert**: For technical or domain-specific questions
2. **Product team**: For roadmap, feature, or capability questions
3. **Legal/compliance**: For terms, privacy, security, or regulatory questions
4. **Billing/finance**: For pricing, invoice, or payment-related questions
5. **Engineering**: For custom configurations, bugs, or technical root causes
6. **Leadership**: For strategic decisions, exceptions, or high-stakes situations

## Research Documentation for Team Knowledge Base

After completing research, capture the knowledge for future use.

### When to Document:
- Question has come up before or likely will again
- Research took significant effort to compile
- Answer required synthesizing multiple sources
- Answer corrects a common misunderstanding
- Answer involves nuance that's easy to get wrong

### Documentation Format:
```
## [Question/Topic]

**Last Verified:** [date]
**Confidence:** [level]

### Answer
[Clear, direct answer]

### Details
[Supporting detail, context, and nuance]

### Sources
[Where this information came from]

### Related Questions
[Other questions this might help answer]

### Review Notes
[When to re-verify, what might change this answer]
```

### Knowledge Base Hygiene:
- Date-stamp all entries
- Flag entries that reference specific product versions or features
- Review and update entries quarterly
- Archive entries that are no longer relevant
- Tag entries for searchability (by topic, product area, customer segment)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/customer-support/skills/draft-response', 'business', 'draft-response', '', 'draft-response', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /draft-response

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Draft a professional, customer-facing response tailored to the situation, customer relationship, and communication context.

## Usage

```
/draft-response <context about the customer question, issue, or request>
```

Examples:
- `/draft-response Acme Corp is asking when the new dashboard feature will ship`
- `/draft-response Customer escalation — their integration has been down for 2 days`
- `/draft-response Responding to a feature request we won't be building`
- `/draft-response Customer hit a billing error and wants a resolution ASAP`

## Workflow

### 1. Understand the Context

Parse the user's input to determine:

- **Customer**: Who is the communication for? Look up account context if available.
- **Situation type**: Question, issue, escalation, announcement, negotiation, bad news, good news, follow-up
- **Urgency**: Is this time-sensitive? How long has the customer been waiting?
- **Channel**: Email, support ticket, chat, or other (adjust formality accordingly)
- **Relationship stage**: New customer, established, frustrated/escalated
- **Stakeholder level**: End user, manager, executive, technical, business

### 2. Research Context

Gather relevant background from available sources:

**~~email:**
- Previous correspondence with this customer on this topic
- Any commitments or timelines previously shared
- Tone and style of the existing thread

**~~chat:**
- Internal discussions about this customer or topic
- Any guidance from product, engineering, or leadership
- Similar situations and how they were handled

**~~CRM (if connected):**
- Account details and plan level
- Contact information and key stakeholders
- Previous escalations or sensitive issues

**~~support platform (if connected):**
- Related tickets and their resolution
- Known issues or workarounds
- SLA status and response time commitments

**~~knowledge base:**
- Official documentation or help articles to reference
- Product roadmap information (if shareable)
- Policy or process documentation

### 3. Generate the Draft

Produce a response tailored to the situation:

```
## Draft Response

**To:** [Customer contact name]
**Re:** [Subject/topic]
**Channel:** [Email / Ticket / Chat]
**Tone:** [Empathetic / Professional / Technical / Celebratory / Candid]

---

[Draft response text]

---

### Notes for You (internal — do not send)
- **Why this approach:** [Rationale for tone and content choices]
- **Things to verify:** [Any facts or commitments to confirm before sending]
- **Risk factors:** [Anything sensitive about this response]
- **Follow-up needed:** [Actions to take after sending]
- **Escalation note:** [If this should be reviewed by someone else first]
```

### 4. Run Quality Checks

Before presenting the draft, verify:

- [ ] Tone matches the situation and relationship
- [ ] No commitments beyond what's authorized
- [ ] No product roadmap details that shouldn't be shared externally
- [ ] Accurate references to previous conversations
- [ ] Clear next steps and ownership
- [ ] Appropriate for the stakeholder level (not too technical for executives, not too vague for engineers)
- [ ] Length is appropriate for the channel (shorter for chat, fuller for email)

### 5. Offer Iterations

After presenting the draft:
- "Want me to adjust the tone? (more formal, more casual, more empathetic, more direct)"
- "Should I add or remove any specific points?"
- "Want me to make this shorter/longer?"
- "Should I draft a version for a different stakeholder?"
- "Want me to draft the internal escalation note as well?"
- "Should I prepare a follow-up message to send after [X days] if no response?"

---

## Customer Communication Best Practices

### Core Principles

1. **Lead with empathy**: Acknowledge the customer's situation before jumping to solutions
2. **Be direct**: Get to the point — customers are busy. Bottom-line-up-front.
3. **Be honest**: Never overpromise, never mislead, never hide bad news in jargon
4. **Be specific**: Use concrete details, timelines, and names — avoid vague language
5. **Own it**: Take responsibility when appropriate. "We" not "the system" or "the process"
6. **Close the loop**: Every response should have a clear next step or call to action
7. **Match their energy**: If they're frustrated, be empathetic first. If they're excited, be enthusiastic.

### Response Structure

For most customer communications, follow this structure:

```
1. Acknowledgment / Context (1-2 sentences)
   - Acknowledge what they said, asked, or are experiencing
   - Show you understand their situation

2. Core Message (1-3 paragraphs)
   - Deliver the main information, answer, or update
   - Be specific and concrete
   - Include relevant details they need

3. Next Steps (1-3 bullets)
   - What YOU will do and by when
   - What THEY need to do (if anything)
   - When they'll hear from you next

4. Closing (1 sentence)
   - Warm but professional sign-off
   - Reinforce you're available if needed
```

### Length Guidelines

- **Chat/IM**: 1-4 sentences. Get to the point immediately.
- **Support ticket response**: 1-3 short paragraphs. Structured and scannable.
- **Email**: 3-5 paragraphs max. Respect their inbox.
- **Escalation response**: As long as needed to be thorough, but well-structured with headers.
- **Executive communication**: Shorter is better. 2-3 paragraphs max. Data-driven.

## Tone and Style Guidelines

### Tone Spectrum

| Situation | Tone | Characteristics |
|-----------|------|----------------|
| Good news / wins | Celebratory | Enthusiastic, warm, congratulatory, forward-looking |
| Routine update | Professional | Clear, concise, informative, friendly |
| Technical response | Precise | Accurate, detailed, structured, patient |
| Delayed delivery | Accountable | Honest, apologetic, action-oriented, specific |
| Bad news | Candid | Direct, empathetic, solution-oriented, respectful |
| Issue / outage | Urgent | Immediate, transparent, actionable, reassuring |
| Escalation | Executive | Composed, ownership-taking, plan-presenting, confident |
| Billing / account | Precise | Clear, factual, empathetic, resolution-focused |

### Tone Adjustments by Relationship Stage

**New Customer (0-3 months):**
- More formal and professional
- Extra context and explanation (don't assume knowledge)
- Proactively offer help and resources
- Build trust through reliability and responsiveness

**Established Customer (3+ months):**
- Warm and collaborative
- Can reference shared history and previous conversations
- More direct and efficient communication
- Show awareness of their goals and priorities

**Frustrated or Escalated Customer:**
- Extra empathy and acknowledgment
- Urgency in response times
- Concrete action plans with specific commitments
- Shorter feedback loops

### Writing Style Rules

**DO:**
- Use active voice ("We'll investigate" not "This will be investigated")
- Use "I" for personal commitments and "we" for team commitments
- Name specific people when assigning actions ("Sarah from our engineering team will...")
- Use the customer's terminology, not your internal jargon
- Include specific dates and times, not relative terms ("by Friday January 24" not "in a few days")
- Break up long responses with headers or bullet points

**DON'T:**
- Use corporate jargon or buzzwords ("synergy", "leverage", "paradigm shift")
- Deflect blame to other teams, systems, or processes
- Use passive voice to avoid ownership ("Mistakes were made")
- Include unnecessary caveats or hedging that undermines confidence
- CC people unnecessarily — only include those who need to be in the conversation
- Use exclamation marks excessively (one per email max, if any)

## Situation-Specific Approaches

**Answering a product question:**
- Lead with the direct answer
- Provide relevant documentation links
- Offer to connect them with the right resource if needed
- If you don't know the answer: say so honestly, commit to finding out, give a timeline

**Responding to an issue or bug:**
- Acknowledge the impact on their work
- State what you know about the issue and its status
- Provide workaround if available
- Set expectations for resolution timeline
- Commit to updates at regular intervals

**Handling an escalation:**
- Acknowledge the severity and their frustration
- Take ownership (no deflecting or excuse-making)
- Provide a clear action plan with timeline
- Identify the person accountable for resolution
- Offer a meeting or call if appropriate for the severity

**Delivering bad news (feature sunset, delay, can't-fix):**
- Be direct — don't bury the news
- Explain the reasoning honestly
- Acknowledge the impact on them specifically
- Offer alternatives or mitigation
- Provide a clear path forward

**Sharing good news (feature launch, milestone, recognition):**
- Lead with the positive outcome
- Connect it to their specific goals or use case
- Suggest next steps to capitalize on the good news
- Express genuine enthusiasm

**Declining a request (feature request, discount, exception):**
- Acknowledge the request and its reasoning
- Be honest about the decision
- Explain the why without being dismissive
- Offer alternatives when possible
- Leave the door open for future conversation

## Response Templates for Common Scenarios

### Acknowledging a Bug Report

```
Hi [Name],

Thank you for reporting this — I can see how [specific impact] would be
frustrating for your team.

I've confirmed the issue and escalated it to our engineering team as a
[priority level]. Here's what we know so far:
- [What's happening]
- [What's causing it, if known]
- [Workaround, if available]

I'll update you by [specific date/time] with a resolution timeline.
In the meantime, [workaround details if applicable].

Let me know if you have any questions or if this is impacting you in
other ways I should know about.

Best,
[Your name]
```

### Acknowledging a Billing or Account Issue

```
Hi [Name],

Thank you for reaching out about this — I understand billing issues
need prompt attention, and I want to make sure this gets resolved
quickly.

I've looked into your account and here's what I'm seeing:
- [What happened — clear factual explanation]
- [Impact on their account — charges, access, etc.]

Here's what I'm doing to fix this:
- [Action 1 — with timeline]
- [Action 2 — if applicable]

[If resolution is immediate: "This has been corrected and you should
see the change reflected within [timeframe]."]
[If needs investigation: "I'm escalating this to our billing team
and will have an update for you by [specific date]."]

I'm sorry for the inconvenience. Let me know if you have any
questions about your account.

Best,
[Your name]
```

### Responding to a Feature Request You Won't Build

```
Hi [Name],

Thank you for sharing this request — I can see why [capability] would
be valuable for [their use case].

I discussed this with our product team, and this isn't something we're
planning to build in the near term. The primary reason is [honest,
respectful explanation — e.g., it serves a narrow use case, it conflicts
with our architecture direction, etc.].

That said, I want to make sure you can accomplish your goal. Here are
some alternatives:
- [Alternative approach 1]
- [Alternative approach 2]
- [Integration or workaround if applicable]

I've also documented your request in our feedback system, and if our
direction changes, I'll let you know.

Would any of these alternatives work for your team? Happy to dig
deeper into any of them.

Best,
[Your name]
```

### Outage or Incident Communication

```
Hi [Name],

I wanted to reach out directly to let you know about an issue affecting
[service/feature] that I know your team relies on.

**What happened:** [Clear, non-technical explanation]
**Impact:** [How it affects them specifically]
**Status:** [Current status — investigating / identified / fixing / resolved]
**ETA for resolution:** [Specific time if known, or "we'll update every X hours"]

[If applicable: "In the meantime, you can [workaround]."]

I'm personally tracking this and will update you as soon as we have a
resolution. You can also check [status page URL] for real-time updates.

I'm sorry for the disruption to your team's work. We take this seriously
and [what you're doing to prevent recurrence if known].

[Your name]
```

### Following Up After Silence

```
Hi [Name],

I wanted to check in — I sent over [what you sent] on [date] and
wanted to make sure it didn't get lost in the shuffle.

[Brief reminder of what you need from them or what you're offering]

If now isn't a good time, no worries — just let me know when would be
better, and I'm happy to reconnect then.

Best,
[Your name]
```

## Follow-up and Escalation Guidance

### Follow-up Cadence

| Situation | Follow-up Timing |
|-----------|-----------------|
| Unanswered question | 2-3 business days |
| Open support issue | Daily until resolved for critical, 2-3 days for standard |
| Post-meeting action items | Within 24 hours (send notes), then check at deadline |
| General check-in | As needed for ongoing issues |
| After delivering bad news | 1 week to check on impact and sentiment |

### When to Escalate

**Escalate to your manager when:**
- Customer threatens to cancel or significantly downsell
- Customer requests exception to policy you can't authorize
- An issue has been unresolved for longer than SLA allows
- Customer requests direct contact with leadership
- You've made an error that needs senior involvement to resolve

**Escalate to product/engineering when:**
- Bug is critical and blocking the customer's business
- Feature gap is causing a competitive loss
- Customer has unique technical requirements beyond standard support
- Integration issues require engineering investigation

**Escalation format:**
```
ESCALATION: [Customer Name] — [One-line summary]

Urgency: [Critical / High / Medium]
Customer impact: [What's broken for them]
History: [Brief background — 2-3 sentences]
What I've tried: [Actions taken so far]
What I need: [Specific help or decision needed]
Deadline: [When this needs to be resolved by]
```$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/customer-support/skills/kb-article', 'business', 'kb-article', '', 'kb-article', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /kb-article

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Draft a publish-ready knowledge base article from a resolved support issue, common question, or documented workaround. Structures the content for searchability and self-service.

## Usage

```
/kb-article <resolved issue, ticket reference, or topic description>
```

Examples:
- `/kb-article How to configure SSO with Okta — resolved this for 3 customers last month`
- `/kb-article Ticket #4521 — customer couldn't export data over 10k rows`
- `/kb-article Common question: how to set up webhook notifications`
- `/kb-article Known issue: dashboard charts not loading on Safari 16`

## Workflow

### 1. Understand the Source Material

Parse the input to identify:

- **What was the problem?** The original issue, question, or error
- **What was the solution?** The resolution, workaround, or answer
- **Who does this affect?** User type, plan level, or configuration
- **How common is this?** One-off or recurring issue
- **What article type fits best?** How-to, troubleshooting, FAQ, known issue, or reference (see article types below)

If a ticket reference is provided, look up the full context:

- **~~support platform**: Pull the ticket thread, resolution, and any internal notes
- **~~knowledge base**: Check if a similar article already exists (update vs. create new)
- **~~project tracker**: Check if there's a related bug or feature request

### 2. Draft the Article

Using the article structure, formatting standards, and searchability best practices below:

- Follow the template for the chosen article type (how-to, troubleshooting, FAQ, known issue, or reference)
- Apply the searchability best practices: customer-language title, plain-language opening sentence, exact error messages, common synonyms
- Keep it scannable: headers, numbered steps, short paragraphs

### 3. Generate the Article

Present the draft with metadata:

```
## KB Article Draft

**Title:** [Article title]
**Type:** [How-to / Troubleshooting / FAQ / Known Issue / Reference]
**Category:** [Product area or topic]
**Tags:** [Searchable tags]
**Audience:** [All users / Admins / Developers / Specific plan]

---

[Full article content — using the appropriate template below]

---

### Publishing Notes
- **Source:** [Ticket #, customer conversation, or internal discussion]
- **Existing articles to update:** [If this overlaps with existing content]
- **Review needed from:** [SME or team if technical accuracy needs verification]
- **Suggested review date:** [When to revisit for accuracy]
```

### 4. Offer Next Steps

After generating the article:
- "Want me to check if a similar article already exists in your ~~knowledge base?"
- "Should I adjust the technical depth for a different audience?"
- "Want me to draft a companion article (e.g., a how-to to go with this troubleshooting guide)?"
- "Should I create an internal-only version with additional technical detail?"

---

## Article Structure and Formatting Standards

### Universal Article Elements

Every KB article should include:

1. **Title**: Clear, searchable, describes the outcome or problem (not internal jargon)
2. **Overview**: 1-2 sentences explaining what this article covers and who it's for
3. **Body**: Structured content appropriate to the article type
4. **Related articles**: Links to relevant companion content
5. **Metadata**: Category, tags, audience, last updated date

### Formatting Rules

- **Use headers (H2, H3)** to break content into scannable sections
- **Use numbered lists** for sequential steps
- **Use bullet lists** for non-sequential items
- **Use bold** for UI element names, key terms, and emphasis
- **Use code blocks** for commands, API calls, error messages, and configuration values
- **Use tables** for comparisons, options, or reference data
- **Use callouts/notes** for warnings, tips, and important caveats
- **Keep paragraphs short** — 2-4 sentences max
- **One idea per section** — if a section covers two topics, split it

## Writing for Searchability

Articles are useless if customers can't find them. Optimize every article for search:

### Title Best Practices

| Good Title | Bad Title | Why |
|------------|-----------|-----|
| "How to configure SSO with Okta" | "SSO Setup" | Specific, includes the tool name customers search for |
| "Fix: Dashboard shows blank page" | "Dashboard Issue" | Includes the symptom customers experience |
| "API rate limits and quotas" | "API Information" | Includes the specific terms customers search for |
| "Error: 'Connection refused' when importing data" | "Import Problems" | Includes the exact error message |

### Keyword Optimization

- **Include exact error messages** — customers copy-paste error text into search
- **Use customer language**, not internal terminology — "can't log in" not "authentication failure"
- **Include common synonyms** — "delete/remove", "dashboard/home page", "export/download"
- **Add alternate phrasings** — address the same issue from different angles in the overview
- **Tag with product areas** — make sure category and tags match how customers think about the product

### Opening Sentence Formula

Start every article with a sentence that restates the problem or task in plain language:

- **How-to**: "This guide shows you how to [accomplish X]."
- **Troubleshooting**: "If you're seeing [symptom], this article explains how to fix it."
- **FAQ**: "[Question in the customer's words]? Here's the answer."
- **Known issue**: "Some users are experiencing [symptom]. Here's what we know and how to work around it."

## Article Type Templates

### How-to Articles

**Purpose**: Step-by-step instructions for accomplishing a task.

**Structure**:
```
# How to [accomplish task]

[Overview — what this guide covers and when you'd use it]

## Prerequisites
- [What's needed before starting]

## Steps
### 1. [Action]
[Instruction with specific details]

### 2. [Action]
[Instruction]

## Verify It Worked
[How to confirm success]

## Common Issues
- [Issue]: [Fix]

## Related Articles
- [Links]
```

**Best practices**:
- Start each step with a verb
- Include the specific path: "Go to Settings > Integrations > API Keys"
- Mention what the user should see after each step ("You should see a green confirmation banner")
- Test the steps yourself or verify with a recent ticket resolution

### Troubleshooting Articles

**Purpose**: Diagnose and resolve a specific problem.

**Structure**:
```
# [Problem description — what the user sees]

## Symptoms
- [What the user observes]

## Cause
[Why this happens — brief, non-jargon explanation]

## Solution
### Option 1: [Primary fix]
[Steps]

### Option 2: [Alternative if Option 1 doesn't work]
[Steps]

## Prevention
[How to avoid this in the future]

## Still Having Issues?
[How to get help]
```

**Best practices**:
- Lead with symptoms, not causes — customers search for what they see
- Provide multiple solutions when possible (most likely fix first)
- Include a "Still having issues?" section that points to support
- If the root cause is complex, keep the customer-facing explanation simple

### FAQ Articles

**Purpose**: Quick answer to a common question.

**Structure**:
```
# [Question — in the customer's words]

[Direct answer — 1-3 sentences]

## Details
[Additional context, nuance, or explanation if needed]

## Related Questions
- [Link to related FAQ]
- [Link to related FAQ]
```

**Best practices**:
- Answer the question in the first sentence
- Keep it concise — if the answer needs a walkthrough, it's a how-to, not an FAQ
- Group related FAQs and link between them

### Known Issue Articles

**Purpose**: Document a known bug or limitation with a workaround.

**Structure**:
```
# [Known Issue]: [Brief description]

**Status:** [Investigating / Workaround Available / Fix In Progress / Resolved]
**Affected:** [Who/what is affected]
**Last updated:** [Date]

## Symptoms
[What users experience]

## Workaround
[Steps to work around the issue, or "No workaround available"]

## Fix Timeline
[Expected fix date or current status]

## Updates
- [Date]: [Update]
```

**Best practices**:
- Keep the status current — nothing erodes trust faster than a stale known issue article
- Update the article when the fix ships and mark as resolved
- If resolved, keep the article live for 30 days for customers still searching the old symptoms

## Review and Maintenance Cadence

Knowledge bases decay without maintenance. Follow this schedule:

| Activity | Frequency | Who |
|----------|-----------|-----|
| **New article review** | Before publishing | Peer review + SME for technical content |
| **Accuracy audit** | Quarterly | Support team reviews top-traffic articles |
| **Stale content check** | Monthly | Flag articles not updated in 6+ months |
| **Known issue updates** | Weekly | Update status on all open known issues |
| **Analytics review** | Monthly | Check which articles have low helpfulness ratings or high bounce rates |
| **Gap analysis** | Quarterly | Identify top ticket topics without KB articles |

### Article Lifecycle

1. **Draft**: Written, needs review
2. **Published**: Live and available to customers
3. **Needs update**: Flagged for revision (product change, feedback, or age)
4. **Archived**: No longer relevant but preserved for reference
5. **Retired**: Removed from the knowledge base

### When to Update vs. Create New

**Update existing** when:
- The product changed and steps need refreshing
- The article is mostly right but missing a detail
- Feedback indicates customers are confused by a specific section
- A better workaround or solution was found

**Create new** when:
- A new feature or product area needs documentation
- A resolved ticket reveals a gap — no article exists for this topic
- The existing article covers too many topics and should be split
- A different audience needs the same information explained differently

## Linking and Categorization Taxonomy

### Category Structure

Organize articles into a hierarchy that matches how customers think:

```
Getting Started
├── Account setup
├── First-time configuration
└── Quick start guides

Features & How-tos
├── [Feature area 1]
├── [Feature area 2]
└── [Feature area 3]

Integrations
├── [Integration 1]
├── [Integration 2]
└── API reference

Troubleshooting
├── Common errors
├── Performance issues
└── Known issues

Billing & Account
├── Plans and pricing
├── Billing questions
└── Account management
```

### Linking Best Practices

- **Link from troubleshooting to how-to**: "For setup instructions, see [How to configure X]"
- **Link from how-to to troubleshooting**: "If you encounter errors, see [Troubleshooting X]"
- **Link from FAQ to detailed articles**: "For a full walkthrough, see [Guide to X]"
- **Link from known issues to workarounds**: Keep the chain from problem to solution short
- **Use relative links** within the KB — they survive restructuring better than absolute URLs
- **Avoid circular links** — if A links to B, B shouldn't link back to A unless both are genuinely useful entry points

## KB Writing Best Practices

1. Write for the customer who is frustrated and searching for an answer — be clear, direct, and helpful
2. Every article should be findable through search using the words a customer would type
3. Test your articles — follow the steps yourself or have someone unfamiliar with the topic follow them
4. Keep articles focused — one problem, one solution. Split if an article is growing too long
5. Maintain aggressively — a wrong article is worse than no article
6. Track what's missing — every ticket that could have been a KB article is a content gap
7. Measure impact — articles that don't get traffic or don't reduce tickets need to be improved or retired$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/customer-support/skills/ticket-triage', 'business', 'ticket-triage', '', 'ticket-triage', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /ticket-triage

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Categorize, prioritize, and route an incoming support ticket or customer issue. Produces a structured triage assessment with a suggested initial response.

## Usage

```
/ticket-triage <ticket text, customer message, or issue description>
```

Examples:
- `/ticket-triage Customer says their dashboard has been showing a blank page since this morning`
- `/ticket-triage "I was charged twice for my subscription this month"`
- `/ticket-triage User can't connect their SSO — getting a 403 error on the callback URL`
- `/ticket-triage Feature request: they want to export reports as PDF`

## Workflow

### 1. Parse the Issue

Read the input and extract:

- **Core problem**: What is the customer actually experiencing?
- **Symptoms**: What specific behavior or error are they seeing?
- **Customer context**: Who is this? Any account details, plan level, or history available?
- **Urgency signals**: Are they blocked? Is this production? How many users affected?
- **Emotional state**: Frustrated, confused, matter-of-fact, escalating?

### 2. Categorize and Prioritize

Using the category taxonomy and priority framework below:

- Assign a **primary category** (bug, how-to, feature request, billing, account, integration, security, data, performance) and an optional secondary category
- Assign a **priority** (P1–P4) based on impact and urgency
- Identify the **product area** the issue maps to

### 3. Check for Duplicates and Known Issues

Before routing, check available sources:

- **~~support platform**: Search for similar open or recently resolved tickets
- **~~knowledge base**: Check for known issues or existing documentation
- **~~project tracker**: Check if there's an existing bug report or feature request

Apply the duplicate detection process below.

### 4. Determine Routing

Using the routing rules below, recommend which team or queue should handle this based on category and complexity.

### 5. Generate Triage Output

```
## Triage: [One-line issue summary]

**Category:** [Primary] / [Secondary if applicable]
**Priority:** [P1-P4] — [Brief justification]
**Product area:** [Area/team]

### Issue Summary
[2-3 sentence summary of what the customer is experiencing]

### Key Details
- **Customer:** [Name/account if known]
- **Impact:** [Who and what is affected]
- **Workaround:** [Available / Not available / Unknown]
- **Related tickets:** [Links to similar issues if found]
- **Known issue:** [Yes — link / No / Checking]

### Routing Recommendation
**Route to:** [Team or queue]
**Why:** [Brief reasoning]

### Suggested Initial Response
[Draft first response to the customer — acknowledge the issue,
set expectations, provide workaround if available.
Use the auto-response templates below as a starting point.]

### Internal Notes
- [Any additional context for the agent picking this up]
- [Reproduction hints if it's a bug]
- [Escalation triggers to watch for]
```

### 6. Offer Next Steps

After presenting the triage:
- "Want me to draft a full response to the customer?"
- "Should I search for more context on this issue?"
- "Want me to check if this is a known bug in the tracker?"
- "Should I escalate this? I can package it with /customer-escalation."

---

## Category Taxonomy

Assign every ticket a **primary category** and optionally a **secondary category**:

| Category | Description | Signal Words |
|----------|-------------|-------------|
| **Bug** | Product is behaving incorrectly or unexpectedly | Error, broken, crash, not working, unexpected, wrong, failing |
| **How-to** | Customer needs guidance on using the product | How do I, can I, where is, setting up, configure, help with |
| **Feature request** | Customer wants a capability that doesn't exist | Would be great if, wish I could, any plans to, requesting |
| **Billing** | Payment, subscription, invoice, or pricing issues | Charge, invoice, payment, subscription, refund, upgrade, downgrade |
| **Account** | Account access, permissions, settings, or user management | Login, password, access, permission, SSO, locked out, can't sign in |
| **Integration** | Issues connecting to third-party tools or APIs | API, webhook, integration, connect, OAuth, sync, third-party |
| **Security** | Security concerns, data access, or compliance questions | Data breach, unauthorized, compliance, GDPR, SOC 2, vulnerability |
| **Data** | Data quality, migration, import/export issues | Missing data, export, import, migration, incorrect data, duplicates |
| **Performance** | Speed, reliability, or availability issues | Slow, timeout, latency, down, unavailable, degraded |

### Category Determination Tips

- If the customer reports **both** a bug and a feature request, the bug is primary
- If they can't log in due to a bug, category is **Bug** (not Account) — root cause drives the category
- "It used to work and now it doesn't" = **Bug**
- "I want it to work differently" = **Feature request**
- "How do I make it work?" = **How-to**
- When in doubt, lean toward **Bug** — it's better to investigate than dismiss

## Priority Framework

### P1 — Critical
**Criteria:** Production system down, data loss or corruption, security breach, all or most users affected.

- The customer cannot use the product at all
- Data is being lost, corrupted, or exposed
- A security incident is in progress
- The issue is worsening or expanding in scope

**SLA expectation:** Respond within 1 hour. Continuous work until resolved or mitigated. Updates every 1-2 hours.

### P2 — High
**Criteria:** Major feature broken, significant workflow blocked, many users affected, no workaround.

- A core workflow is broken but the product is partially usable
- Multiple users are affected or a key account is impacted
- The issue is blocking time-sensitive work
- No reasonable workaround exists

**SLA expectation:** Respond within 4 hours. Active investigation same day. Updates every 4 hours.

### P3 — Medium
**Criteria:** Feature partially broken, workaround available, single user or small team affected.

- A feature isn't working correctly but a workaround exists
- The issue is inconvenient but not blocking critical work
- A single user or small team is affected
- The customer is not escalating urgently

**SLA expectation:** Respond within 1 business day. Resolution or update within 3 business days.

### P4 — Low
**Criteria:** Minor inconvenience, cosmetic issue, general question, feature request.

- Cosmetic or UI issues that don't affect functionality
- Feature requests and enhancement ideas
- General questions or how-to inquiries
- Issues with simple, documented solutions

**SLA expectation:** Respond within 2 business days. Resolution at normal pace.

### Priority Escalation Triggers

Automatically bump priority up when:
- Customer has been waiting longer than the SLA allows
- Multiple customers report the same issue (pattern detected)
- The customer explicitly escalates or mentions executive involvement
- A workaround that was in place stops working
- The issue expands in scope (more users, more data, new symptoms)

## Routing Rules

Route tickets based on category and complexity:

| Route to | When |
|----------|------|
| **Tier 1 (frontline support)** | How-to questions, known issues with documented solutions, billing inquiries, password resets |
| **Tier 2 (senior support)** | Bugs requiring investigation, complex configuration, integration troubleshooting, account issues |
| **Engineering** | Confirmed bugs needing code fixes, infrastructure issues, performance degradation |
| **Product** | Feature requests with significant demand, design decisions, workflow gaps |
| **Security** | Data access concerns, vulnerability reports, compliance questions |
| **Billing/Finance** | Refund requests, contract disputes, complex billing adjustments |

## Duplicate Detection

Before creating a new ticket or routing, check for duplicates:

1. **Search by symptom**: Look for tickets with similar error messages or descriptions
2. **Search by customer**: Check if this customer has an open ticket for the same issue
3. **Search by product area**: Look for recent tickets in the same feature area
4. **Check known issues**: Compare against documented known issues

**If a duplicate is found:**
- Link the new ticket to the existing one
- Notify the customer that this is a known issue being tracked
- Add any new information from the new report to the existing ticket
- Bump priority if the new report adds urgency (more customers affected, etc.)

## Auto-Response Templates by Category

### Bug — Initial Response
```
Thank you for reporting this. I can see how [specific impact]
would be disruptive for your work.

I've logged this as a [priority] issue and our team is
investigating. [If workaround exists: "In the meantime, you
can [workaround]."]

I'll update you within [SLA timeframe] with what we find.
```

### How-to — Initial Response
```
Great question! [Direct answer or link to documentation]

[If more complex: "Let me walk you through the steps:"]
[Steps or guidance]

Let me know if that helps, or if you have any follow-up
questions.
```

### Feature Request — Initial Response
```
Thank you for this suggestion — I can see why [capability]
would be valuable for your workflow.

I've documented this and shared it with our product team.
While I can't commit to a specific timeline, your feedback
directly informs our roadmap priorities.

[If alternative exists: "In the meantime, you might find
[alternative] helpful for achieving something similar."]
```

### Billing — Initial Response
```
I understand billing issues need prompt attention. Let me
look into this for you.

[If straightforward: resolution details]
[If complex: "I'm reviewing your account now and will have
an answer for you within [timeframe]."]
```

### Security — Initial Response
```
Thank you for flagging this — we take security concerns
seriously and are reviewing this immediately.

I've escalated this to our security team for investigation.
We'll follow up with you within [timeframe] with our findings.

[If action is needed: "In the meantime, we recommend
[protective action]."]
```

## Triage Best Practices

1. Read the full ticket before categorizing — context in later messages often changes the assessment
2. Categorize by **root cause**, not just the symptom described
3. When in doubt on priority, err on the side of higher — it's easier to de-escalate than to recover from a missed SLA
4. Always check for duplicates and known issues before routing
5. Write internal notes that help the next person pick up context quickly
6. Include what you've already checked or ruled out to avoid duplicate investigation
7. Flag patterns — if you're seeing the same issue repeatedly, escalate the pattern even if individual tickets are low priority$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/analyze', 'business', 'analyze', '', 'analyze', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /analyze - Answer Data Questions

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Answer a data question, from a quick lookup to a full analysis to a formal report.

## Usage

```
/analyze <natural language question>
```

## Workflow

### 1. Understand the Question

Parse the user's question and determine:

- **Complexity level**:
  - **Quick answer**: Single metric, simple filter, factual lookup (e.g., "How many users signed up last week?")
  - **Full analysis**: Multi-dimensional exploration, trend analysis, comparison (e.g., "What's driving the drop in conversion rate?")
  - **Formal report**: Comprehensive investigation with methodology, caveats, and recommendations (e.g., "Prepare a quarterly business review of our subscription metrics")
- **Data requirements**: Which tables, metrics, dimensions, and time ranges are needed
- **Output format**: Number, table, chart, narrative, or combination

### 2. Gather Data

**If a data warehouse MCP server is connected:**

1. Explore the schema to find relevant tables and columns
2. Write SQL query(ies) to extract the needed data
3. Execute the query and retrieve results
4. If the query fails, debug and retry (check column names, table references, syntax for the specific dialect)
5. If results look unexpected, run sanity checks before proceeding

**If no data warehouse is connected:**

1. Ask the user to provide data in one of these ways:
   - Paste query results directly
   - Upload a CSV or Excel file
   - Describe the schema so you can write queries for them to run
2. If writing queries for manual execution, use the `sql-queries` skill for dialect-specific best practices
3. Once data is provided, proceed with analysis

### 3. Analyze

- Calculate relevant metrics, aggregations, and comparisons
- Identify patterns, trends, outliers, and anomalies
- Compare across dimensions (time periods, segments, categories)
- For complex analyses, break the problem into sub-questions and address each

### 4. Validate Before Presenting

Before sharing results, run through validation checks:

- **Row count sanity**: Does the number of records make sense?
- **Null check**: Are there unexpected nulls that could skew results?
- **Magnitude check**: Are the numbers in a reasonable range?
- **Trend continuity**: Do time series have unexpected gaps?
- **Aggregation logic**: Do subtotals sum to totals correctly?

If any check raises concerns, investigate and note caveats.

### 5. Present Findings

**For quick answers:**
- State the answer directly with relevant context
- Include the query used (collapsed or in a code block) for reproducibility

**For full analyses:**
- Lead with the key finding or insight
- Support with data tables and/or visualizations
- Note methodology and any caveats
- Suggest follow-up questions

**For formal reports:**
- Executive summary with key takeaways
- Methodology section explaining approach and data sources
- Detailed findings with supporting evidence
- Caveats, limitations, and data quality notes
- Recommendations and suggested next steps

### 6. Visualize Where Helpful

When a chart would communicate results more effectively than a table:

- Use the `data-visualization` skill to select the right chart type
- Generate a Python visualization or build it into an HTML dashboard
- Follow visualization best practices for clarity and accuracy

## Examples

**Quick answer:**
```
/analyze How many new users signed up in December?
```

**Full analysis:**
```
/analyze What's causing the increase in support ticket volume over the past 3 months? Break down by category and priority.
```

**Formal report:**
```
/analyze Prepare a data quality assessment of our customer table -- completeness, consistency, and any issues we should address.
```

## Tips

- Be specific about time ranges, segments, or metrics when possible
- If you know the table names, mention them to speed up the process
- For complex questions, Claude may break them into multiple queries
- Results are always validated before presentation -- if something looks off, Claude will flag it$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/data/skills/build-dashboard', 'business', 'build-dashboard', '', 'build-dashboard', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-dashboard - Build Interactive Dashboards

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Build a self-contained interactive HTML dashboard with charts, filters, tables, and professional styling. Opens directly in a browser -- no server or dependencies required.

## Usage

```
/build-dashboard <description of dashboard> [data source]
```

## Workflow

### 1. Understand the Dashboard Requirements

Determine:

- **Purpose**: Executive overview, operational monitoring, deep-dive analysis, team reporting
- **Audience**: Who will use this dashboard?
- **Key metrics**: What numbers matter most?
- **Dimensions**: What should users be able to filter or slice by?
- **Data source**: Live query, pasted data, CSV file, or sample data

### 2. Gather the Data

**If data warehouse is connected:**
1. Query the necessary data
2. Embed the results as JSON within the HTML file

**If data is pasted or uploaded:**
1. Parse and clean the data
2. Embed as JSON in the dashboard

**If working from a description without data:**
1. Create a realistic sample dataset matching the described schema
2. Note in the dashboard that it uses sample data
3. Provide instructions for swapping in real data

### 3. Design the Dashboard Layout

Follow a standard dashboard layout pattern:

```
┌──────────────────────────────────────────────────┐
│  Dashboard Title                    [Filters ▼]  │
├────────────┬────────────┬────────────┬───────────┤
│  KPI Card  │  KPI Card  │  KPI Card  │ KPI Card  │
├────────────┴────────────┼────────────┴───────────┤
│                         │                        │
│    Primary Chart        │   Secondary Chart      │
│    (largest area)       │                        │
│                         │                        │
├─────────────────────────┴────────────────────────┤
│                                                  │
│    Detail Table (sortable, scrollable)           │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Adapt the layout to the content:**
- 2-4 KPI cards at the top for headline numbers
- 1-3 charts in the middle section for trends and breakdowns
- Optional detail table at the bottom for drill-down data
- Filters in the header or sidebar depending on complexity

### 4. Build the HTML Dashboard

Generate a single self-contained HTML file using the base template below. The file includes:

**Structure (HTML):**
- Semantic HTML5 layout
- Responsive grid using CSS Grid or Flexbox
- Filter controls (dropdowns, date pickers, toggles)
- KPI cards with values and labels
- Chart containers
- Data table with sortable headers

**Styling (CSS):**
- Professional color scheme (clean whites, grays, with accent colors for data)
- Card-based layout with subtle shadows
- Consistent typography (system fonts for fast loading)
- Responsive design that works on different screen sizes
- Print-friendly styles

**Interactivity (JavaScript):**
- Chart.js for interactive charts (included via CDN)
- Filter dropdowns that update all charts and tables simultaneously
- Sortable table columns
- Hover tooltips on charts
- Number formatting (commas, currency, percentages)

**Data (embedded JSON):**
- All data embedded directly in the HTML as JavaScript variables
- No external data fetches required
- Dashboard works completely offline

### 5. Implement Chart Types

Use Chart.js for all charts. Common dashboard chart patterns:

- **Line chart**: Time series trends
- **Bar chart**: Category comparisons
- **Doughnut chart**: Composition (when <6 categories)
- **Stacked bar**: Composition over time
- **Mixed (bar + line)**: Volume with rate overlay

Use the Chart.js integration patterns below for each chart type.

### 6. Add Interactivity

Use the filter and interactivity implementation patterns below for dropdown filters, date range filters, combined filter logic, sortable tables, and chart updates.

### 7. Save and Open

1. Save the dashboard as an HTML file with a descriptive name (e.g., `sales_dashboard.html`)
2. Open it in the user's default browser
3. Confirm it renders correctly
4. Provide instructions for updating data or customizing

---

## Base Template

Every dashboard follows this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.5.1" integrity="sha384-jb8JQMbMoBUzgWatfe6COACi2ljcDdZQ2OxczGA3bGNeWe+6DChMTBJemed7ZnvJ" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0" integrity="sha384-cVMg8E3QFwTvGCDuK+ET4PD341jF3W8nO1auiXfuZNQkzbUUiBGLsIQUE+b1mxws" crossorigin="anonymous"></script>
    <style>
        /* Dashboard styles go here */
    </style>
</head>
<body>
    <div class="dashboard-container">
        <header class="dashboard-header">
            <h1>Dashboard Title</h1>
            <div class="filters">
                <!-- Filter controls -->
            </div>
        </header>

        <section class="kpi-row">
            <!-- KPI cards -->
        </section>

        <section class="chart-row">
            <!-- Chart containers -->
        </section>

        <section class="table-section">
            <!-- Data table -->
        </section>

        <footer class="dashboard-footer">
            <span>Data as of: <span id="data-date"></span></span>
        </footer>
    </div>

    <script>
        // Embedded data
        const DATA = [];

        // Dashboard logic
        class Dashboard {
            constructor(data) {
                this.rawData = data;
                this.filteredData = data;
                this.charts = {};
                this.init();
            }

            init() {
                this.setupFilters();
                this.renderKPIs();
                this.renderCharts();
                this.renderTable();
            }

            applyFilters() {
                // Filter logic
                this.filteredData = this.rawData.filter(row => {
                    // Apply each active filter
                    return true; // placeholder
                });
                this.renderKPIs();
                this.updateCharts();
                this.renderTable();
            }

            // ... methods for each section
        }

        const dashboard = new Dashboard(DATA);
    </script>
</body>
</html>
```

## KPI Card Pattern

```html
<div class="kpi-card">
    <div class="kpi-label">Total Revenue</div>
    <div class="kpi-value" id="kpi-revenue">$0</div>
    <div class="kpi-change positive" id="kpi-revenue-change">+0%</div>
</div>
```

```javascript
function renderKPI(elementId, value, previousValue, format = 'number') {
    const el = document.getElementById(elementId);
    const changeEl = document.getElementById(elementId + '-change');

    // Format the value
    el.textContent = formatValue(value, format);

    // Calculate and display change
    if (previousValue && previousValue !== 0) {
        const pctChange = ((value - previousValue) / previousValue) * 100;
        const sign = pctChange >= 0 ? '+' : '';
        changeEl.textContent = `${sign}${pctChange.toFixed(1)}% vs prior period`;
        changeEl.className = `kpi-change ${pctChange >= 0 ? 'positive' : 'negative'}`;
    }
}

function formatValue(value, format) {
    switch (format) {
        case 'currency':
            if (value >= 1e6) return `$${(value / 1e6).toFixed(1)}M`;
            if (value >= 1e3) return `$${(value / 1e3).toFixed(1)}K`;
            return `$${value.toFixed(0)}`;
        case 'percent':
            return `${value.toFixed(1)}%`;
        case 'number':
            if (value >= 1e6) return `${(value / 1e6).toFixed(1)}M`;
            if (value >= 1e3) return `${(value / 1e3).toFixed(1)}K`;
            return value.toLocaleString();
        default:
            return value.toString();
    }
}
```

## Chart.js Integration

### Chart Container Pattern

```html
<div class="chart-container">
    <h3 class="chart-title">Monthly Revenue Trend</h3>
    <canvas id="revenue-chart"></canvas>
</div>
```

### Line Chart

```javascript
function createLineChart(canvasId, labels, datasets) {
    const ctx = document.getElementById(canvasId).getContext('2d');
    return new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: datasets.map((ds, i) => ({
                label: ds.label,
                data: ds.data,
                borderColor: COLORS[i % COLORS.length],
                backgroundColor: COLORS[i % COLORS.length] + '20',
                borderWidth: 2,
                fill: ds.fill || false,
                tension: 0.3,
                pointRadius: 3,
                pointHoverRadius: 6,
            }))
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            plugins: {
                legend: {
                    position: 'top',
                    labels: { usePointStyle: true, padding: 20 }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return `${context.dataset.label}: ${formatValue(context.parsed.y, 'currency')}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: { display: false }
                },
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return formatValue(value, 'currency');
                        }
                    }
                }
            }
        }
    });
}
```

### Bar Chart

```javascript
function createBarChart(canvasId, labels, data, options = {}) {
    const ctx = document.getElementById(canvasId).getContext('2d');
    const isHorizontal = options.horizontal || labels.length > 8;

    return new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: options.label || 'Value',
                data: data,
                backgroundColor: options.colors || COLORS.map(c => c + 'CC'),
                borderColor: options.colors || COLORS,
                borderWidth: 1,
                borderRadius: 4,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: isHorizontal ? 'y' : 'x',
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return formatValue(context.parsed[isHorizontal ? 'x' : 'y'], options.format || 'number');
                        }
                    }
                }
            },
            scales: {
                x: {
                    beginAtZero: true,
                    grid: { display: isHorizontal },
                    ticks: isHorizontal ? {
                        callback: function(value) {
                            return formatValue(value, options.format || 'number');
                        }
                    } : {}
                },
                y: {
                    beginAtZero: !isHorizontal,
                    grid: { display: !isHorizontal },
                    ticks: !isHorizontal ? {
                        callback: function(value) {
                            return formatValue(value, options.format || 'number');
                        }
                    } : {}
                }
            }
        }
    });
}
```

### Doughnut Chart

```javascript
function createDoughnutChart(canvasId, labels, data) {
    const ctx = document.getElementById(canvasId).getContext('2d');
    return new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: data,
                backgroundColor: COLORS.map(c => c + 'CC'),
                borderColor: '#ffffff',
                borderWidth: 2,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '60%',
            plugins: {
                legend: {
                    position: 'right',
                    labels: { usePointStyle: true, padding: 15 }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                            const pct = ((context.parsed / total) * 100).toFixed(1);
                            return `${context.label}: ${formatValue(context.parsed, 'number')} (${pct}%)`;
                        }
                    }
                }
            }
        }
    });
}
```

### Updating Charts on Filter Change

```javascript
function updateChart(chart, newLabels, newData) {
    chart.data.labels = newLabels;

    if (Array.isArray(newData[0])) {
        // Multiple datasets
        newData.forEach((data, i) => {
            chart.data.datasets[i].data = data;
        });
    } else {
        chart.data.datasets[0].data = newData;
    }

    chart.update('none'); // 'none' disables animation for instant update
}
```

## Filter and Interactivity Implementation

### Dropdown Filter

```html
<div class="filter-group">
    <label for="filter-region">Region</label>
    <select id="filter-region" onchange="dashboard.applyFilters()">
        <option value="all">All Regions</option>
    </select>
</div>
```

```javascript
function populateFilter(selectId, data, field) {
    const select = document.getElementById(selectId);
    const values = [...new Set(data.map(d => d[field]))].sort();

    // Keep the "All" option, add unique values
    values.forEach(val => {
        const option = document.createElement('option');
        option.value = val;
        option.textContent = val;
        select.appendChild(option);
    });
}

function getFilterValue(selectId) {
    const val = document.getElementById(selectId).value;
    return val === 'all' ? null : val;
}
```

### Date Range Filter

```html
<div class="filter-group">
    <label>Date Range</label>
    <input type="date" id="filter-date-start" onchange="dashboard.applyFilters()">
    <span>to</span>
    <input type="date" id="filter-date-end" onchange="dashboard.applyFilters()">
</div>
```

```javascript
function filterByDateRange(data, dateField, startDate, endDate) {
    return data.filter(row => {
        const rowDate = new Date(row[dateField]);
        if (startDate && rowDate < new Date(startDate)) return false;
        if (endDate && rowDate > new Date(endDate)) return false;
        return true;
    });
}
```

### Combined Filter Logic

```javascript
applyFilters() {
    const region = getFilterValue('filter-region');
    const category = getFilterValue('filter-category');
    const startDate = document.getElementById('filter-date-start').value;
    const endDate = document.getElementById('filter-date-end').value;

    this.filteredData = this.rawData.filter(row => {
        if (region && row.region !== region) return false;
        if (category && row.category !== category) return false;
        if (startDate && row.date < startDate) return false;
        if (endDate && row.date > endDate) return false;
        return true;
    });

    this.renderKPIs();
    this.updateCharts();
    this.renderTable();
}
```

### Sortable Table

```javascript
function renderTable(containerId, data, columns) {
    const container = document.getElementById(containerId);
    let sortCol = null;
    let sortDir = 'desc';

    function render(sortedData) {
        let html = '<table class="data-table">';

        // Header
        html += '<thead><tr>';
        columns.forEach(col => {
            const arrow = sortCol === col.field
                ? (sortDir === 'asc' ? ' ▲' : ' ▼')
                : '';
            html += `<th onclick="sortTable('${col.field}')" style="cursor:pointer">${col.label}${arrow}</th>`;
        });
        html += '</tr></thead>';

        // Body
        html += '<tbody>';
        sortedData.forEach(row => {
            html += '<tr>';
            columns.forEach(col => {
                const value = col.format ? formatValue(row[col.field], col.format) : row[col.field];
                html += `<td>${value}</td>`;
            });
            html += '</tr>';
        });
        html += '</tbody></table>';

        container.innerHTML = html;
    }

    window.sortTable = function(field) {
        if (sortCol === field) {
            sortDir = sortDir === 'asc' ? 'desc' : 'asc';
        } else {
            sortCol = field;
            sortDir = 'desc';
        }
        const sorted = [...data].sort((a, b) => {
            const aVal = a[field], bVal = b[field];
            const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
            return sortDir === 'asc' ? cmp : -cmp;
        });
        render(sorted);
    };

    render(data);
}
```

## CSS Styling for Dashboards

### Color System

```css
:root {
    /* Background layers */
    --bg-primary: #f8f9fa;
    --bg-card: #ffffff;
    --bg-header: #1a1a2e;

    /* Text */
    --text-primary: #212529;
    --text-secondary: #6c757d;
    --text-on-dark: #ffffff;

    /* Accent colors for data */
    --color-1: #4C72B0;
    --color-2: #DD8452;
    --color-3: #55A868;
    --color-4: #C44E52;
    --color-5: #8172B3;
    --color-6: #937860;

    /* Status colors */
    --positive: #28a745;
    --negative: #dc3545;
    --neutral: #6c757d;

    /* Spacing */
    --gap: 16px;
    --radius: 8px;
}
```

### Layout

```css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.5;
}

.dashboard-container {
    max-width: 1400px;
    margin: 0 auto;
    padding: var(--gap);
}

.dashboard-header {
    background: var(--bg-header);
    color: var(--text-on-dark);
    padding: 20px 24px;
    border-radius: var(--radius);
    margin-bottom: var(--gap);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
}

.dashboard-header h1 {
    font-size: 20px;
    font-weight: 600;
}
```

### KPI Cards

```css
.kpi-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--gap);
    margin-bottom: var(--gap);
}

.kpi-card {
    background: var(--bg-card);
    border-radius: var(--radius);
    padding: 20px 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.kpi-label {
    font-size: 13px;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 4px;
}

.kpi-value {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 4px;
}

.kpi-change {
    font-size: 13px;
    font-weight: 500;
}

.kpi-change.positive { color: var(--positive); }
.kpi-change.negative { color: var(--negative); }
```

### Chart Containers

```css
.chart-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
    gap: var(--gap);
    margin-bottom: var(--gap);
}

.chart-container {
    background: var(--bg-card);
    border-radius: var(--radius);
    padding: 20px 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.chart-container h3 {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 16px;
}

.chart-container canvas {
    max-height: 300px;
}
```

### Filters

```css
.filters {
    display: flex;
    gap: 12px;
    align-items: center;
    flex-wrap: wrap;
}

.filter-group {
    display: flex;
    align-items: center;
    gap: 6px;
}

.filter-group label {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.7);
}

.filter-group select,
.filter-group input[type="date"] {
    padding: 6px 10px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 4px;
    background: rgba(255, 255, 255, 0.1);
    color: var(--text-on-dark);
    font-size: 13px;
}

.filter-group select option {
    background: var(--bg-header);
    color: var(--text-on-dark);
}
```

### Data Table

```css
.table-section {
    background: var(--bg-card);
    border-radius: var(--radius);
    padding: 20px 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
    overflow-x: auto;
}

.data-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
}

.data-table thead th {
    text-align: left;
    padding: 10px 12px;
    border-bottom: 2px solid #dee2e6;
    color: var(--text-secondary);
    font-weight: 600;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    white-space: nowrap;
    user-select: none;
}

.data-table thead th:hover {
    color: var(--text-primary);
    background: #f8f9fa;
}

.data-table tbody td {
    padding: 10px 12px;
    border-bottom: 1px solid #f0f0f0;
}

.data-table tbody tr:hover {
    background: #f8f9fa;
}

.data-table tbody tr:last-child td {
    border-bottom: none;
}
```

### Responsive Design

```css
@media (max-width: 768px) {
    .dashboard-header {
        flex-direction: column;
        align-items: flex-start;
    }

    .kpi-row {
        grid-template-columns: repeat(2, 1fr);
    }

    .chart-row {
        grid-template-columns: 1fr;
    }

    .filters {
        flex-direction: column;
        align-items: flex-start;
    }
}

@media print {
    body { background: white; }
    .dashboard-container { max-width: none; }
    .filters { display: none; }
    .chart-container { break-inside: avoid; }
    .kpi-card { border: 1px solid #dee2e6; box-shadow: none; }
}
```

## Performance Considerations for Large Datasets

### Data Size Guidelines

| Data Size | Approach |
|---|---|
| <1,000 rows | Embed directly in HTML. Full interactivity. |
| 1,000 - 10,000 rows | Embed in HTML. May need to pre-aggregate for charts. |
| 10,000 - 100,000 rows | Pre-aggregate server-side. Embed only aggregated data. |
| >100,000 rows | Not suitable for client-side dashboard. Use a BI tool or paginate. |

### Pre-Aggregation Pattern

Instead of embedding raw data and aggregating in the browser:

```javascript
// DON'T: embed 50,000 raw rows
const RAW_DATA = [/* 50,000 rows */];

// DO: pre-aggregate before embedding
const CHART_DATA = {
    monthly_revenue: [
        { month: '2024-01', revenue: 150000, orders: 1200 },
        { month: '2024-02', revenue: 165000, orders: 1350 },
        // ... 12 rows instead of 50,000
    ],
    top_products: [
        { product: 'Widget A', revenue: 45000 },
        // ... 10 rows
    ],
    kpis: {
        total_revenue: 1980000,
        total_orders: 15600,
        avg_order_value: 127,
    }
};
```

### Chart Performance

- Limit line charts to <500 data points per series (downsample if needed)
- Limit bar charts to <50 categories
- For scatter plots, cap at 1,000 points (use sampling for larger datasets)
- Disable animations for dashboards with many charts: `animation: false` in Chart.js options
- Use `Chart.update('none')` instead of `Chart.update()` for filter-triggered updates

### DOM Performance

- Limit data tables to 100-200 visible rows. Add pagination for more.
- Use `requestAnimationFrame` for coordinated chart updates
- Avoid rebuilding the entire DOM on filter change -- update only changed elements

```javascript
// Efficient table pagination
function renderTablePage(data, page, pageSize = 50) {
    const start = page * pageSize;
    const end = Math.min(start + pageSize, data.length);
    const pageData = data.slice(start, end);
    // Render only pageData
    // Show pagination controls: "Showing 1-50 of 2,340"
}
```

## Examples

```
/build-dashboard Monthly sales dashboard with revenue trend, top products, and regional breakdown. Data is in the orders table.
```

```
/build-dashboard Here's our support ticket data [pastes CSV]. Build a dashboard showing volume by priority, response time trends, and resolution rates.
```

```
/build-dashboard Create a template executive dashboard for a SaaS company showing MRR, churn, new customers, and NPS. Use sample data.
```

## Tips

- Dashboards are fully self-contained HTML files -- share them with anyone by sending the file
- For real-time dashboards, consider connecting to a BI tool instead. These dashboards are point-in-time snapshots
- Request "dark mode" or "presentation mode" for different styling
- You can request a specific color scheme to match your brand$body$)
ON CONFLICT (skill_key) DO NOTHING;
