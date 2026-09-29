# Écran : fiches-detail — Fiches (détail)

> Module Learning · Route `/learn/:id` (overlay IonModal sur le tab courant, 02 §6.1 S1/S3) · SSoT 05 §4.7.1 · Statut : détaillé

## §1 Psychologie designer

- **Objectif utilisateur** : voir tout le contenu d'une fiche (learning card / fiche connaissance) : texte, média, QCM, liens vers nœuds de connaissances connexes — pour consolider l'acquisition.
- **Contexte** : mobile, main libre, réseau mobile/patchy probable ; ouverture depuis Home (côté Knowledge) ou depuis Knowledge list ; overlay = l'utilisateur reste dans son flux (pas de navigation destructive).
- **Fréquence** : plusieurs fois par jour (révision), en sessions courtes ; lecture + interaction QCM.
- **État émotionnel cible** : focus, confiance en sa progression (retour de mastery immédiat), faible friction.
- **Erreur la plus probable** : tap par erreur pendant lecture (pas de confirmation demandée), retour arrière sans savoir si la progression a été enregistrée (mirage).
- **Ce que l'écran RÉSOlut** : surface de lecture + évaluation instantanée (QCM inline) + navigation vers les fiches connexes, avec progression et état de mastery visuel.

## §2 Contexte fonctionnel

- Opened over Home/Knowledge tab (IonModal — 02 §6.1 S1/S3 detail-over-tab rule, router.tsx: `/learn/:id` in overlay list).
- Data : `learn` module — fiche = contenu textuel + optionnel QCM + liens vers `knowledge` nodes (SemanticTree context).
- Async fetch per fiche id : `useQuery`-like (AD-13 6 states), killed state global (AD-13/G-M2).
- QCM section = CTA per question (feedback success/error per réponse).
- Progression : masterie (Acquis/Fragile/Oublié/À venir) visible via node state (SemanticTreeRenderer ring mapping — ssootCode stateRefs).

## §3 Éléments (work of detail)

| Éléments | Composant DS 05 §3 | Lib ui-libraries S1 | Tokens | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Header overlay (titre fiche + close) | 05 §3.1 (Actions) + shell IonModal header | shadcn (Battery) ; header = band pleine largeur (pas de card, 05 §3.3 + dashboard.tsx S4) | --aurora-bg-subtle, --aurora-text-primary | pleine largeur, radius 8px top (pas > 8px) | ui-libraries S1 l.13–14 ; 05 §3.3 |
| Zone contenu (texte/media) | 05 §3.3 Affichage | Surface shadcn (Text/Markdown renderer, Media = native) | --aurora-surface, --aurora-text-primary, --aurora-text-secondary | scrollable, 16px padding mobile | ui-libraries S1 ; 05 §3.3 |
| Section QCM (si présente) | 05 §3.2 Formulaires + 3.1 Actions | shadcn Select/Radio/Checkbox + Button | --aurora-accent-primary, --aurora-border, tokens success/danger (état) | questions empilées, choix full-width mobile | ui-libraries S1 l.13–14 ; 05 §3.2 |
| CTA principal (soumettre QCM / marquer acquis) | 05 §3.1 Actions | shadcn Button (headless Radix) | --aurora-accent-primary, --aurora-on-primary | full-width, height ≥ 44px (a11y) | ui-libraries S1 ; 05 §3.1 |
| Lien vers nœuds connexes (knowledge graph local) | 05 §3.3 + SemanticTreeRenderer (si contexte) | packages/ui SemanticTreeRenderer (React Flow) si arbre ; sinon DataTable/Timeline simple | --aurora-node-mastered/fragile/forgotten, --aurora-border | si arbre : lazy level-1, 30fps mobile ; sinon list | ssootCode keyFiles (SemanticTreeRenderer) ; 05 §3.6 |
| Badge état de mastery (Acquis/Fragile/Oublié/À venir) | 05 §3.3 + node state | shadcn Badge | tokens node (success/50, warning/50, danger/50, border) | compact, inline header | ssootCode stateRefs (SemanticTreeRenderer) ; 05 §3.3 |
| Toast/Snackbar feedback (QCM réponse) | 05 §3.5 Surfaces flottantes | shadcn Toast/Snackbar | --aurora-success/danger (état), --aurora-surface-overlay | bottom, non-blocking | 05 §3.5 l.823 ; ui-libraries S1 |
| État loading (skeleton contenu) | 05 §2.6 + 05 §3.7 (AD-13) | shadcn Skeleton | --aurora-skeleton | pulsing (pas de layout animation) | ssootCode themeRefs (aurora.css skeleton) ; 05 §3.7 |
| État killed (reconnexion) | AD-13 + 05 §6.1 | Alert/shadcn + skeleton freeze | --aurora-skeleton, --aurora-danger | « Reconnexion... » centré | ssootCode stateRefs (ux-states killed) ; ui-libraries §6.1 l.202 |
| CTA « Retour à l'accueil » (404/not-found per §4c) | 05 §3.1 + §6.1 l.202 (404 = FULL-SCREEN centered logo, §9.1 l.387) | shadcn Button | --aurora-accent-primary, logo = COLORED without-background centré (per §9.1 l.387 ; l'ancienne ligne erronée « OQ-10 : SSoT fictive » est corrigée, voir §10) | centré, pleine largeur | ui-libraries §9.1 l.387 + §6.1 l.202 ; OQ-07/OQ-10 (tranchement owner) |

