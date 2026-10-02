# Workspace Priorities, Autonomy Levels, and Insight Triage

Define ongoing workspace priorities with appropriate autonomy levels and triage the resulting insights.

## Workspace Priorities

A priority pairs an ongoing **objective** with an **autonomy level** (defaulting to `CREATE_SUGGESTIONS` if omitted):
- List workspace priorities: `stitch find priorities --json`
- List starter templates: `stitch create priority --templates`
- Create from a template: `stitch create priority --template ui-prototyping --json`
- Create with a custom objective: `stitch create priority --template ui-prototyping --objective="Evaluate visual rhythm and interactive surfaces across application routes (/feed, /schedule) to transform passive readouts into tactile direct-manipulation surfaces. Ground solutions in the 1280px desktop grid and primary reference screen, enforcing the Assessment Triad with zero decorative clutter." --json`

Use the `priority` or `priorities` resource name (`goal` is the wire name and fails with `VALIDATION_ERROR` on creation). Pass `--template <id>` or `--objective` (with optional `--description`) so creation runs non-interactively without waiting on stdin. Each registry template (such as `ui-prototyping` — *Scale Interactive Visual Prototyping*) declares its objective, autonomy level, and the remote workspace skills (`design-synthesis`, `insight-guidelines`, `assessment-guidelines`) that synchronize to the workspace when created.

### Defining Effective Objectives

Write durable, outcome-focused objectives that continue evaluating new material as the codebase evolves, rather than single closed tasks that finish after one pass:
- Prefer `"Evaluate visual rhythm across application routes to ensure mobile schedule views are glanceable and tactile"` over `"Fix table spacing"`.
- Prefer `"Transform booking readouts into direct-manipulation surfaces across /venues and /checkout"` over `"Add a map to /venues"`.
- Prefer `"Bring archive views up to standard of live views with authentic materiality"` over `"Add pagination to /results"`.

## Autonomy Levels

New workspaces default to `CREATE_SUGGESTIONS`; increase autonomy only after verifying suggestion quality:
- `CREATE_SUGGESTIONS`: generates insights and proposal assessments (default).
- `CREATE_ASSETS`: also creates candidate branches and PRs.
- `SUBMIT_ASSETS`: autonomously creates and submits assets.

## Insights and Triage

Insight generation runs asynchronously on the server and typically takes 15 minutes or longer without live CLI streaming. Once complete, inspect findings with `stitch find insights --json`, `stitch get insight <id> --json`, or `stitch api workspaces/{id}/insights`:
- State how many insights are pending triage and their priority distribution (`P1`, `P2`).
- Present top insights with clear titles, routes, and payoff explanations to guide solution selection.
