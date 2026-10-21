# Contributing

Start with the [README](README.md) and [roadmap](docs/roadmap.md).

## Report a problem

Use the [installation bug form](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/issues/new?template=bug_report.yml). Include Windows and G HUB versions, how you installed, the exact error and clear steps. A script left behind after editing is expected uninstall behavior.

Use [Discussions](https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/discussions) for questions. Reports from another Windows account or PC are especially useful because cross-install discovery is not yet verified.

## Propose a change

- Keep changes focused and explain their effect on existing users.
- Do not submit personal calibrated scripts, local backups or account/device identifiers.
- Preserve zero default strengths, separate firing branches and the existing controls unless the owner approves a behavior change.
- Test with isolated folders, never live user scripts.
- For installer changes, run `python test_installer.py` and the Windows `build.ps1` script.
- For documentation changes, run `python check_docs.py` and keep procedures accurate.
- Include actual test results and remaining limitations in the pull request.

See [AGENTS.md](AGENTS.md). Licensing is undecided; do not assume unrestricted reuse or submit third-party material without permission.
