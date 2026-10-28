class_name LumeriaWorld
extends Node3D
## Mondo esplorabile: hub, dieci regioni, cento postazioni, incontri e decorazioni.
## Tutto procedurale, offline, pensato per essere letto dai bambini senza testo obbligatorio.

## Il mondo è volutamente ampio: tra una radura e l'altra c'è prato da
## attraversare e dentro ogni radura c'è spazio per camminare tra le postazioni.
const REGION_DISTANCE := 58.0
const REGION_MEADOW := 16.0
const STATION_STEP_X := 5.6
const STATION_STEP_Z := 5.2

var stations: Array[RegionStation] = []
var special_stations: Array[RegionStation] = []
var collectibles: Array[WorldCollectible] = []
var characters: Array[WorldNpc] = []
var region_centers: Array[Vector3] = []
var region_names: Array[String] = []
var region_colors: Array[Color] = []
var hub_position := Vector3(0, 0, 0)
var _rng := RandomNumberGenerator.new()
var _region_roots: Array[Node3D] = []
var _special_by_kind: Dictionary = {}
var _env_node: WorldEnvironment
var _env: Environment
var _sign_lights: Array[Dictionary] = []
var _sign_phase := 0.0

func build() -> void:
	_rng.seed = 100100
	region_names.assign(MissionData.REGION_NAMES)
	region_colors.assign(MissionData.REGION_COLORS)
	_build_environment()
	if not Settings.setting_changed.is_connected(_on_setting_changed):
		Settings.setting_changed.connect(_on_setting_changed)
	_build_ground()
	_build_paths()
	_build_hub()
	_build_regions()
	_build_nature()
	_build_boundary()
	_build_characters()
	_spawn_collectibles()

# ---------------------------------------------------------------- ambiente
## Attiva o sospende l'ambiente del mondo: quando si apre una missione il
## WorldEnvironment della missione deve essere l'unico attivo.
func set_environment_active(value: bool) -> void:
	if _env_node == null:
		return
	_env_node.environment = _env if value else null

## La qualità scelta nelle impostazioni decide gli effetti costosi.
## Essenziale resta leggero su Mac datati, Massima tiene tutto acceso.
func apply_quality(level: int) -> void:
	if _env == null:
		return
	_env.ssao_enabled = level >= 1
	_env.glow_enabled = level >= 1
	_env.glow_intensity = Settings.glow_energy(0.26)
	_env.glow_bloom = Settings.glow_energy(0.04)

func _on_setting_changed(key: String) -> void:
	if key in ["glow", "quality", "all"]:
		apply_quality(int(Settings.get_setting("quality", 1)))

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#3C79BE")
	sm.sky_horizon_color = Color("#FFD5A2")
	sm.sky_curve = 0.11
	sm.sky_energy_multiplier = 1.0
	sm.ground_bottom_color = Color("#3A5A44")
	sm.ground_horizon_color = Color("#CBB58C")
	sm.ground_curve = 0.04
	sm.sun_angle_max = 26.0
	sm.sun_curve = 0.08
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.58
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.92
	env.tonemap_white = 6.0
	# occlusione ambientale: dà peso a panche, vasi e basamenti
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 2.1
	env.ssao_power = 1.5
	env.ssao_detail = 0.6
	env.glow_enabled = true
	env.glow_intensity = Settings.glow_energy(0.26)
	env.glow_bloom = Settings.glow_energy(0.04)
	env.glow_hdr_threshold = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("#EAD8B6")
	env.fog_density = 0.0023
	env.fog_sky_affect = 0.22
	env.fog_aerial_perspective = 0.55
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.18
	we.environment = env
	_env_node = we
	_env = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sole"
	sun.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-38), 0)
	sun.light_color = Color("#FFF0CE")
	sun.light_energy = 1.4
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 95.0
	sun.directional_shadow_split_1 = 0.12
	sun.directional_shadow_split_2 = 0.3
	sun.directional_shadow_split_3 = 0.65
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "Riflesso"
	fill.rotation = Vector3(deg_to_rad(-14), deg_to_rad(142), 0)
	fill.light_color = Color("#A9CFEA")
	fill.light_energy = 0.18
	add_child(fill)

func _build_ground() -> void:
	var ground := MeshHelpers.cylinder(self, 92.0, 92.0, 0.6, Color("#7FB56E"), Vector3(0, -0.3, 0),
		Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 64)
	ground.name = "Prato"
	var grass := ShaderMaterial.new()
	grass.shader = load("res://assets/shaders/grass.gdshader")
	ground.material_override = grass
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var body := StaticBody3D.new()
	body.name = "Terreno"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 92.0
	cyl.height = 0.6
	shape.shape = cyl
	shape.position = Vector3(0, -0.3, 0)
	body.add_child(shape)
	add_child(body)

	_flower_meadows()

## Prati fioriti in MultiMesh: centinaia di fiori con poche chiamate di disegno.
func _flower_meadows() -> void:
	var colors: Array[Color] = [Color("#F2C24B"), Color("#E9748A"), Color("#FFF7E8"), Color("#B58CD6"), Color("#7EC8E3")]
	var spots: Array[Vector3] = []
	for i in range(70):
		var base := _random_world_point(11.0, 84.0)
		var n := 3 + i % 4
		for k in range(n):
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(0.2, 1.5)
			spots.append(base + Vector3(cos(a) * r, 0.0, sin(a) * r))
	var by_color: Dictionary = {}
	for p in spots:
		var c: Color = colors[_rng.randi() % colors.size()]
		if not by_color.has(c):
			by_color[c] = [] as Array[Vector3]
		by_color[c].append(p)

	# steli: un solo MultiMesh per tutti
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.016
	stem_mesh.bottom_radius = 0.02
	stem_mesh.height = 0.24
	stem_mesh.radial_segments = 4
	stem_mesh.rings = 1
	var stems := _multimesh(stem_mesh, MeshHelpers.material(Color("#4F7F45"), Color(0, 0, 0, 0), 0.0, 0.9))
	var stem_xforms: Array[Transform3D] = []
	for p in spots:
		stem_xforms.append(Transform3D(Basis(), p + Vector3(0, 0.12, 0)))
	stems.multimesh.instance_count = stem_xforms.size()
	for i in range(stem_xforms.size()):
		stems.multimesh.set_instance_transform(i, stem_xforms[i])
	add_child(stems)

	for c in by_color:
		var pts: Array = by_color[c]
		var head := SphereMesh.new()
		head.radius = 0.085
		head.height = 0.13
		head.radial_segments = 6
		head.rings = 3
		var mm := _multimesh(head, MeshHelpers.material(c, c, 0.18, 0.8))
		mm.multimesh.instance_count = pts.size()
		for i in range(pts.size()):
			var p: Vector3 = pts[i]
			var s := _rng.randf_range(0.85, 1.25)
			mm.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), p + Vector3(0, 0.27, 0)))
		add_child(mm)

