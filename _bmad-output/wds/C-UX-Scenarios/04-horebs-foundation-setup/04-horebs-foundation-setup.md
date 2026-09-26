---
id: 04
slug: 04-horebs-foundation-setup
name: Horeb's Foundation Setup
priority: 2
pages: [S-01, S-10, S-11, S-21, S-23, S-30]
chain: 04
design_intent: S
design_status: not-started
status: draft (bridge)
flags: [triage inbox verrouillé sur /learn dans ce scénario (les 3 destinations tasks/learn/settings restent la capacité S-23, scope-report §A #23), KPIs quantitatifs (taux d'activation, rétention) et personas secondaires NON COUVERT PAR LE CORPUS (brief §3)]
---

# 04: Horeb's Foundation Setup

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Horeb fait d'Aurora un espace qui lui ressemble : elle configure son profil (`UserContext` : région, disciplines, cible pro, budget) puis son environnement — première capture universelle triée, journée et semaine planifiées, coaching réglé sur ses silences, thème Nocturne actif — pour que l'app soit calibrée sur elle dès le premier soir. C'est le but utilisateur « avoir un outil qui me connaît », pas une feature « onboarding » : le setup est la condition sine qua non pour que la transformation réelle soit mesurable (strategic-chains Chaîne 04 Q4 : « Configurer le profil (UserContext : région, disciplines, cible pro, budget) + ajuster les préférences (thème, fenêtres de silence, notifications) » ; brief §2 profil `UserContext`).

---

## Business Goal (Q2)

**Goal:** BG-PRIMARY (setup)
**Objective:** Mesurer la transformation réelle de Horeb dans le temps (état, évolution, causes, preuves) — pas un compteur de tâches ; le setup est le prérequis : sans profil `UserContext` complet, aucune transformation mesurable (trigger-map §1 Primary, ADR §18 ; strategic-chains Chaîne 04 Q1/Q7).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — jeune ingénieure en génie civil au Bénin (disciplines BA / RDM / hydraulique), usage mobile intensif nocturne sur Pixel 4a, budget étudiant (`budget_constraint: 'student'`, G-D14 `project-context.md` §5) — trigger-map §2 ; brief §2.
**Situation:** Premier soir de semestre, 22 h, Cotonou : Horeb vient d'installer Aurora sur son Pixel 4a dans sa chambre. Derrière elle, une journée de TP hydraulique et un chapitre de RDM pas encore digéré ; sa connexion mobile data est capricieuse et son forfait étudiant limité (trigger-map §7 signal 15 : « Internet connectivity: limited fiber, mobile data common, power reliability varies » — AD-7). C'est sa toute première ouverture d'Aurora : l'onboarding (S-01) est le tout premier écran qu'elle voit — 3 écrans max, sans tour de fonctions (scope-report S-01 : Screen Registry §A #1 §4.1.1 ; trigger-map §2, Bénin + mobile intensif nocturne).

---

## Driving Forces (Q4)

**Hope:** Revenir à 22 h sur une app déjà sombre, silencieuse et calée sur ses matières, pour s'enfoncer dans un calcul de BA sans y penser (trigger-map §7 signal 6 : « Besoin de concentration en sessions nocturnes (thème Nocturne dédié) » — « Nocturne est un preset autonome… surfaces plus foncées, accents désaturés… pour les sessions nocturnes », SPEC OQ-16 + pack 05 §5 ; renforcé par signal 5 « Peur de la distraction / perte de concentration », ADR §2.8).

**Worry:** Qu'Aurora inonde son Home de notifications et de widgets au lieu de respecter son silence et son rythme de session nocturne (trigger-map §6 Trap « Surcharge de widgets » — « composition fixe qui répond 'Quoi de important maintenant ?' (7 items fixes, jamais un dashboard) », AD-14 + ADR §12 ; §7 signal 4 « Fatigue d'alertes et de notifications — désir d'information contextuelle plutôt que de bruit », adr-extract §13 Coach).

> CONSTRAINT: One sentence per component.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android (app Ionic React + Capacitor, ADR §23.1/§24) — appareil de référence **Pixel 4a**, budgets SPEC OQ-11 : ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps (project-context §3 règle 15 + SPEC OQ-11 ; trigger-map §7 signal 16) ; thème Nocturne (SPEC OQ-16, pack 05 §5).
**Entry:** Premier lancement d'Aurora après installation → **onboarding `onboarding` (S-01)** : 3 écrans max (étudiante → matière → heure de silence → thème), sans tour de fonctions — le tout premier écran qu'elle voit, pas « ouvre l'app » générique (scope-report S-01 : Screen Registry §A #1 §4.1.1 ; strategic-chains Chaîne 04 Q5 : « Lancement de l'app → onboarding (3 écrans max) → Home »).

---

## Best Outcome (Q7)

**User Success (preuve tangible mesurable) :**
Horeb clôture le soir avec un profil `UserContext` validé et persisté sur son appareil — 4 champs : `region`, `disciplines`, `professional_target`, `budget_constraint` (G-D14, `project-context.md` §5 ; AD-15) — et sa première capture du soir (notes de cours BAC/RDM/hydraulique) triée dans `/learn` (S-23 → S-11) avec sa fiche `SourceRef` rattachée (scope-report §Boucles item 1 ; §A #23). Preuve tangible : son thème Nocturne est actif et sa fenêtre de silence du soir est enregistrée dans `/settings` (S-30 : « thème + preview, fenêtres de silence, préférences de notifications, compte » — Screen Registry §A #35) ; à 23 h, elle rouvre l'app et retrouve son environnement déjà calibré — sombre, silencieux, calé sur ses matières (SPEC OQ-16 + pack 05 §5 ; trigger-map §7 signal 6) — avec un bloc d'étude BAC déjà planifié dans la journée (S-10) et son rythme posé sur la semaine (S-11).

**Business Success :**
Activation du profil `UserContext` mesurée — 4 champs complets (`region`, `disciplines`, `professional_target`, `budget_constraint`) persistés au premier soir, onboarding terminé en ≤ 3 écrans sans tour de fonctions (scope-report S-01) — ce qui débloque la mesure de la transformation réelle (BG-PRIMARY, ADR §18) : sans ce profil, la boucle Progress (état, évolution, causes, preuves) n'a pas de référence (strategic-chains Chaîne 04 Q7 : « activation du profil (UserContext complet) → capacité à mesurer la transformation réelle » ; trigger-map §1 Primary).

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « peut », pas de « éventuellement ») — 6 pasos, chaque paso cite sa surface (S-ID + nom + pointeur source court).

1. **`onboarding` (S-01)** — Horeb configure son profil en 3 écrans ou moins (étudiante → BAC/RDM/hydraulique → heures de silence → thème Nocturne), sans tour de fonctions ; `UserContext` rempli (4 champs G-D14) [scope-report S-01 : Screen Registry §A #1 §4.1.1].
2. **`/inbox` (S-23)** — Elle capture sa première charge du soir (notes de cours BAC/RDM/hydraulique) via le CTA « Capture this » ; le triage dépose l'entrée dans `/learn` — point d'entrée du profil (flow 1) [scope-report S-23 + §Boucles item 1 ; EXPERIENCE.md §Key Flows item 1].
3. **`calendrier-jour` (S-10)** — Elle planifie sa session de ce soir (bloc d'étude BAC) sur la journée [scope-report S-10 : Screen Registry §A #10-12 §4.4.1].
4. **`calendrier-semaine` (S-11)** — Elle zoome sur la semaine (même écran, mode `Pager`) pour placer ses routines et échéances dans le rythme hebdomadaire [scope-report S-11 : Screen Registry §A #10-12 §4.4.1].
5. **`mode-coach` (S-21)** — Elle règle le coaching : cadence, fenêtres de silence, désactivation du jour — contrôle total, jamais intrusif (ADR §13 Coach : « Le coaching ne doit pas devenir intrusif » ; « cadence, horaires de silence et niveau d'intervention contrôlés par l'utilisatrice ») [scope-report S-21 : Screen Registry §A #25 §4.9.1 ; trigger-map §7 signal 3].
6. **`/settings` (S-30)** — Elle active le thème Nocturne (avec preview), fixe les préférences de notifications et le compte ; l'environnement est calibré ✓ [scope-report S-30 : Screen Registry §A #35 ; SPEC OQ-16 + pack 05 §5].

*(6 pasos — onboarding → inbox → calendrier jour → calendrier semaine → mode-coach → settings, dernier passo = succès du scénario. S-02 `welcome/home` est le point d'atterrissage naturel après onboarding (strategic-chains Chaîne 04 Q5) mais n'est pas un pas de ce chemin : il est couvert par le scénario 01.)*

---

## Trigger Map Connections

**Persona:** Horeb (Primary — trigger-map §2)

**Driving Forces Addressed:**
- ✅ **Want:** Envie ① Focus — « Focus Mode + anti-distraction = session de travail profond » (trigger-map §2 Drivers positifs, ADR §2.8) ; matérialisée dans le setup par thème Nocturne + fenêtres de silence (signal 6 « Besoin de concentration en sessions nocturnes (thème Nocturne dédié) », SPEC OQ-16 + pack 05 §5).
- ❌ **Fear:** Peur ③ Surcharge de widgets — « Home dégradé en tableau de bord de widgets » (trigger-map §2 Drivers négatifs + §6 Traps, AD-14 + ADR §12 : « composition fixe qui répond 'Quoi de important maintenant ?' ») ; défendue par l'onboarding sans tour de fonctions et la composition Home fixe (7 items, pack 05 §4.1.2) — signal 4 « Fatigue d'alertes et de notifications » (adr-extract §13 Coach).

**Business Goal:** BG-PRIMARY (setup) — activation du profil `UserContext` complet → capacité à mesurer la transformation réelle (trigger-map §1 Primary, ADR §18 ; strategic-chains Chaîne 04 Q1/Q7).

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 04.1 | `04.1-onboarding-profil/` (S-01 `onboarding`) | Onboarding (S-01) : Horeb configure son profil `UserContext` (étudiante, BAC/RDM/hydraulique, heures de silence, thème Nocturne) en 3 écrans ou moins, sans tour de fonctions — 4 champs G-D14 remplis [scope-report S-01 : Screen Registry §A #1 §4.1.1]. Inclut entry context (Q3 + Q4 + Q5 + Q6). | Tapote « C'est parti » → onboarding terminé (l'app est prête pour son premier soir) |
| 04.2 | `04.2-inbox-capture/` (S-23 `/inbox`) | Inbox (S-23) : première capture universelle du soir (notes BAC/RDM/hydraulique) via le CTA « Capture this » ; le triage dépose l'entrée dans `/learn` (flow 1, point d'entrée du profil ; draft Tiptap persisté) [scope-report S-23 + §Boucles item 1] | Triage terminé → l'entrée vit dans `/learn` avec sa fiche `SourceRef` |
| 04.3 | `04.3-calendrier-jour-semaine/` (S-10 `calendrier-jour` + S-11 `calendrier-semaine`, 1 écran 3 modes `Pager`) | Calendrier (S-10 jour + S-11 semaine) : Horeb place sa session de ce soir (bloc d'étude BAC) sur la journée puis zoome sur la semaine pour poser son rythme hebdomadaire (routines + échéances) [scope-report S-10/S-11 : Screen Registry §A #10-12 §4.4.1] | Semaine planifiée → elle passe au réglage du coaching |
| 04.4 | `04.4-mode-coach/` (S-21 `mode-coach`) | Mode-coach (S-21) : Horeb règle cadence, fenêtres de silence et désactivation du jour — contrôle total du coaching, jamais intrusif (ADR §13 Coach ; trigger-map §7 signal 3) [scope-report S-21 : Screen Registry §A #25 §4.9.1] | Coaching configuré → elle passe aux dernières préférences |
| 04.5 | `04.5-settings-preferences/` (S-30 `/settings`) | Settings (S-30) : thème Nocturne + preview, préférences de notifications, compte — l'environnement est calibré ; fin du scénario ✓ [scope-report S-30 : Screen Registry §A #35 ; SPEC OQ-16 + pack 05 §5] | Thème Nocturne actif + notifications maîtrisées ✓ |

**First step** (04.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.

---

## NON COUVERT

Aucune surface de ce scénario n'est inventée : S-01, S-10, S-11, S-21, S-23, S-30 figurent toutes dans l'inventaire du scope-report (§A #1, #10-12, #25, #35). Les KPIs produits quantitatifs (taux d'activation, rétention) et les personas secondaires sont déclarés NON COUVERT PAR LE CORPUS (brief §3 ; trigger-map §3) et ne sont pas invoqués ici.
