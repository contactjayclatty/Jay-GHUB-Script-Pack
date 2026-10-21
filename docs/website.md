# Download website

The public site lives at https://contactjayclatty.github.io/Jay-GHUB-Script-Pack/.

## Pages and design

`site/index.html` is the homepage. `previews.html` contains the installer walkthrough, a full Doc template and searchable roster. `download.html` contains release files and transfer progress. `guide.html` covers installation, configuration, backup recovery and removal. `about.html` records the project purpose, license and compatibility limits.

The site uses plain HTML, CSS and JavaScript with local artwork, charcoal surfaces, pale yellow accents, condensed headings and monospace labels. Navigation marks the current page. No framework, backend, analytics, external fonts or runtime package installation is required. The full roster, guide and download links work without JavaScript.

## Downloads and progress

`site/downloads/` contains exact copies of the published v1.2.0 installer, Windows ZIP and source ZIP. Their hashes were compared with GitHub release asset digests before copying. `release.json` records filenames, sizes, SHA-256 values and direct GitHub alternatives. Same-origin files allow real streaming progress without cross-origin download restrictions.

A click opens an accessible modal, streams the chosen file and displays bytes received. The page checks size and SHA-256 before enabling Save file. Cancel aborts the request; failure or checksum mismatch offers Retry and a direct GitHub link. Escape/Close cancels and restores focus. The browser handles the disk save, so the page says Save requested rather than claiming it can verify a saved file. Unsupported browsers use the ordinary download links. Transfers with no exposed stream use indeterminate progress until verification completes. Small files may finish almost immediately; there are no artificial delays.

Files are buffered in memory with a 50 MB metadata limit. The current largest file is about 235 KB. Reconsider the approach if release assets grow substantially. An unsigned executable remains unsigned; matching a checksum is integrity evidence, not a safety guarantee.

## Updating a release

After publishing and verifying a new release, replace the three mirrored files and update `release.json`, page versions, displayed sizes, checksum and scan/build links together. Keep the direct GitHub alternatives aligned. Update the roster and example Lua from `payload/catalog.json` and the corresponding payload file when those change. The current example is exactly `payload/operator-69.lua` (Doc); it is read-only on the site. The preview GIF uses an isolated test folder, not a live G HUB recording.

## Deployment and validation

`.github/workflows/pages.yml` checks and deploys only `site/` when the site, checker or workflow changes. `python check_website.py` validates all five pages, local navigation/anchors, roster names/aliases, preview provenance and the three file hashes. `python check_docs.py` checks repository documentation.

Browser validation covers desktop and phone-width layouts, navigation, previews, search, FAQ expansion, checksum copying, streamed progress, cancellation/retry, completed verification and save requests. A development-only slow server exercises transfer states without changing production behavior. Corrupt test responses must be rejected before Save. After deployment, open every public page and verify the public file hashes and Pages workflow. Installation evidence remains in [testing](testing.md).

## Latest browser checks

The five-page site passed overflow checks at 320, 390, 768 and 1265 pixels. A throttled local transfer showed changing byte counts, cancellation, successful retry, SHA-256 verification and a save request. A deliberately changed ZIP response was rejected with Save unavailable. These checks exercise browser behavior; they do not run the installer.

## Download page layout

The download page leads with a dedicated installer release panel and one primary download action. ZIP/source options follow, with a separate evidence section, expandable checksum and download-specific help. Mobile hides the introductory benefit list to bring the primary action higher. The transfer dialog marks Receive, Verify and Save stages and offers the setup guide after requesting a save. It still measures actual bytes and checks the same published hashes.
