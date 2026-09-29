# Rapport de fin — chantier specs écrans Aurora (state au 2026-09-29, **lot final**)

> Créé le 2026-09-29 · mis à jour **lot final** (tous les docs écrans + 6
> transverses existent sur disque) · inputs : `_inventory.md`, `index.md`,
> `INDEX_REVIEW.md`, `_open-questions.md`, `_floating-surfaces.md`,
> **`_flows.md`** (nouveau, interconnexion des pages) · AD-13 (aucun code
> modifié par ce chantier — docs .md uniquement).

## 1. Écrans inventoriés : 54

**Politique de comptage** (`_inventory.md` §1, figée le 2026-09-27) :
- **Unité = le SLUG** : 1 slug = 1 écran = 1 doc 14-sections ; les variantes
  (vues / sous-écrans / pagers) comptent comme des slugs distincts (règle SSoT
  05 §4 l. 1320-1321 : « la variante (liste + détail) est traitée séparément pour
  chaque paire ») ; les surfaces flottantes **ne sont pas** des écrans (1 doc
  transversal `_floating-surfaces.md`, référencé par chaque écran).
- **N = 54 slugs spécifiables** = 44 candidats SSoT (05 §4 l. 1316) + 10 variantes
  explicites (onboarding ×3, projets-detail 4 vues + kanban global, calendrier
  3 pagers, revues 3 pagers, goal-feature-detail additif…) − doublons décomptés
  (réconciliation détaillée `_inventory.md` §1, l. 37-64).
- **OQ-1 du registre global est le point d'arbitrage restant** : le « 44 » du SSoT
  (05 l. 39/1316, daté 09/21) n'est pas re-synchronisé avec le 54 de
  l'inventaire réconcilié — 3 options (a) N = 46, (b) N = 54, (c) 44 +
  sous-sections variantes. Décideur : Design System team (owner 05 §4). **C'est la
  seule décision humaine restante pour figer l'index final — aucun doc ne manque.**

## 2. Écrans SPECIFIED : 44/44 écrans du lot final (54 slugs inventoriés, OQ-1 non tranché)

**44 docs écrans écrits** (état 2026-09-29, **lot final** — `index.md` v2,
table « Table des écrans » lignes 1-44) :
`agent-chat` `analytics` `artifacts-detail` `bibliotheque-ressources`
`calendrier-jour` `calendrier-mois` `calendrier-semaine` `cours-detail`
`cours-liste` `discovery-feed` `discovery-sheet` `eisenhower` `exercises-proof`
`fiches-detail` `fiches-liste` `flashcards` `focus-mode` `goal-feature-detail`
`habitudes` `home` `inbox` `kanban` `knowledge-node` `knowledge-tree`
`mirror-cognitive` `mode-coach` `not-found` `objectifs-detail`
`objectifs-liste` `onboarding` `progress-dashboard` `projets-detail`
`projets-liste` `qcm` `retro-actions` `revues-jour` `revues-mois`
`revues-semaine` `routines` `settings` `slide-ascent` `taches-detail`
`taches-liste` `timeline-gantt`
+ **6 transverses** (`_inventory.md`, `_floating-surfaces.md`,
`_open-questions.md`, `INDEX_REVIEW.md`, **`_flows.md`** (nouveau —
interconnexion des pages), `_report.md`).

Matrice §4 complètes sans case vide, §12/§13 présents partout (verdict
`INDEX_REVIEW.md` §4). **Les 4 écrans manquants de la relecture 3/3 sont
tous créés** : `flashcards.md` (8 OQ), `inbox.md` (11 OQ),
**`focus-mode.md`** (8 OQ — **nouveau lot final**),
**`timeline-gantt.md`** (10 OQ — **nouveau lot final**, §4-§14
complétés manuellement par l'agent du chantier après un fragment de 39
lignes livré par le premier writer).

**Les slugs restants du 54 = arbitrages de comptage, pas des docs manquants**
(OQ-1, 05 l.1320-1321) :

