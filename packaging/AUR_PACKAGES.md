# AUR / Custom Packages Needed

This file lists packages referenced in `packages.pentest` (or others) that are not necessarily in the official Arch repositories and will need PKGBUILDs, AUR packaging, or vendor packaging.

- rustscan
- wpscan
- burpsuite (commercial distribution; consider community edition)
- afl++
- hashcat
- ophcrack
- airgeddon
- fluxion
- bettercap
- amass
- waybackurls
- subfinder
- bulk_extractor
- autopsy
- ghidra
- radamsa
- ropper
- ropgadget
- setoolkit
- empire
- seclists
- wordlists / rockyou
- openvas (gvm)
- masscan-utils
- subjack
- httprobe

For each, create a PKGBUILD under `packaging/aur/` and test builds in an isolated chroot or CI runner.
