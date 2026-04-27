#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

SKIP_FRONTMATTER=0
SKIP_MERMAID=0
FORCE_FRONTMATTER=0
FORCE_MERMAID=0

for arg in "$@"; do
  case "$arg" in
    --skip-frontmatter) SKIP_FRONTMATTER=1 ;;
    --skip-mermaid) SKIP_MERMAID=1 ;;
    --force-frontmatter) FORCE_FRONTMATTER=1 ;;
    --force-mermaid) FORCE_MERMAID=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/build.sh [options]

Options:
  --skip-frontmatter   Skip Word/LibreOffice fixed-page export.
  --skip-mermaid       Skip Mermaid rendering.
  --force-frontmatter  Re-export fixed pages even when PDFs look up to date.
  --force-mermaid      Re-render Mermaid diagrams even when PDFs look up to date.
  -h, --help           Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$SKIP_FRONTMATTER" -eq 0 ]]; then
  frontmatter_args=(--allow-fallback)
  [[ "$FORCE_FRONTMATTER" -eq 1 ]] && frontmatter_args+=(--force)
  "$SCRIPT_DIR/export-frontmatter.sh" "${frontmatter_args[@]}"
fi

if [[ "$SKIP_MERMAID" -eq 0 ]]; then
  mermaid_args=(--allow-fallback)
  [[ "$FORCE_MERMAID" -eq 1 ]] && mermaid_args+=(--force)
  "$SCRIPT_DIR/render-mermaid.sh" "${mermaid_args[@]}"
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "latexmk not found. Install MacTeX/TeX Live and latexmk, then retry." >&2
  exit 1
fi

WISH_SKIP_LATEX_PREPARE=1 latexmk -xelatex -interaction=nonstopmode -file-line-error main.tex