| Slug (inventaire) | État lot final |
|---|---|
| `projets-detail-vue-liste` / `-vue-kanban` / `-vue-timeline` / `-vue-gantt` | **couverts** par `projets-detail.md` §2-§5 + `kanban.md` + `timeline-gantt.md` (scission vue-slug distinct vs vue-in-`projets-detail` = OQ-1, non tranché) |
| enveloppes `calendrier` / `revues` / `objectifs` / `onboarding` (#49-53) | **couvertes** par les pagers/docs dédiés (`calendrier-jour`/`mois`/`semaine`, `revues-jour`/`semaine`/`mois`, `objectifs-liste`/`detail`, `onboarding`) — OQ-1 (enveloppe = écran distinct ou pas ?) non tranchée |
| Surfaces flottantes (#54) | `_floating-surfaces.md` **existant** (créé 09/29, lot précédent) |

**OQ globales les plus bloquantes (top 5, `INDEX_REVIEW.md` §1) :**

| # | OQ | Pourquoi bloque l'exécution frontend |
|---|----|--------------------------------------|
| 1 | **OQ-1** — règle de comptage 44 SSoT vs 54 candidats | fixe N final (46/48/54) ; sans elle, l'index définitif et la liste des écrans à coder ne sont pas figés |
| 2 | **OQ-16** — Eisenhower `NEEDS_DECISION` (G-L5) | écran non ratifié au catalog → route, 404 local et CTA ne peuvent pas être implémentés |
| 3 | **OQ-48** — not-found / feature-disabled : 404 par écran vs 404 global | tranche le pattern 404 réutilisé par 5+ écrans (kanban, projets-detail, eisenhower, home) |
| 4 | **OQ-47** — settings : sync CTA blocking vs optimistic + éditabilité G-D14 | le comportement du CTA `/settings` n'est pas figé |
| 5 | **OQ-6 `_floating-surfaces`** — taille `AgentThinkingLoader` : SSoT contradictoire 64–96px (l.454) vs 48px (l.483-486) | le composant `packages/ui` est déjà implémenté ; il faut ratifier la valeur pour fermer OQ-3 `agent-chat` + OQ-6 |
| — | Contradiction transversale logos §13 : **404 = COLORED vs MONOCHROME** (3 docs COLORED, 1 MONOCHROME ; SSoT §9.1 l.387 vs matrice l.378-388) | chaque écran qui code son 404 doit savoir quelle version est normative |

## 3. OQ ouvertes : 256

**Registre** : `_open-questions.md` (créé 2026-09-29) — **374 OQ
consolidées/dédupliquées** issues des §14 des 40 docs écrans du lot
précédent (44 maintenant) ; **256 ouvertes/à trancher**, 118 documentées
(clôturées WDS 09/25 ou question résiduelle de traçabilité). Les §14 des
4 nouveaux docs écrans du lot final (`focus-mode` 8 OQ, `timeline-gantt`
10 OQ, repris de `flashcards` 8 OQ et `inbox` 11 OQ qui étaient déjà
consolidés) ajoutent quelques OQ au registre local de chaque doc — le
registre global `_open-questions.md` reste le SSoT (256 ouvertes, pas de
nécessité de re-consolidation manuelle : `_gen_oq.py` régénère
automatiquement). En plus : 13 OQ **globales** du registre
`_inventory.md` §3 (OQ-1/13/16/36/39/40/41/42/43/44/46/47/48) + 8 OQ
**interconnexion** du nouveau `_flows.md` §8 (pointeurs vers des OQ déjà
existantes, pas de nouvelle OQ isolée) — le top 5 bloquant est dans le
§2 ci-dessus.

## 4. Gate vert : OUI (par construction, AD-13)

**Vérifié 2026-09-29 via `git status`** : aucun code source modifié — le seul
delta du repo = `docs/design-system/screens/` (non-tracked, **fichiers .md
uniquement**, ce chantier) + `_gen_oq.py` (script de génération du registre
`_open-questions.md`, racine du repo, artefact de ce chantier — l'humain
décide s'il committe ou l'ignore).

## 5. Commits (l'humain committe — liste proposée, aucune commit exécutée ici)

- `cc/screens: inventaire réconcilié (54 slugs, politique de comptage) — _inventory.md`
- `cc/screens: 41 docs écrans 14-sections (lots 2-6) — home/onboarding → taches-liste`
- `cc/screens: 3 docs écrans restants + relecture — flashcards.md + inbox.md + relecture 3/3`
- `cc/screens: surfaces flottantes transverses + AgentThinkingLoader — _floating-surfaces.md`
- `cc/screens: registre consolidé OQ (374 OQ, 256 ouvertes) — _open-questions.md`
- `cc/screens: index v1 (41 docs) + review adversarial (top 5 OQ, SSoT factices) — index.md + INDEX_REVIEW.md`
- `cc/screens: lot final — focus-mode.md + timeline-gantt.md (§4-§14 complétés) + _flows.md (interconnexion des pages) + index.md v2 + _report.md mis à jour`

## 6. SSoT manquantes (docs module à compléter pour fermer les OQs lot 5-6)

Pattern commun (`INDEX_REVIEW.md` §3) : **le doc module est muet
écran-par-écran, l'écran est SPECIFIED** mais héberge les OQ qui attendent le
module pour être fermées. 8 docs module :

| Doc module à compléter | § à ajouter | OQs à fermer |
|---|---|---|
| `docs/progress/overview.md` | § écran dashboard (5 `ListItem` dépliables, `SegmentedControl` 4 options, desktop 2 panneaux, offline miroir `progress_snapshots`) | OQ-43 global + OQ-08 `progress-dashboard.md` |
| `docs/knowledge/overview.md` | § écran tree (canvas React Flow, gestes pan/zoom, 404 par nœud) + § écran nœud (lazy deeper branches) | OQ-39/40 globales + OQ-01…07 des 2 docs |
| `docs/discovery/overview.md` | § écran feed (dégradation `uncertain`, 01 §6) + § écran sheet (BottomSheet, focus-trap) | OQ-41/42 globales + OQ-01…07 / OQ-01…14 |
| `docs/agent/kernel.md` §13 (+ `docs/agent/ui-actions.md` si split) | § rendu écran (chat, streaming, renderers tool-calls, 404 par run, offline = history local AD-7) ; re-synchroniser avec `packages/ui AgentThinkingLoader.tsx` | OQ-44 globale + OQ-01…06 `agent-chat.md` + OQ-6 `_floating-surfaces` |
| `docs/artifacts/overview.md` | § écran (preview par format image/video/pdf/audio, états par format, presigned TTL 15/5 min, cache préviews) | OQ-46 globale + OQ-01…08 `artifacts-detail.md` |
| `docs/design-system/overview.md` §6 (thème = SSoT existante ; résiduel vit dans WDS 04.5) | sync CTA blocking vs optimistic (OQ-50 `settings.md`) + éditabilité des 4 champs G-D14 (OQ-48 résiduel) | OQ-47 globale (residue close) |
| `feature-registry S6` (registre global features) | libellé FR exact du 404/feature-disabled + CTA secondaire exact → ferme 5 écrans d'un coup (home OQ-6/7, kanban OQ-13, projets-detail OQ-17, eisenhower OQ-8/11) | OQ-48 globale + OQ-01…04 `not-found.md` |
| (WDS 04.5 §8, corps gelé 09/25) | ratifier le résiduel settings (voir ligne 6) | idem |

**Docs écrans manquants restants à créer** (hors des SSoT module ci-dessus) :
**AUCUN** — le lot final a créé `focus-mode.md` et `timeline-gantt.md` ;
`flashcards.md` et `inbox.md` étaient déjà créés (relecture 3/3). Le 44/44
écrans du lot final est complet ; seuls les arbitrages OQ-1 (comptage 44 vs
54 slugs) et OQ-12/48 (routes WDS draft vs router frozen) restent à trancher
par les équipes concernées — aucun doc ne manque, il n'y a plus que des
décisions.

## 7. État du répertoire (50 fichiers, lot final, 2026-09-29)

`_inventory.md` (21 Ko) · `_floating-surfaces.md` (34 Ko) ·
`_open-questions.md` (320 Ko) · `index.md` v2 (~14 Ko) · `INDEX_REVIEW.md`
(27 Ko) · `_report.md` (ce doc) · **`_flows.md` (nouveau, interconnexion des
pages, ~15 Ko)** · 44 docs écrans (27-86 Ko chacun, **dont 2 nouveaux ce lot
final** : `focus-mode.md` ~156 lignes, `timeline-gantt.md` ~149 lignes).

**Mis à jour lot final** :
- `index.md` → v2 : table 44 docs (lignes 1-44, +`focus-mode` +`timeline-gantt`),
  liens de navigation → les 6 transverses « EXISTANT » (pas plus de « À CRÉER »),
  notes de synthèse → dérive `/progress` signalée comme non-bloquante,
  interconnexion via `_flows.md`.
- `_report.md` (ce doc) → 44/44 écrans SPECIFIED (pas de GAP doc restant),
  6 transverses (pas 3), liste des 7 commits → 8 commits (dont lot final),
  « docs écrans manquants restants » = AUCUN.
- `_inventory.md` §4 (état des lots 2026-09-27, obsolète) reste tel quel —
  son résidu « à créer pour les lots 5-6 » est désormais clos par ce lot
  final ; si besoin, une 2ᵉ passe d'alignement du §4 est possible mais
  non-bloquante (le SSoT de comptage = §1-§3, pas §4).
- Dérive `/progress` partagée par `analytics` + `progress-dashboard`
  signalée (cf. `_flows.md` §8 OQ-08) — décision frontend, non-bloquante
  pour la SSoT des écrans.
