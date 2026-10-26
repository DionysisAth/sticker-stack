class_name SolverBot
extends RefCounted
## A simple greedy player. It plays a level many times with a little
## randomness; its win rate is the level's measured difficulty.
##
## Each turn it scores every sticker it could tap: finishing a triple is best,
## adding to a pair is good, filling the tray is bad, and uncovering stickers
## or saving a burning fuse helps. Random noise breaks ties.

const NOISE := 30.0


## Plays one game from `start` (which is not changed). True if it won.
static func play_once(start: BoardState, rng: RandomNumberGenerator, noise := NOISE) -> bool:
	var st := start.clone()
	var guard := 0
	while st.status == BoardState.Status.PLAYING and guard < 2000:
		guard += 1
		var best := _choose(st, rng, noise)
		if best < 0:
			break
		st.tap(best)
	return st.status == BoardState.Status.WON


static func _choose(st: BoardState, rng: RandomNumberGenerator, noise: float) -> int:
	var counts := {}
	for t in st.tray.types:
		counts[t] = counts.get(t, 0) + 1
	var pairs := 0
	for k in counts:
		if k != Sticker.RAINBOW and counts[k] == 2:
			pairs += 1
	var best := -1
	var best_score := -INF
	for s in st.stickers:
		if not s.alive or not st.is_free(s):
			continue
		var score := 0.0
		if s.wrapped:
			score = 15.0
		elif st.blocked_reason(s) != "":
			continue
		else:
			score = _score(st, s, counts, pairs)
		if rng != null:
			score += rng.randf() * noise
		if score > best_score:
			best_score = score
			best = s.id
	return best


## The move the bot likes best, with no randomness (used for the tutorial
## hand). -1 if there is none.
static func best_move(st: BoardState) -> int:
	return _choose(st, null, 0.0)


## Share of `runs` games won, from 0 to 1. Deterministic for a given seed.
static func win_rate(start: BoardState, runs: int, seed: int = 1) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var wins := 0
	for i in runs:
		if play_once(start, rng):
			wins += 1
	return float(wins) / float(maxi(runs, 1))


## The taps of a game the bot won, or [] if none of `tries` games was won.
## The level editor uses it to store a winning order for hand-made levels.
static func find_solution(start: BoardState, tries: int, seed: int = 1) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in tries:
		var st := start.clone()
		var taps: Array[int] = []
		while st.status == BoardState.Status.PLAYING and taps.size() < 2000:
			var best := _choose(st, rng, NOISE if i % 2 == 0 else NOISE * 3.0)
			if best < 0:
				break
			taps.append(best)
			st.tap(best)
		if st.status == BoardState.Status.WON:
			return taps
	return []


## True if any of `tries` games is won. Used by Shuffle.
static func can_win(start: BoardState, tries: int, seed: int = 1) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in tries:
		# Mostly careful games, with a few noisier ones to explore.
		if play_once(start, rng, NOISE if i % 2 == 0 else NOISE * 3.0):
			return true
	return false


static func _score(st: BoardState, s: Sticker, counts: Dictionary, pairs: int) -> float:
	var score := 0.0
	var cleared := 0
	var added := 1
	var rainbows: int = counts.get(Sticker.RAINBOW, 0)
	if s.pair >= 0 and st.stickers[s.pair].alive:
		# Glued pair: simulate both on a copy of the counts.
		added = 2
		var c2 := counts.duplicate()
		for t in [s.type, st.stickers[s.pair].type]:
			var r := _add(c2, t)
			score += r.x
			cleared += int(r.y)
	else:
		var t := s.type
		if t == Sticker.RAINBOW:
			if pairs > 0:
				score += 90.0
				cleared += 1
			else:
				score -= 30.0
		else:
			var c: int = counts.get(t, 0)
			if c == 2:
				score += 100.0
				cleared += 1
			elif c == 1 and rainbows > 0:
				score += 90.0
				cleared += 1
			elif c == 1:
				score += 40.0
	var after := st.tray.size() + added - cleared * 3
	if after >= Tray.CAPACITY:
		score -= 1000.0
	elif after == Tray.CAPACITY - 1:
		score -= 40.0
	elif after == Tray.CAPACITY - 2:
		score -= 15.0
	if s.roll.is_empty() and s.on_board():
		for i in st.covered_by(s.id):
			if st.cover_count(i) == 1 and st.stickers[i].alive:
				score += 8.0
	if s.fuse > 0:
		score += 70.0 if s.fuse <= 2 else 10.0
	return score


## Adds one sticker of type t to simulated tray counts. Returns (score, cleared).
static func _add(counts: Dictionary, t: int) -> Vector2:
	if t == Sticker.RAINBOW:
		for k in counts:
			if k != Sticker.RAINBOW and counts[k] == 2:
				counts[k] = 0
				return Vector2(90, 1)
		counts[t] = counts.get(t, 0) + 1
		return Vector2(-30, 0)
	var c: int = counts.get(t, 0)
	if c == 2:
		counts[t] = 0
		return Vector2(100, 1)
	if c == 1 and counts.get(Sticker.RAINBOW, 0) > 0:
		counts[t] = 0
		counts[Sticker.RAINBOW] -= 1
		return Vector2(90, 1)
	counts[t] = c + 1
	return Vector2(40 if c == 1 else 0, 0)
