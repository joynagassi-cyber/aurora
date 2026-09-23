# Registry System Specification (master mission S66)

Seven registries that decouple layers. Types in `packages/domain`
(AD-15 SSoT); runtime owners per SPEC wave-0 list. The goal: no layer
hardcodes a growing list of providers, models, features, capabilities,
routes, artifacts, or integrations.

## 1. ProviderRegistry

| Field | Value |
|---|---|
| Purpose | enumerate all external service providers (AI, research, storage, notification, integration) |
| SSoT | `packages/domain` (type); seed data = server config (01 S5.4, AD-16) |
| Contents | provider ID, category (ai / research / storage / notification / integration), base URL, auth method, status (active / degraded / retired) |
| Consumers | `AIModelRouter` (AI providers), `ResearchProvider` adapter, `ObjectStorage` adapter, `NotificationProvider` adapter, `IntegrationProvider` adapter |
| Runtime owner | Foundation (AD-16: one registry owner) |
| Wave | 0 (seed) + 1 (AI providers) + 2 (research / integrations) |

## 2. ModelRegistry

| Field | Value |
|---|---|
| Purpose | catalog of all AI models across providers: capabilities, context, modality, status, quotas, conditions |
| SSoT | `packages/domain` (type); rows in Supabase `model_registry` (owner `packages/data`, AD-16b) |
| Contents | model ID, provider ID, capabilities (reasoning / vision / tools / structured-output / streaming), context window, modality, status (active / retired / deprecated), free-tier quota (snapshot date, G-U4), paid pricing, data policy flags |
| Consumers | `AIModelRouter` (selection), `AIHealthRegistry` (per-model health), `AIBudgetManager` (quota tracking) |
| Runtime owner | `packages/data` team (AD-16b) |
| Wave | 0 (schema) + 1 (Agnes + Workers AI) + 3 (full catalog) |
| Rule | free-tier quotas = dated photographs (2026-09-21 snapshot, ADR v1.7 S8/S18); auto-retirement test (01 S7) catches drift |

## 3. CapabilityRegistry (Agent)

| Field | Value |
|---|---|
| Purpose | the set of agent-discoverable capabilities (kernel S14 `AgentCapability` types) |
| SSoT | `packages/domain` (type); runtime = `packages/agent` (server) |
| Contents | per capability: id, name, description, inputSchema, outputSchema, readScopes, writeScopes, permissions, dependencies, requiresConfirmation, destructive, supportsNaturalLanguage, platform, offlineClass |
| Registration | each module declares its capabilities in its Contract Pack (AD-13); the kernel builds the registry from declarations + availability checks (provider present? feature enabled? platform capability?) |
| Consumers | Agent Kernel (discovery, not hardcoding), Feature Registry (S68: feature -> capabilities mapping) |
| Runtime owner | Agent team |
| Wave | 3 |

## 4. FeatureRegistry

| Field | Value |
|---|---|
| Purpose | the set of product features + their activation state (feature-registry.md S1 `FeatureDescriptor`) |
| SSoT | `packages/domain` (type); seed in `user_context` (Identity) |
| Contents | per feature: id, enabled, visible, routes, capabilities, dependencies, optional, state, offlineClass |
| Registration | each feature module declares its `FeatureModule` (feature-registry.md S67/68) |
| Consumers | Navigation Registry, Screen Registry, Agent Capability Registry, Availability Policy |
| Runtime owner | Foundation + App Shell (G-M7, NEEDS_DECISION) |
| Wave | 0 (ratify) + 1 (implementation) |

## 5. NavigationRegistry

| Field | Value |
|---|---|
| Purpose | the set of routes + navigation entries + deep links, filtered by feature availability |
| SSoT | `packages/domain` (type); runtime = `packages/navigation` (mobile shell) |
| Contents | per entry: route path, label, icon, featureId, depth (tab / sub-tab / detail), deep-link params schema |
| Consumers | Frontend Router (02 S6), Command Palette, Agent `NavigationIntent` |
| Runtime owner | App Shell team |
| Wave | 1 |

## 6. ArtifactRegistry

| Field | Value |
|---|---|
| Purpose | catalog of artifact types + their R2 storage paths, preview capabilities, export formats |
| SSoT | `packages/domain` (type); runtime = Artifact module |
| Contents | per type: kind (sheet / infographic / figure / audio / video / pdf / docx / png), r2 key prefix, preview renderer (AD-10), export formats, max size, retention policy |
| Consumers | Artifact module (create / preview / download), UI (artifact cards, `ArtifactGenerated` event) |
| Runtime owner | Artifact team |
| Wave | 2 |

## 7. IntegrationRegistry

| Field | Value |
|---|---|
| Purpose | catalog of external integrations (Composio toolkits, OneSignal, future MDM) + their auth config + connection state |
| SSoT | `packages/domain` (type); runtime = Integrations module |
| Contents | per integration: ID, vendor (Composio / OneSignal / ...), auth method (OAuth / API key / service token), connectedAccountID mapping, tool catalog ref, status |
| Consumers | Agent Tool Registry (Composio tools), NotificationProvider (OneSignal), Automation engine |
| Runtime owner | Integrations team |
| Wave | 2 |

## Cross-registry invariants

1. A feature in the FeatureRegistry that is `enabled=false` removes its
   capabilities from the CapabilityRegistry (kernel S14: the agent
   discovers what is enabled, never hardcodes).
2. A model in the ModelRegistry that is `retired` is invisible to the
   ModelRouter (AD-5 auto-retirement).
3. A provider in the ProviderRegistry that is `degraded` is deprioritized
   by the ModelRouter (health check, 01 S5.6).
4. A navigation entry in the NavigationRegistry that references a
   disabled feature is hidden (feature-registry.md S2 chain).
5. An integration in the IntegrationRegistry that is `disconnected`
   removes its tools from the Agent Tool Registry (composio.md S3).
