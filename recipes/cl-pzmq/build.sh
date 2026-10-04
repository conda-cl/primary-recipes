#!/bin/bash
set -euo pipefail
DEST="$PREFIX/common-lisp/pzmq"
mkdir -p "$DEST"
cp -r . "$DEST/"
rm -rf "$DEST/.git"
