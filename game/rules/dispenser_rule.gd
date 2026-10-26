extends Rule
## Side dispensers: two queues beside the pile. Only the front sticker of a
## queue can be taken.


func _init() -> void:
	kind = "dispenser"


func hooks() -> Array[String]:
	return ["is_free"]


func is_free(state: BoardState, s: Sticker) -> int:
	if s.queue < 0:
		return -1
	return 1 if state.queue_front(s.queue) == s.id else 0
