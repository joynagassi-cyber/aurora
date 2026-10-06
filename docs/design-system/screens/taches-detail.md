# Écran — Tâches (détail) (`taches-detail`)

Module : Productivité · Route : `/tasks/:id` (S-24) · Statut : **additif** · SSoT écran : WDS 05.5 §1–§11 (OQ-1/OQ-2/OQ-3 closes 09/25) + `05-design-system` §3.1/§3.3/§3.5/§3.6.12/§3.7/§4.3.3 + `ui-libraries` S6/S6.1/S9 + `docs/productivity/eisenhower.md` §4/§5/§10

---

## §1 Psychologie du designer

| Dimension | Valeur |
|---|---|
| Objectif utilisateur | 1 ligne : lire les sous-tâches de la tâche, voir sa position dans la matrice Eisenhower (Q1…Q4), et lancer le Focus en 1 geste. |
| Contexte (device/moment/réseau) | Mobile (Pixel 4a, 540×960 dp), soirée ~23 h, thème Nocturne, réseau instable Bénin (3G) — offline = état premier (AD-7) ; contenu chargé depuis le mirror local PowerSync (WDS 05.5 §3, §10). |
| Fréquence | Quotidienne, 1–2×/jour au moment du check-in nocturne (boucle Horebs : capture → Kanban → détail → focus). |
| État émotionnel cible | Technical Calm : confirmation rapide (sous-tâches lisibles, Q1 surligné), aucun widget superflu (trigger-map §6 trap « Surcharge de widgets », WDS 05.5 §6). |
| Erreur la plus probable | Croire que la tâche a besoin du réseau (elle n'en a pas — AD-7) ; ou attendre une proposition de l'agent alors que le CTA est **fixe** (garde AD-14 : jamais de proposition libre, WDS 05.5 §6). |
| Ce que l'écran RÉSOUT | La question « ma tâche est-elle bien découpée et bien priorisée, et puis-je focus maintenant ? » — sous-tâches (OQ-2 close A : liste plate de checkboxes `RoutineStep`-style) + position Q computed (pas stockée, `quadrantOf(task, now)`, eisenhower.md §5) + CTA fixe « Lancer le focus » (AD-14). |
| Invariant | L'overlay est un **`BottomSheet full` par-dessus le board Kanban** (05 §4.3.3 l.1614–1618 ; pack 02 §6.1 l.390 : détail léger = sheet, retour = le **contexte** board, invariant S6.2) — le board **reste visible** en arrière-plan, jamais une navigation qui « part ». |

---

## §2 Zones de l'écran

| Zone | Contenu | SSoT |
|---|---|---|
| Surfaces (overlay) | `BottomSheet full` (85 % viewport) par-dessus le Kanban (S-05) ; le board reste monté en arrière-plan | WDS 05.5 §6 ; 05 §3.5 l.787–808 ; router.tsx (detail-over-tab) |
| Header (zone 1) | Titre tâche (≤ 60 car., 1 ligne) + Badge statut + Badge priorité (Q) | WDS 05.5 §6 (OQ-1 close A) ; 05 §3.2 |
| Section sous-tâches (zone 2) | Liste plate de checkboxes `RoutineStep`-style (numéro + Checkbox + titre + état) + compteur « x/y complétées » | WDS 05.5 OQ-2 close A ; 05 §3.6.12 l.1232–1242 |
| Section matrice (zone 3) | **Mini-matrice** : 4 cases compactes (Q1–Q4), case de la tâche **surlignée** — vue en contenu, **pas** l'écran quadrant S-39 | WDS 05.5 §6 (NON COUVERT → close) ; eisenhower.md §4 ; 05 §3.3 `Card` |
| CTA fixe | « Lancer le focus » — **seul** CTA d'action (AD-14), bas de l'overlay | WDS 05.5 §6 ; 05 §3.1 (1 primary max) ; eisenhower.md §4 |
| Bandeau offline (si S6=offline) | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) | 05 §3.7 ; WDS 05.5 §7 |

---

## §3 Éléments de l'écran (table 100 % de la zone)

