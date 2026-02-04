#!/usr/bin/env powershell
# Setup WSL2 with Docker Desktop for Nexus OS development
# Run as Administrator
# Usage: powershell -ExecutionPolicy Bypass -File setup_wsl_docker.ps1

param(
    [switch]$SkipDocker = $false,
    [switch]$SkipWSL = $false
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Nexus OS - WSL2 + Docker Setup (Windows)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must run as Administrator!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

# Step 1: Check WSL installation
if (-not $SkipWSL) {
    Write-Host "[1/4] Checking WSL2..." -ForegroundColor Yellow
    $wslStatus = wsl --list --verbose 2>&1
    if ($wslStatus -like "*No installed distributions*") {
        Write-Host "WARNING: WSL2 not fully set up. Install a distribution:" -ForegroundColor Yellow
        Write-Host "  1. Microsoft Store -> Ubuntu 22.04 LTS (or Arch Linux)"
        Write-Host "  2. Or run: wsl --install -d Ubuntu"
        Write-Host "  3. Then restart this script"
        pause
    } else {
        Write-Host "WSL2 is set up. Distributions:" -ForegroundColor Green
        wsl --list --verbose
    }
} else {
    Write-Host "[1/4] Skipping WSL2 check" -ForegroundColor Gray
}

Write-Host ""

# Step 2: Check Docker Desktop
if (-not $SkipDocker) {
    Write-Host "[2/4] Checking Docker Desktop..." -ForegroundColor Yellow
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "Docker is installed:" -ForegroundColor Green
        docker --version
        
        # Try to start Docker if not running
        if (-not (docker ps -ErrorAction SilentlyContinue)) {
            Write-Host "Docker daemon not running. Starting..." -ForegroundColor Yellow
            Start-Service com.docker.service -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }
    } else {
        Write-Host "Docker Desktop not found. Please install:" -ForegroundColor Red
        Write-Host "  https://www.docker.com/products/docker-desktop"
        Write-Host "  After installation, restart this script."
        pause
        exit 1
    }
} else {
    Write-Host "[2/4] Skipping Docker check" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Verify Docker + WSL integration
Write-Host "[3/4] Verifying Docker and WSL integration..." -ForegroundColor Yellow
try {
    $dockerWsl = docker run --rm alpine:latest echo "Docker+WSL integration OK" 2>&1
    if ($dockerWsl -like "*OK*") {
        Write-Host "Docker+WSL integration: OK" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Docker test failed. Check Docker Desktop settings." -ForegroundColor Yellow
    Write-Host "  Settings > Resources > WSL Integration > Enable Ubuntu"
}

Write-Host ""

# Step 4: Verify repository
Write-Host "[4/4] Checking Nexus OS repository..." -ForegroundColor Yellow
if (Test-Path ".\packaging\aur" -PathType Container) {
    Write-Host "Repository structure found:" -ForegroundColor Green
    Get-ChildItem ".\packaging\aur" -Directory | ForEach-Object { Write-Host "  - $($_.Name)" }
} else {
    Write-Host "ERROR: Nexus OS repo structure not found!" -ForegroundColor Red
    Write-Host "Please run this script from the Nexus OS root directory."
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Build AUR packages:"
Write-Host "     bash scripts/build_aur_local.sh .\build_output"
Write-Host ""
Write-Host "  2. Check results:"
Write-Host "     dir build_output\packages"
Write-Host ""
Write-Host "  3. View build logs:"
Write-Host "     Get-Content build_output\logs\*.log"
Write-Host ""
