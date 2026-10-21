# Developer guide

## Components

| File | Responsibility |
| :--- | :--- |
| `Launcher.cs` | Extract the embedded package into a unique temporary directory, run the PowerShell installer and clean up afterward. |
| `Installer.ps1` | Interface, payload validation, per-user installation, snapshots and uninstall ownership. |
| `template.lua` | Neutral seed containing the shared controls. |
| `build_defaults.py` | Generate the operator templates and catalog. |
| `payload/catalog.json` | Names, aliases, version, roster source/date and hashes. |
| `build.ps1` | Verify committed payload hashes, package resources and compile the executable. |
| `scan-release.ps1` | Scan the exact built artifact and record evidence. |

## Build requirements

Windows, Python 3, Windows PowerShell and the .NET Framework C# compiler. Python uses only the standard library for tests. End users need Windows PowerShell and .NET Framework, not Python or a .NET SDK.

```powershell
python test_installer.py
python check_docs.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

Output is written to `dist/`. Building uses the committed payload and never reads installed user scripts.

## Regenerate templates

Edit `template.lua` or the roster in `build_defaults.py`, then run the generator. It runs `luac -p`; configure its local Lua compiler path for your machine. Regeneration writes payload files and the catalog, so review both before committing. All distribution strengths must remain zero.

Refresh the README roster with `python check_docs.py --write-roster`, then run the tests and build.

## Data preservation

Installation creates fresh UUID folders under the current user's G HUB scripts directory. Existing names/aliases are skipped. A snapshot precedes additions; the manifest records installed UUIDs and hashes.

Uninstall checks ownership, hashes and folder contents before removal. Modified or unfamiliar files are preserved. Read [design choices](decisions.md) before changing those rules.

## Interface and scanning

The Windows Forms interface uses original project artwork. Preview it without installation using `Installer.ps1 -RenderPreview <png>`.

CI builds on Windows, enables Defender only on its temporary runner, scans the executable plus extracted scripts and uploads a report. Use that exact binary for release. There is no hosted backend, runtime script downloader or embedded credential.

[Tests](testing.md) · [Release checklist](releasing.md)

## Selection and previews

The checklist keeps selected canonical names separately from the filtered display. The engine accepts `-Operators "Doc,Ash"` (default `*`) for isolated tests and resolves known aliases. Selection is validated before creating snapshots or files. Existing ownership records are merged for later installs.

The optional `make_demo.py` tool needs Pillow and renders the real form while validating a two-operator install/uninstall against a generated test folder. Its GIF is labelled as a test-folder demonstration.

The executable includes product/file version metadata. No publicly trusted code-signing certificate was available for this release, so it remains unsigned. The unrelated development certificate is not used.
