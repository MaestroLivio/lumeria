class_name PausePage
extends OverlayPage
## Pausa: nessuna pressione, nessun tempo che scorre. Si riprende quando si vuole.

signal action(name: String)

const ITEMS := [
	{"name": "resume", "label": "Riprendi", "icon": "play", "variant": "Primary"},
	{"name": "map", "label": "Mappa", "icon": "bussola", "variant": ""},
	{"name": "journal", "label": "Diario", "icon": "libro", "variant": ""},
	{"name": "avatar", "label": "Guardaroba", "icon": "mano", "variant": ""},
	{"name": "settings", "label": "Impostazioni", "icon": "pannello", "variant": ""},
	{"name": "tutorial", "label": "Tutorial", "icon": "aiuto", "variant": ""},
	{"name": "teacher", "label": "Pannello docente", "icon": "libro", "variant": ""},
	{"name": "lab", "label": "Laboratorio libero", "icon": "gioco", "variant": ""},
	{"name": "main_menu", "label": "Menu principale", "icon": "casa", "variant": "Ghost"},
	{"name": "quit", "label": "Esci dal gioco", "icon": "freccia", "variant": "Ghost"},
]

func _init() -> void:
	page_title = "Pausa"
	page_icon = "pannello"
	close_text = "Riprendi"

func _page_ready() -> void:
	var pal := UITheme.palette()
	content.add_child(UIKit.body(
		"Il mondo aspetta. Nessun tempo limite, nessuna penalità: scegli con calma.",
		19, pal["ink_soft"]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for item in ITEMS:
		var b := UIKit.icon_button(str(item["icon"]), str(item["label"]), str(item["variant"]))
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(func() -> void:
			Audio.play_sfx("click")
			action.emit(str(item["name"])))
		grid.add_child(b)
	content.add_child(UIKit.spacer(4))
	var note := UIKit.label("Suggerimento: con START o P apri e chiudi la pausa in qualsiasi momento.", 16, pal["ink_soft"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
