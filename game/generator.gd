class_name LevelGenerator
extends RefCounted
## Makes a level from difficulty parameters and a seed. Every level it returns
## has a known winning order (stored as "solution"), checked with the real
## rules before it is returned.
##
## 1. Pick a symmetric layered pile of slots.
## 2. Pick a winning order: a random order that only ever takes free slots.
##    (This is the same as placing stickers backwards along the order, each on
##    top of what it overlaps.)
## 3. Add rolls and dispensers as extra picks, glue neighbours together.
## 4. Give the picks types so a perfect player never holds more than 5.
## 5. Add the other mechanics as data, then replay the winning order with the
##    rule scripts. If it doesn't win, the level is thrown away.

const SHAPES: Array[String] = [
	"circle", "square", "triangle", "star", "heart", "diamond",
	"hexagon", "moon", "flower", "drop", "cloud", "bolt",
]
const COLORS := 10
const MAX_HELD := 5
const CENTER := Vector2(5.0, 6.0)

var rng := RandomNumberGenerator.new()
var p: Dictionary
var slots: Array[Vector3i] = []
var coverers: Array = []   # slot -> slots on top of it
var covered: Array = []    # slot -> slots under it


## Returns a level dictionary, or {} if this seed didn't work out.
static func generate(params: Dictionary, seed: int) -> Dictionary:
	var g := LevelGenerator.new()
	return g._run(params, seed)


