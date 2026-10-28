class_name BoardState
extends RefCounted
## The whole game state for one attempt at a level: the pile, the tray and
## the rules. Pure logic with no scene nodes, shared by the game screen, the
## generator, the solver bot and the tests.
##
## The view calls tap() and the boosters, then reads drain_events() to animate.

enum Status { PLAYING, WON, FAILED }

const TRAY_SIZE := Tray.CAPACITY
## Return 3 puts stickers back in a row under the pile at these x positions
## (the dispensers, when a level has them, sit at both ends of that row).
const RETURN_ROW_Y := 14
const RETURN_ROW_X: Array[int] = [3, 5, 7]

const RULE_SCRIPTS := {
	"roll": preload("res://game/rules/roll_rule.gd"),
	"mystery": preload("res://game/rules/mystery_rule.gd"),
	"glue": preload("res://game/rules/glue_rule.gd"),
	"padlock": preload("res://game/rules/padlock_rule.gd"),
	"ice": preload("res://game/rules/ice_rule.gd"),
	"wrap": preload("res://game/rules/wrap_rule.gd"),
	"dispenser": preload("res://game/rules/dispenser_rule.gd"),
	"rainbow": preload("res://game/rules/rainbow_rule.gd"),
	"fuse": preload("res://game/rules/fuse_rule.gd"),
}

var level := 0
## [{"shape": String, "color": int}], indexed by sticker type.
var types: Array = []
var stickers: Array[Sticker] = []
var tray := Tray.new()
var status := Status.PLAYING
## "tray_full", "no_moves" or "fuse".
var fail_reason := ""
var picks := 0
var rules: Array[Rule] = []
var rng := RandomNumberGenerator.new()
## Off for bot runs, to save time.
var record_events := true
var events: Array[Dictionary] = []

# Rules per hook, so a plain level calls no rule code at all.
var _r_start: Array[Rule] = []
var _r_free: Array[Rule] = []
var _r_blocked: Array[Rule] = []
var _r_tap: Array[Rule] = []
var _r_extra: Array[Rule] = []
var _r_take: Array[Rule] = []
var _r_after_pick: Array[Rule] = []
var _r_after_clear: Array[Rule] = []

var _covers: Array[PackedInt32Array] = []  # id -> ids this sticker covers
var _cover_count := PackedInt32Array()     # id -> live stickers covering it
var _next_uid := 1
var _undo: Array[Dictionary] = []


static func from_level(data: Dictionary) -> BoardState:
	var st := BoardState.new()
	st.level = int(data.get("level", 0))
	st.types = data.get("types", []).duplicate(true)
	st.rng.seed = hash(st.level) + 7
	var kinds := {}
	var list: Array = data.get("stickers", [])
	for i in list.size():
		var s := Sticker.from_dict(list[i], i)
		st.stickers.append(s)
		if s.kind != "":
			kinds[s.kind] = true
		if s.type == Sticker.RAINBOW or s.roll.has(Sticker.RAINBOW):
			kinds["rainbow"] = true
	for k in kinds:
		if RULE_SCRIPTS.has(k):
			st.rules.append(RULE_SCRIPTS[k].new())
	st._index_rules()
	st._build_covers()
	for r in st._r_start:
		r.on_start(st)
	st.events.clear()
	return st


## A deep copy for the bot and the solvability check. Rules are shared.
func clone() -> BoardState:
	var st := BoardState.new()
	st.level = level
	st.types = types
	for s in stickers:
		st.stickers.append(s.copy())
	st.tray = tray.copy()
	st.status = status
	st.fail_reason = fail_reason
	st.picks = picks
	st.rules = rules
	st._r_start = _r_start
	st._r_free = _r_free
	st._r_blocked = _r_blocked
	st._r_tap = _r_tap
	st._r_extra = _r_extra
	st._r_take = _r_take
	st._r_after_pick = _r_after_pick
	st._r_after_clear = _r_after_clear
	st.rng.seed = rng.seed
	st.rng.state = rng.state
	st._covers = _covers.duplicate()
	st._cover_count = _cover_count.duplicate()
	st._next_uid = _next_uid
	st.record_events = false
	return st


# --- Queries ---------------------------------------------------------------

