#!/bin/bash
set -euo pipefail

# cl-cffi -> common-lisp/cffi, cl-cffi-grovel -> common-lisp/cffi-grovel
DEST="$PREFIX/common-lisp/${PKG_NAME#cl-}"
mkdir -p "$DEST"

# Top-level files the .asd files may read at load time
for f in LICENSE version.lisp-expr; do
  if [ -f "$f" ]; then cp "$f" "$DEST/"; fi
done

for f in $ASD_FILES; do cp "$f" "$DEST/"; done
for d in $SRC_DIRS; do cp -r "$d" "$DEST/"; done

# Windows toolchain setup is only needed by the grovel output
if [ "$PKG_NAME" = "cl-cffi-grovel" ] && [ "$target_platform" = "win-64" ]; then
      cp "$PREFIX/Library/bin/ffi-8.dll" "$PREFIX/Library/bin/libffi-8.dll"
      mkdir -p "$PREFIX/etc/conda/activate.d"
      cat > "$PREFIX/etc/conda/activate.d/cl-cffi-grovel.bat" <<'EOF'
@echo off
set "CC=x86_64-w64-mingw32-gcc"
set "PKG_CONFIG_PATH=%CONDA_PREFIX%\Library\lib\pkgconfig;%PKG_CONFIG_PATH%"
set "CFLAGS=-I%CONDA_PREFIX%\Library\include %CFLAGS%"
set "LDFLAGS=-L%CONDA_PREFIX%\Library\lib %LDFLAGS%"
EOF
fi
