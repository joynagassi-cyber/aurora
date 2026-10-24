# VIDEO : Éditeur Vidéo par Calques — Rapport d'Ingénierie

> Base : HyperFrames (Apache-2.0) · Interface : Aurora-video (inspiration OpenFilm) · Audio : TTS/musique/SFX/ducking
> Sources : arXiv:2508.04228v2 (LayerT2V), arXiv:2312.17432v8 (Vid-LLM Survey), arXiv:2312.16476v7 (SVGDreamer), arXiv:2604.19632v2 (CreatiParser)

> **Note sources** : Les fichiers `2508.04228v2.md` et `2312.17432v8.md` sont dans `_recherche/sources_video/` ; les fichiers `2312.16476v7.md` (SVGDreamer) et `2604.19632v2.md` (CreatiParser) étaient dans `markdown_output/` au moment de l'analyse — aucune version convertie n'était présente dans `sources_video/`. Aucune source arXiv ne contient d'information sur le ducking : les spécifications de ducking (seuils, courbes) proviennent des conventions de l'industrie (FFmpeg `sidechaincompress`), marquées [À ÉVALUER].

## 1. Résumé exécutif

Le projet VIDEO s'appuie sur HyperFrames (Apache-2.0, 64,5k stars) pour le rendu vidéo headless Chromium + composition HTML par calques, et construit Aurora-video comme interface d'édition manuelle avancée, en s'inspirant de l'UX d'OpenFilm (référence uniquement, pas de dépendance). Le pipeline complet (script → storyboard → audio → composition HTML → rendu → édition manuelle → export) est validé. LayerT2V (arXiv:2508.04228v2) confirme la faisabilité de la génération multi-calques cohérente et fournit le modèle conceptuel de calques (foreground/background/alpha, prompts par calque), mais reste écarté pour la production (modèle de recherche, 8×H20). CreatiParser (arXiv:2604.19632v2) apporte le concept de calque texte stocké comme **protocole de rendu structuré** (éditable, non rasterisé), directement transposable au schéma de données Aurora-video. SVGDreamer (arXiv:2312.16476v7) renforce le principe de calques vectoriels indépendants, mais ne contient pas de contenu sur timelines/keyframes/easing (vérifié). Les capacités audio (TTS avec horodatage au mot, musique, SFX, ducking par sidechain RMS) sont des composants à implémenter sur le SDK HyperFrames : le ducking n'apparaît dans aucune source arXiv du corpus, ses spécifications proviennent des conventions FFmpeg [À ÉVALUER]. Les pièges documentés (fusion HyperFrames+OpenFilm, API propriétaires, LayerT2V en production, Revideo) sont listés en §7.

## 2. Méthodes et stratégies

> Chaque méthode est notée [VALIDÉ] (issue du contexte projet ou de HyperFrames) ou [À ÉVALUER] (à implémenter ou à décider).

### 2.1 Génération vidéo par calques (LayerT2V)

- **Méthode** : décomposer la vidéo en calques sémantiques (foreground RGB, background RGB, alpha matte) et les générer simultanément dans un processus unifié. La cohérence inter-calques devient un objectif intrinsèque de la génération, pas une post-processing.
- **Source** : arXiv:2508.04228v2, §3.2 (LayerT2V Pipeline)
- **Intérêt pour VIDEO** : valide l'architecture de la timeline HTML/CSS par calques — chaque élément (texte, image, vidéo, SFX) est un calque indépendant avec son propre timing et sa propre animation, rendus ensemble en un seul composite. La séparation sémantique (avant/arrière-plan) est le fondement du modèle de données.
- **État** : [VALIDÉ] en tant que référence conceptuelle d'architecture par calques ; le modèle LayerT2V lui-même est [ÉCARTÉ] pour la production (voir §7).

### 2.2 Synchronisation audio-vidéo par horodatage au mot

- **Méthode** : chaque mot du script TTS est horodaté (word-level timestamps) pour aligner précisément les calques de sous-titres, les transitions de scènes, et les effets sonores sur la timeline. Le timing de chaque élément est défini par des offset/durée en secondes dans le JSON de timeline.
- **Source** : arXiv:2312.17432v8, §II-A (temporal understanding : dense video captioning, temporal grounding, moment retrieval) ; contexte projet (capacité audio)
- **Intérêt pour VIDEO** : le format JSON de timeline (cf. §5) porte ces horodatages au niveau du mot, ce qui permet de synchroniser les keyframes CSS/HTML avec le TTS généré et le ducking de la musique.
- **État** : [VALIDÉ] comme stratégie de synchronisation (contexte projet) ; implémentation des word timestamps [À ÉVALUER] selon le TTS choisi.

