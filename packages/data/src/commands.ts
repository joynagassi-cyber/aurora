// =============================================================================
// DomainCommand — partial-intent write contracts (03 S3.1 / AD-7 / F-03).
//
// "cmd est TOUJOURS un DomainCommand (partial intent SSoT), JAMAIS une
// entite complete" — a full-entity PUT is a single-writer violation: the
// owning module is the only writer of its rows (03 S4.2 / F-03), and the
// kernel never writes a table, it emits commands/events (F-09).
//
// Commands are PARTIAL: they carry `op` + `id` + a `patch` of the fields
// the caller actually changed. The owning module (Productivity for `Task`,
// Learning for `Review`, …) owns the resulting row in the local store, and
// the upsync queue carries the partial upstream (03 S5.1) — the server
// remains the authority and rewrites `updated_at` canonically (03 S4.2
// rule 3).
//
// The union is per-entity (AD-15 owner mapping, 03 S4.2). Only the entities
// that have a local mirror are commandable from the device; server-only
// entities (expert_skills, events, progress_evidences/trends, …) have no
// local command path — they flow via the module owner on the server.
// =============================================================================

import type { OrSetValue } from '@aurora/domain';

/** Common command envelope (03 S3.1). */
export interface CommandBase {
  /** partial intent, per entity — "task.update", "goal.update", … */
  op: string;
  /** target row id (uuid string) */
  id: string;
  /** the user the command acts for — RLS-scoped, must equal the signed-in
   *  user or the store refuses it (01 S2.2 isolation survives to device). */
  userId: string;
}

/** `TaskUpdateCommand { op:'task.update', id, patch }` (03 S3.1 example). */
export interface TaskUpdateCommand extends CommandBase {
  op: 'task.update';
  patch: {
    title?: string;
    description?: string;
    status?: string;
    priority?: number;
    importance?: number;
    dueAt?: string | null;
    projectId?: string | null;
    goalId?: string | null;
    /** CRDT OR-Set list fields merge losslessly (03 S5.3). */
    tags?: OrSetValue[];
    dependencies?: OrSetValue[];
    evidenceRefs?: OrSetValue[];
  };
}

export interface TaskCreateCommand {
  op: 'task.create';
  /** target row id (uuid string); caller may pin it (recurrences, materialized rows) */
  id: string;
  /** the user the command acts for — RLS-scoped */
  userId: string;
  patch: TaskUpdateCommand['patch'] & { title: string };
}

export interface TaskDeleteCommand extends CommandBase {
  op: 'task.delete';
}

export interface GoalUpdateCommand extends CommandBase {
  op: 'goal.update';
  patch: {
    title?: string;
    description?: string;
    status?: string;
    horizon?: string;
    targetDate?: string | null;
  };
}

export interface NoteUpdateCommand extends CommandBase {
  op: 'note.update';
  patch: {
    title?: string;
    body?: string;
    kind?: string;
  };
}

export interface ResourceUpdateCommand extends CommandBase {
  op: 'resource.update';
  patch: {
    title?: string;
    r2Key?: string | null;
  };
}

export interface FocusSessionStartCommand extends CommandBase {
  op: 'focusSession.start';
  patch: {
    taskId?: string | null;
    plannedMinutes?: number;
  };
}

export interface FocusSessionEndCommand extends CommandBase {
  op: 'focusSession.end';
  patch: {
    actualMinutes?: number;
    status?: string;
  };
}

export interface ReviewRatedCommand extends CommandBase {
  op: 'review.rate';
  patch: {
    rating: number;
  };
}

export interface CourseUpdateCommand extends CommandBase {
  op: 'course.update';
  patch: {
    title?: string;
    description?: string;
    status?: string;
  };
}

export interface DiscoveryItemUpdateCommand extends CommandBase {
  op: 'discoveryItem.update';
  patch: {
    title?: string;
    question?: string;
    whyNow?: string;
    status?: string;
  };
}

export interface AutomationUpdateCommand extends CommandBase {
  op: 'automation.update';
  patch: {
    name?: string;
    enabled?: boolean;
  };
}

