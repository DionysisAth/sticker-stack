extends TestCase
## Board model: free/covered, triples, win and fail.


func _pile() -> BoardState:
	# Two layers: three stickers on top, six underneath.
	return BoardState.from_level(level(3, [
		s(0, 0, 0), s(1, 2, 0), s(2, 4, 0), s(0, 0, 2), s(1, 2, 2), s(2, 4, 2),
		s(0, 1, 1, 1), s(1, 3, 1, 1), s(2, 5, 3, 1),
	]))


func test_free_and_covered() -> void:
	var st := _pile()
	check(st.is_free(st.stickers[6]), "top sticker is free")
	check(not st.is_free(st.stickers[0]), "sticker under the top layer is covered")
	check(st.is_free(st.stickers[2]) == false, "covered by (3,1)")
	st.tap(6)
	check(st.is_free(st.stickers[0]), "uncovered once the top one is gone")


func test_tap_covered_does_nothing() -> void:
	var st := _pile()
	check(not st.tap(0))
	eq(st.tray.size(), 0)
	var ev := st.drain_events()
	eq(ev[0].e, "blocked")
	eq(ev[0].reason, "covered")


func test_pile_can_be_cleared() -> void:
	var st := _pile()
	var guard := 0
	while st.status == BoardState.Status.PLAYING and guard < 50:
		guard += 1
		var free := st.tappable()
		# Prefer a sticker that matches the tray.
		var pick: int = free[0]
		for id in free:
			if st.tray.count_of(st.stickers[id].type) > 0:
				pick = id
				break
		st.tap(pick)
	eq(st.status, BoardState.Status.WON)
	eq(st.tray.size(), 0)


func test_triple_clears() -> void:
	var st := BoardState.from_level(level(1, [s(0, 0, 0), s(0, 2, 0), s(0, 4, 0)]))
	st.tap(0)
	st.tap(1)
	eq(st.tray.size(), 2)
	st.tap(2)
	eq(st.tray.size(), 0)
	eq(st.status, BoardState.Status.WON)


func test_full_tray_fails() -> void:
	var stickers := []
	for i in 7:
		for k in 3:
			stickers.append(s(i, i * 2 % 12, k * 2 + (i / 6) * 6))
	var st := BoardState.from_level(level(7, stickers))
	for i in 7:
		st.tap(i * 3)
	eq(st.status, BoardState.Status.FAILED)
	eq(st.fail_reason, "tray_full")


func test_stuck_with_leftovers_fails() -> void:
	var st := BoardState.from_level(level(1, [s(0, 0, 0), s(0, 2, 0)]))
	st.tap(0)
	st.tap(1)
	eq(st.status, BoardState.Status.FAILED)
	eq(st.fail_reason, "no_moves")


func test_clone_is_independent() -> void:
	var st := _pile()
	var c := st.clone()
	c.tap(6)
	check(st.stickers[6].alive, "original untouched")
	eq(st.tray.size(), 0)
	eq(c.tray.size(), 1)


func test_retry_rebuilds_same_pile() -> void:
	var data := LevelData.load_level(7)
	var a := BoardState.from_level(data)
	var b := BoardState.from_level(data)
	eq(a.stickers.size(), b.stickers.size())
	for i in a.stickers.size():
		eq(a.stickers[i].to_dict(), b.stickers[i].to_dict())
