class_name CameraRig
extends Node3D
## Camera dell'esplorazione, in due visuali scelte dal giocatore:
##
## - TERZA PERSONA: camera orbitale dietro il personaggio. Lo stick destro (o il
##   mouse trascinato) la ruota; con la CAMERA FACILITATA si riposiziona da sola
##   dietro l'avatar mentre cammina, così si gioca con il solo stick sinistro.
## - SOGGETTIVA: camera negli occhi del personaggio, che viene nascosto. Lo
##   stick destro guarda intorno.
##
## La collisione è calcolata con un raggio fisico: la camera non entra mai nei
## muri e non si incastra dentro il personaggio. Niente SpringArm: il vecchio
## braccio elastico, su Windows, si accorciava fino a finire nella testa
## dell'avatar e la camera sembrava bloccarsi in prima persona.

const THIRD_DISTANCE := 5.7
const THIRD_FOV := 62.0
const FIRST_FOV := 74.0
const EYE_HEIGHT := 1.46
const PIVOT_HEIGHT := 1.15
const MIN_DISTANCE := 1.30
const PITCH_MIN := -1.05
const PITCH_MAX := 0.26
const FIRST_PITCH_MIN := -1.15
const FIRST_PITCH_MAX := 1.15
const MOUSE_YAW := 0.0032
const MOUSE_PITCH := 0.0026
const STICK_YAW := 2.2
const STICK_PITCH := 1.5
## Grado di riallineamento automatico della camera facilitata.
const ASSIST_DEADZONE := 0.16
const ASSIST_SPEED := 1.7
## Secondi di pausa dell'assistenza dopo un comando manuale di camera.
const ASSIST_PAUSE := 1.6

var target: Node3D
var yaw := 0.0
var pitch := -0.24
var distance := THIRD_DISTANCE
var input_enabled := true
var first_person := false

var cinematic := false:
	set(value):
		cinematic = value
		_apply_view()

var cinematic_angle := 0.0

var _camera: Camera3D
var _camera_distance := THIRD_DISTANCE
var _shake := 0.0
var _shake_time := 0.0
var _dragging := false
var _assist_pause := 0.0

func _ready() -> void:
	distance = THIRD_DISTANCE
	_camera_distance = THIRD_DISTANCE
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = THIRD_FOV
	_camera.near = 0.06
	_camera.far = 500.0
	add_child(_camera)
	_camera.current = true
	_apply_view()
	if not Settings.setting_changed.is_connected(_on_setting_changed):
		Settings.setting_changed.connect(_on_setting_changed)

func get_camera() -> Camera3D:
	return _camera

func set_target(t: Node3D) -> void:
	target = t
	distance = THIRD_DISTANCE
	_camera_distance = THIRD_DISTANCE
	_apply_view()

func set_distance(value: float) -> void:
	distance = clampf(value, 2.8, 10.0)
	if first_person:
		_camera_distance = 0.0

func add_shake(amount: float = 0.2, seconds: float = 0.25) -> void:
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	_shake = maxf(_shake, amount)
	_shake_time = maxf(_shake_time, seconds)

func _on_setting_changed(key: String) -> void:
	if key == "camera_view" or key == "all":
		_apply_view()

## Legge la visuale scelta e nasconde o mostra il personaggio.
func _apply_view() -> void:
	var want_first := false
	if not cinematic:
		want_first = str(Settings.get_setting("camera_view", "third")) == "first"
	first_person = want_first
	if _camera:
		_camera.fov = FIRST_FOV if first_person else THIRD_FOV
		_camera.near = 0.03 if first_person else 0.06
	# Nel menu cinematografico il personaggio resta sempre visibile.
	_show_avatar(not want_first, cinematic)
	if first_person:
		pitch = clampf(pitch, FIRST_PITCH_MIN, FIRST_PITCH_MAX)
	else:
		pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)
		_camera_distance = distance

func _show_avatar(visible_avatar: bool, cinematic_view: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("set_camera_view"):
		target.set_camera_view(visible_avatar, cinematic_view)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or cinematic:
		_dragging = false
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_YAW
		pitch -= event.relative.y * MOUSE_PITCH
		_pause_assist()
		_clamp_pitch()
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * MOUSE_YAW
		pitch -= event.relative.y * MOUSE_PITCH
		_pause_assist()
		_clamp_pitch()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		if event.pressed and not first_person:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_distance(distance - 0.45)
				_pause_assist()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_distance(distance + 0.45)
				_pause_assist()

func _clamp_pitch() -> void:
	if first_person:
		pitch = clampf(pitch, FIRST_PITCH_MIN, FIRST_PITCH_MAX)
	else:
		pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)

