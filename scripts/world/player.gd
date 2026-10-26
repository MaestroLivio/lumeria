class_name LumeriaPlayer
extends CharacterBody3D
## Avatar giocabile: camminata dolce, nessun combattimento, nessuna caduta.

const WALK_SPEED := 4.6
const BOUNDS := 86.0

var rig: CameraRig
var visual: Node3D
var input_enabled := true
var moving := false
var _bob := 0.0
var _step := 0.0
var _gravity := 18.0
var _last_safe := Vector3.ZERO

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.55
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)
	_build_contact_shadow()
	refresh_appearance()
	set_physics_process(true)

func _build_contact_shadow() -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.15, 1.15)
	quad.mesh = mesh
	quad.rotation.x = -PI / 2.0
	quad.position.y = 0.03
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/blob_shadow.gdshader")
	quad.material_override = mat
	add_child(quad)

func refresh_appearance() -> void:
	if visual and is_instance_valid(visual):
		visual.queue_free()
	visual = AvatarBuilder.build(SaveGame.appearance())
	add_child(visual)

func set_rig(r: CameraRig) -> void:
	rig = r

func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	if rig:
		rig.global_position = pos + Vector3(0, 1.15, 0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return
	var ix := Input.get_axis("move_left", "move_right")
	var iz := Input.get_axis("move_forward", "move_back")
	if bool(Settings.get_setting("dpad_only", false)):
		ix = Input.get_axis("move_left_pad", "move_right_pad")
		iz = Input.get_axis("move_up_pad", "move_down_pad")
	var dir := Vector3.ZERO
	if absf(ix) > 0.08 or absf(iz) > 0.08:
		var yaw := rig.yaw if rig else 0.0
		var forward := Vector3(-sin(yaw), 0, -cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		# Input.get_axis restituisce -1 per "move_forward": forward * -iz.
		dir = (right * ix + forward * -iz).normalized()
	var speed := float(Settings.get_setting("avatar_speed", WALK_SPEED))
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, 18.0 * delta)
	velocity.z = move_toward(velocity.z, target.z, 18.0 * delta)
	moving = dir.length() > 0.05
	if moving:
		var want := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(delta * 10.0, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, -BOUNDS, BOUNDS)
	global_position.z = clampf(global_position.z, -BOUNDS, BOUNDS)
	if global_position.y < -4.0:
		global_position = _last_safe if _last_safe != Vector3.ZERO else Vector3(0, 2, 10)
	if is_on_floor():
		_last_safe = global_position
	_animate(delta, speed)

func _animate(delta: float, speed: float) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	var motion := not bool(Settings.get_setting("reduce_motion", false))
	if moving and motion:
		_bob += delta * speed * 1.75
		visual.position.y = absf(sin(_bob)) * 0.045
		visual.rotation.z = sin(_bob) * 0.022
		var arms := visual.get_node_or_null("Braccia")
		if arms:
			arms.rotation.x = sin(_bob) * 0.38
		var legs := visual.get_node_or_null("Gambe")
		if legs:
			legs.rotation.x = sin(_bob) * 0.22
		_step -= delta * speed
		if _step <= 0.0:
			_step = 0.72
			Audio.play_sfx("tick", randf_range(0.72, 0.9))
	else:
		_bob = 0.0
		visual.position.y = lerpf(visual.position.y, sin(Time.get_ticks_msec() / 900.0) * 0.012, delta * 4.0)
		visual.rotation.z = lerpf(visual.rotation.z, 0.0, delta * 6.0)
		var arms_idle := visual.get_node_or_null("Braccia")
		if arms_idle:
			arms_idle.rotation.x = lerpf(arms_idle.rotation.x, 0.0, delta * 6.0)
		var legs_idle := visual.get_node_or_null("Gambe")
		if legs_idle:
			legs_idle.rotation.x = lerpf(legs_idle.rotation.x, 0.0, delta * 6.0)

func celebrate() -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	var tw := create_tween()
	tw.tween_property(visual, "position:y", 0.42, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(visual, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_BOUNCE)
	Audio.play_sfx("success")
