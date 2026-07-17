extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var world_env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	get_tree().paused = false
	if player:
		player.add_to_group("player")
		if hud and hud.has_method("setup"):
			hud.setup(player)
	_build_atmosphere()
	if GameState:
		GameState.dialogue_open = false
		GameState.is_dead = false
		GameState.show_message("点击窗口后：WASD 移动，鼠标转视角")


func _build_atmosphere() -> void:
	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.70)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.72, 0.64)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.74, 0.78)
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = false
	env.ssao_enabled = false
