extends Node
## Sound effects, synthesized at startup so the MVP needs no audio files:
## peel, land, pop, combo, warning, fail, clear and a few small ones.
## Every play gets a little pitch variation so repeats don't tire.

const RATE := 22050
const VOICES := 10

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build()


## Plays a sound. `pitch` lets combos climb; `vary` adds +-4% randomness.
func play(name: String, pitch := 1.0, volume_db := 0.0, vary := true) -> void:
	if not Save.setting("sound") or not _sounds.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.pitch_scale = pitch * (randf_range(0.96, 1.04) if vary else 1.0)
	p.volume_db = volume_db
	p.play()


func has_sound(name: String) -> bool:
	return _sounds.has(name)


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Peel: a short rising zip of filtered noise.
	_sounds["peel"] = _make(0.13, func(t: float, d: float) -> float:
		var env := sin(PI * t / d) * (1.0 - t / d)
		var chirp := sin(TAU * (900.0 + 2400.0 * t) * t) * 0.25
		return (rng.randf_range(-1, 1) * 0.55 + chirp) * env)
	# Land: a soft low thump.
	_sounds["land"] = _make(0.09, func(t: float, d: float) -> float:
		return sin(TAU * (190.0 - 500.0 * t) * t) * exp(-t * 45.0) * 0.8)
	# Pop: a bright bubble blip.
	_sounds["pop"] = _make(0.16, func(t: float, d: float) -> float:
		var f := 620.0 + 900.0 * t
		return (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t)) * exp(-t * 22.0) * 0.6)
	# Chime: the triple chime; the game raises its pitch for back-to-back triples.
	_sounds["chime"] = _make(0.35, func(t: float, d: float) -> float:
		var a := sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t) + 0.25 * sin(TAU * 1760.0 * t)
		return a * exp(-t * 9.0) * 0.35)
	# Warning: two low beeps.
	_sounds["warning"] = _make(0.32, func(t: float, d: float) -> float:
		var on := 1.0 if fmod(t, 0.16) < 0.09 else 0.0
		return signf(sin(TAU * 260.0 * t)) * 0.18 * on * exp(-fmod(t, 0.16) * 18.0))
	# Fail: a sad slide down.
	_sounds["fail"] = _make(0.6, func(t: float, d: float) -> float:
		var f := 440.0 - 260.0 * (t / d)
		return _tri(f * t) * (1.0 - t / d) * 0.45)
	# Clear: a happy arpeggio.
	var notes := [523.25, 659.25, 783.99, 1046.5]
	_sounds["clear"] = _make(0.62, func(t: float, d: float) -> float:
		var i := mini(int(t / 0.1), notes.size() - 1)
		var lt := t - i * 0.1
		var f: float = notes[i]
		return (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * exp(-lt * 6.0) * 0.4)
	# Blocked: a dull knock when tapping a covered sticker.
	_sounds["blocked"] = _make(0.08, func(t: float, d: float) -> float:
		return sin(TAU * 110.0 * t) * exp(-t * 50.0) * 0.7)
	# Bubble wrap pop: a sharp click.
	_sounds["wrap"] = _make(0.05, func(t: float, d: float) -> float:
		return rng.randf_range(-1, 1) * exp(-t * 120.0) * 0.9)
	# Unlock / thaw: a two-note ding.
	_sounds["unlock"] = _make(0.3, func(t: float, d: float) -> float:
		var f := 1046.5 if t < 0.1 else 1568.0
		return sin(TAU * f * t) * exp(-fmod(t, 0.1) * 10.0) * 0.35)
	# Button press.
	_sounds["click"] = _make(0.05, func(t: float, d: float) -> float:
		return sin(TAU * 700.0 * t) * exp(-t * 80.0) * 0.5)
	# Booster whoosh.
	_sounds["whoosh"] = _make(0.3, func(t: float, d: float) -> float:
		return rng.randf_range(-1, 1) * sin(PI * t / d) * 0.35)


func _make(duration: float, wave: Callable) -> AudioStreamWAV:
	var n := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var v := clampf(wave.call(t, duration), -1.0, 1.0)
		# Short fade in/out to avoid clicks.
		v *= minf(1.0, minf(i / 60.0, (n - i) / 60.0))
		data.encode_s16(i * 2, int(v * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


static func _tri(x: float) -> float:
	return 2.0 * absf(2.0 * (x - floorf(x + 0.5))) - 1.0
