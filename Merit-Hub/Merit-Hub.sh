#!/usr/bin/env bash
set -euo pipefail

# Merit-Hub POSIX launcher. It bootstraps pwsh when absent, then runs the
# canonical Merit-Hub.ps1 with the original arguments.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HUB_PS1="$SCRIPT_DIR/Merit-Hub.ps1"
PWSH_VERSION="${MERIT_PWSH_VERSION:-7.5.2}"
TOOLS_ROOT="${MYMERITTOOLS:-$HOME/Tools}"
PWSH_ROOT="$TOOLS_ROOT/pwsh"

die() {
  printf 'Merit-Hub: ERROR: %s\n' "$*" >&2
  exit 1
}

find_pwsh() {
  if command -v pwsh >/dev/null 2>&1; then
    command -v pwsh
    return 0
  fi
  for candidate in "$PWSH_ROOT/pwsh" "$PWSH_ROOT/pwsh.exe" "$PWSH_ROOT/PowerShell/pwsh"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

download_file() {
  url="$1"
  dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 20 "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$dest" "$url"
  else
    die "curl or wget is required to bootstrap PowerShell 7."
  fi
}

install_portable_pwsh() {
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) asset_arch="x64" ;;
    aarch64|arm64) asset_arch="arm64" ;;
    *) die "Unsupported CPU architecture: $arch" ;;
  esac
  case "$os" in
    linux) asset_os="linux" ;;
    darwin) asset_os="osx" ;;
    *) return 1 ;;
  esac

  archive="PowerShell-$PWSH_VERSION-$asset_os-$asset_arch.tar.gz"
  url="https://github.com/PowerShell/PowerShell/releases/download/v$PWSH_VERSION/$archive"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  mkdir -p "$PWSH_ROOT"
  printf 'Merit-Hub: downloading PowerShell %s to %s\n' "$PWSH_VERSION" "$PWSH_ROOT"
  download_file "$url" "$tmp_dir/$archive"
  tar -xzf "$tmp_dir/$archive" -C "$PWSH_ROOT"
  chmod +x "$PWSH_ROOT/pwsh"
  printf 'Merit-Hub: portable pwsh installed at %s\n' "$PWSH_ROOT/pwsh"
}

pwsh_bin=""
if pwsh_bin="$(find_pwsh)"; then
  :
else
  case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    mingw*|msys*|cygwin*)
      if command -v powershell.exe >/dev/null 2>&1; then
        pwsh_bin="powershell.exe"
      fi
      ;;
  esac
  if [ -z "$pwsh_bin" ]; then
    if [ "${MERIT_HUB_AUTO_INSTALL_PWSH:-0}" = "1" ]; then
      answer="y"
    else
      printf 'Merit-Hub: PowerShell 7 (pwsh) is not installed. Install it locally now? [Y/n] '
      IFS= read -r answer || answer="n"
    fi
    if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy]$ ]]; then
      install_portable_pwsh || die "Could not install PowerShell 7 automatically."
      pwsh_bin="$(find_pwsh)" || die "PowerShell installation completed without a runnable pwsh."
    else
      die "pwsh is required. Re-run and confirm installation, or set MERIT_HUB_AUTO_INSTALL_PWSH=1."
    fi
  fi
fi

if [ ! -f "$HUB_PS1" ]; then
  die "Missing canonical launcher: $HUB_PS1"
fi

export MYMERITTOOLS="$TOOLS_ROOT"
if [ "$pwsh_bin" = "powershell.exe" ] && command -v cygpath >/dev/null 2>&1; then
  HUB_PS1="$(cygpath -w "$HUB_PS1")"
fi
exec "$pwsh_bin" -NoProfile -ExecutionPolicy Bypass -File "$HUB_PS1" "$@"

