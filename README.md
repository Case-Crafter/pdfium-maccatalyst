# pdfium-maccatalyst
Scripts for building Pdfium for Mac Catalyst (ARM64 and X64)

## Build process

To build the Pdfium libraries for Catalyst we have three scripts. The first download the source code, the second patches the code, and the third configures and builds the library.

All the patches has been copied from the [pdfium binaries GitHub project](https://github.com/bblanchon/pdfium-binaries), except for headerpad.patch which adds the headerpad_max_install_names linker parameter so the library install name can be changed to a longer name. This is needed for the .NET MAUI build system.

