/**
 * Component 2 — Context Builder (kernel.md S12).
 *
 * Assembles the 9 context forms (ADR S16) from module PUBLIC contracts
 * (AD-2: cross-module reads go through public views / the event table,
 * never raw module tables). Projections of AD-15 types only — no
 * re-declarations (AD-15).
 *
 * Server-side only (01 S5.6). Every form is optional and degrades to
 * `{}` when the upstream module is unavailable (AD-1 last paragraph).
 */
import type {
  UserContext,
  Goal,
  Task,
  FocusSession,
  Course,
  LearningItem,
  Skill,
  SkillState,
  DiscoveryItem,
  SemanticNode,
  NodeState,
  ProgressEvidence,
  ResearchProvider,
  ExpertSkill,
  CapabilityRegistry,
} from '@aurora/domain';

import type { AgentContext, Intent } from './types.ts';

/**
 * The seam the Context Builder reads through. Each `load*` is one public
 * view of a module (AD-2); implementations live in the server-side
 * adapters (fn-agent-run), the kernel never sees raw module tables.
 * `load*` = `null` when the form is unavailable (degrade, not fail).
 */
export interface ContextAssembler {
  loadPersonal(userId: string): Promise<Partial<UserContext> | null>;
  loadProductivity(userId: string): Promise<{
    goals: Goal[];
    /** open tasks due today */
    openTasks: Task[];
    /** active / planned focus sessions today */
    focusSessions: FocusSession[];
    /** whether the user is in an exam period (data-driven, never a name check) */
    examPeriod?: boolean;
  } | null>;
  loadLearning(userId: string): Promise<{
    courses: Course[];
    /** due learning items (Learning public view, F-07 mirrors kept in
     *  Learning; Progress owns the evidence, not the schedule) */
    due: LearningItem[];
    /** referenced skills (for the Learning context form) */
    skills: Skill[];
  } | null>;
  loadDiscovery(userId: string): Promise<{
    items: DiscoveryItem[];
    /** latest skill states (Progress mirror, read via the public
     *  `skill_states` view — AD-2) */
    skillStates: SkillState[];
  } | null>;
  loadSemantic(userId: string): Promise<{
    nodes: Array<{ node: SemanticNode; state: NodeState }>;
  } | null>;
  loadExpertSkills(userId: string): Promise<ExpertSkill[]>;
  loadToolContext(userId: string): Promise<{
    available: string[];
    /** provider/model availability (AIHealthRegistry snapshot) */
    providers: Array<{ provider: string; model: string; healthy: boolean }>;
  } | null>;
  loadPermission(userId: string): Promise<{
    /** FeatureRegistry seed (AD-2: Identity owns user_context) */
    featureState: Record<string, boolean>;
    /** declared capabilities the user may invoke */
    capabilityIds: string[];
  } | null>;
  /**
   * Load the user's ACTIVE skills from `user_skills` (migration 0019).
   * A builtin row ('builtin:<key>') joins its payload from `skill_catalog`;
   * a user-created row ('user:<ULID>') is self-contained. The result feeds
   * prompt layer 1 (Task 1/2). Degrades to `[]` when the table or key is
   * absent (AD-1: the loop continues without skills).
   */
  loadUserSkills?(userId: string): Promise<Array<Record<string, unknown>>>;
  /**
   * 0021 marketplace — the GLOBAL skill_catalog index (compact: skill_key +
   * name + domain + trigger_ only, never the markdown body). Feeds prompt
   * layer 2.5 so the model knows WHICH skills exist without 600 bodies in
   * context; the agent picks one via skill_search, then loads the full
   * SKILL.md via skill_get. Degrades to [] when the table is absent.
   */
  loadSkillCatalogIndex?(): Promise<
    Array<{ skill_key: string; name: string; domain: string; trigger_: string | null }>
  >;
}

/**
 * Build the 9-form AgentContext for a run. The `intent` form is carried
 * in by the caller (the Intent Engine's output); the 8 data forms come
 * from the assemblers — each degrades independently to `{}` / `[]` so
 * one unavailable module never blocks the loop.
 */
