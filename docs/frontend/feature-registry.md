# Feature Registry, Flags & Module Activation (G-M7 — NEEDS_DECISION, wave 0)

Status: **design specified, decision pending** (master mission §13/§14/§15/§16/§17).
The V1 packs never defined a feature-activation framework; this page is the
prescriptive design (additive; types in `packages/domain` per AD-15; owner
Foundation + App Shell — to ratify at wave 0). Rule: **Aurora must grow and shrink
without breaking; a disabled feature disappears from the surface, its data stays.**

## 1. FeatureDescriptor (mission §14, SSoT `packages/domain`)

```ts
interface FeatureDescriptor {
  id: string;                       // e.g. 'learning', 'discovery', 'focus', 'advanced-analytics', 'audio-transcription'
  enabled: boolean;                 // on/off (module works, contributes to flows)
  visible: boolean;                 // shown in nav/surface (a feature can be enabled-but-hidden)
  routes: string[];                 // route prefixes it owns (02 §6.1 map)
  capabilities: string[];           // agent capability ids it exposes (docs/agent/feature-agentability-matrix.md)
  dependencies: string[];           // feature ids required (transitive, validated at activation)
  optional: boolean;                // product may hide it without breaking the core
  state: 'available' | 'recommended' | 'locked' | 'deprecated';  // registry state, distinct from enabled
  offlineClass: 'offline-capable' | 'online-required' | 'hybrid'; // master mission §19
}
```

Registry states (mission §13): **Feature Enabled / Disabled / Hidden / Available /
Locked / Recommended / Deprecated** — `enabled` (works) × `visible` (shown) ×
`state` (lifecycle) compose; a `deprecated` feature still renders + stores data,
marked out of the surface planning.

## 2. The chain (mission §13 architecture)

```
Feature Registry (SSoT packages/domain + seed in UserContext preferences)
  ↓
Availability Policy (activation = enabled ∧ dependencies satisfied ∧ platform
     capability present (e.g. DPC for focus.block, OQ-17) ∧ provider present when
     online-required (AD-1 graceful degradation))
  ↓
Navigation Registry (tabs/routes visible: 02 §6.1)  →
Screen Registry (05 §4 inventory: hidden screens drop from the inventory render)  →
Agent Capability Registry (only the capabilities of available features are
     discoverable by the kernel — docs/agent/kernel.md §8)
```

Deactivation effect (must ALL hold, mission §13): a hidden feature disappears from
**navigation, shortcuts, command palette, agent capabilities, widgets (Home slots),
dashboards, suggestions** — but **historical data is never touched** (AD-15 tables
stay; reports keep their past data; re-enabling restores the surface instantly, no
migration).

## 3. Horeb adaptation — generic, never `if user === Horeb` (mission §15/§16)

```
Aurora Core + User Capability Profile (UserContext, AD-15 SSoT) + Enabled Capabilities
     + Preferences + Context (period type: exam/regular — a declared context, not a
     hardcoded user check)
        ↓
   Adaptive UI (tabs order/weight, Home slot emphasis, suggestions)
```

- An exam period **declared in the profile** surfaces Learning/Progress/Focus/
  Calendar and minimizes Discovery/Projects/Analytics (rendering + suggestion
  weighting, NOT deletion); the agent receives the same profile (its Context form,
  AD-12) and a disabled capability is **out of its discoverable surface** (kernel §8).
- The UI stays generic: every rule is data-driven (profile + registry +
  preferences); no user-name checks anywhere (review finding if found, 02 §11).

## 4. Command palette & global actions (mission §17)

One capability, **five entry points, zero duplicated business logic**: UI button ·
command palette · agent NL trigger · deep link · automation (Integrations, Cron →
jobs) all resolve to the **same use-case / capability** (02 §4: use-cases are the
orchestration layer; the palette renders a command list *from the capability
registry*, filtering on availability + permissions). Examples: "Créer une tâche" =
`task.create`; "Ouvrir Focus" = `focus.start`; "Rechercher un cours" =
`course.search`; "Créer une fiche" = `learning.sheet.generate`; "Analyser Progress"
= `progress.analyze`; "Lancer une recherche" = `discovery.research`. Deep links and
agent triggers carry the same params as palette commands (context-preserving
navigation, 02 §6 / mobile docs).

## 5. Interaction with known gaps

- G-M7 = this page (ratify wave 0; additive — no AD touched).
- Provider-absent degradation (AD-1 last paragraph, 01 §6) = the availability
  policy's provider check (OCR/transcription/research absent → feature states
  degrade, product keeps working).
