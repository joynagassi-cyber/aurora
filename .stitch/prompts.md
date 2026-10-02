# Bibliothèque de prompts — Thèmes visuels V3

## Direction artistique corrigée

Cette version corrige une dérive vers des images trop minimalistes, trop plates ou trop « aquarelle générique ».
La référence visuelle est la famille d'illustrations montrée dans les captures de l'application : des scènes riches, nettes, colorées, immédiatement lisibles, avec beaucoup de petits détails, mais sans surcharge.


### IDENTITÉ CHROMATIQUE — RÈGLE OBLIGATOIRE

La couleur n'est pas une décoration secondaire : elle constitue la signature du thème. Chaque thème possède une **couleur phare verrouillée**, définie par un code HEX précis.

Règles obligatoires :
- La couleur phare doit être explicitement citée dans **les deux prompts** du thème.
- Utiliser exactement la teinte HEX indiquée comme référence chromatique principale ; ne pas la remplacer par une couleur générique voisine.
- La couleur phare doit être **visiblement dominante**, présente sur plusieurs surfaces ou groupes visuels importants, et ne doit surtout pas être réduite à un simple petit accent.
- Viser environ **25 à 40 % de la masse chromatique visible** pour la couleur phare, selon la scène.
- Les couleurs secondaires servent à créer du contraste, de la profondeur et de la fraîcheur.
- Maintenir des zones claires pour respirer : blanc cassé, lumière, ciel, brume ou surfaces claires selon le thème.
- Les ombres doivent rester colorées et fraîches ; éviter les noirs boueux.
- La couleur phare doit être cohérente entre la couverture paysage et l'image portrait : **même identité, même palette, même température de couleur**.
- Une couleur chaude peut être la couleur phare lorsque le thème l'exige, mais l'image complète doit rester claire, fraîche et équilibrée ; ne jamais transformer le thème en dominante orange/jaune lourde.
- Ne pas utiliser de gradient générique multicolore pour remplacer la palette du thème.

### TABLE DES COULEURS PHARES

| Thème | Couleur phare | HEX | Palette de support |
|---|---|---|---|
| New York | Cobalt Liberty Blue | `#2563EB` | `#2563EB`, `#14B8C4`, `#E8F0FF`, `#64748B`, `#D94B4B` |
| Tokyo | Vermilion Torii Red | `#E23B45` | `#E23B45`, `#F4A6C1`, `#20B8D2`, `#F8F3E8`, `#243A73` |
| Paris | Paris Blue | `#3D6FD8` | `#3D6FD8`, `#F6F2E8`, `#7B8794`, `#6DBB8A`, `#D7C08A` |
| Londres | Westminster Emerald | `#12A878` | `#12A878`, `#74BCEB`, `#F3F5F2`, `#66717C`, `#C93E4B` |
| Dubaï | Dubai Turquoise | `#19A7A8` | `#19A7A8`, `#DCC79A`, `#F5F1E8`, `#5A83A6`, `#1D2E59` |
| Sydney | Harbour Cyan | `#00A9C7` | `#00A9C7`, `#4ED3C7`, `#FFFFFF`, `#4A86C5`, `#F28B7A` |
| Printemps | Spring Leaf Green | `#68C27B` | `#68C27B`, `#F19BBC`, `#7CCBEB`, `#FFF9F1`, `#E5C65B` |
| Été | Summer Aqua | `#19B8D8` | `#19B8D8`, `#31D0C0`, `#F6EBD2`, `#5B9BEA`, `#E4C65A` |
| Automne | Autumn Rust Coral | `#C95B43` | `#C95B43`, `#D98335`, `#3F8B72`, `#8EA8BF`, `#F1E8D8` |
| Hiver | Winter Ice Blue | `#74A9E8` | `#74A9E8`, `#A7D7F2`, `#FFFFFF`, `#71829A`, `#C9D0D8` |
| Noël | Christmas Berry Red | `#C92F50` | `#C92F50`, `#1F7A5B`, `#E4C45C`, `#F8F4EA`, `#4F6EAA` |
| Pâques | Easter Orchid Pink | `#D987B5` | `#D987B5`, `#8DCC86`, `#F4D76E`, `#F8F5EA`, `#78BFE0` |
| Nouvel An | Midnight Electric Violet | `#704CFF` | `#704CFF`, `#D5C8FF`, `#F4F1FF`, `#D8C75E`, `#2C3C73` |
| Fête | Festival Fuchsia | `#F23DAA` | `#F23DAA`, `#20C9E8`, `#FFCC45`, `#6D4DFF`, `#F7F4EF` |
| Paix | Peace Sage | `#78B29A` | `#78B29A`, `#E8EEE7`, `#D8DDE1`, `#FFFFFF`, `#78A8C8` |
| Impressionnisme | Impressionist Mint Teal | `#62B59F` | `#62B59F`, `#5B9AD6`, `#C894D8`, `#F2A8B7`, `#F8F2E8` |
| Jazz | Jazz Royal Purple | `#7657D9` | `#7657D9`, `#425B92`, `#C8875B`, `#F2EEE7`, `#C85AA5` |
| Street Art | Urban Magenta | `#E83D7C` | `#E83D7C`, `#11BFD2`, `#F1C62E`, `#6E4BEA`, `#D7DEE3` |
| Ballet | Ballet Lilac | `#B69ADF` | `#B69ADF`, `#E8B7D3`, `#F7F1E8`, `#AEB8C8`, `#D5BE78` |
| Sculpture | Gallery Mineral Blue | `#4E8BCE` | `#4E8BCE`, `#F3F0E7`, `#B5BDC7`, `#DDEBFA`, `#2F5DA8` |
| Volcans | Lava Crimson | `#D9473F` | `#D9473F`, `#FF764A`, `#25384A`, `#8E9BA8`, `#F4EEE3` |
| Glacier | Arctic Cyan | `#2CB9D4` | `#2CB9D4`, `#286CC4`, `#F9FDFF`, `#B7C4D8`, `#9C8ED8` |
| Dunes | Cool Sand Gold | `#C9A76B` | `#C9A76B`, `#F0E4CC`, `#8AB7D6`, `#C87964`, `#5F7D86` |
| Jungle | Jungle Emerald | `#22B36F` | `#22B36F`, `#0F7C59`, `#8FD85C`, `#54B9C7`, `#F2E7BF` |
| Ponts | Bridge Signal Red | `#D8444B` | `#D8444B`, `#3C78B8`, `#1BA6A6`, `#F3EEE4`, `#6B8F63` |
| Afrique | Contemporary Terracotta | `#C96F4A` | `#C96F4A`, `#2D946B`, `#3C9CC7`, `#F3E2C5`, `#D6A33A` |

### ADN VISUEL COMMUN

Toutes les images doivent ressembler à des **illustrations digitales premium de collection**, avec une composition de scène complète et une vraie sensation de thème visuel.

