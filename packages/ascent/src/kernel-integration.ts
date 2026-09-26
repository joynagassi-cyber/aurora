/**
 * @aurora/ascent — Agent Kernel integration (wave 3, docs/ascent/overview.md
 * S5, S7; implementation.md "Integration Points" + Step 4).
 *
 * Ascent is a CAPABILITY of the single Agent Kernel (AD-12, S22 "1
 * capability, not 13 agents"): the kernel's Context Builder reads the
 * current `AscentLearningIR` to plan the next session, and the kernel emits
 * the `LearningCommand`s (generate_qcm / start_mirror / …) that Ascent's
 * path declares. Ascent reacts to the 6 consumed AD-9 events by rewriting
 * its OWN row (AD-7 single-writer, AD-9 closed vocabulary).
 *
 * This module is PURE and FORWARD-COMPATIBLE: it consumes only the AD-15
 * SSoT types from `@aurora/domain` (the kernel has not yet implemented
 * `packages/agent`, so nothing here imports `@aurora/agent` — AD-1). The
 * kernel plugs into these seams:
 *
 *  - `ascentSessionContext(path)` — the slice of the path the Context
 *    Builder should inject for "what should the user learn next?"
 *    (01 S5.6).
 *  - `collectLearningCommands(path)` — the LearningCommand[] the kernel
 *    dispatches to the Learning module for the active step (AD-7).
 *  - `reactTo(path, event, opts)` — event-driven adaptation; returns the
 *    rewritten path (the kernel persists it to `ascent_paths`).
 *  - `learningCommandsForStuck(path, skillId, opts)` — the "Je bloque"
 *    remediation commands (overview S14 flow).
 *
 * Level-1 derivation ("what to learn next" = current + next, S11) lives
 * in the domain (`packages/domain`'s `Level1View`) so that the Slide-Ascent
 * UI and this server-side Context Builder share ONE derivation — the plan
 * and the render never disagree.
 */
import type {
  AscentActivity,
  AscentLearningIR,
  AscentStep,
  DomainEvent,
  Level1View,
} from '@aurora/domain';
import { level1 } from '@aurora/domain';
import {
  adaptPath,
  insertRemediationForBlocker,
  type AdaptOpts,
} from './adapter.ts';

/**
 * A LearningCommand is the domain command Ascent emits for the Learning
 * module (AD-7): Ascent decides WHAT and in what ORDER; Learning does the
 * work (generate the QCM, start the mirror, …). Shape = `AscentActivity.
 * learningCommand` (SSoT, AD-15 — no re-declaration).
 */
export type LearningCommand = AscentActivity['learningCommand'];

/**
 * The Context Builder's slice of a path (01 S5.6 "Context Builder reads
 * AscentLearningIR"): the goal, the always-visible current+next steps
 * (progressive-disclosure Level 1, S11), the depth record, and the open
 * adaptations the kernel may surface as "why this order?".
 */
export interface AscentSessionContext {
  goal: string;
  targetSkill?: string;
  targetDate?: string;
  status: AscentLearningIR['status'];
  /** Level 1 (S11): current + next step only — never the full path. */
  l1: Level1View;
  /** the active step the kernel should plan a session around. */
  activeStep: AscentStep | undefined;
  /** stepId -> depth (S13). */
  depth: AscentLearningIR['depth'];
  /** the most recent adaptations (audit trail the kernel may explain). */
  recentAdaptations: AscentLearningIR['adaptations'];
}

/**
 * Build the kernel's session context from a path. `l1` is derived the same
 * way Slide-Ascent derives it (S11 single source of truth), so the server
 * plans the session on exactly what the UI will show.
 */
export function ascentSessionContext(path: AscentLearningIR): AscentSessionContext {
  const activeStep =
    path.steps.find((s) => s.status === 'active') ??
    path.steps.find((s) => s.status === 'pending' && s.phase !== 'recap');
  return {
    goal: path.goal,
    targetSkill: path.targetSkill,
    targetDate: path.targetDate,
    status: path.status,
    l1: level1(path),
    activeStep,
    depth: path.depth,
    // only the tail of the log — the kernel does not replay the full history.
    recentAdaptations: path.adaptations.slice(-5),
  };
}

/**
 * Collect the LearningCommands the kernel should dispatch for one step's
 * ACTIVE activities (AD-7: Ascent -> Learning, via the use-case). Only
 * steps that actually carry a `learningCommand` contribute; the order is
 * the step's activity order (pedagogical sequence, S10).
 */
export function collectLearningCommands(
  path: AscentLearningIR,
  stepId: string,
): LearningCommand[] {
  const step = path.steps.find((s) => s.id === stepId);
  if (!step) return [];
  const cmds: LearningCommand[] = [];
  for (const a of step.activities) {
    if (a.learningCommand) cmds.push(a.learningCommand);
  }
  return cmds;
}

/**
 * The LearningCommands for the kernel to plan NOW: the active step's
 * commands, else the current step's. Empty when nothing is actionable
 * (e.g. the path is paused or all steps are done) — the kernel then plans
 * Productivity only.
 */
export function currentLearningCommands(path: AscentLearningIR): LearningCommand[] {
  const ctx = ascentSessionContext(path);
  if (ctx.activeStep) return collectLearningCommands(path, ctx.activeStep.id);
  if (ctx.l1.current) return collectLearningCommands(path, ctx.l1.current.id);
  return [];
}

/**
 * Event-driven adaptation seam. Returns the REWRITTEN path; the kernel
 * persists it to `ascent_paths` (AD-7 single-writer). Unknown / non-
 * consumed events leave the path unchanged (AD-9 stays closed).
 */
export function reactTo(path: AscentLearningIR, event: DomainEvent, opts: AdaptOpts): AscentLearningIR {
  return adaptPath(path, event, opts);
}

/**
 * The "Je bloque" flow (overview S14): stuck -> diagnose -> remediate.
 * Returns `{ path, commands }` — the remediation commands the kernel hands
 * to Learning, and the path with the remediation step inserted.
 */
export function remediateBlocker(
  path: AscentLearningIR,
  skillId: string,
  opts: AdaptOpts,
): { path: AscentLearningIR; commands: LearningCommand[] } {
  const next = insertRemediationForBlocker(path, skillId, opts);
  const blockerStep = next.steps.find(
    (s) => s.phase === 'remediation' && s.skillRef === skillId && s.status === 'pending',
  );
  return {
    path: next,
    commands: blockerStep ? collectLearningCommands(next, blockerStep.id) : [],
  };
}
