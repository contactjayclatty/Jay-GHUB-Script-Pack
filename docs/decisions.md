# Decisions and requirements

2026-10-22, requested by Jay and implemented by Codex:

- Create public repository `contactjayclatty/Jay-GHUB-Script-Pack`, with v1.1.0 as a draft release. Publishing the release is separate from creating its draft.
- Include every operator listed by Ubisoft on 2026-10-22: 78. Revisit on roster updates; the source URL and verification date live in the catalog.
- Distribute neutral zero-strength templates rather than Jay's calibrated values. Those values depend on individual equipment/settings. Never import personal values when regenerating.
- Keep advanced timing/control settings and the separate firing branches. The owner explicitly rejected merging the loops and changing Caps Lock handling.
- Include burst resets, idle waits and the tested aim-release change. The owner reported the earlier calibrated live scripts worked well; this is not proof of another installation's neutral templates or UI.
- Use per-user paths and fresh UUIDs. Skip same names/aliases to avoid replacing someone's configuration. Existing package scripts are also skipped; automatic updates are out of scope.
- Preserve modified installed files on uninstall. Keep snapshots after uninstall as manual recovery material.
- Do not add an open-source license without the owner's decision. Public visibility alone is not a license grant.

Release limitations: executable unsigned; separate-machine UI/discovery UAT outstanding. Revisit release status when that test is recorded. No pricing, hosted service or paid dependency is introduced.
