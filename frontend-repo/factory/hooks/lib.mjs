// Shared helpers for factory hooks. Hooks are defence in depth;
// the binding controls are the Azure DevOps branch policies and pipeline checks.
import path from 'node:path';

export async function readInput() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  try { return JSON.parse(raw || '{}'); } catch { return {}; }
}

export function block(reason) {
  process.stderr.write(`Blocked by factory rules: ${reason}\n`);
  process.exit(2);
}

export function projectRelative(filePath, input) {
  const root = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
  const abs = path.resolve(input.cwd || root, filePath);
  const rel = path.relative(root, abs).split(path.sep).join('/');
  return { rel, outside: rel.startsWith('..') || path.isAbsolute(rel) };
}

export const SECRET_PATTERNS = [
  /(^|\/)\.env(\.[^/]*)?$/i,
  /\.(pem|key|pfx|p12|jks)$/i,
  /(^|\/)secrets?\//i,
  /(^|\/)\.npmrc$/i,
];

export const FACTORY_PATTERNS = [/^factory\//, /^pipelines\//, /^\.claude\//, /^CLAUDE\.md$/, /^azure-pipelines\.ya?ml$/];

export const ROLE_WRITE_SCOPE = {
  'analyst': [/^docs\/slices\//],
  'qa-engineer': [/^e2e\/acceptance\//, /^e2e\/fixtures\//],
  'frontend-engineer': [/^src\//],
  'code-reviewer': [/^reviews\//],
  'test-setup': [
    /^package(-lock)?\.json$/, /^angular\.json$/, /^tsconfig\.spec\.json$/,
    /^karma\.conf\.(js|cjs|mjs)$/, /^jest\.config\.[cm]?[jt]s$/, /^setup-jest\.ts$/,
    /^src\/test\.ts$/, /^src\/.*\.spec\.ts$/, /^e2e\/acceptance\//, /^e2e\/fixtures\//, /^\.gitignore$/,
    /^docs\/baseline\/known-issues\.md$/,
  ],
};
