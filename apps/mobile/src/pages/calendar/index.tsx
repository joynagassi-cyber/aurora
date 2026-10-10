/**
 * Calendar family view (02 S6.1, 05 §4.4.2) — T4 in-page view switcher
 * (inspiration pattern 2026-10-03) + always-on task list strip
 * + DYNAMIC THEMING (10-09).
 *
 * AD-7: events + tasks come from le miroir local (non câblé → état
 * vide honnête, jamais de données factices). Les 6 vues in-page
 * (Liste / Année / Mois / Semaine / 3 Jours / Jour) sont 100 %
 * div CSS Grid (10-09) — le moteur FullCalendar n'est plus monté
 * par cette page depuis la refactorisation `YearView` (l'année
 * passe par `YearView`, le mois par `MonthView`, la semaine/
 * 3 jours par `MultiDayView`, le jour par `DayView`).
 *
 * DYNAMIC THEMING (10-09) : l'utilisateur choisit une image de fond
 * parmi le catalogue (`/themes/<file>.png`), le hook `useDynamicTheme`
 * extrait la couleur dominante de cette image (l'URL du catalogue,
 * même origine que l'app → le canvas reste non-tainted) et le
 * composant injecte les variables CSS correspondantes sur
 * `document.documentElement` via `useEffect` — le cœur du système,
 * AUCUNE classe de thème prédéfinie (pas de `.theme-ocean` /
 * `.theme-prairie`), AUCUNE couleur en dur :
 *   · `--dynamic-accent` : la couleur extraite (FAB, dates actives,
 *     points, icônes actives) ;
 *   · `--ion-color-primary` : l'alias Ionic, re-pointé sur la couleur
 *     extraite (le FAB suit donc l'image automatiquement) ;
 *   · `--text-main` / `--text-muted` : le contraste est résolu par la
 *     FORMULE DE LUMINANCE `(0.299R + 0.587G + 0.114B) / 255` du hook
 *     — un fond clair → texte noir, un fond sombre → texte blanc ;
 *   · `--glass-bg` / `--glass-border` : le fond « verre » des cartes
 *     (translucide clair/sombre selon le contraste résolu).
 *
 * Quand aucune image n'est sélectionnée, le hook retourne `rgb: null`
 * et aucune variable n'est injectée : le calendrier retombe sur les
 * fallback `--ion-*` / `--aurora-*` canoniques (AD-13 honest
 * degradation, la grille et la timeline restent lisibles en thème
 * neutre).
 *
 * La structure (10-09, 100 % div standards, jamais IonList/IonItem/
 * IonGrid — leurs styles par défaut cassent le design) :
 *   · Le header (le mois courant + le switch « Changer l'image ») ;
 *   · La grille du calendrier (7 colonnes, les jours, les pastilles,
 *     la date active) ;
 *   · La timeline (la ligne verticale, les points, les cartes
 *     d'événements « verre ») ;
 *   · Le FAB « + » (l'accent dynamique — `IonFabButton` consomme
 *     `--ion-color-primary`, le FAB suit l'image automatiquement) ;
 *   · La bottom nav locale (le même fond « verre » que les cartes,
 *     l'icône active = l'accent dynamique) — le ShellTabBar global du
 *     Shell reste inchangé, cette barre est la couche propre à la
 *     page calendrier.
 */
import { IonContent, IonFab, IonFabButton, IonHeader, IonTitle } from "@ionic/react";
import { useState, useEffect } from "react";
import type { CalendarViewName, RenderCalendarEvent } from "@aurora/ui";
import { Plus } from "lucide-react";
import { UxStates, type UxStateFlags } from "../../ux-states";
import { useOnlineStatus } from "../../hooks/use-online";
import { useUiStateStore } from "../../state/ui-state";
import {
  PageOptionsMenu,
  settingsItem,
  type PageOptionItem,
} from "../../ux/page-options-menu";
import {
  useDynamicTheme,
  applyDynamicThemeVariables,
  clearDynamicThemeVariables,
} from "../../hooks/useDynamicTheme";
import { DayView } from "./views/DayView";
import { MultiDayView } from "./views/MultiDayView";
import { MonthView } from "./views/MonthView";
import { YearView } from "./views/YearView";

