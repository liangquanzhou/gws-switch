#!/bin/zsh

set -euo pipefail

ROOT="${0:A:h:h}"
TARGET_DIR="${HOME}/.local/bin"

mkdir -p "$TARGET_DIR"

for legacy in gws gws-use gws-gmail gws-didi gws-who gws-accounts gws-do gws-login gws-status gws-doctor gws-config-init; do
  rm -f "${TARGET_DIR}/${legacy}"
done

for name in gws-switch gws-switch-use gws-switch-gmail gws-switch-didi gws-switch-who gws-switch-accounts gws-switch-do gws-switch-login gws-switch-status gws-switch-doctor gws-switch-config-init; do
  ln -sf "${ROOT}/bin/${name}" "${TARGET_DIR}/${name}"
  print -r -- "linked ${TARGET_DIR}/${name} -> ${ROOT}/bin/${name}"
done
