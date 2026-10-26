class_name TrayView
extends Control
## The 7-slot tray in the bottom third. Draws the slots and the danger edge;
## the sticker nodes themselves live in the game's effects layer so they can
## fly in from the board.

var fill := 0
var _pulse := 0.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if fill >= Tray.CAPACITY - 2:
		var speed := 7.0 if fill >= Tray.CAPACITY - 1 else 4.5
		_pulse = 0.5 + 0.5 * sin(_time * speed)
		queue_redraw()
	elif _pulse != 0.0:
		_pulse = 0.0
		queue_redraw()


func set_fill(n: int) -> void:
	fill = n
	queue_redraw()


func slot_size() -> float:
	var pad := 14.0
	var gap := 8.0
	return minf((size.x - pad * 2 - gap * (Tray.CAPACITY - 1)) / Tray.CAPACITY, size.y - pad * 2)


func slot_center(i: int) -> Vector2:
	var s := slot_size()
	var gap := 8.0
	var total := s * Tray.CAPACITY + gap * (Tray.CAPACITY - 1)
	var x0 := (size.x - total) / 2.0
	return Vector2(x0 + i * (s + gap) + s / 2.0, size.y / 2.0)


func slot_global(i: int) -> Vector2:
	return get_global_transform() * slot_center(i)


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#fff6ee")
	box.set_corner_radius_all(34)
	box.shadow_color = Color(0.24, 0.1, 0.3, 0.22)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 6)
	var danger := fill >= Tray.CAPACITY - 2
	if danger:
		var strong := fill >= Tray.CAPACITY - 1
		box.border_color = UITheme.DANGER.lerp(Color("#ffb3b3"), 1.0 - _pulse)
		box.set_border_width_all(int(lerpf(6, 12 if strong else 9, _pulse)))
	else:
		box.border_color = Color.WHITE
		box.set_border_width_all(6)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var s := slot_size()
	for i in Tray.CAPACITY:
		var c := slot_center(i)
		var slot := StyleBoxFlat.new()
		slot.bg_color = Color("#f1e4ec")
		slot.set_corner_radius_all(int(s * 0.3))
		draw_style_box(slot, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)))