func _multimesh(mesh: Mesh, material: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi

# ---------------------------------------------------------------- sentieri
## Dieci sentieri di terra collegano il prato centrale alle regioni.
func _build_paths() -> void:
	var path_root := Node3D.new()
	path_root.name = "Sentieri"
	add_child(path_root)
	for i in range(10):
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		var near := 9.4
		var far := REGION_DISTANCE - REGION_MEADOW + 1.2
		var mid := (near + far) * 0.5
		var length := far - near
		var pos := Vector3(cos(angle) * mid, 0.015, sin(angle) * mid)
		var rot := Vector3(0, PI / 2.0 - angle, 0)
		var border := MeshHelpers.box(path_root, Vector3(3.9, 0.04, length), Color("#BFA57C"), pos + Vector3(0, -0.006, 0), rot)
		border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var strip := MeshHelpers.box(path_root, Vector3(3.2, 0.04, length - 0.2), Color("#D9C39C"), pos + Vector3(0, 0.012, 0), rot)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# sassolini ai lati del sentiero
		for k in range(8):
			var t := _rng.randf_range(near + 2.0, far - 1.5)
			var side := -1.0 if k % 2 == 0 else 1.0
			var off := side * _rng.randf_range(1.9, 2.6)
			var p := Vector3(cos(angle) * t - sin(angle) * off, 0.04, sin(angle) * t + cos(angle) * off)
			var pebble := MeshHelpers.sphere(path_root, _rng.randf_range(0.09, 0.18),
				Color("#C7B79B").darkened(_rng.randf_range(0.0, 0.12)), p)
			pebble.scale = Vector3(1.2, 0.55, 1.0)
			pebble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ---------------------------------------------------------------- natura
## Alberi, cespugli e rocce low-poly sparsi senza invadere sentieri e radure.
func _build_nature() -> void:
	var nature := Node3D.new()
	nature.name = "Natura"
	add_child(nature)
	var placed: Array[Vector3] = []
	var kinds := ["tree_oak", "tree_oak", "tree_pine", "tree_autumn", "tree_birch"]
	var attempts := 0
	var trees := 0
	while trees < 62 and attempts < 400:
		attempts += 1
		var p := _random_world_point(15.0, 84.0)
		if not _nature_spot_free(p, placed, 3.6):
			continue
		if _near_path(p, 2.8):
			continue
		# alberi più fitti verso il bordo del mondo
		var d := Vector2(p.x, p.z).length()
		if d < 30.0 and _rng.randf() < 0.45:
			continue
		var kind: String = kinds[_rng.randi() % kinds.size()]
		var s := _rng.randf_range(0.85, 1.35)
		var rot := _rng.randf() * TAU
		if ModelLibrary.place(nature, kind, p, rot, s) == null:
			_primitive_tree(nature, p, s)
		placed.append(p)
		trees += 1

	for i in range(26):
		var p := _random_world_point(13.0, 86.0)
		if not _nature_spot_free(p, placed, 2.2) or _near_path(p, 2.0):
			continue
		placed.append(p)
		var roll := _rng.randf()
		if roll < 0.5:
			ModelLibrary.place(nature, "bush", p, _rng.randf() * TAU, _rng.randf_range(0.8, 1.25))
		elif roll < 0.82:
			ModelLibrary.place(nature, "rock", p, _rng.randf() * TAU, _rng.randf_range(0.7, 1.5))
		else:
			ModelLibrary.place(nature, "mushroom", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.4))

	# filare di alberi davanti alle colline di confine
	for i in range(34):
		var a := TAU * float(i) / 34.0 + _rng.randf_range(-0.04, 0.04)
		var r := _rng.randf_range(80.0, 86.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var kind2: String = ["tree_pine", "tree_oak", "tree_pine", "tree_birch"][i % 4]
		ModelLibrary.place(nature, kind2, p, _rng.randf() * TAU, _rng.randf_range(1.25, 1.8))

func _nature_spot_free(p: Vector3, placed: Array[Vector3], radius: float) -> bool:
	for q in placed:
		if p.distance_to(q) < radius:
			return false
	return true

func _near_path(p: Vector3, margin: float) -> bool:
	var r := Vector2(p.x, p.z).length()
	var path_far := REGION_DISTANCE - REGION_MEADOW + 2.0
	if r < 10.5 or r > path_far:
		return false
	var a := atan2(p.z, p.x)
	for i in range(10):
		var pa := -PI / 2.0 + TAU * float(i) / 10.0
		var diff := absf(wrapf(a - pa, -PI, PI))
		if diff < atan2(margin, maxf(r, 1.0)):
			return true
	return false

func _primitive_tree(root: Node3D, p: Vector3, s: float) -> void:
	var h := 2.4 * s
	MeshHelpers.cylinder(root, 0.18 * s, 0.26 * s, h, Color("#7A5236"), p + Vector3(0, h / 2, 0))
	MeshHelpers.sphere(root, 1.05 * s, Color("#4E9A4A"), p + Vector3(0, h + 0.55 * s, 0))

func _build_boundary() -> void:
	# Colline morbide ai bordi: suggeriscono il confine senza muri visibili.
	for i in range(28):
		var a := TAU * float(i) / 28.0
		var r := 88.0 + _rng.randf_range(-1.5, 1.5)
		var h := _rng.randf_range(5.0, 13.0)
		MeshHelpers.sphere(self, _rng.randf_range(4.0, 8.0), Color("#6D9B62").darkened(_rng.randf_range(0.0, 0.15)),
			Vector3(cos(a) * r, h * 0.2, sin(a) * r))
	# Il confine è gestito dal giocatore con un clamp morbido:
	# nessun muro invisibile, nessuna sensazione di gabbia.

# ---------------------------------------------------------------- hub
func _build_hub() -> void:
	var root := Node3D.new()
	root.name = "Hub"
	add_child(root)
	_region_roots.append(root)
	# piazza in pietra chiara con cornice e pietre magiche
	MeshHelpers.cylinder(root, 9.5, 9.8, 0.14, Color("#F2E3C8"), Vector3(0, 0.03, 0), Vector3.ZERO,
		Color(0, 0, 0, 0), 0.0, 48)
	MeshHelpers.torus(root, 8.45, 8.6, Color("#C9AE84"), Vector3(0, 0.14, 0))
	MeshHelpers.torus(root, 9.34, 9.48, Color("#D8B98A"), Vector3(0, 0.13, 0))
	for i in range(20):
		var a := TAU * float(i) / 20.0
		var p := Vector3(cos(a) * 8.95, 0.115, sin(a) * 8.95)
		var rune: Color = MissionData.REGION_COLORS[i % 10]
		var tile := MeshHelpers.box(root, Vector3(0.3, 0.03, 0.44), rune, p,
			Vector3(0, -a, 0), rune, 0.35)
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# fontana al centro (modello Blender, con fallback procedurale)
	if ModelLibrary.place(root, "fountain", Vector3.ZERO, 0.0, 1.05, 1.9) == null:
		MeshHelpers.cylinder(root, 1.5, 1.8, 0.55, Color("#C9B18F"), Vector3(0, 0.35, 0))
		MeshHelpers.cylinder(root, 1.35, 1.35, 0.12, Color("#8ED4E8"), Vector3(0, 0.62, 0))
		MeshHelpers.cylinder(root, 0.18, 0.3, 2.0, Color("#E8D9BC"), Vector3(0, 1.5, 0))
		MeshHelpers.sphere(root, 0.36, Color("#FFF3B0"), Vector3(0, 2.65, 0), Color("#FFE066"), 2.4)
	MeshHelpers.label(root, "LUMERIA", 64, Color("#FFF7E8"), Vector3(0, 3.86, 0.03), 72, false)
	MeshHelpers.label(root, "LUMERIA", 64, Color("#FFF7E8"), Vector3(0, 3.86, -0.03), 72, false, Vector3(0, PI, 0))
	MeshHelpers.label(root, "Le cento pietre magiche del sapere", 34, Color("#FFF3B0"), Vector3(0, 3.34, 0.03), 52, false)
	MeshHelpers.label(root, "Le cento pietre magiche del sapere", 34, Color("#FFF3B0"), Vector3(0, 3.34, -0.03), 52, false, Vector3(0, PI, 0))
	var glow := OmniLight3D.new()
	glow.light_color = Color("#FFDF9E")
	glow.light_energy = 1.5
	glow.omni_range = 6.0
	glow.position = Vector3(0, 2.6, 0)
	root.add_child(glow)

	var specials := [
		{"kind": "map", "label": "Mappa", "icon": "bussola", "color": Color("#5FA8D3"), "pos": Vector3(-4.6, 0, 4.6)},
		{"kind": "journal", "label": "Diario", "icon": "libro", "color": Color("#B58CD6"), "pos": Vector3(4.6, 0, 4.6)},
		{"kind": "lab", "label": "Laboratorio", "icon": "pannello", "color": Color("#4FB3A9"), "pos": Vector3(4.6, 0, -4.6)},
		{"kind": "avatar", "label": "Guardaroba", "icon": "mano", "color": Color("#E9748A"), "pos": Vector3(-4.6, 0, -4.6)},
	]
	for d in specials:
		var st := RegionStation.new()
		st.position = d["pos"]
		add_child(st)
		st.setup_special(d["kind"], d["label"], d["icon"], d["color"])
		special_stations.append(st)
		_special_by_kind[d["kind"]] = st

	# lanterne, panchine e fioriere attorno alla piazza
	for i in range(8):
		var a := TAU * float(i) / 8.0 + 0.2
		var p := Vector3(cos(a) * 6.9, 0, sin(a) * 6.9)
		var facing := atan2(cos(a), sin(a))
		if ModelLibrary.place(root, "lantern", p, facing, 1.0) == null:
			MeshHelpers.cylinder(root, 0.08, 0.12, 2.1, Color("#A97A48"), p + Vector3(0, 1.05, 0))
			MeshHelpers.sphere(root, 0.2, Color("#FFF3B0"), p + Vector3(0, 2.15, 0), Color("#FFE066"), 2.2)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#FFCF7A")
		lamp.light_energy = 0.55
		lamp.omni_range = 4.2
		lamp.position = p + Vector3(0, 2.35, 0)
		root.add_child(lamp)
		if i % 2 == 0:
			var bp := Vector3(cos(a) * 7.9, 0, sin(a) * 7.9)
			if ModelLibrary.place(root, "bench", bp, facing, 1.0) == null:
				MeshHelpers.box(root, Vector3(1.6, 0.12, 0.5), Color("#D8B98A"), bp + Vector3(0, 0.48, 0))
				MeshHelpers.box(root, Vector3(1.6, 0.45, 0.1), Color("#D8B98A"), bp + Vector3(0, 0.72, 0.2))
	for i in range(4):
		var a2 := TAU * float(i) / 4.0 + PI / 4.0
		var pp := Vector3(cos(a2) * 3.4, 0, sin(a2) * 3.4)
		MeshHelpers.cylinder(root, 0.52, 0.42, 0.5, Color("#B98A55"), pp + Vector3(0, 0.25, 0), Vector3.ZERO,
			Color(0, 0, 0, 0), 0.0, 12)
		MeshHelpers.cylinder(root, 0.46, 0.46, 0.08, Color("#6B4B33"), pp + Vector3(0, 0.48, 0))
		for k in range(6):
			var fa := TAU * float(k) / 6.0
			MeshHelpers.sphere(root, 0.12, [Color("#E9748A"), Color("#F2C24B"), Color("#FFF7E8")][k % 3],
				pp + Vector3(cos(fa) * 0.3, 0.6, sin(fa) * 0.3))
	_hub_festivities(root)

## Festoni colorati e palloncini attorno alla piazza: aria di festa.
func _hub_festivities(root: Node3D) -> void:
	var colors: Array[Color] = [Color("#E9748A"), Color("#F2C24B"), Color("#7EC8E3"),
		Color("#8CCB7A"), Color("#B58CD6"), Color("#F5D76E")]
	# Festoni tra le lanterne, in un anello attorno alla fontana.
	for i in range(8):
		var a0 := TAU * float(i) / 8.0 + 0.2
		var a1 := TAU * float(i + 1) / 8.0 + 0.2
		var p0 := Vector3(cos(a0) * 6.9, 2.15, sin(a0) * 6.9)
		var p1 := Vector3(cos(a1) * 6.9, 2.15, sin(a1) * 6.9)
		_bunting(root, p0, p1, colors, 6, 0.22)
	# Due festoni incrociati sopra la fontana.
	var f0 := Vector3(-3.2, 2.6, -1.0)
	var f1 := Vector3(3.2, 2.6, 1.0)
	_bunting(root, f0, f1, colors, 9, 0.34)
	var g0 := Vector3(-3.2, 2.6, 1.0)
	var g1 := Vector3(3.2, 2.6, -1.0)
	_bunting(root, g0, g1, colors, 9, 0.34)
	# Palloncini in tre angoli della piazza.
	for i in range(3):
		var ba := TAU * float(i) / 3.0 + 0.55
		_balloons(root, Vector3(cos(ba) * 4.6, 0, sin(ba) * 4.6), colors)

## Un festone di bandierine (triangolini) e lucine lungo una curva che s'aggetta.
func _bunting(root: Node3D, a: Vector3, b: Vector3, colors: Array, n: int, sag: float) -> void:
	var mid := (a + b) * 0.5 + Vector3(0, -sag, 0)
	for i in range(n):
		var t := float(i) / float(n - 1)
		# curva quadratica di Bézier: corda che scende al centro
		var p := a.lerp(b, t)
		p.y = lerpf(lerpf(a.y, mid.y, t), lerpf(mid.y, b.y, t), t)
		var c: Color = colors[i % colors.size()]
		var flag := MeshHelpers.prism(root, Vector3(0.26, 0.22, 0.02), c,
			p + Vector3(0, -0.13, 0), Vector3(0, 0, PI))
		flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# lucina calda sul nodo
		var light := MeshHelpers.sphere(root, 0.035, Color("#FFF3B0"), p,
			Color("#FFE066"), 1.6, 8)
		light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Un mazzetto di palloncini legati a terra da un filo.
func _balloons(root: Node3D, base: Vector3, colors: Array) -> void:
	var n := 3
	for i in range(n):
		var off := Vector3(sin(float(i) * 2.4) * 0.22, 0, cos(float(i) * 2.4) * 0.22)
		var c: Color = colors[(i * 2 + 3) % colors.size()]
		var h := 1.5 + float(i) * 0.22
		var p := base + off + Vector3(0, h, 0)
		MeshHelpers.sphere(root, 0.24, c, p, c, 0.25, 14)
		MeshHelpers.sphere(root, 0.22, c.lightened(0.22), p + Vector3(0, 0.02, 0.12))
		# filo
		MeshHelpers.cylinder(root, 0.008, 0.008, h - 0.2, Color("#E8D9BC"),
			base + off + Vector3(0, (h - 0.2) * 0.5 + 0.1, 0))

# ---------------------------------------------------------------- regioni
func _build_regions() -> void:
	for i in range(10):
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		var center := Vector3(cos(angle) * REGION_DISTANCE, 0, sin(angle) * REGION_DISTANCE)
		region_centers.append(center)
		var root := Node3D.new()
		root.name = "Regione%02d" % (i + 1)
		add_child(root)
		_region_roots.append(root)
		var color: Color = region_colors[i]
		var tint: Color = color.lerp(Color("#E8D8B8"), 0.62)
		# La radura resta di prato: solo anelli colorati e sassolini ne disegnano il confine.
		MeshHelpers.torus(root, REGION_MEADOW - 0.6, REGION_MEADOW, color, center + Vector3(0, 0.1, 0),
			Vector3.ZERO, color, 0.35)
		MeshHelpers.torus(root, 6.2, 6.35, color.darkened(0.08), center + Vector3(0, 0.09, 0),
			Vector3.ZERO, color, 0.2)
		for k in range(20):
			var ra := _rng.randf() * TAU
			var rr := _rng.randf_range(3.0, REGION_MEADOW - 0.8)
			var sp := center + Vector3(cos(ra) * rr, 0.08, sin(ra) * rr)
			var stone := MeshHelpers.sphere(root, _rng.randf_range(0.14, 0.3),
				tint.darkened(_rng.randf_range(0.08, 0.2)), sp)
			stone.scale = Vector3(1.2, 0.35, 1.0)
			stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_build_region_props(i, root, center, color)
		_build_region_sign(i, root, center, color)
		_build_region_stations(i, root, center, angle, color)
		_region_festivities(root, center, color)
		# cespugli attorno alla radura
		for j in range(8):
			var aa := angle + TAU * float(j) / 8.0 + 0.4
			var p := center + Vector3(cos(aa) * (REGION_MEADOW - 1.1), 0.0, sin(aa) * (REGION_MEADOW - 1.1))
			if ModelLibrary.place(root, "bush", p, aa, _rng.randf_range(0.7, 1.15)) == null:
				MeshHelpers.sphere(root, _rng.randf_range(0.45, 0.9), Color("#6D9B62"), p + Vector3(0, 0.3, 0))

func _build_region_stations(i: int, root: Node3D, center: Vector3, angle: float, color: Color) -> void:
	var missions := MissionData.region_missions(i + 1)
	for j in range(missions.size()):
		var m: Dictionary = missions[j]
		# Le missioni si leggono da sinistra verso destra: la prima della
		# regione sta sulla sinistra di chi entra nell'area di scelta.
		var col := 4 - (j % 5)
		var row := j / 5
		# Più spazio tra le postazioni: si passa comodamente anche correndo.
		var local := Vector3(float(col - 2) * STATION_STEP_X, 0.0, (float(row) - 0.5) * STATION_STEP_Z)
		var rotated := Vector3(
			local.x * cos(angle) - local.z * sin(angle), 0,
			local.x * sin(angle) + local.z * cos(angle))
		var st := RegionStation.new()
		st.position = center + rotated
		st.rotation.y = angle + PI
		root.add_child(st)
		st.setup_mission(m, color)
		st.set_completed(SaveGame.is_mission_completed(str(m.get("id", ""))))
		stations.append(st)

func _build_region_sign(i: int, root: Node3D, center: Vector3, color: Color) -> void:
	var toward_hub := (hub_position - center).normalized()
	var p := center + toward_hub * (REGION_MEADOW - 2.4)
	var sign_root := Node3D.new()
	sign_root.position = p
	sign_root.rotation.y = atan2(toward_hub.x, toward_hub.z)
	root.add_child(sign_root)
	MeshHelpers.cylinder(sign_root, 0.08, 0.12, 2.6, Color("#A97A48"), Vector3(-1.4, 1.3, 0))
	MeshHelpers.cylinder(sign_root, 0.08, 0.12, 2.6, Color("#A97A48"), Vector3(1.4, 1.3, 0))
	MeshHelpers.box(sign_root, Vector3(3.6, 1.1, 0.16), color.darkened(0.2), Vector3(0, 2.3, 0))
	# Pannello e scritte su entrambe le facciate: il cartello è fisso.
	for side in [1.0, -1.0]:
		var z: float = 0.09 * float(side)
		MeshHelpers.box(sign_root, Vector3(3.3, 0.84, 0.04), Color("#FFF7E8"), Vector3(0, 2.3, z))
		var rot: Vector3 = Vector3.ZERO if float(side) > 0.0 else Vector3(0, PI, 0)
		MeshHelpers.label(sign_root, "%02d · %s" % [i + 1, region_names[i]], 28, Color("#3B2A20"),
			Vector3(0, 2.42, z + 0.03 * side), 44, false, rot)
		MeshHelpers.label(sign_root, MissionData.CUSTODIANS[i], 22, color.darkened(0.25),
			Vector3(0, 2.12, z + 0.03 * side), 34, false, rot)
	# Una lanterna sopra il cartello: si accende quando ci si avvicina.
	var lamp := OmniLight3D.new()
	lamp.name = "LuceInsegna"
	lamp.light_color = Color("#FFE9B0")
	lamp.light_energy = 0.0
	lamp.omni_range = 4.2
	lamp.visible = false
	lamp.position = Vector3(0, 2.9, 0.35)
	sign_root.add_child(lamp)
	var beam := MeshHelpers.cylinder(sign_root, 0.12, 0.05, 0.34, Color("#FFF3B0"),
		Vector3(0, 3.0, 0.0), Vector3.ZERO, Color("#FFE066"), 1.4)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sign_lights.append({"light": lamp, "center": p + Vector3(0, 2.3, 0), "radius": 16.0, "level": 0.0})

func _build_region_props(i: int, root: Node3D, c: Vector3, color: Color) -> void:
	match i:
		0: _props_bosco(root, c, color)
		1: _props_venti(root, c, color)
		2: _props_giardino(root, c, color)
		3: _props_ferrovia(root, c, color)
		4: _props_officina(root, c, color)
		5: _props_valle(root, c, color)
		6: _props_biblioteca(root, c, color)
		7: _props_mulino(root, c, color)
		8: _props_citta(root, c, color)
		9: _props_torre(root, c, color)

func _props_bosco(root: Node3D, c: Vector3, color: Color) -> void:
	for i in range(9):
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(8.8, 12.4)
		var p := c + Vector3(cos(a) * r, 0, sin(a) * r)
		var kind := "tree_pine" if i % 3 == 1 else ("tree_autumn" if i % 3 == 2 else "tree_oak")
		if ModelLibrary.place(root, kind, p, _rng.randf() * TAU, _rng.randf_range(0.85, 1.2)) == null:
			var h := _rng.randf_range(2.4, 4.6)
			MeshHelpers.cylinder(root, 0.18, 0.28, h, Color("#8A6242"), p + Vector3(0, h / 2, 0))
			MeshHelpers.sphere(root, _rng.randf_range(0.9, 1.6), Color("#5E9E56"), p + Vector3(0, h + 0.3, 0))
	# funghi e cespugli
	for i in range(6):
		var p := c + Vector3(_rng.randf_range(-7.0, 7.0), 0, _rng.randf_range(4.5, 10.5))
		if ModelLibrary.place(root, "mushroom", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.5)) == null:
			MeshHelpers.cylinder(root, 0.07, 0.1, 0.45, Color("#F2E3C8"), p + Vector3(0, 0.22, 0))
			MeshHelpers.sphere(root, 0.3, Color("#D9674A"), p + Vector3(0, 0.48, 0))
	for i in range(4):
		var p := c + Vector3(_rng.randf_range(-10.0, 10.0), 0, _rng.randf_range(-6.0, 2.0))
		ModelLibrary.place(root, "bush", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.25))

