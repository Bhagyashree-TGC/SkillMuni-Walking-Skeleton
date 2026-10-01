# Role: Test Set-up (one-off work item)

You make the project's tests runnable by the pipeline, so that from now on only pipeline results count.
This is done once, before the first slice.

**You may change:** `package.json`, `package-lock.json`, `angular.json` (test sections only), `tsconfig.spec.json`,
`karma.conf.*` or `jest.config.*`, `setup-jest.ts`, `src/test.ts`, `src/**/*.spec.ts`, `e2e/acceptance/**`, `e2e/fixtures/**`, `.gitignore`.
**Branch:** `qa-setup/<id>-<slug>`.
**Packages:** you may add **dev dependencies only** (`npm install -D <package>`); the person confirms each install. Never add, remove or upgrade runtime dependencies.

## Steps
1. **Find out what exists** and report it in plain language before changing anything:
   Angular version; unit test runner (Karma, Jest or none); how many spec files exist; whether `npm test` runs headless; existing e2e tooling.
2. **Unit tests in the pipeline:** add a `test:ci` script that runs the existing unit tests once, headless, with coverage, and writes JUnit XML to `test-results/unit/`:
   - Karma: add `karma-junit-reporter`, a `ChromeHeadlessCI` launcher (`--no-sandbox`) and the `junit` reporter with `outputDir: 'test-results/unit'`.
   - Jest: add `jest-junit` with `JEST_JUNIT_OUTPUT_DIR=test-results/unit`.
   - None: stop and ask the Tech Lead which runner to adopt.
3. **Playwright:** add `@playwright/test` as a dev dependency. `e2e/playwright.config.ts` is provided by the factory; do not change it.
4. **First acceptance test:** write `e2e/acceptance/000-smoke.spec.ts` with one test titled `AC-0: app loads @smoke` that opens `/` and checks the app shell renders (a stable element or the page title). This test also verifies the dev URL after every deployment.
5. **Existing problems (failing unit tests, audit findings):** do not fix, delete or silence them. List each one in the pull request with its error, in plain language. For each, the Tech Lead recommends "fix now" or "accept as known".
   - "Accept as known" needs **Rajib Chowdhury's sign-off**, or Sonal Seth's when he is away (D-069). Propose the entry in `docs/baseline/known-issues.md` (ID `KI-<n>`, issue, where, why, plan to fix, recommended by) and leave "Signed off by CEO" empty for him.
   - Only then may a failing test be skipped, with `// BASELINE-SKIP KI-<n>` on the skip line. The pipeline rejects any other skip.
   - Secret-scan findings are never accepted as known: stop and tell the Tech Lead so the secret is rotated.
6. Add `test-results/`, `playwright-report/` and `.evidence/` to `.gitignore`.
7. Run `npm run test:ci` and `npx playwright test --config e2e/playwright.config.ts` locally, then push and open a pull request linked to the work item. Summarise what you found and changed, and the baseline, in plain language.
