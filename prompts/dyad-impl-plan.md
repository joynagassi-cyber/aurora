# PROMPT — DYAD · PLAN D'IMPLÉMENTATION FRONTEND UI AMÉLIORÉ
(44/54 écrans SSoT → exécution premium, zéro inférence)

Tu es DYAD (track design, owner Design System team). Mission : produire le
**plan d'implémentation amélioré** du frontend UI d'Aurora — à partir des
specs écrans déjà livrées sur disque (chantier screen-specs TERMINÉ) — puis
l'exécuter par lots gaterisés. Tout élément du plan doit citer sa SSoT
(fichier:§ ou fichier:ligne) : **NE PAS SUPPOSER. NE PAS INVENTER.**

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## 0. État des lieux (vérifié 2026-09-29, `git status` : NON-tracked)

`docs/design-system/screens/` = **51 fichiers .md sur disque, aucune
exécution de code (AD-13 : gate vert par construction)** :
- **44 docs écrans** (14 sections chacun, matrice §4 complète, §12/§13
  partout) : agent-chat · analytics · artifacts-detail ·
  bibliotheque-ressources · calendrier-jour/mois/semaine ·
  cours-detail/liste · discovery-feed/sheet · eisenhower ·
  exercises-proof · fiches-detail/liste · flashcards · focus-mode ·
  goal-feature-detail · habitudes · home · inbox · kanban ·
  knowledge-node/tree · mirror-cognitive · mode-coach · not-found ·
  objectifs-detail/liste · onboarding · progress-dashboard ·
  projets-detail/liste · qcm · retro-actions · revues-jour/mois/semaine ·
  routines · settings · slide-ascent · taches-detail/liste ·
  timeline-gantt (table : `index.md` v2, lignes 1-44).
- **6 transverses** : `_inventory.md` (54 slugs + politique de comptage
  figée 09-27 : unité = SLUG, variantes = slugs distincts, surfaces
  flottantes hors écran) · `_floating-surfaces.md` (BottomSheet/Modal/
  Drawer/FAB/Command/AgentThinkingLoader) · **`_flows.md`**
  (interconnexion : 6 mécanismes de transition, matrice écran→surfaces,
  flux par module, contrats AD-7/9/15/17, machine à états cross-pages,
  sémantique `router.tsx` ↔ slugs §7, 8 OQ §8) · `_open-questions.md`
  (registre SSoT : 374 OQ consolidées, **256 ouvertes**, 118 clôturées) ·
  `INDEX_REVIEW.md` (review adversarial, top 5 OQ bloquantes) ·
  `_report.md` (rapport de fin : 44/44 SPECIFIED, gate OUI, §5 commits,
  §6 docs modules à compléter).
- `index.md` v2 + `_report.md` resynchronisés : plus de « à écrire » /
  « À CRÉER ».

## 1. À lire AVANT de produire le plan (ordre imposé)

1. `docs/design-system/screens/_report.md` §1-§7 (état, OQ-1, top 5,
   gate, 8 commits, 8 docs modules)
2. `docs/design-system/screens/_inventory.md` §1-§3 (comptage 54, 13 OQ
   globales) + `index.md` v2 + `INDEX_REVIEW.md` §1-§3
3. `docs/design-system/screens/_flows.md` (interconnexion + 8 OQ §8) +
   `_floating-surfaces.md`
4. `05-design-system.md` =
   `_bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md`
   (§4 l.1316 « 44 écrans », §9 logos S9 + matrice §9.1 l.378-388,
   §9.2 strip C2PA, **§9.3 AgentThinkingLoader**, **§9.3.1** tous
   thèmes / blanc-par-défaut / accent-only)
5. `docs/ui-libraries.md` (engines figés AD-10, S5 mobile, S6 5 états +
   killed, S8 framework de décision, S9 brand assets) +
   `docs/design-system/overview.md`
6. `docs/mobile/navigation-and-page-composition.md` (17 routes
   primaires) + `apps/mobile/src/router.tsx` (code) +
   `packages/ui/src/components/ui/AgentThinkingLoader.tsx` (implémenté)
