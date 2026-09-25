/**
 * Infographic multi-resource engine (docs/artifacts/infographic-multi-resource.md).
 *
 * The agent is the ART DIRECTOR: it structures the infographic
 * (layout / sections / data points) and ORDERS external resources via
 * two tool contracts (the implementations live in packages/agent,
 * wave 3 — AD-12). This module owns:
 *
 *   1. `InfographicSpec` — the AD-10 renderer contract (05 S3.6 DEF:
 *      spec validation -> SVG). The AntV renderer in @aurora/ui draws
 *      the hybrid SVG (layout + text + `<image>` elements).
 *   2. Resource ordering — `SearchEnginePort` (Exa/Tavily) +
 *      `GenAIImagePort` (Agnes Image 2.5 Flash, fal.ai fallback).
 *      Vendor isolation AD-1: the ports are here; the ADAPTERS live in
 *      @aurora/engineering-adapters / @aurora/integrations.
 *   3. Placeholder degradation (AD-1): provider absent -> styled
 *      placeholder, never a broken image.
 *   4. Budget gate (AD-5 AIBudgetManager): max 2 image generations
 *      per infographic.
 */
import type { AIResponseEnvelope } from '@aurora/domain';

// ---- AD-10 contract: InfographicSpec (05 S3.6) ----

export type InfographicLayoutType = 'grid' | 'flow' | 'tree';

export interface InfographicSection {
  id: string;
  label?: string;
  /** 'generated' = GenAI illustration, 'searched' = real photo, 'none' */
  imageSlot?: 'generated' | 'searched' | 'none';
  /** a resolved URL (R2 presigned) or a `{{tool_N_result_M}}` placeholder */
  imageRef?: string;
  caption?: string;
  text?: string;
  /** KaTeX formula rendered inside the section */
  formula?: string;
}

export interface InfographicSpec {
  type: InfographicLayoutType;
  columns?: number;
  gap?: number;
  sections: InfographicSection[];
  /** theme accent tokens (AD-17: resolveToken at render time) */
  themeAccentTokens?: string[];
}

/** Validation: a spec must have at least one section, and image slots
 *  must reference a resolvable ref (resolved URL or placeholder). */
export function validateInfographicSpec(
  spec: InfographicSpec,
): { ok: boolean; errors: string[] } {
  const errors: string[] = [];
  if (spec.sections.length === 0) errors.push('empty_spec: at least one section');
  for (const s of spec.sections) {
    if (s.imageSlot && s.imageSlot !== 'none' && !s.imageRef) {
      errors.push(`section ${s.id}: imageSlot=${s.imageSlot} but no imageRef`);
    }
  }
  return { ok: errors.length === 0, errors };
}

// ---- Tool 1: search engine (real images, Exa/Tavily) ----

export interface SearchedImage {
  imageUrl: string;
  source: string;
  license: string;
}

/** Port for the real-image search tool (ADR S8 ResearchProvider;
 *  Exa/Tavily adapters in @aurora/integrations — AD-1). */
export interface SearchEnginePort {
  searchImages(
    query: string,
    opts?: { limit?: number; imageSize?: string; aspectRatio?: string },
  ): Promise<SearchedImage[]>;
}

/** AD-1 graceful degradation: provider absent -> styled placeholder. */
export function placeholderImage(kind: 'photo' | 'illustration'): SearchedImage {
  return {
    imageUrl: 'placeholder_url',
    source: kind === 'photo' ? 'no-search-provider' : 'no-image-provider',
    license: 'unspecified',
  };
}

// ---- Tool 2: GenAI image engine (Agnes Image primary, fal.ai fallback) ----

/** Port for the GenAI illustration tool (Agnes Image 2.5 Flash primary,
 *  fal.ai flux/schnell fallback — docs/ai/providers/agnes-image.md). */
export interface GenAIImagePort {
  generate(req: {
    prompt: string;
    style?: 'flat' | 'vector' | 'photo-realistic' | 'sketch';
    size?: '256x256' | '512x512' | '1024x1024';
  }): Promise<AIResponseEnvelope<{ imageUrl: string; model: string }>>;
}

/** The Aurora charte graphique (infographic-multi-resource doc):
 *  flat vector, <=3 colors, white/transparent bg, NO text in image. */
export function buildIllustrationPrompt(
  subject: string,
  style: 'flat' | 'vector' | 'photo-realistic' | 'sketch' = 'flat',
): string {
  return [
    subject,
    style === 'photo-realistic'
      ? 'clean photography, soft studio lighting'
      : 'minimalist vector illustration, flat design style, clean lines, clean white background',
    'no text in image',
    'centered composition, high detail',
  ].join(', ');
}

// ---- Budget gate (AD-5 AIBudgetManager, per-infographic caps) ----

export interface ImageBudget {
  /** max image generations per infographic */
  perInfographic: number;
  /** max image generations per day per user */
  perDay: number;
  /** generations already used today */
  usedToday: number;
  /** generations used in THIS infographic build */
  usedThisBuild: number;
}

export const DEFAULT_IMAGE_BUDGET: ImageBudget = {
  perInfographic: 2,
  perDay: 20,
  usedToday: 0,
  usedThisBuild: 0,
};

/** Is a new generation allowed under the budget? */
export function budgetAllows(b: ImageBudget): boolean {
  return (
    b.usedThisBuild < b.perInfographic &&
    b.usedToday + b.usedThisBuild < b.perDay
  );
}

// ---- Result normalization: {{tool_N_result_M}} -> concrete URL ----

/** Resolve `{{tool_N_result_M}}` placeholders in a spec using captured
 *  tool results (the agent's onStepFinish hooks feed `results`). */
export function resolveImageRefs(
  spec: InfographicSpec,
  results: Record<string, string | undefined>,
): InfographicSpec {
  const resolved: InfographicSection[] = spec.sections.map((s) => {
    if (!s.imageRef || !s.imageRef.startsWith('{{')) return s;
    const key = s.imageRef.replace(/\{\{|\}\}/g, '');
    const url = results[key];
    return {
      ...s,
      imageRef:
        url && url !== 'placeholder_url'
          ? url
          : s.imageSlot === 'generated'
            ? placeholderImage('illustration').imageUrl
            : placeholderImage('photo').imageUrl,
    };
  });
  return { ...spec, sections: resolved };
}
