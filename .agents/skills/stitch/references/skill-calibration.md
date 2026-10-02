# Workspace Skill Calibration

Synchronize and calibrate workspace skills when Loop returns generic engineering findings (build scripts, schema drift, dependency audits) instead of UI prototype work.

## Automatic Skill Synchronization via Template Registry

In the Priority Template & Skill Registry, each priority template (such as `ui-prototyping`) declares its associated workspace skills (`design-synthesis`, `insight-guidelines`, `assessment-guidelines`) and synchronizes them automatically when the priority is created.

- Create the UI prototyping standing order and synchronize all three skills in one command: `stitch create priority --template ui-prototyping --json`.
- Customize the objective while still synchronizing the template's registered skills: `stitch create priority --template ui-prototyping --objective="..." --json`.

## Why All Three Skills Are Required

Loop's research orchestrators run in a sandbox and delegate by phase: insight discovery reads `/tmp/skills/insight-guidelines.md`, and assessment synthesis reads `/tmp/skills/assessment-guidelines.md`. Adding `design-synthesis` on its own leaves both subagents on generic software friction defaults, so calibrate all three together:

- `design-synthesis` (architectural ontology): enforces the physical artifact, the human gesture, craft-neutral materiality, and anti-pollution limits.
- `insight-guidelines` (discovery mandate): diagnoses passive detachment rather than code friction and anchors every insight to a real route.
- `assessment-guidelines` (assessment triad): ensures every solution doc carries a domain seed, a design system, and a narrative canvas prompt.

## Inspecting, Patching, and Reverting

- Inspect each skill: `stitch get skill insight-guidelines --workspace WORKSPACE_ID --json`, `stitch get skill assessment-guidelines --workspace WORKSPACE_ID --json`, and `stitch get skill design-synthesis --workspace WORKSPACE_ID --json`.
- Patch built-in guideline skills (`insight-guidelines`, `assessment-guidelines`) with `stitch edit skill insight-guidelines --workspace WORKSPACE_ID --json '{"description":"...","content":"..."}'`, or upsert `design-synthesis` with `stitch create skill --workspace WORKSPACE_ID --json '{"id":"design-synthesis","description":"...","content":"..."}'` (see [workspace-skills.md](workspace-skills.md)).
- Revert a customized skill to its system default: `stitch api "workspaces/WORKSPACE_ID/skills/SKILL_ID:reset" -X POST`.

## The Assessment Triad

Each solution document produced under a calibrated `assessment-guidelines` contains three parts:

1. **Domain seed**: domain name, physical metaphor, primary gesture, and entities with natural units.
2. **Design system**: materiality, authentic surfaces, type hierarchy, and anti-clutter invariants (no fake HUD slashes, no status dots, no redundant labels).
3. **Canvas prompt**: prompt opening with the targeted edit anchor (`This is a targeted edit...`).
