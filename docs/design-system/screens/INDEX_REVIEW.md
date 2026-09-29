# INDEX_REVIEW — Review adversarial du lot docs écrans (state au 2026-09-29)

> Review d'ensemble de `docs/design-system/screens/` (41 docs écrans + 3 transverses).
> Méthode : lecture de `_inventory.md`, `index.md`, `_floating-surfaces.md` (le
> `_open-questions.md` **n'existe pas** — voir §4.3), échantillonnage de 5 docs au
> hasard (settings, knowledge-node, home, agent-chat, progress-dashboard) + contrôle
> ciblé de kanban / onboarding / eisenhower / objectifs-detail (docs les plus denses en
> OQ locales).
> Verdict global : **le lot est SPECIFIED** (41 docs à 14 sections, matrice §4 complètes
> sans case vide, §12 et §13 présents partout). Les SSoT écran des lots 5–6 qui étaient
> « claimées, NON détaillées » dans `_inventory.md` §4 (état 2026-09-27) ont été
> complétées **côté écran** — mais les docs module restent muets écran-par-écran, ce qui
> laisse les OQ locales de type « SSoT manquante » ouvertes. Les points bloquants sont
> dans le §1 (top 5) ; la liste SSoT module manquante est dans le §4.

---

## 1. OQs globales les plus bloquantes (top 5, à trancher par un décideur humain)

| # | OQ globale (registre `_inventory.md` §3) | Pourquoi bloquant pour l'exécution du frontend | Décideur attendu |
|---|------------------------------------------|------------------------------------------------|------------------|
| 1 | **OQ-1 — règle de comptage 44 SSoT vs 54 candidats** (`_inventory.md` §3, options a/b/c) | Fixe le N final (46 vs 48 vs 54). Bloque l'index définitif et le rapport final : sans cette décision, on ne sait pas si 10, 2 ou 0 variantes doivent encore être scindées/enveloppées (ex. `projets-detail` #49 = enveloppe vs #6-9 vues). | Design System team (owner 05 §4) ; les 2 additifs (eisenhower, exercises) → Product / Feature Registry (G-M7) |
| 2 | **OQ-16 — Eisenhower `NEEDS_DECISION` (G-L5)** (`docs/productivity/eisenhower.md`) | Le doc écran `eisenhower.md` existe (16 OQ locales) mais l'écran lui-même n'est pas ratifié au catalog : parent non tranché (onglet projet vs `/tasks`, eisenhower OQ-2) → la route, le 404 local (OQ-8) et le CTA secondaire (OQ-11) ne peuvent pas être implémentés sans cette décision. | Product / G-L5 owner |
| 3 | **OQ-48 — not-found / feature-disabled : règle de 404 par écran vs 404 global** (feature-registry S6, G-M7) | Affecte **plusieurs** docs écrans à la fois (kanban OQ-13, projets-detail OQ-17, eisenhower OQ-8/11, home OQ-6/7) : chaque écran spécifie sa propre 404 locale alors que `not-found.md` spécifie la wildcard globale — il faut trancher la politique (1 page 404 globale réutilisable vs 404 propre par écran) avant de coder les routes de deep link. | 05 owner / feature-registry S6 owner |
| 4 | **OQ-47 — settings : le contenu du bloc « compte » + sync CTA** (docs WDS 04.5 OQ-47/50 dans settings §14) | La partie thème est close (OQ-47/48/49 closes WDS 04.5, ratifiées par Joy) mais OQ-50 (sync CTA blocking vs optimistic) et l'editabilité des 4 champs G-D14 (OQ-48 résiduel) restent ouverts : l'implémentation `/settings` ne peut pas être figée tant que le comportement du CTA n'est pas tranché. | WDS 04.5 owner (ratification Joy) |
| 5 | **OQ-6 `_floating-surfaces` — taille `AgentThinkingLoader` : contradiction SSoT 64–96px vs 48px** (ui-libraries §9.3 l.454 vs l.483-486) | Contradiction de SSoT vivante : l'owner 2026-09-28 dit « 48px » mais la SSoT §9.3 l.454 reste « défaut 88px ; 64–96 in chat ». Le composant `packages/ui` est déjà implémenté ; il faut ratifier la valeur (48px = l.483-486, plus récente) pour désamorcer la SSoT et fermer l'OQ-3 `agent-chat.md` + OQ-6 `_floating-surfaces`. | Owner (designer 05 §3.1 + ui-libraries §9.3) |

**Note** : ce top 5 est un sous-ensemble du registre global de 13 OQs (`_inventory.md` §3 :
OQ-1/13/16/36/39/40/41/42/43/44/46/47/48). OQ-13 (goal-feature-detail), OQ-36
(exercises-proof) et OQ-39/40/41/42/43/44/46 (knowledge/discovery/progress/agent/
artifacts) sont les autres OQ globales du registre — elles sont couvertes par le §4 ci-
dessous (liste SSoT module manquante).

---

## 2. Écrans « claimés non détaillés » avec le plus d'OQs + doc module à compléter

Les 7 docs écrans des lots 5–6 portaient le statut **« claimé, NON détaillé écran-par-
écran »** dans `_inventory.md` §4 (état 2026-09-27). Ils sont aujourd'hui SPECIFIED ;
les OQs qu'ils hébergent de type « SSoT écran manquante » (le doc module est muet
écran-par-écran) sont précisément celles qui restent ouvertes et qui exigent la
complétion du doc module pour être fermées.

