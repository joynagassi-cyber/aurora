/**
 * validate.ts — deterministic validation of the 23 composite workflows
 * (wave 4, HARPYS).
 *
 * Invariants checked (authority: docs/workflows/composite-workflows.md
 * "Cross-workflow invariants"):
 *   1. AD-9 closed vocabulary: eventsEmitted / eventsConsumed ⊆ the 9 events
 *      (imported from @aurora/domain — the SSoT, AD-15). No 10th event.
 *   2. AD-15 JobKind: every job ∈ JobKind (AD-8: heavy work is a
 *      persisted idempotent job).
 *   3. AD-7 single writer: eventsEmitted ⊆ PRODUCERS[module of owner].
 *      A workflow only EMITS events produced by a module it owns in its
 *      flow (the producer lane); it OBSERVES the others via the events
 *      table (eventsConsumed), never by direct table access (AD-2).
 *   4. AD-2: module list is non-empty and every data table has an owner
 *      module present in the workflow flow.
 */
import type { DomainEventName } from '@aurora/domain';
import type { Workflow, WorkflowModule, WorkflowValidation } from './types.ts';

/**
 * The AD-9 producer matrix (01 S3.3 normative):
 * one producer per event. Workflows may only EMIT events of a module
 * that sits in their flow.
 */
export const EVENT_PRODUCER: Record<DomainEventName, WorkflowModule> = {
  TaskCompleted: 'Productivity',
  CourseImported: 'Learning',
  FlashcardReviewed: 'Learning',
  ProgressEvidenceCreated: 'Progress',
  SkillStateChanged: 'Progress',
  GoalUpdated: 'Productivity',
  ArtifactGenerated: 'Artifact',
  JobCompleted: 'Integrations', // job system = Foundation/Integrations ops lane
  DiscoveryItemCreated: 'Discovery',
};

/**
 * Table owner (AD-7 single writer, data-ownership-matrix.md): every table
 * touched by a workflow must be owned by one of the workflow modules.
 */
export const TABLE_OWNER: Record<string, WorkflowModule> = {
  learning_sessions: 'Learning',
  flashcards: 'Learning',
  courses: 'Learning',
  learning_items: 'Learning',
  // calendar = the productivity events/time-block store (01 §4.1)
  calendar: 'Productivity',
  goals: 'Productivity',
  projects: 'Productivity',
  tasks: 'Productivity',
  events: 'Productivity',
  time_blocks: 'Productivity',
  habits: 'Productivity',
  routines: 'Productivity',
  focus_sessions: 'Productivity',
  decisions: 'Productivity',
  semantic_nodes: 'Knowledge',
  semantic_edges: 'Knowledge',
  semantic_bridges: 'Knowledge',
  node_state: 'Knowledge',
  semantic_tree_version: 'Knowledge',
  document_chunks: 'Knowledge',
  source_refs: 'Knowledge',
  sources: 'Knowledge',
  discovery_items: 'Discovery',
  discovery_sources: 'Discovery',
  gaps: 'Discovery',
  progress_evidences: 'Progress',
  progress_snapshots: 'Progress',
  progress_trajectories: 'Progress',
  skill_states: 'Progress',
  artifacts: 'Artifact',
  expert_skills: 'Agent',
  skill_hypotheses: 'Agent',
  contrastive_pairs: 'Agent',
  skill_validation_log: 'Agent',
  agent_runs: 'Agent',
  integrations: 'Integrations',
};

/**
 * Validate ONE workflow against the invariants. Returns a verdict that
 * is stable and deterministic (used by tests and by the docs pipeline).
 */
export function validateWorkflow(
  w: Workflow,
  domainEventNames: readonly string[],
  jobKinds: readonly string[],
): WorkflowValidation {
  const violations: string[] = [];

  // AD-9: closed 9-event vocabulary.
  for (const e of w.eventsEmitted) {
    if (!domainEventNames.includes(e)) {
      violations.push(`AD-9: emitted event "${e}" is not in the 9-event vocabulary`);
    }
  }
  for (const e of w.eventsConsumed) {
    if (!domainEventNames.includes(e)) {
      violations.push(`AD-9: consumed event "${e}" is not in the 9-event vocabulary`);
    }
  }

  // AD-15: job vocabulary (AD-8).
  for (const j of w.jobs) {
    if (!jobKinds.includes(j)) {
      violations.push(`AD-15: job "${j}" is not a valid JobKind`);
    }
  }

  // AD-7: single-writer producer check — only emit events whose producer
  // module is in this workflow's flow.
  for (const e of w.eventsEmitted) {
    const producer = EVENT_PRODUCER[e as DomainEventName];
    if (producer !== undefined && !w.modules.includes(producer)) {
      violations.push(
        `AD-7: workflow ${w.id} emits "${e}" but producer module "${producer}" is not in its flow`,
      );
    }
  }

  // AD-2: data tables must be owned by a module in the flow.
  for (const t of w.data) {
    const owner = TABLE_OWNER[t];
    if (owner === undefined) {
      violations.push(`AD-2: table "${t}" has no owner module (unmapped table)`);
    } else if (!w.modules.includes(owner)) {
      violations.push(
        `AD-2: workflow ${w.id} touches "${t}" owned by "${owner}" but that module is not in its flow`,
      );
    }
  }

  // Basic shape: non-empty flow.
  if (w.modules.length === 0) {
    violations.push('AD-2: workflow has no modules');
  }
  if (w.id === '' || w.name === '') {
    violations.push('shape: id/name missing');
  }

  return { id: w.id, ok: violations.length === 0, violations };
}

/** Validate every workflow; returns the full verdicts list. */
export function validateAll(
  workflows: readonly Workflow[],
  domainEventNames: readonly string[],
  jobKinds: readonly string[],
): readonly WorkflowValidation[] {
  return workflows.map((w) => validateWorkflow(w, domainEventNames, jobKinds));
}

/** True iff every workflow validates. */
export function allValid(
  workflows: readonly Workflow[],
  domainEventNames: readonly string[],
  jobKinds: readonly string[],
): boolean {
  return validateAll(workflows, domainEventNames, jobKinds).every((v) => v.ok);
}

/**
 * Count how many of the 23 workflows EMIT a given AD-9 event (producer
 * coverage check — every event the catalog expects to see should have at
 * least one emitting workflow).
 */
export function emissionCountByEvent(
  workflows: readonly Workflow[],
): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const w of workflows) {
    for (const e of w.eventsEmitted) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
  }
  return counts;
}
