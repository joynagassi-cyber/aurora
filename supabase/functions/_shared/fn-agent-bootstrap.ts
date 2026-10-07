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
import {
  invokeModel as invokeModelFn,
  AGENT_SYSTEM_PROMPT,
  type HealthChecker,
  type BudgetChecker,
  type DataPolicy,
  type RouterRegistry,
  type ErrorRecovery,
  type ProviderSettings,
} from "../../../packages/agent/src/model.ts";
import { KERNEL_TOOLS } from "../../../packages/agent/src/tools.ts";

// ——— Provider chain (AD-3: keys from env ONLY) ———
//
// The LLM chain (A): providers that feed the AI SDK router, in
// failover order. Cerebras is removed (no key, OQ-03). Workers AI
// (F) is wired via the CF token. Each provider = 1 primary key;
// Agnes carries a SECOND key (dual-key failover, 01 §5.6 / AD-5).
//
// Public (non-secret) config — endpoints + available models for the
// device-side model picker (AD-3: no key ever crosses this surface).
export const PROVIDER_ENDPOINTS: Record<string, string> = {
  agnes: "https://apihub.agnes-ai.com/v1",
  "workers-ai": "https://api.cloudflare.com",
  groq: "https://api.groq.com/openai/v1",
  openrouter: "https://openrouter.ai/api/v1",
};

/** The model picker catalog (device-facing, AD-3: no keys here). */
export const PROVIDER_MODEL_CATALOG: Array<{
  provider: string;
  name: string;
  role: "primary" | "fallback" | "last_resort";
  models: string[];
}> = [
  { provider: "agnes", name: "Agnes", role: "primary", models: ["agnes-3.0", "agnes-2.5-flash"] },
  {
    provider: "workers-ai",
    name: "Cloudflare Workers AI",
    role: "fallback",
    models: ["glm-4.7-flash", "gemma-4-26b", "nemotron-3-super-120b"],
  },
  { provider: "groq", name: "Groq", role: "fallback", models: ["gpt-oss-120b", "gpt-oss-20b"] },
  {
    provider: "openrouter",
    name: "OpenRouter",
    role: "last_resort",
    models: ["nemotron-3-ultra", "gemma-4"],
  },
];

interface Chain {
  settings: Record<string, ProviderSettings>;
  health: ProviderHealth;
  budget: BudgetGate;
  policy: DataPolicyGate;
  configured: boolean;
  /** providers with a key, in failover order (device picker). */
  configuredIds: string[];
}

function providerChain(): Chain {
  const settings: Record<string, ProviderSettings> = {};

  // Agnes — dual-key failover (primary + a second capacity pool, AD-5:
  // a 429 still records a cooldown; the failover key is NOT a 429 bypass).
  // The endpoint can be overridden by AGNES_ENDPOINT (the CF AI Gateway
  // custom-provider path — OQ-03: the real value is in .env.local).
  const agnesKey1 = Deno.env.get("AGNES_API_KEY_1") ?? "";
  const agnesKey2 = Deno.env.get("AGNES_API_KEY_2") ?? "";
  const agnesEndpoint =
    Deno.env.get("AGNES_ENDPOINT") || PROVIDER_ENDPOINTS["agnes"];
  if (agnesKey1 || agnesKey2) {
    settings["agnes"] = {
      name: "agnes",
      baseURL: agnesEndpoint,
      apiKey: agnesKey1 || undefined,
      apiKeyFailover: agnesKey2 || undefined,
    };
  }

  // Cloudflare Workers AI — CF token with the workers-ai scope (AD-3).
  const workersToken = Deno.env.get("CF_API_WORKERS_AI_TOKEN") ?? "";
  if (workersToken) {
    settings["workers-ai"] = { name: "workers-ai", baseURL: PROVIDER_ENDPOINTS["workers-ai"], apiKey: workersToken };
  }

  // Groq + OpenRouter — optional fallbacks (wire when a key exists).
  const groqKey = Deno.env.get("GROQ_API_KEY") ?? "";
  if (groqKey) {
    settings["groq"] = { name: "groq", baseURL: PROVIDER_ENDPOINTS["groq"], apiKey: groqKey };
  }
  const openrouterKey = Deno.env.get("OPENROUTER_API_KEY") ?? "";
  if (openrouterKey) {
    settings["openrouter"] = { name: "openrouter", baseURL: PROVIDER_ENDPOINTS["openrouter"], apiKey: openrouterKey };
  }

  return {
    settings,
    health: new ProviderHealth(),
    budget: new BudgetGate(),
    policy: new DataPolicyGate(),
    configured: Object.keys(settings).length > 0,
    configuredIds: Object.keys(settings),
  };
}

