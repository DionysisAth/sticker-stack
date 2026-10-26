class_name Rule
extends RefCounted
## Base class for a mechanic. A board only creates the rules whose `kind`
## appears in its level, so plain levels pay nothing for mechanics.
## Rules hold no per-board state, so cloned boards can share them.

var kind := ""


## The hook names this rule implements, so the board only calls what's used.
func hooks() -> Array[String]:
	return []


## Called once after the level is loaded.
func on_start(_state: BoardState) -> void:
	pass


## Override the free/covered test: 1 = free, 0 = not free, -1 = no opinion.
func is_free(_state: BoardState, _s: Sticker) -> int:
	return -1


## Why a free sticker can't be picked yet ("" = it can).
func blocked_reason(_state: BoardState, _s: Sticker) -> String:
	return ""


## Lets a rule use up a tap without picking (bubble wrap). True = tap used.
func on_tap(_state: BoardState, _s: Sticker) -> bool:
	return false


## Other stickers that come off together with `s` (glued pairs).
func extra_picks(_state: BoardState, _s: Sticker) -> Array[Sticker]:
	return []


## Called as `s` is peeled. True = the sticker stays on the board (rolls).
func take(_state: BoardState, _s: Sticker) -> bool:
	return false


## Called after a pick and its triple (if any) resolved.
func after_pick(_state: BoardState, _picked: Array[Sticker]) -> void:
	pass


## Called when a triple clears. `cleared` is {"type", "uids", "rainbows"}.
func after_clear(_state: BoardState, _cleared: Dictionary) -> void:
	pass
