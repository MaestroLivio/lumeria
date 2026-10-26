class_name AvatarBuilder
extends RefCounted
## Avatar stilizzato a proporzioni infantili, senza stereotipi.
## Riutilizzato dal giocatore e dall'anteprima del guardaroba.
##
## Convenzione di orientamento: l'avatar guarda verso -Z (forward di Godot).
## Tutti i tratti del viso, le punte dei piedi e la visiera del berretto stanno
## quindi su z negativa. Il giocatore ruota il nodo per allineare -Z alla
## direzione di marcia, mentre l'anteprima del guardaroba lo ruota di PI per
## mostrarlo in faccia.

const EYE := Color("#3B2A20")

static func build(appearance: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Avatar"
	var body_idx: int = clampi(int(appearance.get("body", 0)), 0, 2)
	var skin: Color = SaveGame.BODY_COLORS[clampi(int(appearance.get("body_color", 0)), 0, SaveGame.BODY_COLORS.size() - 1)]
	var outfit: Color = SaveGame.OUTFIT_COLORS[clampi(int(appearance.get("outfit_color", 0)), 0, SaveGame.OUTFIT_COLORS.size() - 1)]
	var hat_idx: int = clampi(int(appearance.get("hat", 1)), 0, SaveGame.HATS.size() - 1)
	var hat_color: Color = SaveGame.HAT_COLORS[clampi(int(appearance.get("hat_color", 1)), 0, SaveGame.HAT_COLORS.size() - 1)]

	var scale_y: float = [1.0, 1.06, 1.14][body_idx]
	var width: float = [1.0, 0.9, 0.94][body_idx]
	root.scale = Vector3(width, scale_y, width)

	var hair: Color = skin.darkened(0.58)
	hair = hair.lerp(Color("#3B2A20"), 0.45)
	var shoe: Color = Color("#6B4B3A").lerp(outfit.darkened(0.55), 0.35)

	# ------------------------------------------------------------ gambe e piedi
	var legs := Node3D.new()
	legs.name = "Gambe"
	root.add_child(legs)
	for side in [-1.0, 1.0]:
		var leg := MeshHelpers.capsule(legs, 0.105, 0.46, outfit.darkened(0.3), Vector3(0.145 * side, 0.30, 0))
		leg.name = "GambaDestra" if side > 0.0 else "GambaSinistra"
		# scarpe arrotondate, punta verso -Z
		var boot := MeshHelpers.sphere(legs, 0.125, shoe, Vector3(0.145 * side, 0.075, -0.035))
		boot.scale = Vector3(1.0, 0.62, 1.42)

	# ------------------------------------------------------------ corpo e mantello
	var torso := Node3D.new()
	torso.name = "Corpo"
	root.add_child(torso)
	var tunic := MeshHelpers.capsule(torso, 0.31, 0.64, outfit, Vector3(0, 0.83, 0))
	tunic.name = "Tunica"
	# colletto chiaro e cintura
	MeshHelpers.torus(torso, 0.19, 0.27, outfit.lightened(0.2), Vector3(0, 1.05, 0))
	MeshHelpers.torus(torso, 0.29, 0.335, Color("#8A6242"), Vector3(0, 0.68, 0))
	# fibbia luminosa sul petto, verso -Z (davanti)
	MeshHelpers.sphere(torso, 0.045, Color("#F2C24B"), Vector3(0, 0.92, -0.305), Color("#F2C24B"), 0.9)
	MeshHelpers.torus(torso, 0.065, 0.085, Color("#FFF3B0"), Vector3(0, 0.92, -0.30),
		Vector3(PI / 2, 0, 0), Color("#FFF3B0"), 0.5)
	# zainetto sulla schiena (+Z): rende viva la vista da dietro
	var pack := Node3D.new()
	pack.name = "Zaino"
	torso.add_child(pack)
	var bag := MeshHelpers.sphere(pack, 0.20, Color("#C98A5B"), Vector3(0, 0.86, 0.27))
	bag.scale = Vector3(1.0, 1.08, 0.62)
	MeshHelpers.box(pack, Vector3(0.3, 0.1, 0.1), Color("#8A6242"), Vector3(0, 0.72, 0.30))
	MeshHelpers.box(pack, Vector3(0.24, 0.16, 0.06), Color("#F2E3C8"), Vector3(0, 0.93, 0.345))
	# coperta arrotolata sopra lo zaino
	var roll := MeshHelpers.cylinder(pack, 0.07, 0.07, 0.34, outfit.lightened(0.12),
		Vector3(0, 1.06, 0.27), Vector3(0, 0, PI / 2.0))
	roll.name = "Coperta"
	for side in [-1.0, 1.0]:
		MeshHelpers.box(pack, Vector3(0.055, 0.38, 0.05), Color("#8A6242"),
			Vector3(0.16 * side, 0.98, 0.13), Vector3(deg_to_rad(-12), 0, 0))
	# mantellina corta sulle spalle
	MeshHelpers.cylinder(torso, 0.30, 0.40, 0.20, outfit.darkened(0.12), Vector3(0, 1.10, 0), Vector3.ZERO,
		Color(0, 0, 0, 0), 0.0, 14)

	# ------------------------------------------------------------ braccia e mani
	var arms := Node3D.new()
	arms.name = "Braccia"
	root.add_child(arms)
	for side in [-1.0, 1.0]:
		var arm := MeshHelpers.capsule(arms, 0.092, 0.46, outfit.lightened(0.05),
			Vector3(0.37 * side * width, 0.85, 0))
		arm.name = "BraccioDestro" if side > 0.0 else "BraccioSinistro"
		arm.rotation.z = deg_to_rad(9.0 * side)
		MeshHelpers.sphere(arms, 0.10, skin, Vector3(0.405 * side * width, 0.60, -0.01))

	# ------------------------------------------------------------ testa e viso
	var head := Node3D.new()
	head.name = "Testa"
	root.add_child(head)
	var head_mesh := MeshHelpers.sphere(head, 0.315, skin, Vector3(0, 1.38, 0), Color(0, 0, 0, 0), 0.0, 24)
	head_mesh.name = "Viso"
	# orecchie
	for side in [-1.0, 1.0]:
		MeshHelpers.sphere(head, 0.075, skin.darkened(0.04), Vector3(0.305 * side, 1.36, 0.01))
	# capelli: calotta emisferica + massa posteriore (visibile camminando)
	var cap := MeshHelpers.sphere(head, 0.332, hair, Vector3(0, 1.43, 0.015), Color(0, 0, 0, 0), 0.0, 22)
	var cap_mesh := cap.mesh as SphereMesh
	cap_mesh.is_hemisphere = true
	cap_mesh.height = 0.32
	var back_hair := MeshHelpers.sphere(head, 0.30, hair, Vector3(0, 1.37, 0.11))
	back_hair.scale = Vector3(1.0, 1.0, 0.70)
	# ciuffi sulla fronte (sopra gli occhi, verso -Z)
	MeshHelpers.sphere(head, 0.095, hair, Vector3(-0.14, 1.62, -0.15))
	MeshHelpers.sphere(head, 0.08, hair, Vector3(0.12, 1.64, -0.13))
	# guance
	for side in [-1.0, 1.0]:
		var cheek := MeshHelpers.sphere(head, 0.062, Color("#F08C7A"), Vector3(0.185 * side, 1.30, -0.225))
		cheek.transparency = 0.25
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# occhi grandi e sorridenti, davanti (-Z): sclera chiara e pupilla scura
	for side in [-1.0, 1.0]:
		var sclera := MeshHelpers.sphere(head, 0.055, Color("#FFF9F0"), Vector3(0.112 * side, 1.402, -0.279))
		sclera.scale = Vector3(0.9, 1.08, 0.5)
		var pupil := MeshHelpers.sphere(head, 0.034, EYE, Vector3(0.110 * side, 1.398, -0.301))
		pupil.scale = Vector3(0.9, 1.0, 0.5)
		MeshHelpers.sphere(head, 0.011, Color.WHITE, Vector3(0.121 * side, 1.412, -0.316))
	# sopracciglia
	for side in [-1.0, 1.0]:
		MeshHelpers.box(head, Vector3(0.085, 0.018, 0.012), hair.darkened(0.15),
			Vector3(0.112 * side, 1.475, -0.278), Vector3(0, 0, deg_to_rad(-6.0 * side)))
	# nasino
	MeshHelpers.sphere(head, 0.03, skin.darkened(0.03), Vector3(0, 1.34, -0.309))
	# bocca: cinque pallini disposti ad arco, un sorriso senza denti
	for i in range(5):
		var t := float(i) / 4.0 * 2.0 - 1.0
		var mx := t * 0.058
		var my := 1.283 - (1.0 - t * t) * 0.018
		var mouth := MeshHelpers.sphere(head, 0.0155, Color("#A8564E"),
			Vector3(mx, my, -0.302 + absf(t) * 0.008))
		mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# ------------------------------------------------------------ cappello
	var hat := Node3D.new()
	hat.name = "Cappello"
	root.add_child(hat)
	match hat_idx:
		0:
			# nessun cappello: un ciuffo ribelle
			MeshHelpers.sphere(hat, 0.075, hair, Vector3(0, 1.70, -0.03))
		1:
			# cappello a punta con falda e stellina
			MeshHelpers.cylinder(hat, 0.02, 0.33, 0.46, hat_color, Vector3(0, 1.90, 0), Vector3.ZERO,
				Color(0, 0, 0, 0), 0.0, 18)
			MeshHelpers.cylinder(hat, 0.39, 0.42, 0.06, hat_color.darkened(0.14), Vector3(0, 1.66, 0), Vector3.ZERO,
				Color(0, 0, 0, 0), 0.0, 22)
			MeshHelpers.torus(hat, 0.27, 0.31, hat_color.darkened(0.2), Vector3(0, 1.68, 0))
			MeshHelpers.sphere(hat, 0.055, Color("#FFF3B0"), Vector3(0, 2.16, 0), Color("#FFE066"), 2.2)
		2:
			# berretto con visiera verso -Z
			var dome := MeshHelpers.sphere(hat, 0.335, hat_color, Vector3(0, 1.45, 0.01), Color(0, 0, 0, 0), 0.0, 22)
			var dome_mesh := dome.mesh as SphereMesh
			dome_mesh.is_hemisphere = true
			dome_mesh.height = 0.26
			MeshHelpers.cylinder(hat, 0.34, 0.35, 0.05, hat_color.darkened(0.18), Vector3(0, 1.47, 0), Vector3.ZERO,
				Color(0, 0, 0, 0), 0.0, 22)
			var brim := MeshHelpers.box(hat, Vector3(0.46, 0.045, 0.30), hat_color.darkened(0.24),
				Vector3(0, 1.475, -0.33))
			brim.rotation.x = deg_to_rad(-7)
			MeshHelpers.sphere(hat, 0.045, hat_color.lightened(0.3), Vector3(0, 1.72, 0))
		_:
			# corona di foglie con bacche
			for i in range(9):
				var a := TAU * float(i) / 9.0
				var leaf := MeshHelpers.sphere(hat, 0.10, hat_color.darkened(float(i % 2) * 0.12),
					Vector3(cos(a) * 0.30, 1.60, sin(a) * 0.30))
				leaf.scale = Vector3(1.0, 0.7, 1.25)
			for i in range(4):
				var a2 := TAU * float(i) / 4.0 + 0.4
				MeshHelpers.sphere(hat, 0.045, Color("#FFF3B0"),
					Vector3(cos(a2) * 0.31, 1.68, sin(a2) * 0.31), Color("#FFE066"), 1.4)

	root.set_meta("body", body_idx)
	return root
