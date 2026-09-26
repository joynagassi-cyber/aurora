import type { Workflow } from './types.ts';
export const w17: Workflow = {
  id: 'W17',
  name: 'Audio → Transcription → Knowledge',
  trigger: 'user records an audio course (or imports)',
  actors: ['user', 'server jobs'],
  modules: ['Learning', 'Knowledge'],
  capabilities: ['audio.record', 'transcription.run', 'knowledge.ingest'],
  data: ['document_chunks', 'semantic_nodes'],
  eventsEmitted: ['CourseImported'],
  eventsConsumed: [],
  jobs: ['transcription', 'course_import'],
  ui: [
    { from: 'audio-viewer', to: 'timestamps' },
    { from: 'timestamps', to: 'concepts' },
  ],
  agent: {
    role: 'Tutor',
    action:
      'structures the transcript (provenance = audio segment, AD-11)',
  },
  permissions: ['mic'],
  failures: [
    'STT absent -> audio playable, transcript optional (AD-1 degradation)',
  ],
  recovery: 'jobs idempotent; viewer local.',
};
