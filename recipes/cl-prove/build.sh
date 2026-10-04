#!/bin/bash
set -euo pipefail
DEST="$PREFIX/common-lisp/prove"
mkdir -p "$DEST"
cp -r . "$DEST/"
rm -rf "$DEST/.git"
