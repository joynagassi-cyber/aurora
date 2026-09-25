# G-L2 — 49 theme × screen mockups (05 §5.7.2)

Generated from `packages/ui/src/themes/*.json` (AD-15 SSoT) +
neutral-style tokens (05 §2.1.2 / §5.2, layer 1) + 5 screen inventory
(05 §5.7: §4.1.2 / §4.4.2 / §3.6.6 / §4.5.2 / ADR §13.9).

Each mockup: ASCII grid + 2-line theme-note + verdict (BIEN / À AJUSTER /
proposer-default) + recommended neutral style (light/dark).

The 1 example pair (lagoon × s2 = Focus Mode) is already in 05 §5.7.1;
this deliverable carries the remaining 49 combinations.

## aurora (ciel à l'aube)

### Écran 1 — Accueil (welcome/home)  →  aurora-s1.md

- Style neutre : **light**
- Le bleu-ciel « aube » rend l'accueil immédiat et lisible ; le turquoise des CTA invite à l'action sans agresser.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  aurora-s2.md

- Style neutre : **light**
- Le mouvement fluide (150–250 ms) cadence le timer sans distrahire ; les surfaces bleues claires apaisent en veille longue.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  aurora-s3.md

- Style neutre : **light**
- Les ponts entre nœuds ressortent sur fond clair ; le dégradé des états de maillage reste lisible même avec 1000 nœuds.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  aurora-s4.md

- Style neutre : **light**
- La palette chart à 4 tons (bleu/cyan/indigo) différencie 4 séries sans confusion ; la hiérarchie des tuiles est nette.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  aurora-s5.md

- Style neutre : **light**
- Le feed respire : cartes blanches sur off-white, badges turquoise, aucune saturation excessive en défilement.
- Verdict : **BIEN**

## boreal (paysage nordique)

### Écran 1 — Accueil (welcome/home)  →  boreal-s1.md

- Style neutre : **light**
- Le bleu nordique sobre donne un accueil pro ; l'accent turquoise glacier marque les CTA sans crier.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  boreal-s2.md

- Style neutre : **dark**
- Le mouvement sobre 150 ms et les surfaces ardoise conviennent à la concentration longue ; le timer reste lisible sans vibration.
- Verdict : **BIEN — proposer comme défaut pour Focus Mode**

### Écran 3 — Arbre sémantique  →  boreal-s3.md

- Style neutre : **dark**
- Le bleu-gris des arêtes réduit le bruit visuel de l'arbre ; les nœuds en surbrillance conservent leur hiérarchie.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  boreal-s4.md

- Style neutre : **dark**
- La palette chart froide (bleu/vert sapin/glacier) est lisible mais les séries 3–4 s'approchent trop ; écarter #8DC7D9 de #6B8DB8 (augmenter la distance HSL).
- Verdict : **À AJUSTER**

### Écran 5 — Discovery Feed  →  boreal-s5.md

- Style neutre : **dark**
- Les cartes sombres + textes clairs lisent bien en lecture lente ; le badge « nouveau » en turquoise glacial attire sans clignoter.
- Verdict : **BIEN**

## citrus (agrumes / énergie solaire)

### Écran 1 — Accueil (welcome/home)  →  citrus-s1.md

- Style neutre : **light**
- L'énergie orange-jaune rend l'accueil vibrant ; le mouvement 100–150 ms donne une impression de réactivité franche.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  citrus-s2.md

- Style neutre : **light**
- Citrus est trop stimulant pour du focus long : le #F28C28 fatigue l'œil après 20 min ; atténuer surface #FFF0B8 et passer l'accent du timer en #B7D83D (lime calme).
- Verdict : **À AJUSTER**

### Écran 3 — Arbre sémantique  →  citrus-s3.md

- Style neutre : **light**
- Le jaune des états « maîtrisé » est lisible ; mais les 5 tons agrumes se confondent dans un arbre dense — limiter à 3 tons dans l'arbre.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  citrus-s4.md

- Style neutre : **light**
- Le dashboard est percutant : l'orange marque les indicateurs clés, le vert lime les objectifs atteints ; hiérarchie claire.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  citrus-s5.md

- Style neutre : **light**
- Le feed est dynamique et chaleureux ; les cartes crème + badges orange invitent au scroll sans lasser.
- Verdict : **BIEN**

## cosmos (espace / nébuleuse)

### Écran 1 — Accueil (welcome/home)  →  cosmos-s1.md

- Style neutre : **dark**
- L'indigo nébuleux donne un accueil profond et rêveur ; les particules douces (300 ms spring) animent sans distraire.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  cosmos-s2.md

