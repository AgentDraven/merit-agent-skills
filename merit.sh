#!/usr/bin/env bash
# merit.sh — bash wrapper for merit.ps1.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$ROOT/merit.ps1" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/merit.ps1" "$@"
fi

echo "merit.sh: requires pwsh or powershell" >&2
exit 1
