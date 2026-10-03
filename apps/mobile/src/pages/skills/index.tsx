/**
 * Skills page (ADR S14, expert-skills-extensions.md, ClawHub-compatible).
 *
 * User-facing skills (from marketplace / personal creation) are SEPARATE
 * from expert skills (auto-learned by the agent from its own errors, ADR S14.5).
 * This page manages the user's skill set:
 *  - Browse ClawHub marketplace skills (pre-loaded student-study set)
 *  - Create a personal skill (name + trigger + goal + procedure)
 *  - Activate / deactivate / delete
 *  - Read-only view of expert skills (the agent's own learnings, ADR S14)
 *
 * AD-3: no API keys on the device; marketplace reads are server-side.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Brain, Plus, Search, Sparkles, Trash2, X } from 'lucide-react';
import { useState } from 'react';

// ——— Marketplace catalog (ClawHub-compatible, pre-loaded student set). ———
interface MarketplaceSkill {
  id: string;
  name: string;
  description: string;
  tags: string[];
}

const MARKETPLACE_SKILLS: MarketplaceSkill[] = [
  {
    id: 'spaced-repetition-study',
    name: 'Spaced repetition study',
    description: 'Review flashcards at FSRS-optimal intervals; auto-schedule weak cards for re-learning before exams.',
    tags: ['study', 'memory', 'flashcards'],
  },
  {
    id: 'exam-prep-mode',
    name: 'Exam prep mode',
    description: 'Prioritize weak skills + schedule intensive review blocks in the 48 h window before each exam.',
    tags: ['study', 'exams', 'planning'],
  },
  {
    id: 'note-to-qa-converter',
    name: 'Note → Q&A converter',
    description: 'Convert lecture notes / PDF into self-generated Q&A pairs (learning.session job).',
    tags: ['study', 'learning', 'notes'],
  },
  {
    id: 'focus-anti-procrastination',
    name: 'Focus anti-procrastination',
    description: 'Detect stalling patterns in FocusSession bilans; propose 10-min micro-sessions when motivation drops.',
    tags: ['focus', 'discipline', 'productivity'],
  },
  {
    id: 'scientific-verify-checklist',
    name: 'Scientific verify checklist',
    description: 'Run unit/dimension checks + symbolic validation before marking a scientific task complete.',
    tags: ['science', 'verification', 'engineering'],
  },
];

// ——— Expert skills (auto-learned, ADR S14.5 — read-only view). ———
interface ExpertSkill {
  id: string;
  trigger: string;
  goal: string;
  confidence: number;
  status: 'active' | 'archived' | 'hypothesis';
  source: string; // which evidence / session produced it
}

// Mock data — in production this reads the `expert_skills` table via the
// ContextAssembler (server-side, AD-3). The UI shape mirrors the schema.
const EXPERT_SKILLS: ExpertSkill[] = [
  {
    id: 'es-1',
    trigger: 'RDM revision session at 14:00',
    goal: 'Higher QCM accuracy',
    confidence: 0.7,
    status: 'active',
    source: 'contrastive_pair:A-B',
  },
  {
    id: 'es-2',
    trigger: 'Low energy + interruptions >= 3',
    goal: 'Shorter session (10 min), review not new material',
    confidence: 0.5,
    status: 'hypothesis',
    source: 'triage:hypothesis-14d',
  },
];

type Tab = 'marketplace' | 'personal' | 'expert';

export function SkillsPage() {
  const [tab, setTab] = useState<Tab>('marketplace');
  const [searchQuery, setSearchQuery] = useState('');
  const [activated, setActivated] = useState<Set<string>>(new Set());
  const [showCreate, setShowCreate] = useState(false);
  const [newSkillName, setNewSkillName] = useState('');
  const [newSkillTrigger, setNewSkillTrigger] = useState('');
  const [personalSkills, setPersonalSkills] = useState<Array<{ id: string; name: string; trigger: string }>>([]);

  function toggleActivation(id: string) {
    setActivated((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function createPersonalSkill() {
    if (!newSkillName.trim() || !newSkillTrigger.trim()) return;
    const id = `personal-${personalSkills.length + 1}`;
    setPersonalSkills([...personalSkills, { id, name: newSkillName, trigger: newSkillTrigger }]);
    setActivated((prev) => new Set(prev).add(id));
    setNewSkillName('');
    setNewSkillTrigger('');
    setShowCreate(false);
  }

  const filteredMarketplace = MARKETPLACE_SKILLS.filter((s) => {
    const q = searchQuery.toLowerCase();
    return (
      s.name.toLowerCase().includes(q) ||
      s.description.toLowerCase().includes(q) ||
      s.tags.some((t) => t.toLowerCase().includes(q))
    );
  });

  return (
    <>
      <IonHeader>
        <IonTitle>Skills</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="skills-page">
          {/* Tab bar */}
          <div className="skills-tabs" role="tablist">
            {(
              [
                ['marketplace', 'Marketplace'],
                ['personal', 'Mes skills'],
                ['expert', 'Expert skills'],
              ] as Array<[Tab, string]>
            ).map(([t, label]) => (
              <button
                key={t}
                type="button"
                role="tab"
                aria-selected={tab === t}
                className={`skills-tab ${tab === t ? 'is-active' : ''}`}
                onClick={() => setTab(t)}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === 'marketplace' && (
            <div className="skills-body">
              <div className="skills-search">
                <Search size={14} aria-hidden />
                <input
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Rechercher dans ClawHub…"
                  aria-label="Rechercher un skill"
                />
              </div>
              {filteredMarketplace.map((s) => (
                <div key={s.id} className={`skill-card ${activated.has(s.id) ? 'is-active' : ''}`}>
                  <div className="skill-card-header">
                    <Sparkles size={14} aria-hidden />
                    <h4>{s.name}</h4>
                  </div>
                  <p>{s.description}</p>
                  <div className="skill-card-tags">
                    {s.tags.map((t) => (
                      <span key={t} className="skill-tag">{t}</span>
                    ))}
                  </div>
                  <button
                    type="button"
                    className={`skill-activate-btn ${activated.has(s.id) ? 'is-on' : ''}`}
                    onClick={() => toggleActivation(s.id)}
                  >
                    {activated.has(s.id) ? 'Activé ✓' : 'Activer'}
                  </button>
                </div>
              ))}
              {filteredMarketplace.length === 0 && (
                <div className="skills-empty">Aucun skill ne correspond à « {searchQuery} ».</div>
              )}
            </div>
          )}

          {tab === 'personal' && (
            <div className="skills-body">
              <button
                type="button"
                className="skills-create-btn"
                onClick={() => setShowCreate(true)}
              >
                <Plus size={14} />
                <span>Créer un skill perso</span>
              </button>

              {personalSkills.length === 0 && !showCreate && (
                <div className="skills-empty">
                  Pas encore de skill personnel. Crée-en un ou importe depuis la marketplace.
                </div>
              )}

              {personalSkills.map((s) => (
                <div key={s.id} className={`skill-card ${activated.has(s.id) ? 'is-active' : ''}`}>
                  <div className="skill-card-header">
                    <Sparkles size={14} aria-hidden />
                    <h4>{s.name}</h4>
                    <button
                      type="button"
                      className="skill-delete-btn"
                      aria-label="Supprimer"
                      onClick={() => {
                        setPersonalSkills((prev) => prev.filter((x) => x.id !== s.id));
                        setActivated((prev) => {
                          const n = new Set(prev);
                          n.delete(s.id);
                          return n;
                        });
                      }}
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>
                  <p className="skill-trigger">Trigger : {s.trigger}</p>
                  <button
                    type="button"
                    className={`skill-activate-btn ${activated.has(s.id) ? 'is-on' : ''}`}
                    onClick={() => toggleActivation(s.id)}
                  >
                    {activated.has(s.id) ? 'Activé ✓' : 'Activer'}
                  </button>
                </div>
              ))}

              {showCreate && (
                <div className="skill-create-form">
                  <div className="skill-create-header">
                    <h4>Nouveau skill</h4>
                    <button type="button" onClick={() => setShowCreate(false)} aria-label="Annuler">
                      <X size={14} />
                    </button>
                  </div>
                  <label>
                    Nom
                    <input value={newSkillName} onChange={(e) => setNewSkillName(e.target.value)} placeholder="ex. Révision type RDM" />
                  </label>
                  <label>
                    Trigger (quand ça s'active)
                    <input value={newSkillTrigger} onChange={(e) => setNewSkillTrigger(e.target.value)} placeholder="ex. Avant chaque examen RDM" />
                  </label>
                  <button type="button" className="skill-create-submit" onClick={createPersonalSkill}>
                    Créer
                  </button>
                </div>
              )}
            </div>
          )}

          {tab === 'expert' && (
            <div className="skills-body">
              <div className="skills-hint">
                <Brain size={16} aria-hidden />
                <p>
                  Les expert skills sont créées par l'agent à partir de ses erreurs et réussites
                  (ADR S14). Elles sont activées automatiquement quand leur trigger se déclenche.
                  Tu peux les consulter ici — l'agent ne les expose pas dans le chat.
                </p>
              </div>
              {EXPERT_SKILLS.map((s) => (
                <div key={s.id} className={`skill-card expert-skill ${s.status === 'active' ? 'is-active' : ''}`}>
                  <div className="skill-card-header">
                    <Brain size={14} aria-hidden />
                    <h4>{s.trigger}</h4>
                    <span className={`skill-status skill-status--${s.status}`}>{s.status}</span>
                  </div>
                  <p>{s.goal}</p>
                  <div className="skill-confidence">
                    <div className="skill-confidence-bar">
                      <div
                        className="skill-confidence-fill"
                        style={{ width: `${Math.round(s.confidence * 100)}%` }}
                      />
                    </div>
                    <span>confiance {Math.round(s.confidence * 100)} %</span>
                  </div>
                  <div className="skill-source">Source : {s.source}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