func _props_venti(root: Node3D, c: Vector3, color: Color) -> void:
	for i in range(4):
		var a := TAU * float(i) / 4.0 + 0.4
		var p := c + Vector3(cos(a) * 10.5, 0, sin(a) * 10.5)
		MeshHelpers.torus(root, 1.2, 1.42, color, p + Vector3(0, 2.0, 0), Vector3(PI / 2, a, 0),
			color, 0.25)
		MeshHelpers.cylinder(root, 0.06, 0.08, 2.0, Color("#A97A48"), p + Vector3(0, 1.0, 0))
		var tp := c + Vector3(cos(a + 0.8) * 11.0, 0, sin(a + 0.8) * 11.0)
		if ModelLibrary.place(root, "tree_birch", tp, _rng.randf() * TAU, _rng.randf_range(0.9, 1.2)) == null:
			MeshHelpers.cylinder(root, 0.14, 0.2, 2.9, Color("#E8E2D4"), tp + Vector3(0, 1.45, 0))
			MeshHelpers.sphere(root, 0.85, Color("#8CC26A"), tp + Vector3(0, 3.15, 0))
	for i in range(7):
		var p := c + Vector3(_rng.randf_range(-10.0, 10.0), _rng.randf_range(3.2, 5.2), _rng.randf_range(-10.0, 10.0))
		MeshHelpers.sphere(root, _rng.randf_range(0.5, 1.0), Color("#FFF7E8"), p)
	# bandierine
	for i in range(6):
		var p := c + Vector3(-6.0 + float(i) * 2.4, 0, 10.0)
		MeshHelpers.cylinder(root, 0.04, 0.04, 1.6, Color("#A97A48"), p + Vector3(0, 0.8, 0))
		MeshHelpers.box(root, Vector3(0.6, 0.34, 0.02), color, p + Vector3(0.3, 1.45, 0))

