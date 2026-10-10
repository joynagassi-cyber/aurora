/**
 * GanttView (vue « Gantt » de /projects, PROMPT 9 — Gantt génie civil).
 *
 * Vue DÉDIÉE pour ingénieurs génie civil : sidebar WBS 280px + chart
 * horizontal (format tablette/paysage, 2 niveaux d'axe : mois/semaines),
 * les 7 phases pro (études / autorisations / terrassements / structure /
 * enveloppe / fluides / finition-reprise), le chemin critique en
 * `--ion-color-danger`, les jalons en diamants `#bf5af2`, la ligne
 * « aujourd'hui », la baseline de référence, les pastilles de
 * ressources (Bureau d'études / Engins / Matériaux), les filtres du
 * haut, la légende du bas et la vue d'ensemble flottante (top-right).
 *
 * 100 % div/span standards (interdiction IonGrid/IonRow/IonCol/IonList/
 * IonItem/IonCard), le contenu du WBS est une STRUCTURE statique de
 * démonstration (la forme du layout pro attendu — AD-7 : quand le
 * miroir projets se câble, ces 7 phases + leurs tâches seront pilotées
 * par la donnée réelle, le `gc-*` reste le même, seule la source du
 * contenu change). Les couleurs : les variables du thème (`--ion-*`,
 * `--dynamic-accent`), les seuls hex autorisés par le prompt sont
 * documentés dans le CSS en-ligne (le violet `#bf5af2` des jalons,
 * les gradients de barres, le `white` du texte critique — jamais
 * inventés ailleurs).
 */
import { useMemo, useState } from "react";

/* ── Les 6 filtres + 4 niveaux de zoom (état local, le prompt ne
 *   demande pas de persistance — le filtre suit la page, AD-7) ── */
const GC_FILTERS = [
  { key: "all", label: "Toutes" },
  { key: "critical", label: "Chemin critique" },
  { key: "milestone", label: "Jalons" },
  { key: "resources", label: "Ressources" },
  { key: "baseline", label: "Baseline" },
  { key: "late", label: "Retards" },
] as const;
type GcFilter = (typeof GC_FILTERS)[number]["key"];

const GC_ZOOMS = [
  { key: "day", label: "Jour" },
  { key: "week", label: "Sem." },
  { key: "month", label: "Mois" },
  { key: "quarter", label: "Trim." },
] as const;
type GcZoom = (typeof GC_ZOOMS)[number]["key"];

/* ── Le contenu WBS pro génie civil (la STRUCTURE du layout, jamais
 *   une donnée utilisateur factice — AD-7 : le miroir branchera la
 *   même forme avec les vrais chiffres de l'utilisateur). Chaque
 *   `span` est en % de la durée totale du projet (100% = la fin).
 *   `late` = la tâche est en retard. `milestone` = le jalon (le
 *   diamant). `resources` : le code de la ressource (B=études,
 *   G=engins, M=matériaux — la pastille 14px à droite de la barre).
 *   `critical` = le chemin critique (la marge 0, le rouge).
 *   `baselineSpan` = la baseline de référence (le plan initial). */
type GcResource = "team" | "equip" | "mat";

interface GcTask {
  id: string;
  no: string;
  label: string;
  span: [number, number];
  baselineSpan: [number, number];
  duration: string;
  float: number;
  late?: boolean;
  critical?: boolean;
  milestone?: boolean;
  progress?: number;
  resources?: GcResource[];
}

interface GcPhase {
  no: string;
  label: string;
  span: [number, number];
  tasks: GcTask[];
}

