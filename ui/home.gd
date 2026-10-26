extends Control
## Home: one big Play button for the current level, the boosters you hold,
## and settings. No level select.

var _deco: Array[StickerView] = []
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.get_theme()
	add_child(Backdrop.make(Save.level))
	_add_decoration()

	var safe := Screen.safe_margins(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24 + int(safe.x))
	margin.add_theme_constant_override("margin_bottom", 40 + int(safe.y))
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(top)
	var gear := IconButton.make("gear", 88, UITheme.INK_SOFT, UITheme.INK)
	gear.pressed.connect(func(): Nav.go("settings"))
	top.add_child(gear)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var title := UITheme.label("Sticker\nStack", 120, UITheme.ACCENT, true)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 34)
	title.add_theme_color_override("font_shadow_color", Color(0.3, 0.1, 0.35, 0.3))
	title.add_theme_constant_override("shadow_offset_y", 10)
	title.add_theme_constant_override("line_spacing", -26)
	col.add_child(title)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer2)

	var n := Save.level
	if Difficulty.is_hard(n):
		var tag := UITheme.label("HARD LEVEL", 28, UITheme.DANGER, true)
		col.add_child(tag)
	var play := UITheme.button("Play · Level %d" % n, UITheme.GO, UITheme.GO_DARK, 50)
	play.custom_minimum_size = Vector2(0, 150)
	play.pressed.connect(func(): Nav.go("game", {"level": Save.level}))
	col.add_child(play)
	Card.bounce_in(play, 0.15)

	var intro := Mechanics.next_intro_after(n - 1)
	if intro > 0:
		var left := intro - n
		var text := "New sticker trick this level!" if left == 0 else "New sticker trick in %d level%s" % [left, "" if left == 1 else "s"]
		col.add_child(UITheme.label(text, 28, UITheme.INK_SOFT))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)
	for info in [["undo", "Undo"], ["return3", "Return 3"], ["shuffle", "Shuffle"]]:
		var v := VBoxContainer.new()
		var b := IconButton.make(info[0], 88, UITheme.SKY, UITheme.SKY_DARK)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.set_count(int(Save.boosters.get(info[0], 0)))
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(b)
		v.add_child(UITheme.label(info[1], 22, UITheme.INK, true))
		row.add_child(v)


func _add_decoration() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var shapes := LevelGenerator.SHAPES
	var spots := [Vector2(0.12, 0.2), Vector2(0.85, 0.24), Vector2(0.18, 0.5), Vector2(0.82, 0.52), Vector2(0.5, 0.12)]
	for i in spots.size():
		var v := StickerView.new()
		v.size = rng.randf_range(90, 130)
		v.set_type({"shape": shapes[i % shapes.size()], "color": i}, false, Save.setting("colorblind"))
		v.rotation = rng.randf_range(-0.4, 0.4)
		v.set_meta("spot", spots[i])
		v.set_meta("phase", rng.randf() * TAU)
		v.modulate.a = 0.85
		add_child(v)
		_deco.append(v)
	_place_deco()


func _place_deco() -> void:
	for v in _deco:
		var s: Vector2 = v.get_meta("spot")
		var bob := 0.0 if Save.setting("reduce_motion") else sin(_t * 1.3 + v.get_meta("phase")) * 10.0
		v.position = Vector2(s.x * size.x, s.y * size.y + bob)


func _process(delta: float) -> void:
	_t += delta
	_place_deco()
