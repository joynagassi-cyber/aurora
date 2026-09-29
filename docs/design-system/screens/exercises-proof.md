# Écran : exercises-proof — Exercices de preuve

> Module Learning · Route `/learn/:id` (overlay IonModal sur le tab courant, 02 §6.1 S1/S3, router.tsx) · SSoT WDS 01.6 + catalog `learning.import` · Statut : additif

## §1 Psychologie designer

- **Objectif utilisateur** : exécuter l'exercice progressif sur un domaine (RDM, poutre encastrée) — vérifié par le **Scientific Engine** (unités/dimensions, `scientific.evaluate`/`scientific.verify`) — et produire 1 `ProgressEvidence` (AD-9, F-07) qui prouve le transfert par l'exercice progressif (pas juste le QCM ou le miroir).
- **Contexte** : mobile, main libre, réseau 3G instable probable ; sessions nocturnes (thème Nocturne par défaut, OQ-16) ; exercice = plusieurs sous-étapes (3-7 adaptatif, OQ-2 WDS 01.6) ; chaque sous-étape validée par le Scientific Engine (serveur-only, AD-12).
- **Fréquence** : sessions de révision, plusieurs fois par semaine ; contenu local (AD-7) mais validation = flux serveur (AD-12).
- **État émotionnel cible** : concentration (exercice = tâche cognitive), confiance (validation Scientific Engine visible), motivation (preuve `ProgressEvidence` produite), calme (pas de frustration si échec, retry disponible).
- **Erreur la plus probable** : unités/dimensions non conformes (échec validation Scientific Engine) → message lisible « Validation non conforme : unités erronées » + CTA « Réessayer » (AD-13, A4 : erreur lisible, retry toujours disponible) ; abandon avant validation (fatigue nocturne, ADR §23.1).
- **Ce que l'écran RÉSOUT** : surface d'exécution d'exercice progressif (3 zones fixes : progression, exercice courant, validation fin) + auto-redirect événementiel vers `/progress` (pas un CTA manuel, invariant AD-14, Q8 passo 6) ; la validation de l'exercice déclenche le re-render du dashboard à l'événement `ProgressEvidenceCreated` (AD-9 → ProgressSnapshot, ADR §18.6).

## §2 Contexte fonctionnel

