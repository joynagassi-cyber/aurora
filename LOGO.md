# LOGO — Rapport d'ingénierie : génération de logos vectoriels (SVG) sans images pixelisées

> Rapport autonome et exploitable. Toutes les affirmations issues de la littérature sont
> sourcées par ID arXiv / nom de document. Les éléments qui **n'apparaissent pas dans le
> corpus** sont explicitement marqués `⚠ non trouvé dans le corpus`.
> Les éléments qui sont des **concepts du projet LOGO** (pas de la littérature) sont marqués
> `[PROJET]`.
>
> **Marqueurs de statut** (convention AFFICHE.md) : **[VALIDÉ]** = déjà décidé dans le projet
> LOGO ; **[À ÉVALUER]** = recommandé par le corpus ou à explorer, non encore tranché.

## Légende des sources

Les sources de ce rapport sont les 7 fichiers du répertoire `sources_logo/`. `2404.14368v1.md`
(Graphic Design with LMM / Graphist, qui couvre la génération de SVG) se trouve dans
`sources_affiche/` ; il est miné dans AFFICHE.md §2.4 (z-order IOPR) et §7 (piège #10).

### Note méthodologique sur le corpus (à lire en premier)

| Fichier fourni | Contenu réel | Statut pour LOGO |
|---|---|---|
| `2505.23740v3.md` | LayerPeeler (vectorisation raster→SVG couche par couche) | ✅ Utilisé |
| `2604.20730v3.md` | Render-in-the-Loop (génération SVG avec boucle de rendu visuelle) | ✅ Utilisé |
| `2501.03992v1.md` | NeuralSVG (représentation implicite text-to-vector) | ✅ Utilisé |
| `2503.16421v3.md` | **MagicMotion** (génération vidéo, contrôle de trajectoires) — **et NON SVGDreamer** | ⛔ Exclu (hors sujet, vidéo) |
| `2007.11301v3.md` | DeepSVG (représentation hiérarchique SVG, pré-treatment paths) | ✅ Utilisé |
| `2602.02820v1.md` | From Tokens to Numbers (modélisation continue des nombres SVG, SVGFloat) | ✅ Utilisé |
| `0081.md` | IterMeme (MLLM unifié, représentation de layout robuste) | ✅ Utilisé (layout) |

- **SVGDreamer** est cité comme *baseline* dans [2604.20730] et [2501.03992] mais n'est pas un
  document autonome du corpus.
- **SVGen** (ACM MM '25, RL/GRPO pour la génération de SVG), **OmniSVG**, **LLM4SVG**,
  **StarVector**, **Chat2SVG**, **ReasonSVG** sont cités en références dans [2604.20730] et
  [2602.02820] mais ne font pas l'objet d'un document autonome du corpus.
- **LogoLoom** : `⚠ non trouvé dans le corpus`.
- **vectx** : `⚠ non trouvé dans le corpus` — c'est un concept `[PROJET]` (couche sémantique
  qui compile vers SVG). Ce rapport le positionne en l'ancrant sur les structures du corpus.

Le principe central partagé par tout le corpus : **l'IA produit du SVG (code / représentation
sémantique / nombres) plutôt que des pixels.** C'est le fondement de LOGO.

---

## 1. Résumé exécutif

LOGO s'appuie sur quatre piliers validés par le corpus, tous orientés « écrire du SVG, pas de
pixels » :

1. **Séparation structure / paramètres** — décrire la forme (hiérarchie de paths, commandes,
   couleurs) indépendamment des nombres géométriques ; les nombres restent des valeurs continues
   de première classe, pas des tokens discrets `[2602.02820, 2007.11301]` **[VALIDÉ]**.
