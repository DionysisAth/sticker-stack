extends TestCase
## One test (or more) per mechanic.


func test_roll_peels_one_at_a_time() -> void:
	var st := BoardState.from_level(level(3, [
		s(0, 0, 0, 1, {"kind": "roll", "roll": [1, 2]}),
		s(0, 1, 1, 0), s(0, 4, 0), s(1, 6, 0), s(1, 8, 0), s(2, 10, 0), s(2, 4, 4),
	]))
	eq(st.stickers[0].count(), 3)
	st.tap(0)
	check(st.stickers[0].alive, "roll stays while not empty")
	eq(st.stickers[0].type, 1, "next sticker shows")
	check(not st.is_free(st.stickers[1]), "still covers what's under it")
	st.tap(0)
	st.tap(0)
	check(not st.stickers[0].alive)
	check(st.is_free(st.stickers[1]))
	eq(st.tray.types, [0, 1, 2] as Array[int])


func test_mystery_turns_over_when_uncovered() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0, 1), s(1, 1, 1, 0, {"kind": "mystery"}), s(1, 4, 0, 0, {"kind": "mystery"}),
	]))
	check(st.stickers[1].hidden, "covered mystery is face down")
	check(not st.stickers[2].hidden, "a free mystery sticker shows at once")
	st.tap(0)
	check(not st.stickers[1].hidden, "turned over once uncovered")


func test_glued_pair_comes_off_together() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0, 0, {"kind": "glue", "pair": 1}), s(1, 2, 0, 0, {"kind": "glue", "pair": 0}),
		s(0, 6, 0), s(0, 8, 0), s(1, 6, 4), s(1, 8, 4),
	]))
	st.tap(0)
	check(not st.stickers[0].alive and not st.stickers[1].alive, "both peeled")
	eq(st.tray.size(), 2)
	eq(st.picks, 1, "counts as one pick")


func test_glued_pair_needs_both_free() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0, 0, {"kind": "glue", "pair": 1}), s(1, 2, 0, 0, {"kind": "glue", "pair": 0}),
		s(1, 3, 1, 1),
	]))
	check(not st.tap(0))
	eq(st.drain_events()[0].reason, "glued")


func test_padlock_opens_on_key_triple() -> void:
	var st := BoardState.from_level(level(2, [
		s(1, 0, 0, 0, {"kind": "padlock", "key": 0}),
		s(0, 2, 0), s(0, 4, 0), s(0, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	check(not st.tap(0), "locked")
	eq(st.drain_events()[0].reason, "locked")
	st.tap(1)
	st.tap(2)
	check(st.stickers[0].key >= 0, "still locked with a pair")
	st.tap(3)
	eq(st.stickers[0].key, -1, "opened by the key triple")
	check(st.tap(0))


func test_ice_thaws_after_n_picks() -> void:
	var st := BoardState.from_level(level(2, [
		s(1, 0, 0, 0, {"kind": "ice", "ice": 2}),
		s(0, 2, 0), s(0, 4, 0), s(0, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	check(not st.tap(0))
	st.tap(1)
	eq(st.stickers[0].ice, 1)
	st.tap(2)
	eq(st.stickers[0].ice, 0)
	check(st.tap(0), "thawed")


func test_bubble_wrap_needs_two_taps() -> void:
	var st := BoardState.from_level(level(1, [
		s(0, 0, 0, 0, {"kind": "wrap"}), s(0, 2, 0), s(0, 4, 0),
	]))
	check(st.tap(0), "first tap pops the wrap")
	check(st.stickers[0].alive)
	eq(st.tray.size(), 0)
	eq(st.picks, 0, "popping is not a pick")
	st.tap(0)
	check(not st.stickers[0].alive)


func test_dispenser_front_only() -> void:
	var st := BoardState.from_level(level(2, [
		{"type": 0, "kind": "dispenser", "queue": 0, "order": 0},
		{"type": 1, "kind": "dispenser", "queue": 0, "order": 1},
		{"type": 1, "kind": "dispenser", "queue": 1, "order": 0},
		s(0, 0, 0), s(0, 2, 0), s(1, 4, 0),
	]))
	check(st.is_free(st.stickers[0]))
	check(not st.is_free(st.stickers[1]), "behind the front")
	check(st.is_free(st.stickers[2]), "front of the other queue")
	st.tap(0)
	check(st.is_free(st.stickers[1]), "next one moves up")


func test_rainbow_matches_any_pair() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0), s(0, 2, 0), s(0, 4, 0, 0, {"kind": "rainbow"}),
	]))
	eq(st.stickers[2].type, Sticker.RAINBOW)
	st.tap(0)
	st.tap(1)
	st.tap(2)
	eq(st.status, BoardState.Status.WON)


func test_rainbow_spent_elsewhere_leaves_a_rainbow() -> void:
	# Type 0 is one short (the rainbow stands in for it). Spending the rainbow
	# on type 1 turns the leftover type-1 sticker into a rainbow.
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0), s(0, 2, 0), s(1, 4, 0), s(1, 6, 0), s(1, 8, 0),
		s(0, 10, 0, 0, {"kind": "rainbow"}),
	]))
	st.tap(2)
	st.tap(3)
	st.tap(5)
	eq(st.tray.size(), 0, "rainbow cleared the type-1 pair")
	eq(st.stickers[4].type, Sticker.RAINBOW, "the odd one out turned rainbow")
	st.tap(0)
	st.tap(1)
	st.tap(4)
	eq(st.status, BoardState.Status.WON)


