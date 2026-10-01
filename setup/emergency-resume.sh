#!/usr/bin/env bash
# Reverses emergency-stop.sh. Run only after the Tech Lead (Level 1) and CEO (Level 2) agree.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${HERE}/config.env"
az devops configure --defaults organization="$ORG_URL" project="$PROJECT" >/dev/null

read -r -p "Confirm both approvals were given and recorded (type RESUME): " answer
[[ "$answer" == "RESUME" ]] || { echo "Not resumed."; exit 1; }

for name in skillmuni-frontend-pr-validation skillmuni-frontend-deploy-dev; do
  id="$(az pipelines list --name "$name" --query '[0].id' -o tsv)"
  [[ -z "$id" ]] && continue
  tmp="$(mktemp)"
  az devops invoke --area build --resource definitions --route-parameters project="$PROJECT" definitionId="$id" --api-version 7.1 -o json > "$tmp"
  python3 -c "import json,sys;p=sys.argv[1];d=json.load(open(p));d['queueStatus']='enabled';json.dump(d,open(p,'w'))" "$tmp"
  az devops invoke --area build --resource definitions --route-parameters project="$PROJECT" definitionId="$id" --http-method PUT --in-file "$tmp" --api-version 7.1 -o none
  rm -f "$tmp"; echo "Pipeline $name: enabled"
done
az repos ref unlock --name heads/main --repository "$REPO" -o none && echo "Branch main: unlocked"
