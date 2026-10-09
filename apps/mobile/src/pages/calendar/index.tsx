/**
 * Calendar family view (02 S6.1, 05 §4.4.2) — T4 in-page view switcher
 * (inspiration pattern 2026-10-03) + always-on task list strip
 * + DYNAMIC THEMING (10-09).
 *
 * AD-7: events + tasks come from le miroir local (non câblé → état
 * vide honnête, jamais de données factices). Le moteur FullCalendar
 * est monté via le contrat `CalendarView` de `@aurora/ui`.
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
import type { ReactNode } from "react";
import { CalendarView } from "@aurora/ui";
import type {
  CalendarViewName,
  RenderCalendarEvent,
} from "@aurora/ui";
import type { DayCellContentArg } from "@aurora/ui";
import { Clock, Plus } from "lucide-react";
import { UxStates, type UxStateFlags } from "../../ux-states";
import { useOnlineStatus } from "../../hooks/use-online";
import { useUiStateStore } from "../../state/ui-state";
import {
  PageOptionsMenu,
  settingsItem,
  type PageOptionItem,
} from "../../ux/page-options-menu";
import { CalendarDots, CALENDAR_DOTS_CSS } from "../../ux/calendar-dots";
import {
  useDynamicTheme,
  applyDynamicThemeVariables,
  clearDynamicThemeVariables,
} from "../../hooks/useDynamicTheme";

// (Le bloc `void null as never as typeof _IonContent;` était un
//  vestige d'alias d'imports plus haut — retiré, les imports sont les
//  vrais, `@ionic/react`, jamais `ionicons/icons` qui n'existe pas.)
/**
 * Les 6 vues in-page du pattern d'inspiration (2026-10-03) :
 * Liste (agenda list) · Année · Mois · Semaine · 3 Jours · Jour.
 * `yearGrid` et `threeDayGrid` sont les 2 vues nouvelles (année =
 * render natif mini-mois, 3 jours = grille semaine à 3 colonnes).
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

/** Les 7 jours de la semaine, lundi en premier (05 §2.5 : fr). */
const DOW: string[] = ["L", "M", "M", "J", "V", "S", "D"];

/**
 * Construit les cellules du mois courant (grille standard 7 colonnes).
 * Les cellules « hors du mois courant » portent `.faded` (la teinte
 * grise système `--ion-color-medium`, jamais un hex fixe).
 * AD-7 : les pastilles viennent des `events` (miroir non câblé → 0
 * pastille, jamais un point factice, cf. `CalendarDots`).
 */
function buildMonthCells(): { number: number; faded: boolean; inMonth: boolean; iso: string | null }[] {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDay = new Date(year, month, 1).getDay();
  const padBefore = firstDay === 0 ? 6 : firstDay - 1; // lundi = 1ʳᵉ colonne
  const padAfter = (7 - ((padBefore + daysInMonth) % 7)) % 7;
  const prevMonthDays = new Date(year, month, 0).getDate();
  const cells: { number: number; faded: boolean; inMonth: boolean; iso: string | null }[] = [];
  for (let i = 0; i < padBefore; i++) {
    cells.push({ number: prevMonthDays - padBefore + i + 1, faded: true, inMonth: false, iso: null });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
    cells.push({ number: d, faded: false, inMonth: true, iso });
  }
  for (let i = 0; i < padAfter; i++) {
    cells.push({ number: i + 1, faded: true, inMonth: false, iso: null });
  }
  return cells;
}

/** Les codes `blockType` connus (agent-prompts Phase 2.3) → la teinte
 *  sémantique FROZEN (05 §5.1, AD-17 : jamais une valeur brute). */
