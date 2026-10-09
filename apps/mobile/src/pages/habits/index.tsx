/**
 * Habits family view (PRD-1 §4.5, PRD-HAB-01/02/03 — lot 2026-10).
 *
 * /habits — the daily check-in (« Jour » : cocher les habitudes dues,
 * voir la progression) + the catalog of original habit templates by
 * category (Santé / Vie / Sports / État d'esprit — PRD-HAB-03 : the
 * catalog is a LOCAL data set with ORIGINAL names + quotes, the
 * reference app's brand content is never reproduced).
 *
 * AD-7 honesty: the habits mirror is not wired to `MobileDataProvider`
 * yet → the « Jour » and « Actives » surfaces ship honest empty states
 * + a create CTA that routes to the agent (the agent creates the habit
 * through the owning module — single-writer, AD-7/F-03). Never a fake
 * streak, never invented check-ins.
 *
 * Catalog « + » = pre-filled agent intent (name + category + quote) —
 * a real action, never a dead affordance.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  Apple,
  BedDouble,
  Bike,
  BookOpen,
  Brain,
  Brush,
  CalendarDays,
  Coffee,
  Droplets,
  Dumbbell,
  Flag,
  Footprints,
  Moon,
  PiggyBank,
  Plus,
  Salad,
  Smile,
  Sparkles,
  Sun,
  Timer,
  Waves,
  Wind,
  List,
  type LucideIcon,
} from 'lucide-react';
import { useState } from 'react';
import { useUiStateStore } from '../../state/ui-state';
import {
  PageOptionsMenu,
  settingsItem,
  type PageOptionItem,
} from '../../ux/page-options-menu';
import { useHorizontalSwiper } from '../../ux/use-horizontal-swiper';

/** One catalog category (PRD-HAB-03) — original content only. */
interface HabitTemplate {
  name: string;
  quote: string;
  Icon: LucideIcon;
}
type Category = 'sante' | 'vie' | 'sports' | 'esprit';

/**
 * The habit catalog (≈20 templates — PRD-HAB-03 target « au moins 40 »
 * est itératif : ce lot livre les 20 fondateurs originaux, localisables,
 * sans aucune marque de l'app de référence).
 */
const HABIT_CATALOG: Record<Category, HabitTemplate[]> = {
  sante: [
    { name: "Boire 8 verres d'eau", quote: "Ton corps n'attend pas pour avoir soif.", Icon: Droplets },
    { name: 'Petit-déjeuner', quote: "Le jour commence mieux quand le corps est nourri.", Icon: Salad },
    { name: 'Café matinal', quote: "Un rituel simple pour démarrer en douceur.", Icon: Coffee },
    { name: 'Brosser ses dents', quote: "Deux minutes, matin et soir, pour la vie.", Icon: Brush },
    { name: 'Coucher avant minuit', quote: "Le sommeil est le premier soin.", Icon: BedDouble },
    { name: "S'hydrater à midi", quote: "Un verre d'eau change l'après-midi.", Icon: Apple },
  ],
  vie: [
    { name: 'Journal du soir', quote: "Écris trois lignes sur ta journée.", Icon: BookOpen },
    { name: 'Lire 20 pages', quote: "Une heure de lecture par semaine.", Icon: Brain },
    { name: 'Mettre de l’argent de côté', quote: "Un euro par jour, pas un choc le mois.", Icon: PiggyBank },
    { name: 'Appeler un proche', quote: "Une voix vaut mieux qu’un fil.", Icon: Sun },
    { name: 'Ranger son bureau', quote: "Moins de bruit, plus de calme.", Icon: Timer },
    { name: 'Planifier la semaine', quote: "Vingt minutes le dimanche, une semaine plus claire.", Icon: CalendarDays },
  ],
  sports: [
    { name: "Étirements du matin", quote: "Cinq minutes pour réveiller les muscles.", Icon: Footprints },
    { name: "Course 3× par semaine", quote: "La régularité bat l'intensité.", Icon: Wind },
    { name: 'Yoga 15 min', quote: "Le corps respire quand le mental suit.", Icon: Waves },
    { name: 'Vélo 30 min', quote: "Le plus court chemin vers la forme.", Icon: Bike },
    { name: 'Renforcement 2×', quote: "Deux séances, la base solide.", Icon: Dumbbell },
  ],
  esprit: [
    { name: "Méditer 10 min", quote: "L'esprit s'entraine comme un muscle.", Icon: Smile },
    { name: "Respiration 4-7-8", quote: "Quatre inspirations, sept retentions, huit expirations.", Icon: Wind },
    { name: 'Trois gratitudes', quote: "Chaque soir, trois choses qui ont bien passé.", Icon: Sun },
    { name: "Pause écrans 20h", quote: "Le soir, le temps est à toi.", Icon: Moon },
  ],
};

