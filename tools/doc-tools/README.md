# doc-tools — engine scaffold for the 4 `docs.*` agent capabilities

SSoT: [docs/agent/document-tools.md](../../docs/agent/document-tools.md).

| Capability | Engine | Direction | Where it runs |
|---|---|---|---|
| `docs.generate` | Pandoc (+ typst/weasyprint PDF engine) | TEXT→DOC | job worker (AD-8) |
| `docs.refine` | python-docx | TEXT→DOC (surgical .docx) | job worker (AD-8) |
| `docs.inspect` | mammoth | DOC→TEXT (.docx, light) | job worker (AD-8) |
| `docs.parse` | Docling | DOC→TEXT (complex, heavy) | job worker (AD-8) |

Nothing here is bundled into the app or installed on the device
(AD-3/AD-12/F-09: the device sees `AgentRunState` only). This directory
serves the dev machine + the server job worker.

## Install

```powershell
cd tools\doc-tools
powershell -ExecutionPolicy Bypass -File install.ps1   # scoop (pandoc, typst) + pip + npm
powershell -ExecutionPolicy Bypass -File check.ps1      # versions + smoke round-trip
```

## Notes

- `requirements.txt` pins python-docx + docling (Docling = heavy: model
  inference; first parse downloads the model — cache lives OUTSIDE the
  repo, gitignored, AD-3).
- `package.json` is standalone (NOT a pnpm workspace member — the
  workspace covers `packages/*` only): `npm install` in this directory
  brings in mammoth.
- **`docx-cli` (npm) is intentionally NOT used:** that registry package
  is a doc-site generator, unrelated to .docx. The quick-inspect role is
  filled by mammoth; typo/structure edits stay in python-docx
  (document-tools S6 "Correction").
- PDF engine: default `typst` (`pandoc --pdf-engine=typst`); `weasyprint`
  as CSS-heavy fallback; LaTeX only on template demand (open decision
  document-tools S7.1 — NEEDS_DECISION).
