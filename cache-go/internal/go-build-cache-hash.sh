#!/usr/bin/env bash
#
# Shared helper for the cache-go restore/save actions. Prints a fingerprint of
# the Go build cache, which cache-go/save turns into the build cache key and
# uses to skip the upload when nothing changed since cache-go/restore ran.
#
# Only the "-a" index entries are hashed. Each one holds a single record:
#
#   v1 <actionID> <outputID> <size> <unixnano>
#
# Fields 1-4 are what the cache actually knows: which build inputs produce which
# output, and how big it is. Field 5 is a timestamp Go rewrites on every put, so
# including it would change the fingerprint on every run and defeat the purpose.
# The "-d" blobs need no reading either: each is named after the hash of its own
# contents and is referenced by a record, so the records already cover them.
#
# Hashing the records rather than every byte also keeps this cheap. On a 161G
# cache with ~240k entries the two differ by three orders of magnitude.
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
# entries themselves live one level down in the shard directories. Each record
# carries its own actionID, so sorting the emitted lines is enough to be
# deterministic - the file list needs no sorting of its own.
find . -mindepth 2 -name '*-a' -type f -exec awk '{print $1, $2, $3, $4}' {} + \
  | LC_ALL=C sort \
  | sha256sum \
  | cut -d' ' -f1
