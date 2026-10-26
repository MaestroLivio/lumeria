class_name JournalPage
extends OverlayPage
## Diario delle pietre magiche: stato delle dieci regioni, ascolto delle missioni e incontri.

func _init() -> void:
	page_title = "Diario delle pietre magiche"
	page_icon = "libro"
	close_text = "Chiudi"

func _page_ready() -> void:
	var pal := UITheme.palette()
	content.add_child(UIKit.body(
		"Qui puoi vedere tutte le pietre magiche che hai acceso. Tocca una pietra magica per ascoltarne il nome: nessuna pietra magica è mai perduta.",
		19, pal["ink_soft"]))

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	content.add_child(stats)
	stats.add_child(_stat("stella_finale", "Pietre magiche", "%d / 100" % SaveGame.completed_count(), pal["gold"]))
	stats.add_child(_stat("firefly", "Lucciole", str(SaveGame.collectible_count("fireflies")), pal["accent2"]))
	stats.add_child(_stat("cuore", "Creature", str(SaveGame.collectible_count("critters")), pal["accent"]))
	stats.add_child(_stat("nota", "Pietre", str(SaveGame.collectible_count("stones")), Color("#B58CD6")))

	for region in range(1, 11):
		content.add_child(_region_card(region))

	content.add_child(UIKit.spacer(6))
	var finale := UIKit.button("Rivedi il finale, se la Stella è completa", "", 50)
	finale.disabled = SaveGame.completed_count() < 100
	finale.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		if SaveGame.completed_count() >= 100:
			var main := get_tree().current_scene
			if main and main.has_method("show_final_scene"):
				main.show_final_scene())
	content.add_child(finale)

func _stat(icon: String, label_text: String, value: String, tint: Color) -> PanelContainer:
	var pal := UITheme.palette()
	var p := PanelContainer.new()
	UITheme.style_panel(p, "chip")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	h.add_child(UIKit.icon_rect(icon, 28, tint))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UIKit.label(label_text, 15, pal["ink_soft"]))
	v.add_child(UIKit.label(value, 20, pal["ink"], true))
	return p

func _region_card(region: int) -> PanelContainer:
	var pal := UITheme.palette()
	var missions: Array = MissionData.region_missions(region)
	var done := SaveGame.completed_in_region(region)
	var color: Color = MissionData.REGION_COLORS[region - 1]
	var card := UIKit.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UIKit.content(card)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	head.add_child(UIKit.icon_rect(MissionData.REGION_ICONS[region - 1], 34, color))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	names.add_child(UIKit.label("%02d · %s" % [region, MissionData.REGION_NAMES[region - 1]], 22, pal["ink"], true))
	names.add_child(UIKit.label("Custode: " + MissionData.CUSTODIANS[region - 1], 16, pal["ink_soft"]))
	head.add_child(UIKit.chip("%d / 10" % done, pal["panel2"], pal["accent2"]))
	var listen := UIKit.button("Ascolta", "", 42)
	listen.custom_minimum_size = Vector2(130, 42)
	listen.focus_mode = Control.FOCUS_ALL
	listen.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		Audio.say("%s. Custode %s. %s. Pietre magiche accese: %d su dieci." % [
			MissionData.REGION_NAMES[region - 1], MissionData.CUSTODIANS[region - 1],
			MissionData.CUSTODIAN_LINES[region - 1], done]))
	head.add_child(listen)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for j in range(missions.size()):
		var m: Dictionary = missions[j]
		var id := str(m.get("id", "%03d" % (j + 1)))
		var completed := SaveGame.is_mission_completed(id)
		var b := UIKit.button(str(j + 1), "", 48)
		b.custom_minimum_size = Vector2(0, 48)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_override("font", UITheme.font_bold())
		var tex := IconLibrary.texture("stella_finale", pal["gold"] if completed else Color(0.42, 0.38, 0.32, 0.55))
		if tex:
			b.icon = tex
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 24)
		b.tooltip_text = str(m.get("title", ""))
		b.pressed.connect(func() -> void:
			Audio.play_sfx("click")
			Audio.say("Pietra magica numero %d. %s. %s" % [j + 1, str(m.get("title", "")),
				"Accesa." if completed else "Ancora da accendere. La trovi nel mondo."]))
		grid.add_child(b)

	var bar := ProgressBar.new()
	bar.max_value = 10
	bar.value = done
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	v.add_child(bar)
	return card
