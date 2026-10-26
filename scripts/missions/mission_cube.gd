class_name MissionCube3D
extends Node3D
## Cubo manipolabile della missione: forma, colore, icona o parola.
## Il simbolo sta sul coperchio, così si legge dalla camera alta del tavolo.

const SIZE := 0.86
## Una unità di misura disegnata: 0,30 m per unità. Le corde lunghe 6 unità
## arrivano a 1,8 m, così la differenza si vede davvero.
const BAR_UNIT := 0.30
const BAR_THICK := 0.30

var data: Dictionary = {}
var cube_id := ""
var placed := false
var is_bar := false
var _body: MeshInstance3D
var _orig_mat: Material
var _area: Area3D
var _ring: MeshInstance3D
var _base_scale := 1.0
var _shape := Vector3.ONE
var _home := Vector3.ZERO

func build(d: Dictionary, home: Vector3) -> void:
	data = d
	cube_id = str(d.get("id", ""))
	_home = home
	position = home
	# Alcuni cubi sono deliberatamente più piccoli o più alti (seriazioni).
	# I funghi della missione "dal più piccolo" cambiano solo in altezza:
	# allargarli tutti allo stesso modo confonderebbe la lettura.
	var raw_scale := clampf(float(d.get("scale", 1.0)), 0.45, 1.45)
	if d.has("scale"):
		_base_scale = raw_scale
		_shape = Vector3(1.0, raw_scale, 1.0)
	else:
		_base_scale = raw_scale
		_shape = Vector3.ONE * raw_scale
	scale = _shape
	var bar: Dictionary = d.get("bar", {}) if d.get("bar", {}) is Dictionary else {}
	if not bar.is_empty():
		is_bar = true
		_build_bar(bar)
	else:
		_build_box()
	_build_ring()
	_build_area()

func _cube_color() -> Color:
	return MissionData.COLORS.get(str(data.get("color", "legno")), Color("#D8B98A"))

func _build_box() -> void:
	var color := _cube_color()
	_body = MeshHelpers.box(self, Vector3(SIZE, SIZE, SIZE), color, Vector3.ZERO,
		Vector3.ZERO, color.darkened(0.25), 0.06)
	_body.name = "Cubo"
	_orig_mat = _body.material_override
	# bordi morbidi
	MeshHelpers.box(self, Vector3(SIZE + 0.04, 0.08, SIZE + 0.04), color.darkened(0.16),
		Vector3(0, 0.46, 0))
	MeshHelpers.box(self, Vector3(SIZE + 0.04, 0.08, SIZE + 0.04), color.darkened(0.16),
		Vector3(0, -0.46, 0))

	var label := str(data.get("label", ""))
	var icon_name := str(data.get("icon", ""))
	# Il coperchio ha uno spessore di 0.08: il simbolo va stampato sopra, non dentro.
	var top := SIZE * 0.5 + 0.085
	# Il simbolo è stampato sul coperchio: dall'alto si vede sempre.
	if icon_name != "":
		MeshHelpers.icon(self, icon_name, Color("#FFF6E4"), 0.66, Vector3(0, top, 0),
			false, Vector3(-PI / 2, 0, 0))
	if label != "":
		if icon_name != "":
			# icona sul coperchio + parola leggibile appena sopra il cubo
			MeshHelpers.label(self, label, 30, Color("#FFF6E4"), Vector3(0, 0.78, 0),
				38, true, Vector3.ZERO)
		else:
			MeshHelpers.label(self, label, 58, Color("#FFF6E4"), Vector3(0, top, 0),
				64, false, Vector3(-PI / 2, 0, 0))
	if data.has("count"):
		MeshHelpers.label(self, "×%d" % int(data.get("count", 1)), 34, Color("#FFF6E4"),
			Vector3(0, top, 0.36), 40, false, Vector3(-PI / 2, 0, 0))

