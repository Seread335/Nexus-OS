# Nexus OS — Tích hợp AI sâu vào OS

Tài liệu mô tả cách AI được tích hợp vào Nexus OS và cách sử dụng.

## Tổng quan

- **Cerberus** — Agent bảo mật chạy nền **với quyền root**, chỉ lắng nghe **localhost**: cấu hình YAML, ONNX, health, API `/api/context` (snapshot toàn hệ thống) và `/api/ask` (Ollama + context), mọi truy cập đều **audit log**. Chi tiết request/response: **`docs/API.md`**.
- **nexus-recon** — CLI recon: quét target (nmap), `--ai-report` tóm tắt bằng Ollama hoặc **Cerberus** (`--use-cerberus`) để AI nhìn được **full system context** (process, network, logs).
- **Model Manager** — Script quản lý model: `ollama list/pull`, list/switch/cleanup.

---

## AI với quyền cao nhất chỉ sau người dùng

Cerberus được thiết kế để AI **có thể truy cập toàn bộ hệ thống với quyền cao nhất, chỉ sau người dùng**:

1. **Daemon chạy root**  
   Service systemd `cerberus.service` chạy với `User=root`, nên có quyền đọc mọi file, process, network, log mà policy cho phép.

2. **Chỉ localhost**  
   API bind **127.0.0.1:9380** — chỉ user đăng nhập trên máy (hoặc script chạy local) mới gọi được. Không expose ra mạng.

3. **Policy điều khiển phạm vi đọc**  
   File **`/etc/cerberus/ai_policy.yaml`**:
   - **read_paths**: thư mục/file được phép đưa vào context (vd: `/etc/cerberus`, `/var/log`, `/proc/net`).
   - **read_exclude**: loại trừ (vd: `*.key`, `*password*`, `/etc/shadow`).
   - **max_context_bytes**, **max_file_bytes**, **max_file_lines**: giới hạn dung lượng context gửi cho LLM.
   - **allowed_commands**: whitelist lệnh AI có thể gợi ý/thực thi (khi triển khai bước sau).

4. **Context toàn hệ thống**  
   `GET /api/context` (chỉ từ localhost) trả về snapshot:
   - `ps aux` (process)
   - `ss -tuln`, `ip -br a` (network)
   - `journalctl -n 200` (log)
   - Nội dung file trong **read_paths** (theo giới hạn policy).

5. **Audit**  
   Mỗi lần gọi `/api/context` hoặc `/api/ask` được ghi vào **audit_log_path** (mặc định `/var/log/cerberus/ai_audit.log`).

**Tóm lại:** AI có quyền đọc rất rộng (theo policy) nhờ daemon root, nhưng chỉ kích hoạt qua localhost và mọi lần dùng đều được ghi log; người dùng vẫn là người ra lệnh và kiểm soát.

## Bộ công cụ 50 BlackArch + AI tấn công/phòng thủ

- Nexus cài sẵn **50 công cụ phổ biến** từ repo **BlackArch** (recon, scan, web, exploit, password, wireless, forensics). Chi tiết: **docs/TOOLSET.md**.
- **AI** được cấu hình (`config.yaml` → `ollama.system_prompt`) vai trò red team + blue team, gợi ý lệnh cụ thể từ bộ công cụ (nmap, sqlmap, metasploit, nuclei, responder, …). Policy **allowed_commands** trong `ai_policy.yaml` đã mở rộng để AI có thể gợi ý toàn bộ các lệnh này.

## Gói trong ISO (packages.ai)

Profile Nexus đã thêm nhóm **packages.ai**, gồm:

- Python + pip + virtualenv, numpy, scipy, pandas, scikit-learn, PyYAML, requests, click
- **onnxruntime** (và python-onnxruntime nếu có) — cho Cerberus
- httpx, aiohttp — gọi Ollama / API
- curl, wget, jq, unzip, p7zip — cho model manager

Sau khi chạy `scripts/generate_packages_list.sh`, file `packages.x86_64` sẽ bao gồm các gói AI.

## Ollama (LLM local)

- Ollama không nằm trong repo chính thức Arch; cài thủ công hoặc AUR.
- Khuyến nghị: cài xong chạy `ollama serve` (hoặc systemd service), sau đó:
  - `ollama pull phi3:mini` (hoặc model nhẹ khác)
  - `nexus-recon scan <target> --ai-report` sẽ gọi Ollama để tóm tắt.
  - Cerberus có thể dùng Ollama để giải thích cảnh báo (cấu hình trong `config.yaml`).

## Cấu trúc thư mục model

- **models/active** — Model đang dùng (symlink hoặc bản copy).
- **models/archives** — Model dự phòng / cũ.
- **scripts/model_manager.py** — Lệnh: `ollama-list`, `ollama-pull`, `local-list`, `switch`, `cleanup`.

## Cerberus

- Cấu hình: `/etc/cerberus/config.yaml`, **`/etc/cerberus/ai_policy.yaml`** (policy đọc hệ thống và audit).
- Chạy: service systemd (User=root) hoặc `python -m cerberus.cerberus` (cần quyền root nếu đọc toàn hệ thống).
- API (chỉ 127.0.0.1:9380):
  - `GET /health` — trạng thái, onnx_loaded, deep_access.
  - `GET /api/context` — snapshot toàn hệ thống theo policy (process, network, journal, file trong read_paths).
  - `POST /api/ask` — body `{"prompt": "...", "include_context": true}` → gửi prompt + context cho Ollama, trả response.
- ONNX: `ml.onnx_model` trong config; để trống thì không load model.
- Audit: mọi request tới `/api/context` và `/api/ask` ghi vào `audit_log_path` trong ai_policy.yaml.

## nexus-recon

- Ví dụ:
  - `nexus-recon scan 192.168.1.0/24`
  - `nexus-recon scan example.com --aggressive --ai-report` — tóm tắt qua Ollama.
  - **`nexus-recon scan example.com --ai-report --use-cerberus`** — tóm tắt qua Cerberus; AI nhìn thêm **full system context** (process, network, logs).
- Cần nmap; với `--ai-report`: Ollama hoặc Cerberus (và Ollama) đang chạy.

## Bước tiếp theo (roadmap)

- Falco/eBPF trong Cerberus
- Pipeline quantize GGUF / script convert ONNX
- PKGBUILD cho cerberus và nexus-recon, đưa vào repo nexus-core
