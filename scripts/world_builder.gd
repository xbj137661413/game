extends Node3D
## Procedurally builds an ancient Chinese courtyard with combat & quest actors.

const WOOD := Color(0.45, 0.28, 0.14)
const DARK_WOOD := Color(0.28, 0.16, 0.08)
const STONE := Color(0.55, 0.52, 0.48)
const TILE := Color(0.32, 0.14, 0.12)
const PLASTER := Color(0.90, 0.86, 0.78)
const GRASS := Color(0.32, 0.46, 0.28)
const WATER := Color(0.22, 0.42, 0.50, 0.82)
const GOLD := Color(0.82, 0.66, 0.24)
const PAPER := Color(0.96, 0.88, 0.68)
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


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0, roughness: float = 0.85) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	mesh_i.material_override = _mat(color, roughness)
	mesh_i.position = pos
	mesh_i.rotation.y = rot_y
	parent.add_child(mesh_i)
	return mesh_i


func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, top_r: float = -1.0) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius if top_r < 0.0 else top_r
	cyl.bottom_radius = radius
	cyl.height = height
	mesh_i.mesh = cyl
	mesh_i.material_override = _mat(color)
	mesh_i.position = pos
	parent.add_child(mesh_i)
	return mesh_i


func _static_box(size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0, roughness: float = 0.85) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	body.collision_layer = 1
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	mesh_i.material_override = _mat(color, roughness)
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _build_ground() -> void:
	_static_box(Vector3(90, 1, 90), Vector3(0, -0.5, 0), GRASS, 0.0, 0.95)
	# Outer earth ring tone
	_static_box(Vector3(50, 0.08, 50), Vector3(0, 0.02, 0), MOSS, 0.0, 0.98)
	# Courtyard stone floor with checker-ish slabs
	_static_box(Vector3(30, 0.12, 30), Vector3(0, 0.06, 0), STONE, 0.0, 0.9)
	for x in range(-3, 4):
		for z in range(-3, 4):
			if (x + z) % 2 == 0:
				_box(self, Vector3(3.8, 0.04, 3.8), Vector3(x * 4.0, 0.13, z * 4.0), Color(0.50, 0.47, 0.43), 0.0, 0.92)
	# Raised platform for main hall
	_static_box(Vector3(16, 0.45, 9), Vector3(0, 0.22, -10), Color(0.48, 0.44, 0.38), 0.0, 0.88)
	_static_box(Vector3(14, 0.15, 2.5), Vector3(0, 0.35, -5.8), Color(0.50, 0.46, 0.40))
	# Steps
	for i in range(3):
		_static_box(Vector3(6.0 - i * 0.4, 0.18, 0.8), Vector3(0, 0.15 + i * 0.18, -4.5 - i * 0.55), STONE)


func _build_walls() -> void:
	# North + east + west walls (south wall has gate opening)
	_static_box(Vector3(42, 4.2, 0.7), Vector3(0, 2.1, -19), PLASTER)
	_static_box(Vector3(0.7, 4.2, 38), Vector3(-21, 2.1, 0), PLASTER)
	_static_box(Vector3(0.7, 4.2, 38), Vector3(21, 2.1, 0), PLASTER)
	# South wall wings (gate gap in center)
	_static_box(Vector3(15, 4.2, 0.7), Vector3(-13.5, 2.1, 19), PLASTER)
	_static_box(Vector3(15, 4.2, 0.7), Vector3(13.5, 2.1, 19), PLASTER)
	# Red lower band
	_static_box(Vector3(42, 0.9, 0.75), Vector3(0, 0.45, -19), Color(0.55, 0.12, 0.12))
	_static_box(Vector3(15, 0.9, 0.75), Vector3(-13.5, 0.45, 19), Color(0.55, 0.12, 0.12))
	_static_box(Vector3(15, 0.9, 0.75), Vector3(13.5, 0.45, 19), Color(0.55, 0.12, 0.12))
	_static_box(Vector3(0.75, 0.9, 38), Vector3(-21, 0.45, 0), Color(0.55, 0.12, 0.12))
	_static_box(Vector3(0.75, 0.9, 38), Vector3(21, 0.45, 0), Color(0.55, 0.12, 0.12))
	# Tile tops
	_static_box(Vector3(43, 0.4, 1.15), Vector3(0, 4.35, -19), TILE)
	_static_box(Vector3(15.2, 0.4, 1.15), Vector3(-13.5, 4.35, 19), TILE)
	_static_box(Vector3(15.2, 0.4, 1.15), Vector3(13.5, 4.35, 19), TILE)
	_static_box(Vector3(1.15, 0.4, 39), Vector3(-21, 4.35, 0), TILE)
	_static_box(Vector3(1.15, 0.4, 39), Vector3(21, 4.35, 0), TILE)
	# Gate
	_static_box(Vector3(1.4, 5.0, 1.4), Vector3(-4.0, 2.5, 19), DARK_WOOD)
	_static_box(Vector3(1.4, 5.0, 1.4), Vector3(4.0, 2.5, 19), DARK_WOOD)
	_static_box(Vector3(9.5, 1.0, 1.6), Vector3(0, 5.0, 19), TILE)
	_static_box(Vector3(9.2, 0.35, 1.8), Vector3(0, 5.55, 19), Color(0.22, 0.1, 0.08))
	_box(self, Vector3(2.4, 0.7, 0.15), Vector3(0, 4.3, 19.75), Color(0.2, 0.08, 0.08))
	_static_box(Vector3(8, 0.22, 2.2), Vector3(0, 0.12, 18.2), STONE)


