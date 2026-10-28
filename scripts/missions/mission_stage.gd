class_name MissionStage
extends Node3D
## Tavolo 3D di una missione: cubi, incastri, camera, aiuti e validazione.
## La stessa scena serve anche al Laboratorio libero (lab_mode).

signal completed(mission: Dictionary)
signal next_requested(mission: Dictionary)
signal closed
signal pause_requested

var mission: Dictionary = {}
var lab_mode := false

var _camera: Camera3D
var _board_root: Node3D
var _cube_nodes: Dictionary = {}
var _socket_nodes: Dictionary = {}
var _placements: Dictionary = {}
var _tray_items: Array[MissionCube3D] = []
var _board_items: Array[MissionSocket3D] = []
var _held: MissionCube3D = null
var _hints_used := 0
var _done := false
var _overlay_open := false
var _subtitle_timer := 0.0
var _board_depth := 4.0
var _board_w := 4.0
var _tray_w := 4.0
var _tray_start_z := 2.0
var _tray_z_max := 4.0
var _required_cubes := 0
var _hold_y := 1.85
var _camera_base := Vector3.ZERO
var _camera_target := Vector3.ZERO
var _camera_offset := Vector3.ZERO
var _cam_focus := Vector3.ZERO
var _cam_zoom := 1.0
var _phase := 0.0
var _env: Environment

var _ui: CanvasLayer
var _ui_root: Control
var _title_label: Label
var _instr_label: Label
var _hint_label: Label
var _progress_label: Label
var _focus_label: Label
var _subtitle_label: Label
var _subtitle_panel: PanelContainer
var _success_layer: Control
var _success_title: Label
var _success_text: Label
var _success_next: Button
var _exit_layer: Control
var _hint_text := ""
var quiet := false

# Anteprima 3D del cubo in mano: un piccolo palcoscenico nello schermo.
var _preview_panel: PanelContainer
var _preview_viewport: SubViewport
var _preview_spin: Node3D
var _preview_rays: Node3D
var _preview_cube: MissionCube3D
var _preview_name: Label
var _preview_hint: Label

# Il personaggio della missione: prende le casse dal banco e le porta sulle
# pedane camminando, invece di farle comparire o sparire.
var _avatar: Node3D
var _avatar_model: Node3D
var _carry_anchor: Node3D
var _avatar_home := Vector3.ZERO
var _avatar_walking := false
var _avatar_busy := false
var _avatar_phase := 0.0
var _avatar_limbs: Dictionary = {}
var _skip_avatar := false
var _was_quiet := false
var _near_node: Node3D = null
var _step_sfx := 0.0
var _has_moved := false

## Distanza entro cui il personaggio può prendere una cassa o posarla.
const REACH := 1.30

func setup(m: Dictionary, is_lab: bool = false) -> void:
	mission = m
	lab_mode = is_lab

func _ready() -> void:
	position = Vector3(0, 300, 0)
	_build_environment()
	_build_lights()
	_build_camera()
	_build_board()
	_build_ui()
	Audio.subtitle.connect(_on_subtitle)
	call_deferred("_intro")

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "AmbienteMissione"
	var env := Environment.new()
	# Sfondo a cielo procedurale: una sfumatura morbida invece di un azzurro
	# piatto, così il tavolo sembra appoggiato in un ambiente e non nel vuoto.
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#6E9FC6")
	sm.sky_horizon_color = Color("#E8F1F7")
	sm.sky_curve = 0.14
	sm.sky_energy_multiplier = 1.0
	sm.ground_bottom_color = Color("#AEBECB")
	sm.ground_horizon_color = Color("#DCE7EF")
	sm.ground_curve = 0.06
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFE8C4")
	env.ambient_light_energy = 0.54
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = Settings.glow_energy(0.10)
	env.glow_bloom = Settings.glow_energy(0.03)
	env.glow_hdr_threshold = 1.35
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 2.2
	env.ssao_power = 1.4
	env.fog_enabled = false
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.12
	we.environment = env
	_env = env
	add_child(we)
	apply_quality(int(Settings.get_setting("quality", 1)))
	Settings.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(key: String) -> void:
	if key in ["glow", "quality", "all"]:
		apply_quality(int(Settings.get_setting("quality", 1)))

## Stessi effetti del mondo, regolati dalla qualità scelta e dallo slider
## del bagliore: nessun alone resta fisso a un valore troppo forte.
func apply_quality(level: int) -> void:
	if _env == null:
		return
	_env.ssao_enabled = level >= 1
	_env.glow_enabled = level >= 1
	_env.glow_intensity = Settings.glow_energy(0.10)
	_env.glow_bloom = Settings.glow_energy(0.03)

func _intro() -> void:
	if quiet:
		return
	Audio.say("%s. %s" % [mission.get("title", ""), mission.get("instruction", "")], true, 0.25)

func set_suspended(value: bool) -> void:
	set_process_unhandled_input(not value)
	set_process(not value)

# ---------------------------------------------------------------- scena
func _build_lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-46), deg_to_rad(-30), 0)
	key.light_color = Color("#FFF0D0")
	key.light_energy = 1.2
	key.shadow_enabled = true
	key.shadow_blur = 1.6
	key.directional_shadow_max_distance = 42.0
	key.shadow_bias = 0.03
	key.shadow_normal_bias = 1.2
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-5, 5.5, 7)
	fill.light_color = Color("#9FD8E8")
	fill.light_energy = 0.7
	fill.omni_range = 26
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-20), deg_to_rad(155), 0)
	rim.light_color = Color("#FFD6A0")
	rim.light_energy = 0.45
	add_child(rim)
	# pozza di luce calda sul tavolo: stacca la scena dallo sfondo
	var pool := OmniLight3D.new()
	pool.position = Vector3(0, 7.5, 1.0)
	pool.light_color = Color("#FFE2B0")
	pool.light_energy = 2.2
	pool.omni_range = 18.0
	pool.omni_attenuation = 1.4
	add_child(pool)

func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "CameraMissione"
	# Obiettivo lungo: il tavolo resta leggibile senza deformare i cubi vicini.
	_camera.fov = 42.0
	_camera.near = 0.05
	_camera.far = 120.0
	add_child(_camera)
	_camera.current = true

func _build_avatar() -> void:
	_avatar = null
	_avatar_model = null
	_carry_anchor = null
	_avatar_limbs.clear()
	_avatar_walking = false
	_avatar_busy = false
	if _board_root == null:
		return
	_avatar = Node3D.new()
	_avatar.name = "Personaggio"
	_board_root.add_child(_avatar)
	var model := AvatarBuilder.build(SaveGame.appearance())
	model.name = "Modello"
	model.scale = Vector3.ONE * 0.8
	_avatar.add_child(model)
	_avatar_model = model
	for limb_name in ["BraccioDestro", "BraccioSinistro", "GambaDestra", "GambaSinistra"]:
		var limb := model.find_child(limb_name, true, false) as Node3D
		if limb:
			_avatar_limbs[limb_name] = limb
	# Le mani sono davanti (-Z, avanti dell'avatar), all'altezza del petto.
	_carry_anchor = Node3D.new()
	_carry_anchor.name = "Mani"
	_carry_anchor.position = Vector3(0, 0.82, -0.30)
	_avatar.add_child(_carry_anchor)
	# Il personaggio aspetta su una piccola balconata a destra del tavolo:
	# da lì non copre né le pedane né il banco delle casse.
	var bx := _board_w * 0.5 + 0.85
	var bz := _board_depth * 0.5 - 0.3
	MeshHelpers.cylinder(_board_root, 0.52, 0.68, 0.70, Color("#B98A55"),
		Vector3(bx, 0.35, bz), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 24)
	MeshHelpers.box(_board_root, Vector3(1.25, 0.1, 1.25), Color("#EBD9B8"),
		Vector3(bx, 0.72, bz))
	# Passerella verso il tavolo: il personaggio non cammina sul vuoto.
	var bridge_w := maxf(0.2, bx - 0.55 - _board_w * 0.5 + 0.1)
	MeshHelpers.box(_board_root, Vector3(bridge_w, 0.1, 1.4), Color("#E3D2B8"),
		Vector3(_board_w * 0.5 + bridge_w * 0.5, 0.72, bz))
	_avatar.position = Vector3(bx, 0.78, bz)
	_avatar_home = _avatar.position
	# Orientamento calcolato a mano: look_at su un nodo non ancora nell'albero
	# può inclinare l'avatar, e il personaggio finirebbe sdraiato sul tavolo.
	var look := Vector3(0, 0.78, -1.0) - _avatar.position
	_avatar.rotation = Vector3(0, atan2(-look.x, -look.z), 0)

## Altezza del piano su cui poggia il personaggio: tavolo, balconata o banco.
func _surface_height(pos: Vector3) -> float:
	if pos.z > _tray_start_z + 0.10:
		return 0.54
	return 0.78

## Posizione del nodo nello spazio del tavolo: cubi e pedane possono essere
## figli di altri nodi, quindi il punto di partenza va letto in globale.
func _world_position(node: Node3D) -> Vector3:
	return node.global_position if node != null else Vector3.ZERO

## Alza o abbassa le braccia: il gesto di prendere e posare la cassa.
func _arms_reach(value: bool) -> void:
	var target := -1.18 if value else 0.0
	for limb_name in ["BraccioDestro", "BraccioSinistro"]:
		var limb: Node3D = _avatar_limbs.get(limb_name, null)
		if limb == null:
			continue
		var tw := create_tween()
		tw.tween_property(limb, "rotation:x", target, 0.16)

## Con una cassa in mano le braccia restano avanti mentre si cammina.
func _hold_arms() -> void:
	for limb_name in ["BraccioDestro", "BraccioSinistro"]:
		var limb: Node3D = _avatar_limbs.get(limb_name, null)
		if limb:
			limb.rotation.x = -1.18

func _face_point(point: Vector3) -> void:
	if _avatar == null:
		return
	var dir := point - _avatar.global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		_avatar.rotation.y = atan2(-dir.x, -dir.z)

