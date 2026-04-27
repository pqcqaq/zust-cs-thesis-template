#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

FRONTMATTER=1
NODE_ARGS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output|-o)
      [[ "$#" -ge 2 ]] || { echo "--output requires a path" >&2; exit 2; }
      NODE_ARGS+=("--output" "$2")
      shift 2
      ;;
    --skip-mermaid)
      NODE_ARGS+=("--skip-mermaid")
      shift
      ;;
    --force-mermaid)
      NODE_ARGS+=("--force-mermaid")
      shift
      ;;
    --keep-temp)
      NODE_ARGS+=("--keep-temp")
      shift
      ;;
    --no-frontmatter)
      FRONTMATTER=0
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/build-docx.sh [options]

Options:
  --output, -o <path>  Output DOCX path. Default: dist/<thesis-title>.docx
  --skip-mermaid      Skip Mermaid PNG rendering.
  --force-mermaid     Re-render Mermaid PNG files.
  --no-frontmatter    Explicitly build body DOCX only.
  --keep-temp         Keep temporary Pandoc input directory.
  -h, --help          Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v node >/dev/null 2>&1; then
  echo "node not found. Install Node.js, then retry." >&2
  exit 1
fi

if [[ "$FRONTMATTER" -eq 1 ]]; then
  echo "Warning: macOS/Linux DOCX build outputs editable body content only; use PDF for final fixed-page layout." >&2
fi

node "$SCRIPT_DIR/build-docx.mjs" "${NODE_ARGS[@]}"
