extends Node
## Haptics: a light tick on peel, a medium tap on a triple, a double buzz on
## fail, a heartbeat when the tray is nearly full.


func _on() -> bool:
	return Save.setting("haptics") and OS.has_feature("mobile")


func tick() -> void:
	if _on():
		Input.vibrate_handheld(12, 0.35)


func tap() -> void:
	if _on():
		Input.vibrate_handheld(28, 0.7)


func heartbeat(strong := false) -> void:
	if _on():
		Input.vibrate_handheld(40 if strong else 22, 0.8 if strong else 0.45)


func double_buzz() -> void:
	if not _on():
		return
	Input.vibrate_handheld(60, 1.0)
	await get_tree().create_timer(0.14).timeout
	Input.vibrate_handheld(60, 1.0)