- Illustration digitale contemporaine, raffinée et très propre.
- Rendu illustratif, pas photographie, pas 3D réaliste, pas stock image.
- Couleurs **vives, fraîches, lumineuses et nettes**.
- Couleurs saturées mais jamais sales, fluorescentes ou agressives.
- Chaque thème possède une **palette immédiatement identifiable**, avec 3 à 5 couleurs dominantes et 1 accent éventuel.
- Contraste clair et lisible.
- Lumière fraîche, lumineuse et diffuse.
- Ambiance vivante, énergique et positive, jamais terne.
- Éviter la dominante orange, jaune chaud, sépia ou coucher de soleil sauf nécessité réelle du thème.
- Éviter le marron lourd, les ombres boueuses, les noirs bouchés et les couleurs grises sans vie.
- Donner de la profondeur avec premier plan, sujet principal, arrière-plan et éléments intermédiaires.
- Ajouter de nombreux détails contextuels cohérents : architecture, végétation, objets, textures, nuages, reflets, petites silhouettes, reliefs, décor.
- Les détails doivent enrichir la scène sans transformer l'image en collage.
- Utiliser des formes fluides, des contours nets et des transitions de couleurs propres.
- Les éléments principaux doivent être immédiatement reconnaissables même à petite taille.
- La scène doit donner l'impression d'un **monde complet**, pas d'un objet isolé flottant sur un fond vide.
- Style proche d'une illustration éditoriale moderne haut de gamme destinée à une application grand public.
- Aspect légèrement ludique et élégant, mais jamais enfantin.
- Les images d'une même collection doivent partager la même qualité, profondeur, clarté et logique de lumière.

### CE QU'IL FAUT ÉVITER

Ne pas interpréter « propre » comme « minimaliste ».

Ne pas réduire le thème à un seul objet isolé sur un fond uni.
Ne pas créer une composition vide.
Ne pas utiliser un rendu monochrome pauvre.
Ne pas utiliser une palette pastel délavée par défaut.
Ne pas utiliser une aquarelle blanche et beige sans profondeur.
Ne pas faire de photographie.
Ne pas faire de rendu hyperréaliste.
Ne pas faire d'illustration générique de banque d'images.

### LUMIÈRE

La lumière doit être claire, fraîche et vivante :
- lumière naturelle diffuse ;
- ciel lumineux ;
- ombres douces ;
- reflets propres ;
- légère sensation de profondeur atmosphérique.

Éviter :
- coucher de soleil orange ;
- dominante dorée excessive ;
- lumière jaune épaisse ;
- glow artificiel ;
- HDR agressif ;
- contraste dramatique de film ;
- scène sombre et lourde.

### COULEUR

La couleur est un élément majeur de l'identité du thème.
Elle doit être riche et volontaire.

Chaque image doit avoir :
1. une couleur dominante forte ;
2. une ou deux couleurs secondaires ;
3. une couleur d'accent identifiable ;
4. des tons clairs pour respirer ;
5. des ombres colorées plutôt que des noirs plats.

La combinaison doit être vive mais élégante.

### COMPOSITION

Construire une véritable scène avant de détailler les objets.

Pour chaque image :
- un sujet principal clair ;
- 2 à 5 éléments secondaires ;
- un premier plan subtil ;
- un plan intermédiaire ;
- un arrière-plan détaillé ;
- une perspective cohérente ;
- un point focal fort ;
- des zones respirantes ;
- des détails qui racontent le thème.

Les compositions doivent être riches et fluides, similaires à une illustration premium de galerie mobile.

### COVER — PAYSAGE

Format : 16:9.

Objectif : faire choisir le thème.

Le cover doit être **plus spectaculaire et immédiatement lisible** que l'image appliquée.
Le sujet doit être identifiable en moins d'une seconde.
La scène doit avoir une composition panoramique avec plusieurs plans et suffisamment de petits détails pour donner envie d'ouvrir le thème.

### APPLICATION — PORTRAIT

Format : 4:5, ou 9:16 si le moteur permet directement ce format.

Objectif : devenir l'image réelle du thème dans l'application.

Le portrait doit reprendre exactement la même identité visuelle que le cover, mais avec une composition pensée verticalement.
Le sujet principal devient plus immersif.
Les détails restent riches.
Une partie du ciel, du décor ou d'une zone plus calme peut laisser respirer l'interface.

### QUALITÉ

Toujours viser :
- 4K-quality source rendering ;
- ultra high detail ;
- clean edges ;
- polished materials ;
- refined textures ;
- accurate architecture ;
- coherent perspective ;
- rich but controlled details ;
- crisp colors ;
- premium finish.

Important : « 4K » décrit le niveau de détail attendu. Le générateur doit aussi être configuré techniquement avec la résolution maximale disponible et, si nécessaire, une étape d'upscale.

### NÉGATIF COMMUN

Ajouter à la fin de chaque prompt :

> no text, no typography, no letters, no words, no logo, no watermark, no UI, no frame, no border, no collage, no split screen, no multiple scenes, no isolated object on empty background, no flat empty composition, no washed-out colors, no muddy colors, no brown cast, no excessive orange, no excessive yellow, no sepia, no heavy warm light, no dark heavy shadows, no artificial glow, no neon overload, no excessive blur, no excessive noise, no generic stock illustration, no cheap clipart, no photorealism, no plastic 3D render, no visual artifacts

---

# 1. Villes

## 1.1 New York

### Identité chromatique du thème

**Couleur phare obligatoire : Cobalt Liberty Blue — `#2563EB`.**

Palette verrouillée : #2563EB, #14B8C4, #E8F0FF, #64748B, #D94B4B.

The Statue of Liberty, sky reflections, selected architectural accents and small visual anchors use the cobalt hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of New York City for a mobile theme-selection cover, landscape 16:9. Build a complete lively city scene rather than an isolated landmark. The Statue of Liberty is the main focal point, large and instantly recognizable, placed slightly left of center. In the middle distance, create a layered Manhattan skyline with varied skyscraper silhouettes, rooftop details, windows and subtle atmospheric separation. The lower third contains the Hudson River with clean blue reflections, a small ferry, riverside promenade details and subtle greenery. Add a few tiny distant pedestrians and city-scale details for life without making them focal subjects. Use a refined contemporary illustrated style with smooth shapes, crisp edges, subtle painterly texture and elegant depth. Color identity: clear sky blue, deep cobalt, cool turquoise, ivory and a restrained red accent. Bright cool daylight, luminous sky, fresh atmosphere, soft cloud forms and clean reflections. Rich visual detail, flowing composition, strong focal hierarchy, premium 4K-quality detail, attractive at thumbnail size and clearly recognizable as New York. Exact chromatic anchor: use **Cobalt Liberty Blue `#2563EB`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #14B8C4, #E8F0FF, #64748B, #D94B4B, while keeping the image bright, clear and cool rather than warm.

### Application — 4:5

> Premium polished digital illustration of New York City for the applied mobile theme, portrait 4:5. Create an immersive vertical city scene with the Statue of Liberty as the dominant focal point, rising through the central-left area. Surround it with a richer layered environment: Hudson River in the foreground, a ferry and subtle water reflections, Manhattan skyline in the middle distance, distant bridges and small urban details. Include refined window patterns, rooftop silhouettes, trees and a few tiny human figures for scale. Use the same contemporary premium illustrated language as the cover: crisp forms, fluid transitions, layered depth, fine painterly texture and clean edges. Color identity: cobalt blue, turquoise, ivory, cool gray and a restrained red accent. Bright cool daylight, luminous air, fresh blue atmosphere and soft shadows. Keep a calm patch of sky around the upper subject for interface readability, while the scene remains visually rich and alive. Exact chromatic anchor: use **Cobalt Liberty Blue `#2563EB`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #14B8C4, #E8F0FF, #64748B, #D94B4B, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality rendering.
## 1.2 Tokyo