## Limita il passo alla superficie del tavolo, del banco e della balconata.
func _clamp_play_area(pos: Vector3) -> Vector3:
	var half_table := _board_w * 0.5
	var half_tray := _tray_w * 0.5
	pos.z = clampf(pos.z, -_board_depth * 0.5 + 0.30, _tray_z_max + 0.15)
	if pos.z < _board_depth * 0.5:
		pos.x = clampf(pos.x, -half_table + 0.30, half_table + 1.35)
	elif pos.z < _tray_start_z:
		pos.x = clampf(pos.x, -maxf(half_table, half_tray) + 0.30,
			maxf(half_table, half_tray) - 0.30)
	else:
		pos.x = clampf(pos.x, -half_tray + 0.30, half_tray - 0.30)
	# A destra del tavolo si passa solo dalla passerella della balconata.
	if pos.z < _board_depth * 0.5:
		if pos.x > half_table:
			if absf(pos.z - _avatar_home.z) > 0.68:
				pos.z = clampf(pos.z, _avatar_home.z - 0.68, _avatar_home.z + 0.68)
		elif absf(pos.z - _avatar_home.z) > 0.68:
			pos.x = minf(pos.x, half_table - 0.05)
	return pos

## Camminata libera: stick sinistro o WASD, con la stessa camera del tavolo.
func _update_free_move(delta: float) -> void:
	if _avatar == null:
		return
	if _avatar_busy or _done or _overlay_open:
		if not _avatar_busy:
			_rest_limbs()
			if _held != null:
				_hold_arms()
		return
	var ix := Input.get_axis("move_left", "move_right")
	var iz := Input.get_axis("move_forward", "move_back")
	var px := Input.get_axis("move_left_pad", "move_right_pad")
	var pz := Input.get_axis("move_up_pad", "move_down_pad")
	if bool(Settings.get_setting("dpad_only", false)) or absf(px) > 0.1 or absf(pz) > 0.1:
		ix = px
		iz = pz
	var moving := absf(ix) > 0.10 or absf(iz) > 0.10
	if moving:
		var yaw := _camera.global_rotation.y if _camera else 0.0
		var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var right := Vector3(cos(yaw), 0.0, -sin(yaw))
		var dir := (right * ix + forward * -iz).normalized()
		var speed := float(Settings.get_setting("avatar_speed", 4.6)) * 0.55
		var p := _avatar.position + dir * speed * delta
		p = _clamp_play_area(Vector3(p.x, 0.0, p.z))
		_avatar.position.x = p.x
		_avatar.position.z = p.z
		var floor_y := _surface_height(p)
		_avatar.position.y = lerpf(_avatar.position.y, floor_y,
			clampf(delta * 12.0, 0.0, 1.0))
		_avatar.rotation.y = atan2(-dir.x, -dir.z)
		_has_moved = true
		_animate_walk(delta)
		_step_sfx -= delta
		if _step_sfx <= 0.0:
			_step_sfx = 0.46
			Audio.play_sfx("tick", randf_range(0.76, 0.9))
	else:
		_step_sfx = 0.0
		_rest_limbs()
	if _held != null:
		_hold_arms()

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _nearest_cube() -> MissionCube3D:
	var best: MissionCube3D = null
	var best_d := REACH
	for value in _cube_nodes.values():
		var c := value as MissionCube3D
		if c == null or c == _held or not is_instance_valid(c):
			continue
		var d := _flat_distance(_avatar.global_position, c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best

## Pedana più vicina: preferisce quella giusta, senza nascondere le altre.
func _nearest_socket() -> MissionSocket3D:
	var best: MissionSocket3D = null
	var best_d := REACH
	var compat: MissionSocket3D = null
	var compat_d := REACH
	for s in _board_items:
		if s == null or s.is_fixed:
			continue
		if int(_placements.get(s.socket_id, []).size()) >= s.capacity:
			continue
		var d := _flat_distance(_avatar.global_position, s.global_position)
		if d >= REACH:
			continue
		if d < best_d:
			best_d = d
			best = s
		if _accepts(s, _held) and d < compat_d:
			compat_d = d
			compat = s
	return compat if compat != null else best

## Aggiorna l'oggetto in evidenza vicino al personaggio.
func _update_nearby(force: bool = false) -> void:
	if _avatar == null or _avatar_busy or _done or _overlay_open:
		_set_near(null)
		return
	var target: Node3D = null
	if _held != null:
		target = _nearest_socket()
	else:
		target = _nearest_cube()
	if target != _near_node or force:
		_set_near(target)
	_refresh_focus_text()

func _set_near(node: Node3D) -> void:
	if _near_node != null and is_instance_valid(_near_node):
		_near_node.set_focused(false)
	_near_node = node
	if _near_node != null and is_instance_valid(_near_node):
		_near_node.set_focused(true)

## Prende la cassa con un gesto breve: il personaggio è già vicino.
func _grab_cube(c: MissionCube3D) -> void:
	if c == null or _avatar_busy:
		return
	_avatar_busy = true
	_face_point(c.global_position)
	_arms_reach(true)
	await get_tree().create_timer(0.12, true).timeout
	if not is_inside_tree():
		_avatar_busy = false
		return
	if c.placed:
		_pick_from_socket_now(c)
	else:
		_pick_now(c)
	_attach_to_hands(c)
	await get_tree().create_timer(0.10, true).timeout
	_avatar_busy = false
	_update_nearby(true)

## Posare la cassa sulla pedana scelta, con lo stesso controllo di sempre.
func _release_held(sock: MissionSocket3D) -> void:
	if sock == null or _held == null or _avatar_busy:
		return
	_avatar_busy = true
	_face_point(sock.global_position)
	_arms_reach(true)
	await get_tree().create_timer(0.12, true).timeout
	if not is_inside_tree():
		_avatar_busy = false
		return
	_place_now(sock)
	await get_tree().create_timer(0.10, true).timeout
	_avatar_busy = false
	_update_nearby(true)

## Avvicina l'avatar a un oggetto senza salirci sopra.
func _stand_point(target: Vector3, distance: float = 0.72) -> Vector3:
	var p := _avatar.global_position if _avatar else Vector3.ZERO
	var dir := p - target
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3(0, 0, 1)
	return target + dir.normalized() * distance

func _walk_avatar_to(target: Vector3, speed: float = 3.6) -> void:
	if _avatar == null or not is_inside_tree():
		return
	var dest := _clamp_play_area(Vector3(target.x, _avatar.position.y, target.z))
	var flat := Vector2(_avatar.position.x - dest.x, _avatar.position.z - dest.z)
	if flat.length() < 0.06:
		return
	_has_moved = true
	_avatar_walking = true
	_avatar_phase = 0.0
	var guard := 0.0
	while is_inside_tree() and _avatar != null:
		# Il passo si misura sul piano: l'altezza cambia salendo sul banco e
		# non deve impedire al personaggio di considerarsi arrivato.
		flat = Vector2(_avatar.position.x - dest.x, _avatar.position.z - dest.z)
		if flat.length() <= 0.05:
			break
		var delta := get_process_delta_time()
		if delta <= 0.0:
			delta = 0.016
		var dir := dest - _avatar.position
		dir.y = 0.0
		if dir.length() > 0.001:
			var step := minf(dir.length(), speed * delta)
			_avatar.position += dir.normalized() * step
			_avatar.rotation.y = atan2(-dir.x, -dir.z)
			var floor_y := _surface_height(_avatar.position)
			_avatar.position.y = lerpf(_avatar.position.y, floor_y,
				clampf(delta * 10.0, 0.0, 1.0))
		_animate_walk(delta)
		guard += delta
		if guard > 8.0:
			break
		await get_tree().process_frame
	_avatar_walking = false
	_rest_limbs()
	if _held != null:
		_hold_arms()

## Passo stilizzato: gambe e braccia alternate, con un piccolo sobbalzo.
func _animate_walk(delta: float) -> void:
	_avatar_phase += delta * 9.0
	var swing := sin(_avatar_phase) * 0.55
	var right: Node3D = _avatar_limbs.get("GambaDestra", null)
	var left: Node3D = _avatar_limbs.get("GambaSinistra", null)
	if right:
		right.rotation.x = swing
	if left:
		left.rotation.x = -swing
	var arm_r: Node3D = _avatar_limbs.get("BraccioDestro", null)
	var arm_l: Node3D = _avatar_limbs.get("BraccioSinistro", null)
	if _held == null:
		if arm_r:
			arm_r.rotation.x = -swing * 0.6
		if arm_l:
			arm_l.rotation.x = swing * 0.6
	else:
		_hold_arms()
	if _avatar_model:
		_avatar_model.position.y = absf(sin(_avatar_phase)) * 0.025

func _rest_limbs() -> void:
	for limb_name in _avatar_limbs.keys():
		var limb: Node3D = _avatar_limbs[limb_name]
		if limb:
			limb.rotation.x = 0.0
	if _avatar_model:
		_avatar_model.position.y = 0.0

## Riporta un cubo alla scena principale: serve prima di rimetterlo al banco.
func _detach_cube(c: MissionCube3D) -> void:
	if c == null or _board_root == null:
		return
	if c.get_parent() != _board_root:
		if c.get_parent():
			c.get_parent().remove_child(c)
		_board_root.add_child(c)

## Mette il cubo nelle mani del personaggio mentre lo porta in giro.
func _attach_to_hands(c: MissionCube3D) -> void:
	if c == null or _carry_anchor == null:
		return
	if c.get_parent():
		c.get_parent().remove_child(c)
	_carry_anchor.add_child(c)
	c.position = Vector3.ZERO
	c.rotation = Vector3.ZERO
	c.scale = c.shape_scale(0.62)
	c.set_pickable(false)

func _build_board() -> void:
	if _board_root and is_instance_valid(_board_root):
		_board_root.queue_free()
	_board_root = Node3D.new()
	_board_root.name = "Tavolo"
	add_child(_board_root)
	_cube_nodes.clear()
	_socket_nodes.clear()
	_placements.clear()
	_tray_items.clear()
	_board_items.clear()
	_held = null
	_done = false
	_hints_used = 0
	_hint_text = ""
	_near_node = null
	_has_moved = false
	_step_sfx = 0.0
	_hide_cube_preview()
	if _hint_label:
		_hint_label.text = "Premi X per un aiuto."

	var sockets: Array = mission.get("sockets", [])
	var cubes: Array = mission.get("cubes", [])
	var grid := _socket_grid(sockets)
	var rows: int = int(grid["rows"])
	var cells: Array = grid["cells"]
	# Le risposte non seguono l'ordine di inserimento: i cubi del banco vengono
	# mescolati in modo deterministico per ogni missione. Gli incastri restano
	# invece dove sono quando la loro posizione ha un significato (destra,
	# sinistra, sopra, sotto, primo, secondo...).
	var cube_order: Array[int] = []
	for i in range(cubes.size()):
		cube_order.append(i)
	_shuffle_order(cube_order, _mission_rng("cubes"))
	_board_w = float(grid["width"]) * 1.6 + 1.2
	_board_depth = float(rows) * 1.6 + 1.1
	var basket_mode := bool(grid.get("baskets", false))
	if basket_mode:
		# Le due piattaforme circolari hanno bisogno di spazio dietro per il
		# cartello con l'immagine che spiega cosa ci va dentro.
		_board_depth = 4.4
	var board_z := 0.0

	MeshHelpers.cylinder(_board_root, 1.5, 1.7, 0.55, Color("#D8C3A5"), Vector3(0, 0.28, 0), Vector3.ZERO,
		Color(0, 0, 0, 0), 0.0, 28)
	MeshHelpers.box(_board_root, Vector3(_board_w + 0.5, 0.28, _board_depth + 0.5), Color("#B98A55"),
		Vector3(0, 0.55, board_z))
	MeshHelpers.box(_board_root, Vector3(_board_w, 0.1, _board_depth), Color("#EBD9B8"),
		Vector3(0, 0.72, board_z))
	_board_frame(_board_w, _board_depth, 0.778)
	if basket_mode:
		_build_basket_platforms()

	# Vetrina degli oggetti da contare / mappa del percorso, accanto alla tavola.
	var display: Array = mission.get("display", [])
	var route: Dictionary = mission.get("route", {})
	var extra_x := -_board_w * 0.5 - 0.55
	if not display.is_empty():
		var meta := _build_display_shelf(display, extra_x, board_z)
		extra_x = float(meta.get("left", extra_x)) - 0.45
	if not route.is_empty():
		_build_route_board(route, extra_x, board_z)

	var route_sockets: Array = route.get("sockets", []) if not route.is_empty() else []
	for i in range(sockets.size()):
		var s: Dictionary = sockets[i]
		var cell: Vector2 = cells[i]
		var x := float(cell.x) * 1.6
		var z := (float(cell.y) - float(rows - 1) * 0.5) * 1.6
		var sock_id := str(s.get("id", ""))
		if not s.has("hint_label") and route_sockets.has(sock_id):
			s = s.duplicate(true)
			s["hint_label"] = str(route_sockets.find(sock_id) + 1)
		var sock := MissionSocket3D.new()
		sock.position = Vector3(x, 0.78, z)
		_board_root.add_child(sock)
		sock.build(s, sock.position)
		sock.position = Vector3(x, 0.78, z)
		_socket_nodes[sock.socket_id] = sock
		_placements[sock.socket_id] = []
		if not sock.is_fixed:
			_board_items.append(sock)

	# banco dei cubi
	var tray_z0 := _board_depth * 0.5 + 1.55
	var tray_layout := _tray_layout(cubes, cube_order)
	var tray_rows := int(tray_layout["rows"])
	var row_step := 1.28
	var tray_w := float(tray_layout["width"]) + 0.7
	_tray_w = tray_w
	_tray_start_z = tray_z0 - (float(tray_rows) * row_step + 0.61) * 0.5
	# Passerella continua tra il tavolo e il banco: il personaggio può
	# camminare dal tavolo alle casse senza saltare nel vuoto.
	var apron_front := _board_depth * 0.5
	var apron_back := maxf(apron_front + 0.2, _tray_start_z + 0.25)
	var apron_depth := apron_back - apron_front + 0.4
	MeshHelpers.box(_board_root, Vector3(maxf(_board_w, tray_w) + 0.3, 0.1, apron_depth),
		Color("#E3D2B8"), Vector3(0, 0.70, apron_front + apron_depth * 0.5 - 0.2))
	MeshHelpers.box(_board_root, Vector3(tray_w, 0.18, float(tray_rows) * row_step + 0.61),
		Color("#B98A55"), Vector3(0, 0.4, tray_z0 + float(tray_rows - 1) * row_step * 0.5))
	MeshHelpers.box(_board_root, Vector3(tray_w - 0.25, 0.06, float(tray_rows) * row_step + 0.41),
		Color("#DFCCA8"), Vector3(0, 0.51, tray_z0 + float(tray_rows - 1) * row_step * 0.5))
	_tray_z_max = tray_z0 + float(tray_rows - 1) * row_step + 0.95
	for i in range(cubes.size()):
		var d: Dictionary = cubes[cube_order[i]]
		var slot: Vector2 = (tray_layout["positions"] as Dictionary).get(i, Vector2.ZERO)
		var x := slot.x
		var z := tray_z0 + slot.y
		var cube := MissionCube3D.new()
		cube.position = Vector3(x, 0.98, z)
		_board_root.add_child(cube)
		cube.build(d, Vector3(x, 0.98, z))
		cube.position = Vector3(x, 0.98, z)
		_cube_nodes[cube.cube_id] = cube
		_tray_items.append(cube)
	_required_cubes = _solution_cube_count()
	_build_avatar()

	# Il titolo vive nel pannello dell'interfaccia: sul tavolo occuperebbe la vetrina.
	_frame_points(_content_points())
	if _ui:
		_refresh_ui()
		_update_nearby(true)

## Larghezza reale di un cubo sul banco: le corde lunghe occupano più spazio,
## altrimenti si sovrapporrebbero alle casse vicine e non si leggerebbe più
## quanto sono lunghe.
func _tray_item_width(d: Dictionary) -> float:
	var bar: Dictionary = d.get("bar", {}) if d.get("bar", {}) is Dictionary else {}
	if not bar.is_empty():
		return maxf(1.12, float(bar.get("length", 2)) * MissionCube3D.BAR_UNIT + 0.42)
	return 1.12

## Dispone le casse in righe, con celle larghe quanto l'oggetto. Le righe sono
## centrate e non si sovrappongono.
func _tray_layout(cubes: Array, order: Array) -> Dictionary:
	var gap := 0.26
	var max_row := 6.0 * 1.12 + 0.7
	var rows: Array = []
	var current: Array = []
	var current_w := 0.0
	for i in range(order.size()):
		var d: Dictionary = cubes[order[i]]
		var w := _tray_item_width(d)
		var add := w if current.is_empty() else gap + w
		if not current.is_empty() and current_w + add > max_row:
			rows.append({"items": current, "width": current_w})
			current = []
			current_w = 0.0
			add = w
		current.append({"index": i, "width": w})
		current_w += add
	if not current.is_empty():
		rows.append({"items": current, "width": current_w})
	var positions := {}
	var row_step := 1.28
	for r in range(rows.size()):
		var row: Dictionary = rows[r]
		var cursor := -float(row["width"]) * 0.5
		for item in row["items"]:
			var w := float(item["width"])
			positions[int(item["index"])] = Vector2(cursor + w * 0.5, float(r) * row_step)
			cursor += w + gap
	var width := 0.0
	for row in rows:
		width = maxf(width, float(row["width"]))
	return {"positions": positions, "rows": maxi(1, rows.size()), "width": width}

## Punti reali di ciò che è stato costruito sul tavolo: inquadrare la sagoma
## proiettata evita di riservare spazio per l'aria vuota dietro gli oggetti.
func _content_points() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for child in _board_root.get_children():
		_collect_points(child, Transform3D.IDENTITY, pts)
	return pts

func _collect_points(node: Node, xf: Transform3D, out: Array[Vector3]) -> void:
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is VisualInstance3D and not (node as VisualInstance3D).visible:
		return
	if node is MeshInstance3D:
		var a: AABB = (node as MeshInstance3D).get_aabb()
		for i in range(8):
			out.append(t * (a.position + Vector3(
				a.size.x if (i & 1) else 0.0,
				a.size.y if (i & 2) else 0.0,
				a.size.z if (i & 4) else 0.0)))
	elif node is Sprite3D or node is Label3D:
		# Icone ed etichette non hanno un AABB utile: un margine generoso basta.
		var p: Vector3 = t.origin
		out.append(p + Vector3(-0.45, -0.16, 0.0))
		out.append(p + Vector3(0.45, 0.24, 0.0))
	for child in node.get_children():
		_collect_points(child, t, out)

## Generatore deterministico per missione: la stessa missione mescola sempre
## allo stesso modo, ma missioni diverse hanno ordini diversi.
func _mission_rng(salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var n := int(str(mission.get("id", "0")))
	rng.seed = (n + 17) * 7919 + hash(salt) + hash(str(mission.get("title", "")))
	return rng

## Fisher-Yates con il generatore della missione. Se per caso l'ordine resta
## quello originale, ruota di uno: il banco non deve mai sembrare "in fila".
func _shuffle_order(order: Array[int], rng: RandomNumberGenerator) -> void:
	if order.size() < 2:
		return
	var before := order.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	var same := true
	for i in range(order.size()):
		if order[i] != before[i]:
			same = false
			break
	if same:
		var first := order[0]
		for i in range(order.size() - 1):
			order[i] = order[i + 1]
		order[order.size() - 1] = first

## Riconosce la missione delle due ceste: tre incastri per il cibo e tre per i
## giocattoli. Serve a dare a ogni cesto la sua piattaforma riconoscibile
## invece di due file indistinguibili sulla stessa tavola.
func _basket_layout() -> Dictionary:
	var sockets: Array = mission.get("sockets", [])
	if sockets.size() != 6:
		return {}
	var groups := {"cibo": [], "gioco": []}
	for s in sockets:
		if not (s is Dictionary):
			return {}
		var g := str(s.get("group", ""))
		if not groups.has(g):
			return {}
		(groups[g] as Array).append(s)
	if (groups["cibo"] as Array).size() != 3 or (groups["gioco"] as Array).size() != 3:
		return {}
	return groups

## Due grappoli di tre incastri, uno a sinistra (cibo) e uno a destra
## (giocattoli), ognuno dentro la propria piattaforma circolare.
func _basket_cells(sockets: Array) -> Array:
	var layout := _basket_layout()
	var cells: Array[Vector2] = []
	cells.resize(sockets.size())
	cells.fill(Vector2.ZERO)
	var offsets := [Vector2(0.0, -0.55), Vector2(-0.48, 0.28), Vector2(0.48, 0.28)]
	for side in ["cibo", "gioco"]:
		var cx := -1.1875 if side == "cibo" else 1.1875
		var group: Array = layout[side]
		for i in range(group.size()):
			var idx := sockets.find(group[i])
			if idx < 0:
				idx = i
			cells[idx] = Vector2(cx, 0.0) + offsets[i]
	return cells

## Due piattaforme rotonde, di colore diverso, con un cartello illustrato:
## un piatto e le posate per il CIBO, una palla e una stella per i GIOCATTOLI.
func _build_basket_platforms() -> void:
	var accents := {"cibo": Color("#E8A65A"), "gioco": Color("#7E8CD6")}
	var icons := {"cibo": "cibo", "gioco": "gioco"}
	var labels := {"cibo": "CIBO", "gioco": "GIOCATTOLI"}
	for side in ["cibo", "gioco"]:
		var cx := -1.90 if side == "cibo" else 1.90
		var accent: Color = accents[side]
		# Piattaforma circolare: bordo scuro, superficie chiara, anello colorato.
		MeshHelpers.cylinder(_board_root, 1.84, 1.90, 0.09, accent.darkened(0.18),
			Vector3(cx, 0.75, 0.0), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 40)
		MeshHelpers.cylinder(_board_root, 1.72, 1.76, 0.05, accent.lightened(0.40),
			Vector3(cx, 0.80, 0.0), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 40)
		MeshHelpers.torus(_board_root, 1.72, 1.86, accent, Vector3(cx, 0.795, 0.0),
			Vector3.ZERO, accent, 0.30)
		# Cartello illustrato dietro la piattaforma, rivolto verso la camera.
		MeshHelpers.cylinder(_board_root, 0.06, 0.08, 0.72, accent.darkened(0.32),
			Vector3(cx, 1.08, -2.02))
		MeshHelpers.box(_board_root, Vector3(2.16, 0.86, 0.08), accent.darkened(0.22),
			Vector3(cx, 1.62, -2.02))
		MeshHelpers.box(_board_root, Vector3(1.98, 0.70, 0.05), Color("#FFF7E8"),
			Vector3(cx, 1.62, -1.972))
		MeshHelpers.icon(_board_root, icons[side], accent.darkened(0.06), 0.62,
			Vector3(cx - 0.70, 1.62, -1.945), false)
		MeshHelpers.label(_board_root, labels[side], 38, Color("#3B2A20"),
			Vector3(cx + 0.24, 1.62, -1.945), 56, false)

## Disposizione degli incastri: rispetta l'ordine dei dati.
## - incastri con gruppi: una fila per gruppo (aiuole, case, cesti);
## - sequenze, percorsi, serie: una sola fila, come si legge;
## - il resto: griglia compatta, righe centrate.
func _socket_grid(sockets: Array) -> Dictionary:
	var n := sockets.size()
	var cells: Array[Vector2] = []
	if n <= 0:
		return {"cells": cells, "rows": 1, "width": 1}
	if not _basket_layout().is_empty():
		return {"cells": _basket_cells(sockets), "rows": 1, "width": 4, "baskets": true}
	var all_grouped := true
	var group_order: Array[String] = []
	var group_sizes := {}
	for s in sockets:
		var g := str(s.get("group", "")) if s is Dictionary else ""
		if g == "":
			all_grouped = false
			break
		if not group_sizes.has(g):
			group_sizes[g] = 0
			group_order.append(g)
		group_sizes[g] = int(group_sizes[g]) + 1
	if all_grouped and group_order.size() > 1:
		var row_of := {}
		for r in range(group_order.size()):
			row_of[group_order[r]] = r
		var used := {}
		var width := 1
		for s in sockets:
			var g := str(s.get("group", ""))
			var idx := int(used.get(g, 0))
			used[g] = idx + 1
			var size := int(group_sizes[g])
			width = maxi(width, size)
			cells.append(Vector2(float(idx) - float(size - 1) * 0.5, float(row_of[g])))
		return {"cells": cells, "rows": group_order.size(), "width": width}

	var linear := mission.has("route")
	for s in sockets:
		if s is Dictionary and s.has("fixed"):
			linear = true
	var kind := str(mission.get("kind", ""))
	if kind in ["pattern", "sequence", "arithmetic", "measurement"]:
		linear = true
	if linear:
		for i in range(n):
			cells.append(Vector2(float(i) - float(n - 1) * 0.5, 0.0))
		return {"cells": cells, "rows": 1, "width": maxi(1, n)}

	var cols: int
	if n <= 5:
		cols = n
	elif n <= 8:
		cols = int(ceil(float(n) * 0.5))
	else:
		cols = 5
	var rows := int(ceil(float(n) / float(cols)))
	for i in range(n):
		var r := i / cols
		var c := i % cols
		var in_row := mini(cols, n - r * cols)
		cells.append(Vector2(float(c) - float(in_row - 1) * 0.5, float(r)))
	return {"cells": cells, "rows": rows, "width": cols}

## Cornice dorata rettangolare: segue il tavolo invece di sporgere come un cerchio.
func _board_frame(w: float, d: float, y: float) -> void:
	var c := Color("#E8B84A")
	var t := 0.06
	for side in [-1.0, 1.0]:
		MeshHelpers.box(_board_root, Vector3(w + t, 0.05, t), c,
			Vector3(0, y, side * (d * 0.5 + t * 0.5)), Vector3.ZERO, c, 0.35)
		MeshHelpers.box(_board_root, Vector3(t, 0.05, d + t), c,
			Vector3(side * (w * 0.5 + t * 0.5), y, 0), Vector3.ZERO, c, 0.35)

## Quanti cubi servono davvero alla soluzione (gli avanzi sono distrattori).
func _solution_cube_count() -> int:
	var total := 0
	for value in PuzzleEval.solve(mission).values():
		total += (value as Array).size() if value is Array else 1
	return maxi(total, 1)

## Inquadratura calcolata sulla sagoma reale del tavolo, tenendo libera la fascia
## in alto occupata dai pannelli dell'interfaccia.
func _frame_points(points: Array[Vector3]) -> void:
	if points.is_empty():
		return
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	var target := (lo + hi) * 0.5
	target.y = 0.85
	var dir := Vector3(0.0, 0.66, 1.0).normalized()
	var half_v := deg_to_rad(_camera.fov * 0.5)
	var band := Rect2(0.035, 0.34, 0.93, 0.575)
	var dist := clampf((hi - lo).length() * 0.95, 6.0, 40.0)
	for _iter in range(14):
		_place_camera(target, dir, dist)
		var r := _project_bounds(points)
		var grow := maxf(r.size.x / band.size.x, r.size.y / band.size.y)
		dist = clampf(dist * clampf(grow, 0.70, 1.7), 4.5, 40.0)
		var dy := band.get_center().y - r.get_center().y
		if absf(dy) > 0.004:
			var up := _camera.global_transform.basis.y.normalized()
			target += up * dy * 2.0 * tan(half_v) * dist
		if absf(grow - 1.0) <= 0.012 and absf(dy) <= 0.004:
			break
	_place_camera(target, dir, dist)
	_camera_base = _camera.position
	_camera_target = target
	_camera_offset = _camera_base - _camera_target
	_cam_focus = _camera_target
	_cam_zoom = 1.0

func _place_camera(target: Vector3, dir: Vector3, dist: float) -> void:
	_camera.position = target + dir * dist
	_camera.look_at(to_global(target), Vector3.UP)

func _project_bounds(corners: Array[Vector3]) -> Rect2:
	var vp := _camera.get_viewport()
	var vs := vp.get_visible_rect().size if vp else Vector2(1280, 720)
	if vs.x < 1.0 or vs.y < 1.0:
		vs = Vector2(1280, 720)
	var r := Rect2()
	for i in range(corners.size()):
		var sp := _camera.unproject_position(to_global(corners[i]))
		var n := Vector2(sp.x / vs.x, sp.y / vs.y)
		if i == 0:
			r = Rect2(n, Vector2.ZERO)
		else:
			r = r.expand(n)
	return r

## Vetrina accanto alla tavola: piatti colorati con gli oggetti da contare.
func _build_display_shelf(display: Array, shelf_x: float, shelf_z: float) -> Dictionary:
	var step := 0.56
	var pad := 0.24
	var gap := 0.16
	var entries: Array = []
	for entry in display:
		if entry is Dictionary:
			entries.append(entry)
	if entries.is_empty():
		return {"left": shelf_x, "back": shelf_z}

	var metrics: Array = []
	for entry in entries:
		var count := maxi(0, int(entry.get("count", 1)))
		var cols := clampi(maxi(count, 1), 1, 5)
		var rows := maxi(1, int(ceil(float(maxi(count, 1)) / 5.0)))
		var label := str(entry.get("label", ""))
		var pd := float(rows) * step + pad * 2.0 + (0.18 if label != "" else 0.0)
		metrics.append({
			"w": float(cols) * step + pad * 2.0,
			"d": pd, "cols": cols, "rows": rows, "count": count, "label": label,
		})

	var ncols := 2 if entries.size() > 1 else 1
	var nrows := int(ceil(float(entries.size()) / float(ncols)))
	var col_w: Array[float] = []
	var row_d: Array[float] = []
	col_w.resize(ncols)
	row_d.resize(nrows)
	col_w.fill(0.0)
	row_d.fill(0.0)
	for i in range(metrics.size()):
		var c := i % ncols
		var r := i / ncols
		col_w[c] = maxf(col_w[c], float(metrics[i]["w"]))
		row_d[r] = maxf(row_d[r], float(metrics[i]["d"]))
	var content_w := 0.0
	for w in col_w:
		content_w += w
	content_w += gap * float(maxi(0, ncols - 1))
	var content_d := 0.0
	for d in row_d:
		content_d += d
	content_d += gap * float(maxi(0, nrows - 1))
	var shelf_w := maxf(2.45, content_w + 0.5)
	var shelf_d := content_d + 0.5
	var center_x := shelf_x - shelf_w * 0.5

	# Tavolino laterale, un po' più alto della tavola dei cubi.
	MeshHelpers.cylinder(_board_root, 0.8, 0.95, 0.5, Color("#D8C3A5"),
		Vector3(center_x, 0.35, shelf_z), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 24)
	MeshHelpers.box(_board_root, Vector3(shelf_w + 0.30, 0.26, shelf_d + 0.30),
		Color("#B98A55"), Vector3(center_x, 0.60, shelf_z))
	MeshHelpers.box(_board_root, Vector3(shelf_w, 0.09, shelf_d), Color("#EBD9B8"),
		Vector3(center_x, 0.775, shelf_z))
	MeshHelpers.box(_board_root, Vector3(shelf_w, 0.07, 0.09), Color("#E8B84A"),
		Vector3(center_x, 0.835, shelf_z + shelf_d * 0.5 + 0.02))

	var cursor_x := center_x - content_w * 0.5
	for r in range(nrows):
		var cursor_z := shelf_z - content_d * 0.5
		for rr in range(r):
			cursor_z += row_d[rr] + gap
		var x := cursor_x
		for c in range(ncols):
			var idx := r * ncols + c
			if idx >= metrics.size():
				break
			var m: Dictionary = metrics[idx]
			var entry: Dictionary = entries[idx]
			var px := x + col_w[c] * 0.5
			var pz := cursor_z + row_d[r] * 0.5
			var color: Color = MissionData.COLORS.get(str(entry.get("color", "oro")), Color("#E8B84A"))
			MeshHelpers.box(_board_root, Vector3(float(m["w"]), 0.06, float(m["d"])),
				color.darkened(0.12), Vector3(px, 0.845, pz))
			MeshHelpers.box(_board_root, Vector3(float(m["w"]) - 0.12, 0.045, float(m["d"]) - 0.12),
				color.lightened(0.58), Vector3(px, 0.875, pz))
			MeshHelpers.box(_board_root, Vector3(float(m["w"]) - 0.16, 0.03, 0.07), color,
				Vector3(px, 0.905, pz - float(m["d"]) * 0.5 + 0.10))

			var count := int(m["count"])
			var cols := int(m["cols"])
			var rows := int(m["rows"])
			var label := str(m["label"])
			var x0 := px - float(cols - 1) * step * 0.5
			var z0 := pz - float(rows - 1) * step * 0.5 - (0.10 if label != "" else 0.0)
			for k in range(count):
				var cc := k % 5
				var rr2 := k / 5
				_flat_icon(Vector3(x0 + float(cc) * step, 0.915, z0 + float(rr2) * step),
					str(entry.get("icon", "pallino")), color, 0.42)
			if label != "":
				MeshHelpers.label(_board_root, label, 64, Color("#3B2A20"),
					Vector3(px, 1.18, pz + float(m["d"]) * 0.5 + 0.02), 70)
			x += col_w[c] + gap

	return {"left": center_x - shelf_w * 0.5 - 0.2, "back": shelf_z - shelf_d * 0.5 - 0.15}

## Mappa del percorso accanto alla tavola: griglia, partenza, meta e ostacoli.
func _build_route_board(route: Dictionary, shelf_x: float, shelf_z: float) -> Dictionary:
	var n := clampi(int(route.get("size", 3)), 2, 4)
	var cell := 1.02 if n == 2 else (0.96 if n == 3 else 0.86)
	var pad := 0.24
	var grid_w := float(n) * cell + pad * 2.0
	var shelf_w := grid_w + 0.5
	var shelf_d := grid_w + 0.5
	var center_x := shelf_x - shelf_w * 0.5

	MeshHelpers.cylinder(_board_root, 0.8, 0.95, 0.5, Color("#D8C3A5"),
		Vector3(center_x, 0.35, shelf_z), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 24)
	MeshHelpers.box(_board_root, Vector3(shelf_w + 0.30, 0.26, shelf_d + 0.30),
		Color("#B98A55"), Vector3(center_x, 0.60, shelf_z))
	MeshHelpers.box(_board_root, Vector3(shelf_w, 0.09, shelf_d), Color("#EBD9B8"),
		Vector3(center_x, 0.775, shelf_z))
	MeshHelpers.box(_board_root, Vector3(shelf_w, 0.07, 0.09), Color("#E8B84A"),
		Vector3(center_x, 0.835, shelf_z + shelf_d * 0.5 + 0.02))

	MeshHelpers.box(_board_root, Vector3(grid_w, 0.07, grid_w), Color("#8C6B4A"),
		Vector3(center_x, 0.83, shelf_z))
	MeshHelpers.box(_board_root, Vector3(grid_w - 0.12, 0.05, grid_w - 0.12), Color("#C9B18F"),
		Vector3(center_x, 0.865, shelf_z))

	var start := _route_cell(route.get("start", [0, n - 1]), n)
	var goal := _route_cell(route.get("goal", [n - 1, 0]), n)
	var blocked := {}
	for b in route.get("blocked", []):
		if b is Array and b.size() >= 2:
			blocked[Vector2i(int(b[0]), int(b[1]))] = true

	for y in range(n):
		for x in range(n):
			var cell_pos := Vector3(
				center_x + (float(x) - float(n - 1) * 0.5) * cell,
				0.90,
				shelf_z + (float(y) - float(n - 1) * 0.5) * cell)
			var key := Vector2i(x, y)
			var color := Color("#FFF1D8")
			if blocked.has(key):
				color = Color("#4C4A52")
			elif key == start:
				color = Color("#5DBB72")
			elif key == goal:
				color = Color("#E8B84A")
			MeshHelpers.box(_board_root, Vector3(cell - 0.10, 0.05, cell - 0.10), color, cell_pos)
			if blocked.has(key):
				MeshHelpers.box(_board_root, Vector3(cell - 0.24, 0.24, cell - 0.24),
					Color("#6E6257"), cell_pos + Vector3(0, 0.13, 0))
				MeshHelpers.box(_board_root, Vector3(cell - 0.30, 0.06, 0.10), Color("#D95C5C"),
					cell_pos + Vector3(0, 0.285, 0), Vector3(0, PI * 0.25, 0))
				MeshHelpers.box(_board_root, Vector3(cell - 0.30, 0.06, 0.10), Color("#D95C5C"),
					cell_pos + Vector3(0, 0.285, 0), Vector3(0, -PI * 0.25, 0))
			elif key == start:
				MeshHelpers.cylinder(_board_root, 0.31, 0.31, 0.035, Color("#FFF7E8"),
					cell_pos + Vector3(0, 0.045, 0), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 20)
				MeshHelpers.icon(_board_root, "foot", Color("#1E5C2C"), 0.46,
					cell_pos + Vector3(0, 0.18, 0))
			elif key == goal:
				MeshHelpers.cylinder(_board_root, 0.31, 0.31, 0.035, Color("#FFF7E8"),
					cell_pos + Vector3(0, 0.045, 0), Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 20)
				MeshHelpers.icon(_board_root, _route_goal_icon(), Color("#5A3A00"), 0.50,
					cell_pos + Vector3(0, 0.18, 0))

	# Cornice dorata della griglia.
	for side in [-1.0, 1.0]:
		MeshHelpers.box(_board_root, Vector3(grid_w, 0.025, 0.05), Color("#E8B84A"),
			Vector3(center_x, 0.895, shelf_z + side * grid_w * 0.5))
		MeshHelpers.box(_board_root, Vector3(0.05, 0.025, grid_w), Color("#E8B84A"),
			Vector3(center_x + side * grid_w * 0.5, 0.895, shelf_z))

	return {"left": center_x - shelf_w * 0.5 - 0.2, "back": shelf_z - shelf_d * 0.5 - 0.15}

func _route_cell(value: Variant, n: int) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(clampi(int(value[0]), 0, n - 1), clampi(int(value[1]), 0, n - 1))
	return Vector2i.ZERO

func _route_goal_icon() -> String:
	match str(mission.get("effect", "")):
		"mela":
			return "apple"
		"carro":
			return "train"
		"corridoio_luce":
			return "lantern_full"
		"bussola":
			return "bussola"
	return "star"

func _flat_icon(pos: Vector3, icon_name: String, color: Color, size: float) -> void:
	var spr := Sprite3D.new()
	spr.texture = IconLibrary.texture(icon_name, color)
	var tex_w := 128.0
	if spr.texture:
		tex_w = maxf(1.0, float(spr.texture.get_width()))
	spr.pixel_size = size / tex_w
	spr.position = pos
	spr.rotation = Vector3(-PI / 2, 0, 0)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_board_root.add_child(spr)

## Vignettatura morbida: chiude i bordi del campo visivo e fa emergere il tavolo.
func _add_vignette() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	grad.colors = PackedColorArray([
		Color(0.05, 0.11, 0.14, 0.0),
		Color(0.05, 0.11, 0.14, 0.02),
		Color(0.04, 0.09, 0.12, 0.34),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.46)
	tex.fill_to = Vector2(1.02, 0.5)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(rect)

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "InterfacciaMissione"
	add_child(_ui)
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.theme = UITheme.make_theme()
	_ui.add_child(_ui_root)
	var pal := UITheme.palette()
	_add_vignette()

	# pannello consegna
	var top := PanelContainer.new()
	UITheme.style_panel(top, "card")
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.anchor_right = 0.63
	top.anchor_bottom = 0.0
	top.offset_left = 16
	top.offset_top = 14
	top.offset_right = -6
	top.offset_bottom = 220
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	top.add_child(v)
	var region := int(mission.get("region", 0))
	var region_txt := "Laboratorio" if lab_mode else "Regione %02d · %s" % [region, MissionData.REGION_NAMES[clampi(region - 1, 0, 9)]]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	var rune_icon := UIKit.icon_rect("stella_finale" if not lab_mode else "pannello", 28, pal["gold"])
	head.add_child(rune_icon)
	_title_label = UIKit.label(("Laboratorio · " if lab_mode else "") + str(mission.get("title", "")),
		24, pal["ink"], true)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(_title_label)
	var chip_text := "LIBERO" if lab_mode else str(mission.get("id", ""))
	var id_chip := UIKit.chip(chip_text, pal["panel2"], pal["ink_soft"])
	head.add_child(id_chip)
	v.add_child(UIKit.label(region_txt, 16, pal["accent2"], true))
	_instr_label = UIKit.body(str(mission.get("instruction", "")), 18, pal["ink"])
	_instr_label.custom_minimum_size = Vector2(0, 60)
	v.add_child(_instr_label)
	_focus_label = UIKit.label("", 16, pal["ink_soft"])
	_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_focus_label)

	# pannello aiuto / progresso
	var right := PanelContainer.new()
	UITheme.style_panel(right, "card")
	right.anchor_left = 0.61
	right.anchor_top = 0.0
	right.anchor_right = 1.0
	right.anchor_bottom = 0.0
	right.offset_left = 6
	right.offset_top = 14
	right.offset_right = -16
	right.offset_bottom = 220
	right.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	right.add_child(rv)
	_progress_label = UIKit.label("", 18, pal["accent2"], true)
	rv.add_child(_progress_label)
	_hint_label = UIKit.body("Premi X per un aiuto.", 16, pal["ink_soft"])
	_hint_label.custom_minimum_size = Vector2(0, 56)
	rv.add_child(_hint_label)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	rv.add_child(row1)
	for pair in [["X Aiuto", _hint], ["Y Ascolta", _listen]]:
		var b := UIKit.button(str(pair[0]), "", 38)
		b.add_theme_font_size_override("font_size", Settings.fs(17))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		row1.add_child(b)
	var bb := UIKit.button("B Indietro", "", 38)
	bb.add_theme_font_size_override("font_size", Settings.fs(17))
	bb.focus_mode = Control.FOCUS_NONE
	bb.pressed.connect(_cancel)
	rv.add_child(bb)

	# barra comandi
	var bottom := PanelContainer.new()
	UITheme.style_panel(bottom, "hud")
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -76
	bottom.offset_bottom = -16
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(bottom)
	var bl := UIKit.label(
		"Stick o WASD per muoverti   ·   A prendi o posa   ·   B rimetti o indietro   ·   X aiuto   ·   Y ascolta   ·   START pausa",
		17, pal["hud_ink"], true)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(bl)

	# sottotitoli
	_subtitle_panel = PanelContainer.new()
	UITheme.style_panel(_subtitle_panel, "hud")
	_subtitle_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.offset_left = -420
	_subtitle_panel.offset_right = 420
	_subtitle_panel.offset_top = -154
	_subtitle_panel.offset_bottom = -92
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.visible = false
	_ui_root.add_child(_subtitle_panel)
	_subtitle_label = UIKit.label("", 20, pal["hud_ink"], true)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_panel.add_child(_subtitle_label)

	_build_success_overlay()
	_build_exit_overlay()
	_build_cube_preview()
	_refresh_ui()
	_update_nearby(true)

func _build_success_overlay() -> void:
	var pal := UITheme.palette()
	_success_layer = Control.new()
	_success_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_success_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_success_layer.visible = false
	_ui_root.add_child(_success_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	_success_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_success_layer.add_child(center)
	var card := PanelContainer.new()
	UITheme.style_panel(card, "card")
	card.custom_minimum_size = Vector2(660, 420)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	var star := UIKit.icon_rect("stella_finale", 72, pal["gold"])
	star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(star)
	_success_title = UIKit.title("Pietra magica accesa!", 42)
	_success_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_success_title)
	_success_text = UIKit.body("", 22, pal["ink"])
	_success_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_text.custom_minimum_size = Vector2(0, 80)
	v.add_child(_success_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_success_next = UIKit.button("Prossima missione", "Primary")
	_success_next.name = "Prossima"
	_success_next.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		next_requested.emit(mission))
	row.add_child(_success_next)
	var again := UIKit.button("Rigioca", "")
	again.name = "Rigioca"
	again.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		_success_layer.visible = false
		_overlay_open = false
		_done = false
		set_process_unhandled_input(true)
		set_process(true)
		_build_board())
	row.add_child(again)
	var world := UIKit.button("Torna al mondo", "")
	world.name = "Mondo"
	world.pressed.connect(func() -> void:
		Audio.play_sfx("back")
		closed.emit())
	row.add_child(world)

func _build_exit_overlay() -> void:
	var pal := UITheme.palette()
	_exit_layer = Control.new()
	_exit_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_exit_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_exit_layer.visible = false
	_ui_root.add_child(_exit_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	_exit_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_exit_layer.add_child(center)
	var card := PanelContainer.new()
	UITheme.style_panel(card, "card")
	card.custom_minimum_size = Vector2(520, 260)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	var t := UIKit.title("Tornare al mondo?", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := UIKit.body("I cubi restano qui: potrai riprendere quando vuoi.", 20, pal["ink_soft"])
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var yes := UIKit.button("Sì, torna", "Primary")
	yes.pressed.connect(func() -> void:
		Audio.play_sfx("back")
		closed.emit())
	row.add_child(yes)
	var no := UIKit.button("Continua", "")
	no.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		_exit_layer.visible = false
		_overlay_open = false
		set_suspended(false))
	row.add_child(no)
	no.grab_focus()

# ---------------------------------------------------------------- anteprima cubo
## Un piccolo palcoscenico in basso a destra: il cubo scelto gira, illuminato
## da un raggio di luce, mentre il giocatore cerca l'incastro giusto.
func _build_cube_preview() -> void:
	var pal := UITheme.palette()
	_preview_panel = PanelContainer.new()
	_preview_panel.name = "AnteprimaCubo"
	UITheme.style_panel(_preview_panel, "card")
	_preview_panel.anchor_left = 1.0
	_preview_panel.anchor_top = 1.0
	_preview_panel.anchor_right = 1.0
	_preview_panel.anchor_bottom = 1.0
	_preview_panel.offset_left = -250
	_preview_panel.offset_right = -16
	_preview_panel.offset_top = -430
	_preview_panel.offset_bottom = -160
	_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_preview_panel.visible = false
	_ui_root.add_child(_preview_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_preview_panel.add_child(v)
	var head := UIKit.label("IN MANO", 14, pal["accent2"], true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	_preview_name = UIKit.label("", 18, pal["ink"], true)
	_preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_preview_name.custom_minimum_size = Vector2(0, 24)
	v.add_child(_preview_name)
	var frame := PanelContainer.new()
	UITheme.style_panel(frame, "hud")
	frame.custom_minimum_size = Vector2(218, 164)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(frame)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.stretch_shrink = 1
	svc.custom_minimum_size = Vector2(218, 164)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(svc)
	_preview_viewport = SubViewport.new()
	_preview_viewport.name = "PalcoscenicoCubo"
	_preview_viewport.size = Vector2i(480, 360)
	_preview_viewport.transparent_bg = true
	_preview_viewport.own_world_3d = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.msaa_3d = Viewport.MSAA_4X
	_preview_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	svc.add_child(_preview_viewport)
	_build_preview_world()
	_preview_hint = UIKit.label("Scegli dove posarlo", 13, pal["ink_soft"])
	_preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_preview_hint)

func _build_preview_world() -> void:
	var world := Node3D.new()
	world.name = "MondoAnteprima"
	_preview_viewport.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFF4E0")
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.near = 0.05
	cam.far = 20.0
	cam.position = Vector3(0.0, 1.95, 3.3)
	world.add_child(cam)
	cam.look_at(Vector3(0, 0.48, 0), Vector3.UP)
	cam.current = true

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-52), deg_to_rad(-32), 0)
	key.light_color = Color("#FFF1D2")
	key.light_energy = 0.75
	world.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.2, 1.6, 2.0)
	fill.light_color = Color("#A9D8F0")
	fill.light_energy = 0.35
	fill.omni_range = 8.0
	world.add_child(fill)
	var spark := OmniLight3D.new()
	spark.position = Vector3(0.8, 1.3, -1.4)
	spark.light_color = Color("#FFE066")
	spark.light_energy = 0.6
	spark.omni_range = 5.0
	world.add_child(spark)

	# Il raggio di luce che piove sul cubo.
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 3.6, 0.9)
	spot.light_color = Color("#FFE9B0")
	spot.light_energy = 2.0
	spot.spot_range = 8.0
	spot.spot_angle = 30.0
	spot.spot_angle_attenuation = 1.1
	spot.spot_attenuation = 0.8
	world.add_child(spot)
	spot.look_at(Vector3(0, 0.48, 0), Vector3.UP)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.16
	cone.bottom_radius = 1.12
	cone.height = 2.5
	cone.radial_segments = 36
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = false
	var cone_mi := MeshInstance3D.new()
	cone_mi.mesh = cone
	cone_mi.position = Vector3(0.0, 1.35, 0.45)
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(1.0, 0.9, 0.56, 0.08)
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cone_mat.emission_enabled = true
	cone_mat.emission = Color(1.0, 0.86, 0.5)
	cone_mat.emission_energy_multiplier = 1.3
	cone_mi.material_override = cone_mat
	cone_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(cone_mi)

	# Raggi dorati disposti a stella dietro il cubo.
	_preview_rays = Node3D.new()
	_preview_rays.name = "Raggi"
	_preview_rays.position = Vector3(0, 0.48, -0.80)
	world.add_child(_preview_rays)
	for i in range(20):
		var a := TAU * float(i) / 20.0
		var ray := MeshHelpers.box(_preview_rays, Vector3(0.04, 0.66, 0.02),
			Color("#FFE066"), Vector3(cos(a) * 1.14, sin(a) * 1.14, 0.0),
			Vector3(0, 0, a), Color("#FFE066"), 2.8)
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Piedistallo scuro e anello di luce: il cubo poggia su un piccolo palco.
	MeshHelpers.cylinder(world, 0.40, 0.44, 0.08, Color("#2E2A3A"), Vector3(0, 0.02, 0.0),
		Vector3.ZERO, Color(0, 0, 0, 0), 0.0, 24)
	var halo := MeshHelpers.torus(world, 0.54, 0.60, Color("#FFF3B0"),
		Vector3(0, 0.07, 0), Vector3.ZERO, Color("#FFE066"), 2.2)
	halo.name = "Alone"
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_preview_spin = Node3D.new()
	_preview_spin.name = "CuboCheGira"
	_preview_spin.position = Vector3(0, 0.52, 0)
	world.add_child(_preview_spin)

