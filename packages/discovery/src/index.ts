/**
 * @aurora/discovery — Discovery module public surface (wave 2, ORION).
 *
 * Pure domain logic: multi-source discovery sheets (ADR S13.8), the
 * `ResearchProvider` port (AD-1, optional → degraded `uncertain`
 * results), data-driven Benin filtering (discovery-gap-pipeline S5),
 * gap detection (S1), and the `DiscoveryItemCreated` event builder
 * (AD-9). No vendor SDKs (AD-1), no DOM, no cross-module table writes
 * (AD-2/AD-7: single-writer on `discovery_items`).
 */

export * from './research-provider.ts';
export * from './filtering.ts';
export * from './discovery.ts';
export * from './gaps.ts';
export * from './events.ts';
export * from './jobs.ts';
