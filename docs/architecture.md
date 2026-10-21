# Architecture and product scope

The user runs `Launcher.cs`, a Windows .NET Framework executable. It extracts its embedded archive to a unique temporary directory, launches `Installer.ps1` with Windows PowerShell, waits for it to finish, then cleans its own temporary directory.

`Installer.ps1` displays Install/Uninstall actions and reads `payload/catalog.json`. The installer verifies hashes, snapshots existing scripts, writes fresh UUID folders and ownership records, and skips existing names. Uninstall requires recorded ownership and unchanged script/config hashes; modified files remain.

`template.lua` is the maintainer's neutral seed. `build_defaults.py` generates 78 operator-labelled copies and the catalog. `build.ps1` packages the committed payload and compiles the launcher. `test_installer.py` runs the engine against isolated directories. CI runs that test and build on Windows and uploads artifacts without publishing a release.

The product distributes neutral templates; it does not measure recoil, promise specific performance, automatically select profiles, alter game files, sell entitlements or operate a backend. It is an independent Windows utility with no live service and no project-held credentials. GitHub repository/release access uses the maintainer's authenticated CLI outside the product.

Developer dependencies: Python 3 (standard library only), Windows PowerShell, .NET Framework C# compiler; Lua compiler is used for template-generation syntax checks. Runtime dependencies: Windows PowerShell and .NET Framework. There are no Python packages or embedded credentials.

The tactical UI is authored with Windows Forms, an original project icon and an SVG README banner. The preview renderer draws the actual form without installing anything. CI runs Microsoft Defender against the built release executable and extracted payload, then uploads both the scanned binary and its report. Release tooling must preserve that exact artifact.
