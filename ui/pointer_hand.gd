class_name PointerHand
extends Node2D
## The pointing hand for the first taps of levels 1-3.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 6.0) * 8.0
	var ring := fmod(_t * 1.4, 1.0)
	draw_arc(Vector2.ZERO, 30 + ring * 40, 0, TAU, 32, Color(1, 1, 1, 0.9 * (1.0 - ring)), 6.0, true)
	var o := Vector2(26, 34 + bob)
	var finger := Rect2(o + Vector2(-12, -6), Vector2(24, 62))
	var palm := Rect2(o + Vector2(-16, 40), Vector2(56, 52))
	for shadow in [true, false]:
		var off := Vector2(0, 5) if shadow else Vector2.ZERO
		var col := Color(0.2, 0.05, 0.25, 0.25) if shadow else Color.WHITE
		var f := StyleBoxFlat.new()
		f.bg_color = col
		f.set_corner_radius_all(12)
		f.border_color = UITheme.INK if not shadow else col
		f.set_border_width_all(0 if shadow else 4)
		draw_style_box(f, Rect2(finger.position + off, finger.size))
		var p := f.duplicate()
		p.set_corner_radius_all(20)
		draw_style_box(p, Rect2(palm.position + off, palm.size))
	draw_rect(Rect2(o + Vector2(-8, 44), Vector2(16, 8)), Color.WHITE)
