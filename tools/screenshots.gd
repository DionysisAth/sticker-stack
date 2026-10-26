extends Node
## Captures phone screenshots of the real screens (for checking the look and
## as a starting point for store screenshots). Needs a display, e.g.:
##   xvfb-run -s "-screen 0 1280x1400x24" godot --path . --resolution 720x1280 res://tools/screenshots.tscn
## Writes PNGs to build/screenshots/.

const OUT := "res://build/screenshots/"


func _ready() -> void:
	Analytics.enabled = false
	Save.path = "user://screenshot_save.json"
	Save.reset()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_tree().root.theme = UITheme.get_theme()
	await _shots()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))
	get_tree().quit()


func _shots() -> void:
	# Home.
	Save.level = 12
	await _open("res://ui/home.tscn", "01_home")
	# Level 1 tutorial card.
	Save.level = 1
	Nav.params = {"level": 1}
	var g := await _open_game(1)
	await _snap("02_tutorial_card")
	g._close_card()
	await _wait(0.5)
	await _snap("03_level_1_hint")
	_free(g)
	# A mid-game moment on a few levels, with stickers in the tray.
	for n in [12, 21, 37, 41, 47]:
		Save.seen_cards = ["roll", "mystery", "glue", "padlock", "ice", "wrap", "dispenser", "rainbow", "fuse"]
		g = await _open_game(n)
		if g._card != null:
			g._close_card()
			await _wait(0.3)
		var taps: Array = g.level.solution
		for i in mini(taps.size(), 4 + n % 3):
			g._on_sticker_tapped(int(taps[i]))
			await _wait(0.08)
		await _wait(0.6)
		await _snap("04_level_%d" % n)
		_free(g)
	# Clear card.
	g = await _open_game(9)
	for id in g.level.solution:
		g._on_sticker_tapped(int(id))
		await get_tree().process_frame
	await _wait(1.7)
	await _snap("05_clear_card")
	_free(g)
	# Fail card: fill the tray with singles.
	g = await _open_game(30)
	if g._card != null:
		g._close_card()
		await _wait(0.3)
	var guard := 0
	while g.state.status == BoardState.Status.PLAYING and guard < 60:
		guard += 1
		var pick := -1
		for id in g.state.tappable():
			if g.state.tray.count_of(g.state.stickers[id].type) == 0:
				pick = id
				break
		if pick < 0:
			pick = g.state.tappable()[0]
		g._on_sticker_tapped(pick)
		await _wait(0.05)
	await _wait(1.2)
	await _snap("06_fail_card")
	_free(g)
	Save.level = 12
	await _open("res://ui/settings.tscn", "07_settings")


func _open_game(n: int) -> Control:
	Save.level = n
	Nav.params = {"level": n}
	var g: Control = load("res://ui/game.tscn").instantiate()
	add_child(g)
	await _wait(0.9)
	return g


func _open(path: String, name: String) -> void:
	var s: Control = load(path).instantiate()
	add_child(s)
	await _wait(0.8)
	await _snap(name)
	_free(s)


func _free(n: Node) -> void:
	remove_child(n)
	n.queue_free()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("saved ", name)
