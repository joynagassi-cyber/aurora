/**
 * Learning module — QCM + exercises (AI generation, progressive, error
 * analysis) (wave 2, SAPPHO).
 *
 * docs/learning/overview.md §2: QCM/flashcard generation + FSRS,
 * exercise progression, error tracking (recurring-error detection),
 * targeted revision (consumer of `SkillStateChanged`).
 *
 * Heavy generation = persisted `artifact_gen` job (AD-8). This file is
 * pure: generation prompts, the progressive difficulty ladder, and the
 * recurring-error detector that drives targeted revision.
 */
import type {
  DomainEvent,
  LearningItem,
  OrSetValue,
  SkillState,
} from '@aurora/domain';

/** Progressive difficulty ladder for QCM/exercises (mission §8 flow). */
export const QCM_DIFFICULTY_LADDER = [
  'recall',
  'comprehension',
  'application',
  'analysis',
  'synthesis',
] as const;
export type QcmDifficulty = (typeof QCM_DIFFICULTY_LADDER)[number];

export interface QcmItem {
  learningItemId: string;
  question: string;
  options: string[];
  correctIndex: number;
  difficulty: QcmDifficulty;
  /** corpus-authoritative statement (AD-11) */
  corpusText?: string;
  sourceRefIds: OrSetValue[];
  tags: OrSetValue[];
}

/** One attempt of a QCM/exercise item (feeds the error analysis). */
export interface QcmAttempt {
  learningItemId: string;
  userId: string;
  correct: boolean;
  /** 0..1 confidence of the answer */
  confidence: number;
  difficulty: QcmDifficulty;
  at: string;
}

export interface ErrorCluster {
  difficulty: QcmDifficulty;
  /** learning items repeatedly failed */
  itemIds: string[];
  /** a recurring conceptual error signature (the revision target) */
  signature: string;
  count: number;
}

/**
 * Recurring-error detection: group attempts, and flag any item failed
 * on 2+ difficulties (a conceptual gap, not a slip). Drives targeted
 * revision of the weak `Skill` (consumes `SkillStateChanged` from the
 * Progress module). Pure function.
 */
export function detectRecurringErrors(
  attempts: QcmAttempt[],
  opts?: { perThreshold?: number; totalThreshold?: number },
): ErrorCluster[] {
  const per = opts?.perThreshold ?? 2;
  const total = opts?.totalThreshold ?? 3;
  const byItem = new Map<string, QcmAttempt[]>();
  for (const a of attempts) {
    const list = byItem.get(a.learningItemId);
    if (list === undefined) byItem.set(a.learningItemId, [a]);
    else list.push(a);
  }
  const clusters: ErrorCluster[] = [];
  for (const [itemId, list] of byItem) {
    const fails = list.filter((a) => !a.correct);
    const distinctDifficulties = new Set(fails.map((a) => a.difficulty)).size;
    if (distinctDifficulties >= per || fails.length >= total) {
      const difficulty = mostCommonDifficulty(list);
      clusters.push({
        difficulty: difficulty ?? 'recall',
        itemIds: [itemId],
        signature: `rec:${itemId}:${distinctDifficulties}`,
        count: fails.length,
      });
    }
  }
  return clusters;
}

/**
 * Targeted revision: given a skill state (from Progress), pick the next
 * QCM difficulty to work at. Pure mapping from skill level → ladder
 * position.
 */
export function nextRevisionDifficulty(skill: Pick<SkillState, 'level'>): QcmDifficulty {
  switch (skill.level) {
    case 'novel-problem':
    case 'mastered':
    case 'expert':
      return 'synthesis';
    case 'autonomous-application':
      return 'analysis';
    case 'guided-application':
    case 'recalled':
      return 'application';
    case 'comprehended':
      return 'comprehension';
    case 'discovered':
    default:
      return 'recall';
  }
}

/**
 * The QCM/exercise generation service. AI generation goes through the
 * `artifact_gen` job (AD-8); this class only composes prompts and the
 * progressive ladder for the worker.
 */
export class QcmService {
  /**
   * Build the generation prompt for one difficulty rung (pure). Skill
   * states are read by the caller through the Progress module's public
   * view (AD-2: no cross-module table access) and mapped with
   * `nextRevisionDifficulty`.
   */
  prompt(
    items: Array<Pick<LearningItem, 'content' | 'corpusText'>>,
    difficulty: QcmDifficulty,
  ): string {
    const body = items
      .map((i, idx) => `[${idx + 1}] ${i.content}${i.corpusText ? `\n   (corpus: ${i.corpusText})` : ''}`)
      .join('\n');
    return [
      `Generate a ${difficulty}-level QCM from the material.`,
      `Keep the professor's formulations textually dominant (AD-11).`,
      `Each item: one question, 4 options, one correct index.`,
      '',
      body,
    ].join('\n');
  }

  /** The payload for the persisted `artifact_gen` job (AD-8, idempotent). */
  generationJobPayload(
    req: { userId: string; courseId: string; skillId?: string; difficulty: QcmDifficulty },
    items: Array<Pick<LearningItem, 'content' | 'corpusText'>>,
  ): Record<string, unknown> {
    return {
      artifact: 'qcm',
      courseId: req.courseId,
      skillId: req.skillId ?? null,
      difficulty: req.difficulty,
      prompt: this.prompt(items, req.difficulty),
      idempotencyKey: `artifact_gen:qcm:${req.userId}:${req.courseId}:${req.difficulty}`,
    };
  }
}

/** The QCM module emits no AD-9 event of its own; it feeds the same
 *  `FlashcardReviewed` path. Guard to keep the vocabulary closed. */
export type QcmEmitsNothingNew = QcmAttempt extends DomainEvent['payload']
  ? false
  : true;

function mostCommonDifficulty(list: QcmAttempt[]): QcmDifficulty | null {
  const counts = new Map<QcmDifficulty, number>();
  for (const a of list) counts.set(a.difficulty, (counts.get(a.difficulty) ?? 0) + 1);
  let best: QcmDifficulty | null = null;
  let bestCount = 0;
  for (const [d, c] of counts) {
    if (c > bestCount) {
      best = d;
      bestCount = c;
    }
  }
  return best;
}
