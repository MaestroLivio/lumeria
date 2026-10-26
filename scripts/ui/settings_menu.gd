class_name SettingsMenu
extends Control
## Impostazioni complete: audio, video, accessibilità, camera, comandi, gioco, docente.

signal closed
signal teacher_requested
signal tutorial_requested
signal reset_progress_requested

const CATEGORIES := [
	{"id": "audio", "label": "Audio", "icon": "musica"},
	{"id": "video", "label": "Video", "icon": "pannello"},
	{"id": "access", "label": "Accessibilità", "icon": "occhio"},
	{"id": "camera", "label": "Camera", "icon": "lente"},
	{"id": "controls", "label": "Comandi", "icon": "mano"},
	{"id": "game", "label": "Gioco", "icon": "gioco"},
	{"id": "teacher", "label": "Docente", "icon": "libro"},
]

var _content: VBoxContainer
var _nav: VBoxContainer
var _current := "audio"
var _toast: Label
var _confirm_layer: Control
var _confirm_yes: Button
var _confirm_no: Button
var _confirm_title: Label
var _confirm_text: Label
var _confirm_action: Callable
var _controller_layer: Control
var _controller_info: Label
var _controller_axis: Label
var _controller_buttons: Label
var _controller_process := false
var _root: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make_theme()
	_build()