- **Entrée** : CTA fixe « Exercice progressif » du mirror-cognitive (01.5, S-22) — Zone 3, fin d'analyse (trigger-map §4 Intent #6) ; retour natif depuis `/progress` (01.7) si l'utilisateur revient en arrière (invariant S6.2) ; deep link `/exercises/:id` (push notification, automatisation, S-31 parcours #17, 5 points d'entrée).
- **Overlay IonModal `/learn/:id`** (router.tsx detail-over-tab rule 02 §6.1 S1/S3) : le tab courant reste sous l'overlay (pas de navigation destructive).
- **Data** : exercice progressif = **génération à la volée** (pas pré-généré, OQ-1 WDS 01.6 tranchée 09/25) — le Scientific Engine (module serveur-only, AD-12) génère au moment de la session, pas de pré-génération ; nombre de sous-étapes **adaptatif** (3-7 selon niveau, OQ-2 WDS 01.6 tranchée 09/25, trigger-map §4 Intent #6).
- **Async** : lecture exercice = **serveur** (AD-12/F-09, Agent kernel `Plan → Retrieve → Tools → Verify`) → killed possible sur ce flux ; **pas de mirror local pour le Scientific Engine** (contrairement aux flashcards, AD-7) ; validation = flux serveur uniquement (offline = indisponible, AD-7 « offline = état premier » mais le module est serveur-only).
- **Saisie** : `UnitTextField` (wrapper DS, 05 §3.2) = `TextField` + suffixe fixe (ex. `kN·m` en `JetBrains Mono`) — l'utilisateur ne tape **que le nombre**, l'unité est **fixe et explicite** (règle de non-surprise : « 25,4 » + suffixe `kN·m` ≠ « 25,4 kN·m est-ce compris ? ») ; `inputMode: 'decimal'` (mobile : le clavier numérique = essentiel pour les formules, doc §15).
- **Auto-redirect** : la validation de l'exercice déclenche l'**auto-redirect événementiel** vers `/progress` (01.7) — re-render du dashboard à l'événement `ProgressEvidenceCreated` (AD-9 → ProgressSnapshot, ADR §18.6) — **pas un CTA manuel** (invariant AD-14, Q8 passo 6) ; c'est le **seul mécanisme de sortie** de la surface.

## §3 Éléments (work of detail — 100 % de la zone)

| Élément | Composant DS 05 §3 | Lib ui-libraries S1 | Tokens | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Header overlay (TopBar retour + titre « Exercices » `lg`) | 05 §3.1 Actions + shell IonModal header | shadcn Battery ; header = band pleine largeur, pas de card (dashboard.tsx pattern S4) | --aurora-bg-subtle, --aurora-text-primary (titre lg, 05 §2.2) | pleine largeur, radius top 8px (pas > 8px, S3 l.142) | 05 §4.6.2 pattern header + WDS 01.6 Zone 1 |
| Zone 1 : Progression (badge « Sous-étape 2/5 » + domaine : RDM, poutre encastrée) | 05 §3.3 Affichage (Badge/Chip) | shadcn Badge (statut, non amovible) + texte `sm` 500 | --aurora-primary-surface (fond badge), --aurora-text-primary ; radius `sm` (05 §3.3) | compact, inline sous le header (pas de card) | WDS 01.6 Zone 1 « Progression » |
| Zone 2 : Exercice courant (énoncé + saisie numérique : valeur + unités + CTA « Valider l'étape ») | 05 §3.2 Formulaires (UnitTextField) + 05 §3.1 Actions (Button) | shadcn Input (label au-dessus, jamais à l'intérieur, 05 §3.2) + shadcn Button primary (CTA dominant, max 1 par écran, AD-14) ; **pas** ion-item forms (S3 l.137 interdit, → shadcn/Radix) | --aurora-accent-primary, --aurora-on-primary (CTA), --aurora-border, --aurora-text-primary (énoncé), JetBrains Mono (unités, 05 §2.2) ; height ≥ 44px (56px High Contrast, 05 §6.3) | pleine largeur mobile ; énoncé = `base` Inter, unités = suffixe fixe `JetBrains Mono` (pas de saut de layout) | WDS 01.6 Zone 2 « Exercice courante » + 05 §3.2 UnitTextField |
| Zone 3 : Validation (fin de session) : Scientific Engine : VALIDÉ ✓ + auto-redirect événementiel vers `/progress` (01.7) | 05 §3.3 Affichage (Callout success) + 05 §3.1 Actions (Button ghost, si retry) | shadcn Alert (success, non blocking) + shadcn Button ghost (si échec) ; **pas** de CTA manuel pour l'auto-redirect (invariant AD-14) | --aurora-success, --aurora-success-surface (fond Callout), --aurora-text-primary ; radius `md`, padding `space.3` (05 §3.3 Callout) | centré, pleine largeur, non bloquant (le contenu local reste lisible, AD-7) | WDS 01.6 Zone 3 « Validation (fin) » + 05 §3.3 Callout |
| CTA principal « Valider l'étape » (Zone 2) | 05 §3.1 Actions (Button) | shadcn Button primary (headless Radix + Tailwind, skinnable via --aurora-* vars) | --aurora-accent-primary, --aurora-on-primary ; height ≥ 44px ; `loading` state = ProgressRing 16px **dans** le bouton (pas un spinner externe, 05 §3.1) ; **jamais** un button `loading` qui désactive tout l'écran (le reste reste interactif, AD-7) | bas de l'écran (actions flottantes, 05 §4.6.2 pattern), pleine largeur mobile | WDS 01.6 Zone 2 CTA + 05 §3.1 Button |
| Badge « en cours » / « terminé » / « échec » (états sémantiques §6.1) | 05 §3.3 Affichage (Badge) | shadcn Badge | --aurora-warning (en-cours), --aurora-success (terminé), --aurora-danger (échec) ; tokens sémantiques **frozen** (05 §5.1 règle bloquante : thème ne touche jamais success/warning/danger/info) | compact, inline dans la Zone 1 (progression) | WDS 01.6 + ui-libraries §6.1 l.189–202 |
| Callout danger (échec validation Scientific Engine : unités/dimensions non conformes) | 05 §3.3 Affichage (Callout) | shadcn Alert (destructive) + shadcn Button ghost « Réessayer » (retry in-place, AD-13 A4) | --aurora-danger, --aurora-danger-surface ; radius `md`, padding `space.3` ; icône 24px `danger` (05 §3.3 Callout) | centré, non bloquant (les autres zones restent accessibles, AD-7) ; **pas** de Callout qui disparaît (l'erreur est affichée, AD-7) | WDS 01.6 état `Error` + 05 §3.3 Callout |
| État loading (Skeleton exercice courant + CTA indisponible pendant validation) | 05 §2.6 + 05 §3.7 (AD-13) | shadcn Skeleton | --aurora-skeleton ; **durée** = 2-5s par sous-étape (validation serveur, AD-12) ; **pas** de layout animation (S5 l.169) ; **pas** de shimmer directionnel (05 §2.6 règle 4) | pulse via opacité (pas de reflow) ; si > 300ms → contenu partiel en dessous (pack 02 §7) | WDS 01.6 état `Loading` + 05 §3.7 AD-13 |
| État empty (pas d'exercice actif : aucun domaine RDM sélectionné) | 05 §3.3 Affichage (EmptyState) | shadcn Button primary « Revenir à /progress » (CTA actionnable, pack 02 §7) | --aurora-bg-subtle, --aurora-text-secondary (body `sm`, max 2 lignes) ; icône 48px `text-muted` (05 §3.3 EmptyState) ; **pas** de widget dashboard (AD-14) | centré, pleine largeur ; CTA = retour natif (invariant S6.2) | WDS 01.6 état `Empty` + 05 §3.3 EmptyState |
| État offline (bandeau fine « hors-ligne — validation indisponible ») | 05 §3.3 Affichage (Callout info) | shadcn Badge (offline, header) + shadcn Callout info (non bloquant) | --aurora-info (frozen, jamais redéfini par thème, 05 §5.1) ; **pas** de CTA serveur (la validation n'est pas actionnable offline) ; actions cloud désactivées **avec explicatif** (pas masquées, AD-13 A5) | bandeau fine en haut (05 §3.3 Callout global) ; retour natif vers `/mirror` (01.5) ou `/progress` (01.2) | WDS 01.6 état `Offline` + 05 §3.3 Callout |
| État killed (flux serveur uniquement : Skeleton + « Reconnexion... ») | 05 §3.7 (matrice AD-13) | shadcn Skeleton + texte `sm` `text-muted` | --aurora-skeleton, --aurora-danger (badge d'état) ; priorité killed > offline > query (ssootCode stateRefs ux-states.tsx) ; **pas** de CTA, **pas** de retry, **pas** de navigation | pas de crash, pas de perte de contenu local (AD-7) ; reconnexion OK → re-query → loading/success | WDS 01.6 + ssootCode stateRefs (ux-states killed) |
| 404/not-found (id inconnu, exercice supprimé) | 05 §6.1 (état 404) + §3.1 | logo AURORA monochrome centré (§9.1/§6.1) + shadcn Button « Retour à l'accueil » | --aurora-bg-subtle, --aurora-text-primary ; logo = version monochrome §9.1 (pas de fond, pas de recolor, S9 interdits l.390–392) ; **jamais** la version full en in-app (S9 l.352–353) | centré, pleine largeur ; entrée = fade 200ms ; sortie = navigate back (close overlay) | WDS 01.6 + ui-libraries §6.1 l.202 + §9.1 l.371–405 |

## §4 États (matrice complète AD-13 / 05 §3.7 l.1244–1309)

### (a) 6 états S6 par élément async (ui-libraries §6 l.174–187)

- **loading** (validation Scientific Engine en cours, AD-12, module serveur-only, ~2-5 s par sous-étape) : Zone 2 = skeleton de l'exercice courant + CTA indisponible (pas d'actions avant données) ; tokens = --aurora-skeleton ; texte exact = « Validation en cours… » (court, car serveur AD-12) ; CTA = aucun (pas de retry pendant le loading) ; **entrée** = fade 200ms easeOut (PAGE_TRANSITION, ssootCode motionRefs polish.tsx) ; **sortie** = skeleton → contenu partiel crossfade 200ms (pack 02 §7 : si > 300ms le contenu apparaît partiellement en dessous du Skeleton) ; **pas** de layout animation (S5 l.169).
- **empty** (pas d'exercice actif : aucun domaine RDM sélectionné) : zone contenu vide + CTA primaire « Revenir à /progress » (retour natif, invariant S6.2) ; tokens = --aurora-bg-subtle + --aurora-text-secondary ; **entrée** = fade 200ms ; **sortie** = tap CTA → navigation vers `/progress` (01.2).
- **error** (échec validation Scientific Engine : unités/dimensions non conformes) : Callout danger (« Validation non conforme : unités erronées ») + CTA ghost « Réessayer » (re-saisie, AD-13 A4) ; tokens = --aurora-danger / --aurora-danger-surface ; **entrée** = fade 200ms ; **sortie** = retry OK → Zone 2 rechargée, Callout disparaît ; si fail → retry encore (pas de crash).
- **success** (validation OK, fin de session) : Zone 3 = Callout success (« Scientific Engine : VALIDÉ ✓ (unités/dimensions conformes, scientific.evaluate/verify) ») + auto-redirect événementiel vers `/progress` (pas un CTA manuel, invariant AD-14) ; tokens = --aurora-success / --aurora-success-surface ; **entrée** = fade 200ms ; **sortie** = auto-redirect OK → navigation vers `/progress` (01.7), overlay fermé.
- **offline** (réseau coupé, validation non disponible : module serveur-only) : Badge offline (header) + Callout info (« Hors-ligne — validation indisponible ») ; tokens = --aurora-info (frozen) + --aurora-warning (badge) ; CTA = import/qcm désactivés (pas de CTA serveur) ; **entrée** = fade 200ms ; **sortie** = retour online → refetch (retour au flux loading/success) ; **pas** de CTA d'action (la validation n'est pas actionnable offline).
- **killed** (flux serveur uniquement, AD-13/G-M2) : Skeleton + « Reconnexion… » ; tokens = --aurora-skeleton + --aurora-danger ; CTA = **aucun** (pas de retry, pas de navigation, ssootCode stateRefs ux-states.tsx) ; **entrée** = fade 200ms ; **sortie** = reconnexion OK → re-query → loading/success ; le contenu **local** (AD-7) reste lisible en dessous (pas de crash, pas de perte de contenu local).

### (b) États sémantiques §6.1 (ui-libraries l.189–202)

- **en-cours** (exercice en cours, sous-étape 2/5, validation en attente) : ring node = `warning/50` (Fragile pattern, ssootCode stateRefs SemanticTreeRenderer mapping) + Badge « En cours… » (non amovible) ; tokens = --aurora-warning ; CTA = CTA principal « Valider l'étape » reste actif (pas de blocage) ; source = 05 §3.6 node states + ui-libraries §6.1 l.197.
- **terminé** (exercice validé, auto-redirect déclenché) : ring node = `success/50` (mastered, ssootCode SemanticTreeRenderer mapping) + Callout success (Zone 3) ; tokens = --aurora-success ; CTA = **aucun** (auto-redirect = seul mécanisme de sortie, invariant AD-14) ; source = ui-libraries §6.1 l.198 + 05 §3.6.6.
- **échec** (validation échouée, retry in-place) : ring node = `danger/50` (forgotten/fragile, ssootCode stateRefs) + Callout danger (« Validation non conforme : unités erronées ») avec explication **séparée** de la correction (AD-11, §4.8.2 pattern) ; tokens = --aurora-danger / --aurora-warning ; CTA = « Réessayer » (re-saisie, pas de CTA manuel de sortie) ; source = ui-libraries §6.1 l.199 + 05 §3.3 Callout.
- **succès / erreur générique** = N/A (raison : pas d'écriture dans l'écran — l'exercice est une vue de lecture + validation, pas de mutation locale ; toute erreur/succès = Callout/Toast §4a, pas d'état sémantique d'écran propre).
- **404/not-found** = §4c ci-dessous (id inconnu / exercice supprimé / exercice désactivé par feature-registry : data-state=feature-disabled + CTA re-enable, ssootCode stateRefs not-found/index.tsx, **jamais** un crash/404 brut).

### (c) 404 / not-found (écran routé `/learn/:id`, oui → règle §6.1 l.202)

- Page entière = overlay (pas de page standalone) : **logo AURORA monochrome centré** (version = §9.1 monochrome l.378–388, **pas** de fond, **pas** de recolor (S9 interdits l.390–392), **jamais** la version full en in-app (S9 l.352–353)) ; message court = « Exercice introuvable » ; CTA primaire = « Retour à l'accueil » (shadcn Button, --aurora-accent-primary, ≥ 44px) ; tokens = --aurora-bg-subtle + --aurora-text-primary ; **entrée** = fade 200ms easeOut ; **sortie** = navigate back (close overlay, retour au tab courant) ; source = ui-libraries §6.1 l.202 + §9.1 l.371–405 + 05 §3.1.

### (d) killed sur tout flux serveur (AD-13/G-M2, ui-libraries §6 l.185)

- killed = Skeleton + « Reconnexion… » (§4a killed row) : **pas** de CTA, **pas** de retry, **pas** de navigation ; tokens = --aurora-skeleton (+ --aurora-danger pour le badge d'état) ; **entrée** = fade 200ms ; **sortie** = reconnexion → re-query → loading/success ; portée = **flux serveur uniquement** (validation Scientific Engine, AD-12) : la lecture locale (AD-7) est **inchangée** et reste utilisable pendant le killed (pas de crash, pas de perte de contenu local).

## §5 Animations (GPU only, 150–250ms, reduced-motion = statique — 05 §2.6 + ui-libraries S5 l.169)

| Élément | Action → feedback | Durée | GPU only (transform/opacity) | Smooth | reduced-motion = statique | Source SSoT |
|---|---|---|---|---|---|---|
| Header (ouverture overlay) | tap depuis mirror-cognitive → open | 200ms easeOut (PAGE_TRANSITION opacity 0→1, y 8→0, exit y -4) | opacity + translateY, **pas** de layout | easeOut (pas de spring/bouncy, S3 l.143) | statique (div fixe, ssootCode motionRefs) | ssootCode motionRefs polish.tsx + ui-libraries S5 l.169 |
| Zone 2 (chargé) | skeleton → contenu | crossfade 200ms easeOut | opacity (pas de scale, pas de reflow) | easeOut | statique | ssootCode motionRefs + 05 §2.6 |
| CTA « Valider l'étape » (tap) | tap → pressed | 150ms easeOut (anim.fast, 05 §2.6) | scale 0.95 (pas de layout, S5 l.169) ; pas de bouncy | easeOut | statique (pas d'anim) | ssootCode motionRefs + 05 §2.6 |
| Callout danger (échec) | validation fail → Callout appear | fade 200ms easeOut | opacity (pas de scale) | easeOut | statique | ssootCode motionRefs + 05 §2.6 |
| Callout success (validation OK) | validation OK → Zone 3 appear | fade 200ms easeOut | opacity (pas de scale) | easeOut | statique | ssootCode motionRefs + 05 §2.6 |
| Auto-redirect (fin) | validation OK → navigate `/progress` | fade 200ms easeOut (close overlay) | opacity + translateY (exit y -4) | easeOut | statique | ssootCode motionRefs polish.tsx + ui-libraries S5 l.169 |
| Focus Mode (data-focus-mode=true) | attenuated animations + deferred toasts (ssootCode forbidden : `[data-focus-mode=true] .animate-pulse-skeleton = animation:none`) | N/A (règle globale) | N/A | N/A | statique | ssootCode forbidden (Focus Mode rule 3, 05 §2.6) |

## §6 Tokens (discipline AD-17, 05 §2 l.93–346 + ui-libraries S4 l.145–160)

- **Aucune valeur brute** : pas de hex, pas de px de spacing/typo/radius codé en dur — toujours via variables CSS `hsl(var(--aurora-*))` (05 §5.2/5.3, ssootCode tokenRefs aurora.css).
- **Règle bloquante 05 §5.1 (l.2931)** : le thème ne touche **jamais** success/warning/danger/info (frozen semantic tokens) — utiliser uniquement via les variables, pas de redefinition par thème.
- **10 thèmes + 3 presets = comportement par couche** (05 §5.2, ssootCode themeRefs) : pas de valeur par thème (jamais d'override par thème sauf L3 local override = Focus only, OQ-15) ; l'écran ne code **aucune** valeur par thème.
- **focus visible** : le theme owns focus-ring (aurora.json focusTreatment = ring, ssootCode a11yRefs) — pas de gestion manuelle du focus par écran.
- **icônes** : 05 §2.5 (l.287) — lucide (ssootCode paginationRefs Chevrons/MoreHorizontal) ; **pas** de custom SVG decoration (S3 l.141 interdit, ssootCode forbidden).
- **coins** : radius ≤ 8px (S3 l.142 interdit > 8px) ; **élévations** = 05 §2.4 (l.254), pas de box-shadow brut.
- **Unités** : toujours `JetBrains Mono` + `font-variant-numeric: tabular-nums` (05 §2.2, ssootCode themeRefs aurora.css) ; **pas** de saut de layout (pas de reflow).

## §7 i18n / copy

- Copy = FR (app FR, ssootCode themeRefs + router.tsx context) ; tous les textes = FR (« Validation en cours… », « Exercice introuvable », « Retour à l'accueil », « Scientific Engine : VALIDÉ ✓ », « Validation non conforme : unités erronées », « Réessayer », « Reconnexion… », « Hors-ligne — validation indisponible »).
- Pas de copy EN (pas de hardcoded EN, ssootCode paginationRefs note) ; si i18n = OQ-01 (§14).

## §8 Pagination

- **Règle unique nommée : shadcn Pagination** (ui-libraries S1 l.37) — **paramètres** : pas de pagination par défaut pour l'exercice (3-7 sous-étapes adaptatif, OQ-2 WDS 01.6 tranchée 09/25, **jamais** > 100 lignes).
- Si sous-étapes > 20 (cas rare, pas prévu) → **shadcn Pagination** (20–100 = + pagination, ui-libraries S8 l.304–307) ; si > 100 (interdit par design, 3-7 max) → **pas** d'AG Grid sur ce flux (pas de data table dans l'écran, S3 l.136 interdit ion-list data).
- **JAMAIS** : AG Grid shadcn Pagination Pager jour/semaine/mois (05 §3.4) sur ce flux (pas de calendrier dans l'écran) ; **pas** de 2 lib sur le même écran (S8 l.333 interdit, ssootCode forbidden).

## §9 Surfaces flottantes (05 §3.5 l.752–865)

- **Modal** = l'overlay IonModal lui-même (§2, router.tsx) ; **pas** de Modal imbriquée dans l'overlay (pas de double floating surface).
- **Toast/Snackbar** (05 §3.5 l.823) : feedback validation success/error (§4a success/error) ; **pas** de BottomSheet ni Drawer dans l'écran (pas d'édit d'exercice ici, l'exercice = lecture seule + validation, AD-12 serveur-only).
- **Menu / Dropdown / Popover** : import = Popover shadcn (§3, empty row, S3 l.138 pattern) ; **pas** de Menu contextuel par long-press (pas spec, OQ-02 §14).
- Règle S8 l.333 : **ne jamais mélanger 2 libs sur le même écran** — toutes les surfaces = shadcn/Radix (ui-libraries S1 l.13–14), **pas** de MUI/Ant/Chakra (S3 l.139 interdit).

## §10 Focus Mode (05 §2.6 règle 3, ssootCode forbidden)

- `[data-focus-mode=true]` → attenuated animations (pas de pulse skeleton, ssootCode forbidden : `[data-focus-mode=true] .animate-pulse-skeleton = animation:none`) ; deferred toasts (pas d'interruption) ; contenu inchangé (pas de data change, pas de re-layout, S5 l.169 GPU only) ; pas de CTA modifié (le CTA principal reste actif mais visuellement atténué, OQ-05 §14 si spec manquante).

## §11 Data / contrats (AD-10/AD-12, ssootCode componentRefs)

- **Scientific Engine** = module serveur-only (AD-12) : validation = flux serveur, **pas** de mirror local (contrairement aux flashcards, AD-7) ; `scientific.evaluate`/`scientific.verify` (WDS 01.6, ADR §18.3) ; **pas** d'import direct du moteur dans l'écran (AD-10 boundary, ssootCode componentRefs contracts.ts).
- **ProgressEvidence** = AD-9/F-07 : l'écran **n'émet jamais** `ProgressEvidenceCreated` (AD-2/F-07 : seul Progress l'émet, les événements Learning **alimentent** l'exercice) ; pas de write direct dans l'écran (lecture seule + validation serveur).
- **Local SQLite (AD-7)** : exercice = miroir local (mémo §12) ; **pas** de cache par design pour la validation (serveur-only, AD-12/F-09, WDS 01.6 « le Scientific Engine est un module serveur-only »).

## §12 Offline (classe AD-1/AD-7/AD-12)

- **Classe offline** : **master-feature-catalog** (Learning = feature master, pas optionnelle ; ssootCode stateRefs ascent/index.tsx offline badge via useOnlineStatus) → **miroir local (AD-7/AD-12)** : exercice = SQLite (contenu local, WDS 01.6 offline = « l'exercice est consultable (AD-7 local : SQLite, pas de dépendance cloud) »).
- **Dégradation AD-1** : offline → Badge offline (header) + Callout info « Hors-ligne — validation indisponible » (WDS 01.6 état `Offline`) ; la validation Scientific Engine est **différée** (pas de crash, pas de CTA serveur) ; le contenu local reste 100 % lisible (pas de perte, pas de cache manquant).
- **Ce qui meurt (killed)** : flux serveur uniquement (validation Scientific Engine, AD-12) → Skeleton + « Reconnexion… » (§4a/§4d) ; la lecture locale **ne meurt jamais** (AD-7) ; pas de validation exécutée hors-ligne (AD-12/F-09, WDS 01.6 « le Scientific Engine est un module serveur-only »).

## §13 Logos (occurrences + version exacte, ui-libraries §9 l.349–487)

- **1 seule occurrence** : logo AURORA **monochrome** centré (404/not-found, §4c) — version = §9.1 monochrome (matrice l.378–388), **pas** de fond (in-app = « colorée sans fond / monochrome §9.1 », **jamais** la version full app icon en in-app, S9 l.352–353 + ssootCode logoRefs dashboard.tsx IN_APP_LOGO pattern) ; raison (designer psychology) = feedback d'erreur = calme, pas de brand noise (logo statique, pas d'anim) ; SSoT ref = ui-libraries §9.1 l.371–405 + S9 interdits l.390–392 (pas de recolor, pas de détour, pas de redessin).
- **Pas d'autres occurrences** : header = texte uniquement (« Aurora » via Shell.tsx chrome, pas de logo asset, ssootCode logoRefs) ; contenu = pas de decoration logo (S3 l.141 custom SVG interdit) ; **usage ad hoc interdit** (S9 : toute utilisation hors 404 / AgentThinkingLoader / settings = OQ, ssootCode logoRefs) ; pas d'AgentThinkingLoader dans cet écran (pas de streaming IA, la validation est **côté serveur** puis exécutée, pas de thinking state visible ici ; si thinking = AgentThinkingLoader §9.3 l.420–487, **pas** de wing-flap v2 bloqué l.467–480).
- **C2PA stripped copy** (§9.2 l.407–418) : le logo monochrome in-app = build artifact strippé (pas de métadonnées C2PA, ssootCode logoRefs) ; **pas** de logo avec C2PA dans l'écran.

## §14 Open Questions (OQ)

- **OQ-01** : i18n / copy — l'écran est FR-only par design (ssootCode themeRefs app FR) mais **pas** de SSoT explicite pour la gestion i18n (pas de rule de fallback langue, pas de toggle) → **OQ** (pas de spec i18n, pas de composant i18n dans la battery shadcn, pas de SSoT pour copy EN/FR mix).
- **OQ-02** : Menu contextuel (long-press sur Zone 1/2/3) — **pas** de SSoT pour un menu contextuel dans cet écran (pas de spec dans WDS 01.6, pas de pattern dans ui-libraries S1/S9) → **OQ** (pas de spec, pas de composant dédié, pas de rule pour long-press sur mobile).
- **OQ-03** : `UnitTextField` (Zone 2, §3 row 3) — 05 §3.2 cite le composant (wrapper DS, §3.6.4 indirect) mais **pas** de SSoT pour l'implémentation shadcn (pas de spec pour `TextField` + suffixe fixe `JetBrains Mono` dans la battery shadcn ; pas de composant dédié `UnitTextField` dans ui-libraries S1) → **OQ** (pas de spec UnitTextField, pas de composant dédié dans la battery, pas de rule pour « saisie numérique + unité fixe »).
- **OQ-04** : Auto-redirect événementiel (Zone 3, §3 row 4) — WDS 01.6 dit « auto-redirect événementiel vers `/progress` (pas un CTA manuel, invariant AD-14) » mais **pas** de SSoT pour le mécanisme (pas de rule pour « événement `ProgressEvidenceCreated` → re-render dashboard » ; pas de spec pour le timing de l'auto-redirect ; pas de composant dédié dans la battery shadcn) → **OQ** (pas de spec auto-redirect, pas de rule pour événement → re-render, pas de composant dédié).
- **OQ-05** : Focus Mode atténuation (OQ-15 V1, ssootCode themeRefs theme-adapter.tsx FOCUS_OVERRIDES) — l'écran **consomme** l'override (pas de code Focus-specific, §10) mais **pas** de SSoT pour l'atténuation visuelle du CTA principal (pas de rule pour « atténué = quelle opacité / quel token » ; l'override Focus = `node.secondary-opacity`/`node.active-contrast`, **pas** les CTA) → **OQ** (pas de spec atténuation CTA, pas de token dédié, pas de rule pour CTA in Focus Mode).
- **OQ-06** : Transition sortie vers `/progress` (fin, §4a success) — WDS 01.6 dit « auto-redirect événementiel » mais **pas** de SSoT pour la transition (pas de rule slide/push, pas de pattern navigation entre overlays ; ssootCode floatingSurfaces router.tsx dit « details open OVER the current tab » mais **pas** de spec transition overlay → autre route) → **OQ** (pas de spec transition, pas de rule pour navigate entre 2 overlays, pas de composant transition dédié).
- **OQ-07** : Nombre de sous-étapes (3-7 adaptatif, OQ-2 WDS 01.6 tranchée 09/25) — WDS 01.6 dit « nombre de sous-étapes adaptatif » mais **pas** de SSoT pour l'implémentation (pas de rule pour « adaptatif = quelle logique ? » ; pas de spec pour le calcul du nombre ; pas de composant dédié dans la battery shadcn) → **OQ** (pas de spec adaptatif, pas de rule pour calcul, pas de composant dédié).
- **OQ-08** : 2 panneaux desktop (Phase 2, doc §23.4) — WDS 01.6 dit « variantes = 2 (Nocturne · Light) » mais **pas** de SSoT pour le breakpoint (pas de rule pour « desktop = quel width min », pas de pattern de split-view dans ui-libraries S1) → **OQ** (pas de spec breakpoint, pas de rule pour split-view mobile → desktop, pas de composant split dans la battery).
