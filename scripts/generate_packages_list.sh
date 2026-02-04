#!/usr/bin/env bash
set -euo pipefail

# Generate the final packages.x86_64 by concatenating groups in a stable order.
OUT="$(dirname "$0")/../externals/archiso/configs/nexus/packages.x86_64"
ROOT="$(cd "$(dirname "$0")" && pwd)/.."
CONFIGS="$ROOT/externals/archiso/configs/nexus"

# Order: base, system, networking, container, dev, virt, desktop, pentest
cat "$CONFIGS/packages.base" \
    "$CONFIGS/packages.system" \
    "$CONFIGS/packages.networking" \
    "$CONFIGS/packages.container" \
    "$CONFIGS/packages.dev" \
    "$CONFIGS/packages.virt" \
    "$CONFIGS/packages.desktop" \
    "$CONFIGS/packages.pentest" \
  > "$OUT"

# Remove comments and duplicate lines while preserving order
awk '!/^#/ && NF{ if (!seen[$0]++){ print } }' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"

echo "Generated $OUT ($(wc -l < "$OUT") packages)"
