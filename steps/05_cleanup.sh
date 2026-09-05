#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Leaves the repo with just the scripts: removes the NuGet scratch folder and
# the PDFium checkout. The next run therefore re-syncs and rebuilds from
# scratch — nothing is reused.

cleaned=0
for dir in "$ROOT/nuget-work" "$ROOT/pdfium-source"; do
  if [[ -d "$dir" ]]; then
    echo "Removing $dir ($(du -sh "$dir" | cut -f1))"
    rm -rf "$dir"
    cleaned=1
  fi
done

[[ $cleaned == 1 ]] || echo "Nothing to clean."
