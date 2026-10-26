class_name PuzzleEval
extends RefCounted
## Valutatore puro delle missioni.
## Riceve i dati della missione e la disposizione dei cubi negli incastri.
## Non tocca la scena: così le 100 missioni sono verificabili anche dai test.

const OK := "ok"
const WRONG := "wrong"
const EMPTY := "empty"
const FIXED := "fixed"

## placements: { socket_id: cube_id | [cube_id, ...] }
static func evaluate(mission: Dictionary, placements: Dictionary) -> Dictionary:
	var cubes := _cube_map(mission)
	var sockets: Array = mission.get("sockets", [])
	var socket_states := {}
	var wrong: Array[String] = []
	var required: Array[String] = []
	var total_required := 0
	var total_ok := 0

	for socket in sockets:
		if not (socket is Dictionary):
			continue
		var sid := str(socket.get("id", ""))
		var placed := _cube_ids(placements.get(sid, []))
		if socket.has("fixed"):
			if placed.is_empty():
				socket_states[sid] = FIXED
			else:
				socket_states[sid] = WRONG
				wrong.append(sid)
			continue
		required.append(sid)
		var is_group: bool = str(socket.get("group", "")) != ""
		if not is_group:
			total_required += 1
		var check := _check_socket(socket, placed, cubes, is_group)
		socket_states[sid] = check["state"]
		if check["state"] == OK:
			if not is_group:
				total_ok += 1
		else:
			if check["state"] == WRONG:
				wrong.append(sid)

	# Gruppi: quantità attese per nome di gruppo.
	var group_result := _check_groups(mission, sockets, placements, cubes)
	if not group_result["ok"]:
		for sid in group_result["bad_sockets"]:
			if socket_states.get(sid, "") == OK:
				socket_states[sid] = WRONG
			if not wrong.has(sid):
				wrong.append(sid)
	for sid in group_result.get("good_sockets", []):
		if socket_states.get(sid, "") == EMPTY:
			socket_states[sid] = OK

	# Percorso: qualunque sequenza ortogonale valida che arriva alla meta.
	var route_result := {"present": false, "ok": false, "message": ""}
	if mission.has("route"):
		route_result = _check_route(mission["route"], sockets, placements, cubes)
		if route_result["ok"]:
			for sid in mission["route"].get("sockets", []):
				socket_states[sid] = OK
		if not route_result["ok"]:
			for sid in mission["route"].get("sockets", []):
				if socket_states.get(sid, "") != WRONG:
					socket_states[sid] = WRONG
				if not wrong.has(sid):
					wrong.append(sid)

	var filled_required := 0
	for sid in required:
		if socket_states.get(sid, "") == OK:
			filled_required += 1

	var complete := wrong.is_empty()
	for socket in sockets:
		if not (socket is Dictionary):
			continue
		if socket.has("fixed"):
			continue
		var sid := str(socket.get("id", ""))
		var st := str(socket_states.get(sid, EMPTY))
		if st != OK and not (route_result["present"] and route_result["ok"]):
			complete = false
	if route_result["present"] and not route_result["ok"]:
		complete = false
	if mission.has("groups") and not group_result["ok"]:
		complete = false

	# Sottocompiti: ogni gruppo dichiarato deve essere completo.
	var subs := {}
	var subs_done := 0
	var subs_total := 0
	if mission.has("subs"):
		for sub_name in mission["subs"].keys():
			subs_total += 1
			var ok := true
			for sid in mission["subs"][sub_name]:
				if socket_states.get(sid, "") != OK and socket_states.get(sid, "") != FIXED:
					ok = false
			subs[sub_name] = ok
			if ok:
				subs_done += 1
		if subs_done < subs_total:
			complete = false

	return {
		"complete": complete,
		"sockets": socket_states,
		"subs": subs,
		"subs_done": subs_done,
		"subs_total": subs_total,
		"wrong_sockets": wrong,
		"required": required.size(),
		"filled": filled_required,
		"total_required": total_required,
		"total_ok": total_ok,
		"groups_ok": group_result["ok"],
		"route": route_result,
	}

## Analizza un singolo incastro.
static func _check_socket(socket: Dictionary, placed: Array, cubes: Dictionary, is_group: bool) -> Dictionary:
	if placed.is_empty():
		return {"state": EMPTY}
	var accepts: Array = socket.get("accepts", [])
	if accepts.is_empty():
		return {"state": EMPTY}
	if not is_group and placed.size() > 1:
		return {"state": WRONG}
	for cid in placed:
		if not cubes.has(cid):
			return {"state": WRONG}
		var value := str(cubes[cid].get("value", cid))
		if not accepts.has(value):
			return {"state": WRONG}
	return {"state": OK}

