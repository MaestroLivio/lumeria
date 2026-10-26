class_name LumeriaHud
extends CanvasLayer
## Interfaccia durante l'esplorazione: regione, pietre magiche, prompt, sottotitoli e avvisi.

var _region_label: Label
var _custodian_label: Label
var _progress_label: Label
var _bar: ProgressBar
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _subtitle_panel: PanelContainer
var _subtitle_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _counter_label: Label
var _subtitle_time := 0.0
var _toast_time := 0.0
var _root: Control

func _ready() -> void:
	layer = 5
	_build()
	Audio.subtitle.connect(_on_subtitle)

func _build() -> void:
	var pal := UITheme.palette()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make_theme()
	add_child(_root)

	var region := PanelContainer.new()
	UITheme.style_panel(region, "hud")
	region.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	region.offset_left = 22
	region.offset_top = 18
	region.offset_right = 430
	region.offset_bottom = 126
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(region)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 3)
	region.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	rv.add_child(top)
	var icon := UIKit.icon_rect("leaf", 26, pal["gold"])
	top.add_child(icon)
	_region_label = UIKit.label("Hub di Lumeria", 21, pal["hud_ink"], true)
	_region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_region_label)
	_counter_label = UIKit.label("0 / 100", 18, pal["gold"], true)
	top.add_child(_counter_label)
	_custodian_label = UIKit.label("Benvenuto, esploratore!", 16, Color(pal["hud_ink"], 0.8))
	rv.add_child(_custodian_label)
	_bar = ProgressBar.new()
	_bar.max_value = 100
	_bar.value = 0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 10)
	rv.add_child(_bar)
	_progress_label = UIKit.label("", 15, Color(pal["hud_ink"], 0.72))
	rv.add_child(_progress_label)

	var chips := HBoxContainer.new()
	chips.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	chips.offset_left = -300
	chips.offset_top = 20
	chips.offset_right = -22
	chips.offset_bottom = 64
	chips.alignment = BoxContainer.ALIGNMENT_END
	chips.add_theme_constant_override("separation", 8)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(chips)
	chips.add_child(UIKit.prompt(Settings.layout_glyphs()["start"], "Pausa", 15))
	chips.add_child(UIKit.prompt(Settings.layout_glyphs()["back"], "Diario", 15))

	_prompt_panel = PanelContainer.new()
	UITheme.style_panel(_prompt_panel, "hud")
	_prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -310
	_prompt_panel.offset_right = 310
	_prompt_panel.offset_top = -96
	_prompt_panel.offset_bottom = -32
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_panel.visible = false
	_root.add_child(_prompt_panel)
	var ph := HBoxContainer.new()
	ph.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_theme_constant_override("separation", 12)
	_prompt_panel.add_child(ph)
	ph.add_child(UIKit.glyph_chip(Settings.layout_glyphs()["accept"], 40))
	_prompt_label = UIKit.label("", 21, pal["hud_ink"], true)
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(_prompt_label)

	_subtitle_panel = PanelContainer.new()
	UITheme.style_panel(_subtitle_panel, "hud")
	_subtitle_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.offset_left = -430
	_subtitle_panel.offset_right = 430
	_subtitle_panel.offset_top = -176
	_subtitle_panel.offset_bottom = -110
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.visible = false
	_root.add_child(_subtitle_panel)
	_subtitle_label = UIKit.label("", 20, pal["hud_ink"], true)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_panel.add_child(_subtitle_label)

	_toast_panel = PanelContainer.new()
	UITheme.style_panel(_toast_panel, "card")
	_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.offset_left = -260
	_toast_panel.offset_right = 260
	_toast_panel.offset_top = 22
	_toast_panel.offset_bottom = 82
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false
	_root.add_child(_toast_panel)
	_toast_label = UIKit.label("", 20, pal["ink"], true)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)

func set_region(region: int) -> void:
	if _region_label == null:
		return
	if region <= 0:
		_region_label.text = "Hub di Lumeria"
		_custodian_label.text = "La fontana delle cento luci"
		return
	var idx := region - 1
	_region_label.text = MissionData.REGION_NAMES[idx]
	_custodian_label.text = "Custode: " + MissionData.CUSTODIANS[idx]
	_counter_label.text = "%d / 100" % SaveGame.completed_count()
	var done := SaveGame.completed_in_region(region)
	_bar.value = SaveGame.completed_count()
	_progress_label.text = "Regione: %d pietre magiche su 10" % done

func set_progress() -> void:
	if _bar == null:
		return
	_bar.value = SaveGame.completed_count()
	_counter_label.text = "%d / 100" % SaveGame.completed_count()

func set_prompt(text: String) -> void:
	if _prompt_panel == null:
		return
	_prompt_panel.visible = text != ""
	_prompt_label.text = text

func toast(text: String, seconds: float = 2.2) -> void:
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_time = seconds

func _on_subtitle(text: String, seconds: float) -> void:
	_subtitle_label.text = text
	_subtitle_panel.visible = bool(Settings.get_setting("subtitles", true))
	_subtitle_time = seconds

func _process(delta: float) -> void:
	if _subtitle_time > 0.0:
		_subtitle_time -= delta
		if _subtitle_time <= 0.0:
			_subtitle_panel.visible = false
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast_panel.visible = false

func hide_hud() -> void:
	_root.visible = false

func show_hud() -> void:
	_root.visible = true