2. **Découpage en couches / séparation sémantique-géométrie** — un logo = un graphe de calques
   ordonné (relations d'occlusion) dont chaque path a un sens autonome ; c'est ce qui rend le
   résultat *éditable* et non unamas de pixels `[2505.23740, 2501.03992]` **[VALIDÉ]**.
3. **Boucle de rendu comme garde-fou** — rendre le SVG intermédiaire, vérifier la différence
   visuelle avant d'accepter le fragment suivant ; filtrer les répétitions dégénérées
   `[2604.20730]` **[VALIDÉ]**.
4. **Post-traitement systématique** — optimisation SVGO, canonicalisation des paths,
   vérification SSIM, consolidation et bornage des nombres `[2602.02820, 2007.11301]` **[VALIDÉ]**.

**Validé (décisions du projet, confirmées par le corpus)** : le paradigme « code SVG /
représentation sémantique », le découpage en calques, le post-traitement SVGO, la validation
perceptuelle, la couche vectx comme intermédiaire sémantique, le périmètre initial
(wordmarks, monogrammes, icônes simples).
**À implémenter / À évaluer (spécifique à LOGO)** : la sortie multi-formats, la correction
optique, l'export multi-ratios (1:1 / 4:1), la déclinaison de palettes — `[PROJET]` **[À ÉVALUER]**.

---

## 2. Méthodes et stratégies

Chaque méthode : nom (ID arXiv) → principe → intérêt pour LOGO → statut (**[VALIDÉ]** = déjà
décidé dans le projet ; **[À ÉVALUER]** = recommandé par le corpus, à explorer).

### 2.1 Séparation structure / paramètres — modélisation continue des nombres `[2602.02820]`
- **Principe.** Un SVG est décomposé en deux séquences parallèles : (i) une séquence *tokenique*
  qui conserve la syntaxe symbolique avec des placeholders `[NUM]` à la place de chaque littéral
  numérique, (ii) une séquence *flottante* qui stocke les valeurs. La structure (commandes,
  balises) est apprise par le langage ; les nombres (coordonnées, rayons, opacités) sont régressés
  en continue. On évite la fragmentation d'un littéral `123.456` en 7 tokens et la perte de
  précision des quantisations de type OmniSVG. `[2602.02820]`
- **Intérêt LOGO.** C'est LA base du principe « l'IA écrit du SVG » : la géométrie reste exacte
  et continue, l'éditeur peut manipuler les nombres sans artefacts de quantisation. C'est aussi ce
  qui rend possible le format binaire compact SVGFloat (voir §5.4).
- **Statut.** **[VALIDÉ]** — fondement de l'architecture LOGO (nombres en continu, pas de bins).

### 2.2 Représentation hiérarchique shapes → commandes `[2007.11301]`
- **Principe.** Une image vectorielle est l'ensemble de *paths* ; chaque path est une séquence de
  commandes de dessin ; l'ordre des paths est **arbitraire** (invariance par permutation). On
  encode d'abord chaque forme séparément, puis on raisonne sur les relations entre formes.
  `[2007.11301]`
- **Intérêt LOGO.** Un logo est typiquement une poignée de formes (icône + mot + liseré). La
  hiérarchie forme/commande donne une structure éditable et animable ; l'invariance par
  permutation justifie de normaliser/canonicaliser les paths plutôt que de compter sur l'ordre
  d'apparition (voir §6).
- **Statut.** **[VALIDÉ]** — structure canonique d'un SVG LOGO.

### 2.3 Graphe de couches (layer graph) avec relations d'occlusion `[2505.23740]`
- **Principe.** Le VLM construit un graphe dirigé `G=(V,E)` où chaque sommet = une région de
  couleur plate, avec attributs `color`, `label` (sémantique ou géométrique) et
  `part_of_object` ; arêtes `occlude(v1,v2)` (dirigée) et `interrupted_shape(v1,v2)`
  (non dirigée). Un calque « non-occlus » = sommet qui n'est cible d'aucune arête `occlude`.
  `[2505.23740]`
- **Intérêt LOGO.** C'est le schéma de données qui sépare la *sémantique de la géométrie* :
  « bande du chapeau (bleue) est partie de l'objet 'chapeau' et occlue la couronne ». Permet de
  générer un logo comme une **hiérarchie de calques cohérente et éditable**, pas une image
  aplatie. La même idée, en plus abstrait, est la couche vectx `[PROJET]`.
- **Statut.** **[VALIDÉ]** comme structure de données ; le graphe est le cœur du vectx (§5.5).

### 2.4 Pelure autorégressive (décomposition couche par couche) `[2505.23740]`
- **Principe.** On identifie et on retire les calques les plus hauts (non-occlus), on
  vectorise chaque calque retiré avec un outil de vectorisation, on reconstruit le SVG en
  réempilant dans l'ordre inverse. Le processus est itératif et auto-référentiel : la sortie
  d'une étape devient l'entrée de la suivante. `[2505.23740]`
- **Intérêt LOGO.** Stratégie de **décomposition en calques** générique (explicitement
  conservée par les règles de filtrage). Pour un logo, elle fournit une recette pour **extraire la
  structure en couches** d'une source (maquette, croquis, ou image de référence) plutôt que de
  générer du pixel. Limite connue : erreurs stochastiques qui s'accumulent → prévoir une
  **vérification de succès après chaque étape** (recommandé par les auteurs eux-mêmes).
- **Statut.** **[À ÉVALUER]** — à tester si l'on veut réutiliser une maquette raster existante
  comme source ; n'est pas le chemin principal (le chemin principal est génération sémantique).

### 2.5 Boucle de rendu / auto-feedback visuel (Render-in-the-Loop) `[2604.20730]`
- **Principe.** Reformuler la synthèse SVG en processus de dessin *étapé* : à chaque étape `t`,
  le modèle émet un fragment de code `Ct` (un path), on rasterise le canevas cumulé
  `It = R(C1⊕…⊕Ct)`, et on réinjecte `It` comme contexte visuel pour l'étape suivante. Le modèle
  fait « main » (code) ET « œil » (canevas). On apprend « comment tracer » (différence entre
  canevas courant et objectif) et « quand s'arrêter » (token `<END>`). `[2604.20730]`
- **Intérêt LOGO.** C'est la méthode générique de génération de structure la plus puissante du
  corpus pour produire du SVG *propre et éditable* (contrairement aux méthodes d'optimisation qui
  font du « stroke-stacking »). Le feedback visuel dense résout les relations d'occlusion et le
  bon ordre des calques — exactement ce qu'il faut pour un logo où l'icône passe devant/d'arrière
  le mot.
- **Statut.** **[VALIDÉ]** — pilier n°3 du LOGO ; à implémenter dans le générateur de structure.

### 2.6 Découpage fin des paths (decomposition topologique) `[2604.20730]`
- **Principe.** Avant de générer/apprendre, on décompose les `<path>` longs en sous-paths :
  (1) *subpath extraction* (couper aux commandes de début non-continues, `M`), (2) *analyse de
  topologie* (graphe de dépendance : inclusion = trou via règle de remplissage ; intersection
  spatiale si opacité ≠ 1 pour éviter les artefacts de mélange de couleurs), (3) *fusion des
  composantes connexes* pour regrouper ce qui est visuellement couplé. `[2604.20730]`
- **Intérêt LOGO.** Rend chaque élément distinct (corps du projecteur, lentille, faisceau…)
  atomique et séquentiel, ce qui augmente la densité du feedback visuel et la qualité du SVG final.
  Technique de prétraitement directe à réutiliser dans le pipeline LOGO.
- **Statut.** **[VALIDÉ]** — étape de prétraitement de chaque `<path>` complexe.

### 2.7 Verify-then-accept / garde-fou d'inférence (Render-and-Verify) `[2604.20730]`
- **Principe.** Avant d'accepter un fragment candidat `Ĉt` : on rend le canevas hypothétique
  `Ît` et on applique (a) *vérification de différence visuelle* (si le diff pixel < seuil `ϵ`, le
  fragment n'apporte rien → rejet) et (b) *vérification de répétition* (similarité de chaîne >
  `τsim` → rejet de boucle). Échec → ré-échantillonnage adaptatif ; après `Kmax` échecs →
  forçage du token `<END>`. `[2604.20730]`
- **Intérêt LOGO.** Garde-fou d'inférence léger et robuste (insensible au réglage fin des
  seuils). Pour LOGO : garantit que chaque path ajouté **contribue réellement au rendu** du logo
  et filtre les tracés en double / hors-canevas. Seuil de référence du corpus : `ϵ=0.001`,
  `τsim=0.98`, rendu intermédiaire à 224×224.
- **Statut.** **[VALIDÉ]** — garde-fou systématique sur chaque fragment généré.

