#!/usr/bin/env bash
# Startup test on an Android emulator: install the debug APK, open the app,
# wait, and check it is still running and didn't crash.
set -euo pipefail
APK="${1:-build/android/sticker-stack-debug.apk}"
PKG="com.dionysisath.stickerstack"
mkdir -p build/emulator

adb wait-for-device
adb install -r "$APK"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 30
adb exec-out screencap -p > build/emulator/screen.png || true
adb logcat -d > build/emulator/logcat.txt || true

PID="$(adb shell pidof "$PKG" | tr -d '\r' || true)"
if [ -z "$PID" ]; then
  echo "The app is not running 30 seconds after launch."
  tail -n 200 build/emulator/logcat.txt
  exit 1
fi
if grep -E "FATAL EXCEPTION|Fatal signal|SIGSEGV|SCRIPT ERROR" build/emulator/logcat.txt; then
  echo "Crash or script error in logcat."
  exit 1
fi
echo "App is running (pid $PID) and logcat shows no crash."
