extends StaticBody3D
class_name Interactable

@export var prompt_text: String = "按 E 交互"
@export var item_id: String = ""
@export var display_name: String = "物品"
@export var one_shot: bool = true
@export var message: String = ""

var used: bool = false


func get_prompt() -> String:
	if used and one_shot:
		return ""
	return prompt_text


func interact(_player: Node) -> void:
	if used and one_shot:
		return
	if one_shot:
		used = true
	if item_id != "":
		GameState.collect(item_id, display_name)
	elif message != "":
		GameState.show_message(message)
	else:
		GameState.show_message(display_name)
	_on_interacted()


func _on_interacted() -> void:
	if one_shot:
		visible = false
		collision_layer = 0
		collision_mask = 0