### Identité chromatique du thème

**Couleur phare obligatoire : Vermilion Torii Red — `#E23B45`.**

Palette verrouillée : #E23B45, #F4A6C1, #20B8D2, #F8F3E8, #243A73.

The torii, lantern accents and selected blossom details use the vermilion hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of Tokyo for a mobile theme-selection cover, landscape 16:9. Build a vivid Japanese city-meets-tradition scene. A refined red torii stands as the primary focal point near the center-left, surrounded by flowering cherry trees. Behind it, a compact layered Tokyo skyline mixes modern towers with subtle traditional rooflines. Add hanging lanterns, a narrow walkway, a small bridge, delicate petals moving through the air and distant mountain silhouettes. Use clean contemporary illustration with elegant Japanese visual rhythm, crisp forms, subtle painterly texture and rich layered depth. Color identity: fresh cyan sky, cherry pink, vermilion red, ivory and deep indigo. Keep colors clear and vivid, never muddy. Bright cool daylight, luminous atmosphere and soft cloud layers. The scene should feel alive, sophisticated and distinctly Tokyo, with many small details visible on closer inspection while remaining immediately readable as a thumbnail. Exact chromatic anchor: use **Vermilion Torii Red `#E23B45`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F4A6C1, #20B8D2, #F8F3E8, #243A73, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished Japanese digital illustration of Tokyo for the applied mobile theme, portrait 4:5. Create a richer vertical composition centered on a beautiful vermilion torii surrounded by layered cherry blossom branches, lanterns and a small traditional pathway. In the distance, reveal a refined Tokyo skyline, temple rooflines and a soft mountain silhouette. Add subtle petals, stone texture, wood grain and atmospheric layers to make the scene feel complete and alive. Use crisp contemporary illustrated forms, fluid shapes, delicate painterly texture and clear depth rather than sparse minimalism. Color identity: vermilion, sakura pink, fresh cyan, ivory and deep indigo. Bright cool daylight with soft shadows and clean luminous air. Preserve a calmer upper region for interface readability while keeping the overall scene richly detailed. Exact chromatic anchor: use **Vermilion Torii Red `#E23B45`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F4A6C1, #20B8D2, #F8F3E8, #243A73, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality, elegant and highly recognizable.
## 1.3 Paris

### Identité chromatique du thème

**Couleur phare obligatoire : Paris Blue — `#3D6FD8`.**

Palette verrouillée : #3D6FD8, #F6F2E8, #7B8794, #6DBB8A, #D7C08A.

The sky, water reflections and selected Parisian details use the Paris blue hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of Paris for a mobile theme-selection cover, landscape 16:9. Create a charming complete Parisian riverside scene, not simply a picture of the Eiffel Tower. The Eiffel Tower is the main focal point, slightly left of center. Build the Seine across the foreground with two elegant stone bridges, small sightseeing boats, reflections and a riverside promenade. Behind the water, show layered Haussmann buildings with pale facades, dark roofs, balconies, trees and subtle café details. Add tasteful flowers and street lamps in the foreground. Use a refined contemporary illustrated style with crisp architecture, fluid shapes, subtle painterly texture and rich but controlled detail. Color identity: luminous Paris blue, ivory, cool gray, fresh green and a restrained champagne accent. Bright cool daylight, clean sky, soft clouds and fresh reflections, avoiding any orange sunset appearance. Make it vivid, elegant, lively and immediately desirable as a theme. Exact chromatic anchor: use **Paris Blue `#3D6FD8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F6F2E8, #7B8794, #6DBB8A, #D7C08A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of Paris for the applied mobile theme, portrait 4:5. Create an immersive vertical Seine scene with the Eiffel Tower as the unmistakable central anchor. The lower section contains calm water with layered reflections, a small boat and a stone embankment. Middle layers contain a bridge, trees, café umbrellas, street lamps and refined Haussmann facades. Include flower boxes, balconies, window patterns and small distant figures to make the city feel inhabited. Use crisp contemporary illustrated architecture, fluid color transitions and subtle painterly texture. Color identity: cool blue, ivory, Parisian gray, fresh green and restrained champagne. Bright cool daylight, clean luminous sky, soft shadows and no heavy warm cast. Leave one calm region around the upper background for interface readability. Rich and sophisticated without clutter. Exact chromatic anchor: use **Paris Blue `#3D6FD8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F6F2E8, #7B8794, #6DBB8A, #D7C08A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 1.4 Londres

### Identité chromatique du thème

**Couleur phare obligatoire : Westminster Emerald — `#12A878`.**

Palette verrouillée : #12A878, #74BCEB, #F3F5F2, #66717C, #C93E4B.

The hero color appears in wet reflections, selected architecture details, foliage and subtle signage accents. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of London for a mobile theme-selection cover, landscape 16:9. Create a complete lively Westminster scene with Big Ben as the primary focal point. The River Thames crosses the foreground with clean reflections, a small red double-decker bus or black taxi provides a secondary color accent, and Westminster architecture creates depth. Add a stone bridge, riverside railing, lampposts, subtle trees, distant pedestrians and a few soft rain droplets that catch the light. The rain should make the scene fresh rather than dark. Style: refined contemporary urban illustration with crisp architectural geometry, smooth shapes, subtle painterly texture and rich layered details. Color identity: clear cool blue, emerald green, ivory, muted gray and a controlled classic red accent. Bright overcast daylight, luminous cloud cover, wet surfaces and fresh atmosphere. Avoid gloomy cinematic darkness and avoid warm yellow lighting. Exact chromatic anchor: use **Westminster Emerald `#12A878`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #74BCEB, #F3F5F2, #66717C, #C93E4B, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality and strongly recognizable as London.

### Application — 4:5

> Premium polished digital illustration of London for the applied mobile theme, portrait 4:5. Big Ben and Westminster dominate the vertical center, with the Thames receding into the lower section. Add a small black taxi or red bus, stone embankment, ornate lamps, trees, subtle rain droplets and distant architecture. Create clean wet reflections on pavement and water, with small details in stone, windows and railings. Use contemporary illustrated geometry, fluid shapes, fine texture and layered atmospheric depth. Color identity: cool sky blue, emerald, ivory, gray and controlled London red. Bright fresh overcast light, soft rain and clear visibility rather than a dark storm. Leave a calm upper region for UI. Rich, polished, premium 4K-quality. Exact chromatic anchor: use **Westminster Emerald `#12A878`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #74BCEB, #F3F5F2, #66717C, #C93E4B, while keeping the image bright, clear and cool rather than warm.
## 1.5 Dubaï

### Identité chromatique du thème

**Couleur phare obligatoire : Dubai Turquoise — `#19A7A8`.**

Palette verrouillée : #19A7A8, #DCC79A, #F5F1E8, #5A83A6, #1D2E59.

