class_name Confetti
extends Control
## Coriandoli di festa per ogni missione completata.
## Disegnati a mano, senza texture né particelle: pochi rettangoli colorati che
## cadono ruotando, sopra il pannello di vittoria. Con "Riduci il movimento"
## restano pochi e lenti, senza rinunciare alla festa.

const COLORS: Array[Color] = [
	Color("#F2C24B"), Color("#E9748A"), Color("#6DBE6D"), Color("#4C86C6"),
	Color("#9B7BC4"), Color("#E8944A"), Color("#4FB3A9"), Color("#FFF3B0"),
]

var _pieces: Array[Dictionary] = []
var _time := 0.0
var _duration := 5.0
var _viewport_size := Vector2(1280, 720)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spawn()

func _spawn() -> void:
	var calm := bool(Settings.get_setting("reduce_motion", false))
	var count := 60 if calm else 150
	var speed := 0.55 if calm else 1.0
	for i in range(count):
		_pieces.append({
			"pos": Vector2(randf() * 1400.0 - 60.0, -randf() * 900.0 - 40.0),
			"vel": Vector2(randf_range(-55.0, 55.0), randf_range(110.0, 290.0) * speed),
			"size": Vector2(randf_range(6.0, 13.0), randf_range(9.0, 19.0)),
			"rot": randf() * TAU,
			"spin": randf_range(-4.5, 4.5) * speed,
			"sway": randf_range(0.7, 2.4),
			"phase": randf() * TAU,
			"color": COLORS[randi() % COLORS.size()],
		})

func _process(delta: float) -> void:
	_time += delta
	if size.x > 1.0 and size.y > 1.0:
		_viewport_size = size
	for piece in _pieces:
		var pos: Vector2 = piece["pos"]
		var vel: Vector2 = piece["vel"]
		pos += vel * delta
		pos.x += sin(_time * float(piece["sway"]) + float(piece["phase"])) * 26.0 * delta
		if pos.y > _viewport_size.y + 40.0:
			pos.y = -30.0
			pos.x = randf() * _viewport_size.x
		if pos.x < -60.0:
			pos.x = _viewport_size.x + 40.0
		elif pos.x > _viewport_size.x + 60.0:
			pos.x = -40.0
		piece["pos"] = pos
		piece["rot"] = float(piece["rot"]) + float(piece["spin"]) * delta
	queue_redraw()
	if _time >= _duration:
		queue_free()
	elif _time >= _duration - 0.8:
		modulate.a = maxf(0.0, (_duration - _time) / 0.8)

func _draw() -> void:
	for piece in _pieces:
		var pos: Vector2 = piece["pos"]
		var s: Vector2 = piece["size"]
		draw_set_transform(pos, float(piece["rot"]), Vector2.ONE)
		draw_rect(Rect2(-s.x * 0.5, -s.y * 0.5, s.x, s.y), piece["color"])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
