# Nexus OS — Performance & resource requirements

Khuyến nghị phần cứng, thời gian phản hồi, và cách đo/profiling.

---

## 1. Phần cứng khuyến nghị

| Môi trường | RAM | CPU | Ghi chú |
|------------|-----|-----|--------|
| **ISO live / chạy tối thiểu** | 2 GB | 2 cores | Đủ boot và Cerberus; Ollama cần thêm RAM nếu bật. |
| **Chạy AI (Ollama + Cerberus)** | 4–8 GB | 4 cores | Model nhỏ (phi3:mini, llama3.2:3b): ~4 GB. Model 7B+: 8 GB+. |
| **Build ISO** | 8–16 GB | 4+ cores | archiso + gói BlackArch; 20–40 GB disk. |
| **OpenVAS (Docker)** | 4–8 GB | 2+ cores | Container Greenbone; lần đầu pull image lớn. |

---

## 2. Ollama

- **Startup:** `ollama serve` thường sẵn sàng trong 2–10 giây. Model load on first request (vài giây đến vài chục giây tùy model).
- **Cấu hình Cerberus:** `config.yaml` → `ollama.timeout` (mặc định 120s). Nếu máy yếu hoặc model lớn, tăng lên 180–300.
- **Retry:** Cerberus gọi Ollama với 2 lần retry (sau 1s). Timeout áp dụng cho mỗi lần gọi.

---

## 3. Context builder (GET /api/context)

- **Giới hạn:** `ai_policy.yaml` → `max_context_bytes` (mặc định 512 KB), `max_file_bytes`, `max_file_lines`. Mỗi lệnh (`ps`, `ss`, `ip`, `journalctl`) có timeout 15–30s.
- **Thời gian điển hình:** 1–5 giây tùy số file trong `read_paths` và tốc độ ổ đĩa. Nếu `read_paths` rộng, có thể 5–15s.
- **Tối ưu:** Thu hẹp `read_paths`, tăng `read_exclude`; giảm `max_file_lines` nếu context quá dài.

---

## 4. Profiling & đo nhanh

### Test duration (pytest)
```bash
PYTHONPATH=src pytest tests/ -v --durations=10
```
In ra 10 test chạy chậm nhất.

### Đo /api/context (khi Cerberus đang chạy)
```bash
time curl -s http://127.0.0.1:9380/api/context | jq '.length'
```

### Đo /api/ask (end-to-end với Ollama)
```bash
time curl -s -X POST http://127.0.0.1:9380/api/ask \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Say hello in one word.","include_context":false}' | jq .
```

### Script profile context
```bash
./scripts/profile_context.sh [http://127.0.0.1:9380]
```
Đo thời gian GET /api/context và in ra length (cần Cerberus đang chạy, jq, curl).

---

## 5. Low-end hardware

- **Tắt context khi không cần:** Gửi `include_context: false` cho POST /api/ask để giảm thời gian (không gọi gather_system_context).
- **Model nhỏ:** Dùng phi3:mini, tinyllama, hoặc llama3.2:3b thay vì 7B+.
- **Giảm context:** Giảm `max_context_bytes` (vd 262144) và `max_file_lines` (vd 200) trong ai_policy.yaml.
