#!/usr/bin/env bash
set -euo pipefail

# Wrapper script to build the Nexus profile using the cloned archiso repo.
# Note: archiso's exact build flags vary by release. This script attempts
# common commands and prints guidance if they fail.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHISO_DIR="$ROOT_DIR/externals/archiso"
PROFILE_NAME="nexus"

if [ ! -d "$ARCHISO_DIR" ]; then
  echo "archiso directory not found at $ARCHISO_DIR"
  exit 1
fi

cd "$ARCHISO_DIR"

echo "Building ArchISO profile: $PROFILE_NAME"
# Preferred: build.sh takes a profile name (older/newer versions vary)
if ./build.sh -v "$PROFILE_NAME"; then
  echo "Build finished (profile $PROFILE_NAME)"
  exit 0
fi

# Fallback: try building by pointing to configs/
if ./build.sh -v -c "configs/$PROFILE_NAME"; then
  echo "Build finished (configs/$PROFILE_NAME)"
  exit 0
fi

echo "Automatic build commands failed. Inspect $ARCHISO_DIR/README for exact usage." 
exit 1
