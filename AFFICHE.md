# Rapport d'ingénierie — AFFICHE

**Projet AFFICHE** : générateur de posters et de documents multi-pages (brand kit) produisant du JSON de mise en page (calques), pas des pixels.
**Date** : 2026-10-23 · **Source** : 13 documents dans `_recherche/sources_affiche/` (voir §8) · **Filtre appliqué** : méthodes et stratégies conservées, modèles IA spécifiques / entraînements / architectures neuronales / benchmarks supprimés.
**Légende des marqueurs** : **[VALIDÉ]** = décision déjà prise dans le projet · **[À ÉVALUER]** = à tester avant adoption · « ⚠ non trouvé dans le corpus » = information absente des 13 sources.

---

## 1. Résumé exécutif

Le corpus confirme le principe central d'AFFICHE : générer la mise en page comme structure de données éditables (JSON de calques, HTML, SVG) plutôt que comme image pixelisée — c'est la démarche commune de PosterLlama (HTML), de CreatiPoster (JSON de calques), de GLDesigner (JSON pur) et de l'Ad Banner (HTML div). La chaîne recommandée est séquentielle et multi-agents : classification de style → génération de la charte → génération par document → validation déterministe, avec boucle de feedback itératif plafonnée (SciFig : K=4, gains décroissants après la 3ᵉ ronde ; ~1,2 $ / figure, ~10 min). Le concept de *brand kit* (chaîne de thèmes hérités + banque narrative) est explicitement documenté (2512.17151). Le validateur déterministe hérite de règles objectives issues du corpus : sous-couches strictes (PosterLayout), contraste WCAG, harmonie chromatique de Matsuda/Itten, non-chevauchement, stabilité inter-ronde (SciFig). Les outils validés restent **Fabric.js** (toile éditabile), **Docling** (parsing) et **LightRAG** (graphe de connaissance) ; les références méthodologiques s'appuient sur CreatiPoster (arXiv 2506.10890), PosterLLaVa (arXiv 2406.02884, pipeline PosterGen 4 étapes) et iPoster (arXiv 2603.29469, paradigmes de contrainte utilisateur par masques binaires).

---

## 2. Méthodes et stratégies

Chaque entrée : nom + arXiv, principe, pertinence pour AFFICHE, état.

### 2.1 Génération de mise en page comme code structuré (JSON / HTML / SVG) [VALIDÉ]

- **Principe** : reformuler les éléments de layout (type, boîte, contenu) en séquences HTML ou JSON pour exploiter la connaissance de conception embarquée dans les LLM, plutôt que de prédire des nombres bruts. PosterLlama (arXiv 2404.00995) génère du HTML avec balises `<rect>`, contraintes de texte et jetons `<M>` ; CreatiPoster (arXiv 2506.10890) émet un programme de design JSON P = (L, c_bg) avec calques triés par ordre de rendu ; GLDesigner (arXiv 2411.11435) sort du JSON pur `[{"word","detail","box"}]` ; Ad Banner (arXiv 2512.12596) génère du HTML avec `<div>`.
- **Pertinence AFFICHE** : c'est exactement le contrat de sortie — « JSON de mise en page = calques, pas pixels ». Les coordonnées normalisées 0–1 (PosterLlama, CreatiPoster) rendent le JSON indépendant du format de document (A4, poster 2:3, social 4:5).
- **État** : **[VALIDÉ]** (principe « JSON de calques » déjà retenu par le projet).

### 2.2 Chaîne séquentielle multi-agents plan → layout → composants → feedback [VALIDÉ]

- **Principe** : SciFig (arXiv 2601.04390) : 4 agents séquentiels (Planning → Layout → Composants → Feedback) ; itératif à K=4 rondes de raffinement avec arrêt anticipé — les gains de qualité saturent après la 3ᵉ ronde (6.9 → 7.7) ; coût ~1,2 $ et ~10 min par figure ; ReContraster (arXiv 2604.10442) : boucle cognition → arrangeur → raffineur, sans entraînement. Ad Banner (arXiv 2512.12596) : raisonnement en deux étapes (plan de placement en langage naturel, *puis* code HTML) — la version one-shot échoue car le modèle écrit d'abord le HTML et rationalise *a posteriori* son plan (documenté fig. 7/8).
- **Pertinence AFFICHE** : architecture cible de la chaîne AFFICHE : (1) classification de style, (2) génération de la charte JSON, (3) génération du JSON de mise en page par document, (4) validateur déterministe + boucle de feedback plafonnée (K ≤ 4, arrêt si le score ne progresse plus).
- **État** : **[VALIDÉ]** en structure ; le coût/ronde à recaler sur les modèles du projet.

### 2.3 Contraintes utilisateur par masques binaires par attribut (iPoster) [À ÉVALUER]

