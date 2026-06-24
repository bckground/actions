# bckground labs GitHub Actions Contributing Guide

## Project Overview

This repository contains reusable GitHub Actions for bckground labs projects. It's organized as a collection of composite actions that can be used across multiple repositories.

## Architecture

The repository follows GitHub Actions composite action patterns:

- **`cla-check/`** - CLA (Contributor License Agreement) checking action
- **`setup-mise/`** - Installs [mise](https://mise.jdx.dev/) and the project's tools, with optional caching (S3 or GitHub-native) of the mise data directory
- **`cache-go/`** - Go module and build caching with a selectable backend (S3 or GitHub-native), split into composable sub-actions:
  - `internal/` - Resolves the Go configuration (version, cache paths) and computes the cache keys; shared by the other two
  - `restore/` - Restores the Go module and build caches
  - `save/` - Saves the Go module and build caches
- Each action directory contains:
  - `action.yml` - Action definition with inputs, outputs, and steps
  - Composite actions that wrap external actions with organization-specific defaults

## Key Configuration Files

- **`mise.toml`** - mise tool versions (Node.js, prettier) used for local development and in CI via `setup-mise`
- **`.prettierrc.yml`** - Prettier configuration for formatting YAML, Markdown, and JSON
- **`.github/dependabot.yml`** - Monthly GitHub Actions dependency updates with `area/dependencies` labels

## Development Commands

### Formatting

```bash
prettier --config .prettierrc.yml --write "**/*.{yml,yaml,md,markdown,json,jsonc}"
```

Formats all YAML, Markdown, and JSON files. prettier is provided through `mise` (see `mise.toml`), so run `mise install` first. The same command runs in CI through the `autofix.ci` workflow.

### Validation

Since these are GitHub Actions, testing is typically done by:

1. Using the actions in other repositories
2. Validating formatting with prettier
3. Checking action.yml schema compliance

## Action Usage Patterns

The actions follow the composite action pattern:

- Use `using: "composite"` in `action.yml`
- Wrap external actions with pinned SHA versions for security
- Accept configurable inputs with sensible defaults
- Use environment variables for sensitive data (tokens)
- Select the cache backend with the `cache_backend` input (`s3` | `github` | `none`, default `none`) for the cache-backed actions; pass `s3_credentials` as a single JSON object input when using the `s3` backend

## Dependencies

External action dependencies are pinned to specific SHA commits for security and reproducibility:

- **cla-check**: `cla-assistant/github-action@ca4a40a7d1004f18d9960b404b97e5f30a505a08` (v2.6.1)
- **cache-go** and **setup-mise**: `actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd` (v8.0.0) for hashing, `tespkg/actions-cache@570a8ae32f67c95bcaca3f8cc88702cd318291e9` (v1.10.0) for the `s3` cache backend, and `actions/cache@2c8a9bd7457de244a408f35966fab2fb45fda9c8` (v6.0.0) for the `github` cache backend
- **setup-mise**: `jdx/mise-action@1648a7812b9aeae629881980618f079932869151` (v4.0.1)
