extends Control
## A simple in-game level editor (debug builds: Settings > Level editor).
##
## Click the grid to place a sticker of the chosen type and mechanic on the
## chosen layer; click it again with Erase on to remove it. Dispenser modes
## add to the left or right queue. "Bot x500" measures difficulty, "Test play"
## opens the level in the game, "Save" writes levels/level_NNN.json with a
## winning order found by the bot (only from the editor or a desktop run;
## res:// is read-only on phones).

const KINDS := ["", "roll", "mystery", "glue", "padlock", "ice", "wrap", "rainbow", "fuse", "dispenser L", "dispenser R"]
const GRID_W := 12
const GRID_H := 14

var data := {}
var level_n := 1
var cur_type := 0
var cur_layer := 0
var cur_kind := ""
var cur_value := 3
var erase := false

var _grid: Control
var _status: Label
var _level_spin: SpinBox
var _type_pick: OptionButton
var _layer_spin: SpinBox
var _kind_pick: OptionButton
var _value_spin: SpinBox
var _erase_btn: CheckButton
var _cell := 40.0
var _origin := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.get_theme()
	add_child(Backdrop.make(2))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var row1 := HBoxContainer.new()
	col.add_child(row1)
	var back := IconButton.make("back", 72)
	back.pressed.connect(func(): Nav.go("settings"))
	row1.add_child(back)
	row1.add_child(_small_label("Level"))
	_level_spin = SpinBox.new()
	_level_spin.min_value = 1
	_level_spin.max_value = 999
	row1.add_child(_level_spin)
	row1.add_child(_small_button("Load", _on_load))
	row1.add_child(_small_button("Generate", _on_generate))
	row1.add_child(_small_button("Save", _on_save))

	var row2 := HBoxContainer.new()
	col.add_child(row2)
	row2.add_child(_small_label("Type"))
	_type_pick = OptionButton.new()
	_type_pick.item_selected.connect(func(i): cur_type = i)
	row2.add_child(_type_pick)
	row2.add_child(_small_label("Layer"))
	_layer_spin = SpinBox.new()
	_layer_spin.max_value = 7
	_layer_spin.value_changed.connect(_on_layer)
	row2.add_child(_layer_spin)

	var row3 := HBoxContainer.new()
	col.add_child(row3)
	_kind_pick = OptionButton.new()
	for k in KINDS:
		_kind_pick.add_item(k if k != "" else "plain")
	_kind_pick.item_selected.connect(func(i): cur_kind = KINDS[i])
	row3.add_child(_kind_pick)
	row3.add_child(_small_label("Value"))
	_value_spin = SpinBox.new()
	_value_spin.min_value = 1
	_value_spin.max_value = 20
	_value_spin.value = cur_value
	_value_spin.value_changed.connect(func(v): cur_value = int(v))
	row3.add_child(_value_spin)
	_erase_btn = CheckButton.new()
	_erase_btn.text = "Erase"
	_erase_btn.toggled.connect(func(on): erase = on)
	row3.add_child(_erase_btn)

	_grid = Control.new()
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.draw.connect(_draw_grid)
	_grid.gui_input.connect(_grid_input)
	_grid.resized.connect(func(): _grid.queue_redraw())
	col.add_child(_grid)

	_status = _small_label("")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	var row4 := HBoxContainer.new()
	row4.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row4)
	row4.add_child(_small_button("Check", _on_check))
	row4.add_child(_small_button("Bot x500", _on_bot))
	row4.add_child(_small_button("Test play", _on_test))

	if Nav.params.has("level_data"):
		data = Nav.params.level_data
		level_n = int(Nav.params.get("level", 1))
	else:
		level_n = Save.level
		data = LevelData.load_level(level_n).duplicate(true)
	_level_spin.value = level_n
	_refresh_types()


func _on_layer(v: float) -> void:
	cur_layer = int(v)
	_grid.queue_redraw()


func _small_label(t: String) -> Label:
	var l := UITheme.label(t, 24)
	l.custom_minimum_size = Vector2(0, 56)
	return l


