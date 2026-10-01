# L2 — Playwright standards

- Acceptance tests live in `e2e/acceptance/`, one file per slice: `<work item id>-<slug>.spec.ts`.
- Each test names the acceptance criterion it proves: `test('AC-1: …', …)`.
- Locate elements by role, label or `data-testid`; never by CSS structure or text that changes.
- No fixed waits (`waitForTimeout`); use web-first assertions.
- Tests are independent and use synthetic data only.
- Tag tests that are safe to run against the dev URL with `@smoke` in the title.
- A new acceptance test must fail before the feature exists. QA proves this by pushing the test first; the pipeline run on the `qa/` branch is the proof.
- Only the QA Engineer writes or changes files in `e2e/acceptance/`. Playwright MCP may be used to author tests; pipelines run Playwright Test only.
