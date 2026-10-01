#!/usr/bin/env bash
# Starts a Claude Code session as one factory role.
# Usage: factory/bin/start-role.sh <role> <work item id | PR id for code-reviewer>
# Roles: analyst | qa-engineer | frontend-engineer | code-reviewer | test-setup
set -euo pipefail

ROLE="${1:-}"
REF="${2:-}"

fail() { printf '\nStopped: %s\n\n' "$1" >&2; exit 1; }

case "$ROLE" in
  analyst) PREFIX="analyst/" ;;
  qa-engineer) PREFIX="qa/" ;;
  frontend-engineer) PREFIX="fe/" ;;
  test-setup) PREFIX="qa-setup/" ;;
  code-reviewer) PREFIX="" ;;
  *) fail "unknown role '${ROLE}'. Use analyst, qa-engineer, frontend-engineer, code-reviewer or test-setup." ;;
esac

[[ "$REF" =~ ^[0-9]+$ ]] || fail "give the Azure Boards work item number (or the pull request number for code-reviewer) as the second argument."

# 1. Subscription only (D-067): an API key would switch Claude Code to metered billing.
for v in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX; do
  if [[ -n "${!v:-}" ]]; then
    fail "${v} is set in this terminal. Claude Code would bill the metered API instead of TGC's Max subscription. Remove it (unset ${v}, and delete it from your shell profile or system environment), open a new terminal and try again."
  fi
done
for f in "$HOME/.claude/settings.json" ".claude/settings.local.json"; do
  if [[ -f "$f" ]] && grep -q '"apiKeyHelper"' "$f"; then
    fail "${f} contains an apiKeyHelper, which would switch Claude Code to API-key billing. Remove that setting and try again."
  fi
done

# 2. Run from the repository root.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "run this inside the SkillMuni Frontend repository."
cd "$ROOT"

# 3. Never work on main; branch must match the role.
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  fail "you are on ${BRANCH}. Create the work branch first, for example: git switch -c ${PREFIX:-fe/}${REF}-short-name"
fi
if [[ -n "$PREFIX" && "$BRANCH" != "$PREFIX"* ]]; then
  fail "branch '${BRANCH}' does not match the ${ROLE} role. Its name must start with '${PREFIX}', for example ${PREFIX}${REF}-short-name"
fi

command -v claude >/dev/null 2>&1 || fail "Claude Code is not installed on this machine."

export FACTORY_ROLE="$ROLE"
export FACTORY_REF="$REF"

printf 'Starting %s for #%s on branch %s (subscription login).\n' "$ROLE" "$REF" "$BRANCH"
printf 'Tip: run /status inside the session to confirm the login method is your Claude Max account.\n\n'

exec claude --append-system-prompt-file "factory/roles/${ROLE}.md" \
  "You are the ${ROLE} for #${REF}. Confirm your role and branch, ask me for the work item details if you do not have them, then follow your role steps."
