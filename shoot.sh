#!/usr/bin/env bash
# Render a scene to a PNG with no desktop attached.
#
#   ./shoot.sh                                  # main scene -> shots/main.png
#   ./shoot.sh scenes/player/player.tscn out.png
#
# Runs Godot's Compatibility (OpenGL) renderer against Mesa's software
# rasteriser inside a virtual X server, so this works in a headless container.
# Slow — seconds per shot — but it is a real frame from the real engine.

set -euo pipefail
cd "$(dirname "$0")"

SCENE="${1:-res://scenes/main/main.tscn}"
OUT="${2:-shots/main.png}"
FRAMES="${FRAMES:-10}"
GODOT="${GODOT:-godot}"

case "$SCENE" in res://*) ;; *) SCENE="res://$SCENE" ;; esac
mkdir -p "$(dirname "$OUT")"
ABS_OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
  xvfb-run -a --server-args="-screen 0 1920x1080x24" \
  "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --resolution 960x540 \
  --script res://tools/screenshot.gd -- \
  --scene "$SCENE" --out "$ABS_OUT" --frames "$FRAMES"

echo "-> $OUT"
