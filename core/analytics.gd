extends Node
## Analytics events. Until a Firebase/GameAnalytics plugin is checked against
## Godot 4.7, events go to a local log file (one JSON object per line) at
## user://analytics.log. Set `sink` to forward them to a plugin later.

const LOG_PATH := "user://analytics.log"
## Keeps the log from growing forever on a test phone.
const MAX_LOG_BYTES := 2 * 1024 * 1024

var enabled := true
## Print events to the console (debug builds).
var echo := OS.is_debug_build()
## Optional Callable(event: String, fields: Dictionary) for a real backend.
var sink := Callable()
var session_id := ""
var _session_start := 0.0
var _session_open := false


func _ready() -> void:
	_start_session()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			end_session()
		NOTIFICATION_APPLICATION_RESUMED:
			if not _session_open:
				_start_session()


func track(event: String, fields: Dictionary = {}) -> void:
	if not enabled:
		return
	var row := {"event": event, "t": Time.get_unix_time_from_system(), "session": session_id}
	row.merge(fields)
	if sink.is_valid():
		sink.call(event, fields)
	if echo:
		print("[analytics] ", JSON.stringify(row))
	_append(JSON.stringify(row))


func end_session() -> void:
	if not _session_open:
		return
	_session_open = false
	track("session_end", {
		"level_reached": Save.level,
		"session_length": snappedf(_now() - _session_start, 0.1),
	})


func _start_session() -> void:
	session_id = "%x" % (randi() ^ int(Time.get_unix_time_from_system()))
	_session_start = _now()
	_session_open = true


func _append(line: String) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE
	var f := FileAccess.open(LOG_PATH, mode)
	if f == null:
		return
	if f.get_length() > MAX_LOG_BYTES:
		f.close()
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.seek_end()
	f.store_line(line)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
