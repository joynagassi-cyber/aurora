/**
 * Component 13 — Memory (Expert Skills) (kernel.md S12 / ADR S14).
 *
 * `expert_skills` (server-only table, 03 S4.2): trigger / goal /
 * procedure / constraints / examples / counter-examples / confidence /
 * provenance / validation date / obsolescence conditions.
 * Error loop (ADR S14.3) + success loop (ADR S14.4) + guardrails
 * (ADR S14.5: no one-shot promotion; provenance kept; user can
 * correct / disable / delete; contradiction detection; periodic
 * review via confidence decay).
 *
 * This component owns the skill CRUD + guardrails. The 4 extensions
 * (contrastive pairs, confidence decay, hypotheses, cognitive-drift
 * firewall) live in `expert-skills.ts` (wave 3 task 4) and plug in
 * through the same seams.
 */
import type { ExpertSkill } from '@aurora/domain';

export interface SkillDraft {
  userId: string;
  key: string;
  trigger: string;
  objective: string;
  procedure: string[];
  constraints?: string[];
  successExamples?: string[];
  failures?: string[];
  /** 0..1 — a draft from a single observation starts LOW */
  confidence: number;
  source: ExpertSkill['source'];
  provenance: {
    evidenceIds: string[];
    corrections?: string[];
    sessions?: string[];
  };
  obsolescenceConditions?: string[];
}

export interface MemoryDeps {
  /** persist a new / updated skill row (server-only, AD-3) */
  upsert(skill: ExpertSkill): Promise<void>;
  /** load a user's skills (server-side, no local mirror) */
  load(userId: string): Promise<ExpertSkill[]>;
  /** archive / disable / delete on user request (ADR S14.5) */
  archive(userId: string, skillId: string): Promise<void>;
  delete(userId: string, skillId: string): Promise<void>;
  /** id generator */
  ulid(): string;
  /** clock */
  now(): string;
}

/**
 * `MemoryEngine` — the error loop + success loop + guardrails.
 *
 * ADR S14.5 guardrail enforced here: a one-shot observation NEVER
 * promotes a skill to `validated` (one success is NOT a skill).
 * The skill starts as `candidate`; the 4-extension contrastive-pair
 * mechanism (expert-skills.ts) is what moves it to `validated`
 * after 2+ paired sessions.
 */
export class MemoryEngine {
  private deps: MemoryDeps;

  constructor(deps: MemoryDeps) {
    this.deps = deps;
  }

  /**
   * Crystallize a draft into a skill row. A single observation lands
   * as `candidate` (confidence capped at 0.5 — one-shot rule, ADR
   * S14.5 "no one-shot hypothesis promoted to durable truth").
   */
  async crystallize(draft: SkillDraft): Promise<ExpertSkill> {
    const t = this.deps.now();
    const skill: ExpertSkill = {
      id: this.deps.ulid(),
      userId: draft.userId,
      key: draft.key,
      trigger: draft.trigger,
      objective: draft.objective,
      procedure: draft.procedure,
      constraints: draft.constraints,
      successExamples: draft.successExamples,
      failures: draft.failures,
      // one-shot cap: a fresh skill from a single signal can't exceed 0.5
      confidence: Math.min(draft.confidence, 0.5),
      source: draft.source,
      status: 'candidate',
      obsolescenceConditions: draft.obsolescenceConditions,
      createdAt: t,
      updatedAt: t,
    };
    await this.deps.upsert(skill);
    return skill;
  }

  /**
   * Promote a candidate → validated once the extensions have
   * confirmed it (2+ contrastive pairs, confidence > 0.6 — the rule
   * in expert-skills S2.1). The engine checks the guardrail before
   * promoting: provenance must be non-empty (ADR S14.5 "provenance
   * always kept").
   */
  async promote(skill: ExpertSkill, confidence: number): Promise<ExpertSkill> {
    if (confidence <= 0.6) {
      // below the 2-pair threshold — stay candidate
      return skill;
    }
    const t = this.deps.now();
    const next: ExpertSkill = { ...skill, status: 'validated', confidence, validatedAt: t, updatedAt: t };
    await this.deps.upsert(next);
    return next;
  }

  /**
   * Contradiction detection (ADR S14.5): two active skills cannot
   * both be "true". Flags a candidate that contradicts a validated
   * skill for the same trigger.
   */
  async detectContradiction(userId: string, candidate: ExpertSkill): Promise<ExpertSkill[]> {
    const all = await this.deps.load(userId);
    const contradictions = all.filter((s) => s.status === 'validated' && s.trigger === candidate.trigger && s.objective !== candidate.objective);
    return contradictions;
  }

  /** User authority: correct / disable / delete (ADR S14.5). */
  archive(userId: string, skillId: string): Promise<void> {
    return this.deps.archive(userId, skillId);
  }
  remove(userId: string, skillId: string): Promise<void> {
    return this.deps.delete(userId, skillId);
  }

  /** Load the user's active skills (for the Expert Skills context form). */
  active(userId: string): Promise<ExpertSkill[]> {
    return this.deps.load(userId).then((all) => all.filter((s) => s.status === 'validated' || s.status === 'candidate'));
  }
}
