class_name IconLibrary
extends RefCounted
## Pittogrammi vettoriali generati a runtime (SVG -> texture).
## Nessun asset esterno, licenza originale del progetto.

static var _cache: Dictionary = {}

static func texture(icon_name: String, tint: Color = Color.WHITE) -> Texture2D:
	var key := icon_name + "_" + tint.to_html(false)
	if _cache.has(key):
		return _cache[key]
	var svg := svg(icon_name, tint)
	var img := Image.new()
	var err := img.load_svg_from_buffer(svg.to_utf8_buffer(), 2.0)
	if err != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func svg(icon_name: String, c: Color) -> String:
	var d := c.darkened(0.42)
	var l := c.lightened(0.28)
	var body := _body(icon_name, c, d, l)
	var s := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
	s += '<g stroke="' + d.to_html(false) + '" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">'
	s += body
	s += '</g></svg>'
	return s

static func _body(n: String, c: Color, d: Color, l: Color) -> String:
	var h := c.to_html(false)
	var hd := d.to_html(false)
	var hl := l.to_html(false)
	var white := "fff9ec"
	if n.length() == 5 and n.begins_with("dado"):
		var k := int(n.substr(4))
		if k >= 1 and k <= 6:
			return _dice(k)
	if n.length() == 5 and n.begins_with("mano"):
		var k2 := int(n.substr(4))
		if k2 >= 1 and k2 <= 5:
			return _hand(k2, h)
	match n:
		"fungo":
			return '<ellipse cx="64" cy="50" rx="42" ry="26" fill="#d9674a"/><circle cx="46" cy="44" r="7" fill="#f7f2e7"/><circle cx="80" cy="54" r="5" fill="#f7f2e7"/><rect x="50" y="66" width="28" height="48" rx="12" fill="#f2e3c8"/>'
		"cibo":
			return '<circle cx="64" cy="70" r="40" fill="#fff9ec"/><circle cx="64" cy="70" r="28" fill="#f4e4c1"/><path d="M20 30 V92 M36 30 V58 M28 30 V58" fill="none" stroke-width="6"/><path d="M96 30 V92" fill="none" stroke-width="8"/><path d="M96 30 C112 40 112 58 96 62" fill="none" stroke-width="6"/><circle cx="64" cy="70" r="12" fill="#d95c5c"/>'
		"gioco":
			return '<circle cx="56" cy="70" r="34" fill="#%s"/><path d="M56 40 L65 58 L84 60 L70 72 L74 92 L56 82 L38 92 L42 72 L28 60 L47 58 Z" fill="#fff9ec" opacity="0.9"/><rect x="88" y="28" width="16" height="58" rx="8" fill="#4c86c6" transform="rotate(18 96 57)"/>' % h

		"circle":
			return '<circle cx="64" cy="64" r="43" fill="#' + h + '"/>'
		"square":
			return '<rect x="23" y="23" width="82" height="82" rx="12" fill="#' + h + '"/>'
		"triangle":
			return '<path d="M64 20 L110 104 L18 104 Z" fill="#' + h + '"/>'
		"star":
			return '<path d="' + _star(64, 66, 46, 20, 5) + '" fill="#' + h + '"/>'
		"star4":
			return '<path d="' + _star(64, 66, 46, 16, 4) + '" fill="#' + h + '"/>'
		"hexagon":
			return '<path d="' + _poly(64, 64, 45, 6, 30) + '" fill="#' + h + '"/>'
		"diamond":
			return '<path d="M64 16 L108 64 L64 112 L20 64 Z" fill="#' + h + '"/>'
		"flower":
			var petals := ""
			for i in range(5):
				var a := deg_to_rad(-90 + i * 72)
				petals += '<circle cx="%.1f" cy="%.1f" r="20" fill="#%s"/>' % [64 + cos(a) * 27, 64 + sin(a) * 27, h]
			petals += '<circle cx="64" cy="64" r="16" fill="#' + white + '"/>'
			petals += '<circle cx="64" cy="64" r="8" fill="#' + hd + '"/>'
			return petals
		"leaf":
			return '<path d="M24 104 C20 48 58 18 108 20 C108 76 74 108 24 104 Z" fill="#' + h + '"/><path d="M32 98 L92 34" fill="none"/>'
		"shell":
			return '<path d="M16 100 C16 40 44 16 64 16 C84 16 112 40 112 100 Z" fill="#' + h + '"/><path d="M64 100 L44 34 M64 100 L64 22 M64 100 L84 34" fill="none" stroke-width="4"/>'
		"apple":
			return '<path d="M64 36 C42 18 20 36 24 66 C27 92 48 110 64 110 C80 110 101 92 104 66 C108 36 86 18 64 36 Z" fill="#e6554b"/><path d="M66 34 C70 20 82 14 92 16 C90 28 80 36 66 34 Z" fill="#6fb85b"/><rect x="62" y="22" width="7" height="18" rx="3" fill="#8a5a35"/>'
		"pear":
			return '<path d="M64 30 C52 30 50 46 52 56 C36 66 30 80 34 94 C39 110 88 110 94 94 C98 80 92 66 76 56 C78 46 76 30 64 30 Z" fill="#c9d86a"/><path d="M64 28 C68 18 78 14 86 16 C82 26 74 31 64 28 Z" fill="#6fb85b"/>'
		"banana":
			return '<path d="M24 36 C34 82 74 106 108 88 C96 108 62 116 40 96 C20 78 18 54 24 36 Z" fill="#f4cf4a"/>'
		"ball":
			return '<circle cx="64" cy="64" r="43" fill="#%s"/><path d="M64 21 L82 51 L104 64 L82 77 L64 107 L46 77 L24 64 L46 51 Z" fill="none" stroke-width="3"/>' % h
		"top":
			return '<path d="M44 34 L84 34 L96 96 L32 96 Z" fill="#%s"/><rect x="58" y="12" width="12" height="26" rx="6" fill="#%s"/><circle cx="64" cy="62" r="10" fill="#%s"/>' % [h, hd, hl]
		"train":
			return '<rect x="16" y="42" width="72" height="46" rx="10" fill="#%s"/><rect x="44" y="20" width="26" height="26" rx="6" fill="#%s"/><rect x="86" y="56" width="26" height="30" rx="6" fill="#%s"/><circle cx="34" cy="98" r="10" fill="#%s"/><circle cx="72" cy="98" r="10" fill="#%s"/><circle cx="100" cy="94" r="8" fill="#%s"/>' % [h, hd, hl, hd, hd, hd]
		"sun":
			var rays := ""
			for i in range(8):
				var a := deg_to_rad(i * 45)
				var x1 := 64 + cos(a) * 38
				var y1 := 64 + sin(a) * 38
				var x2 := 64 + cos(a) * 54
				var y2 := 64 + sin(a) * 54
				rays += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/>' % [x1, y1, x2, y2]
			return rays + '<circle cx="64" cy="64" r="31" fill="#f6c74c"/>'
		"sunrise":
			return '<path d="M18 92 H110" fill="none"/><path d="M34 92 A30 30 0 0 1 94 92 Z" fill="#f6c74c"/><path d="M64 22 V42 M22 52 L34 62 M106 52 L94 62" fill="none"/>'
		"sunset":
			return '<path d="M18 92 H110" fill="none"/><path d="M34 92 A30 30 0 0 1 94 92 Z" fill="#ef9450"/><path d="M20 24 L44 36 M108 24 L84 36" fill="none"/>'
		"moon":
			return '<path d="M80 20 C46 24 30 46 32 70 C35 96 58 108 82 104 C62 96 50 78 52 58 C54 38 66 26 80 20 Z" fill="#f6e6a8"/>'
		"night":
			return '<path d="M78 20 C48 24 34 44 36 66 C39 90 60 102 82 98 C62 90 52 74 54 56 C56 38 66 26 78 20 Z" fill="#f6e6a8"/><circle cx="96" cy="34" r="5" fill="#fff3b0"/><circle cx="106" cy="58" r="3" fill="#fff3b0"/>'
		"bird":
			return '<path d="M28 70 C34 46 60 36 84 44 C96 34 108 38 112 46 C104 50 98 54 94 62 C88 84 62 96 42 86 C34 82 28 76 28 70 Z" fill="#%s"/><path d="M64 54 C72 44 88 46 94 58" fill="none"/><path d="M112 46 L124 52 L112 56 Z" fill="#ef9450"/>' % h
		"mole":
			return '<path d="M24 88 C24 58 44 38 68 38 C92 38 108 58 108 86 C108 100 92 106 66 106 C42 106 24 102 24 88 Z" fill="#9a6b4d"/><circle cx="52" cy="68" r="5" fill="#2b201b"/><circle cx="82" cy="68" r="5" fill="#2b201b"/><path d="M60 88 Q68 94 76 88" fill="none"/>'
		"sheep":
			return '<circle cx="40" cy="58" r="22" fill="#f7f2e7"/><circle cx="66" cy="46" r="24" fill="#f7f2e7"/><circle cx="92" cy="62" r="20" fill="#f7f2e7"/><circle cx="50" cy="82" r="22" fill="#f7f2e7"/><circle cx="80" cy="84" r="22" fill="#f7f2e7"/><circle cx="86" cy="56" r="16" fill="#5a4a42"/><circle cx="90" cy="53" r="3" fill="#fff"/><path d="M102 58 Q110 60 104 64" fill="none"/>'
		"kite":
			return '<path d="M64 14 L100 58 L64 102 L28 58 Z" fill="#%s"/><path d="M64 14 V102 M28 58 H100" fill="none" stroke-width="3"/><path d="M64 102 C54 114 76 116 68 124" fill="none"/>' % h
		"candle":
			return '<rect x="50" y="48" width="28" height="62" rx="7" fill="#f4e4c1"/><path d="M64 46 C50 34 58 20 64 14 C70 22 78 34 64 46 Z" fill="#f6a23c"/><circle cx="64" cy="60" r="4" fill="#fff3b0"/>'
		"ship":
			return '<path d="M18 82 H110 L96 106 H32 Z" fill="#a26a48"/><rect x="61" y="16" width="6" height="66" fill="#8a5a35"/><path d="M67 22 L104 50 L67 62 Z" fill="#f7f2e7"/><path d="M59 34 L26 54 L59 64 Z" fill="#e6554b"/>'
		"cloud":
			return '<circle cx="40" cy="72" r="24" fill="#eef3f7"/><circle cx="64" cy="56" r="28" fill="#eef3f7"/><circle cx="92" cy="74" r="22" fill="#eef3f7"/><rect x="28" y="68" width="76" height="26" rx="13" fill="#eef3f7"/>'
		"rock":
			return '<path d="M22 96 L34 54 L58 32 L88 40 L108 70 L100 100 Z" fill="#9aa3ad"/><path d="M58 32 L60 66 L34 54 M60 66 L88 40 M60 66 L100 100" fill="none" stroke-width="3"/>'
		"butterfly":
			return '<path d="M60 62 C34 32 14 40 18 64 C21 84 44 88 60 74 Z" fill="#%s"/><path d="M68 62 C94 32 114 40 110 64 C107 84 84 88 68 74 Z" fill="#%s"/><path d="M62 54 C52 76 52 92 64 108 C76 92 76 76 66 54 Z" fill="#%s"/><path d="M62 54 Q54 40 46 36 M66 54 Q74 40 82 36" fill="none"/>' % [h, hl, hd]
		"rabbit":
			return '<ellipse cx="46" cy="50" rx="12" ry="32" fill="#%s"/><ellipse cx="82" cy="50" rx="12" ry="32" fill="#%s"/><circle cx="64" cy="82" r="34" fill="#%s"/><circle cx="52" cy="76" r="4" fill="#3a2a22"/><circle cx="76" cy="76" r="4" fill="#3a2a22"/><path d="M60 90 Q64 94 68 90" fill="none"/>' % [h, h, h]
		"carrot":
			return '<path d="M54 42 L84 44 L70 112 L54 100 Z" fill="#ef8a3a"/><path d="M56 42 C46 26 44 16 50 10 C62 18 64 28 62 40 M68 42 C70 26 78 16 88 14 C90 28 82 38 76 44" fill="#6fb85b"/>'
		"ladybug":
			return '<ellipse cx="64" cy="70" rx="40" ry="38" fill="#d94f45"/><path d="M64 34 V106" fill="none"/><circle cx="64" cy="38" r="17" fill="#3a2a22"/><circle cx="45" cy="62" r="7" fill="#3a2a22"/><circle cx="83" cy="62" r="7" fill="#3a2a22"/><circle cx="48" cy="86" r="6" fill="#3a2a22"/><circle cx="80" cy="86" r="6" fill="#3a2a22"/>'
		"bell":
			return '<path d="M28 88 C40 78 40 60 42 48 C45 28 56 18 64 18 C72 18 83 28 86 48 C88 60 88 78 100 88 Z" fill="#e8b84a"/><circle cx="64" cy="98" r="8" fill="#a77b25"/><rect x="58" y="10" width="12" height="12" rx="6" fill="#a77b25"/>'
		"firefly":
			return '<circle cx="64" cy="66" r="26" fill="#f6e27a"/><circle cx="64" cy="66" r="16" fill="#fff3b0"/><ellipse cx="44" cy="48" rx="18" ry="10" transform="rotate(-30 44 48)" fill="#eef3f7" opacity="0.8"/><ellipse cx="84" cy="48" rx="18" ry="10" transform="rotate(30 84 48)" fill="#eef3f7" opacity="0.8"/><circle cx="58" cy="62" r="3" fill="#6b5a2a"/><circle cx="70" cy="62" r="3" fill="#6b5a2a"/>'
		"lantern":
			return '<rect x="40" y="32" width="48" height="62" rx="10" fill="#3f4a5a"/><rect x="48" y="42" width="32" height="44" rx="7" fill="#ffe9a8"/><rect x="34" y="24" width="60" height="12" rx="6" fill="#3f4a5a"/><path d="M64 16 V24" fill="none"/><circle cx="64" cy="64" r="10" fill="#f6c74c"/>'
		"lantern_empty":
			return '<rect x="40" y="32" width="48" height="62" rx="10" fill="#3f4a5a"/><rect x="48" y="42" width="32" height="44" rx="7" fill="#303a48"/><rect x="34" y="24" width="60" height="12" rx="6" fill="#3f4a5a"/><path d="M64 16 V24" fill="none"/>'
		"lantern_full":
			return '<rect x="40" y="32" width="48" height="62" rx="10" fill="#3f4a5a"/><rect x="48" y="42" width="32" height="44" rx="7" fill="#ffe9a8"/><circle cx="57" cy="60" r="5" fill="#f6e27a"/><circle cx="71" cy="72" r="5" fill="#f6e27a"/><rect x="34" y="24" width="60" height="12" rx="6" fill="#3f4a5a"/>'
		"gem":
			return '<path d="M64 16 L106 46 L84 108 L44 108 L22 46 Z" fill="#%s"/><path d="M22 46 H106 M64 16 L44 108 M64 16 L84 108 M44 108 L64 46 L84 108" fill="none" stroke-width="3"/>' % h
		"hand":
			return '<path d="M42 62 V36 C42 28 54 28 54 36 V58 M54 56 V28 C54 20 66 20 66 28 V56 M66 56 V34 C66 26 78 26 78 34 V60 M78 60 V44 C78 36 90 38 90 46 V78 C90 100 74 112 58 108 C42 104 32 92 32 78 V66 C32 56 46 56 46 66" fill="#%s"/>' % h
		"foot":
			return '<path d="M48 20 C60 16 68 26 66 42 C65 54 60 58 60 70 C60 82 54 90 46 90 C36 90 32 80 34 66 C36 52 38 48 38 38 C38 28 42 22 48 20 Z" fill="#%s"/><circle cx="44" cy="100" r="7" fill="#%s"/><circle cx="58" cy="98" r="6" fill="#%s"/><circle cx="70" cy="94" r="5" fill="#%s"/>' % [h, h, h, h]
		"mountain":
			return '<path d="M8 104 L48 34 L70 68 L88 44 L122 104 Z" fill="#8d9aa8"/><path d="M34 104 L78 60 L112 104 Z" fill="#%s"/>' % h
		"sprout":
			return '<path d="M64 110 V58" fill="none"/><path d="M62 68 C42 68 28 56 26 38 C48 36 62 48 62 68 Z" fill="#6fb85b"/><path d="M66 58 C86 58 100 46 102 28 C80 26 66 38 66 58 Z" fill="#8ccb7a"/>'
		"seed":
			return '<ellipse cx="64" cy="54" rx="22" ry="30" fill="#b98a55" transform="rotate(-20 64 54)"/><path d="M16 96 H112" fill="none" stroke-width="7"/>'
		"germoglio":
			return '<path d="M64 104 V54" fill="none"/><path d="M63 66 C46 66 34 54 34 38 C54 38 63 50 63 66 Z" fill="#8ccb7a"/><path d="M65 58 C82 58 94 46 94 30 C74 30 65 42 65 58 Z" fill="#6fb85b"/><path d="M16 104 Q64 92 112 104" fill="none"/>'
		"arrow_up":
			return '<path d="M64 16 L104 62 H80 V110 H48 V62 H24 Z" fill="#%s"/>' % h
		"arrow_right":
			return '<path d="M16 48 H62 V24 L112 64 L62 104 V80 H16 Z" fill="#%s"/>' % h
		"arrow_down":
			return '<path d="M64 112 L24 66 H48 V18 H80 V66 H104 Z" fill="#%s"/>' % h
		"arrow_left":
			return '<path d="M112 48 H66 V24 L16 64 L66 104 V80 H112 Z" fill="#%s"/>' % h
		"cane":
			return '<path d="M32 52 C24 24 52 12 70 22 C88 12 112 26 104 52 L104 80 C104 102 80 112 64 104 C48 112 24 102 24 80 Z" fill="#b07a4d"/><path d="M40 44 C34 50 36 58 42 60 M88 44 C94 50 92 58 86 60" fill="none"/><ellipse cx="64" cy="78" rx="24" ry="16" fill="#d5a878"/><circle cx="64" cy="74" r="7" fill="#3a2a22"/>'
		"ape":
			return '<ellipse cx="64" cy="74" rx="34" ry="28" fill="#f2c94c"/><path d="M46 50 V98 M64 44 V104 M82 50 V98" fill="none" stroke-width="8" stroke="#3a2a22"/><ellipse cx="46" cy="44" rx="16" ry="12" transform="rotate(-30 46 44)" fill="#eef3f7"/><ellipse cx="82" cy="44" rx="16" ry="12" transform="rotate(30 82 44)" fill="#eef3f7"/><circle cx="50" cy="70" r="4" fill="#2b201b"/>'
		"uva":
			return '<circle cx="46" cy="54" r="14" fill="#8e5ba8"/><circle cx="70" cy="50" r="14" fill="#8e5ba8"/><circle cx="58" cy="74" r="14" fill="#8e5ba8"/><circle cx="82" cy="72" r="14" fill="#8e5ba8"/><circle cx="46" cy="94" r="14" fill="#8e5ba8"/><circle cx="70" cy="92" r="14" fill="#8e5ba8"/><path d="M64 40 C70 24 82 18 94 20" fill="none" stroke="#6fb85b"/>'
		"oca":
			return '<ellipse cx="66" cy="86" rx="40" ry="24" fill="#f7f2e7"/><path d="M88 70 C96 50 90 28 76 22 C68 18 60 24 64 34 C70 46 76 52 74 74" fill="#f7f2e7"/><circle cx="74" cy="26" r="9" fill="#f7f2e7"/><path d="M82 24 L98 30 L82 34 Z" fill="#ef9450"/><circle cx="76" cy="24" r="2.5" fill="#2b201b"/>'
		"topo":
			return '<circle cx="64" cy="74" r="32" fill="#a7a7b8"/><circle cx="38" cy="42" r="17" fill="#a7a7b8"/><circle cx="90" cy="42" r="17" fill="#a7a7b8"/><circle cx="56" cy="68" r="4" fill="#2b201b"/><circle cx="76" cy="68" r="4" fill="#2b201b"/><circle cx="66" cy="80" r="5" fill="#e88a9a"/><path d="M96 84 C118 84 116 106 100 106" fill="none" stroke="#a7a7b8"/>'
		"orso":
			return '<circle cx="64" cy="68" r="40" fill="#8b6244"/><circle cx="30" cy="36" r="18" fill="#8b6244"/><circle cx="98" cy="36" r="18" fill="#8b6244"/><ellipse cx="64" cy="84" rx="24" ry="18" fill="#d5b08a"/><circle cx="50" cy="60" r="5" fill="#2b201b"/><circle cx="78" cy="60" r="5" fill="#2b201b"/><ellipse cx="64" cy="76" rx="7" ry="5" fill="#2b201b"/>'
		"gufo":
			return '<ellipse cx="64" cy="70" rx="40" ry="44" fill="#a77b55"/><circle cx="48" cy="62" r="15" fill="#fff3b0"/><circle cx="80" cy="62" r="15" fill="#fff3b0"/><circle cx="48" cy="62" r="6" fill="#2b201b"/><circle cx="80" cy="62" r="6" fill="#2b201b"/><path d="M56 88 L64 96 L72 88" fill="#f2c94c"/><path d="M30 36 L44 24 L48 42 M98 36 L84 24 L80 42" fill="#a77b55"/>'
		"serpente":
			return '<path d="M20 94 C50 112 54 68 82 78 C104 86 102 54 82 50 C62 46 58 26 82 22" fill="none" stroke="#6fb85b" stroke-width="16"/><circle cx="84" cy="22" r="8" fill="#6fb85b"/><circle cx="88" cy="19" r="2.5" fill="#2b201b"/>'
		"casa":
			return '<rect x="28" y="58" width="72" height="54" rx="4" fill="#e8c79a"/><path d="M18 60 L64 18 L110 60 Z" fill="#d5674a"/><rect x="56" y="78" width="18" height="34" fill="#8a5a35"/><rect x="38" y="70" width="12" height="12" fill="#8ecae6"/>'
		"pane":
			return '<path d="M20 82 C20 46 40 28 64 28 C88 28 108 46 108 82 C108 98 92 106 64 106 C36 106 20 98 20 82 Z" fill="#d9a05b"/><path d="M40 56 C48 48 60 44 76 46 M42 72 C54 64 76 62 92 68" fill="none" stroke-width="5"/>'
		"biscotto":
			return '<circle cx="64" cy="64" r="42" fill="#d9a05b"/><circle cx="48" cy="48" r="5" fill="#6b4a2f"/><circle cx="82" cy="54" r="5" fill="#6b4a2f"/><circle cx="64" cy="78" r="5" fill="#6b4a2f"/><circle cx="88" cy="82" r="4" fill="#6b4a2f"/><circle cx="42" cy="80" r="4" fill="#6b4a2f"/>'
		"mattoncino":
			return '<rect x="16" y="42" width="96" height="52" rx="6" fill="#c96a4a"/><rect x="30" y="28" width="26" height="16" rx="4" fill="#c96a4a"/><rect x="70" y="28" width="26" height="16" rx="4" fill="#c96a4a"/>'
		"nastro":
			return '<path d="M10 54 C28 30 44 78 64 54 C84 30 100 78 118 54" fill="none" stroke="#%s" stroke-width="18"/>' % h
		"corda":
			return '<path d="M14 84 C34 64 50 96 64 76 C78 56 96 88 114 66" fill="none" stroke="#b98a55" stroke-width="12"/><path d="M14 84 C34 64 50 96 64 76 C78 56 96 88 114 66" fill="none" stroke="#d9b98a" stroke-width="4" stroke-dasharray="6 8"/>'
		"trave":
			return '<rect x="8" y="52" width="112" height="24" rx="6" fill="#b98a55"/><path d="M24 52 V76 M48 52 V76 M72 52 V76 M96 52 V76" fill="none" stroke-width="2"/>'
		"torre":
			return '<rect x="38" y="34" width="52" height="78" fill="#8e9bb5"/><rect x="26" y="22" width="18" height="20" fill="#8e9bb5"/><rect x="55" y="22" width="18" height="20" fill="#8e9bb5"/><rect x="84" y="22" width="18" height="20" fill="#8e9bb5"/><rect x="54" y="56" width="20" height="24" rx="10" fill="#ffe9a8"/>'
		"bilancia":
			return '<path d="M64 20 V96 M32 96 H96 M20 42 H108" fill="none" stroke="#8a6a4a" stroke-width="7"/><path d="M20 42 L8 74 H32 Z M108 42 L96 74 H120 Z" fill="#c9a06a"/>'
		"barattolo":
			return '<rect x="32" y="34" width="64" height="80" rx="14" fill="#cfe8ee" opacity="0.9"/><path d="M34 72 H94 V100 C94 108 86 112 64 112 C42 112 34 108 34 100 Z" fill="#7ec8e3"/><rect x="30" y="24" width="68" height="14" rx="7" fill="#8a6a4a"/>'
		"barattolo_pieno":
			return '<rect x="32" y="34" width="64" height="80" rx="14" fill="#cfe8ee" opacity="0.9"/><path d="M34 54 H94 V100 C94 108 86 112 64 112 C42 112 34 108 34 100 Z" fill="#4aa3c7"/><rect x="30" y="24" width="68" height="14" rx="7" fill="#8a6a4a"/>'
		"piu_pieno":
			return '<rect x="32" y="34" width="64" height="80" rx="14" fill="#cfe8ee" opacity="0.9"/><path d="M34 50 H94 V100 C94 108 86 112 64 112 C42 112 34 108 34 100 Z" fill="#4aa3c7"/><rect x="30" y="24" width="68" height="14" rx="7" fill="#8a6a4a"/><path d="M64 46 L64 70 M52 58 L76 58" stroke="#fff9ec" stroke-width="7"/>'
		"meno_pieno":
			return '<rect x="32" y="34" width="64" height="80" rx="14" fill="#cfe8ee" opacity="0.9"/><path d="M34 86 H94 V100 C94 108 86 112 64 112 C42 112 34 108 34 100 Z" fill="#4aa3c7"/><rect x="30" y="24" width="68" height="14" rx="7" fill="#8a6a4a"/>'
		"pesante":
			return '<rect x="30" y="46" width="68" height="50" rx="10" fill="#7b8794"/><path d="M34 46 C34 26 94 26 94 46" fill="none" stroke-width="10"/><path d="M54 66 H74" stroke="#fff9ec" stroke-width="6"/>'
		"leggero":
			return '<path d="M96 18 C74 20 68 48 52 56 C36 64 24 80 32 100 C54 104 82 88 96 64 C104 50 104 32 96 18 Z" fill="#eef3f7"/><path d="M92 24 C76 44 60 62 40 92" fill="none"/>'
		"lungo":
			return '<rect x="10" y="54" width="108" height="20" rx="10" fill="#c9a06a"/>'
		"corto":
			return '<rect x="34" y="54" width="60" height="20" rx="10" fill="#c9a06a"/>'
		"alta":
			return '<rect x="50" y="12" width="28" height="96" rx="6" fill="#8e9bb5"/><rect x="42" y="108" width="44" height="8" rx="4" fill="#5f6b80"/>'
		"bassa":
			return '<rect x="50" y="66" width="28" height="42" rx="6" fill="#8e9bb5"/><rect x="42" y="108" width="44" height="8" rx="4" fill="#5f6b80"/>'
		"larga":
			return '<rect x="18" y="72" width="92" height="36" rx="6" fill="#8e9bb5"/><rect x="10" y="108" width="108" height="8" rx="4" fill="#5f6b80"/>'
		"dentro":
			return '<rect x="22" y="22" width="84" height="84" rx="8" fill="none" stroke-width="7"/><circle cx="64" cy="64" r="18" fill="#%s"/>' % h
		"fuori":
			return '<rect x="42" y="42" width="64" height="64" rx="8" fill="none" stroke-width="7"/><circle cx="30" cy="30" r="18" fill="#%s"/>' % h
		"sopra":
			return '<path d="M16 92 H112" fill="none" stroke-width="7"/><circle cx="64" cy="40" r="22" fill="#%s"/><path d="M64 64 V84" fill="none"/>' % h
		"sotto":
			return '<path d="M16 36 H112" fill="none" stroke-width="7"/><circle cx="64" cy="88" r="22" fill="#%s"/><path d="M64 64 V40" fill="none"/>' % h
		"vicino":
			return '<circle cx="42" cy="64" r="14" fill="#%s"/><circle cx="72" cy="64" r="14" fill="#%s"/><circle cx="108" cy="64" r="8" fill="#%s" opacity="0.4"/>' % [h, h, h]
		"lontano":
			return '<circle cx="20" cy="64" r="12" fill="#%s"/><circle cx="82" cy="64" r="14" fill="#%s"/><circle cx="108" cy="64" r="8" fill="#%s" opacity="0.4"/>' % [h, h, h]
		"davanti":
			return '<path d="M16 100 H112" fill="none"/><circle cx="64" cy="58" r="24" fill="#%s"/><path d="M64 84 V100" fill="none"/>' % h
		"dietro":
			return '<path d="M16 28 H112" fill="none"/><circle cx="64" cy="74" r="24" fill="#%s"/><path d="M64 28 V50" fill="none"/>' % h
		"destra":
			return '<path d="M20 64 H84 M60 32 L100 64 L60 96" fill="none" stroke-width="12"/>'
		"sinistra":
			return '<path d="M108 64 H44 M68 32 L28 64 L68 96" fill="none" stroke-width="12"/>'
		"freccia":
			return '<path d="M16 52 H64 V28 L112 64 L64 100 V76 H16 Z" fill="#%s"/>' % h
		"pallino":
			return '<circle cx="64" cy="64" r="30" fill="#%s"/>' % h
		"occhio":
			return '<path d="M16 64 C36 34 92 34 112 64 C92 94 36 94 16 64 Z" fill="none" stroke="#%s" stroke-width="7"/><circle cx="64" cy="64" r="20" fill="#%s"/><circle cx="64" cy="64" r="8" fill="#2b201b"/>' % [h, h]
		"bocca":
			return '<path d="M24 64 C40 32 88 32 104 64 C88 96 40 96 24 64 Z" fill="#e88a9a"/><path d="M24 64 H104" fill="none"/>'
		"piu":
			return '<path d="M56 20 H72 V56 H108 V72 H72 V108 H56 V72 H20 V56 H56 Z" fill="#%s"/>' % h
		"meno":
			return '<rect x="20" y="56" width="88" height="16" rx="8" fill="#%s"/>' % h
		"uguale":
			return '<rect x="20" y="42" width="88" height="14" rx="7" fill="#%s"/><rect x="20" y="72" width="88" height="14" rx="7" fill="#%s"/>' % [h, h]
		"maggiore":
			return '<path d="M30 24 L98 64 L30 104" fill="none" stroke="#%s" stroke-width="14"/>' % h
		"minore":
			return '<path d="M98 24 L30 64 L98 104" fill="none" stroke="#%s" stroke-width="14"/>' % h
		"diverso":
			return '<path d="M20 90 L108 38" stroke="#d94f45" stroke-width="12"/><circle cx="54" cy="64" r="26" fill="#%s" opacity="0.8"/>' % h
		"libro":
			return '<path d="M18 28 C38 20 54 24 64 34 C74 24 90 20 110 28 V102 C90 94 74 98 64 108 C54 98 38 94 18 102 Z" fill="#%s"/><path d="M64 34 V108" fill="none"/>' % h
		"chiave":
			return '<circle cx="40" cy="54" r="20" fill="none" stroke-width="10"/><path d="M56 68 L104 116 M88 100 L102 86 M76 112 L90 98" fill="none" stroke-width="10"/>'
		"orma":
			return '<path d="M48 20 C60 16 68 26 66 42 C65 54 60 58 60 70 C60 82 54 90 46 90 C36 90 32 80 34 66 C36 52 38 48 38 38 C38 28 42 22 48 20 Z" fill="#%s"/>' % h
		"onda":
			return '<path d="M12 74 C26 46 40 46 54 74 C68 102 82 102 96 74 C102 62 108 58 116 60" fill="none" stroke="#%s" stroke-width="10"/>' % h
		"nota":
			return '<ellipse cx="46" cy="92" rx="20" ry="15" fill="#%s"/><path d="M64 88 V24 L104 16 V70" fill="none" stroke-width="8"/><ellipse cx="86" cy="72" rx="18" ry="13" fill="#%s"/>' % [h, h]
		"cuore":
			return '<path d="M64 106 C28 82 18 56 30 40 C42 24 58 30 64 44 C70 30 86 24 98 40 C110 56 100 82 64 106 Z" fill="#%s"/>' % h
		"lente":
			return '<circle cx="54" cy="54" r="34" fill="#%s" opacity="0.25"/><circle cx="54" cy="54" r="34" fill="none" stroke="#%s" stroke-width="9"/><path d="M80 80 L112 112" stroke="#%s" stroke-width="13" stroke-linecap="round"/>' % [h, h, h]
		"bussola":
			return '<circle cx="64" cy="64" r="46" fill="#cfe8ee" stroke-width="7"/><circle cx="64" cy="64" r="34" fill="#fff9ec" opacity="0.75"/><path d="M82 40 L72 72 L40 82 L52 52 Z" fill="#d95c5c"/><path d="M72 72 L82 40 L70 68 Z" fill="#4c86c6"/><circle cx="64" cy="64" r="5" fill="#3a2a22"/>'
		"play":
			return '<path d="M34 18 L106 64 L34 110 Z" fill="#%s"/>' % h
		"dado":
			return '<rect x="20" y="20" width="88" height="88" rx="14" fill="#fff9ec"/><circle cx="42" cy="42" r="7" fill="#3a2a22"/><circle cx="64" cy="64" r="7" fill="#3a2a22"/><circle cx="86" cy="86" r="7" fill="#3a2a22"/>'
		"pannello":
			return '<rect x="18" y="24" width="92" height="80" rx="10" fill="#%s"/><path d="M36 46 H92 M36 64 H80 M36 82 H64" stroke="#fff9ec" stroke-width="6"/>' % h
		"musica":
			return '<path d="M22 60 C22 42 38 30 56 34 L56 94 C56 108 40 112 32 102 C24 92 32 80 44 80 L44 48 C44 42 50 40 56 40" fill="none" stroke="#%s" stroke-width="9"/><circle cx="96" cy="92" r="14" fill="#%s"/><path d="M110 92 V34" fill="none" stroke-width="8"/>' % [h, h]
		"stella_finale":
			return '<path d="' + _star(64, 64, 54, 22, 5) + '" fill="#f6d365"/><path d="' + _star(64, 64, 30, 12, 5) + '" fill="#fff3b0"/>'
		"prato":
			return '<path d="M10 104 C26 76 32 100 40 80 C48 60 56 92 64 72 C72 52 80 88 88 66 C96 44 104 86 118 104 Z" fill="#8ccb7a"/>'
		"aiuto":
			return '<circle cx="64" cy="64" r="46" fill="#%s"/><path d="M48 50 C48 34 80 34 80 52 C80 64 64 64 64 78" fill="none" stroke="#fff9ec" stroke-width="10"/><circle cx="64" cy="96" r="6" fill="#fff9ec"/>' % h
		"cesta":
			return '<path d="M22 48 H106 L94 104 H34 Z" fill="#d8b98a"/><path d="M32 62 H96 M36 76 H92 M40 90 H88" stroke="#a97a48" stroke-width="5" fill="none"/><path d="M40 48 C40 24 88 24 88 48" fill="none" stroke="#a97a48" stroke-width="7"/>'
		"cubetto":
			return '<path d="M64 18 L106 40 L106 88 L64 110 L22 88 L22 40 Z" fill="#%s"/><path d="M22 40 L64 62 L106 40 M64 62 V110" fill="none" stroke="#%s" stroke-width="5" opacity="0.55"/>' % [h, hd]
		"gradino":
			return '<path d="M14 104 H44 V80 H74 V56 H104 V32 H120 V112 H14 Z" fill="#%s"/><path d="M14 104 H44 V80 H74 V56 H104 V32" fill="none" stroke="#%s" stroke-width="6"/>' % [h, hd]
		"molla":
			return '<path d="M38 20 H90 C104 20 104 38 90 38 H38 C24 38 24 56 38 56 H90 C104 56 104 74 90 74 H38 C24 74 24 92 38 92 H90" fill="none" stroke="#%s" stroke-width="10" stroke-linecap="round"/>' % h
		"porta":
			return '<path d="M26 108 V56 C26 28 102 28 102 56 V108 Z" fill="#%s"/><path d="M52 108 V72 C52 58 76 58 76 72 V108" fill="#%s" opacity="0.45"/><circle cx="86" cy="80" r="5" fill="#f2c24b"/>' % [h, hd]
	return '<circle cx="64" cy="64" r="42" fill="#' + h + '"/><circle cx="64" cy="64" r="18" fill="#' + white + '" opacity="0.7"/>'