func _show_cube_preview(c: MissionCube3D) -> void:
	if _preview_panel == null or c == null:
		return
	if _preview_cube != null and is_instance_valid(_preview_cube):
		_preview_cube.queue_free()
	_preview_cube = MissionCube3D.new()
	_preview_cube.build(c.data, Vector3.ZERO)
	_preview_cube.set_pickable(false)
	_preview_spin.add_child(_preview_cube)
	_preview_name.text = _cube_name(c)
	_preview_panel.visible = true

func _hide_cube_preview() -> void:
	if _preview_panel:
		_preview_panel.visible = false
	if _preview_cube != null and is_instance_valid(_preview_cube):
		_preview_cube.queue_free()
	_preview_cube = null

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if _done and not _overlay_open:
		return
	if _overlay_open:
		return
	if event.is_action_pressed("pause"):
		pause_requested.emit()
		return
	# Durante il gesto di prendere o posare non si accettano altri comandi.
	if _avatar_busy:
		return
	if event.is_action_pressed("interact"):
		_activate()
	elif event.is_action_pressed("cancel"):
		_cancel()
	elif event.is_action_pressed("repeat_help"):
		_hint()
	elif event.is_action_pressed("highlight"):
		_listen()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_click(event.position)
	elif event is InputEventMouseMotion and _held != null:
		_aim_held(event.position)