func _props_giardino(root: Node3D, c: Vector3, color: Color) -> void:
	for i in range(4):
		var p := c + Vector3(-8.0 + float(i) * 5.3, 0, 10.0)
		MeshHelpers.box(root, Vector3(3.4, 0.28, 1.2), Color("#8A6242"), p + Vector3(0, 0.14, 0))
		MeshHelpers.box(root, Vector3(3.1, 0.22, 0.95), Color("#6B4B33"), p + Vector3(0, 0.26, 0))
		for j in range(4):
			var fp := p + Vector3(-1.1 + float(j) * 0.72, 0.44, 0)
			MeshHelpers.cylinder(root, 0.02, 0.02, 0.45, Color("#4F7F45"), fp)
			MeshHelpers.sphere(root, 0.16, [Color("#F2C24B"), Color("#E9748A"), Color("#B58CD6"), Color("#FFF7E8")][j], fp + Vector3(0, 0.26, 0))
	# girasoli alti
	for i in range(3):
		var p := c + Vector3(-9.0 + float(i) * 1.4, 0, -9.0)
		MeshHelpers.cylinder(root, 0.04, 0.05, 2.2, Color("#4F7F45"), p + Vector3(0, 1.1, 0))
		MeshHelpers.sphere(root, 0.28, Color("#F2C24B"), p + Vector3(0, 2.25, 0))
	for i in range(4):
		var p := c + Vector3(-10.0 + float(i) * 6.5, 0, -10.8)
		ModelLibrary.place(root, "bush", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.2))
	ModelLibrary.place(root, "bench", c + Vector3(6.5, 0, 10.6), PI, 1.0)

