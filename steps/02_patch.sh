#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PATCHES="$ROOT/patches"
SOURCE="$ROOT/pdfium-source/pdfium"

# Order matters: headerpad.patch edits BUILD.gn after shared_library.patch.
for name in shared_library public_headers ios_pdfium headerpad; do
  patch="$PATCHES/$name.patch"
  if git -C "$SOURCE" apply --reverse --check "$patch" 2>/dev/null; then
    echo "already applied: $name.patch"
  else
    echo "applying: $name.patch"
    git -C "$SOURCE" apply -v "$patch"
  fi
done