### 2.3 Découpage en storyboards et génération de prompts par calque

- **Méthode** : le script est découpé en scènes/storyboards ; pour chaque scène, les prompts textuels sont générés par calque (prompt complet du composant, prompt du foreground, prompt du background) pour décrire indépendamment chaque couche de la composition.
- **Source** : arXiv:2508.04228v2, §3.2 (Layered Cross-Attention Modulation : prompts c_full, c_fg, c_bg encodés indépendamment) ; contexte projet (pipeline script→storyboard)
- **Intérêt pour VIDEO** : chaque storyboard du pipeline est une structure JSON contenant les prompts par calque, les temps de début/fin, les transitions, et les éléments d'animation. La génération des calques vidéo (si utilisée) peut être conditionnée par ces prompts.
- **État** : [VALIDÉ] comme structure de storyboard (contexte projet) ; prompts par calque [À ÉVALUER] si génération vidéo intégrée.

### 2.4 Extraction de calques par segmentation/matting vidéo

- **Méthode** : un pipeline 3 étapes : (1) annotation sémantique du sujet principal par LLM (Qwen3-VL) → caption foreground + caption background ; (2) extraction du foreground par matting vidéo (MatAnyone) sur fond vert + génération du background par Gen-Omnimatte (video matting) ; (3) QC automatique par LLM. Chaque vidéo est décomposée en : foreground video, foreground mask sequence, background video, full video.
- **Source** : arXiv:2508.04228v2, §4.2-4.4 (VidLayer Data Construction Pipeline)
- **Intérêt pour VIDEO** : si le pipeline inclut de la génération de fonds/avatars, cette méthode fournit un protocole pour extraire les calques transparents (alpha matte) nécessaires au compositing HTML/CSS. Les composantes (MatAnyone, Gen-Omnimatte) sont à évaluer pour l'intégration.
- **État** : [À ÉVALUER] — optionnel, hors du socle validé (HyperFrames/Aurora-video).

### 2.5 Analyse raster→calques éditables (CreatiParser)

- **Méthode** : décomposer un design rasterisé en 3 calques sémantiques — texte (stocké comme protocole de rendu éditable : position, bbox, angle, courbe Bézier de courbure, police, taille, couleur, ombre, alignement, z-order), sticker (image RGBA décorative avec canal alpha explicite), background (canvas RGB global). Pour les calques non-textes, diffusion multi-branches avec interaction de tokens inter-calques par position spatiale (Layer Token Attention) ; pour le texte, un VLM prédit le protocole de rendu directement depuis l'image.
- **Source** : arXiv:2604.19632v2, §III (Problem Formulation, Text Rendering Protocol, Multi-Branch Diffusion)
- **Intérêt pour VIDEO** : le concept de calque texte stocké comme **protocole de rendu structuré** (pas des pixels) est directement transposable au JSON de timeline Aurora-video : les calques texte de VIDEO (sous-titres, titres) sont des objets éditables avec propriétés typographiques, et non des images rasterisées. Le schéma à 3 calques texte/sticker/background est un modèle de décomposition pour les visuels de scène (thumbnails, cartes).
- **État** : [À ÉVALUER] — méthodologie de recherche (modèles génératifs écartés par les règles de filtrage) ; seule la **structure de calques** et le concept de « protocole de rendu » sont exploités pour le design du schéma de données.

### 2.6 Motion design et animation de calques vectoriels (SVGDreamer)

