# Review — Réconciliation Pack 05 (05-design-system.md)

> **Contexte** : le rédacteur a produit 3 entrées parallèles pour le pack 05 :
> - `dimensions/05-p2.md` (1 264 lignes) — frontmatter + §1–§4.1.1 propres, s'arrête **en pleine phrase** dans 4.1.2 ;
> - `dimensions/05-main.md` (6 915 lignes) — contient §4.6–§4.9.2 **cassés** (un mot par ligne, c. 4 300 lignes d'une ligne) ;
> - 6 fragments `05-chunk*.txt` + fix-tail — **supprimés** lors de la reconstitution (cf. `.memlog.md`).
>
> Le pack 05 consolidé est `dimensions/05-design-system.md` (3 011 lignes). Ce rapport indique **exactement**
> ce qui est propre, ce qui est cassé, et où se trouve le texte de référence pour chaque écran.

**Date** : 2026-09-21 · **Agent** : réconciliation pack 05

---

## 1. Verdict d'ensemble

**Le pack 05 (`05-design-system.md`) est cassé à partir de la ligne ~2313 (§4.5.2 `analytics`).**
Les sections 4.1 → 4.5.1 sont **propres** ; 4.5.2, 4.6.1, 4.6.2, 4.7.1, 4.8.1, 4.8.2, 4.9.1, 4.9.2 sont
**cassées ou tronquées** (texte écrit en lignes d'un à deux mots, héritées de `05-main.md`).

> Nota : l'objectif initial (« vérifier que 4.9.2 est propre dans le pack 05, signalé en fin de §4 ») est
> **faux** : le §4 du pack 05 **s'arrête à 4.5.2 cassé**. Les écrans 4.6 → 4.9.2 n'existent **pas** dans
> le pack 05 ; ils ne vivent que dans `05-main.md` (broyés). La correction nécessite de les **ajouter** au
> pack 05, non de les justifier en place.

| Section | Pack 05 (lignes) | Verdict | Source de vérité |
|---|---|---|---|
| 4.1.1 `onboarding` | 1235–1261 | ✅ **propre** | — (déjà dans le pack 05) |
| 4.1.2 `welcome/home` | 1263–1328 | ✅ **propre** | — |
| 4.3.1 `projets-liste` | 1333–1383 | ✅ **propre** | — |
| 4.3.2 `projets-detail` | 1384–1471 | ✅ **propre** | — |
| 4.3.3 `kanban` | 1472–1537 | ✅ **propre** | — |
| 4.3.4 `objectifs-liste/detail` | 1538–1601 | ✅ **propre** | — |
| 4.3.5 `habitudes` | 1602–1689 | ✅ **propre** | — |
| 4.3.6 `routines` | 1690–1795 | ✅ **propre** | — |
| 4.4.1 `calendrier-jour/semaine/mois` | 1799–1946 | ✅ **propre** | — |
| 4.4.2 `focus-mode` | 1947–2128 | ✅ **propre** | — |
| 4.5.1 `revues-jour/semaine/mois` | 2132–2312 | ✅ **propre** (quelques lignes courtes mais lisibles) | — |
| **4.5.2 `analytics`** | 2313–~2335 (tronc) | ❌ **cassé** | texte broyé dans `05-main.md` L 2313–2529 (pas de version propre connue) |
| **4.6.1 `bibliotheque-ressources`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 2533–2745 |
| **4.6.2 `cours-liste + cours-detail`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 2746–3216 |
| **4.7.1 `fiches-liste + fiches-detail`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 3220–3337 |
| **4.8.1 `flashcards`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 3340–4289 |
| **4.8.2 `qcm`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 4290–5508 |
| **4.9.1 `mode-coach`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 5512–6752 |
| **4.9.2 `mirror-cognitive`** | *absent* | ❌ **cassé / manquant** | texte broyé dans `05-main.md` L 6753–fin (fichier tronqué, L 6915) |

**Écrans 4.2.x** : la numérotation saute de 4.1 à 4.3 (pas de module 4.2 dans le pack 05 ni dans
`05-main.md`) — cohérent avec l'inventaire des 44 écrans (4.1 = Onboarding/Racine, 4.3 = Productivité
projets). Pas de manquant.

---

## 2. Diagnostic détaillé

### 2.1 Ce qui est **propre** dans le pack 05

**§4.1 → §4.5.1** (lignes 1233–2312) : texte fluide, format Markdown normal (paragraphe de ~80 colonnes).
Quelques lignes courtes apparaissent dans 4.5.1 (par ex. L 2133 : « périodique, doc §2.9 »), mais le
texte reste **complet et lisible** — ce n'est pas le broyage mot-à-mot de `05-main.md`.

§5 (Système de thèmes multi-couches) et §7 (Livraison finale) : **propres**, ajoutés par l'agent
`themes-curator` pendant la reconstitution (cf. `.memlog.md` : « Pack 05 reconstitué : §4 propre
(rejointure de 05-part2) + §5 v2… »).

### 2.2 Ce qui est **cassé** dans le pack 05

À partir de la **ligne 2313** (début de 4.5.2), le texte est **broyé** :

```
L 2313  d'ajustement par l'agent ») ;
L 2314  une `RoutineStep` du plan
L 2315  d'action → si l'étape
L 2316  **devient** une tâche, un
L 2317  `Button ghost` « En faire une
L 2318  tâche » (le plan d'action
```

Ce broyage est **identique** à ce qu'on trouve dans `05-main.md` L 2313–2529 : les 6 chunks du rédacteur
avaient cassé le texte en lignes d'un à deux mots. La reconstitution a **rejoint le bon endroit** pour
4.1–4.5.1, mais **4.5.2 et au-delà ont été broyés** parce que leur version propre n'existait nulle part :
- `05-p2.md` s'arrête **dans 4.1.2** (L 1264) ;
- les 6 `05-chunk*.txt` + fix-tail **n'existent plus** (supprimés, cf. `.memlog.md`).

**Les écrans 4.6–4.9.2 n'ont jamais été présents dans le pack 05** : ils n'existent que dans
`05-main.md`, qui est un broyage de ~4 300 lignes (L 2530–6915).

### 2.3 État de `05-main.md` (fichier source du broyage)

- L 1–2529 : §§ 1 à 4.5.2 — **propre** (identique au pack 05 pour 4.1–4.5.1 ; 4.5.2 broyé).
- L 2530–6915 : §§ 4.6 à 4.9.2 — **broyé** (un mot par ligne, 4 321 lignes courtes / 66 lignes
  normales sur cette plage).
- **Fichier tronqué** : `05-main.md` s'arrête en pleine phrase dans 4.9.2 (L 6915) :
  `… la saisie de l'ex` — le texte original de 4.9.2 est **incomplet** même dans `05-main.md`.

### 2.4 État de `05-p2.md` (partie 2 propre)

- Contient **frontmatter complet** + §1–§4.1.1 — **propre**.
- S'arrête **en pleine phrase** dans 4.1.2 (L 1264 : « répondre à **une seule** question : « Qu'est-ce »).
- **Ne contient pas** de version propre de 4.5.2 → 4.9.2.
- Les 4.6–4.9.2 de `05-p2.md` = absents (fichier stoppe à 4.1.2).

