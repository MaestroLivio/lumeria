extends SceneTree
## Galleria di controllo degli asset Blender: cattura una riga di modelli.
## Uso: godot --path . --script tests/asset_gallery.gd

const MODELS := [
	"tree_oak", "tree_pine", "tree_autumn", "tree_birch", "bush", "rock", "mushroom",
	"cottage", "well", "lantern", "fountain", "bench", "crate", "barrel",
]

func _initialize() -> void:
	var scene := Node3D.new()
	root.add_child(scene)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#9FC7E0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#DCE9F5")
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	scene.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-35), 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	scene.add_child(sun)

	MeshHelpers.box(scene, Vector3(60, 0.4, 30), Color("#7FB56E"), Vector3(0, -0.2, 0))

	for i in range(MODELS.size()):
		var name: String = MODELS[i]
		var col := i % 5
		var row := i / 5
		var x := (float(col) - 2.0) * 4.2
		var z := (float(row) - 0.5) * 4.2
		ModelLibrary.place(scene, name, Vector3(x, 0, z), 0.0, 1.0)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 7.0, 14.5)
	cam.look_at_from_position(cam.position, Vector3(0, 1.2, 0), Vector3.UP)
	cam.fov = 52.0
	cam.current = true
	scene.add_child(cam)

	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join("assets_gallery.png"))
	print("GALLERY OK " + dir.path_join("assets_gallery.png"))
	quit(0)