The sky, water features and cool reflective surfaces carry the turquoise hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of Dubai for a mobile theme-selection cover, landscape 16:9. The Burj Khalifa is the dominant focal point, architecturally precise and visually elegant. Surround it with a complete modern city environment: reflective towers, landscaped avenues, palms, water features and sculpted pale desert dunes in the foreground. Add subtle geometric Arab architectural details and distant city scale. Use clean contemporary illustration, fluid shapes, refined gradients, crisp structures and delicate material textures. Color identity: clear turquoise sky, pale sand, ivory, cool metallic blue and restrained deep midnight blue. Bright neutral daylight with cool atmospheric clarity. Avoid fiery desert sunsets and excessive gold. The theme should feel fresh, modern, luxurious and alive, with enough small details to reward inspection. Exact chromatic anchor: use **Dubai Turquoise `#19A7A8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #DCC79A, #F5F1E8, #5A83A6, #1D2E59, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of Dubai for the applied mobile theme, portrait 4:5. Place the Burj Khalifa as the strong vertical centerpiece, surrounded by layered modern towers, palms, landscaped water features and softly curving pale dunes. Add subtle geometric Middle Eastern architectural details and distant streets with tiny figures and vehicles for scale. Keep the style clean, fluid and richly illustrated, with precise architecture and elegant depth. Color identity: turquoise, pale sand, ivory, cool steel blue and deep midnight blue. Bright cool-neutral daylight, crisp air and controlled soft shadows. No orange desert haze, no fiery sunset. Keep the upper sky relatively calm for UI, while the lower scene contains rich environmental detail. Exact chromatic anchor: use **Dubai Turquoise `#19A7A8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #DCC79A, #F5F1E8, #5A83A6, #1D2E59, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 1.6 Sydney

### Identité chromatique du thème

**Couleur phare obligatoire : Harbour Cyan — `#00A9C7`.**

Palette verrouillée : #00A9C7, #4ED3C7, #FFFFFF, #4A86C5, #F28B7A.

Harbor water, sky and selected coastal reflections use the cyan hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of Sydney for a mobile theme-selection cover, landscape 16:9. The Sydney Opera House is the main focal point, with its white sculptural sails clearly defined. Build a complete vibrant harbor scene: Harbour Bridge behind it, turquoise water, small boats, waterfront trees, modern buildings and subtle coastal details. Add layered clouds and a fresh blue sky. Use fluid contemporary illustrated shapes, crisp architecture, subtle painterly texture and luminous reflections. Color identity: vivid cyan, turquoise, clean white, fresh blue and a restrained pale coral accent. Bright cool coastal daylight, transparent atmosphere, soft shadows and lively but controlled reflections. No hot orange sunrise or sunset. The scene should feel fresh, optimistic and distinctly Australian while retaining a premium sophisticated application aesthetic. Rich details and strong thumbnail readability. Exact chromatic anchor: use **Harbour Cyan `#00A9C7`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #4ED3C7, #FFFFFF, #4A86C5, #F28B7A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of Sydney for the applied mobile theme, portrait 4:5. Make the Sydney Opera House the dominant central subject, surrounded by Harbour Bridge, harbor water, small boats, coastal vegetation, waterfront buildings and subtle distant hills. Add sail, glass, stone and water textures with multiple depth layers. Use a fluid contemporary illustrated style with crisp edges, refined painterly transitions and lively but controlled details. Color identity: cyan, turquoise, bright white, clean blue and a restrained pale coral accent. Bright cool coastal daylight, clear air and soft shadows. Keep the upper sky calmer for interface elements, while the lower half remains richly detailed. No warm orange cast. Exact chromatic anchor: use **Harbour Cyan `#00A9C7`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #4ED3C7, #FFFFFF, #4A86C5, #F28B7A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

---

# 2. Saisons
## 2.1 Printemps

### Identité chromatique du thème

**Couleur phare obligatoire : Spring Leaf Green — `#68C27B`.**

Palette verrouillée : #68C27B, #F19BBC, #7CCBEB, #FFF9F1, #E5C65B.

Fresh foliage and large botanical shapes visibly carry the spring green hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of spring, landscape 16:9, designed as a vivid mobile theme-selection cover. Create a complete blooming park scene with flowering cherry trees, fresh green grass, colorful wildflowers, a winding path, a small bench, birds and delicate petals carried by a light breeze. The foreground should contain rich flower and leaf detail, while the middle ground contains a playful path and distant trees. Use a clean contemporary illustrative style with fluid shapes, crisp edges, layered depth and soft painterly texture. Palette: fresh leaf green, cherry pink, sky blue, ivory and a restrained yellow accent. Bright cool daylight, luminous atmosphere, soft clouds and fresh air. No warm orange light. The image should feel alive, optimistic and richly detailed without looking childish. Exact chromatic anchor: use **Spring Leaf Green `#68C27B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F19BBC, #7CCBEB, #FFF9F1, #E5C65B, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of spring, portrait 4:5. Create an immersive blooming garden with flowering cherry branches framing the composition, lush fresh grass, layered flower beds, a curving path, a bench, small birds and floating petals. Build depth from detailed foreground plants to softer distant trees. Use fluid contemporary illustration, crisp forms and subtle painterly texture. Palette: fresh green, sakura pink, sky blue, ivory and a small yellow accent. Bright cool daylight, clean luminous air, soft shadows and no warm orange cast. Leave a relatively calm sky region for the interface while keeping the garden rich and alive. Exact chromatic anchor: use **Spring Leaf Green `#68C27B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F19BBC, #7CCBEB, #FFF9F1, #E5C65B, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 2.2 Été

### Identité chromatique du thème

**Couleur phare obligatoire : Summer Aqua — `#19B8D8`.**

Palette verrouillée : #19B8D8, #31D0C0, #F6EBD2, #5B9BEA, #E4C65A.

The sea, wave highlights and major summer shapes carry the aqua hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of summer, landscape 16:9. Create a lively crystal-clear coastal scene with turquoise water, a bright sandy beach, palm trees, colorful beach accessories, a small sailboat and distant rocky islands. Add soft clouds, subtle wave patterns, shells and fine sand texture. Use a contemporary illustrated style with fluid forms, crisp edges, layered depth and vivid but controlled colors. Palette: clean cyan, turquoise, fresh blue, ivory cream and a restrained sunny yellow. Bright cool daylight rather than hot golden light. The scene should feel refreshing, open, energetic and luxurious, with enough environmental details to feel like a real place rather than a symbol. Exact chromatic anchor: use **Summer Aqua `#19B8D8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #31D0C0, #F6EBD2, #5B9BEA, #E4C65A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of summer, portrait 4:5. Build an immersive tropical shoreline with crystal turquoise water, layered gentle waves, a pale beach, palms, a small sailboat, distant islands, beach objects and subtle shells. Use clean fluid illustration with crisp edges, fine sand and water texture and rich depth. Palette: turquoise, cyan, ivory, fresh blue and restrained yellow. Bright cool daylight, fresh atmosphere, soft shadows and no orange heat haze. Preserve an open region toward the upper sky for UI. Exact chromatic anchor: use **Summer Aqua `#19B8D8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #31D0C0, #F6EBD2, #5B9BEA, #E4C65A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 2.3 Automne

