/**
 * Capacités screen (PRD-AI-06, 10-08 — lot PRD-3 agent).
 *
 * /agent/capacites — « Activer ou désactiver les fonctions de
 * l'assistant ». Two honest layers (AD-7 / AD-13, zéro contrôle mort) :
 *
 *  LIVE (applied + sent with each request via `taskProfile`) :
 *   - Recherche web : off / standard / deep (ui-state shared with /agent,
 *     the AI router enforces it server-side, AD-5).
 *
 *  LOCKED (grisées AVEC RAISON — the PRD's own « option verrouillée »
 *  state : the server capability does not exist yet in Phase 1, so the
 *  control is shown but NEVER shipped as a working dead toggle) :
 *   - Exécution de code + création de fichiers (server job, wave-N)
 *   - Visualisations intégrées (bêta)
 *   - Mémoire (generation / sujets sensibles / fichiers mémoire)
 *   - Accès aux outils : only « Auto » exists today (the kernel decides
 *     server-side, AD-12) — on-demand / always are parked.
 *
 *  Plain French, zéro jargon visible ; tokens only (AD-17) ;
 *  radius ≤ 8 px ; tap ≥ 44 px.
 */
import { IonButton, IonButtons, IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  ArrowLeft,
  Brain,
  Code,
  Globe,
  Lock,
  Sparkles,
  Wrench,
} from 'lucide-react';
import type { ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUiStateStore } from '../../state/ui-state';

/** The live research levels (PRD-AI-06 : chaque réglage persiste et est
 *  envoyé avec la requête — `taskProfile.researchMode`). */
const RESEARCH_LEVELS: Array<{ id: 'off' | 'standard' | 'deep'; label: string; hint: string }> = [
  { id: 'off', label: 'Off', hint: "L'assistant ne cherche pas sur le web." },
  { id: 'standard', label: 'Standard', hint: 'Recherche simple avant de répondre.' },
  { id: 'deep', label: 'Détail', hint: 'Recherche approfondie en plusieurs étapes.' },
];

/** Locked capability row (PRD-AI-06 « Option verrouillée : grisée avec
 *  raison ») — the reason is VISIBLE and plain (zéro jargon). */
interface LockedRow {
  icon: ReactNode;
  title: string;
  reason: string;
}

const LOCKED_ROWS: Array<{ section: string; rows: LockedRow[] }> = [
  {
    section: 'Exécution',
    rows: [
      {
        icon: <Code size={16} aria-hidden />,
        title: 'Exécuter du code et créer des fichiers',
        reason: 'Bientôt disponible — les exécutions de code arriveront avec le service de calcul.',
      },
      {
        icon: <Sparkles size={16} aria-hidden />,
        title: 'Visualisations intégrées (bêta)',
        reason: "Bientôt disponible — les graphiques et arbres s'afficheront directement dans la conversation.",
      },
    ],
  },
  {
    section: 'Mémoire',
    rows: [
      {
        icon: <Brain size={16} aria-hidden />,
        title: 'Se souvenir à partir de tes conversations',
        reason: "Bientôt disponible — rien n'est enregistré pour l'instant ; tes conversations restent supprimables à tout moment.",
      },
      {
        icon: <Lock size={16} aria-hidden />,
        title: 'Inclure les sujets sensibles dans la mémoire',
        reason: "Désactivé par défaut et non disponible — les sujets sensibles n'entrent jamais dans la mémoire sans ton accord explicite.",
      },
    ],
  },
];

export function AgentCapacitesPage() {
  const navigate = useNavigate();
  const researchMode = useUiStateStore((s) => s.agentResearchMode);
  const setResearchMode = useUiStateStore((s) => s.setAgentResearchMode);

  return (
    <>
      <IonHeader>
        <IonButtons slot="start">
          <IonButton fill="clear" onClick={() => navigate('/agent')} aria-label="Retour à l'assistant">
            <ArrowLeft size={18} />
          </IonButton>
        </IonButtons>
        <IonTitle>Capacités</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-capacites>
          <p className="page-purpose">
            Choisis comment l'assistant travaille pour toi.
          </p>

          {/* ——— LIVE : Recherche web (sent with every request, AD-5) ——— */}
          <section className="agent-cap-section">
            <h3 className="agent-cap-section-title">
              <Globe size={16} aria-hidden />
              Recherche web
            </h3>
            <div
              className="agent-cap-segmented"
              role="radiogroup"
              aria-label="Recherche web"
            >
              {RESEARCH_LEVELS.map((lvl) => (
                <button
                  key={lvl.id}
                  type="button"
                  role="radio"
                  aria-checked={researchMode === lvl.id}
                  className={
                    'agent-cap-level' + (researchMode === lvl.id ? ' is-active' : '')
                  }
                  onClick={() => setResearchMode(lvl.id)}
                >
                  {lvl.label}
                </button>
              ))}
            </div>
            <p className="page-hint agent-cap-hint">
              {RESEARCH_LEVELS.find((l) => l.id === researchMode)?.hint}{' '}
              Chaque demande est envoyée avec ce réglage.
            </p>
          </section>

          {/* ——— LIVE : Accès aux outils (kernel = Auto today, AD-12) ——— */}
          <section className="agent-cap-section">
            <h3 className="agent-cap-section-title">
              <Wrench size={16} aria-hidden />
              Accès aux outils
            </h3>
            <div
              className="agent-cap-segmented"
              role="radiogroup"
              aria-label="Accès aux outils"
            >
              <button type="button" role="radio" aria-checked className="agent-cap-level is-active" disabled>
                Auto
              </button>
              <button type="button" role="radio" aria-checked="false" className="agent-cap-level" disabled title="Bientôt disponible">
                À la demande
              </button>
              <button type="button" role="radio" aria-checked="false" className="agent-cap-level" disabled title="Bientôt disponible">
                Toujours
              </button>
            </div>
            <p className="page-hint agent-cap-hint">
              « Auto » : l'assistant choisit l'outil adapté pour toi. Les
              autres modes arrivent plus tard.
            </p>
          </section>

          {/* ——— LOCKED : grisées avec raison (AD-13, jamais mort) ——— */}
          {LOCKED_ROWS.map(({ section, rows }) => (
            <section key={section} className="agent-cap-section">
              <h3 className="agent-cap-section-title">{section}</h3>
              {rows.map((row) => (
                <div key={row.title} className="agent-cap-row is-locked">
                  <span className="agent-cap-icon" aria-hidden>
                    {row.icon}
                  </span>
                  <span className="agent-cap-text">
                    <span className="agent-cap-title">{row.title}</span>
                    <span className="agent-cap-reason">{row.reason}</span>
                  </span>
                  <span className="agent-cap-badge" aria-hidden>
                    <Lock size={12} />
                  </span>
                </div>
              ))}
            </section>
          ))}
        </div>
      </IonContent>
    </>
  );
}
