# Sticker Stack

A tile-match puzzle for Android and iOS. Peel uncovered stickers off a layered
pile into a 7-slot tray; three alike clear; a full tray ends the attempt.
Levels run as one endless line, and a new mechanic arrives every 5 levels.

Built with **Godot 4.7** (GDScript, Compatibility renderer, portrait).

**Test APK (Android):** [latest build of `main`](https://github.com/DionysisAth/sticker-stack/releases/download/test-build/sticker-stack-debug.apk)
(published by CI after the tests and the emulator check pass).

## Run it

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` and press **F5**. The window is a phone-shaped 405×720;
   click to tap.

The level editor is in **Settings → Level editor** (debug builds only).

## Tests

```sh
godot --headless --path . --import
godot --headless --path . res://tests/run_tests.tscn                  # all tests
godot --headless --path . res://tests/run_tests.tscn -- --filter=rules  # one file
```

The tests cover the tray, the board (free/covered, triples, win, fail), every
mechanic, the boosters, the generator, the save file, a play-through of all 50
levels with the real rules, and a smoke test that clears level 1 in the real
game screen.

## Levels

Levels 1–50 are files in `levels/` (one JSON file per level). Each stores the
pile, its types, a winning tap order (`solution`) and the bot's measured win
rate. `levels/README.md` lists every level with its target and bot score.

Rebuild them after changing the generator or the difficulty curve:

```sh
# Check the curve first (8 candidates per level, quick):
godot --headless --path . --script res://tools/difficulty_sweep.gd -- --levels=8,9,10
# Rebuild (30 candidates per level, 500 bot games for the finalists):
godot --headless --path . --script res://tools/build_levels.gd -- --from=1 --to=50
```

Ranges can run in parallel (`--from=1 --to=24` and `--from=25 --to=50` in two
terminals), then `-- --report` rewrites `levels/README.md`.

After level 50 the generator makes levels from the level number as the seed,
keeping the candidate closest to the target win rate, so players never run out
and a retry always gets the same pile.

## Project layout

```
core/      save, audio (synthesized sounds), haptics, analytics, navigation, theme
game/      board_state.gd, tray.gd, sticker.gd, rules/ (one script per mechanic),
           generator.gd, solver_bot.gd, difficulty.gd, mechanics.gd, level.gd
ui/        home, game screen, board and tray views, cards, sticker drawing, settings
levels/    level_001.json ... level_050.json
tools/     build_levels, difficulty_sweep, level_editor, screenshots, make_icons
tests/     test runner and unit tests
ci/        build, test and emulator scripts used by GitHub Actions
```

The game state (`game/`) is pure logic with no scene nodes; the generator, the
bot, the tests and the game screen all use the same rules. Each mechanic is a
small rule script that hooks into "is free", "can pick", "on tap", "on pick",
"after pick" and "after clear", and is plain data in the level file.

## Where things are saved

- `user://save.json`: current level, booster stock, settings (plus attempts at
  the current level, total clears and which tutorial cards were shown).
- `user://analytics.log`: analytics events, one JSON object per line. On
  Android, `user://` is the app's private data folder
  (`adb shell run-as com.dionysisath.stickerstack cat files/analytics.log`).
  Set `Analytics.sink` to forward events to Firebase or GameAnalytics once a
  plugin is chosen.

## CI

`.github/workflows/ci.yml` runs on every push:

1. **Unit tests** (headless Godot).
2. **Debug APK** export, with the version code set from the run number.
3. **Emulator startup test**: installs the APK on an Android 11 emulator,
   opens it, waits 30 s and checks the app is still running with no crash
   in logcat. A screenshot and the logcat are kept as artifacts.
4. On `main`: uploads the APK to the `test-build` release (the link above).

`.github/workflows/release.yml` (run by hand) builds a signed AAB for Google
Play and the iOS Xcode project. It needs these repository secrets:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
and `IOS_TEAM_ID`. Each job skips itself when its secrets are missing.

## Status against the plan

See [`docs/STATUS.md`](docs/STATUS.md).
