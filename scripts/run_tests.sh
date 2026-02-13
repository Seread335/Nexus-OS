#!/usr/bin/env bash
# Run unit tests for Nexus OS (Cerberus, nexus-recon).
# Usage: ./scripts/run_tests.sh [pytest options, e.g. -v --durations=5]

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
export PYTHONPATH="${PYTHONPATH:-}:$REPO_ROOT/src"
if command -v pytest >/dev/null 2>&1; then
  exec pytest tests/ "$@"
fi
# Fallback: python -m pytest
exec python -m pytest tests/ "$@"
