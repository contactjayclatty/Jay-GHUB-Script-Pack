# Jay's G HUB Script Pack

A Windows installer for 78 named Rainbow Six Siege operator Lua templates. Made for Jay's workflow; each new template starts with **zero vertical and horizontal movement**, so users can calibrate their own settings.

## Install

1. Download the `.exe` from [Releases](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/releases).
2. Install and open Logitech G HUB at least once, then fully quit it from its tray icon.
3. Run the installer under the Windows account that uses G HUB and choose **Install scripts**.
4. Reopen G HUB and select the script for your intended profile in the Scripting editor.

The installer targets `%LOCALAPPDATA%\LGHUB\scripts`, creates unique folders, backs up existing scripts, and skips existing names (including aliases such as Jager/Jäger and Valk/Valkyrie). It does not automatically activate scripts or replace existing tuning.

The executable is unsigned. The install/uninstall engine has been tested in isolated folders; the visual installer and discovery on another G HUB installation still need end-to-end testing. No guarantee of compatibility with every G HUB version is claimed.

## Configure

Only `RcCustomStrength` and `HorizontalStrength` are placed in the basic tuning section. Both start at **0**. These are neutral defaults, not operator-specific recoil measurements.

Timing and controls are marked advanced: `VerticalFrequency=2`, `HorizontalFrequency=4`, `DelayRate=7`, Caps Lock required, Custom mode. Burst resets, idle sleeps and aim-release checks are included. Guidance comments do not lock these settings.

Roster checked **22 October 2026** against [Ubisoft's operator directory](https://www.ubisoft.com/en-us/game/rainbow-six/siege/game-info/operators). See [OPERATORS.txt](OPERATORS.txt).

## Uninstall and recover

Quit G HUB and run the installer again, choosing **Uninstall pack**. It removes only unchanged scripts it installed. Modified scripts, unrelated scripts and backup snapshots remain.

Backups and ownership records: `%LOCALAPPDATA%\LGHUB\script-pack-installs\siege-operator-lua-pack-v1`. See [full instructions](README.txt).

## Build and test

Windows with Windows PowerShell 5.1 and the .NET Framework compiler is required. Python 3 is used only for development tests, not by end users.

```powershell
python test_installer.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The executable is produced in `dist/`. Committed payload files are verified before building. To regenerate the roster templates, `build_defaults.py` additionally requires Lua 5.1 `luac.exe` at its documented local tool path; adjust that developer tool path for your machine. It uses `template.lua`, never a user's installed scripts. Regeneration is only required when changing the template or roster.

See [maintainer documentation](docs/index.md), [release procedure](docs/releasing.md), and [agent guidance](AGENTS.md).

This project is independent of Logitech and Ubisoft. Their names identify compatibility and the operator roster. No software license grant is included pending the owner's licensing decision.
