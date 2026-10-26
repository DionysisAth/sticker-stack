extends TestCase
## Play-through check of all hand-tuned levels: each file loads, its
## winning order wins with the real rules, and it fits the plan.


func test_all_levels_play_through() -> void:
	for n in range(1, Difficulty.HAND_TUNED + 1):
		var path := LevelData.path_for(n)
		check(FileAccess.file_exists(path), "%s exists" % path)
		var level := LevelData.parse(FileAccess.get_file_as_string(path))
		check(not level.is_empty(), "level %d parses" % n)
		if level.is_empty():
			continue
		eq(int(level.level), n)
		var st := BoardState.from_level(level)
		eq(st.play(level.solution), BoardState.Status.WON, "level %d winning order" % n)
		eq(bool(level.hard), n % 10 == 0, "level %d Hard flag" % n)
		check(level.has("bot_win_rate"), "level %d has a bot score" % n)


func test_mechanic_intros() -> void:
	for m in Mechanics.LIST:
		var level := LevelData.load_level(m.level)
		eq(level.tutorial, m.id, "level %d shows the %s card" % [m.level, m.id])
		var kinds := {}
		for d in level.stickers:
			kinds[d.get("kind", "")] = true
		check(kinds.has(m.id) or (m.id == "rainbow" and _has_rainbow(level)), "level %d uses %s" % [m.level, m.id])


func test_tutorial_levels_cannot_fail() -> void:
	for n in [1, 2, 3]:
		var level := LevelData.load_level(n)
		check(level.types.size() <= 3, "level %d: 3 types can't fill 7 slots" % n)
		eq(SolverBot.win_rate(BoardState.from_level(level), 50, 3), 1.0, "level %d" % n)


func test_endless_levels_generate() -> void:
	var level := LevelData.generate_endless(51, 2, 10)
	check(not level.is_empty(), "level 51 generates")
	eq(BoardState.from_level(level).play(level.solution), BoardState.Status.WON)


func _has_rainbow(level: Dictionary) -> bool:
	for d in level.stickers:
		if int(d.type) == Sticker.RAINBOW:
			return true
	return false
