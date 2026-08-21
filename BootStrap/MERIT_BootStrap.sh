#!/usr/bin/env bash
# MERIT_BootStrap launcher (OSS). Does NOT replace repo-root ../merit.ps1 CLI.
# Prefer pwsh (PowerShell 7+); fall back to Windows PowerShell 5.1.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$ROOT/MERIT_BootStrap.ps1"

if [[ ! -f "$SCRIPT" ]]; then
  echo "MERIT_BootStrap: MERIT_BootStrap.ps1 not found at $SCRIPT" >&2
  exit 1
fi

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$SCRIPT" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  echo "MERIT_BootStrap: pwsh not found; using Windows PowerShell 5.1" >&2
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT" "$@"
fi

echo "MERIT_BootStrap: requires pwsh or powershell" >&2
exit 1
