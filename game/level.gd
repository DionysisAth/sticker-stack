class_name LevelData
extends RefCounted
## Loads level files. Levels 1-50 are hand-tuned files in res://levels/.
## After that the generator makes levels from the level number as seed, so
## players never run out and a retry always gets the same pile.

const DIR := "res://levels/"

## Generated levels are kept so retries don't redo the bot check.
static var _cache := {}


static func path_for(n: int) -> String:
	return DIR + "level_%03d.json" % n


static func load_level(n: int) -> Dictionary:
	if _cache.has(n):
		return _cache[n]
	var path := path_for(n)
	var level := {}
	if FileAccess.file_exists(path):
		level = parse(FileAccess.get_file_as_string(path))
	if level.is_empty():
		level = generate_endless(n)
	_cache[n] = level
	return level


static func parse(text: String) -> Dictionary:
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


## Makes a level from its number. Tries a few seeds and keeps the one whose
## bot win rate is closest to the target.
static func generate_endless(n: int, candidates := 5, runs := 30) -> Dictionary:
	var p := Difficulty.params(n)
	var best := {}
	var best_err := INF
	var good := 0
	for c in 60:
		var level := LevelGenerator.generate(p, n * 1000 + c)
		if level.is_empty():
			continue
		var rate := SolverBot.win_rate(BoardState.from_level(level), runs, n)
		var err := absf(rate - float(p.target))
		if err < best_err:
			best_err = err
			best = level
			best["bot_win_rate"] = snappedf(rate, 0.01)
		good += 1
		if good >= candidates or err < 0.06:
			break
	return best


## JSON with one sticker per line, so diffs of level files stay readable.
static func to_json(level: Dictionary) -> String:
	var keys := ["level", "hard", "tutorial", "seed", "bot_win_rate", "types", "stickers", "solution"]
	var lines: Array[String] = []
	for k in keys:
		if not level.has(k):
			continue
		var v = level[k]
		if k == "types" or k == "stickers":
			var items: Array[String] = []
			for item in v:
				items.append("    " + JSON.stringify(item, "", false))
			lines.append("  \"%s\": [\n%s\n  ]" % [k, ",\n".join(items)])
		else:
			lines.append("  \"%s\": %s" % [k, JSON.stringify(v, "", false)])
	for k in level:
		if not keys.has(k):
			lines.append("  \"%s\": %s" % [k, JSON.stringify(level[k], "", false)])
	return "{\n" + ",\n".join(lines) + "\n}\n"
