# Contributing

## Development

Run the local smoke test before opening a pull request:

```bash
zsh scripts/test.sh
```

The test suite uses a fake upstream `gws` binary and temporary config directories, so it is safe to run without real Google credentials.

## Pull Requests

- Keep public commands under the `gws-switch-*` namespace.
- Do not commit live credentials, encrypted runtime credentials, or local config files.
- Update `README.md` and `CHANGELOG.md` when behavior changes.

## Release

1. Update `VERSION`.
2. Update `CHANGELOG.md`.
3. Build the release archive:

```bash
zsh scripts/package-release.sh
```

4. Commit the release changes.
5. Create and push a Git tag like `v0.1.2`.
6. Publish the GitHub release with the generated tarball.
7. Update the Homebrew tap formula URL, `sha256`, and version.
