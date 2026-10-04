/**
 * Composio adapter — behind the `IntegrationProvider` port (AD-1 vendor
 * isolation: business code imports this module's contracts, never the
 * vendor SDK; vendor SDKs live only in adapter packages, composio.md §2).
 *
 * Mission S33: Composio is a TOOL/INTEGRATION layer, NOT an AI provider —
 * no AI routing logic may import it as a model.
 *
 * Capabilities (composio.md §1/§3/§4): tool discovery (runtime catalog
 * query, no build-time cache §10), connected accounts & auth state
 * (server-side only, AD-3: no tokens on device / in the bundle), and
 * tool execution (normalized results, §6).
 *
 * Vendor SDK isolation (AD-1, same pattern as research-provider.ts):
 * plain `fetch` to the Composio REST API, no vendor SDK dependency.
 * Secrets: COMPOSIO_API_KEY env (server secret store, AD-3); the adapter
 * degrades to `unavailable`/empty catalog when unconfigured (§3 tool
 * router: optional capability absent = product keeps working).
 */
import type { IntegrationsState } from '@aurora/domain';

/** A tool discovered in the Composio catalog (composio.md §3). */
export interface ComposioTool {
  /** stable tool id (`tool_<appId>_<action>` style, provider-owned) */
  toolId: string;
  /** vendor app (e.g. "gmail", "notion", "slack") */
  app: string;
  name: string;
  description?: string;
  /** JSON Schema (opaque; the Agent Tool Registry validates) */
  inputSchema?: Record<string, unknown>;
  /** auth requirement of the tool */
  requiredAuth: 'oauth' | 'api-key' | 'none';
  /** Permission Engine input (composio.md §8): destructive calls need
   *  user confirmation (ADR §5). */
  destructive?: boolean;
}

/** Normalized tool execution result (composio.md §6: the kernel sees a
 *  normalized result, never a raw OAuth bearer). */
export interface ComposioToolResult {
  ok: boolean;
  /** provider="composio", model="tool:<toolId>" trace context */
  trace: { provider: 'composio'; toolId: string; app: string };
  data?: unknown;
  error?: string;
  /** partial execution: which sub-steps succeeded (composio.md §7) */
  subSteps?: Array<{ step: string; ok: boolean }>;
}

/** Connected-account connection state (composio.md §4). */
export type ConnectionState =
  | 'connected'
  | 'disconnected'
  | 'token_expired'
  | 'reauth_required';

export interface ConnectedAccount {
  /** Composio-side id (composio.md §9: stored in integrations_state.connection_ref) */
  connectedAccountId: string;
  app: string;
  state: ConnectionState;
  lastCheckedAt?: string;
}

/** The `IntegrationProvider` contract this adapter implements
 *  (ADR §8 port; additive wave-2 surface — the 14 shared ports stay
 *  untouched, so this is declared here, in the adapter package). */
export interface IntegrationProvider {
  readonly id: string;
  isConfigured(): boolean;
  /** tool catalog query (composio.md §3, runtime not build-time §10) */
  discoverTools(userId: string, opts?: { app?: string; limit?: number }): Promise<ComposioTool[]>;
  /** connected accounts for a user (§4), normalized to vendor state */
  listConnectedAccounts(userId: string): Promise<ConnectedAccount[]>;
  /** normalized tool execution (§6/§7), idempotent per sub-step */
  executeTool(
    userId: string,
    tool: ComposioTool,
    input: Record<string, unknown>,
    opts?: { idempotencyKey?: string },
  ): Promise<ComposioToolResult>;
}

/**
 * Pure filter (composio.md §3 Tool Registry merge): a tool is only
 * available when the user holds a connected account for that app with
 * state `connected`. Unconnected app → tool marked `unavailable`; the
 * kernel degrades instead of failing (AD-1, test composio.md §11.2).
 */
export function filterAvailableTools(
  tools: ComposioTool[],
  accounts: ConnectedAccount[],
): Array<ComposioTool & { available: boolean; reason?: string }> {
  const byApp = new Map<string, ConnectedAccount>();
  for (const a of accounts) byApp.set(a.app, a);
  return tools.map((t) => {
    const account = byApp.get(t.app);
    if (account === undefined || account.state !== 'connected') {
      return {
        ...t,
        available: false,
        reason:
          account === undefined
            ? 'unconnected'
            : account.state === 'connected'
              ? undefined
              : 'reauth_required',
      };
    }
    return { ...t, available: true };
  });
}

/** Map a provider account to the module's `IntegrationsState` SSoT shape
 *  (01 §4.7): the integrations table is written ONLY by this module
 *  (AD-7 single-writer). */
