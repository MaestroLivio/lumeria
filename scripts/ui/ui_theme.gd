class_name UITheme
extends RefCounted

static var _regular: Font
static var _bold: Font
static var _black: Font

static func palette() -> Dictionary:
	if Settings.is_high_contrast():
		return {
			"bg": Color("#070B14"),
			"panel": Color("#111A2E"),
			"panel2": Color("#1B2740"),
			"ink": Color("#FFFFFF"),
			"ink_soft": Color("#D7E3F4"),
			"accent": Color("#FFD166"),
			"accent2": Color("#59E3D0"),
			"gold": Color("#FFD166"),
			"good": Color("#6EE7A8"),
			"warn": Color("#FFB347"),
			"bad": Color("#FF7A7A"),
			"line": Color("#FFE9A8"),
			"hud_bg": Color(0.02, 0.03, 0.06, 0.94),
			"hud_ink": Color("#FFFFFF"),
			"shadow": Color(0, 0, 0, 0.8),
			"dim": Color(0.0, 0.0, 0.0, 0.82),
			"star": Color("#FFE9A8"),
		}
	return {
		"bg": Color("#24304A"),
		"panel": Color("#FFF7E8"),
		"panel2": Color("#F4E7D0"),
		"ink": Color("#3B2A20"),
		"ink_soft": Color("#705C4D"),
		"accent": Color("#E9748A"),
		"accent2": Color("#3FAF9F"),
		"gold": Color("#F2B84B"),
		"good": Color("#5FAE64"),
		"warn": Color("#E39A35"),
		"bad": Color("#D96556"),
		"line": Color("#D8C3A5"),
		"hud_bg": Color(0.11, 0.13, 0.19, 0.82),
		"hud_ink": Color("#FFF7E8"),
		"shadow": Color(0.05, 0.04, 0.03, 0.35),
		"dim": Color(0.05, 0.07, 0.12, 0.66),
		"star": Color("#FFE9A8"),
	}

static func font_regular() -> Font:
	if _regular == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Avenir Next", "Nunito", "Arial Rounded MT Bold", "Helvetica Neue", "Arial"])
		f.font_weight = 500
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.multichannel_signed_distance_field = true
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_regular = f
	return _regular

static func font_bold() -> Font:
	if _bold == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Avenir Next", "Nunito", "Arial Rounded MT Bold", "Helvetica Neue", "Arial"])
		f.font_weight = 700
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		# I Label3D condividono l'atlante del font: con MSDF alcune build di Godot
		# mostrano lo stesso testo su tutte le etichette 3D. Il font 2D resta MSDF.
		f.multichannel_signed_distance_field = false
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_bold = f
	return _bold

static func font_black() -> Font:
	if _black == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Avenir Next", "Nunito", "Arial Rounded MT Bold", "Helvetica Neue", "Arial"])
		f.font_weight = 800
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.multichannel_signed_distance_field = true
		_black = f
	return _black

