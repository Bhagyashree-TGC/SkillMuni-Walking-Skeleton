#!/usr/bin/env bash
# Pipeline check: each agent branch may only change the files its role owns.
# Mirrors factory/hooks/lib.mjs, but this is the binding check (only pipeline evidence counts).
set -euo pipefail

SOURCE_BRANCH="${SOURCE_BRANCH:-}"
BRANCH="${SOURCE_BRANCH#refs/heads/}"

# In an Azure Repos PR build the checkout is the merge commit; its first parent is the target branch.
if git rev-parse -q --verify HEAD^2 >/dev/null; then
  CHANGED="$(git diff --name-only HEAD^1 HEAD)"
else
  git fetch -q origin main
  CHANGED="$(git diff --name-only origin/main...HEAD)"
fi

echo "Branch: ${BRANCH:-unknown}"
echo "Changed files:"; echo "${CHANGED:-<none>}" | sed 's/^/  /'

case "$BRANCH" in
  analyst/*) ROLE="analyst";           ALLOWED='^docs/slices/' ;;
  qa/*)      ROLE="qa-engineer";       ALLOWED='^e2e/(acceptance|fixtures)/' ;;
  qa-setup/*) ROLE="test-setup";       ALLOWED='^(package(-lock)?\.json|angular\.json|tsconfig\.spec\.json|karma\.conf\.(js|cjs|mjs)|jest\.config\.[cm]?[jt]s|setup-jest\.ts|src/test\.ts|src/.*\.spec\.ts|e2e/(acceptance|fixtures)/.*|\.gitignore|docs/baseline/known-issues\.md)$' ;;
  fe/*)      ROLE="frontend-engineer"; ALLOWED='^src/' ;;
  *)         ROLE="" ;;
esac

errors=0
report() { echo "##vso[task.logissue type=error]$1"; errors=$((errors + 1)); }

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ -n "$ROLE" ]]; then
    if [[ "$f" =~ ^(factory/|pipelines/|\.claude/|CLAUDE\.md$|azure-pipelines\.ya?ml$) ]]; then
      report "$f is a factory rule or pipeline file. Agent branches may not change it; a person must change it on a factory-admin/ branch with both approval levels."
    elif [[ "$f" =~ ^e2e/acceptance/ && "$ROLE" != "qa-engineer" && "$ROLE" != "test-setup" ]]; then
      report "$f is a protected acceptance test. Only the QA Engineer may change it, on a qa/ branch."
    elif ! [[ "$f" =~ $ALLOWED ]]; then
      report "$f is outside what the $ROLE role may change ($ALLOWED). Ask the Tech Lead if this file really needs to change."
    fi
  fi
done <<< "$CHANGED"

if (( errors > 0 )); then
  echo "Protected-path check failed with $errors finding(s)."
  exit 1
fi
echo "Protected-path check passed."