func has_rule(kind: String) -> bool:
	for r in rules:
		if r.kind == kind:
			return true
	return false


## True when nothing on a higher layer overlaps it (or its queue's front).
func is_free(s: Sticker) -> bool:
	if not s.alive:
		return false
	for r in _r_free:
		var v := r.is_free(self, s)
		if v >= 0:
			return v == 1
	return _cover_count[s.id] == 0


## Why a free sticker can't be peeled ("" = it can).
func blocked_reason(s: Sticker) -> String:
	for r in _r_blocked:
		var why := r.blocked_reason(self, s)
		if why != "":
			return why
	return ""


## True when tapping the sticker does something (peel, or pop its wrap).
func can_tap(s: Sticker) -> bool:
	if not is_free(s):
		return false
	return s.wrapped or blocked_reason(s) == ""


## Ids of the stickers a tap would do something on.
func tappable() -> Array[int]:
	var out: Array[int] = []
	for s in stickers:
		if s.alive and can_tap(s):
			out.append(s.id)
	return out


## The sticker id at the front of a dispenser queue, or -1.
func queue_front(q: int) -> int:
	var best := -1
	var best_order := 1 << 30
	for s in stickers:
		if s.alive and s.queue == q and s.order < best_order:
			best_order = s.order
			best = s.id
	return best


## Ids that this sticker covers.
func covered_by(id: int) -> PackedInt32Array:
	return _covers[id]


func cover_count(id: int) -> int:
	return _cover_count[id]


func stickers_left() -> int:
	var n := 0
	for s in stickers:
		if s.alive:
			n += s.count()
	return n


func can_undo() -> bool:
	return not _undo.is_empty() and status != Status.WON and fail_reason != "fuse"


func can_return() -> bool:
	return tray.size() > 0 and status != Status.WON and fail_reason != "fuse"


func can_shuffle() -> bool:
	return status == Status.PLAYING and _shufflable().size() >= 2


# --- Actions ---------------------------------------------------------------

## The player taps a sticker. Returns true if anything happened.
func tap(id: int) -> bool:
	if status != Status.PLAYING or id < 0 or id >= stickers.size():
		return false
	var s := stickers[id]
	if not s.alive:
		return false
	if not is_free(s):
		emit_event({"e": "blocked", "id": id, "reason": "covered"})
		return false
	for r in _r_tap:
		if r.on_tap(self, s):
			_check_end()
			return true
	var why := blocked_reason(s)
	if why != "":
		emit_event({"e": "blocked", "id": id, "reason": why})
		return false
	_pick(s)
	return true


func fail(reason: String, id := -1) -> void:
	if status != Status.PLAYING:
		return
	status = Status.FAILED
	fail_reason = reason
	emit_event({"e": "failed", "reason": reason, "id": id})


## Undo booster: puts the last picked sticker back. Can't go back past a
## cleared triple.
func undo() -> bool:
	if not can_undo():
		return false
	var snap: Dictionary = _undo.pop_back()
	stickers.assign(snap.stickers)
	tray = snap.tray
	picks = snap.picks
	_cover_count = snap.cover_count
	status = Status.PLAYING
	fail_reason = ""
	emit_event({"e": "undo"})
	return true


## Return 3 booster: sends the 3 leftmost tray stickers back on top of the
## pile, in a row under it.
func return_three() -> bool:
	if not can_return():
		return false
	var n := mini(3, tray.size())
	var ids: Array[int] = []
	for i in n:
		var entry := tray.remove_at(0)
		var s := Sticker.new()
		s.id = stickers.size()
		s.type = entry.type
		s.kind = "rainbow" if entry.type == Sticker.RAINBOW else ""
		s.returned = true
		s.x = RETURN_ROW_X[i]
		s.y = RETURN_ROW_Y
		s.z = 100
		for o in stickers:
			if o.alive and o.returned and o.x == s.x:
				s.z = maxi(s.z, o.z + 1)
		_add_sticker(s)
		ids.append(s.id)
		if s.type == Sticker.RAINBOW and not has_rule("rainbow"):
			_add_rule("rainbow")
		emit_event({"e": "returned", "id": s.id, "uid": entry.uid})
	_undo.clear()
	status = Status.PLAYING
	fail_reason = ""
	_check_end()
	return true


