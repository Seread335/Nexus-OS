#!/usr/bin/env powershell
# Detailed diagnostic script for Nexus OS setup troubleshooting
# Run as Administrator

param(
    [switch]$Verbose = $false
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Nexus OS - Diagnostic Check" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Test 1: Check if running as Administrator
Write-Host "[TEST 1] Administrator privileges" -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Write-Host "  PASS: Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Not running as Administrator" -ForegroundColor Red
    Write-Host "  ACTION: Run PowerShell as Administrator" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 2: Git/Bash
Write-Host "[TEST 2] Git Bash installation" -ForegroundColor Yellow
$bashPath = $null
$gitBashPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "D:\Git\bin\bash.exe"
)

foreach ($path in $gitBashPaths) {
    if (Test-Path $path) {
        $bashPath = $path
        break
    }
}

if ($bashPath) {
    Write-Host "  PASS: Git Bash found at: $bashPath" -ForegroundColor Green
} else {
    # Try to find via PATH
    try {
        $bashCmd = Get-Command bash -ErrorAction Stop
        Write-Host "  PASS: bash found in PATH: $($bashCmd.Source)" -ForegroundColor Green
        $bashPath = $bashCmd.Source
    } catch {
        Write-Host "  FAIL: Git Bash not found" -ForegroundColor Red
        Write-Host "  ACTION: Install Git for Windows from https://git-scm.com/download/win" -ForegroundColor Yellow
        $allGood = $false
    }
}
Write-Host ""

# Test 3: Docker
Write-Host "[TEST 3] Docker installation" -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    Write-Host "  PASS: Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Docker not found or not in PATH" -ForegroundColor Red
    Write-Host "  ACTION: Install Docker Desktop from https://docker.com/products/docker-desktop" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 4: Docker daemon running
Write-Host "[TEST 4] Docker daemon status" -ForegroundColor Yellow
try {
    $psOutput = docker ps 2>&1
    if ($psOutput -match "CONTAINER ID" -or $LASTEXITCODE -eq 0) {
        Write-Host "  PASS: Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: Docker daemon not responding" -ForegroundColor Red
        Write-Host "  ACTION: Start Docker Desktop (check system tray)" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "  FAIL: Docker daemon not responding (error: $($_.Exception.Message))" -ForegroundColor Red
    Write-Host "  ACTION: Start Docker Desktop or restart Windows" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 5: Docker image availability
Write-Host "[TEST 5] Arch Linux Docker image" -ForegroundColor Yellow
try {
    $images = docker images --format "table {{.Repository}}:{{.Tag}}" 2>&1 | Select-String "archlinux"
    if ($images) {
        Write-Host "  PASS: archlinux image found locally (faster builds)" -ForegroundColor Green
    } else {
        Write-Host "  INFO: archlinux image not cached (will download on first build)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  WARNING: Could not check Docker images" -ForegroundColor Yellow
}
Write-Host ""

# Test 6: WSL2
Write-Host "[TEST 6] WSL2 installation" -ForegroundColor Yellow
try {
    $wslOutput = wsl --list --verbose 2>&1
    if ($wslOutput -match "Ubuntu|Arch|debian") {
        Write-Host "  PASS: WSL2 distribution found" -ForegroundColor Green
        Write-Host "  Distributions:"
        $wslOutput | Select-String -Pattern "^  " | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    } else {
        Write-Host "  FAIL: No WSL2 distribution installed" -ForegroundColor Red
        Write-Host "  ACTION: Run (as Admin): wsl --install -d Ubuntu" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "  FAIL: WSL2 not found (error: $($_.Exception.Message))" -ForegroundColor Red
    Write-Host "  ACTION: Install WSL2: wsl --install" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 7: Repository structure
Write-Host "[TEST 7] Nexus OS repository structure" -ForegroundColor Yellow
$requiredDirs = @(
    "packaging\aur",
    "scripts",
    "externals\archiso\configs\nexus",
    ".github\workflows"
)

$structureOK = $true
foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path (Get-Location) $dir
    if (Test-Path $dirPath) {
        Write-Host "  PASS: $dir" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $dir (not found)" -ForegroundColor Red
        $structureOK = $false
        $allGood = $false
    }
}
if (-not $structureOK) {
    Write-Host "  ACTION: Run script from Nexus OS root directory" -ForegroundColor Yellow
}
Write-Host ""

# Test 8: Required scripts
Write-Host "[TEST 8] Build scripts" -ForegroundColor Yellow
$scripts = @(
    "scripts/build_aur_local.sh",
    "build_aur.bat",
    "setup_wsl_docker.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path (Get-Location) $script
    if (Test-Path $scriptPath) {
        Write-Host "  PASS: $script" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $script (not found)" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "RESULT: All checks passed! Ready to build." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Cyan
    Write-Host "  build_aur.bat" -ForegroundColor White
} else {
    Write-Host "RESULT: Some checks failed. See above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix the issues above, then run this script again." -ForegroundColor Cyan
}
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
