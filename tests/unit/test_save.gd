extends TestCase


func test_progress_and_rewards() -> void:
	Save.reset()
	eq(Save.level, 1)
	var rewards := []
	for i in 10:
		var r := Save.complete_level()
		if r != "":
			rewards.append(r)
	eq(Save.level, 11)
	eq(rewards, ["undo", "return3"], "+1 booster every 5 clears, taking turns")
	eq(Save.boosters.undo, Save.START_STOCK.undo + 1)


func test_persists() -> void:
	Save.reset()
	Save.complete_level()
	Save.spend_booster("shuffle")
	Save.set_setting("colorblind", true)
	Save.level = 0
	Save.load_game()
	eq(Save.level, 2)
	eq(Save.boosters.shuffle, Save.START_STOCK.shuffle - 1)
	check(Save.setting("colorblind"))
	Save.reset()
	Save.set_setting("colorblind", false)


func test_no_booster_left() -> void:
	Save.reset()
	Save.boosters.undo = 0
	check(not Save.spend_booster("undo"))
	Save.reset()
