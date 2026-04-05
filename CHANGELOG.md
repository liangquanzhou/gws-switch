# Changelog

All notable changes to `gws-switch` will be documented in this file.

The format is based on Keep a Changelog.

## [0.1.1] - 2026-04-05

### Added

- Issue templates for bug reports and feature requests.
- A maintained changelog for future releases.

### Changed

- Updated the zsh loader to prefer the Homebrew install before falling back to the local dev checkout.
- Clarified the README install guidance so Homebrew is the default recommended path.

## [0.1.0] - 2026-04-05

### Added

- Multi-account wrapper commands under the `gws-switch-*` namespace.
- Explicit account manifest support via `~/.config/gws-switch/accounts.json`.
- `gws-switch-doctor` for environment and credential diagnostics.
- `gws-switch-config-init` for bootstrapping local wrapper config.
- Homebrew formula for stable installation.

### Changed

- Standardized public command names to `gws-switch-*` to avoid shadowing upstream `gws`.
- Routed `gws auth ...` through the currently selected account config.
- Reduced the dotfiles module to a thin loader that can prefer the Homebrew install.

### Security

- Kept live runtime credentials and local config files out of the tracked repository.
