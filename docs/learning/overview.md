# Learning Module — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2). Authority: ADR §3/§17, `01-backend` §4.2,
`03-sync` §4.2 (FSRS server-side), `05-design-system` §4.6–4.8, spine AD-6/AD-11.

1. **Purpose** — transform resources into understanding, recall, application and mastery:
   AI study sheets, summaries, QCM, flashcards with FSRS spaced repetition, active
   recall, progressive exercises, correction & error analysis, Coach mode, Mirror
   Cognitive Mode, skill tracking.
2. **Responsibilities** — course import (OCR path: capture → upload → server OCR job →
   KB ingestion, ADR v1.5), sheet generation with **corpus fidelity** (ADR §17:
   professor's formulations stay textually dominant; agent explanations separated and
   labeled; fidelity check before export), QCM/flashcard generation + FSRS scheduling,
   exercise progression, error tracking (recurring-error detection), targeted revision
   (consumer of `SkillStateChanged`), export (MD/PDF/DOCX/PNG via Artifact jobs).
3. **Non-responsibilities** — semantic structure (Knowledge owns the tree + `NodeState`);
   progress evidence rows (Progress produces `ProgressEvidenceCreated`; Learning **never
   creates `ProgressEvidence` directly** — F-07, spine AD-9); FSRS computation (server
   job; device mirrors state, 03 §4.2).
4. **User flows** — import course → review sheet → formulas/definitions → flashcards →
   QCM → exercises → evidence → Progress (mission §8 flow); due-reviews screen from Home
   (AD-14); Mirror Cognitive Mode: student explains a concept → Aurora detects gaps,
   contradictions, errors (ADR §3) — *no dedicated pack section yet* (G-L3: design
   flow/data/agent behavior before wave 2, owner Learning + Agent teams).
5. **Architecture** — slice `apps/mobile/src/features/learning`; heavy work (OCR, FSRS
   ticks, sheet generation) = persisted jobs (AD-8, 01 §5.1 `fn-import-course`);
   FSRS ticks triggered by Postgres triggers on `flashcards` (01 §5.2).
6. **Domain model** — `Course, Subject, Skill (definitions), LearningSession, Review`
   (AD-15; local tables `courses, subjects, skills, learning_sessions, reviews`, 03
   §4.2); flashcards + FSRS state (server: due/stability/difficulty; local mirror read).
7. **Application services** — `ReviewUseCase` (rate flashcard → `ReviewRatedCommand`
   partial, one command), sheet-export use-case (→ Artifact job).
8. **Ports / interfaces** — consumes `OCRProvider` (server, optional, degrades to manual
   entry), `AIProvider` (generation via TaskProfiles, fidelity guard),
   `ScientificEngine` (formula validation in sheets).
9. **Adapters** — repositories (`packages/data`), Tiptap editors + `MathRenderer` for
   sheets/annotations (05 §4.6/4.7), `DocumentScanner`/`AudioArtifactProvider` for
   capture (04 §3.2).
10. **Data model** — 01 §4.2 (courses/subjects/skills/sessions/reviews/flashcards +
    FSRS columns); `CourseImported` payload carries `source`.
11. **API** — no UI→HTTP (local-first); server jobs read R2 documents + Postgres/pgvector.
12. **Events** — produces `CourseImported` (consumers: Knowledge, Discovery, Progress)
    and `FlashcardReviewed` (consumer: Progress); consumes `SkillStateChanged` (targeted
    revision) — declared in the Learning Contract Pack.
13. **Jobs** — OCR extraction, FSRS tick (per-day due sweep), sheet generation,
    QCM/exercise generation, export rendering.
14. **Permissions** — camera/mic for capture (optional paths, permission-matrix §1).
15. **Security** — course content is sensitive user data: provider routing honors
    `DataPolicy` (ADR v1.7 §11, 01 §5.6); RLS per user.
16. **Offline behavior** — due flashcards reviewable offline (local mirror of FSRS
    state); new reviews queue for upsync; generation features degrade (jobs wait for
    connectivity).
17. **Error handling** — `AppError` module-prefixed codes; 5 UX states; OCR absent →
    manual entry (AD-1 graceful degradation, 01 §6).
18. **Recovery** — re-sync merges via server-wins; FSRS state recomputed server-side on
    reconnect if needed (job).
19. **Observability** — review adherence, sheet export volume, FSRS job SLOs
    (`job_logs` + Sentry/PostHog).
20. **Tests** — FSRS determinism (server job tests, 01 §7 family), fidelity check
    (corpus-dominant assertions, ADR §17), single-writer (no direct `progress_evidences`
    writes — F-07 test), E2E import→review scenario (wave 4).
21. **Known limitations** — Mirror Cognitive Mode undesigned (G-L3); local STT not in
    V1 (spine Deferred); long-corpus OCR quality provider-dependent.
22. **Dependencies** — domain types, data repos, KB (ingestion target), Progress (evidence
    consumers), Artifact (exports), Scientific Engine (formula validation).
23. **Future evolution** — Yjs collaborative sheets (V1+ extension, spine Deferred);
    local STT (whisper.cpp) behind `TranscriptionProvider` once evaluated on real
    devices (OQ-07).
