# Repository guidance

Read [docs/index.md](docs/index.md), [docs/decisions.md](docs/decisions.md) and [docs/testing.md](docs/testing.md) before changes. Keep implementation and relevant documentation in the same change; Akinator's context/documentation pass applies when available.

- Never modify the developer's live G HUB installation to test an installer change. `test_installer.py` uses isolated paths.
- Preserve existing names and edited scripts. Do not weaken hash or ownership checks.
- Neutral templates must retain zero strengths and the owner's separate firing loops. Test both branches after control changes.
- Do not claim runtime/UI compatibility from syntax checks, packaging, or tests against temporary folders.
- Do not commit calibrated personal scripts, backups, account identifiers, or generated test data.
- Run `python test_installer.py` and `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1` for installer changes. Review source and embedded hashes before release.
- Follow [docs/releasing.md](docs/releasing.md). Releases remain drafts until Jay explicitly approves publication.
- Run `python check_docs.py` after documentation changes. After roster updates, regenerate the README block with `python check_docs.py --write-roster`.
- Keep discovery metadata accurate. Do not promise stars, invent testimonials, mark draft downloads public, or add unverified performance claims.
