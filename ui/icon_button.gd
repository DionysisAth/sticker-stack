class_name IconButton
extends Button
## A round chunky button with a drawn icon and an optional count badge.
## Icons: home, gear, undo, return3, shuffle, back, close.

var icon_name := "home"
var count := -1
var face := UITheme.SKY
var lip := UITheme.SKY_DARK


static func make(icon_id: String, diameter := 96.0, face_color := UITheme.SKY, lip_color := UITheme.SKY_DARK) -> IconButton:
	var b := IconButton.new()
	b.icon_name = icon_id
	b.face = face_color
	b.lip = lip_color
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.focus_mode = Control.FOCUS_NONE
	var n := UITheme.button_box(face_color, lip_color)
	n.set_corner_radius_all(int(diameter / 2))
	var p := UITheme.button_box(lip_color, lip_color, true)
	p.set_corner_radius_all(int(diameter / 2))
	var d := UITheme.button_box(Color("#cfc4da"), Color("#ad9fbd"))
	d.set_corner_radius_all(int(diameter / 2))
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	b.pressed.connect(func(): Audio.play("click"))
	return b


func set_count(n: int) -> void:
	count = n
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0 - Vector2(0, 3 if not button_pressed else -2)
	var r := minf(size.x, size.y) * 0.24
	var col := Color.WHITE
	var w := maxf(4.0, r * 0.26)
	match icon_name:
		"home":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -0.05 * r), c + Vector2(0, -r), c + Vector2(r, -0.05 * r)]), col)
			draw_rect(Rect2(c + Vector2(-0.7 * r, -0.1 * r), Vector2(1.4 * r, 0.95 * r)), col)
			draw_rect(Rect2(c + Vector2(-0.2 * r, 0.3 * r), Vector2(0.4 * r, 0.55 * r)), face)
		"gear":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2(cos(a), sin(a)) * r * 0.5, c + Vector2(cos(a), sin(a)) * r * 1.05, col, w * 1.3, true)
			draw_circle(c, r * 0.78, col)
			draw_circle(c, r * 0.32, face)
		"undo":
			draw_arc(c + Vector2(0.1 * r, 0.1 * r), r * 0.8, -PI * 0.9, PI * 0.55, 24, col, w, true)
			var tip := c + Vector2(0.1 * r, 0.1 * r) + Vector2(cos(-PI * 0.9), sin(-PI * 0.9)) * r * 0.8
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.5 * r, 0.1 * r), tip + Vector2(0.35 * r, -0.45 * r), tip + Vector2(0.3 * r, 0.45 * r)]), col)
		"return3":
			draw_line(c + Vector2(0, 0.9 * r), c + Vector2(0, -0.4 * r), col, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.6 * r, -0.25 * r), c + Vector2(0, -r), c + Vector2(0.6 * r, -0.25 * r)]), col)
			for i in 3:
				draw_circle(c + Vector2((i - 1) * 0.75 * r, 1.05 * r), r * 0.16, col)
		"shuffle":
			draw_line(c + Vector2(-r, -0.5 * r), c + Vector2(r * 0.6, 0.5 * r), col, w, true)
			draw_line(c + Vector2(-r, 0.5 * r), c + Vector2(r * 0.6, -0.5 * r), col, w, true)
			for sgn in [-1.0, 1.0]:
				var tip := c + Vector2(r, sgn * 0.5 * r)
				draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-0.5 * r, sgn * -0.05 * r - 0.3 * r), tip + Vector2(-0.5 * r, sgn * -0.05 * r + 0.3 * r)]), col)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(0.35 * r, -0.8 * r), c + Vector2(-0.45 * r, 0), c + Vector2(0.35 * r, 0.8 * r)]), col, w * 1.2, true)
		"close":
			draw_line(c + Vector2(-0.7, -0.7) * r, c + Vector2(0.7, 0.7) * r, col, w * 1.2, true)
			draw_line(c + Vector2(-0.7, 0.7) * r, c + Vector2(0.7, -0.7) * r, col, w * 1.2, true)
	if count >= 0:
		var at := Vector2(size.x - size.x * 0.14, size.y * 0.14)
		StickerArt.badge(self, at, size.x * 0.15, str(count), UITheme.ACCENT if count > 0 else Color("#b0a4bf"), Color.WHITE)
