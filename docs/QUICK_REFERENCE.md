# Nexus OS — Quick Reference (Developers)

Hướng dẫn nhanh cho team: blocking issues (vị trí code, tác động, thời gian sửa), lệnh kiểm tra trạng thái, checklist chất lượng, action items theo vai trò, template theo dõi tiến độ, tài liệu tham khảo.

---

## 5 BLOCKING ISSUES (chi tiết)

| # | Vấn đề | Vị trí code | Tác động | Thời gian sửa |
|---|--------|--------------|----------|----------------|
| 1 | Cerberus POST /api/ask — Ollama call | `src/cerberus/cerberus.py`: `do_POST` → `_ollama_generate` | **Đã triển khai:** logic gọi Ollama có đủ (prompt, system_prompt, include_context). Có thể bổ sung retry/timeout. | 0 ngày (optional: 0.5 ngày retry) |
| 2 | nexus-recon report generation | `src/cli/nexus_recon.py`: `cmd_scan` | **Đã triển khai:** `--output FILE` ghi Markdown (scan + AI summary). | — |
| 3 | Unit tests | `tests/` | **Đã thêm:** pytest cho config, policy, /health, nexus_recon (_write_report, run_scan). Chạy: `pytest tests/` (PYTHONPATH=src hoặc pip -e .). | — |
| 4 | ISO verify boot | `scripts/verify_iso_qemu.sh` | **Đã thêm:** script QEMU; doc trong `docs/iso_build.md`. Chạy `./scripts/verify_iso_qemu.sh [path/to/nexus-*.iso]`. | — |
| 5 | Package không ký | `scripts/create_repo.sh`: GPG_KEY optional, chưa bắt buộc | Supply chain risk. Doc hướng dẫn tạo key, `repo-add --sign --key`, và dùng GPG_KEY khi gọi create_repo. | 2–3 ngày |

---

## Status check commands (5 phút verify)

```bash
# 1. Generate package list (có packages.blackarch)
bash scripts/generate_packages_list.sh
# Expect: Generated ... packages.x86_64 (230+ packages)

# 2. Cerberus config load (từ repo root, có src)
PYTHONPATH=src python -c "from cerberus.config import load_config; print(load_config())"

# 3. Policy load
PYTHONPATH=src python -c "from cerberus.ai_policy import load_ai_policy; print(load_ai_policy())"

# 4. Health (nếu Cerberus đang chạy)
curl -s http://127.0.0.1:9380/health | jq .

# 5. nexus-recon help and report
PYTHONPATH=src python -m cli.nexus_recon --help
PYTHONPATH=src python -m cli.nexus_recon scan --help
# Export report: scan --output report.md [--ai-report]

# 6. Run tests
./scripts/run_tests.sh
# hoặc: pip install -e ".[dev]" && pytest tests/ (PYTHONPATH=src)
# Integration: pytest tests/test_integration.py (skip on Windows)
```

---

## Code quality checklist

- [ ] `generate_packages_list.sh` chạy không lỗi và `packages.x86_64` có đủ nhóm (base, ai, blackarch, pentest).
- [ ] Cerberus: chỉ bind 127.0.0.1; mọi /api/context và /api/ask ghi audit.
- [ ] Policy: read_exclude chứa *.key, *password*, /etc/shadow; allowed_commands không thêm lệnh nguy hiểm tùy tiện.
- [ ] Không hardcode secret/API key trong repo.
- [ ] Doc cập nhật khi đổi API hoặc config (ai_integration.md, TOOLSET.md).

---

## Team action items theo role

| Role | Hành động ưu tiên |
|------|-------------------|
| **Infra / CI** | Thêm bước verify ISO (QEMU) trong CI hoặc doc; thiết lập GPG và hướng dẫn ký repo. |
| **Backend / Cerberus** | Viết unit test (config, policy, /health, /api/ask với mock Ollama); (optional) retry/timeout cho Ollama. |
| **CLI / nexus-recon** | Thêm --output report.md; (optional) test scan + ai-report với mock. |
| **Doc / QA** | Cập nhật EXECUTIVE_SUMMARY và QUICK_REFERENCE khi đổi blocking; soạn post-install và OpenAPI (hoặc API section). |

---

## Weekly progress tracking template

```markdown
## Week YYYY-MM-DD

### Done
- [ ] ...
### In progress
- [ ] ...
### Blocked
- [ ] ...
### Next week
- [ ] ...
```

---

## Learning resources & key concepts

- **ArchISO:** https://wiki.archlinux.org/title/Archiso  
- **BlackArch:** https://blackarch.org/downloads.html, repo thêm qua strap.sh hoặc pacman.conf.  
- **Cerberus API:** docs/ai_integration.md, docs/API.md — /health, GET /api/context, POST /api/ask.  
- **Policy:** externals/archiso/configs/nexus/airootfs/etc/cerberus/ai_policy.yaml.  
- **Ollama:** https://ollama.ai — local LLM, API /api/generate.  
- **Performance:** docs/PERFORMANCE.md — RAM/CPU, Ollama timeout, context profiling, `scripts/profile_context.sh`.  
- **PKGBUILDs:** packaging/aur/ — metasploit (meta), metasploit-framework (full build), openvas-bin (Docker wrapper); PKGBUILDs_PLACEHOLDERS.md.

---

*Tham chiếu: SYSTEM_ANALYSIS.md, EXECUTIVE_SUMMARY.md, ARCHITECTURE_DIAGRAMS.md, PERFORMANCE.md.*
