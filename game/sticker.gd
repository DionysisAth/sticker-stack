class_name Sticker
extends RefCounted
## One sticker on the board. Plain data: the rules in game/rules/ read and
## change these fields, the view only draws them.

const RAINBOW := -1

var id := 0
## Index into the level's type list, or RAINBOW.
var type := 0
## Position on the half-step grid (12 x 14) and layer. A sticker spans 2 x 2 steps.
var x := 0
var y := 0
var z := 0
var alive := true
## Mechanic name ("" for a plain sticker). One mechanic per sticker.
var kind := ""

# Mechanic data. Only the field matching `kind` is used.
var roll: Array[int] = []      # roll: the types under the top one, next first
var hidden := false            # mystery: face down until uncovered
var pair := -1                 # glue: id of the partner sticker
var key := -1                  # padlock: type whose triple opens it (-1 = open)
var ice := 0                   # ice: picks left until it thaws
var wrapped := false           # bubble wrap: true until the first tap pops it
var queue := -1                # dispenser: 0 = left, 1 = right, -1 = on the board
var order := 0                 # dispenser: place in the queue, front first
var fuse := 0                  # fuse: picks left before it burns out (0 = none)
var returned := false          # put back on the pile by the Return 3 booster


func on_board() -> bool:
	return queue < 0


func count() -> int:
	return 1 + roll.size()


func overlaps(other: Sticker) -> bool:
	return absi(x - other.x) < 2 and absi(y - other.y) < 2


func copy() -> Sticker:
	var s := Sticker.new()
	s.id = id
	s.type = type
	s.x = x
	s.y = y
	s.z = z
	s.alive = alive
	s.kind = kind
	s.roll = roll.duplicate()
	s.hidden = hidden
	s.pair = pair
	s.key = key
	s.ice = ice
	s.wrapped = wrapped
	s.queue = queue
	s.order = order
	s.fuse = fuse
	s.returned = returned
	return s


## Level-file form. Only fields that matter for this sticker's kind are written.
func to_dict() -> Dictionary:
	var d := {"type": type}
	if queue < 0:
		d["x"] = x
		d["y"] = y
		d["z"] = z
	match kind:
		"roll":
			d["roll"] = roll.duplicate()
		"mystery":
			pass
		"glue":
			d["pair"] = pair
		"padlock":
			d["key"] = key
		"ice":
			d["ice"] = ice
		"wrap":
			pass
		"dispenser":
			d["queue"] = queue
			d["order"] = order
		"rainbow":
			d["type"] = RAINBOW
		"fuse":
			d["fuse"] = fuse
	if kind != "":
		d["kind"] = kind
	return d


static func from_dict(d: Dictionary, sticker_id: int) -> Sticker:
	var s := Sticker.new()
	s.id = sticker_id
	s.type = int(d.get("type", 0))
	s.x = int(d.get("x", 0))
	s.y = int(d.get("y", 0))
	s.z = int(d.get("z", 0))
	s.kind = String(d.get("kind", ""))
	match s.kind:
		"roll":
			for t in d.get("roll", []):
				s.roll.append(int(t))
		"mystery":
			s.hidden = true
		"glue":
			s.pair = int(d.get("pair", -1))
		"padlock":
			s.key = int(d.get("key", -1))
		"ice":
			s.ice = int(d.get("ice", 0))
		"wrap":
			s.wrapped = true
		"dispenser":
			s.queue = int(d.get("queue", 0))
			s.order = int(d.get("order", 0))
		"rainbow":
			s.type = RAINBOW
		"fuse":
			s.fuse = int(d.get("fuse", 0))
	return s
