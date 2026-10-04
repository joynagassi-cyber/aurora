# Composio Integration Specification (master mission S33-35)

**Status:** `IMPLEMENTED_CORE` (wave 2, owner Integrations module + Agent).
- v3.1 sessions API wired into `packages/integrations/src/composio.ts` +
  `supabase/functions/fn-integrations` (migration 2026-10-04).
- Device-side `integrations-client.ts` + `/integrations` page wired (AD-3
  publishable scope only).
- **External blocker (open):** Spotify custom OAuth app (not managed by
  Composio, §2.2). Everything else is code-complete.
Authority: ADR S7/S8 (`IntegrationProvider`), `01-backend` S4.7/S5.2, `03-sync` S4.2
(`Automation` owner = Integrations), `04-mobile` S3.4.
**Rule (mission S33):** Composio is a **tool/integration layer**, NOT an AI provider.
It sits behind the `IntegrationProvider` port; no AI routing logic touches it directly.

## 1. Purpose

Composio provides tool discovery, managed authentication, connected accounts, and
execution on a large catalog of external applications (Gmail, Calendar, Notion,
Slack, GitHub, etc.). Aurora does NOT vendor its own per-app SDKs for V1: all
external-app tool access goes through Composio behind the `IntegrationProvider`
port (AD-1 vendor isolation). The Agent discovers and executes Composio tools
through its Tool Context; no external tokens are held on the device (AD-3).

## 2. Architecture

```
Agent Kernel (server)
  |
  | tool call (typed, via Tool Registry)
  v
Composio adapter (server-side, packages/integrations)
  |  sessions API v3.1 + meta-tools
  v
Composio API (external, backend.composio.dev/api/v3.1)
  |
  | execution result (normalized)
  v
Agent Result Normalizer (kernel S12)
  |
  | AIResponseEnvelope-style trace (provider="composio", model="tool:<toolId>")
  v
owning module applies domain command / emits AD-9 event
```

- **No device-held Composio credentials.** All auth (OAuth tokens, API keys,
  connected accounts) lives server-side in the Composio service. Aurora server
  calls Composio with its own service token; the user's connected-account
  tokens are managed by Composio (per-user scoping, S35).
- **AD-1:** business code imports `IntegrationProvider` (port), never the
  Composio SDK. A vendor swap = adapter swap.
- **AD-3:** no external secrets in the mobile bundle.

### 2.1 Composio v3.1 — sessions API (migration 2026-10-04)

> **v3.1 est le contrat courant** (REST `backend.composio.dev/api/v3.1`).
> Le v1 (`/tools`, execute plat) est **gelé (legacy)** — ne pas réutiliser.
> La migration de 2026-10-04 a aligné `composio.ts` + `fn-integrations` sur
> v3.1 (sessions + meta-tools).

**Sessions** (identités) :
```
POST /sessions          { user_id }                     → { session_id }
GET  /sessions/{id}/tools?toolkit=SPOTIFY&limit=10     → meta-tools + catalog
GET  /sessions/{id}/connected_accounts                  → comptes connectés
POST /sessions/{id}/tools/execute { tool_slug, input, idempotency_key? }
```

**Meta-tools** (exposés par la session au client MCP/agent) :
`COMPOSIO_SEARCH_TOOLS`, `COMPOSIO_MULTI_EXECUTE_TOOL`,
`COMPOSIO_MANAGE_CONNECTIONS`, `COMPOSIO_WAIT_FOR_CONNECTIONS`,
`COMPOSIO_GET_TOOL_SCHEMAS`, `COMPOSIO_REMOTE_WORKBENCH`,
`COMPOSIO_REMOTE_BASH_TOOL`.

**Slug des outils** : `{TOOLKIT}_{ACTION}` en MAJUSCULES. Outils Spotify
réels (catalogue, 88 outils) : `SPOTIFY_START_RESUME_PLAYBACK`,
`SPOTIFY_SEARCH_FOR_ITEM`, `SPOTIFY_GET_CURRENT_USER_S_PLAYLISTS`, …
L'UI **n'invente jamais** un slug — elle pioche dans le catalogue runtime
(skill composio §4).

