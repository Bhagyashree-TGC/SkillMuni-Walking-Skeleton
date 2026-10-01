#!/usr/bin/env bash
# One-time Azure DevOps set-up for the walking skeleton on SkillMuni Frontend.
# Run by a person with Project Administrator rights (factory administrator: Akash Murumkar).
# Requires: Azure CLI with the azure-devops extension (az extension add --name azure-devops).
# Safe to re-run: it lists what exists and only creates what is missing, except branch
# policies, which you should check in the UI before running twice.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${HERE}/config.env"

az devops configure --defaults organization="$ORG_URL" project="$PROJECT" >/dev/null

say() { printf '\n== %s\n' "$1"; }

REPO_ID="$(az repos show --repository "$REPO" --query id -o tsv)"
say "Repository $REPO ($REPO_ID)"

# 1. Pipelines --------------------------------------------------------------
pipeline_id() { az pipelines list --name "$1" --query '[0].id' -o tsv; }
create_pipeline() {
  local name="$1" yaml="$2"
  if [[ -z "$(pipeline_id "$name")" ]]; then
    az pipelines create --name "$name" --repository "$REPO" --repository-type tfsgit \
      --branch main --yaml-path "$yaml" --skip-first-run true --only-show-errors >/dev/null
    echo "Created pipeline: $name"
  else
    echo "Pipeline exists: $name"
  fi
}
say "Pipelines"
create_pipeline "skillmuni-frontend-pr-validation" "pipelines/pr-validation.yml"
create_pipeline "skillmuni-frontend-deploy-dev" "pipelines/deploy-dev.yml"
PR_PIPELINE_ID="$(pipeline_id skillmuni-frontend-pr-validation)"

# 2. Variable group (no secrets) -------------------------------------------
say "Variable group skillmuni-frontend-factory"
if [[ -z "$(az pipelines variable-group list --group-name skillmuni-frontend-factory --query '[0].id' -o tsv)" ]]; then
  az pipelines variable-group create --name skillmuni-frontend-factory --authorize true \
    --variables nodeVersion=20.x auditLevel=critical useArtifactsFeed=false \
                distFolder=dist devStorageAccount=TO-SET devUrl=TO-SET --only-show-errors >/dev/null
  echo "Created. Edit distFolder, devStorageAccount, devUrl and useArtifactsFeed in Library."
else
  echo "Exists."
fi

# 3. Branch policies on main -----------------------------------------------
say "Branch policies on main"
common=(--blocking true --enabled true --branch main --repository-id "$REPO_ID" --only-show-errors)

az repos policy approver-count create "${common[@]}" \
  --minimum-approver-count 1 --creator-vote-counts false --allow-downvotes false \
  --reset-on-source-push true >/dev/null
echo "Minimum one approver; author's own vote does not count; votes reset on new pushes."

az repos policy required-reviewer create "${common[@]}" \
  --required-reviewer-ids "$TECH_LEAD_EMAIL" \
  --message "Level 1 approval — Tech Lead (Constitution Art. 4A)" >/dev/null
echo "Level 1: Tech Lead required on every pull request."

az repos policy required-reviewer create "${common[@]}" \
  --required-reviewer-ids "$TECH_LEAD_EMAIL" \
  --path-filter "/e2e/acceptance/*" \
  --message "Protected acceptance tests — Tech Lead must review any change" >/dev/null
echo "Protected acceptance tests: Tech Lead review."

# Level 2 is one approver group: Rajib Chowdhury, with Sonal Seth as backup when he is away.
# A group as required reviewer is satisfied by ONE member's approval (listing two people
# directly would require both).
L2_NAME="Level 2 approvers"
L2_DESCRIPTOR="$(az devops security group list --project "$PROJECT" \
  --query "graphGroups[?displayName=='${L2_NAME}'].descriptor | [0]" -o tsv)"
if [[ -z "$L2_DESCRIPTOR" || "$L2_DESCRIPTOR" == "None" ]]; then
  L2_DESCRIPTOR="$(az devops security group create --project "$PROJECT" --name "$L2_NAME" \
    --description "CEO (Rajib Chowdhury); Deputy CEO (Sonal Seth) approves only when the CEO is away" \
    --query descriptor -o tsv)"
fi
for m in "$CEO_EMAIL" "$DEPUTY_CEO_EMAIL"; do
  az devops security group membership add --group-id "$L2_DESCRIPTOR" --member-id "$m" -o none 2>/dev/null || true
done
L2_ID="$(az devops security group show --id "$L2_DESCRIPTOR" --query originId -o tsv)"
echo "Approver group '${L2_NAME}': Rajib Chowdhury, Sonal Seth (backup)."

group_reviewer_policy() {   # $1 = file patterns (comma-separated), $2 = message
  local cfg; cfg="$(mktemp)"
  python3 - "$cfg" "$L2_ID" "$REPO_ID" "$1" "$2" <<'PY2'
import json, sys
out, gid, repo, patterns, msg = sys.argv[1:]
json.dump({
    "isEnabled": True, "isBlocking": True,
    "type": {"id": "fd2167ab-b0be-447a-8ec8-39368250530e"},  # Required reviewers
    "settings": {
        "requiredReviewerIds": [gid], "minimumApproverCount": 1, "creatorVoteCounts": False,
        "message": msg, "filenamePatterns": patterns.split(","),
        "scope": [{"repositoryId": repo, "refName": "refs/heads/main", "matchKind": "Exact"}],
    },
}, open(out, "w"))
PY2
  az repos policy create --config "$cfg" --only-show-errors >/dev/null
  rm -f "$cfg"
}

group_reviewer_policy "/factory/*,/pipelines/*,/.claude/*,/CLAUDE.md,/package.json,/package-lock.json" \
  "Factory rule or toolchain change: Level 2 approval (D-059). Sonal Seth approves only when Rajib Chowdhury is away; say so in a comment."
echo "Factory rule and package files: Level 2 (one of the group) also required."

group_reviewer_policy "/docs/baseline/*,/.gitleaksignore" \
  "Accepting a known baseline issue: CEO sign-off (D-069). Sonal Seth signs only when Rajib Chowdhury is away; say so in a comment."
echo "Known issues: CEO sign-off required (Sonal Seth as backup)."

az repos policy build create "${common[@]}" \
  --build-definition-id "$PR_PIPELINE_ID" --display-name "PR validation (evidence)" \
  --manual-queue-only false --queue-on-source-update-only false --valid-duration 0 >/dev/null
echo "Required build: PR validation must pass."

az repos policy comment-required create "${common[@]}" >/dev/null
echo "All review comments must be resolved."

az repos policy work-item-linking create "${common[@]}" >/dev/null
echo "Every pull request must link a work item."

az repos policy merge-strategy create "${common[@]}" \
  --allow-squash true --allow-no-fast-forward false --allow-rebase false --allow-rebase-merge false >/dev/null
echo "Squash merge only."

say "Done. Manual steps remaining (see SETUP-GUIDE.md, step 5):"
cat <<'TXT'
  - Create environment 'skillmuni-frontend-dev' and add an Approvals check:
    approvers Rajib Chowdhury and Sonal Seth, minimum 1, requester cannot approve.
  - Project settings > Repositories > SkillMuni Frontend > Security: give
    '<Project> Build Service' "Contribute to pull requests" (for the escalation comment).
  - Create service connections 'factory-evidence' and 'skillmuni-dev' (workload identity federation).
TXT
