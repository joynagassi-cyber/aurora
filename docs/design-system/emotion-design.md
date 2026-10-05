# Aurora — Emotion Design

**Statut** : proposition normative (au-dessus de `DESIGNED_NOT_IMPLEMENTED`).
**Autorité** : direction « Technical Calm » (05 §1), tokens AD-17 (05 §2.1, G-H2 re-2026-10),
focus-mode spec (S4/S8, DPC v1.8), catalog des sons `apps/mobile/src/lib/focus-sounds.ts`,
polish layer `apps/mobile/src/ux/motion.tsx @aurora/ui`.
**Règle bloquante reprise** : un thème expressif ne redéfinit **jamais**
`success`/`warning`/`danger`/`info` (05 §5.1) — les états sémantiques sont gelés
dans `packages/ui/src/themes/neutral.ts`. Ce document assigne des **états émotionnels**
aux états sémantiques ; il n'invente aucune valeur brute (AD-17 : zéro valeur hors token).

---

## 1. Enregistre & ton émotionnel

### 1.1 Contrat émotionnel global

Aurora ne crée pas l'excitation ; elle crée **l'intensité calme** (*quiet
intensity*). Trois piliers :

| Pilier | Ce que le ressentit l'utilisateur | Ce que le design fait |
|---|---|---|
| **Fiabilité** (AD-7 offline-first) | « Même sans réseau, rien ne casse. » | Le Focus est 100 % local ; le timer est basé sur l'horloge système ; le kill **ne perd rien** (04 §6.1). |
| **Immersion** | « Je suis dedans, pas dessus. » | Chrome retiré sur `/focus` (pas de TopBar, BottomNav masqué, 05 §4.4.2) ; un seul CTA par écran (AD-14). |
| **Reconnaissance discrète** | « Le travail est vu, sans fanfare. » | Bilan de session (`FocusSessionBilan`) = confirmation silencieuse ; pas de confettis, pas de « GREAT JOB ». |