## Il cubo in mano segue il puntatore sul piano del tavolo, così finisce dove
## lo si sta portando invece di restare fermo in un punto fisso.
func _aim_held(screen_pos: Vector2) -> void:
	if _held == null:
		return
	if _held.get_parent() != _board_root:
		return
	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return
	var t := (1.33 - origin.y) / dir.y
	if t <= 0.0:
		return
	var local := _board_root.to_local(origin + dir * t)
	local.x = clampf(local.x, -_board_w * 0.5 + 0.35, _board_w * 0.5 - 0.35)
	local.z = clampf(local.z, -_board_depth * 0.5 - 0.6, _tray_z_max)
	local.y = _hold_y
	_held.position = local

func _mouse_click(screen_pos: Vector2) -> void:
	if _held != null:
		_aim_held(screen_pos)
	var origin := _camera.project_ray_origin(screen_pos)
	var normal := _camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + normal * 80.0, 4)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider = hit.get("collider")
	if collider == null or not collider.has_meta("kind"):
		return
	var kind := str(collider.get_meta("kind"))
	var id := str(collider.get_meta("id"))
	if kind == "cube":
		var cube: MissionCube3D = _cube_nodes.get(id, null)
		if cube:
			if cube == _held:
				return
			if cube.placed:
				_pick_from_socket(cube)
			else:
				_pick(cube)
	elif kind == "socket":
		var sock: MissionSocket3D = _socket_nodes.get(id, null)
		if sock:
			if _held:
				_place(sock)
			elif not _placements.get(sock.socket_id, []).is_empty():
				var ids: Array = _placements[sock.socket_id]
				var cube2: MissionCube3D = _cube_nodes.get(ids[ids.size() - 1], null)
				if cube2:
					_pick_from_socket(cube2)