### 2.8 Représentation implicite ordonnée + régularisation par dropout imbriqué `[2501.03992]`
- **Principe.** Toute la scène SVG est encodée (une poignée de formes, chaque forme = 4 courbes
  de Bézier cubiques concaténées fermées + couleur RGB). Une régularisation par *dropout
  imbriqué* (on tronque aléatoirement les formes au-delà d'un indice) pousse les formes *tôt* à
  porter le sens grossier et les formes *tard* à ajouter les détails. Résultat : un SVG **ordonné
  où chaque path a une signification autonome**, et un contrôle en inférence (complexité,
  palette, ratio d'aspect). `[2501.03992]`
- **Intérêt LOGO.** C'est le contrepoids aux sorties « over-parameterized / pixel-like » du
  texte→vector. Le contrôle de **palette par conditionnement de couleur de fond** et le contrôle du
  **ratio d'aspect (1:1 vs 4:1)** sont directement exploitables pour décliner un logo (marque
  claire / obscure, horizontal / carré).
- **Statut.** **[À ÉVALUER]** — si l'on veut un générateur paramétrique implicite plutôt qu'un
  LLM qui émet du code XML ; apporte des leviers de déclinaison forts mais nécessite un
  réseau dédié (pas un LLM off-the-shelf).

### 2.9 Génération de SVG par LLM/MLLM (méthode générique, citée) `[2604.20730, 2602.02820]`
- **Principe.** Produire directement du code SVG (balises XML + coordonnées de paths) de façon
  auto-régressive, à partir d'un texte ou d'une image. Variétés du corpus : StarVector, OmniSVG,
  LLM4SVG, Chat2SVG, SVGen (avec RL), InternSVG. `[2604.20730, 2602.02820]`
- **Intérêt LOGO.** C'est le « générateur » de structure sémantique. Le corpus montre que le
  simple LLM *open-loop* « dessine à l'aveugle » (géométries hallucinées, calques mal ordonnés) ;
  c'est pourquoi on l'accompagne de la boucle de rendu (§2.5) et du post-traitement (§3).
  Voir pièges §7.
- **Statut.** **[VALIDÉ]** comme paradigme ; les variantes off-the-shelf (StarVector, OmniSVG,
  LLM4SVG, Chat2SVG, SVGen) sont **[À ÉVALUER]** en tant que *générateurs* — le choix retenu est
  un LLM/MLLM piloté par boucle de rendu + verify-then-accept, pas un modèle « blind drawing ».
  **LogoLoom** : `⚠ non trouvé dans le corpus` — statut inconnu, à ne pas retenir comme
  référence.

### 2.10 Couche sémantique vectx `[PROJET]`
- **Principe (conception projet).** Décrire des formes (`Frame`, `circle`, `gridInside`) et des
  thèmes (tokens de style) qui **compilent vers du SVG**.
- **Ancrage corpus.** Ce concept n'existe pas sous le nom « vectx » dans la littérature
  (`⚠ non trouvé`), mais il est **exactement la synthèse** de trois idées du corpus : la
  hiérarchie formes/commandes de [2007.11301], la séparation structure/nombres de [2602.02820],
  et le graphe de couches sémantique de [2505.23740]. La couche vectx est donc un **DL / DSL
  intermédiaire sémantique** qui descend vers le SVG canonique. Schéma cible en §5.5.
- **Statut.** **[VALIDÉ]** comme couche intermédiaire ; le schéma cible est à finaliser (§5.5).

---

## 3. Techniques d'ingénierie et pipelines

### 3.1 Pipeline de bout en bout cible pour LOGO (synthèse des méthodes du corpus)

```
[1] Intent (texte/description, ou image de référence)
   │
   ▼
[2] Couche sémantique vectx [PROJET]
   → spécification de structure : formes (Frame, circle, gridInside…),
     thème (tokens de style : couleurs, ratios, épaisseurs), contraintes géométriques.
   (ancrage : hiérarchie [2007.11301] + graphe de couches [2505.23740])
   │
   ▼
[3] Compilation vectx → SVG canonique
   → séparation structure / nombres : tokens de syntaxe + nombres continus
     ([NUM] placeholders + stream flottant) [2602.02820]
   → découpage topologique des paths longs [2604.20730]
   → canonicalisation des paths (voir §6) [2007.11301]
   │
   ▼
[4] Génération / affinement (générateur de structure)
   → LLM/MLLM écrit le code SVG, en boucle de rendu visuel
     (canevas intermédiaire → feedback → fragment suivant) [2604.20730]
   → ou pelure couche par couche si source raster [2505.23740]
   │
   ▼
[5] Garde-fou d'inférence : Render-and-Verify
   → diff visuel + détection de répétition + ré-échantillonnage [2604.20730]
   │
   ▼
[6] Post-traitement
   → consolidation (fusion stream tokens + nombres → SVG valide),
     arrondi à précision fixe, bornage des coordonnées dans le canevas [2602.02820]
   → optimisation SVGO [2602.02820]
   → vérification perceptuelle (rendu original vs transformé, contrôle SSIM) [2602.02820]
   │
   ▼
[7] Export multi-formats [PROJET]
   → SVG final + déclinaisons (palette claire/obscure, ratios 1:1 / 4:1) [2501.03992]
   → formats dérivés (PNG raster pour aperçu, ICO, etc.)
```

### 3.2 Prétraitement standard du SVG (à réutiliser tel quel)
Source [2602.02820 §2.3] et [2007.11301 App. B] :

- **Simplification SVGO en premier.** Garantit que les transformations affines s'appliquent
  directement aux coordonnées des paths (indispensable avant le scaling).
- **Scaling récursif vers un canevas canonique.** Calcul d'un facteur d'échelle global appliqué à
  *tous* les attributs numériques (coordonnées, longueurs, épaisseurs de traits). Cible du
  corpus : `[-M, M]²` avec `M = 512` (CNM) ou `256×256` (DeepSVG).
- **Parsing/scaling/reconstruction des paths** via la librairie `svg.path` (traitement robuste des
  commandes complexes).
- **Contrôle qualité perceptuel.** On rend l'original ET le transformé en raster (via
  `cairosvg`), on calcule le **SSIM** entre les deux, et on **rejette** tout échantillon avec
  `SSIM < 0.99` ou toute valeur numérique sortant de `[−M, M]`. Ce « gate » de qualité est une
  pratique à adopter dans LOGO : tout post-traitement doit être prouvé neutre visuellement.

