extends Rule
## Mystery stickers are face down until nothing covers them.


func _init() -> void:
	kind = "mystery"


func hooks() -> Array[String]:
	return ["on_start", "after_pick"]


func on_start(state: BoardState) -> void:
	_reveal(state)


func after_pick(state: BoardState, _picked: Array[Sticker]) -> void:
	_reveal(state)


func _reveal(state: BoardState) -> void:
	for s in state.stickers:
		if s.alive and s.hidden and state.is_free(s):
			s.hidden = false
			state.emit_event({"e": "reveal", "id": s.id})
