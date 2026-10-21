# Setup and recovery

[Back to README](../README.md)

## Requirements

Use the Windows account that normally runs G HUB. Install and launch Logitech G HUB at least once before installing this pack. Windows PowerShell and .NET Framework are runtime dependencies; Python and a .NET SDK are not required for end users.

The installer is unsigned. Check the release's scan report and checksums before running it. Do not disable security software to force an installation; report a detection with the filename and hash.

## Installation

1. Download the executable or Windows ZIP from [v1.1.0](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/releases/tag/v1.1.0). Extract the ZIP first if using it.
2. Fully quit G HUB from its system tray icon.
3. Run the installer and choose **Install scripts**.
4. Read the completion message. It reports installed/skipped counts and the backup location.
5. Reopen G HUB. In the intended profile's Scripting editor, select an operator script.
6. Configure its two strengths. Both default to zero, so installation alone produces no mouse movement.

No username substitution is needed. The normal per-user installation does not require administrator access. A different Windows account has a different local G HUB folder.

## Existing scripts

Existing names are skipped even if their contents differ. `Jager` and `Valk` are recognized as aliases for `Jäger` and `Valkyrie`; the catalog lists the remaining aliases. Unrelated scripts are not changed.

There is no automatic update or overwrite mode. If a script was skipped, check it in G HUB rather than assuming the neutral template replaced your settings.

## File layout

```text
%LOCALAPPDATA%\LGHUB\
|-- scripts\
|   |-- <operator UUID>\
|   |   |-- config.json
|   |   `-- script.lua
|   `-- ...
`-- script-pack-installs\
    `-- siege-operator-lua-pack-v1\
        |-- installed.json
        `-- backups\
            `-- <timestamp>\
                `-- scripts\
```

`config.json` contains the display name. `script.lua` contains the settings and logic. `installed.json` records ownership and file hashes for uninstall.

## Uninstall

Quit G HUB, run the same installer, and choose **Uninstall pack**. Only unchanged files installed by this pack are removed. Edited scripts, unrelated folders and snapshots remain. A preserved script can be removed manually through G HUB if you no longer need it.

## Backups and recovery

Each installation snapshots the existing scripts under:

```text
%LOCALAPPDATA%\LGHUB\script-pack-installs\siege-operator-lua-pack-v1\backups
```

To restore a script:

1. Fully quit G HUB.
2. Open the appropriate dated snapshot and its `scripts` folder.
3. Copy only the operator UUID folders you want to restore into `%LOCALAPPDATA%\LGHUB\scripts`.
4. Reopen G HUB and check the selected script and profile.

Keep a separate copy before replacing a folder that contains newer tuning. Uninstall does not delete snapshots.

## Troubleshooting

| Symptom | Check |
| :--- | :--- |
| G HUB is still running | Quit the tray icon. If needed, close `lghub` and `lghub_agent` in Task Manager, then retry. |
| User data not found | Open G HUB once under this Windows account, then fully quit it. |
| An operator was skipped | A matching name or alias already exists; it was preserved. |
| Script produces no movement | Check the selected profile, Caps Lock and the two zero-default strengths. |
| Script names do not appear | Restart G HUB and check the Scripting editor. Report the installed version and exact result if still missing. |
| Uninstall leaves files behind | Edits or changed folder contents cause preservation by design. |

For help, use [Discussions](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/discussions). File reproducible bugs through the [issue form](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/issues/new?template=bug_report.yml), including Windows/G HUB versions and the installer version.