export interface UserContextUpdateCommand extends CommandBase {
  op: 'userContext.update';
  patch: {
    theme?: string;
    themeStyle?: string;
    coachingPrefs?: Record<string, unknown>;
  };
}

/**
 * The device-side command vocabulary. Extending it = additive change to the
 * data-layer contract (a new entity owner or a new op); it is NOT part of
 * the AD-9 event vocabulary (AD-9/F-04: this layer introduces no new event).
 */
export type DomainCommand =
  | TaskUpdateCommand
  | TaskCreateCommand
  | TaskDeleteCommand
  | GoalUpdateCommand
  | NoteUpdateCommand
  | ResourceUpdateCommand
  | FocusSessionStartCommand
  | FocusSessionEndCommand
  | ReviewRatedCommand
  | CourseUpdateCommand
  | DiscoveryItemUpdateCommand
  | AutomationUpdateCommand
  | UserContextUpdateCommand;

/**
 * `ownerModule` routing table (03 S4.2 single-writer mapping, frozen).
 * The store uses this to reject a command aimed at the wrong owner — a
 * second writer touching an entity's rows is a blocking review finding
 * (03 S7, R2).
 */
export const OWNER_MODULE_BY_ENTITY: Readonly<Record<string, string>> = {
  tasks: 'productivity',
  projects: 'productivity',
  goals: 'productivity',
  milestones: 'productivity',
  habits: 'productivity',
  routines: 'productivity',
  focus_sessions: 'productivity',
  decisions: 'productivity',
  calendar_events: 'productivity',
  notes: 'knowledge',
  resources: 'knowledge',
  semantic_nodes: 'knowledge',
  semantic_edges: 'knowledge',
  semantic_bridges: 'knowledge',
  node_state: 'knowledge',
  source_refs: 'knowledge',
  courses: 'learning',
  subjects: 'learning',
  skills: 'learning',
  learning_sessions: 'learning',
  reviews: 'learning',
  skill_states: 'progress',
  progress_snapshots: 'progress',
  discovery_items: 'discovery',
  gaps: 'discovery',
  artifacts: 'artifact',
  automations: 'integrations',
  user_context: 'identity',
};

/** Entity table name a command op targets (lower snake_case mirror). */
export function commandEntity(op: string): string | undefined {
  // op = "<entity>.<verb>" where entity is the domain camelCase singular
  // ("task.update", "focusSession.start", …). The mirror tables are
  // snake_case PLURAL (03 S4.1/AD-15): map the singular domain name to its
  // mirror table, including the Focus-session special cases.
  const entity = op.split('.')[0];
  if (!entity) return undefined;
  const lower = entity.toLowerCase();
  switch (lower) {
    case 'task': return 'tasks';
    case 'project': return 'projects';
    case 'goal': return 'goals';
    case 'milestone': return 'milestones';
    case 'habit': return 'habits';
    case 'routine': return 'routines';
    case 'focussession': return 'focus_sessions';
    case 'decision': return 'decisions';
    case 'calendarevent': return 'calendar_events';
    case 'note': return 'notes';
    case 'resource': return 'resources';
    case 'semanticnode': return 'semantic_nodes';
    case 'semanticedge': return 'semantic_edges';
    case 'semanticbridge': return 'semantic_bridges';
    case 'nodestate': return 'node_state';
    case 'sourceref': return 'source_refs';
    case 'course': return 'courses';
    case 'subject': return 'subjects';
    case 'skill': return 'skills';
    case 'learningsession': return 'learning_sessions';
    case 'review': return 'reviews';
    case 'skillstate': return 'skill_states';
    case 'progresssnapshot': return 'progress_snapshots';
    case 'discoveryitem': return 'discovery_items';
    case 'gap': return 'gaps';
    case 'artifact': return 'artifacts';
    case 'automation': return 'automations';
    case 'usercontext': return 'user_context';
    default: {
      // fall back: snake_case + naive pluralization for additive entities
      const snake = lower.replace(/([A-Z])/g, '_$1').toLowerCase();
      return snake.endsWith('s') ? snake : `${snake}s`;
    }
  }
}
