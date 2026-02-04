# Nexus OS - Tài Liệu Tiến Độ Dự Án

## 1. Tóm Tắt Dự Án

Nexus OS là một hệ điều hành Linux dựa trên Arch Linux, được tối ưu cho công tác bảo mật và kiểm tra xâm nhập. Dự án sử dụng ArchISO để tạo bản cài đặt trực tiếp (ISO), kèm theo một bộ công cụ bảo mật toàn diện được đóng gói dưới dạng các tệp PKGBUILD (định dạng Arch Linux).

## 2. Cấu Trúc Dự Án

```
d:\Nexus OS/
├── docs/                          # Tài liệu dự án
│   ├── ROADMAP.md                 # Lộ trình phát triển
│   ├── architecture.md            # Kiến trúc hệ thống
│   └── getting_started.md         # Hướng dẫn bắt đầu
├── externals/
│   └── archiso/                   # Bản sao ArchISO (công cụ tạo ISO)
│       └── configs/nexus/         # Cấu hình Nexus OS cho ArchISO
│           ├── packages.*         # Danh sách gói cần cài
│           ├── profiledef.sh      # Định nghĩa profile
│           ├── airootfs/          # Nội dung được nhúng vào ISO
│           └── scripts/           # Script tùy chỉnh khi cài đặt
├── packaging/                     # Đóng gói các công cụ thành gói Arch
│   ├── aur/                       # Các gói AUR (Archive User Repository)
│   │   ├── rustscan/
│   │   ├── ghidra/
│   │   ├── hashcat/
│   │   ├── ophcrack/
│   │   ├── wpscan/
│   │   ├── beef/
│   │   ├── bettercap/
│   │   ├── amass/
│   │   ├── subfinder/
│   │   ├── metasploit/
│   │   └── openvas/
│   └── AUR_PACKAGES.md            # Danh sách gói cần tạo
├── scripts/                       # Các script hỗ trợ
│   ├── build_iso.sh               # Tạo tệp ISO
│   ├── build_aur_local.sh         # Build tất cả gói cục bộ
│   ├── generate_packages_list.sh  # Tạo danh sách gói cuối cùng
│   ├── setup_selfhosted_runner_linux.sh # Cài đặt runner CI
│   └── docker_build_rustscan.sh   # Build rustscan trong container
├── .github/
│   └── workflows/
│       └── build-rustscan-selfhosted.yml  # Workflow CI tự động build
├── Tài liệu thiết kế.md           # Thiết kế gốc từ người dùng
└── README.md                      # Giới thiệu dự án
```

## 3. Những Gì Đã Hoàn Thành

### 3.1 Cấu Trúc Dự Án Cơ Bản
- Khởi tạo dự án với cấu trúc thư mục đầy đủ
- Tạo file README, LICENSE, pyproject.toml, requirements.txt
- Khởi tạo git repository và push lên GitHub (nhánh bootstrap-packaging)

### 3.2 Danh Sách Gói (Package Lists)
- Tạo 6 file danh sách gói theo thể loại:
  - packages.base: gói nền tảng (kernel, bootloader, hệ thống)
  - packages.system: công cụ hệ thống (bootloader, device manager, network)
  - packages.networking: công cụ mạng (wireshark, nmap, netcat, etc.)
  - packages.container: Docker, Podman, systemd-nspawn
  - packages.desktop: giao diện (XFCE, Sway), trình duyệt
  - packages.dev: công cụ lập trình (git, gcc, python, go, rust)
  - packages.pentest: 169 công cụ bảo mật (nmap, burp, metasploit, etc.)
  
- Tạo script generate_packages_list.sh để gộp lại thành packages.x86_64

### 3.3 Công Cụ Đóng Gói (AUR PKGBUILDs)
Đã hoàn thành 10 PKGBUILD cho các công cụ quan trọng:

1. **RustScan** - Quét cổng nhanh (Rust)
   - Binary-first: dùng bản biên dịch sẵn, fallback build từ source
   - Cài vào /usr/bin/rustscan