func _props_ferrovia(root: Node3D, c: Vector3, color: Color) -> void:
	MeshHelpers.box(root, Vector3(20.0, 0.08, 0.5), Color("#8A6242"), c + Vector3(0, 0.05, -10.8))
	for side in [-1.0, 1.0]:
		MeshHelpers.box(root, Vector3(20.0, 0.06, 0.09), Color("#9AA3AD"), c + Vector3(0, 0.13, -10.8 + 0.26 * side))
	for i in range(9):
		MeshHelpers.box(root, Vector3(0.35, 0.06, 0.9), Color("#6B4B33"), c + Vector3(-8.0 + float(i) * 2.0, 0.1, -10.8))
	# vagoni
	var train := Node3D.new()
	train.position = c + Vector3(-4.5, 0.25, -9.5)
	train.rotation.y = 0.2
	root.add_child(train)
	MeshHelpers.box(train, Vector3(1.5, 1.0, 1.0), color, Vector3(0, 0.55, 0))
	MeshHelpers.box(train, Vector3(1.1, 0.55, 0.92), Color("#FFF7E8"), Vector3(2.0, 0.42, 0))
	for side in [-1.0, 1.0]:
		for k in [-0.4, 0.4]:
			MeshHelpers.cylinder(train, 0.2, 0.2, 0.12, Color("#3B2A20"), Vector3(k, 0.12, 0.5 * side), Vector3(PI / 2, 0, 0))
	# casse e barili alla stazione merci
	for i in range(2):
		ModelLibrary.place(root, "crate", c + Vector3(7.2 + float(i) * 1.3, 0, -8.4), _rng.randf() * TAU, 1.0)
	ModelLibrary.place(root, "barrel", c + Vector3(9.6, 0, -9.4), 0.0, 1.0)
	ModelLibrary.place(root, "barrel", c + Vector3(10.4, 0, -8.3), 0.6, 1.0)

func _props_officina(root: Node3D, c: Vector3, color: Color) -> void:
	for i in range(4):
		var p := c + Vector3(-8.5 + float(i) * 3.2, 0, -10.2)
		MeshHelpers.torus(root, 0.55, 0.8, color.darkened(0.1), p + Vector3(0, 1.4, 0), Vector3(PI / 2, 0, 0), color, 0.2)
		MeshHelpers.cylinder(root, 0.18, 0.18, 0.25, Color("#9AA3AD"), p + Vector3(0, 1.4, 0), Vector3(PI / 2, 0, 0))
		for k in range(8):
			var aa := TAU * float(k) / 8.0
			MeshHelpers.box(root, Vector3(0.16, 0.24, 0.1), color.darkened(0.2),
				p + Vector3(cos(aa) * 0.7, 1.4 + sin(aa) * 0.7, 0), Vector3(0, 0, aa))
	# banco di lavoro
	MeshHelpers.box(root, Vector3(4.4, 0.18, 1.6), Color("#A97A48"), c + Vector3(5.5, 1.0, -9.0))
	MeshHelpers.box(root, Vector3(0.18, 1.0, 0.18), Color("#8A6242"), c + Vector3(3.6, 0.5, -9.0))
	MeshHelpers.box(root, Vector3(0.18, 1.0, 0.18), Color("#8A6242"), c + Vector3(7.4, 0.5, -9.0))
	# stelle appese
	for i in range(5):
		var p := c + Vector3(-6.0 + float(i) * 3.0, 3.45, -8.0)
		MeshHelpers.sphere(root, 0.16, Color("#F2C24B"), p, Color("#F2C24B"), 2.0)
	for i in range(3):
		ModelLibrary.place(root, "crate", c + Vector3(-8.2 + float(i) * 1.35, 0, -8.3), _rng.randf() * TAU, 1.0)
	ModelLibrary.place(root, "barrel", c + Vector3(-6.2, 0, -9.2), 0.2, 1.0)

