#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

rm -f \
  main.aux \
  main.fdb_latexmk \
  main.fls \
  main.log \
  main.out \
  main.toc \
  main.xdv \
  main.synctex.gz

echo "Cleaned LaTeX temporary files. main.pdf and generated figures were preserved."
