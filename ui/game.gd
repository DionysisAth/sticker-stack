extends Control
## The game screen: board, tray and boosters, plus the clear, fail, Hard and
## tutorial cards. Clearing a level starts the next one right here.

const FLY_TIME := 0.2
const BOOSTER_INFO := [["undo", "Undo"], ["return3", "Return 3"], ["shuffle", "Shuffle"]]
const BLOCK_TIPS := {
	"locked": "Clear the key triple to open it",
	"frozen": "Frozen! Thaws in %d picks",
	"glued": "Free its partner first",
}
const FAIL_TITLES := {
	"tray_full": "Out of room",
	"no_moves": "No moves left",
	"fuse": "The fuse burned out",
}

var level_n := 1
var level: Dictionary
var state: BoardState
## Playing a level from the editor: nothing is saved.
var test_mode := false

var board: BoardView
var tray_view: TrayView
var fx: Node2D
var cards: Control
var level_label: Label
var hard_tag: Label
var bg: TextureRect
var booster_buttons := {}

var tray_nodes := {}       # tray uid -> StickerView
var _popping := {}
var _attempt := 0
var _t_start := 0.0
var _boosters_used := 0
var _combo := 0
var _last_clear_pick := -10
var _danger := 0
var _hint: PointerHand
var _hint_picks_left := 0
var _card: Card
var _ended := false


func _ready() -> void:
	_build_ui()
	test_mode = Nav.params.has("level_data")
	level_n = int(Nav.params.get("level", Save.level))
	start_level(level_n)


# --- Layout ----------------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := Screen.safe_margins(self)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16 + int(safe.x))
	margin.add_theme_constant_override("margin_bottom", 16 + int(safe.y))
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	# Top bar: home, level, (spacer of the same size).
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 92)
	col.add_child(top)
	var home := IconButton.make("home", 84)
	home.pressed.connect(_on_home)
	top.add_child(home)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 0)
	top.add_child(mid)
	level_label = UITheme.label("Level 1", 46, UITheme.INK, true)
	mid.add_child(level_label)
	hard_tag = UITheme.label("HARD", 24, Color.WHITE, true)
	var tag_box := StyleBoxFlat.new()
	tag_box.bg_color = UITheme.DANGER
	tag_box.set_corner_radius_all(14)
	tag_box.content_margin_left = 16
	tag_box.content_margin_right = 16
	hard_tag.add_theme_stylebox_override("normal", tag_box)
	hard_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid.add_child(hard_tag)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(84, 84)
	top.add_child(spacer)

	board = BoardView.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.sticker_tapped.connect(_on_sticker_tapped)
	col.add_child(board)

	tray_view = TrayView.new()
	tray_view.custom_minimum_size = Vector2(0, 124)
	col.add_child(tray_view)

	var boosters := HBoxContainer.new()
	boosters.alignment = BoxContainer.ALIGNMENT_CENTER
	boosters.add_theme_constant_override("separation", 46)
	boosters.custom_minimum_size = Vector2(0, 150)
	col.add_child(boosters)
	for info in BOOSTER_INFO:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var b := IconButton.make(info[0], 104, UITheme.GO, UITheme.GO_DARK)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(_use_booster.bind(info[0]))
		v.add_child(b)
		v.add_child(UITheme.label(info[1], 24, UITheme.INK, true))
		boosters.add_child(v)
		booster_buttons[info[0]] = b

	fx = Node2D.new()
	fx.z_index = 10
	add_child(fx)
	cards = Control.new()
	cards.set_anchors_preset(Control.PRESET_FULL_RECT)
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards)


# --- Level flow ------------------------------------------------------------

func start_level(n: int) -> void:
	level_n = n
	_ended = false
	for node in tray_nodes.values():
		node.queue_free()
	tray_nodes.clear()
	_popping.clear()
	if _card != null:
		_card.queue_free()
		_card = null
	if _hint != null:
		_hint.queue_free()
		_hint = null
	level = Nav.params.level_data if test_mode else LevelData.load_level(n)
	state = BoardState.from_level(level)
	board.colorblind = Save.setting("colorblind")
	board.setup(state)
	_set_backdrop(n)
	level_label.text = "Level %d" % n
	hard_tag.visible = bool(level.get("hard", false))
	_attempt = Save.start_attempt() if not test_mode else 1
	Analytics.track("level_start", {"level": n, "attempt": _attempt})
	_t_start = Time.get_ticks_msec() / 1000.0
	_boosters_used = 0
	_combo = 0
	_danger = 0
	tray_view.set_fill(0)
	_hint_picks_left = 3 if n <= 3 else 0
	_update_boosters()
	_drop_in()
	_intro_cards()