func _props_valle(root: Node3D, c: Vector3, color: Color) -> void:
	# ponte ad arco
	var bridge := Node3D.new()
	bridge.position = c + Vector3(0, 0.25, 10.4)
	bridge.rotation.y = 0.1
	root.add_child(bridge)
	for i in range(11):
		var x := -5.0 + float(i)
		var y := sin(PI * float(i) / 10.0) * 0.85
		MeshHelpers.box(bridge, Vector3(0.92, 0.14, 2.4), Color("#B98A55"), Vector3(x, y, 0),
			Vector3(0, 0, (float(i) - 5.0) * -0.03))
	for side in [-1.0, 1.0]:
		MeshHelpers.cylinder(bridge, 0.035, 0.035, 10.6, Color("#7A624A"),
			Vector3(0, 1.0, 1.05 * side), Vector3(0, 0, PI / 2))
	for i in range(4):
		var p := c + Vector3(-9.0 + float(i) * 6.0, 0, -10.0)
		MeshHelpers.cylinder(root, 0.08, 0.12, 2.4, Color("#A97A48"), p + Vector3(0, 1.2, 0))
	# pozzo e alberi
	ModelLibrary.place(root, "well", c + Vector3(-7.6, 0, -8.0), 0.9, 1.0, 1.1)
	for i in range(3):
		ModelLibrary.place(root, "tree_oak", c + Vector3(-3.0 + float(i) * 3.6, 0, -8.6),
			_rng.randf() * TAU, _rng.randf_range(0.9, 1.15))

func _props_biblioteca(root: Node3D, c: Vector3, color: Color) -> void:
	for i in range(4):
		var p := c + Vector3(-9.5 + float(i) * 6.3, 0, -10.2)
		MeshHelpers.box(root, Vector3(3.4, 3.0, 0.6), Color("#8A6242"), p + Vector3(0, 1.5, 0))
		for shelf in range(3):
			MeshHelpers.box(root, Vector3(3.1, 0.08, 0.5), Color("#C9B18F"), p + Vector3(0, 0.6 + float(shelf) * 0.9, 0))
			for b in range(6):
				var bc: Color = [Color("#D95C5C"), Color("#4C86C6"), Color("#F2C24B"), Color("#6DBE6D"), Color("#9B7BC4")][b % 5]
				MeshHelpers.box(root, Vector3(0.28, 0.42, 0.3), bc,
					p + Vector3(-1.2 + float(b) * 0.48, 0.86 + float(shelf) * 0.9, 0.1))
	# campane
	for i in range(3):
		var p := c + Vector3(-4.0 + float(i) * 4.0, 0, 10.4)
		MeshHelpers.cylinder(root, 0.16, 0.42, 0.7, Color("#E8B84A"), p + Vector3(0, 2.0, 0))
		MeshHelpers.sphere(root, 0.1, Color("#8A6242"), p + Vector3(0, 1.62, 0))
		MeshHelpers.cylinder(root, 0.05, 0.05, 1.1, Color("#A97A48"), p + Vector3(0, 1.0, 0))
	# panche di lettura
	ModelLibrary.place(root, "bench", c + Vector3(-7.4, 0, 9.0), PI, 1.0)
	ModelLibrary.place(root, "bench", c + Vector3(7.4, 0, 9.0), PI, 1.0)
	ModelLibrary.place(root, "lantern", c + Vector3(-9.6, 0, 7.6), 2.4, 1.0)
	ModelLibrary.place(root, "lantern", c + Vector3(9.6, 0, 7.6), 2.4, 1.0)

func _props_mulino(root: Node3D, c: Vector3, color: Color) -> void:
	var mill := Node3D.new()
	mill.position = c + Vector3(7.0, 0, -9.5)
	root.add_child(mill)
	MeshHelpers.cylinder(mill, 0.9, 1.6, 3.4, Color("#EAD9BC"), Vector3(0, 1.7, 0))
	MeshHelpers.cylinder(mill, 0.02, 1.45, 1.1, color.darkened(0.1), Vector3(0, 3.8, 0))
	MeshHelpers.sphere(mill, 0.16, Color("#F2C24B"), Vector3(0, 4.45, 0), Color("#F2C24B"), 1.5)
	for i in range(4):
		var a := TAU * float(i) / 4.0
		var blade := MeshHelpers.box(mill, Vector3(0.5, 2.6, 0.1), Color("#FFF2D8"),
			Vector3(cos(a) * 1.2, 2.8 + sin(a) * 1.2, 0.5), Vector3(0, 0, a))
		blade.rotation.z = a
	# sacchi
	for i in range(4):
		var p := c + Vector3(-9.0 + float(i) * 2.0, 0, -9.0)
		MeshHelpers.sphere(root, 0.55, Color("#D8B98A"), p + Vector3(0, 0.55, 0), Color(0, 0, 0, 0), 0.0, 12)
		MeshHelpers.box(root, Vector3(0.55, 0.22, 0.4), Color("#B98A55"), p + Vector3(0, 0.95, 0))
	# barili del mulino e pini sul retro
	ModelLibrary.place(root, "barrel", c + Vector3(-3.4, 0, -9.4), 0.2, 1.1)
	ModelLibrary.place(root, "barrel", c + Vector3(-2.3, 0, -8.6), 0.8, 0.9)
	for i in range(3):
		ModelLibrary.place(root, "tree_pine", c + Vector3(-9.5 + float(i) * 2.6, 0, -11.0),
			_rng.randf() * TAU, _rng.randf_range(0.9, 1.25))

func _props_citta(root: Node3D, c: Vector3, color: Color) -> void:
	# tre casette con la facciata rivolta verso la radura
	for i in range(3):
		var p := c + Vector3(-8.6 + float(i) * 8.6, 0, -10.2)
		if ModelLibrary.place(root, "cottage", p, PI, _rng.randf_range(0.9, 1.05), 2.5) == null:
			var h := 2.6
			var w := 3.4
			MeshHelpers.box(root, Vector3(w, h, 2.6), Color("#E8CFA6"), p + Vector3(0, h / 2, 0))
			MeshHelpers.prism(root, Vector3(w + 0.3, 1.0, 2.9), color.darkened(0.12), p + Vector3(0, h + 0.5, 0))
			MeshHelpers.box(root, Vector3(0.6, 0.8, 0.08), Color("#8A6242"), p + Vector3(0, 0.6, 1.32))
			for side in [-1.0, 1.0]:
				MeshHelpers.box(root, Vector3(0.5, 0.5, 0.08), Color("#FFD98A"), p + Vector3(0.8 * side, h * 0.62, 1.32))
	# lanterne e casse del mercato
	for i in range(3):
		var p := c + Vector3(-5.0 + float(i) * 5.0, 0, -5.6)
		ModelLibrary.place(root, "lantern", p, 0.0, 0.9)
	ModelLibrary.place(root, "crate", c + Vector3(-2.2, 0, -6.4), 0.3, 1.0)
	ModelLibrary.place(root, "crate", c + Vector3(-1.2, 0, -6.6), -0.2, 0.85)
	ModelLibrary.place(root, "barrel", c + Vector3(2.4, 0, -6.5), 0.0, 1.0)
	# insegne
	for i in range(3):
		var p := c + Vector3(-5.0 + float(i) * 5.0, 0, 10.5)
		MeshHelpers.cylinder(root, 0.05, 0.06, 2.4, Color("#A97A48"), p + Vector3(0, 1.2, 0))
		MeshHelpers.box(root, Vector3(1.6, 0.6, 0.08), color, p + Vector3(0, 2.2, 0))

