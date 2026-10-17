#!/usr/bin/env bash
# Publish build/web/ to the gh-pages branch.
#
#   tools/export_web.sh && tools/deploy_web.sh
#
# gh-pages is kept as a single orphan commit and force-pushed, so the 40MB
# wasm never accumulates in history. Nothing on master is touched.
#
# One-time setup, in the repository's Settings -> Pages:
#   Source: "Deploy from a branch", Branch: gh-pages, folder: / (root)

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

[ -f "$ROOT/build/web/index.html" ] || { echo "no build — run tools/export_web.sh first" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SOURCE_REV="$(git rev-parse --short HEAD)"

git worktree add --detach "$WORK" >/dev/null
(
  set -e
  cd "$WORK"
  # A fresh throwaway branch name each time: `--orphan gh-pages` fails if a
  # local gh-pages already exists, which it does from the second run on.
  git checkout --orphan "deploy-$$" >/dev/null 2>&1
  git rm -rqf . >/dev/null 2>&1 || true
  cp -r "$ROOT/build/web/." .
  touch .nojekyll
  rm -f ./*.import
  git add -A
  git commit -q -m "Deploy web build from $SOURCE_REV"
  git push -f origin "HEAD:gh-pages"
)
git worktree remove --force "$WORK"
git worktree prune
echo "pushed gh-pages (from $SOURCE_REV)"
