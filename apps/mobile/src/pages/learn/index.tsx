/**
 * Learning family (02 S6.1, 05 §4.6–4.9).
 *
 * /learn — due-reviews list + course chain entry (context-preserving:
 * course → chapter → sheet/QCM/flashcards/mirror). Study position is
 * persistent (ui-state); FSRS state is read-only local (AD-7).
 * /learn/:id — detail overlay over the /learn tab with the study modes.
 *
 * Full 6 UX states + killed. Data = the learning mirrors (courses, QCM,
 * flashcards, FSRS) — not yet wired to `MobileDataProvider`, so the
 * surfaces ship honest empty states + CTAs (never fake data, 05 §4).
 * KaTeX (`MathRenderer`) + virtuoso mount here once Tailwind is on mobile.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useState } from 'react';
import {
  AlignLeft,
  Award,
  BookOpen,
  Brain,
  Eye,
  FileText,
  Layers,
  ListChecks,
  SearchCheck,
  Sparkles,
  TrendingUp,
} from 'lucide-react';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';

const STUDY_MODES = [
  ['sheet', 'Fiche'],
  ['qcm', 'QCM'],
  ['flashcards', 'Flashcards'],
  ['mirror', 'Miroir'],
] as const;

/**
 * Le cataloge de modes d'étude (spec Learning — « transform resources into
 * understanding, recall, application and mastery ») : les 10 modes que le
 * module promet, en français simple (zéro jargon : la répétition espacée
 * s'appelle « répétition espacée », jamais « FSRS »). Chaque carte pointe
 * vers l'action honnête : les modes liés à un cours → l'import (pas de
 * cours = pas de mode, jamais de faux contenu) ; Coach → l'agent ;
 * Compétences → le suivi de progression.
 */
const MODE_CATALOG = [
  { id: 'sheet', label: 'Fiches d'étude', desc: 'Des fiches générées par l'IA, fidèles à ton cours.', Icon: FileText, href: '/inbox' },
  { id: 'summary', label: 'Résumés', desc: 'L'essentiel de tes cours, condensé.', Icon: AlignLeft, href: '/inbox' },
  { id: 'qcm', label: 'QCM', desc: 'Teste ta compréhension, question par question.', Icon: ListChecks, href: '/inbox' },
  { id: 'flashcards', label: 'Flashcards', desc: 'Répétition espacée : reviens au bon moment.', Icon: Layers, href: '/inbox' },
  { id: 'recall', label: 'Rappel actif', desc: 'Réponds d'abord, regarde la réponse ensuite.', Icon: Brain, href: '/inbox' },
  { id: 'exercises', label: 'Exercices', desc: 'Progressifs, du simple au complexe.', Icon: TrendingUp, href: '/inbox' },
  { id: 'correction', label: 'Correction', desc: 'Tes erreurs analysées, pour ne plus les refaire.', Icon: SearchCheck, href: '/inbox' },
  { id: 'coach', label: 'Coach', desc: 'L'IA t'accompagne pas à pas dans tes révisions.', Icon: Sparkles, href: '/agent' },
  { id: 'mirror', label: 'Miroir', desc: 'Explique ce que tu as appris, on t'évalue sur ta compréhension.', Icon: Eye, href: '/inbox' },
  { id: 'skills', label: 'Compétences', desc: 'Ton niveau par compétence, qui évolue avec toi.', Icon: Award, href: '/progress' },
] as const;

type StudyMode = (typeof STUDY_MODES)[number][0];

function emptyFlags() {
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  return { flags: { offline: !online, killed } as UxStateFlags, online };
}

export function LearnPage() {
  const { flags } = emptyFlags();

  return (
    <>
      <IonHeader>
        <IonTitle>Apprendre</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-learn-home>
          {/* Le but du module, en une ligne simple (spec Learning) :
              transformer les ressources en compréhension, mémorisation,
              application et maîtrise. */}
          <p className="learn-purpose">
            Transforme tes cours en compréhension, mémorisation et maîtrise.
          </p>

          {/* Due reviews (05 §4.8) — the read-only review mirror. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={{ ...flags, emptyCta: "Reprendre l'étude" }}
            label="Révisions"
          >
            <div className="learn-section">
              <h2 className="learn-section-title">Révisions dues</h2>
              <p>Rien à réviser pour l'instant.</p>
            </div>
          </UxStates>

          {/* Course chain entry (context-preserving: course → chapter → …). */}
          <div className="learn-section">
            <h2 className="learn-section-title">Cours</h2>
            <div data-state="empty">
              <p>Aucun cours</p>
              <a className="aurora-btn aurora-btn--ghost aurora-tap" href="/inbox">
                <BookOpen size={16} aria-hidden /> Importer un cours
              </a>
            </div>
          </div>

          {/* Le systeme complet de modes d'étude (spec Learning) — le
              cataloge honnête : chaque carte pointe vers l'action qui
              l'active (import d'un cours, l'agent, le suivi de progression).
              Jamais de faux contenu (AD-7). */}
          <div className="learn-section">
            <h2 className="learn-section-title">Modes d'étude</h2>
            <div className="learn-modes" data-learn-modes>
              {MODE_CATALOG.map(({ id, label, desc, Icon, href }) => (
                <a key={id} className="learn-mode-card aurora-tap" href={href}>
                  <span className="learn-mode-icon"><Icon size={18} aria-hidden /></span>
                  <span className="learn-mode-text">
                    <strong>{label}</strong>
                    <small>{desc}</small>
                  </span>
                </a>
              ))}
            </div>
            <p className="learn-modes-hint">
              La plupart de ces modes s'activent quand tu as au moins un cours.
              Coach et Compétences sont disponibles dès maintenant.
            </p>
          </div>
        </div>
      </IonContent>
    </>
  );
}

export function LearnDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [mode, setMode] = useState<StudyMode>('sheet');
  const { flags } = emptyFlags();
  const modeLabel = STUDY_MODES.find(([m]) => m === mode)?.[1] ?? 'Fiche';

  return (
    <>
      <IonHeader>
        <IonTitle>Cours</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-course-detail data-course-id={id}>
          <span className="breadcrumb">Apprendre &rsaquo; Cours</span>

          <UxStates state={{ status: 'empty' }} flags={flags} label="Étude">
            <div className="learn-detail">
              {/* Study modes (05 §4.7): sheet / QCM / flashcards / mirror.
                  T4 in-page (cosmetic). KaTeX + virtuoso mount here later. */}
              <div className="segmented" role="tablist" aria-label="Mode d'étude">
                {STUDY_MODES.map(([value, label]) => (
                  <button
                    key={value}
                    role="tab"
                    aria-selected={mode === value}
                    className={
                      mode === value
                        ? 'segmented-item active'
                        : 'segmented-item'
                    }
                    onClick={() => setMode(value)}
                  >
                    {label}
                  </button>
                ))}
              </div>
              <p className="learn-detail-hint">
                Le contenu de ton cours s'affichera ici — mode {modeLabel.toLowerCase()}
                prêt à l'emploi.
              </p>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
