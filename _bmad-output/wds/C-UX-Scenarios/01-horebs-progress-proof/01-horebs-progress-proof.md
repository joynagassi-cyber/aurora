---
id: 01
slug: 01-horebs-progress-proof
name: Horeb's Progress Proof
priority: 1
pages: [S-02, S-13, S-19, S-20, S-22, S-38]
chain: 01
design_intent: S
design_status: not-started
status: draft
flags: [S-38 UNRECONCILED (exercises, scope-report §B + Discrepancies G2, résolution standup wave-0)]
---

# 01: Horeb's Progress Proof

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Horeb produit une **preuve vérifiée de sa transformation réelle** : elle passe une session de révision espacée, un QCM, un exercice progressif, explique sa compréhension au mode miroir, et relie ce qu'elle a fait (preuves) aux causes — pour savoir où elle en est vraiment, pas « combien de choses elle a cochées » (strategic-chains Chaîne 01 Q4 : « Produire une PREUVE de transformation » ; trigger-map §4 Intent #7 « Progresser » + §5 Flywheel ; brief §7 Progress : « transformation réelle — état, évolution, causes, preuves — et non un compteur de tâches »).

---

## Business Goal (Q2)

**Goal:** BG-PRIMARY (critical path, moteur du flywheel)
**Objective:** Mesurer la **TRANSFORMATION RÉELLE** de Horeb dans le temps (état, évolution, causes, preuves) — pas un compteur de tâches (trigger-map §1 Primary, ADR §18 ; strategic-chains Chaîne 01 Q1).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — étudiante en génie civil au Bénin (BA / RDM / hydraulique), usage mobile intensif nocturne sur Pixel 4a (budgets SPEC OQ-11 : ≤ 300 Ko JS gz, ≤ 1,5 s TTI, 30 fps), thème Nocturne (SPEC OQ-16), réseau mobile limité, local-first (AD-7, offline = état premier).
**Situation:** 23h, Horeb est dans sa chambre, seule, téléphone Android en main, session nocturne en thème Nocturne, réseau mobile limité — offline = état premier, l'app reste pleinement utilisable (brief §2 « sessions de concentration nocturnes » ; SPEC OQ-16 ; ADR §23.1 ; AD-7 offline-first ; trigger-map §7 signal 15). Ce qui la pousse à faire cette session : la crainte viscérale d'être à l'étroit entre son niveau académique et le métier réel de bureau d'études (trigger-map §7 signal 12 : « Écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier » — ADR §13.4) ; l'espoir de mesurer sa progression réelle plutôt que de compter des tâches (trigger-map §7 signal 8 : « Toute progression significative doit être reliée à des preuves et à un contexte » — ADR §18.3).

---

## Driving Forces (Q4)

**Hope:** Voir enfin noir sur blanc que sa RDM tient le coup — pas un score, mais une preuve qu'elle sait TRANSFÉRER la flèche d'une poutre encastrée à un cas réel de bureau d'études (trigger-map §7 signal 8 : « Toute progression significative doit être reliée à des preuves et à un contexte » ; ADR §18.3).

**Worry:** Se dire « c'est bon » sur le QCM alors que face à une vraie poutre encastrée du chantier elle ne saurait pas quoi faire — l'écart avec le métier s'élargit sous ses yeux (trigger-map §7 signal 7 : « Détecter les cas où un bon score de reconnaissance masque une faible capacité de transfert » ; ADR §18.2).

> CONSTRAINT: One sentence per component.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android — app (Ionic React + Capacitor, ADR §23.1/§24), appareil de référence **Pixel 4a**, budgets SPEC OQ-11 : ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps (project-context §3 règle 15 + SPEC OQ-11 ; trigger-map §7 signal 16) ; thème Nocturne en session nocturne (SPEC OQ-16).
**Entry:** Elle ouvre l'app et atterrit sur **Home `welcome/home` (AD-14)** : la 7ᵉ item fixe de la composition Home, le bloc « progression critique » (associé au bloc « 12 révisions dues »), qui l'amène vers `/progress` (strategic-chains Chaîne 01 Q5 ; scope-report S-02 + parcours « Learning loop » item 3, EXPERIENCE.md §Key Flows).

---

## Best Outcome (Q7)

**User Success (critères mesurables — lisibles dans les 5 questions de `/progress` S-13) :**
(a) le score QCM **≥ 80 %** avec la **distinction reconnaissance vs transfert affichée** (ADR §18.2) ; (b) l'exercice RDM **validé par le Scientific Engine** (unités/dimensions conformes, `scientific.evaluate`/`scientific.verify` — trigger-map §4 Intent #6) ; (c) le **NodeState `mastered` sur la poutre encastrée** (le Knowledge consomme l'événement `ProgressEvidenceCreated` AD-9, `NodeState` not_started→mastered — trigger-map §7 signal 8, discovery-gap §2C) ; (d) la **SkillState mise à jour sur FSRS** (intervalle de révision augmenté — AD-9 `SkillStateChanged`, F-07). Preuve tangible totale : **4 événements `ProgressEvidenceCreated` (AD-9, F-07) — 1 minimum par surface de preuve** (S-19, S-20, S-22, S-38), tous reliés à leur contexte et compétence dans les 5 questions de `/progress` (strategic-chains Ch.01 Q6 ; ADR §18.2/§18.3).

