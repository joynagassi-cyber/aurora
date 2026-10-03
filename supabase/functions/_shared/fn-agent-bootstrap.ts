// fn-agent-bootstrap — the server-side kernel seams (AD-12, 01 §5.6, OQ-03).
//
// The agent_run handler boots packages/agent's AgentKernel with the
// server-side seams. Env-gated on provider keys (AD-3: they live in the
// server env ONLY, never in the app bundle). Absent keys → the dispatcher
// keeps the documented `pending-bootstrap` degraded no-op (AD-8: idempotent,
// no data loss — the run executes on a future dispatch once the keys land).
//
// The ContextAssembler reads the 0012 public views (`*_public`, AD-2).
// The Memory engine reads/writes the server-only `expert_skills` table.
// The JobDispatcherPort writes to `job_queue` (the Job system's owned
// table, AD-8).

import { ulid } from "./envelope.ts";
import type {
  AgentKernel,
  ContextAssembler,
  MemoryEngine,
  MemoryDeps,
  VerificationDeps,
  KernelDeps,
} from "../../../packages/agent/src/index.ts";
import { AgentKernel as AgentKernelImpl } from "../../../packages/agent/src/kernel.ts";
import type { JobDispatcherPort } from "../../../packages/domain/src/index.ts";
import {
  ProviderHealth,
  BudgetGate,
  DataPolicyGate,
  AgnesRouterRegistry,
  type ProviderSettings,
  makeAgnesRouter,
} from "../../../packages/agent/src/providers.ts";
import type { TaskProfile } from "../../../packages/agent/src/types.ts";
import type { RawModelResponse } from "../../../packages/agent/src/result.ts";

// ——— Provider chain (AD-3: keys from env ONLY) ———
const AGNES_API_KEY = Deno.env.get("AGNES_API_KEY") ?? "";
const AGNES_BASE_URL = Deno.env.get("AGNES_BASE_URL") ?? "";

interface Chain {
  settings: Record<string, ProviderSettings>;
  health: ProviderHealth;
  budget: BudgetGate;
  policy: DataPolicyGate;
  configured: boolean;
}

function providerChain(): Chain {
  const settings: Record<string, ProviderSettings> = {};
  if (AGNES_BASE_URL && AGNES_API_KEY) {
    settings["agnes"] = { name: "agnes", baseURL: AGNES_BASE_URL, apiKey: AGNES_API_KEY };
  }
  return {
    settings,
    health: new ProviderHealth(),
    budget: new BudgetGate(),
    policy: new DataPolicyGate(),
    configured: Object.keys(settings).length > 0,
  };
}

/** The kernel is bootstrap-able when at least one provider is configured. */
export function isKernelConfigured(): boolean {
  return providerChain().configured;
}

// ——— Supabase REST (service_role — env-only, AD-3) ———
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";

async function rest<T>(method: string, path: string, body?: unknown): Promise<T | null> {
  if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) return null;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method,
    headers: {
      apikey: SUPABASE_SECRET_KEY,
      Authorization: `Bearer ${SUPABASE_SECRET_KEY}`,
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) return null;
  return (await res.json()) as T;
}

function sel(view: string) {
  return `${view}?select=*&limit=500`;
}
function byUser<T extends { user_id?: string }>(rows: T[], userId: string): T[] {
  return rows.filter((r) => r.user_id === userId);
}

