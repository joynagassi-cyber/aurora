# Prove a finding

Verify a claimed workspace finding by reproducing the deviation between current and expected behavior against an explicit oracle and assigning an evidence-backed verdict.

## 1. Source workspace context

Check existing workspace state to avoid duplicate work and align with active objectives:
- Run `stitch find priorities --json` to inspect active workspace objectives.
- Run `stitch find insights --json` (or read `.stitch/wiki/graph.json`) to locate existing findings. Insights are read-only from the CLI and can go stale—treat them as leads to verify rather than facts, and determine whether the finding is new, tied to an active priority, or already tracked.

## 2. Isolate the trigger

Build a deterministic Minimal Reproducible Example (MRE)—a script, test, or exact command sequence with unrelated noise stripped away—that reliably reproduces the issue when executed.

## 3. Define the oracle

Name the authoritative source of truth (formal specification, SLA, golden dataset, or reference behavior) and produce a side-by-side comparison of the system's actual output against the oracle's expected output.

## 4. Quantify the impact

Convert subjective observations (`"the UI feels slow"`, `"the code is messy"`) into objective measurements or boolean assertions:
- **Performance**: profiler trace, flame graph, or latency metric (such as `"API response time is 2000ms at p99"`).
- **Code quality**: static analysis metric (such as cyclomatic complexity score or dependency graph cycles).
- **Functionality**: boolean assertion in a test suite.

## 5. Demonstrate falsifiability

Create a behavioral Red/Green transition: a test or measurement that fails on the current tree (Red) and will pass once the underlying issue is fixed in any reasonable way (Green).

## 6. Assign a verdict

End every finding with one verdict decided by evidence gathered in the current session (do not default to `REAL`, as insight and wiki findings go stale quickly):
- `REAL`: the MRE ran and demonstrated the deviation against the oracle.
- `ALREADY_FIXED`: the current tree already meets the oracle; cite the `file:line` showing the fix.
- `FALSE`: the claimed code or behavior does not exist as described; cite the `grep` or file read proving this.
- `NEEDS_RUNTIME_MRE`: static evidence is plausible but insufficient; record the exact runtime command still required.

## 7. Ground-truth self-audit

Before recording a verdict, confirm that every cited file path and symbol exists in the current tree verbatim, impact figures are measured in this session (or marked `"not measured"`), and any batch audit re-checks a random sample of at least 20% (or 5 findings) from scratch with counts per verdict and evidence for every non-`REAL` finding.
