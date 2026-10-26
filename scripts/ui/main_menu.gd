class_name MainMenu
extends Control
## Menu principale: gioca, nuova avventura, mappa, diario, guardaroba, impostazioni.

signal action(name: String)

var _continue_btn: Button
var _info_layer: Control
var _confirm_layer: Control
var _root: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.make_theme()
	_build()
	visible = false

func _build() -> void:
	var pal := UITheme.palette()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.04, 0.06, 0.12, 0.24)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(veil)

	var left := PanelContainer.new()
	UITheme.style_panel(left, "card")
	left.set_anchors_preset(Control.PRESET_FULL_RECT)
	left.anchor_right = 0.40
	left.offset_left = 24
	left.offset_top = 36
	left.offset_right = -8
	left.offset_bottom = -36
	left.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	left.add_child(lv)
	var star := UIKit.icon_rect("stella_finale", 64, pal["gold"])
	star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lv.add_child(star)
	var title := UIKit.title("LUMERIA", 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(title)
	var sub := UIKit.label("Le cento pietre magiche del sapere", 20, pal["accent2"], true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(sub)
	lv.add_child(UIKit.spacer(4))
	lv.add_child(UIKit.body(
		"Un'avventura esplorativa per bambini di 5–7 anni. Cammina, ascolta, gioca: ogni regione nasconde dieci pietre magiche da riaccendere.",
		17, pal["ink_soft"]))
	lv.add_child(UIKit.spacer(2))
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override("separation", 8)
	lv.add_child(icons)
	for icon_name in ["leaf", "freccia", "flower", "train", "star", "nota", "casa", "stella_finale"]:
		icons.add_child(UIKit.icon_rect(icon_name, 26, pal["accent"]))
	lv.add_child(UIKit.spacer(2))
	var privacy := UIKit.label("OFFLINE · NESSUN ACCOUNT · NESSUN DATO PERSONALE", 12, pal["ink_soft"])
	privacy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(privacy)
	var note := UIKit.label("Suggerimento: usa il gamepad. Il gioco parte in una finestra ridimensionabile.", 13, pal["ink_soft"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(note)

	var right := PanelContainer.new()
	UITheme.style_panel(right, "card")
	right.set_anchors_preset(Control.PRESET_FULL_RECT)
	right.anchor_left = 0.41
	right.offset_left = 8
	right.offset_top = 36
	right.offset_right = -24
	right.offset_bottom = -36
	right.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	right.add_child(rv)
	rv.add_child(UIKit.header("Cosa vuoi fare?", 25))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_child(scroll)
	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 4)
	scroll.add_child(buttons)

	_continue_btn = _menu_button(buttons, "Gioca", "play", "Primary", "continue")
	_menu_button(buttons, "Nuova avventura", "stella_finale", "Warm", "new_game")
	_menu_button(buttons, "Mappa delle regioni", "bussola", "", "map")
	_menu_button(buttons, "Diario delle pietre magiche", "libro", "", "journal")
	_menu_button(buttons, "Guardaroba", "mano", "", "avatar")
	_menu_button(buttons, "Impostazioni", "pannello", "", "settings")
	_menu_button(buttons, "Laboratorio libero", "gioco", "", "lab")
	_menu_button(buttons, "Informazioni e comandi", "aiuto", "", "info")
	_menu_button(buttons, "Esci dal gioco", "freccia", "Ghost", "quit")
	rv.add_child(UIKit.spacer(2))
	var foot := UIKit.label("Lumeria è un progetto locale e senza pubblicità.", 13, pal["ink_soft"])
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(foot)

	_build_info()
	_build_confirm()

func _menu_button(parent: VBoxContainer, text: String, icon: String, variant: String,
		action_name: String) -> Button:
	var b := UIKit.icon_button(icon, text, variant)
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", Settings.fs(22))
	b.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		if action_name == "info":
			_show_info()
		elif action_name == "new_game":
			_ask_new_game()
		else:
			action.emit(action_name))
	parent.add_child(b)
	return b

func open(has_progress: bool) -> void:
	visible = true
	_continue_btn.disabled = false
	_continue_btn.text = "Continua l'avventura" if has_progress else "Gioca"
	_info_layer.visible = false
	_confirm_layer.visible = false
	call_deferred("_focus_first")

func _focus_first() -> void:
	if _continue_btn and _continue_btn.is_visible_in_tree():
		_continue_btn.grab_focus()
		return
	var buttons := _root.find_children("*", "Button", true, false)
	for b in buttons:
		if (b as Button).disabled == false and (b as Button).is_visible_in_tree():
			(b as Button).grab_focus()
			return

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
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	var t := UIKit.title("Iniziare una nuova avventura?", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := UIKit.body("Le pietre magiche già accese resteranno nel tuo profilo locale finché non confermi. Vuoi ricominciare da zero?",
		20, pal["ink_soft"])
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var yes := UIKit.button("Sì, ricomincia", "Warm")
	yes.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		_confirm_layer.visible = false
		action.emit("new_game"))
	row.add_child(yes)
	var no := UIKit.button("No, torna", "Primary")
	no.pressed.connect(func() -> void:
		Audio.play_sfx("back")
		_confirm_layer.visible = false
		_focus_first())
	row.add_child(no)

func _ask_new_game() -> void:
	_confirm_layer.visible = true
	var buttons := _confirm_layer.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		(buttons[0] as Button).grab_focus()

func _build_info() -> void:
	var pal := UITheme.palette()
	_info_layer = Control.new()
	_info_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_info_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_info_layer.visible = false
	add_child(_info_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	_info_layer.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_info_layer.add_child(margin)
	var card := PanelContainer.new()
	UITheme.style_panel(card, "card")
	margin.add_child(card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	card.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var t := UIKit.title("Informazioni e comandi", 34)
	v.add_child(t)
	v.add_child(UIKit.body(
		"Lumeria è un gioco educativo 3D per bambini di 5–7 anni. Non ci sono combattimenti, tempo limite, vite o punizioni. Ogni missione può essere riprovata e gli aiuti sono sempre disponibili.",
		20, pal["ink"]))
	v.add_child(UIKit.hsep())
	v.add_child(UIKit.header("Comandi gamepad", 24))
	v.add_child(UIKit.body("Stick sinistro / D-pad: cammina. Stick destro: ruota la camera. A: interagisci. X: aiuto o ripeti la voce. Y: ascolta. START: pausa. BACK: diario. LB/RB: cambia sezione nei menu.", 19))
	v.add_child(UIKit.header("Comandi tastiera e mouse", 24))
	v.add_child(UIKit.body("WASD o frecce: cammina. Mouse: trascina con il tasto sinistro per ruotare la camera. Rotella: zoom. E/Invio/Spazio: interagisci. H: aiuto. L: ascolta. P/Esc: pausa. J: diario.", 19))
	v.add_child(UIKit.header("Privacy", 24))
	v.add_child(UIKit.body("Nessun account, nessuna connessione, nessun tracciamento. I progressi sono salvati solo su questo dispositivo, in un file locale. Puoi esportarli o cancellarli dal pannello docente.", 19))
	v.add_child(UIKit.header("Crediti", 24))
	v.add_child(UIKit.body("Progetto originale Lumeria. Grafica, audio e voci generati a runtime con Godot 4. Voci italiane di sistema macOS. Nessun contenuto di terze parti.", 19))
	var close := UIKit.button("Chiudi", "Primary")
	close.pressed.connect(func() -> void:
		Audio.play_sfx("back")
		_info_layer.visible = false
		_focus_first())
	v.add_child(close)

func _show_info() -> void:
	_info_layer.visible = true
	var buttons := _info_layer.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		(buttons[buttons.size() - 1] as Button).grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _info_layer and _info_layer.visible:
		if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
			_info_layer.visible = false
			_focus_first()
			get_viewport().set_input_as_handled()
		return
	if _confirm_layer and _confirm_layer.visible:
		if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
			_confirm_layer.visible = false
			_focus_first()
			get_viewport().set_input_as_handled()
