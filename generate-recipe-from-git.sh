#!/usr/bin/env bash
# generate-recipe-from-git.sh - scaffold a recipe.yaml (w/o deps) from a git repo
# Usage: ./generate-recipe-from-git.sh <package-name> <repo-url> [ref]
set -euo pipefail

PKG_NAME="$1"
REPO_URL="$2"
REF="${3:-}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

CLONE_OK=0

if [ -n "$REF" ]; then
  git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$TMPDIR/src" 2>/dev/null && CLONE_OK=1
else
  git clone --quiet --depth 1 "$REPO_URL" "$TMPDIR/src" 2>/dev/null && CLONE_OK=1
fi

if [ "$CLONE_OK" -eq 0 ]; then
  # Shallow clone failed -- either REF isn't a branch/tag name (e.g. a raw
  # commit SHA), or the host only serves dumb HTTP (no shallow support at
  # all, e.g. old gitweb/cgit instances like git.kpe.io). Fall back to a
  # full clone either way.
  git clone --quiet "$REPO_URL" "$TMPDIR/src"
  if [ -n "$REF" ]; then
    git -C "$TMPDIR/src" checkout --quiet "$REF"
  fi
fi

COMMIT=$(git -C "$TMPDIR/src" rev-parse HEAD)
SHORT=$(git -C "$TMPDIR/src" rev-parse --short HEAD)
DATE=$(git -C "$TMPDIR/src" log -1 --format=%cd --date=format:%Y.%m.%d)

SYSTEM=$(basename "$REPO_URL" .git | tr '[:upper:]' '[:lower:]')

# Use the ref as version if it looks like a semver tag; else a pseudo-version.
if [[ "$REF" =~ ^v?([0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?)$ ]]; then
  VERSION="${BASH_REMATCH[1]}"
else
  VERSION="0.0.0.${DATE}"
fi

OUTDIR="recipes/${PKG_NAME}"
mkdir -p "$OUTDIR"

cat > "$OUTDIR/recipe.yaml" <<EOF
package:
  name: ${PKG_NAME}
  version: "${VERSION}"

source:
  git: ${REPO_URL}
  rev: ${COMMIT}
  submodules: false

build:
  noarch: generic
  script:
    - DEST="\$PREFIX/common-lisp/${SYSTEM}"
    - mkdir -p "\$DEST"
    - cp -r . "\$DEST/"
    - rm -rf "\$DEST/.git"

requirements:
  run:
    - cl-asdf

tests:
  - script:
      - sbcl --no-userinit --non-interactive
          --eval '(require :asdf)'
          --eval '(asdf:load-system "${SYSTEM}")'
          --eval '(asdf:test-system "${SYSTEM}")'
    requirements:
      run:
        - sbcl

about:
  repository: ${REPO_URL}
  homepage: <homepage>
  license: <license>
  summary: <summary>
  description: |
    <No description provided.>
EOF

echo "Generated $OUTDIR/recipe.yaml"
