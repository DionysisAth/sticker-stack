extends TestCase


func _two_layer() -> BoardState:
	return BoardState.from_level(level(3, [
		s(0, 0, 0), s(1, 2, 0), s(2, 4, 0),
		s(0, 0, 2), s(1, 2, 2), s(2, 4, 2),
		s(0, 0, 4), s(1, 2, 4), s(2, 4, 4),
	]))


func test_undo_puts_sticker_back() -> void:
	var st := _two_layer()
	st.tap(0)
	check(not st.stickers[0].alive)
	check(st.undo())
	check(st.stickers[0].alive, "back on the board")
	eq(st.tray.size(), 0)
	check(not st.can_undo(), "nothing more to undo")


func test_no_undo_past_a_triple() -> void:
	var st := _two_layer()
	st.tap(0)
	st.tap(3)
	st.tap(6)
	eq(st.tray.size(), 0)
	check(not st.can_undo())


func test_undo_after_full_tray() -> void:
	var stickers := []
	for i in 7:
		for k in 3:
			stickers.append(s(i, (i % 6) * 2, k * 2 + (i / 6) * 6))
	var st := BoardState.from_level(level(7, stickers))
	for i in 7:
		st.tap(i * 3)
	eq(st.status, BoardState.Status.FAILED)
	check(st.undo())
	eq(st.status, BoardState.Status.PLAYING)
	eq(st.tray.size(), 6)


func test_return_three() -> void:
	var st := _two_layer()
	st.tap(0)
	st.tap(1)
	st.tap(2)
	eq(st.tray.size(), 3)
	check(st.return_three())
	eq(st.tray.size(), 0)
	var returned := 0
	for x in st.stickers:
		if x.returned:
			returned += 1
			check(st.is_free(x), "returned stickers are on top")
	eq(returned, 3)
	# And the level can still be won.
	check(SolverBot.can_win(st, 20), "still winnable")


func test_shuffle_keeps_types() -> void:
	var data := LevelData.load_level(12)
	var st := BoardState.from_level(data)
	var before := _type_counts(st)
	check(st.shuffle(), "found a winnable mix")
	eq(_type_counts(st), before)
	check(SolverBot.can_win(st, 30), "still winnable after shuffle")


func _type_counts(st: BoardState) -> Dictionary:
	var counts := {}
	for x in st.stickers:
		if not x.alive:
			continue
		for t in [x.type] + Array(x.roll):
			counts[t] = counts.get(t, 0) + 1
	return counts