- **Principe** (arXiv 2603.29469) : état x ∈ R^{N×5} = [catégorie, c_x, c_y, w, h] ; masque binaire M ∈ {0,1}^{N×5} ; l'intention utilisateur est sur-écrite *à chaque étape* de débruitage quand M=1, garantissant la fidélité exacte. Paradigmes : C→S+P (M_i,0=1) ; C+S→P (M_i,0=M_i,3=M_i,4=1) ; Complétion (M_{i,:}=1 sur les ancres) ; Raffinement (un layout grossi sert d'état intermédiaire de débruitage).
- **Pertinence AFFICHE** : le paradigme de **masque par attribut** est directement réutilisable côté validateur/générateur : l'utilisateur verrouille certains attributs d'un calque (position exacte du logo, taille du titre) et le générateur ne doit jamais les altérer — implémentable sans diffusion, en ré-imposant les valeurs verrouillées à chaque itération de la boucle de feedback.
- **État** : **[À ÉVALUER]** — portage du concept de masque dans une boucle LLM + validateur.

### 2.4 Pipeline 4 étapes PosterGen (PosterLLaVa) [À ÉVALUER]

- **Principe** (arXiv 2406.02884) : (1) analyse de l'intention (catégorie QB-Poster, 10 catégories) ; (2) génération du fond ; (3) layout sensible au contenu ; (4) attributs de texte — luminosité WCAG calculée **par patch** de fond, taille de police optimale déduite de la boîte + du contenu + de la police.
- **Pertinence AFFICHE** : l'ordre étapes (fond avant contenu, lisibilité dérivée du fond local) est la bonne séquence d'une chaîne de génération de documents ; l'étape 4 est une **règle de conception déterministe réutilisable** (§6.5).
- **État** : **[À ÉVALUER]** — à déclocher de l'architecture (supprimée du périmètre) et réimplémenter en étapes LLM + calculs déterministes.

### 2.5 Optimisation de lisibilité automatique (ARO) [VALIDÉ comme règle]

- **Principe** (arXiv 2512.17151) : pour chaque boîte de texte, calcul de l'opacité minimale α* d'un **sous-fond rectangulaire arrondi semi-transparent** qui atteint le contraste WCAG 2.2 visé (7.0), couverture 0.98, padding 24, rayon 0.12 de la largeur de boîte ; extraction des boîtes avec PyMuPDF + OpenCV.
- **Pertinence AFFICHE** : technique déterministe parfaite pour le validateur et le « raffineur de lisibilité » du pipeline : au lieu de repiquer les couleurs, on insère des calques `underlay` calculés. Intègre avec la règle de sous-couche de PosterLayout (§6.2).
- **État** : **[VALIDÉ]** en tant que règle de validité/réparation du validateur.

### 2.6 Banque narrative récursive (RNB) pour documents multi-pages [VALIDÉ]

- **Principe** (arXiv 2512.17151) : chaque page résume l'état narratif compact s_i (≤ 5 mots par page) ; le contenu de la page i+1 est conditionné sur l'historique H_{i−1} via une fenêtre mémoire N.
- **Pertinence AFFICHE** : c'est le mécanisme du **brand kit multi-pages** — documents d'un même kit qui partagent un thème racine (JSON de charte) mais chacun sa propre spécialisation, avec continuité narrative entre pages ; chaque document de charte hérite du thème racine et peut surcharger (héritage/specialisation).
- **État** : **[VALIDÉ]** pour l'architecture du brand kit (§5.2).

### 2.7 Classification de style par catégories déclaratives [VALIDÉ]

- **Principe** : 7 catégories de style (Colorful, Geometric, Muted, Professional, Real & Natural, Shapes, Textures — arXiv 2512.17151) servent de classification intermédiaire entre le prompt utilisateur et la charte générée ; dans CreatiPoster (arXiv 2506.10890), la fidélité au style est un des 4 critères d'évaluation (GPT-4.1 + 10 évaluateurs humains).
- **Pertinence AFFICHE** : la **chaîne de style** d'AFFICHE : le prompt → un agent de classification (ou choix utilisateur) → une `style_category` dans la charte JSON qui contraint la palette, la typographie, la grille (§5.2) et le ton de la génération par document.
- **État** : **[VALIDÉ]** comme premier maillon de la chaîne séquentielle.

### 2.8 Critères de qualité et exigences (référentiel de validation) [VALIDÉ]

- **Principe** :
  - **4 critères de qualité** (CreatiPoster, arXiv 2506.10890) : Layout, Couleur, Style graphique, Fidélité au prompt.
  - **4 exigences** (arXiv 2512.17151) : précision du texte, fidélité des assets, éditabilité, attrait esthétique.
  - Tableau de correspondance en **annexe A** (les 4 critères ↔ les 4 exigences, avec les règles déterministes mappables : chaque exigence a au moins une règle objectivable dans le validateur).
