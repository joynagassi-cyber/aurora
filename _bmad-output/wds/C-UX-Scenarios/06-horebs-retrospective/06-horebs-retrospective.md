---
id: 06
slug: 06-horebs-retrospective
name: Horeb's Retrospective
priority: 3
pages: [S-12, S-13]
chain: 06
design_intent: S
design_status: not-started
status: draft (bridge)
---

# 06: Horeb's Retrospective

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**

Boucler sa semaine en comprenant **pourquoi** : Horeb passe par la revue guidée (revues-semaine, S-12) et son analyse des causes (analytics `/progress`, S-13) pour savoir ce qui a fonctionné ou dérapé (reports, stagnation) et adapter sa trajectoire — Self-Improve → Adapt → Review de la boucle §19 (ADR §19 ; trigger-map §5), analyse des causes et non du simple comptage (ADR §18.2 ; trigger-map §7 signal 20).

---

## Business Goal (Q2)

**Goal:** BG-PRIMARY (rétrospective)
**Objective:** Analyser les causes (pas les comptages) pour adapter la trajectoire — trigger-map §1 Primary (ADR §18, transformation réelle dans le temps : état, évolution, causes, preuves) ; boucle complète ADR §19 (… → Self-Improve → Adapt → Review) (trigger-map §5).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — étudiante en génie civil au Bénin (BAC / RDM / hydraulique), bureau d'études en ligne de mire, mobile nocturne intensif (ADR §23 ; trigger-map §2 ; strategic-chains chaîne 06 Q2 ; scope-report S-12).
**Situation:** Dimanche 23h45, fin de sa semaine d'étude, dans sa chambre au Bénin, réseau 3G instable et batterie basse (discovery-gap §5 : « limited fiber, mobile data common, power reliability varies ») — elle passe sa semaine en revue avant la reprise : ce qui a été terminé, ce qui a dérapé (reports, stagnation sur RDM), et pourquoi — sur Pixel 4a (budgets SPEC OQ-11, trigger-map §7 signal 16), thème Nocturne (SPEC OQ-16, trigger-map §7 signal 6).

---

## Driving Forces (Q4)

**Hope:** Elle veut prouver ce qui a réellement fait avancer sa semaine, pas juste compter les tâches terminées (trigger-map §7 signal 8 : « Toute progression significative doit être reliée à des preuves et à un contexte » ; envie ③ Self-improvement, ADR §14.2, trigger-map §2).

**Worry:** Elle a peur de se dire « j'ai progressé » alors que la cause du dérapage reste cachée (trigger-map §7 signal 20 : « Tendances de procrastination » — douleur liée aux reports, analyse des causes, pas de jugement ; peur ① Illusion de progression, ADR §18.2).

> CONSTRAINT: One sentence per component. Phrases, not paragraphs.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android — Pixel 4a (budgets SPEC OQ-11 : ≤ 300 Ko JS gz, ≤ 1,5 s TTI, 30 fps, trigger-map §7 signal 16), thème Nocturne (SPEC OQ-16), local-first (AD-7 : « Offline is a first-class state, not a failure mode »).
**Entry:** Depuis `analytics` `/progress` (S-13 — 5 questions structurées, dashboard Progress ADR §18.6, scope-report §A #13), Horeb appuie sur le CTA « Revue » qui l'ouvre directement dans `revues-semaine` (S-12, un écran 3 modes jour/semaine/mois, formulaire guidé, scope-report §A #14-16 §4.5.1) — le point d'entrée réel de la rétrospective (strategic-chains chaîne 06 Q5 : `analytics` → CTA « Revue » → `revues-*`).

---

## Best Outcome (Q7)

**User Success:**
Sa revue semaine est bouclée et ses **causes sont comprises** — le formulaire guidé de `revues-semaine` structure `pending`/`completed` (scope-report S-12), le dashboard `analytics` (S-13, ADR §18.6) lui montre l'écart charge planifiée vs charge réelle (ADR §2.10 ; trigger-map §7 signal 9) relié à ses preuves (`ProgressEvidenceCreated`, AD-9) : elle sait pourquoi sa semaine a dérapé et comment adapter sa trajectoire (Self-Improve → Adapt, ADR §19).

**Business Success:**
Rétrospective structurée (revues guidées) qui alimente la transformation réelle mesurable (BG-PRIMARY, trigger-map §1) — le moteur agentique Progress (ADR §18.7, trigger-map §5) détecte la stagnation, déclenche l'analyse de cause et adapte les prochaines séances/plans (sous-cycle §15 ; boucle §19 Adapt → Review) au lieu de compter des tâches terminées (ADR §18.2).

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « éventuellement ») — 4 pasos, chaque paso cite sa surface (S-ID + nom + pointeur source court).

