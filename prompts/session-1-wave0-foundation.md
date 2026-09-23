# SESSION 1 — WAVE 0 : FONDATION (3 sous-agents paralleles)

Lance 3 sous-agents en parallele. Chaque sous-agent fait SON travail,
n'attend pas les autres. 1 commit par tache.

## Contexte commun (tous les sous-agents)
- Projet : C:\Users\joyda\dyad-apps\aurora-2
- Monorepo pnpm, 14 packages
- ADR v1.7 + Spine AD-1..AD-16 (lis les docs, ne pas recopier)
- Les secrets sont dans .env.local + GitHub Secrets
- Agnes = PRIMARY (toujours premier, retour apres fallback)
- 1 Supabase project (dev = prod pour le V1)
- UI premium : shadcn/ui + FullCalendar + AG Grid + Framer Motion
  (pas ion-calendar, pas ion-list data tables)

---

## SOUS-AGENT 1 : ACHILLES (Monorepo + Domain Types)

Lis :
- _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md
- _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md
- docs/architecture/contract-catalog.md
- docs/architecture/data-ownership-matrix.md
- docs/epics-stories.md (W0-E1)
- AI_RULES.md

Taches :
1. pnpm-workspace.yaml : 14 packages (packages/* + apps/*)
2. packages/domain : 40+ entites AD-15, 9 evenements, 10 ports,
   enveloppes (ApiEnvelope, AIResponseEnvelope, AppError),
   ProblemIR + Quantity + Unit, GoalProject + SubGoal,
   FeatureDescriptor, AgentCapability, NavigationIntent
3. tsc --noEmit passe sur tout
4. ESLint import/no-restricted-paths (domain n'importe RIEN)

Commits :
- "wave0/achilles: pnpm workspace (14 packages)"
- "wave0/achilles: domain types (AD-15, 40+ entities, 9 events, 10 ports)"
- "wave0/achilles: ESLint boundary rules"

---

## SOUS-AGENT 2 : HERMES (CI/CD + Boundary Tests)

Lis :
- docs/architecture/multi-agent-workflow.md (S4, S5)
- docs/architecture/dependency-matrix.md (S6, S15)
- _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md (wave 0)
- docs/architecture/secrets-checklist.md
- AI_RULES.md

Taches :
1. .github/workflows/ci.yml (push = build+lint+grep, main = +tests+build)
2. Grep 1 : vendor names hors adapters = FAIL
3. Grep 2 : secrets dans le code = FAIL (exception capacitor.config.ts)
4. Grep 3 : "if user === Horeb" = FAIL
5. Grep 4 : document.querySelector dans agent = FAIL
6. Test du spine : 2 branches, meme contrat
7. RLS penetration + no cross-join (03 S5.4)
8. main buildable

Commits :
- "wave0/hermes: CI pipeline"
- "wave0/hermes: 4 boundary grep tests"
- "wave0/hermes: spine test + RLS + no cross-join"
- "wave0/hermes: CI gate (main buildable)"

---

## SOUS-AGENT 3 : MINERVA (Supabase + R2 + PowerSync)

Lis :
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/01-backend.md
- _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/03-sync.md
- docs/backend/supabase.md
- docs/cloudflare/r2.md
- docs/architecture/data-ownership-matrix.md
- .env.local (valeurs Supabase, R2, PowerSync)

Taches :
1. Supabase migrations (SQL) : events, job_queue, job_logs, user_context,
   + toutes les tables modules (01 S4.1-4.7)
   RLS par module, vues publiques
2. PowerSync schema (03 S4.2) : quelles tables sync, config relay
3. R2 presigned URLs (get 15min, upload 5min), test upload/download
4. Cron (pg_cron) + 4 Edge Functions stabs
   (fn-job-dispatcher, fn-import-course, fn-notifications, fn-agent-run)

Commits :
- "wave0/minerva: Supabase migrations + RLS + views"
- "wave0/minerva: PowerSync schema + relay"
- "wave0/minerva: R2 presigned + test"
- "wave0/minerva: Cron + Edge Functions stubs"

---

## Quand les 3 sont finis
- main buildable (tsc + lint + grep + tests)
- pnpm install passe
- Le repo est pret pour la vague 1
