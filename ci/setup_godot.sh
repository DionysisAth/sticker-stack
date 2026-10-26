#!/usr/bin/env bash
# Downloads Godot (and optionally its export templates) into $GODOT_HOME and
# puts a `godot` command on PATH. Used by every CI job.
#   ci/setup_godot.sh            # editor binary only
#   ci/setup_godot.sh templates  # plus export templates
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
GODOT_HOME="${GODOT_HOME:-$HOME/godot}"
TAG="${GODOT_VERSION}-stable"
BASE="https://github.com/godotengine/godot/releases/download/${TAG}"
mkdir -p "$GODOT_HOME" "$GODOT_HOME/bin"

case "$(uname -s)" in
  Darwin)
    if [ ! -d "$GODOT_HOME/Godot.app" ]; then
      curl -fsSL -o "$GODOT_HOME/godot.zip" "$BASE/Godot_v${TAG}_macos.universal.zip"
      unzip -q -o "$GODOT_HOME/godot.zip" -d "$GODOT_HOME" && rm "$GODOT_HOME/godot.zip"
    fi
    ln -sf "$GODOT_HOME/Godot.app/Contents/MacOS/Godot" "$GODOT_HOME/bin/godot"
    TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
    ;;
  *)
    BIN="Godot_v${TAG}_linux.x86_64"
    if [ ! -f "$GODOT_HOME/$BIN" ]; then
      curl -fsSL -o "$GODOT_HOME/godot.zip" "$BASE/${BIN}.zip"
      unzip -q -o "$GODOT_HOME/godot.zip" -d "$GODOT_HOME" && rm "$GODOT_HOME/godot.zip"
    fi
    ln -sf "$GODOT_HOME/$BIN" "$GODOT_HOME/bin/godot"
    TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
    ;;
esac

if [ "${1:-}" = "templates" ] && [ ! -f "$TEMPLATE_DIR/version.txt" ]; then
  mkdir -p "$TEMPLATE_DIR"
  if [ ! -f "$GODOT_HOME/templates/version.txt" ]; then
    curl -fsSL -o "$GODOT_HOME/templates.tpz" "$BASE/Godot_v${TAG}_export_templates.tpz"
    unzip -q -o "$GODOT_HOME/templates.tpz" -d "$GODOT_HOME" && rm "$GODOT_HOME/templates.tpz"
  fi
  cp -R "$GODOT_HOME/templates/." "$TEMPLATE_DIR/"
fi

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$GODOT_HOME/bin" >> "$GITHUB_PATH"
fi
"$GODOT_HOME/bin/godot" --version
