class_name RegionStation
extends Node3D
## Postazione di missione (o chiosco speciale) nel mondo esplorabile.
##
## I cartelli sono FISSI: icona e scritta non inseguono la camera (niente
## billboard). Sono stampati su entrambe le facciate, così restano leggibili
## sia arrivando sia tornando indietro. Quando il giocatore si avvicina, una
## luce calda accende il pannello e il cartello "chiama" l'attenzione.

var mission: Dictionary = {}
var region_index := 0
var special := ""
var completed := false

var title := ""
var station_id := ""
var accent := Color("#F2C24B")

var _icon_front: Sprite3D
var _icon_back: Sprite3D
var _label_code_front: Label3D
var _label_code_back: Label3D
var _label_front: Label3D
var _label_back: Label3D
var _panel_front: MeshInstance3D
var _panel_back: MeshInstance3D
var _panel_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _glow: OmniLight3D
var _sign_glow: OmniLight3D
var _phase := 0.0
var _light_level := 0.0
var _player: Node3D = null

func setup_mission(m: Dictionary, color: Color) -> void:
	mission = m
	station_id = str(m.get("id", ""))
	title = str(m.get("title", ""))
	region_index = int(m.get("region", 1))
	accent = color
	_build("%03d" % int(station_id) if station_id.is_valid_int() else station_id, title,
		str(m.get("icon", "star")), color)

func setup_special(kind: String, label: String, icon_name: String, color: Color) -> void:
	special = kind
	station_id = "special_" + kind
	title = label
	accent = color
	region_index = 0
	_build("", label, icon_name, color)

func _build(code: String, label_text: String, icon_name: String, color: Color) -> void:
	var base := MeshHelpers.cylinder(self, 0.72, 0.9, 0.22, Color("#D8C3A5"), Vector3(0, 0.11, 0))
	base.name = "Base"
	MeshHelpers.cylinder(self, 0.5, 0.62, 0.16, Color("#FFF2D8"), Vector3(0, 0.3, 0))
	var pillar := MeshHelpers.box(self, Vector3(0.12, 1.45, 0.12), Color("#A97A48"), Vector3(0, 1.02, 0))
	pillar.name = "Pilastro"
	# Cornice e pannelli bianchi su entrambe le facciate del cartello.
	MeshHelpers.box(self, Vector3(1.35, 0.9, 0.12), color.darkened(0.18), Vector3(0, 1.95, 0))
	_panel_mat = StandardMaterial3D.new()
	_panel_mat.albedo_color = Color("#FFF7E8").srgb_to_linear()
	_panel_mat.roughness = 0.7
	_panel_mat.emission_enabled = true
	_panel_mat.emission = Color("#FFE9B0").srgb_to_linear()
	_panel_mat.emission_energy_multiplier = 0.0
	_panel_front = MeshHelpers.box(self, Vector3(1.18, 0.66, 0.04), Color("#FFF7E8"),
		Vector3(0, 1.95, 0.08))
	_panel_front.material_override = _panel_mat
	_panel_back = MeshHelpers.box(self, Vector3(1.18, 0.66, 0.04), Color("#FFF7E8"),
		Vector3(0, 1.95, -0.08))
	_panel_back.material_override = _panel_mat

	# Icona e testo su ciascuna faccia: la copia posteriore è ruotata di 180°,
	# così il disegno resta dritto anche guardandolo da dietro. Il testo è scuro
	# sul pannello chiaro, altrimenti da lontano sembrerebbe una lastra vuota.
	var title_size := 22
	if label_text.length() > 24:
		title_size = 17
	elif label_text.length() > 18:
		title_size = 19
	_icon_front = MeshHelpers.icon(self, icon_name, color.darkened(0.22), 0.36,
		Vector3(0, 2.02, 0.135), false)
	_icon_front.name = "IconaAvanti"
	_icon_back = MeshHelpers.icon(self, icon_name, color.darkened(0.22), 0.36,
		Vector3(0, 2.02, -0.135), false, Vector3(0, PI, 0))
	_icon_back.name = "IconaDietro"
	if code != "":
		_label_code_front = MeshHelpers.label(self, code, 18, Color("#FFF7E8"),
			Vector3(0, 2.35, 0.125), 36, false)
		_label_code_front.name = "CodiceAvanti"
		_label_code_back = MeshHelpers.label(self, code, 18, Color("#FFF7E8"),
			Vector3(0, 2.35, -0.125), 36, false, Vector3(0, PI, 0))
		_label_code_back.name = "CodiceDietro"
	_label_front = MeshHelpers.label(self, label_text, title_size, Color("#3B2A20"),
		Vector3(0, 1.71, 0.125), 40, false)
	_label_front.name = "TitoloAvanti"
	_label_back = MeshHelpers.label(self, label_text, title_size, Color("#3B2A20"),
		Vector3(0, 1.71, -0.125), 40, false, Vector3(0, PI, 0))
	_label_back.name = "TitoloDietro"

	_ring = MeshHelpers.torus(self, 0.62, 0.74, color, Vector3(0, 0.42, 0),
		Vector3.ZERO, color, 0.7 if not completed else 0.15)
	_ring.name = "Anello"
	_glow = OmniLight3D.new()
	_glow.light_color = color
	_glow.light_energy = 0.55
	_glow.omni_range = 2.4
	_glow.position = Vector3(0, 1.5, 0)
	add_child(_glow)
	# Luce dedicata al cartello: parte spenta e si accende con l'avvicinarsi.
	_sign_glow = OmniLight3D.new()
	_sign_glow.name = "LuceCartello"
	_sign_glow.light_color = Color("#FFE9B0")
	_sign_glow.light_energy = 0.0
	_sign_glow.omni_range = 2.6
	_sign_glow.omni_attenuation = 1.5
	_sign_glow.position = Vector3(0, 2.1, 0.78)
	_sign_glow.visible = false
	add_child(_sign_glow)
	_apply_completed_visual()

