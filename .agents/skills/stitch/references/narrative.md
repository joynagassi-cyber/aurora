# Workspace Wiki (Narrative View)

Generate a local markdown directory tree of a Stitch Loop workspace with `stitch wiki` so you can browse and report on priorities, insights, and solutions from disk.

## Views

- `natural` (alias `tree`): hierarchical tree (`priorities > insights > solutions`) for exploring how workspace resources relate.
- `by-priority`: groups insights by priority (`P0`–`P3`) for triage and prioritization.
- `default`: flat layout grouped by resource type for quick lookups.

## Commands

- Generate with the default layout: `stitch wiki generate` (pass `-w <id>` to override the active workspace).
- Generate with a specific layout: `stitch wiki generate --view natural` or `stitch wiki generate --view by-priority`.
- Include dismissed insights or archived priorities by passing `--include-dismissed` or `--include-inactive`, and override the output directory with `-o <dir>` (`--output-dir <dir>`).
- Auto-sync on workspace changes: `stitch wiki watch --view natural` (supports `--interval <seconds>` and `--clean-on-exit`).
- Remove generated wiki files: `stitch wiki clean`.

## Output Structure and Reading

All views write read-only markdown files under `.stitch/wiki/` (or `-o <dir>`) alongside a `.stitch-wiki` metadata marker. Do not edit generated files directly.

- Read `.stitch/wiki/README.md` for the workspace overview.
- In `natural` view, files nest under `.stitch/wiki/priorities/{priority-slug}/priority.md`, `.../insights/{insight-slug}/insight.md`, and `.../solutions/{solution-slug}/solution.md`.
- In `by-priority` view, read insights by priority bucket such as `.stitch/wiki/P0/*.md`.