### 3.3 Protocole de vérification d'inférence (Render-and-Verify)
Source [2604.20730 §2.3, App. B] :

- À chaque fragment candidat `Ĉt` :
  1. Rendre `Ît = R(C1:t−1 ⊕ Ĉt)` (canevas 224×224, rendu fidèle à la spec W3C via `CairoSVG`).
  2. `diff(Ît, It−1) < ϵ` ? → rejeter (apport visuel négligeable : re-tracé, forme occultée,
     élément hors canevas).
  3. `similarité(Ĉt, Ct−1) > τsim` ? → rejeter (boucle de répétition).
  4. Échec → ré-échantillonner (température / nucléus légèrement relevés) jusqu'à un fragment
     validé ; après `Kmax` échecs → forcer `<END>`.
- Le mécanisme est un **filtre de dégénérescence**, pas un optimiseur de qualité ; il est stable
  sur un large intervalle de seuils (seuils de référence `ϵ=0.001`, `τsim=0.98`).

### 3.4 Post-traitement et consolidation
Source [2602.02820 §2.6] :

- L'inférence produit **deux** flux : une séquence de tokens (avec `[NUM]`) et une séquence de
  nombres normalisés. Le **SVG CONSOLIDATOR** parcourt les tokens ; à chaque `[NUM]` il consomme
  le prochain nombre, **dénormalise** par le facteur de bornage `M`, **arrondit** à une précision
  décimale fixe, **clippe** dans `[-M, M]`, puis réinsère. Résultat : un unique SVG valide.
- **Recommandation LOGO :** conserver ce contrat de sortie (structure ASCII + nombres bornés et
  arrondis) comme invariant de test unitaires du compilateur vectx→SVG.

### 3.5 Vectorisation de sources raster (option, si on part d'une image)
- Outils cités : **VTracer** et **Potrace** (systèmes classiques non-ML), **Recraft** (outils de
  vectorisation, intégration code). `[2602.02820, 2505.23740]`
- La pelure de LayerPeeler (§2.4) fournit la **structure en couches** là où Potrace/Illustrator
  donnent des formes **fragmentées** sur les zones occlues. Pour LOGO, préférer une source
  vectorielle/structurée ; utiliser la vectorisation uniquement pour récupérer la géométrie brute
  d'une maquette, puis la *re-structurer* en couches sémantiques.

### 3.6 Text→path (wordmarks) et typographie vectorielle
- Le corpus **référence** (sans détailler) la synthèse de polices vectorielles :
  **DeepVecFont / DeepVecFont-v2** et **Word-as-image pour typographie sémantique** (dans les
  bibliographies de [2604.20730] et [2501.03992]). DeepSVG montre la **génération de glyphes**
  class-conditionnés avec **cohérence de style sur un set de glyphes** `[2007.11301 §4.4]`.
- `⚠ Les règles détaillées text→path et de correction optique ne sont pas dans le corpus.`
  Pour LOGO, le wordmark = texte converti en paths (contour de glyphe) pour être éditable et
  indépendant de la police installée ; le monogramme = une/des lettres stylisées en formes
  vectorielles. Ces deux sont au **périmètre initial** `[PROJET]`.

### 3.7 Export multi-formats `[PROJET]`
- `⚠ Non trouvé dans le corpus` comme procédure (le corpus produit du SVG, des formats
  raster via `cairosvg` pour la validation, et le binaire SVGFloat).
- LOGO doit définir : export SVG (production), rendu PNG aperçu (CairoSVG), et éventuellement
  ICO/PDF. Le contrôle **ratio d'aspect 1:1 vs 4:1** de NeuralSVG `[2501.03992]` est la technique
  de déclinaison (carré / horizontal) d'un même logo.

### 3.8 Déclinaisons par contrôle en inférence
- **Palette dynamique :** conditionner la génération sur une couleur de fond cible → le même
  asset produit une palette qui s'adapte (clair/obscur) `[2501.03992 §4.4]`.
- **Complexité :** tronquer le nombre de formes (1, 4, 8, 16…) pour décliner icône minimaliste vs
  version détaillée `[2501.03992]`.
- **Ratio d'aspect :** réémettre les formes pour 1:1 ou 4:1 plutôt que d'étirer naïvement
  `[2501.03992]`.
- Ces trois sont des **leviers de déclinaison** d'un logo de marque — très pertinent pour LOGO.

---

## 4. Systèmes, frameworks et bibliothèques recommandés

> **Statut** : **[VALIDÉ]** = déjà retenu dans le projet LOGO ; **[À ÉVALUER]** = recommandé par
> le corpus, à trancher. **Licence** : les licences ne sont pas précisées dans le corpus ; les
> valeurs listées sont marquées `(GK = connaissance générale, non issue du corpus)`.
> **Maturité / stars GitHub** : non précisées dans le corpus ; marquées `(GK)` quand connues.

