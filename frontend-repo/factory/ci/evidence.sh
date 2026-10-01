#!/usr/bin/env bash
# Collects pipeline evidence into one folder with a manifest of SHA-256 hashes.
# Usage: evidence.sh <stage label>   (runs with condition: always())
set -euo pipefail

LABEL="${1:-validation}"
OUT="${BUILD_ARTIFACTSTAGINGDIRECTORY:-./out}/evidence"
mkdir -p "$OUT"

copy_if() { [[ -e "$1" ]] && cp -r "$1" "$OUT/" || true; }
copy_if test-results
copy_if playwright-report
copy_if .evidence

python3 - "$OUT" "$LABEL" <<'PY'
import hashlib, json, os, sys, datetime
out, label = sys.argv[1], sys.argv[2]
files = []
for root, _, names in os.walk(out):
    for n in sorted(names):
        p = os.path.join(root, n)
        if n == "manifest.json":
            continue
        h = hashlib.sha256(open(p, "rb").read()).hexdigest()
        files.append({"path": os.path.relpath(p, out), "sha256": h, "bytes": os.path.getsize(p)})
e = os.environ.get
manifest = {
    "schema": "tgc-factory-evidence/1",
    "stage": label,
    "project": "SkillMuni Frontend",
    "pipeline": e("BUILD_DEFINITIONNAME"),
    "buildId": e("BUILD_BUILDID"),
    "buildNumber": e("BUILD_BUILDNUMBER"),
    "commit": e("BUILD_SOURCEVERSION"),
    "sourceBranch": e("SYSTEM_PULLREQUEST_SOURCEBRANCH") or e("BUILD_SOURCEBRANCH"),
    "pullRequestId": e("SYSTEM_PULLREQUEST_PULLREQUESTID"),
    "jobStatus": e("AGENT_JOBSTATUS"),
    "requestedFor": e("BUILD_REQUESTEDFOR"),
    "createdUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "files": files,
}
json.dump(manifest, open(os.path.join(out, "manifest.json"), "w"), indent=2)
print(f"Evidence manifest written with {len(files)} file(s).")
PY
