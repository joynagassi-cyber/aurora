---
id: 05
slug: 05-horebs-habit-loop
name: Horeb's Habit Loop
priority: 3
pages: [S-05, S-08, S-09, S-24, S-32, S-39]
chain: 05
design_intent: S
design_status: not-started
status: draft
flags: [S-39 NEEDS_DECISION wave-2]
---

# 05: Horeb's Habit Loop

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Horeb suit ses habitudes et routines : elle vérifie l'adhérence de ses routines ordonnées (matin / soir / étude) via l'heatmap `HabitStreak`, marque le check-in du jour, déroule sa routine ordonnée, puis place sa tâche nocturne dans la matrice Eisenhower et lance le CTA focus qui en découle — des habitudes actives et mesurées, pas de simples rappels passifs (strategic-chains Chaîne 05 Q4 : « Suivre une habitude/routine » : check-in « Marquer aujourd'hui » + séquence d'étapes ; ADR §2 cycle de productivité ; master-feature-catalog L24 `productivity.habits`).

---

## Business Goal (Q2)

**Goal:** BG-PRIMARY (fidélisation)
**Objective:** Maintenir la régularité des pratiques (habitudes/routines) pour que la transformation réelle (mesure, preuves) soit continue — trigger-map §1 Primary (ADR §18) ; ADR §2 (cycle de productivité).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — étudiante en génie civil au Bénin (BAC / RDM / hydraulique), sessions nocturnes mobiles sur Pixel 4a (budgets SPEC OQ-11 : ≤ 300 Ko JS gz, ≤ 1,5 s TTI, 30 fps), thème Nocturne (SPEC OQ-16), réseau 3G instable, local-first (AD-7).

**Situation:** 22h30, dans sa chambre, Horeb vient de terminer ses révisions post-cours RDM. Elle suit un rituel de routine du soir fixe (révisions 30 min → capture de notes → end of day check-in). Fatiguée, elle veut s'assurer que sa routine du soir a été réellement faite et boucler sa journée proprement, sans y ajouter de widget-dashboard supplémentaire (trigger-map §6 trap « Surcharge de widgets » : AD-14, composition fixe de Home, pack 05 §4.1.2).

---

## Driving Forces (Q4)

**Hope:** Maintenir sa routine nocturne d'étude sans la laisser s'effriter — chaque check-in marque une brique de `HabitStreak` qui rend sa régularité mesurable et réelle (trigger-map §7 signal 8 : « Toute progression significative doit être reliée à des preuves et à un contexte » ; ADR §18.3).

**Worry:** Se retrouver avec une pile de rappels non suivis qui transforment ses habitudes actives en simple veille passive de notifications, trahissant l'illusion de régularité qu'elle croit maintenir (trigger-map §7 signal 20 : « Tendances de procrastination » ; ADR §2.10 ; §6 trap « Veille passive »).

> CONSTRAINT: One sentence per component.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android — Pixel 4a (budgets SPEC OQ-11 : ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps ; project-context §3 règle 15 + trigger-map §7 signal 16), thème Nocturne (SPEC OQ-16).

**Entry:** Horeb ouvre Aurora et atterrit sur Home `welcome/home` (AD-14, composition fixe) : elle actionne le bloc « Habitudes/Routines » de la composition et arrive directement dans l'écran `habitudes` (S-08) — pas de navigation additionnelle (strategic-chains Chaîne 05 Q5 ; scope-report S-08).

---

## Best Outcome (Q7)

**User Success:**
Horeb voit son heatmap d'adhérence `HabitStreak` (S-08) qui affiche 7 briques consécutives (7 jours de check-ins) sur la fenêtre mobile de 7 semaines (scope-report S-08, variante mobile) ; elle marque le check-in du jour et la brique 8 apparaît instantanément sur la heatmap — une ligne de régularité mesurée (nombre de briques + continuité), pas un compteur de tâches ni une notification passante (trigger-map §6 trap « Veille passive » ; scope-report §A #8).

**Business Success:**
La régularité est mesurée par les habitudes actives (heatmap `HabitStreak`, 7 briques consécutives observables + 1 brique ajoutée par check-in), chaque check-in créant une preuve d'adhérence traçable qui alimente la transformation réelle (BG-PRIMARY) — ADR §18.2 : transformation dans le temps, pas un compteur de tâches ; master-feature-catalog L24 `productivity.habits`.

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « éventuellement ») — 6 pasos, chaque paso cite sa surface (S-ID + nom + pointeur source court).

