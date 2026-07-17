extends StaticBody3D
class_name NPC

@export var npc_id: String = "elder"
@export var display_name: String = "守院老者"
@export var prompt_text: String = "按 E 交谈"

## lines: Array of { text, condition?, actions? }
## condition keys: quest_status:quest_id:status, has_item:id, always
var dialogue_tree: Array = []

var _talking: bool = false


func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	if dialogue_tree.is_empty():
		dialogue_tree = _default_elder_tree()
	_build_visual()


func _build_visual() -> void:
	if has_node("Visual"):
		return
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.4
	body.mesh = cap
	body.position = Vector3(0, 0.85, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.22, 0.18)
	mat.roughness = 0.75
	body.material_override = mat
	visual.add_child(body)

	var robe := MeshInstance3D.new()
	var robe_mesh := CylinderMesh.new()
	robe_mesh.top_radius = 0.28
	robe_mesh.bottom_radius = 0.45
	robe_mesh.height = 1.1
	robe.mesh = robe_mesh
	robe.position = Vector3(0, 0.7, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.42, 0.12, 0.12)
	robe.material_override = rmat
	visual.add_child(robe)

	var hat := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.05
	hat_mesh.bottom_radius = 0.42
	hat_mesh.height = 0.2
	hat.mesh = hat_mesh
	hat.position = Vector3(0, 1.7, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.12, 0.1, 0.08)
	hat.material_override = hmat
	visual.add_child(hat)

	var staff := MeshInstance3D.new()
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.04
	staff_mesh.bottom_radius = 0.05
	staff_mesh.height = 1.6
	staff.mesh = staff_mesh
	staff.position = Vector3(0.4, 0.9, 0.1)
	staff.rotation_degrees = Vector3(8, 0, 12)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.35, 0.22, 0.12)
	staff.material_override = smat
	visual.add_child(staff)

	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.7
		col.shape = shape
		col.position = Vector3(0, 0.9, 0)
		add_child(col)

	var label := Label3D.new()
	label.text = display_name
	label.font_size = 32
	label.modulate = Color(0.95, 0.88, 0.65)
	label.position = Vector3(0, 2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)


func get_prompt() -> String:
	if _talking or GameState.dialogue_open:
		return ""
	return prompt_text


func interact(_player: Node) -> void:
	if GameState.dialogue_open or _talking:
		return
	var lines := _resolve_lines()
	if lines.is_empty():
		GameState.show_message("%s 沉默不语。" % display_name)
		return
	var ui := get_tree().get_first_node_in_group("dialogue_ui")
	if ui and ui.has_method("open_dialogue"):
		_talking = true
		ui.open_dialogue(display_name, lines, func():
			_talking = false
			_apply_branch_actions(lines)
		)
	else:
		for line in lines:
			GameState.show_message("%s：%s" % [display_name, line.get("text", "")])
		_apply_branch_actions(lines)


func _resolve_lines() -> Array:
	# Pick first matching dialogue branch
	for branch in dialogue_tree:
		if _condition_met(branch.get("condition", "always")):
			return branch.get("lines", [])
	return []


func _condition_met(cond: String) -> bool:
	if cond == "" or cond == "always":
		return true
	var parts := cond.split(":")
	if parts.size() >= 3 and parts[0] == "quest_status":
		var qid := parts[1]
		var status := parts[2]
		if GameState.quests.has(qid):
			return str(GameState.quests[qid].status) == status
		return false
	if parts.size() >= 2 and parts[0] == "has_item":
		return GameState.has_item(parts[1])
	if parts.size() >= 2 and parts[0] == "quest_active":
		return GameState.quests.has(parts[1]) and GameState.quests[parts[1]].status == "active"
	if parts.size() >= 2 and parts[0] == "quest_done":
		return GameState.quests.has(parts[1]) and GameState.quests[parts[1]].status == "completed"
	if cond == "all_main_done":
		return (
			GameState.quests.get("gather_relics", {}).get("status", "") == "completed"
			and GameState.quests.get("purge_bandits", {}).get("status", "") == "completed"
		)
	return false


func _apply_branch_actions(lines: Array) -> void:
	for line in lines:
		_apply_actions(line.get("actions", []))


func _apply_actions(actions: Array) -> void:
	for act in actions:
		var a := str(act)
		var parts := a.split(":")
		if parts[0] == "start_quest" and parts.size() >= 2:
			GameState.start_quest(parts[1])
		elif parts[0] == "report_talk" and parts.size() >= 2:
			GameState.report_talk(parts[1])
		elif parts[0] == "heal":
			GameState.heal_player(GameState.MAX_HEALTH)
		elif parts[0] == "message" and parts.size() >= 2:
			GameState.show_message(":".join(parts.slice(1)))


func _default_elder_tree() -> Array:
	return [
		{
			"condition": "quest_status:return_elder:active",
			"lines": [
				{"text": "旧物归位，宵小尽除……老朽总算能安枕了。", "actions": ["report_talk:elder_report"]},
				{"text": "这枚平安符给你，权当谢礼。清风院大门，永远为你敞开。", "actions": ["heal"]},
			],
		},
		{
			"condition": "quest_status:purge_bandits:active",
			"lines": [
				{"text": "院墙外仍有刀光闪动，还请少侠小心行事。", "actions": []},
			],
		},
		{
			"condition": "quest_status:gather_relics:active",
			"lines": [
				{"text": "左右凉亭与正殿供台，皆曾供奉旧物，烦请寻回。", "actions": []},
			],
		},
		{
			"condition": "quest_status:clear_wind:available",
			"lines": [
				{"text": "少侠且慢。清风院近日常有异响，旧藏亦不知所踪。", "actions": []},
				{"text": "若你愿出手相助，先去寻回散落的古卷与玉佩，再清剿潜入的匪徒。", "actions": ["start_quest:clear_wind", "report_talk:elder"]},
			],
		},
		{
			"condition": "quest_status:clear_wind:active",
			"lines": [
				{"text": "去吧，莫要耽搁。", "actions": []},
			],
		},
		{
			"condition": "quest_status:clear_wind:completed",
			"lines": [
				{"text": "有劳少侠。院中风物，尽可随意游览。", "actions": []},
			],
		},
		{
			"condition": "always",
			"lines": [
				{"text": "清风徐来，岁月无声。", "actions": []},
			],
		},
	]
