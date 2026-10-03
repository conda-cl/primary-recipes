#!/bin/bash
set -euo pipefail

CHANNEL_URL="https://prefix.dev/digikar/common-lisp"
PACKAGES="$@"

# Usage: ./publish.sh pkg-a pkg-b pkg-c

for pkg in "${PACKAGES[@]}"; do
    (
        cd "recipes/$pkg"
        rattler-build publish recipe.yaml --to "$CHANNEL_URL"
    )
done
