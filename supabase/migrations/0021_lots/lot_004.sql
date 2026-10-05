INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/matter-workspace', 'legal', 'matter-workspace', '', 'matter-workspace', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /matter-workspace

Practitioners work across multiple clients and matters. A matter workspace keeps one client or engagement's context separate from every other. This skill manages those workspaces.

## Subcommands

- `/corporate-legal:matter-workspace new <slug>` — create a new matter workspace, run a short intake, write `matter.md`
- `/corporate-legal:matter-workspace list` — list matters with status and active flag
- `/corporate-legal:matter-workspace switch <slug>` — set the active matter
- `/corporate-legal:matter-workspace close <slug>` — archive a matter (move to `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/_archived/`, never delete)
- `/corporate-legal:matter-workspace none` — detach from any active matter, work at practice-level only

## Instructions

1. Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` — confirm the `## Matter workspaces` section is populated. If `Enabled` is `✗`, tell the user: "Matter workspaces are off — you're configured as an in-house practice with one client, so the plugin works from practice-level context automatically. If you actually work across multiple clients, re-run `/corporate-legal:cold-start-interview --redo` and select a private-practice setting. Otherwise, you don't need `/matter-workspace` at all." Don't error — the disabled state is the expected one for in-house users.
2. Use the workflow below.
3. Dispatch on the first token of `$ARGUMENTS`:
   - `new` → run the intake interview, write `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<slug>/matter.md`, seed `history.md` and `notes.md`.
   - `list` → enumerate `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/*/matter.md`, print a table, mark the active matter.
   - `switch` → update the `Active matter:` line in the practice-level CLAUDE.md.
   - `close` → move `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<slug>/` to `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/_archived/<slug>/`, log the close date in `history.md`.
   - `none` → set `Active matter:` to `none — practice-level context only`.
4. Show the user what changed and confirm before writing.

## Notes

- The skill never reads across matters unless `Cross-matter context` is `on` in the practice-level CLAUDE.md.
- Archiving is not deletion — closed matters remain readable for retention/conflicts purposes.
- Slugs are lowercase with hyphens. If a slug is reused across archived and active, the archived one is preserved under `_archived/<slug>/`.

---

Multi-client practitioners (private practice — solo, small firm, large firm) work across many matters. Context from one must not leak into another. This skill is the thin file-management layer that makes that true.

**Default state is off.** In-house users never see this — they run at practice-level only. Matter workspaces turn on at cold-start for private-practice users, or by editing `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗`, this skill does not run; `/corporate-legal:matter-workspace` explains the disabled state and suggests `/corporate-legal:cold-start-interview --redo` for users who actually need matter isolation.

## Storage layout

All matter data lives under:

```
~/.claude/plugins/config/claude-for-legal/corporate-legal/
├── CLAUDE.md                       # practice-level practice profile
└── matters/
    ├── <slug>/
    │   ├── matter.md               # client, counterparty, matter type, key facts, overrides
    │   ├── history.md              # dated log of events, decisions, drafts, reviews
    │   ├── notes.md                # free-form working notes
    │   └── outputs/                # skill outputs for this matter (optional subfolder)
    └── _archived/
        └── <slug>/                 # closed matters — readable but not active
```

Slugs are lowercase with hyphens. Examples: `acme-msa-2026`, `zenith-renewal`, `vendor-xyz-nda`.

## Active matter is in the practice CLAUDE.md

The `Active matter:` line under `## Matter workspaces` in the practice-level CLAUDE.md is the single source of truth. Switching a matter edits that line. No separate state file.

## Subcommand logic

### `new <slug>`