func _build() -> void:
	var pal := UITheme.palette()
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var panel := PanelContainer.new()
	UITheme.style_panel(panel, "card")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)
	_root = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	head.add_child(UIKit.icon_rect("pannello", 34, pal["gold"]))
	var t := UIKit.title("Impostazioni", 36)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var reset := UIKit.button("Ripristina", "", 46)
	reset.pressed.connect(_ask_reset)
	head.add_child(reset)
	var close := UIKit.button("Chiudi", "Primary", 46)
	close.pressed.connect(_close)
	head.add_child(close)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	v.add_child(body)
	var nav_scroll := ScrollContainer.new()
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_scroll.custom_minimum_size = Vector2(224, 0)
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.follow_focus = true
	body.add_child(nav_scroll)
	_nav = VBoxContainer.new()
	_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nav.add_theme_constant_override("separation", 6)
	nav_scroll.add_child(_nav)
	for cat in CATEGORIES:
		var b := UIKit.icon_button(cat["icon"], cat["label"], "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 50)
		b.pressed.connect(func() -> void:
			_current = str(cat["id"])
			Audio.play_sfx("click")
			_rebuild_content())
		_nav.add_child(b)
	body.add_child(UIKit.hsep(pal["line"], 2))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	v.add_child(foot)
	var info := UIKit.label("Le modifiche si applicano subito e restano salvate su questo dispositivo.", 15, pal["ink_soft"])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(info)
	_toast = UIKit.label("", 15, pal["accent2"], true)
	foot.add_child(_toast)

	_build_confirm()
	_build_controller_test()
	_rebuild_content()

func open() -> void:
	visible = true
	theme = UITheme.make_theme()
	_rebuild_content()
	call_deferred("_focus_first")

func _focus_first() -> void:
	var buttons := _nav.find_children("*", "Button", true, false)
	for b in buttons:
		if (b as Button).text.to_lower() == _category_label(_current).to_lower():
			(b as Button).grab_focus()
			return
	if not buttons.is_empty():
		(buttons[0] as Button).grab_focus()

func _category_label(id: String) -> String:
	for c in CATEGORIES:
		if c["id"] == id:
			return str(c["label"])
	return "Audio"

func _close() -> void:
	Audio.play_sfx("back")
	closed.emit()

func _rebuild_content() -> void:
	if _content == null:
		return
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	match _current:
		"audio": _build_audio()
		"video": _build_video()
		"access": _build_access()
		"camera": _build_camera()
		"controls": _build_controls()
		"game": _build_game()
		"teacher": _build_teacher()

func _section(title_text: String, subtitle: String = "") -> VBoxContainer:
	var card := UIKit.card()
	_content.add_child(card)
	var v := UIKit.content(card)
	v.add_child(UIKit.header(title_text, 25))
	if subtitle != "":
		v.add_child(UIKit.body(subtitle, 17))
	return v

func _toggle(parent: VBoxContainer, key: String, text: String) -> void:
	parent.add_child(UIKit.toggle_row(text, bool(Settings.get_setting(key)), func(value: bool) -> void:
		Settings.set_setting(key, value)
		_flash("Salvato: " + text)))

func _slider(parent: VBoxContainer, key: String, text: String, minv: float, maxv: float, step: float, suffix: String = "") -> void:
	parent.add_child(UIKit.slider_row(text, minv, maxv, step, float(Settings.get_setting(key)),
		func(v: float) -> String: return "%d%s" % [int(v), suffix],
		func(v: float) -> void:
			Settings.set_setting(key, v)
			_flash("Salvato: " + text)))

func _cycle(parent: VBoxContainer, key: String, text: String, options: Array, values: Array) -> void:
	var idx := 0
	var current: Variant = Settings.get_setting(key)
	for i in range(values.size()):
		if values[i] == current:
			idx = i
			break
	parent.add_child(UIKit.cycle_row(text, options, idx, func(i: int) -> void:
		if i >= 0 and i < values.size():
			Settings.set_setting(key, values[i])
			_flash("Salvato: " + text)))

func _button_row(parent: VBoxContainer, buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	for b in buttons:
		row.add_child(b)
	return row

# ---------------------------------------------------------------- sezioni
func _build_audio() -> void:
	var s := _section("Audio", "Musica e suoni sono generati nel gioco; la voce è inclusa nell'app e parla anche offline.")
	_slider(s, "audio_music", "Musica", 0, 100, 1, "%")
	_slider(s, "audio_sfx", "Effetti sonori", 0, 100, 1, "%")
	_slider(s, "audio_voice", "Voce narrante", 0, 100, 1, "%")
	_toggle(s, "music_muted", "Musica disattivata")
	var test_voice := UIKit.button("Prova la voce", "", 48)
	test_voice.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		Audio.say("Ciao! Sono la voce di Lumeria. Ascoltiamo insieme la biblioteca dei suoni."))
	var test_sfx := UIKit.button("Prova i suoni", "", 48)
	test_sfx.pressed.connect(func() -> void:
		Audio.play_sfx("success")
		Audio.say("Pietra magica accesa!"))
	_button_row(s, [test_voice, test_sfx])
	s.add_child(UIKit.body("La banca vocale è inclusa nell'app: se un testo non è disponibile, compaiono i sottotitoli.", 16))

func _build_video() -> void:
	var s := _section("Video e finestra", "Il gioco parte sempre in una finestra ridimensionabile. Puoi scegliere uno schermo intero quando vuoi.")
	_cycle(s, "window_mode", "Modalità finestra", ["Finestra", "Senza bordi", "Schermo intero"],
		["windowed", "borderless", "fullscreen"])
	var sizes: Array[Vector2i] = Settings.resolution_sizes()
	var labels: Array = []
	for size in sizes:
		labels.append("%d × %d" % [size.x, size.y])
	var vals: Array = []
	for i in range(sizes.size()):
		vals.append(i)
	_cycle(s, "resolution", "Risoluzione in finestra", labels, vals)
	_toggle(s, "vsync", "Sincronia verticale")
	_slider(s, "glow", "Intensità del bagliore", 0, 150, 5, "%")
	var qlabels := ["Essenziale", "Bilanciata", "Massima"]
	_cycle(s, "quality", "Qualità grafica", qlabels, [0, 1, 2])
	s.add_child(UIKit.body("La qualità Essenziale riduce dettagli e ombre per computer meno potenti.", 16))

func _build_access() -> void:
	var s := _section("Accessibilità", "Il gioco è pensato per chi non sa ancora leggere: ogni testo importante ha voce e icona.")
	_slider(s, "text_size", "Dimensione del testo", 0.8, 1.6, 0.1, "×")
	_toggle(s, "subtitles", "Sottotitoli")
	_toggle(s, "high_contrast", "Alto contrasto")
	_toggle(s, "reduce_motion", "Riduci il movimento")
	_toggle(s, "no_flash", "Evita lampi e flash")
	_toggle(s, "thick_outlines", "Contorni spessi")
	_cycle(s, "hints_mode", "Aiuti", ["Scopro", "Sempre", "Dopo tre prove"],
		["scopro", "sempre", "dopo3"])
	_toggle(s, "guided_mode", "Modalità guidata")
	s.add_child(UIKit.body("La modalità guidata mostra un suggerimento in più dopo ogni tentativo. Nessuna penalità: si può sempre riprovare.", 16))

func _build_camera() -> void:
	var s := _section("Camera", "La camera segue l'avatar e può essere ruotata con lo stick destro o con il mouse.")
	_slider(s, "camera_sensitivity", "Sensibilità camera", 0.4, 2.0, 0.1, "×")
	_cycle(s, "camera_mode", "Tipo di camera", ["Segui", "Orbita libera"], ["follow", "orbit"])
	_toggle(s, "invert_y", "Inverti asse verticale")
	_toggle(s, "auto_recenter", "Ricentra dolcemente")
	_toggle(s, "assisted_camera", "Camera facilitata")
	s.add_child(UIKit.body("Con la camera facilitata, durante le missioni la camera segue dolcemente il personaggio e mantiene il tavolo inquadrato.", 16))
	s.add_child(UIKit.body("La camera non entra mai nei muri: usa un braccio elastico con collisione.", 16))

func _build_controls() -> void:
	var s := _section("Comandi", "Gamepad consigliato. Tastiera e mouse funzionano sempre.")
	var pads := Settings.controller_name()
	s.add_child(UIKit.body("Controller: " + pads, 18, UITheme.palette()["accent2"]))
	_slider(s, "deadzone", "Zona morta stick", 0.1, 0.5, 0.05, "")
	_toggle(s, "vibration", "Vibrazione")
	_toggle(s, "dpad_only", "Solo D-pad per camminare")
	_cycle(s, "controller_layout", "Simboli del controller",
		["Automatico", "Xbox", "PlayStation", "Nintendo"],
		["auto", "xbox", "playstation", "nintendo"])
	s.add_child(UIKit.body("Simboli attuali: " + Settings.controller_layout_name(), 16))
	var test := UIKit.button("Prova il controller", "Primary", 50)
	test.pressed.connect(_open_controller_test)
	_button_row(s, [test])
	s.add_child(UIKit.body("Con il D-pad si navigano anche tutti i menu. A conferma, B torna indietro, LB/RB cambiano sezione.", 16))

func _build_game() -> void:
	var s := _section("Gioco", "Tutte le regioni sono sempre esplorabili. Le missioni si possono rigiocare in qualsiasi momento.")
	_toggle(s, "progression_guided", "Percorso suggerito")
	_toggle(s, "classroom_mode", "Modalità classe")
	var tutorial := UIKit.button("Rivedi il tutorial", "", 50)
	tutorial.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		tutorial_requested.emit())
	_button_row(s, [tutorial])
	s.add_child(UIKit.body("Il tutorial mostra movimento, camera, interazione, diario e pausa in cinque piccoli passi.", 16))
	var info := _section("Il mio viaggio", "Riepilogo locale, senza nomi né dati personali.")
	info.add_child(UIKit.body("Pietre magiche accese: %d su 100\nLucciole incontrate: %d\nCreature accarezzate: %d\nPietre musicali: %d" % [
		SaveGame.completed_count(), SaveGame.collectible_count("fireflies"),
		SaveGame.collectible_count("critters"), SaveGame.collectible_count("stones")], 18))
	var reset := UIKit.button("Azzera i progressi", "Danger", 48)
	reset.pressed.connect(func() -> void:
		_ask_confirm("Azzerare i progressi?", "Le pietre magiche e gli incontri torneranno a zero. L'aspetto dell'avatar resta. Questa azione non si può annullare.",
			func() -> void:
				SaveGame.reset_progress(true)
				_flash("Progressi azzerati.")
				Audio.say("Un nuovo viaggio comincia.")))
	_button_row(info, [reset])

