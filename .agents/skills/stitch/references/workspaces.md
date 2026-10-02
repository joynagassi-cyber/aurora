# Workspaces: Resolution, Pinning, and Traps

Reference for workspace resolution precedence, configuration persistence, automatic git-remote matching, listing guardrails, and repository attachment.

## Workspace Resolution Precedence

`stitch status --flow=loop --json` (`probeWorkspaceFacet` in `src/services/get/status/facets/index.ts`) and the resource verbs (`find`, `get`, `create`, `generate`, `edit` via `resolveAmbientWorkspace` in `src/cli/subcommands/find.ts`) resolve the active workspace in order (first hit wins):

1. Explicit `--workspace <id>` / `-w <id>` flag
2. `STITCH_WORKSPACE` environment variable
3. `./.stitch/manifest.json` -> `workspaceId`
4. `./.stitch.json` -> `workspace` (local)
5. `~/.stitch.json` -> `workspace` (global)
6. Automatic git-remote matching (`stitch status --flow=loop --json` only, when steps 1–5 are unset)

Bare `stitch status --json` (without `--flow`) does not resolve a workspace at all. If `.stitch/manifest.json` names one workspace and `.stitch.json` names another, `.stitch/manifest.json` wins—state that explicitly when the user expects the `.stitch.json` value.

## Writing and Pinning a Workspace

- One-command override (nothing written): `stitch status --flow=loop --workspace <id> --json` or `STITCH_WORKSPACE=<id> stitch status --flow=loop --json`
- Shell session override: `export STITCH_WORKSPACE=<id>`
- Write `.stitch.json` (or `~/.stitch.json` with `--global`): `stitch config set workspace <id>` (creates the file if missing and prints its path; `apiKey` is refused for local writes and requires `--global`)
- Bind project and workspace in `.stitch/manifest.json`: `stitch loop link --project <id> --workspace <id>`
- Interactive TUI picker (writes both `.stitch.json` and `.stitch/manifest.json`): `stitch loop` in a human terminal only; do not run interactive TUI sessions from an agent

## Automatic Git-Remote Matching

When steps 1–5 are unset, `probeWorkspaceFacet` queries all workspaces and tests each attached repository with `url.includes("${owner}/${name}") || url.endsWith("/${name}")`. Because `endsWith("/" + name)` is intentionally loose, it can match a same-named repository under a different owner:

- **No match, repo unknown to Loop**: `AWAITING_GITHUB_APP_INSTALL` (upload the codebase via `stitch upload code .`, or connect GitHub via `stitch github login` / `data.details.installUrl`).
- **No match, repo known or non-default workspaces exist**: `NEEDS_WORKSPACE_CREATION` (with `data.details.candidates` and `data.details.nonDefaultWorkspaces` when non-default workspaces exist).
- **Single match**: selected silently.
- **Multiple matches**: narrowed to dedicated workspaces via `matching.filter(ws => ws.isDefault === false && (ws.repositories?.length || 0) <= 5)` so personal default workspaces holding hundreds of repos do not swallow prototypes. A single dedicated match is selected silently; zero or multiple dedicated matches produce `AMBIGUOUS_WORKSPACE`.

The status payload does not distinguish an auto-matched workspace from one read out of `.stitch/manifest.json` or `.stitch.json`. Report which workspace is active and the evidence from the payload without claiming the user manually chose it.

## Listing Workspaces

- List non-default workspaces (default workspaces are excluded automatically): `stitch find workspaces --limit 10`
- Project minimal fields to avoid large payloads: `stitch find workspaces --fields id,displayName,repositories --limit 10 --json`
- Inspect a single workspace: `stitch get workspace <id> --json`
- Direct REST query: `stitch api workspaces --format json`

Each workspace record contains `id`, `displayName`, `description`, `organization`, `isDefault`, `repositories[]`, `users[]`, and timestamps. Because `description` can hold a full product-overview document (up to several megabytes across many workspaces), project `--fields id,displayName,repositories` when listing in JSON mode. There are no bare noun commands (`stitch find workspaces` and `stitch get workspace <id>` are the valid verb-first forms), and `stitch find workspaces` exits `1` with `Missing authentication` when logged out.

## Attaching a Repository or Borrowing a Workspace

- Attach or detach a repo (`--add-repo` and `--remove-repo` accept a URL, `owner/repo` shorthand, or repo ID; pass `--dryRun` to preview): `stitch edit workspace <id> --add-repo https://github.com/<owner>/<repo> --json`
- Borrowing a workspace created for another repo lands on `NEEDS_PRIORITY` or `NEEDS_MANIFEST` until you run `stitch create priority --template ui-prototyping --json` and `stitch loop link --project <project-id>`.
