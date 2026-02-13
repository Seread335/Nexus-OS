# ISO Build Guide (Nexus profile)

## Prerequisites
- Running on an Arch Linux host (recommended) with `archiso` build dependencies installed.
- Enough free disk space (recommend 20-40 GB for development builds).

## Quick build

From repository root:

```bash
# make script executable once
chmod +x scripts/build_iso.sh
# run build wrapper
./scripts/build_iso.sh
```

If the wrapper fails, inspect `externals/archiso/README` and run the recommended `./build.sh` invocation for your archiso version. Typical usage is:

```bash
cd externals/archiso
./build.sh -v nexus
```

## Profile files
- `externals/archiso/configs/nexus/packages.x86_64` — package list for image
- `externals/archiso/configs/nexus/airootfs/` — overlay files

## Verify ISO boot (QEMU)

After building, verify the ISO boots:

```bash
# From repo root (uses first .iso found in build_output if no arg)
./scripts/verify_iso_qemu.sh

# Or specify ISO path
./scripts/verify_iso_qemu.sh build_output/nexus-YYYY.MM.DD-x86_64.iso
```

Requires: `qemu-system-x86_64` (and optionally `edk2-ovmf` for UEFI). On Arch: `pacman -S qemu-base edk2-ovmf`.

**Checklist:** See **docs/ISO_VERIFY_CHECKLIST.md** for full boot + Cerberus + nexus-recon verify steps.

## Notes
- Some packages (kernel variants, rustscan, specialized tools) may require AUR or extra repos.
- Secure Boot and signing is a later step (see ROADMAP M5).
- Test the ISO with QEMU or VirtualBox before bare-metal.
