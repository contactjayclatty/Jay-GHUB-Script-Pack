# Testing and limitations

`python test_installer.py` checks all 78 neutral templates, then uses Windows PowerShell with explicit isolated test roots. It verifies fresh installation, repeat installation, exact names (including Unicode), aliases, existing script preservation, edited-script preservation, uninstall ownership, retained snapshots and corrupt-payload rejection before target creation.

`build.ps1` verifies SHA-256 payload entries and compiles an executable. It does not prove the UI works or scripts are discovered by G HUB. Template generation also runs `luac -p`; the original local check used Lua 5.1 while G HUB's installed reference lists a Lua 5.4 subset. No undocumented runtime compatibility guarantee is inferred from this.

Required manual UAT before broad distribution:

1. On a separate Windows account or PC, open G HUB once and fully quit it.
2. Run installer; check Install/Uninstall UI and error if G HUB is still running.
3. Confirm all new operator names appear in G HUB and zero-strength defaults produce no movement.
4. Configure one test script, confirm it loads, then confirm uninstall preserves edited files and unrelated scripts.
5. Record Windows/G HUB versions and observed results here.

Status: isolated engine tests and local compiler checks passed before repository creation. Separate-machine visual/discovery UAT remains unverified. CI status must be checked live for each published commit.

`python check_docs.py` verifies the generated README roster against the catalog, checks local document links and headings, and parses the static SVG header. Regenerate only its marked roster block with `python check_docs.py --write-roster`. This does not validate external URLs or replace inspecting GitHub's rendered README.