7. Ajouts du plan agent (ci-dessous §4) + `prompts/dyad-beta-device-ui.md`
   (le pass précédent : ne PAS le rejouer, le plan s'en rapproche)

## 2. Règles owner (non négociables)

- **Zéro inférence** : chaque widget, micro-animation, modal, formulaire,
  pagination, transition, fluidité = citation SSoT (fichier:§/ligne) ou
  OQ ouverte déclarée. Rien ne doit être deviné par Dyad.
- **Changement de pattern = décision, pas correction** : les
  arbitrages (§5) se tranchent explicitement + owner ratifie à la porte.
- **Non-destructif** : le plan = nouveau fichier
  `docs/design-system/impl-plan.md` (+ mises à jour SSoT uniquement si un
  arbitrage l'exige, ex. 05 §4 pour OQ-1). Aucun code dans cette phase.
- **1 lot = 1 commit = 1 rollback** ; préfixe commits plan :
  `cc/plan:` (les 8 commits docs restent `cc/screens:`).
- **Pas de mockups sans re-approbation owner** (G-L2 REJECTED 09-27,
  coût tokens) : validation owner par **HTML previews** dans
  `docs/design-system/previews/` (pattern existant :
  `agent-thinking-loader.html`).
- **Thème : 13 combos × 2 styles neutres, SANS EXCEPTION**. BLANC par
  défaut (LIGHT) ; le noir (DARK) n'arrive que si l'utilisatrice le
  choisit, jamais de switch silencieux. **ACCENT ONLY** : zéro couleur
  hors tokens ; les thèmes servent l'accentuation sur canvas blanc ou noir.
- **Premium attendu** : « c'est basique » = insuffisant. Motion fluide et
  lisible (150-250 ms, GPU, `prefers-reduced-motion`), interface lissée,
  pas de couleur inutile.
- **Évidence-based** : tout claim cité fichier:ligne ; sinon « non
  vérifié ». **Le push fait partie du livrable** (1 commit poussé = 1
  rollback propre).

## 3. PARTIE 0 — Lancer l'exécution frontend : d'abord les 8 commits

Le chantier docs est **non-tracked** : l'index définitif et le plan ne
reposent que sur des fichiers commités. Les 8 commits `cc/screens:`
(`_report.md` §5 = 7 lots + arbitrage `_gen_oq.py`) :

1. `cc/screens: inventaire réconcilié (54 slugs, politique de comptage) — _inventory.md`
2. `cc/screens: 41 docs écrans 14-sections (lots 2-6) — home/onboarding → taches-liste`
3. `cc/screens: 3 docs écrans restants + relecture — flashcards.md + inbox.md + relecture 3/3`
4. `cc/screens: surfaces flottantes transverses + AgentThinkingLoader — _floating-surfaces.md`
5. `cc/screens: registre consolidé OQ (374 OQ, 256 ouvertes) — _open-questions.md`
6. `cc/screens: index v1 (41 docs) + review adversarial (top 5 OQ) — index.md + INDEX_REVIEW.md`
7. `cc/screens: lot final — focus-mode.md + timeline-gantt.md (§4-§14) + _flows.md (interconnexion) + index.md v2 + _report.md`
8. `cc/screens: _gen_oq.py (commit ou gitignore — choix humain ; vérifié 2026-09-29 : le script n'est PAS à la racine du repo, à localiser/réexporter par l'owner ou le marquer « registre maintenu main »)`

Gate avant chaque commit : vert par construction (AD-13, .md uniquement)
— vérifier `git status` + pnpm gates (typecheck/lint/test).

## 4. AJOUTS du plan agent à intégrer dans le plan UI (NE PAS OUBLIER)

- **doc-tools — 4 capacités agent `docs.*`** (commits `bb8eb1e` +
  `111fa0e`, poussés ; SSoT `docs/agent/document-tools.md`) :
  - Pandoc `docs.generate` (Texte→Doc : rapport/fiche/PPT depuis Markdown
    IA), python-docx `docs.refine` (chirurgical .docx), mammoth
    `docs.inspect` (lecture rapide .docx), Docling `docs.parse`
    (extraction complexe PDF scanné/PPTX/XLSX/images → Markdown/JSON).
  - **Impact UI à planifier** : (a) `agent-chat` — flux « générer un
    document » / « importer + lire un document » (jobs `artifact_gen`,
    états visibles dans `AgentRunState`, loader = `AgentThinkingLoader`
    §9.3 pendant la réflexion lourde) ; (b) `artifacts-detail` —
    nouvelles sorties (docs générés .docx/.pdf/.pptx/.epub,
    représentations parsées md/json) : preview par format + export,
    révision `supersedes` (artifacts §24), `ArtifactGenerated` post-R2
    (F-06) ; (c) `knowledge-node/tree` + `bibliotheque-ressources` —
    représentations parsées = SourceRef (provenance AD-11) ; (d)
    `_flows.md` §4 (bus AD-9) : câbler ces 4 flux dans la machine à
    états cross-pages.
- **AgentThinkingLoader** (§9.3, composant DÉJÀ dans
  `packages/ui/src/components/ui/AgentThinkingLoader.tsx` + preview HTML
  `docs/design-system/previews/agent-thinking-loader.html`) : 3 blobs
  organiques + papillon mono statique + 12 verbes rotatifs + chip
  « Réflexion · Ns » + inhale/float ; §9.3.1 tous-thèmes /
  blanc-par-défaut / accent-only. Le plan doit figer les **règles
  d'usage** (job agent = thinking loader, indeterminate = ring
  indéterminé — cf. OQ récurrentes `_flows.md` §6 : OQ-04 `cours-liste`,
  OQ-02 `agent-chat`) et **trancher OQ-6** (taille : SSoT contradictoire
  64-96px l.454 vs 48px l.483-486 → ratifier UNE valeur).
- **S9 logos monochrome** (09 : 4 fichiers, commit `c4adf43` +
  `56aa2e1`) : header = version **COLOREE** ; contextes dédiés (nouvelle
  session chat, **404**, watermark empty-states 8 %) = version
  **MONOCHROME** (matrice §9.1 l.378-388, strip C2PA §9.2).
  **CONTRADICTION TRANSVERSALE à trancher** (INDEX_REVIEW) : 3 docs
  écrans disent 404 = COLORED, 1 dit MONOCHROME (SSoT §9.1 l.387 vs
  matrice l.378-388) — chaque écran qui code son 404 a besoin d'UNE
  version normative.
- **Contrat thème owner** : « la fille veut du blanc, le noir seulement
  si elle le veut » ; interface fluide + repe + lissée ; pas de couleur
  inutile (accents sur canvas blanc/noir uniquement).

## 5. PARTIE 1 — Arbitrages à trancher AVANT le plan (owner/design)

Le plan s'ouvre par ces tranches (chacune : décision + raisonnement +
impact SSoT + porteur de ratification owner) :

