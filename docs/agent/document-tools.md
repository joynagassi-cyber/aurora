# Document Tools — Pandoc · python-docx · mammoth · Docling

Status: `DESIGNED` (wave 3 extension, owner Agent team). Authority: AD-8
(heavy = jobs), AD-3 (no keys/models on device), F-06
(`ArtifactGenerated` post-R2 only), artifacts overview §18/§24 (blobs
immutable; revisions = new rows `supersedes`), ADR §5 (confirmations),
domain job-kind SSoT (AD-15: kind vocabulary unchanged).

The 4 `docs.*` capabilities (kernel S14; seeded in
`packages/agent/src/capability.ts` + `tools.ts`; matrix rows in
[feature-agentability-matrix.md](./feature-agentability-matrix.md))
give the agent chat two strict directions of document work:

| Direction | Capability | Tool id | Engine | Role |
|---|---|---|---|---|
| TEXT→DOC | `docs.generate` | `docs_generate` | **Pandoc** | whole-document generation from LLM Markdown → .docx / .pdf / .pptx / .html / .epub |
| TEXT→DOC | `docs.refine` | `docs_refine` | **python-docx** | surgical precision edits on an existing .docx (complex tables, invoices, dynamic styles) |
| DOC→TEXT | `docs.inspect` | `docs_inspect` | **mammoth** | quick read-only inspection of a .docx (content, structure outline, typo scan) |
| DOC→TEXT | `docs.parse` | `docs_parse` | **Docling** | deep extraction of complex documents (scanned PDF, PPTX, XLSX, HTML, images) → structured Markdown/JSON, faithful table reconstruction |

## 1. Where & when (the selection rule — never mix)

The Planner (kernel S12 Tool Resolver) picks exactly ONE tool per step from
the intent + source file type + complexity. The rule is directional:

- **Creating a new document** (report, spec, fiche, PPT deck, any export of
  agent-authored content) → `docs.generate`. The LLM writes Markdown
  (what LLMs do best and cheapest); Pandoc does the FORM (styles, layout,
  `--reference-doc` template, Mermaid blocks → images).
- **Surgically editing an existing .docx** (fill a complex data table,
  build an invoice pixel-precise, patch a style, replace a section) →
  `docs.refine`. Precision work Pandoc templates cannot express.
