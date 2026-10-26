class_name Tray
extends RefCounted
## The 7-slot tray. Stickers are kept grouped by type; three alike clear.
## A rainbow sticker completes any pair. Each entry has a uid so the view can
## follow it while it moves.

const CAPACITY := 7

var types: Array[int] = []
var uids: Array[int] = []


func size() -> int:
	return types.size()


func is_full() -> bool:
	return types.size() >= CAPACITY


func count_of(t: int) -> int:
	return types.count(t)


func copy() -> Tray:
	var t := Tray.new()
	t.types = types.duplicate()
	t.uids = uids.duplicate()
	return t


## Puts a sticker next to others of its type (or at the end). Returns its index.
func insert(t: int, uid: int) -> int:
	var at := types.size()
	if t != Sticker.RAINBOW:
		var last := types.rfind(t)
		if last >= 0:
			at = last + 1
	types.insert(at, t)
	uids.insert(at, uid)
	return at


## Clears one triple if there is one. Returns {} when nothing cleared, else
## {"type": cleared type, "uids": [the three uids]}.
func resolve() -> Dictionary:
	# Three of a kind first.
	for t in _distinct():
		if t != Sticker.RAINBOW and types.count(t) >= 3:
			return _remove(t, 3, 0)
	var rainbows := types.count(Sticker.RAINBOW)
	if rainbows > 0:
		# A rainbow completes the leftmost pair.
		for t in _distinct():
			if t != Sticker.RAINBOW and types.count(t) == 2:
				return _remove(t, 2, 1)
		if rainbows >= 3:
			return _remove(Sticker.RAINBOW, 3, 0)
	return {}


func remove_at(index: int) -> Dictionary:
	var d := {"type": types[index], "uid": uids[index]}
	types.remove_at(index)
	uids.remove_at(index)
	return d


func _distinct() -> Array[int]:
	var seen: Array[int] = []
	for t in types:
		if not seen.has(t):
			seen.append(t)
	return seen


func _remove(t: int, n: int, rainbows: int) -> Dictionary:
	var removed: Array[int] = []
	var left := n
	var i := 0
	while i < types.size() and left > 0:
		if types[i] == t:
			removed.append(uids[i])
			types.remove_at(i)
			uids.remove_at(i)
			left -= 1
		else:
			i += 1
	left = rainbows
	i = 0
	while i < types.size() and left > 0:
		if types[i] == Sticker.RAINBOW:
			removed.append(uids[i])
			types.remove_at(i)
			uids.remove_at(i)
			left -= 1
		else:
			i += 1
	return {"type": t, "uids": removed, "rainbows": rainbows}