/** The kernel is bootstrap-able when at least one provider is configured. */
export function isKernelConfigured(): boolean {
  return providerChain().configured;
}

/**
 * The device-facing model picker (AD-3: public config only — no key,
 * no baseURL secret; the kernel enforces AD-5 fallback server-side).
 * `auto` = the S2.6 router picks; a provider/model pair pins the run.
 */
export function modelPicker(): Array<{ id: string; label: string; provider: string; model: string }> {
  const chain = providerChain();
  const out: Array<{ id: string; label: string; provider: string; model: string }> = [];
  out.push({ id: "auto", label: "Auto (le router choisit)", provider: "", model: "" });
  for (const entry of PROVIDER_MODEL_CATALOG) {
    if (!chain.configuredIds.includes(entry.provider)) continue; // no key → hidden
    for (const m of entry.models) {
      out.push({
        id: `${entry.provider}:${m}`,
        label: `${entry.name} · ${m}`,
        provider: entry.provider,
        model: m,
      });
    }
  }
  return out;
}

// ——— Supabase REST (service_role — env-only, AD-3) ———
// Le secret service_role est stocké sous SERVICE_ROLE_KEY (Supabase refuse
// tout nom commençant par SUPABASE_). La valeur peut être une clé legacy
// JWT ("eyJ...") ou moderne ("sb_secret_...") : pour la moderne, ne
// l'envoyer QUE sur le header apikey (pas Authorization).
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";
function restHeaders(): Record<string, string> {
  const isLegacyJwt = SERVICE_ROLE_KEY.startsWith("eyJ");
  const h: Record<string, string> = { "Content-Type": "application/json" };
  if (!SERVICE_ROLE_KEY) return h;
  h.apikey = SERVICE_ROLE_KEY;
  if (isLegacyJwt) {
    h.Authorization = `Bearer ${SERVICE_ROLE_KEY}`;
  }
  return h;
}