## Shuffle booster: mixes the types of the stickers still on the board.
## Tries a few mixes and keeps one the bot can still win, so it never makes a
## winnable board unwinnable. Returns false (and changes nothing) if no mix
## passed the check.
func shuffle(tries := 6) -> bool:
	if not can_shuffle():
		return false
	var slots := _shufflable()
	var original: Array[int] = []
	for p in slots:
		original.append(_get_slot_type(p))
	for attempt in tries:
		var mixed := original.duplicate()
		_shuffle_array(mixed)
		if mixed == original and original.size() > 2:
			continue
		for i in slots.size():
			_set_slot_type(slots[i], mixed[i])
		if SolverBot.can_win(self, 12, rng.randi()):
			_undo.clear()
			emit_event({"e": "shuffled"})
			return true
	for i in slots.size():
		_set_slot_type(slots[i], original[i])
	return false


## Magnet (earned in the level by chaining triples): pulls the triple of a
## sticker's type out of the pile, covered or not, and clears it at once
## together with any of that type already in the tray. Stickers held by a
## mechanic (locked, frozen, glued, rolls) can't be pulled. Counts as one pick.
func magnet(id: int) -> bool:
	var group := magnet_group(id)
	if group.is_empty():
		return false
	var t := stickers[id].type
	_undo.clear()
	var uids: Array[int] = []
	# Stickers of that type already in the tray join the triple.
	var i := tray.types.size() - 1
	while i >= 0:
		if tray.types[i] == t and uids.size() < 3 - group.size():
			uids.append(tray.remove_at(i).uid)
		i -= 1
	for p in group:
		_remove(p)
		var uid := _next_uid
		_next_uid += 1
		uids.append(uid)
		emit_event({"e": "pick", "id": p.id, "uid": uid, "type": t, "index": tray.size(), "stays": false, "magnet": true})
	var res := {"type": t, "uids": uids, "rainbows": 0}
	emit_event({"e": "clear", "type": t, "uids": uids, "magnet": true})
	for r in _r_after_clear:
		r.after_clear(self, res)
	picks += 1
	for r in _r_after_pick:
		r.after_pick(self, group)
	_check_end()
	return true


## The stickers a magnet on `id` would pull (that sticker first), or [] if
## there aren't enough pullable ones of its type to finish a triple.
func magnet_group(id: int) -> Array[Sticker]:
	var none: Array[Sticker] = []
	if status != Status.PLAYING or id < 0 or id >= stickers.size():
		return none
	var s := stickers[id]
	if not s.alive or not _pullable(s):
		return none
	var need := 3 - tray.count_of(s.type) % 3
	var others: Array[Sticker] = []
	for o in stickers:
		if o != s and o.alive and o.type == s.type and _pullable(o):
			others.append(o)
	if others.size() < need - 1:
		return none
	# Visible ones first, then the highest.
	var visible_first := func(a: Sticker, b: Sticker) -> bool:
		var fa := is_free(a)
		var fb := is_free(b)
		return fa if fa != fb else a.z > b.z
	others.sort_custom(visible_first)
	var group: Array[Sticker] = [s]
	group.append_array(others.slice(0, need - 1))
	return group


func _pullable(s: Sticker) -> bool:
	return s.type != Sticker.RAINBOW and s.key < 0 and s.ice == 0 and s.pair < 0 and s.roll.is_empty() and s.kind != "roll"


func emit_event(e: Dictionary) -> void:
	if record_events:
		events.append(e)


func drain_events() -> Array[Dictionary]:
	var out := events.duplicate()
	events.clear()
	return out


## Plays a list of taps; used by the tests and the generator's check.
func play(taps: Array) -> Status:
	for id in taps:
		if status != Status.PLAYING:
			break
		tap(int(id))
	return status


# --- Internals -------------------------------------------------------------