// (Le bloc `void null as never as typeof _IonContent;` était un
//  vestige d'alias d'imports plus haut — retiré, les imports sont les
//  vrais, `@ionic/react`, jamais `ionicons/icons` qui n'existe pas.)
/**
 * Les 6 vues in-page du pattern d'inspiration (2026-10-03) :
 * Liste (agenda list) · Année (12 mini-mois) · Mois (grille
 * 7 colonnes) · Semaine (grille 7 jours) · 3 Jours (grille
 * 3 jours) · Jour (frise horaire 1 colonne). `yearGrid` et
 * `threeDayGrid` sont les 2 vues nouvelles (année = render
 * natif mini-mois, 3 jours = grille semaine à 3 colonnes).
 */
type CalendarPageView = CalendarViewName | "yearGrid" | "threeDayGrid";

const CALENDAR_VIEWS: [CalendarPageView, string][] = [
  ["listWeek", "Liste"],
  ["yearGrid", "Année"],
  ["dayGridMonth", "Mois"],
  ["timeGridWeek", "Semaine"],
  ["threeDayGrid", "3 Jours"],
  ["timeGridDay", "Jour"],
];

/**
 * Les 5 teintes de la timeline de liste (.tl-dot-*) — le code de
 * teinte est consommé par la page, jamais une couleur brute (AD-17).
 * blue/green/orange/red/purple : les variables Ionic sémantiques
 * canoniques (--ion-color-*), le fallback canonique (AD-13 honest
 * degradation) reste lisible en thème neutre.
 */
const TL_TONE: Record<string, "blue" | "green" | "orange" | "red" | "purple"> = {
  etude: "green",
  focus: "orange",
  projet: "blue",
  hydratation: "blue",
};

const TL_TONE_FALLBACK: "blue" | "green" | "orange" | "red" | "purple" = "blue";

/** Le catalogue d'images disponibles (servies via `/themes/<file>.png`,
 *  même origine que l'app — le canvas reste non-tainted, l'extraction
 *  fonctionne). Trame minimale de 4 saisons (portrait, le batch
 *  2026-10-B du catalogue `public/themes/`). */
const AVAILABLE_IMAGES: readonly string[] = [
  "/themes/ete_portrait.png",
  "/themes/automne_portrait.png",
  "/themes/hiver_portrait.png",
  "/themes/printemps_portrait.png",
];

/** Les 4 onglets de la bottom nav LOCALE du calendrier (le chrome
 *  global du Shell reste inchangé — cette barre est la couche propre à
 *  la page calendrier, c'est elle qui adopte le fond « verre » du
 *  Dynamic Theming, jamais le ShellTabBar global qui suit le thème
 *  canonique `--aurora-surface-bg`). */
const LOCAL_TABS = [
  { id: "calendar", label: "Calendrier" },
  { id: "tasks", label: "Tâches" },
  { id: "timeline", label: "Chronologie" },
  { id: "settings", label: "Réglages" },
] as const;

type LocalTabId = (typeof LOCAL_TABS)[number]["id"];

