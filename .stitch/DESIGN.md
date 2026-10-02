# Design System: Aurora

## 1. Visual Theme & Atmosphere

« Technical Calm » — un outil de travail dense mais silencieux, conçu pour des
sessions longues. **Deux types de fond, strictement neutres, aucune teinte ni
gradient de canvas :**
- **Fond clair** : blanc uni `#FFFFFF`.
- **Fond dark** : `#121212`, noir simple (pas de teinte bleue, pas d'OLED
  near-black).

Le canvas est le seul élément toujours neutre — un thème expressif colore les
accents et les surfaces de cartes/panneaux, **jamais le fond de l'application**.
Le fond reste soit `#FFFFFF` (clair) soit `#121212` (dark), lisible au-dessus
des surfaces empilées. La densité est celle d'une console technique : tableaux
(AG Grid), calendriers, graphiques (AntV/G2), arbres sémantiques.

## 2. Color Palette & Roles

### Primary Foundation (style neutre, tokens figés — 05 §2.1.2/§2.1.3, G-H2 re-2026-10)
- **Plain White Canvas (`#FFFFFF`)** : fond principal en mode clair, aucun autre
  blanc « cassé » ni slate.
- **Pure Dark Canvas (`#121212`)** : fond principal en mode dark, noir simple.
- **White Surface (`#FFFFFF`)** : cartes et panneaux en clair, sur le fond
  blanc (démarqués par bordure 1px + ombre légère, pas par le contraste de
  canvas).
- **Night Surface (`#1E2026`)** : cartes et panneaux en dark, légèrement au-
  dessus du `#121212`.
- **Night Surface Alt (`#25282F`)** : surfaces empilées en dark.

### Expressive Themes (liste de 10 thèmes — 05 §5.4, `packages/ui/src/themes/*.json`)
Chaque thème applique **ses 4 couleurs d'accent** sur les composants, sans
teinter le canvas :
- **Aurora** (défaut) : `#3678F6` / `#22C7D6` / `#7B61FF` / `#B8DFFF` — ciel à
  l'aube.
- **Lagoon** : bleu-lagon. **Boreal** : nordique. **Sakura** : cerisier
  (`#D85B86`…). **Vesper** : crépuscule. **Solara** : solaire. **Terra** :
  terreuse. **Verdant** : végétal. **Citrus** : agrumes. **Cosmos** : nébuleuse
  (`#3B3FA7` / `#18BFD4` / `#E95BAA`).
- Règle bloquante 05 §5.1 : un thème ne redéfinit **jamais** les états
  sémantiques (success/warning/danger/info) — ceux-ci restent neutres.

### Image Themes (liste de 26 thèmes visuels — appliqués sur demande utilisateur)
En plus des 10 thèmes couleur, l'application propose **26 thèmes
d'illustration** (26 portraits + 26 paysages = 52 images prévues). Batch
2026-10-B : **19 thèmes téléversés, tous complets P+L (38 fichiers)** —
les 7 restants (printemps, ete, automne, hiver, volcans, glacier, dunes)
sont en attente de génération ; voir `.stitch/theme_index.json` pour
l'état définitif à jour. Sur demande utilisateur,
un thème image s'applique en **image de fond de l'application**, et sa
**couleur principale (le « chromatic anchor » de l'image) est accentuée** dans
le design system : le canvas reste l'image elle-même (ni teinte, ni flouté),
et les accents/primary suivent la teinte dominante de l'image (ex. thème « jazz
» → violet royal `#7657D9` accentué).
Convention de nommage des fichiers (`.stitch/images/`) :
`<slug_theme>_<portrait|paysage>.png`, ex. `jazz_portrait.png`,
`new_york_paysage.png`. 26 slugs : new_york, tokyo, paris, londres, dubai,
sydney, printemps, ete, automne, hiver, noel, paques, nouvel_an, fete, paix,
impressionnisme, jazz, street_art, ballet, sculpture, volcans, glacier,
dunes, jungle, ponts, afrique.

### Accent & Interactive (thème par défaut « aurora »)
- **Electric Blue (`#3678F6`)** : actions principales, icônes, ring de focus.
- **Dawn Cyan (`#22C7D6`)** : second interactif, accents graphiques.
- **Aurora Violet (`#7B61FF`)** : accent ponctuel (1 dominante + 1 secondaire
  + 1 accent max — règle 05 §5.4.2).
- **Selection (`#B8DFFF` fill + `#3678F6` border)** : état sélectionné.
- **Focus ring** : 2px `#3678F6`, offset 2px.

### Typography & Text Hierarchy
- **Ink (`#0F172A`)** : texte principal sur fond clair.
- **Slate (`#334155`)** : texte secondaire.
- **Mist (`#94A3B8`)** : étiquettes atténuées, métadonnées ; en dark passe à
  `#64748B`.
- **Disabled (`#CBD5E1` clair / `#475569` dark)** : texte grisé.