| Outil | Rôle dans LOGO | Rôle dans le corpus | Licence | Maturité (GK) | Statut |
|---|---|---|---|---|---|
| **SVGO** (svgo.dev) | Optimisation/minification du SVG en post-traitement | Prétraitement obligatoire avant scaling [2602.02820] | MIT (GK) | Stable, très utilisé (GK) | **[VALIDÉ]** (corpus + projet) |
| **cairosvg** (cairosvg.org) | Rendu SVG→raster (validation perceptuelle, aperçu, boucle de rendu) | Rendu à 224×224 [2604.20730] ; QC SSIM [2602.02820] | LGPL/GPL (GK) | Stable, utilisé en production (GK) | **[VALIDÉ]** (corpus + projet) |
| **svg.path** (PyPI) | Parse/échelle/reconstruction des path data | Pipeline de prétraitement [2602.02820] | MIT (GK) | Léger, stable (GK) | **[VALIDÉ]** (corpus + projet) |
| **VTracer** (visioncortex) | Vectorisation raster→SVG (source raster) | Baseline classique [2602.02820] | Apache-2.0/MIT (GK) | Stable, très utilisé (GK) | **[VALIDÉ]** (corpus + projet) |
| **Potrace** (potrace.sourceforge.net) | Vectorisation raster→SVG (contours) | Baseline classique [2602.02820] | GPL (GK) | Référentiel historique (GK) | **[VALIDÉ]** (corpus + projet) |
| **Bibliothèque DeepSVG** (github.com/alexandre01/deepsvg) | Manipulation / représentation des SVG, animation par interpolation | Outil open source du paper [2007.11301] | non spécifiée (vérifier) | Prototype de recherche (GK) | **[À ÉVALUER]** |
| **CNM** (github.com/mikeogezi/CNM) | Code de référence modélisation continue des nombres + reader/writer SVGFloat | Le paper lui-même [2602.02820] | non spécifiée (vérifier) | Prototype de recherche (GK) | **[À ÉVALUER]** |
| **Recraft** (recraft.ai) | Outil de vectorisation de qualité (intégration code) | Utilisé dans LayerPeeler [2505.23740 App. B] ; cité aussi dans [0081] | Commercial (GK) | API payante, produit de la recherche seulement (GK) | **[À ÉVITER]** en production (piège §7.2) |
| **DiffVG / rasterisateurs différentiables** | Optimisation des primitives vectorielles | Cités comme fondation des méthodes d'optimisation [2501.03992, 2604.20730] | non spécifiée (corpus) | Recherche (GK) | **[À ÉVALUER]** |
| **vectx (couche sémantique)** | DSL de formes + thèmes qui compile vers SVG | Concept `[PROJET]`, ancré sur [2007.11301, 2602.02820, 2505.23740] | — (n'existe pas encore) | Concept projet | **[VALIDÉ]** comme couche à construire |

Recommandations :
- **Noyau éprouvé par le corpus pour le pipeline** : `SVGO` + `svg.path` + `cairosvg`
  (prétraitement, manipulation, validation). C'est le socle le plus cité et **[VALIDÉ]**.
- **Vectorisation** : `VTracer`/`Potrace` pour récupérer la géométrie d'une source raster
  **[VALIDÉ]** ; ne pas s'appuyer sur une API payante (Recraft) en production.
- **À construire** : le compilateur vectx→SVG canonique et le lecteur/écrivain SVGFloat
  (inspiré du code CNM **[À ÉVALUER]**).
- **À évaluer avant adoption** : bibliothèque DeepSVG, code CNM, DiffVG — vérifier licence et
  maturité avant de les brancher dans le pipeline.

---

## 5. Schémas de données et structures

> Chaque schéma indique sa source (corpus ou `[PROJET]`) et son statut. Les structures
> **canoniques** (5.1, 5.2, 5.8) sont **[VALIDÉ]** comme cibles de compilation ; le vectx (5.5)
> est **[VALIDÉ]** à construire ; SVGFloat (5.4) est **[À ÉVALUER]**.

### 5.1 Représentation canonique d'un SVG (hiérarchie formes/commandes) `[2007.11301]` — **[VALIDÉ]**
- Une image = ensemble de `NP` paths. Chaque path `Pi = (Si, fi, vi)` :
  - `Si` : séquence de `NC` commandes ;
  - `fi ∈ {0,1,2}` : propriété de remplissage ;
  - `vi ∈ {0,1}` : visibilité.
- **Commandes retenues** (tab. 1 de DeepSVG) : `<SOS>`, `m` (move), `l` (ligne), `c`
  (Bézier cubique), `z` (fermer), `<EOS>`. Liste d'arguments fixe à 6 réels
  `(qx1, qy1, qx2, qy2, x2, y2)` ; argument inutilisé = `-1`. Padding à `NP`/`NC` fixes avec
  éléments invisibles pour le traitement parallèle.
- **Exemple (corps du projeteur, fig. 2 de [2604.20730]) :** un path complexe contenant corps +
  lentille + faisceau est découpé en sous-paths atomiques avant génération.

### 5.2 Graphe de couches (layer graph) `[2505.23740]` — **[VALIDÉ]**
Schéma JSON du corpus (extrait du prompt H.1) :

```json
{
  "nodes": [
    { "id": "N1", "description": "character head skin", "color": "peach" },
    { "id": "N2", "description": "upper hat body", "color": "blue", "part_of_object": "hat" },
    { "id": "N4", "description": "star decoration on hat", "color": "gold", "part_of_object": "hat" }
  ],
  "edges": [
    { "source": "N2", "target": "N1", "relationship": "occludes" },
    { "source": "N4", "target": "N2", "relationship": "occludes" },
    { "source": "N7", "target": "N2", "relationship": "interrupted_shape" }
  ]
}
```

- **Règles d'attribution (du corpus) :**
  - Chaque tache de couleur plate continue = un nœud distinct (ne pas fusionner).
  - `occlude(A,B)` : A recouvre B (dirigée, définit l'ordre de profondeur).
  - `interrupted_shape(A,B)` : A et B partagent couleur + concept, séparés par un occluseur ;
    sans lui ils formeraient une entité continue.
  - Calque non-occlus = nœud qui n'est **cible d'aucune** `occlude`.
  - Attribut `part_of_object` regroupe les régions d'un même objet sémantique.
  - Fond blanc global = **pas** un nœud ; les détails internes (pupilles, highlights) = nœuds.
- **Sortie VLM par itération :** `{ G, Pg, {Bi, Pi} }` = graphe mis à jour + légende globale +
  boîte englobante & légende par instance.

### 5.3 Séquence de dessin bouclée (Render-in-the-Loop) `[2604.20730]` — **[VALIDÉ]**
- Session complète `S` = alternance : condition `P` (texte ou image de référence), puis
  `C1, I1, C2, I2, …, Cn, In`, et `⟨END⟩`.
- `It = R(C1 ⊕ … ⊕ Ct)` : rasterisation du canevas cumulé après le fragment `t`.
- Le modèle conditionne la prédiction de `Ct+1` sur **tout** l'historique (précédent + canevas
  `It`). Comparer `It` à `P` apprend « quand s'arrêter ».
- **Format de formation (ex. fig. S5 du corpus) :** `[User] description` →
  `[Assistant] <path …/>` → *canevas rendu I1* → `[Assistant] <path …/>` → *canevas I2* →
  `[Assistant] <END>`.

### 5.4 Format binaire SVGFloat `[2602.02820]` — **[À ÉVALUER]**
- Flux unique ASCII/binaire imbrié : la syntaxe de structure reste en ASCII, **toutes** les
  valeurs numériques sont stockées comme floats bruts (`float32` 4 octets, `float16`/`bfloat16`
  2 octets).
- **NaN-boxing** : l'opcode de commande de path (M, L, C, A) est encodé dans les bits de mantisse
  d'une valeur NaN, suivi des paramètres flottants → un seul flux homogène.
- Performance du corpus (variante `float16`) : **−42 %** de taille vs SVG brut, **−19 %** vs SVG
  gzippé, perte de fidélité visuelle négligeable.
- Intérêt LOGO : stockage/transmission compacte des paramètres géométriques sans perte.

### 5.5 Couche sémantique vectx `[PROJET]` (schéma cible, ancré au corpus) — **[VALIDÉ]** à construire
> Concept projet. `⚠ « vectx », « Frame », « gridInside », « tokens de thème » ne sont pas dans le
> corpus ; ils sont construits ici en assemblant les structures 5.1/5.2/5.4.`

Définition cible d'un logo sémantique avant compilation :

```jsonc
// vectx spec (cible) → compile vers SVG canonique (§5.1) + nombres continus (§5.4)
{
  "theme": {                      // "tokens" de style [PROJET]
    "palette": [ "#1a1a1a", "#d4af37" ],
    "aspect": "1:1",              // 1:1 | 4:1  (contrôle NeuralSVG §3.8)
    "weight": 0.5, "corners": "sharp"
  },
  "scene": {                      // = graphe de couches (§5.2)
    "layers": [
      { "id": "L1", "type": "Frame",      "style": "outline",
        "params": { "w": 224, "h": 224 } },
      { "id": "L2", "type": "circle",     "part_of": "monogram",
        "params": { "cx": 112, "cy": 112, "r": 70 } },
      { "id": "L3", "type": "gridInside", "part_of": "monogram",
        "params": { "cells": 3 } }
    ],
    "occludes": [ ["L3","L2"], ["L2","L1"] ]   // ordre de calques (§5.2)
  }
}
```

- `Frame` = contenant (cadre du logo) ; `circle` = primitive géométrique ; `gridInside` =
  subdivision de grille d'un motif (ex. monogramme par cases). Chaque type **compile** vers les
  commandes de §5.1 (un `circle` → 4 arcs → Bézier cubiques, cf. §5.8). Les `params` sont les
  **nombres continus** de §2.1/§5.4. Le `theme` fournit la palette/ratios/épaisseurs.
- C'est cette couche qui porte la **séparation sémantique/géométrie** et qui rend le logo
  **éditable** : on change un token de thème (couleur, ratio) et on recompile, sans retoucher
  les coordonnées.

### 5.7 Propriétés de style (tokens de thème) `[PROJET]`
Propriétés de style vectorielles attendues dans le vectx (concepts `[PROJET]`, ancrés sur les
structures du corpus) :
- **Couleurs** : palette de la charte (héritage du niveau supérieur — cf. AFFICHE §2.5 pour le
  mécanisme de charte racine + thème par document) ; attributs SVG `fill` / `stroke` /
  `stroke-width` ; opacité.
- **Typographie** (si le logo porte du texte) : famille de police, graisse, interlettrage ;
  mais dans LOGO le texte est converti en **paths** (contours de glyphe, §6.4) — la typographie
  vectorielle n'est plus un attribut de rendu mais une **géométrie**.
- **Traits (strokes)** : épaisseur, style (plein / pointillé), jonctions ; les traits fins sont
  sensibles au ratio d'aspect (cf. §3.8 NeuralSVG).
- **Grilles et symétries** : contraintes géométriques (grille, axe de symétrie, ratio canonique
  1:1 / 4:1) portées par le `theme`.

`⚠` Le corpus ne détaille pas un schéma de tokens de style vectoriel ; ce §5.7 est une
construction `[PROJET]` ancrée sur les règles géométriques de [2007.11301] (grille, symétrie,
canonicalisation §6.1) et les contrôles de déclinaison de [2501.03992] (§3.8).

### 5.8 Primitives géométriques → commandes SVG (conversion canonique) `[2007.11301]` — **[VALIDÉ]**
| Forme de base | Équivalent path (corpus) |
|---|---|
| rectangle / ligne / polyline / polygon | sequence de `l` (lignes) |
| cercle / ellipse | 4 commandes d'arc → converties en Bézier cubiques |
| commande `A` (arc elliptique) | décomposée en Bézier cubiques (pas conservée en `A`) |

**Pourquoi `A` → Bézier (argument du corpus) :** les flags d'arc (`large-arc`, `sweep`) rendent
les formes **discontinues** par rapport à leurs arguments, ce qui dégrade l'animation/l'interpolation.
On convertit (paramétrisation en centre + plage angulaire, points de contrôle via l'approximation
de Schneider). **Toute forme courbe de LOGO doit être émise en Bézier, jamais en `A`.**

---

## 6. Règles de conception

> Le corpus fournit des règles **géométriques/structurelles** fortes ; les règles typographiques
> fines (wordmarks/monogrammes/optique) sont partiellement couvertes — indiqué au fil.
> Chaque règle est marquée **[VALIDÉ]** (décision déjà prise) ou **[À ÉVALUER]** (à explorer).

### 6.1 Géométrie et canonicalisation `[2007.11301]` — **[VALIDÉ]**
- **Canevas canonique** : normaliser vers `256×256` (DeepSVG) ou `[-512,512]²` (CNM). Choisir UN
  canon pour LOGO et s'y tenir (recommandation : `512` si on adopte SVGFloat/CNM, `256` sinon).
- **Canonicalisation d'un path** : point de départ = point le plus haut-droite (« topmost
  leftmost ») ; commandes orientées **sens horaire**.