async function rest<T>(method: string, path: string, body?: unknown): Promise<T | null> {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return null;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method,
    headers: restHeaders(),
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
    // Task 1/2 (2026-10-04): the user's ACTIVE skills (user_skills, migration
    // 0019). Builtin rows carry the catalog payload (procedure/constraints/
    // tools are copied at activation, see fn-skills activate_skill); user-
    // created rows are self-contained. Feeds prompt layer 1. Degrades to []
    // when the table is absent (AD-1: the kernel loop continues).
    async loadUserSkills(userId) {
      const rows = await rest<Array<Record<string, unknown>>>("GET", sel("user_skills"));
      if (!rows) return [];
      return byUser(rows, userId).filter((r) => r.active === true);
    },
    // 0021 marketplace: the GLOBAL skill_catalog index (compact — key + name
    // + domain + trigger only, never the markdown body). Feeds prompt
    // layer 2.5 so the model knows WHICH skills exist without polluting the
    // context with 600 bodies; the agent picks one via skill_search, then
    // loads the full SKILL.md via skill_get (the server-side fn-skills EF).
    // Public table (AD-3 read-open), no user filter needed.
    async loadSkillCatalogIndex() {
      const rows = await rest<
        Array<{ skill_key: string; name: string; domain: string; trigger_: string | null }>
      >(
        "GET",
        "skill_catalog?select=skill_key,name,domain,trigger_&limit=600",
      );
      if (!rows) return [];
      return rows;
    },
    async loadToolContext(userId) {
      void userId;
      const chain = providerChain();
      // The available tools = the canonical tool-id set the kernel's
      // Planner / Tool Resolver address steps by (packages/agent/src/tools.ts
      // KERNEL_TOOLS, the tool field of the DefaultCapabilityRegistry
      // entries). Derived, never hand-typed: `Object.keys(KERNEL_TOOLS)`
      // is the single source of truth — when a new capability is seeded in
      // capability.ts, its tool key lands in tools.ts first, so this list
      // stays in sync automatically (kernel S14: the kernel discovers
      // capabilities, never hardcodes).
      return {
        available: Object.keys(KERNEL_TOOLS),
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
      const userId: string =
        req.intent?.userId ?? (req.intent as unknown as { userId?: string })?.userId ?? "unknown";
      // The REAL model seam (OQ-03): the Vercel AI SDK call over the S2.6
      // chain (Agnes dual-key → Workers AI → Groq → OpenRouter).
      // `thinkingLevel` → reasoningEffort; `researchMode` → pre-fetch;
      // `agentMode='mirror'` → expert-skill learning loop (ADR S14).
      //
      // Task 1/2 — prompt layering: the context forms carry the user's
      // active skills (form 10) and expert skills (form 7). We surface them
      // here so invokeModelReal can assemble the layered system prompt
      // (layer 1 = user_skills, layer 2 = expert_skills, layer 3 = ctx).
      const ctx = req.ctx as Record<string, unknown> | undefined;
      const skillsForm = (ctx?.skills ?? {}) as Record<string, unknown>;
      const expertForm = (ctx?.expertSkills ?? {}) as Record<string, unknown>;
      const activeSkills = Array.isArray(skillsForm.active)
        ? (skillsForm.active as ModelCall["activeSkills"])
        : undefined;
      const expertSkillIds = Array.isArray(expertForm.active) ? (expertForm.active as string[]) : [];
      // 0021 marketplace — catalog index (form 11): compact, no body. The
      // context form carries the index; invokeModelReal inlines it as
      // layer 2.5 so the model knows which skills exist before picking one.
      const catalogForm = (ctx?.catalog ?? {}) as Record<string, unknown>;
      const catalogIndex = Array.isArray(catalogForm.index)
        ? (catalogForm.index as ModelCall["catalogIndex"])
        : undefined;
      return invokeModelReal({
        registry,
        health: chain.health,
        budget: chain.budget,
        dataPolicy: chain.policy,
        settings: chain.settings,
        onResearch: undefined, // research jobs dispatch via the tool layer; the kernel's invokeModel seam keeps the S2.6 chain surface
      }, {
        profile: req.profile,
        prompt: JSON.stringify({ intent: req.intent, plan: req.plan, ctx: req.ctx }),
        traceId: ulid(),
        userId,
        activeSkills,
        // Layer 2 at the ID level (token economy: the full expert-skill
        // procedure is NOT inlined — the Planner + Tool Registry already
        // carry the capability details, matching today's ID-level form 7).
        expertSkills: expertSkillIds.map((id) => ({ id })),
        // Layer 2.5 — 0021 marketplace catalog index (compact, no body).
        catalogIndex,
      });
    },
    invokeTool: async (tool, input) => {
      // OQ-03 seam — route les commandes canvas.* vers fn-canvas (le module
      // Canvas = single-writer AD-7 qui applique la mutation sur canvas_*) ;
      // les autres commandes restent le no-op documenté (AD-8 : pas de
      // perte, le module concerné n'existe pas encore côté serveur).
      //
      // L'identité (userId) est portée par le PAYLOAD de l'outil canvas
      // (AD-7 : le kernel l'injecte depuis le contexte courant ; l'EF fn-canvas
      // ne fait JAMAIS confiance au body pour l'identité — ici le payload est
      // le contexte kernel, pas le body HTTP).
      const payload = (input?.payload ?? input) as Record<string, unknown>;
      const cmd = (payload?.command ?? tool) as string;
      const userId = (payload?.userId as string | undefined) ?? '';
      if (typeof cmd === 'string' && cmd.startsWith('canvas.')) {
        const verb = cmd === 'canvas.read' ? 'read' : cmd === 'canvas.write' ? 'write' : cmd === 'canvas.comment' ? 'comment' : cmd === 'canvas.create' ? 'create' : cmd === 'canvas.lock' ? 'lock' : cmd === 'canvas.rename' ? 'rename' : null;
        if (verb && userId) {
          // Le body fn-canvas = verb + champs outils, SANS userId (l'identité
          // vient du Bearer user JWT — AD-7 : jamais du body).
          const { userId: _omit, command: _omitCmd, ...canvasBody } = payload;
          const res = await fetch(SUPABASE_URL + '/functions/v1/fn-canvas', {
            method: 'POST',
            headers: { ...restHeaders(), Authorization: `Bearer ${userId}`, apikey: SERVICE_ROLE_KEY },
            body: JSON.stringify({ verb, ...canvasBody }),
          });
          if (res.ok) {
            return { ...(await res.json()), executed: true };
          }
          return { ok: false, executed: false, error: `fn-canvas ${res.status}` };
        }
      }
      return { note: `tool seam pending — OQ-03 bootstrap (cmd: ${cmd ?? 'unknown'})`, executed: false };
    },
    jobs,
    memory,
    verification,
    ulid,
    now: () => new Date().toISOString(),
  };

  return new AgentKernelImpl(deps);
}

