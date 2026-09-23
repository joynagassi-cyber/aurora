# CI Gate — wave 0 (main buildable)

**Ref:** SPEC.md wave 0 ("main buildable apres chaque vague"),
AD-16c (owner CI = Foundation), dependency-matrix S15 ("Testing the
Decoupling (CI + integration)").

Le gate final sur `main` = le job `ci-gate` de `.github/workflows/ci.yml`.
Il n'etant pas declenche sur les pushes de branches (seuls les pushes de
`main` et les PR vers `main`), c'est le gate que la branch protection
attend en green.

## Ordre exact du gate (job `ci-gate`)

```
pnpm install
  → typecheck (pnpm -r exec tsc --noEmit)
  → lint      (pnpm -r exec eslint . --max-warnings=0)
  → tests     (pnpm -r exec vitest run)
  → build     (pnpm -r exec tsc --noEmit)
  → spine test (tests/spine/equipe-{a,b}.test.ts: 2 equipes, 1 contrat, AD-15)
  → RLS static (scripts/check-rls.sh: 01 S2.2/S7, ENABLE RLS + pas de policy permissive + FORCE RLS service_role)
  → no cross-join (scripts/check-view-joins.ts: 03 S5.4/F-03, vues PowerSync)
  → boundary greps G1-G4 (scripts/check-boundaries.sh: AD-1/AD-2/AD-3)
```

Les 3 checks `spine test`, `RLS static`, `no cross-join` echouent le
run tant que `continue-on-error` n'est pas satisfait — c'est le
comportement voulu en wave 0 (les scripts existent, les packages
n'existent pas encore, le run reste vert avec un log explicite, pas
un FAIL bloquant).

## Si un gate echoue

**1 story = 1 commit = 1 rollback.** Ne pas re-squash ni amender
`main`.

```
git revert <sha-du-commit-problematique>
git push
```

Le revert est le commit "1" du rollback ; le run de CI se relance sur
le nouvel etat de `main`.

## Quand le gate passe-t-il du "skip with reason" au "gate strict"?

Au merge de la premiere PR de wave 1 (fondations : `packages/domain`,
`packages/data`, `packages/ui`), les `continue-on-error` et les
`if: hashFiles(...)` tombent, le gate devient strict, et le
`main buildable` devient invariant verifiable a chaque push.

- **TODO(wave1):** run RLS live contre Supabase dev
  (user A ne lit pas les lignes de user B, sur chaque table — 01 S7
  bloquant, marquee dans scripts/check-rls.sh et dans ci.yml).
- **TODO(wave1):** ajouter les cas de test 03 S7 (1 test par scope
  PowerSync) dans packages/data/scopes/, et run check-view-joins.ts
  sur la suite complete.
- **TODO(wave1):** les secrets GitHub (SUPABASE_URL_DEV, SUPABASE_ANON_KEY_DEV,
  POWERSYNC_URL_DEV, etc. — cf docs/architecture/secrets-checklist.md)
  alimentent le gate live ; jamais en clair dans ce repo (AD-3).

## Branch protection (rappel)

Le reglage GitHub (pas automate par ci.yml) attend tout le job
`ci-gate` en green + 1 review sur `main`, pas de force-push.
Detail: `.github/BRANCH-PROTECTION.md`.