func _run(params: Dictionary, seed: int) -> Dictionary:
	p = params
	rng.seed = seed
	var n: int = p.count
	var mech: Dictionary = p.get("mechanics", {})
	var intro := Mechanics.intro_at(int(p.level)) != ""

	# Extra picks that don't need a board slot.
	var roll_depths: Array[int] = []
	for i in int(mech.get("roll", 0)):
		roll_depths.append(3 if intro else rng.randi_range(2, 4))
	var extras := 0
	for d in roll_depths:
		extras += d - 1
	var disp_items := int(mech.get("dispenser", 0))
	var board_n := n - extras - disp_items
	if board_n < 6:
		return {}

	_make_slots(board_n)
	if slots.size() != board_n:
		return {}
	_build_cover()
	var order := _random_order()

	# Entities in pick order. k: "slot" | "roll" (extra pick of a roll) | "disp".
	var ents: Array[Dictionary] = []
	var glue_pairs := _make_glue(order, int(mech.get("glue", 0)))
	var glued := {}
	for gp in glue_pairs:
		glued[gp.x] = gp.y
		glued[gp.y] = gp.x
	for s in order:
		var e := {"k": "slot", "s": s}
		if glued.has(s) and order.find(glued[s]) == order.find(s) + 1:
			e["glued_next"] = true
		ents.append(e)

	# Rolls: extra picks between the roll's first pick and the first pick of
	# anything it covers.
	var roll_slots: Array[int] = []
	var by_height: Array = range(board_n)
	_shuffle(by_height)
	by_height.sort_custom(func(a, b): return slots[a].z > slots[b].z)
	for d in roll_depths:
		for s in by_height:
			if glued.has(s) or roll_slots.has(s):
				continue
			var t := _index_of_slot(ents, s)
			var limit := ents.size()
			for i in range(t + 1, ents.size()):
				if ents[i].k == "slot" and covered[s].has(ents[i].s):
					limit = i
					break
			roll_slots.append(s)
			var cuts: Array[int] = []
			for j in d - 1:
				cuts.append(rng.randi_range(t + 1, limit))
			cuts.sort()
			cuts.reverse()
			for c in cuts:
				ents.insert(_safe_cut(ents, c, t + 1, limit), {"k": "roll", "s": s})
			break

	# Dispensers: anywhere in the order, alternating queues.
	for i in disp_items:
		var c := rng.randi_range(0, ents.size())
		ents.insert(_safe_cut(ents, c, 0, ents.size()), {"k": "disp", "q": i % 2})

	# Types.
	var seq := _type_sequence(ents.size(), int(p.types), int(p.mix))
	if seq.is_empty():
		return {}
	for i in ents.size():
		ents[i]["t"] = seq[i]

	# Rainbow: replace the pick that completes a triple while it's the only pair.
	if int(mech.get("rainbow", 0)) > 0:
		var counts := {}
		var options: Array[int] = []
		for i in ents.size():
			var t: int = ents[i].t
			var e := ents[i]
			var pairs := 0
			for k in counts:
				if counts[k] == 2:
					pairs += 1
			var ok_kind: bool = (e.k == "slot" and not glued.has(e.s) and not roll_slots.has(e.s)) or e.k == "disp"
			if ok_kind and counts.get(t, 0) == 2 and pairs == 1 and i > 2:
				options.append(i)
			counts[t] = (counts.get(t, 0) + 1) % 3
		for j in mini(int(mech.rainbow), options.size()):
			ents[options.pop_at(rng.randi_range(0, options.size() - 1))]["rainbow"] = true

	# Sticker list: board slots first (id = slot index), then dispenser items.
	var types_list := _pick_types(int(p.types))
	var stickers: Array[Dictionary] = []
	for s in board_n:
		stickers.append({"type": 0, "x": slots[s].x, "y": slots[s].y, "z": slots[s].z})
	var ent_id: Array[int] = []
	var queue_len := [0, 0]
	for e in ents:
		match e.k:
			"slot":
				ent_id.append(e.s)
				stickers[e.s]["type"] = e.t
				if e.get("rainbow", false):
					stickers[e.s]["kind"] = "rainbow"
					stickers[e.s]["type"] = Sticker.RAINBOW
			"roll":
				ent_id.append(e.s)
				stickers[e.s]["kind"] = "roll"
				if not stickers[e.s].has("roll"):
					stickers[e.s]["roll"] = []
				stickers[e.s]["roll"].append(e.t)
			"disp":
				var d := {"type": e.t, "kind": "dispenser", "queue": e.q, "order": queue_len[e.q]}
				if e.get("rainbow", false):
					d["type"] = Sticker.RAINBOW
				queue_len[e.q] += 1
				ent_id.append(stickers.size())
				stickers.append(d)
	for gp in glue_pairs:
		stickers[gp.x]["kind"] = "glue"
		stickers[gp.x]["pair"] = gp.y
		stickers[gp.y]["kind"] = "glue"
		stickers[gp.y]["pair"] = gp.x

	# Actions: one tap per pick, glued pairs are one action.
	var actions: Array = []   # each: [entity indices]
	var i := 0
	while i < ents.size():
		if ents[i].get("glued_next", false):
			actions.append([i, i + 1])
			i += 2
		else:
			actions.append([i])
			i += 1
	var action_of_sticker := {}  # board sticker id -> first action index
	for a in actions.size():
		var sid: int = ent_id[actions[a][0]]
		if not action_of_sticker.has(sid):
			action_of_sticker[sid] = a

	# Triple clear times, for padlock keys.
	var clear_at := {}  # entity index -> cleared type
	var tray := Tray.new()
	for k in ents.size():
		tray.insert(Sticker.RAINBOW if ents[k].get("rainbow", false) else int(ents[k].t), k)
		var res := tray.resolve()
		if not res.is_empty():
			clear_at[k] = res.type

	var plain: Array[int] = []
	for s in board_n:
		if not stickers[s].has("kind"):
			plain.append(s)
	_shuffle(plain)
	var first_ent := {}
	for k in ents.size():
		if not first_ent.has(ent_id[k]):
			first_ent[ent_id[k]] = k

	for kind in ["padlock", "ice", "fuse", "mystery", "wrap"]:
		var want := int(mech.get(kind, 0))
		var placed := 0
		for s in plain.duplicate():
			if placed >= want:
				break
			var a: int = action_of_sticker[s]
			var d: Dictionary = stickers[s]
			match kind:
				"mystery":
					if coverers[s].is_empty():
						continue
				"padlock":
					var keys: Array[int] = []
					for k in clear_at:
						if k < first_ent[s] and not keys.has(clear_at[k]) and clear_at[k] != Sticker.RAINBOW:
							keys.append(clear_at[k])
					keys.erase(d.type)
					if keys.is_empty() or a < 4:
						continue
					d["key"] = keys[rng.randi_range(0, keys.size() - 1)]
				"ice":
					if a < 3:
						continue
					d["ice"] = rng.randi_range(2, mini(a, 9))
				"fuse":
					if a > 14 or a < 1:
						continue
					var slack := rng.randi_range(3, 5) if intro else rng.randi_range(1, 3)
					d["fuse"] = a + 1 + slack
			d["kind"] = kind
			plain.erase(s)
			placed += 1

	# Taps for the winning order (bubble wrap needs a tap to pop first).
	var solution: Array[int] = []
	for act in actions:
		var sid: int = ent_id[act[0]]
		if stickers[sid].get("kind", "") == "wrap" and not solution.has(sid):
			solution.append(sid)
		solution.append(sid)

	var card := Mechanics.card_for(int(p.level))
	var level := {
		"level": p.level,
		"seed": seed,
		"types": types_list,
		"stickers": stickers,
		"tutorial": card.get("id", ""),
		"hard": p.hard,
		"solution": solution,
	}
	var check := BoardState.from_level(level)
	if check.play(solution) != BoardState.Status.WON:
		return {}
	return level