func _small_button(t: String, cb: Callable) -> Button:
	var b := UITheme.button(t, UITheme.SKY, UITheme.SKY_DARK, 24)
	b.custom_minimum_size = Vector2(0, 64)
	b.pressed.connect(cb)
	return b


func _refresh_types() -> void:
	_type_pick.clear()
	for i in data.get("types", []).size():
		var t: Dictionary = data.types[i]
		_type_pick.add_item("%d %s %s" % [i, t.shape, UITheme.COLOR_MARKS[int(t.color)]])
	cur_type = clampi(cur_type, 0, maxi(0, data.types.size() - 1))
	_grid.queue_redraw()
	_on_check()


# --- Grid ------------------------------------------------------------------

func _layout() -> void:
	_cell = minf(_grid.size.x / (GRID_W + 7.0), _grid.size.y / (GRID_H + 1.0))
	_origin = Vector2((_grid.size.x - GRID_W * _cell) / 2.0, _cell * 0.5)


func _draw_grid() -> void:
	_layout()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.5)
	bg.set_corner_radius_all(16)
	_grid.draw_style_box(bg, Rect2(_origin - Vector2(8, 8), Vector2(GRID_W, GRID_H) * _cell + Vector2(16, 16)))
	for x in GRID_W + 1:
		for y in GRID_H + 1:
			_grid.draw_circle(_origin + Vector2(x, y) * _cell, 2.0, Color(0.4, 0.3, 0.5, 0.35))
	var list: Array = data.get("stickers", [])
	var order := range(list.size())
	order.sort_custom(func(a, b): return int(list[a].get("z", 0)) < int(list[b].get("z", 0)))
	var queues := [0, 0]
	for i in order:
		var d: Dictionary = list[i]
		var c: Vector2
		var alpha := 1.0
		if d.get("kind", "") == "dispenser":
			var q := int(d.get("queue", 0))
			c = _origin + Vector2(-2.5 if q == 0 else GRID_W + 2.5, 1.0 + queues[q] * 1.6) * _cell
			queues[q] += 1
		else:
			c = _origin + Vector2(int(d.x) + 1, int(d.y) + 1 - int(d.z) * 0.08) * _cell
			if int(d.z) != cur_layer:
				alpha = 0.45
		var t := int(d.type)
		var info: Dictionary = data.types[t] if t >= 0 and t < data.types.size() else {"shape": "star", "color": 0}
		_grid.draw_set_transform(Vector2.ZERO)
		StickerArt.draw(_grid, c, _cell * 0.8, String(info.shape), UITheme.sticker_color(int(info.color)).lerp(Color.WHITE, 1.0 - alpha), {"rainbow": t == Sticker.RAINBOW, "shadow": alpha > 0.9})
		var tag := String(d.get("kind", ""))
		if tag != "" and tag != "rainbow":
			var extra := ""
			for k in ["ice", "fuse", "key"]:
				if d.has(k):
					extra = str(d[k])
			if d.has("roll"):
				extra = str(d.roll.size() + 1)
			StickerArt.badge(_grid, c + Vector2(0, _cell * 0.55), _cell * 0.3, (tag.substr(0, 2) + extra), UITheme.INK, Color.WHITE)


