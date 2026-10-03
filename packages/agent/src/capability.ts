/**
 * Components 4-6 — Capability Registry + Tool Registry + Tool Resolver
 * (kernel.md S12/S14).
 *
 * The Capability Registry DISCOVERS module capabilities from the
 * Contract Packs each module declares (kernel S14: "the kernel
 * discovers, never hardcodes a growing condition list"). The Tool
 * Registry maps capabilities to typed tool functions with declared
 * read/write scopes. The Tool Resolver picks the tool for a plan step
 * given context + availability (AD-1 last paragraph: graceful
 * degradation when a provider/capability is absent).
 *
 * The registry is the RUNTIME surface of the `CapabilityRegistry`
 * domain contract (packages/domain/registries.ts) — the kernel builds
 * it from the module Contract Pack declarations.
 */
import type { AgentCapability, CapabilityRegistry as DomainCapabilityRegistry } from '@aurora/domain';
import type { AgentContext } from './types.ts';

/**
 * A capability entry in the registry (kernel S14 `AgentCapability`
 * shape — the rich form; the domain's `AgentCapability` is the
 * minimal SSoT form, the kernel extends it with scopes + platform).
 */
export interface CapabilityEntry {
  /** canonical id ("task.create", "focus.start", "calendar.schedule" …) */
  id: string;
  name: string;
  description: string;
  /** the tool function id this capability maps to */
  tool: string;
  readScopes: string[];
  writeScopes: string[];
  /** platform permissions the capability needs (e.g. DPC for focus.block) */
  permissions: string[];
  /** capability / provider ids required for this to be usable */
  dependencies: string[];
  requiresConfirmation: boolean;
  destructive: boolean;
  supportsNaturalLanguage: boolean;
  platform?: 'shared' | 'android' | 'desktop';
  /** planner must not place online-only steps into offline windows */
  offlineClass?: 'offline-capable' | 'online-required' | 'hybrid';
  /** the compensating action (kernel S13 rollback) */
  compensation?: Record<string, unknown>;
}

/**
 * `DefaultCapabilityRegistry` — builds the runtime registry from the
 * module Contract Pack declarations + the domain `CapabilityRegistry`.
 * The kernel never hardcodes the list: it DISCOVERS (kernel S14).
 */
export class DefaultCapabilityRegistry {
  private entries: CapabilityEntry[] = [];

  constructor() {
    this.seedDefaults();
  }
  /** Register a capability from a module's Contract Pack. */
  register(c: CapabilityEntry): void {
    this.entries = [...this.entries.filter((e) => e.id !== c.id), c];
  }

