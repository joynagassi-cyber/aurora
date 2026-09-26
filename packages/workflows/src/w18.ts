import type { Workflow } from './types.ts';
export const w18: Workflow = {
  id: 'W18',
  name: 'OCR → Knowledge',
  trigger: 'document scan (DocumentScanner)',
  actors: ['user', 'server job'],
  modules: ['Knowledge', 'Learning'],
  capabilities: ['document.scan', 'ocr.run'],
  data: ['document_chunks', 'semantic_nodes'],
  eventsEmitted: ['CourseImported'],
  eventsConsumed: [],
  jobs: ['ocr', 'course_import'],
  ui: [
    { from: 'scanner', to: 'import-status' },
    { from: 'import-status', to: 'tree-node' },
  ],
  agent: {
    role: 'Tutor',
    action: 'extracts definitions/formulas with fidelity (ADR §17)',
  },
  permissions: ['camera'],
  failures: ['OCR absent / low quality -> manual entry (01 §6)'],
  recovery: 're-scan; embeddings recomputed idempotently.',
};