export function toIntegrationsState(
  userId: string,
  account: ConnectedAccount,
): IntegrationsState {
  const status: IntegrationsState['status'] =
    account.state === 'connected'
      ? 'connected'
      : account.state === 'disconnected'
        ? 'disconnected'
        : account.state === 'token_expired'
          ? 'reauth-required'
          : 'unknown';
  return {
    userId,
    vendor: 'composio',
    connection: account.app,
    status,
    lastCheckedAt: account.lastCheckedAt,
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Composio REST adapter (v3.1 — sessions + meta-tools).
 * Configured when COMPOSIO_API_KEY is present (server secret store, AD-3);
 * base URL overridable for tests.
 *
 * v3.1 contract (docs.composio.dev/docs/toolkits.md §3):
 *   - REST base: `https://backend.composio.dev/api/v3.1`
 *   - Per-user session: `POST /sessions { user_id }` → session_id
 *   - Session tools: `GET /sessions/{session_id}/tools` → meta-tools
 *     (COMPOSIO_SEARCH_TOOLS, COMPOSIO_MULTI_EXECUTE_TOOL,
 *      COMPOSIO_MANAGE_CONNECTIONS, …)
 *   - Tool execution: `POST /sessions/{session_id}/tools/execute`
 *     body `{ tool_slug, input }`
 *   - Connected accounts: `GET /sessions/{session_id}/connected_accounts`
 *
 * The adapter is transport-agnostic (plain `fetch`, no vendor SDK
 * dependency — AD-1): the Deno EF calls the same `POST /sessions` +
 * `POST /sessions/{id}/tools/execute` pair via its `session.mcp.url`
 * variant when it wants a hosted-MCP client (the `session.mcp.url` +
 * `session.mcp.headers` fields are returned by the create call, so
 * `fn-integrations` can hand an `MCP url+headers` pair to any
 * MCP-compatible client without a provider package — the docs §1
 * "MCP" path).
 *
 * Failure policy (composio.md §7, AD-1): all failures return a degraded
 * result / empty catalog — never throw, never leak a key. 429 honors
 * `retry-after` (no escalation); 401/403 → reauth_required, never
 * key-rotation.
 */
export class ComposioIntegrationProvider implements IntegrationProvider {
  readonly id = 'composio';
  private readonly apiKey: string;
  private readonly baseUrl: string;

  /** Per-user session cache: `userId` → session id (created once per
   *  user, reused — the docs say the session persists across the
   *  application; a fresh session per call would burn the quota). */
  private sessions = new Map<string, string>();

  /**
   * The adapter is runtime-agnostic: keys come from the environment under
   * Node (`process.env`), but they can ALSO be injected explicitly (the
   * Deno EF's `Deno.env.get` → `constructor(apiKey, baseUrl)` — AD-3, the
   * secret store IS the key source, not a hardcode).
   */
  constructor(apiKey?: string, baseUrl?: string) {
    this.apiKey =
      apiKey ?? (typeof process !== 'undefined' ? process.env.COMPOSIO_API_KEY ?? '' : '');
    this.baseUrl =
      baseUrl ??
      (typeof process !== 'undefined'
        ? process.env.COMPOSIO_BASE_URL ??
          'https://backend.composio.dev/api/v3.1'
        : 'https://backend.composio.dev/api/v3.1');
  }

  /**
   * Create (or reuse) the user's Composio session. The session is the
   * runtime context that carries identity, connections, and tool scope
   * for one application user (docs §3 "How sessions behave").
   *
   * v3.1 shape: `POST /sessions` body `{ user_id }`, header
   * `Authorization: ApiToken <COMPOSIO_API_KEY>`. Response:
   * `{ session_id, mcp: { url, headers }, tools: [meta-tools] }`.
   */
  private async sessionFor(userId: string): Promise<string | null> {
    const cached = this.sessions.get(userId);
    if (cached) return cached;
    if (!this.isConfigured()) return null;
    const res = await this.call('/sessions', {
      method: 'POST',
      body: JSON.stringify({ user_id: userId }),
    });
    if (res === null || !res.ok) return null;
    const data = (await res.json().catch(() => ({}))) as { session_id?: string };
    const id = data.session_id;
    if (!id) return null;
    this.sessions.set(userId, id);
    return id;
  }

  isConfigured(): boolean {
    return this.apiKey !== '';
  }

  private async call(
    path: string,
    init: RequestInit,
  ): Promise<Response | null> {
    if (!this.isConfigured()) return null;
    const res = await fetch(`${this.baseUrl}${path}`, {
      ...init,
      headers: {
        Authorization: `ApiToken ${this.apiKey}`,
        'Content-Type': 'application/json',
        ...init.headers,
      },
    });
    // 429: honor retry-after (composio.md §7) — the caller re-dispatches
    // via job retry; no escalation, no key rotation.
    if (res.status === 429) {
      res.headers.get('retry-after'); // observed; dispatcher retries
      return null;
    }
    return res;
  }

  async discoverTools(
    userId: string,
    opts?: { app?: string; limit?: number },
  ): Promise<ComposioTool[]> {
    const sessionId = await this.sessionFor(userId);
    if (sessionId === null) return [];
    const limit = Math.min(opts?.limit ?? 100, 500);
    const q = opts?.app !== undefined ? `?toolkit=${encodeURIComponent(opts.app)}&` : '?';
    const res = await this.call(
      `/sessions/${encodeURIComponent(sessionId)}/tools${q}limit=${limit}`,
      { method: 'GET' },
    );
    if (res === null || !res.ok) {
      // catalog drift / unconfigured → degrade: empty tool list,
      // product keeps working (composio.md §3/§10).
      return [];
    }
    const data = (await res.json().catch(() => ({}))) as
      | Array<{
          slug?: string;
          toolkit_slug?: string;
          toolkit_name?: string;
          name?: string;
          description?: string;
          input_schema?: Record<string, unknown>;
          auth_type?: string;
          tags?: string[];
        }>
      | { data?: Array<{ slug?: string; toolkit_slug?: string; toolkit_name?: string; name?: string; description?: string; input_schema?: Record<string, unknown>; auth_type?: string; tags?: string[] }> };
    const rows = Array.isArray(data) ? data : (data.data ?? []);
    return rows.map((r) => ({
      toolId: String(r.slug ?? r.name ?? ''),
      app: String(r.toolkit_slug ?? r.toolkit_name ?? ''),
      name: String(r.name ?? ''),
      description: r.description,
      inputSchema: r.input_schema,
      requiredAuth:
        r.auth_type === 'API_KEY'
          ? 'api-key'
          : r.auth_type === 'OAUTH2'
            ? 'oauth'
            : 'none',
      // v3.1 meta-tools carry openWorldHint / destructiveHint / important
      // tags — the destructive flag feeds the kernel's Confirmation Engine
      // (composio.md §8: destructive external actions need confirmation).
      destructive: r.tags?.includes('destructiveHint') ?? false,
    }));
  }

  async listConnectedAccounts(userId: string): Promise<ConnectedAccount[]> {
    const sessionId = await this.sessionFor(userId);
    if (sessionId === null) return [];
    const res = await this.call(
      `/sessions/${encodeURIComponent(sessionId)}/connected_accounts`,
      { method: 'GET' },
    );
    if (res === null || !res.ok) return [];
    const data = (await res.json().catch(() => ({}))) as
      | Array<{ id?: string; toolkit_slug?: string; status?: string; last_checked_at?: string }>
      | { data?: Array<{ id?: string; toolkit_slug?: string; status?: string; last_checked_at?: string }> };
    const rows = Array.isArray(data) ? data : (data.data ?? []);
    return rows.map((r) => ({
      connectedAccountId: String(r.id ?? ''),
      app: String(r.toolkit_slug ?? ''),
      state:
        r.status === 'connected'
          ? 'connected'
          : r.status === 'disconnected'
            ? 'disconnected'
            : r.status === 'expired'
              ? 'token_expired'
              : 'reauth_required',
      lastCheckedAt: r.last_checked_at,
    }));
  }

  async executeTool(
    userId: string,
    tool: ComposioTool,
    input: Record<string, unknown>,
    opts?: { idempotencyKey?: string },
  ): Promise<ComposioToolResult> {
    const trace = { provider: 'composio' as const, toolId: tool.toolId, app: tool.app };
    if (!this.isConfigured()) {
      return { ok: false, trace, error: 'composio_not_configured' };
    }
    const sessionId = await this.sessionFor(userId);
    if (sessionId === null) {
      return { ok: false, trace, error: 'composio_not_configured' };
    }
    // v3.1 session execution: POST /sessions/{id}/tools/execute,
    // body { tool_slug, input, idempotency_key? }. The docs §1 "Native
    // Tools" path says `session.execute(tool_slug, arguments)` — this is
    // the REST equivalent (same shape; `tool_slug` is the v3.1 field name).
    const res = await this.call(
      `/sessions/${encodeURIComponent(sessionId)}/tools/execute`,
      {
        method: 'POST',
        body: JSON.stringify({
          tool_slug: tool.toolId,
          input,
          ...(opts?.idempotencyKey !== undefined
            ? { idempotency_key: opts.idempotencyKey }
            : {}),
        }),
      },
    );
    if (res === null) {
      // 429 path or not configured: degraded, bounded retry upstream.
      return { ok: false, trace, error: 'rate_limited_or_unconfigured' };
    }
    if (res.status === 401 || res.status === 403) {
      // reauth / scope-missing alert (composio.md §7): never escalate.
      return {
        ok: false,
        trace,
        error: res.status === 401 ? 'reauth_required' : 'scope_missing',
      };
    }
    if (!res.ok) {
      return { ok: false, trace, error: `http_${res.status}` };
    }
    const data = (await res.json().catch(() => ({}))) as {
      successful?: boolean;
      data?: unknown;
      error?: string;
      log_id?: string;
    };
    return {
      ok: data.successful !== false,
      trace,
      data: data.data,
      error: data.successful === false ? data.error : undefined,
    };
  }
}

/** Factory (AD-1): the only way business code obtains the provider.
 *  Unconfigured env → the adapter reports not-configured and every call
 *  degrades (01 §6). Optional explicit key/baseUrl for runtimes without
 *  `process.env` (the Deno EF). */
export function createIntegrationProvider(
  apiKey?: string,
  baseUrl?: string,
): IntegrationProvider {
  return new ComposioIntegrationProvider(apiKey, baseUrl);
}