func _props_torre(root: Node3D, c: Vector3, color: Color) -> void:
	var tower := Node3D.new()
	tower.position = c + Vector3(0, 0, -9.2)
	root.add_child(tower)
	for i in range(4):
		var r := 2.2 - float(i) * 0.32
		MeshHelpers.cylinder(tower, r, r + 0.12, 1.4, Color("#D8C3A5") if i % 2 == 0 else Color("#C9B18F"),
			Vector3(0, 0.7 + float(i) * 1.3, 0))
	for i in range(10):
		var a := TAU * float(i) / 10.0
		MeshHelpers.sphere(tower, 0.13, Color("#FFE066"),
			Vector3(cos(a) * 1.5, 6.4, sin(a) * 1.5), Color("#FFE066"), 2.0)
	MeshHelpers.sphere(tower, 0.7, Color("#F2C24B"), Vector3(0, 7.2, 0), Color("#F2C24B"), 3.0)
	MeshHelpers.torus(tower, 1.0, 1.15, color, Vector3(0, 7.2, 0), Vector3.ZERO, color, 0.8)
	# telescopio
	var tel := Node3D.new()
	tel.position = c + Vector3(8.0, 0, -7.0)
	tel.rotation.y = -0.7
	root.add_child(tel)
	MeshHelpers.cylinder(tel, 0.08, 0.14, 1.2, Color("#A97A48"), Vector3(0, 0.6, 0))
	MeshHelpers.cylinder(tel, 0.18, 0.22, 1.4, Color("#5FA8D3"), Vector3(0, 1.5, 0), Vector3(deg_to_rad(55), 0, 0))
	# pini e rocce attorno alla torre
	for i in range(4):
		var a := TAU * float(i) / 4.0 + 0.7
		var p := c + Vector3(cos(a) * 10.4, 0, sin(a) * 10.4)
		if i % 2 == 0:
			ModelLibrary.place(root, "tree_pine", p, _rng.randf() * TAU, _rng.randf_range(1.0, 1.3))
		else:
			ModelLibrary.place(root, "rock", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.3))

# ---------------------------------------------------------------- festa di regione
## Un festone nel colore della regione, steso tra due alberi ai lati della radura.
func _region_festivities(root: Node3D, c: Vector3, color: Color) -> void:
	var a := Vector3(c.x - 5.5, 2.3, c.z + 4.5)
	var b := Vector3(c.x + 5.5, 2.3, c.z + 4.5)
	var cols: Array[Color] = [color.lightened(0.15), Color("#FFF7E8"), color.darkened(0.08)]
	_bunting(root, a, b, cols, 8, 0.2)

# ---------------------------------------------------------------- personaggi
## I custodi delle regioni e gli amici animali vagano e salutano il giocatore.
func _build_characters() -> void:
	# Custodi: uno per regione, con la voce e la frase della propria terra.
	for i in range(10):
		var center: Vector3 = region_centers[i]
		var toward_hub := (hub_position - center).normalized()
		var side := toward_hub.cross(Vector3.UP).normalized()
		var home := center + toward_hub * 8.5 + side * 6.8
		home.y = 0.2
		_spawn_npc({
			"name": MissionData.CUSTODIANS[i],
			"voice": MissionData.CUSTODIANS[i].to_lower(),
			"greeting": MissionData.CUSTODIAN_LINES[i],
			"kind": "kid",
			"appearance": _custodian_appearance(i),
			"radius": 5.5,
			"home": home,
		})
	# Un amico animale per regione: accompagna il custode e rende la radura viva.
	var animals := [
		{"name": "Nocciola", "kind": "coniglio", "color": Color("#E8D3B0"),
			"greeting": "Nel bosco ho nascosto una ghianda. La cerchiamo insieme?"},
		{"name": "Brezza", "kind": "uccello", "color": Color("#7EC8E3"),
			"greeting": "Ascolta come fischia il vento tra le foglie!"},
		{"name": "Petalo", "kind": "gatto", "color": Color("#E88BA5"),
			"greeting": "Qui i fiori profumano di miele. Annusa!"},
		{"name": "Binario", "kind": "volpe", "color": Color("#E8944A"),
			"greeting": "Il treno passa e fa ciuff ciuff! Lo aspettiamo?"},
		{"name": "Cometa", "kind": "riccio", "color": Color("#8E7CC3"),
			"greeting": "Le stelle qui brillano anche di giorno!"},
		{"name": "Sasso", "kind": "tartaruga", "color": Color("#6DBE6D"),
			"greeting": "Ho misurato un sasso con le zampe: è lungo tre passi!"},
		{"name": "Foglia", "kind": "coniglio", "color": Color("#B8D8A8"),
			"greeting": "Shhh... i libri stanno raccontando una storia."},
		{"name": "Tic", "kind": "uccello", "color": Color("#F5D76E"),
			"greeting": "Le sillabe fanno clap clap! Proviamo?"},
		{"name": "Insegna", "kind": "gatto", "color": Color("#5FA8D3"),
			"greeting": "In città ogni insegna ha il suo colore!"},
		{"name": "Luce", "kind": "volpe", "color": Color("#F2C24B"),
			"greeting": "Dalla torre si vedono tutte le luci di Lumeria!"},
	]
	for i in range(animals.size()):
		var center2: Vector3 = region_centers[i]
		var toward_hub2 := (hub_position - center2).normalized()
		var side2 := toward_hub2.cross(Vector3.UP).normalized()
		var home2 := center2 + toward_hub2 * 4.0 - side2 * 7.4
		home2.y = 0.2
		var a: Dictionary = animals[i]
		_spawn_npc({
			"name": a["name"], "voice": "animale%d" % (i + 1), "kind": a["kind"],
			"greeting": a["greeting"], "color": a["color"], "radius": 5.0, "home": home2,
		})
	# Amici nella piazza: rendono l'Hub vivo e accogliente.
	_spawn_npc({"name": "Coniglietto", "voice": "coniglio", "kind": "coniglio",
		"greeting": "Ciao! Sono il coniglietto di Lumeria. Vuoi saltellare con me?",
		"color": Color("#F5E9DA"), "radius": 6.0, "home": Vector3(5.2, 0.2, 5.2)})
	_spawn_npc({"name": "Cip", "voice": "uccello", "kind": "uccello",
		"greeting": "Cip cip! Il cielo oggi è pieno di colori!",
		"color": Color("#7EC8E3"), "radius": 7.0, "home": Vector3(-5.6, 0.2, -3.0)})
	_spawn_npc({"name": "Micino", "voice": "gatto", "kind": "gatto",
		"greeting": "Miao! Sdraiati un po' e guarda le luci, se vuoi.",
		"color": Color("#E8A65A"), "radius": 7.0, "home": Vector3(3.2, 0.2, -6.2)})
	_spawn_npc({"name": "Tarta", "voice": "tarta", "kind": "tartaruga",
		"greeting": "Piano piano si va lontano! Vuoi fare due passi con me?",
		"color": Color("#8CCB7A"), "radius": 5.0, "home": Vector3(-6.8, 0.2, 5.6)})
	_spawn_npc({"name": "Fiamma", "voice": "volpe", "kind": "volpe",
		"greeting": "Che bello correre sull'erba! Ti va di giocare?",
		"color": Color("#E8944A"), "radius": 6.5, "home": Vector3(6.6, 0.2, 0.4)})
	_spawn_npc({"name": "Pungi", "voice": "riccio", "kind": "riccio",
		"greeting": "Sto raccogliendo foglie per il mio nido. Mi accompagni?",
		"color": Color("#9A6B4D"), "radius": 5.5, "home": Vector3(-3.4, 0.2, -6.9)})
	# Due bambini del posto: giocano vicino ai chioschi.
	_spawn_npc({"name": "Nino", "voice": "amico1", "kind": "kid",
		"greeting": "Ciao! Io conto le nuvole. Oggi ce ne sono tre!",
		"appearance": {"body": 0, "body_color": 2, "outfit_color": 1, "hat": 2, "hat_color": 3},
		"radius": 4.5, "home": Vector3(-7.2, 0.2, -4.6)})
	_spawn_npc({"name": "Lia", "voice": "amico2", "kind": "kid",
		"greeting": "Ho trovato una piuma blu! La regalo a te.",
		"appearance": {"body": 1, "body_color": 6, "outfit_color": 4, "hat": 3, "hat_color": 0},
		"radius": 4.5, "home": Vector3(7.0, 0.2, -5.4)})

