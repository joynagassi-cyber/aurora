# Stitch Loop Workflow Guide

Move a Stitch Loop workspace through five non-linear states—Orient, Focus, Understand, Act, and Refine—looping back from Refine to any earlier state as needed.

## Orient

Orient establishes what the workspace sees: connected repositories (automatic) plus optional uploaded context (session logs, analytics, user feedback, error logs). Context is additive:
- **Start (code only)**: automatic when repositories are connected; surfaces code-level issues.
- **Next (some context)**: upload session logs or analytics to unlock behavioral findings.
- **Later (rich context)**: combine multiple data sources for product-level insights.

See [workflow/orient.md](workflow/orient.md) for context preparation and upload strategy.

## Focus

Focus defines the workspace priorities that drive analysis:
- **Independent analysis threads**: each priority runs separately without connecting findings across priorities, so choose priorities that cover distinct problem areas without overlap.
- **Specificity matches certainty**: use specific phrasing when you know what to target, and open phrasing when exploring with rich context.

See [workflow/focus.md](workflow/focus.md) for priority design and phrasing patterns.

## Understand

Understand synthesizes what Stitch found across priorities:
- **Materialize the workspace wiki**: run `stitch wiki generate` to write the workspace graph into searchable local markdown files instead of making sequential API calls.
- **Synthesize across priorities**: search across priority and insight files in the wiki to connect shared root causes that independent priority runs do not link automatically.

See [workflow/understand.md](workflow/understand.md) for wiki analysis recipes.

## Act

Act executes on findings based on insight type:
- **Code findings** (config errors, dead code, missing tests): generate solutions that propose code changes, and let higher autonomy levels open branches and PRs.
- **Product findings** (workflow gaps, user friction, strategy insights): use findings to write specs and guide roadmap decisions; no automated execution path exists.

See [workflow/act.md](workflow/act.md) for solution selection strategy.

## Refine

Refine loops back to improve any earlier state:
- **Re-Orient**: upload richer context, delete noisy data sources, or add new signal types.
- **Re-Focus**: tighten or broaden priority phrasing, add priorities for uncovered gaps, or delete unproductive priorities.
- **Re-Understand**: dismiss irrelevant insights and regenerate the wiki after workspace changes.

See [workflow/refine.md](workflow/refine.md) for iteration and restart criteria.