# --- Pile ------------------------------------------------------------------

func _layer_positions(l: int) -> Array[Vector2i]:
	var ox := 0
	var oy := 0
	if l % 2 == 1:
		match int(p.get("offset", 0)):
			0: ox = 1; oy = 1
			1: ox = 1
			2: oy = 1
	var out: Array[Vector2i] = []
	var y := oy
	while y <= 12:
		var x := ox
		while x <= 10:
			out.append(Vector2i(x, y))
			x += 2
		y += 2
	return out


func _make_slots(total: int) -> void:
	var layers := int(p.layers)
	var shape := rng.randi_range(0, 4)
	var weights: Array[float] = []
	var wsum := 0.0
	for l in layers:
		var w := float(layers - l) + 0.6
		weights.append(w)
		wsum += w
	var want: Array[int] = []
	var acc := 0
	for l in layers:
		var c := int(round(total * weights[l] / wsum))
		if l == layers - 1:
			c = total - acc
		want.append(c)
		acc += c
	var chosen: Array = []  # per layer: Array[Vector2i]
	var carry := 0
	for l in layers:
		var target: int = want[l] + carry
		var got := _fill_layer(l, target, shape, chosen)
		chosen.append(got)
		carry = target - got.size()
	# Anything that didn't fit goes on the lower layers' free spots.
	var l2 := 0
	while carry > 0 and l2 < layers:
		var extra := _fill_layer(l2, chosen[l2].size() + carry, shape, chosen, chosen[l2])
		carry -= extra.size() - chosen[l2].size()
		chosen[l2] = extra
		l2 += 1
	slots.clear()
	for l in layers:
		for v in chosen[l]:
			slots.append(Vector3i(v.x, v.y, l))


func _fill_layer(l: int, target: int, shape: int, below: Array, start: Array = []) -> Array[Vector2i]:
	var got: Array[Vector2i] = []
	got.assign(start)
	if target <= got.size():
		return got
	var cands: Array[Dictionary] = []
	var seen := {}
	for v in _layer_positions(l):
		var m := Vector2i(10 - v.x, v.y)
		var key := Vector2i(mini(v.x, m.x), v.y)
		if seen.has(key) or got.has(v):
			continue
		seen[key] = true
		var support := 0
		if l > 0:
			for b in below[l - 1]:
				if absi(b.x - v.x) < 2 and absi(b.y - v.y) < 2:
					support += 1
			if support == 0:
				continue
		var score := _shape_score(v, shape) - support * 0.6 + rng.randf() * 1.6
		cands.append({"a": v, "b": m, "score": score})
	cands.sort_custom(func(x, y): return x.score < y.score)
	for c in cands:
		var need := target - got.size()
		if need <= 0:
			break
		if c.a == c.b:
			got.append(c.a)
		elif need >= 2:
			got.append(c.a)
			got.append(c.b)
		else:
			# One left: prefer a centre spot, else half a pair.
			var centre := false
			for c2 in cands:
				if c2.a == c2.b and not got.has(c2.a):
					got.append(c2.a)
					centre = true
					break
			if not centre:
				got.append(c.a)
	return got


func _shape_score(v: Vector2i, shape: int) -> float:
	var dx := absf(v.x - CENTER.x)
	var dy := absf(v.y - CENTER.y)
	match shape:
		0: return dx + dy * 0.8
		1: return sqrt(dx * dx + dy * dy)
		2: return maxf(dx, dy * 0.8)
		3: return dy * 1.4 + dx * 0.5
		_: return dx * 1.3 + dy * 0.4


