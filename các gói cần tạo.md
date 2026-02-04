Danh sách gói đề xuất (Arch) — đầy đủ theo nhóm ✅
Dưới đây là danh sách gói gợi ý để đưa vào profile configs/nexus/packages.*. Tôi đã phân loại REQUIRED, RECOMMENDED, OPTIONAL / HEAVY, AUR / CUSTOM để bạn dễ chọn.

1) Hệ thống lõi (REQUIRED) 🔧
base
linux-hardened (hoặc linux)
linux-headers
systemd (có sẵn)
efibootmgr
sbctl (Secure Boot helper)
pacman archlinux-keyring pacman-contrib
sudo networkmanager dhcpcd
bash coreutils grep sed awk
2) Filesystem / Encryption / Boot (REQUIRED → RECOMMENDED) 🔐
btrfs-progs
snapper / timeshift (snapshots)
cryptsetup (LUKS2)
lvm2
tpm2-tools (TPM support)
grub (legacy support) — tùy cần
3) Boot security & signing (RECOMMENDED) 🔒
sbsigntools
efitools
sbctl (nếu chưa thêm ở trên)
4) Networking & Privacy (RECOMMENDED) 🌐
wireguard-tools
openresolv / systemd-resolved
openvpn
tor torsocks
cloudflared (DoH client)
dnscrypt-proxy (option)
Ghi chú: Post-quantum WireGuard KEM là experimental — có thể cần build / patch riêng (AUR / custom).

5) Container / Isolation / Sandboxing (RECOMMENDED) 🐳
podman
distrobox (AUR helper or simple script)
bubblewrap firejail (sandboxing)
6) Pentest & Recon (RECOMMENDED → OPTIONAL) 🧰
nmap masscan
rustscan (AUR)
tcpdump wireshark-qt or wireshark-cli
netdiscover zmap gobuster dirb nikto
sqlmap hydra john hashcat (hashcat heavy, GPU drivers optional)
aircrack-ng ettercap
Optional/Heavy: metasploit-framework (AUR / external package), openvas/gvm (large)
7) AI / ML / LLM (RECOMMENDED / AUR/CUSTOM) 🤖
python python-pip onnxruntime onnx
llama.cpp (AUR) or ggml-based runtimes (AUR/custom)
ffmpeg (for multimedia tasks)
ollama (not in official repos — PKGBUILD required / custom packaging)
Tooling scripts: model manager (in repo, not package)
Ghi chú: model binaries không nằm trong ISO — chỉ client/runtime. Model storage và conversion (GGUF/GPTQ) sẽ được quản lý bằng scripts.

8) eBPF & Runtime Security (RECOMMENDED) 🐶
falco (repo or package)
bpftrace
audit auditd
wazuh-agent / ossec (AUR or upstream packages)
9) Desktop / Wayland / KDE (OPTIONAL) 🖥️
plasma plasma-desktop kde-applications sddm (KDE)
sway wlroots wayland pipewire wireplumber mako grim slurp (tiling/Wayland)
xorg-server (if X11 support needed)
10) Dev & Packaging (RECOMMENDED) 🛠️
git base-devel python python-virtualenv rust go gcc cmake make
pkgfile repo-add (from pacman-contrib) for internal repo
11) Virtualization & Testing (RECOMMENDED) 🧪
qemu virt-manager libvirt virt-viewer bridge-utils dnsmasq
12) Utilities & Security UX (RECOMMENDED) ✅
openssh rsync curl wget jq htop neofetch gnupg keepassxc pass
fprintd pam modules (fingerprint), howdy (AUR) optional
ufw / nftables fail2ban
13) SDR & RF (OPTIONAL / HEAVY) 📡
gnuradio gqrx gr-osmosdr (heavy deps)
14) Monitoring, Logging, Telemetry (RECOMMENDED) 📊
rsyslog / journald (systemd)
prometheus-node-exporter (optional)
grafana (optional, heavy)
15) Packages cần tạo / PKGBUILD (AUR or custom) 🔧
ollama (client/installer) — custom PKGBUILD
rustscan (AUR)
metasploit-framework (AUR/packaging)
wireguard-postquantum (POC; custom)
wazuh-agent (may require non-official repo)
Any internal tools: nexus-recon, cerberus, model-manager → create PKGBUILDs and host in internal repo
Tổ chức file packages (gợi ý) 🗂️
packages.base — core + fs + boot
packages.pentest — pentest tools (opt-in)
packages.ai — ai runtimes & libs
packages.desktop — KDE / sway / GUI
packages.aur — list of AUR/custom pkgs with PKGBUILD pointers
Important: một số package nặng (models, hashcat GPU drivers, openvas, metasploit DB) không nên được đưa thẳng vào ISO — để làm optional hoặc cài sau từ repo/internal mirror.