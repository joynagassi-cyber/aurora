# Product Q&A and Workspace Queries

Answer product questions and act on workspace data by querying and updating priorities, insights, solutions, and contexts.

Resolve or pin the active workspace first following [workspaces.md](workspaces.md) (`stitch find workspaces --limit 10`, `stitch config set workspace <workspace-id>`, or `-w <workspace-id>`), and see [../SKILL.md](../SKILL.md) for global CLI rules.

## Data Model and Resource Fields

- **Priority**: product objective driving the analysis pipeline (`id`, `objective`, `description`, `autonomyLevel`).
- **Insight**: product problem or opportunity surfaced by analysis (`id`, `title`, `state`, `priority`, `severity`, `prevalence`, `confidence`, `altitude`, `userSignal`, `gapNature`, `priorities`).
- **Solution**: proposal or mini-PRD addressing an insight (`id`, `title`, `insights`, `spec.summary` TL;DR, `spec.specMarkdown` full PRD).
- **Context**: structured data attached to a workspace (`id`, `data`, `dataSource`, `description`; `data` is a JSON object or valid JSON string up to 10 MB).

## Workflows

### Querying Product Data

1. Fetch a compact insight overview with `stitch find insights --fields id,title,state,priority,severity` (or stream large sets one JSON object per line with `stitch find insights --format ndjson --fields id,title,state,priority`).
2. Identify high-priority items (`P0`/`P1`, `S0`/`S1`) and inspect details with `stitch get insight <insight-id>`, or dismiss irrelevant findings with `stitch dismiss insight <insight-id>`.
3. List related solutions without pulling heavy `specMarkdown` (`3-6KB` each) using `stitch find solutions --insight <insight-id> --fields id,title` (or `stitch find solutions --fields id,title`), then fetch a specific full spec with `stitch get solution <solution-id> --json`.

### Managing Priorities

1. Inspect current priorities (`stitch find priorities --fields id,objective,autonomyLevel` or `stitch get priority <priority-id>`) and existing insights (`stitch find insights --fields id,title,state,priority`).
2. Iterate on phrasing with the user and confirm the final objective and description before creating.
3. Preview with `stitch create priority --objective "<obj>" --description "<desc>" --dryRun`, then create with `stitch create priority --objective "<obj>" --description "<desc>"`.
4. Remove obsolete priorities with `stitch delete priority --id <priority-id>`.

### Generating Solutions

1. Inspect the target insight with `stitch get insight <insight-id>`.
2. Preview with `stitch generate solutions --insight <insight-id> --dryRun`, then run `stitch generate solutions --insight <insight-id>`.
3. Review results with `stitch find solutions --insight <insight-id> --fields id,title` and `stitch get solution <solution-id> --json`.

### Managing Contexts and Workspaces

- List contexts with `stitch find contexts`, preview creation with `stitch create context --json '{"data":{},"dataSource":"<source>","description":"<desc>"}' --dryRun`, create with `stitch create context --json '{"data":{},"dataSource":"<source>","description":"<desc>"}'`, and delete with `stitch delete context --id <context-id>`.
- Inspect a workspace with `stitch get workspace <workspace-id>` or bind a repository with `stitch edit workspace <workspace-id> --add-repo https://github.com/org/repo`.

## Query Rules, Presentation, and Gotchas

- Run one query per user request rather than chaining insight and solution lookups unless the user asks for both. Pass `--debug` on errors to inspect stack traces.
- On read commands (`stitch find` and `stitch get`), bare `--json` only switches output format to JSON; on write commands, `--json '{...}'` supplies the mutation payload.
- Use only resource IDs returned by `stitch find` commands, since IDs are validated against path traversal and injection.
- Write results to an artifact with feedback requested and describe actions in plain language without exposing CLI commands, API paths, or internal flags: group insights by theme or altitude (highlighting `P0`/`P1` and `S0`/`S1`), lead solutions with `spec.summary` and key requirements from `spec.specMarkdown`, and display each priority's objective, description, and autonomy level.