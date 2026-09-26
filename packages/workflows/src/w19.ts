import type { Workflow } from './types.ts';
export const w19: Workflow = {
  id: 'W19',
  name: 'Knowledge → Semantic Tree',
  trigger: 'CourseImported / search results / DiscoveryItemCreated',
  actors: ['Knowledge module'],
  modules: ['Knowledge'],
  capabilities: ['knowledge.ingest'],
  data: ['semantic_nodes', 'semantic_edges', 'node_state', 'semantic_tree_version'],
  eventsEmitted: [],
  eventsConsumed: ['CourseImported', 'DiscoveryItemCreated', 'ProgressEvidenceCreated', 'SkillStateChanged'],
  jobs: ['course_import'],
  ui: [{ from: 'tree', to: 'tree' }],
  agent: {
    role: 'Tutor',
    action: 'the tree is a Semantic Context form (AD-12); deep-links to a node via command bus',
  },
  permissions: [],
  failures: [
    'no local semantic retrieval (server-only, AD-12) -> offline = browse mirror only',
  ],
  recovery: 'version table restores prior tree state.',
};
