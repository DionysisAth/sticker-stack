class_name Picture
extends RefCounted
## The hidden pictures under the pile: one scene per level, taking turns.
## Drawn with shapes in code, so they scale to any sheet size.

const NAMES: Array[String] = [
	"Sunset hills", "Sailing day", "Starry night", "Candy land",
	"Under the sea", "Space trip", "Flower field", "Rainbow sky",
]


static func for_level(level: int) -> int:
	return posmod(level - 1, NAMES.size())


static func name_of(scene: int) -> String:
	return NAMES[posmod(scene, NAMES.size())]


## Draws scene `scene` filling `r`.
static func draw(ci: CanvasItem, r: Rect2, scene: int) -> void:
	match posmod(scene, NAMES.size()):
		0: _sunset(ci, r)
		1: _sailing(ci, r)
		2: _night(ci, r)
		3: _candy(ci, r)
		4: _sea(ci, r)
		5: _space(ci, r)
		6: _flowers(ci, r)
		7: _rainbow(ci, r)


# --- Scenes ----------------------------------------------------------------

static func _sunset(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#ff9a8b"), Color("#ffd6a5"))
	var sun := _at(r, 0.5, 0.48)
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_line(sun + Vector2(cos(a), sin(a)) * r.size.x * 0.17, sun + Vector2(cos(a), sin(a)) * r.size.x * 0.25, Color(1, 0.95, 0.6, 0.8), r.size.x * 0.02, true)
	ci.draw_circle(sun, r.size.x * 0.14, Color("#ffe066"))
	_cloud(ci, _at(r, 0.2, 0.2), r.size.x * 0.09, Color(1, 1, 1, 0.9))
	_cloud(ci, _at(r, 0.78, 0.28), r.size.x * 0.07, Color(1, 1, 1, 0.85))
	_hills(ci, r, 0.55, 0.07, 1.5, 0.3, Color("#f08a5d"))
	_hills(ci, r, 0.68, 0.06, 2.2, 1.7, Color("#b83b5e"))
	_hills(ci, r, 0.82, 0.05, 1.8, 3.1, Color("#6a2c70"))


static func _sailing(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#8ecdf7"), Color("#e0f4ff"))
	ci.draw_circle(_at(r, 0.8, 0.18), r.size.x * 0.08, Color("#fff3a3"))
	_cloud(ci, _at(r, 0.25, 0.18), r.size.x * 0.08, Color.WHITE)
	var sea := Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45))
	_gradient(ci, sea, Color("#3a86ff"), Color("#1d3557"))
	# Boat.
	var b := _at(r, 0.45, 0.55)
	var w := r.size.x * 0.22
	ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-w, -w * 0.05), b + Vector2(w, -w * 0.05), b + Vector2(w * 0.7, w * 0.25), b + Vector2(-w * 0.7, w * 0.25)]), Color("#a0522d"))
	ci.draw_line(b + Vector2(0, -w * 0.05), b + Vector2(0, -w * 1.3), Color("#5a3a1a"), w * 0.05)
	ci.draw_colored_polygon(PackedVector2Array([b + Vector2(w * 0.04, -w * 1.25), b + Vector2(w * 0.75, -w * 0.15), b + Vector2(w * 0.04, -w * 0.15)]), Color.WHITE)
	ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-w * 0.04, -w * 1.0), b + Vector2(-w * 0.55, -w * 0.15), b + Vector2(-w * 0.04, -w * 0.15)]), Color("#ff5a5f"))
	for k in 3:
		_waves(ci, r, 0.62 + k * 0.12, r.size.y * 0.025, Color(1, 1, 1, 0.5 - k * 0.12), k * 1.3)


static func _night(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#14213d"), Color("#3d2c6e"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 60:
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.7)
		ci.draw_circle(p, rng.randf_range(1.0, 3.2), Color(1, 1, 0.85, rng.randf_range(0.5, 1.0)))
	var m := _at(r, 0.72, 0.22)
	ci.draw_circle(m, r.size.x * 0.11, Color("#fff3c4"))
	ci.draw_circle(m + Vector2(r.size.x * 0.05, -r.size.x * 0.03), r.size.x * 0.1, Color("#1c2547"))
	_mountains(ci, r, 0.62, Color("#2b2d5c"), 4)
	_mountains(ci, r, 0.75, Color("#1b1b3a"), 6)


