# onboarding — Onboarding (3 sous-écrans max)

Status: GAP (OQ-1…OQ-14, §14) · Module : Onboarding · Route : boot, avant /home (`/onboarding`, WDS 04.1) · SSoT : 05 §4.1.1 + WDS 04.1

> 3 sous-écrans séquentiels (slides) : S1 « Qui es-tu ? » · S2 « Ton rythme de nuit » · S3 « Ton thème » —
> capte les 4 champs `UserContext` (AD-15 SSoT, 4 champs G-D14 : `region`, `disciplines`,
> `professional_target`, `budget_constraint`) en ≤ 3 écrans, sans tour de fonctions (AD-14).

## 1. Psychologie designer

- **Objectif utilisateur (1 ligne)** : que l'installatrice ressente que l'app est « à elle » — sombre,
  silencieuse, calée sur ses matières — en 3 écrans max, avant le premier soir de session
  (WDS 04.1 §1/§4 ; 05 §4.1.1 objectif).
- **Contexte (device / moment / réseau)** : mobile Android Pixel 4a, ~22 h, 3G capricieuse, forfait
  étudiant ; offline = état premier (AD-7) — pas de serveur requis pour terminer l'onboarding ; budgets
  OQ-11 : JS ≤ 300 Ko gz, TTI ≤ 1,5 s, 30 fps (WDS 04.1 §3/§10).
- **Fréquence** : une fois (premier lancement) + ré-édition rare depuis /settings (WDS 04.1 §2 entrée 2).
- **État émotionnel cible** : rassurée, calme (pas d'éblouissement clair à 22 h — Nocturne par défaut,
  OQ-16), « l'app me connaît » (WDS 04.1 §3 Hope).
- **Erreur la plus probable** : l'utilisateur s'attend à un long tour de features ou à un 4ᵉ écran ;
  la garde AD-14 interdit ça (3 écrans max, CTA unique fixe, 05 §4.1.1 + WDS 04.1 §6).
- **Ce que l'écran RÉSOUT** : « Qui es-tu ? » — il débloque la mesure de la transformation réelle
  (BG-PRIMARY, ADR §18) par un profil `UserContext` complet et persisté localement (WDS 04.1 §4).

## 2. Zones (header / content / footer + surfaces flottantes)

- **Header** : absent — l'onboarding n'est pas une surface TopBar/BottomNav (WDS 04.1 §5 : « onboarding
  n'est pas une surface avec BottomNav » ; le 5ᵉ tab agent S-31/option C n'apparaît pas ici).
- **Content (carrousel de 3 slides, 05 §4.1.1)** : `Avatar` + titre `2xl` + corps `sm` par slide
  (05 §4.1.1 zones) ; contenu par slide :
  - S1 « Qui es-tu ? » : `Avatar` (initiales, pas de logo lourd), chips `disciplines`, `Select`
    `region`, bloc `budget_constraint` verrouillé (WDS 04.1 §6).
  - S2 « Ton rythme de nuit » : fenêtre de silence `21h00 — 01h00` (présents `23h–01h` / `00h–02h`),
    préférence notifs « seulement les alertes » (WDS 04.1 §6).
  - S3 « Ton thème » : preview 2 colonnes Nocturne (surligné, défaut) | Light + 2 boutons de choix
    (WDS 04.1 §6, OQ-16).
- **Footer** : `Button primary` « Continuer » (slides 1–2) + `Button ghost` « Passer » (slide 3)
  (05 §4.1.1 zones footer, verbatim) ; le CTA final « C'est parti » est le seul point d'entrée vers le
  scénario 04.2 (WDS 04.1 §6 garde AD-14).
- **Surfaces flottantes** : aucune (pas de BottomSheet/Modal/Drawer déclenchés ; seule exception =
  1 `Alert` inline sur échec de cours local, §4 — 05 §4.1.1 états).

## 3. Éléments / widgets

Table : élément · composant DS (05 §3) · lib d'implémentation · tokens utilisés · variante responsive · source SSoT.

| Élément | Composant DS (05 §3) | Lib | Tokens | Responsive | SSoT |
|---|---|---|---|---|---|
| Carrousel 3 slides (nav gauche/droite) | Carrousel de slides | motion (Framer Motion, GPU transform+opacity) ; interdiction `layout` animations mobile (ui-libraries §5 l. 162-172, §3 l. 143) ; 200 ms ease-out = PAGE_TRANSITION (apps/mobile/src/ux/polish.tsx:23-28) | `aurora.space.2`/`space.4` ; `anim.normal` (05 §2.6) ; couleurs sémantiques `aurora.color.*` (AD-17) — aucune valeur brute (docs/design-system/overview.md §2 l. 15-25) | Phase 2 desktop : 3 étapes empilées, CTA en bas, logique inchangée (05 §4.1.1 notes responsive) | 05 §4.1.1 DS carrousel |
| Avatars initiales (S1) | `Avatar` (05 §3.3 l. 491) | shadcn/ui avatar (`npx shadcn@latest add avatar`, ui-libraries S1 l. 9-66) | `aurora.color.bg-subtle`, `border` ; taille via grille 4/8px (`aurora.space`, 05 §2.3) | — | 05 §4.1.1 DS Avatar |
| Titre de slide | Typo `2xl` (05 §2.2 l. 190-230) | @fontsource/inter (ui-libraries S1) | `aurora.typo.2xl` ; Inter 300 interdit (05 §2.2 l. 227-230) | — | 05 §4.1.1 zones |
| Corps de slide | Typo `sm` (05 §2.2) | @fontsource/inter | `aurora.typo.sm`, `text-secondary` | — | 05 §4.1.1 zones |
| Chips disciplines « Étudiante · BA · RDM · Hydraulique » (S1) | `Chip` (05 §3.3 l. 491) | shadcn/ui badge/chip (S1) | `aurora.color.primary` (état sélectionné), `surface` (neutre) ; tap ≥ 44px (05 §6.3) | — | WDS 04.1 §6 (3 cases G-D14) |
| Select matière `disciplines` (G-D14) (S1) | `Select` (05 §3.2 l. 412) — `BottomSheet` si > 20 options | shadcn/ui select + Radix (S1) | `aurora.color.surface`, `border-strong` ; focus ring (05 §2.6, a11yRefs) | — | 05 §4.1.1 DS Select |
| Région `region` « ▼ Cotonou » (G-D14) (S1) | `Select` (05 §3.2) | shadcn/ui select (S1) | idem Select | — | WDS 04.1 §6 |
| `professional_target` (G-D14) (S1) | Affiché `Callout` (05 §3.3 l. 491) pré-rempli « Bureau d'études BAC » (WDS OQ-1 option A close, 09/25, WDS 04.1 §8) ; **non éditable ici** (édition ultérieure /settings S-30) | shadcn/ui card/callout | `aurora.color.info` (couche neutre, règle 05 §5.1 — thème ne touche jamais success/warning/danger/info) | — | WDS 04.1 §8 OQ-1 |
| `budget_constraint` verrouillé (G-D14) (S1) | `Badge` (05 §3.3 l. 491) ; 05 §3.2 interdit `Toggle`/chargement animé sur ce type de champ — ici champ verrouillé, jamais un `Toggle` (05 §3.2 l. 412) | shadcn/ui badge (S1) | `aurora.color.surface-alt`, `text-disabled` | — | WDS 04.1 §6 (verrouillé par défaut) |
| Fenêtre silence 21h00 — 01h00 (S2) | `DateField`/`DurationField` (05 §3.2 l. 412 — pas de format HH:MM) | shadcn/ui (S1) ; `Slider` (05 §3.2) pour la fenêtre | `aurora.space.2` ; heures en `JetBrains Mono` (05 §2.2 tabular-nums l. 190-230) | — | 05 §4.1.1 DS + WDS 04.1 §6 |
| Presets de silence 23h–01h / 00h–02h (S2) | `Chip` (05 §3.3) | shadcn/ui chip (S1) | `aurora.color.primary` (actif) / `surface` (inactif) | — | WDS 04.1 §6 |
| Toggles « Notifs : seulement les alertes » (S2) | `Toggle`/`Switch` (05 §3.2 l. 412) — jamais de `loading` animé sur ce type de champ (05 §3.2) ; `Checkbox` ≥ 44px | shadcn/ui switch/checkbox (S1) | `aurora.color.surface`, `border` ; tap ≥ 44px (05 §6.3) | — | WDS 04.1 §6 (S-30) |
| Thème (S3) | `Toggle` (05 §4.1.1 DS) + preview 2 colonnes Nocturne/Light ; Nocturne = preset autonome (OQ-16, 05 §5.5 l. 3153) | shadcn/ui switch + card preview (S1) ; `AuroraThemeProvider` (packages/ui/src/theme/provider.tsx) — thème = JSON, jamais de changement silencieux au foreground (05 §5.8, design-system/overview.md §3 l. 27-54) | 3 couches : neutre (light #F8FAFC / dark #0A0E1A, design-system/overview.md §2 l. 15-25) × 10 expressifs × 3 presets (05 §5.5) ; règle 05 §5.1 l. 2931-2959 — le thème ne rédefinit JAMAIS success/warning/danger/info | — | 05 §4.1.1 + WDS 04.1 §6 (OQ-16) |
| CTA « Continuer » (slides 1–2) + « C'est parti » (slide 3) | `Button primary` (05 §3.1 l. 365 — max 1 primary par écran ; `size=lg` 56px pour CTA d'EmptyState/Modal, ici slide 3) | shadcn/ui button (`npx shadcn@latest add button`, S1) | `aurora.color.primary` (fond), `on-primary` (texte), focus ring (05 §2.6, a11yRefs 44px/56px High Contrast) ; pas de radius > 8px (forbidden) | Slide 3 : fixe en bas, 48px height pouce (WDS 04.1 §6) | 05 §4.1.1 footer + WDS 04.1 §6 |
| CTA « Passer » (slide 3) | `Button ghost` (05 §3.1 l. 365 — jamais à côté de `primary` sans espacement ≥ `space.2`) | shadcn/ui button variant ghost (S1) | `text-secondary` (05 §3.1) ; tap ≥ 44px | — | 05 §4.1.1 footer (verbatim) |
| Retour (slides 2–3) | `Button ghost` (05 §3.1) | shadcn/ui button variant ghost (S1) | `text-secondary` ; `anim.fast` pressed (05 §2.6) | — | WDS 04.1 §6 (← Retour) |

