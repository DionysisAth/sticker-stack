extends Node
## Scene navigation with a short fade. `params` carries data to the next
## screen (for example a level from the editor to test-play).

const SCENES := {
	"home": "res://ui/home.tscn",
	"game": "res://ui/game.tscn",
	"settings": "res://ui/settings.tscn",
	"editor": "res://tools/level_editor.tscn",
}

var params := {}
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(1, 0.93, 0.86, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func go(screen: String, with_params := {}) -> void:
	if _busy:
		return
	_busy = true
	params = with_params
	var instant: bool = Save.setting("reduce_motion")
	if not instant:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 1.0, 0.15)
		await t.finished
	get_tree().change_scene_to_file(SCENES.get(screen, screen))
	if not instant:
		await get_tree().process_frame
		var t2 := create_tween()
		t2.tween_property(_fade, "color:a", 0.0, 0.2)
		await t2.finished
	_busy = false
