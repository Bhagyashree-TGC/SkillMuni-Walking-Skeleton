#!/usr/bin/env bash
# Runs when a pull-request build fails. If this is the third failure in a row for the
# same pull request, it raises an escalation to the Tech Lead on the pull request.
# Needs: SYSTEM_ACCESSTOKEN (mapped from $(System.AccessToken)); never printed.
set -euo pipefail

[[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] || { echo "Not a pull-request build; nothing to check."; exit 0; }
[[ -n "${SYSTEM_ACCESSTOKEN:-}" ]] || { echo "No access token mapped; skipping repeat-failure check."; exit 0; }

python3 <<'PY'
import json, os, urllib.request, urllib.parse
e = os.environ
base = e["SYSTEM_COLLECTIONURI"].rstrip("/") + "/" + urllib.parse.quote(e["SYSTEM_TEAMPROJECT"])
headers = {"Authorization": "Bearer " + e["SYSTEM_ACCESSTOKEN"], "Content-Type": "application/json"}

def call(url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body else None, headers=headers, method="POST" if body else "GET")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read() or b"{}")

pr = e["SYSTEM_PULLREQUEST_PULLREQUESTID"]
branch = f"refs/pull/{pr}/merge"
q = urllib.parse.urlencode({"definitions": e["SYSTEM_DEFINITIONID"], "branchName": branch, "statusFilter": "completed",
                            "queryOrder": "finishTimeDescending", "$top": "2", "api-version": "7.1"})
previous = call(f"{base}/_apis/build/builds?{q}").get("value", [])
streak = 1 + sum(1 for _ in __import__("itertools").takewhile(lambda b: b.get("result") == "failed", previous))
print(f"Consecutive failed runs for PR {pr}: {streak}")

if streak >= 3:
    msg = ("**Factory escalation (Constitution: repeated failure).** This pull request has failed validation three times in a row. "
           "The agent must stop retrying. Next step: write a short root-cause note on the work item and ask the Tech Lead (Akash Murumkar) "
           "to decide how to proceed. Latest run: " + e.get("BUILD_BUILDNUMBER", ""))
    repo = e["BUILD_REPOSITORY_ID"]
    call(f"{base}/_apis/git/repositories/{repo}/pullRequests/{pr}/threads?api-version=7.1",
         {"comments": [{"parentCommentId": 0, "content": msg, "commentType": 1}], "status": 1})
    print("##vso[task.logissue type=error]Third consecutive failure: escalated to the Tech Lead on the pull request.")
PY