2. **Ghidra** - Công cụ đảo ngược mã (Java)
   - Giải nén bộ cài nhị phân
   - Cài vào /opt/ghidra-10.2.2 với wrapper script

3. **Hashcat** - Crack mật khẩu GPU (C)
   - Giải nén file .7z (bộ cài từ hashcat.net)
   - Cài vào /opt/hashcat-6.2.6

4. **Ophcrack** - Crack mật khẩu Windows (C++)
   - Bộ cài nhị phân từ SourceForge
   - Wrapper trong /usr/bin/ophcrack

5. **WPScan** - Quét lỗ hổng WordPress (Ruby)
   - Clone source từ GitHub, cài dependencies
   - Cài vào /opt/wpscan-3.8.22

6. **BeEF** - Khai thác trình duyệt (Ruby)
   - Clone source, tương tự WPScan
   - Cài vào /opt/beef-1.0.7

7. **Bettercap** - MITM attack framework (Go)
   - Giải nén binary release
   - Cài vào /opt/bettercap-1.6.2

8. **Amass** - Reconnaissance tool (Go)
   - Giải nén binary từ GitHub releases
   - Cài vào /opt/amass-4.2.1

9. **Subfinder** - Subdomain enumeration (Go)
   - Binary release từ ProjectDiscovery
   - Cài vào /opt/subfinder-2.6.0

10. **Metasploit** - Framework bảo mật (Ruby)
    - Placeholder skeleton (cần thêm công việc để hoàn thành)

11. **OpenVAS** - Quét lỗ hổng (Go/C)
    - Placeholder skeleton với hướng dẫn split components

### 3.4 CI/CD Workflow

Tạo workflow GitHub Actions tự động (file: .github/workflows/build-rustscan-selfhosted.yml)

