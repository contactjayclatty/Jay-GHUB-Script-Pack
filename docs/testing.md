# Testing

## Automated checks

| Command | Scope |
| :--- | :--- |
| `python test_installer.py` | All 78 neutral defaults; fresh/repeat installs; Unicode names and aliases; existing and edited-file preservation; backups; uninstall ownership; corrupt-payload rejection. |
| `python check_docs.py` | README roster, local links/headings, UTF-8 text and static SVG parsing. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1` | Payload hashes, embedded package and Windows executable build. |
| `scan-release.ps1` in CI | Exact executable, extracted Lua payload and installer script scanned with Microsoft Defender. |

Installer tests use isolated project directories and never modify live G HUB scripts. Template generation additionally uses `luac -p`; local syntax checks used Lua 5.1 while the installed G HUB reference lists a Lua 5.4 library subset. Syntax checks alone do not establish runtime compatibility.

## Malware scan evidence

The [v1.2.0 scan report](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/releases/download/v1.2.0/malware-scan-report.json) reports **no threats detected** and records the exact executable SHA-256, engine/signature versions, targets, exit codes, UTC timestamp, commit and CI run.

The scan requires active Defender and recent signatures. Only an ephemeral GitHub runner is reconfigured; local antivirus settings are not changed. Failed or unavailable scans fail CI. The released executable must match the report's hash.

This is a single-engine, on-demand scan. It is not code signing or a safety guarantee.

## Interface preview

`Installer.ps1 -RenderPreview <png>` renders the actual form offscreen without installing or removing scripts. The README preview was inspected for layout. It does not prove interactive behavior on another machine.

## Manual compatibility check still needed

On another Windows account or PC:

1. Open G HUB once, then fully quit it.
2. Run the installer and confirm that an active G HUB process produces a clear error.
3. Install the pack, reopen G HUB and check operator names in the Scripting editor.
4. Confirm zero strengths cause no movement, then configure one test script.
5. Edit that script, uninstall the pack, and confirm the edit and unrelated scripts survive.
6. Record Windows version, G HUB version and observed results in an issue or discussion.

On 22 October 2026 the maintainer reported that installation works on another PC. Windows/G HUB versions and a recording were not supplied. This is user-reported evidence, not an independently reproduced compatibility matrix. New v1.2.0 selection behavior still needs testing there. CI success must not be presented as universal G HUB compatibility.

Selective-install tests cover subsets, duplicate names, aliases, incremental ownership, package-wide uninstall and rejection of empty/unknown selections before file creation. `make_demo.py` uses Pillow to render the actual form and records verified install/uninstall output from an isolated folder. It does not operate G HUB.
