# Écran : `settings` — Settings (sélecteur thème 10+3 + preview)

- **Route** : `/settings` (page mère des réglages, pas un tab BottomNav)
- **Module** : Settings
- **SSoT** : `docs/design-system/overview.md` §3 + §6 + §9 ; `05-design-system.md` §5 ; `docs/ui-libraries.md` S1/S3/S5/S9 ; `_bmad-output/wds/C-UX-Scenarios/04-horebs-foundation-setup/04.5-settings-preferences.md`
- **Statut** : `GAP (OQ-47)` → **SPECIFIED** (ce doc)
- **Classe offline (catalog)** : offline-capable (perso UI, persist middleware AD-7/AD-15)

---

## §1 — Psychologie designer (1 ligne / dimension)

- **Objectif utilisateur** : calibrer les dernières préférences (thème + preview, notifications, compte) en 2 minutes, sans tour de fonctions — l'environnement est calibré, jamais un dashboard.
- **Contexte** : fin de session nocturne (22–23 h), Pixel 4a Bénin, 3G capricieuse, forfait étudiant limité (trigger-map §7 signal 15/16 ; OQ-11 budgets).
- **Fréquence** : bas (calibration initiale + ajustements ponctuels — pas un écran de navigation quotidienne).
- **État émotionnel cible** : clôture et maîtrise — « l'environnement est calme, sombre, silencieux, calé sur mes matières » (scénario 04 Q7 User Success).
- **Erreur la plus probable** : le thème change silencieusement au retour foreground (flash light/dark au boot) — la règle de non-surprise 05 §2.1.3 est bloquante ici.
- **Ce que l'écran RÉSOUT** : la fatigue d'alertes (signal 4) — notifications maîtrisées par type (ADR §13) ; le thème persisté localement (AD-7) ; le profil complet (AD-15 `UserContext`).

---

## §2 — Zone & composition (4 zones max, garde AD-14)

```
+-------------------------------------+
| /settings · Paramètres              |  ← IonHeader (page mère des réglages)
|                                     |
| ─ SECTION 1 · THÈME + PREVIEW ─────|
|  [13 swatches : 10 thèmes vivants  |  ← pack 05 §5.4/§5.5 : 10 + 3 presets
|   + 3 presets, grille 4×4]         |     (Slate, Nocturne, High Contrast)
|  [Preview statique : 3 mini-cards  |  ← WDS 04.5 OQ-1 close (option A) :
|   Home / Focus / Calendar]          |     swatch + mini-aperçu statique,
|                                     |     pas un re-render live (OQ-11 TTI ≤1.5 s)
| ─ SECTION 2 · NOTIFICATIONS ───────|
|  [Switch] Notifications locales    |  ← ADR §13 (pas de bruit, signal 4)
|  [Toggle] Rappels locaux (Focus)   |     pack 04 §3.2.5 :
|  [Toggle] Push OneSignal (serveur) |     LocalNotificationAdapter (local)
|  [Toggle] Alertes coach (contextuel)|     + RemoteNotificationAdapter OneSignal
|                                     |     (serveur, AD-12/F-09)
| ─ SECTION 3 · COMPTE ──────────────|
|  [Profil] 4 champs G-D14 (edit)    |  ← AD-15 SSoT UserContext
|  [Forfait : étudiant] (fixe)       |     (region, disciplines,
|  [Déconnexion] (rare)              |     professional_target,
|  [Ré-initialisation] (rare)        |     budget_constraint)
|                                     |
| [CTA FIXE BAS] « Enregistrer les   |  ← AD-14 : 1 seul CTA d'action,
|   préférences » (accent doux, 48px)|     fixe, jamais un 5ᵉ bloc
+-------------------------------------+
| BottomNav 5 tabs visible (S-31,    |
| OQ-4 close option C — page mère,   |
| pas route adjacente)               |
+-------------------------------------+
```