- Theme local adaptation (OQ-15, V1 = Focus only) composes with the registry
  independently (theme ≠ feature).
- Agent surface: `capabilities[]` of each descriptor feed the kernel's Capability
  Registry (docs/agent/kernel.md §8) — the kernel **discovers** capabilities, never
  hardcodes a growing condition list (mission §8).

## 6. Module deactivation — the full effect (mission §54, and §70 "supprimer")

When a feature `F` is disabled (registry `enabled=false`), ALL of the following
happen automatically, and **none of them deletes data**:

| Effect | Mechanism |
|---|---|
| navigation removed | Navigation Registry renders only enabled features' entries (02 §6.1 routes stay defined; the guard = registry, not deletion) |
| shortcut removed | Home AD-14 slots + tab shortcuts filter on `visible ∧ enabled` (the AD-14 invariant re-resolves its composition over enabled slots — "Priorité/Prochaine action" survive, feature-specific slots fade) |
| agent capability removed | Capability Registry drops `F`'s capability ids (kernel §14: the agent discovers what is enabled — it never plans a disabled feature) |
| dashboard widget hidden | G2 dashboards (Progress/Analytics) filter series by enabled features; historical data still renders (charts keep past points, marker "feature off") |
| scheduled jobs paused | `job_queue` kinds owned by `F` stop being *created* (the Cron entries are registry-driven); already-pending jobs finish or are cancelled with `JobCompleted{cancelled}` — no orphan work |
| notifications stopped | OneSignal categories + local schedule families of `F` are unsubscribed (`setSubscribed(false)` / `cancelLocal`), state preserved for re-enable |
| existing data preserved | AD-15 tables untouched (03 §4.2 mirrors keep syncing; historical reports keep their data) |
| deep links handled gracefully | a deep link into a disabled feature renders a **dedicated "feature disabled" state** (02 §7 `error` variant with a re-enable CTA + a redirect to the parent tab), never a crash or a 404 (test: feature-registry §54 checklist) |

Re-enable = inverse, instant, no migration. "Se simplifier sans migration
destructrice" (mission §54) holds by construction: deactivation is a **view
layer + scheduling decision**, never a data operation.

## 7. Product modes — one system, five faces (mission §55)

A **mode** = a named profile over the registries (features × preferences ×
context × theme × capabilities) — NOT five apps (mission §55). Declared in
`UserContext` (AD-15), applied by the availability policy:

| Mode | Effect (registry-driven) |
|---|---|
| **Core** | Productivity + Knowledge + Agent core; Learning/Discovery available but de-emphasized |
| **Study** | Learning + Progress + Focus + Calendar emphasized; Discovery/Projects minimized (data intact) |
| **Exam period** | (the §3 example) Learning/Progress/Focus/Calendar front; Discovery/Projects/Analytics minimized |
| **Focus-heavy** | Focus session cadence up, notification suppression scope widened (within focus spec §8), Home slots re-weighted (AD-14 re-resolution) |
| **Professional** | Goals/Projects/Progress (professional dimension, ADR §18.2) front; exam features de-emphasized |
| **Minimal** | Inbox + Tasks + Calendar only; everything else hidden-but-preserved |

Drivers: **features + preferences + context (declared period type) + theme +
capabilities** — all data, no `if user === Horeb` (mission §16). The agent reads
the same profile (Context form, AD-12) and its suggest-sets follow it.

## 8. FeatureModule interface (master mission S67)

Each feature module declares its UI surface in its Contract Pack (AD-13):

```ts
// SSoT packages/domain; one declaration per feature module
interface FeatureModule {
  id: string;                 // 'productivity', 'learning', 'knowledge', …
  name: string;

  routes: RouteDefinition[];  // from NavigationRegistry (02 S6.1)
  navigation: NavigationEntry[]; // tab / sub-tab / detail entries

  capabilities: string[];     // agent capability ids this module exposes
  dependencies: string[];     // feature ids required (transitive, validated at activation)

  enabledByDefault: boolean;  // core = true; optional = false
  optional: boolean;          // product may hide without breaking core

  // add-ons (AD-1 last paragraph: optional capabilities degrade when absent)
  optionalProviders?: string[]; // e.g. discovery: ['youcom', 'tavily', 'exa']
  platformRequires?: string[];  // e.g. focus.block: ['android', 'dpc_provisioned']
}
```

