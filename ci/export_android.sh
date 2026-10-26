#!/usr/bin/env bash
# Exports the Android build.
#   ci/export_android.sh debug    -> build/android/sticker-stack-debug.apk
#   ci/export_android.sh release  -> build/android/sticker-stack.aab (signed)
# Needs: export templates (ci/setup_godot.sh templates), ANDROID_HOME, Java 17.
# Release also needs ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD and
# ANDROID_KEY_ALIAS. The version code is VERSION_CODE (CI run number).
set -euo pipefail
MODE="${1:-debug}"
GODOT="${GODOT:-godot}"
VERSION_CODE="${VERSION_CODE:-1}"
GODOT_MINOR="$("$GODOT" --version | cut -d. -f1-2)"
mkdir -p build/android

# Editor settings: where the Android SDK and Java live.
CONFIG_DIR="$HOME/.config/godot"
mkdir -p "$CONFIG_DIR"
JAVA_DIR="${JAVA_HOME:-/usr/lib/jvm/default-java}"
SDK_DIR="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
for f in "editor_settings-4.tres" "editor_settings-${GODOT_MINOR}.tres"; do
  cat > "$CONFIG_DIR/$f" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$SDK_DIR"
export/android/java_sdk_path = "$JAVA_DIR"
SETTINGS
done

# Version code from the CI run number.
sed -i.bak "s/^version\/code=.*/version\/code=${VERSION_CODE}/" export_presets.cfg && rm -f export_presets.cfg.bak

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

if [ "$MODE" = "debug" ]; then
  KEYSTORE="$PWD/build/debug.keystore"
  if [ ! -f "$KEYSTORE" ]; then
    keytool -genkeypair -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey \
      -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
      -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
  fi
  export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KEYSTORE"
  export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
  export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
  "$GODOT" --headless --path . --export-debug "Android" build/android/sticker-stack-debug.apk
  ls -la build/android/sticker-stack-debug.apk
else
  : "${ANDROID_KEYSTORE_BASE64:?missing secret ANDROID_KEYSTORE_BASE64}"
  : "${ANDROID_KEYSTORE_PASSWORD:?missing secret ANDROID_KEYSTORE_PASSWORD}"
  : "${ANDROID_KEY_ALIAS:?missing secret ANDROID_KEY_ALIAS}"
  KEYSTORE="$PWD/build/upload.keystore"
  echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$KEYSTORE"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ANDROID_KEY_ALIAS"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$ANDROID_KEYSTORE_PASSWORD"
  "$GODOT" --headless --path . --install-android-build-template
  "$GODOT" --headless --path . --export-release "Android Release" build/android/sticker-stack.aab
  rm -f "$KEYSTORE"
  ls -la build/android/sticker-stack.aab
fi
