#!/usr/bin/env bash
#
# Shared helper for the cache-directory restore/save actions. Prints a
# fingerprint of the cached directory, which cache-directory/save turns into
# the cache key and uses to skip the upload when nothing changed since
# cache-directory/restore ran.
#
# cache-go fingerprints the Go build cache from its file names alone, because
# every output there is named after the sha256 of its own contents. An
# arbitrary directory carries no such guarantee, so this reads the bytes: the
# fingerprint is the hash of `sha256sum` over every regular file in a stable
# order, which covers the contents and the paths together.
#
# Metadata is deliberately left out. mtimes, ownership and permissions all
# churn across runners and checkouts without changing what the directory
# holds, and folding them in would mint a fresh fingerprint every run, so save
# would never get to skip an upload.
#
# Non-regular files are skipped along with everything `find -type f` does not
# match, symlinks included, so a directory whose only change is a retargeted
# symlink reads as unchanged. Caches this action is meant for do not work that
# way.
#
# It is invoked via ${{ github.action_path }}/../internal/directory-hash.sh so
# that restore and save always run the helper at the same ref they were checked
# out at (no floating @main reference).
#
# Expected environment:
#   CACHE_DIRECTORY - the directory to fingerprint (a leading ~ is expanded)
set -euo pipefail

: "${CACHE_DIRECTORY:?CACHE_DIRECTORY is required}"

# Callers write the path the way they would for `with: path:`, where
# actions/cache expands a leading ~ itself. Nothing expands it here, so this
# does it by hand - and cache-config.sh resolves it the same way, so both
# helpers always agree on which directory is meant.
directory="${CACHE_DIRECTORY/#\~/${HOME}}"

# A missing directory is a valid state: the restore may have missed, and save
# can run for a job that never created it. It hashes to the digest of the
# empty input, which is stable and distinct from any populated directory.
if [ ! -d "$directory" ]; then
  printf '' | sha256sum | cut -d' ' -f1
  exit 0
fi

cd "$directory" || exit 1

# -print0 / sort -z / xargs -0 keep this correct for paths holding whitespace
# or newlines. sha256sum prints "<digest>  <path>", so hashing its output
# covers the names as well as the bytes. A large directory needs several xargs
# invocations; xargs preserves input order, so the result stays stable.
find . -type f -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 -r sha256sum \
  | sha256sum \
  | cut -d' ' -f1