### Identité chromatique du thème

**Couleur phare obligatoire : Autumn Rust Coral — `#C95B43`.**

Palette verrouillée : #C95B43, #D98335, #3F8B72, #8EA8BF, #F1E8D8.

Maple foliage and key leaf clusters carry the rust-coral hero color, balanced by cool greens and blue-gray. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of autumn, landscape 16:9. Create a rich northern forest-and-lake scene with orange and rust maple trees, evergreen layers, a reflective lake, a winding path, scattered leaves and distant mountains. Keep the palette vibrant but clean rather than brown and heavy. Use contemporary illustrated forms, refined painterly texture and multiple depth layers. Palette: fresh rust orange, coral-red leaves, cool green, clear blue-gray and ivory. Light is bright and cool, filtered through clouds, with gentle reflections and no fiery sunset. The image should feel crisp, colorful, calm and alive. Exact chromatic anchor: use **Autumn Rust Coral `#C95B43`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #D98335, #3F8B72, #8EA8BF, #F1E8D8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished digital illustration of autumn, portrait 4:5. Build a richly layered forest scene opening onto a clear reflective lake, with orange maples, red leaves, evergreen trees, distant mountains and a winding path. Add individual leaves in the foreground and subtle mist near the water. Use crisp contemporary illustration, fluid shapes, refined texture and strong depth. Palette: rust orange, crimson-red, cool green, blue-gray and ivory. Bright cool autumn daylight, fresh air and controlled shadows. No warm orange haze and no dark brown grading. Keep a calm patch of sky or mountain haze for interface readability. Exact chromatic anchor: use **Autumn Rust Coral `#C95B43`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #D98335, #3F8B72, #8EA8BF, #F1E8D8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 2.4 Hiver

### Identité chromatique du thème

**Couleur phare obligatoire : Winter Ice Blue — `#74A9E8`.**

Palette verrouillée : #74A9E8, #A7D7F2, #FFFFFF, #71829A, #C9D0D8.

Snow shadows, sky, ice and atmospheric layers use the ice-blue hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished digital illustration of winter, landscape 16:9. Create a vivid snowy mountain village with snow-covered pine trees, a frozen stream, cozy but clean rooftops, distant alpine peaks, falling snow and subtle blue atmospheric layers. Use rich snow textures and clear silhouettes rather than a flat white background. Palette: icy blue, deep cobalt, white, pale silver and a restrained warm red accent on rooftops. Bright cold daylight, luminous snow, crisp air and soft shadows. Keep the scene cool and fresh, not gloomy. Exact chromatic anchor: use **Winter Ice Blue `#74A9E8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #A7D7F2, #FFFFFF, #71829A, #C9D0D8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality, detailed but clean.

### Application — 4:5

> Premium polished digital illustration of winter, portrait 4:5. Create an immersive alpine landscape with snow-heavy pines in the foreground, a small village, frozen stream, distant mountains and softly falling snow. Add detailed branches, roof textures, ice reflections and atmospheric layers. Palette: icy blue, cobalt, white, pale silver and restrained red. Bright cool daylight, luminous snow and transparent cold air. No dirty gray snow, no dark storm and no warm orange cast. Preserve a calmer region in the sky for UI. Exact chromatic anchor: use **Winter Ice Blue `#74A9E8`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #A7D7F2, #FFFFFF, #71829A, #C9D0D8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

---

# 3. Événements
## 3.1 Noël

### Identité chromatique du thème

**Couleur phare obligatoire : Christmas Berry Red — `#C92F50`.**

Palette verrouillée : #C92F50, #1F7A5B, #E4C45C, #F8F4EA, #4F6EAA.

The hero red anchors ornaments, ribbons and focal festive details without creating a warm orange cast. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished festive digital illustration of Christmas, landscape 16:9. Create a complete elegant winter celebration scene: a beautifully decorated fir tree as the central focal point, luminous ornaments, wrapped gifts, snow-covered windows, small warm-white lights and falling snow. Use a bright clean illustrated style rather than dark holiday realism. Palette: vivid fir green, clean red, ivory, clear snow blue and restrained champagne gold. Keep lighting luminous and controlled, with warm lights used only as small accents instead of dominating the image. Add pine branches, ribbons and tiny decorative details throughout the scene. Rich, colorful, premium and inviting. Exact chromatic anchor: use **Christmas Berry Red `#C92F50`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #1F7A5B, #E4C45C, #F8F4EA, #4F6EAA, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished Christmas illustration, portrait 4:5. Make a decorated fir tree the central immersive subject, surrounded by ornaments, ribbon details, gifts, snow-covered windows, pine branches and softly falling snow. Use crisp contemporary shapes, subtle painterly texture, clear depth and refined decoration. Palette: fir green, red, ivory, cool snow blue and restrained champagne gold. Keep holiday lights as delicate accents rather than a heavy yellow glow. Bright clean atmosphere, cool surrounding light and vivid color. Exact chromatic anchor: use **Christmas Berry Red `#C92F50`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #1F7A5B, #E4C45C, #F8F4EA, #4F6EAA, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 3.2 Pâques

### Identité chromatique du thème

**Couleur phare obligatoire : Easter Orchid Pink — `#D987B5`.**

Palette verrouillée : #D987B5, #8DCC86, #F4D76E, #F8F5EA, #78BFE0.

The hero orchid pink anchors the egg artwork, blossoms and selected decorative details. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished Easter illustration, landscape 16:9. Create a lively spring garden scene with one beautifully patterned Easter egg as the focal point, surrounded by fresh flowers, small pastel eggs, soft grass, a charming stylized chick and light spring branches. Use rich but elegant illustration, layered depth and clear shapes. Palette: fresh mint green, dusty pink, pale yellow, ivory and sky blue. Bright cool daylight, clean air, soft shadows and lively details. Avoid sugary overload and avoid flat minimalism. Exact chromatic anchor: use **Easter Orchid Pink `#D987B5`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #8DCC86, #F4D76E, #F8F5EA, #78BFE0, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished Easter illustration, portrait 4:5. Make a large decorated egg the central subject, surrounded by layered spring flowers, small eggs, fresh grass, a stylized chick and delicate branches. Use crisp fluid illustration, subtle painterly texture and rich environmental detail. Palette: mint green, pink, pale yellow, ivory and clear blue. Bright cool daylight, fresh spring air and soft shadows. Keep the upper region less dense for UI. Exact chromatic anchor: use **Easter Orchid Pink `#D987B5`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #8DCC86, #F4D76E, #F8F5EA, #78BFE0, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 3.3 Nouvel An

### Identité chromatique du thème

**Couleur phare obligatoire : Midnight Electric Violet — `#704CFF`.**

Palette verrouillée : #704CFF, #D5C8FF, #F4F1FF, #D8C75E, #2C3C73.

