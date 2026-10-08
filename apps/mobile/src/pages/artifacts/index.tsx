/**
 * Artifact detail (02 S6.1, ADR §16 preview per format).
 *
 * /artifacts/:id — preview per format (PDF, DOCX, PPTX, XLSX, images,
 * audio). Unsupported = NO fake preview (ADR §16). "loading preview /
 * unsupported" empty state. Presigned R2 URLs (AD-3: the client never
 * holds R2 keys, only short-lived signed URLs). Infographic multi-resource
 * = AntV + images (P4, packages/ui AD-10 `InfographicRenderer`).
 *
 * Full 6 UX states + killed. No artifacts mirror wired yet → the surface
 * ships the honest loading/unsupported states + an export affordance
 * (the `ArtifactGenerated` job lands the preview post-R2, F-06).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { FileQuestion } from 'lucide-react';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';

export function ArtifactPage() {
  const { id } = useParams<{ id: string }>();
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };

  return (
    <>
      <IonHeader>
        <IonTitle>Artefact</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-artifact-id={id}>
          {/* Jargon jamais visible : l'identifiant technique n'est jamais
              affiché tel quel à l'utilisateur. */}
          <span className="breadcrumb">Artefact</span>

          {/* The preview mirror is not wired yet (F-06): this is the
              "preview not available for this format" state. An empty, not a
              perpetual loading — a `loading` skeleton would pulse forever.
              The empty-state CTA routes to the agent (where the export job
              that produces the artifact lives) — never a dead button. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={{ ...flags, emptyCta: "Voir l'agent", emptyCtaHref: "/agent" }}
            label="Aperçu"
          >
            <div className="artifact-preview" data-preview="unsupported">
              <FileQuestion size={40} aria-hidden />
              <p>
                L'aperçu s'affichera ici dès que le document sera prêt.
              </p>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
