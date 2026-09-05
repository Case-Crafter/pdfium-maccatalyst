#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# Runs the whole pipeline: download, patch and build PDFium for Mac Catalyst
# (arm64 + x64), then repackage bblanchon.PDFium.macOS as
# bblanchon.PDFium.MacCatalyst with our own dylibs.
# See ../CaseCrafter/CCPdf/README.md.
#
# Usage: ./build_and_create_nuget.sh [macOS-nuget-version]   (default: see version.sh)

OUTPUT_DIR="${OUTPUT_DIR:-/Users/tor/dev/LocalNugetPackages}"
export OUTPUT_DIR
# One version drives both the PDFium branch we build and the package we produce.
if [[ $# -gt 0 ]]; then export PDFIUM_VERSION="$1"; fi
source "$ROOT/version.sh"
BUILD_OUT="$ROOT/pdfium-source/pdfium/out"
START=$SECONDS

step() {
  echo
  echo "──────────────────────────────────────────────────────────────"
  echo "  $1"
  echo "──────────────────────────────────────────────────────────────"
}

echo "Building PDFium for Mac Catalyst and packaging it as a local NuGet."
echo "  checkout : $ROOT/pdfium-source/pdfium"
echo "  packages : $OUTPUT_DIR"
echo "  version  : $PDFIUM_VERSION ($PDFIUM_REF)"

step "1/5  Downloading the PDFium source (gclient sync — slow on a fresh checkout)"
"$ROOT/steps/01_download.sh"

step "2/5  Applying the Mac Catalyst patches"
"$ROOT/steps/02_patch.sh"

step "3/5  Building libpdfium.dylib for arm64 and x64"
"$ROOT/steps/03_build.sh" arm64
"$ROOT/steps/03_build.sh" x64

step "4/5  Creating the local NuGet package"
"$ROOT/steps/04_create_nuget.sh"

# Read while the build output still exists — step 5 deletes the checkout.
ARCHS="$(lipo -archs "$BUILD_OUT/catalyst-arm64/libpdfium.dylib") + $(lipo -archs "$BUILD_OUT/catalyst-x64/libpdfium.dylib")"
PKG="$(ls -t "$OUTPUT_DIR"/bblanchon.PDFium.MacCatalyst.*.nupkg | head -1)"

step "5/5  Cleaning up"
"$ROOT/steps/05_cleanup.sh"

ELAPSED=$((SECONDS - START))

echo
echo "Done in $((ELAPSED / 60))m $((ELAPSED % 60))s."
echo
echo "  Built    libpdfium.dylib for $ARCHS"
echo "  Packed   $PKG  ($(ls -lh "$PKG" | awk "{print \$5}"))"
echo "  Removed  the PDFium checkout and the packaging scratch folder"
echo
echo "Add $OUTPUT_DIR as a NuGet source and reference bblanchon.PDFium.MacCatalyst."
