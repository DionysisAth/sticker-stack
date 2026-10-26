#!/usr/bin/env bash
# Exports the Xcode project for iOS (macOS only). Building, signing and the
# TestFlight upload happen in Xcode (or xcodebuild) with your Apple account.
# Needs IOS_TEAM_ID (your Apple Developer team id).
set -euo pipefail
GODOT="${GODOT:-godot}"
: "${IOS_TEAM_ID:?set IOS_TEAM_ID (Apple Developer team id)}"
VERSION_CODE="${VERSION_CODE:-1}"
sed -i '' "s/^application\/app_store_team_id=.*/application\/app_store_team_id=\"${IOS_TEAM_ID}\"/" export_presets.cfg
sed -i '' "s/^application\/version=.*/application\/version=\"${VERSION_CODE}\"/" export_presets.cfg
mkdir -p build/ios
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "iOS" build/ios/StickerStack.ipa
ls -la build/ios
