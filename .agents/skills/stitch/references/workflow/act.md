# Act: Execution Strategy

Execute on workspace insights by generating code solutions for technical findings or translating product findings into roadmap decisions.

## Two execution paths

- **Code-level insights** (such as disabled Turborepo caching or unused dependencies slowing CI): run `stitch generate solutions --insight <insight-id>` to propose code changes. The priority's autonomy level determines whether Stitch also opens branches and PRs (`CREATE_ASSETS`, `SUBMIT_ASSETS`).
- **Product-level insights** (such as users switching tools for precise edits or distrusting targeted changes): document the findings to inform product specs and architecture decisions. No automated execution path exists for product insights.

## Selecting solutions

When an insight has multiple proposed solutions, evaluate all of them before acting:
- **Check dependencies**: verify whether solutions conflict or require prerequisite changes, and do not execute multiple solutions for the same insight simultaneously.
- **Prefer root causes**: choose solutions that fix the underlying system over band-aids that patch a symptom.
- **Prefer reversibility**: favor configuration changes over architectural rewrites when impact is comparable.
