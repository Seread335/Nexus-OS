#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$(pwd)"

for pkgdir in packaging/aur/*/; do
  pkgname=$(basename "$pkgdir")
  echo "\n=== BUILD: $pkgname ==="
  if [ ! -f "$pkgdir/PKGBUILD" ]; then
    echo "SKIP $pkgname (no PKGBUILD)"
    continue
  fi

  docker run --rm \
    -v "$WORKSPACE":/workspace \
    -v "$WORKSPACE/.pacman_cache":/var/cache/pacman/pkg \
    -w "/workspace/$pkgdir" \
    archlinux:latest \
    bash -lc "set -e; pacman -Sy --noconfirm --needed base-devel git curl wget unzip p7zip >/dev/null 2>&1 || true; useradd -m -s /bin/bash builduser 2>/dev/null || true; echo 'builduser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builduser; chmod 440 /etc/sudoers.d/builduser; chown -R builduser:builduser /workspace/$pkgdir 2>/dev/null || true; su builduser -c 'cd /workspace/$pkgdir && makepkg -f --noconfirm --syncdeps'"

  rc=$?
  echo "Exit code for $pkgname: $rc"
done

echo "\nAll builds attempted. Check build_output/packages and build_output/logs for artifacts and logs."
