extends SceneTree
## Ritratti di controllo dell'avatar (fronte, schiena, figura intera).
## Uso: godot --path . --script tests/avatar_portrait.gd

const SHOTS := [
	{"name": "avatar_viso", "pos": Vector3(0, 1.40, -1.15), "look": Vector3(0, 1.38, 0), "fov": 26.0},
	{"name": "avatar_schiena", "pos": Vector3(0, 1.35, 1.25), "look": Vector3(0, 1.30, 0), "fov": 28.0},
	{"name": "avatar_intero", "pos": Vector3(1.25, 1.25, 2.15), "look": Vector3(0, 0.95, 0), "fov": 30.0},
]

func _initialize() -> void:
	var scene := Node3D.new()
	root.add_child(scene)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#C8D8E4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFF4E2")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-35), 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-15), deg_to_rad(150), 0)
	fill.light_color = Color("#BBD8F0")
	fill.light_energy = 0.6
	scene.add_child(fill)

	MeshHelpers.cylinder(scene, 0.9, 0.95, 0.12, Color("#E8D9BC"), Vector3(0, -0.06, 0),
		Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 32)

	var avatar := AvatarBuilder.build({
		"body": 1, "body_color": 0, "outfit_color": 0, "hat": 1, "hat_color": 1,
	})
	scene.add_child(avatar)

	var cam := Camera3D.new()
	cam.current = true
	scene.add_child(cam)

	var dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	for shot in SHOTS:
		cam.fov = shot["fov"]
		cam.look_at_from_position(shot["pos"], shot["look"], Vector3.UP)
		for i in range(10):
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var path := dir.path_join(str(shot["name"]) + ".png")
		img.save_png(path)
		print("PORTRAIT " + path)
	quit(0)
