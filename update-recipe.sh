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

set -euo pipefail

pkg="NIL"
dry_run=0
branch="HEAD"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) dry_run=1; shift ;;
        --branch) branch="$2"; shift 2 ;;
        *) pkg="$1"; shift ;;
    esac
done

recipe="recipes/$pkg/recipe.yaml"

version=$(grep -m1 -E '^\s*version:' "$recipe" | sed -E 's/^\s*version:\s*"?([^"#]*)"?.*/\1/')
url=$(grep -m1 -E '^\s*git:' "$recipe" | sed -E 's/^\s*git:\s*//')
echo $url

[[ -n "$version" ]] || { echo "no version: found in $recipe" >&2; exit 1; }
[[ -n "$url" ]]     || { echo "no git: found in $recipe" >&2; exit 1; }

n=$(( $(grep -o '\.' <<<"$version" | wc -l) + 1 ))

# Each branch just decides: new_version, field ("rev" or "tag"), and value.
if [[ "$n" == "6" ]]; then
    tmp=$(mktemp -d)
    if [[ "$branch" == "HEAD" ]]; then
        git clone --quiet --depth 1 "$url" "$tmp"
    else
        git clone --quiet --depth 1 --branch "$branch" "$url" "$tmp"
    fi
    sha=$(git -C "$tmp" rev-parse HEAD)
    date=$(git -C "$tmp" log -1 --date=format:'%Y.%m.%d' --format=%cd)
    rm -rf "$tmp"
    new_version="0.0.0.$date"
    if grep -qE '^\s*tag:' "$recipe"; then field="tag"; value="$sha"
    else field="rev"; value="$sha"
    fi
    echo "$pkg: commit strategy -> ${sha:0:8} ($date)  version $version -> $new_version"
else
    read -r tag sha < <(
        git ls-remote --tags "$url" \
            | awk -F'\t' '{ref=$2; sub("refs/tags/","",ref); sub(/\^\{\}$/,"",ref); sha[ref]=$1} END{for (t in sha) print t, sha[t]}' \
            | sort -k1,1V | tail -n1
    )
    new_version="${tag#v}"; new_version="${new_version#V}"
    if grep -qE '^\s*tag:' "$recipe"; then field="tag"; value="$tag"
    else field="rev"; value="$sha"
    fi
    echo "$pkg: tag strategy -> $tag (${sha:0:8})  version $version -> $new_version"
fi


if [[ "$dry_run" == "0" ]]; then
    sed -i -E "s/^(\s*version:).*/\1 \"$new_version\"/" "$recipe"
    sed -i -E "s/^(\s*$field:).*/\1 $value/" "$recipe"
fi
