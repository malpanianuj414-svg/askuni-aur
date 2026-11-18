# setup-all.ps1
# Master automation script for AskUni (Amity University Rajasthan - BCS 522).
# Executes scripts 00 through 04 in sequence and halts immediately on the first failure.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RootDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$startTime = Get-Date

function Write-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

Write-Banner "AskUni Full-Stack Setup & Verification Pipeline"
Write-Host "Project Root: $RootDir" -ForegroundColor DarkGray

$steps = @(
    @{ File = "00-prereq-check.ps1";   Label = "Step 1/5: Prerequisite Check (Node.js >= 18, npm, Git)" },
    @{ File = "01-scaffold-backend.ps1"; Label = "Step 2/5: Scaffold Backend & Install Dependencies" },
    @{ File = "02-scaffold-widget.ps1";  Label = "Step 3/5: Scaffold Frontend Widget & Dashboards" },
    @{ File = "03-seed-and-test.ps1";    Label = "Step 4/5: Seed Database & Run 53 Automated Tests" },
    @{ File = "04-run-all.ps1";          Label = "Step 5/5: Launch Backend + Frontend & Open Browser" }
)

foreach ($step in $steps) {
    $scriptPath = Join-Path $RootDir $step.File
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Host "[ERR] Missing required script: $scriptPath" -ForegroundColor Red
        exit 1
    }

    Write-Banner $step.Label
    $global:LASTEXITCODE = 0
    & $scriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERR] Pipeline halted at $($step.File) (exit code $LASTEXITCODE)." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

$elapsed = (Get-Date) - $startTime
Write-Banner ("AskUni Setup Completed Successfully in {0:mm\:ss}" -f $elapsed)
exit 0