func _spawn_npc(cfg: Dictionary) -> void:
	var npc := WorldNpc.new()
	npc.position = cfg["home"]
	add_child(npc)
	npc.setup(cfg)
	characters.append(npc)

## Aspetto unico per ogni custode: colore e copricapo richiamano la sua regione.
func _custodian_appearance(i: int) -> Dictionary:
	var list: Array = [
		{"body": 0, "body_color": 0, "outfit_color": 4, "hat": 3, "hat_color": 0},  # Lino
		{"body": 1, "body_color": 4, "outfit_color": 7, "hat": 1, "hat_color": 4},  # Ora
		{"body": 2, "body_color": 0, "outfit_color": 5, "hat": 3, "hat_color": 1},  # Pina
		{"body": 0, "body_color": 2, "outfit_color": 2, "hat": 2, "hat_color": 4},  # Tiko
		{"body": 1, "body_color": 7, "outfit_color": 3, "hat": 1, "hat_color": 3},  # Fero
		{"body": 2, "body_color": 2, "outfit_color": 6, "hat": 2, "hat_color": 2},  # Milla
		{"body": 0, "body_color": 5, "outfit_color": 6, "hat": 1, "hat_color": 0},  # Eco
		{"body": 1, "body_color": 4, "outfit_color": 1, "hat": 3, "hat_color": 4},  # Sila
		{"body": 2, "body_color": 6, "outfit_color": 7, "hat": 2, "hat_color": 3},  # Bibi
		{"body": 1, "body_color": 0, "outfit_color": 5, "hat": 1, "hat_color": 4},  # Astra
	]
	return list[i % list.size()]

# ---------------------------------------------------------------- incontri
func _spawn_collectibles() -> void:
	var firefly_n := 30
	for i in range(firefly_n):
		var id := "ff_%02d" % i
		if SaveGame.has_collectible("fireflies", id):
			continue
		var p := _random_world_point(16.0, 82.0)
		p.y = 0.85
		var c := WorldCollectible.new()
		c.position = p
		add_child(c)
		c.setup("fireflies", id)
		collectibles.append(c)
	for i in range(12):
		var id := "cr_%02d" % i
		if SaveGame.has_collectible("critters", id):
			continue
		var p := _random_world_point(14.0, 84.0)
		p.y = 0.15
		var c := WorldCollectible.new()
		c.position = p
		add_child(c)
		c.setup("critters", id)
		collectibles.append(c)
	for i in range(12):
		var id := "st_%02d" % i
		if SaveGame.has_collectible("stones", id):
			continue
		var p := _random_world_point(14.0, 84.0)
		p.y = 0.15
		var c := WorldCollectible.new()
		c.position = p
		add_child(c)
		c.setup("stones", id)
		collectibles.append(c)

func _random_world_point(min_r: float, max_r: float) -> Vector3:
	for attempt in range(40):
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(min_r, max_r)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var ok := true
		for rc in region_centers:
			if p.distance_to(Vector3(rc.x, 0, rc.z)) < REGION_MEADOW + 2.2:
				ok = false
				break
		if ok:
			return p
	return Vector3(_rng.randf_range(-60, 60), 0, _rng.randf_range(-60, 60))

# ---------------------------------------------------------------- luci dei cartelli
## Accende progressivamente le insegne delle regioni quando il giocatore passa.
func _process(delta: float) -> void:
	if _sign_lights.is_empty():
		return
	_sign_phase += delta
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	var pulse := 1.0
	if not bool(Settings.get_setting("reduce_motion", false)):
		pulse = 0.92 + 0.08 * sin(_sign_phase * 2.1)
	for entry in _sign_lights:
		var center: Vector3 = entry["center"]
		var radius := float(entry["radius"])
		var d := p.global_position.distance_to(center)
		var target := clampf((radius - d) / (radius - 4.0), 0.0, 1.0)
		target = target * target * (3.0 - 2.0 * target)
		entry["level"] = lerpf(float(entry["level"]), target, clampf(delta * 4.0, 0.0, 1.0))
		var lamp: OmniLight3D = entry["light"]
		if lamp:
			var level := float(entry["level"])
			lamp.visible = level > 0.015
			lamp.light_energy = level * 1.8 * pulse * Settings.glow_scale()

# ---------------------------------------------------------------- query
func nearest_station(pos: Vector3, radius: float = 3.0) -> RegionStation:
	var best: RegionStation = null
	var best_d := radius
	for s in stations:
		var d := s.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = s
	for s in special_stations:
		var d2 := s.global_position.distance_to(pos)
		if d2 < best_d:
			best_d = d2
			best = s
	return best

func nearest_collectible(pos: Vector3, radius: float = 2.4) -> WorldCollectible:
	var best: WorldCollectible = null
	var best_d := radius
	for c in collectibles:
		if not is_instance_valid(c):
			continue
		var d := c.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = c
	return best

func station_by_id(id: String) -> RegionStation:
	for s in stations:
		if s.station_id == id:
			return s
	return null

func special_station(kind: String) -> RegionStation:
	return _special_by_kind.get(kind, null)

func region_at(pos: Vector3) -> int:
	if pos.distance_to(hub_position) < 12.5:
		return 0
	var best := 0
	var best_d := REGION_MEADOW + 3.0
	for i in range(region_centers.size()):
		var d := pos.distance_to(region_centers[i])
		if d < best_d:
			best_d = d
			best = i + 1
	return best

func refresh_completed() -> void:
	for s in stations:
		if s.mission.is_empty():
			continue
		s.set_completed(SaveGame.is_mission_completed(s.station_id))

func count_completed() -> int:
	return SaveGame.completed_count()
