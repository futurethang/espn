#!/usr/bin/env bash
# Build the web export into build/web/.
#
#   tools/export_web.sh
#
# Needs Godot's export templates for the pinned version. They are a separate
# ~1.3GB download from the engine:
#   https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz
# Unzip it and put the web_*.zip files in:
#   ~/.local/share/godot/export_templates/4.7.stable/
# Only the web_* templates are needed; the rest can be deleted.
#
# The preset sets thread support OFF. A threaded Godot web build needs
# SharedArrayBuffer, which needs cross-origin isolation headers, which
# GitHub Pages cannot send. The no-threads build runs anywhere.

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT="build/web"

mkdir -p "$OUT"
# Keep Godot from indexing its own output: without this it imports the
# exported PNGs on the next scan and litters the folder with .import files.
touch build/.gdignore
"$GODOT" --headless --export-release "Web" "$OUT/index.html"

# Stops GitHub Pages running the output through Jekyll, which would drop any
# file or folder beginning with an underscore.
touch "$OUT/.nojekyll"
rm -f "$OUT"/*.import

echo "built $OUT ($(du -sh "$OUT" | cut -f1))"