### 2.5 Chunks supprimés

Les 6 `05-chunk*.txt` + `05-fix-tail.txt` (ou équivalent) ont été **supprimés** lors de la
reconstitution (`.memlog.md` : « 8 débris (6 chunks + part2 + fix-tail) supprimés »). Leur contenu
était le §4 broyé de 4.4, 4.8 et divers fragments — **aucun texte propre**.

---

## 3. Liste exacte des écrans manquants/cassés dans le pack 05

| # | Écran | Statut dans pack 05 | Fichier source broyé (réf. ligne) | Remarques |
|---|---|---|---|---|
| 1 | 4.5.2 `analytics` | présent mais broyé L 2313–2335 | `05-main.md` L 2313–2529 (broyé) | **Aucune version propre connue** — à réécrire |
| 2 | 4.6.1 `bibliotheque-ressources` | absent | `05-main.md` L 2533–2745 | broyé ; à réécrire |
| 3 | 4.6.2 `cours-liste + cours-detail` | absent | `05-main.md` L 2746–3216 | broyé ; à réécrire |
| 4 | 4.7.1 `fiches-liste + fiches-detail` | absent | `05-main.md` L 3220–3337 | broyé ; à réécrire |
| 5 | 4.8.1 `flashcards` | absent | `05-main.md` L 3340–4289 | broyé ; à réécrire |
| 6 | 4.8.2 `qcm` | absent | `05-main.md` L 4290–5508 | broyé ; à réécrire |
| 7 | 4.9.1 `mode-coach` | absent | `05-main.md` L 5512–6752 | broyé ; à réécrire |
| 8 | 4.9.2 `mirror-cognitive` | absent | `05-main.md` L 6753–fin (tronqué) | broyé **ET** tronqué (L 6915 = dernière ligne du fichier) ; **à réécrire intégralement** |

**Total : 8 écrans cassés/absents dans le pack 05.**
**Écrans propres dans le pack 05 : 11 (4.1.1, 4.1.2, 4.3.1–4.3.6, 4.4.1, 4.4.2, 4.5.1).**