func _refresh_focus_text() -> void:
	if _focus_label == null:
		return
	var text := ""
	if _near_node is MissionCube3D:
		var c := _near_node as MissionCube3D
		text = "%s · A per prenderlo" % _cube_name(c)
	elif _near_node is MissionSocket3D:
		var s := _near_node as MissionSocket3D
		text = "%s · A per posare la cassa" % _socket_name(s)
	elif _held != null:
		text = "Porta la cassa vicino a una pedana."
	else:
		text = "Muoviti con lo stick o WASD e avvicinati a una cassa."
	if _focus_label.text != text:
		_focus_label.text = text

func _cube_name(c: MissionCube3D) -> String:
	var sp := str(c.data.get("spoken", ""))
	if sp != "":
		return sp
	var l := str(c.data.get("label", ""))
	return l if l != "" else str(c.data.get("value", "cubo"))

func _socket_name(s: MissionSocket3D) -> String:
	var t := str(s.data.get("hint_label", ""))
	return t if t != "" else str(s.data.get("id", "incastro"))

func _activate() -> void:
	_update_nearby(true)
	if _held != null:
		if _near_node is MissionSocket3D:
			_release_held(_near_node as MissionSocket3D)
		else:
			Audio.play_sfx("back")
		return
	if _near_node is MissionCube3D:
		_grab_cube(_near_node as MissionCube3D)
	else:
		Audio.play_sfx("back")

