# Reference templates for Pandoc `--reference-doc` (docs.generate)

A `templateId` in the `docs_generate` tool input = the base name of a
`.docx` in this directory (corporate styles: fonts, margins, headings).

Create one:

1. `pandoc -o starter-reference.docx --print-default-data-file reference.docx`
   (extracts Pandoc's default reference document)
2. Open it in Word and restyle Normal / Title / Heading 1-4 / Caption /
   Table Grid per your charte graphique.
3. Save here (tracked). The job worker resolves `templateId: "corporate"`
   to this file.

No template = Pandoc default styles (graceful degradation, AD-1).
.docx files are gitignored (root .gitignore line 10): the unbranded
Pandoc default (step 1 above) is generated LOCALLY, never committed.
