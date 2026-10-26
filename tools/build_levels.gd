extends SceneTree
## Builds the hand-tuned level files levels/level_NNN.json.
##
## For each level the generator makes `candidates` piles from the difficulty
## curve, the bot plays each `screen` times, the 3 closest to the target win
## rate get the full `runs` games, and the closest one is kept. (In the plan a
## designer plays the top 3 in the level editor and picks one; this tool picks
## automatically, and the editor can replace any level by hand.)
##
## godot --headless --path . --script res://tools/build_levels.gd -- --from=1 --to=50
## Options: --candidates=30 --screen=40 --runs=500
## Ranges can run in parallel processes; then `-- --report` rewrites
## levels/README.md from the level files.

var opts := {"from": 1, "to": Difficulty.HAND_TUNED, "candidates": 30, "screen": 40, "runs": 500, "report": 0}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--report":
			opts.report = 1
		elif a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=")
			if opts.has(kv[0]):
				opts[kv[0]] = int(kv[1])
	if opts.report == 1:
		_write_report()
		quit()
		return
	var t_all := Time.get_ticks_msec()
	for n in range(opts.from, opts.to + 1):
		var t0 := Time.get_ticks_msec()
		var p := Difficulty.params(n)
		var target := float(p.target)
		var cands: Array[Dictionary] = []
		var seed := n * 1000
		while cands.size() < opts.candidates and seed < n * 1000 + opts.candidates * 6:
			var level := LevelGenerator.generate(p, seed)
			seed += 1
			if level.is_empty():
				continue
			var rate := SolverBot.win_rate(BoardState.from_level(level), opts.screen, 11)
			cands.append({"level": level, "rate": rate, "err": absf(rate - target)})
		if cands.is_empty():
			push_error("Level %d: no candidate generated" % n)
			continue
		cands.sort_custom(func(a, b): return a.err < b.err)
		var best := {}
		var best_err := INF
		for c in cands.slice(0, 3):
			var rate := SolverBot.win_rate(BoardState.from_level(c.level), opts.runs, 29)
			if absf(rate - target) < best_err:
				best_err = absf(rate - target)
				best = c.level
				best["bot_win_rate"] = snappedf(rate, 0.01)
		var f := FileAccess.open(LevelData.path_for(n), FileAccess.WRITE)
		f.store_string(LevelData.to_json(best))
		f.close()
		print(_row(n, best), "  (%d candidates, %.1fs)" % [cands.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	if opts.from == 1 and opts.to == Difficulty.HAND_TUNED:
		_write_report()
	print("Done in %.0fs" % ((Time.get_ticks_msec() - t_all) / 1000.0))
	quit()


func _row(n: int, level: Dictionary) -> String:
	var p := Difficulty.params(n)
	var kinds := {}
	var layers := 0
	var picks := 0
	for d in level.stickers:
		var k := String(d.get("kind", ""))
		if int(d.type) == Sticker.RAINBOW:
			k = "rainbow"
		if k != "":
			kinds[k] = kinds.get(k, 0) + 1
		layers = maxi(layers, int(d.get("z", 0)) + 1)
		picks += 1 + d.get("roll", []).size()
	var mech: Array[String] = []
	for k in kinds:
		mech.append("%s ×%d" % [k, kinds[k]])
	var note := "Hard" if level.hard else ("Intro" if String(level.get("tutorial", "")) != "" else "")
	return "| %d | %s | %s | %d | %d | %d | %.0f%% | %.0f%% |" % [
		n, note, ", ".join(mech) if not mech.is_empty() else "-", picks, level.types.size(),
		layers, float(p.target) * 100.0, float(level.get("bot_win_rate", 0)) * 100.0]


func _write_report() -> void:
	var rows: Array[String] = []
	for n in range(1, Difficulty.HAND_TUNED + 1):
		var level := LevelData.parse(FileAccess.get_file_as_string(LevelData.path_for(n)))
		if not level.is_empty():
			rows.append(_row(n, level))
	var text := "# Levels 1-%d\n\n" % Difficulty.HAND_TUNED
	text += "Made by `tools/build_levels.gd`. Bot win rate is measured over %d games\n" % opts.runs
	text += "of the greedy solver bot (`game/solver_bot.gd`).\n\n"
	text += "| Level | Note | Mechanics | Stickers | Types | Layers | Target | Bot win rate |\n"
	text += "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
	text += "\n".join(rows) + "\n"
	var f := FileAccess.open("res://levels/README.md", FileAccess.WRITE)
	f.store_string(text)
	f.close()
