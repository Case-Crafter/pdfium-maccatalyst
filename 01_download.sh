#!/bin/bash
set -euo pipefail

# This script configures and syncs the PDFium source repo
# It assumes depot_tools is already in your PATH

# Create a working directory
mkdir -p pdfium-source
cd pdfium-source

# Configure gclient for an unmanaged PDFium checkout
gclient config --name pdfium --unmanaged https://pdfium.googlesource.com/pdfium.git


# Sync dependencies with gclient
gclient sync