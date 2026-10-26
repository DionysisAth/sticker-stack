class_name BoardView
extends Control
## Draws the pile from a BoardState and turns touches into sticker taps.
## Positions are in half-sticker steps; higher layers sit a little higher so
## the pile reads as a stack. Dispensers sit in columns beside the pile, and
## stickers sent back by Return 3 sit in a row under it.

signal sticker_tapped(id: int)

const LAYER_LIFT := 0.09   # in half-steps per layer
const MAX_CELL := 64.0

var state: BoardState
var views := {}            # sticker id -> StickerView
var cell := 50.0
var colorblind := false

var _origin := Vector2.ZERO
var _bounds := Rect2i(0, 0, 12, 14)
var _queue_x := [-3.2, 13.2]
var _sheet_rect := Rect2()
var _layer: Node2D


func _ready() -> void:
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
	return created


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
		var front_y := float(_bounds.end.y) - 1.0
		return _origin + Vector2(_queue_x[s.queue] + 1.0, front_y) * cell
	var y := float(s.y)
	if s.returned:
		y = float(_bounds.end.y) + 0.7 + float(s.y - BoardState.RETURN_ROW_Y)
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
	# The return row needs x 2..10.
	x0 = mini(x0, 2)
	x1 = maxi(x1, 10)
	_bounds = Rect2i(x0, y0, x1 - x0, y1 - y0)
	_queue_x = [float(x0) - 3.2, float(x1) + 1.2]


func _layout() -> void:
	if state == null:
		return
	var has_queues := state.has_rule("dispenser")
	var x0 := float(_bounds.position.x) - (3.4 if has_queues else 0.4)
	var x1 := float(_bounds.end.x) + (3.4 if has_queues else 0.4)
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
	sheet.bg_color = Color(1, 1, 1, 0.55)
	sheet.set_corner_radius_all(int(cell * 0.8))
	sheet.border_color = Color(1, 1, 1, 0.85)
	sheet.set_border_width_all(4)
	draw_style_box(sheet, _sheet_rect)
	# Dispenser chutes.
	if state.has_rule("dispenser"):
		for q in 2:
			var c := _origin + Vector2(_queue_x[q] + 1.0, float(_bounds.end.y) - 1.0) * cell
			var r := Rect2(c - Vector2(cell * 1.25, cell * 4.6), Vector2(cell * 2.5, cell * 5.85))
			var chute := StyleBoxFlat.new()
			chute.bg_color = Color(1, 1, 1, 0.35)
			chute.set_corner_radius_all(int(cell * 0.6))
			chute.border_color = Color(1, 1, 1, 0.7)
			chute.set_border_width_all(3)
			draw_style_box(chute, r)


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
