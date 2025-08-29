# Installs: Python 3.8 (via winget if available, else via pyenv-win), Git, and VS Code.
# Requires: Windows 10/11 with winget (App Installer). Run from an elevated PowerShell.

[CmdletBinding()]
param(
  [string]$PythonVersion = "3.8.18"  # Latest 3.8.x for pyenv fallback
)

$ErrorActionPreference = "Stop"

function Write-Info  { param($m) Write-Host "`n[mgr] $m" -ForegroundColor Green }
function Write-Warn  { param($m) Write-Host "`n[warn] $m" -ForegroundColor Yellow }
function Write-Err   { param($m) Write-Host "`n[err]  $m" -ForegroundColor Red }

# --- Ensure elevation ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
  Write-Info "Re-launching with Administrator privileges..."
  Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"","-PythonVersion","$PythonVersion"
  )
  exit
}

# --- Pre-flight checks ---
# winget present?
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Err "winget (App Installer) not found. Install from Microsoft Store (App Installer), then re-run."
  exit 1
}

# Better TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Winget-Install {
  param(
    [Parameter(Mandatory=$true)][string]$Id,
    [string]$Version,
    [string]$Source = "winget",
    [switch]$Exact
  )
  $args = @("install","--id",$Id,"--source",$Source,"--accept-package-agreements","--accept-source-agreements","--silent")
  if ($Exact)   { $args += "--exact" }
  if ($Version) { $args += @("--version",$Version) }

  try {
    Write-Info "Installing $Id $(if ($Version) { "($Version)" }) via winget..."
    winget @args | Out-Null
    return $true
  } catch {
    Write-Warn "winget install for $Id failed: $($_.Exception.Message)"
    return $false
  }
}

function Winget-Present {
  param([string]$Id)
  try {
    $out = winget list --id $Id --exact --source winget 2>$null
    return ($LASTEXITCODE -eq 0) -and ($out -match $Id)
  } catch {
    return $false
  }
}

# --- Install Git ---
if (Winget-Present -Id "Git.Git") {
  Write-Info "Git already installed (winget reports present)."
} else {
  if (-not (Winget-Install -Id "Git.Git" -Exact)) {
    Write-Err "Failed to install Git.Git via winget."
  }
}
try { & git --version | Out-Host } catch { Write-Warn "Git not on PATH yet (open a new shell after script finishes)." }

# --- Install VS Code ---
if (Winget-Present -Id "Microsoft.VisualStudioCode") {
  Write-Info "VS Code already installed (winget reports present)."
} else {
  if (-not (Winget-Install -Id "Microsoft.VisualStudioCode" -Exact)) {
    Write-Err "Failed to install VS Code via winget."
  }
}
try { & code --version | Select-Object -First 1 | Out-Host } catch { Write-Warn "Code not on PATH yet (open a new shell after script finishes)." }

# --- Install Python 3.8 ---
# Strategy:
# 1) Try dedicated 3.8 package via winget if available (Python.Python.3.8).
# 2) If not available OR fails, install pyenv-win (via winget) and use it to install $PythonVersion.

$pythonOk = $false

# Option A: winget direct 3.8 (if package exists on your machine's winget source)
$py38WingetId = "Python.Python.3.8"
$havePy38Id   = $false
try {
  $probe = winget show --id $py38WingetId --exact --source winget 2>$null
  $havePy38Id = ($LASTEXITCODE -eq 0)
} catch { $havePy38Id = $false }

if ($havePy38Id) {
  Write-Info "Found $py38WingetId in winget source. Attempting install..."
  if (Winget-Install -Id $py38WingetId -Exact) {
    $pythonOk = $true
  }
} else {
  Write-Warn "winget does not expose $py38WingetId on this machine. Using pyenv-win fallback."
}

# Option B: pyenv-win fallback
if (-not $pythonOk) {
  # Install pyenv-win from winget (recommended)
  if (Winget-Present -Id "pyenv-win.pyenv-win") {
    Write-Info "pyenv-win already installed."
  } else {
    if (-not (Winget-Install -Id "pyenv-win.pyenv-win" -Exact)) {
      Write-Err "Failed to install pyenv-win via winget."
      exit 1
    }
  }

  # Ensure pyenv-win paths are available for THIS session (even before you open a new terminal).
  $pyenvRoot = Join-Path $env:USERPROFILE ".pyenv\pyenv-win"
  $sessionPaths = @(
    (Join-Path $pyenvRoot "bin"),
    (Join-Path $pyenvRoot "shims")
  )
  foreach ($p in $sessionPaths) {
    if (-not ($env:PATH -split ";" | Where-Object { $_ -ieq $p })) {
      $env:PATH = "$p;$env:PATH"
    }
  }

  # Install desired Python 3.8.x and set global
  Write-Info "Installing Python $PythonVersion via pyenv-win..."
  & pyenv install -s $PythonVersion
  & pyenv global $PythonVersion
  $pythonOk = $true
}

# --- Verify Python ---
if ($pythonOk) {
  try {
    $ver = & python -V
    Write-Info "Python installed: $ver"
  } catch {
    Write-Warn "Python not on PATH yet. Open a NEW PowerShell window and run 'python -V'."
  }

  Write-Info @"
TIP: To create a 3.8 virtual environment:
  python -m venv .venv
  .\.venv\Scripts\Activate.ps1
"@
} else {
  Write-Err "Python 3.8 installation was not successful."
  exit 1
}

Write-Info "All done! ✅  (If commands aren't found, open a NEW terminal to refresh PATH.)"
