#!/usr/bin/env bash
# Render a scene to a PNG with no desktop attached.
#
#   ./shoot.sh                                   # main scene -> shots/main.png
#   ./shoot.sh scenes/player/player.tscn out.png
#   INPUT=right,right,down ./shoot.sh  # walk first, then shoot
#
# Runs the real game under Godot's Compatibility (OpenGL) renderer against
# Mesa's software rasteriser inside a virtual X server. The capture happens
# from inside the running game, so the frame goes through the project's own
# stretch settings and camera — what you see is what the window shows.
#
# Slow (seconds per shot) and software-rendered, so it says nothing about
# performance. For "does this look right", it is the real thing.

set -euo pipefail
cd "$(dirname "$0")"

SCENE="${1:-}"
OUT="${2:-shots/main.png}"
SETTLE="${SETTLE:-0.3}"
GODOT="${GODOT:-godot}"

# Window size: the 480x270 base at 2x. Integer scaling keeps pixels square.
WINDOW="${WINDOW:-960x540}"

mkdir -p "$(dirname "$OUT")"
ABS_OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

ARGS=(--capture "$ABS_OUT" --settle "$SETTLE")
if [ -n "${INPUT:-}" ]; then
  ARGS+=(--input "$INPUT")
fi
if [ -n "$SCENE" ]; then
  case "$SCENE" in res://*) ;; *) SCENE="res://$SCENE" ;; esac
  ARGS+=(--scene "$SCENE")
fi

LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
  xvfb-run -a --server-args="-screen 0 1920x1080x24" \
  "$GODOT" --rendering-driver opengl3 --audio-driver Dummy \
  --resolution "$WINDOW" -- "${ARGS[@]}"

echo "-> $OUT"
