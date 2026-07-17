extends CanvasLayer

@onready var prompt_label: Label = $Prompt
@onready var message_label: Label = $Message
@onready var collect_label: Label = $CollectCount
@onready var quest_label: Label = $QuestTracker
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_text: Label = $HealthText
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var damage_vignette: ColorRect = $DamageVignette

var player: CharacterBody3D
var message_time: float = 0.0
var vignette_time: float = 0.0


func _ready() -> void:
	layer = 5
	_ignore_mouse_on_ui(self)
	if GameState:
		GameState.message_shown.connect(_on_message)
		GameState.item_collected.connect(_on_item_collected)
		GameState.health_changed.connect(_on_health)
		GameState.quest_updated.connect(_on_quest)
		GameState.player_died.connect(_on_death)
		_on_health(GameState.health, GameState.MAX_HEALTH)
	message_label.text = ""
	prompt_label.text = ""
	death_overlay.visible = false
	damage_vignette.modulate.a = 0.0
	_refresh_count()
	_refresh_quest()


func _ignore_mouse_on_ui(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse_on_ui(child)


func setup(p: CharacterBody3D) -> void:
	player = p


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""

	if vignette_time > 0.0:
		vignette_time -= delta
		damage_vignette.modulate.a = clampf(vignette_time / 0.4, 0.0, 0.55)
	else:
		damage_vignette.modulate.a = 0.0

	if player == null or (GameState and GameState.dialogue_open):
		prompt_label.text = ""
		return

	if player.has_method("get_look_target"):
		var look: Dictionary = player.get_look_target()
		if look.get("valid", false) and str(look.get("prompt", "")) != "":
			prompt_label.text = str(look.prompt)
		else:
			prompt_label.text = ""


func _on_message(text: String) -> void:
	message_label.text = text
	message_time = 2.5


func _on_item_collected(_item_id: String, _count: int) -> void:
	_refresh_count()


func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_text.text = "气血 %d/%d" % [int(current), int(maximum)]
	if current < maximum and current > 0.0:
		vignette_time = 0.45
	if GameState and not GameState.is_dead:
		death_overlay.visible = false


func _on_quest(_quest_id: String) -> void:
	_refresh_quest()


func _on_death() -> void:
	death_overlay.visible = true


func _refresh_count() -> void:
	if GameState:
		collect_label.text = "行囊：%d" % GameState.get_collect_count()


func _refresh_quest() -> void:
	if GameState:
		quest_label.text = GameState.get_quest_tracker_text()
