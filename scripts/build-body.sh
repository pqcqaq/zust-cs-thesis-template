#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "${script_dir}/build-body.ps1" "$@"
fi

if command -v powershell.exe >/dev/null 2>&1; then
  script_path="${script_dir}/build-body.ps1"
  if command -v cygpath >/dev/null 2>&1; then
    script_path="$(cygpath -w "${script_path}")"
  fi
  exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${script_path}" "$@"
fi

printf '%s\n' "PowerShell 7 (pwsh) is required to run scripts/build-body.ps1 on macOS/Linux." >&2
exit 1
