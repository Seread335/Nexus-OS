# Quick start guide for Windows users (Nexus OS)

## Prerequisites Check

Before starting, verify you have:

1. **Git for Windows** (includes bash)
   - Download: https://git-scm.com/download/win
   - Or: `winget install Git.Git`

2. **Docker Desktop for Windows**
   - Download: https://www.docker.com/products/docker-desktop
   - Or: `winget install Docker.DockerDesktop`
   - After install: Settings > Resources > WSL Integration > Enable Ubuntu/your distro

3. **WSL2 (Windows Subsystem for Linux)**
   - Run (as Admin): `wsl --install`
   - Or install Ubuntu: `wsl --install -d Ubuntu`

## Quick Setup (3 minutes)

### Step 1: Run Setup Script (PowerShell)
```powershell
# Open PowerShell as Administrator, then:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
powershell -ExecutionPolicy Bypass -File setup_wsl_docker.ps1
```

This checks:
- WSL2 is installed and has a distro
- Docker Desktop is running
- Repository structure is correct

### Step 2: Build AUR Packages

**Option A: Use batch script (easiest)**
```cmd
build_aur.bat
```

**Option B: Use bash directly**
```bash
bash scripts/build_aur_local.sh ./build_output
```

This will:
- Download Arch Linux container image (one-time)
- Build all 10+ AUR packages
- Save artifacts to `build_output/packages/`
- Generate logs in `build_output/logs/`

**Expected time:** 20-40 minutes (first run, depends on internet speed)

### Step 3: Check Results
```powershell
# View built packages
dir .\build_output\packages\

# View build logs
type .\build_output\logs\rustscan.log
```

## What Gets Built

By default, these packages are built:
1. rustscan (port scanner)
2. ghidra (reverse engineering)
3. hashcat (password cracker)
4. ophcrack (Windows password cracker)
5. wpscan (WordPress scanner)
6. beef (browser exploitation)
7. bettercap (MITM framework)
8. amass (network reconnaissance)
9. subfinder (subdomain enumeration)
10. metasploit (exploitation framework - placeholder)
11. openvas (vulnerability scanner - placeholder)

## Troubleshooting

### "Docker daemon not running"
- Open Docker Desktop manually
- Or restart: `Restart-Service com.docker.service` (as Admin)

### "bash: command not found"
- Install Git for Windows: https://git-scm.com/download/win
- Or: `winget install Git.Git`

### "Docker daemon connect refused"
- Ensure Docker Desktop is running (check system tray)
- Check WSL2 integration: Docker Desktop > Settings > Resources > WSL Integration

### Build timeout (30 minutes)
- Increase timeout in scripts/build_aur_local.sh (line with `timeout 30m`)
- Or edit .github/workflows/build-rustscan-selfhosted.yml

### Out of disk space
- Docker images + build artifacts can use 10-20 GB
- Check disk: `Get-Volume | Where-Object DriveLetter -eq 'C'`
- Clean up: `docker system prune -a` (removes unused images)

## Next Steps (After Build)

### Option 1: Install Packages in WSL
```bash
# In WSL bash terminal:
sudo pacman -U ./build_output/packages/*.pkg.tar.zst
```

### Option 2: Test ISO Build (advanced)
Requires Arch Linux in WSL or Linux VM:
```bash
# In WSL (Arch):
sudo pacman -S archiso
bash scripts/build_iso.sh ./iso_output
```

Then test with QEMU:
```bash
qemu-system-x86_64 -cdrom ./iso_output/nexus-*.iso -m 2048 -smp 2
```

### Option 3: Set Up Self-Hosted Runner
For automated builds on GitHub:
- Register a Linux machine as self-hosted runner
- Run: `bash scripts/setup_selfhosted_runner_linux.sh <TOKEN> <NAME> <REPO_URL>`
- Builds run automatically on push

## Common Commands

```bash
# View build status
tail -f ./build_output/logs/rustscan.log

# View all logs
ls -la ./build_output/logs/

# Clean up Docker (frees 5-10 GB)
docker system prune -a --volumes

# Clean build artifacts
rm -rf ./build_output/packages/*
```

## More Help

- Project status: `cat docs/PROJECT_STATUS.md`
- Architecture: `cat docs/architecture.md`
- ISO building: `cat docs/iso_build.md`
- Roadmap: `cat docs/ROADMAP.md`

---

Questions? Check the repo: https://github.com/Seread335/Nexus-OS