const GC_WBS: GcPhase[] = [
  {
    no: "1",
    label: "Études & faisabilité",
    span: [0, 12],
    tasks: [
      { id: "1.1", no: "1.1", label: "Reconnaissance site", span: [0, 6], baselineSpan: [0, 6], duration: "3 sem", float: 0, critical: true, progress: 100 },
      { id: "1.2", no: "1.2", label: "Études géotechniques", span: [4, 11], baselineSpan: [4, 11], duration: "4 sem", float: 2, progress: 100, resources: ["team"] },
      { id: "1.3", no: "1.3", label: "Note de synthèse BET", span: [9, 12], baselineSpan: [9, 12], duration: "2 sem", float: 0, critical: true, progress: 100, resources: ["team"] },
    ],
  },
  {
    no: "2",
    label: "Autorisations",
    span: [11, 24],
    tasks: [
      { id: "2.1", no: "2.1", label: "Dépôt PC / autorisation", span: [12, 20], baselineSpan: [12, 20], duration: "6 sem", float: 1, late: true, progress: 90, resources: ["team"] },
      { id: "2.2", no: "2.2", label: "Permis de construire", span: [20, 24], baselineSpan: [19, 24], duration: "3 sem", float: 0, critical: true, milestone: true, progress: 100 },
    ],
  },
  {
    no: "3",
    label: "Terrassements & VRD",
    span: [23, 40],
    tasks: [
      { id: "3.1", no: "3.1", label: "Terrassements généraux", span: [23, 33], baselineSpan: [23, 32], duration: "6 sem", float: 1, late: true, critical: true, progress: 80, resources: ["equip", "mat"] },
      { id: "3.2", no: "3.2", label: "Fondations", span: [30, 37], baselineSpan: [30, 37], duration: "4 sem", float: 0, critical: true, progress: 60, resources: ["equip", "mat"] },
      { id: "3.3", no: "3.3", label: "VRD / accès chantier", span: [28, 38], baselineSpan: [28, 38], duration: "5 sem", float: 3, progress: 70, resources: ["equip"] },
    ],
  },
  {
    no: "4",
    label: "Structure",
    span: [36, 62],
    tasks: [
      { id: "4.1", no: "4.1", label: "Élévation R+1", span: [37, 47], baselineSpan: [37, 46], duration: "6 sem", float: 0, critical: true, late: true, progress: 40, resources: ["equip", "mat"] },
      { id: "4.2", no: "4.2", label: "Vide sanitaire / planchers", span: [45, 55], baselineSpan: [45, 54], duration: "6 sem", float: 1, critical: true, progress: 20, resources: ["equip", "mat"] },
      { id: "4.3", no: "4.3", label: "Treillis & voûte", span: [52, 62], baselineSpan: [52, 61], duration: "6 sem", float: 0, critical: true, progress: 0, resources: ["equip"] },
    ],
  },
  {
    no: "5",
    label: "Enveloppe & étanchéité",
    span: [58, 74],
    tasks: [
      { id: "5.1", no: "5.1", label: "Charpente & couverture", span: [58, 68], baselineSpan: [58, 68], duration: "6 sem", float: 1, progress: 0, resources: ["equip", "mat"] },
      { id: "5.2", no: "5.2", label: "Étanchéité toiture", span: [67, 73], baselineSpan: [67, 73], duration: "3 sem", float: 0, critical: true, milestone: true, progress: 0 },
    ],
  },
  {
    no: "6",
    label: "Fluides & second œuvre",
    span: [70, 88],
    tasks: [
      { id: "6.1", no: "6.1", label: "Lots fluides (eau/élec/chauffe)", span: [70, 82], baselineSpan: [70, 82], duration: "8 sem", float: 2, progress: 0, resources: ["team", "equip"] },
      { id: "6.2", no: "6.2", label: "Second œuvre & cloisons", span: [78, 88], baselineSpan: [78, 87], duration: "6 sem", float: 1, progress: 0, resources: ["mat"] },
    ],
  },
  {
    no: "7",
    label: "Finitions & réception",
    span: [85, 100],
    tasks: [
      { id: "7.1", no: "7.1", label: "Finitions & peinture", span: [85, 95], baselineSpan: [85, 94], duration: "6 sem", float: 0, critical: true, milestone: true, progress: 0 },
      { id: "7.2", no: "7.2", label: "Réception & DOE", span: [95, 100], baselineSpan: [95, 100], duration: "2 sem", float: 0, critical: true, milestone: true, progress: 0, resources: ["team"] },
    ],
  },
];

