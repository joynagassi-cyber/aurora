# Aurora — pnpm monorepo (Phase 1, release-candidate v0.1.0)

19 packages + 2 apps + `supabase/` + `powersync/`. **Status: waves 0→7 delivered, v0.1.0 RC.** The full project map + decision index live in [AI_RULES.md](AI_RULES.md); the live release history in [docs/release/changelog.md](docs/release/changelog.md).

| Package | Role |
|---|---|
| `packages/domain` | SSoT of frozen domain types (AD-15): envelopes, CRDT, 40+ entities, 9 events, 14 ports, AI-pipeline + 7 registries. Imports nothing |
| `packages/data` | PowerSync/SQLite repos + sync engine, migrations, views/scopes, Model Registry (AD-16b), React-Query bridge |
| `packages/ui` | Design System, tokens, components, AD-10 renderers (engines live only here), themes JSON SSoT (AD-17) |
| `packages/platform` | Capacitor adapters behind interfaces (04 S3.2); the only native surface (AD-16c) |
| `packages/agent` | Agent Kernel + capabilities (AD-12) + the Vercel AI SDK layer; device sees only AgentRunState (F-09) |
| `packages/productivity` `learning` `goal-engine` `progress` `discovery` `focus` | Vertical feature domains — tasks·habits·focus · FSRS·QCM·mirror · dynamic goals · progress (F-07 sole producer) · discovery feed · Focus DPC port SSoT |
| `packages/ascent` | Slide-Ascent pedagogical trajectory engine (W3-E2) |
| `packages/workflows` | The 23 composite workflows + AD-9 event-flow + error recovery + self-improvement |
| `packages/scientific-engine` | Generic math/units engine + LaTeX behind the ScientificEngine port (AD-10) |
| `packages/engineering-{core,solvers,adapters,registry}` | Internal decomposition of scientific-engine (IR/units, solvers, swappable adapters, catalog); types SSoT stay in domain (AD-15) |
| `packages/integrations` | Composio (IntegrationProvider), notification adapters |
| `apps/mobile` | Ionic React + Capacitor shell + all screens (Phase 1, Android-only) |
| `apps/server` | Supabase Edge Functions + Cloudflare Workers (server-side kernel/AI, jobs) |

## Commands

```bash
pnpm install      # install all workspace deps
pnpm typecheck    # tsc -b (project references, strict, noUncheckedIndexedAccess)
pnpm lint         # eslint (boundary rules added in wave0/achilles commit 3)
```

## CI gate

All three must pass from a clean checkout (wave 0 acceptance, CI-ready):

```bash
pnpm install     # 1. install workspace + ESLint tooling
pnpm typecheck   # 2. tsc -b --noEmit across all 19 packages + 2 apps
pnpm lint        # 3. eslint boundary rules (AD-1/AD-10/AD-15) on every package
```

The `main` gate also runs the boundary/RLS/view-join + spine greps + the node-native tests — the full, ordered command list is in [AI_RULES.md §9 "Run the gate"](AI_RULES.md#9-run-the-gate-how-to-verify-before-you-finish) and `docs/ci/gate.md`.

Note: `allowBuilds` + `minimumReleaseAge` blocks in `pnpm-workspace.yaml` are pre-existing — do not break them.