- **Reading a .docx quickly** ("read this Word file", "check the
  structure", "find the typo") → `docs.inspect`. Light job, .docx only.
- **Understanding a COMPLEX document** (scanned PDF, PowerPoint deck,
  multi-page spreadsheet tables, image with text) → `docs.parse`.
  Docling's visual-structure models (Granite-Docling family) rebuild the
  reading order + tables; the output feeds Knowledge/agent analysis.
- **Raw photo / low-quality scan** → NOT `docs.parse`: degraded fallback =
  pandoc text extraction (flagged `expectedQuality:'degraded'`, AD-5), and
  photo-quality scans go to the existing `ocr` job pipeline.

**Never** (hard rules, asserted by description text the LLM sees):

1. A generator never parses: Pandoc / python-docx are never used to read
   an existing document.
2. A reader never generates: mammoth / Docling never produce a finished
   document (their output is an intermediate representation).
3. `docs.inspect` on PDF/PPTX/XLSX → switch to `docs.parse`.
4. Whole-document authoring via `docs.refine` → switch to `docs.generate`.
5. Pixel-precise layout via `docs.generate` → switch to `docs.refine`.

## 2. Execution model

- All 4 run **server-side as `artifact_gen` jobs** (AD-8; nothing blocks
  the UI; the job-kind vocabulary is unchanged — the discriminator is
  `payload.docTool` ∈ {pandoc, python-docx, mammoth, docling}, set by the
  kernel tools in `packages/agent/src/tools.ts`).
- Source files: presigned fetch only (AD-3, `presignGet` 15 min, 01 §5.4).
- Outputs: NEW `artifacts` row + R2 upload; `ArtifactGenerated` emitted
  **after** the upload (F-06). A refined document = new revision linked
  `supersedes` to the source row (artifacts §24; source blob immutable).
- Idempotency keys: `doc:<docTool>:…` (stable per logical payload, 01 §5.3).
- Weight: `docs.parse` = heavy (model inference); `docs.generate` with
  PDF = medium (typesetting engine); `docs.inspect` = light.
- The kernel never writes module tables (AD-7): it emits the job
  descriptor; the Artifact module applies the row + emits F-06.

## 3. Contracts (input / output per tool)

| Tool | Input (zod, `tools.ts`) | Output (job → artifact row) |
|---|---|---|
| `docs_generate` | `markdown`, `outputFormat` (docx/pdf/pptx/html/epub), `templateId?` (--reference-doc), `renderMermaid?` | formatted document artifact |
| `docs_refine` | `artifactId`, `operations[]` (typed: fill_table, style_patch, section_replace, text_replace) | new revision artifact (`supersedes`) |
| `docs_inspect` | `artifactId`, `mode` (markdown/html/outline) | parsed representation artifact (provenance-linked) |
| `docs_parse` | `artifactId`, `format` (markdown/json/html) | structured representation artifact (provenance-linked, tables preserved) |

Operation vocabulary for `docs_refine` (v1): `fill_table` (cell → value,
typed units, scientific-style), `style_patch` (named style overrides),
`section_replace` (by heading id), `text_replace` (exact string, count).
Unknown ops = job `failed` with a typed error (01 §6), never silent.

## 4. Confirmation & risk

All 4 = **no confirmation, non-destructive, FULL** (matrix): they only
CREATE artifact rows; the source document is never mutated (immutable
blobs, §18). Deletion of artifacts stays a separate destructive user
action (out of scope here). Consistent with the existing `artifact.generate`
row.

## 5. Fallbacks (AD-1: the product degrades, never breaks)

| Capability | Unavailable / degraded |
|---|---|
| `docs.generate` | raw Markdown artifact (zero binary dependency — always available) |
| `docs.refine` | read-only `docs.inspect` + `degraded` flag (AD-5 envelope) |
| `docs.inspect` | pandoc `.docx`→Markdown (same direction, heavier) |
| `docs.parse` | pandoc text extraction (`degraded` flag); raw scans → `ocr` job |

Every fallback is traceable via `AIResponseEnvelope.fallbackUsed` (AD-5).

## 6. Installation & environment

- Scaffold: `tools/doc-tools/` — `install.ps1` (scoop: pandoc + typst;
  pip: `requirements.txt`; npm: mammoth), `check.ps1` (version + smoke
  tests), `requirements.txt` (python-docx + docling, pinned),
  `templates/` (starter `--reference-doc` .docx), `.gitignore` (model
  cache — AD-3: model weights never in the repo / never on device).
- Runtime owner: the job worker (server). The device NEVER installs or
  runs these tools (AD-12/F-09: the device sees `AgentRunState` only).
- Machine state (dev box, 2026-09-29, evidence-based): pandoc 3.12 ✓
  (scoop), typst 0.15.1 ✓ (scoop, default PDF engine), Python 3.12.10 +
  pip ✓, Node 22.20.0 ✓, mammoth 1.13.0 ✓ (npm, local to this dir),
  python-docx 1.2.0 ✓ (pip), docling 2.131.0 ✓ (pip, import verified
  — torch loads). Round-trip smoke PASSED:
  pandoc md→.docx → mammoth .docx→Markdown ("# Smoke") → python-docx
  read ("Smoke") — 2026-09-29. Caveat: a stale `AppData\Local\pandoc`
  shim shadowed the scoop install on this box (install.ps1 guards now).
- **Correction of the requested toolset:** `docx-cli` on npm is NOT a
  .docx tool (registry v0.0.1-beta.0, description "文档网站生成工具" = a
  doc-site generator). The quick-inspection role is filled by
  **mammoth** (docx → clean HTML/Markdown, MIT, actively maintained);
  typo/structure fixes stay in `docs.refine` (python-docx).

## 7. Open decisions (owner: Foundation + Agent)

1. **PDF engine** — default `typst` (single static binary, fast, modern
   typography, `pandoc --pdf-engine=typst`); `weasyprint` for
   CSS-heavy HTML→PDF; LaTeX only when templates demand it. NEEDS_DECISION.
2. **Mermaid → images** filter for Pandoc (Lua filter + mermaid
   renderer) so agent diagrams embed in .docx/.pdf. NEEDS_DECISION.
3. **Docling model cache** path on the worker (gitignored; first job
  downloads — budget the cold start in the job SLO, AD-16d).
4. Docling upstream offers an MCP server — intentionally NOT used:
  AD-12 forbids a second agent surface; Docling runs in-process in the
  job worker (a typed tool, not an MCP endpoint).
5. Corporate `--reference-doc` templates per brand (`templateId`) —
  provided by the owner; starter template in `tools/doc-tools/templates/`.

## 8. Verification

- `packages/agent/test/doc-tools.test.ts` — registration, directional
  split, typed `artifact_gen` job descriptors (no network, AD-3).
- `tools/doc-tools/check.ps1` — engine presence + one-shot smoke test
  (markdown→docx; docx→markdown; docling import).
- F-06 test (event only post-upload, 01 §7(d)) covers all 4 outputs.
