# Walking skeleton — set-up guide

**Scope (authorized 1 October 2026):** walking skeleton only. Take one small, approved change in
SkillMuni Frontend from intake to a verified dev URL, using Claude Code on one Claude Max 5x seat
(Bhagyashree Urunkar), with Azure DevOps enforcing every gate (D-067). Nothing else.

| Who | Does |
| --- | --- |
| Akash Murumkar (Tech Lead, factory administrator) | Steps 2–6, Level 1 approvals |
| Rajib Chowdhury (CEO) · Sonal Seth (deputy) | Level 2 approvals, dev environment approval |
| Bhagyashree Urunkar (agent seat holder) | Step 1, runs the agent sessions in steps 6 and 8 |
| Yash Pohare (UX) | Reviews the slice if it changes UI behaviour |

## What is in this kit

```
SETUP-GUIDE.md                 this guide
DRILLS.md                      the eight failure drills and how to run them
setup/                         one-time Azure and Azure DevOps scripts (run by a person, never by an agent)
frontend-repo/                 files to add to the SkillMuni Frontend repository
  CLAUDE.md                    factory rules every session loads
  .claude/settings.json        hooks and permission rules
  factory/kernel, standards, profile, roles, templates
  factory/bin/start-role.*     the only way to start an agent session
  factory/hooks/               block out-of-role edits, secrets and risky commands
  factory/ci/                  pipeline checks: protected paths, evidence, repeat-failure escalation
  pipelines/                   PR validation and dev deployment
  e2e/playwright.config.ts     acceptance test configuration
docs-repo/                     skeleton for skillmuni-ecosystem-docs
```

## Step 1 — Prepare the agent seat (Bhagyashree)

1. Install Node.js 20 or later, Git and Claude Code on the laptop.
2. Run `claude`, then `/login`, and choose the **Claude account** (your Max subscription), not the API Console.
3. Run `/status` and check the login method shows your Claude Max account.
4. Make sure `ANTHROPIC_API_KEY` is not set anywhere (user and system environment variables, shell profile). The launcher refuses to start if it is.
5. On claude.ai, Settings → Privacy: turn **off** the setting that allows chats and coding sessions to be used to improve Claude (D-068).
6. Never put client personal data, production data or secrets into a session.

## Step 2 — Create the docs repository and store the approved documents

1. Create the Azure Repos repository `skillmuni-ecosystem-docs` and push the `docs-repo/` folder from this kit.
2. Export the five approved documents (Core Constitution v1.1, Program Model, Operating Model, Blueprint, Decision Register) and add them to `overview/factory-design/` using the names in that folder's README.
3. Protect `main` the same way as step 5 (Level 1 and Level 2 reviewers).

## Step 3 — Create the evidence vault (Azure, India region)

1. `cp setup/config.example.env setup/config.env` and fill it in. It holds no secrets.
2. `az login`, then `bash setup/evidence-vault.sh`.
3. In Azure DevOps create two **Azure Resource Manager** service connections using **workload identity federation** (no stored secrets):
   - `factory-evidence` → factory subscription; give its identity **Storage Blob Data Contributor** on the evidence account only.
   - `skillmuni-dev` → the SkillMuni non-production subscription; give it **Storage Blob Data Contributor** on the dev storage account only.
4. SkillMuni Frontend runs only locally today, so create its dev site: `bash setup/dev-hosting.sh`. It creates an Azure Storage static website in Central India and prints the dev URL. Dev uses synthetic data only; production hosting is a separate decision (D-036).
5. Leave the immutability policy **unlocked** until the Compliance Lead confirms the retention period. Locking is irreversible and needs both approvals.

## Step 4 — Add the kit to SkillMuni Frontend (a person, not an agent)

On a branch named `factory-admin/walking-skeleton`:

1. Copy everything in `frontend-repo/` into the repository root.
2. Fill the `TO CONFIRM` items in `factory/profile/skillmuni-frontend.md`.
3. Confirm `npm run build` writes the site to the folder you will put in `distFolder` (usually `dist/<app>/browser` on recent Angular versions).
4. Do **not** set up tests by hand: an agent does that in step 6.
5. In both pipeline files set `evidenceStorageAccount` to the account from step 3.
6. Open a pull request. Because the policies do not exist yet, get both approvals by hand: Akash, then Rajib (or Sonal). Squash-merge.

## Step 5 — Turn on the gates (Akash)

1. `az extension add --name azure-devops`, `az devops login`, then `bash setup/azure-devops-setup.sh`.
2. In Azure DevOps, by hand:
   - **Pipelines → Environments → New** `skillmuni-frontend-dev` → **Approvals and checks → Approvals**: Rajib Chowdhury and Sonal Seth, minimum 1, "allow approvers to approve their own runs" **off**. This is Level 2 for dev deployment.
   - **Library → skillmuni-frontend-factory**: set `distFolder`, `devStorageAccount`, `devUrl`, and `useArtifactsFeed=true` if the project uses an Azure Artifacts feed.
   - **Project settings → Repositories → SkillMuni Frontend → Security**: give `<project> Build Service` **Contribute to pull requests** (needed for the escalation comment).
   - Authorize both pipelines to use the variable group, the two service connections and the environment (first run will ask).