export async function buildAgentContext(
  userId: string,
  intent: Intent,
  a: ContextAssembler,
  toolContextExtra?: {
    capabilityRegistry?: Pick<CapabilityRegistry, 'available'>;
    researchProvider?: ResearchProvider;
    evidences?: ProgressEvidence[];
  },
): Promise<AgentContext> {
  const [personal, productivity, learning, discovery, semantic, expertSkills, tool, permission, userSkills, catalogIndex] =
    await Promise.all([
      safe(a.loadPersonal(userId)),
      safe(a.loadProductivity(userId)),
      safe(a.loadLearning(userId)),
      safe(a.loadDiscovery(userId)),
      safe(a.loadSemantic(userId)),
      safe(a.loadExpertSkills(userId)),
      safe(a.loadToolContext(userId)),
      safe(a.loadPermission(userId)),
      // form 10 — Task 1/2: active user skills (optional seam, degrades to []).
      safe(a.loadUserSkills ? a.loadUserSkills(userId) : Promise.resolve([])),
      // form 11 — 0021: global skill_catalog index (optional, degrades to []).
      safe(a.loadSkillCatalogIndex ? a.loadSkillCatalogIndex() : Promise.resolve([])),
    ]);

  const expertSkillRows = expertSkills ?? [];
  const evidences = toolContextExtra?.evidences ?? [];

  const toolForm: Record<string, unknown> = {
    available: tool?.available ?? [],
    providers: tool?.providers ?? [],
    researchProviderConfigured: toolContextExtra?.researchProvider?.isConfigured() ?? false,
    /** declared capabilities the user may invoke (Capability Registry,
     *  kernel S14: the kernel DISCOVERS, never hardcodes) */
    capabilityIds: toolContextExtra?.capabilityRegistry?.available(userId)
      .map((c) => c.id) ?? permission?.capabilityIds ?? [],
  };

  return {
    intent,
    personal: personal ? Object.fromEntries(Object.entries(personal)) : {},
    productivity: productivity
      ? {
          goals: productivity.goals.map((g) => g.id),
          openTaskIds: productivity.openTasks.map((t) => t.id),
          focusSessionIds: productivity.focusSessions.map((f) => f.id),
          examPeriod: Boolean(productivity.examPeriod),
        }
      : {},
    learning: learning
      ? {
          courseIds: learning.courses.map((c) => c.id),
          dueItemIds: learning.due.map((d) => d.id),
          skillIds: learning.skills.map((s) => s.id),
        }
      : {},
    discovery: discovery
      ? {
          itemIds: discovery.items.map((d) => d.id),
          skillStateSummary: Object.fromEntries(
            discovery.skillStates.map((s) => [s.skillId, s.level]),
          ),
        }
      : {},
    semantic: semantic
      ? {
          nodeIds: semantic.nodes.map((n) => n.node.id),
          states: Object.fromEntries(
            semantic.nodes.map((n) => [n.node.id, n.state.learningState]),
          ),
        }
      : {},
    expertSkills: {
      active: expertSkillRows
        .filter((s) => s.status === 'validated' || s.status === 'candidate')
        .map((s) => s.id),
      provenance: expertSkillRows.map((s) => s.id),
      evidenceIds: evidences.map((e) => e.id),
    },
    tool: toolForm,
    permission: permission
      ? {
          featureState: permission.featureState,
          capabilityIds: permission.capabilityIds,
          destructiveGates: ['focus.block', 'course.delete'], // ADR S5 confirmation gates
        }
      : {},
    // form 10 — Task 1/2: the user's active skills (prompt layer 1). Each
    // row is self-contained (procedure/constraints/tools) — builtin rows
    // carry the catalog payload, user-created rows their own.
    skills: {
      active: (userSkills ?? [])
        .filter((s) => s.active !== false)
        .map((s) => ({
          key: s.skill_key ?? s.skillKey,
          domain: s.domain,
          name: s.name,
          trigger: s.trigger_ ?? s.trigger,
          objective: s.objective,
          procedure: Array.isArray(s.procedure) ? s.procedure : [],
          constraints: Array.isArray(s.constraints) ? s.constraints : [],
          tools: Array.isArray(s.tools) ? s.tools : [],
          // 0021 marketplace seed: the full markdown SKILL.md body (null for
          // builtin/user-created rows). Feeds prompt layer 1 inline.
          body: typeof (s as { body?: unknown }).body === "string" ? (s as { body: string }).body : null,
        })),
    },
    // form 11 — 0021 marketplace: the global skill_catalog index (compact,
    // no body). The agent uses this to know WHICH skills exist, then
    // calls skill_search / skill_get for details. Feeds prompt layer 2.5.
    catalog: {
      index: (catalogIndex ?? []).map((s) => ({
        key: s.skill_key,
        name: s.name,
        domain: s.domain,
        trigger: s.trigger_ ?? "",
      })),
    },
  };
}

/** Async wrapper that degrades one form to `null` on failure. */
async function safe<T>(p: Promise<T>): Promise<T | null> {
  try {
    return await p;
  } catch {
    return null;
  }
}