- **Simplification de path** : découper aux angles vifs (angle tangent < seuil `η=150°`) ;
  Ramer-Douglas-Peucker pour les segments de ligne ; algorithme de Schneider pour les Bézier ;
  subdiviser les segments plus longs que `Δ=5`.
- **Règle d'arrondi/bornage à l'export** : arrondir les nombres à précision fixe, les clipper
  dans le canevas `[2602.02820]`.

### 6.2 Remplissage et trous (règle de remplissage non-nulle) `[2007.11301]` — **[VALIDÉ]**
- Préférer émettre un attribut de remplissage à 3 valeurs `{outline, fill, erase}` plutôt que de
  reposer sur la règle de remplissage SVG par orientation.
- Les formes `fill`/`erase` qui se chevauchent sont **groupées dans un même path**, orientées
  horaire (fill) / anti-horaire (erase) → le « trou » émerge par la règle de remplissage
  non-nulle. C'est la méthode propre pour produire des **négatifs / contre-formes** (ex. espace
  négatif d'un monogramme).

### 6.3 Hiérarchie, ordre et sémantique des calques `[2007.11301, 2501.03992, 2505.23740]` — **[VALIDÉ]**
- L'ordre des paths est arbitraire (permutation-invariance) → **ne compter jamais sur l'ordre
  d'apparition** ; canonicaliser.
