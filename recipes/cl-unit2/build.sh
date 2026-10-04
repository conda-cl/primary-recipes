#!/bin/bash
set -euo pipefail
DEST="$PREFIX/common-lisp/clunit2"
mkdir -p "$DEST"
cp -r . "$DEST/"
rm -rf "$DEST/.git"