---

## 4. Plan de correction recommandé

### 4.1 Écrans 4.6–4.9.2 (le gros morceau)

**Il n'existe pas de version propre de 4.6–4.9.2 nulle part.**
Seul `05-main.md` (broyé) contient ce texte, et il est tronqué à 4.9.2.

**Deux options** :

**Option A — Réécrire 4.6–4.9.2** (recommandé, ~600–800 lignes propres)
- 4.6.1 : bibliothèque de ressources — 1 écran
- 4.6.2 : cours-liste + cours-detail — 2 écrans
- 4.7.1 : fiches-liste + fiches-detail — 2 écrans
- 4.8.1 : flashcards (FSRS) — 1 écran
- 4.8.2 : QCM — 1 écran
- 4.9.1 : mode-coach — 1 écran
- 4.9.2 : mirror-cognitive — 1 écran
- Sources : `ARCHITECTURE-SPINE.md` (AD-10, AD-11, AD-12), `adr-extract.md` (doc §2.11, §3, §13, §14,
  §17, §18), 05-p2.md §3 (composants disponibles), 05-design-system.md §3 (même).

**Option B — Débroyer `05-main.md` L 2530–6915**
- Faisable en réassemblage : chaque ligne d'un-mot de `05-main.md` correspond à un segment de texte
  original. Le texte est **complet** pour 4.6.1–4.9.1, mais **tronqué** pour 4.9.2.
- 4.9.2 devra être **réécrit** de toute façon (le broyage de `05-main.md` n'est pas fiable, et le
  fichier est coupé en pleine phrase).

**Recommandation** : **Option A** pour 4.6.1–4.9.1 (réécriture propre, ~500 lignes),
**Option A + B** pour 4.9.2 (vérifier ce qui reste dans `05-main.md` L 6753–6915 pour l'Objectif,
le Zones, et le DS, puis réécrire les sections manquantes).

### 4.2 Écran 4.5.2 `analytics` (broyé dans le pack 05, L 2313–2335)

- 4.5.2 est **présent** dans le pack 05 mais broyé (L 2313–2335, puis le texte saute à §5 L 2565).
- La version propre de 4.5.2 **n'existe nulle part** (05-p2 s'arrête à 4.1.2, les chunks sont supprimés).
- **Action** : réécrire 4.5.2 (~60–80 lignes, cf. doc §2.10, §18, `adr-extract.md`).
- **Note** : le texte broyé L 2313–2529 de `05-main.md` contient le contenu **complet** de 4.5.2
  (Zones, DS, États, Transitions, Notes responsive) — il peut servir de **guide de réécriture**,
  même s'il ne peut pas être copié tel quel.

### 4.3 Écran 4.1.2 (broyé dans le pack 05, L 1264)

- `05-p2.md` L 1264 : « répondre à **une seule** question : « Qu'est-ce » — broyé à la ligne 1264.
- `05-design-system.md` L 1263 : le 4.1.2 **est complet et propre** dans le pack 05 (vérifié ci-dessus).
- Pas d'action nécessaire : le pack 05 a déjà la bonne version.

### 4.4 Nettoyage post-correction

- Une fois 4.5.2–4.9.2 réécrits et intégrés dans le pack 05 :
  - Supprimer `05-main.md` (fichier broyé, inutile après correction).
  - Supprimer `05-p2.md` si son contenu est déjà fusionné (le frontmatter + §1–§4.1.1 sont dans le pack 05).
  - Vérifier que le §4 du pack 05 va de 4.1 à 4.9.2 sans trou (n° 4.2 absent = OK, c'est sauté dans l'inventaire).
  - Lancer `/ccg:verify-change` + `/ccg:verify-quality` sur `dimensions/05-design-system.md`.

---

## 5. Références de lignes (à utiliser pour la correction)

| Repère | Fichier | Lignes |
|---|---|---|
| Frontmatter pack 05 | `05-p2.md` | 1–31 |
| §4 propre (réf. 4.1–4.5.1) | `05-design-system.md` | 1213–2312 |
| 4.5.2 broyé (à remplacer) | `05-design-system.md` | 2313–2335 (trou) |
| 4.5.2 broyé (guide) | `05-main.md` | 2313–2529 |
| 4.6–4.9 broyé (guide) | `05-main.md` | 2530–6915 |
| 4.9.2 tronqué | `05-main.md` | 6753–6915 (fin de fichier) |
| §5 thèmes (propre, référence AD-17) | `05-design-system.md` | 2565–3011 |
| Inventaire 44 écrans (normatif §4) | `05-design-system.md` | 1213–1231 |