The hero violet anchors the night sky, major fireworks and luminous graphic forms. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished New Year celebration illustration, landscape 16:9. Create an elegant night city scene with a brilliant Art Deco-inspired fireworks display as the main focal point, layered above a refined skyline and reflective water. Use geometric fireworks shapes, tiny starbursts, streamers and subtle city lights. If numbers are used, do not render readable typography; represent the new year through celebratory visual symbols only. Palette: deep indigo, electric violet, crisp white, luminous gold and a restrained cyan accent. Keep the night fresh and clear rather than black and heavy. Fireworks should be detailed, layered and visually sophisticated, with no excessive glow. Exact chromatic anchor: use **Midnight Electric Violet `#704CFF`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #D5C8FF, #F4F1FF, #D8C75E, #2C3C73, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished New Year illustration, portrait 4:5. Build a vertical night-city scene where layered geometric fireworks bloom above an elegant skyline and reflective water. Add smaller bursts, tiny stars, streamers and subtle architecture. Palette: deep indigo, violet, white, gold and restrained cyan. Keep fireworks crisp and luminous with controlled glow. The sky should feel deep but not muddy or black. Exact chromatic anchor: use **Midnight Electric Violet `#704CFF`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #D5C8FF, #F4F1FF, #D8C75E, #2C3C73, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 3.4 Fête

### Identité chromatique du thème

**Couleur phare obligatoire : Festival Fuchsia — `#F23DAA`.**

Palette verrouillée : #F23DAA, #20C9E8, #FFCC45, #6D4DFF, #F7F4EF.

The hero fuchsia drives ribbons, confetti clusters and the largest celebratory accents. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished contemporary celebration illustration, landscape 16:9. Create a joyful dynamic scene filled with flowing ribbons, elegant confetti, colorful paper shapes, balloons and abstract celebratory movement. Build an intentional composition with a strong central flow rather than random objects. Palette: vivid magenta, electric violet, cyan, fresh yellow and white. Use crisp clean illustrated forms, subtle paper texture and layered depth. Colors should be lively but balanced, not neon-heavy. Bright clean lighting and a cool fresh atmosphere. Exact chromatic anchor: use **Festival Fuchsia `#F23DAA`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #20C9E8, #FFCC45, #6D4DFF, #F7F4EF, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished contemporary celebration illustration, portrait 4:5. Create a rich vertical stream of confetti, ribbons, balloons and paper shapes flowing around an open central area. Use crisp fluid forms, elegant layering and subtle paper textures. Palette: magenta, violet, cyan, yellow and white. Bright cool illumination, clean shadows and high visual energy without visual clutter. Exact chromatic anchor: use **Festival Fuchsia `#F23DAA`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #20C9E8, #FFCC45, #6D4DFF, #F7F4EF, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 3.5 Paix

### Identité chromatique du thème

**Couleur phare obligatoire : Peace Sage — `#78B29A`.**

Palette verrouillée : #78B29A, #E8EEE7, #D8DDE1, #FFFFFF, #78A8C8.

The hero sage green anchors foliage, subtle architectural forms and the main calm color fields. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished illustration representing peace, landscape 16:9. Build a serene but visually rich garden scene with a white dove as the main focal point, surrounded by olive branches, soft pale flowers, distant peaceful hills, a clean sky and subtle flowing fabric or paper textures. Use elegant contemporary Japanese-inspired calm composition without making the image empty. Palette: sage green, pearl gray, ivory, soft sky blue and a restrained pale lavender accent. Bright cool daylight, gentle breeze and luminous atmosphere. The scene should feel clean, hopeful and alive. Exact chromatic anchor: use **Peace Sage `#78B29A`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #E8EEE7, #D8DDE1, #FFFFFF, #78A8C8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished peace-themed illustration, portrait 4:5. Make a graceful white dove the central subject, surrounded by layered olive branches, small pale flowers and distant soft hills. Add subtle feather detail and atmospheric depth. Palette: sage green, pearl gray, ivory, sky blue and pale lavender. Bright cool diffuse light and a calm fresh atmosphere. Rich but restrained, leaving a quiet upper background for UI. Exact chromatic anchor: use **Peace Sage `#78B29A`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #E8EEE7, #D8DDE1, #FFFFFF, #78A8C8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

---

# 4. Art & Culture
## 4.1 Impressionnisme

### Identité chromatique du thème

**Couleur phare obligatoire : Impressionist Mint Teal — `#62B59F`.**

Palette verrouillée : #62B59F, #5B9AD6, #C894D8, #F2A8B7, #F8F2E8.

Water, foliage and dominant brushwork use the mint-teal hero color as the visual thread. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished impressionist-inspired digital illustration, landscape 16:9. Create a complete luminous countryside garden scene with flowering fields, a reflective pond, trees, a small bridge and a colorful sky. Use visible but refined painterly strokes, layered color and contemporary digital clarity rather than a direct reproduction of any existing painting. Palette: clear sky blue, fresh green, lavender, soft pink and ivory. Bright cool daylight, lively vegetation and shimmering reflections. Rich detail, vibrant color and elegant composition. Exact chromatic anchor: use **Impressionist Mint Teal `#62B59F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #5B9AD6, #C894D8, #F2A8B7, #F8F2E8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished impressionist-inspired portrait illustration, 4:5. Build a vertical garden landscape with flowering plants in the foreground, a pond and bridge in the middle distance, layered trees and a luminous sky. Use visible painterly brushwork, vibrant color transitions and subtle paper/canvas texture while maintaining clean modern readability. Palette: blue, green, lavender, pink and ivory. Bright cool daylight, fresh air and soft reflected color. Exact chromatic anchor: use **Impressionist Mint Teal `#62B59F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #5B9AD6, #C894D8, #F2A8B7, #F8F2E8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 4.2 Jazz

### Identité chromatique du thème

**Couleur phare obligatoire : Jazz Royal Purple — `#7657D9`.**

Palette verrouillée : #7657D9, #425B92, #C8875B, #F2EEE7, #C85AA5.

Stage light, ambient shapes and selected reflections use the royal-purple hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished contemporary jazz illustration, landscape 16:9. Make a gleaming brass saxophone the main focal point within a sophisticated late-evening music scene. Surround it with abstract stage lights, subtle musical silhouettes, a refined club interior, small tables and layered atmospheric shapes. Use a graphic editorial style with crisp contours, smooth gradients and rich material texture. Palette: deep indigo, smoky blue, copper, ivory and restrained magenta. Keep the scene cool and sophisticated, with copper acting as a controlled accent rather than creating a warm orange cast. Exact chromatic anchor: use **Jazz Royal Purple `#7657D9`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #425B92, #C8875B, #F2EEE7, #C85AA5, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished contemporary jazz illustration, portrait 4:5. Make the saxophone the central vertical subject with detailed brass reflections, surrounded by abstract musical rhythm, subtle stage lights, silhouettes and club architecture. Palette: indigo, smoky blue, copper, ivory and restrained magenta. Bright enough to remain readable while keeping a sophisticated evening atmosphere. Avoid black-heavy emptiness. Exact chromatic anchor: use **Jazz Royal Purple `#7657D9`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #425B92, #C8875B, #F2EEE7, #C85AA5, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 4.3 Street Art

### Identité chromatique du thème

**Couleur phare obligatoire : Urban Magenta — `#E83D7C`.**

Palette verrouillée : #E83D7C, #11BFD2, #F1C62E, #6E4BEA, #D7DEE3.

