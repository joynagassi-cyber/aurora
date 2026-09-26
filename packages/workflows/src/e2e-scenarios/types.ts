/**
 * e2e-scenarios.ts — the 20 mandatory E2E agent scenarios (OQ-08,
 * Playwright-on-device, docs/agent/e2e-agent-scenarios.md).
 *
 * Each scenario is a DETERMINISTIC TRACING SPEC, not a test runner: it pins
 * the 11 lanes the doc traces (Natural Language -> Intent -> Context ->
 * Capabilities -> Tools -> Modules -> Backend -> UI transitions -> Result ->
 * Progress) plus the AD-9 events it produces and its confirmation/offline
 * classification (ADR S5 + offline behavior note).
 *
 * The scenarios are the executable spec that the OQ-08 Playwright suite
 * (device) will replay. Keeping them here, next to the 23 workflows, means
 * the E2E runner and the workflow contracts share one source of truth.
 *
 * Conventions (from the doc):
 *  - capability IDs = feature-agentability-matrix vocabulary
 *  - UI transitions = 02 S6.1 route map + command bus (kernel S15)
 *  - "confirm" = Confirmation Engine blocks the user until answered (ADR S5)
 *  - Progress evidence = sole-producer rule (F-07: only Progress emits
 *    ProgressEvidenceCreated)
 *  - events ⊆ the 9 AD-9 events
 */
import type { DomainEventName } from '@aurora/domain';
import type { WorkflowModule } from '../types.ts';

/** Confirmation requirement (ADR S5): important/irreversible steps gate. */
export type ConfirmationClass =
  /** read-only / non-irreversible — no gate */
  | 'none'
  /** Confirmation Engine CTA (replan discards old plan, schedule, focus start, blocklist, send) */
  | 'confirm'
  /** destructive / irreversible — confirm every time (E10) */
  | 'destructive';

/** Offline behavior (doc "Offline behavior" note). */
export type OfflineClass =
  /** runs on local mirrors / no network needed */
  | 'offline-capable'
  /** needs AI / R2 / Composio / server */
  | 'online-required'
  /** mirrors read offline, deep analysis online */
  | 'hybrid';

/** One E2E agent scenario — the 11-lane tracing spec + event/offline classes. */
export interface E2EScenario {
  /** 'S1'..'S20' */
  id: string;
  /** the natural-language utterance (master mission S60) */
  utterance: string;
  /** lane: typed intent (TaskProfile) */
  intent: string;
  /** lane: context forms in play (02 S5 / 9 context forms, ADR S16) */
  context: string[];
  /** lane: capabilities (feature-agentability-matrix vocabulary) */
  capabilities: string[];
  /** lane: tools invoked (kernel Tool Registry) */
  tools: string[];
  /** lane: owning modules (03 S4.2) */
  modules: WorkflowModule[];
  /** lane: backend lane (LocalCommandRepository / fn-* / jobs / R2) */
  backend: string;
  /** lane: UI transitions (02 S6.1 + command bus) */
  ui: { from: string; to: string }[];
  /** lane: observable result (user-visible state change) */
  result: string;
  /** lane: Progress effect (S18.x) */
  progress: string;
  /** AD-9 events this scenario produces (closed vocabulary) */
  events: DomainEventName[];
  /** ADR S5 confirmation class */
  confirmation: ConfirmationClass;
  /** offline behavior (kernel S12 offlineClass) */
  offline: OfflineClass;
}
