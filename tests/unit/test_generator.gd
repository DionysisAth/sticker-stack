extends TestCase


func test_every_generated_level_has_a_winning_order() -> void:
	for lv in [1, 2, 4, 7, 12, 17, 22, 27, 32, 37, 42, 47, 50, 63, 88]:
		var p := Difficulty.params(lv)
		var level := {}
		for c in 30:
			level = LevelGenerator.generate(p, lv * 1000 + c)
			if not level.is_empty():
				break
		check(not level.is_empty(), "level %d generates" % lv)
		if level.is_empty():
			continue
		var st := BoardState.from_level(level)
		eq(st.play(level.solution), BoardState.Status.WON, "level %d solution" % lv)
		eq(_count(level), int(p.count), "level %d sticker count" % lv)


func test_same_seed_same_level() -> void:
	var p := Difficulty.params(23)
	var a := LevelGenerator.generate(p, 4242)
	var b := LevelGenerator.generate(p, 4242)
	eq(JSON.stringify(a), JSON.stringify(b))


func test_types_come_in_threes() -> void:
	var p := Difficulty.params(18)
	var level := {}
	for c in 30:
		level = LevelGenerator.generate(p, 777 + c)
		if not level.is_empty():
			break
	var counts := {}
	for d in level.stickers:
		var types: Array = [d.type] + d.get("roll", [])
		for t in types:
			counts[t] = counts.get(t, 0) + 1
	for t in counts:
		if t != Sticker.RAINBOW:
			eq(counts[t] % 3, 0, "type %d count" % t)


func test_difficulty_curve() -> void:
	check(Difficulty.params(10).hard and Difficulty.params(20).hard, "every 10th level is Hard")
	check(not Difficulty.params(11).hard)
	eq(Difficulty.params(1).count, 9, "level 1 has 9 stickers")
	eq(Difficulty.params(1).types, 3)
	# Intro levels use only their new mechanic.
	for m in Mechanics.LIST:
		eq(Difficulty.params(m.level).mechanics.keys(), [m.id], "intro of %s" % m.id)
	check(Difficulty.params(13).mechanics.has("mystery"))
	check(Difficulty.params(50).count > Difficulty.params(6).count, "piles grow")


func _count(level: Dictionary) -> int:
	var n := 0
	for d in level.stickers:
		n += 1 + d.get("roll", []).size()
	return n
