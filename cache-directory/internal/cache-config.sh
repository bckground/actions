#!/usr/bin/env bash
#
# Shared helper for the cache-directory restore/save actions. Resolves the
# cache configuration and emits every cache key to $GITHUB_OUTPUT, so that no
# key is ever assembled in an action.yml.
#
# The directory has no input that determines its contents - that is the whole
# reason this action exists rather than a bare actions/cache keyed on
# hashFiles() - so it is keyed on a fingerprint of its own contents (see
# directory-hash.sh).
#
# It is invoked via ${{ github.action_path }}/../internal/cache-config.sh so
# that restore and save always run the helper at the same ref they were checked
# out at (no floating @main reference).
#
# Expected environment:
#   CACHE_NAME      - the cache-directory input "name"
#   CACHE_DIRECTORY - the cache-directory input "path" (a leading ~ is expanded)
#   DIR_HASH        - fingerprint from directory-hash.sh. Optional: only save
#                     has one, because the fingerprint cannot be known until the
#                     directory is on disk. Without it, "key" is not emitted -
#                     restore has no primary key to look up and uses
#                     "restore-key" for both.
#   GITHUB_REPOSITORY, RUNNER_OS, RUNNER_ARCH, GITHUB_OUTPUT - GitHub defaults
set -euo pipefail

: "${CACHE_NAME:?CACHE_NAME is required}"
: "${CACHE_DIRECTORY:?CACHE_DIRECTORY is required}"
: "${GITHUB_REPOSITORY:?}"
: "${RUNNER_OS:?}"
: "${RUNNER_ARCH:?}"
: "${GITHUB_OUTPUT:?}"

# Resolved exactly as directory-hash.sh resolves it; see the note there.
directory="${CACHE_DIRECTORY/#\~/${HOME}}"

repo="${GITHUB_REPOSITORY//\//-}"
scope="${CACHE_NAME}-at-${repo}-on-${RUNNER_OS}-${RUNNER_ARCH}"

# Name of the variable cache-directory/restore leaves in $GITHUB_ENV for
# cache-directory/save to read. GITHUB_ENV is job-wide and a job may cache more
# than one directory, so the name is derived from CACHE_NAME instead of being a
# constant - which is also why two directories cached in the same job need
# distinct "name" inputs.
slug="$(printf '%s' "$CACHE_NAME" | tr -c '[:alnum:]' '_' | tr '[:lower:]' '[:upper:]')"

{
  echo "directory=${directory}"
  echo "hash-env-var=CACHE_DIRECTORY_HASH_${slug}"
  echo "restore-key=dir-${scope}-"
  if [ -n "${DIR_HASH:-}" ]; then
    echo "key=dir-${scope}-${DIR_HASH}"
  fi
} | tee -a "$GITHUB_OUTPUT"
