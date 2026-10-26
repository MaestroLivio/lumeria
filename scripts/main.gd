class_name LumeriaMain
extends Node3D
## Orchestratore di Lumeria: mondo, avatar, camera, interfaccia, missioni e menu.

const ST_BOOT := "boot"
const ST_MENU := "menu"
const ST_PLAY := "play"
const ST_MISSION := "mission"
const ST_OVERLAY := "overlay"

var state := ST_BOOT
var world: LumeriaWorld
var player: LumeriaPlayer
var rig: CameraRig
var hud: LumeriaHud
var menu: MainMenu
var ui: CanvasLayer

var _menu_focus: Node3D
var _mission: MissionStage
var _overlay: Control
var _overlay_context := ""
var _region := -1
var _near_station: RegionStation = null
var _near_collectible: WorldCollectible = null
var _prompt_text := ""
var _save_clock := 0.0
var _visited: Dictionary = {}
var _started := false
var _welcome_done := false
var _pending_final := false
var _final_open := false
var _smoke := false
var _shots := false
var _selftest := false
var _quickshot := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	_smoke = args.has("--smoke")
	_shots = args.has("--shots")
	_selftest = args.has("--selftest")
	_quickshot = args.has("--quickshot")
	_build_world()
	_build_ui()
	Settings.quality_changed.connect(_on_quality_changed)
	_on_quality_changed(int(Settings.get_setting("quality", 1)))
	SaveGame.progress_changed.connect(_on_progress_changed)
	_enter_menu()
	if _shots:
		call_deferred("_run_shots")
	elif _quickshot:
		call_deferred("_run_quickshot")
	elif _selftest:
		call_deferred("_run_selftest")
	elif _smoke:
		call_deferred("_run_smoke")

# ---------------------------------------------------------------- costruzione
func _build_world() -> void:
	world = LumeriaWorld.new()
	world.name = "Mondo"
	add_child(world)
	world.build()

	player = LumeriaPlayer.new()
	player.name = "Giocatore"
	player.input_enabled = false
	add_child(player)
	var spawn := _spawn_position()
	player.global_position = spawn

	rig = CameraRig.new()
	rig.name = "Camera"
	add_child(rig)
	rig.set_target(player)
	rig.global_position = spawn + Vector3(0, 1.15, 0)
	rig.yaw = 0.35
	player.set_rig(rig)

	hud = LumeriaHud.new()
	hud.name = "HUD"
	add_child(hud)

	_menu_focus = Node3D.new()
	_menu_focus.name = "FuocoMenu"
	_menu_focus.position = Vector3(0, 0.5, 0)
	add_child(_menu_focus)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "Interfaccia"
	ui.layer = 20
	add_child(ui)
	menu = MainMenu.new()
	menu.name = "MenuPrincipale"
	ui.add_child(menu)
	menu.action.connect(_on_menu_action)

func _spawn_position() -> Vector3:
	var p := SaveGame.last_safe_spawn()
	if p.length() > 90.0 or p.y < -2.0 or p.y > 30.0:
		p = Vector3(0, 0.2, 12)
	p.y = maxf(p.y, 0.2)
	return p

## Le impostazioni video cambiano gli effetti anche a partita in corso.
func _on_quality_changed(level: int) -> void:
	if world:
		world.apply_quality(level)
	if _mission and is_instance_valid(_mission):
		_mission.apply_quality(level)

