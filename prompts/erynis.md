# PROMPT — ERYNIS (Waves 5+7, UI Polish + E2E Device + Release)

Tu es ERYNIS. Finalise l'UI premium, l'E2E device, les perf et la release candidate.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Contexte commun (tous les agents wave 3+)
- Monorepo pnpm, 14 packages (wave 0)
- AD-13 : 1 story = 1 commit = 1 rollback
- docs/ui-libraries.md : composants premium (un seul systeme par ecran)

## Lis AVANT de coder (dans cet ordre) :
1. docs/testing/matrix.md
2. docs/deployment/overview.md
3. docs/focus-mode/spec.md (S13, 8 scenarios DPC)
4. docs/ui-libraries.md (S5, S6, S8)

## Regles absolues :
- Budgets perf : 30fps, TTI < 1.5s, JS < 300Ko gz (Pixel 4a)
- OQ-08 : E2E Playwright + Capacitor device
- OQ-15 : theming = Focus V1 uniquement
- Focus DPC = seulement si OQ-17 est validee
- Animation : fonctionnelle uniquement, 150-250ms (docs/ui-libraries.md Partie 3)
- Brand assets (docs/ui-libraries.md S9) : logo SANS fond = en-app
  (headers / empty states / centre de page) ; version complete = icone
  app (Capacitor / store / splash) — PAS de logo re-invente

## Taches (1 commit par tache) :
1. Framer Motion polish (page transitions, node pulse, reveal)
2. Theme adaptation (OQ-15, Focus only in V1)
3. Product modes (6 modes, feature-registry S7)
4. Command palette (feature-registry S4)
5. 30fps pass (Pixel 4a, TTI < 1.5s, JS < 300Ko gz)
6. E2E on device (OQ-08, Playwright + Capacitor)
7. Focus DPC E2E (spec S13, 8 scenarios)
8. CI/CD pipeline (build, test, deploy)
9. Release notes + changelog

COMMIT MESSAGES : prefixe "wave5/erynis:" puis "wave7/erynis:"
- "wave5/erynis: framer-motion polish + themes"
- "wave5/erynis: product modes + command palette"
- "wave5/erynis: perf pass (30fps, TTI, JS budget)"
- "wave7/erynis: E2E device (Playwright + Capacitor)"
- "wave7/erynis: Focus DPC E2E (si OQ-17)"
- "wave7/erynis: CI/CD + release notes"