1. **analytics /progress (S-13)** — Horeb atterrit sur le dashboard Progress (5 questions structurées, ADR §18.6 ; scope-report §A #13 ; BottomNav tab « Progress », scope-report §Shared) et y relit son état de la semaine : progression reliée à ses preuves `ProgressEvidenceCreated` (AD-9) et écart charge planifiée vs charge réelle (ADR §2.10) ; elle appuie sur le CTA « Revue » (strategic-chains chaîne 06 Q5).
2. **revues-semaine (S-12, mode semaine de l'écran revues-jour/semaine/mois)** — L'écran `revues-*` (1 écran, 3 modes, scope-report §A #14-16 §4.5.1) lui présente le formulaire guidé de la revue semaine : structure `pending`/`completed` ; elle identifie ce qui a été terminé et ce qui a dérapé.
3. **revues-semaine (S-12) — analyse des causes** — Dans le formulaire guidé de la même surface `revues-semaine`, Horeb passe du constat (tâches terminées/non) aux **causes** de ses reports et de sa stagnation sur RDM — « Analyser les causes des écarts plutôt que simplement compter les tâches terminées ou non » (ADR §18.2 ; trigger-map §7 signal 20 ; trap §6 « Illusion de progression ») ; elle définit l'adaptation de sa trajectoire (Self-Improve → Adapt, ADR §19).
4. **analytics /progress (S-13)** — Le dashboard `analytics` (S-13, ADR §18.6) consigne la revue complétée avec ses causes et l'adaptation décidée (progress.* ; AD-9 `ProgressEvent`) — la rétrospective de la semaine est terminée et le moteur agentique (ADR §18.7) l'utilise pour adapter les prochaines séances. ✓

---

## Trigger Map Connections

**Persona:** Horeb (Primary)

**Driving Forces Addressed:**
- ✅ **Want:** Envie ③ Self-improvement — réviser, adapter : Expert Skills, apprentissages opérationnels vérifiés (ADR §14.2 ; trigger-map §2 Drivers, ligne 3) + preuve de progrès réel (trigger-map §7 signal 8 : « Toute progression significative doit être reliée à des preuves et à un contexte »).
- ❌ **Fear:** Peur ① Illusion de progression — bon score de reconnaissance masquant une faible capacité de transfert (ADR §18.2 ; trigger-map §2 Drivers, ligne 1 ; trap §6 : modèles de preuve distinguant reconnaissance vs transfert) ; douleur liée aux reports et à la procrastination, sans jugement (trigger-map §7 signal 20 : « Tendances de procrastination » — ADR §2.10 + §18.2).

**Business Goal:** BG-PRIMARY (rétrospective) — analyse des causes (pas les comptages) pour adapter la trajectoire : transformation réelle mesurée dans le temps (état, évolution, causes, preuves, ADR §18) + boucle complète §19 (… → Self-Improve → Adapt → Review) (trigger-map §1 ; trigger-map §5 ; strategic-chains chaîne 06).

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 06.1 | `06.1-analytics-progress/` | Dashboard `analytics` `/progress` (S-13, ADR §18.6 ; scope-report §A #13) : état de la semaine (preuves AD-9, écart charge planifiée vs réelle ADR §2.10) + CTA « Revue » (strategic-chains ch.06 Q5). Inclut entry context (Q3 + Q4 + Q5 + Q6) : dimanche 23h45, fin de semaine, Pixel 4a thème Nocturne (SPEC OQ-11/OQ-16), réseau 3G, local-first AD-7. | Appuie sur le CTA « Revue » → s'ouvre `revues-semaine`. |
| 06.2 | `06.2-revues-semaine/` | `revues-semaine` (S-12, 1 écran 3 modes, scope-report §A #14-16 §4.5.1) : formulaire guidé de la revue semaine — structure `pending`/`completed` ; identification de ce qui a été terminé et de ce qui a dérapé (strategic-chains ch.06 Q4). | Termine le formulaire guidé (constat pending/completed) → passe à l'analyse des causes dans la même surface. |
| 06.3 | `06.3-revues-semaine-causes/` | Toujours dans `revues-semaine` (S-12) : étape d'analyse des **causes** des reports et de la stagnation — ADR §18.2 (via trigger-map §7 signal 20), trap §6 ; décision d'adaptation de la trajectoire (Self-Improve → Adapt, ADR §19). | Valide la revue (causes + adaptation) → retour au dashboard. |
| 06.4 | `06.4-analytics-progress/` | Dashboard `analytics` `/progress` (S-13, ADR §18.6) : la revue complétée avec ses causes et l'adaptation est consignée (progress.* ; AD-9 `ProgressEvent`) ; le moteur agentique (ADR §18.7) l'utilise pour adapter les prochaines séances. | Final — rétrospective de la semaine bouclée, trajectoire adaptée ✓ |

**First step** (06.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.

---
