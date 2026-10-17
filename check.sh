#!/usr/bin/env bash
# Verify the project without opening the editor.
#
#   ./check.sh
#
# 1. Imports the project headlessly. This is what catches GDScript parse
#    errors, missing resource paths and malformed .tscn files.
# 2. Runs the unit tests in tests/unit/.
#
# Exits non-zero if either step fails, so CI can gate on it.

set -uo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: '$GODOT' not found. Set GODOT=/path/to/godot" >&2
  exit 127
fi

echo "== Importing project =="
import_log=$("$GODOT" --headless --import --quit 2>&1)
import_status=$?
echo "$import_log"

# --import exits 0 even when it logged script errors, so scan the output too.
if [ $import_status -ne 0 ] || echo "$import_log" | grep -qE "SCRIPT ERROR|Parse Error|Failed to load|error calling"; then
  echo ""
  echo "FAILED: project did not import cleanly"
  exit 1
fi

echo ""
echo "== Running tests =="
test_log=$("$GODOT" --headless --script res://tools/run_tests.gd 2>&1)
test_status=$?
echo "$test_log"

if [ $test_status -ne 0 ]; then
  echo ""
  echo "FAILED: unit tests"
  exit 1
fi

echo ""
echo "OK"
