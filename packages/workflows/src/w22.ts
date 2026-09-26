import type { Workflow } from './types.ts';
export const w22: Workflow = {
  id: 'W22',
  name: 'Artifact Preview & Export',
  trigger: 'user opens an artifact (imported or generated)',
  actors: ['user', 'Artifact module'],
  modules: ['Artifact', 'Integrations'],
  capabilities: ['artifact.open', 'artifact.export'],
  data: ['artifacts'],
  eventsEmitted: ['ArtifactGenerated', 'JobCompleted'],
  eventsConsumed: [],
  jobs: ['artifact_gen'],
  ui: [{ from: 'artifact-hub', to: 'artifact-preview' }],
  agent: {
    role: 'Agent (orchestration only)',
    action:
      'generates on request; NEVER emits ArtifactGenerated itself (F-06 — Artifact is the producer)',
  },
  permissions: ['presigned URLs only (AD-3)'],
  failures: [
    'preview engine error -> raw file fallback',
    'unsupported format = kept + downloadable, no preview claim',
  ],
  recovery: 're-download / re-generate via idempotent jobs.',
};
