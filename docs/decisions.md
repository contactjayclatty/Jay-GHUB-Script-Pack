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

## 2026-10-22: README and discoverability

Jay requested a substantially improved README and a repository more likely to attract stars. Use accurate topics, clearer benefits and setup guidance, a static branded header, issue forms, Discussions and contributor guidance. Do not promise star growth, purchase/fabricate engagement, post promotional messages, invent results or publish the draft without approval. A public release remains a prerequisite for public binary downloads; the README makes that status explicit.

## 2026-10-22: tactical design and first published project release

Jay explicitly requested a more R6-like design and release of an official installer with a virus check. Use original tactical styling (dark slate, amber, cyan, angular framing), without official logos or claims of Ubisoft/Logitech endorsement. Publication of v1.1.0 is authorized after successful validation and malware scanning.

Local Defender was inactive, so do not change the developer's antivirus configuration or call that a clean scan. Use an ephemeral GitHub Windows runner, update Defender signatures, scan the exact executable plus extracted script payload, and bind evidence to SHA-256. Publish the scanned binary downloaded from that runner, not a separately rebuilt executable. Describe a no-detections result as a single-engine scan, not a guarantee or code signature. The installer remains unsigned.