- Viser des formes à **signification autonome** : chaque path doit pouvoir être retiré/modifié
  sans casser la composition (critère d'éditabilité de NeuralSVG).
- Ordre « fond → premier plan » ; les formes précises portent le sens grossier, les formes tard
  apportent le détail (dropout imbriqué, §2.8).

### 6.4 Typographie vectorielle, wordmarks, monogrammes `[PROJET]` — **[VALIDÉ]** (périmètre)
- **Génération de glyphes** class-conditionnés avec **cohérence de style** sur tout un set de
  glyphes `[2007.11301 §4.4]` — base du monogramme (1 à 2 lettres).
- **Word-as-image / typographie sémantique** et **DeepVecFont** sont **référencés** (bibliographies
  de [2604.20730], [2501.03992]) mais **non détaillés** dans le corpus.
  `⚠ Les règles de réglage de wordmark (interlettrage, casse, ligatures, contours de glyphe) ne
  sont pas dans le corpus.`
- Pour LOGO (choix projet) : le **wordmark** = le texte converti en **paths** (contours de
  glyphe), éditable, indépendant de la police ; le **monogramme** = une lettre stylisée rendue en
  formes vectorielles (primitives + contre-formes §6.2).
- **Périmètre initial (décision projet) [VALIDÉ]** : **wordmarks, monogrammes, icônes simples** ;
  **emblèmes complexes à développer en itération suivante** (la complexité est gérée par
  le contrôle de troncature de §2.8 et les dérivations de §3.8).

### 6.5 Layout robuste (position du texte dans une composition) `[0081]` — **[VALIDÉ]**
- Représenter un layout **non pas** comme boîte `[xmin, ymin, xmax, ymax]` mais comme
  **`([xcenter, ycenter], fontsize)`**. Justification du corpus : le texte est disposé en
  lignes avec interlettrage uniforme et couleur de police unique ; de minimes perturbations
  numériques d'une boîte cassent l'interlettrage et l'aspect de la police, alors que
  centre + taille de police est plus **robuste** et réversible (si interlettrage fixe).
  → Règle pour placer le wordmark/texte relatif à l'icône dans un logo.

### 6.6 Contrôles de déclinaison de marque `[2501.03992]` — **[À ÉVALUER]**
- **Palette par couleur de fond** : même asset, palettes différentes selon le fond.
- **Complexité par troncature** : version « icône seule » vs « icône + détail ».
- **Ratio** : `1:1` (favicon, avatar) vs `4:1` (en-tête, bandeau).

### 6.7 Correction optique `[PROJET]` — **[À ÉVALUER]**
- `⚠` La « correction optique » (compensation visuelle, équilibrage de masses, alignements
  optiques non arithmétiques) n'est PAS dans le corpus. Rien à citer ; à construire à l'appui
  des règles de typographie (§6.4/§6.5) en tant que fonctionnalité projet. À tester
  empiriquement sur les premiers logos générés.

---

## 7. Pièges à éviter

1. **Ne pas générer du SVG « brut » avec un LLM généraliste en open-loop.**
   Le corpus montre que le LLM qui « dessine à l'aveugle » (sans rendu intermédiaire) produit des
   géométries syntaxiquement valides mais visuellement incohérentes, des calques mal ordonnés et
   sur-ajuste des distributions de coordonnées. Remède : boucle de rendu visuelle + verify-then-
   accept (§2.5, §2.7). `[2604.20730]`

2. **Ne pas dépendre de Recraft ni d'API d'images coûteuses.**
   Recraft est cité comme outil de vectorisation de qualité (mais c'est une API commerciale
   payante, [2505.23740 App. B]) et [0081] documente explicitement que les générateurs d'image
   raster (FLUX sans texte, Ideogram/Recraft « sticker-like », Doubao texte cassé) **échouent**
   sur le rendu précis du texte et l'alignement texte-image. LOGO doit donc : (a) rester sur du
   **vectoriel structuré local**, (b) éviter la dépendance à une API d'image payante, (c) traiter
   le texte comme des **paths**, pas comme du texte « peint » par une image.

3. **Ne pas faire de « stroke-stacking » (optimisation pure).**
   Les méthodes d'optimisation (LIVE, DiffVG, VectorFusion) minimisent la perte pixel et
   produisent **des milliers de micro-paths chevauchants**, des fichiers gonflés et non
   éditables. Préférer une génération de structure (code + boucle de rendu) qui émet des
   primitives topologiquement propres. `[2604.20730 §D]`

4. **Ne pas laisser fragmenter les zones occlues.**
   Les vectorisations classiques (Potrace, Illustrator) fragmentent les formes partiellement
   masquées. D'où la structure en calques / pelure (§2.3, §2.4) et le contrôle de la qualité du
   découpage topologique (§2.6). `[2505.23740, 2604.20730]`

5. **Ne pas quantiser les nombres en bins discrets.**
   La quantisation (style OmniSVG) introduit des artefacts et casse les relations quantitatives ;
   préférer la modélisation **continue** (§2.1). `[2602.02820]`

6. **Erreurs stochastiques s'accumulant dans un pipeline auto-régressif.**
   La pelure couche par couche accumule les erreurs (mauvaise détection de calque supérieur,
   removal imparfait). Mesures du corpus : mise à jour du graphe de couches à chaque itération +
   **vérification de succès automatique après chaque pelage** + contrôle d'attention localisé.
   `[2505.23740 §5, App. F]`

7. **Ne pas reposer sur l'ordre d'apparition des paths.**
   L'ordre est arbitraire (permutation-invariance) ; sans canonicalisation, l'interpolation et
   l'édition deviennent instables. `[2007.11301]`

8. **Attention à la fragmentation des calques semi-transparents.**
   Limitation documentée de la pelure : les éléments **semi-transparents** se fragmentent en
   formes discrètes multiples ; prévoir la consolidation des calques partagés. `[2505.23740 Fig. 7]`

9. **Ne pas émettre de commandes d'arc elliptique (`A`) pour les courbes.**
   Rendre `A` en Bézier cubiques (continuité pour l'animation/édition, §5.8). `[2007.11301]`

10. **Gardes-fous en place mais limites sur les états complexes.**
    Même avec la boucle de rendu, les états sémantiques inhabituels/surréalistes peuvent être
    simplifiés (« horloge qui fond » → horloge normale) et les scènes très compositionnelles
    restent ouvertes. Pour un **logo**, rester dans le périmètre (formes simples) où la méthode
    est fiable. `[2604.20730 §3.5]`

---

## 8. Références

**Sources primaires (corpus, `sources_logo/`) :**
- [2505.23740] LayerPeeler: Autoregressive Peeling for Layer-wise Image Vectorization
  (`_recherche/sources_logo/2505.23740v3.md`) — graphe de couches, pelure autorégressive, QC.
- [2604.20730] Render-in-the-Loop: Vector Graphics Generation via Visual Self-Feedback
  (`_recherche/sources_logo/2604.20730v3.md`) — boucle de rendu, découpage topologique,
  Render-and-Verify.
- [2501.03992] NeuralSVG: An Implicit Representation for Text-to-Vector Generation
  (`_recherche/sources_logo/2501.03992v1.md`) — représentation implicite, ordre par dropout
  imbriqué, contrôles palette/ratio/complexité.
- [2503.16421] **fichier fourni** = *MagicMotion* (contrôle de trajectoires, génération vidéo)
  (`_recherche/sources_logo/2503.16421v3.md`) — **exclu** (hors sujet SVG/logo) ; le libellé
  « SVGDreamer » est une erreur de conversion. SVGDreamer est seulement **référencé** comme
  baseline dans [2604.20730] et [2501.03992].
- [2007.11301] DeepSVG: A Hierarchical Generative Network for Vector Graphics Animation
  (`_recherche/sources_logo/2007.11301v3.md`) — représentation canonique, conversions de
  formes, canonicalisation, remplissage {outline,fill,erase}, génération de glyphes.
  Bibliothèque `github.com/alexandre01/deepsvg`.
- [2602.02820] From Tokens to Numbers: Continuous Number Modeling for SVG Generation
  (`_recherche/sources_logo/2602.02820v1.md`) — [NUM]+flux flottants, SVGFloat (NaN-boxing),
  pipeline SVGO/svg.path/cairosvg/SSIM. Code `github.com/mikeogezi/CNM`.
- [0081] IterMeme: Expert-Guided Multimodal LLM for Interactive Meme Creation
  (`_recherche/sources_logo/0081.md`) — représentation de layout `([xcenter,ycenter],fontsize)`,
  pipeline `<image,caption,layout>`, observation des échecs du texte sur les générateurs raster
  (Recraft, Ideogram, FLUX).
- [2404.14368] Graphic Design with Large Multimodal Model (Graphist)
  (`_recherche/sources_affiche/2404.14368v1.md`) — **hors périmètre du corpus LOGO** (présent
  dans `sources_affiche/`), miné dans AFFICHE.md §2.4 (z-order IOPR) et §7 (piège #10, ordre des
  calques). Ne figure pas dans `sources_logo/`.

**Outils référencés dans le corpus (rôles cités) :**
- **SVGO** (svgo.dev) — optimisation SVG.
- **CairoSVG** (cairosvg.org) — rendu SVG→raster (validation, boucle de rendu 224×224).
- **svg.path** (PyPI) — parsing/scaling des path data.
- **VTracer** (github.com/visioncortex/vtracer) — vectorisation raster→SVG.
- **Potrace** (potrace.sourceforge.net) — vectorisation raster→SVG.
- **Recraft** (recraft.ai) — API de vectorisation commerciale (dépendance à éviter, §7.2).

**Méthodes générées citées (pas de document autonome dans le corpus, référencées) :**
StarVector, OmniSVG, LLM4SVG, Chat2SVG, SVGen, ReasonSVG, InternSVG (génération de SVG par
MLLM/RL) — [2604.20730, 2602.02820]. **DeepVecFont / DeepVecFont-v2** et **Word-as-image**
(typographie vectorielle) — référencés dans [2604.20730, 2501.03992] (non détaillés).
**LogoLoom** — `⚠ non trouvé dans le corpus`. **vectx** — `⚠ non trouvé dans le corpus`
(concept `[PROJET]`, ancré en §2.10 et §5.5).

**Divergences / absences à retenir :**
- SVGDreamer absent en tant que document (le fichier `2503.16421v3.md` est en réalité MagicMotion,
  hors sujet).
- Correction optique, règles typographiques fines (wordmark/monogramme), et export
  multi-formats non traitées par le corpus (fonctionnalités `[PROJET]` à construire).
- [2404.14368] n'est pas dans `sources_logo/` ; son contenu pertinent (z-order, calques) est
  récupéré depuis AFFICHE.md.

---

## 9. Décisions immédiates recommandées pour le socle technique

1. **Adopter le pipeline §3.1** comme architecture cible ; socle éprouvé = `SVGO + svg.path +
   cairosvg` (tous cités dans le corpus comme outils de référence).
2. **Émettre les nombres en continu** (placeholder `[NUM]` + flux flottant) et ne **jamais**
   quantiser en bins.
3. **Rendre et vérifier** chaque fragment (Render-and-Verify, seuils `ϵ=0.001`, `τsim=0.98`)
   avant acceptation.
4. **Canonicaliser** les paths (canevas 512, départ haut-gauche, sens horaire, `A`→Bézier,
   simplification RDP/Schneider) et émettre les contre-formes en `{outline,fill,erase}`.
5. **Séparer sémantique et géométrie** via le graphe de couches / la couche vectx, pour une
   sortie **éditable et déclinable** (palette, ratio, complexité).
6. **Texte = paths** : le wordmark/monogramme est converti en contours, jamais « peint » par une
   image ; éviter toute dépendance à Recraft / API d'image coûteuse.
7. **Périmètre initial** : wordmarks, monogrammes, icônes simples ; emblèmes complexes en
   itération suivante.