export function CalendarPage() {
  const [view, setView] = useState<CalendarPageView>("dayGridMonth");
  // AD-13 (6 états) : le calendrier lit le local (AD-7) — hors ligne il
  // reste lisible (last-known), tué l'app = reconnexion + resync.
  const killed = useUiStateStore((s) => s.killed);
  const online = useOnlineStatus();
  const flags: UxStateFlags = { offline: !online, killed };

  const [eventSort, setEventSort] = useState<"echeance" | "titre">("echeance");
  const [taskMode, setTaskMode] = useState<"liste" | "chronologie">("liste");

  /** C5.4 : le menu « ⋮ » (05 §3.5, max 6 items) — calendrier n'est PAS
      multi-vues glissable (un seul moteur FullCalendar, pas de slides),
      donc le glissement horizontal ne s'y applique PAS. Le menu porte le
      tri des événements + le mode liste des tâches + 1 item « Paramètres ».
      Chaque item porte une icône 16px couleur (ref_045) — les teintes sont
      les états FROZEN (05 §5.1, AD-17 : jamais une valeur brute). */
  const menuItems: PageOptionItem[] = [
    {
      id: "tri-echeance",
      label: "Trier par échéance",
      active: eventSort === "echeance",
      onClick: () => setEventSort("echeance"),
    },
    {
      id: "tri-titre",
      label: "Trier par titre",
      active: eventSort === "titre",
      onClick: () => setEventSort("titre"),
    },
    {
      id: "vue-liste",
      label: "Liste des tâches",
      active: taskMode === "liste",
      onClick: () => setTaskMode("liste"),
    },
    {
      id: "vue-chrono",
      label: "Chronologie des tâches",
      active: taskMode === "chronologie",
      onClick: () => setTaskMode("chronologie"),
    },
    settingsItem("calendar"),
  ];

  // AD-7: events come from the calendar mirror (not yet wired → empty).
  const events: RenderCalendarEvent[] = [];

  // DYNAMIC THEMING (10-09) : l'image sélectionnée (l'état local de la
  // page — le switch du header met à jour cet état, le hook s'exécute
  // sur le changement de l'URL), l'extraction (le hook) et l'injection
  // des variables CSS sur <html> (le cœur du système, jamais du code
  // en dur dans le composant lui-même).
  const [imageIndex, setImageIndex] = useState(0);
  const selectedImage = AVAILABLE_IMAGES[imageIndex] ?? null;
  const dynamicTheme = useDynamicTheme(selectedImage);
  useEffect(() => {
    if (dynamicTheme.rgb) {
      applyDynamicThemeVariables(dynamicTheme);
      return () => clearDynamicThemeVariables();
    }
    clearDynamicThemeVariables();
  }, [dynamicTheme]);

  /** Le switch du header : on avance d'UNE image (le cycle, jamais un
   *  choix aléatoire — l'UX attend un cycle prévisible). Le store global
   *  (ui-state) n'est PAS touché ici : le Dynamic Theming du calendrier
   *  est un état LOCAL à la page (la spéc le définit comme tel —
   *  « l'utilisateur choisit une image de fond parmi plusieurs », c'est
   *  la page qui porte ce choix, pas tout le shell). Le hook est piloté
   *  par l'URL, jamais par l'index — le contrat est réversible si un
   *  deep-link ou un paramètre global doit reprendre la main plus tard. */
  const handleCycleImage = () => {
    setImageIndex((i) => (i + 1) % AVAILABLE_IMAGES.length);
  };

  // L'onglet actif de la bottom nav locale (l'état est conservé, la page
  // n'est PAS repoussée — le switch d'onglet est local, 05 §3.4).
  const [activeLocalTab, setActiveLocalTab] = useState<LocalTabId>("calendar");

  /* Le mois courant en français (ref_007 : « octobre », jamais un numéro
   * nu) — dérivé de la date du jour, jamais inventé. */
  const currentMonthLabel = new Date().toLocaleDateString("fr-FR", {
    month: "long",
    year: "numeric",
  });

  /* Le strip « Aujourd'hui » (la timeline de liste, vue listWeek).
     AD-7 : le miroir non câblé n'affiche rien ici non plus ; la
     morphologie d'une carte d'événement est documentée dans le
     CALENDAR_CSS (.tl-card). */
  const todayLabel = new Date().toLocaleDateString("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });

  return (
    <>
      <IonHeader>
        <div className="cal-header">
          <IonTitle>Calendrier</IonTitle>
          <PageOptionsMenu items={menuItems} ariaLabel="Options de la page Calendrier" />
        </div>
      </IonHeader>

      <IonContent>
        {/* Le conteneur principal : l'image choisie est appliquée en
            fond (le style inline, la règle utilisateur :
            `style={{ backgroundImage: url(…) }}`) — le reste (le
            texte, la grille, la timeline, le FAB, la bottom nav)
            consomme les variables injectées par le hook, JAMAIS une
            valeur brute. */}
        <div
          className="cal-dynamic"
          style={
            selectedImage
              ? {
                  backgroundImage: `url(${selectedImage})`,
                  backgroundSize: "cover",
                  backgroundPosition: "center",
                  backgroundAttachment: "fixed",
                }
              : undefined
          }
        >
          <UxStates state={{ status: "success", data: null }} flags={flags} label="Calendrier">
          <div data-calendar="true" data-calendar-sort={eventSort === "echeance" ? "échéance" : "titre"} className="cal-page space-y-2">

            {/* Le header de section (le mois courant + le switch) — le
                titre du mois est celui de la page, jamais un numéro nu
                (ref_007). */}
            <header className="cal-dynamic-header">
              <p className="cal-dynamic-month" aria-label={`Calendrier — ${currentMonthLabel}`}>
                {currentMonthLabel}
              </p>
              <button
                type="button"
                className="cal-dynamic-switch"
                onClick={handleCycleImage}
                aria-label="Changer l'image de fond"
              >
                <span aria-hidden>🖼</span>
                <span>Changer</span>
              </button>
            </header>

            <p className="page-purpose">
              Tous tes blocs et tes tâches sur une seule vue.
            </p>

            {/* Le SegmentedControl in-page (05 §3.4) — le pattern partagé
                `.segmented` / `.segmented-item` (atoms.css), le même que
                /learn /progress /projects /tasks. */}
            <div role="tablist" aria-label="Vue calendrier" className="segmented">
              {CALENDAR_VIEWS.map(([name, label]) => (
                <button
                  key={name}
                  type="button"
                  role="tab"
                  aria-selected={view === name}
                  className={view === name ? "segmented-item active" : "segmented-item"}
                  onClick={() => setView(name)}
                >
                  {label}
                </button>
              ))}
            </div>

            {/* La grille du mois (vue « Mois », `dayGridMonth`) : le
                composant `MonthView` (le grid 7 colonnes des jours,
                les pastilles de tâches colorées, le disque accent
                dynamique sur « aujourd'hui ») — 100 % div CSS Grid,
                jamais IonGrid/IonRow/IonCol (10-09). Le moteur
                FullCalendar (`CalendarView`) est réservé aux vues
                restantes (l'année) ; cette grille standard est
                pilotée par les variables dynamiques du hook. */}
            {view === "dayGridMonth" && (
              <MonthView events={events} monthLabel={currentMonthLabel} rootClassName="cal-month-view" />
            )}

            {/* La frise horaire 1 colonne (vue « Jour », `timeGridDay`) :
                le composant `DayView` (`.cal-day-grid` 44px/1fr, les
                labels d'heures à gauche, le slot à droite avec les
                événements absolus + la ligne « maintenant ») — 100 %
                variables, le fond image respire derrière. JAMAIS un
                second composant de frise de jour (la règle « pas 2
                composants faisant la même chose »). */}
            {view === "timeGridDay" && (
              <DayView events={events} dateLabel={todayLabel} rootClassName="cal-day-view" />
            )}

            {/* Les frises multi-jours (3 Jours / 7 Jours, le
                composant partagé `MultiDayView` — le prop `days`
                pilote la grille, ZÉRO duplication avec un
                WeekView séparé). */}
            {view === "threeDayGrid" && (
              <MultiDayView days={3} events={events} />
            )}
            {view === "timeGridWeek" && (
              <MultiDayView days={7} events={events} />
            )}

            {/* La vue « Année » (`yearGrid`) : le composant `YearView`
                (les 12 mini-mois en 3 colonnes, les jours ayant
                l'événement en `.has-ev`, l'aujourd'hui en
                `.today`) — 100 % div/span CSS Grid, jamais le
                moteur FullCalendar qui n'est plus monté ici. Le
                calendrier est piloté par les variables dynamiques
                du hook (Dynamic Theming, 10-09). */}
            {view === "yearGrid" && (
              <YearView events={events} rootClassName="cal-year-view" />
            )}

            {/* La timeline de liste (vue « Liste ») : le scroll conteneur
                (.tl-scroll), les groupes par date (.tl-group : le header
                .tl-group-date + le conteneur .tl-items dont la ::before
                est la ligne verticale continue), les items (.tl-item :
                le point .tl-dot + la carte .tl-card). 100 % div,
                couleurs 100 % variables — le fond image respire derrière
                (Dynamic Theming, 10-09). */}
            {view === "listWeek" && (
              <section className="cal-card" aria-label="Liste">
                <div className="tl-scroll">
                  <div className="tl-group">
                    <div className="tl-group-date">Aujourd'hui · {todayLabel}</div>
                    <div className="tl-items">
                      {/* AD-7 : le miroir non câblé → la timeline est vide,
                          jamais une carte factice rendue. */}
                      {events.length === 0 ? (
                        <div className="tl-item">
                          <div className="tl-card">
                            <div className="tl-card-title">Aucun événement aujourd'hui</div>
                            <div className="tl-card-desc">Planifie un bloc ou une tâche avec le bouton « + ».</div>
                          </div>
                        </div>
                      ) : (
                        events.map((ev) => {
                          const tone = TL_TONE[ev.blockType ?? ""] ?? TL_TONE_FALLBACK;
                          const start = new Date(ev.start);
                          return (
                            <div key={ev.id} className="tl-item">
                              <div className={`tl-dot tl-dot-${tone}`} aria-hidden />
                              <div className="tl-card">
                                <div className="tl-card-head">
                                  <span className="tl-card-title">{ev.title}</span>
                                  <span className="tl-card-time">
                                    {start.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
                                  </span>
                                </div>
                                {ev.end && (
                                  <div className="tl-card-desc">
                                    Fin à{" "}
                                    {new Date(ev.end).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
                                  </div>
                                )}
                                {ev.conflicting && (
                                  <div className="tl-card-tags">
                                    <span className="tl-tag warn">Conflit</span>
                                  </div>
                                )}
                                {ev.focusSession && (
                                  <div className="tl-card-tags">
                                    <span className="tl-tag done">Focus</span>
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  </div>
                </div>
              </section>
            )}

            {/* Le strip « Tâches du mois » sous la grille (C2.2, ref_020) :
                le miroir non câblé (AD-7) → l'état vide honnête + le CTA. */}
            {view === "dayGridMonth" && (
              <div data-cal-task-list className="cal-card cal-task-list">
                <h3 className="cal-task-list-title">Tâches du mois</h3>
                <p className="page-hint">
                  Les tâches planifiées sur ce mois apparaîtront ici.
                </p>
              </div>
            )}

            {/* Le FAB « + » : le composant Ionic consomme
                `--ion-color-primary` (re-pointée par le hook sur la
                couleur extraite de l'image — le FAB suit donc l'image
                automatiquement, jamais une classe de thème prédéfinie).
                Toujours positionné au-dessus de la bottom nav locale
                (le `bottom: 88px` du CSS dédié). */}
            <IonFab slot="end">
              <IonFabButton color="primary" aria-label="Ajouter un bloc ou une tâche">
                <Plus size={24} />
              </IonFabButton>
            </IonFab>

            {/* La bottom nav LOCALE (le fond « verre » qui suit la couleur
                de l'image choisie — l'icône active = l'accent dynamique,
                `var(--dynamic-accent)`, jamais une valeur brute). Le
                ShellTabBar global du Shell reste inchangé : cette barre
                est propre à la page calendrier, c'est elle (et elle
                seule) qui adopte le fond « verre » du Dynamic Theming. */}
            <nav
              className="cal-dynamic-tabbar"
              role="tablist"
              aria-label="Navigation locale du calendrier"
            >
              {LOCAL_TABS.map((tab) => (
                <button
                  key={tab.id}
                  type="button"
                  role="tab"
                  aria-selected={activeLocalTab === tab.id}
                  className="cal-dynamic-tab"
                  data-active={activeLocalTab === tab.id || undefined}
                  onClick={() => setActiveLocalTab(tab.id)}
                >
                  <span className="cal-dynamic-tab-label">{tab.label}</span>
                </button>
              ))}
            </nav>

            {/* Le CSS dédié de la grille + la timeline (100 % div
                standards, 100 % variables de thème, semi-transparents
                sous thème image — le fond respire derrière). */}
            <style>{CALENDAR_CSS}</style>
          </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}

/* ── Calendrier (frise de liste + timeline) — 100 % variables de thème ──
   · Les vues grille (mois / année) sont portées par les composants
     dédiés (MonthView.tsx / CalendarView FullCalendar) — ce bloc
     ne couvre que la frise de liste (.tl-*) et le menu déroulant.
   · Timeline de liste : le scroll conteneur (.tl-scroll), les groupes
     par date (.tl-group), les items (.tl-item : le point .tl-dot +
     la carte .tl-card) — 100 % variables, le fond image respire
     derrière (Dynamic Theming, 10-09).
   · Cartes + menu déroulant : fond semi-transparent (`--glass-bg`,
     dérivé du thème ou de l'image) + backdrop-filter (blur) → le
     fond image respire à travers (05 §5.4-annexe).                 */
export const CALENDAR_CSS = `
/* — Timeline de liste (vue « Liste », .tl-*) —
   Le scroll conteneur (.tl-scroll), le groupe par date (.tl-group :
   le header .tl-group-date + le conteneur .tl-items dont la ::before
   est la ligne verticale continue), les items (.tl-item : le point
   .tl-dot + la carte .tl-card). 100 % variables, le fond image
   respire derrière (Dynamic Theming, 10-09). */
.tl-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 10px 16px 100px;
}
.tl-group-date {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  padding: 10px 0 4px;
  position: relative;
}
/* La ligne horizontale qui sépare le header du groupe (1px,
   --text-muted très atténué, jamais un hex de gris en dur). */
.tl-group-date::after {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 1px;
  background: var(--text-muted);
  opacity: 0.08;
}
/* Le conteneur des items : l'indent (22px) laisse passer la ligne
   verticale (7px, 1px, --text-muted, opacité 0.1) qui continue du
   premier au dernier item (bottom: -18px fait déborder sur le
   prochain groupe). */
.tl-items {
  padding-left: 22px;
  position: relative;
}
.tl-items::before {
  content: "";
  position: absolute;
  left: 7px;
  top: 8px;
  bottom: -18px;
  width: 1px;
  background: var(--text-muted);
  opacity: 0.1;
}
/* Chaque item : le point en absolu (left: -19px relatif au conteneur
   .tl-items indented à 22px : le point tombe sur la ligne 7px),
   la carte à droite. Le point "perce" la ligne (le ring passe par
   le fond du conteneur, jamais une couleur en dur). */
.tl-item {
  position: relative;
  padding: 8px 0;
}
.tl-dot {
  position: absolute;
  left: -19px;
  top: 14px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  border: 2px solid var(--ion-background-color);
}
/* Les 5 teintes de la liste (AD-17 : les variables sémantiques
   canoniques, jamais une valeur brute). */
.tl-dot-blue   { background: var(--ion-color-primary); }
.tl-dot-green  { background: var(--ion-color-success); }
.tl-dot-orange { background: var(--ion-color-warning); }
.tl-dot-red    { background: var(--ion-color-danger); }
.tl-dot-purple { background: var(--ion-color-tertiary); }

/* La carte d'événement (le fond "verre" : --glass-bg + backdrop
   blur, la bordure --glass-border, le texte --text-main/--text-muted
   - le fond image respire derrière, 05 §5.4-annexe). */
.tl-card {
  background: var(--glass-bg);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid var(--glass-border);
  border-radius: 10px;
  padding: 10px 12px;
}
.tl-card-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
}
.tl-card-title {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-main);
}
.tl-card-time {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: var(--text-muted);
  flex: none;
}
.tl-card-desc {
  margin-top: 4px;
  font-size: 13px;
  color: var(--text-muted);
}
/* Les tags (fond pastel translucide : le seul cas autorisé de
   rgba(…) par la règle "pastilles pastel des événements"). */
.tl-card-tags {
  margin-top: 6px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tl-tag {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-main);
  background: rgba(10, 132, 255, 0.2);
}
.tl-tag.warn { background: rgba(255, 159, 10, 0.2); }
.tl-tag.done { background: rgba(48, 209, 88, 0.2); }

/* — Le menu déroulant (options « ⋮ ») — fond « verre » + le flou backdrop
   (le fond image respire à travers, 05 §5.4-annexe). L'élément actif
   (l'option courante, ex. le tri) = l'accent dynamique (la couleur
   extraite de l'image par le hook), jamais une couleur fixe. */
.cal-header .page-options-menu-list {
  background: var(--glass-bg, var(--ion-card-background, var(--ion-color-light, var(--aurora-surface-bg))));
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid var(--glass-border, var(--ion-toolbar-border-color, var(--aurora-border)));
}
.cal-header .page-options-menu-item.is-active {
  color: var(--dynamic-accent, var(--ion-color-primary, var(--aurora-accent-primary)));
}
`;