func test_fuse_burns_out() -> void:
	var st := BoardState.from_level(level(2, [
		s(1, 0, 0, 0, {"kind": "fuse", "fuse": 2}),
		s(0, 2, 0), s(0, 4, 0), s(0, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	st.tap(1)
	eq(st.stickers[0].fuse, 1)
	st.tap(2)
	eq(st.status, BoardState.Status.FAILED)
	eq(st.fail_reason, "fuse")


func test_fuse_in_time() -> void:
	var st := BoardState.from_level(level(2, [
		s(1, 0, 0, 0, {"kind": "fuse", "fuse": 2}),
		s(0, 2, 0), s(0, 4, 0), s(0, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	st.tap(1)
	st.tap(0)
	eq(st.status, BoardState.Status.PLAYING)
	st.tap(2)
	st.tap(3)
	st.tap(4)
	st.tap(5)
	eq(st.status, BoardState.Status.WON)


func test_level_file_round_trip() -> void:
	var st := BoardState.from_level(LevelData.load_level(37))
	for x in st.stickers:
		var back := Sticker.from_dict(x.to_dict(), x.id)
		eq(back.to_dict(), x.to_dict())


func test_magnet_pulls_a_covered_triple() -> void:
	var st := BoardState.from_level(level(2, [
		s(1, 0, 0, 1), s(0, 1, 1, 0), s(0, 6, 0), s(0, 8, 4), s(1, 10, 0), s(1, 4, 8),
	]))
	check(not st.is_free(st.stickers[1]), "the tapped sticker is covered")
	check(st.magnet(1))
	for id in [1, 2, 3]:
		check(not st.stickers[id].alive, "sticker %d pulled" % id)
	eq(st.tray.size(), 0, "cleared at once")
	eq(st.picks, 1)


func test_magnet_uses_what_the_tray_holds() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0), s(0, 2, 0), s(0, 4, 0), s(1, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	st.tap(0)
	st.tap(3)
	check(st.magnet(1))
	check(not st.stickers[1].alive and not st.stickers[2].alive, "the tapped one plus one more")
	eq(st.tray.types, [1] as Array[int], "the type-0 sticker in the tray cleared with them")


func test_magnet_cannot_pull_held_stickers() -> void:
	var st := BoardState.from_level(level(2, [
		s(0, 0, 0), s(0, 2, 0, 0, {"kind": "ice", "ice": 3}), s(0, 4, 0, 0, {"kind": "padlock", "key": 1}),
		s(1, 6, 0), s(1, 8, 0), s(1, 10, 0),
	]))
	check(st.magnet_group(0).is_empty(), "the other two are frozen and locked")
	check(not st.magnet(0))