| # | Arbitrage | Pourquoi bloque | Décideur |
|---|-----------|-----------------|----------|
| **OQ-1** | 44 SSoT (05 l.39/1316, daté 09-21) vs 54 candidats inventoriés — options (a) N=46, (b) N=54, (c) 44 + sous-sections variantes | fixe N final, l'index définitif et la liste des écrans à coder ; C'EST LE SEUL blocage du §3 | Design System team (Dyad) — owner ratifie |
| **OQ-16** | Eisenhower `NEEDS_DECISION` (G-L5) | écran non ratifié au catalog → route, 404 local et CTA non implémentables (ratifier ou passer P2) | owner |
| **OQ-48** | not-found / feature-disabled : 404 par écran vs 404 global | tranche le pattern 404 réutilisé par 5+ écrans (kanban, projets-detail, eisenhower, home, not-found OQ-01…04) + libellé FR exact (feature-registry S6) | owner + Design System |
| **OQ-47** | settings : sync CTA blocking vs optimistic + éditabilité 4 champs G-D14 | comportement du CTA `/settings` non figé | owner |
| **OQ-6** | taille `AgentThinkingLoader` : 48px vs 64-96px (SSoT contradictoire) | composant déjà implémenté — ratifier la valeur, ferme OQ-3 `agent-chat` + OQ-6 `_floating-surfaces` | Design System (Dyad) |
| **Logos §13** | 404 = COLORED (3 docs) vs MONOCHROME (1 doc ; SSoT §9.1 l.387 vs matrice l.378-388) | version normative unique à coder partout | Design System (Dyad) |
| **OQ-12/48** | routes WDS draft vs router frozen | sémantique `router.tsx` ↔ slugs (`_flows.md` §7) | owner + App Shell |
| **8 docs modules** | completer `docs/{progress,knowledge,discovery,agent,artifacts,design-system}` (table `_report.md` §6) + feature-registry S6 + WDS 04.5 §8 | ferme les OQ écrans hébergées par les modules (256 ouvertes) | équipes modules (Dyad définit les § exacts) |

