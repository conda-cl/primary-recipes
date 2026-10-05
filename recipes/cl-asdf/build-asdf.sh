#!/bin/bash
set -euxo pipefail

mkdir -p "$PREFIX/common-lisp/asdf"

# Install ASDF's source tree
cp -r "$SRC_DIR"/* "$PREFIX/common-lisp/asdf"
rm -rf "$PREFIX/common-lisp/asdf/.git"
