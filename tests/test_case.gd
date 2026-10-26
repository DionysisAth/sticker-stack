class_name TestCase
extends RefCounted
## Tiny test base: methods named test_* are run by tests/run_tests.gd.

var failures: Array[String] = []
var current := ""


func check(cond: bool, msg := "") -> void:
	if not cond:
		failures.append("%s: %s" % [current, msg if msg != "" else "check failed"])


func eq(a, b, msg := "") -> void:
	if typeof(a) != typeof(b) and not (typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]):
		failures.append("%s: %s expected %s (%s), got %s (%s)" % [current, msg, str(b), type_string(typeof(b)), str(a), type_string(typeof(a))])
	elif a != b:
		failures.append("%s: %s expected %s, got %s" % [current, msg, str(b), str(a)])


## Builds a level dictionary from short sticker lists.
static func level(types: int, stickers: Array) -> Dictionary:
	var t := []
	for i in types:
		t.append({"shape": LevelGenerator.SHAPES[i], "color": i})
	return {"level": 0, "types": t, "stickers": stickers}


static func s(type: int, x: int, y: int, z := 0, extra := {}) -> Dictionary:
	var d := {"type": type, "x": x, "y": y, "z": z}
	d.merge(extra, true)
	return d
