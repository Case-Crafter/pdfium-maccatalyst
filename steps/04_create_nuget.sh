#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/version.sh"

# Repackages the bblanchon.PDFium.macOS NuGet as bblanchon.PDFium.MacCatalyst,
# swapping in the dylibs built by 03_build.sh. See ../CaseCrafter/CCPdf/README.md.
#
# Usage: ./steps/04_create_nuget.sh [macOS-nuget-version]   (default: see version.sh)

FEED="https://api.nuget.org/v3-flatcontainer/bblanchon.pdfium.macos"
OUTPUT_DIR="${OUTPUT_DIR:-/Users/tor/dev/LocalNugetPackages}"
WORK="$ROOT/nuget-work"
BUILD_OUT="$ROOT/pdfium-source/pdfium/out"

for arch in arm64 x64; do
  if [[ ! -f "$BUILD_OUT/catalyst-$arch/libpdfium.dylib" ]]; then
    echo "Missing $BUILD_OUT/catalyst-$arch/libpdfium.dylib — run steps/03_build.sh $arch first." >&2
    exit 1
  fi
done

VERSION="${1:-$PDFIUM_VERSION}"
echo "Repackaging bblanchon.PDFium.macOS $VERSION as bblanchon.PDFium.MacCatalyst"

rm -rf "$WORK"
mkdir -p "$WORK"
curl -fsSL "$FEED/$VERSION/bblanchon.pdfium.macos.$VERSION.nupkg" -o "$WORK.nupkg"
unzip -qo "$WORK.nupkg" -d "$WORK"
rm -f "$WORK.nupkg"

# Drop the original package's OPC metadata and signature; nuget pack regenerates them.
rm -rf "$WORK/_rels" "$WORK/package" "$WORK/[Content_Types].xml" "$WORK/.signature.p7s"

sed -i '' 's|<id>bblanchon.PDFium.macOS</id>|<id>bblanchon.PDFium.MacCatalyst</id>|' \
  "$WORK/bblanchon.PDFium.macOS.nuspec"
grep -q '<id>bblanchon.PDFium.MacCatalyst</id>' "$WORK/bblanchon.PDFium.macOS.nuspec"

# osx-<arch> -> maccatalyst-<arch>, with our dylibs in place of bblanchon's.
for arch in arm64 x64; do
  mv "$WORK/runtimes/osx-$arch" "$WORK/runtimes/maccatalyst-$arch"
  cp "$BUILD_OUT/catalyst-$arch/libpdfium.dylib" "$WORK/runtimes/maccatalyst-$arch/native/"
done

# Guard against a stale or mis-copied build landing in the wrong runtime folder.
[[ "$(lipo -archs "$WORK/runtimes/maccatalyst-arm64/native/libpdfium.dylib")" == "arm64" ]]
[[ "$(lipo -archs "$WORK/runtimes/maccatalyst-x64/native/libpdfium.dylib")" == "x86_64" ]]

mkdir -p "$OUTPUT_DIR"
(cd "$WORK" && nuget pack -OutputDirectory "$OUTPUT_DIR" bblanchon.PDFium.macOS.nuspec)

echo "Created $OUTPUT_DIR/bblanchon.PDFium.MacCatalyst.$VERSION.nupkg"
