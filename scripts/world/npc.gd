class_name WorldNpc
extends CharacterBody3D
## Personaggio simpatico che vaga nel mondo e saluta quando il giocatore si avvicina.
## Ogni custode (e ogni amico animale) ha la sua voce, scelta con Audio.say_as:
## il mondo sembra abitato da amici veri, ognuno con il proprio timbro.

const WALK_SPEED := 1.35
const GRAVITY := 18.0

var npc_name := ""
var voice_role := "narrator"
var greeting := ""
var kind := "kid"

var _home := Vector3.ZERO
var _wander_radius := 5.0
var _target := Vector3.ZERO
var _wait_time := 0.0
var _visual: Node3D
var _bob := 0.0
var _walking := false
var _greeted := false
var _greet_cooldown := 0.0
var _phase := 0.0
var _player: Node3D = null
# nodi opzionali animati per gli animali
var _wing_l: Node3D
var _wing_r: Node3D
var _tail: Node3D
var _head: Node3D

func setup(cfg: Dictionary) -> void:
	npc_name = str(cfg.get("name", ""))
	voice_role = str(cfg.get("voice", "narrator"))
	greeting = str(cfg.get("greeting", ""))
	kind = str(cfg.get("kind", "kid"))
	_home = global_position
	_wander_radius = clampf(float(cfg.get("radius", 5.0)), 2.0, 11.0)
	_phase = randf() * TAU
	_visual = _build_visual(cfg)
	add_child(_visual)
	# ombra di contatto morbida, come quella dell'avatar
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	quad.mesh = mesh
	quad.rotation.x = -PI / 2.0
	quad.position.y = 0.03
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/blob_shadow.gdshader")
	quad.material_override = mat
	add_child(quad)
	_pick_target()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	shape.shape = capsule
	shape.position = Vector3(0, 0.78, 0)
	add_child(shape)
	set_physics_process(true)