  /** The 8 kernel tools + the 7 goal capabilities — the canonical set. */
  private seedDefaults(): void {
    type Seed = Partial<CapabilityEntry> & { id: string; tool: string; description: string };
    const base: Seed[] = [
      {
        id: 'planning.daily',
        tool: 'planDay',
        description: 'Compose the day plan (time-blocking + task ordering)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'calendar.schedule',
        tool: 'schedule',
        description: 'Schedule / reorder time blocks on the calendar',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'focus.start',
        tool: 'startFocus',
        description: 'Start a focus session (timer + optional blocklist)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: true, // important action (ADR S5)
        permissions: ['POST_NOTIFICATIONS'],
      },
      {
        id: 'focus.block',
        tool: 'blockApps',
        description: 'Block apps during a focus session (DPC — android + DPC-provisioned, OQ-17)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: true,
        platform: 'android',
        offlineClass: 'offline-capable',
        permissions: ['DEVICE_POLICY_CONTROLLER'],
      },
      {
        id: 'research.query',
        tool: 'research',
        description: 'Run a typed multi-source research query (ResearchProvider)',
        writeScopes: [],
        readScopes: ['discovery:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['research-provider'],
      },
      {
        id: 'learning.qcm',
        tool: 'qcm_generate',
        description: 'Generate QCM items for a skill (artifact_gen job, AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'learning.mirror',
        tool: 'mirror_analyze',
        description: 'Cognitive mirror analysis of a session (agent_run job, AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        dependencies: ['knowledge-base'],
      },
      {
        id: 'scientific.verify',
        tool: 'scientific_verify',
        description: 'Deterministic scientific / engineering verification (job, AD-8)',
        writeScopes: [],
        readScopes: ['engineering:read'],
        destructive: false,
        requiresConfirmation: false,
        dependencies: ['scientific-engine'],
        offlineClass: 'offline-capable',
      },
      // ------------------------------------------------------------------
      // Goal capabilities (dynamic-goal-engine.md "Agent capabilities"):
      // the 7 goal.* commands. AD-7: the kernel emits the command; the
      // Progress module owns user_goals + applies the mutation (GoalProject
      // composition data via @aurora/goal-engine). goal.create is
      // CONFIRMATION_REQUIRED (the user sees the plan before activation).
      // ------------------------------------------------------------------
      {
        id: 'goal.create',
        tool: 'goal_create',
        description: 'NL objective -> decompose -> GoalProject (CONFIRMATION_REQUIRED)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read', 'knowledge:read', 'identity:read'],
        destructive: false,
        requiresConfirmation: true,
      },
      {
        id: 'goal.status',
        tool: 'goal_status',
        description: 'Read GoalProject + GoalProgress snapshot',
        writeScopes: [],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'goal.recompose',
        tool: 'goal_recompose',
        description: 'Re-plan a GoalProject on stall / context change (ADR S13: history preserved)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: true,
      },
      {
        id: 'goal.pause',
        tool: 'goal_pause',
        description: 'Pause a GoalProject (jobs stop, notifications mute; progress + history preserved)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: true,
      },
      {
        id: 'goal.complete',
        tool: 'goal_complete',
        description: 'Mark a GoalProject complete when the success criteria are met (F-07: Progress sole producer of the evidence)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'goal.abandon',
        tool: 'goal_abandon',
        description: 'Abandon a GoalProject (data preserved AD-15, features deactivated)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: true,
      },
      {
        id: 'goal.feature.add',
        tool: 'goal_feature_add',
        description: 'Add a feature to a GoalProject composition ("ajoute des QCM chaque semaine")',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'goal.feature.remove',
        tool: 'goal_feature_remove',
        description: 'Remove a feature from a GoalProject composition ("plus besoin de focus sur ce but")',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      // ------------------------------------------------------------------
      // Document tools (docs/agent/document-tools.md) — 4 capabilities,
      // the two directions (TEXT→DOC: docs.generate / docs.refine;
      // DOC→TEXT: docs.inspect / docs.parse). Never mixed: a generator
      // never parses, a parser never generates (document-tools S4).
      // All heavy steps = persisted artifact_gen jobs (AD-8); outputs are
      // new artifact rows (F-06 post-R2; revisions supersedes, §24).
      // ------------------------------------------------------------------
      {
        id: 'docs.generate',
        tool: 'docs_generate',
        description:
          'Generate a full document from LLM Markdown (Pandoc: .docx/.pdf/.pptx/.html/.epub, --reference-doc templates, Mermaid→images). Whole-document generation ONLY. artifact_gen job (AD-8), F-06 post-R2',
        writeScopes: ['artifact:write'],
        readScopes: ['knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['pandoc'],
      },
      {
        id: 'docs.refine',
        tool: 'docs_refine',
        description:
          'Surgical precision edits on an existing .docx (python-docx: complex data tables, invoices pixel-precise, dynamic styles). NOT for first-time generation. Output = new artifact revision (supersedes, artifacts §24). artifact_gen job (AD-8)',
        writeScopes: ['artifact:write'],
        readScopes: ['artifact:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['python-docx'],
      },
      {
        id: 'docs.inspect',
        tool: 'docs_inspect',
        description:
          'Quickly read / inspect an existing .docx (mammoth: clean HTML/Markdown content, structure outline, typo scan). READ-ONLY source, .docx ONLY (PDF/PPTX/XLSX → docs.parse). Light artifact_gen job (AD-8)',
        writeScopes: ['artifact:write'], // the parsed representation row only (Artifact module applies, AD-7)
        readScopes: ['artifact:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['mammoth'],
      },
      {
        id: 'docs.parse',
        tool: 'docs_parse',
        description:
          'Parse a complex document (Docling: scanned PDF / PPTX / XLSX / HTML / images → structured Markdown/JSON, table reconstruction). READ-ONLY source; DOC→TEXT direction only. Heavy artifact_gen job (AD-8); degraded fallback = pandoc extraction, raw scans → ocr job',
        writeScopes: ['artifact:write'], // the parsed representation row only (Artifact module applies, AD-7)
        readScopes: ['artifact:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['docling'],
      },
      // ------------------------------------------------------------------
      // Feature-agentability-matrix.md — the remaining agentable
      // families (AD-7: every entry EMITS a typed command / job; the
      // owning module applies the mutation — the kernel NEVER writes a
      // module table). Owner per family: Productivity / Learning /
      // Knowledge / Progress / Artifact / Identity / Integrations /
      // Agent (coach). call.policy is NOT_AGENT_ENABLED (V1, opt-in
      // role-gated) → deliberately NOT registered here.
      // ------------------------------------------------------------------
      {
        id: 'task.update',
        tool: 'task_update',
        description: 'Create / update / complete / archive a task (Productivity, AD-7 command)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false, // bulk / delete path = confirmation at module level
      },
      {
        id: 'habit.checkin',
        tool: 'habit_checkin',
        description: 'Log a habit / routine check-in ("j\'ai fait X") (Productivity)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'planning.replan',
        tool: 'planning_replan',
        description:
          'Re-plan / reorder the remaining day on context change (ADR S13: "recalcul du planning restant sans détruire l\'historique")',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: true, // discarding an active plan = important
      },
      {
        id: 'course.search',
        tool: 'course_search',
        description: 'Find a course / resource on a topic (local mirror + server retrieval, READ-ONLY)',
        writeScopes: [],
        readScopes: ['learning:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'hybrid', // offline = mirror only (AD-1 degrade)
      },
      {
        id: 'flashcard.generate',
        tool: 'flashcard_generate',
        description: 'Generate flashcards for a skill / course (Learning, artifact_gen job AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
      },
      {
        id: 'learning.session.start',
        tool: 'learning_session',
        description: 'Start a mirror-mode learning session ("quiz me / explain") (agent_run job AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        dependencies: ['knowledge-base'],
      },
      {
        id: 'learning.import',
        tool: 'learning_import',
        description: 'Ingest course materials for a course (G-L5 course_import job, AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'artifact:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['course-importer'],
      },
      {
        id: 'knowledge.add',
        tool: 'knowledge_add',
        description: 'Ingest a new source into the KB (camera / OCR / upload — ocr job, AD-11 provenance)',
        writeScopes: ['knowledge:write'],
        readScopes: ['artifact:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['ocr'],
      },
      {
        id: 'progress.analyze',
        tool: 'progress_analyze',
        description:
          'Analyze progress across a skill / goal (mirrors light read-only; deep = skill_recompute job AD-8)',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'hybrid',
      },
      {
        id: 'progress.trajectories',
        tool: 'progress_trajectories',
        description: 'Read the progress trajectory / time-series for a skill (READ-ONLY, Progress-owned)',
        writeScopes: [],
        readScopes: ['progress:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'offline-capable',
      },
      {
        id: 'progress.cause',
        tool: 'progress_cause',
        description: 'Root-cause a skill gap ("pourquoi ai-je du mal sur X ?") — heavy skill_recompute job',
        writeScopes: ['progress:write'],
        readScopes: ['progress:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
      },
      {
        id: 'artifact.generate',
        tool: 'artifact_generate',
        description: 'Export a sheet / item as a document (artifact_gen job, AD-8; F-06 post-R2 blob)',
        writeScopes: ['artifact:write'],
        readScopes: ['artifact:read', 'productivity:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
      },
      {
        id: 'artifact.preview',
        tool: 'artifact_preview',
        description:
          '"Show me X" → Artifact Hub preview (USER_ONLY: emits show_artifact ui-command + deep link, the kernel NEVER reads the artifact — device-side local cache, AD-1 degrade to raw download)',
        writeScopes: [],
        readScopes: ['artifact:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'scientific.evaluate',
        tool: 'scientific_evaluate',
        description:
          'Compute / evaluate a formula locally (ScientificEngine light ops, offline-capable; the heavy scientific_verify job covers full verification)',
        writeScopes: [],
        readScopes: ['engineering:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'offline-capable',
        dependencies: ['scientific-engine'],
      },
      {
        id: 'coach.checkin',
        tool: 'coach_checkin',
        description:
          'Proactive coach check-in (cadence + silence-window bounded, ADR §13 — PARTIAL by design)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'settings.theme',
        tool: 'settings_theme',
        description: 'Set the app theme / a preference (user_context command, AD-7 Identity)',
        writeScopes: ['identity:write'],
        readScopes: ['identity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'review.run',
        tool: 'review_run',
        description:
          'Run a productivity review (daily / weekly / monthly; priority changes = confirmation)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read', 'progress:read'],
        destructive: false,
        requiresConfirmation: true, // priority changes are important
      },
      {
        id: 'integrations.automation.toggle',
        tool: 'automation_toggle',
        description: 'Start / stop an automation (Composio, vendor SDK AD-1 — Integrations-owned)',
        writeScopes: ['integrations:write'],
        readScopes: ['integrations:read'],
        destructive: false,
        requiresConfirmation: true,
        dependencies: ['composio'],
      },
      {
        id: 'notification.prefs',
        tool: 'notification_pref',
        description: 'Subscribe / silence a notification channel (user prefs, Integrations-owned)',
        writeScopes: ['integrations:write'],
        readScopes: [],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'task.prioritize',
        tool: 'eisenhower_prioritize',
        description: 'Prioritize tasks into the 4 Eisenhower quadrants (Productivity, G-L5)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
    ];
    for (const b of base) {
      this.register({
        id: b.id,
        name: b.id,
        description: b.description,
        tool: b.tool,
        readScopes: b.readScopes ?? [],
        writeScopes: b.writeScopes ?? [],
        permissions: b.permissions ?? [],
        dependencies: b.dependencies ?? [],
        requiresConfirmation: b.requiresConfirmation ?? false,
        destructive: b.destructive ?? false,
        supportsNaturalLanguage: true,
        ...(b.platform ? { platform: b.platform } : {}),
        ...(b.offlineClass ? { offlineClass: b.offlineClass } : {}),
        ...(b.compensation ? { compensation: b.compensation } : {}),
      });
    }
  }

  /** The domain-shaped view (for the UI shell, registries S10). */
  toDomain(): DomainCapabilityRegistry {
    const list = (): AgentCapability[] =>
      this.entries.map((e) => ({
        id: e.id,
        title: e.name,
        tool: e.tool,
        risk: e.destructive ? 'high' : e.requiresConfirmation ? 'high' : e.writeScopes.length ? 'medium' : 'low',
        effects: e.description,
      }));
    return {
      list,
      available: list, // the per-user gate is applied by the FeatureRegistry (Identity)
      get: (id) => list().find((c) => c.id === id),
    };
  }

  /** All entries (read-only view). */
  all(): CapabilityEntry[] {
    return [...this.entries];
  }

  /** Resolve by capability id. */
  get(id: string): CapabilityEntry | undefined {
    return this.entries.find((e) => e.id === id);
  }

  /** Resolve by tool id (the 8 kernel tools). */
  byTool(tool: string): CapabilityEntry | undefined {
    return this.entries.find((e) => e.tool === tool);
  }
}

/** The Tool Resolver (component 6): given a tool id + context, return the
 * CapabilityEntry — `undefined` when unavailable (provider absent,
 * feature disabled, platform mismatch, offline window). The Planner
 * then marks the step skipped rather than failing the whole run
 * (AD-1 last paragraph: optional capabilities degrade when absent). */
export function resolveTool(
  tool: string,
  ctx: AgentContext,
  registry: Pick<DefaultCapabilityRegistry, 'byTool'>,
): CapabilityEntry | undefined {
  const entry = registry.byTool(tool);  if (!entry) return undefined;
  // Platform gate: focus.block is android-only.
  if (entry.platform && entry.platform === 'android') {
    const dpcAvailable = (ctx.permission as Record<string, unknown>)['devicePolicyAvailable'] === true;
    if (!dpcAvailable) return undefined; // degrade to restriction-only (focus spec §4)
  }
  // Offline gate: online-required tools are unavailable offline.
  if (entry.offlineClass === 'online-required' && ctx.tool.availability === 'offline') {
    return undefined;
  }
  // Dependency gate: required capability absent → unavailable.
  const available = (ctx.tool as unknown as Record<string, unknown>).available as string[] | undefined;
  if (entry.dependencies.length && available) {
    const hasAll = entry.dependencies.every((d) => available.includes(d));
    if (!hasAll) return undefined;
  }
  return entry;
}

export interface ToolResolver {
  resolve(tool: string, ctx: AgentContext, registry: Pick<DefaultCapabilityRegistry, 'byTool'>): CapabilityEntry | undefined;
}

export { classifyAction } from './permission.ts';
