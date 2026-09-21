# Artifact Hub — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2). Authority: ADR §16, `01-backend` §4.6/
§5.4, `04-mobile` §5, spine AD-10 (renderers), AD-9 (F-06).

1. **Purpose** — one unified visualization path for every imported or generated file,
   with type-appropriate preview + source-file access (ADR §16).
2. **Responsibilities** — per-format previews: PDF (paginated read, zoom, search,
   navigation), DOCX (preview + exploitable content extraction), PPTX (slide
   previews), XLSX/CSV (tabular preview + optional G2 charting), images (zoom viewer),
   Markdown/text/code (rendered or editor), audio/video (built-in player where format
   + platform allow), LaTeX (formula/document render when convertible); generated
   artifacts (immediate access in the hub with metadata on source task/context);
   **unsupported formats: kept + downloadable, with no native-preview claim**
   (ADR §16 last bullet — never pretend).
3. **Non-responsibilities** — file bytes live in R2 (only metadata + `r2_key` in
   Postgres/local, 03 §4.2 rule 2); generation engines (OCR, transcription, sheet
   export, infographic) are jobs of their modules; rendering engines sit behind AD-10
   contracts in `packages/ui`.
4. **User flows** — import (document scanner / gallery / upload) → preview → link to
   course/project/goal; generated (agent output) → appear in hub with provenance →
   export/download/share.
5. **Architecture** — R2 private buckets + presigned URLs (server-issued, short TTLs,
   01 §5.4); `artifacts` metadata table (Artifact module, 01 §4.6); previews rendered
   client-side through renderer contracts; heavy processing = jobs (AD-8).
6. **Domain model** — `Artifact` (kind, r2Key, size, generatedAt, jobId, links to
   course/project/goal), `SourceRef` (provenance, Knowledge-owned).
7. **Application services** — open-preview use-cases (presigned fetch → renderer),
   export use-cases (→ jobs).
8. **Ports / interfaces** — `ArtifactProvider`, `ObjectStorage` (presign), renderer
   contracts (`DataVisualizationRenderer` for XLSX charts, `MathRenderer` for LaTeX,
   `InfographicRenderer` for generated visuals, 02 §5/05 §3.6); `AudioArtifactProvider`
   + `AudioWaveformRenderer` for audio (04 §3.2.4/§5: waveform renderer = pure React
   DS component, **not** a Capacitor adapter — 04 §5 rule).
9. **Adapters** — R2 adapter (server presign + client direct upload), format viewers
   (05 §3.6 data components).
10. **Data model** — 01 §4.6 (artifact metadata; R2 objects); local mirror =
    metadata + `r2_key` only (03 §4.2).
11. **API** — presigning Edge Functions (`presignGet` 15 min / `presignUpload` 5 min,
    01 §5.4); no client-held R2 keys (AD-3).
12. **Events** — produces `ArtifactGenerated` **after R2 upload only** (F-06) with
    `jobId` (consumers: Knowledge → `SourceRef`, Learning → evidence; UI consumer
    pending OQ-05 ratification); consumes `JobCompleted` (success states, F-08
    `jobId`+`jobKind`).
13. **Jobs** — `artifact_gen`, `ocr`, `transcription` kinds (04 §3.3); export
    rendering (sheets → MD/PDF/DOCX/PNG, ADR §17).
14. **Permissions** — none beyond user scope (presigned, per-user scoping).
15. **Security** — private bucket + presigned URLs; no key in bundle (04 §7.2b test);
    unsupported formats never crash the viewer (graceful, ADR §16).
16. **Offline behavior** — cached previews/blobs readable offline (`LocalFileStorageAdapter`
    cache, 04 §3.2.2); new artifacts need connectivity.
17. **Error handling** — preview failure → raw-file fallback (download/share external,
    ADR §16); job failure → `error` state with retryable `jobId` (01 §6).
18. **Recovery** — resync of metadata; blobs immutable in R2 (keyed).
19. **Observability** — job SLOs per kind, preview render perf, R2 egress/cost.
20. **Tests** — F-06 test (event only post-upload, 01 §7(d)), F-08 payload test,
    anti-leak (04 §7.2b), viewer degradation tests.
21. **Known limitations** — audio/video playback "where format and platform allow"
    (ADR §16 wording — document per-format support matrix at wave 2); transcription
    optional (no local STT V1).
22. **Dependencies** — R2, jobs system, renderers (`packages/ui`), Learning/Knowledge
    (consumers), Agent (generation requests).
23. **Future evolution** — more preview formats; collaborative artifacts (Yjs,
    deferred); desktop preview integration Phase 2.