## Verifica i gruppi dichiarati in mission["groups"].
static func _check_groups(mission: Dictionary, sockets: Array, placements: Dictionary, cubes: Dictionary) -> Dictionary:
	if not mission.has("groups"):
		return {"ok": true, "bad_sockets": [], "good_sockets": []}
	var expected: Dictionary = mission["groups"]
	var actual := {}
	for group_name in expected.keys():
		actual[group_name] = {}
	var all_sockets := {}
	for socket in sockets:
		if not (socket is Dictionary):
			continue
		var gname := str(socket.get("group", ""))
		if gname == "" or not expected.has(gname):
			continue
		all_sockets[gname] = all_sockets.get(gname, [])
		all_sockets[gname].append(str(socket.get("id", "")))
		for cid in _cube_ids(placements.get(socket.get("id", ""), [])):
			if not cubes.has(cid):
				continue
			var v := str(cubes[cid].get("value", cid))
			actual[gname][v] = int(actual[gname].get(v, 0)) + 1
	var ok := true
	var bad: Array[String] = []
	var good: Array[String] = []
	for gname in expected.keys():
		var exp: Dictionary = expected[gname]
		var act: Dictionary = actual.get(gname, {})
		var same := true
		for v in exp.keys():
			if int(act.get(v, 0)) != int(exp[v]):
				same = false
		for v in act.keys():
			if not exp.has(v) and int(act.get(v, 0)) > 0:
				same = false
		if not same:
			ok = false
			for sid in all_sockets.get(gname, []):
				bad.append(sid)
		else:
			for sid in all_sockets.get(gname, []):
				good.append(sid)
	return {"ok": ok, "bad_sockets": bad, "good_sockets": good}

## Simulazione del percorso su griglia. Coordinate [x, y] con y=0 in alto.
static func _check_route(route: Dictionary, sockets: Array, placements: Dictionary, cubes: Dictionary) -> Dictionary:
	var size := int(route.get("size", 3))
	var start := _vec2i(route.get("start", [0, 0]))
	var goal := _vec2i(route.get("goal", [size - 1, size - 1]))
	var blocked := {}
	for b in route.get("blocked", []):
		blocked[_vec2i(b)] = true
	var step_ids: Array = route.get("sockets", [])
	var pos := start
	var moves := 0
	for sid in step_ids:
		var ids := _cube_ids(placements.get(sid, []))
		if ids.is_empty():
			return {"present": true, "ok": false, "message": "Manca un passo."}
		var cube: Dictionary = cubes.get(ids[0], {})
		if cube.is_empty():
			return {"present": true, "ok": false, "message": "Passo non valido."}
		var value := str(cube.get("value", "")).to_upper()
		var delta := _move_delta(value)
		if delta == Vector2i.ZERO:
			return {"present": true, "ok": false, "message": "Istruzione sconosciuta."}
		pos += delta
		moves += 1
		if pos.x < 0 or pos.y < 0 or pos.x >= size or pos.y >= size:
			return {"present": true, "ok": false, "message": "La luce esce dalla griglia."}
		if blocked.has(pos):
			return {"present": true, "ok": false, "message": "La luce incontra un ostacolo."}
	if pos != goal:
		return {"present": true, "ok": false, "message": "La luce non è arrivata alla meta."}
	return {"present": true, "ok": moves == step_ids.size(), "message": "Percorso completato."}

static func _move_delta(value: String) -> Vector2i:
	match value:
		"SU", "UP", "ALTO": return Vector2i(0, -1)
		"GIÙ", "GIU", "DOWN", "BASSO": return Vector2i(0, 1)
		"SINISTRA", "LEFT": return Vector2i(-1, 0)
		"DESTRA", "RIGHT": return Vector2i(1, 0)
	return Vector2i.ZERO

static func _vec2i(a: Variant) -> Vector2i:
	if a is Array and a.size() >= 2:
		return Vector2i(int(a[0]), int(a[1]))
	if a is Vector2i:
		return a
	return Vector2i.ZERO

static func _cube_map(mission: Dictionary) -> Dictionary:
	var out := {}
	for c in mission.get("cubes", []):
		if c is Dictionary:
			out[str(c.get("id", ""))] = c
	return out

static func _cube_ids(v: Variant) -> Array:
	if v == null:
		return []
	if v is Array:
		return v.duplicate()
	if str(v) == "":
		return []
	return [v]

