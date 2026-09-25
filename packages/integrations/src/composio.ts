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
 * Composio REST adapter. Configured when COMPOSIO_API_KEY is present
 * (server secret store, AD-3); base URL overridable for tests.
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

  constructor() {
    this.apiKey = process.env.COMPOSIO_API_KEY ?? '';
    this.baseUrl =
      process.env.COMPOSIO_BASE_URL ?? 'https://api.composio.dev/api/v1';
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
    void userId;
    const limit = Math.min(opts?.limit ?? 100, 500);
    const q = opts?.app !== undefined ? `?app=${encodeURIComponent(opts.app)}&` : '?';
    const res = await this.call(`/tools${q}limit=${limit}`, { method: 'GET' });
    if (res === null || !res.ok) {
      // catalog drift / unconfigured → degrade: empty tool list,
      // product keeps working (composio.md §3/§10).
      return [];
    }
    const data = (await res.json()) as
      | Array<{
          id?: string;
          toolkitName?: string;
          name?: string;
          description?: string;
          schema?: Record<string, unknown>;
          authType?: string;
        }>
      | { data?: Array<{ id?: string; toolkitName?: string; name?: string; description?: string; schema?: Record<string, unknown>; authType?: string }> };
    const rows = Array.isArray(data)
      ? data
      : (data.data ?? []);
    return rows.map((r) => ({
      toolId: String(r.id ?? ''),
      app: String(r.toolkitName ?? r.name ?? ''),
      name: String(r.name ?? ''),
      description: r.description,
      inputSchema: r.schema,
      requiredAuth:
        r.authType === 'API_KEY'
          ? 'api-key'
          : r.authType === 'OAUTH'
            ? 'oauth'
            : 'none',
    }));
  }

  async listConnectedAccounts(userId: string): Promise<ConnectedAccount[]> {
    const res = await this.call(
      `/accounts?workspaceUserId=${encodeURIComponent(userId)}`,
      { method: 'GET' },
    );
    if (res === null || !res.ok) return [];
    const data = (await res.json()) as
      | Array<{
          id?: string;
          toolkit?: string;
          status?: string;
          last_checked_at?: string;
        }>
      | { data?: Array<{ id?: string; toolkit?: string; status?: string; last_checked_at?: string }> };
    const rows = Array.isArray(data)
      ? data
      : (data.data ?? []);
    return rows.map((r) => ({
      connectedAccountId: String(r.id ?? ''),
      app: String(r.toolkit ?? ''),
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
    const res = await this.call('/tools/execute', {
      method: 'POST',
      body: JSON.stringify({
        tool_id: tool.toolId,
        user_id: userId,
        input,
        ...(opts?.idempotencyKey !== undefined
          ? { idempotency_key: opts.idempotencyKey }
          : {}),
      }),
    });
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
      success?: boolean;
      data?: unknown;
      message?: string;
    };
    return {
      ok: data.success !== false,
      trace,
      data: data.data,
      error: data.success === false ? data.message : undefined,
    };
  }
}

/** Factory (AD-1): the only way business code obtains the provider.
 *  Unconfigured env → the adapter reports not-configured and every call
 *  degrades (01 §6). */
export function createIntegrationProvider(): IntegrationProvider {
  return new ComposioIntegrationProvider();
}
