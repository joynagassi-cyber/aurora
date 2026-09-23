# Vercel AI SDK — Agent Kernel Integration (additive, 2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 3, Agent team).
Authority: ADR v1.7 S2-S15 (AI multi-provider), AD-1 (vendor isolation),
AD-4 (AI pipeline), AD-12/F-09 (one kernel, server-side), 01 S5.6
(kernel execution = fn-agent-run + jobs), kernel.md S12 (15 components).

## Decision

The Agent Kernel's text-generation loop (Intent -> Context -> Plan ->
Tools -> Execute -> Verify -> Result) is implemented using the
**Vercel AI SDK** (`ai` npm package) as the orchestration framework.
CopilotKit is **excluded** (conflicts with frozen AD-10 visual engines:
SemanticTree, Infographic, DataViz, Math, Animation; too heavy an
opinionated UI layer for Aurora's local-first + 5-state UX model).

## Why Vercel AI SDK (conformance check against ADR v1.7)

| ADR constraint | Vercel AI SDK behavior | Conforms? |
|---|---|---|
| AD-1: domain never knows a vendor name | SDK is behind `AIProvider` port; domain code imports the port, not the SDK | YES |
| AD-4: multi-provider (Router -> Gateway -> adapters) | SDK's `LanguageModel` abstraction accepts any OpenAI-compatible endpoint (Agnes, Workers AI, Groq, Cerebras via CF AI Gateway or direct) | YES |
| AD-5: fallback + traceability | `streamText` / `generateText` return structured responses; `AIResponseEnvelope` wraps every call (provider, model, attempt, reason, quality) | YES |
| AD-12/F-09: server-side execution | SDK runs in Supabase Edge Functions (`fn-agent-run`) + CF Workers; device sees only `AgentRunState` | YES |
| ADR v1.7 S6: typed TaskProfile routing (never prompt keywords) | `aiRouter.selectModel(taskProfile)` returns a `LanguageModel` instance; the SDK call is model-agnostic | YES |
| ADR v1.7 S9: 9 AI contracts | SDK implements `AIProvider.complete()` / `AIProvider.stream()`; the other 8 contracts (Registry, Policy, Fallback, Health, Usage, Budget, Guard) are Aurora-specific wrappers around the SDK | YES |
| AD-3: no keys on device | SDK runs server-side; device calls Supabase / CF Gateway; zero provider keys in bundle | YES |
| AD-10: frozen visual engines | SDK output (markdown / JSON / tool calls) is rendered by Aurora's own renderers (KaTeX, AntV G2, React Flow + Dagre); the SDK does NOT impose a UI layer | YES |

## Integration architecture (per package)

```
packages/agent (server-side, wave 3)
  |
  | imports: 'ai' (Vercel AI SDK)
  | AD-1 boundary: this is the ONLY package that imports the SDK
  |
  | kernel.ts:
  |   - Context Builder: reads UserContext + LearningContext + ...
  |   - Planner: builds tool sequence (maxSteps)
  |   - Tool Resolver: maps AgentCapability -> SDK tool definitions
  |   - Execution: streamText({ model, system, messages, maxSteps, tools })
  |   - Verification: onStepFinish (deterministic check, ScientificEngine)
  |   - Result Normalizer: wrap in AIResponseEnvelope
  |
  | tools/:
  |   - researchTool -> ResearchProvider port (You.com/Tavily/Exa)
  |   - knowledgeTool -> KnowledgeBase port (FTS + pgvector + R2)
  |   - composioTool -> IntegrationProvider port (Composio API)
  |   - scientificTool -> ScientificEngine port (deterministic calc)
  |   - progressTool -> Progress public view (read-only)
  |   - focusTool -> FocusController port (start/end/block)
  |
  | router.ts:
  |   - aiRouter.selectModel(taskProfile) -> LanguageModel adapter
  |   - per-provider adapters: AgnesAdapter, WorkersAIAdapter, GroqAdapter,
  |     CerebrasAdapter, OpenRouterAdapter, etc.
  |   - All adapters behind CF AI Gateway (primary) or direct (fallback)
  |   - Fallback chain: primary -> gateway -> CF Worker (Workers AI direct)
  |
  | AD-1 rule: no other package imports 'ai'. packages/domain, packages/ui,
  | apps/mobile NEVER see the Vercel SDK.

apps/mobile (device, wave 1+)
  |
  | imports: 'ai' (client-side ONLY for useChat hook)
  | AD-1 boundary: useChat is the SDK's client abstraction
  |
  | agent/
  |   - useChat({ api: '/fn-agent-run' }) -> streaming AgentRunState
  |   - attachment handling (files/images -> R2 presigned upload)
  |   - tool call rendering (intercept SDK data streams -> route to AD-10 renderers)
  |   - formula content -> MathRenderer (KaTeX)
  |   - chart content -> DataVisualizationRenderer (G2)
  |   - tree content -> SemanticTreeRenderer (React Flow + Dagre)
  |   - infographic -> InfographicRenderer
  |
  | AD-10 rule: the SDK outputs markdown/JSON; Aurora's renderers interpret
  | the content. The SDK does NOT render UI (no CopilotKit, no RSC).

packages/data (local-first, wave 1+)
  |
  | - chat_messages table (local mirror via PowerSync):
  |   {id, userId, sessionId, role, content, toolCalls?, toolResults?,
  |    provider, model, envelope, createdAt}
  | - each agent message persisted locally (SQLite) immediately
  | - PowerSync upsyncs to Supabase (server-wins, 03 S5.1)
  | - offline: chat history readable from local mirror
  | - online: streaming from server; local messages queue if offline
```

## Streaming + tool calling flow (the Agent loop)

```
User: "Organise ma journée, mets 2h de géotechnique ce matin,
       démarre Focus et bloque TikTok et WhatsApp."

Device (useChat):
  POST /fn-agent-run { messages: [...], attachments: [] }
  <- SSE stream (AgentRunState chunks)

Server (fn-agent-run, Vercel AI SDK):
  streamText({
    model: aiRouter.selectModel(taskProfile),  // AGENT profile -> Agnes 3.0
    system: "Tu es l'agent Aurora...",
    messages: [...user context...],
    maxSteps: 5,
    tools: {
      planDay: planningTool,       // -> Productivity commands
      schedule: calendarTool,      // -> EventUpdateCommand
      startFocus: focusTool,       // -> FocusController
      blockApps: blockTool,       // -> DpcAdapter (v1.8)
      research: researchTool,      // -> ResearchProvider
    },
    onStepFinish({ text, toolCalls }) {
      // Verification: deterministic check (e.g., DPC precheck)
      // Job: heavy steps dispatched to job_queue (AD-8)
      // AIResponseEnvelope: trace this step
    },
  })

Device (useChat consumer):
  - streams tokens to AgentRunState panel
  - on toolCall: renders confirmation surface (ADR S5)
  - on toolResult: updates relevant screen (calendar, focus timer)
  - on streamEnd: shows result summary + "Suivant" suggestion
```

## Fallback chain (AD-5, v1.7 S4/S10)

```
Primary: CF AI Gateway -> Agnes (Agnes 3.0 Flash / 2.5 Flash)
Fallback 1: CF AI Gateway -> Workers AI (GLM-4.7 Flash / Gemma 4)
Fallback 2: CF AI Gateway -> Groq / Cerebras (high-speed, if quota)
Last resort: CF Worker (direct Workers AI, no Gateway)
429: respect retry-after; NEVER key rotation (AD-5)
All steps: AIResponseEnvelope { provider, model, attempt, reason,
  expectedQuality, fallbackUsed, traceId }
```

## Security invariants (AD-3)

- Provider API keys: server-side ONLY (Supabase/Cloudflare secret stores)
- Device bundle: zero provider keys; OneSignal appKey only (04 S3.2.5)
- `useChat` calls Supabase Edge Function (`fn-agent-run`) via the
  Supabase JS client (authenticated, RLS-protected)
- R2 uploads: presigned URLs (client never holds R2 keys)
- Composio: server-side auth (composio.md S4); device holds no
  external OAuth tokens

## Tiptap integration (AI-assisted document editing)

Tiptap is the rich-text editor (ADR v1.5 add-on, 02 S4 layer 4, 01 S4.2):

- **Server-side AI generation** produces markdown/JSON content
- **Client-side Tiptap editor** renders it with:
  - `@tiptap/react` (editor component, compatible with Ionic React)
  - `@tiptap/extension-math` (KaTeX rendering of formulas)
  - `@tiptap/extension-link`, `@tiptap/extension-table`,
    `@tiptap/extension-highlight`, `@tiptap/extension-code-block`
  - Aurora custom extensions: `SourceRefInline` (provenance badges,
    AD-11), `CorpusBadge` (teacher vs Aurora explanation, ADR S17),
    `FidelityCheck` (before export, 01 S4.2)
- **Yjs collaborative editing** = future extension (spine Deferred,
  not in V1)
- **AI-assisted editing**: user selects text in Tiptap -> context
  passed to Agent (`useChat` attachment) -> Agent returns
  revision/explanation -> Tiptap inserts with `CorpusBadge` label

## Export formats (Artifact Hub, ADR S16/S17)

| Format | Renderer / Engine | Preview | Export | Status |
|---|---|---|---|---|
| PDF | server-side (puppeteer / wkhtmltopdf in Edge Function) | paginated read, zoom, search | `artifact_gen` job | COVERED |
| DOCX | server-side (docx npm / pandoc) | preview + content extraction | `artifact_gen` job | COVERED |
| PPTX | server-side (pptxgenjs) | slide previews | `artifact_gen` job | COVERED |
| XLSX / CSV | client-side (SheetJS / xlsx npm) | tabular preview + G2 charts | `artifact_gen` job | COVERED |
| PNG / images | client-side (canvas / html2canvas) | zoom viewer | direct R2 | COVERED |
| TXT / Markdown | client-side (raw text) | Tiptap read / code block | direct R2 | COVERED |
| Audio / video | client-side (HTML5 media) | integrated player (if format + platform allow) | direct R2 | COVERED |
| LaTeX | client-side (KaTeX / MathJax via MathRenderer) | formula rendering | export as .tex | COVERED |
| Unsupported | — | no fake preview (ADR S16: conservation + download only) | R2 download / share external | COVERED |

All exports = server-side `artifact_gen` job (AD-8) -> R2 upload ->
`ArtifactGenerated` event (F-06: post-upload only). The Tiptap editor
on the device previews locally; export always goes through the job.

## What this doc does NOT change

- The 9 AI contracts in packages/domain (AD-15 SSoT) remain the
  normative interface. The Vercel AI SDK is an **implementation
  detail** behind `AIProvider` (AD-1).
- The Agent Kernel's 15 components (kernel.md S12) remain the
  architectural specification. The SDK implements the Execution
  Engine + Result Normalizer; the other 13 components are Aurora
  code around the SDK.
- AD-10 frozen renderers are unaffected. The SDK outputs data;
  Aurora renders it.
- No CopilotKit, no React Server Components, no Vercel-specific
  deployment (the app runs on Supabase Edge Functions + CF Workers,
  not Vercel hosting).

## Tests (wave 3)

- SDK isolation: `packages/domain` + `packages/ui` + `apps/mobile/src`
  do NOT import 'ai' (CI grep test, AD-1)
- `streamText` with `maxSteps=5`: tool calls execute in order;
  confirmation surface blocks destructive steps
- Fallback: mock 429 on primary -> gateway routes to fallback ->
  `AIResponseEnvelope.fallbackUsed = true`
- Tiptap: AI-generated content renders with CorpusBadge + SourceRef
- Export: PDF/DOCX/PPTX/XLSX/PNG/TXT all produce valid files in R2
- useChat streaming: tokens render in real-time on device; offline
  = local mirror read; online = streaming
- Local persistence: every chat message in SQLite; PowerSync upsync
