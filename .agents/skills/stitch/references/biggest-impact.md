# Keystone Finder

Identify the single keystone solution in a workspace whose completion invalidates, subsumes, or narrows the scope of the most other solutions.

## Core Concept: Invalidation

A solution invalidates another when completing the first makes the second unnecessary, redundant, or trivially small through one of three mechanisms:
- **Sibling subsumption**: multiple solutions address the same insight (`insights` cluster of 3+ solutions), and the broadest-scope fix (such as a data-model overhaul rather than a tactical cache) subsumes narrower siblings.
- **Root cause elimination**: a structural solution eliminates the root cause that other solutions treat as symptoms. Compare `spec.summary` root-cause signals (`normalize`, `restructure`, `re-architect`, `decompose`, `model`, `schema`, `engine`) against symptom signals (`cache`, `timeout`, `truncate`, `suppress`, `filter`, `throttle`, `limit`, `cap`).
- **Priority convergence**: a solution satisfies 3+ distinct priorities through its `solution -> insights -> priorities` chain, partially invalidating single-priority solutions under those priorities.

## Workflow and Scoring Rubric

1. **Fetch the workspace graph**: run `stitch find solutions --json`, `stitch find insights --json`, and `stitch find priorities --json`.
2. **Score each solution**:
   - **Subsumption (40% weight)**: count sibling solutions that share at least one insight in `insights`, and boost if the solution's `spec.summary` uses root-cause language while siblings use symptom language.
   - **Coverage (35% weight)**: count unique priorities reached across all linked insights (`solution -> insights -> priorities`), normalized to a 1–10 scale against total workspace priorities.
   - **Cascade (25% weight)**: estimate total invalidated solutions as `direct_invalidations + (indirect_invalidations * 0.5)`, where direct invalidations are narrower siblings and indirect invalidations are symptom solutions under the same priorities.
   - **Keystone Score**: compute `(subsumption * 0.40) + (coverage * 0.35) + (cascade * 0.25)`, ranking by invalidation ratio (other work eliminated per unit of effort) rather than raw project size. The highest-scoring solution is the keystone.
3. **Deep-dive the keystone**: run `stitch get solution <id> --json` for the top-ranked solution, read its full `spec.specMarkdown`, and map which solutions it eliminates versus which independent solutions survive.

## Output Structure

Present the analysis for one workspace at a time with these sections:

- **The Pick**: solution title, `Keystone Score: X.X/10 (Subsumption: X, Coverage: X, Cascade: X)`, and a 2–3 sentence explanation of why it is the structural root-cause fix.
- **What to Do**: concrete implementation checklist from `spec.specMarkdown`, candid about effort.
- **What It Reaches**:
  - **Eliminates**: count and list of solutions made unnecessary, citing the causal mechanism (`sibling subsumption`, `root cause elimination`, or `priority convergence`) for each.
  - **Survives**: solutions addressing independent priorities or subsystems that remain valuable.
  - **Cost and trade-off**: honest scope, risk, timeline, and what you gain versus defer by committing to this path.
  - **Stepping stones**: intermediate symptom-level solutions that serve as useful precursors moving toward the keystone rather than away from it.
- **Alternatives**: top 3 runner-up solutions with their `Keystone Score` and a one-line summary of the root cause they address and what they would invalidate.
