# E2E Agent Scenarios (master mission S60)

20 mandatory end-to-end scenarios. Each scenario traces:
Natural Language -> Intent -> Context -> Capabilities -> Tools -> Modules ->
Backend -> UI transitions -> Result -> Progress.
All capabilities referenced are from docs/agent/feature-agentability-matrix.md.
All events are from the 9-event vocabulary (AD-9, 01 S3.3).
Status: `DESIGNED_NOT_IMPLEMENTED` (wave 4+; E2E tooling = OQ-08, Playwright assumption).

## Convention

- Capability IDs use the feature-agentability-matrix vocabulary.
- UI transitions use the 02 S6.1 route map + the command bus (kernel S15).
- Module = the owning module per 03 S4.2.
- "Confirm" = Confirmation Engine (ADR S5) blocks the user until answered.
- Progress evidence = the sole-producer rule (F-07: only Progress emits
  `ProgressEvidenceCreated`).

---

## S1. "Organise ma journée."

- **Intent:** `planning.daily` (typed TaskProfile: complexity=medium, tools=productivity)
- **Context:** Productivity Context (today's calendar, open tasks, due-today items,
  available time blocks), Personal Context (exam period? silence windows).
- **Capabilities:** `planning.daily` -> `task.create` (if missing) + `calendar.schedule`
- **Tools:** Plan + EventUpdateCommand + TaskCreateCommand (owning module: Productivity)
- **Modules:** Productivity (planner + calendar + tasks)
- **Backend:** `LocalCommandRepository.apply('productivity', [EventUpdateCommand, ...])`
  -> upsync to Supabase; no AI call needed (planning is deterministic)
- **UI:** Home -> planning view (05 S4.3); `AgentRunState` shows the plan summary;
  "Confirmer le plan" CTA (replan discarding old plan = CONFIRMATION_REQUIRED)
- **Result:** Day organized: time blocks on calendar, tasks reordered
- **Events:** None (no completed task yet; planning is a write, not an event)
- **Progress:** `planning` adherence tracked (planned vs actual at day end, S18.3)

## S2. "J'ai examen vendredi, prepare mon plan de revision."

- **Intent:** `planning.replan` + `learning.session.start` (compound)
- **Context:** Learning Context (courses, skill states from Progress mirrors),
  Personal Context (exam = declared period type in UserContext)
- **Capabilities:** `progress.analyze` (weak skills) -> `planning.daily` (spread
  study blocks) -> `learning.sheet.generate` (revision sheets per weak topic)
- **Tools:** Progress mirrors read (read-only) + calendar time blocks +
  `artifact_gen` job (revision sheet generation, AI + fidelity check)
- **Modules:** Progress (read skill states), Learning (sheets), Productivity (calendar),
  Artifact (export)
- **Backend:** `progress_snapshots` + `skill_states` read (local mirrors);
  `fn-job-dispatcher` -> `artifact_gen` job (server); R2 upload +
  `ArtifactGenerated` (F-06 post-upload)
- **UI:** Progress dashboard -> weak-skill list -> study plan preview ->
  "Confirmer" -> calendar updated + sheet available in Artifacts
- **Events:** `ArtifactGenerated` (sheet ready); `GoalUpdated` if a goal is linked
- **Progress:** study-plan adherence becomes `ProgressEvidence` on completion

## S3. "Cre deux heures de geotechnique demain matin."

