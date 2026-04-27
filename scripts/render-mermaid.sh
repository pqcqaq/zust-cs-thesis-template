#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MERMAID_DIR="$PROJECT_ROOT/figures/mermaid"
OUTPUT_DIR="$PROJECT_ROOT/figures/generated"
PUPPETEER_CONFIG="$PROJECT_ROOT/puppeteer-config.json"
MERMAID_CONFIG="$PROJECT_ROOT/mermaid-config.json"

FORCE=0
QUIET=0
ALLOW_FALLBACK=0

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --quiet) QUIET=1 ;;
    --allow-fallback) ALLOW_FALLBACK=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/render-mermaid.sh [options]

Options:
  --force           Re-render all Mermaid diagrams.
  --quiet           Reduce output.
  --allow-fallback  Warn and continue when npx/Mermaid rendering fails.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

log() {
  [[ "$QUIET" -eq 1 ]] || echo "$1"
}

if [[ ! -d "$MERMAID_DIR" ]]; then
  log "[mermaid] no source directory"
  exit 0
fi

shopt -s nullglob
sources=("$MERMAID_DIR"/*.mmd)
shopt -u nullglob

if [[ "${#sources[@]}" -eq 0 ]]; then
  log "[mermaid] no .mmd files"
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  message="npx not found; cannot render Mermaid diagrams"
  if [[ "$ALLOW_FALLBACK" -eq 1 ]]; then
    echo "Warning: $message" >&2
    exit 0
  fi
  echo "$message" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
jobs=()

for source in "${sources[@]}"; do
  base="$(basename "$source" .mmd)"
  target="$OUTPUT_DIR/$base.pdf"
  if [[ "$FORCE" -eq 1 || ! -f "$target" || "$source" -nt "$target" || "$PUPPETEER_CONFIG" -nt "$target" || "$MERMAID_CONFIG" -nt "$target" ]]; then
    jobs+=("$source")
  fi
done

if [[ "${#jobs[@]}" -eq 0 ]]; then
  log "[mermaid] generated PDFs are up to date"
  exit 0
fi

for source in "${jobs[@]}"; do
  base="$(basename "$source" .mmd)"
  target="$OUTPUT_DIR/$base.pdf"
  log "[mermaid] render: $(basename "$source") -> $(basename "$target")"
  if ! npx --yes "@mermaid-js/mermaid-cli" \
    -i "$source" \
    -o "$target" \
    -p "$PUPPETEER_CONFIG" \
    -c "$MERMAID_CONFIG" \
    --pdfFit \
    --backgroundColor white; then
    message="Mermaid rendering failed: $source"
    if [[ "$ALLOW_FALLBACK" -eq 1 ]]; then
      echo "Warning: $message" >&2
    else
      echo "$message" >&2
      exit 1
    fi
  fi
done
