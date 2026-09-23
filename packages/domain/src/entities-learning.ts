/**
 * Learning entities (AD-15 SSoT, 01 S4.2).
 * FSRS runs server-side (job); the device mirrors `FsrsState`.
 */
import type { OrSetValue } from './crdt';

export interface Course {
  id: string;
  userId: string;
  title: string;
  subjectId?: string;
  /** semester / year context */
  period?: string;
  /** import source (manual, pdf, web…) — drives `CourseImported` */
  source?: string;
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export interface Subject {
  id: string;
  userId: string;
  name: string;
  /** academic domain (e.g. "civil engineering", "math") */
  domain?: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

/** A skill tracked by the Progress module (01 S4.2: `skills` / `skill_definitions`). */
export interface Skill {
  id: string;
  userId: string;
  name: string;
  subjectId?: string;
  /** discovery → comprehension → recall → guided-app → autonomous-app →
   *  new-problem → mastery → expertise (ADR S18.2) */
  level:
    | 'discovered'
    | 'comprehended'
    | 'recalled'
    | 'guided-application'
    | 'autonomous-application'
    | 'novel-problem'
    | 'mastered'
    | 'expert';
  /** 0..1 */
  confidence?: number;
  updatedAt: string;
}

export interface LearningSession {
  id: string;
  userId: string;
  startedAt: string;
  endedAt?: string;
  subjectId?: string;
  courseIds: OrSetValue[];
  skillIds: OrSetValue[];
  /** what happened in the session (review, practice, explanation…) */
  kind: 'review' | 'practice' | 'study' | 'explanation' | 'quiz';
  durationSec?: number;
  createdAt: string;
  updatedAt: string;
}

/** A review item: QCM / flashcard / open exercise (01 S4.2 `reviews`). */
export interface Review {
  id: string;
  userId: string;
  /** the learning item being reviewed */
  learningItemId: string;
  /** 0..5 typical FSRS rating scale */
  rating?: number;
  reviewedAt?: string;
  /** true when the user self-reported an error (feeds Progress) */
  wasCorrect?: boolean;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

/** QCM / flashcard / exercise / open-problem content (01 S4.2 `learning_items`). */
export interface LearningItem {
  id: string;
  userId: string;
  kind: 'qcm' | 'flashcard' | 'exercise' | 'open-problem' | 'recall';
  subjectId?: string;
  courseId?: string;
  skillId?: string;
  /** question / prompt / content (Tiptap JSON or plain text) */
  content: string;
  /** expected answer (QCM options, flashcard back…) */
  answer?: string;
  /** corpus fidelity: the authoritative formulation (AD-11) */
  corpusText?: string;
  /** provenance (ADR S17, AD-11) */
  sourceRefIds: OrSetValue[];
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

/**
 * FSRS state mirrored on device (server owns the algorithm, 01 S4.2 /
 * data-event-job-catalog S1). due/stability/difficulty are the standard
 * FSRS v4/v5 internal state.
 */
export interface FsrsState {
  /** learning item the card belongs to */
  learningItemId: string;
  userId: string;
  /** ms epoch */
  due: number;
  /** 0..1 (stability, in days internally; normalised here) */
  stability: number;
  /** 0..1 */
  difficulty: number;
  /** retrievability at `now` (computed at read, 0..1) */
  retrievability?: number;
  /** number of successful reviews */
  lapses: number;
  /** last review rating, if any */
  lastRating?: number;
  /** ISO 8601 */
  lastReviewedAt?: string;
  updatedAt: string;
}
