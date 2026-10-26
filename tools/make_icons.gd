extends SceneTree
## Renders the app icons from assets/icon.svg:
##   icon_192.png (Android), icon_432.png + icon_432_bg.png (Android adaptive
##   foreground/background), icon_512.png (Play listing), icon_1024.png (App Store).
## godot --headless --path . --script res://tools/make_icons.gd


func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/icon.svg")
	var rect_start := svg.find("<rect")
	var rect_end := svg.find("/>", rect_start) + 2
	var rect := svg.substr(rect_start, rect_end - rect_start)
	var head := svg.substr(0, rect_start)
	var groups := svg.substr(rect_end, svg.rfind("</svg>") - rect_end)
	# Adaptive icons: the background fills the square, the stickers sit in the
	# middle 66% safe zone.
	var bg := head + rect.replace(" rx=\"112\"", "") + "</svg>"
	var fg := head + "<g transform=\"translate(256 256) scale(0.62) translate(-256 -256)\">" + groups + "</g></svg>"
	_save(svg, 192, "icon_192.png")
	_save(svg, 512, "icon_512.png")
	_save(svg.replace(" rx=\"112\"", ""), 1024, "icon_1024.png")
	_save(fg, 432, "icon_432.png")
	_save(bg, 432, "icon_432_bg.png")
	quit()


func _save(svg: String, px: int, name: String) -> void:
	var img := Image.new()
	var err := img.load_svg_from_string(svg, px / 512.0)
	if err != OK:
		push_error("Could not render %s" % name)
		return
	img.save_png("res://assets/" + name)
	print("wrote assets/", name, " ", img.get_size())
