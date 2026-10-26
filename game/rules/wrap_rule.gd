extends Rule
## Bubble wrap: the first tap pops the wrap, the second peels the sticker.
## Popping is not a pick, so it doesn't count down ice or fuses.


func _init() -> void:
	kind = "wrap"


func hooks() -> Array[String]:
	return ["on_tap"]


func on_tap(state: BoardState, s: Sticker) -> bool:
	if s.wrapped:
		s.wrapped = false
		state.emit_event({"e": "wrap_pop", "id": s.id})
		return true
	return false
