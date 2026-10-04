// =============================================================================
// integrations-client.ts — device-side Composio / fn-integrations client
// (AD-3: the device enqueues the `fn-integrations` EF, like the agent client).
//
// The kernel + Composio execution are server-side (AD-12). This module is
// the device's typed door:
//   - `listAccounts()` / `discoverTools()` / `executeTool()` / `connect()`
//     all POST to `fn-integrations` with the user JWT (the Supabase client
//     carries it; the body NEVER carries identity, AD-7).
//
// AD-3: only the publishable Supabase client is used — zero provider keys
// on the device. The `COMPOSIO_API_KEY` lives in the server secret store
// and is read by the EF (AD-3), never by this client.
// =============================================================================

import type { AuroraSupabaseClient } from '@aurora/data';

/** A connected account (normalized from the v3.1 connected_accounts call). */
export interface IntegrationAccount {
  connectedAccountId: string;
  app: string;
  state: 'connected' | 'disconnected' | 'token_expired' | 'reauth_required';
  lastCheckedAt?: string;
}

/** A discovered tool (the v3.1 session tool catalog, normalized). */
export interface IntegrationTool {
  toolId: string;
  app: string;
  name: string;
  description?: string;
  inputSchema?: Record<string, unknown>;
  requiredAuth: 'oauth' | 'api-key' | 'none';
  destructive?: boolean;
}

/** A normalized tool-execution result (composio.md §6). */
export interface IntegrationToolResult {
  ok: boolean;
  trace: { provider: 'composio'; toolId: string; app: string };
  data?: unknown;
  error?: string;
}

export interface IntegrationClient {
  listAccounts(): Promise<IntegrationAccount[]>;
  discoverTools(opts?: { app?: string; limit?: number }): Promise<IntegrationTool[]>;
  executeTool(
    toolSlug: string,
    input: Record<string, unknown>,
    idempotencyKey?: string,
  ): Promise<IntegrationToolResult>;
  connect(app: string): Promise<{ connectLink: string | null; app: string; note?: string }>;
}

export function createIntegrationClient(supabase: AuroraSupabaseClient): IntegrationClient {
  return {
    async listAccounts() {
      const { data, error } = await supabase.functions.invoke('fn-integrations', {
        body: { verb: 'list_accounts' },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; data?: { accounts?: IntegrationAccount[] } };
      return env?.data?.accounts ?? [];
    },
    async discoverTools(opts) {
      const { data, error } = await supabase.functions.invoke('fn-integrations', {
        body: {
          verb: 'discover_tools',
          app: opts?.app,
          limit: opts?.limit ?? 50,
        },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; data?: { tools?: IntegrationTool[] } };
      return env?.data?.tools ?? [];
    },
    async executeTool(toolSlug, input, idempotencyKey) {
      const { data, error } = await supabase.functions.invoke('fn-integrations', {
        body: {
          verb: 'execute_tool',
          toolSlug,
          input,
          idempotencyKey,
        },
      });
      if (error) throw error;
      const env = data as {
        ok?: boolean;
        data?: IntegrationToolResult & { ok: boolean };
      };
      return env?.data as IntegrationToolResult;
    },
    async connect(app) {
      const { data, error } = await supabase.functions.invoke('fn-integrations', {
        body: { verb: 'connect', app },
      });
      if (error) throw error;
      const env = data as {
        ok?: boolean;
        data?: { connectLink: string | null; app: string; note?: string };
      };
      return env?.data as { connectLink: string | null; app: string; note?: string };
    },
  };
}
