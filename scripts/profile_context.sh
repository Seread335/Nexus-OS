#!/usr/bin/env bash
# Quick profile: time GET /api/context (requires Cerberus on 127.0.0.1:9380)
# Usage: ./scripts/profile_context.sh [base_url]

set -euo pipefail
BASE="${1:-http://127.0.0.1:9380}"
echo "Profiling GET ${BASE}/api/context ..."
start=$(date +%s.%N)
size=$(curl -sS --max-time 60 "${BASE}/api/context" | jq -r '.length // 0')
end=$(date +%s.%N)
elapsed=$(echo "$end - $start" | bc 2>/dev/null || echo "?")
echo "Context length: $size bytes"
echo "Time: ${elapsed}s"
