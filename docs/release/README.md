# Aurora — Release (wave 7, ERYNIS)

**Status:** `RELEASE_PIPELINE_WIRED` (wave 7, task 8 — CI/CD + release notes +
changelog). The **process** is wired; the **targets** are still open:
`dev` / `staging` / `prod` env values (OQ-03, Foundation) and the OQ-08
device-observed E2E (run on the provisioned device, not in CI).

Authority: deployment/overview S3/S5 (CI/CD = GitHub Actions, the
mandatory PR pipeline; release = mobile production-ready, ADR S24),
ADR S21.5 (PR pipeline), wave 7 tasks in docs/epics-stories.md (W7-E1).

## 1. Pipeline (what is wired, what is open)

```
push/PR -> ci-base      (install + typecheck + lint + 4 boundary greps)
         -> ci-gate     (main: + spine test, RLS static, no cross-join,
                         + wave 5-7 gates: E2E device, Focus DPC S13,
                         perf, product modes)
         -> release     (tag v* -> APK build + release notes + changelog;
                         CI green gate; deploy steps are DRY-RUN until
                         OQ-03 env values are ratified)
```

| Piece | State | Owner |
|---|---|---|
| `.github/workflows/ci.yml` | WIRING OK (wave 0 gate + wave 5/7 test steps) | CI / ERYNIS |
| `.github/workflows/release.yml` | NEW — tag-triggered build + notes + changelog | ERYNIS |
| `changelog.md` | NEW — per-wave section, release-notes source | ERYNIS |
| OQ-03 env values (dev/staging/prod) | OPEN (Foundation) | Foundation |
| OQ-08 device E2E (Provisioned DPC) | OPEN (run on target device, not CI) | QA + Foundation |

## 2. Release process (per release)

1. **Gate:** `ci-gate` on `main` green (see docs/ci/gate.md for the order +
   recovery). A failing gate = `git revert <sha>` (1 story = 1 commit =
   1 rollback), NOT a squash/amend on `main`.
2. **Notes:** update `docs/release/changelog.md` (one section per wave,
   AD-13 commit granularity: each story = one bullet).
3. **Tag:** `v{major}.{minor}.{patch}` on `main`. The tag pushes
   `.github/workflows/release.yml`:
   - typecheck + lint + test (the ci-gate shape, re-run on the tag),
   - APK assemble (`apps/mobile` Capacitor),
   - `RELEASE_NOTES.md` generated from `changelog.md`,
   - GitHub Release created with the notes + the APK artifact,
   - deploy steps to `staging` then `prod` (Supabase, CF Workers, R2)
     are **commented / dry-run** until OQ-03 ratifies the env values —
     re-enable per AD-16a when the values land in the GitHub Secrets.
4. **Rollback:** `git revert` the offending story commit + re-tag (the
   pipeline is tag-driven, so a new tag = a new build; no in-place
   rewrite of a published release).

## 3. Secrets (AD-3, never in the repo)

- The pipeline reads **only** the `SUPABASE_URL_<env>`,
  `SUPABASE_SERVICE_KEY_<env>`, `POWERSYNC_*` and `CF_*` entries from
  the GitHub Secrets registry (docs/architecture/secrets-checklist.md).
- The APK build embeds the **publishable** keys only; the service key
  and the provider keys never reach the bundle (AD-3, grep G2 in CI).
- `minimumReleaseAge` (pnpm) + lockfile pinning = no surprise dep
  upgrades mid-release.

## 4. Rollback (per AD-13)

1 story = 1 commit = 1 rollback:

- **On `main`:** `git revert <sha>` (a new commit), push, re-run
  `ci-gate`. The release is NOT re-published until the gate is green.
- **On a tagged release:** cut `v{...}-patch` (a new tag) on the
  reverted tree; do NOT move or delete the published tag.

## 5. Open items to close before release (OQ register)

- **OQ-03** — `dev`/`staging`/`prod` env values (regions, R2 bucket
  names, provider account IDs). Owner: Foundation. **Blocks** the
  deploy steps re-enabling.
- **OQ-08** — Playwright + Capacitor device-observed E2E (the
  `e2e/device/e2e-device.spec.ts` suite) on the target Android 14
  device. Owner: QA. The CI gate here (wave 7 task 6) is the
  zero-device gate; the device-observed suite runs on the device.
- **OQ-17** — DPC provisioning on the target phone (the 8-scenario
  Focus DPC suite `e2e/device/focus-dpc.ts`). Consumer fallback (6/8)
  is what the CI gate asserts; the provisioned path (>=7/8, s6
  factory reset tolerated) runs on the provisioned device.