### Functional States
- **Success (`#10B981`)** / **Warning (`#F59E0B`)** / **Danger (`#EF4444`)** /
  **Info (`#0EA5E9`)** — figés, jamais redéfinis par un thème (règle bloquante
  05 §5.1). Surfaces associées claires : `#E8FAF0`, `#FFF4E0`, `#FEECEC`.
- État des nœuds sémantiques : **Mastered** (vert), **Fragile** (ambre),
  **Forgotten** (rouge).

## 3. Typography Rules

- **Inter** : titres et corps. Base `16px`, `line-height 1.45`, anti-aliasing
  activé. Titres card en `font-semibold`, `tracking-tight` ; labels en
  `text-sm font-medium`.
- **JetBrains Mono** : toutes les valeurs numériques (`tabular-nums`), code,
  unités et timestamps — ex. StatTile : label `text-xs uppercase tracking-wide
  mono`, valeur `text-2xl font-bold tabular-nums`.
- Hiérarchie : display `text-2xl` (32px) pour les KPI ; `h2`-equivalent
  `text-lg font-semibold` ; corps `text-sm` (14px) pour la densité des
  tableaux et listes.

## 4. Component Stylings

- **Buttons** : shadcn/Radix + CVA. Variantes `default` (fond primaire +
  ombre), `secondary`, `outline` (bordure 1px), `ghost`, `link`. Hauteurs
  standard : sm 32px, default 36px, lg 40px ; radius `rounded-md` (6px).
  Focus = ring 1px, jamais d'outline solide.
- **Cards** : `rounded-xl` (12px), bordure 1px, fond `bg-card`, ombre légère ;
  padding 24px sur les zones header/content. Sur canvas clair `#FFFFFF`, une
  carte se démarque par sa bordure 1px + son ombre, pas par un changement de
  canvas.
- **StatTile** : tuile KPI `rounded-md` 1px bordure, padding 16px, label mono
  en majuscules atténué + valeur bold tabulaire ; états `loading` (skeleton
  pulsé) et `empty` (« — » atténué).
- **Inputs & Forms** : fond neutre, bordure 1px `border`, focus ring 1px en
  primaire ; labels au-dessus du champ ; validation inline.
- **Grilles & Data** : AG Grid et DataTables denses ; squelettes en
  `#F1F5F9` (clair) / `#25282F` (dark).
- **Motion** : fluide et léger — 150–250ms, `ease-out` ; reduced-motion →
  transitions instantanées ; Focus Mode → animations squelettes atténuées.

## 5. Layout Principles

- **Grille & espacement** : base 4px/8px, marges 16px mobile / 24–32px desktop,
  gutters 16px, padding de carte 24px.
- **Cibles tactiles** : minimum 40px sur mobile (boutons `h-9`/`h-10`).
- **Responsive** : panneaux multi-colonnes desktop → pile unique mobile avec
  barre d'action flottante en bas.
- **Sidebar** : fond neutre (clair `#FFFFFF` / dark `#121212`), bordure 1px,
  accents en thème courant (bleu électrique par défaut).

## 6. Design System Notes for Stitch Generation

- **Atmosphere keywords** : technical calm, console de travail dense, **canvas
  strictement neutre (blanc `#FFFFFF` ou `#121212`, aucune teinte ni
  gradient)**, accents colorés par thème.
- **Couleurs canoniques** : canvas `#FFFFFF` (clair) / `#121212` (dark),
  surfaces `#FFFFFF` / `#1E2026`, primaire (défaut aurora) `#3678F6`,
  secondaire `#22C7D6`, accent `#7B61FF`, encre `#0F172A`, texte secondaire
  `#334155`, danger `#EF4444`, success `#10B981`, warning `#F59E0B`.
- **Liste de 10 thèmes couleur** : aurora, lagoon, boreal, sakura, vesper,
  solara, terra, verdant, citrus, cosmos — chacun déplace uniquement les
  accents (jamais le canvas, jamais les états sémantiques).
- **Liste de 26 thèmes image** (`.stitch/images/<slug>_<portrait|paysage>.png`
  — batch 2026-10-B : 19 thèmes complets P+L / 38 fichiers, 7 en attente de
  génération) : appliqués sur demande utilisateur comme **image de fond**
  de l'application, avec **accentuation de la couleur principale de l'image**
  dans les composants (le `chromatic anchor` de chaque thème, cf.
  `.stitch/prompts_v4.md` — table des couleurs phares, 26 thèmes).
- **Prompts composants** : boutons de 36px, radius 6px, fond en couleur
  primaire du thème courant avec ombre discrète ; cartes radius 12px, bordure
  1px, ombre légère, padding 24px ; tuiles KPI avec label mono en majuscules
  atténué et valeur bold `tabular-nums` ; panneaux de données denses (tableaux
  AG Grid, graphiques AntV) en palette 4 couleurs du thème courant (bleu/cyan/
  violet par défaut).
