class_name UIKit
extends RefCounted

static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func label(text: String, size: int = 0, color: Color = Color.TRANSPARENT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UITheme.font_bold() if bold else UITheme.font_regular())
	if size > 0:
		l.add_theme_font_size_override("font_size", Settings.fs(size))
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 4)
	return l

static func title(text: String, size: int = 52) -> Label:
	var l := label(text, size, UITheme.palette()["ink"], true)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l

static func header(text: String, size: int = 30) -> Label:
	return label(text, size, UITheme.palette()["accent2"], true)

static func body(text: String, size: int = 24, color: Color = Color.TRANSPARENT) -> Label:
	var c: Color = UITheme.palette()["ink_soft"] if color.a <= 0.0 else color
	var l := label(text, size, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func button(text: String, variant: String = "", min_height: int = 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", UITheme.font_bold())
	UITheme.style_button(b, variant)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

static func icon_button(icon_name: String, text: String, variant: String = "") -> Button:
	var b := button(text, variant, 60)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 14)
	var tex := IconLibrary.texture(icon_name, UITheme.palette()["ink"])
	if tex:
		b.icon = tex
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 30)
	return b

static func spacer(h: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hspacer(w: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hsep(color: Color = Color.TRANSPARENT, thickness: int = 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = UITheme.palette()["line"] if color.a <= 0.0 else color
	r.custom_minimum_size = Vector2(0, thickness)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func card(margin: int = 22, variant: String = "card") -> PanelContainer:
	var p := PanelContainer.new()
	UITheme.style_panel(p, variant)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	p.set_meta("content", v)
	return p

static func content(panel: PanelContainer) -> VBoxContainer:
	return panel.get_meta("content") as VBoxContainer

static func section(title_text: String, subtitle: String = "") -> PanelContainer:
	var p := card()
	var v := content(p)
	v.add_child(header(title_text, 28))
	if subtitle != "":
		v.add_child(body(subtitle, 21))
	return p

static func overlay_root(min_width: int = 900, min_height: int = 600, dim: bool = true) -> Dictionary:
	var root := Control.new()
	full_rect(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	if dim:
		var bg := ColorRect.new()
		full_rect(bg)
		bg.color = UITheme.palette()["dim"]
		bg.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(bg)
	var center := CenterContainer.new()
	full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)
	var panel := PanelContainer.new()
	UITheme.style_panel(panel, "card")
	panel.custom_minimum_size = Vector2(min_width, min_height)
	center.add_child(panel)
	return {"root": root, "panel": panel, "center": center}

static func scroll_page() -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	scroll.add_child(v)
	return {"scroll": scroll, "vbox": v}

static func toggle_row(text: String, value: bool, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := label(text, 23, UITheme.palette()["ink"])
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := button("SÌ" if value else "NO", "Primary" if value else "", 50)
	b.custom_minimum_size = Vector2(130, 50)
	b.pressed.connect(func() -> void:
		value = not value
		b.text = "SÌ" if value else "NO"
		UITheme.style_button(b, "Primary" if value else "")
		Audio.play_sfx("click")
		on_change.call(value)
	)
	row.add_child(b)
	return row

static func slider_row(text: String, minv: float, maxv: float, step: float, value: float,
		fmt_fn: Callable, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := label(text, 23, UITheme.palette()["ink"])
	l.custom_minimum_size = Vector2(300, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(280, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.focus_mode = Control.FOCUS_ALL
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_child(s)
	var vl := label(fmt_fn.call(value), 22, UITheme.palette()["accent2"], true)
	vl.custom_minimum_size = Vector2(110, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(vl)
	s.value_changed.connect(func(v: float) -> void:
		vl.text = fmt_fn.call(v)
		on_change.call(v)
	)
	return row

static func cycle_row(text: String, options: Array, index: int, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := label(text, 23, UITheme.palette()["ink"])
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	index = clampi(index, 0, maxi(0, options.size() - 1))
	var b := button("‹  " + str(options[index]) + "  ›", "", 50)
	b.custom_minimum_size = Vector2(260, 50)
	b.pressed.connect(func() -> void:
		index = (index + 1) % options.size()
		b.text = "‹  " + str(options[index]) + "  ›"
		Audio.play_sfx("click")
		on_change.call(index)
	)
	row.add_child(b)
	return row

static func chip(text: String, bg: Color = Color.TRANSPARENT, fg: Color = Color.TRANSPARENT) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	var pal := UITheme.palette()
	s.bg_color = pal["panel2"] if bg.a <= 0.0 else bg
	s.set_corner_radius_all(999)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(pal["line"], 0.7)
	p.add_theme_stylebox_override("panel", s)
	var l := label(text, 19, pal["ink"] if fg.a <= 0.0 else fg, true)
	p.add_child(l)
	return p

static func glyph_chip(glyph: String, size: int = 46) -> PanelContainer:
	var pal := UITheme.palette()
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(pal["ink"], 0.94)
	s.set_corner_radius_all(12)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(1, 1, 1, 0.3)
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(size, size)
	var l := label(glyph, 20, Color(1, 1, 1, 1), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

static func prompt(glyph: String, text: String, size: int = 21) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(glyph_chip(glyph, 42))
	var l := label(text, size, UITheme.palette()["hud_ink"], true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return h

static func icon_texture(icon_name: String, tint: Color = Color.WHITE) -> Texture2D:
	return IconLibrary.texture(icon_name, tint)

static func icon_rect(icon_name: String, size: int = 48, tint: Color = Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = IconLibrary.texture(icon_name, tint if tint.a > 0.0 else UITheme.palette()["ink"])
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func gradient_rect(from: Color, to: Color, horizontal: bool = true) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, from)
	g.set_color(1, to)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 512
	gt.height = 512
	if horizontal:
		gt.fill_from = Vector2(0, 0.5)
		gt.fill_to = Vector2(1, 0.5)
	else:
		gt.fill_from = Vector2(0.5, 0)
		gt.fill_to = Vector2(0.5, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

static func focus(control: Control) -> void:
	if control and is_instance_valid(control):
		control.grab_focus()

static func fade_in(c: CanvasItem, duration: float = 0.18) -> void:
	if bool(Settings.get_setting("reduce_motion", false)):
		c.modulate.a = 1.0
		return
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)

static func panel_width(c: Control) -> float:
	return 1000.0
