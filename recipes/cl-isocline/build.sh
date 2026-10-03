#!/bin/bash
set -euo pipefail

DEST="$PREFIX/common-lisp/cl-isocline"
mkdir -p "$DEST"
cp -r . "$DEST/"
rm -rf "$DEST/.git"

case "$target_platform" in
  linux-*)
      CC_BIN="$CC"
      FLAGS="-shared -fPIC"
      LIB="libisocline.so"
      ;;
  osx-*)
      CC_BIN="$CC"
      FLAGS="-dynamiclib -fPIC"
      LIB="libisocline.dylib"
      ;;
  win-*)
      CC_BIN="x86_64-w64-mingw32-gcc"
      FLAGS="-shared"
      LIB="libisocline.dll"
      ;;
esac

"$CC_BIN" $FLAGS -O2 -DNDEBUG -Iisocline/include isocline/src/isocline.c -o "$DEST/$LIB"
rm -rf "$DEST/isocline"
