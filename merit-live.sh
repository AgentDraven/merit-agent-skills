#!/usr/bin/env bash
# merit-live.sh - deprecated bash wrapper for merit-live.ps1.
set -euo pipefail

echo "DEPRECATED: use ./merit.sh. merit-live.sh is scheduled for removal before GA." >&2

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$ROOT/merit-live.ps1" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/merit-live.ps1" "$@"
fi

echo "merit-live.sh: requires pwsh or powershell" >&2
exit 1
