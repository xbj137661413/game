extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/Speaker
@onready var body_label: Label = $Panel/Margin/VBox/Body
@onready var hint_label: Label = $Panel/Margin/VBox/Hint

var lines: Array = []
var index: int = 0
var on_finish: Callable = Callable()
var open: bool = false


func _ready() -> void:
	add_to_group("dialogue_ui")
	layer = 20
	open = false
	visible = false
	if panel:
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_dialogue(speaker: String, dialogue_lines: Array, finish: Callable = Callable()) -> void:
	lines = dialogue_lines
	index = 0
	on_finish = finish
	open = true
	visible = true
	if panel:
		panel.visible = true
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	speaker_label.text = speaker
	if GameState:
		GameState.set_dialogue_open(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_current()


func _show_current() -> void:
	if index >= lines.size():
		_close()
		return
	var line: Dictionary = lines[index]
	body_label.text = str(line.get("text", ""))
	hint_label.text = "点击 / 空格 / E 继续" if index < lines.size() - 1 else "点击 / 空格 / E 结束"


func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			advance = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if advance:
		get_viewport().set_input_as_handled()
		index += 1
		_show_current()


func _close() -> void:
	open = false
	visible = false
	if panel:
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GameState:
		GameState.set_dialogue_open(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if on_finish.is_valid():
		on_finish.call()
