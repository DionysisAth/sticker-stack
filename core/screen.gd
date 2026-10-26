class_name Screen
extends RefCounted
## Phone screen helpers.


## Top and bottom safe-area insets (notch, home bar) in UI units.
static func safe_margins(ctrl: Control) -> Vector2:
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.y <= 0 or safe.size.y <= 0:
		return Vector2.ZERO
	var view_h := ctrl.get_viewport_rect().size.y
	var k := view_h / float(screen.y)
	var top := maxf(0.0, safe.position.y * k)
	var bottom := maxf(0.0, (screen.y - safe.end.y) * k)
	return Vector2(minf(top, 120.0), minf(bottom, 120.0))
