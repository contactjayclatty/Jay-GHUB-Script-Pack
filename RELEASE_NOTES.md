# Jay's G HUB Script Pack v1.1.0

Windows installer for **78 operator Lua templates**, based on Ubisoft's roster checked on **22 October 2026**.

## Downloads

- **Jay-GHUB-Script-Pack-v1.1.0.exe**: installer; quit G HUB before running it.
- **Jay-GHUB-Script-Pack-v1.1.0-windows.zip**: installer plus instructions and roster.
- **Jay-GHUB-Script-Pack-v1.1.0-source.zip**: exact source for this release commit.
- **SHA256SUMS.txt**: SHA-256 checksums for the executable and ZIP files.

## Included

- All 78 operators, including Noor and Solid Snake.
- **Neutral vertical and horizontal strengths of 0**. Users must calibrate; these are not measured operator-specific recoil values.
- Marked advanced settings, preserved separate firing loops, burst-start resets, idle sleeps and aim-release checks.
- Per-user installation, existing-name/alias protection, snapshots and ownership-aware uninstall.
- Modified scripts are preserved on uninstall. Existing scripts are never overwritten or automatically upgraded.

## Install

Open G HUB at least once, fully quit it, then run the installer and choose **Install scripts**. Reopen G HUB and select the desired script for your profile. See README.txt for setup and recovery instructions.

## Validation and known limits

- Isolated installation, repeat-install, duplicate/alias, Unicode, modified-script preservation, uninstall, snapshot and corrupt-payload tests passed locally.
- All 78 template scripts passed local Lua syntax checks. The executable builds with the Windows .NET Framework compiler.
- The executable is **unsigned**. Other-PC UI behavior and G HUB script discovery remain **unverified**; this draft is prepared for review/testing.
- Installing does not activate a script or tune it to an individual user's sensitivity, DPI, attachments or weapon.

Independent project; not affiliated with Logitech or Ubisoft. No source license grant is included pending the owner's licensing decision.
