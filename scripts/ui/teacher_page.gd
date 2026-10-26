class_name TeacherPage
extends OverlayPage
## Pannello docente: osservazioni, esportazione e importazione locale.
## Nessun voto, nessun giudizio, nessun dato inviato in rete.

signal progress_changed

const EXPORT_PATH := "user://lumeria_progressi.json"

var _summary: Label
var _status: Label
var _import_btn: Button
var _reset_btn: Button
var _pending := ""

func _init() -> void:
	page_title = "Pannello docente"
	page_icon = "libro"
	close_text = "Chiudi"

func _page_ready() -> void:
	var pal := UITheme.palette()
	content.add_child(UIKit.body(
		"Questa pagina serve agli adulti. Mostra quante pietre magiche sono state accese, i tentativi e gli aiuti usati. Non ci sono voti e non viene inviato nulla in rete.",
		18, pal["ink_soft"]))

	_summary = UIKit.body(SaveGame.summary_text(), 16, pal["ink"])
	_summary.custom_minimum_size = Vector2(0, 300)
	content.add_child(_summary)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var export := UIKit.button("Esporta progressi", "Primary", 50)
	export.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export.pressed.connect(_export)
	row.add_child(export)
	_import_btn = UIKit.button("Importa progressi", "", 50)
	_import_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_btn.pressed.connect(_import)
	row.add_child(_import_btn)
	var copy := UIKit.button("Copia riepilogo", "", 50)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.pressed.connect(_copy)
	row.add_child(copy)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	content.add_child(row2)
	_reset_btn = UIKit.button("Azzera i progressi", "Danger", 50)
	_reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset_btn.pressed.connect(_reset)
	row2.add_child(_reset_btn)

	_status = UIKit.label("", 16, pal["accent2"], true)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)

	var path_box := UIKit.card(18)
	content.add_child(path_box)
	var pv := UIKit.content(path_box)
	pv.add_child(UIKit.header("File locale", 22))
	var path_label := UIKit.body(ProjectSettings.globalize_path(EXPORT_PATH), 15, pal["ink_soft"])
	path_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	pv.add_child(path_label)
	pv.add_child(UIKit.body(
		"Per usare il file su un altro computer della classe: esporta qui, copia il file JSON, poi premi Importa sull'altro dispositivo. Il profilo è anonimo.",
		15, pal["ink_soft"]))

	var note := UIKit.body(
		"Nota pedagogica: il gioco non corregge con voti né penalizza gli errori. Le osservazioni servono a capire quali competenze sono state esplorate e quante volte il bambino ha chiesto aiuto.",
		16, pal["ink_soft"])
	content.add_child(note)

func _export() -> void:
	Audio.play_sfx("click")
	if SaveGame.export_to(EXPORT_PATH):
		_flash("Esportato in: " + ProjectSettings.globalize_path(EXPORT_PATH))
		Audio.say("Progressi esportati sul dispositivo.")
	else:
		_flash("Non è stato possibile scrivere il file.")

func _import() -> void:
	Audio.play_sfx("click")
	if not FileAccess.file_exists(EXPORT_PATH):
		_flash("Nessun file da importare. Esporta prima da un altro dispositivo.")
		return
	if _pending != "import":
		_pending = "import"
		_import_btn.text = "Conferma importazione"
		_flash("Il file esiste. Premi di nuovo per importarlo.")
		return
	_pending = ""
	_import_btn.text = "Importa progressi"
	if SaveGame.import_from(EXPORT_PATH):
		_refresh_summary()
		progress_changed.emit()
		_flash("Progressi importati.")
		Audio.say("Progressi importati. Bentornato nel viaggio.")
	else:
		_flash("Il file non è leggibile.")

func _copy() -> void:
	Audio.play_sfx("click")
	DisplayServer.clipboard_set(SaveGame.summary_text())
	_flash("Riepilogo copiato negli appunti.")

func _reset() -> void:
	Audio.play_sfx("click")
	if _pending != "reset":
		_pending = "reset"
		_reset_btn.text = "Sei sicuro? Premi di nuovo"
		_flash("L'aspetto dell'avatar resterà. Le pietre magiche torneranno a zero.")
		return
	_pending = ""
	_reset_btn.text = "Azzera i progressi"
	SaveGame.reset_progress(true)
	_refresh_summary()
	progress_changed.emit()
	_flash("Progressi azzerati.")
	Audio.say("Un nuovo viaggio comincia.")

func _refresh_summary() -> void:
	if _summary:
		_summary.text = SaveGame.summary_text()

func _flash(text: String) -> void:
	if _status:
		_status.text = text
