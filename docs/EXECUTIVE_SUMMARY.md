# Nexus OS — Tóm Tắt Điều Hành & Sprint Plan

Dành cho lãnh đạo và quản lý dự án: trạng thái 1 trang, deal-breakers, critical/high issues, sprint plan và timeline.

---

## Tóm tắt 1 trang

| Hạng mục | Trạng thái |
|----------|------------|
| **Mục tiêu** | Bản phân phối pentest/security dựa trên Arch, tích hợp AI sâu (Cerberus + Ollama), 50 công cụ BlackArch, hướng tới release v0.1. |
| **Độ sẵn sàng** | ~40–50%: hạ tầng build, profile ISO, AI agent và CLI cơ bản đã có; thiếu test, signing, kiểm chứng ISO boot. |
| **Deal-breakers** | (1) ISO chưa được verify boot. (2) Không có test tự động. (3) Gói chưa ký. (4) Secure Boot chưa làm. Xử lý xong mới có thể release công khai. |

---

## 5 CRITICAL ISSUES (fix ngay)

| # | Vấn đề | Trạng thái code hiện tại | Hành động | Ước lượng |
|---|--------|---------------------------|-----------|-----------|
| 1 | Cerberus POST /api/ask — logic gọi Ollama | ✅ **Đã có:** `_ollama_generate`, system_prompt, include_context | Không cần sửa logic; có thể thêm retry/timeout | 0 ngày |
| 2 | nexus-recon — report generation | ✅ **Đã có:** --output FILE (Markdown: scan + AI summary) | (Tùy chọn) thêm export PDF | — |
| 3 | Unit tests | ✅ **Đã có:** tests/ với pytest (config, policy, /health, nexus_recon) | Thêm vào CI | — |
| 4 | ISO verify boot QEMU | ✅ **Đã có:** scripts/verify_iso_qemu.sh + docs/iso_build.md | Chạy trong CI (optional) | — |
| 5 | Package không ký (supply chain) | ❌ Chưa | Bật GPG trong create_repo.sh, doc tạo key + ký; ký AUR artifacts (nếu có) | 2–3 ngày |

---

## 7 HIGH-PRIORITY ISSUES (1–2 tuần)

1. **API spec chính thức** — ✅ Đã có `docs/API.md` (request/response). (Tùy chọn: OpenAPI YAML.)
2. **Log rotation** — ✅ Đã có `airootfs/etc/logrotate.d/cerberus` (weekly, rotate 4).
3. **Post-install hướng dẫn** — Ollama, nexus-core repo, cerberus.service.
4. **Metasploit/OpenVAS PKGBUILD** — hoàn thiện hoặc đánh dấu placeholder.
5. **BlackArch mirror fallback** — doc hoặc script đổi mirror khi lỗi.
6. **Context builder** — giới hạn/cache để tránh quá tải khi gọi /api/context liên tục.
7. **Security hardening checklist** — doc cho deploy (firewall, user, audit).

---

## Sprint plan (4 sprints, 4–6 tuần)

| Sprint | Mục tiêu | Deliverables | Tuần |
|--------|----------|--------------|------|
| **Sprint 1** | Critical #3, #4, #5 | Pytest Cerberus + nexus_recon (tối thiểu); bước verify ISO (QEMU); GPG + doc signing | 1–2 |
| **Sprint 2** | Critical #2, High 1–2 | nexus-recon --output report.md; OpenAPI spec; logrotate | 2–3 |
| **Sprint 3** | High 3–5, M5 bước đầu | Post-install doc; PKGBUILD metasploit/openvas hoặc placeholder rõ ràng; mirror fallback; bắt đầu Secure Boot (key + doc) | 3–4 |
| **Sprint 4** | Stabilization, v0.1 prep | Fix lỗi phát sinh; test full flow (build ISO → boot → Cerberus + recon); release checklist, tag v0.1-alpha hoặc v0.1 | 4–6 |

---

## Team allocation & timeline

- **v0.1 release mục tiêu:** Tuần 3/10 (hoặc sau Sprint 4 tùy nguồn lực).
- **Owner gợi ý:** 1 dev infra (CI, ISO, signing), 1 dev AI/CLI (Cerberus, nexus-recon, tests), 1 doc/QA (spec, checklist, verify ISO). Có thể gộp vai trò nếu team nhỏ.

---

## Risk matrix

| Rủi ro | Khả năng | Tác động | Giảm thiểu |
|--------|----------|----------|------------|
| BlackArch mirror down khi build | Trung bình | Build ISO thất bại | Document mirror thay thế; cache pacman. |
| Thiếu test → regression | Cao | Lỗi im lặng sau khi sửa | Sprint 1 ưu tiên pytest. |
| Chưa ký gói → supply chain | Trung bình | Tin cậy release | Sprint 1 GPG + doc. |
| ISO không boot trên một số HW | Trung bình | Trải nghiệm người dùng kém | QEMU verify + test trên 2–3 máy thật. |

---

## Success criteria cho v0.1

- ISO build được và boot được trong QEMU (và tùy chọn 1 máy thật).
- Cerberus chạy, /health và /api/ask trả về đúng khi Ollama bật.
- nexus-recon scan <target> --ai-report (và --use-cerberus) chạy và in (hoặc export) báo cáo.
- Có ít nhất 5+ unit test (Cerberus hoặc nexus_recon) và chạy trong CI.
- Repo nexus-core (hoặc AUR) có hướng dẫn ký gói; ít nhất doc mô tả quy trình.
- Doc: quick start, post-install, và ít nhất 1 trong: OpenAPI spec hoặc API section trong ai_integration.

---

*Tham chiếu: SYSTEM_ANALYSIS.md, QUICK_REFERENCE.md, ROADMAP.md.*
