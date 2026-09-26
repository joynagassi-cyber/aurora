/**
 * Vercel AI SDK layer — streamText / generateText adapter (task 2).
 *
 * AD-1 boundary: this file + tools.ts + gateway.ts are the ONLY
 * places in the monorepo that import the Vercel `ai` SDK. The kernel
 * stays SDK-agnostic: `AgentKernel.invokeModel` / `invokeTool`
 * (kernel.ts) delegate here.
 *
 * Zero provider keys (AD-3): this layer never reads a key itself —
 * the `LanguageModel` instance is built by the adapter layer
 * (adapters.ts, ModelGateway) which reads the server secret store.
 * A key is NEVER a function argument.
 *
 * Streaming surface (02 S4, maxSteps=KERNEL_MAX_STEPS):
 * `streamKernelRun` maps the SDK's stream parts to `KernelEvent`s —
 * the device consumes the resulting `AgentRunState` chunks only
 * (AD-12/F-09).
 */
import { streamText, type LanguageModel, type ModelMessage } from 'ai';
import { KERNEL_TOOLS, type KernelToolId } from './tools.ts';

/** The maxSteps for the streaming surface (02 S4). */
export const KERNEL_MAX_STEPS = 5;

/**
 * An adapter that can build a LanguageModel for a provider + model
 * (the router's output, task 3). The adapter owns key lookup
 * (server secret store) — the SDK layer never receives a key.
 */
export interface ModelAdapter {
  build(provider: string, model: string, baseURL: string): Promise<LanguageModel>;
  serving(provider: string, model: string): { provider: string; model: string };
}

export interface StreamKernelRunOptions {
  /** the model serving this run (the router's `select()` output) */
  model: LanguageModel;
  /** the trace id carried in the AgentRunState chunk (AD-5) */
  agentRunId: string;
  /** the provider/model that actually served (envelope, AD-5) */
  provider: string;
  modelName: string;
  system?: string;
  messages?: ModelMessage[];
  /** tool subset (default: all kernel tools) */
  toolIds?: KernelToolId[];
  /** confirmation gate — called for every tool call; return false to refuse */
  onToolCall?: (tool: string, input: unknown) => boolean | Promise<boolean>;
  /** emit a KernelEvent (SSE chunk, 02 S4) */
  onEvent: (e: import('./kernel.ts').KernelEvent) => void;
}

/**
 * Stream a kernel run through the Vercel SDK (streamText,
 * maxSteps=KERNEL_MAX_STEPS, the kernel tool set). Text deltas flow as
 * `{ type: 'text' }` events; tool executions flow as `{ type: 'tool' }`
 * events (the kernel's run() loop owns the AgentRunState snapshot —
 * this layer carries the deltas; fn-agent-run (task 6) maps them to
 * SSE).
 */
export async function streamKernelRun(opts: StreamKernelRunOptions): Promise<string> {
  const tools = opts.toolIds && opts.toolIds.length > 0
    ? Object.fromEntries(
        Object.entries(KERNEL_TOOLS).filter(([k]) => opts.toolIds!.includes(k as KernelToolId)),
      )
    : { ...KERNEL_TOOLS };

  const result = streamText({
    model: opts.model,
    system: opts.system,
    messages: opts.messages ?? [],
    tools,
  });

  let text = '';
  for await (const chunk of result.fullStream) {
    if (chunk.type === 'text-delta') {
      const delta = chunk.text;
      text += delta;
      opts.onEvent({
        type: 'text',
        chunk: delta,
        state: {
          agentRunId: opts.agentRunId,
          stage: 'result',
          status: 'running',
          startedAt: '',
          updatedAt: '',
          text,
        },
      });
    } else if (chunk.type === 'tool-call') {
      const input = chunk.input;
      const allowed = opts.onToolCall ? await opts.onToolCall(chunk.toolName, input) : true;
      opts.onEvent({
        type: 'tool',
        state: {
          agentRunId: opts.agentRunId,
          stage: 'tools',
          status: allowed ? 'running' : 'failed',
          startedAt: '',
          updatedAt: '',
          text,
        },
        tool: chunk.toolName,
        input: allowed ? input : { refused: true, args: input },
      });
    }
  }
  await result.response;
  return text;
}

/**
 * The kernel tool ids (SDK `tools` subset when the router /
 * permission gate restricts the available set, kernel S14).
 */
export const ALL_TOOL_IDS = Object.keys(KERNEL_TOOLS) as KernelToolId[];

/**
 * Build the `ModelMessage` payload from a kernel request + the
 * assembled context (the Context Builder's 9 forms, S2 S16).
 */
export function messagesFor(
  intent: string,
  contextRefs: string[] | undefined,
  contextForm: Record<string, unknown>,
): ModelMessage[] {
  const user = contextRefs && contextRefs.length > 0
    ? `${intent} (refs: ${contextRefs.join(', ')})`
    : intent;
  return [
    { role: 'system', content: JSON.stringify(contextForm) },
    { role: 'user', content: user },
  ];
}

export { KERNEL_TOOLS };
export type { KernelToolId };