# ---------------------------------------------------------------- aspetto
func _build_visual(cfg: Dictionary) -> Node3D:
	if kind == "kid":
		return AvatarBuilder.build(cfg.get("appearance", {}))
	var col: Color = cfg.get("color", Color("#E8A65A"))
	var root := Node3D.new()
	root.name = "Animale"
	match kind:
		"coniglio":
			MeshHelpers.sphere(root, 0.21, col, Vector3(0, 0.30, 0))
			MeshHelpers.sphere(root, 0.15, col.lightened(0.06), Vector3(0, 0.52, -0.16))
			for side in [-1.0, 1.0]:
				_ears_placeholder(root, side, col)
				MeshHelpers.sphere(root, 0.022, Color("#3B2A20"), Vector3(0.05 * side, 0.54, -0.27))
			MeshHelpers.sphere(root, 0.028, Color("#E88BA5"), Vector3(0, 0.48, -0.29))
			MeshHelpers.sphere(root, 0.07, Color("#FFF3F0"), Vector3(0, 0.32, 0.17))
			_head = root
		"uccello":
			MeshHelpers.sphere(root, 0.16, col, Vector3(0, 0.34, 0))
			MeshHelpers.sphere(root, 0.11, col.lightened(0.08), Vector3(0, 0.47, -0.10))
			MeshHelpers.box(root, Vector3(0.05, 0.05, 0.10), Color("#F2A65A"), Vector3(0, 0.46, -0.22))
			for side in [-1.0, 1.0]:
				MeshHelpers.sphere(root, 0.022, Color("#3B2A20"), Vector3(0.05 * side, 0.49, -0.17))
				var wing := MeshHelpers.box(root, Vector3(0.16, 0.05, 0.26), col.darkened(0.12),
					Vector3(0.20 * side, 0.40, -0.04), Vector3(0, 0, deg_to_rad(-14.0 * side)))
				wing.name = "Ala"
				if side < 0.0:
					_wing_l = wing
				else:
					_wing_r = wing
			MeshHelpers.box(root, Vector3(0.06, 0.08, 0.05), col.darkened(0.18), Vector3(0, 0.36, 0.14))
			_head = root
		"gatto":
			MeshHelpers.sphere(root, 0.18, col, Vector3(0, 0.26, 0))
			MeshHelpers.sphere(root, 0.13, col, Vector3(0, 0.42, -0.12))
			for side in [-1.0, 1.0]:
				var ear := MeshHelpers.prism(root, Vector3(0.06, 0.10, 0.03), col.darkened(0.1),
					Vector3(0.07 * side, 0.52, -0.04))
				ear.rotation.z = deg_to_rad(10.0 * side)
				MeshHelpers.sphere(root, 0.02, Color("#3B2A20"), Vector3(0.045 * side, 0.43, -0.22))
			MeshHelpers.sphere(root, 0.02, Color("#E88BA5"), Vector3(0, 0.38, -0.24))
			_tail = MeshHelpers.cylinder(root, 0.03, 0.03, 0.42, col.darkened(0.08),
				Vector3(0, 0.34, 0.20), Vector3(deg_to_rad(-40), 0, 0))
			_head = root
		"volpe":
			MeshHelpers.sphere(root, 0.19, col, Vector3(0, 0.28, 0))
			MeshHelpers.sphere(root, 0.145, col.lightened(0.05), Vector3(0, 0.47, -0.14))
			MeshHelpers.sphere(root, 0.08, Color("#FFF4E4"), Vector3(0, 0.32, -0.20))
			MeshHelpers.sphere(root, 0.03, Color("#3B2A20"), Vector3(0, 0.45, -0.28))
			for side in [-1.0, 1.0]:
				var ear2 := MeshHelpers.prism(root, Vector3(0.07, 0.13, 0.035), col.darkened(0.12),
					Vector3(0.08 * side, 0.60, -0.08))
				ear2.rotation.z = deg_to_rad(14.0 * side)
				MeshHelpers.sphere(root, 0.022, Color("#3B2A20"), Vector3(0.05 * side, 0.50, -0.24))
			# coda folta: due sfere sfalsate
			_tail = MeshHelpers.sphere(root, 0.09, col.darkened(0.05),
				Vector3(0, 0.34, 0.30))
			MeshHelpers.sphere(root, 0.07, Color("#FFF4E4"), Vector3(0, 0.34, 0.43))
			_head = root
		"tartaruga":
			MeshHelpers.sphere(root, 0.17, Color("#E8D9A8"), Vector3(0, 0.22, 0))
			var shell := MeshHelpers.sphere(root, 0.25, col, Vector3(0, 0.36, 0.02))
			shell.scale = Vector3(1.15, 0.62, 1.0)
			for side in [-1.0, 1.0]:
				MeshHelpers.sphere(root, 0.055, Color("#D8C79A"), Vector3(0.20 * side, 0.12, -0.06))
				MeshHelpers.sphere(root, 0.055, Color("#D8C79A"), Vector3(0.20 * side, 0.12, 0.16))
				MeshHelpers.sphere(root, 0.022, Color("#3B2A20"), Vector3(0.045 * side, 0.36, -0.22))
			MeshHelpers.sphere(root, 0.10, col.lightened(0.18), Vector3(0, 0.30, -0.26))
			MeshHelpers.sphere(root, 0.026, Color("#3B2A20"), Vector3(0, 0.26, -0.35))
			_head = root
		"riccio":
			MeshHelpers.sphere(root, 0.21, col, Vector3(0, 0.26, 0))
			MeshHelpers.sphere(root, 0.14, col.lightened(0.16), Vector3(0, 0.30, -0.16))
			MeshHelpers.sphere(root, 0.03, Color("#3B2A20"), Vector3(0, 0.26, -0.29))
			for side in [-1.0, 1.0]:
				MeshHelpers.sphere(root, 0.022, Color("#3B2A20"), Vector3(0.05 * side, 0.34, -0.24))
			# aculei sul dorso
			for i in range(11):
				var a := -0.5 + float(i) * 0.31
				var sp := MeshHelpers.cylinder(root, 0.0, 0.035, 0.20, col.darkened(0.22),
					Vector3(sin(a) * 0.14, 0.42 + cos(a) * 0.10, 0.03 + 0.10 * cos(a)),
					Vector3(0, 0, -a * 0.7))
				sp.name = "Aculeo"
			_head = root
	return root

func _ears_placeholder(root: Node3D, side: float, col: Color) -> void:
	# orecchie lunghe da coniglio
	var ear := MeshHelpers.capsule(root, 0.045, 0.30, col.lightened(0.04),
		Vector3(0.055 * side, 0.70, -0.10), Vector3(0, 0, deg_to_rad(-12.0 * side)))
	ear.name = "Orecchio"