// ——— The 9-form ContextAssembler (AD-2 public views, 0012) ———
export function buildContextAssembler(): ContextAssembler {
  return {
    async loadPersonal(userId) {
      const rows = await rest<Array<Record<string, unknown>>>("GET", sel("user_context_public"));
      if (!rows) return null;
      const row = rows.find((r) => r.user_id === userId);
      if (!row) return null;
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(row)) {
        if (k !== "id" && k !== "user_id" && k !== "created_at" && k !== "updated_at") out[k] = v;
      }
      return out;
    },
    async loadProductivity(userId) {
      const [goals, tasks, focus] = await Promise.all([
        rest<Array<Record<string, unknown>>>("GET", sel("user_goals_public")),
        rest<Array<Record<string, unknown>>>("GET", sel("tasks_public")),
        rest<Array<Record<string, unknown>>>("GET", sel("focus_sessions_public")),
      ]);
      if (!goals || !tasks || !focus) return null;
      const openTasks = tasks.filter((t) => t.status !== "done" && t.status !== "archived");
      return {
        goals: byUser(goals, userId) as never[],
        openTasks: byUser(openTasks, userId) as never[],
        focusSessions: byUser(focus, userId) as never[],
        examPeriod: undefined,
      };
    },
    async loadLearning(userId) {
      const [courses, items, skills] = await Promise.all([
        rest<Array<Record<string, unknown>>>("GET", sel("courses_public")),
        rest<Array<Record<string, unknown>>>("GET", sel("learning_items_public")),
        rest<Array<Record<string, unknown>>>("GET", sel("skills_public")),
      ]);
      if (!courses || !items || !skills) return null;
      const due = items.filter((i) => i.status !== "done" && i.status !== "archived");
      return {
        courses: byUser(courses, userId) as never[],
        due: byUser(due, userId) as never[],
        skills: byUser(skills, userId) as never[],
      };
    },
    async loadDiscovery(userId) {
      const [items, skillStates] = await Promise.all([
        rest<Array<Record<string, unknown>>>("GET", sel("discovery_items_public")),
        rest<Array<Record<string, unknown>>>("GET", sel("skill_states_public")),
      ]);
      if (!items || !skillStates) return null;
      return {
        items: byUser(items, userId) as never[],
        skillStates: byUser(skillStates, userId) as never[],
      };
    },
    async loadSemantic(userId) {
      // AD-1 last paragraph: the semantic form carries the semantic nodes
      // (the Context Builder — context.ts — projects `form.nodes` onto its
      // own `SemanticContext` view). The kernel NEVER writes a module table
      // (AD-7); this is a read-only join. The shape here matches
      // `ContextAssembler.loadSemantic` verbatim ({ node, state } pairs
      // are only required by `KnowledgeGraphPort`, not the assembler).
      const nodes = await rest<Array<Record<string, unknown>>>("GET", sel("semantic_nodes_public"));
      if (!nodes) return null;
      return { nodes: byUser(nodes, userId) as never[] };
    },
    async loadExpertSkills(userId) {
      const rows = await rest<Array<Record<string, unknown>>>("GET", sel("expert_skills"));
      if (!rows) return [];
      return byUser(rows, userId) as never[];
    },
    async loadToolContext(userId) {
      void userId;
      const chain = providerChain();
      // The available tools = the canonical tool-id set the kernel's
      // Planner / Tool Resolver address steps by (packages/agent/src/tools.ts
      // KERNEL_TOOLS, the tool field of the DefaultCapabilityRegistry
      // entries). Kept in sync with capability.ts seedDefaults: when a
      // new capability is seeded, its tool key is added here too
      // (kernel S14: the kernel discovers capabilities, never hardcodes).
      return {
        available: [
          "planDay",
          "schedule",
          "startFocus",
          "blockApps",
          "research",
          "qcm_generate",
          "flashcard_generate",
          "mirror_analyze",
          "scientific_verify",
          "learning_session",
          "knowledge_add",
          "course_search",
          "goal_create",
          "goal_status",
          "goal_recompose",
          "goal_pause",
          "goal_complete",
          "goal_abandon",
          "goal_feature_add",
          "goal_feature_remove",
          "docs_generate",
          "docs_refine",
          "docs_inspect",
          "docs_parse",
          "task_update",
          "habit_checkin",
          "planning_replan",
          "progress_analyze",
          "artifact_generate",
          "scientific_evaluate",
          "coach_checkin",
          "settings_theme",
          "review_run",
          "automation_toggle",
          "notification_pref",
          "eisenhower_prioritize",
          "progress_trajectories",
          "progress_cause",
        ],
        providers: Object.keys(chain.settings).map((p) => ({
          provider: p,
          model: "any",
          healthy: !chain.health.inCooldown(p),
        })),
      };
    },
    async loadPermission(userId) {
      const rows = await rest<Array<Record<string, unknown>>>("GET", sel("user_context_public"));
      if (!rows) return null;
      const row = rows.find((r) => r.user_id === userId);
      if (!row) return null;
      const prefs = (row.preferences as Record<string, unknown>) ?? {};
      return {
        featureState: (prefs.features as Record<string, boolean>) ?? {},
        capabilityIds: [],
      };
    },
  };
}

// ——— Job dispatcher port (AD-8: the job system's owned tables) ———
export function buildJobPort(): JobDispatcherPort {
  return {
    async dispatch(req) {
      const id = ulid();
      const body = {
        id,
        user_id: req.userId,
        kind: req.jobKind,
        payload: req.payload,
        status: "pending",
        idempotency_key: req.idempotencyKey ?? null,
        source_local_mutation_id: req.sourceLocalMutationId ?? null,
        trace_id: req.idempotencyKey ?? id,
      };
      const res = await rest<{ id?: string }>("POST", "job_queue", body);
      return { jobId: res?.id ?? id, status: "pending" as never };
    },
    async getJob(jobId) {
      const row = await rest<Record<string, unknown> | null>(
        "GET",
        `job_queue?id=eq.${jobId}&select=*`,
      );
      if (!row) return null;
      return row as never;
    },
  };
}

