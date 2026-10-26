class_name MeshHelpers
extends RefCounted
## Costruzione di primitive 3D con materiali condivisi.
## Tutto è generato a runtime: nessun modello esterno.

static var _materials: Dictionary = {}
## Materiali con emissione: lo slider del bagliore li aggiorna tutti insieme,
## anche quelli già applicati alla scena.
static var _glow_materials: Array[Dictionary] = []
static var _glow_scale := 1.0

## 0 = nessun bagliore, 1 = intensità piena, 1.5 = massimo dello slider.
static func set_glow_scale(value: float) -> void:
	_glow_scale = clampf(value, 0.0, 1.5)
	for entry in _glow_materials:
		var mat: StandardMaterial3D = entry.get("mat", null)
		if mat != null and is_instance_valid(mat):
			mat.emission_energy_multiplier = float(entry.get("base", 0.0)) * _glow_scale

static func glow_scale() -> float:
	return _glow_scale

static func material(color: Color, emission: Color = Color(0, 0, 0), emission_energy: float = 0.0,
		roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%.2f|%.2f" % [color.to_html(), emission.to_html(), emission_energy, roughness, metallic]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	# I colori scritti come hex sono sRGB: il pipeline 3D lavora in lineare.
	# Senza questa conversione tutto apparirebbe slavato e biancastro.
	m.albedo_color = color.srgb_to_linear()
	m.roughness = roughness
	m.metallic = metallic
	if emission_energy > 0.0 and emission.a > 0.0:
		m.emission_enabled = true
		m.emission = emission.srgb_to_linear()
		m.emission_energy_multiplier = emission_energy * _glow_scale
		_glow_materials.append({"mat": m, "base": emission_energy})
	_materials[key] = m
	return m

static func box(parent: Node3D, size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO,
		rot: Vector3 = Vector3.ZERO, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, color, pos, rot, emission, energy)

static func sphere(parent: Node3D, radius: float, color: Color, pos: Vector3 = Vector3.ZERO,
		emission: Color = Color(0, 0, 0), energy: float = 0.0, segments: int = 20) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(6, segments / 2)
	return _add(parent, mesh, color, pos, Vector3.ZERO, emission, energy)

static func cylinder(parent: Node3D, top_r: float, bottom_r: float, height: float, color: Color,
		pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, emission: Color = Color(0, 0, 0),
		energy: float = 0.0, segments: int = 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 2
	return _add(parent, mesh, color, pos, rot, emission, energy)

static func capsule(parent: Node3D, radius: float, height: float, color: Color,
		pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 6
	return _add(parent, mesh, color, pos, rot)

static func torus(parent: Node3D, inner: float, outer: float, color: Color,
		pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, emission: Color = Color(0, 0, 0),
		energy: float = 0.0) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 12
	return _add(parent, mesh, color, pos, rot, emission, energy)

static func prism(parent: Node3D, size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	return _add(parent, mesh, color, pos, rot)

static func label(parent: Node3D, text: String, size: int, color: Color, pos: Vector3,
		font_size: int = 48, billboard: bool = true, rot: Vector3 = Vector3.ZERO) -> Label3D:
	var l := Label3D.new()
	l.text = text
	# Font di sistema + Label3D: su alcune build l'atlante condiviso mostra lo
	# stesso testo su tutte le etichette. Il font predefinito di Godot è stabile.
	l.font_size = size
	l.outline_size = maxi(6, size / 8)
	l.outline_modulate = Color(0.08, 0.07, 0.1, 0.85)
	l.modulate = color
	l.position = pos
	l.rotation = rot
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.render_priority = 2
	l.pixel_size = 0.0042
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(l)
	return l

static func icon(parent: Node3D, icon_name: String, color: Color, size: float, pos: Vector3,
		billboard: bool = true, rot: Vector3 = Vector3.ZERO) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = IconLibrary.texture(icon_name, color)
	# La texture è renderizzata a 256 px: il parametro size è la larghezza reale.
	var tex_w := 128.0
	if s.texture:
		tex_w = maxf(1.0, float(s.texture.get_width()))
	s.pixel_size = size / tex_w
	s.position = pos
	s.rotation = rot
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.no_depth_test = false
	s.render_priority = 2
	parent.add_child(s)
	return s

static func _add(parent: Node3D, mesh: PrimitiveMesh, color: Color, pos: Vector3, rot: Vector3,
		emission: Color = Color(0, 0, 0), energy: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color, emission, energy)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func clear_materials() -> void:
	_materials.clear()
