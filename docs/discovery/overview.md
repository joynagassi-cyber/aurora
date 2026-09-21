# Discovery Module — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (waves 2–4). Authority: ADR §13 (13.1–13.9),
`01-backend` §4.5, spine AD-1/AD-8 (research providers + jobs), `03-sync` §4.2
(`DiscoveryItem`; `Gap` definitions in domain, rows owned by Progress).

1. **Purpose** — active discovery, not passive watch: "what should this person discover
   now to understand their field better, close gaps, anticipate evolution and raise
   their professional level?" (ADR §13) — technical, academic, scientific,
   professional, regulatory/normative, local/regional/international.
2. **Responsibilities** — dynamic discovery profile (domain, courses, mastered/fragile/
   missing skills, goals, estimated level + evidence, time capacity — 13.1);
   multi-source search (academic + web + professional families cross-checked, 13.2);
   curriculum-vs-professional comparison (13.5); domain living history (13.6);
   current + possible futures (13.7: strict FACT / TREND / ANALYSIS / SCENARIO /
   UNCERTAINTY separation; 2030–2050 = trajectories, not certainties, with sources
   per projection); discovery sheets (13.8, durable objects: title, why-now, factual
   summary, typed sources, confirm/refute against current knowledge, course links,
   target-domain links, skills, new concepts, open questions, recommended actions,
   tree/goal links); discovery loop (13.9: observe → need → multi-source search →
   compare & qualify → select high-utility items → explain → link to existing
   knowledge → create activity/project → measure comprehension/application/ignoring →
   improve next recommendations). Results carry `uncertain` marking when the
   `ResearchProvider` degrades (01 §6, AD-1).
3. **Non-responsibilities** — writing `Gap` rows (Progress owns the rows; definitions
   in `packages/domain`, 03 §4.2); evidence (Progress); learning execution (Learning —
   Discovery *triggers* activity creation via `DiscoveryItemCreated`).
4. **User flows** — gap-driven ("reduce my gaps"), evolution-driven ("what changed in
   my field"), horizon-driven ("2030/2040/2050 scenarios"); each item → discovery
   sheet → optional learning activity or project (13.9).
5. **Architecture** — search = persisted jobs (AD-8, `ResearchProvider` → You.com /
   Tavily / Exa, 01 §3.2); results stored per module schema (01 §4.5); heavy multi-
   source runs never block the UI.
6. **Domain model** — `DiscoveryItem` (+ profile fields), typed sources, typed
   separation fields (fact/trend/analysis/scenario/uncertainty, 13.7), `Gap`
   (definition; rows owned by Progress).
7. **Application services** — sheet use-cases (read local mirror; "work on this" →
   Learning/Learning-module command via event).
8. **Ports / interfaces** — `ResearchProvider` (optional capability: absent provider =
   `uncertain`-marked results, no product break, AD-1 last paragraph).
9. **Adapters** — research worker jobs (01 §5.1), repositories, `DataVisualizationRenderer`
   for horizon charts (G2).
10. **Data model** — 01 §4.5 (discovery items, profile, feeds); local mirror
    `discovery_items` (03 §4.2).
11. **API** — job-driven; UI reads mirrors; no screen-level HTTP.
12. **Events** — produces `DiscoveryItemCreated` (consumers: Learning = activity
    creation, Knowledge = tree links, Progress = measurement, Agent = next
    recommendations — AD-9 matrix); consumes `SkillStateChanged` (competence profile),
    `CourseImported` (gap analysis).
13. **Jobs** — multi-source runs, scenario generation (critical → Verify path, 01
    §5.6).
14. **Permissions** — none (server-side search with provider keys server-only, AD-3).
15. **Security** — provider data policies (ADR v1.7 §11); user profile data in RLS-
    protected tables; source citations preserve provenance (AD-11).
16. **Offline behavior** — feed of local mirror readable offline; new searches need
    connectivity (documented degradation, not failure).
17. **Error handling** — provider failure → retry (transient) / fallback / `uncertain`
    marking; item-level source confidence surfaced in UI (ADR §13.2 "information
    encore incertaine").
18. **Recovery** — job retry (idempotent); mirrors resync.
19. **Observability** — recommendation adoption rate, horizon-view usage, research job
    SLOs + cost (free-tier consumption via `AIUsageTracker`/research quotas, OQ-12
    drift).
20. **Tests** — event contract (01 §7), uncertainty-marking tests, loop scenario E2E
    (wave 4), source-typing assertions.
21. **Known limitations** — provider availability/quota drift (G-U4); horizon scenarios
    are explicitly non-predictive (13.7 discipline); discovery quality bounded by
    provider coverage.
22. **Dependencies** — `ResearchProvider`, Learning (activities), Knowledge (links),
    Progress (measurement), Agent (recommendations).
23. **Future evolution** — provider additions behind the port (Composio for
    specialized sources); uncertainty scoring refinement.
