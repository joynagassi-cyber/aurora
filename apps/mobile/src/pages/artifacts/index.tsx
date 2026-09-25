/**
 * Artifact detail (02 S6.1, ADR §16 preview per format).
 *
 * /artifacts/:id — preview per format (PDF, DOCX, PPTX, XLSX, images,
 * audio). Unsupported = NO fake preview (ADR §16). "loading preview /
 * unsupported" empty state. Presigned R2 URLs (04 §3.2.2, AD-3: client
 * never holds R2 keys, only short-lived signed URLs). Infographic
 * multi-resource = AntV + images (P4, packages/ui AD-10).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';

export function ArtifactPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <>
      <IonHeader>
        <IonTitle>Artefact</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-artifact-id={id} data-state="loading">Préchargement de l'aperçu…</div>
      </IonContent>
    </>
  );
}
