#!/usr/bin/env bash
#
# Shared helper for the cache-go restore/save actions. Resolves the Go
# configuration and emits every cache key to $GITHUB_OUTPUT, so that no key is
# ever assembled in an action.yml.
#
# The module cache and the build cache are keyed independently:
#
#   - the module cache is fully determined by the dependency file, so it is
#     keyed on that file's hash;
#   - the build cache has no equivalent input, so it is keyed on a fingerprint
#     of its own contents (see go-build-cache-hash.sh). The dependency hash is
#     deliberately absent from it, since a dependency change does not
#     invalidate the build cache.
#
# It is invoked via ${{ github.action_path }}/../internal/go-cache-config.sh so
# that restore and save always run the helper at the same ref they were checked
# out at (no floating @main reference).
#
# Expected environment:
#   CACHE_NAME  - the cache name (cache-go input "name")
#   DEP_HASH    - hash of the dependency file(s), from the hashFiles() expression
#   BUILD_HASH  - fingerprint from go-build-cache-hash.sh. Optional: only save
#                 has one, because the fingerprint cannot be known until the
#                 build cache is on disk. Without it, build-key is not emitted -
#                 restore has no primary key to look up and uses
#                 build-restore-key for both.
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
scope="${go_version}-${CACHE_NAME}-at-${repo}-on-${RUNNER_OS}-${RUNNER_ARCH}"

{
  echo "go_version=${go_version}"
  echo "mod_cache=${mod_cache}"
  echo "build_cache=${build_cache}"
  echo "mod-key=go-mod-${scope}-${DEP_HASH}"
  echo "mod-restore-key=go-mod-${scope}-"
  echo "build-restore-key=go-build-${scope}-"
  if [ -n "${BUILD_HASH:-}" ]; then
    echo "build-key=go-build-${scope}-${BUILD_HASH}"
  fi
} | tee -a "$GITHUB_OUTPUT"
