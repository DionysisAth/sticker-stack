class_name AutoFinish
extends RefCounted
## Auto-finish: once no choice is left, the game peels the rest by itself in
## a fast chain. "No choice left" means:
## - every sticker still on the board is uncovered and can be peeled now
##   (no locks, ice, bubble wrap, hidden dispenser stickers),
## - no fuses or rainbows (their outcome depends on the order),
## - and no order of taps could fill the tray: with at most 2 of each type
##   held, the tray can never reach 7 without a triple.
## It also waits until most of the pile is gone, and skips the tutorial
## levels, so it never plays a level for the player.

## Only when at most this share of the level's stickers is left.
const MAX_LEFT_SHARE := 0.4
## Not on the tutorial levels.
const FIRST_LEVEL := 4
const MIN_TAPS := 2


## The taps that finish the level, in a nice order (triples back to back),
## or [] when auto-finish shouldn't start.
static func plan(st: BoardState, total_stickers: int) -> Array[int]:
	var none: Array[int] = []
	if st.status != BoardState.Status.PLAYING or st.level < FIRST_LEVEL:
		return none
	var left := 0
	var held := {}  # type -> stickers of that type on the board and in the tray
	for t in st.tray.types:
		held[t] = held.get(t, 0) + 1
	for s in st.stickers:
		if not s.alive:
			continue
		if not st.is_free(s) or s.wrapped or s.fuse > 0 or st.blocked_reason(s) != "":
			return none
		for t in [s.type] + Array(s.roll):
			held[t] = held.get(t, 0) + 1
			left += 1
	if left == 0 or held.has(Sticker.RAINBOW) or left > total_stickers * MAX_LEFT_SHARE:
		return none
	var worst := 0
	for t in held:
		worst += mini(2, held[t])
	if worst >= Tray.CAPACITY:
		return none
	# Any order works; the bot's order gives back-to-back triples.
	var sim := st.clone()
	var taps: Array[int] = []
	while sim.status == BoardState.Status.PLAYING and taps.size() < 500:
		var id := SolverBot.best_move(sim)
		if id < 0:
			break
		taps.append(id)
		sim.tap(id)
	if sim.status != BoardState.Status.WON or taps.size() < MIN_TAPS:
		return none
	return taps


## Stickers in a level at the start (roll stacks count each sticker).
static func total(st: BoardState) -> int:
	var n := 0
	for s in st.stickers:
		if not s.returned:
			n += s.count()
	return n
