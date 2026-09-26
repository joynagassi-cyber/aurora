/**
 * @aurora/ascent — source hierarchy (wave 3, docs/ascent/overview.md S16).
 *
 * External corpora are ranked A > B > C > D (authority). The hard rule:
 * Level D NEVER overrides Level A/B/C — when a Level C example
 * contradicts a Level A norm, the norm wins and Ascent FLAGS the
 * conflict (never silent). This is a data policy, not an LLM judgment.
 */
import type { AscentSourceLevel } from '@aurora/domain';

/**
 * Authority ranking: higher index = lower authority. A is the most
 * authoritative (normative/official), D the least (blog/AI-generated).
 */
export const SOURCE_LEVELS: readonly AscentSourceLevel[] = ['A', 'B', 'C', 'D'];

export function sourceAuthority(level: AscentSourceLevel): number {
  const i = SOURCE_LEVELS.indexOf(level);
  if (i < 0) throw new Error(`ascent/unknown_source_level: ${String(level)}`);
  return SOURCE_LEVELS.length - i; // A=4, B=3, C=2, D=1
}

/** The most authoritative source among a set of refs. */
export function strongestSource(levels: AscentSourceLevel[]): AscentSourceLevel | undefined {
  if (levels.length === 0) return undefined;
  return levels.reduce((best, l) =>
    sourceAuthority(l) > sourceAuthority(best) ? l : best,
  );
}

export interface SourceRefInfo {
  refId: string;
  level: AscentSourceLevel;
  label?: string;
}

export interface HierarchyConflict {
  /** the winning ref (higher authority) */
  winner: SourceRefInfo;
  /** the overridden ref (lower authority) */
  overridden: SourceRefInfo;
  /** the human-readable flag written into path metadata (never silent) */
  message: string;
}

/**
 * Enforce the hierarchy between two conflicting refs: the higher-authority
 * ref wins. D can never beat A/B/C. Returns the conflict record so the
 * caller can flag it in the path (overview S16 "Ascent flags the
 * conflict … following Level A"). No conflict (same or compatible level)
 * returns `undefined`.
 */
export function resolveConflict(a: SourceRefInfo, b: SourceRefInfo): HierarchyConflict | undefined {
  const authA = sourceAuthority(a.level);
  const authB = sourceAuthority(b.level);
  if (authA === authB) return undefined; // same authority — no override
  const [winner, overridden] = authA > authB ? [a, b] : [b, a];
  return {
    winner,
    overridden,
    message: `Source ${overridden.label ?? overridden.refId} (Level ${overridden.level}) conflicts ` +
      `with ${winner.label ?? winner.refId} (Level ${winner.level}). Following Level ${winner.level}.`,
  };
}

/**
 * Rank a step's source refs: most authoritative first. This ordering is
 * what the UI badge shows (A/B/C/D) and what the path treats as the
 * governing provenance (AD-11).
 */
export function rankSources(refs: SourceRefInfo[]): SourceRefInfo[] {
  return [...refs].sort((x, y) => sourceAuthority(y.level) - sourceAuthority(x.level));
}

/**
 * Flag every pairwise conflict inside a step's source refs. A step whose
 * Level D ref contradicts its Level A ref is flagged; the flag is written
 * into the path metadata so it is never silent (S16 rule).
 */
export function flagConflicts(refs: SourceRefInfo[]): HierarchyConflict[] {
  const conflicts: HierarchyConflict[] = [];
  const seen = new Set<string>();
  for (let i = 0; i < refs.length; i++) {
    for (let j = i + 1; j < refs.length; j++) {
      const c = resolveConflict(refs[i]!, refs[j]!);
      if (c) {
        const key = [c.winner.refId, c.overridden.refId].sort().join(':');
        if (!seen.has(key)) {
          seen.add(key);
          conflicts.push(c);
        }
      }
    }
  }
  return conflicts;
}