static func _candy(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#ffc2e2"), Color("#fff0f6"))
	_cloud(ci, _at(r, 0.3, 0.16), r.size.x * 0.08, Color.WHITE)
	_cloud(ci, _at(r, 0.75, 0.1), r.size.x * 0.06, Color.WHITE)
	_hills(ci, r, 0.7, 0.07, 1.6, 0.5, Color("#ff9ecd"))
	_hills(ci, r, 0.82, 0.05, 2.4, 2.0, Color("#c77dff"))
	var spots := [[0.22, 0.48, "#ff5a5f"], [0.5, 0.38, "#3bb273"], [0.78, 0.5, "#3a86ff"]]
	for sp in spots:
		var c := _at(r, sp[0], sp[1])
		var rad := r.size.x * 0.1
		ci.draw_line(c, c + Vector2(0, r.size.y * 0.35), Color.WHITE, rad * 0.18)
		ci.draw_circle(c, rad, Color(sp[2]))
		for k in 3:
			ci.draw_arc(c, rad * (0.3 + k * 0.22), 0, TAU * 0.8, 24, Color(1, 1, 1, 0.75), rad * 0.08, true)


static func _sea(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#48cae4"), Color("#023e8a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 22:
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		var rad := rng.randf_range(3, 10)
		ci.draw_arc(p, rad, 0, TAU, 16, Color(1, 1, 1, 0.55), 2.0, true)
	var fish := [[0.25, 0.3, "#ffd23f", 1.0], [0.7, 0.45, "#ff70a6", -1.0], [0.4, 0.62, "#ff9f1c", 1.0]]
	for f in fish:
		_fish(ci, _at(r, f[0], f[1]), r.size.x * 0.1, Color(f[2]), f[3])
	for i in 6:
		var x := r.position.x + r.size.x * (0.08 + i * 0.17)
		var pts := PackedVector2Array()
		for k in 12:
			pts.append(Vector2(x + sin(k * 0.9 + i) * 8.0, r.end.y - k * r.size.y * 0.025))
		ci.draw_polyline(pts, Color("#2a9d8f"), 7.0, true)
	ci.draw_rect(Rect2(Vector2(r.position.x, r.end.y - r.size.y * 0.06), Vector2(r.size.x, r.size.y * 0.06)), Color("#f4d58d"))


static func _space(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#10002b"), Color("#3c096c"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 70:
		ci.draw_circle(r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y), rng.randf_range(0.8, 2.6), Color(1, 1, 1, rng.randf_range(0.4, 1)))
	var p := _at(r, 0.3, 0.35)
	ci.draw_circle(p, r.size.x * 0.13, Color("#ff9f1c"))
	ci.draw_circle(p + Vector2(-r.size.x * 0.03, -r.size.x * 0.03), r.size.x * 0.05, Color(1, 1, 1, 0.25))
	_ring(ci, p, r.size.x * 0.22, r.size.x * 0.05, Color("#ffd23f"))
	ci.draw_circle(_at(r, 0.78, 0.2), r.size.x * 0.06, Color("#2ec4b6"))
	# Rocket.
	var k := _at(r, 0.68, 0.66)
	var s := r.size.x * 0.09
	ci.draw_colored_polygon(PackedVector2Array([k + Vector2(0, -s * 1.6), k + Vector2(s * 0.5, -s * 0.6), k + Vector2(s * 0.5, s * 0.7), k + Vector2(-s * 0.5, s * 0.7), k + Vector2(-s * 0.5, -s * 0.6)]), Color.WHITE)
	ci.draw_circle(k + Vector2(0, -s * 0.4), s * 0.25, Color("#3a86ff"))
	ci.draw_colored_polygon(PackedVector2Array([k + Vector2(-s * 0.5, s * 0.1), k + Vector2(-s * 0.9, s * 0.9), k + Vector2(-s * 0.5, s * 0.7)]), Color("#ff5a5f"))
	ci.draw_colored_polygon(PackedVector2Array([k + Vector2(s * 0.5, s * 0.1), k + Vector2(s * 0.9, s * 0.9), k + Vector2(s * 0.5, s * 0.7)]), Color("#ff5a5f"))
	ci.draw_colored_polygon(PackedVector2Array([k + Vector2(-s * 0.3, s * 0.7), k + Vector2(0, s * 1.6), k + Vector2(s * 0.3, s * 0.7)]), Color("#ffd23f"))


static func _flowers(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#a2d2ff"), Color("#e7f6ff"))
	ci.draw_circle(_at(r, 0.15, 0.15), r.size.x * 0.07, Color("#ffe066"))
	_hills(ci, r, 0.5, 0.05, 1.2, 0.8, Color("#80ed99"))
	var field := Rect2(r.position + Vector2(0, r.size.y * 0.58), Vector2(r.size.x, r.size.y * 0.42))
	_gradient(ci, field, Color("#57cc99"), Color("#38a3a5"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var cols := ["#ff5a5f", "#ffd23f", "#ff70a6", "#8338ec", "#ffffff"]
	for i in 26:
		var p := r.position + Vector2(rng.randf() * r.size.x, r.size.y * rng.randf_range(0.45, 0.95))
		var rad := r.size.x * rng.randf_range(0.025, 0.05)
		var pts := StickerArt.points("flower")
		var poly := PackedVector2Array()
		for q in pts:
			poly.append(p + q * rad)
		ci.draw_colored_polygon(poly, Color(cols[i % cols.size()]))
		ci.draw_circle(p, rad * 0.3, Color("#ffb703"))


static func _rainbow(ci: CanvasItem, r: Rect2) -> void:
	_gradient(ci, r, Color("#bde0fe"), Color("#ffffff"))
	var c := _at(r, 0.5, 0.85)
	var band := r.size.x * 0.055
	var cols := ["#ff5a5f", "#ff9f1c", "#ffd23f", "#3bb273", "#3a86ff", "#8338ec"]
	for i in cols.size():
		ci.draw_arc(c, r.size.x * 0.5 - i * band, PI, TAU, 64, Color(cols[i]), band + 1.0, true)
	_cloud(ci, _at(r, 0.12, 0.82), r.size.x * 0.1, Color.WHITE)
	_cloud(ci, _at(r, 0.88, 0.82), r.size.x * 0.1, Color.WHITE)
	ci.draw_circle(_at(r, 0.85, 0.15), r.size.x * 0.06, Color("#ffe066"))


# --- Pieces ----------------------------------------------------------------

static func _at(r: Rect2, fx: float, fy: float) -> Vector2:
	return r.position + Vector2(r.size.x * fx, r.size.y * fy)


static func _gradient(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


static func _hills(ci: CanvasItem, r: Rect2, base: float, amp: float, freq: float, phase: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 40
	for i in n + 1:
		var x := r.position.x + r.size.x * i / n
		var y := r.position.y + r.size.y * (base - amp * sin(freq * TAU * i / n + phase))
		pts.append(Vector2(x, y))
	pts.append(r.end)
	pts.append(Vector2(r.position.x, r.end.y))
	ci.draw_colored_polygon(pts, col)


static func _mountains(ci: CanvasItem, r: Rect2, base: float, col: Color, peaks: int) -> void:
	var pts := PackedVector2Array()
	for i in peaks * 2 + 1:
		var x := r.position.x + r.size.x * i / (peaks * 2.0)
		var y := r.position.y + r.size.y * (base - (0.12 if i % 2 == 1 else 0.0) - 0.03 * sin(i * 1.7))
		pts.append(Vector2(x, y))
	pts.append(r.end)
	pts.append(Vector2(r.position.x, r.end.y))
	ci.draw_colored_polygon(pts, col)


static func _waves(ci: CanvasItem, r: Rect2, at: float, amp: float, col: Color, phase: float) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		pts.append(Vector2(r.position.x + r.size.x * i / 40.0, r.position.y + r.size.y * at + sin(i * 0.8 + phase) * amp))
	ci.draw_polyline(pts, col, 4.0, true)


static func _cloud(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c, s, col)
	ci.draw_circle(c + Vector2(-s * 0.9, s * 0.3), s * 0.7, col)
	ci.draw_circle(c + Vector2(s * 0.9, s * 0.3), s * 0.75, col)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.9, 0), Vector2(s * 1.8, s * 1.0)), col)


static func _fish(ci: CanvasItem, c: Vector2, s: float, col: Color, dir: float) -> void:
	var body := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		body.append(c + Vector2(cos(a) * s, sin(a) * s * 0.55))
	ci.draw_colored_polygon(body, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-dir * s * 0.85, 0), c + Vector2(-dir * s * 1.5, -s * 0.5), c + Vector2(-dir * s * 1.5, s * 0.5)]), col)
	ci.draw_circle(c + Vector2(dir * s * 0.5, -s * 0.1), s * 0.12, Color.WHITE)
	ci.draw_circle(c + Vector2(dir * s * 0.53, -s * 0.1), s * 0.06, Color("#1d3557"))


static func _ring(ci: CanvasItem, c: Vector2, w: float, h: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * w, sin(a) * h).rotated(-0.3))
	ci.draw_polyline(pts, col, h * 0.35, true)
