# Écran — Habitudes (`habitudes`)

Module : Productivité · Route : `/habits` · Statut : **détaillé** · SSoT écran : `05-design-system` §4.3.5 l.1699–1786 + WDS `05.1-habitudes` (OQ-1…OQ-3 closes) + `master-feature-catalog` L24 `productivity.habits` (offline-capable)

---

## §1 Psychologie du designer

| Dimension | Valeur |
|---|---|
| Objectif utilisateur | Lire le **pattern** d'adhérence de mes habitudes (heatmap `HabitStreak` + chiffre de streak) et **boucler la journée en 1 tap** (check-in « Marquer aujourd'hui »). |
| Contexte | Mobile Pixel 4a, 22 h 30 chambre, thème Nocturne (OQ-16 WDS), réseau 3G Bénin instable : l'écran est conçu **offline-d'abord** (AD-7) — le check-in du soir ne doit jamais mourir faute de réseau (WDS 05.1 §3). |
| Fréquence | Quotidienne (check-in = boucle du soir / de la routine) ; lecture heatmap à chaque ouverture du bloc « Habitudes/Routines » de Home (AD-14). |
| État émotionnel cible | Calme de clôture : « ma chaîne tient, je la referme » — jamais le sentiment d'un compteur de tâches ni d'un dashboard de widgets (trigger-map §6 trap « Surcharge de widgets »). |
| Erreur la plus probable | Ouvrir l'écran en pensant qu'on peut « rattraper » le tap d'hier dans une fenêtre de tolérance — le check-in est **le jour courant, 1 tap, aucune heure limite** (WDS 05.1 OQ-1 close A) ; ou croire que le tap « Marquer aujourd'hui » a besoin du réseau (faux — écriture locale AD-7). |
| Ce que l'écran RÉSOUT | « Est-ce que ma régularité tient ? » en **1 heatmap + 1 chiffre** (le chiffre parle, la heatmap est la preuve — 05 §3.6.12), et résout le bouclage du jour **sans réseau** (05 §4.3.5 `offline`). |
| Invariant AD-14 | « Marquer aujourd'hui » = **seul CTA d'action** de la surface, fixe, jamais conditionnel, jamais remplacé par une suggestion d'agent (WDS 05.1 §Budgets ; 05 §4.3.5). |

---

## §2 Zones de l'écran (100 % — 05 §4.3.5 l.1708–1725)

| Zone | Contenu | SSoT |
|---|---|---|
| TopBar | Titre « Habitudes » + 1 `Menu` (icône `more`) : « Routines » (routines = mode séparé, écran S-09) · « Adhérence » (analyse) | 05 §4.3.5 l.1709 ; 05 §3.4 TopBar l.659 |
| Content | Liste verticale de **`Card flat`** (1 par habitude) : titre + `HabitStreak` heatmap (7 semaines mobile — WDS 05.1 OQ-2 close A) + `KeyValueList` compact « streak courant » + `Button secondary` « Marquer aujourd'hui » (tap unique) | 05 §4.3.5 l.1712–1725 ; 05 §3.6.12 l.1218–1231 |
| FAB | « + Créer une habitude » → `BottomSheet` de création (`TextField` titre + `SegmentedControl` quotidien/hebdo + `Select` heure) | 05 §4.3.5 l.1769–1774 |
| Footer | `BottomNav` 5 tabs (S-31 shared : Home · Tâches · Apprendre · Progression · Coach — le 5ᵉ = `/agent`) | WDS 05.1 §2 OQ-3 close C ; 05 §3.4 l.670–691 |
| Surfaces flottantes | `BottomSheet` détail d'habitude (analyse) ; `BottomSheet` création ; `Menu` TopBar ; `Toast` feedback | 05 §4.3.5 l.1752–1774 ; 05 §3.5 l.752 |

> **N/A** : aucune sous-vue `Tabs` sur l'écran (les routines vivent dans l'écran S-09, pas dans un tab — 05 §4.3.5 l.1710–1711).

---

## §3 Éléments de l'écran (table 100 % de la zone)

