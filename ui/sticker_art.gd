class_name StickerArt
extends RefCounted
## Draws die-cut stickers: a coloured shape with a thick white border, a soft
## shadow and a little gloss. Shapes are built once at radius 1 and scaled.

static var _cache := {}


static func points(shape: String) -> PackedVector2Array:
	if _cache.has(shape):
		return _cache[shape]
	var pts := PackedVector2Array()
	match shape:
		"circle":
			pts = _polar(48, func(_a): return 0.92)
		"square":
			pts = _rounded_rect(0.82, 0.82, 0.24)
		"triangle":
			pts = _round_poly([Vector2(0, -0.98), Vector2(0.98, 0.74), Vector2(-0.98, 0.74)], 0.16)
		"star":
			var raw := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				var rr := 1.0 if i % 2 == 0 else 0.5
				raw.append(Vector2(cos(a), sin(a)) * rr + Vector2(0, 0.06))
			pts = _round_poly(raw, 0.07)
		"heart":
			for i in 56:
				var t := TAU * i / 56.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(Vector2(x, y + 2.5) / 16.5)
		"diamond":
			pts = _round_poly([Vector2(0, -1), Vector2(0.78, 0), Vector2(0, 1), Vector2(-0.78, 0)], 0.12)
		"hexagon":
			var raw := PackedVector2Array()
			for i in 6:
				var a := PI / 6 + i * TAU / 6
				raw.append(Vector2(cos(a), sin(a)) * 0.98)
			pts = _round_poly(raw, 0.14)
		"moon":
			var n := 32
			for i in n + 1:
				var t := -PI / 2 + PI * i / n
				pts.append(Vector2(-cos(t) * 0.95, sin(t) * 0.95))
			for i in range(n - 1, 0, -1):
				var t := -PI / 2 + PI * i / n
				pts.append(Vector2(-cos(t) * 0.28, sin(t) * 0.82))
			for i in pts.size():
				pts[i] = pts[i].rotated(-0.35) + Vector2(0.22, 0)
		"flower":
			pts = _polar(60, func(a): return 0.62 + 0.36 * absf(cos(2.5 * a)))
		"drop":
			for i in 48:
				var t := TAU * i / 48.0
				pts.append(Vector2(1.15 * sin(t) * sin(t / 2.0), -cos(t)) * 0.95 + Vector2(0, 0.02))
		"cloud":
			pts = _polar(64, func(a): return 0.8 + 0.17 * absf(sin(3.0 * a + 0.5)))
			for i in pts.size():
				pts[i] = Vector2(pts[i].x * 1.08, minf(pts[i].y, 0.62))
		"bolt":
			pts = _round_poly([
				Vector2(0.22, -1.0), Vector2(-0.62, 0.12), Vector2(-0.06, 0.12),
				Vector2(-0.28, 1.0), Vector2(0.64, -0.16), Vector2(0.08, -0.16),
			], 0.05)
		_:
			pts = _polar(48, func(_a): return 0.92)
	_cache[shape] = pts
	return pts


