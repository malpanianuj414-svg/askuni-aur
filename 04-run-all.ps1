# 04-run-all.ps1
# Launches AskUni backend (port 5000) and frontend (port 5173) in separate PowerShell windows,
# polls http://localhost:5000/api/health until ready, and opens the demo page in the default browser.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RootDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

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

$backendDir = Join-Path $RootDir "backend"
$frontendDir = Join-Path $RootDir "frontend"

if (-not (Test-Path (Join-Path $backendDir "package.json"))) {
    Write-Err "Backend not found at $backendDir. Run 01-scaffold-backend.ps1 first."
    exit 1
}

if (-not (Test-Path (Join-Path $frontendDir "package.json"))) {
    Write-Err "Frontend not found at $frontendDir. Run 02-scaffold-widget.ps1 first."
    exit 1
}

# Detect available PowerShell executable (pwsh or powershell)
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

Write-Step "Starting AskUni Backend Server (http://localhost:5000)"
$backendCmd = "Set-Location '$backendDir'; `$Host.UI.RawUI.WindowTitle = 'AskUni Backend (Port 5000)'; npm start"
Start-Process -FilePath $psExe -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $backendCmd) | Out-Null

Write-Step "Starting AskUni Frontend Vite Server (http://localhost:5173)"
$frontendCmd = "Set-Location '$frontendDir'; `$Host.UI.RawUI.WindowTitle = 'AskUni Frontend (Port 5173)'; npm run dev"
Start-Process -FilePath $psExe -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $frontendCmd) | Out-Null

# Poll http://localhost:5000/api/health with retry loop
Write-Step "Waiting for Backend Health Endpoint (http://localhost:5000/api/health)"
$healthUrl = "http://localhost:5000/api/health"
$maxRetries = 30
$healthy = $false

for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        $resp = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 2
        if ($null -ne $resp -and $resp.success -eq $true) {
            $healthy = $true
            Write-Ok "Backend is healthy! Service: $($resp.service) | Mode: $($resp.database.mode)"
            break
        }
    }
    catch {
        Write-Host "  Attempt $attempt/$maxRetries - waiting for backend..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
    }
}

if (-not $healthy) {
    Write-Err "Backend did not respond at $healthUrl within $maxRetries seconds. Check the Backend PowerShell window for errors."
    exit 1
}

# Brief wait for Vite dev server on port 5173
$frontendUrl = "http://localhost:5173"
$feReady = $false
for ($i = 1; $i -le 15; $i++) {
    try {
        $feResp = Invoke-WebRequest -Uri $frontendUrl -UseBasicParsing -TimeoutSec 2
        if ($feResp.StatusCode -eq 200) {
            $feReady = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if ($feReady) {
    Write-Ok "Frontend dev server is live at $frontendUrl"
}
else {
    Write-Warn "Frontend server is still warming up; opening browser to $frontendUrl..."
}

Write-Step "Opening AskUni Demo Portal in Default Browser"
Start-Process $frontendUrl

Write-Host ""
Write-Ok "AskUni is running!"
Write-Host "  Student Portal + Widget : http://localhost:5173" -ForegroundColor White
Write-Host "  Embed Demo Page         : http://localhost:5173/embed-demo.html" -ForegroundColor White
Write-Host "  Admin Staff Dashboard   : http://localhost:5173/admin" -ForegroundColor White
Write-Host "  System Admin Console    : http://localhost:5173/sysadmin" -ForegroundColor White
Write-Host "  Backend Health API      : http://localhost:5000/api/health" -ForegroundColor White
exit 0