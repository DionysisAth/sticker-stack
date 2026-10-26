class_name CardPicture
extends Control
## The one picture on a tutorial card: a few stickers showing the mechanic.

var mechanic := "basics"


static func make(id: String) -> CardPicture:
	var p := CardPicture.new()
	p.mechanic = id
	p.custom_minimum_size = Vector2(460, 210)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _ready() -> void:
	resized.connect(_build)
	_build()


func _sticker(at: Vector2, shape: String, color: int, size := 120.0) -> StickerView:
	var v := StickerView.new()
	v.size = size
	v.position = at
	v.set_type({"shape": shape, "color": color}, false, Save.setting("colorblind"))
	add_child(v)
	return v


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var c := size / 2.0
	match mechanic:
		"basics":
			for i in 3:
				_sticker(c + Vector2((i - 1) * 110, 0), "heart", 7)
		"layers":
			var under := _sticker(c + Vector2(-35, 15), "star", 2)
			under.set_dim(true, false)
			_sticker(c + Vector2(35, -10), "circle", 5)
		"tray":
			for i in 7:
				var v := _sticker(c + Vector2((i - 3) * 62, 0), ["star", "heart", "moon", "drop", "bolt", "flower", "cloud"][i], i, 64)
				v.z_index = 1
		"roll":
			var v := _sticker(c, "moon", 6)
			v.roll_count = 4
		"mystery":
			var v := _sticker(c + Vector2(-80, 0), "star", 2)
			v.face_down = true
			_sticker(c + Vector2(80, 0), "star", 2)
		"glue":
			var a := _sticker(c + Vector2(-60, 0), "drop", 5)
			var b := _sticker(c + Vector2(60, 0), "flower", 1)
			a.glue_dir = Vector2.RIGHT
			b.glue_dir = Vector2.LEFT
		"padlock":
			var v := _sticker(c + Vector2(-80, 0), "hexagon", 4)
			v.lock_info = {"shape": "heart", "color": 0}
			_sticker(c + Vector2(80, 0), "heart", 0, 90)
		"ice":
			var v := _sticker(c, "diamond", 3)
			v.ice = 3
		"wrap":
			var v := _sticker(c, "cloud", 7)
			v.wrapped = true
		"dispenser":
			var v := _sticker(c, "square", 0)
			v.queue_depth = 3
		"rainbow":
			_sticker(c + Vector2(-120, 0), "triangle", 1, 100)
			_sticker(c + Vector2(-10, 0), "triangle", 1, 100)
			var r := _sticker(c + Vector2(110, 0), "star", 0, 110)
			r.rainbow = true
		"fuse":
			var v := _sticker(c, "bolt", 2)
			v.fuse = 3