# ---------------------------------------------------------------- movimento
func _pick_target() -> void:
	var a := randf() * TAU
	var r := randf_range(0.6, _wander_radius)
	_target = _home + Vector3(cos(a) * r, 0, sin(a) * r)
	_wait_time = randf_range(1.2, 3.2)

func _player_node() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	var p := _player_node()
	var dir := Vector3.ZERO
	if p != null:
		var to_p := p.global_position - global_position
		to_p.y = 0.0
		var d := to_p.length()
		if d < 3.4:
			# Si ferma e guarda il giocatore.
			_wait_time = maxf(_wait_time, 0.3)
			var want := atan2(-to_p.x, -to_p.z)
			rotation.y = lerp_angle(rotation.y, want, clampf(delta * 6.0, 0.0, 1.0))
		else:
			_wait_time -= delta
			if _wait_time <= 0.0 or global_position.distance_to(_target) < 0.5:
				_pick_target()
			var to_t := _target - global_position
			to_t.y = 0.0
			if to_t.length() > 0.3:
				dir = to_t.normalized()
	if bool(Settings.get_setting("reduce_motion", false)):
		dir = Vector3.ZERO
	_walking = dir.length() > 0.1
	if _walking:
		var want := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(delta * 8.0, 0.0, 1.0))
	velocity.x = move_toward(velocity.x, dir.x * WALK_SPEED, 14.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * WALK_SPEED, 14.0 * delta)
	move_and_slide()
	if _walking and get_real_velocity().length() < 0.12:
		_pick_target()
	_animate(delta)

func _animate(delta: float) -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	var motion := not bool(Settings.get_setting("reduce_motion", false))
	if _walking and motion:
		_bob += delta * WALK_SPEED * 1.9
		var step := sin(_bob)
		if kind == "kid":
			_visual.position.y = absf(step) * 0.04
			_visual.rotation.z = step * 0.02
			var arms := _visual.get_node_or_null("Braccia")
			if arms:
				arms.rotation.x = step * 0.34
			var legs := _visual.get_node_or_null("Gambe")
			if legs:
				legs.rotation.x = step * 0.2
		elif kind == "coniglio":
			_visual.position.y = absf(step) * 0.10
			for child in _visual.get_children():
				if child.name == "Orecchio":
					child.rotation.z = lerpf(child.rotation.z, step * 0.25, delta * 6.0)
		elif kind == "uccello":
			_visual.position.y = absf(step) * 0.05
			if _wing_l:
				_wing_l.rotation.z = step * 0.7
			if _wing_r:
				_wing_r.rotation.z = step * 0.7
		else:
			_visual.position.y = absf(step) * 0.04
			if _tail:
				_tail.rotation.y = step * 0.5
	else:
		_bob = 0.0
		_visual.position.y = lerpf(_visual.position.y, sin(Time.get_ticks_msec() / 800.0) * 0.012, delta * 4.0)
		if kind == "kid":
			_visual.rotation.z = lerpf(_visual.rotation.z, 0.0, delta * 6.0)
		elif kind == "uccello" and motion:
			if _wing_l:
				_wing_l.rotation.z = sin(_phase * 5.0) * 0.12
			if _wing_r:
				_wing_r.rotation.z = sin(_phase * 5.0) * 0.12
		elif kind == "gatto" and _tail:
			_tail.rotation.y = sin(_phase * 1.6) * 0.4

func _process(delta: float) -> void:
	_phase += delta
	_greet_cooldown = maxf(0.0, _greet_cooldown - delta)
	var p := _player_node()
	if p == null:
		return
	var to_p := p.global_position - global_position
	to_p.y = 0.0
	var d := to_p.length()
	if d < 3.4 and not _greeted and _greet_cooldown <= 0.0:
		_greeted = true
		_greet_cooldown = 8.0
		if greeting != "":
			Audio.say_as(voice_role, greeting, true)
			_hop()
	elif d > 5.0:
		_greeted = false

func _hop() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	var tw := create_tween()
	tw.tween_property(_visual, "position:y", 0.28, 0.16).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_visual, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_BOUNCE)
	Audio.play_sfx("heart")
