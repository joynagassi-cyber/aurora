# Focus: Priority Design

Design and phrase workspace priorities at the right specificity to guide independent analysis threads.

## Priority specificity

Match priority specificity to your understanding of the problem space and available data (rich context like session logs and analytics supports open priorities because the data provides the signal; code-only workspaces need more specific priorities):
- **Specific** (`"Enable Turborepo remote caching"`): use when you know the exact fix.
- **Outcome-focused** (`"Users can achieve their design intent efficiently"`): use when you know the desired state.
- **Open** (`"Identify gaps in the design editing workflow"`): use when exploring.
- **Too open** (`"Improve the product"`): avoid; too diffuse to focus analysis.

## Priority phrasing

All phrasings can uncover the same underlying issues, but form shapes how broadly Stitch searches and frames findings:
- **Bare verb** (`"Optimize build times"`): direct, focused analysis.
- **Imperative** (`"I want to optimize my CI/CD pipelines"`): slightly more exploratory.
- **Declarative** (`"Build times are optimized"`): frames findings against a desired end-state.
- **Question** (`"Why are my builds slow?"`): investigative, broader exploration.

## Anti-patterns

- **Encoding the solution**: `"Add a properties panel for precise edits"` tells Stitch what to recommend instead of discovering alternatives.
- **Encoding the diagnosis**: `"Fix the session context loss problem"` assumes the root cause instead of finding it from evidence.
- **Overlapping priorities**: each priority runs independently, so two priorities covering the same area produce duplicate, unconnected findings.
- **Too many initial priorities**: start with 2–4 priorities to keep review and synthesis manageable, then add priorities as you identify gaps.
