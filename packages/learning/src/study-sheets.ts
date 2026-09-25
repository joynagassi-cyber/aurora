/**
 * Learning module — AI study sheets (wave 2, SAPPHO).
 *
 * 7 canonical sheet structures + corpus-fidelity guard (ADR §17 / AD-11):
 * the professor's formulations stay textually dominant; agent
 * explanations are separated and labelled. A fidelity check runs before
 * export and blocks the sheet if the corpus text was dropped or
 * paraphrased away (docs/learning/overview.md §2, F-05 rule).
 *
 * Heavy generation = persisted `artifact_gen` job (AD-8) — this file
 * holds the pure contracts + the fidelity checker; the AI call goes
 * through `AIPipelinePort` inside the job worker.
 */
import type {
  AIPipelinePort,
  JobDispatcherPort,
  JobQueue,
  LearningItem,
  OrSetValue,
} from '@aurora/domain';

/** The 7 study-sheet structures (05 §4.6; frozen list, ADR §17). */
export const STUDY_SHEET_STRUCTURES = [
  'summary',
  'formulas',
  'definitions',
  'exercises',
  'mind-map',
  'key-points',
  'exam-prep',
] as const;
export type StudySheetStructure = (typeof STUDY_SHEET_STRUCTURES)[number];

/** One generated study sheet (Tiptap JSON content, AD-11 fidelity). */
export interface StudySheet {
  id: string;
  courseId: string;
  userId: string;
  structure: StudySheetStructure;
  /** Tiptap JSON — the corpus-dominant content */
  content: string;
  /** the authoritative corpus formulation kept alongside (AD-11) */
  corpusText: string;
  /** AI-produced explanation, always labelled as such (ADR §17) */
  aiExplanation?: string;
  /** fidelity score 0..1 — must be >= threshold to export */
  fidelity: number;
  /** the fidelity check verdict */
  fidelityOk: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface StudySheetFidelityOptions {
  /** below this the sheet is NOT exportable (default 0.8) */
  threshold?: number;
}

/**
 * Fidelity check (ADR §11 / §17): every key statement of the corpus
 * text must survive in the sheet content. Pure function — runs in the
 * job worker before the sheet is marked exportable. Returns the score
 * and the missing corpus fragments.
 */
export function checkFidelity(
  sheet: Pick<StudySheet, 'content' | 'corpusText'>,
  opts?: StudySheetFidelityOptions,
): { fidelity: number; ok: boolean; missing: string[] } {
  const threshold = opts?.threshold ?? 0.8;
  const corpusFragments = keyFragments(sheet.corpusText);
  if (corpusFragments.length === 0) return { fidelity: 1, ok: true, missing: [] };
  const missing = corpusFragments.filter((frag) => !normalizedContains(sheet.content, frag));
  const fidelity = 1 - missing.length / corpusFragments.length;
  return { fidelity, ok: fidelity >= threshold, missing };
}

/**
 * Generate a study sheet: pulls the course items through the AI
 * pipeline, runs the fidelity check, enqueues the heavy artifact job.
 * The module owns the LearningItem it creates (AD-7 single-writer).
 */
export class StudySheetService {
  readonly ai: AIPipelinePort;
  readonly jobs: JobDispatcherPort;
  readonly now: () => string;
  constructor(
    ai: AIPipelinePort,
    jobs: JobDispatcherPort,
    now: () => string = () => new Date().toISOString(),
  ) {
    this.ai = ai;
    this.jobs = jobs;
    this.now = now;
  }

  async generate(
    req: {
      userId: string;
      courseId: string;
      structure: StudySheetStructure;
      items: Array<Pick<LearningItem, 'id' | 'content' | 'corpusText' | 'sourceRefIds'>>;
    },
  ): Promise<{ sheet: StudySheet; jobId: string; jobStatus: JobQueue['status'] }> {
    const prompt = sheetPrompt(req.structure, req.items);
    const envelope = await this.ai.generate(prompt, {
      taskProfile: 'study_sheet',
      structure: req.structure,
      courseId: req.courseId,
    });
    const content = envelope.data;
    const corpusText = req.items.map((i) => i.corpusText ?? i.content).join('\n');
    const fidelity = checkFidelity({ content, corpusText });
    const sheet: StudySheet = {
      id: `ss-${req.courseId}-${req.structure}`,
      courseId: req.courseId,
      userId: req.userId,
      structure: req.structure,
      content,
      corpusText,
      aiExplanation: envelope.fallbackUsed ? envelope.data : undefined,
      fidelity: fidelity.fidelity,
      fidelityOk: fidelity.ok,
      createdAt: this.now(),
      updatedAt: this.now(),
    };
    const job = await this.jobs.dispatch({
      jobKind: 'artifact_gen',
      userId: req.userId,
      payload: {
        artifact: 'study_sheet',
        structure: req.structure,
        courseId: req.courseId,
        sheetId: sheet.id,
        fidelityOk: sheet.fidelityOk,
        refs: req.items.map((i) => i.sourceRefIds as OrSetValue[]),
      },
      idempotencyKey: `artifact_gen:study_sheet:${req.courseId}:${req.structure}`,
    });
    return { sheet, jobId: job.jobId, jobStatus: job.status };
  }
}

/** Build the structured prompt for one sheet structure (pure). */
export function sheetPrompt(
  structure: StudySheetStructure,
  items: Array<Pick<LearningItem, 'id' | 'content' | 'corpusText'>>,
): string {
  const body = items
    .map((i, idx) => `[${idx + 1}] ${i.content}${i.corpusText ? `\n   (corpus: ${i.corpusText})` : ''}`)
    .join('\n');
  return [
    `Structure the following course material as a ${structure} study sheet.`,
    `Keep the professor's formulations textually dominant (AD-11).`,
    `Label any added explanation as AI-generated.`,
    '',
    body,
  ].join('\n');
}

// ---- helpers (pure) ----

function normalizedContains(haystack: string, needle: string): boolean {
  return normalize(haystack).includes(normalize(needle));
}

function normalize(s: string): string {
  return s.toLowerCase().replace(/\s+/g, ' ').trim();
}

/** Key fragments = sentences containing a formula/definition marker or
 *  any sentence of reasonable length (heuristic for the fidelity guard). */
function keyFragments(corpus: string): string[] {
  return corpus
    .split(/(?<=[.!?。])\s+|\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length >= 12);
}
