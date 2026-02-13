#!/usr/bin/env bash
set -euo pipefail

# Scripts to create/update a local pacman repository
# Usage: bash scripts/create_repo.sh [repo_dir] [repo_name]

REPO_DIR="${1:-build_output/repo}"
REPO_NAME="${2:-nexus-core}"
GPG_KEY="${GPG_KEY:-}" # Optional: Pass GPG key ID env var to sign repo (supply chain security)

if [ -z "$GPG_KEY" ]; then
  echo "Note: GPG_KEY not set — repo will be unsigned. To sign: export GPG_KEY=0xYOUR_KEY_ID"
  echo "      See docs/SECURITY.md for package signing."
fi
echo "========================================="
echo "Nexus OS - Repository Manager"
echo "========================================="
echo "Repo: $REPO_DIR/$REPO_NAME.db.tar.zst"

mkdir -p "$REPO_DIR"

# Find all built packages in build_output/packages (recursively or flat)
# We assume build_aur_local.sh puts them in build_output/packages
PKG_SOURCE="build_output/packages"

if [ ! -d "$PKG_SOURCE" ]; then
    echo "Error: No package source directory found at $PKG_SOURCE"
    echo "Run scripts/build_aur_local.sh first."
    exit 1
fi

echo "[1/2] Finding packages..."
# Copy all .pkg.tar.zst files to the repo dir to stabilize them
find "$PKG_SOURCE" -name "*.pkg.tar.zst" -exec cp -v {} "$REPO_DIR/" \;

cd "$REPO_DIR"

echo "[2/2] Updating repository database..."
REPO_ADD_ARGS=("--new" "--remove" "--prevent-downgrade")

if [ -n "$GPG_KEY" ]; then
    echo "Signing enabled with key: $GPG_KEY"
    REPO_ADD_ARGS+=("--sign" "--key" "$GPG_KEY")
fi

# Add all packages in current dir to the repo db
# We use *.pkg.tar.zst
PACKAGES=(*.pkg.tar.zst)

if [ ${#PACKAGES[@]} -eq 0 ] || [ ! -f "${PACKAGES[0]}" ]; then
     echo "No packages found to add."
else
     repo-add "${REPO_ADD_ARGS[@]}" "$REPO_NAME.db.tar.zst" "${PACKAGES[@]}"
     echo "Repository updated successfully."
fi

echo ""
# Generate helper pacman.d config snippet
CONF_SNIPPET="$REPO_DIR/${REPO_NAME}.pacman.d.conf"
cat > "$CONF_SNIPPET" <<EOF
[$REPO_NAME]
SigLevel = Optional TrustAll
Server = file://$(pwd)
EOF

echo "Helper config written to: $CONF_SNIPPET"
echo ""
echo "To use this repository on a system, you can either:"
echo "  1) Append the following to /etc/pacman.conf:"
echo ""
cat "$CONF_SNIPPET"
echo ""
echo "  2) Or copy the file into /etc/pacman.d/ and include it from pacman.conf:"
echo "       sudo cp \"$CONF_SNIPPET\" /etc/pacman.d/"
echo "       # then add in /etc/pacman.conf:"
echo "       # Include = /etc/pacman.d/${REPO_NAME}.pacman.d.conf"
echo ""
