# Download website

The public download site lives at https://contactjayclatty.github.io/Jay-GHUB-Script-Pack/.

`site/` contains plain HTML, CSS, JavaScript and local artwork. The GitHub Pages workflow deploys only this directory on changes to the site or its workflow. It requires no framework, package installation, backend, analytics or external fonts. JavaScript adds roster filtering and checksum copying; downloads and the full roster remain available without it.

The design uses charcoal, pale yellow, compact monospace labels and oversized condensed headings. The real installer screenshot is used instead of a simulated interface. Download links explicitly target v1.2.0 so its displayed checksum and scan evidence always refer to the same binary.

## Updating a release

Update versioned download links, file size, checksum and scan/build links in `site/index.html` only after the new release is published and its asset hashes are verified. Update the roster from `payload/catalog.json` if it changes; retain canonical names and aliases in each list item's `data-search`. Replace the screenshot only when the installer interface changes. The site does not fetch mutable release metadata at runtime.

## Verification

Before deployment, check local asset paths, download URLs and roster consistency. After deployment, check the public page at desktop and mobile widths, keyboard focus, roster names/aliases and empty search results, FAQ expansion and checksum copying. Confirm no horizontal overflow and a successful Pages workflow. Installation compatibility evidence remains in [testing](testing.md).
