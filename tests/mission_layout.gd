extends SceneTree
## Diagnostica del tavolo delle missioni: apre tutte le missioni, le risolve e
## controlla che ogni cubo finisca dentro il proprio incastro, senza sovrapporsi
## ai vicini. Uso:
##   godot --headless --path . --script tests/mission_layout.gd [id]
## Stampa LAYOUT OK oppure l'elenco dei problemi trovati.

var _problems: Array[String] = []
var _only := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_only = args[0]
	_run()

func _run() -> void:
	await process_frame
	var missions: Array = MissionData.all()
	var checked := 0
	for m in missions:
		var id := str(m.get("id", ""))
		if _only != "" and id != _only:
			continue
		await _check_mission(m)
		checked += 1
	print("LAYOUT missioni=%d problemi=%d" % [checked, _problems.size()])
	for p in _problems:
		print(" - " + p)
	print("LAYOUT %s" % ("OK" if _problems.is_empty() else "FALLITO"))
	quit(0 if _problems.is_empty() else 1)

func _check_mission(m: Dictionary) -> void:
	var id := str(m.get("id", ""))
	var stage: Node3D = load("res://scripts/missions/mission_stage.gd").new()
	stage.set("quiet", true)
	stage.call("setup", m, false)
	root.add_child(stage)
	await process_frame
	await process_frame
	var ok: bool = stage.call("debug_solve")
	if not ok:
		_problems.append("%s: la soluzione automatica non è stata accettata" % id)
	var sockets: Dictionary = stage.get("_socket_nodes")
	var cubes: Dictionary = stage.get("_cube_nodes")
	var placements: Dictionary = stage.get("_placements")
	# 1. id duplicati tra gli incastri
	var seen := {}
	var dupes: Array[String] = []
	for key in sockets.keys():
		if seen.has(key):
			dupes.append(str(key))
		seen[key] = true
	if not dupes.is_empty():
		_problems.append("%s: id incastro duplicato %s" % [id, str(dupes)])
	# 2. ogni cubo collocato deve stare dentro il proprio incastro
	var placed: Array = []
	for key in placements.keys():
		var sock: Node3D = sockets.get(str(key), null)
		var ids: Array = placements[key]
		if sock == null:
			_problems.append("%s: incastro %s mancante" % [id, str(key)])
			continue
		var cap := int(sock.get("capacity"))
		if ids.size() > cap:
			_problems.append("%s/%s: %d cubi in un incastro da %d" % [id, key, ids.size(), cap])
		for i in range(ids.size()):
			var cube: Node3D = cubes.get(str(ids[i]), null)
			if cube == null:
				_problems.append("%s/%s: cubo %s mancante" % [id, key, str(ids[i])])
				continue
			if cube.get_parent() != sock:
				_problems.append("%s/%s: cubo %s non è figlio dell'incastro" % [id, key, str(cube.get("cube_id"))])
			placed.append({
				"sock": str(key), "id": str(cube.get("cube_id")), "pos": cube.position,
				"scale": cube.scale.x,
			})
	# 3. sovrapposizioni tra cubi collocati nello stesso incastro
	for a in range(placed.size()):
		for b in range(a + 1, placed.size()):
			var pa: Dictionary = placed[a]
			var pb: Dictionary = placed[b]
			if pa["sock"] != pb["sock"]:
				continue
			var ha := 0.43 * float(pa["scale"])
			var hb := 0.43 * float(pb["scale"])
			var dx := absf(float(pa["pos"].x) - float(pb["pos"].x))
			var dz := absf(float(pa["pos"].z) - float(pb["pos"].z))
			if dx < ha + hb - 0.02 and dz < ha + hb - 0.02:
				_problems.append("%s/%s: %s e %s si sovrappongono (dx=%.2f dz=%.2f)" % [
					id, pa["sock"], pa["id"], pb["id"], dx, dz])
	# 4. cubo fuori dalla piastra dell'incastro (lato 1.22)
	for p in placed:
		if absf(float(p["pos"].x)) > 0.5 or absf(float(p["pos"].z)) > 0.5:
			_problems.append("%s/%s: %s esce dalla piastra (%.2f, %.2f)" % [
				id, p["sock"], p["id"], float(p["pos"].x), float(p["pos"].z)])
	stage.queue_free()
	await process_frame
