# Nexus OS — Troubleshooting

## Cerberus

### Service không start
- `systemctl status cerberus` — xem log.
- Kiểm tra config: `cat /etc/cerberus/config.yaml` (YAML hợp lệ, `agent.enabled: true`).
- Nếu thiếu Python hoặc module: cài từ repo (packages.ai) hoặc `pip install -r requirements.txt` trong môi trường Cerberus.

### GET /health trả 403
- API chỉ chấp nhận request từ **localhost**. Gọi từ 127.0.0.1 (ví dụ `curl http://127.0.0.1:9380/health`), không gọi qua IP khác.

### POST /api/ask trả 503
- **Ollama chưa chạy:** `ollama serve` (hoặc enable systemd service ollama nếu có).
- **Ollama disabled trong config:** Trong `config.yaml` đặt `ollama.enabled: true`.
- **Ollama unreachable:** Kiểm tra `ollama.base_url` (mặc định http://127.0.0.1:11434). Test: `curl http://127.0.0.1:11434/api/tags`.

### POST /api/ask trả 504
- Ollama phản hồi chậm (model lớn hoặc máy yếu). Tăng `ollama.timeout` trong config (mặc định 120).

---

## nexus-recon

### "nmap not found"
- Cài nmap: `pacman -S nmap`. Trên ISO Nexus đã có trong danh sách gói.
- Exit code 1 khi nmap không có hoặc timeout.

### AI summary không có / "(Start Cerberus or ollama serve)"
- Bật Cerberus: `systemctl start cerberus`.
- Hoặc chạy Ollama: `ollama serve` và dùng `--ai-report` (không dùng `--use-cerberus`).
- Để dùng full context: `--ai-report --use-cerberus`.

### Report không ghi file
- Kiểm tra quyền thư mục đích. `--output` tạo thư mục cha nếu cần (user cần quyền ghi).

---

## ISO build / boot

### Build ISO lỗi
- Chạy từ **Arch Linux** (hoặc môi trường tương thích archiso). Xem `externals/archiso/README`.
- Đủ dung lượng đĩa (khuyến nghị 20–40 GB).
- Một số gói cần AUR/nexus-core repo: xem `docs/iso_build.md`.

### ISO không boot trong QEMU
- Cài `qemu-system-x86_64`, có thể thêm `edk2-ovmf` cho UEFI.
- Script: `./scripts/verify_iso_qemu.sh path/to/nexus-*.iso`. Chi tiết: `docs/ISO_VERIFY_CHECKLIST.md`.

---

## Model manager

### "Ollama not found"
- Cài Ollama (https://ollama.ai hoặc AUR). Chạy `ollama serve` trước khi dùng `ollama-list` / `ollama-pull`.

### Switch model (local)
- `switch <name>` chỉ hoạt động với model đã có trong `models/archives/<name>`. Với Ollama, dùng `ollama run <model>`; Cerberus dùng model trong `config.yaml` → `ollama.model`.