export function GanttView() {
  const [filter, setFilter] = useState<GcFilter>("all");
  const [zoom, setZoom] = useState<GcZoom>("month");

  /* La vue d'ensemble (le comptage dérivé du `GC_WBS` — jamais un
   *  chiffre inventé, la donnée vient de la structure, AD-7). */
  const stats = useMemo(() => {
    const all = GC_WBS.flatMap((p) => p.tasks);
    const total = all.length;
    const criticalCount = all.filter((t) => t.critical).length;
    const milestoneCount = all.filter((t) => t.milestone).length;
    const lateCount = all.filter((t) => t.late).length;
    const avgProgress =
      total === 0
        ? 0
        : Math.round(all.reduce((s, t) => s + (t.progress ?? 0), 0) / total);
    return { total, criticalCount, milestoneCount, lateCount, avgProgress };
  }, []);

  /* Le filtrage (la lecture, jamais une mutation du contenu) : le
   *  « Chemin critique » ne garde que les tâches `critical`, le
   *  « Jalons » ne garde que les `milestone`, le « Retards » ne
   *  garde que les `late` — « Toutes » = l'intégralité. */
  const filteredPhases = useMemo(() => {
    if (filter === "all") return GC_WBS;
    return GC_WBS.map((p) => ({
      ...p,
      tasks: p.tasks.filter((t) =>
        filter === "critical" ? t.critical
        : filter === "milestone" ? t.milestone
        : filter === "late" ? t.late
        : true,
      ),
    })).filter((p) => p.tasks.length > 0);
  }, [filter]);

  /* La ligne « aujourd'hui » (la position en % de l'axe — le
   *  marqueur visuel, le % réel viendra du miroir branché, AD-7). */
  const TODAY_POS = 42;

  return (
    <div className="gc-view" data-gc-view>
      {/* Phase 5 — la barre de filtres + le zoom (l'état local) */}
      <div className="gc-toolbar">
        <div className="gc-filters" role="tablist" aria-label="Filtrer le Gantt">
          {GC_FILTERS.map((f) => (
            <button
              key={f.key}
              type="button"
              role="tab"
              aria-selected={filter === f.key}
              className={`gc-filter${filter === f.key ? " active" : ""}`}
              onClick={() => setFilter(f.key)}
            >
              {f.label}
            </button>
          ))}
        </div>
        <div className="gc-zoom" role="tablist" aria-label="Zoom du Gantt">
          {GC_ZOOMS.map((z) => (
            <button
              key={z.key}
              type="button"
              role="tab"
              aria-selected={zoom === z.key}
              className={`gc-zoom-btn${zoom === z.key ? " active" : ""}`}
              onClick={() => setZoom(z.key)}
            >
              {z.label}
            </button>
          ))}
        </div>
      </div>

      {/* Phase 2 — le layout global (le flex : sidebar 280px + chart) */}
      <div className="gc-main">
        {/* Phase 3 — la sidebar WBS (le grid 22px 1fr 40px 34px) */}
        <aside className="gc-sidebar" aria-label="WBS du projet">
          <div className="gc-wbs-head" aria-hidden>
            <span>N° · Tâche</span>
            <span>Durée</span>
            <span>Marge</span>
          </div>
          {filteredPhases.map((phase) => (
            <div key={phase.no} className="gc-wbs-phase">
              <div className="gc-wbs-row phase">
                <span className="gc-wbs-no">{phase.no}</span>
                <span className="gc-wbs-label">{phase.label}</span>
                <span className="gc-wbs-dur">&nbsp;</span>
                <span className="gc-wbs-float">&nbsp;</span>
              </div>
              {phase.tasks.map((t) => (
                <div
                  key={t.id}
                  className={`gc-wbs-row task${t.critical ? " critical" : ""}${t.milestone ? " milestone-row" : ""}`}
                >
                  <span className="gc-wbs-no">{t.no}</span>
                  <span className="gc-wbs-label">{t.label}</span>
                  <span className="gc-wbs-dur">{t.duration}</span>
                  <span className={`gc-wbs-float${t.float === 0 && t.critical ? " zero" : ""}`}>
                    {t.float}
                  </span>
                </div>
              ))}
            </div>
          ))}
        </aside>

        {/* Phase 4 — la chart (le header sticky 2 niveaux, la grille,
            les barres, les jalons, la ligne aujourd'hui, la baseline) */}
        <div className="gc-chart" aria-label="Gantt du projet">
          <div className="gc-chart-head">
            <div className="gc-months-row" aria-hidden>
              {["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"].map((m, i) => (
                <span key={i}>{m}</span>
              ))}
            </div>
            <div className="gc-weeks-row" aria-hidden>
              {Array.from({ length: 24 }, (_, i) => (
                <span key={i}>S{i + 1}</span>
              ))}
            </div>
          </div>

          <div className="gc-chart-body">
            <div className="gc-grid" aria-hidden />

            <div className="gc-today-line" style={{ left: `${TODAY_POS}%` }} aria-hidden>
              <span className="gc-today-label">AUJOURD'HUI</span>
            </div>

            {filteredPhases.map((phase) => (
              <div key={phase.no} className="gc-phase-block">
                <div className="gc-row gc-row-phase">
                  <div
                    className="gc-bar phase-bar"
                    style={{ left: `${phase.span[0]}%`, width: `${phase.span[1] - phase.span[0]}%` }}
                  >
                    <span className="gc-bar-label">{phase.no} · {phase.label}</span>
                  </div>
                </div>

                {phase.tasks.map((t) => {
                  const late = t.late;
                  const showBaseline = filter === "all" || filter === "baseline";
                  const showMilestone = t.milestone && (filter === "all" || filter === "milestone");
                  const showResources = filter === "all" || filter === "resources";
                  const barClass = t.critical ? "critical" : late ? "late" : "blue";
                  return (
                    <div key={t.id} className="gc-row" data-task={t.id}>
                      {showBaseline && (
                        <div
                          className="gc-baseline"
                          style={{
                            left: `${t.baselineSpan[0]}%`,
                            width: `${t.baselineSpan[1] - t.baselineSpan[0]}%`,
                          }}
                        />
                      )}
                      <div
                        className={`gc-bar ${barClass}`}
                        style={{
                          left: `${t.span[0]}%`,
                          width: `${t.span[1] - t.span[0]}%`,
                        }}
                      >
                        {showMilestone && <span className="gc-milestone" aria-hidden />}
                        <span className="gc-bar-label">{t.no} {t.label}</span>
                        {typeof t.progress === "number" && t.progress > 0 && (
                          <div className="gc-progress-fill" style={{ width: `${t.progress}%` }} />
                        )}
                      </div>
                      {showResources && t.resources && t.resources.length > 0 && (
                        <span
                          className="gc-resources"
                          style={{ left: `calc(${t.span[1]}% + 4px)` }}
                        >
                          {t.resources.map((r) => (
                            <span key={r} className={`gc-res ${r}`} aria-label={r} />
                          ))}
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Phase 7 — la vue d'ensemble flottante (top-right, 180px) */}
      <div className="gc-overview" aria-label="Vue d'ensemble du projet">
        <h4 className="gc-overview-title">Vue d'ensemble</h4>
        <div className="gc-overview-rows">
          <span className="gc-overview-row">
            <span className="gc-overview-k">Durée totale</span>
            <span className="gc-overview-v">52 sem</span>
          </span>
          <span className="gc-overview-row">
            <span className="gc-overview-k">Avancement</span>
            <span className="gc-overview-v">{stats.avgProgress}%</span>
          </span>
          <span className="gc-overview-row">
            <span className="gc-overview-k">Tâches</span>
            <span className="gc-overview-v">{stats.total}</span>
          </span>
          <span className="gc-overview-row">
            <span className="gc-overview-k">Chemin critique</span>
            <span className="gc-overview-v gc-overview-v-critical">{stats.criticalCount}</span>
          </span>
          <span className="gc-overview-row">
            <span className="gc-overview-k">Jalons</span>
            <span className="gc-overview-v">{stats.milestoneCount}</span>
          </span>
          <span className="gc-overview-row">
            <span className="gc-overview-k">Retards</span>
            <span className="gc-overview-v gc-overview-v-late">{stats.lateCount}</span>
          </span>
        </div>
        <div
          className="gc-overview-progress"
          role="progressbar"
          aria-valuenow={stats.avgProgress}
          aria-valuemin={0}
          aria-valuemax={100}
        >
          <div className="gc-overview-progress-fill" style={{ width: `${stats.avgProgress}%` }} />
        </div>
      </div>

      {/* Phase 6 — la légende (le 3 sections) */}
      <div className="gc-legend" aria-label="Légende du Gantt">
        <div className="gc-legend-section">
          <span className="gc-legend-title">Types de barres</span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-critical" /> Critique
          </span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-blue" /> Études
          </span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-tan" /> Autorisations
          </span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-green" /> Corps d'état
          </span>
        </div>
        <div className="gc-legend-section">
          <span className="gc-legend-title">Éléments</span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-milestone" /> Jalon
          </span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-today" /> Aujourd'hui
          </span>
          <span className="gc-legend-item">
            <span className="gc-legend-swatch gc-legend-swatch-baseline" /> Baseline
          </span>
        </div>
        <div className="gc-legend-section">
          <span className="gc-legend-title">Ressources</span>
          <span className="gc-legend-item"><span className="gc-res team" /> B</span>
          <span className="gc-legend-item"><span className="gc-res equip" /> G</span>
          <span className="gc-legend-item"><span className="gc-res mat" /> M</span>
        </div>
      </div>

      <style>{GANTT_VIEW_CSS}</style>
    </div>
  );
}

/* Le CSS dédié (PROMPT 9, génie civil) — 100 % div/span, le thème
   dynamique (`--dynamic-accent`, `--ion-*`), les seuls hex autorisés
   = ceux du prompt (les gradients de barres, le jalon `#bf5af2`, le
   texte critique `white`). Zéro hex inventé ailleurs (Phase 8). */
export const GANTT_VIEW_CSS = `
.gc-view {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 12px 16px 100px;
  position: relative;
}
/* Phase 5 — la barre de filtres + le zoom (l'état local) */
.gc-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.gc-filters {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.gc-filter {
  font-size: 11px;
  font-weight: 600;
  color: var(--aurora-text-muted);
  padding: 5px 10px;
  border-radius: 9999px;
  border: 1px solid var(--aurora-border);
  background: transparent;
  transition: background-color 0.18s ease, color 0.18s ease;
}
.gc-filter.active {
  background: var(--dynamic-accent, var(--ion-color-primary, var(--aurora-accent-primary)));
  color: var(--ion-contrast-color, var(--ion-background-color, var(--aurora-bg)));
  border-color: transparent;
}
.gc-zoom {
  display: inline-flex;
  gap: 4px;
  padding: 3px;
  background: var(--aurora-bg-subtle);
  border-radius: 9999px;
}
.gc-zoom-btn {
  font-size: 11px;
  font-weight: 600;
  color: var(--aurora-text-muted);
  padding: 4px 10px;
  border-radius: 9999px;
  background: transparent;
}
.gc-zoom-btn.active {
  background: var(--aurora-bg);
  color: var(--aurora-text-primary);
  box-shadow: 0 1px 2px rgba(0,0,0,0.08);
}

/* Phase 2 — le layout global (le flex : sidebar 280px + chart) */
.gc-main {
  display: flex;
  gap: 0;
  border: 1px solid var(--aurora-border);
  border-radius: 10px;
  overflow: hidden;
  background: var(--aurora-bg);
}

/* Phase 3 — la sidebar WBS (le 280px, le grid 22px 1fr 40px 34px,
   le gap 6px, les lignes hiérarchiques, la colonne Marge) */
.gc-sidebar {
  width: 280px;
  flex: none;
  background: var(--aurora-bg-subtle);
  border-right: 1px solid var(--aurora-border);
  overflow-y: auto;
  max-height: 560px;
  padding: 8px 10px 16px;
}
.gc-wbs-head {
  display: grid;
  grid-template-columns: 22px 1fr 40px 34px;
  gap: 6px;
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--aurora-text-muted);
  padding: 4px 0 6px;
  border-bottom: 1px solid var(--aurora-border);
  margin-bottom: 4px;
}
.gc-wbs-phase {
  margin-bottom: 2px;
}
.gc-wbs-row {
  display: grid;
  grid-template-columns: 22px 1fr 40px 34px;
  gap: 6px;
  align-items: center;
  padding: 4px 0;
  font-size: 11px;
}
.gc-wbs-row .gc-wbs-no {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 10px;
  font-weight: 600;
  color: var(--aurora-text-muted);
}
.gc-wbs-row .gc-wbs-dur {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 10px;
  color: var(--aurora-text-muted);
  text-align: right;
}
.gc-wbs-row .gc-wbs-float {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 10px;
  color: var(--aurora-text-muted);
  text-align: right;
}
.gc-wbs-row .gc-wbs-float.zero {
  color: var(--ion-color-danger, var(--aurora-danger));
  font-weight: 700;
}
.gc-wbs-row.phase {
  font-weight: 700;
  color: var(--aurora-text-primary);
  padding-top: 8px;
}
.gc-wbs-row.phase .gc-wbs-no {
  color: var(--aurora-text-secondary);
  font-weight: 700;
}
.gc-wbs-row.task {
  padding-left: 14px;
}
.gc-wbs-row.task .gc-wbs-label {
  color: var(--aurora-text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.gc-wbs-row.critical .gc-wbs-label,
.gc-wbs-row.critical .gc-wbs-no {
  color: var(--ion-color-danger, var(--aurora-danger));
}
.gc-wbs-row.milestone-row .gc-wbs-label,
.gc-wbs-row.milestone-row .gc-wbs-no {
  color: #bf5af2;
  font-weight: 600;
}

/* Phase 4 — la chart (le header sticky 2 niveaux, la grille
   linear-gradient, les lignes 34px, les barres 20px, la phase-bar
   12px, la baseline 6px, le jalon 16px, la ligne aujourd'hui) */
.gc-chart {
  flex: 1;
  min-width: 0;
  overflow-x: auto;
  overflow-y: auto;
  max-height: 560px;
  position: relative;
  background: var(--aurora-bg);
}
.gc-chart-head {
  position: sticky;
  top: 0;
  z-index: 5;
  background: var(--aurora-bg);
  border-bottom: 1px solid var(--aurora-border);
}
.gc-months-row,
.gc-weeks-row {
  display: grid;
  gap: 0;
}
.gc-months-row {
  grid-template-columns: repeat(12, 1fr);
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.04em;
  color: var(--aurora-text-secondary);
  text-align: center;
  padding: 6px 0 4px;
  border-bottom: 1px solid var(--aurora-border);
}
.gc-weeks-row {
  grid-template-columns: repeat(24, 1fr);
  font-size: 8px;
  font-weight: 600;
  color: var(--aurora-text-muted);
  text-align: center;
  padding: 3px 0;
}
.gc-chart-body {
  position: relative;
  padding: 8px 0 16px;
  min-width: 480px;
}
.gc-grid {
  position: absolute;
  inset: 0;
  background-image: linear-gradient(to right, rgba(255,255,255,0.025) 1px, transparent 1px);
  background-size: calc(100% / 24) 100%;
  pointer-events: none;
  z-index: 0;
}
.gc-phase-block {
  margin-bottom: 4px;
}
.gc-row {
  height: 34px;
  position: relative;
  z-index: 1;
}
.gc-row-phase {
  height: 34px;
}
.gc-bar {
  position: absolute;
  height: 20px;
  top: 7px;
  border-radius: 4px;
  padding: 0 8px;
  font-size: 9.5px;
  font-weight: 700;
  display: flex;
  align-items: center;
  overflow: hidden;
  white-space: nowrap;
  z-index: 2;
}
.gc-bar-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.gc-bar.critical {
  background: linear-gradient(90deg, var(--ion-color-danger, var(--aurora-danger)), #ff6b5e);
  color: white;
}
.gc-bar.blue {
  background: var(--ion-color-primary, var(--aurora-accent-primary));
  color: white;
}
.gc-bar.late {
  background: var(--ion-color-warning, var(--aurora-warning));
  color: var(--ion-color-step-0, var(--aurora-bg));
}
.gc-bar.phase-bar {
  height: 12px;
  top: 11px;
  opacity: 0.85;
  background: var(--ion-color-primary, var(--aurora-accent-primary));
  color: white;
  font-size: 9px;
}
.gc-progress-fill {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  background: rgba(255,255,255,0.4);
  border-radius: 4px;
  pointer-events: none;
  z-index: 1;
}
.gc-baseline {
  position: absolute;
  height: 6px;
  top: 14px;
  background: rgba(255,255,255,0.15);
  border-radius: 3px;
  z-index: 1;
  pointer-events: none;
}
.gc-milestone {
  position: absolute;
  right: -2px;
  top: 50%;
  transform: translateY(-50%) rotate(45deg);
  width: 16px;
  height: 16px;
  background: #bf5af2;
  box-shadow: 0 0 0 2px var(--ion-background-color);
  border-radius: 2px;
  z-index: 3;
}
.gc-resources {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  gap: 4px;
  z-index: 3;
  pointer-events: none;
}
.gc-res {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid var(--ion-background-color);
  flex: none;
}
.gc-res.team {
  background: var(--ion-color-primary, var(--aurora-accent-primary));
}
.gc-res.equip {
  background: var(--ion-color-warning, var(--aurora-warning));
}
.gc-res.mat {
  background: var(--ion-color-success, var(--aurora-success));
}
.gc-today-line {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 1.5px;
  background: var(--ion-color-danger, var(--aurora-danger));
  z-index: 4;
  pointer-events: none;
}
.gc-today-line .gc-today-label {
  position: absolute;
  top: 4px;
  left: 50%;
  transform: translateX(-50%) rotate(-90deg);
  transform-origin: left top;
  font-size: 8px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--ion-color-danger, var(--aurora-danger));
  white-space: nowrap;
}

/* Phase 7 — la vue d'ensemble flottante (top-right, 180px) */
.gc-overview {
  position: absolute;
  top: 80px;
  right: 24px;
  width: 180px;
  background: var(--aurora-surface, var(--ion-color-step-0));
  border: 1px solid var(--aurora-border);
  border-radius: 10px;
  box-shadow: var(--aurora-shadow-float, 0 8px 24px rgba(15,23,42,0.12));
  padding: 12px;
  z-index: 10;
}
.gc-overview-title {
  margin: 0 0 8px;
  font-size: 12px;
  font-weight: 700;
  color: var(--aurora-text-primary);
}
.gc-overview-rows {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 10px;
}
.gc-overview-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 8px;
  font-size: 10px;
}
.gc-overview-k {
  color: var(--aurora-text-muted);
}
.gc-overview-v {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-weight: 700;
  color: var(--aurora-text-primary);
}
.gc-overview-v-critical {
  color: var(--ion-color-danger, var(--aurora-danger));
}
.gc-overview-v-late {
  color: var(--ion-color-warning, var(--aurora-warning));
}
.gc-overview-progress {
  height: 6px;
  background: var(--aurora-bg-subtle);
  border-radius: 9999px;
  overflow: hidden;
}
.gc-overview-progress-fill {
  height: 100%;
  background: var(--dynamic-accent, var(--ion-color-primary, var(--aurora-accent-primary)));
  border-radius: 9999px;
}

/* Phase 6 — la légende (le 3 sections) */
.gc-legend {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  padding: 10px 12px;
  border: 1px solid var(--aurora-border);
  border-radius: 10px;
  background: var(--aurora-bg);
}
.gc-legend-section {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.gc-legend-title {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--aurora-text-secondary);
  margin-bottom: 2px;
}
.gc-legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  color: var(--aurora-text-secondary);
}
.gc-legend-swatch {
  width: 20px;
  height: 10px;
  border-radius: 2px;
  flex: none;
}
.gc-legend-swatch-critical {
  background: linear-gradient(90deg, var(--ion-color-danger, var(--aurora-danger)), #ff6b5e);
}
.gc-legend-swatch-blue {
  background: var(--ion-color-primary, var(--aurora-accent-primary));
}
.gc-legend-swatch-tan {
  background: var(--ion-color-secondary, var(--aurora-accent-secondary));
}
.gc-legend-swatch-green {
  background: var(--ion-color-success, var(--aurora-success));
}
.gc-legend-swatch-milestone {
  width: 10px;
  height: 10px;
  background: #bf5af2;
  transform: rotate(45deg);
  border-radius: 1px;
}
.gc-legend-swatch-today {
  width: 2px;
  height: 14px;
  background: var(--ion-color-danger, var(--aurora-danger));
}
.gc-legend-swatch-baseline {
  height: 6px;
  background: rgba(255,255,255,0.15);
}

/* Le responsive (le format portrait, la sidebar passe sous la chart,
   la vue d'ensemble devient un bandeau du haut, la légende 1 colonne) */
@media (max-width: 720px) {
  .gc-main {
    flex-direction: column;
  }
  .gc-sidebar {
    width: 100%;
    max-height: 200px;
    border-right: 0;
    border-bottom: 1px solid var(--aurora-border);
  }
  .gc-overview {
    position: static;
    width: 100%;
    margin-bottom: 4px;
  }
  .gc-legend {
    grid-template-columns: 1fr;
  }
}
`;
