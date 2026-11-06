#!/usr/bin/env bash
# Push main to origin. Run inside WSL, or via push.ps1 from Windows.
set -euo pipefail
cd "$(dirname "$0")/.."
git config credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
git status --short
git push -u origin main