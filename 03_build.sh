#!/bin/bash
set -e

# Check for optional clean flag
CLEAN=false
if [[ "$1" == "--clean" ]]; then
  CLEAN=true
  shift
fi

# Configurable build params
ARCH=$1       # arm64 or x64
BUILD_DIR="out/catalyst-$ARCH"
SOURCE_DIR="$PWD/pdfium-source/pdfium"

# Validate input
if [[ "$ARCH" != "arm64" && "$ARCH" != "x64" ]]; then
  echo "Usage: $0 [--clean] [arm64|x64]"
  exit 1
fi

# Clean build directory if requested
if $CLEAN && [[ -d "$SOURCE_DIR/$BUILD_DIR" ]]; then
  echo "Cleaning build directory $BUILD_DIR..."
  rm -rf "$SOURCE_DIR/$BUILD_DIR"
fi

# Set up GN args
GN_ARGS="
target_os=\"ios\"
target_cpu=\"$ARCH\"
target_environment=\"catalyst\"
ios_enable_code_signing=false
is_component_build=false
use_xcode_clang=true
is_debug=false
pdf_is_standalone=true
pdf_enable_v8=false
pdf_enable_xfa=false
pdf_use_skia=false
use_blink=true
pdf_use_partition_alloc=false
clang_use_chrome_plugins=false
use_sysroot=false
symbol_level=0
"

# Change to source dir
cd "$SOURCE_DIR"

# Generate build config
echo "Generating GN config for $ARCH..."
gn gen "$BUILD_DIR" --args="$GN_ARGS"

# Build PDFium
echo "Building PDFium for $ARCH..."
ninja -C "$BUILD_DIR" pdfium

echo "✅ Build complete: $BUILD_DIR/libpdfium.dylib (or .a)"
