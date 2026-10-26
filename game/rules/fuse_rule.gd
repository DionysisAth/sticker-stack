extends Rule
## Fuse: must be peeled within N picks or the level fails.


func _init() -> void:
	kind = "fuse"


func hooks() -> Array[String]:
	return ["after_pick"]


func after_pick(state: BoardState, picked: Array[Sticker]) -> void:
	for s in state.stickers:
		if s.alive and s.fuse > 0 and not picked.has(s):
			s.fuse -= 1
			state.emit_event({"e": "fuse", "id": s.id, "left": s.fuse})
			if s.fuse == 0 and state.status == BoardState.Status.PLAYING:
				state.fail("fuse", s.id)
