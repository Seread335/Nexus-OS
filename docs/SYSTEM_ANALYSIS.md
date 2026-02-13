# Nexus OS — Phân Tích Kỹ Thuật Hệ Thống

Tài liệu phân tích kiến trúc, trạng thái milestone, điểm mạnh/yếu, bảo mật và khuyến cáo. Cập nhật theo codebase hiện tại.

---

## 1. Kiến trúc hệ thống (6 lớp)

### Lớp 1: Hardware & Boot
- **Nền tảng:** x86_64 (chính), ARM64/RISC-V (roadmap).
- **Boot:** ArchISO (syslinux + systemd-boot), UEFI/BIOS. Secure Boot (M5).
- **Kernel:** linux-hardened trong profile; optional PREEMPT_RT (thiết kế).

### Lớp 2: Base OS & Package
- **Distro:** Arch Linux rolling.
- **Repo:** [core], [extra], [blackarch] (mirror Team Cymru). Optional [nexus-core] (local repo từ `create_repo.sh`).
- **Gói:** packages.base, .system, .networking, .container, .dev, .ai, .virt, .desktop, .pentest, .blackarch → `generate_packages_list.sh` → `packages.x86_64` (~230+ dòng, đã dedup).

### Lớp 3: Build & CI
- **ArchISO profile:** `externals/archiso/configs/nexus/` (profiledef.sh, pacman.conf, airootfs, efiboot, grub, syslinux).
- **Build ISO:** `scripts/build_iso.sh` → copy `src/` vào airootfs/opt/nexus/src → `mkarchiso`.
- **Build AUR:** `scripts/build_aur_local.sh` (Docker archlinux), CI: `.github/workflows/build-rustscan-selfhosted.yml` (self-hosted runner).
- **Repo local:** `scripts/create_repo.sh` → nexus-core.db, snippet pacman.d.

### Lớp 4: AI & Security Agent
- **Cerberus:** Python daemon (systemd, User=root). Bind **127.0.0.1:9380** only.
  - **GET /health:** status, onnx_loaded, deep_access.
  - **GET /api/context:** snapshot hệ thống (ps, ss, ip, journalctl, file theo ai_policy read_paths).
  - **POST /api/ask:** body `{ "prompt", "include_context" }` → prepend system_prompt + optional context → gọi Ollama `/api/generate` → trả response. Mọi request ghi **audit** (ai_audit.log).
- **Policy:** `/etc/cerberus/config.yaml`, `/etc/cerberus/ai_policy.yaml` (read_paths, read_exclude, allowed_commands, max_context_bytes, audit_log_path).
- **Ollama:** LLM local (phi3:mini mặc định); cấu hình base_url, model, system_prompt trong config.

### Lớp 5: CLI & Tooling
- **nexus-recon:** `scan <target> [--aggressive] [--ai-report] [--use-cerberus]`. Chạy nmap, tùy chọn gửi output cho Ollama hoặc Cerberus (full context) để tóm tắt.
- **model_manager.py:** ollama-list, ollama-pull, local-list, switch, cleanup.
- **50 BlackArch tools:** cài sẵn qua packages.blackarch (recon, scan, web, exploit, password, wireless, forensics).

### Lớp 6: User & Operations
- **Live ISO:** /opt/nexus/src (Cerberus + CLI), /usr/local/bin/nexus-recon, systemd cerberus.service (PYTHONPATH=/opt/nexus/src).
- **Dev:** `pip install -e .` → cerberus, nexus-recon trên PATH; hoặc PYTHONPATH=src.

---

## 2. Trạng thái hoàn thành theo milestone (M0–M7)

| Milestone | Mô tả | Trạng thái | Ghi chú |
|-----------|--------|------------|---------|
| **M0** | Repo & infra cơ bản | ✅ Hoàn thành | Cấu trúc thư mục, CI, archiso clone, docs. |
| **M1** | Profile ArchISO configs/nexus | ✅ Hoàn thành | profiledef.sh, pacman.conf, packages.*, airootfs, efiboot, grub, syslinux; build_iso.sh copy src vào airootfs. |
| **M2** | nexus-recon + Cerberus | 🔶 Phần lớn | Cerberus: API /health, /api/context, /api/ask (Ollama), audit, policy. nexus-recon: scan, --ai-report, --use-cerberus. Thiếu: Falco/eBPF, report export file (markdown/pdf). |
| **M3** | AI model strategy | 🔶 Một phần | models/ layout, model_manager.py (ollama + local). Thiếu: quantization pipeline, CI model smoke. |
| **M4** | Packaging & repo | 🔶 Một phần | create_repo.sh, nexus-core snippet; AUR PKGBUILDs. Thiếu: signing (GPG), ISO dùng repo. |
| **M5** | Secure Boot & signing | ❌ Chưa | Key generation, systemd-boot signing, module signing. |
| **M6** | Testing, QA, Security audit | ❌ Rất ít | Gần như không có unit/integration test; ISO chưa verify boot QEMU. |
| **M7** | Release v0.1 | ❌ Chưa | Phụ thuộc M5, M6, test ISO. |

---

## 3. Điểm mạnh (6)

1. **Kiến trúc rõ ràng:** Tách lớp base, build, AI agent, CLI; policy-driven (ai_policy.yaml) cho phạm vi đọc và lệnh AI.
2. **AI tích hợp sâu:** Cerberus chạy root, localhost-only, full context (process, network, logs, file), system_prompt red/blue team, allowed_commands mở rộng; nexus-recon --use-cerberus.
3. **Bộ công cụ mạnh:** 50 BlackArch + Arch pentest (recon, scan, web, exploit, password, wireless, forensics); repo BlackArch trong pacman.conf.
4. **Build & vận hành:** ArchISO profile đầy đủ, build_iso.sh tự nhúng src, build_aur_local.sh + CI self-hosted, create_repo.sh.
5. **Tài liệu:** ROADMAP, PROJECT_STATUS, ai_integration, TOOLSET, iso_build; design doc tiếng Việt.
6. **Bảo mật thiết kế:** Chỉ localhost, audit log, read_paths/read_exclude, whitelist allowed_commands.

