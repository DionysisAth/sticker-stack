extends TestCase
## Opens the real game screen on level 1 and clears it by tapping.


func test_clear_level_one_in_the_game_screen() -> void:
	Save.reset()
	Save.seen_cards = ["basics"]
	Nav.params = {"level": 1}
	var tree := Engine.get_main_loop() as SceneTree
	var game: Control = load("res://ui/game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	await tree.process_frame
	var level: Dictionary = game.level
	for id in level.solution:
		game._on_sticker_tapped(int(id))
		await tree.process_frame
	eq(game.state.status, BoardState.Status.WON)
	await tree.create_timer(1.6).timeout
	eq(Save.level, 2, "progress saved")
	check(game._card != null, "clear card shown")
	game.queue_free()
	Save.reset()