Le registre est **factuel, second personne, présent de l'indicatif** : « Votre session
de 25 minutes est terminée. 0 interruption. » Jamais d'exclamation, jamais d'emoji
(05 §2.5 : Lucide uniquement, pas d'emoji, pas de custom SVG).

### 1.2 Matrice moment → émotion ciblée

| Moment | Émotion cible | Ton | Support (couleur / son / motion) |
|---|---|---|---|
| **Onboarding (première ouverture)** | Sérénité + compétence tranquille (« on ne va pas me submerger ») | Accueillant, sobre | `bg #FFFFFF` ; accent `aurora #3678F6` pour les seuls CTA ; micro-motion 200ms ; son : silence (pas de musique d'accueil). |
| **Focus : pré-session (wind-down)** | Ancrage, anticipation calme | Neutre → attention douce | Badge `accent-primary` (en-cours) ; `NodePulse` 1.5s breath sur le ring avant démarrage ; son optionnel : thème *Nature* ou *Bruit blanc* en fondu. |
| **Focus : actif** | Immersion, stabilité (« le monde s'est tu ») | Silencieux, préeminent | Ring 160px préeminent ; animations atténuées (règle 3, 05 §2.6) ; toasts **déférés** à la fin ; son de fond choisi par l'utilisateur (5 thèmes, §4). |
| **Focus : fin (bilan)** | Soulagement + fierté discrète | Positif sans célébration | `success #10B981` (le repos est vert, 05 §3.6.9 : « le rouge est réservé au danger ») ; BottomSheet 250ms easeOut ; un seul son ponctuel doux (§4.3). |
| **Objectif atteint** | Confirmation solide, « acquis, pas gagné » | Direct, sec | `success` + `success-surface #E8FAF0` ; remplissage de barre 600ms ; son ponctuel de type *solara* (§4.3) — **pas** de boucle. |
| **Objectif non atteint / jalon manqué** | Reconnaissance non-punitrice (« c'est noté, on continue ») | Neutre, pas de blâme | `warning #F59E0B` si retard léger ; `danger #EF4444` **uniquement** si l'objectif est réellement cassé (deadline dépassée, rupture de série) — jamais de rouge pour un simple « pas encore ». |
| **Notification locale (deadline)** | Attention ponctuelle | Brève, informative | `info #0EA5E9` dans l'UI app ; son : **short chime** (§4.2) ; pas de vibration agressive. |
| **Notification distante (OneSignal : coach / job)** | Surprise calme, « l'agent a travaillé pour moi » | Neutre-chaleur | `info` ; chime **différent** de la deadline locale (§4.2, 2 motifs pour ne pas mélanger) ; si Focus actif → **supprimée** (S8, `reduceForFocus`). |
| **Erreur / échec d'opération** | Conscience, pas de honte | Calme, orienté action | `danger #EF4444` + `danger-surface` ; Callout **sous** le timer, timer continue (05 §4.4.2 : « le bilan est un bonus, pas le sujet ») ; **pas de son** (§4.4) ; CTA « Réessayer ». |
| **Hors ligne** | Neutralité (« rien ne change ») | Apaisant | Badge `warning` (S6 : « Offline ») ; le Focus reste parfaitement fonctionnel ; jamais de « PANIQUE, PAS DE RÉSEAU ». |
| **Reconnexion** | Soulagement discret | Factuel | Toast 3s (`success` si resync OK) ; aucun son si on est en Focus actif. |
| **Check-in coach (agent)** | Intéraction humaine déléguée, « quelqu'un me suit » | Chaleur mesurée, jamais de surjouer | Carte agent (`agent.css`), loader organique 3-blobs (ui-libraries §9.3, **pas** three-dot) ; ton de la voix : §5.3. |
| **App au repos / ambiant (Home)** | Clairté tranquille (« que compte-t-il maintenant ? ») | Neutre, rassurant | Home = réponse à *« What matters now? »* (AD-14) ; `NodePulse` **désactivé** (les nœuds secondaires restent statiques, motion.tsx @aurora/ui) ; animation ambiante : **aucune** par défaut (§3.4). |

### 1.3 Règle de hiérarchie émotionnelle

```
danger  >  warning  >  success  >  info  >  accent  >  neutre
 1       2          3         4      5        6
```

Un écran n'affiche **jamais** `danger` et `success` au même endroit sans raison
(contradiction = perte de confiance). En Focus, `success` n'apparaît qu'à la fin
(bilan) ; pendant la session, le seul signal positif en cours = l'avancement du ring
(`accent-primary`).

---

## 2. Couleur & lumière — mapping état émotionnel → token

Tous les hex ci-dessous sont les valeurs **gelées** de `neutral.ts` / `tokens.css`
(G-H2 re-2026-10 : canvas clair `#FFFFFF`, canvas sombre `#121212` — pas de teinte,
pas de dégradé sur le canvas).

### 2.1 Échelles émotionnelles (clair, défaut « blanc-par-défaut »)

| Émotion | Hue | Token | Hex (light) | Hex (dark) | Usage émotionnel |
|---|---|---|---|---|---|
| **Calme** (détente, repos, break) | vert-émeraude, S ~84 %, L 39–53 % | `--aurora-success` / `-surface` | `#10B981` / `#E8FAF0` | `#34D399` / `#064E3B` | Breaks, bilan de focus, repos entre pomodoros. « Le vert = le monde va bien. » |
| **Alerte** (attention, retard, hors ligne) | ambre, S ~92 %, L 50 % | `--aurora-warning` / `-surface` | `#F59E0B` / `#FFF4E0` | `#FBBF24` / `#7C3A08` | Badges « Offline », deadlines proches, jalons en danger. Jamais de flash. |
| **Réussite** (objectif atteint, série maintenue) | vert maîtrisé (nœud `mastered`) | `--aurora-node-mastered` / habit `strong` | `#10B981` / `#4F5AE8` | `#34D399` / `#9AA4F4` | Nœuds maîtrisés du tree, séries fortes. La série **forte** est indigo, pas verte : « solide », pas « euphorique ». |
| **Focus** (immersion, en-cours) | bleu, S ~91 %, L 59 % | `--aurora-accent-primary` | `#3678F6` | (thème actif) | Ring de timer, CTA unique, nœuds en-cours. Le bleu = « ici, maintenant ». |
| **Erreur** (échec terminal non-retryable) | rouge, S ~84 %, L 60 % | `--aurora-danger` / `-surface` | `#EF4444` / `#FEECEC` | `#F87171` / `#7F1D1D` | Échec de bilan, rupture de série, deadline dépassée. **Réservé** — « le rouge est réservé au danger » (05 §3.6.9). |
| **Info** (nouveauté, changement de capacité) | ciel, S ~89 %, L 48 % | `--aurora-info` | `#0EA5E9` | `#38BDF8` | Callouts « réduction des notifications active », reconnexion. |

Règle bloquante 05 §5.1 : ces six couples sont **thème-indépendants**. Les 10 thèmes
expressifs (Aurora, Lagoon, Boreal, Sakura, Vesper, Solara, Terra, Verdant, Citrus,
Cosmos) modifient uniquement les accents (`primary`/`secondary`/`punctual`) — un PR qui
retouche `success` dans un thème JSON est rejeté.

### 2.2 Dégradation émotionnelle des séries d'habitude (`habit-*`)

| État | Light | Dark | Émotion |
|---|---|---|---|
| `habit-weak` | `#E2E8F0` (gris neutre) | `#25282F` | « Fragile » — pas de jugement, couleur quasi-invisible. |
| `habit-med` | `#9AA4F4` (indigo doux) | `#818CF8` | « En construction » — une teinte, pas une alarme. |
| `habit-strong` | `#4F5AE8` (indigo plein) | `#9AA4F4` | « Solide » — la seule couleur de série autorisée à être saturée. |

Un état « oublié » n'est **jamais** affiché en `danger` : c'est `habit-weak`
(repartir est facile), pas `#EF4444` (qui impliquerait que l'utilisateur a échoué).

### 2.3 Bascule fond : normal ↔ focus mode

| Contexte | Canvas | Surfaces | Raison émotionnelle |
|---|---|---|---|
| **Normal (Home, Goals, Skills)** | `#FFFFFF` (light) / `#121212` (dark) | `surface #FFFFFF` / `surface-alt #F8FAFC` | Neutre, « tout est disponible ». |
| **Focus actif** | idem (le canvas **ne change pas** — G-H2 : le canvas ne se teinte jamais) | `surface-overlay` pour les toasts différés ; ring = `accent-primary` sur `surface-alt` | L'immersion vient du **chrome retiré** (navigation masquée), pas d'un changement de fond. Changer le fond en focus = distraction. |
| **Focus + thème Lagoon (recommandé, 05 §5.4.2)** | idem | accents `#007C91`/`#18B7A0`/`#50D8C0` ; motionMood « très fluide, lent (400ms, spring doux) » | Lagoon est le thème **contextuel** du Focus : « lecture, concentration, habitudes/routines ». |
| **Focus nocturne (preset Nocturne)** | `#121212` | surfaces plus foncées (`#1E2026`/`#25282F`), accents **désaturés** (05 §5.5) | Concentration de nuit : accents baissés en saturation pour ne pas stimuler ; `success`/`danger` restent lisibles (dark nuance 400+, §6.3). |

Règle `Local Adaptation` (05 §5.2, OQ-15 tranché V1) : le Focus est le **seul** écran
avec adaptation locale — surfaces secondaires atténuées (nœuds à 40 %), focus ring
renforcé ; le ring **ne** s'atténue jamais (il est le sujet).

### 2.4 Registre « nuit » (dark / Nocturne)

- Canvas `#121212` pur — pas de teinte bleue (G-H2 re-2026-10 : le `#0A0E1A`
  déprécié est banni).
- Émotion : **retrait**, pas « thème sombre = gaming ». Les accents expressifs
  passent en nuance 400–500 (ex. `success #34D399`, `warning #FBBF24`) : plus clairs
  pour le contraste, jamais plus saturés.
- Le Vesper (`#6554C0` → indigo/violet/magenta, motionMood « lent, contemplatif
  400–600ms ease-in-out ») est le thème nocturne **recommandé** pour les revues
  hebdo/mensuelles et le journal des décisions — contemplatif, pas stimulant.

---

## 3. Motion & timing

Référentiels existants (motion.tsx @aurora/ui, DS 05 §2.6) : `PAGE_TRANSITION` 200ms easeOut
(`y: 8 → 0`), `REVEAL` 250ms, `NodePulse` breath 1.5s easeInOut (scale 1 → 1.04 → 1,
le **seul** emphease animé du Focus), Skeleton pulse opacity 0.6 → 1 / 1.2s.
Règle 2 **obligatoire** : `prefers-reduced-motion` → tout passe à l'instantané (0ms).

### 3.1 Table moment → durée / easing / amplitude

| Moment | Durée | Easing | Amplitude / détails | Raison |
|---|---|---|---|---|
| **Notification d'apparition (in-app toast)** | 250ms entrée | `easeOut` (cubique `cubic-bezier(0,0,0.2,1)`) | `y: 12 → 0` + opacity ; sort : `opacity → 0` 200ms, 3s affiché | Toast = information brève, pas d'effet « pop ». |
| **Notification système (shading Android)** | N/A (OS) | — | Le design de l'app ne contrôle pas l'OS ; mais **le son associé** doit rester discret (§4.2). | L'intrusivité perçue vient du son + vibration, pas de la motion. |
| **Countdown du timer focus** | **Aucune animation par seconde** | — | Le temps restant = `tabular-nums` JetBrains Mono 3xl, **stable** (05 §2.2 : pas de jitter) ; seul le `ProgressRing` se remplit, `easeOut` sur l'arc (déterminé, 05 §3.3 l.577-581). | « Les données ne s'animent jamais » (05 §2.6 règle 1) — le chiffre est la vérité, pas un effet. |
| **Remplissage barre de progression (objectif)** | 600ms | `cubic-bezier(0.22,1,0.36,1)` (easeOut « luxe ») | De 0 → X % en un seul geste ; pas d'incrément par palier visible sauf si < 5 s. | La récompision est fluide ; un fill « robotique » (steps) = méchant. |
| **Transition entre écrans** | 200ms | `easeOut` | `PAGE_TRANSITION` exact ; en Focus actif → **instantané** (règle 3, 05 §2.6 l.323-324 : fast → 0ms). | On ne quitte pas une immersion avec un glide. |
| **Ouverture BottomSheet bilan** | 250ms | `easeOut` | Slide-up `y: 100 % → 0`, shadow.4, focus-trap ; reduced-motion = affichage sans animation. | Le bilan **précède** le retour au Home ; l'ouverture doit être posée, pas bondissante. |
| **NodePulse (nœud actif)** | 1.5s × 2 cycles | `easeInOut` | scale 1 → 1.04 → 1 (4 % max) ; **seul** emphease animé autorisé. | Le pulse = « ce nœud vit » ; 4 % = à peine visible, intentionnel (calme). |
| **Animation d'ambiance (fond)** | 1.5s « breath » | `easeInOut` | **Uniquement** sur le Focus (`NodePulse`) ; sur Home : **aucune animation de fond par défaut** (les nœuds secondaires restent statiques, motion.tsx @aurora/ui). L'animation ambiante optionnelle (thème Cosmos : particules douces 300ms spring) est **opt-in** dans les settings. | « Un écran qui respire concentre » — mais un fond qui bouge tout le temps = agitation. |

### 3.2 Hiérarchie temporelle (à retenir)

```
interactif  : 150ms fast   (SegmentedControl, Slider, press scale 0.95)
navigation  : 200ms normal (PAGE_TRANSITION)
surfaces    : 250ms normal (BottomSheet, toasts)
ambiant     : 400–600ms lent (motionMood thème, opt-in)
timer/chiffres: 0ms (jamais)
```

### 3.3 focusMode = mode motion atténué (05 §2.6 règle 3)

`[data-focus-mode="true"]` (aurora.css l.120-122) : animations `slow` **désactivées**
(pas de 400ms sur cet écran), toasts/snickers **déférés** (jamais pendant le
pomodoro, affichés à la fin), transitions de page `fast` → `instant`. En pratique :
l'écran du Focus **ne bouge plus que par le timer** — c'est la motion la plus calme
de l'app, par construction.

---

## 4. Design sonore

### 4.1 Les 25 sons de concentration (5 thèmes) — mapping cas d'usage

Catalogue `focus-sounds.ts` (AD-15, ids stables = clé du tool kernel `focus.sound`) :

| Thème (id) | Sons (ids) | Usage émotionnel recommandé |
|---|---|---|
| **Nature** (`nature`) | `rain-gentle` · `forest-night` · `river-birds` · `ocean-waves` · `tropical-beach` | **Pré-session & breaks** — le passage « je m'arrête » vers « je reviens » ; `forest-night` et `ocean-waves` pour les sessions nocturnes (preset Nocturne). |
| **Bruit blanc** (`bruit-blanc`) | `white-noise` · `cabin-brown-noise` · `rain-steady` · `fireflies` · `wind-light` | **Focus long (≥ 45 min)** — le bruit brun (`cabin-brown-noise`) = le plus « couvrant », idéal pour couper les bruits ambiants (bureaux ouverts, logement bruyant) ; `rain-steady` en boucle = le fond par défaut si l'utilisateur ne choisit rien d'autre. |
| **Ambiance** (`ambiance`) | `cafe-bossa` · `cafe-rain-window` · `lofi-dreamscape` · `lofi-chill` · `chill-relax` | **Travail créatif / étude légère** — « le café sous la pluie » = le son d'« on est dehors du monde mais pas seul ». `chill-relax` pour la fin de journée. |
| **Lointain** (`lointain`) | `space-drone` · `ambient-classics` · `midnight-radio` · `calm-radio` · `zen-radio` | **Revue / contemplation (Vesper)** — les drones pour le journal des décisions, `zen-radio` pour la méditation de fin de session. |
| **Musique** (`musique`) | `lofi-mellow` · `lofi-sunbeam` · `lofi-soochrys` + « Lundi doux » ×2 | **Sessions rythmées (Citrus)** — le seul thème avec du tempo ; réservé aux objectifs « vifs » (revisions, sprints courts). Ne jamais proposer par défaut sur une session de contemplation. |

Règle d'or : **le son de fond est toujours un choix utilisateur, jamais un
défaut imposé** ; le défaut silencieux est légitime (05 §4.4.2 : le Focus est un
réducteur de distracteur, pas un nouvel audio).

### 4.2 Sons d'événement (non-fonds)

| Événement | Son | Spéc | Raison |
|---|---|---|---|
| **Deadline locale (Capacitor `scheduleLocal`)** | `chime-local` (à créer, 1200ms) : 2 notes descendantes douces, ~500 Hz, sans pic (envelope attack ≥ 80ms) | Volume ≤ 40 % du max système, pas de vibration longue (1 vibration courte) | « Rappel » ≠ « alarme ». Le motif **descendant** = « c'est passé, regardez ». |
| **Événement distant OneSignal (coach / job complété / nudge proactif)** | `chime-remote` (à créer, 1000ms) : 3 notes montantes espacées, ~400 Hz | Même volume ; motif **montant** = « quelque chose est arrivé de l'extérieur » | Deux motifs **inécoutables** pour ne pas mélanger local/réseau (pack 04 §3.4 : jamais les deux sur le même objet) — et si l'utilisateur apprend la différence, il peut muer l'un sans l'autre. |
| **Fin de focus (bilan OK)** | `focus-end` (1500ms) : une note unique, ~660 Hz, decay lent | Jouée **après** l'ouverture du BottomSheet, jamais avant (le bilan précède le retour, 05 §4.4.2) | La note unique = « terminé » ; pas de fanfare. |
| **Objectif atteint (jalon)** | `goal-hit` (800ms) : 2 notes montées (quinte), ~523 + 659 Hz | Une seule fois par jalon ; **jamais** en boucle, jamais sur un jalon mineur | La récompision sonore doit être rare pour rester significative. |
| **Erreur / échec** | **Silence** (§4.4) | — | Le son d'erreur est l'anti-pattern par excellence (§7). |
| **Reconnexion** | **Silence** (uniquement toast visuel 3s) | — | Le soulagement se lit, ne se chante pas. |
| **Check-in coach (agent termine de répondre)** | *Optionnel* : micro-tick 120ms (≤ 200 Hz, à -18 dB) | Jamais de « ding d'assistant IA » type notification commerciale | Le tick dit « c'est prêt », rien d'autre. |

Livrables sonores à produire (outils `focus.sound` kernel, ids stables AD-15) :
`chime-local`, `chime-remote`, `focus-end`, `goal-hit` (4 fichiers 44.1 kHz, ≤ 2s,
licences CC/domaine public comme le reste du catalogue).

### 4.3 Réduction sonore pendant le Focus (S8, `reduceForFocus`)

- Les **sons d'événement** sont mutés (pas joués) pendant une session : la
  notification est **différée** à la fin (règle 3 : toasts différés), le chime est
  joué **uniquement** si l'utilisateur a explicitement activé « sons même en Focus »
  (setting optionnel, défaut OFF).
- Le son de fond **continue** s'il a été lancé avant la session (c'est LE
  distracteur que l'utilisateur veut garder) ; si la session est lancée **sans**
  son, aucun son ne démarre automatiquement.
- Les notifications des apps blocklistées (DPC v1.8 : `setPackagesSuspended`) sont
  masquées **par le système** — plus de contrôle son possible, c'est un effet
  système, pas un son d'Aurora.

### 4.4 Silence = règle d'erreur

Tous les états `danger` (échec de bilan, rupture de série, échéance manquée) sont
**silencieux**. Raison : le rouge + un son alarmant = punition ; le rouge **seul**,
accompagné d'un CTA « Réessayer », = information. L'utilisateur doit pouvoir rester
dans une salle de réunion et voir une erreur sans que le téléphone « sonne le
drame ».

---

## 5. Microcopy / voix

### 5.1 Règles de voix (globales)

1. **Second personne, présent** ; phrases ≤ 12 mots.
2. **Zéro exclamation** (sauf 1 usage : le premier objectif atteint de la semaine,
   et encore — on évite). Zéro emoji. Zéro « super ! » / « génial ! ».
3. **Les chiffres en JetBrains Mono** dans le corps de notification quand c'est une
   donnée (durées, scores) — cohérent avec le DS.
4. Le coach parle **à la première personne du pluriel (« on »)** ou à la deuxième
   personne directe (« vous ») — **jamais** le tutoiame, jamais « je sais que vous
   pouvez ! ».
5. L'erreur s'exprime **au passif neutre**, jamais à la faute de l'utilisateur :
   « Le bilan n'a pas pu être généré » (OQ-03 b) — pas « Vous avez raté le bilan ».

### 5.2 Notifications — titres / corps par type d'événement

| Type | Source | Titre | Corps | Son |
|---|---|---|---|---|
| **Deadline locale** (tâche/focus à échéance) | Capacitor local | `Échéance — {tâche}` | « {tâche} est due à {heure}. {optionnel : "Session de 25 min prévue."} » | `chime-local` |
| **Focus : fin de session** | Timer système | `Session de focus terminée` | « {minutes} min. {n} interruption(s). Bilan disponible dans Aurora. » | `focus-end` (si setting ON) |
| **Check-in coach** | OneSignal (agent) | `Coach — {sujet court}` | « Une revue courte est prête pour "{objectif}". 2 questions. » | `chime-remote` |
| **Job complété (agent)** | OneSignal | `Aurora a terminé : {job}` | « {job} a été exécuté. {1 ligne de résultat factuel, ex. "3 tâches archivées."} » | `chime-remote` |
| **Nudge proactif** | OneSignal | `Rappel discret` | « Vous n'avez pas fait de session cette semaine. Une de 25 min ? » — **un seul** nudge/semaine par catégorie (anti-spam, §7) | **silence** (nudge = visuel) |
| **Série d'habitude interrompue** | Local | `Série : {habitude}` | « La série est à {n}. Reprendre aujourd'hui la relance à {n+1}. » — **jamais** « vous avez raté X » | silence |
| **Objectif atteint** | Local/server | `Objectif atteint — {nom}` | « {nom} : {progression} %. Prochain jalon : {date}. » | `goal-hit` |
| **Hors ligne** | `NetworkStatusAdapter` | (pas de notification) — badge in-app seulement | Badge « Hors ligne » (S6, `warning`) + Callout info « Les notifications restent locales pour cette session. » | silence |
| **Reconnexion** | idem | (pas de notification) — toast in-app | « Synchronisation terminée. {n} mises à jour. » (toast 3s) | silence |

### 5.3 Voix du coach (agent AI)

**Registre : direct, chaleureux-mesuré, factuel. Jamais formel-corporate, jamais
encourageant-hype.**

| Situation | Mauvais (hype) | Bon (Aurora) |
|---|---|---|
| Check-in matin | « Ready to crush it today? 🚀 » | « Bonjour. Vous avez 2 tâches et 1 session de focus prévue aujourd'hui. Par quoi commencer ? » |
| Session ratée | « Oh no! Don't give up! » | « Vous n'avez pas fait de session hier. Ça arrive. Préférez-vous la reprendre ce soir ou passer demain ? » |
| Objectif difficile | « You can totally do it, superstar! » | « Cet objectif est ambitieux. Vous êtes à 62 %. Le prochain jalon est dans 3 jours. » |
| Échec technique (agent) | « Oops, something went wrong on our side, sorry! » | « La revue n'a pas pu être générée (réseau). Elle est reportée à {heure}. » |

Règle : le coach **n'exprime jamais de sentiment à la place de l'utilisateur**
(« je suis fier de vous » interdit — c'est le bilan qui montre les faits). Le coach
**propose des actions**, pas des encouragements.

### 5.4 Annonces de Focus mode (verbatim FR, à intégrer dans `Callout`)

| État (spec S4/S6) | Texte exact |
|---|---|
| Entrée en focus (DPC v1.8, blocage actif) | « Focus actif — {n} applications en pause. Les notifications non critiques sont réduites. » |
| Entrée en focus (fallback consumer, `reduceForFocus` seul) | « Focus actif — les notifications d'Aurora sont réduites. Les autres applications ne sont pas affectées. » (capacité **réelle**, 04 §4.2 : on ne promet pas ce qu'on ne bloque pas) |
| Échec de la réduction (Callout warning, spec S2) | « La réduction des notifications n'a pas pu être activée. Le focus continue, sans réduction. » |
| Sortie (fin manuelle / expiration) | « Focus terminé — les applications et notifications ont été restaurées. » |
| Crash/redémarrage (boot receiver, S7) | « Une session de focus a été interrompue ({motif}). La session est reprise automatiquement. Les applications ont été restaurées. » — Callout `info` (neutre, pas `danger`), le choix de **fermer** reste à l'utilisateur (CTA « Fermer » uniquement ; pas de « Reprendre » car le replay est automatique per S7 spec l.130-133 — annuler le replay = fermer la session). **Jamais silencieux** : le Callout annonce explicitement la reprise. |
| Session en cours (badge au-dessus du timer) | « En cours » (accent-primary) — pas de texte d'annonce, le ring est la preuve. |

### 5.5 Messages d'erreur (calme, non-alarmant)

| État | Texte | CTA |
|---|---|---|
| Échec bilan de session (OQ-03, option (b)) | « Le bilan n'a pas pu être généré. La session est enregistrée. » | « Réessayer » (ghost sm) — le timer **continue** (AD-7 : le bilan est un bonus) |
| Hors ligne (badge, OQ-04 : « Hors ligne » FR natif) | Badge : « Hors ligne » | — (pas de CTA, le Focus reste fonctionnel) |
| Échec de sync (reconnexion en arrière-plan) | « Certaines données sont en attente de synchronisation. » | (CTA implicite : se resynchronise seul au retour réseau) |
| Package non-suspendable (blocklist, DPC S9.2) | « {app} ne peut pas être mise en pause ({raison}). La session continue sans elle. » | — (la session démarre avec l'ensemble restant ; ensemble vide = fallback restriction, jamais de blocage total silencieux) |

---

## 6. Arc émotionnel d'une session de Focus

| Phase | Durée | Ce que l'utilisateur **ressent** | Ce que le design **crée** |
|---|---|---|---|
| **A. Pré-focus (wind-down, ~30 s)** | 0 → start | Le monde se met en pause ; le téléphone devient « un lieu ». | `/focus` sans TopBar ni BottomNav (chrome retiré, 05 §4.4.2) ; `NodePulse` 1.5s breath sur le ring **avant** le démarrage (le nœud « respire » = le lieu est vivant mais calme) ; Callout info « Les notifications sont réduites pour cette session » ; son optionnel en fondu (2 s d'attaque pour éviter le coup de tonnerre) ; transition de page entrante 200ms easeOut, puis **plus** de transition (le Focus ne fait plus glisser les écrans). |
| **B. Focus actif (5–90 min)** | start → end | Immersion, stabilité, « le temps se voit mais ne se sent pas ». | Ring 160px préeminent, temps restant 3xl JetBrains Mono **stable** (pas de NumberTick — 05 §2.6 règle 1 : les données ne s'animent jamais) ; animations atténuées (règle 3 : `slow` off, toasts différés, transitions instantanées) ; nœuds secondaires à 40 % (local adaptation, motion.tsx @aurora/ui) ; le son de fond (si choisi) **continue** sans interruption (loop, nature/bruit-blanc) ; aucune notification ne sonne (§4.3) ; le badge « En cours » (accent) au-dessus du timer est le **seul** signal d'état. |
| **C. Pause intermédiaire (Pomodoro break, 5 min)** | entre cycles | « C'est le repos, pas la fin. » | Le ring passe en **`success` vert** (05 §3.6.9 : « le break, le repos, est vert — le rouge est réservé au danger ») ; le label passe de « Temps restant » à « Pause » ; le son reste en continu (pas de coupure) ; le CTA redevient « Reprendre » (pas « Démarrer »). |
| **D. Post-focus (bilan, 15–30 s)** | fin → Home | Soulagement + fierté **discrète** ; le temps est rendu. | Le ring se fige ; BottomSheet `FocusSessionBilan` s'ouvre (250ms easeOut, shadow.4) **avant** le retour au Home (05 §4.4.2 : « le bilan précède le retour ») ; `ChartSpec focusBilan` : barre horizontale `planned vs actual` (`accent-primary` = actual, `surface-alt` = planned) + 2 `StatTile` (score, interruptions) en G2 via `DataVisualizationRenderer` — **pas de valeurs animées** ; si interruption 0 : le score est affiché tel quel, pas de commentaire de « perfection » (le chiffre parle) ; CTA « Revenir au Home » (primary, seul CTA du sheet) ; son `focus-end` (si setting ON) **après** l'ouverture du sheet ; les toasts différés de la session (réductions d'apps, sync) s'affichent **maintenant** (règle 3 : jamais pendant le pomodoro). |
| **E. Retour au monde normal** | après Home | La navigation revient doucement ; tout est à sa place. | Transition de page Home 200ms ; le `NodePulse` du Focus s'arrête (n'importe quel nœud secondaire redevient statique) ; le son de fond s'arrête en fondu (2 s) ; le canvas reste `#FFFFFF` (le fond n'a jamais changé, §2.3) — le monde n'a pas « bougé ». |

Invariants de l'arc (à ne jamais briser) :

1. Le timer est basé sur **l'horloge système** (04 §6.1) : kill / reboot → reprise
   exacte au temps restant ; rien ne « se perd ». (Fiabilité = la base émotionnelle.)
2. Le bilan **ne** déclenche **jamais** d'upload réseau (pack 04 §8.3 R5) : une
   session de Focus offline reste 100 % offline.
3. Le DPC v1.8 restore (S7) : fin / expiration / crash / reboot →
   `setPackagesSuspended(set, false)` + `reduceForFocus(false)` — **le monde est
   toujours rendu**, jamais laissé en suspens.

---

## 7. Anti-patterns (ce qui casse le contrat émotionnel)

| # | Anti-pattern | Pourquoi ça casse | Règle opposée (ce qu'on fait) |
|---|---|---|---|
| **A1** | Couleurs « hype » (jaune vif, orange pulsant) sur un écran de Focus ou de deadline | Le jaune saturé = « URGENT / ACHETEZ » ; l'orange pulsant = « promotion ». Aurora ne vend rien, elle n'alarme pas. | `warning #F59E0B` **statique** (ne pulse jamais) ; les écrans de Focus n'utilisent que `accent` (en-cours) et `success` (break/fin) ; `danger` uniquement terminal. |
| **A2** | Confettis / fanfare / « GOAL REACHED!!! » sur un objectif | Le produit productivité ne devrait pas se comporter comme un looter : le « win » gamifié dévalorise l'effort réel et crée une attente de dopamine que l'app ne peut pas tenir. | Un son `goal-hit` bref (2 notes montées, 800ms) + le chiffre du jalon ; le reste du temps, l'objectif atteint se **voit** dans le tree (`node-mastered` vert), pas dans une explosion. |
| **A3** | Notifications multiples sur le même objet (deadline locale + OneSignal pour la même tâche) | L'utilisateur reçoit le même « rappel » deux fois (une fois locale, une fois serveur) = « l'app ne sait pas ce qu'elle fait ». (04 §3.4 : anti-double-push, test 04 §7.) | Règle bloquante pack 04 §3.4 : **un seul émetteur par objet** (deadline = local, événement serveur = OneSignal) ; le test de CI le vérifie. |
| **A4** | Son d'erreur alarmant (bip aigus, « error » vocal) | Un son de drame sur une erreur transitoire (réseau) = punition + fausse urgence ; en réunion c'est humiliant. | §4.4 : **silence** sur tous les états `danger` ; le Callout (rouge `#EF4444`) + CTA « Réessayer » portent l'information. |
| **A5** | « Vous avez raté X jours de {habitude} » | La re-proche décompose la série ; le rouge « broken streak » pousse l'abandon (effort perçu > récompision). | « La série est à {n}. Reprendre aujourd'hui la relance à {n+1}. » (5.5) ; `habit-weak` gris, **pas** `danger`. |
| **A6** | Un fond qui bouge en permanence (particules, wave, « live ») | « Un écran qui respire concentre » (05 §1) — un fond qui bouge **en permanence** est le contraire. Le Cosmos (particules douces) est opt-in, jamais par défaut. | Animation ambiante = **NodePulse uniquement** (Focus) ; le default de Home = aucun fond animé (les nœuds secondaires sont statiques, motion.tsx @aurora/ui). |
| **A7** | Le Focus qui **bloque** les apps sur un device consumer (promesse v1.8 sur un device non-DPC) | La UI ne doit jamais montrer un CTA « bloquer » quand `isBlockingAvailable() = false` (04 §4.2) ; la capacité réelle = `reduceForFocus` (réduction, pas blocage). | Callout « capacité réelle » : « Les notifications d'Aurora sont réduites. Les autres applications ne sont pas affectées. » — le fallback consumer est documenté, **jamais simulé**. |
| **A8** | Changer le thème en revenant au premier plan | Un changement silencieux de thème au retour foreground = l'app « se transforme » derrière l'utilisateur (05 §2.1 : « jamais de changement de thème silencieux »). | Le choix de thème est persistant (UI store, `persist`); l'auto-bascule (système/heure) est **explicite** dans /settings avec aperçu. |
| **A9** | « Reconnexion réussie ! 🎉 » | Le soulagement de resync n'est pas un événement digne d'une fanfare ; ça dilue l'attention. | Toast 3s `success` « Synchronisation terminée. » — factuel. |
| **A10** | Un 404 / crash « nu » (écran noir, logo monochrome) | « Jamais crash / 404 nu » (ui-libraries §9.1) : l'utilisateur ne doit jamais voir « l'app est morte ». | 404 global = logo **coloré** au centre + « Retour à l'accueil » (ui-libraries §6.1) ; crash Focus = boot receiver restore (§5.5, S7) ; l'état killed n'existe **pas** sur /focus (tout est local, AD-7). |
| **A11** | Fond animé **sous** le Focus (particules, wave, « live » sur l'écran /focus) | A6 interdit le fond animé **permanent** ; A11 précise le cas **sous le focus** : l'animation ambiante (thème Cosmos, particules douces opt-in §3.1 l.140) est **jamais rendue sous l'écran /focus** — un fond qui bouge pendant la session = agitation contradictoire à « le monde s'est tu ». | Sur /focus : `NodePulse` **uniquement** (le nœud focal respire, §3.1) ; les animations de fond du thème actif sont **désactivées** pour cet écran (règle 3, 05 §2.6 : focusMode = animations `slow` off). |
| **A12** | Notification OneSignal (S8) **non muée** pendant une session de Focus active | L'utilisateur en immersion reçoit un chime `chime-remote` en pleine session = rupture d'immersion + « l'app ne respecte pas son propre mode focus ». | Pendant S8 (`reduceForFocus(on)`), le son d'événement est **muté** (§4.3) ; la notification est **différée** à la fin de la session (règle 3 : toasts différés) ; le toast **jamais supprimé** — il arrive au repos, le contexte n'est pas perdu. Setting optionnel « sons même en Focus » (défaut OFF, §4.3). |

---

## 8. Récapitulatif opérationnel (à consommer par le DS)

- **Tokens émotionnels** (frozen, `neutral.ts`) : success `#10B981`/`#34D399`,
  warning `#F59E0B`/`#FBBF24`, danger `#EF4444`/`#F87171`, info `#0EA5E9`/`#38BDF8`,
  accent primaire thème Aurora `#3678F6` (thème Focus recommandé : Lagoon `#007C91`),
  canvas `#FFFFFF` light / `#121212` dark.
- **Motion canonique** : `PAGE_TRANSITION` 200ms easeOut ; BottomSheet 250ms
  easeOut ; `NodePulse` 1.5s breath (scale 4 %) ; timer = **0** animation sur le
  chiffre ; focusMode = animations atténuées + toasts différés ;
  `prefers-reduced-motion` = 0ms partout.
- **Sons d'événement à produire** (ids stables AD-15, out of `focus.sound`) :
  `chime-local` (2 notes descendantes ~500 Hz, 1200ms), `chime-remote` (3 notes
  montantes ~400 Hz, 1000ms), `focus-end` (1 note ~660 Hz, 1500ms), `goal-hit`
  (quinte ~523+659 Hz, 800ms) ; volume global ≤ 40 % ; **silence sur les erreurs**.
- **Voix** : 2e personne, présent, ≤ 12 mots, zéro exclamation/emoji ; erreurs au
  passif neutre ; le coach ne se remplace jamais dans le sentiment de
  l'utilisateur (« je suis fier de vous » interdit).
- **Règles bloquantes reprises** : un thème ne redéfinit jamais les 4 sémantiques
  (05 §5.1) ; un écran n'affiche jamais `danger` + `success` ensemble sans raison ;
  le Focus ne change jamais le canvas ; le DPC v1.8 est le seul mode où le blocage
  d'apps est affiché comme capacité.
