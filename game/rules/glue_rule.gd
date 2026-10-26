extends Rule
## Glued pairs: two stickers come off together and need two tray slots.
## Both must be free.


func _init() -> void:
	kind = "glue"


func hooks() -> Array[String]:
	return ["blocked_reason", "extra_picks"]


func blocked_reason(state: BoardState, s: Sticker) -> String:
	if s.pair >= 0:
		var p := state.stickers[s.pair]
		if p.alive and not state.is_free(p):
			return "glued"
	return ""


func extra_picks(state: BoardState, s: Sticker) -> Array[Sticker]:
	var out: Array[Sticker] = []
	if s.pair >= 0 and state.stickers[s.pair].alive:
		out.append(state.stickers[s.pair])
	return out
