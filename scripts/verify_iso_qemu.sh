#!/usr/bin/env bash
# Verify Nexus OS ISO boots in QEMU.
# Usage: ./scripts/verify_iso_qemu.sh [path/to/nexus-*.iso]
# Requires: qemu-system-x86_64 (and optionally UEFI: edk2-ovmf on Arch)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_PATH="${1:-}"

if [ -z "$ISO_PATH" ]; then
  # Default: latest ISO in build_output
  if [ -d "$REPO_ROOT/build_output" ]; then
    ISO_PATH="$(find "$REPO_ROOT/build_output" -maxdepth 2 -name "*.iso" -type f 2>/dev/null | head -1)"
  fi
  if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    echo "Usage: $0 <path/to/nexus-*.iso>"
    echo "  or run from repo with build_output/*.iso present."
    exit 1
  fi
fi

if [ ! -f "$ISO_PATH" ]; then
  echo "Error: ISO not found: $ISO_PATH"
  exit 1
fi

echo "========================================="
echo "Nexus OS - ISO boot verify (QEMU)"
echo "========================================="
echo "ISO: $ISO_PATH"
echo "Stop: close the QEMU window or press Ctrl+Alt+G then type 'quit'."
echo ""

# Prefer UEFI if OVMF is available (Arch: edk2-ovmf)
QEMU_EXTRA=()
if command -v qemu-system-x86_64 &>/dev/null; then
  for ovmf in /usr/share/edk2-ovmf/x64/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd; do
    if [ -f "$ovmf" ]; then
      QEMU_EXTRA+=(-bios "$ovmf")
      break
    fi
  done
  qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -boot d \
    "${QEMU_EXTRA[@]}"
else
  echo "Error: qemu-system-x86_64 not found. Install qemu (and optionally edk2-ovmf)."
  exit 1
fi
