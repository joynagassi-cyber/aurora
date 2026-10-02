# Flow Playbook: Prototype Onboarding (`prototype`)

Onboard a repository to Stitch Loop by pairing a workspace, capturing and uploading live application views to Stitch Canvas, syncing `DESIGN.md`, and setting a standing-order priority for prototype synthesis.

## 1. Evaluate Flow State and Environment Facets

Run `stitch status --flow=loop --json` first (bare `stitch status --json` reports only sign-in, Canvas credential, and GitHub connection, not flow state). The response envelope `{ success, data }` exposes `data.flow`, `data.state`, `data.step`, `data.totalSteps`, `data.nextAction`, `data.details`, `data.parallelActions`, `data.prototypes`, and `data.facets` (`auth`, `repo`, `workspace`, `capture`, `design`, `synthesis`) probed together without waterfall hiding:

- `NEEDS_LOOP_AUTH` (step 1, `nextAction: "AUTH_LOOP"`): missing or rejected Loop credentials (`data.details.reason`, `data.details.missing`). Run `stitch login` (see Step 1).
- `LOOP_UNREACHABLE` (step 1, `nextAction: "RETRY_CONNECTION"`): Loop backend connection failed (`data.details.reason`), not an auth problem. Report the failure and offer a retry.
- `NOT_IN_GIT_REPO` (step 2, `nextAction: "INIT_GIT"`): folder has no `.git` or `remote.origin.url`. Run `git init` and add a GitHub `origin` remote.
- `AWAITING_GITHUB_APP_INSTALL` (step 2, `nextAction: "INSTALL_GITHUB_APP"`): codebase is not connected to Loop. Upload the local codebase with `stitch upload code .`, or connect GitHub with `stitch github login` (`data.details.installUrl`) for automated PRs (see Step 2).
- `NEEDS_WORKSPACE_CREATION` (step 2, `nextAction: "CREATE_WORKSPACE"`): no workspace is paired (`data.details.candidates`, `data.details.nonDefaultWorkspaces`). Offer existing workspaces or create one (see Step 2).
- `AMBIGUOUS_WORKSPACE` (step 2, `nextAction: "SELECT_WORKSPACE"`): multiple candidate workspaces match in `data.details.candidates` (`{ id, displayName, repos }`). Disambiguate with the user and bind via `stitch config set workspace <workspace-id>` (see Step 2).
- `NEEDS_MANIFEST` (`stitch get status --json` or `--flow=design`, `nextAction: "RUN_EXTRACT"`): `!data.facets.capture.hasSnapshot` or `!data.facets.design.hasManifest`. Capture and upload core application views and link the Canvas project (see Step 3).
- `NEEDS_DESIGN_MD` (`--flow=design`, `nextAction: "CREATE_DESIGN_MD"`): project is linked, but `DESIGN.md` is missing locally. Extract tokens via [../references/design-md.md](../references/design-md.md) and sync via [design.md](design.md).
- `NEEDS_PRIORITY` (step 3, `nextAction: "CREATE_PRIORITY"`): `data.facets.synthesis.hasPriority` is `false`. If `data.facets.capture.hasSnapshot` or `data.facets.design.hasManifest` is false, finish Step 3 first, then create the standing-order priority (see Step 5).
- `SYNTHESIZING_PROTOTYPES` (step 4, `nextAction: "WAIT_FOR_PROTOTYPES"`): `data.facets.synthesis.status` is `SYNTHESIZING` or `data.facets.synthesis.prototypesCount` is `0` (`data.details.synthesisInProgress`, `data.details.pollIntervalSeconds`). Verify multi-route Canvas coverage and priority configuration while synthesis runs (see Step 4).
- `READY` (step 4, `nextAction: "SELECT_PROTOTYPE"`): proposed solutions are available in `data.prototypes` (`{ id, title, summary, recommendedRank, taskCreated }`). Present the proposals and generate approved screens (see Step 4), then ensure a priority is set in Step 5.

### Parallel Track Execution (`data.parallelActions`)

When `!data.facets.design.hasManifest`, `!data.facets.capture.hasSnapshot`, and `data.facets.capture.devServerUrl` is non-empty, `data.parallelActions` pairs `{ track: "background", action: "RUN_CAPTURE", details: { devServerUrl } }` with `{ track: "interactive", action: "AUTH_LOOP" | "CREATE_WORKSPACE" | "SELECT_WORKSPACE" }`. Because `data.facets.capture` and `data.facets.design` are already evaluated during Step 1 and Step 2 states, start route discovery and primary snapshot capture (`stitch capture browser --url "<devServerUrl>/<route>" -o .stitch/captured-dom.html --json`) in the background while resolving sign-in or workspace selection with the user. See [../references/loop-states.md](../references/loop-states.md) for full state and credential details.

### Session Orientation

On the first turn of a session, orient the user with the flow goal (connecting the repository, capturing live routes and `DESIGN.md` onto Stitch Canvas, and synthesizing UI prototypes), what `stitch status --flow=loop --json` confirmed is already configured (account, git remote, active workspace, or detected `data.facets.capture.devServerUrl`), and the concrete next action.

## Step 1 - Sign In

Unified Google OAuth via `stitch login` opens a browser tab (PKCE) and saves credentials to `~/.stitch/credentials.json` for both Loop and Canvas (`STITCH_API_KEY` in `./.env` or environment variables remains supported for headless CI or service accounts). Inform the user before running `stitch login` that it opens a browser tab, or run `stitch status --json` when you need account details, token expiry, or GitHub connection status.

