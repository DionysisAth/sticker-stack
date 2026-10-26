extends Control
## Settings: sound, haptics, colour-blind symbols, reduce motion, reset.

const TOGGLES := [
	["sound", "Sound"],
	["haptics", "Haptics"],
	["colorblind", "Colour-blind symbols"],
	["reduce_motion", "Reduce motion"],
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.make(Save.level + 1))
	var safe := Screen.safe_margins(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24 + int(safe.x))
	margin.add_theme_constant_override("margin_bottom", 40 + int(safe.y))
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	margin.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var back := IconButton.make("back", 88)
	back.pressed.connect(func(): Nav.go("home"))
	top.add_child(back)
	var title := UITheme.label("Settings", 56, UITheme.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(88, 88)
	top.add_child(pad)

	var panel := PanelContainer.new()
	col.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 18)
	panel.add_child(list)
	for t in TOGGLES:
		var cb := CheckButton.new()
		cb.text = t[1]
		cb.button_pressed = Save.setting(t[0])
		cb.custom_minimum_size = Vector2(0, 84)
		cb.focus_mode = Control.FOCUS_NONE
		cb.toggled.connect(_on_toggle.bind(t[0]))
		list.add_child(cb)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	if OS.is_debug_build():
		var editor := UITheme.button("Level editor", UITheme.SKY, UITheme.SKY_DARK, 32)
		editor.pressed.connect(func(): Nav.go("editor"))
		col.add_child(editor)
	var reset := UITheme.button("Reset progress", Color("#b9adc8"), Color("#968aa6"), 32)
	reset.pressed.connect(_confirm_reset)
	col.add_child(reset)
	var version := UITheme.label("Sticker Stack %s" % ProjectSettings.get_setting("application/config/version", ""), 22, UITheme.INK_SOFT)
	col.add_child(version)


func _on_toggle(on: bool, key: String) -> void:
	Save.set_setting(key, on)
	Audio.play("click")


func _confirm_reset() -> void:
	var c := Card.make(self)
	c.box.add_child(UITheme.label("Start again from level 1?", 40, UITheme.INK, true))
	c.box.add_child(UITheme.label("Your level and boosters go back to the start.", 28, UITheme.INK_SOFT))
	var yes := UITheme.button("Reset", UITheme.DANGER, UITheme.DANGER.darkened(0.25))
	var do_reset := func() -> void:
		Save.reset()
		c.close()
	yes.pressed.connect(do_reset)
	c.box.add_child(yes)
	var no := UITheme.button("Keep playing", UITheme.GO, UITheme.GO_DARK)
	no.pressed.connect(c.close)
	c.box.add_child(no)
