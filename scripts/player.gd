extends CharacterBody3D

const WALK_SPEED := 5.5
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 6.5
const MOUSE_SENS := 0.0025
const ATTACK_DAMAGE := 28.0
const ATTACK_RANGE := 2.6
const ATTACK_COOLDOWN := 0.55

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var weapon: Node3D = $Head/Camera3D/Weapon

var gravity: float = 18.0
var pitch: float = 0.0
var attack_cd: float = 0.0
var attack_anim: float = 0.0
var hit_done: bool = false
var invuln: float = 0.0
var spawn_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("player")
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	spawn_pos = global_position
	floor_snap_length = 0.3
	camera.current = true
	ray.target_position = Vector3(0, 0, -3.2)
	# 延迟一帧再锁鼠标，避免启动时焦点丢失
	call_deferred("_capture_mouse")
	if GameState:
		GameState.set_health(GameState.MAX_HEALTH)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if not _blocked():
			_start_attack()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _blocked():
			return
		rotate_y(-event.relative.x * MOUSE_SENS)
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, deg_to_rad(-85.0), deg_to_rad(85.0))
		head.rotation.x = pitch
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and GameState and GameState.is_dead:
			_respawn()
			return
		if event.keycode == KEY_E and not _blocked():
			_try_interact()
			return


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln -= delta
	if attack_cd > 0.0:
		attack_cd -= delta
	if attack_anim > 0.0:
		attack_anim -= delta
		_swing_weapon()
		if not hit_done and attack_anim < 0.32:
			_do_attack_hit()
	else:
		_reset_weapon(delta)

	if _blocked():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir := _move_dir()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	if attack_anim > 0.0:
		speed *= 0.55

	if dir != Vector3.ZERO:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	if global_position.y < -5.0:
		global_position = spawn_pos
		velocity = Vector3.ZERO


func _move_dir() -> Vector3:
	var x := 0.0
	var z := 0.0
	# 直接读物理键，不依赖 InputMap，避免配置失效
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		z -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		z += 1.0
	var local := Vector3(x, 0.0, z)
	if local.length_squared() < 0.001:
		return Vector3.ZERO
	return (transform.basis * local).normalized()


func _blocked() -> bool:
	if GameState == null:
		return false
	return GameState.is_dead or GameState.dialogue_open


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if _blocked() or invuln > 0.0:
		return
	if GameState:
		GameState.damage_player(amount)
	invuln = 0.55
	if from_pos != Vector3.ZERO:
		var knock := global_position - from_pos
		knock.y = 0.0
		if knock.length_squared() > 0.001:
			velocity += knock.normalized() * 4.5 + Vector3.UP * 0.8


func _start_attack() -> void:
	if attack_cd > 0.0 or attack_anim > 0.0:
		return
	attack_cd = ATTACK_COOLDOWN
	attack_anim = 0.42
	hit_done = false


func _do_attack_hit() -> void:
	hit_done = true
	var space := get_world_3d().direct_space_state
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * ATTACK_RANGE)
	query.collision_mask = 8
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty() and hit.collider and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(ATTACK_DAMAGE, global_position)
		return
	var shape := SphereShape3D.new()
	shape.radius = 0.7
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), origin + forward * 1.5)
	params.collision_mask = 8
	params.exclude = [get_rid()]
	for item in space.intersect_shape(params, 4):
		var col = item.get("collider")
		if col and col.has_method("take_damage"):
			col.take_damage(ATTACK_DAMAGE, global_position)
			return


func _swing_weapon() -> void:
	if weapon == null:
		return
	var t := 1.0 - clampf(attack_anim / 0.42, 0.0, 1.0)
	var s := sin(t * PI)
	weapon.rotation_degrees = Vector3(-25.0 - s * 50.0, -20.0 + s * 70.0, -10.0 + s * 30.0)
	weapon.position = Vector3(0.28, -0.28 + s * 0.08, -0.45 - s * 0.1)


func _reset_weapon(delta: float) -> void:
	if weapon == null:
		return
	weapon.rotation_degrees = weapon.rotation_degrees.lerp(Vector3(8, 12, -8), 10.0 * delta)
	weapon.position = weapon.position.lerp(Vector3(0.32, -0.32, -0.48), 10.0 * delta)


func _try_interact() -> void:
	if not ray.is_colliding():
		return
	var col := ray.get_collider()
	if col == null:
		return
	if col.has_method("interact"):
		col.interact(self)
	elif col.get_parent() and col.get_parent().has_method("interact"):
		col.get_parent().interact(self)


func get_look_target() -> Dictionary:
	if ray.is_colliding():
		var col = ray.get_collider()
		var target = col
		if col and not col.has_method("get_prompt") and col.get_parent() and col.get_parent().has_method("get_prompt"):
			target = col.get_parent()
		if target and target.has_method("get_prompt"):
			return {"valid": true, "prompt": str(target.get_prompt())}
	return {"valid": false, "prompt": ""}


func _respawn() -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	pitch = 0.0
	head.rotation.x = 0.0
	if GameState:
		GameState.respawn_player()
	invuln = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