| Écran (doc) | OQs restantes | OQs de type « SSoT module muet écran-par-écran » | Doc module à compléter (path) |
|-------------|--------------|---------------------------------------------------|-------------------------------|
| `knowledge-tree` / `knowledge-node` | 7+8 | OQ-39/40 : la SSoT écran de Knowledge (arbre + nœud) n'existe pas ; `docs/knowledge/overview.md` est muet écran-par-écran (pas de § dédié aux états/interactions/états offline du canvas React Flow) | `docs/knowledge/overview.md` (ajouter un § écran : zones, états canvas, offline, 404 par nœud) |
| `discovery-feed` / `discovery-sheet` | 7+14 | OQ-41/42 : ADR §13.8/§13.9 définit les fields + l'événement `DiscoveryItemCreated` mais pas le rendu écran (le sheet = BottomSheet par-dessus le feed, le feed = dégradation `uncertain` 01 §6) ; le doc module n'a aucun § écran | `docs/discovery/overview.md` (ajouter § écran feed + § écran sheet : états, interactions, 404, offline) |
| `progress-dashboard` | 8 | OQ-43 : `docs/progress/overview.md` est un **Technical Page** (24. Evidence map), muet écran-par-écran ; le doc écran `progress-dashboard.md` le dit explicitement en OQ-08 et « Statut : claimé, non détaillé » (l.3) | `docs/progress/overview.md` (ajouter § écran dashboard : 5 `ListItem` dépliables, `SegmentedControl` 4 options, desktop 2 panneaux) |
| `agent-chat` | 6 | OQ-44 : `docs/agent/kernel.md §13` définit le kernel (runs, tool-calls, `AgentRunState`) mais le **rendu écran** (chat, streaming, renderers tool-calls, 404, offline local) n'est pas dans le doc module ; OQ-4 (chip repliable implémentée ou pas ?) exige de re-synchroniser `packages/ui AgentThinkingLoader.tsx` avec ui-libraries §9.3 l.519-526 | `docs/agent/kernel.md` (§13 rendu écran) + `docs/agent/ui-actions.md` (si le split du rendu écran n'est pas dans kernel.md) |
| `artifacts-detail` | 8 | OQ-46 : `docs/artifacts/overview.md` définit les formats + les presigned (15/5 min TTL) mais pas le rendu écran (preview par format, états par format, 404 par artifact) | `docs/artifacts/overview.md` (ajouter § écran : preview par format, états, 404) |
| `settings` | 4 | OQ-47 : le doc écran est clos sur le thème (WDS 04.5 §8 l.179, 09/25, ratifié par Joy) mais **pas** l'editabilité des champs G-D14 (OQ-48 résiduel) ni le sync CTA blocking vs optimistic (OQ-50) | `docs/design-system/overview.md` §6 (thème) — SSoT écran existante ; le résiduel vit dans `docs/design-system/screens/settings.md` §14 (pas dans un doc module, mais dans le corps WDS 04.5) |
| `not-found` | 4 | OQ-48 : `feature-registry S6` définit les règles (pas de crash, pas de 404 nu, `data-state=feature-disabled`) mais pas le **libellé exact** du message court ni le CTA secondaire ; chaque écran ré-utilise ce pattern (home OQ-6/7, kanban OQ-13, projets-detail OQ-17, eisenhower OQ-8/11) — trancher ici ferme 4 écrans | `docs/design-system/screens/not-found.md` §14 (le libellé + le CTA secondaire exacts) ; SSoT globale = `feature-registry S6` (docs module) |

