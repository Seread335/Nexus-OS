# PKGBUILD status (Nexus OS)

| Package | Status | Notes |
|---------|--------|--------|
| **metasploit-framework** | Complete | Clone from GitHub, `bundle install`, package to /opt; msfconsole wrapper + symlinks. Build: 5–15 min (Ruby deps). |
| **metasploit** | Complete (meta) | Meta package: depends on metasploit-framework; install this for pkgname "metasploit". |
| **openvas-bin** | Complete | Docker/Podman wrapper: openvasctl (start/stop/status/logs), systemd oneshot. No external source (scripts inline). |
| hashcat, rustscan, ghidra, etc. | Per-directory | See each PKGBUILD. |

Add CI job to build these PKGBUILDs and publish to the internal repo if build succeeds.

---

## Checksums cho PKGBUILD (sha256sums)

Với PKGBUILD dùng `source=("https://.../file.tar.gz")`, cần điền `sha256sums=("...")` để build reproducible và an toàn.

**Cách lấy checksum:**
```bash
# Sau khi có file nguồn (tải bằng makepkg -g hoặc tay):
cd packaging/aur/<pkgname>
makepkg -g
# Sinh ra dòng sha256sums=('...') — copy vào PKGBUILD.

# Hoặc trên Arch với pacman-contrib:
updpkgsums
# Tự động cập nhật sha256sums trong PKGBUILD từ source.
```

**Gói dùng git hoặc script inline:** Giữ `sha256sums=('SKIP')` hoặc `source=()` + `sha256sums=()`; ghi chú trong PKGBUILD là "no external tarball".
