class_name MissionSocket3D
extends Node3D
## Incastro della missione: può essere vuoto, fisso o contenere più cubi (cesti).
## Le pedane di misura mostrano il riferimento vero: corde lunghe disegnate a
## unità e torri di altezza diversa, non due piastre identiche.

const BAR_UNIT := 0.30
const BAR_THICK := 0.30
const TOWER_UNIT := 0.26

var data: Dictionary = {}
var socket_id := ""
var accepts: Array = []
var is_fixed := false
var capacity := 1
var has_bar := false
var has_tower := false
## Il cubo risposta si posa davanti al riferimento, per non coprirlo.
var cube_offset := Vector3.ZERO
var _ring: MeshInstance3D
var _label: Label3D
var _icon: Sprite3D
var _area: Area3D
var _focus_ring: MeshInstance3D

func build(d: Dictionary, pos: Vector3) -> void:
	data = d
	socket_id = str(d.get("id", ""))
	accepts = d.get("accepts", [])
	is_fixed = d.has("fixed")
	capacity = int(d.get("capacity", 1))
	position = pos
	var bar: Dictionary = d.get("bar", {}) if d.get("bar", {}) is Dictionary else {}
	var tower: Dictionary = d.get("tower", {}) if d.get("tower", {}) is Dictionary else {}
	has_bar = not bar.is_empty()
	has_tower = not tower.is_empty()
	if has_bar or has_tower:
		cube_offset = Vector3(0, 0, 0.36)
	var color: Color = MissionData.COLORS.get(str(d.get("hint_color", "teal")), Color("#4FB3A9"))
	MeshHelpers.box(self, Vector3(1.22, 0.1, 1.22), Color("#EBD9B8"), Vector3(0, 0.05, 0))
	MeshHelpers.box(self, Vector3(1.02, 0.04, 1.02), Color("#E3D2B8"), Vector3(0, 0.11, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			MeshHelpers.box(self, Vector3(0.08, 0.26, 0.08), Color("#C9B18F"),
				Vector3(0.55 * sx, 0.2, 0.55 * sz))
	_ring = MeshHelpers.torus(self, 0.47, 0.55, color, Vector3(0, 0.13, 0),
		Vector3.ZERO, color, 0.28)
	_ring.name = "Anello"
	_focus_ring = MeshHelpers.torus(self, 0.64, 0.73, Color("#FFE066"), Vector3(0, 0.18, 0),
		Vector3.ZERO, Color("#FFE066"), 1.5)
	_focus_ring.name = "Fuoco"
	_focus_ring.visible = false

	var text := str(d.get("hint_label", ""))
	if is_fixed:
		if has_bar:
			# La corda fissa è il riferimento da confrontare: si disegna lunga.
			_build_bar(bar, 0.13 + BAR_THICK * 0.5, 0.0)
		else:
			var fixed_label := str(d.get("fixed_label", str(d.get("fixed", ""))))
			var fixed_icon := str(d.get("fixed_icon", ""))
			var fixed_color: Color = MissionData.COLORS.get(str(d.get("fixed_color", "legno")), Color("#D8B98A"))
			MeshHelpers.box(self, Vector3(0.76, 0.76, 0.1), fixed_color, Vector3(0, 0.36, 0),
				Vector3.ZERO, fixed_color, 0.12)
			if fixed_icon != "" and fixed_label != "":
				MeshHelpers.icon(self, fixed_icon, Color("#3B2A20"), 0.44, Vector3(0, 0.46, 0.26), false)
				MeshHelpers.label(self, fixed_label, 26, Color("#3B2A20"), Vector3(0, 0.2, 0.27), 34, false)
			elif fixed_icon != "":
				MeshHelpers.icon(self, fixed_icon, Color("#3B2A20"), 0.58, Vector3(0, 0.36, 0.27), false)
			else:
				MeshHelpers.label(self, fixed_label, 42, Color("#3B2A20"), Vector3(0, 0.34, 0.27), 50, false)
			if text == "":
				text = fixed_label
	if text != "":
		# Etichetta sospesa sopra l'incastro: resta leggibile anche col cubo dentro.
		_label = MeshHelpers.label(self, text, 34, Color("#2E2018"),
			Vector3(0, 1.26, 0), 44)
	var hint_icon := str(d.get("hint_icon", ""))
	if hint_icon != "" and not has_tower and not has_bar:
		# Icona distesa sulla piastra: quando il cubo arriva la copre, senza
		# restare sospesa davanti al cubo piazzato.
		_icon = MeshHelpers.icon(self, hint_icon, color, 0.66, Vector3(0, 0.145, 0),
			false, Vector3(-PI / 2, 0, 0))
	if has_bar and not is_fixed:
		_build_bar(bar, 0.13 + BAR_THICK * 0.5, -0.34)
	if has_tower:
		_build_tower(tower)

## Una corda/trave di riferimento, con una tacca per unità: si conta a vista.
func _build_bar(bar: Dictionary, y: float, z: float) -> void:
	var units := maxf(1.0, float(bar.get("length", 2)))
	var color: Color = MissionData.COLORS.get(str(bar.get("color", data.get("fixed_color", "legno"))),
		Color("#B98A55"))
	var length := units * BAR_UNIT
	MeshHelpers.box(self, Vector3(length, BAR_THICK, BAR_THICK), color, Vector3(0, y, z),
		Vector3.ZERO, color.darkened(0.18), 0.05)
	for sx in [-1.0, 1.0]:
		MeshHelpers.cylinder(self, BAR_THICK * 0.5, BAR_THICK * 0.5, BAR_THICK,
			color.darkened(0.08), Vector3(sx * length * 0.5, y, z), Vector3(0, 0, PI / 2),
			color.darkened(0.28), 0.05, 18)
	var whole := int(round(units))
	for i in range(1, whole):
		var x := -length * 0.5 + BAR_UNIT * float(i)
		MeshHelpers.box(self, Vector3(0.022, BAR_THICK + 0.012, BAR_THICK + 0.012),
			color.darkened(0.42), Vector3(x, y, z))
	for sx in [-1.0, 1.0]:
		MeshHelpers.box(self, Vector3(0.035, BAR_THICK + 0.016, BAR_THICK + 0.016),
			color.lightened(0.35), Vector3(sx * (length * 0.5 - 0.055), y, z))

## Torre di riferimento: blocchi sovrapposti, uno per unità di altezza.
func _build_tower(tower: Dictionary) -> void:
	var units := maxi(1, int(tower.get("units", 4)))
	var color: Color = MissionData.COLORS.get(str(tower.get("color", data.get("hint_color", "teal"))),
		Color("#4FB3A9"))
	var w := 0.38
	var z := -0.34
	var base := 0.13
	for i in range(units):
		var shade := color.lightened(0.05 if i % 2 == 0 else -0.05)
		MeshHelpers.box(self, Vector3(w, TOWER_UNIT - 0.025, w), shade,
			Vector3(0, base + TOWER_UNIT * (float(i) + 0.5), z), Vector3.ZERO,
			shade.darkened(0.28), 0.04)
		# linea di separazione chiara: le unità si contano una a una
		if i > 0:
			MeshHelpers.box(self, Vector3(w + 0.02, 0.02, w + 0.02), color.lightened(0.45),
				Vector3(0, base + TOWER_UNIT * float(i), z))
	# cima arrotondata, per distinguere l'alto dal basso
	MeshHelpers.cylinder(self, 0.02, w * 0.5, 0.16, color.lightened(0.2),
		Vector3(0, base + TOWER_UNIT * float(units) + 0.08, z), Vector3.ZERO,
		color.lightened(0.25), 0.08, 4)
	# asta graduata dietro la torre, con una tacca per unità
	MeshHelpers.box(self, Vector3(0.035, TOWER_UNIT * float(units) + 0.2, 0.035),
		Color("#8A6242"), Vector3(-w * 0.5 - 0.13, base + (TOWER_UNIT * float(units) + 0.2) * 0.5, z))
	for i in range(1, units):
		MeshHelpers.box(self, Vector3(0.11, 0.022, 0.03), Color("#6B4A32"),
			Vector3(-w * 0.5 - 0.08, base + TOWER_UNIT * float(i), z))

	if not is_fixed:
		_area = Area3D.new()
		_area.name = "Presa"
		_area.collision_layer = 4
		_area.collision_mask = 0
		_area.monitoring = false
		_area.monitorable = true
		_area.input_ray_pickable = true
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 0.9, 1.2)
		shape.shape = box
		shape.position = Vector3(0, 0.45, 0)
		_area.add_child(shape)
		_area.set_meta("kind", "socket")
		_area.set_meta("id", socket_id)
		add_child(_area)

func set_focused(value: bool) -> void:
	if _focus_ring:
		_focus_ring.visible = value
	if _ring:
		_ring.scale = Vector3.ONE * (1.12 if value else 1.0)
	if _label:
		_label.modulate = Color("#FFF3B0") if value else Color("#FFF7E8")

func set_filled_tint(value: bool) -> void:
	if _ring == null:
		return
	var c: Color = MissionData.COLORS.get(str(data.get("hint_color", "teal")), Color("#4FB3A9"))
	if value:
		_ring.material_override = MeshHelpers.material(c, c, 0.9)
	else:
		_ring.material_override = MeshHelpers.material(c.darkened(0.2), c, 0.25)
	# I segnaposto corti ("?", "1"...) spariscono quando il cubo mostra il valore.
	if _label and _label.text.length() <= 2:
		_label.visible = not value

func center_global() -> Vector3:
	return to_global(Vector3(0, 0.55, 0))
