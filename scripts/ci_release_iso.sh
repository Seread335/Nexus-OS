#!/usr/bin/env bash
set -euo pipefail

# CI helper to sign and prepare ISO release artifacts.
# Expects to run on a runner that has GPG set up or GPG_PRIVATE_KEY provided
# Environment variables:
#  - GPG_PRIVATE_KEY (optional): ASCII-armored private key to import
#  - GPG_PASSPHRASE (optional): passphrase for the imported key
#  - RELEASE_TAG (optional): tag name for the release

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ISO_DIR="$ROOT_DIR/build_output"
OUT_DIR="$ROOT_DIR/build_output/release"
mkdir -p "$OUT_DIR"

ISO_FILE="$(ls -t "$ISO_DIR"/*.iso 2>/dev/null | head -n1 || true)"
if [ -z "$ISO_FILE" ]; then
  echo "No ISO found in $ISO_DIR" >&2
  exit 1
fi

echo "Found ISO: $ISO_FILE"

if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
  echo "Importing GPG key..."
  gpg --batch --import <(printf '%s' "$GPG_PRIVATE_KEY")
fi

BASE="$(basename "$ISO_FILE")"
cp -a "$ISO_FILE" "$OUT_DIR/"
cd "$OUT_DIR"

echo "Generating checksums"
sha256sum "$BASE" > "$BASE".sha256

if command -v gpg >/dev/null 2>&1; then
  echo "Signing ISO"
  if [ -n "${GPG_PASSPHRASE:-}" ]; then
    # Use batch mode with passphrase via GPG_TTY isn't reliable in CI; use --pinentry-mode loopback
    gpg --batch --yes --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" -u "$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')}" --output "$BASE".asc --detach-sig "$BASE" || true
  else
    gpg --batch --yes --output "$BASE".asc --detach-sig "$BASE" || true
  fi
fi

echo "Release artifacts prepared in $OUT_DIR"
ls -la

exit 0
