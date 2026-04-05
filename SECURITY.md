# Security Policy

## Supported Versions

The latest tagged release is the supported version for security fixes.

## Reporting

Do not file public issues containing:

- OAuth client secrets
- refresh tokens
- encrypted runtime credentials
- local config files under `~/.config/gws*`

If you need to report a security issue, sanitize all credentials first and use a private disclosure channel when possible.

## Safe Debugging

Prefer sharing:

- `gws-switch-doctor` output after sanitization
- `gws-switch-status` output after sanitization
- exact commands and high-level symptoms

Do not paste raw credential files into issues, pull requests, or chat logs.
