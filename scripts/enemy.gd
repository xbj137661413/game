extends CharacterBody3D
class_name Enemy

@export var enemy_id: String = "bandit"
@export var display_name: String = "匪徒"
@export var max_health: float = 70.0
@export var move_speed: float = 2.8
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.7
@export var aggro_range: float = 14.0
@export var attack_cooldown: float = 1.1

var health: float = 70.0
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D
var dead: bool = false
var flash_timer: float = 0.0
var body_mesh: MeshInstance3D
var hp_bar: Label3D


func _ready() -> void:
	health = max_health
	collision_layer = 8
	collision_mask = 1
	add_to_group("enemies")
	_build_visual()
	call_deferred("_find_player")


func _build_visual() -> void:
	var model := ModelLibrary.instantiate("enemy_bandit", 1.0)
	if model:
		add_child(model)
		body_mesh = _find_mesh(model)
	else:
		body_mesh = MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.5
		body_mesh.mesh = cap
		body_mesh.position = Vector3(0, 0.9, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.18, 0.16)
		body_mesh.material_override = mat
		add_child(body_mesh)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	col.shape = shape
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

	hp_bar = Label3D.new()
	hp_bar.text = display_name
	hp_bar.font_size = 28
	hp_bar.modulate = Color(0.95, 0.85, 0.7)
	hp_bar.position = Vector3(0, 2.15, 0)
	hp_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_bar.no_depth_test = true
	add_child(hp_bar)


func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for c in n.get_children():
		var found := _find_mesh(c)
		if found:
			return found
	return null


func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null or not is_instance_valid(player):
		_find_player()
		return
	if GameState.dialogue_open:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and body_mesh:
			body_mesh.material_override = null

	if attack_timer > 0.0:
		attack_timer -= delta

	if not is_on_floor():
		velocity.y -= gravity * delta

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > aggro_range or GameState.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		move_and_slide()
		return

	if dist > attack_range * 0.85:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if dir.length() > 0.01:
			look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if to_player.length() > 0.01:
			look_at(global_position + to_player.normalized(), Vector3.UP)
		if attack_timer <= 0.0:
			_do_attack()

	move_and_slide()


func _do_attack() -> void:
	attack_timer = attack_cooldown
	if player and player.has_method("take_damage"):
		var dist := global_position.distance_to(player.global_position)
		if dist <= attack_range + 0.3:
			player.take_damage(attack_damage, global_position)


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if dead:
		return
	health -= amount
	flash_timer = 0.12
	if body_mesh:
		if body_mesh.material_override == null:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.4, 0.35)
			body_mesh.material_override = m
		elif body_mesh.material_override is StandardMaterial3D:
			(body_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.9, 0.4, 0.35)
	if hp_bar:
		hp_bar.text = "%s %d/%d" % [display_name, int(maxf(0.0, health)), int(max_health)]
	if from_pos != Vector3.ZERO:
		var knock := (global_position - from_pos).normalized()
		knock.y = 0.0
		velocity += knock * 5.0
	if health <= 0.0:
		_die()


func _die() -> void:
	dead = true
	GameState.register_kill(enemy_id)
	GameState.show_message("%s 已倒下" % display_name)
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.35)
	tw.tween_callback(queue_free)