static func _star(cx: float, cy: float, outer: float, inner: float, points: int) -> String:
	var pts: Array[String] = []
	for i in range(points * 2):
		var r := outer if i % 2 == 0 else inner
		var a := deg_to_rad(-90.0 + float(i) * 180.0 / float(points))
		pts.append("%.1f %.1f" % [cx + cos(a) * r, cy + sin(a) * r])
	return "M" + " L".join(pts) + " Z"

static func _poly(cx: float, cy: float, r: float, points: int, start_deg: float) -> String:
	var pts: Array[String] = []
	for i in range(points):
		var a := deg_to_rad(start_deg + float(i) * 360.0 / float(points))
		pts.append("%.1f %.1f" % [cx + cos(a) * r, cy + sin(a) * r])
	return "M" + " L".join(pts) + " Z"

static func _dice(k: int) -> String:
	var s := '<rect x="18" y="18" width="92" height="92" rx="16" fill="#fff9ec" stroke="#3a2a22" stroke-width="5"/>'
	var dots: Array = []
	match k:
		1: dots = [[64, 64]]
		2: dots = [[42, 42], [86, 86]]
		3: dots = [[40, 40], [64, 64], [88, 88]]
		4: dots = [[42, 42], [86, 42], [42, 86], [86, 86]]
		5: dots = [[42, 42], [86, 42], [64, 64], [42, 86], [86, 86]]
		6: dots = [[42, 38], [86, 38], [42, 64], [86, 64], [42, 90], [86, 90]]
	for p in dots:
		s += '<circle cx="%d" cy="%d" r="8" fill="#3a2a22"/>' % [int(p[0]), int(p[1])]
	return s

static func _hand(k: int, h: String) -> String:
	var s := '<rect x="26" y="58" width="76" height="52" rx="18" fill="#%s"/>' % h
	var fingers := [
		[32, 26, 12, 40], [48, 16, 12, 50], [64, 10, 12, 56],
		[80, 16, 12, 50], [96, 28, 12, 38],
	]
	for i in range(k):
		var f: Array = fingers[i]
		s += '<rect x="%d" y="%d" width="%d" height="%d" rx="6" fill="#%s"/>' % [f[0], f[1], f[2], f[3], h]
	s += '<rect x="88" y="70" width="28" height="14" rx="7" fill="#%s" transform="rotate(-35 88 70)"/>' % h
	return s
