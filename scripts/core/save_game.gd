extends Node
## Salvataggio locale, versione e import/export.
## Nessun account, nessun dato personale, nessuna rete.

signal progress_changed
signal mission_completed(id: String)

const PATH := "user://lumeria_save.json"
const SCHEMA := 2

const BODIES := ["Rotondo", "Snello", "Alto"]
const BODY_COLORS := [
	Color("#F2B28C"), Color("#E7A06D"), Color("#C98A5B"), Color("#8D5A3B"),
	Color("#F5D6B5"), Color("#B8D8A8"), Color("#A8C8E8"), Color("#E7B8D8"),
]
const HATS := ["Nessuno", "Cappello a punta", "Berretto", "Corona di foglie"]
const HAT_COLORS := [Color("#5EC8B0"), Color("#F2A65A"), Color("#8E7CC3"), Color("#E9748A"), Color("#F5D76E")]
const OUTFIT_COLORS := [
	Color("#4FB3A9"), Color("#E9748A"), Color("#F2A65A"), Color("#7E8CD6"),
	Color("#8CCB7A"), Color("#F5D76E"), Color("#B58CD6"), Color("#5FA8D3"),
]

var data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()

func _default_data() -> Dictionary:
	return {
		"schemaVersion": SCHEMA,
		"localProfileId": _new_id(),
		"createdAt": Time.get_datetime_string_from_system(),
		"updatedAt": Time.get_datetime_string_from_system(),
		"appearance": {"body": 0, "body_color": 0, "outfit_color": 0, "hat": 1, "hat_color": 1},
		"missionStates": {},
		"collectibles": {"fireflies": [], "critters": [], "stones": []},
		"lastSafeSpawn": [0.0, 0.0, 12.0],
		"lastRegion": 0,
		"tutorial_done": false,
		"playSeconds": 0.0,
		"labBuilt": false,
		"finale_visto": false,
	}

func _new_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()

func _load() -> void:
	data = _default_data()
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_merge(parsed)
	_fix_lists()

func _merge(src: Dictionary) -> void:
	for k in ["localProfileId", "createdAt", "appearance", "missionStates", "collectibles",
			"lastSafeSpawn", "lastRegion", "tutorial_done", "playSeconds", "labBuilt", "finale_visto"]:
		if src.has(k):
			data[k] = src[k]
	if src.has("schemaVersion"):
		data["schemaVersion"] = SCHEMA
	if not (data["appearance"] is Dictionary):
		data["appearance"] = _default_data()["appearance"]
	if not (data["missionStates"] is Dictionary):
		data["missionStates"] = {}
	if not (data["collectibles"] is Dictionary):
		data["collectibles"] = {"fireflies": [], "critters": [], "stones": []}
	if not (data["lastSafeSpawn"] is Array) or data["lastSafeSpawn"].size() < 3:
		data["lastSafeSpawn"] = [0.0, 0.0, 12.0]

func _fix_lists() -> void:
	for kind in ["fireflies", "critters", "stones"]:
		if not (data["collectibles"].get(kind) is Array):
			data["collectibles"][kind] = []

func save_now() -> void:
	data["updatedAt"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func has_progress() -> bool:
	return completed_count() > 0 or bool(data.get("tutorial_done", false))

func completed_count() -> int:
	var n := 0
	for id in data["missionStates"].keys():
		if bool(data["missionStates"][id].get("completed", false)):
			n += 1
	return n

func completed_in_region(region: int) -> int:
	var n := 0
	for i in range((region - 1) * 10 + 1, region * 10 + 1):
		if is_mission_completed("%03d" % i):
			n += 1
	return n

func is_mission_completed(id: String) -> bool:
	var st: Dictionary = data["missionStates"].get(id, {})
	return bool(st.get("completed", false))

func mission_state(id: String) -> Dictionary:
	if not data["missionStates"].has(id):
		data["missionStates"][id] = {"completed": false, "attempts": 0, "hints": 0}
	return data["missionStates"][id]

func mark_mission_started(id: String) -> void:
	var st := mission_state(id)
	st["attempts"] = int(st.get("attempts", 0)) + 1
	st["lastPlayed"] = Time.get_datetime_string_from_system()
	save_now()

func mark_mission_completed(id: String, hints_used: int = 0) -> void:
	var st := mission_state(id)
	var first := not bool(st.get("completed", false))
	st["completed"] = true
	st["completedAt"] = Time.get_datetime_string_from_system()
	st["hints"] = int(st.get("hints", 0)) + hints_used
	if first:
		mission_completed.emit(id)
	progress_changed.emit()
	save_now()

func add_hint(id: String) -> void:
	var st := mission_state(id)
	st["hints"] = int(st.get("hints", 0)) + 1
	save_now()

func set_checkpoint(pos: Vector3, region: int = 0) -> void:
	data["lastSafeSpawn"] = [pos.x, pos.y, pos.z]
	if region > 0:
		data["lastRegion"] = region
	save_now()

func last_safe_spawn() -> Vector3:
	var a: Array = data["lastSafeSpawn"]
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func set_appearance(app: Dictionary) -> void:
	data["appearance"] = app
	save_now()

func appearance() -> Dictionary:
	return data["appearance"]

func register_collectible(kind: String, id: String) -> bool:
	_fix_lists()
	var arr: Array = data["collectibles"][kind]
	if arr.has(id):
		return false
	arr.append(id)
	save_now()
	return true

func has_collectible(kind: String, id: String) -> bool:
	_fix_lists()
	return data["collectibles"][kind].has(id)

func collectible_count(kind: String) -> int:
	_fix_lists()
	return data["collectibles"][kind].size()

func unlock_all() -> void:
	# Le regioni sono già tutte esplorabili; questa funzione prepara la modalità docente.
	data["allUnlocked"] = true
	save_now()

func reset_progress(keep_appearance: bool = true) -> void:
	var app: Dictionary = data["appearance"]
	var old_id: String = data["localProfileId"]
	data = _default_data()
	if keep_appearance:
		data["appearance"] = app
	data["localProfileId"] = old_id
	save_now()
	progress_changed.emit()

func export_to(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true

func import_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return false
	var merged := _default_data()
	data = merged
	_merge(parsed)
	_fix_lists()
	save_now()
	progress_changed.emit()
	return true

func summary_text() -> String:
	var lines: Array[String] = []
	lines.append("LUMERIA — riepilogo locale")
	lines.append("Profilo anonimo: %s" % str(data.get("localProfileId", "—")))
	lines.append("Pietre magiche accese: %d / 100" % completed_count())
	lines.append("Lucciole incontrate: %d" % collectible_count("fireflies"))
	lines.append("Creature accarezzate: %d" % collectible_count("critters"))
	lines.append("Pietre musicali: %d" % collectible_count("stones"))
	lines.append("")
	lines.append("Osservazioni di gioco (nessun giudizio):")
	for region in range(1, 11):
		var done := completed_in_region(region)
		lines.append("  Regione %02d: %d/10 missioni · %d tentativi · %d aiuti" % [
			region, done, _attempts_in_region(region), _hints_in_region(region)
		])
	lines.append("")
	lines.append("Dati privati, salvati solo su questo dispositivo.")
	return "\n".join(lines)

func _attempts_in_region(region: int) -> int:
	var n := 0
	for i in range((region - 1) * 10 + 1, region * 10 + 1):
		n += int(mission_state("%03d" % i).get("attempts", 0))
	return n

func _hints_in_region(region: int) -> int:
	var n := 0
	for i in range((region - 1) * 10 + 1, region * 10 + 1):
		n += int(mission_state("%03d" % i).get("hints", 0))
	return n

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_now()
