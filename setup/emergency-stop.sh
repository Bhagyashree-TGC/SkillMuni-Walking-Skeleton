#!/usr/bin/env bash
# EMERGENCY STOP for the factory on SkillMuni Frontend.
# Stops agent work from reaching the repository or environments, at once.
# Undo with emergency-resume.sh. Every use must be recorded in the Decision Register.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${HERE}/config.env"
az devops configure --defaults organization="$ORG_URL" project="$PROJECT" >/dev/null

set_queue_status() {   # $1 = pipeline name, $2 = enabled|disabled
  local id; id="$(az pipelines list --name "$1" --query '[0].id' -o tsv)"
  [[ -z "$id" ]] && { echo "Pipeline not found: $1"; return; }
  local tmp; tmp="$(mktemp)"
  az devops invoke --area build --resource definitions --route-parameters project="$PROJECT" definitionId="$id" \
    --api-version 7.1 -o json > "$tmp"
  python3 - "$tmp" "$2" <<'PY'
import json, sys
p, status = sys.argv[1], sys.argv[2]
d = json.load(open(p)); d["queueStatus"] = status
json.dump(d, open(p, "w"))
PY
  az devops invoke --area build --resource definitions --route-parameters project="$PROJECT" definitionId="$id" \
    --http-method PUT --in-file "$tmp" --api-version 7.1 -o none
  rm -f "$tmp"
  echo "Pipeline $1: $2"
}

echo "EMERGENCY STOP — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
set_queue_status skillmuni-frontend-deploy-dev disabled
set_queue_status skillmuni-frontend-pr-validation disabled
az repos ref lock --name heads/main --repository "$REPO" -o none && echo "Branch main: locked"

cat <<'TXT'

Now, by hand (cannot be scripted safely):
  1. The seat holder exits every Claude Code session (Ctrl+C) and runs /logout.
  2. Revoke any Azure DevOps personal access tokens used by agent sessions
     (User settings > Personal access tokens > Revoke).
  3. Tell the Tech Lead and CEO what happened, in plain language, and record it.
TXT
