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
#   CACHE_NAME          - cache-go input "name", naming both caches at once
#   MOD_CACHE_NAME      - cache-go input "mod-cache-name", naming only the
#                         module cache
#   BUILD_CACHE_NAME    - cache-go input "build-cache-name", naming only the
#                         build cache
#   DEFAULT_CACHE_NAME  - what an unset name falls back to (the calling job's id)
#   DEP_HASH    - hash of the dependency file(s), from the hashFiles() expression
#   BUILD_HASH  - fingerprint from go-build-cache-hash.sh. Optional: only save
#                 has one, because the fingerprint cannot be known until the
#                 build cache is on disk. Without it, build-key is not emitted -
#                 restore has no primary key to look up and uses
#                 build-restore-key for both.
#   GITHUB_REPOSITORY, RUNNER_OS, RUNNER_ARCH, GITHUB_OUTPUT - GitHub defaults
set -euo pipefail

: "${DEFAULT_CACHE_NAME:?DEFAULT_CACHE_NAME is required}"
: "${GITHUB_REPOSITORY:?}"
: "${RUNNER_OS:?}"
: "${RUNNER_ARCH:?}"
: "${GITHUB_OUTPUT:?}"

# "name" names both caches, so combining it with either of the specific inputs
# states the same thing twice and there is no reading that is obviously right.
# Rejecting it is cheaper than picking a precedence nobody remembers.
if [ -n "${CACHE_NAME:-}" ] && { [ -n "${MOD_CACHE_NAME:-}" ] || [ -n "${BUILD_CACHE_NAME:-}" ]; }; then
  echo "::error::'name' cannot be combined with 'mod-cache-name' or 'build-cache-name'" >&2
  exit 1
fi

# The two caches are named apart so that jobs which share dependencies but not
# their build output - or the reverse - can share the half they have in common.
mod_name="${MOD_CACHE_NAME:-${CACHE_NAME:-$DEFAULT_CACHE_NAME}}"
build_name="${BUILD_CACHE_NAME:-${CACHE_NAME:-$DEFAULT_CACHE_NAME}}"

if [ -z "${DEP_HASH:-}" ]; then
  echo "::error::no dependency files matched; unable to compute the go cache key" >&2
  exit 1
fi

go_version="$(go env GOVERSION | sed 's/^go//')"
mod_cache="$(go env GOMODCACHE)"
build_cache="$(go env GOCACHE)"

# GOCACHEPROG names a program that implements the build cache externally. The
# go command then hands every lookup and store to it over stdin/stdout, and
# never touches the build cache directory, which stays empty however much is
# compiled. Blacksmith's runners set one, so that the build cache lives on
# their servers rather than the runner's disk.
#
# Restoring and saving that empty directory moves nothing and tells the caller
# nothing, so both are skipped when a program owns the cache.
if [ -n "$(go env GOCACHEPROG)" ]; then
  build_cache_external="true"
else
  build_cache_external="false"
fi

repo="${GITHUB_REPOSITORY//\//-}"
suffix="at-${repo}-on-${RUNNER_OS}-${RUNNER_ARCH}"
mod_scope="${go_version}-${mod_name}-${suffix}"
build_scope="${go_version}-${build_name}-${suffix}"

{
  echo "go_version=${go_version}"
  echo "mod_cache=${mod_cache}"
  echo "build_cache=${build_cache}"
  echo "build-cache-external=${build_cache_external}"
  echo "mod-key=go-mod-${mod_scope}-${DEP_HASH}"
  echo "mod-restore-key=go-mod-${mod_scope}-"
  echo "build-restore-key=go-build-${build_scope}-"
  if [ -n "${BUILD_HASH:-}" ]; then
    echo "build-key=go-build-${build_scope}-${BUILD_HASH}"
  fi
} | tee -a "$GITHUB_OUTPUT"
