// PreToolUse hook for Bash commands.
import { readInput, block } from './lib.mjs';

const input = await readInput();
const cmd = String((input.tool_input || {}).command || '');
if (!cmd) process.exit(0);

if (!process.env.FACTORY_ROLE) {
  // Read-only inspection is fine without a role; anything that changes state is not.
  if (/\b(git\s+(commit|push|merge|rebase|reset|checkout\s+-b|switch\s+-c)|npm\s+(install|i|ci|add|uninstall)|rm|mv|cp)\b/.test(cmd)) {
    block('this session has no factory role. Start again with factory/bin/start-role.sh.');
  }
}

const role = process.env.FACTORY_ROLE;
const devInstall = /\b(npm|pnpm|yarn)\s+(install|i|add)\s+(?:\S+\s+)*?(-D|--save-dev|--dev)\b/.test(cmd);
if (role === 'test-setup' && devInstall && !/[;&|]/.test(cmd)) {
  process.exit(0); // test-setup may add dev dependencies; the person still confirms each install
}

const rules = [
  [/ANTHROPIC_(API_KEY|AUTH_TOKEN)/, 'Anthropic credentials must never be set or read (subscription only, D-067).'],
  [/\bgit\s+push\b[^\n;&|]*(\s--force\b|\s-f\b|--force-with-lease)/, 'force-push is not allowed.'],
  [/\bgit\s+push\b[^\n;&|]*\b(origin\s+)?(HEAD:)?(refs\/heads\/)?(main|master)\b/, 'pushing to main is not allowed; open a pull request.'],
  [/\bgit\s+commit\b[^\n;&|]*--no-verify/, 'skipping commit checks is not allowed.'],
  [/\bgit\s+config\b[^\n;&|]*\buser\.(name|email)/, 'changing the commit identity is not allowed.'],
  [/\b(cat|less|more|head|tail|type|Get-Content|printenv|env)\b[^\n;&|]*\.env\b/i, 'reading .env files is not allowed.'],
  [/^\s*(env|printenv|set)\s*$/m, 'printing the environment could expose secrets.'],
  [/\brm\s+-[a-zA-Z]*r[a-zA-Z]*\s/, 'recursive deletes need a person; ask first.'],
  [/\b(npm|pnpm|yarn)\s+(install|i|add|uninstall|remove|update|upgrade)\s+(?:-\S+\s+)*[^-\s]/, 'adding, removing or upgrading packages needs approval; ask first. (npm ci is allowed.)'],
  [/\baz\s+/, 'agents do not use the Azure CLI; pipelines do.'],
  [/\b(curl|wget|Invoke-WebRequest)\b[^\n]*\b(-d|--data|-T|--upload-file|-X\s*(POST|PUT|PATCH|DELETE))\b/i, 'sending data to external services is not allowed.'],
];
for (const [pattern, reason] of rules) {
  if (pattern.test(cmd)) block(reason);
}
process.exit(0);
