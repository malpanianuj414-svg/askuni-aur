# 00-prereq-check.ps1
# Verifies Node.js >= 18, npm, and optional Git on Windows 10/11 (PowerShell 5.1 & 7 compatible).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

Write-Step "AskUni Prerequisite Check (Amity University Rajasthan - BCS 522)"
Write-Host "Working directory: $PSScriptRoot" -ForegroundColor DarkGray
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

$nodeOk = $false
$npmOk = $false
$nodeVersionText = "Not installed"

# 1. Check Node.js >= 18
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($null -ne $nodeCmd) {
    $rawNodeVer = (& node -v 2>&1)
    if ($LASTEXITCODE -eq 0 -and $null -ne $rawNodeVer) {
        $nodeVersionText = $rawNodeVer.ToString().Trim()
        $cleanVer = $nodeVersionText.TrimStart('v', 'V')
        $parts = $cleanVer.Split('.')
        $major = 0
        if ($parts.Length -ge 1 -and [int]::TryParse($parts[0], [ref]$major)) {
            if ($major -ge 18) {
                $nodeOk = $true
                Write-Ok "Node.js detected: $nodeVersionText (meets >= 18 requirement)"
            }
            else {
                Write-Warn "Node.js $nodeVersionText detected, but version 18 or higher is required."
            }
        }
        else {
            Write-Warn "Could not parse Node.js version string: $nodeVersionText"
        }
    }
}
else {
    Write-Warn "Node.js is not installed or not in PATH."
}

# 2. Check npm
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($null -ne $npmCmd) {
    $rawNpmVer = (& npm -v 2>&1)
    if ($LASTEXITCODE -eq 0 -and $null -ne $rawNpmVer) {
        $npmOk = $true
        Write-Ok "npm detected: v$($rawNpmVer.ToString().Trim())"
    }
    else {
        Write-Warn "npm command exists but failed to return a version."
    }
}
else {
    Write-Warn "npm is not installed or not in PATH."
}

# 3. Offer winget installation if Node.js >= 18 or npm is missing
if (-not ($nodeOk -and $npmOk)) {
    Write-Host ""
    Write-Err "Required Node.js (>= 18) and/or npm prerequisites are missing."
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -ne $wingetCmd) {
        $choice = Read-Host "Would you like to install Node.js LTS now via winget? [Y/N]"
        if ($choice -match '^(y|yes)$') {
            Write-Host "Running: winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements" -ForegroundColor Cyan
            & winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) {
                Write-Err "winget installation exited with code $LASTEXITCODE. Please install Node.js LTS manually from https://nodejs.org/"
                exit 1
            }
            Write-Host ""
            Write-Ok "Node.js LTS installation completed."
            Write-Warn "IMPORTANT: Close this PowerShell window, open a NEW terminal so PATH updates, and re-run the scripts."
            exit 1
        }
        else {
            Write-Host "Installation skipped. Please install Node.js >= 18 manually from https://nodejs.org/ and re-run." -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Warn "winget is not available on this machine."
        Write-Host "Please download and install Node.js LTS (>= 18) from https://nodejs.org/, reopen PowerShell, and re-run." -ForegroundColor Yellow
        exit 1
    }
}

# 4. Check Git (optional)
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($null -ne $gitCmd) {
    $rawGitVer = (& git --version 2>&1)
    if ($LASTEXITCODE -eq 0 -and $null -ne $rawGitVer) {
        Write-Ok "Git detected (optional): $($rawGitVer.ToString().Trim())"
    }
}
else {
    Write-Warn "Git not found (optional - AskUni does not require Git to build or run)."
}

# 5. Check write permissions in project root
$probeFile = Join-Path $PSScriptRoot ".write-test.tmp"
try {
    [System.IO.File]::WriteAllText($probeFile, "ok", (New-Object System.Text.UTF8Encoding($false)))
    Remove-Item -Path $probeFile -Force -ErrorAction SilentlyContinue
    Write-Ok "Write permissions verified in $PSScriptRoot"
}
catch {
    Write-Err "Cannot write to $PSScriptRoot : $($_.Exception.Message)"
    exit 1
}

# 6. Check default ports 5000 and 5173 (informational)
foreach ($port in @(5000, 5173)) {
    $inUse = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($null -ne $conn) {
            $inUse = $true
        }
    }
    catch {
        # Fallback if Get-NetTCPConnection is restricted
        $netstatLines = netstat -ano | Select-String ":$port\s+.*LISTENING"
        if ($null -ne $netstatLines) {
            $inUse = $true
        }
    }
    if ($inUse) {
        Write-Warn "Port $port is currently in use. Stop existing process or change PORT in backend/.env before starting."
    }
    else {
        Write-Ok "Port $port is available."
    }
}

Write-Host ""
Write-Ok "All required prerequisites passed! Proceed to 01-scaffold-backend.ps1."
exit 0