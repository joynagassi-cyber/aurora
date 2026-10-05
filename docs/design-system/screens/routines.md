# Écran — Routines (`routines`)

Module : Productivité · Route : `/routines` · Statut : **détaillé** · SSoT écran : `05-design-system` §4.3.6 l.1787–1891 + WDS `05.2-routines` (OQ-1…OQ-3 close, pont) + `master-feature-catalog` L24 `productivity.habits` (offline-capable)

---

## §1 Psychologie du designer

| Dimension | Valeur |
|---|---|
| Objectif utilisateur | Voir et dérouler ma **séquence ordonnée** de routine (matin/soir/étude) : numéro + Checkbox + titre + durée — **pas** une liste de to-do (les to-do vivent dans `taches-liste` §4.3.1, la routine est une **séquence**). |
| Contexte | Mobile Pixel 4a, 22 h 45 chambre, thème Nocturne (OQ-16 WDS), réseau 3G Bénin instable : l'écran est conçu **offline-d'abord** (AD-7) — le check d'étape du rituel nocturne ne doit jamais mourir faute de réseau (WDS 05.2 §3). |
| Fréquence | Quotidienne, bornée par famille (le « Soir » se déroule 1×/jour ; « Matin » 1×/jour ; « Étude » aux moments d'étude — les routines = des **ancres temporelles**, `master-feature-catalog` L24). |
| État émotionnel cible | Calme de clôture : « je déroule, la barre avance, le rituel est bouclé » — jamais un compteur de tâches ni un dashboard de widgets (trigger-map §6 trap « Surcharge de widgets ») ; la régularité **se voit** dans le `ProgressBar` qui avance, pas dans un écran de confirmation (05 §4.3.6). |
| Erreur la plus probable | Croire qu'on peut « tout jouer » d'un coup (il n'existe **pas** de bouton « Tout faire » — la routine est **séquentielle**, l'habitude **appartient** à l'utilisatrice, l'app ne « joue » pas la routine à sa place, 05 §4.3.6 l.1829–1837) ; ou croire que le tap de check exige le réseau (faux — écriture locale AD-7, 05 §4.3.6 l.1853–1860). |
| Ce que l'écran RÉSOUT | « Ai-je déroulé toutes les étapes de ma routine du soir ? » en **1 séquence ordonnée + 1 `ProgressBar`** (la preuve = la barre, 05 §4.3.6 l.1861–1868), et résout le déroulement **sans réseau** (05 §4.3.6 `offline`). |
| Invariant AD-14 | Le CTA « Marquer l'étape » = **seul CTA d'action** de la surface (1 tap inline par étape, jamais un formulaire) — WDS 05.2 §10 ; jamais une proposition libre de l'agent dans le chemin court. |

---

## §2 Zones de l'écran (100 % — 05 §4.3.6 l.1799–1824)

| Zone | Contenu | SSoT |
|---|---|---|
| TopBar | Titre « Routines » + `SegmentedControl` « Matin \| Soir \| Étude » (3 familles, choix **exclusif ternaire** — `SegmentedControl` **justifié** ici, 05 §3.4 l.711–718 ; **pas** un select) ; l'écran est accessible en push depuis `/habits` (WDS 05.2 §2) → **`back` 44px** + titre + max 2 IconButtons | 05 §4.3.6 l.1799–1808 ; 05 §3.4 TopBar l.659–668 |
| Content | 1 `ProgressBar` (**% de complétion de la routine du jour**, 05 §4.3.6 l.1813–1816 ; doc §2.7 « Suivi de régularité ») + un `Callout warning` **posé** si la routine est **perturbée** cette semaine (« Votre routine du soir est incohérente cette semaine », l.1817–1823) + une liste de `RoutineStep` §3.6.12 (numéro `JetBrains Mono` + `Checkbox` 44px + titre + durée estimée `JetBrains Mono xs`) — **1 colonne verticale mobile** (WDS 05.2 OQ-1 close A) | 05 §4.3.6 l.1809–1823 ; 05 §3.6.12 l.1232–1242 ; WDS 05.2 OQ-1 |
| FAB | « + Créer une routine » → `BottomSheet` de création (`TextField` titre + `SegmentedControl` famille + `MultiSelect` d'étapes existantes ou `Button ghost` « Nouvelle étape » qui **empile** une `RoutineStep` vide dans la sheet, l.1869–1878) | 05 §4.3.6 l.1869–1878 |
| Footer | `BottomNav` 5 tabs (S-31 shared : Accueil · Tâches · Apprendre · Progression · Coach — 05 §3.4 l.676–678 ; WDS 05.2 OQ-4 close C) | 05 §3.4 l.670–691 ; WDS 05.2 §2 |
| Surfaces flottantes | `BottomSheet` création de routine ; `Toast` feedback (succès/error) ; `Callout` posé dans le contenu (pas flottant) | 05 §4.3.6 l.1869–1878 ; 05 §3.5 l.823 |

> **N/A** : la routine entière = une `Card` qui **contient** les `RoutineStep` (pas une liste plate — la routine est un **objet**, l'étape est sa partie, 05 §3.6.12 l.1240–1242) ; aucune sous-vue `Tabs` sur l'écran (le choix de famille = `SegmentedControl` = sous-option, règle anti-nesting 05 §3.4 l.701–704).

---

## §3 Éléments de l'écran (table 100 % de la zone)

| # | Élément | Composant DS 05 §3 | lib ui-libraries S1 | Tokens (AD-17) | Variante responsive (Phase 2) | Source SSoT |
|---|---|---|---|---|---|---|
| E1 | Titre « Routines » + `back` (push depuis `/habits`) | `TopBar` (05 §3.4 l.659–668) | shadcn (texte + icône, S1) | `text.md` 600, h=56 px, fond `surface`, `touch.target=44` | même mobile/desktop | 05 §4.3.6 l.1799 ; WDS 05.2 §2 (entrée = Card `/habits`) |
| E2 | `SegmentedControl` « Matin \| Soir \| Étude » (ternaire exclusif, max 3 segments **justifié**) | `SegmentedControl` (05 §3.4 l.711–718) | shadcn Tabs shadcn **déguisé = interdit** (anti-nesting 05 §3.4 l.702–704) ; le composant DS `packages/ui` **n'est pas dans S1 → OQ-1** §14 | track `bg-subtle` radius `full`, segment actif = `surface` + `shadow.1` + `text-primary`, `touch.target=44` | **desktop = disparaît** : les 3 familles en **3 colonnes côte à côte** (le desktop a la largeur, doc §23.4) | 05 §4.3.6 l.1800–1808 + l.1880–1886 ; 05 §3.4 l.711–718 |
| E3 | `ProgressBar` complétion routine du jour | `ProgressBar` (05 §3.3 l.553–570) | shadcn Progress (S1 l.33) | track `bg-subtle` (0% = barre **vide visible**, jamais disparue), fill `color.primary`, % en `JetBrains Mono xs` **sans animation de comptage** (règle 1, 05 §2.6 l.323–329) ; `role=progressbar` + `aria-valuenow/min/max` | **desktop : 1 barre par colonne** (3 familles = 3 barres, l.1880–1886) | 05 §4.3.6 l.1813–1816 ; 05 §3.3 l.564, l.569–570 |
| E4 | `Card` routine (container de la séquence) | `Card` (05 §3.3, flat dans liste dense) | shadcn Card (S1 l.12) | fond `surface`, radius `8` max (S3 l.142), `spacing.m` | **3 colonnes** (1 Card/famille) | 05 §3.6.12 l.1240–1242 ; 05 §4.3.6 l.1880–1886 |
| E5 | `RoutineStep` (ligne : numéro + `Checkbox` + titre + durée) | `RoutineStep` (05 §3.6.12 l.1232–1242 : `ListItem` + numérotation `JetBrains Mono` + `Checkbox` §3.2 44px à droite) | **composant DS maison `packages/ui` (pas dans S1 → OQ-2** §14) | numéro `JetBrains Mono xs`, durée `JetBrains Mono xs`, `Checkbox` 44 px (`success` quand cochée, 05 §3.2 l.452–453), ligne ≥ 56 px | **desktop : la durée devient un `Slider` inline éditable** (05 §3.2 l.471–478, l.1887–1891) | 05 §4.3.6 l.1809–1813 ; 05 §3.6.12 l.1232–1242 ; **OQ** : l'existence du composant DS en code = §14 OQ-2 (pas dans `packages/ui`) — aucune SSoT factice |
| E6 | Tap `RoutineStep` → **check inline** (pas de push, pas de BottomSheet) | interaction 05 §4.3.6 `Transitions` l.1861–1868 ; WDS 05.2 OQ-2 close A (check inline **uniquement**) | n/a (pas de nouveau composant) | le `ProgressBar` avance **immédiatement** (écriture locale AD-7) ; la `Checkbox` cochée = `success` | même | 05 §4.3.6 l.1861–1868 ; WDS 05.2 OQ-2 |
| E7 | `Callout warning` « routine perturbée » | `Callout` (05 §3.3 l.628–641 : fond `{level}-surface`, bordure 1px `warning`, radius `md`, padding `space.3`) | shadcn Alert (S1 l.27) | `color.warning` (**figé**, 05 §5.1 l.2931), **posé** dans le contenu (persistant, **pas** un toast) ; le Callout warning **doit** porter une action (05 §3.3 l.634–635) — l'action exacte ici → **OQ-5** §14 | même | 05 §4.3.6 l.1817–1823 (texte posé par SSoT : « Votre routine du matin est incohérente cette semaine ») |
| E8 | `Badge danger` « à resync » (étape non syncée) | `Badge` (05 §3.3 l.531–533) | shadcn Badge (S1 l.31) | `color.danger` (figé, 05 §5.1) ; l'étape **reste**, AD-7 (05 §4.3.6 l.1849–1852) | même | 05 §4.3.6 l.1849–1852 |
| E9 | `EmptyState` **par famille** (tab « Soir » vide) | `EmptyState` (05 §3.3 l.643–646 : icône **domaine** 48px `text-muted`, jamais illustration SaaS) | shadcn Card empty variant (S6 l.182) | icône « routine », `text.md` 600 + CTA `lg` | même | 05 §4.3.6 l.1844–1848 (« Aucune routine du soir — créez-en une » + CTA, verbatim SSoT) |
| E10 | `Skeleton` étapes (loading) | `Skeleton` (05 §3.7 l.1261) | shadcn Skeleton (S6 l.180) | **le numéro reste, la valeur pulse** (la structure est connue, les durations peuvent être syncées — 05 §4.3.6 l.1838–1843) ; `color.skeleton`, pulse opacity 0.6→1 1.2 s (05 §2.6 l.342–343) | même | 05 §4.3.6 l.1838–1843 |
| E11 | Badge top-bar « Hors-ligne » (offline) | `Badge` top-bar (05 §3.7 l.1258) | shadcn Badge | `color.neutral.400`, `icon.size=16` | même | 05 §3.7 l.1258 |
| E12 | FAB « + Créer une routine » | `FAB` (05 §3.1 l.400–403 : bas-droit, **au-dessus** de la BottomNav) | shadcn Button variant (S1 l.11) | fond `color.brand.primary` (L2 du thème actif), `touch.target=56`, `radius=8` | même | 05 §4.3.6 l.1869 |
| E13 | `BottomNav` 5 tabs | `BottomNav` (05 §3.4 l.670–691) | shadcn (S1 l.35) | icône 24 px + label `xs`, h=56 px + safe-area, tab actif = pill `primary-surface` | desktop = side nav | 05 §3.4 l.670–691 ; WDS 05.2 OQ-4 close C |
| E14 | BottomSheet **création de routine** | `BottomSheet` (05 §3.5 l.787) : `TextField` titre (Input shadcn) + `SegmentedControl` « Matin/Soir/Étude » (05 §3.4 l.711–723) + `MultiSelect` d'étapes existantes (chips **removable**, 05 §3.2 l.438–444) ou `Button ghost` « Nouvelle étape » qui **empile** une `RoutineStep` vide dans la sheet | shadcn Sheet + Input + Select (S1 l.13–15, 17) ; `SegmentedControl` / `MultiSelect` DS → **OQ-1/OQ-2** §14 | `touch.target=44`, coins hauts `xl` (§2.4), `shadow.4`, height `full` ≈ 85 % (05 §3.5 l.795) | même | 05 §4.3.6 l.1869–1878 ; 05 §3.2 |
| E15 | `Toast` feedback (succès transitoire) | `Toast` (05 §3.5 l.823) | shadcn Toast (S1 l.29, S6 l.183) | `color.success`, auto-dismiss 3 s | même | S6 l.183 ; 05 §3.5 |

> **S3 (ui-libraries l.133–143)** : `ion-calendar` / `ion-list` data / `ion-item` forms / `ion-datetime` **interdits** — la `RoutineStep` = composant DS (05 §3.6.12) rendu en `ListItem` + `Checkbox` shadcn/Radix, jamais `ion-item` (S3 l.137). **1 écran = 1 système de composants (S1)** : shadcn + composants DS `packages/ui` uniquement ; aucun mélange de 2 libs (S8 l.333). **Pas de bouton « Tout faire »** (05 §4.3.6 l.1829–1837) — un tel CTA = invention interdite.

---

## §4 États de l'écran

### §4(a) Matrice 6 états S6 (AD-13) — éléments asynchrones : liste de `RoutineStep` + `ProgressBar` (AD-7 local)

| État | Composant | Tokens | Texte exact | CTA | Entrée/Sortie |
|---|---|---|---|---|---|
| **loading** | Skeleton par `RoutineStep` (**le numéro reste**, la **valeur pulse** — structure connue, durations syncables, 05 §4.3.6 l.1838–1843) + `ProgressBar` en Skeleton (indéterminé, pas de %, 05 §2.6 l.342–343) ; le store local = court (AD-7) | `color.skeleton`, pulse opacity 0.6→1 1.2 s (05 §2.6 l.342–343) | (silencieux) | FAB actif (création locale) ; le `SegmentedControl` = lecture locale **immédiat** (05 §3.4 l.720–723) ; pas de CTA de check (les étapes ne sont pas encore là) | entrée : fade 150 ms ; sortie : swap liste 250 ms (`anim.normal`) |
| **empty** | `EmptyState` **par famille** (05 §4.3.6 l.1844–1848 ; le tab « Soir » vide n'a **rien** à voir avec le tab « Matin ») | icône « routine » 48 px `text-muted` (icône **domaine** `packages/ui/src/icons/`, 05 §2.5 l.303–304), CTA `Button lg` | « Aucune routine du soir — créez-en une » (verbatim SSoT, l.1847–1848) | CTA « Créer une routine » (ouvre la BottomSheet E14 — jamais le chemin court AD-14 ; **OQ-6** §14 pour les variantes matin/étude du libellé) | fade 250 ms |
| **error** | `Badge danger` **sur l'étape non syncée** (l'étape **reste**, AD-7, 05 §4.3.6 l.1849–1852) ; le `ProgressBar` reflète l'état **réel** (les étapes locales cochées comptent, les non-syncées **n'augmentent pas** la barre — WDS 05.2 §7 Error) ; matrice 05 §3.7 l.1258 : `ListItem` error = badge resync | `color.danger` (figé, 05 §5.1 l.2931) | Badge « à resync » (libellé → **OQ-5** §14) | le check des **autres** étapes reste actionnable (écriture locale) ; « Réessayer » = auto-resync au retour du réseau (05 §3.7 l.1258) | badge = fade 150 ms |
| **success** | `Toast` après sync réussie (S6 l.183) | `color.success`, auto-dismiss 3 s | « Routines synchronisées » (libellé non figé → **OQ-7** §14) | aucune (auto-dismiss) | slide-in bas 250 ms |
| **offline** | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) + liste locale **fonctionnelle** (lecture **et** écriture locales, AD-7, 05 §4.3.6 l.1853–1860) | `color.neutral.400`, `icon.size=16` | « Hors-ligne — données locales » (libellé → **OQ-8** §14) | le check « Marquer l'étape » **reste possible** : une routine ne doit **jamais** exiger le réseau (05 §4.3.6 l.1856–1860 ; AD-7) ; le `ProgressBar` avance **immédiatement** (complétion locale) | fade 150 ms |
| **killed** (G-M2) | Skeleton + bandeau « Reconnexion… » (05 §3.7 l.1290–1301) + logo **monochrome** (§9.1 l.383) | `color.skeleton` + monochrome sur `surface` | « Reconnexion… » | le check **reste actif** (relance depuis le mirror local, AD-7) | entrée **instantanée** (05 §2.6 r.2) ; sortie fade 250 ms |

*Source : 05 §3.7 l.1252–1301 (matrice AD-13 normative : ListItem l.1258, ProgressBar l.1259, Card l.1257, EmptyState l.1262, Skeleton l.1261, Toast l.1269, killed l.1290–1301) ; 05 §4.3.6 l.1838–1860 ; S6 l.174–187.*

### §4(b) États sémantiques §6.1 (ui-libraries l.189–202)

| État sémantique | Appliqué ? | Rendu / N/A (raison) |
|---|---|---|
| **en-cours** | N/A | Le déroulement de la routine n'est **pas** une opération serveur partielle : chaque check = tap binaire local (AD-7), le `ProgressBar` **est** déjà l'indicateur de progression mesurable (§6.1 l.197 : « MEASURABLE progress » — ici la barre **est** l'en-cours, aucun `Progress` additionnel ni streaming) |
| **terminé** | ✓ | **Routine du jour complète** : `ProgressBar` = **100 %** + toutes les `RoutineStep` cochées = complétion **pure­ment visuelle** (WDS 05.2 OQ-3 close A : **pas de CTA global « Routine complète »** — la SSoT ne le mentionne pas, 05 §4.3.6 ; le `ProgressBar` passe en `success` (05 §3.3 l.557–558 : `success` si 100 %) + le `Callout warning` **disparaît** s'il était posé. Jamais de feu d'artifice (§2.6) ; pas d'écran de confirmation (l.1866–1868) |
| **échec** | N/A | Pas d'échec terminal non réessayable d'une routine (le domain `Routine` n'a pas de statut `failed`) ; le cas d'erreur = S6 `error` (badge resync sur l'étape, l'étape reste, AD-7) |
| **succès** | ✓ | Transitoire = S6 `success` (Toast 3 s) après le check d'étape — libellé → **OQ-9** §14 |
| **erreur** | ✓ | S6 `error` (badge danger sur l'étape, reprise en place, l'étape reste, AD-7) |
| **404 / not-found** | ✓ | §4(c) ci-dessous (route `/routines` inconnue / deep link défaillant) |

### §4(c) 404 / not-found (route `/routines` — page entière, §6.1 l.202)

| Élément | Valeur | Tokens | Texte exact | CTA | SSoT |
|---|---|---|---|---|---|
| Logo | **Coloré, sans fond, CENTRÉ** (`aurora_icon_a_integre_dans_l'applciation.png` — le **seul** état qui le mandate, §9.1 l.387) | `color.brand.*`, `spacing.xl` | — | — | ui-libraries §6.1 l.202 ; §9.1 l.387 |
| Message court | texte `sm` centré | `color.neutral.700/300` (light/dark) | « Écran introuvable. Retour à l'accueil ? » (libellé non figé → **OQ-4** §14) | — | §6.1 l.202 |
| CTA primaire | `Button` primary `lg` | `color.brand.primary`, `touch.target=48` (HC 56) | « Retour à l'accueil » | navigation `/` (home) | §6.1 l.202 |
| Secondaire (optionnel) | `Button` ghost | `color.text.secondary` | « Consulter l'écran parent » → `/habits` (l'écran d'origine de la routine, 05 §4.3.5) | — | §6.1 l.202 (« optional secondary ») |

### §4(d) Killed (tout flux serveur, 05 §3.7 l.1290–1301)

| Élément | Valeur | Tokens | Texte exact | SSoT |
|---|---|---|---|---|
| Bandeau top | Skeleton + bannière fine « Reconnexion… » + logo **monochrome** (§9.1 l.383, sur `surface` jamais sur le canvas brut — §9.1 l.399–402) | `color.skeleton` ; monochrome = tonalité #131B22→#B9BABC | « Reconnexion… » | 05 §3.7 l.1290–1301 ; §9.1 l.383, l.399–402 |
| Étapes / `ProgressBar` | Skeleton (relance depuis le mirror local, **jamais** d'écran blanc ni de reset — AD-7) ; le `ProgressBar` **figé** + Callout si job d'alimentation échoué (05 §3.3 l.586–587) | `color.skeleton` | — | 05 §3.7 l.1290–1296 ; 05 §3.3 l.586–587 |
| CTA / FAB | Restent actifs (le check = écriture locale, AD-7) | `color.brand.primary` | « Marquer l'étape » / « + Créer une routine » | 05 §4.3.6 l.1853–1860 |

---

## §5 Micro-interactions (table GPU-only, 150–250 ms, smooth)

| Élément | Action → Feedback | Durée | GPU-only (transform+opacity) | smooth | reduced-motion = statique | SSoT |
|---|---|---|---|---|---|---|
| Page (entrée) | Fade + translateY 8→0 (`PAGE_TRANSITION` motion.tsx @aurora/ui) | 200 ms `anim.normal` ease-out | `transform: translateY`, `opacity` (S5 l.169) | ease-out, pas bouncy (S3 l.143) | statique (S5 ; 05 §2.6 r.2) | motion.tsx @aurora/ui ; 05 §2.6 l.310–317 |
| `RoutineStep` (apparition) | Fade + translateY 8→0 du **conteneur** — **jamais** la donnée (règle 1, 05 §2.6 l.323–329) | 250 ms `anim.normal` | `transform`, `opacity` | ease-out | statique | 05 §2.6 l.323–329 |
| Tap `RoutineStep` → check inline | `Checkbox` passe en cochée **immédiatement** (écriture locale AD-7, mutation queue for upsync 03 §4.2) + le fill du `ProgressBar` glisse à sa nouvelle valeur (glissement de largeur → **OQ-10** §14, SSoT non localisable) | press 150 ms ; fill 200 ms | `transform: scale(0.98)` du tap + `opacity` du crossfade ; **pas** de `layout` (S5 l.169) | ease-out | statique (le check apparaît sans anim) | 05 §4.3.6 l.1861–1868 ; WDS 05.2 OQ-2 close A |
| `ProgressBar` **ne se peint jamais** (règle 1, 05 §2.6 l.323–329 + §3.6.12 l.1224–1226 : la valeur **est**, elle ne « tourne » pas) — l'animation du fill = un glissement de largeur **max 1 fois** par check (**OQ-10** §14 : SSoT non localisable en code ni en doc — aucune règle du glissement de largeur dans 05/motion.tsx @aurora/ui/aurora.css), **pas** de shimmer de remplissage | n/a (voir ligne ci-dessus) | 200 ms max | `transform`/`opacity` uniquement ; **interdit** : animation de comptage 0→N | ease-out | statique (barre figée à sa valeur) | **OQ** (SSoT du glissement de largeur = OQ-10) |
| BottomSheet création | Slide-up translateY 100 %→0 | 250 ms `anim.normal` | `transform: translateY` | ease-out, pas bouncy (S3 l.143) | statique (S5) | 05 §3.5 l.787–796 ; 05 §4.3.6 l.1869 |
| `SegmentedControl` famille | La pilule glisse (`anim.fast`, 05 §3.4 l.716–717) | 150 ms `anim.fast` | `transform: translateX` | ease-out ; **interdite** en reduced-motion (05 §3.4 l.716–717) | statique | 05 §3.4 l.716–717 |
| Toast succès/error | Slide-in bas (translateY + opacity) | 250 ms | `transform: translateY`, `opacity` | ease-out | statique | S6 l.183 ; 05 §2.6 |
| Skeleton loading | Pulse opacity 0.6→1 (1.2 s, **pas** de shimmer agressif — 05 §2.6 l.342–343) ; Focus Mode = `animation:none` ([data-focus-mode], 05 §2.6 r.3) | 1200 ms loop | `opacity` | ease-in-out | **pas de pulse, statique** (05 §2.6 r.2) | 05 §2.6 l.342–343, r.3 |

> **Règle 1 (05 §2.6 l.323–329)** : les **données ne s'animent jamais** — le chiffre de complétion et les étapes **ne scintillent pas, ne comptent pas**. **Règle 4 (05 §2.6 l.340–341)** : aucune animation ne bloque l'input (le check reste tapable pendant le sync cloud). **Mobile (S5 l.169)** : zéro `layout` animation ; GPU only (`transform` + `opacity`). **Focus Mode (05 §2.6 r.3)** : si Horeb est en focus, `/routines` est **masqué** (le focus bloque les autres surfaces, WDS 05.2 §5 note desktop) — pas de variante Focus de l'écran.

---

## §6 Modals / BottomSheets

| Élément | Type | Déclencheur | Contenu | Fermeture | SSoT |
|---|---|---|---|---|---|
| BottomSheet **création de routine** | `BottomSheet` `full` (05 §3.5 l.787–796) | Tap FAB « + Créer une routine » | `TextField` titre (Input shadcn, label **au-dessus** — 05 §3.2 l.414–416) + `SegmentedControl` « Matin / Soir / Étude » (05 §3.4 l.711–723) + `MultiSelect` d'étapes existantes (chips **removable** `×` 44px, 05 §3.2 l.443–444 ; > 20 options = recherche obligatoire) **ou** `Button ghost` « Nouvelle étape » qui **empile** une `RoutineStep` vide dans la sheet (05 §4.3.6 l.1874–1878, §3.2) | Valider → `routines.create` (AD-7 locale, mutation queue for upsync 03 §4.2) / fermer (swipe down / handle / back Android — le formulaire est **auto-persisté**, 05 §3.5 l.780–783) | 05 §4.3.6 l.1869–1878 ; 05 §3.2 ; 05 §3.5 |

> **Pas de Modal plein-écran ni de BottomSheet d'analyse d'étape** sur l'écran (WDS 05.2 OQ-2 close A : le tap sur `RoutineStep` = check **inline uniquement**, 05 §4.3.6 l.1861–1868). L'analyse (adherence/perturbations) vit dans l'écran `/habits` (§4.3.5 BottomSheet d'analyse d'habitude, l.1752–1768), pas ici — la preuve = `ProgressBar` + étapes cochées (WDS 05.2 OQ-2). Un `Modal` empilé sur un `Modal` = interdit (05 §3.5 l.783–785).

---

## §7 Formulaires

| Champ | Composant | Validation | SSoT |
|---|---|---|---|
| Titre de la routine | `TextField` (Input shadcn ; S3 l.137 interdit `ion-item`) | Obligatoire, label **au-dessus** (05 §3.2 l.414–416), erreur **inline** sous le champ (`danger` + icône, jamais dans une Toast, 05 §3.2 l.416–418) | 05 §4.3.6 l.1870–1871 ; 05 §3.2 |
| Famille | `SegmentedControl` « Matin / Soir / Étude » (ternaire exclusif, 05 §3.4 l.711–718) | Exclusif, **immédiat** (lecture locale AD-7, 05 §3.4 l.720–721) | 05 §4.3.6 l.1872–1873 ; 05 §3.4 |
| Étapes | `MultiSelect` (chips removables, 05 §3.2 l.438–444) **ou** `Button ghost` « Nouvelle étape » (empile une `RoutineStep` vide, 05 §4.3.6 l.1874–1878) | Optionnelle (une routine peut être créée **vide** puis empilée) ; > 20 étapes existantes = recherche dans la BottomSheet de choix (05 §3.2 l.445–446) | 05 §4.3.6 l.1874–1878 |

> **Le check d'étape est un TAP UNIQUE, pas un formulaire** (05 §4.3.6 l.1861–1868) — le seul formulaire de l'écran = la **création** de routine (BottomSheet E14). Tout est **shadcn/Radix** (S3 l.137).

---

## §8 Pagination / Tri / Filtres

| Règle | Paramètre | Valeur | SSoT |
|---|---|---|---|
| **Règle unique nommée** | Scroll natif (pas de shadcn Pagination, pas de AG Grid, pas de `Pager` Jour/Semaine/Mois — le `Pager` 05 §3.4 l.737–749 est le navigateur **temporel** du Calendrier/Gantt, pas celui d'une liste de routines) | La liste de `RoutineStep` d'une routine = **store local** (AD-7), volume **faible** (une routine = une **séquence** bornée de 1 à N étapes, 05 §3.6.12 ; doc §12 « simple en surface » : une routine à la fois, pas 8) ; S8 l.304–307 : **< 20 lignes → pas de pagination** ; le scroll vertical natif suffit | 05 §4.3.6 ; S8 l.304–307 ; 05 §3.4 l.737 |
| **Tri** | Ordre de la routine = **l'information** (la numérotation `JetBrains Mono` 1., 2., 3. **est** l'ordre défini, pas un bullet générique — 05 §3.6.12 l.1234–1236) ; **tri par durée / par alpha = interdit** (il dénature la séquence) | Tri **fixe = ordre de la routine**, pas de re-tri animé (règle 1, 05 §2.6) ; desktop = les 3 familles en 3 colonnes (pas de tri, 05 §4.3.6 l.1880–1886) | 05 §3.6.12 l.1234–1236 |
| **Filtre** | Aucun filtre d'écran : le choix de famille = le `SegmentedControl` Matin/Soir/Étude (c'est le **switch de vue**, pas un filtre — 05 §4.3.6 l.1800–1808) | N/A (famille = SegmentedControl exclusif, pas un filtre multi-select) | 05 §4.3.6 l.1800–1808 |

---

## §9 Transitions entre écrans

| Transition | Direction | Durée / curve | GPU-only | SSoT |
|---|---|---|---|---|
| Habitudes → Routines | `/habits` → `/routines` (Menu TopBar « Routines » — 05 §4.3.5 l.1710–1711 ; entrée primaire WDS 05.2 §2 = tap sur la Card « Routine du soir ») | 200 ms fade + y (`PAGE_TRANSITION`) | `transform` + `opacity` | 05 §4.3.5 l.1711 ; WDS 05.2 §2 |
| Deep link `/routines` (notification locale de routine incomplète) | externe → `/routines` (WDS 05.2 §2 entrée 2) | 200 ms fade + y | idem | WDS 05.2 §2 ; 04-mobile §4 |
| Routines → Habitudes (retour) | le **contexte** (règle de non-surprise, 05 §3.4 : le retour retrouve la vue d'avant — SegmentedControl = famille **persistée** par écran, 05 §3.4 l.720–723) | 200 ms fade | `transform` | 05 §3.4 l.704–706 |
| BottomSheet création (création → validation) | le sheet se **rétracte** (translateY 0→100 %), le contexte de la liste est **conservé** (le FAB reste là) | 250 ms slide-down | `transform: translateY` | 05 §3.5 l.787–796 |
| Routines → Taches-liste (après complétion visuelle, sortie secondaire) | `/routines` → `/tasks` (WDS 05.2 §9 : après la confirmation, Horeb ouvre la liste plate de tâches) | 200 ms fade + y | `transform` + `opacity` | WDS 05.2 §9 ; 05 §4.3.1 |
| 404 → Accueil | CTA « Retour à l'accueil » → `/` | 200 ms fade + y | idem | §6.1 l.202 |

> **Mobile (S5 l.169)** : aucune transition de `layout` ; GPU only. **Reduced-motion (05 §2.6 r.2)** : toutes transitions → **statique** (0 ms). **Pas de bouncy (S3 l.143)**.

---

## §10 Thèmes (10 + 3 presets, par couche — AD-17)

| Couche | Comportement par thème (jamais par valeur, 05 §5.2) | Rendu sur cet écran | SSoT |
|---|---|---|---|
| L1 **Neutral** (fond/texte) | `neutral.light #FFFFFF` / `neutral.dark #121212` + texte inverse ; tokens sémantiques **figés** (05 §2.1.2/§2.1.3) | Fond liste + texte titres des `RoutineStep` + le `ProgressBar` track `bg-subtle` | 05 §5.1/§5.2 ; §2.1.2/2.1.3 |
| L2 **Expressive** (10 thèmes vivants) | Le `accent.primary` du thème actif se lit via `hsl(var(--aurora-accent-primary-h))` (05 §5.4) et **colore** le fill du `ProgressBar` + le FAB + le pill du tab actif ; le thème **ne touche jamais** `success`/`warning`/`danger`/`info` (règle bloquante 05 §5.1 l.2931) | `ProgressBar` fill = L2 accent ; FAB = L2 ; la `Checkbox` cochée = `success` **figée** (jamais L2) | 05 §5.2/§5.4 ; §5.1 l.2931 |
| L3 **Override local** (Focus Mode) | **N/A ici** : le Focus Mode (`[data-focus-mode]`, 05 §2.6 r.3) **bloque** l'écran (si Horeb est en focus, `/routines` est **masqué**, WDS 05.2 §5 note) ; le L3 override = réservé au Focus (V1, OQ-15, 05 §5.6 l.3167) | N/A (l'écran n'existe pas en Focus Mode) | 05 §2.6 r.3 ; 05 §5.6 ; WDS 05.2 §5 |
| Presets (3) | `slate` / `nocturne` / `high-contrast` (05 §5.5 l.3153) | **Nocturne** (OQ-16 WDS) : fond sombre, `RoutineStep` numéros/durées `JetBrains Mono` assombries, `ProgressBar` track = `bg-subtle` (sombre) ; **High-Contrast** : tap targets **56 px** (05 §6.3), logo **monochrome** (§9.1 l.384) ; `slate` = preset neutre | 05 §5.5 ; §9.1 l.384 ; WDS 05.2 §5 |

> **AD-17 (ui-libraries S4 l.145–160)** : tokens **uniquement** — aucune valeur couleur/espacement/typo brute dans l'écran ; le thème = une **peau** (L1/L2 bougent, L3 = Focus), les couleurs sémantiques (`success`/`warning`/`danger`/`info`) et les états (error/offline/killed) sont **figés** (05 §5.1 l.2931). WDS 05.2 §5 Variants = 2 (Nocturne default Horeb + Light) — dérivées de L1/L2, pas des valeurs brutes.

---

## §11 Accessibilité (WCAG AA — 05 §6.3)

| Règle | Valeur | SSoT |
|---|---|---|
| Cibles tactiles | ≥ **44 px** (56 px High-Contrast) sur : chaque `RoutineStep` (ligne **entière** tapable — 05 §3.3 l.522 : « un tap **tout** le long de la ligne »), la `Checkbox` (44×44 px, 05 §3.2 l.451), le CTA « Créer une routine » (BottomSheet), FAB (56 px), icône menu/`back` TopBar (44 px), tab BottomNav (56 px) | 05 §6.3 ; 05 §3.2 l.451 ; 05 §3.3 l.522 |
| `aria-label` | Toute icône-button a un `aria-label` textuel : icône `back` TopBar, icône `more` (si présente), icône FAB, icône de l'`EmptyState` (icône **domaine** « routine »), tab BottomNav | 05 §6.3 ; 05 §3.1 l.398 |
| `letter-spacing` | **0** sur tous les corps (pas de tracking positif) | 05 §6.3 |
| Focus visible | Anneau focus visible (`aurora.json` `focusTreatment = ring`, 05 §5.10) sur CTA, FAB, `RoutineStep` (focusable), tab ; **focus trap** dans la BottomSheet de création | 05 §6.3 ; `aurora.json` |
| `ProgressBar` (E3) | **`role="progressbar"`** + `aria-valuenow`/`aria-valuemin`/`aria-valuemax`/`aria-label` = « Complétion de la routine du soir : 60 % » (obligatoires, 05 §3.3 l.566) ; le % en `JetBrains Mono xs` = **visuel**, la valeur lue = le `aria-label` | 05 §3.3 l.566–570 |
| `RoutineStep` (E5) | Chaque ligne = 1 élément **sémantique** (numéro + titre + durée + statut cochée/non) — `role="listitem"` + `aria-label` = « Étape 2 : Révisions 30 min, non cochée » (le **numéro** parle à l'ordre, le `Checkbox` au statut, la durée à `JetBrains Mono xs`) | 05 §3.6.12 l.1232–1242 ; 05 §6.3 |
| Contraste | Ratios AA (4.5:1 texte, 3:1 UI) sur le `Badge danger` « à resync », le `Callout warning`, le CTA, les tabs ; le monochrome killed = **sur `surface`** (05 §2.1.3), jamais sur le canvas brut #121212 (§9.1 l.399–402, blocking si < 3:1) | 05 §6.3 ; §9.1 l.399–402 |
| Reduced-motion | Toutes animations §5/§9 → **statique** ; Skeleton = **pas de pulse** ; le `ProgressBar` = **figé** à sa valeur (règle 1, 05 §2.6) ; le `useReducedMotion()` (hook `packages/ui`) gâte l'ensemble (05 §2.6 l.330–334) | S5 ; 05 §2.6 r.2 ; `packages/ui` |
| Ordre de lecture | `ProgressBar` (preuve de complétion) → `RoutineStep` dans **l'ordre défini** (1., 2., 3. — la séquence **est** l'information, 05 §3.6.12 l.1234–1236) ; jamais de réorganisation visuelle qui casserait l'ordre de la routine | 05 §3.6.12 ; 05 §6.3 |

---

## §12 Offline (classe offline = `master-feature-catalog` L24)

| Aspect | Valeur | SSoT |
|---|---|---|
| Classe offline | `productivity.habits` = **offline-capable** (L24 : "daily/weekly habits + routines (temporal anchors) + adherence analytics; `HabitStreak` heatmap; **offline-capable**") | `master-feature-catalog` L24 |
| Miroir local (AD-7) | PowerSync/SQLite : la liste de `RoutineStep` + le `ProgressBar` = **lecture 100 % locale** (AD-7 : « PowerSync + SQLite on device; the UI reads local state first and syncs to Supabase ») ; le check d'étape = **écriture locale** (`routines` tables 03 §4.2, mutation queue for upsync, 03-sync §4.2) — le check **ne doit pas exiger le réseau** (05 §4.3.6 l.1853–1860 ; AD-7). *(La SSoT du « miroir local » est AD-7 seule : AD-12 = « One Agent Kernel » (spine), c'est AD-7 qui définit le store local PowerSync/SQLite — l'ancienne référence `AD-7/AD-12` de ce §12 est corrigée.)* | 05 §4.3.6 ; 03 §4.2 ; AD-7 (spine) |
| Dégradation (AD-1) | Si le flux cloud (sync des données) est indisponible, l'écran **n'est jamais dégradé** : la séquence + le `ProgressBar` + le check **restent** 100 % fonctionnels (la saisie **manuelle** reste disponible — AD-1 = exactement ce que le check **est** : un tap local, AD-7) | AD-7 ; AD-1 |
| Ce qui meurt (killed) | Le **sync upsync** (mutations des routines créées / checks d'étapes) + l'analyse d'adhérence **distante** (la détection des « routines perturbatrices » qui alimente le `Callout warning` = job serveur S, 01 §4.1) meurent ; la liste locale, le `ProgressBar` (complétion locale) et le FAB (création locale, mise en queue) **restent vivants** (05 §3.7 l.1290–1296 : les données du mirror local s'affichent, **jamais** d'écran blanc ni de reset) | 05 §3.7 l.1290–1296 ; AD-7 |
| État offline affiché | Badge top-bar « Hors-ligne » (05 §3.7 l.1258) + le check « Marquer l'étape » **fonctionnel** (l'écriture locale ne dépend pas du réseau) ; le `SegmentedControl` famille **fonctionne** (choix local, 05 §3.4 l.720–721) ; le `Callout warning` **disparaît** si sa donnée distante n'est plus syncée (pas d'incohérence masquée, AD-1) | §4(a) ; 05 §4.3.6 l.1853–1860 |

> **AD-7 (offline = état premier)** : cet écran est conçu **pour** le réseau 3G Bénin instable de Horeb (WDS 05.2 §3) ; le déroulement du rituel nocturne **boucle** la journée **sans** réseau ; seule la ré-synchronisation distante est reportée (03 §4.2).

---

## §13 Occurrences du logo (S9 l.349–369, versions exactes)

| Occurrence | Version du logo (S9 l.349–360) | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| **TopBar** « Routines » (état normal) | **Coloré, sans fond** (`aurora_icon_a_integre_dans_l'applciation.png`, l.358) — le header **toujours** porte la marque colorée (owner decision 2026-09-27, §9.1 l.380) | Signe de vie de marque, calme ; le coloré sans fond = l'état par défaut applicatif | §9.1 l.380 (matrix : header = colored) |
| État **404** (page entière, §4(c)) | **Coloré, sans fond, CENTRÉ** (le **seul** état qui le mandate, §9.1 l.387) | Le 404 = état « vivant » (CTA primaire « Retour à l'accueil » = marque **active**) ; jamais le monochrome dans un état vivant (interdit §9.1 l.390–391) | §9.1 l.387 ; ui-libraries §6.1 l.202 |
| État **killed** (bandeau, §4(d)) | **Monochrome** (`vs_monochrome_en_svg.svg`, l.360) **sur `surface`** (05 §2.1.3), jamais sur le canvas brut #121212 | « Marque présente mais ne parle pas » (neutre / en attente / inactif) — cohérence visuelle de l'indisponibilité (S6 killed) | §9.1 l.383, l.399–402 |
| Presets **Nocturne + High-Contrast** | **Monochrome** | Ces presets = univers desaturés / contraste élevé ; les 10 thèmes expressifs = version colorée (§9.1 l.384) | §9.1 l.384 |
| `EmptyState` famille (E9) | **Coloré, sans fond** (le `EmptyState` = état **vivant** : le CTA « Créer une routine » est actif = marque **active**, §9.1 l.390–391 interdit le monochrome ici) | « Je n'ai pas encore de routine du soir » = un départ **actif** (la création est immédiate, AD-7) — pas un état « inactif » qui justifierait le monochrome | §9.1 l.387 (empty state = colored), l.390–391 (interdit monochrome « vivant ») |
| **AgentThinkingLoader** (N/A ici) | Monochrome **animé** (§9.3, l'unique exception animée) — **l'écran n'affiche PAS d'agent thinking** (pas de ce composant sur `/routines` : le check est **local**, pas un flux d'agent) | Cité pour exhaustivité S9 ; pas d'occurrence sur `/routines` | §9.3 l.420–487 |

> **Interdits (S9 l.390–392)** : la version **full** (fond arrondi, `aurora_logo_icon_d'affichage_l'applicaiton.png` l.357) **jamais** dans l'app UI ; le monochrome **jamais** dans un état « vivant » (le 404 + l'`EmptyState` = états vivants = **colorés**, §9.1 l.387, l.390–391) ; **aucun** recolor ; le watermark = application **unique** à 8 % (pas de tuiles répétées, §9.1 l.397–398) — **pas de watermark** sur `/routines` (la donnée = la `ProgressBar`, le watermark la battrait, §9.1 l.385). **Aucune occurrence ad hoc** sur `/routines`.

---

## §14 Questions ouvertes (OQ)

- **OQ-1** — Le composant `SegmentedControl` (05 §3.4 l.711–718, DS 05) **n'est pas dans S1** (pas de `SegmentedControl` dans `packages/ui/src/components/ui/`) : le créer (shadcn + tokens, S1 l.331 « build with shadcn primitives + tokens ») ou le dériver du shadcn `Tabs` (S1 l.24) ? L'anti-nesting (05 §3.4 l.702–704 : **Tabs = vue d'écran, SegmentedControl = sous-option**) **interdit** le déguisement en `Tabs` ici (le choix de famille = **sous-option**, pas une vue d'écran) → le `SegmentedControl` = **composant DS maison à créer dans `packages/ui`** (cf. OQ-2 habitudes.md même problème). → **à trancher**.
- **OQ-2** — Le composant `RoutineStep` (05 §3.6.12 l.1232–1242) **n'est pas dans `packages/ui`** (pas de `RoutineStep.tsx` dans `packages/ui/src/components/ui/`) : le créer (composant DS maison sur `ListItem` + `Checkbox` shadcn, S1 l.331) ou le composer ad hoc à l'écran ? Le SSoT §3.6.12 le définit comme un **composant du DS** (numéro `JetBrains Mono` + `Checkbox` + titre + durée) — **le créer dans `packages/ui`** est le chemin S1 (cf. OQ-1 taches-liste.md : composant DS maison pas encore dans `packages/ui`). → **à trancher**.
- **OQ-3** — Le `MultiSelect` de création (E14, 05 §4.3.6 l.1874–1878) : le shadcn `Select` (S1 l.17) **n'est pas** un MultiSelect (le SSoT §3.2 l.438–444 décrit un `MultiSelect` = chips **removables** + `Button` « Ajouter » qui ouvre une `BottomSheet` de choix — ce composant **n'est pas** dans S1) : le créer (composant DS maison, `packages/ui`) ou le composer ad hoc (chips shadcn + Select) ? → **à trancher**.
- **OQ-4** — Le libellé exact du message **404** (§4(c)) n'est pas figé par SSoT (05 §4.3.6 ne spécifie pas le texte 404 ; ui-libraries §6.1 l.202 = "short message", pas le texte). → **à trancher**.
- **OQ-5** — L'action exacte du **`Callout warning`** « routine perturbée » (E7, 05 §4.3.6 l.1817–1823) n'est pas figée par SSoT (la SSoT pose le **texte** du warning mais pas le CTA qui l'accompagne — or 05 §3.3 l.634–635 exige qu'un Callout warning **doit** porter **une action**, même `ghost`). Candidate : un `Button ghost` sm « Voir l'analyse » → ouvre le BottomSheet d'analyse d'habitude de `/habits` (05 §4.3.5 l.1752–1768) ? → **à trancher**.
- **OQ-6** — Les libellés exacts de l'**`EmptyState`** par famille (E9, 05 §4.3.6 l.1844–1848) : la SSoT fige verbatim **uniquement** le cas « Soir » (« Aucune routine du soir — créez-en une ») ; les variantes **Matin** et **Étude** du libellé ne sont pas figées. → **à trancher**.
- **OQ-7** — Le libellé exact de la Toast **`success`** après sync réussie (§4(a)) n'est pas figé par SSoT (ui-libraries S6 l.183 = "Green check + auto-dismiss", pas le texte). → **à trancher**.
- **OQ-8** — Le libellé exact du **Badge top-bar « Hors-ligne »** (E11, offline, §4(a)) n'est pas figé par 05 §4.3.6 (la SSoT dit « Badge top-bar », pas le texte). → **à trancher**.
- **OQ-9** — Le libellé exact de la Toast **`success` transitoire** après le tap de check d'étape (§4(b) succès) n'est pas figé par SSoT (05 §4.3.6 = « le check est **inline**, la régularité se **voit** dans le `ProgressBar` qui avance, **pas dans un écran de confirmation** » — pas de texte de confirmation). Le `ProgressBar` qui avance **suffit-il** sans Toast, ou faut-il une Toast brève (S6 l.183) ? → **à trancher**.
- **OQ-10** — L'animation du fill du `ProgressBar` (glissement de largeur « max 1 fois par check », §5) : aucune SSoT localisable (05 §2.6/§3.3 ne spécifient pas de glissement de largeur du fill ; `motion.tsx @aurora/ui` définit uniquement PAGE_TRANSITION/REVEAL_TRANSITION/NodePulse — pas d'animation de progress ; l'analogie réelle = `goal-card.tsx` `goal-progress-fill` width inline, sans transition CSS) → SSoT **factice remplacée** (le §5 marquait « motion.tsx @aurora/ui progress width 200 ms easeOut » qui n'existe pas). → **à trancher** (durée/courbe du glissement de largeur du fill à définir dans le DS, ou fill statique).
