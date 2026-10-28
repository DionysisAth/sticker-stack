# Status against the game plan

What is built in this repo, what was changed from the plan and why, and what
still needs a person, an account or a real phone.

## Milestones

| Week | Milestone | State |
| --- | --- | --- |
| 1 | Foundation: project, CI (tests, debug APK, emulator startup test, public APK link), save, audio, haptics, analytics, navigation, board model, tray, free/covered, triples, unit tests | **Built.** CI runs on every push. |
| 2 | Playable loop: tap, fly to tray, clear, win and fail cards, retry. Backwards generator and the 500-run bot. 10 levels | **Built** (50 levels). **Your gate:** the fun test with 5 people. |
| 3–4 | Mechanics 2–6 (rolls, mystery, glued pairs, padlock, ice) and a level editor | **Built.** Each has an intro level with a tutorial card. |
| 5 | Mechanics 7–10 (bubble wrap, dispensers, rainbow, fuse) and boosters (Undo, Return 3, Shuffle). Ad and billing plugin spike | Mechanics and boosters **built**. **Your gate:** the plugin spike on real phones. |
| 6 | Progression: Play · Level N home, "new trick in N levels" bar, tutorial 1–3, save, settings, analytics events | **Built.** |
| 7 | Look and feel: sticker art, peel and pop, sounds, haptics, confetti; tune all 50 levels with the bot | **Built** (art and sounds are generated in code, see below). Tuning by hand still to do. |
| 8 | MVP test on Google Play closed testing and TestFlight | **Needs you:** accounts, testers, uploads. |
| 9–12 | v1.0: economy, ads, purchases, consent, mechanics 11–16, levels 51–100, album, store launch | Not started (after the MVP test, as planned). Endless generated levels after 50 already work. |

## What's in the game

- **Rules:** pile on a 12 × 14 half-step grid with layers; a sticker is free when
  nothing on a higher layer overlaps it; covered stickers are dimmed but
  visible; 7-slot tray grouped by type; three alike clear; level cleared when
  board and tray are empty; full tray fails; tapping a covered sticker shakes.
- **Mechanics (levels 6–46):** sticker rolls, mystery stickers, glued pairs,
  padlocks, ice, bubble wrap, side dispensers, rainbow sticker, fuse. Each is
  one rule script in `game/rules/` and plain data in the level file.
- **Boosters:** Undo, Return 3, Shuffle. Free starting stock (3/2/2) and +1
  every 5 clears, taking turns. Shuffle only keeps a mix the bot can still
  win.
- **Progression:** home has one Play · Level N button, the booster stock and
  settings. Clear card with Next and the "new sticker trick in N levels" bar;
  fail card with Try again (same pile) and the boosters that help; Hard card
  before every 10th level; tutorial card at each mechanic's intro; pointing
  hand for the first taps of levels 1–3, which can't be failed (3 types).
- **Look and feel:** die-cut stickers with white border, shadow and gloss in
  12 shapes and 10 colours (every type differs in both), Fredoka font, chunky
  raised buttons, gradient backdrops. Peel curl, arc into the tray and squash;
  pop with confetti in the sticker's colour; combo chime that rises in pitch;
  red pulsing tray edge with a heartbeat haptic at 5 and 6 of 7; confetti and
  bouncing Next button on clear.
- **After the plan:** three additions to make clearing more satisfying.
  - *Auto-finish:* once no choice is left (everything uncovered, no locks,
    ice, wrap, fuses or rainbows, and no order could fill the tray) and at
    most 40% of the pile is left, the game peels the rest in a fast chain
    with rising pitch. Not on levels 1-3. It starts on 45 of the 50 levels,
    with 2-9 stickers left.
  - *Booster jar:* each clear adds a segment; the fifth pops the lid and gives
    a booster (this replaces the silent +1 every 5 clears).
  - *Win streak:* clearing on the first try (boosters allowed) grows a flame
    shown in the top bar, on the clear card and on home. Retrying, or leaving
    and coming back, ends it. Streaks of 3, 5 and 10, then every 5 more, give
    a booster. The fail card warns before a retry ends a streak of 2 or more.
