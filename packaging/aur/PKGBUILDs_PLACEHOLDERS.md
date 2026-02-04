# PKGBUILD placeholders

Create a directory per package under `packaging/aur/` and place a tested `PKGBUILD` there. Example placeholder list:

- packaging/aur/metasploit-framework/PKGBUILD
- packaging/aur/hashcat/PKGBUILD
- packaging/aur/rustscan/PKGBUILD
- packaging/aur/openvas/PKGBUILD
- packaging/aur/ghidra/PKGBUILD

Add CI job to build these PKGBUILDs and publish to the internal repo if build succeeds.
