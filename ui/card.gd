class_name Card
extends Control
## A centred overlay card with a dimmed backdrop that bounces in.
## Add content to `box` (a VBoxContainer).

signal closed

var panel: PanelContainer
var box: VBoxContainer


static func make(parent: Control, width := 600.0) -> Card:
	var c := Card.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(c)
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.08, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(center)
	c.panel = PanelContainer.new()
	c.panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(c.panel)
	c.box = VBoxContainer.new()
	c.box.add_theme_constant_override("separation", 22)
	c.box.alignment = BoxContainer.ALIGNMENT_CENTER
	c.panel.add_child(c.box)
	c.modulate.a = 0.0
	c.call_deferred("_appear")
	return c


func _appear() -> void:
	panel.pivot_offset = panel.size / 2.0
	if Save.setting("reduce_motion"):
		modulate.a = 1.0
		return
	panel.scale = Vector2(0.7, 0.7)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	closed.emit()
	if Save.setting("reduce_motion"):
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(queue_free)


## Makes a button bounce in after a delay (the Next button on the clear card).
static func bounce_in(node: Control, delay := 0.3) -> void:
	if Save.setting("reduce_motion"):
		return
	node.modulate.a = 0.0
	node.scale = Vector2(0.6, 0.6)
	await node.get_tree().process_frame
	node.pivot_offset = node.size / 2.0
	var t := node.create_tween()
	t.tween_interval(delay)
	t.tween_property(node, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(node, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
