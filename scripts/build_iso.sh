#!/usr/bin/env bash
set -euo pipefail

# Build Nexus OS ISO using ArchISO and the custom profile
# Usage: bash scripts/build_iso.sh [output_dir] [work_dir]

OUTPUT_DIR="${1:-./iso_output}"
WORK_DIR="${2:-/tmp/nexus-iso-build}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHISO_DIR="$ROOT_DIR/externals/archiso"
PROFILE_DIR="$ROOT_DIR/externals/archiso/configs/nexus"

echo "========================================="
echo "Nexus OS ISO Builder"
echo "========================================="
echo "Profile: $PROFILE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Work dir: $WORK_DIR"
echo ""

# Check prerequisites
if [ ! -d "$ARCHISO_DIR" ]; then
  echo "Error: ArchISO not found at $ARCHISO_DIR"
  echo "Please ensure externals/archiso is cloned."
  exit 1
fi

if [ ! -d "$PROFILE_DIR" ]; then
  echo "Error: Profile not found at $PROFILE_DIR"
  exit 1
fi

if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "Error: mkarchiso not found. Please install archiso:"
  echo "  sudo pacman -S archiso"
  exit 1
fi

# Ensure output directory
mkdir -p "$OUTPUT_DIR"

echo "[1/3] Validating profile structure..."
for file in profiledef.sh packages.x86_64 airootfs; do
  if [ ! -e "$PROFILE_DIR/$file" ]; then
    echo "Warning: Missing $file in profile (may be optional)"
  fi
done

echo "[2/3] Building ISO..."
cd "$ARCHISO_DIR" || exit 1
if sudo mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" "$PROFILE_DIR"; then
  echo "ISO build successful"
else
  echo "ISO build failed; check $WORK_DIR for logs"
  exit 1
fi

echo "[3/3] Finalizing..."
ISO_FILE=$(ls -t "$OUTPUT_DIR"/*.iso 2>/dev/null | head -n1 || echo "")
if [ -n "$ISO_FILE" ]; then
  SIZE=$(du -h "$ISO_FILE" | cut -f1)
  echo "✓ ISO created: $ISO_FILE ($SIZE)"
  echo ""
  echo "To test with QEMU:"
  echo "  qemu-system-x86_64 -cdrom $ISO_FILE -m 2048 -smp 2"
  echo ""
  echo "To write to USB:"
  echo "  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M conv=fsync"
else
  echo "Error: No ISO file created"
  exit 1
fi
