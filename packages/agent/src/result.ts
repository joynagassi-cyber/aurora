/**
 * Component 12 — Result Normalizer (kernel.md S12).
 *
 * Every model answer → `AIResponseEnvelope` (provider / model /
 * attempt / reason / expectedQuality / fallbackUsed / traceId —
 * 01 S3.1, AD-5 traceability: no untraced fallback).
 *
 * The normalizer is pure: it takes a raw provider response + the
 * router's `ProviderModel` selection and produces the canonical
 * envelope. The kernel attaches it to the `AgentRunState` so the
 * device can surface "which model served this" without leaking
 * keys or provider internals (AD-3).
 */
import type { AIResponseEnvelope } from '@aurora/domain';
import type { ProviderModel } from './router.ts';

/**
 * A raw response from the provider adapter (before normalization).
 * The adapter layer (Vercel SDK `LanguageModel`) returns the text;
 * the normalizer wraps it in the traceable envelope.
 */
export interface RawModelResponse {
  data: unknown;
  /** the provider that actually served the call (after any fallback) */
  provider: string;
  /** the model that actually served the call */
  model: string;
  /** which attempt (1-based; > 1 means a fallback happened) */
  attempt: number;
  /** `primary` | `fallback` | `last_resort` */
  reason: ProviderModel['reason'];
  /** whether the quality was degraded (verification failure, fallback, …) */
  expectedQuality: 'full' | 'degraded';
  /** the server-side trace id (AD-5) */
  traceId: string;
  /**
   * Optional device-preference trace (thinking level, research mode,
   * agent mode — the `TaskProfile` fields the device set). Carried in
   * the envelope for observability (AD-16d), never affects the AD-5
   * fallback chain.
   */
  meta?: Record<string, unknown>;
}

/**
 * Normalize a raw provider response into the canonical
 * `AIResponseEnvelope<T>`. Pure function — no side effects.
 */
export function normalizeResult<T>(raw: RawModelResponse): AIResponseEnvelope<T> {
  return {
    provider: raw.provider,
    model: raw.model,
    attempt: raw.attempt,
    reason: raw.reason,
    expectedQuality: raw.expectedQuality,
    fallbackUsed: raw.attempt > 1 || raw.reason !== 'primary',
    traceId: raw.traceId,
    data: raw.data as T,
  };
}

/** The normalized result shape the kernel returns to the caller. */
export interface NormalizedResult<T> {
  /** the envelope (AD-5 traceability) */
  envelope: AIResponseEnvelope<T>;
  /** whether a fallback was used */
  fallbackUsed: boolean;
  /** a degraded-quality notice (the user is informed, kernel S8) */
  degraded: boolean;
}

/**
 * Build the full normalized result (envelope + derived flags) from a
 * raw response. `degraded` = quality is `degraded` OR a fallback was
 * used — either way the user sees the notice, it is never silent.
 */
export function buildNormalizedResult<T>(raw: RawModelResponse): NormalizedResult<T> {
  const envelope = normalizeResult<T>(raw);
  const degraded = envelope.expectedQuality === 'degraded' || envelope.fallbackUsed;
  return { envelope, fallbackUsed: envelope.fallbackUsed, degraded };
}
