#!/usr/bin/env bash
# Merit-Hub — delegates to Merit-Hub.ps1 (requires pwsh or powershell).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1="$DIR/Merit-Hub.ps1"
if [[ ! -f "$PS1" ]]; then
  echo "Missing $PS1" >&2
  exit 1
fi
if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$PS1" "$@"
fi
if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$PS1" "$@"
fi
echo "Need pwsh or powershell for Merit-Hub." >&2
exit 1
