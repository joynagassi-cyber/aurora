// agent-runs.ts — the agent_runs device hook (AD-7 local-first read side).
//
// `agent_runs` (0008) is a server-owned table with per-user RLS; the
// device reads ONLY through the publishable Supabase client (AD-3). This
// hook is the thin mirror surface the /agent page polls while a run is
// in flight — honest empty state when the row is absent (AD-7: never
// fake data), the running status drives the 5-state UX phase (AD-13).

import { useQuery } from '@tanstack/react-query';
import { qk } from './query-client';
import { useMobileData } from './context';
import type { AgentRunRow } from '../lib/agent-client';

export type { AgentClient, AgentRunRequest, AgentRunHandle, AgentRunRow } from '../lib/agent-client';

/**
 * Poll the `agent_runs` mirror row for a run. Terminal statuses
 * (`completed` / `failed` / `cancelled`) stop the poll; `running`
 * keeps a short cadence (the job executor updates the row on stage
 * advances — no provider stream crosses the device, F-09).
 */
export function useAgentRun(runId: string | undefined) {
  const { agent } = useMobileData();
  return useQuery<AgentRunRow | null>({
    queryKey: qk.agent.run(runId ?? ''),
    queryFn: async () => (agent && runId ? agent.run(runId) : null),
    enabled: runId !== undefined && runId !== '' && agent !== undefined,
    refetchInterval: (query) => {
      const s = query.state.data?.status;
      return s === 'completed' || s === 'failed' || s === 'cancelled' ? false : 3000;
    },
    retry: false,
  });
}
