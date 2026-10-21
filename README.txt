G HUB Operator Script Pack 1.2.0

INSTALL
1. Install and open Logitech G HUB at least once on the destination PC.
2. Fully quit G HUB using its system tray icon.
3. Run Jay-GHUB-Script-Pack-v1.2.0.exe, choose operators, then select Install selected.
4. Reopen G HUB and select the desired script in its Scripting editor for
   the intended game profile. Installing does not automatically select a script.

Installs per Windows user under %LOCALAPPDATA%\LGHUB\scripts.
Administrator access and a separate Python or .NET SDK installation are not needed.
The launcher uses Windows PowerShell and the Windows .NET Framework.
The executable is unsigned; organizational application policies may block it.

CONTENTS AND DEFAULTS
78 operators from Ubisoft's roster, checked 22 October 2026, including Noor,
Solid Snake, Denari, Striker and Sentry. Full list: OPERATORS.txt.
Source: https://www.ubisoft.com/en-us/game/rainbow-six/siege/game-info/operators

All scripts are neutral templates, not operator-tuned recoil profiles:
RcCustomStrength = 0 and HorizontalStrength = 0 (no scripted movement).
Only these two user-tuning values are placed in the basic settings section.
Timing and control values are marked advanced and should normally be left alone:
VerticalFrequency = 2, HorizontalFrequency = 4, DelayRate = 7,
RequireToggle = true, ToggleKey = "CapsLock", RecoilControlMode = "Custom".
EnableRCS remains true, but zero strengths produce no mouse movement.
Burst resets, 1 ms idle waits, separate loops and aim-release checks are retained.
Comments identify advanced settings; the values are not password-locked.
There is no universal correct recoil strength. Users must calibrate for their
weapon, attachments, sensitivity and DPI before relying on a template.

EXISTING SCRIPTS
Scripts with matching names are skipped, even if their contents differ.
Older aliases such as Jager and Valk are also recognized.
Other scripts are left unchanged. This installer does not overwrite or upgrade
an existing script. Each new installation uses fresh UUID folders.

BACKUPS
Before installation, existing scripts are copied to:
%LOCALAPPDATA%\LGHUB\script-pack-installs\siege-operator-lua-pack-v1\backups
Ownership and hash information is saved beside that folder in installed.json.
Backups remain after uninstall. For manual recovery, quit G HUB and copy only
the desired script folders from a snapshot's scripts directory into LGHUB\scripts.

UNINSTALL
Quit G HUB, run this installer again and choose Uninstall pack.
Only unchanged files installed by this package are removed.
Edited scripts, unrelated scripts and backups are preserved. Remove preserved
scripts manually in G HUB if you no longer want them.

VALIDATION AND LIMITS
Tested using isolated temporary folders with Windows PowerShell:
- fresh install of all 78 scripts and repeated installation without duplicates
- existing-name preservation and verified payload hashes
- uninstall ownership tracking and edited-script preservation
- retained backups and rejection of corrupt payloads

All 78 bundled scripts pass Lua 5.1 syntax checks. The installed G HUB API
documents a Lua 5.4 library subset; syntax checks are not a runtime guarantee.
The executable was built and its embedded payload verified. Its visual interface
and script discovery have not been tested end to end on a separate G HUB install.
The user's working G HUB scripts were not changed during installer tests.

SOURCE
GHUB-Script-Installer-source.zip contains the launcher, PowerShell installer,
bundled Lua scripts, build script, tests and SHA-256 catalog for inspection.

VERSION 1.2.0
Search and select individual operators, Select All or Clear before installation.
Selection affects installation only; Uninstall pack checks all scripts it owns.
MIT licensed; LICENSE is included in the package.