Registration: the module's Contract Pack (AD-13) includes the
`FeatureModule` declaration. The FeatureRegistry (S1) builds its seed
from all `FeatureModule` declarations + `user_context` overrides.

## 9. Agent feature declaration (master mission S68)

A feature that wants to be agent-controlled declares, in its Contract
Pack:

```ts
interface AgentFeatureDeclaration {
  featureId: string;          // must match a FeatureModule.id
  capabilities: AgentCapability[]; // the capability ids + full schema
  confirmationPolicy: {
    autoConfirm: string[];    // capability ids that never need confirmation (read-only)
    confirmAlways: string[];  // capability ids that always need confirmation
    confirmConditional: Record<string, string>; // capabilityId -> condition expr
  };
  uiAction: {
    onResult: 'navigate' | 'inline' | 'toast';  // where the result appears
    route?: string;                        // target route for 'navigate'
    deepLinkParams?: string[];             // params the agent may pass
  };
}
```

Example (focus):

```
featureId: 'productivity.focus'
capabilities: [focus.start, focus.end, focus.block]
confirmationPolicy: { autoConfirm: [], confirmAlways: ['focus.block'],
  confirmConditional: { 'focus.start': 'duration > 120' } }
uiAction: { onResult: 'navigate', route: '/focus', deepLinkParams: ['sessionId'] }
```

The kernel's Capability Registry (kernel S14) merges these declarations;
the Confirmation Engine (kernel S12) enforces the policy.

## 10. Dependency graph (master mission S69)

```
types: hard | soft | optional | runtime | external | platform

productivity (core)
  hard:   identity (user_context, RLS root)
  hard:   data (local-first, AD-7)
  soft:   progress (evidence, read-only)
  optional: scientific (inline formula rendering)
  platform: focus.block (android + DPC, OQ-17)

learning (core)
  hard:   knowledge (retrieval, AD-12)
  hard:   agent (AI generation, wave 3)
  optional: artifact (export, AD-1 degradation = no export)
  optional: discovery (gap-triggered items)

knowledge (core)
  hard:   artifact (R2 source documents)
  hard:   agent (retrieval, server-only AD-12)

discovery (optional)
  external: ResearchProvider (You.com/Tavily/Exa — AD-1 degradation: 'uncertain')
  runtime:  progress (skill states for gap targeting)

progress (core)
  runtime: all modules (evidence producers via AD-9 events)
  hard:    data (local mirrors, 03 S4.2)

artifacts (core)
  hard:    data (R2 via ObjectStorage port)
  external: R2 (Cloudflare)
  optional: agent (AI generation)

agent (core, wave 3)
  external: AI providers (AD-4, AD-5)
  external: Composio (optional, AD-1)
  hard:    all module public contracts (AD-2)

integrations (optional)
  external: Composio, OneSignal
  runtime:  agent (tool context)
```

**Invariant:** an optional feature NEVER hard-depends on the Core.
If `discovery` is disabled, `learning` still works (the optional
provider check in the availability policy degrades `discovery.research`
to `uncertain`, not `broken`).

## 11. Product evolution flows (master mission S70)

### Add a new feature

```
1. Domain: define entities in packages/domain (AD-15 SSoT)
2. Application: use-cases + commands (02 S4 layer 4)
3. Contract: port interfaces + Contract Pack declaration (AD-13)
4. Registry: FeatureModule + AgentFeatureDeclaration + FeatureDescriptor
5. Backend: Supabase tables + RLS + Edge Functions (if needed)
6. Frontend: routes + screens + components (02 S4 layers 1-3)
7. Agent capability: capability registration + tool schema
8. Navigation: NavigationRegistry entry + Command Palette entry
9. Tests: unit + integration + contract + E2E (per module test plan)
```

### Remove (deactivate) a feature

```
1. Disable: FeatureRegistry enabled=false
2. Hide: navigation, shortcuts, command palette, agent capabilities,
   widgets, dashboards, suggestions all filter on enabled (S6)
3. Remove agent capability: CapabilityRegistry drops the feature's
   capability ids (kernel S14: the agent adapts)
4. Stop jobs: Cron entries for the feature's job kinds stop being
   created (job_queue, AD-8); pending jobs finish or are cancelled
5. Preserve data: AD-15 tables untouched; mirrors keep syncing;
   historical reports keep their data
6. Deep links: render "feature disabled" state (S6: dedicated error
   variant + re-enable CTA)
```

No migration. No data loss. Re-enable = inverse, instant.