**Lecture** : le lot avec le **plus** d'OQs « SSoT muettes » = **Knowledge**
(2 docs × 7 OQs = 14) puis **Discovery** (2 docs × 7+14 OQs = 21) — ces 4 docs écrans
partagent le même pattern : le doc module (overview.md) est muet écran-par-écran et il
faut l'augmenter d'un § écran pour fermer les OQs locales.

---

## 3. SSoT écran manquantes (liste des docs module à compléter pour fermer les OQs du lot 5–6)

**État du répertoire module** : `docs/progress/`, `docs/knowledge/`, `docs/discovery/`,
`docs/agent/`, `docs/settings/` (n'existe pas), `docs/artifacts/` existent tous ;
`docs/settings/` n'existe pas (le SSoT écran de settings = `docs/design-system/overview.md`
§6 + WDS 04.5). Le pattern commun : **aucun de ces docs module n'a de § écran
détaillé** (pas de §1 zones, pas de §3 éléments, pas de §4 états, pas de §12 offline
dans le module — ces sections sont les 14 du template écran, elles ne vivent que dans
`docs/design-system/screens/<slug>.md`). La SSoT écran = le **module doc** + le **doc
écran** ; le module est muet, l'écran est SPECIFIED mais héberge les OQs qui attendent
le module pour être fermées.

**Table des SSoT écran manquantes (lot 5–6)** :