static func make_theme() -> Theme:
	var p := palette()
	var t := Theme.new()
	t.default_font = font_regular()
	t.default_font_size = Settings.fs(24)

	t.set_color("font_color", "Label", p["ink"])
	t.set_color("default_color", "RichTextLabel", p["ink"])
	t.set_color("font_color", "Button", p["ink"])
	t.set_color("font_hover_color", "Button", p["ink"])
	t.set_color("font_pressed_color", "Button", p["ink"])
	t.set_color("font_focus_color", "Button", p["ink"])
	t.set_color("font_disabled_color", "Button", Color(p["ink"], 0.4))
	t.set_font("font", "Button", font_bold())
	t.set_font_size("font_size", "Button", Settings.fs(24))
	t.set_font_size("font_size", "Label", Settings.fs(24))

	_button_styles(t, "Button", p["panel2"], p["ink"], p["line"], p["gold"])
	_button_styles(t, "Primary", p["accent2"], Color("#FFFDF6"), p["accent2"].darkened(0.2), p["gold"])
	_button_styles(t, "Warm", p["accent"], Color("#FFFDF6"), p["accent"].darkened(0.2), p["gold"])
	_button_styles(t, "Gold", p["gold"], Color("#3B2A20"), p["gold"].darkened(0.15), p["accent2"])
	_button_styles(t, "Danger", p["bad"], Color("#FFFDF6"), p["bad"].darkened(0.2), p["gold"])
	_button_styles(t, "Ghost", Color(0, 0, 0, 0), p["ink"], Color(0, 0, 0, 0), p["gold"])

	t.set_stylebox("panel", "PanelContainer", _panel_style(p["panel"], p["line"], 24, 2, 24, 6))
	t.set_stylebox("panel", "Panel", _panel_style(p["panel"], p["line"], 24, 2, 20, 4))
	t.set_stylebox("panel", "HudPanel", _panel_style(p["hud_bg"], Color(p["hud_ink"], 0.18), 20, 2, 18, 4))
	t.set_stylebox("panel", "Card", _panel_style(p["panel"], p["line"], 26, 3, 26, 8))
	t.set_stylebox("panel", "Chip", _panel_style(p["panel2"], p["line"], 22, 2, 14, 2))
	t.set_stylebox("panel", "TransparentPanel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))

	t.set_color("font_color", "RichTextLabel", p["ink"])
	t.set_color("default_color", "RichTextLabel", p["ink"])
	t.set_stylebox("normal", "RichTextLabel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0, 0))

	t.set_stylebox("panel", "PopupPanel", _panel_style(p["panel"], p["line"], 18, 2, 16, 4))

	# Varianti personalizzate: senza queste mappature Godot non trova gli stili
	# e i controlli ricadono sul tema di base (testo bianco su pannello chiaro).
	for variant in ["Primary", "Warm", "Gold", "Danger", "Ghost"]:
		t.set_type_variation(variant, "Button")
	for variant in ["HudPanel", "Card", "Chip", "TransparentPanel"]:
		t.set_type_variation(variant, "PanelContainer")

	# Slider
	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = p["panel2"].darkened(0.1)
	slider_bg.set_corner_radius_all(8)
	slider_bg.content_margin_top = 6
	slider_bg.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", slider_bg)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = p["accent2"]
	grabber.set_corner_radius_all(14)
	grabber.border_width_left = 3
	grabber.border_width_right = 3
	grabber.border_width_top = 3
	grabber.border_width_bottom = 3
	grabber.border_color = p["gold"]
	grabber.content_margin_left = 10
	grabber.content_margin_right = 10
	grabber.content_margin_top = 10
	grabber.content_margin_bottom = 10
	t.set_stylebox("grabber_area", "HSlider", grabber)
	t.set_stylebox("grabber_area_highlight", "HSlider", grabber)
	t.set_stylebox("focus", "HSlider", _focus_style(p["gold"]))

	# Progress bar
	t.set_stylebox("background", "ProgressBar", _panel_style(p["panel2"], p["line"], 10, 2, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _panel_style(p["accent2"], p["accent2"], 10, 0, 0, 0))
	t.set_color("font_color", "ProgressBar", p["ink"])
	t.set_font_size("font_size", "ProgressBar", Settings.fs(18))

	# Scrollbar
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(p["ink"], 0.08)
	scroll_bg.set_corner_radius_all(8)
	t.set_stylebox("scroll", "VScrollBar", scroll_bg)
	var grab := StyleBoxFlat.new()
	grab.bg_color = p["ink_soft"]
	grab.set_corner_radius_all(8)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)

	# Line edit (pannello docente / import)
	var le := StyleBoxFlat.new()
	le.bg_color = p["panel2"]
	le.border_color = p["line"]
	le.set_border_width_all(2)
	le.set_corner_radius_all(10)
	le.content_margin_left = 12
	le.content_margin_right = 12
	le.content_margin_top = 8
	le.content_margin_bottom = 8
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", _focus_style(p["gold"]))
	t.set_color("font_color", "LineEdit", p["ink"])
	t.set_color("caret_color", "LineEdit", p["accent2"])

	return t

static func _button_styles(t: Theme, type: String, bg: Color, fg: Color, border: Color, focus: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(18)
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 9
	normal.content_margin_bottom = 9
	normal.shadow_color = Color(0, 0, 0, 0.16)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0, 3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)
	hover.border_color = focus
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.12)
	pressed.shadow_size = 0
	pressed.content_margin_top = 11
	pressed.content_margin_bottom = 7
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(bg, 0.35)
	disabled.border_color = Color(border, 0.35)
	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = Color(0, 0, 0, 0)
	focus_sb.set_corner_radius_all(20)
	focus_sb.set_border_width_all(4)
	focus_sb.border_color = focus
	focus_sb.set_expand_margin_all(3)
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	t.set_stylebox("focus", type, focus_sb)
	t.set_color("font_color", type, fg)
	t.set_color("font_hover_color", type, fg)
	t.set_color("font_pressed_color", type, fg)
	t.set_color("font_focus_color", type, fg)
	t.set_color("font_disabled_color", type, Color(fg, 0.5))

static func _panel_style(bg: Color, border: Color, radius: int, border_w: int, margin: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.22)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 4)
	return s

static func _focus_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = color
	s.set_border_width_all(3)
	s.set_corner_radius_all(10)
	return s

static func style_button(btn: Button, variant: String) -> void:
	match variant.to_lower():
		"primary": btn.theme_type_variation = "Primary"
		"warm": btn.theme_type_variation = "Warm"
		"gold": btn.theme_type_variation = "Gold"
		"danger": btn.theme_type_variation = "Danger"
		"ghost": btn.theme_type_variation = "Ghost"
		_: btn.theme_type_variation = ""

static func style_panel(panel: PanelContainer, variant: String) -> void:
	match variant:
		"card": panel.theme_type_variation = "Card"
		"hud": panel.theme_type_variation = "HudPanel"
		"chip": panel.theme_type_variation = "Chip"
		_: panel.theme_type_variation = ""