func _build_teacher() -> void:
	var s := _section("Pannello docente", "Osservazioni di gioco, esportazione e importazione. Nessun giudizio, nessun voto.")
	var summary := UIKit.body(SaveGame.summary_text(), 16, UITheme.palette()["ink"])
	summary.custom_minimum_size = Vector2(0, 230)
	s.add_child(summary)
	var open := UIKit.button("Apri pannello completo", "Primary", 50)
	open.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		teacher_requested.emit())
	_button_row(s, [open])
	s.add_child(UIKit.body("Il pannello completo permette di esportare un file JSON sul dispositivo e di importarlo su un altro computer della classe.", 16))

# ---------------------------------------------------------------- conferme
func _build_confirm() -> void:
	var pal := UITheme.palette()
	_confirm_layer = Control.new()
	_confirm_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_layer.visible = false
	add_child(_confirm_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	_confirm_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.add_child(center)
	var card := PanelContainer.new()
	UITheme.style_panel(card, "card")
	card.custom_minimum_size = Vector2(600, 300)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	card.add_child(v)
	_confirm_title = UIKit.title("", 30)
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_confirm_title)
	_confirm_text = UIKit.body("", 19)
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_confirm_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	_confirm_yes = UIKit.button("Conferma", "Warm")
	_confirm_yes.pressed.connect(func() -> void:
		_confirm_layer.visible = false
		_confirm_action.call())
	row.add_child(_confirm_yes)
	_confirm_no = UIKit.button("Annulla", "Primary")
	_confirm_no.pressed.connect(func() -> void:
		_confirm_layer.visible = false)
	row.add_child(_confirm_no)