## 4. États (6 S6 : loading/empty/error/success/offline/killed) — par élément async

05 §4.1.1 (SSoT, verbatim) : `empty` n'existe pas (l'onboarding **précède** les données). Les 6 états
S6 (ui-libraries §6 l. 174-187) sont énumérés pour l'ensemble de l'écran ci-dessous ; les éléments
sync (chips, boutons de navigation, preview thème) ne gèrent pas d'état async — leur seul état
« killed » = rechargement du store local (§12).

| État | Texte exact (verbatim 05 §4.1.1 / WDS 04.1 §7) | Visuel (composant + tokens) | CTA | SSoT |
|---|---|---|---|---|
| **loading** | SSoT muette sur le texte (WDS 04.1 §7 Loading = « — » ; ui-libraries §6 S6 loading = `Skeleton` sans texte exact pour cet écran) — **OQ-7** : texte exact du skeleton loading | `Skeleton` pulse 0.6→1 / 1.2s, 3 lignes, ~300 ms max, pas de spinner plein écran (30 fps OQ-11) ; `aurora.color.skeleton` (05 §2.1.3 nuances 400 dark, a11yRefs) | — (aucun CTA pendant le loading) | 05 §4.1.1 DS Skeleton + WDS 04.1 §7 + OQ-7 |
| **empty** | n'existe pas (l'onboarding précède les données) — OQ-4 : si ré-édition depuis /settings (WDS 04.1 §2 entrée 2) avec `UserContext` vide = `EmptyState` (05 §3.3 l. 491, 1 CTA max « Continuer ») ; état par défaut = 3 slides pré-remplies | `EmptyState` (05 §3.3 l. 491) : icône `ic-…` (nomenclature `ic-{concept}-{variante}`, 05 §2.5 l. 287-308), 1 CTA max ; `aurora.color.surface`, `text-secondary` | `Button primary` « Continuer » | OQ-4 (non détaillé dans SSoT 05/WDS) |
| **error** (échec import cours local) | `Callout danger` — texte exact **OQ-11** : le mot-à-mot « import échoué — vous pouvez choisir plus tard » n'est **pas** verbatim ; la SSoT verbatim 05 §4.1.1 état error (l. 1345-1348) dit seulement que la matière **peut** être choisie plus tard et que l'onboarding **s'achève** malgré l'échec (on ne bloque pas l'entrée, AD-7) ; WDS 04.1 §7 n'a pas de ligne S6 `error` import-échoué (sa ligne `Error` = le bandeau mirror corrompu « Connexion instable — les données sont enregistrées localement ») → texte du `Callout` = OQ | `Callout` (05 §3.3 l. 491) : bordure `danger` (couche neutre, règle 05 §5.1), icône danger (Ionicons `ic-alert-danger` 05 §2.5) ; `retry` = `Button secondary` sm (05 §3.1) | `Button secondary` « Réessayer » (sm, 32px, 05 §3.1) | 05 §4.1.1 DS états |
| **offline** | `Badge info` « importera à la connexion » (05 §4.1.1 état offline ; 4 choix restent **locaux**, AD-7) ; bandeau fine « Connexion instable — les données sont enregistrées localement » (WDS 04.1 §7 Error state) | `Badge` info (05 §3.3 l. 491, `aurora.color.info` neutre) + `Callout` (05 §3.3) ; `Button primary` « C'est parti » reste actionnable (pas de serveur requis) | `Button primary` « C'est parti » (action locale, AD-7) | 05 §4.1.1 DS états + WDS 04.1 §7 |
| **success** | `Toast` auto-dismiss 3 s — texte exact **OQ-13** : « Profil enregistré ✓ » n'est **pas** verbatim SSoT (05 §4.1.1 n'a pas de ligne `success` ; WDS 04.1 §7 n'a pas de ligne S6 success ; sens SSoT = confirmation transitoire du profil `UserContext` persisté, S6 l. 183) — affiché juste après le CTA « C'est parti » slide 3, avant redirect `/inbox` | `Toast` (05 §3.5 l. 823-842, `aurora.color.success` gelé 05 §5.1) ; 1 ligne max, pas de CTA interne (05 §3.5) | — (pas de CTA dans la `Toast` ; l'action = le redirect qui suit) | 05 §4.1.1 DS états + ui-libraries §6 l. 183 + **OQ-13** (texte exact non verbatim) |
| **killed** (re-synchro requise, mirror corrompu) | Bandeau fine « données locales, re-synchro requise » — **OQ-14** : libellé **non** verbatim SSoT (05 §3.7 l. 1290-1301 donne « Reconnexion… » ; WDS 04.1 §7 Error = « Connexion instable — les données sont enregistrées localement ») ; 3 écrans **toujours** affichés (les champs sont locaux, AD-7) | `Callout` (05 §3.3) : fond `surface-alt`, bordure `warning` (couche neutre 05 §5.1) ; `Button primary` « Enregistrer localement » — libellé CTA = **OQ-14** (WDS 04.1 §7 Actions = « Tap CTA → persiste localement, re-sync au retour réseau », sans libellé verbatim) | `Button primary` « Enregistrer localement » (persistance PowerSync mirror local, AD-7 ; libellé = **OQ-14**) | WDS 04.1 §7 Error + 05 §3.7 l. 1290-1301 (**OQ-14** — libellés non verbatim ; 05 §4.1.1 n'a pas d'état `killed`) |

### Récap par élément async (05 §3.7 matrice AD-13 l. 1244-1306)

| Élément async | loading | empty | error | success | offline | killed |
|---|---|---|---|---|---|---|
| Carrousel / Avatar / titres (slides 1–3) | `Skeleton` (3 lignes, ~300 ms) | n/a (pas de données) | `Callout danger` (sur échec import, slide 1 uniquement) | n/a (pas de confirmation transitoire par slide) | `Badge info` « importera à la connexion » (slide 1) | bandeau fine (libellé = **OQ-14**), 3 slides affichées, CTA local (05 §3.7 l. 1290-1301 + WDS 04.1 §7 ; **OQ-14**) |
| CTA « C'est parti » (slide 3) | inactif (button disabled, `aurora.color.text-disabled`, 05 §3.1) | n/a | inactif sur échec import local (non bloquant, AD-7) | `Toast` auto-dismiss 3 s après le tap, texte exact **OQ-13** (proposé « Profil enregistré ✓ », non verbatim SSoT, §4a) (S6 success, ui-libraries §6 l. 183) | **actionnable** (pas de serveur requis, AD-7) | **actionnable** (persistance locale, AD-7) |

### États sémantiques §6.1 (ui-libraries l. 189-202) — par élément async

| État | Rendu sur cet écran | SSoT |
|---|---|---|
| `en-cours` (l. 197) | N/A — pas de flux mesurable avec résultat partiel sur l'onboarding (pas de streaming, pas de job ; l'import de cours local = échec **transitoire** S6 `error` « Réessayer », jamais un progrès mesurable) ; l'import différé (`Badge info` « importera à la connexion », état offline) est **différé**, pas en-cours (05 §4.1.1 état offline, AD-7) | ui-libraries §6.1 l. 197 |
| `terminé` (l. 198) | **OUI** — après CTA « C'est parti » (slide 3), l'onboarding est **terminé** : `Toast success` auto-dismiss 3 s, texte exact **OQ-13** (proposé « Profil enregistré ✓ », non verbatim SSoT) + redirect → `/inbox` (S-23, WDS OQ-3 option B close, 09/25) ; pas de `CheckCircle2` (l'objet = le profil `UserContext`, pas un item de feed) | ui-libraries §6.1 l. 198 ; WDS OQ-3 ; **OQ-13** |
| `échec` (l. 199) | N/A — l'échec d'import cours local = S6 `error` (transitoire, « Réessayer » en place, AD-7) ; l'onboarding **s'achève malgré l'échec** (05 §4.1.1 état error) — jamais un échec terminal non-réessayable qui bloque l'entrée | ui-libraries §6.1 l. 199 |
| `succès` (l. 200) | **OUI** — `Toast` auto-dismiss 3 s après CTA « C'est parti », texte exact **OQ-13** (proposé « Profil enregistré ✓ », non verbatim SSoT) (S6 `success`, ci-dessus) | ui-libraries §6.1 l. 200 ; §6 l. 183 ; **OQ-13** |
| `erreur` (l. 201) | **OUI** — `Callout danger` « import échoué — vous pouvez choisir plus tard » + `Button secondary` « Réessayer » (S6 `error`, table 4a ci-dessus) | ui-libraries §6.1 l. 201 ; §6 l. 181 |
| `404 / not-found` (l. 202) | **OUI** — voir §4(c) ci-dessous : logo AURORA **coloré SANS fond, au CENTRE** (§9.1 l. 387), jamais un 404 nu (feature-registry S6, not-found/index.tsx l. 1) | ui-libraries §6.1 l. 202 ; §9.1 l. 387 |

### (c) 404 / not-found (ui-libraries §6.1 l. 202, seule state qui mandate le logo centré)

| Élément | Rendu | SSoT |
|---|---|---|
| Page entière (route inconnue / deep link vers l'onboarding) | Logo `aurora_icon_a_integre_dans_l'applciation.png` **coloré SANS fond, au CENTRE** de la page (ui-libraries §9.1 l. 387 : « 404 = COLORED without-background, CENTERED — living empty state, jamais monochrome ») ; message court « Cette page n'est pas disponible » ; CTA primaire `Button primary` **« Retour à l'accueil »** (→ `/home`, 02 §6.3 l. 426-430) ; CTA optionnel secondaire `Button ghost` « Consulter l'écran parent » ; **pas de crash, pas de 404 nu** (feature-registry S6, not-found/index.tsx l. 1-2) ; l'onboarding n'est pas une fonction désactivable par le feature-registry (G-M7, OQ-5, catalog l. 84) → jamais un `data-state=feature-disabled` ici ; occurrence logo listée au **§13** (row « 404 / not-found ») | ui-libraries §6.1 l. 202 ; §9.1 l. 387 ; §9 l. 382-392 ; not-found/index.tsx ; §13 |

### (d) `killed` sur tout flux serveur (ui-libraries S6 l. 185 ; 05 §3.7 l. 1290-1301)

L'onboarding = **local-first 100 %** (AD-7, PowerSync mirror, WDS 04.1 §3) — **aucun** flux serveur synchrone au mount ; le seul flux serveur = la **re-synchro différée** de l'import cours local (05 §4.1.1 état offline). `killed` = **sous-état de `loading`** : relaunch cold **part du miroir local** (AD-7 — jamais d'écran blanc ni de reset), les 3 slides restent affichées, bannière fine — libellé = **OQ-14** (verbatim SSoT = 05 §3.7 l. 1290-1301 « Reconnexion… » / WDS 04.1 §7 Error « Connexion instable — les données sont enregistrées localement ») — les champs restent **actionnables** (AD-7, WDS 04.1 §7). Les composants `loading = n/a` (`Button`, `Badge`, `Callout`) n'ont **rien** de nouveau à rendre (05 §3.7 l. 1297-1298).

Source : 05 §3.7 matrice AD-13 l. 1244-1306 (killed = sous-état de loading) + WDS 04.1 §7 (verbatim) ; règle test par état (05 §3.7 matrice AD-13 l. 1244-1306) ; libellés bandeau/CTA = **OQ-14**.

## 5. Micro-interactions

Table : élément · action → feedback · durée (150–250 ms) · GPU only (transform + opacity) · comportement
`prefers-reduced-motion` = static (05 §2.6 règle 2 l. 330-334, docs/ui-libraries.md §5 l. 162-172 ;
forbidden : bouncy animations, `layout` animations mobile) · source SSoT.

| Élément | Action → feedback | Durée | GPU only | Reduced-motion | SSoT |
|---|---|---|---|---|---|
| CTA « Continuer » (slides 1–2) / « C'est parti » (slide 3) | pressé → `pressed` (fond scintille, `anim.fast`) ; focus → ring 2px `focus-ring` (05 §2.6, a11yRefs l. 3281-3294) ; disabled → fond `surface-alt`, texte `text-disabled`, pas de pressed (05 §3.1) | `anim.fast` (05 §2.6 l. 310-320, 150 ms) ; transition de slide = 200 ms ease-out (`PAGE_TRANSITION`, apps/mobile/src/ux/polish.tsx:23-28) | transform + opacity uniquement (forbidden : `layout` animations mobile, docs/ui-libraries.md §5 l. 162-172) | statique/instantané (`@media (prefers-reduced-motion: reduce) → 0.01ms !important`, packages/ui/src/styles/aurora.css:126-134) | 05 §3.1 + 05 §2.6 |
| CTA « Passer » (slide 3) | pressé → `pressed` (05 §3.1) | `anim.fast` (150 ms) | transform + opacity | statique | 05 §3.1 |
| Chips disciplines (S1) | tap → transition vers état sélectionné (`aurora.color.primary`), scale 0.95 pressed (05 §3.1 FAB pattern appliqué aux chips) | 150 ms (`anim.fast`, 05 §2.6) | transform + opacity | statique | 05 §3.3 + 05 §2.6 |
| Thème Nocturne/Light (S3) | tap → transition instantanée de tokens via CSS variables (`AuroraThemeProvider`, packages/ui/src/theme/provider.tsx ; docs/design-system/overview.md §3 l. 27-54) | 150 ms (`anim.fast`, 05 §2.6) — jamais de changement silencieux au foreground (05 §5.8) | transform + opacity (pas d'animation bloquante sur le choix de thème) | statique | 05 §5.8 + 05 §2.6 |
| Retour (slides 2–3) | tap → slide précédente (`PAGE_TRANSITION` 200 ms, apps/mobile/src/ux/polish.tsx:23-28) | 200 ms ease-out | transform + opacity (pas de `layout` animations mobile, forbidden) | statique | polish.tsx:23-28 |
| `Toggle`/`Switch` (S2 — préférences notifs) | pressé → `pressed` (05 §3.2 l. 412 — **jamais** de `loading` animé sur ce type de champ) ; état intermédiaire = `aurora.color.primary` (05 §3.2) | 150 ms (`anim.fast`, 05 §2.6) | transform + opacity | statique | 05 §3.2 + 05 §2.6 |
| Sélection matière `Select` (S1) | transition vers état sélectionné ; focus → ring (05 §2.6, a11yRefs) | 150 ms (`anim.fast`, 05 §2.6) | transform + opacity | statique | 05 §3.2 |
| Reveal des slides (si `AnimationController`) | `AnimationController` (packages/ui/src/renderers/AnimationController.tsx:19-25) : `REVEAL_DURATION` 150/250/400 ms, reduced-motion = instant (pas de trace) | 250 ms (règle 05 §2.6, `aurora.anim.normal`) | transform + opacity (pas d'animation bloquante, 05 §2.6) | statique/instantané | 05 §2.6 + AnimationController |
| Focus Mode (si activé sur l'écran) | `FocusThemeAdapter` (apps/mobile/src/ux/theme-adapter.tsx) : atténuation du skeleton pulse via `data` attrs (OQ-15, V1 = Focus screen ONLY) ; Focus Mode coupe les animations secondaires (05 §2.6 l. 310-320) | — (pas d'animation sur données scientifiques, 05 §2.6 règle 1) | GPU only | statique (Focus Mode = animations secondaires coupées, 05 §2.6) | 05 §2.6 + theme-adapter.tsx |

Note : 05 §4.1.1 `error` (échec matière) = **pas** de micro-interaction (état statique, `Callout danger`
posé — 05 §2.6 règle 3 : jamais d'animation intrusives ; le Home/onboarding est calme, 05 §2.6).

## 6. Modals / BottomSheets / Drawers

| Surface | Déclencheur | Contenu | Focus-trap | Dismissal | Transition | SSoT |
|---|---|---|---|---|---|---|
| `BottomSheet` (Select matière, > 20 options) | Tap sur `Select` `disciplines` ou `region` (05 §3.2 l. 412 : `Select` = `BottomSheet` si > 20 options) | Liste des options `disciplines` / `region` (05 §3.2) ; focus-trap Radix (shadcn/ui select, S1 l. 9-66) | Radix Dialog focus-trap (packages/ui/src/components/ui/sheet.tsx, ssootCode) | `Esc` (desktop) / tap en dehors (mobile) ; jamais de double-fermeture | 150–250 ms (05 §2.6), GPU only, `prefers-reduced-motion` = statique (05 §2.6 règle 2) | 05 §3.2 l. 412 + ui-libraries S1 |
| `Alert` / `Callout danger` (échec import cours) | Échec de l'upload de cours local (05 §4.1.1 état error) | `Callout` danger : « import échoué — vous pouvez choisir plus tard » + `Button secondary` « Réessayer » (05 §3.3 l. 491, 05 §3.1 l. 365) ; **non** modal (05 §4.1.1) — posé inline, non intrusif (05 §2.6 règle 3) | Pas de focus-trap (inline, 05 §4.1.1) | Automatique à la réouverture de la slide 1 ; `retry` = action manuelle | Pas de transition (statique, 05 §2.6) | 05 §4.1.1 DS états |
| `Modal` (confirmation destructive) — **NON UTILISÉ** ici | N/A (pas d'action destructive sur l'onboarding, 05 §4.1.1) | N/A | N/A | N/A | N/A | 05 §3.1 l. 365 (`destructive` = `Modal` obligatoire) — non applicable |

Note 05 §3.5 (l. 752-864) : `Modal` (85% viewport, jamais empilé, z=40), `BottomSheet` (peek ≈25% /
full ≈85%, z=30), `Drawer` (filtres mobile uniquement, z=30) — l'onboarding n'utilise **aucune**
surface flottante standard (pas de BottomNav, pas de FAB, WDS 04.1 §5/§6).

## 7. Formulaires

Chaque champ du carrousel = `shadcn/ui Form` + React Hook Form + zod (`npx shadcn@latest add form` +
`npm install react-hook-form @hookform/resolvers zod`, ui-libraries S1 l. 9-66). Règle 05 §3.2
(l. 412) : un champ = **un seul label visible**, label au-dessus (jamais placeholder en double),
erreur inline sous le champ (`danger` + icône, 05 §3.2), jamais dans un `Toast` (05 §3.2).

| Champ (G-D14) | Composant | Lib | Validation | Clavier mobile | Persistance | SSoT |
|---|---|---|---|---|---|---|
| `disciplines` (S1) | `Select` / chips (05 §3.2 l. 412, 05 §3.3 l. 491) | shadcn/ui select + chips (S1) | ≥ 1 discipline (05 §3.2 : `Select` = `BottomSheet` si > 20 options) | `touch` handlers (ui-libraries §5 l. 162-172, 44px tap targets) ; pas de format HH:MM (05 §3.2) | Local-first auto-persist (02 §6.3, AD-7 PowerSync mirror, WDS 04.1 §3) | 05 §4.1.1 + WDS 04.1 §6 |
| `region` (S1) | `Select` (05 §3.2 l. 412) | shadcn/ui select (S1) | Valeur requise (05 §3.2) | Idem | Idem | WDS 04.1 §6 |
| `professional_target` (S1) | `Callout` pré-rempli (WDS OQ-1 option A close, 09/25) — **non éditable ici** (05 §4.1.1 DS, WDS 04.1 §8) ; édition ultérieure = /settings S-30 | shadcn/ui card (S1) | — (pré-rempli, inféré de `disciplines` + `region`, WDS 04.1 §8 OQ-1) | — | Idem | WDS 04.1 §8 OQ-1 |
| `budget_constraint` (S1) | Verrouillé par défaut (WDS 04.1 §6 : non éditable, jamais un `Toggle` — 05 §3.2 l. 412) | shadcn/ui badge (S1) | — | — | Idem | WDS 04.1 §6 |
| Silence windows (S2) | `DateField`/`DurationField` (05 §3.2 l. 412 — pas de format HH:MM) + `Slider` (05 §3.2) | shadcn/ui slider (S1) ; valeurs en `JetBrains Mono` tabular-nums (05 §2.2 l. 190-230) | Fenêtre valide (05 §3.2) | `Slider` = 44px tap targets (05 §3.2, ui-libraries §5) | Idem | 05 §4.1.1 DS + WDS 04.1 §6 |
| Préférences notifs (S2) | `Toggle`/`Switch` (05 §3.2 l. 412 — **jamais** de `loading` animé) | shadcn/ui switch (S1) | — | 44px tap targets (05 §3.2) | Idem | WDS 04.1 §6 |
| `theme` (S3) | `Toggle` Nocturne/Light (05 §4.1.1 DS) ; Nocturne = preset autonome (OQ-16, 05 §5.5 l. 3153) | `AuroraThemeProvider` (packages/ui/src/theme/provider.tsx) ; thème = JSON, jamais de changement silencieux au foreground (05 §5.8, design-system/overview.md §3 l. 27-54) | — | Toggles 44px (05 §3.2) | Persisté (UI store, `persist` middleware, 05 §5.8 l. 3235) | 05 §4.1.1 + WDS 04.1 §6 (OQ-16) |

Règle locale (02 §6.3) : l'onboarding **persiste localement** (AD-7 PowerSync mirror, WDS 04.1 §3) —
pas de serveur requis pour terminer. Ré-édition depuis /settings (WDS 04.1 §2 entrée 2) : retour à
`/settings` après `update AD-15`.

## 8. Pagination

Règle unique nommée pour l'écran : **Aucune pagination sur l'onboarding** — 3 slides fixes
(05 §4.1.1 DS carrousel) ; le carrousel est un **composant de navigation d'étapes**, pas une
pagination de données. Si données (ex. liste `disciplines` > 20 options dans le `Select`) :
`BottomSheet` (05 §3.2 l. 412) — pas de pagination par page (pas de `shadcn Pagination`, S1 l. 37 ;
pas d'AG Grid, S1). Pager jour/semaine/mois = non applicable (pas de données temporelles de liste
sur l'onboarding, 05 §3.4 l. 657).

Source : 05 §4.1.1 DS (3 slides) + 05 §3.2 l. 412 (`Select` → `BottomSheet`).

## 9. Transitions

| Transition | Spec | SSoT |
|---|---|---|
| **Entrée** (premier lancement, `UserContext` vide) | Route par défaut `/onboarding` (WDS 04.1 §2 entrée 1) ; `PAGE_TRANSITION` (apps/mobile/src/ux/polish.tsx:23-28) : `{initial y:8, 200ms ease-out, exit y:-4}` — GPU only, `reduced-motion` = statique (polish.tsx header + packages/ui/src/styles/aurora.css:126-134) | WDS 04.1 §2 + polish.tsx:23-28 |
| **Sortie** (CTA « C'est parti », slide 3) | Redirect → `/inbox` (S-23, WDS 04.2) ; **pas** `/home` (WDS OQ-3 option B close, 09/25 : CTA redirige vers `/inbox`, pas `/home`, WDS 04.1 §8) ; `PAGE_TRANSITION` 200 ms (polish.tsx:23-28) | WDS 04.1 §8 OQ-3 + polish.tsx |
| **Nav entre slides 1↔2↔3** | `Retour` (←, slides 2–3) et `Continuer` (→, slides 1–2) ; `PAGE_TRANSITION` 200 ms (polish.tsx:23-28) ; onboarding interrompu = reprend au premier choix manquant (store local, AD-7, 05 §4.1.1 transitions) | polish.tsx + 05 §4.1.1 |
| **Retour natif Android** (bouton back pendant onboarding) | Slide 2/3 → slide 1 (contexte préservé, 02 §6.3) ; Slide 1 → app quit (pas de 4ᵉ écran, AD-14, 05 §4.1.1) ; jamais de changement de tab (02 §6.1 l. 310-344) | 02 §6.3 + 02 §6.1 |
| **Ré-édition depuis /settings** (S-30) | Retour à `/settings` après `update AD-15` (WDS 04.1 §2 entrée 2) ; contexte préservé (02 §6.3) | WDS 04.1 §2 + 02 §6.3 |

Règle transversale (02 §6.1 l. 310-344, pack 02 §6.1) : détail léger = `BottomSheet` par-dessus le
tab courant ; détail lourd (TopBar + sub-nav) = route push ; **jamais** de changement de tab. L'onboarding
n'a pas de BottomNav → aucun détail lourd, aucune `BottomSheet` standard (05 §4.1.1, WDS 04.1 §5).

## 10. Thèmes

Comportement des 3 couches (05 §5.2 l. 2961, design-system/overview.md §3 l. 27-54) sur l'onboarding :

- **Couche 1 — Style Neutre** (light `#F8FAFC` / dark `#0A0E1A`, design-system/overview.md §2 l. 15-25,
  05 §2.1 l. 124/159) : fond, surfaces, texte, bordures, états sémantiques (`success`/`warning`/
  `danger`/`info` **gelés**, 05 §5.1 l. 2931-2959 — **le thème ne les touche JAMAIS**).
- **Couche 2 — Thème Expressif** (10 thèmes, 05 §5.4 l. 3010/3032/3047) : `theme_accent[token]` en
  priorité (résolution `valeur = theme_accent[token] ?? style_neutre[token] ?? défaut`, 05 §5.3 l. 2992) ;
  l'onboarding **n'impose** pas de thème par défaut (le choix de thème est un champ de l'onboarding
  lui-même, slide 3, S3 ; thème Nocturne = défaut affiché, WDS 04.1 §6, OQ-16) ; si `theme_accent`
  absente → `style_neutre` (05 §5.3).
- **Couche 3 — Preset** (05 §5.5 l. 3153) : Slate / Nocturne / High Contrast ; Nocturne = preset
  autonome (OQ-16, 05 §5.5) ; High Contrast = 56px tap targets / 3px focus ring (design-system/overview.md
  §7 l. 87-91, 05 §5.5) ; **V1 = 10 thèmes** (design-system/overview.md §9 l. 101-115, G-H2/G-M6 résolus).
- **Local Adaptation** (05 §5.10, OQ-15) : `FocusThemeAdapter` (apps/mobile/src/ux/theme-adapter.tsx)
  — **V1 = Focus screen ONLY, OQ-15** ; l'onboarding **n'a pas** de `FocusThemeAdapter` (pas de
  `node.secondary-opacity` / `active-contrast` sur l'onboarding, theme-adapter.tsx header).
- **Règle bloquante 05 §5.1** : le thème ne rédefinit **JAMAIS** `success`/`warning`/`danger`/`info`
  (l. 2931-2959) ; `danger`/`warning` sur l'onboarding = couche neutre uniquement (05 §4.1.1 états).

## 11. A11y

WCAG AA (05 §6.3 l. 3327-3335, docs/design-system/overview.md §7 l. 87-91, docs/ui-libraries.md §5
l. 162-172) :

| Règle | Détail sur l'onboarding | SSoT |
|---|---|---|
| Contraste (thème × style neutre) | Vérifié par thème × style neutre (05 §6.3, design-system/overview.md §7) ; 10 thèmes × 5 écrans (05 §5.7 l. 3183, lagoon×focus l. 3201, 49 restants = vague 0 l. 3227) | 05 §5.7 + §6.3 |
| Tap targets | 44px min (05 §6.3) ; 56px sur `High Contrast` preset (design-system/overview.md §3 l. 27-54, 05 §5.5 l. 3153) ; `tapTargetPx` / `focusRingWidth` (packages/ui/src/themes/types.ts:113-118) | 05 §6.3 + design-system/overview.md §3 |
| Focus ring | Visible (ring contrast, 05 §6.3) ; 2px par défaut, 3px sur High Contrast (05 §5.5, design-system/overview.md §7 l. 87-91) ; `focus-ring` (05 §2.6) | 05 §2.6 + §5.5 + §6.3 |
| `aria-label` sur **tous** les icon buttons (05 §6.3, a11yRefs l. 3281-3294) | `IconButton` retour (slides 2–3) = `aria-label` obligatoire (05 §3.1 l. 365) ; CTA « C'est parti » (slide 3) = `aria-label` si icône sans texte (05 §3.1) ; `role='status'` + `aria-label` sur les états loading/killed (apps/mobile/src/ux-states.tsx:79,85,107) ; `role='alert'` sur les états error (apps/mobile/src/ux-states.tsx) | 05 §3.1 + §6.3 + ux-states.tsx |
| `letter-spacing` 0 (05 §6.3 l. 3327-3335) | Pas de `letter-spacing` sur les labels de l'onboarding (05 §6.3) | 05 §6.3 |
| Réduit-motion | `@media (prefers-reduced-motion: reduce)` → `0.01ms !important` (packages/ui/src/styles/aurora.css:126-134) ; `useReducedMotion` gate (polish.tsx, theme-adapter.tsx, AnimationController) ; 05 §2.6 règle 2 (l. 330-334) = **obligatoire** | 05 §2.6 + aurora.css:126-134 |
| Progress bar `role` | `progressbar` = `role` + `aria-valuenow`/`min`/`max` + `aria-label` (apps/mobile/src/pages/goals/dashboard.tsx:80-87 + home/goal-card.tsx:54-61) ; non applicable sur l'onboarding (pas de progress bar de données, 05 §4.1.1) | a11yRefs (patterns) |

Règle : **tous** les `IconButton` sans `aria-label` = CI rouge (05 §3.1 l. 365, test CI, §7).

## 12. Offline

**Classe offline** (catalog `identity.session` l. 84 + `05 §4.1.1`) : l'onboarding est **fully offline-capable** — les 4 champs `UserContext` (`region`, `disciplines`, `professional_target`, `budget_constraint`, AD-15) sont persistés localement (PowerSync mirror, AD-7, `02 §6.3` auto-persist, WDS 04.1 §3 l. 75-76) ; **pas de serveur requis pour terminer** l'onboarding (`05 §4.1.1 état offline`, AD-7 : « l'offline est un état de classe, pas une panne »).

| Aspect | Spécification | SSoT |
|---|---|---|
| Classe offline (catalog) | `offline-capable (miroir local)` — `identity.session` = core (toujours active, modules/index.md §2, catalog l. 84) ; l'onboarding n'est pas une feature désactivable par le `feature-registry` (G-M7, OQ-5 ouverte) ; jamais un 4ᵉ écran (AD-14) | catalog l. 84 + `05 §4.1.1` |
| Miroir local (AD-7) | 4 champs `UserContext` (AD-15 SSoT) = PowerSync mirror SQLite (AD-7 single-writer : seul l'Identity module mute, F-03) ; auto-persist `02 §6.3` ; conflit = server-wins + `updated_at` serveur (AD-7) — le client ne date JAMAIS ses mutations localement de manière à ce que le serveur écrase un `updated_at` plus ancien | AD-7 (adr-traceability l. 16) + 02 §6.3 |
| Miroir local (AD-12) | L'onboarding **n'exécute aucun run agent** (AD-12 : le kernel est serveur, jamais sur device, AD-3) — aucun `AgentRunState` ni job miroiré ici ; le thème (`UserContext.theme` v2 enum, AD-17) et les `user overrides` (AD-17, `theme-adapter.tsx` header) = couche UI **exclue** du miroir AD-7 (AD-7 ne couvre pas les UI preferences — WDS 04.1 §3 l. 75-76, OQ-11) ; le thème est persisté par le UI store (`persist` middleware, `05 §5.8` l. 3235), **pas** par PowerSync | AD-12 (adr-traceability l. 21) + `05 §5.8` + AD-17 |
| Dégradation AD-1 (offline) | L'onboarding n'a **aucune** feature cloud qui meurt : les 4 champs = saisie **100 % locale** ; le seul cas d'échec = l'**import de cours local** (upload R2, `05 §4.1.1 état error` : « import échoué — vous pouvez choisir plus tard ») — la matière reste choisisable **plus tard** (AD-1 : dégradation en entrée manuelle, catalog `learning.import` l. 33 : « degradation: manual entry (AD-1) ») ; l'onboarding **s'achève malgré l'échec** — on ne bloque jamais l'entrée dans l'app (AD-7) ; `Badge info` « importera à la connexion » (état offline, `05 §4.1.1`) ; le CTA « C'est parti » reste **actionnable** en offline (pas de serveur requis, AD-7) | AD-1 (catalog l. 33 + adr-traceability l. 10) + `05 §4.1.1` + AD-7 |
| Killed (G-M2, `05 §3.7` l. 1294-1300) | Le `kill-app` = un relaunch qui **part du miroir** (pas un nouvel état du moteur, pack 02 §11) ; les 3 slides sont **toujours** affichées (les champs sont locaux, AD-7) ; le CTA « C'est parti » reste **actionnable** ; si le PowerSync mirror est corrompu = bandeau fine « données locales, re-synchro requise » (WDS 04.1 §7 Error state) + CTA `Button primary` « Enregistrer localement » (re-persiste les 4 champs, AD-7) ; **jamais** d'écran blanc ni de reset (AD-7) | `05 §3.7` l. 1294-1300 + AD-7 + WDS 04.1 §7 |
| `feature-registry` (G-M7) | `identity.session` = core (catalog l. 84, modules/index.md §2) ; l'onboarding **n'apparaît pas** dans le `feature-registry` (pas de ligne, OQ-5 ouverte) — il est **toujours** actif ; un deep-link vers une feature désactivée = `feature-disabled` state (jamais un 404/crash, `docs/frontend/feature-registry.md` S6, apps/mobile/src/pages/not-found/index.tsx) ; **non applicable** ici : l'onboarding n'a pas de deep-link entrant | catalog l. 84 + feature-registry S6 + OQ-5 |

**Règle bloquante** (AD-7, WDS 04.1 §3 l. 75-76) : l'onboarding **fonctionne** en offline (tout est local) — les 4 champs G-D14 sont **toujours** saisissables et persistables, **jamais** de CTA qui disparaît en offline. Le seul élément qui **meurt** (killed) = la re-synchro du PowerSync mirror (WDS 04.1 §7) ; les 4 champs **restent** (re-lecture du miroir, AD-7).

**Killed** (G-M2, `05 §3.7` l. 1294-1300) : le `kill-app` = un relaunch qui part du **mirror** (pas un nouvel état du moteur) : les 3 slides sont re-lues localement (AD-7) ; le CTA « C'est parti » est **activé** (local, AD-7) ; le PowerSync mirror corrompu = bandeau fine + CTA « Enregistrer localement » (re-persiste, AD-7) ; **jamais** d'écran blanc ni de reset (AD-7).

### Subsection manquante — Dégradation AD-1 (catalog `learning.import` l. 33, sub-case du SSoT écran)

- **Sous-case AD-1 sur cet écran** (dégradation en entrée manuelle, catalog `learning.import` l. 33) : le seul flux cloud de l'onboarding = l'**import de cours local** (upload R2, `05 §4.1.1 état error`/`offline`) ; en offline (ou si le cours n'existe pas encore), la matière reste choisisable **manuellement plus tard** — les 4 champs `UserContext` ne portent **aucune** donnée d'import, ils sont 100 % saisie locale (AD-7). Le « cours » n'est **pas** un 5ᵉ champ G-D14 : il est couvert par le **défaut** du champ `disciplines` (chips S1) — c'est-à-dire l'entrée manuelle du métier, sans dépendre de l'import (AD-1, WDS 04.1 §3 l. 75-76). Le cas « cours local manquant / import échoué, matière non encore choisie » n'est couvert par **aucun SSoT écran explicite** (`05 §4.1.1` traite l'échec d'import en `error` **transitoire** « Réessayer » + `Badge info` « importera à la connexion » (§4a / §4c ci-dessus) mais **ne mentionne pas** la dégradation d'entrée manuelle du **catalog** `learning.import` l. 33) → **OQ-12** (ligne dédiée dans §14 : ouverte, pas de SSoT écran explicite — la SSoT unique = le **catalog** `learning.import` l. 33 + AD-1).

### Subsection manquante — Ce qui **vit** sur le miroir local (AD-7) vs ce qui **meurt** (killed)

| Ce qui **vit** sur le miroir local (AD-7, AD-12) | Ce qui **meurt** (killed, AD-7 / G-M2) |
|---|---|
| Les **4 champs `UserContext`** (`region`, `disciplines`, `professional_target`, `budget_constraint`, AD-15 SSoT) = PowerSync mirror SQLite (AD-7 single-writer : seul l'Identity module mute, F-03, catalog `identity.session` l. 84, modules/index.md §2) ; auto-persist `02 §6.3` ; conflit = **server-wins** + `updated_at` serveur (AD-7, adr-traceability l. 16) — le client ne date **jamais** ses mutations localement de manière à ce que le serveur écrase un `updated_at` plus ancien | La **re-synchro** du PowerSync mirror (WDS 04.1 §7 : « PowerSync mirror corrompu + re-synchro ») : si le mirror est corrompu, bandeau fine « données locales, re-synchro requise » + CTA `Button primary` « Enregistrer localement » (re-persiste les 4 champs, AD-7) — **jamais** d'écran blanc ni de reset (AD-7) |
| Le **thème** (`UserContext.theme` v2 enum, AD-17) et les **`user overrides`** (AD-17, `theme-adapter.tsx` header) = couche **UI**, **exclue** du miroir AD-7 (AD-7 ne couvre pas les UI preferences — WDS 04.1 §3 l. 75-76, OQ-11 du registre WDS) ; le thème est persisté par le **UI store** (`persist` middleware, `05 §5.8` l. 3235), **pas** par PowerSync — il « vit » donc **hors** du miroir AD-7/AD-12 (AD-12 : le kernel est serveur, jamais sur device, AD-3 ; aucun `AgentRunState` ni job miroiré sur l'onboarding — §12 l. 237) | Les **run agent** (AD-12, adr-traceability l. 21) : l'onboarding **n'exécute aucun run agent** (le kernel est serveur, jamais sur device, AD-3) ; en offline, tout ce qui dépend d'un run agent (ex. génération de QCM, retrieval) **meurt** sur cet écran — mais aucun de ces flux n'est présent sur l'onboarding (pas de streaming, pas de job, §4 l. 93 : « pas de flux mesurable avec résultat partiel sur l'onboarding ») ; le seul flux serveur synchrone au mount = **aucun** (§4 l. 108 : « local-first 100 % (AD-7, PowerSync mirror, WDS 04.1 §3) — aucun flux serveur synchrone au mount ; le seul flux serveur = la re-synchro différée de l'import cours local (05 §4.1.1 état offline) ») |
| (voir §12 l. 236 : Miroir local AD-7) ; (voir §12 l. 237 : Miroir local AD-12) | (voir §12 l. 239 : Killed) ; (voir §4 l. 108 : killed sur tout flux serveur) |


## 13. Logos S9 (ui-libraries §9 l. 349-369 — 4 fichiers SSoT : l. 357-360 ; monochrome §9.1 l. 371-405 ; C2PA §9.2 l. 407-418 ; AgentThinkingLoader §9.3 l. 420-487 ; forbidden : custom SVG decorations l. 141)

Règle ui-libraries S9 (l. 352-353) : **4 fichiers SSoT** au repo root — `aurora_logo_icon_d'affichage_l'applicaiton.png` (l. 357 : full, **externe UNIQUEMENT** — Capacitor, Play Store, splash, install ; **jamais** dans l'app UI), `aurora_icon_a_integre_dans_l'applciation.png` (l. 358 : coloré **sans fond**, header + centres de page + empty states + onboarding — la version in-app par défaut), `lg_aurora_vs_monochrome.png` (l. 359 : raster fallback/export), `vs_monochrome_en_svg.svg` (l. 360 : monochrome vector, in-app UNIQUEMENT). Ne JAMAIS redessiner / générer / détourner (l. 352-353, l. 390-392) ; pas de recolor (l. 368, l. 390-392) ; pas de fond derrière la version transparente (l. 367) ; le monochrome est interdit dans les états **vivants** (l. 390-392 : « le monochrome version in a 'living' empty state (primary CTA = active brand = colored) ») ; usage ad hoc interdit — chaque occurrence ci-dessous = version exacte + raison + SSoT ref.

| Occurrence | Version exacte | Raison (psychologie designer) | SSoT |
|---|---|---|---|
| Splash / boot avant `/onboarding` (WDS 04.1 §2 entrée 1) | **COLORED sans fond** (`aurora_icon_a_integre_dans_l'applciation.png`, l. 358) au **centre** de l'écran | S9 in-app default : « In-app splash / onboarding / Home / store = colored (or full, external) » (l. 362-363) ; l'onboarding **précède** les données (05 §4.1.1 : « `empty` n'existe pas ») → état vivant, marque **active** = coloré, pas monochrome (l. 390-392 : living empty state = colored) ; **pas** de fond derrière (l. 367 : « no background color behind the transparent version ») ; position = centre de page (S9 l. 358 : « page center ») | ui-libraries §9 l. 357-363 (SSoT 4 fichiers) ; l. 358 (in-app = coloré sans fond) ; §9.1 l. 388 (in-app splash / onboarding = colored) |
| Nocturne (défaut affiché, OQ-16, S3 preview) | **MONOCHROME** (`vs_monochrome_en_svg.svg`, l. 360, grayscale tonal #131B22 → #B9BABC, transparent bg UNIQUEMENT — l. 394-405) | §9.1 l. 384 : « Nocturne + High Contrast presets = monochrome » — universes désaturés / hautes-contrastes ; la version colorée est réservée aux **10 thèmes expressifs** (l. 384 : « the 10 expressive themes = colored version ») ; l'onboarding s'ouvre **Nocturne par défaut** (WDS 04.1 §6, OQ-16 : état émotionnel cible = rassurée, calme, sombre, l. 1 du §1) → marque **neutre / en attente** = monochrome (l. 375 : « brand present but not speaking ») ; pas de recolor (l. 392) ; le monochrome ne s'anime **jamais** ici (pas de §9.3 — pas d'`AgentThinkingLoader` sur l'onboarding, §4 : l'onboarding est sync, pas de run agent, AD-12) | ui-libraries §9.1 l. 378-388 (matrice : Nocturne/HC = monochrome, l. 384) ; l. 360 (SSoT SVG) ; l. 394-405 (grayscale TONAL #131B22 → #B9BABC, transparent bg ONLY) ; OQ-16 close (09/25) |
| Light (S3 preview, 2ᵉ colonne) | **COLORED sans fond** (`aurora_icon_a_integre_dans_l'applciation.png`, l. 358) | §9.1 l. 384 : « the 10 expressive themes = colored version » — Light = thème expressif (10 thèmes vivants, 05 §5.4 l. 3010/3032/3047) → marque **active** = colorée ; pas de fond (l. 367) ; pas de recolor (l. 392) | ui-libraries §9 l. 357-358 ; §9.1 l. 384 (10 expressifs = colored) |
| 404 / not-found (route inconnue / deep link vers l'onboarding, §4c ci-dessus) | **COLORED sans fond** (`aurora_icon_a_integre_dans_l'applciation.png`, l. 358), **au CENTRE** de la page (jamais monochrome) | §9.1 l. 387 : « 404 / not-found / feature-disabled (page center) = COLORED without-background, CENTERED » — état **vivant** (CTA primaire « Retour à l'accueil » actif) → marque **active** = colorée (l. 390-392 : monochrome **interdit** dans les états vivants) ; pas de fond (l. 367) ; jamais un 404 nu / crash (feature-registry S6, not-found/index.tsx) ; l'onboarding n'étant pas une feature désactivable (G-M7, OQ-5, catalog l. 84), la ligne « feature-disabled » de la matrice (l. 387) ne s'applique qu'au 404 de route inconnue ici | ui-libraries §9.1 l. 387 ; §9 l. 358 (in-app = coloré sans fond) ; §6.1 l. 202 (S6 404) ; §4c ci-dessus |
| Error state (`Callout danger` import cours, 05 §4.1.1 état error) | **Aucun** logo — `ic-alert-danger` (Ionicons `ic-{concept}-{variante}`, 05 §2.5 l. 287-308) + bordure `danger` | L'état error = **Callout inline** (05 §4.1.1 §6 : « `Alert` inline sur échec de cours local ») — **pas** d'`EmptyState` centré ; le logo S9 = centres de page / empty states (l. 358) — un Callout **n'est pas** un empty state (S6 l. 181 : error ≠ empty) ; l'icône danger est un **élément DS** (05 §3.3 l. 491), pas un logo (05 §2.5) ; **non applicable** : le monochrome « killed / disabled states (S6) » (l. 384) ne s'applique **pas** ici (l'onboarding n'est pas une surface killed — §4 : killed = re-synchro du mirror, pas un état S6 du Callout) | 05 §2.5 l. 287-308 (nomenclature icônes) ; 05 §4.1.1 DS états ; ui-libraries §9 l. 358 (logo = centres/empty, pas Callouts) |
| `Avatar` initiales (S1, 05 §4.1.1 DS) | **Aucun** logo — initiales (WDS 04.1 §6 : « [Icône profil, pas de logo lourd] ») | L'`Avatar` (05 §3.3 l. 491) = composant DS d'initiales — **jamais** un logo (WDS 04.1 §6) ; le logo lourd = `forbidden` sur un avatar (pas de recolor / redraw, S9 l. 352-353) ; l'avatar est **synchrone** (pas d'état) — le monochrome S6 (l. 384) ne s'applique pas | WDS 04.1 §6 ; 05 §3.3 l. 491 ; ui-libraries §9 l. 352-353 |
| CTA « C'est parti » (slide 3, 05 §4.1.1 footer) | **Aucun** logo — `Button primary` text-only (05 §3.1 l. 365) | Le CTA = `Button` DS (05 §3.1) — le logo n'est **pas** un composant de navigation (S9 l. 358 : logo = headers / centres / empty states / footer, **pas** dans les boutons) ; le monochrome S6 (l. 384 : « killed / disabled states ») ne s'applique pas (le CTA est **actionnable** en killed, §4 : pas de serveur requis, AD-7) | 05 §3.1 l. 365 ; ui-libraries §9 l. 357-360 |
| `IconButton` retour (slides 2–3, 05 §3.1 l. 365) | **Aucun** logo — `ic-arrow-back` (Ionicons `ic-{concept}-{variante}`, 05 §2.5 l. 287-308) | L'icône retour = **icône DS** (05 §2.5), pas un logo (S9 l. 358 : logo = brand, pas iconography) ; le monochrome S6 (l. 384) ne s'applique pas (pas d'état killed sur l'`IconButton`) | 05 §2.5 l. 287-308 ; 05 §3.1 l. 365 |
| **Jamais sur l'onboarding** | `aurora_logo_icon_d'affichage_l'applicaiton.png` (l. 357 : version **complète** avec fond = icône d'app **externe** UNIQUEMENT — Capacitor, Play Store, splash **externe**, install — **jamais** dans le UI de l'app UI, l. 357 : « NEVER inside the app UI ») ; pas de recolor (l. 392) ; pas de redraw / génération (l. 352-353) ; pas de fond coloré derrière le logo transparent (l. 367) ; le monochrome **interdit** dans un état vivant (l. 390-392) — l'onboarding n'a **aucun** état vivant avec CTA primaire au centre (pas de 404, pas de `EmptyState` vivant, 05 §4.1.1 : « `empty` n'existe pas ») | — | ui-libraries §9 l. 357, 367-368, 390-392, 352-353 |

**Règle bloquante** (ui-libraries §9.1 l. 390-392, S9 l. 352-353) : le logo **n'est jamais** redessiné / généré / détourné (l. 352-353) ; la version **complète** (fond) est **jamais** dans l'app UI (l. 357 : « NEVER inside the app UI ») ; le monochrome est **interdit** dans les états **vivants** (l. 390-392 : « living empty state (primary CTA = active brand = colored) ») ; **pas** de recolor (l. 368, l. 390-392) ; le monochrome ne s'anime **jamais** en dehors de §9.3 (l. 403-404 : « the only animated monochrome usage in the product = AgentThinkingLoader ») — l'onboarding **n'a pas** d'`AgentThinkingLoader` (pas de run agent, AD-12, §4) → le monochrome est **statique** partout sur cet écran.

## 14. Open questions

Chaque OQ : n° · écran · élément · question · options envisagées · décideur.

| N° | Écran | Élément | Question | Options envisagées | Décideur |
|---|---|---|---|---|---|
| **OQ-1** | S1 | `professional_target` (G-D14) | Le champ `professional_target` est-il capté sur l'écran 1, ou pré-rempli par inférence ? (05 §4.1.1 dit « 3 écrans max, 4 champs G-D14 » — répartition non explicitée) | A : pré-rempli par inférence (WDS OQ-1 option A close, 09/25, ratifié par Joy : « Bureau d'études BAC » inféré de `disciplines` + `region`, **3 écrans stricts**) ; B : 4ᵉ écran (NON COUVERT, interdit AD-14) | Close — WDS OQ-1 option A (09/25) |
| **OQ-2** | S3 | Thème Nocturne/Light | Le thème Nocturne est-il le **défaut affiché** sur l'écran 3 (preview 2 colonnes), ou le choix se fait dans /settings (S-30) et l'écran 3 n'existe pas (2 écrans seulement) ? (WDS OQ-2 option A close, 09/25) | A : écran 3 = thème seul (Nocturne/Light, 2 boutons, 2 min) (WDS OQ-2 option A close, 09/25, ratifié par Joy) ; B : écran 3 supprimé, thème dans /settings | Close — WDS OQ-2 option A (09/25) |
| **OQ-3** | CTA final | « C'est parti » (slide 3) | Le CTA redirige-t-il vers `/inbox` (S-23, WDS 04.2) ou vers `/home` (S-02, WDS 01.1) ? | A : `/inbox` (S-23, WDS 04.2) (WDS OQ-3 option B close, 09/25, ratifié par Joy : redirect vers `/inbox`, pas `/home`) ; B : `/home` (S-02) | Close — WDS OQ-3 option B (09/25) |
| **OQ-4** | Empty state (OQ) | 4 champs `UserContext` (AD-15 SSoT, 4 champs G-D14) | Si ré-édition depuis /settings (S-30, WDS 04.1 §2 entrée 2) avec `UserContext` **vide**, quel `EmptyState` afficher ? (05 §4.1.1 dit « `empty` n'existe pas » ; mais l'entrée 2 de WDS 04.1 §2 suppose `UserContext` déjà présent → `empty` non couvert) | A : `EmptyState` (05 §3.3 l. 491, 1 CTA max « Continuer ») ; B : 3 slides pré-remplies (valeurs par défaut) | Open — Design System team (05 §3.3 `EmptyState`) |
| **OQ-5** | Global | Offline / `feature-registry` (G-M7) | L'onboarding est-il activable via le `feature-registry` (G-M7, `NEEDS_DECISION`), ou est-il une fonction **core** (toujours active) ? (catalog l. 84 `identity.session` = core, modules/index.md §2 ; mais onboarding n'a pas de ligne dans le catalog) | A : fonction core (toujours active, `identity.session`, catalog l. 84) ; B : fonction désactivable (feature-registry G-M7) | Open — Product / Feature Registry (G-M7) |
| **OQ-6** | Empty state (si `UserContext` vide, OQ-4) | Logo S9 sur le `EmptyState` (05 §3.3 l. 491, 1 CTA max « Continuer ») | Si OQ-4 se résout en `EmptyState` (05 §3.3), quelle **version** du logo S9 ? S9 (ui-libraries l. 357-363) dit « empty state = COLORED sans fond » (marque active, état vivant) ; mais §9.1 l. 381 dit « Agent chat — new session / empty state = **monochrome** » (marque neutre, l'agent n'a pas encore parlé). L'onboarding **n'est pas** un agent chat — la matrice §9.1 **ne couvre pas** explicitement l'onboarding `EmptyState`. Le CTA « Continuer » est **primaire** (état vivant → S9 = colored, l. 357-358), mais l'absence de données = « brand present but not speaking » (§9.1 l. 375 → monochrome). **Conflit S9 vs §9.1 non résolu** | A : **COLORED** sans fond (`aurora_icon_a_integre_dans_l'applciation.png`, l. 358) — état vivant (CTA primaire actif), S9 default (l. 357-358 : « empty states = colored ») ; B : **MONOCHROME** statique (`vs_monochrome_en_svg.svg`, l. 360) — marque neutre (pas de données = « not speaking », §9.1 l. 375), aligné sur Nocturne (défaut, OQ-16) ; C : **Aucun** logo sur l'`EmptyState` (le composant `EmptyState` 05 §3.3 = icône DS + CTA, pas de logo S9 — le logo n'est réservé qu'aux **centres de page** S9, pas aux `EmptyState` inline) | Open — Design System owner (ui-libraries §9 l. 357-363 + §9.1 l. 371-405 ; 05 §3.3 l. 491 ; SSoT manquante : aucune ligne dans la matrice §9.1 pour « onboarding EmptyState ») |
| **OQ-7** | Global (loading, §4a) | Texte exact du `Skeleton` loading (3 lignes, ~300 ms) | La SSoT est **muette sur le texte** du loading : WDS 04.1 §7 Loading = « — » et ui-libraries §6 S6 l. 180 définit le `Skeleton` (composant) mais pas un texte pour l'onboarding (05 §4.1.1 n'a pas de texte de loading) | A : aucun texte, skeleton muet (conforme WDS 04.1 §7 « — ») ; B : texte `sr-only` stable (« Chargement de votre profil… », SSoT du label manquant) ; C : libellé visible `text-secondary` 1 ligne « Chargement… » (invention SSoT) | Open — Design System team (ui-libraries §6 l. 180 ; WDS 04.1 §7) |
| **OQ-8** | Global (§1 l. 16) | Budgets NFR « JS ≤ 300 Ko gz, TTI ≤ 1,5 s, 30 fps » cités ici comme **OQ-11** (registre WDS) | L'OQ-11 est définie dans la base WDS (`_bmad-output/wds/C-UX-Scenarios/04.1 §10 : Pixel 4a OQ-11`) et **n'a pas de ligne dans ce §14** — registre écran muet sur sa traçabilité locale | A : porter la ligne OQ-11 (budgets) dans le registre global `_open-questions.md` sans dupliquer ici ; B : rattacher ici comme OQ-8 close (valeurs déjà ratifiées WDS 04.1 §10, 09/25) ; C : ouvrir comme question écran (réévaluation des budgets si le bundle onboarding dépasse 300 Ko gz) | Open — Product / Perf (OQ-11 WDS 04.1 §10) |
| **OQ-9** | S3 / Global (§1 l. 19, §13) | Nocturne comme **thème par défaut affiché** (citée ici comme **OQ-16**, registre WDS) | L'OQ-16 est définie dans la base WDS (OQ-16 Nocturne par défaut, 09/25 — WDS 04.1 §3/§10, close) et **n'a pas de ligne dans ce §14** ; le SSoT écran (05 §5.5 l. 3153) rattache le preset Nocturne à l'onboarding sans fixer le **défaut d'ouverture** | A : Nocturne = défaut affiché S3 + défaut d'ouverture (WDS 04.1 §6, 09/25, close) ; B : le défaut d'ouverture est un choix /settings (S-30) et S3 ne surligne aucun preset par défaut (conflit avec l'état émotionnel cible « sombre, 22 h », §1) | Open — Design System team (05 §5.5 l. 3153 + WDS 04.1 §6 OQ-16) |
| **OQ-10** | Global (§5 l. 128, §10 l. 206) | `Local Adaptation` (`FocusThemeAdapter`) appliquée à l'onboarding (citée ici comme **OQ-15**, registre WDS) | L'OQ-15 est close en **V1 = Focus screen ONLY** (apps/mobile/src/ux/theme-adapter.tsx, OQ-15) et **n'a pas de ligne dans ce §14** ; l'onboarding exclut le `FocusThemeAdapter` (§10 l. 206-208) mais la SSoT écran ne documente pas explicitement le **cas Focus Mode actif pendant l'onboarding** (§5 l. 128 = « si activé sur l'écran ») | A : Focus Mode non atteignable pendant l'onboarding (pas de screen Focus, §5 l. 128 N/A) ; B : Focus Mode activable (mode global du store) → atténuation des animations secondaires via `[data-focus-mode]` (05 §2.6 règle 3) même sur l'onboarding, `FocusThemeAdapter` restant Focus-screen-only (OQ-15 V1) | Open — Design System team (OQ-15 WDS/theme-adapter + 05 §2.6 règle 3) |
| **OQ-12** | Global (§12 l. 246) | Dégradation AD-1 (catalog `learning.import` l. 33 : « degradation: manual entry (AD-1) ») sous-case « cours local manquant / import échoué, matière non encore choisie » | `05 §4.1.1` traite l'échec d'import en `error` **transitoire** (« Réessayer ») + `Badge info` « importera à la connexion » (état offline, §4a/§4c) mais **ne mentionne pas** la dégradation **d'entrée manuelle** du **catalog** `learning.import` l. 33 — le SSoT écran est **muette** sur ce sous-case ; la SSoT catalog (AD-1) est la seule source, pas de SSoT écran explicite | A : adosser le sous-case au **défaut** du champ `disciplines` (chips S1, entrée manuelle du métier, sans dépendre de l'import — AD-1, WDS 04.1 §3 l. 75-76) ; B : ouvrir une entrée **manuelle** dédiée (bouton « Choisir manuellement plus tard », 05 §3.1) distincte des chips ; C : laisser le `Badge info` « importera à la connexion » + `Réessayer` couvrir le cas (pas de dégradation d'entrée manuelle, l'import est le seul chemin) | Open — Product / Design System team (catalog `learning.import` l. 33 + AD-1 adr-traceability l. 10 + `05 §4.1.1` état error/offline) |
| **OQ-11** | §4a (ligne `error`, SSoT « verbatim ») | Texte exact du `Callout danger` sur échec d'import cours local | Le mot-à-mot « import échoué — vous pouvez choisir plus tard » est cité dans ce doc comme SSoT verbatim 05 §4.1.1 état error — **factice** : la SSoT (05 l. 1345-1348) ne donne aucun texte exact, seulement le sens (la matière **peut** être choisie plus tard, l'onboarding **s'achève** malgré l'échec, on ne bloque pas l'entrée, AD-7) ; WDS 04.1 §7 n'a pas de ligne S6 `error` import-échoué (sa ligne `Error` = le bandeau mirror corrompu « Connexion instable — les données sont enregistrées localement ») | A : `Callout danger` « Import du cours échoué — vous pouvez choisir la matière plus tard » + `Button secondary` « Réessayer » (sens SSoT, libellé proposé) ; B : `Callout danger` « Impossible d'importer le cours — vous pourrez le choisir plus tard dans /settings » ; C : laisser le libellé = spéc DRAFT jusqu'à ratification (pas de SSoT explicite) | Open — Design System team (05 §4.1.1 l. 1345-1348 ; WDS 04.1 §7 ; S6 `error`, ui-libraries §6 l. 181) |
| **OQ-13** | Global (§4a ligne `success`) | Texte exact du `Toast success` après CTA « C'est parti » (slide 3) | Le mot-à-mot « Profil enregistré ✓ » est cité dans ce doc comme SSoT (05 §4.1.1 DS états + WDS 04.1 §7) — **factice** : 05 §4.1.1 (l. 1343-1351) n'a **pas de ligne `success`** (seulement loading/empty/error/offline) ; WDS 04.1 §7 (Page States) n'a **pas de ligne S6 `success`** (Default/Loading/Empty/Error/Offline) — le sens SSoT = confirmation transitoire du profil `UserContext` persisté (S6 `success` = `Toast` 3 s auto-dismiss, ui-libraries §6 l. 183), mais **aucun texte exact n'est verbatim dans la SSoT** → texte du `Toast` = OQ | A : `Toast` « Profil enregistré ✓ » (libellé proposé, S6 l. 183) ; B : `Toast` « C'est parti » minimal sans checkmark, texte vide (la confirmation = le redirect vers `/inbox` lui-même) ; C : laisser le libellé = spéc DRAFT jusqu'à ratification (pas de SSoT explicite) | Open — Design System team (05 §4.1.1 l. 1343-1351 ; WDS 04.1 §7 ; S6 `success`, ui-libraries §6 l. 183) |
| **OQ-14** | §4a ligne `killed` (bandeau + CTA, mirror corrompu) | Textes exacts du bandeau fine et du CTA sur l'état `killed` (PowerSync mirror corrompu) | Les libellés « données locales, re-synchro requise » (bandeau) et « Enregistrer localement » (CTA) sont cités dans ce doc comme WDS 04.1 §7 — **factice** : WDS 04.1 §7 ne donne que la ligne `Error` verbatim « Connexion instable — les données sont enregistrées localement » + Actions « Tap CTA → persiste localement, re-sync au retour réseau » (sans libellé de CTA) ; 05 §3.7 l. 1290-1301 (matrice AD-13) donne le bandeau killed verbatim = « Reconnexion… » (DS fine) ; **05 §4.1.1 n'a pas d'état `killed`** (seulement loading/empty/error/offline) → texte du bandeau + CTA = OQ | A : bandeau verbatim 05 §3.7 « Reconnexion… » + CTA « C'est parti » inchangé (le CTA reste le CTA standard, pas un CTA dédié) ; B : bandeau verbatim WDS 04.1 §7 « Connexion instable — les données sont enregistrées localement » + CTA proposé « Enregistrer localement » (sens WDS Actions, libellé proposé) ; C : laisser les libellés = spéc DRAFT jusqu'à ratification (pas de SSoT explicite) | Open — Design System team (05 §3.7 l. 1290-1301 ; WDS 04.1 §7 ; S6 `killed`, ui-libraries §6 l. 185) |

Note : les OQ-1 à OQ-3 = **close** (ratifiées 09/25 par Joy, WDS 04.1 §8) — documentées ici pour
traçabilité. Les OQ-4, OQ-5, OQ-6, OQ-7, OQ-8, OQ-9, OQ-10, OQ-11, OQ-12, OQ-13 et OQ-14 = **ouvertes** (pas de
SSoT explicite, OQ dans le sens du prompt : « Pas de SSoT = ligne OQ-<n> dans §14 »). Les numéros
OQ-11 et OQ-15 correspondent à des entrées du **registre WDS global** (OQ-11 = budgets NFR,
OQ-15 = `FocusThemeAdapter` V1 = Focus-only) ; l'**OQ-11 écran** (ci-dessus, §4a ligne `error`)
= texte exact du `Callout danger` import-échoué (SSoT verbatim manquante) — **distinct** de l'OQ-11
budgets du registre WDS (référencé par l'OQ-8 ci-dessus) ; OQ-15 n'a pas de ligne dédiée ici (l'OQ-10
la référence). L'**OQ-13** = texte exact du `Toast success` (ligne `success` §4a) — SSoT muette
(sans ligne `success`), libellé proposé « Profil enregistré ✓ » non verbatim. L'**OQ-14** = textes exacts
du bandeau + CTA sur l'état `killed` (ligne `killed` §4a) — SSoT muette sur les libellés exacts
(05 §3.7 verbatim = « Reconnexion… » ; WDS 04.1 §7 verbatim = « Connexion instable — les données
sont enregistrées localement »), libellés proposés non verbatim.
