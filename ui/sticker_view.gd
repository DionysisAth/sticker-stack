class_name StickerView
extends Node2D
## Draws one sticker and whatever mechanic sits on it. Used on the board, in
## the tray, while flying, and on tutorial cards.

var shape := "circle"
var color := Color.WHITE
var rainbow := false
var face_down := false
var mark := ""
## Full width in pixels.
var size := 100.0

# Mechanic overlays.
var roll_count := 0
var lock_info := {}        # key type ({shape, color}) while locked
var ice := 0
var wrapped := false
var fuse := 0
var glue_dir := Vector2.ZERO
var queue_depth := 0       # dispenser: stickers behind this one
var queue_side := -1.0     # which way the queue fans out (-1 left, 1 right)

var _dim := 0.0


func set_type(info: Dictionary, is_rainbow: bool, colorblind: bool) -> void:
	rainbow = is_rainbow
	if not is_rainbow and not info.is_empty():
		shape = String(info.get("shape", "circle"))
		var ci := int(info.get("color", 0))
		color = UITheme.sticker_color(ci)
		mark = UITheme.COLOR_MARKS[posmod(ci, UITheme.COLOR_MARKS.size())] if colorblind else ""
	else:
		mark = ""
	queue_redraw()


## Covered stickers are dimmed but stay visible.
func set_dim(on: bool, animate := true) -> void:
	var target := 1.0 if on else 0.0
	if not animate:
		_dim = target
		_apply_dim()
		return
	if is_equal_approx(_dim, target):
		return
	var t := create_tween()
	t.tween_method(_set_dim_value, _dim, target, 0.18)


func _set_dim_value(v: float) -> void:
	_dim = v
	_apply_dim()


func _apply_dim() -> void:
	var k := lerpf(1.0, 0.58, _dim)
	modulate = Color(k, k, k * 1.06, 1.0)


func _draw() -> void:
	if size < 4.0:
		return
	var r := size * 0.5 * 0.8
	# Roll: the stack edges peek out below.
	if roll_count > 1:
		var layers := mini(roll_count - 1, 3)
		for i in range(layers, 0, -1):
			var off := Vector2(i * r * 0.07, i * r * 0.1)
			StickerArt.draw(self, off, r, "square", Color("#e9e1f2"), {"shadow": i == layers})
	# Dispenser: the queue behind the front sticker.
	if queue_depth > 0:
		for i in range(mini(queue_depth, 3), 0, -1):
			StickerArt.draw(self, Vector2(queue_side * i * r * 0.2, i * r * 0.06), r * 0.92, "square", Color("#e9e1f2"), {"shadow": false})
	# Glue tape sits under the sticker edge.
	if glue_dir != Vector2.ZERO:
		_tape(r)
	StickerArt.draw(self, Vector2.ZERO, r, shape, color, {"rainbow": rainbow, "hidden": face_down, "mark": mark})
	if glue_dir != Vector2.ZERO:
		_tape(r, true)
	if wrapped:
		_bubble_wrap(r)
	if ice > 0:
		_ice(r)
	if not lock_info.is_empty():
		_padlock(r)
	if fuse > 0:
		_fuse(r)
	if roll_count > 1:
		StickerArt.badge(self, Vector2(-r * 0.75, -r * 0.75), r * 0.32, str(roll_count), UITheme.SKY, Color.WHITE)
	if queue_depth > 0:
		StickerArt.badge(self, Vector2(r * 0.8, -r * 0.8), r * 0.3, str(queue_depth + 1), UITheme.INK_SOFT, Color.WHITE)


func _tape(r: float, top := false) -> void:
	var dir := glue_dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var a := dir * r * 0.55
	var b := dir * size * 0.62
	var w := r * 0.28
	var pts := PackedVector2Array([a + perp * w, b + perp * w, b - perp * w, a - perp * w])
	if top:
		draw_colored_polygon(pts, Color(1.0, 0.93, 0.7, 0.92))
		for i in 3:
			var t := 0.25 + i * 0.25
			var m := a.lerp(b, t)
			draw_line(m + perp * w, m - perp * w, Color(0.9, 0.75, 0.45, 0.8), 2.0, true)
	else:
		draw_colored_polygon(pts, Color(0.3, 0.1, 0.3, 0.15))


func _bubble_wrap(r: float) -> void:
	draw_circle(Vector2.ZERO, r * 1.05, Color(0.85, 0.95, 1.0, 0.45))
	var spots := [Vector2(-0.45, -0.45), Vector2(0.4, -0.4), Vector2(0, 0.05), Vector2(-0.45, 0.45), Vector2(0.45, 0.45)]
	for s in spots:
		var p: Vector2 = s * r
		draw_circle(p, r * 0.26, Color(1, 1, 1, 0.45))
		draw_arc(p, r * 0.26, 0, TAU, 20, Color(1, 1, 1, 0.9), 2.5, true)
		draw_circle(p + Vector2(-r * 0.08, -r * 0.08), r * 0.07, Color(1, 1, 1, 0.95))


func _ice(r: float) -> void:
	var pts := StickerArt.points("square")
	var scaled := PackedVector2Array()
	for p in pts:
		scaled.append(p * r * 1.12)
	draw_colored_polygon(scaled, Color(0.62, 0.86, 1.0, 0.72))
	draw_line(Vector2(-r * 0.6, -r * 0.2), Vector2(-r * 0.2, -r * 0.6), Color(1, 1, 1, 0.8), 4.0, true)
	draw_line(Vector2(-r * 0.5, r * 0.15), Vector2(r * 0.15, -r * 0.5), Color(1, 1, 1, 0.6), 3.0, true)
	StickerArt.badge(self, Vector2(0, 0), r * 0.42, str(ice), Color("#5bb8f5"), Color.WHITE)


func _padlock(r: float) -> void:
	var body := Rect2(Vector2(-r * 0.5, -r * 0.05), Vector2(r, r * 0.8))
	draw_arc(Vector2(0, -r * 0.05), r * 0.32, PI, TAU, 16, Color("#8a6d1f"), r * 0.14, true)
	var shadow := body
	shadow.position.y += 3
	draw_rect(shadow, Color(0.2, 0.05, 0.2, 0.3))
	draw_rect(body, Color("#f6c445"))
	draw_rect(body, Color("#c79a22"), false, 3.0)
	var info: Dictionary = lock_info
	var key_col := UITheme.sticker_color(int(info.get("color", 0)))
	StickerArt.draw(self, body.get_center(), r * 0.3, String(info.get("shape", "circle")), key_col, {"shadow": false})


func _fuse(r: float) -> void:
	var at := Vector2(r * 0.72, -r * 0.72)
	draw_line(at, at + Vector2(r * 0.2, -r * 0.3), Color("#5a4632"), 4.0, true)
	draw_circle(at + Vector2(r * 0.22, -r * 0.34), r * 0.1, Color("#ffcc33"))
	draw_circle(at + Vector2(r * 0.22, -r * 0.34), r * 0.05, Color("#ff6a00"))
	var bg := UITheme.DANGER if fuse <= 2 else Color("#ff8a3d")
	StickerArt.badge(self, at, r * 0.34, str(fuse), bg, Color.WHITE)
