class_name FinalScene
extends Control
## Finale: la Stella delle Possibilità si accende dopo cento pietre magiche.

signal closed

var _star: TextureRect
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make_theme()
	_build()
	call_deferred("_setup_star")
	call_deferred("_celebrate")

func _build() -> void:
	var pal := UITheme.palette()
	var gradient := UIKit.gradient_rect(Color("#0C1330"), Color("#3A2A5A"), false)
	gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gradient)

	for i in range(16):
		var size := randi_range(8, 24)
		var s := UIKit.icon_rect("stella_finale", size, Color(1.0, 0.94, 0.72, 0.55))
		s.set_anchors_preset(Control.PRESET_CENTER)
		var angle := randf() * TAU
		var radius := randf_range(120.0, 420.0)
		var offset := Vector2(cos(angle) * radius, sin(angle) * radius * 0.72)
		s.offset_left = offset.x - float(size) * 0.5
		s.offset_top = offset.y - float(size) * 0.5
		s.offset_right = offset.x + float(size) * 0.5
		s.offset_bottom = offset.y + float(size) * 0.5
		add_child(s)
		var tw := create_tween()
		tw.tween_property(s, "modulate:a", randf_range(0.1, 0.3), randf_range(1.2, 2.4))
		tw.tween_property(s, "modulate:a", randf_range(0.75, 1.0), randf_range(1.2, 2.4))
		tw.set_loops()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(900, 0)
	center.add_child(v)

	_star = UIKit.icon_rect("stella_finale", 220, Color("#FFE066"))
	_star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_star)

	var eyebrow := UIKit.label("CENTO PIETRE MAGICHE · UNA STELLA", 18, Color("#FFD166"), true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(eyebrow)

	var title := UIKit.label("La Stella delle Possibilità", 52, Color("#FFF7E8"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := UIKit.label("Hai riacceso tutte le luci di Lumeria.", 26, Color("#9FE8DA"), true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var text := UIKit.label(
		"Forme, numeri, parole, misure, suoni: ogni scoperta è diventata una luce. " +
		"La Stella ora brilla per te, e continuerà a brillare ogni volta che tornerai.",
		21, Color(1.0, 0.97, 0.91, 0.92))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(760, 0)
	text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(text)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 10)
	v.add_child(stats)
	stats.add_child(_stat("Lucciole", SaveGame.collectible_count("fireflies")))
	stats.add_child(_stat("Creature", SaveGame.collectible_count("critters")))
	stats.add_child(_stat("Pietre musicali", SaveGame.collectible_count("stones")))
	stats.add_child(_stat("Pietre magiche", SaveGame.completed_count()))

	v.add_child(UIKit.spacer(8))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var back := UIKit.button("Torna al mondo", "Primary", 56)
	back.custom_minimum_size = Vector2(280, 56)
	back.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		closed.emit())
	row.add_child(back)
	var diary := UIKit.button("Apri il diario", "Gold", 56)
	diary.custom_minimum_size = Vector2(240, 56)
	diary.pressed.connect(func() -> void:
		Audio.play_sfx("click")
		var main := get_tree().current_scene
		if main and main.has_method("open_journal_from_final"):
			main.open_journal_from_final())
	row.add_child(diary)
	back.grab_focus()

func _stat(label_text: String, value: int) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.1)
	s.set_corner_radius_all(999)
	s.set_border_width_all(2)
	s.border_color = Color(1, 0.88, 0.5, 0.5)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", s)
	p.add_child(UIKit.label("%s  %d" % [label_text, value], 17, Color("#FFF3C4"), true))
	return p

func _setup_star() -> void:
	if _star == null:
		return
	_star.pivot_offset = _star.size * 0.5
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_star, "rotation", TAU, 26.0).from(0.0)
	_tween.tween_property(_star, "scale", Vector2(1.06, 1.06), 1.6).from(Vector2.ONE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_property(_star, "scale", Vector2.ONE, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.set_loops()

func _celebrate() -> void:
	Audio.play_sfx("success")
	Audio.play_sfx("rune", 1.12)
	Audio.say("Cento pietre magiche! La Stella delle Possibilità è accesa. Ogni forma, ogni numero, ogni parola e ogni suono hanno trovato la loro luce. Grazie per aver camminato con noi.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
