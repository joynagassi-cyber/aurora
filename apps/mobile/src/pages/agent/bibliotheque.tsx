/**
 * Bibliothèque screen (PRD-AI-05, 10-08 — lot PRD-3 agent).
 *
 * /agent/bibliotheque — « Centraliser fichiers et médias importés ».
 * Phase 1 honest scope (AD-7 / AD-13, zéro contenu inventé) :
 *
 *  - No `library_files` mirror exists yet (owner wave) → BOTH sections
 *    (Documents / Contenus multimédias) ship the honest EMPTY state +
 *    the import CTA, NEVER fake tiles.
 *  - Import is a REAL action routed to the AGENT (the kernel executes
 *    it server-side, AD-12 : file import is a job — AD-8), with the
 *    source pre-filled (Fichiers / Drive / Photos / Appareil photo —
 *    the PRD's bottom-sheet picker, PRD-AI §2). A course import routes
 *    to the existing /learn import surface (fn-import-course, wave 0).
 *  - The info card (« Importez une fois, utilisez à volonté ») keeps
 *    the PRD's copy, and its « En savoir plus » routes to /learn (the
 *    course import surface) — no dead link.
 */
import { IonButton, IonButtons, IonContent, IonHeader, IonTitle } from '@ionic/react';
import { ArrowLeft, FileText, Image, Info, Plus, FolderOpen } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

/** The PRD's bottom-sheet picker sources (PRD-AI §2 BottomSheetPicker).
 *  Each source pre-fills a real agent intent (the kernel performs the
 *  import server-side, AD-8 : heavy = a job, never a UI-side upload). */
const IMPORT_SOURCES: Array<{ id: string; label: string; intent: string }> = [
  {
    id: 'fichiers',
    label: 'Fichiers',
    intent: "Importe un de mes documents dans ma bibliothèque (source : mes fichiers locaux). Aide-moi à choisir le document et à le classer.",
  },
  {
    id: 'drive',
    label: 'Drive',
    intent: "Importe un document depuis mon Drive dans ma bibliothèque. Liste-moi mes fichiers récents et aide-moi à choisir.",
  },
  {
    id: 'photos',
    label: 'Photos',
    intent: "Importe des photos ou captures d'écran dans ma bibliothèque (source : ma galerie) et aide-moi à les classer.",
  },
  {
    id: 'camera',
    label: 'Appareil photo',
    intent: "Importe une photo ou un document scanné dans ma bibliothèque (source : appareil photo) et prépare-le pour mon usage.",
  },
];

type LibraryTab = 'documents' | 'media';

export function AgentBibliothequePage() {
  const navigate = useNavigate();
  const [tab, setTab] = useState<LibraryTab>('documents');
  const [pickerOpen, setPickerOpen] = useState(false);

  // Each picker source pre-fills a REAL agent intent (the kernel performs
  // the import server-side, AD-8 : heavy = a job, never a UI-side upload).
  const importIntent = (intent: string) =>
    `/agent?intent=${encodeURIComponent(intent)}`;

  return (
    <>
      <IonHeader>
        <IonButtons slot="start">
          <IonButton fill="clear" onClick={() => navigate('/agent')} aria-label="Retour à l'assistant">
            <ArrowLeft size={18} />
          </IonButton>
        </IonButtons>
        <IonTitle>Bibliothèque</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-library>
          <p className="page-purpose">
            Tes fichiers et médias, prêts à servir dans toutes tes conversations.
          </p>

          {/* In-page pager (05 §3.4) : Documents / Contenus multimédias. */}
          <div className="segmented" role="tablist" aria-label="Vue bibliothèque">
            {(
              [
                ['documents', 'Documents'],
                ['media', 'Multimédias'],
              ] as [LibraryTab, string][]
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                role="tab"
                aria-selected={tab === value}
                className={tab === value ? 'segmented-item active' : 'segmented-item'}
                onClick={() => setTab(value)}
              >
                {label}
              </button>
            ))}
          </div>

          {/* PRD-AI-05 : section = honest empty (mirror not wired, AD-7)
              + a REAL import CTA (the agent executes the import, AD-8).
              Static surface (no async data yet) → the empty state IS the
              surface; the import CTA opens the source picker below. */}
          <div
            className="agent-lib-section"
            data-state="empty"
            role="region"
            aria-label={tab === 'documents' ? 'Documents' : 'Contenus multimédias'}
          >
            <span className="agent-lib-empty-icon" aria-hidden>
              {tab === 'documents' ? <FileText size={22} /> : <Image size={22} />}
            </span>
            <p>
              {tab === 'documents'
                ? 'Aucun document importé pour l’instant.'
                : 'Aucun média importé pour l’instant.'}
            </p>
            <p className="page-hint">
              {tab === 'documents'
                ? 'Tes documents (cours, PDF, présentations) apparaîtront ici après un import.'
                : 'Tes images, audios et vidéos apparaîtront ici après un import.'}
            </p>
            <button
              type="button"
              className="aurora-btn aurora-btn--primary aurora-tap"
              onClick={() => setPickerOpen(true)}
            >
              <Plus size={16} aria-hidden />
              Importer un fichier
            </button>
          </div>

          {/* PRD-AI-05 info card (« Importez une fois, utilisez à volonté »)
              — the « En savoir plus » link routes to /learn (the course
              import surface : fn-import-course), a real destination. */}
          <div className="agent-lib-infocard">
            <span aria-hidden>
              <Info size={16} />
            </span>
            <span className="agent-lib-infocard-text">
              Importez une fois, utilisez à volonté.
              <small>
                Un fichier importé reste disponible pour toutes vos
                conversations. Pour les cours, l'import structuré se fait
                depuis la page Apprendre.
              </small>
            </span>
            <a className="aurora-tap" href="/learn">
              <FolderOpen size={14} aria-hidden />
              En savoir plus
            </a>
          </div>
        </div>

        {/* Bottom-sheet picker (PRD-AI §2 BottomSheetPicker : Photos,
            Appareil photo, Fichiers, Drive). Every source pre-fills a
            real agent intent — the kernel performs the import (AD-8). */}
        {pickerOpen && (
          <div
            className="agent-plus-sheet"
            role="dialog"
            aria-modal="true"
            aria-label="Importer un fichier"
            onMouseDown={(e) => {
              if (e.target === e.currentTarget) setPickerOpen(false);
            }}
          >
            <div className="agent-plus-header">
              <h3>Importer un fichier</h3>
              <button
                type="button"
                className="agent-plus-close"
                onClick={() => setPickerOpen(false)}
                aria-label="Fermer"
              >
                ×
              </button>
            </div>
            <div className="agent-plus-section">
              <div className="agent-plus-label">Choisis la source</div>
              {IMPORT_SOURCES.map((s) => (
                <a
                  key={s.id}
                  className="agent-plus-option agent-menu-item aurora-tap"
                  href={importIntent(s.intent)}
                  onClick={() => setPickerOpen(false)}
                >
                  <FolderOpen size={14} aria-hidden />
                  <span>{s.label}</span>
                </a>
              ))}
              <p className="page-hint agent-lib-picker-hint">
                L'import est réalisé par l'assistant — tu choisis, il
                classe et prépare le fichier pour tes conversations.
              </p>
            </div>
          </div>
        )}
      </IonContent>
    </>
  );
}
