#!/usr/bin/env bash
# Pipeline check: a pull request may only skip or disable a test if the skip references an
# accepted known issue (KI-<n>) listed in docs/baseline/known-issues.md. Accepting an issue
# needs the CEO's sign-off, enforced by a required-reviewer policy on docs/baseline/ (D-069).
set -euo pipefail

if git rev-parse -q --verify HEAD^2 >/dev/null; then BASE="HEAD^1"; else git fetch -q origin main; BASE="origin/main"; fi
LEDGER="docs/baseline/known-issues.md"

# Lines added in test files that skip or disable a test.
ADDED="$(git diff -U0 "$BASE" HEAD -- '*.spec.ts' '*.test.ts' | grep -E '^\+[^+]' || true)"
SKIPS="$(printf '%s\n' "$ADDED" | grep -E '(\bxit\(|\bxdescribe\(|\bxtest\(|\b(it|test|describe)\.(skip|fixme)\(|\bpending\(|BASELINE-SKIP)' || true)"

if [[ -z "$SKIPS" ]]; then echo "No new skipped tests."; exit 0; fi

errors=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  id="$(printf '%s' "$line" | grep -oE 'BASELINE-SKIP KI-[0-9]+' | grep -oE 'KI-[0-9]+' || true)"
  if [[ -z "$id" ]]; then
    echo "##vso[task.logissue type=error]A test is skipped without an accepted known issue: ${line:1:160}. Add 'BASELINE-SKIP KI-<n>' and list KI-<n> in ${LEDGER} (needs the CEO's sign-off)."
    errors=$((errors + 1))
  elif ! grep -qE "^\|[[:space:]]*${id}[[:space:]]*\|" "$LEDGER" 2>/dev/null; then
    echo "##vso[task.logissue type=error]${id} is not listed in ${LEDGER}. Accepting it needs the CEO's sign-off."
    errors=$((errors + 1))
  else
    echo "Skip references accepted issue ${id}."
  fi
done <<< "$SKIPS"

(( errors == 0 )) || { echo "Skipped-test check failed with $errors finding(s)."; exit 1; }
