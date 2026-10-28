class_name RingFx
extends Node2D
## A ring that grows (see Fx.ring).

var color := Color.WHITE
var radius := 10.0:
	set(v):
		radius = v
		queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, maxf(3.0, 14.0 - radius * 0.08), true)