# ---------------------------------------------------------------- stati
func _enter_menu() -> void:
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	world.set_environment_active(true)
	state = ST_MENU
	menu.visible = true
	menu.open(SaveGame.has_progress())
	player.input_enabled = false
	rig.input_enabled = false
	rig.cinematic = true
	rig.target = _menu_focus
	rig.set_distance(16.0)
	rig.global_position = Vector3(0, 6.4, 0)
	hud.hide_hud()
	Audio.set_region(0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_play() -> void:
	menu.visible = false
	state = ST_PLAY
	if not _started:
		var spawn := _spawn_position()
		player.teleport(spawn)
		_started = true
	rig.cinematic = false
	rig.set_target(player)
	rig.set_distance(5.7)
	rig.global_position = player.global_position + Vector3(0, 1.15, 0)
	rig.input_enabled = true
	player.input_enabled = true
	rig.get_camera().current = true
	hud.show_hud()
	hud.set_progress()
	_region_update(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.start_music()
	if not _smoke and not bool(Settings.get_setting("tutorial_done", false)):
		_open_overlay(TutorialPage.new(), "play")
	elif not _welcome_done:
		_welcome_done = true
		Audio.say("Benvenuto a Lumeria. Segui le luci: ogni regione nasconde dieci pietre magiche.", true, 0.6)

func _freeze_world() -> void:
	player.input_enabled = false
	player.velocity = Vector3.ZERO
	rig.input_enabled = false
	hud.hide_hud()

func _resume_world() -> void:
	menu.visible = false
	state = ST_PLAY
	player.input_enabled = true
	rig.input_enabled = true
	rig.cinematic = false
	rig.target = player
	rig.set_distance(5.7)
	rig.global_position = player.global_position + Vector3(0, 1.15, 0)
	rig.get_camera().current = true
	hud.show_hud()
	hud.set_progress()
	hud.set_region(_region)
	_region_update(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ---------------------------------------------------------------- overlay
func _open_overlay(page: Control, context: String) -> void:
	if page == null:
		return
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = page
	_overlay_context = context
	if context == "menu":
		menu.visible = false
	elif context == "play":
		_freeze_world()
	elif context == "mission":
		if _mission and is_instance_valid(_mission):
			_mission.set_suspended(true)
	ui.add_child(page)
	if page.has_signal("closed"):
		page.closed.connect(_on_overlay_closed)
	_connect_page(page)
	state = ST_OVERLAY
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _connect_page(page: Control) -> void:
	if page.has_signal("action"):
		page.action.connect(_on_pause_action)
	if page.has_signal("travel"):
		page.travel.connect(_on_travel)
	if page.has_signal("selected"):
		page.selected.connect(_on_lab_selected)
	if page.has_signal("appearance_changed"):
		page.appearance_changed.connect(_on_appearance_changed)
	if page.has_signal("progress_changed"):
		page.progress_changed.connect(_on_progress_changed)
	if page.has_signal("teacher_requested"):
		page.teacher_requested.connect(_on_settings_teacher)
	if page.has_signal("tutorial_requested"):
		page.tutorial_requested.connect(_on_settings_tutorial)

func _close_overlay_silent() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null

func _on_overlay_closed() -> void:
	var ctx := _overlay_context
	if _overlay is FinalScene:
		_final_open = false
	_close_overlay_silent()
	if ctx == "menu":
		_enter_menu()
	elif ctx == "mission" and _mission and is_instance_valid(_mission):
		state = ST_MISSION
		_mission.set_suspended(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_resume_world()

func _on_settings_teacher() -> void:
	_open_overlay(TeacherPage.new(), _overlay_context)

func _on_settings_tutorial() -> void:
	_open_overlay(TutorialPage.new(), _overlay_context)

func _on_appearance_changed() -> void:
	if player and is_instance_valid(player):
		player.refresh_appearance()

func _on_progress_changed() -> void:
	if world:
		world.refresh_completed()
	if hud:
		hud.set_progress()
		hud.set_region(_region)

# ---------------------------------------------------------------- menu principale
func _on_menu_action(name: String) -> void:
	match name:
		"continue":
			_start_play()
		"new_game":
			SaveGame.reset_progress(true)
			_region = -1
			_visited.clear()
			_pending_final = false
			_final_open = false
			_started = false
			player.teleport(Vector3(0, 0.2, 12))
			SaveGame.set_checkpoint(Vector3(0, 0.2, 12), 0)
			world.refresh_completed()
			_start_play()
		"map":
			_open_overlay(MapPage.new(), "menu")
		"journal":
			_open_overlay(JournalPage.new(), "menu")
		"avatar":
			_open_overlay(AvatarPage.new(), "menu")
		"settings":
			_open_overlay(SettingsMenu.new(), "menu")
		"lab":
			_open_overlay(LabMenu.new(), "menu")
		"quit":
			_quit_game()

# ---------------------------------------------------------------- pausa
func _on_pause_action(name: String) -> void:
	if name == "resume":
		_on_overlay_closed()
		return
	var ctx := _overlay_context
	match name:
		"map":
			_open_overlay(MapPage.new(), ctx)
		"journal":
			_open_overlay(JournalPage.new(), ctx)
		"avatar":
			_open_overlay(AvatarPage.new(), ctx)
		"settings":
			_open_overlay(SettingsMenu.new(), ctx)
		"tutorial":
			_open_overlay(TutorialPage.new(), ctx)
		"teacher":
			_open_overlay(TeacherPage.new(), ctx)
		"lab":
			_open_overlay(LabMenu.new(), ctx)
		"main_menu":
			_go_to_menu()
		"quit":
			_quit_game()
		_:
			_on_overlay_closed()

func _go_to_menu() -> void:
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	_close_overlay_silent()
	SaveGame.set_checkpoint(player.global_position, _region)
	_enter_menu()

func _quit_game() -> void:
	SaveGame.set_checkpoint(player.global_position, _region)
	SaveGame.save_now()
	get_tree().quit()

# ---------------------------------------------------------------- viaggi
func _on_travel(region: int) -> void:
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	_close_overlay_silent()
	var pos := Vector3(0, 0.2, 12)
	var dir := Vector3(0, 0, -1)
	if region >= 1 and region <= world.region_centers.size():
		var center: Vector3 = world.region_centers[region - 1]
		# Arrivo laterale: evita il cartello della regione, che altrimenti
		# finirebbe tra la camera e l'avatar.
		var toward_hub := (Vector3.ZERO - center).normalized()
		var side := toward_hub.cross(Vector3.UP).normalized()
		pos = center + side * 7.0
		pos.y = 0.2
		dir = (center - pos).normalized()
	var yaw := atan2(-dir.x, -dir.z)
	player.teleport(pos)
	player.rotation.y = yaw
	rig.yaw = yaw
	rig.global_position = pos + Vector3(0, 1.15, 0)
	_started = true
	_region = -1
	Audio.play_sfx("teleport")
	_start_play()
	if region >= 1 and region <= 10:
		hud.toast("Viaggio verso %02d · %s" % [region, MissionData.REGION_NAMES[region - 1]], 2.6)
	else:
		hud.toast("Bentornato nel Hub di Lumeria", 2.6)
	SaveGame.set_checkpoint(pos, region)

func _on_lab_selected(mission_id: String) -> void:
	_close_overlay_silent()
	_started = true
	_open_mission(mission_id, true)

# ---------------------------------------------------------------- missioni
func _open_mission(mission_id: String, lab: bool = false, _station: RegionStation = null) -> void:
	var m := MissionData.by_id(mission_id)
	if m.is_empty():
		hud.toast("Questa missione non è disponibile.")
		return
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	menu.visible = false
	state = ST_MISSION
	hud.hide_hud()
	player.input_enabled = false
	player.velocity = Vector3.ZERO
	rig.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not lab:
		SaveGame.mark_mission_started(mission_id)
	var stage := MissionStage.new()
	stage.name = "Missione_%s" % mission_id
	stage.setup(m, lab)
	stage.completed.connect(_on_mission_completed)
	stage.next_requested.connect(_on_mission_next)
	stage.closed.connect(_on_mission_closed)
	stage.pause_requested.connect(_on_mission_pause)
	world.set_environment_active(false)
	add_child(stage)
	_mission = stage
	Audio.set_region(int(m.get("region", 0)))

func _on_mission_completed(m: Dictionary) -> void:
	var id := str(m.get("id", ""))
	SaveGame.mark_mission_completed(id)
	world.refresh_completed()
	hud.set_progress()
	hud.set_region(int(m.get("region", _region)))
	Audio.play_sfx("rune")
	Settings.rumble(0.55, 0.3)
	if SaveGame.completed_count() >= 100 and not bool(SaveGame.data.get("finale_visto", false)):
		_pending_final = true

func _on_mission_next(m: Dictionary) -> void:
	var next_index := int(str(m.get("id", "0"))) + 1
	if next_index >= 1 and next_index <= 100:
		if _mission and is_instance_valid(_mission):
			var old := _mission
			_mission = null
			old.queue_free()
		_open_mission("%03d" % next_index, false)
	else:
		_close_mission_to_world()

func _on_mission_closed() -> void:
	_close_mission_to_world()

func _on_mission_pause() -> void:
	_open_overlay(PausePage.new(), "mission")

func _close_mission_to_world() -> void:
	var run_final := _pending_final
	_pending_final = false
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	world.set_environment_active.call_deferred(true)
	state = ST_PLAY
	_resume_world()
	world.refresh_completed()
	hud.set_progress()
	if run_final:
		call_deferred("show_final_scene")

func _on_input_unused(_unused: Variant = null) -> void:
	pass

# ---------------------------------------------------------------- finale
func show_final_scene() -> void:
	if _final_open:
		return
	_final_open = true
	var ctx := "play"
	if _overlay:
		ctx = "menu" if _overlay_context == "menu" else "play"
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
	if _mission and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	SaveGame.data["finale_visto"] = true
	SaveGame.save_now()
	Audio.set_region(0)
	var page := FinalScene.new()
	_open_overlay(page, ctx)

func open_journal_from_final() -> void:
	_final_open = false
	var ctx := "play"
	if _overlay:
		ctx = "menu" if _overlay_context == "menu" else "play"
	_close_overlay_silent()
	_open_overlay(JournalPage.new(), ctx)

# ---------------------------------------------------------------- esplorazione
func _process(delta: float) -> void:
	if state != ST_PLAY:
		return
	if player == null or not is_instance_valid(player):
		return
	SaveGame.data["playSeconds"] = float(SaveGame.data.get("playSeconds", 0.0)) + delta
	_region_update(false)
	_update_nearby()
	_save_clock += delta
	if _save_clock >= 6.0:
		_save_clock = 0.0
		SaveGame.set_checkpoint(player.global_position, _region)

func _region_update(force: bool = false) -> void:
	var r := world.region_at(player.global_position)
	if r == _region and not force:
		return
	_region = r
	hud.set_region(r)
	hud.set_progress()
	Audio.set_region(r)
	if r >= 1:
		if not _visited.has(r):
			_visited[r] = true
			hud.toast("%02d · %s" % [r, MissionData.REGION_NAMES[r - 1]], 2.8)
			Audio.say_as(MissionData.CUSTODIANS[r - 1], MissionData.CUSTODIAN_LINES[r - 1], true, 0.55)
		SaveGame.set_checkpoint(player.global_position, r)
	else:
		if not _visited.has(0):
			_visited[0] = true
			Audio.say("Benvenuto nel Hub di Lumeria. Qui trovi la mappa, il diario, il laboratorio e il guardaroba.", true, 0.4)
		SaveGame.set_checkpoint(player.global_position, 0)

func _update_nearby() -> void:
	_near_station = world.nearest_station(player.global_position, 3.4)
	_near_collectible = world.nearest_collectible(player.global_position, 2.4)
	var text := ""
	if _near_collectible and is_instance_valid(_near_collectible):
		match _near_collectible.kind:
			"fireflies":
				text = "Saluta la lucciola"
			"critters":
				text = "Accarezza la creatura"
			_:
				text = "Suona la pietra musicale"
	elif _near_station and is_instance_valid(_near_station):
		if _near_station.special != "":
			match _near_station.special:
				"map":
					text = "Apri la mappa"
				"journal":
					text = "Apri il diario"
				"lab":
					text = "Entra nel laboratorio"
				"avatar":
					text = "Apri il guardaroba"
				_:
					text = _near_station.title
		else:
			text = "Gioca · " + _near_station.title
	if text != _prompt_text:
		_prompt_text = text
		hud.set_prompt(text)

func _interact() -> void:
	if _near_collectible and is_instance_valid(_near_collectible):
		var c := _near_collectible
		var is_new := SaveGame.register_collectible(c.kind, c.collectible_id)
		match c.kind:
			"fireflies":
				if is_new:
					hud.toast("Lucciola incontrata! %d in tutto." % SaveGame.collectible_count("fireflies"))
					Audio.say("Che bella lucciola! Le luci di Lumeria ti seguono.")
			"critters":
				if is_new:
					hud.toast("La creatura ti vuole bene!")
					Audio.say("La creatura ti si avvicina: puoi accarezzarla.")
			_:
				if is_new:
					hud.toast("Una nota nell'aria! %d pietre." % SaveGame.collectible_count("stones"))
					Audio.say("Questa pietra suona una nota dolce.")
		c.collect()
		_near_collectible = null
		_update_nearby()
		return
	if _near_station and is_instance_valid(_near_station):
		var s := _near_station
		if s.special != "":
			_open_special(s.special)
		else:
			_open_mission(s.station_id, false, s)
		return
	Audio.say("Avvicinati a una luce e premi A per interagire.")

func _open_special(kind: String) -> void:
	match kind:
		"map":
			_open_overlay(MapPage.new(), "play")
		"journal":
			_open_overlay(JournalPage.new(), "play")
		"lab":
			_open_overlay(LabMenu.new(), "play")
		"avatar":
			_open_overlay(AvatarPage.new(), "play")
		_:
			hud.toast("Questo luogo si aprirà presto.")

func _listen_nearby() -> void:
	if _near_collectible and is_instance_valid(_near_collectible):
		match _near_collectible.kind:
			"fireflies":
				Audio.say("Una lucciola. Le piace volare vicino alle lanterne.")
			"critters":
				Audio.say("Una piccola creatura del prato. Puoi accarezzarla.")
			_:
				Audio.say("Una pietra musicale. Suona se la tocchi.")
		return
	if _near_station and is_instance_valid(_near_station):
		if _near_station.mission.is_empty():
			match _near_station.special:
				"map":
					Audio.say("La mappa delle regioni. Scegli dove viaggiare.")
				"journal":
					Audio.say("Il diario delle pietre magiche. Qui vedi tutte le tue scoperte.")
				"lab":
					Audio.say("Il laboratorio libero. Nessuna risposta è sbagliata.")
				"avatar":
					Audio.say("Il guardaroba. Scegli il tuo aspetto.")
				_:
					Audio.say(_near_station.title)
		else:
			Audio.say("%s. %s" % [_near_station.title, str(_near_station.mission.get("instruction", ""))])
		return
	Audio.say("Cammina verso una luce. Quando sei vicino, premi A.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var full := str(Settings.get_setting("window_mode", "windowed")) == "fullscreen"
		Settings.set_setting("window_mode", "windowed" if full else "fullscreen")
		get_viewport().set_input_as_handled()
		return
	if state != ST_PLAY:
		return
	if event.is_action_pressed("pause"):
		_open_overlay(PausePage.new(), "play")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		_open_overlay(JournalPage.new(), "play")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("repeat_help"):
		Audio.repeat_last()
	elif event.is_action_pressed("highlight"):
		_listen_nearby()

# ---------------------------------------------------------------- salvataggio
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if player and is_instance_valid(player):
			SaveGame.set_checkpoint(player.global_position, _region)
		SaveGame.save_now()

# ---------------------------------------------------------------- smoke test
func _settle(frames: int = 8) -> void:
	for i in range(frames):
		await get_tree().process_frame

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		print("SHOT FAIL: " + label)
		return
	var dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(label + ".png")
	img.save_png(path)
	print("SHOT " + path)

## Catture rapide per iterare sulla grafica senza rifare tutti gli screenshot.
func _run_quickshot() -> void:
	SaveGame.reset_progress(true)
	_enter_menu()
	await _settle(25)
	await _capture("q_00_menu")
	Settings.data["tutorial_done"] = true
	_start_play()
	await _settle(45)
	await _capture("q_01_mondo")
	_open_overlay(AvatarPage.new(), "play")
	await _settle(18)
	await _capture("q_02_guardaroba")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_on_travel(3)
	await _settle(45)
	await _capture("q_03_regione")
	# Cartello di una postazione, visto da vicino e di fronte.
	var near_station: RegionStation = null
	for st in world.stations:
		if st.region_index == 3:
			near_station = st
			break
	if near_station != null:
		var front := near_station.global_transform.basis.z
		var spot_pos := near_station.global_position + front * 3.1
		spot_pos.y = 0.2
		var look := (near_station.global_position - spot_pos).normalized()
		player.teleport(spot_pos)
		player.rotation.y = atan2(-look.x, -look.z)
		rig.yaw = player.rotation.y
		rig.global_position = spot_pos + Vector3(0, 1.15, 0)
		await _settle(30)
		await _capture("q_03b_cartello")
		# Stesso cartello visto da dietro: deve restare leggibile.
		var back_pos := near_station.global_position - front * 3.1
		back_pos.y = 0.2
		var look_back := (near_station.global_position - back_pos).normalized()
		player.teleport(back_pos)
		player.rotation.y = atan2(-look_back.x, -look_back.z)
		rig.yaw = player.rotation.y
		rig.global_position = back_pos + Vector3(0, 1.15, 0)
		await _settle(30)
		await _capture("q_03c_cartello_dietro")
	_open_mission("022", false)
	await _settle(25)
	await _capture("q_04_missione")
	if _mission and is_instance_valid(_mission):
		# Anteprima del cubo in mano: si vede mentre si sceglie l'incastro.
		if _mission._tray_items.size() > 0:
			_mission._pick(_mission._tray_items[0])
			await _settle(30)
			await _capture("q_04b_anteprima")
			_mission._cancel()
			await _settle(6)
		_mission.debug_solve()
	await _settle(60)
	await _capture("q_05_vittoria")
	_close_mission_to_world()
	_resume_world()
	await _settle(10)
	# Prova di camminata: sposta l'avatar e mostra la vista da dietro.
	player.rotation.y = deg_to_rad(200.0)
	player.global_position = Vector3(-6.0, 0.2, 8.0)
	rig.yaw = deg_to_rad(20.0)
	await _settle(30)
	await _capture("q_06_camminata")
	print("QUICKSHOT OK")
	get_tree().quit(0)

func _run_shots() -> void:
	SaveGame.reset_progress(true)
	_enter_menu()
	await _settle(20)
	await _capture("01_menu")
	_open_overlay(SettingsMenu.new(), "menu")
	await _settle(12)
	await _capture("02_impostazioni")
	_close_overlay_silent()
	_enter_menu()
	await _settle(8)
	Settings.data["tutorial_done"] = true
	_start_play()
	await _settle(40)
	await _capture("04_mondo")
	_on_travel(3)
	await _settle(40)
	await _capture("05_regione")
	_open_mission("022", false)
	await _settle(25)
	await _capture("06_missione")
	if _mission and is_instance_valid(_mission):
		var ok := _mission.debug_solve()
		print("SHOT missione risolta: %s" % str(ok))
	await _settle(70)
	await _capture("07_vittoria")
	_close_mission_to_world()
	await _settle(12)
	_open_overlay(MapPage.new(), "play")
	await _settle(10)
	await _capture("08_mappa")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(JournalPage.new(), "play")
	await _settle(10)
	await _capture("09_diario")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(AvatarPage.new(), "play")
	await _settle(10)
	await _capture("10_guardaroba")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(TutorialPage.new(), "play")
	await _settle(10)
	await _capture("11_tutorial")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(FinalScene.new(), "play")
	await _settle(10)
	await _capture("12_finale")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(PausePage.new(), "play")
	await _settle(10)
	await _capture("13_pausa")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(TeacherPage.new(), "play")
	await _settle(10)
	await _capture("14_docente")
	_close_overlay_silent()
	_resume_world()
	await _settle(6)
	_open_overlay(LabMenu.new(), "play")
	await _settle(10)
	await _capture("15_laboratorio")
	_close_overlay_silent()
	# Tavoli con molte tessere e tavoli con percorso: controllo visivo dell'inquadratura.
	for pair in [["16_missione_misura", "080"], ["17_missione_percorso", "093"], ["18_missione_finale", "100"],
			["19_conta_base", "022"], ["20_conta_quattro", "029"], ["21_conta_etichette", "030"],
			["22_conta_molti", "038"], ["23_conta_ampia", "099"]]:
		_open_mission(str(pair[1]), false)
		await _settle(25)
		await _capture(str(pair[0]))
		_close_mission_to_world()
		await _settle(8)
	# Ultimo scatto: verifica della UI a 960×540 (il ridimensionamento va dopo
	# tutte le altre catture per non alterare il readback su Metal).
	_open_overlay(SettingsMenu.new(), "menu")
	await _settle(8)
	get_window().size = Vector2i(960, 540)
	await _settle(16)
	await _capture("03_impostazioni_960")
	get_window().size = Vector2i(1280, 720)
	print("SHOTS OK")
	get_tree().quit(0)

func _run_smoke() -> void:
	await get_tree().process_frame
	print("SMOKE stations=%d specials=%d missions=%d characters=%d" % [
		world.stations.size(), world.special_stations.size(), MissionData.all().size(), world.characters.size()])
	if world.stations.size() != 100 or world.special_stations.size() != 4:
		_smoke_fail("conteggio stazioni errato")
		return
	_start_play()
	await get_tree().process_frame
	_open_mission("001", false)
	await get_tree().process_frame
	await get_tree().process_frame
	if _mission == null:
		_smoke_fail("missione 001 non aperta")
		return
	print("SMOKE missione 001 sockets=%d cubes=%d" % [
		_mission._socket_nodes.size(), _mission._cube_nodes.size()])
	_close_mission_to_world()
	await get_tree().process_frame
	var pages: Array[Control] = [
		JournalPage.new(), MapPage.new(), AvatarPage.new(), TeacherPage.new(),
		TutorialPage.new(), PausePage.new(), LabMenu.new(), SettingsMenu.new(), FinalScene.new()
	]
	for page in pages:
		_open_overlay(page, "play")
		await get_tree().process_frame
		await get_tree().process_frame
		_close_overlay_silent()
		await get_tree().process_frame
	_final_open = false
	_resume_world()
	await get_tree().process_frame
	# La voice bank deve viaggiare dentro l'app, non dipendere dal sistema.
	var voice_hash := "Benvenuto a Lumeria. Segui le luci: ogni regione nasconde dieci pietre magiche.".sha256_text()
	var voice_path := "res://assets/voices/narrator/%s.ogg" % voice_hash
	var voice_stream = load(voice_path) if ResourceLoader.exists(voice_path) else null
	var voice_len := 0.0
	if voice_stream is AudioStream:
		voice_len = voice_stream.get_length()
	var voice_ok := voice_len > 1.0
	print("SMOKE voice=%s" % ("ok %.1fs" % voice_len if voice_ok else "MANCANTE"))
	if not voice_ok:
		_smoke_fail("voice bank non inclusa")
		return
	print("SMOKE OK")
	get_tree().quit(0)

## Verifica end-to-end: apre ogni missione, la risolve con gli stessi percorsi
## dell'input, controlla il salvataggio e il finale. Usa --selftest.
func _run_selftest() -> void:
	await _settle(4)
	var backup: Dictionary = SaveGame.data.duplicate(true)
	var backup_tutorial: Variant = Settings.data.get("tutorial_done", false)
	var backup_voice: Variant = Settings.data.get("audio_voice", 88)
	Settings.data["audio_voice"] = 0
	Settings.data["tutorial_done"] = true
	_start_play()
	await _settle(2)
	var failures: Array[String] = []
	var missions: Array = MissionData.all()
	var solved := 0
	for i in range(missions.size()):
		var m: Dictionary = missions[i]
		var id := str(m.get("id", ""))
		_open_mission(id, false)
		await _settle(3)
		if _mission == null or not is_instance_valid(_mission):
			failures.append("%s: missione non aperta" % id)
			continue
		_mission.quiet = true
		var ok: bool = _mission.debug_solve()
		if not ok:
			failures.append("%s: soluzione non accettata dal tavolo" % id)
		await _settle(1)
		if not SaveGame.is_mission_completed(id):
			failures.append("%s: completamento non registrato" % id)
		else:
			solved += 1
		if (i + 1) % 10 == 0:
			print("SELFTEST missioni %d/%d" % [i + 1, missions.size()])
		_close_mission_to_world()
		await _settle(1)
	# Il finale deve aprirsi dopo la centesima pietra magica.
	await _settle(20)
	var final_ok := _final_open and _overlay is FinalScene
	if not final_ok:
		failures.append("finale non aperto dopo 100 missioni")
	print("SELFTEST risolte=%d finale=%s stazioni=%d" % [
		solved, str(final_ok), world.stations.size()])
	SaveGame.data = backup
	SaveGame.save_now()
	Settings.data["tutorial_done"] = backup_tutorial
	Settings.data["audio_voice"] = backup_voice
	if failures.is_empty():
		print("SELFTEST OK")
		get_tree().quit(0)
	else:
		print("SELFTEST FALLITO: %d problemi" % failures.size())
		for f in failures:
			print(" - " + f)
		get_tree().quit(1)

func _smoke_fail(reason: String) -> void:
	print("SMOKE FAIL: " + reason)
	get_tree().quit(1)
