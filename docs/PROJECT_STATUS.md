# Nexus OS - Project Status Report (February 4, 2026)

## Executive Summary

Nexus OS is an Arch Linux-based pentesting/security distribution under active development. The project has completed foundational scaffolding, packaging infrastructure, and CI/CD setup. Currently features 10+ AUR packages, build automation scripts, and preparation for ISO generation.

---

## Project Structure

```
Nexus OS/
├── externals/
│   └── archiso/                    # Cloned ArchISO (Arch ISO build tools)
├── configs/
│   └── nexus/                      # ArchISO profile for Nexus
│       ├── profiledef.sh           # Profile configuration
│       ├── packages.x86_64         # Generated final package list (169 packages)
│       ├── packages.base           # Base system packages
│       ├── packages.system         # System utilities
│       ├── packages.networking     # Network tools
│       ├── packages.container      # Docker/container tools
│       ├── packages.desktop        # Desktop environment (optional)
│       ├── packages.dev            # Development tools
│       ├── packages.virt           # Virtualization tools
│       ├── packages.pentest        # Penetration testing tools (extensive)
│       └── airootfs/               # ISO root filesystem overlay
│           ├── etc/
│           │   ├── systemd/system/cerberus.service
│           │   └── cerberus/config.yaml
│           └── customize_airootfs.sh
├── packaging/
│   ├── AUR_PACKAGES.md             # List of AUR packages
│   └── aur/                        # PKGBUILD files
│       ├── rustscan/
│       ├── ghidra/
│       ├── hashcat/
│       ├── ophcrack/
│       ├── wpscan/
│       ├── beef/
│       ├── bettercap/
│       ├── amass/
│       ├── subfinder/
│       ├── metasploit/
│       └── openvas/
├── scripts/
│   ├── build_iso.sh                # Build Nexus OS ISO
│   ├── build_aur_local.sh          # Local Docker-based AUR builder
│   ├── setup_selfhosted_runner_linux.sh # GitHub Actions runner setup
│   ├── docker_build_rustscan.sh    # Containerized RustScan build
│   └── generate_packages_list.sh   # Assemble packages.x86_64
├── .github/
│   └── workflows/
│       ├── build-rustscan-selfhosted.yml  # CI for AUR packages
│       └── build-aur-selfhosted.yml       # (alternate/reference)
├── docs/
│   ├── ROADMAP.md                  # Project milestones and tasks
│   ├── architecture.md             # Technical architecture
│   ├── design_decisions.md         # Design rationale
│   ├── iso_build.md                # ISO building documentation
│   └── self-hosted-runner.md       # Self-hosted runner setup
├── src/
│   ├── cli/                        # Python CLI skeleton
│   ├── cerberus/                   # Cerberus agent skeleton
│   └── ...
├── tests/
│   └── (test suite, minimal)
├── README.md
├── pyproject.toml                  # Python project config
├── requirements.txt                # Python dependencies
├── LICENSE
├── Dockerfile
└── Tài liệu thiết kế.md            # Original Vietnamese design document
```

---

## Completed Deliverables

### 1. Project Scaffolding
- Full directory structure created
- README, LICENSE, pyproject.toml, requirements.txt
- Python CLI skeleton (nexus_recon.py)
- Cerberus agent skeleton (cerberus.py)

### 2. ArchISO Profile (configs/nexus/)
- profiledef.sh: Profile metadata
- packages.x86_64: Final package list (169 packages total)
- Per-category package files: base, system, networking, container, desktop, dev, virt, pentest
- airootfs/: ISO root filesystem overlay with cerberus service and config
- customize_airootfs.sh: ISO post-install script

### 3. Package Infrastructure
**10 PKGBUILD Files Created:**
1. RustScan (rustscan): Port scanner, binary-first with source fallback
2. Ghidra (ghidra): Reverse engineering framework, binary distribution to /opt
3. Hashcat (hashcat): GPU password cracker, .7z binary extraction
4. Ophcrack (ophcrack): Windows password cracker, binary-first
5. WPScan (wpscan): WordPress scanner, Ruby-based
6. BeEF (beef): Browser exploitation framework, Ruby-based
7. Bettercap (bettercap): MITM attack framework, binary release
8. Amass (amass): Network reconnaissance, Go binary
9. Subfinder (subfinder): Subdomain enumeration, Go binary
10. Metasploit (metasploit): Exploitation framework, placeholder with setup notes
11. OpenVAS (openvas): Vulnerability scanner, detailed split-component skeleton

**Package Features:**
- Binary-first approach (avoid recompilation)
- Wrapper scripts in /usr/bin
- Installation to /opt for heavy tools
- Fallback to source build where needed
- Proper dependency declarations