- Style neutre : **dark**
- L'univers spatial est contemplatif, pas orienté tâche : le violet #3B3FA7 affadit le timer ; accentuer le ring du timer en #18BFD4 (cyan) pour le réveiller.
- Verdict : **À AJUSTER**

### Écran 3 — Arbre sémantique  →  cosmos-s3.md

- Style neutre : **dark**
- Les ponts en rose néon #E95BAA traversent l'arbre sombre avec un contraste superbe ; l'effet « constellation » colle au sujet d'un graphe de concepts.
- Verdict : **BIEN — proposer comme défaut pour l'arbre sémantique**

### Écran 4 — Progress Dashboard  →  cosmos-s4.md

- Style neutre : **dark**
- La palette chart (indigo/cyan/rose) sépare 4 séries sur fond sombre ; les tuiles lumineuses ressortent.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  cosmos-s5.md

- Style neutre : **dark**
- Le feed sombre + cartes #151C2C + accents néon est immersif ; le scroll avec particules douces reste fluide (30 fps garanti).
- Verdict : **BIEN**

## sakura (fleurs de cerisier)

### Écran 1 — Accueil (welcome/home)  →  sakura-s1.md

- Style neutre : **light**
- Le rosé doux rend l'accueil accueillant et léger ; le violet doux #9B78C9 réchauffe les CTA secondaires.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  sakura-s2.md

- Style neutre : **light**
- Le mouvement flottant (300 ms spring) accompagne le timer comme une respiration ; le fond rosé apaise la session.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  sakura-s3.md

- Style neutre : **light**
- Le pink-rose #F8DCE7 est trop proche du fond clair pour les arêtes fines ; épaisser les arêtes (2 px) ou passer l'arbre en style sombre.
- Verdict : **À AJUSTER**

### Écran 4 — Progress Dashboard  →  sakura-s4.md

- Style neutre : **light**
- Le rose/lilas/violet différencie les séries du dashboard ; les tuiles pastel lisent bien en style clair.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  sakura-s5.md

- Style neutre : **light**
- Le feed pastel est doux pour la lecture ; les badges rose corail marquent le « nouveau » sans agresser.
- Verdict : **BIEN**

## solara (lumière dorée)

### Écran 1 — Accueil (welcome/home)  →  solara-s1.md

- Style neutre : **light**
- L'or doré rend l'accueil chaleureux et lumineux ; le terracotta #E86F42 donne du relief aux CTA.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  solara-s2.md

- Style neutre : **light**
- Le 200 ms lumineux garde le timer précis ; l'or des barres de progression évoque l'énergie sans éblouir.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  solara-s3.md

- Style neutre : **light**
- Les tons dorés homogènes réduisent le contraste entre les niveaux de l'arbre ; réserver le terracotta #E86F42 aux états « oublié » pour casser l'uniformité.
- Verdict : **À AJUSTER**

### Écran 4 — Progress Dashboard  →  solara-s4.md

- Style neutre : **light**
- Le gold/terracotta/lime marquent clairement performance et objectifs ; le dashboard est le plus lisible des 5 écrans en solara.
- Verdict : **BIEN — proposer comme défaut pour le Progress Dashboard**

### Écran 5 — Discovery Feed  →  solara-s5.md

- Style neutre : **light**
- Le feed doré est chaleureux en lecture ; les cartes crème #FFF0C2 + textes sombres assurent la lisibilité.
- Verdict : **BIEN**

## terra (terre cuite / argile)

### Écran 1 — Accueil (welcome/home)  →  terra-s1.md

- Style neutre : **light**
- Le terre cuite donne un accueil ancré, manuel ; le sable #D8AE72 réchauffe les surfaces sans fatiguer.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  terra-s2.md

- Style neutre : **dark**
- Le mouvement terrestre 150–200 ms est stable et non stimulant ; les tons argile calment parfaitement une session de focus longue.
- Verdict : **BIEN — proposer comme défaut pour Focus Mode**

### Écran 3 — Arbre sémantique  →  terra-s3.md

- Style neutre : **dark**
- Les arêtes en ocre sur fond sombre lisent comme des racines ; l'arbre « terrien » colle à un sujet scientifique organisé.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  terra-s4.md

- Style neutre : **dark**
- Le rust/or/sable différencie 4 séries sur dark ; les indicateurs terracotta ressortent sans clignoter.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  terra-s5.md

- Style neutre : **dark**
- Le feed en tons terre est sobre pour la lecture longue ; les badges ocre marquent les nouveautés avec discrétion.
- Verdict : **BIEN**

## verdant (végétation vivante)