| Élément | Composant DS 05 §3 | lib ui-libraries S1 | Tokens (AD-17) | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Sheet (conteneur) | BottomSheet `full` (05 §3.5 l.787–808) : handle 32×4 `border-strong`, coins hauts `xl` | shadcn Sheet/Dialog (S1 l.13–14) ; **pas** d'IonModal de contenu (le sheet = le contenu) | `surface`, `radius.lg` (8 px max, S3 l.142), `shadow.4`, `space.4` | desktop (Phase 2) = page dédiée, plus large, mêmes 3 zones (WDS 05.5 §5 variante non comptée) | WDS 05.5 §6 ; S1 l.13 ; 05 §3.5 |
| Titre tâche | TopBar interne du sheet : titre `md` 600, 1 ligne, ellipsis ≤ 60 car. | shadcn Text (headless) | `text.md`, `text-primary`, `space.4` | même | WDS 05.5 §6 (zone 1) ; 05 §3.2 |
| Badge statut | Badge/Chip (05 §3.3 l.531–544) : tonal, `sm` 500 | shadcn Badge | `color.info/warning/danger/success` + `-surface` par statut ; figé par thème (règle bloquante 05 §5.1) | même | 05 §3.3 ; 01 §4.1 l.165 (5 statuts) |
| Badge priorité (Q) | Badge (05 §3.3 l.531) : tonal | shadcn Badge | `color.primary-surface` (Q1) / `neutral-surface` (Q2–Q4) — le quadrant est **computed**, pas stocké | même | eisenhower.md §5 (`quadrantOf`, pure function) ; WDS 05.5 §6 |
| Section sous-tâches (Card) | `Card` (05 §3.3 l.498–511) contenant les `RoutineStep` — une Card = une routine/section | shadcn Card | `surface`, `shadow.1`, `radius.md` (8 px), `space.4` | même | WDS 05.5 OQ-2 close A ; 05 §3.6.12 l.1240–1242 (« la routine est un objet, l'étape est sa partie ») |
| Ligne sous-tâche | `RoutineStep` (05 §3.6.12 l.1232–1242) : `ListItem` + numérotation `JetBrains Mono` (1., 2., 3.) à gauche + `Checkbox` 44 px à droite | shadcn Checkbox (Radix) — **pas** `ion-item` (S3 l.137 interdit) | `row.min-height=56` (05 §3.3 l.514), `font.mono` (JetBrains Mono), `text-primary/secondary` | même | WDS 05.5 OQ-2 close A ; 05 §3.6.12 |
| Checkbox (toggle) | Checkbox (05 §3.2 l.450–459) : 44×44 px, `success` quand cochée (le « fait » = vert, pas `primary` — séparation des sémantiques §2.1) | shadcn Checkbox (S1 l.13 ; S3 interdit ion-item) | `color.success` (coché), `touch.target=44` (HC 56), `anim.fast` (pressed) | même | 05 §3.2 l.450–459 ; a11y 05 §6.3 |
| Compteur sous-tâches | Texte inline `JetBrains Mono` `xs` (ex. « 2/3 complétées ») — pas de ProgressBar (le % est le chiffre, la règle « la donnée parle ») | shadcn Text | `font.mono`, `text-muted`, `xs` | même | WDS 05.5 §6 ; 05 §2.6 règle 1 (données ne s'animent jamais) |
| Mini-matrice 4 cases | `Card flat` (05 §3.3 l.504–506 : « dans une liste dense ») découpée en 4 cases compactes ; la case occupée = surlignée `accent` (Q1 = `accent`/`success` selon thème Nocturne, WDS 05.5 §5) | shadcn Card + Token (composant **non encore** dans `packages/ui` → **OQ-3** §14) | `surface`, `surface-alt`, `color.accent` (Q1 surligné), `radius.md`, 4 cases 2×2 | même (4 cases = 1 ligne par quadrant, 1 case occupée) | WDS 05.5 §6 (OQ-1 close A : 3 zones distinctes) ; eisenhower.md §4 ; 05 §3.3 |
| CTA fixe « Lancer le focus » | `Button` (05 §3.1 l.367–390) variant `primary`, **le seul** CTA d'action de l'écran (AD-14 : max 1 primary) | shadcn Button (Radix + Tailwind) | `color.brand.primary` (thème courant), `on-primary`, `touch.target=44` (HC 56), `radius=8` max, `anim.fast` (pressed) | même (bouton pleine largeur en bas du sheet) | WDS 05.5 §6 ; 05 §3.1 ; AD-14 (05 l.368) |
| Bandeau offline (état S6) | Badge top-bar (05 §3.7 l.1258) : « Hors-ligne » — l'overlay reste **lisible** (AD-7) | shadcn Badge | `color.neutral.400`, `icon.size=16` | même | 05 §3.7 l.1258 ; WDS 05.5 §7 ; AD-7 |
| Toast (feedback action) | Toast (05 §3.5 l.823–841) : acknowledgement passif, 2 s, **pas d'action** | shadcn Toast (S6 l.183) | `color.success`, `text.sm`, auto-dismiss 2 s | même | 05 §3.5 l.823–841 ; S6 l.183 |

> S3 (ui-libraries l.133–143) : `ion-item` (formulaire) **interdit** — les sous-tâches = shadcn Checkbox (S1). La mini-matrice n'a pas de composant dans `packages/ui` → **OQ-3** §14 (à trancher : création `MiniMatrix` dans `packages/ui` ou variante `Card flat` ad hoc acceptée comme **OQ** pas comme invention silencieuse).

---

## §4 États de l'écran

### §4(a) Matrice 6 états S6 (AD-13) — éléments asynchrones : liste sous-tâches + mini-matrice

| État | Composant | Tokens | Texte exact | CTA | Entrée/Sortie |
|---|---|---|---|---|---|
| **loading** | Skeleton (pulse opacity 0.6→1, 1.2 s) × 3 (Header / Sous-tâches ×3 / Mini-matrice 4 cases) | `color.neutral.400`, `anim.slow=400ms` (pulse) | (silencieux) | CTA focus **disabled** (~300 ms max, AD-13, WDS 05.5 §7) | entrée : fade 150 ms ; sortie : swap contenu 250 ms |
| **empty** (pas de sous-tâches) | EmptyState compacte dans la section sous-tâches (05 §3.3 l.643–655) : icône 48 px `text-muted` + titre `md` 600 + body `sm` **max 2 lignes** | `color.neutral.400`, `icon.size=48`, `text.sm` | « Aucune sous-tâche — cette tâche est complète » | CTA focus **reste actif** (le focus ne dépend pas des sous-tâches, WDS 05.5 §7) ; optionnel : CTA « Créer une sous-tâche » (hors chemin court, AD-14) | fade 250 ms |
| **error** (synchronisation échouée) | Callout `danger` (05 §3.3 l.628–641) + Badge « à resync » (05 §3.3 l.527) dans le Header ; le contenu local **reste affiché** (AD-7) | `color.danger`, `color.danger-surface`, `text.sm` | « Tâche non synchronisée — données locales affichées » | Button ghost « Réessayer » dans le Callout (05 §3.3 l.636) + CTA focus actif | fade 200 ms ; retry = re-lecture miroir local (AD-7) |
| **success** | Toast (05 §3.5 l.823–841) : acknowledgement passif, 2 s, **pas d'action** | `color.success`, `text.sm`, auto-dismiss 2 s | « Tâche mise à jour » (après sync des sous-tâches) | aucune (auto-dismiss) | slide-in bas 250 ms |
| **offline** | Bandeau fine top-bar (05 §3.7 l.1258) + Badge « Hors-ligne » ; le contenu (sous-tâches + mini-matrice) **est affiché** (lecture locale AD-7) | `color.neutral.400`, `icon.size=16` | « Hors-ligne — données locales » | CTA focus **actif** (le focus mode est local, eisenhower.md §10) | fade 150 ms |
| **killed** (G-M2, 05 §3.7 l.1290–1301) | Skeleton (état `loading` normal du composant) + bannière fine « Reconnexion… » + logo **monochrome** (§9.1 : killed = monochrome) ; le contenu du mirror local s'affiche **en dessous** (AD-7, jamais d'écran blanc) | `color.neutral.400`, monochrome | « Reconnexion… » (bannière fine DS, pas par composant, l.1295) | CTA focus actif (relance depuis miroir local) | entrée : **instantanée** (pas d'animation, §2.6 r.4) ; sortie : fade 250 ms |

*Source : 05 §3.7 l.1244–1309 ; S6 (ui-libraries l.174–187) ; WDS 05.5 §7 (5 états canoniques).*

### §4(b) États sémantiques §6.1 (ui-libraries l.189–202)

| État sémantique | Composant + Tokens | Texte / CTA | SSoT |
|---|---|---|---|
| **en-cours** (sous-tâche `doing`) | ProgressBar (shadcn) + label `JetBrains Mono` `xs` (valeur courante, jamais un compteur animé — §2.6 règle 1) | « 1/3 en cours » (valeur statique, affichée pas animée) — **libellé exact + sémantique du compteur = OQ-6** §14 (pas de SSoT) | §6.1 l.197 ; 05 §2.6 l.310 |
| **terminé** (tâche `done`) | Lucide `CheckCircle2` + résumé (le « terminé » est l'état de l'objet, pas un toast) | « Tâche terminée » + CTA secondaire « Revenir au Kanban » (AD-14 : prochaine action) | §6.1 l.198 |
| **échec** (sync échoué, non retryable) | shadcn `Alert` destructive + raison + CTA vers **chemin alternatif** (pas retry in-place) | « Synchronisation impossible — vos données locales sont conservées » | §6.1 l.199 ; ≠ S6 `error` (transient) |
| **succès** | S6 `success` (Toast, auto 2 s, pas d'action — 05 §3.5 l.823–841) | « Tâche mise à jour » | §6.1 l.200 |
| **erreur** (transient, retryable) | S6 `error` (Alert destructive + « Réessayer » in-place, 05 §3.3 l.636) | « Impossible de charger les sous-tâches. Réessayer ? » | §6.1 l.201 |
| 404 / not-found (route `/tasks/:id` invalide) | Page entière : logo **coloré, sans fond, centré** (§9.1 : 404 = « colored without-background, CENTERED » ; §6.1 : state 404) ; message court ; CTA primaire | « Tâche introuvable. Elle a peut-être été supprimée ou le lien est invalide. » (**libellé exact = OQ-3** §14, pas de SSoT) + CTA « Retour à l'accueil » (navigation `/`, SSoT §6.1) | §6.1 (state 404) ; §9.1 (404 → COLORED, centered) ; OQ-3 §14 |

> **N/A** : « en-cours » de la tâche elle-même (pas d'état `doing` global mesurable ; le `doing` = le statut de la tâche, voir §4(c) ci-dessous) ; « échec » de la tâche individuelle (pas de statut `failed` dans le domaine task, 01 §4.1 l.165).

### §4(c) Statuts sémantiques de tâche (01 §4.1 l.165 — 5 statuts ADR §2.2)

| Statut | Badge (05 §3.3 l.531) | Couleur | Icône (Lucide 16 px) | Texte Badge | SSoT |
|---|---|---|---|---|---|
| **todo** | tonal | `color.info` | `Circle` | « À faire » | 01 §4.1 l.165 ; 05 §3.3 |
| **doing** | tonal | `color.warning` | `Play` | « En cours » | idem |
| **blocked** | tonal | `color.danger` | `OctagonAlert` | « Bloqué » | idem |
| **done** | tonal | `color.success` | `Check` | « Terminé » | idem |
| **cancelled** | tonal | `color.neutral.400` | `X` | « Annulé » | idem |

> Les 5 statuts sont **figés** (règle bloquante 05 §5.1 l.2931 : les thèmes ne re-définissent **jamais** success/warning/danger/info) — les badges restent les couleurs sémantiques quel que soit le thème (10 thèmes + 3 presets).

### §4(d) Killed (tout flux serveur, 05 §3.7 l.1290–1301)

| Élément | Valeur | Tokens | Texte exact | SSoT |
|---|---|---|---|---|
| Bannière | Bandeau fine (DS, **pas** par composant) + logo **monochrome** (§9.1 : killed = monochrome) | `color.neutral.400` skeleton, monochrome (grayscale métallique #131B22→#B9BABC) | « Reconnexion… » | 05 §3.7 l.1290 ; S9 §9.1 killed row |
| Contenu (sous-tâches + matrice) | Le mirror local s'affiche **sous** le skeleton (AD-7, jamais d'écran blanc, l.1294) | `color.neutral.400` skeleton + contenu local visible | — | 05 §3.7 l.1290–1301 ; AD-7 |
| CTA focus | Reste actif (le focus mode est local, eisenhower.md §10) | `color.brand.primary` | « Lancer le focus » | eisenhower.md §10 ; WDS 05.5 §7 |

---

## §5 Micro-interactions (table GPU-only, 150–250 ms, smooth — ui-libraries S5 l.169)

| Élément | Action → Feedback | Durée | GPU-only (transform+opacity) | smooth | reduced-motion=statique | SSoT |
|---|---|---|---|---|---|---|
| Sheet (ouverture) | Slide-up (translateY 100 %→0, 250 ms) | 250 ms `anim.normal` | `transform: translateY` | ease-out (pas bouncy, S3 l.143) | statique (S5 ; §2.6 r.2) | 05 §2.6 ; motion.tsx @aurora/ui REVEAL_TRANSITION ; WDS 05.5 §Interactions |
| Ligne sous-tâche (tap) | Press feedback (scale 0.98, 150 ms) + toggle Checkbox (success, 150 ms) | 150 ms `anim.fast` | `transform: scale` | linear | statique | 05 §2.6 l.314 ; S5 ; 05 §3.2 l.457 (pressed = verrouillé + success) |
| CTA focus | Press feedback (scale 0.98, 150 ms) + transition page (200 ms) | 150+200 ms | `transform: scale` + fade | ease-out | statique | motion.tsx @aurora/ui PAGE_TRANSITION ; 05 §2.6 |
| Toast | Slide-in bas (translateY + opacity, 250 ms) | 250 ms | `transform: translateY`, `opacity` | ease-out | statique | S6 l.183 ; 05 §2.6 |
| Skeleton (loading) | Pulse (opacity 0.6→1, 1.2 s loop) | 1200 ms loop | `opacity` | ease-in-out | **pas de pulse, statique** (§2.6 r.2 ; S5) | 05 §2.6 l.343 ; S5 |
| Sheet (fermeture swipe-down) | Slide-down (translateY 0→100 %, 200 ms) + fade | 200 ms `anim.normal` | `transform: translateY`, `opacity` | ease-out, pas bouncy (S3 l.143) | statique | WDS 05.5 §Interactions ; motion.tsx @aurora/ui |
| Mini-matrice (surlignage) | **Aucune animation** — la donnée n'est jamais animée (§2.6 règle 1 : « les données ne s'animent jamais ») | — | — | — | statique | 05 §2.6 l.310 (règle 1) ; WDS 05.5 §6 (quadrantOf = pure, pas de serveur) |

> **Règle 1 (§2.6)** : les données (sous-tâches, % complétées, position Q) **ne s'animent jamais** (pas de réordonnancement, pas de trace qui se dessine). **Règle 4** : aucune animation ne bloque l'input. **Mobile** : pas de layout animation (S5 l.169 ; motion.tsx @aurora/ui spring-free 200 ms ease-out). **Reduced-motion** : toutes animations → statiques ; skeleton = pas de pulse (§2.6 r.2 ; aurora.css media query durations → 0.01 ms).

---

## §6 Modals / BottomSheets

| Élément | Type | Déclencheur | Contenu | Fermeture | SSoT |
|---|---|---|---|---|---|
| **BottomSheet full** (l'overlay lui-même) | BottomSheet (05 §3.5 l.787–808, S1 l.13–14) | Tap `KanbanCard` (S-05) / tap ligne `taches-liste` (S-32) / deep link `/tasks/:id` (notification locale) | 3 zones : Header (titre + badges) ; Sous-tâches (liste `RoutineStep` + compteur) ; Mini-matrice (4 cases, Q surlignée) ; CTA focus bas | **Swipe-down** (retour au board, invariant S6.2) / Back Android (descend le sheet, 05 §3.5 l.801–802) / Tap hors zone | WDS 05.5 §2 (4 entrées) ; 05 §3.5 ; router.tsx l.107–108 (detail-over-tab) ; 02 §6.1 l.390 |
| Menu contexte (actions sous-tâche) | Menu (05 §3.5 l.843–854, shadcn) | Long-press ligne sous-tâche | Modifier / Supprimer (destructive, confirmé par Modal §3.1) | Tap item / tap hors | 05 §3.5 l.843 ; S3 (pas de menu natif Android) |
| Modal confirmation destructive | Modal (05 §3.5 l.761–785) | Tap « Supprimer » dans le Menu | Body 1 ligne + CTA « Supprimer » (destructive) + ghost « Annuler » | Back Android / tap hors (le formulaire est auto-persisté, 02 §6.3) | 05 §3.1 l.377–379 (destructive **toujours** confirmé) ; 05 §3.5 l.761 |

> Le détail lourd (une tâche avec sa propre TopBar + routing = une **route**, 02 §6.1) n'existe **pas** ici : l'overlay est un **détail léger** (BottomSheet), jamais une route push (pack 02 §6.1 : « le détail lourd = une route ; le détail léger = une BottomSheet », §4 intro l.1326–1328).

---

## §7 Formulaires

| Champ | Composant | Validation | SSoT |
|---|---|---|---|
| (aucun formulaire inline dans l'overlay) | — | — | — |
| Saisie sous-tâche (optionnelle, hors chemin court) | shadcn `TextField` (05 §3.2 l.420–436 ; S3 **interdit** `ion-item`) | `maxLength` 60 car. (aligné titre tâche ≤ 60, WDS 05.5 §6) ; erreur inline `danger` (jamais dans une Toast, 05 §3.2 l.416–417) | 05 §3.2 ; S3 l.137 ; OQ-2 WDS 05.5 close A (liste plate = pas de sous-formulaire, juste un checkbox) |

> L'overlay est **lecture + toggle** (checkbox) ; toute création de sous-tâche (si présente, hors chemin court) = shadcn TextField (S1) + BottomSheet de capture (§3.5), **jamais** un `ion-item` (S3 l.137 interdit).

---

## §8 Pagination / Tri / Filtres

| Règle | Paramètre | Valeur | SSoT |
|---|---|---|---|
| **Pagination** | **N/A** (pas de pagination sur l'overlay) | L'overlay = 3 zones fixes (Header / Sous-tâches / Mini-matrice) + 1 CTA (AD-14, WDS 05.5 OQ-1 close A) ; le volume de sous-tâches est **borné** (typ. 3–10 ; si > 10 = un `Menu` « Plus de sous-tâches… » qui ouvre la liste complète, 05 §3.5 l.851 — règle max 6 items dans un Menu, **au-delà = 2ᵉ niveau**) | WDS 05.5 §6 ; 05 §3.5 l.843–854 ; AD-14 |
| **Tri** | **N/A** (pas de tri dans l'overlay) | L'ordre des sous-tâches = **numérotation** de la routine (`RoutineStep` : l'ordre **est** l'information, pas un bullet générique — 05 §3.6.12 l.1232–1236) ; pas de retri par l'utilisateur (la routine = un objet figé, l'étape = sa partie, l.1240–1242) | 05 §3.6.12 |
| **Filtres** | **N/A** | L'overlay est le **détail** d'une tâche unique (`/tasks/:id`) — pas de filtre ; le tri/filtre des tâches vit dans `taches-liste` (S-32, WDS 05.3 OQ-1) ou `kanban` (S-05, 05.4 OQ-1) ; l'overlay **n'en a pas** (règle §12 « simple en surface » : 1 écran = 1 objet) | 05 §3.1 intro ; WDS 05.5 §6 ; 05 §12 (simple en surface) |

> **Règle de pagination unique** (ui-libraries S8 l.304–307 : <20 = Table/scroll, 20–100 = +pagination, >100 = AG Grid) : **ne s'applique pas ici** — l'overlay n'a pas de liste plate ; la sous-liste est **courte** (bornée par la routine) ; si elle dépassait 20 items = `Menu` (05 §3.5 l.851), pas de shadcn Pagination (S1 l.37). Le Pager jour/semaine/mois (05 §3.4 l.737–749) = écran Calendrier/Gantt, **pas** l'overlay tâche.

---

## §9 Transitions entre écrans (GPU-only, §2.6 ; motion.tsx @aurora/ui)

| Transition | Direction | Durée / curve | GPU-only | SSoT |
|---|---|---|---|---|
| Ouverture (Kanban → overlay) | `kanban` (S-05) → `BottomSheet full` `/tasks/:id` (par-dessus, le board **reste** visible) | 250 ms slide-up (REVEAL_TRANSITION) | `transform: translateY` + `opacity` | WDS 05.5 §2 (entrée primaire) ; 05 §4.3.3 l.1614–1618 ; motion.tsx @aurora/ui REVEAL_TRANSITION |
| Ouverture (liste → overlay) | `taches-liste` (S-32) → overlay `/tasks/:id` | 250 ms slide-up | idem | WDS 05.5 §2 ; 05 §4.3.1 l.1417 |
| CTA focus → matrice (S-39) | `/tasks/:id` → `/tasks` (taskView→eisenhower, S-39, 05.6) | 200 ms fade + y (PAGE_TRANSITION) ; le sheet **se ferme** d'abord (200 ms slide-down) puis le push | `transform` + `opacity` | WDS 05.5 §4 (CTA focus enclenche la session) ; eisenhower.md §4 ; motion.tsx @aurora/ui PAGE_TRANSITION |
| Retour (swipe-down) | overlay → board Kanban (invariant S6.2 : **retour au contexte**, pas à une liste) | 200 ms slide-down + fade | `transform` + `opacity` | WDS 05.5 §6 (swipe-down = close) ; invariant S6.2 ; 05 §4.3.3 l.1616–1618 |
| Retour natif (Back Android) | descend le sheet (ferme à `peek` puis entièrement, pas de saut direct, 05 §3.5 l.801–802) | 200 ms | idem | 05 §3.5 l.801–802 |

> **Règle 1 (§2.6)** : les données (sous-tâches, % complétées, Q) **ne s'animent jamais** ; les transitions **n'entrainent pas** de re-render du board en arrière-plan (le sheet est superposé, pas un push qui masque, WDS 05.5 §10 : TTI < 300 ms, le contenu est local). **Reduced-motion** : toutes transitions = statiques (§2.6 r.2). **Pas de bouncy** (S3 l.143). **Pas de `layout` animation** (S5 l.169).

---

## §10 Thèmes (10 + 3 presets, par couche — AD-17 ; 05 §5.2 l.2961)

| Couche | Comportement par thème (exemples, **jamais** de valeur par thème) | SSoT |
|---|---|---|
| L1 Neutral (fond/texte) | `neutral.light #FFFFFF` / `neutral.dark #121212` (figé) appliqué au fond du sheet, au texte des sections ; les 10 thèmes + 3 presets changent **seulement** L1/L2/L3 (AD-17) | 05 §5.1 l.2931 / §5.2 l.2961 ; AD-17 (ui-libraries) |
| L2 Expressive (brand) | Couleur de marque par thème (Aurora `#3678F6`, Lagoon, Sakura…) appliquée au **CTA focus** (fond `primary`) et au surlignage de la **case Q occupée** dans la mini-matrice ; le Nocturne (preset) = L2 désaturé (grayscale, cf. §9.1 row Nocturne) | 05 §5.2 ; WDS 05.5 §5 (variante Nocturne : Q1 = `accent`/`success`) |
| L3 Override local | `--brand-*` override utilisateur (si l'user a personnalisé) sur le CTA focus et la case Q surlignée | 05 §5.2 l.2961 ; `packages/ui` theme-adapter (OQ-15 V1) |
| **Règle bloquante 05 §5.1 l.2931** | Les thèmes **ne re-définissent jamais** `success/warning/danger/info` : les **Badges statut** (5 statuts, §4(c)) restent les couleurs sémantiques **fixes** (figées L1), quel que soit le thème (10 + 3) ; le surlignage Q1 = `accent` (thème), **pas** `success` (figé L1) | 05 §5.1 l.2931 ; §5.2 l.2961 |
| Presets (3) | `slate` / `nocturne` / `high-contrast` : le **Nocturne** (défaut Horeb, WDS 05.5 §5) = fond sombre + L2 désaturé ; **High-Contrast** = tap targets 56 px, logo monochrome (§9.1 row Nocturne + High Contrast) ; `slate` = neutral | 05 §5.5 l.3153 ; §9.1 (row Nocturne + High Contrast) ; WDS 05.5 §5 |

> AD-17 (ui-libraries) : **tokens uniquement** — aucune valeur couleur/espacement/typo/radius brute dans l'écran. Le thème est une **peau** : seul L1/L2/L3 bouge ; les couleurs sémantiques (5 statuts §4(c), les états S6 : error/offline/killed) sont **figées** (L1). Les 10 thèmes + 3 presets = comportement par couche, **jamais** une valeur par thème (05 §5.2 ; ui-libraries S4 l.145–160 : l'intégration est via CSS variables, pas via code).

---

## §11 Accessibilité (WCAG AA — 05 §6.3)

| Règle | Valeur | SSoT |
|---|---|---|
| Cibles tactiles | ≥ 44 px (56 px High Contrast) sur : chaque Checkbox sous-tâche (44 px, 05 §3.2 l.451), CTA focus (44 px md, 05 §3.1 l.380), icônes menu, case Q surlignée (tap = voir S-39) | 05 §6.3 ; WDS 05.5 §10 (30 fps, 540 px — OQ-11) |
| `aria-label` | Toute icône-button a un `aria-label` textuel : icône chevron (retour), icône menu, icône toggle ; le `Checkbox` sous-tâche a un `aria-label` = le titre de la sous-tâche (ex. « Révisions RDM 30 min, non faite ») ; la mini-matrice a un `role="img"` + `aria-label` = « Position de la tâche dans la matrice : Q1 (urgent + important) » | 05 §6.3 ; a11yRefs (goal-card.tsx, AgentThinkingLoader.tsx : pattern aria-label + role) |
| `letter-spacing` | 0 sur tous les corps (pas de tracking positif) | 05 §6.3 |
| Focus visible | Anneau focus (2 px `focus-ring`, §6) sur CTA focus, Checkbox, menu items ; le focus **reste visible** dans le sheet (pas de focus trap qui le cache) | 05 §3.1 l.382–383 ; §6.3 ; `packages/ui` focusTreatment (aurora.json) |
| Contraste | Ratios AA (4.5 : 1 texte, 3 : 1 UI) sur les badges statut (5 couleurs figées L1, §4(c)), le CTA focus (`primary` + `on-primary`), la case Q surlignée (`accent` + `on-accent`) | 05 §6.3 ; 05 §5.1 l.2931 (couleurs figées = contraste constant) |
| `reduced-motion` | Toutes animations §5/§9 → statiques ; Skeleton = pas de pulse ; la transition sheet = instantanée | 05 §2.6 r.2 ; S5 (ui-libraries l.169) ; `packages/ui` useReducedMotion (theme/provider.tsx) |
| Ordre de lecture | Header (titre h + badges) → Section sous-tâches (numéro 1., 2., 3. + titre + état) → Mini-matrice (4 cases, légende « Q1 urgent + important ») → CTA focus ; la numérotation `RoutineStep` = l'ordre de la routine (l'information, pas un décor, 05 §3.6.12 l.1234–1236) | 05 §6.3 ; 05 §3.6.12 ; WDS 05.5 §6 |

---

## §12 Offline (classe offline = master-feature-catalog L19 ; AD-7)

| Aspect | Valeur | SSoT |
|---|---|---|
| Classe offline | `productivity.tasks` = **offline-capable** (catalog L19 : « offline-capable; core ») ; l'overlay `/tasks/:id` **n'est** qu'une **vue** de cette classe → il est **toujours lisible** hors-ligne (AD-7) | master-feature-catalog L19 ; AD-7 (02 §7 l.462–493) |
| Miroir local (AD-7/AD-12) | Les **sous-tâches** et la **mini-matrice** sont **chargées depuis le mirror local** (PowerSync/SQLite, pack 03 §5.5 : le mirror est le SSoT local, le cloud est le SSoT distant) ; le CTA focus reste **actif** (le focus mode est **local**, `docs/focus-mode/spec.md` §4 ; eisenhower.md §10 : « matrix fully functional offline, agent suggestions degrade to rule-based local ») ; la mutation (toggle checkbox) = `LocalCommandRepository.apply('productivity', toggleSubtask(id))` en **queue upsync** (pack 03 §4.2 : mutation queue for upsync ; pack 03 §5.5 : re-sync au retour) | WDS 05.5 §6/§7 (offline = état premier) ; AD-7 ; eisenhower.md §10 ; `docs/sync/overview.md` §4.2/§5.5 |
| Dégradation AD-1 | Si le flux agent (capture par voix/chat) est **offline** (cloud kill), **AD-1** = saisie manuelle (champ texte shadcn, S1 l.13) ; l'overlay **n'a jamais** de bloc « suggestion agent » (AD-14 : jamais de proposition libre, WDS 05.5 §6) ; la mini-matrice reste **computed** (`quadrantOf`, pure function, eisenhower.md §5 : « no server ») — elle **ne meurt pas** | master-feature-catalog L34 (AD-1) ; eisenhower.md §5/§10 ; WDS 05.5 §6 (offline = état premier) |
| Ce qui meurt (killed, G-M2) | Le **sync upsync** (la mutation queue est **en attente**, pas perdue — AD-7 : le local reste, l'upsync attend) ; le **suggestion agent** (dégradé en rule-based local, eisenhower.md §10) ; le **scan** (cloud, **désactivé** — l'overlay n'en a pas, mais la classe tasks L19 le porte) ; l'overlay **lui-même ne meurt jamais** (il est une vue du mirror, AD-7) ; l'état **killed** (05 §3.7 l.1290–1301) = le relaunch cold **part du mirror** (jamais d'écran blanc, l.1294) + bannière « Reconnexion… » + auto-resync en arrière-plan (l.1293) ; le CTA focus **reste actif** (local) | 05 §3.7 l.1290–1301 ; eisenhower.md §10 ; AD-7 ; G-M2 |
| État offline affiché | Bandeau fine top-bar (05 §3.7 l.1258) : Badge « Hors-ligne » + **le contenu (sous-tâches + matrice) est affiché** (lecture locale, AD-7) ; le CTA focus **est actif** (local) | 05 §3.7 l.1258 ; WDS 05.5 §7 (état offline) ; AD-7 |

> L'overlay est **premier état offline** (AD-7) : on **lit** les sous-tâches, on **voit** la Q, on **tapes** le CTA focus **sans réseau** ; seules les **mutations en attente d'upsync** (sync) et les **suggestions agent** meurent (dégradées en local).

---

## §13 Occurrences du logo (S9 l.349–369 ; §9.1 l.371–405 ; §9.3 l.420–487)

| Occurrence | Version du logo (S9 l.349–369) | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| **In-app par défaut** (header du board Kanban en arrière-plan, visible **derrière** le sheet) | **Coloré, sans fond** (`assets/aurora_icon_a_integre_dans_l'applciation.png`) — l'unique version in-app autorisée (§9 l.352–353 : « in-app header = colored without background, **never** the full app icon ») | Le board est le **contexte** (invariant S6.2) : le logo coloré au header = la marque **vivante** (le board reste monté, l'overlay est superposé — la marque **ne se coupe pas**) | S9 §9 l.352–353 ; §9.1 l.382 (matrice : in-app default = coloré) ; WDS 05.5 §6 (le board reste visible) |
| **État killed** (bannière, §4(d)) | **Monochrome** (grayscale métallique #131B22→#B9BABC, §9.1 killed row) | Le monochrome = état dégradé / signal faible : le kill = « la marque est présente mais ne parle plus » (§9.1 l.374–376 : « neutralité / attente / inactif ») — ne pas alerter en couleur (le danger = `color.danger` figé L1, pas le logo) | §9.1 killed row ; WDS 05.5 §4(d) ; 05 §3.7 l.1290 |
| **État 404** (route `/tasks/:id` invalide, §4(b)) | **Coloré, sans fond, CENTRÉ** (§6.1 state 404 ; §9.1 404 row) — le 404 est le **seul** état qui **mande** le logo coloré centré (reconfort + rebranding, pas un crash) | Le 404 = l'erreur la plus probable (WDS 05.5 §1) : le logo coloré centré = « la marque est **active** (pas morte) » (living empty state, §9.1 404 row : « active brand = colored ») + le CTA « Retour à l'accueil » (primary) = la prochaine action (AD-14) | §6.1 (state 404) ; §9.1 (404 row) ; WDS 05.5 §4(b) |
| **Presets Nocturne / High-Contrast** | **Monochrome** (§9.1 row Nocturne + High Contrast presets : « desaturated / high-contrast universes ; les 10 thèmes expressifs = coloré ») | Le Nocturne (défaut Horeb, WDS 05.5 §5) = le mode **nuit** : le monochrome = « la marque est là, mais ne se fait pas d'argent » (§9.1 l.374–376 : inactif) — ne pas surligner en couleur dans un thème sombre (la couleur = pour les actions, pas pour le chrome) | §9.1 (row Nocturne + High Contrast) ; WDS 05.5 §5 (variante Nocturne) |
| **AgentThinkingLoader** (N/A ici) | Monochrome **animé** (§9.3 l.420–487 : l'unique exception animée, GPU-only l.426–431, a11y l.457–462) | Ne s'affiche **pas** sur cet écran (l'overlay **n'a jamais** de « l'agent réfléchit » — le CTA est **fixe**, AD-14 : jamais une proposition libre de l'agent, WDS 05.5 §6) ; cité pour exhaustivité S9 | §9.3 l.420–487 ; AD-14 (05 l.368) ; WDS 05.5 §6 |

> **Interdits (S9 l.390–392)** : l'icône applicative **full** (fond arrondi) dans l'app UI (l.390 : « the full (background) version inside the app UI = FORBIDDEN ») ; **jamais** de logo **monochrome** dans un état **vivant** (un EmptyState avec CTA = coloré, l.391 : « monochrome in a living empty state = FORBIDDEN ») ; **aucun** recolor (l.392) ; **jamais** de redessine / génération / détour (l.352–353 : « do NOT redraw, do NOT generate, do NOT fetch a logo from anywhere else »). La **watermark 8 %** = application **unique** sur le QCM (pas sur cet écran, §9.1 l.394). **Usage ad hoc interdit** : la mini-matrice **n'a pas** de logo (c'est une vue de données, pas une surface de marque).

---

## §14 Questions ouvertes (OQ)

| # | Question | Contexte / SSoT manquante | Statut |
|---|---|---|---|
| **OQ-1** | **Route / deep-link exacte** : le WDS 05.5 §2 (entrée 3) dit « deep link `/tasks/:id` (notification locale « tâche due ce soir », automatisation) » — mais le **format du paramètre** `:id` (UUID v4 ? slug ?) **n'est pas figé** dans le SSoT ; le router.tsx (S1, detail-over-tab) dit `/tasks/:id` mais pas le **schéma** de l'id. | WDS 05.5 §2 entrée 3 ; router.tsx l.107–108 ; `UserContext` AD-15 (l'id = `Task.id` SSoT, pas dans le digest) | **À trancher** (à trancher avec le SSoT `UserContext` / `Task` domain model, pas avec l'écran) |
| **OQ-2** | **Composant `MiniMatrix`** : la mini-matrice (4 cases compactes, §6.1 l.189–202 : « vue en contenu S-39, pas l'écran quadrant ») **n'existe pas** dans `packages/ui` (composants DS = DataTable / Timeline / GanttRow / StatTile / KeyValueList / CalendarView / AgGridTable, **pas** de `MiniMatrix`). Le SSoT dit « 4 cases compactes » mais **pas** le composant (shadcn `Card flat` ? nouveau `MiniMatrix` ?). | 05 §3.3 l.498–511 (`Card`) ; 05 §3.6.12 (`RoutineStep`, pas de matrice) ; S1 (ui-libraries l.13–14 : batterie shadcn, pas de MiniMatrix) ; WDS 05.5 §6 (OQ-1 close A = 3 zones, mais le composant matrice **n'est pas** figé) | **À trancher** (à trancher avec le SSoT `packages/ui` / `05-design-system` §3.6 : faut-il créer `MiniMatrix` ou réutiliser `Card flat` + 4 divs ?) |
| **OQ-3** | **Formulation exacte du message 404** : le SSoT (§6.1 state 404) dit « short message » mais **pas le texte** (ex. « Tâche introuvable. Elle a peut-être été supprimée ou le lien est invalide. » — proposition de ce document, **non figée** par SSoT). | §6.1 state 404 ; §9.1 (404 row : logo centré, pas le message) ; cf. OQ-9/OQ-10 kanban.md (même pattern : message 404 non figé) | **À trancher** (à trancher avec le SSoT du 404 global, pas cet écran) |
| **OQ-4** | **Position exacte du CTA focus** : le WDS 05.5 §6 (OQ-3 close) dit « bas de l'overlay » mais **pas** si le CTA est **full-width** (bouton pleine largeur, recommandation) ou **centré** (bouton 56 px, 05 §3.1 `size=lg`) ; le **libellé exact** « Lancer le focus » (WDS 05.5 §4, propose, **non figée** par SSoT §3.1). | 05 §3.1 l.367–390 (Button, `size=md`/`lg`) ; WDS 05.5 §4/§6 (CTA focus, AD-14) ; eisenhower.md §4 (CTA focus après placement Q1, pas le libellé) | **À trancher** (à trancher avec le SSoT `05-design-system` §3.1 : `size=lg` full-width ou `size=md` centré ?) |
| **OQ-5** | **Filtre / tri des sous-tâches** : le WDS 05.5 (OQ-2 close A) dit « liste plate de checkboxes, style `RoutineStep` » — mais si une tâche a **> 10 sous-tâches**, le SSoT dit « un Menu « Plus de sous-tâches… » qui ouvre la liste complète » (05 §3.5 l.851, règle max 6 items) — **le seuil** (10 ? 15 ?) et le **libellé** du Menu **ne sont pas figés** par SSoT. | 05 §3.5 l.843–854 (Menu, max 6 items, l.851) ; WDS 05.5 OQ-2 close A (liste plate) ; `RoutineStep` (05 §3.6.12, pas de seuil) | **À trancher** (à trancher avec le SSoT `05-design-system` §3.5 : seuil du Menu « Plus… ») |
| **OQ-6** | **Sémantique du compteur « en cours »** : le §4(b) cite §6.1 l.197 (`en-cours` = opération **running avec résultats partiels**, progress mesurable) pour le compteur sous-tâches, mais le SSoT ne fige ni le **libellé exact** ni la sémantique : 1/3 = « sous-tâche courante » (étape active d'une routine séquentielle) ou « 1 sur 3 **en cours** » (plusieurs `doing` simultanément) ? Pas de SSoT pour le libellé/la sémantique. | §6.1 l.197 ; WDS 05.5 OQ-2 close A (liste plate) ; 05 §3.6.12 (`RoutineStep` séquentielle, pas de sémantique multi-doing figée) | **À trancher** (libellé exact + sémantique du compteur « x/y en cours », standup Phase 4) |

> **Règle de discipline** : toute règle de ce document cite sa SSoT (doc § ou fichier : ligne). Quand une règle **n'a pas** de SSoT (ex. le texte du 404, le libellé du CTA, le seuil du Menu, le libellé du compteur « en cours ») → elle est **OQ** (ici §14), **jamais** une spec muette, **jamais** un « à décider » masqué dans le corps. Les 6 OQ ci-dessus sont **le** SSoT manquante de cet écran (à trancher au standup Phase 4, WDS 05.5 §8).
