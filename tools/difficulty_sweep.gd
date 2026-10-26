extends SceneTree
## Tuning helper: for each level, generates 8 candidate piles from the
## difficulty curve and prints the bot win rate of each (40 games), next to
## the target. Use it after changing game/difficulty.gd, before rebuilding.
##
## godot --headless --path . --script res://tools/difficulty_sweep.gd -- --levels=7,8,9


func _init() -> void:
	var levels := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--levels="):
			for x in a.substr(9).split(","):
				levels.append(int(x))
	if levels.is_empty():
		levels = range(4, 51)
	for lv in levels:
		var p := Difficulty.params(lv)
		var t0 := Time.get_ticks_msec()
		var rates := []
		var fails := 0
		for c in 8:
			var level := LevelGenerator.generate(p, lv * 1000 + c)
			if level.is_empty():
				fails += 1
				continue
			rates.append(snappedf(SolverBot.win_rate(BoardState.from_level(level), 40, 1), 0.01))
		rates.sort()
		print("L%d target=%.2f n=%d t=%d L=%d mix=%d gen_fail=%d rates=%s ms=%d %s" % [lv, p.target, p.count, p.types, p.layers, p.mix, fails, str(rates), Time.get_ticks_msec() - t0, str(p.mechanics.keys())])
	quit()