## 6. PARTIE 2 — Livrable : le plan d'implémentation amélioré
(nouveau fichier `docs/design-system/impl-plan.md`, structure imposée)

- **§0 Arbitrages** — les tranches §5 de ce prompt, décidées + tracées.
- **§1 Architecture globale** — 17 routes primaires ↔ slugs (N final
  post-OQ-1), 5 familles Tab (T1-T5, `_flows` §3.1), surfaces flottantes
  (T5 Command palette + T1-T5 pagers), sémantique router (§7 `_flows`),
  contrats partagés (AD-7 local-first, AD-9 10 événements V1, AD-15
  types, AD-17 theming 3 couches), machine à états cross-pages (§5-6
  `_flows`), « une seule écriture » par lien (AD-7 col. PERSIST).
- **§2 Plan par lots (exécution)** — 1 lot = 1 groupe module = 1 commit
  (préfixe `dyad/impl:`). Par lot : écrans (liste slugs), composants
  `packages/ui` à réutiliser vs créer (ui-libraries — rien d'inventé ;
  engines AD-10 figés : shadcn/Radix, FullCalendar, AG Grid, Tiptap,
  React Flow/Dagre, AntV G2+Infographic, KaTeX, Framer Motion),
  micro-animations/transitions/fluidité (spec §11-§13 des 44 docs),
  6 états UX par écran (loading/empty/success/error/offline/killed),
  OQs clôturées par le lot + preuves (fichier:ligne).
- **§3 Transverses** — pattern 404/feature-disabled (post-OQ-48, logo
  S9 post-arbitrage), les 6 surfaces flottantes, règles d'usage
  AgentThinkingLoader (job agent vs ring), états globales (§5.2
  `_flows`), derives non-bloquantes déclarées (ex. `/progress` partagé
  `analytics` + `progress-dashboard`, `_flows` §8 OQ-08).
- **§4 Flux doc-tools** — les 4 flux agent (génération/lecture
  documents) câblés agent-chat ↔ artifacts-detail ↔ knowledge (§4 de ce
  prompt, `docs/agent/document-tools.md`).
- **§5 Vérification thème** — matrice 13 combos × 2 styles neutres,
  blanc-par-défaut / accent-only, aperçus HTML par lot pour ratification
  owner (jamais de mockups non approuvés).
- **§6 Perf budgets** — JS ≤ 300 Ko gz · TTI ≤ 1.5 s (Pixel 4a) ·
  30 fps (tree 1000 nœuds) · lazy engines AD-10 · animations GPU
  150-250 ms · reduced-motion respecté.
- **§7 Stratégie OQ (256 ouvertes)** — 3 classes : bloquantes (tranchées
  avant exécution), par-lot (clôturées pendant le lot, SSoT mise à jour),
  différées (déclarées + owner OK) ; registre = `_open-questions.md`
  (regénéré par `_gen_oq.py` s'il est commité, sinon main).
- **§8 Non-objets / décisions ≠ corrections** — code modules (AD-7/AD-13),
  DPC focus (OQ-17, out of V1), backend/Supabase, pass QA DAPHNE
  (`prompts/dyad-design-qa.md` — CONSOMME ce plan, ne pas l'exécuter ici),
  mockups.
- **§9 Gates d'exécution** — une phase à la fois, validation explicite
  owner avant avancement, gate pnpm vert avant chaque commit, push par
  commit, rapport evidence-based à chaque porte.

## 7. Rapport de fin OBLIGATOIRE (template)

- « Commits cc/screens: OUI/NON (x/8, gate vert prouvé) »
- « Arbitrages : OQ-1 (N final = ?) / OQ-16 / OQ-48 / OQ-47 / OQ-6 /
  logos 404 / routes — DECIDÉ/NON + SSoT impactée »
- « Plan amélioré : OUI/NON (`docs/design-system/impl-plan.md`, N lots,
  N écrans couverts) »
- « OQs : bloquantes fermées / par-lot / différées (listes) »
- « Ce que l'owner doit fournir/ratifier : [liste explicite] »

## Hors périmètre (pas de double-travail)

- Pass QA DAPHNE (`prompts/dyad-design-qa.md`) — se lance APRÈS
  ratification du plan.
- Build mobile / Ascent / OneSignal (`prompts/dyad-beta-device-ui.md`) —
  déjà traité ; le plan s'en rapproche mais ne rejoue pas ces tâches.
- Backend, secrets, device owner (OQ-17).