---

## 4. Điểm yếu (13)

1. **Không có unit/integration test:** Không test Cerberus, nexus-recon, context_builder, policy loader.
2. **ISO chưa được kiểm chứng boot:** Chưa có bước QEMU/VM trong CI hoặc doc để verify ISO boot.
3. **Package không ký:** AUR/nexus-core chưa GPG signing → rủi ro supply chain.
4. **Secure Boot chưa làm:** M5 chưa triển khai (kernel/bootloader signing).
5. **Cerberus chưa Falco/eBPF:** Chỉ API + context + Ollama; chưa runtime detection.
6. **nexus-recon chưa export report file:** Chỉ in stdout; chưa --output markdown/pdf.
7. **Phụ thuộc BlackArch mirror:** Build ISO cần mạng; mirror chậm/lỗi ảnh hưởng.
8. **Một số gói AUR có thể lỗi build:** metasploit/openvas placeholder; version pin có thể vỡ.
9. **Không có API spec chính thức:** /api/context, /api/ask chưa OpenAPI/Swagger.
10. **Log rotation chưa cấu hình:** ai_audit.log có thể phình.
11. **Không có bước post-install rõ ràng:** Sau khi cài từ ISO, Ollama/nexus-core repo cần cấu hình thủ công.
12. **Context builder đọc file có thể chậm:** rglob trên read_paths lớn; chưa cache/limit theo thời gian.
13. **Self-hosted runner bắt buộc cho CI:** Cloud runner bị giới hạn (billing); phải có máy Linux cho workflow.

---

## 5. Phân tích bảo mật

- **Policy:** ai_policy.yaml điều khiển đọc (read_paths, read_exclude, max_*) và whitelist lệnh (allowed_commands). Hợp lý cho “AI quyền cao chỉ sau user”.
- **Rủi ro:** (1) Cerberus chạy root — nếu lỗi API hoặc prompt injection có thể lộ context; (2) Gói không ký — cài nhầm gói độc hại; (3) ISO build trên máy không tin cậy — có thể bị can thiệp.
- **Giảm thiểu:** Chỉ bind 127.0.0.1; audit mọi /api/context và /api/ask; đọc theo whitelist path; thực thi lệnh (khi có) chỉ qua allowed_commands và cần xác nhận user (thiết kế). Khuyến cáo: thêm GPG signing, test ISO trong môi trường sạch, rotation và giới hạn kích thước audit log.

---

## 6. Khuyến cáo cụ thể (15)

1. **Thêm pytest cho Cerberus và nexus-recon:** Test load config, policy, context_builder (mock subprocess), /health, /api/ask (mock Ollama).
2. **Thêm bước verify ISO trong CI hoặc doc:** Chạy QEMU với ISO build được, kiểm tra boot và cerberus/nexus-recon có trong image.
3. **Thiết lập GPG và ký repo/packages:** create_repo.sh hỗ trợ GPG_KEY; doc hướng dẫn tạo key và ký.
4. **Export report nexus-recon:** Thêm --output report.md (và tùy chọn pdf) khi dùng --ai-report.
5. **Viết API spec:** OpenAPI cho GET /health, GET /api/context, POST /api/ask (request/response schema).
6. **Cấu hình logrotate cho /var/log/cerberus/:** Tránh ai_audit.log quá lớn.
7. **Post-install script hoặc doc:** Cài Ollama, cấu hình nexus-core repo, bật cerberus.service.
8. **Cache hoặc giới hạn tần suất context:** Tránh gọi /api/context liên tục làm chậm hệ thống.
9. **Triển khai M5 (Secure Boot):** Key, signing kernel/bootloader, doc enroll.
10. **Falco/eBPF trong Cerberus:** Tích hợp runtime detection, gửi event vào context hoặc alert.
11. **Pin version BlackArch hoặc mirror fallback:** Giảm rủi ro mirror đỏ hoặc breaking change.
12. **Kiểm tra và sửa PKGBUILD metasploit/openvas:** Hoặc đánh dấu rõ “placeholder, cài thủ công”.
13. **Trong CI: kiểm tra generate_packages_list + build_iso (dry-run hoặc thật):** Đảm bảo profile và BlackArch không vỡ.
14. **Đánh giá lại max_context_bytes:** Cân bằng giữa đủ thông tin cho LLM và thời gian/bandwidth.
15. **Security review bên thứ ba (khi gần release):** Đánh giá Cerberus, policy, và quy trình build.

---

## 7. Đánh giá sẵn sàng triển khai

- **Triển khai nội bộ / lab:** Có thể dùng ngay: build ISO (có mạng), chạy Cerberus + nexus-recon, 50 BlackArch tools. Rủi ro chấp nhận được nếu môi trường kiểm soát.
- **Triển khai production / release công khai:** Chưa sẵn sàng: cần xử lý test (đặc biệt ISO boot), signing, Secure Boot, và test/QA đầy đủ hơn. Mục tiêu v0.1 sau khi giải quyết 5 blocking/critical issues và một phần khuyến cáo trên.

---

*Tài liệu tham chiếu: PROJECT_STATUS.md, ROADMAP.md, docs/ai_integration.md, docs/TOOLSET.md.*
