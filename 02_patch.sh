#!/bin/bash -eux

PATCHES="$PWD/patches"
SOURCE="$PWD/pdfium-source/pdfium"
OS="ios"
TARGET_ENVIRONMENT="catalyst"

pushd "${SOURCE}"

# Always apply these for non-emscripten builds
git apply -v "$PATCHES/shared_library.patch"
git apply -v "$PATCHES/public_headers.patch"

# Catalyst-specific (uses the ios path)
git apply -v "$PATCHES/ios_pdfium.patch"

# Create room for large install names
git apply -v "$PATCHES/headerpad.patch"

popd