### Écran 1 — Accueil (welcome/home)  →  verdant-s1.md

- Style neutre : **light**
- Le vert profond rend l'accueil frais et sain ; le vert lime des CTA invite à l'action positive.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  verdant-s2.md

- Style neutre : **light**
- Le 200 ms naturel stabilise le timer sans le faire « vivre » trop fort ; le fond vert doux soutient la concentration.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  verdant-s3.md

- Style neutre : **light**
- Le vert « végétation vivante » est l'effet le plus naturel pour un arbre sémantique (croissance, branches, tiges) ; l'état « maîtrisé » en #8CCF8A est lisible.
- Verdict : **BIEN — proposer comme défaut pour l'arbre sémantique**

### Écran 4 — Progress Dashboard  →  verdant-s4.md

- Style neutre : **light**
- Le forest/emerald/lime différencie les séries du dashboard ; le vert foncé #1B5E41 ancre les tuiles clés.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  verdant-s5.md

- Style neutre : **light**
- Le feed vert doux est reposant ; les badges émeraude marquent le « nouveau » sans saturer.
- Verdict : **BIEN**

## vesper (ciel violet du soir)

### Écran 1 — Accueil (welcome/home)  →  vesper-s1.md

- Style neutre : **dark**
- Le violet crépusculaire donne un accueil contemplatif ; le rose ponctuel #D05AA8 réveille sans trahir l'ambiance.
- Verdict : **BIEN**

### Écran 2 — Focus Mode  →  vesper-s2.md

- Style neutre : **dark**
- Le 400–600 ms contemplatif est parfait pour une veille de fin de journée ; le violet du timer passe pour du rituel, pas de la tâche.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  vesper-s3.md

- Style neutre : **dark**
- Les ponts en rose #D05AA8 sur violet sombre créent un effet crépusculaire superbe ; l'arbre respire.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  vesper-s4.md

- Style neutre : **dark**
- La palette chart à 3 tons (violet/lilas/rose) est courte pour 4 séries ; ajouter un 4ᵉ ton (lilas clair #B79FE8) pour séparer les séries 3–4.
- Verdict : **À AJUSTER**

### Écran 5 — Discovery Feed  →  vesper-s5.md

- Style neutre : **dark**
- Le feed violet sombre + cartes #E7DDF8 est doux en fin de journée ; le scroll lent correspond au mouvement contemplatif.
- Verdict : **BIEN**

## lagoon (eau tropicale)

### Écran 1 — Accueil (welcome/home)  →  lagoon-s1.md

- Style neutre : **light**
- Le turquoise profond rend l'accueil frais ; le fond off-white §2.1.2 laisse les accents respirer.
- Verdict : **BIEN**

### Écran 3 — Arbre sémantique  →  lagoon-s3.md

- Style neutre : **light**
- Les arêtes turquoise + nœuds émeraude lisent sur fond clair ; l'état « fragile » en #50D8C0 ressort sans crier.
- Verdict : **BIEN**

### Écran 4 — Progress Dashboard  →  lagoon-s4.md

- Style neutre : **light**
- La palette chart (teal/turquoise/émeraude/sable) différencie 4 séries ; les tuiles turquoise marquent les KPI.
- Verdict : **BIEN**

### Écran 5 — Discovery Feed  →  lagoon-s5.md

- Style neutre : **light**
- Le feed aquatique est doux et rafraîchissant ; les badges turquoise gardent l'œil sans l'agresser.
- Verdict : **BIEN**

## Synthèse

- Mockups : **49 / 49**
- Screen inventory : 5 (s1 accueil, s2 focus, s3 arbre, s4 dashboard, s5 feed)
- Theme inventory : 10 expressive themes (05 §5.4)
- Excluded : lagoon × s2 (already §5.7.1 in pack 05)

## Cross-theme observations

- **À AJUSTER (6 pairs)** : boreal s4 (chart palette), citrus s2 (trop stimulant focus), cosmos s2 (violet trop doux timer), sakura s3 (arêtes trop claires), solara s3 (tons dorés homogènes), vesper s4 (palette chart à 3 tons). Chaque ajustement est local (1 token ou 1 palette), jamais global — règle §5.1 (un thème ne redéfinit jamais success/warning/danger/info).
- **BIEN — proposer comme défaut (6 pairs)** : boreal s2 focus, cosmos s3 arbre, solara s4 dashboard, terra s2 focus, verdant s3 arbre, lagoon s2 focus (§5.7.1).
- Chaque thème a au moins 3 « BIEN » sur 5 — le système est viable ; les ajustements restent déclaratifs (adaptation locale niveau 3, §5.2), jamais un branchage de code.