func _ask_confirm(title: String, text: String, act: Callable) -> void:
	_confirm_title.text = title
	_confirm_text.text = text
	_confirm_action = act
	_confirm_layer.visible = true
	_confirm_no.grab_focus()

func _ask_reset() -> void:
	_ask_confirm("Ripristinare le impostazioni?", "Audio, video, accessibilità e comandi torneranno ai valori iniziali. I progressi non vengono toccati.",
		func() -> void:
			Settings.reset()
			_rebuild_content()
			_flash("Impostazioni ripristinate.")
			Audio.say("Impostazioni ripristinate."))

# ---------------------------------------------------------------- test controller
func _build_controller_test() -> void:
	var pal := UITheme.palette()
	_controller_layer = Control.new()
	_controller_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controller_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_controller_layer.visible = false
	add_child(_controller_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	_controller_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controller_layer.add_child(center)
	var card := PanelContainer.new()
	UITheme.style_panel(card, "card")
	card.custom_minimum_size = Vector2(640, 430)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	var t := UIKit.title("Prova il controller", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_controller_info = UIKit.body("", 19, pal["ink"])
	v.add_child(_controller_info)
	_controller_axis = UIKit.label("", 20, pal["accent2"], true)
	v.add_child(_controller_axis)
	_controller_buttons = UIKit.body("", 20, pal["ink"])
	v.add_child(_controller_buttons)
	var vib := UIKit.button("Fai vibrare", "", 46)
	vib.pressed.connect(func() -> void:
		Settings.rumble(0.7, 0.4)
		Audio.play_sfx("heart"))
	v.add_child(vib)
	var close := UIKit.button("Chiudi", "Primary", 48)
	close.pressed.connect(func() -> void:
		_controller_layer.visible = false
		_controller_process = false
		Audio.play_sfx("back"))
	v.add_child(close)

func _open_controller_test() -> void:
	_controller_layer.visible = true
	_controller_process = true
	_controller_info.text = "Controller: " + Settings.controller_name() + "\nSimboli: " + Settings.controller_layout_name()
	var buttons := _controller_layer.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		(buttons[buttons.size() - 1] as Button).grab_focus()

func _process(_delta: float) -> void:
	if not _controller_process:
		return
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		_controller_axis.text = "Nessun controller collegato. Tastiera e mouse sono attivi."
		_controller_buttons.text = "Puoi collegare un gamepad in qualsiasi momento."
		return
	var pad: int = pads[0]
	var lx := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
	var ly := Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
	var rx := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
	_controller_axis.text = "Stick sinistro  %.2f / %.2f     Stick destro  %.2f / %.2f" % [lx, ly, rx, ry]
	var pressed: Array[String] = []
	var names := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "BACK", 6: "START", 9: "LB", 10: "RB",
		11: "D-pad ↑", 12: "D-pad ↓", 13: "D-pad ←", 14: "D-pad →"}
	for b in names.keys():
		if Input.is_joy_button_pressed(pad, b):
			pressed.append(names[b])
	_controller_buttons.text = "Tasti premuti: " + ("nessuno" if pressed.is_empty() else " · ".join(pressed))
	_controller_info.text = "Controller: " + Input.get_joy_name(pad) + "\nSimboli: " + Settings.controller_layout_name()

func _flash(text: String) -> void:
	if _toast:
		_toast.text = text
		var tw := create_tween()
		_toast.modulate.a = 1.0
		tw.tween_interval(1.4)
		tw.tween_property(_toast, "modulate:a", 0.0, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		if _controller_layer.visible:
			_controller_layer.visible = false
			_controller_process = false
			get_viewport().set_input_as_handled()
		elif _confirm_layer.visible:
			_confirm_layer.visible = false
			get_viewport().set_input_as_handled()
		else:
			_close()
			get_viewport().set_input_as_handled()