**Garde AD-14** : CTA « Enregistrer les préférences » = seul CTA d'action, fixe bas d'écran (48 px pour le pouce), jamais un 5ᵉ bloc, jamais un dashboard (ADR §12, trigger-map §6 trap « Surcharge de widgets »). La preview du thème est statique (swatch + mini-aperçu, pas un re-render live — budget OQ-11 TTI ≤ 1,5 s, 30 fps ; 05 §2.1.3 : le recompute auto est différé au premier mount de `/settings`, pas au boot).

---

## §3 — Table des éléments (100 % de la zone)

| # | Élément | Composant DS (05 §3) | Lib ui-libraries S1 | Tokens | Variante responsive | Source SSoT |
|---|---------|----------------------|---------------------|--------|---------------------|-------------|
| 1 | Header / titre « Paramètres » | `IonHeader` + `IonTitle` (chrome, pas un composant DS) | — (chrome Ionic) | `text-primary`, `space.4`, typo `md` 20px/700 | Pleine largeur, `padding-top: safe-area-inset-top` | 02 §6.1 page matrix ; code `settings/index.tsx` l.20 |
| 2 | Section 1 : titre « Thème » | `Card` (titre `md`, contenu `space.4`) | shadcn Card | `surface`, `shadow.1`, radius `md`, `space.4` | 1 colonne (mobile) ; 2 colonnes swatches si large | 05 §3.3 l.498–505 ; code `settings/index.tsx` |
| 3 | Swatches 10 thèmes + 3 presets | `Badge` (tonal, `primary-surface` si sélectionné) × 13 | shadcn Badge | `primary-surface`, `bg-subtle`, `text-secondary`, radius `sm` | Grille 4×4 (mobile : 2×7 scroll vertical) | 05 §3.3 l.532–544 ; pack 05 §5.4/§5.5 |
| 4 | Preview statique (3 mini-cards Home/Focus/Calendar) | `Card` (flat, `bg-subtle`, sans shadow) × 3 | shadcn Card | `bg-subtle`, `space.3`, radius `md` | 3 colonnes fixes (mobile) ; 1 colonne si < 360 px | WDS 04.5 OQ-1 close (option A) ; 05 §3.3 l.504–506 |
| 5 | Section 2 : titre « Notifications » | `Card` (titre `md`) | shadcn Card | idem §3 | 1 colonne | 05 §3.3 l.498 |
| 6 | Switch « Notifications locales : ON » | `Toggle` / `Switch` (05 §3.2 l.461–469) | shadcn Switch | `primary` si ON, `surface-alt` si OFF, thumb `text-disabled` si disabled | 1 ligne, 44 px tap target | 05 §3.2 l.461–469 ; ADR §13 |
| 7 | Toggle « Rappels locaux (Focus) » | `Toggle` (préférence, pas destructive) | shadcn Switch | idem §6 | 1 ligne, 44 px | 05 §3.2 l.462 ; pack 04 §3.2.5 |
| 8 | Toggle « Push OneSignal (serveur) » | `Toggle` + `Badge` `warning` « serve only » si offline | shadcn Switch + Badge | `primary`, `warning-surface` (offline) | 1 ligne, 44 px | 05 §3.2 l.462 ; AD-12/F-09 ; code `settings/index.tsx` |
| 9 | Toggle « Alertes coach (contextuel) » | `Toggle` + sous-texte `xs` « Explique le constat, ne multiplie pas les notifications » | shadcn Switch | `primary`, `text-muted` | 1 ligne, 44 px | ADR §13 ; trigger-map §7 signal 4 |
| 10 | Section 3 : titre « Compte » | `Card` (titre `md`) | shadcn Card | idem | 1 colonne | 05 §3.3 l.498 |
| 11 | Profil (4 champs G-D14 : region, disciplines, professional_target, budget_constraint) | `ListItem` (subtitle, 2 lignes : titre `base` + subtitle `sm`) | shadcn Table (lecture seule) ou `Card` flat | `surface`, `space.4`, radius `md` | 1 colonne ; champs en `JetBrains Mono` si numériques | AD-15 SSoT UserContext ; WDS 04.5 OQ-2 close (option A, minimale) |
| 12 | Forfait : étudiant (fixe, lecture seule) | `ListItem` (1 ligne) + `Badge` `info` « étudiant » | shadcn Badge | `info-surface`, `text-secondary` | 1 ligne | AD-15 ; WDS 04.5 §6 |
| 13 | Déconnexion (rare) | `Button` (ghost, `danger` si confirmé) | shadcn Button | `text-danger`, `border-danger` si confirmé | 1 ligne, 44 px | AD-15 ; 05 §3.1 |
| 14 | Ré-initialisation (rare) | `Button` (destructive, confirmé par `AlertDialog`) | shadcn AlertDialog + Button | `danger`, `danger-surface` | 1 ligne, 44 px | 05 §3.1 l.365–411 ; AD-15 |
| 15 | CTA « Enregistrer les préférences » | `Button` (primary, fixe bas, 48 px) | shadcn Button | `primary`, `on-primary` (texte blanc) | Fixe bas, pleine largeur, `safe-area-inset-bottom` | AD-14 ; WDS 04.5 §6 ; code `settings/index.tsx` |
| 16 | Bandeau offline (si réseau coupé) | `Badge` (top bar, « Hors-ligne — les préférences sont enregistrées localement ») | shadcn Badge | `warning-surface`, `text-warning` | 1 ligne, pleine largeur, sous le header | AD-7 ; 05 §6.1 l.184 ; WDS 04.5 §7 |
| 17 | BottomNav 5 tabs (S-31) | `IonTabs` (chrome, pas un composant DS) | — (chrome Ionic) | `text-secondary`, `primary` si actif | 5 tabs, 44 px, `safe-area-inset-bottom` | OQ-4 close option C ; 02 §6.1 ; WDS 04.5 §6 |

