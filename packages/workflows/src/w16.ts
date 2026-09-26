import type { Workflow } from './types.ts';
export const w16: Workflow = {
  id: 'W16',
  name: 'Research → Artifact',
  trigger: 'user request ("find me…") or Agent discovery',
  actors: ['Agent (Researcher)', 'Discovery module', 'Artifact module'],
  modules: ['Discovery', 'Artifact', 'Knowledge'],
  capabilities: ['discovery.research', 'artifact.generate'],
  data: ['discovery_items', 'artifacts'],
  eventsEmitted: ['DiscoveryItemCreated', 'ArtifactGenerated'],
  eventsConsumed: [],
  jobs: ['research', 'artifact_gen'],
  ui: [
    { from: 'discovery-feed', to: 'discovery-sheet' },
    { from: 'discovery-sheet', to: 'artifact-hub' },
  ],
  agent: {
    role: 'Researcher',
    action:
      'cross-checks sources, marks uncertainty, never presents a projection as fact (ADR §13.7)',
  },
  permissions: ['provider keys server-only (AD-3)'],
  failures: ['provider down -> fallback / uncertain marking (01 §6)'],
  recovery: 'jobs retry idempotently; items persist.',
};
