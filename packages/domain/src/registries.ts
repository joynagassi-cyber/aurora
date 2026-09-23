/**
 * UI / registres contracts (AD-15 SSoT, contract-catalog S10-S11).
 *
 * Feature Descriptor + Agent Capability + Navigation Intent + UI State
 * Command + Agent Action Envelope, plus the 7 registry interfaces.
 *
 * These are the shared vocabulary between modules (producers) and the
 * UI shell. Implementations live in the owning packages; the types are
 * canonical here (AD-15).
 */
import type { OrSetValue } from './crdt';

// ---- Feature Descriptor (S10) ----

/**
 * A FeatureDescriptor is the single declaration of a capability: what it
 * does, its UI placement, its gating (registry seed), and its lifecycle
 * state. The FeatureRegistry is the SSoT of what's on/off.
 */
export interface FeatureDescriptor {
  /** canonical id, e.g. "focus_session", "qcm_generate" */
  id: string;
  /** display name */
  title: string;
  /** one-line description */
  description?: string;
  /** which module owns it */
  module: string;
  /** UI placement (S11 Navigation) */
  placement?: string;
  /** gating: required capabilities / feature deps */
  requires?: string[];
  /** lifecycle */
  status: 'stable' | 'beta' | 'experimental' | 'deprecated';
  /** default seed (feature-registry.md S1) */
  defaultEnabled: boolean;
  defaultVisible: boolean;
  /** feature-specific config schema (kept abstract) */
  configSchema?: Record<string, unknown>;
}

// ---- Agent Capability (S10) ----

/**
 * An AgentCapability is what the agent kernel may DO: a declared action the
 * AgentPort.run can request. The CapabilityRegistry gates which are
 * available to a user.
 */
export interface AgentCapability {
  /** e.g. "request_artifact_generation", "compose_goal" */
  id: string;
  title: string;
  /** which module / tool the capability maps to */
  tool?: string;
  /** the required feature(s) to be enabled */
  requiresFeatures?: string[];
  /** risk level — high-risk ones require confirmation */
  risk: 'low' | 'medium' | 'high';
  /** human-readable description of the side effects */
  effects?: string;
}

// ---- Navigation Intent (S11) ----

/**
 * A NavigationIntent is a typed request to move the UI (module -> UI
 * shell). Consumed by the NavigationRegistry.
 */
export interface NavigationIntent {
  /** the destination (module screen id) */
  target: string;
  /** params for the destination */
  params?: Record<string, unknown>;
  /** whether to replace or push the current screen */
  mode?: 'push' | 'replace' | 'reset';
  /** deep-link target (optional) */
  deepLink?: string;
}

// ---- UI State Command (S11) ----

/**
 * A UiStateCommand is a typed command that mutates shared UI state (not
 * domain state). E.g. open a drawer, toggle a panel, set the active tab.
 */
export interface UiStateCommand {
  /** command kind, e.g. "open_drawer", "set_tab", "close_modal" */
  command: string;
  /** command-specific payload */
  payload?: Record<string, unknown>;
}

// ---- Agent Action Envelope (S11) ----

/**
 * An AgentActionEnvelope wraps a single agent action: the capability,
 * the declared effect, and the confirmation status. The UI shell renders
 * high-risk envelopes behind a confirmation step.
 */
export interface AgentActionEnvelope {
  /** the capability id being exercised */
  capabilityId: string;
  /** the human-readable action */
  action: string;
  /** the declared effect */
  effect?: string;
  /** whether confirmation is required (high risk) */
  requiresConfirmation: boolean;
  /** the agent run that produced this */
  agentRunId: string;
  /** status of this action */
  status: 'proposed' | 'confirmed' | 'executed' | 'rejected';
}

// ---- 7 registries (S11) ----

/** 1. `FeatureRegistry` — SSoT of what's on/off. */
export interface FeatureRegistry {
  /** all declared features */
  list(): FeatureDescriptor[];
  /** is a feature enabled for a user */
  enabled(featureId: string, userId?: string): boolean;
  /** is a feature visible for a user */
  visible(featureId: string, userId?: string): boolean;
  /** toggle a feature for a user (persisted in user_context seed) */
  setEnabled(featureId: string, userId: string, enabled: boolean): void;
  /** resolve a feature by id */
  get(featureId: string): FeatureDescriptor | undefined;
}

/** 2. `CapabilityRegistry` — SSoT of agent capabilities. */
export interface CapabilityRegistry {
  /** all declared capabilities */
  list(): AgentCapability[];
  /** the capabilities a user may invoke (gated by features) */
  available(userId: string): AgentCapability[];
  /** get a capability by id */
  get(capabilityId: string): AgentCapability | undefined;
}

/** 3. `NavigationRegistry` — target screen definitions. */
export interface NavigationRegistry {
  /** the declared navigation targets */
  targets(): Array<{ id: string; title?: string; module: string }>;
  /** can a user reach a target */
  reachable(targetId: string, userId?: string): boolean;
}

/** 4. `ProviderRegistry` — AI provider declarations. */
export interface ProviderRegistry {
  /** the declared AI providers (in failover order) */
  list(): Array<{ provider: string; models: string[]; role: 'primary' | 'fallback' | 'last_resort' | 'optional' }>;
  /** the ordered provider chain for a class */
  chain(requestClass: 'fast' | 'full'): string[];
}

/** 5. `ModelRegistry` — model declarations (mirrors AIModelRegistry but
 * registry-shaped for the UI shell). */
export interface ModelRegistry {
  /** all declared models */
  list(): Array<{ provider: string; model: string; capabilities: string[] }>;
  /** the model serving a capability */
  forCapability(capability: string): { provider: string; model: string } | undefined;
}

/** 6. `ArtifactRegistry` — artifact kind declarations. */
export interface ArtifactRegistry {
  /** the declared artifact kinds */
  kinds(): Array<{ kind: string; contentType?: string; generators?: string[] }>;
  /** get a kind definition */
  get(kind: string): { kind: string; contentType?: string; generators?: string[] } | undefined;
}

/** 7. `IntegrationRegistry` — integration (vendor) declarations. */
export interface IntegrationRegistry {
  /** the declared integrations */
  list(): Array<{ vendor: string; tools: string[]; status?: string }>;
  /** the integrations a user has connected */
  connected(userId: string): Array<{ vendor: string; connection: string; status: string }>;
}

/**
 * The shared list type used by registries for OR-Set-backed state
 * (re-exported for consumers that need it alongside registry types).
 */
export type RegistryOrSetValue = OrSetValue;
