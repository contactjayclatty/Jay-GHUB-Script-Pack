# Change history

## 2026-10-22: initial GitHub release setup

Before: a locally built installer, source ZIP, 78 neutral templates and isolated engine tests. Earlier 16-script builds contained personal tuning; those artifacts are excluded from this repository.

Change: Jay requested GitHub release setup, authorized a new relevant name and chose public visibility. Repository name uses Jay's verified account display name. Codex prepared self-contained source, Windows build/test automation, documentation, agent rules, versioned assets and a draft release.

Why: make the installer reviewable and distributable without depending on Jay's machine or modifying his working G HUB installation.

Knowledge delta: `README.md`, `AGENTS.md`, `docs/index.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/testing.md`, `docs/releasing.md`, this change record and CI workflow. These are the canonical homes; no global memory files are written.

Verification: scoped install/uninstall tests, payload hashes, executable build and CI/release metadata are checked at the end of this batch. Live GUI/discovery on another PC remains outside the evidence. Revisit if G HUB format changes, roster changes, or manual UAT identifies a mismatch.

Librarian review: documentation links route the user to install, configure, recover, test and release procedures; the remaining runtime limits are explicitly stated. Final gate receipt records observed checks separately.

Build finding: Windows PowerShell requires an explicit `System.IO.Compression` assembly load for `ZipArchiveMode`; added it alongside `System.IO.Compression.FileSystem`. This affected the new build wrapper, not the previously tested installer engine. The failed build was rerun after that fix.

## 2026-10-22: presentation and community setup

Jay requested a much stronger README and better prospects for stars. Replaced the plain landing page with a branded header, honest status/CI badges, setup and calibration guidance, full roster, troubleshooting, evidence table and contribution paths. Added issue/PR templates, contribution guidance, a realistic roadmap and a documentation checker in CI. Discovery settings use relevant topics and enable Discussions; no promotional messages or fabricated engagement are part of the task.

Knowledge delta: `README.md`, `assets/banner.svg`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/roadmap.md`, this record, decisions/testing/index, agent guidance, and the new documentation CI gate. Installer code and the v1.1.0 draft assets are unchanged.

Librarian review: setup, configuration, recovery, support and build paths are linked from the README and maintainer index. Draft downloads and remaining UAT are explicit. GitHub-rendered documentation and remote settings are checked after push. Stars are not a guaranteed outcome.

## 2026-10-22: tactical release styling and malware scan

Jay requested Siege-inspired design and publication with a virus check. Added original tactical banner/UI styling, a project icon and a preview renderer. Added an isolated CI Defender scan with current signatures and a hash-bound report; local Defender was inactive, so local security settings remain unchanged. The release uses the exact CI-scanned binary. README download links and release notes are updated for the approved publication, with unsigned status and independent-project scope retained.

Knowledge delta: README, RELEASE_NOTES, Installer.ps1, build.ps1, scan-release.ps1, validation workflow, assets and the linked testing/architecture/decisions/release/roadmap documents. The 78 Lua payloads and calibrated live scripts remain unchanged. Librarian review: public claims point to scan evidence and preserve the difference between no detections, signing and runtime compatibility.