1. Confirm slug is not already present in `matters/<slug>/` or `matters/_archived/<slug>/`. If reused, ask the user to pick a different slug.
2. Run the intake interview:
   - **Client** (the party we represent, or the internal business unit if in-house)
   - **Counterparty** (the other side — may be multiple)
   - **Matter type** (read the plugin's practice profile for typical categories; for corporate-legal: M&A buy-side | M&A sell-side | financing | board matter | entity reorg | integration project | other)
   - **Confidentiality level** (standard | heightened | clean-team — heightened prompts extra care in cross-matter settings)
   - **Key facts** (2–5 sentences: what this matter is about, who the stakeholders are, what's at stake)
   - **Matter-specific overrides to the practice playbook** (e.g., "client requires 24-month LoL cap not 12", "counterparty is a strategic partner — relationship-preserving tone")
   - **Related matters** (slugs of any connected matters)
3. Write `matters/<slug>/matter.md` using the template below.
4. Seed `matters/<slug>/history.md` with a single "Opened" entry.
5. Create an empty `matters/<slug>/notes.md`.
6. Do **not** auto-switch to the new matter. Ask: "Want to switch to `<slug>` now? (`/corporate-legal:matter-workspace switch <slug>`)"

### `list`

Enumerate `matters/*/matter.md`. Read each file's front-matter or first few lines to extract status. Print a table:

| Slug | Client | Matter type | Status | Opened | Active |
|---|---|---|---|---|---|

Mark the currently-active matter with `*`. Include `_archived/*` under a separate "Archived" heading if any exist.

### `switch <slug>`

1. Confirm `matters/<slug>/matter.md` exists. If not, offer `/corporate-legal:matter-workspace new <slug>`.
2. Edit the `Active matter:` line in the practice-level CLAUDE.md to `Active matter: <slug>`.
3. Show the user the matter.md summary so they can confirm they're on the right matter.

### `close <slug>`

1. Confirm `matters/<slug>/` exists.
2. Append a "Closed" entry to `matters/<slug>/history.md` with today's date.
3. Move `matters/<slug>/` → `matters/_archived/<slug>/`.
4. If the closed matter was the active matter, set `Active matter:` to `none — practice-level context only`.

### `none`

Set `Active matter:` in the practice-level CLAUDE.md to `none — practice-level context only`. Confirm with the user.

## `matter.md` template

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this` in the practice-level CLAUDE.md]

# Matter: [Client] — [short description]

**Slug:** [slug]
**Opened:** [YYYY-MM-DD]
**Status:** active
**Confidentiality:** [standard / heightened / clean-team]

---

## Parties

**Client:** [name]
**Counterparty:** [name(s)]

## Matter type

[vendor MSA | customer agreement | NDA | SaaS subscription | amendment | renewal | other — with one-line rationale]

## Key facts

[2–5 sentences. What this matter is about. Who the stakeholders are. What's at stake. What makes it different from the default playbook.]

## Matter-specific overrides

*Any deviation from the practice-level playbook that applies to this matter and only this matter.*

- [e.g., "LoL cap: client requires 24 months, not house standard 12."]
- [e.g., "Tone: relationship-preserving — counterparty is a strategic partner."]
- [e.g., "Governing law: must be English law, not Delaware."]

## Related matters

- [slug — one line why related]

## Notes on confidentiality

[If heightened or clean-team, describe why. Who may see matter files. Whether cross-matter context is permissible even if globally on.]
```

## `history.md` seed

```markdown
# History: [Client] — [short description]

Append-only event log. Most recent at top.

---

## [YYYY-MM-DD] — Matter opened

Intake completed. Slug: `[slug]`. Status: active.
[Any initial context worth preserving beyond matter.md — e.g., "Opened in response to inbound MSA draft from [counterparty]."]
```

## Cross-matter context

The practice-level CLAUDE.md has a `Cross-matter context:` flag. When it's `off` (the default), a skill working in matter A **never reads** files in `matters/B/` for any other `B`. Period. This is the confidentiality guarantee the setting exists to provide.

When it's `on`, a skill may read files across matter folders only when the user explicitly asks it to (e.g., "compare our position on liability caps across the last five vendor matters"). Even when `on`, the default is to load only the active matter unless the user asks for a cross-matter view.

## What this skill does not do

- **Run a conflicts check.** Conflicts are the practitioner's/firm's job; the intake captures what the user declares.
- **Enforce retention.** Closing archives a matter; it does not delete. Retention policy is out of scope.
- **Auto-route outputs.** The substantive skill decides where to write; this skill tells it *which folder* is active, not what to put in it.
- **Decide whether cross-matter is appropriate.** It reads the flag and obeys.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/tabular-review', 'legal', 'tabular-review', '', 'tabular-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /tabular-review

1. Load `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → diligence structure, thresholds, house format.
2. Confirm: what documents, what columns, where does the output go.
3. Build the typed schema. Write `.review-schema.yaml`. Confirm with the user.
4. Sample run (3–5 docs). Adjust schema. Confirm.
5. Fan out — one sub-agent per document, parallel. Each cell: value + state + verbatim quote + location.
6. Normalization pass. Flag outliers and inconsistencies.
7. Output: `.xlsx` or Google Sheets (ask which), plus `.csv` + `_sources.csv` + markdown always. Work-product header.
8. Summary: verification workload (counts of not_present / unclear / needs_review per column), flagged columns, where the files are, reminder that every cell is a lead not a finding.

```
/corporate-legal:tabular-review
/corporate-legal:tabular-review --schema .review-schema.yaml --docs ./vdr/02-Contracts/
/corporate-legal:tabular-review --template ma-diligence
```

**`--schema <path>`:** Use an existing schema file instead of building one. Useful for re-runs and incremental additions.

**`--template <name>`:** Start from a template in `references/`. Currently: `ma-diligence`.

**`--docs <path>`:** Document source. A local folder, a Drive folder ID, or a VDR path. If omitted, asks.

**`--output <xlsx|gsheets|csv>`:** Output format. If omitted, asks.

**`--sample <n>`:** Sample size for the schema check. Default 5.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

You have a pile of documents and a list of questions you need answered consistently across every one. A diligence request list. A vendor contract audit. A lease portfolio review. The output is a table: document rows, data-point columns, and every cell traceable to the exact words in the source.

This is not issue spotting. `diligence-issue-extraction` finds the 30 problems hiding in 2,000 documents. This skill answers the same 15 questions about all 2,000 documents. Both are legitimate; they answer different questions.

This is also not a replacement for a human reading the document. Every cell this skill produces is a **lead that needs verification**, not a finding. The output is designed to make verification fast, not to skip it.

## Load context

- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → diligence structure, materiality thresholds, house format preferences
- `~/.claude/plugins/config/claude-for-legal/corporate-legal/deals/[code]/deal-context.md` if working a specific deal
- An existing schema file if the user has one (`.review-schema.yaml`)

## The column type system

The thing that makes a tabular review useful is that Column C means the same thing in row 1 as in row 200. Free text drifts. Types hold.

Every column has a **type** that constrains the answer format:

| Type | What it returns | Use for |
|---|---|---|
| `verbatim` | Exact quote from the document, character-for-character | Defined terms, operative clause language, anything where the words matter |
| `classify` | One value from a fixed list you define | Yes/No, present/absent, clause variants (e.g., "sole consent" / "consent not unreasonably withheld" / "silent") |
| `date` | ISO date | Effective date, expiration, termination notice deadline |
| `duration` | Number + unit | Term length, notice period, survival period |
| `currency` | Number + currency code | Caps, thresholds, fees, purchase price references |
| `number` | Bare number | Counts, percentages, page references |
| `free` | Short free text summary | Use sparingly — this is the type that drifts. Only when the others genuinely don't fit. |

**The verbatim rule:** Every non-`verbatim` column also captures the exact source quote that supports the answer, as a companion field. The answer in the cell is the interpretation; the quote is the evidence. A `classify` cell that says "consent not unreasonably withheld" is useless without the sentence it came from, because the reviewer's job is to check whether that's the right read.

## The three states of "not found"

A blank cell hides information. Force one of three explicit states whenever you can't produce a positive answer:

| State | Meaning | When to use |
|---|---|---|
| `not_present` | The document was read and the clause is not there | You are confident the subject matter isn't addressed |
| `unclear` | Something is there but you can't classify it confidently | Ambiguous drafting, partial clause, conflicting provisions |
| `needs_review` | You found something but a human must make the call | Edge case, unusual drafting, the answer depends on a judgment the schema doesn't capture |

These are three different pieces of information. A deal team handles "the contract is silent on assignment" very differently from "the assignment clause is ambiguous." Collapsing them into one blank cell loses the distinction.

## Workflow

### Step 0: What and where

Confirm:
1. **Documents.** Where are they? VDR MCP (Box, Datasite, iManage), local folder, Google Drive folder, or a list of files. How many? If >200, warn that this will take a while and offer to start with a materiality-filtered subset.
2. **Schema.** What columns? Two paths:
   - User picks a template from `references/` (M&A diligence standard is the default)
   - User describes columns in natural language and you structure them into the typed schema
3. **Output.** Excel (`.xlsx`) or Google Sheets — ask which the team works in. CSV and markdown always written as fallbacks. Output goes to the deal folder, Drive, or wherever the user says.

### Step 1: Build and confirm the schema

Turn the user's column list into a structured schema. For each column: a stable `id`, a human `label`, a `type`, a `prompt` (the question a reviewer reading the document would ask), and for `classify` columns an `options` list.

Write it to `.review-schema.yaml` next to the output. This file is the reusable artifact — the user can edit it, add a column, re-run against new documents. Show it to the user and confirm before fanning out.

```yaml
schema:
  name: "M&A Diligence — Project [Code]"
  created: 2026-05-07
  columns:
    - id: counterparty
      label: "Counterparty"
      type: verbatim
      prompt: "Who is the contracting party other than the target?"
    - id: effective_date
      label: "Effective Date"
      type: date
      prompt: "When did the agreement become effective?"
    - id: change_of_control
      label: "Change of Control"
      type: classify
      options: [silent, consent_required, consent_not_unreasonably_withheld, automatic_termination, notice_only]
      prompt: "Does the agreement address a change of control of the target? What does it require?"
    - id: assignment
      label: "Assignment Restrictions"
      type: classify
      options: [silent, consent_required, consent_not_unreasonably_withheld, freely_assignable, assignable_to_affiliates]
      prompt: "Can the target assign this agreement? What restrictions apply?"
    # ... more columns
```

### Step 2: Sample run

Do not fan out to 200 documents on an untested schema. Run 3–5 documents first. Show the user the rows. Look for:
- Columns where most answers are `unclear` — the prompt is ambiguous, rewrite it
- `classify` columns where answers don't fit the options — add options or change to `free`
- `verbatim` columns returning paraphrases — reinforce that it must be character-for-character

Adjust the schema, re-run the sample, confirm. This saves the user from a full run that has to be thrown out.

### Step 3: Fan out

One sub-agent per document, in parallel. Each sub-agent:

1. Reads the entire document (not a RAG chunk — the whole thing).
2. For each column, finds the relevant provision.
3. Returns a structured row: for each column, `{value, state, quote, location}`.
   - `value` is the typed answer (or null if `state` is not `answered`)
   - `state` is `answered | not_present | unclear | needs_review`
   - `quote` is the verbatim supporting text (exact, no paraphrase, no ellipsis inside a sentence — if you cut, cut at sentence boundaries and mark it)
   - `location` is where the quote lives (section number, heading, page — whatever the document gives you)

**The quote is not optional, and the verbatim rule is mechanical, not exhortation.** Each sub-agent must comply with all of the following before returning a cell with `state: answered`:

- The `quote` MUST be a character-for-character copy of contiguous text from the source document, retrievable at the `location` the sub-agent cites. Do NOT compose a quote from a section heading plus standard boilerplate you expect to be there. Do NOT paraphrase and call it verbatim. Do NOT reconstruct a quote from memory of how such clauses "usually" read. Do NOT fill gaps in the source with ellipsis-stitching across non-contiguous text.
- The `location` must be specific enough for the normalization pass to re-open the document and re-read the same span — a section number, heading, or page reference the reviewer can navigate to.
- If the sub-agent cannot locate and copy the exact text (source truncated, OCR garbage, provision implied but not written, section heading visible but body not loaded), the cell state is `needs_review`, the `value` is null, and `notes` MUST contain `quote_unavailable: <reason>`. It is NEVER acceptable to set `state: answered` with a composed or reconstructed quote.
- The same rule applies to `verbatim`-typed columns AND to the companion source quotes attached to `classify` / `date` / `duration` / `currency` / `number` / `free` cells. The supporting quote carries the same verbatim obligation as the cell value.

The normalization pass in Step 4 spot-checks this by re-reading the source at the cited `location` and comparing the stored `quote` character-for-character against the source text. A mismatch downgrades the cell to `needs_review`, notes `quote_mismatch`, and flags the whole column for a wider spot-check — if one sub-agent composed a quote, others in the same run may have too.

### Step 4: Normalize

After the fan-out, read the whole table column by column. This is the pass that catches the failure mode of every tabular review tool: the same clause interpreted inconsistently across documents.

For each `classify` column:
- Check that every `answered` value is in the options list. Outliers get re-classified or bumped to `needs_review`.
- Check for clusters: if 180 documents say `consent_required` and 20 say `consent_not_unreasonably_withheld`, that's probably real. If 195 say `consent_required` and 5 say `freely_assignable`, look at the 5 — they're either genuinely different or misclassified.

For each `date` / `duration` / `currency` column:
- Check format consistency. Normalize.
- Flag implausible values (a 99-year term, a $1 cap) as `needs_review`.

For each `verbatim` column AND for the companion source quotes on every other column:
- Spot-check by re-opening the source document at the cited `location` for a random sample (at least 3–5 rows per column, or 10% of rows, whichever is larger) and comparing the stored `quote` character-for-character against the source.
- If any quote is composed, paraphrased, reconstructed, or cannot be located at the cited span: downgrade that cell to `needs_review` with `quote_mismatch` in notes, and flag the whole column — expand the spot-check to the rest of the column rather than assuming the other rows are clean. One fabricated quote is enough to justify widening the check.
- A cell with `state: answered` and a mismatched quote is a higher-severity failure than an `unclear` or `needs_review` cell — it misrepresents the evidence trail. Downgrade aggressively.

### Step 5: Output

Write the table in three formats:

**Markdown** (always, for in-session review):
```markdown
| Document | Counterparty | Effective Date | Change of Control | Assignment | ⚠️ Flags |
|---|---|---|---|---|---|
| Vendor MSA — Acme | Acme Corp | 2023-04-01 | consent_required | consent_required | — |
| Supply Agmt — Beta | Beta LLC | 2021-11-15 | ⚠️ unclear | silent | CoC ambiguous §14.2 |
```

**CSV** (`.csv`, always):
One file for the values, one companion file for the quotes and locations (`_sources.csv`). Keeps the main file clean and the evidence trail complete.

**Excel** (`.xlsx`) or **Google Sheets** — whichever the user works in. Ask; don't guess. Both follow the same workbook structure (see `references/excel-output.md` and `references/gsheets-output.md`). For Excel: Claude in Excel (Office agent) if available, `openpyxl` fallback. For Sheets: Sheets MCP if available, Sheets API via ADC, CSV-import fallback. In the spreadsheet output:
- Each data column is paired with a hidden source column containing the quote and location. Cell comments (Excel) or notes (Sheets) on the visible column surface the quote on hover.
- Color code by state: white = answered, yellow = unclear or needs_review, gray = not_present.
- A `Verified` column per data column, blank by default. The reviewer marks it. This is the verify/flag pattern that makes the table auditable — the deal team can see at a glance what a human has actually checked.
- A `_schema` sheet with the column definitions, so the file is self-documenting.

Prepend the work-product header from the plugin config `## Outputs` as a top row. Alongside it, include a distribution note:

> This review is derived from source documents that may be privileged, confidential, or both. It inherits the sources' privilege and confidentiality status — distribution beyond the privilege circle can waive privilege. Store with the matter's privileged files and make distribution decisions deliberately.

### Step 6: Summary

After the table is written, give the user a one-screen readout:
- Document count, column count, rows completed
- Count of `not_present`, `unclear`, `needs_review` per column — this is the verification workload
- Any columns where the normalization pass flagged >10% of rows
- Where the output files are
- A reminder: every cell is a lead, not a finding. Verification required before this informs a rep, a schedule, or a memo.

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- **It does not replace reading the documents.** It tells you where to look.
- **It does not produce confidence scores.** A 0.73 is not information. The `unclear` / `needs_review` states and the verbatim quotes are the confidence signal — if the quote doesn't support the value, flag it.
- **It does not silently skip documents.** Every document the user pointed at gets a row. A document that couldn't be read gets a row of `needs_review` with a note.
- **It does not pretend a paraphrase is a quote.** The evidence trail is the whole point.

## Relationship to other skills

- `diligence-issue-extraction` finds issues; this extracts data points. If an extraction reveals an issue (a MAC clause that references a specific earnings target, a poison pill), note it and suggest running diligence-issue-extraction on that document.
- `material-contract-schedule` builds one specific table (the disclosure schedule). It can consume this skill's output directly — the schedule is a filtered, reformatted view of a tabular review.
- `ai-tool-handoff` hands bulk review to Luminance/Kira when the corpus is too large or the team prefers a dedicated platform. This skill is the in-house option for anything it can handle — run it first, hand off the residue.

## Output safeguards

Every output gets the work-product header. Every cell gets a source citation or a flagged state. The summary explicitly says verification is required. The Excel `Verified` column makes the verification state auditable. This is not a tool that lets you skip reading; it's a tool that makes reading faster.$body$),
('marketplace:claude-for-legal/claude-for-legal/corporate-legal/skills/written-consent', 'legal', 'written-consent', '', 'written-consent', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /written-consent

1. Load `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → Board & Secretary (consents repository, resolution language, state of incorporation, board composition).
2. Use the workflow below.
3. Identify the action and classify (routine / review-flag).
4. If review-flag: show outside counsel warning and confirm before proceeding.
5. Search consents repository for closest precedent. If no repository: use seed consents from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`.
6. Draft consent in house format using precedent as base.
7. Output: consent draft + signatory checklist + review prompts.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/corporate-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/corporate-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Most routine board approvals don't need a meeting. Officer appointments, equity grants, bank authorizations, contract approvals above the officer threshold, intercompany arrangements — these happen by unanimous written consent. This skill drafts them quickly in your house format, finds the prior consent that's closest to what you need, and flags the actions where you should be getting outside counsel eyes before anyone signs.

## Scope warning — read before drafting

> **This skill is designed for day-to-day consents with direct precedents in your repository or seed documents.** Routine actions — officer appointments, equity grants, annual authorizations, standard contract approvals — are the right use case. The skill finds a prior consent that closely matches, adapts it to the current action, and produces a clean draft.
>
> **For major one-off actions, outside counsel review is prudent regardless of what this skill produces.** This includes: M&A transactions (asset purchases, stock purchases, mergers, investments), financing rounds, equity issuances to new investors, change-of-control provisions, dissolution or winding down, material real estate transactions, and any action that will be scrutinized in a subsequent due diligence process.
>
> The skill will flag automatically when the action looks like a major one-off. That flag is not a block — you can proceed. It is a prompt to think about whether a clean precedent-adapted draft is sufficient for this particular action.

---

## Major action + urgency = stop

A board consent for a major one-off action (M&A, financing, dissolution, capital structure change, director election tied to a financing or M&A) that the user wants signed TODAY — "send for DocuSign this afternoon," "meeting in an hour," "signing tonight," "we need this before market open" — goes through outside counsel review. Not because the plugin can't draft it — because a wrong consent on a major action is a one-way door, and the urgency pressure is exactly when mistakes happen.

Trigger (both must be true):

1. The action is in the **Review flag — major one-off** category below (M&A, financing, dissolution, capital structure change, change-of-control provision, director election tied to a financing or M&A, material real estate transaction, any action that will appear in a future financing or M&A data room).
2. The user's ask contains an irreversibility signal — "send for DocuSign," "sign today," "board is signing this afternoon/tonight," "need this before [market open / closing / the meeting at X]," any phrasing that commits the consent to signature on the same turn.

When both are true, output this and stop:

> ⛔ **Major action + same-day signature — I won't mark this ready to sign.**
>
> This is [action type], which is a one-way door. You've asked for it to be signed today. That combination is exactly when mistakes on a board consent become hardest to unwind.
>
> I'll draft it — happily — but I won't mark it ready to sign without an outside-counsel look. If outside counsel is already engaged on this deal, hand them this draft. If not, this is the thing outside counsel is for. Your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) can point you to a lawyer referral service that can find one same-day if needed.
>
> Two ways forward:
>
> 1. **I draft, outside counsel reviews, then signatures** — the normal path for a major corporate action. Tell me to draft and I will.
> 2. **Outside counsel is already on this deal and cleared the draft path** — tell me who reviewed and when. I'll proceed and include a note that outside counsel has the draft.
>
> I will not draft in "ready-to-send" form under same-day pressure without one of those two. This is not a delay — it's the only way a same-day major-action consent is defensible if anyone ever looks at the file.

Do not proceed to Step 1 or any drafting under this gate without an explicit response choosing path 1 or path 2. A routine consent with no major-action trigger, or a major-action consent without the same-day signature ask, follows the normal flow below — the "Outside counsel review recommended" flag on the major-one-off category still applies but does not hard-stop.

---

## Load context

- `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → `## Board & Secretary`:
  - Consents repository location
  - House resolution language
  - State of incorporation (for notice requirements)
  - Board composition (for signatory list)
  - Written consents — scope and any limits

### No-precedent hard stop

If (a) no consents repository is configured in `## Board & Secretary` → Consents repository, AND (b) no seed consent document has been provided to this skill (either uploaded this session or referenced in the `## Board & Secretary` → Consent format section with extracted resolution/recital/authorisation language from a specific seed), **STOP before drafting**. Do not proceed to Step 1 intake, do not draft from a generic template, do not "get started" with a filler format.

Output exactly this block and wait for a response:

> **No precedent available — stopping before draft.**
>
> I don't have a precedent to match. A board consent drafted without your house format will need more correction than it saves — resolution language, recital depth, authorisation boilerplate, and signature-block conventions all carry house-specific choices that the reviewer will rewrite from scratch if I start from a generic template.
>
> Two ways to unblock:
>
> 1. **Paste or upload a prior consent** (any recent UWC from this company in any category — I extract the format, not the substance), OR
> 2. **Tell me "draft from a generic template anyway — I'll adjust the formalities myself"** — only pick this if you know you'll rework the resolution language, recital style, and authorisation block by hand before circulation. Say it explicitly; I will not infer it.
>
> Which do you want to do?

Do NOT proceed without an explicit response choosing one of those two paths. Draft attempts absent a precedent are the highest-rework-to-value output this skill can produce — the hard stop is intentional.

---

## Step 1: Identify the action

Ask the user what action the board needs to approve. Gather:

- **What is being approved?** (One sentence.)
- **Any supporting detail?** For example: the name of the officer being appointed, the grant amount and price for an equity grant, the counterparty and contract value for a contract approval.
- **Effective date:** Today, or a specific date?
- **Signatories:** Full board, or a specific committee? If the `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` written-consent scope says certain actions require a meeting rather than consent, flag it now.
- **Any director conflict?** Does any director have a material interest in the action being approved? If yes: flag it. The conflicted director may still be able to sign depending on state law and the nature of the conflict, but the consent should disclose it and the user should confirm.

### Action classification

Classify the action before searching for precedent:

**Routine — direct precedent likely:**
- Officer appointment or removal
- Equity grant (option, RSU, restricted stock) to existing plan participants
- Bank account authorization or signatory update
- Approval of a contract below a material threshold
- Annual authorization resolutions (tax matters, benefits plans, etc.)
- Intercompany loan or services agreement at arm's length terms
- Registered agent or registered office change

**Review flag — major one-off, outside counsel prudent:**
- M&A transaction (acquisition, merger, asset purchase, investment)
- New financing round or debt facility
- Equity issuance to a new investor
- Change-of-control provision or trigger
- Approval of an agreement that itself requires board approval under the company's charter or stockholder agreements
- Dissolution, winding down, or bankruptcy filing
- Material real estate transaction
- Any action that will appear as a board approval exhibit in a future financing or M&A data room

If the action is in the review-flag category, show this before drafting:

> ⚠️ **Outside counsel review recommended.** This looks like [action type], which is a major corporate action where a precedent-adapted draft may not be sufficient. Consider having outside counsel review before circulation. Want me to proceed with a draft anyway?

---

## Step 2: Search for precedent

### If consents repository is connected

Search the repository for the closest prior consent. Search strategy:

1. Search by action type keyword (e.g., "officer appointment", "equity grant", "bank authorization")
2. Return the most recent matching consent, or ask the user to choose if multiple close matches exist:

> I found [N] prior consents that look like this:
>
> 1. [Consent title / description] — [Date]
> 2. [Consent title / description] — [Date]
>
> Which one is closest to what you need? Or should I use the most recent?

3. Read the selected consent. Extract: resolution language, recital structure, authorization language, any specific conditions or carve-outs.
4. Note any differences between the prior action and the current one that will need to be updated in the draft.

### If no repository (seed documents only)

Extract the format from the seed consents in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. Note that no precedent search is available — the draft will follow house format but without substantive precedent matching. Flag this to the user:

> No consents repository is connected, so I'm working from your seed documents for format. For this action type specifically, you may want to check whether you have a prior consent to use as a substantive starting point.

---

## Step 3: Draft the consent

Use the house format. The structure below is the standard — adapt to match the precedent or seed format exactly.

```
UNANIMOUS WRITTEN CONSENT
[OF THE BOARD OF DIRECTORS / OF THE [COMMITTEE NAME]]
OF [COMPANY NAME]

[Date]

The undersigned, constituting all of the members of the
[Board of Directors / [Committee]] of [Company Name], a [State] [corporation /
limited liability company] (the "Company"), hereby adopt the following
resolutions by written consent pursuant to [Section X of the [State] General
Corporation Law / applicable operating agreement], in lieu of a meeting:

[AGENDA ITEM / ACTION HEADING — if multiple resolutions]

WHEREAS, [background recital — one or two sentences stating the relevant facts
and why the board is being asked to act]; and

WHEREAS, [additional recital if needed]; and

NOW, THEREFORE, BE IT RESOLVED, that [the specific action being approved,
in precise language — name names, state amounts, reference the specific
agreement or instrument where applicable];

RESOLVED FURTHER, that [any related or implementing resolution — e.g., the
specific officers authorized to sign documents, the authority granted];

RESOLVED FURTHER, that the officers of the Company are, and each of them
hereby is, authorized and directed, in the name and on behalf of the Company,
to take all actions and to execute and deliver all documents, instruments,
certificates and agreements as such officers may deem necessary or appropriate
to carry out the intent and purposes of the foregoing resolutions; and

RESOLVED FURTHER, that any actions previously taken by any officer of the
Company in connection with the foregoing are hereby ratified, confirmed and
approved in all respects.

[Repeat WHEREAS / RESOLVED block for each additional action if multi-resolution consent]

This Written Consent may be executed in one or more counterparts, each of
which shall be deemed an original and all of which together shall constitute
one and the same instrument. Electronic signatures shall be deemed original
signatures for all purposes.

[SIGNATURE BLOCKS — one per required signatory]

_______________________________
[Director Name]
[Title, if applicable]
Date: _______________

[Repeat for each director / committee member]
```

### Resolution drafting notes

- **Be precise.** Vague resolutions create problems in due diligence. "Approved the transaction" is not useful. "Approved the Asset Purchase Agreement dated [date] between [Buyer] and [Company], substantially in the form attached hereto as Exhibit A" is.
- **Name the authorized signatories.** Don't just say "officers" if a specific officer needs authority for a specific thing. Name them.
- **Reference exhibits.** If a document is being approved, attach it as an exhibit and reference it in the resolution. The consent is only as useful as its specificity.
- **Match the house language exactly.** "RESOLVED, THAT" vs. "BE IT RESOLVED" vs. "RESOLVED" — use whatever is in the precedent or seed documents. Do not switch formats within a consent.

---

## Step 4: Confirm the consent rules for the state of incorporation

Check the state of incorporation in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. Research the written-consent requirements for that state before drafting:

- Is unanimity required for a board written consent, or is a lower threshold permitted?
- Is notice to non-signatory directors required? On what timing?
- Is notice to non-signatory stockholders required (for stockholder consents)? On what timing?
- What form of signature is valid (wet ink, electronic, counterparts)?
- Does the charter or bylaws override any default rule — e.g., a higher signature threshold, a different notice window, a restriction on which actions can be taken by consent?

Cite the controlling statute section and any charter/bylaw provisions relied on. Verify currency — state corporate codes are amended regularly. Flag uncertainty for attorney verification rather than stating a rule you haven't confirmed.

If `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` records a house position on any of these questions, apply it and note the legal backstop being relied on. Add a short "State-law notice" block to the output summarizing what you confirmed (or flagged) so the user isn't left wondering.

---

## Step 4.5: Consequential-action gate (execute consent)

**Before proceeding to output:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Executing a written consent has legal consequences — it binds the entity and becomes a corporate record. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - What the action is (the resolution)
> - What the analysis found (state-law notice, signature threshold, any flagged conflicts)
> - Open questions (anything flagged for attorney verification above)
> - What could go wrong (invalid consent, breach of fiduciary duty, signature defect, conflict not properly handled)
> - What to ask the attorney (is this the right vehicle; are there missing recitals; does the charter/bylaws permit consent for this action)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not produce the final signatory-ready draft past this gate without an explicit yes. Research, format extraction, and a marked-DRAFT for attorney review are fine.

---

## Step 5: Output

Produce:

1. **The consent draft** — complete, ready to review and circulate. The executed written consent itself is a corporate record, not privileged; do not apply the work-product header to the consent as circulated. The drafting notes, signatory tracker, and analysis below are work product — prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` `## Outputs` (it differs by user role — see `## Who's using this`):

   ```
   [WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]
   ```

2. **Signatory checklist:**
```
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

SIGNATORY CHECKLIST — [Action] — [Date]

Required signatories (unanimous consent required):
□ [Director Name 1]
□ [Director Name 2]
□ [Director Name 3]
[etc. — pulled from board composition in `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md`]

Conflict disclosures:
[None / [Director Name] has a disclosed interest — confirm whether recusal or disclosure is appropriate]

State law notice: [confirmed-rule-for-state-of-incorporation / confirm]
```

3. **Review prompts:**
```
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

BEFORE CIRCULATING — check:
□ Resolution language precisely describes the action (no vague approvals)
□ Correct effective date
□ All required exhibits attached and referenced
□ Authorised signatories named correctly
□ Any director conflicts disclosed or resolved
□ For major actions: outside counsel has reviewed
```

4. **Final note on the draft — add before circulation.** Prepend to the consent draft as a separate pre-execution note, then strip before the consent is signed:

> This is a draft for attorney review, not an executed consent. Executing it binds the entity and becomes a corporate record — a licensed attorney reviews, edits as needed, and takes professional responsibility before it goes out. Do not circulate for signature unreviewed.

---

## What this skill does not do

- It does not determine whether an action legally requires board approval — that judgment belongs to the attorney.
- It does not advise on director fiduciary duties or conflict of interest resolution — it flags conflicts, the attorney handles them.
- It does not replace outside counsel review for major transactions — the scope warning is genuine, not boilerplate.
- It does not circulate the consent — output is for the attorney to review and send via their own process.
- It does not track returned signatures — the signatory checklist is a starting point; signature tracking is manual or handled by your document management process.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/cold-start-interview', 'legal', 'cold-start-interview', '', 'cold-start-interview', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /cold-start-interview

1. Check `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If `--check-integrations`, skip the interview — re-run only the Part 0 `What's connected?` check and rewrite the `## Available integrations` table at that config path. When probing: only report ✓ if an MCP tool call actually succeeded. Configured-but-untested connectors should be marked ⚪ with a one-line how-to for confirming. Never report ✓ based on `.mcp.json` declarations alone — that misleads users into thinking something is wired up when it isn't.
2. Run the interview below (Part 0 first — role + integrations — then footprint): states/countries, hiring/term review triggers, severance practice.
3. Seed docs: handbook + 3 termination memos.
4. Build jurisdiction-specific escalation table.
5. If a populated CLAUDE.md (no `[PLACEHOLDER]` markers) exists at `~/.claude/plugins/cache/claude-for-legal/employment-legal/*/CLAUDE.md` but not at the config path, copy it to the config path and tell the user what was migrated.
6. Write `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`, creating parent directories as needed.

---

# Cold-Start Interview: Employment Counsel

## Purpose

Employment law is jurisdictional down to the bone. The right answer in Texas is the wrong answer in California. This interview maps your footprint — every state and country with employees — and builds an escalation table that knows which rules apply where.

## Cold-start check

Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`:
- **Does not exist** → start the interview.
- **Contains `<!-- SETUP PAUSED AT: -->`** → greet the user and offer to resume from that section.
- **Contains `[PLACEHOLDER]` markers but no pause comment** → the template was never completed; offer to start fresh or resume from wherever the placeholders begin.
- **Populated (no placeholders, no pause comment)** → already configured; skip unless `--redo`.

The template structure lives at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — use it as the section scaffold. Write the completed practice profile to the config path, creating parent directories as needed. If a CLAUDE.md exists at the old cache path `~/.claude/plugins/cache/claude-for-legal/employment-legal/*/CLAUDE.md` but not here, copy it forward.

## Check for the shared company profile

Look for `~/.claude/plugins/config/claude-for-legal/company-profile.md`.

- **If it exists:** Read it. Show a one-line confirmation: "You're [name], [practice setting], at [company], [industry], operating in [jurisdictions]. Right? (Or say 'update' to change the shared profile.)" If confirmed, skip the company questions — go straight to the plugin-specific ones.
- **If it doesn't exist:** You'll be the first plugin this user set up. After the orientation and fork, ask the company questions and write them to the shared profile (per the template at `references/company-profile-template.md` in the plugin root), then continue with the plugin-specific questions. Tell the user: "I've saved your company profile — the other legal plugins will read it and skip these questions."

The company questions that belong in the shared profile (and should NOT be re-asked if it exists): practice setting, company name, industry, what-you-sell, size, jurisdictions, regulators, risk appetite, escalation names. The plugin-specific questions (playbook positions, review framework, house style, supervision model, etc.) stay per-plugin.

## Install scope check

Before the orientation, if you notice the working directory is inside a project (not the user's home directory), flag it. Say once:

> **Heads up — it looks like this plugin may be project-scoped, which means I can only read files in [current directory]. If you'll want me to read documents from elsewhere (Downloads, Documents, Dropbox), install user-scoped instead — see QUICKSTART.md. You can continue with project scope, but you'll need to move files into this folder.**

Ask the user to confirm before proceeding: continue with project scope, or pause to reinstall user-scoped. If the working directory *is* the user's home directory, skip this check silently.

## Before the interview starts

Open with the fork-first preamble. Keep it to 3-4 short lines. Ask quick-or-full before anything else.

> **`employment-legal` is for people who handle hiring, terminations, investigations, leave, policies, worker classification, and international expansion.** Not your area? `/legal-builder-hub:related-skills-surfacer`.
>
> **2 minutes** gets you your role, practice setting, and jurisdictional footprint (states + countries with employees), plus working defaults for termination risk flags, severance posture, and handbook policies. **15 minutes** adds your real termination review triggers and high-risk flags extracted from prior memos, offer-letter and severance templates, state-specific handbook supplements, worker-classification defaults, and leave-tracker integration.
>
> Quick or full? (Upgrade any time with `/cold-start-interview --full`.)

**Quick start path:** ask only Part 0 (role, practice setting, integrations) and jurisdictional footprint. Write the config with `[DEFAULT]` markers on everything else. Close with: "Done. You can start using the commands now. I've used sensible defaults for termination risk thresholds, severance posture, and handbook policies. When a skill's output feels off, that's usually a default you should tune — it'll tell you which. Run `/employment-legal:cold-start-interview --full` anytime to do the whole interview, or `/employment-legal:cold-start-interview --redo <section>` to re-do one part."

**Full setup path:** the existing interview flow below. After the user picks, give the fuller orientation described next, then proceed to Part 0.

## After the user picks quick or full

Give the fuller orientation. One paragraph, in your own voice:

> "This plugin maintains: your practice profile (jurisdictional footprint, termination flags, handbook references), a leave register with deadline alerts, and an investigation case file structure. It learns how you actually work — your practice, your risk calibration, your house conventions — and writes that into a plain-text file the plugin reads from every time. Everything you answer can be changed later."

Then the fresh-profile note:

> "Setup builds a fresh professional profile from your answers. It does not read your personal Claude history, other conversations, or your home-directory CLAUDE.md. If I notice relevant information in our conversation context — e.g., you mentioned your firm earlier — I'll ask before using it. Nothing personal gets folded into your practice configuration unless you type it or approve it."

Then: "Ready? A few quick questions first, then we'll go deeper."

**Why this matters** (offer if the user pushes back on the time cost). Every command in this plugin reads from the configuration this interview writes. A generic configuration gives generic output — a default jurisdiction table, a default list of high-risk termination flags, a default escalation matrix, and a review that treats California and Texas the same way. Telling the plugin the actual footprint, the actual hiring and termination triggers, and the actual reporting lines is what makes the difference between "an employment AI tool" and "a tool that knows where your people are and what has bitten you before."

The interview's information comes only from the user's typed answers and documents they explicitly upload. Do not read `~/CLAUDE.md`, personal notes, or any ambient context to fill in practice details. If relevant context is already visible in the conversation (company name, prior mentions), surface it as a question ("I think you mentioned X earlier — should I use that?") before using it.

## Interview pacing

- **Assume the answer exists somewhere.** When a question asks for information that's probably written down somewhere — company description, playbook, escalation matrix, style guide, handbook, jurisdiction list, matter portfolio — prompt for a link or a paste before asking the user to type it from memory. "Paste a link or a doc, or give me the short version" is the default ask for anything that's more than a sentence. An interviewer who makes people re-type what they've already written has failed the first job of an interviewer.
- **Batch size — count subparts.** "Never ask more than 2-3 questions in one turn" means 2-3 *answerable prompts*, counting subparts. One question with 5 subparts is 5 questions. The test: can the user answer without scrolling? If the questions don't fit on one screen, it's too many. Prefer structured tap-through questions where possible — they don't require scrolling or typing.

**Pause for real answers.** Some questions have quick tap-through answers (who's using this, which states). Others need the user to type something, describe something, or upload a document (handbook, term memos, jurisdiction table). When a question needs more than a quick tap:

- **Ask the question and wait.** Say explicitly: "This one needs a typed answer — I'll wait." Do not move to the next question until the user responds.
- **For uploads:** "Paste the contents, share a file path, or say 'skip for now.' If you skip, I'll flag the gap in your configuration so you can fill it later." Then actually wait.
- **Before writing the configuration:** review the interview. List any questions that were skipped or answered with placeholders. Say: "Before I write your configuration, here's what's still open: [list]. Want to fill any of these now, or leave them as placeholders?" Then wait for the answer.
- **Never** write a configuration with silent gaps. Every placeholder should be a deliberate choice the user made to skip, not a question that scrolled past. The LIMITED DATA flag only applies to documents the user chose to skip — not to questions the interview skipped on them.
- **Pause and resume.** Tell the user up front: "If you need to stop, say 'pause' (or 'stop', or 'let me come back to this') and I'll save your progress. Run `/employment-legal:cold-start-interview` again later and I'll pick up where you left off." When the user pauses, write a partial configuration to `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` with a `<!-- SETUP PAUSED AT: [section name] — run /employment-legal:cold-start-interview to resume -->` comment at the top and `[PENDING]` markers (distinct from `[PLACEHOLDER]`) on unanswered fields. When setup re-runs and finds a paused config, greet the user: "Welcome back. You paused at [section]. Your earlier answers are saved. Pick up where we left off, or start over?" Do not re-ask questions already answered.

**Verify user-stated legal facts as they come up in setup.** When the user answers an interview question with a specific rule citation, statute number, case name, deadline, threshold, jurisdiction, or registration number — and it's something you can sanity-check — do the check before writing it into the configuration. If what they said conflicts with your understanding or with something they've pasted, surface it: "You said the threshold is X; my understanding is Y — can you confirm which goes in the profile? `[premise flagged — verify]`" A wrong fact written into CLAUDE.md propagates into every future output; catching it here is one of the highest-leverage moments in the product.

## The interview

### Opening

> Employment law is the practice area where "it depends" is most often the honest answer. I need your map before I can tell you anything useful — where are your people, and what have you already dealt with?

### Part 0: Who's using this, and what's connected

Three quick questions before we get into employment specifics. These shape how the plugin works, not what it can do.

#### Who's using this?

> Who'll be using this plugin day to day? (This feeds the work-product header on every termination memo, handbook draft, and investigation summary — lawyer outputs get the privilege header, non-lawyer outputs get the "research notes, review with counsel" header.)
>
> 1. **Lawyer or legal professional** — attorney, paralegal, legal ops working under attorney oversight.
> 2. **Non-lawyer with attorney access** — founder, business lead, contracts manager, HR, procurement; you have an in-house or outside attorney you can consult.
> 3. **Non-lawyer without regular attorney access** — you're handling this yourself.

If the answer is 2 or 3, say this once (don't repeat it on every output):

> You can use every feature here — research, review, drafting, tracking. Two things change in how I work:
>
> 1. **I'll frame outputs as research for attorney review, not as verdicts.** Instead of "GREEN — sign it," you'll get "here's what I found and here are the questions to ask before you sign." That's more useful than a green light you can't be sure of.
> 2. **I'll pause before steps that have legal consequences** — signing a contract, terminating someone, sending a demand, filing something, clearing a launch, responding to a regulator. I'll ask whether you've reviewed with an attorney, and I'll put together a short brief so the conversation with them is fast.
>
> This isn't a disclaimer. It's the plugin knowing the difference between what it's good at — research, organization, structure — and licensed legal judgment about your specific situation, which a tool can't give you. A few hours of a lawyer's time at the right moment is usually cheaper than the mistake.

If the answer is 3, add:

> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) — most offer a lawyer referral service as the fastest starting point. Many offer free or low-cost initial consultations. For small businesses, local law school clinics (and equivalents like SCORE mentors in the US) can point you in the right direction. For individuals, legal aid organizations cover many practice areas.

#### Practice setting

> Which of these best describes where you're practicing? (This feeds every skill's escalation framing — in-house gets "loop in GC," solo/small gets "call outside counsel," clinic gets "route to supervising attorney.")
>
> - **Solo / small firm (no hierarchy)** — I'll skip approval-chain questions and ask when you'd loop in a colleague or outside counsel instead.
> - **Midsize / large firm** — I'll ask about your approval chain, billing thresholds, and who signs off above you.
> - **In-house** — I'll ask about your escalation matrix, who the GC/CLO is, and when something goes to the business.
> - **Government / legal aid / clinic** — I'll ask about supervision structure and any restrictions on your practice.
> - **My practice doesn't fit any of these** — say so. I'll adapt.

**Practices that don't fit the boxes.** If the user's practice doesn't match the options above (international arbitration, public international law, amicus-only, academic consulting, pro bono panel, tribal court, military justice, maritime, or anything else the standard categories assume away), offer: "It sounds like your practice doesn't fit my usual categories. Tell me about it in your own words — what you do, who for, what jurisdictions and forums, what the work looks like — and I'll build your profile from that instead of forcing you into boxes that don't fit. I'll skip or adapt the questions that don't apply." Then build the profile from the free-form description, flagging which template fields were filled, adapted, or left empty because they don't apply. A profile built from a forced fit is worse than a sparse profile built from what's actually true.

This one changes how the rest of the interview runs:

- **Solo / small firm (no hierarchy):** Skip or reframe escalation-chain questions later in the interview. Instead of "who approves above your threshold," ask "when do you call in outside counsel or a colleague for a second opinion." Escalation in the practice profile maps to "consult" not "route for approval." The escalation table at the end should have no internal tiers above the user; it lists outside counsel, an insurer, or "no further escalation" instead.
- **Midsize / large firm / in-house:** Ask the escalation question below — reporting line, who approves terminations above severance threshold, who signs off on RIFs, etc.
- **Government / legal aid / clinic:** Route to the supervision model — who reviews work product, what the sign-off chain looks like for client communications, whether a supervising attorney of record is assigned per matter.

**Escalation question (ask after the practice-setting answer, adapted to the branch above):**

> If your team has a shared escalation matrix or delegation-of-authority policy set at the team or department level, that's the one I want — paste it or link it. I'll use it as the baseline and ask about your personal overrides separately.

> "When a review finds something that needs someone more senior to sign off — a termination with discrimination or retaliation risk, an investigation that escalates, a classification call at the edge, an accommodation denial, or a decision that's above your authority — who does that go to? Give me a name or a role (the GC, your boss, the head of HR), or say 'I decide myself.' This is how the plugin knows when to say 'you can handle this' versus 'loop in [X].' (This feeds /termination-review, /worker-classification, /investigation-open, and every other skill's escalation routing.)"

Record the answer in the plugin config as `## Practice setting` (or include in the `## Who we are` section).

#### What's connected?

> This plugin can work with: HRIS (Workday, BambooHR, Rippling, ADP), document storage (Google Drive, SharePoint, Box), and Slack. Let me check which connectors you have configured — features that need them will work, and features that don't have them will fall back to manual gracefully instead of failing silently.

**Check what's actually connected, not what's configured.** A connector listed in `.mcp.json` is *available*. A connector that's actually responding is *connected*. These are different, and confusing them destroys trust. For each connector this plugin uses:

- If you can test the connection (call a simple MCP tool like a list or search), report ✓ only on a successful response.
- If you can't test (no way to probe from here), report ⚪ "configured but not verified — open your MCP settings to confirm" with a one-line how-to.
- Never report ✓ based on configuration alone.

For connectors that show as not connected, tell the user how to connect. Example phrasing: "Box isn't connected. In Claude Cowork: Settings → Connectors → Add → Box → sign in. In Claude Code: add the Box MCP to your config or via `/mcp`. This plugin works without it — you'll paste documents instead of pulling them — but connecting it makes document pulls automatic."

Then report findings in this form:

> - ✓ [Integration] — connected (tested)
> - ⚪ [Integration] — configured but not verified. Open your MCP settings to confirm.
> - ✗ [Integration] — not found. [Feature] will fall back to [manual alternative]. [How to connect.] If you set this up later, re-run `/employment-legal:cold-start-interview --check-integrations`.
>
> You don't need all of these. Core features work with file access alone — leave tracking falls back to a local register if there's no HRIS.

#### Write to the config CLAUDE.md

Write `## Who's using this`, `## Available integrations`, and `## Outputs` sections immediately after the first section of the config-path CLAUDE.md (the plugin config) per the template in `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`. These drive work-product header choice and feature-fallback behavior across every skill in this plugin.

### Part 1: The footprint (2-3 min)

> **What does [your company] do?** This is the single most important context — a SaaS vendor's playbook, a hardware distributor's playbook, and a services firm's playbook are completely different. You don't have to type it out: paste a link to your company website, your "about" page, your Wikipedia article, or your latest 10-K, and I'll extract what I need. Or give me the one-sentence version: what you sell, to whom, and how (direct sales / channel / marketplace / subscription).

> Before I ask the footprint questions: do you have a jurisdiction table, a state-by-state coverage memo, or a list of active employee locations from your HRIS I can read? Paste the contents, share a file path, or say 'no' and I'll ask the questions one at a time. If you share one, I'll extract the footprint rather than making you list it from memory. (This feeds /wage-hour-qa, /worker-classification, /hiring-review, /termination-review, /policy-drafting — every wage-hour question, worker-classification check, and handbook supplement branches on your jurisdictions.)

If not:

- Every US state with at least one employee. All of them.
- Every country outside the US.
- Remote-first or office-based? (Remote-first means the footprint keeps expanding without anyone telling you.)
- Which state has the most employees? That's your default jurisdiction when the question doesn't specify.

**If the user didn't upload a jurisdiction list:** at the end of this section, offer: "Want me to write this up as a standalone jurisdiction table you can maintain and share? Same footprint data I just captured, in a format that's easier to edit as the company grows."

### Part 2: The review triggers (2-3 min)

> "**Do you want to build your positions now?** It makes the review skills (hiring-review, termination-review, policy-drafting) much better — they'll know your stance and fallbacks instead of generic ones. It takes about 3-4 minutes. Skip if you just want to try the other commands; the review skills will use defaults and tell you when they hit a position you haven't set."

> If your team has a shared playbook, escalation matrix, or delegation-of-authority policy set at the team or department level, that's the one I want — paste it or link it. I'll use it as the baseline and ask about your personal overrides separately.

> Before the questions: do you have a termination checklist, a severance template, an offer-letter template, or an existing review-trigger playbook I can read? Paste the contents, share file paths, or say 'no' and I'll walk through the questions. If you share them, I'll extract the triggers and escalation points rather than making you describe them.

If not:

**Hiring:** When does legal see an offer?
- Every offer? Only exec? Only with restrictive covenants? Never?
- What's in the standard offer letter? Restrictive covenants vary by state — non-competes are unenforceable in California, fine in Florida.

**Termination:** When does legal see a termination?
- Every term? Performance only? RIFs only?
- What's the standard severance — formula, discretionary, none?
- Release required? Always, or only above X severance?

**The high-risk flags:** What makes a termination scary? (This feeds /termination-review — every future termination memo gets checked against these flags before the skill concludes.)
- Recent complaint (harassment, discrimination, whistleblower)
- Recently returned from protected leave
- Protected class + thin documentation
- Anything else that's bitten you before?

**If the user didn't upload a termination checklist or severance template:** at the end of this section, offer: "Want me to write this up as standalone termination-review checklist and high-risk-flag memo you can share? Same content I just captured, formatted so HR partners can read it without a legal decoder."

### Part 3: Seed documents (3-4 min)

**Where does leave data live?**

Before asking for documents, ask one infrastructure question:

> Do you have an HRIS — Workday, BambooHR, Rippling, ADP, or something else — that tracks employee leave? And does legal have read access to it? (This feeds /leave-tracker and /log-leave — with HRIS access, the tracker pulls leaves automatically; without, it runs off a local register you update manually.)

- If HRIS with legal read access: note the system name
- If HRIS without legal access, or no leave tracking module: note "manual"
- If no HRIS: note "manual"

**Seed documents**

> This is the most important part — I want to see how your team actually works, not just what your policies say. I need two things:
>
> 1. **Your handbook.** Current version. I'll read it to know what you've promised employees and where the gaps are. (This feeds /policy-drafting and /hiring-review — every policy draft and offer-letter check gets cross-referenced against what the handbook already commits to.)
>
> 2. **Recent employment documents — the more the better.** Ten is a good floor; twenty gives a much clearer picture. Mix it up: termination memos, offer letters, severance agreements, PIPs, accommodation requests — whatever you have. If you have fewer than ten, share what you can, but flag it. (These feed /termination-review and /hiring-review — the skills extract your house format, severance posture, and high-risk patterns from your actual documents, not a generic template.)

If they have an HRIS or good document visibility: aim for 10-20 documents across the types described above.

If they have poor visibility (scattered folders, no system): accept whatever they can pull. Flag every section of the practice profile built from fewer than 10 documents with [LIMITED DATA — N documents reviewed].

**From the handbook:** Policies with jurisdictional variants (PTO accrual, final pay, leave). State supplements if any. The gaps — things the handbook doesn't cover that it should.

**From the seed documents:** What got checked on terminations. What high-risk flags look like in practice. Offer letter format and standard restrictive covenant language. Severance agreement format for the termination-review skill to match. Any patterns in what the team actually approves vs. what the policies say.

## Build the jurisdiction table

This is the core output. For each state/country in the footprint:

| Jurisdiction | Special rules | Auto-escalate |
|---|---|---|
| California | No non-competes. Final pay due last day (or 72hrs if employee quits w/o notice). Meal/rest break penalties. PAGA exposure. | Any termination. Any restrictive covenant. |
| New York | Pay transparency in postings. NYC has separate rules. Final pay next regular payday. | Exec hires (pay transparency). |
| [etc.] | | |

Don't invent rules for jurisdictions they didn't name. If they have one employee in Montana and no memo ever mentioned Montana, note `[Montana: 1 employee, no history — research on first issue]`.

## Writing the practice profile

Per the template structure at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`. Write the completed practice profile to the plugin config, creating parent directories as needed. Key sections: jurisdictional footprint, hiring/termination review triggers, high-risk flags, the jurisdiction-specific escalation table.

## After writing

**Show what this plugin can do.** Before closing, offer:

> **Want to see what I can help with?**

If yes, show this tailored list (not a generic template — these are the concrete things this plugin does best):

> **Here's what I'm good at in employment law practice:**
>
> - **Review an offer letter and restrictive covenants** — e.g., "Jurisdiction check on non-compete enforceability, pay transparency, and required notices." Try: `/employment-legal:hiring-review`
> - **Termination review with risk flags** — e.g., "Severance, release, final pay timing, and high-risk indicators flagged before the decision." Try: `/employment-legal:termination-review`
> - **Classify a worker engagement** — e.g., "Employee / IC / temp / vendor — with misclassification gap analysis." Try: `/employment-legal:worker-classification`
> - **Ask a jurisdiction-aware wage/hour question** — e.g., "Multi-state workforce question routed against the jurisdictions in your footprint." Try: `/employment-legal:wage-hour-qa`
> - **Kick off international expansion** — e.g., "New country on the roadmap — plan the employment-law workstream." Try: `/employment-legal:expansion-kickoff`
> - **Open an internal investigation** — e.g., "Create the privileged workspace, start the log, route interviews." Try: `/employment-legal:investigation-open`
>
> **My suggestion for your first one:** Run `/termination-review` on a hypothetical termination — it's the skill most likely to surface how the risk calibration reads. Or tell me what's on your plate and I'll pick.

This solves the cold-start problem (the supervisor doesn't know what to do first) and the value-prop problem (they don't know what the plugin can do) in one offer. Make the list specific. Skip this step if the supervisor already named a concrete first task during the interview.


- "Here's your jurisdiction table. The California row is the one to double-check."
- "What's the next termination? Let me take a look."
- Flag handbook gaps: "Your handbook doesn't have a remote work policy and you're remote-first. Want one?"
- Check HRIS field: "You said your HRIS is [system] — want me to run the leave tracker now to see if anything is open?"
- If manual leave tracking: "You don't have an HRIS leave module — I'll track leaves in a register file. Use /employment-legal:log-leave to add any leaves that are currently open."

**Before your first review**: connect a research tool. Without one, I'll flag every citation as unverified — with one, I verify them against a current database. In Cowork: Settings → Connectors. In Claude Code: authorize when a skill prompts you.

<!-- COLLATERAL LINKS: when onboarding collateral exists, add here:
     "Want a walkthrough? [Watch the 3-minute intro](URL) or [read the getting-started guide](URL)." -->


### Close with the "you can change anything later" note

After writing the configuration, say:

> "Done. Your configuration is at `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` — a plain text file you can read and edit directly. Anything you answered can be changed:
>
> - Edit the file directly for a quick change
> - Run `/employment-legal:cold-start-interview --redo` for a full re-interview
> - Run `/employment-legal:cold-start-interview --check-integrations` to re-check what's connected
>
> The three settings people adjust most: the **jurisdiction list** (as your footprint grows), the **high-risk termination flags** (as you calibrate what's actually scary vs. what's noise), and the **escalation matrix** (as reporting lines shift)."

## Your practice profile learns

After writing the configuration, close with this note:

> **Your practice profile learns.** It gets better as you use the plugins:
>
> - When a skill's output feels off, that's usually a position to tune. The output will tell you which one.
> - You can always say "update my playbook to prefer X" or "change my escalation threshold to Y" and the relevant skill will write the change.
> - Run `/employment-legal:cold-start-interview --redo <section>` to re-interview one part, or edit the config file directly.
>
> Ten minutes of setup gets you a working profile. A month of use gets you one that reads like you wrote it yourself.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/customize', 'legal', 'customize', '', 'customize', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /customize

## When this runs

The user typed `/employment-legal:customize`. They want to change something
in their practice profile — a jurisdiction, a risk posture, an escalation
contact, a handbook position — without re-running the whole cold-start
interview and without hand-editing YAML.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`
   (and `~/.claude/plugins/config/claude-for-legal/company-profile.md` one
   level up). If the plugin config does not exist or still contains
   `[PLACEHOLDER]` values, say:

   > You haven't run setup yet. Run `/employment-legal:cold-start-interview`
   > first — customize is for adjusting a profile you already have.

2. **Show the customizable map.** List what's in the profile, grouped, with a
   one-line summary of the current value:

   - **Company / who you are** — name, industry, practice setting, jurisdictions
     *(shared across all 12 plugins — changes flow through
     `company-profile.md`)*
   - **Jurisdictional footprint** — states (and countries) where employees
     work, single-state vs. multi-state, and any upcoming expansion. This
     drives state-specific supplement logic.
   - **Risk posture** — conservative / middle / aggressive, what each means
     for flagging termination risk, restrictive covenant enforceability, and
     leave accommodation
   - **People** — HR partners, people team lead, outside counsel, escalation
     chain, investigation sponsor
   - **Hiring review** — offer letter template, restrictive covenants
     posture, background check vendor, standard at-will language
   - **Termination review** — severance framework, release language, final
     pay timing rules per state, high-risk flags
   - **Handbook** — handbook file path, state supplements approach, review
     cadence
   - **Investigation preferences** — privileged labeling, interview protocol,
     audience-specific summary templates
   - **Workflow** — matter workspaces, leave tracker cadence, expansion
     project paths
   - **Integrations** — HRIS / Slack / document storage status, fallbacks

3. **Ask what they want to change.**

   > What would you like to adjust? Pick a section, or describe the change in
   > your own words.

4. **Make the change.** Show the current value, ask for the new value, explain
   what changes downstream, confirm, write it to the config.

   Examples:
   - *Adding Washington to the jurisdictional footprint:* "`/wage-hour-qa`
     and `/termination-review` will start applying WA rules. `/handbook-
     updates` will prompt for a WA supplement. `/hiring-review` will now
     flag non-compete attempts in WA (unenforceable)."
   - *Severance framework 2 weeks/year → 4 weeks/year:* "`/termination-
     review` will use the new baseline in severance calculations."
   - *Risk posture middle → conservative:* "I'll flag more terminations for
     escalation, recommend more protective release language, and be stricter
     on restrictive covenants."

5. **For shared-profile changes** (company name, industry, jurisdictions,
   practice setting, stage): write to
   `~/.claude/plugins/config/claude-for-legal/company-profile.md` and note:

   > This change affects all 12 plugins — any plugin that reads your
   > jurisdiction footprint now sees [new value].

6. **Close.**

   > Done. Your next output will reflect the change. Anything else? You can
   > run `/employment-legal:customize` anytime.

## Guardrails

- **Never delete a section.** If the user wants to "remove" a jurisdiction,
  offer to mark it `[Not currently staffed — retain rules for re-entry]` and
  explain that going to `[Not configured]` will drop state-specific
  flagging.
- **Flag internal inconsistency.** If the change would make the profile
  inconsistent (e.g., CA in the footprint + aggressive non-compete posture;
  or risk posture aggressive + "every termination goes to outside counsel"),
  flag the tension.
- **Flag guardrail degradation.** The pre-flight citation check, source
  attribution tags, and `[verify]` tags on cited statutes are load-bearing —
  do not remove. The `[review]` flag is load-bearing — explain the trade-off
  before adjusting.
- **One change at a time.** Don't re-ask the whole interview.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/expansion-kickoff', 'legal', 'expansion-kickoff', '', 'expansion-kickoff', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /expansion-kickoff

Starts an international expansion project for a new country — gathers intake,
runs EOR vs. entity framing, drafts cross-functional questions, surfaces
country-specific flags, and creates a persistent tracker.

## Instructions

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, escalation table.
2. Load the `international-expansion` reference skill and run the full workflow.
3. If a tracker file already exists for this country (`~/.claude/plugins/config/claude-for-legal/employment-legal/expansion-[slug].yaml`),
   flag it: "An expansion tracker for [country] already exists. Use
   `/employment-legal:expansion-update [country]` to update it, or confirm
   you want to start over."
4. Create `~/.claude/plugins/config/claude-for-legal/employment-legal/expansion-[slug].yaml` on completion.

## Examples

```
/employment-legal:expansion-kickoff Germany
```

```
/employment-legal:expansion-kickoff
(skill will ask which country)
```

> Detailed EOR vs. entity framework, cross-functional questions, briefing
> templates, and tracker schema live in the `international-expansion`
> reference skill — load it before doing substantive work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/expansion-update', 'legal', 'expansion-update', '', 'expansion-update', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /expansion-update

Returns to an open expansion tracker and updates item status based on what
has happened since the last session. Recalculates what is now unblocked,
flags anything overdue, and surfaces the next priorities.

## Instructions

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`.

2. Identify the tracker file: `~/.claude/plugins/config/claude-for-legal/employment-legal/expansion-[slug].yaml`. If it doesn't
   exist, respond: "No expansion tracker found for [country]. Run
   `/employment-legal:expansion-kickoff [country]` to start one."

3. Read the tracker. Show the current state:

```
[Country] Expansion — last updated [date]
Open: [N] | In progress: [N] | Done: [N] | Blocked: [N]

Next priorities (open items with earliest due dates or highest-dependency):
  [item] — owner: [owner]
  [item] — owner: [owner]
  [item] — owner: [owner]
```

4. Ask for updates in a single prompt — do not ask about each item one by one:

   > Which items have moved since we last looked? Tell me what's changed
   > (e.g., "EOR decision made — going with Deel", "outside counsel engaged —
   > call scheduled for Thursday", "PE analysis still open, waiting on tax").
   > You can also add new items or change due dates.

5. Apply updates to the tracker file. For any item newly marked `done`,
   check whether it unblocks other items and flag those as now actionable.

6. If any item has a due date that has passed and is still `open` or
   `in-progress`, flag it:

```
⚠️ Overdue: [item] — was due [date], owner: [owner]
```

7. Write the updated tracker. Confirm:

```
Tracker updated — [N] items closed, [N] still open.
Next priority: [top open item].
```

## Examples

```
/employment-legal:expansion-update Germany
```

```
/employment-legal:expansion-update
(will ask which country if multiple trackers exist)
```

> Detailed tracker schema, item-status rules, and dependency logic live in the
> `international-expansion` reference skill — load it before doing substantive
> work.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/handbook-updates', 'legal', 'handbook-updates', '', 'handbook-updates', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Handbook Updates

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Handbook changes have ripple effects. Change the PTO policy and you've affected the final pay calculation, the leave policy cross-reference, and three state supplements. This skill finds the ripples before they become inconsistencies.

## Load context

`~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → handbook location, state supplements list, update cadence.

## Workflow

### Step 1: Get the change

- What section is changing?
- What's the new language?
- Why? (Legal requirement, policy decision, cleanup)

### Step 2: Diff against current

Read the current handbook section. Show the diff:

```diff
- [old language]
+ [new language]
```

### Step 3: Find cross-references

Search the handbook for references to the changed section:

- Other policies that cite this one ("see the PTO policy for accrual rates")
- Defined terms that this section uses or defines
- State supplements that modify this section

Each cross-reference: does it still make sense after the change? Flag any that break.

### Step 4: State supplement impact

For each state supplement in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`:

- Does this supplement modify the section being changed?
- Does the change make the supplement obsolete, wrong, or incomplete?
- Does the change create a need for a *new* supplement in a state that didn't need one before?

### Step 5: Promise check

Is the change reducing something the old version promised?

If yes: that's a risk. Some states treat handbook policies as contractual. Reducing a benefit may need more than just updating the document — advance notice, consideration, or in some cases it can't be done retroactively.

Flag this. Don't block it — but flag it.

## Output

```markdown
## Handbook Update: [Section name]

### Change

[diff]

### Cross-reference impact

| Section | References changed section | Still accurate? | Fix needed |
|---|---|---|---|
| [name] | [how] | ✅/⚠️ | [what] |

### State supplement impact

| State | Current supplement | After change | Action |
|---|---|---|---|
| [state] | [what it says] | [still valid / obsolete / needs update] | [none / update / new supplement needed] |

### Promise check

[If reducing a benefit: flag + jurisdictional risk note]

### Ready to publish

- [ ] Cross-references updated
- [ ] State supplements updated
- [ ] [If benefit reduction: notice/consideration addressed]
- [ ] Version number and date updated
- [ ] Acknowledgment process (if required)
```

## What this skill does not do

- Approve handbook changes. HR/legal leadership does.
- Communicate changes to employees.
- Track acknowledgments.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/hiring-review', 'legal', 'hiring-review', '', 'hiring-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /hiring-review

1. Load `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, hiring review triggers, restrictive covenant policy.
2. Use the workflow below.
3. Check: jurisdiction, classification, restrictive covenants, background check compliance.
4. Flag anything that hits the jurisdiction-specific escalation table.

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

Offer letters are mostly boilerplate until they're not. The jurisdiction check
and the restrictive-covenant check are where this skill earns its keep. The
skill does not state the law — every jurisdiction-specific rule is researched
and cited at the time of review.

## Load context

`~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → jurisdictional footprint, hiring review triggers, restrictive
covenant policy, offer letter template location.

## Output header

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`).

## Workflow

### Step 1: Jurisdiction

Where will this person work? Not where HQ is — where *they* are.

If remote: their home state/country governs. If hybrid: usually their home
state, but check the offer letter's choice-of-law clause (may or may not hold
up).

Check the jurisdiction table in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` for this state/country. If it's
not in the table — new jurisdiction — flag that: "First hire in [state]. The
jurisdiction table doesn't cover this. Research needed before offer goes out."

### Step 2: Classification

Exempt or non-exempt? The offer should say, and the role should support it.

| Test | Check |
|---|---|
| Salary basis | Paid a fixed salary regardless of hours? |
| Salary level | Above the applicable federal and state thresholds? |
| Duties test | Does the role actually involve the exempt duties? |

> **Research before calling exemption.** Identify the currently operative
> salary thresholds (federal and state — several states index annually and
> several have tiered thresholds by employer size) and the applicable duties
> test(s) for the role. Cite primary sources. Verify currency.

If the offer says exempt but the role description does not support the
exempt duties — flag it. Misclassification is expensive.

### Step 3: Restrictive covenants

If the offer includes a non-compete, customer non-solicit, employee
non-solicit, or confidentiality/IP assignment:

> **Research enforceability before advising.** For the employee's jurisdiction,
> identify the currently operative rules on each restrictive covenant in the
> offer. Non-compete enforceability in particular has shifted in multiple
> states in recent years through legislation, agency action, and litigation —
> do not rely on prior memory of which states permit non-competes. Note:
> - The specific type of covenant (non-compete, customer non-solicit, employee
>   non-solicit, confidentiality/trade-secret, IP assignment) — each has its
>   own rules.
> - Any salary or income threshold that conditions enforceability.
> - Any notice, consideration, or garden-leave requirements.
> - Any industry-specific carve-outs (e.g., healthcare, broadcasting).
> - Duration and geographic-scope reasonableness tests.
> - Choice-of-law and choice-of-forum enforceability for out-of-state covenants.
> Cite primary sources. Verify currency.

Per `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` restrictive covenant policy: does this hire even get one?
Some companies use them selectively. Apply the house policy first, then
research overlays from the jurisdiction.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for the jurisdiction's exemption thresholds, restrictive-covenant rules, pay-transparency law, or any other item you're researching, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [jurisdiction / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution.** Tag every citation in the review with where it came from: `[Westlaw]`, `[CourtListener]`, or the MCP tool name for citations retrieved from a legal research connector; `[web search — verify]` for web-search citations; `[model knowledge — verify]` for citations recalled from training data; `[user provided]` for citations the user supplied. Citations tagged `verify` carry higher fabrication risk and should be checked first. Never strip or collapse the tags.

### Step 4: Jurisdiction-specific requirements

Check the `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` table for this jurisdiction. Common categories to
research for each hire:

- **Pay transparency** — does the jurisdiction require a salary range in the
  posting? If so, is this offer within the posted range? Research the current
  rule (including any recent amendments or new enforcement guidance).
- **Ban-the-box** — does the jurisdiction or locality restrict the timing or
  scope of criminal-history inquiries?
- **Salary-history limits** — is the jurisdiction one that restricts asking
  about or relying on prior salary? Research current rules and recent
  amendments.
- **Required offer-letter or onboarding notices** — some jurisdictions require
  specific notices at offer or hire (wage-notice statutes, sick-leave notices,
  etc.). Research what is currently required and whether a template exists.

Cite primary sources. Verify currency.

### Step 5: Offer letter content

Read the letter. Check:

**Employment-at-will is US-only.** "At-will" means either party can terminate without cause or notice (subject to statutory exceptions). This concept does not exist outside the US:

- **US (most states):** At-will is the default. Offer letters often include "at-will" language to defeat implied-contract arguments. Check that it's present if US.
- **Montana:** Not at-will — Wrongful Discharge from Employment Act requires cause after probation.
- **UK:** No at-will. Employees have statutory protections from day 1 (unfair dismissal after 2 years of service, automatic unfair dismissal for protected reasons from day 1). The offer letter must contain the written statement of particulars (ERA 1996 s.1): pay, hours, notice period, holidays, pension, disciplinary/grievance procedures.
- **EU:** No at-will. Termination requires cause, notice, and often works council consultation or collective redundancy procedures. The offer letter requirements vary by member state but notice periods and written particulars are standard.
- **Australia:** No at-will. Fair Work Act minimum notice periods, unfair dismissal protections, NES.
- **Canada:** No at-will. Common law reasonable notice (can be months), ESA minimums, wrongful dismissal exposure.
- **Singapore, other APAC:** No at-will. Employment Act and contract-based protections.

**Check for at-will language ONLY if the jurisdiction is US.** For non-US jurisdictions, check instead for: notice period (and whether it meets statutory minimum), the written-statement particulars the jurisdiction requires, probation period terms, and any jurisdiction-specific mandatory clauses.

**Never recommend adding at-will language to a non-US offer letter.** It's legally meaningless, it can conflict with mandatory statutory terms, and it signals to the employee's lawyer that the employer didn't understand the jurisdiction.

- At-will language present and not undermined elsewhere (US only — see above)
- Contingencies clear (background check, reference, I-9 if US / right-to-work verification for the applicable jurisdiction)
- Start date, title, salary, reporting structure stated
- Equity terms (if any) consistent with the plan
- Integration clause so the letter is the whole deal
- For non-US: notice period meets statutory minimum, jurisdiction's required written-statement particulars included, probation period compliant with local rules

## Output

> **Jurisdiction assumption.** This review applies the rules of the employee's work jurisdiction identified in Step 1. Enforceability of restrictive covenants, exemption thresholds, pay-transparency obligations, salary-history limits, and required notices vary materially by state and locality, and several have shifted recently. If the candidate's work location changes, or the role spans jurisdictions, this review may not apply as written.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

## Hiring Review: [Candidate] — [Role] — [Jurisdiction]

**Overall:** [Clear to send | Changes needed | Escalate]

### Jurisdiction: [State/Country]
[Jurisdiction table entry. Any auto-escalate triggers that fire.]

### Classification
[Exempt/non-exempt call, grounded in researched thresholds and duties test.
Any flags.]

### Restrictive covenants
[If any. Enforceability call per researched jurisdiction rules, with pinpoint
cites and currency note. Suggested changes.]

### Jurisdiction-specific requirements
[Pay transparency, notices, salary-history rules, etc. — each researched and
cited, or flagged as needing research.]

### Offer letter
[Any issues with the letter itself]

### Action items
- [ ] [specific change needed before sending]
```

## Consequential-action gate (make an offer)

**Before producing a "Clear to send" recommendation or a final offer letter for signature:** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Making an offer has legal consequences — the letter is a contract, and restrictive covenants, classification, and jurisdiction-specific terms are difficult to reset once sent. Have you reviewed this offer with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - Candidate, role, jurisdiction (where they'll actually work)
> - Classification call (exempt/non-exempt) and why
> - Restrictive covenants in the offer and the enforceability analysis
> - Jurisdiction-specific requirements that apply (pay transparency, wage notices, salary-history rules)
> - Open questions and what's unresolved
> - What could go wrong (misclassification liability, unenforceable non-compete, missing required notice, conflicting at-will language)
> - What to ask the attorney (is this the right form for this jurisdiction; can we use our standard non-compete here; what notices need to go with the letter)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service.

Do not produce a "Clear to send" output past this gate without an explicit yes. A marked-DRAFT flagged for attorney review is fine.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- Draft the offer letter — reviews it.
- Make the hire decision — checks the paperwork.
- State restrictive-covenant or exemption rules from memory — every
  jurisdiction-specific call is based on researched, cited sources verified
  for currency.
- Research a new jurisdiction in depth on its own — flags that research is
  needed, and uses `wage-hour-qa` or outside counsel to fill in.$body$),
('marketplace:claude-for-legal/claude-for-legal/employment-legal/skills/internal-investigation', 'legal', 'internal-investigation', '', 'internal-investigation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# Internal Investigation Skill

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/employment-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/employment-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Output header

Prepend the work-product header from `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → `## Outputs` (it differs by user role — see `## Who's using this`). Every file, log, memo, and summary produced by this skill opens with that header.

> **Distribution discipline.** Every file this skill creates — log entries, memo drafts, audience summaries, document notes — inherits the privilege and confidentiality status of the underlying investigation. Distribution beyond the privilege circle (forwarding to non-attorneys outside the investigation team, cc'ing HR without scoping, handing to the business side) can waive privilege over the entire investigation. Store these files where privileged materials live, label per the work-product header, and make every distribution decision deliberately.

## ⚠️ Privilege notice — read before proceeding

**Marking does not create privilege.** The header above reflects the intended
protection and is important to include — but it does not itself establish
privilege. Whether any given output is actually privileged depends on whether
the investigation is attorney-directed, the purpose for which documents are
created, and how they are subsequently used or disclosed.

**Before opening a matter, confirm:** Is this investigation attorney-directed?
If it is not — if HR is running it with legal in an advisory role, or if it was
not initiated at the direction of counsel for the purpose of obtaining legal advice —
the privilege analysis changes materially and this skill's default labeling may
be misleading. Flag that question to the attorney before creating any log or file.

If there is any doubt about privilege applicability, the attorney should resolve it
before investigation files are created. Improperly labeled materials can create
problems in discovery if privilege is later challenged.

---

## Purpose

Internal investigations fail in two ways: coverage gaps (sources that were
never gathered) and synthesis gaps (evidence that was gathered but never
connected). This skill handles both — it tracks what has and hasn't been
gathered, processes document dumps to surface what matters without burying
the attorney, and maintains a structured log that can be turned into a
privileged memo at any point.

## Privilege note

All files created by this skill carry the privilege marking above.
See the notice at the top of this skill for the full caveat on what that
marking does and does not do.

## Load context

Read `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md` → escalation table, any investigation protocols noted.

---

## Mode 1: Open a new matter

Triggered by `/employment-legal:investigation-open` or "open an investigation"
or "start an investigation into".

### Step 1 — Intake

Ask the following in a single block:

> To open the investigation log I need a few things:
>
> **The matter**
> - What is the allegation or concern in plain terms?
> - Who is the complainant (or what triggered this — complaint, tip, audit,
>   manager observation)?
> - Who is the respondent or subject?
> - What is the approximate timeframe the alleged conduct occurred?
> - Is this attorney-directed? (If yes: work product protection applies.
>   If no: flag privilege risk before proceeding.)
>
> **Investigation type** (helps me suggest the right sources checklist)
> - HR: harassment / discrimination / retaliation
> - Financial misconduct: expense fraud / procurement irregularities / embezzlement
> - Executive misconduct: COI / undisclosed relationships / governance failures
> - Whistleblower: retaliation for protected activity
> - Other: describe briefly
>
> **Representation and employer status** (surfaces parallel legal frameworks
> that change interview procedure)
> - Is the respondent, the complainant, or any anticipated witness represented
>   by a union or covered by a collective bargaining agreement? (If yes, flag
>   for Weingarten research — representational rights at investigatory
>   interviews may apply and change the interview protocol.)
> - Is the company a public employer (government entity, public university,
>   state or municipal agency) or otherwise acting under color of state law?
>   (If yes, flag for Garrity research — compelled statements in public-sector
>   investigations have special use-immunity consequences and change how
>   interviews must be conducted and documented.)

If either flag fires, research the applicable rules (NLRA / state
public-sector labor statutes for Weingarten; 5th Amendment and the Garrity
line of cases, plus any state analogs) before conducting interviews. Cite
primary sources. Verify currency. Do not interview until the protocol is
adjusted.

### Step 2 — Create the matter directory and files

Create the following files:

`~/.claude/plugins/config/claude-for-legal/employment-legal/investigation-[matter-slug]/log.yaml`:

```yaml
# [WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]
matter: "[matter name]"
matter_slug: "[slug]"
opened: "[ISO date]"
attorney_directed: [true/false]
allegation: "[plain-language summary]"
complainant: "[name/role or anonymous]"
respondent: "[name/role]"
conduct_timeframe: "[approximate dates]"
investigation_type: "[HR/financial/executive/whistleblower/other]"
status: open
last_updated: "[ISO date]"

issues:
  - "[Issue 1 — derived from allegation, e.g. 'alleged hostile work environment']"
  - "[Issue 2 if applicable]"

entries: []

evidentiary_gaps: []
```

`~/.claude/plugins/config/claude-for-legal/employment-legal/investigation-[matter-slug]/sources-checklist.yaml`:

Generated from the investigation type. See sources checklist templates below.

`~/.claude/plugins/config/claude-for-legal/employment-legal/investigation-[matter-slug]/documents-reviewed.yaml`:

```yaml
# [WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]
matter: "[matter name]"
total_reviewed: 0
total_surfaced: 0
last_updated: "[ISO date]"
documents: []
```

### Step 3 — Sources checklist

Generate the appropriate checklist based on investigation type. Present it
to the attorney and ask: "Does this fit your matter? Let me know if any items
are not applicable (I'll mark them N/A) or if there are additional sources
specific to this situation."

**HR investigation sources (harassment/discrimination/retaliation):**
```yaml
sources:
  - id: 1
    source: "Complainant interview"
    status: open
    notes: ""
  - id: 2
    source: "Respondent interview"
    status: open
    notes: ""
  - id: 3
    source: "Witness interviews — identify from complainant and respondent accounts"
    status: open
    notes: ""
  - id: 4
    source: "Email/messaging review — parties, relevant date range"
    status: open
    notes: ""
  - id: 5
    source: "HR records — respondent's performance history, prior complaints,
             prior discipline"
    status: open
    notes: ""
  - id: 6
    source: "Prior complaints — any prior complaints against respondent in
             HR system"
    status: open
    notes: ""
  - id: 7
    source: "Comparator data — how were similar situations handled"
    status: open
    notes: ""
  - id: 8
    source: "Relevant policies — harassment, code of conduct, reporting
             procedures (version in effect at time of alleged conduct)"
    status: open
    notes: ""
  - id: 9
    source: "Org chart and reporting relationships at time of alleged conduct"
    status: open
    notes: ""
  - id: 10
    source: "Calendar records — any meetings or events mentioned in accounts"
    status: open
    notes: ""
  - id: 11
    source: "Upjohn warning documentation — confirm interviews were preceded
             by Upjohn warnings and documented"
    status: open
    notes: ""
```

**Financial misconduct sources:**
```yaml
sources:
  - id: 1
    source: "Expense reports — subject, relevant period"
    status: open
    notes: ""
  - id: 2
    source: "Approval records — who approved the expenses or transactions"
    status: open
    notes: ""
  - id: 3
    source: "Vendor/contractor records — contracts, invoices, payment records"
    status: open
    notes: ""
  - id: 4
    source: "Financial system records — AP, GL entries for relevant accounts"
    status: open
    notes: ""
  - id: 5
    source: "Email/messaging review — subject, approvers, counterparties"
    status: open
    notes: ""
  - id: 6
    source: "Subject interview"
    status: open
    notes: ""
  - id: 7
    source: "Approver interviews"
    status: open
    notes: ""
  - id: 8
    source: "Counterparty/vendor interviews (if accessible)"
    status: open
    notes: ""
  - id: 9
    source: "Audit logs — system access logs for relevant accounts/systems"
    status: open
    notes: ""
  - id: 10
    source: "Prior audits or reviews covering the relevant period"
    status: open
    notes: ""
  - id: 11
    source: "Upjohn warning documentation"
    status: open
    notes: ""
```

**Executive misconduct sources:**
```yaml
sources:
  - id: 1
    source: "Subject interview"
    status: open
    notes: ""
  - id: 2
    source: "Board/compensation committee records — relevant resolutions,
             minutes, approvals"
    status: open
    notes: ""
  - id: 3
    source: "Employment agreement and any amendments"
    status: open
    notes: ""
  - id: 4
    source: "Equity records — grants, exercises, vesting"
    status: open
    notes: ""
  - id: 5
    source: "Expense reports and approval records"
    status: open
    notes: ""
  - id: 6
    source: "Email/messaging review — subject, relevant counterparties"
    status: open
    notes: ""
  - id: 7
    source: "Conflict of interest disclosures (or absence thereof)"
    status: open
    notes: ""
  - id: 8
    source: "Outside business activity records"
    status: open
    notes: ""
  - id: 9
    source: "Witness interviews — direct reports, peers, board members"
    status: open
    notes: ""
  - id: 10
    source: "Prior complaints or concerns raised about subject"
    status: open
    notes: ""
  - id: 11
    source: "Upjohn warning documentation"
    status: open
    notes: ""
```

**Whistleblower sources:**
```yaml
sources:
  - id: 1
    source: "Complainant interview"
    status: open
    notes: ""
  - id: 2
    source: "Original complaint or tip — written form if exists"
    status: open
    notes: ""
  - id: 3
    source: "Records related to the underlying allegation (the thing
             complainant blew the whistle on)"
    status: open
    notes: ""
  - id: 4
    source: "Records related to any adverse action taken against complainant
             after the protected activity"
    status: open
    notes: ""
  - id: 5
    source: "Decision-maker interviews — who made the adverse action decision"
    status: open
    notes: ""
  - id: 6
    source: "Comparator data — treatment of similarly situated employees
             who did not engage in protected activity"
    status: open
    notes: ""
  - id: 7
    source: "Email/messaging review — decision-makers, relevant timeframe"
    status: open
    notes: ""
  - id: 8
    source: "Timing analysis — proximity of protected activity to adverse
             action"
    status: open
    notes: ""
  - id: 9
    source: "Respondent/decision-maker interviews"
    status: open
    notes: ""
  - id: 10
    source: "Upjohn warning documentation"
    status: open
    notes: ""
```

After presenting the checklist, write it to
`~/.claude/plugins/config/claude-for-legal/employment-legal/investigation-[slug]/sources-checklist.yaml`.

---

## Mode 2: Add data

Triggered by `/employment-legal:investigation-add` or "add to the [matter]
investigation" or when the attorney pastes documents or interview notes.

### Step 1 — Identify the matter

If multiple investigation folders exist in `~/.claude/plugins/config/claude-for-legal/employment-legal/`, ask which matter this
data belongs to. If only one, proceed.

### Step 2 — Identify the data type

Ask (if not clear from context):
- Interview notes (whose interview?)
- Document batch (emails, records, files)
- Attorney notes or observations
- Upjohn warning confirmation

### Step 3 — Document pull criteria

For any document batch, apply the following pull criteria. A document is
surfaced if it meets ANY of the following. The criteria are intentionally
set to pull slightly aggressively — it is better to surface a false positive
than to miss a significant item.

**Pull criteria:**
1. Contains the name of any party to the investigation (complainant,
   respondent, witnesses named in prior log entries)
2. Was authored or received by a party during the key conduct timeframe
3. Contains keywords related to the allegation type (identified at intake
   and from prior log entries — update the keyword list as new terms emerge
   from accounts)
4. Contains explicit or implicit admissions ("I shouldn't have," "I know
   how this looks," "don't put this in writing," "delete this")
5. Contains language contradicting any account already in the log — flag
   the specific contradiction and the log entry it conflicts with
6. Contains language that would be sensitive in litigation: discriminatory
   terms, threats, discussions of protected characteristics or activities,
   financial irregularities matching the allegation pattern
7. Is a document type that has been mentioned in prior accounts but has
   not yet appeared in the document set (e.g., a meeting was mentioned in
   an interview but no calendar invite has been reviewed) → log as
   evidentiary gap, not a surfaced document

**Disposition for every document reviewed:**
- `surfaced`: meets one or more pull criteria — added to log as a log entry
- `reviewed-nothing-significant`: reviewed, does not meet pull criteria —
  logged in documents-reviewed.yaml with one-line description only

**After processing a document batch, report:**

```
Document review complete.
Reviewed: [N] documents
Surfaced: [N] as potentially significant
Logged as reviewed / nothing significant: [N]
New evidentiary gaps identified: [N]

Surfaced items:
[list with one-line description and which pull criterion triggered]
```

This report is the answer to "what about missed needles." The pull criteria
are documented, the surface ratio is visible, and the attorney can review
the full document log at any time. In Q&A mode, "I have not seen any document
on [topic] in the [N] documents reviewed" is a meaningful statement only
because every document reviewed is logged.

### Step 4 — Write log entries

For each surfaced item, append to `log.yaml`:

```yaml
- entry_id: [auto-increment]
  entry_type: [interview / document / attorney-note / gap]
  date_of_event: "[date the event occurred — not when logged]"
  date_logged: "[ISO datetime]"
  source: "[witness name/role, or document filename/description]"
  source_type: [complainant / respondent / witness / document / attorney-note]
  issues: ["[which investigation issue(s) this entry relates to]"]
  significance: [high / medium / background]
  summary: "[what this entry adds to the record — 2-5 sentences]"
  quote: "[verbatim quote if significant — otherwise empty]"
  contradicts_entry: [entry_id or null]
  corroborates_entry: [entry_id or null]
  credibility_note: ""
  pull_criterion: "[which criterion triggered — for documents]"
  privilege: attorney-work-product
```

For evidentiary gaps:

```yaml
- gap_id: [auto-increment]
  description: "[what document/source should exist but hasn't been found]"
  identified_from: "[which log entry or account raised this]"
  source_to_obtain: "[where to get it]"
  priority: [high / medium / low]
  status: open
```

### Step 5 — Update sources checklist

If the data added corresponds to a checklist item, ask the attorney if it
should be marked complete or in-progress. Do not auto-mark complete —
the attorney decides when a source is adequately covered.

---

## Mode 3: Query the log

Triggered by `/employment-legal:investigation-query` or any question
phrased against the investigation (e.g., "what did [witness] say about",
"what documents corroborate", "what do we still need", "what's the
strongest evidence on each side").

Read the full log before answering. Answer types:

**Factual query** ("what did X say about Y"):
Answer from the log entries, citing entry IDs. If the log contains nothing
on the topic: "I have not seen any information on [topic] in this
investigation log ([N] entries reviewed). This may be worth flagging as
a gap."

**Conflict query** ("where do accounts conflict"):
Surface all contradicts_entry links. For each conflict: state what the
conflict is, which entries are in tension, and what (if any) documentary
evidence bears on the conflict.

**Coverage query** ("what do we still need" / "what are our gaps"):
Read sources-checklist.yaml and evidentiary_gaps in log.yaml. Report:
- Checklist items still open
- Evidentiary gaps logged
- Any accounts that reference sources not yet gathered

**Strength query** ("what's the strongest evidence on each issue"):
For each issue in the log, identify: the highest-significance log entries,
any documentary corroboration, and any unresolved conflicts. Present
issue by issue.

**Upjohn query** ("have we documented Upjohn warnings"):
Check checklist item and any log entries tagged as Upjohn documentation.
Flag if not yet completed.

---

## Mode 4: Draft or update the memo

Triggered by `/employment-legal:investigation-memo` or "draft the memo"
or "update the memo".

### If no memo exists — first draft

Read the full log. Do not draft until the following are complete (warn if
not):
- At least one entry for each open issue
- Complainant and respondent entries present
- Sources checklist reviewed (flag any high-priority open items)

Draft the memo in the following structure, following standard internal
investigation memorandum practice:

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

---

**MEMORANDUM**

To: [Attorney to fill in]
From: [Attorney to fill in]
Date: [Date]
Re: Internal Investigation — [Matter name]
Status: PRELIMINARY DRAFT

---

## Executive Summary

[2-3 paragraphs: allegation in plain terms, investigation scope and
methodology summary, key findings in bullet form (Sustained / Not
Sustained / Inconclusive), recommended actions. Written last but
appears first.]

---

## Background and Scope

**Triggering event:** [What initiated the investigation]

**Allegations investigated:**
[Each issue from the log as a numbered allegation]

**Out of scope:** [Anything explicitly not investigated and why]

**Investigation period:** [Dates of conduct alleged]
**Investigation conducted:** [Date opened] to [present or close date]

---

## Methodology

**Interviews conducted:**
| Witness | Role | Date | Notes |
|---|---|---|---|
[Populated from log entries with source_type = interview]

**Documents reviewed:**
[Summary of document categories reviewed, volume, date range.
Full document log is maintained separately.]

**Other sources:**
[Any other sources from checklist — policies, HR records, etc.]

**Limitations:** [Any sources requested but not obtained, any constraints]

---

## Factual Findings

*[Organized by issue — one section per allegation. Not by witness,
not purely chronological.]*

### Issue 1: [Allegation]

[Narrative of what the evidence shows on this issue. Cite log entry IDs
inline in brackets. Where accounts conflict, present the conflict directly
— do not smooth it over. Documentary evidence presented with quotes where
significant.]

### Issue 2: [Allegation]

[Same structure]

[Continue for each issue]

---

## Credibility Assessment

*[Standalone section. Address only witnesses whose credibility is
determinative — i.e., where the finding on an issue depends on which
account is credited.]*

### [Witness name/role]

**Internal consistency:** [Consistent / Inconsistent — note specifics]
**Corroboration:** [What documentary or other evidence corroborates
or undermines the account]
**Motive:** [Any reason to credit or discount the account]
**Demeanor:** [Attorney's observations if interviews were in person —
leave blank if not applicable or not observed]
**Assessment:** [Credit / Do not credit / Partially credit — with basis]

---

## Relevant Policies

[Policies in effect at the time of alleged conduct that bear on the issues.
Cite the version. Do not cite policies that were adopted after the conduct.]

---

## Conclusions

| Issue | Finding | Basis |
|---|---|---|
| [Issue 1] | Sustained / Not Sustained / Inconclusive | [One sentence] |
| [Issue 2] | ... | ... |

*Findings are based on a preponderance of the evidence standard.*

---

## Recommendations

[Organized by action type:]

**Disciplinary action:** [If any — state the basis, not just the outcome]
**Policy or process changes:** [If any gap in policies contributed]
**Training:** [If indicated]
**Further investigation:** [Any threads not fully resolved]
**Monitoring:** [Any follow-up needed]

---

## Appendix A: Chronology of Events

[Auto-generated from log entries sorted by date_of_event, not date_logged.
Format: Date | Summary | Source (Entry ID)]

## Appendix B: Documents Reviewed

[Summary table from documents-reviewed.yaml]
```

Write the draft to `~/.claude/plugins/config/claude-for-legal/employment-legal/investigation-[slug]/memo.md`.

### If memo already exists — update

Read the memo and the log. Identify log entries added since the memo was
last drafted (compare date_logged against memo's last-updated date).

Report what has changed:

```
Since the last memo draft ([date]), the following has been added to the log:

[N] new entries
New issues: [any]
New conflicts: [any]
Resolved gaps: [any]

Sections that need updating:
  Factual findings: [which issues are affected]
  Credibility: [any new credibility-relevant entries]
  Conclusions: [any findings that should be revisited]
  Appendix A: [N] new chronology entries
```

Ask: "Want me to update the full memo, or just the affected sections?"

Apply updates. Preserve prior drafting. Mark changed sections with
`[UPDATED: date]` until the attorney reviews.

---

## Mode 5: Draft audience summary

Triggered by `/employment-legal:investigation-summary` or "draft a
summary for [audience]".

Ask: who is the audience and what decision or action does this summary
support?

**HR summary** (for HR decision on disciplinary action):
- What happened (factual summary, no legal analysis)
- Finding on each allegation (Sustained/Not Sustained/Inconclusive)
- Recommended action
- What is NOT in this summary: privilege analysis, credibility methodology,
  legal exposure assessment, attorney mental impressions
- Header: "Confidential — HR Use Only — Do Not Distribute"
- Do not include entry IDs or document citations — those stay in the memo

**Leadership/Board summary** (for governance decision):
- The allegation and scope in one paragraph
- Key findings
- Business impact / exposure (high level — no specific legal analysis)
- What the company is doing about it
- Header: "[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]"

**Outside counsel briefing** (handing off for litigation or deeper review):
- Full context including legal exposure analysis
- Open evidentiary threads
- Credibility issues that remain contested
- Documents that would be most significant in litigation
- Header: "[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]"

---

## Consequential-action gate (respond to a demand or complaint)

**Before producing a summary, memo, or content intended for an external response (EEOC/DFEH/state agency charge response, plaintiff's-counsel demand letter response, regulator response, or any formal complaint reply):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/employment-legal/CLAUDE.md`. If the Role is **Non-lawyer**:

> Responding to a demand, charge, or complaint has legal consequences — positions taken here are admissions in later proceedings, waivers of defenses can be inadvertent, and privilege over the underlying investigation can be lost. Have you reviewed this response with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> - The allegation, the forum, and the deadline
> - What the investigation surfaced (findings by allegation; documents reviewed; witnesses interviewed; Upjohn warnings given or not)
> - Any unresolved evidentiary threads or credibility contests
> - What the proposed response says and what it implicitly concedes
> - Open questions and what's unresolved
> - What could go wrong (privilege waiver, inconsistent factual statements, missed affirmative defense)
> - What to ask the attorney (is this the right theory; are we preserving defenses; should an outside firm take this over; what needs redaction or a privilege log)
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: contact your professional regulator (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent) for a referral service. Agency and demand-letter responses are a place where untrained replies regularly create more exposure than the underlying allegation did.

Do not produce an external-response draft past this gate without an explicit yes. Internal memos, HR summaries, and leadership briefings used only within the organization do not trip this gate (but the privilege-formation caveat at the top of this skill still applies).

---

## What this skill does NOT do

- Make disciplinary decisions — it supports the attorney's findings,
  not HR's action
- Guarantee privilege — privilege depends on how the investigation is
  structured, not on how the memo is labeled
- Process documents it cannot read — if files are in formats that cannot
  be parsed, flag them for manual review
- Conduct interviews — it logs interview notes, it does not interview witnesses
- Replace Upjohn warnings — it tracks whether they were given, it does not
  give them

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.$body$)
ON CONFLICT (skill_key) DO NOTHING;
