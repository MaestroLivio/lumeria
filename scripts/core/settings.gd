extends Node
## Impostazioni globali di Lumeria.
## Tutto è pensato per essere modificabile con il solo gamepad.

signal setting_changed(key: String)
signal quality_changed(level: int)
signal accessibility_changed

const PATH := "user://lumeria_settings.json"

const DEFAULTS := {
	"audio_music": 62,
	"audio_sfx": 78,
	"audio_voice": 88,
	"music_muted": false,
	"subtitles": true,
	"text_size": 1.0,
	"high_contrast": false,
	"thick_outlines": true,
	"reduce_motion": false,
	"no_flash": true,
	"glow": 55,
	"quality": 1,
	"vsync": true,
	"window_mode": "windowed",
	"resolution": 0,
	"camera_sensitivity": 1.0,
	"invert_y": false,
	"camera_mode": "follow",
	"auto_recenter": true,
	"assisted_camera": true,
	"avatar_speed": 4.6,
	"deadzone": 0.25,
	"vibration": false,
	"hints_mode": "scopro",
	"guided_mode": false,
	"dpad_only": false,
	"controller_layout": "auto",
	"progression_guided": false,
	"classroom_mode": false,
	"tutorial_done": false,
	"check_updates": true,
}

var data: Dictionary = {}
var _loaded := false
var _applying := false
var _save_queued := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_inputs()
	_load()
	_apply_audio()
	_apply_glow()
	_apply_window(false)
	_apply_video()
	call_deferred("_apply_window_startup")

# ---------------------------------------------------------------- API

func get_setting(key: String, fallback: Variant = null) -> Variant:
	if data.has(key):
		return data[key]
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	return fallback

func set_setting(key: String, value: Variant, apply_now: bool = true) -> void:
	if not _loaded:
		return
	if data.get(key) == value:
		return
	data[key] = value
	if apply_now:
		_apply(key)
	_save_soon()
	setting_changed.emit(key)

func toggle(key: String) -> void:
	set_setting(key, not bool(get_setting(key)))

func fs(base: int) -> int:
	return maxi(11, int(round(float(base) * float(get_setting("text_size", 1.0)))))

func is_high_contrast() -> bool:
	return bool(get_setting("high_contrast", false))

## Intensità del bagliore come moltiplicatore (0 = spento, 1 = pieno).
## Il valore predefinito è volutamente sotto 1: le luci restano leggibili
## senza abbagliare, e chi vuole più effetto alza lo slider.
func glow_scale() -> float:
	return clampf(float(get_setting("glow", 55)) / 100.0, 0.0, 1.5)

## Un'intensità di luce o di emissione regolata dallo slider del bagliore.
func glow_energy(base: float) -> float:
	return base * glow_scale()

func reset() -> void:
	data = DEFAULTS.duplicate(true)
	_apply_audio()
	_apply_glow()
	_apply_window(false)
	_apply_video()
	_save_soon()
	accessibility_changed.emit()
	setting_changed.emit("all")

# ---------------------------------------------------------------- inner

func _apply(key: String) -> void:
	match key:
		"audio_music", "audio_sfx", "audio_voice", "music_muted":
			_apply_audio()
		"window_mode", "resolution", "vsync":
			_apply_window(true)
		"quality":
			_apply_video()
		"glow":
			_apply_glow()
			accessibility_changed.emit()
		"high_contrast", "text_size", "thick_outlines", "reduce_motion", "no_flash", "subtitles":
			if key == "high_contrast" or key == "text_size" or key == "thick_outlines":
				accessibility_changed.emit()
		"vibration":
			if not bool(data.get("vibration", false)):
				Input.stop_joy_vibration(0)
		"camera_mode", "auto_recenter", "dpad_only", "avatar_speed", "deadzone":
			pass

func _apply_audio() -> void:
	var a := get_node_or_null("/root/Audio")
	if a and a.has_method("apply_settings"):
		a.apply_settings()

func _apply_glow() -> void:
	MeshHelpers.set_glow_scale(glow_scale())

