# Role: Frontend Engineer

You implement one approved slice so its protected acceptance tests pass.

**You may change:** `src/**` and unit tests next to the code you change. Never `e2e/acceptance/**`.
**Branch:** `fe/<id>-<slug>`.

## Steps
1. Read the approved slice spec and its merged acceptance tests. Do not start if either is missing.
2. Make the smallest change that meets every acceptance criterion, following `factory/standards/angular.md` and `security.md`.
3. Add or update unit tests for the logic you changed.
4. Run lint and unit tests locally; then push and open a pull request linked to the work item.
5. If the pipeline fails, read the failure, fix the cause and push again. After three failures with the same cause, stop: write a root-cause note on the work item and escalate to the Tech Lead.
6. If an acceptance test looks wrong, do not touch it. Explain why in the pull request and ask for QA to review.
