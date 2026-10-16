#!/usr/bin/env bash
# Fails if site files changed between BASE and HEAD but CACHE_VERSION in sw.js did not.
# Usage: check-cache-version.sh <base-ref> [head-ref]
set -euo pipefail
BASE="${1:?base ref required}"; HEAD="${2:-HEAD}"
# Files that trigger a bump: the precached ASSETS list in sw.js at HEAD ('/' = index.html).
assets=$(git show "$HEAD:sw.js" | sed -n '/const ASSETS/,/\]/p' | grep -oE "'/[^']*'" | tr -d "'" | sed -e 's#^/$#/index.html#' -e 's#^/##' | sort -u)
changed=$(git diff --name-only "$BASE" "$HEAD" | grep -Fxf <(echo "$assets") || true)
if [ -z "$changed" ]; then echo "No cached site files changed; no bump needed."; exit 0; fi
ver() { git show "$1:sw.js" 2>/dev/null | sed -nE "s/.*const CACHE_VERSION *= *['\"]([^'\"]+)['\"].*/\1/p" | head -1; }
old=$(ver "$BASE"); new=$(ver "$HEAD")
echo "Changed site files:"; echo "$changed" | sed 's/^/  - /'
echo "CACHE_VERSION: base='$old' head='$new'"
if [ -z "$new" ]; then echo "::error file=sw.js::CACHE_VERSION not found in sw.js"; exit 1; fi
if [ "$old" = "$new" ]; then
  echo "::error file=sw.js::Site files changed but CACHE_VERSION ('$new') was not bumped. Bump it (e.g. dd-studio-v7)."
  exit 1
fi
echo "OK: CACHE_VERSION bumped."
