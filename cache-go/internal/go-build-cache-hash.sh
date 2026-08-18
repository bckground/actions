#!/usr/bin/env bash
#
# Shared helper for the cache-go restore/save actions. Prints a fingerprint of
# the Go build cache, which cache-go/save turns into the build cache key and
# uses to skip the upload when nothing changed since cache-go/restore ran.
#
# The fingerprint is the sorted list of output file ("-d") names, hashed. Each
# output is named after the sha256 of its own contents, so the list of names
# describes exactly what the cache holds - without reading a single file.
#
# The index records ("-a") are deliberately left out. Each one maps an action
# to the output it produced:
#
#   v1 <actionID> <outputID> <size> <unixnano>
#
# and some actionIDs - the per-directory source indexes - hash in file mtimes.
# A CI checkout rewrites every mtime, so runs that built nothing new kept
# minting fresh records for outputs the cache already held, and the
# fingerprint changed every run: save never got to skip. Records can also
# misdescribe the cache in ways output names cannot: one can point at an
# output that is gone (the two files are written - and trimmed - separately),
# and stale ones linger for days after mtime churn replaces them.
#
# The trade-off: a run that only adds new records for existing outputs reads
# as unchanged and is not re-uploaded, so the next run re-derives those
# records. That is precisely the mtime-churn case, and re-indexing costs
# milliseconds; work that produces genuinely new bytes always changes the
# fingerprint.
#
# It is invoked via ${{ github.action_path }}/../internal/go-build-cache-hash.sh
# so that restore and save always run the helper at the same ref they were
# checked out at (no floating @main reference).
#
# Takes no input: it resolves the build cache directory itself, so that it can
# run before go-cache-config.sh, which needs its output to build the key.
set -euo pipefail

build_cache="$(go env GOCACHE)"

# A missing cache is a valid state: restore cleans before it restores, and the
# restore itself may have missed. It hashes to the digest of the empty input,
# which is stable and distinct from any populated cache.
if [ ! -d "$build_cache" ]; then
  printf '' | sha256sum | cut -d' ' -f1
  exit 0
fi

cd "$build_cache" || exit 1

# -mindepth 2 skips the cache root, which holds only README and trim.txt; the
# outputs themselves live one level down in the shard directories.
find . -mindepth 2 -name '*-d' -type f \
  | LC_ALL=C sort \
  | sha256sum \
  | cut -d' ' -f1