## Gesto completo: il personaggio cammina fino al cubo, lo prende con le mani
## e lo tiene davanti a sé. La versione immediata serve ai test e alle
## dimostrazioni, dove non si può aspettare l'animazione.
func _pick(c: MissionCube3D) -> void:
	if c == null or c.placed or c == _held:
		return
	if _avatar_busy:
		return
	# Una cassa alla volta: prima si posa (o si rimette al banco) quella in mano.
	if _held != null:
		Audio.play_sfx("back")
		return
	if _skip_avatar or _avatar == null:
		_pick_now(c)
		return
	_avatar_busy = true
	await _walk_avatar_to(_stand_point(_world_position(c), 0.66))
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_arms_reach(true)
	await get_tree().create_timer(0.18, true).timeout
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_pick_now(c)
	_attach_to_hands(c)
	await get_tree().create_timer(0.18, true).timeout
	_arms_reach(_held != null)
	_avatar_busy = false
	_update_nearby(true)

func _pick_now(c: MissionCube3D) -> void:
	if c == null or c.placed or c == _held:
		return
	# Se c'era già un cubo in mano torna al suo posto: niente cubi sovrapposti.
	_stow_held()
	_held = c
	_place_held_in_scene(c)
	_show_cube_preview(c)
	Audio.play_sfx("pickup", 1.05)
	Audio.say(_cube_name(c))

