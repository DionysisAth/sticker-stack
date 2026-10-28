class_name BoardView
extends Control
## Draws the pile from a BoardState and turns touches into sticker taps.
## Positions are in half-sticker steps; higher layers sit a little higher so
## the pile reads as a stack. Dispensers sit in columns beside the pile, and
## stickers sent back by Return 3 sit in a row under it, between the two
## dispensers (when the level has them). Keeping everything inside the pile's
## width keeps stickers big enough to tap (48 dp and up).

signal sticker_tapped(id: int)

const LAYER_LIFT := 0.09   # in half-steps per layer
const MAX_CELL := 64.0

var state: BoardState
var views := {}            # sticker id -> StickerView
var cell := 50.0
var colorblind := false

var _origin := Vector2.ZERO
var _bounds := Rect2i(0, 0, 12, 14)
var _queue_x := [0.0, 10.0]
var _sheet_rect := Rect2()
var _layer: Node2D

# Hidden picture: paper covers the sheet; a spot fades open once no sticker
# covers it any more. Cells are half-sticker steps.
const PAPER := Color("#fff7ef")
const REVEAL_FADE_MS := 280.0
var picture := 0
var _footprint := {}       # cells under the pile at the start
var _revealed := {}        # cell -> time it opened (msec)
var _full := 0.0           # 0..1, the whole picture showing (level clear)
var _shine := -1.0         # light sweep across the picture, -1 = none


func _ready() -> void:
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_layer = Node2D.new()
	add_child(_layer)
	resized.connect(_on_resized)


func setup(st: BoardState) -> void:
	state = st
	for v in views.values():
		v.queue_free()
	views.clear()
	_compute_bounds()
	_footprint.clear()
	_revealed.clear()
	_full = 0.0
	_shine = -1.0
	for s in st.stickers:
		if s.on_board() and not s.returned:
			for c in _cells_of(s):
				_footprint[c] = true
	_layout()
	sync(false)


## Updates every view from the state; creates views for new stickers (Return 3,
## Undo) and returns their ids.
func sync(animate := true) -> Array[int]:
	var created: Array[int] = []
	if state == null:
		return created
	for s in state.stickers:
		if not s.alive:
			if views.has(s.id):
				views[s.id].queue_free()
				views.erase(s.id)
			continue
		var v: StickerView = views.get(s.id)
		if v == null:
			v = StickerView.new()
			_layer.add_child(v)
			views[s.id] = v
			created.append(s.id)
		_apply(s, v, animate and not created.has(s.id))
	_update_reveal(animate)
	return created


## Share of the hidden picture uncovered so far (0..1).
func revealed_share() -> float:
	return float(_revealed.size()) / maxf(1.0, _footprint.size())


## Level clear: the rest of the paper fades away and a shine sweeps across.
func reveal_all() -> void:
	var t := create_tween()
	t.tween_method(_set_full, 0.0, 1.0, 0.1 if Save.setting("reduce_motion") else 0.7)
	if not Save.setting("reduce_motion"):
		t.tween_method(_set_shine, 0.0, 1.0, 0.6)
		t.tween_callback(_set_shine.bind(-1.0))


func picture_rect() -> Rect2:
	return Rect2(_origin + Vector2(_bounds.position) * cell, Vector2(_bounds.size) * cell)


func _set_full(v: float) -> void:
	_full = v
	queue_redraw()


func _set_shine(v: float) -> void:
	_shine = v
	queue_redraw()


func _cells_of(s: Sticker) -> Array[Vector2i]:
	return [Vector2i(s.x, s.y), Vector2i(s.x + 1, s.y), Vector2i(s.x, s.y + 1), Vector2i(s.x + 1, s.y + 1)]


func _update_reveal(animate: bool) -> void:
	var covered := {}
	for s in state.stickers:
		if s.alive and s.on_board() and not s.returned:
			for c in _cells_of(s):
				covered[c] = true
	var now := Time.get_ticks_msec() - (0 if animate else int(REVEAL_FADE_MS))
	var changed := false
	for c in _footprint:
		if covered.has(c):
			if _revealed.erase(c):
				changed = true
		elif not _revealed.has(c):
			_revealed[c] = now
			changed = true
	if changed:
		set_process(true)
		queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()
	var now := Time.get_ticks_msec()
	for c in _revealed:
		if now - _revealed[c] < REVEAL_FADE_MS:
			return
	set_process(false)