const BLOCK_TONE: Record<string, "primary" | "success" | "warning"> = {
  etude: "success",
  focus: "warning",
  projet: "primary",
  hydratation: "primary",
};

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
  const [cells] = useState(() => buildMonthCells());
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

  /**
   * C2.2 : le superposé de pastilles SUR la cellule de la grille (le
   * hook FullCalendar `dayCellContent`, 05 §3.4 l.750 : le contenu de
   * la cellule reste contrôlé par la page, jamais par le composant).
   * Quand le mirroir n'est pas câblé (AD-7), `events` est vide → PAS
   * une seule pastille (le composant est honnête). */
  const renderDayCell = (arg: DayCellContentArg): ReactNode => {
    const codes: import("../../ux/calendar-dots").AccentCode[] = events
      .filter((ev) => ev.start?.startsWith(arg.dateStr.slice(0, 10)))
      .map((ev) => ev.accentCode ?? "primary");
    return (
      <div className="cal-day-cell">
        <span className="cal-day-number">{arg.dayNumber}</span>
        <CalendarDots codes={codes} ariaLabel={`${arg.dayNumber} : ${codes.length} événement(s)`} />
      </div>
    );
  };

  /* Le mois courant en français (ref_007 : « octobre », jamais un numéro
   * nu) — dérivé de la date du jour, jamais inventé. */
  const currentMonthLabel = new Date().toLocaleDateString("fr-FR", {
    month: "long",
    year: "numeric",
  });

  /* Le strip « Aujourd'hui » (la timeline verticale d'événements).
     AD-7 : le miroir non câblé n'affiche rien ici non plus ; la
     morphologie d'une carte d'événement (horaire + titre + icône
     d'horloge alignée à droite, ex. « Boire de l'eau ») est documentée
     dans le CALENDAR_CSS (`.cal-tl-card`). */
  const todayLabel = new Date().toLocaleDateString("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });

  // La date « aujourd'hui » (la seule donnée réelle de la page, AD-7 :
  // le miroir non câblé → jamais un événement factice, la pastille
  // n'apparaît que sur le jour courant lui-même, pas sur d'autres
  // jours inventés).
  const now = new Date();
  const todayDay = now.getDate();
  const todayIso = now.toISOString().slice(0, 10);

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

            {/* La grille du calendrier : 7 colonnes × les jours, 100 %
                div (interdiction IonList/IonItem/IonGrid, 10-09).
                `yearGrid` / les autres vues = le moteur FullCalendar
                (`CalendarView`) ; la grille standard (`.cal-dynamic-grid`)
                est 100 % div CSS Grid, pilotée par les variables
                dynamiques injectées par le hook. */}
            {view === "dayGridMonth" && (
              <div className="cal-card cal-grid-card" aria-label="Grille du mois">
                <div className="cal-dynamic-dow" aria-hidden>
                  {DOW.map((letter, i) => (
                    <span key={i}>{letter}</span>
                  ))}
                </div>
                <div className="cal-dynamic-grid">
                  {cells.map((c, i) => {
                    // La date active : LE jour courant (la seule donnée
                    // réelle de la page) — jamais une date inventée.
                    const isActive = !c.faded && c.number === todayDay;
                    // Les pastilles (le pseudo-élément `::after` du CSS,
                    // `data-has-event`) : le miroir non câblé (AD-7) →
                    // jamais un point factice ; seule la date
                    // « aujourd'hui » porte la pastille (le signal de
                    // « c'est le jour », jamais « il y a N événements »
                    // inventé).
                    const hasEvent = c.iso !== null && c.iso === todayIso;
                    return (
                      <div
                        key={i}
                        className={`cal-cell cal-dynamic-day${c.faded ? " faded" : ""}`}
                        data-muted={c.faded || undefined}
                        data-active={isActive || undefined}
                        data-has-event={hasEvent || undefined}
                        data-date={c.iso ?? undefined}
                      >
                        <span className="cal-day-number">{c.number}</span>
                      </div>
                    );
                  })}
                </div>
                {/* Les pastilles des jours qui ont du contenu (AD-7 : le
                    mirroir non câblé → 0 pastille, jamais un point factice). */}
                <style>{CALENDAR_DOTS_CSS}</style>
              </div>
            )}

            {view !== "dayGridMonth" && (
              <CalendarView
                key={view}
                events={events}
                initialView={
                  view === "threeDayGrid" ? "timeGridWeek" : view === "yearGrid" ? "dayGridMonth" : view
                }
                mobile
                height={view === "yearGrid" ? 380 : 420}
                emptyMessage="Aucun événement — planifie un bloc."
                dayCellContent={
                  view === "timeGridWeek" || view === "timeGridDay"
                    ? renderDayCell
                    : undefined
                }
              />
            )}

            {/* La timeline (Chronologie) : ligne verticale continue en
                absolute (left: 84px), points colorés par les variables
                dynamiques (l'accent extrait de l'image), cartes
                semi-transparents (backdrop-filter) — le fond image
                respire derrière (05 §5.4-annexe + Dynamic Theming). */}
            <section className="cal-card cal-timeline" aria-label="Aujourd'hui">
              <h3 className="cal-section-title">
                Aujourd'hui
                <span className="cal-timeline-date">{todayLabel}</span>
              </h3>
              <div className="cal-timeline-body">
                <div className="cal-timeline-line" aria-hidden />
                {/* AD-7 : le miroir non câblé → la timeline est vide,
                    jamais une carte factice rendue. La morphologie d'une
                    carte est documentée dans le CALENDAR_CSS ci-dessous
                    (`.cal-tl-card`). */}
                {events.length === 0 ? (
                  <p className="cal-timeline-empty">
                    Aucun événement aujourd'hui.
                  </p>
                ) : (
                  events.map((ev) => {
                    const start = new Date(ev.start);
                    return (
                      <div key={ev.id} className="cal-tl-row">
                        <span
                          className={`cal-tl-dot cal-tl-dot--${BLOCK_TONE[ev.blockType ?? ""] ?? "primary"}`}
                          aria-hidden
                        />
                        <div className="cal-tl-card">
                          <div className="cal-tl-card-main">
                            <span className="cal-tl-time">{start.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}</span>
                            <span className="cal-tl-label">{ev.title}</span>
                          </div>
                          {/* L'icône d'horloge (timeOutline, `Clock` lucide)
                              s'aligne à droite de la carte pour les
                              événements de durée (ex. « Boire de l'eau »). */}
                          <Clock size={16} aria-label="Durée" className="cal-tl-card-icon" />
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </section>

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

/* ── Calendrier (grille + timeline) — 100 % variables de thème ──────────
   · Grille : display:grid, 7 colonnes, text-align:center ; les dates
     grisées = `.faded` (color: var(--ion-color-medium) — le grey
     « inactif » du thème, JAMAIS un #000/…/#1c1c1e en dur).
   · Les pastilles sous les jours du mois = pseudo-élément `::after`
     centré, couleur var(--dynamic-accent) (l'accent extrait de l'image
     par le hook, le fallback `--ion-text-color` quand aucune image n'est
     sélectionnée — AD-13 honest degradation).
   · Timeline : la ligne verticale continue = un div absolu à gauche
     (left:84px, top:20px, bottom:0, width:1px) qui masque les dots ;
     les dots sont les pastilles colorées (variables dynamiques,
     fallbacks canoniques) avec un ring qui « perc[e] » la ligne.
   · Cartes d'événements + menu déroulant : fond semi-transparent
     (`--glass-bg`, dérivé du thème ou de l'image) + backdrop-filter
     (blur) → le fond image respire à travers (05 §5.4-annexe).        */
export const CALENDAR_CSS = `
/* — Grille du mois (7 colonnes, centré) — */
.cal-grid-card .cal-dynamic-dow,
.cal-grid-card .cal-dynamic-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
}
.cal-grid-card .cal-dynamic-dow span {
  padding: 6px 0;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--text-muted, var(--ion-color-medium, var(--aurora-text-muted)));
}
.cal-grid-card .cal-dynamic-grid {
  gap: 4px;
}
.cal-grid-card .cal-dynamic-day {
  position: relative;
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  background: transparent;
}
/* Les dates grisées (hors du mois courant) : opacité réduite, jamais un
   hex de gris inventé. */
.cal-grid-card .cal-dynamic-day[data-muted] {
  opacity: 0.4;
}
.cal-grid-card .cal-dynamic-day .cal-day-number {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-main, var(--ion-text-color, var(--aurora-text-primary)));
}
/* La date active : le fond accent = --dynamic-accent (la couleur extraite
   de l'image par le hook, le fallback --ion-color-primary quand aucune
   image n'est choisie) + le texte passe en blanc, la date active est un
   disque (border-radius 50%), pas un carré arrondi. */
.cal-grid-card .cal-dynamic-day[data-active] {
  background: var(--dynamic-accent, var(--ion-color-primary, var(--aurora-accent-primary)));
  border-radius: 50%;
}
.cal-grid-card .cal-dynamic-day[data-active] .cal-day-number {
  color: var(--ion-contrast-color, #fff);
}
/* Les points sous les dates (il y a du contenu ce jour) : pseudo-
   élément ::after centré sous le chiffre, couleur = l'accent dynamique,
   jamais une valeur brute. */
.cal-grid-card .cal-dynamic-day[data-has-event]::after {
  content: "";
  position: absolute;
  bottom: 4px;
  left: 50%;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  transform: translateX(-50%);
  background: var(--dynamic-accent, var(--ion-text-color, var(--aurora-text-primary)));
}
.cal-grid-card .cal-dynamic-day[data-active][data-has-event]::after {
  background: var(--ion-contrast-color, #fff);
}

/* — La timeline (Aujourd'hui) — */
.cal-timeline {
  position: relative;
}
.cal-timeline .cal-section-title {
  display: flex;
  align-items: baseline;
  gap: 8px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main, var(--ion-text-color, var(--aurora-text-primary)));
}
.cal-timeline .cal-timeline-date {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-muted, var(--ion-color-medium, var(--aurora-text-muted)));
}
.cal-timeline .cal-timeline-body {
  position: relative;
  padding: 12px 0 4px;
}
/* La ligne verticale continue : un div absolu à gauche qui monte de bas en
   haut, teinte = --text-muted (jamais un gris fixe) qui masque les dots. */
.cal-timeline .cal-timeline-line {
  position: absolute;
  left: 84px;
  top: 20px;
  bottom: 0;
  width: 1px;
  background-color: var(--text-muted, var(--ion-color-medium, var(--aurora-border-strong)));
  opacity: 0.3;
}
.cal-timeline .cal-timeline-empty {
  padding: 8px 0 8px 120px;
  font-size: 13px;
  color: var(--text-muted, var(--ion-color-medium, var(--aurora-text-muted)));
}
/* Chaque ligne d'événement : le dot à gauche (aligné sur la ligne), la
   carte à droite. */
.cal-timeline .cal-tl-row {
  position: relative;
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 8px;
  align-items: center;
  padding: 8px 0;
}
/* Les dots colorés (variables dynamiques : l'accent extrait de l'image) —
   le ring (border --glass-bg) les fait percer la ligne verticale en les
   calant sur le fond « verre » du thème. */
.cal-timeline .cal-tl-dot {
  position: absolute;
  left: 78px;
  top: 50%;
  transform: translateY(-50%);
  width: 12px;
  height: 12px;
  border-radius: 50%;
  border: 3px solid var(--glass-bg, var(--ion-background-color, var(--aurora-bg)));
  z-index: 1;
}
.cal-timeline .cal-tl-dot--primary  { background: var(--dynamic-accent, var(--ion-color-primary, var(--aurora-accent-primary))); }
.cal-timeline .cal-tl-dot--warning  { background: var(--ion-color-warning, var(--aurora-warning)); }
.cal-timeline .cal-tl-dot--success  { background: var(--ion-color-success, var(--aurora-success)); }

/* Les cartes d'événements : fond « verre » (--glass-bg, dérivé du thème ou
   de l'image) + le flou backdrop qui laisse le fond image respirer
   derrière. Les heures + le titre à gauche, l'icône (ex. l'horloge de
   « Boire de l'eau ») alignée à droite. Le texte consomme --text-main,
   jamais une valeur brute. */
.cal-tl-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  padding: 14px 16px;
  border-radius: 10px;
  background: var(--glass-bg, var(--ion-card-background, var(--ion-color-light, var(--aurora-surface-bg))));
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid var(--glass-border, var(--ion-toolbar-border-color, var(--aurora-border)));
  color: var(--text-main, var(--ion-text-color, var(--aurora-text-primary)));
}
.cal-tl-card-main {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.cal-tl-time {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: var(--text-muted, var(--ion-color-medium, var(--aurora-text-muted)));
}
.cal-tl-label {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-main, var(--ion-text-color, var(--aurora-text-primary)));
}
/* L'icône d'horloge (timeOutline), alignée à droite de la carte, teinte
   --text-muted, jamais une couleur fixe. */
.cal-tl-card-icon {
  flex: none;
  color: var(--text-muted, var(--ion-color-medium, var(--aurora-text-muted)));
}

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