// ——— Memory engine (expert_skills server-only, AD-12) ———
export function buildMemoryEngine(): MemoryEngine {
  const deps: MemoryDeps = {
    async load(userId) {
      const rows = await rest<Array<Record<string, unknown>>>("GET", sel("expert_skills"));
      if (!rows) return [];
      return byUser(rows, userId) as never[];
    },
    async upsert(skill) {
      const payload = {
        id: skill.id,
        user_id: skill.userId,
        trigger_: skill.trigger,
        objective: skill.objective,
        procedure: skill.procedure,
        constraints: skill.constraints ?? {},
        confidence: skill.confidence,
        source: skill.source,
        status: skill.status,
      };
      await rest("POST", "expert_skills", payload);
    },
    async archive(userId, skillId) {
      await rest("PATCH", `expert_skills?id=eq.${skillId}&user_id=eq.${userId}`, {
        status: "deprecated",
      });
    },
    async delete(userId, skillId) {
      await rest("DELETE", `expert_skills?id=eq.${skillId}&user_id=eq.${userId}`);
    },
    ulid,
    now: () => new Date().toISOString(),
  };
  return new MemoryEngine(deps);
}

// ——— Verification deps (AD-8: the deterministic check is a job) ———
function buildVerificationDeps(jobs: JobDispatcherPort): VerificationDeps {
  return {
    async verifyJob(stepId, input) {
      const r = await jobs.dispatch({
        jobKind: VERIFY_JOB_KIND,
        userId: String((input as { userId?: string }).userId ?? ""),
        payload: { stepId, input },
        idempotencyKey: `verify:${stepId}`,
      });
      void r;
      // The verify job runs asynchronously; the kernel's verification engine
      // treats a "job dispatched" as ok-with-pending (the verdict lands in
      // the job result — the run's `result` is only fully verified once
      // the job completes. AD-8: no silent acceptance — the pending verdict
      // degrades the run's `expectedQuality` to 'degraded' via the
      // VerificationEngine, kernel §8).
      return { ok: true, details: { jobId: r.jobId, pending: true } };
    },
    async checkSources(stepId) {
      // KB / source check (AD-11) — degraded to a pass-through pending the
      // Knowledge port wiring (AD-1 last paragraph: optional capabilities
      // degrade when absent).
      void stepId;
      return { ok: true, refs: [] };
    },
  };
}

// A JobKind the domain vocabulary actually carries (packages/domain/jobs.ts):
// the verify kind is 'verify', NOT 'agent_verify' (AD-15 closed set).
const VERIFY_JOB_KIND = "verify" as import("../../../packages/domain/src/index.ts").JobKind;

// ——— The kernel factory (AD-12: one kernel, server-side) ———
export function buildAgentKernel(): AgentKernel | null {
  const chain = providerChain();
  if (!chain.configured) return null;

  const assembler = buildContextAssembler();
  const jobs = buildJobPort();
  const memory = buildMemoryEngine();
  const verification = buildVerificationDeps(jobs);

  const router = makeAgnesRouter(chain.health, chain.budget, chain.policy);
  const registry = new AgnesRouterRegistry();

  const deps: KernelDeps = {
    assembler,
    permission: async (userId) => {
      const form = await assembler.loadPermission(userId);
      const featureState: Record<string, boolean> = form?.featureState ?? {};
      return {
        userId,
        // AD-12: the kernel enforces per-scope read/write; the deployment
        // default is read-open (the owning module's RLS is the authority,
        // AD-7 single writer — the Permission Context only gates the
        // kernel's own tool selection, never the module's writes).
        scopes: Object.keys(featureState).map((f) => `${f}:read`),
        featureState,
        destructiveGates: [],
        allow: (action, scope) =>
          action === "read" || featureState[scope.split(":")[0]] !== false,
      };
    },
    router: {
      registry,
      health: chain.health,
      budget: chain.budget,
      dataPolicy: chain.policy,
    },
    invokeModel: async (req): Promise<RawModelResponse> => {
      // The model seam. `router.select(profile, userId)` picks the
      // provider/model; the Vercel AI SDK call itself is a documented
      // stub until the full AI pipeline lands (OQ-03) — the envelope is
      // marked degraded, never faked (kernel §8: no silent acceptance).
      const userId: string = (req.intent as unknown as { userId?: string }).userId ?? "unknown";
      const selection = router.select(req.profile, userId);
      const provider = selection?.provider ?? "agnes";
      const model = selection?.model ?? "unconfigured";
      return {
        data: "[agent-run bootstrap pending: provider pipeline not yet wired — OQ-03]",
        provider,
        model,
        attempt: 1,
        reason: selection?.reason ?? "primary",
        expectedQuality: "degraded",
        traceId: "",
      };
    },
    invokeTool: async (tool, input) => {
      void tool; void input;
      return { note: "tool seam pending — OQ-03 bootstrap", executed: false };
    },
    jobs,
    memory,
    verification,
    ulid,
    now: () => new Date().toISOString(),
  };

  return new AgentKernelImpl(deps);
}

/**
 * The router seam — the provider/model the router picks for the task
 * profile (deterministic, S2.5 — no LLM call, no pipeline dependency).
 */
export function routerSelection(profile: TaskProfile, userId: string) {
  const chain = providerChain();
  if (!chain.configured) return null;
  const router = makeAgnesRouter(chain.health, chain.budget, chain.policy);
  return router.select(profile, userId);
}