/** The thinking-level → OpenAI-compatible `reasoning_effort` mapping. */
const THINKING_EFFORT: Record<TaskProfile['thinkingLevel'], string> = {
  low: 'minimal',
  medium: 'medium',
  high: 'high',
  max: 'xhigh',
};

/**
 * The model seam (OQ-03): the REAL Vercel AI SDK call over the 5-provider
 * S2.6 chain (Agnes dual-key → Workers AI → Groq → OpenRouter).
 *
 * `thinkingLevel` (TaskProfile, device picker) drives the `reasoningEffort`
 * provider option — the OpenAI-compatible SDK surfaces it under
 * `providerOptions.openaiCompatible.reasoningEffort` (the exact field name
 * the SDK schema accepts; non-reasoning models ignore it gracefully).
 *
 * `agentMode`:
 *   - 'mirror' → the expert-skill learning loop (ADR S14) wraps the call;
 *   - 'ascent' → the Slide-Ascent pedagogy prelude (docs/ascent/overview S12);
 *   - 'chat'   → single-round, no agentic tool loop;
 *   - 'agent'  → the full agentic loop (maxSteps cap applies).
 *
 * `researchMode`:
 *   - 'deep'   → dispatch a `research` job (Exa/Tavily/You.com) before the
 *                 model call; the sources are appended to the system prompt;
 *   - 'standard' → one round of retrieval;
 *   - 'off'    → no research.
 */
