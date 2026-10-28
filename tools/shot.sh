#!/usr/bin/env bash
# Renders a screenshot of the running game (needs xvfb-run). Usage:
#   GODOT=/path/to/godot tools/shot.sh out.png [--new-game|--demo] [--panel=population|valleys|trade|building]
set -e
OUT=$(realpath -m "$1"); shift
cd "$(dirname "$0")/.."
timeout 60 xvfb-run -a -s "-screen 0 1600x900x24" "${GODOT:-godot}" --path . --rendering-driver opengl3 \
  --resolution 1600x900 -- "$@" --shot="$OUT" 2>&1 | grep -E "SCRIPT ERROR|^\s+at: .*res://" || true
