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

git worktree add --detach "$WORK" >/dev/null
(
  cd "$WORK"
  git checkout --orphan gh-pages >/dev/null 2>&1
  git rm -rqf . >/dev/null 2>&1 || true
  cp -r "$ROOT/build/web/." .
  touch .nojekyll
  git add -A
  git commit -q -m "Deploy web build from $(git -C "$ROOT" rev-parse --short HEAD)"
  git push -f -u origin gh-pages 2>&1 | tail -2
)
git worktree remove --force "$WORK"
echo "pushed gh-pages"
