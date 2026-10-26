class_name MapPage
extends OverlayPage
## Mappa delle regioni: viaggio rapido e panoramica dei progressi.

signal travel(region: int)

func _init() -> void:
	page_title = "Mappa delle regioni"
	page_icon = "bussola"
	close_text = "Chiudi"

func _page_ready() -> void:
	var pal := UITheme.palette()
	var hub := UIKit.button("Hub", "Primary", 46)
	hub.custom_minimum_size = Vector2(96, 46)
	hub.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		travel.emit(0))
	header_right.add_child(hub)
	header_right.move_child(hub, 0)
	content.add_child(UIKit.body(
		"Dieci regioni, tutte aperte. Scegli dove andare: il viaggio è immediato e non consuma nulla.",
		18, pal["ink_soft"]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for region in range(1, 11):
		grid.add_child(_region_card(region))
	var note := UIKit.label("Suggerimento: dalla mappa puoi raggiungere anche una regione già visitata. Le missioni restano sempre disponibili.", 15, pal["ink_soft"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)

func _region_card(region: int) -> PanelContainer:
	var pal := UITheme.palette()
	var color: Color = MissionData.REGION_COLORS[region - 1]
	var done := SaveGame.completed_in_region(region)
	var card := UIKit.card(14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UIKit.content(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	h.add_child(UIKit.icon_rect(MissionData.REGION_ICONS[region - 1], 34, color))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	h.add_child(names)
	names.add_child(UIKit.label("%02d · %s" % [region, MissionData.REGION_NAMES[region - 1]], 18, pal["ink"], true))
	names.add_child(UIKit.label("Custode %s · %d/10 pietre magiche" % [MissionData.CUSTODIANS[region - 1], done], 14, pal["ink_soft"]))
	var go := UIKit.button("Vai", "Primary", 38)
	go.custom_minimum_size = Vector2(86, 38)
	go.focus_mode = Control.FOCUS_ALL
	go.pressed.connect(func() -> void:
		Audio.play_sfx("teleport")
		travel.emit(region))
	h.add_child(go)
	return card