func set_completed(value: bool) -> void:
	completed = value
	_apply_completed_visual()

func _apply_completed_visual() -> void:
	if _ring == null:
		return
	if completed:
		_ring.material_override = MeshHelpers.material(accent, accent, 2.2)
	else:
		_ring.material_override = MeshHelpers.material(accent.darkened(0.15), accent, 0.4)

func _process(delta: float) -> void:
	_phase += delta
	if _ring:
		_ring.rotation.y += delta * (0.5 if completed else 0.22)
	_update_sign_light(delta)

## La luce del cartello cresce con la vicinanza del giocatore: è un invito
## dolce, senza lampi, e rende la postazione riconoscibile da lontano.
func _update_sign_light(delta: float) -> void:
	var p := _player_node()
	var target := 0.0
	if p != null:
		var d := p.global_position.distance_to(global_position)
		target = clampf((15.0 - d) / 11.0, 0.0, 1.0)
		target = target * target * (3.0 - 2.0 * target)  # smoothstep
	_light_level = lerpf(_light_level, target, clampf(delta * 4.0, 0.0, 1.0))
	var pulse := 1.0
	if _light_level > 0.02 and not bool(Settings.get_setting("reduce_motion", false)):
		pulse = 0.92 + 0.08 * sin(_phase * 2.2 + float(region_index))
	var e := _light_level * pulse
	if _sign_glow:
		_sign_glow.visible = e > 0.015
		_sign_glow.light_energy = e * 0.95 * Settings.glow_scale()
		_sign_glow.omni_range = 2.5 + e * 1.6
	if _glow:
		_glow.light_energy = ((0.42 if completed else 0.30) + e * 0.55) * Settings.glow_scale()
	if _panel_mat:
		_panel_mat.emission_energy_multiplier = e * 0.38 * Settings.glow_scale()
	var tint := Color(1.0 + e * 0.12, 1.0 + e * 0.10, 0.96 + e * 0.06)
	for icon in [_icon_front, _icon_back]:
		if icon:
			icon.modulate = tint
	for lab in [_label_front, _label_back]:
		if lab:
			lab.modulate = Color("#3B2A20").lerp(Color("#8A5A20"), e * 0.35)
	for lab in [_label_code_front, _label_code_back]:
		if lab:
			lab.modulate = Color("#FFF7E8").lerp(Color("#FFE066"), e * 0.8)
	if _ring:
		_ring.scale = Vector3.ONE * (1.0 + e * 0.05)

func _player_node() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player

func prompt_text() -> String:
	if special != "":
		return title
	if completed:
		return "Rigioca: " + title
	return title