## Draws one sticker centred at `c` with radius `r`.
## opts: rainbow, hidden, mark (colour-blind label), shadow (default true).
static func draw(ci: CanvasItem, c: Vector2, r: float, shape: String, color: Color, opts := {}) -> void:
	var hidden: bool = opts.get("hidden", false)
	var rainbow: bool = opts.get("rainbow", false)
	if hidden:
		shape = "square"
	elif rainbow:
		shape = "star"
	var unit := points(shape)
	var pts := PackedVector2Array()
	pts.resize(unit.size())
	for i in unit.size():
		pts[i] = c + unit[i] * r
	var border := r * 0.16
	if opts.get("shadow", true):
		var sh := Color(0.25, 0.05, 0.3, 0.22)
		var off := Vector2(0, r * 0.1)
		var spts := _offset(pts, off)
		ci.draw_colored_polygon(spts, sh)
		ci.draw_polyline(_closed(spts), sh, border * 2.0, true)
	# White die-cut border.
	ci.draw_colored_polygon(pts, Color.WHITE)
	ci.draw_polyline(_closed(pts), Color.WHITE, border * 2.0, true)
	# Body.
	if rainbow:
		var cols := PackedColorArray()
		for p in pts:
			var a := (p - c).angle()
			cols.append(Color.from_hsv(fposmod(a / TAU, 1.0), 0.75, 1.0))
		ci.draw_polygon(pts, cols)
	elif hidden:
		ci.draw_colored_polygon(pts, Color("#b9b0c9"))
		ci.draw_polyline(_closed(pts), Color("#a69cb8"), 2.0, true)
		_text(ci, c + Vector2(0, r * 0.36), "?", int(r * 1.15), Color.WHITE)
		return
	else:
		ci.draw_colored_polygon(pts, color)
		ci.draw_polyline(_closed(pts), color.darkened(0.12), maxf(1.5, r * 0.05), true)
	# Gloss.
	var gloss := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		gloss.append(c + Vector2(-0.3 * r, -0.4 * r) + Vector2(cos(a) * 0.26 * r, sin(a) * 0.13 * r).rotated(-0.5))
	ci.draw_colored_polygon(gloss, Color(1, 1, 1, 0.38))
	var mark: String = opts.get("mark", "")
	if mark != "" and not rainbow:
		badge(ci, c + Vector2(r * 0.62, r * 0.62), r * 0.36, mark, Color.WHITE, UITheme.INK)


## A round badge with text (counts, colour-blind labels).
static func badge(ci: CanvasItem, at: Vector2, radius: float, text: String, bg: Color, fg: Color) -> void:
	ci.draw_circle(at + Vector2(0, radius * 0.12), radius + 3, Color(0.2, 0.05, 0.25, 0.25))
	ci.draw_circle(at, radius + 3, Color.WHITE)
	ci.draw_circle(at, radius, bg)
	var size := int(radius * (1.25 if text.length() <= 1 else 0.95))
	_text(ci, at + Vector2(0, size * 0.36), text, size, fg)


static func _text(ci: CanvasItem, baseline_center: Vector2, text: String, size: int, color: Color) -> void:
	if size <= 0:
		return
	var font := UITheme.font_bold()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, baseline_center - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func text(ci: CanvasItem, baseline_center: Vector2, t: String, size: int, color: Color) -> void:
	_text(ci, baseline_center, t, size, color)


static func _polar(n: int, radius_at: Callable) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n - PI / 2
		out.append(Vector2(cos(a), sin(a)) * float(radius_at.call(a + PI / 2)))
	return out


static func _rounded_rect(hw: float, hh: float, rad: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var corners := [Vector2(hw - rad, -hh + rad), Vector2(hw - rad, hh - rad), Vector2(-hw + rad, hh - rad), Vector2(-hw + rad, -hh + rad)]
	var start := [-PI / 2, 0.0, PI / 2, PI]
	for k in 4:
		for i in 7:
			var a: float = start[k] + (PI / 2) * i / 6.0
			out.append(corners[k] + Vector2(cos(a), sin(a)) * rad)
	return out


## Rounds a polygon's corners a little so stickers look die-cut, not sharp.
static func _round_poly(raw: PackedVector2Array, rad: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := raw.size()
	for i in n:
		var prev := raw[(i - 1 + n) % n]
		var cur := raw[i]
		var next := raw[(i + 1) % n]
		var a := cur + (prev - cur).normalized() * minf(rad, (prev - cur).length() * 0.4)
		var b := cur + (next - cur).normalized() * minf(rad, (next - cur).length() * 0.4)
		for s in 5:
			var t := s / 4.0
			out.append(a.lerp(cur, t).lerp(cur.lerp(b, t), t))
	return out


static func _offset(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] + off
	return out


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
