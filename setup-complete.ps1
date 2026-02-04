#!/usr/bin/env powershell
# Nexus OS Complete Setup - Auto-detect, auto-install, auto-configure
# Run once as Administrator, then just use build_aur.bat

param(
    [switch]$NoInstall = $false,
    [switch]$SkipWSL = $false
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Write-Status { param([string]$msg, [string]$level = "INFO")
    $colors = @{
        "PASS" = "Green"
        "FAIL" = "Red"
        "WARN" = "Yellow"
        "INFO" = "Cyan"
        "ACTION" = "Magenta"
    }
    Write-Host "[$level] $msg" -ForegroundColor $colors[$level]
}

function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    return $isAdmin
}

# MAIN SETUP
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Nexus OS - Complete Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check Admin
if (-not (Test-Admin)) {
    Write-Status "This script must run as Administrator!" "FAIL"
    Write-Status "Right-click PowerShell → Run as Administrator, then re-run this script" "ACTION"
    pause
    exit 1
}

Write-Status "Running as Administrator" "PASS"
Write-Host ""

# Phase 1: Check requirements
Write-Host "[PHASE 1] Checking requirements..." -ForegroundColor Yellow
Write-Host ""

$checks = @{
    "Git Bash" = {
        if (Get-Command bash -ErrorAction SilentlyContinue) {
            Write-Status "Git Bash found" "PASS"
            return $true
        }
        return $false
    }
    "Docker" = {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            try {
                $ver = docker --version 2>&1
                Write-Status "Docker found: $ver" "PASS"
                return $true
            } catch {
                Write-Status "Docker found but not running" "WARN"
                return $false
            }
        }
        return $false
    }
}

$missing = @()
foreach ($check in $checks.Keys) {
    if (-not (& $checks[$check])) {
        $missing += $check
    }
}

Write-Host ""

# Phase 2: Install missing components
if ($missing.Count -gt 0 -and -not $NoInstall) {
    Write-Host "[PHASE 2] Installing missing components..." -ForegroundColor Yellow
    
    if ($missing -contains "Git Bash") {
        Write-Status "Installing Git for Windows..." "ACTION"
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install Git.Git -e --silent
            Write-Status "Git installed via winget" "PASS"
        } else {
            Write-Status "Please install Git manually: https://git-scm.com/download/win" "WARN"
        }
    }
    
    if ($missing -contains "Docker") {
        Write-Status "Please install Docker Desktop manually: https://docker.com/products/docker-desktop" "WARN"
        Write-Status "After installation, re-run this script" "ACTION"
        pause
        exit 1
    }
    
    Write-Host ""
}

# Phase 3: Docker daemon check + start
Write-Host "[PHASE 3] Ensuring Docker is running..." -ForegroundColor Yellow
try {
    $psOutput = docker ps 2>&1
    Write-Status "Docker daemon running" "PASS"
} catch {
    Write-Status "Docker daemon not responding, attempting to start..." "WARN"
    try {
        Start-Service com.docker.service -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $psOutput = docker ps 2>&1
        Write-Status "Docker started" "PASS"
    } catch {
        Write-Status "Could not start Docker. Please start Docker Desktop manually." "FAIL"
        Write-Status "Then re-run this script" "ACTION"
        pause
        exit 1
    }
}
Write-Host ""

# Phase 4: Pull Docker image
Write-Host "[PHASE 4] Preparing Docker image..." -ForegroundColor Yellow
try {
    $images = docker images --format "{{.Repository}}" | Select-String "archlinux"
    if ($images) {
        Write-Status "archlinux image already cached" "PASS"
    } else {
        Write-Status "Downloading archlinux Docker image (~500MB, may take 2-5 min)..." "ACTION"
        docker pull archlinux:latest
        if ($?) {
            Write-Status "archlinux image downloaded" "PASS"
        }
    }
} catch {
    Write-Status "Could not prepare Docker image: $_" "WARN"
}
Write-Host ""

# Phase 5: WSL2 (optional but recommended)
if (-not $SkipWSL) {
    Write-Host "[PHASE 5] Checking WSL2..." -ForegroundColor Yellow
    try {
        $wslOutput = wsl --list --verbose 2>&1
        if ($wslOutput -match "Ubuntu|Arch") {
            Write-Status "WSL2 distro found" "PASS"
        } else {
            Write-Status "No WSL2 distro found. WSL2 is optional but recommended." "WARN"
            $response = Read-Host "Install Ubuntu via WSL2? (y/n) [n]"
            if ($response -eq "y") {
                Write-Status "Installing Ubuntu (requires restart)..." "ACTION"
                wsl --install -d Ubuntu
                Write-Status "Restart Windows to complete WSL2 setup, then re-run this script" "ACTION"
                pause
                exit 0
            }
        }
    } catch {
        Write-Status "WSL2 check failed (optional, can proceed without)" "WARN"
    }
    Write-Host ""
}

# Phase 6: Repository structure
Write-Host "[PHASE 6] Validating repository..." -ForegroundColor Yellow
$requiredPaths = @(
    "packaging\aur",
    "scripts\build_aur_local.sh",
    "build_aur.bat",
    "externals\archiso\configs\nexus"
)

$repoOK = $true
foreach ($path in $requiredPaths) {
    if (Test-Path $path) {
        Write-Status "Found: $path" "PASS"
    } else {
        Write-Status "Missing: $path" "FAIL"
        $repoOK = $false
    }
}

if (-not $repoOK) {
    Write-Status "Please run this script from Nexus OS root directory" "ACTION"
    pause
    exit 1
}
Write-Host ""

# Phase 7: Create config file for future runs
Write-Host "[PHASE 7] Saving configuration..." -ForegroundColor Yellow
$configDir = "$(Get-Location)\.nexus"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force > $null
}

$configFile = "$configDir\setup.config"
$config = @{
    "setup_date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "docker_ready" = $true
    "bash_path" = (Get-Command bash -ErrorAction SilentlyContinue).Source
    "docker_path" = (Get-Command docker -ErrorAction SilentlyContinue).Source
    "wsl_installed" = $null -ne (wsl --list --verbose 2>&1 | Select-String "Ubuntu|Arch")
}

$config | ConvertTo-Json | Set-Content $configFile
Write-Status "Configuration saved to .nexus/setup.config" "PASS"
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You are now ready to build packages!" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Build AUR packages" -ForegroundColor Cyan
Write-Host "  build_aur.bat" -ForegroundColor White
Write-Host ""
Write-Host "Or use bash directly:" -ForegroundColor Cyan
Write-Host "  bash scripts/build_aur_local.sh ./build_output" -ForegroundColor White
Write-Host ""
Write-Host "Packages will be created in: .\build_output\packages\" -ForegroundColor Cyan
Write-Host ""
Write-Host "For future runs, just execute build_aur.bat" -ForegroundColor Green
Write-Host "No need to re-run setup unless something breaks!" -ForegroundColor Green
Write-Host ""
