#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTMATTER_DIR="$PROJECT_ROOT/frontmatter"
MANIFEST="$FRONTMATTER_DIR/frontmatter.json"

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
Usage: ./scripts/export-frontmatter.sh [options]

Options:
  --force           Re-export fixed pages even when PDFs look up to date.
  --quiet           Reduce output.
  --allow-fallback  Warn and continue when LibreOffice is unavailable.
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

if [[ ! -f "$MANIFEST" ]]; then
  echo "Frontmatter manifest not found: $MANIFEST" >&2
  exit 1
fi

SOFFICE=""
for candidate in soffice libreoffice; do
  if command -v "$candidate" >/dev/null 2>&1; then
    SOFFICE="$(command -v "$candidate")"
    break
  fi
done

if [[ -z "$SOFFICE" ]]; then
  message="LibreOffice/soffice not found; fixed Word pages cannot be exported on this platform."
  if [[ "$ALLOW_FALLBACK" -eq 1 ]]; then
    echo "Warning: $message" >&2
    echo "Warning: LaTeX fallback pages will be used if frontmatter PDFs are missing." >&2
    exit 0
  fi
  echo "$message" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found; cannot read frontmatter/frontmatter.json." >&2
  exit 1
fi

while IFS=$'\t' read -r source_rel target_rel; do
  [[ -n "$source_rel" ]] || continue
  source_path="$FRONTMATTER_DIR/$source_rel"
  target_path="$FRONTMATTER_DIR/$target_rel"
  target_dir="$(dirname "$target_path")"

  if [[ ! -f "$source_path" ]]; then
    echo "Frontmatter source not found: $source_path" >&2
    exit 1
  fi

  if [[ "$FORCE" -eq 0 && -f "$target_path" && "$target_path" -nt "$source_path" ]]; then
    log "[frontmatter] up to date: $(basename "$target_path")"
    continue
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  log "[frontmatter] export: $(basename "$source_path") -> $(basename "$target_path")"
  "$SOFFICE" --headless --convert-to pdf --outdir "$tmp_dir" "$source_path" >/dev/null

  converted="$tmp_dir/$(basename "${source_path%.*}").pdf"
  if [[ ! -f "$converted" ]]; then
    echo "LibreOffice did not produce expected PDF: $converted" >&2
    exit 1
  fi

  mkdir -p "$target_dir"
  mv "$converted" "$target_path"
  rm -rf "$tmp_dir"
  trap - EXIT
done < <(python3 - "$MANIFEST" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
data = json.loads(manifest.read_text(encoding="utf-8"))
for page in data.get("pages", []):
    print(f"{page['source']}\t{page['target']}")
PY
)