func _apply_window(user_action: bool) -> void:
	var win := get_window()
	if win == null:
		return
	var mode := str(get_setting("window_mode", "windowed"))
	win.unresizable = false
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_size(screen)
			DisplayServer.window_set_position(Vector2i(0, 0))
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			if user_action:
				var sizes := resolution_sizes()
				var idx: int = clampi(int(get_setting("resolution", 0)), 0, sizes.size() - 1)
				DisplayServer.window_set_size(_window_px(sizes[idx]))
				win.move_to_center()
	# vsync
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if bool(get_setting("vsync", true)) else DisplayServer.VSYNC_DISABLED
		)

func _apply_window_startup() -> void:
	# Requisito esplicito: il gioco parte SEMPRE in finestra ridimensionabile.
	var win := get_window()
	if win == null:
		return
	win.unresizable = false
	var screen := DisplayServer.screen_get_scale()
	var target := _window_px(Vector2i(1280, 720))
	win.min_size = Vector2i(
		mini(roundi(960.0 * screen), target.x),
		mini(roundi(540.0 * screen), target.y))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(target)
	win.move_to_center()
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(get_setting("vsync", true)) else DisplayServer.VSYNC_DISABLED
	)

## Converte una dimensione logica (punti) in pixel fisici e la limita allo schermo.
## Su macOS Retina una finestra da 1280×720 punti resta leggibile e grande il giusto.
func _window_px(points: Vector2i) -> Vector2i:
	var s := float(DisplayServer.screen_get_scale())
	var scr := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var px := Vector2i(roundi(float(points.x) * s), roundi(float(points.y) * s))
	px.x = mini(px.x, maxi(720, usable.size.x - 32))
	px.y = mini(px.y, maxi(480, usable.size.y - 32))
	return px

func _apply_video() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var q := int(get_setting("quality", 1))
	match q:
		0:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.72
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			Engine.max_fps = 30
		1:
			vp.msaa_3d = Viewport.MSAA_2X
			vp.scaling_3d_scale = 1.0
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			Engine.max_fps = 60
		_:
			vp.msaa_3d = Viewport.MSAA_4X
			vp.scaling_3d_scale = 1.0
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			Engine.max_fps = 0
	quality_changed.emit(q)

func resolution_sizes() -> Array[Vector2i]:
	return [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(1024, 576)]

func resolution_label() -> String:
	var sizes := resolution_sizes()
	var idx: int = clampi(int(get_setting("resolution", 0)), 0, sizes.size() - 1)
	var s: Vector2i = sizes[idx]
	return "%d × %d" % [s.x, s.y]

func quality_label() -> String:
	match int(get_setting("quality", 1)):
		0: return "Essenziale"
		2: return "Massima"
		_: return "Bilanciata"

func layout_glyphs() -> Dictionary:
	var layout := str(get_setting("controller_layout", "auto"))
	if layout == "auto":
		layout = _detect_layout()
	match layout:
		"playstation":
			return {"accept": "✕", "cancel": "○", "repeat": "□", "highlight": "△",
				"lb": "L1", "rb": "R1", "start": "OPTIONS", "back": "SHARE", "style": "playstation"}
		"nintendo":
			return {"accept": "A", "cancel": "B", "repeat": "Y", "highlight": "X",
				"lb": "L", "rb": "R", "start": "+", "back": "−", "style": "nintendo"}
		_:
			return {"accept": "A", "cancel": "B", "repeat": "X", "highlight": "Y",
				"lb": "LB", "rb": "RB", "start": "START", "back": "BACK", "style": "xbox"}

func controller_layout_name() -> String:
	var l := str(get_setting("controller_layout", "auto"))
	if l == "auto":
		l = _detect_layout()
	match l:
		"playstation": return "PlayStation"
		"nintendo": return "Nintendo"
		_: return "Xbox"

func _detect_layout() -> String:
	if Input.get_connected_joypads().is_empty():
		return "xbox"
	var n := Input.get_joy_name(Input.get_connected_joypads()[0]).to_lower()
	if n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation") or n.contains("sony"):
		return "playstation"
	if n.contains("nintendo") or n.contains("switch") or n.contains("joy-con") or n.contains("joycon"):
		return "nintendo"
	return "xbox"

func has_controller() -> bool:
	return not Input.get_connected_joypads().is_empty()

func controller_name() -> String:
	var pads := Input.get_connected_joypads()
	return "Controller collegato" if pads.is_empty() else Input.get_joy_name(pads[0])