## Posizione del cubo in mano: davanti al tavolo, dove la camera lo vede bene.
func _place_held_in_scene(c: MissionCube3D) -> void:
	c.position = Vector3(0, _hold_y, _board_depth * 0.5 + 0.9)
	c.scale = c.shape_scale(1.12)
	c.set_pickable(false)

## Riporta al banco il cubo in mano, senza suoni: serve quando se ne prende un altro.
func _stow_held() -> void:
	if _held == null:
		return
	var old := _held
	_held = null
	_hide_cube_preview()
	_return_cube_home(old)
	_refresh_focus_text()
	_refresh_ui()

## Riporta un cubo al suo posto sul banco, staccandolo dalle mani o dall'incastro.
func _return_cube_home(c: MissionCube3D) -> void:
	if c == null:
		return
	_detach_cube(c)
	c.return_home()
	c.set_pickable(true)

func _pick_from_socket(c: MissionCube3D) -> void:
	if c == null or _held == c:
		return
	if _avatar_busy:
		return
	if _held != null:
		Audio.play_sfx("back")
		return
	if _skip_avatar or _avatar == null:
		_pick_from_socket_now(c)
		return
	_avatar_busy = true
	await _walk_avatar_to(_stand_point(_world_position(c), 0.70))
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_arms_reach(true)
	await get_tree().create_timer(0.16, true).timeout
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_pick_from_socket_now(c)
	_attach_to_hands(c)
	await get_tree().create_timer(0.16, true).timeout
	_arms_reach(_held != null)
	_avatar_busy = false
	_update_nearby(true)

func _pick_from_socket_now(c: MissionCube3D) -> void:
	if c == null or _held == c:
		return
	var sid := ""
	for key in _placements.keys():
		if _placements[key].has(c.cube_id):
			sid = str(key)
			break
	if sid == "":
		return
	_stow_held()
	_placements[sid].erase(c.cube_id)
	var sock: MissionSocket3D = _socket_nodes.get(sid, null)
	if sock:
		sock.set_filled_tint(not _placements[sid].is_empty())
		_layout_socket(sock)
	_held = c
	c.set_placed(false)
	_detach_cube(c)
	_place_held_in_scene(c)
	_show_cube_preview(c)
	Audio.play_sfx("pickup")
	Audio.say(_cube_name(c))

