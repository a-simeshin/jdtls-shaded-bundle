# jdtls-shaded-bundle

Mirror of [Eclipse JDT Language Server](https://github.com/eclipse-jdtls/eclipse.jdt.ls)
(jdtls) milestone bundles, republished as GitHub Releases for convenient,
URL-stable access.

## How it works

[`scripts/mirror.sh`](scripts/mirror.sh), run daily by
[`.github/workflows/mirror.yml`](.github/workflows/mirror.yml):

1. Scrapes `https://download.eclipse.org/jdtls/milestones/` for versions.
2. Takes the newest `KEEP_LAST` (default 10) versions.
3. For each version without an existing release: reads `latest.txt` for the
   exact archive name, downloads `*.tar.gz` + `*.tar.gz.sha256`, verifies the
   checksum, and publishes a GitHub Release tagged with the version (e.g.
   `1.58.0`), attaching both files as assets.

Manual run with custom depth: **Actions → Mirror jdtls milestones → Run
workflow** (set `keep_last`, e.g. `30` for a one-off backfill).

## Downloading

Each release exposes the original archive and its checksum as assets:

```bash
curl -fLO https://github.com/a-simeshin/jdtls-shaded-bundle/releases/download/1.58.0/jdt-language-server-1.58.0-<timestamp>.tar.gz
```

All artifacts originate from `download.eclipse.org` and retain their upstream
filenames and SHA-256 checksums.
