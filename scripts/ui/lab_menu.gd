class_name LabMenu
extends OverlayPage
## Laboratorio libero: scegli una qualsiasi delle cento missioni e prova senza vincoli.

signal selected(mission_id: String)

var _region := 1
var _body: VBoxContainer

func _init() -> void:
	page_title = "Laboratorio libero"
	page_icon = "gioco"
	close_text = "Chiudi"

func _page_ready() -> void:
	var pal := UITheme.palette()
	content.add_child(UIKit.body(
		"Qui nessuna risposta è sbagliata: i cubi si posano liberamente e non ci sono pietre magiche da accendere. Serve per esplorare, costruire e ascoltare con calma.",
		19, pal["ink_soft"]))
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	content.add_child(_body)
	_rebuild()

func _rebuild() -> void:
	if _body == null:
		return
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	var pal := UITheme.palette()

	var tabs := GridContainer.new()
	tabs.columns = 5
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	_body.add_child(tabs)
	for r in range(1, 11):
		var b := UIKit.button("%02d" % r, "Primary" if r == _region else "", 44)
		b.tooltip_text = MissionData.REGION_NAMES[r - 1]
		b.pressed.connect(func() -> void:
			Audio.play_sfx("click")
			_region = r
			_rebuild())
		tabs.add_child(b)

	var card := UIKit.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(card)
	var v := UIKit.content(card)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	head.add_child(UIKit.icon_rect(MissionData.REGION_ICONS[_region - 1], 34,
		MissionData.REGION_COLORS[_region - 1]))
	head.add_child(UIKit.header("%02d · %s" % [_region, MissionData.REGION_NAMES[_region - 1]], 24))
	v.add_child(UIKit.body(MissionData.CUSTODIAN_LINES[_region - 1], 16, pal["ink_soft"]))

	var missions: Array = MissionData.region_missions(_region)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	for m in missions:
		var id := str(m.get("id", ""))
		var b := UIKit.button("%s · %s" % [id, str(m.get("title", ""))], "", 54)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = str(m.get("instruction", ""))
		b.pressed.connect(func() -> void:
			Audio.play_sfx("teleport")
			selected.emit(id))
		grid.add_child(b)