func _place(sock: MissionSocket3D) -> void:
	if _avatar_busy:
		return
	if _held == null or sock == null or sock.is_fixed:
		return
	# Validazione prima di mettersi in cammino: se il posto non va bene, il
	# personaggio non deve fare un viaggio a vuoto.
	var ids: Array = _placements.get(sock.socket_id, [])
	if ids.size() >= sock.capacity:
		Audio.play_sfx("back")
		Audio.say("Questo cesto è pieno. Prendi un altro posto.")
		return
	if not _accepts(sock, _held) and not lab_mode:
		Audio.play_sfx("back")
		Audio.say("Qui forse va un altro cubo. Proviamo insieme.")
		return
	if _skip_avatar or _avatar == null:
		_place_now(sock)
		return
	_avatar_busy = true
	await _walk_avatar_to(_stand_point(_world_position(sock), 0.80))
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_arms_reach(true)
	await get_tree().create_timer(0.16, true).timeout
	_place_now(sock)
	await get_tree().create_timer(0.14, true).timeout
	_arms_reach(_held != null)
	_avatar_busy = false
	_update_nearby(true)

func _place_now(sock: MissionSocket3D) -> void:
	if _held == null or sock == null or sock.is_fixed:
		return
	var ids: Array = _placements.get(sock.socket_id, [])
	if ids.size() >= sock.capacity:
		Audio.play_sfx("back")
		Audio.say("Questo cesto è pieno. Prendi un altro posto.")
		return
	if not _accepts(sock, _held) and not lab_mode:
		Audio.play_sfx("back")
		Audio.say("Qui forse va un altro cubo. Proviamo insieme.")
		return
	var cube := _held
	_held = null
	_hide_cube_preview()
	ids.append(cube.cube_id)
	_placements[sock.socket_id] = ids
	cube.set_placed(true, sock, -1 if sock.capacity == 1 else ids.size() - 1, ids.size())
	cube.set_pickable(true)
	_layout_socket(sock)
	sock.set_filled_tint(true)
	Audio.play_sfx("place", 1.0 + float(ids.size()) * 0.04)
	_refresh_ui()
	if not lab_mode:
		_check_complete()
	if _done:
		return
	_refresh_ui()

func _accepts(sock: MissionSocket3D, cube: MissionCube3D) -> bool:
	if lab_mode:
		return true
	if sock.is_fixed:
		return false
	if mission.has("route"):
		return true
	if sock.accepts.is_empty():
		return false
	return sock.accepts.has(str(cube.data.get("value", cube.cube_id)))

func _layout_socket(sock: MissionSocket3D) -> void:
	var ids: Array = _placements.get(sock.socket_id, [])
	for i in range(ids.size()):
		var c: MissionCube3D = _cube_nodes.get(ids[i], null)
		if c == null:
			continue
		c.set_placed(true, sock, -1 if sock.capacity == 1 else i, ids.size())
		c.set_focused(false)

func _cancel() -> void:
	if _avatar_busy:
		return
	if _held == null or _skip_avatar or _avatar == null:
		_cancel_now()
		return
	# Anche il ripensamento è un gesto: il personaggio torna al suo posto sul
	# banco e rimette la cassa dove l'aveva presa.
	_avatar_busy = true
	var home := _board_root.to_global(_held.home_position())
	await _walk_avatar_to(_stand_point(home, 0.62))
	if not is_inside_tree() or _avatar == null:
		_avatar_busy = false
		return
	_arms_reach(true)
	await get_tree().create_timer(0.14, true).timeout
	_cancel_now()
	await get_tree().create_timer(0.12, true).timeout
	_arms_reach(_held != null)
	_avatar_busy = false
	_update_nearby(true)

func _cancel_now() -> void:
	if _held:
		var c := _held
		_held = null
		_hide_cube_preview()
		_return_cube_home(c)
		Audio.play_sfx("back")
		_refresh_ui()
	else:
		_request_close()
	_update_nearby(true)

func _request_close() -> void:
	if lab_mode:
		closed.emit()
		return
	_hide_cube_preview()
	_overlay_open = true
	_exit_layer.visible = true
	set_suspended(true)
	var b := _exit_layer.find_children("*", "Button", true, false)
	if b.size() > 0:
		(b[b.size() - 1] as Button).grab_focus()

func _check_complete() -> void:
	var res := PuzzleEval.evaluate(mission, _placements)
	if not bool(res.get("complete", false)):
		_refresh_ui()
		return
	_done = true
	set_process_unhandled_input(false)
	Audio.play_sfx("success")
	Audio.say(str(mission.get("success", "Pietra magica accesa!")))
	completed.emit(mission)
	await get_tree().create_timer(0.55, true).timeout
	if not is_inside_tree():
		return
	_show_success()

## Modalità dimostrativa/test: posa i cubi usando gli stessi percorsi dell'input reale.
## Il personaggio resta fermo al suo posto: qui serve solo la soluzione, subito.
func debug_solve() -> bool:
	if _done:
		return true
	_skip_avatar = true
	_avatar_busy = false
	var solution := PuzzleEval.solve(mission)
	for sid in solution.keys():
		var value: Variant = solution[sid]
		var ids: Array = value if value is Array else [value]
		var sock: MissionSocket3D = _socket_nodes.get(str(sid), null)
		if sock == null:
			continue
		for cid in ids:
			var cube: MissionCube3D = _cube_nodes.get(str(cid), null)
			if cube == null or cube.placed:
				continue
			_pick_now(cube)
			_place_now(sock)
			if _held != null:
				_cancel_now()
				return false
	return PuzzleEval.evaluate(mission, _placements).get("complete", false)

func _show_success() -> void:
	_hide_cube_preview()
	_overlay_open = true
	_success_layer.visible = true
	# Festa per la pietra appena accesa: fanfara e coriandoli.
	Audio.play_sfx("fanfare")
	var old_confetti := _success_layer.get_node_or_null("Coriandoli")
	if old_confetti:
		old_confetti.queue_free()
	var confetti := Confetti.new()
	confetti.name = "Coriandoli"
	_success_layer.add_child(confetti)
	var last := int(str(mission.get("id", "100")))
	_success_next.visible = not lab_mode and last < 100
	var title := "Pietra magica accesa!"
	if last == 100:
		title = "La Stella è completa!"
	_success_title.text = title
	_success_text.text = str(mission.get("success", ""))
	if _success_next.visible:
		_success_next.grab_focus()
	else:
		var alt := _success_layer.find_child("Mondo", true, false) as Button
		if alt:
			alt.grab_focus()
	_refresh_ui()

# ---------------------------------------------------------------- aiuti
func _hint() -> void:
	if _done or _overlay_open:
		return
	if lab_mode:
		Audio.say("Qui puoi provare liberamente: nessuna soluzione, solo scoperte.")
		return
	var hints: Array = mission.get("hints", [])
	if hints.is_empty():
		return
	var idx := mini(_hints_used, hints.size() - 1)
	_hint_text = str(hints[idx])
	_hints_used += 1
	SaveGame.add_hint(str(mission.get("id", "")))
	Audio.play_sfx("click")
	Audio.say(_hint_text)
	if _hint_label:
		_hint_label.text = _hint_text
	_refresh_ui()
	if _hints_used >= 3:
		# trasformazione: mette in luce la prima coppia giusta ancora libera
		for s in _board_items:
			if _placements.get(s.socket_id, []).size() > 0:
				continue
			for c in _tray_items:
				if _accepts(s, c):
					s.set_focused(true)
					c.set_focused(true)
					Audio.say("Guarda questo cubo e questo incastro: stanno bene insieme.")
					return

func _listen() -> void:
	if _overlay_open:
		return
	var item: Node = _near_node if _near_node != null else _held
	if item is MissionCube3D:
		Audio.say(_cube_name(item as MissionCube3D))
	elif item is MissionSocket3D:
		Audio.say("%s. Incastro vuoto." % _socket_name(item as MissionSocket3D))
	else:
		Audio.say(str(mission.get("instruction", "")))

func _on_subtitle(text: String, seconds: float) -> void:
	if _subtitle_label == null:
		return
	_subtitle_label.text = text
	_subtitle_panel.visible = bool(Settings.get_setting("subtitles", true))
	_subtitle_timer = seconds
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta
	_update_free_move(delta)
	_update_nearby()
	_update_camera(delta)
	if _held and is_instance_valid(_held) and _held.get_parent() == _board_root:
		_held.rotation.y += delta * 1.4
	if _preview_panel and _preview_panel.visible:
		if _preview_spin and is_instance_valid(_preview_spin):
			_preview_spin.rotation.y += delta * 1.15
		if _preview_rays and is_instance_valid(_preview_rays):
			_preview_rays.rotation.z -= delta * 0.22
	if _subtitle_timer > 0.0:
		_subtitle_timer -= delta
		if _subtitle_timer <= 0.0:
			_subtitle_panel.visible = false

## Camera facilitata: dopo il primo passo segue dolcemente il personaggio,
## senza perdere d'inquadratura il tavolo e i suoi riferimenti.
func _update_camera(delta: float) -> void:
	if _camera == null or _camera_offset == Vector3.ZERO:
		return
	var focus := _camera_target
	var zoom := 1.0
	if _has_moved and _avatar != null and bool(Settings.get_setting("camera_assist", true)):
		var off := _avatar.position - _camera_target
		off.y = 0.0
		focus += Vector3(clampf(off.x * 0.55, -2.4, 2.4), 0.0,
			clampf(off.z * 0.55, -1.8, 1.8))
		# Un filo di campo in più: il tavolo resta leggibile mentre si segue.
		zoom = 1.12
	_cam_focus = _cam_focus.lerp(focus, clampf(delta * 3.5, 0.0, 1.0))
	_cam_zoom = lerpf(_cam_zoom, zoom, clampf(delta * 3.0, 0.0, 1.0))
	_camera.position = _cam_focus + _camera_offset * _cam_zoom
	_camera.look_at(to_global(_cam_focus), Vector3.UP)

func _refresh_ui() -> void:
	if _progress_label == null:
		return
	var filled := 0
	for key in _placements.keys():
		filled += (_placements[key] as Array).size()
	_progress_label.text = "Cubi posati: %d / %d" % [mini(filled, _required_cubes), _required_cubes]
	if _hint_text != "":
		_hint_label.text = _hint_text
	if _focus_label:
		_refresh_focus_text()
