#!/usr/bin/env bash
# Run local security checks: tests + gitleaks (if available)
set -euo pipefail
echo "Running pytest..."
python -m pytest -q
if command -v gitleaks >/dev/null 2>&1; then
  echo "Running gitleaks detect..."
  mkdir -p build_output
  gitleaks detect --report-format=json --redact --report-path=build_output/gitleaks-report.json || true
  echo "gitleaks report: build_output/gitleaks-report.json"
else
  echo "gitleaks not found; to install: https://github.com/gitleaks/gitleaks#installation"
fi