## Corde, nastri e travi: una barra lunga davvero, con una tacca per unità.
## Le tacche permettono di contare i pezzi senza leggere un numero.
func _build_bar(bar: Dictionary) -> void:
	var units := maxf(1.0, float(bar.get("length", 2)))
	var color: Color = MissionData.COLORS.get(str(bar.get("color", data.get("color", "legno"))),
		_cube_color())
	var length := units * BAR_UNIT
	_body = MeshHelpers.box(self, Vector3(length, BAR_THICK, BAR_THICK), color, Vector3.ZERO,
		Vector3.ZERO, color.darkened(0.18), 0.05)
	_body.name = "Barra"
	_orig_mat = _body.material_override
	# estremità arrotondate: la corda non finisce a spigolo vivo
	for sx in [-1.0, 1.0]:
		MeshHelpers.cylinder(self, BAR_THICK * 0.5, BAR_THICK * 0.5, BAR_THICK,
			color.darkened(0.08), Vector3(sx * length * 0.5, 0, 0), Vector3(0, 0, PI / 2),
			color.darkened(0.28), 0.05, 18)
	# tacche scure ai confini di ogni unità
	var whole := int(round(units))
	for i in range(1, whole):
		var x := -length * 0.5 + BAR_UNIT * float(i)
		MeshHelpers.box(self, Vector3(0.022, BAR_THICK + 0.012, BAR_THICK + 0.012),
			color.darkened(0.42), Vector3(x, 0, 0))
	# fascette chiare alle due estremità, per vedere dove inizia e finisce
	for sx in [-1.0, 1.0]:
		MeshHelpers.box(self, Vector3(0.035, BAR_THICK + 0.016, BAR_THICK + 0.016),
			color.lightened(0.35), Vector3(sx * (length * 0.5 - 0.055), 0, 0))
	var label := str(data.get("label", ""))
	if label != "":
		MeshHelpers.label(self, label, 30, Color("#FFF6E4"), Vector3(0, BAR_THICK * 0.5 + 0.10, 0),
			34, true, Vector3.ZERO)
	elif str(data.get("icon", "")) != "":
		MeshHelpers.icon(self, str(data.get("icon", "")), Color("#FFF6E4"), 0.38,
			Vector3(0, BAR_THICK * 0.5 + 0.06, 0), true)

func _build_ring() -> void:
	_ring = MeshHelpers.torus(self, 0.58, 0.68, Color("#FFE066"), Vector3(0, 0.02, 0),
		Vector3.ZERO, Color("#FFE066"), 1.4)
	_ring.name = "Fuoco"
	_ring.visible = false

func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "Presa"
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	_area.monitorable = true
	_area.input_ray_pickable = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	if is_bar:
		var units := maxf(1.0, float((data.get("bar", {}) as Dictionary).get("length", 2)))
		box.size = Vector3(units * BAR_UNIT + 0.2, 0.55, 0.55)
	else:
		box.size = Vector3(0.96, 0.96, 0.96)
	shape.shape = box
	_area.add_child(shape)
	_area.set_meta("kind", "cube")
	_area.set_meta("id", cube_id)
	add_child(_area)

func set_focused(value: bool) -> void:
	if _ring == null:
		return
	_ring.visible = value
	if _ring.visible and is_bar:
		# Per una corda lunga il cerchio sarebbe un ovale enorme: basta la
		# luce sul corpo, che segue la forma reale.
		_ring.visible = false
	if not placed:
		scale = _shape * (1.08 if value else 1.0)
	if value:
		var base := _cube_color()
		if is_bar:
			var bar: Dictionary = data.get("bar", {})
			base = MissionData.COLORS.get(str(bar.get("color", data.get("color", "legno"))), base)
		_body.material_override = MeshHelpers.material(
			base.lightened(0.1), Color("#FFE066"), 0.36)
	else:
		_body.material_override = _orig_mat

## Il cubo in mano non deve intercettare i clic: sotto c'è l'incastro da scegliere.
func set_pickable(value: bool) -> void:
	if _area == null:
		return
	_area.collision_layer = 4 if value else 0
	_area.input_ray_pickable = value

## Dispone il cubo dentro l'incastro. Con più cubi nello stesso cesto si
## dividono lo spazio in una fila, senza sovrapporsi.
func set_placed(is_placed: bool, socket: Node3D = null, slot: int = 0, count: int = 1) -> void:
	placed = is_placed
	if is_placed and socket:
		if get_parent() != socket:
			if get_parent():
				get_parent().remove_child(self)
			socket.add_child(self)
		var n := maxi(1, count)
		var s := clampf(1.16 / float(n), 0.34, 0.86)
		var idx := maxi(0, slot)
		var f := s
		# Una corda posata da sola conserva la lunghezza vera: è il confronto
		# con la corda di riferimento a dover restare leggibile.
		if is_bar and n == 1:
			f = 1.0
		var x := (float(idx) - float(n - 1) * 0.5) * s
		# Appoggia sul vassoio dell'incastro: niente cubi o corde sospesi.
		var half_h := (BAR_THICK * 0.5 if is_bar else SIZE * 0.5) * f * _shape.y
		position = Vector3(x, 0.134 + half_h, 0)
		if socket is MissionSocket3D:
			var sock := socket as MissionSocket3D
			position += Vector3(sock.cube_offset.x, 0.0, sock.cube_offset.z)
		scale = _shape * f
		rotation = Vector3.ZERO
	else:
		if get_parent():
			get_parent().remove_child(self)
		# Il chiamante lo riaggiunge alla scena.

func return_home() -> void:
	placed = false
	rotation = Vector3.ZERO
	scale = _shape
	position = _home
	set_pickable(true)

func home_position() -> Vector3:
	return _home

func base_scale() -> float:
	return _base_scale

## Scala da applicare quando il cubo è in mano o nell'anteprima: mantiene
## l'eventuale allungamento verticale dei funghi.
func shape_scale(extra: float = 1.0) -> Vector3:
	return _shape * extra
