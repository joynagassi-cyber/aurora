---
name: stitch
description: >-
  Use when the user invokes /stitch, onboards a repo to Stitch Loop, turns an
  existing app into Stitch designs, captures or uploads screens, generates or
  edits screens, extracts or reviews DESIGN.md, manages design systems, or works
  with Loop workspaces, priorities, insights, solutions, workspace skills,
  connections, or the wiki. Also use to find the biggest-impact or quickest
  solution, prove a finding, or answer product questions.
---

# Stitch

This skill is the single entry point for Stitch Canvas design work and Stitch Loop workspaces. Route the user's request to the matching workflow or reference below, and run the `stitch` CLI directly for every action. Check `stitch status --flow=loop --json` (or `--flow=design`) first when workspace, repository, dev server, or project state matters.

## Route by intent

- Onboard a repository or set up Stitch Loop from scratch: [flows/prototype.md](flows/prototype.md)
- Bring an existing app into a Canvas project with no workspace: [references/code-to-design.md](references/code-to-design.md)
- Discover routes or capture HTML snapshots from a dev server, browser, or built file: [references/capture-screens.md](references/capture-screens.md)
- Upload captured HTML, images, or `DESIGN.md` to a Stitch project: [references/upload.md](references/upload.md)
- Extract a `DESIGN.md` specification from existing frontend code: [references/design-md.md](references/design-md.md)
- Author, validate, or sync `DESIGN.md` with the design flow state machine: [flows/design.md](flows/design.md)
- List, inspect, create, update, or apply Stitch design systems: [references/design-system.md](references/design-system.md)
- Generate new screens, explore variants, or edit existing screens on Stitch Canvas: [references/generate-screens.md](references/generate-screens.md)
- Enhance a rough UI prompt with design vocabulary and style terms: [references/prompt-keywords.md](references/prompt-keywords.md)
- Map product types, component patterns, and layouts before generating screens: [references/design-mappings.md](references/design-mappings.md)
- Review a running local app against `DESIGN.md` using a captured snapshot: [flows/review.md](flows/review.md)
- Recover from a Loop onboarding state: [references/loop-states.md](references/loop-states.md)
- Pick, pin, or resolve a workspace: [references/workspaces.md](references/workspaces.md)
- Set up a workspace, write priorities, and act on insights (Orient, Focus, Understand, Act, Refine): [references/workflow.md](references/workflow.md)
- Set priorities, autonomy levels, or triage insights: [references/priorities-and-insights.md](references/priorities-and-insights.md)
- Find the one root-cause solution that makes other work unnecessary: [references/biggest-impact.md](references/biggest-impact.md)
- Find the quickest, lowest-risk solution to ship first: [references/low-hanging-fruit.md](references/low-hanging-fruit.md)
- Prove or disprove a finding, bug, or insight with evidence: [references/prove-finding.md](references/prove-finding.md)
- Answer product questions from insights, solutions, and context: [references/chat.md](references/chat.md)
- Explore or report on a workspace as a directory tree: [references/narrative.md](references/narrative.md)
- Inspect, patch, create, or reset workspace skills: [references/workspace-skills.md](references/workspace-skills.md)
- Calibrate workspace skills for UI prototyping: [references/skill-calibration.md](references/skill-calibration.md)
- Connect GitHub, Slack, or other tools to a workspace: [references/connections.md](references/connections.md)
- Run a specific command or explore the CLI: `stitch --help`, `stitch <command> --help`, `stitch <command> <resource> --schema`

## Operational rules

- **Check flow state first**: `stitch status --flow=loop --json` (pass `--workspace <id>` to pin a workspace) and `stitch status --flow=design --json` evaluate the onboarding and design state machines (`data.flow`, `data.step`, `data.totalSteps`, `data.state`, `data.nextAction`, `data.facets.capture.devServerUrl`, `data.facets.design`). Bare `stitch status --json` checks sign-in and `canvas.present` only and returns no flow state.
- **Call the CLI directly**: Never call the Stitch MCP server; execute the `stitch` CLI binary directly.
- **Capture rather than generate when importing code**: When turning an existing app into Stitch designs or onboarding a repo, capture real views with `stitch capture` and upload them with `stitch upload screen`. Never call `stitch generate screen` during code import or onboarding.
- **Keep the repository clean during capture**: Never edit files in `src/` to bypass login screens or write capture scripts into the repo. `stitch capture browser --url="http://localhost:PORT/ROUTE" -o .stitch/captured-dom.html --json` also writes `.stitch/verify-capture.png` and never uploads automatically. If an auth gate or modal blocks the view, drive the live tab with `chrome-devtools` (`take_snapshot`, `click`, `fill`, `navigate`) and re-run `stitch capture browser --page 1 -o .stitch/captured-dom.html --json` to capture without reloading.
- **Pause before binding or batch uploads**: Confirm with the user before binding a project (`stitch config set project <project-id>`), binding a workspace (`stitch config set workspace <workspace-id>`), or uploading a batch of screens.
- **Guard workspace queries against context bloat**: Raw workspace descriptions can exceed 2.5 MB. Run `stitch find workspaces --limit 10` for summaries, or pass `stitch find workspaces --fields id,displayName,repositories --limit 10 --json` when JSON is needed.
- **Seed priorities from templates**: `stitch create priority --template <id>` (for example `--template ui-prototyping`) creates a standing order from the template registry and syncs its workspace skills (`design-synthesis`, `insight-guidelines`, `assessment-guidelines`).
- **Resolve URLs via the CLI**: Print links with `stitch url project <project-id>` or `stitch url screen <screen-id> --project <project-id>` rather than constructing Canvas URLs by hand.