func _pause_assist() -> void:
	_assist_pause = ASSIST_PAUSE

func _process(delta: float) -> void:
	if _camera == null:
		return
	if cinematic:
		_animate_cinematic(delta)
		return
	if target == null or not is_instance_valid(target):
		return
	if first_person:
		_process_first_person(delta)
	else:
		_process_third_person(delta)
	_apply_shake(delta)

## Vista dall'alto che ruota lentamente: usata dal menu e dai viaggi.
func _animate_cinematic(delta: float) -> void:
	cinematic_angle += delta * 0.075
	yaw = cinematic_angle
	pitch = -0.18
	if target:
		global_position = global_position.lerp(target.global_position + Vector3(0, 6.5, 0), delta * 1.2)
	rotation = Vector3(0, yaw, 0)
	_camera_distance = 17.0
	_camera.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, _camera_distance))
	_camera.fov = THIRD_FOV

func _process_first_person(delta: float) -> void:
	_read_rotation_input(delta)
	global_position = target.global_position + Vector3(0, EYE_HEIGHT, 0)
	rotation = Vector3(pitch, yaw, 0)
	_camera.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.02))
	_camera.fov = FIRST_FOV

func _process_third_person(delta: float) -> void:
	_read_rotation_input(delta)
	_apply_assisted_camera(delta)
	var pivot := target.global_position + Vector3(0, PIVOT_HEIGHT, 0)
	global_position = global_position.lerp(pivot, clampf(delta * 9.0, 0.0, 1.0))
	rotation = Vector3(pitch, yaw, 0)
	var wanted := _clear_distance(pivot)
	# Se qualcosa si avvicina, la camera si ritrae subito; quando lo spazio
	# torna libero si riallontana con calma, senza scatti.
	if wanted < _camera_distance:
		_camera_distance = lerpf(_camera_distance, wanted, clampf(delta * 18.0, 0.0, 1.0))
	else:
		_camera_distance = lerpf(_camera_distance, wanted, clampf(delta * 4.0, 0.0, 1.0))
	if _camera_distance < MIN_DISTANCE:
		_camera_distance = MIN_DISTANCE
	_camera.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, _camera_distance))
	_camera.fov = THIRD_FOV

func _read_rotation_input(delta: float) -> void:
	if not input_enabled:
		return
	var v := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if v.length() > 0.08:
		yaw -= v.x * delta * STICK_YAW
		pitch -= v.y * delta * STICK_PITCH
		_pause_assist()
		_clamp_pitch()
	if not first_person:
		var zoom := Input.get_action_strength("zoom_in") - Input.get_action_strength("zoom_out")
		if absf(zoom) > 0.05:
			set_distance(distance - zoom * delta * 3.2)
			_pause_assist()

## Camera facilitata: mentre il personaggio cammina, la camera si sposta da sola
## dietro la sua direzione. Con lo stick destro si prende il comando e
## l'assistenza tace per un momento.
func _apply_assisted_camera(delta: float) -> void:
	if _assist_pause > 0.0:
		_assist_pause = maxf(0.0, _assist_pause - delta)
		return
	if not input_enabled:
		return
	if not bool(Settings.get_setting("camera_assist", true)):
		return
	if target == null or not is_instance_valid(target):
		return
	if not bool(target.get("moving")):
		return
	var want := target.rotation.y
	var diff := wrapf(want - yaw, -PI, PI)
	if absf(diff) <= ASSIST_DEADZONE:
		return
	yaw += clampf(diff, -ASSIST_SPEED * delta, ASSIST_SPEED * delta)
	yaw = wrapf(yaw, -PI, PI)

## Distanza libera tra il punto di ripresa e la camera, misurata con un raggio
## contro il mondo: nessun muro tra i due.
func _clear_distance(pivot: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return distance
	var back := global_transform.basis.z.normalized()
	var from := pivot + Vector3(0, 0.12, 0)
	var to := pivot + back * distance
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	if target is CollisionObject3D:
		var exclude: Array[RID] = []
		exclude.append((target as CollisionObject3D).get_rid())
		query.exclude = exclude
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return distance
	var point: Vector3 = hit["position"]
	var free := from.distance_to(point) - 0.30
	return clampf(free, MIN_DISTANCE, distance)

func _apply_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake_time -= delta
		_camera.position += Vector3(
			randf_range(-_shake, _shake) * 0.08,
			randf_range(-_shake, _shake) * 0.08, 0)
		if _shake_time <= 0.0:
			_shake = 0.0
			_camera.position = Vector3(0, 0, _camera_distance)