func _grid_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_layout()
	if cur_kind.begins_with("dispenser"):
		var q := 0 if cur_kind.ends_with("L") else 1
		var n := 0
		for d in data.stickers:
			if d.get("kind", "") == "dispenser" and int(d.queue) == q:
				n += 1
		data.stickers.append({"type": cur_type, "kind": "dispenser", "queue": q, "order": n})
		_changed()
		return
	var g: Vector2 = (event.position - _origin) / _cell
	var x := clampi(int(round(g.x - 1.0)), 0, GRID_W - 2)
	var y := clampi(int(round(g.y - 1.0)), 0, GRID_H - 2)
	var hit := -1
	for i in data.stickers.size():
		var d: Dictionary = data.stickers[i]
		if d.has("x") and int(d.z) == cur_layer and absi(int(d.x) - x) < 2 and absi(int(d.y) - y) < 2:
			hit = i
	if erase:
		if hit >= 0:
			_remove(hit)
			_changed()
		return
	if hit >= 0:
		_status.text = "That spot on layer %d is taken (stickers on one layer can't overlap)." % cur_layer
		return
	var d := {"type": cur_type, "x": x, "y": y, "z": cur_layer}
	match cur_kind:
		"roll":
			d.roll = []
			for i in cur_value - 1:
				d.roll.append(cur_type)
		"padlock":
			d.key = (cur_type + 1) % maxi(1, data.types.size())
		"ice":
			d.ice = cur_value
		"fuse":
			d.fuse = cur_value
		"rainbow":
			d.type = Sticker.RAINBOW
		"glue":
			# Glue to the neighbour on the left, on the same layer.
			for j in data.stickers.size():
				var o: Dictionary = data.stickers[j]
				if o.has("x") and int(o.z) == cur_layer and int(o.y) == y and int(o.x) == x - 2 and o.get("kind", "") == "":
					o.kind = "glue"
					o.pair = data.stickers.size()
					d.pair = j
			if not d.has("pair"):
				_status.text = "Glue needs a plain sticker right next to it on the left."
				return
	if cur_kind != "" and cur_kind != "rainbow":
		d.kind = cur_kind
	elif cur_kind == "rainbow":
		d.kind = "rainbow"
	data.stickers.append(d)
	_changed()


func _remove(i: int) -> void:
	var d: Dictionary = data.stickers[i]
	if d.has("pair"):
		var o: Dictionary = data.stickers[int(d.pair)]
		o.erase("kind")
		o.erase("pair")
	data.stickers.remove_at(i)
	# Fix glue pair indices after the removal.
	for o in data.stickers:
		if o.has("pair") and int(o.pair) > i:
			o.pair = int(o.pair) - 1


func _changed() -> void:
	data.erase("solution")
	data.erase("bot_win_rate")
	_grid.queue_redraw()
	_on_check()


# --- Actions ---------------------------------------------------------------

func _on_check() -> void:
	var counts := {}
	for d in data.get("stickers", []):
		var types: Array = [int(d.type)] + Array(d.get("roll", []))
		for t in types:
			counts[t] = counts.get(t, 0) + 1
	var bad: Array[String] = []
	for t in counts:
		if t != Sticker.RAINBOW and counts[t] % 3 != 0:
			bad.append("type %d has %d" % [t, counts[t]])
	var total := 0
	for t in counts:
		total += counts[t]
	_status.text = "%d stickers. %s" % [total, "Every type comes in threes." if bad.is_empty() else "Not in threes: " + ", ".join(bad)]
	if data.has("bot_win_rate"):
		_status.text += " Bot win rate %.0f%%." % (float(data.bot_win_rate) * 100.0)


func _on_load() -> void:
	level_n = int(_level_spin.value)
	data = LevelData.load_level(level_n).duplicate(true)
	_refresh_types()


func _on_generate() -> void:
	level_n = int(_level_spin.value)
	var p := Difficulty.params(level_n)
	for c in 50:
		var lv := LevelGenerator.generate(p, level_n * 1000 + randi() % 100000)
		if not lv.is_empty():
			data = lv
			break
	_refresh_types()


func _on_bot() -> void:
	var rate := SolverBot.win_rate(BoardState.from_level(data), 500, 29)
	data.bot_win_rate = snappedf(rate, 0.01)
	_on_check()


func _on_test() -> void:
	data.level = level_n
	Nav.go("game", {"level": level_n, "level_data": data})


func _on_save() -> void:
	data.level = level_n
	data.hard = Difficulty.is_hard(level_n)
	data.tutorial = String(Mechanics.card_for(level_n).get("id", ""))
	var st := BoardState.from_level(data)
	var taps := SolverBot.find_solution(st, 400, 5)
	if taps.is_empty():
		_status.text = "Not saved: the bot found no winning order in 400 games."
		return
	data.solution = taps
	if not data.has("bot_win_rate"):
		_on_bot()
	var path := LevelData.path_for(level_n)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status.text = "Can't write %s here (res:// is read-only outside the editor)." % path
		return
	f.store_string(LevelData.to_json(data))
	f.close()
	LevelData._cache.erase(level_n)
	_status.text = "Saved %s." % path