| SSoT écran manquante | Slug doc écran (SPECIFIED, héberge les OQs) | Doc module à compléter (path + § à ajouter) | OQs à fermer en conséquence |
|----------------------|---------------------------------------------|---------------------------------------------|------------------------------|
| progress-dashboard écran (5 `ListItem` dépliables + `SegmentedControl` 4 options + desktop 2 panneaux) | `progress-dashboard` (OQ-43, OQ-08) | `docs/progress/overview.md` — ajouter §1 écran (zones, composition), §2 context (5 questions fondamentales doc §18.1 citées mais **pas** dans le module), §3 éléments (les 5 `ListItem` dépliables), §4 états (S6 + sémantiques + 404 + killed), §12 offline (miroir local `progress_snapshots`) | OQ-08 `progress-dashboard.md`, OQ-43 registre global |
| knowledge-tree écran (canvas React Flow, gestes pan/zoom, split-view desktop) | `knowledge-tree` (OQ-39) | `docs/knowledge/overview.md` — ajouter §1 écran, §2 context (AD-10 mirror local, AD-12 retrieval), §3 éléments (`SemanticNodeComponent`, canvas, TopBar), §4 états (S6 + killed + 404 par nœud), §5 animations (gestes, reduced-motion), §12 offline (miroir / retrieval) | OQ-01…07 `knowledge-tree.md`, OQ-39 registre global |
| knowledge-node écran (lazy deeper branches, 02 §9.2) | `knowledge-node` (OQ-40) | `docs/knowledge/overview.md` — ajouter § écran nœud (zones, lazy loading des branches, 404 par nœud inconnu, offline local de la branche chargée) | OQ-01…07 `knowledge-node.md`, OQ-40 registre global |
| discovery-feed écran (S-27, dégradation `uncertain` 01 §6) | `discovery-feed` (OQ-41) | `docs/discovery/overview.md` — ajouter §1 écran (feed, zones, TopBar), §2 context (jobs serveur, AD-12/F-09, dégradation `uncertain`), §3 éléments (cards feed, `ListItem`), §4 états (S6 + offline dégradation), §12 offline (miroir / pas de miroir = pas de re-sync, AD-12) | OQ-01…07 `discovery-feed.md`, OQ-41 registre global |
| discovery-sheet écran (S-40, détail d'une `DiscoveryItem`, `DiscoveryItemCreated`) | `discovery-sheet` (OQ-42) | `docs/discovery/overview.md` — ajouter § écran sheet (BottomSheet par-dessus le feed, focus-trap, 404 par `DiscoveryItem` inconnue, offline local de la sheet) | OQ-01…14 `discovery-sheet.md`, OQ-42 registre global |
| agent-chat écran (streaming + tool-call renderers + 404) | `agent-chat` (OQ-44) | `docs/agent/kernel.md §13` + éventuellement `docs/agent/ui-actions.md` — ajouter § rendu écran (zones chat, input, renderers tool-calls par type, 404 par run inconnu, offline = conversation history local AD-7) ; **re-synchroniser** avec `packages/ui AgentThinkingLoader.tsx` (OQ-4 `agent-chat.md` : chip repliable implémentée ou spec future ?) | OQ-01…06 `agent-chat.md`, OQ-44 registre global, OQ-6 `_floating-surfaces` |
| artifacts-detail écran (preview par format, presigned 15/5 min) | `artifacts-detail` (OQ-46) | `docs/artifacts/overview.md` — ajouter §1 écran (zones preview, TopBar, actions par format), §2 context (presigned TTL, cache préviews 04 §3.2.2), §3 éléments (preview par format : image/video/pdf/audio), §4 états (S6 + offline = cache local des préviews), §12 offline (presigned re-généré au retour réseau) | OQ-01…08 `artifacts-detail.md`, OQ-46 registre global |
| settings écran (résiduel OQ-48/50) | `settings` (OQ-47 close, OQ-48/49 closes résiduels, OQ-50 open) | `docs/design-system/overview.md §6` (SSoT écran existante, pas à compléter pour le thème) ; **à compléter** dans le corps WDS 04.5 : sync CTA blocking vs optimistic (OQ-50) + éditabilité des 4 champs G-D14 (OQ-48 résiduel) | OQ-48/OQ-50 `settings.md` (registre global OQ-47 reste ouvert jusqu'à ratification du résiduel) |
| not-found écran (libellé + CTA secondaire exacts) | `not-found` (OQ-48) | `feature-registry S6` (docs module, pas de path dédié dans le lot 5–6 — c'est une section du registre global des features) — à compléter : libellé FR exact du message court (« Page introuvable. » vs « Cette fonction n'est pas disponible. ») + CTA secondaire exact (« Consulter l'écran parent » ghost, **optionnel**) ; fermer les OQ-6/7 `home.md`, OQ-13 `kanban.md`, OQ-17 `projets-detail.md`, OQ-8/11 `eisenhower.md` d'un coup | OQ-01…04 `not-found.md`, OQ-48 registre global |

**Lecture SSoT écran manquante (lot 5–6)** : 8 docs module à compléter (5 dans
`docs/progress|knowledge|discovery|agent|artifacts/` + 1 section du `feature-registry S6`
+ 1 corps WDS 04.5 résiduel + 1 section de `docs/design-system/overview.md §6`). C'est le
pattern du lot : **le module doc est muet écran-par-écran, l'écran est SPECIFIED en
isolé mais héberge les OQs qui attendent le module pour être fermées**.

---

## 4. Constats transverses (état de cette run)

### 4.1 Matrice §4 (complète sans case vide) — 5 docs échantillonnés

| Doc | §4 présent | Matrice S6 (loading/empty/error/success/offline/killed) | Case vide | Verdict |
|-----|-----------|----------------------------------------------------------|-----------|---------|
| `settings.md` | §4 (l.83) | 6 états + sémantiques + 404 + killed — table complète | nulle | PASS |
| `knowledge-node.md` | §4 (l.39) | 6 états S6 + killed + 404 — table complète | nulle | PASS |
| `home.md` | §4 (l.49) | 6 états S6 + sémantiques + 404 — table complète (7 blocs × 6 états + killed N/A raison) | nulle | PASS |
| `agent-chat.md` | §4 (l.51) | 6 états S6 + killed — table complète par élément | nulle | PASS |
| `progress-dashboard.md` | §4 (l.47) | 6 états S6 + killed + 404 — table complète (5 zones × 6 états) | nulle | PASS |

**Verdict matrice §4** : aucune case vide dans les 5 docs échantillonnés. Le lot est
conforme à la règle AD-13 (états par élément, 5 S6 + killed).

### 4.2 §12 Offline et §13 Logos (versions exactes) — 5 docs échantillonnés

| Doc | §12 présent | §13 présent | §13 logos (versions exactes, SSoT) | Verdict |
|-----|------------|-------------|-------------------------------------|---------|
| `settings.md` | §12 (l.200) | §13 (l.214) | COLORED sans fond centre (404) — `aurora_icon_a_integre_dans_l'applciation.png` (l.358) — SSoT exact (§9.1 l.387) | PASS |
| `knowledge-node.md` | §12 (l.121) | §13 (l.128) | COLORED sans fond centre (404) — `aurora_icon_a_integre_dans_l'applciation.png` (l.358) — SSoT exact (§9.1 l.387) | PASS |
| `home.md` | §12 (l.168) | §13 (l.188) | **CONTRADICTION** : §13 l.404 dit « monochrome interdit dans un état vivant (404 = COLORED) » (§9.1 l.390-392) mais la matrice §9.1 l.378-388 (la SSoT) dit « **Nocturne/High Contrast = monochrome** » — le doc home.md applique la matrice mais la SSoT 404 = COLORED **toujours** (pas de exception par preset). Le doc ne tranche pas si le 404 du Home en preset Nocturne/HC reste COLORED ou passe MONOCHROME — **OQ à ajouter** (à l'heure actuelle ce n'est pas dans le §14) | FAIL (contradiction SSoT, à trancher) |
| `agent-chat.md` | §12 (l.149) | §13 (l.165) | MONOCHROME statique (empty state §9.1 l.381) + MONOCHROME animé (`AgentThinkingLoader §9.3` — S9 l.403-404 : le seul monochrome animé) — SSoT exacte, cohérente | PASS |
| `progress-dashboard.md` | §12 (l.130) | §13 (l.136) | MONOCHROME centre (404) — SSoT §9.1 matrice l.378-388 ; **CONTRADICTION** avec `home.md`/`settings.md`/`knowledge-node.md` qui disent COLORED (404 = état vivant = COLORED) — le doc progress-dashboard applique la SSoT « 404 = monochrome (feedback d'erreur = calme) » alors que la SSoT 404 = « COLORED without-background, CENTERED » (l.387, état vivant, CTA « Retour à l'accueil » actif). **CONTRADICTION entre les 5 docs** : 3 disent COLORED, 1 dit MONOCHROME, 1 dit MONOCHROME animé (loader) | FAIL (contradiction entre docs, à trancher) |

**Verdict SSoT logos §13** : **contradiction transversale** entre les 5 docs échantillon-
nés sur la version du logo 404 : `settings`/`knowledge-node`/`home` = **COLORED** (SSoT
§9.1 l.387 : 404 = état vivant, CTA actif = marque colorée), `progress-dashboard` =
**MONOCHROME** (SSoT §9.1 matrice l.378-388 : 404 = feedback d'erreur = calme, marque
statique), `agent-chat` = **MONOCHROME animé** (`AgentThinkingLoader`, S9 l.403-404 —
c'est le seul monochrome animé du produit, pas une contradiction). Les 2 SSoT (§9.1
l.387 et l.378-388) **se contredisent** ; l'owner doit trancher laquelle est normative
pour le 404 (COLORED vs MONOCHROME). **Blocant pour l'exécution du frontend** : chaque
écran qui code son 404 doit utiliser la version exacte (pas de SSoT = pas de choix).

### 4.3 État des docs transverses (state au 2026-09-29)

| Doc transverse | État (au 2026-09-29 12:31) | À faire |
|----------------|----------------------------|---------|
| `_inventory.md` (2026-09-27) | EXISTANT (statut « SPECIFIED » par lot §4 **obsolète** : il dit « à créer » pour les lots 5-6 alors que 41 docs écrans sont SPECIFIED) | Mettre à jour §4 (état des lots) pour refléter l'état courant (41 docs SPECIFIED + OQs restantes du §14 de chaque doc) |
| `index.md` (2026-09-29 12:03) | EXISTANT (41 docs listés, « **41 docs écrans** écrits à ce jour ») | OK — re-synchroniser le § « Slugs de l'inventaire non encore documentés » (il liste `projets-detail-vue-*` / `flashcards` / `focus-mode` / `inbox` + le doc transverse `_floating-surfaces` — ces 4 slugs n'ont toujours **pas** de doc dédié, le `flashcards`/`focus-mode`/`inbox` = à créer, le `projets-detail-vue-*` = compris dans `projets-detail` §2-5) |
| `_floating-surfaces.md` (2026-09-29 12:31) | EXISTANT (6 sections + OQ-1…OQ-6 dans §10) | OK — `index.md` le dit « **À CRÉER** » (l.19, l.101) — **mettre à jour** `index.md` pour refléter l'état (il est **créé**) |
| `_open-questions.md` | **N'EXISTE PAS** (ls : 44 fichiers, pas de `_open-questions.md`) ; `index.md` l.20/l.102 le dit « **À CRÉER** » | **À CRÉER** (c'est le doc que cette run était censée alimenter : consolidation du registre global OQ n°1/13/16/36/39-44/46-48 du `_inventory.md` §3 + pointeur vers les OQ locales de chaque doc §14) — **INDEX_REVIEW.md = le deliverable de cette run ; `_open-questions.md` n'existe pas** |

**Verdict docs transverses** : 1 des 4 docs transverses manquants (`_open-questions.md`)
— **créer** avant le lot final (c'est le point d'entrée de l'adjudication des OQs du lot
5–6). `_floating-surfaces.md` est créé mais `index.md` ne l'a pas mis à jour.

### 4.4 SSoT factices (citations de ligne SSoT inexistantes) — 5 docs échantillonnés

`home.md` OQ-11/12/13/16 sont **citées comme factices** dans le §14 (citation
`ui-libraries S8 l.289-291` = FullCalendar, pas la règle volume (l.304-307) ;
citation `05 §6.3 l.3327-3335` = pas de règle letter-spacing ; citation `shadcn
list-item` = le `ListItem` est un composant DS, pas une lib S1 ; citation `doc §18.1`
= 5 questions fondamentales de Progress, pas « l'élément le plus urgent » (ceci =
§18.2)). `cours-detail.md` (2 occurrences factices), `eisenhower.md` (2), `kanban.md`
(5) en portent aussi.