| # | Élément | Composant DS 05 §3 | lib ui-libraries S1 | Tokens (AD-17) | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| E1 | Titre « Habitudes » | `TopBar` (05 §3.4) | shadcn (texte, 05 §3.4 l.659) | `text.md` 600, `color.neutral.900/100`, TopBar h=56 px | même mobile/desktop | 05 §3.4 l.659–667 |
| E2 | Menu TopBar (« Routines » / « Adhérence ») | `Menu` + icône `more` (05 §3.4, 2ᵉ action = Menu) | shadcn Menu/Dropdown (S1 l.17) | `icon.size=20`, `touch.target=44` (HC 56) | même | 05 §4.3.5 l.1709–1711 |
| E3 | Card habitude (container) | `Card` flat (05 §3.3 / §4.3.5) | shadcn Card (S1 l.12) | `color.neutral.900/100`, `radius=8` max (S3 l.142), `spacing.m` | **2 colonnes en grille desktop** | 05 §4.3.5 l.1713 + l.1776–1777 |
| E4 | Titre de l'habitude | texte dans Card | shadcn Text | `text.sm` 600, `color.neutral.900/100` | même | 05 §4.3.5 l.1714 |
| E5 | Heatmap d'adhérence | `HabitStreak` (05 §3.6.12 l.1218–1231) | **composant DS maison** (`packages/ui`, pas dans S1 → **OQ-1** §14) | `habit-weak`/`habit-med`/`habit-strong` (05 §2.1.2 l.155), niveau 0 = `bg-subtle`, cellules 12×12 px | **12 semaines desktop vs 7 mobile** (05 §4.3.5 l.1778–1784) | 05 §3.6.12 ; WDS 05.1 OQ-2 close A |
| E6 | Streak courant « N jours » | `KeyValueList` compact (05 §3.6 / §4.3.5) | **KeyValueList** (AD-10 DS data, 05 §3.6) | `font.mono` (JetBrains Mono `lg`) + valeur | même | 05 §4.3.5 l.1723–1724 ; WDS 05.1 OQ-3 close |
| E7 | CTA « Marquer aujourd'hui » | `Button` secondary (05 §3.1 / §4.3.5) | shadcn Button (S1 l.11) | `color.neutral.900/100`, `touch.target=48` (HC 56), `radius=8` | même, **toujours visible** (AD-14) | 05 §4.3.5 l.1717–1721 ; WDS 05.1 §Budgets |
| E8 | `Badge` « à resync » (error) | `Badge` (05 §3.3) | shadcn Badge (S1 l.31) | `color.danger` (figé, 05 §5.1) | même | 05 §4.3.5 l.1742–1744 |
| E9 | `EmptyState` (0 habitude) | `EmptyState` (05 §4.3.5) | shadcn Card empty variant (S6 l.182) | icône « habitude », `text.sm`, CTA | même | 05 §4.3.5 l.1733–1740 |
| E10 | `Skeleton` Card (loading) | `Skeleton` (05 §3.7 l.1261) | shadcn Skeleton (S6 l.180) | `color.neutral.400`, `anim.slow` (pulse) | même | 05 §4.3.5 l.1731–1732 |
| E11 | Badge top-bar « Hors-ligne » | `Badge` top-bar (05 §3.7 l.1258) | shadcn Badge | `color.neutral.400`, `icon.size=16` | même | 05 §3.7 l.1258 |
| E12 | FAB « + Créer une habitude » | `FAB` (05 §3.1, vit **au-dessus** de la BottomNav) | shadcn Button variant (S1 l.11) | `color.brand.primary` (L2 du thème actif), `touch.target=56` (FAB), `radius=8` | même | 05 §3.4 l.685 ; 05 §4.3.5 l.1769 |
| E13 | `BottomNav` 5 tabs | `BottomNav` (05 §3.4 l.670–691) | shadcn (S1 l.35) | `icon.size=24`, label `xs`, h=56 px + safe-area, tab actif = pill `primary-surface` | desktop = side nav (S1) | 05 §3.4 l.670–691 ; WDS 05.1 OQ-3 close C |
| E14 | BottomSheet détail (analyse) | `BottomSheet` (05 §3.5 l.787) : `Timeline` §3.6.3 (reports) + `HabitStreak` étendu 12 mois + `KeyValueList` routines perturbatrices | shadcn Sheet/Drawer (S1 l.13–14) | `color.neutral.900/100`, `radius=8` | même | 05 §4.3.5 l.1752–1768 |
| E15 | BottomSheet création | `BottomSheet` : `TextField` (Input shadcn) + `SegmentedControl` quotidien/hebdo (05 §3.4 l.711–723) + `Select` d'heure (05 §3.2 l.412) | shadcn Sheet + Input + Select (S1 l.13–15,17) ; `SegmentedControl` = **pas dans S1 → OQ-2** §14 | `touch.target=44`, `radius=8` (segment = radius `full` sur le track, 05 §3.4 l.716) | même | 05 §4.3.5 l.1770–1774 |
| E16 | `Toast` feedback (succès) | `Toast` (05 §3.5 l.823) | shadcn Toast (S1 l.29, S6 l.183) | `color.success`, auto-dismiss 3 s | même | 05 §3.5 ; S6 l.183 |

