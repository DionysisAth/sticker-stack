class_name Mechanics
extends RefCounted
## The mechanics roadmap: one new mechanic every 5 levels. Each entry is the
## level it arrives at, its card title and its one line of text.

const LIST: Array[Dictionary] = [
	{"id": "roll", "level": 6, "title": "Sticker rolls",
		"tip": "A roll is a stack. Peel the top one to see the next."},
	{"id": "mystery", "level": 11, "title": "Mystery stickers",
		"tip": "Face-down stickers turn over once nothing covers them."},
	{"id": "glue", "level": 16, "title": "Glued pairs",
		"tip": "Glued stickers come off together and take two tray slots."},
	{"id": "padlock", "level": 21, "title": "Padlocks",
		"tip": "Clear a triple of the key sticker to open the lock."},
	{"id": "ice", "level": 26, "title": "Ice",
		"tip": "Frozen stickers thaw after you peel the number shown."},
	{"id": "wrap", "level": 31, "title": "Bubble wrap",
		"tip": "Tap once to pop the wrap, then again to peel."},
	{"id": "dispenser", "level": 36, "title": "Side dispensers",
		"tip": "Only the front sticker of each dispenser can be taken."},
	{"id": "rainbow", "level": 41, "title": "Rainbow sticker",
		"tip": "A rainbow completes any pair. Pick your moment."},
	{"id": "fuse", "level": 46, "title": "Fuse",
		"tip": "Peel a fuse sticker before its count runs out!"},
]

## Tutorial cards for the first three levels (one rule per level).
const BASICS: Dictionary = {
	1: {"id": "basics", "title": "Peel and match",
		"tip": "Tap a sticker to peel it. Three alike in the tray clear."},
	2: {"id": "layers", "title": "Covered stickers",
		"tip": "Dimmed stickers are covered. Peel the ones on top first."},
	3: {"id": "tray", "title": "Watch the tray",
		"tip": "The tray holds 7. If it fills up, you're out of room."},
}


## The tutorial card for a level ({} if none): a basics card or a mechanic intro.
static func card_for(level: int) -> Dictionary:
	if BASICS.has(level):
		return BASICS[level]
	for m in LIST:
		if m.level == level:
			return m
	return {}


## Mechanic ids available at a level (introduced at or before it).
static func unlocked(level: int) -> Array[String]:
	var out: Array[String] = []
	for m in LIST:
		if m.level <= level:
			out.append(m.id)
	return out


## The mechanic introduced exactly at this level, or "".
static func intro_at(level: int) -> String:
	for m in LIST:
		if m.level == level:
			return m.id
	return ""


## The level number where the next new mechanic arrives, or -1.
static func next_intro_after(level: int) -> int:
	for m in LIST:
		if m.level > level:
			return m.level
	return -1


static func title(id: String) -> String:
	for m in LIST:
		if m.id == id:
			return m.title
	return id.capitalize()
