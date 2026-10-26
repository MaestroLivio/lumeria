class_name WorldCollectible
extends Node3D
## Piccoli incontri dell'esplorazione: lucciole, creature, pietre musicali.

var kind := "fireflies"
var collectible_id := ""
var _phase := 0.0
var _visual: Node3D
var _taken := false

func setup(k: String, id: String) -> void:
	kind = k
	collectible_id = id
	_phase = randf() * TAU
	_build()

func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	match kind:
		"fireflies":
			MeshHelpers.sphere(_visual, 0.11, Color("#FFF3B0"), Vector3.ZERO, Color("#FFE066"), 3.0)
			MeshHelpers.sphere(_visual, 0.055, Color.WHITE, Vector3(0, 0, 0), Color.WHITE, 1.5)
			for side in [-1.0, 1.0]:
				var wing := MeshHelpers.box(_visual, Vector3(0.18, 0.02, 0.1), Color(1, 1, 1, 0.42),
					Vector3(0.12 * side, 0.04, 0))
				wing.transparency = 0.55
			var l := OmniLight3D.new()
			l.light_color = Color("#FFE066")
			l.light_energy = 0.9
			l.omni_range = 1.8
			add_child(l)
		"critters":
			var body_color: Color = [Color("#E8A65A"), Color("#B98A55"), Color("#8E7CC3"), Color("#6FAE6A")][randi() % 4]
			MeshHelpers.sphere(_visual, 0.18, body_color, Vector3(0, 0.12, 0))
			MeshHelpers.sphere(_visual, 0.12, body_color.lightened(0.12), Vector3(0, 0.3, 0.08))
			for side in [-1.0, 1.0]:
				MeshHelpers.sphere(_visual, 0.035, Color("#3B2A20"), Vector3(0.06 * side, 0.33, 0.17))
				MeshHelpers.sphere(_visual, 0.07, body_color.darkened(0.18), Vector3(0.14 * side, 0.05, 0))
		"stones":
			var c: Color = [Color("#7EC8E3"), Color("#E9748A"), Color("#F2C24B"), Color("#9B7BC4")][randi() % 4]
			MeshHelpers.prism(_visual, Vector3(0.26, 0.5, 0.18), c, Vector3(0, 0.25, 0))
			MeshHelpers.sphere(_visual, 0.09, Color.WHITE, Vector3(0, 0.36, 0), c, 2.0)
			var l2 := OmniLight3D.new()
			l2.light_color = c
			l2.light_energy = 0.5
			l2.omni_range = 1.4
			add_child(l2)
	_visual.position.y = 0.1

func _process(delta: float) -> void:
	if _taken:
		return
	_phase += delta
	if bool(Settings.get_setting("reduce_motion", false)):
		return
	_visual.position.y = 0.1 + sin(_phase * 2.1) * 0.09
	_visual.rotation.y += delta * 0.8

func collect() -> void:
	if _taken:
		return
	_taken = true
	Audio.play_sfx("firefly" if kind == "fireflies" else ("heart" if kind == "critters" else "stone"))
	if bool(Settings.get_setting("reduce_motion", false)):
		queue_free()
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual, "scale", Vector3(0.05, 0.05, 0.05), 0.28)
	tw.tween_property(_visual, "position:y", _visual.position.y + 0.8, 0.28)
	tw.chain().tween_callback(queue_free)
