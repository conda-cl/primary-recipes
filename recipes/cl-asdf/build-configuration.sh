#!/bin/bash
set -euxo pipefail

mkdir -p "$PREFIX/etc/conda/activate.d"

# Tell ASDF where to find Common Lisp systems
cat > "$PREFIX/etc/conda/activate.d/cl-asdf.sh" <<'EOF'
if [ -n "${PIXI_PROJECT_ROOT:-}" ]; then
  export CL_SOURCE_REGISTRY="${PIXI_PROJECT_ROOT}//:${CONDA_PREFIX}/common-lisp//"
else
  export CL_SOURCE_REGISTRY="${CONDA_PREFIX}/common-lisp//"
fi
EOF

# Same, for cmd.exe activation on Windows
cat > "$PREFIX/etc/conda/activate.d/cl-asdf.bat" <<'EOF'
@echo off
if defined PIXI_PROJECT_ROOT (
  set "CL_SOURCE_REGISTRY=%PIXI_PROJECT_ROOT%//;%CONDA_PREFIX%/common-lisp//"
) else (
  set "CL_SOURCE_REGISTRY=%CONDA_PREFIX%/common-lisp//"
)
EOF
