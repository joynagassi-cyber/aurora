# Écran : artifacts-detail — Artefact (détail / preview par format)

> Module Artifacts · Route `/artifacts/:id` (overlay IonModal sur le tab courant, 02 §6.1 S1/S3, router.tsx) · SSoT docs/artifacts/overview.md + WDS 03.5 + ADR §16 · Statut : détaillé (claimé, NON détaillé = OQ-46 levée ici)

## §1 Psychologie designer

- **Objectif utilisateur** : voir l'aperçu d'un artefact (fichier importé ou généré) **dans son format réel** — PDF/DOCX/PPTX/XLSX/image/audio/LaTeX/Markdown — avec les métadonnées de provenance (source, tâche, contexte) et l'accès au fichier source (télécharger/partager) ; formats non pris en charge = **conservation du fichier + téléchargement/partage, jamais de prévisualisation factice** (ADR §16 dernière balle, docs/artifacts/overview.md §2).
- **Contexte** : mobile, main libre, réseau patchy probable ; ouverture depuis la bibliothèque `bibliotheque-ressources` (05 §4.6.1 Transitions) ou deep link agent (OQ-05 module-ownership-matrix l.106) ; overlay = l'utilisateur reste dans son flux (pas de navigation destructive).
- **Fréquence** : plusieurs fois par semaine — chaque artefact généré par l'agent (fiche, QCM, infographie, rapport) ou chaque import (document scanné, audio, image) passe ici ; les blobs sont **immuables** (R2, docs/artifacts/overview.md §18) donc la relecture est fidèle.
- **État émotionnel cible** : confiance (mon contenu s'affiche tel quel, pas de fake preview), orientation (d'où vient cet artefact = provenance ADR §16), calme (lecture, pas de mutation).
- **Erreur la plus probable** : l'artefact est dans un format **non pris en charge** (ou le moteur de rendu échoue) — l'écran **ne crash jamais** : graceful fallback = fichier brut téléchargeable/partageable externe, **sans prétendre à un rendu natif** (ADR §16 dernière balle + docs/artifacts/overview.md §15, viewer degradation tests §20).
- **Ce que l'écran RÉSOUT** : un seul chemin de visualisation unifié pour **tout** fichier (importé ou généré, ADR §16) — rendu par format adapté via les contrats AD-10 (`packages/ui`), métadonnées de source visible, accès au fichier source ; offline = les préviews/blobs **cachés** restent lisibles (LocalFileStorageAdapter cache, docs/artifacts/overview.md §16, 04 §3.2.2).

## §2 Contexte fonctionnel