const CATEGORY_LABELS: Record<Category, string> = {
  sante: 'Santé',
  vie: 'Vie',
  sports: 'Sports',
  esprit: "État d'esprit",
};

type HabitsTab = 'jour' | 'actives' | 'catalogue';

/**
 * The daily check-in's day band (ref_087, lot C 2026-10-08) — the
 * « jeu—mer » strip with the active day highlighted, above the honest
 * empty state. The day strip is real (today's date, derived, AD-7); the
 * check-in below it stays an honest empty state + create CTA (the
 * habits mirror is not wired yet — no fake streaks, no invented
 * check-ins).
 */
function HabitsDayBand() {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  const today = now.getDate();
  // A 7-day strip ending on today (the reference's « jours » banner,
  // re-centered on "today" so it always ends on the real current day).
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(year, month, today - (6 - i));
    return {
      key: d.toISOString().slice(0, 10),
      short: d.toLocaleDateString('fr-FR', { weekday: 'short' }).replace('.', ''),
      isToday: i === 6,
    };
  });
  return (
    <div className="habits-day-band" role="group" aria-label="Cette semaine">
      {days.map((d) => (
        <button
          key={d.key}
          type="button"
          className={`habits-day-band-cell${d.isToday ? ' is-active' : ''}`}
          aria-current={d.isToday ? 'date' : undefined}
          tabIndex={0}
        >
          <span className="habits-day-band-cell-label">{d.short}</span>
          {/* The day's check-in dot — filled only for `today` (which is
              the honest check-in state: a neutral ring, not a fake
              streak number, since no habit log is wired yet, AD-7). */}
          <span className="habits-day-band-dot" aria-hidden />
        </button>
      ))}
    </div>
  );
}

/**
 * The weekly follow-through grid (ref_087 / ref_090, lot C 2026-10-08) —
 * a 7-day strip where each day's cell is tinted by how much of the
 * habit's goal was met that day, on the ALREADY-FROZEN token ramp
 * `--aurora-habit-weak/med/strong` (05 §2.1.2). With no wired habit log
 * (AD-7) the grid renders the RAMP ITSELF as the empty state — an honest
 * "this is what your week will look like" legend, not a fake data set:
 * the three intensity cells are real tokens, labeled, and the "today"
 * cell is the active ring.
 */
function HabitsWeekGrid() {
  const levels: Array<{ key: 'weak' | 'med' | 'strong'; label: string }> = [
    { key: 'weak', label: 'Un peu' },
    { key: 'med', label: 'Bien' },
    { key: 'strong', label: 'Complet' },
  ];
  return (
    <div className="habits-week-grid" data-state="empty" aria-label="Aperçu de la grille de suivi">
      <p className="habits-week-grid-caption">
        Chaque jour de ta semaine se teinte selon l'avancement — de
        <em> faible</em> à<em> complet</em>.
      </p>
      <div className="habits-week-grid-legend" role="list" aria-label="Niveaux de teinte">
        {levels.map((l) => (
          <span key={l.key} role="listitem" className={`habits-week-grid-swatch habits-week-grid-swatch--${l.key}`}>
            <span className="habits-week-grid-swatch-dot" aria-hidden />
            {l.label}
          </span>
        ))}
      </div>
      <div className="habits-week-grid-row" role="list" aria-label="Cette semaine">
        {Array.from({ length: 7 }, (_, i) => (
          <span
            key={i}
            role="listitem"
            className="habits-week-grid-cell"
            aria-label={i === 6 ? "Aujourd'hui" : `J-${6 - i}`}
          >
            <span
              className={`habits-week-grid-cell-fill${i === 6 ? ' is-today' : ''}`}
              aria-hidden
            />
          </span>
        ))}
      </div>
    </div>
  );
}

