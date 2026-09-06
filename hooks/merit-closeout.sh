#!/usr/bin/env bash
set -u
input="$(cat 2>/dev/null || true)"
if printf '%s' "$input" | grep -Eqi 'stop_hook_active[^a-zA-Z0-9]*(true|1)'; then
  printf '%s\n' '{"continue":true,"systemMessage":"MERIT stop-hook recursion guard: validation reminder already issued."}'
  exit 0
fi
repo="${MERIT_REPO_PATH:-${PWD}}"
cli="${MERIT_CLI_PATH:-$repo/merit-agent-skills/merit.ps1}"
if [ ! -f "$cli" ]; then
  printf '%s\n' '{"continue":true,"systemMessage":"MERIT closeout hook could not locate merit.ps1; guidance-only warning."}'
  exit 0
fi
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$cli" law closeout >/dev/null 2>&1 || true
  pwsh -NoProfile -File "$cli" closeout --path "$repo" --validate-only >/dev/null 2>&1
  code=$?
else
  printf '%s\n' '{"continue":true,"systemMessage":"MERIT closeout hook requires pwsh; run merit.ps1 manually."}'
  exit 0
fi
if [ "$code" -eq 0 ]; then
  printf '%s\n' '{"continue":true,"systemMessage":"MERIT closeout validation passed. End with 3-3: Done, State, Next."}'
else
  printf '%s\n' '{"continue":false,"stopReason":"MERIT closeout validation failed; inspect the closeout receipt and remediate before ending."}'
  exit 2
fi
