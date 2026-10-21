# Release checklist

## Prepare

1. Check the roster and version in `payload/catalog.json`.
2. Update version references in the build script, generator and release notes together.
3. Run the installer tests, documentation checks and Windows build. Review the staged files for personal configurations, backups and identifiers.
4. Push the commit and wait for every Windows validation step, including the Defender scan, to succeed.

## Package the scanned artifact

1. Download that run's `windows-installer` artifact.
2. Confirm `malware-scan-report.json` reports no detections and identifies the intended commit.
3. Hash the executable and compare it with the scan report. Use this exact binary, not a later local rebuild.
4. Create the source ZIP with `git archive` from the release commit.
5. Create a Windows ZIP containing the executable, README.txt, OPERATORS.txt and scan report.
6. Generate SHA256SUMS.txt over the executable, ZIPs and report.

## Publish

Upload the files to a draft release. Verify uploaded names, sizes and SHA-256 digests. Check the target commit and CI result before publishing. After publication, open the public release while signed out and confirm the installer is listed.

Describe the project as independent and the executable as unsigned. Link the actual report rather than using claims such as certified safe or guaranteed compatible. Do not replace published executables without a new version and scan. Documentation edits on the default branch do not change a historical release.

The first release, v1.1.0, was published on 22 October 2026 with its scan evidence. Future releases require maintainer approval.