- **Inside the level:** four additions so clearing feels like progress.
  - *Hidden picture:* the sheet under the pile hides an illustration (eight
    scenes drawn in code, one per level in turn). Each spot fades open once
    no sticker covers it; on clear the rest of the paper fades, a shine
    sweeps across and "Picture complete!" shows, and the clear card names it.
  - *Pile meter* in the top bar fills as stickers are cleared.
  - *Juicier triples:* the three stickers jump together and burst with
    confetti and a shockwave ring, the pile hops, and back-to-back triples
    show a bigger "Combo" and shake the screen a little (off with reduce
    motion).
  - *Magnet:* chaining 3 triples (each within 2 picks of the last) earns a
    Magnet for this level; the ring around its button shows the chain. Tap
    it, then any sticker, even a covered one, to pull and clear its whole
    triple (stickers held by locks, ice, glue or rolls can't be pulled). It
    counts as one pick. The bot doesn't use it, so it's a reward for skill.
- **Accessibility:** colour-blind labels, reduce-motion setting, touch targets
  over 48 dp, tray and boosters in the bottom third.
- **Analytics:** `level_start`, `level_clear`, `level_fail`, `booster_used`,
  `tutorial_seen`, `session_end`, written to a local log file as planned until
  the plugin is chosen.

## Changes from the plan

- **Rainbow sticker rule.** As first written, spending the rainbow on the
  "wrong" pair left unmatched stickers at the end, so rainbow levels were close
  to unwinnable (the bot won 0–3%). Now, when a rainbow completes a pair, the
  one sticker of that type left over turns into a rainbow. The pile can
  always still be cleared, and when to spend it is still the decision.
- **Fuse** means the sticker must be *peeled* within N picks (the number on it
  counts down with each pick).
- **Bubble wrap:** popping the wrap is not a pick, so it doesn't count down ice
  or fuses.
- **Generator and bot live in `game/`, not `tools/`**, because the game uses
  them at runtime (endless levels and the Shuffle check). `tools/` holds the
  command-line scripts and the editor.
- **"Designer plays the top 3":** `tools/build_levels.gd` keeps the candidate
  closest to the target automatically. Replace any level by hand in the
  editor.
- **Art and sound are generated in code** (vector drawing and synthesized
  sounds), so there are no art or audio files to manage yet. A real art and
  sound pass can replace them later.
- **Save** also keeps attempts at the current level (for analytics and the
  streak), total clears (for the booster jar), the current and best streak,
  and which tutorial cards were shown. `level_clear` also reports
  `auto_taps`, `streak` and `magnets_earned`; using a Magnet is a
  `booster_used` event with `booster: "magnet"`.
- **Package id:** `com.dionysisath.stickerstack` (change it in
  `export_presets.cfg` before the first store upload if you want another).

## What needs you

1. **Fun test (week-2 gate).** Five people, the test APK, and watch whether
   they ask for "one more".
2. **Real phones.** Touch feel, haptics and speed on one Android phone and one
   iPhone. Haptics only work on a phone.
3. **Plugin spike (week-5 gate).** AdMob, Play Billing and StoreKit plugins on
   Godot 4.7, on real phones. If they don't work, the plan says switch to
   Flutter.
4. **Analytics backend.** Pick Firebase or GameAnalytics and a Godot 4.7
   plugin, then set `Analytics.sink` in `core/analytics.gd`.
5. **Accounts and signing** (launch checklist): Google Play and Apple
   developer accounts; name and trademark check; an upload keystore backed
   up in two places and added as the secrets `ANDROID_KEYSTORE_BASE64`,
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`; Play App Signing; iOS
   certificates and `IOS_TEAM_ID`; a Mac for the Xcode build and upload.
6. **Testers.** Recruit by week 6; start the Play closed test (12 testers,
   14 days) on day one of week 8.
7. **Hand tuning.** Play the 50 levels; replace any that feel off in the
   level editor. `levels/README.md` shows the bot score for each. Most are
   within a few points of their target; the furthest off are level 38
   (bot 54%, target 72%), level 30 (Hard, 46% vs 35%), level 43 (61% vs 72%)
   and level 17 (83% vs 75%).
8. **Store listing.** `tools/screenshots.gd` captures the real screens as a
   starting point; icons are in `assets/` (512 px and 1024 px included).
   Still needed: feature graphic, preview video, descriptions, privacy policy.
