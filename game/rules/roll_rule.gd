extends Rule
## Sticker rolls: a stack where only the top sticker shows. Peeling the top
## reveals the next one; the roll stays on the pile until it's empty.


func _init() -> void:
	kind = "roll"


func hooks() -> Array[String]:
	return ["take"]


func take(state: BoardState, s: Sticker) -> bool:
	if s.roll.is_empty():
		return false
	s.type = s.roll.pop_front()
	state.emit_event({"e": "roll_next", "id": s.id, "type": s.type})
	return true
