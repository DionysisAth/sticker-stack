extends Rule
## Rainbow: matches any type. The tray does the matching (a rainbow completes
## the leftmost pair). When it completes a pair, the one sticker of that type
## now left over turns into a rainbow, so the pile can always still be
## cleared: spending it early is a choice, never a trap.


func _init() -> void:
	kind = "rainbow"


func hooks() -> Array[String]:
	return ["after_clear"]


func after_clear(state: BoardState, cleared: Dictionary) -> void:
	var t: int = cleared.type
	if int(cleared.get("rainbows", 0)) == 0 or t == Sticker.RAINBOW:
		return
	# Count what's left of that type, and pick the sticker to turn: a
	# visible one if possible (free first, then the highest), else one inside
	# a roll.
	var left := state.tray.count_of(t)
	var best: Sticker = null
	var roll_owner: Sticker = null
	var roll_index := -1
	for s in state.stickers:
		if not s.alive:
			continue
		if s.type == t:
			left += 1
			if best == null or _better(state, s, best):
				best = s
		for i in s.roll.size():
			if s.roll[i] == t:
				left += 1
				roll_owner = s
				roll_index = i
	if left % 3 != 1:
		return
	if best != null:
		best.type = Sticker.RAINBOW
		state.emit_event({"e": "rainbowed", "id": best.id})
	elif roll_owner != null:
		roll_owner.roll[roll_index] = Sticker.RAINBOW
		state.emit_event({"e": "rainbowed", "id": roll_owner.id})


func _better(state: BoardState, a: Sticker, b: Sticker) -> bool:
	var fa := state.is_free(a)
	var fb := state.is_free(b)
	if fa != fb:
		return fa
	return a.z > b.z
