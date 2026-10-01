# Starts a Claude Code session as one factory role (Windows PowerShell).
# Usage: .\factory\bin\start-role.ps1 <role> <work item id | PR id for code-reviewer>
param(
  [Parameter(Mandatory = $true)][ValidateSet('analyst', 'qa-engineer', 'frontend-engineer', 'code-reviewer', 'test-setup')][string]$Role,
  [Parameter(Mandatory = $true)][ValidatePattern('^\d+$')][string]$Ref
)
$ErrorActionPreference = 'Stop'
function Fail($msg) { Write-Host "`nStopped: $msg`n" -ForegroundColor Red; exit 1 }

$prefix = @{ 'analyst' = 'analyst/'; 'qa-engineer' = 'qa/'; 'frontend-engineer' = 'fe/'; 'code-reviewer' = ''; 'test-setup' = 'qa-setup/' }[$Role]

# 1. Subscription only (D-067)
foreach ($v in 'ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'CLAUDE_CODE_USE_BEDROCK', 'CLAUDE_CODE_USE_VERTEX') {
  $val = [Environment]::GetEnvironmentVariable($v)
  if ($val) { Fail "$v is set. Claude Code would bill the metered API instead of TGC's Max subscription. Remove it from your user and system environment variables, open a new terminal and try again." }
}
foreach ($f in "$HOME\.claude\settings.json", ".claude\settings.local.json") {
  if ((Test-Path $f) -and (Select-String -Path $f -Pattern '"apiKeyHelper"' -Quiet)) { Fail "$f contains an apiKeyHelper, which would switch Claude Code to API-key billing. Remove it and try again." }
}

# 2. Repository root
$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { Fail 'run this inside the SkillMuni Frontend repository.' }
Set-Location $root

# 3. Branch rules
$branch = (git rev-parse --abbrev-ref HEAD)
if ($branch -in 'main', 'master') { Fail "you are on $branch. Create the work branch first, for example: git switch -c $(if ($prefix) { $prefix } else { 'fe/' })$Ref-short-name" }
if ($prefix -and -not $branch.StartsWith($prefix)) { Fail "branch '$branch' does not match the $Role role. Its name must start with '$prefix'." }

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Fail 'Claude Code is not installed on this machine.' }

$env:FACTORY_ROLE = $Role
$env:FACTORY_REF = $Ref
Write-Host "Starting $Role for #$Ref on branch $branch (subscription login). Run /status in the session to confirm the login method."
claude --append-system-prompt-file "factory/roles/$Role.md" "You are the $Role for #$Ref. Confirm your role and branch, ask me for the work item details if you do not have them, then follow your role steps."
