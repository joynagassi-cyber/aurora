# Orient: Context Strategy

Prepare and upload optional workspace context to deepen analysis from code-level issues to behavioral and product insights.

## Context depth

Context is optional and additive—Stitch works with connected repositories alone and surfaces richer findings as you attach data:
- **Code only** (repos connected, no context): enables code-level findings such as dependency issues, config errors, and dead code.
- **Some context** (session logs or analytics): enables behavioral findings such as usage patterns and friction signals.
- **Rich context** (multiple data sources): enables product-level findings such as workflow gaps and strategic positioning.

## Context types

- **Session logs** (user-agent conversation transcripts): friction detection, repetition patterns, and user language analysis.
- **Analytics data** (usage metrics, funnel data): drop-off points, feature adoption, and engagement patterns.
- **User feedback** (bug reports, feature requests): priority signals, pain points, and unmet needs.
- **Error logs** (stack traces, failure rates): reliability gaps and error clustering.

## Preparing and uploading context

- **Upload raw data, not pre-analyzed summaries**: provide raw evidence so the system performs its own analysis rather than repeating pre-digested conclusions.
- **Describe context neutrally**: state what the data is (`"Design session transcript. 38 sessions. User and agent turns."`), not what it concludes (`"Sessions showing user frustration with spatial changes."`).
- **Specify the schema for structured data**: include the schema field (such as `JSON object: {sessionId, sessionNumber, turns: [{turnIndex, actor, content}]}`) to help the parser interpret structured payloads.
- **Scope and timing**: upload one context per logical unit (one session, feedback batch, or error log) via `stitch create context` before creating priorities so analysis runs have full data; use the SDK for large uploads that exceed CLI `--json` payload limits.
