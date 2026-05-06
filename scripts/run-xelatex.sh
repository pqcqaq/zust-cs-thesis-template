#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ "${ZUST_SKIP_LATEX_PREPARE:-}" != "1" ]]; then
  "$SCRIPT_DIR/export-frontmatter.sh" --allow-fallback
  "$SCRIPT_DIR/render-mermaid.sh" --allow-fallback
fi

if ! command -v xelatex >/dev/null 2>&1; then
  echo "xelatex not found. Install MacTeX or TeX Live, then retry." >&2
  exit 1
fi

exec xelatex "$@"
