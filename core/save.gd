extends Node
## Local save: the current level, the booster stock and the settings.
## (Plus small bookkeeping: attempts at the current level, total clears for
## the booster jar, the win streak, and which tutorial cards were shown.)

signal changed

const BOOSTERS: Array[String] = ["undo", "return3", "shuffle"]
const START_STOCK := {"undo": 3, "return3": 2, "shuffle": 2}
## The booster jar: one segment per clear; when full it gives a booster
## (taking turns between them) and starts again.
const JAR_SIZE := 5
## Win streak: levels cleared on the first try in a row. These streaks give
## a booster, and after the last one every 5 more do.
const STREAK_REWARDS := {3: "undo", 5: "return3", 10: "shuffle"}

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
var streak := 0
var best_streak := 0
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
	streak = int(data.get("streak", 0))
	best_streak = int(data.get("best_streak", streak))
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
		"streak": streak,
		"best_streak": best_streak,
		"seen_cards": seen_cards,
	}, "  "))
	changed.emit()


## Called when the current level is cleared. Returns what the clear earned:
##   jar: segments filled after this clear (JAR_SIZE when it just filled)
##   jar_reward: booster from a full jar, or ""
##   streak: the win streak after this clear (0 if it wasn't a first try)
##   streak_reward: booster for reaching a streak milestone, or ""
func complete_level() -> Dictionary:
	var first_try := attempts <= 1
	level += 1
	attempts = 0
	clears += 1
	var out := {"jar": clears % JAR_SIZE, "jar_reward": "", "streak": 0, "streak_reward": ""}
	if clears % JAR_SIZE == 0:
		out.jar = JAR_SIZE
		out.jar_reward = BOOSTERS[(clears / JAR_SIZE - 1) % BOOSTERS.size()]
		boosters[out.jar_reward] += 1
	streak = streak + 1 if first_try else 0
	best_streak = maxi(best_streak, streak)
	out.streak = streak
	out.streak_reward = streak_reward_for(streak)
	if out.streak_reward != "":
		boosters[out.streak_reward] += 1
	save_game()
	return out


## The booster a streak of `n` earns, or "".
static func streak_reward_for(n: int) -> String:
	if STREAK_REWARDS.has(n):
		return STREAK_REWARDS[n]
	var last: int = STREAK_REWARDS.keys().max()
	if n > last and (n - last) % 5 == 0:
		return BOOSTERS[((n - last) / 5 - 1) % BOOSTERS.size()]
	return ""


## Segments in the jar right now.
func jar_fill() -> int:
	return clears % JAR_SIZE


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
	streak = 0
	best_streak = 0
	seen_cards = []
	boosters = START_STOCK.duplicate()
	save_game()