- **Pertinence AFFICHE** : c'est le contrat de qualité du validateur déterministe et des rapports de génération ; « éditabilité » renvoie directement au principe « JSON de calques, pas pixels ».
- **État** : **[VALIDÉ]**.

### 2.9 Méthode de contrôle par sous-couches (Inverse-Order Pair Ratio) [VALIDÉ comme règle]

- **Principe** (Graphist, arXiv 2404.14368) : le ratio IOPR des paires de calques se chevauchant est exploité comme signal de contrôle du contenu visuel (les éléments qui *passent dessous* signalent l'arrière-plan) ; limites documentées : le modèle reste limité aux **designs homogènes** (une page, pas un kit), et le rendu utilise du RGB-A avec alpha — donc les assets doivent être livrés avec transparence.
- **Pertinence AFFICHE** : règle du validateur : les calques `underlay` doivent être strictement *sous* les calques de contenu qu'ils soutiennent (z-order explicite par indice de rendu o_j, CreatiPoster) ; inversion signalée comme violation (§5.3, type `ZORDER_INVERSION`).
- **État** : **[VALIDÉ]** comme règle de validation.

### 2.10 Contrôles de géométrie de layout (PosterLayout) [VALIDÉ comme règles]

- **Principe** (arXiv 2303.15937) : 3 types d'éléments (logo, texte, underlay) ; règle de sous-couche stricte ; séquence de placement (texte, puis sous-couches, puis logo) ; 8 métriques objectivables : Validité (éléments > 0.1 % de la canvas), Overlay, Align, Undl, Unds, Utilization, Occlusion, Readability.
- **Pertinence AFFICHE** : jeu de règles déterministes du validateur, directement implémentable sur le JSON de calques (aucun modèle requis) ; les 8 métriques servent d'indicateurs de sortie du rapport de validation.
- **État** : **[VALIDÉ]**.

### 2.11 Harmonisation chromatique par roue (Matsuda/Itten) [VALIDÉ]

- **Principe** (Cohen-Or et al. 2006, 1141911.1141933) : 7 gabarits de teintes harmonieuses (i, I, L, T, V, X, Y ; le N en niveaux de gris est exclu) ; tailles de secteurs exactes (§6.1) ; gabarits invariants par rotation (l'orientation α est un paramètre libre, resolu par l'algorithme de Brent) ; rétrécissement de teinte gaussien (σ = w/2) ; les couleurs à faible saturation restent inchangées ; étiquetage de cohérence par graph-cut (Boykov-Jolly).
- **Pertinence AFFICHE** : moteur de **génération de palette** du JSON de charte : au lieu d'un prompt → 5 hex aléatoires, un modèle « matsuda » + gabarit + orientation donne une palette *harmonisée par construction* ; le validateur peut rejeter les palettes qui ne correspondent à aucun gabarit (§5.3, type `STYLE_MISMATCH` via contraste/harmonie).
- **État** : **[VALIDÉ]** comme modèle de palette par défaut de la charte (cf. §5.2, `"palette_model": "matsuda"`).

---

## 3. Techniques d'ingénierie et pipelines

### 3.1 Pipeline minimal recommandé (décision du projet)

```
logo + charte + slogan
      ↓ (agente de charte)
JSON de charte (racine du brand kit)
      ↓ (génération par document)
JSON de mise en page d'UN poster (calques)
      ↓ (validateur déterministe, §5.3)
canvas Fabric.js éditabile
      ↓ (édition par prompt, boucle de feedback plafonnée K ≤ 4)
export (SVG / PDF / calques JSON)
```

Chaque document du kit est un spécialisation du thème racine (§5.2) ; la boucle de feedback reprend la logique SciFig (iPoster) : arrêt anticipé si le score du validateur ne progresse plus, plafond K = 4 rondes (2601.04390).

### 3.2 Techniques transverses extraites du corpus

- **Raisonnement en deux étapes plutôt qu'une seule** (arXiv 2512.12596) : plan de placement en langage naturel *puis* code ; la version one-shot échoue car le modèle rationalise *a posteriori*. → règle du prompt : ne jamais mélanger plan et code dans le même appel.
- **Permutation aléatoire de l'ordre des calques à l'entraînement/génération** (arXiv 2404.00995, §3.1) : les éléments de layout n'ont pas d'ordre intrinsèque ; imposer un ordre fixe crée un risque de surapprentissage → le JSON de calques doit être insensible à l'ordre (les rendus dépendent de l'indice o_j, jamais de la position du tableau).
- **Coût et durée de la boucle** (arXiv 2601.04390) : ~1,2 $ et ~10 min par figure à K=4, gains décroissants après la 3ᵉ ronde → plafonner la boucle et mesurer le score après chaque ronde pour arrêter.
- **Échecs d'injection** (arXiv 2512.12596) : le raisonnement en 0-shot ignore le contenu de l'image ; un contexte peu-échantillon (few-shot) stabilise la sortie → le générateur de charte reçoit 2–4 exemples de chartes validées.
- **Attributs par patch plutôt que globaux** (arXiv 2406.02884) : la lisibilité est calculée localement sur le fond *sous chaque élément* ; une couleur de texte « moyenne » globale échoue sur les fonds variés → règle §6.5.
- **Verrouillage d'attributs par masque** (arXiv 2603.29469) : à chaque itération de la boucle de feedback, re-écrire les attributs verrouillés (M=1) après chaque génération (cf. §2.3).
- **Géométrie par GIoU + relative position** (arXiv 3583780.3615028, RADM) : la perte de chevauchement et le positionnement relatif catégoriel (les sous-couches *couvrent*, les autres *évitent*) sont des heuristiques de placement réutilisables sans diffusion : dans un raffineur, pénaliser le chevauchement par IoU/GIoU et forcer la non-superposition entre éléments qui ne sont pas sous-couche.
- **Extraction de boîtes de texte existantes** (arXiv 2512.17151) : PyMuPDF + OpenCV pour récupérer les positions/taillons d'un document source et alimenter le JSON de calques (mode « import de charte » : on parse un PDF existant avec Docling → JSON de mise en page).

