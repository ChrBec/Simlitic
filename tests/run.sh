#!/usr/bin/env bash
# Runs the headless test suite. Fails on any test failure or script error.
# Usage: GODOT=/path/to/godot tests/run.sh
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --import --path . >/dev/null 2>&1
out=$("$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1)
code=$?
echo "$out" | grep -v '^$'
if echo "$out" | grep -q "SCRIPT ERROR"; then echo "script errors detected"; exit 1; fi
exit $code
