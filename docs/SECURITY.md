# Nexus OS — Security

Tóm tắt bảo mật: package signing, policy, audit log, và khuyến nghị triển khai.

## 1. Package / repository signing (supply chain)

### Signing guide (step-by-step)

**Bước 1 — Tạo GPG key (một lần):**
```bash
gpg --full-generate-key
# Chọn RSA and RSA, 4096 bits; nhập identity (name, email).
# Hoặc nhanh: gpg --quick-generate-key "Nexus OS Repo" default default 0
```

**Bước 2 — Lấy Key ID:**
```bash
gpg --list-secret-keys --keyid-format long
# Dòng sec rsa4096/XXXXXXXX YYYY-MM-DD — XXXXXXXX là Key ID (8 ký tự).
```

**Bước 3 — Ký repo khi tạo/cập nhật:**
```bash
export GPG_KEY=XXXXXXXX   # thay bằng Key ID của bạn
./scripts/create_repo.sh build_output/repo nexus-core
# repo-add sẽ dùng --sign --key $GPG_KEY; file .db.tar.zst.sig được tạo.
```

**Bước 4 — Trên máy client (người cài gói):**
```bash
# Export public key từ máy build (trên máy build):
gpg --export --armor YOUR_KEY_ID > nexus-repo.pub
# Copy nexus-repo.pub sang client, rồi trên client:
sudo pacman-key --add nexus-repo.pub
sudo pacman-key --lsign-key YOUR_KEY_ID
# Trong /etc/pacman.conf, với repo nexus-core dùng:
# SigLevel = Required DatabaseOptional
# (hoặc Optional TrustedOnly nếu chấp nhận unsigned packages)
```

- Chi tiết: [Arch Wiki - Pacman package signing](https://wiki.archlinux.org/title/Pacman/Package_signing).

## 2. AI policy (context & commands)

- **File:** `/etc/cerberus/ai_policy.yaml`.
- **read_paths / read_exclude:** Đã hardened: loại trừ `*.key`, `*.pem`, `/etc/shadow`, `/etc/ssl/private`, `*secret*`, `*password*`, `.ssh`, v.v. Không đọc credential/key material khi build context.
- **allowed_commands:** Whitelist lệnh; chỉ thêm lệnh cần thiết. User nên xác nhận trước khi thực thi lệnh AI gợi ý.

## 3. Audit log

- **Đường dẫn:** `/var/log/cerberus/ai_audit.log` (mặc định).
- **Nội dung:** Mỗi request `/api/context` và `/api/ask` ghi một dòng (path, client, extra).
- **Khuyến nghị:** Giữ log append-only; dùng logrotate (đã có `etc/logrotate.d/cerberus`). Để verify integrity có thể dùng auditd hoặc checksum định kỳ (triển khai tùy chọn).

## 4. Context & transport

- **Cerberus API:** Chỉ bind 127.0.0.1 — chỉ process local gọi được.
- **Ollama:** Mặc định local (http://127.0.0.1:11434). Nếu cấu hình Ollama ở host khác: context và prompt đi qua HTTP; nên dùng TLS (Ollama hỗ trợ env để bật HTTPS) và mạng tin cậy.

## 5. Checklist triển khai

- [ ] Ký repo với GPG khi build repo nội bộ.
- [ ] Rà soát `read_paths` / `read_exclude` trước khi mở rộng.
- [ ] Bật logrotate cho `/var/log/cerberus/`.
- [ ] Không expose Cerberus/Ollama ra internet; chỉ localhost hoặc mạng nội bộ có bảo vệ.
