#!/usr/bin/env bash
#
# update-recipe.sh — bump one flat rattler-build recipe.yaml.
#
#   package.version has 3 dot-separated elements  -> pin to latest git tag
#   package.version has 6 dot-separated elements  -> pin to latest commit,
#     version becomes "0.0.0.YYYY.MM.DD" from the commit's date
#
# Assumes the recipe shape you're using:
#   package:
#     version: "..."
#   source:
#     git: <url>
#     rev: <sha>      # or: tag: <tag>
#
# Requires: git only.
#
# Usage: ./update-recipe.sh lisp-project-name [--dry-run] [--branch BRANCH]

pkg="$1"

pixi -q run sbcl --noinform --no-userinit --noprint --non-interactive \
     --eval '(require :asdf)' \
     --load rattler-recipe-manager.asd \
     --eval '(handler-bind ((warning (function muffle-warning)))
               (asdf:load-system :rattler-recipe-manager))' \
     --eval '(trace)' \
     --eval "(rattler-recipe-manager:update-recipe \"$pkg\")" \
     --quit