func retry() -> void:
	start_level(level_n)


func _intro_cards() -> void:
	if bool(level.get("hard", false)):
		await _show_hard_card()
	var tut := String(level.get("tutorial", ""))
	if tut != "" and (not Save.seen_cards.has(tut) or test_mode):
		await _show_tutorial(tut)
	_update_hint()


func _drop_in() -> void:
	if Save.setting("reduce_motion"):
		return
	var i := 0
	for id in board.views:
		var v: StickerView = board.views[id]
		v.scale = Vector2.ZERO
		var t := v.create_tween()
		t.tween_interval(0.012 * i + 0.02 * state.stickers[id].z)
		t.tween_property(v, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


func _set_backdrop(n: int) -> void:
	var cols := UITheme.backdrop(n)
	var g := Gradient.new()
	g.colors = PackedColorArray([cols[0], cols[1]])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	bg.texture = tex


# --- Input and events ------------------------------------------------------

func _on_sticker_tapped(id: int) -> void:
	if _card != null or _ended or state.status != BoardState.Status.PLAYING:
		return
	state.tap(id)
	_process_events()


func _process_events() -> void:
	for e in state.drain_events():
		match e.e:
			"blocked":
				_on_blocked(e)
			"wrap_pop":
				Audio.play("wrap")
				Haptics.tick()
				_burst_at_sticker(e.id, [Color.WHITE, Color("#cdeeff")], 10)
			"pick":
				_fly(e)
			"clear":
				_pop_triple(e)
			"reveal":
				_flip(e.id)
			"unlock", "thaw":
				Audio.play("unlock")
				_burst_at_sticker(e.id, [Color("#ffe066"), Color.WHITE], 12)
			"rainbowed":
				Audio.play("unlock", 1.3)
				_burst_at_sticker(e.id, UITheme.STICKER_COLORS, 20)
				Fx.float_text(fx, fx.to_local(board.sticker_global_pos(e.id)) + Vector2(0, -70), "Rainbow!", UITheme.ACCENT_DARK)
			"failed":
				_on_failed(e)
			"won":
				_on_won()
	# Stickers that came back from the tray (Undo, Return 3) fly from it.
	var orphans: Array[StickerView] = []
	for uid in tray_nodes.keys():
		if not state.tray.uids.has(uid) and not _popping.has(uid):
			orphans.append(tray_nodes[uid])
			tray_nodes.erase(uid)
	var created := board.sync(true)
	for i in created.size():
		var v := board.view_of(created[i])
		if v == null:
			continue
		var target := v.position
		if i < orphans.size():
			v.global_position = orphans[i].global_position
		else:
			v.scale = Vector2(0.2, 0.2)
		var t := v.create_tween()
		t.tween_property(v, "position", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(v, "scale", Vector2.ONE, 0.25)
	for o in orphans:
		o.queue_free()
	_layout_tray()
	_update_danger()
	_update_boosters()
	_update_hint()


func _on_blocked(e: Dictionary) -> void:
	var v := board.view_of(e.id)
	Audio.play("blocked")
	if v != null:
		# Shake around its resting spot, so quick repeated taps don't drift.
		var x := v.get_parent().to_local(board.sticker_global_pos(e.id)).x
		var t := v.create_tween()
		for k in [10.0, -8.0, 5.0, 0.0]:
			t.tween_property(v, "position:x", x + k, 0.04)
	var tip := String(BLOCK_TIPS.get(e.reason, ""))
	if tip != "":
		if e.reason == "frozen":
			tip = tip % state.stickers[e.id].ice
		Fx.float_text(fx, fx.to_local(board.sticker_global_pos(e.id)) + Vector2(0, -70), tip)


## Peel the sticker off the board and fly it into the tray.
func _fly(e: Dictionary) -> void:
	_hint_picks_left = maxi(0, _hint_picks_left - 1)
	var v: StickerView
	var start := board.sticker_global_pos(e.id)
	if not e.stays:
		v = board.take_view(e.id)
	if v == null:
		v = StickerView.new()
		v.size = board.sticker_size()
		fx.add_child(v)
	else:
		v.get_parent().remove_child(v)
		fx.add_child(v)
	v.global_position = start
	var info: Dictionary = {} if e.type == Sticker.RAINBOW else state.types[e.type]
	v.set_type(info, e.type == Sticker.RAINBOW, Save.setting("colorblind"))
	v.face_down = false
	v.roll_count = 0
	v.lock_info = {}
	v.ice = 0
	v.wrapped = false
	v.fuse = 0
	v.glue_dir = Vector2.ZERO
	v.queue_depth = 0
	v.visible = true
	v.set_dim(false, false)
	v.z_index = 300
	v.queue_redraw()
	v.set_meta("landed", false)
	tray_nodes[e.uid] = v
	var idx: int = state.tray.uids.find(e.uid)
	if idx < 0:
		idx = e.index
	var p0 := fx.to_local(start)
	var p1 := fx.to_local(tray_view.slot_global(idx))
	var k := tray_view.slot_size() / maxf(v.size, 1.0) * 1.05
	Audio.play("peel")
	Haptics.tick()
	var t := v.create_tween()
	if Save.setting("reduce_motion"):
		t.tween_property(v, "position", p1, 0.12)
		t.parallel().tween_property(v, "scale", Vector2(k, k), 0.12)
	else:
		# Curl a corner and lift, arc into the tray, squash on landing.
		t.tween_property(v, "skew", 0.35, 0.05)
		t.parallel().tween_property(v, "scale", Vector2(1.12, 1.12), 0.05)
		t.parallel().tween_property(v, "rotation", -0.2, 0.05)
		var ctrl := (p0 + p1) / 2.0 + Vector2(0, -180)
		var arc := func(f: float) -> void:
			var a := p0.lerp(ctrl, f)
			var b := ctrl.lerp(p1, f)
			v.position = a.lerp(b, f)
			v.scale = Vector2.ONE * lerpf(1.12, k, f)
			v.rotation = lerpf(-0.2, 0.0, f)
			v.skew = lerpf(0.35, 0.0, f)
		t.tween_method(arc, 0.0, 1.0, FLY_TIME).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(v, "scale", Vector2(k * 1.18, k * 0.8), 0.05)
		t.tween_property(v, "scale", Vector2(k, k), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var land := func() -> void:
		v.set_meta("landed", true)
		Audio.play("land", 1.0, -8.0)
		_layout_tray()
	t.tween_callback(land)


func _layout_tray() -> void:
	for i in state.tray.uids.size():
		var uid: int = state.tray.uids[i]
		var v: StickerView = tray_nodes.get(uid)
		if v == null or not v.get_meta("landed", false):
			continue
		var target := fx.to_local(tray_view.slot_global(i))
		if v.position.distance_to(target) > 0.5:
			var t := v.create_tween()
			t.tween_property(v, "position", target, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pop_triple(e: Dictionary) -> void:
	for uid in e.uids:
		_popping[uid] = true
	if state.picks - _last_clear_pick <= 2:
		_combo += 1
	else:
		_combo = 0
	_last_clear_pick = state.picks
	var combo := _combo
	await get_tree().create_timer(FLY_TIME + 0.12).timeout
	if not is_inside_tree():
		return
	var center := Vector2.ZERO
	var n := 0
	for uid in e.uids:
		var v: StickerView = tray_nodes.get(uid)
		if v == null:
			continue
		center += v.position
		n += 1
		tray_nodes.erase(uid)
		var t := v.create_tween()
		t.tween_property(v, "scale", v.scale * 1.35, 0.1)
		t.tween_property(v, "scale", Vector2.ZERO, 0.12)
		t.parallel().tween_property(v, "modulate:a", 0.0, 0.12)
		t.tween_callback(v.queue_free)
	for uid in e.uids:
		_popping.erase(uid)
	var col := Color.WHITE
	if e.type != Sticker.RAINBOW and e.type < state.types.size():
		col = UITheme.sticker_color(int(state.types[e.type].color))
	if n > 0:
		Fx.confetti(fx, center / n, [col, col.lightened(0.4), Color.WHITE], 28)
	Audio.play("chime", 1.0 + 0.12 * mini(combo, 6))
	Audio.play("pop", 1.0 + 0.08 * mini(combo, 6), -4.0)
	Haptics.tap()
	if combo >= 2:
		Fx.float_text(fx, center / maxf(n, 1) + Vector2(0, -90), "Combo x%d!" % (combo + 1), UITheme.ACCENT_DARK)
	_layout_tray()


func _flip(id: int) -> void:
	var v := board.view_of(id)
	if v == null or Save.setting("reduce_motion"):
		return
	var t := v.create_tween()
	t.tween_property(v, "scale:x", 0.0, 0.08)
	t.tween_property(v, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _burst_at_sticker(id: int, colors: Array, amount: int) -> void:
	if id < 0 or id >= state.stickers.size():
		return
	Fx.confetti(fx, fx.to_local(board.sticker_global_pos(id)), colors, amount, 0.5)


func _update_danger() -> void:
	var n := state.tray.size()
	tray_view.set_fill(n)
	if n >= Tray.CAPACITY - 2 and n > _danger and state.status == BoardState.Status.PLAYING:
		Haptics.heartbeat(n >= Tray.CAPACITY - 1)
		Audio.play("warning", 1.0 if n == Tray.CAPACITY - 2 else 1.25, -6.0)
	_danger = n


func _update_hint() -> void:
	var show := _hint_picks_left > 0 and _card == null and state.status == BoardState.Status.PLAYING
	var id := SolverBot.best_move(state) if show else -1
	if id < 0:
		if _hint != null:
			_hint.queue_free()
			_hint = null
		return
	if _hint == null:
		_hint = PointerHand.new()
		_hint.z_index = 400
		fx.add_child(_hint)
	_hint.position = fx.to_local(board.sticker_global_pos(id))


# --- Win and fail ----------------------------------------------------------

func _on_won() -> void:
	_ended = true
	var seconds := Time.get_ticks_msec() / 1000.0 - _t_start
	Analytics.track("level_clear", {
		"level": level_n, "attempts": _attempt, "picks": state.picks,
		"boosters_used": _boosters_used, "seconds": snappedf(seconds, 0.1),
	})
	var reward := "" if test_mode else Save.complete_level()
	await get_tree().create_timer(FLY_TIME + 0.35).timeout
	if not is_inside_tree():
		return
	Audio.play("clear")
	Haptics.tap()
	var mid := size / 2.0
	Fx.confetti(fx, mid + Vector2(-180, 0), UITheme.STICKER_COLORS, 60, 1.4)
	Fx.confetti(fx, mid + Vector2(180, 0), UITheme.STICKER_COLORS, 60, 1.4)
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree():
		_show_clear_card(reward)


func _on_failed(e: Dictionary) -> void:
	var tray_types: Array = []
	for t in state.tray.types:
		tray_types.append(t)
	Analytics.track("level_fail", {
		"level": level_n, "attempt": _attempt, "reason": e.reason,
		"stickers_left": state.stickers_left(), "tray": tray_types,
	})
	Audio.play("fail")
	Haptics.double_buzz()
	if e.reason == "fuse":
		_burst_at_sticker(e.id, [UITheme.DANGER, Color("#ffcc33")], 30)
	await get_tree().create_timer(FLY_TIME + 0.45).timeout
	if is_inside_tree() and state.status == BoardState.Status.FAILED:
		_show_fail_card(e.reason)


# --- Cards -----------------------------------------------------------------

func _open_card(width := 600.0) -> Card:
	if _card != null:
		_card.queue_free()
	_card = Card.make(cards, width)
	_update_hint()
	return _card


func _close_card() -> void:
	if _card != null:
		_card.close()
		_card = null
	_update_hint()


func _show_clear_card(reward: String) -> void:
	var c := _open_card()
	c.box.add_child(UITheme.label("Level %d cleared!" % level_n, 50, UITheme.INK, true))
	if reward != "":
		var name := ""
		for info in BOOSTER_INFO:
			if info[0] == reward:
				name = info[1]
		c.box.add_child(UITheme.label("+1 %s booster" % name, 30, UITheme.GO_DARK, true))
	var next := UITheme.button("Next", UITheme.GO, UITheme.GO_DARK, 44)
	next.custom_minimum_size = Vector2(0, 116)
	next.pressed.connect(_on_next)
	c.box.add_child(next)
	Card.bounce_in(next, 0.25)
	var upcoming := level_n + 1
	var intro := Mechanics.next_intro_after(level_n)
	if intro > 0:
		var left := intro - upcoming
		var text := "New sticker trick next level!" if left == 0 else "New sticker trick in %d level%s" % [left, "" if left == 1 else "s"]
		c.box.add_child(UITheme.label(text, 28, UITheme.INK_SOFT))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 26)
		bar.max_value = 5
		bar.value = clampi(5 - left, 0, 5)
		bar.show_percentage = false
		c.box.add_child(bar)
	if Difficulty.is_hard(upcoming):
		c.box.add_child(UITheme.label("Next up: a Hard level", 28, UITheme.DANGER, true))


func _show_fail_card(reason: String) -> void:
	var c := _open_card()
	c.box.add_child(UITheme.label(String(FAIL_TITLES.get(reason, "Out of room")), 50, UITheme.INK, true))
	c.box.add_child(UITheme.label("Same pile, same chance. You've got this!", 28, UITheme.INK_SOFT))
	var again := UITheme.button("Try again", UITheme.GO, UITheme.GO_DARK, 42)
	again.custom_minimum_size = Vector2(0, 110)
	var on_again := func() -> void:
		_close_card()
		retry()
	again.pressed.connect(on_again)
	c.box.add_child(again)
	var helps: Array = []
	if state.can_undo():
		helps.append(["undo", "Undo"])
	if state.can_return():
		helps.append(["return3", "Return 3"])
	if not helps.is_empty():
		c.box.add_child(UITheme.label("or use a booster", 26, UITheme.INK_SOFT))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		c.box.add_child(row)
		for h in helps:
			var stock := int(Save.boosters.get(h[0], 0))
			var b := UITheme.button("%s (%d)" % [h[1], stock], UITheme.SKY, UITheme.SKY_DARK, 30)
			b.custom_minimum_size = Vector2(220, 90)
			b.disabled = stock <= 0
			var use := func(which: String) -> void:
				_close_card()
				_use_booster(which)
			b.pressed.connect(use.bind(h[0]))
			row.add_child(b)


func _show_hard_card() -> void:
	var c := _open_card()
	c.box.add_child(UITheme.label("Hard level", 54, UITheme.DANGER, true))
	c.box.add_child(UITheme.label("Take your time. A retry always gives the same pile.", 28, UITheme.INK_SOFT))
	var go := UITheme.button("Let's go", UITheme.ACCENT, UITheme.ACCENT_DARK, 40)
	go.pressed.connect(_close_card)
	c.box.add_child(go)
	await c.closed


func _show_tutorial(id: String) -> void:
	var info := Mechanics.card_for(level_n)
	if info.is_empty() or info.id != id:
		for m in Mechanics.LIST:
			if m.id == id:
				info = m
		for k in Mechanics.BASICS:
			if Mechanics.BASICS[k].id == id:
				info = Mechanics.BASICS[k]
	var opened := Time.get_ticks_msec() / 1000.0
	var c := _open_card()
	c.box.add_child(UITheme.label(String(info.get("title", "")), 46, UITheme.INK, true))
	c.box.add_child(CardPicture.make(id))
	c.box.add_child(UITheme.label(String(info.get("tip", "")), 30, UITheme.INK))
	var ok := UITheme.button("Got it", UITheme.GO, UITheme.GO_DARK, 40)
	ok.pressed.connect(_close_card)
	c.box.add_child(ok)
	await c.closed
	Save.mark_card_seen(id)
	Analytics.track("tutorial_seen", {"mechanic": id, "seconds": snappedf(Time.get_ticks_msec() / 1000.0 - opened, 0.1)})


func _on_next() -> void:
	_close_card()
	if test_mode:
		Nav.go("editor", Nav.params)
		return
	start_level(Save.level)


func _on_home() -> void:
	if test_mode:
		Nav.go("editor", Nav.params)
	else:
		Nav.go("home")


# --- Boosters --------------------------------------------------------------

func _use_booster(id: String) -> void:
	if _ended or (_card != null):
		return
	if not Save.has_booster(id):
		Fx.float_text(fx, fx.to_local(booster_buttons[id].get_global_rect().get_center()) + Vector2(0, -90), "None left")
		return
	var before := state.tray.size()
	var ok := false
	match id:
		"undo":
			ok = state.undo()
		"return3":
			ok = state.return_three()
		"shuffle":
			ok = state.shuffle()
			if not ok:
				Fx.float_text(fx, fx.to_local(board.get_global_rect().get_center()), "No better mix found")
	if not ok:
		return
	Save.spend_booster(id)
	_boosters_used += 1
	Analytics.track("booster_used", {"level": level_n, "booster": id, "tray_fill": before})
	Audio.play("whoosh")
	if id == "shuffle":
		for v: StickerView in board.views.values():
			var t := v.create_tween()
			t.tween_property(v, "rotation", 0.25, 0.08)
			t.tween_property(v, "rotation", -0.2, 0.1)
			t.tween_property(v, "rotation", 0.0, 0.08)
	_process_events()


func _update_boosters() -> void:
	if state == null:
		return
	for id in booster_buttons:
		var b: IconButton = booster_buttons[id]
		b.set_count(int(Save.boosters.get(id, 0)))
		var usable := false
		match id:
			"undo":
				usable = state.can_undo()
			"return3":
				usable = state.can_return()
			"shuffle":
				usable = state.can_shuffle()
		b.disabled = not usable or _ended