- **Intent:** `calendar.schedule` (specific: 2h block, geotechnique course, tomorrow AM)
- **Context:** Learning Context (geotechnique = course ID + subject), Productivity
  Context (tomorrow's calendar, availability)
- **Capabilities:** `calendar.schedule` (CONFIRMATION_REQUIRED)
- **Tools:** EventUpdateCommand (create time block 09:00-11:00, courseId ref)
- **Modules:** Productivity (calendar) + Learning (course link, read-only)
- **Backend:** `LocalCommandRepository.apply('productivity', EventUpdateCommand)` -> upsync
- **UI:** Calendar -> new block visible; `AgentRunState`: "Bloc geotechnique 09-11
  demain matin, confirme ?" -> Confirm
- **Result:** Time block persisted
- **Events:** None
- **Progress:** N/A (scheduling only)

## S4. "Lance une session Focus de 90 minutes."

- **Intent:** `focus.start` (specific: 90 min)
- **Context:** Productivity Context (open tasks, current time), DPC state
  (v1.8: `isBlockingAvailable()` detection)
- **Capabilities:** `focus.start` (CONFIRMATION_REQUIRED, session start)
- **Tools:** `FocusController.startSession({duration: 90, blocklist: []})`
  (in-app timer + `reduceForFocus(true)`; DPC: + `applyBlocklist` if blocklist non-empty)
- **Modules:** Productivity (FocusSession row) + platform (`FocusController` / `DpcAdapter`)
- **Backend:** `focus_sessions` table (Productivity, 03 S4.2); no AI call
- **UI:** Focus screen (05 S4.4) -> timer active; `AgentRunState`: "Session Focus
  90 min demarree"
- **Events:** None at start; `FocusSessionCompleted` would be an internal
  transition (not one of the 9 AD-9 events; it is a module-internal state change)
- **Progress:** at session end, `FocusSessionBilan` -> Progress sole-producer
  emits `ProgressEvidenceCreated` (discipline evidence, S18.3)

## S5. "Bloque TikTok et WhatsApp pendant cette session."

- **Intent:** `focus.block` (specific: TikTok, WhatsApp, during active focus session)
- **Context:** DPC state (v1.8: `isBlockingAvailable()`), blocklist history
- **Capabilities:** `focus.block` (PLATFORM_DEPENDENT: android + DPC-provisioned, OQ-17;
  CONFIRMATION_REQUIRED: blocklist)
- **Tools:** `DpcAdapter.precheckBlocklist(['com.tiktok...','com.whatsapp...'])` ->
  `DpcAdapter.applyBlocklist([...], true)` (`setPackagesSuspended`)
- **Modules:** Productivity (FocusSession.blocklist update) + platform (DpcAdapter)
- **Backend:** `focus_sessions.blocklist` (suspendability results per package)
- **UI:** Focus screen -> blocklist shown with per-package status
  (suspendable / not-suspendable / aurora-protected); "Confirmer le blocage" CTA
- **Result:** `setPackagesSuspended([tiktok, whatsapp], true)` applied;
  Internet stays active; Aurora stays active
- **Events:** None (system-level, not an AD-9 event)
- **Progress:** at session end, blocklist honored = discipline evidence

## S6. "Je ne comprends pas cette notion, explique-la a mon niveau."

- **Intent:** `learning.mirror.analyze` / tutor capability (natural-language explanation)
- **Context:** Learning Context (course, chapter, concept being studied),
  Expert Skills (user's demonstrated understanding level from Progress),
  Semantic Context (SemanticTree node for the concept)
- **Capabilities:** `learning.mirror.analyze` (FULL, online)
- **Tools:** Knowledge retrieval (FTS + pgvector over the course corpus) +
  AI call (`AIProvider.complete` via router: ROUTINE -> cheaper model;
  the explanation is not critical, no ScientificEngine verification needed)
- **Modules:** Knowledge (retrieval, server-only AD-12), Learning (course context),
  Agent (AI call + result)
- **Backend:** `fn-agent-run` (server) -> AI Gateway -> provider; result =
  `AIResponseEnvelope` + provenance (AD-11: source refs attached)
- **UI:** Current screen (concept detail) -> explanation panel appears below
  the concept; source citations rendered; "Verifie-moi" CTA -> triggers S7
- **Events:** None
- **Progress:** if the user then quizzes (S7), the result feeds `ProgressEvidenceCreated`

## S7. "Verifie si j'ai vraiment compris ce chapitre."

- **Intent:** `learning.mirror.analyze` (verification mode: quiz the user)
- **Context:** Learning Context (chapter, related concepts in Semantic Tree),
  Progress Context (prior evidence for this chapter)
- **Capabilities:** `qcm.generate` (20-item QCM) + `flashcard.generate`
  (optional, for weak items)
- **Tools:** `artifact_gen` job (QCM generation, AI + fidelity check) +
  in-session QCM review (local)
- **Modules:** Learning (QCM + flashcards), Progress (evidence recording),
  Agent (AI generation)
- **Backend:** `fn-job-dispatcher` -> QCM generation job (server, AI);
  QCM items stored in `learning_items` (Learning); review = local mirror read
- **UI:** QCM screen (05 S4.7) -> answer 20 questions -> score + error
  analysis; weak items -> flashcard CTA
- **Events:** `FlashcardReviewed` (if flashcards used); Progress sole-producer
  emits `ProgressEvidenceCreated` (understanding evidence, S18.3)
- **Progress:** QCM score + error pattern -> `SkillState` update -> `SkillStateChanged`

## S8. "Fais-moi une fiche fidelle au cours."

- **Intent:** `learning.sheet.generate` (specific: fidelity = corpus-dominant)
- **Context:** Learning Context (course, selected chapters), Knowledge Context
  (source documents in R2)
- **Capabilities:** `qcm.generate` / `flashcard.generate` / `learning.sheet`
  (FULL, online)
- **Tools:** `artifact_gen` job: AI extracts structured content (7 structures,
  ADR S17) + fidelity check (corpus dominance + formula memory) + export
  (MD/PDF/DOCX/PNG)
- **Modules:** Learning (sheet content), Knowledge (source), Artifact (export + R2)
- **Backend:** server job -> AI Gateway -> provider; R2 upload (presigned);
  `ArtifactGenerated` emitted post-upload (F-06)
- **UI:** Learning -> "Generer fiche" -> loading (job) -> artifact card
  with preview (05 S4.6); fidelity badge visible; "Fichu" -> Artifacts
- **Events:** `ArtifactGenerated` (producer: Artifact; consumers: Knowledge,
  Learning, UI [OQ-05])
- **Progress:** sheet reviewed = application evidence (S18.3)

## S9. "Teste-moi avec 20 QCM."

- **Intent:** `qcm.generate` (specific: 20 items, topic from context)
- **Context:** Learning Context (topic/chapter), Progress Context (weak areas
  for targeted items)
- **Capabilities:** `qcm.generate` (FULL, online)
- **Tools:** `artifact_gen` job (20-item QCM, AI + fidelity) + in-session review
- **Modules:** Learning (items), Agent (AI), Progress (evidence)
- **Backend:** generation job; QCM items in `learning_items`; review local
- **UI:** QCM screen -> 20 questions -> score + per-question feedback;
  error analysis (recurring errors, S18.3)
- **Events:** `FlashcardReviewed` (if items -> flashcards);
  `ProgressEvidenceCreated` (Progress sole producer)
- **Progress:** QCM accuracy -> `SkillState` update; recurring errors ->
  targeted practice recommendation

## S10. "Analyse mes erreurs."

- **Intent:** `progress.analyze` (specific: error patterns)
- **Context:** Progress Context (evidence history, `progress_events` server-only),
  Learning Context (course/chapter scope)
- **Capabilities:** `progress.analyze` (FULL, offline-capable for mirrors;
  deep analysis = online)
- **Tools:** read `progress_evidences` + `progress_events` (S jobs: aggregation,
  01 S5.2) + `skill_states` mirrors
- **Modules:** Progress (analysis), Learning (course context, read)
- **Backend:** S jobs (aggregation + causal analysis, S18.4: correlation !=
  causation discipline); results in `progress_snapshots`
- **UI:** Progress dashboard -> error-pattern view (by topic, by skill,
  by time); "Replanifier" CTA -> triggers S19
- **Events:** None (analysis is a read + job, not an AD-9 event)
- **Progress:** the analysis output = input for replanning

## S11. "Que dois-je apprendre ensuite ?"

- **Intent:** `discovery.gaps` + `progress.analyze` (compound: next learning targets)
- **Context:** Progress Context (skill states, trajectories S18.5), Learning
  Context (completed courses, pending), Discovery Context (gap definitions)
- **Capabilities:** `progress.analyze` (read) + `discovery.research` (if
  external knowledge needed) + `learning.session.start` (plan next items)
- **Tools:** Progress mirrors read + (optionally) `research` job (external,
  `ResearchProvider`); results = ranked list of next items
- **Modules:** Progress (read), Discovery (gaps + research), Learning (next
  items)
- **Backend:** `skill_states` + `progress_trajectories` (server mirrors);
  optional `research` job (heavy, AD-8)
- **UI:** Progress -> "Next up" view -> ranked list with rationale;
  "Planifier" CTA -> calendar blocks
- **Events:** `DiscoveryItemCreated` (if a gap becomes a discovery item);
  `GoalUpdated` (if a goal is created)
- **Progress:** the gap->plan loop feeds S18.5 trajectories

## S12. "Recherche ce qui a recemment change dans mon domaine."

- **Intent:** `discovery.research` (specific: recency filter, user's domain)
- **Context:** Discovery Context (user profile, domain, prior findings),
  Personal Context (professional vs academic domain)
- **Capabilities:** `discovery.research` (FULL, online-required)
- **Tools:** `research` job (server, AD-8): `ResearchProvider` multi-source
  (You.com / Tavily / Exa); FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY
  separation (S13.7); `uncertain` marking when provider absent (01 S6)
- **Modules:** Discovery (findings), Knowledge (ingest if user saves)
- **Backend:** `fn-job-dispatcher` -> `research` job; results in
  `discovery_items` + `sources`; `DiscoveryItemCreated` event
- **UI:** Discovery screen -> research results with source badges +
  confidence markers; "Ajouter au Knowledge Base" CTA
- **Events:** `DiscoveryItemCreated` (producer: Discovery; consumers:
  Learning, Knowledge, Progress, Agent)
- **Progress:** new gap knowledge -> `SkillStateChanged` (if a skill is
  affected)

## S13. "Transforme cette decouverte en plan d'apprentissage."

- **Intent:** compound: `discovery.sheet` -> `learning.session.start` ->
  `planning.daily`
- **Context:** Discovery Context (the specific discovery item), Learning
  Context (relevant courses), Productivity Context (available time)
- **Capabilities:** `discovery.sheet` (read) + `learning.session.start` +
  `planning.daily` (CONFIRMATION_REQUIRED)
- **Tools:** Discovery sheet content -> Learning items (QCM / flashcards /
  exercises) -> calendar time blocks
- **Modules:** Discovery (item), Learning (items), Productivity (planning)
- **Backend:** `DiscoveryItemCreated` already emitted; learning items created
  (Learning module); calendar blocks (Productivity); `GoalUpdated` if a goal
  is linked
- **UI:** Discovery -> "Planifier" -> study plan preview -> Confirm ->
  calendar updated + learning items in Learning screen
- **Events:** `GoalUpdated` (if goal created); learning item creation is
  module-internal (no AD-9 event)
- **Progress:** plan adherence -> S18.3 evidence on completion

## S14. "Genere un PDF de ma fiche."

- **Intent:** `artifact.generate` (specific: PDF format, from existing sheet)
- **Context:** Artifact Context (the sheet artifact ID), Learning Context
- **Capabilities:** `artifact.generate` (FULL, online + R2)
- **Tools:** `artifact_gen` job: render sheet -> PDF (server-side, R2 upload,
  presigned URL)
- **Modules:** Artifact (generation + R2), Learning (source content)
- **Backend:** `fn-job-dispatcher` -> `artifact_gen` (PDF); R2 put;
  `ArtifactGenerated` post-upload (F-06)
- **UI:** Learning/Artifacts -> "PDF" CTA -> job loading ->
  artifact card with download/preview; `ArtifactGenerated` triggers
  Artifacts screen refresh (UI consumer = OQ-05)
- **Events:** `ArtifactGenerated` (producer: Artifact)
- **Progress:** N/A (export is not a learning evidence)

## S15. "Ajoute cette information a mon Knowledge Base."

- **Intent:** `knowledge.retrieval` (write path: add a source)
- **Context:** Knowledge Context (existing tree, related nodes), user-provided
  content (URL, text, file)
- **Capabilities:** (no dedicated `knowledge.add` capability in V1 matrix;
  the Agent uses `artifact.generate` + Knowledge ingestion via
  `CourseImported` or manual entry) -> **status: PARTIAL** (Knowledge write
  path is limited to course import + OCR; free-form "add fact" = manual
  entry in V1, documented limitation)
- **Tools:** if file: `DocumentScanner` + `ocr` job -> `CourseImported`;
  if text: manual entry flow (UI)
- **Modules:** Knowledge (ingestion), Artifact (OCR), Learning (course link)
- **Backend:** `fn-import-course` + `ocr` job; Knowledge ingestion
  (Postgres FTS + pgvector + R2)
- **UI:** Knowledge screen -> "Ajouter" -> capture/import flow ->
  `CourseImported` event -> tree node created
- **Events:** `CourseImported` (producer: Learning; consumers: Knowledge,
  Discovery, Progress)
- **Progress:** new knowledge -> potential `SkillStateChanged`

## S16. "Montre-moi le concept dans l'arbre sémantique."

- **Intent:** `knowledge.tree` (navigate / inspect)
- **Context:** Semantic Context (the concept, its parent/child nodes,
  bridges)
- **Capabilities:** `course.search` (full, PARTIAL offline = mirror browse);
  `knowledge.tree` inspection is USER_ONLY (the user navigates the tree;
  the Agent can deep-link to a node via the command bus)
- **Tools:** `SemanticTreeRenderer` (AD-10, lazy level-1 + incremental Dagre);
  deep link: `NavigationIntent { route: '/knowledge/tree/:nodeId' }`
- **Modules:** Knowledge (tree data + renderer contract)
- **Backend:** local mirror read (offline-capable); server retrieval for
  expanded levels (online, AD-12)
- **UI:** Knowledge -> tree view -> node expanded; Agent can open the
  specific node via deep link (command bus, kernel S15)
- **Events:** None
- **Progress:** N/A (navigation)

## S17. "Analyse mes progres de cette semaine."

- **Intent:** `progress.analyze` (specific: weekly window)
- **Context:** Progress Context (weekly snapshots, evidence, skill states),
  Productivity Context (completed tasks, focus sessions)
- **Capabilities:** `progress.analyze` (FULL; mirrors offline, deep = online)
- **Tools:** read `progress_snapshots` + `progress_evidences` + `skill_states`
  (local mirrors); S jobs for aggregation if online
- **Modules:** Progress (analysis + dashboards), Productivity (task/focus data,
  read-only)
- **Backend:** local mirror read (offline); server S jobs for trends
  (online); results in `progress_snapshots`
- **UI:** Progress dashboard -> weekly view (G2 charts, `ChartSpec`);
  "Replanifier" CTA if delay detected
- **Events:** None
- **Progress:** the analysis itself is Progress output; delay detection ->
  S18 replanning

## S18. "Pourquoi suis-je en retard ?"

- **Intent:** `progress.analyze` (causal analysis, S18.4)
- **Context:** Progress Context (planned vs actual, evidence gaps),
  Productivity Context (task completion rates, focus adherence),
  Personal Context (period type, external events)
- **Capabilities:** `progress.analyze` (FULL)
- **Tools:** S jobs: causal analysis (correlation != causation discipline,
  S18.4); results = ranked causes with confidence
- **Modules:** Progress (causal engine), Productivity (data source, read)
- **Backend:** server S job; results in `progress_snapshots`
- **UI:** Progress -> "Retards" view -> causal list with evidence refs;
  "Replanifier" CTA -> S19
- **Events:** None
- **Progress:** the cause analysis feeds the replanning decision

## S19. "Replanifie ma semaine."

- **Intent:** `planning.replan` (CONFIRMATION_REQUIRED: replan discards old plan)
- **Context:** Productivity Context (current week plan, uncompleted tasks),
  Progress Context (detected delay from S18), Personal Context
- **Capabilities:** `planning.replan` + `calendar.schedule` + `task.update`
  (bulk postpone)
- **Tools:** Plan rebuild (deterministic: available time + task priorities +
  delay offset); EventUpdateCommand + TaskUpdateCommand (postpone)
- **Modules:** Productivity (planner + calendar + tasks)
- **Backend:** `LocalCommandRepository.apply('productivity', [...])` -> upsync;
  plan history preserved (ADR S13: "recalcul du planning restant sans
  detruire l'historique")
- **UI:** Calendar -> new plan preview (diff from old plan); "Confirmer"
  -> calendar updated; old plan visible in history
- **Events:** `TaskCompleted` (if any tasks completed during replan);
  `GoalUpdated` (if a goal deadline shifts)
- **Progress:** replan adherence -> S18.3 evidence on next cycle

## S20. "Envoie ce document par Gmail."

- **Intent:** `artifact.send_external` (Gmail via Composio)
- **Context:** Artifact Context (the document, R2 key, presigned URL),
  Integrations Context (Gmail connectedAccountID)
- **Capabilities:** (Composio tool: `gmail.send`; FULL if Gmail connected;
  USER_ONLY if not connected -> "Connect Gmail" prompt)
- **Tools:** `IntegrationProvider` -> Composio `gmail.send(to, subject,
  attachment=presignedUrl)`; Confirmation Engine (sending = important)
- **Modules:** Artifact (source), Integrations (Composio adapter), Agent (orchestration)
- **Backend:** server-side Composio call (no device-held tokens, AD-3);
  result = `{ok, messageId}` normalized
- **UI:** Artifact screen -> "Envoyer" -> recipient input -> "Confirmer
  l'envoi" -> "Envoye: <messageId>"; `AgentRunState` shows the result
- **Events:** None (external tool call, not an AD-9 event)
- **Progress:** N/A

---

## Cross-cutting notes

- **Every scenario ends in a UI state change** (screen navigation, data
  refresh, or `AgentRunState` update). The Agent never manipulates React
  components directly; all UI effects go through the command bus
  (kernel S15).
- **Confirmation points** (ADR S5) are explicit: S1 (plan), S3 (schedule),
  S4 (focus start), S5 (blocklist), S13 (plan), S19 (replan), S20 (send).
  All others are read-only or non-irreversible.
- **Offline behavior:** S1, S3, S4, S7 (review), S16, S17 work on local
  mirrors. S2, S8, S9, S12, S14, S20 require online (AI, R2, Composio).
  The Agent's TaskProfile includes `offlineClass`; the Planner refuses to
  schedule online-only steps into offline windows (kernel S12).
- **Error recovery:** every scenario has a failure path documented in
  docs/agent/error-recovery.md. A partial execution (e.g., S13: learning
  items created but calendar not updated) is recoverable: the plan records
  per-step compensating actions; the user can retry the failed step.
