# Nexus OS Tool Usage & Verification Guide

This guide details how to verify the installation of the "Monster" security toolset and how to build the custom packages.

## 1. Prerequisites (Building Packages)
Before building the ISO, you must build the custom AUR packages.

**On Windows (WSL):**
```powershell
# Run from the repository root
# 1. Setup WSL and Docker if needed
.\setup_wsl_docker.ps1

# 2. Build the packages (Downloads sources and builds .pkg.tar.zst files)
bash scripts/build_aur_local.sh
```

**On Linux:**
```bash
# Ensure you have 'base-devel' installed
sudo pacman -S base-devel

# Build packages
bash scripts/build_aur_local.sh
```

## 2. Verification of Tools

Once installed (or inside the ISO), verify the following tools:

### Metasploit Framework
```bash
# Launch the console (First run may take a moment to initialize DB)
msfconsole -q -x "version; exit"
```
**Expected Output:** `Framework: 6.x.x`

### BeEF (Browser Exploitation Framework)
```bash
# Start BeEF
sudo beef
```
**Expected Output:** Logs indicating BeEF server started at `http://127.0.0.1:3000/ui/panel` and hook URL.

### Bettercap
```bash
bettercap -version
```
**Expected Output:** `bettercap v2.41.5 ...`

### Burp Suite Community
```bash
# Launch (Requires GUI)
burpsuite
```
**Authentication:** You may need to accept terms on first launch.

### Ghidra
```bash
ghidra
```
**Expected Output:** Ghidra splash screen or project manager.

### Nmap
```bash
nmap --version
```

### Aircrack-ng
```bash
aircrack-ng --help
```

## 3. ISO Build Verification
After building the packages, build the ISO:

```bash
# Build ISO (Requires Linux/WSL with loop device support or privileged container)
bash scripts/build_iso.sh
```

To test the ISO in QEMU:
```bash
qemu-system-x86_64 -cdrom output/nexus-os.iso -m 4G -enable-kvm
```
