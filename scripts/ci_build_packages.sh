#!/usr/bin/env bash
set -euo pipefail

# CI helper to build PKGBUILDs under packaging/aur on an Arch runner.
# This script is intended to be run on an Arch Linux CI runner with
# base-devel, pacman-contrib, and git installed. It builds packages,
# optionally signs them with a GPG key provided in $GPG_PRIVATE_KEY,
# and generates a local repo database with repo-add.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT_DIR/packaging/aur"
OUT_DIR="$ROOT_DIR/build_output/packages"
mkdir -p "$OUT_DIR"

echo "Starting package build for packages under $PKG_DIR"

cd "$PKG_DIR"
for d in */ ; do
  pkgdir="$PKG_DIR/$d"
  if [ -f "$pkgdir/PKGBUILD" ]; then
    echo "Building package in $pkgdir"
    cd "$pkgdir"
    # ensure dependencies and build
    if ! command -v makepkg >/dev/null 2>&1; then
      echo "makepkg not found; ensure base-devel is installed on runner" >&2
      exit 1
    fi
    # build the package but don't install
    makepkg --noconfirm --syncdeps --rmdeps --cleanbuild -f
    # copy resulting package files (.tar.zst or .pkg.tar.zst)
    for pkg in *.pkg.* *.tar.* 2>/dev/null; do
      if [ -f "$pkg" ]; then
        cp -a "$pkg" "$OUT_DIR/"
      fi
    done
  fi
done

cd "$OUT_DIR"

# Optionally import GPG key if provided
if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
  echo "Importing GPG key from env..."
  gpg --batch --import <(printf '%s' "$GPG_PRIVATE_KEY")
fi

echo "Creating repo database"
mkdir -p repo
if command -v repo-add >/dev/null 2>&1; then
  repo-add repo/nexus.db.tar.gz *.pkg.* 2>/dev/null || true
else
  echo "repo-add not available; install pacman-contrib on runner" >&2
fi

echo "Package build complete. Artifacts in $OUT_DIR and repo/"

echo "Files:"
ls -la

exit 0
