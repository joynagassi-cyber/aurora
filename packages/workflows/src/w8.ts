import type { Workflow } from './types.ts';
export const w8: Workflow = {
  id: 'W8',
  name: 'Course → Revision (sheet)',
  trigger: 'import completes (CourseImported) or user request',
  actors: ['user', 'Learning module', 'Agent'],
  modules: ['Learning', 'Knowledge', 'Artifact'],
  capabilities: ['course.search', 'learning.sheet.generate'],
  data: ['courses', 'document_chunks', 'artifacts'],
  eventsEmitted: ['ArtifactGenerated'],
  eventsConsumed: ['CourseImported'],
  jobs: ['ocr', 'course_import', 'artifact_gen'],
  ui: [
    { from: 'import', to: 'sheet' },
    { from: 'sheet', to: 'artifact-hub' },
  ],
  agent: {
    role: 'Tutor',
    action:
      'extracts definitions/formulas/traps with fidelity + fidelity check before export',
  },
  permissions: ['camera (scan)'],
  failures: [
    'OCR/STT absent -> manual entry',
    'fidelity drift -> flagged blocks (never silent)',
  ],
  recovery: 'idempotent jobs; export = ArtifactGenerated post-R2 (F-06).',
};
