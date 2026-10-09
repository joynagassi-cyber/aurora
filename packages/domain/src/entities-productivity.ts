/**
 * Productivity entities (AD-15 SSoT, 01 S4.1).
 * Field-level detail is owned by the Data Contract Pack (wave 0, spine S Deferred) —
 * these shapes are the frozen minimal entities; no re-declaration elsewhere (AD-15).
 */
import type { OrSetValue } from './crdt';

export type TaskStatus = 'todo' | 'in_progress' | 'blocked' | 'done' | 'cancelled';

export interface Task {
  id: string;
  userId: string;
  title: string;
  description?: string;
  status: TaskStatus;
  projectId?: string;
  subjectId?: string;
  goalId?: string;
  dueAt?: string; // ISO 8601
  priority?: number;
  tags: OrSetValue[]; // CRDT OR-Set list (03 S5.3)
  dependencies: OrSetValue[]; // CRDT OR-Set list
  /** CRDT OR-Set list of Progress EvidenceRefs (03 S4.2 mirror rule) */
  evidenceRefs: OrSetValue[];
  /** actual time logged in seconds (ADR S2.2) */
  timeSpentSec?: number;
  recurring?: boolean;
  recurrenceRule?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SubTask {
  id: string;
  taskId: string;
  title: string;
  status: TaskStatus;
  doneAt?: string;
  createdAt: string;
  updatedAt: string;
}

/** Calendar event (01 S4.1) — distinct from the server `events` Event History. */
export interface Event {
  id: string;
  userId: string;
  title: string;
  startAt: string;
  endAt: string;
  location?: string;
  allDay?: boolean;
  recurring?: boolean;
  recurrenceRule?: string;
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export type ProjectView = 'list' | 'kanban' | 'timeline' | 'gantt' | 'calendar';

export interface Project {
  id: string;
  userId: string;
  title: string;
  goalId?: string;
  deadline?: string;
  status: 'planning' | 'active' | 'paused' | 'done' | 'cancelled';
  description?: string;
  tags: OrSetValue[];
  /** CRDT OR-Set: milestone/resource/note refs */
  linkedMilestones: OrSetValue[];
  linkedResources: OrSetValue[];
  viewMode?: ProjectView;
  createdAt: string;
  updatedAt: string;
}

export interface Milestone {
  id: string;
  userId: string;
  projectId: string;
  title: string;
  dueAt?: string;
  reachedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Goal {
  id: string;
  userId: string;
  title: string;
  /** ADR S2.6: short / medium / long term horizon */
  horizon: 'short' | 'medium' | 'long';
  targetDate?: string;
  status: 'active' | 'achieved' | 'abandoned';
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Habit {
  id: string;
  userId: string;
  title: string;
  cadence: 'daily' | 'weekly' | 'custom';
  /** 1..7 for weekly; recurrenceRule for custom */
  weekdays?: number[];
  recurrenceRule?: string;
  /** streak / adherence stats (ADR S2.8) */
  currentStreak: number;
  bestStreak: number;
  createdAt: string;
  updatedAt: string;
}

export interface Routine {
  id: string;
  userId: string;
  title: string;
  /** morning / evening / study / custom */
  kind: 'morning' | 'evening' | 'study' | 'custom';
  steps: OrSetValue[]; // CRDT list of step refs
  attachedHabitIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

/** Countdown event (PRD-CD-01, lot C 2026-10-08) — days until a date
 *  (fête, anniversaire, date marquante). Local-only shape for now (the
 *  mirror is not wired, AD-7) : the `Countdown` entity is declared here
 *  so /countdown can render an honest empty + derived days-left without
 *  inventing a second source of truth. */
export interface Countdown {
  id: string;
  userId: string;
  /** The kind of countdown (style, ref_109). */
  kind: 'fete' | 'anniversaire' | 'date_anniversaire' | 'countdown';
  title: string;
  /** ISO 8601 target date — the days-left is DERIVED (targetDate - today),
   *  never stored (AD-7: one source of truth). */
  targetDate: string;
  /** Optional user image behind the card (ref_109's "photo plein écran"
   *  style). Never a fixed asset — honest: absent = no image. */
  imageUrl?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Note {
  id: string;
  userId: string;
  title: string;
  /** Tiptap document JSON (05/ADR S26 v1.5) — corpus fidelity via SourceRef (AD-11) */
  content: string;
  tags: OrSetValue[];
  sourceRefIds: OrSetValue[]; // CRDT list (03 S5.3)
  /** ADR S2.10: structured note blocks */
  blockTypes?: string[];
  createdAt: string;
  updatedAt: string;
}

export interface Resource {
  id: string;
  userId: string;
  title: string;
  /** course / pdf / document / image / video / link / exercise / report / note (ADR S2.11) */
  kind: 'course' | 'pdf' | 'document' | 'image' | 'video' | 'link' | 'exercise' | 'report' | 'note' | 'audio' | 'other';
  url?: string;
  /** R2 object key (files never in SQLite; AD-7 / 01 S4.6) */
  r2Key?: string;
  subjectId?: string;
  skillId?: string;
  projectId?: string;
  goalId?: string;
  learningSessionId?: string;
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export interface Decision {
  id: string;
  userId: string;
  title: string;
  rationale?: string;
  alternatives?: string[];
  decidedAt: string;
  context?: string;
  linkedTaskIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

/** Focus session (ADR S2.8, 04 S4). */
export interface FocusSession {
  id: string;
  userId: string;
  startedAt: string;
  endedAt?: string;
  /** pomodoro / timer / open */
  mode: 'pomodoro' | 'timer' | 'open';
  plannedDurationSec?: number;
  /** focus app rules engaged (04 S4.1) */
  blockProfile?: string;
  linkedTaskIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

/** Focus app rule (ADR S2.8: block/limit distracting apps where the platform allows). */
export interface FocusAppRule {
  id: string;
  userId: string;
  /** app identifier on device */
  appId: string;
  action: 'block' | 'limit';
  dailyLimitMin?: number;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}

/** Focus notification policy (04 S3.4: suppress Aurora's notifications during a session). */
export interface FocusNotificationPolicy {
  userId: string;
  /** mute OneSignal in-app + remote (RemoteNotificationAdapter.setSubscribed(false)) */
  muteRemote: boolean;
  /** silence non-critical local notifications (LocalNotificationAdapter.reduceForFocus) */
  reduceLocal: boolean;
  /** critical notifications that still get through */
  criticalAllowlist: OrSetValue[];
  updatedAt: string;
}

/** Focus call policy (ADR S2.8: call handling during focus). */
export interface FocusCallPolicy {
  userId: string;
  mode: 'silent' | 'favorites' | 'normal';
  favorites?: string[];
  updatedAt: string;
}

/** Focus session bilan (G-H1: end-of-session review, ADR S2.8). */
export interface FocusSessionBilan {
  id: string;
  userId: string;
  focusSessionId: string;
  completedAt: string;
  /** actual vs planned (ADR S2.10: planned vs real) */
  plannedDurationSec?: number;
  actualDurationSec: number;
  interruptions?: number;
  /** ChartSpec shape for the bilan screen (G-H1 / G-M5) */
  metrics?: Record<string, unknown>;
  notes?: string;
}
