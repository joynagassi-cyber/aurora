/**
 * Vercel AI SDK — the 8 kernel tools (vercel-ai-sdk-integration.md, wave 3 task 2).
 *
 * AD-1 boundary: this file is the ONLY place in the monorepo that
 * imports the Vercel `ai` SDK (verified by the CI grep test, 01 S7).
 * The 8 tools are typed `tool()` definitions the kernel's Execution
 * Engine hands to `streamText` / `generateText` (maxSteps=5, the
 * 02 S4 streaming surface).
 *
 * Each tool is a THIN adapter: it calls the owning module's command /
 * port (AD-7 single-writer: the kernel never writes a module table —
 * it emits commands; the owning module applies the mutation). Heavy
 * tools (research, qcm_generate, mirror_analyze, scientific_verify)
 * return a job id — the work persists in `job_queue` (AD-8), the
 * dispatcher runs it, the result is observable via `job_queue` /
 * `JobCompleted` (AD-9, F-08).
 *
 * Zero provider keys here (AD-3): the SDK layer only ever sees the
 * `LanguageModel` instance the router built; keys live in the server
 * secret store.
 */
import { tool, type Tool } from 'ai';
import { z } from 'zod';

/**
 * The SDK's `Tool` union (FunctionTool | DynamicTool | …) is not
 * portable through this package's declaration emit (the SDK re-exports
 * it from nested @ai-sdk sub-packages, TS2742). Every `tool()` result
 * below is a FunctionTool-shaped object, so we name it via the SDK's
 * exported `Tool` alias with `any` type args — `any` keeps the input /
 * output positions covariant, so each concrete tool's inferred type is
 * assignable without re-exporting transitive SDK types.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- TS2742: the SDK Tool union is not portable through declaration emit (see the doc block above); `any` keeps each concrete tool assignable.
type KernelTool = Tool<any, any>;

/**
 * The 8 kernel tools (capability-catalog S2 / feature-agentability-matrix)
 * + the 7 goal capabilities (dynamic-goal-engine.md). Input schemas are
 * the minimal declared inputs (kernel S14: "typed input (validated before
 * execution)").
 */

/** 1. planDay — compose the day plan (planning.daily → Productivity command). */
export const planDay: KernelTool = tool({
  description: 'Compose the day plan: time-block today + order open tasks (planning.daily).',
  inputSchema: z.object({
    examPeriod: z.boolean().optional(),
    /** the user's declared energy today (low/medium/high) — drives session length */
    energyLevel: z.enum(['low', 'medium', 'high']).optional(),
    /** course ids to reserve blocks for */
    courseIds: z.array(z.string()).optional(),
  }),
  execute: async (input) => {
    // AD-7: emit the Productivity command; the module applies the write.
    // The command bus (kernel S15) routes this to planning.daily.
    return { ok: true, command: 'productivity.plan_day', payload: input };
  },
});

