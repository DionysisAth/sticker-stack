class_name RewardJar
extends Control
## The booster jar: one candy segment per clear. When the last segment goes
## in, the lid pops and `opened` fires (the game shows the booster).

signal opened

const SEGMENT_COLORS: Array[Color] = [
	Color("#ff70a6"), Color("#ffd23f"), Color("#3bb273"), Color("#3a86ff"), Color("#8338ec"),
]

var segments := Save.JAR_SIZE
var fill := 0.0
var _lid_lift := 0.0
var _shake := 0.0


static func make(start_fill: int, diameter := 120.0) -> RewardJar:
	var j := RewardJar.new()
	j.fill = start_fill
	j.custom_minimum_size = Vector2(diameter, diameter * 1.15)
	j.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return j


## Fills up to `to` segments; pops the lid if that fills the jar.
func animate_to(to: int, delay := 0.35) -> void:
	var instant: bool = Save.setting("reduce_motion")
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_method(_set_fill, fill, float(to), 0.1 if instant else 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: Audio.play("pop", 1.0 + 0.1 * to, -6.0))
	if to >= segments:
		if not instant:
			t.tween_method(_set_shake, 0.0, 1.0, 0.35)
		t.tween_method(_set_lid, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(opened.emit)


func _set_fill(v: float) -> void:
	fill = v
	queue_redraw()


func _set_lid(v: float) -> void:
	_lid_lift = v
	queue_redraw()


func _set_shake(v: float) -> void:
	_shake = v
	queue_redraw()


func _draw() -> void:
	var w := size.x * 0.72
	var h := size.y * 0.7
	var wobble := sin(_shake * TAU * 4.0) * 0.08 * (1.0 - _shake)
	draw_set_transform(size / 2.0, wobble, Vector2.ONE)
	var body := Rect2(Vector2(-w / 2.0, -h / 2.0 + size.y * 0.08), Vector2(w, h))
	# Glass.
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(1, 1, 1, 0.55)
	glass.border_color = Color.WHITE
	glass.set_border_width_all(5)
	glass.set_corner_radius_all(int(w * 0.22))
	glass.shadow_color = Color(0.25, 0.05, 0.3, 0.2)
	glass.shadow_size = 6
	glass.shadow_offset = Vector2(0, 4)
	draw_style_box(glass, body)
	# Candy segments, bottom up.
	var inner := body.grow(-9)
	var seg_h := inner.size.y / segments
	for i in segments:
		var amount := clampf(fill - i, 0.0, 1.0)
		if amount <= 0.0:
			break
		var r := Rect2(Vector2(inner.position.x, inner.end.y - seg_h * (i + amount)), Vector2(inner.size.x, seg_h * amount - 2))
		var seg := StyleBoxFlat.new()
		seg.bg_color = SEGMENT_COLORS[i % SEGMENT_COLORS.size()]
		seg.set_corner_radius_all(int(minf(seg_h, inner.size.x) * 0.3))
		draw_style_box(seg, r)
		draw_rect(Rect2(r.position + Vector2(6, 3), Vector2(r.size.x * 0.3, maxf(2.0, r.size.y * 0.25))), Color(1, 1, 1, 0.35))
	# Glass shine.
	draw_rect(Rect2(body.position + Vector2(w * 0.12, h * 0.12), Vector2(w * 0.08, h * 0.55)), Color(1, 1, 1, 0.45))
	# Lid: pops up and tilts when the jar opens.
	var lid_off := Vector2(w * 0.25, -size.y * 0.25) * _lid_lift
	draw_set_transform(size / 2.0 + lid_off, wobble - 0.6 * _lid_lift, Vector2.ONE)
	var lid := Rect2(Vector2(-w * 0.42, -h / 2.0 + size.y * 0.08 - 16), Vector2(w * 0.84, 18))
	var lid_box := StyleBoxFlat.new()
	lid_box.bg_color = UITheme.ACCENT
	lid_box.border_color = UITheme.ACCENT_DARK
	lid_box.border_width_bottom = 5
	lid_box.set_corner_radius_all(9)
	draw_style_box(lid_box, lid)
	draw_set_transform(Vector2.ZERO)
