extends Node
## Runs every tests/unit/test_*.gd file and quits with exit code 0 if all
## pass. Run headless:
##   godot --headless --path . res://tests/run_tests.tscn
## Pass `-- --filter=name` to run only files whose name contains `name`.

const DIR := "res://tests/unit/"


func _ready() -> void:
	# Let the tree finish setting up so tests can add scenes to it.
	await get_tree().process_frame
	Analytics.enabled = false
	Analytics.echo = false
	Save.path = "user://test_save.json"
	var filter := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--filter="):
			filter = a.substr(9)
	var files := DirAccess.get_files_at(DIR)
	var total := 0
	var failed: Array[String] = []
	var t0 := Time.get_ticks_msec()
	for f in files:
		if not f.begins_with("test_") or not f.ends_with(".gd"):
			continue
		if filter != "" and not f.contains(filter):
			continue
		var script: GDScript = load(DIR + f)
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			if String(m.name).begins_with("test_"):
				methods.append(m.name)
		methods.sort()
		for m in methods:
			var tc = script.new()
			if tc is Node:
				add_child(tc)
			tc.current = "%s::%s" % [f, m]
			# Awaiting works for both plain and coroutine test methods.
			await Callable(tc, m).call()
			total += 1
			if tc.failures.is_empty():
				print("  ok   ", tc.current)
			else:
				for msg in tc.failures:
					print("  FAIL ", msg)
				failed.append(tc.current)
			if tc is Node:
				tc.queue_free()
	print("\n%d tests, %d failed (%.1fs)" % [total, failed.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	if FileAccess.file_exists(Save.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))
	get_tree().quit(1 if not failed.is_empty() or total == 0 else 0)
