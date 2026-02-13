# ISO Verify Checklist (Nexus OS)

Đảm bảo ISO build được và boot được trước khi release.

## 1. Build ISO

```bash
./scripts/build_iso.sh
# Hoặc: cd externals/archiso && ./build.sh -v nexus
```

Output: `build_output/*.iso` (hoặc thư mục out của archiso).

## 2. Boot trong QEMU

```bash
./scripts/verify_iso_qemu.sh [path/to/nexus-*.iso]
```

- **Yêu cầu:** `qemu-system-x86_64` (Arch: `pacman -S qemu-base edk2-ovmf`).
- Mở cửa sổ QEMU; dừng: đóng cửa sổ hoặc Ctrl+Alt+G → `quit`.

## 3. Checklist sau khi boot (verify Cerberus + tools on ISO)

**Bắt buộc:** Chạy lần lượt sau khi đăng nhập vào live system (root hoặc user có sudo).

| Bước | Lệnh / Kiểm tra | Kết quả mong đợi |
|------|------------------|------------------|
| 1. Login | Đăng nhập user (root/arch) | Vào được shell |
| 2. Cerberus service | `systemctl status cerberus` | **active (running)** hoặc at least **enabled** — đây là bước verify Cerberus starts on ISO |
| 3. Health | `curl -s http://127.0.0.1:9380/health \| jq .` | `"status":"ok"` |
| 4. nexus-recon | `nexus-recon scan --help` | In help, không lỗi |
| 5. Report | `nexus-recon scan 127.0.0.1 -o /tmp/r.md` | Exit 0 hoặc 1 (nmap), file /tmp/r.md tồn tại |

**One-liner verify (chạy trong live system):**
```bash
systemctl is-active cerberus && curl -s http://127.0.0.1:9380/health | jq -e '.status=="ok"' && nexus-recon --version
```
Nếu cả ba thành công (exit 0) thì Cerberus đã start và API phản hồi đúng.

## 4. Nếu ISO không boot

- Kiểm tra log build: `build_output/logs/` (nếu có).
- Chạy archiso với `-v` để xem lỗi.
- Trên QEMU: kiểm tra có báo lỗi kernel/initramfs không; thử UEFI vs BIOS (bỏ/thêm `-bios` trong script).

## 5. CI (tùy chọn)

Trên runner có QEMU (self-hosted hoặc runner với KVM), có thể thêm bước:

```yaml
- name: Verify ISO boot
  run: ./scripts/verify_iso_qemu.sh build_output/*.iso
  # Timeout 120s; có thể dùng expect/script để gửi key và thoát
```

Hiện tại CI chưa chạy QEMU mặc định (cần nhiều tài nguyên).
