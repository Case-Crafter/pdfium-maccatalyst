# pdfium-maccatalyst

Scripts for building PDFium for Mac Catalyst (arm64 and x64) and packaging the
result as a local NuGet for use by [CCPdf](../CaseCrafter/CCPdf).

## Usage

```
./build_and_create_nuget.sh [macOS-nuget-version]
```

That is the only command you need. It runs all five steps in `steps/`:
downloads the PDFium source, patches it, builds `libpdfium.dylib` for arm64 and
x64, repackages the upstream `bblanchon.PDFium.macOS` NuGet as
`bblanchon.PDFium.MacCatalyst` with our own dylibs, and deletes everything it
downloaded on the way.

The optional argument selects which release to build. It sets both the
`bblanchon.PDFium.macOS` package we repackage and the PDFium release branch we
build from — see [Versioning](#versioning) — so the version on the package
always matches the source it was built from. Without it, the version pinned in
`version.sh` is used.

### Output

One file, written to `/Users/tor/dev/LocalNugetPackages`:

```
bblanchon.PDFium.MacCatalyst.<version>.nupkg
```

Set `OUTPUT_DIR` to write it somewhere else:

```
OUTPUT_DIR=~/packages ./build_and_create_nuget.sh
```

Add that folder as a NuGet source and reference `bblanchon.PDFium.MacCatalyst`.

Nothing else is left behind — step 5 removes the PDFium checkout and the
packaging scratch folder, so a re-run always starts from a clean slate and
re-downloads and rebuilds everything (15-25 minutes).

### Requirements

`depot_tools` on your `PATH` (for `gclient` and `gn`), Xcode, `ninja`, `nuget`
(from Mono) and `curl`.

### Versioning

`version.sh` holds the one constant that drives the build:

```
PDFIUM_VERSION=154.0.8035        # the bblanchon.PDFium.macOS release we repackage
PDFIUM_REF=refs/heads/chromium/8035   # the matching PDFium release branch
```

PDFium's release branches follow the same numbering as bblanchon's packages, so
`PDFIUM_REF` is derived from `PDFIUM_VERSION` and the two cannot drift apart.

To move to a newer PDFium, bump `PDFIUM_VERSION`. The checkout is pinned rather
than tracking `main` on purpose: upstream moves fast enough to break the patches
in `patches/`, which is exactly what happens if the pin is removed. After a
bump, if `02_patch.sh` reports that a patch no longer applies, regenerate that
patch against the new branch.

## The steps

Each script in `steps/` is independently runnable and can be called from any
directory — they locate the repo from their own path, not the working
directory.

### `steps/01_download.sh`

Creates `pdfium-source/`, points gclient at the PDFium release branch named by
`PDFIUM_REF` and runs `gclient sync` to fetch PDFium and its dependencies. This
is the slow part (~9 GB).

### `steps/02_patch.sh`

Applies the four patches in `patches/` to the checkout, in order. Patches that
are already applied are detected and skipped, so the script is safe to re-run.

All patches are taken from the
[pdfium-binaries project](https://github.com/bblanchon/pdfium-binaries) except
`headerpad.patch`, which adds the `headerpad_max_install_names` linker flag so
the library's install name can later be rewritten to a longer one — the .NET
MAUI build system needs this.

| patch | what it does |
| --- | --- |
| `shared_library.patch` | builds `pdfium` as a `shared_library` rather than a `component` |
| `public_headers.patch` | makes the public headers use relative includes and always export `FPDF_*` |
| `ios_pdfium.patch` | compiles the Apple platform sources for iOS/Catalyst, not just macOS |
| `headerpad.patch` | reserves header space for a longer install name |

### `steps/03_build.sh [--clean] <arm64\|x64>`

Runs `gn gen` and `ninja` for one architecture, producing
`pdfium-source/pdfium/out/catalyst-<arch>/libpdfium.dylib`. Pass `--clean` to
wipe that build directory first. The main script calls it once per
architecture.

### `steps/04_create_nuget.sh [macOS-nuget-version]`

Downloads `bblanchon.PDFium.macOS` at `PDFIUM_VERSION` from nuget.org, unpacks it into
`nuget-work/`, renames the package id to `bblanchon.PDFium.MacCatalyst`,
renames `runtimes/osx-<arch>` to `runtimes/maccatalyst-<arch>`, drops our
dylibs in place of bblanchon's, and runs `nuget pack`. It verifies that each
dylib really is the architecture its folder claims before packing, and refuses
to run if step 3 has not produced both dylibs.

### `steps/05_cleanup.sh`

Deletes `nuget-work/` and `pdfium-source/`, leaving only the scripts.

## Notes

`03_build.sh` passes `use_lld=false`, which links with Apple's `ld` instead of
lld. As of Xcode 26.6 the macOS SDK reexports `libsystem_eligibility`,
`libsystem_sanitizers` and `libsystem_trial` for the maccatalyst platform but
ships no maccatalyst slice in those `.tbd` files, which lld rejects outright.
Drop the flag once Apple fixes the SDK.
