#!/usr/bin/env bash
# Deploy the current working tree to a Surge preview URL.
#
#   scripts/preview.sh                  -> https://puny-cherry.surge.sh
#   scripts/preview.sh my-test.surge.sh -> https://my-test.surge.sh
#
# Only git-tracked files are published (with their current, possibly uncommitted,
# contents). CNAME is left out so Surge never targets the production domain, and
# robots.txt is replaced so search engines don't index the preview.
set -euo pipefail

DOMAIN="${1:-puny-cherry.surge.sh}"
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

cd "$ROOT"
git ls-files -z | while IFS= read -r -d '' f; do
  case "$f" in
    CNAME|README.md|.gitignore|scripts/*|.github/*|*.php) continue ;;
  esac
  [ -f "$f" ] || continue # tracked but deleted in the working tree
  mkdir -p "$BUILD/$(dirname "$f")"
  cp "$f" "$BUILD/$f"
done

printf 'User-agent: *\nDisallow: /\n' > "$BUILD/robots.txt"

echo "Deploying $(find "$BUILD" -type f | wc -l | tr -d ' ') files to https://$DOMAIN"
npx --yes surge@0.46.0 "$BUILD" "$DOMAIN"
