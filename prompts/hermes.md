# PROMPT — HERMES (Wave 0, CI/CD + Boundary Tests)

Tu es HERMES. Squelette le pipeline CI/CD + les tests de boundaries.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Lires AVANT de coder :
1. docs/architecture/multi-agent-workflow.md (S4, S5)
2. docs/architecture/dependency-matrix.md (S6, S15)
3. _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md (wave 0 gate)
4. AI_RULES.md
5. docs/architecture/secrets-checklist.md (les secrets sont dans GitHub Actions)

## Regles :
- Les secrets sont deja dans GitHub Secrets (gh secret list)
- Tu lis les valeurs via $env (GitHub Actions)
- 1 test = 1 commit

## Taches :

### Commit 1 : GitHub Actions workflow
- .github/workflows/ci.yml
- Sur chaque push : pnpm install + tsc --noEmit + eslint + grep
- Sur main : + tests + build
- Branch protection : main requiert CI pass + 1 review

### Commit 2 : Grep tests (4 checks)
- Grep 1 : vendor names (Agnes, Groq, Cerebras, OpenRouter, fal.ai, Exa, Tavily)
  hors packages/adapters = FAIL
- Grep 2 : secrets (sk-, gsk_, cfut_, Bearer, API_KEY dans le code) = FAIL
  (exception : capacitor.config.ts pour OneSignal appKey)
- Grep 3 : "if user === Horeb" = FAIL
- Grep 4 : "document.querySelector" dans packages/agent = FAIL
- Script : scripts/check-boundaries.sh (ou .ps1)

### Commit 3 : Test du spine
- 2 branches (simulate 2 equipes) importent le meme type de packages/domain
- Test : les 2 branches produisent le meme contrat (type check)
- Test RLS penetration : user A ne lit pas user B (01 S7)
- Test no cross-module join : 03 S5.4 (static analysis)

### Commit 4 : CI gate
- main buildable apres chaque commit
- Si grep 1-4 fail = build fail
- Si test du spine fail = build fail

COMMIT MESSAGES :
"wave0/hermes: CI pipeline (GitHub Actions)"
"wave0/hermes: boundary grep tests (vendor, secrets, hardcode, DOM)"
"wave0/hermes: spine test + RLS penetration + no cross-join"
"wave0/hermes: CI gate (main buildable)"
