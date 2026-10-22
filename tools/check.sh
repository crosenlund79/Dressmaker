#!/usr/bin/env bash
# Refreshes Godot's import/class cache, then loads every script and scene.
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . tools/validate_scripts.tscn 2>&1 | grep -E "SCRIPT ERROR|Parse Error|FAILED|ERROR|failures" || true