func _build_cover() -> void:
	coverers.clear()
	covered.clear()
	for i in slots.size():
		coverers.append([])
		covered.append([])
	for i in slots.size():
		for j in slots.size():
			var a := slots[i]
			var b := slots[j]
			if a.z > b.z and absi(a.x - b.x) < 2 and absi(a.y - b.y) < 2:
				covered[i].append(j)
				coverers[j].append(i)


## A random order that only ever takes a slot nothing covers any more.
func _random_order() -> Array[int]:
	var left: Array[int] = []
	var avail: Array[int] = []
	for i in slots.size():
		left.append(coverers[i].size())
		if left[i] == 0:
			avail.append(i)
	var order: Array[int] = []
	while not avail.is_empty():
		var s: int = avail.pop_at(rng.randi_range(0, avail.size() - 1))
		order.append(s)
		for c in covered[s]:
			left[c] -= 1
			if left[c] == 0:
				avail.append(c)
	return order


## Glues side-by-side neighbours, moving the second one right after the first
## in the order. Only pairs where that keeps the order valid are used.
func _make_glue(order: Array[int], want: int) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	if want <= 0:
		return pairs
	var cands: Array[Vector2i] = []
	for a in slots.size():
		for b in slots.size():
			if slots[a].z == slots[b].z and slots[a].y == slots[b].y and slots[b].x == slots[a].x + 2:
				cands.append(Vector2i(a, b))
	_shuffle(cands)
	var used := {}
	for c in cands:
		if pairs.size() >= want:
			break
		if used.has(c.x) or used.has(c.y):
			continue
		var ta := order.find(c.x)
		var tb := order.find(c.y)
		var first := c.x if ta < tb else c.y
		var second := c.y if ta < tb else c.x
		var tf := mini(ta, tb)
		var ok := true
		for cv in coverers[second]:
			if order.find(cv) >= tf:
				ok = false
				break
		if not ok:
			continue
		order.erase(second)
		order.insert(order.find(first) + 1, second)
		used[c.x] = true
		used[c.y] = true
		pairs.append(Vector2i(first, second))
	return pairs


# --- Types -----------------------------------------------------------------

## A type for each pick, with triples interleaved so that taking the picks in
## order never holds more than MAX_HELD stickers or `mix` open triples.
func _type_sequence(n: int, type_count: int, mix: int) -> Array[int]:
	var bag: Array[int] = []
	for i in n / 3:
		bag.append(i % type_count)
	_shuffle(bag)
	var seq: Array[int] = []
	var open := {}
	var held := 0
	var guard := 0
	while seq.size() < n and guard < n * 20:
		guard += 1
		var new_type := -1
		if open.size() < mix and held + 1 <= MAX_HELD:
			for t in bag:
				if not open.has(t):
					new_type = t
					break
		var advance: Array = []
		for t in open:
			if open[t] == 2 or held + 1 <= MAX_HELD:
				advance.append(t)
		if new_type >= 0 and (advance.is_empty() or rng.randf() < 0.45):
			bag.erase(new_type)
			open[new_type] = 1
			held += 1
			seq.append(new_type)
		elif not advance.is_empty():
			var t: int = advance[rng.randi_range(0, advance.size() - 1)]
			open[t] += 1
			held += 1
			seq.append(t)
			if open[t] == 3:
				open.erase(t)
				held -= 3
		else:
			return []
	return seq if seq.size() == n else []


func _pick_types(count: int) -> Array:
	var shapes := SHAPES.duplicate()
	_shuffle(shapes)
	var colors: Array[int] = []
	for c in COLORS:
		colors.append(c)
	_shuffle(colors)
	var out := []
	for i in count:
		out.append({"shape": shapes[i], "color": colors[i]})
	return out


# --- Helpers ---------------------------------------------------------------

func _index_of_slot(ents: Array[Dictionary], s: int) -> int:
	for i in ents.size():
		if ents[i].k == "slot" and ents[i].s == s:
			return i
	return -1


## Moves an insertion point off the middle of a glued pair.
func _safe_cut(ents: Array[Dictionary], c: int, lo: int, hi: int) -> int:
	if c > 0 and c <= ents.size() and ents[c - 1].get("glued_next", false):
		if c + 1 <= hi:
			return c + 1
		if c - 1 >= lo:
			return c - 1
	return c


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