### 3.3 Validateur déterministe (spine du pipeline)

Le validateur est **deterministe** : aucune IA, uniquement des règles du corpus (§5.3 détaille les types de violation). Il produit : (a) un rapport de violations typées, (b) 8 indicateurs de layout (PosterLayout), (c) un score global qui pilote l'arrêt anticipé de la boucle de feedback (§3.1, K ≤ 4). Le raffineur (LLM) ne voit que le rapport ; il ne voit jamais de pixels.

---

## 4. Systèmes / frameworks / bibliothèques recommandées

| Nom | Rôle dans AFFICHE | Licence | Maturité | État |
|---|---|---|---|---|
| **Fabric.js** | Toile éditabile : import du JSON de calques, édition par prompt (calques sélectionnés → prompt → patch du JSON), export SVG | MIT | Production (10+ ans) | **[VALIDÉ]** (déjà retenu par le projet) |
| **Docling** | Parsing de documents existants (PDF/DOCX/images) vers JSON structuré, alimenter le mode « import de charte » et l'extraction de boîtes de texte | MIT | Production (IBM) | **[VALIDÉ]** (déjà retenu par le projet) |
| **LightRAG** | Graphe de connaissance du brand kit : entités (palettes, polices, assets, documents) + relations (héritage de thème) ; requêtes naturelles sur le kit | MIT | Production (Microsoft) | **[VALIDÉ]** (déjà retenu par le projet) |
| **PyMuPDF** | Extraction de boîtes de texte et de positions dans les documents sources (pipeline ARO, 2512.17151) | AGPLv3 / commerciale | Production | [À ÉVALUER] (licence AGPL à clarifier pour un produit) |
| **OpenCV** | Extraction de bordures et de boîtes (456, 457) | Apache 2.0 | Production | [À ÉVALUER] (couplé PyMuPDF) |
| **Skia** | Rendu déterministe du JSON de calques (utilisé par CreatiPoster, 2506.10890) | BSD-3 | Production | [À ÉVALUER] (si export vectoriel nécessaire) |
| **Graphist / CreatiPoster / PosterLLaVa / iPoster** | **Références méthodologiques uniquement** : ne pas intégrer (modèles entraînés, hors périmètre « pas de fine-tuning, pas d'image pixelisée ») | — | Recherche | **Suppression** — on n'emporte que les méthodes (§2) |

**Note de licence** : les licences marquées « connaissance générale, non issue du corpus » (GK) — le corpus ne contient pas d'informations de licence.

---

## 5. Schémas de données et structures

### 5.1 JSON de mise en page (calques)

Modèle CreatiPoster (arXiv 2506.10890) : P = (L, c_bg) ; chaque calque ℓ_j porte 4 groupes d'attributs :
- `a^sem` : type de calque (text/asset/underlay/deco) + contenu (texte ou identifiant d'asset) ;
- `a^geo` : position, taille, crop, rotation, courbure, masques ;
- `a^sty` : police, couleur, contour, opacité, alignement, espacement, styles de texte ;
- `o_j ∈ {1..m}` : **ordre de rendu bas-à-haut** (z-order explicite, jamais implicite).

Coordonnées **normalisées 0–1** (PosterLlama, CreatiPoster, Ad Banner) → JSON indépendant du format final.

```json
{
  "canvas": { "w": 1.0, "h": 1.0, "bg": "#1A1A2E" },
  "calques": [
    {
      "id": "c1",
      "a_sem": { "type": "underlay", "asset": null },
      "a_geo": { "x": 0.05, "y": 0.05, "w": 0.9, "h": 0.9, "rotation": 0, "crop": null, "mask": null },
      "a_sty": { "fill": "#FFFFFF", "opacity": 0.92, "stroke": null, "radius": 0.12 },
      "o": 1,
      "M": { "lock_x": true, "lock_y": true, "lock_w": false, "lock_h": false, "lock_cat": true },
      "detail": "sous-fond pour la lisible du titre, opacité minimale α* calculée par ARO (§2.5)"
    },
    {
      "id": "c2",
      "a_sem": { "type": "text", "text": "LANCEMENT 2026", "asset": null },
      "a_geo": { "x": 0.1, "y": 0.12, "w": 0.8, "h": 0.15, "rotation": 0, "crop": null, "mask": null },
      "a_sty": { "font_family": "Inter", "font_size": 0.045, "fill": "#0F0F2C", "align": "left", "line_height": 1.15, "opacity": 1.0 },
      "o": 2,
      "M": { "lock_x": false, "lock_y": false, "lock_w": false, "lock_h": false, "lock_cat": false }
    },
    {
      "id": "c3",
      "a_sem": { "type": "asset", "text": null, "asset": "logo_primary" },
      "a_geo": { "x": 0.78, "y": 0.86, "w": 0.14, "h": 0.06, "rotation": 0, "crop": null, "mask": null },
      "a_sty": { "fill": null, "opacity": 1.0 },
      "o": 3,
      "M": { "lock_x": true, "lock_y": true, "lock_w": true, "lock_h": true, "lock_cat": true }
    }
  ]
}
```

- Le champ `M` (arXiv 2603.29469) porte les attributs **verrouillés** (iPoster) que la boucle de feedback ne doit jamais modifier.
- Le champ `detail` (arXiv 2411.11435) est la trace CoT par calque — optionnel, utile au débug et à l'audit du raffineur.

### 5.2 JSON de charte (racine du brand kit)

Structure héritée (arXiv 2512.17151 : chaîne de thèmes + RNB ; 2404.14368 : palette harmonieuse ; 2303.15937 : grille et sous-couches) :

```json
{
  "charte": {
    "version": "1.0",
    "style_category": "Professional",
    "palette": {
      "model": "matsuda",
      "gabarit": "V",
      "orientation_deg": 35,
      "couleurs": ["#1A1A2E", "#E94560", "#F5F5F5", "#0F0F2C", "#7C8399"]
    },
    "typographie": {
      "titre":    { "font": "Inter", "weight": 800, "size_scale": 1.0 },
      "sous_titre":{ "font": "Inter", "weight": 600, "size_scale": 0.62 },
      "corps":    { "font": "Inter", "weight": 400, "size_scale": 0.40 },
      "note":     { "font": "Inter", "weight": 400, "size_scale": 0.30 }
    },
    "grille": { "colonnes": 12, "marges": 0.05, "goutters": 0.02 },
    "assets": [
      { "id": "logo_primary", "src": "assets/logo.svg", "transparent": true, "format": "svg" },
      { "id": "hero_texture", "src": "assets/texture.jpg", "transparent": false }
    ],
    "narrative_bank": {
      "max_mots_par_page": 5,
      "fenetre_memoire": 12,
      "resume": []
    },
    "documents": [
      { "id": "poster_principal", "theme_local": { "palette_couleur_accent": "#E94560" }, "page": 1 },
      { "id": "catalogue_p1", "theme_local": { "grille_marges": 0.07 }, "page": 2, "conditionne_sur": "poster_principal" }
    ]
  }
}
```

- `style_category` : l'une des 7 catégories (§2.7, arXiv 2512.17151) ; le générateur du document doit produire un style cohérent avec cette catégorie, sinon violation `STYLE_MISMATCH` (§5.3).
- `narrative_bank` : arXiv 2512.17151 (RNB) ; chaque document du kit conditionne le suivant via `conditionne_sur`.
- `palette.model = "matsuda"` : gabarit + orientation (§2.11) ; les 5 couleurs sont **dérivées** du gabarit, pas saisies.

### 5.3 Rapport de validation du validateur déterministe

Types de violation objectivables (règles du corpus) :

| Type de violation | Règle | Source |
|---|---|---|
| `BOUNDARY_OVERRUN` | x < 0 ou x+w > 1 (mêmes pour y) | PosterLlama, CreatiPoster |
| `TEXT_OVERLAP` | chevauchement de calques texte/texte (IoU > 0) | PosterLayout (8 métriques), SciFig (QC du harnais) |
| `LABEL_DUP` | texte identique en deux calques superposés | SciFig (QC du harnais) |
| `WCAG_CONTRAST` | contraste texte/sous-fond < 4.5 (objectif 7.0 si ARO activé) | PosterLLaVa (§2.4), ARO (§2.5) |
| `UNDERLAY_MISPLACE` | un texte est *sous* son underlay (inversion) | PosterLayout (règle de sous-couche stricte), IOPR (arXiv 2404.14368) |
| `ZORDER_INVERSION` | o_j incohérent avec la hiérarchie sémantique déclarée | CreatiPoster (2506.10890, indice o_j) |
| `ROUND_INSTABILITY` | un attribut sans verrou M change de valeur à chaque boucle (instabilité inter-ronde) | SciFig (QC du harnais, 2601.04390) |
| `CONSTANTIONAL_VIOLATION` | violation d'une règle de grille (colonnes, marges) de la charte | PosterLayout + charte (§5.2) |
| `STYLE_MISMATCH` | couleurs du document hors palette de charte, ou typographie hors rôles déclarés | CreatiPoster (critère « Couleur » + « Style graphique »), SciFig (QC des heuristiques 8, 2601.04390) |

Le rapport renvoie : liste de violations typées + **8 indicateurs PosterLayout** (Val, Ove, Ali, Undl, Unds, Uti, Occ, Rea) + un score 0–10 pilotant l'arrêt anticipé (§3.1).

### 5.4 Métriques du layout (PosterLayout, arXiv 2303.15937)

8 métriques objectivables : Val (validité, éléments > 0.1 %), Ove (overlay), Ali (align), Undl (unders), Unds (unders strict), Uti (utilization), Occ (occlusion), Rea (readability). Ces indicateurs alimentent le score global du rapport de validation et servent de **règles de sortie du validateur** (pas de modèle).

### 5.5 Exemple de JSON de mise en page après ARO (démo)

```json
{
  "avant": { "c2": { "a_sty": { "fill": "#FFFFFF", "opacity": 1.0 } } },
  "apres_validateur": {
    "c2": { "a_sty": { "fill": "#FFFFFF", "opacity": 1.0 } },
    "c1": { "a_sty": { "fill": "#FFFFFF", "opacity": 0.92, "radius": 0.12 },
             "note": "α* calculée pour contraste ≥ 7.0 sur le patch du fond local (2512.17151)" }
  }
}
```

---

## 6. Règles de conception

### 6.1 Palettes (modèle Matsuda/Itten, 1141911.1141933)

- **7 gabarits** de teintes harmonieuses : i, I, L, T, V, X, Y (le N en niveaux de gris est exclu).
- **Tailles de secteurs exactes** :
  - V, Y, X grands : 26 % du disque (93.6°) ;
  - i, I, L, Y secondaires : 5 % (18°) ;
  - L grand : 22 % (79.2°) ;
  - T : 50 % (180°).
- **Orientation** : les gabarits I, X, Y ont des centres de secteurs espacés de 180° ; le L de 90° ; l'orientation α du gabarit est un paramètre libre (résolu par l'algorithme de Brent) → invariance par rotation.
- **Rétrécissement de teinte gaussien** (σ = w/2) pour ramener les teintes vers le centre du gabarit.
- **Couleurs à faible saturation** : non modifiées (exemptées du rétrécissement).
- **Étiquetage de cohérence** par graph-cut (Boykov-Jolly).
- **Limites documentées** : régions déconnectées et gabarit mal choisi → résultat inadapté ; le gabarit doit correspondre à l'intention (§2.7 `style_category`).

### 6.2 Grille et sous-couches (PosterLayout, 2303.15937)

- 3 types d'éléments de base : **logo, texte, underlay**.
- **Règle de sous-couche stricte** : un underlay est toujours *sous* un texte/logo qu'il soutient ; inversion = violation (§5.3 `UNDERLAY_MISPLACE`).
- Séquence de placement : texte → sous-couches → logo (ordre de génération, à respecter dans le raffineur).
- Un élément est **valide** s'il couvre > 0.1 % de la canvas (sinon ignoré dans les indicateurs).

### 6.3 Typographie (PosterLLaVa, 2406.02884 + GLDesigner, 2411.11435)

- Taille de police optimale **déduite de la boîte + du contenu + de la police** (PosterLLaVa §2.4) : jamais une taille fixe.
- Lignes de texte : une seule ligne par calque de texte dans le JSON (GLDesigner : chaque glyphe porte un `box` individuel + `detail` CoT) → permet au raffineur de détecter la casse d'une ligne.
- Les rôles typographiques déclarés dans la charte (§5.2) contraignent la génération : un texte hors rôle = violation `STYLE_MISMATCH`.

### 6.4 Contrainte de style (CreatiPoster, 2506.10890 + 2512.17151)

- `style_category` (§5.2) définit le **champ de variation autorisé** : le générateur du document ne peut sortir de cette catégorie, sinon violation `STYLE_MISMATCH`.
- Le 4ᵉ critère de qualité (CreatiPoster) est « Fidélité au prompt » : le prompt utilisateur est le contrat ; tout écart est mesuré par l'évaluation (§2.8).

### 6.5 Lisibilité locale (PosterLLaVa, 2406.02884 + ARO, 2512.17151)

- La **luminosité WCAG** est calculée **par patch de fond** (pas globalement) ; les fonds variés exigent un calcul local.
- Cible : **contraste 7.0** (WCAG 2.2), couverture 0.98, padding 24, rayon 0.12 (ARO).
- Mécanisme de correction : insertion d'un **sous-fond rectangulaire arrondi semi-transparent** (calque `underlay` du JSON de calques) avec l'opacité minimale α* qui atteint la cible ; le texte reste à sa couleur de charte (pas de changement de couleur).

### 6.6 Non-chevauchement et z-order (Graphist, 2404.14368 + RADM, 3583780.3615028)

- **IOPR** : les paires de calques qui se chevauchent sont classées par ordre inverse (les *dessous* signalent l'arrière-plan) → le z-order doit être **cohérent avec la sémantique déclarée** (§5.3 `ZORDER_INVERSION`).
- **GRAM** (RADM) : les sous-couches *couvrent* les éléments qu'elles soutiennent ; les autres paires *évitent* le chevauchement → règle déterministe du raffineur : minimiser le GIoU entre éléments qui ne sont pas en relation de sous-couche.
- **Permutation aléatoire de l'ordre des calques** à l'entraînement (PosterLlama §3.1) : le JSON de calques est insensible à l'ordre du tableau ; l'ordre de rendu est *uniquement* porté par l'indice o_j.

---

## 7. Pièges à éviter (erreurs documentées dans le corpus)

1. **Raisonnement one-shot (plan + code dans le même appel)** : le modèle écrit le code et rationalise *a posteriori* le plan, ou ignore le contenu de l'image (arXiv 2512.12596, fig. 7/8). → Toujours séparer plan (langage naturel) et code ; toujours injecter le contenu de l'image/canvas dans le prompt du plan.
2. **Attributs globaux plutôt que locaux pour la lisibilité** : une couleur de texte « moyenne » échoue sur les fonds variés (arXiv 2406.02884). → Calcul par patch (§6.5).
3. **Texte / boîte de texte mal assortis** : le décalage entre la taille du texte et la taille de la boîte dégrade le rendu de texte dans la scène (arXiv 2404.00995, limitation §5) ; de même, la longueur du texte doit être prise en compte dès la génération de la boîte (2411.11435 : la longueur conditionne la boîte). → Le raffineur redimensionne la boîte en fonction du contenu *avant* de fixer la police.
4. **Génération d'images pixelisées pour les posters** : hors périmètre du projet (décision validée) et incompatible avec l'éditabilité (arXiv 2506.10890 : l'éditabilité est l'une des 4 exigences). → JSON de calques uniquement.
5. **Sous-couches mal placées** : un underlay *au-dessus* du texte qu'il est censé soutenir détruit la lisibilité (arXiv 2303.15937, règle de sous-couche stricte). → Validation `UNDERLAY_MISPLACE` (§5.3).
6. **Chevauchement de calques texte** : les textes qui se superposent deviennent illisibles ; c'est la 1ʳᵉ violation détectée par le harnais de SciFig (arXiv 2601.04390). → Validation `TEXT_OVERLAP` (§5.3).
7. **Instabilité inter-ronde de la boucle de feedback** : le raffineur qui change un attribut non verrouillé à chaque itération produit des rapports imprévisibles (arXiv 2601.04390, QC du harnais ; arXiv 2603.29469, masques M). → Verrouiller les attributs (M=1) et vérifier la stabilité (§5.3 `ROUND_INSTABILITY`).
8. **Palette hors harmonie** : des couleurs saisies librement produisent des palettes incohérentes ; le rétrécissement de teinte est inexistant (1141911.1141933). → Modèle « matsuda » + gabarit + orientation (§6.1).
9. **Gabarit de palette mal adapté au style** : régions déconnectées et gabarit inadapté → résultat inadapté (1141911.1141933, limites documentées). → Le gabarit est choisi en fonction de la `style_category` (§2.7).
10. **Évaluation par VLM du sous-couche** : le juge visuel peut produire de **faux négatifs** sur la présence d'un underlay (arXiv 2512.12596, fig. 4) — on ne peut pas se fier à un VLM pour vérifier la géométrie. → Le validateur est **deterministe** (§5.3), le VLM n'évalue que l'esthétique (critère 4).
11. **Boucle de feedback non plafonnée** : les gains de qualité saturent après 3 rondes (arXiv 2601.04390 : K=4, gains décroissants) → plafonner à K=4 et arrêter si le score ne progresse plus.
12. **Designs homogènes uniquement** : Graphist (arXiv 2404.14368) est limité aux designs homogènes (une page, pas un kit) ; les références méthodologiques du corpus (CreatiPoster, PosterLLaVa) sont des **modèles entraînés** et hors périmètre du projet (pas de fine-tuning, pas d'image pixelisée) → on n'emporte que les méthodes (§2), pas les modèles.

---

## 8. Références

| # | Source | Identifiant | Fichier du corpus |
|---|---|---|---|
| 1 | PosterLlama — HTML layout, masques, permutation | arXiv 2404.00995 | `2404.00995v3.md` |
| 2 | PosterLLaVa — PosterGen 4 étapes, WCAG par patch | arXiv 2406.02884 | `2406.02884v3.md` |
| 3 | PosterLayout — 8 métriques, règle de sous-couche | arXiv 2303.15937 | `2303.15937v1.md` |
| 4 | ReContraster — boucle 3 agents, sans entraînement | arXiv 2604.10442 | `2604.10442v1.md` |
| 5 | iPoster — masques binaires par attribut, 4 paradigmes | arXiv 2603.29469 | `2603.29469v1.md` |
| 6 | Graphist — IOPR, palette harmonieuse, z-order | arXiv 2404.14368 | `2404.14368v1.md` |
| 7 | CreatiPoster — JSON de calques, 4 critères, protocole de complétion | arXiv 2506.10890 | `CreatiPoster_Towards_Editable_and_Controllable_Multilayer.md` |
| 8 | ARO + RNB + 7 catégories de style | arXiv 2512.17151 | `2512.17151v2.md` |
| 9 | SciFig — chaîne 4 agents, K=4, harnais déterministe, 8 heuristiques | arXiv 2601.04390 | `2601.04390v3.md` |
| 10 | RADM — VTRAM + GRAM, GIoU, sous-couches par catégorie | CIKM'23 (10.1145/3583780.3615028) | `3583780.3615028.md` |
| 11 | Color Harmonization (Matsuda/Itten) — 7 gabarits, σ=w/2, Brent, graph-cut | ACM/SIGGRAPH 2006 | `1141911.1141933.md` |
| 12 | GLDesigner — JSON pur, CoT par glyphe, ViO | ACM MM '25 (arXiv 2411.11435) | `2411.11435v2.md` |
| 13 | Ad Banner — raisonnement 2 étapes, one-shot échec, VLM faux négatif | arXiv 2512.12596 | `2512.12596v1.md` |

**Outils du projet (déjà validés, non issus du corpus)** : Fabric.js, Docling, LightRAG — voir §4.

---

## Annexe A — Correspondance 4 critères ↔ 4 exigences

| Critère de qualité (CreatiPoster, 2506.10890) | Exigence (arXiv 2512.17151) | Règle déterministe mappable (§5.3) |
|---|---|---|
| **Layout** | **Précision du texte** | `TEXT_OVERLAP`, `BOUNDARY_OVERRUN`, `LABEL_DUP` (PosterLayout 8 métriques, SciFig harnais) |
| **Couleur** | **Fidélité des assets** | `WCAG_CONTRAST` (per-patch, ARO), `STYLE_MISMATCH` (palette de charte) |
| **Style graphique** | **Éditabilité** | `ZORDER_INVERSION`, `UNDERLAY_MISPLACE`, `ROUND_INSTABILITY` (JSON de calques, Fabric.js, masques M) |
| **Fidélité au prompt** | **Attrait esthétique** | Évaluation par VLM (critère 4 uniquement, pas de géométrie) + 8 heuristiques de SciFig (WCAG 2.1 AA, harmonie Matsuda, utilisation du canvas, Tufte, non-chevauchement par paires, uniformité 8×8 des espaces vides, cohérence de police) |

**Règle d'or** : le **geometric** (layout, z-order, contraste, non-chevauchement) est toujours vérifié par le **validateur déterministe** ; le **subjective** (esthétique, attrait) est seul confié au VLM — jamais l'inverse (cf. piège 10, arXiv 2512.12596 fig. 4).

---

*Fin du rapport — généré à partir des 13 documents du corpus. Les marqueurs [VALIDÉ] / [À ÉVALUER] indiquent l'état de chaque décision pour le projet AFFICHE. Les références GK (connaissance générale, non issue du corpus) concernent les informations de licence (§4).*