> **S3 (ui-libraries l.133–143)** : `ion-calendar` / `ion-list` data / `ion-item` forms / `ion-datetime` **interdits** — la création d'habitude n'a **pas** de champ horaire `ion-datetime` (règle S3 l.138 → FullCalendar + Popover si besoin ; ici le `Select` d'heure shadcn suffit, 05 §4.3.5 l.1773). **1 écran = 1 système de composants (S1)** : tout ici = shadcn + composants DS `packages/ui` ; aucun mélange de 2 libs sur l'écran (S8 l.333).

---

## §4 États de l'écran

### §4(a) Matrice 6 états S6 (AD-13) — élément asynchrone : liste de Cards (`HabitStreak` = DS local, 05 §3.7 l.1284)

| État | Composant | Tokens | Texte exact | CTA | Entrée/Sortie |
|---|---|---|---|---|---|
| **loading** | Skeleton par Card (pulse opacity 0.6→1, 1.2 s, 05 §2.6 l.342–343) + heatmap en skeleton | `color.neutral.400`, `anim.slow` (pulse) | (silencieux) | CTA « Marquer aujourd'hui » **resté actif** (lecture store local, court — 05 §4.3.5 l.1731–1732) ; FAB actif | entrée : fade 150 ms ; sortie : swap liste 250 ms |
| **empty** | `EmptyState` (shadcn Card empty variant, S6 l.182) | icône « habitude », `text.sm`, `icon.size=24` | « Aucune habitude — commencez par une seule, par jour » | CTA « Créer une habitude » (ouvre la BottomSheet E15 — jamais le chemin court AD-14) ; l'`EmptyState` **insiste** sur le « une seule » (doc §12, 05 §4.3.5 l.1738–1739) | fade 250 ms |
| **error** | `Badge danger` **sur la Card** (l'habitude **reste**, AD-7) + heatmap lue read-only du mirror local | `color.danger` (figé, 05 §5.1) | Badge « à resync » sur la Card (libellé exact non figé → **OQ-5** §14) | CTA « Marquer aujourd'hui » **actionnable** (l'écriture est locale) | badge = fade 150 ms |
| **success** | `Toast` (S6 l.183) après sync réussie | `color.success`, auto-dismiss 3 s | « Habitudes synchronisées » (libellé non figé → **OQ-6** §14) | aucune (auto-dismiss) | slide-in bas 250 ms |
| **offline** | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) + liste locale **fonctionnelle** | `color.neutral.400`, `icon.size=16` | « Hors-ligne — données locales » | CTA « Marquer aujourd'hui » **reste possible** : l'écriture est locale, pack 03, **ne doit pas exiger le réseau** (05 §4.3.5 l.1745–1751 ; AD-7) | fade 150 ms |
| **killed** (G-M2) | Skeleton + bandeau « Reconnexion… » (bannière fine DS, 05 §3.7 l.1290–1301) | `color.neutral.400` skeleton + monochrome logo (§9.1 l.383) | « Reconnexion… » | CTA « Marquer aujourd'hui » reste actif (relance depuis le mirror local, AD-7) | entrée : **instantané** (pas d'animation, 05 §2.6 r.2) ; sortie : fade 250 ms |

*Source : 05 §3.7 l.1252–1301 (matrice AD-13 normative : HabitStreak l.1284, Button l.1254, Card l.1257, EmptyState l.1262, Toast l.1269, killed l.1290–1301) ; WDS 05.1 §7 ; S6 l.174–187.*

### §4(b) États sémantiques §6.1 (ui-libraries l.189–202)

| État sémantique | Appliqué ? | Rendu / N/A (raison) |
|---|---|---|
| **en-cours** | N/A | Aucune opération partielle mesurable sur l'écran liste (pas de streaming ni de QCM) — le check-in est **binaire** (tap → brique posée, AD-7) ; le `Progress` % n'a pas de sens ici (§6.1 l.197 ≠ S6 loading) |
| **terminé** | ✓ | **Journée bouclée** : toutes les briques du jour posées → le CTA « Marquer aujourd'hui » passe en **état terminé** : texte « Journée bouclée » + icône `CheckCircle2` (lucide) + `color.success` (le CTA **reste**, il ne disparaît pas — AD-14 « toujours visible »). Libellé exact → **OQ-7** §14. |
| **échec** | N/A | Pas d'échec terminal non réessayable d'une habitude sur la liste (le domain `Habit` n'a pas de statut `failed`) ; le cas d'erreur = S6 `error` transitoire (badge resync) |
| **succès** | ✓ | Transitoire = S6 `success` (Toast, 3 s) — le tap de check-in répond par une Toast « Marqué » (libellé → **OQ-8** §14) |
| **erreur** | ✓ | S6 `error` (badge danger sur la Card, reprise en place, l'habitude reste, AD-7) |
| **404 / not-found** | ✓ | §4(c) ci-dessous (route `/habits` inconnue / deep link défaillant) |

### §4(c) 404 / not-found (route `/habits` — page entière, §6.1 l.202)

| Élément | Valeur | Tokens | Texte exact | CTA | SSoT |
|---|---|---|---|---|---|
| Logo | **Coloré, sans fond, CENTRÉ** (le seul état qui le mandate — §9.1 l.387) | `color.brand.*`, `spacing.xl` | — | — | ui-libraries §6.1 l.202 ; §9.1 l.387 |
| Message court | texte `sm` centré | `color.neutral.700/300` | « Écran introuvable. Retour à l'accueil ? » (libellé non figé → **OQ-4** §14) | — | §6.1 l.202 |
| CTA primaire | `Button` primary | `color.brand.primary`, `touch.target=48` (HC 56) | « Retour à l'accueil » | navigation `/` (home) | §6.1 l.202 |

### §4(d) Killed (tout flux serveur, 05 §3.7 l.1290–1301)

| Élément | Valeur | Tokens | Texte exact | SSoT |
|---|---|---|---|---|
| Bandeau top | Skeleton + bannière fine « Reconnexion… » + logo **monochrome** (§9.1 l.383) | `color.neutral.400` skeleton ; monochrome = tonalité #131B22→#B9BABC sur `surface` (jamais sur le canvas brut) | « Reconnexion… » | 05 §3.7 l.1296 ; §9.1 l.383, l.399–402 |
| Cards | Skeleton (relance depuis le mirror local, **jamais d'écran blanc ni de reset** — AD-7) | `color.neutral.400` | — | 05 §3.7 l.1290–1296 |
| CTA / FAB | Restent actifs (le check-in = écriture locale, AD-7) | `color.brand.primary` | « Marquer aujourd'hui » / « + Créer une habitude » | 05 §4.3.5 l.1745–1751 |

---

## §5 Micro-interactions (table GPU-only, 150–250 ms, smooth)

| Élément | Action → Feedback | Durée | GPU-only (transform+opacity) | smooth | reduced-motion = statique | SSoT |
|---|---|---|---|---|---|---|
| Page (entrée) | Fade + translateY 8→0 | 200 ms `anim.normal` | `transform: translateY`, `opacity` (S5 l.169) | ease-out | statique (S5 ; 05 §2.6 r.2) | polish.tsx `PAGE_TRANSITION` ; 05 §2.6 l.310 |
| Card habitude (apparition) | Fade + translateY 8→0 (le **conteneur** s'anime, **jamais** la donnée de la heatmap — règle 1 §2.6 l.323–329) | 250 ms `anim.normal` | `transform`, `opacity` | ease-out, pas bouncy (S3 l.143) | statique | 05 §2.6 l.323–329 |
| Heatmap `HabitStreak` | **AUCUNE animation de remplissage** (05 §3.6.12 l.1224–1226 : « les cellules *sont*, elles ne se « peignent pas » » ; la case se **remplit immédiatement**, pas de trace) | 0 ms | n/a (statique par design) | n/a | statique (idem, règle 1) | 05 §3.6.12 l.1224–1226 ; 05 §2.6 l.323 |
| CTA « Marquer aujourd'hui » (tap) | Press feedback scale 0.98 → la case du jour apparaît **immédiatement** (écriture locale, AD-7) + Toast succès (si non-bouclé) | 150 ms press ; Toast 250 ms | `transform: scale` | ease-out | statique (le case apparaît sans anim) | 05 §3.6.12 l.1229–1231 ; S5 ; 05 §2.6 l.314 |
| BottomSheet détail / création | Slide-up translateY 100 %→0 | 250 ms `anim.normal` | `transform: translateY` | ease-out, pas bouncy (S3 l.143) | statique (S5) | 05 §2.6 ; 05 §3.5 l.787 |
| `SegmentedControl` (création) | La pilule glisse | 150 ms `anim.fast` | `transform: translateX` | ease-out ; **interdite** en reduced-motion (05 §3.4 l.716–717) | statique | 05 §3.4 l.716–717 |
| Toast succès / error | Slide-in bas (translateY + opacity) | 250 ms | `transform: translateY`, `opacity` | ease-out | statique | S6 l.183 ; 05 §2.6 |
| Skeleton loading | Pulse opacity 0.6→1 (1.2 s, **pas** de shimmer agressif — 05 §2.6 l.342–343) | 1200 ms loop | `opacity` | ease-in-out | **pas de pulse, statique** (05 §2.6 r.2) | 05 §2.6 l.342–343 |

> **Règle 1 (05 §2.6 l.323–329)** : les **données ne s'animent jamais** — le chiffre de streak et les cellules de la heatmap **ne scintillent pas, ne comptent pas** (pas de « compteur » 0→N). **Règle 4 (05 §2.6 l.340–341)** : aucune animation ne bloque l'input (le check-in reste tapable pendant le sync cloud). **Mobile (S5 l.169)** : zéro `layout` animation ; GPU only (`transform` + `opacity`).

---

## §6 Modals / BottomSheets

| Élément | Type | Déclencheur | Contenu | Fermeture | SSoT |
|---|---|---|---|---|---|
| BottomSheet **détail d'habitude** (analyse) | `BottomSheet` (05 §3.5 l.787) | Tap sur une Card | `Timeline` §3.6.3 des **reports** + `HabitStreak` **étendus 12 mois** + `KeyValueList` « routines perturbatrices » qui la **ciblent** (l'habitude « lire » est perturbée par la routine « écran le soir » — ce lien est **affiché**, pas un « insight » mystérieux, §1 « calme ») | Tap hors zone / swipe down / bouton retour | 05 §4.3.5 l.1752–1768 ; 05 §3.6.3 |
| BottomSheet **création d'habitude** | `BottomSheet` (05 §3.5 l.787) | Tap FAB « + Créer une habitude » | `TextField` titre (Input shadcn) + `SegmentedControl` « quotidien / hebdo » (05 §3.4 l.711–723) + `Select` d'heure (05 §3.2 l.412) | Valider → `habits.create` (AD-7 locale) / fermer | 05 §4.3.5 l.1770–1774 |
| `Menu` TopBar | `Menu` (05 §3.5 l.843) | Tap icône `more` | 2 items : « Routines » (→ écran S-09, 05 §4.3.6) · « Adhérence » (→ l'analyse, 05 §4.3.5 l.1711) | Tap item / tap hors | 05 §4.3.5 l.1709–1711 ; 05 §3.5 |
| `Toast` feedback | `Toast` (05 §3.5 l.823) | Après check-in / après sync | « Marqué » (succès, 3 s) / « à resync » (error, 3 s) | auto-dismiss | 05 §3.5 ; S6 l.183 |

> **Pas de Modal plein-écran** sur l'écran liste (le détail **léger** = BottomSheet, 05 §3.4 l.1326–1328 : un détail léger = BottomSheet §3.5 ; le **lourd** (TopBar + sub-nav) = route push — ici l'analyse de l'habitude **reste** dans le BottomSheet, 05 §4.3.5 l.1752).

---

## §7 Formulaires

| Champ | Composant | Validation | SSoT |
|---|---|---|---|
| Titre de l'habitude | `TextField` (Input shadcn) | Obligatoire, `sm` | 05 §4.3.5 l.1771 ; 05 §3.2 l.412 |
| Fréquence | `SegmentedControl` « quotidien / hebdo » (binaire, 05 §3.4 l.711–723) | Exclusif, **immédiat** (lecture locale AD-7) | 05 §3.4 l.711–723 ; 05 §4.3.5 l.1772 |
| Heure de rappel | `Select` (shadcn Select, S1 l.17) | Optionnelle, heure de déclenchement du **check-in** (pas d'`ion-datetime` — S3 l.138) | 05 §4.3.5 l.1773 ; S3 l.138 |

> **Le check-in quotidien est un TAP UNIQUE, pas un formulaire** (05 §4.3.5 l.1718–1721 ; WDS 05.1 §3). Le seul formulaire de l'écran = la **création** d'habitude (BottomSheet E15). Les formulaires utilisent **shadcn/Radix** (S3 l.137 interdit `ion-item`).

---

## §8 Pagination / Tri / Filtres

| Règle | Paramètre | Valeur | SSoT |
|---|---|---|---|
| **Règle unique nommée** | Scroll natif (pas de shadcn Pagination, pas de AG Grid, pas de `Pager` Jour/Semaine/Mois) | La liste d'habitudes = **store local** (AD-7), volume **faible** (doc §12 « simple en surface » : une habitude à la fois, pas 8 — 05 §4.3.5 l.1738–1740) ; le scrolling vertical natif suffit (S8 l.304–307 : **<20 lignes → pas de pagination**, pas d'AG Grid, pas de AG Grid) ; le `Pager` jour/semaine/mois (05 §3.4 l.737–749) = **N/A** ici (c'est le Pager du Calendrier/Gantt, 05 §4.4.1, pas celui d'une liste d'habitudes) | 05 §4.3.5 l.1738–1740 ; S8 l.304–307 ; 05 §3.4 l.737 |
| **Tri** | Habitude **active** (streak le plus long / check-in du jour d'abord) | Tri local, **immédiat** (AD-7) ; pas de re-tri animé (règle 1, 05 §2.6) | 05 §2.6 l.323 ; AD-7 |
| **Filtre** | Aucun filtre d'écran (les routines = l'écran S-09, pas un filtre de cet écran — 05 §4.3.5 l.1710–1711) | N/A | 05 §4.3.5 l.1710 |

---

## §9 Transitions entre écrans

| Transition | Direction | Durée / curve | GPU-only | SSoT |
|---|---|---|---|---|
| Home → Habitudes | `/` → `/habits` (bloc « Habitudes/Routines » AD-14) | 200 ms fade + y (`PAGE_TRANSITION`) | `transform` + `opacity` | 05 §2.6 ; polish.tsx ; WDS 05.1 §2 |
| Habitudes → Routines | Menu TopBar → écran S-09 (`/routines`) | 200 ms fade | `transform` | 05 §4.3.5 l.1711 ; 05 §4.3.6 |
| Habitudes → Adhérence | Menu TopBar → l'analyse (la vue d'adhérence) | 200 ms fade | `transform` | 05 §4.3.5 l.1711 |
| Card → BottomSheet détail | overlay **par-dessus** le tab courant (règle detail-over-tab, 02 §6.1) | 250 ms slide-up | `transform` | 05 §4.3.5 l.1752 ; 05 §3.4 l.1326–1328 |
| FAB → BottomSheet création | overlay par-dessus le tab courant | 250 ms slide-up | `transform` | 05 §4.3.5 l.1769 |
| Retour (BottomSheet / screen) | Retour = le **contexte** (règle de non-surprise, 05 §3.4 l.1325–1328) | 200 ms fade | `transform` | 05 §3.4 l.1325 |

> **Mobile (S5 l.169)** : aucune transition de `layout` ; GPU only. **Reduced-motion (05 §2.6 r.2)** : toutes transitions → **statique** (0 ms). **Pas de bouncy (S3 l.143)**.

---

## §10 Thèmes (10 + 3 presets, par couche — AD-17)

| Couche | Comportement par thème (jamais par valeur, 05 §5.2) | Rendu sur cet écran | SSoT |
|---|---|---|---|
| L1 **Neutral** (fond/texte) | `neutral.light #F8FAFC` / `neutral.dark #0A0E1A` + texte inverse | Fond liste + texte titres des Cards | 05 §5.1/§5.2 |
| L2 **Expressive** (10 thèmes vivants) | Le `accent.primary` du thème actif se lit via `hsl(var(--aurora-accent-primary-h))` (05 §5.4) et **colore le CTA « Marquer aujourd'hui » + le FAB + le pill du tab actif** — la heatmap `HabitStreak` = `habit-weak`/`habit-med`/`habit-strong` (05 §2.1.2 l.155) qui **suivent** le token `habit-*` (pas `accent`) ; le **chiffre de streak** = `font.mono` (JetBrains Mono, 05 §2.2) | CTA + FAB + tab actif = L2 ; heatmap = `habit-*` ; streak = `mono` | 05 §5.2/§5.4 ; 05 §3.6.12 |
| L3 **Override local** (Focus Mode) | **N/A ici** : le Focus Mode (`[data-focus-mode]`, 05 §2.6 r.3) **bloque** les autres surfaces (WDS 05.1 §5 : « si Horeb est en focus, `/habits` est masqué ») — le L3 override = réservé au Focus (V1, OQ-15 05 §5.6) | N/A (l'écran n'existe pas en Focus Mode) | 05 §2.6 r.3 ; 05 §5.6 |
| **Règle bloquante 05 §5.1 l.2931** | Les thèmes **ne re-définissent jamais** `success` / `warning` / `danger` / `info` | Le **Badge danger** « à resync » (§4(a) error) + la **success** Toast = couleurs sémantiques **figées**, quel que soit le thème (L2 ne touche pas ces tokens) | 05 §5.1 l.2931 |
| Presets (3) | `slate` / `nocturne` / `high-contrast` | **Nocturne** (OQ-16 WDS) : fond sombre, heatmap `habit-*` **assombries**, niveau 0 = `bg-subtle` (WDS 05.1 §5) ; **High-Contrast** : tap targets **56 px**, logo **monochrome** (§9.1 l.384) ; `slate` = preset neutre | 05 §5.5 ; §9.1 l.384 ; WDS 05.1 §5 |

> **AD-17 (ui-libraries S4 l.145–160)** : tokens **uniquement** — aucune valeur couleur/espacement/typo brute dans l'écran ; le thème = une **peau** (L1/L2 bougent, L3 = Focus), les couleurs sémantiques (badges success/warning/danger) et les états (error/offline/killed) sont **figés** (05 §5.1).

---

## §11 Accessibilité (WCAG AA — 05 §6.3)

| Règle | Valeur | SSoT |
|---|---|---|
| Cibles tactiles | ≥ **44 px** (56 px High-Contrast) sur : chaque Card (zone tapable), CTA « Marquer aujourd'hui », FAB, icône menu TopBar, tab BottomNav | 05 §6.3 ; 05 §3.4 l.682 |
| `aria-label` | Toute icône-button a un `aria-label` textuel : icône menu TopBar, icône FAB, icônes statut des Badge, icônes tab BottomNav | 05 §6.3 |
| `letter-spacing` | **0** sur tous les corps (pas de tracking positif) | 05 §6.3 |
| Focus visible | Anneau focus visible (05 §5.10 / `aurora.json` `focusTreatment = ring`) sur CTA, FAB, Card (focusable), tab ; **focus trap** dans le BottomSheet | 05 §6.3 ; `aurora.json` |
| Heatmap `HabitStreak` | **`role=group`** + `aria-label` = « Adhérence de [habitude], [N] jours de streak » ; les cellules 12×12 px **ne sont PAS** des cibles individuelles (lecture = le chiffre de streak `mono`, non les 49 cellules) — la preuve visuelle = la heatmap, l'information lue = le chiffre (05 §3.6.12) | 05 §3.6.12 l.1226–1228 ; 05 §6.3 |
| Contraste | Ratios AA (4.5:1 texte, 3:1 UI) sur le Badge danger, le CTA, les tabs ; le monochrome killed = **sur `surface`** (05 §2.1.3), jamais sur le canvas brut #0A0E1A (§9.1 l.399–402, blocking si < 3:1) | 05 §6.3 ; §9.1 l.399–402 |
| Reduced-motion | Toutes animations §5/§9 → **statique** ; Skeleton = **pas de pulse** ; la heatmap = **toujours** statique (règle 1, 05 §2.6) ; le `useReducedMotion()` (hook `packages/ui`) gâte l'ensemble (05 §2.6 l.330–334) | S5 ; 05 §2.6 r.2 ; `packages/ui` |
| Ordre de lecture | Card = titre (600) → heatmap (group, `aria-label`) → chiffre streak (mono) → CTA ; jamais de « insight » caché (le lien perturbateur est **affiché** dans le BottomSheet, 05 §4.3.5 l.1766–1768) | 05 §6.3 ; 05 §4.3.5 |

---

## §12 Offline (classe offline = `master-feature-catalog` L24)

| Aspect | Valeur | SSoT |
|---|---|---|
| Classe offline | `productivity.habits` = **offline-capable** (L24 : "offline-capable") | `master-feature-catalog` L24 |
| Miroir local (AD-7, AD-12) | PowerSync/SQLite : la liste d'habitudes + la heatmap `HabitStreak` = **lecture 100 % locale** (AD-7 spine l.81–85 : « the UI reads local state first and syncs to Supabase ») ; le check-in = **écriture locale** (mapping entité `Habit` → table locale `habits`, 03-sync §4.2 l.212, single-writer Productivity) — mutation **mise en file for upsync** (03-sync §4.2), **pas d'exigence réseau** (05 §4.3.5 l.1745–1751 ; AD-7 spine l.85 : « Offline is a first-class state, not a failure mode »). **AD-12 (One Agent Kernel, spine l.125–128)** ne touche pas ce miroir : le kernel agent ne fait **jamais** de logique locale ni ne mute les tables Productivity — l'analyse d'adhérence (le seul flux « distant » de cet écran) passe par le **serveur** (AD-12/F-09), jamais par le miroir ; le miroir local reste le domaine exclusif d'AD-7 | 05 §4.3.5 ; 03-sync §4.2 ; spine AD-7 l.81–85 ; spine AD-12 l.125–128 |
| Dégradation (AD-1) | Si le flux cloud (sync des données d'analyse d'adhérence — **capacité optionnelle** d'analyse distante, pas une table du miroir) est indisponible, l'écran **n'est jamais dégradé** : la liste + le CTA + la heatmap **restent** 100 % fonctionnels (AD-1 spine l.35 : « Optional capabilities … must **degrade gracefully** when their provider is absent » — ici, la dégragation = le flux d'analyse distante meurt (→ OQ-9), le tap manuel du check-in **reste**, ce que le check-in **est** — AD-7 spine l.85 ; AD-1 = l'isolation fournisseur, pas la saisie manuelle en soi) | spine AD-1 l.31–35 ; spine AD-7 l.81–85 |
| Ce qui meurt (killed) | Le **sync upsync** (mutations des habitudes créées / check-ins en file) + l'analyse d'adhérence **distante** (flux optionnel du cloud, AD-1 l.35 : dégradation propre — l'écran ne crash jamais) meurent ; la liste locale, le CTA « Marquer aujourd'hui » (écriture locale) et le FAB (création locale, mise en queue) **restent vivants** (05 §3.7 l.1290–1296 : les données du mirror local s'affichent, **jamais** d'écran blanc ni de reset — AD-7) ; **killed = sous-état de `loading` (G-M2, 05 §3.7 l.1290), pas un 6ᵉ état canonique** : le rendu = `loading` + auto-resync + bannière fine « Reconnexion… » | 05 §3.7 l.1290–1296 ; AD-7 ; AD-1 |
| État offline affiché | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) + le CTA « Marquer aujourd'hui » **fonctionnel** (l'écriture locale ne dépend pas du réseau) | §4(a) ; 05 §4.3.5 l.1745–1751 |

> **AD-7 (offline = état premier)** : cet écran est conçu **pour** le réseau 3G Bénin instable de Horeb (WDS 05.1 §3) ; le check-in du soir **boucle** la journée **sans** réseau ; seule la ré-synchronisation distante est reportée.

---

## §13 Occurrences du logo (S9 l.349–369, versions exactes)

| Occurrence | Version du logo (S9 l.349–360) | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| **TopBar** « Habitudes » (état normal) | **Coloré, sans fond** (`aurora_icon_a_integre_dans_l'applciation.png`, l.358) — le header **toujours** porte la marque colorée (owner decision 2026-09-27) | Signe de vie de marque, calme ; le coloré sans fond = l'état par défaut applicatif | §9.1 l.380 (matrix : header = colored) |
| État **404** (page entière, §4(c)) | **Coloré, sans fond, CENTRÉ** | Le 404 = le **seul** état qui mandate le logo coloré centré (reconfort + actif, « Retour à l'accueil » = marque active) | §9.1 l.387 ; ui-libraries §6.1 l.202 |
| État **killed** (bandeau, §4(d)) | **Monochrome** (`vs_monochrome_en_svg.svg`, l.360) sur `surface` (05 §2.1.3), jamais sur le canvas brut | « Marque présente mais ne parle pas » (neutres / en attente / inactif) — cohérence visuelle de l'indisponibilité | §9.1 l.383, l.399–402 |
| Presets **Nocturne + High-Contrast** | **Monochrome** | Ces presets = univers desaturés / contraste élevé ; les 10 thèmes expressifs = version colorée | §9.1 l.384 |
| **Watermark** (si l'écran en a un) | Monochrome, opacité **8 %**, application **unique** sur la zone de contenu (jamais au-dessus du texte, jamais en carrossel) | Le gris ne « lutte » jamais contre le contenu (la heatmap = la donnée, le watermark doit rester invisible) | §9.1 l.385, l.397–398 |
| **AgentThinkingLoader** (N/A ici) | Monochrome **animé** (§9.3, l'unique exception animée — mais l'écran n'affiche **pas** d'agent thinking, pas de ce composant ici) | Cité pour exhaustivité S9 ; pas d'occurrence sur `/habits` | §9.3 l.420–487 |

> **Interdits (S9 l.390–392)** : la version **full** (fond arrondi) **jamais** dans l'app UI ; le monochrome **jamais** dans un état « vivant » (le 404 = état vivant, coloré, §9.1 l.387) ; **aucun** recolor ; le watermark = application **unique** à 8 % (pas de tuiles répétées). **Aucune occurrence ad hoc** sur `/habits`.

---

## §14 Questions ouvertes (OQ)

- **OQ-1** — Le composant `HabitStreak` (heatmap GitHub-like, 05 §3.6.12) **n'est pas dans `packages/ui`** (`packages/ui/src/components/ui/` listé ci-dessus : pas de `HabitStreak.tsx`) : faut-il le créer (composant DS maison, S1 : « NEVER write a custom component if a library has it » — mais la bibliothèque ne **couvre pas** une heatmap de 7×7 cellules → **le créer dans `packages/ui`** est le chemin S1 l.331 : « build with shadcn primitives + tokens ») ? → **à trancher** (cf. OQ-2 taches-liste.md : composant DS maison pas encore dans `packages/ui`).
- **OQ-2** — Le `SegmentedControl` « quotidien / hebdo » (05 §3.4 l.711–723, DS 05) **n'est pas dans S1** (pas de `SegmentedControl` dans `packages/ui/src/components/ui/`) : le créer (shadcn + tokens) ou réutiliser le shadcn `Tabs` (S1 l.24) déguisé en sous-option (l'anti-nesting 05 §3.4 l.702–704 = **interdit** : Tabs = vue d'écran, SegmentedControl = sous-option) ? → **à trancher**.
- **OQ-3** — Le `HabitStreak` mobile = **7 semaines** (WDS 05.1 OQ-2 close A) vs **5 semaines** (05 §4.3.5 l.1715) : les deux SSoT **se contredisent** (7 vs 5) ; le desktop = **12 semaines** dans les deux (05 §4.3.5 l.1778–1784 ; WDS 05.1 §5). → **à trancher au standup** (cf. WDS 05.1 OQ-2 : « contradiction de sources, à signaler au standup »).
- **OQ-4** — Le libellé exact du message 404 (« Écran introuvable… » §4(c)) n'est pas figé par SSoT (05 §4.3.5 ne spécifie pas le texte 404 ; ui-libraries §6.1 l.202 = "short message", pas le texte). → **à trancher**.
- **OQ-5** — Le libellé exact du Badge `danger` « à resync » (S6 `error`, §4(a)) n'est pas figé par 05 §4.3.5 (qui dit « `Badge danger` sur la Card » sans le texte). → **à trancher**.
- **OQ-6** — Le libellé exact de la Toast `success` après sync (§4(a)) n'est pas figé par SSoT (ui-libraries S6 l.183 = "Green check + auto-dismiss", pas le texte). → **à trancher**.
- **OQ-7** — L'état sémantique **`terminé`** (journée bouclée, §4(b)) : le CTA « Marquer aujourd'hui » passe-t-il en texte « Journée bouclée » + icône `CheckCircle2` (§4(b)) ou reste-t-il inchangé (le check-in du lendemain est déjà le prochain) ? La transition CTA actif → CTA terminé n'est pas figée par 05 §4.3.5 (qui ne traite que le tap **unique**, pas l'état post-bouclage). → **à trancher**.
- **OQ-8** — Le libellé exact de la Toast **`success` transitoire** après le tap de check-in (« Marqué », §4(b) succès) n'est pas figé par SSoT (05 §4.3.5 = « un tap unique, pas un formulaire », pas de texte de confirmation). → **à trancher**.
- **OQ-9** — §12 « Dégradation (AD-1) » : l'**analyse d'adhérence distante** (le seul flux cloud de l'écran — le BottomSheet « Adhérence », §2/§6) n'a **pas de rendu figé** dans 05 §4.3.5 (ni le §4 de ce doc) quand son flux est indisponible (offline prolongé / killed) : la matrice AD-13 (05 §3.7) dit seulement que `Timeline`/`KeyValueList` restent en rendu **local** (les rapports syncés restent), mais **ni le message de Callout, ni le CTA, ni le libellé de dégradation** d'une section « analyse distante indisponible » ne sont spécifiés (AD-1 l.35 exige une dégradation **propre** — pas de crash —, sans figer le rendu). → **à trancher** (à quel Callout/libellé le BottomSheet « Adhérence » passe-t-il quand l'analyse distante meurt ?).
