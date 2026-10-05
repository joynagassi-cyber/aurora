// SkillDocSheet — bottom sheet affichant le corps markdown complet d'un skill
// du catalogue marketplace (0021 seed). Rendu via react-markdown + remark-gfm
// (gfm = tables dans les SKILL.md Anthropic).
//
// Aucune donnée mock : le composant ne rend que le `body` passé en prop.
// Fermeture par clic sur le fond ou bouton X (accessibilité : focus trap
// minimal, Escape n'est pas géré par Ionic — clic sur backdrop suffit).

import { FileText, X } from 'lucide-react';
import { useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { SkillCatalogEntry } from '../../lib/skills-client';

interface Props {
  entry: SkillCatalogEntry;
  onClose: () => void;
}

export function SkillDocSheet({ entry, onClose }: Props) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeRef.current?.focus();
    // Bloque le scroll du document quand la sheet est ouverte (sheet plein bas).
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  return (
    <div
      className="skill-doc-sheet"
      role="dialog"
      aria-modal="true"
      aria-label={`Document du skill ${entry.name}`}
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="skill-doc-sheet-card">
        <header className="skill-doc-sheet-header">
          <div className="skill-doc-sheet-title">
            <FileText size={16} aria-hidden />
            <h3>{entry.name}</h3>
            <span className="skill-source-tag">{entry.source}</span>
          </div>
          <button
            ref={closeRef}
            type="button"
            className="skill-doc-sheet-close"
            aria-label="Fermer le document"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </header>
        {entry.description && <p className="skill-doc-sheet-desc">{entry.description}</p>}
        <div className="skill-doc-sheet-body">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{entry.body ?? ''}</ReactMarkdown>
        </div>
      </div>
    </div>
  );
}