func _pick(s: Sticker) -> void:
	var group: Array[Sticker] = [s]
	for r in _r_extra:
		group.append_array(r.extra_picks(self, s))
	_undo.append(_snapshot())
	var cleared := false
	for p in group:
		var t := p.type
		var stays := false
		for r in _r_take:
			if r.take(self, p):
				stays = true
		if not stays:
			_remove(p)
		var uid := _next_uid
		_next_uid += 1
		var at := tray.insert(t, uid)
		emit_event({"e": "pick", "id": p.id, "uid": uid, "type": t, "index": at, "stays": stays})
		var res := tray.resolve()
		if not res.is_empty():
			cleared = true
			emit_event({"e": "clear", "type": res.type, "uids": res.uids})
			for r in _r_after_clear:
				r.after_clear(self, res)
		elif tray.is_full():
			fail("tray_full")
			break
	picks += 1
	if status == Status.PLAYING:
		for r in _r_after_pick:
			r.after_pick(self, group)
	if cleared:
		_undo.clear()
	_check_end()


func _index_rules() -> void:
	for r in rules:
		var h := r.hooks()
		if h.has("on_start"): _r_start.append(r)
		if h.has("is_free"): _r_free.append(r)
		if h.has("blocked_reason"): _r_blocked.append(r)
		if h.has("on_tap"): _r_tap.append(r)
		if h.has("extra_picks"): _r_extra.append(r)
		if h.has("take"): _r_take.append(r)
		if h.has("after_pick"): _r_after_pick.append(r)
		if h.has("after_clear"): _r_after_clear.append(r)


func _check_end() -> void:
	if status != Status.PLAYING:
		return
	var any_alive := false
	for s in stickers:
		if s.alive:
			any_alive = true
			if can_tap(s):
				return
	if not any_alive and tray.size() == 0:
		status = Status.WON
		emit_event({"e": "won"})
	else:
		fail("no_moves")


func _remove(s: Sticker) -> void:
	s.alive = false
	for i in _covers[s.id]:
		_cover_count[i] -= 1


func _build_covers() -> void:
	var n := stickers.size()
	_covers.clear()
	_covers.resize(n)
	_cover_count.resize(n)
	_cover_count.fill(0)
	for i in n:
		_covers[i] = PackedInt32Array()
	for i in n:
		var a := stickers[i]
		if not a.on_board():
			continue
		for j in range(i + 1, n):
			var b := stickers[j]
			if not b.on_board() or a.z == b.z or not a.overlaps(b):
				continue
			if a.z > b.z:
				_covers[i].append(j)
				_cover_count[j] += 1
			else:
				_covers[j].append(i)
				_cover_count[i] += 1


func _add_sticker(s: Sticker) -> void:
	stickers.append(s)
	_covers.append(PackedInt32Array())
	_cover_count.append(0)
	for o in stickers:
		if o == s or not o.alive or not o.on_board() or not o.overlaps(s) or o.z == s.z:
			continue
		if s.z > o.z:
			_covers[s.id].append(o.id)
			_cover_count[o.id] += 1
		else:
			_covers[o.id].append(s.id)
			_cover_count[s.id] += 1


func _add_rule(kind: String) -> void:
	# New lists rather than changing them in place: clones share them.
	rules = rules.duplicate()
	rules.append(RULE_SCRIPTS[kind].new())
	_r_start = []
	_r_free = []
	_r_blocked = []
	_r_tap = []
	_r_extra = []
	_r_take = []
	_r_after_pick = []
	_r_after_clear = []
	_index_rules()


func _snapshot() -> Dictionary:
	var copies: Array[Sticker] = []
	for s in stickers:
		copies.append(s.copy())
	return {
		"stickers": copies,
		"tray": tray.copy(),
		"picks": picks,
		"cover_count": _cover_count.duplicate(),
	}


## Every type slot Shuffle may change: [sticker id, roll index] (-1 = top).
func _shufflable() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for s in stickers:
		if not s.alive or s.type == Sticker.RAINBOW:
			continue
		out.append(Vector2i(s.id, -1))
		for i in s.roll.size():
			out.append(Vector2i(s.id, i))
	return out


func _get_slot_type(p: Vector2i) -> int:
	var s := stickers[p.x]
	return s.type if p.y < 0 else s.roll[p.y]


func _set_slot_type(p: Vector2i, t: int) -> void:
	var s := stickers[p.x]
	if p.y < 0:
		s.type = t
	else:
		s.roll[p.y] = t


func _shuffle_array(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
