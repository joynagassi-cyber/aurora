# Loop States

Reference for Loop diagnostic state evaluation (`src/services/get/state-machine.ts` and `src/services/get/status/flows/prototype.flow.ts`), status payload fields, recovery commands, and credential gates.

States are evaluated in order and the first match wins: a repository with no git remote reports `NOT_IN_GIT_REPO` regardless of downstream state, so always fix the reported state rather than an inferred one.

## Reading Status

- Evaluate the Loop flow: `stitch status --flow=loop --json` (adds `flow`, `step`, `totalSteps`, `parallelActions`)
- Evaluate the full FSM across all facets and flows: `stitch get status --json` or `stitch loop --json`
- Check sign-in, Canvas credential, and GitHub connection only (no flow state): `stitch status --json`

Always pass `--json` so a TTY does not launch the interactive Ink TUI. Successful calls return `{ "success": true, "data": { ... } }`; failures return `{ "success": false, "error": { "code", "message", "recoverable" } }` with exit code `1`.

`data` keys: `state`, `nextAction`, `workspaceId?`, `repo?` (`url`, `owner`, `name`, `branch?`), `stitch?` (`projectId`, `referenceScreenId?`, `deviceType`), `designMd?` (`valid`, `path`), `prototypes` (array), `details?`, `parallelActions?`, `facets` (`auth`, `repo`, `workspace`, `capture`, `design`, `synthesis`), `environment`, `flows`, `services`, and `nextStep`.

## States and Recovery Actions

- `NEEDS_LOOP_AUTH` (`nextAction: "AUTH_LOOP"`): no Loop credential and no stored OAuth session (`data.details.reason`, `data.details.missing`). Run `stitch login` or set `STITCH_API_KEY`.
- `LOOP_UNREACHABLE` (`nextAction: "RETRY_CONNECTION"`): workspaces probe failed for a non-auth reason (`data.details.reason`). Check connectivity and retry; re-authenticating will not help.
- `NEEDS_STITCH_AUTH` (`nextAction: "AUTH_STITCH"`): Canvas credential missing or rejected on post-priority checks; cleared automatically by unified Google OAuth via `stitch login` or `STITCH_API_KEY`.
- `STITCH_UNREACHABLE` (`nextAction: "RETRY_CONNECTION"`): Stitch Design API could not be reached (`data.details.reason`). Check connectivity and retry.
- `NOT_IN_GIT_REPO` (`nextAction: "INIT_GIT"`): no `.git` directory or no `remote.origin.url`. Run `git init` and `git remote add origin <url>`.
- `AWAITING_GITHUB_APP_INSTALL` (`nextAction: "INSTALL_GITHUB_APP"`): repository is invisible to Loop. Upload the local codebase with `stitch upload code .`, or connect GitHub with `stitch github login` (`data.details.installUrl`).
- `NEEDS_WORKSPACE_CREATION` (`nextAction: "CREATE_WORKSPACE"`): repository is known or other workspaces exist (`data.details.candidates`, `data.details.nonDefaultWorkspaces`), but no workspace is paired. Offer existing workspaces or create one, then run `stitch config set workspace <id>`.
- `AMBIGUOUS_WORKSPACE` (`nextAction: "SELECT_WORKSPACE"`): multiple candidate workspaces match (`data.details.candidates`). Pick one with the user, then run `stitch config set workspace <id>`.
- `NEEDS_MANIFEST` (`nextAction: "RUN_EXTRACT"`): no `.stitch/manifest.json`, missing `projectId`, or missing local snapshot. Capture a reference screen and run `stitch loop link --project <project-id>`.
- `NEEDS_DESIGN_MD` (`nextAction: "CREATE_DESIGN_MD"`): `DESIGN.md` is missing in the design or review flow. Follow [../flows/design.md](../flows/design.md) and upload with `stitch upload design DESIGN.md --json`.
- `NEEDS_PRIORITY` (`nextAction: "CREATE_PRIORITY"`): no active standing-order priority goal in the workspace. Run `stitch create priority --template ui-prototyping --json`.
- `SYNTHESIZING_PROTOTYPES` (`nextAction: "WAIT_FOR_PROTOTYPES"`): workspace and priority are wired and analysis is running (`data.details.synthesisInProgress`, `data.details.pollIntervalSeconds`), with zero prototypes synthesized yet. Wait and re-poll `stitch status --flow=loop --json`.
- `READY` (`nextAction: "SELECT_PROTOTYPE"`): prototypes are available in `data.prototypes`. Present them to the user.

## Credentials and Workspace Resolution

- **Loop credential**: gates `stitch status --flow=loop --json`. Satisfied by `STITCH_API_KEY`, `STITCH_ACCESS_TOKEN`, a `STITCH_API_KEY` or `LOOP_*` line in `./.env`, or a stored OAuth session from `stitch login` (`~/.stitch/credentials.json`, mode `0600`, auto-refreshed within 60s of expiry). Failures populate `data.details.reason`, plus `data.details.missing: true` when no credential was found. There is no `auth` subcommand; run `stitch status --json` to inspect the signed-in account.
- **Canvas credential**: satisfied by unified Google OAuth (`stitch login`) or `STITCH_API_KEY` from env or `./.env`. Missing it produces `NEEDS_STITCH_AUTH` (or `MISSING_CANVAS_CREDENTIALS` on direct Canvas commands).
- **Workspace resolution**: takes the first hit from `--workspace <id>` on `stitch status --flow=loop --json`, `STITCH_WORKSPACE`, `./.stitch/manifest.json`, `./.stitch.json`, `~/.stitch.json`, and finally live repository matching. See [workspaces.md](workspaces.md).
