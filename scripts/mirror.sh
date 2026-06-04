#!/usr/bin/env bash
#
# Mirror Eclipse jdtls milestone bundles into this repo's GitHub Releases.
#
# For each of the last N milestone versions that does not yet have a release,
# downloads the .tar.gz + .sha256 from download.eclipse.org, verifies the
# checksum, and publishes a GitHub Release tagged with the version.
#
# Env:
#   KEEP_LAST   number of newest milestone versions to consider (default 10)
#   GH_TOKEN    GitHub token (provided by Actions); required by `gh`
#
set -euo pipefail

BASE="https://download.eclipse.org/jdtls/milestones"
KEEP_LAST="${KEEP_LAST:-10}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

log() { printf '==> %s\n' "$*"; }

# --- discover versions -------------------------------------------------------
# Scrape the directory index for "x.y.z/" hrefs, then keep the newest N by
# semantic version order.
log "Fetching milestone index"
mapfile -t VERSIONS < <(
  curl -fsSL "$BASE/" \
    | grep -oE "href='/jdtls/milestones/[0-9]+\.[0-9]+\.[0-9]+'" \
    | sed -E "s#.*/([0-9]+\.[0-9]+\.[0-9]+)'#\1#" \
    | sort -t. -k1,1n -k2,2n -k3,3n -u \
    | tail -n "$KEEP_LAST"
)
log "Candidate versions (last $KEEP_LAST): ${VERSIONS[*]}"

# --- existing releases -------------------------------------------------------
mapfile -t EXISTING < <(gh release list --limit 1000 --json tagName --jq '.[].tagName' || true)
has_release() {
  local v="$1"
  for e in "${EXISTING[@]:-}"; do [[ "$e" == "$v" ]] && return 0; done
  return 1
}

# --- mirror loop -------------------------------------------------------------
created=0
for ver in "${VERSIONS[@]}"; do
  if has_release "$ver"; then
    log "$ver already released, skipping"
    continue
  fi

  dir="$BASE/$ver"
  # latest.txt holds the exact archive filename (timestamp varies per build).
  fname="$(curl -fsSL "$dir/latest.txt" | tr -d '[:space:]')"
  if [[ -z "$fname" ]]; then
    log "WARNING: no latest.txt for $ver, skipping"
    continue
  fi

  log "$ver -> $fname"
  ( cd "$WORKDIR" \
    && curl -fsSL -O "$dir/$fname" \
    && curl -fsSL -O "$dir/$fname.sha256" )

  # The .sha256 file contains only the bare hash, so build a check line.
  ( cd "$WORKDIR" \
    && want="$(tr -d '[:space:]' < "$fname.sha256")" \
    && echo "$want  $fname" | sha256sum -c - )
  log "checksum OK"

  gh release create "$ver" \
    "$WORKDIR/$fname" \
    "$WORKDIR/$fname.sha256" \
    --title "jdtls $ver" \
    --notes "Mirror of $dir/$fname

Source: $dir
SHA256 verified at publish time."

  rm -f "$WORKDIR/$fname" "$WORKDIR/$fname.sha256"
  created=$((created + 1))
done

log "Done. Created $created new release(s)."
