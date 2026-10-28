class_name Fx
extends RefCounted
## Small effects: confetti bursts and floating text.

static var _dot: Texture2D


static func dot_texture() -> Texture2D:
	if _dot == null:
		var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_dot = ImageTexture.create_from_image(img)
	return _dot


## A one-shot confetti burst at a position in `parent`.
static func confetti(parent: Node, at: Vector2, colors: Array, amount := 26, spread := 1.0) -> void:
	if Save.setting("reduce_motion"):
		amount = int(amount / 3)
	var p := CPUParticles2D.new()
	p.texture = dot_texture()
	p.position = at
	p.amount = maxi(amount, 4)
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 260.0 * spread
	p.initial_velocity_max = 620.0 * spread
	p.gravity = Vector2(0, 1300)
	p.angular_velocity_min = -720
	p.angular_velocity_max = 720
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	p.damping_min = 40
	p.damping_max = 120
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.75, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	p.color_ramp = grad
	if colors.size() > 0:
		var cg := Gradient.new()
		var offs := PackedFloat32Array()
		var cols := PackedColorArray()
		for i in colors.size():
			offs.append(float(i) / maxf(1.0, colors.size() - 1))
			cols.append(colors[i])
		cg.offsets = offs
		cg.colors = cols
		cg.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		p.color_initial_ramp = cg
	p.z_index = 500
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## An expanding ring (the shockwave of a triple).
static func ring(parent: Node, at: Vector2, color: Color, radius := 120.0) -> void:
	if Save.setting("reduce_motion"):
		return
	var r := RingFx.new()
	r.position = at
	r.color = color
	r.z_index = 450
	parent.add_child(r)
	var t := r.create_tween()
	t.tween_property(r, "radius", radius, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(r, "modulate:a", 0.0, 0.35)
	t.tween_callback(r.queue_free)


## Text that floats up and fades (tips like "Locked!").
static func float_text(parent: Node, at: Vector2, text: String, color := UITheme.INK, size := 30) -> void:
	var l := UITheme.label(text, size, color, true)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 10)
	l.custom_minimum_size = Vector2(420, 50)
	l.size = Vector2(420, 50)
	l.position = at - Vector2(210, 25)
	l.z_index = 600
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 70, 1.1).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.5)
	t.tween_callback(l.queue_free)
