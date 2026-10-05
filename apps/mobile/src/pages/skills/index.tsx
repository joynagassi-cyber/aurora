/**
 * Skills page — the multi-source Skills Marketplace (Task 1, 2026-10-04).
 *
 * Three tabs, all server-backed through `fn-skills` (AD-3: publishable
 * scope only, zero provider keys on the device):
 *  - "Catalogue"  : the global curated catalog (skill_catalog, public read),
 *                   grouped by domain. Activate / deactivate toggles write
 *                   the user's own rows (user_skills, RLS-isolated).
 *  - "Mes skills" : the user's activated + personal skills, with a create
 *                   form for user-authored skills.
 *  - "Expert"     : the agent's auto-learned skills (expert_skills, ADR S14)
 *                   — read-only view.
 *
 * AD-7 degradation: when the `skills` client is absent (no Supabase env,
 * OQ-03) the page shows an honest empty state, never a fake catalog.
 *
 * All user-facing text is French.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  Brain,
  Check,
  Loader2,
  Plus,
  Search,
  Sparkles,
  Trash2,
  X,
} from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { useMobileData } from '../../query/context';
import type { SkillCatalogEntry, UserSkillRow } from '../../lib/skills-client';

// ——— Domain labels (the 6 catalog domains, French) —————————————————————
const DOMAIN_LABELS: Record<string, string> = {
  science: 'Scientifique',
  marketing: 'Marketing & Productivité',
  social: 'Réseau & Social',
  research: 'Recherche',
  documents: 'Documents & Présentations',
  creative: 'Création',
};

type Tab = 'catalog' | 'personal' | 'expert';

export function SkillsPage() {
  const { skills } = useMobileData();

  const [tab, setTab] = useState<Tab>('catalog');
  const [searchQuery, setSearchQuery] = useState('');
  const [domainFilter, setDomainFilter] = useState<string>('all');

  // Catalog state (server).
  const [catalog, setCatalog] = useState<SkillCatalogEntry[]>([]);
  const [userSkills, setUserSkills] = useState<UserSkillRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  // Create form (Mes skills tab).
  const [showCreate, setShowCreate] = useState(false);
  const [newSkillName, setNewSkillName] = useState('');
  const [newSkillDomain, setNewSkillDomain] = useState('documents');
  const [newSkillTrigger, setNewSkillTrigger] = useState('');
  const [creating, setCreating] = useState(false);

  const activeKeys = useMemo(
    () => new Set(userSkills.filter((s) => s.active).map((s) => s.skillKey)),
    [userSkills],
  );

  const loadAll = useCallback(async () => {
    if (!skills) return;
    setLoading(true);
    setLoadError(null);
    try {
      const [cat, mine] = await Promise.all([
        skills.listCatalog(),
        skills.listUserSkills(),
      ]);
      setCatalog(cat);
      setUserSkills(mine);
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : 'chargement du catalogue en échec');
    } finally {
      setLoading(false);
    }
  }, [skills]);

  useEffect(() => {
    void loadAll();
  }, [loadAll]);

  const toggleCatalogSkill = useCallback(
    async (entry: SkillCatalogEntry) => {
      if (!skills) return;
      const key = `builtin:${entry.skillKey}`;
      const isActive = activeKeys.has(key);
      if (isActive) {
        await skills.deactivateSkill(key);
      } else {
        await skills.activateSkill(key, {
          domain: entry.domain,
          name: entry.name,
          trigger: entry.trigger ?? undefined,
          objective: entry.objective ?? undefined,
          procedure: entry.procedure,
          constraints: entry.constraints,
          tools: entry.tools,
          source: entry.source,
        });
      }
      // Refresh the user's rows.
      try {
        setUserSkills(await skills.listUserSkills());
      } catch {
        /* keep local state on refresh failure */
      }
    },
    [skills, activeKeys],
  );

  const deletePersonalSkill = useCallback(
    async (skillKey: string) => {
      if (!skills) return;
      try {
        await skills.deleteUserSkill(skillKey);
        setUserSkills((prev) => prev.filter((s) => s.skillKey !== skillKey));
      } catch (e) {
        setLoadError(e instanceof Error ? e.message : 'suppression du skill en échec');
      }
    },
    [skills],
  );

  const createPersonalSkill = useCallback(async () => {
    if (!skills || !newSkillName.trim() || creating) return;
    setCreating(true);
    try {
      await skills.createUserSkill({
        name: newSkillName.trim(),
        domain: newSkillDomain,
        trigger: newSkillTrigger.trim() || undefined,
      });
      setNewSkillName('');
      setNewSkillTrigger('');
      setShowCreate(false);
      setUserSkills(await skills.listUserSkills());
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : 'création du skill en échec');
    } finally {
      setCreating(false);
    }
  }, [skills, newSkillName, newSkillDomain, newSkillTrigger, creating]);

  // Degraded state: the skills client is absent (no Supabase env, AD-7).
  if (!skills) {
    return (
      <>
        <IonHeader>
          <IonTitle>Skills</IonTitle>
        </IonHeader>
        <IonContent>
          <div className="skills-page">
            <div className="skills-empty">
              <p>Skills indisponibles.</p>
              <p>
                Le catalogue de skills est servi par le backend
                (fn-skills). Configure l'environnement Supabase (URL +
                publishable key) pour l'activer.
              </p>
            </div>
          </div>
        </IonContent>
      </>
    );
  }

  const domains = useMemo(() => {
    const set = new Set(catalog.map((c) => c.domain));
    return Array.from(set);
  }, [catalog]);

  const visibleDomains = domainFilter === 'all' ? domains : domains.filter((d) => d === domainFilter);

  const filteredCatalog = catalog.filter((c) => {
    if (domainFilter !== 'all' && c.domain !== domainFilter) return false;
    const q = searchQuery.toLowerCase();
    if (!q) return true;
    return (
      c.name.toLowerCase().includes(q) ||
      (c.objective ?? '').toLowerCase().includes(q) ||
      (c.description ?? '').toLowerCase().includes(q)
    );
  });

  const personalSkills = userSkills.filter((s) => s.source === 'user-created');
  const catalogActivated = userSkills.filter(
    (s) => s.source !== 'user-created' && s.active,
  );

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
                ['catalog', 'Catalogue'],
                ['personal', 'Mes skills'],
                ['expert', 'Expert'],
              ] as Array<[Tab, string]>
            ).map(([t, label]) => {
              const idx = t === 'catalog' ? 0 : t === 'personal' ? 1 : 2;
              return (
                <button
                  key={t}
                  type="button"
                  role="tab"
                  id={`tab-${t}`}
                  aria-selected={tab === t}
                  aria-controls={`panel-${t}`}
                  tabIndex={tab === t ? 0 : -1}
                  onKeyDown={(e) => {
                    let next = -1;
                    if (e.key === 'ArrowRight') next = (idx + 1) % 3;
                    else if (e.key === 'ArrowLeft') next = (idx - 1 + 3) % 3;
                    else if (e.key === 'Home') next = 0;
                    else if (e.key === 'End') next = 2;
                    if (next >= 0) {
                      e.preventDefault();
                      const target =
                        next === 0 ? 'catalog' : next === 1 ? 'personal' : 'expert';
                      setTab(target as Tab);
                      document.getElementById(`tab-${target}`)?.focus();
                    }
                  }}
                  className={`skills-tab ${tab === t ? 'is-active' : ''}`}
                  onClick={() => setTab(t)}
                >
                  {label}
                </button>
              );
            })}
          </div>

          {loadError && (
            <div className="skills-error" role="alert">
              <p>
                <span aria-hidden>⚠</span> {loadError}
              </p>
              <button type="button" onClick={() => void loadAll()}>
                Réessayer
              </button>
            </div>
          )}

          {tab === 'catalog' && (
            <div
              id="panel-catalog"
              role="tabpanel"
              aria-labelledby="tab-catalog"
              tabIndex={0}
              className="skills-body"
            >
              {/* Domain filter chips */}
              <div className="skills-domain-chips" role="group" aria-label="Filtrer par domaine">
                <button
                  type="button"
                  className={`skill-domain-chip ${domainFilter === 'all' ? 'is-active' : ''}`}
                  onClick={() => setDomainFilter('all')}
                >
                  Tous
                </button>
                {domains.map((d) => (
                  <button
                    key={d}
                    type="button"
                    className={`skill-domain-chip ${domainFilter === d ? 'is-active' : ''}`}
                    onClick={() => setDomainFilter(d)}
                  >
                    {DOMAIN_LABELS[d] ?? d}
                  </button>
                ))}
              </div>

              <div className="skills-search">
                <Search size={14} aria-hidden />
                <input
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Rechercher un skill…"
                  aria-label="Rechercher un skill"
                />
              </div>

              {loading && catalog.length === 0 ? (
                <div className="skills-empty">
                  <Loader2 size={16} aria-hidden className="is-spinning" />
                  Chargement du catalogue…
                </div>
              ) : (
                visibleDomains.map((d) => (
                  <section key={d} className="skills-domain-group">
                    <h3 className="skills-domain-title">{DOMAIN_LABELS[d] ?? d}</h3>
                    {filteredCatalog
                      .filter((c) => c.domain === d)
                      .map((entry) => {
                        const key = `builtin:${entry.skillKey}`;
                        const isActive = activeKeys.has(key);
                        return (
                          <div
                            key={key}
                            className={`skill-card ${isActive ? 'is-active' : ''}`}
                          >
                            <div className="skill-card-header">
                              <Sparkles size={14} aria-hidden />
                              <h4>{entry.name}</h4>
                              <span className="skill-source-tag">{entry.source}</span>
                            </div>
                            {entry.objective && <p>{entry.objective}</p>}
                            {entry.trigger && (
                              <p className="skill-trigger">Trigger : {entry.trigger}</p>
                            )}
                            {entry.procedure.length > 0 && (
                              <ol className="skill-procedure">
                                {entry.procedure.map((step, i) => (
                                  <li key={i}>{step}</li>
                                ))}
                              </ol>
                            )}
                            <div className="skill-card-tags">
                              {entry.tools.map((t) => (
                                <span key={t} className="skill-tag">
                                  {t}
                                </span>
                              ))}
                            </div>
                            <button
                              type="button"
                              className={`skill-activate-btn ${isActive ? 'is-on' : ''}`}
                              onClick={() => void toggleCatalogSkill(entry)}
                            >
                              {isActive ? (
                                <>
                                  <Check size={12} aria-hidden /> Activé
                                </>
                              ) : (
                                'Activer'
                              )}
                            </button>
                          </div>
                        );
                      })}
                  </section>
                ))
              )}
              {!loading && filteredCatalog.length === 0 && (
                <div className="skills-empty">
                  Aucun skill ne correspond à « {searchQuery || (DOMAIN_LABELS[domainFilter] ?? domainFilter)} ».
                </div>
              )}
            </div>
          )}

          {tab === 'personal' && (
            <div
              id="panel-personal"
              role="tabpanel"
              aria-labelledby="tab-personal"
              tabIndex={0}
              className="skills-body"
            >
              <button
                type="button"
                className="skills-create-btn"
                onClick={() => setShowCreate((v) => !v)}
              >
                <Plus size={14} aria-hidden />
                <span>Créer un skill perso</span>
              </button>

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
                    <input
                      value={newSkillName}
                      onChange={(e) => setNewSkillName(e.target.value)}
                      placeholder="ex. Révision type RDM"
                    />
                  </label>
                  <label>
                    Domaine
                    <select
                      value={newSkillDomain}
                      onChange={(e) => setNewSkillDomain(e.target.value)}
                    >
                      {Object.entries(DOMAIN_LABELS).map(([k, label]) => (
                        <option key={k} value={k}>
                          {label}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label>
                    Trigger (quand ça s'active)
                    <input
                      value={newSkillTrigger}
                      onChange={(e) => setNewSkillTrigger(e.target.value)}
                      placeholder="ex. Avant chaque examen"
                    />
                  </label>
                  <button
                    type="button"
                    className="skill-create-submit"
                    disabled={!newSkillName.trim() || creating}
                    onClick={() => void createPersonalSkill()}
                  >
                    {creating ? 'Création…' : 'Créer'}
                  </button>
                </div>
              )}

              {/* Personal (user-created) skills */}
              {personalSkills.length > 0 && (
                <section className="skills-domain-group">
                  <h3 className="skills-domain-title">Créés par toi</h3>
                  {personalSkills.map((s) => (
                    <div key={s.skillKey} className={`skill-card ${s.active ? 'is-active' : ''}`}>
                      <div className="skill-card-header">
                        <Sparkles size={14} aria-hidden />
                        <h4>{s.name}</h4>
                        <button
                          type="button"
                          className="skill-delete-btn"
                          aria-label="Supprimer"
                          onClick={() => void deletePersonalSkill(s.skillKey)}
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                      {s.trigger && <p className="skill-trigger">Trigger : {s.trigger}</p>}
                      <button
                        type="button"
                        className={`skill-activate-btn ${s.active ? 'is-on' : ''}`}
                        onClick={async () => {
                          try {
                            if (s.active) await skills.deactivateSkill(s.skillKey);
                            else await skills.activateSkill(s.skillKey);
                            setUserSkills(await skills.listUserSkills());
                          } catch (e) {
                            setLoadError(e instanceof Error ? e.message : 'action skill en échec');
                          }
                        }}
                      >
                        {s.active ? (
                          <>
                            <Check size={12} aria-hidden /> Activé
                          </>
                        ) : (
                          'Activer'
                        )}
                      </button>
                    </div>
                  ))}
                </section>
              )}

              {/* Catalog skills the user activated */}
              {catalogActivated.length > 0 && (
                <section className="skills-domain-group">
                  <h3 className="skills-domain-title">Activés depuis le catalogue</h3>
                  {catalogActivated.map((s) => (
                    <div key={s.skillKey} className="skill-card is-active">
                      <div className="skill-card-header">
                        <Sparkles size={14} aria-hidden />
                        <h4>{s.name}</h4>
                        <button
                          type="button"
                          className="skill-activate-btn is-on"
                          onClick={async () => {
                            try {
                              await skills.deactivateSkill(s.skillKey);
                              setUserSkills(await skills.listUserSkills());
                            } catch (e) {
                              setLoadError(e instanceof Error ? e.message : 'action skill en échec');
                            }
                          }}
                        >
                          <Check size={12} aria-hidden /> Activé
                        </button>
                      </div>
                    </div>
                  ))}
                </section>
              )}

              {personalSkills.length === 0 && catalogActivated.length === 0 && (
                <div className="skills-empty">
                  Pas encore de skill actif. Active un skill depuis le catalogue
                  ou crée ton premier skill perso.
                </div>
              )}
            </div>
          )}

          {tab === 'expert' && (
            <div
              id="panel-expert"
              role="tabpanel"
              aria-labelledby="tab-expert"
              tabIndex={0}
              className="skills-body"
            >
              <div className="skills-hint">
                <Brain size={16} aria-hidden />
                <p>
                  Les expert skills sont créées par l'agent à partir de ses erreurs
                  et réussites (ADR S14). Elles sont activées automatiquement quand
                  leur trigger se déclenche. Tu peux les consulter ici — l'agent ne
                  les expose pas dans le chat.
                </p>
              </div>
              {/*
               * The expert-skills table (expert_skills, ADR S14.5) is
               * server-only — the mobile shell has no typed client for it yet.
               * This tab shows an honest empty state until a dedicated
               * `fn-skills` expert verb (or a domain-level expert client) is
               * wired. No hardcoded mock data.
               */}
              <div className="skills-empty">
                <p>Aucune expert skill disponible.</p>
                <p>
                  L'agent apprend de ses propres exécutions et crée des expert
                  skills validées. Consulte le rapport de l'agent pour voir ce
                  qu'il a appris.
                </p>
              </div>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
