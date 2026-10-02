# Understand: Analysis and Synthesis

Synthesize workspace findings and uncover cross-priority patterns using the pre-materialized markdown wiki.

## The wiki

Run `stitch wiki generate` to materialize the full workspace graph (priorities, insights, and solutions) into searchable markdown files under `.stitch/wiki`:
- **Full workspace view**: inspect all priorities, insights, and solutions together instead of paginating individual API responses.
- **Cross-priority comparison**: search across files to compare findings and spot structural relationships or distribution gaps across the full dataset.

## Wiki analysis patterns

Run these searches from `.stitch/wiki`:
- **Map insights to priorities**: `grep 'insights/' priorities/*.md`
- **Check priority distribution across insights**: `grep -h 'P[0-4]' insights/*.md | sort | uniq -c`
- **Count solutions per insight**: `for f in insights/*.md; do echo "$(grep -c 'solutions/' "$f") $(basename $f)"; done | sort -rn`

## Cross-priority synthesis

Stitch analyzes each priority independently and does not automatically link shared root causes across priorities (for example, a CI/CD priority finding `"caching disabled"` and a dead-code priority finding `"unused dependencies slow installs"` may both point to the same build system). When you find cross-cutting patterns that describe the same underlying problem from different angles, either create a spanning priority to surface deeper insights or record a manual synthesis document.
