#!/bin/zsh

set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="$(<"${ROOT}/VERSION")"
DIST_DIR="${ROOT}/dist"
ARCHIVE_BASENAME="gws-switch-${VERSION}"
STAGE_DIR="${DIST_DIR}/${ARCHIVE_BASENAME}"
ARCHIVE_PATH="${DIST_DIR}/${ARCHIVE_BASENAME}.tar.gz"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
mkdir -p "$DIST_DIR"

cp -R \
  "${ROOT}/bin" \
  "${ROOT}/src" \
  "${ROOT}/scripts" \
  "${ROOT}/.github" \
  "${ROOT}/CHANGELOG.md" \
  "${ROOT}/README.md" \
  "${ROOT}/config.example.json" \
  "${ROOT}/VERSION" \
  "${STAGE_DIR}/"

tar -C "$DIST_DIR" -czf "$ARCHIVE_PATH" "$ARCHIVE_BASENAME"
shasum -a 256 "$ARCHIVE_PATH"
print -r -- "archive: $ARCHIVE_PATH"
