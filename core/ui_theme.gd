class_name UITheme
extends RefCounted
## Colours, fonts and the Control theme: bright and candy-coloured, round
## Fredoka font, chunky raised buttons.

const STICKER_COLORS: Array[Color] = [
	Color("#ff5a5f"),  # red
	Color("#ff9f1c"),  # orange
	Color("#ffd23f"),  # yellow
	Color("#3bb273"),  # green
	Color("#2ec4b6"),  # teal
	Color("#3a86ff"),  # blue
	Color("#8338ec"),  # purple
	Color("#ff70a6"),  # pink
	Color("#a0522d"),  # brown
	Color("#1d3557"),  # navy
]
## Colour-blind mode marks each colour with a short label.
const COLOR_MARKS: Array[String] = ["Re", "Or", "Ye", "Gr", "Te", "Bl", "Pu", "Pi", "Br", "Na"]

const INK := Color("#3d2c4e")
const INK_SOFT := Color("#7a6a8a")
const PAPER := Color("#fffaf3")
const ACCENT := Color("#ff5a8a")
const ACCENT_DARK := Color("#d63b6c")
const GO := Color("#3bb273")
const GO_DARK := Color("#2a8a57")
const DANGER := Color("#ff3b3b")
const SKY := Color("#3a86ff")
const SKY_DARK := Color("#2766cc")

## Backdrop gradients (top, bottom); levels take turns.
const BACKDROPS: Array = [
	[Color("#ffc2d6"), Color("#ffe3c2")],
	[Color("#c2e8ff"), Color("#e6d4ff")],
	[Color("#c9f7d8"), Color("#fff2b8")],
	[Color("#ffd8b8"), Color("#ffc2e2")],
	[Color("#d6d0ff"), Color("#c7f2f0")],
]

static var _font_bold: Font
static var _font_semi: Font


static func font_bold() -> Font:
	if _font_bold == null:
		_font_bold = load("res://assets/fonts/Fredoka-Bold.woff2")
	return _font_bold


static func font_semi() -> Font:
	if _font_semi == null:
		_font_semi = load("res://assets/fonts/Fredoka-SemiBold.woff2")
	return _font_semi


static func sticker_color(index: int) -> Color:
	return STICKER_COLORS[posmod(index, STICKER_COLORS.size())]


static func backdrop(level: int) -> Array:
	return BACKDROPS[posmod(level - 1, BACKDROPS.size())]


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font_semi()
	t.default_font_size = 30
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.7))
	t.set_font("font", "Button", font_bold())
	t.set_font_size("font_size", "Button", 34)
	t.set_constant("h_separation", "Button", 12)
	t.set_stylebox("normal", "Button", button_box(ACCENT, ACCENT_DARK))
	t.set_stylebox("hover", "Button", button_box(ACCENT.lightened(0.06), ACCENT_DARK))
	t.set_stylebox("pressed", "Button", button_box(ACCENT_DARK, ACCENT_DARK, true))
	t.set_stylebox("disabled", "Button", button_box(Color("#c9bfd4"), Color("#a89cb6")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", card_box())
	t.set_stylebox("panel", "Panel", card_box())
	# Check buttons for settings.
	t.set_font("font", "CheckButton", font_semi())
	t.set_font_size("font_size", "CheckButton", 32)
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_color("font_hover_pressed_color", "CheckButton", INK)
	t.set_color("font_focus_color", "CheckButton", INK)
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(s, "CheckButton", StyleBoxEmpty.new())
	t.set_icon("checked", "CheckButton", toggle_icon(true))
	t.set_icon("unchecked", "CheckButton", toggle_icon(false))
	# Progress bar for "new trick in N levels".
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#efe4f5")
	bg.set_corner_radius_all(14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GO
	fill.set_corner_radius_all(14)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_font_size("font_size", "ProgressBar", 1)
	t.set_color("font_color", "ProgressBar", Color(0, 0, 0, 0))
	return t


## A chunky raised button: a darker lip under a rounded face.
static func button_box(face: Color, lip: Color, pressed := false) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = face
	b.border_color = lip
	b.set_corner_radius_all(30)
	b.border_width_bottom = 2 if pressed else 9
	b.content_margin_left = 34
	b.content_margin_right = 34
	b.content_margin_top = 18 + (7 if pressed else 0)
	b.content_margin_bottom = 18
	b.shadow_color = Color(0.24, 0.1, 0.3, 0.18)
	b.shadow_size = 6
	b.shadow_offset = Vector2(0, 4)
	b.anti_aliasing = true
	return b


static func card_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = PAPER
	b.set_corner_radius_all(36)
	b.content_margin_left = 36
	b.content_margin_right = 36
	b.content_margin_top = 32
	b.content_margin_bottom = 32
	b.shadow_color = Color(0.24, 0.1, 0.3, 0.25)
	b.shadow_size = 18
	b.shadow_offset = Vector2(0, 8)
	b.border_color = Color.WHITE
	b.set_border_width_all(6)
	return b


static func style_button(btn: Button, face: Color, lip: Color) -> void:
	btn.add_theme_stylebox_override("normal", button_box(face, lip))
	btn.add_theme_stylebox_override("hover", button_box(face.lightened(0.06), lip))
	btn.add_theme_stylebox_override("pressed", button_box(lip, lip, true))


static func toggle_icon(on: bool) -> ImageTexture:
	var w := 96
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var track := GO if on else Color("#cfc4da")
	for y in h:
		for x in w:
			var cx := clampf(x, h / 2.0, w - h / 2.0)
			if Vector2(x, y).distance_to(Vector2(cx, h / 2.0)) <= h / 2.0 - 1:
				img.set_pixel(x, y, track)
	var knob := Vector2(w - h / 2.0 if on else h / 2.0, h / 2.0)
	for y in h:
		for x in w:
			if Vector2(x, y).distance_to(knob) <= h / 2.0 - 6:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


static func label(text: String, size := 30, color := INK, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Only sentences wrap; short labels keep their natural width.
	if text.length() > 22:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, face := ACCENT, lip := ACCENT_DARK, size := 34) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(0, 96)
	style_button(b, face, lip)
	b.pressed.connect(func(): Audio.play("click"))
	return b
