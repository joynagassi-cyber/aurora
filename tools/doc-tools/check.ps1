# Aurora doc-tools — engine presence + smoke round-trip.
# SSoT: docs/agent/document-tools.md S8.
# Usage: powershell -ExecutionPolicy Bypass -File check.ps1
#        DOC_TOOLS_FULL_SMOKE=1 also runs a real Docling parse
#        (first run downloads the model — budget it).
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# --- 1. engine versions ---------------------------------------------------
pandoc --version | Select-Object -First 1
if (Get-Command typst -ErrorAction SilentlyContinue) { typst --version }
python -c "import importlib.metadata as m; print('python-docx', m.version('python-docx'))"
python -c "import importlib.metadata as m; print('docling', m.version('docling'))"
node -e "console.log('mammoth', require('mammoth/package.json').version)"

# --- 2. smoke round-trip: md -> docx -> (mammoth md/html, python-docx text) ---
Set-Content -Path "$root\smoke.md" -Value "# Smoke`nRound-trip ok."
pandoc "$root\smoke.md" -o "$root\smoke.docx" | Out-Null
node -e "require('mammoth').convertToMarkdown({path:'$($root.Replace('\','/'))/smoke.docx'}).then(r => { const line = r.value.trim().split('\n').filter(Boolean)[0]; if (!line.includes('Smoke')) throw new Error('mammoth smoke failed: ' + line); console.log('mammoth md ok:', line); return require('mammoth').convertToHtml({path:'$($root.Replace('\','/'))/smoke.docx'}) }).then(r => { if (!r.value.includes('Smoke')) throw new Error('mammoth html failed'); console.log('mammoth html ok:', r.value.slice(0, 40).trim()) })"
python -c "import docx; d = docx.Document(r'$root\smoke.docx'); p = d.paragraphs[0].text; assert 'Smoke' in p, p; print('python-docx ok:', p)"

# --- 3. optional full Docling parse --------------------------------------
if ($env:DOC_TOOLS_FULL_SMOKE -eq "1") {
  python -c "import sys; from docling.datamodel.base_models import InputFormat; from docling.document_converter import DocumentConverter; print('docling import ok'); print('docling full smoke requires a sample file — run in CI, not here')"
}

Remove-Item "$root\smoke.md", "$root\smoke.docx" -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "doc-tools check passed."