- **Entrée** : `bibliotheque-ressources` (05 §4.6.1 « sortie vers l'aperçu d'un artefact (l'écran de visualisation AD-10, §4.6.1) ») ; deep link agent (`AgentActionEnvelope`, module-ownership-matrix l.106) ; `ArtifactGenerated` (F-06, post-upload R2, UI = OQ-05 du module → ce doc). **Sortie** : `cours-detail` (WDS 03.5 CTA « Ouvrir dans /learn », ADR §13.9) ; retour arrière conserve la bibliothèque (store UI pack 02 §3.2, AD-7 persist).
- **Overlay IonModal** `/artifacts/:id` (router.tsx l.71, detail-over-tab rule 02 §6.1 S1/S3) : le tab courant reste sous l'overlay (pas de navigation destructive).
- **Data** : `Artifact` (kind, r2Key, size, generatedAt, jobId, liens cours/projet/objectif, docs/artifacts/overview.md §6) + `SourceRef` (provenance, Knowledge-owned) ; les **binaire ne sont JAMAIS en SQLite** (03 §4.2 rule 2, module-ownership-matrix l.105) — seulement `r2_key` + métadonnées localement.
- **Async** : **presign** (Edge Function `presignGet` 15 min / `presignUpload` 5 min, 01 §5.4, docs/artifacts/overview.md §11) → **fetch** blob → **rendu** (contrats AD-10, packages/ui, 04 §5) ; offline = cache local `LocalFileStorageAdapter` (04 §3.2.2, docs/artifacts/overview.md §16 « cached previews/blobs readable offline ») ; **killed** = sur tout flux serveur (AD-13/G-M2, ssootCode stateRefs ux-states.tsx : priorité killed > offline > query).
- **Formats non pris en charge** : ADR §16 dernière balle — fichier **conservé** + métadonnées + téléchargement/partage externe, **jamais de prévisualisation factice** (« never pretend », docs/artifacts/overview.md §2) ; l'état = raw-file fallback (docs/artifacts/overview.md §17 « preview failure → raw-file fallback »).

## §3 Éléments (work of detail — 100 % de la zone)

| Élément | Composant DS 05 §3 | Lib ui-libraries S1 | Tokens | Variante responsive | Source SSoT |
|---|---|---|---|---|---|
| Header overlay (TopBar retour + titre artefact `lg` + Badge kind) | 05 §3.1 Actions + shell IonModal header | shadcn Battery ; header = band pleine largeur, pas de card (dashboard.tsx pattern S4) | --aurora-bg-subtle, --aurora-text-primary (titre lg, 05 §2.2) ; Badge = 05 §3.3 | pleine largeur, radius top 8px (pas > 8px, S3 l.142) | ADR §16 « prévisualisation adaptée au type de fichier et accès au fichier source » + docs/artifacts/overview.md §6 (kind) |
| Zone aperçu par format (viewer) — **le composant principal** | 05 §3.6 data/viz wrappers (05 l.866–1243) | shadcn (suivant kind) : PDF/DOCX/PPTX = viewer (OQ-01 §14) ; XLSX/CSV = `DataTable` 05 §3.6.1 (G2) ou `AgGridTable` (> 100 rows, S8) ; images = zoom viewer (OQ-02) ; audio = `AudioWaveformRenderer` (05 §3.6, 04 §5 rule : composant React pur, **pas** adapter Capacitor) ; LaTeX = `MathBlock` (05 §3.6.8, KaTeX) ; Markdown/texte/code = rendu (OQ-03) ; infographie générée = `InfographicSlot` (05 §3.6.7, AntV) ; **non pris en charge** = zone fallback raw-file (§4) | --aurora-surface, --aurora-text-primary, chartPalette (thème, 05 §5.4) ; data scientifique = **jamais animée** (05 §2.6 règle 1, ssootCode forbidden) | scrollable ; XLSX > 100 rows → AG Grid virtualisé (60fps Pixel 4a, S8 l.304–307) ; audio = waveform + timestamps (04 §3.2.4) | ADR §16 (liste des formats) + docs/artifacts/overview.md §2 (responsibilities) + 05 §3.6 l.866–1243 |
| Section métadonnées de provenance (`KeyValueList`) | 05 §3.6 (data) | `KeyValueList` (packages/ui, ssootCode componentRefs) | --aurora-text-primary/secondary, --aurora-border | sous l'aperçu, non scrollable séparé | docs/artifacts/overview.md §6 (Artifact : kind, r2Key, size, generatedAt, jobId) + §11 (provenance ADR §16 « source, tâche et contexte de génération ») |
| Badge état d'export (`en-cours` / `terminé` / `échec`, §6.1) | 05 §3.3 (Badge) + §6.1 | shadcn Badge (état) + Progress (en-cours %) | --aurora-success/warning/danger (frozen 05 §5.1) ; en-cours = --aurora-info | compact, inline après « Exporter » | docs/artifacts/overview.md §12 (`JobCompleted` F-08, états succès/échec) + ui-libraries §6.1 l.197–201 |
| CTA « Télécharger » (fichier source) | 05 §3.1 (Button) | shadcn Button primary (headless Radix) | --aurora-accent-primary, --aurora-on-primary ; height ≥ 44px (56px High Contrast, 05 §6.3) | bas de l'écran (actions flottantes), pleine largeur mobile | ADR §16 « accès au fichier source » + docs/artifacts/overview.md §2 (downloadable) |
| CTA « Partager » (externe, `artifact.share`) | 05 §3.1 (Button) | shadcn Button ghost + shadcn Menu (partage natif, OQ-04 §14) | --aurora-surface, --aurora-text-primary | ghost, à côté de Télécharger | module-ownership-matrix l.107 (`artifact.share`) + docs/artifacts/overview.md §4 (export/download/share) |
| CTA « Ouvrir dans /learn » (WDS 03.5, ADR §13.9) | 05 §3.1 (Button) | shadcn Button primary | --aurora-accent-primary, --aurora-on-primary ; ≥ 44px | bas de l'écran, au-dessus de Télécharger | WDS 03.5 §6 (CTA fixe « Ouvrir dans /learn » → S-25 → cours-detail S-16, 03.6) + ADR §13.9 « crée éventuellement une activité d'apprentissage ou un projet » |
| CTA « Exporter » (job `artifact_gen`/`ocr`/`transcription`, ADR §17) | 05 §3.1 (Button) | shadcn Button secondary (disabled si offline/échec) + Progress inline (en-cours) | --aurora-accent-secondary, --aurora-warning (en-cours) | secondaire, non bloquant | docs/artifacts/overview.md §13 (jobs export ADR §17) + §12 (`JobCompleted` F-08) |
| État loading (skeleton aperçu + métadonnées) | 05 §3.7 (AD-13) + 05 §2.6 | shadcn Skeleton | --aurora-skeleton ; pulse via opacité (pas de layout, S5 l.169) ; **pas** de web-search skeleton (ssootCode forbidden) | centré, pleine largeur | docs/artifacts/overview.md §5 (previews rendered client-side) + ui-libraries §6 l.180 |
| État empty (artefact inconnu / supprimé) | 05 §3.7 + pack 02 §7 | shadcn Card (empty variant, S8 l.304) | --aurora-bg-subtle, --aurora-text-secondary | centré, pleine largeur | docs/artifacts/overview.md §15 (graceful, pas de crash) + ui-libraries §6 l.182 |
| État error (rendu échoué) | 05 §3.7 | shadcn Alert (destructive) + CTA « Réessayer » | --aurora-danger, --aurora-danger-surface | pleine largeur, sous l'header | docs/artifacts/overview.md §17 (« preview failure → raw-file fallback, download/share external, ADR §16 ») |
| Format non pris en charge (fallback raw-file) | 05 §3.7 (état sémantique « échec », §6.1 l.199) | shadcn Alert (warning, **pas** destructive — le fichier existe, le rendu ne le permet pas) + CTA « Télécharger le fichier brut » + CTA « Partager » | --aurora-warning, --aurora-surface | pleine largeur, pas de rendu factice | ADR §16 dernière balle + docs/artifacts/overview.md §2/§15/§17 |
| Badge offline (préview/blobs cachés lus, upload KO) | 05 §3.3 (Badge) + AD-1 | shadcn Badge | --aurora-warning (frozen 05 §5.1) | en header | docs/artifacts/overview.md §16 (« cached previews/blobs readable offline », 04 §3.2.2) |
| killed (tout flux serveur : presign/fetch/générations) | 05 §3.7 (matrice AD-13 l.1244–1309) + ui-libraries §6 l.185 | shadcn Skeleton + « Reconnexion... » | --aurora-skeleton, --aurora-danger ; priorité killed > offline > query (ssootCode stateRefs ux-states) | pas de CTA, pas de retry, pas de navigation | ssootCode stateRefs + ui-libraries §6.1 l.202 |
| 404/not-found (id inconnu, artefact supprimé) | 05 §6.1 (état 404 l.202) + §3.1 | logo AURORA coloré centré (§9.1/§6.1) + shadcn Button « Retour à l'accueil » + optionnel secondary « Consulter l'écran parent » (bibliotheque) | --aurora-bg-subtle, --aurora-text-primary ; logo = version §9.1 (pas de fond, pas de recolor, S9 l.390–392) | centré, pleine largeur | ui-libraries §6.1 l.202 + §9.1 l.371–405 |

## §4 États (matrice complète AD-13 / 05 §3.7 l.1244–1309)

### (a) 6 états S6 par élément async (ui-libraries §6 l.174–187)

- **loading** (flux presign → fetch → rendu) : Skeleton aperçu + KeyValueList (§3, loading row) ; tokens = --aurora-skeleton ; texte exact = « Chargement de l'aperçu… » (court, cache local = rapide si présent) ; CTA = **aucun** (pas d'actions avant données) ; **entrée** = fade 200ms easeOut (PAGE_TRANSITION, ssootCode motionRefs polish.tsx) ; **sortie** = skeleton → contenu crossfade 200ms.
- **empty** (artefact inconnu / supprimé / non synchronisé) : Card empty (S8) + CTA « Revenir à la bibliothèque » (navigate back, 02 §6.1 S3) ; tokens = --aurora-bg-subtle + --aurora-text-secondary ; **entrée** = fade 200ms ; **sortie** = retour (close overlay, bibliothèque S14 préservée S6.2).
- **error** (rendu échoué — format pris en charge mais moteur a échoué) : Alert destructive + message court + CTA « Réessayer » (§3, error row) ; tokens = --aurora-danger / --aurora-danger-surface ; **entrée** = fade 200ms ; **sortie** = retry OK → rendu ; fail → raw-file fallback (§4 non-prises-en-charge).
- **success** (export terminé, retour sur l'écran) : Toast success (§3, export row) ; tokens = --aurora-success ; texte = « Export terminé — [format] » ; CTA = le CTA « Télécharger » redevient actif (fichier exporté disponible) ; **entrée** = toast slide up 200ms (translateY, pas de layout, S5 l.169) ; **sortie** = auto-dismiss 3s (§3.5 l.823 pattern).
- **offline** (lecture cache OK, upload/presign/générations KO) : Badge offline (§3, offline row) + les préviews/blobs **cachés** restent lisibles (docs/artifacts/overview.md §16, 04 §3.2.2) ; CTA « Exporter » / « Partager » (si non-caché) désactivés ; tokens = --aurora-warning + --aurora-info ; **entrée** = fade 200ms ; **sortie** = retour online → refetch (retour au flux loading/success).
- **killed** (tout flux serveur : AD-13/G-M2) : Skeleton + « Reconnexion… » (§3, killed row) ; tokens = --aurora-skeleton + --aurora-danger ; CTA = **aucun** (pas de retry, pas de navigation) ; **entrée** = fade 200ms ; **sortie** = reconnexion OK → re-query → loading/success ; le contenu **local** (cache) reste lisible en dessous (AD-7), seul le flux serveur est mort.

### (b) États sémantiques §6.1 (ui-libraries l.189–202)

- **en-cours** (export/génération en cours — job `artifact_gen`/`ocr`/`transcription`) : Progress (valeur %, §6.1 l.197) + label live + Badge warning ; tokens = --aurora-info + --aurora-warning ; CTA = « Annuler » (job killable, 01 §5.3) si présent ; source = docs/artifacts/overview.md §12 (`JobCompleted` F-08) + ui-libraries §6.1 l.197.
- **terminé** (export validé, fichier disponible) : Lucide `CheckCircle2` + Badge success + CTA « Télécharger » actif ; tokens = --aurora-success ; source = ui-libraries §6.1 l.198 + docs/artifacts/overview.md §12.
- **échec** (job échoué, non retryable in place — 01 §6) : Alert destructive + raison + CTA alternative path (réessayer plus tard, vérifier réseau) ; tokens = --aurora-danger ; source = ui-libraries §6.1 l.199 + docs/artifacts/overview.md §12/§17.
- **succès / erreur générique** = S6 (transient, §4a) — l'artefact est **immuable** (R2, docs/artifacts/overview.md §18) donc **pas** d'état sémantique d'écriture (pas de mutation locale, pas de conflit) ; toute erreur/succès = Callout/Toast §4a.
- **404/not-found** = §4c ci-dessous (id inconnu / artefact supprimé / deep link vers feature désactivée : data-state=feature-disabled + CTA re-enable, ssootCode stateRefs not-found/index.tsx, **jamais** un crash/404 brut).

### (c) 404 / not-found (écran routé `/artifacts/:id`, oui → règle §6.1 l.202)

- Page entière = overlay (pas de page standalone) : **logo AURORA coloré sans fond, centré** (version = §9.1 l.371–405, **pas** de fond, **pas** de recolor (S9 interdits l.390–392), **jamais** la version full app icon en in-app (S9 l.352–353)) ; message court = « Artefact introuvable » ; CTA primaire = « Retour à l'accueil » (shadcn Button, --aurora-accent-primary, ≥ 44px) ; CTA secondaire optionnel = « Consulter l'écran parent » (bibliotheque, navigate back) ; tokens = --aurora-bg-subtle + --aurora-text-primary ; **entrée** = fade 200ms easeOut ; **sortie** = navigate back (close overlay, retour au tab courant) ; source = ui-libraries §6.1 l.202 + §9.1 l.371–405 + 05 §3.1.

### (d) killed sur tout flux serveur (AD-13/G-M2, ui-libraries §6 l.185)

- killed = Skeleton + « Reconnexion… » (§4a killed row) : **pas** de CTA, **pas** de retry, **pas** de navigation ; tokens = --aurora-skeleton (+ --aurora-danger pour le badge d'état) ; **entrée** = fade 200ms ; **sortie** = reconnexion → re-query → loading/success ; portée = **flux serveur uniquement** (presign/fetch/générations, docs/artifacts/overview.md §11/§13) : la lecture du **cache local** (04 §3.2.2, docs/artifacts/overview.md §16) est **inchangée** et reste utilisable pendant le killed (pas de crash, pas de perte de contenu local).

## §5 Animations (GPU only, 150–250ms, reduced-motion = statique — 05 §2.6 + ui-libraries S5 l.169)

| Élément | Action → feedback | Durée | GPU only (transform/opacity) | Smooth | reduced-motion = statique | Source SSoT |
|---|---|---|---|---|---|---|
| Header (ouverture overlay) | tap depuis biblio/deep-link → open | 200ms easeOut (PAGE_TRANSITION opacity 0→1, y 8→0, exit y -4, ssootCode motionRefs polish.tsx) | opacity + translateY, **pas** de layout (S5 l.169) | easeOut (pas de spring/bouncy, S3 l.143) | statique (div fixe, ssootCode forbidden) | ssootCode motionRefs + ui-libraries S5 l.169 |
| Zone aperçu (chargé) | skeleton → contenu | crossfade 200ms easeOut | opacity (pas de scale, pas de reflow) | easeOut | statique | ssootCode motionRefs + 05 §2.6 |
| `MathBlock` (LaTeX, KaTeX) | **aucune animation** — donnée scientifique = **jamais** animée (05 §2.6 règle 1, AnimationController header ssootCode motionRefs) | N/A | N/A | N/A | statique (pas de trace) | 05 §2.6 règle 1 + ssootCode forbidden |
| `InfographicSlot` (AntV) / `DataTable` (G2) | **aucune animation** — données visuelles = jamais animées (règle 1) ; seul le reveal de la zone (crossfade) s'anime | 200ms (reveal) / N/A (data) | opacity (reveal) | easeOut | statique | 05 §2.6 + ssootCode forbidden (scientific data NEVER animates) |
| `AudioWaveformRenderer` (waveform + timestamps) | **aucune animation** — waveform = données ; le seul « mouvement » = le playhead (si lecture) = **pas** de layout (OQ-05 §14 si spec manquante) | N/A (pas d'anim si spec absente) | N/A | N/A | statique | 05 §2.6 + 04 §5 rule (composant React pur, pas adapter Capacitor) |
| Progress (export en-cours) | job tick → valeur % | 200ms easeOut (barre width, **pas** de layout) | width (pas de layout, S5 l.169) ; pas de spring | easeOut | statique (barre figée à la valeur) | ssootCode motionRefs dashboard.tsx (progress fill) + 05 §2.6 |
| Toast (success/error) | event → toast | slide up 200ms easeOut (translateY, pas de layout) | translateY | easeOut | statique (pas de toast animé, ssootCode forbidden) | ssootCode motionRefs + 05 §3.5 l.823 |
| Focus Mode (data-focus-mode=true) | attenuated animations + deferred toasts (ssootCode forbidden : `[data-focus-mode=true] .animate-pulse-skeleton = animation:none`) | N/A (règle globale) | N/A | N/A | statique | ssootCode forbidden (Focus Mode rule 3, 05 §2.6) |

## §6 Tokens (discipline AD-17, 05 §2 l.93–346 + ui-libraries S4 l.145–160)

- **Aucune valeur brute** : pas de hex, pas de px de spacing/typo/radius codé en dur — toujours via variables CSS `hsl(var(--aurora-*))` (05 §5.2/5.3, ssootCode tokenRefs aurora.css).
- **Règle bloquante 05 §5.1 (l.2931)** : le thème ne touche **jamais** success/warning/danger/info (frozen semantic tokens) — utiliser uniquement via les variables, pas de redefinition par thème.
- **10 thèmes + 3 presets = comportement par couche** (05 §5.2, ssootCode themeRefs) : pas de valeur par thème (jamais d'override par thème sauf L3 local override = Focus only, OQ-15) ; l'écran ne code **aucune** valeur par thème.
- **focus visible** : le theme owns focus-ring (aurora.json focusTreatment = ring, ssootCode a11yRefs) — pas de gestion manuelle du focus par écran.
- **icônes** : 05 §2.5 (l.287) — lucide (ssootCode paginationRefs Chevrons/MoreHorizontal) ; **pas** de custom SVG decoration (S3 l.141 interdit, ssootCode forbidden).
- **coins** : radius ≤ 8px (S3 l.142 interdit > 8px) ; **élévations** = 05 §2.4 (l.254), pas de box-shadow brut.
- **chartPalette** = thème (05 §5.4, ssootCode themeRefs resolve.ts `resolveToken`) : les rendus G2/AntV consomment la palette du thème courant, **jamais** une palette codée en dur.

## §7 i18n / copy

- Copy = FR (app FR, ssootCode themeRefs + router.tsx context) ; tous les textes = FR (« Chargement de l'aperçu… », « Artefact introuvable », « Retour à l'accueil », « Revenir à la bibliothèque », « Télécharger », « Partager », « Ouvrir dans /learn », « Exporter », « Reconnexion… »).
- **EXCEPTION** : les labels shadcn Pagination (« Previous »/« Next »/« More pages ») = EN hardcoded (ssootCode paginationRefs note, OQ i18n) — **si** pagination utilisée (XLSX 20–100 rows, §8) → OQ-06 §14 (FR vs EN pour ce flux).
- Pas de copy EN hors composant shadcn Pagination (pas de hardcoded EN dans le reste, ssootCode paginationRefs note) ; si i18n = OQ-06 §14.

## §8 Pagination

- **Règle unique nommée : shadcn Pagination** (ui-libraries S1 l.37) — **paramètres** : volume par décision tree S8 l.304–307 :
  - **XLSX/CSV < 20 rows** → `DataTable` shadcn **sans** pagination (Table, S8).
  - **20–100 rows** → `DataTable` + **shadcn Pagination** (pages, S8).
  - **> 100 rows** → **AG Grid virtualisé** via `packages/ui AgGridTable` (60fps Pixel 4a, ssootCode paginationRefs progress/index.tsx ; rowBuffer 10, maxVisibleRows 30, S5 l.152).
- Les **autres formats** (PDF paginé, PPTX diapositives, images, audio) = navigation **propre au viewer** (page/slide/suivant-précédent), **pas** de shadcn Pagination (pas de décision tree applicable, OQ-07 §14 si spec manquante).
- **JAMAIS** : AG Grid shadcn Pagination Pager jour/semaine/mois (05 §3.4) sur ce flux (pas de calendrier dans l'écran) ; **pas** de 2 lib sur le même écran (S8 l.333 interdit, ssootCode forbidden) — XLSX = soit Table+Pagination, soit AG Grid, **pas** les deux.

## §9 Surfaces flottantes (05 §3.5 l.752–865)

- **Modal** = l'overlay IonModal lui-même (§2, router.tsx) ; **pas** de Modal imbriquée dans l'overlay (pas de double floating surface).
- **Toast/Snackbar** (05 §3.5 l.823) : feedback export success/error (§4a success/erreur) ; auto-dismiss 3s ; deferred si Focus Mode (ssootCode forbidden).
- **Menu** : partage = shadcn Menu (`artifact.share`, §3) ; **pas** de BottomSheet ni Drawer dans l'écran (pas d'édit d'artefact ici — les artefacts sont **immuables** (R2, docs/artifacts/overview.md §18), édition = nouvel artefact, `supersedes` (docs/artifacts/overview.md §24)).
- **Popover** : **pas** de Popover dans l'écran (pas de date picker, pas de sélecteur — l'artefact n'est pas un formulaire, 05 §3.2 N/A ici).
- Règle S8 l.333 : **ne jamais mélanger 2 libs sur le même écran** — toutes les surfaces = shadcn/Radix (ui-libraries S1 l.13–14), **pas** de MUI/Ant/Chakra (S3 l.139 interdit).

## §10 Thèmes (comportement par couche, 05 §5 l.2925–3306)

- **10 thèmes vivants + 3 presets** (05 §5.4/5.5, ssootCode themeRefs packages/ui/themes/) : l'écran **consomme** le thème courant (JSON SSoT, AD-15/AD-17) — **pas** de valeur par thème codée (§6 règle bloquante 05 §5.1).
- **Résolution** (05 §5.3, l.2992) : `valeur = theme_accent[token] ?? style_neutre[token] ?? défaut` ; le thème change = le rendu change (chartPalette, accent, skeleton) **sans re-render** (CSS variables, ui-libraries S4 l.145–160, ssootCode themeRefs aurora.css).
- **focus visible** = thème owns (aurora.json focusTreatment = ring, ssootCode a11yRefs) — pas de gestion manuelle.
- **preset High Contrast** : targets ≥ 56px (05 §6.3, ssootCode a11yRefs) ; focus ring 3px ; l'écran ne code **aucune** valeur par preset (comportement par couche, 05 §5.5/5.8).
- **Focus Mode** (05 §2.6 règle 3) = L3 local override (OQ-15 V1, ssootCode themeRefs theme-adapter.tsx) — l'écran **consomme** l'override (atténuation animations + toasts deferred, §5), ne code **jamais** une valeur par écran (§6).

## §11 A11y (WCAG AA, 05 §6 l.3308–3346 + §6.3 l.3327)

- **Tap targets** ≥ 44px (56px High Contrast preset, 05 §6.3) ; tous les CTA (§3) = ≥ 44px.
- **aria-label** sur tous les icon buttons (Télécharger/Partager/Menu, §3) : `aria-label="Télécharger [titre artefact]"`, `aria-label="Partager [titre artefact]"`.
- **letter-spacing 0** (05 §6.3, ssootCode themeRefs Inter variable) ; **pas** de letter-spacing > 0 sur le contenu.
- **focus visible** : thème owns (aurora.json focusTreatment = ring, ssootCode a11yRefs) ; **pas** de focus invisible (pas de `outline: none` sans replacement).
- **Reduced motion** = **statique** (05 §2.6 règle 2, ssootCode forbidden) : pas de layout, pas de keyframe loop, pas de rotation de mots (AgentThinkingLoader N/A ici, pas de streaming IA visible dans l'écran ; si présent = §9.3 l.420–487, statique si reduced) ; `prefers-reduced-motion` media query (ssootCode themeRefs aurora.css) → toutes les durées = 0.01ms.
- **États screen-reader** : la zone aperçu = `role="region"` + `aria-label` (si non-native, OQ-01 §14) ; le `KeyValueList` = liste native (pas de data grid ARIA si < 20 rows, S8).
- **Contraste** : les tokens success/warning/danger/info = **frozen** (05 §5.1) → le contraste est **garanti** par le thème (presets High Contrast = 7:1, 05 §5.5) ; l'écran **ne redéfinit jamais** un token sémantique (règle bloquante, §6).

## §12 Offline (classe AD-1/AD-7/AD-12 + master-feature-catalog)

- **Classe offline** : **offline-capable** (cache préviews, docs/artifacts/overview.md §16 « cached previews/blobs readable offline », 04 §3.2.2 `LocalFileStorageAdapter` cache ; master-feature-catalog, _inventory.md l.73 « offline-capable (metadata + cache R2) »).
- **Miroir local (AD-7/AD-12)** : métadonnées `Artifact` (kind, r2Key, size, generatedAt, jobId) + `SourceRef` = **SQLite** (PowerSync, 03 §4.2 rule 2 : binaire **jamais** en SQLite, seulement `r2_key`) ; les **blobs** = cache `LocalFileStorageAdapter` (04 §3.2.2, déductible/reconstruisible, **pas** source de vérité, AD-7 04 l.395).
- **Dégradation AD-1** : offline → Badge offline (header, §3) + les préviews/blobs **cachés** restent 100 % lisibles (docs/artifacts/overview.md §16) ; les actions **serveur** (presign/upload/export/générations, 01 §5.4) sont **désactivées** (CTA grisé, pas de crash, pas de CTA serveur, §4a offline).
- **Ce qui meurt (killed)** : tout flux serveur (presign/fetch/export, AD-13/G-M2) → Skeleton + « Reconnexion… » (§4a/§4d) ; la **lecture du cache** **ne meurt jamais** (AD-7, docs/artifacts/overview.md §16) ; pas d'export exécuté hors-ligne (AD-12, §4a offline CTA désactivés).

## §13 Logos (occurrences + version exacte, ui-libraries §9 l.349–487)

- **1 seule occurrence** : logo AURORA **coloré sans fond, centré** (404/not-found, §4c) — version = §9.1 (matrice l.378–388, **pas** de fond, in-app = « colorée sans fond / monochrome §9.1 », **jamais** la version full app icon en in-app (S9 l.352–353 + ssootCode logoRefs dashboard.tsx IN_APP_LOGO pattern)) ; **pas** de recolor (S9 interdits l.390–392) ; **pas** de détour (pas de redessin, S9) ; raison (designer psychology) = feedback d'erreur = calme, pas de brand noise (logo statique, pas d'anim) ; SSoT ref = ui-libraries §9.1 l.371–405.
- **Pas d'autres occurrences** : header = texte uniquement (« Artefact » via Shell.tsx chrome, pas de logo asset, ssootCode logoRefs) ; contenu = pas de decoration logo (S3 l.141 custom SVG interdit) ; **usage ad hoc interdit** (S9 : toute utilisation hors 404 / AgentThinkingLoader / settings = OQ, ssootCode logoRefs) ; pas d'AgentThinkingLoader dans cet écran (pas de streaming IA visible, l'artefact est un **fichier** (importé/généré), pas un chat ; si thinking = §9.3 l.420–487, **pas** de wing-flap v2 bloqué l.467–480).
- **C2PA stripped copy** (§9.2 l.407–418) : le logo in-app = build artifact strippé (pas de métadonnées C2PA, ssootCode logoRefs) ; **pas** de logo avec C2PA dans l'écran.
- **AgentThinkingLoader** (ui-libraries §9.3 l.420–487) : **N/A** ici (pas de streaming IA visible dans l'écran ; si l'export = job serveur (docs/artifacts/overview.md §13), l'attente = Progress (en-cours, §4b), **pas** le loader IA).

## §14 Open Questions (OQ)

- **OQ-01** : composant viewer PDF/DOCX/PPTX — **pas** de SSoT explicite pour le composant (05 §3.6 l.866–1243 liste `DataTable`/`KeyValueList`/`Timeline`/`GanttRow`/`Sparkline`/`SemanticTreeNode`/`InfographicSlot`/`MathBlock`/`FocusTimer` mais **pas** de viewer document natif ; ui-libraries S1 l.13–14 = shadcn Battery, **pas** de viewer document) → **OQ** (pas de spec viewer, pas de composant dans la battery, pas de rule pour « PDF/DOCX/PPTX = quel composant maison » ; si custom = S3 l.141 interdit si custom SVG decoration, mais un viewer non-SVG = OQ).
- **OQ-02** : composant viewer images (zoom) — **pas** de SSoT explicite (05 §3.6 N/A, ADR §16 « visionneuse avec zoom » mais **pas** de composant dédié dans la battery ni dans 05 §3) → **OQ** (pas de spec zoom viewer, pas de composant, pas de rule pour « zoom = transform scale (GPU, S5) ou autre »).
- **OQ-03** : rendu Markdown/texte/code — **pas** de SSoT explicite (ADR §16 « rendu ou éditeur adapté » mais **pas** de composant dédié dans 05 §3 / ui-libraries S1 ; si éditeur = Tiptap (ui-libraries S5 l.169, keyboard avoidance Capacitor) mais **pas** de rule pour « Markdown = rendu seul (read-only) ou éditable ») → **OQ** (pas de spec rendu Markdown, pas de composant dédié, pas de rule pour lecture seule vs éditeur).
- **OQ-04** : composant partage natif (`artifact.share`) — **pas** de SSoT explicite (module-ownership-matrix l.107 cite `artifact.share` mais **pas** de composant dédié dans la battery shadcn ni de rule pour « partage = Menu (natif Capacitor Share) ou URL presignée à copier ») → **OQ** (pas de spec partage, pas de composant, pas de rule pour le mécanisme (Capacitor Share plugin vs copie d'URL presignée 15 min, 01 §5.4)).
- **OQ-05** : playhead `AudioWaveformRenderer` (si lecture audio dans l'écran) — **pas** de SSoT explicite pour l'animation du playhead (05 §3.6 cite `AudioWaveformRenderer` comme composant React pur (04 §5 rule, **pas** adapter Capacitor) mais **pas** de rule pour « playhead = transform (GPU, S5) ou other » ; la lecture elle-même = `AudioArtifactProvider.stream()` (04 §3.2.4), **pas** un composant) → **OQ** (pas de spec playhead animé, pas de rule pour GPU-only ici, si pas d'anim = statique (05 §2.6 règle 1, data jamais animée) — à trancher).
- **OQ-06** : i18n labels shadcn Pagination (si XLSX 20–100 rows, §8) — **pas** de SSoT explicite (ssootCode paginationRefs : labels EN hardcoded, OQ i18n note ; le reste de l'écran = FR (§7)) → **OQ** (pas de rule pour FR/EN mix sur ce flux, pas de composant i18n dans la battery).
- **OQ-07** : navigation propre au viewer PDF (pages) / PPTX (slides) — **pas** de SSoT explicite (ADR §16 « lecture paginée, zoom, recherche et navigation » mais **pas** de composant dédié ni de rule pour « navigation = chevrons lucide (S8) ou swipes (05 §3.4, mobile) » ; si shadcn Pagination = §8 (20–100 = + pagination) mais **pas** de rule pour « pages PDF = Pagination ou contrôles custom ») → **OQ** (pas de spec navigation viewer, pas de composant, pas de rule pour le mécanisme (tap zones / swipes / chevrons)).
- **OQ-08** : Focus Mode atténuation (OQ-15 V1, ssootCode themeRefs theme-adapter.tsx FOCUS_OVERRIDES) — l'écran **consomme** l'override (atténuation animations + toasts deferred, §5/§10) mais **pas** de SSoT pour l'atténuation visuelle des CTA (pas de rule pour « atténué = quelle opacité / quel token » ; l'override Focus = `node.secondary-opacity`/`node.active-contrast`, **pas** les CTA) → **OQ** (pas de spec atténuation CTA, pas de token dédié, pas de rule pour CTA in Focus Mode ; WDS 03.5 §5 propose options A/B/C au standup, **pas** ratifié).
