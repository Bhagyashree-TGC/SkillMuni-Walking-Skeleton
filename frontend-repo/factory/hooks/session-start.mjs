// SessionStart hook: tells the session its role. It cannot stop a session;
// the launcher and the write guards do that.
const role = process.env.FACTORY_ROLE;
const ref = process.env.FACTORY_REF;
let context;

if (process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_AUTH_TOKEN) {
  process.stderr.write('WARNING: an Anthropic API credential is set. This session may be billed to the metered API. Exit now and use factory/bin/start-role.sh.\n');
  context = 'An Anthropic API credential is set in this environment, which breaks factory rule D-067. Do not do any work. Tell the person to exit, remove the credential and restart with factory/bin/start-role.sh.';
} else if (!role) {
  context = 'This session was not started with factory/bin/start-role.sh, so it has no factory role and cannot change files. You may answer questions and read code. If the person wants work done, tell them to exit and restart with: factory/bin/start-role.sh <analyst|qa-engineer|frontend-engineer|code-reviewer|test-setup> <work item number>.';
} else {
  context = `Factory role: ${role}. Reference: #${ref}. Follow factory/roles/${role}.md and the rules in CLAUDE.md. File changes outside your role are blocked.`;
}

process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: context } }));