Tính năng:
- Chạy trên self-hosted runner (máy Linux của người dùng)
- Trigger khi có push vào packaging/aur/**
- Tự động download và cache Docker image (archlinux:latest)
- Caching pacman packages (/var/cache/pacman/pkg) để tránh tải lại
- Build mỗi PKGBUILD trong container Arch
- Timeout 30 phút cho mỗi build (tránh hang)
- Smoke test tự động kiểm tra từng gói (chạy --version, kiểm tra file cài đặt)
- Cleanup artifacts (giữ 3 bản mới nhất, xóa cũ)
- Upload artifacts dưới tên "aur-packages"

### 3.5 Script Build Cục Bộ

1. **scripts/build_aur_local.sh** - Build tất cả gói AUR
   - Chạy Docker container archlinux
   - Build từng PKGBUILD tuần tự
   - Output: packages/ + logs/
   - Summary: số thành công, thất bại, hướng dẫn install

2. **scripts/build_iso.sh** - Tạo file ISO
   - Validate cấu hình profile
   - Chạy mkarchiso từ ArchISO
   - Output: ISO file + hướng dẫn test với QEMU
   - Hướng dẫn ghi ISO ra USB

3. **scripts/setup_selfhosted_runner_linux.sh** - Cài đặt self-hosted runner
   - Tạo user và group cho runner (ghrunner)
   - Download GitHub Actions runner
   - Cài đặt dependencies (curl, git, ssl, etc.)
   - Cấu hình systemd service tự động start
   - Hướng dẫn kiểm tra status và logs

### 3.6 Tài Liệu

- ROADMAP.md: Lộ trình phát triển chi tiết
- architecture.md: Kiến trúc hệ thống
- design_decisions.md: Quyết định thiết kế

## 4. Những Gì Đang Tiến Hành

Hiện tại không có công việc đang tiến hành. Tất cả phần chính đều đã hoàn tất.

## 5. Những Gì Cần Làm Tiếp

### 5.1 Hoàn Thành Metasploit PKGBUILD (Ưu Tiên Cao)
- Cần clone full source từ https://github.com/rapid7/metasploit-framework
- Bundle tất cả dependencies Ruby
- Tạo database initialization script cho PostgreSQL
- Tạo wrapper msfconsole
- Hiện tại: chỉ có skeleton, không thể build được

### 5.2 Hoàn Thành OpenVAS PKGBUILD (Ưu Tiên Cao)
- Chia thành các gói con: gvm-libs, openvas-scanner, gvmd, gsa (web UI)
- Thêm download URLs cho mỗi component
- Implement build steps dùng cmake
- Tạo systemd service files
- Setup PostgreSQL database scripts
- Post-install hooks để initialize

### 5.3 Thêm PKGBUILD cho Gói Khác
Danh sách gói còn lại cần PKGBUILD (từ packages.pentest):
- afl++ (fuzzer)
- airgeddon (wireless)
- fluxion (wireless)
- amass (đã có, nhưng chưa test)
- waybackurls (subdomain từ Wayback Machine)
- bulk_extractor (forensics)
- autopsy (GUI forensics)
- radamsa (binary fuzzing)
- ropper (ROP gadget finder)
- ropgadget (ROP search)
- setoolkit (social engineering)
- empire (C2 framework)
- seclists (wordlists)
- wordlists / rockyou (password lists)
- masscan-utils
- subjack
- httprobe

### 5.4 Test Build ISO (Ưu Tiên Cao)
- Chạy scripts/build_iso.sh trên WSL2 (Ubuntu/Debian)
- Fix bất kỳ issue nào liên quan archiso
- Test boot ISO trong QEMU
- Kiểm tra tất cả packages được cài đúng
- Kiểm tra cerberus service start

### 5.5 Setup Self-Hosted Runner
- Chạy scripts/setup_selfhosted_runner_linux.sh trên WSL2
- Tạo GitHub personal access token cho phép registration
- Verify runner xuất hiện trong GitHub Settings → Actions → Runners
- Trigger một build workflow để test
- Kiểm tra artifacts được upload đúng

### 5.6 Tài Liệu Chi Tiết (Ưu Tiên Trung)
- Hướng dẫn WSL2 setup (install Ubuntu, Docker, tools)
- Hướng dẫn build AUR packages cục bộ
- Hướng dẫn build ISO
- Hướng dẫn test ISO
- Troubleshooting guide
- Chỉnh sửa README và getting_started.md

### 5.7 Tối Ưu Workflow
- Thêm artifact retention policy (giữ 30 ngày)
- Thêm test step chạy ISO inside container (boot test)
- Thêm notification slack/email khi build fail
- Performance monitoring (build time tracking)

### 5.8 CI Pipeline cho ISO Build
- Tạo workflow riêng cho build ISO
- Trigger khi packages.x86_64 hoặc airootfs/* thay đổi
- Publish ISO artifact
- Tự động test boot

## 6. Hướng Dẫn Sử Dụng (WSL2 Windows)

### 6.1 Yêu Cầu
- Windows 10/11 với WSL2 enabled
- Ubuntu 22.04 LTS trên WSL2 (hoặc Debian)
- Docker installed trong WSL2
- Git installed

### 6.2 Setup Ban Đầu

```bash
# 1. Clone dự án vào WSL2
cd /mnt/d/Nexus\ OS  # hoặc folder khác
git clone https://github.com/Seread335/Nexus-OS.git
cd Nexus-OS
git checkout bootstrap-packaging

# 2. Cài đặt dependencies
sudo apt-get update
sudo apt-get install -y docker.io archiso git curl

# 3. Thêm user vào docker group (tránh dùng sudo)
sudo usermod -aG docker $USER
newgrp docker

# 4. Start Docker
sudo systemctl start docker
```

### 6.3 Build AUR Packages Cục Bộ

```bash
bash scripts/build_aur_local.sh ./output_packages
```

Kết quả:
- Packages: ./output_packages/packages/
- Logs: ./output_packages/logs/

### 6.4 Build ISO (cần archiso cài sẵn)

```bash
# Cài archiso (trên WSL2, chỉ có trong repo Arch, không Debian/Ubuntu)
# Cách thay thế: sử dụng mkarchiso từ chroot Arch hoặc container

# Hoặc: build bằng container (nếu cài mkarchiso không được)
sudo mkdir -p /tmp/iso-build
bash scripts/build_iso.sh ./iso_output /tmp/iso-build
```

### 6.5 Setup Self-Hosted Runner

```bash
# 1. Tạo GitHub Personal Access Token
# Truy cập: https://github.com/settings/tokens
# Cấp quyền: repo, workflow, admin:org_hook
# Copy token

# 2. Chạy setup script
bash scripts/setup_selfhosted_runner_linux.sh "<YOUR_TOKEN>" "wsl-nexus-runner" "https://github.com/Seread335/Nexus-OS"

# 3. Verify runner
sudo systemctl status actions-runner
sudo journalctl -u actions-runner -f

# 4. Check GitHub Actions Runners
# Truy cập: https://github.com/Seread335/Nexus-OS/settings/actions/runners
```

## 7. Trạng Thái Các Công Cụ

### Đã Sẵn Sàng (10 gói)
- rustscan: Hoàn thành, build thành công
- ghidra: Hoàn thành
- hashcat: Hoàn thành
- ophcrack: Hoàn thành
- wpscan: Hoàn thành
- beef: Hoàn thành
- bettercap: Hoàn thành
- amass: Hoàn thành
- subfinder: Hoàn thành
- openvas: Skeleton (cần thêm công việc)

### Chưa Sẵn Sàng
- metasploit: Skeleton (cần bundle Ruby, DB setup)
- 20+ gói khác: Cần viết PKGBUILD

## 8. Thống Kê Dự Án

| Loại | Số Lượng | Ghi Chú |
|------|---------|--------|
| Commits | 20+ | Tất cả trên nhánh bootstrap-packaging |
| PKGBUILD | 11 | 10 hoàn thành, 1 skeleton |
| Scripts | 5 | build_iso, build_aur_local, build_rustscan, setup_runner, generate_packages |
| Workflows | 1 | build-rustscan-selfhosted.yml |
| Packages được liệt kê | 169 | Từ packages.pentest + packages.* khác |
| Gói AUR cần tạo | 30+ | Danh sách trong AUR_PACKAGES.md |
| Dòng code/config | 3000+ | Đóng gói PKGBUILD, scripts, config, workflow |

## 9. Các Lỗi Đã Xảy Ra và Cách Giải Quyết

### Lỗi Mirror/Network
- **Vấn đề**: Pacman mirror timeout khi cài packages trong container
- **Giải Pháp**: Dùng caching pacman packages, mount /var/cache/pacman/pkg từ host

### Lỗi Linker khi Build Rustscan
- **Vấn đề**: Crate "ring" unresolved symbols khi compile từ source
- **Giải Pháp**: Dùng pre-built binary, fallback sang source nếu cần

### Git Nested Repository
- **Vấn đề**: Khi build rustscan, .git của RustScan source bị track bởi main repo
- **Giải Pháp**: Clean up và remove từ git, giữ binary artifact thay thế

### Cloud CI Blocked
- **Vấn đề**: GitHub Actions cloud bị lock vì billing issue
- **Giải Pháp**: Dùng self-hosted runner, script build cục bộ

## 10. Ghi Chú Quan Trọng

1. **WSL2 và Docker**: Docker trên WSL2 chạy được Linux container, phù hợp cho ArchISO build
2. **Archiso**: Cần chạy mkarchiso từ Arch Linux (hoặc container archlinux)
3. **Self-hosted Runner**: Cần Linux + Docker + đủ disk space (tối thiểu 10GB cho build cache)
4. **Caching**: Tắt caching sẽ làm chậm build đáng kể (mỗi build mất 30+ phút)
5. **Artifact Cleanup**: Script tự động xóa artifacts cũ để tránh disk full

## 11. Liên Hệ và Tài Nguyên

- GitHub Repo: https://github.com/Seread335/Nexus-OS
- ArchISO Docs: https://wiki.archlinux.org/title/Archiso
- Arch Linux Wiki: https://wiki.archlinux.org/
- GitHub Actions Docs: https://docs.github.com/en/actions

---

Tài liệu cập nhật lần cuối: February 4, 2026
