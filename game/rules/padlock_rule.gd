extends Rule
## Padlock: a locked sticker opens when a triple of its key type clears.


func _init() -> void:
	kind = "padlock"


func hooks() -> Array[String]:
	return ["blocked_reason", "after_clear"]


func blocked_reason(_state: BoardState, s: Sticker) -> String:
	return "locked" if s.key >= 0 else ""


func after_clear(state: BoardState, cleared: Dictionary) -> void:
	var cleared_type: int = cleared.type
	for s in state.stickers:
		if s.alive and s.key >= 0 and s.key == cleared_type:
			s.key = -1
			state.emit_event({"e": "unlock", "id": s.id})
