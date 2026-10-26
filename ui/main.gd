extends Node
## Entry point: applies the theme and opens the home screen.


func _ready() -> void:
	get_tree().root.theme = UITheme.get_theme()
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().change_scene_to_file.call_deferred(Nav.SCENES.home)
