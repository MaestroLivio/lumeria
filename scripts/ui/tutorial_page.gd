class_name TutorialPage
extends OverlayPage
## Tutorial in sei passi, con voce e immagini. Pensato per chi non sa ancora leggere.

const STEPS := [
	{"icon": "stella_finale", "title": "Benvenuto a Lumeria",
		"text": "Cento pietre magiche luminose aspettano di essere riaccese. Non ci sono combattimenti, tempo limite o vite: solo scoperte.",
		"voice": "Benvenuto a Lumeria! Cento pietre magiche luminose aspettano di essere riaccese. Qui nessuno perde e nessuno ha fretta."},
	{"icon": "orma", "title": "Cammina",
		"text": "Muovi lo stick sinistro o il D-pad. Con la tastiera usa W A S D oppure le frecce.",
		"voice": "Per camminare muovi lo stick sinistro o il D-pad. Con la tastiera usa le lettere W A S D oppure le frecce."},
	{"icon": "lente", "title": "Guarda intorno",
		"text": "Ruota la camera con lo stick destro. Con il mouse, trascina tenendo premuto il tasto sinistro. Le frecce della tastiera funzionano sempre.",
		"voice": "Ruota la camera con lo stick destro. Con il mouse puoi trascinare tenendo premuto il tasto sinistro. La camera non entra mai nei muri."},
	{"icon": "mano", "title": "Avvicinati e interagisci",
		"text": "Quando sei vicino a una postazione o a una lucciola, premi A. Sulla tastiera usa E, Invio o Spazio.",
		"voice": "Avvicinati a una postazione o a una lucciola. Quando compare il suggerimento, premi A per interagire. Sulla tastiera usa E, Invio o Spazio."},
	{"icon": "libro", "title": "Diario, mappa e pausa",
		"text": "BACK o J apre il diario. La mappa si trova nel Hub. START o P mette tutto in pausa: il mondo aspetta te.",
		"voice": "Il diario si apre con BACK o con la lettera J. Nel Hub trovi la mappa. START o P mette il gioco in pausa: il mondo aspetta te."},
	{"icon": "aiuto", "title": "Chiedere aiuto è bello",
		"text": "Se un incastro sembra difficile, premi X per un aiuto. Puoi riprovare quante volte vuoi: nessuna pietra magica si spegne.",
		"voice": "Se qualcosa sembra difficile, premi X per un aiuto. Puoi riprovare quante volte vuoi. Nessuna pietra magica si spegne mai."},
]

var _index := 0
var _icon: TextureRect
var _step_label: Label
var _title_label: Label
var _text_label: Label
var _dots: Label
var _prev: Button
var _next: Button

func _init() -> void:
	page_title = "Tutorial"
	page_icon = "aiuto"
	close_text = "Inizia"

func _page_ready() -> void:
	var pal := UITheme.palette()
	var card := UIKit.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(card)
	var v := UIKit.content(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	_icon = UIKit.icon_rect(STEPS[0]["icon"], 96, pal["gold"])
	h.add_child(_icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 6)
	h.add_child(texts)
	_step_label = UIKit.label("", 16, pal["accent2"], true)
	texts.add_child(_step_label)
	_title_label = UIKit.title("", 30)
	texts.add_child(_title_label)
	_text_label = UIKit.body("", 20, pal["ink"])
	_text_label.custom_minimum_size = Vector2(0, 90)
	texts.add_child(_text_label)

	_dots = UIKit.label("", 22, pal["gold"], true)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_dots)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_prev = UIKit.button("Indietro", "", 52)
	_prev.custom_minimum_size = Vector2(190, 52)
	_prev.pressed.connect(_go_prev)
	row.add_child(_prev)
	_next = UIKit.button("Avanti", "Primary", 52)
	_next.custom_minimum_size = Vector2(240, 52)
	_next.pressed.connect(_go_next)
	row.add_child(_next)

	content.add_child(UIKit.body(
		"Puoi rivedere questo tutorial quando vuoi da Impostazioni → Gioco.",
		16, pal["ink_soft"]))
	_show_step(0)
	call_deferred("_focus_default_button")

func _show_step(i: int) -> void:
	_index = clampi(i, 0, STEPS.size() - 1)
	var s: Dictionary = STEPS[_index]
	_icon.texture = IconLibrary.texture(str(s["icon"]), UITheme.palette()["gold"])
	_step_label.text = "Passo %d di %d" % [_index + 1, STEPS.size()]
	_title_label.text = str(s["title"])
	_text_label.text = str(s["text"])
	var marks: Array[String] = []
	for k in range(STEPS.size()):
		marks.append("●" if k == _index else "○")
	_dots.text = " ".join(marks)
	_prev.disabled = _index == 0
	_next.text = "Inizia l'avventura" if _index == STEPS.size() - 1 else "Avanti"
	Audio.play_sfx("click")
	Audio.say(str(s["voice"]))

func _go_prev() -> void:
	if _index > 0:
		_show_step(_index - 1)

func _go_next() -> void:
	if _index < STEPS.size() - 1:
		_show_step(_index + 1)
	else:
		close_page()

func close_page() -> void:
	if _closing:
		return
	Settings.set_setting("tutorial_done", true)
	SaveGame.data["tutorial_done"] = true
	SaveGame.save_now()
	super.close_page()
