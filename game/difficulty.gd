class_name Difficulty
extends RefCounted
## The difficulty curve. Each 5-level block starts easy with its new mechanic
## and climbs; every 10th level is Hard and is followed by an easy intro level.
##
## Knobs: sticker count, number of types, layer depth, how many triples are
## open at once in the winning order ("mix"), how much the layers overlap,
## and how many mechanic stickers there are.

const HAND_TUNED := 50
const MAX_TYPES := 10

## Target bot win rates.
const TARGET_TUTORIAL := 1.0
const TARGET_INTRO := 0.9
const TARGET_HARD := 0.35
const TARGET_BY_POS: Array[float] = [0.9, 0.75, 0.72, 0.68, 0.62]


static func is_hard(level: int) -> bool:
	return level % 10 == 0


static func params(level: int) -> Dictionary:
	var p := {
		"level": level,
		"hard": is_hard(level),
		"mechanics": {},
		"offset": 0,
	}
	var pos := (level - 1) % 5
	var block := (level - 1) / 5
	match level:
		1:
			return _merge(p, {"count": 9, "types": 3, "layers": 1, "mix": 1, "target": TARGET_TUTORIAL})
		2:
			return _merge(p, {"count": 12, "types": 3, "layers": 2, "mix": 1, "target": TARGET_TUTORIAL})
		3:
			return _merge(p, {"count": 15, "types": 3, "layers": 2, "mix": 2, "target": TARGET_TUTORIAL})
		4:
			return _merge(p, {"count": 21, "types": 4, "layers": 3, "mix": 2, "target": 0.9})
		5:
			return _merge(p, {"count": 24, "types": 5, "layers": 3, "mix": 2, "target": 0.8})
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 7919 + 13
	var intro := pos == 0
	var endless := level > HAND_TUNED
	var size := 24.0 + minf(level, 50) * 1.2
	if endless:
		size = 66.0 + rng.randi_range(-6, 12)
	size *= [0.6, 0.85, 0.95, 1.0, 1.08][pos]
	if p.hard:
		size *= 1.1
	p.count = clampi(int(round(size / 3.0)) * 3, 18, 96)
	var types := 4 + mini(block, 9) / 2
	if pos >= 2:
		types += 1
	if pos == 1 and block >= 3:
		types += 1
	if p.hard:
		types += 1
	if intro:
		types = 4 + mini(block, 6) / 3
	p.types = clampi(types, 3, MAX_TYPES)
	var layers := 2 + mini(block, 9) / 3 + (1 if pos >= 2 or (pos == 1 and block >= 3) else 0)
	p.layers = clampi(layers if not intro else mini(layers, 3), 2, 6)
	p.mix = 1 if intro else (3 if pos >= 2 or p.hard or block >= 3 else 2)
	p.offset = rng.randi_range(0, 2)
	if intro:
		p.target = TARGET_INTRO
	elif p.hard:
		p.target = TARGET_HARD
	else:
		p.target = TARGET_BY_POS[pos]
	p.mechanics = _mechanics_for(level, pos, p.hard, rng)
	return p


## Mechanic counts. The intro level uses its mechanic alone; the next four
## mix it with one or two earlier ones.
static func _mechanics_for(level: int, pos: int, hard: bool, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var unlocked := Mechanics.unlocked(level)
	if unlocked.is_empty():
		return out
	var newest: String = unlocked[unlocked.size() - 1]
	if level > HAND_TUNED:
		# Endless: two or three random mechanics.
		var pool := unlocked.duplicate()
		for i in rng.randi_range(2, 3):
			var k: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			out[k] = amount(k, false, hard, rng)
		return out
	var intro := pos == 0
	out[newest] = amount(newest, intro, hard, rng)
	if not intro:
		var older := unlocked.slice(0, unlocked.size() - 1)
		var n := 0 if older.is_empty() else (1 if pos <= 2 else 2)
		for i in mini(n, older.size()):
			var k: String = older.pop_at(rng.randi_range(0, older.size() - 1))
			out[k] = amount(k, false, hard, rng)
	return out


## How many of a mechanic to place.
static func amount(kind: String, intro: bool, hard: bool, rng: RandomNumberGenerator) -> int:
	var lo := 1
	var hi := 2
	match kind:
		"roll": lo = 2; hi = 3
		"mystery": lo = 5; hi = 9
		"glue": lo = 2; hi = 4
		"padlock": lo = 2; hi = 3
		"ice": lo = 3; hi = 4
		"wrap": lo = 4; hi = 7
		"dispenser": lo = 6; hi = 10   # stickers in the two queues together
		"rainbow": lo = 1; hi = 1
		"fuse": lo = 1; hi = 2
	if intro:
		return lo
	if hard:
		return hi
	return rng.randi_range(lo, hi)


static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	a.merge(b, true)
	return a
