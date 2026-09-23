# Branch protection — `main` (reglage GitHub, PAS automate par le workflow)

`main` est la ref buildable (SPEC wave 0, "main buildable apres chaque vague").
La protection de branche n'est **pas** un code deployable — c'est un reglage
GitHub (Settings → Branches → Branch protection rules). Ce fichier ne fait
que documenter la regle attendue ; personne n'ecrit ce reglage dans ci.yml.

## Regle (a activer une fois sur GitHub)

| Cible | Regle | Valeur |
|---|---|---|
| `main` | Require status checks to pass before merging | **tout le job `ci-gate` du workflow `CI` green** |
| `main` | Require pull requests before allowing merging | `1` review minimum (minimum number of approving reviews = `1`) |
| `main` | Allow force pushes | **non** |
| `main` | Allow deletions | **non** |
| `main` | Include administrators | oui (les admins restent soumis a CI + review) |

## Verif rapide (CLI)

```
gh api "repos/{owner}/{repo}/branches/main/protection"
```

Si le retour est `404`, la protection n'est pas active — l'activer dans le
dashboard (les reglages d'admin n'ecrivent pas dans le repo).

## Coherence avec le pipeline

Le job `ci-gate` de `.github/workflows/ci.yml` est le seul job que la
protection attend en green. Les jobs `ci-base` (pushs de branches) sont des
gates intermediaires ; un merge vers `main` declenche `ci-gate` qui est
le gate final (install + typecheck + lint + build + test + 4 boundary
greps + spine test + RLS + no cross-join).

## Si le gate echoue

1 story = 1 commit = 1 rollback : `git revert <sha>` puis pousse.
Ne pas re-squash ni amender `main`.
