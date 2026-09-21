# Modules — Registry & Index

The modular monolith (spine § Design Paradigm): one deployable unit, 10 business
modules with strong separation (AD-2), vertical slices (AD-13). Each module page
follows the 23-section structure (mission §32).

| Module | Page | Module owner (03 §4.2) | Wave |
|---|---|---|---|
| Identity | below (§2) | Identity | 1 (Auth Supabase, 01 §8.1) |
| Productivity | [productivity/overview.md](../productivity/overview.md) | Productivity | 2 |
| Learning | [learning/overview.md](../learning/overview.md) | Learning | 2 |
| Knowledge (KB + Semantic Tree) | [knowledge/overview.md](../knowledge/overview.md) | Knowledge | 2 |
| Discovery | [discovery/overview.md](../discovery/overview.md) | Discovery | 2–4 |
| Progress | [progress/overview.md](../progress/overview.md) | Progress | 2–4 |
| Agent | [agent/kernel.md](../agent/kernel.md) | Agent | 3 |
| Scientific | [scientific-engine/overview.md](../scientific-engine/overview.md) | Scientific | 2–3 |
| Artifact | [artifacts/overview.md](../artifacts/overview.md) | Artifact | 2 |
| Integrations | [integrations/overview.md](../integrations/overview.md) | Integrations | 2 |
| Data (local-first layer) | [data/local-first.md](../data/local-first.md) | Data team | 1 |

Cross-module rules (AD-2/AD-9/AD-13/AD-15): read another module's **public contract
types only**; declare event consumers in your Contract Pack; write **only** your own
module's tables; consume AD-15 types from `packages/domain`, never re-declare them.

## 1. Capability → architecture map (spine)

Tasks/goals/calendar/focus/habits → Productivity (AD-7/AD-8/AD-14) · courses/skills/
reviews/FSRS → Learning + Knowledge Base (AD-6/AD-11) · semantic tree → Knowledge
(truth) + `@xyflow/react` (view, AD-6/AD-10) · discovery → Discovery via
`ResearchProvider` (AD-1/AD-8) · progress → Progress + Event History (AD-6/AD-9) ·
AI orchestration → Agent Kernel + AI Router/Gateway (AD-4/AD-5/AD-12) · math & units →
Scientific engine (swappable, AD-8) · artifacts & file visualization → Artifact Hub +
renderer contracts (AD-10) · external integrations → Integrations
(`IntegrationProvider` = Composio, AD-1) · parallel development → Contract Packs + PR
gates (AD-13).

## 2. Identity module (compact page)

1. **Purpose** — the user's identity, auth and profile/preferences.
2. **Responsibilities** — Supabase Auth (email/social), session lifecycle,
   `UserContext` (AD-15 entity, owner Identity, 03 §4.2: `user_context` local table):
   profile, preferences, silence windows (coaching cadence, ADR §13), theme preference
   (v2 enum, nullable — coherence review mustFixForV2 #5; light default fallback, 05 §1).
3. **Non-responsibilities** — business entities (owning modules); RLS policy design
   (Data team, 01 §2.2).
4. **User flows** — onboarding (05 §4.1), login/refresh (01 §6: JWT auto-refresh;
   auth failure → login screen; the device cannot call Edge Functions without
   identity), settings (theme/silence windows).
5. **Architecture** — Supabase Auth (server); local session + `user_context` mirror.
6. **Domain model** — `UserContext` (+ preferences including theme v2 enum).
7. **Application services** — session use-cases; preference commands.
8. **Ports / interfaces** — none external (auth is platform infrastructure).
9. **Adapters** — Supabase Auth client (data layer), local store.
10. **Data model** — `user_context` (Identity, 03 §4.2).
11. **API** — Supabase Auth endpoints (via `packages/data`); no custom auth API in V1.
12. **Events** — none produced in V1's 9-event vocabulary.
13. **Jobs** — none.
14. **Permissions** — owns the permission-preference surface consumed by other modules
    (see permission-matrix).
15. **Security** — RLS base (every row carries `user_id`); token refresh discipline
    (01 §6).
16. **Offline behavior** — app usable offline with a valid local session; auth
    required again on re-auth triggers.
17. **Error handling** — 01 §6 auth error paths.
18. **Recovery** — token refresh; re-login.
19. **Observability** — auth failure rates (Sentry).
20. **Tests** — RLS penetration (01 §7), refresh/expiration flows.
21. **Known limitations** — V1 auth = Supabase default providers only (no
    enterprise IdP).
22. **Dependencies** — every module (identity = RLS root).
23. **Future evolution** — SSO/enterprise (post-V1).