func _build_main_hall() -> void:
	var hall := Node3D.new()
	hall.name = "MainHall"
	hall.position = Vector3(0, 0.4, -10)
	add_child(hall)

	for x in [-5.5, -1.85, 1.85, 5.5]:
		_cylinder(hall, 0.32, 4.4, Vector3(x, 2.6, -2.8), DARK_WOOD)
		_cylinder(hall, 0.32, 4.4, Vector3(x, 2.6, 2.8), DARK_WOOD)
		# Pillar bases
		_box(hall, Vector3(0.7, 0.25, 0.7), Vector3(x, 0.15, -2.8), STONE)
		_box(hall, Vector3(0.7, 0.25, 0.7), Vector3(x, 0.15, 2.8), STONE)

	_box(hall, Vector3(13, 3.4, 0.4), Vector3(0, 2.1, -3.4), PLASTER)
	_box(hall, Vector3(0.4, 3.4, 7.0), Vector3(-6.4, 2.1, 0), PLASTER)
	_box(hall, Vector3(0.4, 3.4, 7.0), Vector3(6.4, 2.1, 0), PLASTER)
	# Red beams
	_box(hall, Vector3(13.5, 0.35, 0.45), Vector3(0, 4.1, 3.2), Color(0.55, 0.12, 0.1))
	_box(hall, Vector3(13.5, 0.35, 0.45), Vector3(0, 4.1, -3.2), Color(0.55, 0.12, 0.1))

	# Multi-tier roof
	_box(hall, Vector3(15.5, 0.3, 9.2), Vector3(0, 4.6, 0), TILE)
	var left_roof := _box(hall, Vector3(15.8, 0.22, 4.6), Vector3(0, 5.15, -2.2), TILE)
	left_roof.rotation.x = deg_to_rad(20)
	var right_roof := _box(hall, Vector3(15.8, 0.22, 4.6), Vector3(0, 5.15, 2.2), TILE)
	right_roof.rotation.x = deg_to_rad(-20)
	_box(hall, Vector3(14.5, 0.45, 0.7), Vector3(0, 5.7, 0), Color(0.22, 0.1, 0.08))
	# Roof ornaments
	_cylinder(hall, 0.08, 0.5, Vector3(-7, 5.95, 0), GOLD, 0.2)
	_cylinder(hall, 0.08, 0.5, Vector3(7, 5.95, 0), GOLD, 0.2)

	# Door
	_box(hall, Vector3(2.8, 3.2, 0.18), Vector3(0, 2.0, 3.35), WOOD)
	_box(hall, Vector3(0.22, 3.2, 0.28), Vector3(-1.5, 2.0, 3.4), DARK_WOOD)
	_box(hall, Vector3(0.22, 3.2, 0.28), Vector3(1.5, 2.0, 3.4), DARK_WOOD)
	_box(hall, Vector3(0.15, 0.15, 0.15), Vector3(0.9, 2.0, 3.5), GOLD, 0.0, 0.3)

	# Interior altar
	_static_box(Vector3(3.8, 0.9, 1.1), Vector3(0, 0.95, -12.2), WOOD)
	_static_box(Vector3(0.55, 0.7, 0.55), Vector3(0, 1.7, -12.2), GOLD, 0.0, 0.35)
	# Incense sticks
	for i in range(3):
		_cylinder(self, 0.02, 0.55, Vector3(-0.25 + i * 0.25, 2.15, -12.2), Color(0.85, 0.75, 0.55))


func _build_side_pavilions() -> void:
	_build_pavilion(Vector3(-11, 0, 2), "LeftPavilion")
	_build_pavilion(Vector3(11, 0, 2), "RightPavilion")