- **Méthode** : représentation vectorielle (primitives : courbes de Bézier, polygones, lignes) pour des éléments visuellement éditables, indépendants de la résolution et compacts ; contrôle par primitives individuelles (attention sur primitives + masques d'attention) permettant la manipulation fine d'éléments séparés — analogue au contrôle par calque.
- **Source** : arXiv:2312.16476v7, §I-§III (abstract, SIVE)
- **Intérêt pour VIDEO** : le modèle « chaque élément animé = primitive vectorielle indépendante avec ses paramètres » renforce la stratégie de composition HTML/CSS : les calques de scène restent des nœuds CSS/SVG distincts (et non une image rasterisée compositée) pour préserver l'éditabilité manuelle dans Aurora-video. **Vérification** : le document exploitable de SVGDreamer ne contient pas de contenu sur les timelines animées, keyframes, easing ou SMIL (vérifié par scan) — ces informations sont « non trouvées dans le corpus ».
- **État** : [À ÉVALUER] — uniquement comme principe de représentation vectorielle ; non validé pour le pipeline VIDEO.

### 2.7 QC automatique par LLM multimodal

- **Méthode** : un LLM multimodal (GPT-4o ou équivalent) évalue chaque frame/clé-frame sur des critères définis (fidelity du foreground, artifacts du background, cohérence temporelle) en produisant des scores numériques par critère. Les segments ne passant pas le seuil sont rejetés.
- **Source** : arXiv:2508.04228v2, §4.4 (Automatic Quality Control, prompt GPT-4o Artifacts AutoChecker)
- **Intérêt pour VIDEO** : après le rendu par HyperFrames, un QC automatique par LLM peut valider la qualité de chaque scène avant l'export. Les critères (ghosting, color leakage, paridolia, melting textures) sont documentés et applicables à la vérification des composites.
- **État** : [À ÉVALUER] — QC optionnel post-rendu (attention au piège des benchmarks LLM non reproductibles, §7).

## 3. Techniques d'ingénierie et pipelines

### 3.1 Pipeline de bout en bout (contexte projet + sources)

```
Script → Storyboard → Génération audio → Composition HTML → Rendu → Édition manuelle → Export
```

| Étape | Description | Source | Outils |
|-------|-------------|--------|--------|
| **Script** | Écriture du script narratif (texte brut) | contexte projet | Édition texte / LLM |
| **Storyboard** | Découpage en scènes avec prompts par calque, timing, transitions | arXiv:2508.04228v2 §3.2 (layer prompts) | JSON storyboard |
| **Génération audio** | TTS (mots horodatés), musique, SFX, ducking RMS | contexte projet | API TTS + FFmpeg |
| **Composition HTML** | Construction des scènes en HTML/CSS/JS calqués (keyframes CSS) | contexte projet | HyperFrames SDK |
| **Rendu** | Capture headless Chromium → frames → encodage vidéo | contexte projet | Chromium + FFmpeg |
| **Édition manuelle** | Interface Aurora-video sur le SDK HyperFrames (timeline, calques, keyframes) | contexte projet | Aurora-video (à construire) |
| **Export** | Rendu final + QC + export formats cibles | arXiv:2508.04228v2 §4.4 (QC) | FFmpeg + LLM QC |

### 3.2 Composition HTML5 par scènes (HyperFrames)

- **Méthode** : chaque scène du storyboard est un document HTML5 autonome (ou un calque dans une structure HTML) contenant : calques CSS (position, z-index, opacité, filtres), animations CSS keyframes, éléments vidéo/audio, sous-titres. La composition HTML est rendue par HyperFrames (headless Chromium) en séquence de frames.
- **Source** : contexte projet (HyperFrames comme base de rendu) ; arXiv:2508.04228v2 §3.2 (calques = foreground + background + alpha, composés en un seul stream)
- **Formats de données** : JSON de timeline (cf. §5), HTML/CSS par scène, FFmpeg pour l'encodage.
- **Principe vectoriel (SVGDreamer)** : les calques texte/graphiques de scène sont décrits comme primitives vectorielles indépendantes (Bézier, polygones) pour rester éditables en résolution indépendante — arXiv:2312.16476v7 §I.
- **État** : [VALIDÉ] (HyperFrames) / composition HTML par scènes [VALIDÉ] (contexte projet)

### 3.3 Protocole de validation par LLM (QC)

- **Méthode** : après le rendu, chaque frame critique est passée à un LLM multimodal avec un prompt structuré (4 panneaux : frame originale, mask, background inpainté, foreground extrait). Le LLM score BG et FG de 0 à 10. Seuil d'acceptation : score ≥ 7 sur les 2 frames clés de l'intervalle. Les intervalles avec des scores inférieurs sont rejetés.
- **Source** : arXiv:2508.04228v2 §4.4 + Appendix C.2 (prompt GPT-4o détaillé)
- **Critères documentés** :
  - **BG 0-3 (rejet)** : ghosting/color leakage, floating blobs, paridolia, melting textures
  - **BG 4-6 (médio)** : flou, clone-stamping visible
  - **BG 7-9 (bon)** : propre, shadows cast acceptables
  - **FG 0-3 (rejet)** : blob inidentifiable, bruit
  - **FG 7-9 (bon)** : clair, reconnu, halos légers
  - **10 (parfait)** : sans défaut

### 3.4 Audio : TTS + ducking RMS + synchronisation

- **Méthode** (à implémenter) :
  1. **TTS** : générer le TTS à partir du script ; produire des word-level timestamps (JSON de mots + offset/durée).
  2. **Musique/SFX** : overlay sur la timeline ; placement par offset.
  3. **Ducking** : lorsque le TTS est actif, réduire le volume de la musique (sidechain gain control) ; détection par RMS (Root Mean Square) de la bande TTS pour déclencher la réduction.
  4. **Synchronisation** : les keyframes CSS/HTML et les transitions de scènes sont calées sur les horodatages des mots (offset en secondes).
- **Source** : contexte projet (capacités audio) ; arXiv:2312.17432v8 §II-A (temporal grounding, moment retrieval pour l'alignement)
- **Outils** : FFmpeg (mixage, ducking par sidechaincompress, encodage) ; API TTS locales ou personnelles (cf. §4).
- **État** : [VALIDÉ] comme architecture de production audio (contexte projet) ; l'implémentation TTS/ducking est [À ÉVALUER].

### 3.5 Protocoles de validation par étape

| Étape | Protocole de validation | Format |
|-------|------------------------|--------|
| **Storyboard** | Chaque scène a des prompts par calque, un timing et une transition ; les scènes sont contiguës sans trou sur la timeline | JSON storyboard (schéma §5) |
| **Audio** | Vérifier que les word timestamps couvrent 100 % du texte TTS ; durée totale TTS = durée de la piste ; le ducking n'attaque jamais les SFX exclus | JSON word timestamps + piste audio rendue |
| **Composition HTML** | Chaque scène HTML se rend sans erreur dans Chromium headless ; les z-index sont valides ; les assets (images/vidéos) sont résolus | Page HTML + log de rendu |
| **Rendu** | Chaque frame de sortie est analysée ; seuil de qualité par calque (voir §3.3 si QC LLM activé) ; sinon vérification manuelle sur Aurora-video avant export | Vidéo encodée + rapport QC |
| **Édition manuelle** | L'utilisateur confirme que les keyframes et calques modifiés restent synchrones après ajustement ; le rendu final est revu avant export | Timeline JSON mise à jour |
| **Export** | Les pistes audio et vidéo sont encodées dans les formats cibles ; vérification de la durée et du framerate final | Fichier exporté + log FFmpeg |

## 4. Systèmes, frameworks et bibliothèques recommandés

| Outil | Rôle | Licence | Statut | Source |
|-------|------|---------|--------|--------|
| **HyperFrames** | Base de rendu headless Chromium + SDK d'édition + skills audio/synchronisation | Apache-2.0 (64,5k stars) | **Validé** (base du projet) | contexte projet |
| **Aurora-video** | Interface d'édition manuelle (timeline, calques, keyframes) | À définir | **À construire** (inspiré d'OpenFilm pour l'UX) | contexte projet |
| **OpenFilm** | Référence UX uniquement | — | **Écarté** (pas de dépendance) | contexte projet |
| **FFmpeg** | Encodage vidéo, mixage audio, ducking, export | LGPL | **Validé** (standard) | contexte projet |
| **Chromium** (headless) | Moteur de rendu | Apache-2.0 | **Validé** (intégré à HyperFrames) | contexte projet |
| **TTS local/API** | Synthèse vocale + word-level timestamps | Divers | **À évaluer** (clés perso ou modèles locaux, pas API propriétaire) | contexte projet |
| **Coqui XTTS / TTS local** | TTS auto-hébergé avec timestamps par mot | MIT (à vérifier) | **À évaluer** (conforme à la contrainte d'API personnelles/modèles locaux) | conventions secteur |
| **LayerT2V** | Référence conceptuelle de génération multi-calques | Code à venir | **Écarté** (modèle de recherche, pas de production) | arXiv:2508.04228v2 |
| **Revideo** | Alternative de génération vidéo | — | **Écarté** (équipe partie sur Midrender, risque d'abandon) | contexte projet |
| **MatAnyone / Gen-Omnimatte** | Matting vidéo (extraction calques) | MIT / à vérifier | **À évaluer** (si génération de calques vidéo nécessaire) | arXiv:2508.04228v2 §4.3 |
| **GPT-4o / LLM multimodal** | QC post-rendu | API propriétaire | **À évaluer** (QC uniquement) | arXiv:2508.04228v2 §4.4 |
| **Vid-LLM (analyseurs)** | QC sémantique, storyboard assisté | Divers | **À évaluer** | arXiv:2312.17432v8 |
| **CreatiParser / SVGDreamer** | Références de schémas de calques et de rendu textuel structuré | Recherche | **Non intégrable** (modèles de diffusion ; seuls les schémas sont transposables) | arXiv:2604.19632v2, arXiv:2312.16476v7 |
| **Qwen3-VL / SAM3** | Annotation sémantique et extraction de masks | Apache-2.0 / à vérifier | **À évaluer** (pipeline VidLayer optionnel) | arXiv:2508.04228v2 §4.2 |
| **SDK d'édition Aurora-video** | Construire sur le SDK HyperFrames (timeline, calques, keyframes, édition manuelle) | À définir | **À construire** | contexte projet |

## 5. Schémas de données et structures

### 5.1 JSON de Timeline (format cible Aurora-video)

Le schéma ci-dessous est **proposé** pour l'implémentation (pas documenté dans les sources arXiv ; inspiré par les structures de LayerT2V et le contexte projet).

```json
{
  "project": "aurora-video",
  "version": "1.0",
  "fps": 30,
  "resolution": { "width": 1920, "height": 1080 },
  "duration": 120.0,
  "tracks": [
    {
      "id": "track_video_1",
      "type": "video",
      "source": "scene_01.html",
      "start": 0.0,
      "end": 15.0,
      "zIndex": 1
    },
    {
      "id": "track_audio_tts",
      "type": "audio",
      "source": "narration.wav",
      "start": 0.0,
      "end": 15.0,
      "zIndex": 0,
      "wordTimestamps": [
        { "word": "Bonjour", "offset": 0.5, "duration": 0.8 },
        { "word": "et", "offset": 1.3, "duration": 0.2 },
        { "word": "bienvenue", "offset": 1.5, "duration": 1.1 }
      ]
    },
    {
      "id": "track_audio_music",
      "type": "audio",
      "source": "music_bg.mp3",
      "start": 0.0,
      "end": 120.0,
      "zIndex": 0,
      "ducking": {
        "enabled": true,
        "sidechainSource": "track_audio_tts",
        "thresholdDb": -24,
        "ratio": 4,
        "attackMs": 50,
        "releaseMs": 500
      }
    },
    {
      "id": "track_sfx_1",
      "type": "audio",
      "source": "whoosh.mp3",
      "start": 14.5,
      "end": 15.5,
      "zIndex": 0
    }
  ],
  "scenes": [
    {
      "id": "scene_01",
      "promptFull": "A woman walking down stairs at night",
      "promptForeground": "A blonde woman with red backpack stepping onto a small boat",
      "promptBackground": "A dark dock with calm water and dim lighting",
      "layers": [
        {
          "id": "layer_bg_01",
          "type": "background",
          "asset": "bg_scene01.mp4",
          "start": 0.0,
          "end": 15.0,
          "zIndex": 0
        },
        {
          "id": "layer_fg_01",
          "type": "foreground",
          "asset": "fg_scene01.mov",
          "alpha": "fg_scene01_mask.mov",
          "start": 2.0,
          "end": 13.0,
          "zIndex": 1,
          "animation": {
            "keyframes": [
              { "time": 0.0, "opacity": 0.0, "transform": "translate(0,0)" },
              { "time": 2.0, "opacity": 1.0, "transform": "translate(0,-20px)" },
              { "time": 13.0, "opacity": 1.0, "transform": "translate(0,0)" },
              { "time": 15.0, "opacity": 0.0, "transform": "translate(0,10px)" }
            ]
          }
        },
        {
          "id": "layer_subtitle_01",
          "type": "text",
          "content": "Elle descend les escaliers.",
          "style": { "font": "Inter", "size": 32, "color": "#FFFFFF", "background": "rgba(0,0,0,0.6)" },
          "start": 0.5,
          "end": 4.0,
          "zIndex": 2,
          "animation": {
            "keyframes": [
              { "time": 0.5, "opacity": 0.0 },
              { "time": 0.8, "opacity": 1.0 },
              { "time": 3.7, "opacity": 1.0 },
              { "time": 4.0, "opacity": 0.0 }
            ]
          }
        }
      ],
      "transition": {
        "type": "crossfade",
        "duration": 0.5,
        "targetScene": "scene_02"
      }
    }
  ],
  "qc": {
    "enabled": true,
    "llmProvider": "gpt-4o",
    "threshold": { "bgScore": 7, "fgScore": 7 },
    "keyframeInterval": 10
  }
}
```

### 5.2 Arbre de scènes (hiérarchie)

```
Project
└── Scene_01
    ├── Layer_BG_01 (background video)
    ├── Layer_FG_01 (foreground video + alpha matte)
    ├── Layer_Subtitle_01 (texte animé)
    └── Transition → Scene_02
└── Scene_02
    ├── Layer_BG_02
    ├── Layer_FG_02
    ├── Layer_Text_02
    └── Transition → Scene_03
```

### 5.3 Keyframes CSS/HTML (format de données)

Chaque calque porte un tableau de keyframes : `{ time: secondes, properties: { opacity, transform, filter, position } }`. La composition HTML rend ces keyframes via CSS `@keyframes` ou Web Animations API. Le timing est synchronisé avec les word timestamps du TTS.

### 5.4 Text rendering protocol (arXiv:2604.19632v2)

Schéma de calque texte éditable de CreatiParser, transposable aux calques texte de VIDEO (sous-titres, titres) :

```json
{
  "textLayer": {
    "canvas": { "W": 1920, "H": 1080 },
    "instances": [
      {
        "geometry": { "x": 120, "y": 840, "w": 420, "h": 64, "angle": 0.0,
                       "bend": { "p0": [0,0], "p1": [0,0], "p2": [0,0], "p3": [0,0], "tau": 0 } },
        "semantics": { "string": "Bienvenue", "direction": "ltr" },
        "appearance": { "font": "Inter-Bold", "size": 48, "color": "#FFFFFF",
                         "strokeWidth": 0, "shadow": { "color": "rgba(0,0,0,0.6)", "angle": 90, "blur": 8 },
                         "lineHeight": 1.2, "letterSpacing": 1.0, "emphasis": {} },
        "relation": { "align": "left", "zOrder": 2 }
      }
    ]
  }
}
```

Source : arXiv:2604.19632v2 §III-C (Text Rendering Protocol). Les valeurs de l'exemple sont issues du contexte projet (palette typographique).

### 5.5 Properties de style (palette)

Les propriétés de style (couleurs, polices, opacité, filtres) sont définies dans le JSON par calque et par scène. La palette est à définir selon les besoins du projet (information non trouvée dans le corpus arXiv ; le rapport arXiv:2508.04228v2 décrit les composantes visuelles mais pas de palette de design).

## 6. Règles de conception

### 6.1 Transitions

- **Crossfade** : opacité de la scène N descend de 1→0 pendant que la scène N+1 monte de 0→1 (durée typique 0.3–0.7 s).
- **Cut** : changement instantané (durée 0 s).
- **Wipe/slide** : mouvement horizontal ou vertical d'un élément (défini par les keyframes `transform`).
- **Source** : contexte projet (règles de storyboard) ; les types de transitions ne sont pas documentés dans le corpus arXiv (information non trouvée dans le corpus — règles de conception standard de l'industrie).

### 6.2 Motion design (keyframes)

- **Principe** : chaque calque a une trajectoire d'animation définie par des keyframes temporelles (time, opacity, transform).
- **Synchronisation** : les keyframes des éléments textuels sont calées sur les word timestamps du TTS (un sous-titre apparaît au mot, disparaît au mot suivant).
- **Règle** : les animations des calques foreground s'étalent sur la durée du segment vidéo qu'ils remplacent ; les calques texte s'animent sur la durée du sous-titre.
- **Source** : contexte projet (synchronisation par horodatage au niveau du mot) ; arXiv:2508.04228v2 §3.2 (cohérence temporelle entre calques).

### 6.3 Synchronisation audio (ducking, TTS, horodatage)

- **Ducking** : lorsque le TTS est actif (détection par RMS), le gain de la musique est réduit (sidechain compression). Paramètres typiques (à valider par audition) : threshold -24 dB, ratio 4:1, attack 50 ms, release 500 ms.
- **TTS** : le TTS génère des word-level timestamps (offset + durée par mot) qui servent de référence de timing pour les sous-titres et les transitions.
- **Synchronisation** : les keyframes CSS/HTML sont calées sur ces horodatages. La musique/SFX sont placées par offset sur la timeline.
- **Source** : contexte projet (capacités audio : TTS, musique, SFX, ducking, synchronisation par horodatage au niveau du mot). **Note** : le ducking n'apparaît dans aucune source arXiv du corpus ; les valeurs ci-dessus sont des conventions de l'industrie (FFmpeg `sidechaincompress`), marquées [À ÉVALUER].

### 6.4 Règles de storyboard

- **Structure** : chaque storyboard = une scène avec prompts par calque (full, foreground, background), timing de début/fin, transition vers la scène suivante.
- **Découpage** : le script est découpé en scènes de durée variable (typiquement 10–30 s par scène).
- **Prompts par calque** : le prompt du foreground décrit le sujet principal ; le prompt du background décrit le contexte ; le prompt complet décrit la composition. Les prompts sont générés indépendamment par calque (synchronisation sémantique par LLM).
- **Source** : arXiv:2508.04228v2 §3.2 (Layered Cross-Attention : prompts c_full, c_fg, c_bg) ; contexte projet (pipeline script → storyboard).
- **État** : [VALIDÉ] (contexte projet) ; les durées types 10–30 s sont des conventions standard (information non trouvée dans le corpus).

## 7. Pièges à éviter

| Piège | Description | Source |
|--------|-------------|--------|
| **Fusion HyperFrames + OpenFilm** | Intégrer OpenFilm comme dépendance de HyperFrames crée un coût d'ingénierie disproportionné. OpenFilm est utilisé comme **référence UX** uniquement, pas comme composant. | contexte projet |
| **Dépendance à des API d'images/audio propriétaires** | Utiliser des API propriétaires pour la génération audio ou visuelle crée un verrou (vendor lock-in). Utiliser des clés API personnelles ou des modèles locaux pour le TTS, la musique, et les SFX. | contexte projet |
| **LayerT2V en production** | LayerT2V est un modèle de recherche (3 stages de fine-tuning, 8×H20, 5K steps). Non viable pour la production. Les concepts (calques, alpha mattes) sont exploités, pas le modèle. | arXiv:2508.04228v2 |
| **Revideo** | L'équipe a abandonné Revideo au profit de Midrender. Non maintenu, non recommandé. | contexte projet |
| **Benchmarks LLM non reproductibles** | Les scores GPT-based changent avec les versions de GPT, dépendent du prompt engineering, et le LLM évaluateur favorise ses propres patterns de génération. Ne pas baser les critères de validation sur des benchmarks LLM sans version fixée. | arXiv:2312.17432v8 §IV-B |
| **4D RoPE pour l'identité de calque** | Étendre les position embeddings de 3D à 4D (ajouter un axe calque) perturbe les position embeddings pré-entraînés et dégrade la qualité (flickering, artifacts). L'identité de calque est catégorielle, pas spatiale/temporelle — nécessite un mécanisme de conditioning dédié. | arXiv:2508.04228v2 §5.3 (Ablation Study) |
| **Semantic leakage entre calques** | Sans isolation explicite des prompts par calque, le texte du prompt du foreground peut contaminer le calque background et vice-versa. Utiliser des prompts encodés indépendamment et un mask d'attention par calque. | arXiv:2508.04228v2 §3.2 (Layered Cross-Attention) |
| **MatAnyone sur petits objets** | MatAnyone a des difficultés à segmenter les petits foregrounds sur de longs contextes temporels ; Gen-Omnimatte produit de la texture leakage sur les backgrounds encombrés. Ces failles réduisent le rendement des échantillons multi-foreground. | arXiv:2508.04228v2 §F (Limitations) |
| **Ducking global écrasant les SFX** | Les paramètres de ducking appliqués globalement peuvent masquer des SFX importants. Le ducking doit être déclenché sur la bande TTS uniquement (sidechain), et chaque piste SFX doit pouvoir être exclue de la sidechain. Paramètres typiques (à valider par audition) : threshold -24 dB, ratio 4:1, attack 50 ms, release 500 ms. | conventions FFmpeg `sidechaincompress` (contexte projet) [À ÉVALUER] |
| **Modèles de diffusion en production** | CreatiParser (arXiv:2604.19632v2) et SVGDreamer (arXiv:2312.16476v7) reposent sur des modèles de diffusion (SDXL, VAE 4 canaux RGBA) et du training RL/GRPO. Ces modèles ne sont pas des briques exploitables par le pipeline VIDEO (composition HTML + HyperFrames) ; seuls leurs schémas de calques et de rendu textuel structuré sont transposables. | arXiv:2604.19632v2, arXiv:2312.16476v7 |
| **Alpha mask ≠ RGB** | Les alpha masks sont monocanaux, sparses et quasi binaires — les appliquer directement un VAE RGB pré-entraîné dégrade la reconstruction. Adapter le VAE spécifiquement pour les masks. | arXiv:2508.04228v2 §3.2 (Mask VAE Adaptation) |

## 8. Références

### 8.1 Documents arXiv

| ID | Titre | Utilité principale |
|----|-------|-------------------|
| arXiv:2508.04228v2 | LayerT2V: A Unified Multi-Layer Video Generation Framework | Architecture par calques, prompts par calque, QC par LLM, matting vidéo |
| arXiv:2312.17432v8 | Video Understanding with Large Language Models: A Survey | Taxonomie Vid-LLM, tasks temporels (dense captioning, moment retrieval), benchmarks et évaluation |
| arXiv:2312.16476v7 | SVGDreamer: Text Guided SVG Generation with Diffusion Model | Représentation vectorielle éditable, contrôle par primitives (principe de calques SVG) |
| arXiv:2604.19632v2 | CreatiParser: Generative Image Parsing of Raster Graphic Designs into Editable Layers | Décomposition raster→calques (texte/sticker/background), protocole de rendu texte structuré |

### 8.2 Outils et frameworks (contexte projet)

| Outil | Rôle |
|-------|------|
| HyperFrames | Base de rendu (Apache-2.0, 64,5k stars, SDK d'édition, skills audio) |
| Aurora-video | Interface d'édition (à construire sur HyperFrames, inspiré d'OpenFilm) |
| OpenFilm | Référence UX (pas une dépendance) |
| FFmpeg | Encodage, mixage audio, ducking, export |
| Chromium | Moteur de rendu headless (intégré à HyperFrames) |
| LayerT2V / VidLayer | Référence architecturale (génération multi-calques) |
| MatAnyone / Gen-Omnimatte | Matting vidéo (à évaluer) |
| GPT-4o / Qwen3-VL / SAM3 | QC, annotation, extraction de masks (à évaluer) |
| CreatiParser / SVGDreamer | Références de schémas de calques et de rendu textuel structuré (non intégrables en production) |

### 8.3 Dépôts GitHub mentionnés

| Dépôt | Rôle |
|-------|------|
| `https://layert2v.github.io` | Page du projet LayerT2V (code et dataset VidLayer à venir) |
| `https://github.com/yunlong10/Awesome-LLMs-forVideo-Understanding` | Repository du survey Vid-LLM (ressources et références) |
| `https://github.com/showlab/VLog` | Outil de conversion vidéo→document (Vid-LLM Summarizer) |

### 8.4 Articles et modèles mentionnés dans le corpus

| Référence | Type |
|-----------|------|
| MatAnyone (Yang et al., 2025, CVPR) | Matting vidéo stable |
| Gen-Omnimatte (Lee et al., 2025, CVPR) | Video matting / décomposition |
| SAM3 (Carion et al., 2025) | Prompt-to-mask segmentation |
| Qwen3-VL (Bai et al., 2025) | LLM vision pour annotation |
| GPT-4o (OpenAI, 2024) | QC multimodal |
| Wan2.1 (Wan et al., 2025) | Modèle de génération vidéo (base de LayerT2V) |
| LayerFlow (Ji et al., 2025, SIGGRAPH) | Génération multi-calques (pré-écurie de LayerT2V) |
| VBench (Huang et al., 2023) | Benchmark d'évaluation de génération vidéo |

> **Note** : Les informations sur HyperFrames (license Apache-2.0, 64,5k stars, SDK d'édition, skills audio), OpenFilm (référence UX), Revideo (équipe partie sur Midrender), et le pipeline complet (script → storyboard → audio → composition HTML → rendu → édition → export) proviennent du **contexte projet** fourni, non des documents arXiv. Les informations de LayerT2V et du survey Vid-LLM proviennent des documents arXiv lus.
