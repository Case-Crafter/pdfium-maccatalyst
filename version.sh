# Single source of truth for what we build and what we call it. Sourced by
# steps/01_download.sh and steps/04_create_nuget.sh.
#
# PDFIUM_VERSION is the bblanchon.PDFium.macOS release we repackage, and becomes
# the version of the package we produce. PDFIUM_REF is the matching PDFium
# release branch — 154.0.8035 maps to refs/heads/chromium/8035 — so the version
# on the package and the source it was built from always agree.
#
# To move to a newer PDFium, bump PDFIUM_VERSION. If the patches in patches/
# stop applying, regenerate them against the new branch.

PDFIUM_VERSION="${PDFIUM_VERSION:-154.0.8035}"
PDFIUM_REF="${PDFIUM_REF:-refs/heads/chromium/${PDFIUM_VERSION##*.}}"
