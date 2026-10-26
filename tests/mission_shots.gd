extends SceneTree
## Cattura il tavolo di alcune missioni, prima e dopo la soluzione.
## Uso: godot --path . --script tests/mission_shots.gd -- 001 002 006 009 010 097

var _ids: Array[String] = ["001", "009", "010", "097"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_ids.clear()
		for a in args:
			_ids.append(str(a))
	_run()

func _run() -> void:
	await process_frame
	var dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	for id in _ids:
		var m: Dictionary = MissionData.by_id(id)
		if m.is_empty():
			print("MISSION FAIL " + id)
			continue
		var stage: Node3D = load("res://scripts/missions/mission_stage.gd").new()
		stage.set("quiet", true)
		stage.call("setup", m, false)
		root.add_child(stage)
		await _frames(12)
		await _snap(dir, "%s_prima" % id)
		stage.call("debug_solve")
		await _frames(20)
		await _snap(dir, "%s_dopo" % id)
		stage.queue_free()
		await _frames(4)
	quit(0)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _snap(dir: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		print("SNAP FAIL " + label)
		return
	var path := dir.path_join("m_" + label + ".png")
	img.save_png(path)
	print("SNAP " + path)