async function invokeModelReal(
  deps: InvokeModelDeps,
  call: ModelCall,
): Promise<RawModelResponse> {
  const profile = call.profile;
  const thinking = profile.thinkingLevel ?? 'medium';
  const research = profile.researchMode ?? 'off';
  const mode = profile.agentMode ?? 'agent';

  // — Research (pre-fetch, 01 §6.1; AD-8: dispatch when the profile demands) —
  let researchContext = '';
  if (research !== 'off' && deps.onResearch) {
    const sources = await deps.onResearch(research, call);
    researchContext = sources.length
      ? `\n\n## Research (pre-fetched, ${research} mode)\n${sources
          .map((s) => `- ${s.title ?? s.url}: ${s.snippet ?? ''}`)
          .join('\n')}`
      : '';
  }

  // — Mirror-mode prelude (ADR S14: user-teaches-AI, before the model call) —
  const mirrorPrelude =
    mode === 'mirror' ? '\n\n(Le mode miroir est actif : l\'utilisateur t\'enseigne ce qu\'il a appris. Structure ce qu\'il dit en expert-skill : déclencheur, objectif, procédure, contrainte. N\'invente rien : reformule uniquement.)' : '';

  // — Ascent-mode prelude (docs/ascent/overview S12: the agent CONDUCTS the
  //    Slide-Ascent climb; the /ascent page only READS the resulting path) —
  const ascentPrelude =
    mode === 'ascent' ? '\n\n(Le mode Ascent est actif : tu conduis la montée pédagogique. Explique le concept en cours avec des analogies (toujours labellisées), propose l\'activité à faire, diagnostique si l\'utilisateur bloque (style Miroir), et structure le résultat comme un chemin d\'ascension que la page /ascent affichera. N\'improvise pas le corpus : reformule ce que l\'utilisateur maîtrise déjà.)' : '';

  // — Task 1/2 (2026-10-04): prompt layering —
  // Layer 0 = AGENT_SYSTEM_PROMPT (identity, fixed).
  // Layer 1 = active user skills (user_skills, self-contained rows).
  // Layer 2 = expert skills (ID-level, token economy).
  // Layer 3/4 = research pre-fetch + mirror prelude (existing).
  // Each layer is '' when empty — assembly order is deterministic.
  const skillsLayer = call.activeSkills?.length
    ? '\n\n[SKILLS ACTIVES]\n' +
      call.activeSkills
        .slice(0, 8) // hard cap: 8 skills max in-prompt (token budget)
        .map((s) => {
          const head = `• ${s.name ?? s.key} (domaine: ${s.domain ?? '—'})`;
          const trigger = s.trigger ? ` Déclencheur : ${s.trigger}.` : '';
          const obj = s.objective ? ` Objectif : ${s.objective}.` : '';
          const proc = s.procedure.length ? ` Procédure : ${s.procedure.join(' → ')}.` : '';
          const cons = s.constraints.length ? ` Contraintes : ${s.constraints.join(' ; ')}.` : '';
          // 0021 marketplace seed: when the row carries a full markdown SKILL.md
          // body (marketplace source), it inlines the procedure in place of the
          // meta summary — the body IS the skill (prompt-only skills have empty
          // procedure/constraints/tools by design).
          const bodySection = s.body
            ? `\n\n${s.body}\n`
            : proc + cons;
          return head + trigger + obj + bodySection;
        })
        .join('\n')
    : '';
  const expertLayer = call.expertSkills?.length
    ? '\n\n[SKILLS EXPERTES (acquises)]\n' +
      call.expertSkills
        .slice(0, 10)
        .map((s) => {
          const conf = typeof s.confidence === 'number' ? ` (${Math.round(s.confidence * 100)}%)` : '';
          const trig = s.trigger ? ` : ${s.trigger}` : '';
          const obj = s.objective ? ` → ${s.objective}` : '';
          return `- ${s.key ?? s.id}${conf}${trig}${obj}`;
        })
        .join('\n')
    : '';

  // — 0021 marketplace: prompt layer 2.5 — the global skill_catalog index
  //    (compact: key + name + domain + trigger, no body). The model sees
  //    WHICH skills exist and can call skill_search to narrow the set, then
  //    skill_get to load the full SKILL.md procedure for the chosen one.
  //    Grouped by domain so the list is scannable; the body is NEVER inlined.
  const catalogLayer = call.catalogIndex?.length
    ? '\n\n[CATALOGUE DE SKILLS (index compact — utiliser skill_search puis skill_get)]\n' +
      call.catalogIndex
        .slice(0, 200) // cap the index: 200 rows ≈ 40KB, token budget friendly
        .map(
          (s) =>
            `- ${s.key} [${s.domain}] ${s.name}${s.trigger ? ` — ${s.trigger}` : ''}`,
        )
        .join('\n') +
      '\n→ Pour chaque cas, appelle `skill_search` (query + domaine) pour trouver le skill adapté, puis `skill_get` (skillKey) pour charger sa procédure complète avant d\'agir.'
    : '';

  const systemPrompt =
    `${AGENT_SYSTEM_PROMPT}` +
    skillsLayer +
    expertLayer +
    catalogLayer +
    researchContext +
    mirrorPrelude +
    ascentPrelude;

  const res = await invokeModelFn(
    {
      registry: deps.registry,
      health: deps.health,
      budget: deps.budget,
      dataPolicy: deps.dataPolicy,
      settings: deps.settings,
      recovery: deps.recovery,
    },
    {
      profile,
      system: systemPrompt,
      prompt: call.prompt,
      traceId: call.traceId,
      userId: call.userId,
    },
  );

  return {
    data: res.data,
    provider: res.provider,
    model: res.model,
    attempt: res.attempt,
    reason: res.reason,
    expectedQuality: res.expectedQuality,
    traceId: res.traceId,
    // AD-16d observability: which device preferences drove the call
    meta: {
      thinkingLevel: thinking,
      reasoningEffort: THINKING_EFFORT[thinking],
      researchMode: research,
      agentMode: mode,
      fallbackUsed: res.fallbackUsed,
      researchSources: researchContext.length,
    },
  };
}

