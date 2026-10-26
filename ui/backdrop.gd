class_name Backdrop
extends RefCounted
## Gradient backdrops behind every screen.


static func make(level: int) -> TextureRect:
	var r := TextureRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cols := UITheme.backdrop(level)
	var g := Gradient.new()
	g.colors = PackedColorArray([cols[0], cols[1]])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	r.texture = tex
	return r