## §4 États (matrice complète AD-13/05 §3.7)

### (a) 6 états S6 par élément async

- **loading** : Skeleton contenu + header statique ; tokens = skeleton ; texte = « Chargement de la fiche... » ; CTA = aucun (pas d'actions avant données) ; transition d'entrée = fade 200ms easeOut (PAGE_TRANSITION ssootCode motionRefs) ; transition de sortie = skeleton → contenu (crossfade 200ms).
- **empty** : pas de fiche pour l'id (id invalide, supprimée) → état empty + CTA « Retour à l'accueil » (même que 404, §4c) ; tokens = bg-subtle, text-secondary ; entrée = fade 200ms ; sortie = retour (navigate back).
- **error** : fetch fail (network/5xx) → Alert danger + message court + CTA retry (« Réessayer ») ; tokens = danger ; entrée = fade 200ms ; sortie = si retry OK → contenu, si fail → retry encore.
- **success** : contenu chargé + QCM répondu OK → toast success (« Acquis ! ») ; tokens = success ; entrée = toast slide up 200ms (pas de layout) ; sortie = toast auto dismiss 3s.
- **offline** : badge offline (useOnlineStatus ssootCode stateRefs) + contenu caché (pas de lecture hors-ligne par design, AD-1) ; CTA « Reconnexion... » ; tokens = warning + skeleton ; entrée = fade ; sortie = quand online → refetch.
- **killed** : killed state global (ux-states resolveUxState killed>offline>query) → skeleton + « Reconnexion... » (pas de crash) ; tokens = skeleton + danger ; entrée = fade ; sortie = pas de sortie (killed = terminal local, attendant reconnexion).

### (b) États sémantiques §6.1

- **en-cours** : QCM en cours (questions répondues mais non soumises) → badge warning « En cours... » ; tokens = warning ; pas de CTA (attend soumission).
- **terminé** : QCM soumis + acquis → badge success « Acquis » ; tokens = success ; CTA « Voir fiche suivante » (si existante).
- **échec** : QCM soumis + non acquis → badge danger « Oublié » + CTA « Réviser » (replay QCM) ; tokens = danger.
- (Si pas de QCM pour la fiche : N/A — badge only = node state only (Acquis/Fragile/Oublié/À venir), pas de workflow QCM.)

### (c) 404 / not-found (si routé — oui, overlay)

- Page entière = overlay (pas de page standalone) : logo AURORA **COLORED without-background centré** per matrice §9.1 l.387 + §6.1 l.202 (404 = « the only state that MANDATES the centered logo ») — version exacte = `assets/aurora_icon_a_integre_dans_l'applciation.png` (SSoT §9 l.358 : « In-app logo (default) », NEVER app icon) ; **OQ-07** : l'ancienne ligne de ce §4c disait « monochrome » → erronée par rapport à la SSoT §9.1 l.387–392 ; correction appliquée ici, tranchement final per owner ; message court « Fiche introuvable » + CTA primaire « Retour à l'accueil » (shadcn Button, --aurora-accent-primary) ; tokens = bg-subtle, text-primary ; entrée = fade 200ms ; sortie = navigate back (close overlay) ; source = ui-libraries §6.1 l.202 + §9.1 l.387 + §9 l.358.

### (d) killed sur tout flux serveur

- killed = skeleton + « Reconnexion... » (pas de CTA, pas de retry, pas de navigation) ; tokens = skeleton ; entrée = fade 200ms ; sortie = quand reconnexion OK → refetch contenu → success ; source = ssootCode stateRefs (ux-states killed) + ui-libraries §6 l.185.

## §5 Animations (GPU only, 150–250ms, reduced-motion = statique)

| Éléments | Action → feedback | Durée | GPU only | Smooth | reduced-motion=static | Source SSoT |
|---|---|---|---|---|---|---|
| Header (ouverture) | tap → open overlay | 200ms easeOut (PAGE_TRANSITION) | opacity+translateY (pas de layout) | easeOut (pas de spring/bouncy) | static (pas d'animation) | ssootCode motionRefs (polish.tsx) ; ui-libraries S5 l.169 |
| Contenu (chargé) | skeleton → contenu | crossfade 200ms easeOut | opacity (pas de scale) | easeOut | static | ssootCode motionRefs ; ui-libraries S3 l.143 |
| Badge mastery (changement) | state change → badge update | 200ms easeOut | opacity+translateY (pas de scale) | easeOut | static | ssootCode motionRefs ; 05 §2.6 |
| Toast feedback (QCM) | réponse → toast | slide up 200ms easeOut | translateY (pas de layout) | easeOut | static (pas de toast animé) | ssootCode motionRefs ; ui-libraries §3.5 |
| Node tree (si connecté) | node reveal | 150ms easeOut (si non reduced) | opacity+scale (pas de layout) | easeOut | static | ssootCode motionRefs ; 05 §2.6 |
| Button (QCM soumission) | tap → pressed | 200ms easeOut | opacity (pas de scale) | easeOut | static | ui-libraries S3 l.143 |

## §6 Tokens (AD-17 discipline)

- Ne toucher JAMAIS les tokens success/warning/danger/info (règle bloquante 05 §5.1) — utiliser uniquement via variables (hsl(var(--aurora-*))).
- Theme = skin only (AD-17) : pas de valeur brute (aucun hex, aucun px de spacing/typo/radius codé en dur) — toujours via variables CSS (05 §5.2/5.3).
- 10 thèmes + 3 presets = comportement par couche (05 §5.2) : pas de valeur par thème (jamais de override par thème, sauf L3 local override = Focus only, OQ-15).

## §7 Accessibility (WCAG AA, 05 §6.3)

- Tap targets ≥ 44px (56px High Contrast) : CTA, questions QCM, badge tappable (si interactif).
- aria-label sur tous les icon buttons (close header, retry, etc.).
- letter-spacing 0 (pas de tracking, 05 §2.2).
- focus visible (theme owns focus-ring, ssootCode themeRefs aurora.json focusTreatment=ring).
- Progression QCM : role=progressbar + aria-valuenow/min/max/label (si progress bar, ssootCode a11yRefs goal-card.tsx pattern).
- Toast : aria-live=polite (si role=status, ssootCode a11yRefs AgentThinkingLoader pattern).

## §8 Pagination

- 1 règle unique nommée : **shadcn Pagination** (ui-libraries S1 l.37) — si contenu fiche > 20 pages (pas prévu pour fiche = un contenu court) ; sinon N/A (une fiche = une unité de contenu, pas de pagination interne).
- Params : pas de pagination par défaut ; si QCM > 20 questions → shadcn Pagination (20–100 = + pagination per ui-libraries S8 l.304–307).

## §9 Offline (AD-1/AD-7/AD-12)

- **Classe offline** = master-feature-catalog : Learning = module central (non feature optionnelle) → toute fiche = contenu serveur, **pas de cache par design (AD-1)** ; miroir local = **aucun** (AD-7/AD-12 : les fiches ne sont pas synchronisées localement ; pas de SQLite pour le contenu de fiche). SSoT refs = ssootDesign (AD-1/AD-7/AD-12) + ui-libraries §6 l.174–187 (S6 : offline l.184, killed l.185).
- **Dégradation AD-1** : offline → badge offline `useOnlineStatus` (ssootCode stateRefs, pattern apps/mobile/src/pages/ascent/index.tsx) + contenu **caché** (pas de lecture hors-ligne par design, AD-1) ; pas de miroir local → pas de « last-known data » (ui-libraries §6 l.184 prescrit générique « Offline badge + last-known data » ; ici inapplicable car aucun cache → **OQ-06**, à trancher par l'owner : accepter l'absence de last-known ou prévoir un cache minimal hors AD-7/AD-12) ; le CTA est « Reconnexion... » (pas de retry local, pas de navigation destructive) ; texte exact du badge = **OQ-12**.
- **Ce qui meurt (killed)** : killed = skeleton + « Reconnexion... » + shimmer (ui-libraries §6 l.185 : « Skeleton + auto-resync ») (pas de CTA, pas de retry, pas de navigation ; tokens = skeleton + danger) ; pas de contenu affiché, pas de QCM (pas de soumission) ; killed est terminal local en attendant la reconnexion (ux-states.tsx resolveUxState killed>offline>query, ssootCode stateRefs) ; texte exact du killed = **OQ-11** ; source = ui-libraries §6 l.185 + ssootCode stateRefs.

## §10 Logo (occurrences + version exacte)

- **Occurrence 1 — logo AURORA en 404/not-found (page center, §4c)** : version exacte = **COLORED sans fond, centrée** (`assets/aurora_icon_a_integre_dans_l'applciation.png`, SSoT §9 l.358 : « In-app logo (default) : header, page center (empty states…), footer. NEVER as the external app icon ») ; raison : état vivant (CTA primaire « Retour à l'accueil » = marque active = colorée) — matrice §9.1 l.387 « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED » + §6.1 l.202 (404 = « the only state that MANDATES the centered logo, S9 ») ; SSoT ref = ui-libraries §9 l.358 + §9.1 l.371–405 + §6.1 l.202 ; **le §4c du spec a été corrigé** (ancienne mention « monochrome » = erronée, cf. OQ-07/OQ-10) ; usage ad hoc = interdit (S9).
- **Cas prescriptif 2 — logo COLORED sans fond dans le header (top bar de chaque écran)** : version exacte = **COLORED sans fond** (`assets/aurora_icon_a_integre_dans_l'applciation.png`) ; raison : owner decision 2026-09-27, matrice §9.1 l.380 « Header / top bar (every screen) = colored without-background — la marque COLORED porte TOUJOURS le header » ; SSoT ref = ui-libraries §9.1 l.380 ; **conflit avec l'implémentation actuelle** (Shell.tsx = chrome textuel uniquement, dashboard.tsx S4 « header = band, no logo asset ») → **OQ-08** : ajouter le logo colored dans le header per §9.1 l.380 ou maintenir le chrome textuel ? À trancher par l'owner avant implémentation.
- **Cas prescriptif 3 (exclu de cet écran) — AgentThinkingLoader** : version exacte = **monochrome SVG** (`assets/vs_monochrome_en_svg.svg` §9 l.360 → copie stripped `apps/mobile/.build/aurora-mono.stripped.svg` §9.2, passée en PROP `butterfly` du composant) ; raison : matrice §9.1 l.382 « Agent thinking / loading (animated) = monochrome SVG, animated (§9.3) — "the brand is thinking" » ; SSoT ref = ui-libraries §9.1 l.382 + §9.3 l.420–487 ; **absent de l'écran fiches-detail** (pas de streaming IA, pas de thinking state) ; si thinking state = AgentThinkingLoader §9.3 (wing-flap v2 bloqué l.467–480).
- **Versions NE JAMAIS utilisées ici** : version pleine `assets/aurora_logo_icon_d'affichage_l'applicaiton.png` = app icon EXTERNE uniquement (Capacicons/Play Store/splash/install), NEVER in-app UI (S9 §9 l.357, §9 l.369) ; `assets/lg_aurora_vs_monochrome.png` = raster fallback / exports de documents (PDF/DOCX/PNG) uniquement (S9 §9 l.359) ; watermark = single application à 8% d'opacité (§9.1 l.397–398, pas applicable ici) ; interdits S9 l.390–392 = pleine jamais en in-app, monochrome interdit dans les états vivants, pas de recolor, pas de redessin/génération/détournement (S9 l.352–353, l.390–392) ; pas de logo dans le contenu de la fiche (décoration custom SVG interdite, ui-libraries S3 l.141) ; usage ad hoc = interdit (S9).

## §11 i18n / copy

- **Copy = FR** (app FR per ssootCode themeRefs + router.tsx context) : tous les textes affichés = FR (« Chargement de la fiche... », « Fiche introuvable », « Retour à l'accueil », « Acquis ! », « Oublié », « Réviser », « Reconnexion... », « En cours... », badge mastery Acquis/Fragile/Oublié/À venir = fallbacks ssootCode stateRefs SemanticTreeRenderer) ; pas de copy EN (pas de hardcoded EN per ssootCode paginationRefs note : pagination labels EN « Previous/Next/More pages » = unthemed copy, **OQ-09** : thématiser les labels de pagination en FR ou garder EN ? à trancher par l'owner) ; pas de règle i18n par design (copy = FR only, SSoT app = FR, OQ si i18n demandé).

## §12 Offline (rappel, classe + miroir + dégradation + killed)

- **Classe offline** = master-feature-catalog (Learning = module central, non feature optionnelle) ; **miroir local = aucun** (AD-7/AD-12 : pas de synchronisation locale du contenu de fiche, pas de cache par design AD-1) ; **dégradation AD-1** = badge offline (texte exact = **OQ-12**) + contenu caché (pas de crash, pas de cache, pas de last-known data car aucun miroir → **OQ-06**) ; **killed** = skeleton + « Reconnexion... » + shimmer (ui-libraries §6 l.185 : « Skeleton + auto-resync ») (pas de CTA, pas de retry, pas de navigation ; terminal local en attendant la reconnexion ; texte exact = **OQ-11**) ; ce qui vit sur le miroir local = **rien** (AD-7/AD-12 : aucun contenu de fiche n'est synchronisé localement, pas de SQLite) ; source = §9 ci-dessus + ssootCode stateRefs (ux-states.tsx, useOnlineStatus, apps/mobile/src/pages/ascent/index.tsx) + ui-libraries §6 l.184 (offline) + l.185 (killed).

## §13 Logo (rappel, occurrences + version)

- **Occurrences listées (version exacte + raison + SSoT ref)** :
  - **404/not-found (page center, §4c)** : **COLORED sans fond, centrée** = `assets/aurora_icon_a_integre_dans_l'applciation.png` (§9 l.358) ; raison : état vivant (CTA primaire = marque active) per matrice §9.1 l.387 + §6.1 l.202 ; **§4c corrigé** (ancienne mention « monochrome » = erronée, cf. OQ-07/OQ-10).
  - **Header / top bar (cas prescriptif de la matrice, owner 2026-09-27)** : **COLORED sans fond** (§9.1 l.380) ; conflit avec l'implémentation actuelle (Shell.tsx = chrome textuel, dashboard.tsx S4 « band, no logo asset ») → **OQ-08** à trancher par l'owner avant implémentation.
  - **AgentThinkingLoader (exclu de cet écran)** : **monochrome SVG stripped** (§9 l.360 + §9.2, `butterfly` prop §9.3) per matrice §9.1 l.382 ; pas de thinking state dans une fiche.
  - **Jamais** : version pleine `aurora_logo_icon_d'affichage_l'applicaiton.png` (S9 l.357/369 = externe uniquement), `lg_aurora_vs_monochrome.png` (raster/exports l.359), recolor/redessin/génération (S9 l.352–353, l.390–392), usage ad hoc (S9).
- **SSoT refs = ui-libraries §9 l.349–369 + §9.1 l.371–405 + §9.2 l.407–418 + §9.3 l.420–487 + §6.1 l.202.**

## §14 Open Questions (OQ)

- **OQ-01** : QCM inline = composant shadcn Select/Radio/Checkbox (pas de composant QCM dédié per ssootCode componentRefs — pas de QCM dans la battery) → OQ : est-ce que QCM = 3 composants shadcn composites (Select + Button + Feedback) ou un composant maison « QuizBlock » (pas accepté silencieusement per ui-libraries S1 rule « 1 écran = 1 système de composants ») ? → **OQ** (pas de SSoT pour QCM, pas de composant dédié, pas de quiz dans 05 §3 → OQ).
- **OQ-02** : Navigation vers fiche suivante (si existante, §4b terminé) = pas de SSoT pour « fiche suivante » (pas de séquence dans 05 §4.7.1, pas de rule pour next/prev dans fiche) → **OQ** (pas de spec, pas de composant, pas de navigation rule).
- **OQ-03** : Contenu média (si fiche = image/video) = pas de SSoT pour media dans fiche (pas de media player dans 05 §3.3, pas de media dans ui-libraries S1 battery) → **OQ** (pas de spec media, pas de composant media, pas de rule pour media in fiche).
- **OQ-04** : Depth de fiche (texte long = scroll ou paginer ?) = §8 dit N/A si < 20 pages, mais pas de SSoT pour max length de fiche (pas de rule pour taille de contenu) → **OQ** (pas de spec pour taille de contenu, pas de rule pour truncation).
- **OQ-05** : Contexte connaissance (si fiche = nœud dans graphe, pas fiche standalone) = pas de SSoT pour fiche dans graphe (pas de rule pour fiche = nœud vs fiche = standalone per 05 §4.7.1) → **OQ** (pas de spec pour type de fiche, pas de rule pour fiche dans graphe).
- **OQ-06** : Last-known data offline = le pattern S6 l.314 (ui-libraries §8) prévoit « offline → Badge + last-known data », mais AD-1/AD-7/AD-12 pour Learning = **pas de cache par design, pas de miroir local** (fiche = contenu serveur) → pas de last-known data possible ; à trancher par l'owner : accepter l'absence de last-known (badge offline + contenu caché uniquement) ou prévoir un cache minimal hors AD-7/AD-12 ? SSoT refs = ssootCode stateRefs (ux-states.tsx) + ui-libraries §8 l.314.
- **OQ-07** : ~~Conflit interne logo 404~~ — **CORRIGÉ lors vérification 2026-09-29** : l'ancienne formulation supposait que la matrice §9.1 « bloquait » la version colorée ; c'était une lecture erronée. La matrice §9.1 l.387 **prescrit** explicitement « 404 / not-found / feature-disabled (page center) = **COLORED** without-background, **CENTERED** » (état vivant, CTA primaire = marque active), corroborée par §6.1 l.202 (« the only state that MANDATES the centered logo (S9) ») et les interdits l.390–392 (monochrome interdit dans les états vivants). **Les lignes du spec disant « monochrome » (ancien §4c, ancien §3 l.35, ancien §10) ont été corrigées en « COLORED sans fond, centrée »** ; il ne reste aucun conflit : tranchement owner = confirmation de la correction (résolution prévue, OQ conservée pour traçabilité). SSoT refs = ui-libraries §9.1 l.387–392 + §6.1 l.202 + §9 l.358 (vérifié).
- **OQ-08** : Logo dans le header = matrice §9.1 l.380 prescrit « Header / top bar (every screen) = colored without-background » (la marque COLORED porte TOUJOURS le header, owner decision 2026-09-27), mais le Shell.tsx actuel (ssootCode logoRefs) = chrome textuel uniquement (IonMenu header title « Aurora », pas d'asset logo) et le pattern S4 goals/dashboard.tsx = « header = full-width band, no card, no logo asset » → conflit entre la matrice §9.1 (logo colored dans le header de chaque écran) et l'implémentation actuelle Shell.tsx (pas de logo) ; à trancher par l'owner : ajouter le logo colored without-background dans le header de l'overlay fiche per §9.1 l.380, ou maintenir le chrome textuel per Shell.tsx actuel (et éventuellement corriger la matrice §9.1) ? SSoT refs = ui-libraries §9.1 l.380 + ssootCode logoRefs (Shell.tsx, dashboard.tsx).
- **OQ-09** : Labels de pagination en FR = ssootCode paginationRefs note que les labels du shadcn Pagination sont hardcoded EN (« Previous » / « Next » / « More pages ») = copy unthématisée ; si la fiche nécessite une pagination (QCM > 20 questions, §8) ou un contenu long (§OQ-04), les labels seront EN dans une app FR → à trancher par l'owner : thématiser/traduire les labels du composant pagination.tsx en FR, ou accepter EN pour la pagination seule ? SSoT refs = ssootCode paginationRefs (packages/ui/src/components/ui/pagination.tsx).
- **OQ-10** : ~~SSoT fictif~~ — **CORRIGÉ et consolidé en OQ-07 (vérification 2026-09-29)** : l'ancienne OQ-10 présumait que la matrice §9.1 l.387 interdisait le logo monochrome centré pour le 404 ; l'examen exact de la ligne l.387 montre l'inverse — elle **prescrit** « COLORED without-background, CENTERED » pour « 404 / not-found / feature-disabled (page center) » (living empty state), confirmé par §6.1 l.202 et les interdits l.390–392 (monochrome interdit dans les états vivants). Les lignes du spec (« monochrome » dans §4c/§3/§10) ont été corrigées en « COLORED sans fond, centrée » ; plus de conflit interne, plus de SSoT fictif — cette OQ est conservée uniquement pour traçabilité et pointe vers OQ-07 pour le tranchement final par l'owner. SSoT refs = ui-libraries §9.1 l.387–392 + §6.1 l.202 (vérifié).
- **OQ-11** : Texte exact de l'état killed (skeleton + « Reconnexion... », §4a/§4d) = pas de SSoT pour le texte exact de l'état killed (ui-libraries §6 l.185 définit l'état, pas le copy FR exact) → texte « Reconnexion... » = OQ à trancher par l'owner (copy FR bloquant avant implémentation). SSoT refs = ui-libraries §6 l.185 + ssootCode stateRefs (ux-states.tsx).
- **OQ-12** : Texte exact de l'état offline (badge offline, §4a) = pas de SSoT pour le label exact du badge offline (ui-libraries §6 l.184 définit l'état, pas le copy FR) → à trancher par l'owner. SSoT refs = ui-libraries §6 l.184 + ssootCode stateRefs (useOnlineStatus pattern, apps/mobile/src/pages/ascent/index.tsx).