func _build_pavilion(origin: Vector3, name_str: String) -> void:
	var p := Node3D.new()
	p.name = name_str
	p.position = origin
	add_child(p)

	for x in [-2.2, 2.2]:
		for z in [-2.2, 2.2]:
			_cylinder(p, 0.18, 3.1, Vector3(x, 1.75, z), DARK_WOOD)
			_box(p, Vector3(0.45, 0.18, 0.45), Vector3(x, 0.12, z), STONE)

	_box(p, Vector3(5.5, 0.22, 5.5), Vector3(0, 3.3, 0), WOOD)
	_box(p, Vector3(6.2, 0.18, 6.2), Vector3(0, 3.65, 0), TILE)
	_cylinder(p, 0.06, 0.7, Vector3(0, 4.05, 0), GOLD, 0.32)
	# Railings
	for z in [-2.2, 2.2]:
		_box(p, Vector3(4.4, 0.12, 0.12), Vector3(0, 1.1, z), WOOD)
	for x in [-2.2, 2.2]:
		_box(p, Vector3(0.12, 0.12, 4.4), Vector3(x, 1.1, 0), WOOD)
	_static_box(Vector3(5.0, 0.2, 5.0), origin + Vector3(0, 0.1, 0), STONE)


func _build_path_and_pond() -> void:
	_static_box(Vector3(4.2, 0.1, 20), Vector3(0, 0.1, 5), PATH, 0.0, 0.9)
	_static_box(Vector3(12, 0.1, 3.2), Vector3(0, 0.1, 0), PATH, 0.0, 0.9)
	_static_box(Vector3(4.2, 0.1, 8), Vector3(0, 0.1, -3), PATH, 0.0, 0.9)

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
	rim.material_override = _mat(STONE, 0.9)
	rim.position = Vector3(0, -0.12, 0)
	pond_body.add_child(rim)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.8, 0.45, 6.2)
	col.shape = shape
	col.position = Vector3(0, -0.2, 0)
	pond_body.add_child(col)
	add_child(pond_body)

	# Lotus pads
	for i in range(5):
		var pad := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35 + (i % 3) * 0.08
		cyl.bottom_radius = cyl.top_radius
		cyl.height = 0.04
		pad.mesh = cyl
		pad.material_override = _mat(Color(0.2, 0.45, 0.25), 0.7)
		pad.position = Vector3(-2.5 + i * 1.2, 0.12, 6.5 + (i % 2) * 0.8)
		add_child(pad)

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
		_make_lantern(pos)


func _make_lantern(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_cylinder(root, 0.1, 1.7, Vector3(0, 0.85, 0), DARK_WOOD)
	var paper := _box(root, Vector3(0.75, 0.95, 0.75), Vector3(0, 2.1, 0), PAPER, 0.0, 0.55)
	paper.material_override = _mat(PAPER, 0.55, 0.0, Color(1.0, 0.7, 0.3), 0.45)
	_box(root, Vector3(0.9, 0.1, 0.9), Vector3(0, 2.65, 0), WOOD)
	_box(root, Vector3(0.9, 0.1, 0.9), Vector3(0, 1.6, 0), WOOD)
	_cylinder(root, 0.05, 0.2, Vector3(0, 2.85, 0), GOLD, 0.12)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.35)
	light.light_energy = 2.0
	light.omni_range = 9.0
	light.shadow_enabled = false
	light.position = Vector3(0, 2.1, 0)
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
		_make_tree(s)