---

## §4 — Matrice des états (S6 + sémantiques §6.1 + 404 + killed)

### (a) 6 états S6 par élément async

| Élément | loading | empty | error | success | offline | killed |
|---------|---------|-------|-------|---------|---------|--------|
| **§2 Theme swatches** | `Skeleton` × 13 (shimmer, 300 ms max, pas de spinner plein écran) | N/A (13 thèmes toujours disponibles) | N/A (thème = local, pas d'async) | `Toast` « Thème enregistré » (3 s auto-dismiss) | `Badge` warning top bar ; swatches restent actionnables (local) | N/A |
| **§4 Preview statique** | N/A (statique, pas d'async) | N/A | N/A | N/A | `Badge` warning ; preview reste statique (pas de re-render live) | N/A |
| **§6–9 Notification toggles** | N/A (local, `LocalNotificationAdapter` Capacitor) | N/A (valeur par défaut = « maîtrisées ») | N/A | `Toast` « Préférences de notifications enregistrées » (3 s) | `Badge` warning ; toggles locaux restent actionnables ; push OneSignal = `Badge` `danger` « serve only » (désactivé) | N/A |
| **§11–14 Compte (profil, forfait, déconnexion, ré-init)** | N/A (lecture `UserContext` SSoT locale) | N/A (4 champs G-D14 pré-remplis de l'onboarding 04.1) | N/A | `Toast` « Profil mis à jour » (3 s) | `Badge` warning ; édition locale persiste (AD-7) | N/A |
| **§15 CTA « Enregistrer les préférences »** | N/A | N/A | `Alert` destructive inline (si sync échouée, `Callout` sous le CTA) | `Toast` « Préférences enregistrées ✓ » (3 s) | `Badge` warning ; CTA reste actionnable (persiste localement, sync différée) | N/A |

### (b) États sémantiques §6.1

| État | S'applique ? | Composant + visual | Texte exact | CTA | Transition d'entrée/sortie | Source |
|------|-------------|--------------------|-------------|-----|---------------------------|--------|
| **en-cours** | N/A (pas de streaming ni d'import sur `/settings`) | — | — | — | — | ui-libraries §6.1 l.197 |
| **terminé** | N/A (l'écran n'a pas d'objet terminal ; le CTA = `success` Toast) | — | — | — | — | ui-libraries §6.1 l.198 |
| **échec** | N/A (pas d'opération non-réessayable in-place ; l'erreur = `error` S6 transient) | — | — | — | — | ui-libraries §6.1 l.199 |
| **succès** | **Oui** (après tap CTA) | `Toast` shadcn, 3 s auto-dismiss | « Préférences enregistrées ✓ » | — | Entrée : fade-in 200 ms easeOut (GPU opacity) ; Sortie : fade-out 200 ms | ui-libraries §6.1 l.200 ; S6 success l.183 |
| **erreur** | **Oui** (si sync échouée, `Callout` inline) | `Alert` destructive (border `danger`) | « Échec de la synchronisation — les préférences sont enregistrées localement. Réessaie au prochain retour réseau. » | « Réessayer » (Button ghost, `border-danger`) | Entrée : fade-in 200 ms ; Sortie : fade-out 200 ms | ui-libraries §6.1 l.201 ; S6 error l.181 |
| **404 / not-found** | **Oui** (page entière, si deep link `/settings/*` inconnu) | Page entière : logo AURORA **coloré sans fond, CENTRE** (§9.1/§6.1) + message court + CTA primaire | « Paramètres introuvables. » / CTA : « Retour à l'accueil » | « Retour à l'accueil » (Button primary, `accent`) ; secondaire : « Consulter l'écran parent » (ghost) | Entrée : fade-in 200 ms ; Sortie : navigation (pas de transition) | ui-libraries §6.1 l.202 ; §9.1 l.387 ; code `not-found/index.tsx` |

### (c) Killed (G-M2) sur tout flux serveur

| Élément | killed ? | Composant + visual | Texte exact | CTA | Transition | Source |
|---------|---------|--------------------|-------------|-----|-----------|--------|
| **§8 Push OneSignal** | **Oui** (serveur, AD-12/F-09) | `Badge` `danger` « serve only » + `Skeleton` shimmer (si reconnexion en cours) | « Reconnexion... » (shimmer, 1.5 s) | — (auto-resync au retour réseau) | Entrée : shimmer fade-in 300 ms ; Sortie : badge disparaît (fade-out 200 ms) | ui-libraries S6 l.185 ; WDS 04.5 §7 offline |

> **Tous les autres éléments** (swatches, preview, toggles locaux, compte, CTA) = **N/A** (local, AD-7 PowerSync mirror — killed n'existe que sur les flux serveur, pas sur les prefs locales).

---

## §5 — Animations & transitions (GPU only, 150–250 ms, reduced-motion = statique)

| Élément | Action → feedback | Durée | GPU only (transform + opacity) | smooth (pas bouncy) | reduced-motion | Source SSoT |
|---------|-------------------|-------|-------------------------------|---------------------|----------------|-------------|
| **§3 Swatch tap** | Tap swatch → fond `primary-surface` (instant, pas de transition) | 0 ms | N/A (instant) | N/A | N/A | 05 §3.3 l.523 ; ui-libraries S5 l.169 |
| **§4 Preview update** | Thème change → preview statique re-rendu (instant, pas d'animation) | 0 ms | N/A (instant, budget OQ-11 TTI ≤ 1,5 s) | N/A | N/A | WDS 04.5 OQ-1 close (option A) |
| **§6–9 Toggle flip** | Tap toggle → thumb slide left/right | 200 ms easeOut | `transform: translateX` (GPU) | smooth (pas bouncy) | `prefers-reduced-motion` : thumb saute (instant, pas de slide) | 05 §2.6 ; ui-libraries S5 l.169 ; S3 l.143 |
| **§15 CTA press** | Press → fond `primary` + léger `scale(0.98)` | 150 ms easeIn | `transform: scale` (GPU) | smooth | statique (pas de scale) | 05 §2.6 ; ui-libraries S3 l.143 |
| **§15 CTA success** | Tap CTA → `Toast` « ✓ » apparaît (fade-in 200 ms) puis disparaît (fade-out 200 ms) | 200 ms × 2 | `opacity` (GPU) | smooth | `Toast` apparaît/disparaît instantanément (pas de fade) | ui-libraries S6 l.183 ; S5 l.169 |
| **§16 Bandeau offline** | Offline détecté → bandeau `Badge` warning apparaît (fade-in 200 ms) | 200 ms | `opacity` (GPU) | smooth | statique (bandeau apparaît instantanément) | WDS 04.5 §7 ; S5 l.169 |
| **§4(c) 404 page** | Deep link inconnu → page 404 (fade-in 200 ms) | 200 ms | `opacity` (GPU) | smooth | statique | ui-libraries §6.1 l.202 |
| **Page transition (entrée `/settings`)** | Navigation vers `/settings` → `PAGE_TRANSITION` opacity 0→1 + y 8→0 | 200 ms easeOut | `transform: translateY` + `opacity` (GPU) | smooth | statique (pas de transition) | code `motion.tsx @aurora/ui` ; S5 l.169 |

> **Interdits** : layout animations sur mobile (ui-libraries S5 l.169) ; bouncy (S3 l.143) ; `prefers-reduced-motion` = statique (05 §2.6 règle 2 ; `aurora.css` media query clamps all durations to 0.01 ms).

---

## §6 — Pagination

| Règle | Paramètres | Source |
|-------|-----------|--------|
| **N/A** — `/settings` n'a pas de liste de données paginée (13 swatches + 3 mini-cards + 4 toggles + 4 lignes compte = ~24 éléments fixes, < 20 rows par zone) | Si une zone dépassait 20 éléments → shadcn `Pagination` (ui-libraries S1 l.37) ; ici : scroll natif `IonContent`, pas de paginer | ui-libraries S8 l.304–307 (< 20 rows = Table, pas de pagination) |

---

## §7 — Tokens (AD-17, 05 §5)

- **Tokens only** : aucune valeur color/spacing/typo/radius brute dans ce doc. Tous les éléments citent leurs tokens (§3).
- **10 thèmes + 3 presets** = comportement par couche (05 §5.2) :
  - **Couche 1 (Neutral)** : `light #FFFFFF` / `dark #121212` — figées, jamais redéfinies par un thème (05 §5.1 blocking rule).
  - **Couche 2 (Expressive)** : 10 thèmes (Aurora, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus, Cosmos) × 3 presets (Slate, Nocturne, High Contrast) — chacun définit 4 accents + gradient + motion mood + chart palette (05 §5.4/§5.5).
  - **Couche 3 (Local)** : Focus Mode uniquement (OQ-15) — `/settings` n'a pas d'adaptation locale.
- **Règle bloquante 05 §5.1** : un thème **ne touche jamais** `success`/`warning`/`danger`/`info` (tokens sémantiques = neutral layer uniquement).
- **Nocturne = preset autonome** (OQ-16 tranché V1, 2026-09-25) : canvas `#121212`, accents désaturés — pas un alias de Dark.

---

## §8 — Pagination (règle unique nommée)

| Règle | Nom | Paramètres |
|-------|-----|-----------|
| N/A | `/settings` = écran fixe (pas de liste de données, pas de QCM 1000+ rows) | Si un jour une zone dépasse 20 éléments → **shadcn Pagination** (ui-libraries S1 l.37 : `Pagination/PaginationContent/PaginationItem/PaginationLink` + `Previous/Next` ; `aria-current=page`) |

---

## §9 — Surfaces flottantes (05 §3.5)

| Surface | S'applique ? | Composant | Stack z-index | Source |
|---------|-------------|-----------|---------------|--------|
| `Modal` | N/A (pas de confirmation destructive sur `/settings` — la ré-init est une `AlertDialog` §4, pas un Modal) | shadcn Dialog | 40 (05 §3.5 l.754–759) | 05 §3.5 l.761 |
| `BottomSheet` | N/A (pas de select > 8 options sur `/settings`) | shadcn Sheet | 30 | 05 §3.5 l.787 |
| `Drawer` | N/A | shadcn Drawer | 30 | 05 §3.5 l.810 |
| `Toast` / `Snackbar` | **Oui** (success CTA) | shadcn Toast | 50 | 05 §3.5 l.823 ; S6 l.183 |
| `Menu` (context) | N/A | shadcn ContextMenu | 30 | 05 §3.5 l.843 |
| `Dropdown` | N/A (pas de `Select` sur `/settings`) | shadcn DropdownMenu | 30 | 05 §3.5 l.856 |

> **Stacking normative** (05 §3.5 l.754–759) : contenu 0 < TopBar/BottomNav 10 < BottomSheet/Menu/Drawer 30 < Modal 40 < Toast 50 < Splash 60. `/settings` ne déclenche que Toast (50) et AlertDialog (40).

---

## §10 — A11y WCAG AA (05 §6.3)

- **Tap targets** : ≥ 44 px (56 px en High Contrast preset) — tous les toggles (§6–9), swatches (§3), CTA (§15), lignes compte (§11–14).
- **aria-label** : tous les icon buttons (chevron déconnexion, chevron ré-init, badge offline) — `aria-label` explicite (ex. « Déconnecter », « Réinitialiser », « Bandeau hors-ligne »).
- **letter-spacing** : 0 (aucune valeur brute, token `typo.*`).
- **Focus visible** : ring `focus-ring` (token thème, `aurora.json focusTreatment = ring`) — contrast vérifié sur les 2 styles neutres (05 §6.3 ; code `aurora.json`).
- **Contraste** : `text-primary` sur `bg` ≥ 4.5:1 (WCAG AA) ; `text-secondary` ≥ 3:1 ; `Badge` warning sur `surface` ≥ 4.5:1 (nocturne = accents désaturés, mais contraste maintenu — 05 §5.5).
- **Screen reader** : `Toast` success = `role="status"` + `aria-live="polite"` ; `Badge` offline = `aria-label="Hors-ligne"` ; CTA = `aria-label="Enregistrer les préférences"`.
- **Reduced motion** : `prefers-reduced-motion` = statique (05 §2.6 règle 2 ; `aurora.css` media query clamps all durations to 0.01 ms) — tous les fades/slides/scales du §5 deviennent instantanés.

---

## §11 — Interactions détaillées

| Élément | Interaction | Feedback | Durée | Source |
|---------|-------------|----------|-------|--------|
| Swatch tap | Tap 1 des 13 swatches | Fond du swatch = `primary-surface` (sélection) ; les 12 autres = `bg-subtle` ; preview statique re-rendu instantanément | 0 ms (instant) | 05 §3.3 l.523 ; WDS 04.5 OQ-1 |
| Toggle flip | Tap toggle | Thumb slide 200 ms easeOut ; `success` Toast si préférence persistée | 200 ms | 05 §2.6 ; S5 l.169 |
| CTA press | Tap « Enregistrer » | `scale(0.98)` 150 ms ; `Toast` « ✓ » 200 ms fade-in + 3 s + 200 ms fade-out | 150 ms + 3 s + 200 ms | S3 l.143 ; S6 l.183 |
| Déconnexion | Tap « Déconnexion » → `AlertDialog` confirmation | « Tu es sûr(e) ? » + CTA « Confirmer » (destructive) / « Annuler » (ghost) | 200 ms (dialog) | 05 §3.1 ; AD-15 |
| Ré-init | Tap « Ré-initialisation » → `AlertDialog` (double confirmation) | « Toutes les données locales seront effacées. » + CTA « Confirmer » (destructive) / « Annuler » | 200 ms | 05 §3.1 ; AD-15 |

---

## §12 — Offline (AD-7 / AD-12 / AD-1)

| Élément | Classe offline (catalog) | Miroir local (AD-7/AD-12) | Dégradation AD-1 | Ce qui meurt (killed) |
|---------|-------------------------|---------------------------|------------------|----------------------|
| Thème (13 swatches + preview) | **offline-capable** (perso UI, persist middleware) | `UserContext.theme` + `theme_style` AD-15/AD-17, PowerSync mirror local (AD-7) | N/A (thème = local, pas de serveur requis) | N/A |
| Notifications locales (Focus, tâches) | **offline-capable** (AD-7, `LocalNotificationAdapter` Capacitor persistées localement) | `LocalNotificationAdapter` = Capacitor local (AD-7) | N/A | N/A |
| Push OneSignal | **online-required** (AD-12/F-09, kernel = serveur) | N/A (serveur uniquement) | `Badge` warning « serve only » si offline ; push = désactivées (les notifications locales restent actionnables, AD-7) | **killed** : `Skeleton` shimmer + « Reconnexion... » (si reconnexion en cours) |
| Compte (4 champs G-D14 + forfait + déconnexion + ré-init) | **offline-capable** (AD-15 `UserContext` SSoT, PowerSync mirror local AD-7) | `UserContext` = 4 champs + `theme`/`theme_style` AD-17, persistés localement (AD-7) | N/A | N/A |
| CTA « Enregistrer les préférences » | **offline-capable** (persiste localement, sync différée) | PowerSync mirror local (AD-7) : la configuration est **toujours** persistée localement, même sans réseau | N/A | N/A |

> **Règle AD-1 (dégradation)** : si le réseau tombe, l'écran `/settings` reste **100 % actionnable** (thème, toggles locaux, compte, CTA) — seule la push OneSignal meurt (killed : shimmer + « Reconnexion... »). Offline = état premier (AD-7), pas un échec.

---

## §13 — Occurrences logos (version exacte + raison + SSoT ref)

| Occurrence | Version du logo | Raison (designer psychology) | SSoT ref |
|------------|----------------|------------------------------|----------|
| 404 / not-found (page entière, §4c) | **COLORED sans fond, CENTRE** (`assets/aurora_icon_a_integre_dans_l'applciation.png`) | « living empty state » : le CTA « Retour à l'accueil » = marque active (color), pas monochrome (inactif) — §9.1 l.387 | ui-libraries §9.1 l.387 ; §6.1 l.202 |
| N/A (pas de logo dans le header `/settings`) | — | Le header = chrome Ionic (`IonTitle` « Paramètres »), pas un logo asset (règle S9 : le logo n'est pas dans le chrome) | code `settings/index.tsx` l.20 ; §9 l.363–364 |
| N/A (pas de `AgentThinkingLoader` sur `/settings`) | — | L'agent ne « pense » pas sur `/settings` (pas de flux async serveur, tout est local) — le loader est réservé à `/agent` (§9.3) | ui-libraries §9.3 l.420–487 |
| N/A (pas de watermark / fond / export sur `/settings`) | — | `/settings` n'a pas de fond décoratif, pas d'export document — pas de watermark (règle §9.1 l.385) | ui-libraries §9.1 l.385 |

> **Règle S9 bloquante** : ne jamais mélanger 2 libs sur le même écran (ui-libraries S8 l.333) ; ne pas redessiner/générer/détourner les logos (S9 l.352–353/390–392) ; monochrome interdit dans les états vivants (l.390–392) ; pas de recolor (l.392).

---

## §14 — Open Questions (OQ)

| # | Question | Élément | Context | Source |
|---|----------|---------|---------|--------|
| OQ-47 | `/settings` était `GAP` (claimé, NON détaillé) dans `_inventory.md` l.124 : « design-system/overview §6 + WDS 04.5 (claimé, NON détaillé) ». Ce doc le spécifie. **Question résiduelle** : le format du bloc preview thème (mini-aperçu statique vs re-render live vs liste de swatches) est **close option A** (WDS 04.5 §8 l.179, 09/25, ratifié par Joy) — mais la **liste de 13 swatches** (10 thèmes + 3 presets) n'était pas dans le corps gelé WDS 04.5 (qui proposait 2 swatches Nocturne/Light). **Question** : la grille 4×4 de 13 swatches est-elle cohérente avec le budget OQ-11 (TTI ≤ 1,5 s, 30 fps) ou faut-il scroller vertical (2×7) ? | §3 #3 (swatches 13) ; §5 (preview update) | WDS 04.5 OQ-1 close (option A : statique) ; 05 §5.4/§5.5 (10+3) ; OQ-11 budgets | WDS 04.5 §8 l.179 ; 05 §5.4 l.3010–3045 ; OQ-11 |
| OQ-48 | La section « compte » : le contenu exact (profil + forfait + déconnexion + ré-init) est **close option A** (WDS 04.5 OQ-2, 09/25, ratifié par Joy : minimale, AD-15 SSoT). **Question résiduelle** : les 4 champs G-D14 sont-ils **éditables** sur `/settings` (tap → `BottomSheet` édition) ou en **lecture seule** (l'édition = onboarding 04.1 uniquement) ? | §3 #11 (profil 4 champs) | WDS 04.5 OQ-2 close (minimale) ; AD-15 SSoT ; onboarding 04.1 | WDS 04.5 §8 l.180 ; AD-15 ; 04.1-onboarding-profil |
| OQ-49 | Les préférences de notifications : **close option A** (WDS 04.5 OQ-3, 09/25, ratifié par Joy : par type, 3 toggles). **Question résiduelle** : le toggle « Push OneSignal » = `online-required` (AD-12/F-09) — en offline, il est **désactivé** (killed) mais **affiché** (grayed out, `Badge` « serve only »). **Question** : faut-il cacher le toggle en offline (pas afficher un élément inutilisable) ou le garder visible (cohérence UI, l'utilisateur sait que la push existe mais pas en offline) ? | §3 #8 (toggle push) ; §12 (killed) | WDS 04.5 OQ-3 close (par type) ; AD-12/F-09 ; S6 l.185 (killed) | WDS 04.5 §8 l.181 ; AD-12 ; ui-libraries S6 l.185 |
| OQ-50 | La page `/settings` est **offline-capable** (perso UI, AD-7). **Question résiduelle** : le `PowerSync mirror local` (AD-7) sync les préférences avec le serveur **quand ?** — instantanément au CTA (si réseau OK) ou **différé** (prochain background sync, 02 §6.2) ? Le corps gelé WDS 04.5 dit « persiste localement, re-sync au retour réseau » (§7 l.171) — mais ne précise pas si le CTA bloque (wait sync) ou non (optimistic, AD-7 local-first). | §15 (CTA) ; §12 (sync) | WDS 04.5 §7 l.171 ; AD-7 local-first ; 02 §6.2 (pas de réseau au mount) | WDS 04.5 §7 ; AD-7 ; 02 §6.2 |

> **OQ-47/48/49** = closes (WDS 04.5, 09/25, ratifié par Joy) — les questions résiduelles ci-dessus sont les **details d'implémentation** non couverts par le corps gelé (pas de blocage spec, mais à clarifier au standup wave-0). **OQ-50** = open (sync CTA : blocking vs optimistic).

---

*Écran `settings` SPECIFIED · 14 sections complètes · 4 OQs (§14) · SSoT : 05 §5 (thèmes), WDS 04.5 (bridge), ui-libraries S1/S3/S5/S6/S9, AD-7/AD-13/AD-14/AD-15/AD-17, ADR §13/§13.1*
