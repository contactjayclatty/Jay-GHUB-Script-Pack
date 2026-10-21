# Release procedure

1. Confirm scope and roster date in `payload/catalog.json`; never pull data from live installed scripts.
2. Update version consistently in catalog, build script, template generator and documentation.
3. Run `python test_installer.py` and `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`. Record real exit codes; repeat only a failed gate after a fix.
4. Review Git's staged file list for personal paths, backups or calibrated scripts. Commit, push, and verify the Windows Actions job.
5. Use `git archive --format=zip --output=<source.zip> HEAD` for the exact source archive. Bundle the executable, README.txt and OPERATORS.txt into a versioned Windows ZIP.
6. Download the successful CI's scanned `windows-installer` artifact. Verify malware-scan-report.json reports no threats and matches the executable SHA-256 and target commit. Use this exact binary; do not substitute a new local build. Generate `SHA256SUMS.txt` over the executable and both ZIP files. Upload all assets plus the scan report to a **draft** v1.1.0 release with limitations in its notes.
7. Verify release API metadata, target commit, assets, sizes and hashes. Confirm CI completion; a created draft or successful upload alone is not release validation.
8. Jay explicitly approved publication of the tactical v1.1.0 installer after a virus check. Publish only after the scan and other checks pass; subsequent releases still require explicit authorization.

The installer is unsigned; do not describe it as signed, certified, universally compatible or calibrated for individual users. No Git hooks are used.