### 2.2 Spotify & OAuth non géré (gotcha majeur)

**Spotify est le SEUL toolkit des 14 (Gmail, Google Calendar, Google Docs,
Google Drive, Google Sheets, Outlook, Notion, Slack, GitHub, Todoist,
ClickUp, Trello, YouTube — 13) qui n'a PAS d'OAuth géré par Composio.**

Conséquences :
- Les 13 autres toolkits : « Composio-managed OAuth available? **Yes** » →
  le connect utilise uniquement `COMPOSIO_API_KEY` du projet (platform),
  sans app maison. Le connect est un `POST /sessions/{id}/connections`
  (Connect Link) qui retourne une URL à ouvrir (Composio gère le callback,
  le refresh, le token store — AD-3).
- **Spotify** : « Composio-managed OAuth available? **No** » → il faut créer
  une **app Spotify Developer** (client_id + secret) + un **Composio
  AuthConfig** qui référence cette app maison. L'app a les scopes
  `streaming`, `user-library-read`, `playlist-read-private`, `playlist-modify-private`,
  `user-read-email`, `user-read-private`. Tant que l'app maison n'est pas
  déclarée côté Composio, `SPOTIFY_*` reste « non connectable ».

> C'est un **blocage externe** (Spotify Developer Dashboard + Composio
> AuthConfig) que l'IA ne peut PAS faire elle-même. Tout le reste du pipeline
> (adapter v3.1, EF, UI, focus page) est code-complet; seul ce point exige
> une action humaine.

## 3. Tool discovery & schema

- Composio exposes a **tool catalog** (toolkits per app). Aurora queries it at
  runtime (not at build time) through the `IntegrationProvider.discoverTools()`
  method (proposed additive contract, S65).
- Each tool has: `toolId`, `app`, `name`, `description`, `inputSchema`
  (JSON Schema), `outputSchema`, `requiredAuth` (OAuth / API key / none),
  `destructive` flag.
- The Agent's **Tool Registry** (kernel S12) merges: (a) internal capabilities
  (feature-agentability-matrix.md) + (b) Composio tools filtered by
  availability (user has a connected account for that app).
- **Tool Router** logic (server-side): given a plan step that needs an external
  capability, the router matches the required app + action against the
  Composio catalog; if no match, the tool is marked `unavailable` and the
  kernel degrades (AD-1: optional capability absent = product keeps working).

## 4. Connected accounts & auth

- **Auth Config** (server-side, per user): OAuth app registrations, API key
  vault, connected-account mapping (`userID` <-> `connectedAccountID`).
- **OAuth flow:** user initiates in Aurora (deep link to Composio auth page
  or in-app WebView); callback lands server-side (Supabase Edge Function or
  Composio webhook); token stored in Composio; Aurora stores only the
  `connectedAccountID` + connection state.
- **Connection state:** `connected | disconnected | token_expired |
  reauth_required`. The kernel checks state before each tool call; a
  `reauth_required` state triggers a user-facing "reconnect" prompt (UI
  `AgentRunState`), not a silent failure.
- **Scopes:** per-app, declared in the Auth Config. Aurora never requests
  scopes beyond what the tool requires (least-privilege).
- **Token refresh:** handled by Composio server-side; Aurora does not manage
  refresh tokens.

## 5. Webhooks / triggers

- Composio supports webhook triggers (e.g., "when a Gmail email arrives").
  V1: **not in scope** for Aurora's agent loop. The Agent is request-driven
  (user intent). Webhook-to-agent is a Phase 2 / wave 4+ extension (recorded,
  not built).
- Cron-based automations (ADR S8, `Automation` entity) remain the scheduled
  action mechanism; they do not go through Composio webhooks.

## 6. Agent + Composio flow (S34)

Canonical example: "Envoie mon document par Gmail."

