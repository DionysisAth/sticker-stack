extends Node
## Local save: the current level, the booster stock and the settings.
## (Plus small bookkeeping: attempts at the current level, total clears for
## the booster reward, and which tutorial cards were already shown.)

signal changed

const BOOSTERS: Array[String] = ["undo", "return3", "shuffle"]
const START_STOCK := {"undo": 3, "return3": 2, "shuffle": 2}
## Every this many clears, one more booster (taking turns between them).
const REWARD_EVERY := 5

var path := "user://save.json"
var level := 1
var boosters := START_STOCK.duplicate()
var settings := {
	"sound": true,
	"haptics": true,
	"colorblind": false,
	"reduce_motion": false,
}
var attempts := 0
var clears := 0
var seen_cards: Array = []


func _ready() -> void:
	load_game()


func load_game() -> void:
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	level = maxi(1, int(data.get("level", 1)))
	attempts = int(data.get("attempts", 0))
	clears = int(data.get("clears", 0))
	seen_cards = data.get("seen_cards", [])
	var b: Dictionary = data.get("boosters", {})
	for k in BOOSTERS:
		boosters[k] = int(b.get(k, boosters[k]))
	var s: Dictionary = data.get("settings", {})
	for k in settings:
		if s.has(k):
			settings[k] = bool(s[k])


func save_game() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file: %s" % path)
		return
	f.store_string(JSON.stringify({
		"level": level,
		"boosters": boosters,
		"settings": settings,
		"attempts": attempts,
		"clears": clears,
		"seen_cards": seen_cards,
	}, "  "))
	changed.emit()


## Called when the current level is cleared. Returns the booster earned, or "".
func complete_level() -> String:
	level += 1
	attempts = 0
	clears += 1
	var reward := ""
	if clears % REWARD_EVERY == 0:
		reward = BOOSTERS[(clears / REWARD_EVERY - 1) % BOOSTERS.size()]
		boosters[reward] += 1
	save_game()
	return reward


func start_attempt() -> int:
	attempts += 1
	save_game()
	return attempts


func has_booster(id: String) -> bool:
	return int(boosters.get(id, 0)) > 0


func spend_booster(id: String) -> bool:
	if not has_booster(id):
		return false
	boosters[id] -= 1
	save_game()
	return true


func set_setting(key: String, value: bool) -> void:
	settings[key] = value
	save_game()


func setting(key: String) -> bool:
	return bool(settings.get(key, false))


func mark_card_seen(id: String) -> void:
	if not seen_cards.has(id):
		seen_cards.append(id)
		save_game()


func reset() -> void:
	level = 1
	attempts = 0
	clears = 0
	seen_cards = []
	boosters = START_STOCK.duplicate()
	save_game()
