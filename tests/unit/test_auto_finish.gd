extends TestCase


func _endgame(types: int, extra := []) -> BoardState:
	var stickers := []
	for t in types:
		for k in 3:
			stickers.append(s(t, t * 2 % 12, k * 2 + (t / 6) * 6))
	stickers.append_array(extra)
	var data := level(types, stickers)
	data.level = 10
	return BoardState.from_level(data)


func test_finishes_a_safe_endgame() -> void:
	var st := _endgame(3)
	var taps := AutoFinish.plan(st, 30)
	eq(taps.size(), 9)
	check(st.stickers[0].alive, "planning doesn't change the board")
	eq(st.play(taps), BoardState.Status.WON)


func test_not_when_a_sticker_is_covered() -> void:
	var st := _endgame(3, [s(0, 1, 1, 1), s(0, 9, 9, 0), s(0, 11, 11, 0)])
	check(AutoFinish.plan(st, 40).is_empty())


func test_not_when_the_order_could_fill_the_tray() -> void:
	# Four types: 2 of each could sit in the tray at once (8 > 7).
	check(AutoFinish.plan(_endgame(4), 40).is_empty())


func test_not_while_most_of_the_pile_is_left() -> void:
	check(AutoFinish.plan(_endgame(3), 12).is_empty())


func test_not_on_tutorial_levels() -> void:
	var st := _endgame(3)
	st.level = 2
	check(AutoFinish.plan(st, 30).is_empty())


func test_not_with_a_fuse() -> void:
	var data := level(3, [s(0, 0, 0, 0, {"kind": "fuse", "fuse": 9}), s(0, 2, 0), s(0, 4, 0), s(1, 6, 0), s(1, 8, 0), s(1, 10, 0)])
	data.level = 10
	check(AutoFinish.plan(BoardState.from_level(data), 30).is_empty())
