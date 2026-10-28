class_name StreakFlame
extends Control
## The win-streak flame with the streak number on it. Flickers gently.

var streak := 0
var _t := 0.0


static func make(n: int, diameter := 84.0) -> StreakFlame:
	var f := StreakFlame.new()
	f.streak = n
	f.custom_minimum_size = Vector2(diameter, diameter)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f


func set_streak(n: int) -> void:
	streak = n
	queue_redraw()


func _process(delta: float) -> void:
	if streak > 0 and not Save.setting("reduce_motion"):
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0 + Vector2(0, size.y * 0.06)
	var r := minf(size.x, size.y) * 0.42
	var lit := streak > 0
	var flick := sin(_t * 9.0) * 0.04 + sin(_t * 5.3) * 0.03
	var outer := _flame(c, r * (1.0 + flick), 1.0)
	var inner := _flame(c + Vector2(0, r * 0.22), r * 0.6 * (1.0 - flick), 0.8)
	var shadow := PackedVector2Array()
	for p in outer:
		shadow.append(p + Vector2(0, 4))
	draw_colored_polygon(shadow, Color(0.25, 0.05, 0.3, 0.22))
	draw_polyline(_closed(outer), Color.WHITE, 8.0, true)
	draw_colored_polygon(outer, Color("#ff6a3d") if lit else Color("#c9bfd4"))
	draw_colored_polygon(inner, Color("#ffd23f") if lit else Color("#e4dcec"))
	if streak > 0:
		var txt := str(streak)
		var fs := int(r * (0.95 if txt.length() < 2 else 0.75))
		var font := UITheme.font_bold()
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base := c + Vector2(-w / 2.0, r * 0.62)
		draw_string_outline(font, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, UITheme.ACCENT_DARK)
		draw_string(font, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## A teardrop flame pointing up, with a little curl at the tip.
func _flame(c: Vector2, r: float, sway: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		# A teardrop, with licks along the upper edges.
		var licks := 1.0 + 0.16 * sin(5.0 * t + _t * 3.0 * sway) * maxf(0.0, cos(t) + 0.2)
		var x := sin(t) * (0.5 - 0.5 * cos(t)) * 0.95 * licks
		var y := (-cos(t) * 1.15 + 0.15) * (1.0 + 0.06 * absf(sin(2.5 * t)))
		x += sin(_t * 4.0) * 0.06 * sway * maxf(0.0, -y)
		pts.append(c + Vector2(x, y) * r)
	return pts


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
