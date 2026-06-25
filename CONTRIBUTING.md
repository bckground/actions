# bckground labs GitHub Actions Contributing Guide

## Project Overview

This repository contains reusable GitHub Actions for bckground labs projects. It's organized as a collection of composite actions that can be used across multiple repositories.

## Architecture

The repository follows GitHub Actions composite action patterns:

- **`cla-check/`** - CLA (Contributor License Agreement) checking action
- **`setup-mise/`** - Installs [mise](https://mise.jdx.dev/) and the project's tools, with optional caching (S3 or GitHub-native) of the mise data directory
- **`cache-go/`** - Go module and build caching with a selectable backend (S3 or GitHub-native), with two sub-actions sharing a helper script:
  - `restore/` - Restores the Go module and build caches
  - `save/` - Saves the Go module and build caches
  - `internal/go-cache-config.sh` - Shared script (resolves the Go configuration and computes the cache keys) that `restore` and `save` invoke via `github.action_path`, so both run it at the same ref
- Each action directory contains:
  - `action.yml` - Action definition with inputs, outputs, and steps
  - Composite actions that wrap external actions with organization-specific defaults

## Key Configuration Files

- **`mise.toml`** - mise tool versions (Node.js, prettier, actionlint, shellcheck) used for local development and in CI
- **`.prettierrc.yml`** - Prettier configuration for formatting YAML, Markdown, and JSON
- **`.github/dependabot.yml`** - Monthly GitHub Actions dependency updates with `area/dependencies` labels
- **`.github/actionlint.yaml`** - Declares the custom Blacksmith runner labels so `actionlint` accepts the `runs-on` values

## Development Commands

### Formatting

```bash
prettier --config .prettierrc.yml --write "**/*.{yml,yaml,md,markdown,json,jsonc}"
```

Formats all YAML, Markdown, and JSON files. prettier is provided through `mise` (see `mise.toml`), so run `mise install` first. The same command runs in CI through the `autofix.ci` workflow.

### Linting

```bash
actionlint
shellcheck cache-go/internal/*.sh
```

`actionlint` lints the workflow files (and runs `shellcheck` on their inline scripts); `shellcheck` lints the standalone helper scripts. Both tools are provided through `mise`. The same checks run in CI through the `lint` workflow.

### Validation

Beyond the linting and formatting above, behavior is validated through:

1. The `test` workflow, which exercises the validation guard, `setup-mise`, and the `cache-go` save/restore round-trip across the `github` and `s3` backends (the `s3` jobs run only when their secrets are available). It uses a minimal Go module fixture under `_test/fixtures/go`.
2. Using the actions in other repositories

## Action Usage Patterns

The actions follow the composite action pattern:

- Use `using: "composite"` in `action.yml`
- Wrap external actions with pinned SHA versions for security
- Accept configurable inputs with sensible defaults
- Use environment variables for sensitive data (tokens)
- Select the cache backend with the `cache-backend` input, and pass `s3-credentials` as a single JSON object input when using the `s3` backend. Both actions require an explicit value: `setup-mise` accepts `s3` | `github` | `none` (use `none` to install tools without caching), while `cache-go` accepts only `s3` | `github`, since caching is its only job and `none` would be a no-op

## Dependencies

External action dependencies are pinned to specific SHA commits for security and reproducibility:

- **cla-check**: `cla-assistant/github-action@ca4a40a7d1004f18d9960b404b97e5f30a505a08` (v2.6.1)
- **cache-go** and **setup-mise**: `actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd` (v8.0.0) for hashing, `tespkg/actions-cache@570a8ae32f67c95bcaca3f8cc88702cd318291e9` (v1.10.0) for the `s3` cache backend, and `actions/cache@2c8a9bd7457de244a408f35966fab2fb45fda9c8` (v6.0.0) for the `github` cache backend
- **setup-mise**: `jdx/mise-action@1648a7812b9aeae629881980618f079932869151` (v4.0.1)
- **CI workflows**: `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6.0.2) and `actions/setup-go@924ae3a1cded613372ab5595356fb5720e22ba16` (v6.5.0); the `lint` workflow also runs `jdx/mise-action` (above) directly
