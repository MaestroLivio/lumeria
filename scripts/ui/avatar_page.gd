class_name AvatarPage
extends OverlayPage
## Guardaroba: anteprima 3D e personalizzazione dell'avatar.

signal appearance_changed

var _appearance: Dictionary = {}
var _preview_root: Node3D
var _avatar: Node3D
var _controls: VBoxContainer
var _viewport: SubViewport
var _spin := 0.0

func _init() -> void:
	page_title = "Guardaroba"
	page_icon = "mano"
	close_text = "Indossa e torna"

func _page_ready() -> void:
	var pal := UITheme.palette()
	_appearance = SaveGame.appearance().duplicate(true)
	content.add_child(UIKit.body(
		"Scegli il corpo, i colori e il cappello. L'avatar è solo tuo e resta salvato su questo dispositivo.",
		19, pal["ink_soft"]))

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(body)

	var preview_panel := PanelContainer.new()
	UITheme.style_panel(preview_panel, "chip")
	preview_panel.custom_minimum_size = Vector2(330, 330)
	preview_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(preview_panel)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(320, 320)
	preview_panel.add_child(holder)
	_build_preview(holder)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	_controls = VBoxContainer.new()
	_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls.add_theme_constant_override("separation", 10)
	right.add_child(_controls)

	var hint := UIKit.label("Ogni scelta si applica subito anche nel mondo.", 15, pal["ink_soft"])
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hint)
	_rebuild_controls()

func _build_preview(holder: Control) -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(container)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(512, 512)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(_viewport)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#2B3552")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#C9D8F2")
	env.ambient_light_energy = 0.7
	world_env.environment = env
	_viewport.add_child(world_env)

	_preview_root = Node3D.new()
	_viewport.add_child(_preview_root)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42), deg_to_rad(-32), 0)
	key.light_color = Color("#FFF0D0")
	key.light_energy = 1.5
	_preview_root.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.2, 2.2, 2.4)
	fill.light_color = Color("#9FD8E8")
	fill.light_energy = 1.1
	fill.omni_range = 9.0
	_preview_root.add_child(fill)

	MeshHelpers.cylinder(_preview_root, 0.95, 1.05, 0.16, Color("#E8D9BC"), Vector3(0, -0.08, 0), Vector3.ZERO,
		Color(0, 0, 0, 0), 0.0, 32)
	MeshHelpers.torus(_preview_root, 0.99, 1.07, Color("#F2B84B"), Vector3(0, 0.02, 0), Vector3.ZERO,
		Color("#F2B84B"), 0.5)
	var shadow := MeshInstance3D.new()
	var shadow_mesh := QuadMesh.new()
	shadow_mesh.size = Vector2(1.5, 1.5)
	shadow.mesh = shadow_mesh
	shadow.rotation.x = -PI / 2.0
	shadow.position = Vector3(0, 0.02, 0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = load("res://assets/shaders/blob_shadow.gdshader")
	shadow.material_override = shadow_mat
	_preview_root.add_child(shadow)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.18, 3.65)
	camera.fov = 38.0
	camera.near = 0.05
	camera.far = 40.0
	_preview_root.add_child(camera)
	camera.look_at_from_position(Vector3(0, 1.18, 3.65), Vector3(0, 1.06, 0), Vector3.UP)

	_rebuild_avatar()

func _rebuild_avatar() -> void:
	if _avatar and is_instance_valid(_avatar):
		_avatar.queue_free()
	_avatar = AvatarBuilder.build(_appearance)
	_avatar.scale = Vector3(1.08, 1.08, 1.08)
	_preview_root.add_child(_avatar)

func _rebuild_controls() -> void:
	if _controls == null:
		return
	for c in _controls.get_children():
		_controls.remove_child(c)
		c.queue_free()
	var pal := UITheme.palette()
	_controls.add_child(UIKit.cycle_row("Corpo", SaveGame.BODIES,
		clampi(int(_appearance.get("body", 0)), 0, SaveGame.BODIES.size() - 1),
		func(i: int) -> void:
			_appearance["body"] = i
			_apply()))
	_controls.add_child(_swatch_row("Colore della pelle", "body_color", SaveGame.BODY_COLORS))
	_controls.add_child(_swatch_row("Colore del vestito", "outfit_color", SaveGame.OUTFIT_COLORS))
	_controls.add_child(UIKit.cycle_row("Cappello", SaveGame.HATS,
		clampi(int(_appearance.get("hat", 1)), 0, SaveGame.HATS.size() - 1),
		func(i: int) -> void:
			_appearance["hat"] = i
			_apply()))
	_controls.add_child(_swatch_row("Colore del cappello", "hat_color", SaveGame.HAT_COLORS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_controls.add_child(row)
	var random := UIKit.button("Sorpresa!", "Warm", 48)
	random.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		_appearance["body"] = randi_range(0, SaveGame.BODIES.size() - 1)
		_appearance["body_color"] = randi_range(0, SaveGame.BODY_COLORS.size() - 1)
		_appearance["outfit_color"] = randi_range(0, SaveGame.OUTFIT_COLORS.size() - 1)
		_appearance["hat"] = randi_range(0, SaveGame.HATS.size() - 1)
		_appearance["hat_color"] = randi_range(0, SaveGame.HAT_COLORS.size() - 1)
		_apply()
		call_deferred("_rebuild_controls"))
	row.add_child(random)
	var classic := UIKit.button("Classico", "", 48)
	classic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	classic.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		_appearance = {"body": 0, "body_color": 0, "outfit_color": 0, "hat": 1, "hat_color": 1}
		_apply()
		call_deferred("_rebuild_controls"))
	row.add_child(classic)
	return

func _swatch_row(label_text: String, key: String, colors: Array) -> VBoxContainer:
	var pal := UITheme.palette()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(UIKit.label(label_text, 20, pal["ink"]))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	box.add_child(h)
	var selected := clampi(int(_appearance.get(key, 0)), 0, colors.size() - 1)
	for i in range(colors.size()):
		var color: Color = colors[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 40)
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "Colore %d" % (i + 1)
		var normal := StyleBoxFlat.new()
		normal.bg_color = color
		normal.set_corner_radius_all(12)
		normal.set_border_width_all(4 if i == selected else 2)
		normal.border_color = pal["gold"] if i == selected else Color(pal["ink"], 0.28)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.border_color = pal["accent2"]
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0, 0, 0, 0)
		focus.set_corner_radius_all(14)
		focus.set_border_width_all(4)
		focus.border_color = pal["gold"]
		focus.set_expand_margin_all(2)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_stylebox_override("focus", focus)
		b.pressed.connect(func() -> void:
			Audio.play_sfx("click")
			_appearance[key] = i
			_apply()
			Audio.say("Colore %d" % (i + 1))
			call_deferred("_rebuild_controls"))
		h.add_child(b)
	return box

func _apply() -> void:
	SaveGame.set_appearance(_appearance.duplicate(true))
	_rebuild_avatar()
	appearance_changed.emit()

func _process(delta: float) -> void:
	if _avatar == null or not is_instance_valid(_avatar):
		return
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	_spin += delta * 0.5
	# L'avatar guarda verso -Z: l'anteprima lo gira di mezzo giro per mostrare
	# il viso alla camera, che sta sul lato +Z.
	_avatar.rotation.y = PI + _spin
