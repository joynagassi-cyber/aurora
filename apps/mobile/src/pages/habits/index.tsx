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
  Footprints,
  Moon,
  PiggyBank,
  Salad,
  Smile,
  Sun,
  Timer,
  Waves,
  Wind,
  type LucideIcon,
} from 'lucide-react';
import { useState } from 'react';

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

export function HabitsPage() {
  const [tab, setTab] = useState<HabitsTab>('jour');

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
        <IonTitle>Habitudes</IonTitle>
      </IonHeader>
      <IonContent>
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
            /* PRD-HAB-01 (Jour) : le check-in du jour (pastilles
               circulaires + libellé + progression). Mirror not wired
               → honest empty + a real create CTA (agent). */
            <div data-habits-day className="habits-empty-card">
              <p>Aucune habitude suivie pour l'instant.</p>
              <p className="habits-hint">
                Le check-in du jour s'affichera ici dès que tu auras créé
                ta première habitude.
              </p>
              <a className="aurora-btn aurora-btn--primary aurora-tap" href={createFirstIntent()}>
                Créer ma première habitude
              </a>
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
      </IonContent>
    </>
  );
}