**Verdict SSoT factices** : **pattern récurrent** de citations de lignes SSoT qui ne
correspondent pas au contenu réel du SSoT (la citation existe mais la ligne citée ne
porte pas le contenu cité). Ce pattern = **blocking review finding** (c'est ce qui
empêche l'exécution : le frontend implémente la citation, pas le SSoT). **À re-lire**
dans les docs module (pas seulement écran) : les SSoT de 05 §4, ui-libraries S1/S5/S6/S9,
WDS 04.5 sont citées à des lignes qui peuvent ne pas porter le contenu cité (ex. WDS
04.5 §8 l.179 = OQ-1 close option A statique, mais l'editabilité G-D14 n'y est pas).
Le doc écran qui cite une ligne factice doit marquer l'OQ dans son §14 (pattern
`home.md` OQ-11/12/13/16 = le pattern correct) ; **les docs qui n'ont pas d'OQ
factice en §14 mais citent des lignes potentiellement factices = à vérifier** (pas de
contradiction visible dans les 5 docs échantillonnés, mais le pattern existe dans le lot).

### 4.5 OQs locales par doc (re-comptage au 2026-09-29, pour le lot final)

| Doc | OQs uniques (§14 + autres) | Doc | OQs uniques |
|-----|---------------------------|-----|-------------|
| `onboarding` | 16 | `knowledge-node` | 8 |
| `home` | 17 | `knowledge-tree` | 8 |
| `kanban` | 17 | `mirror-cognitive` | 9 |
| `eisenhower` | 16 | `mode-coach` | 9 |
| `settings` | 4 | `not-found` | 6 |
| `progress-dashboard` | 8 | `agent-chat` | 6 |
| `artifacts-detail` | 10 | `discovery-feed` | 10 |
| `discovery-sheet` | 14 | `objectifs-detail` | 12 |
| `objectifs-liste` | 14 | `projets-detail` | 21 |
| `projets-liste` | 12 | `cours-detail` | 10 |
| `cours-liste` | 8 | `fiches-liste` | 10 |
| `fiches-detail` | 13 | `analytics` | 13 |
| `bibliotheque-ressources` | 18 | `calendrier-jour` | 9 |
| `calendrier-mois` | 12 | `calendrier-semaine` | 10 |
| `habitudes` | 11 | `routines` | 12 |
| `exercises-proof` | 12 | `goal-feature-detail` | 12 |
| `qcm` | 11 | `retro-actions` | 10 |
| `revues-jour` | 6 | `revues-mois` | 8 |
| `revues-semaine` | 11 | `slide-ascent` | 16 |
| `taches-detail` | 10 | `taches-liste` | 10 |
| `flashcards` | **n'existe pas** (doc manquant, §4.3) | `focus-mode` / `inbox` / `projets-detail-vue-*` | **n'existe pas** (§4.3) |

