#!/bin/bash
# Local Docker-based build script for all AUR packages
# Usage: bash scripts/build_aur_local.sh [output_dir]

set -e

OUTPUT_DIR="${1:-.}"
ARCH_IMAGE="archlinux:latest"
WORKSPACE=$(pwd)

echo "========================================="
echo "Nexus OS Local AUR Package Builder"
echo "========================================="
echo "Output directory: $OUTPUT_DIR"
echo "Workspace: $WORKSPACE"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR/packages"
mkdir -p "$OUTPUT_DIR/logs"

# Count packages
PACKAGE_COUNT=$(find packaging/aur -maxdepth 1 -type d ! -name aur | wc -l)
echo "Found $PACKAGE_COUNT packages to build."
echo ""

# Build each package
BUILD_SUCCESS=0
BUILD_FAILED=0
FAILED_PACKAGES=()

for pkgdir in packaging/aur/*/; do
  pkgname=$(basename "$pkgdir")
  logfile="$OUTPUT_DIR/logs/${pkgname}.log"
  
  if [ ! -f "$pkgdir/PKGBUILD" ]; then
    echo "⊘ SKIP $pkgname (no PKGBUILD)"
    continue
  fi
  
  echo "Building $pkgname..."
  
  if docker run --rm \
    -v "$WORKSPACE:/workspace" \
    -v "$WORKSPACE/.pacman_cache:/var/cache/pacman/pkg" \
    -w "/workspace/$pkgdir" \
    "$ARCH_IMAGE" \
    bash -c "pacman -Sy --noconfirm --needed base-devel git curl wget unzip p7zip >/dev/null 2>&1; useradd -m -s /bin/bash builduser 2>/dev/null; echo 'builduser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/builduser; chmod 440 /etc/sudoers.d/builduser; chown -R builduser:builduser /workspace/$pkgdir 2>/dev/null; su builduser -c 'cd /workspace/$pkgdir && makepkg -f --noconfirm --syncdeps' 2>&1" > "$logfile" 2>&1; then
    
    # Move artifacts to output
    pkgfiles=$(ls "$pkgdir"*.pkg.tar.* 2>/dev/null || echo "")
    if [ -n "$pkgfiles" ]; then
      cp "$pkgdir"*.pkg.tar.* "$OUTPUT_DIR/packages/" 2>/dev/null || true
      echo "✓ OK $pkgname"
      ((BUILD_SUCCESS++))
    else
      echo "⚠ WARN $pkgname (no artifact, see $logfile)"
      ((BUILD_FAILED++))
      FAILED_PACKAGES+=("$pkgname")
    fi
  else
    echo "✗ FAIL $pkgname (build error, see $logfile)"
    ((BUILD_FAILED++))
    FAILED_PACKAGES+=("$pkgname")
  fi
done

echo ""
echo "========================================="
echo "Build Summary"
echo "========================================="
echo "Success: $BUILD_SUCCESS"
echo "Failed: $BUILD_FAILED"
if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
  echo "Failed packages:"
  for pkg in "${FAILED_PACKAGES[@]}"; do
    echo "  - $pkg"
  done
fi
echo ""
echo "Artifacts: $OUTPUT_DIR/packages/"
echo "Logs: $OUTPUT_DIR/logs/"
echo ""
echo "To install a package:"
echo "  sudo pacman -U $OUTPUT_DIR/packages/<pkgname>-<version>-<arch>.pkg.tar.*"
echo ""

# Update Repository
if [ -f "scripts/create_repo.sh" ]; then
    echo "Updating local repository..."
    bash scripts/create_repo.sh "$OUTPUT_DIR/repo" "nexus-core"
fi

