#!/usr/bin/env bash
#
# Shared helper for the cache-go restore/save actions. Resolves the Go
# configuration and emits the cache keys to $GITHUB_OUTPUT.
#
# It is invoked via ${{ github.action_path }}/../internal/go-cache-config.sh so
# that restore and save always run the helper at the same ref they were checked
# out at (no floating @main reference).
#
# Expected environment:
#   CACHE_NAME  - the cache name (cache-go input "name")
#   DEP_HASH    - hash of the dependency file(s), from the hashFiles() expression
#   GITHUB_REPOSITORY, RUNNER_OS, RUNNER_ARCH, GITHUB_OUTPUT - GitHub defaults
set -euo pipefail

: "${CACHE_NAME:?CACHE_NAME is required}"
: "${GITHUB_REPOSITORY:?}"
: "${RUNNER_OS:?}"
: "${RUNNER_ARCH:?}"
: "${GITHUB_OUTPUT:?}"

if [ -z "${DEP_HASH:-}" ]; then
  echo "::error::no dependency files matched; unable to compute the go cache key" >&2
  exit 1
fi

go_version="$(go env GOVERSION | sed 's/^go//')"
mod_cache="$(go env GOMODCACHE)"
build_cache="$(go env GOCACHE)"

repo="${GITHUB_REPOSITORY//\//-}"
prefix="go-${go_version}-${CACHE_NAME}-at-${repo}-on-${RUNNER_OS}-${RUNNER_ARCH}"

{
  echo "go_version=${go_version}"
  echo "mod_cache=${mod_cache}"
  echo "build_cache=${build_cache}"
  echo "key=${prefix}-${DEP_HASH}"
  echo "restore-key=${prefix}-"
} | tee -a "$GITHUB_OUTPUT"