3. Check **Repos → Branches → main → Branch policies** shows: one approver (author's vote excluded), Tech Lead required, Level 2 required on factory and package files, Level 2 group required on known issues, Tech Lead required on `e2e/acceptance`, PR validation required, comments resolved, work item linked, squash only.

## Step 6 — Agent sets up the tests, and the baseline is recorded

1. Akash creates the work item "Test set-up for the pipeline".
2. Bhagyashree: `git switch -c qa-setup/<id>-test-setup` · `factory/bin/start-role.sh test-setup <id>`. The session reports what test tooling exists, wires unit tests into `npm run test:ci` with JUnit output, adds Playwright, writes the first `@smoke` acceptance test, and opens a pull request. Each package install asks you to confirm; only dev dependencies are allowed.
3. The pull request's validation run is the project's **baseline**. Existing problems (failing unit tests, audit findings) are recorded, not fixed silently. For each one Akash recommends "fix now" or "accept as known". **Accepting as known needs Rajib's sign-off (D-069):** the issue goes into `docs/baseline/known-issues.md` as `KI-<n>`, and Azure DevOps requires approval from the "Level 2 approvers" group for any change to that file: Rajib, or Sonal only when he is away (she says so in a comment). A failing test can then be skipped only with `BASELINE-SKIP KI-<n>`; the pipeline rejects any other skip. Secret-scan findings are never accepted: the secret is rotated and removed.
4. Akash (Level 1) and Rajib or Sonal (Level 2, because `package.json` changes the toolchain) approve; squash-merge. The merge deploys to dev after Level 2 approval on the environment, and the `@smoke` test verifies the dev URL for the first time.
5. Confirm the evidence folders appear in the vault under `evidence/skillmuni-frontend/<build id>/`.

## Step 7 — Choose the slice

Akash and Rajib pick one small, low-risk change (for example a label, validation message or empty-state screen) and create the Azure Boards work item. Not sign-in, payments, personal data or deletions.

## Step 8 — Run the journey (Bhagyashree runs the sessions)

| # | Who | What |
| --- | --- | --- |
| 1 | Analyst session | `git switch -c analyst/<id>-<slug>` · `factory/bin/start-role.sh analyst <id>` · paste the work item · the session writes `docs/slices/<id>-<slug>.md` and opens a PR |
| 2 | Akash (+ Yash if UX) | Review and approve the slice spec; Rajib approves as Level 2 |
| 3 | QA session | `git switch -c qa/<id>-<slug>` from updated main · `start-role.sh qa-engineer <id>` · writes acceptance tests, opens PR; the pipeline must show them **failing** for the right reason |
| 4 | Akash, Rajib | Approve the failing tests as correct. They are merged with a validation exception note on the PR, then protected. |
| 5 | Frontend session | `git switch -c fe/<id>-<slug>` · `start-role.sh frontend-engineer <id>` · implements, opens PR; the pipeline must go green |
| 6 | Code Reviewer session | `start-role.sh code-reviewer <PR id>` on the PR branch · writes `reviews/<PR id>.md`; Bhagyashree posts the findings on the PR |
| 7 | Akash | Level 1 approval after findings are resolved; squash-merge |
| 8 | Rajib or Sonal | Level 2 approval on the `skillmuni-frontend-dev` environment; deployment runs |
| 9 | Pipeline | Verifies the dev URL and runs `@smoke` tests; evidence stored in the vault |

Note on step 4: the QA pull request is the one place where a red build is the expected result. The required build policy will block it, so Akash uses **"Override branch policies and enable merge"** with the reason "Acceptance tests failing before implementation, as required (Playwright standard)". That override is visible in the pull request history, which is the record. Merging to `main` also queues a dev deployment; Rajib or Sonal should **reject** that one, since the feature is not built yet. Keep the gap between steps 4 and 5 short: until the feature merges, other pull requests will also show these tests failing.

## Step 9 — Failure drills

Run all eight drills in `DRILLS.md` and record the result of each on the work item.

## Exit criteria

- The journey completed end to end, with every approval and pipeline result linked to the work item.
- Every drill behaved as expected.
- Measured and recorded: number of sessions, usage-limit pauses on the Max 5x seat, elapsed time per step, pipeline minutes.

Then report back. The full factory build is a separate authorization.

## Emergency stop

`bash setup/emergency-stop.sh` disables both pipelines and locks `main`, then lists the manual steps.
`bash setup/emergency-resume.sh` reverses it after both approvals.
