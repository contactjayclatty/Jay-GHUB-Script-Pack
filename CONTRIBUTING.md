# Contributing

## Bugs and questions

Use [Discussions](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/discussions) for setup help. Use the [bug form](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/issues/new?template=bug_report.yml) for a reproducible problem.

Include Windows/G HUB versions, the installer version, steps, expected behavior and the actual result. Remove personal identifiers from screenshots and logs. Cross-install reports are especially useful; see the [manual test steps](docs/testing.md#manual-compatibility-check-still-needed).

## Pull requests

Keep the change focused. Explain what changes for users and which checks passed. State anything still untested.

For installer changes:

```powershell
python test_installer.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

For documentation changes:

```powershell
python check_docs.py
```

After changing the roster, refresh its README block with `python check_docs.py --write-roster`.

Preserve zero distribution strengths, separate firing branches and existing control behavior unless a behavior change is agreed. Never weaken payload hashes, ownership checks, name protection or edited-file preservation. Test against isolated directories, never live scripts.

Do not submit personal calibration, backups, account identifiers or third-party material without permission. Licensing is undecided; public access does not imply unrestricted reuse.

[Developer guide](docs/architecture.md) · [Design choices](docs/decisions.md) · [Roadmap](docs/roadmap.md)
