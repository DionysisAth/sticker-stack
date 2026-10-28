extends TestCase


func test_jar_gives_a_booster_every_5_clears() -> void:
	Save.reset()
	var rewards := []
	var fills := []
	for i in 10:
		var r := Save.complete_level()
		fills.append(r.jar)
		if r.jar_reward != "":
			rewards.append(r.jar_reward)
	eq(Save.level, 11)
	eq(fills, [1, 2, 3, 4, 5, 1, 2, 3, 4, 5])
	eq(rewards, ["undo", "return3"], "taking turns")
	eq(Save.jar_fill(), 0)


func test_first_try_streak() -> void:
	Save.reset()
	var got := []
	for i in 5:
		Save.start_attempt()
		var r := Save.complete_level()
		got.append(r.streak)
		if i == 2:
			eq(r.streak_reward, "undo", "a streak of 3 earns Undo")
	eq(got, [1, 2, 3, 4, 5])
	eq(Save.boosters.undo, Save.START_STOCK.undo + 2, "streak of 3 and the first full jar")
	eq(Save.boosters.return3, Save.START_STOCK.return3 + 1, "streak of 5")
	# A retry ends the streak.
	Save.start_attempt()
	Save.start_attempt()
	eq(Save.complete_level().streak, 0)
	eq(Save.best_streak, 5)
	Save.reset()


func test_streak_milestones() -> void:
	eq(Save.streak_reward_for(2), "")
	eq(Save.streak_reward_for(3), "undo")
	eq(Save.streak_reward_for(5), "return3")
	eq(Save.streak_reward_for(10), "shuffle")
	eq(Save.streak_reward_for(12), "")
	eq(Save.streak_reward_for(15), "undo")
	eq(Save.streak_reward_for(20), "return3")


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