**Business Success:**
La **transformation réelle est traçable** dans le temps (état, évolution, causes, preuves) : 4 `ProgressEvidenceCreated` (AD-9) émis depuis les surfaces de preuve et mesurés par le dashboard Progress ADR §18.6 (S-13) — chaque session produit ≥ 1 preuve vérifiée par surface (4 surfaces = 4 événements), et le flywheel (trigger-map §5, moteur agentique ADR §18.7) re-lance automatiquement révision/exercice sur les gaps détectés (strategic-chains Chaîne 01 Q7 ; ADR §18 ; brief §7 Progress).

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « éventuellement ») — 7 pasos, chaque passo cite sa surface (S-ID + nom + pointeur source court). Chaque transition entre pasos est le **CTA unique et fixe de la surface courante** (composition AD-14, jamais une proposition libre de l'agent) : c'est ce qui garantit que le chemin est le seul chemin — l'utilisateur n'a aucune décision de branchement à prendre.

1. **`welcome/home` (S-02)** — Horeb ouvre l'app : la 7ᵉ item fixe de la composition Home AD-14, le bloc « progression critique » (avec le bloc « 12 révisions dues »), signale un gap sur RDM ; elle l'actionne — le bloc est le CTA unique de cette transition, vers `/progress` [strategic-chains Ch.01 Q5 ; scope-report S-02, parcours Learning loop item 3, EXPERIENCE.md §Key Flows].
2. **`analytics` (`/progress`) (S-13, état pré)** — Les 5 questions structurées (pas un dashboard de KPIs) lui montrent l'état, l'évolution et la cause du gap RDM ; le **CTA fixe de la surface** « Réviser » (file due) est son unique action de départ vers `flashcards` [scope-report S-13, ADR §18.6 ; strategic-chains Ch.01 Q1].
3. **`flashcards` (S-19)** — Session de révision espacée FSRS sur la file de 12 cartes dues (RDM) ; son auto-évaluation alimente `SkillState` (`SkillStateChanged` AD-9) et `ProgressEvidence` (F-07) ; en fin de file, le **CTA fixe du screen** « QCM du domaine » est le seul CTA d'action de la surface, vers `qcm` [scope-report S-19 ; EXPERIENCE.md Learning loop item 3 ; composition AD-14].
4. **`qcm` (S-20)** — QCM généré par l'agent serveur sur le même domaine, exécuté séquentiellement ; le résultat est une `ProgressEvidence` (score distinguant reconnaissance de transfert, ADR §18.2) ; à la validation du score, le **CTA fixe** « Expliquer pour vérifier » est l'unique action de sortie, vers `mirror-cognitive` [scope-report S-20 ; strategic-chains Ch.01 S-20 ; trigger-map §4 Intent #7].
5. **`mirror-cognitive` (S-22)** — Elle explique à voix haute ce qu'elle a compris d'une poutre encastrée ; le kernel analyse et affiche lacunes, contradictions et erreurs (trigger-map §7 signal 10, ADR §3) ; la preuve de compréhension (pas de cocher) est enregistrée comme `ProgressEvidence` ; en fin d'analyse, le **CTA fixe** « Exercice progressif » est l'unique action de sortie, vers `exercises` [scope-report S-22 ; trigger-map §4 Intent #6].
6. **`exercises` (`/exercises/:id`) (S-38)** — Elle lance l'exercice progressif sur le domaine, vérifié par le Scientific Engine (unités/dimensions, `scientific.evaluate`/`scientific.verify`) ; le résultat est une `ProgressEvidence` ; la validation de l'exercice déclenche l'**auto-redirect automatique** vers `/progress` — re-render du dashboard à l'événement `ProgressEvidenceCreated` (AD-9 → ProgressSnapshot, dashboard ADR §18.6) [scope-report S-38 ; trigger-map §4 Intent #6].
7. **`analytics` (`/progress`) (S-13, état post)** ✓ — Retour automatique sur `/progress` : les 4 nouvelles preuves (révision S-19, QCM S-20, miroir S-22, exercice S-38) sont affichées dans les 5 questions, reliées à leur contexte et compétence ; les 4 critères mesurables Q7 sont visibles (score QCM ≥ 80 % avec distinction reconnaissance/transfert, exercice validé par le Scientific Engine, NodeState `mastered` poutre encastrée, SkillState FSRS à intervalle augmenté) — la transformation réelle est prouvée, pas comptée : succès du scénario [strategic-chains Ch.01 Q6/Q7 ; ADR §18.2/§18.3 ; trigger-map §7 signal 8].

*(7 pasos — plage 5-8 respectée ; S-20 et S-38 sont deux formes de preuve distinctes demandées par l'inventaire de la chaîne (strategic-chains Chaîne 01, pages assignées), chacune non optionnelle : le QCM distingue reconnaissance vs transfert (ADR §18.2), l'exercice vérifie le transfert par le Scientific Engine (trigger-map §4 Intent #6) — aucune transition n'est une proposition libre de l'agent, chaque passo se termine par le CTA unique et fixe de sa surface ou par l'auto-redirect événementiel.)*

---

## Trigger Map Connections

**Persona:** Horeb (Primary — trigger-map §2)

**Driving Forces Addressed:**
- ✅ **Want:** Envie ③ Self-improvement — Expert Skills, apprentissages opérationnels vérifiés (trigger-map §2 Drivers, ADR §14/§14.2) × signal 8 « preuve de progrès réel » (trigger-map §7, ADR §18.3).
- ❌ **Fear:** Peur ① Illusion de progression — « bon score de reconnaissance masquant une faible capacité de transfert » (trigger-map §2 Drivers + §6 Traps, ADR §18.2) × signal 7 (trigger-map §7).

**Business Goal:** BG-PRIMARY — transformation réelle traçable (état, évolution, causes, preuves), moteur du flywheel (trigger-map §1 Primary + §5 ; ADR §18 ; strategic-chains Chaîne 01).

---

## Scenario Steps

1 folder = 1 surface (règle du template WDS) — S-13 apparaît 2× (état pré au step 01.2, état post au step 01.7) : pattern Storyboard « states within views » (scope-report §Typologie, `EXPERIENCE.md` §State Patterns) ; `pages` frontmatter reste 6 surfaces.

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 01.1 | `01.1-home-progress-block/` (S-02 `welcome/home`) | Horeb ouvre l'app en session nocturne (AD-14, 7ᵉ item fixe) et lit le bloc « progression critique » qui signale le gap RDM + 12 révisions dues [strategic-chains Ch.01 Q5]. Inclut entry context (Q3 + Q4 + Q5 + Q6). | CTA fixe du bloc « progression critique » → arrive sur `/progress` (01.2) |
| 01.2 | `01.2-analytics-progress/` (S-13 `analytics`, **état pré**) | Les 5 questions structurées de `/progress` (ADR §18.6) révèlent état/évolution/cause du gap RDM, avant toute preuve nouvelle [scope-report S-13] | CTA fixe de la surface « Réviser » (file due) → arrive sur `flashcards` (01.3) |
| 01.3 | `01.3-flashcards-review/` (S-19 `flashcards`) | Session FSRS des 12 cartes dues ; auto-évaluation qui alimente `SkillState`/`ProgressEvidence` (AD-9, F-07) [scope-report S-19] | En fin de file, le CTA FIXE du screen « QCM du domaine » (seul CTA d'action, composition AD-14 — jamais de proposition libre de l'agent) → arrive sur `qcm` (01.4) |
| 01.4 | `01.4-qcm-evaluation/` (S-20 `qcm`) | QCM généré par l'agent serveur, séquentiel ; résultat = `ProgressEvidence` qui distingue reconnaissance vs transfert (ADR §18.2) [scope-report S-20] | À la validation du score, CTA FIXE « Expliquer pour vérifier » → arrive sur `mirror-cognitive` (01.5) |
| 01.5 | `01.5-mirror-cognitive/` (S-22 `mirror-cognitive`) | Elle explique la notion (vocal) ; le kernel affiche lacunes/contradictions/erreurs (signal 10, ADR §3) ; preuve de compréhension enregistrée comme `ProgressEvidence` [scope-report S-22] | En fin d'analyse, CTA FIXE « Exercice progressif » → arrive sur `exercises` (01.6) |
| 01.6 | `01.6-exercises-proof/` (S-38 `exercises` **uniquement** [flag UNRECONCILED — scope-report §B + G2]) | Exercice progressif vérifié par le Scientific Engine (unités/dimensions, `scientific.evaluate`/`scientific.verify`) → `ProgressEvidence` [scope-report S-38] | CTA FIXE « Retour `/progress` » — la validation de l'exercice déclenche l'auto-redirect événementiel (`ProgressEvidenceCreated` AD-9 → re-render dashboard ADR §18.6) → arrive sur 01.7 |
| 01.7 | `01.7-analytics-confirmed/` (S-13 `analytics`, **état post**) | Retour automatique sur `/progress` (re-render par l'événement `ProgressEvidenceCreated`, dashboard ADR §18.6) : les 4 nouvelles preuves (S-19, S-20, S-22, S-38) sont affichées dans les 5 questions, reliées contexte + compétence (signal 8, ADR §18.3) ; critères mesurables Q7 visibles : (a) score QCM ≥ 80 % avec distinction reconnaissance/transfert, (b) exercice validé Scientific Engine, (c) NodeState `mastered` poutre encastrée, (d) SkillState FSRS à intervalle augmenté — **scénario success ✓** [strategic-chains Ch.01 Q6/Q7 ; ADR §18.2/§18.3] | **Final — scenario success** : la transformation réelle est prouvée, pas comptée ✓ |

**First step** (01.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.
