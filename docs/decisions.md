# Design choices

## Neutral distribution

All 78 templates start with zero horizontal and vertical strengths. Personal calibration is not suitable as a universal default. Timing and control settings are separated from the two basic tuning fields.

The catalog records the roster source/date, display names, older aliases and hashes. New operators require a deliberate catalog update; the installer does not fetch scripts at runtime.

## Preserve existing work

A matching name or alias is skipped. The installer snapshots current scripts before adding fresh UUID folders. Uninstall requires recorded ownership, unchanged hashes and the expected folder contents. Edited scripts and snapshots are retained.

These rules favor preserving calibration over silently updating a script. Automatic replacement is outside the current scope.

## Stable controls

Keep the two firing branches separate, with burst-start counter resets, idle sleeps and aim-release checks. The existing Caps Lock behavior is deliberate: the toggle is checked before entering the aim loop. Changes to controls require testing both branches and documenting any effect on calibration.

## Release integrity

Publish the exact executable produced and scanned in CI. Verify the scan-report hash before upload, and GitHub's uploaded digest afterward. A scan with no detections is not a code signature or a guarantee of safety. The installer remains unsigned.

## Licensing and branding

Use original project artwork, without official Ubisoft or Logitech logos or endorsement claims. The project is MIT licensed. Retain its copyright and permission notice in redistributed copies.

## Selective installation

Version 1.2.0 adds a searchable checklist. All operators are selected initially; Clear enables choosing a smaller set. Filtering does not discard hidden selections. Empty or unknown selections are rejected before filesystem changes. Additional installs merge ownership records. Uninstall remains package-wide and is not limited by the current checklist.
