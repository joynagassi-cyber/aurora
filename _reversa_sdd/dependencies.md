# Aurora — Registres de dépendances et graphes (Reversa Scout)

**Généré :** 2026-09-23 · **Niveau de doc :** complet

## Monorepo cible (packages)

| Package | Owner équipe | Rôle | Dépendances internes (graphe orienté) |
|---|---|---|---|
| `packages/domain` | Foundation + par entité (F-01) | SSoT types AD-15, envelopes, événements (9), FeatureDescriptor, AgentCapability | **rien** (centre hexagonal, AD-15) |
| `packages/data` | Data team | PowerSync/SQLite, migrations, repositories, Model Registry, vues PowerSync, bridge RQ (03 S5.8) | `domain` |
| `packages/ui` | Design System team | Design System, contrats AD-10 (5 moteurs encapsulés), tokens, thèmes (pack 05 S5) | `domain` (jamais `data` ni `platform`) |
| `packages/platform` | Foundation (exclusif, AD-16c) | Adapters Capacitor (whitelist 04 S3.1), `capacitor.config.ts` | `domain` |
| `packages/agent` | Agent team | Surface UI du kernel (F-09) — exécution côté serveur (AD-12) | `domain`, `ui` |
| `packages/scientific-engine` | Scientific team | ScientificEngine port, LaTeX | `domain` |
| `packages/integrations` | Integrations team | Research providers, Composio, OneSignal | `domain`, `data` |
| `apps/mobile` | App Shell team | Shell Ionic + Capacitor, feature-slices, routing, état UX (5 normatifs) | `domain`, `data`, `ui`, `platform`, `agent` (pas feature-sibling) |
| `apps/server` | Foundation | Supabase Edge Functions, dispatcher, AI gateway wiring | SDK de fournisseurs **ici uniquement** + workers |

## Invariants de frontières (AD-13, 02-frontend S11)

- `import/no-restricted-paths` ESLint = CI red sur violation.
- `packages/domain` n'importe **rien**.
- Les SDK de fournisseur vivent **uniquement** dans les adapters (`data`, `platform`, `integrations`, `scientific-engine`) + `apps/server` workers.
- `packages/ui` ↛ `packages/data`/`packages/platform`.
- Feature-slices `apps/mobile` ↛ feature-sibling.
- Les 5 moteurs AD-10 (`@xyflow/react`+`@dagrejs/dagre`, `@antv/infographic`, `@antv/g2`, `KaTeX`, `motion`) = **seulement** dans `packages/ui`.

## Services externes (pas de version, valeurs = OQ-03 Foundation wave 0)

| Service | Consommé par | Contrat |
|---|---|---|
| Supabase (dev/staging/prod) | `apps/server`, `packages/data` | RLS par module, `user_context`, `events`, `job_queue` |
| Cloudflare R2 (3 buckets) | `apps/server` (Edge Fn) | presigned 15 min get / 5 min upload |
| Cloudflare AI Gateway | `apps/server` | `AIProvider` port typé (AD-1), pas de nom de modèle dans domain |
| Agnes (primaire), Groq/Cerebras | via gateway | fallback AD-5, 429 jamais contourné par rotation de clés |
| OneSignal | `fn-notifications` (serveur) + `packages/platform` adapter | appKey **uniquement** dans `capacitor.config.ts` (AD-3) |
| You.com/Tavily/Exa | `packages/integrations` | `ResearchProvider` port |
| Composio | `packages/integrations` | port typé |
| Sentry + PostHog | tous les packages (telemetry) | pas de clé dans le bundle client (AD-3) |

## Données de contrôle (OQ)

- **OQ-01** (ratification layout pnpm) + **OQ-02** (mapping équipe par entité AD-15) = **blocants wave 0**, packs 01/03 S8.1.
- **OQ-03** (valeurs env) = tranchées par Foundation wave 0 (AD-16a).
- **OQ-04** (`FOREGROUND_SERVICE` >30 s) = à valider avec pack 03 avant wave 1 → paramètre `minSyncIntervalMs` (owner `packages/data`, 03 S5.7).
- **OQ-08** (framework E2E Android) = **tranché** : Playwright + driver Capacitor ; Appium = fallback si Android 14 non supporté.
- **OQ-09** (list virtualisation) = **tranché** : `IonList` natif, `react-virtuoso` si >100 items.
- **OQ-10** (nom `@aurora/ui`) = **tranché** (assumption).
- **OQ-11** (device de référence) = **tranché** : Pixel 4a (budgets : ≤300 Ko JS gz, ≤1.5 s TTI, 30 fps).
- **OQ-14..16** (thèmes) = **tranchés** : 10 thèmes vivants + 3 presets en V1 ; `Nocturne` preset autonome (pas alias Dark).
- **OQ-17** (Focus DPC) = **OPEN, blocant** pour le figage Focus v1.8 (candidat ADR additif, ne modifie pas le spine gelé) : device owner provisioning + `setPackagesSuspended` (API 29+) + matrice de suspendabilité par package. Si échec = mode dégradé 04 S4.1 (restriction uniquement).

## Ordre de vague (spine S Consistency Conventions / ADR S21.12)

```
wave 0  contrats/tokens/types/schémas/CI            (ce SPEC + packs 01–05 ratifiés, OQ-01/OQ-02 tranchés)
wave 1  Fondations (UI: packages/ui + gating G1 ; Data: PowerSync relay + RLS + R2 ; Auth Supabase)
wave 2  Features (Productivity, Learning, Knowledge, Discovery, Progress, Scientific/Artifacts — G2 figé)
wave 3  Agent Kernel (serveur, F-09)
wave 4  Intégration (flows transverses, 23 workflows)
wave 5  Dyad (refinement UI/UX)
wave 6  Codex (deep review globale)
wave 7  Release candidate (E2E Android, CI/CD, OQ-08)
```

`main` buildable après chaque vague ; test du spine (deux équipes → même contrat) vérifié à chaque merge.
