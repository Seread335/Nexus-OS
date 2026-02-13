#!/usr/bin/env bash
# Generate a secure token for Cerberus and print export command.
set -euo pipefail
if command -v openssl >/dev/null 2>&1; then
  token=$(openssl rand -hex 32)
else
  # Fallback to Python
  token=$(python - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
)
fi
cat <<EOF
# Cerberus auth token (keep secret)
CERBERUS_AUTH_TOKEN=${token}
# Example to set in systemd unit or environment:
# export CERBERUS_AUTH_TOKEN=${token}
EOF
chmod 600 "$0"
