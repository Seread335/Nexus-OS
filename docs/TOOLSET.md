# Nexus OS — Bộ công cụ (50 BlackArch + Arch)

Nexus OS cài sẵn **50 công cụ phổ biến nhất** từ repo **BlackArch** và Arch, nhằm tấn công (red team) và phòng thủ (blue team) cực mạnh.

## Repo BlackArch

- Profile Nexus thêm repo **[blackarch]** trong `pacman.conf` (mirror Team Cymru).
- Build ISO cần kết nối mạng để tải `blackarch-keyring`, `blackarch-mirrorlist` và các gói trong `packages.blackarch`.
- Sau khi cài, có thể cài thêm bất kỳ công cụ nào trong 2800+ tools: `pacman -Ss blackarch` hoặc `pacman -S blackarch-<category>`.

## 50 công cụ cài sẵn (packages.blackarch)

| Nhóm | Công cụ |
|------|---------|
| **Recon & OSINT** | amass, subfinder, theharvester, recon-ng, findomain, dnsenum, dnsrecon, fierce, dmitry, massdns, zdns, zgrab2 |
| **Scanning** | nmap, masscan, zmap, netdiscover, arp-scan, nikto, gobuster, dirb, dirbuster, ffuf, wfuzz, nuclei (+templates), onesixtyone, hping, fping |
| **Web/App** | sqlmap, burpsuite, wpscan, commix, wafw00f, whatweb, zaproxy |
| **Exploit & Post-exploit** | metasploit, exploitdb, crackmapexec, responder, proxychains-ng, pth-toolkit, mimikatz, powersploit |
| **Password & Hash** | hydra, john, hashcat, hashcat-utils, ophcrack, crunch, cewl, hash-identifier, hashid, ncrack |
| **Wireless** | aircrack-ng, reaver, wifite, kismet |
| **MITM & Network** | mitmproxy, dnschef, dns2tcp, sslsplit, sslscan, sslyze |
| **Forensics & Reverse** | binwalk, radare2, bulk-extractor, sleuthkit, foremost, scalpel |
| **Utilities** | seclists, wordlistctl, socat, tcpdump, wireshark-qt, openbsd-netcat |

## Nâng cấp AI (tấn công + phòng thủ)

- **config.yaml** — `ollama.system_prompt`: AI được cấu hình vai trò red team + blue team, gợi ý lệnh cụ thể từ bộ công cụ đã cài.
- **ai_policy.yaml** — `allowed_commands`: mở rộng whitelist (nmap, masscan, sqlmap, hydra, metasploit, nuclei, responder, crackmapexec, burpsuite, radare2, …) để AI có thể gợi ý hoặc (khi triển khai bước sau) thực thi có xác nhận.
- Khi gọi **Cerberus** `POST /api/ask` với `include_context: true`, AI nhìn full system (process, network, logs) và trả lời theo hướng tấn công/phòng thủ, kèm lệnh gợi ý.

## Build ISO có BlackArch

1. Đảm bảo `pacman.conf` trong profile có `[blackarch]` và `Server = https://mirror.team-cymru.com/blackarch/$repo/os/$arch`.
2. Chạy `scripts/generate_packages_list.sh` để nối `packages.blackarch` vào `packages.x86_64`.
3. Build: `bash scripts/build_iso.sh ./iso_output` (cần mạng để pacman tải BlackArch packages).
4. Nếu mirror lỗi hoặc chậm, đổi `Server` trong `pacman.conf` sang mirror khác: https://blackarch.org/downloads.html (Mirror Sites).

## Thêm công cụ sau khi cài

- Cài một tool: `sudo pacman -S <tên-gói>` (vd. `sudo pacman -S sqlmap` nếu chưa có).
- Cài cả nhóm BlackArch: `sudo pacman -Sg | grep blackarch` (xem nhóm), rồi `sudo pacman -S blackarch-webapp` (vd.).