The hero magenta forms the largest painted color family, balanced by cyan and violet. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished street-art-inspired illustration, landscape 16:9. Create a complete urban wall scene with layered abstract painted forms, expressive spray textures, geometric lettering-like shapes without readable words, colorful paint transitions, concrete details, a few plants and subtle city architecture. Palette: vivid cyan, red, yellow, purple and concrete gray. Keep composition energetic but highly controlled, with strong visual rhythm and clear focal areas. Fresh daylight, crisp color and clean surfaces rather than dirty grunge. Exact chromatic anchor: use **Urban Magenta `#E83D7C`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #11BFD2, #F1C62E, #6E4BEA, #D7DEE3, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished street-art-inspired illustration, portrait 4:5. Create a richly layered painted urban wall with large flowing color shapes, spray texture, geometric forms, concrete cracks, small plants and subtle city details. Palette: cyan, red, yellow, purple and cool gray. Bright fresh daylight, clean saturation and strong depth. No readable text or tags. Exact chromatic anchor: use **Urban Magenta `#E83D7C`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #11BFD2, #F1C62E, #6E4BEA, #D7DEE3, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 4.4 Ballet

### Identité chromatique du thème

**Couleur phare obligatoire : Ballet Lilac — `#B69ADF`.**

Palette verrouillée : #B69ADF, #E8B7D3, #F7F1E8, #AEB8C8, #D5BE78.

Curtains, fabric highlights and selected stage color fields use the lilac hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished contemporary ballet illustration, landscape 16:9. Create an elegant stage-like environment where ballet pointe shoes and the lower silhouette of a dancer form the primary focal point. Surround the subject with flowing fabric, subtle stage curtains, delicate dust particles and soft architectural shapes. Use clean premium illustration with graceful curves, refined textures and layered depth. Palette: ivory, blush pink, cool lavender, soft gray and restrained champagne. Bright cool stage illumination with a clean luminous atmosphere, not yellow and not theatrical darkness. Exact chromatic anchor: use **Ballet Lilac `#B69ADF`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #E8B7D3, #F7F1E8, #AEB8C8, #D5BE78, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished contemporary ballet illustration, portrait 4:5. Make elegant pointe shoes and the lower silhouette of a dancer the main vertical focal point, surrounded by flowing fabric and subtle stage architecture. Add fine satin texture, delicate floor reflections and graceful movement. Palette: ivory, blush pink, lavender, cool gray and restrained champagne. Bright soft cool stage light, clean background and calm depth. Exact chromatic anchor: use **Ballet Lilac `#B69ADF`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #E8B7D3, #F7F1E8, #AEB8C8, #D5BE78, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 4.5 Sculpture

### Identité chromatique du thème

**Couleur phare obligatoire : Gallery Mineral Blue — `#4E8BCE`.**

Palette verrouillée : #4E8BCE, #F3F0E7, #B5BDC7, #DDEBFA, #2F5DA8.

Window light, secondary surfaces and selected exhibition accents use the mineral-blue hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished contemporary sculpture illustration, landscape 16:9. Create a complete modern museum-like scene centered on a large abstract marble sculpture with elegant curves and subtle asymmetry. Surround it with a refined architectural interior, polished floor reflections, secondary sculptural forms and natural light entering through tall windows. Use crisp contemporary illustration with realistic marble texture but clearly illustrative styling. Palette: ivory, cool gray, pale blue and one restrained cobalt accent. Bright cool daylight, clean geometry and soft shadows. Exact chromatic anchor: use **Gallery Mineral Blue `#4E8BCE`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F3F0E7, #B5BDC7, #DDEBFA, #2F5DA8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished contemporary sculpture illustration, portrait 4:5. Make a sophisticated abstract marble sculpture the central vertical focal point inside a modern museum space. Add polished flooring, soft window light, subtle secondary forms and fine stone texture. Palette: ivory, cool gray, pale blue and restrained cobalt. Bright cool daylight, fresh architecture and refined depth. Exact chromatic anchor: use **Gallery Mineral Blue `#4E8BCE`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F3F0E7, #B5BDC7, #DDEBFA, #2F5DA8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

---

# 5. Nature & Ingénierie
## 5.1 Volcans

### Identité chromatique du thème

**Couleur phare obligatoire : Lava Crimson — `#D9473F`.**

Palette verrouillée : #D9473F, #FF764A, #25384A, #8E9BA8, #F4EEE3.

Lava channels and selected volcanic highlights use the crimson hero color, while most of the environment stays cool. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished volcanic landscape illustration, landscape 16:9. Create a dramatic but visually clean volcanic scene with a large stratovolcano in the distance, a glowing lava river, dark basalt rocks, smoke plumes and a cool sky filled with layered clouds. Keep the lava vibrant and controlled rather than making the whole image orange. Add sparse vegetation at the edge of the volcanic terrain for contrast. Palette: basalt charcoal, deep blue-gray, vivid red-orange lava and ivory cloud highlights. Use cool surrounding light and a fresh atmospheric sky. Exact chromatic anchor: use **Lava Crimson `#D9473F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #FF764A, #25384A, #8E9BA8, #F4EEE3, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished volcanic landscape illustration, portrait 4:5. Make the volcanic mountain and winding lava flow the central vertical composition. Add basalt textures, smoke layers, sparse vegetation and distant ridges. Keep the surrounding environment cool blue-gray so the lava becomes a precise controlled accent rather than a hot overall color cast. Exact chromatic anchor: use **Lava Crimson `#D9473F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #FF764A, #25384A, #8E9BA8, #F4EEE3, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 5.2 Glacier

### Identité chromatique du thème

**Couleur phare obligatoire : Arctic Cyan — `#2CB9D4`.**

Palette verrouillée : #2CB9D4, #286CC4, #F9FDFF, #B7C4D8, #9C8ED8.

Crevasses, ice glow and meltwater carry the arctic-cyan hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished glacier landscape illustration, landscape 16:9. Create a spectacular clear blue glacial valley with a giant glacier face, deep turquoise crevasses, snow-covered peaks, reflective meltwater and distant clouds. Add detailed ice fractures and subtle translucent blue layers. Palette: glacier cyan, deep cobalt, white, pale lavender and cool gray. Bright cold daylight, luminous snow and crystal-clear air. The image should feel vibrant and alive rather than monochrome. Exact chromatic anchor: use **Arctic Cyan `#2CB9D4`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #286CC4, #F9FDFF, #B7C4D8, #9C8ED8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished glacier landscape illustration, portrait 4:5. Build an immersive vertical glacier valley with detailed blue ice walls, deep crevasses, snow peaks, a meltwater stream and soft clouds. Use multiple translucent ice layers, crisp fractures and reflective surfaces. Palette: cyan, cobalt, white, pale lavender and cool gray. Bright cold light and crystal-clear atmosphere. Exact chromatic anchor: use **Arctic Cyan `#2CB9D4`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #286CC4, #F9FDFF, #B7C4D8, #9C8ED8, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 5.3 Dunes

### Identité chromatique du thème

**Couleur phare obligatoire : Cool Sand Gold — `#C9A76B`.**

Palette verrouillée : #C9A76B, #F0E4CC, #8AB7D6, #C87964, #5F7D86.