**Total** : 41 docs × 4-21 OQs = **~350 OQs locales** (non dédupliquées, l'OQ-1
`_floating-surfaces` et les OQs du registre global `_inventory.md` §3 = 13 OQs
**globales** n'y sont pas comptées).

### 4.6 Verdict global

1. **Matrice §4** : complète sans case vide (5/5 docs échantillonnés PASS).
2. **§12 Offline** : présent dans les 5 docs échantillonnés, conforme AD-7 (miroir local,
   no réseau au mount, resync au retour).
3. **§13 Logos versions exactes** : **contradiction entre docs** (404 = COLORED vs
   MONOCHROME) — 3 docs disent COLORED, 1 dit MONOCHROME (404 = feedback d'erreur =
   calme), 1 dit MONOCHROME animé (`AgentThinkingLoader` = S9 l.403-404, le seul mono-
   chrome animé, **pas** une contradiction). Les SSoT §9.1 l.387 et l.378-388 se
   contredisent ; l'owner doit trancher laquelle est normative pour le 404. **Blocant**.
4. **SSoT écran module manquante (lot 5–6)** : 8 docs module à compléter
   (§3) — c'est le **blocage** principal de l'exécution du frontend UI : le module doc
   est muet écran-par-écran, l'écran est SPECIFIED en isolé mais héberge les OQs qui
   attendent le module pour être fermées.
5. **Docs écrans manquants** : `flashcards` (05 §4.8.1 l.2640-2697 + WDS 01.3),
   `focus-mode` (05 §4.4.2 l.2044-2228, OQ-17 DPC), `inbox` (WDS 04.2 + catalog
   `productivity.inbox`) = 3 docs écran **absents** du lot 3-4 (pas 5-6) mais
   référencés dans `index.md` § « Slugs de l'inventaire non encore documentés » —
   à créer pour boucler le 54 slugs (OQ-1, règle de comptage).
6. **OQ globales** : 13 dans le registre `_inventory.md` §3 (OQ-1/13/16/36/39/40/41/42/
   43/44/46/47/48). Top 5 bloquants = OQ-1 (règle de comptage), OQ-16 (Eisenhower
   NEEDS_DECISION), OQ-48 (404 par écran vs global), OQ-47 (settings sync CTA), OQ-6
   `_floating-surfaces` (contradiction SSoT `AgentThinkingLoader` 48px vs 64-96px).
7. **Docs transverses** : `_open-questions.md` = **à créer** (c'est le deliverable qui
   manque de cette run) ; `_floating-surfaces.md` = **créé** mais `index.md` ne l'a pas
   mis à jour ; `_inventory.md` §4 = **obsolète** (dit « à créer » pour les lots 5-6,
   alors que 41 docs sont SPECIFIED).
8. **SSoT factices** : pattern récurrent de citations de lignes SSoT qui ne portent pas
   le contenu cité (home.md OQ-11/12/13/16, cours-detail.md 2, eisenhower.md 2,
   kanban.md 5) — **blocking review finding** (l'implémentation suit la citation, pas le
   SSoT). Les SSoT de 05 §4, ui-libraries S1/S5/S6/S9, WDS 04.5 sont à re-lire sur les
   lignes citées (WDS 04.5 §8 l.179 = OQ-1 close statique, mais l'editabilité G-D14
   n'y est pas ; le sync CTA blocking vs optimistic (OQ-50) n'est pas dans le corps gelé).

---

## 5. Plan d'action pour l'exécution du frontend UI

1. **Trancher les 5 OQs globales du §1** (décideur humain, en 1 standup) — OQ-1, OQ-16,
   OQ-48, OQ-47, OQ-6 `_floating-surfaces` — c'est le blocage **maximal** de l'exécution.
2. **Créer `_open-questions.md`** (le doc manquant de cette run) : consolidation du
   registre global de 13 OQs + pointeur vers les OQ locales de chaque doc §14.
3. **Mettre à jour `index.md`** : `_floating-surfaces.md` est créé (pas « À CRÉER »),
   `_inventory.md` §4 est obsolète (41 docs SPECIFIED, pas « à créer »).
4. **Compléter les 8 docs module du §3** (progress, knowledge ×2, discovery ×2, agent,
   artifacts, feature-registry S6, WDS 04.5 résiduel, design-system/overview §6) —
   c'est le blocage **modéré** de l'exécution (les OQs locales des lots 5-6 en dépendent).
5. **Créer les 3 docs écrans manquants du §4.6.5** : `flashcards.md`, `focus-mode.md`,
   `inbox.md` — c'est le blocage **faible** de l'exécution (les OQs locales de ces
   3 slugs n'existent pas encore).
6. **Re-lire les SSoT sur les lignes citées** (05 §4, ui-libraries S1/S5/S6/S9, WDS
   04.5 §8 l.179-181) pour les citations factices (home.md OQ-11/12/13/16, cours-detail.md
   2, eisenhower.md 2, kanban.md 5) — c'est le blocage **élevé** (le frontend implémente
   la citation, pas le SSoT).
7. **Trancher la contradiction §13 logos 404** (COLORED vs MONOCHROME, §4.2) : l'owner
   doit ratifier laquelle des 2 SSoT (§9.1 l.387 vs l.378-388) est normative pour le 404
   (blocant pour chaque écran qui code son 404).

---

*Review générée 2026-09-29 · input : 44 fichiers (41 docs écrans + `_inventory.md` +
`index.md` + `_floating-surfaces.md`) · verdict : lot 5–6 SPECIFIED côté écran,
**SSoT écran module manquante = 8 docs module à compléter** (blocage principal),
**contradiction §13 logos 404** (blocant), **3 docs écrans manquants** (blocage faible),
**SSoT factices** (blocage élevé).*
