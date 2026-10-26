class_name OverlayPage
extends Control
## Base delle pagine sovrapposte (diario, mappa, pausa, docente, tutorial).
## Layout fluido: funziona da 960×540 fino allo schermo intero.

signal closed

var page_title := "Pagina"
var page_icon := "libro"
var close_text := "Chiudi"
var content: VBoxContainer
var header_right: HBoxContainer
var panel: PanelContainer
var scroll: ScrollContainer
var _closing := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make_theme()
	_build_base()
	_page_ready()
	call_deferred("_focus_default_button")

func _build_base() -> void:
	var pal := UITheme.palette()
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = pal["dim"]
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	panel = PanelContainer.new()
	UITheme.style_panel(panel, "card")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	head.add_child(UIKit.icon_rect(page_icon, 34, pal["gold"]))
	var title_label := UIKit.title(page_title, 34)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title_label)
	header_right = HBoxContainer.new()
	header_right.add_theme_constant_override("separation", 10)
	head.add_child(header_right)
	var close := UIKit.button(close_text, "Primary", 46)
	close.pressed.connect(close_page)
	header_right.add_child(close)

	root.add_child(UIKit.hsep(pal["line"], 2))

	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

func _page_ready() -> void:
	pass

func close_page() -> void:
	if _closing:
		return
	_closing = true
	Audio.play_sfx("back")
	closed.emit()

func _focus_default_button() -> void:
	if content == null:
		return
	await get_tree().process_frame
	var buttons := content.find_children("*", "Button", true, false)
	var best: Button = null
	for b in buttons:
		if not is_instance_valid(b) or (b as Button).disabled or not (b as Button).is_visible_in_tree():
			continue
		if best == null or b.global_position.y < best.global_position.y:
			best = b as Button
	if best:
		best.grab_focus()
	if scroll:
		scroll.scroll_vertical = 0

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		close_page()
		get_viewport().set_input_as_handled()
