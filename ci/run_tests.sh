#!/usr/bin/env bash
# Imports the project and runs all unit tests headless. Exit code 0 = green.
set -euo pipefail
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . res://tests/run_tests.tscn 2>&1 | tee test-output.txt
# Godot can exit 0 after a script error; treat those as failures too.
if grep -qE "SCRIPT ERROR|Parse Error" test-output.txt; then
  echo "Script errors found"
  exit 1
fi
grep -qE "^[0-9]+ tests, 0 failed" test-output.txt
