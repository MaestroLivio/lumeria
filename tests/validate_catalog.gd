extends SceneTree
const MissionDataScript = preload("res://scripts/data/mission_data.gd")
const PuzzleEvalScript = preload("res://scripts/missions/puzzle_eval.gd")
## Test headless del catalogo e del valutatore. Nessuna scena necessaria.

var failures: Array[String] = []

func _init() -> void:
	var missions: Array = MissionDataScript.all()
	print("Missioni caricate: %d" % missions.size())
	if missions.size() != 100:
		failures.append("Attese 100 missioni, trovate %d" % missions.size())
	var ids := {}
	for m in missions:
		ids[str(m.get("id", ""))] = true
	for i in range(1, 101):
		var id := "%03d" % i
		if not ids.has(id):
			failures.append("Manca la missione " + id)
	var structure := PuzzleEvalScript.validate_mission_data(missions)
	failures.append_array(structure)

	var solved := 0
	for m in missions:
		var placements := _solve(m)
		var result := PuzzleEvalScript.evaluate(m, placements)
		if not result["complete"]:
			failures.append("%s (%s): soluzione non accettata · %s" % [
				m.get("id", "?"), m.get("title", "?"), str(result)])
		else:
			solved += 1
	print("Missioni risolte dal validatore: %d / 100" % solved)

	# Verifica che una disposizione incompleta non sia accettata.
	var empty_ok := 0
	for m in missions:
		if PuzzleEvalScript.evaluate(m, {})["complete"]:
			empty_ok += 1
	if empty_ok > 0:
		failures.append("%d missioni risultano complete senza cubi." % empty_ok)

	if failures.is_empty():
		print("TEST OK: catalogo, struttura e validatore.")
		quit(0)
	else:
		print("TEST FALLITI: %d" % failures.size())
		for f in failures:
			print(" - " + f)
		quit(1)

func _solve(m: Dictionary) -> Dictionary:
	var placements := {}
	var used := {}
	var cubes: Array = m.get("cubes", [])
	var sockets: Array = m.get("sockets", [])
	var groups: Dictionary = m.get("groups", {})

	# Percorso: usa la soluzione dichiarata, cubo per valore.
	if m.get("route") is Dictionary:
		var route: Dictionary = m["route"]
		var solution: Array = route.get("solution", [])
		var step_ids: Array = route.get("sockets", [])
		for i in range(mini(solution.size(), step_ids.size())):
			var want := str(solution[i]).to_upper()
			for c in cubes:
				var cid := str(c.get("id", ""))
				if used.has(cid):
					continue
				if str(c.get("value", "")).to_upper() == want:
					placements[step_ids[i]] = cid
					used[cid] = true
					break

	# Gruppi con quantità esatte.
	if not groups.is_empty():
		for gname in groups.keys():
			var pending: Array = []
			for c in cubes:
				var cid := str(c.get("id", ""))
				if used.has(cid):
					continue
				if groups[gname].has(str(c.get("value", ""))):
					pending.append(cid)
			for s in sockets:
				if not (s is Dictionary) or str(s.get("group", "")) != gname:
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

	# Incastri normali: primo cubo compatibile non ancora usato.
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
			var cid := str(c.get("id", ""))
			if used.has(cid):
				continue
			if accepts.has(str(c.get("value", ""))):
				take.append(cid)
				used[cid] = true
		if not take.is_empty():
			placements[str(s.get("id", ""))] = take if take.size() > 1 else take[0]
	return placements