The dune ridges and sand planes carry the cool sand-gold hero color, balanced by cool sky blue. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished desert dunes illustration, landscape 16:9. Create a sweeping landscape of elegant sculpted dunes with layered curves, a distant caravan silhouette, sparse vegetation and a cool luminous sky. The sand must feel rich and dimensional without becoming orange or brown-heavy. Use palette of pale sand, ivory, muted coral, cool blue and restrained gold. Bright clean daylight, subtle wind lines and soft shadows. Add distant atmospheric hills to increase depth. Exact chromatic anchor: use **Cool Sand Gold `#C9A76B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F0E4CC, #8AB7D6, #C87964, #5F7D86, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished desert dunes illustration, portrait 4:5. Make sculpted dune curves the main visual language, with a small distant caravan and sparse plants adding scale. Add fine wind patterns, subtle sand texture and atmospheric layers. Palette: pale sand, ivory, muted coral, cool blue and restrained gold. Bright neutral daylight, no hot orange haze. Exact chromatic anchor: use **Cool Sand Gold `#C9A76B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #F0E4CC, #8AB7D6, #C87964, #5F7D86, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 5.4 Jungle

### Identité chromatique du thème

**Couleur phare obligatoire : Jungle Emerald — `#22B36F`.**

Palette verrouillée : #22B36F, #0F7C59, #8FD85C, #54B9C7, #F2E7BF.

Large foliage masses and main botanical structures carry the jungle-emerald hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished tropical jungle illustration, landscape 16:9. Create a richly layered rainforest scene with broad leaves, palms, vines, a clear stream, small exotic birds and mist between distant trees. Use vivid but controlled greens with cyan sky openings, yellow-green highlights and ivory mist. Build many layers of vegetation while keeping a clear path for the eye. Fresh diffused daylight filtering through foliage, no dark muddy green. Exact chromatic anchor: use **Jungle Emerald `#22B36F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #0F7C59, #8FD85C, #54B9C7, #F2E7BF, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished tropical jungle illustration, portrait 4:5. Build a dense but readable vertical rainforest with large leaves in the foreground, palms, vines, a flowing stream, birds, distant trees and soft mist. Use multiple green tones, cyan openings and yellow-green highlights. Keep the scene luminous and fresh rather than dark. Add precise leaf textures and water reflections. Exact chromatic anchor: use **Jungle Emerald `#22B36F`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #0F7C59, #8FD85C, #54B9C7, #F2E7BF, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 5.5 Ponts

### Identité chromatique du thème

**Couleur phare obligatoire : Bridge Signal Red — `#D8444B`.**

Palette verrouillée : #D8444B, #3C78B8, #1BA6A6, #F3EEE4, #6B8F63.

The main bridge structure and selected engineering details use the signal-red hero color. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished engineering-and-city illustration of the Golden Gate Bridge, landscape 16:9. Make the bridge the dominant graphic subject, spanning the frame with elegant cable geometry. Surround it with San Francisco hills, clean blue water, distant city details, a few boats and soft coastal clouds. Use a crisp contemporary illustrated style with precise engineering lines, fluid shapes, layered depth and refined texture. Palette: vivid bridge red, cool blue, teal, ivory and muted green. Bright cool daylight, fresh coastal atmosphere and clean reflections. No sunset orange cast. Exact chromatic anchor: use **Bridge Signal Red `#D8444B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #3C78B8, #1BA6A6, #F3EEE4, #6B8F63, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished Golden Gate Bridge illustration, portrait 4:5. Compose the bridge vertically with strong cable lines drawing the eye toward the distance. Add blue water, coastal hills, small boats, distant city details and clouds. Use precise engineering geometry, layered depth and clean illustrated textures. Palette: vivid bridge red, cool blue, teal, ivory and muted green. Bright cool daylight and fresh coastal air. Exact chromatic anchor: use **Bridge Signal Red `#D8444B`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #3C78B8, #1BA6A6, #F3EEE4, #6B8F63, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.
## 5.6 Afrique

### Identité chromatique du thème

**Couleur phare obligatoire : Contemporary Terracotta — `#C96F4A`.**

Palette verrouillée : #C96F4A, #2D946B, #3C9CC7, #F3E2C5, #D6A33A.

Textile-inspired geometry, selected architecture and earth surfaces use the terracotta hero color, balanced by cool blue and green. Elle doit rester clairement perceptible dans la couverture paysage comme dans l'image portrait, sans être remplacée par une teinte générique.


### Cover — 16:9

> Premium polished contemporary African illustration, landscape 16:9. Create a rich celebratory African landscape combining elegant geometric textile-inspired patterns, earth-tone architecture, tropical vegetation and a majestic elephant in the middle distance. The elephant is recognizable and dignified, not cartoonish. Use patterned fabrics inspired by African visual traditions without copying a specific copyrighted design. Build a complete scene with savanna grasses, distant trees, textured earth, a clear sky and subtle human silhouettes in the far background for scale. Palette: vivid terracotta, ochre, deep green, clear blue and cream, balanced with fresh cool highlights so the image does not become overly warm. Use sophisticated contemporary illustration with crisp shapes, rich decorative details, layered depth and premium finish. The result should feel unmistakably African, modern, vibrant and elegant. Exact chromatic anchor: use **Contemporary Terracotta `#C96F4A`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #2D946B, #3C9CC7, #F3E2C5, #D6A33A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

### Application — 4:5

> Premium polished contemporary African illustration, portrait 4:5. Make a dignified elephant the main focal point within a richly layered savanna scene. Surround it with stylized African-patterned textiles, tall grasses, acacia-like trees, subtle earth architecture and distant human silhouettes for scale. Use sophisticated contemporary illustration with crisp forms, fluid patterns, detailed vegetation, layered atmospheric depth and refined texture. Palette: terracotta, ochre, deep green, clear blue and cream, balanced with cool highlights to avoid an overly hot orange image. Bright clean daylight, soft shadows and lively color. Preserve a calmer upper sky for UI while maintaining a rich environment. Exact chromatic anchor: use **Contemporary Terracotta `#C96F4A`** as the dominant hero color, visibly repeated across major visual surfaces; support it with #2D946B, #3C9CC7, #F3E2C5, #D6A33A, while keeping the image bright, clear and cool rather than warm. Premium 4K-quality.

---

## CONTRAT DE GÉNÉRATION — COULEUR PHARE

Pour chaque thème, l'agent doit traiter la couleur phare comme une **contrainte de direction artistique**, pas comme une suggestion. Avant génération, il doit vérifier :

1. Le code HEX du thème est présent dans le prompt paysage.
2. Le même code HEX est présent dans le prompt portrait.
3. Le code HEX est décrit comme la couleur dominante ou l'ancre chromatique, pas comme un simple accent.
4. La palette de support ne dilue pas l'identité du thème.
5. L'image reste fraîche, claire et vivante, même lorsque la couleur phare est chaude.
6. Aucune autre couleur ne doit prendre visuellement le dessus au point de faire perdre l'identité du thème.

### Test visuel final

À basse taille, si l'on voit la couverture pendant moins d'une seconde, la couleur phare doit déjà contribuer à identifier le thème. La couverture et le portrait doivent être immédiatement reconnaissables comme appartenant au **même thème**, mais pas être des recadrages identiques.