## Hands a sticker's view over to the caller (it flies to the tray).
func take_view(id: int) -> StickerView:
	var v: StickerView = views.get(id)
	if v != null:
		views.erase(id)
	return v


func view_of(id: int) -> StickerView:
	return views.get(id)


func sticker_global_pos(id: int) -> Vector2:
	return get_global_transform() * _pos_of(state.stickers[id])


func sticker_size() -> float:
	return cell * 2.0


func _apply(s: Sticker, v: StickerView, animate: bool) -> void:
	v.size = cell * 2.0
	var info: Dictionary = {} if s.type == Sticker.RAINBOW else state.types[s.type]
	v.set_type(info, s.type == Sticker.RAINBOW, colorblind)
	v.face_down = s.hidden
	v.roll_count = s.count() if s.kind == "roll" else 0
	v.lock_info = state.types[s.key] if s.key >= 0 and s.key < state.types.size() else {}
	v.ice = s.ice
	v.wrapped = s.wrapped
	v.fuse = s.fuse
	v.glue_dir = Vector2.ZERO
	if s.pair >= 0 and state.stickers[s.pair].alive:
		var p := state.stickers[s.pair]
		v.glue_dir = Vector2(p.x - s.x, p.y - s.y).normalized()
	v.queue_depth = 0
	var visible_now := true
	if s.queue >= 0:
		var front := state.queue_front(s.queue)
		visible_now = front == s.id
		if visible_now:
			var behind := 0
			for o in state.stickers:
				if o.alive and o.queue == s.queue and o.id != s.id:
					behind += 1
			v.queue_depth = behind
			v.queue_side = -1.0 if s.queue == 0 else 1.0
	v.visible = visible_now
	v.z_index = s.z + (200 if s.returned else 0)
	var target := _pos_of(s)
	if animate and v.position.distance_to(target) > 1.0:
		var t := v.create_tween()
		t.tween_property(v, "position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		v.position = target
	var free := state.is_free(s)
	v.set_dim(not free, animate)
	v.queue_redraw()


func _pos_of(s: Sticker) -> Vector2:
	if s.queue >= 0:
		return _origin + Vector2(_queue_x[s.queue] + 1.0, _row_y() + 1.0) * cell
	var y := float(s.y)
	if s.returned:
		y = _row_y() + float(s.y - BoardState.RETURN_ROW_Y)
	return _origin + Vector2(s.x + 1.0, y + 1.0 - s.z * LAYER_LIFT) * cell


func _compute_bounds() -> void:
	var x0 := 99
	var y0 := 99
	var x1 := -99
	var y1 := -99
	for s in state.stickers:
		if s.queue >= 0 or s.returned:
			continue
		x0 = mini(x0, s.x)
		y0 = mini(y0, s.y)
		x1 = maxi(x1, s.x + 2)
		y1 = maxi(y1, s.y + 2)
	if x0 > x1:
		x0 = 0
		y0 = 0
		x1 = 12
		y1 = 12
	# The bottom row (dispensers and Return 3) needs x 0..12 with
	# dispensers, 3..9 without.
	var queues := state.has_rule("dispenser")
	x0 = mini(x0, 0 if queues else 3)
	x1 = maxi(x1, 12 if queues else 9)
	_bounds = Rect2i(x0, y0, x1 - x0, y1 - y0)
	_queue_x = [float(x0), float(x1) - 2.0]


## Top of the row under the pile.
func _row_y() -> float:
	return float(_bounds.end.y) + 0.7


func _layout() -> void:
	if state == null:
		return
	var x0 := float(_bounds.position.x) - 0.4
	var x1 := float(_bounds.end.x) + 0.4
	var y0 := float(_bounds.position.y) - 0.6
	var y1 := float(_bounds.end.y) + 2.9   # room for the return row
	cell = minf(minf(size.x / (x1 - x0), size.y / (y1 - y0)), MAX_CELL)
	var used := Vector2((x1 - x0) * cell, (y1 - y0) * cell)
	_origin = (size - used) / 2.0 - Vector2(x0, y0) * cell
	_sheet_rect = Rect2(_origin + Vector2(_bounds.position) * cell - Vector2(cell, cell) * 0.5,
		Vector2(_bounds.size) * cell + Vector2(cell, cell))
	queue_redraw()


func _on_resized() -> void:
	_layout()
	sync(false)


func _draw() -> void:
	if state == null:
		return
	# The backing sheet the stickers sit on.
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = PAPER
	sheet.set_corner_radius_all(int(cell * 0.8))
	sheet.border_color = Color.WHITE
	sheet.set_border_width_all(5)
	sheet.shadow_color = Color(0.25, 0.08, 0.3, 0.15)
	sheet.shadow_size = 8
	sheet.shadow_offset = Vector2(0, 4)
	draw_style_box(sheet, _sheet_rect)
	_draw_picture()
	# Dispenser chutes.
	if state.has_rule("dispenser"):
		for q in 2:
			var c := _origin + Vector2(_queue_x[q] + 1.0, _row_y() + 1.0) * cell
			var r := Rect2(c - Vector2(cell * 1.3, cell * 1.3), Vector2(cell * 2.6, cell * 2.75))
			var chute := StyleBoxFlat.new()
			chute.bg_color = Color(1, 1, 1, 0.35)
			chute.set_corner_radius_all(int(cell * 0.6))
			chute.border_color = Color(1, 1, 1, 0.7)
			chute.set_border_width_all(3)
			draw_style_box(chute, r)


func _draw_picture() -> void:
	var pr := picture_rect()
	if pr.size.x <= 0 or cell <= 0:
		return
	Picture.draw(self, pr, picture)
	# Paper over every spot that isn't uncovered yet.
	var now := Time.get_ticks_msec()
	for y in range(_bounds.position.y, _bounds.end.y):
		for x in range(_bounds.position.x, _bounds.end.x):
			var c := Vector2i(x, y)
			var a := 1.0
			if _revealed.has(c):
				a = 1.0 - clampf((now - _revealed[c]) / REVEAL_FADE_MS, 0.0, 1.0)
			a = minf(a, 1.0 - _full)
			if a <= 0.0:
				continue
			var r := Rect2(_origin + Vector2(x, y) * cell, Vector2(cell, cell))
			draw_rect(r, Color(PAPER, a))
	# Shine sweeping across on clear.
	if _shine >= 0.0:
		var x := pr.position.x + (pr.size.x + pr.size.y) * _shine - pr.size.y
		var band := cell * 1.6
		var poly := PackedVector2Array([
			Vector2(x, pr.end.y), Vector2(x + band, pr.end.y),
			Vector2(x + band + pr.size.y, pr.position.y), Vector2(x + pr.size.y, pr.position.y)])
		var clipped := Geometry2D.intersect_polygons(poly, PackedVector2Array([pr.position, Vector2(pr.end.x, pr.position.y), pr.end, Vector2(pr.position.x, pr.end.y)]))
		for part in clipped:
			draw_colored_polygon(part, Color(1, 1, 1, 0.45))
	# A thin frame around the picture area.
	draw_rect(pr, Color(0.85, 0.75, 0.8, 0.5), false, 2.0)


func _gui_input(event: InputEvent) -> void:
	# Touches arrive as mouse clicks too (emulate_mouse_from_touch), so only
	# mouse buttons are handled, to never count one tap twice.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if state == null:
		return
	var id := sticker_at(event.position)
	if id >= 0:
		accept_event()
		sticker_tapped.emit(id)


## The topmost visible sticker under a point (local coordinates), or -1.
func sticker_at(pos: Vector2) -> int:
	var best := -1
	var best_z := -1
	var half := cell * 0.98
	for s in state.stickers:
		if not s.alive:
			continue
		var v: StickerView = views.get(s.id)
		if v == null or not v.visible:
			continue
		var d := pos - v.position
		if absf(d.x) <= half and absf(d.y) <= half:
			var z := s.z + (200 if s.returned else 0)
			if z > best_z:
				best_z = z
				best = s.id
	return best