/**
 * The invokeModel seam (OQ-03) — the REAL Vercel AI SDK call.
 *
 * The S2.6 router picks the provider/model; if the device's model picker
 * pinned one (taskProfile.preferredProvider), the router returns it FIRST,
 * and AD-5 fallback still applies if that provider is in cooldown / down.
 *
 * The thinking level (taskProfile.thinkingLevel) sets the Vercel AI SDK
 * reasoning effort: low = fast, medium = balanced, high = deep reasoning,
 * max = full CoT + tool use.
 * researchMode = 'deep' escalates to a multi-round research job (01 §6.1)
 * before the main model call; 'standard' = one round.
 * agentMode = 'mirror' triggers the expert-skill learning loop (ADR S14):
 * the user's explanation is structured as a skill draft.
 */
export interface InvokeModelDeps {
  registry: RouterRegistry;
  health: HealthChecker;
  budget: BudgetChecker;
  dataPolicy: DataPolicy;
  settings: Record<string, ProviderSettings | undefined>;
  recovery?: ErrorRecovery;
  /** Research hook: (mode, call) → fetched sources (Exa/Tavily/You.com). */
  onResearch?: (
    mode: 'standard' | 'deep',
    call: ModelCall,
  ) => Promise<Array<{ title?: string; url: string; snippet?: string }>>;
}

export interface ModelCall {
  profile: TaskProfile;
  prompt: string;
  traceId: string;
  userId: string;
  /**
   * Task 1/2 — prompt layer 1: the user's ACTIVE skills (user_skills rows,
   * self-contained: key/name/trigger/objective/procedure/constraints/tools).
   * Absent → layer 1 renders empty (AD-1: the call proceeds without skills).
   */
  activeSkills?: Array<{
    key: string;
    domain?: string;
    name?: string;
    trigger?: string | null;
    objective?: string | null;
    procedure: string[];
    constraints: string[];
    tools: string[];
    /** 0021 marketplace seed: full markdown SKILL.md body (null for builtin/user-created). */
    body?: string | null;
  }>;
  /** Task 2 — prompt layer 2: active expert skills (ID + trigger + objective + confidence). */
  expertSkills?: Array<{
    id: string;
    key?: string;
    trigger?: string;
    objective?: string;
    confidence?: number;
  }>;
  /**
   * 0021 marketplace — prompt layer 2.5: the global skill_catalog index
   * (compact: skill_key + name + domain + trigger only, NO body). Let the
   * model know which skills exist so it can call skill_search / skill_get
   * to load details; the bodies are fetched on demand, not inlined here.
   */
  catalogIndex?: Array<{
    key: string;
    name: string;
    domain: string;
    trigger: string;
  }>;
}
