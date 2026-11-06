#!/usr/bin/env bash
# Open the draft window for phase N: signed tag gates-draft-pN, pushed. Usage: tag_draft.sh 0
set -euo pipefail
N="${1:?usage: tag_draft.sh <phase number>}"
cd "$(dirname "$0")/.."
git tag -s "gates-draft-p${N}" -m "open Phase ${N} gate draft window"
git push origin "gates-draft-p${N}"
git tag -v "gates-draft-p${N}"