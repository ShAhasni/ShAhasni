<#
.SYNOPSIS
    One-time developer environment setup for a fresh Windows machine with VS Code.

.DESCRIPTION
    Installs (via winget): Git (includes Git Bash), Python, Node.js LTS, GitHub CLI,
    Windows Terminal, PowerShell 7, Claude Desktop. Then configures Git, upgrades pip,
    installs pipx/uv/ruff, installs Claude Code (CLI + VS Code extension), and installs
    the recommended VS Code extensions.

.USAGE
    Open PowerShell (no admin needed; winget will prompt UAC where required) and run:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\setup\setup-windows.ps1 -GitName "Your Name" -GitEmail "you@example.com"
#>
param(
    [string]$GitName  = "",
    [string]$GitEmail = "",
    [string]$PythonVersion = "3.14",  # stable release line; change to 3.13 if a library needs it
    [string]$VSCodeDir = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-WingetPackage($id) {
    $installed = winget list --id $id -e --accept-source-agreements 2>$null | Select-String $id
    if ($installed) {
        Write-Host "  $id already installed - upgrading if needed"
        winget upgrade --id $id -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    } else {
        Write-Host "  Installing $id"
        winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
    }
}

# --- 0. Pre-checks -----------------------------------------------------------
Write-Step "Checking for winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
}

# --- 1. Core tools -----------------------------------------------------------
Write-Step "Installing core tools"
$packages = @(
    "Git.Git",                          # Git + Git Bash
    "Python.Python.$PythonVersion",     # Python (python.org build, includes py launcher)
    "OpenJS.NodeJS.LTS",                # Node.js LTS + npm
    "GitHub.cli",                       # gh
    "Microsoft.PowerShell",             # PowerShell 7
    "Microsoft.WindowsTerminal",
    "Anthropic.Claude"                  # Claude Desktop app
)
if (-not (Test-Path (Join-Path $VSCodeDir "Code.exe"))) { $packages += "Microsoft.VisualStudioCode" }
foreach ($p in $packages) { Install-WingetPackage $p }
Update-SessionPath

# Make sure VS Code's 'code' command is on PATH (user-scope install puts it in <VSCodeDir>\bin)
$codeBin = Join-Path $VSCodeDir "bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ((Test-Path $codeBin) -and ($userPath -notlike "*$codeBin*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$codeBin", "User")
}
Update-SessionPath
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Error "VS Code 'code' command not found in $codeBin. Pass -VSCodeDir with the correct folder."
}

# --- 2. Git configuration ----------------------------------------------------
Write-Step "Configuring Git"
if ($GitName)  { git config --global user.name  $GitName }
if ($GitEmail) { git config --global user.email $GitEmail }
git config --global init.defaultBranch main
git config --global core.autocrlf true          # CRLF on disk, LF in repo
git config --global pull.rebase false
git config --global credential.helper manager   # Git Credential Manager (ships with Git for Windows)
git config --global core.editor "code --wait"
if (-not (git config --global user.name)) {
    Write-Warning "Git user.name not set. Run: git config --global user.name 'Your Name'"
}

# --- 3. Python tooling -------------------------------------------------------
Write-Step "Setting up Python tooling"
py -$PythonVersion -m pip install --upgrade pip
py -$PythonVersion -m pip install --user pipx
py -$PythonVersion -m pipx ensurepath
py -$PythonVersion -m pipx install uv
py -$PythonVersion -m pipx install ruff

# --- 4. Claude Code ---------------------------------------------------------
Write-Step "Installing Claude Code"
# Claude Code on Windows uses Git Bash as its shell
$gitBash = Join-Path $env:ProgramFiles "Git\bin\bash.exe"
if (Test-Path $gitBash) {
    [Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBash, "User")
    $env:CLAUDE_CODE_GIT_BASH_PATH = $gitBash
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression   # official native installer
}
$claudeBin = Join-Path $env:USERPROFILE ".local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ((Test-Path $claudeBin) -and ($userPath -notlike "*$claudeBin*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$claudeBin", "User")
}
Update-SessionPath

# --- 5. VS Code extensions ---------------------------------------------------
Write-Step "Installing VS Code extensions"
$extFile = Join-Path $PSScriptRoot "vscode-extensions.txt"
Get-Content $extFile | Where-Object { $_ -and -not $_.StartsWith("#") } | ForEach-Object {
    code --install-extension $_.Trim() --force
}

# --- 6. Make Git Bash the default VS Code terminal ---------------------------
Write-Step "Setting Git Bash as default VS Code terminal"
$settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
New-Item -ItemType Directory -Force -Path (Split-Path $settingsPath) | Out-Null
$settings = $null
if (Test-Path $settingsPath) {
    try { $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json } catch { $settings = $null }
}
if ($null -eq $settings) { $settings = New-Object PSObject }
$settings | Add-Member -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "Git Bash" -Force
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

# --- 7. Summary --------------------------------------------------------------
Write-Step "Installed versions"
git --version
py -$PythonVersion --version
node --version
npm --version
gh --version | Select-Object -First 1
claude --version

Write-Host "`nDone. Close and reopen VS Code (and any terminals) so PATH changes take effect." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. gh auth login        # connect GitHub" -ForegroundColor Green
Write-Host "  2. claude               # sign in to Claude Code (opens browser)" -ForegroundColor Green
Write-Host "  3. Open Claude Desktop from the Start menu and sign in" -ForegroundColor Green
