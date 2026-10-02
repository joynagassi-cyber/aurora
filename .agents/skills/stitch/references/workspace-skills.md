# Workspace Skills: Calibration and Prompt Engineering

Inspect, calibrate, create, and reset workspace skills via the API to steer autonomous research and assessment subagents in `/tmp/skills/` inside the Stitch Loop backend sandbox.

## 1. Inventory and Inspect Workspace Skills

List all skills in the target workspace with `stitch find skills --workspace=<workspaceId> --json` and inspect individual skill content with `stitch get skill insight-guidelines --workspace=<workspaceId> --json`.

- **Customizable (`isReadOnly: false`)**: `insight-guidelines`, `insight-workflow`, `assessment-guidelines`, `assessment-workflow`. These serve built-in system defaults (`isSystemDefault: true`, status `System Default`) until patched (`isSystemDefault: false`, status `Customized`).
- **Sealed (`isReadOnly: true`, status `Read-Only`)**: `system-overview`, `system-workflow`, `insight-protocol`, `assessment-protocol`, `investigation-report-guidelines`. Attempting to patch these returns HTTP 400.

## 2. Resolve Grounded Context and Route Mappings

Screen IDs change whenever baselines are re-extracted or uploaded, so do not hardcode numeric Stitch Canvas screen IDs in skill templates. Query active context records with `stitch find contexts --workspace=<workspaceId> --json` and extract:

1. **`codebase_architecture_ui`** (`routes[]`): maps each application route (such as `/chapters`, `/telemetry`, `/`) to its verified `referenceScreenId`.
2. **`loop_cli_manifest`** (or `stitch_manifest`): holds the fallback project ID (`stitch.projectId`) and primary desktop reference screen (`stitch.referenceScreen.id`).
3. **Priority objective fallback**: if contexts are absent, inspect the active priority objective via `stitch find priorities --workspace=<workspaceId> --json` for explicit screen references.

## 3. Calibrate Guidelines or Upsert a Custom Skill

See [skill-calibration.md](skill-calibration.md) to synchronize all three UI prototyping skills at once with `stitch create priority --template ui-prototyping --json`. For manual calibration:

- **Strategy A — Patch existing `insight-guidelines` (recommended)**: The backend copies `insight-guidelines` into `/tmp/skills/insight-guidelines.md` in every research agent's sandbox, so appending prompt synthesis rules there ensures insight discovery produces design prompts. Run `stitch edit skill insight-guidelines --workspace <workspaceId> --json '{"description":"Guidelines for insights with Stitch Canvas narrative design prompt synthesis.","content":"<FULL_AUGMENTED_GUIDELINES_CONTENT>"}'`.
- **Strategy B — Upsert a dedicated custom skill**: Create or update a modular custom skill by running `stitch create skill --workspace <workspaceId> --json '{"id":"stitch-design-prompt","description":"Synthesizes narrative Stitch Canvas design prompts for UI prototype solutions with dynamic screen resolution.","content":"<STITCH_DESIGN_PROMPT_CONTENT>"}'`.

### Canvas Prompt Specification

Calibrated instructions for UI design prompts should enforce this contract:

1. **Opening anchor**: begin with `"This is a targeted edit. Maintain this exact screen layout except for the following instructions."`
2. **Canvas baseline and screen ID header**: `[Canvas Baseline: {targetRoute} · Reference Screen ID: {resolvedScreenId}]`.
3. **Narrative intent and interaction flow**: frame the user journey, tactile controls, and atmospheric breathing room without prescribing DOM tags or component surgery.
4. **Token stripping**: omit raw hex color codes and font tokens from the prompt; `DESIGN.md` supplies ambient styling context.
5. **Desktop proportions**: target standard `1280x800` desktop canvas proportions with vertical breathing room.
6. **Inputs and outputs**: ground elements exclusively in authentic user inputs and outputs (document text, timelines, audio milestones), excluding internal engine plumbing.

## 4. Verify Live Ingestion and Reversibility

- Confirm the update succeeded and verify live status with `stitch get skill insight-guidelines --workspace=<workspaceId> --json` (`"isSystemDefault": false` and `"systemDefault": "workspaces/<workspaceId>/skills/insight-guidelines"`).
- Restore a customized skill to its built-in system default with `stitch api "workspaces/<workspaceId>/skills/insight-guidelines:reset" -X POST`.