export function HabitsPage() {
  const [tab, setTab] = useState<HabitsTab>('jour');
  const panelOpen = useUiStateStore((s) => s.panelOpen);
  const setPanelOpen = useUiStateStore((s) => s.setPanelOpen);

  /** C5.4 : le glissement horizontal REVOILE le panneau latéral caché
      (05 §3.6.15 l.1402-1411) — `useHorizontalSwiper` partagé (pointer-
      based, GPU-only, `prefers-reduced-motion` = désactivé, le bascule
      reste au tap). Les 3 vues (Jour / Actives / Catalogue) glissent
      latéralement, le panneau reste T4 cosmetic-persistent. */
  const { isGliding, handlers, surfaceStyle } = useHorizontalSwiper(setPanelOpen);

  /** C5.4 : le menu « ⋮ » (05 §3.5 l.843-854, max 6 items) — bascule de
      vue (Jour / Actives / Catalogue) + réglages. La vue par défaut
      « Jour » n'est PAS dans le menu (K-10). 2 items de vue + 1
      « Paramètres » = 3 items. Chaque item porte une icône 16px
      couleur (ref_045) — les teintes sont les états FROZEN (05 §5.1,
      AD-17 : jamais une valeur brute). */
  const VIEW_ICONS: Record<HabitsTab, { icon: LucideIcon; tone: PageOptionItem['iconTone'] }> = {
    jour: { icon: Timer, tone: 'accent' },
    actives: { icon: List, tone: 'success' },
    catalogue: { icon: Sparkles, tone: 'warning' },
  };
  const menuItems: PageOptionItem[] = [
    ...(['actives', 'catalogue'] as const).map((v) => ({
      id: `vue-${v}`,
      label: v === 'actives' ? 'Actives' : 'Catalogue',
      icon: VIEW_ICONS[v].icon,
      iconTone: VIEW_ICONS[v].tone,
      active: tab === v,
      onClick: () => setTab(v),
    })),
    settingsItem('habits'),
  ];

  /** Intent générique (pas de modèle choisi) : l'agent aide à créer. */
  const createFirstIntent = () =>
    `/agent?intent=${encodeURIComponent(
      "Crée ma première habitude : aide-moi à choisir, à la cadrer (fréquence, objectif, rappel) et à la suivre chaque jour.",
    )}`;

  /** Intent pré-rempli depuis le catalogue (PRD-HAB-03 : « Tap + : ouvre
   *  création préremplie » — ici la création passe par l'agent, AD-7). */
  const createFromTemplate = (cat: Category, t: HabitTemplate) =>
    `/agent?intent=${encodeURIComponent(
      `Crée mon habitude « ${t.name} » (catégorie ${CATEGORY_LABELS[cat]}). Mon intention : ${t.quote}`,
    )}`;

  return (
    <>
      <IonHeader>
        <div className="habits-header">
          <IonTitle>Habitudes</IonTitle>
          <PageOptionsMenu items={menuItems} ariaLabel="Options de la page Habitudes" />
        </div>
      </IonHeader>
      <IonContent>
        <div
          data-habits-view={tab}
          className={`habits-surface${isGliding ? ' is-gliding' : ''}`}
          style={surfaceStyle}
          onPointerDown={handlers.onPointerDown}
          onPointerMove={handlers.onPointerMove}
          onPointerUp={handlers.onPointerUp}
          onPointerLeave={handlers.onPointerUp}
        >
          <div data-habits className="habits-page">
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Tes rituels quotidiens, au rythme qui te va.
          </p>

          {/* T4 in-page pager (05 §3.4) : Jour / Actives / Catalogue. */}
          <div className="segmented" role="tablist" aria-label="Vue habitudes">
            {(
              [
                ['jour', 'Jour'],
                ['actives', 'Actives'],
                ['catalogue', 'Catalogue'],
              ] as [HabitsTab, string][]
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

          {tab === 'jour' && (
            /* PRD-HAB-01 (Jour) : the day's check-in (day strip + habit
               rows + check-in buttons, ref_087). The check-in rows stay
               an honest empty state + a real create CTA (agent) because
               the habits mirror is not wired yet — the day band above
               them is real (today, derived), and the week-grid legend
               below previews the tinting ramp that WILL carry each day's
               progress. */
            <div data-habits-day className="habits-day">
              <HabitsDayBand />
              <div className="habits-empty-card">
                <p>Aucune habitude suivie pour l'instant.</p>
                <p className="habits-hint">
                  Le check-in du jour s'affichera ici dès que tu auras créé
                  ta première habitude — une pastille par habitude, qui se
                  remplit au fil de la journée.
                </p>
                <a className="aurora-btn aurora-btn--primary aurora-tap" href={createFirstIntent()}>
                  Créer ma première habitude
                </a>
              </div>
              <HabitsWeekGrid />
            </div>
          )}

          {tab === 'actives' && (
            /* PRD-HAB-02 (Actif / Archivé) : the active + archived list.
               Same honest empty (mirror not wired) + hints. */
            <div data-habits-active className="habits-empty-card">
              <p>Aucune habitude active, aucune archivée.</p>
              <p className="habits-hint">
                Tes habitudes actives et archivées apparaîtront ici —
                archiver conserve l'historique et la série.
              </p>
              <button
                type="button"
                className="aurora-btn aurora-btn--ghost aurora-tap"
                onClick={() => setTab('catalogue')}
              >
                Voir le catalogue
              </button>
            </div>
          )}

          {tab === 'catalogue' && (
            /* PRD-HAB-03 (Galerie) : the catalog grouped by category,
               each template = icon chip + name + original quote + a
               « + » that pre-fills the agent intent. */
            <div id="habits-catalogue" data-habits-catalogue>
              {(Object.keys(HABIT_CATALOG) as Category[]).map((cat) => (
                <section key={cat} className="habits-category">
                  <h3 className="habits-category-title">
                    {CATEGORY_LABELS[cat]}
                  </h3>
                  <div className="habits-grid">
                    {HABIT_CATALOG[cat].map((t) => (
                      <a
                        key={t.name}
                        className="habits-card aurora-tap"
                        href={createFromTemplate(cat, t)}
                      >
                        <span className="habits-card-icon">
                          <t.Icon size={18} aria-hidden />
                        </span>
                        <span className="habits-card-text">
                          <strong>{t.name}</strong>
                          <small>{t.quote}</small>
                        </span>
                        <span className="habits-card-add" aria-hidden>
                          +
                        </span>
                      </a>
                    ))}
                  </div>
                </section>
              ))}
            </div>
          )}
        </div>
        </div>

        {/* Le panneau caché révélé par le glissement horizontal (C5.4) —
            transformé en slide latéral (GPU-only), jamais un overlay
            qui masque la page (le panneau COEXISTE avec la vue).
            ref_045 : le panneau porte le profil de l'habitude courante
            (nom + % + jalon manqué + CTA) — jamais un écran vide mort. */}
        {panelOpen && (
          <div
            data-habits-panel-open
            className="habits-panel-slide"
            role="complementary"
            aria-label="Détail de l'habitude"
          >
            <div data-habits-panel className="habits-panel">
              <p className="page-purpose">Le détail de l'habitude.</p>
              <div className="habits-panel-profile">
                <div className="habits-panel-profile-head">
                  <span className="habits-panel-profile-name">Habitude</span>
                  <span className="habits-panel-profile-pct mono">0%</span>
                </div>
                <div className="habits-panel-profile-progress">
                  <div
                    className="habits-panel-profile-progress-fill"
                    style={{ width: '0%' }}
                  />
                </div>
                <span className="habits-panel-profile-missed mono">
                  <Flag size={12} aria-hidden /> Manquant 24/09
                </span>
                <a
                  className="aurora-btn aurora-btn--primary aurora-tap habits-panel-cta"
                  href={createFirstIntent()}
                >
                  <Plus size={16} aria-hidden /> Créer une habitude
                </a>
              </div>
            </div>
          </div>
        )}
      </IonContent>
    </>
  );
}