```
Intent: send_artifact (external: Gmail)
  | Context: artifact ID resolved (Artifact module, local mirror)
  | Capability: artifact.send_external (Composio Gmail tool)
  | Auth check: Gmail connectedAccountID = connected?
  |   yes -> proceed
  |   no  -> AgentRunState shows "Connect Gmail" CTA -> Composio OAuth flow
  |          -> retry after connect
  | Tool call: gmail.send(to, subject, attachment=artifact r2Key presign)
  | Execute: Composio executes -> normalized result {ok, messageId}
  | Verify: attachment size / recipient domain sanity (kernel Verification Engine)
  | Continue: AgentRunState shows "Sent: <subject> to <recipient>"
```

- **The Agent never holds external tokens.** Tool execution = server-side
  Composio call with the user's `connectedAccountID`; the kernel sees a
  normalized result, not a raw OAuth bearer.
- **Confirmation:** sending an email = important action -> Confirmation
  Engine (kernel S12) prompts the user before execution (ADR S5).

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Tool not found / catalog drift | `unavailable`; kernel degrades (AD-1); user informed |
| Auth expired / `reauth_required` | UI prompt to reconnect; session pauses at this step; retry on success |
| Composio API timeout | bounded retry (3x, exponential backoff per AD-5 policy for
  non-AI calls); then `JobCompleted{failed}` + `AgentRunState` error surface |
| Tool execution error (401/403/429) | 429 = respect `retry-after`; 401/403 =
  reauth or scope-missing alert; never key-rotate or escalate privileges |
| Partial execution (e.g., email sent but file not attached) | result marked
  `degraded`; kernel records which sub-steps succeeded/failed; user can retry
  the failed sub-step only (idempotency key per sub-step) |

## 8. Security (S35)

- **Per-user scoping:** every Composio call carries `userID` +
  `connectedAccountID`; RLS on Aurora's `integrations_state` table enforces
  that a user can only query/execute their own connections.
- **Credentials server-side:** OAuth tokens, API keys, session cookies for
  external apps are held by Composio (or Aurora's server secret store if
  self-hosted); **never in the mobile bundle, never in local SQLite**.
- **Audit:** every tool execution = a `job_logs` row (job kind
  `integration_<toolId>`) + PostHog event `composio_tool_executed`
  (toolId, app, status, latency -- NO payload content, NO document bodies).
- **Permission boundary:** the kernel's Permission Engine (kernel S12)
  classifies each Composio tool call as read / write / destructive based on
  the tool schema's `destructive` flag + app-scoped policy. Destructive
  external actions (e.g., delete a Slack message) require confirmation.

## 9. Data model

| Entity | Owner | Table | Notes |
|---|---|---|---|
| `integration_state` | Integrations | `integrations_state` (01 S4.7) | per-user, per-app connection state |
| `Automation` | Integrations | `automations` (03 S4.2) | Cron-triggered actions (separate from Composio; both under Integrations module) |
| `connectedAccountID` | Composio (external) | -- | stored in `integrations_state.connection_ref` |

## 10. Limits & documented constraints

- Composio coverage per app is provider-dependent; a tool that works in
  Composio today may be removed or renamed (catalog drift). The registry
  re-syncs on each discovery call (no cached tool list in V1).
- Rate limits on Composio per-plan; the kernel's `AIBudgetManager` does not
  manage Composio quota (it is not an AI provider). A per-integration quota
  tracker (`integration_usage`) is a wave-2+ addition if needed.
- **No V1 desktop Composio adapter.** Desktop (Phase 2) reuses the same
  server-side Composio calls; no device-local Composio SDK.

## 11. Tests

- Tool discovery returns only available tools (filtered by connection state).
- Unconnected app -> tool marked `unavailable`, kernel degrades.
- Auth expiry -> reauth flow completes, tool retry succeeds.
- Destructive tool call -> Confirmation Engine blocks until user answers.
- Composio 429 -> `retry-after` honored, no escalation.
- No external secret in mobile bundle (anti-leak test, same class as 04 S7.2e).
- RLS: user A cannot read user B's `integrations_state`.