## Step 2 - Pair Workspace and Connect Codebase

Whenever `data.workspaceId` or `data.facets.workspace.workspaceId` is set, state the workspace name and tracked repository (`data.facets.repo.owner`/`data.facets.repo.name`).

- `AMBIGUOUS_WORKSPACE`: list `data.details.candidates` by display name and repository count without bare UUIDs, recommend the workspace dedicated to this repository, and bind the user's choice with `stitch config set workspace <workspace-id>`.
- `AWAITING_GITHUB_APP_INSTALL`: recommend uploading the local codebase directly with `stitch upload code .` (no GitHub OAuth or repo permissions needed), or offer `stitch github login` (`data.details.installUrl`) only if the user wants automated GitHub pull requests.
- `NEEDS_WORKSPACE_CREATION`: offer both creating a dedicated workspace (`stitch create workspace --json '{"displayName":"<name>"}'`) and selecting an existing workspace from `data.details.candidates` or `stitch find workspaces --limit 10`. Pin the chosen workspace with `stitch config set workspace <workspace-id>` or bind both project and workspace in Step 3 with `stitch loop link --project <project-id>`. See [../references/workspaces.md](../references/workspaces.md) for precedence rules and pinning options.

## Step 3 - Capture App Views, Link Canvas Project, and Sync `DESIGN.md`

Onboarding places the application's 3–5 core views onto a Stitch Canvas project as real captured snapshots so generated prototypes match the live UI structure and styling. Capture real views with `stitch capture` and upload them with `stitch upload screen`; do not call `stitch generate screen` during onboarding, and do not edit files in `src/` to bypass login screens.

1. **Discover and capture core views**: Inspect router definitions and navigation components in `src/` to identify the 3–5 primary user-facing views (URL paths, hash routes, or in-memory tab states). Using `data.facets.capture.devServerUrl`, capture the primary reference view (`stitch capture browser --url "http://localhost:PORT/PRIMARY_ROUTE" -o .stitch/captured-dom.html --json`), verify `.stitch/verify-capture.png`, and handle any auth gates or in-memory state navigation with `chrome-devtools` and `stitch capture browser --page 1 -o .stitch/captured-dom.html --json` following [../references/capture-screens.md](../references/capture-screens.md).
2. **Link the Canvas project and sync `DESIGN.md`**: After the user approves the primary snapshot, bind the Stitch Canvas project to the workspace manifest with `stitch loop link --project <project-id>`. If `data.facets.design.hasDesignMd` is `false` or needs refreshing, extract `DESIGN.md` from source code following [../references/design-md.md](../references/design-md.md), then validate and upload it with `stitch upload design DESIGN.md --json` following [design.md](design.md).
3. **Upload all remaining core views**: Capture each remaining route or in-memory view following [../references/capture-screens.md](../references/capture-screens.md), upload each snapshot with `stitch upload screen .stitch/<view>.html --project <project-id> --route "<route>" --title "<View Title>" --json` following [../references/upload.md](../references/upload.md), and confirm all views are on Canvas with `stitch find screens --project <project-id> --json`.

## Step 4 - Review Synthesized Prototypes and Generate Screens

- **When `data.state` is `SYNTHESIZING_PROTOTYPES`**: Check `.stitch/manifest.json` for `stitch.projectId` and run `stitch find screens --project <project-id> --json`. If the project has only 1–2 screens while the codebase has additional core views, complete Step 3 first so every core view is on Canvas. Once all core views are uploaded, explain that background synthesis is analyzing the repository (typically 15+ minutes) and guide the user to Step 5 to review or create workspace priorities while waiting. Do not fabricate or call `stitch generate screen` from local code or `DESIGN.md` while `data.prototypes` is empty.
- **When `data.state` is `READY`**: Present the proposed solutions from `data.prototypes` (`id`, `title`, `summary`, `recommendedRank`, `taskCreated`, or fetch full specifications with `stitch get solution <id> --json`) as concise two-line cards. When the user approves a proposal from `data.prototypes`, pass the calibrated Canvas prompt from its specification (`specs/*.md`, opening with `This is a targeted edit. Maintain this exact screen layout except for the following instructions. [Canvas Reference: ... Reference Screen ID: ...]`) directly to `stitch generate screen --project <project-id> --title "<Solution Title>" --device DESKTOP --prompt "<prompt from solution>"` without inventing ad-hoc prompts.

## Step 5 - Configure Standing-Order Priority

Establish the workspace's standing-order priority from the Priority Template Registry, offering `ui-prototyping` (`Scale Interactive Visual Prototyping`) as the recommended option alongside a custom focus:

- **Recommended template**: Run `stitch create priority --template ui-prototyping --json` to create the `Scale Interactive Visual Prototyping` priority with `CREATE_SUGGESTIONS` autonomy and synchronize the template's registered workspace skills (`design-synthesis`, `insight-guidelines`, `assessment-guidelines`) for the Assessment Triad (`seed.json`, `DESIGN.md`, narrative Canvas prompt).
- **Custom objective**: If the user asks for a custom aesthetic or interaction objective, run `stitch create priority --template ui-prototyping --objective "<Custom Objective>" --json` (with optional `--description`) so the `ui-prototyping` workspace skills still synchronize.
- **Inspect templates or priorities**: List starter templates with `stitch create priority --templates` or existing workspace priorities with `stitch find priorities --json`. See [../references/priorities-and-insights.md](../references/priorities-and-insights.md) and [../references/skill-calibration.md](../references/skill-calibration.md).
