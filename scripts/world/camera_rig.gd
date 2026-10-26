class_name CameraRig
extends Node3D
## Camera in terza persona, orbitale, con spring arm e zoom.

var target: Node3D
var yaw := 0.0
var pitch := -0.24
var distance := 5.7
var input_enabled := true
var cinematic := false
var cinematic_angle := 0.0
var _spring: SpringArm3D
var _camera: Camera3D
var _shake := 0.0
var _shake_time := 0.0
var _dragging := false

func _ready() -> void:
	_spring = SpringArm3D.new()
	_spring.name = "SpringArm"
	_spring.spring_length = distance
	_spring.margin = 0.25
	_spring.collision_mask = 1
	add_child(_spring)
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 62.0
	_camera.near = 0.08
	_camera.far = 500.0
	_spring.add_child(_camera)
	_camera.current = true

func get_camera() -> Camera3D:
	return _camera

func set_target(t: Node3D) -> void:
	target = t
	distance = 5.7

func set_distance(value: float) -> void:
	distance = clampf(value, 2.8, 10.0)
	if _spring:
		_spring.spring_length = distance

func add_shake(amount: float = 0.2, seconds: float = 0.25) -> void:
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	_shake = maxf(_shake, amount)
	_shake_time = maxf(_shake_time, seconds)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or cinematic:
		_dragging = false
		return
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or _dragging):
		var sens := float(Settings.get_setting("camera_sensitivity", 1.0))
		yaw -= event.relative.x * 0.0032 * sens
		pitch -= event.relative.y * 0.0026 * sens
		pitch = clampf(pitch, -1.08, 0.22)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_distance(distance - 0.45)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_distance(distance + 0.45)

func _process(delta: float) -> void:
	if _spring == null:
		return
	if cinematic:
		cinematic_angle += delta * 0.075
		yaw = cinematic_angle
		pitch = -0.18
		if target:
			global_position = global_position.lerp(target.global_position + Vector3(0, 6.5, 0), delta * 1.2)
		rotation = Vector3(0, yaw, 0)
		_spring.rotation.x = pitch
		_spring.spring_length = 17.0
		return
	if target and is_instance_valid(target):
		var desired := target.global_position + Vector3(0, 1.15, 0)
		global_position = global_position.lerp(desired, clampf(delta * 9.0, 0.0, 1.0))
	if input_enabled:
		var v := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
		if v.length() > 0.08:
			var sens := float(Settings.get_setting("camera_sensitivity", 1.0))
			yaw -= v.x * delta * 2.2 * sens
			pitch -= v.y * delta * 1.5 * sens
			pitch = clampf(pitch, -1.08, 0.22)
		var zoom := Input.get_action_strength("zoom_in") - Input.get_action_strength("zoom_out")
		if absf(zoom) > 0.05:
			set_distance(distance - zoom * delta * 3.2)
	rotation = Vector3(0, yaw, 0)
	_spring.rotation.x = pitch
	if _shake > 0.0:
		_shake_time -= delta
		_camera.position = Vector3(
			randf_range(-_shake, _shake) * 0.08,
			randf_range(-_shake, _shake) * 0.08, 0)
		if _shake_time <= 0.0:
			_shake = 0.0
			_camera.position = Vector3.ZERO
	else:
		_camera.position = _camera.position.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))