## Controllo strutturale del catalogo: usato dai test.
static func validate_mission_data(missions: Array) -> Array[String]:
	var errors: Array[String] = []
	var seen := {}
	for m in missions:
		if not (m is Dictionary):
			errors.append("Missione non valida (non è un dizionario).")
			continue
		var id := str(m.get("id", ""))
		if id == "":
			errors.append("Missione senza id.")
			continue
		if seen.has(id):
			errors.append("ID duplicato: " + id)
		seen[id] = true
		for k in ["region", "title", "objective", "instruction", "kind", "cubes", "sockets", "hints", "success"]:
			if not m.has(k):
				errors.append("%s: campo mancante %s" % [id, k])
		if not (m.get("cubes") is Array) or (m.get("cubes") as Array).is_empty():
			errors.append("%s: nessun cubo." % id)
		if not (m.get("sockets") is Array) or (m.get("sockets") as Array).is_empty():
			errors.append("%s: nessun incastro." % id)
		if not (m.get("hints") is Array):
			errors.append("%s: aiuti non validi." % id)
		else:
			var hints: Array = m["hints"]
			if hints.size() < 3:
				errors.append("%s: servono tre aiuti." % id)
		var cube_ids := {}
		for c in m.get("cubes", []):
			if c is Dictionary:
				var cid := str(c.get("id", ""))
				if cid == "":
					errors.append("%s: cubo senza id." % id)
				elif cube_ids.has(cid):
					errors.append("%s: cubo duplicato %s." % [id, cid])
				cube_ids[cid] = true
		var socket_ids := {}
		for s in m.get("sockets", []):
			if s is Dictionary:
				var sid := str(s.get("id", ""))
				if sid == "":
					errors.append("%s: incastro senza id." % id)
				elif socket_ids.has(sid):
					errors.append("%s: incastro duplicato %s." % [id, sid])
				socket_ids[sid] = true
		if m.get("subs") is Dictionary:
			for sub in m["subs"].keys():
				for sid in m["subs"][sub]:
					if not socket_ids.has(str(sid)):
						errors.append("%s: sottocompito %s cita incastro inesistente %s" % [id, sub, sid])
		if m.get("route") is Dictionary:
			var route: Dictionary = m["route"]
			for sid in route.get("sockets", []):
				if not socket_ids.has(str(sid)):
					errors.append("%s: percorso cita incastro inesistente %s" % [id, sid])
	return errors

## Soluzione completa derivata dai vincoli: usata dai test e dalla modalità dimostrativa.
## Restituisce { socket_id: cube_id | [cube_id, ...] }.
static func solve(mission: Dictionary) -> Dictionary:
	var placements := {}
	var used := {}
	var cubes: Array = mission.get("cubes", [])
	var sockets: Array = mission.get("sockets", [])
	var groups: Dictionary = mission.get("groups", {})

	if mission.get("route") is Dictionary:
		var route: Dictionary = mission["route"]
		var solution: Array = route.get("solution", [])
		var step_ids: Array = route.get("sockets", [])
		for i in range(mini(solution.size(), step_ids.size())):
			var want := str(solution[i]).to_upper()
			for c in cubes:
				if not (c is Dictionary):
					continue
				var cid := str(c.get("id", ""))
				if used.has(cid):
					continue
				if str(c.get("value", "")).to_upper() == want:
					placements[str(step_ids[i])] = cid
					used[cid] = true
					break

	if not groups.is_empty():
		for gname in groups.keys():
			var pending: Array = []
			for c in cubes:
				if not (c is Dictionary):
					continue
				var cid := str(c.get("id", ""))
				if used.has(cid):
					continue
				if groups[gname].has(str(c.get("value", ""))):
					pending.append(cid)
			for s in sockets:
				if not (s is Dictionary) or str(s.get("group", "")) != str(gname):
					continue
				var cap := int(s.get("capacity", 1))
				var take: Array = []
				while pending.size() > 0 and take.size() < cap:
					var cid2: String = pending.pop_front()
					take.append(cid2)
				if not take.is_empty():
					placements[str(s.get("id", ""))] = take if take.size() > 1 else take[0]
					for cid3 in take:
						used[cid3] = true

	for s in sockets:
		if not (s is Dictionary) or s.has("fixed"):
			continue
		if placements.has(str(s.get("id", ""))):
			continue
		var accepts: Array = s.get("accepts", [])
		if accepts.is_empty():
			continue
		var cap := int(s.get("capacity", 1))
		var take: Array = []
		for c in cubes:
			if take.size() >= cap:
				break
			if not (c is Dictionary):
				continue
			var cid := str(c.get("id", ""))
			if used.has(cid):
				continue
			if accepts.has(str(c.get("value", ""))):
				take.append(cid)
				used[cid] = true
		if not take.is_empty():
			placements[str(s.get("id", ""))] = take if take.size() > 1 else take[0]
	return placements

## Soluzione leggibile per il pannello docente (primo incastro valido per ogni sede).
static func solution_hint(mission: Dictionary) -> String:
	var parts: Array[String] = []
	for socket in mission.get("sockets", []):
		if not (socket is Dictionary):
			continue
		if socket.has("fixed"):
			continue
		var accepts: Array = socket.get("accepts", [])
		if accepts.is_empty():
			continue
		parts.append("%s → %s" % [socket.get("id", "?"), accepts[0]])
	return ", ".join(parts)
