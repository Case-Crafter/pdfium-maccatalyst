#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/version.sh"

# This script configures and syncs the PDFium source repo
# It assumes depot_tools is already in your PATH

# Create a working directory
mkdir -p "$ROOT/pdfium-source"
cd "$ROOT/pdfium-source"

# Pin to a PDFium release branch. Tracking main means gclient sync eventually
# moves the source out from under the patches in patches/.
gclient config --name pdfium "https://pdfium.googlesource.com/pdfium.git@$PDFIUM_REF"


# Sync dependencies with gclient
gclient sync