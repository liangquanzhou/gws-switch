#!/bin/zsh

set -euo pipefail

ROOT="${0:A:h:h}"

zsh "${ROOT}/tests/smoke.zsh"
