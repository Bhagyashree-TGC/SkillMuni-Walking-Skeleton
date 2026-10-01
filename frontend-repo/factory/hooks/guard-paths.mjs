// PreToolUse hook for Edit | Write | MultiEdit | NotebookEdit.
import { readInput, block, projectRelative, SECRET_PATTERNS, FACTORY_PATTERNS, ROLE_WRITE_SCOPE } from './lib.mjs';

const input = await readInput();
const ti = input.tool_input || {};
const target = ti.file_path || ti.notebook_path || ti.path;
if (!target) process.exit(0);

const role = process.env.FACTORY_ROLE;
const { rel, outside } = projectRelative(target, input);

if (!role || !ROLE_WRITE_SCOPE[role]) {
  block('this session has no factory role. Close it and start again with factory/bin/start-role.sh <role> <work item>.');
}
if (outside) block(`${target} is outside the repository.`);
if (SECRET_PATTERNS.some((p) => p.test(rel))) block(`${rel} may hold secrets; agents never write these files.`);
if (FACTORY_PATTERNS.some((p) => p.test(rel))) block(`${rel} is a factory rule or pipeline file; only people change these, with both approval levels.`);
if (/^e2e\/acceptance\//.test(rel) && !['qa-engineer', 'test-setup'].includes(role)) {
  block(`${rel} is a protected acceptance test; only the QA Engineer changes it, through a reviewed pull request.`);
}
if (!ROLE_WRITE_SCOPE[role].some((p) => p.test(rel))) {
  block(`the ${role} role may not change ${rel}. Allowed: ${ROLE_WRITE_SCOPE[role].map(String).join(', ')}.`);
}
process.exit(0);
