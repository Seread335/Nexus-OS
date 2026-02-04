# Nexus OS — Roadmap & Task List (Aegis)

**Mục tiêu:** Dẫn dắt dự án từ prototype -> production-ready live ISO (Arch-based) với AI-local, hardened kernel, secure-boot, và toolset pentest hợp lý.

---

## Tổng quan mốc chính (Milestones) ✅
1. M0 — **Thiết lập repo & infra cơ bản** (this week)
2. M1 — **Profile ArchISO `configs/nexus`** (2–3 weeks)
3. M2 — **Tooling core: `nexus-recon` + `cerberus` agent** (4–8 weeks)
4. M3 — **AI setup: model manager + quantization pipeline** (3–6 weeks)
5. M4 — **Packaging & repo: pacman repo + deb/overlay** (2–4 weeks)
6. M5 — **Secure Boot, Signing & OTA/atomic updates** (3–6 weeks)
7. M6 — **Testing: CI, QA, Security Audit, HW tests** (4–8 weeks)
8. M7 — **Release v0.1 (ISO + docs + basic LLM)** (target date TBD)
9. M8 — **Hardening / Post-quantum VPN / Advanced features** (ongoing)

---

## Chi tiết công việc theo mốc

### M0 — Thiết lập repo & infra cơ bản ✅
- [ ] Chuẩn hóa structure (docs/, externals/archiso, infra/, packaging/, scripts/, models/)
- [ ] Thêm `ROADMAP.md`, contributing, code of conduct, license
- [ ] CI cơ bản: lint + pytest + model smoke tests
- Owner: @maintainer, Est: 3–5 ngày
- Success: repo có CI passing, archiso cloned, directory conventions documented

### M1 — Tạo `configs/nexus` cho ArchISO 🔧
- [ ] Tạo profile skeleton: packages.x86_64, ai-overlay, hooks, mkinitcpio config
- [ ] Package list cơ bản (base, linux-hardened, systemd-boot, btrfs, lvm, luks2, wireguard, podman, nmap, wireshark, kde, sway opt-in)
- [ ] Overlay: default polkit, systemd units (cerberus.service), dotfiles
- [ ] `scripts/build_iso.sh` (wrapper, cleans chroot/cache, builds iso, validates)
- [ ] Test build minimal ISO in QEMU/VM
- Owner: @iso-team, Est: 2 weeks
- Success: Có ISO booted trong VM, packages cài đúng, overlay applied

### M2 — Core Tools Development (nexus-recon, cerberus) 🛠️
- `nexus-recon`:
  - [ ] Scan wrappers (nmap, masscan, rustscan) + parsing
  - [ ] Report generator (markdown/pdf), CVSS scoring, export
  - [ ] CLI + tests + simple AI-prompt integration (local model client)
- `cerberus` agent:
  - [ ] Falco/eBPF integration skeleton, local rules runtime
  - [ ] ML anomaly hook (ONNX runtime inference example)
  - [ ] Service, config, logs, health endpoint
- Owner: @tools-team, Est: 4–8 weeks
- Success: unit tests, integration in ISO as systemd service, basic e2e smoke test

### M3 — AI Model Strategy & Tools 🤖
- [ ] `models/` layout: `active/`, `archives/`, `scripts/` (manager)
- [ ] Implement quantization pipeline (gguf / GPTQ / llama.cpp convert scripts)
- [ ] Model selection policy (small local + remote large hybrid), LoRA support
- [ ] Scripts: download, convert, list, switch, cleanup (auto-archive older models)
- [ ] CI: sanity inference tests (token gen, small prompt test) to avoid broken models
- Owner: @ai-team, Est: 3–6 weeks
- Success: Able to switch model quickly, quantized model running locally under resource limits

### M4 — Packaging & Repo 🔁
- [ ] Setup internal pacman repo (signed packages) and optional deb overlay
- [ ] Create PKGBUILDs for core tools and cerberus
- [ ] Implement unattended-upgrades + atomic update tests (if using rpm-ostree style, adapt)
- Owner: @release-team, Est: 2–4 weeks
- Success: Packages build reproducibly and land in a test repo; ISO uses repo

### M5 — Secure Boot & Signing 🔐
- [ ] Key generation & test signing flow for kernel and bootloader
- [ ] systemd-boot integration + docs for enrolling keys
- [ ] Module signing policy & scripts
- Owner: @sec-team, Est: 3–6 weeks
- Success: ISO can boot with Secure Boot enabled on test hardware after enrolling keys

### M6 — Testing, QA, & Security Audit 🔎
- [ ] Automated CI tests: unit, integration, model inference smoke, packer/ISO build smoke
- [ ] Fuzz/Regression testing for recon tools (rate-limited, safe mode)
- [ ] In-house security review + 3rd party audit scope
- [ ] HW test matrix (x86_64 bare metal, ARM64 RPi5 image, RISC-V experimental if available)
- Owner: @qa-team, Est: 4–8 weeks
- Success: Passing CI, documented audit findings remediated before release

### M7 — Release & Docs 📦
- [ ] Release artifacts: signed ISO, checksums, test images
- [ ] Complete docs: install guide, dev docs, model management, secure boot guide
- [ ] Release checklist & press/announcement
- Owner: @release-team + @docs, Est: 1–2 weeks
- Success: Public release asset + docs; release tag + release notes

### M8 — Post-release / Advanced Features 🚀
- [ ] Post-quantum WireGuard hybrid proof-of-concept
- [ ] Identity cloaking improvements, browser sandboxes, honeypot automation
- [ ] Expanded hardware support & official ARM images
- Owner: Ongoing

---

## Các công việc song song / hành chính
- Security & License review (FOSS compliance)
- CI infrastructure for model artifacts (artifacts retention policy)
- Disk/Storage policy for local LLMs (quota + cleanup scripts)
- Community / contribution guidelines, issue templates

---

## Acceptance criteria chung
- ISO boots on VM + baremetal x86_64
- core tools (nexus-recon, cerberus) có tests và pass CI
- local LLM small model runs under target resource thresholds (e.g., <16GB RAM, <80GB disk)
- Secure Boot signed + tested
- Packaging reproducible + signed

---

## Next immediate actions (this sprint)
1. Create `configs/nexus` minimal profile in `externals/archiso` and add initial package list. (Owner: @iso-team)
2. Commit `docs/ROADMAP.md`, add issues for each major task and assign owners.
3. Add model manager skeleton (`scripts/model_manager.py`) and storage folders.

---

*Ghi chú:* Các ước lượng thời gian là tham khảo; điều chỉnh theo nhân lực và mức ưu tiên. Luôn kiểm tra disk & model storage trước khi tải model lớn.
