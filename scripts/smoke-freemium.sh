#!/usr/bin/env bash
# smoke-freemium.sh — bash wrapper for smoke-freemium.ps1.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$ROOT/scripts/smoke-freemium.ps1" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/smoke-freemium.ps1" "$@"
fi

echo "smoke-freemium.sh: requires pwsh or powershell" >&2
exit 1
