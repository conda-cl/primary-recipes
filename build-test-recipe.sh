#!/bin/bash
set -euo pipefail

CHANNEL_URL="https://prefix.dev/digikar/common-lisp"
OUT="$(pwd)/output"
TEST_SCRIPT="./integrations/test-integrations.sh"
GROUP_FILE=""
PACKAGES=()

# Usage: ./build-test-recipe.sh [-g integrations/numericals.txt] pkg-a pkg-b pkg-c
#
# Example: ash recipe-test-and-publish.sh -g integrations/mgl-pax cl-autoload named-readtables cl-pythonic-string-reader cl-dref mgl-pax cl-try
#
# I wished the example could work, but I have spent several hours on this to
# actually resolve the circular-repo dependencies, and even though I was able to
# get it to work the tests fail.
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -g|--group)
            GROUP_FILE="$2"
            shift 2
            ;;
        *)
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

mkdir -p "$OUT"

# 1. Run the recipes
for pkg in "${PACKAGES[@]}"; do
    (
        cd "recipes/$pkg"
        rattler-build build --recipe recipe.yaml \
                      --output-dir "$OUT" \
                      --channel "$OUT" \
                      --channel "$CHANNEL_URL" \
                      --allow-symlinks-on-windows
    )
done

# 2. Run the integration tests if provided
if [[ -n "$GROUP_FILE" ]]; then
    "$TEST_SCRIPT" "$OUT" "$GROUP_FILE" "${PACKAGES[@]}"
fi