### 4. CI/CD Infrastructure
**GitHub Actions Workflow (build-rustscan-selfhosted.yml):**
- Trigger: push to packaging/aur/**
- Runs on self-hosted Linux runner with Docker
- Features:
  * Docker image caching (pull archlinux:latest once)
  * Pacman package cache mount (~/.cache/pacman/pkg) for speed
  * Parallel builds (max-parallel: 4)
  * Build timeout: 30 minutes per package
  * Smoke tests (package-specific: --version, file checks, etc.)
  * Artifact cleanup (keep last 3 builds)
  * Upload to Actions artifacts

**Package-Specific Smoke Tests:**
- RustScan: --version
- Hashcat: --version + /opt/hashcat-* directory presence
- Ophcrack: --help + /opt/ophcrack-* directory presence
- Ghidra: /opt/ghidra-* and /usr/bin/ghidra wrapper checks
- OpenVAS: docs file presence
- Generic fallback: --version or simple execution test

### 5. Build Automation Scripts

**a) scripts/build_aur_local.sh**
- Local Docker-based builder for all AUR packages
- No need for self-hosted runner
- Features:
  * Caches dependencies
  * Handles binary artifacts (local fallback)
  * Summary report (success/failed counts)
  * Logs per package
  * Installation instructions
- Usage: `bash scripts/build_aur_local.sh ./build_output`

**b) scripts/build_iso.sh**
- Build Nexus OS ISO using ArchISO profile
- Validates profile structure
- Output summary with ISO size
- QEMU and USB write instructions
- Requires: archiso package, sudo access
- Usage: `bash scripts/build_iso.sh ./iso_output`

**c) scripts/setup_selfhosted_runner_linux.sh**
- Full GitHub Actions runner installation
- Creates ghrunner user/group
- Downloads latest runner release
- Installs dependencies (curl, git, openssl, etc.)
- Configures systemd service (auto-start)
- Usage: `bash scripts/setup_selfhosted_runner_linux.sh <TOKEN> <NAME> <REPO_URL>`

**d) scripts/docker_build_rustscan.sh**
- Containerized Rust build for RustScan
- Uses rust:latest image
- Installs build tools, clones repo, builds via cargo
- Output to /workspace/build_artifacts/

**e) scripts/generate_packages_list.sh**
- Concatenates all package group files (*.base, *.pentest, etc.)
- Generates final packages.x86_64 for ArchISO

### 6. Documentation
- docs/ROADMAP.md: Detailed project milestones
- docs/architecture.md: Technical architecture
- docs/design_decisions.md: Design rationale
- docs/iso_build.md: ISO building guide
- docs/self-hosted-runner.md: Runner setup instructions
- README.md: Project overview

### 7. Git Repository
- Local repo initialized, branch: bootstrap-packaging
- Pushed to: https://github.com/Seread335/Nexus-OS.git
- Commits: ~15+ with clear messages
- Branch tracking: origin/bootstrap-packaging up-to-date

---

## Package Coverage

### Total Packages: 169

**Breakdown by Category:**
- base: ~25 packages (linux, grub, systemd, etc.)
- system: ~20 packages (utilities, file managers, shells)
- networking: ~15 packages (ssh, curl, wget, net-tools, etc.)
- container: ~10 packages (docker, podman, systemd-nspawn)
- desktop: ~5 packages (optional: xfce4, sway, wayland, etc.)
- dev: ~30 packages (gcc, python, rust, nodejs, git, etc.)
- virt: ~5 packages (qemu, libvirt, virt-manager)
- pentest: ~60+ packages (nmap, metasploit-framework, aircrack-ng, etc.)
- AUR: 10-11 specialized packages (rustscan, ghidra, etc.)

### Key Pentest Tools Included
- Network scanning: nmap, masscan, zmap, rustscan, netdiscover, arp-scan
- Web apps: gobuster, dirb, nikto, wpscan, burpsuite, sqlmap, wfuzz, ffuf
- Exploitation: metasploit, beef, msfpc
- Password cracking: hydra, john, hashcat, ophcrack
- Wireless: aircrack-ng, reaver, wash
- MITM: ettercap, mitmproxy, sslstrip, bettercap, responder
- Recon: theharvester, recon-ng, amass, subfinder, waybackurls
- Reverse engineering: radare2, ghidra, binwalk, pwntools
- Forensics: sleuthkit, autopsy, bulk_extractor, foremost
- Containers: docker, podman for vulnerable labs

---

## Current Limitations & Notes

### 1. GitHub Actions Cloud Runner
- BLOCKED: Account billing lock prevents cloud CI runs
- SOLUTION: Use self-hosted runner on Linux machine instead

### 2. Build Environment
- Requires Linux (Arch-based preferred) for:
  * ISO building (mkarchiso)
  * Docker-based local builds
  * Self-hosted runner registration
- Windows users: Use WSL2 (Ubuntu/Arch in WSL) or Linux VM

### 3. AUR Package Status
- RustScan: Binary build tested, working release artifact
- Ghidra: PKGBUILD ready, requires .zip download
- Hashcat: PKGBUILD ready, requires .7z download
- Others: PKGBUILD ready, need testing
- Metasploit & OpenVAS: Placeholder PKGBUILDs (need more work)

### 4. ArchISO Profile
- Tested structure but not yet built into ISO (requires Linux + archiso)
- Packages.x86_64 generated successfully (169 packages)
- Customize script ready for post-install tasks

---

## How to Use (from Windows with WSL)

### Prerequisites
1. Windows 10/11 with WSL2 enabled
2. Ubuntu 22.04+ or Arch Linux in WSL
3. Git, Docker, and basic development tools

### Step 1: Set Up WSL Environment
```bash
# In WSL terminal (Ubuntu)
sudo apt-get update
sudo apt-get install -y git build-essential curl wget
# For Docker:
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
# For ArchISO (if Ubuntu):
# May need to install archiso differently or use Docker alternatives
```

### Step 2: Clone Repository (or use existing)
```bash
cd /mnt/d/  # Access Windows D: drive from WSL
cd "Nexus OS"
git status
```

### Step 3: Build AUR Packages Locally
```bash
# Requires Docker in WSL
bash scripts/build_aur_local.sh ./build_output

# Check results
ls -lah ./build_output/packages/
cat ./build_output/logs/*.log  # View build logs
```

### Step 4: Build ISO (on WSL or Linux machine)
```bash
# First, ensure archiso is installed
# On Arch WSL:
sudo pacman -S archiso

# On Ubuntu WSL: may need to compile or use Docker
# Build ISO:
bash scripts/build_iso.sh ./iso_output

# Output: iso_output/nexus-*.iso
```

### Step 5: Test ISO
```bash
# Option A: Test in QEMU (if installed)
qemu-system-x86_64 -cdrom ./iso_output/nexus-*.iso -m 2048 -smp 2

# Option B: Write to USB (on Linux directly)
lsblk  # Identify USB device
sudo dd if=./iso_output/nexus-*.iso of=/dev/sdX bs=4M conv=fsync
```

### Step 6: Set Up Self-Hosted Runner (optional, for CI)
```bash
# On a Linux machine (not WSL):
bash scripts/setup_selfhosted_runner_linux.sh <GITHUB_TOKEN> "my-runner" "https://github.com/Seread335/Nexus-OS"

# Check runner status:
sudo systemctl status actions-runner
sudo journalctl -u actions-runner -f
```

---

## Architecture & Design

### Cerberus Agent
- Lightweight monitoring/reconnaissance agent
- Skeleton in src/cerberus/cerberus.py
- Systemd service: etc/systemd/system/cerberus.service
- Config: etc/cerberus/config.yaml

### CLI Tool
- Python-based (src/cli/nexus_recon.py)
- Wrapper around various pentest tools
- Future: Integration with Nmap, Masscan, RustScan + LLM-based reporting

### Package Management Strategy
- Binary-first approach: prefer prebuilt releases
- Fallback to source build if binary unavailable
- Minimize compilation time (ISO build speed)
- Support for local artifacts (CI-friendly)

### CI/CD Strategy
- Cloud CI blocked (GitHub billing)
- Self-hosted runner on Linux machine (persistent)
- Local Docker builds for development (no runner needed)
- Artifact caching (pacman packages, Docker images)

---

## Roadmap & Next Steps

### Immediate (Week 1-2)
1. [ ] Set up and register self-hosted runner on Linux machine
2. [ ] Test first workflow run (build all AUR packages)
3. [ ] Debug and fix any package build failures
4. [ ] Smoke test all built packages

### Short Term (Week 2-4)
1. [ ] Complete MetaSploit and OpenVAS PKGBUILDs
2. [ ] Build and test Nexus OS ISO (requires Linux + archiso)
3. [ ] Document ISO testing and deployment
4. [ ] Add more tools as needed (based on pentest requirements)

### Medium Term (Month 2)
1. [ ] Implement full Cerberus agent
2. [ ] Create CLI tool for automated scanning/reporting
3. [ ] Add LLM integration (local model or API)
4. [ ] Set up internal package repository (optional)

### Long Term (Month 3+)
1. [ ] Security hardening of ISO
2. [ ] Custom kernel configurations (if needed)
3. [ ] Automated ISO releases (monthly/quarterly)
4. [ ] Community feedback and contributions
5. [ ] Documentation and user guides

---

## Git Commit History (Current Session)

Latest commits on bootstrap-packaging branch:

1. "ci(workflow): add docker image caching, pacman cache mount, build timeout, artifact cleanup"
2. "packaging: add amass, subfinder, metasploit PKGBUILDs; scripts: add local Docker-based build"
3. "packaging: add wpscan, beef, bettercap PKGBUILDs; scripts: improve self-hosted runner setup"
4. "ci(self-hosted): add smoke-tests for built packages; packaging(ophcrack): add binary-first PKGBUILD"
5. "packaging(hashcat): binary-first PKGBUILD"
6. "packaging(ghidra): install into /opt, add wrapper; ci(self-hosted): build all packaging/aur packages"
... and more

Full history: https://github.com/Seread335/Nexus-OS/commits/bootstrap-packaging

---

## Troubleshooting Guide

### Problem: "Docker is required but not found"
**Solution:**
- Install Docker: `sudo apt-get install docker.io` (Ubuntu) or `sudo pacman -S docker` (Arch)
- Add user to docker group: `sudo usermod -aG docker $USER` then logout/login
- Start Docker daemon: `sudo systemctl start docker`

### Problem: "makepkg: command not found"
**Solution:**
- Install archiso/base-devel: `sudo pacman -S archiso base-devel`
- Or run builds inside Docker (scripts/build_aur_local.sh)

### Problem: "mkarchiso not found when building ISO"
**Solution:**
- Install archiso: `sudo pacman -S archiso`
- For Ubuntu WSL: use Docker to run mkarchiso inside ArchLinux container
- Or build on native Arch Linux machine

### Problem: GitHub Actions runner fails with "unrecognized option"
**Solution:**
- Check runner version compatibility
- Reinstall runner: `bash setup_selfhosted_runner_linux.sh ... <new_token>`
- Check runner logs: `journalctl -u actions-runner -n 50 -e`

### Problem: Package build timeout (30 minutes exceeded)
**Solution:**
- Increase timeout in workflow (edit build-rustscan-selfhosted.yml: timeout 30m -> timeout 60m)
- Or pre-build and cache heavy dependencies
- Split large packages (e.g., Metasploit) into multiple smaller packages

### Problem: "Permission denied" when running scripts
**Solution:**
- Make script executable: `chmod +x scripts/build_iso.sh`
- Use bash explicitly: `bash scripts/build_iso.sh` instead of `./scripts/build_iso.sh`

### Problem: WSL pacman mirrors are slow/timing out
**Solution:**
- Edit /etc/pacman.d/mirrorlist to use faster mirrors
- Or use Docker with specific Arch mirror: `docker run archlinux:latest pacman -S ...`
- Pre-cache packages on host and mount volume

---

## Key Technologies & Tools

- **Base OS**: Arch Linux
- **ISO Building**: ArchISO (official Arch tool)
- **Package Management**: Pacman, AUR, PKGBUILD
- **CI/CD**: GitHub Actions (self-hosted runner)
- **Containerization**: Docker
- **Build Automation**: Bash scripts
- **Version Control**: Git, GitHub
- **Pentest Tools**: 60+ packages (see package list above)
- **Programming Languages**: Python (CLI/agent), Rust (RustScan), Ruby (WPScan/BeEF), Go (Amass/Subfinder)

---

## Contact & Repository

- **Repository**: https://github.com/Seread335/Nexus-OS
- **Branch**: bootstrap-packaging (active development)
- **Main Branch**: main (future release branch)
- **License**: (check LICENSE file in repo)

---

## Summary Statistics

- Total Lines of Code: ~5000+ (scripts, configs, docs, PKGBUILDs)
- PKGBUILD Files: 11
- Bash Scripts: 5+ (build, setup, generate)
- CI/CD Workflows: 2+
- Documentation Files: 10+
- Git Commits: 15+ (this session)
- Packages in Profile: 169
- Pentest Tools: 60+
- Estimated ISO Size: ~800MB - 1.5GB (including all tools)

---

## Final Notes

This document captures the state of Nexus OS as of February 4, 2026. The project is at the "packaging & CI foundation" stage. All build infrastructure is in place; the next critical step is to set up a self-hosted runner on a Linux machine and conduct the first end-to-end ISO build and test.

For Windows users, WSL2 (Windows Subsystem for Linux) provides a convenient development environment. However, full ISO building and runner setup work best on native Linux.

Updates to this document should be made as project milestones are completed.
