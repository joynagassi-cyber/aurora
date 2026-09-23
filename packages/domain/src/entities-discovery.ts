/**
 * Discovery entities (AD-15 SSoT, 01 S4.5, ADR S13).
 * Discovery = active, usefulness-driven discovery (not passive veille):
 * find what matters now, explain why it matters, tie it to the learner's
 * path, progressively broaden capability.
 */
import type { OrSetValue } from './crdt';

/**
 * A DiscoveryItem — a durable, reusable discovery object (ADR S13.8,
 * "fiche de découverte"). Not a raw link; it answers "why now?" and
 * connects to the learner's existing knowledge.
 */
export interface DiscoveryItem {
  id: string;
  userId: string;
  /** title + starting question (ADR S13.8) */
  title: string;
  question?: string;
  /** why Aurora recommends this discovery now (ADR S13.8) */
  whyNow: string;
  /** factual summary (ADR S13.8) */
  summary: string;
  /** the typed sources (academic / scientific / technical / professional /
   *  technological / sector news / regulatory / local-international).
   *  Distinguish scientific discovery vs professional practice vs
   *  commercial innovation vs media trend vs uncertain info (ADR S13.2). */
  sources: OrSetValue[]; // CRDT list of DiscoverySource ids
  /** what this confirms or contradicts in current knowledge (ADR S13.8) */
  confirmsOrContradicts?: string;
  /** link to courses followed (ADR S13.8) */
  relatedCourseIds: OrSetValue[];
  /** link to the target professional domain (ADR S13.8) */
  domainRef?: string;
  /** affected competencies (ADR S13.8) */
  relatedSkillIds: OrSetValue[];
  /** new concepts to learn (ADR S13.8) */
  newConcepts?: string[];
  /** open questions (ADR S13.8) */
  openQuestions?: string[];
  /** recommended actions: read / experiment / practice / deepen / follow /
   *  ignore for now (ADR S13.8) */
  recommendedActions?: Array<'read' | 'experiment' | 'practice' | 'deepen' | 'follow' | 'ignore-for-now'>;
  /** links to the semantic tree and affected goals (ADR S13.8) */
  semanticNodeIds: OrSetValue[];
  relatedGoalIds: OrSetValue[];
  /** when the discovery was created (drives DiscoveryItemCreated) */
  createdAt: string;
  updatedAt: string;
}

/** A typed source for a discovery (ADR S13.2 multi-source requirement). */
export interface DiscoverySource {
  id: string;
  userId: string;
  discoveryItemId: string;
  /** source family (ADR S13.2) */
  kind:
    | 'academic'
    | 'scientific'
    | 'technical'
    | 'professional'
    | 'technological'
    | 'sector-news'
    | 'regulatory'
    | 'local-regional'
    | 'international'
    | 'other';
  url?: string;
  title?: string;
  /** provenance / credibility marking (ADR S13.2: "uncertain" when degraded) */
  credibility?: 'documented' | 'frequent' | 'interpretation' | 'uncertain';
  createdAt: string;
  updatedAt: string;
}

/**
 * A DiscoveryScenario — a future-horizon scenario (ADR S13.7). Strictly
 * separates: established facts, documented trends, future scenarios.
 * For 2030–2050: trajectories, not certainties.
 */
export interface DiscoveryScenario {
  id: string;
  userId: string;
  /** the horizon this scenario targets (ADR S13.7: 2030 / 2040 / 2050) */
  horizon: 'now' | '2030' | '2040' | '2050';
  /** which knowledge level this scenario describes (ADR S13.7):
   *  state / trend / factor / scenario / competency-gain /
   *  competency-loss / uncertainty / source */
  level:
    | 'current-state'
    | 'documented-trend'
    | 'accelerating-factor'
    | 'slowing-factor'
    | 'future-scenario'
    | 'competency-rising'
    | 'competency-falling'
    | 'uncertainty'
    | 'source';
  title: string;
  description: string;
  /** the uncertainties / hypotheses of the scenario (ADR S13.7) */
  hypotheses?: string[];
  /** sources used for the projection (ADR S13.7) */
  sourceIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}
