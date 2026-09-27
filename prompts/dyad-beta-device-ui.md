# PROMPT — DYAD BETA (build mobile + wiring Ascent + QA design premium)

Tu es DYAD (track design + fullstack). Mission : rendre l'app Aurora
EXÉCUTABLE sur device Android + garantir le look premium des écrans.
C'est le dernier blocage avant la bêta.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## État (ne pas refaire)
- Monorepo pnpm 20 packages + apps/mobile (Ionic React + Capacitor)
- Waves 0–7 livrés : modules, UI (shadcn + FullCalendar + AG Grid +
  Framer Motion + AntV + KaTeX), kernel agent, Ascent, CI/release
- Backend Supabase dev LIVE (19 migrations, 4 jobs pg_cron, 0016 Ascent)
- Gate vert à maintenir : pnpm typecheck / pnpm lint / pnpm test /
  sh scripts/check-boundaries.sh / check-rls.sh / check-view-joins.ts
- 1 story = 1 commit = 1 rollback (AD-13), prefixe "dyad/beta:"

## Lis AVANT de coder (dans cet ordre)
1. docs/ui-libraries.md (S1–S9 : S3 interdit, S5 mobile, S6 5 états +
   killed, S8 framework de décision, S9 brand assets)
2. docs/design-system/overview.md
3. docs/architecture/multi-agent-workflow.md (S3, premium UI)
4. .env.local (AURORA_ONESIGNAL_APP_ID — owner Joy gère les secrets)
5. apps/mobile/capacitor.config.ts

## Regles absolues
- AD-3 : ZERO secret/credential sur device ; OneSignal = appKey seul,
  via process.env.AURORA_ONESIGNAL_APP_ID (PAS de valeur hardcodée)
- PAS de mockups (G-L2 REJECTED 09/27) ; design = tokens thèmes +
  ui-libraries.md, jamais de nouvelle palette
- PAS ion-calendar (→ FullCalendar), PAS ion-list data (→ AG Grid),
  PAS ion-item forms (→ shadcn/Radix), un seul système de composants
  par écran
- Logos : S9 — version SANS fond = en-app (headers / centres de page /
  empty states) ; version complète = icone app externe UNIQUEMENT
- AD-9 : aucun nouvel event ; Ascent = lecture du mirror local
- Animation : fonctionnelle, 150–250ms ; accessibilité WCAG AA,
  touch targets >= 44px, aria-label sur icon buttons
- 5 états UX + killed sur tout composant async (ui-libraries.md S6)

## Taches (1 commit par tache)

### 1. Chemin de build mobile (le blocage n°1)
- Bundler VITE pour apps/mobile : vite.config.ts + index.html (entrée)
  + build → dist/ (JS exécutable, webDir Capacitor déjà = dist)
  + script "dev" (dev-server) ; GARDER tsconfig.build.json (d.ts pour
  les refs composites) — le build web est SEPARÉ du typecheck
- `npx cap add android` (si android/ absent) + `npx cap sync`
- Package.json scripts alignés ; le gate typecheck/lint doit rester
  vert APRES l'ajout du bundler

### 2. Wiring Ascent mobile (flag Sophia)
- AuroraDataProvider (apps/mobile) : brancher le repository Ascent sur
  le LOCAL MIRROR de ascent_paths (lecture seule, offline) au boot
  (packages/data) ; screen Slide-Ascent alimenté par ce provider
- Test : path lisible offline ; états vide/chargement/erreur présents

### 3. OneSignal réel
- capacitor.config.ts : utiliser AURORA_ONESIGNAL_APP_ID depuis
  .env.local (le user remplit la valeur) ; supprimer le placeholder
  fallback si l'env est absente = échec explicite au build (pas de
  clé muette)

### 4. Pass DAPHNE — QA design premium (tous les écrans critiques)
- Écrans : Home AD-14, Goal Dashboard, Slide-Ascent, Focus,
  Semantic Tree, Agent chat, Progress
- Vérifier : look premium (pas de "vieux Ionic"), 5 états + killed,
  cohérence 10 thèmes + 3 presets, tokens (pas de couleur hardcodée),
  logos S9, a11y, 44px
- Fixes = commits "dyad/beta: <écran> premium fixes"

### 5. Perf pass (spec wave 5)
- 30fps (tree 1000 nœuds, Pixel 4a), TTI < 1.5s, JS < 300Ko gz
- Mesures réelles + rapport (pas de claim sans capture)

## Rapport de fin OBLIGATOIRE
- "Build mobile exécutable : OUI/NON (+ artefact généré)"
- "Wiring Ascent : OUI/NON (+ test offline)"
- "OneSignal : OUI/NON (clé via env)"
- "QA design : écrans passés / issues restantes"
- "Perf : 30fps / TTI / JS budget (captures)"
- "Gate vert : OUI/NON (typecheck+lint+test+boundaries)"
- Si NON quelque part : ce qui manque + ce que l'owner doit fournir
