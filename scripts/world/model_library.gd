class_name ModelLibrary
extends RefCounted
## Carica i modelli low-poly generati con Blender (assets/models/*.glb).
## Se un modello manca il gioco continua a funzionare: le decorazioni
## procedurali restano il fallback silenzioso.

const DIR := "res://assets/models/"

static var _scenes: Dictionary = {}
static var _failed: Dictionary = {}

static func has_model(model_name: String) -> bool:
	return scene(model_name) != null

static func scene(model_name: String) -> PackedScene:
	if _scenes.has(model_name):
		return _scenes[model_name]
	if _failed.has(model_name):
		return null
	var path := DIR + model_name + ".glb"
	if not ResourceLoader.exists(path):
		_failed[model_name] = true
		return null
	var res := load(path)
	if res is PackedScene:
		_scenes[model_name] = res
		return res
	_failed[model_name] = true
	return null

## Istanzia un modello. `s` può essere uno scalare o un Vector3.
## `collide` aggiunge un cilindro statico per gli edifici.
static func place(parent: Node3D, model_name: String, pos: Vector3, rot_y: float = 0.0,
		s: Variant = 1.0, collide: float = 0.0) -> Node3D:
	var packed := scene(model_name)
	if packed == null:
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		return null
	node.position = pos
	node.rotation.y = rot_y
	if s is Vector3:
		node.scale = s
	else:
		var f := float(s)
		node.scale = Vector3(f, f, f)
	parent.add_child(node)
	if collide > 0.0:
		var body := StaticBody3D.new()
		body.name = "Collisione"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = collide
		cyl.height = 2.0
		shape.shape = cyl
		shape.position = Vector3(0, 1.0, 0)
		body.add_child(shape)
		node.add_child(body)
	return node

static func clear_cache() -> void:
	_scenes.clear()
	_failed.clear()
