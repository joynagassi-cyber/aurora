import type { Workflow } from './types.ts';
export const w7: Workflow = {
  id: 'W7',
  name: 'Discovery → Learning',
  trigger: 'DiscoveryItemCreated event, or user opens a discovery sheet',
  actors: ['Discovery module', 'Learning module', 'Agent'],
  modules: ['Discovery', 'Learning', 'Knowledge', 'Progress'],
  capabilities: ['discovery.sheet.open', 'learning.activity.create'],
  data: ['discovery_items'],
  eventsEmitted: [],
  eventsConsumed: ['DiscoveryItemCreated'],
  jobs: ['research'],
  ui: [
    { from: 'discovery-feed', to: 'discovery-sheet' },
    { from: 'discovery-sheet', to: 'learning-activity' },
  ],
  agent: {
    role: 'Researcher',
    action:
      'explains the discovery and links it to existing knowledge (ADR §13.9 loop)',
  },
  permissions: [],
  failures: ['ResearchProvider absent -> items marked uncertain (01 §6)'],
  recovery: 'items persisted; research jobs retry idempotently.',
};