1. **habitudes (S-08)** — Horeb ouvre l'écran `habitudes` depuis le bloc « Habitudes/Routines » de Home AD-14 ; elle voit l'heatmap d'adhérence `HabitStreak` (7 semaines mobile, scope-report §A #8) ; elle tape le check-in « Marquer aujourd'hui » — la brique du jour s'ajoute à sa chaîne (scope-report §A #8 ; master-feature-catalog L24 `productivity.habits`).
2. **routines (S-09)** — Horeb ouvre la routine ordonnée « Soir » (séquence d'étapes, pas un to-do — scope-report §A #9) ; elle déroule les étapes de son rituel nocturne (révisions 30 min → capture de notes) dans l'ordre défini ; elle confirme que la routine est complète (toutes les étapes faites).
3. **taches-liste (S-32)** — Horeb consulte sa liste plate de tâches (S-32, scope-report §B #32, référencée §4.3.1) ; elle identifie la tâche nocturne qui exige priorisation (la seule tâche qui n'a pas encore de statut défini dans la liste).
4. **kanban (S-05)** — Horeb ouvre le board Kanban global (S-05, 5 colonnes : à faire / en cours / bloqué / terminé / annulé, scope-report §A #5) ; elle glisse sa tâche nocturne de la colonne « à faire » vers la colonne « en cours » (drag local entre colonnes, scope-report §A #5).
5. **/tasks/:id (S-24)** — Horeb ouvre l'overlay de détail `/tasks/:id` (S-24, scope-report §A #24) ; elle lit les sous-tâches de sa tâche nocturne (section sous-tâches de l'overlay) ; elle ferme l'overlay.
6. **Eisenhower (S-39)** [NEEDS_DECISION wave-2] — Horeb ouvre la vue/matrice Eisenhower (4 quadrants, S-39 — surface additive critique G1 : `docs/productivity/eisenhower.md` §4 ; `docs/architecture/gap-register.md` L40 ; `docs/features/master-feature-catalog.md` L20 `productivity.eisenhower`) ; elle place sa tâche nocturne dans le quadrant Q1 (urgent + important) via le glisser-déposer sur la matrice ; elle tape le CTA focus — le check-in du jour est bouclé, sa régularité est mesurée. ✓

---

## Trigger Map Connections

**Persona:** Horeb (Primary — trigger-map §2)

**Driving Forces Addressed:**
- ✅ **Want:** Envie ① Focus — session de travail profond (trigger-map §2 Drivers, ADR §2.8) + envie de régularité mesurée par preuves (`HabitStreak`), pas par rappels passifs (trigger-map §7 signal 8 ; master-feature-catalog L24 `productivity.habits`).
- ❌ **Fear:** Peur ② Veille passive — accumulation de liens/notifications sans action (trigger-map §2 Drivers, ADR §13, §17 ; trigger-map §6 trap « Veille passive ») — les habitudes actives remplacent les simples rappels (ADR §2, cycle de productivité ; §7 signal 20).

**Business Goal:** BG-PRIMARY (fidélisation) — maintenir la régularité des pratiques (habitudes/routines actives) pour que la transformation réelle (mesure, preuves) soit continue (trigger-map §1 Primary, ADR §18 ; ADR §2 cycle de productivité).

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 05.1 | `05.1-habitudes/` | Écran `habitudes` (S-08) : heatmap `HabitStreak` (7 semaines mobile) + check-in « Marquer aujourd'hui » (scope-report §A #8 ; master-feature-catalog L24 `productivity.habits`). Inclut entry context (Q3 + Q4 + Q5 + Q6) : session nocturne 22h30, Pixel 4a, thème Nocturne, fatigue post-RDM, bloc « Habitudes/Routines » de Home AD-14. | Tapote le check-in « Marquer aujourd'hui » → la brique du jour s'ajoute à la heatmap → ouvre la routine ordonnée du soir (05.2). |
| 05.2 | `05.2-routines/` | Écran `routines` (S-09) : séquence ordonnée du rituel nocturne (matin / soir / étude — scope-report §A #9) ; déroule les étapes (révisions 30 min → capture de notes) dans l'ordre défini. | Confirme que la routine est complète (toutes les étapes faites) → ouvre la liste plate de tâches (05.3). |
| 05.3 | `05.3-taches-liste/` | Écran `taches-liste` (S-32, scope-report §B #32, §4.3.1) : liste plate des tâches récapitulant l'état du jour. | Identifie la tâche nocturne qui n'a pas encore de statut défini → ouvre le board Kanban (05.4). |
| 05.4 | `05.4-kanban/` | Écran `kanban` (S-05, 5 colonnes statuts, scope-report §A #5) : vue parente de `/tasks/:id` (S-24) et de la matrice Eisenhower (S-39) (strategic-chains Chaîne 05). | Glisse la tâche nocturne de la colonne « à faire » vers la colonne « en cours » (drag local) → ouvre l'overlay de détail (05.5). |
| 05.5 | `05.5-tasks-detail/` | Overlay `/tasks/:id` (S-24, scope-report §A #24) : sous-tâches + matrice Eisenhower en contenu (vue en contenu, pas l'écran quadrant — critique G1). | Lit les sous-tâches de la tâche nocturne → ferme l'overlay → ouvre la vue/matrice Eisenhower (05.6). |
| 05.6 | `05.6-eisenhower/` | Vue/matrice Eisenhower (S-39, critique G1, 4 quadrants) [NEEDS_DECISION wave-2] : placement Q1 (urgent + important) via glisser-déposer + CTA focus (`docs/productivity/eisenhower.md` §4 ; `docs/architecture/gap-register.md` L40). | Place la tâche dans le quadrant Q1, tape le CTA focus — le check-in du jour est bouclé, la régularité est mesurée. ✓ **Final — scenario success** |

**First step** (05.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.