func rumble(strength: float = 0.35, duration: float = 0.16) -> void:
	if not bool(get_setting("vibration", false)):
		return
	var pads := Input.get_connected_joypads()
	for p in pads:
		Input.start_joy_vibration(p, strength * 0.6, strength, duration)

# ---------------------------------------------------------------- persistence

func _load() -> void:
	data = DEFAULTS.duplicate(true)
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in DEFAULTS.keys():
					if parsed.has(k):
						var def: Variant = DEFAULTS[k]
						var val: Variant = parsed[k]
						if typeof(def) == typeof(val) or (def is float and val is int):
							data[k] = val
	_loaded = true

func _save_soon() -> void:
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_save_now")

func _save_now() -> void:
	_save_queued = false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

# ---------------------------------------------------------------- input

func _ensure_inputs() -> void:
	_axis_action("move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_axis_action("move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_axis_action("move_forward", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_axis_action("move_back", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_button_action("move_left_pad", [], JOY_BUTTON_DPAD_LEFT)
	_button_action("move_right_pad", [], JOY_BUTTON_DPAD_RIGHT)
	_button_action("move_up_pad", [], JOY_BUTTON_DPAD_UP)
	_button_action("move_down_pad", [], JOY_BUTTON_DPAD_DOWN)

	_button_action("interact", [KEY_E, KEY_ENTER, KEY_SPACE], JOY_BUTTON_A)
	_button_action("cancel", [KEY_BACKSPACE], JOY_BUTTON_B)
	_button_action("repeat_help", [KEY_H], JOY_BUTTON_X)
	_button_action("highlight", [KEY_TAB, KEY_L], JOY_BUTTON_Y)
	_button_action("cycle_next", [KEY_R], JOY_BUTTON_RIGHT_SHOULDER)
	_button_action("cycle_prev", [KEY_Q], JOY_BUTTON_LEFT_SHOULDER)
	_axis_action("zoom_in", [KEY_EQUAL, KEY_KP_ADD], JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_axis_action("zoom_out", [KEY_MINUS, KEY_KP_SUBTRACT], JOY_AXIS_TRIGGER_LEFT, 1.0)
	_button_action("pause", [KEY_P, KEY_ESCAPE], JOY_BUTTON_START)
	_button_action("journal", [KEY_J], JOY_BUTTON_BACK)

	_axis_action("cam_left", [KEY_LEFT], JOY_AXIS_RIGHT_X, -1.0)
	_axis_action("cam_right", [KEY_RIGHT], JOY_AXIS_RIGHT_X, 1.0)
	_axis_action("cam_up", [KEY_UP], JOY_AXIS_RIGHT_Y, -1.0)
	_axis_action("cam_down", [KEY_DOWN], JOY_AXIS_RIGHT_Y, 1.0)

	# Navigazione UI: D-pad, stick sinistro e pulsanti faccia.
	_ui_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ui_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ui_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ui_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)
	_ui_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_ui_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ui_button("ui_up", JOY_BUTTON_DPAD_UP)
	_ui_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_ui_button("ui_accept", JOY_BUTTON_A)
	_ui_button("ui_cancel", JOY_BUTTON_B)
	_ui_button("ui_focus_next", JOY_BUTTON_RIGHT_SHOULDER)
	_ui_button("ui_focus_prev", JOY_BUTTON_LEFT_SHOULDER)

func _deadzone() -> float:
	return clampf(float(data.get("deadzone", 0.25)), 0.08, 0.6)

func _axis_action(action: String, keys: Array, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, _deadzone())
	InputMap.action_set_deadzone(action, _deadzone())
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
	var ev2 := InputEventJoypadMotion.new()
	ev2.axis = axis
	ev2.axis_value = value
	if not InputMap.action_has_event(action, ev2):
		InputMap.action_add_event(action, ev2)

func _button_action(action: String, keys: Array, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, _deadzone())
	InputMap.action_set_deadzone(action, _deadzone())
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
	var ev2 := InputEventJoypadButton.new()
	ev2.button_index = button
	if not InputMap.action_has_event(action, ev2):
		InputMap.action_add_event(action, ev2)

func _ui_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, _deadzone())
	InputMap.action_set_deadzone(action, _deadzone())
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)

func _ui_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
