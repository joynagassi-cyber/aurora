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
import { Download, FileQuestion } from 'lucide-react';
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
          <span className="breadcrumb">Artefact &rsaquo; {id}</span>

          {/* The preview mirror is not wired yet (F-06): this is the
              "preview not available for this format" state. An empty, not a
              perpetual loading — a `loading` skeleton would pulse forever.
              The "Télécharger" button is the CTA that routes somewhere. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={{ ...flags, emptyCta: 'Télécharger' }}
            label="Aperçu"
          >
            <div className="artifact-preview" data-preview="unsupported">
              <FileQuestion size={40} aria-hidden />
              <p>Aperçu indisponible pour ce format</p>
              <button className="aurora-btn aurora-btn--ghost aurora-tap" type="button">
                <Download size={18} aria-hidden />
                Télécharger
              </button>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
