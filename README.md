# Aurora — pnpm monorepo (wave 0)

14 packages + 2 apps. Layout = spine Structural Seed + OQ-01 ratified (docs/architecture/00-overview.md S3).

| Package | Role |
|---|---|
| `packages/domain` | SSoT of frozen domain types (AD-15): entities, events, ports, envelopes. Imports nothing |
| `packages/data` | PowerSync/SQLite, migrations, views/scopes, Model Registry (AD-16b), React-Query bridge |
| `packages/ui` | Design System, tokens, components, AD-10 renderers (engines live only here), themes JSON SSoT (AD-17) |
| `packages/platform` | Capacitor adapters behind interfaces (04 S3.2); the only native surface (AD-16c) |
| `packages/agent` | Agent Kernel + capabilities (AD-12); device sees only AgentRunState (F-09) |
| `packages/scientific-engine` | Generic math/units engine + LaTeX behind the ScientificEngine port (AD-10) |
| `packages/integrations` | Composio (IntegrationProvider), notification adapters |
| `packages/engineering-{core,solvers,adapters,registry}` | Internal decomposition of scientific-engine (IR/units, solvers, swappable adapters, catalog); types SSoT stay in domain (AD-15) |
| `apps/mobile` | Ionic React + Capacitor shell + vertical feature slices (Phase 1, Android-only) |
| `apps/server` | Supabase Edge Functions + Cloudflare Workers (server-side kernel/AI, jobs) |

## Commands

```bash
pnpm install      # install all workspace deps
pnpm typecheck    # tsc -b (project references, strict, noUncheckedIndexedAccess)
pnpm lint         # eslint (boundary rules added in wave0/achilles commit 3)
```

Note: `allowBuilds` + `minimumReleaseAge` blocks in `pnpm-workspace.yaml` are pre-existing — do not break them.
