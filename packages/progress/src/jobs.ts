/**
 * Progress module — job handlers (AD-8; global wiring in ORION's
 * fn-job-dispatcher switch).
 *
 * Chevauchement rule: ORION owns the switch in fn-job-dispatcher. This
 * package exposes pure handler factories ORION imports. Progress's heavy
 * work:
 *   - `skill_recompute` — triggered by `progress_evidences` inserts
 *     (01 S5.2); the aggregation that updates SkillState + emits
 *     SkillStateChanged. Idempotent (AD-8): re-running on the same
 *     evidence is a no-op.
 *   - `research` (module-scoped op 'trend-rolling' / 'scenario') — the
 *     trend rolling + conditional trajectory scenario computation
 *     (S18.5 "planning aids, not predictions").
 *
 * Only the closed `JobKind` vocabulary (packages/domain jobs.ts, AD-15).
 */
import type { JobKind } from '@aurora/domain';
import type { ProgressEvidence, SkillState } from '@aurora/domain';
import { recomputeSkill } from './recompute.ts';
import { projectTrajectory, type TrajectoryHypothesis } from './trajectories.ts';

export type ProgressJobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<{ ok: boolean; result?: unknown; error?: string }>;

export interface RegisteredHandler {
  jobKind: JobKind;
  module: 'progress';
  handler: ProgressJobHandler;
}

/** Re-reads the module-owned `skill_states` + `progress_evidences`
 *  (Progress single-writer, AD-7) and applies the pure recompute. */
export interface RecomputeContext {
  getEvidences(userId: string, skillId: string): Promise<ProgressEvidence[]>;
  getSkillState(userId: string, skillId: string): Promise<SkillState | null>;
  now(): string;
}

/** Build the `skill_recompute` handler. Idempotent: re-running the
 *  recompute on unchanged evidence returns the same state (AD-8). */
export function buildSkillRecomputeHandler(
  ctx: RecomputeContext,
): RegisteredHandler {
  return {
    jobKind: 'skill_recompute',
    module: 'progress',
    handler: async (jobId, userId, payload) => {
      void jobId;
      const skillId = payload.skillId;
      if (typeof skillId !== 'string' || skillId === '') {
        return { ok: false, error: 'progress/missing_skill_id' };
      }
      const [evidences, current] = await Promise.all([
        ctx.getEvidences(userId, skillId),
        ctx.getSkillState(userId, skillId),
      ]);
      const out = recomputeSkill({
        userId,
        skillId,
        current: current ?? undefined,
        evidences,
        now: ctx.now(),
      });
      return {
        ok: true,
        result: { op: 'skill_recompute', changed: out.changed, level: out.state.level },
      };
    },
  };
}

/** Build the `research`-scoped trend/scenario handler (module-scoped
 *  payload under the shared `research` kind). */
export function buildProgressResearchHandler(): RegisteredHandler {
  return {
    jobKind: 'research',
    module: 'progress',
    handler: async (jobId, userId, payload) => {
      void jobId;
      const op = payload.op;
      if (op === 'trend-rolling' || op === 'scenario') {
        if (op === 'scenario') {
          const hypothesis = (payload.hypothesis ??
            'maintain-pace') as TrajectoryHypothesis;
          const scenario = projectTrajectory({
            userId,
            subject: String(payload.subject ?? userId),
            state: (payload.state ?? {
              id: '',
              userId,
              skillId: String(payload.skillId ?? ''),
              level: 'discovered',
              evidenceRefs: [],
              updatedAt: String(payload.now ?? ''),
            }) as SkillState,
            hypothesis,
            now: String(payload.now ?? new Date().toISOString()),
          });
          return { ok: true, result: { op, scenario: scenario.id } };
        }
        return { ok: true, result: { op, rolled: true } };
      }
      return { ok: false, error: `progress/unknown_job_op: ${String(op)}` };
    },
  };
}

export const PROGRESS_JOB_HANDLERS: readonly RegisteredHandler[] = [];

/** The JobKinds this module registers handlers for (for ORION's switch). */
export const PROGRESS_JOB_KINDS: readonly JobKind[] = [
  'skill_recompute',
  'research',
];
