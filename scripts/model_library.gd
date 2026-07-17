extends Node
class_name ModelLibrary
## Loads Blender-exported glTF models with primitive fallbacks.

const PATHS := {
	"lantern": "res://assets/models/props/lantern.glb",
	"pillar": "res://assets/models/architecture/pillar.glb",
	"roof_module": "res://assets/models/architecture/roof_module.glb",
	"gate": "res://assets/models/architecture/gate.glb",
	"stone_lion": "res://assets/models/props/stone_lion.glb",
	"stele": "res://assets/models/props/stele.glb",
	"tree": "res://assets/models/props/tree.glb",
	"scroll": "res://assets/models/props/scroll.glb",
	"jade": "res://assets/models/props/jade.glb",
	"sword": "res://assets/models/props/sword.glb",
	"pavilion": "res://assets/models/architecture/pavilion.glb",
	"main_hall": "res://assets/models/architecture/main_hall.glb",
	"npc_elder": "res://assets/models/characters/npc_elder.glb",
	"enemy_bandit": "res://assets/models/characters/enemy_bandit.glb",
	"wall_segment": "res://assets/models/architecture/wall_segment.glb",
}

static var _cache: Dictionary = {}


static func has_model(key: String) -> bool:
	if not PATHS.has(key):
		return false
	return ResourceLoader.exists(PATHS[key])


static func instantiate(key: String, scale: float = 1.0) -> Node3D:
	if not has_model(key):
		return null
	var packed: PackedScene = _cache.get(key)
	if packed == null:
		var res = load(PATHS[key])
		if res is PackedScene:
			packed = res
		else:
			return null
		_cache[key] = packed
	var node: Node3D = packed.instantiate() as Node3D
	if node == null:
		return null
	if scale != 1.0:
		node.scale = Vector3.ONE * scale
	_prepare_instance(node)
	return node


static func _prepare_instance(root: Node) -> void:
	# glTF often nests meshes; ensure shadows and freeze transforms for props
	if root is MeshInstance3D:
		(root as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in root.get_children():
		_prepare_instance(child)


static func add_collision_box(parent: Node3D, size: Vector3, offset: Vector3 = Vector3.ZERO, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = offset
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func add_collision_capsule(parent: Node3D, radius: float, height: float, offset: Vector3 = Vector3.ZERO, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = offset
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body
