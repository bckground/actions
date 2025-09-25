# bckground labs GitHub Actions Contributing Guide

## Project Overview

This repository contains reusable GitHub Actions for bckground labs projects. It's organized as a collection of composite actions that can be used across multiple repositories.

## Architecture

The repository follows GitHub Actions composite action patterns:

- **`yaml-lint/`** - YAML linting action using yamllint
- **`cla-check/`** - CLA (Contributor License Agreement) checking action
- Each action directory contains:
  - `action.yml` - Action definition with inputs, outputs, and steps
  - Composite actions that wrap external actions with organization-specific defaults

## Key Configuration Files

- **`.yamllint`** - YAML linting configuration with quoted-strings enabled and line-length disabled
- **`.github/dependabot.yml`** - Monthly GitHub Actions dependency updates with `area/dependencies` labels

## Development Commands

### Linting

```bash
yamllint .
```

Uses the `.yamllint` configuration file to lint all YAML files in the repository.

### Validation

Since these are GitHub Actions, testing is typically done by:

1. Using the actions in other repositories
2. Validating YAML syntax with yamllint
3. Checking action.yml schema compliance

## Action Usage Patterns

Both actions follow the composite action pattern:

- Use `using: "composite"` in `action.yml`
- Wrap external actions with pinned SHA versions for security
- Accept configurable inputs with sensible defaults
- Use environment variables for sensitive data (tokens)

## Dependencies

- **yaml-lint action**: Uses `ibiqlik/action-yamllint@2576378a8e339169678f9939646ee3ee325e845c` (v3.1.1)
- **cla-check action**: Uses `cla-assistant/github-action@ca4a40a7d1004f18d9960b404b97e5f30a505a08` (v2.6.1)

All external action dependencies are pinned to specific SHA commits for security and reproducibility.
