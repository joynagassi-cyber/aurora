# Low-Hanging Fruit Finder

Rank workspace solutions by ease of execution to recommend the lowest-risk, best-scoped starting point.

## Workflow and Scoring Rubric

1. **Fetch the workspace overview**: run `stitch find solutions --json`, `stitch find insights --json`, and `stitch find priorities --json`. Extract each solution (`title`, `spec.summary`, `insights`), its linked insights (`state`, `priority`, `severity`, `priorities`), and workspace priorities (`objective`, `description`). Keep only solutions linked to active insights (`state="ACTIVE"`), skipping `RESOLVED` or `DISMISSED` insights.
2. **Score each solution (`Fruit Score`, 1–10, higher = easier)**:
   - **Scope (40% weight)** from `spec.summary` footprint:
     - `8-10`: single file, single handler, config change, or additive-only (no existing code modified).
     - `5-7`: a few files in one module with no API contract changes.
     - `3-4`: multiple modules, requires coordination, or touches shared code.
     - `1-2`: architectural overhaul, cross-cutting concern, or migration.
      - Signal words: easy (`handler`, `endpoint`, `middleware`, `config`, `header`, `add`, `minimal`) vs. hard (`re-architect`, `migrate`, `decompose`, `normalize`, `overhaul`, `engine`). Favor additive and observability work (handlers, metrics, logging, error handling) over refactoring existing paths.
   - **Risk (35% weight)** from blast radius and follow-on work:
     - `8-10`: additive only, no behavior change to existing paths, clear acceptance criteria.
     - `5-7`: modifies existing behavior behind a flag or with clear rollback.
     - `3-4`: changes shared data models affecting multiple consumers.
     - `1-2`: breaking API changes, data migration, or multi-service coordination.
   - **Clarity (25% weight)** from specification precision:
     - `8-10`: specific acceptance criteria, clear success metrics, constrained scope.
     - `5-7`: clear summary and general direction, but vague on specifics.
     - `3-4`: abstract or aspirational with multiple interpretations.
     - `1-2`: unclear problem statement requiring open-ended research.
3. **Rank and deep-dive the winner**: sort descending by `(scope * 0.40) + (risk * 0.35) + (clarity * 0.25)`, select the top 3, and run `stitch get solution <id> --json` for the winner to read its full `spec.specMarkdown` before recommending (`spec.summary` alone is insufficient to judge scope).

## Output Structure

Present the recommendation for one workspace at a time with these sections:

- **The Pick**: solution title, `Fruit Score: X.X/10 (Scope: X, Risk: X, Clarity: X)`, and a 1–2 sentence summary of why it is the best starting point.
- **What to Do**: concrete implementation checklist from `spec.specMarkdown`.
- **What It Reaches**:
  - **Scope**: narrow list of files or systems touched.
  - **Risk**: what could break (near zero for low-hanging fruit).
  - **Done when**: acceptance criteria from the spec.
  - **Watch out**: constraints or gotchas from the spec.
- **Alternatives**: top 3 runner-up solutions with their `Fruit Score` and a one-line summary of why they ranked lower.
