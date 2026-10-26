extends Rule
## Ice: a frozen sticker thaws after N other picks.


func _init() -> void:
	kind = "ice"


func hooks() -> Array[String]:
	return ["blocked_reason", "after_pick"]


func blocked_reason(_state: BoardState, s: Sticker) -> String:
	return "frozen" if s.ice > 0 else ""


func after_pick(state: BoardState, picked: Array[Sticker]) -> void:
	for s in state.stickers:
		if s.alive and s.ice > 0 and not picked.has(s):
			s.ice -= 1
			state.emit_event({"e": "thaw" if s.ice == 0 else "ice", "id": s.id})