/** 2. schedule — schedule / reorder a time block (calendar.schedule → EventUpdateCommand). */
export const schedule: KernelTool = tool({
  description: 'Schedule or reorder a time block on the calendar (calendar.schedule).',
  inputSchema: z.object({
    /** the subject / task to schedule */
    subject: z.string(),
    /** ISO 8601 start */
    startAt: z.string(),
    /** duration in minutes */
    durationMin: z.number().int().positive(),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.event_update', payload: input }),
});

/** 3. startFocus — start a focus session (focus.start → FocusController, ADR S5 confirmation). */
export const startFocus: KernelTool = tool({
  description: 'Start a focus session (timer + optional blocklist). Important action — confirmation required (ADR S5).',
  inputSchema: z.object({
    /** planned duration in minutes */
    durationMin: z.number().int().positive().default(25),
    /** linked task ids */
    taskIds: z.array(z.string()).optional(),
    /** the notification policy id */
    notificationPolicy: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.start', payload: input }),
});

/** 4. blockApps — block apps during focus (focus.block → DpcAdapter, v1.8 DPC). */
export const blockApps: KernelTool = tool({
  description: 'Suspend the blocklist packages for a focus session (focus.block). DPC-provisioned (OQ-17); degrades to restriction-only when DPC is absent.',
  inputSchema: z.object({
    /** package names to suspend */
    packages: z.array(z.string()),
    /** true = suspend, false = restore (S7 total restore) */
    suspend: z.boolean().default(true),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.blocklist', payload: input }),
});

/** 5. research — run a typed multi-source research query (ResearchProvider port). */
export const research: KernelTool = tool({
  description: 'Run a typed multi-source research query (You.com / Tavily / Exa via the ResearchProvider port). Returns a job id — the work persists in job_queue (AD-8).',
  inputSchema: z.object({
    topic: z.string(),
    domains: z.array(z.string()).default([]),
    kinds: z.array(
      z.enum(['academic', 'scientific', 'technical', 'professional', 'technological', 'other']),
    ).default(['other']),
    region: z.string().optional(),
  }),
  execute: async (input) => {
    // Heavy step → persisted `research` job (AD-8). The dispatcher runs
    // the ResearchProvider; the result is observable via job_queue /
    // JobCompleted (F-08: jobId + jobKind mandatory).
    return { ok: true, jobKind: 'research', payload: input, idempotencyKey: `research:${input.topic}` };
  },
});

/** 6. qcm_generate — generate QCM items for a skill (Learning → artifact_gen job). */
export const qcmGenerate: KernelTool = tool({
  description: 'Generate QCM items for a skill / course (Learning). Heavy step → artifact_gen job (AD-8); the items render via the AD-10 engines when the artifact lands.',
  inputSchema: z.object({
    /** the skill / course the QCM targets */
    skillId: z.string(),
    /** difficulty ladder position (QcmService) */
    difficulty: z.enum(['easy', 'medium', 'hard', 'adaptive']).optional(),
    /** number of items */
    count: z.number().int().positive().default(5),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'artifact_gen', payload: input }),
});

/** 7. mirror_analyze — cognitive mirror analysis of a session (agent_run job). */
export const mirrorAnalyze: KernelTool = tool({
  description: 'Run the cognitive mirror on a learning session: claims vs the semantic tree (Learning + Knowledge). Heavy step → agent_run job (AD-8).',
  inputSchema: z.object({
    /** the transcript of the session */
    transcript: z.string(),
    /** the declared claims to check */
    claims: z.array(z.string()).default([]),
    /** the subject / course id */
    subjectId: z.string().optional(),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'agent_run',
    payload: { capability: 'mirror_cognitive', ...input },
  }),
});

/** 8. scientific_verify — deterministic scientific / engineering verification (ScientificEngine, job). */
export const scientificVerify: KernelTool = tool({
  description: 'Deterministic verification of a scientific / engineering result (ScientificEngine, AD-10). The LLM does NOT solve it — it structures + the solver computes + the verifier validates (engineering-intelligence-layer S1). Heavy step → scientific job (AD-8).',
  inputSchema: z.object({
    /** the domain (math | rdm | concrete | hydraulics | geotech | …) */
    domain: z.string(),
    /** the problem type */
    problemType: z.string(),
    /** typed inputs ({ value, unit } — NEVER a bare number) */
    inputs: z.array(z.object({ key: z.string(), value: z.number(), unit: z.string() })),
    /** requested outputs */
    requestedOutputs: z.array(z.string()).default([]),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'scientific', payload: input }),
});

// ---------------------------------------------------------------------------
// Goal capabilities — the 7 agent goal commands (dynamic-goal-engine.md
// "Agent capabilities"). AD-7: the kernel NEVER writes a module table.
// The GoalProject row is Progress-owned (user_goals, F-07) — every tool
// below EMITS a typed `goal.*` command on the command bus; the Progress
// module applies the mutation and persists it. `goal.create` is
// CONFIRMATION_REQUIRED (the user sees the plan before it goes active);
// decomposition is the LLM step (the `goalDecomposition` payload), the
// assembly/validation is @aurora/goal-engine (the caller wires it, or the
// Progress module re-validates — the shape is the same frozen AD-15 type).
// ---------------------------------------------------------------------------

/** goal.create — NL objective -> GoalProject (CONFIRMATION_REQUIRED, dynamic-goal-engine.md). */
export const goalCreate: KernelTool = tool({
  description:
    'Create a GoalProject from a natural-language objective: decompose into sub-goals + feature placements, assemble the plan. CONFIRMATION_REQUIRED — the user sees the plan before it is active.',
  inputSchema: z.object({
    /** the NL goal, verbatim */
    objective: z.string(),
    /** the typed decomposition (the LLM step's output — GoalDecomposition, @aurora/goal-engine) */
    goalDecomposition: z.record(z.unknown()),
  }),
  execute: async (input) => {
    // AD-7: emit the command; the Progress module applies + persists
    // (user_goals) and confirms with the user before activation.
    return { ok: true, command: 'goal.create', payload: input };
  },
});

/** goal.status — read the GoalProject + GoalProgress (read-only). */
export const goalStatus: KernelTool = tool({
  description: 'Read a GoalProject with its progress snapshot (GoalProject + GoalProgress).',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.status', payload: input };
  },
});

/** goal.recompose — ADR S13: re-plan without destroying history. */
export const goalRecompose: KernelTool = tool({
  description:
    'Re-plan a GoalProject when progress stalls or context changes (ADR S13: recalcul du planning restant sans détruire l\'historique).',
  inputSchema: z.object({
    goalId: z.string(),
    /** the new decomposition (same shape as goal.create) */
    goalDecomposition: z.record(z.unknown()),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.recompose', payload: input };
  },
});

/** goal.pause — jobs stop, notifications mute (AD-7: data mutation by Progress). */
export const goalPause: KernelTool = tool({
  description: 'Pause a GoalProject: active features stop (jobs stop, notifications mute). Progress + history are preserved.',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.pause', payload: input };
  },
});

/** goal.complete — the Progress module checks the success criteria (F-07). */
export const goalComplete: KernelTool = tool({
  description:
    'Mark a GoalProject complete — only when the success criteria are met. The check + evidence are Progress-owned (F-07 sole producer of ProgressEvidenceCreated).',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.complete', payload: input };
  },
});

/** goal.abandon — data preserved, features deactivated (AD-15 additive). */
export const goalAbandon: KernelTool = tool({
  description:
    'Abandon a GoalProject: the row + all progress/history are preserved (AD-15), the goal\'s features are deactivated.',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.abandon', payload: input };
  },
});

/** goal.feature.add — "et ajoute des QCM chaque semaine". */
export const goalFeatureAdd: KernelTool = tool({
  description:
    'Add a feature to an active GoalProject\'s composition ("ajoute des QCM chaque semaine").',
  inputSchema: z.object({
    goalId: z.string(),
    featureId: z.string(),
    /** optional: attach the feature to a specific sub-goal */
    subGoalId: z.string().optional(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.feature.add', payload: input };
  },
});

/** goal.feature.remove — "plus besoin de focus sur ce but". */
export const goalFeatureRemove: KernelTool = tool({
  description: 'Remove a feature from an active GoalProject\'s composition ("plus besoin de focus sur ce but").',
  inputSchema: z.object({
    goalId: z.string(),
    featureId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.feature.remove', payload: input };
  },
});

// ---------------------------------------------------------------------------
// Document tools (docs/agent/document-tools.md) — the 4 docs.* capabilities,
// two strict directions (NEVER mixed, document-tools S4):
//   TEXT→DOC : docs_generate (Pandoc, whole-document) + docs_refine
//              (python-docx, surgical precision on an existing .docx)
//   DOC→TEXT : docs_inspect (mammoth, quick .docx read) + docs_parse
//              (Docling, complex multi-format read incl. tables)
// All heavy steps = persisted `artifact_gen` jobs (AD-8; the kind
// vocabulary is unchanged — the discriminator is payload.docTool).
// Generated / refined / parsed outputs land as NEW artifact rows
// (blobs immutable, artifacts §24 supersedes) — `ArtifactGenerated`
// only post-R2 (F-06).
// ---------------------------------------------------------------------------

/** docs.generate — LLM Markdown → .docx/.pdf/.pptx/.html/.epub (Pandoc, AD-8 job). */
export const docsGenerate: KernelTool = tool({
  description:
    'Generate a FULL document from Markdown (Pandoc): docx / pdf / pptx / html / epub. Optional templateId (--reference-doc corporate styles); Mermaid blocks render as images. Whole-document generation ONLY — to parse an existing document use docs.parse / docs.inspect. Heavy step → artifact_gen job (AD-8); the artifact lands in the Artifact Hub (F-06, post-R2 only).',
  inputSchema: z.object({
    /** the LLM-authored Markdown source */
    markdown: z.string(),
    /** target format */
    outputFormat: z.enum(['docx', 'pdf', 'pptx', 'html', 'epub']).default('docx'),
    /** a --reference-doc template id (corporate style), optional */
    templateId: z.string().optional(),
    /** render embedded Mermaid blocks as images (pandoc Lua filter) */
    renderMermaid: z.boolean().optional(),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'artifact_gen',
    payload: { docTool: 'pandoc', ...input },
    // null-safe: direct execute() calls bypass zod .default() (test path).
    idempotencyKey: `doc:pandoc:${input.outputFormat ?? 'docx'}`,
  }),
});

/** docs.refine — surgical .docx precision (python-docx, new revision). */
export const docsRefine: KernelTool = tool({
  description:
    'Surgical, pixel-precise edits on an EXISTING .docx (python-docx): complex data tables, invoices, dynamic styles, targeted text replacement. NOT for first-time whole-document generation (use docs.generate). Output = a NEW artifact revision (supersedes; source blob immutable, artifacts §24). Heavy step → artifact_gen job (AD-8).',
  inputSchema: z.object({
    /** the artifact to refine (presigned fetch — no client-held keys, AD-3) */
    artifactId: z.string(),
    /** typed edit operations (table fill, style patch, section replace) */
    operations: z.array(z.record(z.unknown())).min(1),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'artifact_gen',
    payload: { docTool: 'python-docx', ...input },
    idempotencyKey: `doc:refine:${input.artifactId}`,
  }),
});

/** docs.inspect — quick read of an existing .docx (mammoth, read-only, light). */
export const docsInspect: KernelTool = tool({
  description:
    'Quickly read / inspect an existing .docx (mammoth): clean Markdown/HTML of the content + structure outline + typo scan. READ-ONLY, .docx ONLY — for PDF / PPTX / XLSX / scanned documents use docs.parse. Light artifact_gen job (AD-8); the parsed representation is stored as a new artifact row linked to the source (provenance).',
  inputSchema: z.object({
    /** the artifact to inspect (presigned fetch, AD-3) */
    artifactId: z.string(),
    /** output mode */
    mode: z.enum(['markdown', 'html', 'outline']).default('markdown'),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'artifact_gen',
    payload: { docTool: 'mammoth', ...input },
    idempotencyKey: `doc:inspect:${input.artifactId}:${input.mode ?? 'markdown'}`,
  }),
});

/** docs.parse — complex document → structured Markdown/JSON (Docling, heavy). */
export const docsParse: KernelTool = tool({
  description:
    'Parse a COMPLEX existing document (Docling): scanned or native PDF, PPTX, XLSX, HTML, images → clean structured Markdown / JSON, with faithful multi-page table reconstruction. READ-ONLY, DOC→TEXT direction only — it never generates documents (that is docs.generate). Heavy model-inference step → artifact_gen job (AD-8). Degraded fallback: pandoc text extraction (degraded flag, AD-5); raw photo / low-quality scan → ocr job pipeline.',
  inputSchema: z.object({
    /** the source artifact (presigned fetch, AD-3) */
    artifactId: z.string(),
    /** output format for the parsed representation */
    format: z.enum(['markdown', 'json', 'html']).default('markdown'),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'artifact_gen',
    payload: { docTool: 'docling', ...input },
    idempotencyKey: `doc:parse:${input.artifactId}:${input.format ?? 'markdown'}`,
  }),
});

// ---------------------------------------------------------------------------
// Canvas tools (0022) — "le canvas est utilisé par l'agent, pas par
// l'humain" : l'humain reste éditeur de /canvas (StarterKit), l'agent
// POUVOIR lire / écrire / commenter la session canvas via le kernel.
//
// AD-7 single-writer : le kernel NE MODIFIE JAMAIS directement une table
// module. Chaque outil EMIT une commande typée `canvas.*` ; le module
// Canvas (le device-side client canvas-client.ts, ou un futur endpoint
// serveur si on en a besoin) applique la mutation. L'humain et l'agent
// écrivent la même table — l'agent passe par le kernel, l'humain par le
// client device. Pas de job (ops light, AD-1 "light ops local") ;
// canvas_write reste une op de modification de contenu → confirmation
// portée par le risk du planStep (pattern planner), pas un flag dédié
// dans l'outil.
// ---------------------------------------------------------------------------

/** canvas_read — lit la session canvas courante (bloc + commentaires) pour l'agent. */
export const canvasRead: KernelTool = tool({
  description:
    "Read the current canvas session (blocks + comments) for the agent to 'visualiser' une session d'artefact (spec originale, partie 4). The canvas is the SSoT (markdown par bloc, 0022). READ-ONLY, thin command (AD-7 : le module Canvas lit sa propre table) ; pas de job. Le payload porte userId (injecté par le kernel, AD-7 identity from context, jamais du body).",
  inputSchema: z.object({
    canvasId: z.string(),
    includeComments: z.boolean().default(true),
    /** l'identité du user courant (portée par le kernel, AD-7 : l'EF ne fait jamais confiance au body). */
    userId: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'canvas.read', payload: input }),
});

/**
 * canvas_write — écrit un bloc markdown dans une session canvas (l'agent
 * propose / modifie le contenu). AD-7 : le module Canvas applique la
 * mutation. Overwrite = confirmation via le risk du planStep (le
 * planner, pas l'outil). Le canvas reste la SSoT (markdown par bloc,
 * 0022) ; l'agent écrit via cette commande, le module applique la
 * mutation (AD-7). L'humain garde l'accès d'édition dans /canvas
 * (StarterKit) — les deux écrivent la même table, l'agent passe par
 * le kernel, l'humain par le client device.
 */
export const canvasWrite: KernelTool = tool({
  description:
    "Écrit / remplace un bloc markdown dans une session canvas (l'agent propose, modifie ou crée le contenu d'un bloc). canvas = SSoT (markdown par bloc, 0022). AD-7 : le kernel émet la commande ; le module Canvas (endpoint fn-canvas) applique la mutation. Overwrite = confirmation via le risk du planStep (pas de flag dédié ici). Le payload porte userId (injecté par le kernel, AD-7 : l'EF ne fait jamais confiance au body).",
  inputSchema: z.object({
    canvasId: z.string(),
    blockId: z.string().optional(),
    markdown: z.string(),
    /** l'identité du user courant (portée par le kernel, AD-7 : l'EF ne fait jamais confiance au body). */
    userId: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'canvas.write', payload: input }),
});

/**
 * canvas_comment — crée / répond à un commentaire ancré sur une
 * sélection du canvas (canvas_comments, anchor_start / anchor_end,
 * 0022). replyToCommentId présent = réponse à un commentaire
 * existant ; absent = nouveau commentaire. AD-7, light (pas de job).
 */
export const canvasComment: KernelTool = tool({
  description:
    "Crée ou répond à un commentaire ancré sur une sélection du canvas (canvas_comments : anchor_start / anchor_end dans le texte plat de la session, 0022). replyToCommentId présent = réponse ; absent = nouveau commentaire. AD-7 : le module Canvas (endpoint fn-canvas) applique (pas de job, op light, non-destructive). Le payload porte userId (injecté par le kernel, AD-7 : l'EF ne fait jamais confiance au body).",
  inputSchema: z.object({
    canvasId: z.string(),
    replyToCommentId: z.string().optional(),
    body: z.string(),
    /** l'identité du user courant (portée par le kernel, AD-7 : l'EF ne fait jamais confiance au body). */
    userId: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'canvas.comment', payload: input }),
});

// ---------------------------------------------------------------------------
// Feature-agentability-matrix.md — the remaining agentable families.
//
// Each tool is a THIN AD-7 command / AD-8 job emitter: the kernel NEVER
// writes a module table — it emits a typed `<module>.<action>` command
// (the owning module applies the mutation) or persists a job (the
// dispatcher runs it). The owning module per family:
//   Productivity  : task / habit / review / eisenhower / planning.replan
//   Learning      : course.search / flashcard / learning.session / import
//   Knowledge     : knowledge.add (OCR / ingest)
//   Progress      : progress.analyze / trajectories / cause
//   Artifact      : artifact.generate / preview (deep-link only, user-only read)
//   Scientific    : scientific.evaluate (light, offline-capable sibling of
//                   the heavy scientific.verify job)
//   Identity      : settings.theme / preferences (user_context commands)
//   Integrations  : integrations.automation.toggle, notification.*
//                   (Composio / OneSignal vendor SDKs, AD-1)
//   Agent (coach) : coach.checkin (proactive, cadence-bounded)
//
// The matrix's USER_ONLY row (artifact.preview) is NOT a writing tool:
// it only emits the `show_artifact` UI command + a deep-link
// NavigationIntent (the device opens the preview, the kernel never
// touches the artifact — AD-7 / F-06).
// ---------------------------------------------------------------------------

/** task.create / task.update — one thin mutation tool (AD-7 Productivity). */
export const taskUpdate: KernelTool = tool({
  description:
    'Create / update / complete / archive a task (matrix row "task.create / task.update"). Thin command → productivity.task_update; the Productivity module applies the write (AD-7).',
  inputSchema: z.object({
    /** task ids (update / complete / archive) */
    taskIds: z.array(z.string()).min(1),
    /** the new state (or the task to create, when `create` + title set) */
    action: z.enum(['update', 'complete', 'archive', 'create']),
    /** required for create */
    title: z.string().optional(),
    /** fields to patch */
    patch: z.record(z.unknown()).optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.task_update', payload: input }),
});

/** habit.checkin — "I did X" (matrix row habit.checkin; Productivity). */
export const habitCheckin: KernelTool = tool({
  description:
    'Log a habit / routine check-in ("j\'ai fait X") — matrix row habit.checkin. Thin command → productivity.habit_checkin (AD-7).',
  inputSchema: z.object({
    habitId: z.string(),
    /** an optional note ("météo", "contexte" — the journal line) */
    note: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.habit_checkin', payload: input }),
});

/** planning.replan — "recalcul du planning restant" (ADR S13, Productivity). */
export const planningReplan: KernelTool = tool({
  description:
    'Re-plan / reorder the remaining day when context changes (matrix row planning.daily / planning.replan, ADR S13: "recalcul du planning restant sans détruire l\'historique"). Thin command → productivity.replan (executed blocks keep their results, AD-7).',
  inputSchema: z.object({
    /** what changed (new task, freed slot, energy drop…) */
    trigger: z.string(),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.replan', payload: input }),
});

/** course.search — "find my course on X" (Learning + Knowledge, read-only). */
export const courseSearch: KernelTool = tool({
  description:
    'Find a course / resource on a topic (matrix row course.search): local mirror + server retrieval. READ-ONLY (no job, no write — AD-7: no module mutation). Online-required for retrieval; offline degrades to mirror-only (AD-1).',
  inputSchema: z.object({
    topic: z.string(),
    limit: z.number().int().positive().default(5),
  }),
  execute: async (input) => ({ ok: true, command: 'learning.course_search', payload: input }),
});

/** flashcard.generate — sibling of qcm_generate (matrix rows qcm.generate / flashcard.generate). */
export const flashcardGenerate: KernelTool = tool({
  description:
    'Generate flashcards for a skill / course (matrix row flashcard.generate, Learning). Heavy step → artifact_gen job (AD-8), the items render via the AD-10 engines when the artifact lands.',
  inputSchema: z.object({
    skillId: z.string(),
    difficulty: z.enum(['easy', 'medium', 'hard', 'adaptive']).optional(),
    count: z.number().int().positive().default(10),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'artifact_gen', payload: input }),
});

/** learning.session.start — mirror-mode session (matrix row learning.session.start / learning.mirror.analyze). */
export const learningSession: KernelTool = tool({
  description:
    'Start a mirror-mode learning session ("quiz me / explain what I understand") — matrix row learning.session.start. Heavy step → agent_run job (AD-8); the kernel runs the mirror on the session transcript when it closes.',
  inputSchema: z.object({
    skillId: z.string(),
    mode: z.enum(['quiz', 'explain', 'teach']).default('quiz'),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'agent_run',
    payload: { capability: 'learning_session', ...input },
  }),
});

/** learning.import — ingest course materials for the exam (matrix / G-L5 course_import row). */
export const learningImport: KernelTool = tool({
  description:
    'Ingest course materials / resources for a course (matrix row learning.import, G-L5 course_import): split + OCR + FSRS seed as a course_import job (AD-8); the Learning module applies the learning_items rows (AD-7).',
  inputSchema: z.object({
    courseId: z.string(),
    /** the source artifact ids (presigned fetch, AD-3) */
    artifactIds: z.array(z.string()),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'course_import', payload: input }),
});

/** knowledge.add — ingest a new source into the KB (matrix row knowledge.* family). */
export const knowledgeAdd: KernelTool = tool({
  description:
    'Ingest a new source into the knowledge base (camera / OCR / upload — matrix row knowledge.add, AD-11 provenance): an ocr job (AD-8); the Knowledge module applies the semantic_nodes rows (AD-7 single-writer).',
  inputSchema: z.object({
    /** the source artifact (presigned fetch, AD-3) */
    artifactId: z.string(),
    /** the source kind (provenance, AD-11) */
    kind: z.enum(['note', 'course', 'article', 'formula', 'other']).default('other'),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'ocr', payload: input }),
});

/** progress.analyze — "how am I progressing?" (matrix row progress.analyze; mirrors light / S heavy). */
export const progressAnalyze: KernelTool = tool({
  description:
    'Analyze progress across a skill / goal ("comment je progresse ?") — matrix row progress.analyze. Light step reads mirrors + skill_states offline-capable; the deep variant recomputes as a skill_recompute job (AD-8) when `deep: true`.',
  inputSchema: z.object({
    skillId: z.string().optional(),
    goalId: z.string().optional(),
    /** deep = recompute (heavy job, AD-8); light = mirror read-only */
    deep: z.boolean().default(false),
  }),
  execute: async (input) =>
    input.deep
      ? { ok: true, jobKind: 'skill_recompute', payload: input }
      : { ok: true, command: 'progress.analyze', payload: input },
});

/** progress.trajectories — read the per-skill time-series (Progress, read-only). */
export const progressTrajectories: KernelTool = tool({
  description:
    'Read the progress trajectory / time-series for a skill (matrix / G-L5 progress.trajectories): READ-ONLY over progress_trajectories (AD-7: the Progress module owns the table, the kernel only reads it).',
  inputSchema: z.object({
    skillId: z.string(),
    /** the period to read (ISO start/end, or "30d" style) */
    period: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'progress.trajectories_read', payload: input }),
});

/** progress.cause — root-cause a skill gap (heavy S-job, AD-8). */
export const progressCause: KernelTool = tool({
  description:
    'Root-cause a skill gap ("pourquoi ai-je du mal sur X ?") — matrix / G-L5 progress.cause: a heavy skill_recompute job (AD-8) over the gap + the review history; the Progress module applies the diagnosis.',
  inputSchema: z.object({
    skillId: z.string(),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'skill_recompute', payload: input }),
});

/** artifact.generate — generic export (matrix row artifact.generate; sibling of the 4 docs.* document tools). */
export const artifactGenerate: KernelTool = tool({
  description:
    'Export a sheet / item as a document (matrix row artifact.generate, e.g. "exporte ce planning en PDF"): an artifact_gen job (AD-8); the Artifact module writes the row (AD-7) + the R2 blob (F-06 post-R2, AD-3: no device keys — presigned only).',
  inputSchema: z.object({
    /** the source item / artifact to export */
    sourceRef: z.string(),
    outputFormat: z.enum(['docx', 'pdf', 'pptx', 'html', 'epub', 'csv', 'json']).default('pdf'),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'artifact_gen', payload: input }),
});

/**
 * artifact.preview — matrix row USER_ONLY. The kernel does NOT produce a
 * preview: it emits the `show_artifact` UI command + a deep-link
 * NavigationIntent (command-bus.ts AGENT_UI_COMMANDS closed set, AD-12)
 * — the device opens the preview (local cache, AD-1 graceful degrade:
 * raw file download fallback). No job, no write.
 */
export const artifactPreview: KernelTool = tool({
  description:
    '"Show me X" → the Artifact Hub preview (matrix row artifact.preview, USER_ONLY): emits the show_artifact ui-command + a deep-link (AD-12/F-09: the kernel drives the UI through the command bus only — it NEVER reads the artifact, the device does, AD-1 graceful degrade to raw download). No job, no write.',
  inputSchema: z.object({
    artifactId: z.string(),
  }),
  execute: async (input) => ({
    ok: true,
    ui: {
      command: 'show_artifact',
      payload: { artifactId: input.artifactId },
      deepLink: `/artifacts/${input.artifactId}`,
    },
  }),
});

/** scientific.evaluate — light, offline-capable sibling of scientific_verify (matrix row scientific.evaluate / scientific.verify). */
export const scientificEvaluate: KernelTool = tool({
  description:
    'Compute / evaluate a formula locally (matrix row scientific.evaluate, light): the ScientificEngine runs offline-capable (AD-1: "light ops local"); the heavy `scientific_verify` job covers the deterministic full verification. The LLM NEVER solves — it structures the typed inputs.',
  inputSchema: z.object({
    domain: z.string(),
    problemType: z.string(),
    inputs: z.array(z.object({ key: z.string(), value: z.number(), unit: z.string() })),
  }),
  execute: async (input) => ({ ok: true, command: 'engineering.evaluate', payload: input }),
});

/** coach.checkin — proactive, cadence-bounded (matrix row coach.checkin, PARTIAL by design). */
export const coachCheckin: KernelTool = tool({
  description:
    'A proactive coach check-in ("temps de faire une pause / bonjour, comment va ta révision ?") — matrix row coach.checkin, cadence-limited by design (ADR §13: user-controlled cadence + silence windows). Thin command → productivity.coach_checkin (soft write, AD-7); the notification lands via the server (OneSignal, Integrations) or local.',
  inputSchema: z.object({
    /** the message */
    body: z.string(),
    /** respect the user's silence window + cadence (ADR §13) */
    honorSilenceWindow: z.boolean().default(true),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.coach_checkin', payload: input }),
});

/** settings.theme / preferences — user_context commands (matrix row settings.theme / preferences, PARTIAL). */
export const settingsTheme: KernelTool = tool({
  description:
    'Set the app theme / a preference ("passe l\'app en thème sombre") — matrix row settings.theme / preferences: a user_context command (AD-7: the Identity module owns user_context and applies the write). Light, read-open.',
  inputSchema: z.object({
    /** theme id (theme JSON SSoT, G-H2) */
    themeId: z.string(),
    style: z.enum(['light', 'dark', 'auto']).default('auto'),
  }),
  execute: async (input) => ({ ok: true, command: 'identity.set_theme', payload: input }),
});

/** review.run — daily / weekly / monthly (matrix row review.run, CONFIRMATION_REQUIRED on priority changes). */
export const reviewRun: KernelTool = tool({
  description:
    'Run a productivity review (daily / weekly / monthly — matrix row review.run, CONFIRMATION_REQUIRED on priority changes): a light command over the journal + decisions; the Productivity module applies the review outcome (AD-7).',
  inputSchema: z.object({
    horizon: z.enum(['daily', 'weekly', 'monthly']).default('weekly'),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.review_run', payload: input }),
});

/** integrations.automation.toggle — Composio automation (matrix row integrations.automation.toggle, CONFIRMATION_REQUIRED). */
export const automationToggle: KernelTool = tool({
  description:
    'Start / stop an automation ("stoppe l\'automatisation X") — matrix row integrations.automation.toggle, CONFIRMATION_REQUIRED: a thin command → integrations.automation_update (AD-7: the Integrations module owns automations + the vendor SDKs, AD-1).',
  inputSchema: z.object({
    automationId: z.string(),
    enabled: z.boolean(),
  }),
  execute: async (input) => ({ ok: true, command: 'integrations.automation_update', payload: input }),
});

/** notification.subscribe / silence — user prefs (matrix row notification.subscribe / silence, PARTIAL). */
export const notificationPref: KernelTool = tool({
  description:
    'Subscribe / silence a notification channel ("silence les push de révision") — matrix row notification.subscribe / silence: a user-prefs command (AD-7: the Integrations module owns notification_preferences).',
  inputSchema: z.object({
    channel: z.enum(['push', 'in-app', 'email']).default('push'),
    /** true = subscribe, false = silence */
    enabled: z.boolean(),
  }),
  execute: async (input) => ({ ok: true, command: 'integrations.notification_pref', payload: input }),
});

/** eisenhower — quadrant prioritization (matrix / G-L5 eisenhower row). */
export const eisenhowerPrioritize: KernelTool = tool({
  description:
    'Priorize tasks into the 4 Eisenhower quadrants ("priorise mes tâches") — matrix / G-L5 eisenhower row: a thin command → productivity.eisenhower (AD-7: the Productivity module applies the quadrant / priority fields on tasks).',
  inputSchema: z.object({
    taskIds: z.array(z.string()).min(1),
    /** the suggested quadrant per task (Q1 urgent+important … Q4) */
    quadrants: z.record(z.enum(['Q1', 'Q2', 'Q3', 'Q4'])),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.eisenhower', payload: input }),
});

/**
 * pomodoro_schedule — plan a series of Pomodoro blocks for a study plan
 * (focus-mode spec, planning-execution). Emits a `productivity.pomodoro_plan`
 * command; the Productivity module applies the time blocks.
 */
export const pomodoroSchedule: KernelTool = tool({
  description:
    'Schedule a series of Pomodoro blocks for a study plan (e.g. 4 x 25 min with 5 min pauses between). The agent auto-creates the blocks and pauses (planning-execution §3).',
  inputSchema: z.object({
    /** number of Pomodoro blocks */
    count: z.number().int().positive().min(1).max(8).default(4),
    /** work block duration in minutes (15-45) */
    workMin: z.number().int().positive().min(15).max(45).default(25),
    /** pause duration in minutes (2-15) */
    pauseMin: z.number().int().positive().min(2).max(15).default(5),
    /** linked goal / course id (planning context) */
    goalId: z.string().optional(),
  }),
  execute: async (input) => ({
    ok: true,
    command: 'productivity.pomodoro_plan',
    payload: input,
  }),
});

/**
 * The focus-sound catalog (kernel read-only surface, AD-11 provenance).
 *
 * The actual audio URLs live in the MOBILE package (apps/mobile/src/lib/
 * focus-sounds.ts) — they are device-side assets (streamed/looped by the
 * Focus controller), never server secrets. This kernel tool exposes the
 * catalog shape (theme buckets + sound ids + names) so the planner can
 * address a sound by `soundId` in `focus_sound` / `focus_profile`
 * (deterministic reference resolution — AD-15 closed vocabulary:
 * `sound` is a NAME; the id is the stable reference).
 */
export interface FocusSoundCatalogEntry {
  id: string;
  name: string;
  theme: 'nature' | 'bruit-blanc' | 'ambiance' | 'lointain' | 'musique';
  loop: boolean;
}

/** The 5-theme / 25-sound catalog (spec focus S6: min 15, 5 par thème). */
export const FOCUS_SOUND_CATALOG: readonly FocusSoundCatalogEntry[] = [
  { id: 'rain-gentle', name: 'Pluie douce', theme: 'nature', loop: true },
  { id: 'forest-night', name: 'Forêt apaisante (nuit)', theme: 'nature', loop: true },
  { id: 'river-birds', name: 'Rivière & oiseaux', theme: 'nature', loop: true },
  { id: 'ocean-waves', name: 'Vagues douces', theme: 'nature', loop: true },
  { id: 'tropical-beach', name: 'Plage tropicale', theme: 'nature', loop: true },
  { id: 'white-noise', name: 'Bruit blanc', theme: 'bruit-blanc', loop: true },
  { id: 'cabin-brown-noise', name: 'Bruit brun (cabine)', theme: 'bruit-blanc', loop: true },
  { id: 'rain-steady', name: 'Pluie stable (boucle)', theme: 'bruit-blanc', loop: true },
  { id: 'fireflies', name: 'Brouhaha nocturne', theme: 'bruit-blanc', loop: true },
  { id: 'wind-light', name: 'Vent léger', theme: 'bruit-blanc', loop: true },
  { id: 'cafe-bossa', name: 'Café (bossa vintage)', theme: 'ambiance', loop: true },
  { id: 'cafe-rain-window', name: 'Café sous la pluie', theme: 'ambiance', loop: true },
  { id: 'lofi-dreamscape', name: 'Lofi rêveur', theme: 'ambiance', loop: true },
  { id: 'lofi-chill', name: 'Lofi chill', theme: 'ambiance', loop: true },
  { id: 'chill-relax', name: 'Chill & relax', theme: 'ambiance', loop: true },
  { id: 'space-drone', name: 'Drone spatial', theme: 'lointain', loop: true },
  { id: 'ambient-classics', name: 'Classiques ambiantes', theme: 'lointain', loop: true },
  { id: 'midnight-radio', name: 'Radio minuit', theme: 'lointain', loop: true },
  { id: 'calm-radio', name: 'Session calme', theme: 'lointain', loop: true },
  { id: 'zen-radio', name: 'Zen radio', theme: 'lointain', loop: true },
  { id: 'sundown-loop', name: 'Lundi doux (boucle)', theme: 'musique', loop: true },
  { id: 'sundown-loop-2', name: 'Lundi doux II', theme: 'musique', loop: true },
  { id: 'lofi-mellow', name: 'Mellow visions (boucle)', theme: 'musique', loop: true },
  { id: 'lofi-sunbeam', name: 'Sunbeam dream (boucle)', theme: 'musique', loop: true },
  { id: 'lofi-soochrys', name: 'Lo-Fi zen', theme: 'musique', loop: true },
];

export const FOCUS_SOUND_THEMES = [
  'nature',
  'bruit-blanc',
  'ambiance',
  'lointain',
  'musique',
] as const satisfies readonly FocusSoundCatalogEntry['theme'][];

/**
 * focus_sound_catalog — READ-ONLY listing of the available concentration
 * sounds (spec focus S6: 5 thèmes × 5 sons, min 15 total). The planner
 * uses this to ground a `focus_sound` / `focus_profile` payload in a
 * known `sound` name (AD-11 provenance; AD-15 closed vocabulary: the 5
 * theme ids above are the ONLY valid `theme` discriminators).
 */
export const focusSoundCatalog: KernelTool = tool({
  description:
    'List the available concentration sounds (spec focus S6: 5 themes x 5 sounds, 25 total, Internet Archive / Jamendo sourced, CC / public-domain licensed). READ-ONLY - no write, no job. Use it to pick a `sound` name for focus_sound / focus_profile (the kernel enforces the closed 5-theme vocabulary).',
  inputSchema: z.object({
    /** optional theme filter (nature / bruit-blanc / ambiance / lointain / musique) */
    theme: z
      .enum(FOCUS_SOUND_THEMES)
      .optional(),
  }),
  execute: async (input) => ({
    ok: true,
    command: 'focus.sound_catalog_read',
    payload: {
      theme: input.theme,
      sounds: input.theme
        ? FOCUS_SOUND_CATALOG.filter((s) => s.theme === input.theme)
        : FOCUS_SOUND_CATALOG,
    },
  }),
});

/**
 * focus_sound — set the concentration sound for a focus session
 * (focus-mode spec, "sons de concentration"). 15+ sounds organized
 * in themes; only Aurora may emit notifications during the session.
 */
export const focusSound: KernelTool = tool({
  description:
    'Set the concentration sound for the next focus session (15+ catalog sounds, 5 par thème; focus-mode spec). The sound plays during the session; only Aurora may emit notifications.',
  inputSchema: z.object({
    /** the sound name from the catalog */
    sound: z.string(),
    /** the focus session id to attach the sound to */
    sessionId: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.sound', payload: input }),
});

/**
 * focus_profile — create / update a concentration profile
 * (a study-plan preset: Pomodoro/Chrono + blocklist + sound + tasks).
 * Used when the agent plans the day's focus sessions in bulk.
 */
export const focusProfile: KernelTool = tool({
  description:
    'Create or update a concentration profile (Pomodoro/Chrono + blocklist + focus sound + linked tasks). The agent uses this when planning the day: one command sets up the whole focus session (planning becomes trivial — "just work").',
  inputSchema: z.object({
    /** profile id (omit for create) */
    profileId: z.string().optional(),
    /** 'pomodoro' | 'chrono' */
    mode: z.enum(['pomodoro', 'chrono']),
    /** work duration in minutes (Pomodoro) or end time ISO (Chrono) */
    workMin: z.number().int().positive().optional(),
    endTimeIso: z.string().optional(),
    /** concentration sound name */
    sound: z.string().optional(),
    /** blocklist package names to suspend */
    blocklist: z.array(z.string()).default([]),
    /** linked task ids */
    taskIds: z.array(z.string()).default([]),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.profile', payload: input }),
});

/**
 * skill_activate — activate / deactivate a user skill
 * (ADR S14 user-facing skills; separate from auto-learned expert skills).
 */
export const skillActivate: KernelTool = tool({
  description:
    'Activate or deactivate a user skill from the Skills marketplace / personal set (ADR S14 user skills, NOT expert skills). The kernel applies the skill context to subsequent runs.',
  inputSchema: z.object({
    /** the skill id (ClawHub / personal) */
    skillId: z.string(),
    /** true = activate, false = deactivate */
    active: z.boolean().default(true),
  }),
  execute: async (input) => ({ ok: true, command: 'agent.skill_set', payload: input }),
});

/**
 * skill_create — create a personal skill (ADR S14 user skill authoring).
 */
export const skillCreate: KernelTool = tool({
  description:
    'Create a personal skill (trigger + goal + procedure). The skill is stored server-side in the user\'s skill registry and can be activated in future runs.',
  inputSchema: z.object({
    name: z.string(),
    /** what activates this skill */
    trigger: z.string(),
    /** the goal it achieves */
    goal: z.string(),
    /** the ordered procedure */
    steps: z.array(z.string()),
  }),
  execute: async (input) => ({ ok: true, command: 'agent.skill_create', payload: input }),
});

/**
 * skill_search — search the global skill_catalog by query text and/or domain.
 * The server-side EF (fn-skills `search_catalog` verb) runs the PostgREST
 * `ilike` filter over `skill_catalog.name/trigger_/objective` and returns
 * up to 10 compact rows (key, name, domain, trigger_, objective, source)
 * without the markdown body (token economy — the agent picks one, then
 * calls skill_get for the full SKILL.md). READ-ONLY, no write, no job.
 */
export const skillSearch: KernelTool = tool({
  description:
    'Search the global skills catalog (skill_catalog, 600+ rows, 0021 marketplace + 18 builtin) by free-text query and/or domain. Returns up to 10 compact matches (key, name, domain, trigger, objective, source) — NOT the full body. Use it to discover which skill fits the current case, then call skill_get with the chosen key to load its full procedure before acting. READ-ONLY.',
  inputSchema: z.object({
    /** free-text to match against name / trigger_ / objective (ilike, case-insensitive) */
    query: z.string().default(''),
    /** optional domain filter (e.g. 'documents', 'code', 'design', 'learning') */
    domain: z.string().optional(),
  }),
  execute: async (input) => ({
    ok: true,
    command: 'skills.search_catalog',
    payload: {
      query: input.query,
      domain: input.domain,
      limit: 10,
    },
  }),
});

/**
 * skill_get — retrieve the full SKILL.md body of a single catalog entry
 * by its `skill_key`. The server-side EF (fn-skills `get_skill` verb)
 * does one PostgREST point lookup. Use after skill_search has identified
 * the right key; the body is inlined into the working context so the
 * agent can follow the procedure step by step. READ-ONLY.
 */
export const skillGet: KernelTool = tool({
  description:
    'Retrieve the full SKILL.md body + procedure + constraints for a single skill_catalog entry by its skill_key. Call after skill_search has identified the right key — the body is the authoritative procedure; follow it step by step. READ-ONLY, no write.',
  inputSchema: z.object({
    /** the skill_key from a skill_search result */
    skillKey: z.string(),
  }),
  execute: async (input) => ({
    ok: true,
    command: 'skills.get',
    payload: { skillKey: input.skillKey },
  }),
});

/**
 * The full kernel tool set, keyed by the canonical tool ids the Planner's
 * `resolveTool` + `ExecutionEngine.invoke` address them by
 * (capability.tool === these keys).
 */
export const KERNEL_TOOLS = {
  planDay,
  schedule,
  startFocus,
  blockApps,
  research,
  qcm_generate: qcmGenerate,
  flashcard_generate: flashcardGenerate,
  mirror_analyze: mirrorAnalyze,
  learning_session: learningSession,
  scientific_verify: scientificVerify,
  scientific_evaluate: scientificEvaluate,
  goal_create: goalCreate,
  goal_status: goalStatus,
  goal_recompose: goalRecompose,
  goal_pause: goalPause,
  goal_complete: goalComplete,
  goal_abandon: goalAbandon,
  goal_feature_add: goalFeatureAdd,
  goal_feature_remove: goalFeatureRemove,
  // Document tools (docs/agent/document-tools.md) — 4 docs.* capabilities
  docs_generate: docsGenerate,
  docs_refine: docsRefine,
  docs_inspect: docsInspect,
  docs_parse: docsParse,
  // Feature-agentability-matrix.md — the remaining agentable families
  task_update: taskUpdate,
  habit_checkin: habitCheckin,
  planning_replan: planningReplan,
  course_search: courseSearch,
  learning_import: learningImport,
  knowledge_add: knowledgeAdd,
  progress_analyze: progressAnalyze,
  progress_trajectories: progressTrajectories,
  progress_cause: progressCause,
  artifact_generate: artifactGenerate,
  artifact_preview: artifactPreview,
  coach_checkin: coachCheckin,
  settings_theme: settingsTheme,
  review_run: reviewRun,
  automation_toggle: automationToggle,
  notification_pref: notificationPref,
  eisenhower_prioritize: eisenhowerPrioritize,
  // Focus planning (focus-mode spec + planning-execution)
  pomodoro_schedule: pomodoroSchedule,
  focus_sound: focusSound,
  focus_profile: focusProfile,
  focus_sound_catalog: focusSoundCatalog,
  // Skills (ADR S14 user skills, separate from expert skills)
  skill_activate: skillActivate,
  skill_create: skillCreate,
  // Skill catalog search (0021 marketplace): the agent searches the global
  // skill_catalog per case — skill_search returns compact matches,
  // skill_get retrieves the full SKILL.md body of the chosen skill.
  skill_search: skillSearch,
  skill_get: skillGet,
  // Canvas tools (0022) : l'agent POUVOIR lire / écrire / commenter la
  // session canvas. L'humain reste éditeur de /canvas (StarterKit) —
  // les deux écrivent la même table, l'agent passe par le kernel
  // (commandes canvas.*), l'humain par le client device (AD-7).
  canvas_read: canvasRead,
  canvas_write: canvasWrite,
  canvas_comment: canvasComment,
};

export type KernelToolId = keyof typeof KERNEL_TOOLS;
export type ToolSet = typeof KERNEL_TOOLS;
