extends Node3D
## Builds the courtyard using Blender glTF models when available, with primitive fallbacks.

const WOOD := Color(0.45, 0.28, 0.14)
const DARK_WOOD := Color(0.28, 0.16, 0.08)
const STONE := Color(0.55, 0.52, 0.48)
const TILE := Color(0.32, 0.14, 0.12)
const PLASTER := Color(0.90, 0.86, 0.78)
const GRASS := Color(0.32, 0.46, 0.28)
const WATER := Color(0.22, 0.42, 0.50, 0.82)
const GOLD := Color(0.82, 0.66, 0.24)
const PATH := Color(0.52, 0.48, 0.42)
const MOSS := Color(0.28, 0.40, 0.24)


func _ready() -> void:
	_build_ground()
	_build_walls()
	_build_main_hall()
	_build_side_pavilions()
	_build_path_and_pond()
	_build_lanterns()
	_build_trees()
	_build_decor_and_pickups()
	_build_npc()
	_build_enemies()
	_build_ambient_details()


func _mat(color: Color, roughness: float = 0.85, metallic: float = 0.0, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m


func _static_box(size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	body.collision_layer = 1
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	mesh_i.material_override = _mat(color)
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _box_mesh(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	mesh_i.material_override = _mat(color)
	mesh_i.position = pos
	parent.add_child(mesh_i)
	return mesh_i


func _place_model(key: String, pos: Vector3, rot_y: float = 0.0, scale: float = 1.0) -> Node3D:
	var node := ModelLibrary.instantiate(key, scale)
	if node == null:
		return null
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)
	return node


func _place_prop(key: String, pos: Vector3, col_size: Vector3, rot_y: float = 0.0, scale: float = 1.0, col_offset: Vector3 = Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	var model := ModelLibrary.instantiate(key, scale)
	if model:
		root.add_child(model)
	else:
		_box_mesh(root, col_size, col_offset + Vector3(0, col_size.y * 0.5, 0), STONE)
	ModelLibrary.add_collision_box(root, col_size, col_offset + Vector3(0, col_size.y * 0.5, 0), 1)
	return root


func _build_ground() -> void:
	_static_box(Vector3(90, 1, 90), Vector3(0, -0.5, 0), GRASS)
	_static_box(Vector3(50, 0.08, 50), Vector3(0, 0.02, 0), MOSS)
	_static_box(Vector3(30, 0.12, 30), Vector3(0, 0.06, 0), STONE)
	for x in range(-3, 4):
		for z in range(-3, 4):
			if (x + z) % 2 == 0:
				_static_box(Vector3(3.8, 0.04, 3.8), Vector3(x * 4.0, 0.13, z * 4.0), Color(0.50, 0.47, 0.43))
	for i in range(3):
		_static_box(Vector3(6.0 - i * 0.4, 0.18, 0.8), Vector3(0, 0.15 + i * 0.18, -4.5 - i * 0.55), STONE)


func _build_walls() -> void:
	# Prefer wall segments from Blender
	if ModelLibrary.has_model("wall_segment"):
		for z in [-19.0, 19.0]:
			if absf(z - 19.0) < 0.1:
				# south wall wings (gate gap)
				for x in [-14.0, -10.0, -6.0, 6.0, 10.0, 14.0]:
					_place_prop("wall_segment", Vector3(x, 0, z), Vector3(4.0, 3.5, 0.6), 0.0, 1.0)
			else:
				for x in range(-16, 17, 4):
					_place_prop("wall_segment", Vector3(float(x), 0, z), Vector3(4.0, 3.5, 0.6), 0.0, 1.0)
		for x in [-21.0, 21.0]:
			for z in range(-16, 17, 4):
				_place_prop("wall_segment", Vector3(x, 0, float(z)), Vector3(0.6, 3.5, 4.0), deg_to_rad(90.0), 1.0)
	else:
		_static_box(Vector3(42, 4.2, 0.7), Vector3(0, 2.1, -19), PLASTER)
		_static_box(Vector3(0.7, 4.2, 38), Vector3(-21, 2.1, 0), PLASTER)
		_static_box(Vector3(0.7, 4.2, 38), Vector3(21, 2.1, 0), PLASTER)
		_static_box(Vector3(15, 4.2, 0.7), Vector3(-13.5, 2.1, 19), PLASTER)
		_static_box(Vector3(15, 4.2, 0.7), Vector3(13.5, 2.1, 19), PLASTER)

	# Gate model
	if ModelLibrary.has_model("gate"):
		_place_prop("gate", Vector3(0, 0, 19), Vector3(6.0, 5.0, 1.8), 0.0, 1.0)
	else:
		_static_box(Vector3(1.4, 5.0, 1.4), Vector3(-4.0, 2.5, 19), DARK_WOOD)
		_static_box(Vector3(1.4, 5.0, 1.4), Vector3(4.0, 2.5, 19), DARK_WOOD)
		_static_box(Vector3(9.5, 1.0, 1.6), Vector3(0, 5.0, 19), TILE)
	_static_box(Vector3(8, 0.22, 2.2), Vector3(0, 0.12, 18.2), STONE)


func _build_main_hall() -> void:
	if ModelLibrary.has_model("main_hall"):
		_place_prop("main_hall", Vector3(0, 0, -10), Vector3(11, 6, 8), PI, 1.0)
	else:
		_static_box(Vector3(14, 0.4, 8), Vector3(0, 0.2, -10), Color(0.48, 0.45, 0.40))
		_static_box(Vector3(12, 3.2, 0.35), Vector3(0, 2.0, -13.2), PLASTER)
		_static_box(Vector3(14, 0.35, 8.5), Vector3(0, 4.5, -10), TILE)


func _build_side_pavilions() -> void:
	for pos in [Vector3(-11, 0, 2), Vector3(11, 0, 2)]:
		if ModelLibrary.has_model("pavilion"):
			_place_prop("pavilion", pos, Vector3(4.5, 3.5, 4.5), 0.0, 1.0)
		else:
			_static_box(Vector3(4.5, 0.2, 4.5), pos + Vector3(0, 0.1, 0), STONE)


func _build_path_and_pond() -> void:
	_static_box(Vector3(4.2, 0.1, 20), Vector3(0, 0.1, 5), PATH)
	_static_box(Vector3(12, 0.1, 3.2), Vector3(0, 0.1, 0), PATH)
	_static_box(Vector3(4.2, 0.1, 8), Vector3(0, 0.1, -3), PATH)

	var pond_body := StaticBody3D.new()
	pond_body.position = Vector3(0, -0.02, 7)
	pond_body.collision_layer = 1
	var water_mesh := MeshInstance3D.new()
	var water_box := BoxMesh.new()
	water_box.size = Vector3(9, 0.18, 5.5)
	water_mesh.mesh = water_box
	var water_mat := _mat(WATER, 0.08, 0.35)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mesh.material_override = water_mat
	pond_body.add_child(water_mesh)
	var rim := MeshInstance3D.new()
	var rim_box := BoxMesh.new()
	rim_box.size = Vector3(9.8, 0.4, 6.2)
	rim.mesh = rim_box
	rim.material_override = _mat(STONE)
	rim.position = Vector3(0, -0.12, 0)
	pond_body.add_child(rim)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.8, 0.45, 6.2)
	col.shape = shape
	col.position = Vector3(0, -0.2, 0)
	pond_body.add_child(col)
	add_child(pond_body)

	for i in range(3):
		_static_box(Vector3(1.3, 0.16, 1.0), Vector3(-1.6 + i * 1.6, 0.14, 7), STONE)


func _build_lanterns() -> void:
	var positions := [
		Vector3(-4.5, 0, 13), Vector3(4.5, 0, 13),
		Vector3(-7, 0, -6), Vector3(7, 0, -6),
		Vector3(-9, 0, 8), Vector3(9, 0, 8),
		Vector3(-5.5, 0, -14), Vector3(5.5, 0, -14),
	]
	for pos in positions:
		var root := _place_prop("lantern", pos, Vector3(0.6, 2.4, 0.6))
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.72, 0.35)
		light.light_energy = 1.6
		light.omni_range = 8.0
		light.shadow_enabled = false
		light.position = Vector3(0, 1.9, 0)
		root.add_child(light)


func _build_trees() -> void:
	var spots := [
		Vector3(-15, 0, -13), Vector3(15, 0, -13),
		Vector3(-15, 0, 11), Vector3(15, 0, 11),
		Vector3(-8, 0, 15), Vector3(8, 0, 15),
		Vector3(-17, 0, 0), Vector3(17, 0, 0),
		Vector3(-12, 0, -8), Vector3(12, 0, -8),
	]
	for s in spots:
		if ModelLibrary.has_model("tree"):
			var root := Node3D.new()
			root.position = s
			add_child(root)
			var model := ModelLibrary.instantiate("tree", 1.0)
			if model:
				root.add_child(model)
			ModelLibrary.add_collision_box(root, Vector3(0.8, 3.5, 0.8), Vector3(0, 1.75, 0), 1)
		else:
			_static_box(Vector3(0.6, 3.5, 0.6), s + Vector3(0, 1.75, 0), Color(0.28, 0.16, 0.08))


func _build_decor_and_pickups() -> void:
	_place_prop("stone_lion", Vector3(-5.5, 0, 17), Vector3(1.3, 2.2, 1.3))
	_place_prop("stone_lion", Vector3(5.5, 0, 17), Vector3(1.3, 2.2, 1.3), PI)

	_make_pickup(Vector3(-11, 1.15, 2), "scroll_left", "左侧亭中古卷", "按 E 拾取古卷", "scroll")
	_make_pickup(Vector3(11, 1.15, 2), "scroll_right", "右侧亭中古卷", "按 E 拾取古卷", "scroll")
	_make_pickup(Vector3(0, 1.55, -12.2), "jade", "供台上的玉佩", "按 E 拾取玉佩", "jade")
	_make_pickup(Vector3(-3.2, 0.45, 7), "lotus", "池边莲花", "按 E 采摘莲花", "")

	_make_lore(Vector3(0, 0, 14.5), "石碑", "「此地旧称清风院，暮鼓晨钟，百年未绝。近日宵小潜入，旧物失散，望有缘人助之。」")


func _build_npc() -> void:
	var npc := StaticBody3D.new()
	npc.set_script(load("res://scripts/npc.gd"))
	npc.position = Vector3(3.5, 0, -6.5)
	npc.rotation.y = deg_to_rad(-30)
	npc.npc_id = "elder"
	npc.display_name = "守院老者"
	npc.prompt_text = "按 E 与守院老者交谈"
	add_child(npc)


func _build_enemies() -> void:
	var spots := [Vector3(-12, 0.1, 10), Vector3(13, 0.1, 9), Vector3(0, 0.1, -16)]
	var names := ["匪徒甲", "匪徒乙", "匪徒丙"]
	for i in range(spots.size()):
		var e := CharacterBody3D.new()
		e.set_script(load("res://scripts/enemy.gd"))
		e.position = spots[i]
		e.enemy_id = "bandit"
		e.display_name = names[i]
		e.max_health = 70.0
		add_child(e)


func _build_ambient_details() -> void:
	for pos in [Vector3(-6, 0, 5), Vector3(7, 0, 4), Vector3(-14, 0, -5), Vector3(14, 0, -4)]:
		_static_box(Vector3(1.2, 0.7, 0.9), pos + Vector3(0, 0.35, 0), Color(0.45, 0.43, 0.4))
		_static_box(Vector3(0.7, 0.45, 0.6), pos + Vector3(0.6, 0.22, 0.3), Color(0.48, 0.46, 0.42))


func _make_pickup(pos: Vector3, item_id: String, display_name: String, prompt: String, model_key: String) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 4
	body.collision_mask = 0
	body.set_script(load("res://scripts/interactable.gd"))
	body.prompt_text = prompt
	body.item_id = item_id
	body.display_name = display_name
	body.one_shot = true

	var visual: Node3D = null
	if model_key != "" and ModelLibrary.has_model(model_key):
		visual = ModelLibrary.instantiate(model_key, 1.0)
	if visual:
		body.add_child(visual)
	else:
		var mesh_i := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		mesh_i.mesh = sphere
		mesh_i.material_override = _mat(GOLD, 0.3, 0.6, Color(0.9, 0.7, 0.2), 0.8)
		body.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	body.add_child(col)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.45)
	light.light_energy = 0.7
	light.omni_range = 2.8
	body.add_child(light)
	add_child(body)


func _make_lore(pos: Vector3, title: String, text: String) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	body.set_script(load("res://scripts/interactable.gd"))
	body.prompt_text = "按 E 阅读%s" % title
	body.item_id = ""
	body.display_name = title
	body.one_shot = false
	body.message = text

	if ModelLibrary.has_model("stele"):
		var model := ModelLibrary.instantiate("stele", 1.0)
		if model:
			body.add_child(model)
	else:
		var mesh_i := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 2.1, 0.38)
		mesh_i.mesh = box
		mesh_i.material_override = _mat(STONE)
		mesh_i.position = Vector3(0, 1.05, 0)
		body.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 2.2, 0.55)
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	body.add_child(col)
	add_child(body)