func _make_tree(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_cylinder(root, 0.28, 3.8, Vector3(0, 1.9, 0), Color(0.28, 0.16, 0.08))
	_cylinder(root, 1.9, 1.3, Vector3(0, 4.2, 0), Color(0.22, 0.40, 0.20), 0.55)
	_cylinder(root, 1.4, 1.1, Vector3(0.35, 5.1, 0.15), Color(0.28, 0.46, 0.24), 0.35)
	_cylinder(root, 1.15, 0.95, Vector3(-0.25, 5.7, -0.15), Color(0.20, 0.38, 0.18), 0.28)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 3.8
	col.shape = shape
	col.position = Vector3(0, 1.9, 0)
	body.add_child(col)
	root.add_child(body)


func _build_decor_and_pickups() -> void:
	_make_statue(Vector3(-5.5, 0, 17), "石狮")
	_make_statue(Vector3(5.5, 0, 17), "石狮")

	_make_pickup(Vector3(-11, 1.15, 2), "scroll_left", "左侧亭中古卷", "按 E 拾取古卷")
	_make_pickup(Vector3(11, 1.15, 2), "scroll_right", "右侧亭中古卷", "按 E 拾取古卷")
	_make_pickup(Vector3(0, 1.55, -12.2), "jade", "供台上的玉佩", "按 E 拾取玉佩")
	_make_pickup(Vector3(-3.2, 0.45, 7), "lotus", "池边莲花", "按 E 采摘莲花")

	_make_lore(Vector3(0, 0, 14.5), "石碑", "「此地旧称清风院，暮鼓晨钟，百年未绝。近日宵小潜入，旧物失散，望有缘人助之。」")
	# Weapon rack flavor
	_static_box(Vector3(1.6, 1.4, 0.25), Vector3(-8, 0.9, -8), WOOD)
	_box(self, Vector3(0.08, 1.1, 0.08), Vector3(-8.3, 1.5, -8), Color(0.7, 0.72, 0.75), 0.0, 0.3)
	_box(self, Vector3(0.08, 1.1, 0.08), Vector3(-7.7, 1.5, -8), Color(0.7, 0.72, 0.75), 0.0, 0.3)


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
	var spots := [
		Vector3(-12, 0.1, 10),
		Vector3(13, 0.1, 9),
		Vector3(0, 0.1, -16),
	]
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
	# Rock clusters
	for pos in [Vector3(-6, 0, 5), Vector3(7, 0, 4), Vector3(-14, 0, -5), Vector3(14, 0, -4)]:
		_static_box(Vector3(1.2, 0.7, 0.9), pos + Vector3(0, 0.35, 0), Color(0.45, 0.43, 0.4), randf() * 1.5)
		_static_box(Vector3(0.7, 0.45, 0.6), pos + Vector3(0.6, 0.22, 0.3), Color(0.48, 0.46, 0.42))
	# Banners on gate pillars
	_box(self, Vector3(0.15, 2.2, 0.6), Vector3(-4.0, 3.2, 18.2), Color(0.6, 0.12, 0.12))
	_box(self, Vector3(0.15, 2.2, 0.6), Vector3(4.0, 3.2, 18.2), Color(0.6, 0.12, 0.12))


func _make_statue(pos: Vector3, label: String) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_box(root, Vector3(1.3, 0.4, 1.3), Vector3(0, 0.2, 0), STONE)
	_box(root, Vector3(0.95, 1.25, 0.85), Vector3(0, 1.05, 0), Color(0.58, 0.56, 0.52))
	_box(root, Vector3(0.75, 0.55, 0.75), Vector3(0, 1.95, 0), Color(0.58, 0.56, 0.52))
	_box(root, Vector3(0.35, 0.25, 0.55), Vector3(0, 2.35, 0.15), Color(0.55, 0.53, 0.5))
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.3, 2.4, 1.3)
	col.shape = shape
	col.position = Vector3(0, 1.2, 0)
	body.add_child(col)
	root.add_child(body)
	root.set_meta("label", label)


func _make_pickup(pos: Vector3, item_id: String, display_name: String, prompt: String) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 4
	body.collision_mask = 0
	body.set_script(load("res://scripts/interactable.gd"))
	body.prompt_text = prompt
	body.item_id = item_id
	body.display_name = display_name
	body.one_shot = true

	var mesh_i := MeshInstance3D.new()
	if item_id.begins_with("scroll"):
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.08, 0.55)
		mesh_i.mesh = box
		mesh_i.material_override = _mat(Color(0.78, 0.68, 0.42), 0.7, 0.0, GOLD, 0.35)
	elif item_id == "jade":
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		mesh_i.mesh = sphere
		mesh_i.material_override = _mat(Color(0.45, 0.85, 0.55), 0.25, 0.15, Color(0.3, 0.9, 0.4), 0.6)
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.05
		cyl.height = 0.25
		mesh_i.mesh = cyl
		mesh_i.material_override = _mat(Color(0.85, 0.35, 0.45), 0.5, 0.0, Color(0.9, 0.3, 0.4), 0.4)
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

	# gentle spin
	body.set_meta("spin", true)
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

	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 2.1, 0.38)
	mesh_i.mesh = box
	mesh_i.material_override = _mat(STONE, 0.92)
	mesh_i.position = Vector3(0, 1.05, 0)
	body.add_child(mesh_i)
	var top := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(1.7, 0.25, 0.5)
	top.mesh = top_box
	top.material_override = _mat(Color(0.45, 0.42, 0.38))
	top.position = Vector3(0, 2.2, 0)
	body.add_child(top)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 2.2, 0.55)
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	body.add_child(col)
	add_child(body)


