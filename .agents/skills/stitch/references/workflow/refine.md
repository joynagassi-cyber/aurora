# Refine: Iteration Strategy

Iterate on workspace results by adjusting context, priority phrasing, or triaged findings across earlier workflow states.

## Refinement levers

- **Re-Orient (change what the system sees)**: upload new context (session logs for friction, analytics for drop-off, error logs for failures) when behavioral patterns are missing, and delete noisy contexts that produce irrelevant findings.
- **Re-Focus (change what the system looks for)**: switch to a more open priority phrasing when findings are too shallow or a more specific phrasing when findings are scattered, add priorities for uncovered gaps, and delete priorities that yield only obvious or generic findings.
- **Re-Understand (change how you interpret findings)**: dismiss non-actionable insights with `stitch dismiss insights <insight-id>`, regenerate the wiki after workspace changes by running `stitch wiki clean` followed by `stitch wiki generate`, and document cross-cutting patterns manually.

## When to refine vs. restart

- **Refine** when Stitch surfaces relevant findings but misses specific signals—add context or adjust priorities to fill the gap.
- **Restart** in a new workspace when the priority structure is fundamentally wrong or the connected repositories need to change.
