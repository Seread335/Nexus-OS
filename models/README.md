# Nexus OS — AI Models

Thư mục quản lý model cho tích hợp AI sâu trong Nexus OS.

## Cấu trúc

- **`active/`** — Model đang dùng cho Cerberus / nexus-recon (symlink hoặc bản copy).
- **`archives/`** — Model cũ hoặc thay thế (để tiết kiệm dung lượng có thể xóa).
- **`scripts/`** — Script convert/quantize (GGUF, GPTQ) — tùy chọn.

## Cách dùng

- **Ollama (khuyến nghị):** Cài Ollama, chạy `ollama pull <tên>`; `nexus-recon --ai-report` và Cerberus sẽ gọi Ollama API local.
- **Model file (GGUF/ONNX):** Dùng `scripts/model_manager.py` để download/list/switch/cleanup.

## Chính sách

- Model nhẹ chạy local (ví dụ Phi-3 mini, Gemma 2B, Qwen2-0.5B) cho recon + Cerberus.
- Model lớn hoặc chuyên biệt có thể dùng qua API remote (tùy cấu hình).
