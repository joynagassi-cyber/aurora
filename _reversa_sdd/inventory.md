# Aurora — Inventaire du projet (Reversa Scout)

**Généré :** 2026-09-23 · **Agent :** reversa-scout · **Niveau de doc :** complet

## Nature du projet

Aurora n'est **pas** un codebase legacy : c'est un projet en **phase pré-implémentation**.
L'« existant » = documentation d'architecture (88+ fichiers dans `docs/`), le spine ADR v1.7 gelé,
le SPEC avec 17 open questions, 5 packs de Contract Packs (dimensions 01–05), et le plan d'épics/stories
(7 vagues, ~38 stories) dans `docs/epics-stories.md`. Le monorepo pnpm à venir (`apps/mobile`,
`apps/server`, 7 packages) n'existe pas encore.

## Arborescence racine

```
aurora-2/
├── .claude/settings.local.json          # config locale
├── .env.local                           # secrets locaux (gitignored)
├── .mcp.json                            # MCP servers config
├── .gitignore
├── _bmad/                               # BMad framework (bmb setup)
│   ├── config.yaml                      # output folder = _bmad-output
│   └── config.user.yaml                 # user Joy, langue FR
├── _bmad-output/
│   ├── architecture/architecture-aurora-2026-09-21/
│   │   ├── adr-extract.md               # ADR v1.7 (83 KB) — autorité normative
│   │   ├── ARCHITECTURE-SPINE.md        # AD-1..AD-16 gelés (21 KB)
│   │   ├── SPEC.md                      # contrat prescriptif + OQ-01..OQ-17
│   │   ├── dimensions/01..05-*.md       # 5 packs (48–175 KB chacun)
│   │   └── reviews/ (adversary F-01..F-10, pack-coherence, reconciliation)
│   └── implementation-readiness-report-2026-09-22.md
├── AI_RULES.md                          # guide scannable du projet (11 KB)
├── Aurora_Architecture_Decisions_v1_7_final.docx   # source ADR originaire (exclu du git)
├── pnpm-workspace.yaml                  # allowBuilds dyad (monorepo à scaffolder)
├── prompts/                             # session prompts (wave 0–3) + agents (achilles, dyad-design-qa, hermes, minerva)
├── skills/reports/                      # vide
└── docs/                                # 88 fichiers techniques (~30 sous-dossiers)
```

## Modules identifiés (sources d'information)

| Module docs/ | Contenu | Pack de référence |
|---|---|---|
| architecture/ | 00-overview, ADR compliance, traceability, registres, gap-register, permission-matrix | spine + reviews |
| agent/ | kernel (15 §), capability-registry, permissions, e2e-scenarios (20) | AD-12/F-09 |
| ai/ | gateway, model-registry, providers (8), budget, fallback | AD-4/AD-5/AD-16b |
| focus-mode/ | spec S0–S15, android, device-owner | OQ-17 candidat ADR v1.8 |
| mobile/ | navigation, feature-registry/activation/deactivation | pack 04 |
| frontend/ | feature-registry, module-ownership-matrix, page-contracts | pack 02 |
| design-system/ | overview | pack 05 (175 KB) |
| data/ | local-first | pack 03 |
| events/, jobs/ | catalogue événements + jobs | AD-9/AD-8 |
| productivity/, learning/, knowledge/, discovery/, progress/, scientific-engine/ | overviews modules | wave 2 |
| integrations/, security/, testing/, deployment/, workflows/, troubleshooting/ | transverses | — |
| features/master-feature-catalog.md | ~40 features | G-M7 |

## Technologies (ciblées, non installées)

- **Frontend :** Ionic React + TypeScript, React Router v6, Zustand, @tanstack/react-query
- **Mobile :** Capacitor (Android Phase 1)
- **Local-first :** PowerSync + SQLite
- **Backend :** Supabase (PostgreSQL + RLS + Auth + Edge Functions + Cron), pgvector
- **Fichiers :** Cloudflare R2 (presigned)
- **AI :** Agnes (primaire) → Cloudflare AI Gateway → Workers AI → Groq/Cerebras
- **Observation :** Sentry + PostHog
- **Tests :** Vitest (unit), Playwright (E2E), Capacitor smoke (Android)
- **Monorepo :** pnpm (`packages/{domain,data,ui,platform,agent,scientific-engine,integrations}`, `apps/{mobile,server}`)

## Entrypoints

- **Aucun point d'entrée applicatif existant** (monorepo non scaffolder).
- Points de référence : `docs/epics-stories.md` W0-E1-1 = story de scaffolding.
- Configs : `pnpm-workspace.yaml` (préexistant), `AI_RULES.md` (règles d'implémentation).
- CI/CD : GitHub Actions (à créer en wave 0, story W0-E1-4).
- **Canaux agents :** `prompts/session-1..4-wave*.md` (séances de guidance), `prompts/{achilles,dyad-design-qa,hermes,minerva}.md`.

## Intégrations externes

| Service | Rôle | Pack |
|---|---|---|
| Supabase (3 envs dev/staging/prod) | SSoT PostgreSQL + RLS + Auth + Cron | 01 |
| Cloudflare R2 | Buckets privés + presigned URLs | 01 S5.4/AD-16a |
| Cloudflare AI Gateway + Workers AI | Pipeline AI (AD-4/AD-5) | 01 S5.6 |
| OneSignal | Notifications serveur (pack 04) | 04 S3.2 |
| You.com/Tavily/Exa | Research multi-source (Discovery) | W2-E4-1 |
| Composio | Intégrations tierces | integrations/ |

## Base de données

- **Aucun schéma/migration existant.** Schéma à créer en wave 0 (W0-E3-1/W0-E3-2)
  selon `docs/architecture/data-event-job-catalog.md` + `data-ownership-matrix.md` + pack 01 S4.
- `user_context` (root), `events` (AD-9), `job_queue`+`job_logs` (AD-8) = tables fondatrices.

## Tests

- **Aucun test existant.** Cible : Vitest (unit, no DOM) + Playwright (E2E web) + Capacitor smoke.
- Matrice normative : `docs/testing/matrix.md` (systemique + par module). Focus Mode = 13 scenarios [spec S13],
  Agent E2E = 20 scenarios, Workflows composites = 23 [W4-E1-1].

## Résumé Scout

- **Linguage principal :** TypeScript (100% du code cible)
- **Framework principal :** Ionic React + Capacitor + Supabase
- **Modules identifiés :** 7 packages pnpm + 2 apps + ~30 areas docs
- **Intégrations externes :** 6 (Supabase, R2, CF AI Gateway, OneSignal, research providers, Composio)
- **BDD :** à créer (Supabase PostgreSQL + pgvector)
- **Tests :** à créer (Vitest + Playwright)
- **État :** documentation 100% prête, code 0% — **wave 0 = 100% du code à produire**
