# Aurora doc-tools — one-shot engine install (dev machine / job worker).
# SSoT: docs/agent/document-tools.md S6. Idempotent: safe to re-run.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# 1) Pandoc + typst (scoop) — docs.generate + the default PDF engine
foreach ($pkg in @("pandoc", "typst")) {
  if (Get-Command $pkg -ErrorAction SilentlyContinue) {
    Write-Host "skip  : $pkg already on PATH"
  } else {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
      throw "scoop not found — install pandoc/typst manually (document-tools S7.1)"
    }
    scoop install $pkg
  }
}
# Guard: a stale non-scoop shim can shadow the scoop install (seen 2026-09-29:
# C:\Users\<user>\AppData\Local\pandoc\pandoc.exe pointed at a missing file).
try {
  & pandoc --version | Select-Object -First 1 | Out-Null
} catch {
  throw "pandoc on PATH is broken — remove the stale shim directory (e.g. %LOCALAPPDATA%\pandoc) or run: scoop reset pandoc"
}

# 2) python-docx + docling (pip) — docs.refine + docs.parse
pip install -r "$root\requirements.txt"

# 3) mammoth (npm, local to this dir — not a pnpm workspace member)
#    — docs.inspect
Push-Location $root
try {
  npm install --no-audit --no-fund
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "doc tools installed. Verify with: powershell -File check.ps1"
